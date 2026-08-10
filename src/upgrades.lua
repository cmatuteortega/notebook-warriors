-- What levelling up offers you.
--
-- Every upgrade is a *line*: a row here with a list of levels, taken one at a
-- time and always in order. Nothing outside this file knows what any of them
-- do. The draft (src/levelup.lua) offers whichever lines still have a level
-- left in them, and the run's loadout (src/loadout.lua) replays every level it
-- has ever taken, from scratch, whenever anything changes.
--
-- That replay is why a level is written as a function of the thing it changes
-- rather than a patch applied once and forgotten. Taking the fifth level of the
-- ruler re-runs levels one to five over a *fresh copy* of the tool, so no level
-- has to know what the ones before it did, nothing can drift after a few
-- hundred applications of a multiplier, and a number that depends on something
-- outside the run -- the one ruler upgrade measured off the page you can see --
-- is simply recomputed when that changes.
--
--   id       what the loadout files the line under
--   name     what the card says, in a 3x5 font: keep it short
--   icon     a sprite from Sprites.icons
--   kind     "weapon" (something that fights for you), "tool" (something you
--            draw with) or "passive" (a number about you)
--   tool     for kind == "tool": the name of the row in Tools.list it upgrades.
--            A line whose tool has been shelved is never offered.
--   design   for a thing you draw rather than one you are handed: the name of a
--            design in src/design.lua. Taking the first level of the line puts
--            you on the board to draw it, the way the hero is drawn.
--   weight   how often it comes up against the other lines (default 1)
--   levels   in order. Each is { text, apply }:
--              text    what the card says this level does
--              apply(target, screen)  `target` is the run's stat block, or --
--                      for a tool line -- the run's copy of that tool. `screen`
--                      is { w, h } of the canvas, for the one upgrade that is
--                      measured off the page rather than written down here.
--
-- Adding a line is a row here plus an icon in src/sprites.lua. Adding a passive
-- weapon is a row here whose first level puts a block on the stats, a module
-- that flies it, and a row in src/loadout.lua's WEAPONS pairing the two -- plus,
-- if it is something the player should draw, a design in src/design.lua and the
-- `design` field below naming it.

local util = require("src.util")

local Upgrades = {}

-- Every number a run can change about itself, at the value it starts on. A
-- passive weapon is absent rather than zeroed -- the block turning up *is* what
-- brings the weapon into the run.
function Upgrades.baseStats()
    return {
        speed = 1,          -- multiplier on Player.SPEED
        maxHp = 100,
        fireRate = 1,       -- multiplier on the auto-shot's interval: lower is faster
        damage = 1,         -- multiplier on everything that hits
        toolDamage = 1,     -- ... and on what you draw with, on top of it
        passiveDamage = 1,  -- ... and on what fights for you, on top of it
        magnet = 26,        -- how far off a gem starts coming to you, in pixels

        star = nil,         -- see src/orbital.lua
        rocket = nil,       -- see src/rocket.lua
    }
end

-- The two damage lines are the same line twice, pointed at the two halves of
-- the game: what you draw and what draws itself. The percentages climb rather
-- than repeat, so the fifth level of either is worth nearly three of the first
-- and the choice stays live all the way up.
local function sharpen(field, percent)
    return function(s) s[field] = s[field] * (1 + percent / 100) end
end

local RISING = { 15, 20, 25, 30, 40 }

local function risingLine(id, name, icon, field, what)
    local levels = {}
    for i, percent in ipairs(RISING) do
        levels[i] = {
            text = i == 1
                and ("+" .. percent .. "% DAMAGE FROM " .. what)
                or ("+" .. percent .. "% MORE ON TOP OF THAT"),
            apply = sharpen(field, percent),
        }
    end
    return { id = id, name = name, icon = icon, kind = "passive", levels = levels }
end

