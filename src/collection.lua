-- What of the book has been opened, and what it asks for.
--
-- The catalogue is a hundred and fifty levels down thirty-six lines and the draft
-- lays three cards, so for most of this project the whole of it was reachable on
-- the first run and none of it was ever *arrived at*. The library (src/library.lua)
-- was written to answer half of that -- the catalogue read out loud on a page you
-- are standing still on -- and this is the other half: two thirds of those lines
-- are not in the book yet, and the library is where you find out what there is and
-- what it costs. A catalogue you can read is a list; a catalogue with holes in it
-- is a collection.
--
-- **It is keyed to what the book already remembers and has no file of its own.**
-- That is the whole shape of the feature rather than a saving: src/records.lua
-- keeps one line per lesson and every number on it is a *maximum*, so an unlock
-- read off a record can never be taken away, can never disagree with anything, and
-- costs nothing to keep in step. There is no owned-set to write, no order to
-- replay, and a hand-edited records file is the only way to be wrong about any of
-- it. Nothing here is saved because nothing here is a fact of its own -- every one
-- of them is a fact about a run you already played.
--
-- **One feat, one line.** A quest used to hand over two -- a weapon and a passive
-- together, so that every unlock changed two of the library's shelves at once --
-- and the two were never separable afterwards: a player who wanted the pen was
-- told to survive two minutes and handed a bomb as well, and neither half of that
-- could be moved, priced or retired without moving the other. Seventeen quests
-- with one line apiece say the same thing at the same rate and each of them is a
-- row that can be re-aimed on its own, which is what makes the shelf readable at
-- all: one hole, one price, one thing behind it.
--
-- **The four things a quest may ask for** are the four columns the register can
-- answer, and they are deliberately not one axis with four numbers on it:
--
-- - `time` -- the longest run anywhere in the book. Asks you to last.
-- - `kills` -- the biggest body count on any one page. Asks you to fight, and
--   quietly asks *where*: some pages hand you four kills a second and some ten,
--   so a big number is a page you went and found.
-- - `sat` -- how many lessons have been played far enough in that the boss walked
--   on. Asks you to go round the book rather than to get better at one page of it.
-- - `beat` -- how many lessons have had their boss put down. Asks you to win, and
--   to win in more than one place.
--
-- The ladder alternates between them on purpose. Three time quests in a row would
-- be one quest with three prices, and a run would learn to chase one number and
-- ignore the register's other columns.
--
-- **`played` used to be the third of those and is not a question any more.** It
-- counted lessons opened at all, and it stopped meaning anything the day the
-- timetable itself went behind a ladder: a lesson you have played is a lesson you
-- unlocked by playing the one above it, so PLAY 3 LESSONS was a demand that could
-- not be missed. Being round the book is what the term is for now, and what is
-- asked here instead is how *far into* the pages you got.
--
-- **And only three of the seventeen ask about a boss**, which is a deliberate
-- ceiling rather than a shortage of ideas. The eye is provisional -- one fight
-- standing in for seven, six of which nobody has drawn -- so a ladder leaning on
-- it is a ladder that cannot be tuned until they all exist. `sat` is the half of
-- the same question that does not care what walks on at minute ten, and it carries
-- five quests to `beat`'s three for exactly that reason. When the seven bosses are
-- real the obvious move is to put the *lesson tools* behind beating their own
-- lesson rather than sitting it; today that would be forty-three lines of the
-- eighty-one hanging off six fights that do not exist.
--
-- **What is never held back is what a run is *handed*.** `issue` in src/loadout.lua
-- does not come through here at all, so a lesson still opens holding its tool and a
-- character still opens holding its weapon whatever any of this says. That is the
-- rule everything below is written against, and it is what makes the second half of
-- the ladder possible: a gate on a line somebody is handed is not a lock on having
-- it, it is a lock on **carrying it anywhere else**.
--
-- Which is what the seven lesson tools are. A lesson hands out one tool
-- (`tool` in src/subjects.lua) and no two lessons hand out the same one, so each of
-- them is gated on *its own lesson* being sat all the way through -- ten minutes,
-- `SIT`, which is the boss's own arrival (`Spawner.BOSS_AT`). Until then the pencil
-- is a science tool: you draw with it on that page all you like and the draft will
-- not deal it to you anywhere else, and the library says so rather than pretending
-- the thing does not exist. Sit the lesson out and it is yours everywhere.
--
-- Sat rather than *beaten*, and the two words are kept apart everywhere in this
-- file: **SIT** is being still on the page when the boss walks on and **BEAT** is
-- putting it down. It used to be one word, `PASS`, which meant the first and read
-- as the second.
--
-- Those seven are **derived from the timetable rather than written out**, which is
-- the one thing here to preserve: a lesson gates the tool it issues, so a new
-- lesson gates its own with nothing to keep in step and no way for the two lists to
-- drift apart. It also quietly enforces the rule the README already asks for --
-- two lessons issuing one line is not caught anywhere else, and here it is caught
-- at load, since a line may only be gated once.
--
-- The three tools no lesson issues -- the pen, the gluestick and the scissors --
-- have nowhere to be a local tool of, so they are gated on the ladder like a weapon.
--
-- **And three of the four character weapons are the same bargain again.** The book
-- comes with one hero and the other three are bought at the canteen
-- (src/characters.lua), which is what makes the weapons they carry gateable at all:
-- a lock on a line every run is handed would be a lock on nothing, and a lock on a
-- line only *some* runs are handed is a lock on carrying it as anybody else. So a
-- bought hero's line is his until five minutes have been survived as him, `RIDE`,
-- and then it is in the book for everybody. The base hero's line is the one weapon
-- gated by nothing, and it has to be: it is what a fresh book's first draft has to
-- deal.
--
-- Those three are **derived from the roster** for the reason the seven lesson tools
-- are derived from the timetable: a hero gates the weapon he carries, so a fourth
-- one to buy brings its own gate with it and there is no second list to fall out of
-- step. It catches the same kind of typo on the way in, too -- two heroes carrying
-- one line would be two gates on it, which asserts.
--
-- **And the fusions are behind their own parts.** Forty-five of them, every pair
-- of the ten tools, and until now not one was held back by anything -- so a fresh
-- book's library read fifty-one of eighty-one lines open while the draft could
-- reach six. That was the counter lying rather than the ladder being generous: a
-- fusion has never been dealable without both its tools finished on the strip
-- (`Loadout:ready`), so what was missing was the book *saying* so.
--
-- Derived from `needs` for the reason the lesson tools are derived from the
-- timetable: a new fusion brings its own gate and there is no second list to fall
-- out of step. `needs` and not `fuses`, because a fusion wants a catalyst passive
-- as well as its two tools and a book missing the cartridge is a book that cannot
-- reach the nine fusions built on it. Nothing here recurses -- a fusion is made of
-- tools and passives and never of another fusion -- so `Collection.has` asking
-- `Collection.has` of its parts goes exactly one deep.
--
-- What this does *not* do is change what a run may be dealt, and the one word that
-- keeps it that way is in src/loadout.lua: a fusion is exempt from this file at
-- the draft, because `ready` already asks a strictly stronger question. The one
-- case where the two disagree is the case the exemption is for -- a lesson tool is
-- *handed* to you on its own page long before the book has it, so PENCIL crossed
-- with PEN is buildable on science while the collection still calls the pencil
-- shut. The shelf's answer and the draft's answer are different questions: what
-- could be built at all, and what can be taken now.
--
-- **And the timetable itself is behind this now**, which is the one thing here that
-- is not a line in the catalogue at all. Seven lessons a fresh book could sit in
-- any order was seven doors with the same nothing written on them: the pages are
-- the widest choice in the game and the first run had to make it blind, having
-- never seen a page or held a tool. So a lesson is opened by the lesson *above* it
-- in `Subjects.list` -- the book is a book, and you work down it -- and the bar is
-- a rung higher each time: two minutes on science opens P.E., three minutes on
-- P.E. opens grammar, and so on down to seven on maths for art. A minute a rung
-- rather than one bar for all six because the ladder is also the difficulty curve
-- the game does not otherwise have: the front of the book is a page you are handed
-- and the back of it is a page you are good enough for, and the last rung stops
-- three minutes short of a `SIT` so that opening the deepest page and sitting it
-- out stay two different afternoons.
--
-- It is the same kind of lock as a lesson tool read from the other end. A tool is
-- gated on its own page being sat; a page is gated on the page before it being
-- sat *some of the way*, which is what makes the two of them one ladder rather
-- than two: the run that opens maths is the run that is most of the way to owning
-- the pushpin everywhere.
--
-- **Where a run finds out.** `Loadout:candidates` is the one place this is asked
-- during a run, beside the ban EXPEL leaves and for the same reason: what the draft
-- may reach is one list and one question, not a filter every deal has to remember.
-- A line already under way is offered whatever this says, exactly as it is offered
-- whatever the slots say -- nothing a run is carrying is ever taken off it.
--
-- **And there is a switch in front of both doors while the game is being made.**
-- src/dev.lua overrides the two answers below -- and nothing else, and nothing on
-- disk -- so a book that has opened everything, or nothing, can be stood in front
-- of without a record being written or a register being edited back afterwards.
-- It comes out at launch, and it costs so little to take out for the reason this
-- header keeps giving: there are two doors, and everything asks through them.
--
-- One of the two other doors this was built for is now open, and it went in exactly
-- where the header said it would: the canteen sells a hero and the hero's weapon is
-- a `need` of its own answered in `Collection.met`, with nothing above that line
-- changed. The other -- a homework page that awards one -- goes in the same way.

