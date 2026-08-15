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
-- It is also the one weapon with nothing on a board. Every other one is a thing
-- you draw (src/design.lua) and this one is two lines: the pointer that turns
-- with you and the beam that goes down it, both of them a length and a width the
-- upgrade line decides. There is nothing here a drawing could be.
--
-- That is also why it is the one thing in the game that is aimed at *any* angle.
-- Nothing is drawn at a rotation, so anything with a sprite has to round its
-- heading to the eight that sprite is kept at -- the rocket does exactly that.
-- A line has no such problem: `pixelart.line` and `pixelart.band` plot whole
-- pixels along any heading at all, so the aim is the walk vector itself and the
-- pointer is drawn at the same angle the beam takes.
--
-- What it costs to aim is the wind-up, and the wind-up is three states you read
-- in order:
--
--   1. The pointer, always. A short line off you, turning as you turn, saying
--      which way the next beam goes -- slate, so it reads as a pencil mark on
--      the page rather than as something happening.
--   2. The flash. Over the last stretch before the shot, a one-pixel line in
--      blush runs the whole way the beam is about to go, blinking faster the
--      closer it comes. It is the shot drawn thin: what it covers is exactly
--      what the beam will cover.
--   3. The beam, `width` pixels across the same line: blush through the middle
--      with a one-pixel red edge either side, so it reads as light with a shape
--      rather than as a bar of ink.
--
-- The aim is live through both of the first two and latched at the shot, so the
-- flash is a promise the beam keeps. None of it is a warning to the horde, which
-- cannot read it -- it is a sight, and walking is how you turn it.
--
-- The line stops where the page does. It is asked of `Camera.bounds()` every
-- time it fires rather than being a number on the block, for the sun's reason:
-- what happens off the edge of the screen is invisible, and a weapon that killed
-- out there would be doing most of its work in the one place the player has no
-- way of looking. A wider window is a longer beam, which is the same bargain
-- every screen-measured thing in the game makes.

local Camera = require("src.camera")
local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Beam = {}
Beam.__index = Beam

-- Off the shoulder, the same pixel the auto-shot and the rockets leave from:
-- three things firing from one hero should leave from one place.
local MUZZLE_Y = -1

-- The pointer, as a distance from the muzzle to each end of it. The near end
-- clears the hero at his tallest -- 15x19, so 9 and a half from the middle to
-- the top of his head -- in every direction it can point, which is what keeps it
-- a thing beside him rather than a thing stuck through him.
local SIGHT_IN, SIGHT_OUT = 12, 20

-- The flash: how long before the shot it starts, and the blink period at the
-- two ends of that. Both periods are well above a frame at 60fps, so the
-- flicker is something you see rather than something that fights the refresh
-- rate; the acceleration between them is what says "now" without a clock being
-- drawn anywhere.
local FLASH_FOR = 0.45
local BLINK_SLOW, BLINK_FAST = 0.15, 0.05

-- The arms, as turns of the aim, in the order the levels buy them: ahead,
-- behind, and then the two sides at once. Written as swaps and sign flips
-- rather than as angles, which makes them exact -- a quarter turn of a unit
-- vector should not come back off a cosine a millionth short.
local ARMS = {
    function(dx, dy) return dx, dy end,
    function(dx, dy) return -dx, -dy end,
    function(dx, dy) return -dy, dx end,
    function(dx, dy) return dy, -dx end,
}

-- Slack on the circle the horde is asked for, so a thing whose centre sits just
-- past the far end of the beam is still handed to the band test that rejects it.
-- The biggest enemy in the game is 6 across the middle and the widest beam is 5.
local SLACK = 9

-- Enemy fire is a pellet rather than a thing with a radius of its own
-- (Game:updateEnemyShots), so the beam is told how big one is here.
local PELLET_R = 2

-- The cycle, in order. `rest` is the one part with no length on the block: it is
-- whatever is left of `every` once the wind-up and the beam have had their
-- share, which is what makes `every` the number on the card -- one beam to the
-- next, wind-up included -- rather than a gap you would have to add up.
local NEXT = { charge = "fire", fire = "rest", rest = "charge" }

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
        -- bought: the flash starts on the frame the draft closes.
        phase = "charge",
        t = 0,
        tick = 0,
        -- The heading the beam that is out this instant is going down, latched
        -- when it fired. Nothing reads it while the pointer is the only thing up
        -- -- that follows your feet -- and nothing writes it while the beam is
        -- on the page.
        faceX = 1, faceY = 0,
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
-- pointer starts flashing again on the frame the last beam goes out -- rather
-- than a clock that runs backwards.
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
-- you last walked, exactly. Not rounded to anything -- see the header.
--
-- A keyboard can only ever hand this eight headings and a thumb stick can hand
-- it any of them, which is a difference in what the two can express rather than
-- a difference in what the weapon does with them.
function Beam:aim(game)
    return game.player.headX, game.player.headY
