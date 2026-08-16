-- Rockets, going off on their own.
--
-- The second passive weapon, and the opposite half of the idea to the stars
-- (src/orbital.lua): a star is bolted to you and only ever touches what comes
-- to it, and a rocket leaves. That is the whole reason both exist -- one guards
-- the ring you are standing in, the other reaches out and picks something off
-- while your hands are busy drawing.
--
-- Like the star it is a thing you draw rather than a thing you are handed
-- (src/design.lua), and the drawing is eleven by seven of pointy: the default is
-- a rocket, and redrawing it as a dart, an arrow or a sharpened pencil changes
-- nothing but those pixels.
--
-- It is the one thing in the game that points where it is going, so it is the
-- one thing kept at more than one heading: the drawing is turned into a ring of
-- eight (Sprites.turned, pixelart.turn) and a rocket picks the nearest of them
-- when it launches. Four of those eight are the drawing exactly and four are
-- resampled, which is the whole cost of drawing your own -- thin art survives
-- the quarter turns and blurs on the diagonals. Nothing is rotated while the
-- game is running: the ring is built into ordinary sprites at ordinary integer
-- positions when the board is handed over.
--
-- Everything about it comes off the stat block the upgrade line built
-- (src/upgrades.lua): how often a volley goes up, how many go in it, how hard
-- each one hits and how many things it will go through before it stops. A
-- rocket already in the air keeps the numbers it launched with, which is what
-- it means for an upgrade to change what comes *next*.
--
-- Hits are asked of the run's spatial hash rather than of the horde, the way a
-- bullet's are: a rocket is small and travels a pixel or two a frame, so the
-- nine cells around it are the whole of what it can reach and nothing can
-- tunnel past it.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local util = require("src.util")

local Rocket = {}
Rocket.__index = Rocket

-- One number for all eight headings, measured off the body's short way rather
-- than its length: a rocket meets things nose-on and the nose is one pixel
-- across. Three is the seven-pixel body's own half-height -- a slightly fatter
-- bullet, which is what it is. The same bargain the star's reach makes, so
-- drawing a different rocket, or turning this one, changes what it looks like
-- and never what it touches.
local HIT_R = 3

-- Off the shoulder, the same pixel the auto-shot leaves from: two things firing
-- from one hero should leave from one place.
local MUZZLE_Y = -1

-- Nothing in range, so the volley is not spent -- it is held, and goes up the
-- moment something walks into it. Checked often enough that walking into a
-- fresh crowd is answered immediately rather than on the next full cooldown.
local RELOAD_LOOK = 0.1

local SMOKE_STEP = 3   -- pixels flown between one puff of exhaust and the next
local SMOKE_TAIL = 5   -- back from the middle to the nozzle, which is where the
                       -- exhaust has to leave from or it comes out of the body

local EIGHTH = math.pi / 4

-- Which of the eight drawings a heading is flown with. Worked out once, at
-- launch, because a rocket flies a straight line and never changes its mind --
-- so nothing here runs per frame.
local function facing(dx, dy)
    -- math.atan2 rather than math.atan: LOVE 11 is LuaJIT, so this is Lua 5.1.
    return math.floor(math.atan2(dy, dx) / EIGHTH + 0.5) % 8 + 1
end

function Rocket.new()
    return setmetatable({
        def = nil,
        cool = 0,
        live = {},   -- the ones in the air
    }, Rocket)
end

function Rocket:configure(def)
    self.def = def
end

--- the explosion --------------------------------------------------------------

-- Small, and two-coloured on purpose: red is what everything in the game throws
-- when it lands a hit, and the graphite going up with it is what makes this one
-- read as a bang rather than a bigger spark. The rocket itself is blue and the
-- burst it ends on is red, which is not an inconsistency but the whole rule in
-- one frame: blue is the thing you sent, red is what happens to what it hit.
-- No blast radius -- what a rocket
-- does to the thing behind the thing it hit is go through it, and that is the
-- pierce upgrade rather than a splash nobody can see the edge of.
local function explode(game, x, y)
    game.particles:burst(x, y, 6, Palette.red)
    game.particles:burst(x, y, 4, Palette.graphite)
end

--- launching ------------------------------------------------------------------

