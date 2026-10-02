-- How hard the book is, and what it is called when it is harder.
--
-- Every other axis this game has is *sideways*. A lesson changes what the page
-- is ruled with and what is in your hand (src/subjects.lua) but deliberately
-- never what the crowd costs -- "a page may shape an arrival; it may never price
-- one" -- because that is what keeps a record on one page worth comparing to a
-- record on another. A hero changes who walks out there (src/characters.lua). A
-- perk changes what a draft may be asked (src/perks.lua). None of them makes the
-- run *harder*, and after a dozen afternoons that is the thing the book has run
-- out of ways to be: you have beaten the eye on seven pages and the eighth is the
-- same eye.
--
-- So this is the one dial that is allowed to price the crowd, and it is a
-- **course**: which class you are sitting the lesson as. High school is the game
-- as it was drawn and the game a fresh book plays; a bachelor's, a master's and a
-- doctorate are the same seven lessons read at a level that expects more of you.
-- The metaphor is doing real work rather than decorating a number -- a harder
-- difficulty in most games is a modifier you switch on, and a *course* is
-- something you enrol in, pay for, and are afterwards said to have sat. All three
-- of those turn out to be things this book already knows how to do.
--
-- **It is bought, not unlocked**, which is the one decision here worth being firm
-- about. Everything the collection opens is opened by *playing* (src/collection.
-- lua): a lesson by the lesson above it, a line by a milestone. A harder book
-- cannot work that way, because the milestone it would have to ask for is "beat
-- the game", and a player who has beaten the game and is told to beat it again
-- before the book will get harder has been told the wrong thing. So it is on the
-- counter (src/canteen.lua) beside the perks and the heroes: a level of this line
-- is one more course open, coins are the whole of what it asks, and
-- src/refund.lua hands it back like everything else there. It is also why nothing
-- here goes through src/dev.lua -- a course is a thing you bought, not a thing the
-- book opened, which is exactly the line that file draws around the purse.
--
-- **The dials, and why they are these dials.** A course is spent almost entirely
-- on the two things that were already the difficulty ramp, turned up:
--
-- - `clock` multiplies the difficulty clock, which is the one dial a *subject*
--   was always allowed and no subject has ever turned (`Spawner:update`). It is
--   how many bodies there are: the floor, the wave interval and the batch all
--   read that clock, so a course leans on the whole tap at once and never on one
--   knob of it.
-- - `hp` and `ramp` are the health curve: a flat multiplier on everything, and a
--   steepening of the 15%-a-minute compounding underneath it (`HP_PER_MINUTE`).
--   Two numbers rather than one because they say different things -- `hp` is how
--   tough the horde is when it walks on and `ramp` is how fast that gets away
--   from you, and a course that only had the first would be a course whose tenth
--   minute felt like high school's.
-- - `speed` is the one genuinely new thing a course does to a monster, and it is
--   kept small on purpose. A blob walks 20px a second against a player who walks
--   faster than that, and the whole of the horde's counterplay is that you can
--   *leave*; 12% at a doctorate is the difference between walking away
--   comfortably and walking away, which is a different game to play without being
--   a different game to learn.
--
--   It is the one dial here that the run now turns as well (SPEED_MOST in
--   src/spawner.lua): the minute multiplies this rather than replacing it, so
--   what the class buys is still 4% a rung at every minute of the run, and the
--   ceiling that keeps the horde under the player is on the run's half of the
--   product rather than on the whole of it. A ceiling on the whole of it would
--   read as the same design and quietly delete this row -- every class would
--   arrive at the same top speed, a doctorate merely sooner.
-- - `elite` and `blown` are the two facts about an *arrival* (`Spawner:elite`,
--   `BLOWN_RISE`): more of the crowd is worth turning towards, and the enormous
--   one is overdue sooner. Neither adds anything new -- both lean on a curve the
--   spawner already computes -- but they lean on it in two different places, and
--   which place is the whole content of the pair.
--
--   **`elite` shortens the climb and must never lift the ceiling.** ELITE_MOST's
--   one-in-seven is priced against what a champion *costs the page*: the mark is
--   the body drawn at twice the size (ELITE_GROW), so a seventh of the horde at
--   four times the paper is already most of what the page can carry, and the note
--   over that constant says out loud that past it a double body stops meaning
--   "that one". A course may buy a harder run and may not buy its way past that.
--   So the dial divides ELITE_RAMP instead: a doctorate reaches the same ceiling
--   in half the time, capped by minute seven and a half rather than minute eleven,
--   which measures out over a cycle as a champion in every 40 arrivals against
--   high school's one in 59 -- half again as many double bodies on the page.
--   Which is the honest shape for it anyway -- an endless run sits on the ceiling
--   whatever course it is, so the only thing there was left to sell is the middle
--   of a run, and the middle of a run is what the ten minutes this game is built
--   around *is*.
--
--   **`blown` is tuned against how many you meet, and that had to be measured.**
--   Both dials are read once per arrival and a harder course hands you fewer
--   arrivals -- a doctorate's horde takes over twice as long to clear -- so a
--   chance-per-arrival multiplied by two against an arrival count halved is a
--   course that meets no more of them than the easy one. Which is exactly what the
--   first pass at this measured. A blow-up is an *event*, a handful in a whole
--   run, so the unit that matters is the count and not the fraction, and 3, 9 and
--   30 look wildly out of scale with the rest of the table without being it: a
--   blow-up is metered rather than rolled (the chance climbs at every arrival
--   until one lands, `Spawner:blown`), so how far apart they are goes as the
--   *square root* of the rise -- four times the rise is twice as often -- and then
--   the falling arrival count takes most of that back. Measured over one cycle at
--   a fixed damage-per-second they come out at 1.24, 1.48 and 1.62 times as many
--   blow-ups as high school -- against arrival counts of 76%, 61% and 46% of its.
--
--   Past about there, BLOWN_MOST starts answering instead of the rise and a
--   bigger number stops buying anything. That is the ceiling doing the job it is
--   there for, and it is the same restraint `elite` is under, arrived at from the
--   other side: this dial can never turn the horde into what it is a blow-up of,
--   however hard the course, because the thing it moves is not the ceiling.
-- - `fury` is the third fact about an arrival (`Spawner:fury`) and the one dial
--   in this table that is a *gate* rather than a lean. Everything else here is a
--   multiple of high school, which means every rung of the ladder is the same
--   game with the numbers moved; this is the one thing a doctorate has that the
--   book below it does not have at all -- the same monster gone over in red pen,
--   quicker on its legs and hitting for half again, on exactly the row's health.
--
--   **Zero is how you spell "never" for a meter.** Fury is metered rather than
--   rolled, exactly like a blow-up, so a dial of 0 is a chance that never climbs
--   off the floor and there is no rung named anywhere in src/spawner.lua and no
--   second question asked at a spawn. Which is the shape the rest of this table
--   is in: a class is a row of numbers, and the day fury is worth having a third
--   of the way down the ladder it is one 0 becoming a 20.
--
--   The 60 is the blow-up's own number at the same rung, and deliberately the
--   same: what fury was priced at is *a blow-up's rarity* -- something you meet
--   about once every half minute of a busy page -- so it inherits the whole of
--   the argument above, the falling arrival count and the square root included.
--
--   It is also the one thing in this file that touches what a hit costs you, and
--   the note below still holds: what that forbids is a class quietly repricing a
--   blob, and this reprices one arrival that is wearing red while it does it.
-- - `pay` is the other side of the bargain and the reason anybody enrols
--   (`Purse.forRun`): a doctorate pays three times what high school does, so the
--   counter it was bought over is also what it is spent on.
--
-- **What a course deliberately does not touch is what a hit costs you.** Enemy
-- damage stays exactly where src/enemy.lua wrote it, and that is the same
-- restraint the spawner puts on its own ramp -- health may climb continuously
-- because a tougher blob is a longer fight, and damage may not, because a blob
-- that hits for a fraction more is a blob nobody can learn. A course is a step
-- rather than a slope, so it *could* have moved it; it doesn't, and the reason is
-- worth being exact about, because a course changes plenty else that a player has
-- learned. What a harder class may take away is *time*: a blob you could kill in
-- one hit now takes two, a crowd you could outwalk now nearly keeps up. What it
-- may not take away is the arithmetic you count your own page of health in -- the
-- blob's 6 is a quarter of you in every class in the building, and a doctorate
-- that quietly made it a third would be a doctorate you die to for a reason
-- nothing on screen ever said.
--
-- `fury` is the exception that proves that last clause rather than a hole in it.
-- An enraged arrival does hit for half again, and every word of the restraint
-- above survives it because the thing it forbids is the word *quietly*: a
-- doctorate's blob still hits for 6, and the one that hits for 9 is red and black
-- from head to foot, is one arrival in a hundred, and said its own name the first
-- time it walked on. What may not be learned is a number that moved behind you.
--
-- **A run is sat at one course and the register remembers which**
-- (src/records.lua). That is the whole reason the ladder is worth having rather
-- than being a private multiplier: a best of 8:31 means one thing on a page you
-- sat at high school and another on the page you sat at a doctorate, and a
-- register that kept the first number without the second would be a book that had
-- forgotten the harder half of what you did.
--
-- The file is written the way a record, a purse and a roster are: plain text in
-- the save directory, a key and one token a line, and a line the game cannot read
-- costs that line its default. A course file nobody can read is a book that has
-- not enrolled in anything, which is the safe way for it to be wrong.

