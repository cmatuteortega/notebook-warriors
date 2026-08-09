-- The drawing board, between answering the title screen and the run starting.
--
-- You are handed a stick man on a board, a pencil and a rubber, and whatever you
-- leave on the board is the sprite you play as. The board *is* the sprite, one
-- cell per pixel, blown up by a whole number the way main.lua blows up the whole
-- canvas -- so there is nothing between what you draw and what walks onto the
-- page a second later. The life-size copy standing in the margin is the same
-- sprite at 1:1, which is the only honest preview of a character fifteen pixels
-- across.
--
-- The board is the biggest thing on the screen and everything else is set beside
-- it in a column: the title, the copy, the boxes, the line saying what the
-- screen is waiting for. The tools are pinned to the right edge of the safe area
-- on the run's own margin, in the run's own box, popping out the same way when
-- selected -- the tools are in the same place on the page whether you are
-- drawing the hero or playing him, so there is only one spot to reach for. When
-- there is not enough width for a column beside the board -- a phone held
-- upright -- the column goes above and below it instead, and the board keeps its
-- size.
--
-- It asks to be finished the way every other screen here asks anything: a box
-- you scribble in (src/scribble.lua). OK! starts the run with what is on the
-- board; RESET puts the stick man back. Ink that lands outside the board and
-- outside the boxes is not part of the drawing -- it is just ink on the page,
-- and fades off it.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Particles = require("src.particles")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hero = require("src.hero")
local util = require("src.util")

local Studio = {}

local TITLE = { "DRAW YOUR", "HERO" }
local TITLE_SCALE, LABEL_SCALE = 2, 2

-- Every line that can appear under the boxes. Listed so the column can be made
-- wide enough for the longest of them before any of them is chosen, rather than
-- changing width when the prompt changes.
local HINT_IDLE = "SCRIBBLE OK! TO PLAY"
local HINT_EMPTY = "DRAW SOMETHING FIRST"
local HINT_LIFT = "LIFT TO CONFIRM"
local HINT_RELEASE = "RELEASE TO CONFIRM"
local HINT_KEYS = "OR PRESS ENTER"
local HINTS = { HINT_IDLE, HINT_EMPTY, HINT_LIFT, HINT_RELEASE, HINT_KEYS }

-- The board takes whatever is left over once everything else has had its share
-- of the canvas, on a whole-number zoom, between these.
local MIN_ZOOM, MAX_ZOOM = 4, 12
-- Below this the board is too cramped to draw on with a finger, and the column
-- is better off above and below it than beside it.
local BESIDE_MIN = 6

-- The tool buttons, in the run's own geometry: same size box, same margin off
-- the right edge of the safe area, same slide-out on the selected one. See
-- SEL_SIZE, SEL_GAP, SEL_MARGIN and SEL_POP in src/hud.lua.
local BTN, BTN_GAP = 13, 3
local TOOL_MARGIN, TOOL_POP = 4, 3
local TOOL_GAP = 8 -- clearance between the tools and everything else

local BTN_INSET = 6 -- between the board and the copy standing beside it
local COL_GAP = 10  -- between the column and the board
local BOX_GAP = 5   -- between one labelled box and the next, stacked
local EDGE = 4      -- the board's own margin off the safe area

local BOARD_PAD = 2   -- between the drawing area and its border
local BOX_TIME = 0.3  -- the board and the boxes drawing themselves on
local CONFIRM = 0.32  -- the answered box flashing before the run starts

local TOOLS = {
    { icon = "pencil", ch = Hero.PENCIL },
    { icon = "rubber", ch = Hero.BLANK },
}

-- The board is a whole number of cells plus the last line of the lattice, which
-- closes the right and bottom edges of it.
local function boardW(zoom) return Hero.W * zoom + 1 end
local function boardH(zoom) return Hero.H * zoom + 1 end

--- setup ----------------------------------------------------------------------

