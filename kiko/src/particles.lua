-- Migas. Pixeles sueltos que salen de todo lo que se rompe.
--
-- Un pixel y ya esta: ni sprites ni tamanos. Lo que separa un reventon de
-- otro no es la particula, es COMO sale -- un estallido va en todas las
-- direcciones, una chispa de rayo sale disparada a lo largo de la fila, y una
-- miga de galleta cae -- y eso son tres funciones de diez lineas sobre la
-- misma lista.
--
-- Todo esta en pixeles de ARTE y se dibuja dentro del scale() entero, asi que
-- una particula es un cuadrado de 4x4 en pantalla y no un punto: a esta
-- escala, un punto de verdad no se ve.
--
-- El alpha aqui es deliberado y es de los pocos del juego: una particula que
-- desaparece de golpe se lee como un fallo de dibujo, y bajarle el color por
-- la paleta no sirve porque no hay rampa para los seis colores de galleta.

local Particles = {}
Particles.__index = Particles

local GRAVEDAD = 90     -- px de arte por segundo al cuadrado
local ROCE = 2.6

function Particles.nuevo()
    return setmetatable({ lista = {} }, Particles)
end

function Particles:anadir(p)
    -- Tope duro: una cadena de pelotas puede pedir dos mil particulas en un
    -- fotograma y a partir de cierto punto no se distingue ninguna, solo se
    -- nota el tiron.
    if #self.lista >= 900 then return end
    self.lista[#self.lista + 1] = p
end

-- El estallido de una galleta: en todas direcciones y con algo de peso.
function Particles:estallido(x, y, n, color, fuerza)
    fuerza = fuerza or 1
    for k = 1, n do
        local a = (k / n) * math.pi * 2 + love.math.random() * 0.6
        local v = (14 + love.math.random() * 26) * fuerza
        self:anadir({
            x = x, y = y,
            vx = math.cos(a) * v, vy = math.sin(a) * v - 12 * fuerza,
            vida = 0.30 + love.math.random() * 0.35, t = 0,
            color = color, peso = 1,
        })
    end
end

-- La chispa de un rayo: sale a lo LARGO de la fila o la columna, casi sin
-- abrirse. Es lo que hace que un rayo se lea como un rayo y no como otra
-- explosion: las particulas dicen por donde ha pasado.
function Particles:chispa(x, y, dx, dy, n, color)
    for _ = 1, n do
        local v = 60 + love.math.random() * 90
        local desvio = (love.math.random() - 0.5) * 22
        self:anadir({
            x = x, y = y,
            vx = dx * v - dy * desvio, vy = dy * v + dx * desvio,
            vida = 0.18 + love.math.random() * 0.22, t = 0,
            color = color, peso = 0.15,
        })
    end
end

-- Confeti: sube y cae. Solo para el final de nivel, que es lo unico que se
-- celebra.
function Particles:confeti(x, y, n)
    local Palette = require("src.palette")
    for _ = 1, n do
        local fam = Palette.galletas[love.math.random(#Palette.galletas)]
        self:anadir({
            x = x, y = y,
            vx = (love.math.random() - 0.5) * 90,
            vy = -60 - love.math.random() * 90,
            vida = 1.1 + love.math.random() * 0.9, t = 0,
            color = fam.base, peso = 1, roce = 0.4,
        })
    end
end

function Particles:update(dt)
    for i = #self.lista, 1, -1 do
        local p = self.lista[i]
        p.t = p.t + dt
        if p.t >= p.vida then
            self.lista[i] = self.lista[#self.lista]
            self.lista[#self.lista] = nil
        else
            local roce = math.exp(-(p.roce or ROCE) * dt)
            p.vx = p.vx * roce
            p.vy = p.vy * roce + GRAVEDAD * (p.peso or 1) * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
        end
    end
end

function Particles:draw()
    for _, p in ipairs(self.lista) do
        local k = 1 - p.t / p.vida
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], k * 0.95)
        love.graphics.rectangle("fill", math.floor(p.x), math.floor(p.y), 1, 1)
    end
    love.graphics.setColor(1, 1, 1, 1)
end

function Particles:limpiar() self.lista = {} end

return Particles
