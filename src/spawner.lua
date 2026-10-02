-- Drops enemies on a ring just outside the camera so they always walk on from
-- offscreen, and slowly turns up the pressure as the run goes on.
--
-- A run is a **cycle** repeated: ten minutes of horde, then the eye boss, and
-- the horde stops arriving while it is on the page. Killing it wins the run
-- (src/win.lua); carrying on hands the spawner another cycle, harder than the
-- last. The spawner owns that clock because it already owns every other one --
-- what phase the run is in is a fact about what is being spawned.

local Enemy = require("src.enemy")
local Subjects = require("src.subjects")
local Course = require("src.course")
local util = require("src.util")

local Spawner = {}
Spawner.__index = Spawner

local SPAWN_RADIUS = 200
local SPAWN_CLEARANCE = 24 -- past the corner of the screen, so nothing appears
                           -- out of thin air on a wide one
local MAX_ENEMIES = 260

-- ...of which the last few belong to the drills and nothing else.
--
-- This exists because of a thing that is easy to miss about the taps below: past
-- about minute five they are not being held down by the floor or by the wave
-- timer, they are being held down by MAX_ENEMIES. The page sits at its ceiling.
-- Which means a drill scheduled for minute eight -- the half of the run drills
-- were added for -- would find no room and walk on as four monsters, and the
-- game would quietly stop having the feature exactly where it needed it.
--
-- So the ordinary horde stops short and a drill may spend the difference. The
-- trade is real and it is the right way round: the page holds forty fewer bodies
-- of undifferentiated horde in exchange for the shapes always arriving intact,
-- and forty out of 260 is not a difference anybody can see while a wall crossing
-- the page is.
--
-- It is forty *in the first cycle* and it grows with the drills, because a fixed
-- reserve breaks quietly and late: a ring is twenty bodies and drills widen 30% a
-- cycle, so by the fifth cycle one asks for forty-four and would never once fit.
-- Rings would simply stop happening, in the runs that had earned them. Growing
-- the reserve at the same rate means the mix shifts towards shaped arrivals as
-- the cycles go on -- which is the right way for it to shift, since by cycle five
-- health is up twentyfold and undifferentiated bodies are the half of the page
-- with the least left to say. Never past half the ceiling, all the same: the
-- horde is still the game.
local DRILL_ROOM = 40

-- The horde has a floor as well as a ceiling. The floor rises with the
-- difficulty clock at FLOOR_RATE enemies per scaled second, and whenever the
-- horde is under it the spawner refills immediately instead of waiting for the
-- next wave -- so a build that clears the screen is answered with more horde,
-- not a quiet spell, and kill speed buys xp rather than calm. Topped up REFILL
-- at a time, every frame, so a cleared page pours back in over a second or so
-- instead of materialising all at once.
local FLOOR_RATE = 0.6
local REFILL = 3

-- How long a cycle of horde runs before the boss walks on. Ten minutes of real
-- time rather than of the difficulty clock, because this is the one number in
-- here the player is also reading -- it is the clock in the top of the HUD.
Spawner.BOSS_AT = 600

-- What the boss fight spawns alongside the boss.
--
-- It was eyes only, on the grounds that what arrives with the boss should read
-- as the boss's own. That was true and it was also boring: an escort of nothing
-- but shooters is an escort you deal with the same way every time, and once the
-- arena went in (src/arena.lua) it stopped being enough of a problem -- the box
-- means you are already being made to move, and a handful of slow shooters
-- standing in it is a fight you can solve by standing somewhere else.
--
-- A mix instead, and the weights are the argument. Bats are the most of it
-- because they are the one enemy the arena makes genuinely dangerous: they are
-- quick, so on an open page they are a thing you outrun and in a box they are a
-- thing you have to kill. Skulls come next as the weight that has to be spent
-- damage on rather than walked away from, so the escort cannot be ignored while
-- you empty a magazine into something big. Eyes stay, fewest of the plain three,
-- because the fan is still what punishes standing still and the boss is still an
-- eye -- they are the family resemblance rather than the pressure.
--
-- Wads and bulbs are the two the box changes the most, which is why they are in
-- it at all. A wad's dash is dodgeable on an open page by walking off the line
-- it drew; inside a box the line has a wall at the end of it and the room to
-- dodge into is room the boss is also using. A bulb is worse: its burst is
-- ground taken away, and the whole point of the arena is that there is only so
-- much ground. Both are kept low -- two apiece -- because either of them at
-- bat weights would be a fight about the escort rather than about the eye.
--
-- Faster and more of them than the eyes-only version, since the mix is cheaper
-- per body: a bat is two health.
local ESCORT = {
    { "bat", 5 },
    { "skull", 3 },
    { "eye", 2 },
    { "wad", 2 },
    { "bulb", 2 },
}
local ESCORT_EVERY = 1.5
local ESCORT_MAX = 20

-- What time adds to the horde. Both are compounding, and both are read as an
-- exponent of *where the run has got to* rather than stepped on at a boundary
-- (Spawner:scale) -- so hp climbs smoothly through the ten minutes and carries
-- on climbing through the next ten, while damage steps once a cycle. hp can
-- afford to be continuous because a tougher blob is a longer fight; damage
-- cannot, because a blob that hits for a fraction more every minute is a blob
-- nobody can learn.
--
-- **hp is per minute and damage is per cycle, and the two units are the
-- difference between them.** A minute is the unit the player is reading -- it is
-- the clock in the top of the HUD -- so a health curve written per minute is one
-- whose steepness can be checked against the thing on screen, and 15% a minute
-- compounding is the whole difficulty ramp of this game in one number:
--
--     minute  1   x1.00   a blob is 4hp   -- one hit from the pencil's four
--     minute  5   x1.75   a blob is 7hp   -- two
--     minute 10   x3.52   a blob is 14hp  -- four, and the eye walks on
--     minute 15   x7.08   a blob is 28hp  -- seven
--
-- Which is the answer to the question this number exists to answer: the thing
-- you opened the run one-shotting takes most of a magazine by the time an
-- endless run is halfway through its second cycle, and it got there without a
-- single step a player could point at.
--
-- The first HP_GRACE seconds do not scale at all, and that minute is doing real
-- work rather than being a rounding of the curve. A run at ten seconds is a run
-- with no draft behind it and a player still learning which way the gesture
-- goes; anything above 1.0 there turns the game's most basic sentence -- the
-- pencil's 4 kills the blob's 4 -- into a lie that costs a second hit. So the
-- ramp starts at minute one, and everything before it is the sentence.
local HP_PER_MINUTE = 1.15
local HP_GRACE = 60
local DAMAGE_PER_CYCLE = 1.18

-- And what time adds to the *legs*, which is the one thing time scales here with
-- a ceiling written into the shape of the curve rather than a number in front of
-- it.
--
-- hp can compound for ever because a tougher blob is a longer fight. Speed
-- cannot, because a blob quicker than the player is not a longer fight -- it is
-- the end of the only counterplay the whole horde has, which is that you can
-- *leave*. And the margin is not generous: the fastest walker in the game is the
-- bat's 38 against a player's 58 (`SPEED` in src/player.lua), so an exponent as
-- small as 1% a minute draws the two level by minute 32 and 1.5% by minute 21 --
-- cycle four and cycle three, both of them inside an endless run rather than
-- past the end of one. Measured against a player who does nothing but run away,
-- 1.5% a minute has a doctorate's cycle three touching him two thousand times a
-- minute. That is not a harder run; it is a run with the horde's counterplay
-- taken out of it.
--
-- So the shape is an approach and not a climb: the horde walks *towards* a speed
-- SPEED_MOST above the row and never arrives, halving what is left of the gap
-- every SPEED_HALF minutes. Two things fall out of that, and both are why it is
-- this rather than a `math.min` over an exponent. There is no minute at which
-- the ramp stops, so there is no cliff in it -- a capped exponent tops out
-- around minute seven and every minute after that is flat, which reads as the
-- game having given up. And the ceiling is on the *ramp*, so it multiplies the
-- course's own 4% a rung (src/course.lua) instead of competing with it: a
-- ceiling on the product is the tidier line and it quietly eats that dial, since
-- a doctorate would reach it by minute three and a half and all four classes
-- would walk at exactly the same speed from there on.
--
--     minute  0   x1.00   a bat is 38   -- 66% of the player's 58
--     minute  6   x1.09   a bat is 41
--     minute 20   x1.16   a bat is 44
--     minute 60   x1.18   a bat is 45   -- 77%, and it never gets past that
--
-- 18% is read off the far end of that column rather than the near one, because
-- it is the doctorate's number that has to stay under the player: x1.32 at the
-- top of the ladder, which is a bat at 50 against 58. It also keeps the one
-- invariant the wad's lunge is built on -- 165px a second for 0.42s is 69px
-- against a 96px trigger range, so the charge closes distance and never crosses
-- it in one go -- 92px with four still to spare at the top of both curves.
local SPEED_MOST = 0.18
local SPEED_HALF = 6

