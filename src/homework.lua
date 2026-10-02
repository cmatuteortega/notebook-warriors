-- The homework page: what the book is asking you to go and do, as a checklist.
--
-- It used to be the collection's seventeen quests with a meter against each --
-- the library's own list of holes, read out a second time so that one number
-- could be printed beside it. That number now hangs under the demand on the
-- shelf where the demand is (src/library.lua) and this page is the thing the book
-- did not have: a list of what you have *done* rather than of what you have
-- opened. See src/challenges.lua for why those are two different questions and
-- why a register of maxima can only ever ask the first.
--
-- Nothing is answered here, so nothing is scribbled: the boxes are drawn, and
-- stray ink fades. Done is ink, undone graphite, and a standing demand is red --
-- which is the library's own pair of colours for its own pair of states, because
-- it is the same fact twice.
--
-- **A row is a name, its pips, a demand and a figure.** The pips are the one
-- thing on this page that is not on any other: a challenge usually has three
-- rungs, so it has three boxes, and each fills red as its rung falls. One row
-- however long the ladder, because three rows saying BLOB with different numbers
-- on them is a list you cannot run your eye down.
--
-- **And four sections, one to a spread** (src/spread.lua), for the reason the
-- canteen grew the same footer: this list is going to keep growing and a page is
-- a page. Ten rows a section is comfortable on the shortest window this game is
-- ever handed; forty in a column would not be. Where the window is wide enough
-- to hold two leaves the ten are split down the crease, five and five, and a
-- finger drag turns to the next section the way it turns a page; where it is not
-- -- a phone held upright -- the spread collapses to one leaf and the ten go
-- back in a column, with the same drag lifting the whole page away.
--
-- Split down the middle rather than filled to the foot of the verso and spilled,
-- because five and five reads as a spread and nine and one reads as a page that
-- ran out.
--
-- Everything is measured across *every* section rather than across the one
-- showing, so no column moves as the page is turned -- the library's rule, and it
-- matters here for the library's reason: this is a screen you read by running
-- your eye down it.
--
-- **What does not turn is not on the page.** The heading, the count in the corner
-- and the footer are drawn out past the overprint pass with the arrows and the
-- corner button, and the rows are drawn inside it. That split was cosmetic while
-- a section changed in one frame; with a leaf moving across the page it is what
-- decides what moves with it, and the answer is the list -- the title of the
-- screen, how much of it there is and the way through it are the book rather than
-- the leaf.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local Sprites = require("src.sprites")
local Challenges = require("src.challenges")
local Spread = require("src.spread")
local I18n = require("src.i18n")

local Homework = {}
Homework.__index = Homework

local HEAD = "HOMEWORK"
local HEAD_SCALE = 2

local EDGE = 4             -- off the edge of the page
local HEAD_TOP = 10        -- ... and the heading off the top of it, the library's
                           -- own clearance
local HEAD_GAP = 6         -- the heading to the first row

local BOX = 5              -- one pip, cut to the height of the lettering beside
                           -- it, so a row is one line tall
local PIP_GAP = 1          -- one pip to the next: a hair, so a ladder reads as one
                           -- thing rather than as three boxes that happen to be
                           -- near each other
local BOX_GAP = 3          -- the pips to the name
local COL_GAP = 6          -- one column of the row to the next
local ROW_GAP = 5          -- one row to the next, and it has to beat LINE_GAP by
                           -- enough to read as a bigger gap: a row is up to three
                           -- lines now, so the space between two rows is the only
                           -- thing saying where one of them stops
local LINE_GAP = 2         -- ... and one line of a row to the next

local ARROW = 11           -- the library's footer arrow, which is the corner
                           -- button's box
local ARROW_GAP = 6        -- ... and its clearance off the section name between
                           -- them
local FOOT_GAP = 6         -- the lowest row the page can show down to the arrows

local LINE = Font.height + LINE_GAP

--- what is on the list -------------------------------------------------------

-- The catalogue never changes, so it is read once and held. How far along a row is
-- is deliberately not held here -- that is src/challenges.lua's own question and
-- its own cache, keyed to registers that can change between frames.
local function sections()
    return Challenges.sections()
end

function Homework.new()
    return setmetatable({ book = Spread.new() }, Homework)
end

