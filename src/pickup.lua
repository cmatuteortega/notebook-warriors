-- What the page scatters for you to walk to. Three kinds -- a heart that heals,
-- a droplet that refills the ink well, a diamond worth a whole level -- and all
-- of them land out of view, because the reward is the walk: a gem is thrown at
-- your feet by a kill you already made, and these are the opposite half of that
-- idea, something out there that pays a run for moving instead of standing in
-- one spot grinding the horde. That is also why the magnet ignores them and
-- there is no pull at all -- touched means touched.
--
-- They arrive two ways. A scatter clock drops one just past the screen edge
-- every few seconds, so there is always something a few steps from view -- and
-- underneath that, the page itself has pickups at fixed spots, a pure function
-- of the cell coordinates like the ruling and everything else about the page
-- (see src/background.lua on determinism). A fixed spot materialises when you
-- come near, is still there if you leave and come back, and once taken is gone
-- for the run: it is a place on the page, not a beat on a clock, and knowing
-- where one is is worth something.

local Sprites = require("src.sprites")
local Palette = require("src.palette")
local util = require("src.util")

local Pickup = {}
Pickup.__index = Pickup

-- The scatter, on a slow clock, and never many lying around: a page carpeted
-- in prizes is a page where none of them is worth turning for.
Pickup.EVERY = 5
Pickup.MAX = 8

-- How far past the screen edge a scattered one lands. The enemy ring is no
-- good here: it clears the *corner* of the screen, which up or down -- where
-- the view is half as tall as it is wide -- is a hundred pixels of blind
-- walking, and a pickup nobody ever sees promotes nothing. These sit close
-- enough that a few steps in any direction bring one into view.
local CLEARANCE = 24
local SPREAD = 70

local DESPAWN = 480  -- wider than the enemies' 420, so one you saw and turned
                     -- away from is still there if you come back for it
local TOUCH = 4      -- on top of the player's radius
local MIN_APART = 30 -- no two pickups closer than this: two on one spot read
                     -- as one, and the second is a prize nobody knows they won

-- The fixed layer. One spot in roughly every third cell, held away from the
-- cell borders so no two neighbours can land inside MIN_APART of each other.
-- MATERIALIZE sits under DESPAWN so a spot on the boundary does not flicker
-- in and out as you shuffle.
local CELL = 260
local DENSITY = 0.35
local MATERIALIZE = 440

local HEAL = 25      -- a quarter of the base bar
local INK = 0.5      -- fraction of the well, so a bigger well drinks deeper

-- The diamond is rare because it is a draft in disguise -- a free level is
-- worth more than anything else on this table -- and rarity is what keeps
-- spotting one an event rather than an errand.
local KINDS = {
    { kind = "heart",   weight = 4 },
    { kind = "ink",     weight = 4 },
    { kind = "diamond", weight = 1 },
}

-- Always consumed, even by a bar with no room for it: a heart that refused a
-- full bar hung around holding one of the MAX slots, quietly throttling the
-- scatter clock for as long as you stayed healthy -- and a run walking past a
-- heart it cannot use right now still reads "taken" more honestly than a heart
-- that bounces off. The diamond banks its level, and the run stops to spend it
-- the same way an earned one is spent (Game:update).
local TAKE = {
    heart = function(game, x, y)
        local p = game.player
        p.hp = math.min(p.maxHp, p.hp + HEAL)
        game.particles:burst(x, y, 6, Palette.red)
    end,
    ink = function(game, x, y)
        local max = game.loadout.stats.inkMax
        game.ink = math.min(max, game.ink + max * INK)
        game.particles:burst(x, y, 6, Palette.blue)
    end,
    diamond = function(game, x, y)
        game.player:levelUp()
        game.particles:burst(x, y, 8, Palette.sky)
    end,
}

-- One weighted table serves both layers: the scatter rolls the dice, a fixed
-- spot hashes its cell, and either way the roll lands in [0,1).
local function kindFor(roll)
    local total = 0
    for _, row in ipairs(KINDS) do total = total + row.weight end

    roll = roll * total
    for _, row in ipairs(KINDS) do
        roll = roll - row.weight
        if roll <= 0 then return row.kind end
    end
    return KINDS[1].kind
end

local function clearOf(pickups, x, y)
    for _, p in ipairs(pickups) do
        if util.len(p.x - x, p.y - y) < MIN_APART then return false end
    end
    return true
