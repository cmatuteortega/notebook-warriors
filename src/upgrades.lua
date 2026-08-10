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
        regen = 0,          -- health a second, healed back on its own
        fireRate = 1,       -- multiplier on the auto-shot's interval: lower is faster
        damage = 1,         -- multiplier on everything that hits
        toolDamage = 1,     -- ... and on what you draw with, on top of it
        passiveDamage = 1,  -- ... and on what fights for you, on top of it
        magnet = 26,        -- how far off a gem starts coming to you, in pixels
        xpGain = 1,         -- multiplier on what a gem is worth once it arrives

        -- The meter, in three parts, because they are three different things:
        -- how much ink you can hold, how fast it comes back, and how far it
        -- goes. A bigger well does not refill any faster -- that is the whole
        -- trade it makes -- and cheaper ink is worth having whether the well is
        -- big or small.
        inkMax = 1,         -- what a full meter holds
        inkRegen = 1,       -- multiplier on Tools.REGEN
        inkDelay = 1,       -- multiplier on Tools.DELAY: lower starts sooner
        inkCost = 1,        -- multiplier on what every tool charges

        -- How long what you put on the page goes on working: a mark's life, and
        -- the hold a mark has on whatever it caught. The two travel together
        -- because they are the same idea read off either end -- a glue smear
        -- that lasts longer sticks things down for longer by definition.
        markLife = 1,
        knock = 1,          -- multiplier on the shove a mark gives

        star = nil,         -- see src/orbital.lua
        rocket = nil,       -- see src/rocket.lua
    }
end

-- The two damage lines are the same line twice, pointed at the two halves of
-- the game: what you draw and what draws itself. The percentages climb rather
-- than repeat, so the last level of either is worth twice the first and the
-- choice stays live all the way up.
--
-- Four steps rather than five, and the opening one moved up from 15% to 20% to
-- pay for it. Both of those are the same decision: these were the longest
-- passive lines in the draft and the pool they are drawn from is now fifteen
-- lines deep, so a run is far less likely to finish either -- which makes what a
-- single pick is worth matter more than what the full line is worth. The end of
-- the line comes down from 3.14x to 2.73x, which is the price of the first pick
-- being worth a third more than it was.
local function sharpen(field, percent)
    return function(s) s[field] = s[field] * (1 + percent / 100) end
end

local RISING = { 20, 25, 30, 40 }

