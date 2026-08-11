-- What you can draw with.
--
-- Every tool is the same object shape, so adding another is a matter of
-- appending a row here plus an icon in src/sprites.lua:
--
--   radius     how far from the stroke's centre line it can touch an enemy
--   damage     per hit
--   knock      knockback impulse applied away from the stroke
--   freeze     seconds a caught enemy is held in place (nil = never)
--   wall       solid: enemies steer around the line instead of crossing it
--   slick      slippery surface: {boost} for the player, {turn} for enemies
--   spacing    pixels between brush stamps along the path
--   smooth     how tightly the nib follows the pointer (nil = exactly)
--   ink        meter cost per pixel of line drawn (per drop, for a dropped one)
--   life       seconds the mark stays on the page after the stroke ends
--   ramp       colours the mark passes through as it fades, in order
--   fade       fraction of life before stamps start dropping out (dither)
--   rough      fraction of stamps missing from the off, for a broken mark
--   rehit      seconds before the same enemy can be hit again (nil = once)
--   linger     keep hitting enemies standing on the mark after it is drawn
--   tickRate   seconds between those ticks
--   stamp      draws one brush dab in the currently set colour. A brush may
--              have none, in which case it leaves no mark at all -- see crumbs
--   edge       second pass drawn underneath the core: {stamp, color, rough}
--   holes      third pass drawn over the top of it, same shape as edge
--   speck      particles thrown off while drawing: {chance, color}
--   crumbs     debris rubbed off the tip instead of a mark, thrown out to the
--              sides of the stroke rather than every way at once: {chance,
--              color}, chance per stamp step
--
-- Four of the tools are not brushes at all, and none of them draws a line, so
-- none of the fields above describe them. Each carries one of three blocks
-- instead -- the block says how the tool is *used*, not what it is -- and for
-- all of them `ink` is the flat price of one use rather than a cost per pixel:
--
--   drop   placed. A tap puts one where you tapped: {lands, radius, damage,
--          freeze, life}. `lands` is the module that turns up on the page, and
--          it is the only thing separating the pushpin from the stapler --
--          those two are used in exactly the same way, so they share the block
--          and the code path, and differ in what arrives and by how much. See
--          src/pin.lua and src/staple.lua.
--   snap   aimed. Press and it pivots about the player, release and it comes
--          down: {length, width, damage, knock, life, ramp, fade}. See
--          src/ruler.lua.
--   sweep  opened. Press and the needle goes into the page there, drag to open
--          it out to the width you want, release and it swings: {minR, maxR,
--          damage, knock, turn, life, ramp, fade}, plus the three the upgrade
--          line moves -- `laps` times round (`turn` is seconds for one of
--          them), `bite` times the damage over the first `biteArc` radians of
--          each lap, and `counter` for a second leg going the other way. See
--          src/compass.lua.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Pin = require("src.pin")
local Staple = require("src.staple")
local util = require("src.util")

local Tools = {}

Tools.MIN_INK = 0.18  -- can't start a stroke below this
Tools.REGEN = 0.3     -- meter per second
Tools.DELAY = 0.25    -- pause before the meter starts refilling

-- Pencil: a 1px core roughened up with a second pixel alongside it, which is
-- what makes a straight line read as graphite instead of a vector.
local function pencilStamp(s, stroke)
    love.graphics.rectangle("fill", s.x, s.y, 1, 1)
    local r = util.hash01(s.i, stroke.seed, 11)
    if r > 0.55 then
        local a = util.hash01(s.i, stroke.seed, 12)
        love.graphics.rectangle("fill",
            s.x + (a < 0.5 and -1 or 1),
            s.y + (r > 0.8 and 1 or 0), 1, 1)
    end
end

local function tipStamp(name)
    return function(s)
        Sprites.tips[name]:drawMask(s.x, s.y)
    end
end

local penStamp = tipStamp("pen")
local crayonStamp = tipStamp("crayon")
local crayonEdge = tipStamp("crayonEdge")

