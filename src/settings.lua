-- The settings page: how loud the game is, what language it is in, which way up
-- the page is held, which thumb walks, how much of a hit it says out loud, and
-- whether it asks you to draw the things it hands you.
--
-- **Nothing on this page is a question, so nothing on it is a box you scribble
-- in.** That is the same rule the timetable's tabs and the whole of the library
-- are drawn along, and it holds harder here than in either of them. A box
-- (src/scribble.lua) is a thing you cannot take back -- it arms while you draw in
-- it, it warms slate to red, and lifting commits it -- and every one of those
-- properties is wrong for a volume. A volume is not an answer you could get
-- wrong; it is a quantity, you can always move it again, and the only way to know
-- whether it is right is to *hear* it. So a bar is dragged, an arrow is pressed,
-- and the corner button closes the page -- and ink that lands anywhere else is
-- still ink and still fades off, because the page is a page.
--
-- It follows the pause card's shape rather than the library's -- one fixed block
-- of rows, centred in the safe area, a heading over it and a hint under it --
-- because it *can*: seven rows are seven rows on every screen and in both
-- languages, so there is a block here of a height that is the same twice, which
-- is the one thing the library never has. The dev row is the one thing that
-- changes that count and it is not a counter-example: it is on the page only
-- once the heading has been tapped three times (src/dev.lua), so a block that
-- grew is a block you asked for rather than one that twitched under you. What it does not borrow is the card.
-- The pause card is paper because there is a run underneath it that lettering
-- cannot be read against; here there is nothing underneath but the page you came
-- in on, so this is written straight onto it, the way the timetable and the
-- library are.
--
-- The bars themselves are the exception and go out past the overprint pass with
-- the corner button, for the timetable's tab reason: a paper-filled box still has
-- every inked pixel of its border paired with the page under it, so a border
-- landing on a rule comes out a step darker and the box reads as a hole rather
-- than as a thing lying on the page. The number beside a bar goes out with it --
-- the bar and what it says are one object -- while the labels, the heading and
-- the hint are lettering and stay on the page.
--
-- The two stepped rows are the library's footer arrows doing the library's job:
-- two boxes either side of the name of the thing they step. A language's own name
-- for itself is what is written between them (src/i18n.lua), because someone
-- looking for Spanish is looking for the word ESPANOL; the drawings row steps
-- between two words that say what happens rather than between ON and OFF, since
-- ON against a row worded as a refusal is a double negative you have to stop and
-- work out. Both rows' arrows are struck off the widest word either of them can
-- hold, so they line up with each other as well as standing still while their own
-- word is stepped.
--
-- What is set here is saved by src/options.lua, and saved when a drag *ends*
-- rather than while it is happening: a file written on every frame of a drag is a
-- file written sixty times to say one thing.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local Sprites = require("src.sprites")
local Sfx = require("src.sfx")
local I18n = require("src.i18n")
local Options = require("src.options")
local Design = require("src.design")
local Damage = require("src.damage")
local Orient = require("src.orient")
local Characters = require("src.characters")
local Dev = require("src.dev")
local util = require("src.util")

local Settings = {}

local HEAD = "SETTINGS"
local HEAD_SCALE = 2

local EDGE = 4
local HEAD_GAP = 9         -- the heading to the first row
local ROW_GAP = 7          -- one row to the next, and the most it is ever drawn
                           -- at: a page too short for the block closes it up
                           -- (Settings:layout)
local HINT_GAP = 9         -- the last row to the hint
local LABEL_GAP = 6        -- a label to the control beside it
local VALUE_GAP = 5        -- a control to the number beside it

-- The bar. Wider than the HUD's readout bars (60x6) and a pixel taller, and both
-- for the same reason: this one is *grabbed*. The extra width is resolution --
-- 62 pixels of inner track is finer than the ear can tell apart, so a drag never
-- runs out of places to put the level -- and the extra height is somewhere for a
-- finger to land.
local BAR_W, BAR_H = 64, 7
local KNOB_W = 3           -- the handle, and what says the bar is a control
                           -- rather than a readout
