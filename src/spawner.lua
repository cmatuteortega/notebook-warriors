-- Drops enemies on a ring just outside the camera so they always walk on from
-- offscreen, and slowly turns up the pressure as the run goes on.

local util = require("src.util")

local Spawner = {}
Spawner.__index = Spawner

local SPAWN_RADIUS = 200
local SPAWN_CLEARANCE = 24 -- past the corner of the screen, so nothing appears
                           -- out of thin air on a wide one
local MAX_ENEMIES = 260

-- { kind, unlocked at (seconds), weight }
local TABLE = {
    { "blob",  0,  10 },
    { "bat",   25, 7 },
    { "skull", 60, 3 },
}

function Spawner.new()
    return setmetatable({ timer = 0 }, Spawner)
end

function Spawner:pick(time)
    local total = 0
    for _, row in ipairs(TABLE) do
        if time >= row[2] then total = total + row[3] end
    end

    local roll = love.math.random() * total
    for _, row in ipairs(TABLE) do
        if time >= row[2] then
            roll = roll - row[3]
            if roll <= 0 then return row[1] end
        end
    end
    return TABLE[1][1]
end

function Spawner:update(dt, game)
    self.timer = self.timer - dt
    if self.timer > 0 then return end

    local time = game.time
    self.timer = math.max(0.22, 1.1 - time * 0.008)

    -- A phone screen is wider than the 320x180 this ring was drawn for, so the
    -- ring has to clear the corner of whatever canvas we actually got.
    local ring = math.max(SPAWN_RADIUS,
        util.len(game.vw, game.vh) / 2 + SPAWN_CLEARANCE)

    local batch = 1 + math.floor(time / 25)
    for _ = 1, batch do
        if #game.enemies >= MAX_ENEMIES then break end
        local a = love.math.random() * math.pi * 2
        local r = ring + love.math.random() * 24
        game:spawnEnemy(
            self:pick(time),
            game.player.x + math.cos(a) * r,
            game.player.y + math.sin(a) * r)
    end
end

return Spawner