-- A volley is aimed a rocket at a time rather than all down one line: three
-- rockets at the one enemy are one rocket with a bigger number on it, and three
-- going three ways are three rockets. So it asks for as many targets as it has
-- to fire and takes them nearest first, and only what is left over when the
-- volley outnumbers the crowd doubles up.
--
-- Doubling up is where the old fan survives, and it has to: the last thing on
-- the page should still take three spread across its front rather than three
-- down one line. Each shared aim is fanned about itself, so a share of one goes
-- straight down its target and an odd share always has one that does.
function Rocket:launch(game)
    local def = self.def
    local px, py = game.player.x, game.player.y + MUZZLE_Y

    local targets = game:nearestEnemies(px, py, def.range, def.count)

    -- Aims rather than targets from here, kept as two lists rather than a table
    -- each: this runs a couple of times a second and the volley is done with
    -- them by the end of it. An enemy standing exactly on the muzzle has no
    -- direction to be fired at and drops out, which with one target in range is
    -- the old behaviour of holding the volley rather than spending it.
    local aimX, aimY, n = {}, {}, 0
    for _, e in ipairs(targets) do
        local ax, ay = util.normalize(e.x - px, e.y - py)
        if ax ~= 0 or ay ~= 0 then
            n = n + 1
            aimX[n], aimY[n] = ax, ay
        end
    end
    if n == 0 then return false end

    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything. Read at launch: the rocket carries the number it was
    -- fired with rather than looking it up again on the way.
    local stats = game.loadout.stats
    local damage = def.damage * stats.passiveDamage * stats.damage

    for i = 1, def.count do
        -- Round-robin over the aims, so a volley with more rockets than targets
        -- doubles up on the nearest first.
        local t = (i - 1) % n + 1
        local share = math.floor((def.count - t) / n) + 1  -- rockets on this aim
        local j = math.floor((i - 1) / n) + 1              -- which of them this is

        -- Rotated off the aim rather than worked back out of an angle, so the
        -- straight-down-the-middle case really is straight.
        local off = (j - (share + 1) / 2) * def.spread
        local ax, ay = aimX[t], aimY[t]
        local c, s = math.cos(off), math.sin(off)
        local dx, dy = ax * c - ay * s, ax * s + ay * c

        self.live[#self.live + 1] = {
            x = px, y = py,
            dx = dx, dy = dy,
            face = facing(dx, dy),
            damage = damage,
            pierce = def.pierce,
            life = def.life,
            smoke = 0,
            -- What this one has already gone through, so a rocket that pierces
            -- can't shave the same enemy on every frame it spends inside it.
            -- Plain keys rather than the orbit's weak ones: this table dies
            -- with the rocket a second or so from now.
            hit = {},
        }
    end

    return true
end

--- flying ---------------------------------------------------------------------

function Rocket:fly(dt, game, grid)
    local speed = self.def.speed

    for i = #self.live, 1, -1 do
        local r = self.live[i]
        local step = speed * dt

        r.x = r.x + r.dx * step
        r.y = r.y + r.dy * step
        r.life = r.life - dt

        -- Exhaust, shed off the tail at a fixed spacing in pixels rather than
        -- in seconds, so the trail is the same trail at any framerate. A crumb
        -- leaves across the direction it is given with some of it carried
        -- along, which pointed backwards is a plume opening out behind.
        r.smoke = r.smoke - step
        if r.smoke <= 0 then
            r.smoke = SMOKE_STEP
            game.particles:crumb(r.x - r.dx * SMOKE_TAIL, r.y - r.dy * SMOKE_TAIL,
                -r.dx, -r.dy, 2, Palette.graphite)
        end

        game:eachNear(grid, r.x, r.y, function(e)
            if r.hit[e] then return end

            local dx, dy = e.x - r.x, e.y - r.y
            local reach = HIT_R + e.radius
            if dx * dx + dy * dy >= reach * reach then return end

            r.hit[e] = true
            explode(game, r.x, r.y)
            if e:hurt(r.damage) then
                game:killEnemyAt(e)
            end

            if r.pierce <= 0 then
                r.life = 0
                return true -- spent: nothing else in these cells is its problem
            end
            r.pierce = r.pierce - 1
        end)

        if r.life <= 0 then
            table.remove(self.live, i)
        end
    end
end

function Rocket:update(dt, game, grid)
    -- What is already up moves before anything new joins it, so a rocket's
    -- first frame is the one where it is still sat on your shoulder.
    self:fly(dt, game, grid)

    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = self:launch(game) and self.def.every or RELOAD_LOOK
    end
end

function Rocket:draw(game)
    local ring = Sprites.turned.rocket

    love.graphics.setColor(1, 1, 1)
    for _, r in ipairs(self.live) do
        ring[r.face]:draw(r.x, r.y)
    end
end

return Rocket
