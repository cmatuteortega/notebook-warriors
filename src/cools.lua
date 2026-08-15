-- The cool S, floating off across the page.
--
-- The fourth passive weapon, and the one that needed no inventing: it is the S
-- everybody drew in the back of an exercise book, and this game is an exercise
-- book. You draw it yourself like the star and the rocket (src/design.lua), it
-- comes in off the edge of the page from a direction nobody picked, and it cuts
-- everything on the line it takes until the page runs out from under it.
--
-- It is the third answer to the question the other weapons answer. A star holds
-- the ring you are standing in, a rocket picks the one thing that matters, the
-- sun owns a corner and waits for the horde to come to it -- and this one draws
-- a straight line across the whole page and does not care what is on it. That
-- makes it the only weapon in the game with no relationship at all to where the
-- enemies are: it is not aimed and it does not seek. What you buy with it is a
-- line drawn clean through the crowd, at full damage, every single thing on it,
-- however many that is.
--
-- It comes in from off the page rather than out of the player, and the whole
-- difference is what that does to the line it draws. One that left your hand
-- would only ever cover the half of the page you were standing at the edge of;
-- one that comes in from outside and is pointed at where you were standing as
-- it arrives crosses the *whole* page and goes through the crowd on both sides
-- of you. That aim is taken once, at the edge, and never corrected -- so it
-- cuts the line you were standing on a second ago rather than following you,
-- and stepping out of your own S's way is a thing you can do.
--
-- Two things fall out of "until it exits screen" and both matter:
--
--   - Its life is the *viewport*, not a timer, so `Camera.bounds()` is read
--     every frame and the thing that ends it is the page moving out from under
--     it as much as it flying off the page. Walking away from one kills it.
--   - The edge is a wall rather than an ending from the very first level, and
--     the levels that add bounces are buying page time rather than damage.
--     Bounces are finite, which is the whole of why this terminates: an S with
--     none left flies off and is gone, and there is no arrangement of ink that
--     can keep one forever.
--
-- Nothing turns at draw time, so the S is drawn upright at every heading it
-- flies. That is not a compromise here -- a doodle floating past has no more
-- business pointing where it is going than the ruled lines do.

local Camera = require("src.camera")
local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Walls = require("src.walls")
local util = require("src.util")

local CoolS = {}
CoolS.__index = CoolS

local TWO_PI = math.pi * 2

-- Half the 9x17 body. Two numbers rather than the one radius the star and the
-- rocket carry, because this is the one thing that fights at a size and a shape
-- you can see: it is twice as tall as it is wide and it never turns, so a box
-- is exactly what it looks like and a circle would be a lie in both directions.
-- A design is fixed at the size of the art it starts from, so drawing your own S
-- changes what it looks like and never what it cuts.
local HIT_W, HIT_H = 4, 8

-- The circle that box fits inside, plus the biggest enemy in the game. This is
-- what `eachWithin` is asked for and it is why it is asked rather than
-- `eachNear`: the nine 12px cells only guarantee 12 pixels of reach from the
-- point that asks, and the top of this sprite is further off than that. One or
-- two of these are in the air at a time, so the whole horde is affordable
-- every frame in a way the sun's disc would not be.
local REACH = 15

function CoolS.new()
    return setmetatable({
        def = nil,
        cool = 0,     -- 0, so taking the level sends one out at once
        live = {},
    }, CoolS)
end

function CoolS:configure(def)
    self.def = def
end

--- going out ------------------------------------------------------------------

