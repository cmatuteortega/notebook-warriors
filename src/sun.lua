-- The sun coming up in the corner of the page.
--
-- The third passive weapon, and the one that belongs to the page you are
-- *looking at* rather than to the world drawn on it. A star is bolted to you
-- (src/orbital.lua) and a rocket leaves you (src/rocket.lua); both are
-- somewhere in particular, and both go where the fight is. The sun does not. It
-- rises in a corner of the screen, burns everything the disc covers while it is
-- up, sinks back out and comes up in a different corner -- so what it really
-- does is take a quarter of the page away from the horde for a few seconds at a
-- time, and tell you which quarter long before it matters. It is the one weapon
-- you play around rather than aim.
--
-- The disc is solid, and that is the design rather than an oversight: while the
-- sun is up you cannot read that corner, and the price of the safest place on
-- the page is not being able to see it. What walks back out is what tells you
-- what happened -- anything that stood in the light too long keeps a grey ghost
-- of its own outline for the rest of its life (Enemy:sunburn), so the page
-- remembers the burn the way it remembers a spent pin.
--
-- Everything about it comes off the stat block the upgrade line built
-- (src/upgrades.lua): how wide, how hard, how long it stays and how long it is
-- gone, how far it swells while it burns, whether the opposite corner comes up
-- with it, and whether it throws sunrays across the page at full height. The
-- instance outlives being reconfigured, so a sun already up stays up and the
-- level that widens it widens the one you are standing in.
--
-- The two things it hits with ask two different questions, and the split is the
-- ordinary one. The disc covers ground -- eighty pixels of it, far wider than
-- the nine 12px cells `Game:eachNear` looks in -- so it asks `Game:eachWithin`,
-- the whole horde, affordable because it is asked twice a second on a tick
-- rather than every frame. A sunray in flight is a small thing at a point, like
-- a bullet or a rocket, so it asks the spatial hash exactly as they do.
--
-- It is the most expensive thing in the game to *draw*, and worth knowing why:
-- a filled disc is a span per row and its rim is eight pixels per step of the
-- circle, and three quarters of both are plotted off the page behind the corner
-- where nothing can see them. That is affordable at one or two suns up for a few
-- seconds at a time, and it is the price of drawing a circle on the same pixel
-- grid as everything else rather than letting love.graphics.circle put a smooth
-- polygon on the page. If it ever stops being affordable, the saving is to plot
-- only the quadrant that shows.

local Camera = require("src.camera")
local Palette = require("src.palette")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")

local Sun = {}
Sun.__index = Sun

local TWO_PI = math.pi * 2
local ROOT2 = math.sqrt(2)

-- The rays it is drawn with, and the lines the last level shoots down. Twelve
-- is what leaves a gap you can see between one and the next at the rim of the
-- widest disc; they turn slowly, which is what stops a shape this big reading as
-- a sticker stuck on the screen.
local SPOKES = 12
local SPIN = 0.32          -- radians a second
local RAY_GAP = 2          -- clear of the rim, so the rim stays a rim
local RAY_LEN = 6

-- The wind-up the last level adds: over the final RAY_WIND seconds before a
-- volley the spokes stretch by RAY_STRETCH, and at full stretch they come off
-- and fly. So the shot is the drawing leaving rather than a second thing
-- appearing over the top of it -- you can see it coming in the spokes, which is
-- the only warning anything in this game gives.
local RAY_WIND = 0.4
local RAY_STRETCH = 7

-- Where the face sits, as a fraction of the disc's resting radius along the
-- diagonal into the page. Measured off the resting radius rather than off the
-- pulse, so the face holds still while the disc breathes around it -- a face
-- that slid in and out with the rim would read as the sun leaning at you.
local FACE_OUT = 0.45

-- How near the head of a flying sunray a thing has to be, on top of its own
-- radius. Three pixels for a one-pixel line: a ray that only caught what it drew
-- over would be a weapon you had to aim, and nothing about the sun is aimed.
local RAY_R = 3

-- The four corners of the screen: which corner of the viewport, and the
-- direction from it into the page. Numbered so that opposite corners add to
-- five, which is the whole of how the two-corner level finds its partner.
local CORNERS = {
    { 0, 0,  1,  1 },  -- 1 top left
    { 1, 0, -1,  1 },  -- 2 top right
    { 0, 1,  1, -1 },  -- 3 bottom left
    { 1, 1, -1, -1 },  -- 4 bottom right
}

-- The cycle, in order, and the field on the stat block that says how long each
-- part of it lasts. `off` is the sun below the corner: nothing drawn, nothing
-- burnt, and the only part of the cycle the player gets the whole page back.
local NEXT = { rise = "hold", hold = "set", set = "off", off = "rise" }
local LASTS = { rise = "up", hold = "stay", set = "down", off = "gap" }

function Sun.new()
    return setmetatable({
        def = nil,
        phase = "rise",   -- taking the level shows you what you bought
        t = 0,
        spin = 0,
        swell = 0,
        tick = 0,
        corner = love.math.random(4),
        rayT = 0,
        -- The rays that have come off and are flying. They are in world space
        -- from the moment they leave: a ray still stuck to the sun would slide
        -- sideways with the camera, and a thing that has left is a thing that
        -- has left.
        shots = {},
    }, Sun)