function Studio:enter()
    self.t = 0
    self.phase = "drawing" -- drawing -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.tool = 1

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)
    self.particles = Particles.new()

    -- A pointer already down when the screen opened -- the one that answered
    -- the title screen -- is not a press of this one.
    self.wasDown = Input.pointerDown
    self.mode = nil
    self.carry = 0
    self.lastX, self.lastY = 0, 0

    self.choice = Scribble.newChoice({
        { key = "ok", label = "OK!" },
        { key = "reset", label = "RESET" },
    }, LABEL_SCALE)
    self.boxes = self.choice.boxes

    -- Nothing to walk here, and the stick's corner is page like any other: you
    -- have to be able to scribble anywhere.
    Input.stickEnabled = false
end

--- layout ---------------------------------------------------------------------

-- Wide enough for the longest thing that can ever appear in it, so nothing in
-- the column moves sideways while the screen is up.
function Studio:columnWidth()
    local w = self.choice:columnWidth()
    for _, line in ipairs(TITLE) do
        w = math.max(w, Font.width(line) * TITLE_SCALE)
    end
    for _, line in ipairs(HINTS) do
        w = math.max(w, Font.width(line))
    end
    return w
end

-- The column's own stack, top to bottom, measured from its top. Both
-- arrangements use it: beside the board it is a column, above and below the
-- board it is the same pieces with the board spliced into the middle.
function Studio:columnStack()
    local titleH = Font.height * TITLE_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    local boxesH = #self.boxes * Scribble.BOX_H + (#self.boxes - 1) * BOX_GAP

    local s, y = {}, 0
    s.title = y;   y = y + titleH + 3
    s.title2 = y;  y = y + titleH + 9
    s.preview = y; y = y + Hero.H + 2 + 10
    s.boxes = y;   y = y + boxesH + 9
    s.hint = y;    y = y + hintH
    s.height = y

    return s
end

function Studio:layoutBeside(lay, ins, inner, availH)
    local zoom = math.min(
        math.floor((availH - EDGE * 2 - 1) / Hero.H),
        math.floor((inner - lay.colW - COL_GAP - BOARD_PAD - 1) / Hero.W))
    lay.zoom = util.clamp(zoom, MIN_ZOOM, MAX_ZOOM)

    local s = self:columnStack()
    local bh = boardH(lay.zoom)
    local total = math.max(s.height, bh)

    local top = math.floor(ins.t + (availH - total) / 2)
    local colTop = top + math.floor((total - s.height) / 2)

    lay.board = top + math.floor((total - bh) / 2)

    -- Pushed as far right as the tools allow rather than centred against the
    -- column. The board is a fixed size once the zoom is picked, so the width
    -- left over is the column's to have: sat in the middle it would leave the
    -- slack split between the page margin and the gap to the tools, where it is
    -- doing nothing, instead of around the writing, where it reads. BOARD_PAD is
    -- the border the board draws outside itself, which has to clear the tools.
    lay.bx = ins.l + inner - boardW(lay.zoom) - BOARD_PAD

    -- Rounded up, not down. When the board has taken all it can the column is
    -- left exactly as wide as its widest line, and printBig floors the corner it
    -- starts from -- so centring the other way puts that line a pixel off the
    -- edge of the page.
    lay.textCx = ins.l + math.ceil((lay.bx - COL_GAP - ins.l) / 2)
    lay.title = colTop + s.title
    lay.title2 = colTop + s.title2
    lay.previewX = lay.textCx
    lay.previewY = colTop + s.preview + math.floor((Hero.H + 2) / 2)
    lay.hint = colTop + s.hint

    self.choice:layoutColumn(
        lay.textCx - math.floor(self.choice:columnWidth() / 2), colTop + s.boxes, BOX_GAP)
end

