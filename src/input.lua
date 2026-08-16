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
-- That following is on a leash. A run is one long hold -- the thumb is almost
-- never lifted -- and a horde is fled in one general direction for a while, so
-- an origin that followed without limit would ratchet: every push past the rim
-- displaces it for good and nothing brings it back until you let go, and after
-- a minute of that your hand is in the middle of the page you draw on. Within
-- STICK_LEASH of where the thumb landed the ring follows; at the boundary it
-- slides sideways but no further out. It is a short leash on purpose: the drift
-- is what the stick does when the thumb has already gone somewhere it should
-- not have to, so the room it is given is a concession and not a feature.
--
-- Nor may it drift out to an edge. STICK_MARGIN is clearance the ring keeps
-- from every side of the safe area wherever it has got to, not just where it
-- rests, because a ring against the edge of the screen is a thumb against it
-- with nowhere left to push -- which is the whole complaint this stick is
-- written against, arrived at from the other direction.
--
-- Be honest about what that costs, because it is the one thing here that costs
-- anything. A reversal answers once the thumb is back inside the throw, so
-- while the ring is keeping up it is 23px of travel however far you have gone
-- -- and past the leash it is that plus everything you went over by, paid back
-- before the stick will turn. There is no arrangement without that bill: the
-- distance a reversal costs *is* the distance from the thumb to the origin, and
-- the distance the ring has wandered is the rest of the way to the thumb, so
-- the two only trade against each other. A leash buys the second with the
-- first, and it is the right way round because the wander is unbounded and
-- silent while the lag is bounded, self-correcting and only ever felt where the
-- thumb is somewhere it cannot play from anyway.
--
-- Which is why the other two are the real fix, and both remove the reason to
-- push out at all rather than managing what happens when you do: the throw is
-- set against a thumb (full tilt is the knob's edge touching the rim, and the
-- ring is sized so that lands about a centimetre out, where it used to be four
-- millimetres), and there is no speed above full tilt, so the ring says so in
-- red rather than letting a thumb push on for something that is not there.
--
-- Everything here is reported in canvas pixels, never window pixels, so the
-- rest of the game never has to think about the display scale.

local util = require("src.util")

local Input = {}

local scale, offX, offY = 1, 0, 0
local vw, vh = 320, 180
local touchScale = 1
local inset = { l = 0, t = 0, r = 0, b = 0 }

-- The ring is drawn big because the throw has to be, and the throw is the one
-- HUD measurement taken off a thumb instead of off the page: a canvas pixel is
-- about a third of a millimetre on a phone, so a 13px throw put full speed four
-- millimetres from where you pressed and every push after that was drag. Full
-- tilt is the knob's edge meeting the rim -- STICK_MAX is STICK_R - KNOB_R and
-- has to stay that way, or the picture stops agreeing with the reading.
Input.STICK_R = 28      -- outer ring radius, canvas pixels
Input.KNOB_R = 8
Input.STICK_MAX = 20    -- distance from the origin that counts as full tilt
local STICK_DEAD = 3    -- held at about a seventh of the throw, as before
-- Ring rim to the edge of the safe area, and it is a floor rather than a
-- resting place: the ring keeps this much clear of every edge wherever it has
-- drifted to, not just where it sits when nobody is holding it. A ring hard up
-- against the edge of the screen is a thumb hard up against it too, which is
-- the corner of the phone you cannot push into.
local STICK_MARGIN = 12
local STICK_LEASH = 1.25 -- how far the ring may follow the thumb from where it
                         -- landed, in ring radii
local ZONE_REACH = 1.6  -- how far out of the corner a touch still grabs the
                        -- stick, in ring radii -- the rest of the page draws.
                        -- In *pixels* this is what it always was: the zone is a
                        -- quadrant of the page taken away from drawing, and a
                        -- bigger ring is not a reason to take more of it.

Input.usingTouch = false
-- ox,oy is the ring's origin and follows the thumb; ax,ay is where the thumb
-- first landed and does not, since that is what the leash is measured from.
Input.stick = { active = false, id = nil, ox = 0, oy = 0, ax = 0, ay = 0, x = 0, y = 0 }
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