end

function Sun:configure(def)
    self.def = def
end

--- where it is ----------------------------------------------------------------

-- Whole pixels: the disc is plotted row by row from this (pixelart.circleFill),
-- so a fractional radius would put half of those rows off the grid.
function Sun:reach()
    local def = self.def
    if def.swell <= 0 then return def.radius end
    return math.floor(def.radius + math.sin(self.swell) * def.swell)
end

-- 0 with the sun still below the corner, 1 at full height.
function Sun:height()
    local def = self.def
    local phase = self.phase
    if phase == "hold" then return 1 end
    if phase == "rise" then return self.t / def.up end
    if phase == "set" then return 1 - self.t / def.down end
    return 0
end

-- The centre of the disc, which travels along the diagonal rather than growing:
-- at height 0 it is exactly its own radius outside the corner, so the circle
-- passes through the corner and not a pixel of it is on the page, and at height
-- 1 the centre *is* the corner and exactly a quarter of it shows.
local function centre(corner, height, r)
    local left, top, w, h = Camera.bounds()
    local spec = CORNERS[corner]
    local back = (1 - height) * r / ROOT2

    return left + spec[1] * w - spec[3] * back,
           top + spec[2] * h - spec[4] * back,
           spec[3] / ROOT2, spec[4] / ROOT2
end

-- Every sun that is up this instant, with the way into the page from each. One,
-- or two in opposite corners; nothing at all while it is below the page, which
-- is what makes this the one guard both the burn and the draw need.
function Sun:each(fn)
    local height = self:height()
    if height <= 0 then return end

    local r = self:reach()
    for i = 1, self.def.corners do
        local corner = i == 1 and self.corner or 5 - self.corner
        local x, y, dx, dy = centre(corner, height, r)
        fn(x, y, r, dx, dy)
    end
end

-- Never the corner it just left. With two up at once there are only two pairs of
-- opposite corners to be in, so moving means swapping pairs rather than picking
-- freely -- otherwise two thirds of the moves would light the same two corners
-- again and the sun would read as blinking rather than as crossing the page.
function Sun:move()
    if self.def.corners > 1 then
        self.corner = self.corner <= 2 and self.corner + 2 or self.corner - 2
    else
        self.corner = (self.corner - 1 + love.math.random(3)) % 4 + 1
    end
end

--- burning --------------------------------------------------------------------

-- On a tick rather than every frame, which is what makes asking the whole horde
-- affordable -- and what makes the damage a number you can read off the card
-- instead of a rate you have to work out.
function Sun:burn(dt, game)
    local def = self.def
    if self:height() <= 0 then return end

    self.tick = self.tick - dt
    if self.tick > 0 then return end
    self.tick = def.tick

    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything.
    local stats = game.loadout.stats
    local damage = def.damage * stats.passiveDamage * stats.damage
    local left, top, w, h = Camera.bounds()

    self:each(function(x, y, r)
        game:eachWithin(x, y, r, function(e)
            -- Only what is actually covered. Three quarters of the disc hangs
            -- off the page behind the corner, and burning things back there
            -- would make the sun three times the weapon it looks like -- and
            -- make it kill, invisibly, in the one place the player has no way
            -- of looking.
            if e.x < left or e.x > left + w or e.y < top or e.y > top + h then return end

            if e:hurt(damage) then
                game:killEnemyAt(e)
                return
            end

            -- Marked only if it lives through the burn, which is what the mark
            -- means: this one stood in the sun and walked out of it. The splat
            -- is the one beat worth spending on the moment -- everything else
            -- the sun does happens under a disc nobody can see through.
            if e:sunburn(def.tick, def.soak, game.time) then
                game.particles:burst(e.x, e.y, 3, Palette.blush)
            end
        end)
    end)
end

--- sunrays --------------------------------------------------------------------

-- How long a spoke is drawn this instant. A fixed length until the last level
-- gives the rays somewhere to go; from then on each one stretches over the
-- wind-up to the next volley and comes off at full stretch, so what flies is
-- the line that was turning round the sun a moment ago rather than a second
-- thing appearing over the top of it.
--
-- Only while the sun is at full height: a sun still climbing out of the corner
-- has nothing to throw, so its rays sit still.
function Sun:spokeLen()
    if not self.def.rays or self:height() < 1 then return RAY_LEN end
    if self.rayT >= RAY_WIND then return RAY_LEN end

    return RAY_LEN + RAY_STRETCH * (1 - math.max(0, self.rayT) / RAY_WIND)
end

