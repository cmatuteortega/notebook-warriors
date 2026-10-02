-- The homework: what the book asks you to go and do.
--
-- This used to be the collection's seventeen quests read out as a checklist, and
-- that was the same page twice. A quest is a **hole in the catalogue** -- it has a
-- shape, a price and a thing behind it -- and the library is the screen built to
-- show holes: an entry with its levels taken out, its name in graphite and its
-- demand in red. The one thing the library could not say was how far along you
-- were, so the homework page existed to say 3966/4000 and nothing else. That
-- meter now hangs under the demand where the demand is (src/library.lua), the
-- quests are read in the one place they were always about, and this page is free
-- to be the thing the book did not have.
--
-- Which is a list of **things you have done**, rather than of things you have
-- opened. The difference is the whole design:
--
-- - A quest is answered by your *best* run. It asks for four thousand kills on
--   one page or nine minutes in one sitting, and a book that only remembers its
--   best page can only ever ask you to have a better one.
-- - A challenge is answered by *every* run. FIFTY THOUSAND BLOBS is four hundred
--   afternoons and no single one of them; COMPLETE EVERY CLASS AT MASTERS is
--   seven wins nobody had in one evening. Neither is a number a maximum can
--   reach, which is why src/tally.lua exists at all.
--
-- **Nothing here unlocks anything, and that is deliberate.** Every reward in this
-- game is already a door -- a line in the catalogue, a page on the timetable, a
-- hero at the counter -- and each of those has a screen whose whole job is to say
-- what is behind it. A challenge that handed one over would be a second ladder
-- pointing at the same doors, and the first thing it would cost is the library's
-- promise that a shelf is the whole of what there is to open. So a challenge pays
-- in the only currency a checklist has: the box goes red. It is the part of the
-- book that is about the player rather than about the game.
--
-- **A row is a name, a ladder and a meter.** Three tiers is the usual shape --
-- five hundred, five thousand, fifty thousand -- and the row shows the lowest one
-- still standing, with a pip filled in for each that has fallen. One row, one
-- subject, however many rungs: the alternative is three rows saying BLOBS with
-- different numbers on them, which is a list you cannot run your eye down.
--
-- A row with one rung is an ordinary row with a short ladder (the four courses,
-- the four collections), and it needs no special case anywhere: what makes a row
-- long is how many numbers are in `want`.
--
-- **Four sections, stepped by the library's footer arrows**, because this list is
-- going to keep growing and a page is a page:
--
-- - **BESTIARY** -- one body count per row of `Enemy.types`. Per monster and not
--   one number over all of them, because a single ALL KILLS challenge is one
--   demand with ten prices and a run would learn to farm whichever page pays
--   fastest. Ten rows that each say something about a different part of the
--   horde say ten different things.
-- - **TERM** -- the boss count, the hours, and one row per rung of the ladder
--   (src/course.lua) asking for the whole timetable at that class or harder.
-- - **COLLECTION** -- the catalogue read as four sets rather than as eighty-one
--   lines: the tools, the weapons, the passives, and the drawings that are in
--   your own hand rather than the book's.
-- - **EVOLUTIONS** -- one row per tool, asking for every fusion built on it. The
--   library's own word for them, on the library's own terms: forty-five fusions
--   as forty-five rows would be four pages of homework, and ten rows of nine is
--   the same fact said in the order you actually fill it.
--
-- **Everything on all four is derived.** A new monster, a new lesson, a new rung
-- of the course ladder, a new tool, a new fusion and a new drawing board each
-- bring their own row and there is no list here to keep in step -- which is the
-- rule the whole extending section of CLAUDE.md is written along, and it matters
-- more here than anywhere: a homework list that fell out of step with the game
-- would be the book asking for something that does not exist.
--
-- **What it costs to add one that is not derived** is a row in the section it
-- belongs to: a `name`, a `want` ladder, a `have` that reads some register, and an
-- `ask` written as a phrase rather than a string (see below). Nothing else in the
-- game has to be told.

local Enemy = require("src.enemy")
local Subjects = require("src.subjects")
local Course = require("src.course")
local Upgrades = require("src.upgrades")
local Collection = require("src.collection")
local Records = require("src.records")
local Tally = require("src.tally")
local Design = require("src.design")

local Challenges = {}

--- how a demand is written ----------------------------------------------------

