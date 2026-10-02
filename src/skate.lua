-- The trail the skate leaves behind you.
--
-- The seventh passive weapon, and the only one that is a *surface*. The other
-- six are all things that happen to the crowd -- a star cuts what it turns
-- through, a rocket leaves, a beam flashes, an S crosses, a bomb goes off -- and
-- the nearest any of them comes to this is the crater the bomb's last level
-- leaves smouldering, which is one round patch that was somewhere you had
-- already decided to be. A skate turns the whole line you have walked into that
-- patch, continuously, for as long as you keep walking.
--
-- Which makes it the one weapon aimed by the half of the game you play with your
-- feet, and aimed *behind* you. That is not the laser beam's question over
-- again: the beam asks whether you will turn and face a crowd, and this asks
-- whether you will let one follow you. Anything chasing you walks its own centre
-- through where your centre was a moment ago, so a thing that damages the line
-- you just left is a thing that damages exactly whatever is closest to catching
-- you -- and the crowd cannot stop chasing, since chasing is all it does.
--
-- What the line sells is that bargain getting better rather than the damage
-- getting bigger. First the trail cuts at all; then what stands in it loses its
-- footing and slows down, so the crowd strings out along the line instead of
-- arriving in a lump; then the cut gets deep enough to finish what the string-out
-- started; then the fresh end of the trail carries *you* faster, which is the one
-- level that pays you for going back over your own line; and finally every gem
-- lying on the trail comes to you however far off it is, so a lap of the page is
-- a lap of collecting it.
--
-- The board is drawn by the player (src/design.lua) and it is the one drawing
-- that goes under another: it is drawn at the hero's feet in place of his shadow,
-- and having one takes his walk bounce away (Player:draw). A hero who slides
-- instead of bobbing is the whole of what this weapon looks like from the outside
-- -- there is no muzzle, no arc and nothing in the air, so the readout is the
-- animation.
--
-- Everything here is in the player's half of the palette and in the pairing the
-- rest of it uses: sky through the middle and blue round the rim, exactly as the
-- bomb's burn is and the boss's blot is not (src/puddle.lua). It is ground *you*
-- took, so it is drawn in the colours of the pen that took it.

local Palette = require("src.palette")
local Sprites = require("src.sprites")

local Skate = {}
Skate.__index = Skate

-- Pixels between one stamp of the trail and the next. Four rather than the
-- crayon's two: this is laid down by walking rather than by dragging a finger,
-- so it is laid for the whole run and never in a burst, and even along the
-- oval's flattest axis (seven, at its narrowest) a stamp every four pixels is a
-- solid band with nothing to gain from twice as many of them. It is also what
-- every walk over the trail costs, so it is the one number here that is about
-- the frame budget as much as the look.
local SPACING = 4

-- The oval one stamp of the band is laid with, and therefore how wide the band
-- is -- except it is two numbers now, not one, the way a real chisel-tip
-- highlighter is: held at a fixed angle it shows its full blade dragged one way
-- and only the thin edge dragged the other. The nib here is a fixed oval rather
-- than a rotated chisel (nothing here is ever turned to face where it is going,
-- see the rendering rules), wide across x and flat across y, so travelling
-- straight down draws with the oval's full width and travelling straight across
-- draws with its flat one. Thirteen across because that is the deck of the board
-- (Sprites.SKATE) -- what is left on the page at its widest is the width of what
-- left it -- and seven tall at the flat end, picked for how thin it reads rather
-- than against anything else here (`FOOT` below is about *where* the oval sits,
-- not how flat it is).
-- The two nibs it is stamped with are `newOval(6, 3)` and `newOval(7, 4)`
-- (`Sprites.tips.skate` and `skateEdge`), so this and those have to agree.
local RADIUS_X = 6
local RADIUS_Y = 3
local WIDTH = RADIUS_X * 2 + 1

-- What the band actually reaches on each axis, and it is `pixelart.newOval`'s own
-- limit rather than the radius: a generated oval takes every pixel inside
-- `radius + 0.4` on both axes, so the half-pixel bias that keeps its rim from
-- looking cut off flat is part of how wide -- and how flat -- it is. Reading it
-- off the same numbers here is what makes the band that kills exactly the band
-- that was drawn -- the bomb's "the ring that flashes is the ring that killed"
-- applied to a line: whatever pixel the oval inked at a stamp is exactly the
-- pixel that can hurt something standing on that stamp, on both axes rather
-- than one.
local REACH_X = RADIUS_X + 0.4
local REACH_Y = RADIUS_Y + 0.4

