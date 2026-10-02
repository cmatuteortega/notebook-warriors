-- The birds that fly about you.
--
-- The eleventh passive weapon, and the one that answers a question the other
-- eleven do not: everything else on the page happens on a beat. A star comes
-- round, a rocket goes up, a bomb goes off, a cloud arrives -- each of them is an
-- *event* you learn the rhythm of. A flock is not an event. It is a handful of small
-- things milling about where you are, all the time, taking a pixel off whatever
-- they brush past, and what a run buys with the first level of this line is not a
-- number worth having but the shape of one: one bird nicking one point off one
-- thing is the smallest attack in the game, and the line is five levels of there
-- being *more of it*.
--
-- Which makes it the star's opposite twin rather than another orbit, and that is
-- the one thing about this weapon worth protecting. A star is on a *ring*: it has
-- an angle, the angle advances, and where it will be in a second is a thing you
-- could work out. Nothing here has an angle at all. A bird picks somewhere near
-- the flock to be, flies at it, turns as fast as a bird turns and picks somewhere
-- else when it arrives -- so what it draws on the page is a path rather than a
-- circle, and no two of them are drawing the same one. The flock's own centre is
-- only *chasing* you (`CHASE`) on top of that, so the whole loose knot of them
-- swings wide of a corner and folds back over you when you stop.
--
-- What is left of going round you is a lean rather than a sweep: each bird steps
-- its next goal round the flock from the last one, usually the way it leans
-- (`turn`), with half the flock leaning each way -- and one step in four goes the
-- other way anyway (`REVERSE`). That last part is the one that matters. A drift
-- that only ever went one way comes all the way round in the end, and then the
-- *envelope* of the path is a ring however scattered the points on it were; a bird
-- that doubles back every so often is a bird changing its mind, and there is no
-- ring left in it. Which is the whole point of the exercise, since the game
-- already has the best version of a ring in it.
--
-- Two levels change what it *is* rather than how much of it there is. The fourth
-- puts a couple of the birds to work: a carrier breaks off, flies out to
-- a gem lying too far off for the magnet to have noticed, taps it, and the gem
-- comes home (`Flock:hauls`, asked by Game:updateGems, which is the skate's
-- magnet level handed over the same way -- as a *reach* rather than as a second
-- kind of pull, so a fetched gem sets off and snaps in exactly like every other
-- one). The fifth is the room rather than the count: a bird may be sent anywhere
-- from the hero's own feet to the edge of a flock half again as wide, so fourteen
-- of them are a cloud you are standing inside where five were something following
-- you about.
--
-- The bird is drawn by the player (src/design.lua) -- seven pixels of the doodle
-- everybody puts in the corner of a page. It never turns: it is flying round you
-- at every angle there is, and an m has no front.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local util = require("src.util")

local Flock = {}
Flock.__index = Flock

local TWO_PI = math.pi * 2

-- How hard the flock's centre chases the player, in fractions a second, and it is
-- deliberately soft: at 4.2 a run walking flat out drags the middle of the flock
-- about fourteen pixels behind him, so the birds trail, swing wide of a corner and
-- pile back over him when he stops. It is soft rather than softer because the lag
-- compounds -- a bird spends part of its speed on turning, so it sits behind a
-- centre that is itself behind you -- and a flock strung out fifty pixels back is
-- a weapon that has stopped reaching anything (see `LEASH`).
local CHASE = 4.2

-- How fast a bird may swing its heading round, in fractions a second. This is
-- what makes the flight read as flying: a bird handed somewhere new to be does
-- not set off towards it, it *banks* towards it, and speed over turn rate is the
-- radius of that curve -- a hundred over ten is ten pixels, so a bird changing its
-- mind carves a bird-sized arc rather than a corner.
local TURN = 10

-- How long a bird will keep flying at one goal, and how close counts as arrived.
-- Between them these are the length of a swoop: at a bit under a second a bird
-- crosses most of the flock before it thinks again, and arriving early is what
-- keeps a short hop short rather than leaving it circling a point it has reached.
local HOLD_MIN, HOLD_MAX = 0.45, 1.1
local ARRIVE = 5

-- How far round the flock a bird steps its next goal from its last one, in
-- radians. Never a fresh angle out of the hat: a random point every time is a
-- bird bouncing about inside a disc, and what this wants is a bird *going*
-- somewhere -- a third to two thirds of the way round, usually the way this bird
-- leans, which is a drift rather than an orbit.
local SWING_MIN, SWING_MAX = 0.7, 2.1

-- And how often it steps the other way instead. A quarter, which is what keeps
-- the drift from closing into a loop: a bird that only ever stepped one way
-- eventually comes all the way round and the *envelope* of its path is a ring,
-- however scattered the points on it were. One doubling back in four is a bird
-- changing its mind, and there is no ring left in it.
local REVERSE = 0.25

