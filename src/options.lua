-- What the player has set: language, the two volumes, which way up the page is
-- held, which corner the stick is in, how loud a hit is said, and whether a new
-- drawing is asked for. None of it belongs to a run.
--
-- Nothing here owns a value -- each setting lives in the module that knows what
-- it means (src/i18n, src/sfx, src/orient, src/input, src/damage, src/design),
-- and that module also owns the LIST of values it may take, which is what a
-- line is read back against: a value not on the list is a later version's file
-- and keeps the default. This file owns the format only, reading it once at
-- load and writing whenever a screen sets a value on its owner and calls
-- `Options.save` -- the same split src/records.lua uses.
--
-- Plain text in the LOVE save directory (`options.txt`), one setting a line,
-- and an unreadable line is skipped rather than trusted: a bad line costs that
-- setting its default and nothing else. A garbled options file must never be a
-- game that will not start.

local I18n = require("src.i18n")
local Sfx = require("src.sfx")
local Design = require("src.design")
local Input = require("src.input")
local Damage = require("src.damage")
local Orient = require("src.orient")
local Dev = require("src.dev")

local Options = {}

local FILE = "options.txt"

-- Volumes write to two decimals: finer than the bars drag, still readable by eye.
local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

-- 1/0 rather than a word, so every line is a key plus one token.
local function flag(v)
    return v and 1 or 0
end

-- A word off the owning module's own list, or nothing at all.
local function oneOf(list, value)
    for _, v in ipairs(list) do
        if v == value then return value end
    end
end

function Options.save()
    local out = {
        ("lang %s"):format(I18n.lang),
        ("sfx %.2f"):format(clamp01(Sfx.volume)),
        ("music %.2f"):format(clamp01(Sfx.music)),
        ("screen %s"):format(Orient.mode),
        ("stick %s"):format(Input.stickSide),
        ("damage %s"):format(Damage.show),
        ("ask %d"):format(flag(Design.ask)),
        -- DEV, out at launch with src/dev.lua. Written rather than defaulted so
        -- a dev who set ALL yesterday still has it; an unknown value defaults.
        ("unlocks %s"):format(Dev.unlocks),
        -- DEV, out with it: whether the gesture has ever been done on this book.
        -- A player who never has it has a 0 here and nothing to see.
        ("dev %d"):format(flag(Dev.shown)),
    }
    love.filesystem.write(FILE, table.concat(out, "\n"))
end

-- No file is a first run, not an error: every value keeps its default and
-- nothing is saved until something is changed.
function Options.load()
    local text = love.filesystem.read(FILE)
    if not text then return end

    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^(%S+)%s+(%S+)$")
        if key == "lang" then
            -- I18n refuses a language it has no words for -- i.e. a later
            -- version's file.
            I18n.set(value)
        elseif key == "sfx" then
            local v = tonumber(value)
            if v then Sfx.volume = clamp01(v) end
        elseif key == "music" then
            local v = tonumber(value)
            if v then Sfx.music = clamp01(v) end
        elseif key == "screen" then
            -- Read off a list like any other, but applied by the caller:
            -- turning the phone is a window call and belongs to main.lua.
            Orient.mode = oneOf(Orient.MODES, value) or Orient.mode
        elseif key == "stick" then
            Input.stickSide = oneOf(Input.SIDES, value) or Input.stickSide
        elseif key == "damage" then
            Damage.show = oneOf(Damage.MODES, value) or Damage.show
        elseif key == "unlocks" then
            -- DEV (src/dev.lua).
            Dev.unlocks = oneOf(Dev.MODES, value) or Dev.unlocks
        elseif key == "dev" then
            -- DEV. An unreadable line leaves it hidden -- the way round that
            -- costs a player nothing; a dev just taps three times again.
            local v = tonumber(value)
            if v then Dev.shown = v ~= 0 end
        elseif key == "ask" then
            -- A non-number leaves the default alone, so a hand-edited file
            -- cannot turn the boards off by being unreadable.
            local v = tonumber(value)
            if v then Design.ask = v ~= 0 end
        end
    end
end

return Options