local Records = require("src.records")
local Upgrades = require("src.upgrades")
local Subjects = require("src.subjects")
local Characters = require("src.characters")
local Spawner = require("src.spawner")
local Dev = require("src.dev")

local Collection = {}

-- The seventeen quests, easiest first. `need` is one column of the register and
-- one number to clear; `line` is the single thing it opens.
--
-- The order is the order they are expected to fall rather than a grouping by
-- column, because it is read top-down by the homework page and a checklist sorted
-- by what it asks instead of by when you get it is a checklist you cannot find
-- your place in. The first lands ninety seconds into the first run -- a collection
-- has to be seen filling before it is worth filling -- and the last is the book
-- finished.
--
-- The two time quests at the bottom of that tier sit **above the term's own
-- ceiling**, which is the one number here worth guarding. Opening every page costs
-- a seven-minute run at the deepest rung (`Collection.rungs`), so a quest priced
-- at seven minutes or less is a quest nobody ever goes and does: it arrives while
-- you are doing something else, and a reward you cannot miss is not a reward. Ten
-- of these used to be exactly that.
Collection.gates = {
    { need = { time = 90 },    line = "pen" },
    { need = { kills = 300 },  line = "gluestick" },
    { need = { time = 180 },   line = "plane" },
    { need = { kills = 1000 }, line = "topmarks" },
    { need = { time = 300 },   line = "tape" },
    { need = { time = 450 },   line = "sun" },
    { need = { kills = 2500 }, line = "blotter" },
    { need = { time = 540 },   line = "cartridge" },
    { need = { sat = 1 },      line = "metronome" },
    { need = { sat = 2 },      line = "beam" },
    { need = { kills = 4000 }, line = "spiral" },
    { need = { sat = 4 },      line = "fixative" },
    { need = { sat = 6 },      line = "birds" },
    { need = { sat = 7 },      line = "laminate" },
    { need = { beat = 1 },     line = "scissors" },
    { need = { beat = 3 },     line = "bandaid" },
    { need = { beat = 7 },     line = "storm" },
}

