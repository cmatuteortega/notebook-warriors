-- A staple, driven into the page.
--
-- The pushpin's opposite number, and used identically: you tap the paper and
-- one lands where you tapped. Everything else about the two is the other way
-- round.
--
-- A pin is one big expensive decision -- most of half the meter, a quarter of a
-- second in the air, a 41px crater, and enough damage to kill everything caught
-- in it but the tank. A staple is a tenth of the meter, it lands the instant
-- you tap, it reaches 15px and it does 2, which is a bat and nothing else. It
-- is not an attack, it is a fastener. What it does is hold one thing to the
-- paper for two seconds, and the way you use it is to keep tapping: a row of
-- them across the front of the horde, or three into the blob about to reach
-- you.
--
-- Nothing about it is telegraphed, because there is nothing to dodge. The pin's
-- fall is what stops a tap on a moving target being a certainty; a staple has
-- no fall at all, and what keeps it honest instead is that hitting barely hurts
-- and the circle is small enough to miss with.
--
-- It goes in flat, or leaning a few degrees one way or the other, which is the
-- one thing a page full of them needs: twenty staples lying at exactly the same
-- angle read as a pattern printed on the paper rather than as twenty separate
-- decisions.

local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Staple = {}
Staple.__index = Staple

local CROWN = 10    -- the bar across the top
local LEG = 3       -- how far the ends turn down into the paper

-- How far off flat it can land: nothing, or a lean of a few degrees either way.
--
-- A staple goes into the page the way the stapler was held, which is very
-- nearly square and never far from it. The lean is there so that twenty of them
-- do not read as a pattern printed on the paper, and it is kept this small for
-- the same reason it exists -- past about fifteen degrees the legs stop landing
-- square under the crown and the shape reads as an arrow instead of a staple.
-- At ten it is a bar with a pixel of slope in it, which is exactly what a
-- hand-placed staple looks like.
local LEAN_MIN = math.rad(5)
local LEAN_MAX = math.rad(10)

local function pickLean()
    -- Flat as often as either lean, so the upright one stays the one you read
    -- the tool by.
    local which = love.math.random(3)
    if which == 1 then return 0 end

    local a = LEAN_MIN + love.math.random() * (LEAN_MAX - LEAN_MIN)
    return which == 2 and a or -a
end

function Staple.new(def, x, y)
    return setmetatable({
        def = def,
        x = x, y = y,
        angle = pickLean(),
        age = 0,
        landed = false,
    }, Staple)
end

-- Everything inside the small circle at once, which in practice is one thing.
-- Backwards, because a kill takes an enemy out of the list underneath us.
function Staple:bite(game)
    local def = self.def

    game.particles:burst(self.x, self.y, 3, Palette.graphite) -- fibres

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

-- Returns false once it has finished holding -- which is not the same as being
-- finished with. Like the pushpin it is driven through the paper rather than
-- drawn on it, and it never comes back out: the game moves it to the spent pile
-- and stops updating it, and it stays on the page for the rest of the run.
--
-- It bites on the frame it is placed. There is no fall to wait out, which is
-- the whole feel of the tool: a stapler goes down and it is done.
function Staple:update(dt, game)
    if not self.landed then
        self.landed = true
        self:bite(game)
    end

    self.age = self.age + dt
    return self.age < self.def.life
end

-- Where the crown and the legs are, given the tilt it went in at.
function Staple:span()
    local ca, sa = math.cos(self.angle), math.sin(self.angle)
    return ca * CROWN / 2, sa * CROWN / 2,  -- half the crown, along it
           -sa * LEG, ca * LEG              -- a leg, square to it
end

-- The page's share of it: the scrap of ground it stands on, the same bar every
-- monster gets. It belongs to the page, so it goes under everything standing on
-- it -- a shadow painted over the top of the crowd would be a shadow on the
-- crowd.
--
-- Deliberately not the shape of the staple. A graphite copy of the crown offset
-- a pixel reads as a doubled line at this size rather than as a shadow, and on
-- the diagonals it fills in the gap that makes the shape legible at all.
function Staple:drawMark()
    local hx, hy, lx, ly = self:span()

    -- As wide as the staple actually is, and directly under its lowest pixel.
    -- Both change with the tilt: a fixed bar sits out to one side of the ones
    -- standing on their end and reads as a smudge rather than as ground.
    local w = math.max(3, math.floor(math.abs(hx) * 2 + math.abs(lx) + 0.5))
    local drop = math.floor(math.abs(hy) + math.max(0, ly)) + 1

    -- The crown is centred on the anchor but the legs hang off one side of it,
    -- so the shape's middle is half a leg over from where the staple is.
    love.graphics.setColor(Palette.graphite)
    love.graphics.rectangle("fill",
        math.floor(self.x + lx / 2) - math.floor(w / 2),
        math.floor(self.y) + drop, w, 1)
end

-- The staple itself is an object above the paper rather than a mark in it, so
-- it is drawn with the things that stand on the page. Same reasoning as the
-- pin: a staple you cannot see behind a blob is one you cannot aim the next one
-- off, and aiming the next one off the last is the whole of how this tool is
-- used.
--
-- The same staple whatever it is doing. It does not fade as its hold runs out
-- and it does not fade afterwards -- fading is what ink does, and a staple is
-- not ink, it is wire through paper. What the hold is doing is read off the
-- enemy instead, which stops moving and grows a blue shadow.
function Staple:draw()
    local hx, hy, lx, ly = self:span()

    love.graphics.setColor(Palette.ink)

    -- The crown, then a leg down from each end of it. At this lean the crown is
    -- a flat run with a single pixel of step in it and the legs come out square,
    -- which is the whole reason the lean is kept small.
    pixelart.line(self.x - hx, self.y - hy, self.x + hx, self.y + hy)
    pixelart.line(self.x - hx, self.y - hy, self.x - hx + lx, self.y - hy + ly)
    pixelart.line(self.x + hx, self.y + hy, self.x + hx + lx, self.y + hy + ly)
end

return Staple
