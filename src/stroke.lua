-- One mark on the page.
--
-- A stroke is a chain of brush stamps laid down at a fixed spacing as the head
-- moves, which is what keeps the line even no matter how fast the pointer
-- travels. Damage is applied to the *segment* between the old and new head, so
-- a fast flick can't tunnel past an enemy between frames.
--
-- Marks are anchored in world space: they stay on the paper where you drew
-- them while the camera scrolls away.

local Palette = require("src.palette")
local util = require("src.util")

local Stroke = {}
Stroke.__index = Stroke

local PATH_STEP = 4    -- how coarsely the path is recorded for lingering damage
local DITHER_START = 0.55 -- fraction of life after which stamps start dropping out

function Stroke.new(tool, x, y)
    return setmetatable({
        tool = tool,
        x = x, y = y,       -- the head
        tx = x, ty = y,     -- smoothed target, for nibs that trail the pointer
        -- A tool can be pure utility (the pen is), in which case there is no
        -- reason to ever run the hit test.
        touches = tool.damage > 0 or tool.knock > 0 or tool.freeze ~= nil,
        stamps = {},
        path = { x, y },    -- coarse polyline, used by lingering tools
        -- Everything the mark has covered, so asking "am I standing on it"
        -- is four comparisons in the overwhelmingly common case of "no".
        minX = x, minY = y, maxX = x, maxY = y,
        hit = {},           -- enemy -> time last hit by this stroke
        seed = love.math.random() * 997,
        i = 0,              -- stamp counter, doubles as each stamp's noise seed
        carry = 0,          -- leftover distance, keeps spacing even across frames
        age = 0,
        active = true,
        tick = 0,
    }, Stroke)
end