-- Everything above this line is a quest written out; everything below it is a gate
-- some other table decided. The boundary used to be a number the homework page
-- read off the front of the list, back when that screen was these seventeen rows
-- with a meter against each. It is not read any more and it is not worth keeping
-- as a constant: the shelf reads the whole table, the meters moved onto the shelf
-- with the demands they belong to (`Collection.meterOf`), and the homework page is
-- a list of a different kind of thing now (src/challenges.lua).

Collection.SIT = Spawner.BOSS_AT

-- And the seven the timetable decides: one per lesson, gating the tool that lesson
-- issues on that lesson being sat. Appended rather than written above so there is
-- exactly one list of what is held back, and derived so that the two can never
-- disagree about which tool belongs to which page.
for _, sub in ipairs(Subjects.list) do
    if sub.tool then
        Collection.gates[#Collection.gates + 1] = {
            need = { lesson = sub.key }, line = sub.tool,
        }
    end
end

-- And how long a hero has to be *played* for his weapon to leave his hands. Half a
-- lesson, and half rather than all of one because a page is a thing you sit through
-- while a hero is a thing you play: five minutes in is where how a run opened has
-- stopped being most of what it is, which is the moment the opening is worth handing
-- to somebody else. Struck off the boss's arrival like `SIT`, so a book whose
-- lessons got longer moves both of them.
Collection.RIDE = Spawner.BOSS_AT / 2

