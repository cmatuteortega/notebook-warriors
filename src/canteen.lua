-- The canteen: the counter the purse is spent over.
--
-- It was one of the two instances of src/blank.lua until there was something to
-- put on it, which is exactly the move that module's header describes -- a page
-- that grows anything of its own moves out into a module of its own and takes
-- what it needs with it. What it grew first was the purse (src/purse.lua), and
-- what it has grown since is the other half of that transaction: the things there
-- are to spend it on (src/perks.lua), each of them a level you own for ever and a
-- use you spend once a run. Three of them are spent on a draft and the fourth is
-- spent the frame the run would have ended, and the counter does not care which:
-- a row is a name, a price and a box whatever the thing at the end of it does.
--
-- **On a spread, the goods are on the verso and what they do is on the recto**
-- (src/spread.lua), one blurb on the line facing the row it belongs to. That is
-- not an arrangement invented for the fold: it is the only one the fold allows.
-- A leaf is half the page, and the widest blurb on this counter is wider than
-- everything else in a row put together -- so with the sentence in the words
-- column a spread cannot hold a row at all, and the counter degrades to prices
-- with nothing saying what they buy. Facing pages are what a book does with
-- exactly that problem, and it turns out to read better than the stacked
-- version: the left page is the transaction and the right page is the argument
-- for it. Where there is only one leaf nothing moves -- the sentence goes back
-- under the name where it has always been.
--
-- **Three kinds of thing are sold here, so the counter has three sections.** A
-- perk is a use a run spends, a hero is a hero (src/characters.lua) and a course
-- is how hard the whole book is (src/course.lua) -- the first is spent on a screen
-- the run has stopped for, the second decides who walks onto the page and the
-- third decides what he walks into -- and the note under the counter says which of
-- those you are looking at, which is the whole reason they are not one list: a
-- page printing EVERY LEVEL IS ONE USE A RUN over a row selling the starman would
-- be the counter lying about its own goods. They are stepped with the library's own footer (`<` the
-- section `>`), and the rows themselves know nothing about it: a row is a name, a
-- price and a box, plus a `shop` to ask the five questions a price needs answering,
-- and src/perks.lua and src/characters.lua answer those five the same way -- so one
-- function draws a reroll and a hero.
--
-- **And a fourth section that sells nothing.** REFUND hands back everything bought
-- on the other three at what was paid for it (src/refund.lua), which is one row and
-- the same transaction as any other as far as this screen goes -- a name, a price
-- and a box -- with one thing about it written down: `back` on the row, which is
-- what makes the figure read `+40` rather than `40`. It is a section rather than a
-- row at the bottom of one because it is about all three of the others at once, and a
-- row on the perks page that also sold your heroes back would be the counter's own
-- split broken by the one row that cannot respect it.
--
-- The split also happens to be what makes the page *fit*: a box is twenty pixels
-- deep, so seven rows in one column is a counter hanging off the bottom of a
-- sixteen-by-nine page. That is not why the split is where it is -- it is where the
-- note stops being true -- but it is why there had to be one somewhere. The course
-- ladder is one row for the same reason it is one row in src/course.lua and not
-- three: buying a master's before a bachelor's is not a thing this book should
-- have to have an opinion about, and a line whose level *is* how far up you are
-- cannot express it.
--
-- **The purse is furniture and the counter is the page**, which is the split this
-- screen was laid out along before there was anything on the counter at all. What
-- you *have* hangs small in the top right at 1:1 -- the corner button's own margin
-- mirrored to the other end of the same top edge, and level with it -- and what
-- there is to *buy* is the body of the page, read down the middle from under the
-- heading. Buying does not move the readout and the readout does not move for a
-- purse that has reached a hundred: the room it keeps is struck off four figures
-- rather than off the number showing.
--
-- **Buying is the one thing on this page that is answered rather than pressed.**
-- Everywhere else in the margins of this book -- the tabs, the library's names, the
-- settings page's bars -- a press is a press, on the rule that choosing what to
-- look at is not a question and a quantity is not an answer. A purchase is neither
-- of those. It is a thing you cannot take back, and a box you scribble in is how
-- this game asks about one (src/scribble.lua) -- so each row has a box at the end
-- of it, it warms slate to blue to red as it fills, it commits when the pen comes
-- off, and the coins come out then and not before. A row with nothing left to sell,
-- or nothing in the purse to buy it with, has no box drawn at all and ink that
-- lands where one would be is ink on the page.
--
-- The box is *wiped* after a purchase rather than spent (`Choice:clear`), which is
-- the studio's RESET doing the same job: a counter you can only buy one thing at
-- is a counter you have to leave and come back to.
--
-- And the page it is all drawn on is whichever lesson you opened it from: the book
-- is still open there and you have turned to the back of it.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Purse = require("src.purse")
local Perks = require("src.perks")
local Characters = require("src.characters")
local Course = require("src.course")
local Refund = require("src.refund")
local Hud = require("src.hud")
local Sprites = require("src.sprites")
local Sfx = require("src.sfx")
local Spread = require("src.spread")
local I18n = require("src.i18n")

