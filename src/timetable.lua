-- The timetable: which page of the book this run is played on.
--
-- It sits between the title screen and the board your character is drawn on,
-- which is the only place it can sit. The subject decides how the page is ruled
-- and the ruling is what the drawing is read against (src/overprint.lua), so
-- picking it after the hero is drawn would mean drawing him against one page and
-- playing him on another.
--
-- **The lessons are index tabs down the edge of the book.** That is the whole
-- arrangement, and it is the one thing on this screen that is not a metaphor:
-- you are choosing where to open a notebook, and the way a notebook offers you
-- that choice is a column of tabs sticking out of its edge. They run off the
-- right of the sheet, one per subject, stacked; the lesson is written on the tab
-- with the icon of the tool it hands you at the outside end; and the tab of the
-- lesson you are on is **pulled out** into the page, the way the one you have a
-- finger in is.
--
-- The rest of the sheet is the run that lesson would be: the heading, what the
-- lesson gives you and what your best run on that page came to, which class you
-- are sitting it as, the character about to walk out there, and two boxes --
-- `CUSTOM` to change him and `GO!` to start: a row at the foot on a wide page,
-- apart on a page held upright (`Timetable:panel`).
--
-- **A tab is pressed, not answered, and that is deliberate.** Everything this
-- game asks you, you answer by drawing (src/scribble.lua) -- but a tab is not a
-- question. It is where the book is open, the same kind of thing as the tool
-- selector down the side of a run: you put your finger on one and the book falls
-- open there, page and all. Nothing is spent and nothing is decided, so nothing
-- needs the ceremony of being drawn. The one question on this screen is `GO!`,
-- and that is a box you scribble in like every other question in the game -- and
-- the only bordered box here, which is what makes it read as the answer you
-- cannot take back.
--
-- Two things about the tabs are load-bearing:
--
-- **A tab is card, so it is opaque.** Every one of them is filled in
-- `Palette.paper`, the one colour that covers what is under it rather than
-- stacking with it, and the whole column is drawn *after* the overprint pass so
-- that nothing on a tab is paired with the page under it either -- the border and
-- the lesson are the flat colour they say they are, the way the draft's cards
-- are. Nothing here is a window: what a tab has to carry is a word and an icon,
-- and a page of squares or staves showing through either of them is a pattern
-- competing with the only two things on the tab worth reading.
--
-- **Picking is not leaving.** A tab selects -- the page under the whole screen
-- turns to that ruling, the panel fills in with that lesson's tool and records --
-- and only `GO!` leaves. Seven tabs that went straight to the drawing board would
-- be seven doors with nothing written on them, and the thing worth writing on
-- them (what the lesson hands you, what you have already done with it) has to be
-- somewhere you can stand and read it.
--
-- **The class you are sitting it as is the last row of that block** -- `<` the
-- course `>` (src/course.lua), in the column the figures are in, right-aligned
-- like all of them -- and where it went took three goes to get right, which is
-- worth writing down because the answer is a fact about this whole layout.
--
-- It was a column of four cards down the left margin first, showing the whole
-- ladder at once, locked rungs and all. That is genuinely more than a stepper
-- says, and it cost fifty pixels of margin -- which on any page narrower than a
-- desktop one is fifty pixels the *sheet* then has to be walked out of. Then it
-- was a stepper in the margin under the corner button, which cost the sheet
-- nothing but sat with the furniture, away from the thing it is about.
--
-- It is a row of the block now because the block is where it belongs: everything
-- in that column is what this run would be, and which class you are sitting it as
-- is exactly that. What made the row affordable is the row of boxes at the foot of
-- the page -- see `Timetable:panel` -- since moving `CUSTOM` down beside `GO!`
-- handed the column twenty-eight pixels back and a stat row costs seven.
--
-- What a stepper cannot say on its own is that there is *more* ladder, so the `>`
-- says it: slate where there is a rung to step onto, **red** where the ladder goes
-- on but has not been paid for -- red being what this book writes a thing you have
-- to go and do something about in -- and graphite at the top of it, where there is
-- nothing further at all.
--
-- **And the left margin is where the things that are not the question go**, all of
-- them pressed rather than scribbled for exactly the reason a tab is: nothing is
-- decided by any of them.
--
-- The **corner button** in the top left is a back arrow in the same box in the
-- same corner the run's pause button uses (src/hud.lua), and it closes the book
-- back to the title. `GO!` spends the screen and `CUSTOM` spends a detour; going
-- back spends nothing, and it is the one way out of here that does not even
-- settle which lesson you were on. Being the same box in the same corner as the
-- pause button is the whole of what says so: it is the button that backs out of
-- wherever you are, and this screen is a place you can be.
--
-- The **tabs in the bottom left** are the parts of the book that are not
-- lessons: the shop (`CANTEEN`, src/canteen.lua) and, under it, the catalogue
-- (`LIBRARY`, src/library.lua) and the list of what the book still wants from you
-- (`HOMEWORK`, src/homework.lua). They are tabs rather than buttons because that is what they are -- the
-- subjects are index tabs down the right edge of the book and these are the tabs
-- off the *other* edge, at the bottom, where the reference section of a school
-- notebook goes. Each one is cut to exactly a lesson tab, and each runs off the
-- left edge the way a lesson tab runs off the right.
--
-- **The column is stacked flush**, every card at the same edge of the sheet and
-- one gap apart: they are the same piece of card in the same place, the way the
-- lesson tabs down the other edge are. What says one card from the next is the
-- gap between them and the word on each, exactly as it is over there -- a column
-- that stepped its cards into the page would be saying they are a stack with an
-- order to it, and these are three doors that have nothing to do with each other.
--
-- The corner button and that column are why the panel is fitted between them
-- rather than against the page: the left margin has something in it top and
-- bottom, and a sheet measured off the edges of the page would start its heading
-- under the button and finish `GO!` behind the cards.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local Sprites = require("src.sprites")
local Subjects = require("src.subjects")
local Characters = require("src.characters")
local Course = require("src.course")
local Design = require("src.design")
local Upgrades = require("src.upgrades")
local Records = require("src.records")
local Mark = require("src.mark")
local Collection = require("src.collection")
local Sfx = require("src.sfx")
local I18n = require("src.i18n")
local util = require("src.util")

local Timetable = {}

local HEAD = "TODAYS LESSON"
local HEAD_SCALE = 2

-- The lesson's own name, set at the heading's size rather than the panel's. The
-- heading says what kind of thing you are looking at and the name says which one
-- it is, and the second is the answer -- so the two of them are the same size and
-- the five rows under them are the small print.
local NAME_SCALE = 2

-- And the character, at twice the size he is played at where the column has the
-- room for it. Everywhere else in the game a drawing is shown at 1:1 on the
-- grounds that a hero shown any other way is a hero shown a way the game never
-- draws him; here he is the one thing on a sheet of lettering that is not
-- lettering, and eleven pixels of stick man under a heading ten pixels tall reads
-- as a smudge. Whole number, like every scale in the game, so he is still on the
-- pixel grid -- and the step down from it is 1:1 rather than anything between (see
-- `Timetable:panel`).
local HERO_SCALE = 2

-- The two things you can do with a lesson once you have picked it, and the sizes
-- are the difference between them. `GO!` is what this screen is for and it is
-- twice the size of anything else answerable here; `CUSTOM` is the door to the
-- drawing board, which most runs walk past -- a run opens with the character you
-- already have, and the board is where you go when you want a different one.
--
-- They sit in one row at the foot of the page, so the difference in size is now
-- read side by side rather than a page apart -- which is the right way round for
-- it: two boxes the same size with one word twice the other's is a row that says
-- which of the two the screen is for.
local GO = "GO!"
local GO_SCALE = 2
local CUSTOM = "CUSTOM"
local CUSTOM_SCALE = 1

-- The label on the sixth row of the stat block, which is the course selector. It
-- is a word rather than nothing because a bare `< MASTERS >` under a block of
-- records reads as stepping whatever is above it, and what is above it is five
-- records and a lesson name.
local COURSE = "COURSE"

-- The tabs off the other edge of the book, in the corner opposite the back
-- button, listed bottom-up -- which is the order they are stepped into the page
-- in and the order they are written on in. Each carries a word and nothing else:
-- a lesson tab wears the icon of the tool it hands you, and none of these hands
-- you anything -- they are somewhere to go.
--
-- `key` is the keyboard route to each, and the two new ones are H and K: C is
-- the drawing board and there is nothing else in `canteen` to reach for. Nothing
-- on the sheet advertises them -- the screen carries no instructions at all any
-- more, since everything they would have named is a thing on the page you can
-- press.
-- Read *down* the page they are CANTEEN, LIBRARY, HOMEWORK, which is the order
-- the three are worth opening in and the order they stop being about the next run:
-- the counter is what you spend before one, the catalogue is what the run could be
-- dealt, and the homework is about the book rather than about any run at all.
local SIDE = {
    { answer = "homework", label = "HOMEWORK", key = "h" },
    { answer = "library",  label = "LIBRARY",  key = "l" },
    { answer = "canteen",  label = "CANTEEN",  key = "k" },
}

-- Every word on this sheet is measured before it is drawn -- at its widest, and
-- across every lesson and every character, so that nothing moves as the selection
-- changes -- which means a measurement and the draw it is for have to be of the
-- same words. These three are each measured in two or three separate places (a
-- box's width, where the box is placed, and the clamp that keeps the panel clear
-- of the tabs), so the dictionary is asked here rather than at each of them.
local function headText() return I18n.t(HEAD) end
local function goText() return I18n.t(GO) end
local function customText() return I18n.t(CUSTOM) end

