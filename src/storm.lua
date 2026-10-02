-- Passive weapon: a cloud drifts in off the page edge, parks over one enemy
-- picked at random (Game:randomEnemyIn), then bolts it and everyone in a circle
-- round it. It follows its mark in, so the bolt cannot miss; the circle can be
-- walked out of.

local Camera = require("src.camera")
local Palette = require("src.palette")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")
local util = require("src.util")

local Storm = {}
Storm.__index = Storm

local TWO_PI = math.pi * 2

-- Wait between the cloud stopping and the bolt, so nothing is hit without being
-- shown where. No level scales it; at the player's 58px/s it is just enough to
-- walk out of a 12px circle.
local GATHER = 0.45

-- How long the bolt is on the page, and how long one flash lasts: two lit beats
-- and two dark, which reads as lightning rather than a sprite that appeared.
local STRIKE = 0.3
local FLICKER = 0.055

-- The cloud's flicker while gathering, at half the strike's speed.
local FILL = 0.11

-- How long a struck enemy wears its blue outline (Enemy:shock). A readout, not
-- a state -- long enough to still be there when you look back.
local SHOCK = 1

-- Smallest a zap may be worth and still be passed on. The chain has no hop
-- limit (`chain` in src/upgrades.lua); falloff plus this floor ends one.
local MIN_ZAP = 1

-- How far a cloud will go for its next mark once it has struck and has bolts
-- left. Short, so that level buys lingering over a crowd rather than travel.
local LINGER = 90

-- Retry wait when there is nowhere to send a cloud (empty or full page), so a
-- run does not lose its first bolt to a page that was empty on the beat.
local LOOK = 0.25

-- Bolt drawn so its point lands on the strike, cloud so its belly is at the
-- bolt's head. Struck off the drawings: a longer bolt hangs its cloud higher.
local function boltY(sy)
    local bolt = Sprites.lightning
    return sy - bolt.h + bolt.oy + 1
end

local function hoverY(sy)
    local bolt, cloud = Sprites.lightning, Sprites.cloud
    return sy - bolt.h - cloud.h + cloud.oy + 1
end

-- Clouds allowed at once -- a level, not a constant (`clouds` in
-- src/upgrades.lua). A launch over the cap is held, not spent (Storm:update).
function Storm:cap()
    return self.def.clouds
end

function Storm.new()
    return setmetatable({
        def = nil,
        cool = 0,    -- 0, so taking the level sends one in at once
        live = {},
    }, Storm)
end

function Storm:configure(def)
    self.def = def
end

--- rolling in ----------------------------------------------------------------

-- Somebody worth striking: one enemy at random from those in the viewport --
-- nothing may be killed where it cannot be seen.
local function mark(game, skip)
    local left, top, w, h = Camera.bounds()
    return game:randomEnemyIn(left, top, w, h, skip)
end

-- Who the clouds already up are on, so a second does not park on the same one.
function Storm:taken()
    local out = {}
    for _, c in ipairs(self.live) do out[c.target] = true end
    return out
end

-- Where the cloud wants to be: over whoever it has marked, a bolt up.
local function station(target)
    return target.x, hoverY(target.y)
end

-- One step along the line to a point, and whether it got there. Straight-line
-- rather than per-axis, which would walk a cloud in an L and along an edge.
local function toward(x, y, tx, ty, step)
    local dx, dy = tx - x, ty - y
    local d = util.len(dx, dy)
    if d <= step then return tx, ty, true end
    return x + dx / d * step, y + dy / d * step, false
end

-- How far out a cloud must start to be off the page in *any* direction, plus a
-- cloud's width. Measured from the station, not the viewport centre: a station
-- hangs above its target, so a centre-struck radius could pop a cloud into the
-- opposite corner instead of arriving.
local function offPage(sx, sy, left, top, w, h)
    local far = 0
    for _, cx in ipairs({ left, left + w }) do
        for _, cy in ipairs({ top, top + h }) do
            far = math.max(far, util.len(cx - sx, cy - sy))
        end
    end
    return far + Sprites.cloud.w
end

-- Another mark for a cloud that has lost its own. False when there is nobody
-- left to visit, the one thing that ends a visit early.
function Storm:remark(c, game)
    local target = mark(game, self:taken())
    if not target then return false end
    c.target = target
    return true
end