local Canteen = {}
Canteen.__index = Canteen

local HEAD = "CANTEEN"
local HEAD_SCALE = 2
local EDGE = 4
local HEAD_TOP = 10    -- the heading off the top of the page, the library's own
                       -- clearance
local HEAD_GAP = 9     -- ... and the settings page's gap down to the first row

local ROW_GAP = 5      -- one row of the counter to the next
local LINE_GAP = 2     -- ... and the two lines inside one row, where it has two
local COL_GAP = 5      -- one column of a row to the next
local HINT_GAP = 8     -- the last row down to the two lines under it
local FOOT_GAP = 6     -- ... and the lowest of those down to the arrows
local ARROW = 11       -- the library's footer arrow, which is the corner button's
                       -- box
local ARROW_GAP = 6    -- ... and its clearance off the section name between them

-- The room the readout keeps in its corner, in figures rather than in pixels: a
-- purse this deep is a million kills, and reserving for it is what stops the
-- heading's clearance depending on how rich you are.
local WIDEST = "0000"

-- And the widest price any row could ever ask, for the same reason down the page:
-- the price column is struck off two figures rather than off the price showing, so
-- nothing in a row moves as a line is bought up.
local WIDEST_PRICE = "00"

-- What a row says where the price used to be once there is nothing left to sell.
-- The draft's own word for a line with no level after this one, which is the same
-- fact about the same kind of thing.
local MAX = "MAX"

-- How long the border of a bought box goes on flashing before it is wiped and can
-- be answered again. The draft's own confirm, since it is the same flash saying the
-- same thing -- an answer has landed.
local BOUGHT = 0.34

-- The four sections, in the order the purse meets them: what you spend inside a
-- run, who plays it, how hard the book is, and the way back off all three. `note` is the line under the counter saying what a level of
-- anything on this section actually *is*, which is the thing the two halves disagree
-- about and the whole reason there are two of them. `keys` is the other line's
-- keyboard half, written out because English is the key (src/i18n.lua) -- a section
-- that grows a row adds a figure to it and to the Spanish beside it.
-- `shut`, `touch` and `keys` are the three lines under the counter, and the first
-- two are only written where the page's own words would be wrong: a section with
-- nothing to answer on it says COME BACK WITH MORE COINS, which is true of a
-- counter and nonsense about a refund.
local SECTIONS = {
    {
        name = "PERKS",
        note = "EVERY LEVEL IS ONE USE A RUN",
        keys = "SCRIBBLE A BOX OR PRESS 1 2 3 4",
    },
    {
        name = "HEROES",
        note = "A HERO IS YOURS FOR GOOD",
        keys = "SCRIBBLE A BOX OR PRESS 1 2 3",
    },
    -- The course ladder (src/course.lua), and the last thing on the counter that
    -- is actually sold. It is here rather than first because the sections run in
    -- the order the purse meets them, and this is the furthest of the three from
    -- the run itself: a perk is spent inside one, a hero plays one, and a course
    -- is which book the whole afternoon is out of. It is also the dearest, which
    -- is the same fact said in coins.
    --
    -- The note is the one line on this page that has to carry the whole idea, so
    -- it says the *bargain* rather than the mechanism: what a level of this is, is
    -- a harder book, and the reason to want one is that it pays.
    {
        name = "COURSES",
        note = "EVERY LEVEL IS A HARDER BOOK",
        keys = "SCRIBBLE A BOX OR PRESS 1",
    },
    -- And the way back off the other three (src/refund.lua), which is a section
    -- rather than a row at the bottom of one because it is about all three of them
    -- at once -- a row on the perks page that also sold your heroes back would be the
    -- counter's own split broken by the one row that cannot respect it. One row on
    -- it, so the block below the heading stands where it always stands and most of
    -- it is empty: the furniture on this page does not move for what is on it, and
    -- a section you turn to expecting a list and find one line on is a page saying
    -- there is one thing here.
    {
        name = "REFUND",
        note = "YOU GET EVERY COIN BACK",
        keys = "SCRIBBLE A BOX OR PRESS 1",
        touch = "SCRIBBLE A BOX TO REFUND",
        shut = "NOTHING TO REFUND",
    },
}

-- One list of rows per section, built once: both catalogues are the same tables for
-- every screen the program draws and nothing here reads a run, so there is nothing
-- to rebuild when the page is opened again. What *is* asked every frame is what a
-- row costs and how much of it you own, and that is the `shop`'s business.
--
-- The hero with no price is the one the book comes with, and it is not on the
-- counter at all: a row that cannot be bought and cannot be wanted is a row saying
-- you already have something.
local counters

