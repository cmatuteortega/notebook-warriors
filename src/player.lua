local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Input = require("src.input")
local util = require("src.util")

local Player = {}
Player.__index = Player

-- What the player is before the run has taught it anything. Every one of these
-- is the base an upgrade multiplies or adds to (src/upgrades.lua), so this is
-- still the place to balance from -- the loadout only ever scales what is here.
local SPEED = 58
local FIRE_RATE = 0.55
local DAMAGE = 3
local RANGE = 96
local INVULN_TIME = 0.6

-- The experience ladder, and it is a curve rather than a ratio on purpose.
--
-- It used to be exponential -- every level 1.35x the cost of the one before --
-- which sounds gentle and is not. By level 30 a single level wanted 40,000 xp,
-- which is six minutes of a horde at full tilt for one card, and a run simply
-- stopped levelling somewhere around 28. That put the real ceiling on a run
-- nowhere near where the draft's is: the four-slot caps (`Loadout.SLOTS`) leave
-- room for 59 picks, so over half of what a run was *allowed* to learn was never
-- once put on a card. The ladder was the wall, not the catalogue.
--
-- Quadratic keeps the shape and loses the wall. A level still costs more than
-- the one before it and always by more than it did last time, so the late ones
-- are still earned -- what it no longer does is outrun the page. The two curves
-- sit within a few percent of each other up to about level 10, which is the
-- stretch anyone has ever actually felt, and they part company after it.
--
-- 0.9 is set against what the horde pays out rather than picked for its shape.
-- The spawner's floor and batch size (src/spawner.lua) have a run earning
-- somewhere between 85 and 140 xp a second once every enemy is unlocked, which
-- lands the 59th and last pick between minute 15 and minute 20 depending on how
-- fast the build clears. Past there the ladder carries on and so does the
-- draft, which by then is offering the endless lines (src/upgrades.lua).
local XP_BASE = 5    -- what the first level costs
local XP_RISE = 0.9  -- and how much steeper every one after it gets

local function xpFor(level)
    return math.floor(XP_RISE * level * level + level + XP_BASE)
end

-- `loadout` is the run's, and is read live rather than copied: an upgrade taken
-- mid-run changes these numbers under the player's feet, which is the point.
function Player.new(x, y, loadout)
    local stats = loadout.stats

    return setmetatable({
        x = x, y = y,
        loadout = loadout,
        -- Kept in proportion to the sprite the studio hands over, which is a
        -- good deal bigger than a monster: contact lands about where the drawing
        -- does rather than a few pixels inside it.
        radius = 6,
        flip = false,
        moving = false,
        -- The way you are walking, kept when you stop rather than cleared with
        -- `moving`: it is what the laser beam is aimed down (src/beam.lua), and
        -- an aim that fell back to nothing the moment you stood still would be
        -- one you could never line up. Any heading at all, not one of eight --
        -- a thumb stick hands over whatever angle it is pushed at, and nothing
        -- reading this has a sprite to round it for. Facing right to start with,
        -- which is the way the hero is drawn before anything has turned him.
        headX = 1, headY = 0,
        bob = 0,
        hp = stats.maxHp,
        maxHp = stats.maxHp,
        invuln = 0,

        level = 1,
        xp = 0,
        xpNext = xpFor(1),
        pending = 0,  -- levels reached but not yet spent on an upgrade

        -- Auto-attack: fires at the nearest enemy in range, hands-free.
        fireTimer = 0,

        slick = false,
        skid = 0, -- spacing on the wax flicked up while running
    }, Player)
end

-- The run has just taken an upgrade. Everything else is read where it is used,
-- but health has two numbers and only one of them is a stat: the room a fresh
-- page adds is handed over full, because a bigger bar you then have to go and
-- fill is not a reward, it is homework.
function Player:applyStats()
    local grew = self.loadout.stats.maxHp - self.maxHp
    self.maxHp = self.loadout.stats.maxHp
    if grew > 0 then
        self.hp = math.min(self.maxHp, self.hp + grew)
    end
end

