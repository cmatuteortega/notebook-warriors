local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Walls = require("src.walls")
local Sfx = require("src.sfx")
local pixelart = require("src.pixelart")
local util = require("src.util")

local Enemy = {}
Enemy.__index = Enemy

-- Every point of damage that has ever gone through Enemy:hurt, added up. It
-- belongs to the module and not to a monster -- nothing on an enemy reads it --
-- and there is exactly one thing in the game that wants it: the bandaid takes a
-- cut of what the run's own weapons dealt, and the honest way to know that number
-- is to read this either side of the passes that are the run's fire (Game:update,
-- Loadout:mend). Which works because every hit in the game arrives through one
-- door, so there is one place to count and nothing to keep in step.
Enemy.dealt = 0

local WALL_LOOK = 7  -- how far outside its clearance a wall starts to be felt
local SLIDE_HOLD = 0.9 -- how long a chosen way round a wall is kept to
local SLIP_CARRY = 0.5 -- how long footing stays lost after leaving the wax

-- What a hit looks like on the thing that took it. Two things happen at once
-- and they are one effect: the body blows out to paper and drops back through
-- blush, wearing a red rim for the whole of it, and it kicks a few pixels
-- backwards and slides home again.
--
-- Neither of them is worth a number on the row (Enemy.types). A hit on a paper
-- clip and a hit on the boss are the same event -- something landed -- and a
-- boss that flinched less would read as a boss that was not hit rather than as
-- a boss that is heavy. What says how much it was worth is the number the page
-- throws (src/damage.lua); this says *that* it happened, and it says it the
-- same way every time so it can be read out of the corner of an eye in a crowd
-- of two hundred.
--
-- The whole thing is over in about a tenth of a second, which is the point: at
-- the rate this game hands out hits, anything longer and a thing under sustained
-- fire never comes back off the ramp, and a permanent white monster with a red
-- edge is not a hit -- it is a palette swap.
local HIT_FLASH = 0.14      -- how long the silhouette is lit for
local HIT_WHITE = 0.06      -- of which this much is the blown-out paper stage
local HIT_BUMP = 3          -- how far back it is knocked, in pixels
local HIT_BUMP_TIME = 0.12  -- and how long it takes to slide home

-- How long out of the sun before what it has already soaked up is forgotten.
-- Comfortably longer than the sun's own burn tick, so a thing standing under
-- the disc goes on adding up between one burn and the next, and shorter than a
-- walk across the page, so crossing a lit corner twice in a run is not the same
-- as standing in one.
local SOAK_COOL = 1.2

-- The boss's pupil: a disc slid across the iris towards the player rather than
-- a pixel of the sprite, which is why the art has no pupil in it. The eye is the
-- one enemy in the game whose sprite says which way it is facing, and a boss you
-- are running away from ought to be watching you do it.
local PUPIL_R = 4
local PUPIL_SLIDE = 5 -- how far off centre it may sit: the iris is 19 across
                      -- and the pupil is 9, so at 5 it still clears the rim
local PUPIL_TURN = 6  -- how fast it swings across, in fractions per second --
                      -- an eye tracks smoothly, it does not snap