-- And the three the roster decides: one per hero the book has to be bought, gating
-- the weapon that hero carries on having lasted `RIDE` as him. Appended for the
-- lesson tools' reason -- one list of what is held back -- and derived for the same
-- one, so the roster and this can never disagree about which weapon belongs to whom.
for _, char in ipairs(Characters.list) do
    if char.price then
        Collection.gates[#Collection.gates + 1] = {
            need = { hero = char.key }, line = char.weapon,
        }
    end
end

-- And the forty-five the catalogue decides: one per fusion, gating it on the book
-- having everything it is made of. Derived off `needs` for the reason the other
-- two derived blocks are -- a new fusion brings its own gate, and there is no
-- second list to keep in step -- and appended last because it is the only one of
-- the four that is answered by asking this file about *other lines*.
--
-- The whole of `needs` and not just the pair in `fuses`: a fusion wants a catalyst
-- passive it does not consume, and a book with both tools and no cartridge cannot
-- reach the nine that are built on one.
for _, up in ipairs(Upgrades.list) do
    if up.needs then
        Collection.gates[#Collection.gates + 1] = {
            need = { made = up.needs }, line = up.id,
            -- The pair, kept beside the parts: `needs` is what has to be in the
            -- book and `fuses` is the two lines the thing is actually *made of*,
            -- which is what the shelf names. Reading it off `needs` by position
            -- would work today and break the first time somebody writes a
            -- catalyst first.
            fuses = up.fuses,
        }
    end
end

-- And how much of a lesson opens the next one. A rung is a tenth of a lesson,
-- struck off the boss's arrival like `SIT` and `RIDE` so a book whose lessons got
-- longer moves all three together, and the rung a lesson sits on is its place in
-- `Subjects.list` -- the second page asks for two of them, the seventh for seven.
--
-- Ten pages is therefore as far as this arithmetic reaches: an eleventh would be
-- asking for longer than a lesson lasts to open a page, which is a ladder with a
-- rung above the ceiling. A book that grew that far wants a smaller rung rather
-- than a special case at the bottom of the column.
Collection.STEP = Spawner.BOSS_AT / 10

-- lesson key -> the lesson above it and what that lesson owes, built once. A
-- lesson with no rung is open, which is the first page and only ever the first
-- page: the book has to open somewhere.
--
-- Derived from the list for the lesson tools' reason and one more of its own --
-- a chain written out is a chain that can be written into a circle, and two
-- lessons each waiting on the other is a book with pages nobody can ever reach.
-- Read off the order, it cannot be: every rung points at a lower index.
Collection.rungs = {}
for i, sub in ipairs(Subjects.list) do
    if i > 1 then
        Collection.rungs[sub.key] = {
            after = Subjects.list[i - 1].key,
            time = i * Collection.STEP,
        }
    end
end

-- id -> the gate holding it, built once. A line with no gate is in the book, so
-- this table is also the whole list of what can be missing from it.
--
-- Asserted against the catalogue on the way in, the way off-palette art is
-- (src/pixelart.lua): a gate naming a line that does not exist locks nothing at
-- all, which is a typo the game would otherwise go on running perfectly with and
-- nobody would find until somebody wondered where the storm had got to.
Collection.gateOf = {}

-- And id -> how far down the ladder that gate is, which is the one thing about a
-- gate that is a fact about the *table* rather than about the row. The library
-- (src/library.lua) shelves its names by it, so that a shelf reads what you have
-- first and then what is coming in the order it is coming, and a free line -- one
-- with no gate at all -- is rank nil and sorts above every ranked one.
--
-- Which is also what makes the order of this table worth caring about: it is the
-- order every shelf in the library is written in, so moving a quest up the list
-- moves it up the shelf. One list says when a thing arrives and where it is
-- shelved, and nothing can disagree with it.
Collection.rank = {}

