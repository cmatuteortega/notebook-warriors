-- What the book has done, added up.
--
-- This is src/records.lua read the other way round, and the two are deliberately
-- separate files rather than more columns on one. A **record** is a maximum kept
-- per lesson -- the longest run, the biggest body count -- and the whole of what
-- makes it safe is that it cannot go down and cannot be paid twice: submit it
-- from every route out of a run and the answer is the same. A **tally** adds up.
-- It is the purse's kind of number (src/purse.lua) rather than the register's,
-- and everything awkward about this file comes from that one difference: a tally
-- banked twice for the same kills is kills made out of nothing.
--
-- So why keep any at all, when the collection's seventeen quests never needed
-- one? Because the homework page stopped asking what your *best* run did and
-- started asking what you have *done* (src/challenges.lua). FIFTY THOUSAND BLOBS
-- is not a thing any one run will ever say -- it is four hundred afternoons -- and
-- there is no maximum anywhere that adds up to it. A book that only remembers its
-- best page can only ever ask you to have a better one.
--
-- **Three things are counted and they are the three a run finishes holding:**
--
-- - `kills[kind]` -- one body count per row of `Enemy.types`, because a homework
--   list that asked for fifty thousand of *anything* would be one challenge with
--   ten prices and a run would learn to farm the page that pays fastest. Keyed by
--   the spawner's own name for the monster, so a new row in src/enemy.lua brings
--   its own counter with it and there is no list here to keep in step.
-- - `bosses` -- how many have been put down, ever. The register keeps the most one
--   run managed; this keeps every one of them.
-- - `time` -- how long the book has been played, in seconds, across every page and
--   every run. The one number in the game that is about the player rather than
--   about anything they did.
--
-- **How it is kept honest: a watermark, not a hook.** Nothing here is called when
-- something dies. The run counts what it counts, exactly as it always has, and
-- `Game:bankTally` hands over the *difference* between what the run holds now and
-- what it has already banked (`Game.tallied`). Every number a run counts only ever
-- goes up, so a difference is always the work done since the last bank -- which
-- makes this as safe to call as `Game:bankRun` beside it: twice in a row adds
-- nothing, walking out through the pause card and coming back adds the second half
-- only, and a bookmarked run resumed on the next launch starts with its watermark
-- set to what it had already paid in (`Game:openBookmark`).
--
-- That is the whole of why the awkwardness is here rather than in the run: one
-- function, called from the one place a run already tells the book what it did,
-- and no weapon, no monster and no screen knows this file exists.
--
-- The file is written the way a record, a purse and a design are: plain text in
-- the save directory, one key and one number a line, and a line the game cannot
-- read costs that one counter and nothing else.

local Enemy = require("src.enemy")

local Tally = {}

local FILE = "tally.txt"

-- kind -> how many of it have been killed, over the life of the book. Only kinds
-- something has actually died as are in here, which is what a fresh book looks
-- like: no file, and nothing killed.
Tally.kills = {}

-- And the two that are not per anything.
Tally.bosses = 0
Tally.time = 0

-- Bumped whenever any of the above changes, for `Records.stamp`'s reason exactly:
-- the homework page asks this file the same question once per row per frame, and
-- the answers are worth holding on to between the times nothing happened.
Tally.stamp = 0

function Tally.killsOf(kind)
    return Tally.kills[kind] or 0
end

function Tally.save()
    local out = {}
    -- Written in `Enemy.types`' own order rather than in a hash walk's, so the
    -- file is the same file twice and a diff of two saves is the afternoon
    -- between them.
    for kind in pairs(Enemy.types) do out[#out + 1] = kind end
    table.sort(out)

    local lines = {}
    for _, kind in ipairs(out) do
        local n = Tally.kills[kind]
        if n and n > 0 then
            lines[#lines + 1] = ("kill %s %d"):format(kind, n)
        end
    end
    lines[#lines + 1] = ("bosses %d"):format(Tally.bosses)
    lines[#lines + 1] = ("time %.1f"):format(Tally.time)

    love.filesystem.write(FILE, table.concat(lines, "\n"))
end

-- Everything a run did since the last time it said so, as one table, and written
-- on the spot. One door rather than three, because the three arrive together and
-- a file write is worth spending on a change rather than on each column of one.
--
-- A hand that adds up to nothing writes nothing: there is no difference on disk
-- between a book that has not changed and one that has had zero added to it, and
-- this is called from every route out of a run -- including the two that reach it
-- with a run that has already paid in full.
--
-- A kind the book has no row for is dropped rather than kept, for the register's
-- reason (`Records.submit`): a monster renamed between versions is not worth
-- keeping a body count against, and a hand-edited file may not invent one.
function Tally.add(run)
    local moved = false

    for kind, n in pairs(run.kills or {}) do
        if n > 0 and Enemy.types[kind] then
            Tally.kills[kind] = (Tally.kills[kind] or 0) + n
            moved = true
        end
    end

    if (run.bosses or 0) > 0 then
        Tally.bosses = Tally.bosses + run.bosses
        moved = true
    end
    if (run.time or 0) > 0 then
        Tally.time = Tally.time + run.time
        moved = true
    end

    if moved then
        Tally.stamp = Tally.stamp + 1
        Tally.save()
    end
    return moved
end

-- No file at all is a fresh book rather than an error, and so is a line that has
-- been edited into something unreadable: a counter the game cannot read is a
-- counter that starts at nothing, and nothing is written back until something is
-- actually done.
function Tally.load()
    Tally.kills = {}
    Tally.bosses = 0
    Tally.time = 0
    Tally.stamp = Tally.stamp + 1

    local text = love.filesystem.read(FILE)
    if not text then return end

    for line in text:gmatch("[^\r\n]+") do
        local kind, n = line:match("^kill%s+(%S+)%s+(%d+)$")
        if kind and Enemy.types[kind] then
            Tally.kills[kind] = tonumber(n)
        else
            local bosses = line:match("^bosses%s+(%d+)$")
            local time = line:match("^time%s+([%d%.]+)$")
            if bosses then Tally.bosses = tonumber(bosses) end
            if time then Tally.time = tonumber(time) or 0 end
        end
    end
end

return Tally
