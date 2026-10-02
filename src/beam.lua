-- Passive weapon, and the only one you aim: a beam down the heading you are
-- walking, on a charge / fire / rest cycle. The one weapon aimed at *any* angle
-- -- a sprite must round its heading to the eight `pixelart.turn` bakes, but
-- `pixelart.line`/`band` plot whole pixels along any heading at all, so the aim
-- is the walk vector itself, live through the wind-up and latched at the shot.

local Camera = require("src.camera")
local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Beam = {}
Beam.__index = Beam

-- Off the shoulder, the same pixel the auto-shot and the rockets leave from.
local MUZZLE_Y = -1

-- The pointer, as distances from the muzzle to each of its ends. The near end
-- clears the hero at his tallest (15x19, so 9 and a half from the middle to the
-- top of his head) in every direction it can point.
local SIGHT_IN, SIGHT_OUT = 12, 20

-- The flash: how long before the shot it starts, and the blink period at each
-- end of that. Both periods are well above a frame at 60fps, so the flicker is
-- seen rather than fighting the refresh rate.
local FLASH_FOR = 0.45
local BLINK_SLOW, BLINK_FAST = 0.15, 0.05

-- The arms, as turns of the aim in the order the levels buy them: ahead, then
-- behind. A sign flip rather than an angle, so a half turn of a unit vector is
-- exact. Two and not four -- a cross stops reading as something you aimed.
local ARMS = {
    function(dx, dy) return dx, dy end,
    function(dx, dy) return -dx, -dy end,
}

-- Slack on the circle the horde is asked for, so a thing off the end of the
-- beam at the far corner of the band still reaches the test that decides: half
-- the widest beam the line can buy plus the biggest enemy, 4 and 6.
local SLACK = 12

-- The cycle, in order. `rest` is the one part with no length on the block -- it
-- is whatever `every` has left after the wind-up and the beam, which is what
-- makes `every` beam-to-beam, wind-up included.
local NEXT = { charge = "fire", fire = "rest", rest = "charge" }

-- Distance from a point to the viewport edge along a unit heading. Each half is
-- guarded rather than divided by zero: a heading flat to an axis never meets
-- those two edges.
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
        -- Winding up, not resting, so taking the level shows what you bought.
        phase = "charge",
        t = 0,
        tick = 0,
        -- The heading the beam out this instant is going down, latched at the
        -- shot. Unread while only the pointer is up -- that follows your feet.
        faceX = 1, faceY = 0,
    }, Beam)
end

function Beam:configure(def)
    self.def = def
end

--- the cycle ------------------------------------------------------------------

-- What is left of the period once the wind-up and the beam have taken theirs.
-- Floored at nothing: the levels that lengthen the beam and the one that halves
-- the period are bought separately, so a run can reach a shape where they no
-- longer fit -- a weapon with no gap, rather than a clock running backwards.
function Beam:rest()
    local def = self.def
    return math.max(0, def.every - def.charge - def.hold)
end

function Beam:lasts(phase)
    if phase == "charge" then return self.def.charge end
    if phase == "fire" then return self.def.hold end
    return self:rest()
end

-- Where the sight points: the way you are walking, or last walked, exactly --
-- not rounded to anything (see the header).
function Beam:aim(game)
    return game.player.headX, game.player.headY
end

--- firing ---------------------------------------------------------------------

-- Every arm of one shot, as the way along it, all turned off the same aim.
function Beam:each(dx, dy, fn)
    for i = 1, self.def.arms do
        fn(ARMS[i](dx, dy))
    end
end

-- Every arm as a line: heading, start, and length before the page runs out. The
-- one place the viewport is read, so the flash, the beam and the damage are one
-- segment by construction. Starts at the pointer's tip (SIGHT_OUT), so the
-- sight is the barrel and the hero is never under his own beam; an arm already
-- off the page comes out negative and is skipped.
function Beam:eachLine(x, y, dx, dy, fn)
    local left, top, w, h = Camera.bounds()

    self:each(dx, dy, function(ax, ay)
        local sx, sy = x + ax * SIGHT_OUT, y + ay * SIGHT_OUT
        local len = toEdge(sx, sy, ax, ay, left, top, w, h)
        if len > 0 then fn(ax, ay, sx, sy, len) end
    end)
end