local KNOB_OVER = 1        -- how far it stands proud of the track, top and bottom

-- The gesture that puts the dev row on the page and the pause card's two
-- switches with it (src/dev.lua). Three taps on the heading, and the heading
-- because it is the one piece of this page that is not a control: there is
-- nothing there to press by accident and nothing a player is ever reaching for.
-- A window rather than a running total, so two taps today and one tomorrow is
-- not a reveal.
local TAPS = 3
local TAP_WINDOW = 1.2

local ARROW = 11           -- the same box the corner button, the studio's roster
                           -- and the library's footer all use
local ARROW_GAP = 5        -- ... and its clearance off the name between them

-- The drawings row's two words. What is being set is whether the game opens a
-- board for something it has just given you -- the weapon out of a draft, the arm
-- a character carries -- so the words are what it does about it rather than a yes
-- and a no: SKIP is a thing you can read once and know what you have turned off.
local ASK = "ASK"
local SKIP = "SKIP"

-- What the other two rows write between their arrows. The *values* are the
-- owning module's and so is the order they are stepped in (`Damage.MODES`,
-- `Input.SIDES`), which leaves this page with the one thing that is actually
-- its own: the word for each of them. A module that grows a third mode grows a
-- word here and nothing else.
local SHOW_WORD = { all = "ALL", big = "BIG ONLY", none = "NONE" }
local SIDE_WORD = { left = "LEFT", right = "RIGHT" }

-- Which way up the page is held (src/orient.lua). Three short words on purpose:
-- every stepped row's arrows are struck off the widest word *any* of them can
-- hold, so a row that said LANDSCAPE would push the arrows out on the six rows
-- that have nothing to do with it. WIDE and TALL are what the page *is*, which
-- is the thing actually being set, and both are shorter than BIG ONLY in
-- English and than PREGUNTAR in Spanish -- so this row costs the layout
-- nothing at all.
local SCREEN_WORD = { auto = "AUTO", wide = "WIDE", tall = "TALL" }

-- DEV, and out at launch with the row at the bottom of `ROWS` and src/dev.lua.
-- Two of the three words are the damage row's, which is the whole reason they are
-- the words: EARNED is the only thing this row can say that the page cannot
-- already say somewhere else, so the column the arrows are struck off does not
-- move for a row that is not going to ship.
local UNLOCK_WORD = { earned = "EARNED", all = "ALL", none = "NONE" }

