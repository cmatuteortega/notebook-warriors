-- What the book remembers about a lesson.
--
-- A run leaves nothing behind it. The page is infinite and thrown away, the
-- marks fade, and the loadout dies with the player -- which is right for a run
-- and wrong for a *book*: seven lessons you have never told apart look
-- identical from the timetable, and the only thing that can tell them apart
-- before you have played them is what you did on them last time.
--
-- So one line per subject is kept, and it is three numbers rather than a table of
-- them: how long the longest run on that page lasted, how many it killed, and how
-- many times one run on it has put that lesson's boss down -- all three of them
-- things the run is already counting (`game.time`, `game.kills`, `game.eyes`), and
-- the first two the pair the win card prints. Nothing else here is worth keeping
-- score of, because nothing else is a thing you can beat.
--
-- The third is called `bosses` here and `eyes` in the run, and the difference is
-- deliberate. The eye is the only boss anybody has drawn yet and every lesson
-- fights it; each lesson is getting its own. A run may name what it is fighting,
-- because a run only ever fights one thing -- but this file outlives seven of
-- them, and a column called `eyes` would be a column that went quietly wrong on
-- the day maths grew a boss of its own.
--
-- The third one was added for a second reader. This file used to be read by one
-- screen -- the timetable's two stat rows -- and it is now also what says which
-- parts of the catalogue the book has opened at all (src/collection.lua), which is
-- the one thing here worth knowing before changing it: a quest is written
-- against these numbers, so a number that stopped being kept is a shelf of the
-- library that can never be filled in.
--
-- **And a fourth field that is not a number of anything: the course the best run
-- was sat at** (src/course.lua). A best of 8:31 means one thing on a page you sat
-- at high school and another on the page you sat at a doctorate, so a register
-- that kept the first without the second would have forgotten the harder half of
-- what you did -- which is the whole reason the ladder is a thing the book
-- remembers rather than a private multiplier.
--
-- It is a **label on the time and not a record of its own**, and that is the one
-- place this file bends its own rule, so it is worth being exact about. The three
-- numbers are maxima and cannot go down. This moves with `time` and only with
-- `time`: beat your best on the easiest course in the book and the register says
-- so, in both columns, because the alternative is a line reading 8:31 at a
-- doctorate about a run that was nothing of the kind. Which is safe precisely
-- because nothing gates on it -- the collection asks this file for times, kills,
-- bosses and counts of pages clearing a bar, and never once for a course. A field
-- that can go down may exist here as long as no unlock is written against it, and
-- if one ever is, this is the field that has to change first.
--
-- **And a fifth that is the course again, kept the honest way: `won`, the hardest
-- class this lesson's boss has ever been put down at.** It is the one thing above
-- that a gate *is* written against (COMPLETE EVERY CLASS AT MASTERS, on the
-- homework list -- src/challenges.lua), which is exactly why it cannot be the
-- field above it. So it is a maximum on the ladder's own order and nothing else:
-- it moves only upwards, it moves only when a boss actually goes down, and it
-- knows nothing about the clock beside it. Beat art at a doctorate and then spend
-- a fortnight beating it at high school and the register still says doctorate,
-- because you still did it.
--
-- Two fields naming a course and one meaning: a page you played, and a page you
-- won. Neither is derivable from the other -- the longest run on a page need not
-- be the one that shut the eye -- which is the whole reason there are two.
--
-- A record is a **maximum**, never a last-run or an average. A page you have
-- played once is a page you have a best on, and a bad run must not be able to
-- take something away from you -- which is also why every route out of a run
-- banks (`Game:bankRun`): dying, winning and walking out of the pause card are
-- all the same fact, that this is how far the run got.
--
-- That is also the whole reason the collection is keyed to this file and has none
-- of its own: an unlock read off a maximum can never be taken away, so there is
-- nothing to save and nothing to keep in step. The boss count is a maximum on the
-- same terms -- the most bosses *one* run on that page put down, not a tally of
-- them -- which is what keeps it a record rather than a meter. And it is what
-- makes the two counts below (`Records.sat`, `best.beat`) safe to gate on: a count
-- of pages whose maximum clears a bar is itself a thing that can only go up.
--
-- The file is written the way a design is (src/design.lua): plain text in the
-- save directory, one record a line, and a line that has been edited into
-- something the game cannot read is skipped rather than trusted -- a bad line
-- costs you that lesson's record and nothing else.

