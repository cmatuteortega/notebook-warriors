-- Utilidades sin love. Todo lo que hay aqui lo puede llamar `src/board.lua`,
-- que es codigo puro y se prueba sin ventana (`tests/test_board.lua`).

local Util = {}

function Util.clamp(v, lo, hi)
    if v < lo then return lo elseif v > hi then return hi end
    return v
end

function Util.lerp(a, b, t) return a + (b - a) * t end

function Util.round(v) return math.floor(v + 0.5) end

function Util.sign(v) return v < 0 and -1 or (v > 0 and 1 or 0) end

-- Generador congruencial propio, y no `love.math.random`, por dos razones: la
-- logica del tablero no puede tocar love (es lo que la hace probable sin
-- ventana) y una partida con la misma semilla tiene que dar EXACTAMENTE el
-- mismo reparto en movil y en escritorio. Los tres numeros son los de
-- Numerical Recipes: periodo 2^32 y productos que caben en un double.
function Util.rng(semilla)
    local estado = math.floor(semilla or 0) % 4294967296
    return function()
        estado = (1664525 * estado + 1013904223) % 4294967296
        return estado / 4294967296
    end
end

-- Un entero en [1, n] a partir de un generador.
function Util.dado(rnd, n) return math.floor(rnd() * n) + 1 end

-- Baraja en el sitio (Fisher-Yates) con el generador que se le pase.
function Util.barajar(lista, rnd)
    for i = #lista, 2, -1 do
        local j = Util.dado(rnd, i)
        lista[i], lista[j] = lista[j], lista[i]
    end
    return lista
end

return Util
