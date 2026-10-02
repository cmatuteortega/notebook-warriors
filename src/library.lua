-- The library: everything the draft can ever hand you, written out.
--
-- Every other screen in this game asks you something. This one does not, and
-- that is the whole of what it is: the draft deals three cards out of a hundred
-- and ninety levels and never says what the other hundred and eighty-seven were, so
-- a run is played against a catalogue you can only learn by being dealt it. The
-- library is the back of the book you are allowed to read before the lesson
-- starts -- what tools exist, what fights for you, what a passive line becomes
-- four levels in -- and it costs the run nothing, because it is off the timetable
-- rather than on the way through it.
--
-- **Nothing here is answered, so nothing here is scribbled.** Every box in the
-- game (src/scribble.lua) is a thing you cannot take back, and there is nothing
-- on this page you could take back: you press a name to read it, you press an
-- arrow to turn to another section, and you press the corner to close it. That is
-- the same rule the timetable's tabs are drawn along -- choosing what to *look*
-- at is not a question -- applied to a screen where looking is all there is. Ink
-- that lands anywhere else is still just ink and still fades off the page, since
-- the page is a page.
--
-- Four things arrange it:
--
-- **The shelf** is every line of the section, an icon and a name apiece, laid out
-- in as many columns as the page will take -- bar the fusions, which are behind
-- the toggle below. It is the index: pressing one turns the page under it over to
-- that entry, and the picked name is the one in red.
--
-- It is written in the order the book gets them, not the order they were drawn:
-- the lines a fresh save already has first, then the rest in the order the ladder
-- opens them (see `shelfOrder`). So the top of every shelf is what a run can
-- actually be dealt today and the bottom is the queue, and the reading goes the
-- same way the collection does.
--
-- **The entry** is the picked line written out in full -- its name at twice the
-- size beside its icon, then one numbered row per level, in order, because a line
-- is *taken* in order and the fourth level of the pencil is only ever reached
-- through the first three. That is the fact the draft cannot tell you: a card
-- shows you the level you are being offered, and this shows you the line it is
-- part of.
--
-- **The shelf and the entry are the two pages of a spread** (src/spread.lua) --
-- the index on the verso and the line it opens on the recto, which is what a
-- reference book has always done with exactly this pair of things. Where there is
-- only one leaf to play with (a phone held upright) they stack, the shelf above
-- and the entry under it, which is where they both were before there was a fold
-- at all.
--
-- **The footer** is `<` the section `>`, at the foot of the page, the studio's
-- roster arrows doing the studio's job (src/studio.lua): two arrows either side
-- of the name of the thing they step. Tools, then what fights for you, then the
-- numbers about you -- which is the order the catalogue itself is written in and
-- the order a run reads them in. A section is a spread, so the arrows turn a
-- leaf, and so does a finger dragged across the page.
--
-- **The toggle** is the word EVOLUTIONS in the bottom left corner, and it is the
-- one thing on this page that changes what the page *is* rather than which part
-- of it you are reading.
--
-- Down -- which is how the screen opens -- the fusions (src/upgrades.lua) are not
-- on the tool shelf at all. That is worth the paragraph, because it is the one
-- thing this screen hides. A fusion is not a line you can be dealt: it is what
-- two finished lines turn into, so twenty-four of them sitting in the middle of the
-- ten tools is twenty-four names a run cannot ask for, listed exactly as flatly as
-- the ten it can -- and there are more fusions now than there are tools to make
-- them out of, so on the shelf they would be most of the page. The shelf is the
-- index of what the draft deals, and that is what it should read as.
--
-- Up, the shelf stops being an index and becomes a pair of picks: press two tools
-- and the block underneath is what those two make of each other, or a line saying
-- they make nothing. Which is the one question the rest of the book cannot answer,
-- because it is not a question about a line at all -- it is a question about two
-- of them, and there is nowhere on a page of single entries to ask it.
--
-- The picks are marked on the *icons*, in the blush a fused tool's own drawing
-- wears everywhere in the game (`Hud.drawIcon`), and not in the red the shelf
-- already spends on where you are reading. Two colours, one meaning each: red is
-- the name under your finger, blush is a tool going into a fusion -- which is
-- what blush already meant on the card that offers one.
--
-- It is lettering rather than a box, and it is pressed the way a name on the
-- shelf is, because that is what it is: the one vocabulary this screen has for a
-- thing you press is a word that goes red once it is the one you picked. And it
-- is only drawn on a shelf that has evolutions on it, since a word offering
-- nothing is worse than no word.
--
-- The page is read from the top down rather than centred, the shelf's columns are
-- cut to the widest name in the whole book and the shelf itself is given the room
-- the fullest shelf needs, so the heading, every name on the shelf and the top of
-- the entry under it are in the same place on all three sections. That is the timetable's
-- rule and it matters more here: this is a screen you read by pressing one name
-- after another, and a list that reflowed under your finger would be a list you had
-- to find your place in again every time.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Hud = require("src.hud")
local Sprites = require("src.sprites")
local Tools = require("src.tools")
local Upgrades = require("src.upgrades")
local Collection = require("src.collection")
local Sfx = require("src.sfx")
local Spread = require("src.spread")
local I18n = require("src.i18n")

local Library = {}

-- The book this screen is read in. One of it rather than one per opening, because
-- there is one of this screen: `Library` is a table and not a class, the way the
-- timetable and the menu are.
Library.book = Spread.new()

-- Two thirds of the catalogue is not in the book on a fresh save
-- (src/collection.lua), and this is the screen that says so. Which is what turns
-- it from a catalogue into a collection: a line the book has not opened is drawn
-- as the hole it is -- its icon as a silhouette, its name in graphite -- and where
-- its levels would have been read there is the one thing it asks for instead.
--
-- The name is deliberately *not* hidden. A shelf of question marks is a wall, and
-- what makes a hole worth filling is knowing the shape of it: the point of the
-- screen is that the whole book is legible from the first run, and the only thing
-- a lock takes away is the reading of what each level does.
--
-- And the count hangs in the top right, at 1:1, level with the corner button --
-- the canteen's purse readout in the canteen's corner, for the canteen's reason.
-- It is furniture rather than page: how much of the book there is is a fact about
-- the book, so it does not move when a shelf is stepped and it is measured off
-- four figures rather than off the two showing.
--
-- It counts **what the screen is showing**, which is the shelves down and the
-- fusions up. One figure that follows the toggle rather than one figure over
-- everything, because the two halves fill at completely different rates and at
-- completely different times: the thirty-six are opened one at a time by quests
-- and the forty-five come in a flood, nine at once, every time the tool shelf
-- grows. Added together they were one number that said nothing about either --
-- and, until the fusions were gated at all (src/collection.lua), a number that
-- read fifty-one of eighty-one to a fresh book whose draft could reach nine.