-- What a carrier does instead: a straight line at a flat speed, since it has
-- somewhere to be. Comfortably faster than the player, or a bird sent to fetch
-- something behind you would never catch either the gem or the flock again.
local FLY = 115

-- How close it has to get to have it, how close it stops banking and goes
-- straight in, and how far off it will go looking. The reach is generous -- most
-- of a screen -- because what the level sells is the xp you were never going to
-- walk back for.
--
-- The leash below is the other measured one, and it is what stops a flock
-- becoming a queue. A banked bird spends some of its speed on turning, so one
-- wandering behind a walking run loses ground even though it flies faster than
-- the run does -- and fifty pixels back is a weapon that has stopped touching
-- anything near you. Past this much of the block's reach a bird gives up flying
-- prettily and goes straight at its goal, which it can always win, since the
-- slowest bird in the flock is quicker than the fastest the player can be made.
--
-- The landing distance is the one that has to be right rather than chosen: a
-- banked turn has a radius (speed over `TURN`, about fourteen pixels for a
-- carrier), and a bird that arrives at a gem across that turn would circle it for
-- ever without ever closing the last five pixels. So it stops flying like a bird
-- once it is a couple of body lengths off and takes the thing -- which is what
-- landing looks like anyway, and which is *guaranteed* to close as long as this is
-- comfortably outside that radius.
local GRAB = 5
local LAND = 20
local LEASH = 1.7
local FETCH = 150

-- How often a carrier with nothing to fetch looks again. A beat rather than
-- every frame, on the shot's terms: a walk of the gems on the page is cheap but
-- there is no reason to do it sixty times a second.
local LOOK = 0.3

-- The bird's own half-width, and it is the *grid's* rather than the drawing's --
-- the pellet's rule (see Sprites.SHOT). A bird is seven across, so this is three,
-- and filling in the empty bottom row of the board changes what a bird looks like
-- and never what it touches.
local HIT_R = 3

-- One bird. What makes it itself is a hash of its index rather than a roll, so a
-- flock is stable across a rebuild -- taking the next level of the line adds birds
-- to the end of the list and leaves the ones already up exactly as they were,
-- which is the same promise the orbit makes about its angle.
local function newBird(i)
    return {
        -- A fraction of the block's speed rather than a speed of its own: the
        -- block is what the levels move, and a flock where every bird flew at the
        -- same rate would be a formation again.
        rate = 0.85 + util.hash01(i, 2, 5) * 0.35,
        -- Which way round the flock it tends to work, and it never changes: this
        -- is the whole of what is left of going round you, and it is worth half
        -- the flock leaning each way.
        turn = util.hash01(i, 3, 5) < 0.5 and -1 or 1,
        wob = util.hash01(i, 4, 5) * TWO_PI,
        -- Filled in by Flock:settle, since there is nowhere to put a bird until
        -- there is a player to put it near: where it is, the way it is pointing,
        -- and where it is going -- the last of those as an offset from the flock's
        -- centre rather than as a point on the page (see Flock:wander).
        x = nil, y = nil,
        hx = 0, hy = 0,
        ox = nil, oy = nil, hold = 0,
        -- A carrier's errand, and the beat it looks for one on.
        gem = nil,
        look = 0,
        -- What this bird has already nicked and when. Per bird rather than shared
        -- across the flock, which is the one place this differs from the orbit on
        -- purpose: three stars on one ring sweep the same crowd as one pass, so
        -- they share a list; fourteen birds milling about are fourteen separate
        -- things happening to you, and sharing it would make the swarm level
        -- worth nothing at all. Weak keys, since a run kills thousands of things
        -- and this table outlives every one of them.
        hit = setmetatable({}, { __mode = "k" }),
    }
end

function Flock.new()
    return setmetatable({
        def = nil,
        birds = {},
        -- Where the flock is, as opposed to where the player is.
        cx = nil, cy = nil,
        -- The gems a carrier has tapped. Weak keys for the hit list's reason: a
        -- gem that has been picked up is gone, and nothing here should be what
        -- remembers it.
        hauled = setmetatable({}, { __mode = "k" }),
    }, Flock)
end

function Flock:configure(def)
    self.def = def

    -- Grown and shrunk rather than rebuilt, so a bird already in the air keeps
    -- where it is, where it was going and how fast it gets there when the line is
    -- taken another level. Nothing in the catalogue takes birds away; the second loop
    -- is here so that retuning one that did would not leave a ghost flying.
    for i = #self.birds + 1, def.count do
        self.birds[i] = newBird(i)
    end
    for i = #self.birds, def.count + 1, -1 do
        self.birds[i] = nil
    end
