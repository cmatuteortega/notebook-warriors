local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Input = require("src.input")
local Camera = require("src.camera")
local Sfx = require("src.sfx")
local util = require("src.util")

local Player = {}
Player.__index = Player

-- What the player is before the run has taught it anything. Every one of these
-- is the base an upgrade multiplies or adds to (src/upgrades.lua), so this is
-- still the place to balance from -- the loadout only ever scales what is here.
local SPEED = 58
local INVULN_TIME = 0.6

-- How hard the page is knocked when something lands on you (`Camera.knock`).
--
-- This is the one thing in the game that scales with what a hit was worth, and
-- it is the mirror image of the enemies' flinch, which deliberately does not
-- (`HIT_*` in src/enemy.lua). A monster that took a hit has a number thrown off
-- it saying how hard, so its flinch only has to say *that* it happened; you get
-- no number. What you get is a bar that has already moved, in the corner, which
-- is the last place you are looking while something is chasing you -- so the
-- knock is the only thing in the frame that says how much of it just went, and
-- it says it where you cannot miss it.
--
-- Measured as a share of the bar rather than in points, because that is the
-- thing the player actually cares about: a skull's 12 is most of a knock on a
-- fresh page and rather less of one thirty levels later, which is what being
-- tougher ought to feel like. `SHAKE_FULL` is the share that buys the whole
-- thing -- 15%, so an ordinary skull hit at base health lands near the top of
-- the range and everything smaller is spread across the rest of it, rather than
-- every hit in the game bunching up at the quiet end.
local SHAKE_SOFT = 2    -- pixels, what the lightest tap is worth
local SHAKE_HARD = 5    -- and what a hit you will remember is
local SHAKE_FULL = 0.15 -- the share of the bar that pays for SHAKE_HARD

-- What getting back up is worth, for the one thing in the game that lets you
-- (RETAKE, src/perks.lua, through `Game:openRetake`). Both numbers live here
-- rather than on the perk's own row for the reason the language lives on I18n:
-- health and the window nothing can touch you in are the two numbers this file
-- owns, and the catalogue over there is a name and a list of prices.
--
-- Half a page rather than all of it, because a full bar would make the perk a
-- fourth life bought with coins rather than a second chance -- what you are handed
-- back is enough to get out of the crowd that killed you and not enough to stand
-- in it. The grace is more than three times an ordinary hit's window
-- (`INVULN_TIME`) and that is the whole of what makes it a chance at all: you come
-- back standing exactly where you died, which is by definition the worst place on
-- the page, and a hero who came back on the same 0.6s everything else gets would
-- be killed again by the same blob before he had taken a step.
local REVIVE_SHARE = 0.5
local REVIVE_GRACE = 2

-- The hands-free attack is not here at all any more, and neither is the clock it
-- came on. It was two constants and a dozen lines in this file -- a shot at
-- whatever was nearest, or a swing if the character was the kind who swings --
-- and it is now two passive weapons like any other (src/shot.lua, src/sword.lua)
-- with their numbers on their own blocks in src/upgrades.lua. What that changed
-- is what a hero *is*: he walks, he draws, he takes hits and he levels up, and
-- everything that fights on his behalf is a line the run is carrying. A character
-- is which of those two lines he opens the run holding (src/characters.lua) and
-- nothing else, so a swordsman can end a run shooting.

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
-- mid-run changes these numbers under the player's feet, which is the point. It
-- is also the whole of what makes one hero different from another now, since what
-- a character picks is which weapon line the run opens holding -- so nothing
-- about the character reaches this file.
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

        slick = false,
        skid = 0, -- spacing on the wax flicked up while running
        -- Standing on a board (src/skate.lua). Latched in `update` rather than
        -- asked for again in `draw`, so the frame he is drawn on and the frame he
        -- was moved on agree about whether he is walking or sliding.
        skating = false,
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