function Player:update(dt, game)
    -- Keyboard or invisible touch stick; the stick is analogue, so this vector
    -- can be shorter than 1 and the player walks proportionally slower.
    local dx, dy = Input.movement()

    -- Wax underfoot: you run along your own crayon lane. The enemies chasing
    -- you are on the same surface and can't corner on it, which is the point.
    local slick = game.hasSlick and game:slickAt(self.x, self.y) or nil
    self.slick = slick ~= nil
    local speed = SPEED * self.loadout.stats.speed
    if slick then speed = speed * slick.boost end

    self.x = self.x + dx * speed * dt
    self.y = self.y + dy * speed * dt

    self.moving = dx ~= 0 or dy ~= 0

    -- Held rather than tracked: what is wanted is the way you last *meant* to
    -- go, so this takes the input vector and not the distance actually covered.
    -- Being shoved into a wall, glued to the page or slid along your own wax
    -- would otherwise all count as turning round.
    if self.moving then
        self.headX, self.headY = util.normalize(dx, dy)
    end

    -- Flakes kicked up off the wax, so the speed reads as speed.
    if self.slick and self.moving then
        self.skid = self.skid - speed * dt
        if self.skid <= 0 then
            self.skid = 7
            game.particles:burst(self.x - dx * 3, self.y + 4 - dy * 3, 1, Palette.blue)
        end
    end
    if dx < 0 then self.flip = true elseif dx > 0 then self.flip = false end

    -- One-pixel walk bounce, the whole animation budget of a doodle.
    self.bob = self.moving and (self.bob + dt * 9) % 2 or 0

    self.invuln = math.max(0, self.invuln - dt)

    -- Mending, if the run has learned how. It runs while you are being hit as
    -- well as between waves -- there is no "out of combat" in a game where the
    -- horde never stops arriving, and a heal that switched off whenever anything
    -- was near you would be a heal that never ran at all. What keeps it honest
    -- is the rate: see the sellotape line in src/upgrades.lua.
    local regen = self.loadout.stats.regen
    if regen > 0 and self.hp < self.maxHp then
        self.hp = math.min(self.maxHp, self.hp + regen * dt)
    end

    self.fireTimer = self.fireTimer - dt
    if self.fireTimer <= 0 then
        if self:fire(game) then
            self.fireTimer = FIRE_RATE * self.loadout.stats.fireRate
        else
            self.fireTimer = 0.05 -- nothing in range; check again shortly
        end
    end
end

function Player:fire(game)
    local best = game:nearestEnemy(self.x, self.y, RANGE)
    if not best then return false end

    -- The auto-shot is the one weapon you never aim, so it is a passive one as
    -- far as the upgrades are concerned: graphite sharpens it, scissors do not.
    local stats = self.loadout.stats
    local dx, dy = util.normalize(best.x - self.x, best.y - self.y)
    game:spawnBullet(self.x, self.y - 1, dx, dy,
        DAMAGE * stats.passiveDamage * stats.damage)
    return true
end

function Player:hurt(amount)
    if self.invuln > 0 then return false end
    self.hp = math.max(0, self.hp - amount)
    self.invuln = INVULN_TIME
    return true
end

-- A level is not spent here. It is banked, and the run notices and stops to ask
-- what to do with it (Game:openDraft) -- which is why this counts them rather
-- than returning that one was reached: a big enough pickup can carry two, and
-- the second draft has to come up after the first is answered rather than being
-- swallowed by it.
function Player:addXp(amount)
    -- What a gem is worth on arrival rather than what it was worth lying on the
    -- page, so the multiplier lands once, here, however the xp got to us. It
    -- leaves the total fractional, which nothing minds: xp is only ever read as
    -- a fraction of the next level and is never written down as a number.
    self.xp = self.xp + amount * self.loadout.stats.xpGain
    while self.xp >= self.xpNext do
        self.xp = self.xp - self.xpNext
        self:levelUp()
    end
end

-- One level, banked. Also reachable without any xp at all -- the diamond
-- pickup grants one outright (src/pickup.lua) -- and a granted level keeps the
-- xp already saved towards the next: the ladder steps up underneath it, but
-- nothing the horde paid out is thrown away.
function Player:levelUp()
    self.level = self.level + 1
    -- Read off the level rather than stepped on from the last rung. The two
    -- come to the same thing -- the chain always started at level one either
    -- way -- but a ladder written as a function of where you are is one you can
    -- read the cost of any level off without walking up to it, which is how the
    -- 0.9 above was set against what the horde pays out.
    self.xpNext = xpFor(self.level)
    self.pending = self.pending + 1
end

function Player:draw()
    -- Blink while invulnerable.
    if self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 1 then return end

    local sprite = Sprites.player
    local y = self.y - (self.bob >= 1 and 1 or 0)

    Sprites.shadow(sprite, self.x, self.y)

    love.graphics.setColor(1, 1, 1)
    sprite:draw(self.x, y, self.flip)
end

return Player
