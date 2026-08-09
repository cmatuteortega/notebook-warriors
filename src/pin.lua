-- A pushpin, driven into the page.
--
-- Every other tool is a brush: you hold the pointer down and a line grows under
-- it. This one is not drawn, it is *placed*. Tap the page and a pin drops on
-- that spot, and the landing punches a circle out of the horde -- one hit, big
-- enough to kill anything but the toughest thing in the game, and whatever
-- lives through it is pinned to the paper until the pin comes back out.
--
-- The fall is not a delay for its own sake. It is what turns the ring on the
-- page into a promise rather than a report: you can see where it is going to
-- land before it lands, and so can the blob walking out of it. A quarter of a
-- second is about eleven pixels of bat, which is what stops a tap on a moving
-- target from being a certainty.
--
-- It lands once. There is no second tick, nothing to stand on and nothing to
-- walk into afterwards -- the pin is spent the moment it arrives, and what is
-- left on the page is a marker for how long the things around it stay still.
--
-- And then it stays there, exactly as it went in. A pin is not a mark, it is an
-- object driven through the paper: paper does not let go of one and it does not
-- fade, because fading is what ink does and this is not ink. This is the one
-- thing in the game that accumulates -- everything else goes -- so a long run is
-- read back off the page afterwards as the places you were in trouble.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")

local Pin = {}
Pin.__index = Pin

local FALL = 0.28   -- seconds from the tap to the landing
local LIFT = 30     -- how far above the page it starts, in pixels
local SHOCK = 0.18  -- how long the ring stays inked after the landing

function Pin.new(def, x, y)
    return setmetatable({
        def = def,
        x = x, y = y,
        fall = FALL,
        age = 0,
        shock = 0,
        landed = false,
    }, Pin)
end

-- Everything inside the circle at once: one hit each, and one chance to stick.
-- Backwards, because a kill takes an enemy out of the list underneath us.
function Pin:land(game)
    local def = self.def

    -- Paper fibres off the puncture, then whatever the circle caught.
    game.particles:burst(self.x, self.y, 9, Palette.graphite)

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        local dx, dy = e.x - self.x, e.y - self.y
        local reach = def.radius + e.radius

        if dx * dx + dy * dy < reach * reach then
            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(def.damage) then
                game:killEnemy(i)
            elseif e:freeze(def.freeze) then
                -- Only the ones still standing get held, and only the first
                -- time each -- the same splash of blue the gluestick spends.
                game.particles:burst(e.x, e.y, 3, Palette.sky)
            end
        end
    end
end

-- Returns false once it has finished holding. It is not thrown away then --
-- the game moves it to the spent pile and stops updating it -- so this is
-- "nothing about me will ever change again" rather than "remove me".
function Pin:update(dt, game)
    if not self.landed then
        self.fall = self.fall - dt
        if self.fall <= 0 then
            self.landed = true
            self.shock = SHOCK
            self:land(game)
        end
        return true
    end

    self.age = self.age + dt
    self.shock = math.max(0, self.shock - dt)
    return self.age < self.def.life
end

-- The ring and the shadow belong to the page, so they are drawn with the ink
-- and under everything standing on it -- a shadow painted over the top of the
-- crowd it is falling into would be a shadow on the crowd. The ring starts as
-- the pencil circle the pin is aimed at, and the landing inks it and throws it
-- outwards.
--
-- Named for what it is rather than what it looks like, because the stapler
-- answers the same call with a crease instead of a ring: both are things that
-- were tapped onto the page, and the game draws them from one list.
function Pin:drawMark()
    if not self.landed then
        local t = 1 - self.fall / FALL

        love.graphics.setColor(Palette.graphite)
        pixelart.circleOutline(self.x, self.y, self.def.radius)

        -- Closing up under the pin: the pin's own height off the page cannot
        -- say how far there is left to fall on its own.
        local w = 1 + math.floor(t * 4)
        love.graphics.rectangle("fill",
            math.floor(self.x) - math.floor(w / 2), math.floor(self.y), w, 1)
    elseif self.shock > 0 then
        local out = math.floor((1 - self.shock / SHOCK) * 3)
        love.graphics.setColor(Palette.slate)
        pixelart.circleOutline(self.x, self.y, self.def.radius + out)
    end
end

-- The pin itself is an object above the paper rather than a mark on it, so it
-- is drawn with the things that stand on the page.
function Pin:draw()
    local y = self.y

    if not self.landed then
        -- Squared, so it gathers speed on the way down instead of drifting in.
        local t = 1 - self.fall / FALL
        y = self.y - LIFT * (1 - t * t)
    end

    -- The same pin whatever it is doing. It does not fade as its hold runs out
    -- and it does not fade afterwards: a mark on paper fades, and this is not a
    -- mark -- it is a thing stuck through the page, and it looks the same on the
    -- last frame of the run as it did going in. What the hold is doing is read
    -- off the enemy instead, which stops moving and grows a blue shadow.
    love.graphics.setColor(1, 1, 1)
    Sprites.pin:draw(self.x, y)
end

return Pin