-- And what a *cycle* adds to the eye, which is not on the curve above.
--
-- The boss's 900 is the one number in Enemy.types set by measurement rather than
-- by design -- it is what makes the fight half a minute long for a strong run --
-- and a per-minute health curve would put it somewhere nobody measured: 15% a
-- minute reaches x3.5 by the time the first eye walks on, so the fight the game
-- was tuned around would arrive at three thousand health instead of 1260.
--
-- So the eye keeps the curve the horde used to be on, read per cycle, which
-- leaves the first one at exactly the 1260 it was tuned to and each one after it
-- 40% heavier than the last. That is the right unit for it anyway: there is one
-- eye per cycle, you meet it once, and what should be true of it is that this
-- cycle's is harder than last cycle's -- not that it grew while you walked to it.
local BOSS_HP_PER_CYCLE = 1.4

-- { kind, unlocked at (seconds), weight }
--
-- Nine rows over ten minutes, which is a new thing to look at roughly every
-- eighty seconds for the whole of a cycle. That spacing is the point of the
-- column: a run's difficulty already climbs continuously (Spawner:scale) and a
-- continuous climb is not something a player can *see*. What they can see is the
-- minute a shape they have never met walks over the edge, and there should be
-- one of those left for as long as the cycle lasts -- the old table spent its
-- last unlock at 450 and then had nothing to say for two and a half minutes.
--
-- They are ordered by what they ask of you rather than by how hard they are.
-- Blob and bat are the page (walk away, or don't). The wad is the first thing
-- that asks for a reaction rather than a plan. The blot is the first that asks
-- what your damage is *shaped* like. The skull is the wall. The bulb is the
-- first that makes where you fight matter. The eye is range. The grin is the
-- first thing your crowd control cannot fully answer, and the redeye is the
-- first that will not come to you -- the two that arrive last are the two that
-- take something away from a build rather than adding something to the page,
-- and a build has to exist before either is a lesson.
--
-- `drop` is not here and never will be: nothing spawns one, they fall off a
-- blot (Game:splitEnemy).
--
-- The weights hold the shape the game shipped with -- blob and bat are half the
-- horde between them and everything else is trim. Nine kinds sharing the other
-- half means no single one of them is common, which is correct: the wad, the
-- bulb and the grin are all *events*, and an event that happens six times a
-- minute is weather.
local TABLE = {
    { "blob",   0,   10 },
    { "bat",    45,  7 },
    { "wad",    120, 4 },
    { "blot",   200, 3 },
    { "skull",  280, 3 },
    { "bulb",   360, 3 },
    { "eye",    420, 2 },
    { "grin",   480, 2 },
    { "redeye", 540, 2 },
}

-- Champions: the same monster drawn twice the size and several times as hard to
-- put down (Enemy.new, Sprite:draw).
--
-- It is not a row in the table above and deliberately so. An elite is a fact
-- about one *arrival* rather than about a kind, so it costs no art, no
-- behaviour and no unlock time, and every kind that ever gets added is elite-able
-- the day it lands. It arrives as a multiplied scale for the same reason the
-- cycle's difficulty does -- which is also what makes the reward free: xp rides
-- the hp multiplier (Enemy.new), so something 3.6 times as long to kill is worth
-- 3.6 times as much without a second number anywhere.
--
-- The mark used to be a rim of heavier ink and is now the size, and that is the
-- one thing about this row that is no longer free: a rim reads at any distance and
-- costs no page, while ELITE_GROW spends four times the paper on every seventh
-- arrival. What it buys is a mark that survives the crowd it has to be read in --
-- a one-pixel rim on a body touching four others is a rim you have to hunt for,
-- and a body twice the size of the ones around it is not. The radius grows with
-- the drawing (Enemy.new), so a champion is now also harder to miss and harder to
-- squeeze past than the row it came from, which the rim never was: what was one
-- sentence about health is two, and the second one is about the page.
--
-- 3.6 and 1.25 are a deliberate mismatch. What an elite should be is a *target*
-- -- something in the crowd worth turning towards and spending a cooldown on --
-- and that wants health, not damage: an elite bat that hits like a skull is a
-- thing that killed you from off screen, while an elite bat that takes eight
-- times as long to die is a thing you noticed. The damage moves at all only so
-- that walking into one still reads as a mistake.
--
-- Nothing before ELITE_FROM, because a champion in the third minute is just a
-- blob that took a while, and then a chance that climbs to ELITE_MOST and stops.
-- One in seven is the ceiling on purpose, and it is load-bearing in a way it was
-- not when the mark was ink: past that the double body stops meaning "that one"
-- and starts being how big the horde is.
local ELITE_FROM = 210
local ELITE_RAMP = 480
local ELITE_MOST = 0.14
local ELITE_GROW = 2
local ELITE_HP = 3.6
local ELITE_DAMAGE = 1.25

-- **Blow-ups: the same monster, drawn three times the size.**
--
-- Now that a champion is a size too, the pair is one axis at two magnitudes
-- rather than two axes, and this is the far end of it: the same art at three
-- times the scale, standing on nine times the paper, on five times the health of
-- its row (Enemy.new, Sprite:draw). It costs no art and no behaviour, for the
-- champion's reason -- it is a fact about an arrival.
--
-- What the pair lost by landing on one axis is that they used to be told apart by
-- *kind* -- ink against paper, a health bar against a shape -- and are now told
-- apart by *how much*, which is a weaker thing to ask a player to read in a crowd.
-- Two things buy it back, and both were already here. One is rarity: a champion is
-- a seventh of the horde and a blow-up is a handful in a whole run, so the thing
-- at three times the size is a thing you have almost certainly not seen for a
-- minute, and it is standing next to the doubles rather than among them. The other
-- is that a blow-up is the one of the two that says its own name (BLOWN_NOTICE) --
-- which is what the announcement was always for: telling you the enormous blob is
-- a thing the game meant.
--
-- Three numbers rather than the single factor this used to be, because the size and
-- health have come apart. BLOWN_HP's 5 is above the 3 the size would have priced,
-- since three times across on three times the health is a thing that dies before
-- you have finished walking round it; and it is above a champion's 3.6 by much
-- less than the size is above a champion's 2, which is the whole trade of the row.
-- What a blow-up is for is being *in the way*, and something that was also the
-- longest fight on the page would be a mini-boss wearing a monster's art. Because
-- xp rides the hp multiplier the reward follows the health and not the size, which
-- is the right way round: a run is paid for the killing and never for the paper.
--
-- BLOWN_DAMAGE stays exactly where twice the drawing had put it, and is now the
-- one number here that neither of the other two moved. It could have gone to the
-- size, and three times a grin's 16 is most of a health bar in one contact hit --
-- from the slowest thing in the game, wearing the loudest silhouette in the game,
-- after a line of text with its name on it. Anything that telegraphed that hard
-- and hit that hard would only ever be a punishment for a misread, and it is the
-- champion's mismatch one step further out: the standouts buy health, and the
-- damage moves only enough that walking into one still reads as a mistake.
--
-- What it is *not* is slower. The obvious version of this idea is a lumbering
-- giant you walk away from, and that version is a wall rather than a monster:
-- the thing that makes a big bat frightening is that it is still a bat. A scale
-- does carry a speed now -- the course puts one there (src/course.lua) -- and
-- this is the one branch of Spawner:scale that deliberately leaves it alone at 1
-- times whatever the course said: a blow-up walks at exactly what it is a
-- blow-up of, which is the whole of the idea.
--
-- **The pressure, rather than a chance.** BLOWN_RISE is added to a meter at
-- every arrival and the meter is the chance, so what is actually being tuned is
-- *how many monsters apart* blow-ups are and not how many seconds -- which is
-- the honest unit, since the page spawns three a second when it is filling and
-- almost nothing when it is full. The meter goes back to nothing the moment one
-- lands.
--
-- A flat chance would do neither of the two things this has to do. It clumps:
-- two blow-ups in the same second is a thing a flat roll does regularly and a
-- thing the player will read as the game having changed the rules. And it
-- droughts: a run can go four minutes without one and the idea quietly stops
-- existing. A rising meter cannot do either -- it starts at almost zero, so the
-- one that just landed is the least likely thing to happen next, and it climbs
-- until something gives.
--
-- BLOWN_MOST is the ceiling the climb stops at rather than the chance itself,
-- and what it is for is bounding the drought rather than capping anything: one
-- in a hundred arrivals is reached after about a thousand of them, and a page
-- still spawning at all then produces one inside another hundred. Two minutes
-- is the longest a run can go without one, and it takes a bad roll to get there.
-- BLOWN_HURRY leans on the rise every cycle, so a tenth cycle meets them oftener
-- as well as harder -- but the meter is what is being hurried, never the
-- ceiling, so this can never turn into the horde being made of them. That
-- restraint is the same one ELITE_MOST is under, and now that both marks are
-- sizes it is the same argument twice: a size you see too often stops being a
-- size at all and just becomes how big the crowd is.
--
-- The rise, the ceiling and the hurry together come out at one every half minute of
-- a busy page, nine in the back half of a first cycle and a little over twice
-- that in a fifth. And because the unit is arrivals, how often you meet one is
-- partly a fact about *your build*: a run clearing the page twice as fast is
-- being handed twice as many monsters and therefore twice as many blow-ups,
-- which is the same bargain the floor already offers -- clearing the page buys
-- more page -- and is the right way round.
--
-- Nothing before BLOWN_FROM, in minutes of horde (Spawner:minutes) rather than
-- real seconds, which is the clock the drills read and the clock that makes an
-- endless run work: cycle two starts past every gate, so from minute ten they
-- are simply part of the weather.
local BLOWN_GROW = 3
local BLOWN_HP = 5
local BLOWN_DAMAGE = 2
local BLOWN_FROM = 5
local BLOWN_RISE = 0.00001
local BLOWN_MOST = 0.01
local BLOWN_HURRY = 0.2
-- And four times as fast while MORE OF THE SAME is running, which is the joke
-- the surge was waiting for: twenty seconds of one kind is the one stretch of
-- the run where the page has stopped varying what it sends, so the thing it
-- varies instead is how big one of them is. Multiplied on the rise rather than
-- fired off the surge, so it is still a roll and the surge is still only making
-- one likely -- an event that *guaranteed* one would be the fourth kind of
-- schedule in a file that already has three. BLOWN_MOST still holds over it, so
-- what four times the rise actually buys is a meter that saturates inside the
-- surge rather than a surge that rains giants: measured, a MORE OF THE SAME
-- hands you about one, against the two thirds of one the same stretch of
-- ordinary page would have.
local BLOWN_ONLY = 4
local BLOWN_NOTICE = "DRAWN THREE TIMES THE SIZE"

-- **Fury: the same monster gone over in red pen.**
--
-- The third fact an arrival can be, and the first one that is not a size. A
-- champion and a blow-up are one axis at two magnitudes -- more paper, more
-- health -- and the axis is used up: a sprite scale is a whole number, so there
-- is no room between 2 and 3 for a third, and 4 is a body wider than the boss.
-- What was left to vary is what the pair deliberately do not touch. Both are
-- *slower to kill*; neither is quicker, and neither hits for much more, because
-- the note over ELITE_DAMAGE is that a standout should be a target and not an
-- ambush. So an enraged arrival is the other monster the horde was missing: the
-- same body at the same size, on exactly the row's health, that gets to you
-- sooner and takes more off you when it does.
--
-- That makes it the one arrival fact that is legible from its *behaviour* rather
-- than from its outline, which is also why it is the one that may stack with the
-- other two. A champion and a blow-up are mutually exclusive because they are
-- both sizes and would add up to a body the page cannot hold; fury is a colour
-- and a pair of multipliers, so an enraged champion is a legible amount of
-- monster and an enraged blow-up is the loudest thing this game can put on a
-- page. Which is the right shape for a rung nobody reaches by accident.
--
-- **The mark is the whole body, in two colours** (Sprites.enraged): the drawing
-- reduced to red where it was mostly made of one mark and ink everywhere else.
-- It costs no paper at all -- the silhouette, the radius and every number
-- measured off the sprite are untouched -- which is what pays for the champion's
-- one extravagance and lets this stack on top of it. The page is a pencil
-- palette on blue ruling, so red and black and nothing else is the loudest a
-- body can be without being bigger, and it is the one mark here that reads the
-- same on a page that has reskinned the crowd.
--
-- **The numbers.** 1.25 on the legs is measured against the one row it matters
-- for: a bat is 38 and the fastest thing in the horde, and 38 through a
-- doctorate's class, the run's own ramp and this comes out at 60 by minute ten
-- and 63 in an endless run, against a player's 58. Over the player is deliberate
-- and it is the whole point of the row -- an enraged bat is the one arrival in
-- the game you cannot simply walk away from, and a bat is 2 health, which is what
-- makes that fair. Everything else stays under: an enraged blob is 31 and an
-- enraged skull 24, so what the multiplier buys the rest of the horde is a
-- shorter breath between you and it rather than a chase.
--
-- 1.5 on damage is above both standouts' and the reason is the mismatch argued
-- over ELITE_DAMAGE, read the other way round. A champion buys health because
-- what it should be is a target; fury buys none, so what it has to be instead is
-- a *threat*, and a thing that arrived faster and hit for what the row always hit
-- for would be a champion with the interesting half taken out. An enraged skull
-- is 18 of a hundred and an enraged grin 24, which is the same arithmetic
-- everything else on the page asks you to do -- and unlike a course's dial it is
-- allowed to move it, because it says so on the body: the note in src/course.lua
-- that a class may not touch what a hit costs you is about the *silent*
-- multiplier on a whole crowd, and this is one arrival wearing red.
--
-- It leaves health alone entirely, which also settles the reward without a
-- second number: xp rides the hp multiplier (Enemy.new), and an enraged blob is
-- not a longer fight, so it pays a blob. A run is paid for the killing.
--
-- **The chance is the blow-up's own meter, run twice.** Same rise, same ceiling,
-- same lean per cycle, its own accumulator -- so the two roll independently and
-- an enraged blow-up is the product of two rare things rather than a third
-- chance somebody has to keep in step. The numbers are written again here rather
-- than read off the BLOWN_ block because they are the same *today* and are not
-- the same *fact*: the blow-up's rise is priced against how much paper the page
-- can carry, and this one against how often a page should hand you something you
-- cannot walk away from.
--
-- Nothing before FURY_FROM, in minutes of horde like the blow-up's gate, and
-- earlier than it because this costs the page nothing. Not from minute zero all
-- the same: the opening minutes are where a player learns what an ordinary body
-- of each row does, and a red one before that teaches nothing -- there is no
-- ordinary to read it against.
--
-- **And it is a doctorate's**, which is the one thing here that is not a fact
-- about an arrival: the gate is the course's own dial (`fury` in src/course.lua)
-- rather than a rung named in this file, because how hard the book is has been
-- exactly one table's business since the courses went in. Zero on the first
-- three rungs is a meter that never climbs, which is the honest way to spell
-- "never" for something that is metered rather than rolled.
local FURY_SPEED = 1.25
local FURY_DAMAGE = 1.5
local FURY_FROM = 3
local FURY_RISE = 0.00001
local FURY_MOST = 0.01
local FURY_HURRY = 0.2
local FURY_NOTICE = "GONE OVER IN RED PEN"

-- **Drills: the shape an arrival has.**
--
-- Everything above this answers *how many* and *what*. A drill answers *from
-- where*, and it exists because the honest reading of the ramp above is that it
-- runs out of things to say around minute five: the wave timer is pinned at its
-- floor, the page is at its cap, and the only variable left is more of the same
-- at once. This is the other axis, and it is the one the ramp cannot reach.
--
-- What it is really fixing is that the page is *isotropic*. The horde arrives on
-- a uniformly random bearing every other second of the run, which averages out
-- to pressure from everywhere -- so running is a thing you do to buy a second
-- rather than a decision about anything, and there is no such thing as a good
-- place to stand. A wall coming over one edge is a decision.
--
-- Five of them, and each one asks the page a different question:
--
--     LINE    a wall along one edge, marching in step -- do you go round it?
--     RING    the circle closes -- there is no round it, only through
--     SIDE    for a while, everything comes over one edge -- a hot side
--     PINCER  two walls, opposite edges -- the answer to having run from one
--     GRID    a block in step, evenly spaced -- the page itself walking at you
--
-- They arrive through the ordinary path (Spawner:dropAt), which is the whole of
-- the rule: a drill is the horde of *that minute*, with that minute's health,
-- that minute's unlocks and that minute's champions, standing somewhere a random
-- bearing would never have put it. A subject may shape an arrival; it may never
-- price one. That is what keeps two lessons comparable while making them
-- different games to play.

-- Marching is `Enemy:lure` and nothing new (src/enemy.lua). A lured monster
-- walks at a point instead of at you, and every member of a wall is lured at
-- *its own* point straight across the page -- offset along the wall by exactly
-- the amount it was spawned by -- which is what keeps the wall parallel instead
-- of a funnel that collapses onto the player in the first second.
--
-- The lure lapses rather than being cancelled, and that moment is the point of
-- the whole event: a wall walks across the page, and somewhere around the middle
-- of it every one of them turns and remembers you are there. Seven seconds is
-- picked off the slow end of the bestiary -- a blob walks 20px a second, so it
-- is most of a page -- and the target is put two rings out so nothing ever
-- arrives at the place it was told to walk to, which would leave it standing.
--
-- It also overrules the shooters' stand-off (`keep` in src/enemy.lua), so a
-- redeye in a wall marches with the wall rather than hanging back at 110px. That
-- is the one place in this game a shooter is somewhere it did not choose to be,
-- and it is worth having: a marching wall with the range in it is a wall you
-- cannot answer by simply not being near it.
local MARCH_HOLD = 7
local MARCH_PAST = 2    -- lure target, in rings past the player
local SIDE_ARC = 1.4    -- how wide "one edge" is, in radians

-- The drills themselves. `count` and `gap` are the first cycle's shape, `at` is
-- the minute of horde a page may first ask for it, and `notice` is what the run
-- calls it out loud the once (Spawner:announce).
--
-- The unlock column is TABLE's idea again and reads off the same clock
-- (Spawner:minutes), which is what makes it survive an endless run without a
-- second rule anywhere: minute ten is cycle two's minute nought, so a run that
-- carries on past the eye arrives at its second cycle with all five already in
-- the bag and never sees the ladder again. The first cycle teaches them one at a
-- time; every cycle after it is the exam.
--
-- The times interleave with TABLE rather than spreading evenly. That column
-- already hands you something new at 0.75, 2, 3.3, 4.7, 6, 7, 8 and 9 minutes,
-- so these sit in its gaps -- which means a first run meets a new *thing* or a
-- new *shape* roughly every forty seconds for the whole ten minutes, and never
-- both in the same breath.
--
-- The order is the order they can be understood in. The wall is first because it
-- is the one whose counterplay is visible from the moment it walks on: it has
-- ends. The ring is second because it is the same event with the ends taken
-- away, and it only means that if you have met the wall. The grid is third as
-- the one that is dangerous for a reason other than its shape -- a block is
-- deep, so it is the one you cannot finish before it reaches you. The pincer is
-- fourth, being two walls and therefore the only one that needs the first to
-- have been understood. And the hot side is last because it is the subtlest: the
-- only one that is a *condition* rather than a thing that happens, and the only
-- one a player can be inside for several seconds without noticing.
--
-- **All five land inside the first cycle, and the unlock order is sorted by how
-- much the pages need them rather than only by how hard they are.** Both of
-- those are constraints, and the second was got wrong twice. The shapes that are
-- some page's *signature* -- the wall, the ring, the grid -- have to unlock early
-- enough to actually be signature, because a page only deals from what has
-- unlocked: with the grid arriving at 8.5 minutes, the two subjects whose entire
-- identity is the grid dealt it about once a run, and with it at 6 they dealt it
-- twice. The hot side is nobody's signature -- every page keeps it as garnish and
-- none is built on it -- so it is the one that can afford to arrive last and be
-- seen least. Nothing may unlock after 7.5 minutes: a sixth drill goes in the
-- gaps, not on the end.
local DRILLS = {
    { name = "line",   at = 1.5, shape = "wall",   count = 14, gap = 15,
      notice = "A LINE ACROSS THE PAGE" },
    { name = "ring",   at = 3.0, shape = "circle", count = 20,
      notice = "A CIRCLE IS DRAWN" },
    { name = "grid",   at = 4.5, shape = "block",  count = 16, gap = 18,
      notice = "THE TABLE FILLS IN" },
    { name = "pincer", at = 6.0, shape = "pincer", count = 16, gap = 15,
      notice = "BOTH MARGINS AT ONCE" },
    { name = "side",   at = 7.5, shape = "bias",   lasts = 18,
      notice = "ONE MARGIN CROWDS" },
}

-- **A page's hand must hold at least two of the first three to unlock**, which
-- is the one rule constraining the weights in src/subjects.lua and it is there
-- because a page can only ever deal from what has unlocked. P.E. broke it: with
-- the wall its only early shape, the first four and a half minutes of every P.E.
-- run dealt the wall six times running and the no-repeat rule had nothing to
-- pick instead. A narrow hand is a page with character between minutes six and
-- ten and a page with a stutter before that, so the character has to be built
-- out of shapes the run has actually reached.
--
-- What a page asks for when it has not said (Subjects.default, and any subject
-- added without an opinion). An even hand of all five, which is the unruled
-- page's mix -- see the note over `drills` in src/subjects.lua.
local DRILL_MIX = { line = 2, ring = 2, side = 2, pincer = 2, grid = 2 }
local DRILL_EVERY = 45

-- What a cycle adds to a drill, which is size and frequency and pointedly not
-- stats: those are already climbing 15% a minute underneath it (Spawner:scale),
-- so a cycle-three wall is both half again as wide *and* made of things that
-- take four times as long to cut through, and only one of those two numbers is
-- written here.
--
-- 30% wider a cycle is the number that matters, because it is the number that
-- eventually takes the counterplay away. A 14-wide wall at 15px apart is 210
-- pixels of page, which on any screen this game runs on is a wall with ends you
-- can get round if you commit early. Three cycles later the same wall is wider
-- than the page and the only way past it is through it -- which is the ring's
-- lesson arriving a second time, at the one moment a run has the damage to have
-- an opinion about it.
local DRILL_GROWTH = 0.3
local DRILL_HURRY = 0.88   -- per cycle, on the gap between drills
local DRILL_LEAST = 18     -- and never closer together than this

-- **Surges: the same shapes, more or less of them.** Where a drill belongs to
-- the page, these belong to everybody -- the same three on every lesson at the
-- same minutes, because they are the run's pulse rather than the page's
-- character. Somebody who has learnt what the bell means should be able to carry
-- that to any page in the book.
--
--     SWARM  the floor and the batch both lift, for fifteen seconds
--     QUIET  and then, only ever behind a swarm, eight seconds of almost nothing
--     ONLY   for twenty seconds the horde is very nearly all one kind
--
-- The quiet is the interesting one, because it is the only place this game
-- breaks its own rule that clearing the page buys you more page and never a rest
-- (see FLOOR_RATE). It breaks it on purpose and only ever as the *back half* of
-- a swarm: the rule holds everywhere except the eight seconds after the worst
-- fifteen. That is what makes both halves legible -- a lull nobody earned is
-- just a gap in the game, while a lull that arrives when the swarm ends is the
-- swarm ending, which is a thing worth being able to feel.
--
-- It is also self-scaling in a way an absolute number would not be. Nothing
-- despawns, so a quiet does not empty the page: it stops the refill, and what
-- the eight seconds are actually worth is however much of the swarm you can
-- clear in them. A run that is winning gets a breather and a run that is
-- drowning gets almost nothing, off one multiplier.
--
-- ONLY is the one that asks what a build is *shaped* like, which is the axis the
-- bestiary is already written along -- twenty seconds of nothing but skulls asks
-- whether you own any single-target damage at all, and twenty seconds of nothing
-- but bats asks the exact opposite. Mechanically it is the `crowd` dial no
-- subject has ever turned (Spawner:weight), turned by the clock instead and then
-- let go of.
local SURGES = {
    { name = "swarm", at = 2.5, lasts = 15, floor = 1.6, batch = 2,
      notice = "THE BELL RINGS" },
    { name = "only",  at = 5.5, lasts = 20,
      notice = "MORE OF THE SAME" },
}
local SURGE_EVERY = 55
local QUIET_LASTS = 8
local QUIET_FLOOR = 0.3
local QUIET_NOTICE = "THE ROOM SETTLES"

-- The one kind many times over, and everything else down to a trickle rather
-- than to nothing: a horde with exactly one shape in it stops reading as the
-- crowd behaving oddly and starts reading as the spawn table having broken.
local ONLY_LIFT = 24
local ONLY_DROP = 0.15

-- Nothing else starts for a moment after something has, because two events at
-- once is neither of them. The whole value of naming a shape is that the page is
-- briefly *about* that shape, and a swarm arriving halfway through a pincer is a
-- page that is about nothing in particular again.
local SETTLE = 8

-- The page the run is being played on (src/subjects.lua) is the spawner's
-- business and nobody else's: whatever a subject does to the horde is entirely
-- made of numbers in here. It is held rather than read off the game every time,
-- because it cannot change while a run is going on -- you pick the page before
-- the run is built.
--
-- Three dials now, and they are read defensively rather than required because
-- they are turned to different amounts and not all of them by every page.
-- `crowd` and `clock` are still at rest everywhere -- the machinery is here for
-- the day a lesson leans on the horde's makeup -- while `drills` is turned by
-- all seven, which is the one thing a page is allowed to say about how the
-- horde arrives. A subject with none of the three set is the table as written
-- and an even hand of drills (DRILL_MIX), so a new row in Subjects.list works
-- before it has an opinion.
--
-- **And the course, which is the other half of what a run was built with**
-- (src/course.lua) -- held here beside the subject, for the subject's reason
-- exactly: it is decided before the run exists and cannot change while one is
-- going on. What the two of them are allowed to say is the whole difference
-- between them. A page may shape an arrival and may never price one; a course
-- prices every arrival on it and cannot shape a single one. That is what keeps
-- seven lessons comparable to each other while making a doctorate a fact about
-- the run rather than about the page.
--
-- Every dial the course turns is read straight off the row (`Course.list`), so
-- unlike a subject's there is nothing defensive about it: the first row is all
-- ones, which is the game as it was drawn, and a course with a dial missing is a
-- row somebody forgot to fill in rather than a page with no opinion.
function Spawner.new(subject, course)
    subject = subject or Subjects.default
    return setmetatable({
        timer = 0,
        phase = "waves",  -- waves -> boss, and back round on an endless run
        cycle = 1,
        cycleStart = 0,   -- when this cycle's ten minutes began
        escortT = 0,
        subject = subject,
        course = course or Course.at(),

        -- The two event clocks, counting down in real seconds rather than on the
        -- difficulty clock. A drill is a rhythm the player is meant to be able to
        -- feel, and the difficulty clock runs at 0.4x precisely so that the ramp
        -- cannot be felt -- so these are the one part of the spawner that reads
        -- the same clock the HUD does.
        drillT = (subject.drills and subject.drills.every) or DRILL_EVERY,
        surgeT = SURGE_EVERY,
        lastDrill = nil,  -- never the same shape twice running
        lastSurge = nil,
        seen = {},        -- which names this run has already spent

        -- What an event is currently *doing*, all of it decaying to nothing on
        -- its own. Held on the spawner rather than on the game because every one
        -- of them is a fact about what is being spawned, which is the same
        -- argument the phase and the cycle are here on.
        sideA = 0, sideT = 0,      -- the hot side, while it lasts
        onlyKind = nil, onlyT = 0, -- the one kind, while it lasts
        floorMul = 1, batchMul = 1, mulT = 0,
        after = nil,               -- the quiet, waiting behind a swarm

        -- How overdue a blow-up is (Spawner:blown). The one piece of event state
        -- that is not cleared by anything: it survives the boss fight and the
        -- roll into the next cycle, because it is a fact about the horde rather
        -- than about an event, and a meter that reset every ten minutes would put
        -- a drought at the start of every cycle -- exactly where a fresh page is
        -- least interesting.
        due = 0,

        -- And how overdue an enraged one is (Spawner:fury), on its own meter for
        -- the reason the pair are allowed to land together: two accumulators is
        -- what makes them independent rolls rather than one roll with two
        -- outcomes. Not cleared either, for `due`'s reason exactly.
        rage = 0
    }, Spawner)
end

-- How many of the ceiling the ordinary taps may fill; the rest is the drills'.
function Spawner:hordeMost()
    return math.floor(math.max(MAX_ENEMIES / 2,
        MAX_ENEMIES - DRILL_ROOM * (1 + DRILL_GROWTH * (self.cycle - 1))))
end

function Spawner:bossAt()
    return self.cycleStart + Spawner.BOSS_AT
end

-- How far through this cycle's ten minutes the run is, 0 to 1. It sticks at 1
-- for the length of the boss fight, which is what stops the escort quietly
-- getting tougher while you are busy.
function Spawner:progress(time)
    return util.clamp((time - self.cycleStart) / Spawner.BOSS_AT, 0, 1)
end

-- How many minutes of *horde* the run has been through. Cycles completed plus
-- how far through this one we are, times the ten minutes a cycle is -- which is
-- real time for the whole of a first run and drifts behind it by however long
-- each boss fight took after that.
--
-- That drift is the point of measuring it this way rather than off game.time.
-- Spawner:progress sticks at 1 while the eye is up, so the clock the horde's
-- health is read off stops with it: an escort does not quietly get tougher over
-- the minute you spend fighting the thing it came in with, and a fight you drag
-- out does not hand the next cycle a stronger horde as a punishment for having
-- taken a while.
function Spawner:minutes(time)
    return (self.cycle - 1 + self:progress(time)) * (Spawner.BOSS_AT / 60)
end

-- What a monster spawned right now is worth, as multipliers on the numbers
-- written in Enemy.types. One curve for the whole run rather than a first-ten-
-- minutes ramp and a separate endless one: the exponent is minutes of horde
-- elapsed, so hp compounds at HP_PER_MINUTE through the first cycle and goes on
-- compounding through the next without a step at the join.
--
-- Three multipliers rather than two since the courses went in (src/course.lua),
-- and the third is still the odd one out, though no longer for the reason it
-- first was: speed is the one number here that the run and the class both have
-- an opinion about and no *arrival* has. Which is why it rides out past all
-- three branches below while the minute reaches it exactly as the minute reaches
-- health -- same clock, same call to Spawner:minutes, no step at the join.
--
-- `kind` is optional and there is exactly one thing it changes: the eye is off
-- the horde's clock and on a per-cycle one (BOSS_HP_PER_CYCLE). It is read here
-- rather than being a field on the row because it is not a fact about the
-- monster -- it is a fact about which *curve* an arrival is priced on, and this
-- is the one function that prices an arrival.
function Spawner:scale(time, elite, kind, grow, fury)
    local course = self.course

    -- The course is on the *exponent* as well as in front of it, and the two are
    -- the two things a harder class is (src/course.lua): `hp` is how tough the
    -- horde is the moment it walks on and `ramp` is how much faster that gets
    -- away from you. A course with only the first would be a course whose tenth
    -- minute felt like high school's, since 15% a minute compounding swamps any
    -- flat number by then.
    -- Read once and used twice: health and legs are on the same clock, and a
    -- second call would be a second place for that to stop being true.
    local minutes = self:minutes(time)
    local hp = HP_PER_MINUTE ^ (math.max(0, minutes - HP_GRACE / 60) * course.ramp)
    if kind and Enemy.types[kind].boss then
        hp = BOSS_HP_PER_CYCLE ^ self.cycle
    end
    -- The flat half, and it is applied after the branch above so it reaches the
    -- eye too: the boss is off the horde's clock and on a per-cycle one, but a
    -- doctorate's eye is still a doctorate's.
    hp = hp * course.hp

    local damage = DAMAGE_PER_CYCLE ^ (self.cycle - 1)

    -- A blow-up. The size used to be the multiplier as well, which is why this
    -- branch once needed no constants of its own; the two came apart when the
    -- champion took the other size, so what it is priced on now is BLOWN_HP and
    -- BLOWN_DAMAGE and `grow` is only how big it is drawn. Ahead of the champion
    -- because the two are exclusive -- see Spawner:dropAt.
    local out
    if grow then
        out = { hp = hp * BLOWN_HP, damage = damage * BLOWN_DAMAGE, grow = grow }
    elseif not elite then
        out = { hp = hp, damage = damage }
    else
        -- A champion is the run's own scale multiplied again, so it is a champion
        -- of *this* minute: one in cycle three is harder than one in cycle one by
        -- exactly the amount everything else is, and there is no second curve to
        -- keep in step with the first.
        --
        -- The size is the exception and is flat, like the blow-up's: what a
        -- champion is is a body twice the row's, and a body that also grew with
        -- the minute would put a cycle-four blob on more of the page than the
        -- boss stands on. Health is what a curve is for.
        out = { hp = hp * ELITE_HP, damage = damage * ELITE_DAMAGE,
                grow = ELITE_GROW, elite = true }
    end

    -- And the legs (Enemy.new), which are the class multiplied by the minute.
    -- What a doctorate buys is a horde 12% quicker at every minute of the run;
    -- what the minute adds is the approach to SPEED_MOST above that, which it
    -- never completes. Multiplied rather than the larger of the two winning, for
    -- the reason the clock's two dials are multiplied in Spawner:update: they are
    -- two different facts -- which class, and how long you have been sat in it.
    --
    -- It rides out past the branches because it is the one number in this
    -- function no arrival has an opinion about: a blow-up is deliberately not
    -- slower than the thing it is a blow-up of and a champion is deliberately not
    -- quicker, so all three walk at whatever the run says the horde walks at. The
    -- eye is the exception that proves it -- it is off the horde's health curve
    -- (BOSS_HP_PER_CYCLE) and on this one all the same, since a cycle-four eye
    -- crossing its box at a cycle-one pace would be the one part of the fight
    -- that had not moved with the run. 26 becomes 34 at the top of the ladder,
    -- which is still well under the player: the box's whole premise
    -- (Spawner:sendBoss) is that the eye has to come to you.
    out.speed = course.speed
        * (1 + SPEED_MOST * (1 - 0.5 ^ (minutes / SPEED_HALF)))

    -- And an enraged one, which is the one arrival fact that reaches the legs
    -- (FURY_SPEED, above) -- so it is applied here rather than in a branch of
    -- its own, after the speed the three branches above deliberately share and
    -- on top of whichever of them ran. Two multipliers and a flag: everything
    -- else about it, including how long it takes to kill and therefore what it
    -- is worth, is exactly the arrival it would have been.
    if fury then
        out.damage = out.damage * FURY_DAMAGE
        out.speed = out.speed * FURY_SPEED
        out.fury = true
    end

    -- How big what it *throws* is: the bulb's blast, a pellet, a tear, the wet
    -- they leave. It tracks the drawing exactly, and it rides out past the
    -- branches for that reason -- there is no arrival whose attack is a different
    -- size from its body, so this is a restatement of `grow` and not a fourth
    -- thing to tune.
    --
    -- It is a separate field from `grow` all the same, and the reason is the
    -- rendering rule: `grow` is a *sprite scale* and is only ever allowed to be a
    -- whole number (Sprite:draw, and the whole-pixels rule in main.lua), where
    -- this is a plain multiplier on distances that nothing constrains. Reading
    -- `grow` at every blast radius would quietly weld a drawing constraint onto a
    -- geometry one, and the day a giant wants a blast that is not exactly three
    -- times a small one, the number to move would be the one that decides how the
    -- art is scaled. So: two fields, equal today, meaning different things.
    --
    -- What it scales is how *big* an attack is and never how far away it starts
    -- or how fast it arrives -- `shot.range`, `shot.speed`, `shot.every`,
    -- `charge.range` and `keep.at` are the numbers on the row for every arrival.
    -- A giant eye fires a bigger pellet at the same distance on the same beat,
    -- which is one new fact to read rather than four.
    out.reach = out.grow or 1
    return out
end

-- Whether this arrival is a champion. Read once, at the spawn, and then baked
-- into the monster like every other number it walked on with -- so a horde that
-- was elite when it arrived stays elite, and nothing already on the page changes
-- because the chance went up behind it.
--
-- The boss is never one, and that is a guard rather than a weight of zero: the
-- eye already is what an elite is pretending to be, and 3.6 times 900 is not a
-- fight anybody finishes.
function Spawner:elite(time, kind)
    if Enemy.types[kind].boss or time < ELITE_FROM then return false end
    -- **The course shortens the climb and never lifts the ceiling**, and this is
    -- the one dial in the file where that distinction is load-bearing rather than
    -- tidy (src/course.lua). It multiplied the chance, ceiling and all, when it
    -- first went in -- on the argument that ELITE_MOST's restraint could be
    -- relaxed by whatever somebody had paid for -- and that argument did not
    -- survive the mark becoming the *size* instead of a rim of ink. One in seven
    -- arrivals at four times the paper is what the ceiling was picked at; one in
    -- three and a half is a horde made of double bodies, which is the exact thing
    -- the note over ELITE_MOST says must not happen at any price. A course may buy
    -- a harder run and it may not buy its way past that.
    --
    -- So a doctorate reaches the same one in seven and reaches it twice as fast --
    -- capped by minute seven and a half rather than minute eleven, which is most
    -- of twice as many champions across the ten minutes the game is built around
    -- and not one extra in the cycles past it. That is the right shape for it
    -- anyway: an endless run is already sitting on the ceiling whatever course it
    -- is, so what there was left to sell here is the middle of a run.
    local ramp = ELITE_RAMP / self.course.elite
    local chance = math.min(ELITE_MOST, (time - ELITE_FROM) / ramp * ELITE_MOST)
    return love.math.random() < chance
end

-- How much nearer a blow-up one arrival brings the next one. The cycle leans on
-- it and so does a MORE OF THE SAME surge, and they multiply rather than picking
-- the larger: a surge in cycle four is the most likely place in the game to meet
-- one, which is where it should be.
function Spawner:swell()
    -- The course is on the rise and never on BLOWN_MOST, which is the one place
    -- here that restraint is load-bearing rather than tidy: the ceiling is what
    -- bounds the drought, and a course that lifted it could turn the horde into
    -- what it is a blow-up of. So a doctorate meets them two and a half times as
    -- close together and never more than one in a hundred arrivals.
    local rise = BLOWN_RISE * (1 + BLOWN_HURRY * (self.cycle - 1))
        * self.course.blown
    return self.onlyKind and rise * BLOWN_ONLY or rise
end

-- Whether this arrival was drawn three times the size, as the factor to draw it at or
-- nil for the ordinary one. Called once per arrival and *not* idempotent -- the
-- meter moves here -- which is why it lives at the one place an arrival is
-- decided (Spawner:dropAt) and is called from nowhere else.
--
-- The boss is never one, for both of the reasons it is never a champion: it is
-- already the thing this is imitating, and a forty-pixel body at three times the
-- scale would not fit in the box it is fought in.
function Spawner:blown(time, kind)
    if Enemy.types[kind].boss then return nil end
    if self:minutes(time) < BLOWN_FROM then return nil end

    self.due = math.min(BLOWN_MOST, self.due + self:swell())
    if love.math.random() >= self.due then return nil end

    self.due = 0
    return BLOWN_GROW
end

-- Whether this arrival walked on enraged. The blow-up's meter run a second time
-- on its own accumulator (`rage` in Spawner.new) and, like it, not idempotent --
-- so this too is called from the one place an arrival is decided and nowhere
-- else.
--
-- The course is the gate rather than a rung named here, and it is on the rise for
-- `blown`'s reason: a doctorate hands out fewer arrivals than high school, so a
-- chance *per arrival* is not the unit anybody cares about, and 60 is what makes
-- an enraged one as often a thing as a blow-up is on the same rung. Where the two
-- dials differ is that this one starts at zero, which is the whole of what makes
-- fury a doctorate's: a meter that never climbs is a chance that never comes up,
-- with no second question anywhere and no rung named in this file.
--
-- The boss is never one, and for once it is not the guard the other two need. An
-- eye at 900 health has no size left to grow into, but it would take a fury
-- perfectly well -- the reason it may not is that the fight is a fixed thing you
-- have learned: a boss a quarter quicker across its box, hitting for half again,
-- on some runs and not others would be the one encounter in the game whose rules
-- the page changed behind you.
function Spawner:fury(time, kind)
    if Enemy.types[kind].boss then return false end
    if self:minutes(time) < FURY_FROM then return false end

    self.rage = math.min(FURY_MOST, self.rage
        + FURY_RISE * (1 + FURY_HURRY * (self.cycle - 1)) * self.course.fury)
    if love.math.random() >= self.rage then return false end

    self.rage = 0
    return true
end

-- What one row of the table is worth in this subject. The unlock time is not
-- the subject's to move -- what has been seen by minute five is a fact about the
-- run's ramp rather than about the page -- so a class leans on the weights only,
-- and everything it does not name goes on weighing what it weighed.
function Spawner:weight(row)
    local crowd = self.subject.crowd
    local w = row[3] * ((crowd and crowd[row[1]]) or 1)
    -- And the one kind, while a surge is asking for it. Multiplied on top of the
    -- subject's dial rather than replacing it, so a page that leans on a kind
    -- leans on it here too -- there is one place a weight is decided and this is
    -- still it.
    if self.onlyKind then
        w = w * (row[1] == self.onlyKind and ONLY_LIFT or ONLY_DROP)
    end
    return w
end

function Spawner:pick(time)
    local total = 0
    for _, row in ipairs(TABLE) do
        if time >= row[2] then total = total + self:weight(row) end
    end

    local roll = love.math.random() * total
    for _, row in ipairs(TABLE) do
        if time >= row[2] then
            roll = roll - self:weight(row)
            if roll <= 0 then return row[1] end
        end
    end
    return TABLE[1][1]
end

-- The ring itself. A phone screen is wider than the 320x180 this was drawn for,
-- so it has to clear the corner of whatever canvas we actually got.
function Spawner:ring(game)
    return math.max(SPAWN_RADIUS,
        util.len(game.vw, game.vh) / 2 + SPAWN_CLEARANCE)
end

-- One enemy, somewhere on the offscreen ring.
function Spawner:drop(game, ring, kind)
    local a = love.math.random() * math.pi * 2
    -- The hot side, while it lasts. It lives here rather than in a shape of its
    -- own because what it changes *is* the ordinary arrival: it is the only drill
    -- that is not a thing that happens but a thing that is true for a while, and
    -- eighteen seconds of the whole horde coming over one edge is a bigger event
    -- than any one wall, spent slowly.
    if self.sideT > 0 then
        a = self.sideA + (love.math.random() - 0.5) * SIDE_ARC
    end
    local r = ring + love.math.random() * 24
    self:dropAt(game, game.player.x + math.cos(a) * r,
                      game.player.y + math.sin(a) * r, kind)
end

-- One arrival at a point rather than on a bearing, which is the whole of what a
-- drill needs and the horde does not. Everything else about it is the ordinary
-- path -- what kind, what it is worth, whether it is a champion -- because a
-- drill is a shape and not a kind of monster.
--
-- Also the one place a champion is decided, because it is the one place an
-- ordinary arrival is decided. Handed over as the scale rather than as a flag,
-- so nothing between here and the monster has to know the idea exists.
function Spawner:dropAt(game, x, y, kind)
    kind = kind or self:pick(game.time)

    -- Two rolls and never both, and now that both of them are sizes this is
    -- structural rather than a design decision. Together they would be eighteen
    -- times the row's health at six times across -- a blob standing on more page
    -- than the boss, which is a mini-boss and not a monster, and which the box a
    -- boss is fought in would not hold. Either one on its own is a legible amount
    -- of monster. The champion roll is skipped rather than overruled, so a blow-up
    -- does not quietly eat a random number either.
    local grow = self:blown(game.time, kind)
    -- And a third roll that is nobody's exclusive (Spawner:fury): fury is a
    -- colour rather than a size, so it costs the page nothing to put on top of
    -- either standout or on top of neither, and it is rolled every time rather
    -- than skipped -- the two sizes are what cannot be added together, and this
    -- adds to both.
    local fury = self:fury(game.time, kind)
    local e = game:spawnEnemy(kind, x, y, self:scale(game.time,
        not grow and self:elite(game.time, kind), kind, grow, fury))

    -- Named the first time one happens and never again, exactly like a drill:
    -- what the line is for is telling you that the enormous blob on the page is
    -- a thing the game meant, and once is enough for that.
    --
    -- The enraged one gets a line for the same reason, and the better claim of
    -- the two: what a blow-up is is visible, where a red body is a body that has
    -- been *repriced*, and the honest way to learn that otherwise is to be caught
    -- by a bat you could always outrun.
    --
    -- One line per arrival, so the rare page that is both says the size and keeps
    -- the other name unspent for whenever the next one lands. A name is spent by
    -- being *said* (`Spawner:announce`) and not by being true, and two of them at
    -- the same arrival would mean the first was marked as taught while the second
    -- was on screen over the top of it.
    if grow then
        self:announce(game, BLOWN_NOTICE)
    elseif fury then
        self:announce(game, FURY_NOTICE)
    end

    return e
end

-- How many of something a drill asks for right now: what it asks for in the
-- first cycle, a third again for every cycle since, and never more than the page
-- has room left for. The cap is checked here rather than inside each shape so
-- that a wall at the ceiling comes out as a short wall instead of as a wall with
-- holes in it -- the ends of it are the counterplay, and a wall whose middle is
-- missing is a different event.
-- With `want`, what this cycle asks for; without it, what the page has room to
-- give. Spawner:beginDrill compares the two and drops the drill rather than
-- dealing half of one.
function Spawner:many(game, n, want)
    n = math.floor(n * (1 + DRILL_GROWTH * (self.cycle - 1)) + 0.5)
    if want then return n end
    return math.max(0, math.min(n, MAX_ENEMIES - #game.enemies))
end

-- A wall along one edge, marching. `a` is the bearing it arrives from, so it
-- walks towards the opposite one, and each member is lured at the point directly
-- across the page from where it started (see MARCH_HOLD).
function Spawner:wall(game, a, n, gap)
    local ring, p = self:ring(game), game.player
    local fx, fy = math.cos(a), math.sin(a)
    local ax, ay = -fy, fx      -- along the wall
    for i = 1, n do
        local off = (i - (n + 1) / 2) * gap
        local e = self:dropAt(game, p.x + fx * ring + ax * off,
                                    p.y + fy * ring + ay * off)
        e:lure(p.x - fx * ring * MARCH_PAST + ax * off,
               p.y - fy * ring * MARCH_PAST + ay * off, MARCH_HOLD)
    end
end

-- The circle. No lure and none wanted: a ring of monsters all walking at you is
-- already a ring closing, and it is the one drill whose shape the chase itself
-- draws rather than fights. Exact angles rather than jittered ones -- a circle
-- that is nearly a circle reads as a bug, and this one is meant to read as drawn.
function Spawner:circle(game, n)
    local ring, p = self:ring(game), game.player
    for i = 1, n do
        local a = (i - 1) / n * math.pi * 2
        self:dropAt(game, p.x + math.cos(a) * ring, p.y + math.sin(a) * ring)
    end
end

-- A block, marching. As square as the count divides, and the ranks are laid out
-- *away* from the player rather than across the page, so the near rank arrives
-- first and what is behind it is still coming -- which is the only thing that
-- makes this different from a thick wall.
function Spawner:block(game, a, n, gap)
    local cols = math.max(2, math.floor(math.sqrt(n) + 0.5))
    local ring, p = self:ring(game), game.player
    local fx, fy = math.cos(a), math.sin(a)
    local ax, ay = -fy, fx
    for i = 0, n - 1 do
        local col = (i % cols) - (cols - 1) / 2
        local row = math.floor(i / cols)
        local out = ring + row * gap
        local e = self:dropAt(game, p.x + fx * out + ax * col * gap,
                                    p.y + fy * out + ay * col * gap)
        e:lure(p.x - fx * ring * MARCH_PAST + ax * col * gap,
               p.y - fy * ring * MARCH_PAST + ay * col * gap, MARCH_HOLD)
    end
end

-- The five shapes, keyed by the `shape` on the row rather than picked out by a
-- chain of names. A drill is a row in DRILLS and a lookup in here, which is the
-- rule the rest of this game is built along: a sixth shape is a row and a
-- function and nothing else changes.
local SHAPES = {
    wall = function(self, game, d, a, n)
        self:wall(game, a, n, d.gap)
    end,
    circle = function(self, game, d, a, n)
        self:circle(game, n)
    end,
    -- Two walls, opposite edges, each half the count -- so a pincer is a line's
    -- worth of monsters arranged as the one shape a line cannot be answered the
    -- same way as. Both march, which means they walk through each other over the
    -- top of wherever you were standing when it started.
    pincer = function(self, game, d, a, n)
        self:wall(game, a, math.floor(n / 2), d.gap)
        self:wall(game, a + math.pi, math.floor(n / 2), d.gap)
    end,
    block = function(self, game, d, a, n)
        self:block(game, a, n, d.gap)
    end,
    bias = function(self, game, d, a)
        self.sideA, self.sideT = a, d.lasts
    end,
}

-- Named the first time it happens in a run, and silent every time after, which
-- is the whole of how these are taught. The run says "THE BELL RINGS" once,
-- while you are looking at what it means, and then trusts you to have learnt it.
-- An endless run's second cycle has already spent every name it owns and so is
-- silent by construction -- correctly, because by then none of it is news.
function Spawner:announce(game, text)
    if not text or self.seen[text] then return end
    self.seen[text] = true
    game:say(text)
end

-- Nothing else starts for `lasts` plus a breath, so that each event gets to be
-- the thing on the page. Pushing both clocks rather than holding a busy flag,
-- because there is nothing to ask afterwards: a clock that has been pushed out
-- is a clock that is not going to fire.
function Spawner:settle(lasts)
    local hold = lasts + SETTLE
    self.drillT = math.max(self.drillT, hold)
    self.surgeT = math.max(self.surgeT, hold)
end

-- The gap between events on this page, in real seconds, closing up a little
-- every cycle and then stopping. Endless runs get drills *more often* as well as
-- bigger, because the thing that makes a tenth cycle hard cannot only be that
-- everything has more health -- but it stops at DRILL_LEAST, since past about
-- one every twenty seconds an event is not an event, it is the weather.
function Spawner:gap(base)
    return math.max(DRILL_LEAST, base * DRILL_HURRY ^ (self.cycle - 1))
end

-- Which drill, out of the ones this page owns and the run has reached.
function Spawner:pickDrill(time)
    local of = (self.subject.drills and self.subject.drills.of) or DRILL_MIX
    local minutes = self:minutes(time)
    local bag, total = {}, 0
    for _, d in ipairs(DRILLS) do
        local w = of[d.name] or 0
        if w > 0 and minutes >= d.at then
            bag[#bag + 1] = { d, w }
            total = total + w
        end
    end
    if #bag == 0 then return nil end

    -- Never the same shape twice running, unless the page has only unlocked the
    -- one. A bag that can repeat itself deals two walls in a row often enough to
    -- read as the game having a single idea, and the fix is cheap enough that
    -- there is no argument for living with it.
    if #bag > 1 then
        for _, row in ipairs(bag) do
            if row[1].name == self.lastDrill then
                total = total - row[2]
                row[2] = 0
            end
        end
    end

    local roll = love.math.random() * total
    for _, row in ipairs(bag) do
        if row[2] > 0 then
            roll = roll - row[2]
            if roll <= 0 then return row[1] end
        end
    end
    return bag[1][1]
end

function Spawner:beginDrill(game)
    self.drillT = self:gap((self.subject.drills and self.subject.drills.every)
        or DRILL_EVERY)

    local d = self:pickDrill(game.time)
    if not d then return end

    -- A drill that cannot arrive whole does not arrive at all, and is not named
    -- and not remembered when it doesn't. Being told a wall is crossing the page
    -- and then watching four monsters walk on is worse than the page just going
    -- on being busy, and it would spend the one announcement this shape gets for
    -- the whole run (Spawner:announce) on the version of it that isn't one. It
    -- comes back on the next gap, shortened, since nothing was spent.
    local want = d.count and self:many(game, d.count, true) or 0
    if d.count and self:many(game, d.count) < want then
        self.drillT = math.min(self.drillT, SETTLE)
        return
    end

    SHAPES[d.shape](self, game, d, love.math.random() * math.pi * 2, want)
    self.lastDrill = d.name
    self:announce(game, d.notice)
    self:settle(d.lasts or 0)
end

-- Which kind the horde is very nearly all of, for as long as ONLY lasts. Uniform
-- among what has been unlocked rather than weighted, because the whole point is
-- the kinds that are ordinarily trim: a roll weighted the way the horde is
-- weighted would come up blob most times it happened, and the blob is the one
-- kind whose every page you have already seen. So blob is out of the hat, and
-- for exactly that reason -- twenty seconds of the default is not an event.
function Spawner:pickOnly(time)
    local open = {}
    for _, row in ipairs(TABLE) do
        if time >= row[2] and row[1] ~= "blob" then open[#open + 1] = row[1] end
    end
    if #open == 0 then return "bat" end
    return open[love.math.random(#open)]
end

-- The back half of a swarm. It does not announce on a fresh name every time for
-- the same reason none of them do, and it is started from the swarm's own expiry
-- rather than being scheduled, because a quiet that could turn up on its own
-- would be a free rest and the floor exists to say there are none of those.
function Spawner:beginQuiet(game)
    self.floorMul, self.batchMul, self.mulT = QUIET_FLOOR, 0, QUIET_LASTS
    self:announce(game, QUIET_NOTICE)
end

function Spawner:beginSurge(game)
    self.surgeT = self:gap(SURGE_EVERY)

    local minutes = self:minutes(game.time)
    local bag = {}
    for _, sur in ipairs(SURGES) do
        if minutes >= sur.at and sur.name ~= self.lastSurge then
            bag[#bag + 1] = sur
        end
    end
    if #bag == 0 then return end

    local sur = bag[love.math.random(#bag)]
    self.lastSurge = sur.name
    if sur.floor then
        self.floorMul, self.batchMul, self.mulT = sur.floor, sur.batch, sur.lasts
        self.after = "quiet"
    else
        self.onlyKind, self.onlyT = self:pickOnly(game.time), sur.lasts
    end
    self:announce(game, sur.notice)
    self:settle(sur.lasts + (sur.floor and QUIET_LASTS or 0))
end

-- Everything an event is currently doing, decaying. One function because they
-- all decay the same way and none of them has anything to say on the way out
-- except the swarm, which hands over to its own back half.
function Spawner:updateEvents(dt, game)
    self.sideT = math.max(0, self.sideT - dt)

    if self.onlyT > 0 then
        self.onlyT = self.onlyT - dt
        if self.onlyT <= 0 then self.onlyKind = nil end
    end

    if self.mulT > 0 then
        self.mulT = self.mulT - dt
        if self.mulT <= 0 then
            self.floorMul, self.batchMul = 1, 1
            if self.after == "quiet" then
                self.after = nil
                self:beginQuiet(game)
            end
        end
    end

    self.drillT = self.drillT - dt
    if self.drillT <= 0 then self:beginDrill(game) end

    self.surgeT = self.surgeT - dt
    if self.surgeT <= 0 then self:beginSurge(game) end
end

-- Wiped at both ends of a boss fight. The fight is the fight: an escort that
-- came over one edge because a hot side was still running, or a quiet that
-- happened to be holding the horde back as the eye walked on, would be the run
-- keeping a promise it made to the ten minutes before -- and the next cycle
-- should open on its own terms rather than halfway through the last one's
-- weather. The clocks are reset rather than cleared so a fresh cycle waits its
-- first gap out instead of opening with a wall.
function Spawner:clearEvents()
    self.sideT, self.onlyT, self.mulT = 0, 0, 0
    self.onlyKind, self.after = nil, nil
    self.floorMul, self.batchMul = 1, 1
    self.drillT = self:gap((self.subject.drills and self.subject.drills.every)
        or DRILL_EVERY)
    self.surgeT = self:gap(SURGE_EVERY)
end

-- One of the escort, by weight.
function Spawner:escort()
    local total = 0
    for _, row in ipairs(ESCORT) do total = total + row[2] end

    local roll = love.math.random() * total
    for _, row in ipairs(ESCORT) do
        roll = roll - row[2]
        if roll <= 0 then return row[1] end
    end
    return ESCORT[1][1]
end

-- The boss walks on from the ring like everything else, and that is deliberate:
-- there is no arrival animation, just the moment you notice that what came over
-- the edge this time is enormous.
--
-- The box goes up at the same moment (src/arena.lua), pinned where the player is
-- standing rather than where the eye is: you get the middle of it, and the eye
-- has to come to you. It is the game taking the one answer away that would
-- otherwise beat this fight without playing it -- the eye is slower than you, so
-- on an open page walking in a straight line is a strategy.
function Spawner:sendBoss(game)
    self.phase = "boss"
    self.escortT = ESCORT_EVERY
    self:clearEvents()
    game:openArena()
    self:drop(game, self:ring(game) + 20, "bosseye")
end

-- The boss is down and the run went on rather than ending. The next cycle's ten
-- minutes start now, so the pause the fight took is not deducted from them --
-- and the box comes down, because the next ten minutes are horde again and the
-- horde is the half of the game that is played on an open page.
function Spawner:nextCycle(game)
    self.cycle = self.cycle + 1
    self.cycleStart = game.time
    self.phase = "waves"
    self.timer = 0
    self:clearEvents()
    game:closeArena()
end

-- The boss fight: no horde at all, a drip of escort, and nothing to do with the
-- difficulty clock. The floor and the waves are what make the page fill up over
-- ten minutes, and both of them running under a boss would mean the boss was
-- never the thing you were fighting.
--
-- The escort walks on from the ring like everything else and is then put inside
-- the box, rather than being spawned inside it directly: the ring is what keeps
-- an arrival off the middle of the page, and a bat appearing three pixels from
-- your face because that is where the random landed would be the one unfair
-- thing in a fight built out of fair ones. Game:spawnEnemy does the clamping, so
-- this does not have to know the box exists.
function Spawner:updateBoss(dt, game)
    self.escortT = self.escortT - dt
    if self.escortT > 0 then return end
    self.escortT = ESCORT_EVERY

    if #game.enemies < ESCORT_MAX then
        self:drop(game, self:ring(game), self:escort())
    end
end

function Spawner:update(dt, game)
    if self.phase == "boss" then
        self:updateBoss(dt, game)
        return
    end

    if game.time >= self:bossAt() then
        self:sendBoss(game)
        return
    end

    -- The difficulty clock runs at 0.4x real time, so the pressure at minute
    -- ten is what a full-speed clock would have reached by minute four. Every
    -- knob below (floor, interval, batch) reads this, not game.time, so the
    -- whole ramp slows together; enemy *unlocks* in TABLE still go by real time.
    -- It is the run's clock rather than the cycle's: an endless run does not
    -- start its horde over, it starts its horde where the last cycle left it.
    --
    -- The subject's `clock` is the one dial a page has on the ramp itself, and
    -- it is on this line rather than on any of the three knobs below so that a
    -- harder page is harder in the way ten more minutes are harder, rather than
    -- in a way this game has never asked anyone to play against. It does not
    -- reach the unlock times in TABLE, which go by real time: a subject changes
    -- how much of the horde there is, never what is in it.
    --
    -- The course's is the same dial turned by somebody who paid for it
    -- (src/course.lua), and it is on the same line for the same reason and with
    -- the same limit: a doctorate is two thirds again the crowd at every minute
    -- of the run and still meets the wad at minute two. Multiplied together
    -- rather than the larger of the two winning, because they are two different
    -- facts -- which page, and which class -- and a page that leaned on the horde
    -- should lean on it in every class in the building.
    local time = game.time * 0.4 * (self.subject.clock or 1) * self.course.clock

    local ring = self:ring(game)

    -- The drills and the surges, before the taps below rather than after, so a
    -- swarm's first second is already swarming and a wall does not have to wait
    -- out a frame of ordinary horde to land.
    self:updateEvents(dt, game)

    -- The floor, checked every frame whatever the wave timer says. `floorMul` is
    -- a swarm or a quiet leaning on it, and it is the floor these lean on rather
    -- than the clock on the line above: multiplying the clock would drag the
    -- unlock-independent knobs -- interval, batch -- along with it and make a
    -- fifteen-second swarm briefly a different minute of the game.
    local least = math.min(math.floor(time * FLOOR_RATE * self.floorMul),
        self:hordeMost())
    for _ = 1, math.min(least - #game.enemies, REFILL) do
        self:drop(game, ring)
    end

    -- The waves, on their own timer, on top of whatever the floor is holding.
    self.timer = self.timer - dt
    if self.timer > 0 then return end
    self.timer = math.max(0.22, 1.1 - time * 0.008)

    -- A quiet sets `batchMul` to nought, which is what actually makes it quiet:
    -- past about minute five the floor is no longer the binding constraint on
    -- the page and this tap is, so a lull that only leaned on the floor would be
    -- a lull you could not feel.
    local batch = math.floor((1 + math.floor(time / 25)) * self.batchMul + 0.5)
    local most = self:hordeMost()
    for _ = 1, batch do
        if #game.enemies >= most then break end
        self:drop(game, ring)
    end
end

return Spawner
