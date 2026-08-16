-- The box the boss fight happens in.
--
-- Every other minute of a run is played on an infinite page: the horde arrives
-- from off the edge of the screen, and walking away from a problem is always an
-- answer to it. That is the right shape for a horde, which has no plan and does
-- not care where you go. It is the wrong shape for one slow enemy, because a
-- boss you can walk away from for ever is a boss you never have to fight -- and
-- the eye is *deliberately* slower than you (src/enemy.lua), so without this the
-- honest way to beat it would be to walk in a straight line for half an hour.
--
-- So the ten minutes are up and somebody draws a box round the two of you. It is
-- pinned where the *player* is standing at that moment rather than where the eye
-- comes over the ring, because the alternative is being handed a wall at your
-- back before you have seen what put it there.
--
-- It is a rectangle for the reason everything in this game is a rectangle you
-- scribble in: the title screen, the pause card and every one of the draft's
-- three answers is a box drawn on the page, and this is the one you fight in
-- rather than the one you answer. Clamping to it is also exact in a way a circle
-- is not, and exact matters when the thing being clamped is the player.
--
-- Nothing here is a wall in the `src/walls.lua` sense. A pen line is something
-- enemies path around and the player crosses freely; this is the opposite --
-- nobody crosses it, and nothing has to path around it because there is no
-- outside to be on. It is a clamp, applied after everything else has finished
-- moving, which is why it always wins and never has to argue with knockback.

local Palette = require("src.palette")
local util = require("src.util")

local Arena = {}
Arena.__index = Arena

-- How much bigger than the screen the box is, on each axis.
--
-- 1.5 is the number the whole fight is balanced on and it is a compromise
-- between two failures. Much tighter and the eye is standing on you from the
-- first second, which turns a fight about ground into a fight about damage.
-- Much wider and you can kite it for the full half minute without ever making a
-- decision, which is the thing this module exists to stop.
--
-- At 1.5 the box is 480x270 on a 320x180 page: about eight seconds to cross at
-- a walk, twenty for the eye to follow, and you can see a little under half of
-- it at a time. That last part is deliberate too -- the walls are usually just
-- off screen, so where the edges are is something you have to carry in your head
-- rather than read, which is what makes backing into one a mistake you can make.
local SPAN = 1.5

-- Drawn a whisker inside the clamp, so the line is on the page rather than being
-- the first pixel you are not allowed to stand on.
local INSET = 1

-- The wobble on the ruled edge. Hand-drawn like everything else that is not
-- machine-ruled -- the background's ruling is printed and dead straight, and
-- this is not printed, it is somebody boxing off part of the page.
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

-- Somewhere inside, with `pad` of clearance. The one operation this module
-- really has: everything that moves asks for it after it has moved, so nothing
-- has to know the box exists while it is deciding where to go.
function Arena:clamp(x, y, pad)
    pad = pad or 0
    return util.clamp(x, self.left + pad, self:right() - pad),
           util.clamp(y, self.top + pad, self:bottom() - pad)
end

function Arena:contains(x, y)
    return x >= self.left and x <= self:right()
        and y >= self.top and y <= self:bottom()
end

-- A point inside, `pad` off the edge, for anything that wants to put something
-- in here rather than move something already in it -- the eye's tears, and the
-- escort walking on.
function Arena:somewhere(pad)
    pad = pad or 0
    return self.left + pad + love.math.random() * (self.w - pad * 2),
           self.top + pad + love.math.random() * (self.h - pad * 2)
end

--- drawing -------------------------------------------------------------------

-- How far along each edge is drawn in, 0 to 1. The box does not appear, it is
-- *drawn* -- four strokes racing out from the corners over three quarters of a
-- second, which is exactly as long as it takes to notice that the page just got
-- smaller. Nothing is clamped any differently while it draws: the rule lands the
-- moment the eye does, and the line catching up is a thing you watch rather than
-- a thing you are waiting for.
local DRAW_TIME = 0.75

-- One edge, wobbled off the seed so it reads as drawn rather than ruled. Plotted
-- a pixel at a time because that is the only way anything gets on this page --
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