local Purse = require("src.purse")

local Course = {}

local FILE = "course.txt"

-- The ladder, easiest first, and the order is the order it is bought in: a level
-- of the counter's line opens the next row down, so this list is the price list's
-- own order and moving a row moves what a level buys.
--
-- `name` is English because English is the key (src/i18n.lua). PHD rather than
-- PH.D. because the 3x5 face has a full stop and a word with two of them in it
-- reads as three words on a card 40 pixels wide.
--
-- Every dial on the first row is 1, and that is worth saying out loud rather than
-- leaving implied: HIGH SCHOOL is not the easy setting, it is *the game* -- every
-- number argued for in README.md, every measurement the bestiary was tuned by,
-- and the only course a fresh book has. The three below it are departures from it
-- and are written as multiples of it for exactly that reason.
Course.list = {
    {
        key = "school", name = "HIGH SCHOOL",
        clock = 1, hp = 1, ramp = 1, speed = 1,
        elite = 1, blown = 1, fury = 0, pay = 1,
    },
    -- A first departure, and it is meant to be one you take *because* you have
    -- stopped losing rather than because you want a harder time: a quarter more
    -- health and a fifth more bodies is about one extra minute of the ramp
    -- arriving early, which a build that beats the eye comfortably will barely
    -- notice until minute eight. It is also the rung where the game's most basic
    -- sentence stops being true -- 4 health times 1.25 rounds to 5, so the
    -- pencil's 4 no longer kills a blob in one -- and that is the loudest thing a
    -- first rung could possibly say. It is allowed to say it because you chose it
    -- and the timetable says which class you are in, in the margin, in red.
    {
        key = "bachelor", name = "BACHELOR",
        clock = 1.2, hp = 1.25, ramp = 1.08, speed = 1.04,
        elite = 1.25, blown = 3, fury = 0, pay = 1.4,
    },
    -- The middle of the ladder, and where the numbers stop being trim: 1.6 times
    -- the health under a curve 16% steeper comes out near twice the horde's
    -- health by the time the eye walks on, which is the first course where a
    -- build that does not answer a crowd runs out of page.
    {
        key = "masters", name = "MASTERS",
        clock = 1.4, hp = 1.6, ramp = 1.16, speed = 1.08,
        elite = 1.6, blown = 9, fury = 0, pay = 2,
    },
    -- And the top of it, at three times the health, two thirds again the crowd,
    -- half again as many champions on the page and about 1.6 times as many
    -- blow-ups a cycle. Three times the payout with it, which is the number that
    -- makes the whole ladder a bargain rather than a badge -- a doctorate pays for
    -- the perks that make a doctorate survivable.
    {
        key = "phd", name = "PHD",
        clock = 1.65, hp = 2.1, ramp = 1.25, speed = 1.12,
        elite = 2, blown = 60, fury = 60, pay = 3,
    },
}