-- How far below the player's centre the band is laid, and it is not a
-- compromise any more -- it is where the board already is. `Sprites.board`
-- and `Sprites.shadow` both place the board at `sprite.h - sprite.oy - 1`
-- below the hero's own centre, nineteen and nine on every hero board there is,
-- which is nine; the trail now starts from that same line rather than
-- somewhere between it and his shoulders, so what is left on the page reads as
-- coming out from directly under the board instead of from behind him.
--
-- That does cost the band something: `FOOT` now sits past `REACH_Y`, the flat
-- oval's own vertical reach, so a chaser walking dead level through exactly
-- where your centre was, while you are travelling exactly horizontally, can
-- land past the flat edge and go uncaught for that stretch. Real chasers
-- converge on you rather than tracing your path point for point, and this
-- weapon has never promised anything at the full width when it isn't drawing
-- at the full width -- but it is the trade this position makes, and it is not
-- free.
local FOOT = 9

-- The fresh end of the trail, as a fraction of a stamp's life, and a constant
-- rather than a number on the block -- the bomb's `BLINK` argument. It is what
-- the boost level is paid over *and* the stretch that is drawn with its rim on,
-- which has to be one number in one place: the readout for "you go faster here"
-- is the wet-looking end of your own line, and a level that moved one without
-- the other would be a weapon that lied about where its own boost was.
local FRESH = 0.35

-- How long an enemy keeps skidding after it has left the band. The trail is
-- walked once a frame from here, which is *after* the crowd has moved
-- (Game:update), so a slow read straight off the band would always land a frame
-- late; carrying it for a moment covers that and does the wax's job at the same
-- time -- a thing that skids off the end of a line carries on skidding for a
-- step instead of getting its footing back on a pixel (`SLIP_CARRY` in
-- src/enemy.lua).
local CARRY = 0.12

function Skate.new()
    return setmetatable({
        def = nil,
        trail = {},   -- oldest first, so the tail is eaten off the front
        lay = nil,    -- where the last stamp went down
        tick = 0,     -- 0, so the first cut lands as soon as there is a trail
        -- The box the whole trail fits in, kept as it is laid rather than
        -- measured every frame: it is what the horde is asked for (see `cut`).
        x1 = 0, y1 = 0, x2 = 0, y2 = 0,
    }, Skate)
end

function Skate:configure(def)
    self.def = def
end

--- laying it down -------------------------------------------------------------

-- One stamp, in world space, `FOOT` below wherever the player is standing.
function Skate:stamp(x, y)
    local n = #self.trail
    self.trail[n + 1] = { x = math.floor(x), y = math.floor(y), age = 0 }
    self.lay = self.trail[n + 1]
end

function Skate:update(dt, game, grid)
    local def = self.def
    local life = def.life
    local player = game.player

    -- Off the front: stamps expire in the order they were laid, so the trail is
    -- always one unbroken chain and the fade is the tail being eaten. Which is
    -- the one mark on the page that does not need to dither out -- a trail
    -- getting *shorter* is what a trail does, and dropping stamps out of a 13px
    -- band would only be filled in by their neighbours anyway (see the crayon's
    -- pinholes in src/tools.lua).
    local dead = 0
    for i = 1, #self.trail do
        local s = self.trail[i]
        s.age = s.age + dt
        if s.age >= life then dead = i end
    end
    for _ = 1, dead do table.remove(self.trail, 1) end
    if #self.trail == 0 then self.lay = nil end

    -- A stamp every SPACING pixels of walking, and nothing at all while standing
    -- still: a trail is a record of where you went, so a hero holding one spot
    -- must not be sitting in a puddle of his own making.
    local px, py = player.x, player.y + FOOT
    local last = self.lay
    if not last then
        self:stamp(px, py)
    else
        local dx, dy = px - last.x, py - last.y
        if dx * dx + dy * dy >= SPACING * SPACING then
            self:stamp(px, py)
        end
    end

    -- The trail's own bounding box, and the trail is never empty by the time this
    -- runs. There is no line query in this game (see the laser beam), so what a
    -- thing reaching across the page does is ask for a circle that holds it and
    -- then test itself; this is where that circle comes from.
    local x1, y1 = math.huge, math.huge
    local x2, y2 = -math.huge, -math.huge
    for i = 1, #self.trail do
        local s = self.trail[i]
        if s.x < x1 then x1 = s.x end
        if s.y < y1 then y1 = s.y end
        if s.x > x2 then x2 = s.x end
        if s.y > y2 then y2 = s.y end
    end
    self.x1, self.y1, self.x2, self.y2 = x1, y1, x2, y2

    self.tick = self.tick - dt
    local cutting = self.tick <= 0
    if cutting then self.tick = def.tick end

    -- One walk over the crowd for both jobs, and only when there is a job: the
    -- slow has to be looked at every frame or it would arrive in steps, and the
    -- damage lands on a tick like every other thing in the game that hurts by
    -- being stood in. A run that has neither due this frame -- which is every
    -- frame of a run that has only taken the first level -- does not walk at all.
    if cutting or def.slow < 1 then
        self:cut(game, cutting)
    end
end

--- what is standing in it -----------------------------------------------------