-- Put back on a rung of the ladder, for a run picked up from a bookmark
-- (src/bookmark.lua). Called after `applyStats`, since the health it is clamped
-- against is the one the restored loadout just worked out.
--
-- `xpNext` is recomputed rather than read out of the file, for the reason
-- `levelUp` recomputes it: the ladder is a function of where you are, so a
-- bookmark that wrote the cost down would go on being right about a number a
-- later version had changed its mind about. Everything here is clamped, because
-- this is the one file in the game somebody may have edited by hand -- and a
-- floor of one hp rather than zero so a garbled line cannot drop you onto the
-- page already dead.
function Player:restore(level, xp, pending, hp)
    self.level = math.max(1, math.floor(level))
    self.xpNext = xpFor(self.level)
    self.xp = math.max(0, math.min(xp, self.xpNext))
    self.pending = math.max(0, math.floor(pending))
    self.hp = math.max(1, math.min(hp, self.maxHp))
end

-- Up again, on the frame the run would have ended (`Game:openRetake`). The two
-- numbers are this file's and nothing is handed in, so there is exactly one thing
-- a retake means and every screen that announces it is reading the same event.
--
-- The floor of one hp is `restore`'s, and for a sharper reason here: a page whose
-- health upgrades worked out an odd `maxHp` of one would otherwise halve to
-- nothing and put the hero back on the page already dead, which is the one state
-- this function exists to get him out of.
--
-- Nothing else about him is touched. The ink he had left, the level he was on, the
-- tool in his hand and the marks on the page are all still his -- that is what a
-- retake *is*, and the only thing that changed is that the run did not stop.
function Player:revive()
    self.hp = math.max(1, math.floor(self.maxHp * REVIVE_SHARE))
    self.invuln = REVIVE_GRACE
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

    -- The other surface underfoot, and the only one you did not have to draw:
    -- the fresh end of your own skate trail (src/skate.lua). It stacks with the
    -- wax rather than replacing it -- both are things you left on the page and
    -- there is no reason a run holding a crayon should have to choose -- and it
    -- reads only the stretch still wet, which is the whole shape of that level.
    local trail = self.loadout:trail()
    self.skating = trail ~= nil
    if trail then
        speed = speed * (trail:boostAt(self.x, self.y) or 1)
    end

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

    -- One-pixel walk bounce, the whole animation budget of a doodle -- and the
    -- one thing a skate takes away. A hero on a board does not walk, and the
    -- bounce stopping is the whole of what the weapon looks like from the outside
    -- (Player:draw): there is no muzzle, no arc and nothing in the air, so the
    -- animation is the readout.
    self.bob = (self.moving and not self.skating) and (self.bob + dt * 9) % 2 or 0

    self.invuln = math.max(0, self.invuln - dt)

    -- Mending, if the run has learned how. It runs while you are being hit as
    -- well as between waves -- there is no "out of combat" in a game where the
    -- horde never stops arriving, and a heal that switched off whenever anything
    -- was near you would be a heal that never ran at all. What keeps it honest
    -- is the rate: see the sellotape line in src/upgrades.lua.
    -- Guarded on the low end as well as the high: a page at zero is a page
    -- Game:update has not yet noticed is dead (the check runs at the end of
    -- the frame, after this), and ticking so much as a fraction of health
    -- back in before that check runs is a run that cannot lose while it is
    -- standing in a crowd, which regen alone can reach given enough of the
    -- endless "PATCH UP" line.
    local regen = self.loadout.stats.regen
    if regen > 0 and self.hp > 0 and self.hp < self.maxHp then
        self.hp = math.min(self.maxHp, self.hp + regen * dt)
    end

    -- Nothing is fired from here. Whatever this run attacks with is stepped with
    -- the rest of its weapons, after the crowd has moved (Loadout:updateWeapons).
end