-- Add a row here to add a monster; the spawner picks from this table by name.
-- Every row walks at the player, and every block below is a way of not *only*
-- doing that. None of them is a special case anywhere else in the game: each is
-- read in one place, and a row without it is the row this game shipped with.
--
-- **`name`** is the one field on a row that nothing in a run ever reads. It is
-- what the *book* calls the thing, for the one screen that names monsters out
-- loud (src/challenges.lua, where a row is one body count a homework list is
-- kept of) -- so a new monster brings its own line of homework with it and there
-- is no second list of what the horde is made of to keep in step. Written here
-- in English, like every other string in the game, and translated at the draw
-- (src/i18n.lua).
--
-- **`shot`** makes it a shooter. It still walks at the player like the rest, but
-- every `every` seconds, if the player is within `range`, it spits a pellet
-- (Game:updateEnemyShots) that flies at `speed` and hits for `damage`. `spread`
-- and `arc` make it a volley: `spread` pellets fanned across `arc` radians
-- instead of the one straight down the line.
--
-- **`keep`** stops it walking all the way in. Past `at` it closes like anything
-- else; inside `at` it circles; inside `back` it retreats. Only a shooter has any
-- use for one, and what it buys is the difference between a shooter you meet
-- because it came to you and a shooter you have to go and get (Enemy:update).
--
-- **`charge`** makes it commit. Every `every` seconds, with the player inside
-- `range`, it stands still for `wind` seconds wearing a red outline, then runs
-- `time` seconds down the heading it locked *at the start of the wind* at
-- `speed`, then stands `rest` seconds getting its breath. The heading is stale
-- on purpose: the whole attack is dodgeable by stepping aside during the wind,
-- and it is the only thing in the game that asks for a decision inside half a
-- second rather than over several.
--
-- **`split`** makes it two problems. When it dies it leaves `count` of `into`
-- thrown `spread` pixels out (Game:splitEnemy), carrying the parent's own
-- difficulty scale rather than the run's current one -- what came off a monster
-- is as hard as the monster was. `blown` is the one exception and is optional:
-- what a *blow-up* of the row leaves instead, at the run's own scale rather than
-- the parent's, because a child scaled up three times over stops being the thing
-- the row named.
--
-- **`burst`** makes killing it cost something. Where it died, everything inside
-- `radius` takes `damage` -- which is the player and nobody else, since a burst
-- that thinned the crowd would make these a *reward* -- and `puddle` is left
-- lying on the page (src/puddle.lua), so the ground the fight was on stops being
-- ground. Same bargain the boss's tear makes: it hits on the way and wets where
-- it stops.
--
-- **`knock`** and **`hold`** are what a shove and a glueing are worth against
-- it, both 1 for everything ordinary. They went in for the boss -- one that can
-- be bowled across the page by a pin is one you never have to look at -- and the
-- grin is the horde-sized version of the same idea: something the crowd-control
-- half of a build cannot fully answer.
--
-- Four more fields turn a row into a boss: `boss` (never despawns, never shoved
-- out of the way by the crowd, and ends the run when it dies), `pupil` (an eye
-- that watches you), `trail` (a wet blot dropped behind it as it walks) and
-- `tears` (the same wet thrown rather than walked, three ways --
-- Game:updateTears).
--
-- The box the fight happens in is not one of them, and deliberately: an arena is
-- a fact about the *fight* rather than about the monster, so the spawner opens it
-- when it sends the boss (src/arena.lua) and nothing in this table knows.
--
-- Every *distance* written in a block above -- a burst radius, a pellet's `hit`,
-- a puddle's radius, a `spread` -- is the number for an ordinary arrival and is
-- multiplied by `reach` for a champion or a blow-up (Spawner:scale, Enemy.new).
-- Every *time* and every *range* is the number on the row for all three: a giant
-- eye fires a bigger pellet from the same distance on the same beat.
Enemy.types = {
    blob  = { name = "BLOB", sprite = "blob",  hp = 4,  speed = 20, radius = 4, damage = 6,  xp = 1, shadow = 6 },
    bat   = { name = "BAT", sprite = "bat",   hp = 2,  speed = 38, radius = 4, damage = 4,  xp = 1, shadow = 7 },
    skull = { name = "SKULL", sprite = "skull", hp = 12, speed = 15, radius = 5, damage = 12, xp = 3, shadow = 8 },
    -- The wad: the one thing on the page that arrives all at once.
    --
    -- Everything else in this table is answered by *position over seconds* --
    -- you walk away from a skull, you put damage in front of a crowd, you step
    -- out of a lane of tears. That is the whole game and it is a good game, and
    -- it means nothing here has ever asked the player to react. The wad does,
    -- once every three seconds or so, and half a second is all it gives you.
    --
    -- The numbers are all one bargain: it is slower than a blob while walking
    -- (18) so it is never a chase, and nearly three times the player while
    -- dashing (165) so the dash is never a chase either -- it is a line drawn
    -- across the page that you are either standing on or not. 10 damage is
    -- deliberately just under the skull's 12: getting hit by one is the worst
    -- thing an ordinary monster does to you short of a skull walking into you,
    -- and it should be, because it is the only one you could have avoided.
    --
    -- 6hp so that the answer to a wad you *saw* coming is often just to kill it
    -- during the half second it is standing still telegraphing.
    wad = { name = "WAD", sprite = "wad", hp = 6, speed = 18, radius = 4, damage = 10, xp = 3, shadow = 7,
            charge = { range = 96, every = 2.9, wind = 0.5, speed = 165,
                       time = 0.42, rest = 0.8 } },
    -- The blot: a blob that is two fights.
    --
    -- Almost everything a build in this game buys is *area* -- the sword arc,
    -- the bomb, the sun, the storm, the beam -- so area is not really a choice,
    -- it is the default, and nothing on the page had ever made the player feel
    -- that. A blot killed by a stroke that also caught its three drops is a
    -- blot that cost one swing; a blot killed by a single pellet is three more
    -- things walking at you. That is the entire design.
    --
    -- 11hp and 16 speed puts it between a skull and a blob to fight and slower
    -- than either to arrive, because the drops are the real bill and it should
    -- not also be quick. It pays 1xp itself and lets the drops carry the rest,
    -- so ignoring one is not a way to be paid for it.
    -- `split.blown` is what a *blow-up* of it leaves instead, and a blot is the
    -- only row that has ever wanted one. Three times the size, the drops it would
    -- otherwise leave come off at three times the size too -- and a drop that
    -- wide is not a drop any more, it is a body wider than a grin with 2 health,
    -- which reads as debris rather than as three more fights.
    --
    -- What a giant blot leaves instead is three *blots*, ordinary ones, which then
    -- do what a blot does. So the row says the same sentence at both sizes -- this
    -- thing is two fights -- and the enormous one says it twice: one giant becomes
    -- three blots becomes nine drops, and the area you needed the first time you
    -- had to answer this is the area you need three times over.
    --
    -- It cannot run away with itself, and that is the whole reason the field names
    -- what a *blow-up* leaves rather than what a blot leaves: the children arrive
    -- at the ordinary scale, so Enemy:isBlown is false on every one of them and
    -- the second generation takes the plain `into`. Three levels, never four.
    blot = { name = "BLOT", sprite = "blot", hp = 11, speed = 16, radius = 5, damage = 8, xp = 1, shadow = 9,
             split = { into = "drop", count = 3, spread = 6, blown = "blot" } },
    -- The drop: never spawned, only fallen off. Two health, so anything at all
    -- clears one, and 30 speed so the three of them are a spread rather than a
    -- second blot -- they get *past* you, which is what makes a blot killed in
    -- the wrong place a mistake you are still living with a moment later.
    drop = { name = "DROP", sprite = "drop", hp = 2, speed = 30, radius = 3, damage = 4, xp = 1, shadow = 5 },
    -- The bulb: the only enemy whose death is worse than its life.
    --
    -- Every build in this game ends up killing the crowd at arm's length --
    -- that is what an aura, an orbit and a swing all are -- and until now there
    -- was no cost to it whatsoever. A bulb makes *where* you clear the crowd a
    -- decision: 14 damage is the hardest single hit anything short of the boss
    -- lands, and 26 is comfortably wider than any melee radius in the game, so
    -- one that dies at your feet is a hit you take.
    --
    -- It bursts when it *dies*, not on a fuse of its own, and that is the whole
    -- rule -- one door (Game:killEnemy), no second timer to read, and a chain
    -- when one takes another with it. The player's invulnerability window is
    -- what keeps a chain from being fatal (Player:hurt): four going off together
    -- is one hit, exactly as wading through four puddles is.
    --
    -- 26 speed, quicker than a blob, because a bulb that never reaches you is a
    -- bulb you only ever kill at range, and then it is not a decision. 8hp so it
    -- is easy to kill early and easy to kill by accident late, which is the joke.
    bulb = { name = "BULB", sprite = "bulb", hp = 8, speed = 26, radius = 5, damage = 5, xp = 2, shadow = 8,
             burst = { radius = 26, damage = 14,
                       puddle = { radius = 11, life = 4.5, damage = 5 } } },
    -- The grin: the one the crowd control cannot answer.
    --
    -- Half of what a built run does to the horde is *move* it -- the pushpin
    -- and the ruler shove, the spiral lures, the gluestick and the staple hold,
    -- the rubber launches -- and against everything in this table those tools
    -- have always worked completely. `knock` and `hold` were written for the
    -- boss for exactly that reason; this is the horde-sized version, and it is
    -- the only row here that is a *fact about the player's build* rather than
    -- about a monster's own attack.
    --
    -- 0.25 and 0.45 rather than 0 either way, for the boss's reason: a tool
    -- that visibly does nothing is worse than one that does a little, and every
    -- level of the gluestick line should still buy something against it.
    --
    -- 34hp is nearly three skulls and 11 speed is the slowest thing in the game,
    -- which is the trade the whole row is built on: it can always be walked away
    -- from, and it can never be walked away from *cheaply*, because the page it
    -- is standing on is page you have given up. 16 damage is the hardest contact
    -- hit in the table -- the one thing you must not do is let the slow one
    -- catch you -- and 8xp is what three skulls' worth of work is owed.
    --
    -- Fourteen across and a 7px radius, which makes it the only enemy allowed to
    -- be bigger than the eye. Size is doing real work here: nothing about being
    -- unshovable can be *seen*, so the silhouette has to promise it before the
    -- first pushpin bounces off, and half a second of watching a build fail to
    -- move something is the worst possible way to learn a rule.
    grin = { name = "GRIN", sprite = "grin", hp = 34, speed = 11, radius = 7, damage = 16, xp = 8, shadow = 13,
             knock = 0.25, hold = 0.45 },
    eye   = { name = "EYE", sprite = "eye",   hp = 14, speed = 9,  radius = 6, damage = 10, xp = 4, shadow = 9,
              shot = { range = 100, every = 2.4, speed = 40, damage = 8 } },
    -- The bloodshot eye is the same body with the pupil gone red, and it is the
    -- one enemy that will not come to you.
    --
    -- It was an eye that walked in faster and fired more often, which made it a
    -- harder eye and not a different one: anything that clears its own melee
    -- radius -- which is most of what a build sells -- never had to think about
    -- either of them, because both delivered themselves into it. `keep` is the
    -- fix and it costs nothing but a heading (Enemy:update). It closes to 80,
    -- circles there, and backs off inside 56, so the pellets keep coming from a
    -- distance you have to *choose* to cross.
    --
    -- Which is why it is quick now -- 34, twice what it was. It is still well
    -- under the player's 58, so walking one down always works and always costs
    -- you the walk; that price is the whole design. The fire rate stayed where
    -- it was rather than rising with the range, because a shooter you are
    -- crossing a page to reach is already firing for longer.
    redeye = { name = "RED EYE", sprite = "redeye", hp = 14, speed = 34, radius = 6, damage = 10, xp = 6, shadow = 9,
              shot = { range = 110, every = 1.6, speed = 40, damage = 8 },
              keep = { at = 80, back = 56 } },
    -- The eye boss, which is the eye at four times across and the same idea
    -- taken seriously: it walks at you slower than you can walk away, it fires
    -- a fan rather than a pellet, and it wets the page behind itself so the
    -- ground you retreated over stops being ground. Every one of those is a
    -- thing you answer by moving, which is why it is slow -- a boss you cannot
    -- outrun would just be a big blob.
    --
    -- The hp is the one number here set by measurement rather than by design.
    -- A run holding every passive weapon at its last level puts about 30 damage
    -- a second into a *single* target -- far less than it does into a crowd,
    -- since most of what a build sells is area -- so 900, scaled to 1260 by the
    -- time the first one walks on (Game:enemyScale), is a fight of half a minute
    -- for a strong run and rather longer for one that drafted wide. That is the
    -- number to move if the fight is the wrong length; everything else about the
    -- boss is a design decision.
    --
    -- It is also why the eye is the one row the horde's health curve does not
    -- touch: that curve compounds by the minute and would have handed the first
    -- eye something over three thousand health, which is not a length anybody
    -- measured. `boss` on this row is what buys the exemption -- the spawner
    -- prices an eye per cycle instead (BOSS_HP_PER_CYCLE, src/spawner.lua), so
    -- the 1260 above is still the fight, and the second eye is 40% past it.
    bosseye = { name = "BOSS EYE", sprite = "bosseye", hp = 900, speed = 26, radius = 20, damage = 20,
              xp = 250, shadow = 34, boss = true, pupil = true, knock = 0.06, hold = 0.3,
              shot = { range = 190, every = 2.6, speed = 46, damage = 12, hit = 4,
                       spread = 5, arc = 1.05, sprite = "bossShot" },
              trail = { every = 0.5, gap = 9, radius = 12, life = 7, damage = 6 },
              -- The eye cries, and where a tear lands the page is wet.
              --
              -- The trail above is the boss denying you the ground it walked
              -- over, which is ground you chose to give it. The tears are the
              -- half of the same idea it does not have to walk to: they land
              -- where it is not, so the arena fills up from the middle as well
              -- as behind it, and a corner you were saving stops being a plan.
              --
              -- Three deliveries off one projectile, which is what keeps the
              -- fight varied without teaching three separate things. A tear is a
              -- tear wherever it came from -- it hurts if it hits you on the way
              -- and it puddles where it stops -- so all any of these change is
              -- *where* a handful of them land.
              --
              -- The puddle a tear leaves is deliberately smaller and shorter
              -- than the one the boss drags behind it: the trail is the price of
              -- letting it walk, and should be worse than weather.
              tears = { speed = 74, damage = 8, hit = 3, sprite = "tear",
                        puddle = { radius = 10, life = 5.5, damage = 6 },
                        -- The weather. A few at a time, anywhere in the box,
                        -- landing near or far -- the one attack that is not
                        -- aimed at you at all, so it is the one that makes
                        -- standing still bad on its own account.
                        scatter = { every = 3.2, count = 3, near = 34, far = 130 },
                        -- The lane. Fired straight down the line to the player
                        -- and landing at rising distances, so what it draws is a
                        -- wall across the way you were about to go rather than a
                        -- shot at where you are. Aimed, but at the ground.
                        lane = { every = 7.5, count = 5, from = 26, step = 24 },
                        -- The two turns. Fired once each as the fight passes two
                        -- thirds and one third of the eye's health, a full ring
                        -- of tears thrown out around it -- so the moment the bar
                        -- says the fight is going your way, the floor answers.
                        -- Thresholds rather than a clock, because what they are
                        -- for is marking progress you earned.
                        ring = { at = { 0.66, 0.33 }, count = 14, radius = 50 } } },
}

