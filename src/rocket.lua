-- Rockets, going off on their own.
--
-- The second passive weapon, and the opposite half of the idea to the stars
-- (src/orbital.lua): a star is bolted to you and only ever touches what comes
-- to it, and a rocket leaves. That is the whole reason both exist -- one guards
-- the ring you are standing in, the other empties out into the page around it
-- while your hands are busy drawing.
--
-- It leaves in one of **eight** directions, picked out of a hat. It used to pick
-- the nearest thing in range and fly at that, and giving that up is the whole
-- shape of the weapon now: a volley is a pattern on the paper rather than an
-- answer to somebody, so what it is worth is how much of the page it covers and
-- not what it was pointed at. Which makes it the cool S (src/cools.lua) read
-- from the other end -- an S comes in off the page in a direction nobody picked
-- and crosses where you are; a volley leaves *from* where you are in directions
-- nobody picked -- and it hands the aiming half of the stars pairing over to the
-- shot (src/shot.lua), which is the weapon that answers the thing that matters.
--
-- The trade is worth saying plainly, because it runs the other way from every
-- other weapon's opening level: this is now worth *less* against one straggler
-- than it was and considerably more against a crowd. Nothing in the line
-- sharpens a rocket to make up for it -- every level is about the shape of the
-- volley (two of the eight, then four, then what happens at the end of the
-- flight, then all eight), since an unaimed rocket's worth is how much of the
-- compass is covered and a run that wants each one landing harder buys the
-- passive that sells damage to everything that fights for it.
--
-- Those eight are exactly the eight headings the drawing is kept at
-- (Sprites.turned, pixelart.turn), which is the one quiet gain in all this:
-- nothing is rounded any more. A rocket used to fly at whatever angle its target
-- happened to be at and be drawn with the nearest of eight sprites, so the
-- drawing pointed a few degrees off its own line; now the line *is* a heading and
-- the drawing points exactly along it. Four of the eight are the drawing exactly
-- and four are resampled, which is the whole cost of drawing your own -- thin art
-- survives the quarter turns and blurs on the diagonals -- and a volley of four
-- or eight now flies both kinds at once, so a board drawn thin shows that cost
-- rather than hiding it. Nothing is rotated while the game is running: the ring
-- is built into ordinary sprites at ordinary integer positions when the board is
-- handed over.
--
-- Like the star it is a thing you draw rather than a thing you are handed
-- (src/design.lua), and the drawing is eleven by seven of pointy: the default is
-- a rocket, and redrawing it as a dart, an arrow or a sharpened pencil changes
-- nothing but those pixels.
--
-- Everything about it comes off the stat block the upgrade line built
-- (src/upgrades.lua): how often a volley goes up, how many go in it, how hard
-- each one hits, how many things it will go through before it stops and whether
-- it bursts where it stops. A rocket already in the air keeps the numbers it
-- launched with, which is what it means for an upgrade to change what comes
-- *next*.
--
-- Hits are asked of the run's spatial hash rather than of the horde, the way a
-- bullet's are: a rocket is small and travels a pixel or two a frame, so the
-- nine cells around it are the whole of what it can reach and nothing can
-- tunnel past it. The burst at the end of the flight is the exception and asks
-- the whole horde, for the bomb's reason -- see `Rocket:burst`.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")

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

local SMOKE_STEP = 3   -- pixels flown between one puff of exhaust and the next
local SMOKE_TAIL = 5   -- back from the middle to the nozzle, which is where the
                       -- exhaust has to leave from or it comes out of the body

local TWO_PI = math.pi * 2

-- The ring a burst leaves, for two or three frames, and the bomb's FLASH by name
-- and by argument (src/bomb.lua): it is the only account the player ever gets of
-- how far one reached, and a blast with a radius nobody drew is a blast nobody
-- can learn. Bursts land in ones and twos rather than four at a time like the
-- bomb's, so the rim spatter is thinner -- six puffs rather than eight.
local FLASH = 0.14
local PUFFS = 6