-- Patched up. The bandaid's half of the sellotape (src/upgrades.lua): the tape
-- mends you for walking about and this mends you for what your weapons are doing
-- to the crowd, so the two are worth carrying together rather than being the same
-- level twice.
--
-- No invulnerability window and nothing to say about it: healing is not an event
-- the way being hit is, it is the bar going the other way a fraction at a time.
-- Which is also why nothing here refuses a heal at full health -- there is
-- nothing to refuse, and the clamp is the whole of it.
--
-- It does refuse one thing: a page already at zero. `Game:update` deals this
-- frame's damage (Game:updateEnemies and friends) before it pays the bandaid
-- out (Loadout:mend) and only checks for death after both -- so a run hitting
-- something hard enough to kill it and heavy enough that the bandaid pays
-- back even a fraction of a point in the same frame would never see the death
-- check find anything but a positive number. Once you are at zero the only
-- way back up is `revive` or `restore`, which say so on purpose.
function Player:mend(amount)
    if amount <= 0 or self.hp <= 0 then return end
    self.hp = math.min(self.maxHp, self.hp + amount)
end

function Player:hurt(amount)
    if self.invuln > 0 then return false end
    self.hp = math.max(0, self.hp - amount)
    self.invuln = INVULN_TIME

    -- Here rather than at the four places that hit you, for Enemy:hurt's reason:
    -- everything arrives through this one door, so there is one place that has
    -- to know and a fifth thing that can hurt you shakes the page and sounds for
    -- free. Under the invulnerability check as well, so the frames you cannot be
    -- hurt on are frames the page is still and quiet -- a knock or a cry that
    -- fired on a hit that did nothing would be the game lying about a hit you
    -- did not take.
    --
    -- The two go together and are one event: the knock says how much of the bar
    -- went and the sound says that it went at all, and neither is any use on a
    -- frame where the other did not happen. No gap on its row and none wanted --
    -- the invulnerability window above is already the rate limit, and a run
    -- being chewed on should sound like it.
    local share = math.min(1, (amount / self.maxHp) / SHAKE_FULL)
    Camera.knock(SHAKE_SOFT + (SHAKE_HARD - SHAKE_SOFT) * share)
    Sfx.play("hurt")
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

-- Blinked out of the page while invulnerable. Asked twice a frame -- once by the
-- hero and once by the blank stamped into the page under him -- and a frame where
-- the two disagreed would print a hero-shaped hole in the ruling.
function Player:blinked()
    return self.invuln > 0 and math.floor(self.invuln * 20) % 2 == 1
end

-- Where his feet are this frame, bounce and all. Two callers for the blink's
-- reason, and they have to agree to the pixel.
function Player:footing()
    return self.y - (self.bob >= 1 and 1 or 0)
end

-- The blank stamped into the page under him, from inside Overprint.beginSolid and
-- for Enemy:drawSolid's reason: his own silhouette in paper, so the ruling and
-- whatever else the page is printed with stop at his edge instead of coming
-- through him.
--
-- Neither the shadow nor the board under it. Both of those are on the paper
-- rather than standing on it -- a shadow that did not darken over a rule would be
-- a sticker, and the board is the ground he is riding, not part of him.
function Player:drawSolid()
    if self:blinked() then return end

    love.graphics.setColor(Palette.paper)
    Sprites.player:drawMask(self.x, self:footing(), self.flip)
end

function Player:draw()
    if self:blinked() then return end

    local sprite = Sprites.player
    local y = self:footing()

    -- The board, where the shadow goes and instead of it: a skate is the ground
    -- he is standing on, so there is nothing left for a scrap of shadow to be
    -- under. It is drawn here rather than by the weapon that owns it because it
    -- has to be under him and he is sorted into the crowd by depth
    -- (Game:draw) -- everything else a passive weapon draws is over the lot.
    --
    -- Placed off the hero's own sprite for the shadow's own reason: the hero is
    -- drawn by the player and his feet are wherever they left them.
    if self.skating then
        Sprites.board(sprite, Sprites.skate, self.x, self.y)
    else
        Sprites.shadow(sprite, self.x, self.y)
    end

    love.graphics.setColor(1, 1, 1)
    sprite:draw(self.x, y, self.flip)
end

return Player