-- Where a cloud goes after striking, with bolts left: the two nearest on
-- screen, so it can prefer somebody other than the thing it just hit but
-- falls back to it if that is all there is.
function Storm:linger(c, game)
    local left, top, w, h = Camera.bounds()
    local again

    for _, e in ipairs(game:nearestEnemies(c.x, c.y, LINGER, 2)) do
        if e.x >= left and e.x <= left + w and e.y >= top and e.y <= top + h then
            if e ~= c.target then
                c.target = e
                return true
            end
            again = e
        end
    end

    if not again then return false end
    c.target = again
    return true
end

-- One cloud, in from off the page on a random heading and out on that same
-- heading rather than turning round. Its numbers are copied onto it, so a level
-- taken mid-visit changes the next storm. False when there is nowhere to send
-- one -- the caller's cue to hold the launch rather than spend it.
function Storm:launch(game)
    if #self.live >= self:cap() then return false end

    local target = mark(game, self:taken())
    if not target then return false end

    local def = self.def
    local stats = game.loadout.stats
    local tx, ty = station(target)
    local out = offPage(tx, ty, Camera.bounds())
    local a = love.math.random() * TWO_PI
    local cos, sin = math.cos(a), math.sin(a)

    self.live[#self.live + 1] = {
        x = tx + cos * out, y = ty + sin * out,
        -- The way in, kept for the way out.
        dx = -cos, dy = -sin,
        target = target,
        -- Filled in at the strike. Whole pixels; the ring is plotted from it.
        sx = 0, sy = 0,
        -- Graphite sharpens passives; the global multiplier lands on all.
        damage = def.damage * stats.passiveDamage * stats.damage,
        radius = def.radius,
        speed = def.speed,
        -- By reference, the way a burn is.
        chain = def.chain,
        -- Where the zap jumped, filled in at the strike and drawn with the bolt.
        arcs = {},
        bolts = def.bolts,  -- strikes still in it
        state = "in",
        wait = 0,
        blink = 0,
    }

    return true
end

--- striking ------------------------------------------------------------------

-- One thing zapped: spark, blue outline, damage. Returns true if it survives --
-- the chain runs along the living, so it stops at every kill as at every gap.
local function zap(game, e, damage)
    game.particles:burst(e.x, e.y, 2, Palette.red)
    e:shock(SHOCK)
    if e:hurt(damage) then
        game:killEnemyAt(e)
        return false
    end
    return true
end