-- The eight, clockwise from nose-right, in the order `Sprites.turned` keeps
-- them: heading `i` is flown with `ring[i]` and there is no rounding step
-- anywhere between the two.
--
-- Written out rather than taken off math.cos at load, because cos(pi/2) is not
-- zero: a rocket fired straight down the page should be flying straight down the
-- page, and a fifteen-decimal-place sideways drift is the kind of thing that
-- comes out as a body sliding a pixel over a second and a half of flight.
local DIAG = math.sqrt(0.5)
local HEADINGS = {
    {  1,     0     },
    {  DIAG,  DIAG  },
    {  0,     1     },
    { -DIAG,  DIAG  },
    { -1,     0     },
    { -DIAG, -DIAG  },
    {  0,    -1     },
    {  DIAG, -DIAG  },
}

function Rocket.new()
    return setmetatable({
        def = nil,
        cool = 0,      -- 0, so taking the level sends a volley up at once
        live = {},     -- the ones in the air
        blasts = {},   -- the rings of the ones that have burst
    }, Rocket)
end

function Rocket:configure(def)
    self.def = def
end

--- hitting something ----------------------------------------------------------

-- Small, and two-coloured on purpose: red is what everything in the game throws
-- when it lands a hit, and the graphite going up with it is what makes this one
-- read as a bang rather than a bigger spark. The rocket itself is blue and the
-- spark it makes is red, which is not an inconsistency but the whole rule in
-- one frame: blue is the thing you sent, red is what happens to what it hit.
-- Which is also the split between this and `burst` below -- that one is the
-- rocket itself going off, so it is blue.
local function spark(game, x, y)
    game.particles:burst(x, y, 6, Palette.red)
    game.particles:burst(x, y, 4, Palette.graphite)
end

--- the burst at the end -------------------------------------------------------

