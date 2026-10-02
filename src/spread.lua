-- The book the back pages are read in: two leaves, a crease down the middle,
-- and a page you turn with your finger.
--
-- The library, the canteen and the homework page were each one page with `< >`
-- under it, and stepping them was a cut: the section was one thing on one frame
-- and another thing on the next. That is the right furniture for a list and the
-- wrong furniture for a *book*, which is what all three of them are -- they are
-- read off the back of the same notebook the run is played on, they are stepped
-- in a fixed order, and the one gesture a phone has for "the next of these" is
-- the one your hand already makes over a page.
--
-- So a section is a spread rather than a page. Two leaves side by side with the
-- gutter between them, the section laid across both (the library's shelf on the
-- verso and the entry it opens on the recto; the canteen's and the homework
-- page's rows split down the middle), and a drag lifts the recto off the crease,
-- bends it, carries it across and lays it down as the next section's verso.
-- Which is what a leaf of a book *is*: one sheet with the end of one spread
-- printed on the front of it and the start of the next on the back.
--
-- **The whole of it is three numbers.** A leaf is a sheet hinged at the crease.
-- The sheet as a whole is standing at `mid`, it bows by `phi` radians over its
-- length, so it runs from `psi = mid - phi/2` at the root to `mid + phi/2` at the
-- free edge, and a point `u` along the paper is lying at `theta = psi + phi*u`.
-- Everything else falls out of integrating that:
--
--     x(u) = W * (sin(theta) - sin(psi)) / phi
--
-- -- where that bit of paper has got to across the page -- and `cos(theta)`,
-- which is how square-on it is to you, and so both which face of the sheet you
-- are looking at (the front while it is positive, the back once it is not) and
-- how much light it is catching.
--
-- The bow is hung either side of `mid` rather than off the root, and `mid` is
-- taken as `acos(1 - 2p)` rather than as `p * pi`, and both of those are there for
-- the same reason: **the free edge has to go where the finger goes.** A sheet bent
-- away from a root at the drag angle projects far wider than the drag asked for,
-- so the page hangs back and then whips across at the end; taken through the
-- arc-cosine and bowed symmetrically, the free edge travels within a percent or
-- two of straight across the page, which is what a hand dragging it expects. The
-- bend is then a thing that happens to the paper *between* the finger and the
-- spine, which is exactly what it is.
--
-- That is the whole model, and it is deliberately the whole model: no
-- perspective, no vertical foreshortening, nothing sampled off a curve at an
-- angle. A page is blitted a *column* at a time, every column a whole pixel wide
-- at a whole pixel position, which is the one way to bend a page that does not
-- break the rule the rest of this game is drawn under (see the head of
-- DESIGNDOC.md): whole pixels only, never at an angle. The bend is in which
-- source column lands where, and in nothing else.
--
-- **Shading steps down the palette rather than fading.** A column lying at an
-- angle catches less light, and the game has exactly one way to say that in
-- eight colours with no alpha: move the colour one rung darker, which is the
-- move `Palette.overprint` already makes for ink landing on a ruled line. So the
-- ramp here is that column of that table walked twice, and the sheet is drawn
-- through a shader that walks each pixel down it -- nothing where the paper is
-- square on, two rungs where it is edge-on, and everything between.
--
-- "Everything between" is where the second half of the rule comes in, because
-- there is no colour between paper and graphite and there never will be. A
-- fraction of a rung is *dithered*: a 4x4 comb decides, per pixel, whether it
-- takes the rung above or the one below, so three-tenths of a rung is three
-- pixels in ten one step darker. Which is how every fade in this game is drawn
-- (src/scribble.lua) and the only way this one could be -- quantised to three
-- flat bands, a bending page came out as three grey slabs with straight edges,
-- and straight edges are the one thing a curve must not have.
--
-- One entry of that table is not reused, and it is the interesting one. Paper
-- over anything is paper, because paper is an eraser and an eraser does not
-- stack; but paper *in shade* is graphite, because shade is not something laid on
-- the page, it is less light reaching it. Two different questions that happen to
-- share a ramp for the other seven colours -- and with paper left as an eraser
-- the shadow of a lifted leaf came out as a row of dashes, the ruling darkening
-- under it and the page between the rules not.
--
-- **A leaf that has no room is not a leaf.** A phone held upright gives the page
-- about 180 pixels across and half of that is not a page of anything, so under
-- MIN_LEAF the book collapses to one leaf: no crease, the screen lays its two
-- halves out stacked as it always did, and the same drag lifts the *whole* page
-- away about its left edge to show the next one underneath. Half a turn rather
-- than a whole one, because with one leaf showing there is no back of the sheet
-- to land on -- what is under it is already where you are going.
--
-- **The drag and the pen share the page.** Everything here is drawn on, so every
-- press has to be read as either a line or a turn, and the reading has to be over
-- in the first few pixels or the page stops answering the pen.
--
-- A press within GRAB of the outer edge of a leaf is a turn on the frame it lands,
-- no threshold at all: that is where a hand reaches for a page, and it is the one
-- strip of these screens with nothing printed on it. A press anywhere else is
-- **undecided**, and stays undecided for at most SLIP pixels of travel or HOLD
-- seconds, whichever comes first -- sideways and it is a turn, anything else and
-- it is a line, and a finger that has sat still for a tenth of a second is a line
-- too. While it is undecided the pen lays nothing, and that is the whole of what
-- the gesture costs: the first five pixels of a stroke, on three screens whose own
-- headers say the ink on them is ink and fades.
--
-- The bias is deliberate and it is towards the *line*. A page turn is a fast
-- gesture and a drawn line usually is not, so the two thresholds sort them almost
-- by themselves; and where they do not, a slow drag across the page draws on it
-- and there are two arrows and two page edges that will still turn it.

local Palette = require("src.palette")
local Sfx = require("src.sfx")

local Spread = {}
local Book = {}
Book.__index = Book

--- the numbers ---------------------------------------------------------------

local MIN_LEAF = 140    -- a leaf narrower than this is not a leaf: under twice
                        -- this across, the book opens as a single page
local GUTTER = 6        -- how far the crease's shadow reaches onto each leaf
local INNER = 9         -- ... and how much of each leaf is left clear beside it.
                        -- The gutter margin of any bound book, and it is wider
                        -- than the shadow on purpose: paper near a fold is paper
                        -- you are reading down a slope, and a column of lettering
                        -- that starts where the shading stops still reads as one
                        -- that starts in the fold
local OUTER = 10        -- ... and the margin down the other side of each leaf,
                        -- which is the book's rather than any screen's. Every
                        -- page in this notebook has room round the writing; what
                        -- the fold changed is that there are now two pages to
                        -- give it to, and a leaf that gave its room away to fit
                        -- one more column was three screens quietly printing to
                        -- the edge of the paper
local GRAB = 20         -- the outer strip of a leaf that turns the page the
                        -- moment it is touched, with no threshold at all -- the
                        -- edge your hand already goes for
local SLIP = 5          -- ... and how far a finger that landed anywhere else has
                        -- to travel, sideways, before it is read as a turn
                        -- instead of as a line
local HOLD = 0.12       -- ... or how long it may sit there before it is one
                        -- anyway. A tap lays a dot on these pages and a dot is
                        -- not a gesture, so it must not be waited on
local BEND = 0.95       -- how far the sheet bows over its length at the middle
                        -- of a full turn, in radians. Past about 1.2 the far end
                        -- folds back over the near one hard enough to read as a
                        -- crumple rather than as paper.
local BEND_ONE = 0.55   -- ... and on a single leaf, where the turn is a half one
                        -- and there is no back face for a fold to hide behind
local THROW = 1.5       -- a full turn, in leaf widths of finger travel
local SNAP = 0.38       -- seconds an unassisted turn takes (an arrow, a key)
local FLICK = 90        -- canvas pixels a second past which a let-go is a flick
                        -- and finishes the turn from wherever it had got to
local SHADOW = 4        -- the band of page a lifted sheet darkens beside it
local SHADE_RUNG = 0.7  -- ... and how far down the ramp it darkens it. Under a
                        -- rung, so the band is dithered rather than solid: a
                        -- sheet a few pixels off the page does not black it out

-- Below this the bend is a straight sheet, and the integral above is 0/0. It is
-- a floor rather than a branch: at 1e-4 radians over a leaf the difference
-- between the arc and the chord is a ten-thousandth of a pixel.
local FLAT = 1e-4

--- the shade ramp ------------------------------------------------------------

-- Every palette colour one and two rungs darker. Seven of the eight are not a new
-- decision -- a rung down is what `Palette.overprint` already says a mark becomes
-- over a ruled line, so it is that column of that table, walked. The eighth is
-- paper, which that table leaves alone because an eraser does not stack, and
-- which shade has to darken because otherwise nothing between the rules gets
-- darker at all. Two rungs is as far as it needs to go: everything has reached
-- ink or slate by then, and ink is the bottom.
local RUNGS = 3         -- rows of the ramp: 0, 1 and 2 rungs down

local SHADE = [[
uniform Image ramp;
uniform Image comb;
uniform vec3 cols[COLS];
uniform float rung;

vec4 effect(vec4 tint, Image tex, vec2 tc, vec2 sc) {
    vec3 c = Texel(tex, tc).rgb;

    // Nearest palette entry, exactly as src/overprint.lua matches: the source is
    // a canvas this game drew, so every pixel of it is already one of the eight.
    int bi = 0;
    float best = 4.0;
    for (int i = 0; i < COLS; i++) {
        vec3 d = c - cols[i];
        float m = dot(d, d);
        if (m < best) { best = m; bi = i; }
    }

    // A rung and a bit: the bit is paid in pixels rather than in colour, the comb
    // deciding which of them step down and which stay.
    float r = floor(rung);
    if (Texel(comb, sc / 4.0).r < fract(rung)) r += 1.0;

    vec2 at = vec2((float(bi) + 0.5) / float(COLS),
                   (r + 0.5) / float(RUNGS));
    return vec4(Texel(ramp, at).rgb, 1.0);
}
]]

local shade, ramp, comb, quad
local bufA, bufB, bufW, bufH

-- One rung down, by name.
local function darker(name)
    if name == "paper" then return "graphite" end
    return Palette.overprint[name][2]
end

local function buildRamp()
    local w = #Palette.marks
    local data = love.image.newImageData(w, RUNGS)

    for x = 1, w do
        local name = Palette.marks[x]
        for y = 1, RUNGS do
            local c = Palette[name]
            assert(c, "the shade ramp names a colour that is not in the palette")
            data:setPixel(x - 1, y - 1, c[1], c[2], c[3], 1)
            name = darker(name)
        end
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- The ordinary 4x4 ordered dither, as an image: the threshold a pixel has to
-- beat to take the darker of the two rungs it is between. Wrapped, so the shader
-- can index it straight off the screen position and the comb stays nailed to the
-- page rather than sliding about with whatever is being drawn through it.
local BAYER = {
    {  0,  8,  2, 10 },
    { 12,  4, 14,  6 },
    {  3, 11,  1,  9 },
    { 15,  7, 13,  5 },
}

local function buildComb()
    local data = love.image.newImageData(4, 4)
    for y = 1, 4 do
        for x = 1, 4 do
            local v = (BAYER[y][x] + 0.5) / 16
            data:setPixel(x - 1, y - 1, v, v, v, 1)
        end
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    img:setWrap("repeat", "repeat")
    return img
end

function Spread.load()
    shade = love.graphics.newShader(
        ("#define COLS %d\n#define RUNGS %d\n"):format(#Palette.marks, RUNGS)
        .. SHADE)

    ramp = buildRamp()
    comb = buildComb()
    shade:send("ramp", ramp)
    shade:send("comb", comb)

    local cols = {}
    for i, name in ipairs(Palette.marks) do cols[i] = Palette[name] end
    shade:send("cols", unpack(cols))
    shade:send("rung", 0)

    quad = love.graphics.newQuad(0, 0, 1, 1, 1, 1)
end

-- The two sheets a turn is composed out of, at the size the window is now. Only
-- one of these screens is ever up, so they are shared rather than one pair per
-- page, and they are only made the first time a page is actually turned: a book
-- nobody opens costs two canvases it never allocated.
local function buffers(w, h)
    if bufW == w and bufH == h and bufA then return end

    if bufA then bufA:release() end
    if bufB then bufB:release() end

    bufA = love.graphics.newCanvas(w, h)
    bufB = love.graphics.newCanvas(w, h)
    bufA:setFilter("nearest", "nearest")
    bufB:setFilter("nearest", "nearest")
    bufW, bufH = w, h
end

--- a book --------------------------------------------------------------------

-- How many sections there are is handed in every frame rather than held, because
-- a screen's catalogue can grow between one opening and the next -- the
-- library's shelves are gated on the register -- and a book that cached the
-- number would be a book with a page in it that is not there any more.
function Spread.new()
    return setmetatable({
        at = 1,         -- the section open
        to = nil,       -- where a turn in progress is going
        dir = 0,        -- +1 forward (the recto lifts), -1 back (the verso does)
        p = 0,          -- how far round it has got, 0..1
        auto = false,   -- running itself home rather than following a finger
        home = false,   -- ... and which end of the turn it is running to
        down = false,
        held = false,   -- a finger is on the page and it may yet be a turn
        ax = 0, ay = 0, -- where it came down
        lx = 0,         -- where it was last frame, for the flick
        wait = 0,       -- ... and how long it has been undecided
        speed = 0,
        count = 1,
        onTurn = nil,   -- the screen's, if it has anything to put down
    }, Book)
end

-- A screen opening again. Whatever was held when it was last closed is not held
-- now -- the press that opened it belongs to the tab that was pressed -- and a
-- turn left in the air is landed rather than carried, since the page it was going
-- to is the page that is about to be drawn.
function Book:rest()
    self.down, self.held, self.dir = false, false, 0
    if self.to then self.at = self.to end
    self.to, self.p, self.auto = nil, 0, false
end

--- geometry ------------------------------------------------------------------

-- The page, the two leaves on it and the crease between them. Struck off the
-- safe area rather than off the canvas, like everything else positioned against
-- an edge in this game, and the leaf width is floored so the crease lands on a
-- whole pixel and the two leaves are the same width to the pixel: a gutter half
-- a pixel off centre is a gutter that shimmers as a window is dragged.
function Book:fit(game, count)
    local ins = game.inset

    self.count = math.max(1, count or 1)
    self.at = (self.at - 1) % self.count + 1
    if self.to then self.to = (self.to - 1) % self.count + 1 end

    local lay = self.lay or {}
    lay.x = ins.l
    lay.w = game.vw - ins.l - ins.r
    lay.top = ins.t
    lay.bottom = game.vh - ins.b
    lay.h = lay.bottom - lay.top

    lay.two = math.floor(lay.w / 2) >= MIN_LEAF
    if lay.two then
        lay.leafW = math.floor(lay.w / 2)
        lay.verso = lay.x
        lay.recto = lay.x + lay.leafW
        lay.crease = lay.recto
        lay.printW = lay.leafW - INNER - OUTER
    else
        lay.leafW = lay.w
        lay.verso = lay.x
        lay.recto = lay.x
        lay.crease = nil
        lay.printW = lay.leafW - OUTER * 2
    end

    self.lay = lay
    return lay
end

-- Where a screen may print on one leaf: 1 is the verso (the left-hand page), 2 the
-- recto. On a single leaf both answers are the same page, which is the whole of
-- what a screen has to know about the collapse -- it lays its two halves out
-- stacked when `two` is false, and asks for the rects either way.
--
-- It is the printable area rather than the leaf: INNER comes off the spine side
-- of each and OUTER off the other, so the two answers are the same width and are
-- mirror images of each other about the fold. The sheet the turn is cut out of is
-- the whole leaf, margins and all -- what is bent is paper, not a column of text.
function Book:leaf(i)
    local lay = self.lay
    if not lay.two then return lay.x + OUTER, lay.top, lay.printW, lay.h end

    local x = i == 2 and lay.recto + INNER or lay.verso + OUTER
    return x, lay.top, lay.printW, lay.h
end

function Book:spread()
    return self.lay and self.lay.two
end

--- turning -------------------------------------------------------------------

-- Which section a turn of `dir` lands on. Wrapping, because that is what the
-- arrows it replaces have always done: the sections are a ring and the last
-- one's `>` has to go somewhere.
function Book:at_(dir)
    return (self.at - 1 + dir) % self.count + 1
end

function Book:turning()
    return self.to ~= nil
end

-- True while a finger is on a page that might be going somewhere: the screen's
-- pen must lay no ink and its buttons must swallow nothing.
function Book:eating()
    return self.held or self.to ~= nil
end

-- The section the screen should be laying out. It is `at` throughout a turn --
-- `to` only becomes `at` when the sheet lands -- so nothing a screen measures
-- moves under it while the page is moving.
function Book:section()
    return self.at
end

-- The turn begins. Nothing already drawn is rewound: the few stamps a threshold
-- crossing has laid are ink on a page that fades, which is what all the ink on
-- these screens is.
function Book:begin(dir, x)
    if self.count < 2 then return end
    self.dir = dir
    self.to = self:at_(dir)
    self.p = 0
    self.auto = false
    self.home = false
    self.ax = x or self.ax
    Sfx.play("transition")

    -- A screen with something live on the page it is leaving gets told here
    -- rather than when the leaf lands, because the moment a page starts moving is
    -- the moment you have stopped answering it -- the canteen disarms a box that
    -- was half scribbled in. It fires on a turn that falls back home as well, and
    -- that is right: you reached for the page.
    if self.onTurn then self.onTurn() end
end

-- A turn that runs itself: an arrow, a key, anything that is not a finger.
function Book:turn(dir)
    if self.to or self.held then return end
    self:begin(dir)
    self.auto = true
end

-- How far a finger has to carry the free edge for a whole turn. Measured in leaf
-- widths rather than in pixels, so it is the same gesture on a phone and in a
-- desktop window three times the size: a page is a page.
function Book:throw()
    return math.max(1, self.lay.leafW * THROW)
end

-- A finger coming down. `blocked` is the screen saying this point is furniture
-- -- an arrow, the corner button, a box that is answered -- and furniture is
-- pressed rather than dragged.
--
-- Landing in the outer strip of a leaf starts the turn there and then, with no
-- threshold, because that is where a hand goes for a page and there is nothing
-- out there to hit. Landing anywhere else only puts the book on watch.
function Book:grab(x, y, blocked)
    if self.to or self.count < 2 or blocked then return end

    local lay = self.lay
    if y < lay.top or y > lay.bottom then return end

    self.held = true
    self.ax, self.ay, self.lx = x, y, x
    self.speed = 0
    self.wait = 0
    self.dir = 0

    -- Which edge decides which way: the outer edge of the recto pulls forward,
    -- the outer edge of the verso pulls back. On a single leaf there is one page
    -- and both its edges are live, each pulling the way it points.
    if lay.x + lay.w - x <= GRAB then
        self:begin(1, x)
    elseif x - lay.x <= GRAB then
        self:begin(-1, x)
    end
end

-- The finger moving, while it is still undecided: sideways past the threshold and
-- it is a turn, anything else that far and it is a line and the pointer is handed
-- back to the pen. A stroke drawn straight down the page crosses SLIP vertically
-- in no time, which is exactly the case the second test is for.
function Book:decide(dt, x, y)
    local dx, dy = x - self.ax, y - self.ay

    if math.abs(dx) >= SLIP and math.abs(dx) > math.abs(dy) then
        self:begin(dx < 0 and 1 or -1, x)
        return
    end

    self.wait = self.wait + dt
    if dx * dx + dy * dy >= SLIP * SLIP or self.wait >= HOLD then
        self.held = false
    end
end

-- ... and once it is decided. Forward is the recto going left, so leftward travel
-- is progress; back is the mirror. Clamped at both ends rather than rubber-banded
-- -- a book has no give past a leaf lying flat, either flat.
function Book:drag(x)
    local travel = (self.ax - x) * self.dir
    self.p = math.min(1, math.max(0, travel / self:throw()))
end

-- The finger off the page. Past halfway, or moving fast enough that it was a
-- flick, the turn finishes itself; short of both it falls back where it came
-- from. `to` is kept either way and the fall-back runs `p` down to 0, so the
-- sheet is drawn coming home rather than snapping there.
function Book:letGo()
    self.held = false
    if not self.to then
        self.dir = 0
        return
    end

    self.auto = true
    self.home = not (self.p > 0.5 or self.speed * self.dir > FLICK)
end

-- One call a frame, ahead of the screen's pen, so that the frame a stroke turns
-- into a turn is a frame the pen lays nothing. `down`, `x` and `y` are the
-- pointer as the screen already has it (past its own stale guard), and `blocked`
-- says the press landed on furniture.
function Book:track(dt, down, x, y, blocked)
    if down and not self.down then
        self:grab(x, y, blocked)
    elseif down and self.held then
        -- Smoothed the way the pen smooths its own (src/scribble.lua), so one
        -- janky frame cannot decide whether a let-go was a flick.
        if dt > 0 then
            local v = (self.lx - x) / dt
            self.speed = self.speed + (v - self.speed) * math.min(1, dt * 12)
        end
        self.lx = x

        if self.dir == 0 then
            self:decide(dt, x, y)
        else
            self:drag(x)
        end
    elseif self.held then
        self:letGo()
    end
    self.down = down

    if not self.to or self.held or not self.auto then return end

    -- Landing swaps the section under the book, and that is the one moment `at`
    -- moves: everything up to it is two spreads drawn at once and nothing yet
    -- having changed.
    local step = dt / SNAP
    if self.home then
        self.p = self.p - step
        if self.p <= 0 then
            self.p, self.to, self.dir, self.auto = 0, nil, 0, false
        end
    else
        self.p = self.p + step
        if self.p >= 1 then
            self.at = self.to
            self.p, self.to, self.dir, self.auto = 0, nil, 0, false
        end
    end
end

--- the crease ----------------------------------------------------------------

-- The gutter, drawn by the screen inside its own ink pass so that it prints
-- rather than lies on top: graphite over paper is graphite and graphite over a
-- ruled line is slate, so the shadow darkens the ruling exactly as much as it
-- darkens the paper and the two go under it together. That is the difference
-- between a fold in the page and a grey stripe drawn on one.
--
-- It is dithered rather than banded because it has to *fall off*, and a fall-off
-- in eight colours with no alpha is a thinning of stamps -- the rule every fade
-- in this game is drawn under. The two columns hard against the fold go down
-- solid, since that is the bit of paper standing up out of the binding; from
-- there it thins to nothing by the lip of the gutter.
--
-- The pattern is an ordered one rather than a random drop, and that is not a
-- performance choice. A noise field would be a different field every time the
-- window changed shape, and -- worse -- the eye reads scattered graphite on this
-- page as *pencil*, because scattered graphite on this page is what pencil is
-- (src/scribble.lua). A 4x4 grid reads as tone.
function Book:drawCrease()
    local lay = self.lay
    if not lay or not lay.two then return end

    local cx = lay.crease
    love.graphics.setColor(Palette.graphite)

    for d = -GUTTER, GUTTER - 1 do
        local x = cx + d
        if x >= lay.x and x < lay.x + lay.w then
            -- Nearest the fold the paper is most nearly edge-on, so the density
            -- is one at the crease and nothing at the lip. Squared, because a
            -- linear ramp of dither reads as a band with a hard outer edge.
            local near = 1 - math.abs(d + 0.5) / GUTTER
            local dens = near * near
            if math.abs(d + 0.5) < 1 then dens = 1 end

            local col = BAYER[x % 4 + 1]
            for y = lay.top, lay.bottom - 1 do
                if (col[y % 4 + 1] + 0.5) / 16 < dens then
                    love.graphics.rectangle("fill", x, y, 1, 1)
                end
            end
        end
    end
end

--- drawing -------------------------------------------------------------------

-- One column of a source canvas, one whole pixel wide at a whole pixel position.
local function column(src, sx, top, h, dx)
    if sx < 0 or sx >= bufW then return end
    quad:setViewport(sx, top, 1, h, bufW, bufH)
    love.graphics.draw(src, quad, dx, top)
end

-- The sheet: every point along it, from the root at the hinge out to the free
-- edge, laid down as one column.
--
-- It is walked root-first because that is back-to-front. The far end of a bowed
-- sheet is the end nearest you -- it has lifted off the page and the root has
-- not -- so where the bend is hard enough that the far end has folded back over
-- the near one, the columns that arrive later are the ones in front. Painting in
-- that order is the whole of the hidden-surface problem here: no depth buffer,
-- no sorting, just the order of the loop.
--
-- Answers how far across the page the sheet reaches, and which side of the hinge
-- that is -- which is where the shade it throws goes. Past halfway the sheet has
-- curled, so the point furthest from the hinge is no longer the free edge but the
-- fold: that is what is nearest the page it is shading, so that is what is asked
-- for.
function Book:drawSheet(front, back)
    local lay = self.lay
    local W = lay.leafW
    local hinge = lay.two and lay.crease or lay.x

    -- The root angle, and how far the sheet bows away from it. The bow is
    -- greatest halfway round and nothing at either end, so a leaf lying flat --
    -- either flat -- is a leaf blitted column for column onto itself.
    local mid, phi
    if lay.two then
        -- A whole turn: the sheet lies flat one way at 0 and flat the other way
        -- at 1, and passes through edge-on halfway.
        mid = math.acos(1 - 2 * self.p)
        phi = BEND * math.sin(mid)
    else
        -- Half a turn on a single leaf: forward, the page you are on stands up
        -- off its left edge until it is edge-on and gone; back, the page you are
        -- returning to comes down the same arc the other way.
        mid = math.acos(1 - (self.dir >= 0 and self.p or 1 - self.p))
        -- Two bounds the second leaf gave for free and this one has to be told:
        -- the root may not lag back past flat on the page, and the free edge may
        -- not come round past edge-on -- with one page showing there is no back
        -- of the sheet for either to land on.
        phi = math.min(BEND_ONE * math.sin(mid * 2), math.pi - 2 * mid, 2 * mid)
    end
    if phi < FLAT then phi = FLAT end
    local psi = mid - phi / 2

    -- Which way the sheet reaches from its hinge when it is lying flat. On two
    -- leaves that is the side the face you are leaving is printed on; on one
    -- there is only the one way to reach.
    local side = (not lay.two or self.dir >= 0) and 1 or -1

    local root = math.sin(psi)
    local steps = math.max(2, math.ceil(W * 2))
    local rung = -1     -- never a legal value, so the first column always sends
    local far, reach = hinge, -1

    love.graphics.setShader(shade)
    love.graphics.setColor(1, 1, 1)

    for i = 0, steps do
        local u = i / steps
        local theta = psi + phi * u
        local face = math.cos(theta)

        local dx = math.floor(hinge + side * W * (math.sin(theta) - root) / phi)
        if math.abs(dx - hinge) > reach then
            far, reach = dx, math.abs(dx - hinge)
        end

        -- How square-on this bit of paper is decides how much light it has, and
        -- light in eight colours is a rung of the ramp and a fraction of the
        -- next one. Cubed, so that most of a leaf that is merely leaning stays
        -- the colour it is printed and the darkening is spent at the fold, where
        -- the paper actually turns away from you. Straight off the cosine the
        -- whole sheet greys over the moment the turn starts, and a page you
        -- cannot read is a page you cannot tell you are leaving.
        --
        -- Rounded to a sixteenth before it is sent: the value it is rounded from
        -- changes every column, and a uniform pushed three hundred times a frame
        -- to say the same thing to within a pixel of shade is three hundred
        -- round trips bought for nothing.
        local lit = 1 - math.abs(face)
        local want = math.floor((RUNGS - 1) * lit * lit * lit * 16 + 0.5) / 16
        if want ~= rung then
            rung = want
            shade:send("rung", rung)
        end

        -- The front of the sheet while it is facing you, the back once it is
        -- not. Both are read from the spine outwards, which is why the back
        -- lands the right way round when the leaf finally lies flat: `u` is a
        -- distance along the paper, and the paper is the same paper.
        if face >= 0 then
            column(front, math.floor(hinge + side * u * W), lay.top, lay.h, dx)
        elseif back then
            column(back, math.floor(hinge - side * u * W), lay.top, lay.h, dx)
        end
    end

    love.graphics.setShader()
    return far, far < hinge and -1 or 1
end

-- The band of page just beyond the sheet's free edge, one rung down: a sheet
-- standing off the page throws a little shade onto it, and without it the leaf
-- reads as printed on the page rather than lifted off it.
local function shadow(src, x0, side, top, h)
    love.graphics.setShader(shade)
    shade:send("rung", SHADE_RUNG)
    love.graphics.setColor(1, 1, 1)

    for i = 0, SHADOW - 1 do
        local x = x0 + side * i
        column(src, x, top, h, x)
    end

    love.graphics.setShader()
end

-- Draw the book. `page(section)` is the screen drawing one whole spread -- its
-- own overprint pass, background and all -- and it is called once at rest and
-- twice mid-turn, into canvases rather than onto the screen. Furniture (the
-- corner button, the footer, anything that goes out past the pass) is the
-- screen's own business and is drawn after this returns, so it stays put while
-- the page under it moves.
function Book:draw(game, page)
    if not self.to then
        page(self.at)
        return
    end

    buffers(game.vw, game.vh)

    -- Two spreads, composited whole. Drawn every frame rather than once at the
    -- grab: these pages have ink fading off them and lettering that wobbles, and
    -- a page that froze for the third of a second a turn takes would be the one
    -- moment in the book where the paper stopped breathing.
    --
    -- `Overprint.finish` puts its result back on whatever canvas was set when
    -- the pass opened (src/overprint.lua), so setting one here is the whole of
    -- rendering a page off-screen.
    local target = love.graphics.getCanvas()

    love.graphics.setCanvas(bufA)
    page(self.at)

    love.graphics.setCanvas(bufB)
    page(self.to)

    love.graphics.setCanvas(target)

    local lay = self.lay
    local fwd = self.dir >= 0

    love.graphics.setColor(1, 1, 1)

    if not lay.two then
        -- One leaf: what you are going to is already underneath, and the sheet
        -- on top of it is what you are leaving. Backwards is the same picture
        -- run the other way -- the page you are going back to swinging down over
        -- the one you are on -- so the two canvases change places and `psi` runs
        -- the other way (see drawSheet).
        local under = fwd and bufB or bufA
        local sheet = fwd and bufA or bufB

        love.graphics.setScissor(lay.x, lay.top, lay.w, lay.h)
        love.graphics.draw(under, 0, 0)

        local edge, side = self:drawSheet(sheet, nil)
        shadow(under, edge + side, side, lay.top, lay.h)

        love.graphics.setScissor()
        return
    end

    -- Two leaves. Under the sheet is the half of each spread that is not on it:
    -- going forward, the verso you are leaving stays until the sheet lands on it
    -- and the recto you are going to is uncovered the moment the sheet lifts;
    -- going back, both the other way round. Which is exactly what a book does,
    -- and why you spend a moment of every turn looking at one page of one spread
    -- beside one page of the next.
    local vs = fwd and bufA or bufB    -- whose verso shows under the sheet
    local rs = fwd and bufB or bufA    -- ... and whose recto

    love.graphics.setScissor(lay.verso, lay.top, lay.leafW, lay.h)
    love.graphics.draw(vs, 0, 0)

    love.graphics.setScissor(lay.recto, lay.top, lay.leafW, lay.h)
    love.graphics.draw(rs, 0, 0)

    -- The sheet itself: the face you are leaving on the front of it and the face
    -- you are going to on the back -- forward, this spread's recto and the next
    -- one's verso; back, this spread's verso and the previous one's recto. One
    -- sheet of paper with a page printed on each side of it, which is the fact
    -- this whole file is about.
    love.graphics.setScissor(lay.x, lay.top, lay.w, lay.h)
    local edge, side = self:drawSheet(bufA, bufB)

    -- And the shade it throws, just past where it reaches, onto whichever leaf is
    -- lying there. Which leaf that is follows the sheet rather than the direction
    -- of travel: halfway through a turn the sheet crosses the crease, and from
    -- there on it is shading the page it is about to land on.
    shadow(side < 0 and vs or rs, edge + side, side, lay.top, lay.h)

    love.graphics.setScissor()
end

return Spread