-- Everything in the circle under the bolt, once, then -- with the chain level -
-- everything the survivors pass it on to. `eachWithin` not `eachNear`: the
-- circle is wider than nine 12px cells, and this is asked at a strike rather
-- than every frame. Caught by centre-inside-ring, so the ring that flashes at
-- the bolt's foot is exactly the ring that killed.
function Storm:strike(c, game)
    -- Snapped onto the mark rather than where the cloud drifted to: a pixel at
    -- most, but the pixel that lands the bolt *on* the thing it came for.
    c.sx, c.sy = math.floor(c.target.x), math.floor(c.target.y)
    c.x, c.y = c.sx, hoverY(c.sy)

    game.particles:burst(c.sx, c.sy, 8, Palette.sky)

    -- Both thrown away with the strike: a bolt is one event.
    local hit, wave = {}, {}
    c.arcs = {}

    game:eachWithin(c.sx, c.sy, c.radius, function(e)
        if hit[e] then return end
        hit[e] = true
        if zap(game, e, c.damage) then wave[#wave + 1] = e end
    end)

    if not c.chain then return end

    -- Hop by hop, everybody in range of everybody left standing. No travel
    -- limit -- a thinning crowd or the falloff ends it; `hit` keeps it bounded.
    local damage = c.damage * c.chain.falloff
    while #wave > 0 and damage >= MIN_ZAP do
        local next = {}

        for _, from in ipairs(wave) do
            game:eachWithin(from.x, from.y, c.chain.range, function(e)
                if hit[e] then return end
                hit[e] = true
                -- The two points the zap went between, taken here rather than
                -- at the draw: by draw time both of them have walked on.
                c.arcs[#c.arcs + 1] = {
                    math.floor(from.x), math.floor(from.y),
                    math.floor(e.x), math.floor(e.y),
                }
                if zap(game, e, damage) then next[#next + 1] = e end
            end)
        end

        wave = next
        damage = damage * c.chain.falloff
    end
end

--- drifting ------------------------------------------------------------------

-- One cloud's frame. Returns false only at the edge of the page: one that has
-- done what it came for carries straight on until the page runs out from under
-- it. `speed` is a floor twice over -- it must beat the fastest enemy (the bat,
-- 38) to hold station, and the player (58) or a cloud could be walked to the
-- edge and held there for ever.
function Storm:step(c, dt, game, left, top, w, h)
    local step = c.speed * dt
    local cloud = Sprites.cloud

    if c.state == "out" then
        c.x, c.y = c.x + c.dx * step, c.y + c.dy * step
        return c.x + cloud.w > left and c.x - cloud.w < left + w
            and c.y + cloud.h > top and c.y - cloud.h < top + h
    end

    -- A mark that has `gone` (src/enemy.lua: killed, or left behind you) is
    -- replaced if the page has anybody else. An empty page ends the visit:
    -- a bolt into bare paper is what this weapon must not spend itself on.
    if c.target.gone and not self:remark(c, game) then
        c.state = "out"
        return true
    end

    -- Followed through the wait as well as the approach. The mark can do
    -- nothing about the bolt; the crowd with it can walk out of the circle.
    if c.state ~= "strike" then
        local tx, ty = station(c.target)
        local arrived
        c.x, c.y, arrived = toward(c.x, c.y, tx, ty, step)
        if c.state == "in" and arrived then
            c.state, c.wait, c.blink = "gather", GATHER, 0
        end
    end

    if c.state == "gather" then
        c.wait = c.wait - dt
        c.blink = c.blink + dt / FILL
        if c.wait <= 0 then
            self:strike(c, game)
            c.state, c.wait, c.blink = "strike", STRIKE, 0
        end

    elseif c.state == "strike" then
        c.wait = c.wait - dt
        c.blink = c.blink + dt / FLICKER
        if c.wait <= 0 then
            -- On to somebody else if the line bought more than one bolt.
            c.bolts = c.bolts - 1
            if c.bolts > 0 and self:linger(c, game) then
                c.state = "in"
            else
                c.state = "out"
            end
        end
    end

    return true
end

function Storm:update(dt, game, grid)
    local left, top, w, h = Camera.bounds()

    for i = #self.live, 1, -1 do
        if not self:step(self.live[i], dt, game, left, top, w, h) then
            table.remove(self.live, i)
        end
    end

    -- A launch with nowhere to go is held rather than spent: an empty page is
    -- not a beat this weapon should lose.
    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = self:launch(game) and self.def.every or LOOK
    end
end

--- drawing -------------------------------------------------------------------

-- Bolts first and clouds over them, so a bolt's head goes under the paper of
-- its cloud; a rim goes down with its own bolt, not in a pass of its own.
-- Neither flash is a fade -- an unlit beat draws nothing at all, since alpha
-- would be a ninth colour (see the rendering rules).
function Storm:draw(game)
    local bolt, cloud = Sprites.lightning, Sprites.cloud

    for _, c in ipairs(self.live) do
        if c.state == "strike" and math.floor(c.blink) % 2 == 0 then
            local y = boltY(c.sy)
            -- The only account of what the bolt reached. An outline rather
            -- than a disc: only the sun may cover the crowd it is killing.
            love.graphics.setColor(Palette.sky)
            pixelart.circleOutline(c.sx, c.sy, c.radius)

            -- Every jump the zap made, on the bolt's lit beats only. Straight
            -- lines: a jag re-roughed each frame shimmers. Blue rather than the
            -- flash's sky, which is the colour the ruling is drawn in.
            love.graphics.setColor(Palette.blue)
            for _, arc in ipairs(c.arcs) do
                pixelart.line(arc[1], arc[2], arc[3], arc[4])
            end

            Sprites.rim(bolt, c.sx, y)

            love.graphics.setColor(1, 1, 1)
            bolt:draw(c.sx, y)
        end
    end

    for _, c in ipairs(self.live) do
        if c.state == "gather" and math.floor(c.blink) % 2 == 0 then
            love.graphics.setColor(Palette.sky)
            cloud:drawMask(c.x, c.y)
        else
            love.graphics.setColor(1, 1, 1)
            cloud:draw(c.x, c.y)
        end
    end
end

return Storm
