-- One movement vector and one drawing pointer, however they were produced.
--
-- Desktop: WASD/arrows to move, mouse to draw.
-- Touch:   a thumb stick in the bottom-left corner, and any other finger draws.
--
-- The stick is drawn (see src/hud.lua) at a fixed home in the corner, but it is
-- not pinned there: press anywhere in that corner and the ring jumps under your
-- thumb, which is what makes it usable without looking at it. Push past the rim
-- and the ring follows your thumb, so it can never run out of travel mid-sprint
-- and leave you walking into the horde at half speed.
--
-- Everything here is reported in canvas pixels, never window pixels, so the
-- rest of the game never has to think about the display scale.

local util = require("src.util")

local Input = {}

local scale, offX, offY = 1, 0, 0
local vw, vh = 320, 180
local touchScale = 1
local inset = { l = 0, t = 0, r = 0, b = 0 }

Input.STICK_R = 20      -- outer ring radius, canvas pixels
Input.KNOB_R = 7
Input.STICK_MAX = 13    -- distance from the origin that counts as full tilt
local STICK_DEAD = 2
local STICK_MARGIN = 7  -- ring rim to the corner of the safe area
local ZONE_REACH = 2.2  -- how far out of the corner a touch still grabs the
                        -- stick, in ring radii -- the rest of the page draws

Input.usingTouch = false
Input.stick = { active = false, id = nil, ox = 0, oy = 0, x = 0, y = 0 }
-- Turned off on the title screen, where there is nothing to walk and the whole
-- page -- corner included -- has to be drawable.
Input.stickEnabled = true

Input.pointerDown = false
Input.pointerX, Input.pointerY = 0, 0
local pointerId = nil

-- Assigned by the game. Return true to swallow the press (a tap on the tool
-- selector, say) so it doesn't also start a stroke.
Input.onPointerDown = nil

function Input.setTransform(s, ox, oy, w, h, ts)
    scale, offX, offY, vw, vh = s, ox, oy, w, h
    touchScale = ts or 1
end

function Input.setSafeInsets(l, t, r, b)
    inset.l, inset.t, inset.r, inset.b = l, t, r, b
end

local function toCanvas(x, y)
    return (x - offX) / scale, (y - offY) / scale
end

-- Touches come in screen pixels; the mouse and the canvas transform work in
-- window units. The two only differ if DPI scaling is on.
local function touchToCanvas(x, y)
    return toCanvas(x / touchScale, y / touchScale)
end

--- the stick ------------------------------------------------------------------

-- Where the ring rests when no thumb is on it.
function Input.stickHome()
    return inset.l + STICK_MARGIN + Input.STICK_R,
           vh - inset.b - STICK_MARGIN - Input.STICK_R
end

local function inStickZone(cx, cy)
    local hx, hy = Input.stickHome()
    local reach = Input.STICK_R * ZONE_REACH
    return cx <= hx + reach and cy >= hy - reach
end

-- Ring centre, knob centre, and whether a thumb is on it. For the HUD.
function Input.stickState()
    local stick = Input.stick
    if not stick.active then
        local hx, hy = Input.stickHome()
        return hx, hy, hx, hy, false
    end

    local nx, ny, dist = util.normalize(stick.x - stick.ox, stick.y - stick.oy)
    local d = math.min(dist, Input.STICK_MAX)
    return stick.ox, stick.oy, stick.ox + nx * d, stick.oy + ny * d, true
end

--- movement ------------------------------------------------------------------

