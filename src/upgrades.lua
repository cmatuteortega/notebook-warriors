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
-- For the one line that builds a whole `drop` block: the SEAM's wire, which is
-- the stapler's finished block written inside the ruler's own (src/tools.lua).
local Staple = require("src.staple")
-- And for the three that build a whole `cut` block, which carries a ramp: the
-- scissors' slit is drawn paper-first, and paper is the one colour that wipes the
-- ruling under it (`chord` in src/tools.lua, `trimsTheLine` below).
local Palette = require("src.palette")

local Upgrades = {}

-- Every number a run can change about itself, at the value it starts on. A
-- passive weapon is absent rather than zeroed -- the block turning up *is* what
-- brings the weapon into the run.
function Upgrades.baseStats()
    return {
        speed = 1,          -- multiplier on Player.SPEED
        maxHp = 100,
        regen = 0,          -- health a second, healed back on its own
        -- And health as a fraction of the damage the run's own weapons deal
        -- (the bandaid line below, paid out by Loadout:mend). Deliberately not
        -- the same number as `regen` in a trench coat: one is what a run gets
        -- for surviving and this is what it gets for fighting, so a build with
        -- both is a build that is rewarded for standing in the crowd rather than
        -- for walking away from it -- and a run carrying nothing that fights for
        -- it gets nothing at all out of this.
        mend = 0,
        -- Multiplier on the gap between one thing a weapon does and the next:
        -- lower is sooner. The metronome line below is the only thing that moves
        -- it, and it is the one multiplier in the catalogue that no weapon module
        -- reads -- Loadout:rebuild spends it on the blocks themselves
        -- (`scaleCadence`), so every clock in the game goes on being written in
        -- seconds and goes on reading its own number.
        --
        -- It replaced a `fireRate` that src/shot.lua and src/sword.lua read and
        -- nothing else, on the grounds that those two were the only things that
        -- attacked on a beat you had not asked for. Which was never true: a sun
        -- coming up, a bomb going off and a cloud rolling in are all beats nobody
        -- asked for, so there is one dial for all of them rather than one for the
        -- two that happen to come out of the hero's own hands.
        weaponRate = 1,
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
        --
        -- And then the same question asked of the other half of the game, which
        -- is a second number and not a wider reading of this one, for exactly the
        -- reason `toolDamage` and `passiveDamage` are two: a run that draws for a
        -- living and a run that lets the page fight for it are two builds, and a
        -- line worth taking to both is a line neither of them had to choose. So
        -- the fixative moves what you *drew* and the laminate moves what fights
        -- for you, on the same axis and never in the same card.
        markLife = 1,
        passiveLife = 1,
        -- Nothing sells this any more: the elastic band was the one line on the
        -- axis and it is off the roster. It stays at 1 -- the identity -- rather
        -- than going, because two places still read it (`scaleKnock` walks it
        -- into every tool copy, and the spiral's shove is written against it),
        -- so putting the axis back on sale is a row and nothing else.
        knock = 1,          -- multiplier on the shove a mark gives

        -- The two hands-free attacks, which are weapons like any other and were
        -- not always: both used to be a clock inside src/player.lua that every
        -- run carried whether it wanted one or not. A character now opens a run
        -- with one of these lines at level one (`weapon` in src/characters.lua)
        -- and the draft can sell it the other.
        shot = nil,         -- see src/shot.lua
        sword = nil,        -- see src/sword.lua

        star = nil,         -- see src/orbital.lua
        rocket = nil,       -- see src/rocket.lua
        sun = nil,          -- see src/sun.lua
        cools = nil,        -- see src/cools.lua
        beam = nil,         -- see src/beam.lua
        bomb = nil,         -- see src/bomb.lua
        skate = nil,        -- see src/skate.lua
        storm = nil,        -- see src/storm.lua
        birds = nil,        -- see src/flock.lua
        spiral = nil,       -- see src/spiral.lua
    }
end

-- The two damage lines are the same line twice, pointed at the two halves of
-- the game: what you draw and what draws itself. The percentages climb rather
-- than repeat, so the last level of either is worth twice the first and the
-- choice stays live all the way up.
--
-- Four steps rather than five, and the opening one moved up from 15% to 20% to
-- pay for it. Both of those are the same decision: these were the longest
-- passive lines in the draft and the pool they are drawn from is twelve lines
-- deep against five slots, so a run is far less likely to finish either -- which
-- makes what a single pick is worth matter more than what the full line is
-- worth. The end of
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
-- and four upgrades -- and all ten tool lines have their four written now. They
-- were not always: the pen, the stapler and the scissors were unlock-only for a
-- long time, and the draft handled that on its own by never offering a line with
-- no level left in it. What finishing a line is *for* has since become a second
-- thing as well, since a fusion may only be made of lines a run can finish
-- (`needs` in `fusionLine` below) -- the pen's four are why the CORRAL exists.
--
-- Four rather than six since the trim, and two rules picked which two went from
-- each line. The first was the flat ink discount, which every one of the seven
-- had a copy of and the blotter sells to all of them at once. The second was
-- whatever a passive already sold or a later level already overwrote -- the
-- compass's lap and a half against its two, the ruler's 135 against a length
-- the finale measures off the screen. Nothing that a finale stands on went:
-- the rubber keeps the 240 its ram is timed against.
--
-- `opts.levels` is everything after the unlock.
--
-- Nothing here says which tool a run begins holding: that is the lesson's to say
-- (`tool` in src/subjects.lua) and `Loadout.new` takes the named line to level
-- one before the run is built. A line does not need to know whether it was
-- issued or drafted -- either way it is a line at level one with its levels
-- still to come.
local function toolLine(id, name, icon, tool, unlock, opts)
    opts = opts or {}

    local levels = { { text = unlock, apply = function() end } }
    for _, level in ipairs(opts.levels or {}) do
        levels[#levels + 1] = level
    end

    return {
        id = id, name = name, icon = icon,
        kind = "tool", tool = tool,
        levels = levels,
    }
end

-- A *fusion*: a tool line the draft will not deal until every line it is made of
-- has been taken to its last level, and which takes some of those lines off the
-- run as it lands.
--
-- It is a tool line and nothing more exotic than one. Its first level unlocks a
-- tool, its levels are replayed on that tool's copy, it counts against the four
-- places on the strip, the library lists it on the tool shelf and the selector
-- column draws it -- none of which had to be told fusions exist. Two fields are
-- the whole of it:
--
--   needs   line ids that must all be *finished* before this is ever offered.
--           A condition and only a condition -- nothing is taken from a line
--           for being named here.
--   fuses   which of those the run actually spends: their tools come off the
--           strip and their slots come back. Always a subset of `needs`, and
--           always at least one line of this line's own kind, which is what
--           makes a fusion cost the strip *less* than it gives back -- two
--           tools in, one out, one place free. The levels themselves are not
--           refunded and never could be: they are what was fused.
--
-- The split between the two is the interesting half. A fusion may ask for
-- something it does not consume -- the HALO wants a finished FIXATIVE and gives
-- it back untouched -- and that is how a fusion is aimed at a *build* rather than
-- at a pair of tools. What the run had to have been doing to get here is a
-- condition; what the run hands over is a cost; a catalyst is the first without
-- the second.
--
-- Nothing else in the game changes. `Loadout:candidates` is where `needs` is
-- asked and `Loadout:rebuild` is where `fuses` is spent, and both are one clause.
local function fusionLine(id, name, icon, tool, spec)
    local line = toolLine(id, name, icon, tool, spec.unlock,
        { levels = spec.levels })
    line.needs = spec.needs
    line.fuses = spec.fuses
    -- A fusion's unlock may have something to apply where an ordinary tool
    -- line's never does, and the reason is `scaleDamage`: a table the sharpener
    -- writes into has to be built fresh on the run's copy every rebuild, so a
    -- fused tool's `ignite` is assigned by this level exactly as the marker's own
    -- fourth level assigns the marker's (see the HALO row in src/tools.lua).
    if spec.apply then line.levels[1].apply = spec.apply end
    return line
end

-- The ruler's own finale, applied to a fused row's `snap` block: half a screen
-- diagonal reaches the corner of whatever shape of canvas the run ended up on.
--
-- **The only number in the game measured off the window rather than written
-- down**, which is why it cannot live on a row and why every unlock that wants it
-- is handed the screen. `Loadout:rebuild` recomputes it when the window changes
-- shape, so a run that goes fullscreen mid-page gets a longer ruler on the next
-- rebuild rather than a stale one.
--
-- Eight lines want it: the SNAP LINE, where two pins aim a ruler rather than
-- bounding one, and the seven fusions off the ruler itself, every one of which is
-- the whole page by construction -- a fusion is only dealt once both its lines are
-- finished, and a finished ruler rules corner to corner. The eight extra pixels
-- are so the ends clear the corner rather than stopping on it.
local function rulesThePage(t, screen)
    t.snap.length = math.ceil(util.len(screen.w, screen.h) / 2) + 8
end

-- The finished SCISSORS written onto a fused row as a `chord`: a whole `cut` block
-- that is not the row's block, cast between the two ends of the mark the row draws
-- (`Game:chordCut`). Three lines want it and it is one function rather than three
-- copies for `rulesThePage`'s reason -- every number in it is a parent's finished
-- one, and a fusion whose parent moved a number would want it moved in all three.
--
-- **Built by an unlock rather than written on a row, and it must be.** `chord` is
-- not in `Tools.BLOCKS`, so `Tools.copy` does not lift it onto the run's own copy;
-- a table written on the shared row that `scaleDamage` then writes into would
-- compound its multiplier on every rebuild for the rest of the program's life. It
-- is the STITCH's and the SNAG's `fasten`, one shape over.
--
-- The scissors' line, level by level, is all of it: the cap off (`reach`), the deep
-- stretch between the two ends (`blades`), the run-on to both edges (`through`) and
-- the half you are not standing on coming away (`sever`). A fusion is only dealt
-- once both its lines are finished, so a finished pair of scissors is what a fused
-- row inherits.
--
-- `ink` is the parent's own flat 0.3 -- what a cut has always cost -- charged at the
-- release and refused rather than clamped. The row's own `ink` is a price per pixel
-- and stays that, so a run is paying for the line it drew and then for the cut, one
-- each, which is the two halves of the gesture priced as the two things they are.
--
-- `opts` is what one row adds and the others do not: `tapped` for a mark with no two
-- ends worth cutting between (the SHEAR), `ignite` for blades that leave what they
-- cut burning (the SCORCH), `paste` for a crowd that arrives in the corner stuck (the
-- COLLAGE). Every one of them is a field `src/scissors.lua` already reads.
--
-- `paste` rather than a second `hold`: the chord already carries one and it is the
-- tap window (`Game:wasTap`), so seconds of glue on the far side of a cut wants a
-- word of its own -- and paste is the word, since it is the gluestick's own
-- substance travelling with the paper.
local function trimsTheLine(t, opts)
    opts = opts or {}

    t.chord = {
        reach = math.huge, width = 3,
        damage = 12, knock = 0,
        blades = { damage = 20, width = 6 },
        through = true,
        sever = { tick = 0.5, paste = opts.paste },
        life = 1.6, fade = 0.6,
        ramp = { Palette.paper, Palette.paper, Palette.graphite },
        ink = 0.3,
        -- The tap test, and the same two numbers the STUB and the SNAG use for the
        -- same question: what decides is the finger's own travel and how long the
        -- press lasted, never the line, because a finger held still while the
        -- player walks lays real line in world space (`Game:wasTap`).
        tapped = opts.tapped,
        slack = 6, hold = 0.3,
        ignite = opts.ignite,
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
        -- The attack the game opens with, and for most of this project it was
        -- not a line at all: it was a clock inside src/player.lua that every hero
        -- carried, and being a shootman was what set its numbers. Pulling it out
        -- here costs nothing and says something -- a run is what fights, not the
        -- hero, and what it fights with is a list you can add to.
        --
        -- The shootman opens a run holding this at level one (`weapon` in
        -- src/characters.lua), exactly as the lesson opens one holding a tool,
        -- and it spends a weapon slot the same way. Anybody else can draft it.
        --
        -- Five levels, and every one of them is a number rather than a shape,
        -- which is the opposite of the sword standing next to it and is the
        -- point: a pellet going in a straight line at the thing that matters has
        -- no geometry to sell, so what this line sells is the four things a
        -- pellet is -- how often, how fast, how hard, how many. The last is the
        -- only one that changes what the weapon *is*, which is where a level like
        -- that belongs.
        --
        -- The unlock is deliberately *below* where the shot used to sit: slower,
        -- softer and lazier than the beat the rest of the balance was set
        -- against. A shootman opens on that, so the line is where his own weapon
        -- is earned back rather than a thing he arrives finished -- which is what
        -- the starman and the skateman already had and the first two heroes
        -- did not.
        id = "shot",
        name = "SHOT",
        icon = "bullseye",
        kind = "weapon",
        -- The pellet is drawn, on the board the shootman is handed after his own
        -- (src/design.lua) -- so a run that drafts this instead is put on that
        -- board the moment it takes the card, the way the star and the rocket
        -- put you on theirs. The line and that board are the same word for the
        -- same thing, which is why one entry in src/i18n.lua does for both -- and
        -- the card's icon is not the drawing but a bullseye, since what is on
        -- offer is the aim rather than the pellet.
        design = "bullet",
        levels = {
            {
                text = "A SHOT GOES OUT AT WHATEVER IS NEAREST",
                apply = function(s)
                    s.shot = {
                        -- Three of these were the shootman's row in
                        -- src/characters.lua once, at 0.55, 96 and 3 -- the beat
                        -- the rest of the game was set against. What is written
                        -- here is that shot with the line's own levels taken back
                        -- out of it: a shade over half the damage a second, and a
                        -- pellet slow enough that a bat crossing in front of you
                        -- can be missed. Level four is where 3 is passed and
                        -- level two is where the beat is.
                        every = 0.7,    -- seconds between one shot and the next
                        range = 96,     -- about a third of the page, and the one
                                        -- number no level here moves: how far a
                                        -- shot reaches is what tells the two
                                        -- attacks apart, and this line sells the
                                        -- pellet rather than the page
                        damage = 2,     -- a blob in two, a skull in six
                        speed = 80,     -- px a second, against a bat's 38 and the
                                        -- player's 58: quick enough to arrive,
                                        -- slow enough to be walked out from under
                        shots = 1,      -- how many leave on one beat
                    }
                end,
            },
            -- The beat first, because it is the one you feel without being told:
            -- the shot the game was balanced around, handed back.
            { text = "THE SHOT COMES ROUND HALF AGAIN AS OFTEN",
              apply = function(s) s.shot.every = 0.5 end },
            -- Then the flight. It is the level with the least to read on the card
            -- and the most to watch on the page -- what it buys is pellets landing
            -- on things that used to have moved, which against the bats is most of
            -- what a shot misses.
            { text = "THE PELLET FLIES HALF AGAIN AS FAST",
              apply = function(s) s.shot.speed = 130 end },
            -- Then the damage, and it is a doubling rather than a nudge because
            -- this is the level that finally puts the weapon past the shot it
            -- opened below: 4 on a 0.5s beat is half again the 3 on 0.55s that
            -- used to be the whole of it.
            { text = "EACH PELLET HITS TWICE AS HARD",
              apply = function(s) s.shot.damage = 4 end },
            -- The one that changes what the weapon is, and the one the line ends
            -- on: a shot answers the thing that matters, and two answer the two
            -- things that matter. Against a crowd that is coverage this weapon
            -- has never had; against one blob it is both pellets in the same
            -- body, which src/shot.lua is deliberately written to allow -- the
            -- boss is exactly the fight the level is for.
            { text = "TWO PELLETS LEAVE ON EVERY BEAT",
              apply = function(s) s.shot.shots = 2 end },
        },
    },
    {
        -- The other half of the same idea, and the same history: this was what
        -- the melee hero swung instead of shooting, and it is a card now. Being
        -- able to hold both is the whole point of the split -- a shootman who
        -- drafts this has something for whatever walked all the way in, and a
        -- swordsman who drafts SHOT has something for whatever will not.
        --
        -- The swordsman opens a run holding this at level one, and unlike the
        -- shot beside it that first level is the weapon exactly as it has always
        -- been -- nothing was taken out of it to make room for the four after it.
        -- The two lines are written from opposite ends on purpose: a pellet has
        -- only numbers to sell, so SHOT sells four of them, and an arc is all
        -- shape, so this sells the shape and never once sharpens the blade. A run
        -- that wants a swing cutting deeper buys the passive that sells damage to
        -- everything it owns, which is the star's argument (see the note on its
        -- fourth level) and it holds twice as hard here: doubling six on a weapon
        -- that already takes everything standing in the arc is not a level, it is
        -- a different game.
        --
        -- So: longer, then wider, then a shove on whatever lived, then the whole
        -- circle. Three of those are `reach` and `sweep` on the block, which is
        -- why those two moved out of src/sword.lua and onto it.
        id = "sword",
        name = "SWORD",
        icon = "sword",
        kind = "weapon",
        design = "sword",
        levels = {
            {
                text = "A SWORD CUTS AN ARC THROUGH WHAT IS CLOSE",
                apply = function(s)
                    s.sword = {
                        -- The swordsman's row, unchanged: contact range and a
                        -- shade past it, double the shot's old damage, and half
                        -- again as long between swings to pay for the arc.
                        every = 0.825,
                        range = 22,
                        damage = 6,
                        -- How far from the middle of the hero the edge cuts.
                        -- Still contact range -- the hero is 15 across, so this
                        -- is an arm and a blade past his own outline and anything
                        -- at the tip of it is a step from touching you, which is
                        -- the price the damage is paid for -- but an arm's length
                        -- rather than a fist's. It is also the *width* of the arc,
                        -- since the sweep is an angle: every pixel here is 2.4
                        -- pixels of edge.
                        reach = 17,
                        -- Radians one swing covers. A shade under a hundred and
                        -- forty degrees: wide enough that a swing aimed at the
                        -- nearest blob takes the two either side of it, narrow
                        -- enough that there is a behind to be caught from.
                        sweep = 2.4,
                        -- What a survivor is shoved with, at rest. Off rather
                        -- than absent, so this block says up front what the line
                        -- can do to it -- the scissors' `blades` rule.
                        knock = 0,
                    }
                end,
            },
            -- The arm, and it buys two things with one number: seven pixels
            -- further out is also seven pixels of extra edge at every point of
            -- the sweep, so a longer sword is a wider one without the arc having
            -- moved. `range` goes with it and has to -- that is how far off the
            -- weapon will pick something at all, and a sword reaching 24 that
            -- only looks 22 would spend the difference on nothing.
            { text = "THE BLADE REACHES FURTHER OUT",
              apply = function(s)
                  s.sword.reach = 24
                  s.sword.range = 29
              end },
            -- Then the turn: 3.4 radians is a hundred and ninety-five degrees,
            -- so the arc passes the half circle and a swing starts taking things
            -- that were level with you when it went. It costs no time at all --
            -- `TIME` in src/sword.lua is not on this block -- so what this
            -- actually buys is a faster edge over more ground, which is the
            -- level's whole argument for coming after the reach rather than
            -- before it.
            { text = "THE ARC SWEEPS WIDER THAN A HALF CIRCLE",
              apply = function(s) s.sword.sweep = 3.4 end },
            -- The one level in the line that is not geometry, and it is here
            -- because by now the arc is wide enough that a swing leaves a rank
            -- standing rather than a blob. A shove is bought time: whatever lived
            -- through the cut is walking back in from further off, which on a
            -- 0.825s beat is most of the wait. 34 against the rubber's launch is
            -- a stumble rather than a flight -- this is a sword, not a bat.
            { text = "WHAT SURVIVES THE CUT IS KNOCKED BACK",
              apply = function(s) s.sword.knock = 34 end },
            -- The finale, and the shape the whole line was walking towards: an
            -- arc has a behind and a circle does not. Written as a full turn
            -- rather than as a flag, so every angle in src/sword.lua goes on
            -- being an angle -- which is what the unwrapped sweep in that module
            -- exists for. It is a spin and not a pose, since the swing still
            -- takes `TIME`: the edge goes round two and a half times as fast
            -- instead of the arm staying out two and a half times as long.
            { text = "THE SWING GOES ALL THE WAY ROUND",
              apply = function(s) s.sword.sweep = math.pi * 2 end },
        },
    },
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
        -- One of the two lines a character can open a run holding that is not an
        -- unlock and nothing else: the starman is issued level one of this
        -- (`weapon` in src/characters.lua) and the draft goes on selling him the
        -- four after it. Nothing here knows or cares which way it arrived.
        --
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
        -- it, and a volley of rockets empties out of you into the page around
        -- it. A run that has taken both is covered close and far, which is a
        -- shape worth being able to build; a run that has taken one has chosen
        -- which half of the page it is fighting on.
        --
        -- Nothing here is aimed. A rocket goes off down one of the eight
        -- headings the drawing is kept at, picked out of a hat, so what a volley
        -- is worth is the ground it covers rather than what it was pointed at --
        -- which is the cool S read from the other end, and it hands the
        -- answering-the-thing-that-matters half of this pairing over to SHOT.
        -- The line is written straight down that: two of the eight, then four,
        -- then what happens where one stops, then the whole compass. Nothing in
        -- it sharpens a rocket, because what an unaimed volley is short of is
        -- coverage and not damage -- a run that wants each one landing harder
        -- buys the passive that sells damage to everything that fights for it.
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
                text = "TWO ROCKETS GO OFF IN DIRECTIONS NOBODY PICKED",
                apply = function(s)
                    s.rocket = {
                        every = 1.9,    -- seconds between one volley and the next
                        -- Two of them, each going through one, which is where
                        -- the old line's first three levels have gone: an aimed
                        -- rocket could open as a single one that stopped at the
                        -- first thing it met, and an unaimed one that did would
                        -- be a level you took and could not see. So the opening
                        -- level is the volley being a shape at all, and every
                        -- level after it widens the shape.
                        count = 2,
                        pierce = 1,     -- extra enemies one goes through
                        -- A blob or a bat outright and a skull left on 4. The
                        -- same number it always was, and the line still never
                        -- moves it: what changed is that this is now the price
                        -- of standing in the way rather than of being nearest.
                        damage = 8,
                        speed = 88,     -- slower than the biro, and it should be
                        life = 1.6,     -- seconds, so about 140px of flight
                        blast = nil,    -- the fourth level, below
                    }
                end,
            },
            -- The volley and the pierce doubled at once, which the old line
            -- spent two separate levels on and could afford to while a rocket
            -- was fired at somebody. Four of the eight is the first volley that
            -- is properly a pattern -- more of the compass covered than not --
            -- and going through two is what keeps a heading that opens onto a
            -- crowd from being spent on the first blob standing in it.
            { text = "FOUR GO OFF AT ONCE, THROUGH TWO THINGS EACH",
              apply = function(s)
                  s.rocket.count = 4
                  s.rocket.pierce = 2
              end },
            -- The plainest level in the line, and deliberately the middle one:
            -- four through three is the shape the two levels before it have
            -- been building, so this is the level that finishes that shape
            -- rather than the one that changes it.
            { text = "THEY CARRY ON THROUGH THREE",
              apply = function(s) s.rocket.pierce = 3 end },
            -- The one that changes what the weapon *is*, and the answer to the
            -- single thing an unaimed volley is bad at: a rocket that found
            -- nobody used to just stop being there, and now it goes off in a
            -- circle where it ended. So a volley becomes small craters on a ring
            -- around you rather than lines that may or may not have crossed
            -- anything -- see src/rocket.lua for what a burst catches and why it
            -- is asked of the whole horde.
            --
            -- 14px is half the bomb's opening crater, which is the honest size
            -- for something landing two to eight at a time against one bomb
            -- every four and a half seconds. 4 is a blob or a bat outright and a
            -- skull still standing: the burst clears the chaff round whatever
            -- the rocket itself was worth, and does not quietly become the
            -- damage level this line refuses to sell.
            { text = "EACH ONE BURSTS IN A CIRCLE WHERE IT STOPS",
              apply = function(s)
                  s.rocket.blast = { radius = 14, damage = 4 }
              end },
            -- The finale, and with the aiming gone it is the plainest one in the
            -- catalogue: every heading there is, every time. A volley stops
            -- being a couple of directions the run was dealt and becomes a ring
            -- going out of you -- which is also the one volley the shuffle in
            -- src/rocket.lua cannot roll badly, since eight of eight is the
            -- whole compass whatever order they come out in.
            { text = "EIGHT GO OFF AT ONCE, ONE EVERY WAY",
              apply = function(s) s.rocket.count = 8 end },
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
        -- standing in, the rockets go off into the page around it, the sun owns
        -- a corner and waits -- and the cool S takes a straight line across the
        -- whole page and does not care what is on it.
        --
        -- It is the rocket read from the other end and the two want to stay
        -- opposite: a volley leaves *from* you down headings nobody picked, and
        -- an S arrives from off the page on a line that happens to cross you.
        -- Which is why this one is still the one with no relationship at all to
        -- where the enemies are. It is not aimed, it does not seek, and it will
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
                        -- does: it comes in off the page and crosses the whole
                        -- of it through where you were standing, cutting every
                        -- single thing on the line. That is more page swept in
                        -- one arrival than a star covers in ten seconds of
                        -- turning, and it is meant to be an event you watch
                        -- rather than a rhythm you stop noticing.
                        every = 7,
                        -- A little quicker than you walk, which is what makes it
                        -- float rather than fly: you can watch one cross, you can
                        -- walk a crowd into one, and at 320px of page it is on
                        -- screen for four or five seconds. Anything faster would
                        -- be a bullet, and there is already a bullet. Nothing in
                        -- the line moves it -- see src/cools.lua.
                        speed = 70,
                        -- A blob or a bat outright and a skull in three. Lower
                        -- than the rocket's opening 8 because nothing stops one
                        -- of these: it goes through the whole crowd rather than
                        -- through the first thing it meets, and the rocket has
                        -- to buy that with a level.
                        damage = 5,
                        -- None. The first S a run drafts crosses the page once
                        -- and is gone, which is the weakest this weapon is ever
                        -- allowed to be and the whole reason the rest of the
                        -- line reads as one idea: every level after this is
                        -- about the edge of the page refusing to be an ending.
                        bounces = 0,    -- edges of the page it will come off
                        ink = false,    -- and whether pen lines turn it too
                        forever = false, -- and whether it ever stops
                    }
                end,
            },
            -- The first bounce, and the biggest single step in the line: one
            -- bounce is not a longer S, it is a there *and* a back. It cuts the
            -- line you were standing on and then cuts it again from the other
            -- side, and the second pass goes through a crowd that has spent the
            -- first one walking into where it landed.
            { text = "IT BOUNCES OFF THE EDGE OF THE PAGE",
              apply = function(s) s.cools.bounces = 1 end },
            { text = "ONE COMES IN TWICE AS OFTEN",
              apply = function(s) s.cools.every = 3.5 end },
            -- Your own pen lines turn it too. The pen is the one tool that
            -- leaves something solid (`wall` in src/tools.lua), so it is the one
            -- tool that can turn an S -- the ink an enemy has to walk around is
            -- the ink an S comes off -- which makes this level an instruction to
            -- go and draw the shape you want it running around inside.
            --
            -- Ink costs a bounce exactly as the page does, so at this level it
            -- is a *choice* rather than a gift: a run with one bounce in hand
            -- spends it on the wall it drew or on the edge it was heading for,
            -- and drawing the wall in the right place is the whole skill of it.
            -- The level after this is the one that stops making you choose.
            { text = "YOUR PEN LINES BOUNCE IT TOO",
              apply = function(s) s.cools.ink = true end },
            -- The finale, and the one thing in the game that never leaves the
            -- page. The budget stops being a budget: a single S stays up for the
            -- rest of the run, coming off every edge and every pen line it
            -- meets, cutting the crowd again on every pass.
            --
            -- It is a trade rather than a straight upgrade, and worth being
            -- plain about which way it goes. What a run gives up is arrivals --
            -- the clock stops mattering the moment the page is full and never
            -- empties, so `every` above is a number this level retires -- and
            -- what it gets is a permanent line loose on the page. One that is
            -- there is worth more than two that are coming: you learn where it
            -- is, you fight around it, and the pen stops being a wall you draw
            -- against the horde and becomes the shape you keep an S inside.
            { text = "ONE S STAYS ON THE PAGE FOR GOOD, BOUNCING FOREVER",
              apply = function(s) s.cools.forever = true end },
        },
    },
    {
        -- The fifth passive weapon, and the one that breaks the rule the other
        -- four are built on: it is aimed. A star turns where it turns, a volley
        -- of rockets goes off down headings nobody picked, the sun owns whichever
        -- corner it came up in and a cool S arrives from a direction nobody
        -- chose -- all four fight while
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
                        --
                        -- Nothing in the line shortens it. The wind-up is not a
                        -- cost the weapon is apologising for, it is the half of
                        -- the weapon you play: a beam you could not read coming
                        -- would be a beam you could not aim.
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
                        --
                        -- One number the whole way up. What this line sells is
                        -- the beam being *there* -- for longer, more often, over
                        -- more of the page -- and a run that wants it cutting
                        -- deeper buys the graphite that sharpens everything.
                        damage = 6,
                        -- Pixels across the band it cuts, and what it is drawn
                        -- at. Five rather than three because this is the one
                        -- thing in the game made of light rather than of biro:
                        -- at three it read as another pencil line laid across a
                        -- page already full of them, and the whole of what it
                        -- has to say from the far side of the screen is that it
                        -- is not one of your marks.
                        width = 5,
                        arms = 1,       -- ahead, and then behind as well
                    }
                end,
            },
            -- The one that changes what the weapon *is*. Up to here it is a
            -- flash that catches whatever the line was lying across at one
            -- instant, and past it the beam stands there for the best part of a
            -- second and cuts again every fifth of one -- so it stops being a
            -- thing you land on a crowd and starts being a thing the crowd has
            -- to walk through. It also makes the wind-up worth the wait: what
            -- the flash promises is now a place you can hold rather than a
            -- moment you have to time.
            { text = "THE BEAM HOLDS INSTEAD OF FLASHING",
              apply = function(s) s.beam.hold = 0.9 end },
            -- And then the same beam twice as often, which is the plainest
            -- level in the line and wants to be: it comes after the one that
            -- made a shot worth waiting for, and it is the level that turns the
            -- weapon from an event into a rhythm you can walk to.
            { text = "IT COMES ROUND TWICE AS OFTEN",
              apply = function(s) s.beam.every = 2.5 end },
            -- Nine rather than five, which is the one level that changes what a
            -- beam *catches* rather than when it is there. The line is aimed
            -- with your feet and your feet are not precise, so the honest thing
            -- to sell is forgiveness: a band half again as wide is a crowd you
            -- had to line up a little less exactly, and the two pixels either
            -- side are worth more against a horde walking across the line than
            -- more damage down the middle of it would be.
            { text = "THE BEAM CUTS A WIDER BAND",
              apply = function(s) s.beam.width = 9 end },
            -- The finale, and the shape the line has been walking towards: the
            -- horde arrives from every side, so the half of the page a single
            -- beam leaves behind it is the half you turned your back on. Firing
            -- out of both ends of the same line answers that without touching
            -- what the line is worth -- and it is what makes walking *through* a
            -- crowd rather than away from one a way to play.
            --
            -- Both ends of one line and not a cross, which this was for a while:
            -- a perpendicular pair only pays when you are stood exactly between
            -- two crowds, which is not a thing anyone can arrange, and four
            -- beams out of a hero standing in the middle stops reading as
            -- something you aimed at all.
            { text = "A SECOND BEAM FIRES OUT BEHIND YOU",
              apply = function(s) s.beam.arms = 2 end },
        },
    },
    {
        -- The sixth passive weapon, and the only one that makes the player wait.
        -- The other five resolve the instant they act -- a star cuts what it
        -- turns through, a rocket leaves, a beam is a flash, an S crosses -- so
        -- all five are things that happen *to* the crowd. This one is put down at
        -- your feet and then does nothing for a couple of seconds, which turns
        -- the ground you just left into somewhere: the crowd walks in while you
        -- walk out.
        --
        -- Which makes the fuse the whole weapon, and the line is written down it.
        -- Never aimed -- the aim is where your feet were, the cool S's bargain
        -- from the other end, an S being a line through where you were standing
        -- and a bomb a hole in it -- so what the levels sell is the crater, the
        -- rhythm and the wait, and finally the crater going on burning after the
        -- bang.
        id = "bomb",
        name = "BOMB",
        icon = "bomb",
        kind = "weapon",
        -- Drawn rather than issued, like every weapon but the beam -- and the one
        -- board whose drawing is shown in a colour it was not drawn in, since the
        -- fuse flashes the silhouette blue. Which is the one thing to know before
        -- drawing on it: what blinks is the shape, so a shape worth seeing filled
        -- in is what the board is asking for.
        design = "bomb",
        levels = {
            {
                text = "A BOMB DROPS AT YOUR FEET AND BLOWS UP WHAT IS STILL THERE",
                apply = function(s)
                    s.bomb = {
                        -- Slower than the rocket and quicker than an S. What one
                        -- of these is worth is everything standing in a circle,
                        -- at full damage, with no pierce to buy and nothing to
                        -- stop it -- but only what is *still* standing there when
                        -- the fuse runs out, and the crowd has a couple of
                        -- seconds to be somewhere else.
                        every = 4.5,
                        -- Long enough to walk clear of your own crater at 58px a
                        -- second and short enough that what was chasing you is
                        -- still in it. Under a second and it is a weapon that
                        -- goes off where you are rather than where you were;
                        -- much over two and the crowd simply arrives after it.
                        fuse = 2.2,
                        -- A blob or a bat outright and a skull in two, which is
                        -- the beam's opening number and the same argument: this
                        -- covers an area rather than a line, and the crowd was
                        -- given time to leave it.
                        damage = 6,
                        -- Pixels of crater. The star's ring is 22 out and the
                        -- sun's disc is 60, so this opens at exactly the ring you
                        -- already know the size of -- one bomb takes the circle
                        -- you were standing in the middle of.
                        radius = 22,
                        burn = nil,     -- the finale, below
                    }
                end,
            },
            -- The one that changes the *shape* of what the weapon covers, and it
            -- is the first level for the star's reason: half again as far out is
            -- well over twice the paper, so the crater stops being the ring round
            -- your feet and becomes a piece of the page. It is also the level the
            -- blast ring exists for -- a crater nobody could see the edge of
            -- would be a crater nobody could learn.
            { text = "THE BLAST REACHES HALF AGAIN AS FAR",
              apply = function(s) s.bomb.radius = 33 end },
            -- The plainest level in the line, and it comes after the one that
            -- made a bomb worth walking away from: twice as often is what turns
            -- it from a thing you place into a rhythm you walk.
            { text = "ONE DROPS TWICE AS OFTEN",
              apply = function(s) s.bomb.every = 2.25 end },
            -- The fuse, and the one level that is really about the crowd rather
            -- than about the bomb: half the wait is half the page the horde gets
            -- to cross before it goes off, so what was a threat you had to lead
            -- things into starts catching whatever was already following you.
            -- BLINK does not move with it (src/bomb.lua), so a short fuse is lit
            -- almost the moment it lands and nothing ever goes off unannounced.
            { text = "THE FUSE BURNS TWICE AS FAST",
              apply = function(s) s.bomb.fuse = 1.1 end },
            -- The finale, and the only thing in the line that outlives the bang:
            -- the crater goes on burning for four seconds, cutting twice a second
            -- whatever is standing in it. It is the same blot the boss drags
            -- behind it (src/puddle.lua) in the other half of the palette, and it
            -- is exactly the crater, so this level is worth precisely as much as
            -- the one that widened it -- the two of them together are what make a
            -- bomb ground the horde has to go round rather than a moment it has
            -- to survive.
            --
            -- 2 a tick is deliberately the smallest number a weapon in this game
            -- hits for: what the level sells is the ground being *taken*, not the
            -- damage, and a burn that killed on its own would make the bang the
            -- part you waited through.
            { text = "THE CRATER GOES ON BURNING AFTER THE BANG",
              apply = function(s)
                  s.bomb.burn = { damage = 2, tick = 0.5, life = 4 }
              end },
        },
    },
    {
        -- The seventh passive weapon, and the only one that is a surface. Every
        -- other one is a thing that *happens* -- a star cuts what it turns
        -- through, a rocket leaves, a beam flashes, an S crosses, a bomb goes off
        -- -- and the closest any of them comes to this is the crater the bomb's
        -- last level leaves smouldering, which is one patch of ground somewhere
        -- you had already decided to be. A skate turns the whole line you have
        -- walked into that patch, for as long as you keep walking.
        --
        -- So it is aimed with your feet and aimed *behind* you, which is not the
        -- laser beam's question over again: the beam asks whether you will turn
        -- and face a crowd, and this asks whether you will let one follow you.
        -- Whatever is closest to catching you is walking its own centre down the
        -- line your centre just left, and the crowd cannot stop chasing.
        --
        -- The line sells that bargain getting better rather than the damage
        -- getting bigger: the trail cuts, then it takes their footing, then it
        -- cuts deep enough to finish what the string-out started, then the fresh
        -- end of it carries you faster, and finally every gem lying on it comes
        -- to you.
        id = "skate",
        name = "SKATE",
        icon = "skate",
        kind = "weapon",
        -- The other line a character opens holding: the skateman is issued level
        -- one of this, which makes him the one hero whose whole attack is the
        -- ground he has just left -- he cannot stand still and fight until he has
        -- drafted something that does.
        --
        -- Drawn rather than handed over, and the one board that goes *under* another
        -- drawing: it is laid at the hero's feet in place of his shadow, and it
        -- is as wide as the board he was drawn on so that it reads as something
        -- he is standing on. Which is also the one thing to know before drawing
        -- on it -- having one takes his walk bounce away, so what anybody draws
        -- here is a thing seen sliding and never bobbing.
        design = "skate",
        levels = {
            {
                text = "A SKATE LEAVES A TRAIL THAT CUTS WHAT FOLLOWS YOU",
                apply = function(s)
                    s.skate = {
                        -- Three seconds, which at 58px a second is about half a
                        -- page of line behind you. Long enough that a crowd
                        -- following you is standing in it and short enough that
                        -- the page is not eventually all trail -- the one weapon
                        -- whose whole footprint is a length of time.
                        life = 3,
                        -- Two a cut, twice a second, which is the smallest thing
                        -- in the game hitting on the tick the bomb's burn hits
                        -- on. Both of those are the point rather than timidity:
                        -- this is the only damage in the game that lands on the
                        -- crowd *continuously* and without being aimed at all,
                        -- so what the first level buys is the trail existing.
                        -- The third level is where it starts killing.
                        damage = 2,
                        tick = 0.5,
                        slow = 1,        -- what standing in it does to their legs
                        boost = 1,       -- and what the fresh end does to yours
                        magnet = false,  -- and whether xp on it comes to you
                    }
                end,
            },
            -- Their footing, and the biggest step in the line for what it does to
            -- the *shape* of a fight rather than to a number. A crowd chasing you
            -- arrives in a lump; a crowd chasing you down a line that takes two
            -- fifths of its legs arrives strung out along the line, fastest
            -- first, which is a fight you can walk backwards through. It is the
            -- crayon's wax pointed at speed instead of at steering -- and unlike
            -- the wax it is not a lane you had to draw first.
            { text = "WHAT STANDS IN THE TRAIL LOSES ITS FOOTING",
              apply = function(s) s.skate.slow = 0.6 end },
            -- And then the cut that finishes them. Two to five is the one place
            -- in this line where a number simply gets bigger, and it comes third
            -- because it is worth most after the level above it: a crowd strung
            -- out along the line is a crowd standing in it for longer.
            { text = "THE TRAIL CUTS FAR DEEPER INTO WHAT STANDS IN IT",
              apply = function(s) s.skate.damage = 5 end },
            -- The one level that pays *you* for going back over your own line,
            -- and it is deliberately only the wet end of it (`FRESH` in
            -- src/skate.lua): the stretch you laid four seconds ago is a trap for
            -- the crowd and the stretch you laid one second ago is a road, so
            -- what this buys is turning back into your own trail rather than
            -- laying a lap and living on it. The wet end is already the part
            -- drawn with its rim on, so the boost arrives with a readout it did
            -- not have to invent.
            { text = "YOU RIDE THE FRESH END OF YOUR OWN TRAIL FASTER",
              apply = function(s) s.skate.boost = 1.45 end },
            -- The finale, and the magnet's other half in the way top marks is:
            -- the magnet buys a radius round where you are and this buys the
            -- shape of where you have *been*, so a lap of the page collects the
            -- lap. It is the one level in any weapon line that pays in xp rather
            -- than in damage, and it can be because this is the one weapon that
            -- leaves a map of the run behind it.
            { text = "EVERY GEM ON THE TRAIL COMES TO YOU",
              apply = function(s) s.skate.magnet = true end },
        },
    },
    {
        -- The tenth passive weapon, and the only one that arrives from outside
        -- to do a job. A cloud rolls in off the edge of the page, parks itself
        -- over somebody, fills up, drops a bolt through the paper and drifts off
        -- the other side.
        --
        -- It is the cool S turned round, which is the pair worth keeping: an S
        -- comes in from outside aimed at *you* and cuts a whole line it never
        -- corrects, and this comes in from outside aimed at *them* and takes one
        -- small circle it stopped over. A line and no target against a target and
        -- no line -- and the target is nobody in particular, one of the crowd at
        -- random, because a cloud is weather rather than a promise.
        --
        -- What it is for is the number: one bolt is the biggest single hit any
        -- weapon in this game lands in one place, and it lands somewhere in the
        -- crowd every few seconds whatever your hands are doing. It is
        -- deliberately one short of the skull's 12hp -- the pushpin's rule -- so
        -- the toughest thing in the crowd is what the line has left to sell.
        id = "storm",
        name = "STORM",
        icon = "storm",
        kind = "weapon",
        -- The bolt is drawn (src/design.lua) and the cloud is not, which is the
        -- one board that is half of a weapon on purpose: the bolt is what the
        -- thing *does* and the cloud is only what carries it in. It is also the
        -- board where the *height* of the drawing is a measurement -- the cloud
        -- hangs exactly a bolt above whatever it is about to strike.
        design = "lightning",
        -- The line runs the way the visit does rather than the way the damage
        -- does, and nothing in it makes a bolt hit harder: a wider circle, a
        -- second cloud, a cloud that stays and strikes three times, and finally a
        -- bolt that is passed on by everything it failed to kill. Which is the
        -- one thing to hold onto if any of it is retuned -- what a storm is worth
        -- is how much of the page it is standing over, and `damage` is the number
        -- the graphite line is for.
        levels = {
            {
                text = "A CLOUD ROLLS IN AND STRIKES THE CROWD WITH LIGHTNING",
                apply = function(s)
                    s.storm = {
                        -- Slower than a bomb drops, since one of these takes a
                        -- couple of seconds to arrive before it does anything --
                        -- what a run is buying is the whole visit rather than the
                        -- moment at the end of it.
                        every = 5,
                        -- One short of a skull, the pushpin's number: the biggest
                        -- single hit in the game and still not quite enough for
                        -- the toughest thing in the crowd.
                        damage = 10,
                        -- Pixels of strike, and the smallest circle any weapon
                        -- here covers -- half the bomb's opening crater. A bolt
                        -- is a point rather than a blast, so what it takes is
                        -- whoever it was aimed at and whoever was standing with
                        -- them.
                        radius = 12,
                        -- How many places one cloud visits before it leaves, and
                        -- how many clouds may be over the page at once. One and
                        -- one: a visit, and a single event to watch land. The
                        -- line sells both.
                        bolts = 1,
                        clouds = 1,
                        -- How fast it drifts, and it has two floors under it
                        -- rather than a reason of its own. It has to beat the
                        -- quickest thing in the crowd (the bat, at 38), since a
                        -- cloud follows what it has marked and one that could not
                        -- keep up would be a weapon that misses; and it has to
                        -- beat the player (58) for the cool S's reason, a cloud
                        -- slower than you being one you could walk to the edge of
                        -- the page and hold there for ever. At 96 the longest
                        -- arrival there is -- a corner of the page -- is about
                        -- two seconds, which is the whole of the visit you watch.
                        speed = 96,
                        chain = nil,    -- the finale, below
                    }
                end,
            },
            -- The circle, first, for the bomb's reason: half again as far out is
            -- well over twice the paper, so what changes is not how hard a bolt
            -- hits but how many things were standing near enough to it. It is
            -- also the level the ring exists for -- everything else in this line
            -- is about where the cloud goes, and this is the only one you read
            -- off the strike itself.
            { text = "THE BOLT TAKES A WIDER CIRCLE WITH IT",
              apply = function(s) s.storm.radius = 18 end },
            -- A second cloud, which is the first level that changes what the
            -- weapon *is*: one cloud is an event that lands every few seconds and
            -- two are weather, arriving from two directions on two clocks and
            -- never over the same enemy (`Storm:taken`). It is the star's second
            -- star and the sun's second sun, and it stops at two for the same
            -- reason a third S is never offered -- a page with three of them on
            -- it is a page you cannot read.
            { text = "A SECOND CLOUD ROLLS IN WITH IT",
              apply = function(s) s.storm.clouds = 2 end },
            -- And then the visit stops being a visit. A cloud that has struck
            -- stays and works its way along the crowd it is already over
            -- (`LINGER` in src/storm.lua) instead of leaving, so what arrives is
            -- no longer a bolt but a couple of seconds of being stood under.
            -- Three rather than two because the shape of the thing is a *stay*:
            -- one more strike would read as the cloud having missed.
            { text = "A CLOUD STAYS AND STRIKES TWICE MORE BEFORE IT GOES",
              apply = function(s) s.storm.bolts = 3 end },
            -- The finale, and the only damage in the game that spreads. What
            -- survives a bolt hands it on to whoever is standing near it, and
            -- they hand it on again, for as long as the crowd is dense enough to
            -- carry it -- so the level is worth nothing at all against one thing
            -- and worth the whole page against forty, which is the opposite of
            -- how every other weapon's last level scales and the reason to end
            -- the line on it.
            --
            -- It runs along the *living*: a zap is passed on by what it did not
            -- kill, so the chain stops at every kill as well as at every gap.
            -- That is what keeps it from being a screen-clear -- a strong run
            -- kills the first rank outright and the zap never leaves it, and a
            -- run whose damage has not kept up is the one that watches it cross
            -- the page. Nothing else in this game pays a run for hitting softly.
            { text = "WHAT SURVIVES A BOLT PASSES IT ON TO WHOEVER IS NEAR",
              apply = function(s)
                  s.storm.chain = {
                      -- A little over a body's width apart, so a crowd carries it
                      -- and a straggler does not. It is measured centre to centre
                      -- like every other circle here.
                      range = 26,
                      -- What is left of the zap at each hop. Three fifths, which
                      -- against the opening 10 is 6, 3.6, 2.1, 1.3 and then under
                      -- the point of a point (`MIN_ZAP`) -- five jumps from a
                      -- bolt that has not been sharpened, and further from one
                      -- that has, since the falloff runs off the damage the run
                      -- actually deals.
                      falloff = 0.6,
                  }
              end },
        },
    },
    {
        -- The eleventh weapon, and the one that is not an event. Every other
        -- thing that fights for you arrives on a beat you can count -- a star
        -- comes round, a rocket goes up, a bomb goes off, a cloud parks itself
        -- overhead -- and this is a handful of small things milling about where
        -- you happen to be, taking a pixel off whatever they brush past. So it is
        -- the star read the other way round rather than a second orbit: a star is
        -- one thing on a ring bolted to you, and nothing in a flock holds
        -- formation with anything (see `CHASE` in src/flock.lua, which is the
        -- whole of the difference).
        --
        -- It opens on the smallest attack in the game -- one bird, one point of
        -- damage -- on purpose. What the line sells is that there is more of it:
        -- five, then a deeper bite, then eight with a couple of them running
        -- errands, and finally a swarm spread across the page instead of a wheel
        -- round you. A run that drafts the first level and nothing else has
        -- bought a doodle for company, and that is an honest thing for a card to
        -- be worth.
        id = "birds",
        name = "M BIRDS",
        icon = "birds",
        kind = "weapon",
        -- Drawn, like nearly everything that fights for you, and the board with
        -- the most copies of what is on it -- fourteen at the top of the line.
        design = "bird",
        levels = {
            {
                text = "A BIRD WHEELS ROUND YOU AND NICKS WHAT IT PASSES",
                apply = function(s)
                    s.birds = {
                        count = 1,
                        -- One. Nothing else in the game deals one, and the whole
                        -- line is written off the fact that this one does.
                        damage = 1,
                        -- How far from the middle of the flock a bird may be
                        -- sent, and how much of that circle it is sent into: a
                        -- loose shell around you at a quarter, anywhere at all
                        -- from your feet outwards near one. Which is the level
                        -- that makes it a swarm -- see Flock:wander.
                        reach = 34,
                        spread = 0.6,
                        -- Pixels a second, jittered per bird (85 to 120). The
                        -- floor under it is the fastest the player can ever be
                        -- made -- 58 through a maxed paper plane is 81 -- because
                        -- a bird that could be outrun would turn the flock into a
                        -- queue behind a running hero. A bird is quick; this is
                        -- the one number here that is allowed to be.
                        speed = 100,
                        rehit = 0.55,    -- before the same bird nicks the same thing
                        carriers = 0,    -- how many fetch xp instead of flying loose
                    }
                end,
            },
            -- Five at once, which is where it stops being a doodle: one bird is
            -- something you notice and five are something the crowd walks into.
            { text = "A FLOCK OF FIVE COMES WITH IT",
              apply = function(s) s.birds.count = 5 end },
            -- The only level in the line that touches the number. Three, because
            -- the step from one has to be felt and every other level here is
            -- about how many beaks there are.
            { text = "EVERY BIRD BITES THREE TIMES AS DEEP",
              apply = function(s) s.birds.damage = 3 end },
            -- And the one that changes what a bird *is*: two of them stop
            -- fighting and start fetching. What they go and get is the xp lying
            -- where you killed something and then walked away from -- anything
            -- already inside the magnet is left alone (Flock:fetch), so this is
            -- reach on your income rather than another magnet level.
            { text = "THREE MORE JOIN AND SOME FETCH YOUR GEMS",
              apply = function(s)
                  s.birds.count = 8
                  s.birds.carriers = 2
              end },
            -- The finale, and it is the room rather than the count doing the
            -- work: fourteen birds sent anywhere from the hero's own feet to a
            -- page-width of flock around him is a cloud you are standing inside,
            -- where five in a loose shell is something following you about. Which
            -- is a thing this line can end on that no other weapon does --
            -- everything else covers ground by reaching further, and this covers
            -- it by filling in what it already reached.
            { text = "THE FLOCK BECOMES A SWARM ALL OVER THE PAGE",
              apply = function(s)
                  s.birds.count = 14
                  s.birds.spread = 0.9
                  s.birds.reach = 46
              end },
        },
    },
    {
        -- The twelfth weapon and the only one that does no damage whatsoever.
        -- What it sells is *where the fight is*: a spiral winds onto the page and
        -- everything near it walks in and stays there, which is the one thing
        -- none of the other eleven can arrange -- a bomb at your feet, a beam
        -- down your line and a bolt out of a cloud are all answers to the
        -- question of where the crowd already is, and this is the question.
        --
        -- So it is worth the most next to everything else and the least on its
        -- own, and that is the shape of the card rather than a flaw in it. A run
        -- carrying a sun, a crater or a swarm and a spiral is a run that has
        -- decided where the killing happens; a run carrying only this has drawn a
        -- very good hole in the page.
        --
        -- The pull is a lure and the last level's push is a shove, and the
        -- difference is load-bearing -- see the top of src/spiral.lua. Nothing in
        -- the line makes anything hit harder, because there is nothing here that
        -- hits.
        id = "spiral",
        name = "SPIRALS",
        icon = "spiral",
        kind = "weapon",
        -- No `design`, and it is only the second line without one (the laser beam
        -- is the other). A spiral is drawn by arithmetic -- so many arms, so many
        -- turns, wound either way, spinning -- and a board holds a fixed grid of
        -- pixels used exactly as drawn. There is nothing in a curve for a drawing
        -- to be.
        levels = {
            {
                text = "A SPIRAL WINDS ONTO THE PAGE AND DRAWS THE CROWD IN",
                apply = function(s)
                    s.spiral = {
                        every = 5,       -- seconds between one and the next
                        most = 1,        -- how many may be on the page at once
                        life = 3,        -- seconds one stays before it fades
                        radius = 40,     -- how far it reaches, and how wide it draws
                        -- How long a thing keeps walking in after the spiral has
                        -- stopped telling it to. Short enough at the opening that
                        -- walking out of the pull is walking out of it.
                        hold = 0.4,
                        push = nil,      -- the finale, below
                    }
                end,
            },
            -- Two of them and twice as often, which between them mean there is
            -- nearly always one somewhere: one spiral is a thing that happens and
            -- two are a page with places in it.
            { text = "TWO WIND ON AT ONCE AND TWICE AS OFTEN",
              apply = function(s)
                  s.spiral.most = 2
                  s.spiral.every = 2.5
              end },
            -- Half again as far out, which is well over twice the paper -- the
            -- bomb's level and the same arithmetic. What changes is not how hard
            -- it pulls but how much of the crowd was standing near enough to be
            -- pulled.
            { text = "THEY REACH FURTHER ACROSS THE PAGE",
              apply = function(s) s.spiral.radius = 58 end },
            -- Longer on the page and a far longer hold, which is the level that
            -- turns a gather into a *pile*: at a second and a half nothing walks
            -- out of one under its own steam, so what a spiral leaves behind it
            -- is a crowd still coming back for a moment after the ink has gone.
            { text = "WHAT THEY CATCH IS HELD IN FOR LONGER",
              apply = function(s)
                  s.spiral.life = 5
                  s.spiral.hold = 1.5
              end },
            -- And the other sign. One spiral round your own feet for the rest of
            -- the run, pushing rather than pulling, which is the only thing in
            -- this game that answers the question of what is standing on you.
            --
            -- A shove and never a lure: something told to walk away from you
            -- would never come back, and a run nothing could reach is a run
            -- without a difficulty. What this buys is a treadmill -- knockback
            -- decays, so a blob loses most of its ground, a bat loses some of it,
            -- and the boss (whose `knock` is 0.06) walks in as if none of it were
            -- happening.
            { text = "ONE WINDS ROUND YOU AND PUSHES INSTEAD OF PULLING",
              apply = function(s)
                  s.spiral.push = { radius = 34, force = 30 }
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
    -- The two axes the whole catalogue divides damage along, and which side the
    -- hero's own attack is on is worth knowing: the shot and the swing are both
    -- `passiveDamage`, since neither is aimed -- graphite sharpens them, the
    -- sharpener does not. That is the same split for both characters
    -- (src/characters.lua), so a run that drafts graphite gets the same
    -- percentage whether what it is multiplying leaves the hand or stays in it.
    --
    -- The sharpener sells the drawing half, and the name is the point of it: a
    -- sharpener is what you put a pencil in, so what it buys is every mark on
    -- the page biting deeper. It used to be called the scissors, until the
    -- scissors turned out to be a tool -- see the tool lines below, and note
    -- that the two are now completely separate things: the passive deepens
    -- everything you draw, including a cut, and the tool is one of them.
    risingLine("sharpener", "SHARPENER", "sharpener", "toolDamage", "WHAT YOU DRAW"),
    risingLine("graphite", "GRAPHITE", "graphite", "passiveDamage", "WHAT FIGHTS FOR YOU"),
    {
        -- The third axis of the same thing, and the one the catalogue was
        -- missing: not what a hit is worth but how often one lands. Damage and
        -- cadence are the two halves of everything a run actually deals, and
        -- until this line existed only the first half was for sale -- each weapon
        -- line decides how often that weapon comes round, and nothing pointed at
        -- all of them at once.
        --
        -- What it moves is the **gap** and never the thing itself. A wind-up, a
        -- fuse, a sun's time up, the length of a beam and every tick something
        -- already on the page hurts on are all left exactly where their own line
        -- put them. Two of those are worth saying out loud, since they are the
        -- ones somebody will reach for: a shorter fuse is a level of the bomb's
        -- own line and this must not quietly sell it again, and a faster tick is
        -- damage per second wearing a cadence's card -- the sharpener's job, on
        -- exactly the reasoning the fixative's own exclusions are written on
        -- (`scalePersistence` in src/loadout.lua). Which numbers those are and why
        -- lives with the pass that spends this one, next to that.
        --
        -- The steps are the blotter's to the decimal, and that is the whole of how
        -- the size of them was picked: those are the two lines in the catalogue
        -- that make a number *smaller*, so they make it smaller at the same rate.
        -- Taken to the end everything comes round 1.73 times as often, which is a
        -- good deal less than the 2.73 either damage line is worth -- the right
        -- way round, since a rate multiplies whatever the damage lines did to
        -- every weapon at once.
        --
        -- One place it pays out more than anywhere else, and it is allowed to: the
        -- laser beam's rest is what is left of its period once the wind-up and the
        -- beam itself have taken theirs, so shortening the period comes out of the
        -- gap alone and a maxed pair leaves nothing of it. Beam:rest is already
        -- written for that shape -- it floors at nothing rather than running
        -- backwards -- so what that run gets is a weapon that is never idle: the
        -- pointer starts winding up on the frame the last beam goes out.
        --
        -- Not a beam that never stops, which is worth being exact about. The
        -- wind-up is a phase of its own and the rest is what runs out, so a
        -- floored rest still has 0.6s of charge behind every beam -- and the line
        -- still refuses to sell that. The laminate arrives at the same floor from
        -- the other side, by lengthening the beam rather than shortening the
        -- period, and neither of them can go past it.
        id = "metronome",
        name = "METRONOME",
        icon = "metronome",
        kind = "passive",
        levels = {
            { text = "EVERYTHING THAT FIGHTS FOR YOU COMES ROUND SOONER",
              apply = function(s) s.weaponRate = s.weaponRate * 0.88 end },
            { text = "SOONER AGAIN",
              apply = function(s) s.weaponRate = s.weaponRate * 0.88 end },
            { text = "SOONER AGAIN",
              apply = function(s) s.weaponRate = s.weaponRate * 0.88 end },
            { text = "NOTHING ON THE PAGE WAITS ITS TURN",
              apply = function(s) s.weaponRate = s.weaponRate * 0.85 end },
        },
    },
    -- The tool lines. One per row of Tools.list, and every one of them opens
    -- with the tool itself: you do not start a run holding the strip, you start
    -- it holding a pencil, and everything else has to be drafted.
    --
    -- Four tools is all a run may carry (Loadout.SLOTS), and the pencil is one
    -- of the four from the first frame -- so the draft is really offering three.
    -- That is the point of unlocking them: ten tools you can all reach is ten
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
        "A PENCIL. IT SCRATCHES WHATEVER YOU DRAW OVER", { levels = {
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
    -- The pen's four. The tool is terrain and the line never stops being that:
    -- nothing here shoves, and what damage it does buy is the *fence* being
    -- leaned on or coming off the paper rather than the pen being swung. It
    -- opens by making one stroke more wall, then charges the crowd for standing
    -- against it, then makes the mark's own last second an event, and ends by
    -- taking the clock off it altogether -- which is the tool's written
    -- argument (a wall is only worth drawing if it outlives the panic that made
    -- you draw it) taken as far as it goes.
    --
    -- Longer and cheaper are deliberately absent, as they are everywhere else:
    -- the fixative sells the first to every mark with a life and the blotter the
    -- second to every tool. Neither is what a *fence* is short of.
    toolLine("pen", "PEN", "pen", "PEN",
        "A PEN. ITS LINE IS A WALL THEY CANNOT CROSS", { levels = {
            -- The nib the tool row authored (src/tools.lua): 7px of blue
            -- instead of 3, and the wall's reach doubled with it, since
            -- Walls:rebuild files a segment at the tool's own radius. Same
            -- price per pixel of path, so it is the cheapest page this line
            -- ever sells -- which is why it opens on it.
            { text = "A BROADER NIB LAYS A THICKER WALL",
              apply = function(t)
                  t.radius = t.broad.radius
                  t.stamp = t.broad.stamp
              end },
            -- The first damage the pen has ever done, and it is the wall doing
            -- it: 1 a tick to whatever is pressed against the ink, which is a
            -- blob in four hits and a skull in twelve. Slight on purpose -- the
            -- crowd walks the length of a fence rather than standing on it, so
            -- this is paid out over the whole line for as long as the line
            -- lasts, and a pen that killed anything promptly would be a pencil
            -- that also stops people.
            --
            -- `linger` is the highlighter's machinery unchanged (Stroke:update),
            -- `rehit` paces the same enemy, and `graze` is the two pixels of
            -- slack a wall needs to be measurable at all: Enemy:resolveWalls
            -- parks a body at exactly the ink's edge, so a tick measured at the
            -- radius alone lands on floating-point luck. Nothing about the
            -- shove moves, and nothing ever will -- `knock` stays 0 through
            -- scaleKnock whatever is written on that axis.
            { text = "THE LINE STINGS WHATEVER LEANS ON IT",
              apply = function(t)
                  t.damage = 1
                  t.linger, t.tickRate, t.rehit = true, 0.5, 0.5
                  t.graze = 2
              end },
            -- The mark's own end, which up to here was the one moment a pen
            -- line was worth nothing: the fade is the warning that the fence is
            -- about to stop stopping anything, and this is what the warning is
            -- now warning about. 4 is a blob exactly -- the pencil's loop and
            -- the gluestick's tear are the same number for the same reason --
            -- and it lands along the whole line at once, so a wall drawn across
            -- the front of the horde and left to run out takes the rank leaning
            -- on it with it. The one thing in the game a *timer* the player
            -- started is the trigger for. See Stroke:pop.
            { text = "WHEN THE LINE GOES IT TAKES THE CROWD WITH IT",
              apply = function(t) t.pop = { damage = 4, reach = 6 } end },
            -- The finale, and the level the tool has been arguing for since it
            -- was written: the last line you drew has no clock on it at all. It
            -- changes what the pen *is* -- a stroke you spend and redraw becomes
            -- a fence you place and keep -- and it changes what the meter is
            -- for, since holding ground stops costing anything per second.
            --
            -- One line, and that is the whole of what holds it down: drawing the
            -- next is what lets the last one go, so the page cannot be latticed
            -- shut, and what is released fades on its ordinary nine seconds --
            -- then pops, if the level above was taken, which makes replacing a
            -- wall a thing you can aim. A run that does box itself in has spent
            -- its whole meter on ground it can never move and is still standing
            -- on a page the eyes shoot over and the boss has to be killed on.
            { text = "THE LAST LINE STAYS UNTIL YOU DRAW ANOTHER",
              apply = function(t) t.keep = true end },
        } }),
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
            -- 41px of crater to 51. It used to be measured against the compass;
            -- it no longer can be, since a compass takes no area at all now
            -- (src/compass.lua) and this is uncontested as the biggest single
            -- patch of page anything in the game covers at once. What holds it
            -- down instead is its own price and the crater's 10, which is one
            -- short of the toughest thing in the game on purpose.
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
    -- The stapler's four, and the line is the tool changing its mind about what
    -- it is. It is written down as a fastener that barely hurts, tapped one
    -- expensive decision at a time (src/tools.lua), and the four levels buy both
    -- halves of that back: it hits like something now, it hits far harder one
    -- time in five, the page it has covered is page you move quickly across, and
    -- the last level turns the tap into a drag. What none of them touches is the
    -- price -- ten a meter, whether you place them one at a time or run a seam.
    --
    -- The pushpin next to it went the other way on purpose: nothing there raises
    -- the crater's 10 or shortens the fall, because that tool's design *is* one
    -- big telegraphed decision. This one is a hundred small ones, so its line
    -- sells the thing a hundred small ones can be: a rate, and a page you have
    -- worked over.
    toolLine("stapler", "STAPLER", "stapler", "STAPLER",
        "A STAPLER. TAP AND IT FASTENS ONE TO THE PAGE", { levels = {
            -- 2 is a bat and nothing else -- the written tool is a fastener that
            -- happens to scratch. 6 is a blob, a bat, a drop and a wad outright,
            -- and half a skull, which is the first level in the line and the
            -- biggest single thing in it: the tool stops being something you
            -- spend to *hold* a body still for whatever else you own, and starts
            -- being something that clears the thing it landed on.
            --
            -- Still nowhere near the pin's 10, and it should not be: that crater
            -- takes a 41px circle for four and a half times the ink, and this is
            -- 15px of page for a tenth of the meter. What is being paid for here
            -- is the landing, ten times a meter, on things that are moving.
            { text = "IT DRIVES IN DEEPER",
              apply = function(t) t.drop.damage = 6 end },
            -- The crit the pencil used to buy, and the tool the field was
            -- waiting for. A one-in-five on something you tap dozens of times a
            -- page is a *rate* -- 1.4x the damage over a page, and the arithmetic
            -- is honest because the sample is large -- where the same roll on a
            -- pin you get two of from a full meter would only ever be a story
            -- about one pin.
            --
            -- Triple on 6 is 18, which takes a skull, an eye and a blot outright
            -- and leaves the grin standing: the one enemy written to survive
            -- everything a build does to move the crowd survives this too, and
            -- the tank of the table goes on being the thing you cannot staple
            -- your way out of. Rolled and announced in Staple:bite.
            { text = "ONE IN FIVE GOES STRAIGHT THROUGH",
              apply = function(t) t.drop.crit = { chance = 0.2, mult = 3 } end },
            -- The level that gives the tool a second half. Everything above is
            -- about the staple going in; this is the only thing in the catalogue
            -- about one coming back out -- the hold runs its two seconds exactly
            -- as it always did and then the wire is torn out of the paper for
            -- another 6, a fifth of those going straight through at 18 as well
            -- (Staple:update).
            --
            -- **It is the one hit in the game that cannot miss, and the hold is
            -- what earns it.** Everything else the crowd can walk out of; what a
            -- crown caught two seconds ago is standing precisely where it was,
            -- because the crown is the thing holding it. So the honest way to
            -- read the level is not "double damage" but "the second 6 lands on
            -- exactly what the first one did not kill", which is a different
            -- promise -- a staple that killed on the way in tears out of an empty
            -- circle, and a fastener with nothing under it is worth nothing.
            --
            -- What it costs is the page. A staple used to be the one drop that
            -- stayed, and a run with this on it staples a page it does not get to
            -- keep -- the spent pile stops filling with wire (Game:updateDrops),
            -- so the record of where the trouble was is only ever pins from here
            -- on. That is the trade, and it is deliberately a real one: the tool
            -- goes from something that leaves a page behind it to something that
            -- happens twice and is gone.
            { text = "IT TEARS BACK OUT AND BITES AGAIN",
              apply = function(t) t.drop.prise = true end },
            -- The finale, and the one level in the catalogue that changes a
            -- *gesture*. Everything the tool was written against -- tapped not
            -- drawn, ten separate decisions, a held finger is none -- is sold
            -- back here, and it is the last level on purpose: the three above are
            -- what make a seam worth having, since a line of staples is a line of
            -- 6s, a fifth of them 18, and a lane you can run down.
            --
            -- 12px apart, so the circles just overlap and a full meter is ten of
            -- them: about 120px of seam, a third of the page. Each is charged the
            -- tool's own price (Game:rakeDrops), so what this buys is presses
            -- rather than page -- the meter still owns exactly how much stapling
            -- a run can do, and it always did.
            { text = "HOLD AND DRAG TO RUN A SEAM OF THEM",
              apply = function(t) t.drop.rake = { every = 12 } end },
        } }),
    -- The scissors' four, and the line is about the *line*: not a bigger number
    -- but more page in one cut, one step at a time. The unlock has to carry the
    -- whole gesture, since this is the one tool on the strip whose use is not
    -- obvious from picking it up -- every other tool does something on the first
    -- press and this one waits for the second.
    --
    -- What holds the four together is that none of them retires the one before
    -- it, which is the trap a line shaped like this walks into. Unlimited reach
    -- would be dead weight the moment the cut ran edge to edge anyway, and it
    -- isn't, because by then the two taps are placing the *deep* part of a cut
    -- that was going to cross the page regardless. And the finale needs the level
    -- before it to mean anything at all: a page only has two halves to choose
    -- between once a cut goes all the way across it.
    toolLine("scissors", "SCISSORS", "scissors", "SCISSORS",
        "SCISSORS. TAP TWICE AND THE PAGE CUTS BETWEEN", { levels = {
            -- The cap comes off rather than moving up. 128px was the price of a
            -- tool that can be placed anywhere on the page and shows you nothing
            -- between the taps, and what is left holding it once that price is
            -- paid is the pointer: a tap cannot land off the canvas, so the
            -- longest cut in the game is a screen's diagonal and the meter still
            -- charges the same for it.
            --
            -- Which is also the level that makes the travel worth something. Up
            -- to here the blades are down the line inside a sixth of a second;
            -- past it a cut can be long enough that the crowd walks while it is
            -- opening, so the far end of one is genuinely a lead rather than a
            -- place.
            { text = "THE CUT RUNS AS FAR AS THE SECOND TAP",
              apply = function(t) t.cut.reach = math.huge end },
            -- 20 rather than the obvious 24, and a band twice as wide, which is
            -- the same decision twice: what this level sells is the blades
            -- *closing* on something rather than the number going up. 12 already
            -- kills the toughest thing in the crowd outright, so a bigger number
            -- buys almost nothing against the crowd this tool was written for --
            -- where 6 against 3 is the difference between having to thread a cut
            -- down a line of blobs and being able to lay it near one.
            --
            -- It is deliberately not written as a multiplier. Doubling would keep
            -- pace with the sharpener forever and leave the aimed stretch worth
            -- twice a page-crossing cut at every level of it; an absolute number
            -- is a lead the rest of the cut closes as a run gets stronger, which
            -- is the right way round for a level bought early.
            { text = "IT BITES DEEPER AND WIDER BETWEEN YOUR TAPS",
              apply = function(t) t.cut.blades = { damage = 20, width = 6 } end },
            -- The cut stops ending where you tapped. From here the two taps are
            -- a *line* rather than a pair of ends: it runs on from both of them
            -- to the edges of the page, at the written 12 across the written 3,
            -- so the stretch you aimed is still the part that is worth something.
            --
            -- Clipped to the viewport rather than to the world, the sun's rule
            -- and the beam's: nothing is killed off the page, and a cut that
            -- reached past the edge would be one whose best use was aiming at
            -- things you cannot see.
            { text = "IT RUNS ON PAST BOTH TAPS TO THE EDGES",
              apply = function(t) t.cut.through = true end },
            -- The finale, and the one thing in the game that writes into the
            -- page layer rather than onto it: the cut goes all the way across, so
            -- the page is in two, and the half you are not standing on is lifted
            -- off it -- the paper between the rules gone grey, the ruling itself
            -- printed exactly where it was, and everything that was standing on
            -- it *gone with it*.
            --
            -- **There is no damage in this level at all**, and it is the only one
            -- in the book a run can finish without buying a single point of it.
            -- What the offcut does to the crowd is *move* it: everything standing
            -- on the half that goes is carried off with the paper and put down
            -- again in the corner of the page furthest from you, whole -- no gem,
            -- no xp, no kill, nothing split and nothing burst, because nothing
            -- died and nothing was hurt (Game:liftEnemyTo is the whole contract).
            -- It used to be a point a half-second, and the trouble with that was
            -- never the number -- it was that half a page withering slowly is the
            -- same card as a bomb with a bigger crater, and the scissors had spent
            -- three levels earning something that is not a bomb. A page you can
            -- take *away* is.
            --
            -- **And what it takes away is ground, not monsters.** The version of
            -- this that despawned the offcut priced itself in xp -- everything it
            -- emptied was a gem the run never got -- which reads well written down
            -- and played like a get out of jail free card anyway: whatever the
            -- tally said, the page was clear and the fight was over. Repositioning
            -- sells exactly what the drawing promises and nothing more. The same
            -- crowd at the same health is standing in the far corner, and the cut
            -- has bought the seconds it takes them to walk back -- while charging
            -- for it, because they arrive out of one corner together instead of
            -- from the ring they were spread round before.
            --
            -- It also runs for as long as the cut is on the page and no longer,
            -- so keeping half a page lifted is something a run does by going on
            -- cutting. The meter is what limits that, which is where a limit on
            -- how much page you can own belongs.
            { text = "THE HALF YOU ARE NOT ON GOES, AND THEY GO WITH IT",
              apply = function(t) t.cut.sever = { tick = 0.5 } end },
        } }),
    -- The compass's four, and every one of them is about the journey the leg
    -- makes rather than about the circle being bigger or the number being
    -- higher: where on the turn it bites, how many turns there are, and how many
    -- legs are making them. Nothing here shortens `turn`, which would be the
    -- obvious level and the wrong one -- the far side of a circle having most of
    -- a second to walk out is the tool, not a flaw in it.
    toolLine("compass", "COMPASS", "compass", "COMPASS",
        "A COMPASS. IT CUTS A CIRCLE ROUND THEM", { levels = {
            -- This used to be the one level in the catalogue with no trade in
            -- it: the cut was the whole filled disc, so opening out bought area
            -- on a squared law and the leg still took the same 0.8s round. Now
            -- that a compass cuts the line it draws and not the middle of it
            -- (src/compass.lua) the level is honest -- what it buys is fence,
            -- which climbs in a straight line rather than a curve, and what it
            -- costs is that a bigger circle is a circle you have to *place*.
            -- A ring at 16 is dropped on a crowd; a ring at 66 has to be drawn
            -- so the crowd is standing on it, and every extra pixel of radius is
            -- more page the crowd can be standing in the middle of. Wider is
            -- better and it is no longer free, which is the whole difference.
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
            -- being cut by. 12 is the skull's health exactly -- the longest line
            -- in the game stops being unable to touch a tank.
            --
            -- And the second lap is worth more than "the same cut twice" now
            -- that the cut is a rim. 1.6s is long enough for the crowd to have
            -- walked across a line 3 wide, so what comes round the second time
            -- is largely not what was cut the first: the lap that used to re-cut
            -- the same disc now sweeps up whoever has since wandered onto the
            -- fence. It is the level that turns the ring from a hit into a
            -- place.
            { text = "TWICE ROUND, AND IT CUTS FAR DEEPER",
              apply = function(t) t.sweep.laps, t.sweep.damage = 2, 12 end },
            -- The finale changes the shape of the attack rather than its
            -- numbers. Two legs from the same rest point, going opposite ways
            -- and meeting on the far side, so a lap closes in half the time
            -- without the arm moving any faster -- two laps of it come to the
            -- same one turn's worth of waiting a single leg used to spend on
            -- one. There is nowhere left on the rim that is a safe place to be
            -- standing, which is what the far side used to be.
            --
            -- It is the level that gained most from the cut becoming a rim, and
            -- it is worth knowing why: while the disc was the hit, halving the
            -- promise only bought tempo, because anything that stepped off the
            -- line was still standing inside the circle and was cut anyway. Now
            -- stepping off the line is the counterplay, and this is the level
            -- that takes half of it away. The thin ring's own weakness and its
            -- own answer, which is where a finale belongs.
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

    -- The first fusion.
    --
    -- MARKER and COMPASS are the pair, and they are the pair because they are
    -- the two lines that end up wanting the same thing and cannot both have it.
    -- The marker's band is the best ground in the game and the worst to place --
    -- it goes where your hand goes, which is to say where *you* are, and the
    -- crowd it is for is the crowd you are trying not to be standing in. The
    -- compass is the one tool that reaches away from you and the one that leaves
    -- nothing behind: a circle drawn round a horde you are nowhere near, that
    -- cuts once and is gone. Each is exactly what the other is missing, and a run
    -- that finished both spent eight of its levels learning that the hard way.
    -- What it gets for them is the band drawn where the circle went.
    --
    -- The catalyst is a passive on purpose, and this is where that rule is set
    -- down once for all forty-five. A fusion asking only for the two tools it
    -- eats would be a thing a run walks into by drafting greedily; asking for a
    -- third line the run cannot spend on either tool is what makes it a build
    -- rather than a coincidence. It is never consumed: whatever the third line
    -- was doing for the run goes on doing it afterwards, because the run earned
    -- it and the fusion did not eat it.
    --
    -- **FIXATIVE is the line, and what picks it is that this row's worth is a
    -- clock.** What the arm leaves behind is a band of fire that ticks for 3.6
    -- seconds (`life`), and `scalePersistence` reaches that number -- so a
    -- finished fixative is the difference between a ring you drew round a horde
    -- and a ring the horde is still standing in. A choice and not a tax: the band
    -- ticks its 5 either way, and 3.6 seconds is already a real ring. The fire
    -- itself does not move -- `ignite` is neither `life` nor `freeze`, so nothing
    -- here stretches the 2 seconds of burn, only the paper it is burning on.
    --
    -- What the tool is is entirely in src/tools.lua, and what it costs the strip
    -- is entirely in `fuses`: the marker and the compass come off, the halo goes
    -- on, and one of the four places is free again.
    fusionLine("halo", "HALO", "halo", "HALO", {
        needs = { "highlighter", "compass", "fixative" },
        fuses = { "highlighter", "compass" },
        unlock = "THE MARKER GOES IN THE COMPASS: A RING THAT BURNS",
        -- The marker's fire, rebuilt on the run's copy every rebuild rather than
        -- written on the row -- see `fusionLine` above and the HALO row itself.
        apply = function(t) t.ignite = { time = 2, tick = 0.4, damage = 2 } end,
        -- Nothing after the unlock yet. A fusion may have its own levels like any
        -- other line -- the shape is there -- but this one arrives with eight
        -- already in it, and a card that sold a ninth would be selling the run
        -- something it has no way left to choose against.
    }),

    -- The second fusion, and it is the first one's argument told from the other
    -- side of the compass.
    --
    -- PENCIL and COMPASS are the pair, and what makes them a pair is a hole in
    -- the compass that the pencil is the only line in the game shaped to fill.
    -- A compass cuts the circle it draws and never the middle of it -- the inside
    -- of one is the safest place on the page, and that is the tool rather than a
    -- flaw in it. The pencil's own finale is the same idea drawn by hand and from
    -- the other end: close a line on itself and everything the ring holds is cut.
    -- It is cheap because the ring is yours to draw, badly, around a crowd that is
    -- walking away from you. Fuse them and the ring is drawn *for* you -- perfect,
    -- at whatever width you dragged, around a crowd you are nowhere near -- and
    -- the safest place on the page stops being anywhere.
    --
    -- So the two fusions off the compass are two answers to the same question and
    -- a run may only ever have one of them: the halo makes the *rim* worth
    -- standing on, and this makes the middle worth surrounding. The pencil is the
    -- more painful half to hand over of the two -- it is the tool every run opens
    -- holding, so this is the one card in the draft that can leave you without
    -- one -- and that is the price of the only tool that claims an area at reach.
    --
    -- SELLOTAPE is the catalyst, and it is the first of the ten rows that ask
    -- for it. What the tape pays a run for is *time*, the currency a run that
    -- committed ten levels to two tools has already been spending -- and it says
    -- nothing at all about a line, which is exactly the qualification here.
    -- Every economy line the strip sells would be a lie or a tax on this row:
    -- the price is flat (0.45 a press), so the blotter cannot reach it; the ring
    -- is drawn for you in one gesture, so there is no chain to fit inside a well
    -- and no next one to get to sooner; and the ring closes and is gone, so there
    -- is no clock to stretch.
    --
    -- **That is the tape's job in this catalogue.** It is the catalyst for the
    -- rows no economy line can speak to without becoming the row's own
    -- prerequisite, and there are ten of them. It was once the third line of all
    -- twenty-four fusions off the compass, the pushpin and the ruler, which made
    -- it a toll rather than a sentence -- a run that finished it opened half the
    -- book at once. Ten is what is left when every row that had a better ask got
    -- one.
    fusionLine("lasso", "LASSO", "lasso", "LASSO", {
        needs = { "pencil", "compass", "tape" },
        fuses = { "pencil", "compass" },
        unlock = "THE PENCIL GOES IN THE COMPASS: A RING THAT CLOSES",
        -- The pencil's lasso, rebuilt on the run's copy every rebuild rather than
        -- written on the row -- `scaleDamage` reaches `loop`, see `fusionLine`
        -- above and the LASSO row in src/tools.lua. 4 is the pencil's own number
        -- and it is not nudged for being reached by an arm now: what the fusion
        -- buys is a ring nobody has to draw, closing twice a swing (`laps`) around
        -- ground the compass could never touch, and the day the pencil's fourth
        -- level changes this changes with it.
        apply = function(t) t.loop = { damage = 4 } end,
        -- Nothing after the unlock, for the halo's reason: eight levels are
        -- already in it.
    }),

    -- The third fusion, and the one that says what the pattern is.
    --
    -- GLUESTICK and COMPASS are a pair for the plainest reason of the three. The
    -- smear is the strongest thing a run can put on the page and the hardest to
    -- put anywhere useful: what it does is stop everything standing on it, so
    -- where it wants to be is under the crowd -- and getting it there means
    -- dragging your own hand through the crowd, which is the one place a run
    -- spends its whole time trying not to be. Every level of the line makes that
    -- worse rather than better: a wider head, deeper cuts on what it holds, a
    -- tear on the way loose and a field that pulls the crowd in are all reasons
    -- to want the paste further from you than your arm reaches. The compass is
    -- the only tool in the game that reaches away from you at all.
    --
    -- So this is the fusion with the least invention in it and the most
    -- consequence: nothing about the glue changes, and it is simply laid where it
    -- was always meant to go. See the MOAT row in src/tools.lua for the one
    -- decision that falls out of copied numbers -- a head 20 wide against a
    -- smallest circle of 16, so the drag now chooses between a plug of paste and
    -- a wall of it.
    --
    -- SELLOTAPE a second time, and here it is the *tax rule* doing the choosing
    -- rather than an absence. This row's whole worth is per second it is on the
    -- page -- six seconds of paste that softens, tears and pulls -- so the
    -- FIXATIVE is the line it wants most of anything on the strip, and that is
    -- precisely why it may not be the ask. A catalyst that is the line a row
    -- cannot play without is a tax and not a choice (the CLINCH's rule, argued at
    -- the foot of this file). The tape is what is left when the one line with
    -- something to say about the row would also be the row's prerequisite.
    fusionLine("moat", "MOAT", "moat", "MOAT", {
        needs = { "gluestick", "compass", "tape" },
        fuses = { "gluestick", "compass" },
        unlock = "THE GLUESTICK GOES IN THE COMPASS: A RING THAT HOLDS",
        -- No `apply` in the spec, and it is the first fusion not to want one --
        -- so the unlock keeps the empty one `toolLine` gives every tool's first
        -- level, exactly like an ordinary tool line's. The halo has to build
        -- `ignite` and the lasso `loop` because `scaleDamage` writes into both
        -- and `Tools.copy` is one level deep; everything the glue does is
        -- either a bare number the sharpener multiplies on the run's own copy
        -- (`tear`) or a table nothing ever writes into (`pull`), so the row says
        -- all of it and this level has nothing left to do.
        --
        -- Nothing after the unlock either, for the halo's reason: eight levels
        -- across two lines are already in it.
    }),

    -- The fourth fusion, and the only one that does no damage of any kind.
    --
    -- SCISSORS and COMPASS are the pair, and the argument is a shape rather than
    -- a number. The scissors reach anywhere and their last level writes into the
    -- page itself -- the half you are not standing on lifts off it, and every
    -- body standing on it lifts off with it -- and what they cannot do is choose
    -- which half. A cut is a straight line, so the only region a pair of scissors
    -- can take is half a page, which is an enormous amount of page to be deciding
    -- about with two taps, and the choice is really between two bad ones. The
    -- compass is the only tool that draws a *closed* line. Fuse them and the
    -- offcut is a disc you sized with the drag: the same finale, aimed.
    --
    -- **What the ring does is clear its own middle, and clear is the exact word --
    -- it does not empty it.** Everything inside is taken off the page and put down
    -- again in the corner of it furthest from you, not killed: no gem, no xp, no
    -- kill on the tally, nothing split and nothing burst, because nothing was
    -- hurt. See Game:liftEnemyTo for the contract and Compass:lift for the sweep.
    --
    -- It is the one tool in the game that buys nothing but room, and that is what
    -- separates it from the lasso rather than a number. Both are a ring that does
    -- something to the middle of itself, which is the one thing a compass has
    -- never done -- but the lasso's middle is a *hit*, 4 damage the instant the
    -- line closes, and this one's is a *place the horde is not*. Two cards
    -- arguing about how hard would have been the same card twice; two cards
    -- arguing about the verb are two builds. For a long while this one was a
    -- point every half second on ground that was visibly gone, and the honest
    -- reading of that is that it was a slow, worse lasso wearing the scissors'
    -- clothes.
    --
    -- And what it costs is the shape of the arrival rather than the run's xp. The
    -- disc does not spend the crowd it holds -- it stacks it in one corner, at the
    -- health it had, walking back -- so a punch is a fight postponed and gathered
    -- rather than a fight cancelled, which is the only way a card that clears a
    -- 66-pixel disc with one press can be allowed to exist.
    --
    -- **The price is the xp, and the price is why it can be absolute.** A disc
    -- opened on a crowd is every gem in that crowd not dropping, so the tool
    -- takes the run's own levelling to pay for the room -- and a build that
    -- reaches for it whenever the meter fills gets to the boss a level or two
    -- behind a build that fought for the same ground. Nothing has to be tuned to
    -- make that true; it falls out of not crediting the kill, which is the whole
    -- of the mechanism. It is also the reason this is a *panic* button rather
    -- than a rotation: the correct time to spend a level of your own is when the
    -- alternative is spending the run.
    --
    -- And the disc stays open, so the hole goes on being a hole for whatever
    -- walks into it while the rim is on the paper. That is the compass's own
    -- third-level distinction -- a hit against a place -- landing on the one
    -- fusion that took it literally.
    --
    -- One thing falls out of the split that nobody designed and that is worth
    -- keeping: **the rim still pays and the middle never does.** The ring cuts 12
    -- to whatever is standing on the line it draws, gems and all, and clears
    -- everything inside it for nothing -- so the same gesture is a kill at its edge
    -- and a shove to the far corner at its centre, and how wide you open it is a
    -- question about which of the two you came for. A small circle on a tight knot
    -- is a weapon; a wide one round a room is a broom, and a broom sweeps rather
    -- than burns. See the PUNCH row in src/tools.lua.
    -- TOP MARKS is the catalyst, and it is the first of three rows to ask for
    -- it. The paragraph above is the argument already: what a severed region
    -- holds is carried off and set down, not hurt, and `Game:liftEnemyTo` credits
    -- no gem, no xp and no kill on the tally -- so the middle of this ring is the
    -- run's own levelling, spent to buy room. A catalyst that says *you may have
    -- the tool that stops earning once you have fixed earning* is the one sentence
    -- this row was always making and nobody was charging for. Not a tax: the rim
    -- still cuts 12 to whatever is standing on the line it draws, gems and all.
    fusionLine("punch", "PUNCH", "punch", "PUNCH", {
        needs = { "scissors", "compass", "topmarks" },
        fuses = { "scissors", "compass" },
        unlock = "THE SCISSORS GO IN THE COMPASS: A RING THAT LIFTS OUT",
        -- No `apply`, and it is the moat's and the spindle's reason arrived at
        -- from a different direction: `sever` used to carry a damage number, and
        -- a table `scaleDamage` writes into has to be built fresh on the run's
        -- copy every rebuild. It carries a clock and nothing else now, so the
        -- sharpener has no reason to reach it, the row says all of it, and this
        -- level has nothing left to do.
        --
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The fifth fusion, and the one that finally gives the compass something to
    -- carry rather than something to draw with.
    --
    -- PUSHPIN and COMPASS are the two tools that reach, and they are the only two.
    -- Everything else on the strip happens where your hand is; a pin is tapped
    -- onto any spot on the page and a circle is stood anywhere you press. What
    -- makes them a pair rather than two ways of doing the same thing is that they
    -- disagree about *when*. A pin is one instant -- a quarter-second fall you can
    -- see coming, a crater, and the one thing that lived through it stuck to the
    -- paper -- and all three of those happen at once, so the tool reads as a
    -- single event. A compass is the opposite: the slowest thing in the game to
    -- bring to bear and the only one whose hit you can watch travel, most of a
    -- second of promise.
    --
    -- Fuse them and the pushpin's two halves come apart in time. The crater is
    -- dragged round the rim, punching the chaff out the whole way; the survivor is
    -- picked up on the point and carried, in front of you, for a whole turn; and
    -- the pin goes through it into the page wherever the arm happens to stop. It
    -- is the pushpin's own design with the compass's clock inside it, and it needed
    -- both parents finished to be worth writing: a crater that killed everything
    -- would have nothing to carry, and an arm that arrived instantly would have
    -- nowhere to carry it.
    --
    -- The one thing this fusion invents is the *carrying*, and it is deliberately
    -- the least it could be: one body per leg (so two, on a finished compass),
    -- frozen while it rides, dropped if it leaves the horde some other way. See
    -- Compass:haul and Compass:nail in src/compass.lua, and the SPINDLE row in
    -- src/tools.lua for why every number in it is a parent's -- including the one
    -- place the two parents disagree, where the fused row takes the *weaker*
    -- number because the stronger one would delete the finale.
    -- FIXATIVE, and of the eight rows that ask for it this is the one where the
    -- number is plainest: what the leg drives into the page is a pin carrying
    -- `freeze` 4 and `life` 4 inside its `drop`, and `scalePersistence` walks
    -- both. The carrying is a clock too -- one body per leg, frozen while it
    -- rides -- so a finished fixative lengthens the ride and the pinning at the
    -- end of it in the same breath. Not a tax: the pin's 10 lands on the nail.
    fusionLine("spindle", "SPINDLE", "spindle", "SPINDLE", {
        needs = { "pushpin", "compass", "fixative" },
        fuses = { "pushpin", "compass" },
        unlock = "THE PUSHPIN GOES IN THE COMPASS: IT DRAGS AND PINS",
        -- No `apply`, and for the moat's reason rather than by luck: everything
        -- the pin brings is either a bare number the sharpener multiplies on the
        -- run's own copy or a field inside a block, and `Tools.copy` makes both
        -- blocks fresh every rebuild. `drop` being a real block instead of three
        -- loose fields is what buys that -- see the SPINDLE row.
        --
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The sixth fusion, and the one that took the longest to be possible: the pen
    -- had no upgrade line at all until now, and a fusion may only ever be made of
    -- lines a run can *finish*.
    --
    -- PEN and COMPASS are the pair, and they are a pair because the pen has two
    -- limits and the compass is the answer to both of them at once. The first is
    -- the one every tool but the compass has -- a fence is drawn by dragging your
    -- own hand down the line you want it on, which means walking the length of the
    -- wall you wanted through the crowd you wanted it against. The second is the
    -- pen's alone and is much worse: **its line has ends.** Enemies round the ends
    -- of a wall deliberately (Enemy:avoidWalls), so a hand-drawn fence is a thing
    -- the crowd flows past rather than a thing it is stopped by, and the pen has
    -- never once been able to enclose anything. The compass is the only tool that
    -- reaches away from you and the only one that draws a *closed* line. Put the
    -- pen in the leg and both limits go in the same gesture: the wall is laid where
    -- you are not, and it has no ends at all.
    --
    -- So this is the fusion that changes the shape of the fight rather than the
    -- numbers in it, and it is the only one of the six that does. The other five
    -- are things that happen to the crowd -- a ring that burns, closes, holds,
    -- lifts out, drags and pins -- and every one of them is over in a second or
    -- two. This one leaves a place. A closed pen ring is somewhere the crowd is,
    -- inside or outside, and with the pen's finale on it the ring has no clock: it
    -- stays until you swing the next one. What it costs is what the pen always
    -- charged for a wall -- the crowd is *held* rather than hurt, 2 a second to
    -- whatever leans on the ink and nothing at all to whatever does not, so a run
    -- that fenced the horde off has bought itself time and not a single kill.
    --
    -- It is also the one card in the draft that can leave a run boxed in on
    -- purpose, and that is worth saying out loud rather than patching: the player
    -- crosses their own ink freely, so a ring drawn round yourself is a fortress
    -- for as long as you stand still in it -- and standing still is the one thing
    -- a run cannot afford, because the gems are on the floor outside it, the eyes
    -- shoot over ink (Game:updateBullets) and the boss has to be killed rather
    -- than waited out. The pen's own last level was written with that same
    -- sentence in it. This makes it cheap enough to reach for, which makes it a
    -- decision instead of a theory.
    --
    -- SELLOTAPE a third time, and the MOAT's reason word for word: `keep` and a
    -- nine-second wall make the fixative this row's prerequisite rather than its
    -- choice, and a flat 0.55 press puts it out of the blotter's reach.
    fusionLine("corral", "CORRAL", "corral", "CORRAL", {
        needs = { "pen", "compass", "tape" },
        fuses = { "pen", "compass" },
        unlock = "THE PEN GOES IN THE COMPASS: A RING THEY CANNOT CROSS",
        -- The pen's third level, rebuilt on the run's copy every rebuild rather
        -- than written on the row: `scaleDamage` writes `pop.damage` and
        -- Tools.copy is one level deep, which is the halo's `ignite`, the lasso's
        -- `loop` and the punch's `sever` for the fourth time. The numbers are the
        -- pen's to the digit -- 4 is a blob exactly, along the whole ring at once,
        -- the moment the ink goes -- and on a held ring that moment is nine
        -- seconds after you replaced it, which makes swinging the next circle a
        -- thing you can aim the last one's ending with.
        apply = function(t) t.pop = { damage = 4, reach = 6 } end,
        -- Nothing after the unlock, for the halo's reason: eight levels across two
        -- lines are already in it.
    }),

    -- The seventh fusion, and the corral's argument told in wire.
    --
    -- STAPLER and COMPASS are the pair, and what makes them one is that the
    -- stapler is the most *repetitive* tool on the strip and the compass is the
    -- only one that does anything at reach. Ten staples a meter, one press each,
    -- every one of them a 15px circle you have to land on something that is
    -- walking -- and all four of its levels are about making that press worth
    -- more (deeper, one in five straight through, torn back out two seconds later
    -- for a second bite) until the last one, which sells the ten presses back as a
    -- single drag. That drag is still yours to walk, though, in a straightish line,
    -- through the crowd you wanted the seam in front of. Give the stapler to the
    -- arm and the seam is raked round a circle you are nowhere near, evenly, and
    -- it closes -- a seam that meets itself is a hem.
    --
    -- **The one thing it invents is a price that the drag decides**, and it is the
    -- first in the game. Every other sweep costs one number at the needle and
    -- opens as wide as you like for nothing; a wider hem is more staples, and the
    -- stapler's whole line is written on the price of a staple never changing (see
    -- its finale: the level buys presses, not page). So the row carries a second
    -- price per staple and the drag is capped by the meter -- open it until the leg
    -- stops opening, which is the tool telling you how much wire is left in it. It
    -- is the one place in the game where a tool's reach is a thing you can run out
    -- of mid-gesture, and it reads as exactly what it is.
    --
    -- What it does *not* invent is anything a staple does. Landing, biting,
    -- critting, holding for two seconds, and either staying in the paper for the
    -- rest of the run or tearing back out of it are all Staple's, unchanged and
    -- not one of them told a compass was involved -- and the last of those is the
    -- best thing here, because nobody designed it: thirty-four staples went into a
    -- ring on the same frame, so thirty-four come out on the same frame too. The
    -- hem closes on a crowd, holds all of it for two seconds, and then unfastens
    -- the whole rim at once.
    --
    -- FIXATIVE, and it is the HALO's argument told in wire. What the arm leaves
    -- on the page is a ring of staples, and a staple is two numbers a clock owns
    -- -- `life` 2 and `freeze` 2, both inside the `drop` that `scalePersistence`
    -- walks -- so a finished fixative is a ring still holding when the next rank
    -- reaches it. Not a tax: the staple's 6 and its crit are paid on the press.
    fusionLine("hem", "HEM", "hem", "HEM", {
        needs = { "stapler", "compass", "fixative" },
        fuses = { "stapler", "compass" },
        unlock = "THE STAPLER GOES IN THE COMPASS: A RING OF STAPLES",
        -- No `apply`, and for the moat's and the spindle's reason: everything the
        -- stapler brings lives inside its `drop` block, `Tools.copy` makes that
        -- block fresh on the run's copy every rebuild, and the two tables in it
        -- are ones nothing writes into -- `crit.mult` is a multiplier on damage
        -- the sharpener has already scaled (`scaleDamage` says so where it skips
        -- it) and `prise` is a flag nothing anywhere writes to.
        --
        -- Nothing after the unlock, for the halo's reason: eight levels across two
        -- lines are already in it.
    }),

    -- The eighth fusion, and the only one aimed at where you are standing.
    --
    -- RUBBER and COMPASS are the pair, and the argument is the plainest in the
    -- book: the rubber is the tool that moves the crowd and it can only move the
    -- crowd that is already on top of you. What a rub does is shove -- 240 is a
    -- 27px throw, and the finale makes whatever it throws a weapon until it slows
    -- -- and every pixel of that has to be delivered by dragging your own hand
    -- through the thing you are trying to get away from. The compass is the only
    -- tool that reaches away from you. But this is the one fusion that does not
    -- want the reach: it wants the compass's *shape*, and the shape is a closed
    -- ring you can stand in the middle of.
    --
    -- So the leg sweeps the disc and everything inside goes straight out of it.
    -- Plant it on your own feet and the rank that had reached you leaves; plant it
    -- round a crowd and the crowd is scattered outwards instead of stirred round
    -- the rim, which is what the compass's own knock has always done. The middle
    -- of a compass was the safest place on the page -- three of its four levels are
    -- written on that -- and this is the one card that makes the middle the *only*
    -- thing it touches.
    --
    -- **Nothing dies**, and that is what pays for touching everything at once. 2 a
    -- body, 4 where the leg bites, which is what a rubber has always dealt and the
    -- one number its own line never moved. What the tool buys is a second and a
    -- half of empty page around you, and the only thing on it that can actually
    -- kill is the crowd hitting the crowd (`ram`, the rubber's finale, at 5 a
    -- collision).
    --
    -- **And it leaves nothing at all.** Every other fusion puts something on the
    -- paper -- a band, a graphite ring, a smear, a hole, a pin, a fence, a row of
    -- staples -- and a rubber's mark is over the moment you let go (`life = 0`,
    -- copied straight across). So the circle is drawn in graphite as the arm
    -- follows it and gone with the arm, which makes this the cleanest thing in the
    -- game to look at afterwards and the only sweep that leaves the page exactly as
    -- it found it.
    --
    -- Two of the rubber's four levels have nothing to land in, which is more than
    -- any other fusion drops and worth being straight about: `lean` is a tip that
    -- keeps hitting while it rests and an arm never rests, `scrub` is half price
    -- over ground already covered and there is no per-pixel price here at all. Both
    -- are about the wrist and the meter, and a sweep has neither. See the CLEARING
    -- row in src/tools.lua.
    --
    -- MAGNET, and it is the first of three rows to ask for it. The only damage
    -- this tool does that can kill anything is dealt by the crowd to itself, out
    -- past where you were standing when you opened the disc (`ram`, and the
    -- CLEARING row in src/tools.lua) -- so every gem this row earns drops at the
    -- far edge of a circle you are in the middle of, and the pickup radius is the
    -- one number that decides whether the run is paid for the rub at all. A
    -- condition and not a tax: the shove is the tool, and it lands whether or not
    -- you ever reach what it killed.
    fusionLine("clearing", "CLEARING", "clearing", "CLEARING", {
        needs = { "rubber", "compass", "magnet" },
        fuses = { "rubber", "compass" },
        unlock = "THE RUBBER GOES IN THE COMPASS: IT SWEEPS IT CLEAR",
        -- The rubber's finale, rebuilt on the run's copy every rebuild rather than
        -- written on the row -- `scaleDamage` reaches `ram` by name and Tools.copy
        -- is one level deep, which is the halo's `ignite`, the lasso's `loop`, the
        -- punch's `sever` and the corral's `pop` for the fifth time. 5 is the
        -- rubber's own number and it is not nudged for being thrown by an arm: a
        -- blob is dead on arrival, and what gets hit never becomes a projectile
        -- itself, so a disc emptied outwards is one volley and not a chain.
        apply = function(t) t.ram = { damage = 5 } end,
        -- Nothing after the unlock, for the halo's reason: eight levels across two
        -- lines are already in it.
    }),

    -- The ninth fusion, and the only one that puts nothing in the leg.
    --
    -- RULER and COMPASS are the pair, and they are the pair for a reason none of
    -- the other eight could use: they are the two instruments in a geometry set,
    -- and there is a thing you do with the two of them together that everybody who
    -- has ever held them already knows. Two arcs from two centres cross at two
    -- points; lay the straight edge through those two points. It is the first
    -- construction anybody is taught, and it is the only fusion in the game whose
    -- two halves were designed to be used together by somebody other than us.
    --
    -- What each half brings is the other's missing piece, and it is not reach --
    -- both of these already reach. **A ruler's line goes through you.** That is its
    -- one real limitation and no level of it moves: it is 200px long and it can be
    -- 400, and every pixel of that is on a line through your own feet, so what you
    -- get to choose is which way the page is swept and never *where*. The compass
    -- is the only tool that goes somewhere you are not -- but it can only ever draw
    -- a closed ring. Put the two together and the ruler's line is a **chord**: it
    -- sits square to the line joining the two needles, half way along, as long as
    -- the overlap is deep, and nowhere near you. Both ends were placed by placing
    -- two needles, which makes this the one thing on the strip you aim by drawing
    -- something else twice.
    --
    -- **It is the first tool whose second half is a relationship between two
    -- marks**, and that is the interesting half of the card. Everything else on the
    -- strip is a gesture landing. This one needs two swings, close enough together
    -- that the first ring has not faded (2.2s past the arm stopping), and neither
    -- swing is worth anything alone -- one circle rules nothing at all. So the
    -- price is paid in *gestures*: 0.4 twice, most of a full meter, before a single
    -- line comes down. Nothing else here charges like that, and nothing else here
    -- has a window you read off the paper rather than off a number -- the fading
    -- ring is the timer.
    --
    -- One parent level has nothing to land in, and it is the ruler's finale. How
    -- far this ruler reaches is not the tool's to decide any more -- the two
    -- circles are 66 at the widest, so the chord can never pass 132 against the
    -- 400 the last level buys. The reach is what was sold and the position is what
    -- was bought, which is the trade written out. See the FOLD row in
    -- src/tools.lua.
    --
    -- CARTRIDGE, and it is the price that picks it. A fold is *two* presses --
    -- two arcs from two centres, and the ruler falls where they cross -- so 0.4 a
    -- press is 0.8 a fold and a base meter holds exactly one. Nothing about this
    -- row is short of room; what it is short of is the next fold, and the
    -- cartridge is the only line on the strip that sells one.
    fusionLine("fold", "FOLD", "fold", "FOLD", {
        needs = { "ruler", "compass", "cartridge" },
        fuses = { "ruler", "compass" },
        unlock = "TWO CIRCLES CROSSING: A RULER FALLS BETWEEN",
        -- No `apply`, and for the moat's, the spindle's and the hem's reason:
        -- everything either parent brings is a number inside a block, `snap` and
        -- `sweep` are both in `Tools.BLOCKS`, and `Tools.copy` makes both fresh on
        -- the run's copy every rebuild -- so the sharpener finds the ruler's 12 and
        -- the lead's 12 where it already looks and nothing shared is ever scaled
        -- twice.
        --
        -- Nothing after the unlock, for the halo's reason: eight levels across two
        -- lines are already in it.
    }),

    -- The tenth fusion, and the first one that is not the compass.
    --
    -- Nine of them are one instrument wearing another, and the reason given every
    -- time was that the compass is the only tool that reaches away from you. That
    -- was half of the truth. **A pushpin also lands wherever you tapped and never
    -- where your hand is** -- what a pin has never had is a *line*. It is a point,
    -- and a point cannot be a shape, a fence or a band however far off you put it.
    --
    -- PENCIL and PUSHPIN are the pair, then, and they are a pair for the LASSO's
    -- reason read from the other end. The pencil's finale is the only level in the
    -- game that claims an *area*, and it claims it by asking you to draw the border
    -- yourself -- badly, one-handed, around a crowd that is walking away from you
    -- while you draw it. The LASSO answers that by having the border drawn for you,
    -- perfectly, at whatever width you dragged. This answers it by letting you
    -- **build** the border: drop pins and the pencil joins up the ones that are
    -- close, and a circuit of them cuts everything it holds. The corners are
    -- exactly where you tapped, and every corner punched a 51px crater and pinned
    -- whatever survived it on the way in.
    --
    -- So the two halves genuinely need each other, which is the test a fusion has
    -- to pass. The pin gets the thing it never had -- a line, and therefore a shape
    -- -- and the pencil gets the thing it never had, which is a border it does not
    -- have to be standing next to. And a run may only hold one of the pencil's two
    -- answers, since both lines eat it (`fuses`): the LASSO is a ring the tool
    -- draws and you place, this is a ring you place a corner at a time.
    --
    -- It is the dearest way to close a ring in the game and the slowest: three taps
    -- and a meter and a half against the LASSO's one press. What it buys for that
    -- is a shape of any number of sides, in any shape at all, made out of three
    -- hits that were worth taking on their own.
    --
    -- CARTRIDGE, and this is where the threading family's ask is argued for all
    -- five of them.
    --
    -- Half a meter is two taps and therefore exactly one thread (see the row in
    -- src/tools.lua), so the obvious read is that the INKWELL is the line -- and
    -- the numbers say otherwise. A 0.5 press comes back in 0.5 / `Tools.REGEN`
    -- plus `Tools.DELAY`, which is about 1.9 seconds, and a pin stands in the
    -- paper for 4 (`PIN.life`). The third post arrives with the first two still
    -- there: **the chain already crosses wells at base**, so what gates the shape
    -- is the trickle and not the room.
    --
    -- Which is the SNAG's own test run the other way round. That row asks for the
    -- well because its hold is two seconds and the meter does not come back
    -- inside two; these five ask for the trickle because their window is twice
    -- their refill. One rule, two answers, and the number that separates them is
    -- written down in both places.
    fusionLine("dots", "DOT TO DOT", "dots", "DOT TO DOT", {
        needs = { "pencil", "pushpin", "cartridge" },
        fuses = { "pencil", "pushpin" },
        unlock = "THE PENCIL JOINS THE PINS: A SHAPE THAT CUTS",
        -- The pencil's lasso, rebuilt on the run's copy every rebuild rather than
        -- written on the row -- `scaleDamage` reaches `loop`, see `fusionLine`
        -- above and the DOT TO DOT row in src/tools.lua. 4 is the pencil's own
        -- number and it is not nudged for being reached by a ring of pins now:
        -- what the fusion buys is a border you built rather than drew, and the day
        -- the pencil's fourth level changes this changes with it.
        apply = function(t) t.loop = { damage = 4 } end,
        -- Nothing after the unlock, for the halo's reason: eight levels are already
        -- in it.
    }),

    -- The eleventh, and the second answer the pen has been given to the same
    -- question.
    --
    -- PEN and PUSHPIN, and what makes them a pair is the CORRAL's argument with a
    -- different answer at the end of it. A pen is terrain, terrain is only worth
    -- anything where the fight is, and drawing a fence means walking the length of
    -- the wall you wanted through the crowd you wanted it against. Worse, the line
    -- is *open*, and a fence with two ends is a fence the crowd walks round.
    --
    -- The CORRAL fixes both by putting the nib on an arm that draws a closed circle
    -- at reach. This fixes both by driving posts: tap and a pin lands where you
    -- tapped, tap again nearby and a rail is strung between the two, and what you
    -- get is a fence in whatever shape you tapped it -- a line across a corridor, a
    -- spur off the one you laid ten seconds ago, a triangle round a spawn. Closed
    -- if you close it, and closed is your decision rather than the tool's.
    --
    -- **And every post is worth driving on its own**, which is the half the corral
    -- cannot match. A compass leg laying a fence is a compass leg laying a fence;
    -- each pin here is the biggest single hit in the game -- a 51px crater and a
    -- pinned tank -- and the wall is what you get for having placed two of them
    -- near each other. A tool whose entire cost was going to where the wall had to
    -- be now pays you for standing each end of it up.
    --
    -- One parent level has nothing to land in, and it is the pen's finale. "THE
    -- LAST LINE STAYS UNTIL YOU DRAW ANOTHER" is a rule about one gesture's worth
    -- of wall, and a fence built pin by pin is not one gesture -- it would let go
    -- of every rail but the newest as you built the thing. What it bought is bought
    -- instead by the posts: a thread is on the page for as long as both its pins
    -- are, on all three of these rows, whether the parent paid for it or not. Which
    -- is bounded better than `keep` was, and by something you can see rather than by
    -- a rule -- a pin holds for four seconds, so a player who keeps tapping still
    -- cannot lattice the page shut. See the STOCKADE row in src/tools.lua.
    --
    -- CARTRIDGE, the threading family's line -- the DOT TO DOT has the argument
    -- and the numbers. And a run may only hold one of the pen's two answers,
    -- since both lines eat it.
    fusionLine("stockade", "STOCKADE", "stockade", "STOCKADE", {
        needs = { "pen", "pushpin", "cartridge" },
        fuses = { "pen", "pushpin" },
        unlock = "THE PEN JOINS THE PINS: A FENCE WITH POSTS",
        -- The pen's third level, rebuilt on the run's copy every rebuild rather
        -- than written on the row, exactly as the CORRAL rebuilds it and for the
        -- same reason: `scaleDamage` writes `pop.damage` and Tools.copy is one
        -- level deep. A rail that has finally come off the page takes the rank
        -- leaning on it with it, and here what starts that clock is a post coming
        -- out rather than a hand drawing the next line.
        apply = function(t) t.pop = { damage = 4, reach = 6 } end,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The twelfth, and the marker's second answer.
    --
    -- MARKER and PUSHPIN, and the opening argument is the HALO's word for word: the
    -- marker's band is the best ground in the game and the worst to place. It goes
    -- where your hand goes, which is where *you* are, and the crowd it is for is
    -- the crowd you are trying not to be standing in. Both fusions off the marker
    -- answer that with reach; what they differ in is the shape the reach arrives
    -- in, and a run may only have one of them.
    --
    -- A halo is a ring: you open it out to the width you want and swing it once,
    -- and the tool decides everything about the shape but its size. A cordon is a
    -- strip between two points you chose -- across a doorway, or a Y, or a triangle
    -- with a burning edge -- and a crater at every corner of it, because every
    -- corner was a pin. Which is the trade the whole pushpin family makes: the
    -- compass hands you a perfect shape you cannot choose, and pins hand you any
    -- shape at all, one expensive tap at a time.
    --
    -- The name is what the tool is. A cordon is tape strung between two posts to
    -- say a stretch of ground is not to be crossed, and this one does not stop
    -- anybody at all: it is fifteen pixels of sky that burns whatever stands on it
    -- and sets alight anything that so much as crosses. The crowd may walk through
    -- it. It is what walking through costs.
    --
    -- CARTRIDGE, the threading family's line (see the DOT TO DOT), untouched as
    -- every catalyst is. The FIXATIVE would have been the marker's own ask --
    -- this row leaves a burning band exactly like the HALO's -- but the band is
    -- the cheaper half of a row whose name is the *rail*, and a rail is a chain.
    fusionLine("cordon", "CORDON", "cordon", "CORDON", {
        needs = { "highlighter", "pushpin", "cartridge" },
        fuses = { "highlighter", "pushpin" },
        unlock = "THE MARKER JOINS THE PINS: A BAND THAT BURNS",
        -- The marker's fire, rebuilt on the run's copy every rebuild rather than
        -- written on the row -- the HALO's rule, and the same three numbers it
        -- assigns. Touching a thread at all is enough, which is what makes a
        -- cordon worth stringing across a lane the crowd is running down: the band
        -- itself only ticks every 0.35s and a bat crosses it in less than that.
        apply = function(t) t.ignite = { time = 2, tick = 0.4, damage = 2 } end,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The thirteenth, and the first pushpin fusion whose thread is not a mark.
    --
    -- RULER and PUSHPIN, and the pair is the FOLD's argument reaching the opposite
    -- conclusion. **A ruler's line goes through you.** That is the tool's one real
    -- limitation and no level of it moves: 200px becomes 400 and every pixel of
    -- that still lies on a line through your own feet, so what a ruler lets you
    -- choose is which way the page gets swept and never where. The FOLD answers
    -- that by selling the reach to buy the position -- two circles crossing rule a
    -- chord that can never pass 132, nowhere near you. This answers it by keeping
    -- the reach and selling *precision* instead: two pins a hundred and twenty
    -- pixels apart are a
    -- pair of sights, and the finished ruler comes down on the line through them,
    -- corner to corner of the page.
    --
    -- Which is the better half of the two trades to have to make, because it is a
    -- skill rather than a number. Put the second pin one pixel off and the far end
    -- of the line moves eight. Nothing about that is hidden -- both craters are
    -- lying on the page and the line is the line through them -- and nothing about
    -- it is forgiving, which is exactly what stops a page-crossing hit you can
    -- place anywhere from being a page-crossing hit you can place anywhere.
    --
    -- And a run may hold only one of the ruler's two answers, since both lines eat
    -- it. The FOLD is a chord you aim by drawing two circles; this is a diameter
    -- you aim by driving two nails.
    --
    -- CARTRIDGE, the threading family's line (see the DOT TO DOT), untouched.
    fusionLine("snapline", "SNAP LINE", "snapline", "SNAP LINE", {
        needs = { "ruler", "pushpin", "cartridge" },
        fuses = { "ruler", "pushpin" },
        unlock = "THE PINS AIM A RULER FROM EDGE TO EDGE",
        -- The ruler's own finale, rebuilt on the run's copy every rebuild rather
        -- than written on the row -- and it is the *only* thing in the game
        -- measured off the screen rather than written down, so it is the one
        -- unlock `apply` here that has to be handed the window at all. Half a
        -- diagonal reaches the corner of whatever shape of canvas the run ended up
        -- on, and the loadout recomputes it when the window changes shape.
        --
        -- `Ruler.cast` reads this field where the FOLD leaves it unwritten, and
        -- that one `or` is the whole difference between a cast aimed by two points
        -- and a cast bounded by them. Which means this level is not decoration on
        -- the row: without it the pins would rule a hundred-and-twenty-pixel stub.
        apply = rulesThePage,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The fourteenth, and the one fusion in the catalogue whose two halves were
    -- **already the same gesture**.
    --
    -- SCISSORS and PUSHPIN. Scissors are tapped twice -- the first tap anchors,
    -- the second says which way it runs, the page opens between them. A pushpin is
    -- tapped once and lands. Two pins are two taps, so there is nothing new here
    -- about how the tool is used, which is the rarest thing any row in the
    -- catalogue can say and the reason this one needed no new idea at all.
    --
    -- **What it fixes is that the scissors' first tap was free and did nothing.**
    -- Read the scissors' own row: the whole price of a tool that can be placed
    -- anywhere on the page is the *gap* between the taps, because the horde keeps
    -- walking through it and the row of blobs the first tap lined up is not the row
    -- the second one cuts. A cut has to be led rather than aimed. Here the first
    -- tap is the biggest single hit in the game -- a 51px crater, and whatever
    -- survives it pinned to the paper -- and it leaves an object standing in the
    -- page that you can *see* while you choose the second one. The gap between the
    -- taps stops being the cost and becomes the tool.
    --
    -- Every parent level lands, and the two lines happen to interlock: `blades`
    -- bites deeper "between the two taps", which is now between the two pins;
    -- `through` runs the rest out to the page's edges; and `sever` lifts the half
    -- you are not standing on. The row in src/tools.lua is where the sever is
    -- argued -- three pins are three cuts each choosing their own half, so what is
    -- left is a page in ribbons rather than a page in two, and the parent still
    -- does it three times cheaper and better aimed. What this buys is never the
    -- sever; it is the craters underneath it.
    --
    -- A run may hold only one of the scissors' two answers, since both lines eat
    -- them. The PUNCH puts the blades on a compass leg and takes a circle out of
    -- the page; this drives the two taps into it.
    --
    -- CARTRIDGE, the threading family's line (see the DOT TO DOT). It is the one
    -- of the five that credits nothing for what it removes, so TOP MARKS -- the
    -- ask on the three rows whose whole signature is a cut -- was the alternative
    -- here. The family's price won: a tear between two posts is still two posts,
    -- and the posts are what the meter is spent on.
    fusionLine("tearline", "TEAR LINE", "tearline", "TEAR LINE", {
        needs = { "scissors", "pushpin", "cartridge" },
        fuses = { "scissors", "pushpin" },
        unlock = "THE PINS TEAR THE PAGE FROM EDGE TO EDGE",
        -- The scissors' second level, rebuilt on the run's copy every rebuild
        -- rather than written on the row, and it is the only one of the four that
        -- has to be: `scaleDamage` reaches `cut.blades.damage` by name and
        -- Tools.copy is one level deep. The other three are on the row -- `reach`
        -- is a number nothing writes, `through` is a boolean, and `sever` is a
        -- {tick} with no damage in it at all, which is the PUNCH's reason for
        -- writing its own down too.
        apply = function(t) t.cut.blades = { damage = 20, width = 6 } end,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The fifteenth, and the first fusion off the pushpin that is **one pin rather
    -- than two**.
    --
    -- GLUESTICK and PUSHPIN, and this is the sharpest pair in the family because
    -- the gluestick **deals no damage at all**. That is its whole identity and its
    -- whole problem: the smear holds everything and kills nothing, so it has never
    -- had anything to be holding things *for*. And it goes where your hand goes,
    -- at the dearest ink on the strip, so the patch is laid where you are standing
    -- and the crowd it is for is the crowd you are trying not to be standing in.
    --
    -- A pushpin is exactly the missing half. Ten damage in a 51px circle, placed
    -- anywhere, killing everything it caught but the toughest thing in the game --
    -- and *that* is what the paste is then holding, softened by half again so
    -- everything else the run owns cuts deeper into it, torn on the way loose, and
    -- with the free dragged in from a hundred pixels across. The crater sorts the
    -- crowd and the pool keeps what is left.
    --
    -- **Nothing is strung, and that is the gluestick being itself rather than an
    -- exception.** You do not string paste between two points -- paste is a blob,
    -- and a line of it is a line of glue on your fingers. What a gluestick leaves
    -- is a patch, so what a pin loaded with one leaves is a patch round the hole
    -- (`pool` in src/tools.lua).
    --
    -- The name is the pun and the pun is the tool: a *tack* is a pushpin and
    -- *tacky* is what glue is. It is the CORRAL's kind of name, one word that is
    -- both parents at once -- and unlike the corral's it does not survive the
    -- border, so the Spanish names the blob.
    --
    -- A run may hold only one of the gluestick's two answers: the MOAT is a ring
    -- of paste the tool places for you, and this is a disc of it you place.
    --
    -- SELLOTAPE a fourth time, and the MOAT's reason a second time: a pool whose
    -- worth is per second it is there wants the fixative, which is exactly why it
    -- may not ask for it. Flat price, one gesture, no chain -- nothing else on
    -- the strip has a claim on this row.
    fusionLine("tack", "TACK", "tack", "TACK", {
        needs = { "gluestick", "pushpin", "tape" },
        fuses = { "gluestick", "pushpin" },
        unlock = "A PIN IN A POOL OF PASTE: IT HOLDS WHAT IT SPARED",
        -- No `apply`, and it is the MOAT's reason word for word: everything the
        -- glue's upper levels bring is a bare number the sharpener multiplies on
        -- the run's own copy (`tear`), a table nothing ever writes into (`pull`),
        -- or a scalar (`soften`). There is no shared table for a multiplier to
        -- compound into, so the row says all of it.
        --
        -- Nothing after the unlock either, for the halo's reason.
    }),

    -- The sixteenth, the second that is one pin rather than two, and the row that
    -- makes the pushpin's oldest word true.
    --
    -- RUBBER and PUSHPIN. The pin's own row has called its circle a *crater* since
    -- the day it was written, and what has always actually happened in there is
    -- that things walk out of it -- "anything that killed outright would leave the
    -- pinning with nothing to pin" is the tool's entire design. Load the pin with a
    -- rubber and nothing walks out. Everything the circle caught and did not kill
    -- is thrown straight out of it at 240, twenty-seven pixels, and lands as a
    -- weapon: what a finished rubber sends flying knocks down what it hits.
    --
    -- **The rubber's limitation is not the one every other tool in this family
    -- has.** The others go where your hand goes; a rubber goes where your *wrist*
    -- goes. It only works while the tip is travelling, at a fifteen-pixel reach,
    -- which means standing in the crowd and scrubbing at it -- and the one thing it
    -- does is the best shove in the game. This delivers that shove as a single tap,
    -- at reach, radially, out of a circle you chose.
    --
    -- And the two halves land in the right order without being told to. The crater
    -- goes off first and kills everything but the tank; the pool is laid on the
    -- frame after it lands, so what gets thrown is exactly *what survived* --
    -- straight into whatever is walking in behind it. A tool whose finale is "what
    -- it sends flying knocks down what it hits" and a tool whose whole design is
    -- "the tank walks out of the crater" turn out to be one sentence read from two
    -- ends.
    --
    -- Two of the rubber's four levels have nothing to land in, which is more than
    -- any other fusion drops and exactly what the CLEARING drops: `lean` is a tip
    -- that keeps hitting while it rests and nothing here rests, `scrub` is half
    -- price over ground already covered and nothing here is charged by the pixel.
    -- Both are about the wrist and the meter, and a tap has neither.
    --
    -- A run may hold only one of the rubber's two answers: the CLEARING sweeps a
    -- disc clear as the leg comes round, and this empties one the instant it lands.
    --
    -- MAGNET, the rubber's line a second time (see the CLEARING). 240 of knock
    -- is the biggest throw in the game, and what it throws is what pays for the
    -- next level.
    fusionLine("crater", "CRATER", "crater", "CRATER", {
        needs = { "rubber", "pushpin", "magnet" },
        fuses = { "rubber", "pushpin" },
        unlock = "A PIN THAT THROWS OUT WHAT IT DID NOT KILL",
        -- The rubber's finale, rebuilt on the run's copy every rebuild rather than
        -- written on the row, which is the CLEARING's placement for the CLEARING's
        -- reason: `scaleDamage` reaches `tool.ram` by name at the top level, and
        -- being reachable is exactly why it cannot sit on a row Tools.copy only
        -- copies one level deep.
        apply = function(t) t.ram = { damage = 5 } end,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The seventeenth, the last off the pushpin, and the only fusion in the game
    -- whose two parents already share a gesture.
    --
    -- STAPLER and PUSHPIN. Every other fusion in this family works because the pin
    -- brings a reach and the other tool brings a *nib* -- a line, a band, a wall, a
    -- pool -- and a pin has never had one. The stapler has no nib either. It is a
    -- `drop`, the same block, placed by the same tap, arriving down the same code
    -- path; the two tools have differed in nothing but the numbers inside one block
    -- since the day they were written. So this row is not two shapes on a page, it
    -- is one block laid over another -- and they are opposites field for field,
    -- which is what makes the overlay worth doing. One big telegraphed decision
    -- against a hundred small ones. Take the pin's numbers and the staple's
    -- gesture and you have a tool; take them the other way round and you have a
    -- staple that makes you wait a quarter of a second for it, which is nothing at
    -- all. There is exactly one interesting way to read the pair.
    --
    -- Three fields come across and each of them *retires* a pushpin level rather
    -- than sitting beside it. `instant` takes off the fall the pin's own file argues
    -- so carefully for -- the promise that a report is coming, eleven pixels of bat,
    -- the reason a tap on a moving target is not a certainty -- because a stapler
    -- has never had one. `rake` is the stapler's own finale, unchanged and running
    -- through the same `Game:rakeDrops`: a tap is still one pin, and holding the
    -- pointer down rakes a seam of craters 48 apart, which is the parent's written
    -- rule ("so the circles just overlap") read at a 25px bite instead of a 7px
    -- one. And `crit` replaces `point`: both are a multiplier on one hit and they
    -- differ only in what decides it, and *aim* cannot decide it on a tool whose
    -- gesture is a drag -- what you choose in a seam is a line, and which body each
    -- step lands its point on is luck.
    --
    -- **Which is where the two upgrade lines above turn out to have been arguing
    -- with each other.** The stapler's crit level is written on the claim that a
    -- one-in-five is a *rate* only when the sample is large, "where the same roll on
    -- a pin you get two of from a full meter would only ever be a story about one
    -- pin". Four a meter, raked, is the sample that makes it a rate. The drag is
    -- what legitimises the crit, and the crit is what pays for the aim the drag gave
    -- up.
    --
    -- What survives from the pin is the crater, the hold and `drive`, and `drive` is
    -- where a seam pays off in a way a tap never could. Its own row is careful that
    -- "a pin dropped on a *lone* skull changes nothing at all" -- the exception to
    -- "the tank walks out of the crater" has to be earned through the crowd standing
    -- round it -- and a rake is how a crowd gets under a circle on purpose. The
    -- craters do not overlap, so nothing here doubles up: what a seam does to a grin
    -- is hit it as it goes past and again on the next step. The tank dies to being
    -- *raked across*.
    --
    -- One of the stapler's four levels has nothing to land in, on the CLEARING's
    -- terms: `prise` is wire pulled back out of the paper for a second bite, and
    -- what this row drives in is a pin -- a hole, with nothing to pull. A crater
    -- does not come out again, and the pin's own file is the argument for why not.
    --
    -- FIXATIVE, the HEM's argument at the pushpin's numbers: the pin this row
    -- rakes into the page carries `freeze` 4 and `life` 4 inside its `drop`, and
    -- both are numbers `scalePersistence` walks. A seam of pins that holds a
    -- second longer is a seam the next rank does not get through. Not a tax --
    -- the 10 and the crit are paid on the press.
    fusionLine("volley", "VOLLEY", "volley", "VOLLEY", {
        needs = { "stapler", "pushpin", "fixative" },
        fuses = { "stapler", "pushpin" },
        unlock = "A PIN THAT DOES NOT FALL, AND A SEAM IF YOU DRAG",
        -- No `apply`, and it is the TACK's reason: `crit` and `rake` are tables
        -- nothing in the game ever writes into -- scaleDamage steps over
        -- `crit.mult` by name, being a multiplier on damage it has already scaled
        -- -- and `drive` is a bare number it multiplies on the run's own copy. So
        -- there is no shared table for a multiplier to compound into, and the row
        -- may say all of it.
        --
        -- Nothing after the unlock either, for the halo's reason.
    }),

    -- **The eighteenth, and the first of seven off the RULER.**
    --
    -- The ruler had been fused into twice before it ever did any fusing. The FOLD
    -- casts one between two compass circles and the SNAP LINE casts one between two
    -- pins, and both are answers to the same sentence: a ruler's line goes through
    -- your own feet, so you choose which way the page is swept and never where. One
    -- sells the reach to buy the position, the other keeps the reach and pays in
    -- precision.
    --
    -- These seven leave that sentence alone and answer the complaint nobody had
    -- written down. **A ruler's mark does nothing.** Everything in the band is hit
    -- once and thrown clear of the line to both sides, and what is left is a
    -- corridor with a ruled pencil line down the middle of it -- and the corridor
    -- closes the moment the crowd walks back in, because a pencil line is not
    -- terrain, not fire, not paste and not a fence. So the second parent is what
    -- gets left in the lane. The ruler opens it; the fusion keeps it open.
    --
    -- Every one of the seven is the whole page, and that is the ruler's own finale
    -- doing it rather than a decision taken seven times: a fusion is only dealt once
    -- both its lines are finished, and a finished ruler rules corner to corner. So
    -- all seven `apply` the same half-diagonal (`rulesThePage` above), and what
    -- distinguishes them is entirely what is lying in the lane afterwards.
    --
    -- PENCIL and RULER, and it is the pair a child is issued on the first day of
    -- term. What the pencil leaves is nothing except the fact of having been drawn,
    -- which makes this the only one of the seven that costs the corridor nothing --
    -- the other six all take something off the shove, and two of them stop it dead.
    -- What it rules is the band's two long edges, which are the two dashed lines a
    -- ruler's aim has drawn since the tool was written and are exactly where a ruler
    -- has always been weakest: inside the band you take 12 and a pixel outside it
    -- you took nothing, and now you take 9.
    --
    -- A run may hold only one of the pencil's two answers, since both lines eat it.
    -- The LASSO is a ring the compass draws round a crowd; this is two lines you
    -- point through one.
    --
    -- SELLOTAPE a fifth time, untouched a fifth time.
    fusionLine("margin", "MARGIN", "margin", "MARGIN", {
        needs = { "pencil", "ruler", "tape" },
        fuses = { "pencil", "ruler" },
        unlock = "IT RULES A LINE DOWN EITHER SIDE OF THE BAND",
        -- The ruler's finale and nothing else. The pencil's two levels that land
        -- are a number and a nib, both of which the row may say outright -- and its
        -- other two do not land at all: `flow` is a price per pixel with no finger
        -- to keep down, and `loop` closes a ring by drawing one, which two parallel
        -- lines will not do however long they run. The row argues both.
        apply = rulesThePage,
        -- Nothing after the unlock, for the halo's reason.
    }),

    -- The nineteenth, and the pen's third answer.
    --
    -- PEN and RULER. The pen's two complaints are that its line goes where its hand
    -- goes and that its line is open, and it has now been given three different
    -- ways out of them. The CORRAL draws a fence with no ends where your hand is
    -- not. The STOCKADE builds one a post at a time with a crater under every
    -- corner. This one fixes neither -- the line still goes through you and it still
    -- has two ends -- and instead answers a question nobody asked, which is **how
    -- long a fence can be**.
    --
    -- A hundred and seventy pixels from a full meter, drawn at the speed of your own
    -- hand, against the page's whole diagonal in the frame you let go. The page is
    -- in two. What keeps that from being a run nothing can reach is the camera and
    -- not a rule: the wall divides where you *were*, the page keeps scrolling, and
    -- the horde spawns off the ring beyond it -- so the one fence in the game you
    -- use by walking away from it.
    --
    -- **It is also the one fused row the pen's finale lands on cleanly.** `keep`
    -- holds one gesture's worth of wall and drops it when the next is laid, and a
    -- ruler is one gesture exactly. The STOCKADE had to leave the level out because
    -- a fence built pin by pin is not one gesture; here ruling the next spine drops
    -- the last, which -- with `pop` -- means replacing your own wall is an attack
    -- along the length of the old one.
    --
    -- A run may hold one of the pen's three answers. That is now the widest choice
    -- any tool offers, and the three are genuinely different shapes rather than
    -- three sizes of the same one: a circle the arm draws, a shape you build, and a
    -- line you point.
    --
    -- SELLOTAPE a sixth time. `keep` and a nine-second wall put this row where
    -- the CORRAL is: the fixative is its prerequisite and not its choice.
    fusionLine("spine", "SPINE", "spine", "SPINE", {
        needs = { "pen", "ruler", "tape" },
        fuses = { "pen", "ruler" },
        unlock = "IT RULES A WALL FROM ONE EDGE TO THE OTHER",
        -- The pen's third level, built here rather than written on the row for the
        -- HALO's reason: `scaleDamage` reaches `pop.damage` by name and Tools.copy
        -- is one level deep. Everything else the pen brings is a bare number, a
        -- boolean or a stamp, and the row says all of it.
        apply = function(t, screen)
            rulesThePage(t, screen)
            t.pop = { damage = 4, reach = 6 }
        end,
    }),

    -- The twentieth, and the marker's third.
    --
    -- MARKER and RULER. The band is the best ground in the game and the worst to
    -- place -- it goes where your hand goes, which is where *you* are, and the crowd
    -- it is for is the crowd you are trying not to be standing in. The HALO answers
    -- that with a ring drawn round them; the CORDON answers it with a strip pinned
    -- between two craters; and this does not answer it at all. It makes the
    -- placement irrelevant instead: a line through your own feet at an angle you
    -- chose crosses everything on the page, and what it crosses catches fire.
    --
    -- **It is the one row in the family where the ruler's shove is doing the work
    -- rather than being spent.** Everything in the band takes 12 and is thrown clear
    -- of the line to both sides -- across thirteen pixels of burning nib on the way
    -- out, and touching the band at all is two seconds of fire that travels with the
    -- body and goes on ticking after it has left. The corridor is opened by throwing
    -- the crowd through the thing that is holding it open, and nothing had to be
    -- written for that: it is the parent's shove and the parent's burn landing in
    -- the same frame.
    --
    -- A run may hold only one of the marker's three answers.
    --
    -- FIXATIVE, the HALO's line for the HALO's reason: what a finished marker
    -- leaves is 3.6 seconds of burning band (`life`), `scalePersistence` reaches
    -- it, and a band ruled edge to edge is worth what it is still there for. The
    -- fire itself does not move -- `ignite` is neither `life` nor `freeze`.
    fusionLine("underline", "UNDERLINE", "underline", "UNDERLINE", {
        needs = { "highlighter", "ruler", "fixative" },
        fuses = { "highlighter", "ruler" },
        unlock = "IT RULES A BURNING BAND ACROSS THE PAGE",
        -- The marker's own fourth, built here exactly as the HALO builds it and for
        -- the same reason -- `scaleDamage` writes into `ignite`.
        apply = function(t, screen)
            rulesThePage(t, screen)
            t.ignite = { time = 2, tick = 0.4, damage = 2 }
        end,
    }),

    -- The twenty-first, and the gluestick's third.
    --
    -- GLUESTICK and RULER, and it is the sharpest pair in this family for the reason
    -- the TACK is the sharpest in the other: the gluestick **deals no damage at
    -- all**. It holds everything and kills nothing, at the dearest ink on the strip,
    -- laid where you are standing.
    --
    -- **What makes this one worth reading is that it is the fusion that does not do
    -- the family's job.** Six of these seven open a lane and keep it open. Paste
    -- holds, and a held body drops the push it was carrying the same frame -- so the
    -- ruler's shove, which is the whole tool, simply does not happen to anything
    -- this catches. What lands is 12 across the band and a page-wide bar of glue
    -- with the crowd standing in it.
    --
    -- Which is not a rule breaking, it is a fusion doing what a fusion is: both
    -- parents still doing exactly what they always did. The gluestick has never
    -- shoved anything and says so on its row; the ruler decides *where* the page
    -- stops. And a straight edge turns out to be a very good way to decide it,
    -- because a crowd does not walk round a bar of paste the way it walks round a
    -- fence -- it walks into it and stays. `soften` then cuts everything the run owns
    -- half again as deep into a whole page of stationary crowd, `tear` takes a
    -- blob's worth off each of them on the way loose, and `pull` collects the ones
    -- that would have missed.
    --
    -- A run may hold only one of the gluestick's three answers: a ring of paste the
    -- tool places for you, a disc of it round a crater you placed, or a bar of it
    -- from one edge of the page to the other.
    --
    -- SELLOTAPE a seventh time, and the MOAT's rule a third time: paste priced
    -- per second may not ask for the line that sells seconds.
    fusionLine("trench", "TRENCH", "trench", "TRENCH", {
        needs = { "gluestick", "ruler", "tape" },
        fuses = { "gluestick", "ruler" },
        unlock = "IT RULES A BAR OF PASTE THEY STICK FAST IN",
        -- The ruler's finale and nothing else, and it is the TACK's reason word for
        -- word: everything the glue's upper levels bring is a bare number the
        -- sharpener multiplies on the run's own copy (`soften`, `tear`) or a table
        -- nothing in the game ever writes into (`pull`). Only what `scaleDamage`
        -- reaches has to be built fresh every rebuild.
        apply = rulesThePage,
    }),

    -- The twenty-second, and the second panic button on the strip.
    --
    -- RUBBER and RULER. The CLEARING is the first: a compass leg that wipes the disc
    -- it swept instead of cutting the rim it drew, planted on your own feet, so the
    -- rank that had reached you goes over the horizon of it. This is the same idea
    -- with no horizon.
    --
    -- **A rubber leaves nothing**, so there is nothing to leave in the lane and the
    -- rubber's half lives entirely inside the block -- where it takes the band off
    -- (`snap.wipe`, Ruler:strike). What a ruler with one lands on is everything
    -- within its own *length* of the line, and a finished ruler's length is half a
    -- page diagonal, so it lands on the page: the whole crowd, wherever it is
    -- standing, chipped for 2 and thrown straight away from the line you pointed.
    -- The same word in the other block does the same job for the CLEARING, and both
    -- are only allowed because a rubber's hit was never an edge -- you do not cut
    -- with one, you clear an area with one.
    --
    -- What you are choosing is an *axis* rather than a place, which is the only
    -- decision in it and is a real one: turn it wrong and half the crowd is thrown
    -- at the half of the page you were about to walk into.
    --
    -- A run may hold only one of the rubber's two answers. The CLEARING empties a
    -- disc round your feet; this parts the page along a line through them.
    --
    -- MAGNET, the rubber's line a third time (see the CLEARING). This is the
    -- widest throw of the three -- the whole page thrown clear of the line -- so
    -- it is also the row that scatters its own xp the furthest.
    fusionLine("parting", "PARTING", "parting", "PARTING", {
        needs = { "rubber", "ruler", "magnet" },
        fuses = { "rubber", "ruler" },
        unlock = "THE WHOLE PAGE IS THROWN CLEAR OF THE LINE",
        -- The rubber's finale, built here rather than written on the row, the
        -- CLEARING's placement for the CLEARING's reason: `scaleDamage` reaches
        -- `tool.ram` by name, so a `ram` on the shared row would compound the
        -- multiplier into it every rebuild.
        apply = function(t, screen)
            rulesThePage(t, screen)
            t.ram = { damage = 5 }
        end,
    }),

    -- The twenty-third, and the stapler's third.
    --
    -- STAPLER and RULER. The stapler is the most repetitive tool on the strip -- ten
    -- a meter, one press each, every one aimed by hand at a 15px circle on something
    -- that is moving -- and every fusion it has is a different way of not doing the
    -- repeating. The HEM runs the seam round a circle until it closes. The VOLLEY
    -- sells the pin's tap back as a drag. This runs one straight across the page in
    -- a single press: a line of wire with two ends, at an angle you chose, from one
    -- edge of the paper to the other.
    --
    -- **It is the dearest single press in the game and the stapler's own invariant
    -- is what makes it so.** Every level in that line is written against "ten a
    -- meter is still ten a meter", so wire is the one thing on a fused row that
    -- cannot be free. The HEM charges for it as the drag opens (`sweep.per`); here
    -- the count is decided by the screen rather than by the player, so there is
    -- nothing for a drag to buy and the whole of it is one number on the row.
    --
    -- And like the TRENCH it does not shove: the band takes 12, the wire takes 6 on
    -- top of it with a fifth of those going straight through at 18, and everything
    -- the wire catches is fastened to the paper before the push it was given is ever
    -- spent. The ruler opens the lane and the wire keeps what was standing in it,
    -- which is what a stapler is for. And then it lets go of all of it at once: the
    -- wire comes back out of the page two seconds later for a second 6, so the row
    -- is a straight line that hits, holds, and hits again -- and leaves nothing
    -- behind, which is the level's own trade wherever it is taken.
    --
    -- A run may hold only one of the stapler's four answers.
    --
    -- SELLOTAPE an eighth time, and this is the row that argues hardest for an
    -- ink line and must not be given one. 0.9 is the dearest single press in the
    -- game and a full meter barely affords it -- which the row itself calls the
    -- point rather than a side effect: three seconds of standing still per press
    -- is the only thing holding back a run that would otherwise wire the whole
    -- page shut (see the SEAM in src/tools.lua). The CARTRIDGE halves that wait
    -- and the INKWELL buys the second press outright, so either one is a catalyst
    -- that pays a run for dismantling the row's own brake. The tape says nothing
    -- about the meter, and here that is the whole of its qualification.
    fusionLine("seam", "SEAM", "seam", "SEAM", {
        needs = { "stapler", "ruler", "tape" },
        fuses = { "stapler", "ruler" },
        unlock = "IT RULES A SEAM OF STAPLES ACROSS THE PAGE",
        -- The ruler's finale, and the stapler's finished block one level inside the
        -- ruler's own. Built here rather than written on the row because it must be:
        -- `scaleDamage` reaches `snap.wire.damage` by name (src/loadout.lua) and
        -- Tools.copy copies the row and its blocks one level deep, so a whole block
        -- a level further in would compound the multiplier every rebuild.
        --
        -- Every number is the stapler at its four -- 6 a press, one in five straight
        -- through at 18, the wire torn back out two seconds later for a second 6,
        -- and the seam's own 12px spacing -- and `rake.every` is the one field here
        -- that has changed
        -- *reader* rather than value. Nothing routes on it (the gesture is the snap,
        -- and the block is not even on the row), so the seam is not dragged by a
        -- finger; Game:seamAlong reads it, and it means what it has always meant --
        -- how far apart along a path the presses go.
        --
        -- `sound` is named on the block for Game:driveDrop's reason: what arrives
        -- there is a block and not a tool, so a row called something other than
        -- STAPLER would otherwise press in silence.
        apply = function(t, screen)
            rulesThePage(t, screen)
            t.snap.wire = {
                lands = Staple,
                radius = 7, damage = 6, freeze = 2, life = 2,
                crit = { chance = 0.2, mult = 3 },
                prise = true,
                rake = { every = 12 },
                sound = "stapler",
            }
        end,
    }),

    -- The twenty-fourth, the last of the ruler's seven, and the scissors' third.
    --
    -- SCISSORS and RULER, which is a real object in a real stationery cupboard: a
    -- straight edge with a blade hinged to run down it, and what it does to a page
    -- is exactly this.
    --
    -- **The two halves are one gesture and it is the ruler's.** The scissors' whole
    -- price is the *gap* between their two taps -- the horde keeps walking through
    -- it, so the row of blobs the first tap lined up is not the row the second one
    -- cuts, and a cut has to be led rather than aimed. A ruler has no gap: held,
    -- turned, released, and the page opens along the line in the frame it landed. So
    -- what this buys is a cut that can be *aimed*, and what it pays with is the one
    -- thing a ruler cannot give -- a line that goes anywhere but through your own
    -- feet.
    --
    -- 12 from the band and 20 from the blades is 32, the deepest single hit in the
    -- game, and the grin has 34. The tank goes on walking out of everything, which
    -- is its job.
    --
    -- **And the scissors' finale is the level this row is really about.** `sever`
    -- lifts "the half you are not standing on" off the page with everything on it,
    -- and a ruler's line goes *through* you -- so at the moment this lands there is
    -- no such half. Every other cut in the game freezes the answer off the tap that
    -- placed it; freezing one here would pick a half off a floating-point sign,
    -- which is a page-wide finale decided by nothing.
    --
    -- So this one keeps asking. It re-reads your feet every frame (`follows` on the
    -- sever, `Scissors:takeSides`): straddle the slit and neither half goes, step
    -- off it and the half you left goes with everything on it, cross back and it is
    -- the other half instead. The ruler's one central fact stops being what breaks
    -- the level and becomes what aims it -- the pivot is your feet, so the offcut is
    -- wherever your feet are not, and choosing it is *walking* rather than tapping.
    --
    -- It is the same move the TEAR LINE made on the same level from the other side:
    -- there three pins are three cuts each picking their own half and what is left
    -- is a page in ribbons. Both generalise the parent's sentence rather than break
    -- it, and neither costs the parent anything -- an ordinary cut still freezes its
    -- half, because a cut you placed with two taps has a side you chose.
    --
    -- The FOLD is still the row to read beside this one: it gave up the ruler's own
    -- finale for the mirror image of the same fact. Between them they say the thing
    -- worth knowing about fusing anything into a ruler -- **the pivot is your own
    -- feet, and every parent level that assumed otherwise has to be looked at.**
    --
    -- A run may hold only one of the scissors' three answers, and all three now end
    -- in the same level read three different ways: the PUNCH takes a disc out of the
    -- page and lifts what is standing in it, the TEAR LINE cuts the page to ribbons
    -- and lifts every offcut at once, and this lifts whichever half you are not
    -- standing on *this second*.
    --
    -- TOP MARKS, the third of the three rows that ask for it, and the three are
    -- the three whose signature is a cut. What a cut removes is not killed:
    -- `Game:liftEnemyTo` credits no gem, no xp and no kill on the tally, so the
    -- half of the page you step off carries the run's own levelling away with it
    -- while the difficulty clock goes on climbing. This is the one line on the
    -- strip that answers that, and it is a condition and not a tax -- the `snap`
    -- half still cuts 12 to whatever is standing on the line, so the row earns
    -- something either way.
    --
    -- And with that the three tools that reach have all nine of theirs, which is
    -- every pair in the game a gesture could be borrowed for.
    fusionLine("guillotine", "GUILLOTINE", "guillotine", "GUILLOTINE", {
        needs = { "scissors", "ruler", "topmarks" },
        fuses = { "scissors", "ruler" },
        unlock = "IT TRIMS THE PAGE: THE HALF YOU STEP OFF GOES",
        -- The ruler's finale and the scissors' second level, and the second is here
        -- for the TEAR LINE's reason: `scaleDamage` reaches `cut.blades.damage` by
        -- name and Tools.copy is one level deep. The other three the row may say
        -- outright -- `reach` is a number nothing writes, `through` is a boolean
        -- written at false on purpose, and `sever` is a table with no damage in it
        -- at all, which is the PUNCH's reason for writing its own down too.
        apply = function(t, screen)
            rulesThePage(t, screen)
            t.cut.blades = { damage = 20, width = 6 }
        end,
    }),

    -- **The twenty-fifth, and the first of five off the PENCIL.**
    --
    -- Every fusion above this line has a *carrier* in it. The compass reaches away
    -- from you, a pin lands where you tapped, a ruler is aimed -- three gestures
    -- worth borrowing, nine pairings, eight and seven, and the second parent is
    -- always what the borrowed gesture is carrying. That is twenty-four of the
    -- forty-five pairs the strip can make, and the twenty-one left over are
    -- exactly the ones with no carrier in them: a pencil and a pen have no reach
    -- to lend each other, so there was nothing for either to hold.
    --
    -- These five are the answer, and it is a fourth carrier rather than twenty-one
    -- exceptions: **the stroke itself**. A line you drag has a length, an inside
    -- once it closes, and a mark left lying on the page afterwards -- as much a
    -- shape as a ring is, and the pencil is the one tool that owns all three. So
    -- the second parent is what the drawn line is made of, or what closing one
    -- means, and the gesture never changes in any of the five: press, drag, lift,
    -- charged by the pixel.
    --
    -- **SELLOTAPE is not the catalyst here, and that is the family saying which
    -- family it is.** The tape was once the third line of all twenty-four rows
    -- above, and that was the mistake this family was the first to notice: what
    -- the tape pays a run for is *time*, which is the currency a run that
    -- committed ten levels to two tools has already been spending, and it says
    -- nothing at all about a line. Twenty-four rows asking for it made it a toll
    -- rather than a sentence. The INKWELL says something.
    --
    -- Which is the rule the rest of the catalogue was eventually held to, and the
    -- twenty-four came apart under it: six of them ask the fixative for a clock
    -- they leave running, six the cartridge for the next press, three the magnet
    -- for xp thrown out of reach and three top marks for xp never credited at
    -- all. Ten still ask the tape, and the LASSO says what they have in common --
    -- it is the catalyst for a row no economy line can speak to without becoming
    -- that row's prerequisite. This family is where the argument starts. All five of these are priced by the pixel,
    -- three of them want one long unbroken gesture to work at all, and the meter
    -- is the only thing standing between a pencil and the whole page -- so a run
    -- that finished the well is a run that has been *drawing*, which is the
    -- condition this family is actually aimed at. It is given back untouched
    -- exactly as the tape is, on the same terms: a fusion may ask for something it
    -- does not consume, and that is how it is aimed at a build rather than at a
    -- pair of tools.
    --
    -- PENCIL and PEN, which is the pair every run opens holding and the only
    -- fusion in the book that eats both of the tools you were issued with. What
    -- the pen has never been able to do is hurt anything; what the pencil has
    -- never been able to do is *keep* what it ringed. Each is the other's ceiling,
    -- which is what makes this the one to open the family on.
    --
    -- A run may hold one of the pencil's six answers and one of the pen's four,
    -- and this row is on both lists -- so taking it is the choice that closes the
    -- most doors of any card in the draft.
    --
    -- **The two numbers on the row are the fusion.** 9 is what being drawn over
    -- costs and 1 is what leaning on the finished fence costs, and it took a field
    -- (`sting` in src/tools.lua) because the two parents disagree about `damage`
    -- and neither is wrong: a pencil is what the nib does going past, a pen is what
    -- the wall does to a rank standing against it for as long as it stands there.
    -- Nothing before this row had ever needed both, because nothing before it was a
    -- brush whose mark outlived the stroke by nine seconds and could be kept
    -- indefinitely.
    fusionLine("deckle", "DECKLE", "deckle", "DECKLE", {
        needs = { "pencil", "pen", "inkwell" },
        fuses = { "pencil", "pen" },
        unlock = "A FENCE YOU CAN CLOSE, AND WHAT IT SHUTS IN IS CUT",
        -- The pencil's finale and the pen's third level, both built here rather
        -- than written on the row for the HALO's reason: `scaleDamage` reaches
        -- `loop.damage` and `pop.damage` by name and Tools.copy is one level deep,
        -- so a table the sharpener writes into has to be built fresh on the run's
        -- copy every rebuild. The pen's other three are flat fields and the row may
        -- say them outright -- including `keep`, so this is a fusion written at
        -- both parents finished with nothing left out of either.
        apply = function(t)
            t.loop = { damage = 4 }
            t.pop = { damage = 4, reach = 6 }
        end,
    }),

    -- The twenty-sixth. PENCIL and RUBBER, which is one object rather than two --
    -- a pencil with an eraser on the end of it -- and the only row on the strip
    -- that is a different tool depending on whether your finger moves.
    --
    -- The pair is two complaints that cancel. A pencil is a line you have to
    -- commit to: there is no gesture in the tool for "not now", so the finger is
    -- down and the crowd is arriving and the only thing you can do about it is
    -- keep drawing. A rubber is that gesture and nothing else -- 240 of shove and
    -- almost no damage, the panic button of the strip -- and its own trouble is
    -- the mirror image: it has to be scrubbed, so it is only ever a weapon in the
    -- hand of a run that was already holding it. One row, one press to draw with
    -- and one to shove with, and neither tool has to be the one you picked.
    --
    -- **The tap is priced and refused, not clamped.** 0.12 is about eight from a
    -- full meter, over the stapler's flat 0.1 and well under the scissors' 0.3:
    -- it is a 7px circle you have to be standing next to, it kills almost nothing
    -- on its own, and what it is worth is entirely where the crowd ends up. A tap
    -- you cannot afford simply does not land, the way every price in the game
    -- refuses rather than clamping (`Purse.spend` is the same argument one screen
    -- over).
    fusionLine("stub", "STUB", "stub", "STUB", {
        needs = { "pencil", "rubber", "inkwell" },
        fuses = { "pencil", "rubber" },
        unlock = "DRAW WITH THE POINT, TAP TO SHOVE THEM OFF IT",
        -- The pencil's finale and the whole finished rubber folded into one press.
        -- Built here rather than on the row because `scaleDamage` reaches three
        -- numbers in it by name -- `loop.damage`, `tap.damage` and `tap.ram.damage`
        -- -- and Tools.copy is one level deep, let alone two.
        --
        -- Every number is the rubber's own: the 7px tip it was written with, the
        -- 2 it chips for, the 240 its first level throws at, and the 5 its finale
        -- knocks down what it lands on for. What is left out is `lean` and
        -- `scrub`, and both for the LASSO's reason rather than as a nudge -- one
        -- prices a resting tip and the other prices a second pass over the same
        -- patch, and a gesture that is over the instant it starts has neither.
        -- `slack` is the rubber's own release threshold (`RUB_HEARD` in
        -- src/game.lua), which is already the line that file draws between a rub
        -- that happened and one that did not.
        apply = function(t)
            t.loop = { damage = 4 }
            t.tap = {
                radius = 7, damage = 2, knock = 240,
                ram = { damage = 5 },
                ink = 0.12,
                -- What still counts as not having moved, and both numbers are the
                -- *finger's* rather than the line's -- see Game:wasTap for why
                -- measuring the mark was wrong. 6 screen pixels of accumulated
                -- travel is a thumb that did not go anywhere on a 320-wide canvas,
                -- and a third of a second is a press nobody would call a hold. A
                -- tap is brief and it is still, and it has to be both: travel alone
                -- would call a slow careful short line a tap, and time alone would
                -- call a flick one.
                slack = 6, hold = 0.3,
            }
        end,
    }),

    -- The twenty-seventh. PENCIL and HIGHLIGHTER, and the trade is one sentence:
    -- the band gives up *touching* and buys *surrounding*.
    --
    -- A finished marker sets alight anything that so much as crosses it, and lays
    -- 13 pixels of page to do it. This is the nib the tool was written with, 9
    -- across, and nothing that walks over it catches at all -- what catches is
    -- whatever the line closes on. It is the CLEARING's kind of fusion, a fused
    -- row taking a *central* fact off a parent rather than adding to it, and the
    -- argument is the same shape: a band that ignited on contact *and* ignited
    -- what it enclosed would have bought nothing with the pencil, because
    -- everything inside a ring you just drew has already been touched by the
    -- drawing of it.
    --
    -- A run may hold one of the pencil's six and one of the marker's three.
    fusionLine("bleed", "BLEED", "bleed", "BLEED", {
        needs = { "pencil", "highlighter", "inkwell" },
        fuses = { "pencil", "highlighter" },
        unlock = "RING THEM WITH INK AND THE WHOLE PATCH CATCHES",
        -- The marker's finale, unnudged, hung off the pencil's finale instead of
        -- off the band: `loop.ignite` rather than `ignite`, which is the whole of
        -- what this row fuses. Built here for the HALO's reason -- `scaleDamage`
        -- reaches `loop.ignite.damage` by name.
        --
        -- No `loop.damage` beside it, and that is deliberate rather than an
        -- oversight: being ringed is one event and it is the fire. A number there
        -- would be the pencil quietly keeping its own finale as well as buying the
        -- marker's, and it is what the walk in src/loadout.lua now asks by name
        -- rather than assumes.
        apply = function(t)
            t.loop = { ignite = { time = 2, tick = 0.4, damage = 2 }, wash = true }
        end,
    }),

    -- The twenty-eighth. PENCIL and GLUESTICK, and the name is the tool: to drag
    -- is what your finger does and what the line does back.
    --
    -- One of the gluestick's four levels acts on things the smear has *not*
    -- caught, and it is the finale -- everything free within reach is pulled
    -- towards the nearest ink. On a gluestick that gathers a crowd into a hold
    -- that cannot hurt it. On a pencil the same field is feeding a blade.
    --
    -- So the hold, the softening and the tear all go, and that is the fusion's
    -- argument rather than a trim. The gluestick's written identity is that the
    -- smear never hurts what it holds -- three of its four levels are about what
    -- happens to something stuck -- and a body dragged onto a pencil line does not
    -- need to be held there. What survives is the one level that was never about
    -- the hold, and the reach it throws is the finished gluestick's to the pixel:
    -- see the row, where 42 is 26 measured off a 4px point instead of a 20px head.
    fusionLine("drag", "DRAG", "drag", "DRAG", {
        needs = { "pencil", "gluestick", "inkwell" },
        fuses = { "pencil", "gluestick" },
        unlock = "THE LINE PULLS THEM ONTO ITSELF AS YOU DRAW",
        -- The pencil's finale, and it is the level the field was waiting for: a
        -- line that drags the crowd into itself and then closes a ring behind them
        -- is the two halves of the row doing one thing. Built here for the HALO's
        -- reason; `pull` is written on the row instead, because nothing ever writes
        -- into it and the sharpener has no business in a speed.
        apply = function(t) t.loop = { damage = 4 } end,
    }),

    -- The twenty-ninth, and the last of the five. PENCIL and SCISSORS: the
    -- scissors' finale with a shape you drew round it instead of a straight line
    -- through the page.
    --
    -- **Nothing inside the ring is hurt.** It is taken off the paper with the
    -- paper, which means the row inherits the scissors' price along with the
    -- scissors' effect -- no gem, no xp, nothing split and nothing burst -- and
    -- the price is the point. A border you can draw round anything at all cannot
    -- be allowed to kill anything at all, so it does something absolute instead
    -- and pays for it in the one currency a run cannot buy back.
    --
    -- It is also the answer to the question the pencil's own finale left open. A
    -- lasso claims an area for 4 damage, which is chaff and a chip off a skull,
    -- and it is cheap because the ring is yours to draw badly around a crowd that
    -- is walking away from you. The four other rows in this family all answer
    -- "what if the ring did more"; this one answers "what if it did something
    -- else", and it is the only one of the five that makes the pencil stop being a
    -- weapon.
    --
    -- What a hand can ring is smaller than what a cut can halve, and that is the
    -- trade against the parent rather than a limitation of it: the scissors take
    -- half a page in one tap and cannot choose its shape, and this chooses the
    -- shape exactly and has to walk round it while the crowd walks too.
    --
    -- **Nothing is built here**, which makes it the only fusion in the family with
    -- no `apply` at all -- and it is the PUNCH's reason exactly. What a severed
    -- region does to the crowd is take it off the page rather than hurt it, so
    -- there is no damage in `loop.lift` for the sharpener to find, nothing shared
    -- for it to compound, and the row may simply say what it does.
    fusionLine("cutout", "CUTOUT", "cutout", "CUTOUT", {
        needs = { "pencil", "scissors", "inkwell" },
        fuses = { "pencil", "scissors" },
        unlock = "THE RING TAKES THE PAGE, AND THEM WITH IT",
    }),

    -- The thirtieth, and the sixth off the pencil. PENCIL and STAPLER, and it is
    -- the second row in the family whose tool depends on whether your finger moves.
    --
    -- The STUB was the first and it is the mirror of this one. There the tap is the
    -- panic -- a rubber on the end of a pencil, for the moment the crowd arrives and
    -- there is no gesture in the tool for "not now". Here the tap is the *work*: it
    -- is a stapler, used exactly as a stapler is used, and the drag is what the work
    -- gets fastened to. Two rows, one shape, opposite arguments.
    --
    -- **Every staple goes through, and that is the stapler's own reasoning applied
    -- to a smaller sample rather than a number being handed out.** The parent rolls
    -- one in five and its row says why: a one-in-five on a thing you tap dozens of
    -- times a page is a rate, and the arithmetic is honest because the sample is
    -- large -- where the same roll on a pushpin you get two of from a full meter
    -- would only ever be a story about that one pin. This gets two per gesture. So
    -- the chance goes to 1 for exactly the reason it was set to 0.2, and what is
    -- kept is not the number but the sentence under it.
    --
    -- What pays for it is the stapler's *finale*, which this row cannot have. `rake`
    -- is the one level in the catalogue that changes a gesture -- hold and drag and
    -- you run a seam, ten a meter, a third of the page -- and the drag here is
    -- already spent on the pencil. So the trade is a missing field rather than a
    -- nudged number: thirty staples along a line you dragged, or two at the ends of
    -- one you drew, and those two go through whatever they land on.
    --
    -- A run may hold one of the pencil's six and one of the stapler's four.
    fusionLine("stitch", "STITCH", "stitch", "STITCH", {
        needs = { "pencil", "stapler", "inkwell" },
        fuses = { "pencil", "stapler" },
        unlock = "A STAPLE AT EACH END, AND EVERY ONE GOES THROUGH",
        -- The pencil's finale and the finished stapler's whole drop, both built here
        -- rather than written on the row for the HALO's reason: `scaleDamage`
        -- reaches `loop.damage` and `fasten.damage` by name and Tools.copy is one
        -- level deep.
        --
        -- The staple is the SEAM's `wire` with two fields changed, and the pair is
        -- worth reading together because the differences are the whole of both rows:
        -- the chance goes from a fifth to all of them, and `rake` goes. There a
        -- straight edge presses thirty of them along a line it ruled; here a hand
        -- drives two into the ends of a line it drew. `sound` is named on the block
        -- for `Game:driveDrop`'s reason -- it reads the block and never the row, so
        -- a staple driven by anything but a tap arrives silent unless the block says
        -- otherwise.
        apply = function(t)
            t.loop = { damage = 4 }
            t.fasten = {
                lands = Staple,
                radius = 7, damage = 6, freeze = 2, life = 2,
                crit = { chance = 1, mult = 3 },
                prise = true,
                sound = "stapler",
                -- The stapler's own flat price, per staple, charged at the release
                -- and refused rather than clamped (`Game:fastenEnds`) -- so a
                -- gesture the meter can only half afford lands the end you were
                -- holding and not the one you left behind.
                ink = 0.1,
                -- The STUB's two numbers and the STUB's reason (Game:wasTap): what
                -- decides is the finger's own travel and the length of the press,
                -- never the line, because a finger held still while the player walks
                -- lays real line in world space and would read as a drag. Under
                -- these the gesture was a tap and the press staple is the whole of
                -- it; over them there are two ends and a line between them.
                slack = 6, hold = 0.3,
            }
        end,
    }),

    -- **Three brushes fused with each other, which is the family without its
    -- pencil.** The six above answer every pair the pencil is in; these are the
    -- first three of the fifteen pairs left, and all fifteen are among the pen, the
    -- rubber, the marker, the gluestick, the stapler and the scissors.
    --
    -- What changes without a pencil in the pair is that the *body* of the mark stops
    -- being obvious, and src/tools.lua carries the argument: one parent's mark is
    -- the body and the other is what happens at it, and which is which is settled
    -- by asking whose mark is a **place**. A pen line is terrain and a marker band
    -- is a surface; a rub is an event that happens to whatever is under the tip and
    -- is nowhere at all once it is over. So the pen is the body of two of these and
    -- the marker of the third, and the rubber -- in both of the pairs it is in --
    -- is what the place does to whatever arrives at it, or, where it cannot be
    -- that, the other gesture entirely.
    --
    -- **Their catalysts are three different lines, and that is the one thing here
    -- the pencil's six do not do.** All six of those ask for a finished INKWELL,
    -- which reads as one sentence about the family -- these want a big well -- and
    -- it is the right sentence when the six differ in what they draw rather than in
    -- how they are paid for. These three differ in exactly that, so each asks for
    -- the ink line its own row is about: the fence that has to outlive the panic
    -- wants the FIXATIVE, the nib that charges by its own width wants the BLOTTER,
    -- and the row that spends one meter on two gestures wants the CARTRIDGE. It
    -- costs a run the same four levels either way, and it puts three different
    -- builds on the three cards.
    fusionLine("bumper", "BUMPER", "bumper", "BUMPER", {
        needs = { "pen", "rubber", "fixative" },
        fuses = { "pen", "rubber" },
        -- The FIXATIVE, because everything this row is worth is worth it for as long
        -- as the wall is up: it is the one line in the game that sells the *life* of
        -- a mark, and this mark is a fence that hits back.
        unlock = "THE FENCE THROWS BACK WHATEVER WALKS INTO IT",
        -- The pen's third level and the rubber's finale, both built here rather than
        -- written on the row for the HALO's reason: `scaleDamage` reaches
        -- `pop.damage` and `ram.damage` by name and Tools.copy is one level deep.
        --
        -- 4 along the whole line as it comes off the page and 5 to whatever a
        -- launched body runs into, and the second of those is where this tool's
        -- damage actually comes from -- the numbers on the row itself are chip.
        apply = function(t)
            t.pop = { damage = 4, reach = 6 }
            t.ram = { damage = 5 }
        end,
    }),

    -- The pen's second fusion in this family and the marker's first. Nine seconds of
    -- burning band, which is the pen's clock on the marker's mark -- and a nib whose
    -- weight follows your hand, which is the first choice the drawing has ever
    -- offered *inside* one stroke: heavy and dear where you meant it, thin and half
    -- price where you were only getting ink between yourself and something.
    fusionLine("swell", "SWELL", "swell", "SWELL", {
        needs = { "pen", "highlighter", "blotter" },
        fuses = { "pen", "highlighter" },
        -- The BLOTTER, because the row's own second axis is the price of a pixel:
        -- a tool that charges by how wide the nib happens to be is the one place in
        -- the game a flat discount on everything you draw is a *mechanic* and not
        -- only a saving.
        unlock = "A BURNING LINE, THICK WHEN YOU DRAW IT SLOWLY",
        -- The marker's finale, unnudged, built here for the BUMPER's reason --
        -- `scaleDamage` reaches `ignite.damage` by name.
        --
        -- **Two seconds of burn, exactly as the parent wrote it.** What lasts longer
        -- on this row is the *mark* -- the pen's nine seconds instead of the
        -- marker's three and a half -- and that is the whole of what the pen sells
        -- here. Stretching the burn as well would be a number invented rather than
        -- combined, and a burn is a body on fire rather than ink on paper: it is the
        -- one duration the fixative deliberately does not sell either (see
        -- `scalePersistence` in src/loadout.lua).
        apply = function(t)
            t.ignite = { time = 2, tick = 0.4, damage = 2 }
        end,
    }),

    -- And the rubber's second, which is the STUB's shape on the other pair it fits:
    -- swipe and it is the whole finished marker, tap and it is the whole finished
    -- rubber. Nothing is taken off either parent, because the two of them are never
    -- doing anything at the same moment -- what pays for it is one meter under two
    -- gestures, and the band is the dearest ink in the catalogue.
    fusionLine("scuff", "SCUFF", "scuff", "SCUFF", {
        needs = { "rubber", "highlighter", "cartridge" },
        fuses = { "rubber", "highlighter" },
        -- The CARTRIDGE, and it is the line this row is most obviously about: the
        -- delay before the meter starts refilling is exactly what you feel dabbing
        -- at the page with a tapped tool, and this is a tapped tool that has just
        -- spent its well on a band.
        unlock = "SWIPE TO BURN THEM, TAP TO SHOVE THEM OFF IT",
        -- The marker's finale and the whole of the finished rubber folded into one
        -- press, both built here for the BUMPER's reason: `scaleDamage` reaches
        -- `ignite.damage`, `tap.damage` and `tap.ram.damage` by name.
        --
        -- The tap is the STUB's, to the number, and it is written out again rather
        -- than shared because that is precisely what Tools.copy being one level deep
        -- forbids -- a table two rows point at is a table the sharpener multiplies
        -- twice. It is the same parent finished, so it is the same rub: a 7px circle
        -- at the point the finger landed on, 240 of shove out of it, 2 of chip, and
        -- what it launches knocking down what it hits. `slack` and `hold` are the
        -- finger's own travel and the length of the press (Game:wasTap), never the
        -- line -- a finger held still while the player walks lays real world line
        -- and would otherwise read as a drag, which is exactly the moment a panic
        -- tap is made.
        apply = function(t)
            t.ignite = { time = 2, tick = 0.4, damage = 2 }
            t.tap = {
                radius = 7, damage = 2, knock = 240,
                ram = { damage = 5 },
                ink = 0.12,
                slack = 6, hold = 0.3,
            }
        end,
    }),

    -- **The gluestick's three, which finish the brushes.** Six pairs of brushes
    -- exist and all six now have a row; every pair still missing is a brush with a
    -- nib-less block. They are also the body rule tested where it is hardest, since
    -- one of the three parents it beats is the *pen* -- a fence and a smear are both
    -- places, so what settles it is that paste is the stronger place: a fence says
    -- where a body may not stand, and paste says where a body is standing and will go
    -- on standing. So the mark is the smear in all three, and the second parent turns
    -- into a property of it. See src/tools.lua for the long version.
    --
    -- Their catalysts repeat ones already used, which is allowed and worth saying
    -- once: a catalyst is a condition and is never consumed, so two fusions may ask
    -- for the same line -- all six of the pencil's ask for the INKWELL. What a
    -- catalyst is for is aiming the card at a *build*, and these three are aimed at
    -- the three the gluestick actually has.
    fusionLine("pastedown", "PASTEDOWN", "pastedown", "PASTEDOWN", {
        needs = { "pen", "gluestick", "inkwell" },
        fuses = { "pen", "gluestick" },
        -- The INKWELL, and of every row in the book this is the one that most plainly
        -- needs it: 41 pixels of paste at the dearest ink in the catalogue, and a
        -- wall is only worth drawing if it is long enough to enclose something. The
        -- well is the whole difference between a bar of paste and a prison.
        unlock = "A WALL OF PASTE. NOTHING IN, NOTHING OUT",
        -- The pen's third level, and the only thing on this row an unlock has to
        -- build: `scaleDamage` reaches `pop.damage` by name and Tools.copy is one
        -- level deep. Everything else the two parents finished with is written on the
        -- row, including the gluestick's `soften`, `tear` and `pull` -- safe there
        -- for the MOAT's reasons.
        apply = function(t)
            t.pop = { damage = 4, reach = 6 }
        end,
    }),

    -- The CLEARING read backwards: there the rubber is on a compass and everything
    -- inside the swept disc is thrown straight out of it, here everything near the
    -- paste is hauled into it and stuck. One row empties a place and the other fills
    -- one. What made it interesting to write is that the reversal could not be a
    -- shove -- `Stroke:apply` knocks and then freezes in the same call, and a frozen
    -- body drops its push -- so the rubber's 240 had to become a *haul*, which is a
    -- field the gluestick already had. The row's own comment has the arithmetic.
    fusionLine("pulp", "PULP", "pulp", "PULP", {
        needs = { "rubber", "gluestick", "cartridge" },
        fuses = { "rubber", "gluestick" },
        -- The CARTRIDGE. This is the row you never want to lift your finger off --
        -- the haul only exists where the paste is, and the scrub discount dies with
        -- the stroke -- so what it wants is ink coming back while you are still
        -- working, and the price axis is already bought: `scrub` is on the row.
        unlock = "THE SMEAR HAULS THEM IN AND HOLDS THEM THERE",
        -- No `apply`, the MOAT's case: every table on the row is read and never
        -- written, and the one field the sharpener would have reached -- the rubber's
        -- `ram` -- is deliberately absent (see the row).
    }),

    -- And the gluestick with the marker, which is the shortest trade in the family:
    -- the glue is the strongest crowd control in the game and deals nothing on
    -- purpose, three of its four levels are written so the damage comes from
    -- somewhere else, and this row is the somewhere else.
    fusionLine("mordant", "MORDANT", "mordant", "MORDANT", {
        needs = { "highlighter", "gluestick", "fixative" },
        fuses = { "highlighter", "gluestick" },
        -- The FIXATIVE, the one line that sells how long a mark goes on working. It
        -- is the only catalyst that buys both halves of this row at once -- a longer
        -- hold and more ticks landing on what is held -- and it is the honest ask,
        -- because everything this tool is worth is worth it per second the paste is
        -- on the page.
        unlock = "THE PASTE BURNS EVERYTHING IT HAS STUCK",
        -- No `apply`, for the PULP's reason and one more: the marker's `ignite` is
        -- deliberately not on this row, so the one table the sharpener would have had
        -- to be handed fresh does not exist here.
    }),

    -- **The stapler's four, and the first rows in this family whose gesture is not
    -- a stroke.** Twelve of the fifteen pencil-less pairs are a line you drag; the
    -- nine left were all a brush with a *block*, which is a wall the family had to
    -- hit -- you cannot make the stroke the carrier when one parent has no stroke.
    --
    -- What gets borrowed instead is the one block gesture that *is* a drag: `rake`
    -- lays a staple every twelve pixels for as long as you hold, which is a path
    -- across the page at a fixed spacing and a stroke in everything but name. Two of
    -- these hang a mark off it and the third puts paste on the wire. (The fourth
    -- borrows nothing and gives the drag to the rubber -- see the SNAG.) It is the
    -- pushpin's threading family with one number changed -- at the pin's reach of 120
    -- a handful of taps is a *shape you build*, at the stapler's 14 thirty presses are
    -- a *line you drag* -- so the STOCKADE and the CORDON are the shapes and the
    -- PALING and the WICK are the lines. `LINK` in src/tools.lua is the number.
    --
    -- **The PALING and the CLINCH ask for a finished SELLOTAPE -- the ninth and
    -- tenth rows to, and the last -- where the twelve above ask for an ink line**, and the switch back is the honest one rather than a
    -- lapse: the ink lines were right for rows priced by the *pixel*, and neither of
    -- these is. They are priced by the press, ten to a meter, exactly as their parent
    -- is -- 0.14 and 0.15 -- so a bigger well and a faster trickle are both answers to
    -- a question this row never asks, and the blotter cannot reach a flat price at all.
    -- What the tape pays a run for is time, and here that is the whole of its
    -- qualification: it is the one line with nothing to say about a press.
    --
    -- The WICK is the exception among the three and it asks the FIXATIVE, for the
    -- HEM's reason: it is the only one of them that hangs a *clock* off the wire --
    -- a marker's burning band at `life` 3.6 over staples at `life` 2, both of them
    -- numbers `scalePersistence` walks.
    --
    -- RUBBER + STAPLER is the fourth and it is the SNAG, at the foot of them. It is
    -- the one row in the family that does not borrow `rake`, and the note in
    -- src/tools.lua has the long version: a seam of staples raked beside a rub is a
    -- shove undoing the fastening next to it, so the seam was the wrong carrier and
    -- the answer was the STUB's -- a gesture each. Which is also why it is priced
    -- by the pixel where the other three are priced by the press, and so one of the
    -- two in the family that does not ask for the tape.
    fusionLine("paling", "PALING", "paling", "PALING", {
        needs = { "pen", "stapler", "tape" },
        fuses = { "pen", "stapler" },
        unlock = "A FENCE STRUNG FROM STAPLE TO STAPLE",
        -- The pen's third level, and the only thing on this row an unlock has to
        -- build: `scaleDamage` reaches `pop.damage` by name and Tools.copy is one
        -- level deep. The `keep` above it is deliberately not here -- `thread` holds
        -- every rail for as long as both its staples stand, which is the STOCKADE's
        -- argument unchanged (see the row).
        apply = function(t)
            t.pop = { damage = 4, reach = 6 }
        end,
    }),

    -- The CORDON at the other end of the same field: there a strip of burning band
    -- between two pins you placed, here a continuous one you drag, pinned to the
    -- paper every twelve pixels. A wick is a cord that burns along its length and is
    -- held in place while it does, which is the row in one word -- and being held is
    -- exactly what the marker's band has always been short of.
    fusionLine("wick", "WICK", "wick", "WICK", {
        needs = { "highlighter", "stapler", "fixative" },
        fuses = { "highlighter", "stapler" },
        unlock = "A BURNING LINE STRUNG FROM STAPLE TO STAPLE",
        -- The marker's finale, built here for the CORDON's reason: `scaleDamage`
        -- reaches `ignite.damage` by name.
        apply = function(t)
            t.ignite = { time = 2, tick = 0.4, damage = 2 }
        end,
    }),

    -- And the gluestick's contract moved onto a fastener. A smear holds what stands
    -- in it for as long as it is on the paper because the freeze is re-applied every
    -- tick; a staple has never worked that way. `tacky` is that difference and
    -- nothing else -- the circle is swept every four tenths of a second and anything
    -- in it is stuck to the wire again -- which turns a fastening you aimed at one
    -- body into a spot on the page that fastens whatever crosses it. What collects
    -- five seconds of that is the stapler's own third level: `prise` tears the wire
    -- back out and bites everything still standing where it was stuck.
    fusionLine("clinch", "CLINCH", "clinch", "CLINCH", {
        needs = { "gluestick", "stapler", "tape" },
        fuses = { "gluestick", "stapler" },
        unlock = "STAPLES THAT STAY, AND HOLD WHATEVER CROSSES THEM",
        -- No `apply`, the MOAT's case: the whole block is written on the row, the
        -- sharpener finds `drop.damage` on the run's own copy of it (Tools.copy lifts
        -- every block), `crit.mult` is stepped over by name, and `soften` and `tacky`
        -- are read by nobody who writes.
    }),

    -- And the fourth, which finishes the stapler and is the fourth row in the game
    -- that is a different tool depending on whether your finger moves. Tap and a
    -- staple lands; drag and it is the whole finished rubber -- and the rub takes
    -- every staple it crosses back out of the paper, early, biting on the way with
    -- the crit certain rather than rolled. Two gestures, one meter, and a loop
    -- between them: fasten the front of the crowd down, then sweep across it and
    -- collect. src/tools.lua has the argument.
    fusionLine("snag", "SNAG", "snag", "SNAG", {
        needs = { "rubber", "stapler", "inkwell" },
        fuses = { "rubber", "stapler" },
        -- **The INKWELL, and it is the one of the four ink lines this row can
        -- actually be aimed at.** The unit of play here is not a gesture, it is a
        -- *chain* of them -- some staples and then the rub that collects them -- and
        -- the chain has to fit inside one well or it does not happen: the hold is two
        -- seconds and the meter does not come back inside two seconds. Capacity is
        -- exactly that, and nothing else on the list is.
        --
        -- The cartridge would only get you to the next chain sooner, which is a
        -- different sentence. The blotter is the one that *looks* right on a row
        -- charged by the press and by the pixel at once, and it is the one that
        -- cannot be: `scaleCost` discounts the row's `ink` and a staple's price is
        -- `fasten.ink`, one level in, which it does not reach -- the STITCH's staples
        -- are undiscounted for the same reason. And the fixative is the line this row
        -- wants most of all, since it stretches the hold (`scalePersistence` reaches
        -- `fasten.freeze`) and the hold is the window you have to get the rub back
        -- across -- which is precisely why it is not the ask, the CLINCH's rule: a
        -- catalyst that is the line the row cannot play without is a tax and not a
        -- choice.
        unlock = "TAP TO STAPLE THEM, SWIPE TO RIP IT BACK OUT",
        -- The rubber's finale and the whole finished stapler, both built here for the
        -- BUMPER's reason -- `scaleDamage` reaches `ram.damage` and `fasten.damage`
        -- by name, `scalePersistence` reaches `fasten.freeze` and `fasten.life`, and
        -- Tools.copy is one level deep, so a `fasten` written on the shared row would
        -- be scaled once per rebuild for ever.
        --
        -- The staple is the parent's, to the number, and the crit stays at the
        -- parent's one in five rather than going to the STITCH's certainty. **That
        -- difference is the sample and not a nudge.** The STITCH's staples come two to
        -- a drawn line, so a fifth there is a story about one staple; these come one
        -- to a *tap*, which is the stapler's own gesture at the stapler's own price --
        -- ten a meter, dozens a page -- so the fifth is a rate again, honest for the
        -- reason the parent's row says it is. What this row makes certain is the other
        -- bite, the one the rub goes and gets (`snag` on the row, `Staple:snag`),
        -- because that one is not luck: it is a staple placed, a hold spent getting
        -- back to it, and a second gesture paid for out of the same well.
        --
        -- `tapped` is what makes a drop and a brush share a row at all: the staple is
        -- the tap and nothing goes in at the press. See `fasten` in src/tools.lua and
        -- Game:fastenEnds.
        apply = function(t)
            t.ram = { damage = 5 }
            t.fasten = {
                lands = Staple,
                radius = 7, damage = 6, freeze = 2, life = 2,
                crit = { chance = 0.2, mult = 3 },
                prise = true,
                sound = "stapler",
                tapped = true,
                -- The stapler's own flat price per staple, charged at the release and
                -- refused rather than clamped (`Game:fastenEnds`), and `slack` and
                -- `hold` are the STUB's two numbers doing the STUB's job: what
                -- decides is the finger's own travel and the length of the press,
                -- never the line, because a finger held still while the player walks
                -- lays real line in world space and would read as a drag.
                ink = 0.1,
                slack = 6, hold = 0.3,
            }
        end,
    }),

    -- The forty-first and the last pair in the catalogue: SCISSORS and STAPLER,
    -- which finishes the scissors' nine and with them every pair of tools in the
    -- game.
    --
    -- **It is the only one of the five off the scissors that keeps their gesture.**
    -- The other four all hand the cut to something else -- two pins cast it, a
    -- ruler lands it, a compass rings it, a hand draws round it -- and this one
    -- still tapped twice. What changes is what the taps leave behind: a staple in
    -- the paper at each of them, and the stretch between filled with more at the
    -- stapler's own twelve-pixel spacing, so the line is stitched to the page
    -- before the blades come down it.
    --
    -- Which is the parent's one real weakness answered from the other end to the
    -- TEAR LINE's. A cut is two taps with a gap between them and the horde keeps
    -- walking through the gap; the TEAR LINE made the first tap a crater, and this
    -- makes the line *hold*. A stapler is the tool that stops things moving and the
    -- scissors are the tool that needs things to stand still.
    --
    -- src/tools.lua has the rest, including the two things this row is the only one
    -- in the game to do: charge a price on the scissors' first tap, and inherit
    -- `sever` without having to re-read it.
    fusionLine("hinge", "HINGE", "hinge", "HINGE", {
        needs = { "scissors", "stapler", "topmarks" },
        fuses = { "scissors", "stapler" },
        -- TOP MARKS, and it is the last of the three rows that ask for it -- the
        -- PUNCH, the GUILLOTINE and this one, the three whose signature is a cut.
        -- What a cut takes off the page is not killed: `Game:liftEnemyTo` credits
        -- no gem, no xp and no kill on the tally, so a run that answers every
        -- crowd by opening the paper under it is a run whose levelling has stopped
        -- while the difficulty clock has not. Top marks is the one line that
        -- answers that, and it is a condition and not a tax -- the staples still
        -- land, still bite 6 and still crit, so this row earns on the half of it
        -- that is a stapler.
        --
        -- The ink lines were the obvious asks and both are wrong here for the
        -- same reason the PALING gives: both halves of this row are priced by the
        -- press -- 0.45 a tap, ten staples to a meter on the parent -- so a
        -- discount by the pixel cannot reach it and a bigger well answers a
        -- question it never asks.
        --
        -- The well is the line this row wants most, since 0.9 for the gesture is
        -- very nearly the whole meter and a fuller one is a second tap that does
        -- not have to wait -- which is exactly why it is not the ask (the CLINCH's
        -- rule): a catalyst that is the line a row cannot play without is a tax
        -- rather than a choice, and a full meter already covers both taps with a
        -- tenth to spare.
        unlock = "IT STAPLES THE LINE, THEN CUTS THE PAGE ALONG IT",
        -- Both tables built here rather than written on the row, the HALO's reason
        -- twice over: `scaleDamage` walks `Tools.BLOCKS` and reaches
        -- `cut.blades.damage` and `cut.wire.damage` by name, `scalePersistence`
        -- reaches `cut.wire.freeze` and `cut.wire.life`, and `Tools.copy` copies the
        -- row and its blocks one level deep -- so either table shared on the row
        -- would compound its multiplier on every rebuild.
        --
        -- Every number in both is a parent's finished one. `blades` is the scissors'
        -- second level to the digit (20 across 6 between the taps), and the wire is
        -- the stapler at its four -- 6 a press, one in five straight through at 18,
        -- torn back out two seconds later for a second 6, and the seam's own 12px
        -- spacing. It is the SEAM's block, field for field, which is the point: the
        -- fusion is one tool's line read against another tool's, and there was
        -- nothing here to balance.
        --
        -- `sound` is named on the block for Game:driveDrop's reason -- what arrives
        -- there is a block and not a tool, so a row called HINGE would otherwise
        -- staple in silence.
        apply = function(t)
            t.cut.blades = { damage = 20, width = 6 }
            t.cut.wire = {
                lands = Staple,
                radius = 7, damage = 6, freeze = 2, life = 2,
                crit = { chance = 0.2, mult = 3 },
                prise = true,
                rake = { every = 12 },
                sound = "stapler",
            }
        end,
    }),

    -- **And the last four are the scissors against the four brushes**, which were the
    -- catalogue's last hole and are one idea between them: what carries a cut when
    -- there is no ring to close it with is the mark's own *two ends*. You drag, the
    -- ink goes down, and the page comes apart along the straight line between where
    -- you pressed and where you stopped (`chord` in src/tools.lua, `trimsTheLine`
    -- above, `Game:chordCut`). The CUTOUT could ring what it cut because a pencil
    -- closes rings and the other four brushes do not; a line has ends whether or not
    -- it comes back to itself.
    --
    -- Three of the four are written. What each pairing then argues about is what the
    -- ink does with the cut, and no two of them answer the same way: paste holds the
    -- crowd on the line and travels with the paper, a marker band lights what the
    -- blades touch, and a rub -- which is nowhere at all once it is over, so it has no
    -- ends to cut between -- keeps the parent's taps and hands the drag the one thing
    -- a blade will not do, which is shove.

    -- The forty-second. GLUESTICK and SCISSORS: cut and paste, and the name is the
    -- mechanic. The smear pulls the crowd onto the line and holds it there, the
    -- blades come down the middle of it at 20, and the half that goes takes them to
    -- the far corner *stuck*. src/tools.lua has the argument.
    fusionLine("collage", "COLLAGE", "collage", "COLLAGE", {
        needs = { "gluestick", "scissors", "inkwell" },
        fuses = { "gluestick", "scissors" },
        -- The INKWELL, the twelve stroke rows' ask: this one is priced by the pixel
        -- like every brush -- 1/90, the dearest ink in the game -- and the meter is
        -- the only thing between a smear and the whole page. The cut on top of it is
        -- a flat 0.3, so a gesture that draws a long smear *and* opens the page is
        -- the one thing on the strip that can empty a full well in one motion, and
        -- capacity is exactly what answers that.
        unlock = "THEY GO WITH THE HALF YOU CUT, AND STAY STUCK",
        -- Four seconds of paste on the far side of the cut, which is the gluestick's
        -- own finished hold said in the pushpin's number rather than in the smear's:
        -- 0.55 is what standing *in* paste is worth, re-applied every tick for as
        -- long as you stand there, and this is a single dose handed to a body that
        -- has just been put down somewhere else. The pin's four seconds is the
        -- game's number for one dose of "not going anywhere", so it is the number
        -- here -- and the fixative stretches it (`scalePersistence`), because a hold
        -- is a hold wherever the body is standing.
        apply = function(t) trimsTheLine(t, { paste = 4 }) end,
    }),

    -- The forty-third. MARKER and SCISSORS: the band is the mark and the blades set
    -- fire to what they cut, so everything the offcut then carries to the corner
    -- arrives burning and burns the whole way back. The row is the one that could
    -- not have been written while a severed region still despawned -- fire needs
    -- seconds and a despawn is the end of them.
    fusionLine("scorch", "SCORCH", "scorch", "SCORCH", {
        needs = { "highlighter", "scissors", "cartridge" },
        fuses = { "highlighter", "scissors" },
        -- The CARTRIDGE rather than the well, and it is the one row of the four
        -- where the two ink lines actually say different things. A band is cheap
        -- (1/120) and the cut is 0.3, so what this run out of is not capacity, it is
        -- the *pause*: the burn is two seconds and the cut is what delivers it, so
        -- the tool wants to be ready again before the last crowd has finished
        -- burning. A bigger well would buy a longer band, which is not what a row
        -- whose payload is a clock is asking for.
        unlock = "THE BLADES LEAVE THEM BURNING AS THEY GO",
        -- The marker's finale, and **the same table on both ends**: the burn the band
        -- sets and the burn the blades set are one block, so `scaleDamage` scales
        -- `ignite.damage` once through the row and the chord reads what it wrote. Two
        -- copies would be two numbers drifting apart with every sharpener a run
        -- takes, for a difference nobody could see on the page.
        apply = function(t)
            t.ignite = { time = 2, tick = 0.4, damage = 2 }
            trimsTheLine(t, { ignite = t.ignite })
        end,
    }),

    -- The forty-fourth. RUBBER and SCISSORS, and the only one of the four that
    -- cannot give the cut to its own line: a rub is an event that is nowhere once it
    -- is over. So it keeps the parent's two taps and gives the drag to the rubber --
    -- tap twice and the page comes apart, sweep and 240 of shove drives the crowd
    -- over the slit, where the missing paper puts them in the far corner. The fifth
    -- row in the game that is a different tool depending on whether your finger
    -- moves.
    fusionLine("shear", "SHEAR", "shear", "SHEAR", {
        needs = { "rubber", "scissors", "inkwell" },
        fuses = { "rubber", "scissors" },
        -- The INKWELL, the SNAG's argument arrived at from the other side: the unit
        -- of play here is a *chain* of gestures rather than one -- a cut, and then
        -- the rub that drives them over it -- and the chain has to fit inside one
        -- well or it does not happen, because the slit closes in a second and a half
        -- and the meter does not come back inside that. The cartridge would only get
        -- you to the next chain sooner, which is the wrong sentence for a tool whose
        -- two halves have to happen together.
        unlock = "TAP TO CUT THE PAGE, SWIPE THEM OVER THE EDGE",
        -- The rubber's finale and the scissors' whole line, both built here for the
        -- SNAG's reason -- `scaleDamage` reaches `ram.damage` and the chord's own
        -- numbers by name, and `Tools.copy` lifts neither.
        --
        -- `tapped` is what makes the two gestures share a row, and it is the same
        -- field the SNAG writes with the same meaning: the cut happens *because* the
        -- finger never went anywhere. `lean` is the level this row does not get and
        -- src/tools.lua says why -- on a row where the press is a tap that anchors a
        -- cut, a tip that hits where it rests would shove the crowd off the line in
        -- the gap between the two taps.
        apply = function(t)
            t.ram = { damage = 5 }
            trimsTheLine(t, { tapped = true })
        end,
    }),

    -- The forty-fifth, the last pair the ten tool lines can make, and the only row
    -- in the game where the mark *is* the region: PEN and SCISSORS.
    --
    -- The line you draw is a line the horde cannot cross. Anything that touches it
    -- is lifted off the page and put down in the corner furthest from you, for as
    -- long as the line is there -- and the pen's last level means that is until you
    -- draw the next one. **It is the scissors' finale with a line for a shape**, the
    -- fourth after the half-plane, the disc and the ring, and the first that is not
    -- an area.
    --
    -- What it cost the pen is the wall, and src/tools.lua argues that at length: a
    -- wall is a line the crowd steers *around*, so walling and lifting at once would
    -- be a row whose two halves cancelled. Without it the line is a tripwire rather
    -- than a fence, which is the stronger of the two and the honest trade for a
    -- level given up.
    fusionLine("deadline", "DEADLINE", "deadline", "DEADLINE", {
        needs = { "pen", "scissors", "blotter" },
        fuses = { "pen", "scissors" },
        -- The BLOTTER, and it is the one of the four ink lines this row can be aimed
        -- at rather than the one it wants most. What a deadline costs is **length**:
        -- 1/170 a pixel with nothing else to pay -- there is no press in the gesture
        -- at all, the cut being the mark rather than a thing cast off it -- so the
        -- only question the meter ever asks this tool is how much page one line can
        -- reach across, and a discount per pixel is that question answered.
        --
        -- The well would buy the same thing once (the SWELL's argument, one family
        -- over) where the blotter buys it every time; the cartridge buys the *next*
        -- line sooner, which on a row that keeps the last one is the least useful
        -- thing on the list. And the fixative is the line this row wants most of all
        -- -- it stretches a mark's life -- which is exactly why it is not the ask,
        -- the CLINCH's rule: a catalyst that is the line a row cannot play without is
        -- a tax rather than a choice. `keep` already makes the line permanent, so the
        -- fixative is a luxury here rather than the price of entry.
        unlock = "NOTHING CROSSES THE LINE, AND IT STAYS DRAWN",
        -- The pen's third level, built here for the HALO's reason: `scaleDamage`
        -- reaches `pop.damage` by name and `Tools.copy` is one level deep. `lift` is
        -- on the row instead, having no damage in it for the sharpener to find -- the
        -- PUNCH's rule, one shape thinner.
        apply = function(t) t.pop = { damage = 4, reach = 6 } end,
    }),

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
        -- that the sharpener and the blotter between them still cannot touch.
        --
        -- It is worth the most to the tools that do no damage at all: the pen
        -- wall you drew in a panic outlives the panic by twice as much, and the
        -- gluestick's smear holds what it caught for twice as long. See
        -- `scalePersistence` in src/loadout.lua for exactly which numbers move --
        -- a ruled line the ruler leaves behind is not one of them, because it has
        -- already done everything it is going to do.
        --
        -- It stops at the nib, and the laminate below is the same question asked
        -- of what fights for you. Two lines rather than one wider one, for the
        -- reason the two damage lines are two: see `passiveLife` above.
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
        -- The fixative's other half, and the reason the two are separate lines is
        -- the reason the sharpener and the graphite are: a run that draws for a
        -- living and a run that stands still and lets the page fight for it are
        -- two builds, and one card worth taking to both is a card neither of them
        -- had to choose.
        --
        -- What it points at is short and will stay short, which is the honest
        -- thing about this line rather than a gap in it. Ten of the twelve weapons
        -- *happen* and are over -- a rocket goes up, a bolt comes down, a swing
        -- takes the arc it takes -- and a duration is only a thing you can buy
        -- from the two that leave something lying there: the spiral, which does no
        -- damage at all and is a hold and nothing else, and the skate, whose trail
        -- *is* the weapon. So this is a line with two customers, and it is worth
        -- carrying next to the fixative for the same reason the graphite is worth
        -- carrying next to the sharpener: what it is worth is a fact about the
        -- build and not about the card.
        --
        -- The steps are the fixative's, to the decimal. Two halves of one axis
        -- that climbed at different rates would be a run reading the same
        -- sentence twice and getting two different numbers out of it -- which is
        -- exactly what the two damage lines refuse to do, and they share `RISING`
        -- to make sure of it.
        --
        -- A burn is not a hold and this does not buy one. A crater that goes on
        -- burning, a sun that stays up: those are hits still landing, so they
        -- belong to the graphite. Everything this does *not* stretch is listed
        -- with the pass that spends it (`scaleWeaponPersistence` in
        -- src/loadout.lua), and the rule the list is written on is one line long
        -- -- a hold lengthens, a burn does not.
        id = "laminate",
        name = "LAMINATE",
        icon = "laminate",
        kind = "passive",
        levels = {
            { text = "WHAT FIGHTS FOR YOU LASTS LONGER AND HOLDS LONGER",
              apply = function(s) s.passiveLife = s.passiveLife * 1.2 end },
            { text = "LONGER AGAIN",
              apply = function(s) s.passiveLife = s.passiveLife * 1.2 end },
            { text = "LONGER AGAIN",
              apply = function(s) s.passiveLife = s.passiveLife * 1.2 end },
            { text = "SEALED IN AND NOTHING WEARS IT OFF",
              apply = function(s) s.passiveLife = s.passiveLife * 1.25 end },
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
    {
        -- The other half of the sellotape, and the two are worth carrying
        -- together rather than being the same level twice: the tape mends you for
        -- being alive and this mends you for what is being done to the crowd. So
        -- one pays a run for walking away and this pays it for standing in the
        -- middle, which is the first thing in the catalogue that rewards the
        -- position the whole game is about.
        --
        -- It is a fraction of the damage the run's *own weapons* dealt and
        -- deliberately not of what you draw. Two reasons and they point the same
        -- way. Ink already has a meter and a cost -- the trade for a stroke is
        -- paid at the nib, and healing for drawing would be an ink bar that
        -- filled a health bar. And a weapon fights while your hands are busy, so
        -- what this actually buys is the thing no other passive sells: a reason
        -- to keep drawing while the page kills for you.
        --
        -- Which is why a run carrying nothing that fights for it gets nothing at
        -- all out of this card, and that is allowed. Every run arrives holding a
        -- weapon (`weapon` in src/characters.lua), so there is no run this is dead
        -- on -- only runs it is worth very little to, which are the runs that
        -- drafted tools and drew for a living.
        --
        -- The numbers are small and the ceiling in src/loadout.lua is smaller.
        -- Against a run putting a couple of hundred points a second into a crowd
        -- the full line is a few points of health a second, which is the
        -- sellotape's own top level and change -- and the cap is what stops an
        -- exceptional build turning that into a health bar that cannot be moved.
        id = "bandaid",
        name = "BANDAID",
        icon = "bandaid",
        kind = "passive",
        levels = {
            { text = "WHAT FIGHTS FOR YOU PATCHES YOU UP AS IT CUTS",
              apply = function(s) s.mend = s.mend + 0.006 end },
            { text = "MORE COMES BACK",
              apply = function(s) s.mend = s.mend + 0.005 end },
            { text = "MORE AGAIN",
              apply = function(s) s.mend = s.mend + 0.005 end },
            { text = "EVERY CUT THEY DEAL CLOSES ONE OF YOURS",
              apply = function(s) s.mend = s.mend + 0.008 end },
        },
    },
}

-- The lines that never finish.
--
-- Everything above has a bottom to it: so many levels, taken in order, and then
-- the draft stops offering that line. Between that and the four-slot caps a run
-- has exactly 59 picks in it, and it now reaches the last of them with the horde
-- still arriving -- which used to mean every level after that was swallowed in
-- silence, `Game:openDraft` returning false and the run carrying on unasked.
--
-- These are what it is asked instead. One of them is small on purpose -- a few
-- percent, the size of number the catalogue *opens* a line with rather than the
-- one it ends on -- and there is no last one: the draft goes on offering them
-- for as long as the run goes on living. What a run buys past the catalogue is
-- not a new thing to do, it is more of what it already does, and saying that in
-- the size of the numbers is the honest way to say it.
--
-- They are kept out of `Upgrades.list` deliberately, and that is the whole of
-- how they stay out of the way. A line in that table is a candidate from the
-- first draft onwards, and three percent of nothing offered against a weapon on
-- level three would be a wasted card; `Loadout:roll` reaches for these only once
-- it has run out of real ones, which is exactly when they are worth anything.
--
-- The icons are the passive lines' own, reused rather than drawn again. An
-- endless line is not a new idea, it is an old one that refuses to stop, so the
-- icon saying which axis it pushes is the right thing for it to say -- and by
-- the time these come up the line each icon was borrowed from is finished and
-- out of the pool, so the two are almost never on a page together.
--
-- `forever(n)` is both the flag that says a line has no bottom and the thing
-- that builds the level it is asked for. It hands back the same { text, apply }
-- an authored level is written as, so nothing downstream has to know which shape
-- of line it is holding -- see `Upgrades.levelAt`.
local function endlessLine(id, name, icon, first, again, apply)
    return {
        id = id, name = name, icon = icon,
        kind = "endless",
        forever = function(n)
            return { text = n == 1 and first or again, apply = apply }
        end,
    }
end

-- Eight of them rather than one, because the draft lays down three cards and
-- three cards should still be a choice. One endless line offering the same thing
-- three times over would be a level-up you press through rather than answer,
-- which is the one thing every screen in this game is built not to be.
--
-- Eight covers twelve of the fifteen passive lines. Three of the numbers the
-- rest are made of are left out on a rule rather than by omission: **nothing
-- endless may multiply a number downwards.** The blotter's ink cost, the
-- cartridge's delay and the metronome's gap are those three, and a few percent
-- off any of them, taken for ever, converges on free ink that comes back
-- instantly and a page where everything fires every frame -- which is not an
-- upgrade to the meter or to the clock, it is neither of them being in the game.
-- The drawing half of this game is built on paying for what you put on the page
-- and the fighting half on waiting for the next beat, and an endless line is the
-- last place either should be quietly bought out. (The bandaid is the one line
-- with no endless answer for no reason at all: `mend` is an addition on a number
-- with no bad limit, so one could be written and simply has not been.)
--
-- Everything below is therefore additive, or a multiplier heading *up* from a
-- number with no bad limit, and there is no exception. There used to be one --
-- an endless fire rate, floored at four times the rate a run opens on, a floor
-- being the only honest way to write a downward line with no last level and an
-- admission that it should not have been one. The metronome above is that axis
-- back in the catalogue, where a line has a last level and 0.88 four times is a
-- number you can write down; it is deliberately not back out here.
Upgrades.endless = {
    endlessLine("morelead", "PRESS HARDER", "sharpener",
        "EVERYTHING YOU DO CUTS DEEPER",
        "DEEPER AGAIN. THERE IS NO LAST ONE",
        function(s) s.damage = s.damage * 1.06 end),
    endlessLine("morepage", "MORE PAGE", "page",
        "+15 MAX HEALTH AND +15 BACK NOW",
        "+15 MORE, AND +15 BACK NOW",
        function(s) s.maxHp = s.maxHp + 15 end),
    endlessLine("morespeed", "FASTER STILL", "plane",
        "YOU MOVE FASTER",
        "FASTER AGAIN. THERE IS NO LAST ONE",
        function(s) s.speed = s.speed * 1.03 end),
    -- The two halves of the gem in one card, the way the magnet and top marks
    -- lines split them: past the catalogue there is nothing left to spend a
    -- level on separately, so what is left is simply more xp, sooner.
    endlessLine("moresweep", "SWEEP UP", "magnet",
        "XP COMES FROM FURTHER AND IS WORTH MORE",
        "FURTHER AND MORE AGAIN",
        function(s)
            s.magnet = s.magnet + 12
            s.xpGain = s.xpGain * 1.04
        end),
    endlessLine("moreink", "TOP UP", "cartridge",
        "A DEEPER WELL THAT FILLS FASTER",
        "DEEPER AND FASTER AGAIN",
        function(s)
            s.inkMax = s.inkMax + 0.1
            s.inkRegen = s.inkRegen * 1.08
        end),
    -- The one number here that is watched rather than just stacked. The
    -- sellotape line's own warning stands and applies harder to something with
    -- no last level: a heal that outruns what is hitting you ends the run's
    -- difficulty rather than easing it. 0.25 is a quarter of what the tape's
    -- first level gives, so several of these are needed to match one real card
    -- -- which is the rate at which it stays sustain rather than immunity.
    endlessLine("moremend", "PATCH UP", "tape",
        "YOU MEND A LITTLE FASTER",
        "A LITTLE FASTER AGAIN",
        function(s) s.regen = s.regen + 0.25 end),
    -- The fixative's axis, written as an addition where the catalogue line it
    -- answers is written as a multiplication. That is the difference between a
    -- line with four levels and one with none: x1.2 four times is 2.16 and
    -- stops, while x1.2 for ever is a mark that never leaves the page. Adding to
    -- the multiplier climbs in a straight line instead of a curve, so twenty of
    -- them is +1.2 rather than x38.
    --
    -- Both halves of the axis in one card, the way PRESS HARDER is both halves
    -- of the damage split: past the catalogue there is no longer anything to
    -- spend a level on separately, and the fixative and the laminate are the same
    -- sentence asked about either side of the page.
    endlessLine("morehold", "STAYS LONGER", "fixative",
        "EVERYTHING YOU LEAVE LASTS AND HOLDS LONGER",
        "LONGER AGAIN. THERE IS NO LAST ONE",
        function(s)
            s.markLife = s.markLife + 0.06
            s.passiveLife = s.passiveLife + 0.06
        end),
}

-- The nth level of a line, whichever shape the line is. An authored one has its
-- levels written out above; an endless one builds the level it is asked for.
-- That is the whole of the difference between them, and it lives here so that
-- nothing else has to care -- the replay in Loadout:rebuild, the text on a draft
-- card and the level counters all come through this one door.
function Upgrades.levelAt(up, n)
    if up.forever then return up.forever(n) end
    return up.levels[n]
end

-- How many levels a line has in it. An endless one answers with a number no run
-- reaches, which keeps "has it got one left" the same test for both shapes --
-- and quietly keeps MAX off a card that can never be at its last level, since
-- nothing is ever equal to infinity.
function Upgrades.levelsIn(up)
    return up.forever and math.huge or #up.levels
end

-- Every line a run can be carrying: the catalogue, and then the endless ones.
-- The order is load-bearing rather than tidy. Loadout:rebuild replays levels in
-- exactly this order, so an endless multiplier lands on top of everything the
-- catalogue did rather than underneath it -- which is the same rule the
-- whole-loadout multipliers follow and for the same reason.
function Upgrades.each(fn)
    for _, up in ipairs(Upgrades.list) do fn(up) end
    for _, up in ipairs(Upgrades.endless) do fn(up) end
end

Upgrades.byId = {}
Upgrades.each(function(up)
    Upgrades.byId[up.id] = up
end)

-- Which drawings in the game belong to a fusion, keyed by icon rather than by
-- line. Every screen that puts an icon on the page asks here whether the thing
-- it is drawing is a fused one, and puts a blush plate behind it if it is
-- (`Hud.drawIcon`) -- so a fused tool is marked out in the selector column, on
-- the shelf and in its own entry without any of those three being told what a
-- fusion is.
--
-- By icon because that is the only name for a line the selector column has: it
-- is handed a tool off the strip (src/tools.lua) rather than the upgrade row
-- that unlocked it, and a tool's icon is its name for itself everywhere else in
-- this game. It is also why nothing new is written on the rows: this is derived
-- off `fuses`, so a new fusion is marked out by existing.
Upgrades.fused = {}
Upgrades.each(function(up)
    if up.fuses then Upgrades.fused[up.icon] = true end
end)

return Upgrades