-- The freshest stamp covering a point, or nil. Freshest rather than any, because
-- the boost is paid on the wet end of the line and walking back over an old
-- stretch that happens to cross a new one should read as being on the new one.
--
-- Walked newest first for exactly that, which is also what makes it quick in the
-- case that matters: the thing chasing you is on the stamp you just laid.
function Skate:at(x, y)
    local trail = self.trail

    for i = #trail, 1, -1 do
        local s = trail[i]
        local dx, dy = x - s.x, y - s.y
        if (dx * dx) / (REACH_X * REACH_X) + (dy * dy) / (REACH_Y * REACH_Y) <= 1 then
            return s
        end
    end
end

-- Whether the trail could reach a point at all. The bounding box first, exactly
-- as `Stroke:covers` does it: the crowd is walked every frame and most of it is
-- nowhere near a line the player left behind.
function Skate:near(x, y)
    return x >= self.x1 - REACH_X and x <= self.x2 + REACH_X
        and y >= self.y1 - REACH_Y and y <= self.y2 + REACH_Y
end

-- Everything standing on the line, once. `eachWithin` for the sun's reason and
-- the beam's -- a trail is far longer than the nine 12px cells `eachNear` looks
-- in, and there is nothing to ask about a line, so it asks for the circle that
-- holds the box and tests the band itself.
--
-- The slow is not applied here so much as *handed over*: the enemy carries it
-- for `CARRY` seconds (src/enemy.lua) rather than being told its speed every
-- frame, which is what lets this run after the crowd has already moved.
function Skate:cut(game, cutting)
    local def = self.def
    local cx, cy = (self.x1 + self.x2) / 2, (self.y1 + self.y2) / 2
    local dx, dy = self.x2 - cx + WIDTH, self.y2 - cy + WIDTH -- a band's slack

    game:eachWithin(cx, cy, math.sqrt(dx * dx + dy * dy), function(e)
        if not self:near(e.x, e.y) or not self:at(e.x, e.y) then return end

        if def.slow < 1 then
            e.chill, e.chillT = def.slow, CARRY
        end

        if cutting then
            -- The one red anywhere in the weapon, and the bomb's burn's reason
            -- for it: a speck off something taking a hit belongs to the thing
            -- being hit, not to what hit it. The sky and the blue are what the
            -- trail is; this is what it did.
            game.particles:burst(e.x, e.y, 1, Palette.red)
            if e:hurt(def.damage) then
                game:killEnemyAt(e)
            end
        end
    end)
end

--- what it does for you -------------------------------------------------------

-- The multiplier on your own speed where you are standing, or nil. Only the wet
-- end counts, which is the whole shape of the level: the trail you laid four
-- seconds ago is a trap for the crowd and the trail you laid one second ago is a
-- road, so the way to use it is to keep turning back into your own line rather
-- than to lay a lap and live on it.
function Skate:boostAt(x, y)
    if self.def.boost <= 1 then return nil end
    if not self:near(x, y) then return nil end

    local s = self:at(x, y)
    if s and s.age <= self.def.life * FRESH then return self.def.boost end
end

-- Whether xp lying here comes to you however far off it is. The magnet upgrade
-- buys a radius round the player and this buys a *shape* -- the line you walked
-- -- which is why the two are worth having together rather than being the same
-- level twice: one collects where you are and this collects where you have been.
function Skate:pullsAt(x, y)
    if not self.def.magnet then return false end
    return self:near(x, y) and self:at(x, y) ~= nil
end

--- drawing --------------------------------------------------------------------

-- Down with the marks and the boss's puddles rather than up with the weapons
-- (Loadout:drawGround). It is ground rather than an object, so the crowd walks
-- over the top of it: a 13px band drawn over the horde would hide the whole of
-- what it is doing to it, which is the one thing only the sun may do.
--
-- The rim goes down for every stamp before any of their bodies do, the cool S's
-- rule: drawn a stamp at a time, each stamp's rim would be laid over the body of
-- the one before it and the band would come out ribbed.
function Skate:drawGround(game)
    local trail = self.trail
    local wet = self.def.life * FRESH

    -- Blue where the trail is still wet and nothing where it is not, which is
    -- the puddle's rim drying off by another name (src/puddle.lua): the darker
    -- of the two colours is what makes an edge readable, so it is what the fresh
    -- end has and the stale end has given up. It is also the only readout the
    -- boost level gets -- see FRESH.
    love.graphics.setColor(Palette.blue)
    for i = 1, #trail do
        local s = trail[i]
        if s.age <= wet then
            Sprites.tips.skateEdge:drawMask(s.x, s.y)
        end
    end

    love.graphics.setColor(Palette.sky)
    for i = 1, #trail do
        local s = trail[i]
        Sprites.tips.skate:drawMask(s.x, s.y)
    end
end

-- Nothing stands over the page here. The band is ground and goes down in
-- `drawGround` above; the board itself is drawn by the hero standing on it
-- (Player:draw), because it has to be under him and he is sorted into the crowd.
-- So this weapon is the one with no `draw` at all -- see Loadout:drawWeapons.

return Skate