local HEAD = "LIBRARY"
local HEAD_SCALE = 2
local NAME_SCALE = 2       -- the entry being read, at the heading's own size

local EDGE = 4             -- off the edge of the page
local HEAD_TOP = 10        -- ... and the heading off the top of it, which is more:
                           -- the title is the one thing on the page with nothing
                           -- above it, so it is the one thing that has to be given
                           -- the room to read as the top of a page rather than as a
                           -- line that ran out of page above it.
local ICON = 11            -- every icon in the game is 11x11
local ICON_GAP = 3         -- an icon to the name beside it
local PLATE_GAP = 8        -- one name on the shelf to the next across
local ROW_GAP = 3          -- ... and down
local HEAD_GAP = 6         -- the heading to the shelf
local BLOCK_GAP = 6        -- one block of the page to the next
local LINE_GAP = 2         -- one line of lettering to the next
local LEVEL_GAP = 4        -- a level's number to what it does
local HINT_GAP = 6         -- the hint to the arrows under it
local ARROW = 11           -- the same box the corner button and the studio use
local ARROW_GAP = 6        -- ... and its clearance off the name between them

-- The toggle, and the two things the block under the shelf says when it is up and
-- there is nothing to write out. Held here rather than inline for the reason every
-- string on every screen is: they are what the page reads and they go through the
-- dictionary (src/i18n.lua).
local EVO = "EVOLUTIONS"
local PICK = "PICK TWO TOOLS"
local NOTHING = "NOTHING COMES OF THESE TWO"

local LINE = Font.height + LINE_GAP
local LEVEL_COL = Font.width("0") + LEVEL_GAP

-- The three sections, in catalogue order: what you draw with, what draws itself,
-- and the numbers about you. `kind` is the field on an upgrade row
-- (src/upgrades.lua), so a line lands in a section by being what it is rather
-- than by being listed here twice.
--
-- The endless lines are deliberately not a fourth section. They are what the
-- draft pads itself with once the catalogue has dried up, they are nine variations
-- on lines that already have a section of their own, and a page of them would be
-- a page saying the same nine things the passives page says with no last level on
-- them. What is worth knowing about them is that they exist, and that is the
-- draft's news to break.
local KINDS = {
    { kind = "tool",    name = "TOOLS" },
    { kind = "weapon",  name = "WEAPONS" },
    { kind = "passive", name = "PASSIVES" },
}

--- what is on the shelves ----------------------------------------------------

-- Whether a tool line's tool is still on the strip. A line whose tool has been
-- shelved (`Tools.shelved`, the crayon) is never offered by the draft and never
-- reaches a loadout, so listing it here would be the library promising something
-- the game cannot deal -- which is the one thing a catalogue must not do.
local function toolLive(name)
    for _, tool in ipairs(Tools.list) do
        if tool.name == name then return true end
    end
    return false
end

-- One list per section, built once. The catalogue is the same table for every run
-- the program plays and nothing here reads a run at all, so there is nothing to
-- rebuild when the screen is opened again.
--
-- What *is* rebuilt every frame is which of them are in the book: that is a
-- question about the register (src/records.lua) and the register can change
-- between one opening of this screen and the next -- or, on a run that has just
-- ended, between two frames of it.
local shelves

-- And the lines no shelf carries: the fusions, read out under a pair of picks
-- instead of down a column (`Library:pairing`). One flat list rather than one per
-- section, since what is asked of it is always "do these two make anything" and
-- never "what is on this shelf".
local fusions

