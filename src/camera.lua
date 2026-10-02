local util = require("src.util")

local Camera = {}

Camera.x, Camera.y = 0, 0
Camera.w, Camera.h = 320, 180

-- Who the camera follows; kept rather than passed because `bounds` needs it.
Camera.tx, Camera.ty = 0, 0

-- The knock: a third of a second of the page jumping under everything on it.
-- Two sine waves at rates that do not divide into each other, so the loop never
-- repeats -- per-frame random reads as a buzz at three pixels of travel, and a
-- decaying kick returns identically. Clock-driven, not random, so the same hit
-- shakes the same way (determinism). `x` starts at full stretch and `y` at
-- nothing (a sideways snap first); amplitude in whole pixels.
local SHAKE_TIME = 0.3
local SHAKE_X = 46 -- rad/s: about 2.2 turns over the life of a knock
local SHAKE_Y = 31 -- and about 1.5, so the two never line up twice
Camera.shakeT, Camera.shakeMag = 0, 0

-- Max rather than sum, so a hit inside a running knock restarts it at the
-- larger of the two: stacked shakes make a screen you cannot play on.
function Camera.knock(mag)
    Camera.shakeMag = math.max(Camera.shakeMag, mag)
    Camera.shakeT = SHAKE_TIME
end

-- Run beside Camera.follow, once a frame and outside the playing branch
-- (Game:update): a knock taken on the frame you died should still finish.
function Camera.settle(dt)
    Camera.shakeT = math.max(0, Camera.shakeT - dt)
    if Camera.shakeT <= 0 then Camera.shakeMag = 0 end
end

local function knocked()
    if Camera.shakeT <= 0 then return 0, 0 end
    local a = Camera.shakeMag * (Camera.shakeT / SHAKE_TIME)
    local e = SHAKE_TIME - Camera.shakeT
    return math.floor(a * math.cos(e * SHAKE_X) + 0.5),
           math.floor(a * math.sin(e * SHAKE_Y) + 0.5)
end

function Camera.setViewport(w, h)
    Camera.w, Camera.h = w, h
end

function Camera.set(x, y)
    Camera.x, Camera.y = x, y
    Camera.tx, Camera.ty = x, y
    -- Flat: the cut to a fresh page (Game:reset) must not arrive crooked.
    Camera.shakeT, Camera.shakeMag = 0, 0
end

function Camera.follow(x, y, dt)
    -- Exponential smoothing, frame-rate independent.
    local t = 1 - math.exp(-8 * dt)
    Camera.x = util.lerp(Camera.x, x, t)
    Camera.y = util.lerp(Camera.y, y, t)
    Camera.tx, Camera.ty = x, y
end

-- Whole pixels, snapped against WHAT THE CAMERA FOLLOWS rather than the world;
-- the difference is a one-pixel shimmer on the hero. Flooring `Camera.x`
-- independently left the hero's own fraction in the subtraction, so he flipped
-- between two pixels while walking (six times worse diagonally, where both axes
-- cross on one frame and it smears). Flooring the LAG subtracts his fraction
-- from itself: he holds one pixel and the repeating ruling steps instead.
local function snap(target, cam, span)
    return math.floor(target) - math.floor(target - cam + span / 2 + 0.5)
end

local function page()
    return snap(Camera.tx, Camera.x, Camera.w),
           snap(Camera.ty, Camera.y, Camera.h)
end

-- Which rectangle of the world the screen shows, knock included. Here rather
-- than in `attach` because the paper is a wrapped quad drawn at exactly this
-- rectangle: an unknown translate would slide the ruling off one edge.
function Camera.bounds()
    local left, top = page()
    local sx, sy = knocked()
    return left + sx, top + sy, Camera.w, Camera.h
end

-- The same rectangle with the knock taken back out, for the one caller reading
-- THROUGH a shake: turning the pointer into a world position
-- (Game:updateDrawing). A drawing may be lied to about the page; a pen line,
-- which becomes a wall you live with, may not.
function Camera.steady()
    local left, top = page()
    return left, top, Camera.w, Camera.h
end

function Camera.attach()
    local left, top = Camera.bounds()
    love.graphics.push()
    love.graphics.translate(-left, -top)
end

function Camera.detach()
    love.graphics.pop()
end

return Camera
