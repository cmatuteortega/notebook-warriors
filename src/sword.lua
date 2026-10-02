-- The sword an arc gets swung with.
--
-- The shot it stands against (src/shot.lua) is a point leaving you: one enemy,
-- one pellet, a third of the page away, and it never asks you to be anywhere.
-- This is the other end of that -- an arc turned through the crowd at arm's
-- length, cutting everything standing in it for twice the damage. The whole
-- weapon is that trade written once: you have to be inside the thing that is
-- trying to touch you, and being there is worth double.
--
-- Both of them are passive weapons like any other now (src/upgrades.lua,
-- src/loadout.lua), where they used to be the two halves of one clock inside
-- src/player.lua. The swordsman opens a run with this line at level one the way a
-- lesson opens one holding a tool, and anybody else can draft it -- so a shootman
-- who takes this card has a shot *and* an arm, which is the whole reason the two
-- were pulled out of the hero in the first place.
--
-- It is not aimed by hand. Like the shot, it goes at the nearest thing in range
-- and on a clock of its own, so a run holding it plays the way a run without it
-- does -- walking and drawing -- and what it decides is how close to stand.
-- Nothing here is a button.
--
-- Four things about the swing are worth knowing before changing one.
--
-- **It is swept, not stamped.** The arc is walked over `TIME` and each frame cuts
-- the wedge it has just crossed, with a `struck` set so nothing is cut twice by
-- one swing -- the beam's rule (src/beam.lua). A swing that resolved on its first
-- frame would be a disc of damage with an animation played over the top of it,
-- and the thing that makes this weapon readable is that the blade reaches the far
-- side of the arc *later* than the near side.
--
-- **The pivot is live.** The wedge is measured off where the player is this
-- frame, not where he was when the arm went, so a swing carries with you while
-- you walk out of the crowd you are cutting. A swing anchored to the ground would
-- be the one thing in this game you had to stand still for.
--
-- **The arc that flashes is the arc that killed.** The trail is drawn at exactly
-- the block's `reach` and covers exactly the part of the sweep that has already
-- been tested, which is the bomb's rule (src/bomb.lua): a reach nobody can see is
-- a reach nobody can learn.
--
-- **The geometry is the line's, and it did not used to be.** `reach` and `sweep`
-- are on the block (src/upgrades.lua) rather than being constants here, because
-- what this line sells is the arc: a longer arm, then a wider turn, then the whole
-- circle. That is the opposite of the shot's line, which sells four numbers and no
-- shape at all, and it is the right way round -- an arc is all shape, and a
-- weapon whose levels only sharpened it would be a shot you had to stand next to.
-- What is *not* on the block is `TIME`: how long the arm is out is the half of
-- this weapon you play, so a wider sweep is a faster edge rather than a longer
-- wait, and the whole circle is a spin rather than a pose.
--
-- The blade is a drawing (src/design.lua) and it is the second thing in the game
-- kept at eight headings, the rocket being the first. It is held rather than
-- flown, so its board is 3 wide and 8 tall and drawn *point up* rather than
-- nose-right -- see POINT_UP.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local util = require("src.util")

local Sword = {}
Sword.__index = Sword

local TWO_PI = math.pi * 2
local EIGHTH = math.pi / 4

-- The blade's own length, in pixels, which is the board's height and nothing
-- else: the drawing is 3x8 (src/design.lua), so the sword is 8 long however
-- anybody fills it in. It is here so that `hold` below can be a measurement
-- rather than a number -- the one thing in this file that has to agree with the
-- art.
local BLADE = 8

-- How far out the middle of the blade rides, given how far the edge cuts. It is
-- `reach` less half the drawing's own length rather than a number of its own: at
-- a reach of 17 the blade covers 9 to 17 out and its *point* lands exactly on 17.
-- That is what lets the trail be drawn at `reach` and still read as the path the
-- point took -- the arc you can see and the arc that cuts are the same arc, which
-- is the bomb's ring by another name. The level that lengthens the arm moves this
-- with it and says nothing about it.
local function holdFor(reach)
    return reach - BLADE / 2
end

-- How long one swing takes, whatever it covers, and the one piece of the arc's
-- geometry that is not on the block. It is about a fifth of the gap between
-- swings, so the arm is down far longer than it is out -- which is the half of
-- the weapon you play, and the reason no level may touch it: a level that bought
-- a wider arc by holding the arm out longer would be selling you a slower weapon
-- in the shape of a bigger one. A wider `sweep` is a faster edge instead, and
-- the last level of the line is a spin rather than a pose because of it.
local TIME = 0.16

-- The leading stretch of the trail, drawn in the brighter blue -- what the edge
-- is doing this instant against what it has already done. Two colours rather
-- than a fade, because a fade is alpha and there is none in this game.
local LEAD = 0.5

-- How far past the reach the circle asked of the horde goes, so that a body whose
-- middle is outside the arc but whose edge is plainly under the blade is still
-- offered to the test. The widest body in the crowd is the eye boss at 20, and
-- this is only the prefilter -- what actually widens the wedge is each enemy's own
-- radius, in distance and (converted per enemy, since the same body is a wider
-- wedge the closer it stands) in angle.
local SLACK = 20

