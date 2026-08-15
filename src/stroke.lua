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
        drawn = 0,          -- total pixels of line so far, for tools with `flow`
        leanTick = 0,       -- next resting-tip hit is due at once: see update
        loopFrom = 1,       -- oldest path index a loop may still close against
        age = 0,
        active = true,
        tick = 0,
    }, Stroke)
end

-- (nx, ny) is the direction the head is travelling, which only a tool that
-- sheds debris rather than laying a dab has any use for.
function Stroke:addStamp(x, y, game, nx, ny)
    self.i = self.i + 1

    -- A brush can leave nothing on the page at all -- the rubber does. The walk
    -- along the segment still paces what comes off it, there is just no dab to
    -- keep.
    if self.tool.stamp then
        local stamp = { x = math.floor(x), y = math.floor(y), i = self.i }
        -- Stacked ink shows: with `stack`, a dab laid back over ground this
        -- stroke has already covered is marked, and draw() paints it in the
        -- pooled-ink colour -- so where the band will burn double is exactly
        -- where it reads deeper. A choice you cannot see is not one you can
        -- make.
        if self.tool.stack and self:revisits(x, y) then
            stamp.over = true
        end
        self.stamps[#self.stamps + 1] = stamp
    end

    if x < self.minX then self.minX = x elseif x > self.maxX then self.maxX = x end
    if y < self.minY then self.minY = y elseif y > self.maxY then self.maxY = y end

    local speck = self.tool.speck
    if speck and util.hash01(self.i, self.seed, 21) < speck.chance then
        game.particles:burst(x, y, 1, speck.color)
    end

    local crumbs = self.tool.crumbs
    if crumbs and util.hash01(self.i, self.seed, 22) < crumbs.chance then
        game.particles:crumb(x, y, nx, ny, self.tool.radius, crumbs.color)
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
        self:addStamp(ax + nx * t, ay + ny * t, game, nx, ny)
        t = t + self.tool.spacing
    end
    self.carry = t - used

    if self.touches then
        self:damageSegment(game, ax, ay, bx, by)
    end

    self.x, self.y = bx, by
    self.drawn = self.drawn + used
    local px, py = self.path[#self.path - 1], self.path[#self.path]
    if util.len(bx - px, by - py) >= PATH_STEP then
        self.path[#self.path + 1] = bx
        self.path[#self.path + 1] = by
        if self.tool.loop then
            self:tryCloseLoop(game)
        end
    end

    -- A tip that is travelling is scrubbing, not leaning: any real movement
    -- holds the resting hit back by a full cadence, so `lean` only pays and
    -- fires once the tip has genuinely come to rest.
    if self.tool.lean then
        self.leanTick = math.max(self.leanTick, self.tool.rehit)
    end

    return used
end

-- Even-odd ray cast over the tail of the path from `from`, treated as a closed
-- polygon (the last point joins back to the first). Enough geometry for a
-- hand-drawn lasso: a point grazing the ink itself lands either way, and at
-- pencil scale neither answer matters.
local function insideLoop(px, py, path, from)
    local inside = false
    local n = #path
    local x1, y1 = path[n - 1], path[n]
    for p = from, n - 1, 2 do
        local x2, y2 = path[p], path[p + 1]
        if (y2 > py) ~= (y1 > py) then
            if px < x1 + (py - y1) / (y2 - y1) * (x2 - x1) then
                inside = not inside
            end
        end
        x1, y1 = x2, y2
    end
    return inside
end

-- The pencil's last level: a line closed on itself cuts everything inside.
--
-- Checked each time a path point lands. A closing point must be old enough
-- that the ring has real perimeter -- MIN_LOOP points, so a wiggle is not a
-- lasso -- and no older than the last loop this stroke already closed: a close
-- spends the path behind it, so one circle is one cut and a spiral has to keep
-- travelling to keep cutting. The cut bypasses the stroke's hit list on
-- purpose -- being ringed and being scratched are different events, and an
-- enemy the line grazed on the way round is still inside the ring it drew.
local MIN_LOOP = 10   -- path points between the closing pair: ~40px of perimeter
local CLOSE_GAP = 4   -- how far past the radius still reads as "came back to it"

function Stroke:tryCloseLoop(game)
    local path = self.path
    local hx, hy = path[#path - 1], path[#path]
    local reach = self.tool.radius + CLOSE_GAP

    local from
    for p = self.loopFrom, #path - MIN_LOOP * 2, 2 do
        if util.len(path[p] - hx, path[p + 1] - hy) < reach then
            from = p
            break
        end
    end
    if not from then return end

    -- Everything from the touched point to the head is the ring, and it is
    -- spent the moment it closes.
    self.loopFrom = #path + 1
    game.particles:burst(hx, hy, 5, Palette.ink)

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if insideLoop(e.x, e.y, path, from) then
            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(self.tool.loop.damage) then
                game:killEnemy(i)
            end
        end
    end
end

-- Is (x, y) back over ground this stroke has already been over? The stretch
-- just behind the head doesn't count -- a stroke is always standing on its own
-- tail -- so the skip is measured off the reach: everything nearer along the
-- path than the radius could reach in a straight line is ignored, and only ink
-- old enough that the head must have *left and come back* answers. Used by
-- tools with `scrub` (Game:updateDrawing) to price a re-rub cheaper.
function Stroke:revisits(x, y)
    local path, reach = self.path, self.tool.radius
    local skip = math.ceil(reach / PATH_STEP) + 1
    local last = #path - 3 - skip * 2

    for p = 1, last, 2 do
        if util.distToSegment(x, y, path[p], path[p + 1], path[p + 2], path[p + 3]) < reach then
            return true
        end
    end
    return false
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

-- Which way (x, y) would be dragged into this mark, if it is close enough to
-- feel it: the direction to the nearest recorded point of the path, or nothing
-- outside `range` of the ink's edge. The gluestick's last level asks this
-- every frame for every free enemy, so the bounding box does the refusing for
-- almost all of them, the same way it does for covers -- and the path's
-- recorded points are near enough for a drag that a segment projection would
-- buy nothing.
function Stroke:pullTowards(x, y, range)
    local reach = self.tool.radius + range
    if x < self.minX - reach or x > self.maxX + reach
        or y < self.minY - reach or y > self.maxY + reach then
        return
    end

    local path = self.path
    local best, bx, by
    for p = 1, #path - 1, 2 do
        local dx, dy = path[p] - x, path[p + 1] - y
        local d = dx * dx + dy * dy
        if not best or d < best then
            best, bx, by = d, path[p], path[p + 1]
        end
    end
    -- Nothing to pull towards, out of reach, or already standing on the spot
    -- it would be pulled to -- a direction from a point to itself is noise.
    if not best or best > reach * reach or best < 1 then return end
    return util.normalize(bx - x, by - y)
end

function Stroke:canHit(enemy, time)
    local last = self.hit[enemy]
    if not last then return true end
    return self.tool.rehit ~= nil and time - last >= self.tool.rehit
end

-- `layers` is how many passes of the mark are lying over the enemy at once --
-- only ever above 1 for a lingering tool with `stack` (see lingerTick below) --
-- and it multiplies the damage alone: two layers of ink do not shove or hold
-- any harder than one.
function Stroke:apply(game, enemy, index, ax, ay, bx, by, layers)
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

        -- The rubber's last level: this shove is hard enough that what it
        -- sends flying is itself a weapon until it slows back down.
        if tool.ram then
            enemy:launch(tool.ram)
        end
    end

    -- The tool goes with the freeze: the gluestick's upper levels read their
    -- victim off the enemy afterwards (Enemy:hurt, Game:updateGlue).
    if tool.freeze and enemy:freeze(tool.freeze, tool) then
        game.particles:burst(enemy.x, enemy.y, 3, Palette.sky)
    end

    -- A tool can be pure crowd control; don't flash an enemy that took nothing.
    if tool.damage > 0 then
        local damage = tool.damage * (layers or 1)
        -- The pencil's crit level. Rolled live per hit, like a particle spawn,
        -- rather than hashed: a crit is an event that happens once, not stored
        -- variation that has to come out the same twice. It multiplies after
        -- the layers, and it is always announced -- a big number nobody saw
        -- land is indistinguishable from a bug.
        if tool.crit and love.math.random() < tool.crit.chance then
            damage = damage * tool.crit.mult
            game.particles:crit(enemy.x, enemy.y)
        end
        game.particles:burst(enemy.x, enemy.y, 2, Palette.red)
        if enemy:hurt(damage) then
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
--
-- With `stack`, ink laid over your own ink counts. What is counted is *passes*,
-- not segments: the path is recorded every few pixels, so a straight band over
-- an enemy is many covering segments in a row and has to read as one layer --
-- a new layer starts only where the path left the enemy and came back, which
-- is exactly what scribbling over a patch does. Capped at `stack`, or a tight
-- enough scribble would be a one-stroke pushpin. Without `stack` the first
-- covering segment settles it, exactly as before.
function Stroke:lingerTick(game)
    local path, radius = self.path, self.tool.radius
    if #path < 4 then return end
    local stack = self.tool.stack or 1

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if self:canHit(e, game.time) then
            local reach = radius + e.radius
            local layers, over = 0, false
            local ax, ay, bx, by
            for p = 1, #path - 3, 2 do
                local covers = util.distToSegment(e.x, e.y,
                    path[p], path[p + 1], path[p + 2], path[p + 3]) < reach
                if covers and not over then
                    layers = layers + 1
                    if layers == 1 then
                        ax, ay, bx, by = path[p], path[p + 1], path[p + 2], path[p + 3]
                    end
                    if layers >= stack then break end
                end
                over = covers
            end
            if layers > 0 then
                self:apply(game, e, i, ax, ay, bx, by, layers)
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

    -- The rubber's lean level: while the stroke is held down and the tip is at
    -- rest (extend pushes this timer back whenever the head moves), the tip
    -- itself keeps hitting where it sits -- a zero-length segment, so the
    -- shove goes radially off the tip -- and the hit list is shared with the
    -- moving stroke, so `rehit` paces the pair of them together. Starting at
    -- zero means the press itself lands one: touching them with the rubber is
    -- enough.
    --
    -- Each resting hit is priced as `lean.px` pixels of the tool's own ink, so
    -- the meter owns leaning the way it owns everything else -- through
    -- tool.ink, where the blotter's discount already lives. Too poor to pay
    -- and the tick simply waits, retrying as the meter creeps back.
    if self.active and self.tool.lean then
        self.leanTick = self.leanTick - dt
        if self.leanTick <= 0 then
            local price = self.tool.lean.px * self.tool.ink
            if game.ink >= price then
                self.leanTick = self.tool.rehit
                game:spendInk(price)
                self:damageSegment(game, self.x, self.y, self.x, self.y)
            end
        end
    end

    -- A stroke being drawn is never culled, whatever its life -- which is what
    -- lets a mark that leaves nothing behind set a life of zero and go the
    -- instant you let go.
    return self.active or self.age < self.tool.life
end

function Stroke:draw()
    local tool = self.tool
    if not tool.stamp then return end   -- nothing to draw: see Stroke:addStamp

    local f = self.age / tool.life

    -- Fading happens in two palette-safe ways at once: the colour steps down
    -- the ramp, and individual stamps start dropping out. No alpha, so nothing
    -- ever blends into a ninth colour.
    local start = tool.fade or DITHER_START
    local dither = 0
    if f > start then
        dither = (f - start) / (1 - start)
    end

    -- `over` filters by the stacked-ink mark: nil takes every stamp, false
    -- only the first pass, true only the dabs laid back over the stroke's own
    -- ink.
    local stamps = self.stamps
    local function pass(stamp, color, rough, over)
        love.graphics.setColor(color)
        local threshold = math.max(dither, rough or 0)
        for i = 1, #stamps do
            local s = stamps[i]
            if (over == nil or not s.over == not over)
                and (threshold == 0 or util.hash01(s.i, self.seed, 31) > threshold) then
                stamp(s, self)
            end
        end
    end

    if tool.edge then
        pass(tool.edge.stamp, tool.edge.color, tool.edge.rough)
    end

    local body = tool.ramp[math.min(#tool.ramp, math.floor(f * #tool.ramp) + 1)]
    if tool.stack then
        -- Where the band was worked over it is drawn in the edge's colour --
        -- the ink that pooled -- which for the highlighter is red over blush:
        -- the same deepening a real one shows on a second pass, and the map of
        -- exactly where the layers will burn together.
        pass(tool.stamp, body, tool.rough, false)
        pass(tool.stamp, tool.edge and tool.edge.color or body, tool.rough, true)
    else
        pass(tool.stamp, body, tool.rough)
    end

    -- Painted over the top of the finished mark, for texture the fill itself
    -- can't carry.
    if tool.holes then
        pass(tool.holes.stamp, tool.holes.color, tool.holes.rough)
    end
end

return Stroke