function Homework:enter()
    self.t = 0
    self.back = false

    -- The one thing neither register stamps: a hero bought at the counter opens
    -- the weapon he carries, and the walk from the canteen to here is the only
    -- moment that can have happened without a run in between.
    Challenges.refresh()

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer already down from the tab that opened this page presses and draws
    -- nothing until it is lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()
    self.book:rest()

    -- Nothing to walk, and the stick's corner must be scribbleable like the rest.
    Input.stickEnabled = false
end

function Homework:rows()
    return sections()[self.book.at].rows
end

-- How many of a section's rows go on the verso. Half of them, rounded up, so the
-- longer column is the one you read first; all of them on a page with only one
-- leaf on it, which is the whole of what this screen has to know about the
-- collapse.
function Homework:half(rows)
    if not self.book:spread() then return #rows end
    return math.ceil(#rows / 2)
end

--- layout --------------------------------------------------------------------

-- Each column is cut to the widest thing that can *ever* land in it, across every
-- section and not just the one showing, so nothing moves as a row is finished or
-- as the footer is pressed -- hence `Challenges.meterRoom` (the last rung of the
-- ladder) rather than the live meter, and every rung's demand rather than the one
-- outstanding. Measured off I18n.say, i.e. the translation, never the English key.
local function columns()
    local name, ask, meter, pips = 0, 0, 0, 1

    for _, section in ipairs(sections()) do
        for _, row in ipairs(section.rows) do
            name = math.max(name, Font.width(I18n.say(row.name)))
            meter = math.max(meter, Font.width(Challenges.meterRoom(row)))
            pips = math.max(pips, #row.want)
            for _, want in ipairs(row.want) do
                ask = math.max(ask, Font.width(I18n.say(row.ask(want)) or ""))
            end
        end
    end

    return name, ask, meter, pips
end

-- Widest the corner count can get: as many rungs as the fullest section has, all
-- of them fallen.
local function tallyWidth()
    local most = 1
    for _, section in ipairs(sections()) do
        local n = 0
        for _, row in ipairs(section.rows) do n = n + #row.want end
        most = math.max(most, n)
    end
    return Font.width(("%d/%d"):format(most, most))
end

-- And the widest section name, so the two footer arrows never move as one is
-- pressed. The canteen's own measurement, on the canteen's own footer.
local function sectionWidth()
    local w = 0
    for _, section in ipairs(sections()) do
        w = math.max(w, Font.width(I18n.t(section.name)))
    end
    return w
end

function Homework:layout(game)
    self.game = game

    local ins = game.inset
    local lay = {}
    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)

    -- The book first: everything below is measured off a *leaf* rather than off
    -- the page, and whether there are two of them is the one thing that decides
    -- how wide a row is allowed to be.
    local book = self.book
    book:fit(game, #sections())
    local leafX, _, leafW = book:leaf(1)
    local availW = leafW - EDGE * 2

    lay.nameW, lay.askW, lay.meterW, lay.pips = columns()
    lay.pipsW = lay.pips * BOX + (lay.pips - 1) * PIP_GAP

    -- **How many lines a row is, is the page's decision and not a constant.** A row
    -- has four things in it -- the ladder, the name, the demand and the figure --
    -- and three ways to arrange them, each narrower than the last:
    --
    --   1  [pips] NAME     KILL 500 OF THEM     0/500
    --   2  [pips] NAME                          0/500
    --          KILL 500 OF THEM
    --   3  [pips] NAME
    --          KILL 500 OF THEM
    --          0/500
    --
    -- The widest that fits wins, and on a spread that is nearly always the third:
    -- a leaf is half the page, the demand alone is ninety pixels of it, and a row
    -- laid flat across one runs to the paper's edge. Which is the trade taken
    -- deliberately -- **a row may have as many lines as it likes and may not eat
    -- the margin**, because a list printed to the edge of the paper reads as a
    -- page that did not fit rather than as a page.
    --
    -- The third is the library's own shape for exactly this trio (`drawLine`): the
    -- demand, and the figure on the line under it with no blank line between them,
    -- because there the two *are* one sentence -- what is owed, and what has been
    -- paid off it.
    local head = lay.pipsW + BOX_GAP + lay.nameW
    local flat = head + COL_GAP + lay.askW + COL_GAP + lay.meterW
    local twoUp = math.max(head + COL_GAP + lay.meterW, lay.pipsW + BOX_GAP + lay.askW)
    local stack = lay.pipsW + BOX_GAP
        + math.max(lay.nameW, lay.askW, lay.meterW)

    lay.lines = flat <= availW and 1 or (twoUp <= availW and 2 or 3)
    lay.blockW = lay.lines == 1 and flat or (lay.lines == 2 and twoUp or stack)
    lay.rowH = Font.height + (lay.lines - 1) * LINE + ROW_GAP

    -- Where the block sits *inside* a leaf, so that one number places it on
    -- either of them and the two columns are mirror images of each other however
    -- the window is shaped.
    lay.blockOff = EDGE + math.floor((availW - lay.blockW) / 2)
    lay.blockX = leafX + lay.blockOff

    -- The count, in the corner button's own box mirrored to the other end of the
    -- same top edge and level with it -- the library's corner, for the library's
    -- reason: how much of the list there is is a fact about the list rather than
    -- part of it. It counts the section showing rather than the whole page, which
    -- is the library's rule as well: the four fill at completely different rates,
    -- and added together they would be one figure that said nothing about any of
    -- them.
    local bx, by = Hud.cornerBox(game)
    lay.tallyRight = game.vw - ins.r - Hud.CORNER_MARGIN
    lay.tally = by + math.floor((Hud.CORNER_SIZE - Font.height) / 2)

    -- The heading shares the top row with both corners where there is room for it
    -- and steps under the pair of them where there is not, which is the library's
    -- guard and has to clear both: the button is in one corner and the count is
    -- lettering in the other.
    local headW = Font.width(I18n.t(HEAD)) * HEAD_SCALE
    local buttonRight = bx + Hud.CORNER_SIZE
    local underBoth = math.max(Hud.cornerBottom(game),
        lay.tally + Font.height) + EDGE

    lay.head = lay.cx - headW / 2 > buttonRight + EDGE
        and lay.cx + headW / 2 < lay.tallyRight - tallyWidth() - EDGE
        and ins.t + HEAD_TOP
        or underBoth

    lay.list = math.max(underBoth,
        lay.head + Font.height * HEAD_SCALE + HEAD_GAP)

    -- The footer off the bottom edge, pinned to it rather than centred with the
    -- list: it is the library's footer doing the library's job -- which section of
    -- the same page am I reading -- so it sits where the library's sits, and the
    -- list stops a clear gap above it.
    lay.arrowY = game.vh - ins.b - EDGE - ARROW
    lay.sectionW = sectionWidth()
    lay.bottom = lay.arrowY - FOOT_GAP

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function Homework:backAt(x, y)
    local bx, by, bw, bh = Hud.cornerTarget(self.game)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

-- One of the two footer arrows, as a box: the canteen's recipe, both struck off
-- the middle of the page with the widest section name between them.
function Homework:arrowBox(dir)
    local lay = self.lay
    local half = (lay.sectionW + (ARROW + ARROW_GAP) * 2) / 2
    local x = dir < 0 and lay.cx - half or lay.cx + half - ARROW
    return math.floor(x), lay.arrowY
end

-- Which arrow, if either, a point lands on. Padded the way every small target in
-- the game is padded, and by more on a phone.
function Homework:arrowAt(x, y)
    if not self.lay then return nil end

    local padX, padY = 4, 2
    if Input.usingTouch then padX, padY = 8, 6 end

    for dir = -1, 1, 2 do
        local ax, ay = self:arrowBox(dir)
        if x >= ax - padX and x <= ax + ARROW + padX
            and y >= ay - padY and y <= ay + ARROW + padY then
            return dir
        end
    end
    return nil
end

-- An arrow, or a key: the same turn a finger makes, run at its own pace. The
-- book owns which section is open, so there is nothing here to move.
function Homework:step(dir)
    self.book:turn(dir)
end

-- Furniture: the corner button and the two footer arrows. It is one question
-- rather than two because both of the things that ask it want the same answer --
-- the pen must not draw here, and the book must not take the page here.
function Homework:furniture(x, y)
    return self:backAt(x, y) or self:arrowAt(x, y) ~= nil
end

-- The corner button and the two footer arrows swallow whatever crosses them
-- rather than being drawn on: a press on one was taken as a press rather than as
-- the start of a line. Answers whether the stamp became ink, which is what the
-- pen's swish is fired off (src/scribble.lua) -- a swallowed stamp was never a
-- line, so it must not sound like one.
--
-- A finger turning a page swallows its stamps for the same reason and answers
-- the same way: it is a hand on the paper rather than a nib on it, and a swish
-- fired for it would be the book saying a line was drawn where a page was turned.
function Homework:mark(x, y)
    if self.book:eating() then return false end
    if self:furniture(x, y) then return false end
    self.marks:add(x, y)
    return true
end

function Homework:press(x, y)
    if self.book:eating() then return end

    if self:backAt(x, y) then
        self.back = true
        return
    end

    local dir = self:arrowAt(x, y)
    if dir then self:step(dir) end
end

-- Returns "back" the moment the corner button is pressed, and nothing at all
-- otherwise. There is nothing on this page to answer, so there is nothing for it
-- to hand over.
function Homework:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.back then return "back" end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    -- The book first, so that the frame a stroke turns into a turn is a frame
    -- the pen lays nothing: `mark` and `press` both ask it whether the finger is
    -- on the page or on a page (src/spread.lua).
    self.book:track(dt, down, Input.pointerX, Input.pointerY,
        self:furniture(Input.pointerX, Input.pointerY))

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    if self.back then return "back" end
end

function Homework:keypressed(key)
    -- Backspace is the corner button, exactly as it is on the timetable, in the
    -- library and at the canteen.
    if key == "backspace" then
        self.back = true
        return
    end

    -- And left and right step the section, the way the arrows they stand for do:
    -- the library's own keys, on the library's own footer.
    if key == "left" or key == "a" then
        self:step(-1)
    elseif key == "right" or key == "d" then
        self:step(1)
    end
end

--- draw ----------------------------------------------------------------------

-- One pip: a slate border filled in paper, and the red square in the middle of it
-- once that rung has fallen. The same two rectangles every box in this game is
-- made of (src/scribble.lua) with the scribble taken out, because there is nothing
-- here to answer -- what it is showing is an answer that has already been given
-- somewhere else, on a page you played.
local function drawPip(x, y, done)
    love.graphics.setColor(Palette.slate)
    love.graphics.rectangle("fill", x, y, BOX, BOX)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, BOX - 2, BOX - 2)

    if done then
        love.graphics.setColor(Palette.red)
        love.graphics.rectangle("fill", x + 1, y + 1, BOX - 2, BOX - 2)
    end
end

-- `bx` is the left edge of the block on the leaf this row is on: the one number
-- that moves a row from the verso to the recto, since every column inside it is
-- struck off that edge and the two leaves are the same width to the pixel.
function Homework:drawRow(lay, row, bx, y)
    local done = Challenges.done(row)
    local met = done >= #row.want

    -- The ladder, left to right, one pip a rung. A row with one rung draws one
    -- pip and needs no special case: what makes a row long is how many numbers are
    -- in `want`. They are left-aligned in the column the widest ladder reserved, so
    -- a short row's pips start where a long row's do and the names stay in a line.
    for i = 1, #row.want do
        drawPip(bx + (i - 1) * (BOX + PIP_GAP), y, i <= done)
    end

    -- What it is about, in the library's own two colours for the same two states:
    -- a thing you have finished is ink and a thing you have not is graphite.
    love.graphics.setColor(met and Palette.ink or Palette.graphite)
    local nameX = bx + lay.pipsW + BOX_GAP
    Font.print(I18n.say(row.name), nameX, y)

    -- And the rung still standing. Red while it stands, because red on every
    -- screen in this book is the book asking you for something; nothing at all
    -- once the ladder is finished, because then there is nothing being asked.
    -- Beside the name on a row laid flat, under it on one that is not -- and under
    -- it means under the *name*, in the column the name is in, so the two read as
    -- a heading and the line belonging to it rather than as two columns.
    local ask = I18n.say(Challenges.ask(row))
    if ask then
        love.graphics.setColor(Palette.red)
        if lay.lines == 1 then
            Font.print(ask, nameX + lay.nameW + COL_GAP, y)
        else
            Font.print(ask, nameX, y + LINE)
        end
    end

    -- The figure, and only while there is a rung to count towards. Slate rather
    -- than graphite: it is a live number about a live demand, and graphite here is
    -- what a spent thing is drawn in.
    --
    -- Hard against the right edge of the block where the row has a right edge to
    -- hang it on, and on the line under the demand where it has not -- with no
    -- blank line between them, because there the two are one sentence: what is
    -- owed, and what has been paid off it. That is the library's own treatment of
    -- the same pair (`Library:drawLine`), which it should be, since it is the same
    -- pair.
    local meter = Challenges.meter(row)
    if meter then
        love.graphics.setColor(Palette.slate)
        if lay.lines == 3 then
            Font.print(meter, nameX, y + LINE * 2)
        else
            Font.print(meter, bx + lay.blockW - Font.width(meter), y)
        end
    end
end

-- One footer arrow, in the corner button's own recipe: a slate box filled with
-- paper and the chevron in the middle of it. The same glyph both ways round --
-- three columns wide, so its origin is the middle one and the flip is an exact
-- mirror rather than a resample.
function Homework:drawArrow(dir)
    local x, y = self:arrowBox(dir)

    love.graphics.setColor(Palette.slate)
    love.graphics.rectangle("fill", x, y, ARROW, ARROW)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, ARROW - 2, ARROW - 2)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons.chevron:draw(x + ARROW / 2, y + ARROW / 2, dir > 0)