local PAD = 4          -- the edge of a tab to the writing on it
local ICON = 11        -- the tool's icon, and every icon in the game is 11x11
local NAME_GAP = 4     -- the lesson to the icon of its tool
local GUTTER = 8       -- the panel to the tabs
local TAB_GAP = 2      -- one tab to the next
local EDGE = 4         -- and off the edge of the page
local HEAD_GAP = 6     -- one thing in the panel to the next
local LINE_GAP = 2     -- one line of lettering to the next
local STAT_GAP = 6     -- the least between a stat's label and its number
local HERO_GAP = 8     -- the last row of the block down to the drawing under it
local ARM_GAP = 3      -- and the character to the thing in his hand
local STACK_GAP = 4    -- one box to the other where the two are stacked

-- How far the picked tab is pulled out into the page. The same trick, and the
-- same four pixels, as the selected slot on the tool selector (src/hud.lua):
-- what you are holding sticks out further than what you are not. It is also the
-- whole of what says a tab is picked, which is why it is worth four pixels of a
-- 320-pixel page.
local TAB_POP = 4

-- And how far every tab runs off the sheet. Only the border and the fill go out
-- there -- nothing written on a tab is ever past the safe edge -- so a phone that
-- hides those four pixels under a notch hides a corner of a rectangle.
local TAB_OVER = 4

-- A tab is as tall as there is room for, between an icon with a pixel to spare
-- above and below it and about twice that. The height is how much of the page
-- opens the book at that lesson, so a short tab is a worse tab: it is what a
-- finger is aimed at.
local TAB_MIN, TAB_MAX = 13, 22

-- Six rows in the block, and the sixth is not a readout: hero, tool, best time,
-- most killed, best mark, and then the course selector. All six are measured
-- whether or not the lesson has been played and whether or not the ladder has been
-- bought, so the panel holds still.
--
-- The selector is the last of them because it is the one row here that is a
-- *question*. The five above it are what has already happened to this page, in the
-- order they read -- who is going, with what, how long, how many, what it came
-- back marked -- and the thing you can still change goes at the foot of that,
-- where it is next to the drawing it is about and the two boxes under it. Reading
-- down, the sheet goes from what the page has been to what it is about to be.
local STAT_ROWS = 6

-- The course selector: a chevron, the course, a chevron. The glyph is
-- `Sprites.icons.chevron` drawn bare rather than in the library's 11px box, which
-- is the whole reason this row fits in the margin at all -- two boxes and their
-- clearances come to forty-four pixels before the word, and the panel would have
-- had to give way for them.
--
-- The row is deeper than the five pixels it draws, and that is for the thumb: what
-- is being pressed is a corner of the page rather than a three-pixel glyph, so
-- each arrow claims a square the size of the corner button's box.
local CHEVRON = 3      -- the glyph is three columns wide, origin the middle one
local COURSE_H = 11    -- the press target on each end, which is the corner
                       -- button's box: what is pressed is a corner of the sheet
                       -- rather than a three-pixel glyph, and the two are allowed
                       -- to be different sizes
local COURSE_GAP = 4   -- a chevron to the word between them

-- One box at the foot of the page to the other. Wider than a gap inside a block
-- and narrower than the draft's `CARD_GAP`, which separates three cards across a
-- whole page: these two are a hand span apart because they are two questions and
-- not two answers to one.
local ACT_GAP = 12

-- `GO!` off the foot of the page in the upright arrangement, so it reads as
-- sitting in its corner rather than wedged into it.
local CORNER_GAP = 12

-- The tabs draw themselves on as the screen opens, one after the next down the
-- edge, and the icon is stamped on once its tab has finished.
local TAB_TIME = 0.18
local TAB_STAGGER = 0.05

local CONFIRM = 0.34   -- the picked tab flashing before the page turns

local function clock(t)
    return ("%d:%02d"):format(math.floor(t / 60), math.floor(t % 60))
end

function Timetable:enter(key)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    -- What was *pressed* rather than answered: "back" for the corner button or
    -- "library" for the tab in the other corner. Both are handed back the instant
    -- they are hit -- see `update` -- so this is a latch for one frame rather than
    -- a state the screen sits in.
    self.pressed = nil
    self.lastAct = nil

    -- The book cannot be handed back open at a page it does not open at. Nothing
    -- in the game can do that -- a run banks a record on the page it was played on
    -- and a page you played was open -- so this is the hand-edited records file
    -- and nothing else, and it costs that file the lesson it was lying about
    -- rather than a screen with no way off it.
    self.current = key or Subjects.default.key
    if not Collection.lessonOpen(self.current) then
        self.current = Subjects.default.key
    end
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the title screen's YES is not this screen's to
    -- read: it draws nothing and presses nothing until it has been lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- One tab per lesson. They are plain rectangles rather than
    -- `Scribble.newChoice` boxes, because nothing about a tab is answered: it is
    -- pressed, and `fill` is here only so the tabs can take their colour from
    -- `Scribble.boxColor` like everything else that is picked, hot or stepping
    -- out of the way.
    --
    -- `open` is asked once, here, rather than at every draw: this screen is where
    -- you stand between runs, so nothing can be earned while it is up and the
    -- answer cannot change under it. It is asked again the next time the book is
    -- opened at this page, which is the frame after a run banked whatever it
    -- earned (`Game:bankRun`).
    self.tabs = {}
    for i, sub in ipairs(Subjects.list) do
        self.tabs[i] = {
            key = sub.key, fill = 0, open = Collection.lessonOpen(sub.key),
        }
    end

    -- And one per tab in the other margin, in the same shape and for the same
    -- reason: nothing about one of these is answered either. They are placed in
    -- `layout` -- what is here is only which they are.
    self.sides = {}
    for i, side in ipairs(SIDE) do
        self.sides[i] = { answer = side.answer, label = side.label, key = side.key }
    end

    -- How far up the ladder the book has enrolled, asked once here rather than at
    -- every draw, for the lesson tabs' reason exactly: this screen is where you
    -- stand between runs, so nothing can be bought while it is up and the answer
    -- cannot change under it -- the counter is a page you have to leave to reach.
    self.rungs = Course.top()

    -- The two questions on this screen, and they are boxes because they are the
    -- only things here that are actually decided: one starts the run and the
    -- other opens the drawing board. Kept as a box apiece rather than as one
    -- two-box choice, the way the pause card keeps its dev switch apart from its
    -- QUIT?, because they are answered at different sizes and mean different
    -- kinds of thing -- and because arming one must not disarm the other.
    self.go = Scribble.newChoice({ { key = "go", label = GO } }, GO_SCALE)
    self.custom = Scribble.newChoice({ { key = "custom", label = CUSTOM } },
                                     CUSTOM_SCALE)

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

--- what a lesson is ----------------------------------------------------------

function Timetable:selectedTab()
    for _, tab in ipairs(self.tabs) do
        if tab.key == self.current then return tab end
    end
end

-- Whether the selector may step that way, and what the arrow at that end is
-- therefore saying. Three answers rather than two: there is a rung to step onto,
-- or the ladder goes on and has not been paid for, or there is nothing beyond.
-- Asked off `self.rungs` rather than of src/course.lua, so the whole screen is
-- answering out of the one set of answers taken when it opened.
function Timetable:courseStep(dir)
    local i = Course.current.index + dir
    if i < 1 or i > #Course.list then return "end" end
    return i <= self.rungs and "open" or "unpaid"
end

-- Whether the book opens at the page it is turned to (`Collection.rungs`). Read
-- off the tab rather than asked of the collection again, so the whole screen is
-- answering out of the one set of answers taken when it opened.
--
-- This is the only thing on the screen `GO!` is conditional on, and everything
-- that touches that box asks it: the ink that lands in it, the press that fills
-- it, the key that answers it, the flash that spends the screen and the drawing of
-- the box itself. A shut lesson is otherwise a lesson like any other -- you turn
-- to it, the page turns with you, and what the panel has to say is why it will not
-- open rather than how your best run on it went.
function Timetable:openHere()
    local tab = self:selectedTab()
    return tab == nil or tab.open
end

-- The rows of the panel: who is going out there, what the lesson hands him, and
-- what you have done with it. That is the order the panel reads in and it is the
-- order they are listed in -- who, with what, how it went.
--
-- The hero row is the one line here that is not the lesson's (it is the character
-- picked on the board, src/characters.lua) and it is first anyway, because it is
-- the one thing on this screen you would otherwise have to go two screens away to
-- find out. The lettering does not say so: a label and a value is what all five
-- of these are, and singling this one out would be saying that which hero you are
-- is a stranger fact than which tool you have.
--
-- The tool is read out of the upgrade catalogue rather than out of src/tools.lua,
-- for the same reason the subject names a line there -- a tool line's first level
-- is its unlock, so the line is what a lesson issues.
--
-- A lesson with no record on it says so once rather than printing two zeroes: a
-- run that lasted 0:00 and killed nothing is a thing that could have happened,
-- and the panel must not look like it did.
--
-- **The mark is the last row and it is the only one in red**, which is the two
-- things worth saying about it. Last because it is what the page came back with
-- rather than another thing the run counted -- the two rows above it are the
-- numbers, and the letter is what a teacher wrote over the top of them. Red
-- because that is the only colour a mark is ever in (src/mark.lua): every other
-- value in this block is ink, and the grade is red pen on all three screens that
-- print one.
--
-- It is derived rather than kept. `Mark.forRun` is the only door to a grade and
-- the register keeps what it reads -- the longest run on the page, and whether a
-- run on it has put the boss down -- so the best mark is that door asked about
-- the best run, and nothing has to be filed or migrated for it. Which also means
-- a step added to the ladder re-marks every page in the book at once, the same
-- way it re-prices every grade above it.
-- The widest course in the book, in the language it will be lettered in. Asked
-- twice -- the selector is cut to it, and the stat block's clock row reserves room
-- for it -- so it is here rather than at both.
local function courseWidth()
    local w = 0
    for _, row in ipairs(Course.list) do
        w = math.max(w, Font.width(I18n.t(row.name)))
    end
    return w
end

-- The whole control, which is what the value column has to hold on its row.
local function selectorWidth()
    return CHEVRON + COURSE_GAP + courseWidth() + COURSE_GAP + CHEVRON
