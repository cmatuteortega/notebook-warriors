-- Turns ASCII art into palette-locked images. Every sprite in the game is
-- authored as a table of equal-length strings where each character is a key
-- from Palette.key ('.' = transparent), so no colour can sneak in off-palette.

local Palette = require("src.palette")

local pixelart = {}

local Sprite = {}
Sprite.__index = Sprite

function pixelart.newSprite(rows, opts)
    opts = opts or {}
    local h = #rows
    local w = #rows[1]

    local data = love.image.newImageData(w, h)
    -- A white silhouette of the same art, used for the flat "just got hit"
    -- flash. Tinting the sprite itself would only multiply its colours darker.
    local mask = love.image.newImageData(w, h)

    for y = 1, h do
        local row = rows[y]
        assert(#row == w, ("pixel-art row %d is %d wide, expected %d"):format(y, #row, w))
        for x = 1, w do
            local ch = row:sub(x, x)
            if ch ~= "." then
                local c = Palette.key[ch]
                assert(c, "unknown palette key '" .. ch .. "'")
                data:setPixel(x - 1, y - 1, c[1], c[2], c[3], 1)
                mask:setPixel(x - 1, y - 1, 1, 1, 1, 1)
            end
        end
    end

    local sprite = pixelart.fromData(data, mask, opts)
    -- The art it was compiled from, kept so the same drawing can be compiled
    -- again in other colours (pixelart.twoTone, Sprites.enraged). Strings, so
    -- holding onto them costs nothing next to the two images beside them, and
    -- only art authored as ASCII has any -- a generated disc has no rows and
    -- nothing may assume one does.
    sprite.rows = rows
    return sprite
end

function pixelart.fromData(data, mask, opts)
    opts = opts or {}
    local w, h = data:getDimensions()

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")

    local maskImg = love.graphics.newImage(mask)
    maskImg:setFilter("nearest", "nearest")

    return setmetatable({
        img = img,
        mask = maskImg,
        w = w,
        h = h,
        -- Origin defaults to the centre so entity positions are body centres.
        ox = opts.ox or math.floor(w / 2),
        oy = opts.oy or math.floor(h / 2),
    }, Sprite)
end

-- A filled circle. Past about nine pixels across, hand-authoring a round brush
-- tip in ASCII is all transcription and no design, so the big ones are
-- generated. The half-pixel bias keeps the rim from looking cut off flat.
function pixelart.newDisc(radius)
    local size = radius * 2 + 1
    local data = love.image.newImageData(size, size)
    local mask = love.image.newImageData(size, size)
    local limit = (radius + 0.4) * (radius + 0.4)
    local c = Palette.ink

    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local dx, dy = x - radius, y - radius
            if dx * dx + dy * dy <= limit then
                data:setPixel(x, y, c[1], c[2], c[3], 1)
                mask:setPixel(x, y, 1, 1, 1, 1)
            end
        end
    end

    return pixelart.fromData(data, mask)
end

-- A filled oval: `newDisc` with the two radii pulled apart. A nib generated
-- this way reads as a chisel tip without ever being turned to face where it is
-- going (see the rendering rules) -- it is wide on one axis and flat on the
-- other, fixed, so a line dragged along its wide axis comes out thick and a
-- line dragged along its flat one comes out thin. The skate's trail is the one
-- user of it (src/skate.lua). Same half-pixel bias as `newDisc`, kept per axis
-- so the flat side isn't cut off flat either.
function pixelart.newOval(rx, ry)
    local w, h = rx * 2 + 1, ry * 2 + 1
    local data = love.image.newImageData(w, h)
    local mask = love.image.newImageData(w, h)
    local lx, ly = rx + 0.4, ry + 0.4
    local c = Palette.ink

    for y = 0, h - 1 do
        for x = 0, w - 1 do
            local dx, dy = x - rx, y - ry
            if (dx * dx) / (lx * lx) + (dy * dy) / (ly * ly) <= 1 then
                data:setPixel(x, y, c[1], c[2], c[3], 1)
                mask:setPixel(x, y, 1, 1, 1, 1)
            end
        end
    end

    return pixelart.fromData(data, mask)
end

--- turning art -----------------------------------------------------------------

-- A quarter turn clockwise: what was the top-left corner comes out the
-- top-right one. Exact, and it has to be -- every pixel lands on exactly one
-- pixel, so what comes out is the art that went in at another heading.
local function turnQuarter(rows)
    local w, h = #rows[1], #rows
    local out = {}

    for y = 1, w do
        local line = {}
        for x = 1, h do
            line[x] = rows[h - x + 1]:sub(y, y)
        end
        out[y] = table.concat(line)
    end

    return out
end

-- Any other angle, by walking the destination and asking which source pixel is
-- nearest. That way round leaves no holes: going the other way scatters the
-- source across the destination and leaves gaps between where it lands.
local function turnFree(rows, angle)
    local w, h = #rows[1], #rows
    -- Square, and big enough for the diagonal, since art turned off the square
    -- lies corner to corner in a bigger box than it started in.
    local size = math.ceil(math.sqrt(w * w + h * h)) + 1

    local c, s = math.cos(-angle), math.sin(-angle)
    -- Turned about the same point every sprite is drawn about (see `ox`, `oy`),
    -- so changing heading turns the thing on the spot instead of shifting it.
    local cx, cy = (w + 1) / 2, (h + 1) / 2
    local mid = (size + 1) / 2

    local out = {}
    for y = 1, size do
        local line = {}
        for x = 1, size do
            local dx, dy = x - mid, y - mid
            local sx = math.floor(dx * c - dy * s + cx + 0.5)
            local sy = math.floor(dx * s + dy * c + cy + 0.5)
            line[x] = (sx >= 1 and sx <= w and sy >= 1 and sy <= h)
                and rows[sy]:sub(sx, sx) or "."
        end
        out[y] = table.concat(line)
    end

    return out
end

-- One of eight headings of a piece of ASCII art, clockwise, as a new grid of
-- the same characters. `eighths` is 0 for the art as authored.
--
-- The turn is baked into a grid here rather than done with the angle argument
-- on love.graphics.draw, and that is what keeps the whole-pixel rule: what
-- comes out is an ordinary sprite drawn at an integer position, with nothing
-- sampled at an angle while the game is running.
--
-- The two halves of this are not equally honest and it is worth knowing which
-- one you are getting. The quarter turns are exact. The diagonals cannot be --
-- there is no lossless 45 degree map on a square grid -- so they take the
-- nearest source pixel instead. On a solid shape that reads as the same shape
-- with a staircased edge; on art made of single-pixel lines it does not
-- survive, and a thin arrow drawn on the rocket's board comes out as a blob at
-- four of its eight headings. That is the known price of turning a drawing
-- nobody authored, not a bug waiting to be fixed here.
function pixelart.turn(rows, eighths)
    eighths = eighths % 8

    -- Exact wherever it can be: a quarter turn never pays for a resample, so
    -- the four square headings are always the drawing itself.
    if eighths % 2 == 0 then
        for _ = 1, eighths / 2 do
            rows = turnQuarter(rows)
        end
        return rows
    end

    return turnFree(rows, eighths * math.pi / 4)
end

--- recolouring art ------------------------------------------------------------

-- The same drawing in two colours: whatever it is mostly made of in `fill`,
-- and every other mark in `rest`. Transparent stays transparent, so the
-- silhouette is untouched -- what comes out is the same shape, and only the
-- shading inside it has gone.
--
-- Two tones rather than a colour-for-colour map, and this is the whole reason
-- the function is shaped like this: a fixed map cannot recolour a body it has
-- not seen. `o` is the *fill* of a blot and a drop and the *detail* of every
-- other enemy in the game, so any table saying what ink becomes either leaves
-- the two ink-bodied rows unchanged or blacks out the eyes of the eight that
-- are not. Asking the art which mark it is made of answers for both, and goes
-- on answering for a page's own reskin of the crowd (Sprites.enemySkins) and
-- for whatever anybody draws next -- which is the same bargain the four offset
-- masks of an outline make (`outline` in src/enemy.lua): derive the mark from
-- the drawing rather than authoring one per drawing.
--
-- The fill is the commonest mark *inside* the drawing -- of the pixels whose
-- four neighbours are all opaque -- and both halves of that are load-bearing.
--
-- Commonest rather than lightest, because the lightest mark is the obvious pick
-- and is the wrong one: a blot is ink with two pixels of paper in it, and a
-- highlight two pixels wide is not what a body looks like. Taking the majority
-- also makes the result predictable in the way that matters -- `fill` comes out
-- covering more of the drawing than any other mark, so a crowd recoloured this
-- way reads as `fill` from across the page.
--
-- Inside, because an outline is not a fill and this game draws almost everything
-- with one. A bat is more wing-and-rim than body and a grin is nearly half teeth,
-- so counting every pixel hands the majority to the mark the *edges* are drawn in
-- and turns both inside out -- a red rim round a dark body, which is a different
-- creature rather than an angry one. Ignoring the edge asks the drawing what it is
-- filled with instead, which is the question. A shape with no inside at all --
-- art a pixel thick everywhere, which nothing in this game is -- falls back to
-- counting the whole of it, since the alternative there is a drawing entirely in
-- `rest`.
--
-- What it still cannot do is keep three tones. Any two marks that were different
-- and are both `rest` come out the same: a bat's mouth is red on paper and ends up
-- the black its wings are. Two colours is two colours, and which detail goes is
-- the price of the mark being the whole body.
--
-- A tie goes to whichever of them is met first reading top-left to bottom-right.
-- Ties have to break *somewhere* and they have to break the same way every time
-- -- these are baked once and drawn for the rest of the run -- so it is reading
-- order rather than anything about the palette, which is the one ordering a grid
-- of characters already has.
function pixelart.twoTone(rows, fill, rest)
    local at = function(x, y)
        local row = rows[y]
        return row and row:sub(x, x) or ""
    end
    -- Opaque, and off the edge counts as transparent: `at` answers "" outside
    -- the grid, which is not "." and would otherwise read as a pixel.
    local opaque = function(x, y)
        local ch = at(x, y)
        return ch ~= "" and ch ~= "."
    end

    local count, best, most = {}, nil, 0
    local sweep = function(inside)
        count, best, most = {}, nil, 0
        for y = 1, #rows do
            for x = 1, #rows[y] do
                local ch = at(x, y)
                local take = ch ~= "."
                if take and inside then
                    take = opaque(x - 1, y) and opaque(x + 1, y)
                        and opaque(x, y - 1) and opaque(x, y + 1)
                end
                if take then
                    local n = (count[ch] or 0) + 1
                    count[ch] = n
                    if n > most then best, most = ch, n end
                end
            end
        end
    end

    -- Inside the body first, and the whole of it only if there is no inside --
    -- art a pixel thick everywhere, which nothing in this game is and which
    -- would otherwise come out entirely in `rest`.
    sweep(true)
    if not best then sweep(false) end

    local out = {}
    for y = 1, #rows do
        out[y] = rows[y]:gsub("[^.]", function(ch)
            return ch == best and fill or rest
        end)
    end
    return out
end

--- pixel-grid shapes ----------------------------------------------------------

-- love.graphics.circle and love.graphics.line would draw smooth polygons at
-- whatever sub-pixel positions the maths lands on. These plot whole pixels in
-- the currently set colour instead, so a ring or a bar sits on the same grid as
-- everything else on the page. The thumb stick is drawn with them, and so is
-- the ring a pushpin marks its landing with, the leg of a compass, and every
-- staple.

-- One sample per pixel of the longer axis, which is what makes a line at any
-- angle come out as an unbroken run of single pixels rather than a dotted one.
function pixelart.line(x0, y0, x1, y1)
    local dx, dy = x1 - x0, y1 - y0
    local steps = math.max(1, math.floor(math.max(math.abs(dx), math.abs(dy)) + 0.5))

    for i = 0, steps do
        local t = i / steps
        love.graphics.rectangle("fill",
            math.floor(x0 + dx * t), math.floor(y0 + dy * t), 1, 1)
    end
end

-- The same line `width` pixels thick, for the laser beam (src/beam.lua).
--
-- One span per pixel of the longer axis -- a column of the band for a beam
-- that is mostly across the page, a row of it for one that is mostly down --
-- rather than a pixel at a time. Two reasons, and the first is correctness:
-- the obvious way to thicken a line is to plot `width` pixels along its
-- perpendicular at every step, and at an angle like 27 degrees the points that
-- lands on do not tile, so the band comes out with holes in it. A span is
-- contiguous by construction.
--
-- The second is cost. A beam is as long as the page is wide and the last level
-- fires four of them at once, so this is the only thing in the game drawing
-- eight hundred pixels a frame in a straight line; spans make that a couple of
-- hundred rectangles instead of a few thousand, the same trade circleFill
-- makes for the sun.
--
-- The span is opened out by the slope -- `width` measured square to the line is
-- more than `width` measured down a column -- which is what keeps a beam the
-- same thickness at every angle it can be aimed at.
--
-- Both ends are cut square to the *line* rather than to the axis, which is the
-- second clip each span gets. Cutting square to the axis is a column of work
-- less and was invisible while both ends of the only band in the game were
-- hidden -- one inside the player, one off the page -- but it leaves a diagonal
-- band with a step of overhang at each end, and the moment an end is somewhere
-- anybody can look at it that step is a nub hanging off it. A cut square to the
-- line is also what lets a disc of the band's own half-width round an end off
-- exactly, with nothing poking out from under it.
local function span(lo, hi, aLo, aHi)
    lo, hi = math.max(lo, aLo), math.min(hi, aHi)
    if hi < lo then return nil end

    local from = math.floor(lo + 0.5)
    -- Exclusive upper bound, and never less than the one pixel a band this
    -- thin still has to put down somewhere.
    return from, math.max(1, math.floor(hi + 0.5) - from)
end

function pixelart.band(x0, y0, x1, y1, width)
    local dx, dy = x1 - x0, y1 - y0
    local len = math.sqrt(dx * dx + dy * dy)
    if len < 1 then return end

    local ux, uy = dx / len, dy / len
    local half = width / 2

    if math.abs(dx) >= math.abs(dy) then
        local ext = half * len / math.abs(dx)
        local step = dx >= 0 and 1 or -1

        for i = 0, math.floor(math.abs(dx) + 0.5) do
            local x = x0 + step * i
            local y = y0 + dy * (x - x0) / dx

            -- How far along the line this column already is, and therefore the
            -- range of y still inside the two ends. A line with no run in y
            -- meets neither end anywhere but at its own two columns, which the
            -- walk cannot leave.
            local aLo, aHi = -math.huge, math.huge
            if uy ~= 0 then
                local done = (x - x0) * ux
                local a, b = -done / uy, (len - done) / uy
                aLo, aHi = math.min(a, b), math.max(a, b)
                aLo, aHi = y0 + aLo, y0 + aHi
            end

            local top, h = span(y - ext, y + ext, aLo, aHi)
            if top then
                love.graphics.rectangle("fill", math.floor(x), top, 1, h)
            end
        end
    else
        local ext = half * len / math.abs(dy)
        local step = dy >= 0 and 1 or -1

        for i = 0, math.floor(math.abs(dy) + 0.5) do
            local y = y0 + step * i
            local x = x0 + dx * (y - y0) / dy

            local aLo, aHi = -math.huge, math.huge
            if ux ~= 0 then
                local done = (y - y0) * uy
                local a, b = -done / ux, (len - done) / ux
                aLo, aHi = math.min(a, b), math.max(a, b)
                aLo, aHi = x0 + aLo, x0 + aHi
            end

            local left, w = span(x - ext, x + ext, aLo, aHi)
            if left then
                love.graphics.rectangle("fill", left, math.floor(y), w, 1)
            end
        end
    end
end

function pixelart.circleOutline(cx, cy, r)
    cx, cy = math.floor(cx), math.floor(cy)

    local x, y, err = r, 0, 1 - r
    while x >= y do
        love.graphics.rectangle("fill", cx + x, cy + y, 1, 1)
        love.graphics.rectangle("fill", cx + y, cy + x, 1, 1)
        love.graphics.rectangle("fill", cx - y, cy + x, 1, 1)
        love.graphics.rectangle("fill", cx - x, cy + y, 1, 1)
        love.graphics.rectangle("fill", cx - x, cy - y, 1, 1)
        love.graphics.rectangle("fill", cx - y, cy - x, 1, 1)
        love.graphics.rectangle("fill", cx + y, cy - x, 1, 1)
        love.graphics.rectangle("fill", cx + x, cy - y, 1, 1)

        y = y + 1
        if err < 0 then
            err = err + 2 * y + 1
        else
            x = x - 1
            err = err + 2 * (y - x) + 1
        end
    end
end

function pixelart.circleFill(cx, cy, r)
    cx, cy = math.floor(cx), math.floor(cy)

    for dy = -r, r do
        local dx = math.floor(math.sqrt(r * r - dy * dy))
        love.graphics.rectangle("fill", cx - dx, cy + dy, dx * 2 + 1, 1)
    end
end

-- Every horizontal span inside a closed polygon, one row at a time.
--
-- The rows are the point. A filled shape at an angle plotted a pixel at a time
-- does not tile and comes out with holes in it, where a span is contiguous by
-- construction -- which is `pixelart.band`'s argument and the scissors' offcut's
-- (`Scissors:drawSever`), and this is the same trick for a shape that is not a
-- half-plane. It is also what lets one caller paint the middle of a ring in ink
-- and another lay rebaked page into it: both want spans, and a span is all this
-- knows how to produce.
--
-- Even-odd, matching `Stroke.insidePath`, so a hand-drawn ring that crossed
-- itself is filled the same way it is tested -- a shape whose middle is painted
-- somewhere its own hit test says is outside would be worse than either answer
-- on its own. `poly` is flat pairs and closed implicitly, which is the shape a
-- path already is.
--
-- Clipped to `y0`/`y1` by the caller's own bounds rather than here: the two
-- callers clip to the viewport for the offcut's reason -- nothing is cleared or
-- painted a page away from anybody looking at it.
function pixelart.fillPolygon(poly, y0, y1, emit)
    local n = #poly
    if n < 6 then return end   -- fewer than three corners is not a shape

    local xs = {}
    for y = math.floor(y0), math.floor(y1) do
        -- The scanline's own centre, so a row is in or out rather than landing
        -- exactly on a vertex and counting it twice.
        local py = y + 0.5
        local count = 0
        local ax, ay = poly[n - 1], poly[n]
        for p = 1, n - 1, 2 do
            local bx, by = poly[p], poly[p + 1]
            if (by > py) ~= (ay > py) then
                count = count + 1
                xs[count] = ax + (py - ay) / (by - ay) * (bx - ax)
            end
            ax, ay = bx, by
        end

        if count > 1 then
            -- Insertion sort: a hand-drawn ring crosses a row twice almost
            -- always and four times occasionally, so this is a swap or two and
            -- never a sort worth the name.
            for i = 2, count do
                local v = xs[i]
                local j = i - 1
                while j > 0 and xs[j] > v do
                    xs[j + 1] = xs[j]
                    j = j - 1
                end
                xs[j + 1] = v
            end

            for i = 1, count - 1, 2 do
                local from = math.floor(xs[i])
                local to = math.floor(xs[i + 1])
                if to >= from then emit(from, y, to - from + 1) end
            end
        end
    end
end

--- sprites --------------------------------------------------------------------

-- `s` is a whole-number blow-up of the art and is 1 for all but one caller: a
-- monster drawn twice the size (Spawner:blown). A scale rather than a second set
-- of baked images, which is the opposite of the choice `pixelart.turn` makes for
-- headings, and for a reason that only applies here -- the crowd is drawn
-- through a page's own reskin of it (Sprites.enemy), so baking the big copies
-- would mean baking one for every skin of every enemy against the chance that
-- one of them walks on. A whole scale, nearest filtering and a floored position
-- put the result on exactly the same pixel grid as everything else, which is the
-- only thing the rule actually asks; the rule that stands is the one about
-- angles, and there is still no rotation here.
function Sprite:draw(x, y, flip, s)
    s = s or 1
    love.graphics.draw(self.img, math.floor(x), math.floor(y), 0,
        flip and -s or s, s, self.ox, self.oy)
end

-- Draws the silhouette in the current colour.
function Sprite:drawMask(x, y, flip, s)
    s = s or 1
    love.graphics.draw(self.mask, math.floor(x), math.floor(y), 0,
        flip and -s or s, s, self.ox, self.oy)
end

return pixelart
