-- The title screen.
--
-- Drawn on the page rather than over it. The paper pans underneath as if a
-- camera were following someone, a doodle of the player walks his own lap of it
-- with the same monsters the run spawns strung out behind him, and the title
-- writes itself on in the pencil you play with.
--
-- The choice is made the way everything else in this game is made: by drawing.
-- Scribble inside the YES box and the run starts, scribble inside NO and the
-- book closes. The boxes themselves -- what counts as an answer, and when it is
-- committed -- are src/scribble.lua, which the pause card asks with too.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Particles = require("src.particles")
local Enemy = require("src.enemy")
local Walls = require("src.walls")
local Tools = require("src.tools")
local Input = require("src.input")
local Scribble = require("src.scribble")
local util = require("src.util")

local Menu = {}

-- Every mark on this screen is a pencil mark, and fades down the real tool's
-- colour ramp rather than inventing a second way for ink to leave the page.
local PENCIL = Tools.list[1]

local TITLE_TOP, TITLE_BOTTOM = "NOTEBOOK", "WARRIORS"
local TITLE_SCALE, LABEL_SCALE = 3, 2

-- The intro writes itself on in order; all of these are seconds from entry.
local WRITE_STEP = 0.05   -- per letter of the title
local T_TITLE = 0.2
local T_RULE = T_TITLE + (#TITLE_TOP + #TITLE_BOTTOM) * WRITE_STEP + 0.08
local RULE_TIME = 0.3
local T_START = T_RULE + RULE_TIME
local T_BOXES = T_START + 0.22
local BOX_TIME = 0.4
local T_HINT = T_BOXES + BOX_TIME
local INTRO_END = T_HINT + 0.2

local CONFIRM_FLASH = 0.3 -- the picked box flashing on its own
local CONFIRM_OUT = 0.6   -- the page leaving, or the book closing

local DRIFT_X, DRIFT_Y = 11, 6 -- the page pans this many pixels a second
local LURE_RATE = 0.34         -- radians a second round its orbit
-- Wide enough that the lap goes round the outside of the title block rather
-- than through the middle of it, and clamped to the canvas so a phone in
-- portrait doesn't send him off the side of the page.
local LURE_RX, LURE_RY = 112, 62
local CRITTER_MAX = 7
local CRITTER_EVERY = 0.7
local CRITTER_START = 4        -- already on the page when the screen opens
local CRITTER_KINDS = { "blob", "blob", "bat", "skull" }

--- setup ---------------------------------------------------------------------

function Menu:enter()
    self.t = 0
    self.phase = "intro"  -- intro -> choosing -> confirm
    self.pending = nil    -- drawn in, waiting for the pen to come off the page
    self.chosen = nil
    self.confirmT = 0
    self.dither = 0

    self.scrollX, self.scrollY = 0, 0
    self.driftScale = 1
    self.lureAngle = 0
    self.lure = { x = 0, y = 0 }
    self.lureFlip = false

    self.particles = Particles.new()
    self.walls = Walls.new() -- nothing solid here, but Enemy expects to be asked
    self.critters = {}
    self.critterTimer = CRITTER_EVERY
    self.seeded = false -- the opening handful, dropped once the canvas is known

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)
    self.pen = Scribble.newPen()
    self.written = 0      -- letters of the title on the page so far

    self.choice = Scribble.newChoice({
        { key = "yes", label = "YES" },
        { key = "no", label = "NO" },
    }, LABEL_SCALE)
    self.boxes = self.choice.boxes

    -- The bottom-left corner belongs to the thumb stick during a run, but here
    -- it is page like any other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

-- Stacked top to bottom, then the whole stack is centred in the safe area, so
-- it lands right whatever shape of screen the canvas ended up being.
function Menu:layout(game)
    local ins = game.inset
    local titleH = Font.height * TITLE_SCALE
    local startH = Font.height * LABEL_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local lay, y = {}, 0
    lay.titleTop = y;    y = y + titleH + 3
    lay.titleBottom = y; y = y + titleH + 9
    lay.rule = y;        y = y + 3 + 9
    lay.start = y;       y = y + startH + 11
    lay.boxes = y;       y = y + Scribble.BOX_H + 10
    lay.hint = y;        y = y + hintH

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - y) / 2)
    for k, v in pairs(lay) do lay[k] = v + top end

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - startH) / 2)

    -- YES [] and NO [] laid out as one strip and centred under the title.
    self.choice:layout(lay.cx, lay.boxes)

    self.lay = lay
    return lay