end

--- flying --------------------------------------------------------------------

-- Somewhere to be, for a flock that has not flown yet.
--
-- Both ends of the frame go through here and the draw needs it as much as the
-- update does, which is not belt and braces: a weapon is configured the moment
-- its level is taken, and a level is taken with the run *held* -- the draft's
-- cards are laid over a page that is still being drawn behind them, so the first
-- thing that ever happens to this flock is being drawn. A bird with no position
-- yet is put straight where it was going rather than at the player, so a level
-- taken mid-run puts the new birds out in the flock instead of streaming them all
-- out of the hero at once.
function Flock:settle(game)
    if not self.cx then
        self.cx, self.cy = game.player.x, game.player.y
    end
    for i, b in ipairs(self.birds) do
        if not b.ox then self:wander(b, i) end
        if not b.x then
            b.x, b.y = self.cx + b.ox, self.cy + b.oy
            -- Pointing the way it will be going in a moment, so a fresh bird does
            -- not spend its first half second turning round.
            b.hx, b.hy = util.normalize(-b.ox, -b.oy)
        end
    end
end

-- Somewhere new to be, as an offset from the flock's centre.
--
-- Kept as an offset rather than as a point on the page, and that is not a detail:
-- a goal is somewhere *near you*, so it walks with you. Stored absolutely, a bird
-- would keep flying at the spot you were standing in when it set off, and a flock
-- following a run across the page would string out into a queue.
--
-- The angle is stepped on from where the bird is now rather than drawn fresh, by
-- a third to two thirds of a turn, always the way this bird leans. What that
-- gives is a bird crossing the flock and coming round -- a path, at a different
-- radius every time, out of step with every other bird -- where a fresh angle
-- would give a fly in a jar and a fixed step would give the ring this weapon
-- exists not to be.
--
-- `spread` is what the level buys: at a quarter a bird stays out in a loose shell
-- around you, and near one it may be handed anywhere from your own feet to the
-- edge of the flock, which is what turns a ring of birds into a swarm.
function Flock:wander(b, i)
    local def = self.def
    local from

    if b.ox and (b.ox ~= 0 or b.oy ~= 0) then
        from = math.atan2(b.oy, b.ox)
    else
        -- Nothing to step on from yet, so the index picks the first one and the
        -- flock opens spread out rather than in a line.
        from = util.hash01(i or 1, 1, 5) * TWO_PI
    end

    local way = b.turn
    if love.math.random() < REVERSE then way = -way end

    local a = from + way * (SWING_MIN + love.math.random() * (SWING_MAX - SWING_MIN))
    local r = def.reach * (1 - def.spread * love.math.random())

    b.ox, b.oy = math.cos(a) * r, math.sin(a) * r
    b.hold = HOLD_MIN + love.math.random() * (HOLD_MAX - HOLD_MIN)
end

-- The gem this carrier is on its way to, if it has one worth having. Nil is not
-- a failure -- most of the time there is nothing out there, and a carrier with
-- nothing to fetch is an ordinary bird flying loose.
--
-- Anything already inside the magnet is left alone: it is coming to you anyway,
-- and a bird sent to collect what was arriving would be the level doing nothing
-- while looking busy. What it is for is the gem lying where you killed something
-- and then walked away from.
function Flock:fetch(b, dt, game)
    if b.gem and (b.gem.dead or self.hauled[b.gem]) then b.gem = nil end
    if b.gem then return true end

    b.look = b.look - dt
    if b.look > 0 then return false end
    b.look = LOOK

    local magnet = game.loadout.stats.magnet
    local player = game.player
    local best, bestD

    for _, g in ipairs(game.gems) do
        local home = util.len(g.x - player.x, g.y - player.y)
        if not self.hauled[g] and home > magnet then
            local d = util.len(g.x - b.x, g.y - b.y)
            if d <= FETCH and (not bestD or d < bestD) then
                best, bestD = g, d
            end
        end
    end

    b.gem = best
    return best ~= nil
end

-- Whether xp lying here is on its way to you because a bird went and got it.
-- Asked by Game:updateGems through Loadout:flock, exactly as the skate's trail
-- is asked whether a gem is lying on it: what is handed back is a *reach*, so
-- everything about the way a gem travels stays in one place.
--
-- Tapped once and coming home for good. A carrier that flew back out to shepherd
-- its gem the whole way in would be a bird doing the magnet's job slowly, and the
-- moment it is tapped there is nothing left for it to decide.
function Flock:hauls(gem)
    return self.hauled[gem] == true
end

