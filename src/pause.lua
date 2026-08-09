-- The pause screen.
--
-- Holding the run puts a question on the page, and it is asked the way the
-- title screen asks its own: a box you scribble in (src/scribble.lua). QUIT?
-- YES or NO. Drawing in YES closes the run and hands the page back to the title
-- screen; drawing in NO lets it go again, and so does the button in the corner.
--
-- It is written on the page rather than laid over it -- no panel, no card, just
-- lettering and two boxes -- so the frozen run shows through and the whole page
-- stays drawable. Ink that misses the boxes is not an answer, just ink, and
-- fades off exactly as it does on the title screen.

local Palette = require("src.palette")
local Font = require("src.font")
local Input = require("src.input")
local Scribble = require("src.scribble")
local util = require("src.util")

local Pause = {}
Pause.__index = Pause

local HEAD, TITLE = "PAUSED", "QUIT?"
local LABEL_SCALE = 2
local BOX_TIME = 0.25  -- the boxes drawing themselves on as the question opens
local CONFIRM = 0.32   -- the answered box flashing before the answer takes hold

function Pause.new()
    local self = setmetatable({}, Pause)
    self:open()
    return self
end

-- Every pause is a fresh question: ink drawn into a box last time is not still
-- sitting there deciding this one.
function Pause:open()
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer already down when the run was held -- a pen mid-stroke, or the
    -- other hand still on the page -- is not a press of this screen. Only one
    -- that arrives after it counts.
    self.pen = Scribble.newPen(Input.pointerDown)

    self.choice = Scribble.newChoice({
        { key = "yes", label = "YES" },
        { key = "no", label = "NO" },
    }, LABEL_SCALE)
end

-- The line under the boxes says what the screen is waiting for, which is the
-- only warning that lifting is what commits an answer.
function Pause:prompt()
    if self.choice.armed then
        return Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    end
    return "SCRIBBLE IN A BOX"
end

-- Stacked top to bottom, then centred in the safe area, so it lands right on
-- whatever shape of screen the canvas ended up being.
function Pause:layout(game)
    local ins = game.inset
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local lay, y = {}, 0
    lay.head = y;  y = y + Font.height + 5
    lay.title = y; y = y + Font.height * LABEL_SCALE + 9
    lay.boxes = y; y = y + Scribble.BOX_H + 9
    lay.hint = y;  y = y + hintH

    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - y) / 2)
    lay.head = lay.head + top
    lay.title = lay.title + top
    lay.boxes = lay.boxes + top
    lay.hint = lay.hint + top

    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.labelY = lay.boxes + math.floor((Scribble.BOX_H - Font.height * LABEL_SCALE) / 2)

    self.choice:layout(lay.cx, lay.boxes)

    self.lay = lay
    return lay
end

function Pause:commit(box)
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses
-- is just ink on the page.
function Pause:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

--- update --------------------------------------------------------------------

-- Returns "quit" or "resume" on the frame the answer lands, and nothing at all
-- until then.
function Pause:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then
            return self.chosen.key == "yes" and "quit" or "resume"
        end
        return
    end

    -- The keyboard fills a box in rather than jumping past it, and there is no
    -- pen to lift, so that answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    local down = Input.pointerDown
    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end)

    -- Armed, not answered: nothing is committed until the pen comes off the
    -- page, so a line that carries on into the other box changes the answer
    -- rather than being too late.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function Pause:keypressed(key)
    if self.phase ~= "asking" then return end

    if key == "y" then
        self.choice:autoFill(self.choice.boxes[1])
    elseif key == "n" then
        self.choice:autoFill(self.choice.boxes[2])
    end
end

--- draw ----------------------------------------------------------------------

function Pause:draw(game)
    local lay = self:layout(game)

    self.marks:draw(0)

    love.graphics.setColor(Palette.slate)
    Font.printCentered(HEAD, lay.cx, lay.head)

    -- Asking, in a hand that can't keep still. Everything here is drawn over a
    -- page with a horde standing on it, so the lettering carries a shadow the
    -- title screen's own asking doesn't need.
    local pulse = math.sin(self.t * 3.4) > 0
    Scribble.printBig(TITLE, lay.cx, lay.title, LABEL_SCALE,
        pulse and Palette.ink or Palette.slate,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 7 })

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)
    for i, box in ipairs(self.choice.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)

        Scribble.printBig(box.label, box.labelCx, lay.labelY, LABEL_SCALE, color,
            { shadow = Palette.paper, wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    -- Once the answer is in, the line has nothing left to ask for: the box
    -- flashing on its own is the whole of the feedback.
    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil

        Scribble.printBig(self:prompt(), lay.cx, lay.hint, 1,
            armed and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not armed then
            Scribble.printBig("OR PRESS Y OR N", lay.cx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
        end
    end
end

return Pause