-- Off the edge of the page from a direction nobody picked, aimed at where the
-- player is standing as it sets off. Two of them come in from opposite sides
-- rather than from two rolls of the dice: two random headings agree with each
-- other about a third of the time, and two S's arriving side by side is one S
-- that looks like a mistake.
--
-- Far enough out that the whole thing starts off the page on any window the
-- game can be given -- the half-diagonal of the viewport clears the corners,
-- which is the same sum the spawner does to keep the horde out of sight.
function CoolS:launch(game)
    local def = self.def
    local stats = game.loadout.stats
    -- A passive weapon is what graphite sharpens, and the global multiplier
    -- lands on everything. Read at launch: one already floating keeps the number
    -- it went out with, the way a rocket does.
    local damage = def.damage * stats.passiveDamage * stats.damage

    local _, _, w, h = Camera.bounds()
    local out = util.len(w, h) / 2 + HIT_H * 2
    local base = love.math.random() * TWO_PI

    for i = 0, def.count - 1 do
        local a = base + i * TWO_PI / def.count
        local c, s = math.cos(a), math.sin(a)

        self.live[#self.live + 1] = {
            x = game.player.x + c * out, y = game.player.y + s * out,
            -- Straight back at the player, and never corrected after this. It
            -- goes through where you were standing when it set off, which is
            -- what makes the line worth stepping out of.
            dx = -c, dy = -s,
            speed = def.speed,
            accel = def.accel,
            damage = damage,
            bounces = def.bounces,
            ink = def.ink,
            -- Not on the page yet: nothing about the edge applies until all of
            -- it has arrived. See CoolS:turn.
            arrived = false,
            -- What this one has already been through, so it can't shave the
            -- same enemy on every frame it spends inside it. Emptied on every
            -- bounce: a bounce is a fresh pass across the page, and a crowd it
            -- comes back through is a crowd it cuts again.
            hit = {},
        }
    end
end

--- cutting --------------------------------------------------------------------

function CoolS:cut(s, game)
    game:eachWithin(s.x, s.y, REACH, function(e)
        if s.hit[e] then return end
        if math.abs(e.x - s.x) > HIT_W + e.radius then return end
        if math.abs(e.y - s.y) > HIT_H + e.radius then return end

        s.hit[e] = true
        game.particles:burst(e.x, e.y, 2, Palette.red)
        if e:hurt(s.damage) then
            game:killEnemyAt(e)
        end
    end)
end

--- bouncing -------------------------------------------------------------------

-- Off your own pen lines -- the last level. The pen is the one tool that leaves
-- something solid (`wall` in src/tools.lua), so it is the one tool that can turn
-- this: the ink an enemy has to walk around is the ink an S comes off. Which
-- means the level is really an instruction to go and draw the shape you want
-- the S to run around inside, and a pen box with the horde in it is the whole
-- trick.
--
-- The segment hash is asked rather than the strokes, exactly as an enemy asks
-- it, and a bounce off ink costs a bounce like a bounce off the page: without
-- that, a closed pen box would be a permanent S and the weapon would stop being
-- a thing that crosses the page.
function CoolS:ricochet(s, game)
    local walls = game.walls
    if walls.count == 0 then return end

    local seg, cx, cy
    walls:each(s.x, s.y, function(other)
        local ox, oy, d = Walls.closest(other, s.x, s.y)
        if d < other.r + HIT_W and not seg then
            seg, cx, cy = other, ox, oy
        end
    end)
    if not seg then return end

    local nx, ny = Walls.normalOut(seg, s.x - cx, s.y - cy)
    local into = s.dx * nx + s.dy * ny
    -- Already going away from the line: it came off it last frame, or it was
    -- drawn across a line it was already past. Either way there is nothing to
    -- turn, and turning it would send it back in.
    if into >= 0 then return end

    s.x, s.y = cx + nx * (seg.r + HIT_W), cy + ny * (seg.r + HIT_W)
    s.dx = s.dx - 2 * into * nx
    s.dy = s.dy - 2 * into * ny
    s.bounces = s.bounces - 1
    s.hit = {}
end