local Subjects = require("src.subjects")
local Course = require("src.course")

local Records = {}

local FILE = "records.txt"

-- key -> { time, kills, bosses, course, won }. Absent means never played, which is
-- a thing the timetable says out loud rather than printing as a row of zeroes.
Records.by = {}

-- Bumped every time the above changes, which is twice in the life of the program:
-- when the file is read and when a record is beaten. It is here for the one reader
-- that asks the same question of this table many times a frame -- the collection,
-- once per line of the catalogue per shelf drawn -- so that it can hold on to the
-- answer rather than walking seven lessons for each of thirty-six names. The same
-- trick `Library:rewrap` caches the whole book's line breaks with, and for the same
-- reason: the work is nothing, and doing nothing repeatedly is still nothing being
-- done repeatedly.
Records.stamp = 0

function Records.get(key)
    return Records.by[key]
        or { time = 0, kills = 0, bosses = 0, course = Course.default.key }
end

-- How far up the ladder this lesson has been beaten, as an index into
-- `Course.list` -- 0 for a page whose boss has never gone down at all, which is
-- what makes it a number rather than a key: what is asked of it is always "at
-- this rung or higher", and that is a comparison rather than a lookup.
function Records.wonAt(key)
    local won = Records.get(key).won
    return won and Course.get(won).index or 0
end

-- And how many lessons have been beaten at that rung or better -- the third count
-- of pages, beside `Records.best`'s `beat` and `Records.sat`, and a maximum on
-- their terms: a page that has cleared a rung cannot stop having cleared it.
--
-- Kept here rather than folded into `best` for `sat`'s reason exactly: everything
-- that function answers, it answers out of this file's own numbers, and this one
-- has to be told which rung is being asked about.
function Records.beatAt(index)
    local n = 0
    for _, sub in ipairs(Subjects.list) do
        if Records.wonAt(sub.key) >= index then n = n + 1 end
    end
    return n
end

-- Whether a lesson has anything to show yet. Time is the test rather than
-- kills, because a run can end without killing anything and no run ends without
-- having lasted.
function Records.played(key)
    return Records.get(key).time > 0
end

function Records.save()
    local out = {}
    for _, sub in ipairs(Subjects.list) do
        local rec = Records.by[sub.key]
        if rec then
            -- The course this page was won at goes last and is written as `-`
            -- when there is none, because the field after it would otherwise be
            -- the field before it on the way back in: the format is positional,
            -- and an empty token is not a token.
            out[#out + 1] = ("%s %.1f %d %d %s %s"):format(sub.key, rec.time,
                rec.kills, rec.bosses or 0, rec.course or Course.default.key,
                rec.won or "-")
        end
    end
    love.filesystem.write(FILE, table.concat(out, "\n"))
end

-- The best of the book rather than of a page: the longest run anywhere, the
-- biggest body count on any one page, the most bosses one run has put down
-- anywhere, and how many *different* lessons have had their boss put down.
--
-- The fourth is the odd one and it is the reason this function is worth having.
-- The first three are the best of a column and ask you to get better at a page;
-- a count of pages asks you to leave one, which is the one thing the other three
-- cannot ask for and the whole reason the book has seven of them. It used to be
-- `played` -- how many lessons had been opened at all -- and that stopped being a
-- question the day the timetable itself went behind a ladder: a lesson you have
-- played is a lesson you unlocked by playing the one above it, so counting them
-- was counting the term twice.
--
-- Maxima across pages rather than sums, for the reason the file keeps maxima: a
-- number that can go down is a thing that could take an unlock away. A count of
-- pages clearing a bar is a maximum on the same terms -- a page that has cleared
-- it cannot stop having cleared it -- which is what makes `beat` gateable and what
-- made `played` gateable before it.
function Records.best()
    local best = { time = 0, kills = 0, bosses = 0, beat = 0 }

    for _, sub in ipairs(Subjects.list) do
        local rec = Records.by[sub.key]
        if rec then
            best.time = math.max(best.time, rec.time)
            best.kills = math.max(best.kills, rec.kills)
            best.bosses = math.max(best.bosses, rec.bosses or 0)
            if (rec.bosses or 0) >= 1 then best.beat = best.beat + 1 end
        end
    end

    return best
end