-- `scale` is how much harder the run has got since it started (Game:enemyScale)
-- and it is baked in *here*, once, rather than read off the run wherever damage
-- is dealt. That is what makes a monster keep the numbers it walked on with: the
-- horde standing on the page when a cycle ends is the horde that cycle spawned,
-- and nothing already alive gets tougher because the clock rolled over. It is
-- also why hp, damage, xp and the radius live on the enemy while everything else
-- stays on the shared `def` -- those four are the only ones a scale touches, and
-- the radius is the newest and the odd one out: it is the first thing a scale has
-- ever changed that is not a number on a health bar but a fact about how much of
-- the page the thing is standing on (`grow`, below).
-- Health is rounded to a whole number and damage is not, and that asymmetry is
-- the one place a scale is allowed to be inexact.
--
-- What a player actually learns about a monster is *how many hits it takes*, and
-- with health this small -- a bat is 2 -- an unrounded multiplier turns that
-- into a fraction they cannot see and can only lose to. A blob on 4.14 health
-- takes two swings of a pencil that deals 4, and nothing on screen says why; on
-- 4 it takes one, which is the game's most basic sentence and worth protecting
-- for the minute the ramp leaves alone (HP_GRACE in src/spawner.lua). Rounding
-- to nearest rather than down, so the curve is not quietly discounted -- a bat
-- floored would spend most of a cycle on the 2 it was written with.
--
-- Damage is left fractional because the reading is the other way round: nobody
-- counts how many blobs it takes to kill *them*, they read a health bar, and a
-- bar is happy with a fraction. Rounding it would also snap the 18%-a-cycle
-- damage curve into jumps on the low numbers, where 4 to 5 is a quarter.
local function wholeHp(base, mul)
    return math.max(1, math.floor(base * mul + 0.5))
end

