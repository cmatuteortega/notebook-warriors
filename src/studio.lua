-- The drawing board: whatever this game asks you to draw, you draw here.
--
-- It opens twice. Between answering the title screen and the run starting you
-- are handed a stick man, a pencil, a pen and a rubber, and whatever you leave
-- on the board is the sprite you play as. Mid-run, the first time a draft gives
-- you a weapon that is drawn rather than issued, the board comes back with that
-- weapon on it (src/design.lua) -- you are not handed a star, you draw one.
--
-- The board *is* the sprite either way, one cell per pixel, blown up by a whole
-- number the way main.lua blows up the whole canvas -- so there is nothing
-- between what you draw and what walks onto the page a second later. The
-- life-size copy standing in the margin is the same sprite at 1:1, which is the
-- only honest preview of something fifteen pixels across. Nothing in here is
-- written down about what is being drawn: the board is as many cells as the
-- design has pixels, and the title, the hint and the preview are the design's.
--
-- The board is the biggest thing on the screen and everything else is set beside
-- it in a column: the title, the copy, the boxes, the line saying what the
-- screen is waiting for. The tools are pinned to the right edge of the safe area
-- on the run's own margin, in the run's own box, popping out the same way when
-- selected -- the tools are in the same place on the page whether you are
-- drawing the hero or playing him, so there is only one spot to reach for. Where
-- there is no room for a column beside the board -- a phone held upright -- the
-- same pieces go above and below it instead, and the two arrangements are picked
-- between by which leaves the bigger cell to draw on.
--
-- It asks to be finished the way every other screen here asks anything: a box
-- you scribble in (src/scribble.lua). OK! keeps what is on the board and hands
-- it over; RESET puts back what you were given to draw over. Ink that lands
-- outside the board and outside the boxes is not part of the drawing -- it is
-- just ink on the page, and fades off it.
--
-- The hero's board asks one thing more, between the drawing and the boxes: *which*
-- hero this is
-- (src/characters.lua), between two arrows. That is the one thing on this screen
-- that is pressed rather than drawn in -- the timetable's rule, where a tab is
-- pressed and only leaving is answered: which character to look at is not the
-- question, and it can be changed as many times as you like before OK!. It is
-- here rather than on the timetable because it is a question about the drawing --
-- pick the swordsman and OK! hands the screen straight on to the board his sword
-- is drawn on, since a sword he swings is as much of him as his own outline.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Particles = require("src.particles")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Design = require("src.design")
local Characters = require("src.characters")
local Sfx = require("src.sfx")
local I18n = require("src.i18n")
local util = require("src.util")

local Studio = {}

-- The first line of the title. The second is the design's own, so the board
-- says what it is asking for.
local TITLE_TOP = "DRAW YOUR"
local TITLE_SCALE, LABEL_SCALE = 2, 2

-- Every line that can appear under the boxes, apart from the design's own idle
-- one. Listed so the column can be made wide enough for the longest of them
-- before any of them is chosen, rather than changing width when the prompt
-- changes.
local HINT_EMPTY = "DRAW SOMETHING FIRST"
local HINT_LIFT = "LIFT TO CONFIRM"
local HINT_RELEASE = "RELEASE TO CONFIRM"
local HINT_KEYS = "OR PRESS ENTER"
local HINTS = { HINT_EMPTY, HINT_LIFT, HINT_RELEASE, HINT_KEYS }

-- The board takes whatever is left over once everything else has had its share
-- of the canvas, on a whole-number zoom, between these. Both are limits on the
-- *cell* rather than on the board, which is what makes a small design come out
-- looking small: a cell is one pixel of drawing and a finger is the same size on
-- every board, so a seven-pixel star gets the same size cell the hero does and a
-- board a third the size, rather than the same board with cells you could not
-- read as pixels.
local MIN_ZOOM, MAX_ZOOM = 4, 12

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

-- The character selector, on the board that is the character (`roster` in
-- src/design.lua): two arrows with the name of whoever is picked between them,
-- and under it the one line saying how that hero fights. It goes between the
-- drawing and the boxes -- see Studio:columnStack for the order and why. The
-- arrows are the corner button's own 11px box, because they belong to the same
-- set of things on this screen that are *pressed* rather than drawn in.
local ARROW = 11
local ARROW_GAP = 6    -- between an arrow and the name
local ROSTER_GAP = 8   -- between the selector and the boxes under it
local BLURB_GAP = 3    -- between the name and the line under it

