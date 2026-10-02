-- The spirals that wind onto the page and gather the crowd into them.
--
-- The twelfth passive weapon and the only one that does no damage at all. Every
-- other one is a way of putting a number on something; this one moves the horde
-- and then leaves you to it. What a run buys is not damage per second, it is a
-- crowd standing *somewhere in particular* -- which is the one thing the other
-- eleven cannot arrange for themselves, since a bomb at your feet, a beam down
-- your line and a bolt out of a cloud are all answers to the question of where
-- the fight already is. This is the question.
--
-- So it is the weapon that is worth the most next to the others and worth the
-- least on its own, and that is deliberate: a spiral is a hole in the page that
-- everything nearby walks into, and what happens to them in there is whatever
-- else the run is carrying. A run with a sun, a crater or a swarm and a spiral is
-- a run that chooses where the killing happens.
--
-- **The pull is a decision and the push is a force**, and the two halves of the
-- line are built out of the two things the game already has for moving a monster.
-- A spiral *lures*: an enemy inside it is handed somewhere else to walk to
-- (Enemy:lure), which is the skate's chill handed over the same way -- the crowd
-- has already moved by the time the weapons are stepped, so what a weapon does to
-- it lands next frame. Being lured is a thing it decides to do, so it keeps
-- walking, keeps bumping into its neighbours and keeps hurting you if you are
-- standing where it is going. The push is a *shove* (Enemy:knockback) and could
-- not be a lure: an enemy told to walk away from you would never reach you again,
-- and a weapon that made a run untouchable would be the end of the run. A shove
-- decays, so what the last level actually buys is a treadmill -- a blob loses most
-- of its ground and a bat loses some of it, and the boss barely notices, since
-- `knock` on its row already says what a shove is worth against it and this asks
-- through the same door as everything else that pushes.
--
-- **It has no board, and it is only the second weapon with none** (the laser
-- beam is the other). A spiral is procedurally drawn -- a random number of arms,
-- a random number of turns, a random handedness, spinning -- and a drawing is a
-- fixed grid of pixels used exactly as drawn. There is nothing here a board
-- could hold: what makes a spiral a spiral is the winding, which is arithmetic,
-- and it is plotted with `pixelart` at whatever angle it has got to rather than
-- being a sprite rounded to one of eight. The beam is aimed anywhere for the same
-- reason and it is the same freedom.
--
-- Everything it draws goes down with the marks (`drawGround`), under the crowd:
-- it is ink on the paper, not an object standing on it, and the things walking
-- into it have to be visible on top of it.

local Camera = require("src.camera")
local Palette = require("src.palette")
local pixelart = require("src.pixelart")
local util = require("src.util")

local Spiral = {}
Spiral.__index = Spiral

local TWO_PI = math.pi * 2

-- How long one takes to wind onto the page. The whole spiral is plotted from the
-- middle out, so this is free: what is drawn is the curve up to however far it
-- has got, and a spiral that appeared whole would be a stamp rather than
-- something being drawn.
local GROW = 0.4

-- The fraction of its life it spends going. Ink fades by stepping down the ramp
-- and dropping pixels out at random, never by alpha (see the rendering rules), so
-- what this stretch is is blue going pale and the curve going dotted.
local FADE = 0.45

-- How often the crowd is told where to walk, and how long a telling lasts is
-- `hold` on the block. The tick is well inside the shortest hold the line ever
-- sells, so an enemy standing in a spiral is never briefly let go of -- and one
-- walking out of it keeps going for the rest of its hold, which is the whole of
-- what the fourth level sells.
local PULL_TICK = 0.15

-- The push is its own clock and a shorter one, since a shove decays: it is a
-- steady outward pressure made of little ones, and at anything slower than this
-- the crowd would step in and out in time with it.
local PUSH_TICK = 0.1

-- How fast one turns on the page, in radians a second. Slow enough to read as a
-- drawn line rather than a wheel: what a spiral is doing is winding, and the spin
-- is the only thing that says the page is pulling rather than that somebody drew
-- a curl on it.
local SPIN = 1.4

-- Pixels between one plotted sample and the next along the curve. Two, which is
-- what keeps a line unbroken (`pixelart.line` joins them) without plotting the
-- same pixel twice on the tight inner turns.
local STEP = 2

-- How far from the player one may wind on, and how many goes it gets at finding
-- somewhere. A spiral under your own feet is a spiral you are standing in the
-- middle of, which is the opposite of what it is for -- and after a handful of
-- tries it takes what it can get rather than skipping its turn.
local MIN_OFF = 44
local TRIES = 6