end

-- One spread: the section laid across both leaves, with nothing on it that does
-- not turn with it. Called into a canvas rather than onto the screen while a leaf
-- is moving (src/spread.lua), which is why it is a whole overprint pass of its
-- own and why it takes the section rather than reading `self`.
function Homework:drawPage(game, section)
    local lay = self.lay
    local rows = sections()[section].rows

    -- Written on the page rather than laid over it, like every other screen in
    -- the book: the ruling shows through the lettering, and the ruling is the
    -- lesson you came in from, because the book is still open at it -- you have
    -- turned to another part of it rather than closed it.
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()

    -- The gutter first, so everything else is printed over it rather than under
    -- it: it is the shadow the fold casts on the paper, not on the list.
    self.book:drawCrease()
    self.marks:draw(0)

    -- The list, down the verso and on down the recto, and a row that would run off
    -- the foot of the page is not drawn rather than being drawn half. Every
    -- section fits the shortest page this game is handed with room over; the guard
    -- is for a window squashed past anything a phone or a desktop hands us, where
    -- a list that drew through the footer would be the one thing on screen that
    -- ignored it.
    local half = self:half(rows)
    for i, row in ipairs(rows) do
        local leaf = i <= half and 1 or 2
        local n = leaf == 1 and i or i - half
        local y = lay.list + (n - 1) * lay.rowH

        if y + Font.height <= lay.bottom then
            local lx = self.book:leaf(leaf)
            self:drawRow(lay, row, lx + lay.blockOff, y)
        end
    end

    Overprint.finish()
