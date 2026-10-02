-- The bomb sitting on the page, counting down.
--
-- The sixth passive weapon, and the first one that asks the player to wait. The
-- other five all resolve the instant they act -- a star cuts what it turns
-- through, a rocket leaves, a beam is a flash, an S crosses -- so every one of
-- them is a thing that happens *to* the crowd. A bomb is put down and then does
-- nothing at all for a couple of seconds, which turns the page around it into a
-- place: the crowd walks into it while you walk out, and where you were standing
-- a moment ago is suddenly the most interesting square on the paper.
--
-- That is what makes it the one weapon whose whole shape is the *fuse*. It
-- drops at your feet, so you always know exactly where one is; the levels make
-- the crater wider, the drops closer together and the fuse shorter, and the last
-- one leaves the crater burning after the bang. None of them makes it aimed,
-- because the aim is your feet a second ago, which is the same bargain the cool S
-- makes from the other end -- an S is a line through where you *were*, and a bomb
-- is a hole in it.
--
-- It is drawn by the player (src/design.lua) and it is the only drawing in the
-- game shown in a colour nobody drew it in: over the last stretch of the fuse
-- the sprite's own silhouette flashes blue (`drawMask`, the trick the sun's
-- bleach and the S's rim are built out of), accelerating as it goes. The blink is
-- the whole of what the weapon tells you, so it is read off the drawing rather
-- than added next to it -- there is nothing on the page saying "bomb" but the
-- thing you drew, and nothing saying "now" but the blue.
--
-- Blue and not red, and the whole weapon follows it: the flash, the blast and the
-- burn it leaves are one family in the player's own half of the palette -- the
-- half the pen, the bullets and the beam are all drawn in.
-- Red is the other side, so a bomb flashing red read as something the horde had
-- put on the page rather than the one thing on it that was yours. What that costs
-- is the easy contrast: blue is the colour of half the marks on the page, so what
-- makes the flash read is the *silhouette* going solid at a stroke rather than
-- the hue -- which is the other half of why the board asks for a shape worth
-- seeing filled in.
--
-- Nothing here hurts the player, and the colour is now the whole of why that has
-- to stay true: blue is yours and red is theirs, and a bomb that could kill you
-- would be a weapon you had to aim away from your own feet -- which is the one
-- place this one is allowed to go.

local Palette = require("src.palette")
local Puddle = require("src.puddle")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")

local Bomb = {}
Bomb.__index = Bomb

local TWO_PI = math.pi * 2

-- The warning, and it is a constant rather than a number on the block: the fuse
-- is what the levels shorten and this is what stays. Whatever a bomb's fuse is,
-- the last nine tenths of a second of it are spent flashing, so a run that has
-- bought the short fuse gets bombs that are lit almost the moment they land --
-- the level makes them go off sooner without ever making one go off unannounced.
local BLINK = 0.9

-- How long between blinks at the start of that stretch and at the bang. An
-- accelerating flicker rather than a clock, which is the laser beam's flash by
-- another name: the two ends say *going to* and *about to*, and nobody has to
-- count anything.
local BLINK_SLOW, BLINK_FAST = 0.16, 0.05

-- The ring the blast leaves, for two or three frames. It is the only account the
-- player ever gets of how far a bomb reached, and the level that widens the
-- crater is unreadable without it -- the damage lands in one instant on things
-- that are dead before you could have looked at them.
--
-- An outline rather than a filled disc, and that is the sun's rule the other way
-- up: the sun is allowed to hide what is standing under it because not being able
-- to see into the safe corner is the trade its whole line is written around.
-- Nothing else in the game may cover the crowd it is killing.
local FLASH = 0.14

-- Bursts of spatter thrown round the rim of the blast, on top of the one at the
-- middle. Eight is what reads as a ring of dust rather than as a spray from the
-- centre, and it is the other half of what says how wide the crater was.
local PUFFS = 8

function Bomb.new()
    return setmetatable({
        def = nil,
        cool = 0,      -- 0, so taking the level drops one at once
        live = {},     -- ticking
        blasts = {},   -- the rings of ones that have gone off
        burns = {},    -- and what the last level leaves in the crater
    }, Bomb)
end

function Bomb:configure(def)
    self.def = def
end

--- going down -----------------------------------------------------------------

-- One bomb, at your feet, in world space from the moment it lands: a bomb that
-- moved with the camera would be the one thing on the page you could not walk
-- away from.
--
-- Everything it will need is copied onto it here, the way a rocket keeps the
-- numbers it was fired with -- so a level taken while one is ticking changes the
-- next bomb and not the one already lit. Whole pixels, because the crater's ring
-- is plotted from this point.
function Bomb:drop(game)
    local def = self.def
    local stats = game.loadout.stats

    self.live[#self.live + 1] = {
        x = math.floor(game.player.x), y = math.floor(game.player.y),
        fuse = def.fuse,
        radius = def.radius,
        -- A passive weapon is what graphite sharpens, and the global multiplier
        -- lands on everything.
        damage = def.damage * stats.passiveDamage * stats.damage,
        burn = def.burn,
        -- How far into the blink it is, in blinks. Counted up rather than worked
        -- out from the fuse, because the period changes as it goes and dividing a
        -- shrinking gap into a shrinking time gives a flicker that stutters
        -- backwards.
        blink = 0,
    }
end

-- How long this blink lasts: BLINK_SLOW at the start of the warning and
-- BLINK_FAST at the bang, whatever the fuse was.
local function period(b)
    local left = math.max(0, b.fuse) / BLINK
    return BLINK_FAST + (BLINK_SLOW - BLINK_FAST) * left
end

--- going off -----------------------------------------------------------------