function Spiral.new()
    return setmetatable({
        def = nil,
        cool = 0,   -- 0, so taking the level winds one on at once
        live = {},
        -- The last level's own spiral, the one round the player. Built once and
        -- then kept: it has no life and never leaves.
        push = nil,
        pushT = 0,
    }, Spiral)
end

function Spiral:configure(def)
    self.def = def

    if def.push and not self.push then
        -- Fixed where a loose spiral is rolled: two arms, two turns, always
        -- wound the same way. Not because the handedness says anything -- the
        -- loose ones are random and one of them will match it half the time --
        -- but because this is the one spiral you see for the rest of the run, and
        -- a thing you are looking at that often should be the same thing every
        -- time. What says it is yours rather than one that happened to land on
        -- you is that it is under your feet and never leaves.
        self.push = {
            spin = love.math.random() * TWO_PI,
            dir = -1,
            arms = 2,
            turns = 2,
            seed = love.math.random(4096),
        }
    end
end

--- winding on ----------------------------------------------------------------

-- Somewhere on the page for a spiral to be, with the whole of it on the page --
-- the sun's rule, read the other way round: nothing may be *drawn* where it
-- cannot be seen either, and half a spiral hanging off the edge is a curl rather
-- than a hole. It reads `Camera.bounds()` for that, as everything anchored to the
-- viewport does.
function Spiral:launch(game)
    local def = self.def
    if #self.live >= def.most then return false end

    local left, top, w, h = Camera.bounds()
    local r = def.radius
    local px, py = game.player.x, game.player.y
    local x, y

    for _ = 1, TRIES do
        x = left + r + love.math.random() * math.max(1, w - r * 2)
        y = top + r + love.math.random() * math.max(1, h - r * 2)
        if util.len(x - px, y - py) >= MIN_OFF then break end
    end

    -- Everything it will need is copied onto it here, the rocket's rule: a level
    -- taken while one is on the page changes the next spiral and not the one
    -- already turning.
    self.live[#self.live + 1] = {
        x = x, y = y,
        age = 0,
        life = def.life,
        radius = r,
        hold = def.hold,
        spin = love.math.random() * TWO_PI,
        dir = love.math.random(2) == 1 and 1 or -1,
        -- What makes each one its own drawing. One arm is a curl and two is a
        -- whirl; three at this size is a disc with a texture, so there is
        -- nothing past two worth offering.
        --
        -- The turns are held between one and a half and two and a half for two
        -- reasons that happen to agree. A winding every twenty pixels or so
        -- reads as a spiral, and at four or five turns the gaps close up and it
        -- reads as a target -- and the pixels drawn are pi x turns x radius x
        -- arms, which at the top of the line is nine hundred of them for one
        -- spiral. The laser beam is the only other thing in the game that draws
        -- in that order (see pixelart.band, which exists to keep it there), and
        -- two spirals plus the one round your feet is as much of it as this
        -- weapon should ever ask for.
        arms = love.math.random(2),
        turns = 1.4 + love.math.random(),
        -- Which pixels drop out on the way out. Kept rather than rolled at the
        -- draw, so a spiral dissolves the same way every frame instead of
        -- shimmering.
        seed = love.math.random(4096),
        tick = 0,
    }

    return true
end

--- pulling -------------------------------------------------------------------

-- Everybody standing inside one, handed the middle of it to walk to. `eachWithin`
-- for the sun's reason -- a spiral is far wider than the nine 12px cells the hash
-- looks in -- and on a tick rather than every frame, which is the same bargain.
--
-- The boss is not exempt and needs no clause of its own: `hold` on its row is
-- already what being held is worth against it -- 0.3, written for the gluestick
-- -- and a lure is a hold. At the opening that is shorter than this tick, so a
-- boss inside a spiral leans into it between beats and never parks in it; at the
-- top of the line it follows for half a second at a time. Which is the shape
-- every other kind of control in this game takes against it, and it arrives here
-- for nothing.
function Spiral:pull(s, game)
    game:eachWithin(s.x, s.y, s.radius, function(e)
        e:lure(s.x, s.y, s.hold * (e.def.hold or 1))
    end)
end