function Enemy.new(kind, x, y, scale)
    local def = Enemy.types[kind]
    local hpMul = scale and scale.hp or 1
    local dmgMul = scale and scale.damage or 1
    local grow = scale and scale.grow or 1
    -- The course's legs (src/course.lua), and the one multiplier on an arrival
    -- that is *not* about how long it takes to kill. Left fractional for the
    -- damage curve's reason: nobody counts pixels a second, and 20 to 22 is a
    -- thing you feel rather than a thing you read.
    local spdMul = scale and scale.speed or 1
    -- How big what it throws is (Spawner:scale). Equal to `grow` today and read
    -- separately from it everywhere, because what it multiplies is a distance and
    -- what `grow` multiplies is a drawing.
    local reach = scale and scale.reach or 1
    local hp = wholeHp(def.hp, hpMul)

    return setmetatable({
        kind = kind,
        def = def,
        x = x, y = y,
        hp = hp,
        maxHp = hp,
        damage = def.damage * dmgMul,
        shotDamage = def.shot and def.shot.damage * dmgMul or nil,
        trailDamage = def.trail and def.trail.damage * dmgMul or nil,
        -- A tear hits for less than a pellet does and puddles for what a puddle
        -- is worth, and both are scaled here with everything else -- so the
        -- three numbers stay three numbers. Reading the fan's damage for a tear
        -- would have worked today (the trail and a tear's puddle happen to both
        -- be 6) and quietly stopped working the moment anyone tuned one of them.
        tearDamage = def.tears and def.tears.damage * dmgMul or nil,
        tearWet = def.tears and def.tears.puddle.damage * dmgMul or nil,
        -- And the bulb's dose, both halves of it, for the same reason: what a
        -- burst hits for and what the blot of ink it leaves hurts for are two
        -- numbers, and a cycle that sharpens one sharpens both (Game:burstEnemy).
        burstDamage = def.burst and def.burst.damage * dmgMul or nil,
        wetDamage = def.burst and def.burst.puddle.damage * dmgMul or nil,
        -- How wide the blast is, which is the one number on an attack that a
        -- standout arrival moves (`reach`, above). Baked here with the damages
        -- rather than read at the death, so a bulb that walked on enormous goes
        -- off enormous however long it stood around first -- the same rule every
        -- other number on an arrival keeps.
        burstRadius = def.burst and def.burst.radius * reach or nil,
        -- And the multiplier itself, for the three attacks whose size is worked
        -- out somewhere else: a pellet and a tear are built at the moment they
        -- are fired (Game:fireEnemyShot, Game:throwTear) and a puddle is built
        -- where it lands (Puddle.new), so those read this and scale themselves.
        reach = reach,
        -- The scale it walked on with, kept whole so it can be handed on. Only
        -- one thing wants it -- a `split` gives its children the parent's own
        -- scale rather than the run's current one (Game:killEnemy) -- and that
        -- is the same principle the three numbers above are baked for, one step
        -- further out: what came off a monster is as hard as the monster was,
        -- however long it has been standing on the page.
        scale = scale,
        -- A champion: the same row at several times the health, worth several
        -- times the xp because xp rides the hp multiplier, and drawn at twice the
        -- size so you can pick it out of a crowd (`grow`, below). It is a fact
        -- about the *spawn* rather than about the kind, which is why it arrives on
        -- the scale and not as a row of its own -- an elite anything is one line
        -- in the spawner and no new art at all (src/spawner.lua).
        --
        -- It used to be what picked the rim of heavier ink out of
        -- Enemy:outlineColour and it is now read in one place, Enemy:isBlown --
        -- which is the only question anything in the game asks about *which* of
        -- the two standouts an arrival was, and it asks it because a blow-up that
        -- splits leaves something different (`split.blown`, above).
        elite = (scale and scale.elite) or false,
        -- Enraged: the same row at the same size on the same health, quicker on
        -- its legs and hitting for half again, drawn in two colours so that all
        -- three of those are one thing you read rather than three things you find
        -- out (Spawner:fury, Sprites.enraged). The multipliers are already spent
        -- by the time this arrives -- they are on `speed` and `damage` above like
        -- every other number an arrival walked on with -- so what the flag is for
        -- is the drawing, and Enemy:footing is the one place that reads it.
        --
        -- It is the third fact about an *arrival* and the first that is not a
        -- size, which is why it sits beside `elite` rather than anywhere near
        -- `grow`: the two standouts are exclusive because they are both bodies,
        -- and this stacks with either because it is a colour.
        fury = (scale and scale.fury) or false,
        -- Worth what it costs to kill, which is why this rides the *hp*
        -- multiplier and not the damage one. A cycle-two blob takes 40% longer
        -- to put down, so a run clears 40% fewer of them a minute; paying the
        -- written 1xp for it would mean the horde quietly paid less every cycle
        -- while the xp ladder went on asking for more (`XP_RISE` in
        -- src/player.lua), and a long run would stop levelling somewhere in
        -- cycle two however well it was going. Tying the two together makes xp a
        -- second a flat thing across a cycle boundary rather than a falling one:
        -- the ladder still slows down as it climbs, which it should, but it
        -- slows down because levels cost more and never because the page has
        -- quietly stopped paying.
        --
        -- It leaves the value fractional, which nothing minds -- xp is only ever
        -- read as a fraction of the next level (Player:addXp) and is never
        -- written down for anyone to see.
        xp = def.xp * hpMul,
        -- How fast it walks, and until the courses went in this was read straight
        -- off the row every frame. It is baked here now for the reason every
        -- other number on an arrival is: what walked on at a doctorate in cycle
        -- three goes on being that, and nothing already standing on the page
        -- changes because the class did or because a minute went by. Which is
        -- also what makes the ramp behind this legible (SPEED_MOST in
        -- src/spawner.lua) -- the page you are looking at is a record of the
        -- minutes it arrived over rather than one number applied to all of it.
        --
        -- Two numbers rather than one because a wad has two speeds and they are
        -- different kinds of thing -- what it walks at and what it *falls
        -- forward* at (`charge` in Enemy.types). Scaling only the first would be
        -- a run that made the horde quicker and left the one enemy whose whole
        -- point is a sudden closing of distance exactly where it was. The lunge
        -- is 69px of a 96px trigger range at the row's own speed and 92 at the
        -- top of everything, so what the multiplier buys it is a shorter walk
        -- afterwards and never a charge that reaches from the edge of its range.
        speed = def.speed * spdMul,
        dashSpeed = def.charge and def.charge.speed * spdMul or nil,
        -- How many times over it was drawn: 1 for the ordinary horde, 2 for a
        -- champion (Spawner:elite) and 3 for a blow-up (Spawner:blown) -- the same
        -- monster, the same art, the same behaviour, bigger. It is a whole number
        -- because it is a sprite scale before it is anything else (Enemy:draw,
        -- Sprite:draw), which is also what bounds the idea at three: the standouts
        -- can only ever be whole multiples of the row, so there is no room between
        -- 2 and 3 to put a third one in. It is on the scale rather than on the row
        -- for the champion's reason: it is a fact about one arrival, so every kind
        -- that ever gets added can be blown up the day it lands.
        grow = grow,
        -- And the body grows with the drawing, which is the whole of what makes
        -- it fair. Every hit radius, every separation pass, the box, the pen
        -- lines and both spatial hashes read this field off the instance and
        -- never `def.radius` -- so a thing twice the size is twice as hard to
        -- miss and twice as hard to squeeze past, without a single weapon
        -- knowing the idea exists.
        radius = def.radius * grow,
        flash = 0,
        -- The recoil: which way it is being shoved, and how much of the shove
        -- is left. Purely a drawing offset -- see Enemy:footing -- which is why
        -- it lives beside `flash` and nowhere near `pushX/pushY`, the shove
        -- that really does move things.
        bumpX = 0, bumpY = 0, bumpT = 0,
        hitCooldown = 0,
        -- What it has taken since the page last said so, and the moment that
        -- reading opened (Game:spendHits). Kept here rather than at the dozen
        -- places that deal damage for the same reason the glue's multiplier is:
        -- everything arrives through Enemy:hurt, so there is exactly one place
        -- that has to count. `tookAt` is 0 for "nothing pending" -- the sweep
        -- stamps it the first frame it finds something, off the run clock, which
        -- is a clock Enemy:hurt has no business being handed.
        took = 0, tookAt = 0,
        pushX = 0, pushY = 0,
        frozen = 0,
        burnT = 0, burnTick = 0, -- on fire: see Enemy:ignite / Game:updateBurning
        bob = util.hash01(x, y, 9) * 2, -- desync the walk cycles
        -- Which way it prefers to round an obstacle, so a crowd meeting a wall
        -- head-on splits and goes both ways instead of filing along it.
        side = util.hash01(x, y, 13) < 0.5 and -1 or 1,
        slideX = 0, slideY = 0, slideT = 0,
        -- Shooters spawn mid-beat, half to one-and-a-half periods from firing,
        -- so a ring of them arriving together doesn't volley in sync.
        shotT = def.shot and def.shot.every * (0.5 + util.hash01(x, y, 17)) or nil,
        -- The charger's clock and where it has got to. `chargePhase` is nil for
        -- "walking like everything else" and otherwise one of wind / dash /
        -- rest, with `phaseT` counting down whichever it is in; `dashX,dashY`
        -- is the heading it locked when the wind started and rides out to the
        -- end whatever the player does about it. Seeded off the spawn point like
        -- the shot clock and for the same reason: a ring of wads arriving
        -- together must not wind up in unison.
        chargeT = def.charge and def.charge.every * (0.4 + util.hash01(x, y, 23)) or nil,
        chargePhase = nil,
        phaseT = 0,
        dashX = 0, dashY = 0,
        -- The trail clock, and where the last blot went: a boss standing still
        -- drops one puddle and stops, since the clock only pays out once it has
        -- walked clear of what it last put down (Game:updateEnemies).
        trailT = def.trail and def.trail.every or nil,
        -- The two tear clocks, and how many of the health thresholds have been
        -- passed. `rings` counts rather than flags because the thresholds are
        -- taken in order and never come back -- healing is not a thing in this
        -- game, so "how many have gone" is the whole state a ring needs.
        scatterT = def.tears and def.tears.scatter.every or nil,
        laneT = def.tears and def.tears.lane.every or nil,
        rings = 0,
        headX = 0, headY = 0, -- the way it is actually going, vs the way it wants to
        -- Where the pupil is looking, as a fraction of how far it may slide.
        -- Chased rather than set, so the eye swings round to you (Enemy:draw).
        lookX = 0, lookY = 0,
        slipT = 0, slipTurn = 0,
        -- Somewhere else to walk to, and how long it goes on being somewhere else
        -- (src/spiral.lua). Handed over rather than read off the page for the
        -- chill's reason below -- the weapons are stepped after the crowd has
        -- moved, so what a spiral said this frame is spent on the next one -- and
        -- it is a *lure* rather than a shove because being drawn into something
        -- has to be a thing this decides to do: it keeps walking, keeps jostling
        -- its neighbours and keeps hurting whoever is standing where it is going.
        lureX = 0, lureY = 0, lureT = 0,
        -- Slowed down by standing on the trail a skate left (src/skate.lua).
        -- Carried for a moment rather than read off the page, because the
        -- weapons are stepped after the crowd has moved -- so what is here is
        -- what the trail said last frame, which is the wax's `slipT` doing the
        -- same job for the same reason.
        chill = 1, chillT = 0,
        -- How long it goes on wearing the blue outline a bolt left on it
        -- (src/storm.lua). A readout and nothing else -- nothing reads it back
        -- -- but it is the only thing the storm says about *who* it hit: the
        -- strike itself is a third of a second of flash on a page full of marks,
        -- and a thing that walks out of it still lit is a thing you can follow.
        shockT = 0,
        -- Off the page: killed, or walked far enough behind you to be forgotten
        -- (Game:killEnemy, Game:updateEnemies). Nothing in the game held onto an
        -- enemy across frames until the storm did -- a cloud spends a couple of
        -- seconds arriving over the one it has marked -- and this is how the one
        -- thing that does can tell that what it is following is no longer there.
        gone = false,
        -- Time stood under the sun, when it was last stood there, and whether
        -- it has had enough of it: see Enemy:sunburn.
        soak = 0, soakAt = 0, bleached = false,
    }, Enemy)
