-- Single-pixel ink specks, sprayed when something dies or gets hit.

local Palette = require("src.palette")

local Particles = {}
Particles.__index = Particles

function Particles.new()
    return setmetatable({ list = {} }, Particles)
end

function Particles:burst(x, y, count, color)
    for _ = 1, count do
        local a = love.math.random() * math.pi * 2
        local speed = 18 + love.math.random() * 34
        self.list[#self.list + 1] = {
            x = x, y = y,
            dx = math.cos(a) * speed,
            dy = math.sin(a) * speed,
            life = 0.25 + love.math.random() * 0.3,
            color = color or Palette.slate,
        }
    end
end

function Particles:update(dt)
    for i = #self.list, 1, -1 do
        local p = self.list[i]
        p.x = p.x + p.dx * dt
        p.y = p.y + p.dy * dt
        p.dx = p.dx * (1 - 3 * dt)
        p.dy = p.dy * (1 - 3 * dt)
        p.life = p.life - dt
        if p.life <= 0 then
            table.remove(self.list, i)
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.list) do
        love.graphics.setColor(p.color)
        love.graphics.rectangle("fill", math.floor(p.x), math.floor(p.y), 1, 1)
    end
end

return Particles
