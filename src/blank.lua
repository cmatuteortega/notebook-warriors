-- A page of the book with nothing on it yet: the library's shape
-- (src/library.lua) minus the catalogue, heading passed in. Nothing is
-- answered, so nothing is scribbled -- only the corner button presses, ink
-- anywhere else fades off. NOTHING INSTANCES IT TODAY; it is here for the next
-- tab that opens onto nothing, and a page that grows anything of its own
-- becomes its own module (the canteen did, src/canteen.lua).

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local I18n = require("src.i18n")

local Blank = {}
Blank.__index = Blank

local HEAD_SCALE = 2
local EDGE = 4
local HEAD_TOP = 10       -- the heading off the top of the page, the library's own
                          -- clearance
local HEAD_GAP = 6

-- The one thing every page this module draws has in common, so not an argument.
local SOON = "NOTHING HERE YET"

function Blank.new(head)
    return setmetatable({ head = head }, Blank)
end

function Blank:enter()
    self.t = 0
    self.back = false

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the tab that opened this page presses and draws
    -- nothing until it is lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- Nothing to walk, and the stick's corner is page like any other.
    Input.stickEnabled = false
end

-- Heading and its one line centred, corner button in the margin beside them.
-- If a narrow page or long heading would make the two meet, the title steps
-- down under the button, which is the one thing here that cannot move.
function Blank:layout(game)
    self.game = game

    local ins = game.inset
    local lay = {}
    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.w = game.vw - ins.l - ins.r - EDGE * 2

    local headW = Font.width(I18n.t(self.head)) * HEAD_SCALE
    local buttonRight = Hud.cornerBox(game) + Hud.CORNER_SIZE
    local underButton = Hud.cornerBottom(game) + EDGE
    lay.head = lay.cx - headW / 2 > buttonRight + EDGE
        and ins.t + HEAD_TOP
        or underButton

    lay.line = math.max(underButton, lay.head + Font.height * HEAD_SCALE + HEAD_GAP)

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function Blank:backAt(x, y)
    local bx, by, bw, bh = Hud.cornerTarget(self.game)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

-- Returns whether the stamp became ink, which is what fires the pen's swish
-- (src/scribble.lua): the corner button swallows what crosses it and lays no
-- line, so it must not sound like one.
function Blank:mark(x, y)
    if self:backAt(x, y) then return false end
    self.marks:add(x, y)
    return true
end

function Blank:press(x, y)
    if self:backAt(x, y) then self.back = true end
end

-- Returns "back" when the corner button is pressed, nothing otherwise: there is
-- no other way off this page.
function Blank:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.back then return "back" end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    if self.back then return "back" end
end

function Blank:keypressed(key)
    -- Backspace is the corner button, as on the timetable and in the library.
    if key == "backspace" then self.back = true end
end

--- draw ----------------------------------------------------------------------

function Blank:draw(game)
    local lay = self:layout(game)

    -- Written on the page, not over it: the ruling of the lesson you came in
    -- from shows through the lettering.
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    Scribble.printBig(I18n.t(self.head), lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    local soon = I18n.t(SOON)
    if Font.width(soon) <= lay.w then
        Scribble.printBig(soon, lay.cx, lay.line, 1, Palette.graphite, { seed = 61 })
    end

    Overprint.finish()

    -- Outside the overprint pass: a paper-filled box still pairs every inked
    -- border pixel with the page under it, so it reads as a transparency.
    Hud.drawCorner(game, "back", false)
end

return Blank