-- Returns a vector of magnitude 0..1. The stick is analogue; the keyboard is
-- always full tilt.
function Input.movement()
    local dx, dy = 0, 0
    if love.keyboard.isDown("a", "left") then dx = dx - 1 end
    if love.keyboard.isDown("d", "right") then dx = dx + 1 end
    if love.keyboard.isDown("w", "up") then dy = dy - 1 end
    if love.keyboard.isDown("s", "down") then dy = dy + 1 end

    if dx ~= 0 or dy ~= 0 then
        local nx, ny = util.normalize(dx, dy)
        return nx, ny
    end

    local stick = Input.stick
    if stick.active then
        local nx, ny, dist = util.normalize(stick.x - stick.ox, stick.y - stick.oy)
        if dist < STICK_DEAD then return 0, 0 end
        local tilt = math.min(dist, Input.STICK_MAX) / Input.STICK_MAX
        return nx * tilt, ny * tilt
    end

    return 0, 0
end

--- pointer -------------------------------------------------------------------

-- The HUD gets first refusal on every press. Ahead of the pointer already being
-- taken, or you could never change tool without lifting the pen first; and
-- ahead of the stick, whose zone is a generous quadrant rather than the ring it
-- draws -- a button or a prompt that lands inside it has to still be pressable,
-- and "tap anywhere to restart" has to mean anywhere.
local function hudTook(cx, cy)
    return Input.onPointerDown ~= nil and Input.onPointerDown(cx, cy)
end

local function beginPointer(id, cx, cy)
    if pointerId ~= nil then return end
    pointerId = id
    Input.pointerDown = true
    Input.pointerX, Input.pointerY = cx, cy
end

local function movePointer(id, cx, cy)
    if pointerId ~= id then return end
    Input.pointerX, Input.pointerY = cx, cy
end

local function endPointer(id)
    if pointerId ~= id then return end
    pointerId = nil
    Input.pointerDown = false
end

-- Drop every held input. Used when the window loses focus, since the release
-- events for whatever was down at the time never arrive.
function Input.releaseAll()
    Input.stick.active, Input.stick.id = false, nil
    pointerId = nil
    Input.pointerDown = false
end

--- love callbacks ------------------------------------------------------------

function Input.mousepressed(x, y, button)
    if Input.usingTouch or button ~= 1 then return end

    local cx, cy = toCanvas(x, y)
    if hudTook(cx, cy) then return end
    beginPointer("mouse", cx, cy)
end

function Input.mousemoved(x, y)
    if Input.usingTouch then return end
    movePointer("mouse", toCanvas(x, y))
end

function Input.mousereleased(x, y, button)
    if Input.usingTouch or button ~= 1 then return end
    endPointer("mouse")
end

function Input.touchpressed(id, x, y)
    -- Mobile LÖVE also emits synthetic mouse events for touches; once a real
    -- touch arrives, stop listening to those or every tap counts twice.
    Input.usingTouch = true

    local cx, cy = touchToCanvas(x, y)
    if hudTook(cx, cy) then return end

    local stick = Input.stick
    if Input.stickEnabled and not stick.active and inStickZone(cx, cy) then
        stick.active, stick.id = true, id
        stick.ox, stick.oy = cx, cy
        stick.x, stick.y = cx, cy
    else
        beginPointer(id, cx, cy)
    end
end

function Input.touchmoved(id, x, y)
    local cx, cy = touchToCanvas(x, y)
    local stick = Input.stick
    if stick.active and stick.id == id then
        stick.x, stick.y = cx, cy

        -- Thumb past the rim: drag the ring along behind it. Without this a
        -- long swipe leaves the origin stranded and the stick reads as full
        -- tilt in a direction you stopped pointing several centimetres ago.
        local dx, dy = stick.x - stick.ox, stick.y - stick.oy
        local dist = util.len(dx, dy)
        if dist > Input.STICK_MAX then
            local pull = (dist - Input.STICK_MAX) / dist
            stick.ox = stick.ox + dx * pull
            stick.oy = stick.oy + dy * pull
        end
    else
        movePointer(id, cx, cy)
    end
end

function Input.touchreleased(id)
    local stick = Input.stick
    if stick.active and stick.id == id then
        stick.active, stick.id = false, nil
    else
        endPointer(id)
    end
end

return Input
