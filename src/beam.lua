-- The laser beam, fired down the line you are walking.
--
-- The fifth passive weapon, and the only one you aim. Everything else that
-- fights for you decides for itself where to go: a star turns wherever it is in
-- its orbit (src/orbital.lua), a rocket picks the nearest thing (src/rocket.lua),
-- the sun owns whichever corner it came up in (src/sun.lua) and a cool S arrives
-- from a direction nobody chose (src/cools.lua). This one goes where you were
-- walking -- so it is the one weapon that answers to the half of the game you
-- were already playing with your feet, and the run that lines it up is the run
-- that walks into the crowd rather than away from it.
--
-- What it costs to aim is the wind-up. A beam does not go off the moment it is
-- ready: an arrow comes up first, out at arm's length, pointing where the beam
-- will go and blinking faster the closer it comes -- and the aim is live for
-- every frame of that. You watch the arrow swing round as you turn, and it is
-- latched at the instant the beam leaves. So the telegraph is not a warning to
-- the horde, which cannot read it, but the whole of how you use the weapon:
-- the arrow is the sight, and walking is how you turn it.
--
-- The arrow is the thing you draw (src/design.lua), not the beam. The beam is a
-- line the width and length the levels say, which makes this the sun's bargain
-- rather than the star's: what is authored is sized by the upgrade line and what
-- is drawn is the part with a face on it.
--
-- Two things are quantized to the eight headings, and it is one decision made
-- twice. Nothing in this game is drawn at an angle, so the arrow can only point
-- eight ways (Sprites.turned, pixelart.turn) -- and a beam that fired at the
-- exact angle you were walking while the arrow rounded to the nearest eighth
-- would be a sight that lies about where the shot is going. So the aim rounds
-- once, before either of them reads it, and the arrow points exactly down the
-- line the beam will take.
--
-- The line stops where the page does. It is asked of `Camera.bounds()` every
-- time it fires rather than being a number on the block, for the sun's reason:
-- what happens off the edge of the screen is invisible, and a weapon that killed
-- out there would be doing most of its work in the one place the player has no
-- way of looking. A wider window is a longer beam, which is the same bargain
-- every screen-measured thing in the game makes.

local Camera = require("src.camera")
local Palette = require("src.palette")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")

local Beam = {}
Beam.__index = Beam

local EIGHTH = math.pi / 4

-- Off the shoulder, the same pixel the auto-shot and the rockets leave from:
-- three things firing from one hero should leave from one place.
local MUZZLE_Y = -1

-- How far out the sight sits. Measured off the two sprites rather than picked:
-- the hero is 15x19 and the arrow is 11x7 turned to 7x11, so this clears both
-- of them in every one of the eight directions it can sit in. An arrow
-- overlapping the man holding it reads as part of him rather than as a thing
-- pointing away from him.
local SIGHT_OUT = 17

-- The wind-up blink, from the period it starts at to the one it ends on. Both
-- are well above a frame at 60fps, so the flicker is something you see rather
-- than something that fights the refresh rate; the acceleration between them is
-- what says "now" without a clock being drawn anywhere.
local BLINK_SLOW, BLINK_FAST = 0.18, 0.05

-- The arms, as eighths off the heading, in the order the levels buy them:
-- ahead, behind, and then the two sides at once. `def.arms` takes the first n,
-- so the shape a run is firing is one number rather than a set of flags.
local ARMS = { 0, 4, 2, 6 }

-- Slack on the circle the horde is asked for, so a thing whose centre sits just
-- past the far end of the beam is still handed to the band test that rejects it.
-- The biggest enemy in the game is 6 across the middle and the widest beam is 3.
local SLACK = 8

-- Enemy fire is a pellet rather than a thing with a radius of its own
-- (Game:updateEnemyShots), so the beam is told how big one is here.
local PELLET_R = 2

-- The cycle, in order, and the field on the stat block that says how long each
-- part of it lasts. `rest` is the one part that is not on the block: it is
-- whatever is left of `every` once the wind-up and the beam have had their
-- share, which is what makes `every` the number on the card -- one beam to the
-- next, wind-up included -- rather than a gap you would have to add up.
local NEXT = { charge = "fire", fire = "rest", rest = "charge" }

-- math.atan2 rather than math.atan: LOVE 11 is LuaJIT, so this is Lua 5.1.
-- Eighths are counted from 0 so the arithmetic on them is plain; the ring of
-- drawings is 1-based, and only Beam:draw knows that.
local function facing(dx, dy)
    return math.floor(math.atan2(dy, dx) / EIGHTH + 0.5) % 8
end

