local util = require("src.util")

local Camera = {}

Camera.x, Camera.y = 0, 0
Camera.w, Camera.h = 320, 180

function Camera.setViewport(w, h)
    Camera.w, Camera.h = w, h
end

function Camera.set(x, y)
    Camera.x, Camera.y = x, y
end

function Camera.follow(x, y, dt)
    -- Exponential smoothing, frame-rate independent.
    local t = 1 - math.exp(-8 * dt)
    Camera.x = util.lerp(Camera.x, x, t)
    Camera.y = util.lerp(Camera.y, y, t)
end

-- Snapped to whole pixels: a fractional camera would make the ruled lines and
-- every sprite shimmer as they cross the pixel grid.
function Camera.bounds()
    local left = math.floor(Camera.x - Camera.w / 2)
    local top = math.floor(Camera.y - Camera.h / 2)
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