-- The eighth of the ring the drawing sits at when it points straight up.
--
-- Everything else in the game with a heading is drawn nose-right and read
-- straight out of `Sprites.turned` (see src/design.lua), and this is the one
-- exception: a sword is *held*, so what anybody draws on a 3x8 board is a sword
-- standing on its pommel with the point at the top. The ring is still turned
-- clockwise from the art as drawn, so pointing it anywhere is that turn plus the
-- two eighths the art is already round -- one constant, here, rather than a
-- board nobody would draw a sword on.
local POINT_UP = 2

-- The drawing at the heading nearest `angle`. The sprite is one of eight, which
-- is what keeps it a whole-pixel drawing rather than something sampled at an
-- angle mid-swing; the *cut* is at whatever angle the sweep is actually at, so
-- the blade is a picture of the swing rather than the swing itself.
local function bladeAt(angle)
    local ring = Sprites.turned.sword
    local e = (math.floor(angle / EIGHTH + 0.5) + POINT_UP) % 8
    return ring[e + 1]
end

function Sword.new()
    return setmetatable({
        -- The block the upgrade line built: how far off it will go for
        -- something, how often, what the cut is worth, how far and how wide the
        -- arc turns, and what a survivor is shoved with. `TIME` is the one piece
        -- of the swing that stays a constant here -- see it.
        def = nil,
        timer = 0,
        live = false,
        t = 0,
        -- Every angle below is *unwrapped* -- measured off `from` and allowed to
        -- run past a whole turn rather than being folded back into (-pi, pi].
        -- That is what lets the last level of the line be a full circle: a sweep
        -- of 2pi folded down is a sweep of nothing, and an arc's ends are the
        -- same angle the moment it closes. There used to be a signed `delta`
        -- here folding every comparison into (-pi, pi] and it had to go with the
        -- wrapping: plain subtraction is right once everything comes off one
        -- base, and it is right for a span of any size.
        from = 0,   -- where this swing started
        run = 0,    -- and how far round it goes from there, signed
        angle = 0,  -- where the edge is this instant
        cut = 0,    -- and how far the tested wedge has got, which trails it by a
                    -- frame at most: this is what the trail is drawn from
        struck = {},
        damage = 0,
        -- Which way the last one went. Alternating rather than always clockwise:
        -- an arm that returns is what a second swing looks like, and it costs
        -- nothing but this flag.
        back = false,
    }, Sword)
end

function Sword:configure(def)
    self.def = def
end

--- swinging -------------------------------------------------------------------

-- One swing, at something.
--
-- The damage is handed in rather than read here so that a swing keeps it for its
-- whole length, the way a rocket keeps what it was fired with: an upgrade taken
-- while the arm is out lands on the next one rather than half way through this
-- one.
function Sword:swing(game, target, damage)
    local player = game.player
    local aim = math.atan2(target.y - player.y, target.x - player.x)

    self.back = not self.back
    local sweep = self.back and -self.def.sweep or self.def.sweep

    self.live = true
    self.t = 0
    -- Centred on the aim, so a swing takes what it was sent at half way through
    -- rather than at one end. At a sweep of 2pi that is the whole page around
    -- you and the aim only decides where the spin starts, which is the level
    -- doing exactly what it says.
    self.from = aim - sweep / 2
    self.run = sweep
    self.angle = self.from
    self.cut = self.from
    self.struck = {}
    self.damage = damage
end

-- Everything standing in the wedge between where the edge was and where it is
-- now, once each.
--
-- `eachWithin` rather than the spatial hash, for the sun's reason and the bomb's:
-- what is being asked about is ground rather than a point, and the nine 12px
-- cells `eachNear` looks in do not cover a 17px reach, let alone the 24 the line
-- sells. It is affordable because a swing is ten frames long and there is one of
-- them every half second or so.
--
-- Both angles are unwrapped and come off the same base (see `Sword.new`), so the
-- span between them is a plain subtraction and may be anything up to a whole
-- turn. What is folded into a circle is only each *body's* bearing, and it is
-- folded forwards -- into [0, 2pi) off the near edge of the wedge -- rather than
-- into (-pi, pi] off its middle, which is the whole of why a full circle needs no
-- clause of its own here: once the wedge and its slack come to a turn, nothing is
-- outside it and everything in reach is cut.
function Sword:cutWedge(game, from, to)
    local player = game.player
    local px, py = player.x, player.y
    local reach = self.def.reach

    local run = to - from
    if run == 0 then return end
    -- Walked from whichever end came first, so there is one direction below. The
    -- wedge is the same wedge either way round; only which end the edge started
    -- at differs, and that is the trail's business rather than the damage's.
    if run < 0 then from, run = to, -run end

    game:eachWithin(px, py, reach + SLACK, function(e)
        if self.struck[e] then return end

        local dx, dy = e.x - px, e.y - py
        local dist = util.len(dx, dy)
        if dist > reach + e.radius then return end

        -- A body is a wedge rather than a point, and a wider one the closer it
        -- stands. Anything overlapping the pivot is in every direction at once.
        local slack = dist > e.radius and math.asin(e.radius / dist) or math.pi

        -- Forwards off the near edge. Inside is `off <= run`; the slack either
        -- side is the two ends, the near one reached by coming the long way round
        -- past a whole turn.
        local off = (math.atan2(dy, dx) - from) % TWO_PI
        if off > run + slack and off < TWO_PI - slack then return end

        self.struck[e] = true
        game.particles:burst(e.x, e.y, 2, Palette.red)
        if e:hurt(self.damage) then
            game:killEnemyAt(e)
        elseif self.def.knock > 0 then
            -- Shoved only if it lived through it, which is the level exactly as
            -- it is written on the card. A push is bought time and time is worth
            -- nothing against something already dead -- and it is the corpse's
            -- own particles and damage number that say a swing landed, so a
            -- shove there would be the one bit of feedback the page did not
            -- need. Handed over rather than applied, the spiral's way (the
            -- weapons are stepped after the crowd has already moved), and
            -- through `stats.knock` because a shove is a shove whatever threw
            -- it.
            local nx, ny = util.normalize(dx, dy)
            e:knockback(nx, ny, self.def.knock * game.loadout.stats.knock)
        end
    end)