local BOARD_PAD = 2   -- between the drawing area and its border
local BOX_TIME = 0.3  -- the board and the boxes drawing themselves on
local CONFIRM = 0.32  -- the answered box flashing before the run starts

-- Pencil, pen, rubber -- ink, blue and paper, which is every colour a design is
-- allowed to hold (see the head of src/design.lua for why it is three and not
-- eight). The rubber is last rather than in the middle so that the two buttons
-- that put something down are neighbours and the one that takes it away is at
-- the end of the strip, which is also the order they are in the run's own
-- selector.
--
-- `key` is the letter this tool answers to; its number is its place here, so
-- nothing in this file has to know how many there are.
local TOOLS = {
    { icon = "pencil", ch = Design.PENCIL, key = "p" },
    { icon = "pen",    ch = Design.PEN,    key = "b" },
    { icon = "rubber", ch = Design.BLANK,  key = "e" },
}

-- The board is a whole number of cells plus the last line of the lattice, which
-- closes the right and bottom edges of it.
function Studio:boardW(zoom) return self.design.w * zoom + 1 end
function Studio:boardH(zoom) return self.design.h * zoom + 1 end

--- setup ----------------------------------------------------------------------

function Studio:enter(design)
    self.design = design
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
    self.pen = Scribble.newPen(Input.pointerDown)
    self.mode = nil

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

-- The row the arrows and the name sit on. The name is lettered at the box
-- labels' scale, so which of the two is taller is a thing that can change if
-- either number does.
function Studio:rosterRow()
    return math.max(ARROW, Font.height * LABEL_SCALE)
end

function Studio:rosterHeight()
    return self:rosterRow() + BLURB_GAP + Font.height
end

-- Measured off the *widest* name in the roster rather than the one showing, so
-- the arrows are in the same place for every character: something you press
-- should not move because of what you pressed it for last.
function Studio:rosterWidth()
    local name = 0
    for _, char in ipairs(Characters.list) do
        name = math.max(name, Font.width(I18n.t(char.name)) * LABEL_SCALE)
    end
    return name + (ARROW + ARROW_GAP) * 2
end

-- Wide enough for the longest thing that can ever appear in it, so nothing in
-- the column moves sideways while the screen is up.
function Studio:columnWidth()
    local w = self.choice:columnWidth()
    w = math.max(w, Font.width(I18n.t(TITLE_TOP)) * TITLE_SCALE)
    w = math.max(w, Font.width(I18n.t(self.design.title)) * TITLE_SCALE)
    w = math.max(w, Font.width(I18n.t(self.design.hint)))
    for _, line in ipairs(HINTS) do
        w = math.max(w, Font.width(I18n.t(line)))
    end

    -- Every character's name and every blurb, not the ones showing: stepping the
    -- roster must not re-fit the screen it is on.
    if self.design.roster then
        w = math.max(w, self:rosterWidth())
        for _, char in ipairs(Characters.list) do
            w = math.max(w, Font.width(I18n.t(char.blurb)))
        end
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

    -- Top to bottom: what you are drawing, who it is, and then the two boxes that
    -- answer for both of them. The selector sits between the drawing and the
    -- boxes rather than under them because that is the order the screen is read
    -- in -- the board and the copy beside it are the *what*, the name under them
    -- is the *who*, and OK! is the answer to the pair. Anything answerable is
    -- last, with the line that talks about it directly underneath.
    local s, y = {}, 0
    s.title = y;   y = y + titleH + 3
    s.title2 = y;  y = y + titleH + 9
    s.preview = y; y = y + self.design.h + 2 + 10
    if self.design.roster then
        s.roster = y
        y = y + self:rosterHeight() + ROSTER_GAP
    end
    s.boxes = y;   y = y + boxesH + 9
    s.hint = y;    y = y + hintH
    s.height = y

    return s
end