-- No column to spare: the same pieces run down the middle with the board
-- spliced in, and the copy stands in the margin beside it.
function Studio:layoutStacked(lay, ins, inner, availH)
    local titleH = Font.height * TITLE_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    -- The stack without the board: two title lines, one row of boxes, the hint.
    local chrome = titleH * 2 + 3 + 6 + 7 + Scribble.BOX_H + 7 + hintH + 1

    -- Kept clear either side of the board so it stays centred on what is left
    -- of the width, with room for the copy on one of them.
    local margin = Hero.W + BTN_INSET

    local zoom = math.min(
        math.floor((availH - chrome) / Hero.H),
        math.floor((inner - margin * 2 - 1) / Hero.W))
    lay.zoom = util.clamp(zoom, MIN_ZOOM, MAX_ZOOM)

    local y = 0
    local title = y;  y = y + titleH + 3
    local title2 = y; y = y + titleH + 6
    local board = y;  y = y + boardH(lay.zoom) + 7
    local boxes = y;  y = y + Scribble.BOX_H + 7
    local hint = y;   y = y + hintH

    local top = math.floor(ins.t + (availH - y) / 2)

    lay.textCx = math.floor(ins.l + inner / 2)
    lay.title = top + title
    lay.title2 = top + title2
    lay.board = top + board
    lay.hint = top + hint
    lay.bx = math.floor(lay.textCx - boardW(lay.zoom) / 2)

    -- The copy stands in the margin the board left, on the far side from the
    -- tools so it is never crowded by them.
    lay.previewX = lay.bx - BTN_INSET - math.floor(Hero.W / 2)
    lay.previewY = lay.board + math.floor(boardH(lay.zoom) / 2)

    self.choice:layout(lay.textCx, top + boxes)
end

-- Beside the board when there is width for a column that still leaves the board
-- something worth drawing on, and above and below it when there is not.
function Studio:layout(game)
    local ins = game.inset
    local availH = game.vh - ins.t - ins.b

    local lay = { colW = self:columnWidth() }

    -- The tools are placed first and off the screen rather than off the board,
    -- exactly as the run places its selector, and everything else shares what
    -- is left of the width.
    local total = #TOOLS * (BTN + BTN_GAP) - BTN_GAP
    lay.btnX = game.vw - ins.r - TOOL_MARGIN - BTN
    lay.btnTop = math.floor(ins.t + availH / 2 - total / 2)

    local inner = lay.btnX - TOOL_POP - TOOL_GAP - ins.l

    lay.beside = inner - lay.colW - COL_GAP - BOARD_PAD - 1 >= Hero.W * BESIDE_MIN + 1
    if lay.beside then
        self:layoutBeside(lay, ins, inner, availH)
    else
        self:layoutStacked(lay, ins, inner, availH)
    end

    self.lay = lay
    return lay
end

--- what is under the pointer --------------------------------------------------

-- The cell a canvas-space point lands on, or nil for a point off the board.
function Studio:cellAt(x, y)
    local lay = self.lay
    if not lay then return nil end

    local gx = math.floor((x - lay.bx) / lay.zoom) + 1
    local gy = math.floor((y - lay.board) / lay.zoom) + 1
    if gx < 1 or gx > Hero.W or gy < 1 or gy > Hero.H then return nil end
    return gx, gy
end

function Studio:buttonPos(i, selected)
    return self.lay.btnX - (selected and TOOL_POP or 0),
           self.lay.btnTop + (i - 1) * (BTN + BTN_GAP)
end