local function heading(eighth)
    local a = eighth * EIGHTH
    return math.cos(a), math.sin(a)
end

-- How far it is from a point to the edge of the viewport along a heading, for a
-- heading that is already a unit vector. Whichever edge the line reaches first
-- is the one that ends it; a heading with no component towards an axis simply
-- never meets those two edges, which is why each half is guarded rather than
-- divided by zero.
local function toEdge(x, y, dx, dy, left, top, w, h)
    local far = math.huge

    if dx > 0 then far = math.min(far, (left + w - x) / dx)
    elseif dx < 0 then far = math.min(far, (left - x) / dx) end
    if dy > 0 then far = math.min(far, (top + h - y) / dy)
    elseif dy < 0 then far = math.min(far, (top - y) / dy) end

    if far == math.huge then return 0 end
    return math.max(0, far)
end

function Beam.new()
    return setmetatable({
        def = nil,
        -- Winding up rather than resting, so taking the level shows you what you
        -- bought: the arrow comes up on the frame the draft closes.
        phase = "charge",
        t = 0,
        tick = 0,
        -- The heading the beam that is out this instant is going down, latched
        -- when it fired. Nothing reads it while the arrow is up -- that follows
        -- your feet -- and nothing writes it while the beam is on the page.
        face = 0,
    }, Beam)
end

function Beam:configure(def)
    self.def = def
end

--- the cycle ------------------------------------------------------------------

-- What is left of the period once the wind-up and the beam have taken theirs.
-- Floored at nothing: the levels that lengthen the beam and the level that
-- halves the period are bought separately and in whatever order the draft
-- happens to offer them, so a run can hold a shape where they no longer fit
-- inside each other. What that gives is a weapon with no gap at all -- the
-- arrow comes up on the frame the last beam goes out -- rather than a clock
-- that runs backwards.
function Beam:rest()
    local def = self.def
    return math.max(0, def.every - def.charge - def.hold)
end

function Beam:lasts(phase)
    if phase == "charge" then return self.def.charge end
    if phase == "fire" then return self.def.hold end
    return self:rest()
end

-- Where the sight is pointing this instant: the way you are walking, or the way
-- you last walked, rounded to the eight headings the arrow can be drawn at.
function Beam:aim(game)
    return facing(game.player.headX, game.player.headY)
end

--- firing ---------------------------------------------------------------------

-- Every arm of one shot, as a heading and the way along it. One beam, or one
-- and the one behind it, or the whole cross -- struck off the latched aim, so
-- all of them turn together with the arrow that promised them.
function Beam:each(face, fn)
    for i = 1, self.def.arms do
        local e = (face + ARMS[i]) % 8
        local dx, dy = heading(e)
        fn(e, dx, dy)
    end
end

-- Everything standing on one arm, once. The horde is asked rather than the nine
-- cells `Game:eachNear` looks in, for the sun's reason and with the sun's
-- bargain: a beam is as long as the page is wide, which no number of cells
-- covers, and this runs on a tick a few times a second rather than every frame.
--
-- A band rather than a line, and the test is done in the beam's own frame:
-- how far along it a thing is, and how far off it. Anything behind the muzzle or
-- past the page edge is not on the beam at all, which is the first two clauses.
function Beam:cut(game, x, y, dx, dy, len, damage, struck)
    local half = self.def.width / 2

    game:eachWithin(x, y, len + SLACK, function(e)
        if struck[e] then return end

        local ex, ey = e.x - x, e.y - y
        local along = ex * dx + ey * dy
        if along < 0 or along > len then return end
        if math.abs(ex * -dy + ey * dx) > half + e.radius then return end

        -- One thing is hit once by one shot however many arms are crossing it.
        -- Only ever true within a pixel or two of the muzzle, where the whole
        -- cross meets -- but standing on the player is not four beams' worth of
        -- anything, and the alternative is a weapon whose damage depends on
        -- where in a crowd it happened to be standing.
        struck[e] = true
        game.particles:burst(e.x, e.y, 2, Palette.red)
        if e:hurt(damage) then
            game:killEnemyAt(e)
        end
    end)
end

-- The fourth level: what the eyes spit is burnt out of the air. The pellets are
-- the one pressure a pen wall cannot hold off (Game:updateEnemyShots), so the
-- weapon that answers them is the one that reaches all the way across the page
-- -- and it answers them by standing in front of them, which is a thing you have
-- to have walked into place.
--
-- Walked backwards because it removes as it goes, and the same band test the
-- horde gets: a pellet on the beam is a pellet on the beam.
function Beam:burn(game, x, y, dx, dy, len)
    local half = self.def.width / 2

    for i = #game.shots, 1, -1 do
        local s = game.shots[i]
        local ex, ey = s.x - x, s.y - y
        local along = ex * dx + ey * dy

        if along >= 0 and along <= len
            and math.abs(ex * -dy + ey * dx) <= half + PELLET_R then
            game.particles:burst(s.x, s.y, 3, Palette.red)
            table.remove(game.shots, i)
        end
    end