end

-- Steers along a wall rather than into it. Not real pathfinding, but it reads
-- as the same thing from outside: an enemy that meets a pen line slides along
-- it and rounds the end, and it costs one grid lookup instead of a search.
function Enemy:avoidWalls(dx, dy, walls)
    local near, clearance, nx, ny
    walls:each(self.x, self.y, function(seg)
        local cx, cy, d = Walls.closest(seg, self.x, self.y)
        local clear = seg.r + self.radius
        if d < clear + WALL_LOOK and (near == nil or d < near) then
            near, clearance = d, clear
            nx, ny = Walls.normalOut(seg, self.x - cx, self.y - cy)
        end
    end)
    if not near then return dx, dy end

    -- Walking along it, or away from it, is nobody's problem.
    local into = -(dx * nx + dy * ny)
    if into <= 0 then return dx, dy end

    local tx, ty = -ny, nx
    if self.slideT > 0 then
        -- Already going round: keep going that way. Re-deciding every frame
        -- would park it at the point on the wall nearest the player, sliding a
        -- pixel one way and a pixel back, and it would never reach an end.
        if tx * self.slideX + ty * self.slideY < 0 then tx, ty = -tx, -ty end
    else
        local along = dx * tx + dy * ty
        if math.abs(along) <= 0.05 then
            if self.side < 0 then tx, ty = -tx, -ty end
        elseif along < 0 then
            tx, ty = -tx, -ty
        end
    end
    self.slideX, self.slideY, self.slideT = tx, ty, SLIDE_HOLD

    -- Turn harder the closer it is and the more squarely it is heading in, so
    -- a glancing approach barely bends and a head-on one turns to a slide.
    local blend = into * util.clamp((clearance + WALL_LOOK - near) / WALL_LOOK, 0, 1)
    local rx, ry = util.normalize(dx + (tx - dx) * blend, dy + (ty - dy) * blend)
    if rx == 0 and ry == 0 then return tx, ty end
    return rx, ry
end

-- Steering alone is only a suggestion: the horde behind would shove enemies
-- straight through the line. This is the part that makes ink solid.
function Enemy:resolveWalls(walls)
    if self.frozen > 0 then return end
    walls:each(self.x, self.y, function(seg)
        local cx, cy, d = Walls.closest(seg, self.x, self.y)
        local clear = seg.r + self.radius
        if d < clear then
            local nx, ny = Walls.normalOut(seg, self.x - cx, self.y - cy)
            self.x, self.y = cx + nx * clear, cy + ny * clear
        end
    end)
end

-- One beat of the wad's attack (`charge` in Enemy.types), and the only thing in
-- this file that takes the walk away from an enemy rather than bending it.
--
-- Returns whether it has the movement this frame. Standing still counts: a wad
-- winding up and a wad getting its breath back are both *doing* something, and
-- both of them are doing it instead of walking at you.
--
-- Three phases and one clock between them, which is what keeps this readable
-- from outside: `chargePhase` is nil for "walking like everything else", and
-- `phaseT` is however long is left of whichever of the three it is in.
function Enemy:charge(dt, player)
    local charge = self.def.charge

    -- A tool that moves the crowd wins, exactly as it does over the stand-off's
    -- circling: something told to walk into a spiral walks into the spiral, and
    -- a wind-up it was half way through is dropped rather than banked.
    if self.lureT > 0 then
        self.chargePhase = nil
        return false
    end

    if self.chargePhase == nil then
        self.chargeT = self.chargeT - dt
        if self.chargeT > 0 then return false end

        -- The beat is spent whether or not the player was in reach, the way a
        -- shooter's is (Game:updateEnemies): a clock that only ran in range
        -- would mean every wad that walked into 96 pixels dashed on the frame
        -- it arrived, and a telegraph you meet already lit is not a telegraph.
        self.chargeT = charge.every

        local dx, dy, dist = util.normalize(player.x - self.x, player.y - self.y)
        if dist > 0 and dist < charge.range then
            -- The heading is locked *here*, at the top of the wind, and never
            -- looked at again. Half a second later it is stale by however far
            -- the player has walked, and that gap is the whole attack: the red
            -- outline is not saying "I am about to hit you", it is saying where
            -- the line is going to be.
            self.chargePhase, self.phaseT = "wind", charge.wind
            self.dashX, self.dashY = dx, dy
        end
        return false
    end

    self.phaseT = self.phaseT - dt

    if self.chargePhase == "wind" then
        if self.phaseT <= 0 then
            self.chargePhase, self.phaseT = "dash", charge.time
        end
        return true
    end

    if self.chargePhase == "dash" then
        -- No wall steering, no lost footing, no chill: it is not walking, it is
        -- falling forward, and none of the three things that bend a walk have
        -- anything to bend. It still cannot end up *inside* a pen line --
        -- Enemy:resolveWalls gets the last word after the crowd has moved -- so
        -- a dash into ink is a dash that stops dead against it, which is the
        -- right thing to happen and costs nothing here to say.
        --
        -- The heading is written to `headX,headY` anyway, so that a wad coming
        -- off a dash onto wax carries the line it was on rather than snapping.
        self.headX, self.headY = self.dashX, self.dashY
        self.x = self.x + self.dashX * self.dashSpeed * dt
        self.y = self.y + self.dashY * self.dashSpeed * dt
        if self.phaseT <= 0 then
            self.chargePhase, self.phaseT = "rest", charge.rest
        end
        return true
    end

    -- Getting its breath, which is when it is worth killing: the clock for the
    -- next one has already been reset, so a wad that has just missed is a wad
    -- you have most of two seconds with, standing still, at arm's length.
    if self.phaseT <= 0 then self.chargePhase = nil end
    return true
