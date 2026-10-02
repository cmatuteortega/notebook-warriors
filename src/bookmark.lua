-- Where you left off, for a run the program was closed on. A bookmark, not a
-- save: it keeps the twenty-odd numbers a run is (lesson, character, course,
-- the level on each line, clock, health, ink, cycle) and drops the page -- the
-- horde, the strokes, the pins, the puddles -- so you come back on FRESH PAPER
-- at the minute you left with the build you had (`Loadout:restore` rebuilds
-- from the levels alone). Only the fallback: a run walked out of through the
-- pause card is still in memory and handed back whole (`Game:continueRun`), and
-- `Game.resumable` decides which one the title screen's CONTINUE offers.
--
-- Plain text in the LOVE save directory (`bookmark.txt`), one key and its
-- tokens a line, in src/records.lua's shape. An unreadable or unknown line is
-- skipped and never an error -- this is the file a later version is likeliest
-- to disagree with, and the worst a bookmark may do is fail to be offered.

local Subjects = require("src.subjects")
local Course = require("src.course")
local Characters = require("src.characters")
local Upgrades = require("src.upgrades")
local Perks = require("src.perks")

local Bookmark = {}

local FILE = "bookmark.txt"

-- What was on disk at launch, or nil. Read once in Game:load and never
-- re-read: anything written later in the session is for the NEXT launch.
Bookmark.run = nil

-- Every value read out of the file goes through one of these, all with a floor:
-- the file is hand-editable, and a negative clock or cycle is a run whose horde
-- never arrives. Upper clamps stay where the field is understood -- health in
-- `Player:restore`, a level in `Loadout:restore`, the tool against the strip.
local function num(v, default, least)
    return math.max(least or 0, tonumber(v) or default)
end

local function int(v, default, least)
    return math.floor(num(v, default, least))
end

-- The boss phase is deliberately not written: a spawner restored mid-fight with
-- no boss on the page would drip escort for ever (`Spawner:updateBoss` only
-- leaves the phase when the boss dies). A bookmark is always in the horde
-- phase, and `cycleStart` makes that come out right -- if the ten minutes are
-- up, `Spawner:update` sends the eye again on the first frame.
function Bookmark.save(game)
    local player, loadout = game.player, game.loadout
    if not (player and loadout and game.subject and game.spawner) then return end

    local out = {
        ("subject %s"):format(game.subject.key),
        ("character %s"):format(Characters.current.key),
        -- Off the run rather than off the pick (src/course.lua): dropping the
        -- page must not finish a doctorate's run at high school, or the reverse.
        ("course %s"):format((game.course or Course.default).key),
        ("time %.2f"):format(game.time),
        ("kills %d"):format(game.kills),
        ("level %d"):format(player.level),
        ("xp %.2f"):format(player.xp),
        ("pending %d"):format(player.pending),
        ("hp %.2f"):format(player.hp),
        ("ink %.2f"):format(game.ink),
        ("tool %d"):format(game.tool),
        ("cycle %d"):format(game.spawner.cycle),
        ("cyclestart %.2f"):format(game.spawner.cycleStart),
        -- What the run has sold back, the second term of what it pays out
        -- (`Purse.forRun`); dropped, the run comes back poorer than it left.
        ("skipped %d"):format(game.skipped or 0),
    }

    -- The perks it has left, one line each (src/perks.lua). By key rather than
    -- as a row of numbers, so a key this version lacks is simply skipped.
    for _, row in ipairs(Perks.list) do
        local left = game.perks and game.perks[row.key]
        if left then
            out[#out + 1] = ("perk %s %d"):format(row.key, left)
        end
    end

    -- What it has thrown out: line ids, validated at the door like the levels --
    -- a line the catalogue no longer has cannot be banned from it.
    for id in pairs(loadout.banned) do
        out[#out + 1] = ("banned %s"):format(id)
    end

    -- In the order they were first taken, which is load-bearing twice:
    -- `Loadout:rebuild` replays levels in it and `Loadout:syncEquipped` walks it
    -- to build the tool strip, so it fixes the slot `tool` above wrote down.
    for _, id in ipairs(loadout.order) do
        out[#out + 1] = ("line %s %d"):format(id, loadout:levelOf(id))
    end

    love.filesystem.write(FILE, table.concat(out, "\n"))
end

-- Called only from the three places a run ENDS rather than pauses: dying, END
-- on the win card, and GO! starting the next. Never from the way out of the
-- program -- closing the book is not throwing the bookmark away.
function Bookmark.clear()
    Bookmark.run = nil
    love.filesystem.remove(FILE)
end

function Bookmark.load()
    Bookmark.run = nil

    local text = love.filesystem.read(FILE)
    if not text then return end

    -- Kept apart so a hand-edited file cannot land a `line` where a value goes.
    local vals, lines = {}, {}
    local perks, banned = {}, {}
    for row in text:gmatch("[^\r\n]+") do
        local key, rest = row:match("^(%S+)%s+(.+)$")
        if key == "line" then
            local id, level = rest:match("^(%S+)%s+(%d+)$")
            -- Validated at the door: a line the catalogue no longer has never
            -- becomes one of the levels a restored loadout counts as having.
            if id and Upgrades.byId[id] then
                lines[#lines + 1] = { id = id, level = tonumber(level) }
            end
        elseif key == "perk" then
            -- Clamped against how long the line is NOW: a perk shortened by a
            -- later version costs the run the difference and nothing else.
            local id, left = rest:match("^(%S+)%s+(%d+)$")
            if id and Perks.byKey[id] then
                perks[id] = math.min(tonumber(left), Perks.levels(id))
            end
        elseif key == "banned" then
            if Upgrades.byId[rest] then banned[#banned + 1] = rest end
        elseif key then
            vals[key] = rest
        end
    end

    -- Strict about the page, lenient about the hero: a bookmark for a lesson the
    -- book no longer has is a bookmark to nowhere, while a character only picks
    -- the drawing and the issued line (which is in `lines` either way), so an
    -- unknown one falls back to the first row as `Characters.load` allows.
    local subject = Subjects.get(vals.subject)
    if not vals.subject or subject.key ~= vals.subject then return end

    -- `Loadout.new` issues the lesson's tool and the character's weapon before
    -- the first frame, so every bookmark has at least two lines; none left means
    -- a file whose catalogue this version shares nothing with.
    if #lines == 0 then return end

    Bookmark.run = {
        subject = subject.key,
        character = Characters.get(vals.character).key,
        -- Lenient like the hero: an unknown course is a run sat at high school,
        -- not a bookmark to nowhere. Clamped again against what the book has
        -- paid for on the way in (`Course.pick`).
        course = Course.get(vals.course).key,
        time = num(vals.time, 0),
        kills = int(vals.kills, 0),
        level = int(vals.level, 1, 1),
        xp = num(vals.xp, 0),
        pending = int(vals.pending, 0),
        -- One rather than zero: dying clears the file, so a nought here is a
        -- garbled line, not a run to be killed by the first thing it meets.
        hp = num(vals.hp, 1),
        ink = num(vals.ink, 0),
        tool = int(vals.tool, 1, 1),
        cycle = int(vals.cycle, 1, 1),
        -- Never past the clock it is measured against: the boss is due at
        -- `cycleStart + BOSS_AT`, so a start in the future is unplayed minutes.
        cycleStart = math.min(num(vals.cyclestart, 0), num(vals.time, 0)),
        lines = lines,
        skipped = int(vals.skipped, 0),
        perks = perks,
        banned = banned,
    }
end

return Bookmark
