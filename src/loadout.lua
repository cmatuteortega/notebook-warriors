-- What a run has learned.
--
-- One of these is built by Game:reset and thrown away with the run. It holds
-- the level a run has reached on every upgrade line (src/upgrades.lua) and
-- turns that into three things the rest of the game reads:
--
--   stats    every number about the player, from move speed to how far xp comes
--   tools    the run's *own copy* of Tools.list, with the upgrades applied
--   weapons  the passive weapons that fight for you, live
--
-- All three are rebuilt from scratch every time an upgrade is taken, by
-- replaying every level from the ground up. That costs nothing at the rate a
-- run levels up, and it buys two things worth far more than it: no level has to
-- undo anything, and a number that depends on the shape of the window comes out
-- right again when the window changes shape.
--
-- The tools are copies because Tools.list is shared by every run the program
-- plays and upgrades change the numbers in it. The weapons are *not* rebuilt:
-- an orbit that has been turning for two minutes keeps its angle when the
-- upgrade that speeds it up lands, and a rocket already in the air keeps the
-- numbers it was fired with.
--
-- One line can also take another *off* a run: a fusion (`needs` and `fuses` in
-- src/upgrades.lua) is only dealt once every line it is made of is finished, and
-- the lines it names in `fuses` stop reaching the strip and give their places
-- back the moment it lands. That is the only thing in the game that undoes a
-- pick, and it is written so that it does not: the fused lines keep their levels
-- and those levels are still replayed onto their tools, which simply stop being
-- handed out. Nothing here has to remember a fusion happened -- `Loadout:ready`
-- reads `needs` off the catalogue and `rebuild` works `fuses` out from the lines
-- taken -- which is what keeps a run restored from a bookmark, a list of levels
-- and nothing else, arriving in exactly the same state.

local Collection = require("src.collection")
local Tools = require("src.tools")
local Upgrades = require("src.upgrades")
local Shot = require("src.shot")
local Sword = require("src.sword")
local Orbital = require("src.orbital")
local Rocket = require("src.rocket")
local Sun = require("src.sun")
local CoolS = require("src.cools")
local Beam = require("src.beam")
local Bomb = require("src.bomb")
local Skate = require("src.skate")
local Storm = require("src.storm")
local Flock = require("src.flock")
local Spiral = require("src.spiral")

local Loadout = {}
Loadout.__index = Loadout

-- Passive weapons: the stat block an upgrade line puts on the run, and the
-- module that flies it. The block turning up is what brings the weapon in.
--
-- The first two are the hands-free attacks (src/shot.lua, src/sword.lua), and
-- they are first here for a reason that shows: this list is the order weapons are
-- drawn in (Loadout:drawWeapons), and the arm has to go down before the things
-- that float over the page do, exactly where Game:draw used to draw it by hand.
local WEAPONS = {
    { stat = "shot", module = Shot },
    { stat = "sword", module = Sword },
    { stat = "star", module = Orbital },
    -- Next to the stars, which is where it belongs in every sense: both are
    -- things attached to you rather than sent out from you, and both are drawn
    -- over the crowd because what they are doing is only legible against it.
    { stat = "birds", module = Flock },
    { stat = "rocket", module = Rocket },
    { stat = "sun", module = Sun },
    { stat = "cools", module = CoolS },
    { stat = "beam", module = Beam },
    { stat = "bomb", module = Bomb },
    { stat = "skate", module = Skate },
    -- Nothing of the spiral is drawn up with the weapons at all -- it is ink on
    -- the page and goes down in the ground pass -- so where it sits in this list
    -- only decides what it is drawn *over* down there: the bomb's burning crater
    -- and the skate's wax, which is the right way round. A line laid over a
    -- filled patch reads; a filled patch laid over a line eats it.
    { stat = "spiral", module = Spiral },
    -- Last, which is where the highest thing on the page belongs: a cloud is
    -- filled in paper and covers what it floats over, so it goes down after
    -- everything it is meant to be above.
    { stat = "storm", module = Storm },
}