-- What the fourth level of the line buys: a rocket that has run out of page --
-- or out of pierce -- goes off in a circle where it stopped instead of simply
-- not being there any more. Which is the level that finally makes an unaimed
-- volley worth something on a thin crowd: a rocket that missed everything still
-- ends somewhere, and where it ends is now a small crater.
--
-- Everything caught, once, and asked of the whole horde rather than of the nine
-- cells `eachNear` looks in -- the bomb's reason exactly: a circle wider than
-- twelve pixels reaches past what the hash guarantees. It is affordable for the
-- opposite of the sun's reason too, being asked once when a rocket ends rather
-- than on a tick for as long as one is up.
--
-- Caught by its centre being inside the ring, which is the bomb's test and the
-- sun's: the ring that flashes is exactly the ring that killed. Something the
-- rocket itself had already gone through can be caught again by the burst, and
-- that is right rather than a leak -- the two are separate events at separate
-- places, and a body caught by both reads as one number on the page anyway,
-- since damage is banked per frame and spent once (src/damage.lua).
--
-- Blue through the middle and sky round the rim, the pairing everything of the
-- player's is drawn in, and an *outline* rather than a filled disc: only the sun
-- is allowed to cover the crowd it is killing.
function Rocket:burst(r, game)
    local b = r.blast
    -- Whole pixels: the ring is plotted from this point.
    local x, y = math.floor(r.x), math.floor(r.y)

    game.particles:burst(x, y, 6, Palette.blue)
    for i = 0, PUFFS - 1 do
        local a = (i + love.math.random()) / PUFFS * TWO_PI
        game.particles:burst(x + math.cos(a) * b.radius * 0.8,
            y + math.sin(a) * b.radius * 0.8, 1, Palette.sky)
    end

    game:eachWithin(x, y, b.radius, function(e)
        if e:hurt(b.damage) then
            game:killEnemyAt(e)
        end
    end)

    self.blasts[#self.blasts + 1] = { x = x, y = y, r = b.radius, t = FLASH }
end

--- launching ------------------------------------------------------------------

-- A volley takes `count` of the eight headings, no two the same. Distinct rather
-- than rolled independently for the plainest of reasons: two rockets down one
-- line are one rocket with a bigger number on it, and the whole point of the
-- weapon is the ground a volley covers. It also means the finale is not a lucky
-- roll -- eight of eight is the whole compass, every time.
--
-- A partial shuffle of a scratch list of the eight, taken `count` deep, rather
-- than rolling a heading and rejecting the ones already taken: a volley of eight
-- would spend most of its rolls being told no, and the last level of the line is
-- exactly that volley. The list is the aims this used to build by another name,
-- so it costs the frame nothing it was not already paying.
--
-- Nothing is looked for and nothing can be missing, so a volley always goes up:
-- the old hold-the-shot-and-look-again is gone with the targeting, and the beat
-- on the block is now the whole clock.
function Rocket:launch(game)
    local def = self.def
    local px, py = game.player.x, game.player.y + MUZZLE_Y

    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything. Read at launch: a rocket carries the numbers it was
    -- fired with rather than looking them up again on the way.
    local stats = game.loadout.stats
    local damage = def.damage * stats.passiveDamage * stats.damage
    -- One table for the volley, since every rocket in it bursts the same way and
    -- none of them writes to it.
    local blast = def.blast and {
        radius = def.blast.radius,
        damage = def.blast.damage * stats.passiveDamage * stats.damage,
    }

    local order = { 1, 2, 3, 4, 5, 6, 7, 8 }
    -- Clamped rather than trusted: there are eight headings and no more, so a
    -- ninth rocket would be indexing past the end of the list.
    local n = math.min(def.count, #HEADINGS)
    for i = 1, n do
        local j = love.math.random(i, #HEADINGS)
        order[i], order[j] = order[j], order[i]
    end

    for i = 1, n do
        local h = order[i]

        self.live[#self.live + 1] = {
            x = px, y = py,
            dx = HEADINGS[h][1], dy = HEADINGS[h][2],
            -- The heading *is* the drawing, with nothing worked out from an
            -- angle in between.
            face = h,
            damage = damage,
            pierce = def.pierce,
            blast = blast,
            life = def.life,
            smoke = 0,
            -- What this one has already gone through, so a rocket that pierces
            -- can't shave the same enemy on every frame it spends inside it.
            -- Plain keys rather than the orbit's weak ones: this table dies
            -- with the rocket a second or so from now.
            hit = {},
        }
    end
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
            spark(game, r.x, r.y)
            if e:hurt(r.damage) then
                game:killEnemyAt(e)
            end

            if r.pierce <= 0 then
                r.life = 0
                return true -- spent: nothing else in these cells is its problem
            end
            r.pierce = r.pierce - 1
        end)

        -- The one place a rocket ends, whichever way it ran out, which is what
        -- makes the burst the end of the *flight* rather than a second thing
        -- that happens to time out at the same moment.
        if r.life <= 0 then
            if r.blast then self:burst(r, game) end
            table.remove(self.live, i)
        end
    end
end

function Rocket:update(dt, game, grid)
    -- What is already up moves before anything new joins it, so a rocket's
    -- first frame is the one where it is still sat on your shoulder.
    self:fly(dt, game, grid)

    for i = #self.blasts, 1, -1 do
        local ring = self.blasts[i]
        ring.t = ring.t - dt
        if ring.t <= 0 then table.remove(self.blasts, i) end
    end

    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = self.def.every
        self:launch(game)
    end
end

function Rocket:draw(game)
    -- The rings first, so a rocket flying through where the last one burst reads
    -- as crossing it rather than as being cut by it.
    love.graphics.setColor(Palette.blue)
    for _, ring in ipairs(self.blasts) do
        pixelart.circleOutline(ring.x, ring.y, ring.r)
    end

    local ring = Sprites.turned.rocket

    love.graphics.setColor(1, 1, 1)
    for _, r in ipairs(self.live) do
        ring[r.face]:draw(r.x, r.y)
    end
end

return Rocket