function Stroke:addStamp(x, y, game)
    self.i = self.i + 1
    self.stamps[#self.stamps + 1] = { x = math.floor(x), y = math.floor(y), i = self.i }

    if x < self.minX then self.minX = x elseif x > self.maxX then self.maxX = x end
    if y < self.minY then self.minY = y elseif y > self.maxY then self.maxY = y end

    local speck = self.tool.speck
    if speck and util.hash01(self.i, self.seed, 21) < speck.chance then
        game.particles:burst(x, y, 1, speck.color)
    end
end

-- Advances the head towards (x, y), spending at most `budget` pixels of line.
-- Returns how much was actually drawn.
function Stroke:extend(x, y, budget, game, dt)
    -- A smoothed nib chases the pointer instead of snapping to it, so shaky
    -- input and sharp direction changes come out as curves rather than kinks.
    if self.tool.smooth then
        local k = 1 - math.exp(-self.tool.smooth * dt)
        self.tx = self.tx + (x - self.tx) * k
        self.ty = self.ty + (y - self.ty) * k
        x, y = self.tx, self.ty
    end

    local dx, dy = x - self.x, y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.35 or budget <= 0 then return 0 end

    local used = math.min(dist, budget)
    local nx, ny = dx / dist, dy / dist
    local ax, ay = self.x, self.y
    local bx, by = ax + nx * used, ay + ny * used

    local t = self.carry
    while t <= used do
        self:addStamp(ax + nx * t, ay + ny * t, game)
        t = t + self.tool.spacing
    end
    self.carry = t - used

    if self.touches then
        self:damageSegment(game, ax, ay, bx, by)
    end

    self.x, self.y = bx, by
    local px, py = self.path[#self.path - 1], self.path[#self.path]
    if util.len(bx - px, by - py) >= PATH_STEP then
        self.path[#self.path + 1] = bx
        self.path[#self.path + 1] = by
    end

    return used
end

-- Is (x, y) standing on this mark? Used by surfaces rather than weapons, so it
-- answers for a point rather than resolving a hit.
function Stroke:covers(x, y)
    local reach = self.tool.radius
    if x < self.minX - reach or x > self.maxX + reach
        or y < self.minY - reach or y > self.maxY + reach then
        return false
    end

    local path = self.path
    for p = 1, #path - 3, 2 do
        if util.distToSegment(x, y, path[p], path[p + 1], path[p + 2], path[p + 3]) < reach then
            return true
        end
    end

    -- The path is only recorded every few pixels; the head runs on past it.
    local n = #path
    return util.distToSegment(x, y, path[n - 1], path[n], self.x, self.y) < reach
end

function Stroke:canHit(enemy, time)
    local last = self.hit[enemy]
    if not last then return true end
    return self.tool.rehit ~= nil and time - last >= self.tool.rehit
end

function Stroke:apply(game, enemy, index, ax, ay, bx, by)
    local tool = self.tool
    self.hit[enemy] = game.time

    if tool.knock > 0 then
        -- Push away from the line itself, so an eraser sweep shoves the horde
        -- sideways instead of along the direction you happened to be drawing.
        local vx, vy = bx - ax, by - ay
        local len2 = vx * vx + vy * vy
        local t = 0
        if len2 > 0 then
            t = ((enemy.x - ax) * vx + (enemy.y - ay) * vy) / len2
            t = t < 0 and 0 or (t > 1 and 1 or t)
        end
        local px, py = util.normalize(enemy.x - (ax + vx * t), enemy.y - (ay + vy * t))
        if px == 0 and py == 0 then px, py = util.normalize(-vy, vx) end
        enemy:knockback(px, py, tool.knock)
    end

    if tool.freeze and enemy:freeze(tool.freeze) then
        game.particles:burst(enemy.x, enemy.y, 3, Palette.sky)
    end

    -- A tool can be pure crowd control; don't flash an enemy that took nothing.
    if tool.damage > 0 then
        game.particles:burst(enemy.x, enemy.y, 2, Palette.red)
        if enemy:hurt(tool.damage) then
            game:killEnemy(index)
        end
    end
end

function Stroke:damageSegment(game, ax, ay, bx, by)
    local radius = self.tool.radius
    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if self:canHit(e, game.time)
            and util.distToSegment(e.x, e.y, ax, ay, bx, by) < radius + e.radius then
            self:apply(game, e, i, ax, ay, bx, by)
        end
    end
end

-- Highlighter only: everything standing on the band takes a tick of damage.
function Stroke:lingerTick(game)
    local path, radius = self.path, self.tool.radius
    if #path < 4 then return end

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if self:canHit(e, game.time) then
            for p = 1, #path - 3, 2 do
                local ax, ay, bx, by = path[p], path[p + 1], path[p + 2], path[p + 3]
                if util.distToSegment(e.x, e.y, ax, ay, bx, by) < radius + e.radius then
                    self:apply(game, e, i, ax, ay, bx, by)
                    break
                end
            end
        end
    end
end

function Stroke:finish()
    self.active = false
end

-- Returns false once the mark has faded off the page.
function Stroke:update(dt, game)
    if not self.active then
        self.age = self.age + dt
    end

    if self.tool.linger then
        self.tick = self.tick - dt
        if self.tick <= 0 then
            self.tick = self.tool.tickRate
            self:lingerTick(game)
        end
    end

    return self.age < self.tool.life
end

function Stroke:draw()
    local tool = self.tool
    local f = self.age / tool.life

    -- Fading happens in two palette-safe ways at once: the colour steps down
    -- the ramp, and individual stamps start dropping out. No alpha, so nothing
    -- ever blends into a ninth colour.
    local start = tool.fade or DITHER_START
    local dither = 0
    if f > start then
        dither = (f - start) / (1 - start)
    end

    local stamps = self.stamps
    local function pass(stamp, color, rough)
        love.graphics.setColor(color)
        local threshold = math.max(dither, rough or 0)
        for i = 1, #stamps do
            local s = stamps[i]
            if threshold == 0 or util.hash01(s.i, self.seed, 31) > threshold then
                stamp(s, self)
            end
        end
    end

    if tool.edge then
        pass(tool.edge.stamp, tool.edge.color, tool.edge.rough)
    end
    pass(tool.stamp, tool.ramp[math.min(#tool.ramp, math.floor(f * #tool.ramp) + 1)], tool.rough)

    -- Painted over the top of the finished mark, for texture the fill itself
    -- can't carry.
    if tool.holes then
        pass(tool.holes.stamp, tool.holes.color, tool.holes.rough)
    end
end

return Stroke