-- A line the run is handed rather than offered: taken to level one before it has
-- been asked anything, spending a slot of its kind exactly as a drafted one does.
-- Nothing downstream can tell the difference, which is the whole of why it is
-- done this way -- there is no "this one was free" flag anywhere for a level, a
-- counter or the draft to have to know about.
local function issue(self, id)
    local up = id and Upgrades.byId[id]
    if not up then return end

    self.taken[up.id] = 1
    self.order[#self.order + 1] = up.id
end

function Loadout.new(vw, vh, startTool, startWeapon)
    local self = setmetatable({
        taken = {},      -- id -> level reached
        order = {},      -- ids, in the order they were first taken
        -- Lines this run has thrown out (EXPEL in the draft, src/perks.lua):
        -- id -> true, and the draft never offers one again. It is a set rather
        -- than a list because the only question ever asked of it is whether a
        -- given line is in it, and it lives here rather than on the run because
        -- what a run may be offered is exactly what this file already decides.
        banned = {},
        stats = {},
        tools = {},
        -- Lines a fusion has spent (`fuses` in src/upgrades.lua): id -> true.
        -- Derived in `rebuild` off the lines taken rather than recorded when one
        -- lands, for the reason every other thing here is: a run restored from a
        -- bookmark is a list of levels and nothing else, and anything that has to
        -- be remembered separately is one more thing that can come back wrong.
        fused = {},
        equipped = {},   -- the tools unlocked, in the order they were unlocked
        weapons = {},
        live = {},       -- stat name -> the weapon flying it, kept across rebuilds
        -- Health the bandaid has earned and not handed over yet (Loadout:mend).
        -- It survives a rebuild along with the weapons, since taking a level is
        -- not a reason to forget what the last one earned.
        owed = 0,
    }, Loadout)

    -- What a run is handed before it has been asked anything, and it is two
    -- lines: one tool and one weapon. A run does not start holding the strip or
    -- the sky -- it starts holding one of each, and every other slot is empty
    -- until the draft fills it.
    --
    -- The tool comes from the lesson (`tool` in src/subjects.lua) and the weapon
    -- from the character (`weapon` in src/characters.lua), and both arrive as
    -- line ids rather than as things, because that is what being handed one *is*:
    -- a tool line's first level is its unlock and a weapon line's first level is
    -- the block turning up, so issuing either is taking that line to level one.
    -- The draft goes on offering both whatever levels they have left -- which for
    -- the two weapons is none, today.
    issue(self, startTool)
    issue(self, startWeapon)

    self:rebuild(vw, vh)
    return self
end

function Loadout:levelOf(id)
    return self.taken[id] or 0
end

-- A line put out of the run. Deliberately separate from the levels: a banned line
-- keeps whatever level it had reached, because expelling it is a refusal of the
-- *rest* of it rather than a giving back of what it already did -- a run that has
-- taken two levels of the orbit and thrown the line out still has two levels of
-- orbit. So nothing is rebuilt here; the ban only ever narrows what may be dealt.
function Loadout:expel(id)
    if not Upgrades.byId[id] then return false end
    self.banned[id] = true
    return true
end

-- Put back what a run had learned, for one being picked up from a bookmark
-- (src/bookmark.lua). `lines` is `{ { id, level }, ... }` in the order the lines
-- were first taken, and that order is the reason a bookmark writes it out rather
-- than writing a level per id: `rebuild` replays levels in it and
-- `syncEquipped` walks it to build the strip, so it is what decides which slot a
-- tool is in.
--
-- Everything is *replaced* rather than added to. `Loadout.new` has already
-- issued the lesson's tool and the character's weapon, and the bookmark's own
-- list has both of those in it too -- the run being restored is on the same page
-- as the same hero -- so the two lists agree about their first two entries and
-- merging them would only be a way of getting that wrong.
--
-- A level is replayed from scratch here like any other, which is the whole
-- reason this is twenty numbers rather than a serialised loadout: every level in
-- the catalogue is written as a function of what it changes rather than as a
-- difference from the level before it, so a run's stats are a pure function of
-- the levels it reached.
function Loadout:restore(lines, vw, vh)
    self.taken, self.order = {}, {}

    for _, line in ipairs(lines) do
        local up = Upgrades.byId[line.id]
        -- A line the catalogue no longer has is dropped and a level past the end
        -- of one is clamped, rather than either being trusted: this is the one
        -- file in the game a later version is likely to disagree with, and no
        -- disagreement may cost more than the line it is about. `levelsIn` is
        -- `math.huge` for an endless line, which clamps to itself.
        if up and not self.taken[up.id] then
            self.taken[up.id] = math.min(math.max(1, math.floor(line.level)),
                Upgrades.levelsIn(up))
            self.order[#self.order + 1] = up.id
        end
    end

    self:rebuild(vw, vh)
end

--- building it ---------------------------------------------------------------

local function toolNamed(tools, name)
    for _, tool in ipairs(tools) do
        if tool.name == name then return tool end
    end
end

-- Damage multipliers land once, at the end, on top of whatever the tool's own
-- upgrades did to its numbers -- so the sharpener deepens the ruler you have
-- rather than the ruler you started with.
local function scaleDamage(tool, mult)
    if tool.damage then tool.damage = tool.damage * mult end
    -- The highlighter's burn, the rubber's ram, the pencil's loop, the
    -- gluestick's tear and what the pen's line takes with it as it comes off
    -- the page are damage like any other, so the sharpener reaches them.
    -- Safe to write into: the upgrade levels build these fresh on the run's
    -- copy every rebuild, so nothing shared is ever scaled twice.
    if tool.ignite then tool.ignite.damage = tool.ignite.damage * mult end
    if tool.ram then tool.ram.damage = tool.ram.damage * mult end
    if tool.pop then tool.pop.damage = tool.pop.damage * mult end
    -- What a *mark* does to whatever leans on it, where that is not what the nib
    -- does going past (`sting`, the DECKLE). It is damage like any other and the
    -- sharpener has always reached both halves of a row that carried two.
    if tool.sting then tool.sting = tool.sting * mult end
    if tool.tear then tool.tear = tool.tear * mult end
    -- A ring's payload is three fields and a row picks (`loop` in src/tools.lua),
    -- so both of the ones carrying a number are asked for by name rather than
    -- assumed. `damage` used to be the only one and used to be safe to read
    -- blind; the BLEED writes an `ignite` and no damage at all, and the CUTOUT's
    -- ring hurts nothing -- it takes the paper away and the crowd with it -- so a
    -- blind read is a nil multiplication the first time either of them closes a
    -- circle. `lift` is the third and is deliberately not here for `sever`'s
    -- reason: there is no damage in moving something across the page.
    if tool.loop then
        if tool.loop.damage then tool.loop.damage = tool.loop.damage * mult end
        if tool.loop.ignite then
            tool.loop.ignite.damage = tool.loop.ignite.damage * mult
        end
    end
    -- The STUB's tap, which is a whole rub folded into one press: its own damage,
    -- and the ram written inside it rather than out on the row so that only the
    -- shove hard enough to matter ever reads one.
    if tool.tap then
        tool.tap.damage = tool.tap.damage * mult
        if tool.tap.ram then tool.tap.ram.damage = tool.tap.ram.damage * mult end
    end
    -- And what a stroke fastens its own ends down with (`fasten`, the STITCH),
    -- which is a whole `drop` block on the row rather than inside one -- the SEAM's
    -- `snap.wire` a storey out, and reached by name for the same reason. Its
    -- `crit.mult` is left alone, the rule this walk follows everywhere: a
    -- multiplier on damage this pass has already scaled is not damage.
    if tool.fasten then
        tool.fasten.damage = tool.fasten.damage * mult
    end
    -- And what a stroke opens the page with along the line between its own two ends
    -- (`chord`, the COLLAGE / SCORCH / SHEAR) -- a whole `cut` block on the row
    -- rather than one of `Tools.BLOCKS`, so it is reached by name exactly as
    -- `fasten` is, and its own `blades` a storey further in for the reason the
    -- blocks' is: the scissors keep one number a level deeper than the block and
    -- reaching it blind is one field away from indexing the compass's bare `bite`.
    --
    -- `ignite` on it is deliberately *not* here. On the one row that writes one it is
    -- the same table as `tool.ignite`, scaled above -- the burn the band sets and the
    -- burn the blades set are one burn -- so a second multiplication here would
    -- square it.
    if tool.chord then
        tool.chord.damage = tool.chord.damage * mult
        tool.chord.blades.damage = tool.chord.blades.damage * mult
    end
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block and block.damage then
            block.damage = block.damage * mult
        end
        -- The pushpin's drive is damage too; its `point` is a multiplier on
        -- damage already scaled here, so it is left alone the way crit.mult is.
        if block and block.drive then
            block.drive = block.drive * mult
        end
        -- And the scissors keep one of their numbers a level deeper than the
        -- block: what the stretch between the two taps closes for. Reached by
        -- name rather than by walking into whatever sub-tables a block happens to
        -- have -- the compass's `sweep.bite` is a bare number, so a blind walk is
        -- one field away from indexing one.
        --
        -- `sever` is the block's other sub-table and it is deliberately not here.
        -- What a severed region does to the crowd is carry it off the page and set
        -- it down in the far corner rather than hurt it (Scissors:lift,
        -- Compass:lift), so there is no damage in it for the sharpener to find --
        -- which is also what lets the PUNCH write `sever` on its row instead of
        -- building it from a level every rebuild.
        if block and block.blades then
            block.blades.damage = block.blades.damage * mult
        end
        -- And a straight edge keeps the other one: what a ruler presses into the
        -- page along the line it lands on (`snap.wire`, the SEAM in src/tools.lua).
        -- It is a whole `drop` block one level in, so it is reached by name for the
        -- blades' reason -- and only its damage is, because a staple has never
        -- shoved anything and its `crit.mult` is a multiplier on damage this walk
        -- has already scaled, which is the rule the walk follows everywhere else.
        if block and block.wire then
            block.wire.damage = block.wire.damage * mult
        end
    end
end

-- The shove, and knock sits in exactly the places damage sits, so this is the
-- same walk. Nothing in the catalogue moves `stats.knock` off 1 today -- the
-- elastic band was the one line that did and it is off the roster -- so this
-- walk is the identity until something is written on that axis again. It stays
-- written as a multiplication for when that happens, and that is load-bearing:
-- the pen, the highlighter and the gluestick are written with a knock of 0
-- because not shoving is what they are, and a multiplier leaves all three at 0.
-- It also keeps `Stroke.touches` honest, since that asks whether the knock is
-- above zero to decide whether a stroke touches anything at all.
local function scaleKnock(tool, mult)
    if tool.knock then tool.knock = tool.knock * mult end
    -- The one shove in the game that is not on a row or in a block: a tap is a
    -- gesture a brush row carries, so its knock sits where the gesture does.
    if tool.tap then tool.tap.knock = tool.tap.knock * mult end
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block and block.knock then
            block.knock = block.knock * mult
        end
    end
end

-- The blotter, on the same terms and for the same reason: whatever the tool
-- charges after its own upgrades have had their say, charged less. One field,
-- because `ink` means the same thing on a brush and on a tool that is tapped --
-- per pixel there, per use here -- and a discount applies to both alike.
local function scaleCost(tool, mult)
    tool.ink = tool.ink * mult
end

-- The fixative. What moves is what goes on *working* after the stroke is over:
-- how long a mark stays on the page, and how long it holds what it caught.
--
-- Tools and nothing else. `scaleWeaponPersistence` below is the *laminate*
-- asking the same question of the weapons, and they are two lines and two stats
-- rather than one of each for the reason the two damage multipliers are two
-- (src/upgrades.lua). What the two passes share is the question -- is this
-- duration the thing being on the page, or a journey to somewhere and a wait for
-- something -- and each answers it against what its own half of the game is made
-- of.
--
-- Which is why this walks the top-level fields and the drop block and stops
-- there. A brush's `life` is exactly how long it keeps hitting, walling or
-- lingering, and the gluestick's `freeze` is its whole point. A pin's hold and
-- its life are one number written twice (src/tools.lua) and have to stay that
-- way, so both move together. But the line a ruler leaves, the circle a compass
-- leaves and the slit the scissors leave have already done everything they are
-- ever going to do -- the hit landed on the swing, or on the tap -- so
-- stretching those would put nothing on the page but old pencil.
--
-- The compass's `sweep.turn` is left alone for a stronger reason than that, and
-- anyone adding a duration here should know it: the leg cuts what it passes over
-- as it arrives, so a slower turn gives the far side of the circle *longer to
-- walk out*. It is the one length of time in the game where more is worse, and a
-- blanket "things last longer" that reached it would quietly make the compass
-- worse every time the card was taken.
--
-- The highlighter's `ignite.time` is also left alone, and it is the one exclusion
-- here worth reading next to the laminate's list, because that pass *does* stretch
-- the bomb's crater and the two look like the same thing from a distance. They are
-- not. `ignite` is a body burning: something that touched the band is on fire, and
-- how long it burns for is how much damage that one hit ends up doing -- a hit
-- still landing on a thing already hit, which is the sharpener's to sell. A crater
-- is a *place*, and how long it smoulders is how long that stretch of page is
-- somewhere the crowd cannot walk. One is damage with a duration attached; the
-- other is ground, and ground is exactly what this axis is for.
local function scalePersistence(tool, mult)
    if tool.life then tool.life = tool.life * mult end
    if tool.freeze then tool.freeze = tool.freeze * mult end

    local drop = tool.drop
    if drop then
        if drop.freeze then drop.freeze = drop.freeze * mult end
        if drop.life then drop.life = drop.life * mult end
    end

    -- And the drop blocks that are not on the row: what a straight edge presses
    -- into the page as it comes down (`snap.wire`, the SEAM in src/tools.lua) and
    -- what a pair of blades leaves along the line between two taps (`cut.wire`,
    -- the HINGE). A staple's hold is a staple's hold whether a finger, an arm, a
    -- ruler or a pair of scissors drove it, so the fixative reaches it exactly as
    -- it reaches the other two.
    --
    -- Walked off `Tools.BLOCKS` rather than reached by name, which is where
    -- `scaleDamage` already finds the same field: two rows carry a wire inside a
    -- block now, so the choice was a walk or a second clause, and the walk is the
    -- one that costs the third row nothing. Only `wire` is read out of the block
    -- and never whatever else is in there, which is the point of `blades`' rule
    -- rather than a departure from it -- a blind walk into a block's sub-tables is
    -- one field away from indexing the compass's bare `sweep.bite`.
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        local wire = block and block.wire
        if wire then
            if wire.freeze then wire.freeze = wire.freeze * mult end
            if wire.life then wire.life = wire.life * mult end
        end
    end

    -- And the other one, which is a drop block on the row without being *the* row's
    -- block: what a stroke fastens its own two ends down with (`fasten`, the
    -- STITCH). Same sentence as the wire above -- a staple's hold is a staple's
    -- hold whoever drove it -- and reached by name for the same reason.
    local fasten = tool.fasten
    if fasten then
        if fasten.freeze then fasten.freeze = fasten.freeze * mult end
        if fasten.life then fasten.life = fasten.life * mult end
    end

    -- And the paste a severed half carries off with it: what the offcut leaves on
    -- the crowd it sets down in the corner (`chord.sever.paste`, the COLLAGE).
    --
    -- **A hold and not a slit**, which is what puts it here at all. The paragraph
    -- above leaves the mark a pair of scissors makes alone on purpose -- the slit has
    -- already done everything it is ever going to do, so stretching it would put
    -- nothing on the page but old pencil -- and this is not that. It is the
    -- gluestick's own `freeze` handed to a body, one storey in, and the gluestick's
    -- `freeze` is the first thing this pass reaches.
    local chord = tool.chord
    if chord and chord.sever and chord.sever.paste then
        chord.sever.paste = chord.sever.paste * mult
    end
end

-- The laminate, and the rule it selects on is the metronome's read the other way
-- round. That one moves the gap between one thing a weapon does and the next;
-- this one moves **how long the thing is there**. Between them they cover every
-- length of time on a weapon block and they never touch the same field, which is
-- not tidiness -- it is what lets a player hold both cards and know what each of
-- them bought.
--
-- So the question asked of every duration here is: is this the thing being on the
-- page, or is it a journey to somewhere and a wait for something? A crater
-- smouldering, a sun at full height, a beam lying across the paper, a spiral
-- wound on and a trail behind you are all the first. A rocket's time of flight, a
-- fuse and a wind-up are all the second, and the second is nobody's to sell here.
--
-- It is a list rather than a walk because `life` means three different things
-- across the twelve blocks and only one of them is persistence -- and because the
-- one nested field it wants (`burn.life`) is a field a blind walk would have to go
-- looking for.
--
--   spiral  `life` is how long a spiral stays wound onto the page and `hold` is
--           how long what it caught keeps walking in after the ink has gone. Both
--           are the gluestick's freeze by another name -- this weapon does no
--           damage at all, so a hold is the entire thing there is to lengthen and
--           it is the least arguable entry in either pass.
--   skate   `life` is how long one stamp of the trail stays down, which is the
--           whole footprint of the weapon: the trail is the only thing in the game
--           whose *size* is a length of time, so this is the biggest single thing
--           the laminate does anywhere. It is also the one entry with a frame
--           budget behind it -- the trail is `life x speed / SPACING` stamps long
--           and every walk over it costs that (`SPACING` in src/skate.lua), so the
--           laminate and the paper plane between them roughly treble it. Still a
--           hundred-odd oval stamps, which is one texture draw each and a bounded
--           box test per enemy on a half-second tick.
--   bomb    `burn.life` is the crater going on smouldering, which is ground you
--           took away -- a puddle in the other half of the palette (src/bomb.lua),
--           and a surface anything can walk into later rather than a hit still
--           landing on something already hit. The fuse is *not* here: that is the
--           wait, it is the whole of what the bomb's own line is about, and this
--           must not sell it from the other end.
--   sun     `stay` is the seconds at full height, and only that. `up` and `down`
--           are the rising and the setting -- transitions rather than the sun
--           being up -- and stretching them would slow the animation down instead
--           of leaving the disc there for longer. `gap` is the metronome's.
--   beam    `hold` is how long the light is actually across the page, which is
--           worth nothing at all until the level that turns the flash into a beam
--           and then worth as much as anything here. `charge` is not here for two
--           reasons pointing the same way: it is a wind-up, and its own line
--           refuses to sell it because the wind-up is the half of the weapon you
--           play.
--
-- What is deliberately *not* here, since each one is a duration somebody will
-- reach for:
--
--   rocket  its `life` is time of flight, so stretching it is *range* -- and
--           with the aiming gone (src/rocket.lua) range is most of what an
--           unaimed volley is worth, which makes this the one entry here it
--           would be easiest to talk yourself into. Its own line sells the shape
--           of the volley instead, deliberately, and the burst at the end of a
--           flight is a hit landing rather than anything left on the page.
--   cool S  it has no life at all. What ends one is the viewport running out from
--           under it, and there is no number here to move.
--   storm   nothing it does persists. The shock an enemy wears is an outline with
--           an expiry, which is a readout rather than an effect.
--   spiral  `push` -- the finale's ring round your own feet -- has no life either:
--           it never leaves, and math.huge does not need help.
--   ticks   every one of them, everywhere. A tick is how *often* something already
--           on the page hurts, which is a rate and not a length -- and it is not
--           the metronome's either, for the same reason: what it would buy is
--           damage per second, which is what the graphite is for.
--
-- And one that is worse than not helping, which is the sun's `soak`: the seconds
-- under the disc before a survivor carries the bleach out. Multiplying that up
-- makes the mark *harder* to earn, so it is the compass's `sweep.turn` in the tool
-- pass above -- the second length of time in this game where more is worse, and
-- the second reason both of these passes are lists and not walks.
local WEAPON_PERSISTENCE = {
    { stat = "spiral", fields = { "life", "hold" } },
    { stat = "skate", fields = { "life" } },
    { stat = "bomb", block = "burn", fields = { "life" } },
    { stat = "sun", fields = { "stay" } },
    { stat = "beam", fields = { "hold" } },
}

local function scaleWeaponPersistence(stats, mult)
    for _, spec in ipairs(WEAPON_PERSISTENCE) do
        local block = stats[spec.stat]
        -- A level deeper where the row says so, and nil where that level has not
        -- been drafted yet: the crater is the last level of the bomb's line, so
        -- most runs holding a bomb have no `burn` at all.
        if block and spec.block then block = block[spec.block] end
        if block then
            for _, field in ipairs(spec.fields) do
                if block[field] then block[field] = block[field] * mult end
            end
        end
    end
end

-- The metronome, and the one multiplier in the game a weapon module never sees.
-- The three fields below are every gap in the catalogue and they all mean the
-- same thing -- how long until this weapon does its thing again -- so this is a
-- walk by name rather than a list of twelve:
--
--   every   the gap between one shot, swing, launch, drop, cloud or spiral and
--           the next. Nine of the blocks have one, and the sunrays have theirs a
--           level deeper than the block, which is the only nesting here.
--   gap     the sun's, and only the sun's: it is the stretch it spends below the
--           page between one rising and the next, which is `every` written from
--           the other end because the sun is up for a while rather than at once.
--   rehit   the star's and the flock's, which are the two weapons that are simply
--           *there* and have no launch to space out. The gap between one cut of
--           the same enemy and the next is the only cadence either of them has,
--           so it is theirs.
--
-- Everything else about a weapon's clock is left alone, and the two that will be
-- reached for are worth naming. A `tick` -- the sun's burn, the skate's cut, the
-- crater's smoulder -- is how fast something already landed goes on hurting,
-- which is damage per second and belongs to the damage lines; the fixative's own
-- exclusions above are written on the same reasoning. And a wind-up or a fuse is
-- the half of a weapon you *play* -- the beam's `charge` and the bomb's `fuse`
-- are each sold by their own line, on purpose, and this must not sell them
-- again. The beam is the one place that shows: its rest is the period less the
-- wind-up and the light, so shortening the period comes out of the rest alone
-- and a fully-bought pair leaves it at nothing. Beam:rest floors there rather
-- than running backwards, so that is a beam with no gap in it and not a clock in
-- trouble.
local CADENCE = { "every", "gap", "rehit" }

local function scaleCadence(stats, mult)
    for _, spec in ipairs(WEAPONS) do
        local block = stats[spec.stat]
        if block then
            for _, field in ipairs(CADENCE) do
                if block[field] then block[field] = block[field] * mult end
            end
            if block.rays and block.rays.every then
                block.rays.every = block.rays.every * mult
            end
        end
    end
end

function Loadout:rebuild(vw, vh)
    local screen = { w = vw, h = vh }

    self.stats = Upgrades.baseStats()

    -- What the run's fusions have eaten, worked out before anything is counted
    -- or equipped off it. The levels of a fused line are still replayed below and
    -- still land on that tool's copy -- there is nothing to undo, and undoing it
    -- would be the one thing this file never does. What changes is only that the
    -- tool does not reach the strip and the line does not hold a place on it.
    --
    -- Except while the dev toggle's *tool* switch is lending, which suspends this
    -- exactly as it already suspends the four-slot caps, and for the same reason:
    -- what that switch promises is *every* tool on the strip at once, and a grant
    -- that handed over a fusion would be a grant that took two tools away again --
    -- so the one gesture for looking at all of them would be the one gesture that
    -- could not show you the marker or the compass. It is not the fusion being
    -- wrong there, it is the switch being a lie about the rules on purpose, which
    -- is what it is for. Turning it off rebuilds with that half already cleared,
    -- so a fusion the run genuinely earned eats its lines again on the way out.
    -- The weapon switch is not asked, since nothing it lends touches the strip.
    self.fused = {}
    if not self:lent("tool") then
        for _, id in ipairs(self.order) do
            for _, eaten in ipairs(Upgrades.byId[id].fuses or {}) do
                self.fused[eaten] = true
            end
        end
    end

    self.tools = {}
    for i, tool in ipairs(Tools.list) do
        self.tools[i] = Tools.copy(tool)
    end

    -- The catalogue and then the endless lines, in that order, which is what
    -- puts an endless multiplier on top of what the catalogue did. Every level
    -- is fetched through Upgrades.levelAt rather than off `up.levels`, so a line
    -- that generates its levels replays exactly like one that has them written
    -- out -- the replay does not know or care which it is holding.
    Upgrades.each(function(up)
        local level = self.taken[up.id]
        local target = self.stats
        if up.tool then target = toolNamed(self.tools, up.tool) end

        if level and target then
            for l = 1, level do
                Upgrades.levelAt(up, l).apply(target, screen)
            end
        end
    end)

    -- The four multipliers that apply to every tool at once, landing after
    -- every tool's own upgrades rather than before them.
    local mult = self.stats.toolDamage * self.stats.damage
    for _, tool in ipairs(self.tools) do
        scaleDamage(tool, mult)
        scaleKnock(tool, self.stats.knock)
        scaleCost(tool, self.stats.inkCost)
        scalePersistence(tool, self.stats.markLife)
    end

    -- And the two that apply to the weapon blocks, on the same terms and for the
    -- same reason: after every weapon's own levels have had their say, so the
    -- metronome shortens the gap the bomb's own line already halved and the
    -- laminate stretches the stay the spiral's own line already lengthened.
    --
    -- Writing into the blocks is safe for exactly the reason the tool copies are:
    -- the replay above builds these fresh out of `Upgrades.baseStats` on every
    -- rebuild, so nothing shared is ever scaled and nothing is ever scaled twice.
    -- It is also why the weapon modules read `passiveDamage` at the point they
    -- use it and do not read either of these at all -- damage is a number a
    -- rocket carries away with it, and a clock is a number the weapon is still
    -- standing next to.
    scaleWeaponPersistence(self.stats, self.stats.passiveLife)
    scaleCadence(self.stats, self.stats.weaponRate)

    self:syncWeapons()
    self:syncEquipped()
end

-- The tools this run has unlocked, in the order it unlocked them.
--
-- A tool line's first level is the unlock and has nothing to apply, so having
-- taken any level of it at all *is* what equips the tool -- there is no separate
-- flag to keep in step with the levels. Order is the order lines were first
-- taken, which makes this list append-only: a tool unlocked mid-run lands on the
-- end and never moves anything already in it, so the index the player is holding
-- goes on meaning the tool they were holding.
--
-- A line whose tool has been shelved contributes nothing, exactly as it is never
-- offered in the first place.
function Loadout:syncEquipped()
    self.equipped = {}

    for _, id in ipairs(self.order) do
        local up = Upgrades.byId[id]
        -- A line a fusion ate is not on the strip any more. Its levels were
        -- spent -- they are what the fusion is made of -- so the line keeps its
        -- level and simply stops handing a tool over.
        if up.kind == "tool" and not self.fused[id] then
            local tool = toolNamed(self.tools, up.tool)
            if tool then
                self.equipped[#self.equipped + 1] = {
                    tool = tool, up = up, level = self:levelOf(id),
                }
            end
        end
    end
end

-- A weapon whose block has appeared is built once and reconfigured forever
-- after. Nothing here ever takes one away: no upgrade has taken anything away
-- yet, and if one ever does, this is where it would go.
function Loadout:syncWeapons()
    self.weapons = {}

    for _, spec in ipairs(WEAPONS) do
        local block = self.stats[spec.stat]
        if block then
            local weapon = self.live[spec.stat]
            if not weapon then
                weapon = spec.module.new()
                self.live[spec.stat] = weapon
            end
            weapon:configure(block)
            self.weapons[#self.weapons + 1] = weapon
        end
    end
end

-- The run's version of a row in Tools.list. Every part of the game that reads a
-- tool's numbers mid-run goes through here rather than through Tools.get, which
-- is what makes an upgrade to a tool land on the thing the tool leaves behind
-- without any of those places knowing upgrades exist.
--
-- The index is a slot on the strip -- 1 to 4 -- and not a row of Tools.list.
-- Which tool is in which slot is a fact about this run, so it is a fact this
-- object owns; nothing outside it should be indexing Tools.list to find out what
-- the player is holding.
function Loadout:tool(index)
    local slot = self.equipped[index]
    return slot and slot.tool
end

--- the draft -----------------------------------------------------------------

-- How many *lines* of each kind one run can carry. A kind missing from here is
-- uncapped, and one is: the endless lines (src/upgrades.lua) have no cap because
-- capping them would be capping the run, which is the one thing they exist not
-- to do. Everything a run's *shape* is made of is still counted here.
--
-- The cap is on how many lines a run may *start*, not on how many levels it may
-- take. That is the whole mechanic: once the slots are full the lines a run has
-- never touched stop being offered, and the ones it has carry on coming up until
-- they are finished. A run stops collecting and starts committing.
--
-- Four tools is still the tightest of the three caps, because a tool line's
-- first level hands you the tool itself: the strip is drafted, not issued. One
-- of the four is gone before the run starts -- the lesson hands one over (`tool`
-- in src/subjects.lua) and it is taken as the run is built -- so what the draft
-- is really offering is the other three. Ten tools you can all reach would be ten
-- tools none of which you had to choose between.
--
-- The weapon cap is five against the ten lines written, and one of the five is
-- gone before the run starts: the character hands one of them over the way the
-- lesson hands over a tool (src/characters.lua), so what the draft is really
-- offering is the other four. It went from four to five when those two attacks
-- became lines of their own for exactly that reason -- a run drafts as many
-- weapons as it always did, and the thing it came with is now counted honestly
-- instead of being invisible. It still bites hardest of the three: a run starts
-- half the catalogue and has to decide which five it never touches.
Loadout.SLOTS = { weapon = 5, passive = 5, tool = 4 }

-- What the run has started, by kind. A line occupies its slot from the moment
-- its first level is taken and never gives it back, unless a fusion ate it --
-- `order` is exactly the list of lines that have been started, which is why it is
-- what gets counted.
function Loadout:slotsUsed()
    local used = {}
    for _, id in ipairs(self.order) do
        -- Except a line a fusion has eaten, which gives its place back. That is
        -- the one exception to "a line occupies its slot for ever", and it is not
        -- really one: the line is gone, and what took it is holding a slot of its
        -- own two lines up the list.
        if not self.fused[id] then
            local kind = Upgrades.byId[id].kind
            used[kind] = (used[kind] or 0) + 1
        end
    end
    return used
end

-- Used and total for one kind, for anything that wants to say so out loud.
-- `cap` is nil for a kind that has no limit.
function Loadout:slots(kind)
    return self:slotsUsed()[kind] or 0, Loadout.SLOTS[kind]
end

-- Every line the draft is allowed to offer: one with a level left in it, whose
-- tool is still on the strip if it names one, which the book has opened at all,
-- and which the run either has room to start or has already started.
--
-- That last clause is the one that matters, and it is now doing the same job
-- twice. A line already under way is always offered, however full the slots are
-- and whatever the collection says -- otherwise filling the last slot could
-- strand a line on level one with no way to finish it, and the cap would be
-- punishing a run for the order it happened to be offered things in rather than
-- for what it chose. The collection reads the same way round: nothing a run is
-- already carrying is ever taken off it, which is what makes it safe for a lesson
-- or a character to hand over a line the book has not opened.
-- Whether a fusion's ingredients are all finished (`needs` in src/upgrades.lua).
-- True for everything else, since a line that asks for nothing is always ready.
--
-- *Finished* rather than merely started, and the whole feature is in that word: a
-- fusion is what a run does with lines it has nothing left to spend on, so it can
-- never be a shortcut past them. `levelsIn` answers `math.huge` for an endless
-- line, which no run ever reaches -- so an endless line named here would be a
-- fusion nobody can be dealt, which is a fusion written wrong rather than a case
-- to handle.
-- And that nothing it means to *spend* has been spent already, which is what
-- makes two fusions sharing an ingredient a choice rather than a shopping list.
-- The pencil and the marker both fuse with the compass, and there is one compass:
-- a run that finished all three could otherwise take one fusion and then be dealt
-- the other, which would eat a line that is already gone -- a fusion costing the
-- strip nothing where the whole shape of the mechanic is two tools in and one
-- out. `fuses` is what a fusion hands over, so a line already handed over is a
-- fusion that cannot be made.
--
-- Read off `self.fused`, so the dev toggle's tool switch suspends this along with
-- the eating itself and a dev strip still shows every fusion at once -- which is
-- the same lie about the rules that switch already tells, on purpose.
function Loadout:ready(up)
    for _, id in ipairs(up.needs or {}) do
        local need = Upgrades.byId[id]
        if not need or self:levelOf(id) < Upgrades.levelsIn(need) then
            return false
        end
    end
    for _, id in ipairs(up.fuses or {}) do
        if self.fused[id] then return false end
    end
    return true
end

function Loadout:candidates()
    local out = {}
    local used = self:slotsUsed()
    -- And nothing the run has expelled, and nothing the book has not opened yet
    -- (src/collection.lua). All of it filtered here rather than at the roll, so
    -- that what the draft may reach is one list and one question rather than
    -- something each deal has to remember: a ban is a fact about this run, an
    -- unlock is a fact about the book, and neither is a fact about one deal.

    for _, up in ipairs(Upgrades.list) do
        local level = self:levelOf(up.id)
        local left = level < Upgrades.levelsIn(up)
        local cap = Loadout.SLOTS[up.kind]
        -- A fusion never has to find room, and it is not an exemption: it hands
        -- back at least as many places of its own kind as it takes (`fuses` in
        -- src/upgrades.lua), so a run with a full strip is exactly the run one is
        -- for. Refusing it at the cap would mean the four-slot rule locked out
        -- the one card that unlocks it.
        local room = level > 0 or cap == nil or up.fuses ~= nil
            or (used[up.kind] or 0) < cap
        -- A fusion is exempt from the collection here, and that is not a hole in
        -- it: `ready` above already asks a strictly stronger question -- both
        -- parents *finished on this strip* -- than the book having them at all.
        -- The one case where the two disagree is the case this is for. A lesson
        -- issues its tool to the run that opens on it long before the book has
        -- opened that tool anywhere else (`issue`), so the pencil crossed with the
        -- pen is buildable on a science page while `Collection.has` still calls
        -- the pencil shut. The shelf's question is what could ever be built; this
        -- one is what can be taken now, and gating a fusion twice would have quietly
        -- taken away the first fusion a fresh book could reach.
        local open = level > 0 or up.needs ~= nil or Collection.has(up.id)

        if left and room and open and not self.banned[up.id]
            and not self.fused[up.id] and self:ready(up)
            and (not up.tool or toolNamed(self.tools, up.tool)) then
            out[#out + 1] = up
        end
    end

    return out
end

-- n distinct lines, weighted, and n of them however far into a run this is
-- asked: whatever the catalogue cannot fill, the endless lines do.
--
-- Which is what turns the ceiling on a run from a ceiling on how far it can get
-- into a ceiling on what it can *carry*. The four-slot caps are untouched and go
-- on doing exactly what they did -- a run still stops being offered new lines the
-- moment it has committed to its four weapons, its four tools and its five
-- passives, and it still has to decide which fifth weapon it never starts. What
-- has changed is only what happens *after* that: a level reached past the last
-- real pick is still a level, and it is still asked about.
--
-- Real lines are drawn first and drawn always. An endless line is a few percent
-- and a real one is a whole weapon, so there is no draft anywhere in a run where
-- the padding should be taking a place a genuine candidate could have had -- the
-- endless ones only ever fill what is left over.
--
-- `avoid` is lines already lying on the table, for the one caller that wants a
-- card rather than a deal: EXPEL replaces the card it threw out and leaves the
-- other two where they are (`Game:expelLine`), so it asks for one line that is not
-- either of them. It is a list of upgrade rows rather than of ids because that is
-- what the caller is holding -- the offer itself.
function Loadout:roll(n, avoid)
    local pool = self:candidates()
    local offer = {}

    local held = {}
    for _, up in ipairs(avoid or {}) do held[up.id] = true end
    for i = #pool, 1, -1 do
        if held[pool[i].id] then table.remove(pool, i) end
    end

    while #offer < n and #pool > 0 do
        local total = 0
        for _, up in ipairs(pool) do total = total + (up.weight or 1) end

        local r = love.math.random() * total
        for i, up in ipairs(pool) do
            r = r - (up.weight or 1)
            if r <= 0 then
                offer[#offer + 1] = up
                table.remove(pool, i)
                break
            end
        end
    end

    -- Flat rather than weighted, and without repeating: these are six ways of
    -- pressing harder rather than six things of different sizes, so there is
    -- nothing here for a weight to say. Drawn from a copy, so the catalogue's
    -- own table is never the thing being torn up.
    local spare = {}
    for _, up in ipairs(Upgrades.endless) do
        -- An expelled endless line stays expelled, and a card already on the table
        -- is not dealt twice. Both are the same rule the real pool is under, and
        -- the padding has to be under it too or a reroll's fourth card would be the
        -- line the run just threw out.
        if not self.banned[up.id] and not held[up.id] then
            spare[#spare + 1] = up
        end
    end

    while #offer < n and #spare > 0 do
        local i = love.math.random(#spare)
        offer[#offer + 1] = spare[i]
        table.remove(spare, i)
    end

    return offer
end

-- What a dev switch hands over. There are two of them, and the split is the
-- point: the kinds a run *carries* are the strip down one margin and the weapons
-- down the other, both drafted rather than issued, and both therefore things a
-- playtest cannot see without spending a run getting to them -- but they are not
-- looked at the same way. A tool is judged by what your hand does with it, and a
-- page already carrying all thirteen weapons is a page where nothing your hand
-- does can be seen at all. One switch each means a playtest can borrow the half
-- it is looking at and leave the other half of the run alone. Passives are
-- deliberately not offered by either: they are numbers about the player rather
-- than things to look at, and a playtest that wants one wants a particular one
-- rather than all fifteen. Which kinds have a switch is `Pause.DEV`.
--
-- `dev` is nil until a switch is thrown and nil again once the last one is
-- handed back, so `loadout.dev` still answers "is anything borrowed at all" --
-- which is the question the four-slot caps and the fusions are asked about
-- below. Under it, one map of id -> the level that line really stood at per
-- borrowed kind, so each half restores exactly what it lent and nothing else.
function Loadout:lent(kind)
    return self.dev ~= nil and self.dev[kind] ~= nil
end

-- Granting maxes every line of that kind that has a level left -- ones the run
-- never started and ones it was part-way through alike -- straight past the
-- four-slot caps; the counters on the held screens go red rather than lie about
-- it. A maxed line has no level left, so the draft cannot invest in one while
-- the switch is on -- which is what keeps the restore honest.
--
-- It walks the catalogue rather than `candidates`, so it hands over lines the book
-- has not opened yet (src/collection.lua) along with the rest -- and fusions,
-- whose `needs` it is satisfying in the same pass anyway. What a granted fusion
-- does *not* do is eat the lines it is made of: `rebuild` holds that back while
-- anything is borrowed, so the strip a playtest is handed is the marker and the
-- compass and the halo, rather than the halo instead of them. See the note there.
function Loadout:grant(kind, vw, vh)
    -- Granting a half that is already lending would overwrite what it remembers
    -- with the levels it wrote itself, and the restore would then hand back the
    -- loan instead of the run. Nothing calls it that way -- the switch asks
    -- `lent` first -- and the guard is here so nothing can.
    if self:lent(kind) then return end

    self.dev = self.dev or {}
    local borrowed = {}
    self.dev[kind] = borrowed

    for _, up in ipairs(Upgrades.list) do
        if up.kind == kind and self:levelOf(up.id) < #up.levels then
            borrowed[up.id] = self:levelOf(up.id)
            self.taken[up.id] = #up.levels
            if borrowed[up.id] == 0 then
                self.order[#self.order + 1] = up.id
            end
        end
    end

    self:rebuild(vw, vh)
end

-- Every line that half lent drops back to the level the run had really reached;
-- one it had never started leaves the strip, or the sky, entirely. The replay in
-- rebuild makes restoring as safe as granting was, since nothing has to be
-- undone, only not replayed -- and the other half, if it is still on, is replayed
-- along with everything else rather than being touched here.
function Loadout:revoke(kind, vw, vh)
    local borrowed = self.dev and self.dev[kind]
    if not borrowed then return end

    for id, level in pairs(borrowed) do
        if level == 0 then
            self.taken[id] = nil
            for i = #self.order, 1, -1 do
                if self.order[i] == id then
                    table.remove(self.order, i)
                    break
                end
            end
        else
            self.taken[id] = level
        end
    end

    self.dev[kind] = nil
    if not next(self.dev) then self.dev = nil end
    self:rebuild(vw, vh)

    -- A weapon the run never really started gives its instance up as well as
    -- its block. Everywhere else an instance outliving its block is the point
    -- -- an orbit keeps its angle through an upgrade -- but a sun the run only
    -- ever borrowed would otherwise still be part-way round its cycle if the
    -- draft later offered the line for real, and the first level of a weapon is
    -- meant to show you what you just bought. Keyed off the block being gone
    -- rather than off a list, since that is exactly the condition -- so handing
    -- the tools back walks it and finds nothing, which is correct and free.
    for stat in pairs(self.live) do
        if not self.stats[stat] then self.live[stat] = nil end
    end
end

-- Takes the next level of a line and rebuilds everything off it. Returns the
-- line, for whoever wants to say what was just taken.
function Loadout:take(id, game)
    local level = self:levelOf(id) + 1
    self.taken[id] = level
    if level == 1 then self.order[#self.order + 1] = id end

    self:rebuild(game.vw, game.vh)
    return Upgrades.byId[id]
end

--- the weapons ---------------------------------------------------------------

function Loadout:updateWeapons(dt, game, grid)
    for _, weapon in ipairs(self.weapons) do
        weapon:update(dt, game, grid)
    end
end

-- The most the bandaid may hand back, in health a second, and how many seconds
-- of that it is allowed to owe you. Both are constants here rather than numbers
-- on the stats for the bomb's `BLINK` reason: whatever the line ever does to the
-- fraction, the rate a plaster works at stays exactly this.
--
-- The ceiling is set against what the sellotape sells at the top of its own line
-- -- a skull's worth every seven seconds, which is 1.7 a second -- and left
-- comfortably above it, since this one has to be *earned* every second it pays
-- out. What it is there to stop is the build that is already killing everything
-- also being unkillable.
local MEND_MOST = 4
local MEND_BANK = 2

-- The bandaid's cut of what the run's own weapons just dealt (src/upgrades.lua).
--
-- `dealt` is measured by the caller and not here, because the caller is the only
-- thing that knows *which* damage this frame was a weapon's: it reads the one
-- running total every hit in the game passes through (Enemy.dealt) either side of
-- the passes that are the run's fire. Everything a tool did landed earlier in the
-- frame and is not in the number, which is the whole of what makes this line mean
-- what its card says.
--
-- **What is earned is owed rather than paid.** A ceiling taken out of each frame
-- on its own would be a ceiling on a *burst*, and this game's damage arrives in
-- bursts -- a bolt with a chain on it or a crater going off in a crowd is several
-- hundred points inside one frame and nothing at all for the second either side
-- of it. Capping that where it lands would have quietly thrown away nine tenths
-- of what the line earned and left it paying out only for the weapons that tick.
-- So the cut goes into a debt and the debt is paid down at the rate above: a bomb
-- in a crowd is a couple of seconds of mending afterwards, which is also the
-- better thing to feel.
--
-- The debt is capped too, at `MEND_BANK` seconds of it. Without that, one
-- enormous frame would be a long tail of healing the run was no longer doing
-- anything to deserve -- a plaster is not a bank account.
function Loadout:mend(dt, game, dealt)
    local rate = self.stats.mend
    if rate <= 0 then return end

    self.owed = math.min(self.owed + math.max(0, dealt) * rate, MEND_MOST * MEND_BANK)
    if self.owed <= 0 then return end

    local pay = math.min(self.owed, MEND_MOST * dt)
    self.owed = self.owed - pay
    game.player:mend(pay)
end

-- What a weapon puts over the page: everything that stands proud of the paper or
-- floats above it, drawn after the crowd (Game:draw).
--
-- `draw` is optional for the same reason `drawGround` below is, read the other
-- way round -- the skate has nothing standing over the page at all. Its trail is
-- ground and goes down with the marks, and the board itself is drawn by the hero
-- standing on it (Player:draw), because it has to be *under* him and he is sorted
-- into the crowd by depth. A weapon with nothing up here says nothing about it.
function Loadout:drawWeapons(game)
    for _, weapon in ipairs(self.weapons) do
        if weapon.draw then weapon:draw(game) end
    end
end

-- The trail a skate is laying, if this run has one (src/skate.lua). It is the
-- only weapon anything outside this file asks a question of, and three parts of
-- the frame have to: the player reads what he is standing on (Player:update),
-- his own draw swaps his shadow for the board he is on, and the gems ask whether
-- they are lying on it (Game:updateGems). The block is what says the run has the
-- weapon and `live` is what flies it, so both are asked.
function Loadout:trail()
    return self.stats.skate and self.live.skate or nil
end

-- The flock, if this run has one (src/flock.lua). The second weapon anything
-- outside this file asks a question of, and the question is the trail's: a gem
-- lying out on the page is coming to you if a bird has been out and tapped it
-- (Game:updateGems). Asked the same way for the same reason -- the block is what
-- says the run has the weapon and `live` is what flies it.
function Loadout:flock()
    return self.stats.birds and self.live.birds or nil
end

-- What a weapon has left lying on the *page* rather than standing over it, drawn
-- with the marks and the boss's puddles instead of up with the weapons
-- (Game:draw). Only the bomb's burn has any, and the reason it needs its own pass
-- is the reason every other weapon does not: nothing else a weapon puts down
-- covers ground the crowd then walks across, and a filled patch drawn over the
-- crowd would hide the things it is burning.
--
-- Optional, so a weapon with nothing on the page says nothing about it.
function Loadout:drawGround(game)
    for _, weapon in ipairs(self.weapons) do
        if weapon.drawGround then weapon:drawGround(game) end
    end
end

return Loadout
