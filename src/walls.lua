-- The solid parts of the page.
--
-- A pen line is a fence: enemies have to walk around it, the player crosses it
-- freely. Every wall stroke's coarse path is chopped into segments and dropped
-- into a spatial hash, so an enemy asks "what is near me" with one table
-- lookup rather than walking every mark on the page.
--
-- Rebuilt only when a wall stroke is drawn, grows or expires -- which means it
-- is rebuilt while you are drawing and sits still the rest of the time.

local util = require("src.util")

local Walls = {}
Walls.__index = Walls

local CELL = 16
-- Segments are filed under every cell within this much of them, so a query
-- only has to look at the single cell the enemy is standing in. It has to
-- cover the biggest enemy radius plus how far ahead a wall is felt.
local PAD = 14

local function cellKey(cx, cy)
    return cx * 100000 + cy
end

function Walls.new()
    return setmetatable({ grid = {}, count = 0 }, Walls)
end

function Walls:add(ax, ay, bx, by, radius)
    local seg = { ax = ax, ay = ay, bx = bx, by = by, r = radius }
    self.count = self.count + 1

    local pad = PAD + radius
    local x0 = math.floor((math.min(ax, bx) - pad) / CELL)
    local x1 = math.floor((math.max(ax, bx) + pad) / CELL)
    local y0 = math.floor((math.min(ay, by) - pad) / CELL)
    local y1 = math.floor((math.max(ay, by) + pad) / CELL)

    for cy = y0, y1 do
        for cx = x0, x1 do
            local k = cellKey(cx, cy)
            local bucket = self.grid[k]
            if not bucket then
                bucket = {}
                self.grid[k] = bucket
            end
            bucket[#bucket + 1] = seg
        end
    end
end

function Walls:rebuild(strokes)
    self.grid = {}
    self.count = 0

    for _, s in ipairs(strokes) do
        if s.tool.wall then
            local path, r = s.path, s.tool.radius
            for i = 1, #path - 3, 2 do
                self:add(path[i], path[i + 1], path[i + 2], path[i + 3], r)
            end
            -- The path only records a point every few pixels, so without this
            -- the last stretch of a line you are still drawing wouldn't block
            -- anything -- the wall would lag behind the nib.
            local n = #path
            if s.x ~= path[n - 1] or s.y ~= path[n] then
                self:add(path[n - 1], path[n], s.x, s.y, r)
            end
        end
    end
end

-- Every segment that could be within PAD of (x, y).
function Walls:each(x, y, fn)
    if self.count == 0 then return end
    local bucket = self.grid[cellKey(math.floor(x / CELL), math.floor(y / CELL))]
    if not bucket then return end
    for i = 1, #bucket do
        fn(bucket[i])
    end
end

-- Closest point on a segment to (x, y), and how far away it is.
function Walls.closest(seg, x, y)
    local vx, vy = seg.bx - seg.ax, seg.by - seg.ay
    local len2 = vx * vx + vy * vy
    local t = 0
    if len2 > 0 then
        t = ((x - seg.ax) * vx + (y - seg.ay) * vy) / len2
        t = t < 0 and 0 or (t > 1 and 1 or t)
    end
    local cx, cy = seg.ax + vx * t, seg.ay + vy * t
    return cx, cy, util.len(x - cx, y - cy)
end

-- Which way is "out of the wall". Standing exactly on the line there is no
-- such direction, so fall back to the segment's own perpendicular.
function Walls.normalOut(seg, ox, oy)
    local nx, ny = util.normalize(ox, oy)
    if nx == 0 and ny == 0 then
        nx, ny = util.normalize(-(seg.by - seg.ay), seg.bx - seg.ax)
        if nx == 0 and ny == 0 then return 0, -1 end
    end
    return nx, ny
end

return Walls