end

function Enemy:update(dt, player, walls, slick)
    -- The eye follows you whatever else is happening to it -- glued, frozen,
    -- stood still -- because that is the one thing an eye does. Chased towards
    -- the direction of the player rather than set to it, so it swings.
    if self.def.pupil then
        local dx, dy = util.normalize(player.x - self.x, player.y - self.y)
        local k = 1 - math.exp(-PUPIL_TURN * dt)
        self.lookX = self.lookX + (dx - self.lookX) * k
        self.lookY = self.lookY + (dy - self.lookY) * k
    end

    -- Glued: no chase, no drift, and any knockback it was carrying is dropped
    -- so it doesn't lurch the moment it comes unstuck. It can still be hit, and
    -- it still hurts the player who walks into it.
    if self.frozen > 0 then
        self.frozen = self.frozen - dt
        self.pushX, self.pushY = 0, 0
        self.flash = math.max(0, self.flash - dt)
        -- The recoil runs down while stuck too. It is a drawing and not a
        -- shove, so it is not the thing the line above drops -- a glued monster
        -- being shot still flinches, it just doesn't go anywhere.
        self.bumpT = math.max(0, self.bumpT - dt)
        self.hitCooldown = math.max(0, self.hitCooldown - dt)
        self.shockT = math.max(0, self.shockT - dt)
        -- Run down while stuck, unlike the chill and the lost footing above: a
        -- multiplier on a speed nothing is using costs nothing to keep, but a
        -- glued thing let go of two seconds later should not set off towards a
        -- spiral that is no longer on the page.
        self.lureT = math.max(0, self.lureT - dt)
        -- And a wind-up it was half way through, for the knockback's reason: a
        -- wad let go of four seconds later should not spend a heading it picked
        -- before it was stuck. Dropped rather than paused -- what it does when
        -- it comes free is wind up again, in front of you, at where you are now.
        self.chargePhase = nil
        return
    end

    self.slideT = math.max(0, self.slideT - dt)

    -- Either it is walking, or it is committed to a line it picked half a second
    -- ago (`charge`). The two are exclusive and nothing below this cares which:
    -- a shove still rides on top of a dash, and a dashing wad still bobs.
    if not (self.def.charge and self:charge(dt, player)) then
        -- What it is walking at, which is the player unless something has
        -- offered it somewhere better. Everything after this -- the walls, the
        -- wax, the heading it keeps -- is untouched by the swap, so a lured
        -- thing rounds a pen line and skids on a crayon lane exactly as it
        -- would on its way to you.
        local tx, ty = player.x, player.y
        if self.lureT > 0 then
            self.lureT = self.lureT - dt
            tx, ty = self.lureX, self.lureY
        end

        -- Standing on the lure is standing still: normalize answers 0,0 for no
        -- distance at all, which is what makes a spiral a place a crowd gathers
        -- rather than a place it mills around the edge of.
        local dx, dy, dist = util.normalize(tx - self.x, ty - self.y)

        -- The stand-off (`keep`): close, circle, or back away. It reads the
        -- same heading everything else does and only turns it, so a shooter
        -- holding its distance still rounds a pen line, still skids on wax and
        -- still keeps a heading through a shove -- there is no second way of
        -- walking in here.
        --
        -- Deliberately below the lure rather than above it: something told to
        -- walk into a spiral walks into the spiral. Holding a range is what it
        -- does when nothing else has been decided for it, and a tool that
        -- overrules the crowd should overrule this exactly as it overrules a
        -- chase.
        local keep = self.def.keep
        if keep and self.lureT <= 0 and dist > 0 then
            if dist < keep.back then
                dx, dy = -dx, -dy
            elseif dist < keep.at then
                -- Round rather than away, so backing off is a retreat and
                -- holding station is a circle. `side` is the way it already
                -- prefers to round an obstacle, so a pair of them at the same
                -- range orbit opposite ways instead of shadowing each other.
                dx, dy = -dy * self.side, dx * self.side
            end
        end
        if walls.count > 0 then
            dx, dy = self:avoidWalls(dx, dy, walls)
        end

        -- On wax it can't get purchase to change direction: the heading it
        -- arrived with wins, and it only bends towards where it wants to go.
        -- The footing stays lost for a moment after it leaves the band, so a
        -- thing that skids off the end carries on skidding instead of turning
        -- on a pixel -- without that, a 13px band crossed at speed would be
        -- over too fast to feel. Anywhere else the heading snaps, exactly as it
        -- always has.
        if slick then
            self.slipT, self.slipTurn = SLIP_CARRY, slick.turn
        elseif self.slipT > 0 then
            self.slipT = self.slipT - dt
        end

        if self.slipT > 0 then
            local k = 1 - math.exp(-self.slipTurn * dt)
            local hx = self.headX + (dx - self.headX) * k
            local hy = self.headY + (dy - self.headY) * k
            local nx, ny = util.normalize(hx, hy)
            if nx ~= 0 or ny ~= 0 then dx, dy = nx, ny end
        end
        self.headX, self.headY = dx, dy

        -- Sky underfoot: the line a skate left behind the player, which takes
        -- a fraction of the legs off whatever is following him down it. A
        -- multiplier rather than a stop -- being glued is the gluestick's, and
        -- a crowd strung out along a line is what this is for.
        local speed = self.speed
        if self.chillT > 0 then
            self.chillT = self.chillT - dt
            speed = speed * self.chill
        end

        self.x = self.x + dx * speed * dt
        self.y = self.y + dy * speed * dt
    end

    -- Knockback rides on top of the chase and bleeds off exponentially.
    if self.pushX ~= 0 or self.pushY ~= 0 then
        self.x = self.x + self.pushX * dt
        self.y = self.y + self.pushY * dt
        local decay = math.exp(-9 * dt)
        self.pushX, self.pushY = self.pushX * decay, self.pushY * decay
        if math.abs(self.pushX) + math.abs(self.pushY) < 1 then
            self.pushX, self.pushY = 0, 0
        end
    end

    self.bob = (self.bob + dt * 7) % 2
    self.flash = math.max(0, self.flash - dt)
    self.bumpT = math.max(0, self.bumpT - dt)
    self.hitCooldown = math.max(0, self.hitCooldown - dt)
    self.shockT = math.max(0, self.shockT - dt)
end

function Enemy:hurt(amount)
    -- Glue-stuck things take deeper cuts -- a gluestick level. Everything that
    -- deals damage arrives through this one door, so the multiplier rides on
    -- the enemy rather than being known to any of the dozen things that hit.
    if self.glue and self.frozen > 0 and self.glue.soften then
        amount = amount * self.glue.soften
    end
    self.hp = self.hp - amount
    self.flash = HIT_FLASH
    -- The third piece of the same feedback as the two lines either side of it:
    -- the thing is lit, it is knocked back, and it is heard. Here for the reason
    -- all of that is here -- thirty things in the game deal damage and every one
    -- of them arrives through this door -- and that is also what makes the sound
    -- affordable. A built run lands four passives, a mark and a tool on twenty
    -- bodies a second, so a hit sound needs thinning out; one door means one
    -- place to thin it, which is the gap on its row (src/sfx.lua) rather than a
    -- clock kept here or a rule any of the thirty callers has to know.
    Sfx.play("gethit")

    -- Which way it flinches. Nothing that deals damage is handed to this door --
    -- there are thirty of them and they arrive with a number and nothing else --
    -- so the direction is taken off the thing that was hit rather than off the
    -- thing that hit it: backwards along the way it was walking. It is walking
    -- at you, so backwards is away from the hit for nearly every hit on the
    -- page, and it costs the thirty callers nothing to be right about it.
    --
    -- Something with no heading at all -- gathered on a spiral, or hit on the
    -- frame it walked on -- jolts downwards instead, because a hit that moves
    -- nothing at all reads as a hit that missed.
    local bx, by = -self.headX, -self.headY
    if bx == 0 and by == 0 then bx, by = 0, 1 end
    self.bumpX, self.bumpY, self.bumpT = bx, by, HIT_BUMP_TIME
    -- Counted after the softening and not before it, so what is added up is what
    -- was actually taken off the thing.
    Enemy.dealt = Enemy.dealt + amount
    -- Added up rather than announced. Two weapons landing on the same enemy in
    -- the same frame are one thing that happened to it, and the page says so
    -- with one number; Game:spendHits is what decides when the total has stood
    -- still long enough to be worth reading.
    self.took = self.took + amount
    return self.hp <= 0