-- One step along a list of values, wrapping. Two of them or three, this is the
-- same function -- which is what keeps a row from having to know how long its
-- own list is, and what makes a two-value row step the same way both arrows are
-- pressed without anything being said about it.
local function stepped(list, value, dir)
    local at = 1
    for i, v in ipairs(list) do
        if v == value then at = i end
    end
    return list[(at - 1 + dir) % #list + 1]
end

-- The widest word a list can put between the arrows, measured in the language it
-- will be lettered in.
local function listWidth(list, words)
    local w = 0
    for _, value in ipairs(list) do
        w = math.max(w, Font.width(I18n.t(words[value])))
    end
    return w
end

-- What a key press moves a volume by. Twenty steps end to end: coarse enough
-- that a few taps cross the range and fine enough that the step is not a jump.
local KEY_STEP = 0.05

-- The rows, in the order they are read. `kind` is what the row *is*, which is
-- the whole of how a press on it is handled: a level is dragged and a choice is
-- stepped.
--
-- The two volumes first, loudest thing first -- and music ahead of sound because
-- it is the one thing on this page you can hear without doing anything, the track
-- being up from the frame the program read this file (src/sfx.lua). Which is also
-- why the music bar is the only control here that needs nothing played to
-- demonstrate it: it is playing already, and dragging it is heard while the finger
-- is down. Then the language, and then the four rows that are about the game as
-- you play it rather than about the program: which way up you hold it, where
-- your thumb goes, what the page says when you hit something, and what it asks
-- you when it gives you something.
--
-- A choice row carries three functions and nothing else: the word to write
-- between its arrows, the widest word it could ever write there, and what a step
-- does. `text` and `widest` have to be of the same words in the same language --
-- a row measured on the English and lettered in the Spanish is a row the
-- lettering runs out of -- which is why each row translates in both or in
-- neither. The language's own name is the one word on this page that is never
-- translated (src/i18n.lua).
local ROWS = {
    { key = "music", label = "MUSIC", kind = "level",
      get = function() return Sfx.music end,
      set = function(v) Sfx.music = v end },
    { key = "sfx", label = "SOUND", kind = "level",
      get = function() return Sfx.volume end,
      set = function(v) Sfx.volume = v end },
    { key = "lang", label = "LANGUAGE", kind = "choice",
      text = function() return I18n.current().name end,
      widest = function()
          local w = 0
          for _, lang in ipairs(I18n.langs) do
              w = math.max(w, Font.width(lang.name))
          end
          return w
      end,
      step = function(dir) I18n.step(dir) end },
    -- Which way up the phone holds the page, and the row above the stick because
    -- it is the larger fact about how the thing is held: how you are holding it
    -- decides where your spare thumb ends up, not the other way round. Like the
    -- stick it is a row only a phone can act on -- a desktop window is the
    -- player's to drag and has no orientation to set -- and like the stick it is
    -- written down on every screen anyway rather than coming and going, for the
    -- reason given below.
    { key = "screen", label = "SCREEN", kind = "choice",
      text = function() return I18n.t(SCREEN_WORD[Orient.mode]) end,
      widest = function() return listWidth(Orient.MODES, SCREEN_WORD) end,
      step = function(dir)
          Orient.mode = stepped(Orient.MODES, Orient.mode, dir)
          -- Turned where it is stepped rather than on the way out of the page:
          -- the only way to know whether TALL is the one you wanted is to watch
          -- the page go tall, which is the argument the volume bars are played
          -- back on.
          Orient.apply()
      end },
    -- Only a phone has a thumb stick, and this row is drawn on every screen
    -- anyway. A row that came and went with `Input.usingTouch` would be a page
    -- whose height changes under you the first time you touch the screen, and
    -- the one fixed block is the whole reason this page can be centred at all --
    -- so it is written down where a phone player can find it and simply says
    -- nothing to anybody else.
    { key = "stick", label = "STICK", kind = "choice",
      text = function() return I18n.t(SIDE_WORD[Input.stickSide]) end,
      widest = function() return listWidth(Input.SIDES, SIDE_WORD) end,
      step = function(dir)
          Input.stickSide = stepped(Input.SIDES, Input.stickSide, dir)
      end },
    { key = "damage", label = "DAMAGE NUMBERS", kind = "choice",
      text = function() return I18n.t(SHOW_WORD[Damage.show]) end,
      widest = function() return listWidth(Damage.MODES, SHOW_WORD) end,
      step = function(dir)
          Damage.show = stepped(Damage.MODES, Damage.show, dir)
      end },
    { key = "ask", label = "NEW DRAWINGS", kind = "choice",
      text = function() return I18n.t(Design.ask and ASK or SKIP) end,
      widest = function()
          return math.max(Font.width(I18n.t(ASK)), Font.width(I18n.t(SKIP)))
      end,
      -- Two words is one step whichever way it is taken, so both arrows do the
      -- same thing here. Which is not a reason to draw only one of them: an
      -- arrow either side is what says the word between them is stepped, and a
      -- row with one arrow on it would read as a row that only goes one way.
      step = function() Design.ask = not Design.ask end },
    -- DEV. What the book has opened, overridden (src/dev.lua) -- everything, or
    -- nothing, over whatever the register actually says. Last on the page because
    -- it is the one row here that is not a setting: everything above it is a thing
    -- a player chooses about the program, and this is a thing a dev does to the
    -- game. Which is also why it carries `dev` and is not drawn until the gesture
    -- has been done. It comes out at launch, and taking it out is this row, the
    -- three calls to `Dev.opened` and the `unlocks` and `dev` lines in
    -- src/options.lua.
    { key = "unlocks", label = "UNLOCKS", kind = "choice", dev = true,
      text = function() return I18n.t(UNLOCK_WORD[Dev.unlocks]) end,
      widest = function() return listWidth(Dev.MODES, UNLOCK_WORD) end,
      step = function(dir)
          Dev.unlocks = stepped(Dev.MODES, Dev.unlocks, dir)
          -- The pick is clamped to what the roster now says (`Characters.pick`),
          -- so stepping down to NOTHING does not leave the studio standing on a
          -- hero its own arrows will not step back to.
          Characters.pick(Characters.current.key)
      end },
}

-- The rows actually on the page. `ROWS` above is every row there is; this is the
-- ones that get drawn, which is all of them but the dev row until the gesture has
-- been done. Rebuilt only when the answer changes rather than every frame, and
-- refreshed at the top of `layout` so everything measuring, hit-testing or
-- drawing a row this frame is looking at the same list.
local rows = ROWS
local shownDev = nil

local function refresh()
    local want = Dev.showing()
    if want == shownDev then return end
    shownDev = want

    rows = {}
    for _, row in ipairs(ROWS) do
        if want or not row.dev then rows[#rows + 1] = row end
    end
end

--- setup ---------------------------------------------------------------------

function Settings:enter()
    self.t = 0
    self.row = 1
    self.back = false
    self.dragging = nil   -- the row a finger has hold of, nil the rest of the time
    self.dirty = false    -- something moved and has not been written yet
    self.taps = 0         -- taps on the heading, and when the last of them landed
    self.tapAt = -TAP_WINDOW

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the button that opened this screen is not this
    -- screen's to read, exactly as the library treats the tab that opened it.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- Nothing to walk here, so the corner the thumb stick lives in is page like
    -- any other.
    Input.stickEnabled = false
end

--- layout --------------------------------------------------------------------

-- Every label, measured at the widest of them, so the bars line up in one column
-- and none of them moves as the language changes the words in front of them.
local function labelWidth()
    local w = 0
    for _, row in ipairs(rows) do
        w = math.max(w, Font.width(I18n.t(row.label)))
    end
    return w
end

-- The widest word any stepped row can hold, so the arrows stay where they are as
-- the word between them is stepped -- the library's own rule for its footer, read
-- across both rows rather than down one, so the two pairs of arrows line up with
-- each other as well.
local function choiceWidth()
    local w = 0
    for _, row in ipairs(rows) do
        if row.kind == "choice" then w = math.max(w, row.widest()) end
    end
    return w
end

-- The number beside a bar, measured at its widest rather than at what it says
-- now: a readout that shifts left as it passes 100 is a readout that twitches.
local function valueWidth()
    return Font.width("100")
end

-- One fixed block, centred in the safe area. There is nothing here whose height
-- the content decides -- seven rows are seven rows in both languages -- so
-- unlike the library this page has something worth centring.
function Settings:layout(game)
    self.game = game
    refresh()

    -- The dev row can leave the page while the keyboard is standing on it.
    if self.row > #rows then self.row = #rows end

    local ins = game.inset
    local lay = {}
    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)

    lay.labelW = labelWidth()
    lay.choiceW = choiceWidth()
    lay.valueW = valueWidth()

    -- The control column is as wide as the widest control in it, so the labels in
    -- front and the numbers behind both line up whichever row is being read.
    lay.controlW = math.max(BAR_W, lay.choiceW + (ARROW + ARROW_GAP) * 2)
    lay.rowH = math.max(BAR_H + KNOB_OVER * 2, ARROW, Font.height)

    local blockW = lay.labelW + LABEL_GAP + lay.controlW + VALUE_GAP + lay.valueW
    lay.blockX = math.floor(lay.cx - blockW / 2)
    lay.labelRight = lay.blockX + lay.labelW
    lay.controlX = lay.labelRight + LABEL_GAP
    lay.controlCx = lay.controlX + math.floor(lay.controlW / 2)
    lay.valueX = lay.controlX + lay.controlW + VALUE_GAP

    local headH = Font.height * HEAD_SCALE
    -- One line under the rows, and only what to do: everything else about this
    -- page is heard rather than read.
    local hintH = Font.height

    -- The corner button is the one thing on this page that cannot move, and on a
    -- screen short enough for the centred block to reach it the block gives way.
    -- Which is where the block runs out of page: a phone lying down is 180 pixels
    -- tall whatever else it is, and the button has the top of them before the
    -- heading has been drawn.
    local topMin = Hud.cornerBottom(game) + EDGE
    local room = game.vh - ins.b - topMin

    -- So a page too short for its rows spends the air between them rather than
    -- pushing the hint off the bottom -- the rows keep their own height, and the
    -- gap closes to a floor of one pixel, which is the least that still reads as
    -- separate rows rather than as a paragraph. It costs nothing until it is
    -- needed: every shape and row count that ships clears the check and keeps
    -- the gap the page was drawn with.
    local gaps = #rows - 1
    local fixed = headH + HEAD_GAP + #rows * lay.rowH + HINT_GAP + hintH

    lay.rowGap = ROW_GAP
    if gaps > 0 and fixed + gaps * ROW_GAP > room then
        lay.rowGap = math.max(1, math.floor((room - fixed) / gaps))
    end

    local rowsH = #rows * lay.rowH + gaps * lay.rowGap
    local total = headH + HEAD_GAP + rowsH + HINT_GAP + hintH
    local top = math.floor(ins.t + (game.vh - ins.t - ins.b - total) / 2)

    top = math.max(top, topMin)

    lay.head = top
    lay.rowTop = top + headH + HEAD_GAP
    lay.hint = lay.rowTop + rowsH + HINT_GAP

    self.lay = lay
    return lay
end

function Settings:rowY(i)
    return self.lay.rowTop + (i - 1) * (self.lay.rowH + self.lay.rowGap)
end

-- The bar's track, which is what a drag is measured against and what a press is
-- tested against. Centred in the control column, since a bar is narrower than
-- the language row is wide.
function Settings:barBox(i)
    local lay = self.lay
    local x = lay.controlCx - math.floor(BAR_W / 2)
    local y = self:rowY(i) + math.floor((lay.rowH - BAR_H) / 2)
    return x, y, BAR_W, BAR_H
end

-- One of a stepped row's two arrows. `dir` is -1 for the left and 1 for the
-- right, both struck off the middle of the control column with the widest word
-- either row can hold between them.
function Settings:arrowBox(i, dir)
    local lay = self.lay
    local half = (lay.choiceW + (ARROW + ARROW_GAP) * 2) / 2
    local x = dir < 0 and lay.controlCx - half or lay.controlCx + half - ARROW
    local y = self:rowY(i) + math.floor((lay.rowH - ARROW) / 2)
    return math.floor(x), y
end

--- what a point lands on -----------------------------------------------------

-- A finger is bigger and blinder than a mouse pointer, so every small target here
-- reaches further out on touch -- the same allowance the tool selector and the
-- library's arrows are given.
local function pad()
    if Input.usingTouch then return 8, 6 end
    return 4, 3
end

-- Which bar a point is on, if any. The row's whole height counts rather than the
-- track's, so a press a little above or below the bar still grabs it: at seven
-- pixels tall the track alone is a target you would have to aim at.
function Settings:barAt(x, y)
    if not self.lay then return nil end

    local padX, padY = pad()
    for i, row in ipairs(rows) do
        if row.kind == "level" then
            local bx, by, bw, bh = self:barBox(i)
            if x >= bx - padX and x <= bx + bw + padX
                and y >= by - padY and y <= by + bh + padY then
                return i
            end
        end
    end
end

-- Which arrow of which row, since there is more than one stepped row now.
function Settings:arrowAt(x, y)
    if not self.lay then return nil end

    local padX, padY = pad()
    for i, row in ipairs(rows) do
        if row.kind == "choice" then
            for dir = -1, 1, 2 do
                local ax, ay = self:arrowBox(i, dir)
                if x >= ax - padX and x <= ax + ARROW + padX
                    and y >= ay - padY and y <= ay + ARROW + padY then
                    return i, dir
                end
            end
        end
    end
end

function Settings:backAt(x, y)
    local bx, by, bw, bh = Hud.cornerTarget(self.game)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

-- The heading, measured off the lettering rather than off the page: the word is
-- centred on `lay.cx` and drawn at HEAD_SCALE, so this box is exactly what is on
-- the screen, padded like every other target here and by more on touch.
function Settings:headAt(x, y)
    if not self.lay then return false end

    local text = I18n.t(HEAD)
    local w, h = Font.width(text) * HEAD_SCALE, Font.height * HEAD_SCALE
    local hx = math.floor(self.lay.cx - w / 2)
    local padX, padY = pad()

    return x >= hx - padX and x <= hx + w + padX
        and y >= self.lay.head - padY and y <= self.lay.head + h + padY
end

-- One tap on the heading. Three inside the window throw the switch and the next
-- three throw it back, so the gesture is the way in and the way out -- with the
-- exception src/dev.lua names: a book whose unlocks are overridden shows the row
-- whatever this said, because that is the row that puts it back.
--
-- The count is dropped when the window lapses rather than kept, so a tap now and
-- two next time is not a reveal, and the tap is *not* swallowed: ink still lands
-- on the word and fades off it like ink anywhere else on this page. A heading
-- that ate your pen would be a heading announcing that something is behind it.
function Settings:tapHead()
    if self.t - self.tapAt > TAP_WINDOW then self.taps = 0 end
    self.tapAt = self.t
    self.taps = self.taps + 1
    if self.taps < TAPS then return end

    self.taps = 0
    Dev.shown = not Dev.shown
    self.dirty = true
    self:bank()
    -- The sound a box makes when it takes an answer, because that is what this
    -- is: the page has nothing else to say that it heard you.
    Sfx.play("accept")
end

--- moving things -------------------------------------------------------------

-- Where along the track a point is, as 0 to 1. Measured against the *inner*
-- track rather than the box, so dragging to the last pixel of it is full and the
-- border is not a stretch of bar you cannot reach.
function Settings:levelAt(i, x)
    local bx = self:barBox(i)
    return util.clamp((x - (bx + 1)) / (BAR_W - 2), 0, 1)
end

function Settings:setLevel(i, value)
    rows[i].set(util.clamp(value, 0, 1))
    self.dirty = true
    -- The rubbing loop is the one voice that can be playing while this happens,
    -- and it is retuned where it stands rather than being left at the level it
    -- started on (src/sfx.lua).
    Sfx.retune()
end

-- A drag ending is when the file is written, and when the level is played back:
-- one sound at the level you just set, which is the only way to know whether it
-- is the level you wanted.
--
-- Only for the sound row, and the music row wants nothing: playing an effect to
-- demonstrate the *music* volume would be demonstrating the wrong number, and the
-- track is already at the level the bar was let go at -- retuned where it stands
-- while the finger was still down (Sfx.retune), so there is nothing left to
-- announce.
function Settings:landLevel(i)
    if rows[i].key == "sfx" then Sfx.play("accept") end
    self:bank()
end

-- A step is made where it is pressed rather than banked: it is a whole move and
-- there is no finger to wait for. `dirty` is set first so a step that changes
-- nothing it can see still writes the file.
function Settings:stepChoice(i, dir)
    rows[i].step(dir)
    self.row = i
    self.dirty = true
    Sfx.play("transition")
    self:bank()
end

function Settings:bank()
    if not self.dirty then return end
    self.dirty = false
    Options.save()
end

--- update --------------------------------------------------------------------

-- Ink that misses everything is ink on the page and fades off it. A bar, an arrow
-- and the corner button all swallow whatever crosses them rather than being drawn
-- on: a press on any of them was taken as a press rather than as the start of a
-- line, which is the rule the timetable's tabs and the library's names are
-- already held to.
-- Answers whether the stamp became ink, for the pen's swish (src/scribble.lua).
-- It matters most here: a bar is dragged the width of the page and lays not one
-- pixel of line, so a pen that sounded off the pointer instead of off the ink
-- would swish all the way along a volume the player is trying to hear.
function Settings:mark(x, y)
    if self.dragging then return false end
    if self:barAt(x, y) or self:arrowAt(x, y) or self:backAt(x, y) then
        return false
    end
    self.marks:add(x, y)
    return true
end

-- The press edge. What is latched here is latched for the whole stroke, exactly
-- as the studio latches whether a stroke is drawing or answering: a bar you have
-- hold of stays the bar you have hold of even when the finger leaves the track,
-- because a drag that let go the moment you strayed a pixel off a seven pixel bar
-- would be a drag you could not do.
function Settings:press(x, y)
    if self:backAt(x, y) then
        self.back = true
        return
    end

    local i, dir = self:arrowAt(x, y)
    if i then
        self:stepChoice(i, dir)
        return
    end

    i = self:barAt(x, y)
    if i then
        self.dragging = i
        self.row = i
        self:setLevel(i, self:levelAt(i, x))
        return
    end

    -- Last of everything, so a control wins wherever its padded box overlaps the
    -- heading's: the gesture may never cost somebody a press they meant to make.
    if self:headAt(x, y) then self:tapHead() end
end

-- Returns "back" the moment the corner button is pressed, and nothing at all
-- otherwise. There is nothing else for this screen to answer with: it hands
-- nothing over, and what it changes it changes where it stands.
function Settings:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.back then
        -- A drag interrupted by the way out is still a drag that happened.
        self:bank()
        return "back"
    end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    -- The pen is tracked either way, since a stroke that misses everything is
    -- still a line on the page -- but while a bar is held the pointer belongs to
    -- the bar and lays no ink.
    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    if self.dragging then
        if down then
            self:setLevel(self.dragging, self:levelAt(self.dragging, Input.pointerX))
        else
            local i = self.dragging
            self.dragging = nil
            self:landLevel(i)
        end
    end

    if self.back then
        self:bank()
        return "back"
    end
end

-- Up and down walk the rows, which on a keyboard is how a list of settings is
-- read; left and right move whatever the row on is. Backspace is the corner
-- button, exactly as it is on the timetable and in the library.
function Settings:keypressed(key)
    if key == "backspace" then
        self.back = true
        return
    end

    if key == "up" or key == "w" then
        self.row = (self.row - 2) % #rows + 1
        return
    end
    if key == "down" or key == "s" then
        self.row = self.row % #rows + 1
        return
    end

    local dir = (key == "left" or key == "a") and -1
        or ((key == "right" or key == "d") and 1 or nil)
    if not dir then return end

    local row = rows[self.row]
    if row.kind == "choice" then
        self:stepChoice(self.row, dir)
    else
        self:setLevel(self.row, row.get() + dir * KEY_STEP)
        -- A key press is a whole move rather than the middle of one, so it lands
        -- where it is made instead of waiting for a finger to come up.
        self:landLevel(self.row)
    end
end

--- draw ----------------------------------------------------------------------

-- The bar, its handle and the number beside it: the level as a length, and then
-- as a figure, because a length tells you where you are in the range and a figure
-- tells you whether it is the same as it was yesterday.
--
-- Blue rather than red. The palette splits the page between the two sides of the
-- fight -- red is theirs, blue is yours -- and a volume is about as yours as
-- anything in the game gets.
--
-- The row being read is the one with an ink handle rather than a slate one, which
-- is the only thing on the page saying where the keyboard is: it is deliberately
-- not red, because red on the furniture in this game means armed or full and a
-- row you happen to be standing on is neither.
function Settings:drawBar(i, hot)
    local x, y, w, h = self:barBox(i)
    local level = rows[i].get()

    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)

    local inner = math.floor((w - 2) * util.clamp(level, 0, 1))
    if inner > 0 then
        love.graphics.setColor(Palette.blue)
        love.graphics.rectangle("fill", x + 1, y + 1, inner, h - 2)
    end

    -- The handle sits at the end of the fill and stands a pixel proud of the
    -- track top and bottom, which is what makes it read as something laid across
    -- the bar rather than as the last stretch of it.
    local kx = util.clamp(x + 1 + inner - math.floor(KNOB_W / 2),
        x, x + w - KNOB_W)
    love.graphics.setColor(hot and Palette.ink or Palette.slate)
    love.graphics.rectangle("fill", math.floor(kx), y - KNOB_OVER,
        KNOB_W, h + KNOB_OVER * 2)

    love.graphics.setColor(Palette.slate)
    Font.print(("%d"):format(math.floor(level * 100 + 0.5)),
        self.lay.valueX, y + math.floor((h - Font.height) / 2))
