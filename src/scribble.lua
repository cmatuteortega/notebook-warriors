-- The way this game asks a question: you draw the answer.
--
-- Every question here is a *box you scribble in* -- the title screen asks
-- whether to start, the pause card whether to quit, and the draft you get for
-- levelling up (src/levelup.lua) puts one under each of its three cards. What
-- counts is ground covered inside the box, on a 2px grid, so a line drawn
-- through it answers while a graze does not.
--
-- The answer is only *armed*, not committed, until the pen comes off the page
-- -- so a line that carries on into the next one changes the answer rather
-- than being too late -- and the lettering and the borders are drawn by hand,
-- which here means redrawn a few times a second so they never quite sit still.
-- Nothing in here knows what any answer means: it reports which one is armed
-- and leaves the rest to the screen that asked.

local Font = require("src.font")
local Palette = require("src.palette")
local Tools = require("src.tools")
local util = require("src.util")

local Scribble = {}

-- Ink laid down while answering is pencil, and fades down the real tool's
-- colour ramp rather than inventing a second way for ink to leave the page.
local PENCIL = Tools.list[1]

Scribble.BOX_W, Scribble.BOX_H = 26, 20
Scribble.LABEL_GAP = 4    -- between a label and its box
Scribble.CARD_GAP = 18    -- between one labelled box and the next

local BOX_PAD = 3         -- ink this close to the border doesn't count as fill
local COVER_CELL = 2      -- ink is counted on a 2px grid inside the box
local COVER_MIN = 6       -- cells that have to be marked to answer it: a line
                          -- through the box, not a whole box filled in
local AUTO_ROWS = 6       -- sweeps in the scribble the keyboard draws for you
local AUTO_TIME = 0.4
local WOBBLE_FPS = 7      -- how often a hand-drawn line is redrawn

local WARM_WARM = 0.25    -- fill at which the border turns blue
local WARM_HOT = 0.6      -- and then red
local CONFIRM_FPS = 18    -- flashes a second while the answer registers

local MARK_LIFE = 1.6     -- ink that missed the boxes fades off the page
local MARK_DITHER = 0.55
local MARK_MAX = 1200

--- hand-drawn lines ----------------------------------------------------------

-- Everything drawn this way wanders a pixel and re-wanders a few times a
-- second. That is what a line looks like when it is drawn again by hand for
-- every frame of an animation, rather than drawn once and moved about.
function Scribble.wobbleAt(seed, t)
    local frame = math.floor(t * WOBBLE_FPS)
    local a = util.hash01(seed, frame, 5)
    local b = util.hash01(seed, frame, 6)
    return (a < 0.17 and -1 or (a > 0.83 and 1 or 0)),
           (b < 0.17 and -1 or (b > 0.83 and 1 or 0))
end