-- A phrase is a key and what goes in its slots, never a finished string --
-- src/collection.lua's rule, kept here for src/collection.lua's reason: English is
-- the key (src/i18n.lua), so a demand built here and looked up later is a demand
-- looked up under words no dictionary has. `KILL 5000 OF THEM` is not a key,
-- `KILL %d OF THEM` is. The slot is filled after the translation, where it is
-- drawn (`I18n.say`).
local function phrase(key, a, b)
    return { key = key, a = a, b = b }
end

-- A stretch of time, written the way a stretch of time is read rather than as a
-- number of anything. Under an hour it is the clock every other screen in this
-- game writes (`9:00`); over one it grows an hours column and keeps going, so
-- fifty hours is `50:00:00` rather than three thousand minutes.
--
-- It goes into a slot as a string and comes back out of `I18n.t` unchanged, which
-- is that function's documented answer for anything it has no entry for -- and a
-- clock face has none in any language.
local function span(seconds)
    seconds = math.floor(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor(seconds % 3600 / 60)
    local s = seconds % 60

    if h > 0 then return ("%d:%02d:%02d"):format(h, m, s) end
    return ("%d:%02d"):format(m, s)
end

--- the bestiary ---------------------------------------------------------------

-- What a monster worth one experience point owes, and every other row on the
-- shelf is this divided by what one of *it* is worth.
--
-- Three numbers rather than one, because a challenge nobody can see moving is a
-- challenge nobody starts: five hundred is an afternoon, five thousand is the
-- month you spent learning the game, and fifty thousand is the one you will still
-- be walking towards when everything else on this page is red.
local KILL_LADDER = { 500, 5000, 50000 }

-- Rounded to one figure, so every rung on every row of the bestiary is a number
-- you can hold in your head: two hundred skulls rather than a hundred and
-- sixty-seven. The rounding is what makes dividing the ladder legible at all --
-- without it the shelf would read as arithmetic somebody did rather than as a
-- demand somebody wrote.
local function roundish(n)
    local place = 10 ^ math.max(0, math.floor(math.log(n) / math.log(10)))
    return math.max(place, math.floor(n / place + 0.5) * place)
end

-- Divided by what the thing is worth (`xp` in src/enemy.lua), which is the one
-- number on a monster's row that already says how much of an event it is. So a
-- grin -- eight points, and the slowest thing in the game -- asks for sixty
-- rather than for five hundred, and the ladder says the same *sentence* on every
-- row instead of the same number: go and kill a great many of these.
--
-- Read off the bestiary rather than written out, so a new monster arrives with
-- its homework already priced.
local function killLadder(def)
    local want = {}
    for i, n in ipairs(KILL_LADDER) do
        want[i] = roundish(n / math.max(1, def.xp or 1))
    end
    return want
end

-- The horde in the order it gets harder to kill, which is the one order this
-- table can be read in that means something and is not a second list: `hp`
-- ascending, with the row's own key breaking a tie so that two monsters of the
-- same toughness do not swap places between one build and the next (`table.sort`
-- in LuaJIT is not stable -- the library's shelves are sorted with the same
-- guard).
--
-- The boss is not on it. It has a row of its own in TERM, where what is counted
-- is a fight rather than a body, and a book that listed it here would be asking
-- for fifty thousand of the thing the whole game is built to make rare.
local function bestiary()
    local kinds = {}
    for kind, def in pairs(Enemy.types) do
        if not def.boss and def.name then kinds[#kinds + 1] = kind end
    end
    table.sort(kinds, function(a, b)
        local ha, hb = Enemy.types[a].hp, Enemy.types[b].hp
        if ha ~= hb then return ha < hb end
        return a < b
    end)

    local rows = {}
    for _, kind in ipairs(kinds) do
        local def = Enemy.types[kind]
        rows[#rows + 1] = {
            name = phrase(def.name),
            want = killLadder(def),
            have = function() return Tally.killsOf(kind) end,
            ask = function(want) return phrase("KILL %d OF THEM", want) end,
        }
    end
    return rows
end

--- the term -------------------------------------------------------------------

-- How many bosses, ever. Five is the week you learned to win, fifty is the season,
-- five hundred is the shelf nobody clears by accident -- and every one of them is
-- ten minutes of play at the least, which is what makes this the slowest three
-- numbers on the page and the reason there is only one row of them.
local BOSS_LADDER = { 5, 50, 500 }

-- And how long the book has been open. Five minutes is the first run, five hours
-- is knowing the game, and fifty is the one that is not really a challenge at all
-- -- it is the book noticing. The top of it is fifty rather than the hundred and
-- twenty hours a nice joke would have asked for, for one flat reason: the meter
-- beside it is `49:12:07/50:00:00` and a page has edges.
local TIME_LADDER = { 5 * 60, 5 * 3600, 50 * 3600 }

local function term()
    local rows = {
        {
            name = phrase("BOSSES"),
            want = BOSS_LADDER,
            have = function() return Tally.bosses end,
            ask = function(want) return phrase("BEAT %d OF THEM", want) end,
        },
        {
            name = phrase("TIME PLAYED"),
            want = TIME_LADDER,
            how = "span",
            have = function() return Tally.time end,
            ask = function(want) return phrase("PLAY %s", span(want)) end,
        },
    }

    -- And one per rung of the ladder, asking for the whole timetable at that class
    -- or harder (`Records.beatAt`). Derived from src/course.lua for the reason
    -- everything on this page is derived: a fifth course brings its own row.
    --
    -- The rungs are separate rows rather than one row with four numbers on it,
    -- and that is the one place the ladder shape is deliberately refused. A
    -- three-tier row asks for *more of the same thing*; these four ask for the
    -- same amount of four different things, and beating the book at a doctorate
    -- is not five hundred times beating it at high school.
    for _, course in ipairs(Course.list) do
        rows[#rows + 1] = {
            name = phrase(course.name),
            want = { #Subjects.list },
            have = function() return Records.beatAt(course.index) end,
            ask = function() return phrase("BEAT EVERY LESSON") end,
        }
    end

    return rows
end

--- the catalogue --------------------------------------------------------------

-- How many of a list of catalogue lines the book has opened. The collection's one
-- door (`Collection.has`) asked of each, so a set is open exactly when every line
-- in it is -- there is no second opinion here about what being in the book means.
local function opened(ids)
    local n = 0
    for _, id in ipairs(ids) do
        if Collection.has(id) then n = n + 1 end
    end
    return n
end

-- Every line of a kind, as a list of ids. Fusions are kept apart from the tools
-- they are made of for the library's reason: they are not lines the draft can
-- deal, there are more of them than there is catalogue, and they open nine at a
-- time rather than one -- so counting them in with the ten tools would be one
-- figure that said nothing about either half of it.
local function linesOf(kind, fused)
    local ids = {}
    for _, up in ipairs(Upgrades.list) do
        if up.kind == kind and (up.fuses ~= nil) == fused then
            ids[#ids + 1] = up.id
        end
    end
    return ids
end

-- Every `name` on this page is a phrase rather than a string, including the ones
-- that are a single word: what draws them is `I18n.say` either way, so a row with
-- a slot in its name (the fusions) and a row without one are the same thing to
-- the screen and there is no second way of writing a name for it to know about.
local function setRow(name, ids, ask)
    return {
        name = type(name) == "table" and name or phrase(name),
        want = { #ids },
        have = function() return opened(ids) end,
        ask = function() return phrase(ask or "OPEN EVERY ONE") end,
    }
end

local function collection()
    return {
        setRow("TOOLS", linesOf("tool", false)),
        setRow("WEAPONS", linesOf("weapon", false)),
        setRow("PASSIVES", linesOf("passive", false)),
        -- The one row on this page that is not about the catalogue at all. What it
        -- asks for is that nothing in the book is in the book's own handwriting --
        -- every board drawn on, heroes included (`Design.boards`) -- which is the
        -- only challenge here you can finish without playing.
        {
            name = phrase("DRAWINGS"),
            want = { #Design.boards() },
            have = Design.drawn,
            ask = function() return phrase("DRAW EVERY ONE YOURSELF") end,
        },
    }
end

-- One row per tool, asking for every fusion built on it. Read off `fuses` -- the
-- pair a fusion is actually *made of* rather than `needs`, which also names the
-- catalyst passive it wants -- so the pencil's row is the nine fusions with a
-- pencil in them and nothing else.
--
-- Derived both ways round: a new tool brings a row, and a new fusion lands on the
-- rows of the two tools it is made of. Nothing here knows there are forty-five.
local function evolutions()
    local rows = {}
    for _, up in ipairs(Upgrades.list) do
        if up.kind == "tool" and not up.fuses then
            local ids = {}
            for _, fusion in ipairs(Upgrades.list) do
                if fusion.fuses
                    and (fusion.fuses[1] == up.id or fusion.fuses[2] == up.id) then
                    ids[#ids + 1] = fusion.id
                end
            end
            -- Named by the tool alone rather than by PENCIL FUSIONS, because the
            -- section under the arrows already says EVOLUTIONS and a list does not
            -- need to repeat its own heading ten times -- the library's shelves
            -- are read the same way round. It is also what keeps this page on a
            -- phone held upright: the name column is cut to the widest name in the
            -- book, in both languages, and FUSIONES DE GLUESTICK was that name by
            -- half a column.
            if #ids > 0 then
                rows[#rows + 1] = setRow(up.name, ids)
            end
        end
    end
    return rows
end

--- the list -------------------------------------------------------------------

-- Built once, on the first ask: every one of the four is read off a catalogue that
-- is the same table for every run the program plays. What is *not* built once is
-- how far along any of them is -- that is a question about the registers, and the
-- registers change between one opening of this page and the next.
local sections

function Challenges.sections()
    if not sections then
        sections = {
            { name = "BESTIARY", rows = bestiary() },
            { name = "TERM", rows = term() },
            { name = "COLLECTION", rows = collection() },
            { name = "EVOLUTIONS", rows = evolutions() },
        }
    end
    return sections
end

--- where you are on one -------------------------------------------------------

-- What every row on the page currently reads, held between the many times a frame
-- it is asked: the list draws thirty-odd rows and asks each of them twice (once
-- for the demand, once for the meter), and none of those asks can have changed
-- anything. The same trick the collection holds the register with, and on the same
-- terms -- the work is nothing, and doing nothing repeatedly is still nothing
-- being done repeatedly.
--
-- Invalidated off the two registers' own stamps, plus a hand refresh for the one
-- thing neither of them counts: a hero bought at the counter opens the weapon he
-- carries, and the purse is not a register with a stamp on it. The page calls
-- `Challenges.refresh` on the way in, which is the only moment that can have
-- happened.
local seen, stamp = {}, nil

function Challenges.refresh()
    seen, stamp = {}, nil
end

function Challenges.have(row)
    local now = Records.stamp .. ":" .. Tally.stamp
    if stamp ~= now then seen, stamp = {}, now end

    local n = seen[row]
    if n == nil then
        n = row.have()
        seen[row] = n
    end
    return n
end

-- Which rung is still standing, or nil once none is. The first unmet one rather
-- than the highest met, because what a row shows is what it is *asking for* --
-- a finished rung has nothing left to say.
function Challenges.tier(row)
    local have = Challenges.have(row)
    for i, want in ipairs(row.want) do
        if have < want then return i, want end
    end
    return nil
end

-- How many rungs have fallen, which is what the pips beside the name show and
-- what the count in the corner adds up.
function Challenges.done(row)
    local i = Challenges.tier(row)
    return i and i - 1 or #row.want
end

function Challenges.met(row)
    return Challenges.tier(row) == nil
end

-- What the row is asking for, or nothing at all once it is finished. A phrase
-- rather than a string, for `I18n.say` to put into words at the draw.
function Challenges.ask(row)
    local _, want = Challenges.tier(row)
    return want and row.ask(want) or nil
end

local function meterText(have, want, how)
    if how == "span" then
        return ("%s/%s"):format(span(math.min(have, want)), span(want))
    end
    return ("%d/%d"):format(math.min(have, want), want)
end

-- How close the rung still standing is, or nothing for a row with none. Here
-- rather than on the page for the reason every other string in this file is here:
-- a clock is formatted one way in the whole book.
function Challenges.meter(row)
    local _, want = Challenges.tier(row)
    if not want then return nil end
    return meterText(Challenges.have(row), want, row.how)
end

-- And the widest that meter can ever read, which is what a column of them is cut
-- to. Measured off the *last* rung rather than off the one showing, because a
-- column sized to today's demand is a column that moves the day you clear it --
-- and this is a list you read by running down it.
function Challenges.meterRoom(row)
    local last = row.want[#row.want]
    return meterText(last, last, row.how)
end

return Challenges