-- And the last level's, which is the same circle with the sign flipped: away
-- from you rather than towards the middle. A shove rather than a telling, for the
-- reason at the top of this file.
--
-- Anything standing exactly on you gets nothing, since there is no direction to
-- push it in -- and it is about to be touching you anyway, which is a problem a
-- spiral was never going to solve.
function Spiral:shove(game)
    local def = self.def.push
    local player = game.player

    game:eachWithin(player.x, player.y, def.radius, function(e)
        local nx, ny = util.normalize(e.x - player.x, e.y - player.y)
        if nx ~= 0 or ny ~= 0 then
            e:knockback(nx, ny, def.force * game.loadout.stats.knock)
        end
    end)
end

function Spiral:update(dt, game, grid)
    local def = self.def

    for i = #self.live, 1, -1 do
        local s = self.live[i]
        s.age = s.age + dt
        s.spin = (s.spin + s.dir * SPIN * dt) % TWO_PI

        if s.age >= s.life then
            table.remove(self.live, i)
        else
            s.tick = s.tick - dt
            if s.tick <= 0 then
                s.tick = PULL_TICK
                self:pull(s, game)
            end
        end
    end

    -- A spiral with nowhere to go is not a thing that can happen -- the page is
    -- always somewhere -- so unlike the cloud and the cool S this clock is never
    -- held, only spent. The one thing that turns a beat down is the page already
    -- being at its cap, and waiting the full gap for the next go is what the cap
    -- is *for*.
    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = def.every
        self:launch(game)
    end

    if self.push then
        self.push.spin = (self.push.spin + self.push.dir * SPIN * dt) % TWO_PI
        -- Where it is and how wide, kept here rather than reached for at the
        -- draw: it is round the player this frame, and the draw is only ever
        -- allowed to read.
        self.push.x, self.push.y = game.player.x, game.player.y
        self.push.radius = def.push.radius

        self.pushT = self.pushT - dt
        if self.pushT <= 0 then
            self.pushT = PUSH_TICK
            self:shove(game)
        end
    end
end

--- drawing -------------------------------------------------------------------

-- One spiral, plotted a sample at a time and joined up. r = t * radius against an
-- angle winding `turns` times round is the plainest spiral there is, and the
-- plainest is what a hand draws.
--
-- `fade` under one is the dropout: a sample whose own hash falls above what is
-- left of the spiral is not drawn, and the line simply carries on from the last
-- one that was -- so the curve goes dotted and then goes, rather than going grey.
-- The hash is of the sample and the spiral's own seed, so the holes stay in the
-- same places while they spread.
local function plot(s, grown, fade)
    local total = s.radius * grown
    local steps = math.max(2, math.ceil(math.pi * s.turns * total / STEP))

    for arm = 0, s.arms - 1 do
        local offset = arm / s.arms * TWO_PI
        local px, py

        for i = 0, steps do
            local t = i / steps
            local a = s.spin + offset + s.dir * t * s.turns * TWO_PI
            local r = t * total
            local x = math.floor(s.x + math.cos(a) * r)
            local y = math.floor(s.y + math.sin(a) * r)

            if px and (x ~= px or y ~= py)
                and (fade >= 1 or util.hash01(i, arm, s.seed) < fade) then
                pixelart.line(px, py, x, y)
            end

            px, py = x, y
        end
    end
end

-- Down on the page with the marks and the boss's blots rather than up with the
-- weapons, and this is the one weapon that is *only* down here: it is a line
-- drawn on the paper, and the crowd being drawn into it has to be drawn over it.
-- The push spiral is under the player's own feet for the same reason.
--
-- Blue, because it is yours -- the half of the palette that runs from the pen you
-- draw walls with to the bomb's fuse. It goes pale before it goes, which is the
-- ramp fades are made of and not a fade of its own.
function Spiral:drawGround(game)
    for _, s in ipairs(self.live) do
        local left = 1 - s.age / s.life
        local fade = 1

        if left < FADE then
            fade = left / FADE
            love.graphics.setColor(Palette.sky)
        else
            love.graphics.setColor(Palette.blue)
        end

        plot(s, math.min(1, s.age / GROW), fade)
    end

    -- Guarded on having been placed as well as on existing, and that is not belt
    -- and braces: the level is taken while the run is *held*, and the draft's
    -- cards are laid over a page still being drawn behind them -- so the first
    -- thing that happens to this spiral is being drawn, a frame before anything
    -- has told it where the player is.
    if self.push and self.push.x then
        love.graphics.setColor(Palette.blue)
        plot(self.push, 1, 1)
    end
end

return Spiral