end

local function statRows(key)
    local sub = Subjects.get(key)
    local up = Upgrades.byId[sub.tool]
    local rec = Records.get(key)
    local played = Records.played(key)

    -- Read through the dictionary here rather than at the draw, because these
    -- rows are what `statWidth` measures the panel from: a block measured on HERO
    -- and TOOL and then lettered HEROE and UTIL is a block the lettering runs out
    -- of. A clock and a kill count are numbers and are nobody's language, and a
    -- grade is a letter rather than a word -- an A is an A on either page.
    return {
        { I18n.t("HERO"), I18n.t(Characters.current.name) },
        { I18n.t("TOOL"), I18n.t(up.name) },
        -- The clock and the class it was run at, on **one row**, because they are
        -- one fact: 8:31 means one thing sat at high school and another sat at a
        -- doctorate (src/records.lua), so a register that printed the number
        -- without the class would have forgotten the harder half of what you did.
        --
        -- One row rather than two, and that is a layout decision rather than a
        -- tidy-up. Every row here is five pixels and a gap, and the sixth row this
        -- started life as cost seven pixels of column -- which is exactly the seven
        -- that decide whether the character below is drawn at twice the size he is
        -- played at or at once (see `Timetable:panel`). A drawing of who is walking
        -- out there is worth more than a second label, so the course rides along
        -- the row it is about and the panel is the height it always was.
        { I18n.t("BEST"),
          played and ("%s  %s"):format(clock(rec.time),
              I18n.t(Course.get(rec.course).name)) or "--" },
        { I18n.t("MARK"),
          played and Mark.forRun(rec.time, (rec.bosses or 0) >= 1) or "--",
          Palette.red },
    }
end

--- layout --------------------------------------------------------------------

-- Every tab is the same width and the lessons all start at the same pixel, so
-- the column reads as one block of tabs rather than as seven labels of different
-- lengths hanging off the edge.
local function nameWidth()
    local w = 0
    for _, sub in ipairs(Subjects.list) do
        w = math.max(w, Font.width(I18n.t(sub.name)))
    end
    return w
end

-- The stat block is measured across *every* lesson rather than the one on show,
-- so the numbers stay in one column as you move down the tabs. A block that
-- resized itself around each lesson's tool name would be a panel that twitched
-- every time you changed your mind.
local function statWidth()
    local labelW, valueW = 0, 0
    for _, sub in ipairs(Subjects.list) do
        for _, row in ipairs(statRows(sub.key)) do
            labelW = math.max(labelW, Font.width(row[1]))
            valueW = math.max(valueW, Font.width(row[2]))
        end
    end

    -- And across every character, not the one showing: the hero row is the one
    -- value here that changes without the tabs being touched, so stepping the
    -- roster on the board and coming back must not resize the panel it comes
    -- back to.
    for _, char in ipairs(Characters.list) do
        valueW = math.max(valueW, Font.width(I18n.t(char.name)))
    end

    -- And the clock row at its widest, which is a clock and the longest course in
    -- the book beside it rather than whatever is on the record showing: it is the
    -- other value in the block that can change without the tabs being touched,
    -- since a run banked on this page rewrites it.
    valueW = math.max(valueW,
        Font.width("0:00") + Font.width("  ") + courseWidth())

    -- And the sixth row, which `statRows` does not return because it is a control
    -- rather than a reading. Measured into the same two columns all the same --
    -- that is what makes it a row of the block -- so the label column holds its
    -- word and the value column holds the whole selector.
    labelW = math.max(labelW, Font.width(I18n.t(COURSE)))
    valueW = math.max(valueW, selectorWidth())

    return labelW + STAT_GAP + valueW
end

-- What the character has in his hand, at the size it will actually be: the sword
-- he swings or the shot he sends (`design` in src/characters.lua), which is the
-- other drawing he is made of and the only thing on this screen that says which
-- one he has. Measured across the whole roster rather than for the character
-- showing, so stepping the roster on the board and coming back does not move the
-- stats beside it -- everything in this panel is measured at its widest.
local function armSize()
    local w, h = 0, 0
    for _, char in ipairs(Characters.list) do
        local design = char.design and Design.by[char.design]
        if design then
            w = math.max(w, design.w)
            h = math.max(h, design.h)
        end
    end
    return w, h
end