-- Pinholes where the wax skipped the tooth of the paper. They are painted on
-- top of the band rather than left out of it: stamps are laid 2px apart and
-- are 13px across, so an omitted one is simply filled in by its neighbours --
-- a gap in a wide mark has to be drawn, not skipped.
local function crayonHoles(s, stroke)
    local function at(seed) return math.floor(util.hash01(s.i, stroke.seed, seed) * 9) - 4 end
    love.graphics.rectangle("fill", s.x + at(42), s.y + at(43), 1, 1)
    if util.hash01(s.i, stroke.seed, 44) > 0.55 then
        love.graphics.rectangle("fill", s.x + at(45), s.y + at(46), 1, 1)
    end
end
local markerStamp = tipStamp("marker")
local markerEdge = tipStamp("markerEdge")
local glueStamp = tipStamp("glue")
local glueEdge = tipStamp("glueEdge")

Tools.list = {
    {
        name = "PENCIL",
        icon = "pencil",
        radius = 2, damage = 6, knock = 24,
        spacing = 1, ink = 1 / 230, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilStamp,
        speck = { chance = 0.10, color = Palette.graphite },
    },
    {
        name = "PEN",
        icon = "pen",
        -- The pen doesn't fight. Its line is solid to enemies -- they have to
        -- walk around it, and round the ends of it -- while the player crosses
        -- freely. It is a fence you can draw, and it lasts far longer than
        -- anything else, because a wall is only useful if it outlives the
        -- panic that made you draw it.
        radius = 2, damage = 0, knock = 0,
        wall = true,
        -- Round nib, one stamp per pixel: an even 3px line at any angle,
        -- against the pencil's deliberately ragged 1px.
        spacing = 1, ink = 1 / 170, life = 9,
        -- The nib trails the pointer slightly, which rolls hand jitter and the
        -- polygonal steps of a fast drag into the smooth curve a ballpoint
        -- actually leaves. Higher is tighter.
        smooth = 26,
        -- A wall you can't see is a trap, so the line holds full ink for most
        -- of its life and then goes visibly thin and pale in the last stretch:
        -- the fade is the warning that it is about to stop stopping anything.
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penStamp,
    },
    {
        name = "RUBBER",
        icon = "rubber",
        -- The one brush that puts nothing on the page. It used to sweep in
        -- paper, which really did wipe the ruling off -- but a pale shape lying
        -- there for a second afterwards reads as something smeared on rather
        -- than something rubbed off, which is to say it looked like the
        -- gluestick at half the size.
        --
        -- What a rubber actually leaves is crumbs, so crumbs are all this
        -- leaves: they come off the sides of the tip as it travels and they are
        -- gone before the stroke is. Nothing outlives the rub, hence a life of
        -- zero -- the mark is over the moment you let go.
        radius = 7, damage = 2, knock = 165,
        spacing = 2, ink = 1 / 150, life = 0,
        rehit = 0.3,
        crumbs = { chance = 0.7, color = Palette.graphite },
    },
    {
        name = "HIGHLIGHTER",
        icon = "marker",
        radius = 5, damage = 3, knock = 0,
        spacing = 2, ink = 1 / 120, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35,
        ramp = { Palette.blush },
        stamp = markerStamp,
        edge = { stamp = markerEdge, color = Palette.red },
        speck = { chance = 0.04, color = Palette.blush },
    },
    {
        name = "GLUESTICK",
        icon = "glue",
        -- Deliberately the eraser's look at exactly twice its radius. It deals
        -- no damage at all: the whole point is that anything caught in the smear
        -- stops dead for as long as the smear is on the page, which is a long
        -- time. Freeze is re-applied on every tick, so a stuck enemy stays
        -- stuck until the glue itself fades.
        radius = 14, damage = 0, knock = 0,
        -- Tight spacing relative to the fat tip, or the rim shows up as a row
        -- of overlapping arcs instead of one smooth edge.
        spacing = 2, ink = 1 / 90, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4,
        freeze = 0.55,
        ramp = { Palette.paper },
        stamp = glueStamp,
        edge = { stamp = glueEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
    },
    {
        name = "PUSHPIN",
        icon = "pushpin",
        -- Not a brush: there is no line to draw, so nothing above applies. You
        -- tap and a pin falls on that spot.
        --
        -- The damage is deliberately one short of the toughest thing in the
        -- game (the skull's 12hp), which is the whole design in a number: a pin
        -- clears every blob and bat inside a 41px circle outright, and the tank
        -- is what walks out of the crater -- except that it doesn't walk, it is
        -- stuck to the paper. Kill it and it dies; survive it and you are
        -- pinned. Anything that killed outright would leave the pinning with
        -- nothing to pin.
        --
        -- The pin does not come out and does not fade: one driven through paper
        -- stays in it, looking the way it did going in, for the rest of the run.
        -- Which means the pin is not the timer on its own hold -- the enemy is,
        -- and always was the better place to read it, since a held enemy stops
        -- moving and grows a blue shadow.
        drop = { lands = Pin, radius = 20, damage = 10, freeze = 2.5, life = 2.5 },
        -- Charged per pin, not per pixel: two from a full meter, and about a
        -- second and a half of standing still to earn each one back. It is the
        -- biggest single thing you can do to the page, so it is priced like it.
        ink = 0.45,
    },
    {
        name = "STAPLER",
        icon = "stapler",
        -- Placed, exactly like the pushpin -- you tap and one lands where you
        -- tapped -- and the pin turned inside out in every other respect.
        --
        -- A pin is one big expensive decision: most of half the meter, a
        -- quarter of a second in the air, a 41px crater, and enough damage to
        -- kill everything caught in it but the tank. A staple is a tenth of the
        -- meter, it lands the instant you tap, it reaches 15px and it does 2,
        -- which is a bat and nothing else. It is not an attack, it is a
        -- fastener: it holds one thing to the paper for two seconds, and the
        -- way you use it is to keep tapping.
        --
        -- Ten from a full meter against the pin's two, so the same ink buys
        -- roughly the same page either way -- as one crater you place once, or
        -- as ten fastenings you have to land one at a time on things that are
        -- moving. That is the whole choice the pair offers.
        --
        -- Nothing is telegraphed, because there is nothing to dodge. The pin's
        -- fall is what stops a tap on a moving target being a certainty; a
        -- staple has no fall at all, and what keeps it honest instead is that
        -- hitting barely hurts and the circle is small enough to miss with.
        --
        -- Freeze and life are the same number on purpose, the way they are for
        -- the pin -- life is only how long it is still worth updating, since a
        -- staple never comes out of the paper and never fades. A page you have
        -- worked over stays covered in them.
        drop = { lands = Staple, radius = 7, damage = 2, freeze = 2, life = 2 },
        ink = 0.1,
    },
    {
        name = "RULER",
        icon = "ruler",
        -- Not a brush either, and not placed: aimed. It pivots about the player
        -- while you hold, and lands when you let go.
        --
        -- 200px long against a 15px band -- by a distance the longest reach in
        -- the game, and the narrowest. That is the trade the whole tool is: it
        -- can touch more of the page at once than anything else can, but only
        -- the part of it that happens to line up through you, and you have to
        -- stand there turning it until it does.
        --
        -- The knockback is what it is for. 8 damage clears the chaff, but it is
        -- the shove that matters: everything is thrown clear of the line and
        -- off both sides at once, so a ruler that kills nothing still opens a
        -- corridor across the page through the middle of the horde.
        snap = {
            length = 100, width = 7,
            damage = 8, knock = 210,
            -- The mark left behind is a ruled pencil line and leaves the page
            -- like one.
            life = 1.6, fade = 0.55,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- Cheaper than a pin, because it has to be lined up and the horde does
        -- not wait while you do it: about three from a full meter.
        ink = 0.35,
    },
    {
        name = "COMPASS",
        icon = "compass",
        -- Not a brush, not placed and not aimed: opened. The needle goes into
        -- the page where you press, and how far you drag out of that press is
        -- how wide the circle is. Let go and the leg comes round.
        --
        -- The slowest thing in the game to bring to bear, and the only one
        -- whose hit you can watch travel. Nothing lands on the release: the
        -- lead sets off from wherever you left it and cuts what it passes over
        -- as it arrives there, so the far side of a wide circle has most of a
        -- turn to walk out -- and can see the arm coming the whole way.
        --
        -- It is also the only tool that reaches away from the player, which is
        -- what it is really for: a circle drawn round a crowd you are not
        -- standing in. 7 damage is deliberately over the blob's 4 and under the
        -- skull's 12 -- the biggest area in the game clears chaff and cannot
        -- touch a tank, where the pushpin covers a quarter as much page and
        -- kills everything but one.
        --
        -- The knock is tangential rather than outward, so what the leg catches
        -- is dragged round the circle with it. A horde standing in one comes
        -- out of it stirred rather than scattered; scattering is the ruler's
        -- job, and a compass that did the same thing would be a round one.
        sweep = {
            minR = 16, maxR = 54,
            damage = 7, knock = 130,
            turn = 0.8,   -- seconds for a turn's worth of arm, however it is spent
            -- The three the upgrade line moves, written here at the values that
            -- mean "off" so the levels can read as one assignment each. What
            -- they buy is all measured in that one turn's worth: a lap and a
            -- half costs half again as long to land, and a second leg closes a
            -- lap in half the time because the two of them share it. The bite
            -- is the only part of the circle you get to aim, and it starts
            -- wherever you left the leg resting.
            laps = 1, bite = 1, biteArc = math.pi / 3, counter = false,
            -- What it leaves behind is a ruled pencil circle, and it goes off
            -- the page like one.
            life = 2.2, fade = 0.5,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- Between a ruler and a pin: two and a half from a full meter. It
        -- reaches further across the page than anything else and takes the
        -- longest to land, and both of those are in the price.
        ink = 0.4,
    },
}

-- Off the strip for now. Nothing here is broken -- it is a whole tool, drawn
-- and balanced -- it is just not on the column at the moment. Move a row back
-- into Tools.list above and it is a tool again; nothing else in the game knows
-- the difference, because nothing addresses a tool by name or by index.
Tools.shelved = {
    {
        name = "CRAYON",
        icon = "crayon",
        -- Wax: the only mark that does nothing to an enemy's health at all.
        -- It is a surface. You move half again as fast along it, and anything
        -- chasing you loses its footing on it -- it keeps the heading it came
        -- in with and can only turn slowly, so it slides straight past you and
        -- has to come back round. Cheap per pixel, because a lane is only
        -- worth having if it is long enough to run down.
        radius = 6, damage = 0, knock = 0,
        spacing = 2, ink = 1 / 200, life = 7,
        slick = { boost = 1.75, turn = 0.8 },
        ramp = { Palette.sky },
        fade = 0.7,
        stamp = crayonStamp,
        -- A broken outline: wax piles up unevenly against the paper rather
        -- than ruling a clean border, and a continuous one made the band read
        -- as a user-interface capsule instead of something drawn.
        edge = { stamp = crayonEdge, color = Palette.blue, rough = 0.4 },
        holes = { stamp = crayonHoles, color = Palette.paper, rough = 0.25 },
        speck = { chance = 0.06, color = Palette.blue }, -- flakes of wax
    },
}

-- The three blocks that turn a tool into something other than a brush. Named
-- here because two other things have to walk them: the copy below, and the
-- upgrade that sharpens every damage number a run owns (src/loadout.lua).
Tools.BLOCKS = { "drop", "snap", "sweep" }

-- A tool a run can change its mind about.
--
-- These rows are shared by every run the program plays, and upgrades move the
-- numbers in them -- the ruler grows, the scissors sharpen everything you draw
-- -- so a run works from copies rather than from the rows themselves and hands
-- those copies out through Loadout:tool. What is copied is what carries
-- numbers; ramps, stamps and the module a drop lands as are read-only, and are
-- shared.
function Tools.copy(tool)
    local out = {}
    for k, v in pairs(tool) do out[k] = v end

    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block then
            local copy = {}
            for k, v in pairs(block) do copy[k] = v end
            out[name] = copy
        end
    end

    return out
end

-- The tool as it was written down, which is what the selector draws and what a
-- run's copy starts from. Anything reading a tool's *numbers* mid-run wants
-- Loadout:tool instead: this one has never heard of an upgrade.
function Tools.get(index)
    return Tools.list[index]
end

return Tools
