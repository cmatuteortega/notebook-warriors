-- Passive auto-shot: on each beat, a Bullet (src/bullet.lua) at each of the
-- nearest targets in range. Clock and target choice only, no drawing. NB
-- `game.shots` and enemy `shot` rows are the *enemy's* fire, unrelated.

local util = require("src.util")

local Shot = {}
Shot.__index = Shot

-- Retry delay when there was nothing in range. The beat is held rather than
-- spent, so walking into a fresh crowd is answered on the spot.
local LOOK = 0.05

-- Perpendicular gap between a volley's pellets so two copies of a 5x5 drawing
-- read as two. Offsets the start, not the aim: 2px over 96 is ~1 degree.
local SPREAD = 4

function Shot.new()
    return setmetatable({
        def = nil,
        timer = 0,
    }, Shot)
end

function Shot:configure(def)
    self.def = def
end

-- One beat. `nearestEnemies` rather than the spatial hash: range exceeds a
-- cell and this is asked a few times a second. Plural because the last level
-- of the line fires two at once.
function Shot:update(dt, game)
    local def = self.def

    self.timer = self.timer - dt
    if self.timer > 0 then return end

    local player = game.player
    local shots = def.shots
    local targets = game:nearestEnemies(player.x, player.y, def.range, shots)
    if #targets == 0 then
        self.timer = LOOK
        return
    end

    -- Graphite (passiveDamage) sharpens passives; the global multiplier is
    -- on top.
    local stats = game.loadout.stats
    local damage = def.damage * stats.passiveDamage * stats.damage

    for i = 1, shots do
        -- Both pellets at the nearest when the crowd is thinner than the
        -- volley, so a second shot is not wasted on a one-blob boss fight.
        local target = targets[i] or targets[#targets]
        local dx, dy = util.normalize(target.x - player.x, target.y - player.y)

        -- Spaced across the line (see SPREAD); a single shot leaves centred.
        local off = shots > 1 and (i - (shots + 1) / 2) * SPREAD or 0
        -- A pixel up, so the shot leaves the hero's hand rather than his feet.
        game:spawnBullet(player.x - dy * off, player.y - 1 + dx * off,
            dx, dy, damage, def.speed)
    end

    -- `every` alone, in seconds: the metronome already shortened it on the
    -- block (`scaleCadence` in src/loadout.lua).
    self.timer = def.every
end

return Shot
