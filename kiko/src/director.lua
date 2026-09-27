-- El director: una corrutina que lleva el tiempo de las animaciones.
--
-- Una cascada de match-3 es una secuencia larga y con esperas -- rompe, espera
-- a que se apague, deja caer, espera a que aterrice, vuelve a mirar -- y
-- escrita con maquinas de estados sale un plato de espaguetis donde cada
-- estado tiene que acordarse de a donde iba. Escrita como corrutina se lee de
-- arriba abajo, que es como pasa:
--
--     Director.lanzar(function()
--         romper(suceso)
--         Director.esperar(0.25)
--         caer()
--         Director.esperar(0.30)
--     end)
--
-- Mientras hay corrutina viva el tablero esta OCUPADO y no admite dedos. Eso
-- no es un efecto secundario, es la razon por la que esto existe: un dedo a
-- media cascada es la forma clasica de que un match-3 se descuadre.

local Director = {}

local co, espera, condicion = nil, 0, nil

function Director.reset()
    co, espera, condicion = nil, 0, nil
end

function Director.ocupado()
    return co ~= nil
end

local function reanudar()
    local ok, valor = coroutine.resume(co)
    if not ok then
        -- Un error dentro de la corrutina no puede tirar el juego: se imprime
        -- (en movil se lee en la consola, tres dedos) y el tablero vuelve a
        -- admitir dedos, que es preferible a quedarse tieso para siempre.
        print("[director] " .. tostring(valor))
        co = nil
        return
    end
    if coroutine.status(co) == "dead" then
        co = nil
        return
    end
    if type(valor) == "number" then
        espera, condicion = valor, nil
    elseif type(valor) == "function" then
        espera, condicion = 0, valor
    else
        espera, condicion = 0, nil
    end
end

function Director.lanzar(fn)
    assert(not co, "el director ya tiene faena")
    co = coroutine.create(fn)
    espera, condicion = 0, nil
    reanudar()
end

-- Espera dentro de la corrutina. Un cero es "hasta el fotograma siguiente",
-- que es lo que hace falta para que lo que se acaba de dibujar se vea.
function Director.esperar(t)
    coroutine.yield(t or 0)
end

-- Espera a que algo sea cierto. Se usa para esperar a los tweens de flux, que
-- no saben avisar.
function Director.hasta(fn)
    coroutine.yield(fn)
end

function Director.update(dt)
    if not co then return end
    if condicion then
        if condicion() then
            condicion = nil
            reanudar()
        end
        return
    end
    if espera > 0 then
        espera = espera - dt
        if espera > 0 then return end
    end
    reanudar()
end

-- Cortar por lo sano. Solo al salir de la pantalla: dejar una corrutina viva
-- al cambiar de nivel la despierta encima del tablero siguiente.
function Director.cortar()
    co, espera, condicion = nil, 0, nil
end

return Director