-- Off the edges of the page, and off ink if it has been taught to. Returns false
-- once it has run out of both bounces and page, which is the only way one of
-- these ever ends.
function CoolS:turn(s, game, left, top, w, h)
    -- Still on its way in. Nothing about the edge applies until every pixel of
    -- it is on the page: an S that started outside would otherwise be off the
    -- edge on its first frame and either die there or bounce straight back out
    -- of the page it was arriving on.
    --
    -- The one way that could go wrong is an S that never arrives -- the page
    -- walks off in the other direction faster than it can close -- so the thing
    -- that ends that is being asked whether it is still coming: once it is no
    -- longer heading towards the middle of the page at all, it never will be.
    if not s.arrived then
        if s.x - HIT_W >= left and s.x + HIT_W <= left + w
            and s.y - HIT_H >= top and s.y + HIT_H <= top + h then
            s.arrived = true
        else
            return (left + w / 2 - s.x) * s.dx + (top + h / 2 - s.y) * s.dy > 0
        end
    end

    if s.ink and s.bounces > 0 then self:ricochet(s, game) end

    -- Which edge it is over, as the direction it would have to be sent to come
    -- back on: 0 for an edge it is nowhere near.
    local hx, hy = 0, 0
    if s.x - HIT_W < left then hx = 1
    elseif s.x + HIT_W > left + w then hx = -1 end
    if s.y - HIT_H < top then hy = 1
    elseif s.y + HIT_H > top + h then hy = -1 end

    if hx == 0 and hy == 0 then return true end

    if s.bounces <= 0 then
        -- Touching an edge is not leaving: it goes on cutting all the way out,
        -- and is only gone once no part of it is on the page.
        return s.x + HIT_W > left and s.x - HIT_W < left + w
            and s.y + HIT_H > top and s.y - HIT_H < top + h
    end

    s.bounces = s.bounces - 1
    s.hit = {}

    -- Set against the edge rather than reflected about the heading, and stood
    -- clear of it: a camera walking sideways can push the page past an S faster
    -- than the S is travelling, and a plain reflection would then bounce it
    -- again on the next frame and every frame after.
    if hx ~= 0 then
        s.dx = math.abs(s.dx) * hx
        s.x = hx > 0 and left + HIT_W or left + w - HIT_W
    end
    if hy ~= 0 then
        s.dy = math.abs(s.dy) * hy
        s.y = hy > 0 and top + HIT_H or top + h - HIT_H
    end

    return true
end

--- flying ---------------------------------------------------------------------

function CoolS:update(dt, game, grid)
    local left, top, w, h = Camera.bounds()

    for i = #self.live, 1, -1 do
        local s = self.live[i]

        -- It winds up as it goes, once the run has bought that. Nothing caps it:
        -- what caps it is the page, since the faster it goes the sooner it uses
        -- up the bounces it has and leaves.
        s.speed = s.speed + s.accel * dt
        local step = s.speed * dt

        s.x = s.x + s.dx * step
        s.y = s.y + s.dy * step

        self:cut(s, game)
        if not self:turn(s, game, left, top, w, h) then
            table.remove(self.live, i)
        end
    end

    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = self.def.every
        self:launch(game)
    end
end

-- A pale blue rim, one pixel out all the way round and drawn under the drawing
-- rather than over it, so nothing of what you drew is covered.
--
-- It is there because of what the page fills up with. Everything on it is ink,
-- and an S is the same colour and the same weight of line as the hero, the
-- crowd and every mark you have left behind -- six thin strokes crossing a page
-- made of thin strokes. The rim is what lifts it off all that: from across the
-- page you see the blue coming before you read the S. Blue rather than any
-- other colour because it is the page's own -- the ruling is drawn in it -- so
-- what floats past reads as a thing on the paper rather than a thing added on
-- top of it.
--
-- Four offset copies of the sprite's own silhouette rather than authored art,
-- because this is a drawing the player made and the rim has to fit whatever
-- they left on the board. It does not move `HIT_W`/`HIT_H`: what the rim marks
-- out is the drawing, and what it cuts with is still the body inside it.
function CoolS:draw(game)
    local sprite = Sprites.cools

    love.graphics.setColor(Palette.sky)
    for _, s in ipairs(self.live) do
        sprite:drawMask(s.x - 1, s.y)
        sprite:drawMask(s.x + 1, s.y)
        sprite:drawMask(s.x, s.y - 1)
        sprite:drawMask(s.x, s.y + 1)
    end

    love.graphics.setColor(1, 1, 1)
    for _, s in ipairs(self.live) do
        sprite:draw(s.x, s.y)
    end
end

return CoolS