for i, gate in ipairs(Collection.gates) do
    local id = gate.line
    assert(Upgrades.byId[id], "collection gates an unknown line: " .. id)
    -- A line has one price. Two gates on one line is either a quest written twice
    -- or -- the way it would actually happen -- two lessons issuing the same tool,
    -- which is a thing nothing else in the game notices.
    assert(not Collection.gateOf[id], "collection gates twice: " .. id)
    Collection.gateOf[id] = gate
    Collection.rank[id] = i
end

-- The register's columns, held on to between the many times a frame this is
-- asked: the library draws thirty-six names and asks about every one of them, and
-- `Records.stamp` is what says the held answer is still the answer. Nothing here
-- is expensive -- it is seven lessons and a handful of maxima -- but the shelf
-- asks it a hundred times a frame and none of those hundred can have changed
-- anything.
local best, bestStamp

local function register()
    if bestStamp ~= Records.stamp then
        best, bestStamp = Records.best(), Records.stamp
        -- And the one count the register cannot make on its own, since what
        -- counts as sitting a lesson out is this file's number and not that one's
        -- (`Records.sat`). Folded into the same table and cached on the same
        -- stamp, so `met` has one place to look and one thing to invalidate.
        best.sat = Records.sat(Collection.SIT)
    end
    return best
end

-- Whether a quest has been done. One comparison per column it names, so a gate
-- asking for two things at once would work without anything being told -- none
-- does today, and one that did would want a sentence of its own on the shelf
-- rather than the one line `Collection.why` writes.
function Collection.met(gate)
    local need = gate.need

    -- A lesson sat out is the one thing here asked of *one* page rather than of
    -- the best of them, so it is read straight off that page's record rather than
    -- out of `Records.best` -- nine minutes on every lesson in the book is not ten
    -- minutes on any of them.
    if need.lesson then
        return Records.get(need.lesson).time >= Collection.SIT
    end

    -- And a hero proved is the other thing asked of one row of a register rather
    -- than of the best of them -- a different register, kept per hero rather than
    -- per page (src/characters.lua). Per hero and not per page on purpose: what is
    -- being asked is whether you have played *him*, and where you did it is the
    -- timetable's question rather than this one.
    if need.hero then
        return Characters.best(need.hero) >= Collection.RIDE
    end

    -- And a fusion is the one gate asked of the *book* rather than of the
    -- register: what it wants is other lines, so it asks the door the same way
    -- every screen does. One deep and never further -- nothing a fusion is made of
    -- is itself a fusion -- so this cannot wind up on itself.
    if need.made then
        for _, id in ipairs(need.made) do
            if not Collection.has(id) then return false end
        end
        return true
    end

    local best = register()

    for what, want in pairs(need) do
        if (best[what] or 0) < want then return false end
    end
    return true
end

-- The one door. Everything that wants to know whether a line is in the book asks
-- here -- the draft's pool, the library's shelf -- and nothing anywhere reads
-- `gates` itself.
--
-- Which is what makes the dev switch (src/dev.lua) one call: a book that has
-- opened everything, or nothing, is this answer overridden in the one place it is
-- ever given. A line with no gate is in the book whatever that switch says --
-- there has to be something for a fresh book to deal.
function Collection.has(id)
    local gate = Collection.gateOf[id]
    if gate == nil then return true end
    return Dev.opened(Collection.met(gate))
end

-- The other door, and the only thing asked of this file that is not a line in the
-- catalogue: whether the book will open at a page at all. The timetable asks it
-- once per tab and `Game` asks it of the page it is about to stand a run on.
--
-- Read straight off the one lesson above rather than through `Records.best`, for
-- the reason a `lesson` gate is: what is owed is two minutes on *science*, and two
-- minutes on the whole rest of the book is not that.
function Collection.lessonOpen(key)
    local rung = Collection.rungs[key]
    if rung == nil then return true end

    -- A page you have already written on stays open, which is this file's own
    -- promise kept across a version rather than a rule of the ladder: an unlock
    -- read off a maximum can never be taken away, and a book that had been round
    -- the timetable before there was a term would otherwise wake up with its best
    -- lesson shut. A book that started life with the ladder can never reach this
    -- clause -- the only way to have a record on a page is to have opened it.
    --
    -- Both halves of that go through the dev switch together (src/dev.lua): a
    -- timetable shut down to its first page is no use if the pages you have
    -- already written on stay open, since those are exactly the ones a book worth
    -- testing on has.
    return Dev.opened(Records.played(key)
        or Records.get(rung.after).time >= rung.time)