-- The stacked arrangement without the board in it: two title lines, one row of
-- boxes, the hint. Wanted before the zoom is picked, since what is left over
-- after this is what the board has to fit into.
function Studio:stackedChrome()
    local titleH = Font.height * TITLE_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2
    local roster = self.design.roster and ROSTER_GAP + self:rosterHeight() or 0
    return titleH * 2 + 3 + 6 + 7 + Scribble.BOX_H + roster + 7 + hintH + 1
end

-- The cell each arrangement could give the board, so the fit can pick between
-- them rather than guess. Clamped here rather than after the choice: both come
-- out over the ceiling for a small design and under the floor on a canvas with
-- no room in it, and it is what the board would actually get that the two are
-- being compared on.
function Studio:besideZoom(colW, inner, availH)
    return util.clamp(math.min(
        math.floor((availH - EDGE * 2 - 1) / self.design.h),
        math.floor((inner - colW - COL_GAP - BOARD_PAD - 1) / self.design.w)),
        MIN_ZOOM, MAX_ZOOM)
end

function Studio:stackedZoom(inner, availH)
    -- Kept clear either side of the board so it stays centred on what is left
    -- of the width, with room for the copy on one of them.
    local margin = self.design.w + BTN_INSET
    return util.clamp(math.min(
        math.floor((availH - self:stackedChrome()) / self.design.h),
        math.floor((inner - margin * 2 - 1) / self.design.w)),
        MIN_ZOOM, MAX_ZOOM)
end

function Studio:layoutBeside(lay, ins, inner, availH)
    local s = self:columnStack()
    local bh = self:boardH(lay.zoom)
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
    lay.bx = ins.l + inner - self:boardW(lay.zoom) - BOARD_PAD

    -- Rounded up, not down. When the board has taken all it can the column is
    -- left exactly as wide as its widest line, and printBig floors the corner it
    -- starts from -- so centring the other way puts that line a pixel off the
    -- edge of the page.
    lay.textCx = ins.l + math.ceil((lay.bx - COL_GAP - ins.l) / 2)
    lay.title = colTop + s.title
    lay.title2 = colTop + s.title2
    lay.previewX = lay.textCx
    lay.previewY = colTop + s.preview + math.floor((self.design.h + 2) / 2)
    lay.roster = s.roster and colTop + s.roster or nil
    lay.hint = colTop + s.hint

    self.choice:layoutColumn(
        lay.textCx - math.floor(self.choice:columnWidth() / 2), colTop + s.boxes, BOX_GAP)
end

-- No column to spare: the same pieces run down the middle with the board
-- spliced in, and the copy stands in the margin beside it.
function Studio:layoutStacked(lay, ins, inner, availH)
    local titleH = Font.height * TITLE_SCALE
    local hintH = Input.usingTouch and Font.height or Font.height * 2 + 2

    local y = 0
    local title = y;  y = y + titleH + 3
    local title2 = y; y = y + titleH + 6
    local board = y;  y = y + self:boardH(lay.zoom) + 7
    local roster
    if self.design.roster then
        roster = y
        y = y + self:rosterHeight() + ROSTER_GAP
    end
    local boxes = y;  y = y + Scribble.BOX_H + 7
    local hint = y;   y = y + hintH

    local top = math.floor(ins.t + (availH - y) / 2)

    lay.textCx = math.floor(ins.l + inner / 2)
    lay.title = top + title
    lay.title2 = top + title2
    lay.board = top + board
    lay.roster = roster and top + roster or nil
    lay.hint = top + hint
    lay.bx = math.floor(lay.textCx - self:boardW(lay.zoom) / 2)

    -- The copy stands in the margin the board left, on the far side from the
    -- tools so it is never crowded by them.
    lay.previewX = lay.bx - BTN_INSET - math.floor(self.design.w / 2)
    lay.previewY = lay.board + math.floor(self:boardH(lay.zoom) / 2)

    self.choice:layout(lay.textCx, top + boxes)
end