-- A volley: every spoke of every sun that is up snaps off and flies straight
-- out along the way it was pointing. Twenty-four lines leaving a lit corner at
-- once is the finale of a line that has spent four levels making a corner
-- dangerous to stand in and this is the level where the corner stops being able
-- to be walked around.
--
-- Each ray carries the numbers it left with, the way a rocket does: an upgrade
-- landing mid-flight changes the next volley rather than this one.
function Sun:throw(game)
    local rays = self.def.rays
    local stats = game.loadout.stats
    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything.
    local damage = rays.damage * stats.passiveDamage * stats.damage
    local step = TWO_PI / SPOKES
    local len = self:spokeLen()

    self:each(function(x, y, r)
        local out = r + RAY_GAP + len

        for i = 0, SPOKES - 1 do
            local a = self.spin + i * step
            local c, s = math.cos(a), math.sin(a)

            self.shots[#self.shots + 1] = {
                -- The leading end, which is the end that does the hitting: the
                -- body of the ray is drawn back from here.
                x = x + c * out, y = y + s * out,
                dx = c, dy = s,
                len = len,
                speed = rays.speed,
                damage = damage,
                left = rays.length,
                -- What it has already gone through. A ray is light rather than
                -- a thing, so nothing stops it -- but it may only cut each
                -- victim once on the way past. Plain keys rather than the
                -- orbit's weak ones: this table dies with the ray a second from
                -- now.
                hit = {},
            }
        end
    end)
end

-- Hits are asked of the spatial hash rather than of the horde, the way a
-- bullet's are: a ray in flight is a point at the head of a short line moving a
-- couple of pixels a frame, so the nine cells around it are the whole of what it
-- can reach and nothing can tunnel past it. The body behind the head needs no
-- test of its own -- everything it is lying across, the head went through first.
function Sun:fly(dt, game, grid)
    for i = #self.shots, 1, -1 do
        local ray = self.shots[i]
        local step = ray.speed * dt

        ray.x = ray.x + ray.dx * step
        ray.y = ray.y + ray.dy * step
        ray.left = ray.left - step

        game:eachNear(grid, ray.x, ray.y, function(e)
            if ray.hit[e] then return end

            local dx, dy = e.x - ray.x, e.y - ray.y
            local reach = RAY_R + e.radius
            if dx * dx + dy * dy >= reach * reach then return end

            ray.hit[e] = true
            game.particles:burst(ray.x, ray.y, 2, Palette.red)
            if e:hurt(ray.damage) then
                game:killEnemyAt(e)
            end
        end)

        if ray.left <= 0 then
            table.remove(self.shots, i)
        end
    end
end

-- Rays already out fly whatever the sun is doing -- a volley thrown a moment
-- before it sank goes on across the page after it has gone -- and only a sun at
-- full height throws a new one.
function Sun:shoot(dt, game, grid)
    self:fly(dt, game, grid)

    if self:height() < 1 then return end

    self.rayT = self.rayT - dt
    if self.rayT > 0 then return end

    -- Thrown before the clock is wound back on, because what is thrown is the
    -- spoke at the length it has stretched to and `spokeLen` reads that clock.
    self:throw(game)
    self.rayT = self.def.rays.every
end

--- the cycle ------------------------------------------------------------------

function Sun:update(dt, game, grid)
    local def = self.def

    self.spin = (self.spin + SPIN * dt) % TWO_PI
    self.swell = (self.swell + def.swellRate * dt) % TWO_PI

    -- A loop rather than an if, so a frame long enough to swallow a whole phase
    -- lands in the right one instead of a phase behind. Every length on the
    -- block is above zero, which is what makes it terminate.
    self.t = self.t + dt
    while self.t >= def[LASTS[self.phase]] do
        self.t = self.t - def[LASTS[self.phase]]
        self.phase = NEXT[self.phase]
        if self.phase == "rise" then self:move() end
    end

    self:burn(dt, game)
    if def.rays then self:shoot(dt, game, grid) end
end

--- drawing --------------------------------------------------------------------

function Sun:draw(game)
    local face = Sprites.sunface
    local step = TWO_PI / SPOKES
    local len = self:spokeLen()

    -- The ones that have left, first: they are behind the sun they came out of,
    -- so a ray still crossing the disc's own rim reads as leaving rather than as
    -- lying on top of it.
    love.graphics.setColor(Palette.red)
    for _, ray in ipairs(self.shots) do
        pixelart.line(ray.x - ray.dx * ray.len, ray.y - ray.dy * ray.len,
            ray.x, ray.y)
    end

    self:each(function(x, y, r, dx, dy)
        -- Blush rather than red, and solid: over the ruling it comes out red
        -- (Palette.overprint), so the lines of the page go on showing through
        -- the sun exactly as they show through everything else drawn on it.
        love.graphics.setColor(Palette.blush)
        pixelart.circleFill(x, y, r)
        love.graphics.setColor(Palette.red)
        pixelart.circleOutline(x, y, r)

        for i = 0, SPOKES - 1 do
            local a = self.spin + i * step
            local c, s = math.cos(a), math.sin(a)
            pixelart.line(x + c * (r + RAY_GAP), y + s * (r + RAY_GAP),
                x + c * (r + RAY_GAP + len), y + s * (r + RAY_GAP + len))
        end

        love.graphics.setColor(1, 1, 1)
        face:draw(x + dx * self.def.radius * FACE_OUT,
            y + dy * self.def.radius * FACE_OUT)
    end)
end

return Sun