end

--- the page underneath -------------------------------------------------------

function Menu:lurePos(game)
    -- A figure of eight rather than a circle: it reads as someone wandering the
    -- page rather than running a track, and it keeps doubling back through the
    -- horde trailing him.
    local rx = math.min(LURE_RX, game.vw * 0.36)
    local ry = math.min(LURE_RY, game.vh * 0.36)
    return self.scrollX + game.vw / 2 + math.cos(self.lureAngle) * rx,
           self.scrollY + game.vh / 2 + math.sin(self.lureAngle * 1.3) * ry
end

function Menu:spawnCritter(x, y)
    self.critters[#self.critters + 1] =
        Enemy.new(CRITTER_KINDS[love.math.random(#CRITTER_KINDS)], x, y)
end

function Menu:updateChase(dt, game)
    self.scrollX = self.scrollX + DRIFT_X * self.driftScale * dt
    self.scrollY = self.scrollY + DRIFT_Y * self.driftScale * dt
    self.lureAngle = self.lureAngle + LURE_RATE * dt

    self.lure.x, self.lure.y = self:lurePos(game)
    self.lureFlip = math.sin(self.lureAngle) > 0

    local cx = self.scrollX + game.vw / 2
    local cy = self.scrollY + game.vh / 2
    local ring = util.len(game.vw, game.vh) / 2

    -- The first few are already on his heels when the screen opens. Walking
    -- them in from the ring would take most of a minute at blob pace, and the
    -- title screen does not last a minute.
    if not self.seeded then
        self.seeded = true
        for _ = 1, CRITTER_START do
            local a = love.math.random() * math.pi * 2
            local r = 40 + love.math.random() * 70
            self:spawnCritter(self.lure.x + math.cos(a) * r, self.lure.y + math.sin(a) * r)
        end
    end

    self.critterTimer = self.critterTimer - dt
    if self.critterTimer <= 0 and #self.critters < CRITTER_MAX and self.phase ~= "confirm" then
        self.critterTimer = CRITTER_EVERY
        -- After that they come from off the edge of the page, like the
        -- spawner's ring, so nothing appears out of thin air on the title.
        local a = love.math.random() * math.pi * 2
        self:spawnCritter(cx + math.cos(a) * (ring + 16), cy + math.sin(a) * (ring + 16))
    end

    for i = #self.critters, 1, -1 do
        local e = self.critters[i]
        e:update(dt, self.lure, self.walls, nil)
        if util.len(e.x - cx, e.y - cy) > ring + 60 then
            table.remove(self.critters, i)
        end
    end

    -- With seven of them the n^2 pass is free, and without it the whole crowd
    -- converges into what looks like a single sprite.
    for i = 1, #self.critters do
        for j = i + 1, #self.critters do
            local a, b = self.critters[i], self.critters[j]
            local dx, dy = a.x - b.x, a.y - b.y
            local d2 = dx * dx + dy * dy
            local min = a.radius + b.radius
            if d2 > 0 and d2 < min * min then
                local d = math.sqrt(d2)
                local push = (min - d) * 0.5
                a.x, a.y = a.x + dx / d * push, a.y + dy / d * push
                b.x, b.y = b.x - dx / d * push, b.y - dy / d * push
            end
        end
    end
end

--- drawing on it -------------------------------------------------------------

-- Ink that lands in a box is the answer and is counted there (see
-- src/scribble.lua); ink that misses is just ink on the page, and fades.
--
-- `quiet` counts the mark without letting the box arm, which is what keeps the
-- keyboard shortcut's scribble on screen for its full length.
function Menu:mark(x, y, quiet)
    if self.phase == "choosing" and self.choice:mark(x, y, quiet) then
        self.pending = self.choice.armed
        return
    end

    self.marks:add(x, y)
end

function Menu:choose(box)
    if self.phase == "confirm" then return end
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
    self.particles:burst(box.x + box.w / 2, box.y + box.h / 2, 16,
        box.key == "yes" and Palette.red or Palette.slate)
end

-- The keyboard shortcut fills the box in rather than jumping past it: the box
-- still gets answered the only way a box here gets answered.
function Menu:autoFill(box)
    if self.phase == "choosing" then self.choice:autoFill(box) end
end

function Menu:updateScribble(dt)
    self.marks:update(dt)

    local filled = self.choice:update(dt)
    if filled then self:choose(filled) end

    -- Once the answer is in, the page stops taking ink: the screen is on its way
    -- off and a fresh scribble would be drawn onto something already leaving.
    local down = Input.pointerDown
    self.pen:track(down and self.phase ~= "confirm", Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end,
        function()
            -- Any press skips the intro straight to the boxes, and the press
            -- that skipped it still draws.
            if self.phase == "intro" then self:skip() end
        end)

    -- A box that has been drawn in is only armed, not answered. Nothing is
    -- committed until the pen comes off the page, so a line that carries on
    -- into the other box changes the answer rather than being too late, and
    -- you can see which one you are about to pick before you lift.
    if self.pending and not down then
        self:choose(self.pending)
    end
end

-- A little graphite puffs off each letter as it lands, so the title reads as
-- being written rather than switched on.
function Menu:updateWriting()
    local total = #TITLE_TOP + #TITLE_BOTTOM
    local target = util.clamp(math.floor((self.t - T_TITLE) / WRITE_STEP), 0, total)
    while self.written < target do
        self.written = self.written + 1
        local x, y = self:letterPos(self.written)
        self.particles:burst(x, y, 2, Palette.graphite)
    end
end

-- Centre of the nth letter of the title, counting straight through both lines.
function Menu:letterPos(n)
    local lay = self.lay
    local line, i, y = TITLE_TOP, n, lay.titleTop
    if n > #TITLE_TOP then
        line, i, y = TITLE_BOTTOM, n - #TITLE_TOP, lay.titleBottom
    end

    local x = lay.cx - Font.width(line) * TITLE_SCALE / 2
    return x + (i - 1) * Font.advance * TITLE_SCALE + TITLE_SCALE,
           y + Font.height * TITLE_SCALE / 2
end

function Menu:skip()
    self.t = math.max(self.t, INTRO_END)
    self.phase = "choosing"
end

--- update --------------------------------------------------------------------

-- Returns "yes" or "no" on the frame the choice finishes playing out, and
-- nothing at all until then.
function Menu:update(dt, game)
    self:layout(game)
    self.t = self.t + dt

    self:updateChase(dt, game)
    self:updateScribble(dt)
    self:updateWriting()
    self.particles:update(dt)

    if self.phase == "intro" and self.t >= INTRO_END then
        self.phase = "choosing"
    end

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt

        -- The box flashes on its own first, then the whole screen dithers off
        -- the page the way a mark does -- no alpha, so nothing blends into a
        -- ninth colour on the way out.
        local out = util.clamp((self.confirmT - CONFIRM_FLASH) / CONFIRM_OUT, 0, 1)
        self.dither = out
        if self.chosen.key == "yes" then
            -- YES pulls the page away into the run.
            self.driftScale = 1 + out * out * 34
        end

        if self.confirmT >= CONFIRM_FLASH + CONFIRM_OUT then
            return self.chosen.key
        end
    end
end

function Menu:keypressed(key)
    if self.phase == "confirm" then return end
    if self.phase == "intro" then self:skip() end

    if key == "y" or key == "return" or key == "kpenter" or key == "space" then
        self:autoFill(self.boxes[1])
    elseif key == "n" then
        self:autoFill(self.boxes[2])
    end
end

--- draw ----------------------------------------------------------------------

local function byDepth(a, b)
    return a.y < b.y
end

-- The player doodle, walking his own lap of the page. He is not a Player: there
-- is no health, nothing shoots, and the horde behind him never quite arrives.
function Menu:drawLure()
    local x, y = math.floor(self.lure.x), math.floor(self.lure.y)

    Sprites.shadow(Sprites.player, x, y)

    love.graphics.setColor(1, 1, 1)
    Sprites.player:draw(x, y - (math.floor(self.t * 7) % 2), self.lureFlip)
end

function Menu:drawChase()
    table.sort(self.critters, byDepth)

    local pending = true
    for _, e in ipairs(self.critters) do
        if pending and e.y > self.lure.y then
            self:drawLure()
            pending = false
        end
        e:draw()
    end
    if pending then self:drawLure() end
end

function Menu:draw(game)
    local lay = self:layout(game)
    local left, top = math.floor(self.scrollX), math.floor(self.scrollY)

    -- Menu and all: it is written on the page, not laid over it, so the whole
    -- screen goes through the overprint pass and the ruling shows through the
    -- title the same way it shows through a pencil line drawn mid-run.
    Overprint.beginPage()
    love.graphics.push()
    love.graphics.translate(-left, -top)
    Background.draw(left, top, game.vw, game.vh)
    love.graphics.pop()

    Overprint.beginInk()

    love.graphics.push()
    love.graphics.translate(-left, -top)
    self:drawChase()
    love.graphics.pop()

    -- From here down it is canvas space: the menu is pinned to the screen while
    -- the paper slides underneath it.
    self.marks:draw(self.dither)

    Scribble.printBig(TITLE_TOP, lay.cx, lay.titleTop, TITLE_SCALE, Palette.ink, {
        shadow = Palette.graphite, wobble = true, t = self.t, seed = 1,
        dither = self.dither, count = self.written,
    })
    Scribble.printBig(TITLE_BOTTOM, lay.cx, lay.titleBottom, TITLE_SCALE, Palette.red, {
        shadow = Palette.blush, wobble = true, t = self.t, seed = 2,
        dither = self.dither, count = self.written - #TITLE_TOP,
    })

    if self.t >= T_RULE then
        local n = math.floor(Font.width(TITLE_BOTTOM) * TITLE_SCALE + 6)
            * util.clamp((self.t - T_RULE) / RULE_TIME, 0, 1)
        local x0 = lay.cx - math.floor(Font.width(TITLE_BOTTOM) * TITLE_SCALE / 2) - 3
        love.graphics.setColor(Palette.slate)
        for i = 0, math.floor(n) do
            if self.dither == 0 or util.hash01(i, self.seed, 31) > self.dither then
                Scribble.stamp({
                    x = x0 + i,
                    y = lay.rule + math.floor(math.sin(i * 0.07) * 1.5),
                    i = i,
                }, self.seed)
            end
        end
    end

    if self.t >= T_START then
        -- Asking, in a hand that can't keep still.
        local pulse = math.sin(self.t * 3.4) > 0
        Scribble.printBig("START?", lay.cx, lay.start, LABEL_SCALE,
            pulse and Palette.ink or Palette.slate,
            { wobble = true, t = self.t, seed = 7, dither = self.dither })
    end

    if self.t >= T_BOXES then
        local progress = util.clamp((self.t - T_BOXES) / BOX_TIME, 0, 1)

        for i, box in ipairs(self.boxes) do
            local color = Scribble.boxColor(box, self.chosen, self.confirmT)

            Scribble.printBig(box.label, box.labelCx, lay.labelY, LABEL_SCALE, color,
                { wobble = true, t = self.t, seed = 30 + i * 5, dither = self.dither })
            Scribble.drawBox(box, progress, color, 10 + i, self.dither)
            -- Ink inside a box is the answer, and does not fade.
            Scribble.drawMarks(box.marks, PENCIL.ramp[1], self.seed, self.dither)
        end
    end

    if self.t >= T_HINT then
        -- Once a box is armed the line underneath says what it is waiting for,
        -- which is the only warning that lifting is what commits it.
        local armed = self.pending ~= nil
        local prompt = "SCRIBBLE IN A BOX"
        if armed then
            prompt = Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
        end

        Scribble.printBig(prompt, lay.cx, lay.hint, 1, armed and Palette.red or Palette.slate,
            { seed = 51, dither = self.dither })
        if not Input.usingTouch and not armed then
            Scribble.printBig("OR PRESS Y OR N", lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52, dither = self.dither })
        end
    end

    self.particles:draw()

    Overprint.finish()
end

return Menu