-- Which tool, if any, a press lands on. Tested exactly as the run tests its
-- selector: the strip is one continuous column rather than separate boxes, so a
-- press in the gap picks one instead of doing nothing, and there is no bound on
-- the far side -- the column is against the edge of the screen, and everything
-- out that way belongs to it.
function Studio:buttonAt(cx, cy)
    local lay = self.lay
    if not lay then return nil end

    local padX, padY = 4, 2
    if Input.usingTouch then padX, padY = 11, 6 end
    if cx < lay.btnX - TOOL_POP - padX then return nil end

    local total = #TOOLS * (BTN + BTN_GAP) - BTN_GAP
    if cy < lay.btnTop - padY or cy > lay.btnTop + total + padY then return nil end

    return util.clamp(math.floor((cy - lay.btnTop) / (BTN + BTN_GAP)) + 1, 1, #TOOLS)
end

-- The tool buttons get first refusal on every press, ahead of the pointer that
-- would otherwise start drawing with it: you cannot be made to lift the pen
-- before you are allowed to change tool.
function Studio:pointerDown(cx, cy)
    if self.phase ~= "drawing" then return false end

    local index = self:buttonAt(cx, cy)
    if index then
        self.tool = index
        return true
    end
    return false
end

--- drawing --------------------------------------------------------------------

function Studio:mark(x, y)
    if self.mode == "board" then
        local gx, gy = self:cellAt(x, y)
        if gx then Hero.set(gx, gy, TOOLS[self.tool].ch) end
        return
    end

    -- Ink that lands in a box is an answer and is counted there; ink that
    -- misses everything is just ink on the page.
    if self.choice:mark(x, y) then return end
    self.marks:add(x, y)
end

function Studio:answer(box)
    if box.key == "reset" then
        Hero.reset()
        -- Answered in place rather than closing the screen, so the box has to
        -- be answerable again: the ink comes back out of it.
        self.choice:clear(box)
        self.particles:burst(box.x + box.w / 2, box.y + box.h / 2, 12, Palette.slate)
        return
    end

    -- An empty board is not an answer. Nothing drawn is nothing to play as, and
    -- it would be saved and handed back on the next launch as well.
    if Hero.isBlank() then
        self.choice:clear(box)
        return
    end

    Hero.save()
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
    self.particles:burst(box.x + box.w / 2, box.y + box.h / 2, 16, Palette.red)
end

--- update ---------------------------------------------------------------------

-- Returns "start" on the frame the board is handed over, and nothing until then.
function Studio:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)
    self.particles:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return "start" end
        return
    end

    -- The keyboard fills a box in rather than jumping past it, and there is no
    -- pen to lift, so that answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then self:answer(filled) end

    local down = Input.pointerDown
    if down then
        local x, y = Input.pointerX, Input.pointerY

        if not self.wasDown then
            self.lastX, self.lastY, self.carry = x, y, 0
            -- Latched on the press: a stroke that starts on the board draws on
            -- it for its whole length and can never answer a box, and one that
            -- starts off the board can never reach it. Overshooting a box
            -- should not cost your hero a leg.
            self.mode = self:cellAt(x, y) and "board" or "page"
            self:mark(x, y)
        end

        self.carry = Scribble.walkSegment(self.lastX, self.lastY, x, y, self.carry,
            function(mx, my) self:mark(mx, my) end)
        self.lastX, self.lastY = x, y
    end
    self.wasDown = down

    -- Armed, not answered: nothing is committed until the pen comes off the
    -- page, so a line that carries on into the other box changes its mind.
    if self.choice.armed and not down then
        self:answer(self.choice.armed)
    end
end

-- The keys fill a box in rather than jumping past it, the way they do on every
-- other screen here: the box still gets answered the only way a box here gets
-- answered.
function Studio:keypressed(key)
    if self.phase ~= "drawing" then return end

    if key == "1" or key == "p" then
        self.tool = 1
    elseif key == "2" or key == "e" then
        self.tool = 2
    elseif key == "r" then
        self.choice:autoFill(self.boxes[2])
    elseif key == "return" or key == "kpenter" or key == "space" or key == "y" then
        self.choice:autoFill(self.boxes[1])
    end
end

function Studio:wheelmoved(dy)
    if self.phase ~= "drawing" or dy == 0 then return end
    self.tool = self.tool % #TOOLS + 1
end

--- draw -----------------------------------------------------------------------

function Studio:prompt()
    if Hero.isBlank() then return HINT_EMPTY end
    if self.choice.armed then
        return Input.usingTouch and HINT_LIFT or HINT_RELEASE
    end
    return HINT_IDLE
end

function Studio:boxColor(box)
    if self.chosen then
        if self.chosen ~= box then return Palette.graphite end
        -- Flashing while the answer registers.
        return math.floor(self.confirmT * 18) % 2 == 0 and Palette.red or Palette.ink
    end

    -- The border warms up as the box fills, so you can see the answer coming.
    if box.fill >= 0.6 then return Palette.red end
    if box.fill >= 0.25 then return Palette.blue end
    return Palette.slate