local function build()
    if counters then return end

    counters = { {}, {}, {}, {} }
    for _, row in ipairs(Perks.list) do
        counters[1][#counters[1] + 1] = {
            key = row.key, name = row.name, blurb = row.blurb, icon = row.icon,
            shop = Perks,
        }
    end
    for _, char in ipairs(Characters.list) do
        if char.price then
            counters[2][#counters[2] + 1] = {
                key = char.key, name = char.name, blurb = char.blurb,
                icon = char.icon, shop = Characters,
            }
        end
    end
    -- The one row of the course section, and the ladder is *one* line with three
    -- levels on it rather than three lines with one -- so the row says COURSE and
    -- what is on the strip beside it is how many rungs of it have been paid for,
    -- exactly as a perk's row does. What each of them is actually called is on the
    -- timetable, where you pick which to sit (src/timetable.lua): a counter is
    -- where you enrol and not where you choose.
    counters[3][1] = {
        key = Course.KEY, name = "COURSE", blurb = "HARDER BOOK, MORE COINS",
        icon = "cap", shop = Course,
    }
    -- The one row of the last section, and the only row on the counter whose
    -- figure is money coming the other way -- which is what `back` says, and the
    -- one thing about a row this page's drawing has to be told. The coin is its
    -- icon for the reason every other row wears the icon of the thing it hands
    -- over: what this one hands over is coins.
    counters[4][1] = {
        key = Refund.KEY, name = "REFUND ALL",
        blurb = "EVERY PERK HERO AND COURSE",
        icon = "coin", shop = Refund, back = true,
    }
end

function Canteen.new()
    return setmetatable({ book = Spread.new() }, Canteen)
end

function Canteen:enter()
    self.t = 0
    self.back = false
    self.bought = nil     -- the box whose border is still flashing
    self.boughtT = 0

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the tab that opened this page is not this page's
    -- to read: it presses nothing and draws nothing until it is lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()
    self.book:rest()

    -- One unlabelled box per row of the counter -- the row is the label, the way a
    -- draft card is the label of the box under it -- placed by `layout`. Every row
    -- gets one whether or not it can be bought today: which of them is *drawn* is
    -- decided a frame at a time, and a box that came and went would be a box that
    -- moved the rows under it.
    build()

    -- One choice per section rather than one for the counter. A box belongs to the
    -- row it is at the end of, and stepping to the other section is arriving at
    -- other rows: a box that changed which row it answered for would be a scribble
    -- begun on a reroll and finished on a hero.
    self.choices = {}
    for i, rows in ipairs(counters) do
        local defs = {}
        for j, row in ipairs(rows) do
            defs[j] = { key = row.key }
        end
        self.choices[i] = Scribble.newChoice(defs, 1)
    end
    self.choice = self.choices[self.book.at]

    -- The page starting to move is this counter putting down whatever was in its
    -- hand: see `leaving`.
    self.book.onTurn = function() self:leaving() end

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

-- The rows of the section showing. Everything on this page that is about *a* row
-- goes through here, and the two things that are about all of them -- how wide a
-- column has to be, how deep the block is -- deliberately do not (see `layout`).
function Canteen:rows()
    return counters[self.book.at]
end

-- The row a box is at the end of. Boxes and rows are the same list in the same
-- order, one choice per section, so this is a lookup by position rather than a
-- search for a key.
function Canteen:rowAt(box)
    for i, other in ipairs(self.choice.boxes) do
        if other == box then return self:rows()[i] end
    end
    return nil
end

-- What the purse holds, plainly. No plus on it, unlike the two cards a run ends
-- on: those are showing something being added and this is showing what there is.
function Canteen:total()
    return ("%d"):format(Purse.total)
end

--- layout --------------------------------------------------------------------

-- Every column of the counter, measured at the widest thing that could ever stand
-- in it rather than at what stands there now: the widest name in the language it
-- will be lettered in, the widest blurb, two figures of price, and the box. Which
-- is the timetable's rule and the settings page's -- nothing in a block may move
-- because something in it was answered.
--
-- Every section at once, never the one showing: this is the library's rule about
-- its three shelves and it holds here for the same reason twice over. Nothing may
-- move as a row is bought, and nothing may move as the footer is stepped either --
-- the heading, the block and the boxes are in the same place on every section, so
-- what changes when you turn to the other one is the words in them.
local function eachRow(fn)
    for _, rows in ipairs(counters) do
        for _, row in ipairs(rows) do fn(row) end
    end
end

local function nameWidth()
    local w = 0
    eachRow(function(row) w = math.max(w, Font.width(I18n.t(row.name))) end)
    return w
end

local function blurbWidth()
    local w = 0
    eachRow(function(row) w = math.max(w, Font.width(I18n.t(row.blurb))) end)
    return w
end

-- The refund is the one row that can say a bigger number than any row asks -- it
-- says the whole counter at once, with a sign in front of it -- so the column is
-- struck off that rather than off two figures, and it stops moving for the same
-- reason everything else here does: it is measured at what could ever stand in it.
local function priceWidth()
    local w = math.max(Purse.width(WIDEST_PRICE), Font.width(I18n.t(MAX)))
    return math.max(w, Purse.width(("+%d"):format(Refund.most())))
end

-- How wide the `n/n` column has to be, asked of the rows rather than written down:
-- a perk line is three long and a hero is one, and the counter reserves for the
-- longest of them.
local function ownWidth()
    local most = 1
    eachRow(function(row) most = math.max(most, row.shop.levels(row.key)) end)
    return Font.width(("%d/%d"):format(most, most))