-- The 3x5 glyphs are sized for the HUD and far too small for a title, so they
-- are blown up by a whole number -- the same trick main.lua plays on the whole
-- canvas, for the same reason: the letters stay on the pixel grid.
--
-- opts: shadow (colour, offset one pixel), wobble, t, seed, dither, count.
function Scribble.printBig(text, cx, y, s, color, o)
    local seed, t = o.seed or 0, o.t or 0
    local dither = o.dither or 0
    local n = math.min(#text, o.count or #text)
    local x = math.floor(cx - Font.width(text) * s / 2)
    y = math.floor(y)

    for i = 1, n do
        if dither == 0 or util.hash01(i, seed, 31) > dither then
            local dx, dy = 0, 0
            if o.wobble then dx, dy = Scribble.wobbleAt(seed + i, t) end

            local gx = x + (i - 1) * Font.advance * s + dx
            local ch = text:sub(i, i)

            if o.shadow then
                love.graphics.push()
                love.graphics.translate(gx + 1, y + dy + 1)
                love.graphics.scale(s, s)
                love.graphics.setColor(o.shadow)
                Font.print(ch, 0, 0)
                love.graphics.pop()
            end

            love.graphics.push()
            love.graphics.translate(gx, y + dy)
            love.graphics.scale(s, s)
            love.graphics.setColor(color)
            Font.print(ch, 0, 0)
            love.graphics.pop()
        end
    end
end

-- The nib that answers a question is blunter than the one you play with. A 1px
-- line reads as a hairline against 3x lettering and a two-pixel border -- like
-- a crack rather than something drawn -- so the core is 2px square, with the
-- pencil's own ragged extra pixel riding alongside it.
function Scribble.stamp(m, seed)
    love.graphics.rectangle("fill", m.x, m.y, 2, 2)

    local r = util.hash01(m.i, seed, 11)
    if r > 0.55 then
        local a = util.hash01(m.i, seed, 12)
        love.graphics.rectangle("fill",
            m.x + (a < 0.5 and -1 or 2),
            m.y + (r > 0.8 and 1 or 0), 1, 1)
    end
end

-- A run of stamps in one colour. Ink inside a box doesn't fade, so this is the
-- whole of drawing an answer.
function Scribble.drawMarks(list, color, seed, dither)
    love.graphics.setColor(color)
    for _, m in ipairs(list) do
        if dither == 0 or util.hash01(m.i, seed, 31) > dither then
            Scribble.stamp(m, seed)
        end
    end
end

-- The border, walked a pixel at a time from the top-left corner, so it can be
-- drawn on progressively: one side after another, the way you would draw it.
-- Returns the point and the outward normal of the side it is on.
local function perimeterAt(x, y, w, h, i)
    if i < w then return x + i, y, 0, -1 end
    i = i - w
    if i < h - 1 then return x + w - 1, y + 1 + i, 1, 0 end
    i = i - (h - 1)
    if i < w - 1 then return x + w - 2 - i, y + h - 1, 0, 1 end
    return x, y + h - 2 - (i - (w - 1)), -1, 0
end

-- The boxes are the one thing on a screen like this that holds still. They are
-- drawn wonky -- two waves down each side, snapped to a whole pixel, so the line
-- drifts off true and comes back the way a hand-drawn one does -- but the wonk
-- is the same every frame. They are what you are aiming at, and something you
-- are aiming at should not be moving.
function Scribble.drawBox(box, progress, color, seed, dither)
    love.graphics.setColor(color)

    local total = 2 * box.w + 2 * box.h - 4
    local n = math.floor(total * util.clamp(progress, 0, 1))

    for i = 0, n - 1 do
        if dither == 0 or util.hash01(i, seed, 31) > dither then
            local px, py, nx, ny = perimeterAt(box.x, box.y, box.w, box.h, i)
            local wave = math.sin(i * 0.23 + seed) + 0.6 * math.sin(i * 0.11 + seed * 3)
            local off = wave > 0.8 and 1 or (wave < -0.8 and -1 or 0)
            px, py = px + nx * off, py + ny * off

            -- Two pixels of line, the second laid inwards, so a heavier border
            -- doesn't grow the box.
            love.graphics.rectangle("fill", px, py, 1, 1)
            love.graphics.rectangle("fill", px - nx, py - ny, 1, 1)
        end
    end
end

-- What a box's border says about where the answer has got to, which is the same
-- thing on every screen that asks: the border warms slate -> blue -> red as the
-- box fills, so you can see the answer coming, and the one that was chosen
-- flashes while it registers while the other goes grey and steps out of it.
--
-- `chosen` is the box that was answered, or nil while the question is still
-- open, and `confirmT` is how long it has been answered for.
function Scribble.boxColor(box, chosen, confirmT)
    if chosen then
        if chosen ~= box then return Palette.graphite end
        return math.floor(confirmT * CONFIRM_FPS) % 2 == 0 and Palette.red or Palette.ink
    end

    if box.fill >= WARM_HOT then return Palette.red end
    if box.fill >= WARM_WARM then return Palette.blue end
    return Palette.slate
end

-- Stamps laid one pixel apart along the segment the pointer covered, exactly as
-- a real stroke lays them, so a fast scribble is a line and not a row of dots.
-- Returns the carry into the next segment.
local function walkSegment(x0, y0, x1, y1, carry, fn)
    local dx, dy = x1 - x0, y1 - y0
    local dist = util.len(dx, dy)
    if dist == 0 then return carry end

    local nx, ny = dx / dist, dy / dist
    local d = carry
    while d <= dist do
        fn(x0 + nx * d, y0 + ny * d)
        d = d + 1
    end
    return d - dist
end

--- the pen ------------------------------------------------------------------

-- The pointer, turned into a line. Every screen that asks a question is also a
-- page you can draw the rest of, so all of them do the same thing with it: lay
-- a stamp on the press, join each frame's position to the last one, and carry
-- the leftover distance across so the spacing stays even.
--
-- The press edge is the interesting one, which is why it gets a callback of its
-- own. What is latched there is latched for the whole stroke: the studio decides
-- on the press whether a stroke is drawing on the board or on the page around
-- it, and a stroke aimed at OK! that overshoots must not cost your hero a leg.
local Pen = {}
Pen.__index = Pen

-- `down` seeds the pen's idea of the pointer. A screen that opens with one
-- already down -- the studio, opened by the scribble that answered the title
-- screen -- passes true, so that press is not read as a press of this screen.
function Scribble.newPen(down)
    return setmetatable({ down = down or false, x = 0, y = 0, carry = 0 }, Pen)
end

-- `mark(x, y)` for every stamp, `press(x, y)` first if this is the press edge.
function Pen:track(down, x, y, mark, press)
    if down then
        if not self.down then
            self.x, self.y, self.carry = x, y, 0
            if press then press(x, y) end
            mark(x, y)
        end

        self.carry = walkSegment(self.x, self.y, x, y, self.carry, mark)
        self.x, self.y = x, y
    end
    self.down = down
end

--- ink that missed -----------------------------------------------------------

-- You can draw anywhere on a screen that is asking you something -- it is a
-- page like any other -- and what misses the boxes is not an answer, just ink.
-- It fades off in its own time, and dithers away rather than going transparent,
-- so nothing blends into a ninth colour on the way out.
local Marks = {}
Marks.__index = Marks

function Scribble.newMarks(seed)
    return setmetatable({ list = {}, seed = seed, index = 0 }, Marks)
end

function Marks:add(x, y)
    self.index = self.index + 1
    self.list[#self.list + 1] =
        { x = math.floor(x), y = math.floor(y), i = self.index, age = 0 }
    if #self.list > MARK_MAX then table.remove(self.list, 1) end
end

function Marks:update(dt)
    for i = #self.list, 1, -1 do
        local m = self.list[i]
        m.age = m.age + dt
        if m.age > MARK_LIFE then table.remove(self.list, i) end
    end
end

function Marks:draw(dither)
    local ramp = PENCIL.ramp
    local last

    for _, m in ipairs(self.list) do
        local f = m.age / MARK_LIFE
        local color = ramp[math.min(#ramp, math.floor(f * #ramp) + 1)]

        local drop = dither or 0
        if f > MARK_DITHER then
            drop = math.max(drop, (f - MARK_DITHER) / (1 - MARK_DITHER))
        end

        if drop == 0 or util.hash01(m.i, self.seed, 31) > drop then
            if color ~= last then
                love.graphics.setColor(color)
                last = color
            end
            Scribble.stamp(m, self.seed)
        end
    end
end

--- the question --------------------------------------------------------------

local Choice = {}
Choice.__index = Choice

-- defs: { { key = "yes", label = "YES" }, ... }, laid out left to right as one
-- strip of `LABEL [box]` pairs. A def may leave `label` out when the screen
-- places its boxes itself (`place`) under things that already say what they
-- are, the way the draft's cards do.
function Scribble.newChoice(defs, labelScale)
    local self = setmetatable({
        boxes = {},
        labelScale = labelScale,
        armed = nil,   -- drawn in, waiting for the pen to come off the page
        index = 0,
    }, Choice)

    for i, def in ipairs(defs) do
        self.boxes[i] = {
            key = def.key,
            label = def.label,
            w = Scribble.BOX_W,
            h = Scribble.BOX_H,
            marks = {}, cover = {}, covered = 0, fill = 0,
        }
    end

    return self
end

function Choice:stripWidth()
    local w = -Scribble.CARD_GAP
    for _, box in ipairs(self.boxes) do
        w = w + Font.width(box.label) * self.labelScale
              + Scribble.LABEL_GAP + box.w + Scribble.CARD_GAP
    end
    return w
end

-- The window can change shape mid-question -- a phone rotating, or a desktop
-- window dragged narrow enough to rearrange the studio -- so ink already inside
-- a box comes along with it when the box moves.
local function moveBox(box, nx, ny)
    if box.x and (box.x ~= nx or box.y ~= ny) then
        local dx, dy = nx - box.x, ny - box.y
        for _, m in ipairs(box.marks) do m.x, m.y = m.x + dx, m.y + dy end
    end
    box.x, box.y = nx, ny
end

-- Strung out left to right and centred on cx, with the box tops at y.
function Choice:layout(cx, y)
    local x = math.floor(cx - self:stripWidth() / 2)

    for _, box in ipairs(self.boxes) do
        box.labelW = Font.width(box.label) * self.labelScale
        box.labelCx = x + box.labelW / 2

        moveBox(box, x + box.labelW + Scribble.LABEL_GAP, y)
        x = box.x + box.w + Scribble.CARD_GAP
    end
end

-- The width a column of these needs, so a screen can size the column it is
-- putting them in before it lays them out.
function Choice:columnWidth()
    local labelW = 0
    for _, box in ipairs(self.boxes) do
        labelW = math.max(labelW, Font.width(box.label) * self.labelScale)
    end
    return labelW + Scribble.LABEL_GAP + Scribble.BOX_W
end

-- The same pair stacked instead of strung out, for a screen with a column to
-- put them in rather than a line. Labels are set flush against the boxes so the
-- boxes line up under one another whatever their labels are.
function Choice:layoutColumn(x, y, gap)
    local labelW = 0
    for _, box in ipairs(self.boxes) do
        labelW = math.max(labelW, Font.width(box.label) * self.labelScale)
    end

    for i, box in ipairs(self.boxes) do
        box.labelW = Font.width(box.label) * self.labelScale
        box.labelCx = x + labelW - box.labelW / 2

        moveBox(box, x + labelW + Scribble.LABEL_GAP, y + (i - 1) * (box.h + gap))
    end
end

-- One box, put exactly where the screen wants it -- for a box that belongs to
-- something laid out elsewhere, like the one under each of the draft's cards,
-- rather than to a strip or a column of its own.
function Choice:place(box, x, y)
    moveBox(box, math.floor(x), math.floor(y))
end

function Choice:boxAt(x, y)
    for _, box in ipairs(self.boxes) do
        if box.x
            and x >= box.x + BOX_PAD and x <= box.x + box.w - BOX_PAD - 1
            and y >= box.y + BOX_PAD and y <= box.y + box.h - BOX_PAD - 1 then
            return box
        end
    end
end

-- Lays a stamp and counts the ground it covered, returning the box it landed
-- in or nil for a mark that missed every box -- which is the caller's to keep
-- or throw away. `quiet` counts without letting the box arm, which is what
-- keeps the keyboard's scribble on screen for its full length instead of
-- arming a fiftieth of the way into it.
function Choice:mark(x, y, quiet)
    x, y = math.floor(x), math.floor(y)

    local box = self:boxAt(x, y)
    if not box then return nil end

    self.index = self.index + 1
    box.marks[#box.marks + 1] = { x = x, y = y, i = self.index }

    -- Measured from the padded corner rather than the box's, so the grid lines
    -- up with the area that can actually be drawn in.
    local key = math.floor((y - box.y - BOX_PAD) / COVER_CELL) * 64
              + math.floor((x - box.x - BOX_PAD) / COVER_CELL)
    if not box.cover[key] then
        box.cover[key] = true
        box.covered = box.covered + 1
        box.fill = math.min(1, box.covered / COVER_MIN)
        -- The last box drawn in wins, so a stroke that runs on into the other
        -- one changes its mind.
        if box.fill >= 1 and not quiet then self.armed = box end
    end

    return box
end

-- Wipes the ink back out of a box so it can be answered again. For a box that
-- does something to the screen it is on rather than closing it -- the studio's
-- RESET -- which has to be answerable twice.
function Choice:clear(box)
    box.marks, box.cover = {}, {}
    box.covered, box.fill, box.auto = 0, 0, nil
    if self.armed == box then self.armed = nil end
end

-- Where the scribble goes when the keyboard answers: a zigzag across the inside
-- of the box, given as a position for u in 0..1.
local function autoPoint(box, u)
    local ix, iy = box.x + BOX_PAD, box.y + BOX_PAD
    local iw, ih = box.w - BOX_PAD * 2 - 1, box.h - BOX_PAD * 2 - 1

    local p = u * AUTO_ROWS
    local row = math.floor(p)
    local f = p - row
    if row % 2 == 1 then f = 1 - f end

    return ix + f * iw, iy + u * ih
end

-- The keyboard shortcut fills the box in rather than jumping past it: the box
-- still gets answered the only way a box here gets answered.
function Choice:autoFill(box)
    if not box.auto then box.auto = 0 end
end

-- Runs the keyboard's scribble on. Returns the box it finishes filling, which
-- is answered outright: there is no pen to lift, so there is nothing to wait
-- for.
function Choice:update(dt)
    local done
    for _, box in ipairs(self.boxes) do
        if box.auto and box.auto < 1 then
            local from = box.auto
            box.auto = math.min(1, box.auto + dt / AUTO_TIME)

            local steps = math.max(1, math.ceil((box.auto - from) * 120))
            for s = 1, steps do
                local mx, my = autoPoint(box, from + (box.auto - from) * (s / steps))
                self:mark(mx, my, true)
            end

            if box.auto >= 1 then done = box end
        end
    end
    return done
end

return Scribble