Upgrades.list = {
    {
        -- The first passive weapon: something that fights while your hands are
        -- busy drawing. It is deliberately the one line that changes shape as
        -- it climbs rather than only its numbers -- one star, then two, then a
        -- triangle, then an orbit that breathes in and out and sweeps a band of
        -- page instead of a ring of it.
        id = "star",
        name = "STARS",
        icon = "star",
        kind = "weapon",
        -- You are not given a star, you draw one -- on the same board the hero
        -- was drawn on, kept in the same way, the first time this line is taken.
        -- The card's icon is not it: the icon says what is on offer, the same
        -- 11x11 glyph as every other line, and the seven pixels that go round
        -- you are yours.
        design = "star",
        levels = {
            {
                text = "A STAR ORBITS YOU AND CUTS WHAT IT TOUCHES",
                apply = function(s)
                    s.star = {
                        count = 1,
                        radius = 22,     -- clear of a 6px hero, close enough to guard
                        rate = 2.6,      -- radians a second: a turn every 2.4s
                        damage = 4,      -- a blob outright, a skull in three
                        rehit = 0.45,    -- before the same enemy can be cut again
                        breathe = 0,     -- how far the orbit swells, in pixels
                        breatheRate = 1.15,
                    }
                end,
            },
            { text = "A SECOND STAR JOINS THE ORBIT",
              apply = function(s) s.star.count = 2 end },
            { text = "THE ORBIT TURNS FASTER",
              apply = function(s) s.star.rate = s.star.rate * 1.45 end },
            { text = "THE STARS CUT DEEPER",
              apply = function(s) s.star.damage = s.star.damage + 3 end },
            { text = "A THIRD STAR MAKES IT A TRIANGLE",
              apply = function(s) s.star.count = 3 end },
            -- The one that changes what the weapon *is*: a ring only ever
            -- touches things at one distance, and a ring that breathes sweeps
            -- everything between two.
            { text = "THE ORBIT SWELLS AND SHRINKS AS IT TURNS",
              apply = function(s) s.star.breathe = 11 end },
            { text = "THE STARS CUT DEEPER STILL",
              apply = function(s) s.star.damage = s.star.damage + 4 end },
            { text = "THE ORBIT TURNS FASTER STILL",
              apply = function(s) s.star.rate = s.star.rate * 1.4 end },
        },
    },
    {
        -- The other half of the same idea as the stars, and deliberately its
        -- opposite: a star guards the ring you are standing in and never leaves
        -- it, a rocket leaves and picks something off. A run that has taken
        -- both is covered close and far, which is a shape worth being able to
        -- build; a run that has taken one has chosen which half of the page it
        -- is fighting on.
        id = "rocket",
        name = "ROCKET",
        icon = "rocket",
        kind = "weapon",
        -- Drawn rather than issued, the way the star is. Eleven by seven of
        -- pointy with a rocket in them to start with -- the reskin is the point,
        -- and the board is where it happens.
        design = "rocket",
        levels = {
            {
                text = "A ROCKET LAUNCHES AT WHATEVER IS NEAREST",
                apply = function(s)
                    s.rocket = {
                        every = 1.9,    -- seconds between one volley and the next
                        count = 1,
                        spread = 0.2,   -- radians between one rocket of a volley
                                        -- and the one beside it
                        -- A blob or a bat outright and a skull left on 4, so the
                        -- opening level clears the crowd it is fired into and
                        -- still has to fire twice at the thing you were worried
                        -- about. The damage level below is what closes that gap.
                        damage = 8,
                        pierce = 0,     -- extra enemies one goes through
                        speed = 88,     -- slower than the biro, and it should be
                        range = 110,    -- how far off it will pick a target
                        life = 1.6,     -- seconds, so about 140px of flight
                    }
                end,
            },
            { text = "THEY COME UP FASTER",
              apply = function(s) s.rocket.every = 1.45 end },
            { text = "TWO GO UP AT ONCE",
              apply = function(s) s.rocket.count = 2 end },
            -- The one that changes what the weapon *is*: up to here a rocket is
            -- one enemy's problem, and past it a volley is a line drawn through
            -- the crowd.
            { text = "THEY CARRY ON THROUGH WHAT THEY HIT",
              apply = function(s) s.rocket.pierce = 1 end },
            -- 13, which is one more than a skull has.
            { text = "THEY GO OFF HARDER",
              apply = function(s) s.rocket.damage = s.rocket.damage + 5 end },
            { text = "THREE GO UP AT ONCE",
              apply = function(s) s.rocket.count = 3 end },
            { text = "FASTER STILL",
              apply = function(s) s.rocket.every = 1 end },
            { text = "THEY CARRY ON THROUGH TWO MORE",
              apply = function(s) s.rocket.pierce = 3 end },
            { text = "THEY GO OFF HARDER STILL",
              apply = function(s) s.rocket.damage = s.rocket.damage + 7 end },
        },
    },
    {
        -- Range on the gems, which is really range on your attention: the
        -- further xp comes to you, the less of the run you spend walking back
        -- over ground you have already cleared.
        id = "magnet",
        name = "MAGNET",
        icon = "magnet",
        kind = "passive",
        levels = {
            { text = "XP COMES TO YOU FROM FURTHER OFF",
              apply = function(s) s.magnet = s.magnet + 18 end },
            { text = "FURTHER OFF AGAIN",
              apply = function(s) s.magnet = s.magnet + 18 end },
            { text = "FURTHER OFF AGAIN",
              apply = function(s) s.magnet = s.magnet + 18 end },
            { text = "THE WHOLE PAGE LEANS YOUR WAY",
              apply = function(s) s.magnet = s.magnet + 24 end },
        },
    },
    risingLine("scissors", "SCISSORS", "scissors", "toolDamage", "WHAT YOU DRAW"),
    risingLine("graphite", "GRAPHITE", "graphite", "passiveDamage", "WHAT FIGHTS FOR YOU"),
    {
        -- The tool line. Everything here is a number in the ruler's own snap
        -- block (src/tools.lua) rather than a stat about you, which is what
        -- makes it a different kind of upgrade: it is only worth anything if
        -- you are still picking the ruler up.
        id = "ruler",
        name = "RULER",
        icon = "ruler",
        kind = "tool",
        tool = "RULER",
        levels = {
            { text = "THE RULER REACHES FURTHER ACROSS THE PAGE",
              apply = function(t) t.snap.length = 135 end },
            { text = "A WIDER BAND COMES DOWN",
              apply = function(t) t.snap.width = 10 end },
            { text = "IT COMES DOWN HARDER",
              apply = function(t) t.snap.damage = 12 end },
            { text = "IT COSTS LESS INK TO SWING",
              apply = function(t) t.ink = 0.22 end },
            { text = "LONGER AND WIDER AGAIN",
              apply = function(t) t.snap.length, t.snap.width = 165, 13 end },
            -- The only number in the game measured off the screen rather than
            -- written down: half a diagonal reaches the corner of whatever
            -- shape of canvas the run ended up on, and the loadout recomputes
            -- it when the window changes shape.
            { text = "IT RULES THE WHOLE PAGE END TO END",
              apply = function(t, screen)
                  t.snap.length = math.ceil(util.len(screen.w, screen.h) / 2) + 8
              end },
        },
    },
    {
        id = "sharpener",
        name = "SHARPENER",
        icon = "sharpener",
        kind = "passive",
        levels = {
            { text = "YOUR AUTO SHOT COMES FASTER",
              apply = function(s) s.fireRate = s.fireRate * 0.88 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.fireRate = s.fireRate * 0.88 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.fireRate = s.fireRate * 0.88 end },
            { text = "AS FAST AS THE LEAD WILL GO",
              apply = function(s) s.fireRate = s.fireRate * 0.85 end },
        },
    },
    {
        id = "plane",
        name = "PAPER PLANE",
        icon = "plane",
        kind = "passive",
        levels = {
            { text = "YOU MOVE FASTER",
              apply = function(s) s.speed = s.speed * 1.08 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.speed = s.speed * 1.08 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.speed = s.speed * 1.08 end },
            { text = "OFF ACROSS THE PAGE",
              apply = function(s) s.speed = s.speed * 1.1 end },
        },
    },
    {
        -- Health is the one stat the player is handed the *difference* on the
        -- moment it changes, rather than having to go and find it: see
        -- Player:applyStats.
        id = "page",
        name = "FRESH PAGE",
        icon = "page",
        kind = "passive",
        levels = {
            { text = "+20 MAX HEALTH AND +20 BACK NOW",
              apply = function(s) s.maxHp = s.maxHp + 20 end },
            { text = "+20 MAX HEALTH AND +20 BACK NOW",
              apply = function(s) s.maxHp = s.maxHp + 20 end },
            { text = "+20 MAX HEALTH AND +20 BACK NOW",
              apply = function(s) s.maxHp = s.maxHp + 20 end },
            { text = "+30 MAX HEALTH AND +30 BACK NOW",
              apply = function(s) s.maxHp = s.maxHp + 30 end },
        },
    },
}

Upgrades.byId = {}
for _, up in ipairs(Upgrades.list) do
    Upgrades.byId[up.id] = up
end

return Upgrades