end

-- The biggest icon anywhere on the counter, and how many rows the fullest section
-- has: the block is reserved at both, so the counter is the same shape whichever
-- section is up.
local function iconSize()
    local w, h = 0, 0
    eachRow(function(row)
        local icon = Sprites.icons[row.icon]
        w, h = math.max(w, icon.w), math.max(h, icon.h)
    end)
    return w, h
end

local function mostRows()
    local n = 0
    for _, rows in ipairs(counters) do n = math.max(n, #rows) end
    return n
end

-- And the widest section name, so the two footer arrows never move as one is
-- pressed.
local function sectionWidth()
    local w = 0
    for _, section in ipairs(SECTIONS) do
        w = math.max(w, Font.width(I18n.t(section.name)))
    end
    return w
end

-- The heading in the top row with the corner button in the margin at one end of
-- it and the purse at the other, and the guard is the library's doubled: on a page
-- narrow enough, or with a heading long enough, that the title would meet either
-- of them, it steps down below both -- they are the two things here that cannot
-- move.
--
-- Everything under it is one block, **centred** in the page the heading leaves --
-- the settings page's shape rather than the library's, and for the settings page's
-- reason: the counter is as many rows as src/perks.lua has, in both languages and
-- in every purse, so there is something here whose height is the same twice. The
-- library reads from the top because the catalogue decides how long its lists are
-- and a page that recentred itself would move every name on the shelf each time an
-- arrow was pressed; nothing on this counter can change height at all.
--
-- The block degrades one way, and only one: the blurbs go first. A row is an icon,
-- a name, what it does, how many you own, what the next one costs and a box to
-- answer, and the only one of those the page can do without is the sentence -- the
-- rest is the transaction. On a phone held upright that is the difference between
-- the counter fitting and the prices hanging off the edge of it.
function Canteen:layout(game)
    self.game = game

    local ins = game.inset
    local lay = {}
    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)

    -- The book first: the counter is laid out on a *leaf*, and whether there are
    -- two of them is what decides where the sentence under a name goes.
    local book = self.book
    book:fit(game, #SECTIONS)
    local versoX, _, leafW = book:leaf(1)
    local rectoX = book:leaf(2)
    lay.w = leafW - EDGE * 2
    lay.two = book:spread()

    -- The corner button's box mirrored to the other end of the same edge, and
    -- level with it: the coin is two pixels shallower than the button, so it is
    -- dropped by half that rather than hung off the top of the safe area.
    local bx, by = Hud.cornerBox(game)
    lay.purseRight = game.vw - ins.r - Hud.CORNER_MARGIN
    lay.purse = by + math.floor((Hud.CORNER_SIZE - Purse.height()) / 2)

    local headW = Font.width(I18n.t(HEAD)) * HEAD_SCALE
    local purseLeft = lay.purseRight - Purse.width(WIDEST)
    local underBoth = math.max(Hud.cornerBottom(game),
        lay.purse + Purse.height()) + EDGE
    local clears = lay.cx - headW / 2 > bx + Hud.CORNER_SIZE + EDGE
        and lay.cx + headW / 2 < purseLeft - EDGE
    lay.head = clears and ins.t + HEAD_TOP or underBoth

    local icon, iconH = iconSize()
    lay.nameW = nameWidth()
    lay.ownW = ownWidth()
    lay.priceW = priceWidth()

    -- The words column is as wide as the wider of the two things written in it, so
    -- a name and the sentence under it read as one block rather than as two
    -- columns that happen to start together.
    -- **How a row is arranged is the page's decision**, and there are three of
    -- them, each narrower than the last:
    --
    --   wide   [icon] REROLL            0/3   5   [box]
    --                 THREE NEW CARDS
    --   plain  [icon] REROLL            0/3   5   [box]
    --   stack  [icon] REROLL                      [box]
    --                 0/3           5
    --
    -- The widest that fits wins. `wide` is only ever on offer where the sentence is
    -- on this page at all, which is where there is one leaf: on a spread it is
    -- printed facing the row instead, for the reason the header gives. And `stack`
    -- is what a leaf comes to -- the goods alone are a hundred and forty pixels
    -- across and a leaf is a hundred and fifty, so a row laid flat runs to the
    -- paper's edge -- which is the trade taken deliberately: **a row may have as
    -- many lines as it likes and may not eat the margin.**
    --
    -- It costs nothing down the page either, which is the good luck in it. The box
    -- at the end of a row is twenty pixels deep and two lines of lettering are
    -- twelve, so the second line goes *inside* the height the row already had: a
    -- stacked counter is exactly as tall as a flat one.
    local words = lay.nameW
    lay.facing = lay.two
    lay.blurbs = true

    local ends = COL_GAP + lay.ownW + COL_GAP + lay.priceW + COL_GAP + Scribble.BOX_W
    local wide = icon + COL_GAP + math.max(words, blurbWidth()) + ends
    local plain = icon + COL_GAP + words + ends
    lay.stackW = math.max(words, lay.ownW + COL_GAP + lay.priceW)
    local stack = icon + COL_GAP + lay.stackW + COL_GAP + Scribble.BOX_W

    local blockW
    if not lay.facing and wide <= lay.w then
        blockW = wide
    elseif plain <= lay.w then
        lay.blurbs = false
        blockW = plain
    else
        lay.blurbs = false
        lay.stack = true
        blockW = stack
    end
    if lay.facing then lay.blurbs = false end

    lay.blockX = versoX + EDGE + math.floor((lay.w - blockW) / 2)
    lay.iconX = lay.blockX + math.floor(icon / 2)
    lay.wordsX = lay.blockX + icon + COL_GAP
    lay.boxX = lay.blockX + blockW - Scribble.BOX_W

    -- Stacked, the pair goes on the second line of the words column -- how many
    -- you own against its left edge and what the next one costs against its right,
    -- so the prices still line up down the counter and the row still reads left to
    -- right. Flat, they are the two columns they always were.
    if lay.stack then
        lay.ownX = lay.wordsX
        lay.priceCx = lay.wordsX + lay.stackW - math.floor(lay.priceW / 2)
    else
        lay.ownX = lay.blockX + blockW - Scribble.BOX_W - COL_GAP - lay.priceW
            - COL_GAP - lay.ownW
        lay.priceCx = lay.ownX + lay.ownW + COL_GAP + math.floor(lay.priceW / 2)
    end

    -- The facing page: the sentences, left-aligned in the room the widest of them
    -- takes, and everything the counter has to say about the section under them.
    -- Struck off the widest sentence in the whole catalogue and not off the ones
    -- on this section, which is this page's rule everywhere else and holds here
    -- for the same reason: nothing may move because the page was turned.
    lay.blurbX = rectoX + EDGE
        + math.floor((lay.w - math.min(lay.w, blurbWidth())) / 2)
    lay.sayCx = lay.two and rectoX + math.floor(leafW / 2) or lay.cx

    -- A row is as deep as the box at the end of it, which is deeper than either the
    -- icon or two lines of lettering -- so the row height is one number whether the
    -- blurbs are on the page or not, and dropping them never moves anything down it.
    lay.rowH = math.max(Scribble.BOX_H, iconH, Font.height * 2 + 2)

    local rows = mostRows()
    local rowsH = rows * lay.rowH + (rows - 1) * ROW_GAP
    -- Two lines under the rows: what to do, and the one fact about what a level is
    -- worth. The draft's own pair, and reserved whether or not they will fit.
    local blockH = rowsH + HINT_GAP + Font.height * 2 + 2

    -- The footer off the bottom edge, pinned to it rather than centred with the
    -- counter: it is the library's footer doing the library's job -- which section
    -- of the same page am I reading -- so it sits where the library's sits.
    lay.arrowY = game.vh - ins.b - EDGE - ARROW
    lay.sectionW = sectionWidth()

    -- Centred in what is left below the heading and above the footer, and never
    -- above the heading: the title, the two things in the top corners and the
    -- arrows are the things on this page that cannot move.
    local from = math.max(underBoth,
        lay.head + Font.height * HEAD_SCALE + HEAD_GAP)
    lay.rowTop = math.max(from,
        math.floor(from + (lay.arrowY - FOOT_GAP - from - blockH) / 2))
    lay.hint = lay.rowTop + rowsH + HINT_GAP

    -- Where each row of the section showing stands, kept here rather than on the
    -- catalogue's own rows: src/perks.lua and src/characters.lua are the same tables
    -- for every screen the program draws, and a layout that wrote into either would
    -- be one screen deciding where another one's rows are.
    lay.rows = {}
    for i = 1, mostRows() do
        lay.rows[i] = lay.rowTop + (i - 1) * (lay.rowH + ROW_GAP)
    end

    -- Every section's boxes and not only the section showing, because while a leaf
    -- is turning two of them are being drawn at once: the page you are leaving and
    -- the page coming up under it are both real for a third of a second, and a
    -- section whose boxes had never been placed would arrive with them all at the
    -- origin. They all land in the same column at the same heights, so this costs
    -- a dozen assignments and buys the turn.
    for i, choice in ipairs(self.choices) do
        for j in ipairs(counters[i]) do
            choice:place(choice.boxes[j], lay.boxX,
                lay.rows[j] + math.floor((lay.rowH - Scribble.BOX_H) / 2))
        end
    end

    self.lay = lay
    return lay
end

function Canteen:rowY(i)
    return self.lay.rows[i]
end

--- update --------------------------------------------------------------------

-- One of the two footer arrows, as a box: the library's own recipe, both struck off
-- the middle of the page with the widest section name between them.
function Canteen:arrowBox(dir)
    local lay = self.lay
    local half = (lay.sectionW + (ARROW + ARROW_GAP) * 2) / 2
    local x = dir < 0 and lay.cx - half or lay.cx + half - ARROW
    return math.floor(x), lay.arrowY
end

-- Which arrow, if either, a point lands on. Padded the way every small target in
-- the game is padded, and by more on a phone.
function Canteen:arrowAt(x, y)
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

-- The other section. Turning a page rather than changing your mind, so a box left
-- part-scribbled is still part-scribbled when you come back to it -- but whatever
-- was *armed* is disarmed on the way out, since nothing is bought until the pen
-- lifts and the pen is about to lift somewhere else. Leaving it armed would be a
-- purchase waiting for the frame you turned back.
function Canteen:leaving()
    self.choice.armed = nil

    -- And the flash is landed on the way out rather than carried: it belongs to a
    -- purchase on a page you are no longer looking at, and the box under it has to
    -- be wiped either way. Wiped here, while `self.choice` is still the section it
    -- was bought on -- which it is, because the book only moves `at` when the leaf
    -- lands and this is called as it lifts.
    if self.bought then
        self.choice:clear(self.bought)
        self.bought = nil
    end
end

-- An arrow, or a key: the same turn a finger makes, run at its own pace. `leaving`
-- is hung off the book rather than called here, so a page turned by hand puts the
-- counter down exactly as a page turned by an arrow does.
function Canteen:step(dir)
    self.book:turn(dir)
end

function Canteen:backAt(x, y)
    local bx, by, bw, bh = Hud.cornerTarget(self.game)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

-- The corner button and the two footer arrows swallow whatever crosses them rather
-- than being drawn on: a press on one was taken as a press rather than as the start
-- of a line.
-- Answers whether the stamp became ink, which is what the pen's swish is fired
-- off (src/scribble.lua): a swallowed stamp was never a line, so it must not
-- sound like one.
--
-- A box for a row that cannot be bought is deliberately *not* swallowed. It is not
-- drawn either, so what is there is bare page, and ink laid across bare page is a
-- line -- swallowing it would be the page refusing to be drawn on over a rectangle
-- of nothing.
-- Furniture: the corner button and the two footer arrows. One question rather
-- than two, because both of the things that ask it want the same answer -- the pen
-- must not draw here, and the book must not take the page here.
function Canteen:furniture(x, y)
    return self:backAt(x, y) or self:arrowAt(x, y) ~= nil
end

function Canteen:mark(x, y)
    -- A finger turning a page is a hand on the paper rather than a nib on it, so
    -- it swallows its stamps the way every other piece of furniture does -- and
    -- for the extra reason that a scribble does something here: a drag across the
    -- counter that filled a box on its way out would buy a thing you were leaving.
    if self.book:eating() then return false end
    if self:furniture(x, y) then return false end

    local box = self.choice:boxAt(x, y)
    -- A box still flashing what it just bought is furniture and swallows what
    -- crosses it: it is drawn, so ink over it would be ink on a box, and it is
    -- about to be wiped anyway -- the alternative is a scribble that carries on
    -- through the flash and buys the next level nobody asked for.
    if box and box == self.bought then return false end

    local row = box and self:rowAt(box)
    if row and row.shop.canBuy(row.key) and self.choice:mark(x, y) then
        return true
    end

    self.marks:add(x, y)
    return true
end

function Canteen:press(x, y)
    if self.book:eating() then return end

    if self:backAt(x, y) then
        self.back = true
        return
    end

    local dir = self:arrowAt(x, y)
    if dir then self:step(dir) end
end

-- Bought, by whichever catalogue the row came off (`shop.buy`, through
-- `Purse.spend`) -- the purse is what refuses, so a price that moved between the
-- frame the box was drawn and the frame it filled costs nothing worse than a box
-- that flashes and hands nothing over.
function Canteen:buy(box)
    local row = self:rowAt(box)
    if row and row.shop.buy(row.key) then
        Sfx.play("accept")
    end
    self.bought, self.boughtT = box, 0
end

-- Returns "back" the moment the corner button is pressed, and nothing at all
-- otherwise. There is no other way off this page, and nothing for it to hand
-- over: what is bought here belongs to the book rather than to a run, so a screen
-- that spends the purse still has nothing to give back.
function Canteen:update(dt, game)
    -- The section is the book's, so the choice is too, and it is picked up before
    -- anything is laid out: the leaf landing is what moves it.
    self.choice = self.choices[self.book.at]

    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.back then return "back" end

    -- The flash, and then the box is wiped so the next level of the same line can
    -- be answered in it. Wiped rather than left full for the studio's RESET reason:
    -- a box that does something to the screen it is on rather than closing it has
    -- to be answerable twice.
    if self.bought then
        self.boughtT = self.boughtT + dt
        if self.boughtT >= BOUGHT then
            self.choice:clear(self.bought)
            self.bought = nil
        end
    end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    -- The book first, so that the frame a stroke turns into a turn is a frame the
    -- pen lays nothing and the box it was crossing is not filled in.
    self.book:track(dt, down, Input.pointerX, Input.pointerY,
        self:furniture(Input.pointerX, Input.pointerY))

    -- The keyboard's scribble, run on. It answers outright -- there is no pen to
    -- lift -- exactly as it does in the draft.
    local filled = self.choice:update(dt)
    if filled then self:buy(filled) end

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    -- Armed, not answered: nothing is bought until the pen comes off the page, so
    -- a scribble that carries on out of a box changes its mind.
    if self.choice.armed and not down then
        self:buy(self.choice.armed)
        self.choice.armed = nil
    end

    if self.back then return "back" end
end

function Canteen:keypressed(key)
    -- Backspace is the corner button, exactly as it is on the timetable, in the
    -- library and on the homework page.
    if key == "backspace" then
        self.back = true
        return
    end

    -- Left and right step the section, the way the arrows they stand for do: the
    -- library's own keys, on the library's own footer.
    if key == "left" or key == "a" then
        self:step(-1)
        return
    elseif key == "right" or key == "d" then
        self:step(1)
        return
    end

    -- And the number keys are the rows of the section showing, the draft's own
    -- shortcut: the scribble is drawn in rather than jumped past, so a row is still
    -- bought the only way a row is bought.
    if self.book:turning() then return end

    local i = tonumber(key)
    local box = i and self.choice.boxes[i]
    local row = box and self:rows()[i]
    if row and row.shop.canBuy(row.key) then
        self.choice:autoFill(box)
    end
end

--- draw ----------------------------------------------------------------------

-- What the next one costs, or that there is no next one. The pair is drawn by
-- src/purse.lua wherever a coin count is drawn, so a price on the counter is the
-- same drawing as the payout on a card -- and it is drawn in *graphite* when it
-- cannot be afforded, which is the one thing on this page saying why a row has no
-- box on it.
function Canteen:drawPrice(row, y)
    local lay = self.lay
    local price = row.shop.priceOf(row.key)

    if not price then
        love.graphics.setColor(Palette.slate)
        Font.printCentered(I18n.t(MAX), lay.priceCx, y)
        return
    end

    -- The refund row wears the sign the two end cards' payouts wear (`+3`), since
    -- what its figure says is what you would be handed rather than what you would
    -- be asked for -- and the same coin and the same face either way, because it
    -- is the same currency and reads as one drawing (src/purse.lua).
    local text = (row.back and "+%d" or "%d"):format(price)
    Purse.draw(text, lay.priceCx, y - math.floor((Purse.height() - Font.height) / 2),
        row.shop.canBuy(row.key) and Palette.ink or Palette.graphite)
end

function Canteen:drawRow(i, row)
    local lay = self.lay
    local blurb = lay.facing or lay.blurbs
    local top = self:rowY(i)
    local icon = Sprites.icons[row.icon]

    love.graphics.setColor(1, 1, 1)
    icon:draw(lay.iconX, top + math.floor(lay.rowH / 2))

    -- The name and, under it, either what pressing one of these does or what you
    -- own and what it costs -- whichever the row is carrying on a second line.
    -- Both lines are centred against the row *as a block*, so a row with two and a
    -- row with one both sit in the middle of their own height.
    local two = lay.stack or (blurb and not lay.facing)
    local textH = two and Font.height * 2 + LINE_GAP or Font.height
    local textY = top + math.floor((lay.rowH - textH) / 2)
    local under = textY + Font.height + LINE_GAP

    love.graphics.setColor(Palette.ink)
    Font.print(I18n.t(row.name), lay.wordsX, textY)

    -- What pressing one of these does: under the name on one leaf, on the line
    -- facing it on two. Facing, it is set on the row's own middle rather than
    -- under anything, so the sentence and the price it is arguing for are on one
    -- line across the fold.
    if blurb then
        love.graphics.setColor(Palette.graphite)
        if lay.facing then
            Font.print(I18n.t(row.blurb), lay.blurbX,
                top + math.floor((lay.rowH - Font.height) / 2))
        else
            Font.print(I18n.t(row.blurb), lay.wordsX, under)
        end
    end

    -- How many you own out of how many there are, red once the line is finished --
    -- which is the slot counters' own rule on the held screens (src/hud.lua): red
    -- means full, and a full line and a full set of slots are the same news.
    local level = row.shop.level(row.key)
    local most = row.shop.levels(row.key)

    -- On the row's own middle where they are columns of their own, and on the
    -- second line of the words column where the row has stacked: the pair belongs
    -- to the name above it either way, and either way it is one line of lettering
    -- set against something.
    local at = lay.stack and under or top + math.floor((lay.rowH - Font.height) / 2)

    love.graphics.setColor(level >= most and Palette.red or Palette.slate)
    Font.print(("%d/%d"):format(level, most), lay.ownX, at)

    self:drawPrice(row, at)
end

-- One footer arrow, in the corner button's own recipe: a slate box filled with
-- paper and the chevron in the middle of it. The same glyph both ways round -- three
-- columns wide, so its origin is the middle one and the flip is an exact mirror
-- rather than a resample.
function Canteen:drawArrow(dir)
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
-- is moving (src/spread.lua), which is why it is a whole overprint pass of its own
-- and why it takes the section rather than reading `self`.
function Canteen:drawPage(game, at)
    local lay = self.lay
    local rows = counters[at]
    local section = SECTIONS[at]

    -- Written on the page rather than laid over it, like every other screen in
    -- the book: the ruling shows through the lettering, and the ruling is the
    -- lesson you came in from -- the coin included, which is why its fill goes a
    -- step darker where a rule crosses it and the 1 inside it does not: the fill is
    -- a mark and stacks, and the figure is paper and covers (src/sprites.lua).
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()

    -- The gutter first, so everything else prints over it rather than under it:
    -- it is the shadow the fold casts on the paper, not on the counter.
    self.book:drawCrease()
    self.marks:draw(0)

    for i, row in ipairs(rows) do
        self:drawRow(i, row)
    end

    -- The two lines under the counter, on the facing page where there is one: what
    -- to do, and the one fact about what a level here is worth. Both are about the
    -- goods rather than about the transaction, so they belong on the side the
    -- sentences are on.
    local hint = I18n.t(self:hint(at))
    if Font.width(hint) <= lay.w then
        Scribble.printBig(hint, lay.sayCx, lay.hint, 1, Palette.slate, { seed = 61 })
    end
    local note = I18n.t(section.note)
    if Font.width(note) <= lay.w then
        Scribble.printBig(note, lay.sayCx, lay.hint + Font.height + 2, 1,
            Palette.graphite, { seed = 62 })
    end

    Overprint.finish()

    -- The boxes, out past the pass for the library's reason: a box filled in paper
    -- still has every inked pixel of its border paired with the page underneath,
    -- so a border landing on a rule comes out a step darker and the box reads as a
    -- transparency rather than as a thing lying on the page. Out past the pass but
    -- still on the *page* -- this is inside the leaf being drawn, so a box goes
    -- round the fold with the row it is at the end of, which is what it is.
    --
    -- A row with nothing to sell has no box. Which is the whole of how this page
    -- says a row is closed to you: the price beside it is grey, and there is nothing
    -- there to answer.
    local choice = self.choices[at]
    for i, row in ipairs(rows) do
        local box = choice.boxes[i]
        if row.shop.canBuy(row.key) or self.bought == box then
            Scribble.drawBox(box, 1,
                Scribble.boxColor(box, self.bought, self.boughtT), 40 + i * 3, 0)
            Scribble.drawMarks(box.marks, Palette.ink, self.seed, 0)
        end
    end
end

function Canteen:draw(game)
    local lay = self:layout(game)

    -- The leaf, or the two of them, or the one turning between them.
    self.book:draw(game, function(at) self:drawPage(game, at) end)

    -- And then everything that is the book rather than the leaf: the heading, what
    -- is in the purse, the way back and the footer that turns the page. None of it
    -- moves when a page does, which is the whole reason it is drawn out here.
    Scribble.printBig(I18n.t(HEAD), lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    -- Right-aligned by centring the pair on the middle of the room it takes, since
    -- centring is the only thing Purse.draw knows how to do. So it grows leftwards
    -- off the edge it is hung on, which is what an amount in a corner should do.
    local total = self:total()
    Purse.draw(total, lay.purseRight - Purse.width(total) / 2, lay.purse,
        Palette.ink)

    -- The section, between the two arrows that step it, and red because it is the
    -- one thing in the footer that changes. It names the section the book is *open*
    -- at throughout a turn, so it changes on the frame the leaf lands rather than
    -- while it is in the air -- a label that renamed itself halfway through the
    -- gesture would be naming neither page.
    Scribble.printBig(I18n.t(SECTIONS[self.book.at].name), lay.cx,
        lay.arrowY + math.floor((ARROW - Font.height) / 2), 1, Palette.red,
        { seed = 60 })

    self:drawArrow(-1)
    self:drawArrow(1)
    Hud.drawCorner(game, "back", false)
end

-- The one line under the counter, and it is the state of the section showing rather
-- than an instruction printed whatever is true: a page telling you to scribble a box
-- when there is no box on it is a page arguing with itself. Three things it can be
-- saying, in the order they stop being about you -- there is something to buy, you
-- cannot afford any of it, there is none of it left.
function Canteen:hint(at)
    local anyLeft, anyBuyable = false, false
    for _, row in ipairs(counters[at]) do
        if row.shop.priceOf(row.key) then anyLeft = true end
        if row.shop.canBuy(row.key) then anyBuyable = true end
    end

    local section = SECTIONS[at]

    -- A section that can only ever be shut for one reason says that reason, in
    -- place of both of the counter's: a refund does not run out of stock and no
    -- purse is ever too light for one, so there is one thing wrong with it and the
    -- page says it rather than picking the nearer of two lines that are not true.
    if section.shut and not anyBuyable then return section.shut end

    if not anyLeft then return "NOTHING LEFT TO BUY" end
    if not anyBuyable then return "COME BACK WITH MORE COINS" end
    if Input.usingTouch then return section.touch or "SCRIBBLE A BOX TO BUY" end
    -- The keys written out rather than counted, the draft's own line and the
    -- timetable's: English is the key (src/i18n.lua), so a line built out of the
    -- number of rows would be a line with no translation. Which is why it is on the
    -- section (`keys` in `SECTIONS`) -- a section that grows a row grows a figure
    -- there.
    return section.keys
end

return Canteen