-- Everything standing in the crater, once. `eachWithin` rather than the spatial
-- hash for the sun's reason -- a crater is far wider than the nine 12px cells
-- `eachNear` looks in -- and it is affordable for the opposite of the sun's
-- reason: this is asked once when a bomb goes off rather than twice a second for
-- as long as one is up.
--
-- Caught by its centre being inside the ring rather than by its edge touching it,
-- which is the sun's test too: the ring that flashes is exactly the ring that
-- killed, and a blast with a radius nobody drew would be a blast nobody could
-- learn.
-- Blue through the middle and sky round the rim, which is the ordinary pairing
-- for anything of the player's: the same two colours the burn is drawn in and the
-- same way round, so the blast and what it leaves behind are one event in two
-- stages rather than two things that happened in the same place. It is also why
-- the spatter is not the red every *hit* in the game throws -- what is being drawn
-- here is the bomb going off, not the crowd being caught by it, and the enemies it
-- kills spark red on their own through Game:killEnemy.
function Bomb:blow(b, game)
    game.particles:burst(b.x, b.y, 10, Palette.blue)
    for i = 0, PUFFS - 1 do
        local a = (i + love.math.random()) / PUFFS * TWO_PI
        game.particles:burst(b.x + math.cos(a) * b.radius * 0.8,
            b.y + math.sin(a) * b.radius * 0.8, 2, Palette.sky)
    end

    game:eachWithin(b.x, b.y, b.radius, function(e)
        if e:hurt(b.damage) then
            game:killEnemyAt(e)
        end
    end)

    self.blasts[#self.blasts + 1] = { x = b.x, y = b.y, r = b.radius, t = FLASH }

    if b.burn then
        local stats = game.loadout.stats
        self.burns[#self.burns + 1] = {
            -- The blot is a puddle (src/puddle.lua) in the other half of the
            -- palette: sky over blue where the boss's is blush over red, because
            -- this is ground *you* took away. Exactly the crater's radius, so the
            -- ring that flashed is the edge of what is left smouldering -- and
            -- the level that widens the blast widens the burn without saying so.
            patch = Puddle.new(b.x, b.y,
                { radius = b.radius, life = b.burn.life,
                  fill = Palette.sky, rim = Palette.blue },
                b.burn.damage * stats.passiveDamage * stats.damage,
                love.math.random(2 ^ 20)),
            every = b.burn.tick,
            tick = b.burn.tick,
        }
    end
end

-- What is left in the crater, hurting whatever stands in it on a clock of its
-- own. It has to be a clock: a burn is the one thing here that damages by being
-- stood in rather than by landing, and nothing in the crowd carries an
-- invulnerability window to rate-limit it the way the player does.
function Bomb:smoulder(dt, game)
    for i = #self.burns, 1, -1 do
        local burn = self.burns[i]
        local patch = burn.patch

        if not patch:update(dt) then
            table.remove(self.burns, i)
        else
            burn.tick = burn.tick - dt
            if burn.tick <= 0 then
                burn.tick = burn.every
                game:eachWithin(patch.x, patch.y, patch.r, function(e)
                    -- The one red in the whole weapon, and deliberately: a speck
                    -- off something taking a hit is red everywhere in this game,
                    -- and it belongs to the thing being burnt rather than to the
                    -- burn. The blue is what the bomb is; the red is what it did.
                    game.particles:burst(e.x, e.y, 1, Palette.red)
                    if e:hurt(patch.damage) then
                        game:killEnemyAt(e)
                    end
                end)
            end
        end
    end
end

--- ticking --------------------------------------------------------------------

function Bomb:update(dt, game, grid)
    for i = #self.live, 1, -1 do
        local b = self.live[i]

        b.fuse = b.fuse - dt
        if b.fuse <= BLINK then
            b.blink = b.blink + dt / period(b)
        end

        if b.fuse <= 0 then
            table.remove(self.live, i)
            self:blow(b, game)
        end
    end

    for i = #self.blasts, 1, -1 do
        local ring = self.blasts[i]
        ring.t = ring.t - dt
        if ring.t <= 0 then table.remove(self.blasts, i) end
    end

    self:smoulder(dt, game)

    -- No cap on how many may be on the page, unlike the cool S: a fuse is a
    -- length written on the block rather than however long the page takes to walk
    -- out from under something, and no level makes the fuse longer than the gap
    -- between drops. So what is on the page is one bomb, or two for the last
    -- fiftieth of a second of a fuse -- there is no surplus for a cap to catch.
    self.cool = self.cool - dt
    if self.cool <= 0 then
        self.cool = self.def.every
        self:drop(game)
    end
end

--- drawing --------------------------------------------------------------------

-- The burn, down with the marks and the boss's puddles rather than up here with
-- the weapons (Loadout:drawGround). It is ground rather than an object, so the
-- crowd walks over the top of it -- a filled patch drawn over the crowd would
-- hide the things it is burning, which is the one thing only the sun is allowed
-- to do.
function Bomb:drawGround(game)
    for _, burn in ipairs(self.burns) do
        burn.patch:draw()
    end
end

function Bomb:draw(game)
    -- The rings first, so a bomb that has landed inside the crater of the last
    -- one reads as standing in it rather than as being cut by it.
    love.graphics.setColor(Palette.blue)
    for _, ring in ipairs(self.blasts) do
        pixelart.circleOutline(ring.x, ring.y, ring.r)
    end

    local sprite = Sprites.bomb
    for _, b in ipairs(self.live) do
        if b.fuse <= BLINK and math.floor(b.blink) % 2 == 0 then
            love.graphics.setColor(Palette.blue)
            sprite:drawMask(b.x, b.y)
        else
            love.graphics.setColor(1, 1, 1)
            sprite:draw(b.x, b.y)
        end
    end
end

return Bomb