-- A tool line, which is the one shape of line that opens by handing you
-- something rather than by changing a number.
--
-- Its first level is the *unlock*: taking it puts the tool on the strip, and
-- there is nothing to apply because the tool turning up is the whole of the
-- upgrade. Which is why the loadout can read "is this tool equipped" straight
-- off `levelOf(line) > 0` and no tool needs a flag of its own saying so.
--
-- Everything after the unlock is that tool getting better, and is handed the
-- run's copy of it exactly as before. The intended shape is seven -- the unlock
-- and six upgrades -- and only the ruler has its six written; the rest are
-- unlock-only until someone writes them, which the draft handles on its own by
-- never offering a line with no level left in it.
--
-- `opts.start` marks a tool a run begins holding rather than has to draft. The
-- loadout takes the first level of any line carrying it before the run starts,
-- so a starting tool costs one of the three slots like any other.
-- `opts.levels` is everything after the unlock.
local function toolLine(id, name, icon, tool, unlock, opts)
    opts = opts or {}

    local levels = { { text = unlock, apply = function() end } }
    for _, level in ipairs(opts.levels or {}) do
        levels[#levels + 1] = level
    end

    return {
        id = id, name = name, icon = icon,
        kind = "tool", tool = tool,
        start = opts.start,
        levels = levels,
    }
end

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
            -- One step where there used to be two, x1.45 and then x1.4, landing
            -- within a hair of the same place. A line six long cannot afford to
            -- say a thing twice, and "twice as fast" is a level you feel where
            -- "faster still" is a level you read.
            { text = "THE ORBIT TURNS TWICE AS FAST",
              apply = function(s) s.star.rate = s.star.rate * 2 end },
            -- The two damage steps folded the same way, 4 straight to 11. All
            -- the pair ever bought between them was a skull in two instead of a
            -- skull in three, and one level buys that on its own.
            { text = "THE STARS CUT FAR DEEPER",
              apply = function(s) s.star.damage = s.star.damage + 7 end },
            { text = "A THIRD STAR MAKES IT A TRIANGLE",
              apply = function(s) s.star.count = 3 end },
            -- The one that changes what the weapon *is*, and now the one the
            -- line ends on: a ring only ever touches things at one distance,
            -- and a ring that breathes sweeps everything between two. It was
            -- the sixth level before the trim and it is the sixth level after
            -- it, which is the whole reason the other four were the ones to go.
            { text = "THE ORBIT SWELLS AND SHRINKS AS IT TURNS",
              apply = function(s) s.star.breathe = 11 end },
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
            { text = "TWO GO UP AT ONCE",
              apply = function(s) s.rocket.count = 2 end },
            -- The one that changes what the weapon *is*: up to here a rocket is
            -- one enemy's problem, and past it a volley is a line drawn through
            -- the crowd. It sat fourth of nine and it sits third of six, which
            -- is nearer the middle of the line than it was -- the turn is worth
            -- reaching, and a run should not have to spend two thirds of a line
            -- getting to it.
            { text = "THEY CARRY ON THROUGH WHAT THEY HIT",
              apply = function(s) s.rocket.pierce = 1 end },
            -- 13, which is one more than a skull has, and the last damage
            -- number in this line that means anything: nothing in the game has
            -- more than 12 health, so a rocket that has closed that gap has
            -- closed it, and the old ninth level taking it on to 20 was buying
            -- overkill against a thing already dead. The line stops on the
            -- number that does something.
            { text = "THEY GO OFF HARDER",
              apply = function(s) s.rocket.damage = s.rocket.damage + 5 end },
            -- Both rate steps at once, 1.9 straight to 1. Same reasoning as the
            -- stars: two levels that each shave a fraction off a timer are one
            -- level that halves it.
            { text = "THEY COME UP TWICE AS OFTEN",
              apply = function(s) s.rocket.every = 1 end },
            -- The finale does two things because the two are one idea -- three
            -- rockets fanned, each going through four -- and a volley is what
            -- the line has been building towards since the pierce level.
            { text = "THREE GO UP AT ONCE, THROUGH FOUR THINGS EACH",
              apply = function(s)
                  s.rocket.count = 3
                  s.rocket.pierce = 3
              end },
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
    {
        -- The magnet's other half, and the reason the two are separate lines:
        -- the magnet changes how far a gem comes, this changes what it is worth
        -- when it arrives. Which makes this the only line in the game that
        -- changes the *pace* of a run rather than anything inside it -- every
        -- other upgrade makes the run you are having better, and this one gets
        -- you to the next draft sooner.
        id = "topmarks",
        name = "TOP MARKS",
        icon = "tick",
        kind = "passive",
        levels = {
            { text = "EVERY GEM IS WORTH MORE EXPERIENCE",
              apply = function(s) s.xpGain = s.xpGain * 1.15 end },
            { text = "WORTH MORE AGAIN",
              apply = function(s) s.xpGain = s.xpGain * 1.15 end },
            { text = "WORTH MORE AGAIN",
              apply = function(s) s.xpGain = s.xpGain * 1.15 end },
            { text = "FULL MARKS FOR EVERYTHING YOU PICK UP",
              apply = function(s) s.xpGain = s.xpGain * 1.2 end },
        },
    },
    risingLine("scissors", "SCISSORS", "scissors", "toolDamage", "WHAT YOU DRAW"),
    risingLine("graphite", "GRAPHITE", "graphite", "passiveDamage", "WHAT FIGHTS FOR YOU"),
    -- The tool lines. One per row of Tools.list, and every one of them opens
    -- with the tool itself: you do not start a run holding the strip, you start
    -- it holding a pencil, and everything else has to be drafted.
    --
    -- Three tools is all a run may carry (Loadout.SLOTS), and the pencil is one
    -- of the three from the first frame -- so the draft is really offering two.
    -- That is the point of unlocking them: nine tools you can all reach is nine
    -- tools none of which you had to choose.
    toolLine("pencil", "PENCIL", "pencil", "PENCIL",
        "A PENCIL. IT SCRATCHES WHATEVER YOU DRAW OVER", { start = true }),
    toolLine("pen", "PEN", "pen", "PEN",
        "A PEN. ITS LINE IS A WALL THEY CANNOT CROSS"),
    toolLine("rubber", "RUBBER", "rubber", "RUBBER",
        "A RUBBER. IT SHOVES WHAT IT RUBS AT, HARD"),
    toolLine("highlighter", "MARKER", "marker", "HIGHLIGHTER",
        "A HIGHLIGHTER. WHAT IT COVERS KEEPS BURNING"),
    toolLine("gluestick", "GLUESTICK", "glue", "GLUESTICK",
        "A GLUESTICK. WHATEVER IT SMEARS STOPS DEAD"),
    toolLine("pushpin", "PUSHPIN", "pushpin", "PUSHPIN",
        "A PUSHPIN. TAP AND IT PUNCHES A HOLE IN THEM"),
    toolLine("stapler", "STAPLER", "stapler", "STAPLER",
        "A STAPLER. TAP AND IT FASTENS ONE TO THE PAGE"),
    toolLine("compass", "COMPASS", "compass", "COMPASS",
        "A COMPASS. IT CUTS A CIRCLE ROUND THEM"),
    -- The one tool with its six written. Everything in them is a number in the
    -- ruler's own snap block (src/tools.lua) rather than a stat about you, which
    -- is what makes a tool line a different kind of upgrade: it is worth nothing
    -- at all unless you spent one of your three slots on the tool first.
    toolLine("ruler", "RULER", "ruler", "RULER",
        "A RULER. IT COMES DOWN AND CLEARS A LANE", { levels = {
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
        } }),
    -- The three ink lines. Everything you draw is paid for out of one meter and
    -- nothing else in the draft touches it, so a run that has committed to
    -- drawing has three separate places to put a level -- and they are genuinely
    -- three, not one written out three ways: how much you can hold, how fast it
    -- comes back, and how far it goes.
    {
        -- Capacity, and only capacity. The meter refills at the same rate it
        -- always did, so a bigger well takes proportionally longer to fill from
        -- empty: what this buys is a longer line in one go, or one more pin
        -- before you have to stop, and not more ink per minute. That is the
        -- cartridge's job below, and keeping the two apart is what stops either
        -- of them being the obvious pick.
        --
        -- The room is handed over full, for the same reason a fresh page hands
        -- its health over full: a bigger meter you then have to go and stand
        -- still to fill is not a reward, it is homework.
        id = "inkwell",
        name = "INKWELL",
        icon = "inkwell",
        kind = "passive",
        levels = {
            { text = "+30 INK IN THE WELL, AND +30 IN IT NOW",
              apply = function(s) s.inkMax = s.inkMax + 0.3 end },
            { text = "+30 INK IN THE WELL, AND +30 IN IT NOW",
              apply = function(s) s.inkMax = s.inkMax + 0.3 end },
            { text = "+30 INK IN THE WELL, AND +30 IN IT NOW",
              apply = function(s) s.inkMax = s.inkMax + 0.3 end },
            { text = "+40 INK IN THE WELL, AND +40 IN IT NOW",
              apply = function(s) s.inkMax = s.inkMax + 0.4 end },
        },
    },
    {
        -- Throughput. Two numbers rather than one, and the line alternates
        -- between them, because the pause before the meter starts refilling is
        -- felt quite differently from the rate it refills at -- the delay is
        -- what you notice dabbing at the page with a stapler, and the rate is
        -- what you notice halfway through a long pen wall.
        id = "cartridge",
        name = "CARTRIDGE",
        icon = "cartridge",
        kind = "passive",
        levels = {
            { text = "INK COMES BACK FASTER",
              apply = function(s) s.inkRegen = s.inkRegen * 1.3 end },
            { text = "AND STARTS COMING BACK SOONER",
              apply = function(s) s.inkDelay = s.inkDelay * 0.5 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.inkRegen = s.inkRegen * 1.3 end },
            { text = "THE NIB NEVER RUNS DRY",
              apply = function(s)
                  s.inkRegen = s.inkRegen * 1.35
                  s.inkDelay = s.inkDelay * 0.4
              end },
        },
    },
    {
        -- Price. The one of the three that is worth exactly as much to a run
        -- drawing pencil lines as to a run tapping out staples, since it is a
        -- multiplier on whatever the tool in your hand happens to charge.
        --
        -- It lands after every tool's own upgrades, the way the damage
        -- multipliers do (src/loadout.lua), so it discounts the ruler you have
        -- rather than the ruler you started with -- including the ruler level
        -- that already set its price down to 0.22.
        id = "blotter",
        name = "BLOTTER",
        icon = "blotter",
        kind = "passive",
        levels = {
            { text = "EVERYTHING YOU DRAW COSTS LESS INK",
              apply = function(s) s.inkCost = s.inkCost * 0.88 end },
            { text = "LESS AGAIN",
              apply = function(s) s.inkCost = s.inkCost * 0.88 end },
            { text = "LESS AGAIN",
              apply = function(s) s.inkCost = s.inkCost * 0.88 end },
            { text = "NOTHING SOAKS INTO THE PAGE UNUSED",
              apply = function(s) s.inkCost = s.inkCost * 0.85 end },
        },
    },
    {
        -- Not how hard a mark hits or what it costs, but how long it goes on
        -- working -- which is the one thing about the drawing half of the game
        -- that the scissors and the blotter between them still cannot touch.
        --
        -- It is worth the most to the tools that do no damage at all: the pen
        -- wall you drew in a panic outlives the panic by twice as much, and the
        -- gluestick's smear holds what it caught for twice as long. See
        -- Loadout:rebuild for exactly which numbers move -- a ruled line the
        -- ruler leaves behind is not one of them, because it has already done
        -- everything it is going to do.
        id = "fixative",
        name = "FIXATIVE",
        icon = "fixative",
        kind = "passive",
        levels = {
            { text = "WHAT YOU DRAW LASTS LONGER AND HOLDS LONGER",
              apply = function(s) s.markLife = s.markLife * 1.2 end },
            { text = "LONGER AGAIN",
              apply = function(s) s.markLife = s.markLife * 1.2 end },
            { text = "LONGER AGAIN",
              apply = function(s) s.markLife = s.markLife * 1.2 end },
            { text = "IT SETS ON THE PAGE AND STAYS SET",
              apply = function(s) s.markLife = s.markLife * 1.25 end },
        },
    },
    {
        -- The shove, which until now nothing pointed at. Three tools have one
        -- and they are the three the line is for: the ruler, whose knock is the
        -- whole tool -- 8 damage clears the chaff but it is the shove that opens
        -- a corridor across the page through the middle of the horde -- the
        -- rubber, and the compass, which drags what it catches round the circle
        -- rather than out of it.
        --
        -- A multiplier and not an addition, deliberately. The pen, the
        -- highlighter and the gluestick are all written with a knock of 0
        -- because not shoving is the point of them: a wall that pushed things
        -- away from it would not be a wall, and glue that shoved would not be
        -- glue. Multiplying leaves all three at 0, where adding would quietly
        -- hand a shove to the three tools designed around not having one.
        --
        -- Which does mean this is a passive that behaves like a tool line: a run
        -- drawing pen walls gets nothing from it at all. That is the same trade
        -- the scissors make against a run that only fights with what it was
        -- given, and it is a fair one as long as the draft is deep enough to
        -- offer somewhere else to put the level.
        id = "elastic",
        name = "ELASTIC BAND",
        icon = "elastic",
        kind = "passive",
        levels = {
            { text = "WHAT YOU DRAW THROWS THINGS FURTHER",
              apply = function(s) s.knock = s.knock * 1.25 end },
            { text = "FURTHER AGAIN",
              apply = function(s) s.knock = s.knock * 1.25 end },
            { text = "FURTHER AGAIN",
              apply = function(s) s.knock = s.knock * 1.25 end },
            { text = "NOTHING STAYS WHERE YOU HIT IT",
              apply = function(s) s.knock = s.knock * 1.35 end },
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
    {
        -- The other half of the fresh page, and the half the run did not have:
        -- a bigger bar is worth nothing once it is empty, and until this line
        -- existed nothing in the game put health back at all. A fresh page is
        -- room to take another hit, and this is the only way to un-take one.
        --
        -- Deliberately slow. At the top of the line it is a skull's worth of
        -- damage back every seven seconds, which is sustain between waves rather
        -- than anything you can stand in a crowd and rely on -- the moment it
        -- outruns what is hitting you it stops being an upgrade and starts being
        -- the end of the run's difficulty.
        id = "tape",
        name = "SELLOTAPE",
        icon = "tape",
        kind = "passive",
        levels = {
            { text = "TORN PAGES MEND: YOU HEAL AS YOU GO",
              apply = function(s) s.regen = s.regen + 0.4 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.regen = s.regen + 0.4 end },
            { text = "FASTER AGAIN",
              apply = function(s) s.regen = s.regen + 0.4 end },
            { text = "THE TEAR CLOSES BEHIND YOU",
              apply = function(s) s.regen = s.regen + 0.6 end },
        },
    },
}

Upgrades.byId = {}
for _, up in ipairs(Upgrades.list) do
    Upgrades.byId[up.id] = up
end

return Upgrades