-- Everything standing on one arm, once. `eachWithin` rather than `eachNear`: a
-- beam is as long as the page is wide, and this runs on a tick a few times a
-- second rather than every frame. Tested in the beam's own frame -- how far
-- along, how far off -- so the gap the pointer occupies is a real dead zone
-- around you, and a thing already touching you is the stars' problem.
function Beam:cut(game, x, y, dx, dy, len, damage, struck)
    local half = self.def.width / 2

    game:eachWithin(x, y, len + SLACK, function(e)
        if struck[e] then return end

        local ex, ey = e.x - x, e.y - y
        local along = ex * dx + ey * dy
        if along < 0 or along > len then return end
        if math.abs(ex * -dy + ey * dx) > half + e.radius then return end

        -- One thing is hit once however many arms cross it. Unreachable while
        -- the arms are two ends of one line starting clear of you, but a third
        -- arm or a muzzle start brings the crossing straight back.
        struck[e] = true
        game.particles:burst(e.x, e.y, 2, Palette.red)
        if e:hurt(damage) then
            game:killEnemyAt(e)
        end
    end)
end

-- One tick of one shot: every arm, against everything standing on it. Damage is
-- read here rather than carried, unlike the rocket's -- nothing about a beam
-- outlives the instant it fires, so an upgrade mid-hold lands on that hold.
function Beam:strike(game)
    local stats = game.loadout.stats
    -- Graphite sharpens passives; the global multiplier lands on everything.
    local damage = self.def.damage * stats.passiveDamage * stats.damage

    local x, y = game.player.x, game.player.y + MUZZLE_Y
    local struck = {}

    self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, sx, sy, len)
        self:cut(game, sx, sy, dx, dy, len, damage, struck)
    end)
end

function Beam:update(dt, game, grid)
    -- A loop rather than an if, so a frame long enough to swallow a phase lands
    -- in the right one. `charge` and `hold` are above zero on every block the
    -- line can build, so it terminates even with the rest squeezed to nothing.
    self.t = self.t + dt
    while self.t >= self:lasts(self.phase) do
        self.t = self.t - self:lasts(self.phase)
        self.phase = NEXT[self.phase]

        if self.phase == "fire" then
            -- The aim stops following your feet here and nowhere else: what is
            -- latched is what the flash was promising on its last frame.
            self.faceX, self.faceY = self:aim(game)
            self.tick = 0

            -- A spark at each muzzle rather than one at the player: the beam is
            -- what comes out of the pointer, so that is where the light is.
            self:eachLine(game.player.x, game.player.y + MUZZLE_Y,
                self.faceX, self.faceY, function(_, _, sx, sy)
                    game.particles:burst(sx, sy, 4, Palette.red)
                end)
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

-- Whether the flash is lit. It runs over the last FLASH_FOR of the wind-up, or
-- the whole of it on a shorter block, and its period shortens as it goes, so
-- the blink runs away with itself towards the shot.
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

    -- The pointer, always, once per arm the run has bought. The only part still
    -- following your feet while a beam is out, so it says where the *next* one
    -- goes. First, so the flash and the beam cover it rather than it scratching
    -- through them.
    love.graphics.setColor(Palette.slate)
    self:each(liveX, liveY, function(dx, dy)
        pixelart.line(x + dx * SIGHT_IN, y + dy * SIGHT_IN,
            x + dx * SIGHT_OUT, y + dy * SIGHT_OUT)
    end)

    -- The flash, one pixel wide down the whole line the beam will take. Sky
    -- rather than blue: it is the shot drawn thin, not a shot already happened.
    if self:flashing() then
        love.graphics.setColor(Palette.sky)
        self:eachLine(x, y, liveX, liveY, function(dx, dy, sx, sy, len)
            pixelart.line(sx, sy, sx + dx * len, sy + dy * len)
        end)
        return
    end

    if self.phase ~= "fire" then return end

    -- Sky through the middle with a one-pixel blue edge: sky alone is lost
    -- against the paper, blue alone a bar you cannot see through. The edge is
    -- the same band drawn two pixels narrower on top rather than two lines laid
    -- beside it, so it is whatever `pixelart.band`'s outermost pixels are at
    -- that angle and cannot come apart at a seam. Both darken over the ruling
    -- (Palette.overprint). The near end is capped with a disc, since the band's
    -- cut is only square to the axis and that end is now something you look at.
    local width = self.def.width
    local cap = math.floor(width / 2)

    love.graphics.setColor(Palette.blue)
    self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, sx, sy, len)
        pixelart.band(sx, sy, sx + dx * len, sy + dy * len, width)
        pixelart.circleFill(sx, sy, cap)
    end)

    -- Every edge before any middle, so where two arms cross one beam's edge can
    -- never sit in another beam's light. The cap is a ring the same way.
    if width > 2 then
        love.graphics.setColor(Palette.sky)
        self:eachLine(x, y, self.faceX, self.faceY, function(dx, dy, sx, sy, len)
            pixelart.band(sx, sy, sx + dx * len, sy + dy * len, width - 2)
            pixelart.circleFill(sx, sy, cap - 1)
        end)
    end
end

return Beam