-- Whichever arrangement leaves the bigger cell to draw on, with the column
-- beside the board on a tie -- which is a wide screen, where the column has
-- somewhere to go and putting it above and below would only waste the width.
-- Asking which is bigger rather than whether the width looks sufficient is what
-- lets a small design come out right: seven pixels of star fit beside the column
-- on a phone held upright, at cells half the size the stacked arrangement would
-- have given them.
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

    local beside = self:besideZoom(lay.colW, inner, availH)
    local stacked = self:stackedZoom(inner, availH)

    lay.beside = beside >= stacked
    lay.zoom = lay.beside and beside or stacked

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
    if gx < 1 or gx > self.design.w or gy < 1 or gy > self.design.h then return nil end
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

-- One of the two arrows, as a box. `dir` is -1 for the left one and 1 for the
-- right, and both are struck off the middle of the column: the name goes between
-- them and the gap is the widest name in the roster, so neither arrow moves as
-- you step through it.
function Studio:arrowBox(dir)
    local lay = self.lay
    local half = self:rosterWidth() / 2
    local x = dir < 0 and lay.textCx - half or lay.textCx + half - ARROW
    return math.floor(x), lay.roster + math.floor((self:rosterRow() - ARROW) / 2)
end

-- Which arrow, if either, a press lands on. Padded the way every other pressable
-- thing on this screen is padded, and by more on a phone: these are the smallest
-- targets the studio has.
function Studio:arrowAt(cx, cy)
    local lay = self.lay
    if not lay or not lay.roster then return nil end

    local padX, padY = 4, 2
    if Input.usingTouch then padX, padY = 8, 6 end

    for dir = -1, 1, 2 do
        local x, y = self:arrowBox(dir)
        if cx >= x - padX and cx <= x + ARROW + padX
            and cy >= y - padY and cy <= y + ARROW + padY then
            return dir
        end
    end
    return nil
end

-- One step along the roster (src/characters.lua). Pressed and not answered, the
-- way a tab on the timetable is: which hero to *look* at is not a question, and
-- the same short transition says the screen turned to another one rather than
-- left for one.
--
-- It changes what is on the board as well as who it is for, because every
-- character has a hero drawing of his own (`Design.heroes`): the shootman you drew
-- and the swordsman you drew are two people. The board is the same 15x19 either
-- way, so nothing about the screen moves -- what changes is the grid under the
-- cells and the sprite it keeps up to date, which is applied here because all of
-- them write the same one.
--
-- The board being stepped away from is *kept* if there is anything on it. `OK!` is
-- still the only thing that answers the screen, but the drawing you are leaving
-- and the one you are arriving at are two different files, and a step that
-- quietly threw the last ten strokes away would be the one place in this game
-- where drawing something loses it. A blank one is not saved, for the reason `OK!`
-- refuses one: an empty file is an invisible hero.
function Studio:step(dir)
    if not self.design.roster then return end

    -- And a roster of one does not step, since three of the four heroes are bought
    -- at the canteen and a fresh book has one (src/characters.lua). Nothing about
    -- the screen may pretend it did: no save, no transition, and no board swapped
    -- for the same board. It is the arrows that say so -- they are drawn grey there
    -- (`drawArrow`), the draft's own spent button.
    if Characters.count() < 2 then return end

    if not self.design:isBlank() then self.design:save() end

    Characters.step(dir)
    self.design = Design.hero()
    self.design:apply()
    Sfx.play("transition")
end

-- The tool buttons and the arrows get first refusal on every press, ahead of the
-- pointer that would otherwise start drawing with it: you cannot be made to lift
-- the pen before you are allowed to change tool, and a press that steps the
-- roster is a press rather than the start of a line -- swallowing it here is what
-- keeps ink off the arrows without the mark pass having to know about them.
function Studio:pointerDown(cx, cy)
    if self.phase ~= "drawing" then return false end

    local index = self:buttonAt(cx, cy)
    if index then
        self.tool = index
        return true
    end

    local dir = self:arrowAt(cx, cy)
    if dir then
        self:step(dir)
        return true
    end

    return false
end

--- drawing --------------------------------------------------------------------

-- Answers whether the stamp became ink, which is what the pen's swish is fired
-- off (src/scribble.lua). A cell painted on the board counts: it is the one
-- place in the game where drawing puts a pixel somewhere for good rather than
-- somewhere that fades, and it should sound as drawn as everything that does.
function Studio:mark(x, y)
    if self.mode == "board" then
        local gx, gy = self:cellAt(x, y)
        if gx then self.design:set(gx, gy, TOOLS[self.tool].ch) end
        return gx ~= nil
    end

    -- Ink that lands in a box is an answer and is counted there; ink that
    -- misses everything is just ink on the page.
    if self.choice:mark(x, y) then return true end
    self.marks:add(x, y)
    return true