-- The sheet, and every last thing on it is read straight down the middle: the
-- heading, the lesson under it at twice the size of anything else written here,
-- the five rows of what this run would be, the character who would be walking out
-- there, the box that changes him, and `GO!` at the foot of the page.
--
-- That line is the middle of the **screen** -- not the middle of what the tabs
-- left over, which is a different line and reads as being slightly out rather
-- than as being centred. The tabs are off the sheet at their edge, so what they
-- take is margin; the page they leave is still the whole page, and the thing this
-- screen is about goes down the middle of it. Where a narrow page would put a
-- centred block under the tabs, the line steps left by exactly as much as it
-- takes to clear them.
--
-- **The character is in that column and not beside it**, which is the one
-- decision here worth writing down. He used to stand out in the left margin with
-- `CUSTOM` under him, on the argument that he is not what the screen is choosing
-- and so is not what it should be centred on -- and what that actually bought was
-- a hero standing in the margin the tabs are stacked in, a hand span from a
-- column of card, with the sheet reading as two things that had been laid out
-- separately. He is who is going out to whatever the tabs pick, and the order the
-- column reads in says so on its own: what today is, which lesson, how it has
-- gone, which class you are sitting it as, and who is going out there.
--
-- **And the two boxes are both at the foot, out of the column altogether**, which
-- is the newest decision here and the one the rest of this layout now rests on.
-- `CUSTOM` used to sit directly under the character on the argument that it is the
-- door to *him* rather than to the lesson, and `GO!` alone at the very foot on the
-- argument that the one answer which spends the screen should be where nothing
-- else is. Both were true; between them they cost the column twenty-eight pixels
-- out of its middle, which is where the drawing is, and twenty-eight pixels is the
-- difference between the character being drawn at twice the size he is played at
-- and at once. A word under him is a worse way of serving him than a bigger
-- drawing of him. See `Timetable:panel` for the two arrangements the foot has and
-- which page gets which.
--
-- **There are no hint lines above it any more.** The three of them -- what to
-- scribble, which keys pick a tab, which keys answer what -- were a paragraph of
-- instructions sitting in the space the character now stands in, and everything
-- they named is a thing on the page you can press. What is left to say is said by
-- the page itself: a box warms slate to blue to red as it fills, which is how
-- every question in this game says it is being answered.
--
-- Every part of the sheet is still measured at its widest and tallest -- the
-- longest lesson name in the book, the widest tool name, the longest character
-- name, the longest course, every weapon in the roster, all six rows of the block
-- whether or not there is anything to put in them -- so nothing moves as you go
-- down the tabs.
--
-- The character is the one part that can be dropped, and it is height that drops
-- him rather than width, since he is in the column instead of beside it. He goes
-- first because he is the only part that says nothing you cannot read elsewhere:
-- the board two screens on is where you actually deal with him. Nothing has to
-- close up behind him any more -- the boxes are at the foot in both arrangements,
-- so the column simply ends at the stats.
--
-- `top` is the first row the sheet may have and `bottom` the last, and neither
-- is measured off the safe edge: the corner button has the rows above and the
-- column of tabs in the left margin the rows below, and those are the only things
-- on this screen a stroke cannot be drawn over.
--
-- Read in order, this function decides which arrangement the two boxes are in,
-- the middle line, where they actually land, how much height that leaves the
-- column, how big the character can be in it, and how what is left over is spent.
-- Each one needs the last.
function Timetable:panel(lay, top, bottom)
    local hero = Sprites.player
    local headH = Font.height * lay.headScale
    local nameH = Font.height * lay.nameScale

    -- **The two boxes are one row at the foot of the page**, `CUSTOM` then `GO!`,
    -- and that is worth the paragraph because it used to be the other way and the
    -- other way was argued for. `GO!` was alone at the foot on the grounds that it
    -- is the one answer that spends the screen, and `CUSTOM` sat directly under
    -- the character on the grounds that it is the door to *him* rather than to the
    -- lesson. Both of those are true and neither was worth what it cost: a box is
    -- twenty pixels deep and it was taking twenty-eight out of the middle of the
    -- column, which is where the drawing of the character is -- and the drawing is
    -- the one thing on this sheet that says anything a word could not. Twenty-eight
    -- pixels is the difference between him being drawn at twice the size he is
    -- played at and at once, on a phone and on a 16:9 page alike.
    --
    -- So the two of them share the row nothing else is in, and the sheet spends
    -- what that frees on the two things it is actually about: the class you are
    -- sitting the lesson as, and how big the hero is. `CUSTOM` is still the door to
    -- the character -- it is just no longer captioning him, and a bigger drawing of
    -- him serves him better than a word underneath did.
    --
    -- They are still two separate `Choice`s placed side by side rather than one
    -- two-box choice, which is the same reason they were two when they were apart:
    -- they are answered at different sizes, they mean different kinds of thing, and
    -- arming one must not disarm the other.
    lay.customW = Font.width(customText()) * CUSTOM_SCALE
                + Scribble.LABEL_GAP + Scribble.BOX_W
    lay.goW = Font.width(goText()) * GO_SCALE + Scribble.LABEL_GAP + Scribble.BOX_W

    -- Both boxes are `Scribble.BOX_H` deep whatever their label is set at, so a
    -- row of them is one height and the words ride in the middle of it.
    local actH = math.max(Scribble.BOX_H, Font.height * GO_SCALE)
    local pairW = lay.customW + ACT_GAP + lay.goW
    local stackW = math.max(lay.customW, lay.goW)

    lay.statW = statWidth()
    lay.courseW = selectorWidth()
    local statsH = Font.height * STAT_ROWS + LINE_GAP * (STAT_ROWS - 1)

    -- The character and what is in his hand, at the size they will be drawn: the
    -- sword he swings or the shot he sends, measured across the whole roster so
    -- stepping it on the board and coming back moves nothing.
    local armW, armH = armSize()
    local heroW = hero.w + (armW > 0 and ARM_GAP + armW or 0)
    local heroH = math.max(hero.h + 1, armH) -- the ground under him, and the bounce

    -- What counts as room to spare, the drawing's own row deep because the drawing
    -- is what the room is for.
    local SPARE = heroH * HERO_SCALE

    -- The column, top to bottom, and its width is the widest row in it -- the
    -- character and his box included, since they are rows of it now rather than
    -- something standing alongside. He is measured at the *biggest* size he could
    -- be drawn at, whatever size the column ends up giving him, because this is
    -- what the middle line is clamped off and that line may not move as a page
    -- gets shorter, or as one gets taller and steps him up (`panel`'s ladder).
    local colW = math.max(Font.width(headText()) * lay.headScale,
                          nameWidth() * lay.nameScale, lay.statW,
                          heroW * HERO_SCALE)
    local statsBottom = headH + HEAD_GAP + nameH + HEAD_GAP + statsH

    -- The one line everything on this sheet is centred on. It gives only where the
    -- page is narrow enough that a centred block would run under the tabs, and
    -- then only by as much as that: the widest thing on the middle line is walked
    -- left until it clears them. Everything centred is measured into that one
    -- clamp -- the column and whatever is at the foot -- so they all stay on the
    -- same line as each other whatever the page does.
    local function centre(wide)
        return math.max(lay.textX + math.ceil(wide / 2),
                        math.min(lay.pageCx,
                                 lay.textX + lay.textW - math.ceil(wide / 2)))
    end

    -- **Whether the two boxes share the foot is a question about the page**, and
    -- this is where it is answered. The pair is about 120 pixels in English and
    -- 150 in Spanish, and the foot of the page also has the three cards in the
    -- left margin on it -- so on a page around 240 across in Spanish the doors and
    -- the lesson tabs take two thirds of the width between them and the pair does
    -- not fit in what is left.
    --
    -- Where it does not, they **stack** instead -- `CUSTOM` over `GO!`, both
    -- centred, still both at the foot -- which is narrow enough to clear those
    -- cards on any page this game is handed. Stacking rather than putting `CUSTOM`
    -- back in the column, which is what this screen did before the pair: a second
    -- row at the foot costs twenty-four pixels and a box in the column costs
    -- twenty-eight, so the stack is the cheaper of the two fallbacks by eight
    -- pixels *and* it keeps the column free of boxes in both arrangements. Which
    -- is the whole point of having moved them: the column is the run, and the run
    -- is what this screen is for.
    --
    -- Asked by laying the pair out and looking rather than by a width sum: what
    -- decides it is where the row actually lands once `cx` has been clamped, and
    -- `cx` depends on how wide the widest thing on the middle line is, which is
    -- the thing being decided. Two passes is cheaper than an argument about it.
    -- Whether the foot can be lifted clear over the cards and the column still
    -- print under them at the size it wants. A wide page never can; a page held
    -- upright has the height going spare, and lifting keeps the middle line where
    -- walking the row sideways off it does not.
    local blockMin = statsBottom + HERO_GAP + heroH * HERO_SCALE
    local function liftedY(h) return lay.sideTop - EDGE - h end
    local function canLift(h)
        return liftedY(h) - HEAD_GAP - math.max(top, lay.underButton) >= blockMin
    end

    -- **And a page held upright is given the two boxes apart.** The pair exists
    -- because a box in the column costs twenty-eight pixels of the drawing, and a
    -- page with a hundred going spare is not paying that: `CUSTOM` goes back under
    -- the character it is the door to, and `GO!` takes the corner the cards in the
    -- other margin leave empty, on its own, which is what the one answer that
    -- spends the screen was owed all along. Only where that corner clears the
    -- cards, sits under the last lesson tab rather than beside it, and the column
    -- can carry `CUSTOM` on its end with `SPARE` still left over.
    local cornerX = lay.sideRight
                  + math.floor((lay.tabRight - lay.sideRight - lay.goW) / 2)
    local cornerY = bottom - actH - CORNER_GAP
    local corner = cornerX >= lay.sideRight + EDGE
               and cornerY >= lay.tabBottom + EDGE
               and liftedY(0) - math.max(top, lay.underButton)
                   >= blockMin + HERO_GAP + actH + SPARE

    local paired = false
    local cx

    if corner then
        -- `CUSTOM` is a row of the column now and is measured into the middle line
        -- like every other row of it; `GO!` is the one thing here off that line.
        cx = centre(math.max(colW, lay.customW))
    else
        paired = true
        cx = centre(math.max(colW, pairW))
        if cx - math.floor(pairW / 2) < lay.sideRight + EDGE
           and not (pairW <= lay.textW and canLift(actH)) then
            paired = false
            cx = centre(math.max(colW, stackW))
        end
    end

    lay.corner = corner
    lay.paired = paired
    lay.actsW = paired and pairW or stackW
    lay.cx = cx

    -- The sheet starts at the top of the page rather than under the corner
    -- button, which is the library's rule (src/library.lua) taken for the
    -- library's reason: everything on this screen is centred on the page while
    -- the button is out in the margin, dozens of pixels away on every page the
    -- game is handed, and starting the column under it spends that height on
    -- nothing. The guard is the narrow page or the long heading where the two
    -- would actually meet -- there the column steps down under the button, since
    -- the button is the one thing here that cannot move.
    if cx - math.ceil(colW / 2) <= lay.buttonRight + EDGE then
        top = math.max(top, lay.underButton)
    end

    -- What the column carries on its end -- `CUSTOM` and the gap above it, or
    -- nothing -- added into every height it is measured by below, so the box is a
    -- row of the block rather than something the block is kept clear of.
    local tailH = corner and HERO_GAP + actH or 0
    local availH

    if corner then
        -- `CUSTOM` is placed with the drawing, once there is a drawing to put it
        -- under, and the column runs down to the cards rather than to a foot.
        lay.goX, lay.goY = cornerX, cornerY
        lay.customX = cx - math.floor(lay.customW / 2)
        lay.actsX, lay.actsY = cornerX, cornerY
        availH = liftedY(0) - top
    else
        -- The foot of the page, from the bottom up: it is the one thing here
        -- pinned to an edge rather than fitted between two, and the column has
        -- what is left. Centred on the same line the column is centred on, so the
        -- sheet reads down one middle from the heading to the answer.
        local footH = paired and actH or actH * 2 + STACK_GAP
        lay.actsX = cx - math.floor(lay.actsW / 2)
        lay.actsY = bottom - footH

        -- Unless the page is narrow enough that the foot of it and the column
        -- of cards in the left margin are the same corner. A box with a card
        -- lying across it is not a box you can answer, so it has to move, and
        -- there are two ways to move it which cost completely different things.
        -- Walking the foot right off the middle line costs the sheet a little
        -- symmetry on a page nobody would call symmetrical anyway; lifting it
        -- over the cards costs the column every row below the stats, the
        -- drawing included.
        --
        -- So the page is asked what it can afford. **Where there is height to
        -- spare it is lifted** -- and the boxes stay on the middle line the
        -- heading and the drawing are on. Where there is not, it is walked
        -- sideways as before, and only a page with neither to give gets both.
        local clear = lay.sideRight + EDGE
        if lay.actsX < clear then
            if canLift(footH) then
                lay.actsY = liftedY(footH)
            elseif clear + lay.actsW <= lay.tabX - EDGE then
                lay.actsX = clear
            else
                lay.actsY = math.min(lay.actsY, liftedY(footH))
            end
        end

        -- The middle of the foot rather than the middle of the sheet, which are
        -- the same line until the clause above has moved one of them.
        local actsCx = lay.actsX + math.floor(lay.actsW / 2)

        if paired then
            lay.customX, lay.customY = lay.actsX, lay.actsY
            lay.goX = lay.actsX + lay.customW + ACT_GAP
            lay.goY = lay.actsY
        else
            -- Each centred on its own width rather than flush to one edge,
            -- since the two are two questions rather than a list -- and `GO!`
            -- at the very foot, because it is the one that spends the screen.
            lay.customX = actsCx - math.floor(lay.customW / 2)
            lay.customY = lay.actsY
            lay.goX = actsCx - math.floor(lay.goW / 2)
            lay.goY = lay.actsY + actH + STACK_GAP
        end

        -- What the column has to fit in: everything above the foot, with a row
        -- of clearance so the boxes never read as its last line.
        availH = lay.actsY - HEAD_GAP - top
    end

    -- The character is the row that gives, and he gives in two steps rather than
    -- one: twice the size he is played at where the column has the room for it,
    -- 1:1 where it does not, and dropped where even that will not fit. The middle
    -- step is worth having because the drawing is the player's own and can be any
    -- height at all -- a tall hero on a short page used to be a hero not shown --
    -- and because 1:1 is not a compromise so much as the size he is drawn at
    -- everywhere else in the game.
    --
    -- Dropped, the block is the heading and the stats and nothing else, so the
    -- sheet loses a drawing rather than growing a hole where one was.
    --
    -- The test is the whole of what moving the boxes bought. It used to have a box
    -- and the gap above it on the end of it -- twenty-eight pixels standing between
    -- the character and the foot of the page -- and it does not any more on the two
    -- arrangements that keep the boxes at the foot. A 20px drawing now clears
    -- twice-size on every page this game is handed, including a phone with a notch
    -- in it, where it did not before. The upright arrangement carries that row
    -- again (`tailH`), and can, being only ever taken where those pixels are spare.
    --
    -- The ladder runs up as well, past twice size, on a page with more height than
    -- the sheet has rows. A step up has to leave `SPARE` behind -- a page filled to
    -- its edges has been run out of rather than used -- and may not come out wider
    -- than `colW`, which is the width `lay.cx` was clamped off, so a taller page
    -- cannot move the heading sideways. Both together leave a wide page exactly
    -- where it was: there a third size fits by six pixels and leaves nothing.
    lay.heroScale = nil
    for _, scale in ipairs({ 4, 3, HERO_SCALE, 1 }) do
        local h = statsBottom + HERO_GAP + heroH * scale + tailH
        local room = scale <= HERO_SCALE
                  or (availH - h >= SPARE and heroW * scale <= colW)
        if h <= availH and room then
            lay.heroScale = scale
            break
        end
    end

    local withHero = lay.heroScale ~= nil
    local blockH = statsBottom + tailH
                 + (withHero and HERO_GAP + heroH * lay.heroScale or 0)

    -- **Centred as one lump while the page can hold the sheet in a glance, and
    -- spread where it cannot.** Splitting a few pixels of slack between the two
    -- ends is what sits the sheet in the middle of the page; splitting a hundred
    -- makes two holes, one above the heading and one under the drawing, with the
    -- writing marooned between them. So a page with that much to spare is filled
    -- the way a page of a notebook is -- the writing at the top, the drawing in the
    -- middle of what is left under it -- and the heading starts below the corner
    -- button rather than level with it, fifteen pixels nobody else wanted.
    local slack = availH - blockH
    local spread = slack >= SPARE

    local y = spread and math.max(top, lay.underButton)
                     or math.max(top, math.floor(top + slack / 2))

    -- Where the drawing lands: hard under the stats on a centred page, floating in
    -- the middle of what is left below them on a spread one -- with whatever the
    -- column carries after it, since a box under the character stays under him.
    local heroY = y + statsBottom + HERO_GAP
    if spread and withHero then
        local band = availH - (y - top) - statsBottom - HERO_GAP
        heroY = heroY + math.floor((band - heroH * lay.heroScale - tailH) / 2)
    end

    -- And the box that captions him, on the gap the rest of the column is written
    -- to.
    if corner then
        lay.customY = HERO_GAP
            + (withHero and heroY + heroH * lay.heroScale or y + statsBottom)
    end

    lay.head = y
    lay.name = y + headH + HEAD_GAP
    lay.stats = lay.name + nameH + HEAD_GAP
    lay.statX = cx - math.floor(lay.statW / 2)

    -- The selector on the last row of the block, laid to the block's own grid: the
    -- label in the column the labels are in and the control in the column the
    -- values are in, right-aligned like every figure above it. Which is what makes
    -- it read as a row of the block rather than as something parked between the
    -- block and the drawing -- it is the sixth row, and the only one you can
    -- answer.
    lay.courseY = lay.stats + (STAT_ROWS - 1) * (Font.height + LINE_GAP)
    lay.courseX = lay.statX + lay.statW - lay.courseW

    if withHero then
        -- The hero's corner, not his origin: he is drawn inside a transform
        -- scaled by `lay.heroScale` (see `drawHero`), so everything below is in the
        -- drawing's own pixels and only this pair is in canvas pixels.
        --
        -- Centred as a *pair* -- him and what he is holding -- rather than him
        -- centred with the arm hung off one side, since the two of them together
        -- are the row.
        lay.heroX = cx - math.floor(heroW * lay.heroScale / 2)
        lay.heroY = heroY

        -- A pixel down for the bounce to lift him back out of.
        lay.heroDrawY = hero.oy + 1

        -- The middle of the space every weapon in the roster would fit in, on the
        -- character's own midline: what is in his hand hangs beside him at the
        -- height of his hands, and the widest one decides the row so a sword and
        -- a pellet start from the same pixel.
        if armW > 0 then
            lay.armX = hero.w + ARM_GAP + math.floor(armW / 2)
            lay.armY = lay.heroDrawY
        end
    end

    -- Placed rather than laid out as a strip: the two boxes are two separate
    -- choices sharing a row, and `Choice:layout` would take them both over.
    self.custom:place(self.custom.boxes[1],
        lay.customX + Font.width(customText()) * CUSTOM_SCALE + Scribble.LABEL_GAP,
        lay.customY)
    self.go:place(self.go.boxes[1],
        lay.goX + Font.width(goText()) * GO_SCALE + Scribble.LABEL_GAP, lay.goY)
end

-- The tabs are hung off the right edge of the sheet and everything else has what
-- is left. They are the one thing here that never gives: a lesson you cannot read
-- is worse than a panel with less room than it wanted, and the panel has
-- somewhere to go -- the title drops to single size, and then the character goes.
function Timetable:layout(game)
    local ins = game.inset
    local availW = game.vw - ins.l - ins.r
    local availH = game.vh - ins.t - ins.b

    local left = ins.l + EDGE
    local right = ins.l + availW      -- the safe edge: the tabs run off it
    local n = #self.tabs

    local lay = {}

    -- A tab holds the lesson and the icon of its tool, and this is the least it
    -- can be and still hold both.
    lay.tabW = PAD + nameWidth() + NAME_GAP + ICON + PAD
    lay.tabX = right - lay.tabW
    lay.tabRight = right

    lay.tabH = util.clamp(math.floor((availH - TAB_GAP * (n - 1)) / n),
                          TAB_MIN, TAB_MAX)

    local columnH = n * lay.tabH + TAB_GAP * (n - 1)
    local top = math.max(ins.t, math.floor(ins.t + (availH - columnH) / 2))

    -- Where the column runs out, which is what the panel asks of it before putting
    -- anything in the corner under it.
    lay.tabBottom = top + columnH

    for i, tab in ipairs(self.tabs) do
        -- The picked tab is pulled out into the page, and it is the tab itself
        -- that moves: what you press is the tab as it is drawn.
        local out = tab.key == self.current and TAB_POP or 0

        tab.x = lay.tabX - out
        tab.y = top + (i - 1) * (lay.tabH + TAB_GAP)
        tab.w, tab.h = lay.tabW + out, lay.tabH
        tab.fill = out > 0 and 1 or 0
    end

    -- The way back to the title, in the corner the pause button has during a run.
    -- The target is taken from src/hud.lua whole rather than measured again here,
    -- so what a press claims and what a stroke is kept off are the same rectangle.
    lay.backX, lay.backY, lay.backW, lay.backH = Hud.cornerTarget(game)

    -- And the parts of the book that are not lessons, in the opposite corner of
    -- the same margin: lesson tabs mirrored, running TAB_OVER off the safe *left*
    -- edge so what goes past it is the corner of a rectangle and never anything
    -- written.
    --
    -- Each is cut to exactly a lesson tab -- `lay.tabW` across and `lay.tabH`
    -- down, whatever the page made those -- and that is the one thing about them
    -- worth being firm on. A tab is a piece of card in the edge of a book, and the
    -- whole of what says these belong to the same book is that they are the same
    -- piece of card. Sized to their own words they read as labels stuck on the
    -- corner; sized to the corner button above them, as more buttons that happened
    -- to have words in them. Neither is what they are.
    --
    -- They are stacked bottom-up off the foot of the sheet, all at the same edge
    -- and TAB_GAP apart -- the lesson tabs' own column, mirrored and read from the
    -- bottom. `sideRight` and `sideTop` are the corner of the page the whole
    -- margin claims, courses included, which is what `GO!` and the character have
    -- to stay clear of.
    --
    local sideX = ins.l - TAB_OVER
    local sideW, sideH = TAB_OVER + lay.tabW, lay.tabH
    local sideBottom = game.vh - ins.b - EDGE - sideH

    for i, side in ipairs(self.sides) do
        side.x = sideX
        side.y = sideBottom - (i - 1) * (sideH + TAB_GAP)
        side.w, side.h = sideW, sideH
    end

    lay.sideRight = sideX + sideW
    lay.sideTop = self.sides[#self.sides].y

    -- The panel, and the title is the one thing in it that gets smaller rather
    -- than being dropped: it is the question, so it cannot go, and it is the only
    -- thing here with a size to spend.
    lay.textX = left
    lay.textW = lay.tabX - TAB_POP - GUTTER - left

    -- The middle of the screen, and everything centred on this sheet is centred
    -- on it rather than on what the tabs left over: a tab is card in the edge of
    -- the book, so the column of them is margin and the page it leaves is still
    -- the whole page. `textX`/`textW` are what a centred block has to *clear*, not
    -- what it is centred in.
    lay.pageCx = ins.l + math.floor(availW / 2)
    lay.headScale = Font.width(headText()) * HEAD_SCALE <= lay.textW and HEAD_SCALE or 1
    lay.nameScale = nameWidth() * NAME_SCALE <= lay.textW and NAME_SCALE or 1

    -- What the corner button occupies, for the panel to keep its heading clear of
    -- where the two would meet.
    lay.buttonRight = Hud.cornerBox(game) + Hud.CORNER_SIZE
    lay.underButton = Hud.cornerBottom(game) + EDGE

    -- The tabs are hung off the full height of the sheet -- they are down the
    -- other edge, so neither thing in the left margin is anything to them -- and
    -- only the panel is fitted between them.
    self:panel(lay, ins.t + EDGE, game.vh - ins.b - EDGE)

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

-- A lesson is picked, not entered. Exactly one tab is ever out, so choosing
-- another puts the old one back -- which is what makes the selection a thing you
-- can see at a glance rather than a thing you have to remember, and what lets you
-- change your mind as many times as you like before `GO!`.
--
-- The page under the whole screen turns with it, which is the short transition
-- rather than the long one: the book is still open at this screen, it is just
-- open at a different page of it.
function Timetable:select(tab)
    if tab.key == self.current then return end

    Sfx.play("transition")
    self.current = tab.key
end

-- One rung up or down the ladder, and it is stepped rather than picked, which is
-- the one way a course is unlike a lesson: seven lessons are seven places the book
-- opens and four courses are a *scale*, so what says which one you are on is the
-- word rather than which of four things is sticking out. `Course.step` stops at
-- both ends rather than wrapping, for the same reason -- a selector that fell off
-- the top of a scale back to the bottom would be arguing with what it is drawn as.
--
-- Silent where it cannot move, since nothing happened. The arrow at that end has
-- already said so by not being slate (`Timetable:courseStep`).
function Timetable:stepCourse(dir)
    local was = Course.current
    if Course.step(dir) ~= was then Sfx.play("transition") end
end

-- `what` is "go" or "custom", and it is what `update` hands back once the box has
-- finished flashing: the run, or the drawing board and then this screen again.
function Timetable:commit(what)
    self.phase = "confirm"
    Sfx.play("accept")
    self.answer = what
    self.chosen = what == "go" and self.go.boxes[1] or self.custom.boxes[1]
    self.confirmT = 0
end

-- Whether a point is on the corner button, target and all.
function Timetable:backAt(x, y)
    local lay = self.lay
    return lay and x >= lay.backX and x <= lay.backX + lay.backW
        and y >= lay.backY and y <= lay.backY + lay.backH
end

-- And which of the tabs in the other margin, if any, it is on. Padded here
-- rather than in src/hud.lua because these tabs are the timetable's own and
-- nothing else has them, and by more on a phone for the reason every small target
-- in the game is: a finger is blinder than a pointer.
--
-- The cards are a gap apart and none of them overlaps another, so the order they
-- are walked in decides nothing; the padding is the only thing that can put a
-- point on two of them at once, and there the card nearer the foot of the page
-- wins, being the one nearer the thumb that reached for it.
function Timetable:sideAt(x, y)
    if not self.sides or not self.sides[1].x then return nil end

    local pad = Input.usingTouch and 5 or 2
    for _, side in ipairs(self.sides) do
        if x >= side.x - pad and x <= side.x + side.w + pad
            and y >= side.y - pad and y <= side.y + side.h + pad then
            return side
        end
    end
    return nil
end

-- One end of the selector, as a box: a square the size of the corner button's,
-- centred on a glyph three pixels wide. What is being pressed is a corner of the
-- page rather than the chevron drawn in it, which is the same argument the
-- library's own footer arrows are boxes on.
function Timetable:arrowBox(dir)
    local lay = self.lay
    if not lay or not lay.courseX then return nil end
    -- Centred on the glyph both ways: the row it is drawn on is one line of
    -- lettering deep and the target is the corner button's box, so it hangs three
    -- pixels above and below the row it belongs to. Which costs nothing -- what is
    -- above it is a gap in a stat block and what is below it is a gap to the
    -- drawing, and neither is a thing a press can land on.
    local mid = lay.courseY + math.floor(Font.height / 2)
    local gx = dir < 0 and lay.courseX + math.floor(CHEVRON / 2)
        or lay.courseX + lay.courseW - math.ceil(CHEVRON / 2)
    local half = math.floor(COURSE_H / 2)
    return gx - half, mid - half
end

-- Which way a point steps the selector, or nil for neither end of it. Padded like
-- everything else in this margin and by the same amounts, because it is the same
-- finger reaching for the same corner.
--
-- The word between the two is deliberately *not* pressable. Everywhere else on
-- this screen the whole row of a thing is its target -- a box's label presses its
-- box, a tab's word presses its tab -- because in both of those the label says
-- what the one thing does. Here it says which of four the setting is on, and a
-- press on it could only mean one of the two arrows: whichever it picked would be
-- wrong half the time.
function Timetable:courseAt(x, y)
    -- Nothing there on a page the book does not open at yet: the five rows the
    -- selector is the sixth of have been replaced by why it will not open
    -- (`Timetable:drawShut`), and the whole block is that message instead. So the
    -- row is not drawn and cannot be pressed -- a control you cannot see is not one
    -- that should answer a press landing on where it would have been.
    if not self:openHere() then return nil end

    local pad = Input.usingTouch and 4 or 1
    for _, dir in ipairs({ -1, 1 }) do
        local ax, ay = self:arrowBox(dir)
        if ax and x >= ax - pad and x <= ax + COURSE_H + pad
            and y >= ay - pad and y <= ay + COURSE_H + pad then
            return dir
        end
    end
    return nil
end

-- Ink that lands on either arrow is swallowed rather than drawn, which is what
-- every pressable thing on this screen does with a stamp: a press there was a
-- press and not the start of a line. The *word* between them is not swallowed and
-- should not be -- the selector is a row of the sheet now rather than furniture
-- lying on it, so the lettering is written on the page like the five rows above it
-- and a stroke drawn across it is a stroke drawn across the page.
function Timetable:courseRow(x, y)
    return self:courseAt(x, y) ~= nil
end

function Timetable:tabAt(x, y)
    for _, tab in ipairs(self.tabs) do
        if tab.x and x >= tab.x and x < tab.x + tab.w
            and y >= tab.y and y < tab.y + tab.h then
            return tab
        end
    end
end

-- Ink that lands in a box is an answer and is counted there; ink that misses is
-- just ink on the page, and fades off it. Which box took the last stamp is worth
-- remembering, because the two of them are stacked a few pixels apart: a stroke
-- that crossed both answers the one it ended in.
--
-- A tab swallows whatever crosses it rather than being drawn on, and so do the
-- two things in the left margin. The fill would hide it anyway, and a press on
-- any of them was taken as a press rather than as the start of a line.
-- Answers whether the stamp became ink, which is what the pen's swish is fired
-- off (src/scribble.lua): a box takes it as an answer and the page takes it as a
-- line, but a tab or a margin button swallows it, and what a tab swallowed was
-- never drawn.
function Timetable:mark(x, y)
    if self.custom:mark(x, y) then self.lastAct = "custom" return true end
    -- Where the lesson is shut there is no box at that end of the page, so ink
    -- that lands where one would be is ink on the page: a box you can fill and
    -- cannot answer is worse than no box at all.
    if self:openHere() and self.go:mark(x, y) then self.lastAct = "go" return true end
    if self:tabAt(x, y) or self:backAt(x, y) or self:sideAt(x, y)
        or self:courseRow(x, y) then
        return false
    end
    self.marks:add(x, y)
    return true
end

-- The whole row of a box is pressable, the word included: the label is what says
-- what the box does, so pressing the label is pressing the box.
local function inRow(box, fromX, x, y)
    return box.x and x >= fromX and x < box.x + box.w
        and y >= box.y and y < box.y + box.h
end

-- The press edge. The two margin buttons and a tab all act there and then --
-- there is nothing to arm and nothing to lift, because none of them decides
-- anything -- and a box gets the scribble drawn into it, the way tapping a card
-- does on the draft.
--
-- The margin gets first refusal, ahead of the tabs and the boxes both: neither of
-- those two is part of the question being asked, so nothing else may claim a
-- press that landed on one.
function Timetable:press(x, y)
    if self:backAt(x, y) then
        self.pressed = "back"
        return
    end

    local side = self:sideAt(x, y)
    if side then
        self.pressed = side.answer
        return
    end

    -- Ahead of the tabs and the boxes for the doors' reason -- the margin is not
    -- part of the question being asked, so nothing else may claim a press that
    -- landed in it -- and it acts on the press for a tab's reason: nothing is
    -- decided, so there is nothing to arm and nothing to lift.
    local dir = self:courseAt(x, y)
    if dir then
        self:stepCourse(dir)
        return
    end

    local tab = self:tabAt(x, y)
    if tab then
        self:select(tab)
        return
    end

    -- Each row from its own word rather than from one shared edge: the two boxes
    -- are in two places on the page now, so there is no shared edge to start at.
    if inRow(self.custom.boxes[1], self.lay.customX, x, y) then
        self.custom:autoFill(self.custom.boxes[1])
    elseif self:openHere() and inRow(self.go.boxes[1], self.lay.goX, x, y) then
        self.go:autoFill(self.go.boxes[1])
    end
end

-- Returns what was answered ("go" or "custom") and the lesson it was answered
-- about, on the frame the box has finished flashing, and nothing at all until
-- then -- or "back" and the `answer` of whichever margin tab it was the moment one
-- is pressed. A box is answered and gets the beat of flashing every answer in this
-- game gets; a tab is pressed, and a press that took a beat to happen would be a
-- press you were not sure you had made.
--
-- The lesson goes back with all of them, and what is done with it is `Game`'s to
-- decide: `GO!`, `CUSTOM` and every tab in the left margin are things done *to*
-- the lesson you are on, and only `back` leaves without settling which one that
-- was.
function Timetable:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.pressed then return self.pressed, self.current end

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return self.answer, self.current end
        return
    end

    -- The keyboard and a tap both draw the scribble rather than jumping past it,
    -- and there is no pen to lift, so what they fill stands as soon as it is
    -- full.
    if self.custom:update(dt) then
        self:commit("custom")
        return
    end

    if self:openHere() and self.go:update(dt) then
        self:commit("go")
        return
    end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    -- Taken on the press that made it rather than a frame later, so a margin
    -- button goes when the finger lands on it.
    if self.pressed then return self.pressed, self.current end

    -- Armed, not answered: neither box is taken until the pen comes off the page,
    -- so a line that runs out of one again has changed its mind. Where a stroke
    -- armed both, the one it was in last is the one it meant.
    if not down then
        local go = self:openHere() and self.go.armed
        if self.lastAct == "custom" then
            if self.custom.armed then self:commit("custom")
            elseif go then self:commit("go") end
        else
            if go then self:commit("go")
            elseif self.custom.armed then self:commit("custom") end
        end
    end
end

function Timetable:keypressed(key)
    if self.phase ~= "asking" then return end

    local slot = tonumber(key)
    if slot and self.tabs[slot] then
        self:select(self.tabs[slot])
    elseif key == "backspace" then
        -- The keyboard route to the corner button. It presses rather than draws,
        -- unlike the keys that answer the boxes, because the button it presses
        -- is not a box: there is nothing there to scribble in.
        self.pressed = "back"
    elseif key == "return" or key == "space" then
        if self:openHere() then self.go:autoFill(self.go.boxes[1]) end
    elseif key == "c" then
        self.custom:autoFill(self.custom.boxes[1])
    elseif key == "left" or key == "a" then
        -- Left and right because the thing they step is drawn left to right, which
        -- is the library's own pair for its own footer and the same gesture about
        -- the same shape of control. The number keys are the term's, and a course
        -- is not a numbered slot the way a lesson tab is.
        self:stepCourse(-1)
    elseif key == "right" or key == "d" then
        self:stepCourse(1)
    else
        -- And the tabs in the other margin, pressed rather than drawn for the
        -- corner button's reason: there is nothing on one of them to scribble in.
        for _, side in ipairs(self.sides) do
            if key == side.key then self.pressed = side.answer end
        end
    end
end

--- draw ----------------------------------------------------------------------

-- The character, standing on the page he will actually be standing on, with the
-- scrap of ground under him and the one-pixel walk bounce -- the drawing board's
-- preview, blown up.
--
-- Blown up by pushing a whole-number scale rather than by drawing anything
-- differently, which is the same trick `Scribble.printBig` plays on the 3x5 face
-- and main.lua plays on the whole canvas: the drawing is used exactly as drawn,
-- every coordinate inside the transform is still a whole number, and what lands
-- on the screen is a grid of whole squares on the pixel grid. So the
-- bounce is one *drawing* pixel, and the ground under him is measured off the
-- sprite by `Sprites.shadow` the way it is everywhere else.
--
-- Which is also why the layout hands this the hero's top-left corner and keeps
-- everything else in the drawing's own pixels: past the translate there is only
-- one coordinate system and it is the sprite's.
function Timetable:drawHero(lay)
    local sprite = Sprites.player
    local bounce = math.floor(self.t * 7) % 2

    love.graphics.push()
    love.graphics.translate(lay.heroX, lay.heroY)
    love.graphics.scale(lay.heroScale, lay.heroScale)

    Sprites.shadow(sprite, sprite.ox, lay.heroDrawY)

    -- The page blanked out under him first, the run's own trick (Game:draw): he
    -- is standing on the sheet rather than printed into it, and at this size a
    -- rule coming through him crosses the drawing four times. Stamped from inside
    -- the scale, which is the whole reason Overprint hands the page layer back
    -- where it is standing instead of collecting a pass somewhere else -- past the
    -- translate there is only one coordinate system and nothing outside this
    -- function knows it.
    --
    -- What he is holding is not in it, for the same reason the shadow is not: a
    -- tool is drawn on the page everywhere else in the game and goes on darkening
    -- over a rule the way every other mark does.
    Overprint.beginSolid()
    love.graphics.setColor(Palette.paper)
    sprite:drawMask(sprite.ox, lay.heroDrawY - bounce, false)
    Overprint.endSolid()

    love.graphics.setColor(1, 1, 1)
    sprite:draw(sprite.ox, lay.heroDrawY - bounce, false)

    -- What he is carrying, on the same bounce: it is in his hand, so it walks when
    -- he does. No ground under it and no rim round it -- he is the thing standing
    -- on the page and this is the thing he is holding.
    --
    -- Drawn as it is drawn, which for the sword means point-up (src/sword.lua
    -- turns it at the swing, and there is no swing here to turn it to).
    if lay.armX then
        local design = Design.by[Characters.current.design]
        if design then
            Sprites[design.sprite]:draw(lay.armX, lay.armY - bounce, false)
        end
    end

    love.graphics.pop()
end

-- What the lesson is, what it hands you and what you have got out of it. The
-- labels are slate and the numbers ink: the numbers are the part you are reading
-- and the labels are there to say what they are.
--
-- The heading and the lesson are the same size and one under the other, in the
-- two colours the screen has to spend: the heading is red because it is the only
-- thing here that never changes, and the lesson is ink because it is the thing
-- the tabs are turning over.
function Timetable:drawPanel(lay)
    local sub = Subjects.get(self.current)

    Scribble.printBig(headText(), lay.cx, lay.head, lay.headScale, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    if lay.heroX then self:drawHero(lay) end

    -- Set with a shadow only where there is room for one: at 1x a letter is three
    -- pixels across and an offset copy is a smudge over half of it, which is the
    -- same rule the small box's label is drawn by.
    local nameOpts = { seed = 5 }
    if lay.nameScale > 1 then
        nameOpts.shadow, nameOpts.wobble, nameOpts.t = Palette.graphite, true, self.t
    end
    local open = self:openHere()

    -- A lesson the book does not open at yet is written in graphite, which is what
    -- everything faded in this game is written in and what the library writes a
    -- line it has not opened in (src/library.lua) -- the same fact about the same
    -- book, said the same way. No shadow on it either, for the library's reason:
    -- the shadow *is* graphite, so a graphite name with one is a name drawn twice
    -- in one colour a pixel apart, which is a smudge rather than a faded word.
    if not open then nameOpts.shadow = nil end

    Scribble.printBig(I18n.t(sub.name), lay.cx, lay.name, lay.nameScale,
        open and Palette.ink or Palette.graphite, nameOpts)

    if not open then
        self:drawShut(lay)
        return
    end

    local y = lay.stats
    for _, row in ipairs(statRows(self.current)) do
        love.graphics.setColor(Palette.slate)
        Font.print(row[1], lay.statX, y)
        -- Ink unless the row asks for something else, and one row does: the mark
        -- is red wherever it is printed.
        love.graphics.setColor(row[3] or Palette.ink)
        Font.printRight(row[2], lay.statX + lay.statW, y)
        y = y + Font.height + LINE_GAP
    end

    -- And the sixth row, which is the one you can answer.
    self:drawCourse(lay)
end

-- What stands where the record would be on a page the book does not open at yet:
-- why there is nothing to read, in graphite, and what to go and do about it, in
-- red. It is the library's hole, in the library's two colours, in the same two
-- phrases from the same file (`Collection.lessonWhy`) -- a page you cannot open
-- and a tool you cannot carry are the same fact and the book says them alike.
--
-- The five stat rows are what it replaces rather than what it is drawn between:
-- every value on them is a record, a shut page has none, and `--` five times over
-- is a page that has been played badly rather than a page that has not been
-- opened. The block they left is deeper than these two lines need, and that is the
-- room the wrapping has on a narrow page.
--
-- Wrapped to the widest a *centred* block can be on this line rather than to the
-- panel's own width: `lay.cx` walks left off the middle of the page where the tabs
-- would otherwise be under it, and a line centred on it and measured off the full
-- width would go back under them.
function Timetable:drawShut(lay)
    local head, ask = Collection.lessonWhy(self.current)
    local width = 2 * math.min(lay.cx - lay.textX,
                               lay.textX + lay.textW - lay.cx)
    local y = lay.stats

    for i, part in ipairs({
        { text = I18n.say(head), color = Palette.graphite },
        { text = I18n.say(ask), color = Palette.red },
    }) do
        if part.text then
            love.graphics.setColor(part.color)
            for _, line in ipairs(Font.wrap(part.text, width)) do
                Font.printCentered(line, lay.cx, y)
                y = y + Font.height + LINE_GAP
            end
            -- A blank line between the two, so the demand reads as an answer to
            -- the line above it rather than as the rest of the sentence -- the
            -- library's own gap, in the library's own units.
            if i == 1 then y = y + LINE_GAP end
        end
    end
end

-- One tab: the edge of a page, with the lesson on it and the icon of the tool it
-- hands you at the outside end.
--
-- **Every tab is filled in paper**, the picked one included. Paper is the one
-- colour that covers what is under it rather than stacking with it
-- (src/palette.lua), so a tab is a piece of card lying on the sheet and not a
-- window onto it. The picked one used to be left unfilled, on the argument that
-- the page running through it says "this tab belongs to this sheet"; what it
-- actually said, on the pages with something to say -- squared, the ledger's
-- header bands, the staves -- was that a hole had been cut in the tab, with the
-- ruling crossing the lesson written on it. A tab is card. Card is opaque.
--
-- Which leaves the pop and the colour to say which one is open, and between them
-- that is plenty: it is the only tab sticking out into the page and the only one
-- in red.
--
-- Colour comes off `Scribble.boxColor` like every other picked, hot or
-- stepped-aside thing in the game, which is why a tab carries a `fill` of 1 or 0:
-- the picked one is red, the rest are slate, and once `GO!` has been answered
-- `flash` takes them all over so the picked one flashes and the rest go graphite.
--
-- Both the fill and the border run `TAB_OVER` past the safe edge so the outside
-- end of a tab is off the sheet rather than squared off against it. Nothing
-- written on a tab goes out there: the icon is placed from the safe edge in.
function Timetable:drawTab(i, tab, flash)
    local sub = Subjects.list[i]
    local drawn = util.clamp((self.t - (i - 1) * TAB_STAGGER) / TAB_TIME, 0, 1)
    if drawn <= 0 then return end

    -- A tab the book does not open at yet is graphite, picked or not, and that is
    -- the one thing about a tab red does not get to say. Red on this column means
    -- *this is where the book is open*; on a shut page it would be the tab lying
    -- about the only thing a tab is for. So the pop says which one you are looking
    -- at and the colour says whether it will open -- two things, said by the two
    -- halves of what a picked tab already was.
    local color = tab.open and Scribble.boxColor(tab, flash, self.confirmT)
        or Palette.graphite
    local w = tab.w + TAB_OVER

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", tab.x, tab.y, w, tab.h)

    Scribble.drawBox({ x = tab.x, y = tab.y, w = w, h = tab.h },
        drawn, color, 20 + i * 3, 0)

    -- Everything on a tab is centred on its midline rather than sat on its top
    -- edge, since the tab's height is whatever the screen could spare and the
    -- lettering's is not.
    local midY = tab.y + math.floor(tab.h / 2)

    local name = I18n.t(sub.name)
    Scribble.printBig(name, tab.x + PAD + Font.width(name) / 2,
        midY - math.floor(Font.height / 2), 1, color,
        -- Counted off the *drawn* name in letters, not off the row's own string
        -- in bytes. Two things went wrong that way: a lesson whose translation is
        -- longer than the English stayed permanently cut short once the tab had
        -- finished writing itself on, and a letter made of two bytes counted as
        -- two (src/font.lua).
        { seed = 40 + i, count = math.ceil(Font.count(name) * drawn) })

    -- The tool, and on a shut page its own silhouette in graphite -- the library's
    -- locked icon, drawn by the same call, since what a lesson is holding out to
    -- you is a thing you can see the shape of and not yet take. Through
    -- `Hud.drawIcon` rather than off the sprite table for that: it is the one place
    -- in the game that knows how to draw an icon as a hole.
    if drawn >= 1 then
        Hud.drawIcon(Upgrades.byId[sub.tool].icon,
            self.lay.tabRight - PAD - ICON / 2, midY,
            not tab.open and Palette.graphite or nil)
    end
end

-- One of the two things you can do with the lesson you have picked: the word,
-- right against its box, and the box itself. The word hangs off its own box
-- rather than off a shared edge, since the two of them are no longer a pair --
-- the two of them share the foot of the page, or stack there, and neither is
-- captioning anything above it.
--
-- The answered one flashes and the other steps aside, which is `Scribble.boxColor`
-- doing what it does on every screen that offers more than one answer -- even
-- though these two are separate choices, because what is passed as `chosen` is
-- the box that was actually answered.
function Timetable:drawAct(box, label, scale, y, progress, seed)
    local color = Scribble.boxColor(box, self.chosen, self.confirmT)
    local w = Font.width(label) * scale

    -- Only the big label gets the shadow and the wobble. At 1x a letter is three
    -- pixels across and a shadow offset one pixel is a smudge over half of it,
    -- and a word that re-wanders every seventh of a second at that size is a word
    -- you have to read twice -- so the quiet answer is drawn quietly, which is
    -- also the difference between the two of them said in ink.
    local opts = { seed = seed }
    if scale > 1 then
        opts.shadow, opts.wobble, opts.t = Palette.blush, true, self.t
    end

    Scribble.printBig(label, box.x - Scribble.LABEL_GAP - w / 2,
        y + math.floor((Scribble.BOX_H - Font.height * scale) / 2),
        scale, color, opts)

    Scribble.drawBox(box, progress, color, seed, 0)
    Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
end

-- One of the tabs in the other margin: a lesson tab mirrored, off the left edge
-- of the sheet, in the corner opposite the back button.
--
-- Everything the lesson tabs are is true of these and for the same reasons --
-- filled in `Palette.paper` because a tab is card and card is opaque, drawn out
-- past the overprint pass so the border and the lettering are the flat colour they
-- say they are, and running `TAB_OVER` off the safe edge so a tab reads as coming
-- out of the book rather than as being squared off against the screen.
--
-- Two things about them are their own. They are always slate, never red: red on a
-- tab means *this is where the book is open*, and the book is never open at one of
-- these -- they are tabs you press to go somewhere else, not ones that say where
-- you are. And they carry no icon, because a lesson tab's icon is the tool that
-- lesson hands you and none of these hands you anything.
--
-- They write themselves on bottom-up on the lesson tabs' own stagger, so the
-- column arrives as a column rather than as three cards appearing at once.
function Timetable:drawSide(i, side)
    local drawn = util.clamp((self.t - (i - 1) * TAB_STAGGER) / TAB_TIME, 0, 1)
    if drawn <= 0 then return end

    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", side.x, side.y, side.w, side.h)

    Scribble.drawBox({ x = side.x, y = side.y, w = side.w, h = side.h },
        drawn, Palette.slate, 17 + i * 3, 0)

    -- Centred on the card both ways, which is the one place these tabs do not copy
    -- a lesson tab: a lesson has two things to place and puts one at each end, and
    -- these have a word and nothing else, so the word goes in the middle of the
    -- card rather than flush to an edge with nothing opposite it.
    local label = I18n.t(side.label)
    Scribble.printBig(label, side.x + side.w / 2,
        side.y + math.floor((side.h - Font.height) / 2), 1, Palette.slate,
        { seed = 47 + i, count = math.ceil(Font.count(label) * drawn) })
end

-- The sixth row of the block: `<` the class you are sitting it as `>`, in the
-- column the figures are in and right-aligned like all of them.
--
-- **The two chevrons are drawn bare rather than in boxes**, unlike the library's
-- footer arrows. The glyph is three columns wide, so the whole control is
-- fifty-seven pixels and fits inside the value column the clock row had already
-- reserved -- two 11px boxes and their clearances would have been forty-four
-- pixels before the word and would have made the block wider than the heading
-- above it. What is *pressed* is still a square the size of the corner button's
-- (`Timetable:arrowBox`): the target is a corner of the sheet, the drawing is a
-- glyph, and they are allowed to be different sizes.
--
-- **The colours are three things said in one row.** The word is ink, because in
-- this block ink is what a value is written in and slate is what a label is -- the
-- five rows above it say so, and the course is the value of the row it is on. An
-- arrow with a rung behind it is slate, the colour of everything on this screen
-- you can press. An arrow at the end of the ladder is graphite, the colour of
-- everything out of reach in this book. And an arrow with ladder behind it that
-- has not been paid for is **red** -- which is the one that earns the row: a
-- stepper cannot show you the rungs you have not bought the way a column of cards
-- could, so the arrow has to say there is more, and red is how the rest of this
-- book says go and do something about it (`Collection.lessonWhy`, the library's
-- own hole). A book that has bought nothing shows a graphite `<` and a red `>`,
-- which is the whole of what tells you the ladder exists.
--
-- Written *on* the page rather than laid on it -- inside the overprint pass with
-- the rest of the block -- because that is what it now is: a row of the sheet, so
-- the ruling shows through it exactly as it shows through the five rows above.
function Timetable:drawCourse(lay)
    love.graphics.setColor(Palette.slate)
    Font.print(I18n.t(COURSE), lay.statX, lay.courseY)

    local label = I18n.t(Course.current.name)
    Scribble.printBig(label, lay.courseX + math.floor(lay.courseW / 2),
        lay.courseY, 1, Palette.ink, { seed = 61 })

    -- Drawn as a *mask* rather than as the sprite, which is the one thing about
    -- these two glyphs worth knowing: the art is palette-locked, so the chevron in
    -- `Sprites.icons` is ink and only ink, and there is no colour to set on it.
    -- `Hud.drawIcon` has the same problem and answers it the same way -- the
    -- silhouette stamped in whatever colour is set, which for a glyph that is all
    -- one colour anyway is the glyph.
    local half = math.floor(COURSE_H / 2)
    for _, dir in ipairs({ -1, 1 }) do
        local state = self:courseStep(dir)
        love.graphics.setColor(state == "open" and Palette.slate
            or state == "unpaid" and Palette.red or Palette.graphite)
        -- The same glyph both ways round -- three columns wide, so its origin is
        -- the middle one and the flip is an exact mirror rather than a resample.
        local ax, ay = self:arrowBox(dir)
        Sprites.icons.chevron:drawMask(ax + half, ay + half, dir > 0)
    end
end

function Timetable:draw(game)
    local lay = self:layout(game)

    -- Everything the lesson is written *with* goes on the page rather than over
    -- it, so the ruling shows through the question the same way it shows through
    -- a pencil line drawn mid-run -- and the ruling it shows through is the one
    -- you are about to play on.
    Overprint.beginPage()
    Background.drawAs(self.current, 0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    self:drawPanel(lay)

    local progress = util.clamp(self.t / (TAB_TIME * 2), 0, 1)
    self:drawAct(self.custom.boxes[1], customText(), CUSTOM_SCALE, lay.customY,
        progress, 12)
    -- And `GO!` only where there is somewhere to go. The room it had is left
    -- empty rather than closed up: every other part of this sheet is measured at
    -- its widest and tallest so that nothing moves as you step the tabs, and a
    -- column that walked down the page whenever you turned to a shut lesson would
    -- be the one thing here that does. An empty foot of page is what a shut page
    -- looks like.
    if self:openHere() then
        self:drawAct(self.go.boxes[1], goText(), GO_SCALE, lay.goY, progress, 11)
    end

    Overprint.finish()

    -- The tabs are drawn *after* the pass, which is what makes them card rather
    -- than writing. Filling one in paper clears the ruling under it, but the pass
    -- pairs every inked pixel with the page beneath it whatever else was drawn in
    -- between -- so a border or a letter that happened to land on a rule still
    -- came out a step darker, and a tab read as a transparency laid on the page
    -- with the lines showing through its lettering. Out here nothing is paired
    -- with anything: a tab is the flat colour it says it is, the way the draft's
    -- cards and the pause card are.
    --
    -- The lesson that is about to be played flashes as the page turns while the
    -- rest of the tabs step out of it, exactly as one answer among several does
    -- anywhere else -- so the tabs say which lesson `GO!` took even though `GO!`
    -- is the box that was answered. Only for `GO!`: `CUSTOM` is not leaving this
    -- lesson, it is going to draw on it and coming back, so the tabs have no news.
    local flash = self.answer == "go" and self:selectedTab() or nil
    for i, tab in ipairs(self.tabs) do
        self:drawTab(i, tab, flash)
    end

    -- And everything in the left margin, out here with the tabs for the same
    -- reason: a box or a card in the margin is a thing lying on the page rather
    -- than a mark made on it.
    --
    -- The back button is never hot -- the pause button goes red to say the run
    -- behind it is frozen, and there is nothing frozen behind this one.
    Hud.drawCorner(game, "back", false)
    for i, side in ipairs(self.sides) do
        self:drawSide(i, side)
    end


end

return Timetable