end

--- firing ---------------------------------------------------------------------

-- Every arm of one shot, as the way along it. One beam, or one and the one
-- behind it, or the whole cross -- all of them turned off the same aim, so they
-- turn together with the pointer that promised them.
function Beam:each(dx, dy, fn)
    for i = 1, self.def.arms do
        fn(ARMS[i](dx, dy))
    end
end

-- Every arm of one shot as a line: the way along it, and how far it gets before
-- the page runs out. The one place the viewport is read, so the flash, the beam
-- and the damage are all the same line by construction rather than by three
-- places agreeing about it.
function Beam:eachLine(x, y, dx, dy, fn)
    local left, top, w, h = Camera.bounds()

    self:each(dx, dy, function(ax, ay)
        local len = toEdge(x, y, ax, ay, left, top, w, h)
        if len > 0 then fn(ax, ay, len) end
    end)
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

-- The fifth level: what the eyes spit is burnt out of the air. The pellets are
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
    local struck = {}

    self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, len)
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
            -- latched is what the flash was promising on the last frame it was
            -- up, so the shot goes where the sight was pointing rather than
            -- where you turned a frame too late.
            self.faceX, self.faceY = self:aim(game)
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

-- Whether the flash is lit this instant. It runs over the last FLASH_FOR of the
-- wind-up -- or the whole of it, on a block whose wind-up is shorter than that
-- -- and its period shortens as it goes, so the count runs away with itself
-- towards the end. Which is exactly the read wanted: something that is going to
-- happen, and then something that is about to.
function Beam:flashing()
    if self.phase ~= "charge" then return false end

    local left = self.def.charge - self.t
    if left > FLASH_FOR then return false end

    local into = 1 - left / math.min(FLASH_FOR, self.def.charge)
    local period = BLINK_SLOW + (BLINK_FAST - BLINK_SLOW) * into
    return math.floor(self.t / period) % 2 == 0
end

function Beam:draw(game)
    local x, y = game.player.x, game.player.y + MUZZLE_Y
    local liveX, liveY = self:aim(game)

    -- The pointer, always, in every phase, and once per arm the run has bought
    -- -- one line at first, then one out of each end, then the whole cross. It
    -- is the only part of this still following your feet while a beam is out,
    -- so it is already saying where the *next* one goes.
    --
    -- First, so that the flash and the beam cover it rather than the other way
    -- round. A pointer lying on top of its own beam would read as a scratch
    -- through it, and a pointer that agrees with the beam has nothing to say
    -- that the beam is not already saying: the frames where you want to see it
    -- are the ones where you have turned since the shot, and on those it is
    -- somewhere else on the page anyway.
    love.graphics.setColor(Palette.slate)
    self:each(liveX, liveY, function(dx, dy)
        pixelart.line(x + dx * SIGHT_IN, y + dy * SIGHT_IN,
            x + dx * SIGHT_OUT, y + dy * SIGHT_OUT)
    end)

    -- The flash, one pixel wide down the whole line the beam is about to take.
    -- Blush rather than red: it is the shot drawn thin, and a thin line in the
    -- shot's own colour would read as a shot that had already happened.
    if self:flashing() then
        love.graphics.setColor(Palette.blush)
        self:eachLine(x, y, liveX, liveY, function(dx, dy, len)
            pixelart.line(x, y, x + dx * len, y + dy * len)
        end)
        return
    end

    if self.phase ~= "fire" then return end

    -- Light through the middle and darker at the edges, which is the sun's
    -- treatment of its disc and works here for the same reason: blush alone is
    -- pale enough to lose against the paper, and red alone is a solid bar you
    -- cannot see anything through. An edge in the darker of the two is what
    -- gives it a shape rather than a presence.
    --
    -- The edge is the same band drawn two pixels narrower on top rather than
    -- two lines laid down beside it. A line placed separately would have to
    -- agree with `pixelart.band`'s own rounding at every angle it can be aimed
    -- at, and everywhere it disagreed the beam would come apart at the seam;
    -- drawn this way the edge is whatever the band's own outermost pixels are,
    -- by construction. It costs a second pass over the same span, and no alpha
    -- means painting over the middle of the first one is free.
    --
    -- Both colours come out a step darker where they cross the ruling
    -- (Palette.overprint) exactly as everything else does, so the page goes on
    -- showing through the one thing on it made of light.
    local width = self.def.width

    love.graphics.setColor(Palette.red)
    self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, len)
        pixelart.band(x, y, x + dx * len, y + dy * len, width)
    end)

    -- Every edge goes down before any of the middles, so that where two arms
    -- cross, one beam's edge can never sit in another beam's light. The cool S
    -- draws its rim the same way round and for the same reason.
    if width > 2 then
        love.graphics.setColor(Palette.blush)
        self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, len)
            pixelart.band(x, y, x + dx * len, y + dy * len, width - 2)
        end)
    end
end

return Beam