end

-- One tick of one shot: every arm, against the horde and against the air.
--
-- The damage is read here rather than carried, unlike the rocket's and the cool
-- S's. Nothing about a beam outlives the instant it is fired -- it is not a
-- thing travelling with numbers on it -- so an upgrade taken while one is
-- holding lands on the rest of that hold, which is the only reading of "what it
-- does now" that a line of light supports.
function Beam:strike(game)
    local stats = game.loadout.stats
    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything.
    local damage = self.def.damage * stats.passiveDamage * stats.damage

    local x, y = game.player.x, game.player.y + MUZZLE_Y
    local left, top, w, h = Camera.bounds()
    local struck = {}

    self:each(self.face, function(_, dx, dy)
        local len = toEdge(x, y, dx, dy, left, top, w, h)
        if len <= 0 then return end

        self:cut(game, x, y, dx, dy, len, damage, struck)
        if self.def.pellets then
            self:burn(game, x, y, dx, dy, len)
        end
    end)
end

function Beam:update(dt, game, grid)
    -- A loop rather than an if, so a frame long enough to swallow a whole phase
    -- lands in the right one instead of a phase behind. `charge` and `hold` are
    -- both above zero on every block the line can build, which is what makes it
    -- terminate even when the rest has been squeezed to nothing.
    self.t = self.t + dt
    while self.t >= self:lasts(self.phase) do
        self.t = self.t - self:lasts(self.phase)
        self.phase = NEXT[self.phase]

        if self.phase == "fire" then
            -- The aim stops following your feet here and nowhere else. What is
            -- latched is what the arrow was promising on the last frame it was
            -- up, so the shot goes where the sight was pointing rather than
            -- where you turned a frame too late.
            self.face = self:aim(game)
            self.tick = 0
            game.particles:burst(game.player.x, game.player.y + MUZZLE_Y,
                4, Palette.red)
        end
    end

    if self.phase ~= "fire" then return end

    self.tick = self.tick - dt
    if self.tick <= 0 then
        self.tick = self.def.tick
        self:strike(game)
    end
end

--- drawing --------------------------------------------------------------------

-- The blink, accelerating from BLINK_SLOW to BLINK_FAST across the wind-up. The
-- period shortens as the arrow reads it, so the count runs away with itself
-- towards the end -- which is exactly the read wanted: something that is going
-- to happen, and then something that is about to.
function Beam:showSight()
    local t = self.t / self.def.charge
    local period = BLINK_SLOW + (BLINK_FAST - BLINK_SLOW) * t
    return math.floor(self.t / period) % 2 == 0
end

-- A band rather than a line, drawn as `width` copies stepped along the beam's
-- own perpendicular. Whole pixels either way: on the four square headings the
-- step is exactly a pixel, and on the diagonals the floor inside pixelart.line
-- lands the copies on the neighbouring pixels of the same staircase.
--
-- Red, and red alone. It comes out slate where it crosses the ruling
-- (Palette.overprint) exactly as everything else red in the game does, so the
-- page goes on showing through the one thing in it made of light.
function Beam:drawArm(x, y, dx, dy, len)
    local px, py = -dy, dx
    local width = self.def.width

    for i = 0, width - 1 do
        local off = i - (width - 1) / 2
        pixelart.line(x + px * off, y + py * off,
            x + dx * len + px * off, y + dy * len + py * off)
    end
end

function Beam:draw(game)
    local x, y = game.player.x, game.player.y + MUZZLE_Y

    if self.phase == "charge" then
        if not self:showSight() then return end

        local ring = Sprites.turned.arrow
        love.graphics.setColor(1, 1, 1)
        self:each(self:aim(game), function(e, dx, dy)
            ring[e + 1]:draw(x + dx * SIGHT_OUT, y + dy * SIGHT_OUT)
        end)
        return
    end

    if self.phase ~= "fire" then return end

    local left, top, w, h = Camera.bounds()
    love.graphics.setColor(Palette.red)
    self:each(self.face, function(_, dx, dy)
        local len = toEdge(x, y, dx, dy, left, top, w, h)
        if len > 0 then self:drawArm(x, y, dx, dy, len) end
    end)
end

return Beam