-- The box the ring's centre is kept inside: the safe area with a ring and a
-- margin taken off every edge, so the drifting ring keeps the same clearance
-- the resting one does. A window too small to hold it (never a phone, but a
-- dragged desktop one) collapses to the middle rather than an inside-out box.
local function fieldBounds()
    local keep = Input.STICK_R + STICK_MARGIN
    local l, r = inset.l + keep, vw - inset.r - keep
    local t, b = inset.t + keep, vh - inset.b - keep
    if l > r then l, r = (l + r) / 2, (l + r) / 2 end
    if t > b then t, b = (t + b) / 2, (t + b) / 2 end
    return l, r, t, b
end

local function clampToField(x, y)
    local l, r, t, b = fieldBounds()
    return math.min(math.max(x, l), r), math.min(math.max(y, t), b)
end

-- Where the drifting ring is allowed: the same box, stretched to hold the point
-- the thumb landed on. Stretched rather than clamped so that grabbing the stick
-- out at the very corner of the screen is not answered by shoving the ring off
-- the thumb -- the ring may sit where you put it, and may only drift inwards
-- from there. Because the box holds the anchor and a box is convex, this can
-- only bring the origin nearer the anchor, so it can never break the leash.
local function clampToDrift(ax, ay, x, y)
    local l, r, t, b = fieldBounds()
    l, r = math.min(l, ax), math.max(r, ax)
    t, b = math.min(t, ay), math.max(b, ay)
    return math.min(math.max(x, l), r), math.min(math.max(y, t), b)
end

-- Where the ring rests when no thumb is on it: the corner of that box, so the
-- resting place is one of the positions the drifting ring is allowed and the
-- two cannot be given different margins by accident.
function Input.stickHome()
    return clampToField(-math.huge, math.huge)
end

local function inStickZone(cx, cy)
    local hx, hy = Input.stickHome()
    local reach = Input.STICK_R * ZONE_REACH
    return cx <= hx + reach and cy >= hy - reach
end

-- Ring centre, knob centre, whether a thumb is on it, and how far over it is.
-- For the HUD: the tilt is what turns the ring red, since there is nothing
-- above full tilt and a thumb pushing for more has to be told so.
function Input.stickState()
    local stick = Input.stick
    if not stick.active then
        local hx, hy = Input.stickHome()
        return hx, hy, hx, hy, false, 0
    end

    local nx, ny, dist = util.normalize(stick.x - stick.ox, stick.y - stick.oy)
    local d = math.min(dist, Input.STICK_MAX)
    return stick.ox, stick.oy, stick.ox + nx * d, stick.oy + ny * d, true,
           d / Input.STICK_MAX
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
        stick.ax, stick.ay = cx, cy
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

        -- ...but only so far from where the thumb landed. Clamping the origin
        -- back into that disc rather than refusing the drag outright is what
        -- keeps a turn live at the boundary: the drag carries the origin
        -- sideways as well as outwards, and only the outward half is taken
        -- off, so the ring slides round the leash and goes on answering.
        --
        -- The thumb is not clamped with it, so past here the offset grows and
        -- this is an ordinary fixed stick: still walking you the way you were
        -- going, at full tilt, and charging the excess back before it turns.
        local leash = Input.STICK_R * STICK_LEASH
        local lx, ly = stick.ox - stick.ax, stick.oy - stick.ay
        local slack = util.len(lx, ly)
        if slack > leash then
            stick.ox = stick.ax + lx / slack * leash
            stick.oy = stick.ay + ly / slack * leash
        end

        -- And never out to an edge. The margin the resting ring keeps is the
        -- margin the drifted one keeps, since a ring against the edge of the
        -- screen is a thumb against it, with nowhere left to push.
        --
        -- Clamping here rather than at the press is what keeps it honest: the
        -- origin starts exactly under the thumb, so the stick reads neutral on
        -- the frame you take hold of it however close to the corner you grabbed
        -- it. It is only the *drift* that is not allowed out there, and a grab
        -- from outside the box can still drift inwards -- the box is stretched
        -- to hold where the thumb landed (fieldFrom), never shrunk to it.
        stick.ox, stick.oy = clampToDrift(stick.ax, stick.ay, stick.ox, stick.oy)
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