end

-- `knock` on the row is what a shove is worth against this thing, and it exists
-- for exactly one reason: a boss that can be bowled across the page by a pin is
-- a boss you never have to look at. It rides here rather than at the dozen
-- places that shove, the same way the glue's damage multiplier rides on
-- Enemy:hurt.
function Enemy:knockback(nx, ny, force)
    force = force * (self.def.knock or 1)
    self.pushX = self.pushX + nx * force
    self.pushY = self.pushY + ny * force
end

-- Given somewhere else to walk to for a while (src/spiral.lua). Set rather than
-- added to: a thing standing in two spirals is being pulled into whichever spoke
-- to it last, which is the only answer that does not need a rule of its own.
function Enemy:lure(x, y, hold)
    self.lureX, self.lureY, self.lureT = x, y, hold
end

-- Sent flying hard enough to matter -- the rubber's last level. A launch gets
-- a fresh hit list, so an enemy rubbed at again can bowl over the same thing
-- again; what counts as still flying is Game:updateRams' threshold on the push
-- speed, which is also what quietly ends the state -- a glued enemy drops its
-- push and stops being a projectile the same frame.
function Enemy:launch(ram)
    self.ram = { damage = ram.damage, hit = {} }
end

-- Set alight -- the highlighter's last level (src/upgrades.lua). Touching the
-- ink again refreshes the burn rather than stacking it, so standing on the band
-- holds it at full and leaving starts the clock. The first tick lands at once:
-- catching fire is felt the moment it happens, not a beat later. The block is
-- kept by reference, the way a rocket keeps the numbers it was fired with --
-- an upgrade mid-burn changes the next fire, not this one.
function Enemy:ignite(burn)
    if self.burnT <= 0 then self.burnTick = 0 end
    self.burnT = math.max(self.burnT, burn.time)
    self.burn = burn
end

-- Left out in the sun (src/sun.lua). Exposure is *counted* rather than timed
-- from a start: a thing that walks in and out of the disc is judged on the total
-- it has stood under it, and what it soaked up is forgotten again once it has
-- been out of the light for SOAK_COOL. That is what makes this "stayed under too
-- long" rather than "was under it once", and it is why the sun does not need to
-- keep a list of who is in it.
--
-- Past the limit it is bleached for good and carries a grey ghost of its own
-- outline for the rest of its life (Enemy:draw) -- the mark is the only thing
-- the sun tells you about what it did, since nothing under a solid disc can be
-- seen while it is happening. Returns true the one time it crosses, so the
-- caller can spend a splat on the moment.
function Enemy:sunburn(amount, limit, now)
    if now - self.soakAt > SOAK_COOL then self.soak = 0 end
    self.soakAt = now
    if self.bleached then return false end

    self.soak = self.soak + amount
    self.bleached = self.soak >= limit
    return self.bleached
end

-- Struck by lightning (src/storm.lua), and all that means here is the outline it
-- wears afterwards. The damage landed in the same breath through Enemy:hurt like
-- everything else in the game; this is the second the bolt is still on it.
--
-- Held at the longest rather than added to, the way a burn is: two bolts into the
-- same thing is one thing lit for a second, not one lit for two.
function Enemy:shock(duration)
    self.shockT = math.max(self.shockT, duration)
end

-- Returns true only the first time, so the caller can spend a splat on it.
-- `glue` is the tool doing the sticking, when a tool is: the enemy carries it
-- for as long as it is held, which is how the gluestick's upper levels --
-- deeper cuts while stuck (Enemy:hurt), the tear on the way loose
-- (Game:updateGlue) -- know their victim without the tool keeping a list.
-- A pin's or a staple's hold passes nothing and grants nothing, with one
-- exception: a staple with paste on it (`tacky`, the CLINCH) hands over its own
-- *block*, which is the one thing here that is not a whole tool. Nothing minds --
-- what is read off this afterwards is `soften` and `tear` by name, and a block may
-- carry either.
function Enemy:freeze(duration, glue)
    local wasFree = self.frozen <= 0
    -- `hold` is the same bargain `knock` makes: a boss glued for the full four
    -- seconds is a boss that is not a fight, so it shrugs most of it off. It is
    -- never zero -- a tool that visibly does nothing is worse than one that does
    -- a little -- and it is scaled rather than capped, so every level of the
    -- gluestick line still buys something against it.
    self.frozen = math.max(self.frozen, duration * (self.def.hold or 1))
    if glue then self.glue = glue end
    return wasFree
end

-- The four offset masks every outline on an enemy is made of: its own
-- silhouette one pixel out in every direction, drawn *under* the body rather
-- than over it, so what it says is "that one" about something that still reads
-- as what it was. Four masks rather than authored art because the thing being
-- outlined may be any sprite in the game, including a page's own reskin of it.
--
-- Four things wear one and only one of them is ever seen, since all four are the
-- same four masks in different colours. Enemy:outlineColour is where they are
-- ranked, in the order they are worth.
-- The rim stays one pixel whatever size the body is: `s` scales the silhouette
-- and never the offsets. A blow-up's rim scaled with it would be a two-pixel
-- band, which is a different mark on the page -- and the rim is a *word* rather
-- than a decoration, so it has to look the same on a bat as on a grin twice the
-- size of one.
local function outline(sprite, x, y, colour, s)
    love.graphics.setColor(colour)
    sprite:drawMask(x - 1, y, nil, s)
    sprite:drawMask(x + 1, y, nil, s)
    sprite:drawMask(x, y - 1, nil, s)
    sprite:drawMask(x, y + 1, nil, s)
end

-- Which sprite it is and where it is standing this frame. Two callers -- the
-- thing itself and the blank it stamps into the page under it -- and they have to
-- agree to the pixel: a blank a pixel off the body would print a paper rim along
-- one edge of the bob and nowhere else.
function Enemy:footing()
    -- Stuck things stop bobbing.
    local bob = self.frozen <= 0 and self.bob >= 1
    local y = bob and self.y - 1 or self.y

    -- An enraged arrival is its own art in two colours, and it is swapped in
    -- here rather than at the draw so that both callers get the same answer: the
    -- twin is the same shape at the same origin, so the blank stamped under it is
    -- the blank the ordinary body would have had, and asking twice in two places
    -- would be two chances for that to stop being true.
    local sprite = Sprites.enemy(self.def.sprite)
    if self.fury then sprite = Sprites.enraged(sprite) end

    -- The recoil is folded in here and never into x/y, for both of the reasons
    -- this function exists. Where a thing is *standing* is what every hit
    -- radius, every separation pass and both spatial hashes are reading, and
    -- three pixels of flinch is not worth lying to them about -- a monster you
    -- could miss by shooting it would be the one unfair thing on the page. And
    -- the blank stamped under the body comes out of this same answer, so a body
    -- that jolted without its blank would drag the ruling through itself for a
    -- tenth of a second on every hit.
    --
    -- It slides home linearly, which on a whole-pixel grid is what makes it read
    -- as a recoil rather than as a wobble: 3, 2, 1, 0 is four held frames going
    -- one way, and an eased curve would spend most of them at the same pixel.
    if self.bumpT > 0 then
        local k = HIT_BUMP * (self.bumpT / HIT_BUMP_TIME)
        return sprite, self.x + self.bumpX * k, y + self.bumpY * k
    end
    return sprite, self.x, y