end

function Homework:draw(game)
    local lay = self:layout(game)

    -- The leaf, or the two of them, or the one turning between them.
    self.book:draw(game, function(section) self:drawPage(game, section) end)

    -- And then everything that is the book rather than the leaf, out past the
    -- pass: the way back, the heading, how much of this section is done and the
    -- footer that steps it. None of it moves when a page does, which is the whole
    -- reason it is drawn here and not up there -- and it is the same reason the
    -- arrows were already out here, the library's: a box filled in paper still
    -- has every inked pixel of its border paired with the page underneath, so a
    -- border landing on a rule comes out a step darker and the box reads as a
    -- transparency rather than as a thing lying on the page.
    Scribble.printBig(I18n.t(HEAD), lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    -- How many rungs of this section have fallen, out of how many it has. Rungs
    -- rather than rows, because a row is not a thing you finish in one go: three
    -- pips of a bestiary row are three separate afternoons, and a count that only
    -- moved when the last of them fell would sit still for a month.
    local done, all = 0, 0
    for _, row in ipairs(self:rows()) do
        done = done + Challenges.done(row)
        all = all + #row.want
    end

    -- Right-aligned by centring it on the middle of the room it takes, since
    -- centring is the only thing `printBig` knows how to do, so it grows leftwards
    -- off the edge it hangs on. Red once there is nothing left on this section.
    local count = ("%d/%d"):format(done, all)
    Scribble.printBig(count, lay.tallyRight - Font.width(count) / 2, lay.tally, 1,
        done >= all and Palette.red or Palette.slate, { seed = 62 })

    -- The section, between the two arrows that step it, and red because it is the
    -- one thing in the footer that changes. It names the section the book is
    -- *open* at throughout a turn, so it changes on the frame the leaf lands
    -- rather than while it is in the air -- a label that renamed itself halfway
    -- through the gesture would be naming neither page.
    Scribble.printBig(I18n.t(sections()[self.book.at].name), lay.cx,
        lay.arrowY + math.floor((ARROW - Font.height) / 2), 1, Palette.red,
        { seed = 60 })

    self:drawArrow(-1)
    self:drawArrow(1)
    Hud.drawCorner(game, "back", false)
end

return Homework