end

-- One arrow, in the corner button's own recipe: a slate box filled with paper and
-- the chevron in the middle of it. The same glyph both ways round -- three
-- columns wide, so its origin is the middle one and the flip is an exact mirror.
function Settings:drawArrow(i, dir)
    local x, y = self:arrowBox(i, dir)

    love.graphics.setColor(Palette.slate)
    love.graphics.rectangle("fill", x, y, ARROW, ARROW)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, ARROW - 2, ARROW - 2)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons.chevron:draw(x + ARROW / 2, y + ARROW / 2, dir > 0)
end

function Settings:hint()
    if Input.usingTouch then return "DRAG A BAR TO SET IT" end
    return "DRAG A BAR OR USE THE ARROWS"
end

function Settings:draw(game)
    local lay = self:layout(game)

    -- Written on the page rather than laid over it, like every other screen off
    -- the title: the ruling shows through the lettering, and the page it shows
    -- through is whichever lesson the book is open at.
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    Scribble.printBig(I18n.t(HEAD), lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    -- The labels, flush to the right of their column so every one of them ends
    -- against the same edge and the controls read as a column rather than as
    -- six things at six depths.
    for i, row in ipairs(rows) do
        local y = self:rowY(i) + math.floor((lay.rowH - Font.height) / 2)
        love.graphics.setColor(i == self.row and Palette.ink or Palette.slate)
        Font.printRight(I18n.t(row.label), lay.labelRight, y)
    end

    -- What each stepped row is set to, between the arrows that step it. Red
    -- because it is a *choice* rather than an amount, and red is what says which
    -- one is picked everywhere else in this game's furniture. A seed apiece, so
    -- the two words wobble as two hands rather than as one stencil.
    for i, row in ipairs(rows) do
        if row.kind == "choice" then
            Scribble.printBig(row.text(), lay.controlCx,
                self:rowY(i) + math.floor((lay.rowH - Font.height) / 2),
                1, Palette.red, { seed = 60 + i })
        end
    end

    Scribble.printBig(I18n.t(self:hint()), lay.cx, lay.hint, 1, Palette.graphite,
        { seed = 61 })

    Overprint.finish()

    -- The bars, the arrows and the way back all go out past the pass: they are
    -- boxes filled in paper, and paper does not survive being paired with the
    -- ruling underneath it -- a border landing on a rule comes out a step darker
    -- and the box reads as a hole cut in the page. The numbers go with the bars
    -- rather than with the lettering, because a bar and what it says are one
    -- object.
    for i, row in ipairs(rows) do
        if row.kind == "level" then
            self:drawBar(i, self.dragging == i or self.row == i)
        else
            self:drawArrow(i, -1)
            self:drawArrow(i, 1)
        end
    end
    Hud.drawCorner(game, "back", false)
end

return Settings