end

function Studio:answer(box)
    if box.key == "reset" then
        self.design:reset()
        -- Answered in place rather than closing the screen, so the box has to
        -- be answerable again: the ink comes back out of it.
        self.choice:clear(box)
        Sfx.play("accept")
        self.particles:burst(box.x + box.w / 2, box.y + box.h / 2, 12, Palette.slate)
        return
    end

    -- An empty board is not an answer. Nothing drawn is nothing to play as, and
    -- it would be saved and handed back on the next launch as well.
    if self.design:isBlank() then
        self.choice:clear(box)
        return
    end

    self.design:save()
    self.phase = "confirm"
    Sfx.play("accept")
    self.chosen = box
    self.confirmT = 0
    self.particles:burst(box.x + box.w / 2, box.y + box.h / 2, 16, Palette.red)
end

--- update ---------------------------------------------------------------------

-- Returns "done" on the frame the board is handed over, plus the design that was
-- on it -- which the caller cannot have remembered from the way in, since the
-- roster's arrows can change it while the screen is up (see Studio:step). What
-- happens next is the caller's: a run starts, or a held one carries on.
function Studio:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)
    self.particles:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return "done", self.design end
        return
    end

    -- The keyboard fills a box in rather than jumping past it, and there is no
    -- pen to lift, so that answer stands as soon as the scribble lands.
    local filled = self.choice:update(dt)
    if filled then self:answer(filled) end

    local down = Input.pointerDown
    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(x, y)
            -- Latched on the press: a stroke that starts on the board draws on
            -- it for its whole length and can never answer a box, and one that
            -- starts off the board can never reach it. Overshooting a box
            -- should not cost your hero a leg.
            self.mode = self:cellAt(x, y) and "board" or "page"
        end)

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

    -- Each tool answers to its own letter and to its place in the strip, read
    -- off TOOLS rather than written out, so adding one is one row up there and
    -- nothing down here. `R` is RESET's and no tool may claim it.
    for i, tool in ipairs(TOOLS) do
        if key == tool.key or key == tostring(i) then
            self.tool = i
            return
        end
    end

    -- The arrows step the roster outright rather than drawing anything, because
    -- there is nothing here to draw: the boxes are answered by scribbling and this
    -- is pressed, on the keyboard exactly as with a finger.
    if key == "left" or key == "right" then
        self:step(key == "left" and -1 or 1)
        return
    end

    if key == "r" then
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
    if self.design:isBlank() then return HINT_EMPTY end
    if self.choice.armed then
        return Input.usingTouch and HINT_LIFT or HINT_RELEASE
    end
    return self.design.hint
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
    local w, h = self:boardW(z), self:boardH(z)

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", lay.bx, lay.board, w, h)

    love.graphics.setColor(Palette.graphite)
    for gy = 0, self.design.h do
        for gx = 0, self.design.w do
            love.graphics.rectangle("fill", lay.bx + gx * z, lay.board + gy * z, 1, 1)
        end
    end

    for gy = 1, self.design.h do
        for gx = 1, self.design.w do
            local ch = self.design:get(gx, gy)
            if ch ~= Design.BLANK then
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

-- The drawing at the size it will actually be, on the page beside the board it
-- is being drawn on. Whatever the run does to it when it draws it, the preview
-- does too, which is the whole job of the thing: something that stands on the
-- page gets the scrap of ground under it and the one-pixel walk bounce; a cool S
-- gets the pale blue rim it floats around wearing; something that floats bare --
-- a star on its orbit -- gets neither, and is shown exactly as it will look
-- going round you. All of that is read off the design (src/design.lua) rather
-- than known here, so a new thing to draw brings its own answer with it.
function Studio:drawPreview(lay)
    local sprite = Sprites[self.design.sprite]
    local x, y = lay.previewX, lay.previewY

    if self.design.walks then
        Sprites.shadow(sprite, x, y)
        y = y - (math.floor(self.t * 7) % 2)
    end
    if self.design.rim then
        Sprites.rim(sprite, x, y)
    end

    love.graphics.setColor(1, 1, 1)
    sprite:draw(x, y, false)