end

-- Paper is the one colour that does not overprint -- it wipes whatever is under
-- it rather than stacking with it -- so filling the board with it genuinely
-- clears the ruling off that patch of page, and what is drawn there is drawn on
-- blank paper. The squared lattice on top of it is the page the hero is being
-- worked out on, and it is doing real work: a cell is filled a pixel short of
-- its square, so the gutter survives between two filled neighbours and fifteen
-- pixels blown up nine times still read as fifteen pixels rather than one blob.
function Studio:drawBoard(lay)
    local z = lay.zoom
    local w, h = boardW(z), boardH(z)

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", lay.bx, lay.board, w, h)

    love.graphics.setColor(Palette.graphite)
    for gy = 0, Hero.H do
        for gx = 0, Hero.W do
            love.graphics.rectangle("fill", lay.bx + gx * z, lay.board + gy * z, 1, 1)
        end
    end

    for gy = 1, Hero.H do
        for gx = 1, Hero.W do
            local ch = Hero.get(gx, gy)
            if ch ~= Hero.BLANK then
                love.graphics.setColor(Palette.key[ch])
                love.graphics.rectangle("fill",
                    lay.bx + (gx - 1) * z + 1, lay.board + (gy - 1) * z + 1, z - 1, z - 1)
            end
        end
    end

    Scribble.drawBox({
        x = lay.bx - BOARD_PAD,
        y = lay.board - BOARD_PAD,
        w = w + BOARD_PAD * 2,
        h = h + BOARD_PAD * 2,
    }, util.clamp(self.t / BOX_TIME, 0, 1), Palette.ink, 3, 0)
end

function Studio:drawButtons()
    for i, tool in ipairs(TOOLS) do
        local selected = i == self.tool
        local x, y = self:buttonPos(i, selected)

        love.graphics.setColor(selected and Palette.red or Palette.slate)
        love.graphics.rectangle("fill", x, y, BTN, BTN)
        love.graphics.setColor(Palette.paper)
        love.graphics.rectangle("fill", x + 1, y + 1, BTN - 2, BTN - 2)

        love.graphics.setColor(1, 1, 1)
        Sprites.icons[tool.icon]:draw(x + BTN / 2, y + BTN / 2)
    end
end

-- The hero at the size he will actually be, standing on the page beside the
-- board he is being drawn on, with the one-pixel walk bounce the run gives him.
function Studio:drawPreview(lay)
    local x, y = lay.previewX, lay.previewY

    Sprites.shadow(Sprites.player, x, y)

    love.graphics.setColor(1, 1, 1)
    Sprites.player:draw(x, y - (math.floor(self.t * 7) % 2), false)
end

function Studio:draw(game)
    local lay = self:layout(game)

    -- Written on the page rather than laid over it, like every other screen
    -- here, so it goes through the overprint pass and the ruling shows through
    -- the lettering.
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()

    self.marks:draw(0)

    Scribble.printBig(TITLE[1], lay.textCx, lay.title, TITLE_SCALE, Palette.ink,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 3 })
    Scribble.printBig(TITLE[2], lay.textCx, lay.title2, TITLE_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 4 })

    self:drawBoard(lay)
    self:drawButtons()
    self:drawPreview(lay)

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)
    local labelH = Font.height * LABEL_SCALE
    for i, box in ipairs(self.boxes) do
        local color = self:boxColor(box)
        local labelY = box.y + math.floor((Scribble.BOX_H - labelH) / 2)

        Scribble.printBig(box.label, box.labelCx, labelY, LABEL_SCALE, color,
            { wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    -- Once the answer is in, the box flashing on its own is the whole of the
    -- feedback; there is nothing left for the line to ask for.
    if self.phase == "drawing" then
        local urgent = self.choice.armed ~= nil or Hero.isBlank()

        Scribble.printBig(self:prompt(), lay.textCx, lay.hint, 1,
            urgent and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not urgent then
            Scribble.printBig(HINT_KEYS, lay.textCx, lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
        end
    end

    self.particles:draw()

    Overprint.finish()
end

return Studio