end

function Pickup.new(kind, x, y)
    return setmetatable({
        kind = kind,
        x = x, y = y,
        bob = util.hash01(x, y, 5) * 2,
        dead = false,
    }, Pickup)
end

-- A candidate spot just past a random edge of the screen -- never in view,
-- always a short walk from being in view. The side is rolled in proportion to
-- its length, so the scatter is even along the whole rim of the screen rather
-- than piling up on the short sides.
local function pastEdge(game)
    local hw, hh = game.vw / 2, game.vh / 2
    local out = CLEARANCE + love.math.random() * SPREAD

    local r = love.math.random() * (game.vw + game.vh) * 2
    if r < game.vw then                     -- above
        return game.player.x + love.math.random() * game.vw - hw,
            game.player.y - (hh + out)
    elseif r < game.vw * 2 then             -- below
        return game.player.x + love.math.random() * game.vw - hw,
            game.player.y + hh + out
    elseif r < game.vw * 2 + game.vh then   -- left
        return game.player.x - (hw + out),
            game.player.y + love.math.random() * game.vh - hh
    else                                    -- right
        return game.player.x + hw + out,
            game.player.y + love.math.random() * game.vh - hh
    end
end

-- One scattered pickup, or nil when every roll landed on top of something
-- already out there -- the clock simply tries again on its next beat.
function Pickup.scatter(game)
    for _ = 1, 8 do
        local x, y = pastEdge(game)
        if clearOf(game.pickups, x, y) then
            return Pickup.new(kindFor(love.math.random()), x, y)
        end
    end
end

-- What the fixed layer holds at one cell, if anything. Seeded per run rather
-- than truly global, because every run starts at (0, 0): a layout shared by
-- all runs would hand every one of them the same opening pickups -- the same
-- diamond a hundred pixels from the start, every time -- and an opening you
-- can memorise is an opening, not a discovery. Within the run it never moves.
local function fixedAt(cx, cy, seed)
    if util.hash01(cx, cy, seed + 7) >= DENSITY then return end

    return kindFor(util.hash01(cx, cy, seed + 8)),
        (cx + 0.2 + util.hash01(cx, cy, seed + 9) * 0.6) * CELL,
        (cy + 0.2 + util.hash01(cx, cy, seed + 10) * 0.6) * CELL
end

-- Walk the fixed cells within reach and wake any spot that should be standing
-- and is not: not taken this run, not already awake, and not inside MIN_APART
-- of something else (a scattered pickup can sit on a fixed spot; the spot
-- waits its turn). A woken pickup that is later walked away from dies off the
-- list like any other -- what brings it back is this, on the way back in.
function Pickup.materialize(game)
    local px, py = game.player.x, game.player.y

    local awake = {}
    for _, p in ipairs(game.pickups) do
        if p.cell then awake[p.cell] = true end
    end

    for cy = math.floor((py - MATERIALIZE) / CELL),
             math.floor((py + MATERIALIZE) / CELL) do
        for cx = math.floor((px - MATERIALIZE) / CELL),
                 math.floor((px + MATERIALIZE) / CELL) do
            local key = cx * 100000 + cy
            if not game.pickupTaken[key] and not awake[key] then
                local kind, x, y = fixedAt(cx, cy, game.pickupSeed)
                if kind and util.len(x - px, y - py) < MATERIALIZE
                    and clearOf(game.pickups, x, y) then
                    local p = Pickup.new(kind, x, y)
                    p.cell = key
                    game.pickups[#game.pickups + 1] = p
                end
            end
        end
    end
end

function Pickup:update(dt, game)
    local player = game.player
    local dist = util.len(player.x - self.x, player.y - self.y)

    if dist < player.radius + TOUCH then
        TAKE[self.kind](game, self.x, self.y)
        -- A fixed spot is spent for the run; a scattered one just dies.
        if self.cell then game.pickupTaken[self.cell] = true end
        self.dead = true
        return
    end

    -- Abandoned rather than hoarded: a run that walks off leaves it behind --
    -- a scattered one for good, a fixed one until the next visit.
    if dist > DESPAWN then
        self.dead = true
        return
    end

    self.bob = (self.bob + dt * 3) % 2
end

function Pickup:draw()
    love.graphics.setColor(1, 1, 1)
    Sprites.pickups[self.kind]:draw(self.x, self.y - (self.bob >= 1 and 1 or 0))
end

return Pickup