end

-- What a locked line has to say for itself: two phrases, or nothing at all for a
-- line that is in the book. The first says why there is nothing to read and the
-- second says what to go and do about it, which are two different sentences and
-- want to be two: a hole and a price.
--
-- **A phrase is a key and what goes in its slots, never a finished string.**
-- English is the key (src/i18n.lua), so a line built here and looked up later is a
-- line looked up under words no dictionary has -- `BEAT 3 LESSONS` is not a key,
-- `BEAT %d LESSONS` is. So the slots are filled *after* the translation, where it
-- is drawn, and a string in a slot is itself a key: a number is a number in every
-- language and a lesson's name is not.
--
-- Two slots rather than one because a fusion names both the things it is made of,
-- and naming one of them would be the shelf answering half a question.
local function phrase(key, a, b)
    return { key = key, a = a, b = b }
end

-- A clock rather than a count of minutes, which is what the time quests used to
-- say. Every bar on the ladder used to be a whole number of minutes and is not any
-- more: the first is ninety seconds, because a collection has to be seen filling
-- inside the first run and two minutes is already the term's first rung. SURVIVE 1
-- MINUTES is what rounding that down reads as.
--
-- It goes into the slot as a string and comes back out of `I18n.t` unchanged,
-- which is that function's documented answer for anything it has no translation
-- for -- and a clock has none in any language.
local function clock(seconds)
    return ("%d:%02d"):format(math.floor(seconds / 60), math.floor(seconds % 60))
end

local function minutes(seconds)
    return math.floor(seconds / 60)
end

-- One of three sentences depending on how many pages are wanted, because a
-- checklist is read as English before it is read as arithmetic: BEAT 1 LESSONS is
-- a demand written by a machine, and BEAT 7 LESSONS is the book finished said in
-- the flattest way available. The middle one is the only one that wants a number
-- in it.
local function pages(one, some, all, n)
    if n <= 1 then return phrase(one) end
    if n >= #Subjects.list then return phrase(all) end
    return phrase(some, n)
end

function Collection.why(id)
    local gate = Collection.gateOf[id]
    if not gate then return nil end

    local need = gate.need

    -- A lesson tool is the one hole that is not a hole: the thing is in the book,
    -- it is just in *one page* of it. Saying NOT IN THE BOOK YET over a tool the
    -- player drew with this morning would be the catalogue lying, which is the one
    -- thing a catalogue may not do -- so this pair names the page instead, and the
    -- demand under it says "there" rather than the lesson's name twice over.
    if need.lesson then
        return phrase("ONLY IN %s", Subjects.get(need.lesson).name),
            phrase("SURVIVE %d MINUTES THERE", minutes(Collection.SIT))
    end

    -- A character's weapon is that same hole with one more state in front of it: a
    -- hero nobody has bought cannot be played at all, so what is owed is the counter
    -- rather than the clock. One line, two prices, and the shelf prints whichever of
    -- them is still outstanding.
    if need.hero then
        local char = Characters.get(need.hero)
        if not Characters.owns(need.hero) then
            return phrase("ONLY FOR %s", char.name),
                phrase("BUY THAT HERO IN THE CANTEEN")
        end
        return phrase("ONLY FOR %s", char.name),
            phrase("SURVIVE %d MINUTES AS THAT HERO", minutes(Collection.RIDE))
    end

    -- And a fusion is the third hole that is not one. The thing is not missing,
    -- it is *unmade* -- so the head says what it is made of rather than that it is
    -- absent, which is also the only interesting thing there is to say about a
    -- fusion, and the demand names the first part still outstanding rather than
    -- listing all three. One step at a time is what a demand is for; the pair the
    -- head already named is the rest of the answer.
    if need.made then
        local a, b = Upgrades.byId[gate.fuses[1]], Upgrades.byId[gate.fuses[2]]
        local first
        for _, part in ipairs(need.made) do
            if not Collection.has(part) then
                first = Upgrades.byId[part]
                break
            end
        end
        return phrase("MADE OF %s AND %s", a.name, b.name),
            first and phrase("OPEN %s FIRST", first.name) or nil
    end

    local shut = phrase("NOT IN THE BOOK YET")

    if need.time then
        return shut, phrase("LAST %s IN ONE RUN", clock(need.time))
    elseif need.kills then
        return shut, phrase("%d KILLS ON ONE PAGE", need.kills)
    elseif need.sat then
        return shut, pages("SIT A LESSON TO THE END",
            "SIT %d LESSONS TO THE END", "SIT EVERY LESSON TO THE END", need.sat)
    elseif need.beat then
        return shut, pages("BEAT A LESSON", "BEAT %d LESSONS",
            "BEAT EVERY LESSON", need.beat)
    end

    return shut