end

-- Which outline it is wearing this frame, or nil for none: the four ranked, most
-- urgent first. All four are things happening *to* it or being done *by* it, which
-- they were not always -- the champion used to sit at the bottom of this list in
-- ink, and it was the one entry that was neither. It says itself with the page now
-- (ELITE_GROW, src/spawner.lua), and what that leaves behind is a ranking where
-- every rim is temporary and none of them is a fact about how the thing arrived. Answering it once rather than laying four masks over each other
-- also makes this the single place that knows whether there is an outline at all,
-- which Enemy:drawSolid needs -- a wind-up blinking one frame out of step between
-- the body and the blank under it would leave a paper rim round the sprite.
--
-- Just hit, in red, and top of the ranking because it is the only one of the
-- four that is about this exact instant rather than about a state the thing is
-- in -- for a tenth of a second, what it is doing matters less than what just
-- happened to it. Red because red is the spark that comes off anything taking a
-- hit everywhere else in the game (src/palette.lua), and because the rim is
-- what keeps the paper stage of the flash from reading as the monster
-- vanishing: the rim is the shape, and the hole inside it is the impact.
--
-- Winding up, or already coming (Enemy:charge), in red: theirs, and the one
-- outline here that is a *warning* rather than a record of something that has
-- already happened to it. The wind-up blinks and the dash does not, which is the
-- whole of the tell -- a flashing wad is a line about to be drawn and there is
-- still time to step off it, a solid one is the line. Blinked off the phase clock
-- rather than off the run's, so every wad on the page flashes to its own beat; a
-- rank of them pulsing in unison would read as one thing. The blink falls through
-- to whatever is underneath rather than to nothing, because a sunburnt wad halfway
-- through a wind-up is still sunburnt on the frames the red is out.
--
-- Just struck, in blue rather than red because the bolt is yours and red is
-- theirs. It is the one outline here that goes away again: a sunburn is what a
-- thing carries for the rest of its life, this is what it is wearing now.
--
-- Sun-bleached, in graphite: it has been stood in the sun, and the one rim here
-- that is a record rather than an instant or a warning.
--
-- Deliberately never more than the one pixel out. Every hit radius in the
-- game is the number on the row (Enemy.types) and a silhouette that lied about it
-- by four pixels would be the one unfair thing on the page -- the same bargain a
-- page's reskin makes (Sprites.enemySkins), for the same reason.
function Enemy:outlineColour()
    if self.flash > 0 then return Palette.red end
    if self.chargePhase == "dash" then return Palette.red end
    if self.chargePhase == "wind" and math.floor(self.phaseT * 14) % 2 == 0 then
        return Palette.red
    end
    if self.shockT > 0 then return Palette.blue end
    if self.bleached then return Palette.graphite end
end

-- Whether this arrival is a blow-up rather than a champion or an ordinary body.
-- Both standouts carry a `grow`, and `elite` is the only thing that tells them
-- apart -- which is what that field is for now that neither of them wears a rim.
--
-- Exactly one thing asks: a blow-up that splits leaves something different from
-- what a champion or an ordinary one leaves (`split.blown` in Enemy.types,
-- Game:splitEnemy). Nothing else in the game needs to know which roll produced a
-- monster, and nothing else should -- the point of both standouts is that they
-- are the same monster.
function Enemy:isBlown()
    return self.grow > 1 and not self.elite
end

-- The blank stamped into the page under it, from inside Overprint.beginSolid:
-- exactly the pixels the body is about to cover and not one more, so the ruling
-- and whatever else the page is printed with stop where the thing standing on
-- them starts. One pixel more when it is wearing an outline, the outline being
-- part of the silhouette rather than a mark on the paper.
--
-- Not the shadow, which is the one thing here that really is on the paper: a
-- smear of graphite goes on darkening over a rule like every other mark.
function Enemy:drawSolid()
    local sprite, x, y = self:footing()

    love.graphics.setColor(Palette.paper)
    if self:outlineColour() then outline(sprite, x, y, Palette.paper, self.grow) end
    sprite:drawMask(x, y, nil, self.grow)
end

function Enemy:draw()
    local sprite, x, y = self:footing()
    local stuck = self.frozen > 0

    -- Which colour the body is wearing this frame, or nil for its own art. Two
    -- steps down the ramp rather than one: blown out to paper for the first
    -- couple of frames and dropping back through blush on the way out, which is
    -- how every other fade in the game is done and is what makes this read as a
    -- flash going off rather than as a light being switched on and off. Paper is
    -- the page's own colour, so what that first step actually draws is a hole in
    -- the shape of the thing, inside the red rim Enemy:outlineColour puts round
    -- it -- the two are one effect and neither works alone.
    local lit
    if self.flash > 0 then
        lit = self.flash > HIT_FLASH - HIT_WHITE and Palette.paper or Palette.blush
    end

    -- Stuck: the shadow turns into a smear of glue. It is also the one thing
    -- here that does not move with the recoil: the shadow is on the paper and
    -- the body is what was hit, so the body kicking off its own shadow is most
    -- of what sells the flinch as a flinch.
    love.graphics.setColor(stuck and Palette.sky or Palette.graphite)
    -- Wider *and* thicker on a blow-up, both off the same `grow`: what is on the
    -- paper under a body twice the size is a mark twice the size, and a big thing
    -- standing on a one-pixel line would read as hovering over the page. The
    -- glue's own two pixels are scaled with it for the same reason -- a smear is
    -- as wide as the foot that is stuck in it.
    local grow = self.grow
    local shadow = (self.def.shadow + (stuck and 2 or 0)) * grow
    -- Struck off the bottom edge of the sprite -- `h - oy` -- rather than off
    -- half its height, which is Sprites.shadow's own expression and makes it the
    -- one rule in the game for where a thing stands. Half the height was the
    -- same number for every enemy authored at its own centre, and stops being
    -- one the moment a skin is drawn taller than the enemy it replaces
    -- (Sprites.enemySkins): the headroom it grows into is on the top of the
    -- grid, so `h` moves and `h - oy` does not, and the feet stay where they
    -- were. It also puts the shadow under the odd-height enemies rather than one
    -- pixel inside them, which is what half the height was quietly doing.
    love.graphics.rectangle("fill",
        math.floor(self.x) - math.floor(shadow / 2),
        math.floor(self.y) + (sprite.h - sprite.oy) * grow - 1,
        shadow, (stuck and 2 or 1) * grow)

    local ring = self:outlineColour()
    if ring then outline(sprite, x, y, ring, grow) end

    if lit then
        love.graphics.setColor(lit)
        sprite:drawMask(x, y, nil, grow)
    else
        love.graphics.setColor(1, 1, 1)
        sprite:draw(x, y, nil, grow)
    end

    -- The pupil, over the iris the art left empty. A disc rather than a sprite
    -- because it is drawn at a different place every frame and there is nothing
    -- to author: `pixelart.circleFill` plots whole pixels on the same grid as
    -- everything else, which is the rule a rotated sprite would break. It
    -- flashes with the body, since a white body with a black pupil still in it
    -- would read as the hit landing on something else.
    if self.def.pupil then
        love.graphics.setColor(lit or Palette.ink)
        pixelart.circleFill(
            x + self.lookX * PUPIL_SLIDE,
            y + self.lookY * PUPIL_SLIDE, PUPIL_R)
    end
end

return Enemy
