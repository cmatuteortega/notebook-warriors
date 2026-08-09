local util = {}

function util.clamp(v, lo, hi)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

function util.lerp(a, b, t)
    return a + (b - a) * t
end

function util.len(x, y)
    return math.sqrt(x * x + y * y)
end

function util.normalize(x, y)
    local l = math.sqrt(x * x + y * y)
    if l == 0 then return 0, 0, 0 end
    return x / l, y / l, l
end

-- Distance from a point to a line segment. Every brush stroke is a chain of
-- these, so this is what decides whether a stroke touched an enemy.
function util.distToSegment(px, py, ax, ay, bx, by)
    local vx, vy = bx - ax, by - ay
    local len2 = vx * vx + vy * vy
    local t = 0
    if len2 > 0 then
        t = ((px - ax) * vx + (py - ay) * vy) / len2
        t = t < 0 and 0 or (t > 1 and 1 or t)
    end
    local dx, dy = ax + vx * t - px, ay + vy * t - py
    return math.sqrt(dx * dx + dy * dy)
end

-- Deterministic value noise in [0,1). Same inputs always give the same result,
-- which is what lets the background generate itself on the fly without storing
-- anything: doodle placement is a pure function of the cell coordinates.
function util.hash01(x, y, seed)
    local n = math.sin(x * 127.1 + y * 311.7 + (seed or 0) * 74.7) * 43758.5453123
    return n - math.floor(n)
end

function util.hashInt(x, y, seed, count)
    return 1 + math.floor(util.hash01(x, y, seed) * count) % count
end

return util