-- And how many lessons have been *sat* -- played far enough into that the boss
-- walked on. The other count of pages, and the one that cannot be answered here
-- without being told the bar, since how long a lesson runs for is the spawner's
-- business and what counts as sitting one is the collection's (`Collection.SIT`).
--
-- Kept apart from `Records.best` rather than folded into it for that reason
-- alone: everything that function answers, it answers out of this file's own
-- numbers. This one needs a number from somewhere else, and a `best` that had to
-- be handed one would be a `best` every caller had to know the bar to ask for.
--
-- It is the boss-blind half of the pair. `beat` asks whether you won; this asks
-- only whether you were still on the page when the fight started, which is a
-- question that stays exactly as meaningful when all seven bosses are different.
function Records.sat(seconds)
    local n = 0
    for _, sub in ipairs(Subjects.list) do
        if Records.get(sub.key).time >= seconds then n = n + 1 end
    end
    return n
end

-- The three numbers are kept apart on purpose: the longest run, the biggest body
-- count and the run that got furthest into the eye need not be the same run. A
-- page where you survived twelve minutes hiding behind pen lines and another where
-- you cleared four hundred in six is two things you did to that page, and the
-- register has room to say both.
function Records.submit(key, time, kills, bosses, course)
    -- A key the book no longer has a page for -- a subject renamed between
    -- versions -- is not worth keeping a record against.
    if Subjects.get(key).key ~= key then return false end

    local rec = Records.by[key]
    if not rec then
        rec = { time = 0, kills = 0, bosses = 0, course = Course.default.key }
        Records.by[key] = rec
    end

    local better = false
    -- The course goes with the clock and nowhere else (see the note at the top):
    -- it is what the longest run on this page was sat at, so it moves when that
    -- run is replaced and stays put when a shorter one on a harder course beats
    -- the body count.
    if time > rec.time then
        rec.time, better = time, true
        rec.course = Course.get(course).key
    end
    if kills > rec.kills then rec.kills, better = kills, true end
    if (bosses or 0) > (rec.bosses or 0) then rec.bosses, better = bosses, true end

    -- And the class it was won at, which moves on its own terms and on nobody
    -- else's (see the top of this file): only when something actually went down,
    -- only ever upwards, and never because the clock moved. A run that put two
    -- eyes down says exactly what a run that put one down says -- what is being
    -- asked is whether this page has been beaten *here*, and once is beaten.
    if (bosses or 0) >= 1 then
        local at = Course.get(course)
        if at.index > (rec.won and Course.get(rec.won).index or 0) then
            rec.won, better = at.key, true
        end
    end

    if better then
        Records.stamp = Records.stamp + 1
        Records.save()
    end
    return better
end

function Records.load()
    Records.by = {}
    Records.stamp = Records.stamp + 1

    local text = love.filesystem.read(FILE)
    if not text then return end

    for line in text:gmatch("[^\r\n]+") do
        -- The boss count is optional on the way in, which is what a file written
        -- before it was kept looks like: an old line reads back as a page whose
        -- best run never put anything down, which is the safe way for it to be
        -- wrong -- the quest it feeds is asked again the next time one goes down.
        -- The field was called `eyes` when it was written and is called `bosses`
        -- now; the file is positional, so the rename costs no migration and an
        -- old file needs no reading twice. The course after it is optional on the
        -- same terms and is the one field here that is a word rather than a
        -- figure, which is why it is last: everything positional stays where it
        -- was and the new field is a token nobody's pattern was reading.
        local key, time, kills, bosses, course, won =
            line:match("^(%S+)%s+([%d%.]+)%s+(%d+)%s*(%d*)%s*(%S*)%s*(%S*)$")
        time, kills = tonumber(time), tonumber(kills)
        if key and time and kills and Subjects.get(key).key == key then
            Records.by[key] = {
                time = time, kills = kills, bosses = tonumber(bosses) or 0,
                -- The course is optional on the way in for the boss count's
                -- reason, and an unreadable one reads back as high school: a file
                -- written before the ladder existed is a file every run in which
                -- *was* high school, so the lenient answer here happens to be the
                -- true one.
                course = Course.get(course).key,
                -- And the class it was *won* at, which is the one field here
                -- that may legitimately be missing: `-` is a page never beaten,
                -- and so is a file written before this column existed. Nothing
                -- is guessed from the column beside it -- a page you played at a
                -- doctorate is not a page you beat there -- so an old file asks
                -- for its hardest wins again, which is the safe way round.
                won = Course.byKey[won or ""] and won or nil,
            }
        end
    end
end

return Records
