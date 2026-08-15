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
        sun = nil,          -- see src/sun.lua
        cools = nil,        -- see src/cools.lua
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
-- run's copy of it exactly as before. The intended shape is five -- the unlock
-- and four upgrades -- and seven of them have their four written: the pencil,
-- the rubber, the highlighter, the gluestick, the pushpin, the ruler and the
-- compass. The pen and the stapler are unlock-only until someone writes them,
-- which the draft handles on its own by never offering a line with no level
-- left in it.
--
-- Four rather than six since the trim, and two rules picked which two went from
-- each line. The first was the flat ink discount, which every one of the seven
-- had a copy of and the blotter sells to all of them at once. The second was
-- whatever a passive already sold or a later level already overwrote -- the
-- compass's lap and a half against its two, the ruler's 135 against a length
-- the finale measures off the screen. Nothing that a finale stands on went:
-- the rubber keeps the 240 its ram is timed against.
--
-- `opts.start` marks a tool a run begins holding rather than has to draft. The
-- loadout takes the first level of any line carrying it before the run starts,
-- so a starting tool costs one of the four slots like any other.
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
            -- within a hair of the same place. A line five long cannot afford to
            -- say a thing twice, and "twice as fast" is a level you feel where
            -- "faster still" is a level you read.
            { text = "THE ORBIT TURNS TWICE AS FAST",
              apply = function(s) s.star.rate = s.star.rate * 2 end },
            -- The damage step went in the trim to five, and the graphite line
            -- is why it could: 4 through a maxed graphite (x1.2 x1.25 x1.3
            -- x1.4) is 10.9, which is the 11 this level used to write, so a run
            -- that wants the star cutting deeply can still buy exactly that --
            -- it just buys it from the passive that sells damage rather than
            -- from a level each weapon keeps a copy of. What is left is the
            -- count, which nothing else sells: one star, two, three.
            { text = "A THIRD STAR MAKES IT A TRIANGLE",
              apply = function(s) s.star.count = 3 end },
            -- The one that changes what the weapon *is*, and the one the line
            -- ends on: a ring only ever touches things at one distance, and a
            -- ring that breathes sweeps everything between two. It has ended
            -- the line through two trims now, which is the whole reason
            -- everything cut was cut from in front of it.
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
            -- the crowd. It sat fourth of nine and it sits third of five, which
            -- is the middle of the line -- the turn is worth reaching, and a run
            -- should not have to spend most of a line getting to it.
            { text = "THEY CARRY ON THROUGH WHAT THEY HIT",
              apply = function(s) s.rocket.pierce = 1 end },
            -- The damage step went in the trim to five, for the star's reason:
            -- 8 through a maxed graphite is 21.8, which clears a skull's 12
            -- twice over where this level only ever cleared it by one. A run
            -- that wants rockets landing harder buys the passive that sells
            -- damage to everything that fights for it.
            --
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
        -- The third passive weapon, and the one that is not about where the
        -- fight is. The stars guard the ring you stand in and the rocket goes
        -- out to whatever is nearest -- both go to the horde. The sun does not
        -- move at all: it comes up in a corner of the *screen*, burns whatever
        -- is under it, sinks and comes up somewhere else, and what a run does
        -- with it is fight in that corner while it is lit and leave when it
        -- goes. It is the one weapon you play around rather than aim, which is
        -- what makes it worth building next to two that both chase.
        --
        -- The disc is solid and hides what is under it, and that cost is the
        -- line's whole shape: every level makes the safe corner bigger, or
        -- brighter, or doubles it, and none of them makes it easier to see
        -- into. What comes out of the light carries a grey ghost of itself
        -- (Enemy:sunburn), and that mark is what the sun tells you about what
        -- it did in there.
        id = "sun",
        name = "SUN",
        icon = "sun",
        kind = "weapon",
        -- Drawn rather than issued, the way the star and the rocket are -- but
        -- the only one of the three where what you draw is part of the thing
        -- rather than all of it. The disc, its rim and its rays are sized by
        -- the levels below; the face laid over the middle is yours.
        design = "sun",
        levels = {
            {
                text = "A SUN RISES IN A CORNER AND BURNS WHAT IT COVERS",
                apply = function(s)
                    s.sun = {
                        -- How far it reaches into the page from the corner. A
                        -- quarter of the disc is what shows, so 60 covers about
                        -- a twentieth of a 320x180 page. The number is really an
                        -- angle rather than an area: you are always in the
                        -- middle of the screen and the horde always walks in at
                        -- you, so what a corner disc is worth is the slice of
                        -- the ways in that it blocks, and 60 out of the 184 to
                        -- the corner is a slice about forty degrees wide.
                        radius = 60,
                        -- 3 a tick is 6 a second, which is two thirds of what a
                        -- single star does to the one thing it touches -- and it
                        -- lands on everything in the corner at once. The sun is
                        -- deliberately the slowest killer in the game and the
                        -- widest, and the only one whose damage is not really
                        -- the point of it.
                        --
                        -- The number is also what keeps the bleach reachable. A
                        -- thing that stands under the disc for `soak` and is
                        -- still alive carries the mark out (Enemy:sunburn), so
                        -- the burn has to be slow enough that the heavy ones
                        -- live through two ticks of it -- which is why this line
                        -- has no level that burns past 5. A blob burns away
                        -- before it can be marked and a skull comes out
                        -- scorched, and that is the right way round.
                        damage = 3,
                        tick = 0.5,      -- seconds between one burn and the next
                        up = 0.7,        -- seconds coming up over the corner
                        stay = 5,        -- seconds at full height
                        down = 0.7,      -- and going back down
                        gap = 4,         -- seconds below the page before the next
                        swell = 0,       -- how far the disc breathes, in pixels
                        swellRate = 2.2,
                        corners = 1,
                        -- Two ticks under the disc before a thing is bleached
                        -- for good. Long enough that crossing a lit corner does
                        -- not do it and standing in one does, and short enough
                        -- that the things with the health to survive two ticks
                        -- are exactly the things that carry the mark out.
                        soak = 1,
                        rays = nil,      -- the finale, below
                    }
                end,
            },
            -- Deeper and for longer at once, because they are one idea -- more
            -- sun -- and because neither half is a level on its own. The burn
            -- stops at 5 for the reason above: 6 a tick clears a skull in two
            -- and nothing would ever walk out of the light carrying the mark.
            -- What is left to give is the clock, and 7 up against 3 down turns a
            -- corner that is sometimes lit into one that is usually lit.
            { text = "IT BURNS DEEPER AND HANGS ABOUT LONGER",
              apply = function(s)
                  s.sun.damage = 5
                  s.sun.stay = 7
                  s.sun.gap = 3
              end },
            -- One level for two changes, because they are one idea: the disc
            -- gets bigger and then refuses to sit still at its new size. Reach
            -- on its own would be a level you read rather than one you feel --
            -- the corner is already a corner -- and a pulse on the old radius
            -- would be decoration. Together they are the sun going from a shape
            -- in the corner to a thing burning in it.
            { text = "IT REACHES FURTHER AND PULSES AS IT BURNS",
              apply = function(s)
                  s.sun.radius = 80
                  s.sun.swell = 8
              end },
            -- The one that changes what the weapon *is*: up to here the sun is
            -- one lit corner at a time, and past it two are lit at once and
            -- there is a diagonal of burning page between them. Opposite
            -- corners rather than adjacent ones -- two along one edge would be
            -- a bar across the top of the page, and the whole point of the sun
            -- is that it is a corner.
            { text = "A SECOND SUN RISES IN THE OPPOSITE CORNER",
              apply = function(s) s.sun.corners = 2 end },
            -- The finale, and the only level that reaches off the disc: the
            -- rays it has been drawn with since the first level stop being
            -- decoration and start coming off. Each spoke stretches as the
            -- volley comes due and then leaves along the way it was pointing,
            -- so what crosses the page is the drawing itself rather than a
            -- second thing fired from behind it -- and the stretch is a warning
            -- you can read, which nothing else in the game gives.
            --
            -- 130px of flight is most of the way across the page from a corner,
            -- and 150 is quicker than the biro: a thing made of light should
            -- not be outrun. Nothing stops one -- it cuts each victim once and
            -- carries on -- because a ray that could be blocked by the first
            -- blob in the way would be twelve blobs' worth of nothing.
            { text = "SUNRAYS SHOOT OUT OF IT ACROSS THE PAGE",
              apply = function(s)
                  s.sun.rays = {
                      damage = 9,
                      every = 1.4,   -- seconds between one volley and the next
                      speed = 150,
                      length = 130,  -- how far one flies before it burns out
                  }
              end },
        },
    },
    {
        -- The fourth passive weapon, and the third answer to the question the
        -- other three answer between them. The stars hold the ring you are
        -- standing in, the rocket picks the one thing that matters, the sun owns
        -- a corner and waits -- and the cool S takes a straight line across the
        -- whole page and does not care what is on it.
        --
        -- Which makes it the only weapon with no relationship at all to where
        -- the enemies are. It is not aimed, it does not seek, and it will
        -- happily sail out over empty paper: what a run buys is a line drawn
        -- clean through the crowd at full damage, every single thing on it,
        -- however many that is. The line's whole shape is buying more chances
        -- for that line to be a good one -- more often, two at a time, and then
        -- three levels of refusing to leave the page.
        id = "cools",
        name = "COOL S",
        icon = "cools",
        kind = "weapon",
        -- Drawn rather than issued, like the other three -- though this is the
        -- one board where the drawing already exists and everybody is sure they
        -- know it. What the board is really offering is the argument about how
        -- it goes: where the middle line starts, which way the long diagonal
        -- leans, how sharp the points are.
        design = "cools",
        levels = {
            {
                text = "A COOL S FLOATS IN AND CUTS A LINE THROUGH WHERE YOU STAND",
                apply = function(s)
                    s.cools = {
                        -- Seven seconds, which is by a long way the slowest
                        -- thing in the game, and the price of what one of these
                        -- does: it comes in off the page, crosses the whole of
                        -- it through where you were standing, bounces and
                        -- crosses back, cutting every single thing on both
                        -- lines. That is more page swept in one arrival than a
                        -- star covers in ten seconds of turning, and it is
                        -- meant to be an event you watch rather than a rhythm
                        -- you stop noticing -- about one on the page at a time,
                        -- which is also what keeps a screen of them for the
                        -- levels that earn it.
                        every = 7,      -- seconds between one and the next
                        count = 1,
                        -- A little quicker than you walk, which is what makes it
                        -- float rather than fly: you can watch one cross, you can
                        -- walk a crowd into one, and at 320px of page it is on
                        -- screen for four or five seconds. Anything faster would
                        -- be a bullet, and there is already a bullet.
                        speed = 70,
                        accel = 0,      -- how hard it winds up as it goes
                        -- A blob or a bat outright and a skull in three. Lower
                        -- than the rocket's opening 8 because nothing stops one
                        -- of these: it goes through the whole crowd rather than
                        -- through the first thing it meets, and the rocket has
                        -- to buy that with a level.
                        damage = 5,
                        -- One from the start, because the edge of the page is
                        -- the only thing that ever ends one of these and a
                        -- weapon that crossed the page once was over before you
                        -- had read it. One bounce is a there and a back: it
                        -- cuts the line you were standing on, then cuts it
                        -- again from the other side.
                        bounces = 1,    -- edges of the page it will come off
                        ink = false,    -- and whether pen lines turn it too
                    }
                end,
            },
            { text = "ONE COMES IN TWICE AS OFTEN",
              apply = function(s) s.cools.every = 3.5 end },
            -- Opposite sides rather than two rolls of the dice: two random
            -- headings agree with each other about a third of the time, and two
            -- S's arriving side by side look like a bug rather than an upgrade.
            -- Both are aimed at the same spot, so the pair crosses through where
            -- you are standing and through each other. Struck about a random
            -- heading, so which way the pair comes is still nobody's decision.
            { text = "TWO COME IN AT ONCE, FROM OPPOSITE SIDES",
              apply = function(s) s.cools.count = 2 end },
            -- The one that changes how the weapon *feels* rather than what it
            -- does: it winds up as it goes, from a drift you can walk beside to
            -- something crossing the page faster than anything else in the
            -- game. 60 a second doubles its speed in a little over a second and
            -- has it at four times by the time it has crossed once.
            --
            -- Worth being straight about what this buys, because it is not
            -- damage: the line an S draws is the same line at any speed, and a
            -- fast one simply draws it sooner and leaves sooner. What it really
            -- fixes is the page walking off and leaving it -- one drifting at 70
            -- can be outrun by a player at 58 with the camera behind them, and
            -- one that has wound up cannot be. That, and it is the level that
            -- makes the thing look dangerous.
            { text = "IT PICKS UP SPEED THE FURTHER IT GOES",
              apply = function(s) s.cools.accel = 60 end },
            { text = "IT BOUNCES OFF THE EDGE OF THE PAGE A SECOND TIME",
              apply = function(s) s.cools.bounces = 2 end },
            -- The finale: your own pen lines turn it too. The pen is the one
            -- tool that leaves something solid (`wall` in src/tools.lua), so it
            -- is the one tool that can turn an S -- the ink an enemy has to walk
            -- around is the ink an S comes off -- which makes this level an
            -- instruction to go and draw the shape you want it running around
            -- inside. A pen box with the horde in it is the whole trick.
            --
            -- The third bounce goes with it rather than in a level of its own,
            -- and that is deliberate: a run that never drafted the pen would
            -- otherwise finish this line on a level that does nothing at all.
            -- Ink costs a bounce like the page does, so an S in a closed box
            -- still leaves eventually -- without that the weapon would stop
            -- being a thing that crosses the page and start being a thing that
            -- lives in a box.
            { text = "YOUR PEN LINES BOUNCE IT TOO, AND THE PAGE ONCE MORE",
              apply = function(s)
                  s.cools.bounces = 3
                  s.cools.ink = true
              end },
        },
    },
    {
        -- The fifth passive weapon, and the one that breaks the rule the other
        -- four are built on: it is aimed. A star turns where it turns, a rocket
        -- picks its own target, the sun owns whichever corner it came up in and
        -- a cool S arrives from a direction nobody chose -- all four fight while
        -- your hands are busy, and none of them asks you anything. This one
        -- fires down the line you are walking, so the half of the game you play
        -- with your feet is suddenly also how you shoot.
        --
        -- What it charges for that is the wind-up. A pointer turns with you at
        -- all times, and over the last stretch before each shot a one-pixel line
        -- flashes down the whole way the beam is about to go. The aim follows
        -- your feet through both and is latched at the shot, so the flash is a
        -- promise the beam keeps. None of it is a warning to the horde, which
        -- cannot read it -- it is a sight, and the weapon is really a question
        -- about whether you will turn and walk into the crowd to line it up.
        --
        -- The line the levels buy is about coverage rather than damage: sooner,
        -- for longer, and then more of the page at once -- the beam behind, and
        -- the whole cross. The one level that is neither is the pellets, which
        -- is the only answer in the game to a shooter's fire once it has left.
        id = "beam",
        name = "LASER BEAM",
        icon = "beam",
        kind = "weapon",
        -- The one weapon with no board behind it. Every other one hands you
        -- something to draw; this one is two lines, the pointer and the beam,
        -- both of them a length and a width these levels decide. There is
        -- nothing here a drawing could be.
        levels = {
            {
                text = "A BEAM FIRES DOWN THE LINE YOU ARE WALKING",
                apply = function(s)
                    s.beam = {
                        -- One beam to the next, wind-up included -- so this is
                        -- the number on the card rather than a gap you would
                        -- have to add the other two to. Slower than everything
                        -- but the cool S, because a beam covers half the page in
                        -- one go and you were told where it was going to land.
                        every = 5,
                        -- Long enough to read the flash, turn on it and still be
                        -- pointing where you meant when it goes. Much under half
                        -- a second and the sight is something you react to
                        -- rather than aim with; much over one and the weapon
                        -- spends more of its cycle promising than firing.
                        charge = 0.6,
                        -- A flash to start with: on the page for two or three
                        -- frames, which is exactly one tick of damage. The level
                        -- that holds it is where this number stops being a
                        -- formality.
                        hold = 0.15,
                        tick = 0.2,     -- seconds between one cut and the next
                        -- A blob or a bat outright and a skull in two. Higher
                        -- than the cool S's 5 because a beam is half the line an
                        -- S draws -- it leaves you rather than crossing the
                        -- whole page through you -- and because the S is not
                        -- something you had to walk into position for.
                        damage = 6,
                        -- Pixels across the band it cuts, and what it is drawn
                        -- at. Five rather than three because this is the one
                        -- thing in the game made of light rather than of biro:
                        -- at three it read as another pencil line laid across a
                        -- page already full of them, and the whole of what it
                        -- has to say from the far side of the screen is that it
                        -- is not one of your marks.
                        width = 5,
                        arms = 1,       -- ahead, behind, and then both sides
                        pellets = false, -- and whether it burns enemy fire
                    }
                end,
            },
            { text = "IT COMES ROUND TWICE AS OFTEN",
              apply = function(s) s.beam.every = 2.5 end },
            -- The one that changes what the weapon *is*. Up to here it is a
            -- flash that catches whatever the line was lying across at one
            -- instant, and past it the beam stands there for the best part of a
            -- second and cuts again every fifth of one -- so it stops being a
            -- thing you land on a crowd and starts being a thing the crowd has
            -- to walk through. It also makes the wind-up worth the wait: what
            -- the arrow is promising is now a place you can hold.
            { text = "THE BEAM HOLDS INSTEAD OF FLASHING",
              apply = function(s) s.beam.hold = 0.9 end },
            -- The horde arrives from every side, so the half of the page a
            -- single beam leaves behind it is the half you turned your back on.
            -- Firing out of both ends of the same line answers that without
            -- touching what the line is worth -- and it is what makes walking
            -- through a crowd rather than away from one a way to play.
            { text = "A SECOND BEAM FIRES OUT BEHIND YOU",
              apply = function(s) s.beam.arms = 2 end },
            -- The only thing in the game that answers a pellet already in the
            -- air. An eye's fire is the one pressure a pen wall cannot hold off
            -- (Game:updateEnemyShots) and until now the only reply was to kill
            -- the eye or take the hit; this is a third, and it is the one that
            -- suits the weapon -- a beam is already a line across the page, and
            -- what it does with fire crossing that line is burn it.
            --
            -- Fifth rather than last, because it is worth most to a run that has
            -- the beam standing still: a flash meets one pellet by luck, a held
            -- beam is a shutter across the whole line.
            { text = "IT BURNS ENEMY FIRE OUT OF THE AIR",
              apply = function(s) s.beam.pellets = true end },
            -- The finale, and the shape the line has been walking towards: the
            -- two sides come up with the two ends and the beam is a cross with
            -- you standing in the middle of it. Four quarters of the page open
            -- at once, and the aim stops being about which crowd to cut and
            -- starts being about how to stand in the crossing -- which is the
            -- level where a weapon you aim by walking becomes one you *place*.
            { text = "FOUR BEAMS AT ONCE, AHEAD BEHIND AND BOTH SIDES",
              apply = function(s) s.beam.arms = 4 end },
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
    -- Four tools is all a run may carry (Loadout.SLOTS), and the pencil is one
    -- of the four from the first frame -- so the draft is really offering three.
    -- That is the point of unlocking them: nine tools you can all reach is nine
    -- tools none of which you had to choose.
    -- The pencil's four. The tool every run holds from the first frame, so its
    -- line is the one line every run can finish -- which is why nothing in it
    -- changes what the pencil is: it stays the cheap ragged line you kill with
    -- by drawing over things, and the levels make drawing over things deeper,
    -- broader and cheaper the longer you draw.
    --
    -- The flat ink discount went in the trim to four, along with every other
    -- tool's: the blotter sells that axis to every tool at once, and a level
    -- each tool owns a copy of is a level none of them needs. What the pencil
    -- keeps is the discount no passive can sell -- one paid to a *style*.
    toolLine("pencil", "PENCIL", "pencil", "PENCIL",
        "A PENCIL. IT SCRATCHES WHATEVER YOU DRAW OVER", { start = true, levels = {
            -- 9 is a skull in two comfortable hits, which is the whole of what
            -- it has to be now that the crit that made 27 of it is gone.
            { text = "IT SCRATCHES DEEPER",
              apply = function(t) t.damage = 9 end },
            -- The point the tool row authored (src/tools.lua): three pixels of
            -- graphite instead of one, and double the reach to go with it.
            { text = "A BROADER POINT, PRESSED HARDER",
              apply = function(t)
                  t.radius = t.broad.radius
                  t.stamp = t.broad.stamp
              end },
            -- The level for the player who draws in cursive. The price per
            -- pixel eases towards half while the finger stays down and snaps
            -- back the moment it lifts -- the floor is the cap that keeps a
            -- lap of the page from becoming free pencil, and short deliberate
            -- strokes get nothing, which is the point: it pays a style, not a
            -- meter. Charged in Game:updateDrawing.
            { text = "THE LONGER THE LINE, THE LESS EACH PIXEL COSTS",
              apply = function(t) t.flow = { over = 150, floor = 0.5 } end },
            -- The finale is the most pencil thing in the game: a lasso. Close
            -- the line on itself and everything inside the ring takes the cut
            -- -- slight on purpose (a blob or a bat, a chip off a skull),
            -- because the ring costs nothing beyond the line you were already
            -- paying for and can be drawn around a whole crowd. It changes
            -- what the tool *is* the way a finale should: the pencil stops
            -- being only an edge you drag through things and becomes the one
            -- tool that can claim an area by drawing its border. Detection and
            -- the wiggle/spiral rules live in Stroke:tryCloseLoop.
            { text = "CLOSE THE LINE IN A LOOP: EVERYTHING INSIDE IS CUT",
              apply = function(t) t.loop = { damage = 4 } end },
        } }),
    toolLine("pen", "PEN", "pen", "PEN",
        "A PEN. ITS LINE IS A WALL THEY CANNOT CROSS"),
    -- The rubber's four. The tool is the shove -- the damage was always chip,
    -- and the chip level was the one that went -- so the line opens on the
    -- shove, spends its middle making the rub easier to deliver and cheaper to
    -- sustain, and ends by making the shove itself the weapon: what it throws
    -- knocks down what it lands on.
    toolLine("rubber", "RUBBER", "rubber", "RUBBER",
        "A RUBBER. IT SHOVES WHAT IT RUBS AT, HARD", { levels = {
            -- 165 to 240 is an 18px throw becoming 27 (the push decays at
            -- exp(-9t), so distance is force/9). It is also the launch speed
            -- the last level's ramming is measured off, which is why the line
            -- opens here: everything below stands on this number.
            { text = "THE SHOVE THROWS THEM FURTHER",
              apply = function(t) t.knock = 240 end },
            -- Up to here the rubber only works while the tip is travelling --
            -- hold it still and nothing happens. Now the tip itself keeps
            -- hitting where it rests, on the same 0.3s cadence as the rub, so
            -- pinning something against a corner stops needing the wrist: you
            -- lean on it instead of scrubbing at it. Not free: each resting
            -- hit is priced as nine pixels of rub -- about five seconds of
            -- leaning on a full meter -- so this is the *cheap sustained*
            -- option against the scrub's expensive burst, not a way around
            -- the meter.
            { text = "NO SCRUB NEEDED: LEAN IT ON THEM AND IT SHOVES",
              apply = function(t) t.lean = { px = 9 } end },
            -- Half price over ground this stroke has already covered
            -- (Stroke:revisits), which is most of what a rub is: the second
            -- and every later pass over the patch you are working at. Dragging
            -- the rubber somewhere new pays full price the whole way there, so
            -- the discount rewards rubbing harder, not roaming further.
            { text = "SCRUBBING THE SAME PATCH COSTS HALF THE INK",
              apply = function(t) t.scrub = 0.5 end },
            -- The finale. Anything this shove sends flying shoves and damages
            -- whatever it runs into while it is still truly flying -- about a
            -- fifth of a second and twenty pixels off the upgraded throw
            -- (Game:updateRams) -- so a rub delivered into the front of a
            -- crowd bowls the front rank through the second. 5 is a blob dead
            -- on arrival; the victims are shoved on but never become
            -- projectiles themselves, one rub being one volley, not a chain.
            { text = "WHAT IT SENDS FLYING KNOCKS DOWN WHAT IT HITS",
              apply = function(t) t.ram = { damage = 5 } end },
        } }),
    -- The highlighter's four. The band is a surface that keeps hurting, so the
    -- line is about the band -- how much page it covers, how hard each tick
    -- lands, what happens where the passes cross -- and it ends on the one
    -- level that lets the damage off the band entirely. How long it sits went
    -- in the trim: the fixative sells life to everything that has one.
    toolLine("highlighter", "MARKER", "marker", "HIGHLIGHTER",
        "A HIGHLIGHTER. WHAT IT COVERS KEEPS BURNING", { levels = {
            -- The band grows from 9px of nib to 13, and the hit reach grows
            -- with it. The fatter nib itself is authored on the tool row
            -- (src/tools.lua) -- this level only says the band gets it.
            { text = "A WIDER BAND COMES OFF THE NIB",
              apply = function(t)
                  t.radius = t.broad.radius
                  t.stamp, t.edge = t.broad.stamp, t.broad.edge
              end },
            -- 5 is a blob's 4 in one tick instead of two: the band stops being
            -- something chaff walks across and starts being something it dies
            -- standing on.
            { text = "IT BURNS DEEPER",
              apply = function(t) t.damage = 5 end },
            -- The level that gives drawing over your own band a point. Each
            -- separate pass of the stroke lying over an enemy is a layer and
            -- the tick lands once per layer, up to three -- so scrubbing a
            -- patch triples the burn where the passes cross, and the cap is
            -- what keeps a tight scribble from being a one-stroke pushpin.
            { text = "LAYERS STACK WHERE YOU DRAW OVER YOUR OWN INK",
              apply = function(t) t.stack = 3 end },
            -- The finale takes the one thing the tool could never do -- hurt
            -- something that kept walking -- and buys exactly that: touching
            -- the band at all sets an enemy alight for two seconds, and the
            -- fire leaves the page with it. Checked every frame rather than on
            -- the tick (Game:updateBurning), because a bat crosses the band in
            -- less time than a tick and "crossed it" is the point.
            { text = "WHAT TOUCHES THE BAND CATCHES FIRE",
              apply = function(t) t.ignite = { time = 2, tick = 0.4, damage = 2 } end },
        } }),
    -- The gluestick's four. The tool deals nothing and shoves nothing -- that is
    -- its whole identity, and the line keeps it: the smear never hurts what it
    -- holds. It opens by making the hold wider and then gives it teeth that all
    -- point outwards -- everything else cuts deeper into what is stuck, coming
    -- loose is what costs, and the last level stops the crowd having to be
    -- caught at all. Longer and cheaper went in the trim; the fixative and the
    -- blotter sell both.
    toolLine("gluestick", "GLUESTICK", "glue", "GLUESTICK",
        "A GLUESTICK. WHATEVER IT SMEARS STOPS DEAD", { levels = {
            -- The fatter head authored on the tool row (src/tools.lua), the
            -- way the pencil's and the highlighter's are.
            { text = "A WIDER SMEAR COMES OFF THE STICK",
              apply = function(t)
                  t.radius = t.broad.radius
                  t.stamp, t.edge = t.broad.stamp, t.broad.edge
              end },
            -- The crowd-control payoff written as a number: glue plus pencil
            -- was always the combination, and half again on everything that
            -- lands makes it official. A broad pencil's 9 becomes 13.5 -- past
            -- a skull -- while the compass's 7 becomes 10.5 and still cannot
            -- touch a tank, which its design depends on. Carried on the enemy
            -- while it is stuck (Enemy:hurt), so every source of damage gets
            -- the bonus without knowing it.
            { text = "WHAT IT HOLDS TAKES DEEPER CUTS",
              apply = function(t) t.soften = 1.5 end },
            -- The first damage in the line, and the glue still is not dealing
            -- it: coming loose is. 4 is a blob exactly -- chaff the smear held
            -- never walks away from it -- paid once when the hold ends,
            -- however long it lasted (Game:updateGlue).
            { text = "WHAT COMES LOOSE COMES AWAY TORN",
              apply = function(t) t.tear = 4 end },
            -- The finale turns a patch of page into a field: everything free
            -- within reach of the smear is dragged towards the ink. The speed
            -- is the level -- between a skull's legs and a bat's -- so the
            -- heavy things cannot walk out of the field, the fast things can,
            -- and the smear sorts the crowd it was thrown into.
            { text = "THE SMEAR PULLS EVERYTHING NEAR IT IN",
              apply = function(t) t.pull = { range = 26, speed = 30 } end },
        } }),
    -- The pushpin's four. The tool is one big expensive decision -- a fall
    -- everyone can see coming, a crater that kills everything but the toughest
    -- thing, and that thing pinned -- and the line pays the three skills a
    -- tapped tool has: where the point lands, when the crowd is thickest, and
    -- whether the spot deserves the biggest single spend in the game.
    --
    -- Two levels are deliberately absent. Nothing shortens the fall: it is
    -- the bat's eleven pixels of head start, this tool's compass-turn, and
    -- paying it away would delete the counterplay. And nothing raises the
    -- crater's 10: one short of a skull is the whole design, so the only
    -- deeper hits in the line are the two that have to be earned -- the aimed
    -- point and the crowded crater.
    toolLine("pushpin", "PUSHPIN", "pushpin", "PUSHPIN",
        "A PUSHPIN. TAP AND IT PUNCHES A HOLE IN THEM", { levels = {
            -- The hold first, because the hold is what the tool really is:
            -- the crater clears the chaff, but the pinned tank is the design.
            -- Its life is the same number written twice (src/tools.lua) and
            -- the two have to stay together.
            { text = "IT PINS THEM DOWN FOR LONGER",
              apply = function(t) t.drop.freeze, t.drop.life = 4, 4 end },
            -- 41px of crater to 51 -- still well under the compass, which is
            -- the tool that owns "the biggest area in the game".
            { text = "A WIDER CIRCLE COMES DOWN",
              apply = function(t) t.drop.radius = 25 end },
            -- The compass's bite fallen from above: the one body the point
            -- itself comes down on takes double. 20 kills a skull or an eye
            -- outright -- the crater still can't, and never will -- and the
            -- window is the enemy plus two pixels of slack through a
            -- quarter-second fall, so it is a shot you have to mean
            -- (Pin:land).
            { text = "THE POINT BITES DOUBLE WHAT IT FALLS ON",
              apply = function(t) t.drop.point = 2 end },
            -- The finale: the landing is the game's one instantaneous area
            -- hit, so it is the one place a crowd converts into depth. Every
            -- kill under the circle is weight behind the point, taken by the
            -- survivors as a second hit -- one kill finishes a skull that
            -- took the crater, two an eye -- while a pin dropped on a *lone*
            -- skull changes nothing at all: "anything that killed outright
            -- would leave the pinning with nothing to pin" stands in the base
            -- case, and the exception is earned through the crowd standing
            -- round it. See Pin:land.
            { text = "WHAT THE CRATER KILLS DRIVES THE POINT DEEPER",
              apply = function(t) t.drop.drive = 2 end },
        } }),
    toolLine("stapler", "STAPLER", "stapler", "STAPLER",
        "A STAPLER. TAP AND IT FASTENS ONE TO THE PAGE"),
    -- The compass's four, and every one of them is about the journey the leg
    -- makes rather than about the circle being bigger or the number being
    -- higher: where on the turn it bites, how many turns there are, and how many
    -- legs are making them. Nothing here shortens `turn`, which would be the
    -- obvious level and the wrong one -- the far side of a circle having most of
    -- a second to walk out is the tool, not a flaw in it.
    toolLine("compass", "COMPASS", "compass", "COMPASS",
        "A COMPASS. IT CUTS A CIRCLE ROUND THEM", { levels = {
            -- Wider is straightforwardly better here, unlike everywhere else:
            -- the leg takes the same 0.8s round however wide the circle is, so
            -- opening it out buys page without buying the horde any more time.
            { text = "IT OPENS OUT WIDER",
              apply = function(t) t.sweep.maxR = 66 end },
            -- The level that gives the drag a second job. Up to here the
            -- direction you dragged in only said which part of the circle got
            -- cut first, which mattered to nobody; now it says which part gets
            -- cut twice as deep, and 14 over that sixth of the turn is a skull
            -- with two left.
            { text = "THE LEAD BITES DOUBLE WHERE IT SETS OFF",
              apply = function(t) t.sweep.bite = 2 end },
            -- Both at once, because the pair is one idea: a second full lap is
            -- only worth waiting 1.6s for if what it comes round to is worth
            -- being cut by. 12 is the skull's health exactly -- the biggest area
            -- in the game stops being unable to touch a tank.
            { text = "TWICE ROUND, AND IT CUTS FAR DEEPER",
              apply = function(t) t.sweep.laps, t.sweep.damage = 2, 12 end },
            -- The finale changes the shape of the attack rather than its
            -- numbers. Two legs from the same rest point, going opposite ways
            -- and meeting on the far side, so a lap closes in half the time
            -- without the arm moving any faster -- two laps of it come to the
            -- same one turn's worth of waiting a single leg used to spend on
            -- one. There is nowhere left on the rim that is a safe place to be
            -- standing, which is what the far side used to be.
            { text = "A SECOND LEG COMES ROUND THE OTHER WAY",
              apply = function(t) t.sweep.counter = true end },
        } }),
    -- Everything in the ruler's is a number in its own snap block
    -- (src/tools.lua) rather than a stat about you, which is what makes a tool
    -- line a different kind of upgrade: it is worth nothing at all unless you
    -- spent one of your four slots on the tool first.
    toolLine("ruler", "RULER", "ruler", "RULER",
        "A RULER. IT COMES DOWN AND CLEARS A LANE", { levels = {
            { text = "A WIDER BAND COMES DOWN",
              apply = function(t) t.snap.width = 10 end },
            { text = "IT COMES DOWN HARDER",
              apply = function(t) t.snap.damage = 12 end },
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