function Flock:update(dt, game, grid)
    local def, player = self.def, game.player
    local stats = game.loadout.stats

    self:settle(game)
    local chase = 1 - math.exp(-CHASE * dt)
    self.cx = self.cx + (player.x - self.cx) * chase
    self.cy = self.cy + (player.y - self.cy) * chase

    -- A passive weapon is what graphite sharpens, and the global multiplier lands
    -- on everything.
    local damage = def.damage * stats.passiveDamage * stats.damage
    local turn = 1 - math.exp(-TURN * dt)

    for i, b in ipairs(self.birds) do
        b.wob = (b.wob + dt * 6) % TWO_PI

        -- Where this one is trying to be, and how fast it is allowed to get
        -- there. Two answers and one flight: an errand is a goal like any other,
        -- so a carrier banks towards its gem the way every other bird banks
        -- towards the flock rather than sliding at it in a straight line.
        --
        -- The first `carriers` birds are the ones that run errands, so a level
        -- that adds more of them puts the new ones out in the flock and leaves the
        -- errand-runners where they were.
        local gx, gy, speed

        if i <= def.carriers and self:fetch(b, dt, game) then
            gx, gy, speed = b.gem.x, b.gem.y, FLY
        else
            -- Arrived, or has been at it long enough to think again. The hold is
            -- what stops a bird that has just missed its goal by a pixel spending
            -- the next second circling it.
            b.hold = b.hold - dt
            local dx, dy = self.cx + b.ox - b.x, self.cy + b.oy - b.y
            if b.hold <= 0 or dx * dx + dy * dy <= ARRIVE * ARRIVE then
                self:wander(b, i)
            end
            gx, gy = self.cx + b.ox, self.cy + b.oy
            speed = def.speed * b.rate
        end

        -- Banked rather than steered: the heading chases the direction of the
        -- goal and the bird goes wherever the heading points, which is what puts
        -- a curve in the path instead of a corner. A bird sitting exactly on its
        -- goal keeps the heading it had, since there is no direction in no
        -- distance.
        --
        -- Two things are flown straight rather than banked: the last of an errand
        -- (`LAND`) and the way home for a bird that has been left behind
        -- (`LEASH`). A wandering bird that overshoots is a bird circling a spot
        -- for a moment and then thinking of somewhere else, which is what a flock
        -- does -- but a carrier circling a gem is a level that never pays out, and
        -- a bird strung out behind a run is a weapon that has stopped reaching
        -- anything.
        local dx, dy, d = util.normalize(gx - b.x, gy - b.y)
        if dx ~= 0 or dy ~= 0 then
            local far = util.len(b.x - self.cx, b.y - self.cy) > def.reach * LEASH
            if far or (b.gem and d <= LAND) then
                b.hx, b.hy = dx, dy
            else
                b.hx, b.hy = util.normalize(b.hx + (dx - b.hx) * turn,
                                            b.hy + (dy - b.hy) * turn)
            end
        end

        b.x, b.y = b.x + b.hx * speed * dt, b.y + b.hy * speed * dt

        -- And the errand is finished by arriving rather than by the goal being
        -- reached, since a gem walks nowhere and the bird is the only thing
        -- moving.
        if b.gem and util.len(b.gem.x - b.x, b.gem.y - b.y) <= GRAB then
            self.hauled[b.gem] = true
            b.gem = nil
        end

        -- What it clipped on the way past. The nine cells the hash looks in are
        -- the whole of what a seven-pixel bird can reach, so this asks the grid
        -- rather than the horde -- a bullet's bargain, taken by every bird every
        -- frame, which is what the smallness of the numbers pays for.
        game:eachNear(grid, b.x, b.y, function(e)
            local dx, dy = e.x - b.x, e.y - b.y
            local reach = HIT_R + e.radius
            if dx * dx + dy * dy >= reach * reach then return end

            local last = b.hit[e]
            if last and game.time - last < def.rehit then return end
            b.hit[e] = game.time

            game.particles:burst(e.x, e.y, 1, Palette.red)
            if e:hurt(damage) then
                game:killEnemyAt(e)
            end
        end)
    end
end

--- drawing -------------------------------------------------------------------

-- Up with the weapons rather than down on the page: a bird is over the paper and
-- over the crowd, which is the star's place in the order and for the star's
-- reason -- it is attached to you, and what it is doing is only legible while
-- you can see it against what it is doing it to.
--
-- The one pixel of flap is the drawing lifting off its own baseline on half of
-- its breath, which is the gem's bob and the hero's walk by the same trick: one
-- whole pixel, never a fraction of one, and never a second sprite.
function Flock:draw(game)
    self:settle(game)

    love.graphics.setColor(1, 1, 1)
    for _, b in ipairs(self.birds) do
        Sprites.bird:draw(b.x, b.y - (math.sin(b.wob * 2) >= 0 and 1 or 0))
    end
end

return Flock
