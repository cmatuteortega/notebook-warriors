-- The box the boss fight happens in: the rest of a run is an infinite page, and
-- the eye is deliberately slower than the player (src/enemy.lua), so without a
-- box the honest way to beat it is to walk in a straight line for half an hour.
-- Pinned where the *player* stands when it goes up, so nobody is handed a wall
-- at their back before seeing what put it there.
--
-- Nothing here is a wall in the `src/walls.lua` sense -- nobody crosses it and
-- there is no outside to path around. It is a clamp applied after everything
-- else has finished moving, which is why it always wins over knockback.

local Palette = require("src.palette")
local util = require("src.util")

local Arena = {}
Arena.__index = Arena

-- How much bigger than the screen the box is, on each axis. 1.5 is what the
-- fight is balanced on: 480x270 on a 320x180 page, so you see under half of it
-- at a time and must carry the edges in your head. Tighter and the eye stands
-- on you from the first second; wider and you can kite the whole half minute.
local SPAN = 1.5

-- Drawn a whisker inside the clamp, so the line is on the page rather than being
-- the first pixel you are not allowed to stand on.
local INSET = 1

-- The wobble on the edge: this is drawn by hand, not printed like the
-- background's dead-straight ruling.
local WOBBLE = 1.6

function Arena.new(cx, cy, vw, vh)
    local w, h = math.floor(vw * SPAN), math.floor(vh * SPAN)
    return setmetatable({
        left = math.floor(cx - w / 2),
        top = math.floor(cy - h / 2),
        w = w, h = h,
        t = 0,          -- how long it has been up, for the drawing-on
        seed = love.math.random() * 613,
    }, Arena)
end

function Arena:right() return self.left + self.w end
function Arena:bottom() return self.top + self.h end

function Arena:update(dt)
    self.t = self.t + dt
end

-- Somewhere inside, with `pad` of clearance. Everything that moves asks for it
-- *after* it has moved, so nothing has to know the box exists while deciding
-- where to go.
function Arena:clamp(x, y, pad)
    pad = pad or 0
    return util.clamp(x, self.left + pad, self:right() - pad),
           util.clamp(y, self.top + pad, self:bottom() - pad)
end

function Arena:contains(x, y)
    return x >= self.left and x <= self:right()
        and y >= self.top and y <= self:bottom()
end

-- A point inside, `pad` off the edge, for anything placing something in here
-- rather than moving something already in it -- the eye's tears, the escort.
function Arena:somewhere(pad)
    pad = pad or 0
    return self.left + pad + love.math.random() * (self.w - pad * 2),
           self.top + pad + love.math.random() * (self.h - pad * 2)
end

--- drawing -------------------------------------------------------------------

-- How long the four edges take to draw themselves in. Purely cosmetic: the
-- clamp is in force from the first frame, the line is only catching up.
local DRAW_TIME = 0.75

-- One edge, wobbled off the seed. Plotted a pixel at a time:
-- love.graphics.line is never used (see the rendering rules).
function Arena:edge(x1, y1, x2, y2, along, key)
    local steps = math.max(math.abs(x2 - x1), math.abs(y2 - y1))
    if steps <= 0 then return end

    local drawn = math.floor(steps * along)
    for i = 0, drawn do
        local f = i / steps
        local x = math.floor(x1 + (x2 - x1) * f)
        local y = math.floor(y1 + (y2 - y1) * f)
        -- Perpendicular jitter: the edge wanders a pixel or so the way a line
        -- drawn against no ruler does.
        local n = util.hash01(i, key, self.seed) - 0.5
        local off = math.floor(n * WOBBLE)
        if x1 == x2 then x = x + off else y = y + off end
        love.graphics.rectangle("fill", x, y, 1, 1)
    end
end

-- Red, which is the colour this game says "this matters" in -- the level
-- heading, the MAX on a finished card, the boss's own health bar. A box round
-- the fight is the same sentence as all three, and blush is already the printed
-- margin the page came with, so the drawn one has to be the louder of the two.
function Arena:draw()
    local along = util.clamp(self.t / DRAW_TIME, 0, 1)
    local l, t = self.left + INSET, self.top + INSET
    local r, b = self:right() - INSET, self:bottom() - INSET

    love.graphics.setColor(Palette.red)
    self:edge(l, t, r, t, along, 1)
    self:edge(l, b, r, b, along, 2)
    self:edge(l, t, l, b, along, 3)
    self:edge(r, t, r, b, along, 4)
end

return Arena