Course.byKey = {}
for i, row in ipairs(Course.list) do
    row.index = i
    Course.byKey[row.key] = row
end

Course.default = Course.list[1]

-- What the counter's one row is called, and the only key this module answers the
-- shop's five questions about. One row with three levels rather than three rows
-- with one, because a course ladder is a ladder: buying MASTERS before BACHELOR
-- is not a thing the book should have to have an opinion about, and a line whose
-- level *is* how far up you are cannot express it.
Course.KEY = "course"

-- What each rung costs, and there are three because the first course is not
-- bought. Priced off RETAKE rather than off the cheap perks (src/perks.lua): what
-- this sells is not a better draft but a different book, so a first one is most of
-- an afternoon and the last is a fortnight. `pay` is what keeps that from being a
-- wall -- every course pays for the next one faster than the last did.
Course.price = { 15, 40, 90 }

-- How many rungs have been paid for, so HIGH SCHOOL plus this is how far the
-- ladder goes. Loaded once in `Game:load` and written the moment it changes.
Course.open = 0

-- Which one the next run is sat at. A row rather than a key, the way
-- `Characters.current` is: everything that reads it wants the dials off it.
Course.current = Course.default

function Course.get(key)
    return Course.byKey[key] or Course.default
end

-- The course a run is built with. One door, because a run must never read
-- `Course.current` for itself: the pick is a setting and a run is a thing that
-- has already started, and the two come apart the moment somebody walks out
-- through the pause card and changes their mind (`Game:reset` takes it once).
function Course.at()
    return Course.current
