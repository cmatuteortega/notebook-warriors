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
-- Both of the things it hits with are asked of the run rather than of the
-- spatial hash, and for one reason: a disc eighty pixels across and a ray a
-- hundred and thirty long are both far wider than the nine 12px cells
-- `Game:eachNear` looks in. So the sun asks `Game:eachWithin`, which is the
-- whole horde -- affordable because it is asked twice a second on a tick rather
-- than every frame, the same bargain `Game:nearestEnemy` makes.
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

-- Where the face sits, as a fraction of the disc's resting radius along the
-- diagonal into the page. Measured off the resting radius rather than off the
-- pulse, so the face holds still while the disc breathes around it -- a face
-- that slid in and out with the rim would read as the sun leaning at you.
local FACE_OUT = 0.45

-- How near a sunray a thing has to be, on top of its own radius. Three pixels
-- for a one-pixel line: a ray that only caught what it drew over would be a
-- weapon you had to aim, and nothing about the sun is aimed.
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
        -- A volley of sunrays is one thing rather than a list of lines: they all
        -- go at once, so all it takes to draw them is the angle the sun was at
        -- when they went and how long they have left. Keeping the angle rather
        -- than the lines is what lets them stay stuck to a sun whose corner is
        -- moving under a camera that is following the player.
        rayT = 0,
        rayLife = 0,
        raySpin = 0,
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

-- The last level: the rays it has been drawn with all along reach across the
-- page and cut down them. Hit-scan rather than something that flies, because
-- what is being fired is the drawing -- the line is out and done in a fifth of
-- a second, and a ray you could walk out of the way of would be a different
-- weapon.
--
-- Only at full height. A volley thrown while the sun is still coming up would
-- rake the page from a disc that is mostly still under the corner, at an angle
-- nothing on screen could have seen coming.
function Sun:shoot(dt, game)
    local rays = self.def.rays

    self.rayLife = math.max(0, self.rayLife - dt)
    if self:height() < 1 then return end

    self.rayT = self.rayT - dt
    if self.rayT > 0 then return end
    self.rayT = rays.every

    self.rayLife = rays.life
    self.raySpin = self.spin

    local stats = game.loadout.stats
    local damage = rays.damage * stats.passiveDamage * stats.damage
    local step = TWO_PI / SPOKES

    self:each(function(x, y)
        game:eachWithin(x, y, rays.length, function(e)
            local dx, dy = e.x - x, e.y - y
            -- Which ray it is nearest, and how far off that one it is: the
            -- perpendicular distance is the distance out times the sine of the
            -- angle between. Cheaper than testing twelve segments, and exactly
            -- the same answer.
            local off = (math.atan2(dy, dx) - self.raySpin) % step
            local delta = math.min(off, step - off)
            local d = math.sqrt(dx * dx + dy * dy)

            if d * math.sin(delta) < RAY_R + e.radius then
                game.particles:burst(e.x, e.y, 2, Palette.red)
                if e:hurt(damage) then
                    game:killEnemyAt(e)
                end
            end
        end)
    end)
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
    if def.rays then self:shoot(dt, game) end
end

--- drawing --------------------------------------------------------------------

function Sun:draw(game)
    local face = Sprites.sunface
    local rays = self.def.rays
    local step = TWO_PI / SPOKES

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
                x + c * (r + RAY_GAP + RAY_LEN), y + s * (r + RAY_GAP + RAY_LEN))
        end

        if self.rayLife > 0 then
            for i = 0, SPOKES - 1 do
                local a = self.raySpin + i * step
                local c, s = math.cos(a), math.sin(a)
                pixelart.line(x + c * (r + RAY_GAP), y + s * (r + RAY_GAP),
                    x + c * rays.length, y + s * rays.length)
            end
        end

        love.graphics.setColor(1, 1, 1)
        face:draw(x + dx * self.def.radius * FACE_OUT,
            y + dy * self.def.radius * FACE_OUT)
    end)
end

return Sun