end

-- The clock, and then whatever the arm is part way through.
--
-- The two are stepped in that order and independently: a swing takes about a
-- fifth of the gap between swings (see TIME), so the arm is down far longer than
-- it is out and the clock never lands on a swing already in the air. If a level
-- ever shortens the gap far enough that it does, the new swing simply takes over
-- -- which is what a faster arm looks like.
function Sword:update(dt, game)
    local def = self.def
    local player = game.player

    self.timer = self.timer - dt
    if self.timer <= 0 then
        local target = game:nearestEnemy(player.x, player.y, def.range)
        if target then
            -- A passive weapon is what graphite sharpens, and the global
            -- multiplier lands on everything.
            local stats = game.loadout.stats
            self:swing(game, target,
                def.damage * stats.passiveDamage * stats.damage)
            -- Straight off the block: what the metronome does to the beat, it
            -- did to the block itself (`scaleCadence` in src/loadout.lua).
            self.timer = def.every
        else
            -- Nothing in reach: the beat is held rather than spent, so walking
            -- into a crowd is answered on the spot rather than half a second
            -- late. src/shot.lua's LOOK by another name.
            self.timer = 0.05
        end
    end

    if not self.live then return end

    self.t = self.t + dt
    local at = util.clamp(self.t / TIME, 0, 1)
    self.angle = self.from + self.run * at

    self:cutWedge(game, self.cut, self.angle)
    self.cut = self.angle

    if self.t >= TIME then self.live = false end
end

--- drawing --------------------------------------------------------------------

-- The blade, and the arc it has been through. Drawn over the crowd (see the draw
-- order in src/game.lua): a swing you cannot see behind the blob it is cutting is
-- a swing you cannot time, which is the pin's argument and matters more here --
-- this is the one thing on the page telling you whether you are standing close
-- enough.
function Sword:draw(game)
    if not self.live then return end

    local player = game.player
    -- A swing is an arm coming off a hero, and a dead run's hero is not drawn
    -- (Game:draw). Nothing updates a dead run either, so a swing caught mid-air
    -- by the frame you died would otherwise hang there for ever over nobody.
    if player.hp <= 0 then return end
    local px, py = player.x, player.y
    local reach = self.def.reach
    local run = self.cut - self.from
    -- Half a pixel of arc a step. A whole pixel is what the arc *is* and leaves
    -- holes in it anyway once both coordinates are floored, and this is thirty
    -- rectangles rather than fifteen -- two hundred rather than a hundred once
    -- the line has bought the whole circle, which is the beam's order of work on
    -- ten frames in every fifty.
    local step = (run >= 0 and 1 or -1) / (reach * 2)

    -- One pixel per pixel of arc, plotted rather than lined: a ring drawn with
    -- love.graphics would be a polygon at whatever sub-pixel positions the maths
    -- landed on, and everything on this page is on the grid.
    local i = 0
    while math.abs(i * step) <= math.abs(run) do
        local a = self.from + i * step
        -- Plain subtraction: `a` and `cut` are both unwrapped off `from`, so the
        -- last half-radian of a full circle is half a radian behind the edge
        -- rather than a turn and a half ahead of it.
        local lead = math.abs(a - self.cut) <= LEAD
        love.graphics.setColor(lead and Palette.blue or Palette.sky)
        love.graphics.rectangle("fill",
            math.floor(px + math.cos(a) * reach),
            math.floor(py + math.sin(a) * reach), 1, 1)
        i = i + 1
    end

    local hold = holdFor(reach)
    love.graphics.setColor(1, 1, 1)
    bladeAt(self.angle):draw(px + math.cos(self.angle) * hold,
        py + math.sin(self.angle) * hold)
end

return Sword