-- What order a shelf is written in: the lines in the book from the start, and then
-- the rest in the order the ladder opens them (`Collection.rank`, which is a line's
-- place in src/collection.lua's one list of gates). A free line has no rank at all,
-- which is what puts the whole free block on top -- the shelf is not sorted into
-- open and shut, it is sorted by *when*, and never having been shut is the earliest
-- when there is.
--
-- The catalogue's own order is the tiebreaker, and it has to be there: `table.sort`
-- in LuaJIT is not stable, so two lines that are both free would otherwise swap
-- places between one build and the next for no reason anybody could see.
--
-- **It is sorted once, and it does not resort as the book fills.** Both keys are
-- facts about the catalogue rather than about the register: whether a line has a
-- gate and where that gate sits are the same on run one and run four hundred, so
-- the shelf a player learns the shape of is the shelf they keep. A list ordered by
-- what is *currently* open would be a list that rearranged itself under the finger
-- of the person who just filled a hole in it, which is exactly the thing the
-- top-down layout above is at pains not to do -- and it would do it at the one
-- moment the player has most reason to be looking.
--
-- What it buys is that a shelf answers two questions in the reading order you ask
-- them in. What can I be dealt right now is the block at the top; what is coming
-- and in what order is the block under it, top to bottom. Before this the two were
-- interleaved by catalogue order, which is the order the lines were *written* --
-- so a fresh book's weapons shelf had its four playable lines sitting second,
-- fourth, sixth and eighth in a column of graphite.
--
-- It also groups the derived gates without being told to, since they are appended
-- to the ladder in blocks: the tools shelf comes out as the two the quests hand
-- over, then the scissors, then the seven the timetable does, and the weapons shelf
-- ends on the three that belong to heroes you have not bought. That is a shelf
-- sorted by who is holding it back, one step below being sorted by when.
local function shelfOrder(at)
    return function(a, b)
        local ra, rb = Collection.rank[a.id], Collection.rank[b.id]
        if ra ~= rb then return (ra or 0) < (rb or 0) end
        return at[a.id] < at[b.id]
    end
end

local function build()
    if shelves then return end

    -- Where each line sits in the catalogue, for the sort's tiebreaker.
    local at = {}
    for i, up in ipairs(Upgrades.list) do at[up.id] = i end

    shelves = {}
    fusions = {}
    for i, section in ipairs(KINDS) do
        local list = {}
        for _, up in ipairs(Upgrades.list) do
            if up.kind == section.kind
                and (up.kind ~= "tool" or toolLive(up.tool)) then
                -- Sorted by `fuses` rather than by a list of names written down
                -- here, so a new fusion is behind the toggle by existing --
                -- the same rule the shelves themselves are filled by `kind`
                -- under. Still filtered by `toolLive` on the way past: a fusion
                -- whose tool came off the strip is not a thing the book can
                -- promise either.
                if up.fuses then
                    fusions[#fusions + 1] = up
                else
                    list[#list + 1] = up
                end
            end
        end
        table.sort(list, shelfOrder(at))
        shelves[i] = list
    end

    -- The fusions are left in catalogue order. They are not a shelf -- nothing
    -- reads them as a column and nothing indexes into them but a scan for a pair
    -- (`Library:pairing`) -- and every one of the forty-five is shut on a fresh
    -- book anyway, so there is no free block for an order to put on top.
end

-- A phrase from the collection, put into words. It moved into src/i18n.lua the day
-- the timetable grew holes of its own to explain: the rule it keeps -- translate
-- the key, then fill the slot -- is a rule about translation and belongs beside
-- `I18n.t` rather than on one of the two screens that draws a phrase.
local say = I18n.say

-- How much of what is on the screen is open, counted over the shelves rather than
-- over the collection's own gates: what a collection is is the whole shelf with
-- the holes in it, and a count of the gates alone would read 0/17 to somebody
-- holding two thirds of the game. Counted here rather than in src/collection.lua
-- because it is the shelves that decide what is in the book at all -- a line whose
-- tool has been shelved is not a hole, it is not there.
--
-- The fusions are counted apart from them rather than with them, which is the one
-- thing here that changed when they were gated (src/collection.lua). They are not
-- on a shelf, they are not dealt, they open nine at a time rather than one, and
-- there are more of them than there are lines in the rest of the catalogue -- so
-- added in they were the figure, and the thirty-six the screen is actually a list
-- of could not be read off it at all.
local function tally(list)
    local have, total = 0, 0

    for _, up in ipairs(list) do
        total = total + 1
        if Collection.has(up.id) then have = have + 1 end
    end

    return have, total
end

-- What the corner is showing: the fusions with the toggle up and the shelves with
-- it down, which is the same rule the block under the shelf is written by. A count
-- of something you are not looking at is furniture that has wandered off the page.
function Library:tally()
    if self.evo then return tally(fusions) end

    local have, total = 0, 0
    for _, list in ipairs(shelves) do
        local h, t = tally(list)
        have, total = have + h, total + t
    end
    return have, total
end

-- The room the count keeps: the widest either mode can be, at both halves' widest,
-- so neither a book filling up nor the toggle being pressed ever moves it. There
-- are more fusions than shelved lines today and there is no rule that says there
-- always will be, so it is a max rather than the one that happens to be bigger.
local function tallyWidth()
    local widest = #fusions
    for _, list in ipairs(shelves) do widest = math.max(widest, #list) end

    local shelved = 0
    for _, list in ipairs(shelves) do shelved = shelved + #list end
    widest = math.max(widest, shelved)

    return Font.width(("%d/%d"):format(widest, widest))
end

function Library:enter()
    build()

    self.t = 0
    self.index = 1
    self.back = false
    -- The toggle starts down and the picks start empty every time the screen is
    -- opened. Both are a way of *reading* the book rather than anything about the
    -- book, and a screen that opened in the mode it was last closed in would be a
    -- screen that opened without the ten tools on it for no reason the player
    -- could see.
    self.evo = false
    self.picks = {}
    self.wrapped = nil     -- the width every level's text was last broken to
    self.wrappedLang = nil -- ... and the language it was broken in

    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the tab that opened this screen is not this
    -- screen's to read: it presses nothing and draws nothing until it is lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()
    self.book:rest()

    -- A page starting to move is this screen putting down what was in its hand:
    -- see `leaving`.
    self.book.onTurn = function() self:leaving() end

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other.
    Input.stickEnabled = false
end

--- layout --------------------------------------------------------------------

-- The widest name in the whole catalogue, not in the section showing: the shelf
-- is one grid of one column width, and a grid that resized itself around each
-- section would move every name on the page each time an arrow was pressed.
local function nameWidth()
    local w = 0
    for _, list in ipairs(shelves) do
        for _, up in ipairs(list) do
            w = math.max(w, Font.width(I18n.t(up.name)))
        end
    end
    return w
end

-- And the widest section name, so the two arrows in the footer never move as the
-- word between them changes.
local function sectionWidth()
    local w = 0
    for _, section in ipairs(KINDS) do
        w = math.max(w, Font.width(I18n.t(section.name)))
    end
    return w
end

-- Every level of every line, broken to the width the entry block ended up. Done
-- once per width rather than once per frame -- a window being dragged is the only
-- thing that ever pays for it -- and for the whole book at once, since the shelves
-- are stepped through without anything being reloaded.
--
-- Nothing is measured off the result. The page is laid out from the top down (see
-- `layout`), so how tall an entry comes out is a thing that happens rather than a
-- thing anything else has to know in advance.
function Library:rewrap(width)
    -- Cached on the width *and the language*. Every level in the book is broken
    -- here, so it is not a thing to do every frame -- but the language can be
    -- changed from the settings page, and a book still broken to the English it
    -- was last read in is a book of the wrong words.
    if self.wrapped == width and self.wrappedLang == I18n.lang then return end

    self.wrapped = width
    self.wrappedLang = I18n.lang
    self.lines = {}

    -- Keyed by the line's own id rather than by where it sits on a shelf, because
    -- the block under the shelf is not always reading a shelf: a fusion has no
    -- column and no index, and what it is written out under is a pair of picks.
    local function wrap(up)
        local block = {}
        for level = 1, Upgrades.levelsIn(up) do
            -- Broken from the *translation*: where a line of copy wraps is a
            -- property of the words that go on the page, and the catalogue
            -- holds English (src/i18n.lua). Which is also why this is redone
            -- when the language changes and not only when the width does --
            -- see `Library:rewrap`.
            block[level] = Font.wrap(I18n.t(Upgrades.levelAt(up, level).text),
                width)
        end
        self.lines[up.id] = block
    end

    for _, list in ipairs(shelves) do
        for _, up in ipairs(list) do wrap(up) end
    end
    for _, up in ipairs(fusions) do wrap(up) end
end

-- The page is read from the top down: the heading in the top row, the shelf under
-- it, the entry under that, and the footer pinned to the foot on its own. Whatever
-- is left over is blank page at the bottom, which is what blank page looks like.
--
-- It is deliberately **not** centred, and that is the one layout decision here
-- worth explaining. Everything on this screen is a list of a length the catalogue
-- decides -- ten tools, seven weapons, twelve passives, each with as many levels
-- as it has -- so there is no block to centre that is the same height twice, and a
-- page that recentred itself would move the heading and every name on the shelf
-- each time an arrow was pressed. Read from the top and none of that can happen:
-- the heading and the top of the shelf are in the same place on all three shelves,
-- whatever is on them.
--
-- It also buys the room a centred page was spending. A block centred against the
-- fullest shelf reserves the worst of two shelves that pull opposite ways -- the
-- passives are the fullest list with the shortest entries, the weapons the emptiest
-- with the tallest -- and on a squarish window that reserve was the difference
-- between the last level of a line being on the page and being cut off it.
-- Where the nth name on a shelf sits. The grid is one grid for the whole book --
-- the column width is the widest name anywhere in it and the row count the fullest
-- shelf -- so this depends on nothing but the number, which is what lets a shelf
-- be drawn for a section that is not the one open.
function Library:plateRect(lay, i)
    local col = (i - 1) % lay.cols
    local row = math.floor((i - 1) / lay.cols)
    return {
        x = lay.blockX + col * (lay.plateW + PLATE_GAP),
        y = lay.shelf + row * (ICON + ROW_GAP),
        w = lay.plateW,
        h = ICON,
    }
end

function Library:layout(game)
    self.game = game

    local ins = game.inset
    local left = ins.l + EDGE

    local lay = {}
    lay.cx = math.floor(ins.l + (game.vw - ins.l - ins.r) / 2)
    lay.w = game.vw - ins.l - ins.r - EDGE * 2

    -- The book first: the shelf is laid out on a leaf, and whether there is a
    -- second one is what decides where the entry goes -- beside the shelf or under
    -- it.
    local book = self.book
    book:fit(game, #KINDS)
    local versoX, _, leafW = book:leaf(1)
    local rectoX = book:leaf(2)
    local availW = leafW - EDGE * 2
    lay.two = book:spread()

    -- One plate is an icon and the longest name in the book, and as many go
    -- across as fit. One column is the floor: a phone in portrait gets a list.
    lay.plateW = ICON + ICON_GAP + nameWidth()
    lay.cols = math.max(1,
        math.floor((availW + PLATE_GAP) / (lay.plateW + PLATE_GAP)))
    lay.blockW = lay.cols * lay.plateW + (lay.cols - 1) * PLATE_GAP
    lay.blockX = versoX + EDGE + math.floor((availW - lay.blockW) / 2)

    -- The entry gets the facing leaf where there is one, and the shelf's own width
    -- where there is not -- so on one page the screen has one left edge and one
    -- right edge rather than a block per thing on it, and on two it has a page
    -- each.
    lay.entryW = lay.two and availW or lay.blockW
    lay.entryX = lay.two and rectoX + EDGE or lay.blockX
    self:rewrap(lay.entryW - LEVEL_COL)

    local headH = Font.height * HEAD_SCALE
    lay.nameH = math.max(ICON, Font.height * NAME_SCALE)

    -- The footer, off the bottom edge: the hint, and the arrows under it.
    lay.arrowY = game.vh - ins.b - EDGE - ARROW
    lay.hintY = lay.arrowY - HINT_GAP - Font.height
    lay.sectionW = sectionWidth()

    -- The toggle, in the corner the page ends in and level with the arrows. It is
    -- left-aligned on the page's own left edge rather than struck off the middle
    -- like everything else in the footer, because it is the one thing down there
    -- that is not part of the pair of arrows: what it belongs to is the corner.
    --
    -- Nothing is reserved for it and nothing needs to be. Its widest translation
    -- is eleven letters -- forty-three pixels -- and the left arrow is struck off
    -- the middle of the page with the widest section name beside it, which on the
    -- narrowest page this game is handed (a phone held upright, 180 across) still
    -- leaves a few pixels between the two. On anything wider it is most of the
    -- page.
    lay.evoX = left
    lay.evoY = lay.arrowY + math.floor((ARROW - Font.height) / 2)

    -- The heading sits in the very top row of the page and *shares* it with the
    -- corner button, rather than starting below it the way the timetable's panel
    -- does. It can, because it is centred on the page while the button is out in
    -- the margin: on every page this game is handed there are dozens of pixels
    -- between them. Starting it under the button cost the whole page that height --
    -- the shelf, the entry and all -- which on a tall screen put the title a fifth
    -- of the way down a page it is the top of.
    --
    -- The guard is for the page narrow enough, or a heading long enough, that the
    -- two would actually meet; there the title steps down under the button, since
    -- the button is the one thing here that cannot move.
    -- The count, in the corner button's own box mirrored to the other end of the
    -- same top edge and level with it: the figure is six pixels shallower than the
    -- button, so it is dropped by half that rather than hung off the safe edge.
    -- The canteen's purse readout, in the canteen's corner, and for the canteen's
    -- reason -- what there is of a thing belongs in the furniture, not in the page.
    local bx, by = Hud.cornerBox(game)
    lay.tallyRight = game.vw - ins.r - Hud.CORNER_MARGIN
    lay.tally = by + math.floor((Hud.CORNER_SIZE - Font.height) / 2)

    local headW = Font.width(I18n.t(HEAD)) * HEAD_SCALE
    local buttonRight = bx + Hud.CORNER_SIZE
    local underBoth = math.max(Hud.cornerBottom(game),
        lay.tally + Font.height) + EDGE
    -- Clearing *both* corners now rather than only the button, since the count is
    -- lettering in the other one: the heading shares the top row with them or it
    -- steps below the pair of them, and there is no middle answer where it sits
    -- level with one and under the other.
    lay.head = lay.cx - headW / 2 > buttonRight + EDGE
        and lay.cx + headW / 2 < lay.tallyRight - tallyWidth() - EDGE
        and ins.t + HEAD_TOP
        or underBoth

    -- The shelf still clears both corners whatever the heading did, so a title in
    -- the top row does not drag the first row of names up beside them.
    local y = math.max(underBoth, lay.head + headH + HEAD_GAP)
    lay.shelf = y

    -- The shelf is given the room the *fullest* shelf in the book needs, not the
    -- room the one showing needs, so the entry under it starts in the same place
    -- on all three sections. The catalogue decides how many tools, weapons and
    -- passives there are and they are not the same number, so a shelf measured to
    -- itself moves the entry -- its icon, its name at twice the size and every
    -- level under it -- up and down the page each time an arrow is pressed. This is
    -- the same rule the columns are already cut to the widest name in the book for,
    -- applied down the page instead of across it, and it costs the emptiest shelf a
    -- row or two of blank page: cheap, next to a heading you have to find again.
    lay.rows = 0
    for _, list in ipairs(shelves) do
        lay.rows = math.max(lay.rows, math.ceil(#list / lay.cols))
    end
    -- On a spread the entry starts level with the shelf, on the page beside it,
    -- and the reserve below is spent on nothing -- there is no block under the
    -- shelf to push down. On one leaf it is what it always was: the fullest shelf's
    -- worth of rows, then a gap, then the entry.
    lay.entry = lay.two and y or y + lay.rows * (ICON + ROW_GAP) - ROW_GAP + BLOCK_GAP

    -- Where the entry has to stop. Read from the top there is room for the wordiest
    -- line in the book on every page the game is handed, so this is never reached;
    -- on one that is short enough that it is, the last level goes rather than being
    -- written across the footer.
    lay.entryBottom = lay.hintY - BLOCK_GAP

    -- One rectangle per name on the shelf, which is what a press picks and what
    -- ink is kept off. Only for the section that is open: a name on the page
    -- coming up under a turning leaf is not a name you can press yet, and the
    -- shelf being drawn for it asks `plateRect` directly.
    self.plates = {}
    for i = 1, #shelves[self.book.at] do
        self.plates[i] = self:plateRect(lay, i)
    end

    self.lay = lay
    return lay
end

-- One of the two footer arrows, as a box. `dir` is -1 for the left and 1 for the
-- right, both struck off the middle of the page with the widest section name
-- between them.
function Library:arrowBox(dir)
    local lay = self.lay
    local half = (lay.sectionW + (ARROW + ARROW_GAP) * 2) / 2
    local x = dir < 0 and lay.cx - half or lay.cx + half - ARROW
    return math.floor(x), lay.arrowY
end

-- And the toggle, as a box: the word itself, in the row the arrows are in. The
-- word is five pixels deep and the row is eleven, and the taller box is the one
-- that is wanted -- what is being pressed is the corner of the page, not the
-- lettering in it.
function Library:evoBox()
    local lay = self.lay
    return lay.evoX, lay.arrowY, Font.width(I18n.t(EVO)), ARROW
end

--- update --------------------------------------------------------------------

-- Whether the shelf showing has anything on it that fuses, which is what decides
-- whether the toggle is on the page at all. Asked of the fusions rather than
-- written down as "the first section", so a weapon that fuses one day takes the
-- toggle to the weapons shelf by being what it is.
function Library:evolvable(at)
    local kind = KINDS[at or self.book.at].kind
    for _, up in ipairs(fusions) do
        if up.kind == kind then return true end
    end
    return false
end

-- Thrown or dropped, and the picks go with it either way: a mode left half full
-- of the last pair looked at is a mode you have to clear before you can use it.
function Library:toggleEvo()
    self.evo = not self.evo
    self.picks = {}
    Sfx.play("transition")
end

function Library:picked(i)
    for _, p in ipairs(self.picks) do
        if p == i then return true end
    end
    return false
end

-- Two picks and no more, and the *second* is the one a third press replaces. That
-- is the asymmetry worth having: every fusion in the book today has the compass
-- in it, so what a player does with this screen is hold one tool still and run
-- down the shelf against it -- one press per pair rather than two. Pressing a
-- name already picked takes it back off, which is the only way to move the first.
function Library:pick(i)
    for k, p in ipairs(self.picks) do
        if p == i then
            table.remove(self.picks, k)
            Sfx.play("transition")
            return
        end
    end

    if #self.picks < 2 then
        self.picks[#self.picks + 1] = i
    else
        self.picks[2] = i
    end
    Sfx.play("transition")
end

-- What the two picks make of each other, or nothing at all.
--
-- Matched on `fuses` rather than on `needs` (src/upgrades.lua), and the two are
-- not the same list: what a fusion is *of* is the pair of lines it spends, while
-- what it also asks for is a catalyst it gives back -- and the entry writes that
-- out on its own in the red it asks in, so pairing on it would be asking the
-- player to name the thing the answer is about to tell them.
--
-- Counted over the fusion's own list rather than by comparing two ids both ways
-- round, so a fusion of three lines one day is not answered by two of them.
function Library:pairing()
    if #self.picks < 2 then return nil end

    local list = shelves[self.book.at]
    local a, b = list[self.picks[1]], list[self.picks[2]]
    if not (a and b) or a == b then return nil end

    for _, up in ipairs(fusions) do
        if #up.fuses == 2 then
            local hit = 0
            for _, id in ipairs(up.fuses) do
                if id == a.id or id == b.id then hit = hit + 1 end
            end
            if hit == 2 then return up end
        end
    end
end

-- A section, and then the first thing on it: stepping to a shelf and landing on
-- whatever happened to be the sixth name of the last one would be arriving
-- somewhere with no idea where you were.
--
-- And the toggle goes back down with it. The mode belongs to the shelf it was
-- thrown on -- the picks are indices into that shelf and two of the three
-- sections have nothing to pair -- so turning the page puts it away rather than
-- carrying a pair of picks onto a list they do not point into.
function Library:leaving()
    self.index = 1
    self.evo = false
    self.picks = {}
end

-- An arrow, or a key: the same turn a finger makes, run at its own pace. `leaving`
-- is hung off the book rather than called here, so a page turned by hand puts the
-- shelf down exactly as a page turned by an arrow does.
function Library:step(dir)
    self.book:turn(dir)
end

function Library:select(i)
    if i == self.index then return end
    self.index = i
    Sfx.play("transition")
end

function Library:backAt(x, y)
    local bx, by, bw, bh = Hud.cornerTarget(self.game)
    return x >= bx and x <= bx + bw and y >= by and y <= by + bh
end

-- Which arrow, if either, a point lands on. Padded the way every small target in
-- the game is padded, and by more on a phone.
function Library:arrowAt(x, y)
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

-- The toggle, padded the same way and by the same two numbers: it is a small
-- target in a corner and a thumb is a thumb. Nothing at all on a shelf with no
-- evolutions, so a press in that corner is a press on the page.
function Library:evoAt(x, y)
    if not self.lay or not self:evolvable() then return false end

    local padX, padY = 4, 2
    if Input.usingTouch then padX, padY = 8, 6 end

    local bx, by, bw, bh = self:evoBox()
    return x >= bx - padX and x <= bx + bw + padX
        and y >= by - padY and y <= by + bh + padY
end

function Library:plateAt(x, y)
    for i, plate in ipairs(self.plates or {}) do
        if x >= plate.x and x < plate.x + plate.w
            and y >= plate.y and y < plate.y + plate.h then
            return i
        end
    end
end

-- Ink that misses everything is ink on the page and fades off it. A name, an
-- arrow and the corner button all swallow whatever crosses them rather than being
-- drawn on: a press on any of them was taken as a press rather than as the start
-- of a line, and the timetable's tabs already work this way.
-- Answers whether the stamp became ink, for the pen's swish (src/scribble.lua):
-- a name, an arrow and the corner button all swallow what crosses them, and a
-- pointer dragged across the shelf is laying no line to sound.
-- Furniture: every rectangle on this screen that is pressed rather than drawn on.
-- One question rather than four, because both of the things that ask it want the
-- same answer -- the pen must not draw here, and the book must not take the page
-- here.
function Library:furniture(x, y)
    return self:plateAt(x, y) ~= nil or self:arrowAt(x, y) ~= nil
        or self:backAt(x, y) or self:evoAt(x, y)
end

function Library:mark(x, y)
    -- A finger turning a page is a hand on the paper rather than a nib on it, so
    -- it swallows its stamps the way the shelf and the footer do.
    if self.book:eating() then return false end
    if self:furniture(x, y) then return false end
    self.marks:add(x, y)
    return true
end

-- The press edge, and everything on this screen acts there and then: nothing here
-- is armed, lifted or confirmed, because nothing here decides anything. The
-- corner button gets first refusal for the timetable's reason -- it is the one
-- thing on the page that is not part of what you came to read.
function Library:press(x, y)
    if self.book:eating() then return end

    if self:backAt(x, y) then
        self.back = true
        return
    end

    if self:evoAt(x, y) then
        self:toggleEvo()
        return
    end

    local dir = self:arrowAt(x, y)
    if dir then
        self:step(dir)
        return
    end

    local i = self:plateAt(x, y)
    if i then
        -- Where you are reading moves either way, and with the toggle up the
        -- press also picks: red follows your finger, blush is what you have
        -- handed over. Pressing a picked name takes it back, which `Library:pick`
        -- does on its own -- so a name is picked and unpicked by exactly the same
        -- press, in the same place, and `select` refusing to move for it is why
        -- that reads as one thing rather than two.
        self:select(i)
        if self.evo then self:pick(i) end
    end
end

-- Returns "back" the moment the corner button is pressed, and nothing at all
-- otherwise. There is no other way off this screen: it hands nothing over, so
-- there is nothing for it to answer with.
function Library:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.back then return "back" end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    -- The book first, so that the frame a stroke turns into a turn is a frame the
    -- pen lays nothing and the name it was crossing is not opened.
    self.book:track(dt, down, Input.pointerX, Input.pointerY,
        self:furniture(Input.pointerX, Input.pointerY))

    self.pen:track(dt, down, Input.pointerX, Input.pointerY,
        function(mx, my) return self:mark(mx, my) end,
        function(px, py) self:press(px, py) end)

    if self.back then return "back" end
end

-- Left and right step the section, the way the arrows they stand for do; up and
-- down walk the shelf, which on a keyboard is how you read a list. Backspace is
-- the corner button, exactly as it is on the timetable.
function Library:keypressed(key)
    if key == "backspace" then
        self.back = true
    elseif key == "left" or key == "a" then
        self:step(-1)
    elseif key == "right" or key == "d" then
        self:step(1)
    elseif key == "up" or key == "w" then
        local n = #shelves[self.book.at]
        self:select((self.index - 2) % n + 1)
    elseif key == "down" or key == "s" then
        local n = #shelves[self.book.at]
        self:select(self.index % n + 1)
    elseif key == "e" then
        -- The one key on this screen that is a letter for a word rather than a
        -- direction, because the thing it presses is a word.
        if self:evolvable() then self:toggleEvo() end
    elseif key == "return" or key == "space" then
        -- On a keyboard the walk and the pick are two presses, which they have to
        -- be: arrows that picked as they passed would hand the book a pair nobody
        -- asked for on the way to the one they wanted.
        if self.evo then self:pick(self.index) end
    end
end

--- draw ----------------------------------------------------------------------

-- The index. Every name in the section, and the one you are reading is the one in
-- red -- which is what red means everywhere else in this game's furniture, and
-- all it has to mean here: the entry under the shelf says the same thing at twice
-- the size, so the colour is a pointer into a list rather than the only account
-- of where you are.
-- `at` is the section, and `here` whether it is the one the book is open at: on
-- the page coming up under a turning leaf nothing is picked and nothing is being
-- read, because the press that will do either has not happened yet.
function Library:drawShelf(lay, at, here)
    local list = shelves[at]

    for i, up in ipairs(list) do
        local plate = self:plateRect(lay, i)
        local open = Collection.has(up.id)

        -- A line the book has not opened is its own silhouette in graphite -- the
        -- draft's own grey button (`Hud.drawButton`) and the bomb's fuse, which is
        -- the one trick in the game for drawing a thing that is there without
        -- being there. Graphite for both halves rather than slate, since the whole
        -- of what the row has to say is that it is a hole in a list of names.
        -- Through Hud so a picked tool wears the blush plate a fused one wears
        -- everywhere else in the game (`Hud.drawIcon`): with the toggle up, blush
        -- on a tool means it is going *into* a fusion, which is the same colour
        -- saying the same thing one step earlier. Forced rather than left to the
        -- icon, since nothing on a shelf is a fusion any more -- and forced even
        -- on a line the book has not opened, because which two you picked is not
        -- a thing a lock has any business hiding.
        Hud.drawIcon(up.icon, plate.x + ICON / 2, plate.y + ICON / 2,
            not open and Palette.graphite or nil,
            here and self.evo and self:picked(i) or nil)

        -- Red is still where you are reading, locked or not: what the colour says
        -- on this shelf is which name the entry underneath belongs to, and a
        -- locked line has an entry of its own to read.
        love.graphics.setColor(here and i == self.index and Palette.red
            or (open and Palette.slate or Palette.graphite))
        Font.print(I18n.t(up.name), plate.x + ICON + ICON_GAP,
            plate.y + math.floor((ICON - Font.height) / 2))
    end
end

-- One line, written out in full: its icon and name, then a numbered row per level
-- in the order they are taken.
--
-- The numbers are the point of the block rather than decoration on it. A draft
-- card tells you what one level does; what a line *is* is the shape of all of
-- them, and the only way to read that is to see the fourth level sitting under
-- the three you would have to take to reach it.
--
-- Handed the line rather than reading it off the shelf, because there are two
-- ways to arrive here now: a name pressed on the shelf, and a pair of picks that
-- came out of `Library:pairing`. A fusion is written out by exactly the same
-- block as a tool -- same icon, same name, same numbered levels, same hole if the
-- book has not opened it -- which is the whole reason it can be kept off the
-- shelf at no cost.
function Library:drawLine(lay, up)
    local open = Collection.has(up.id)

    Hud.drawIcon(up.icon, lay.entryX + ICON / 2,
        lay.entry + math.floor(lay.nameH / 2),
        not open and Palette.graphite or nil)

    local nameX = lay.entryX + ICON + ICON_GAP
    local name = I18n.t(up.name)
    Scribble.printBig(name, nameX + Font.width(name) * NAME_SCALE / 2,
        lay.entry + math.floor((lay.nameH - Font.height * NAME_SCALE) / 2),
        NAME_SCALE, open and Palette.ink or Palette.graphite,
        -- No shadow on a locked name: the shadow *is* graphite, so a graphite name
        -- with one is a name drawn twice in one colour a pixel apart, which comes
        -- out as a smudge rather than as a faded word.
        { shadow = open and Palette.graphite or nil,
          wobble = true, t = self.t, seed = 5 })

    local y = lay.entry + lay.nameH + LINE_GAP

    -- The hole, where the levels would have been. Three things are said and they
    -- are three different kinds of thing: why there is nothing to read, in the
    -- graphite everything faded on this screen is drawn in; what the book is asking
    -- for, in the red it writes its demands in; and how far along that demand you
    -- are, in the slate a live figure is drawn in. Nothing else about the line is
    -- shown -- the levels are the reading a lock takes away, and a catalogue that
    -- listed them anyway would be a lock on nothing.
    --
    -- The figure is the one of the three that was somewhere else until recently.
    -- It was the whole of what the homework page had to say that this screen did
    -- not, and a second screen listing the same seventeen holes to print one number
    -- against each of them was the library with the entries taken out. It belongs
    -- under the demand: a hole, its price, and how much of the price you have paid
    -- read as one paragraph, and neither of the last two means much without the
    -- other. The homework page is a list of a different kind of thing now
    -- (src/challenges.lua).
    --
    -- Nothing at all for a gate with no meter -- a lesson tool, a hero's weapon, a
    -- fusion -- and that is the honest answer rather than a gap: a page is sat or
    -- it is not, and there is no such thing as being two thirds of the way through
    -- owning the pencil.
    --
    -- All three are wrapped to the block like a level's own text is, since the
    -- demand naming a lesson is the longest string on this screen and a phone in
    -- portrait is one column wide.
    if not open then
        local head, ask = Collection.why(up.id)

        for i, part in ipairs({
            { text = say(head), color = Palette.graphite },
            { text = say(ask), color = Palette.red },
            { text = Collection.meterOf(up.id), color = Palette.slate },
        }) do
            -- A gate with nothing to ask for says only the first half, which is a
            -- shape no row has today and the safe way for a new one to be wrong.
            if part.text then
                love.graphics.setColor(part.color)
                for _, line in ipairs(Font.wrap(part.text, lay.entryW)) do
                    if y + Font.height > lay.entryBottom then return end
                    Font.print(line, lay.entryX, y)
                    y = y + LINE
                end
                -- A blank line between the head and the demand, so the demand
                -- reads as an answer to the line above it rather than as the rest
                -- of the sentence. None between the demand and the figure, because
                -- there the two *are* one sentence: what is owed, and what has been
                -- paid off it.
                if i == 1 then y = y + LINE_GAP end
            end
        end
        return
    end

    -- What a fusion is made of (`needs` in src/upgrades.lua), above its levels
    -- and in the red the book writes its demands in -- the same red the locked
    -- entry above asks in, because it is the same kind of sentence: this is here
    -- and you cannot have it yet. It has to be said *here* and nowhere else. A
    -- fusion is only ever dealt once its lines are finished, so the draft card is
    -- the one place the player can never find out that it exists -- by the time
    -- the card turns up, knowing would have been the useful part.
    --
    -- It is still all three names when the entry was reached by pairing two of
    -- them, and it should be: what the pair asked was what these two make, and
    -- what this answers is what the run has to finish before it is offered --
    -- which is those two *and* the catalyst nobody would have thought to press.
    --
    -- The names rather than the icons, and wrapped like a level's own text is:
    -- three icons in a row would be a rebus on the one entry in the book that has
    -- something specific to ask for, and a phone in portrait is one column wide.
    if up.needs then
        local names = {}
        for i, id in ipairs(up.needs) do
            names[i] = I18n.t(Upgrades.byId[id].name)
        end

        love.graphics.setColor(Palette.red)
        for _, line in ipairs(Font.wrap(
            I18n.t("FINISH %s FIRST"):format(table.concat(names, " ")),
            lay.entryW)) do
            if y + Font.height > lay.entryBottom then return end
            Font.print(line, lay.entryX, y)
            y = y + LINE
        end
        y = y + LINE_GAP
    end

    for level, wrapped in ipairs(self.lines[up.id]) do
        for j, line in ipairs(wrapped) do
            if y + Font.height > lay.entryBottom then return end

            -- The number against the block's left edge and the text in a column
            -- of its own, so a level that runs to two lines still reads as one
            -- level rather than as two.
            if j == 1 then
                love.graphics.setColor(Palette.slate)
                Font.print(tostring(level), lay.entryX, y)
            end

            love.graphics.setColor(Palette.ink)
            Font.print(line, lay.entryX + LEVEL_COL, y)
            y = y + LINE
        end
    end
end

-- Which line the block under the shelf is written out for: the name you pressed,
-- or -- with the toggle up -- what the two names you pressed make of each other.
--
-- With fewer than two picked, or two that make nothing, the block is a sentence
-- instead. Both are graphite, and neither is red, because neither is a demand:
-- the book is not withholding anything here, it is waiting for a second press or
-- answering with a shrug. The red on this page is spent on where you are reading
-- and on what a locked line wants, and a shrug in it would read as either.
--
-- It says nothing about *why* two tools make nothing, and that is deliberate: the
-- only honest answer is that nobody has drawn that one yet, and a book that
-- explained itself there would be a book making promises about a page that does
-- not exist.
function Library:drawEntry(lay, at, here)
    if here and self.evo then
        local up = self:pairing()
        if up then return self:drawLine(lay, up) end

        love.graphics.setColor(Palette.graphite)
        local y = lay.entry
        for _, line in ipairs(Font.wrap(
            I18n.t(#self.picks < 2 and PICK or NOTHING), lay.entryW)) do
            if y + Font.height > lay.entryBottom then return end
            Font.print(line, lay.entryX, y)
            y = y + LINE
        end
        return
    end

    local up = shelves[at][here and self.index or 1]
    if up then self:drawLine(lay, up) end
end

-- One footer arrow, in the corner button's own recipe: a slate box filled with
-- paper and the chevron in the middle of it. The same glyph both ways round --
-- three columns wide, so its origin is the middle one and the flip is an exact
-- mirror rather than a resample.
function Library:drawArrow(dir)
    local x, y = self:arrowBox(dir)

    love.graphics.setColor(Palette.slate)
    love.graphics.rectangle("fill", x, y, ARROW, ARROW)
    love.graphics.setColor(Palette.paper)
    love.graphics.rectangle("fill", x + 1, y + 1, ARROW - 2, ARROW - 2)

    love.graphics.setColor(1, 1, 1)
    Sprites.icons.chevron:draw(x + ARROW / 2, y + ARROW / 2, dir > 0)
end

function Library:hint()
    if self.evo then
        if Input.usingTouch then return "TAP TWO TOOLS TO PAIR THEM" end
        return "CLICK TWO TOOLS TO PAIR THEM"
    end
    if Input.usingTouch then return "TAP A NAME TO READ IT" end
    return "CLICK A NAME OR USE THE ARROWS"
end

-- One spread: the shelf on the verso and the entry it opens on the recto, with
-- nothing on it that does not turn with it. Called into a canvas rather than onto
-- the screen while a leaf is moving (src/spread.lua), which is why it is a whole
-- overprint pass of its own and why it takes the section rather than reading
-- `self`.
function Library:drawPage(game, at)
    local lay = self.lay
    local here = at == self.book.at

    -- Written on the page rather than laid over it, like every other screen here:
    -- the ruling shows through the lettering, and the ruling is the lesson you
    -- came in from, because the book is still open at it -- you have turned to the
    -- back, not closed it.
    Overprint.beginPage()
    Background.draw(0, 0, game.vw, game.vh)

    Overprint.beginInk()

    -- The gutter first, so everything else prints over it rather than under it: it
    -- is the shadow the fold casts on the paper, not on the shelf.
    self.book:drawCrease()
    self.marks:draw(0)

    self:drawShelf(lay, at, here)
    self:drawEntry(lay, at, here)

    Overprint.finish()
end

function Library:draw(game)
    local lay = self:layout(game)

    -- The leaf, or the two of them, or the one turning between them.
    self.book:draw(game, function(at) self:drawPage(game, at) end)

    -- And then everything that is the book rather than the leaf: the heading, how
    -- much of the catalogue there is, the footer that turns the page, the toggle
    -- and the line saying what to press. None of it moves when a page does, which
    -- is the whole reason it is drawn out here -- and it is the same reason the
    -- arrows were already out here, the timetable's: a box filled in paper still
    -- has every inked pixel of its border paired with the page underneath, so a
    -- border landing on a rule comes out a step darker and the box reads as a
    -- transparency rather than as a thing lying on the page.
    Scribble.printBig(I18n.t(HEAD), lay.cx, lay.head, HEAD_SCALE, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    -- How much of the book there is. Right-aligned by centring it on the middle of
    -- the room it takes, since centring is the only thing `printBig` knows how to
    -- do -- so it grows leftwards off the edge it hangs on, which is what a count
    -- in a corner should do. Red once there is nothing left to find: it is the one
    -- thing on this screen that can be finished, and finished is worth saying.
    local have, total = self:tally()
    local count = ("%d/%d"):format(have, total)
    Scribble.printBig(count, lay.tallyRight - Font.width(count) / 2, lay.tally, 1,
        have >= total and Palette.red or Palette.slate, { seed = 62 })

    -- The section, between the two arrows that step it, and red because it is the
    -- one thing in the footer that changes. It names the section the book is *open*
    -- at throughout a turn, so it changes on the frame the leaf lands rather than
    -- while it is in the air -- a label that renamed itself halfway through the
    -- gesture would be naming neither page.
    Scribble.printBig(I18n.t(KINDS[self.book.at].name), lay.cx,
        lay.arrowY + math.floor((ARROW - Font.height) / 2),
        1, Palette.red, { seed = 60 })

    -- The toggle, in the corner, in the footer's own lettering. Red when it is up
    -- for the reason a name on the shelf is red when it is the one being read --
    -- what red says on this page is "this one" -- and slate rather than graphite
    -- when it is down, because it is a thing you can press and graphite here is
    -- what a faded thing is drawn in.
    --
    -- Centred on the middle of its own word, since centring is the only thing
    -- `printBig` knows how to do, so it grows rightwards off the edge it hangs on.
    if self:evolvable() then
        local word = I18n.t(EVO)
        Scribble.printBig(word, lay.evoX + Font.width(word) / 2, lay.evoY, 1,
            self.evo and Palette.red or Palette.slate, { seed = 63 })
    end

    local hint = I18n.t(self:hint())
    if Font.width(hint) <= lay.w then
        Scribble.printBig(hint, lay.cx, lay.hintY, 1, Palette.graphite, { seed = 61 })
    end

    self:drawArrow(-1)
    self:drawArrow(1)
    Hud.drawCorner(game, "back", false)
end

return Library