end

-- Whether the book may be sat at this row. Index rather than key because the
-- answer is a fact about how far up the ladder you have paid, and the first row
-- is always open -- a book that had bought nothing and could sit nothing would be
-- a book with no game in it.
--
-- Not through src/dev.lua, unlike every other locked thing in the game. A course
-- is a purchase and not an unlock, which is the line that file draws around the
-- purse: ALL must not hand you a doctorate you did not pay for, because the way
-- back off one is a refund and not a switch.
function Course.owns(index)
    return index <= 1 or Course.open >= index - 1
end

-- The highest row paid for, which is what a pick is clamped to and what a book
-- that has just refunded everything falls back to.
function Course.top()
    return math.min(#Course.list, 1 + Course.open)
end

--- the counter ---------------------------------------------------------------

-- The five questions the canteen asks about a row (src/canteen.lua), answered
-- exactly as src/perks.lua and src/characters.lua answer them. That is the whole
-- of what the three files have in common and it is deliberately all of it: a row
-- is a name, a price and a box, and what is behind it is the note under the
-- counter's business.
function Course.level()
    return Course.open
end

function Course.levels()
    return #Course.price
end

function Course.priceOf()
    return Course.price[Course.open + 1]
end

function Course.canBuy()
    local price = Course.priceOf()
    return price ~= nil and Purse.total >= price
end

-- Bought, and the purse is what refuses (`Purse.spend` never clamps), so a rung
-- only opens if the coins actually came out.
--
-- The pick is deliberately *not* moved to it. Enrolling in a doctorate and being
-- put in one is not the same thing -- the timetable is where you choose what to
-- sit, and a counter that changed which page you were about to play would be the
-- one row in the shop that reached past its own screen.
function Course.buy()
    local price = Course.priceOf()
    if not price or not Purse.spend(price) then return false end

    Course.open = Course.open + 1
    Course.save()
    return true
end

--- the pick ------------------------------------------------------------------

-- Clamped to what has been paid for rather than refused, which is the roster's
-- rule (`Characters.pick`): a book that has just handed back its courses
-- (src/refund.lua) is standing on one it no longer owns, and the honest answer to
-- that is the top of what is left rather than a screen that will not answer.
function Course.pick(key)
    local row = Course.get(key)
    if not Course.owns(row.index) then row = Course.list[Course.top()] end

    Course.current = row
    Course.save()
    return Course.current
end

-- One up or down the ladder, stopping at both ends rather than wrapping. A course
-- is a *scale* -- the one thing in this book that has an order to it and says so
-- -- and a `< >` stepper that fell off the top of it back to high school would be
-- a control arguing with what it is drawn as (src/timetable.lua). Stopping is also
-- what lets the arrow at each end *say* something: the timetable reads the refusal
-- back out as a colour, so the far end of the ladder and the rung you have not
-- paid for look different from a rung you can step onto.
function Course.step(dir)
    local i = Course.current.index + dir
    if i < 1 or i > #Course.list or not Course.owns(i) then
        return Course.current
    end
    return Course.pick(Course.list[i].key)
end

--- the file ------------------------------------------------------------------

function Course.save()
    love.filesystem.write(FILE, table.concat({
        ("open %d"):format(Course.open),
        ("at %s"):format(Course.current.key),
    }, "\n"))
end

-- The rungs first and the pick second, because a pick is clamped to the rungs.
-- Not through `pick` or `buy`, for the roster's reason: a launch that read the
-- file should not write it back.
function Course.load()
    Course.open = 0
    Course.current = Course.default

    local text = love.filesystem.read(FILE)
    if not text then return end

    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^(%S+)%s+(%S+)$")
        if key == "open" then
            -- Clamped against how long the ladder is *now*, which is the leniency
            -- src/perks.lua reads a level with: a ladder shortened by a later
            -- version costs the book the difference and nothing else.
            local n = tonumber(value)
            if n then
                Course.open = math.max(0, math.min(math.floor(n), #Course.price))
            end
        elseif key == "at" then
            local row = Course.byKey[value]
            if row then Course.current = row end
        end
    end

    -- And the clamp the two lines cannot do separately: a hand-edited file naming
    -- a course it has not bought is a book sat at the top of what it has.
    if not Course.owns(Course.current.index) then
        Course.current = Course.list[Course.top()]
    end
end

return Course