end

-- And how far along one of the seventeen is, for the shelf that reads them out
-- (src/library.lua): where the register stands against what the quest wants, and
-- how to write it -- `"clock"` for a stretch of time and `"count"` for everything
-- else. Nothing for a quest already done, and nothing for the three derived
-- ladders, which have no meter to show: a page is sat or it is not.
--
-- This used to be the whole of what a second screen had to say. It reads better
-- where the demand is: a hole, its price, and how much of the price you have paid
-- are one paragraph, and the middle of those three means very little without the
-- last.
function Collection.progress(gate)
    local need = gate.need
    local best = register()

    if need.time then return best.time, need.time, "clock" end
    if need.kills then return best.kills, need.kills, "count" end
    if need.sat then return best.sat, need.sat, "count" end
    if need.beat then return best.beat, need.beat, "count" end
end

local function meterText(have, want, how)
    if how == "clock" then
        return ("%s/%s"):format(clock(math.min(have, want)), clock(want))
    end
    return ("%d/%d"):format(math.min(have, want), want)
end

-- The meter written out, or nothing for a quest already done and nothing for the
-- three derived ladders, which have none to show: a page is sat or it is not.
-- Here rather than on the shelf for the reason every other string in this file is
-- here -- a clock is formatted one way in the whole book, and the screen that
-- draws this one has no business owning the second copy of that.
function Collection.meter(gate)
    if Collection.met(gate) then return nil end

    local have, want, how = Collection.progress(gate)
    if not have then return nil end
    return meterText(have, want, how)
end

-- The same thing asked by line rather than by gate, for the screen that has a name
-- in its hand and no gate (src/library.lua). The shelf is where a hole is read out
-- now, so it is where the meter hangs: what the entry costs is the demand in red,
-- and how close you are to it is the figure under that.
function Collection.meterOf(id)
    local gate = Collection.gateOf[id]
    return gate and Collection.meter(gate) or nil
end

-- And the widest that meter can ever read, which is what a column of them is cut
-- to. Measured off the demand rather than off where the register happens to stand,
-- because a column sized to today's figures is a column that moves the first time
-- one of them grows a digit -- and this is a list you read by running down it.
function Collection.meterRoom(gate)
    local _, want, how = Collection.progress(gate)
    if not want then return nil end
    return meterText(want, want, how)
end

-- And what a shut page has to say, in the same two parts a hole in the catalogue
-- says it in: why there is nothing here, and what to go and do about it.
--
-- The pair is the lesson tool's pair read from the other end, and it is written in
-- the same two phrases on purpose -- a page you cannot open yet and a tool you
-- cannot carry yet are the same fact about the same lesson, so the book says them
-- the same way. `SURVIVE %d MINUTES THERE` is the tool's own second line, word for
-- word: the head names the page and the demand says "there" rather than naming it
-- twice, which is what lets one dictionary entry serve both.
function Collection.lessonWhy(key)
    local rung = Collection.rungs[key]
    if not rung then return nil end

    return phrase("ONLY AFTER %s", Subjects.get(rung.after).name),
        phrase("SURVIVE %d MINUTES THERE", minutes(rung.time))
end

return Collection
