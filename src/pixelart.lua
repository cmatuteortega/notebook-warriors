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

    return pixelart.fromData(data, mask, opts)
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

--- pixel-grid shapes ----------------------------------------------------------

-- love.graphics.circle and love.graphics.line would draw smooth polygons at
-- whatever sub-pixel positions the maths lands on. These plot whole pixels in
-- the currently set colour instead, so a ring or a bar sits on the same grid as
-- everything else on the page. The thumb stick is drawn with them, and so is
-- the ring a pushpin marks its landing with, the leg of a compass, and every
-- staple.

-- One sample per pixel of the longer axis, which is what makes a line at any
-- angle come out as an unbroken run of single pixels rather than a dotted one.
--
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

--- sprites --------------------------------------------------------------------

function Sprite:draw(x, y, flip)
    love.graphics.draw(self.img, math.floor(x), math.floor(y), 0,
        flip and -1 or 1, 1, self.ox, self.oy)
end

-- Draws the silhouette in the current colour.
function Sprite:drawMask(x, y, flip)
    love.graphics.draw(self.mask, math.floor(x), math.floor(y), 0,
        flip and -1 or 1, 1, self.ox, self.oy)
end

return pixelart