end

-- One arrow, in the corner button's own recipe: a slate box filled with paper and
-- the glyph in the middle of it. The same drawing both ways round -- the chevron
-- is three wide, so its origin is the middle column and the flip is an exact
-- mirror rather than a resample.
--
-- Grey, with the glyph as a silhouette, on a roster with nothing to step to: the
-- draft's spent button exactly (src/levelup.lua), and drawn rather than dropped for
-- the same reason -- a column that lost a row while there was one hero to look at
-- would move everything under it. It still swallows the press, since a button you
-- can see is not a piece of page you can draw on.
function Studio:drawArrow(dir)
    local x, y = self:arrowBox(dir)
    local live = Characters.count() > 1

    love.graphics.setColor(live and Palette.slate or Palette.graphite)
    love.graphics.rectangle("fill", x, y, ARROW, ARROW)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, ARROW - 2, ARROW - 2)

    if live then
        love.graphics.setColor(1, 1, 1)
        Sprites.icons.chevron:draw(x + ARROW / 2, y + ARROW / 2, dir > 0)
    else
        love.graphics.setColor(Palette.graphite)
        Sprites.icons.chevron:drawMask(x + ARROW / 2, y + ARROW / 2, dir > 0)
    end
end

-- Which hero the drawing on the board is going to be, under the drawing and above
-- the boxes: the name between the two arrows and the one line saying how he fights
-- under that.
--
-- It is on this screen rather than on the timetable because it is a question
-- about the drawing -- the swordsman's sword is drawn on the board that opens
-- next -- and it is stepped rather than scribbled for because, like a tab on the
-- timetable, choosing which one to *look* at is not the question. `OK!` is.
function Studio:drawRoster(lay)
    self:drawArrow(-1)
    self:drawArrow(1)

    local char = Characters.current
    Scribble.printBig(I18n.t(char.name), lay.textCx, lay.roster, LABEL_SCALE,
        Palette.ink,
        { wobble = true, t = self.t, seed = 61 })
    Scribble.printBig(I18n.t(char.blurb), lay.textCx,
        lay.roster + self:rosterRow() + BLURB_GAP, 1, Palette.slate, { seed = 62 })
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

    Scribble.printBig(I18n.t(TITLE_TOP), lay.textCx, lay.title, TITLE_SCALE,
        Palette.ink,
        { shadow = Palette.graphite, wobble = true, t = self.t, seed = 3 })
    Scribble.printBig(I18n.t(self.design.title), lay.textCx, lay.title2,
        TITLE_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 4 })

    self:drawBoard(lay)
    self:drawButtons()
    self:drawPreview(lay)
    if lay.roster then self:drawRoster(lay) end

    local progress = util.clamp(self.t / BOX_TIME, 0, 1)
    local labelH = Font.height * LABEL_SCALE
    for i, box in ipairs(self.boxes) do
        local color = Scribble.boxColor(box, self.chosen, self.confirmT)
        local labelY = box.y + math.floor((Scribble.BOX_H - labelH) / 2)

        Scribble.printBig(Scribble.label(box), box.labelCx, labelY,
            LABEL_SCALE, color,
            { wobble = true, t = self.t, seed = 30 + i * 5 })
        Scribble.drawBox(box, progress, color, 10 + i, 0)
        Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
    end

    -- Once the answer is in, the box flashing on its own is the whole of the
    -- feedback; there is nothing left for the line to ask for.
    if self.phase == "drawing" then
        local urgent = self.choice.armed ~= nil or self.design:isBlank()

        Scribble.printBig(I18n.t(self:prompt()), lay.textCx, lay.hint, 1,
            urgent and Palette.red or Palette.slate, { seed = 51 })
        if not Input.usingTouch and not urgent then
            Scribble.printBig(I18n.t(HINT_KEYS), lay.textCx,
                lay.hint + Font.height + 2, 1,
                Palette.graphite, { seed = 52 })
        end
    end

    self.particles:draw()

    Overprint.finish()
end

return Studio
