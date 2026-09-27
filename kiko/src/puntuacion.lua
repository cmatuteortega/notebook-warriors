-- La puntuacion del arcade: Base x Mult.
--
--     Puntos = (Base de gemas + Base de la forma) x (Mult de la forma + Mult de
--              mejoras) x xMult de mejoras
--
-- Un MOVIMIENTO es la jugada del dedo y toda la cascada que la sigue, y se
-- cobra UNA vez, cuando el tablero se ha quedado quieto. La jugada del dedo
-- fija la forma y el Mult; la cascada solo suma Base (sus galletas y la base de
-- las formas que case), y no mueve el Mult salvo con las mejoras que lo dicen
-- (Cadena, Remanso).
--
-- No hay Mult de estado de serie: sin mejoras, cada jugada vale lo que es. La
-- ronda si recuerda algo de la jugada anterior (su color, su forma), pero eso
-- solo lo cobran las mejoras que lo piden: Obsesion (afinidad de color),
-- Lealtad, Monocromo, Preparacion, Crescendo y Molde. Hubo una ESCALADA y una
-- afinidad de serie y se quitaron: medido, la escalada inflaba los puntos sin
-- separar a quien planifica de quien no (ver `docs/scoring-redesign.md`,
-- seccion 10).
--
-- El orden de aplicacion es fijo y es el mismo que ensena la secuencia de la
-- pantalla, paso a paso:
--
--   1. Base  = forma(s) de la jugada + galletas + bonus de color + estorbos
--              + pastillas + formas casadas en la cascada
--   2. Mult  = mult de la forma (+ doble, + doblete)
--              + afinidad (Obsesion, ya actualizada con ESTA jugada)
--              + preparacion + regalo + cadena + remanso
--   3. xMult = fusion, crescendo, monocromo, molde (de una en una, en ese orden)
--   Total = floor(Base x Mult x xMult)
--
-- Este modulo es PURO: no toca love, ni el tablero, ni la pantalla. Lo que le
-- llega son tablas con lo que ha pasado (`sumarSuceso` las rellena a partir de
-- los sucesos de `src/board.lua`) y lo que devuelve es el resultado con cada
-- paso nombrado y el estado siguiente, sin cambiar el que le pasan. Es lo que
-- deja probarlo sin ventana (`tests/test_puntuacion.lua`) y simular partidas
-- enteras (`tests/simular.lua`).

local C = require("src.puntuacion_config")

local P = {}
P.C = C

-- El premio que da `Board.premio` a un grupo dice que forma es, y se lee de
-- ahi para no tener la tabla de formas escrita dos veces.
local DE_PREMIO = { estrella = "cuadrado", pelota = "cinco", envuelta = "lt",
                    rayaH = "cuatro", rayaV = "cuatro" }

function P.formaDePremio(premio)
    return DE_PREMIO[premio] or "tres"
end

-- La clave de la pareja de un combo, sin importar el orden ni la direccion de
-- la raya: "raya+raya", "especial+pelota", ...
function P.clavePareja(ea, eb)
    local function norma(e)
        if e == "rayaH" or e == "rayaV" then return "raya" end
        return e or "galleta"
    end
    local a, b = norma(ea), norma(eb)
    if a == "pelota" and b ~= "pelota" and b ~= "galleta" then b = "especial" end
    if b == "pelota" and a ~= "pelota" and a ~= "galleta" then a = "especial" end
    if a > b then a, b = b, a end
    return a .. "+" .. b
end

--== Formas ================================================================

local function nivelDe(clave, mods)
    return 1 + ((mods and mods.niveles and mods.niveles[clave]) or 0)
end

-- Una forma con su nivel: { clave, nombre, corto, nivel, base, mult, rango }.
function P.forma(clave, mods)
    local def = C.FORMAS[clave]
    local nivel = nivelDe(clave, mods)
    return {
        clave = clave, nombre = def.nombre, corto = def.corto, nivel = nivel,
        base = def.base + (nivel - 1) * def.subir.base,
        mult = def.mult + (nivel - 1) * def.subir.mult,
        rango = def.rango,
    }
end

--== Estado y jugada =======================================================

-- Lo que recuerda una ronda entre movimiento y movimiento. Se crea al empezar
-- cada ronda: nada pasa de una ronda a otra.
--   rangoPrevio  el rango de la forma de la jugada anterior (Crescendo)
--   tresPrevio   si la jugada anterior fue una linea de tres (Preparacion)
--   colorPrevio, eslabones  el color de la anterior y cuantas seguidas lo
--                repiten (Obsesion, Monocromo)
--   afinidad     el Mult de Obsesion acumulado; cero sin la mejora
--   usos         cuantas veces se ha hecho cada forma (Molde)
function P.nuevoEstado()
    return { rangoPrevio = nil, tresPrevio = false, afinidad = 0, eslabones = 0,
             colorPrevio = nil, usos = {} }
end

local function copiarEstado(e)
    local usos = {}
    for k, v in pairs(e.usos or {}) do usos[k] = v end
    return { rangoPrevio = e.rangoPrevio, tresPrevio = e.tresPrevio, afinidad = e.afinidad,
             eslabones = e.eslabones, colorPrevio = e.colorPrevio, usos = usos }
end

-- Un movimiento a medio contar.
--   forma   { tipo = "normal", formas = {clave...}, color, crea }
--         | { tipo = "combo", pareja = clave, color }
--   gemas   [color] = n; `sinColor` las que no tienen (la pelota)
--   cascada lista de claves de forma casadas despues de la jugada
--   pasos   cuantas resoluciones de cascada ha habido
function P.nuevaJugada()
    return { forma = nil, gemas = {}, sinColor = 0, estorbos = 0, pastillas = 0,
             cascada = {}, pasos = 0 }
end

-- Mete en la jugada lo que ha pasado en un suceso del tablero (`resolver` o
-- `combo`). El PRIMER suceso con forma es la jugada del dedo; los que vienen
-- despues son la cascada.
function P.sumarSuceso(j, s)
    for _, onda in ipairs(s.ondas or {}) do
        for _, c in ipairs(onda.celdas or {}) do
            if c.color then
                j.gemas[c.color] = (j.gemas[c.color] or 0) + 1
            else
                j.sinColor = j.sinColor + 1
            end
        end
        j.estorbos = j.estorbos + #(onda.barro or {}) + #(onda.hielo or {})
                     + #(onda.moho or {})
    end

    if s.combo then
        if not j.forma then
            j.forma = { tipo = "combo", color = s.color,
                        pareja = P.clavePareja(s.pareja and s.pareja[1], s.pareja and s.pareja[2]) }
        end
    elseif s.formas then
        if not j.forma then
            local formas = {}
            for _, f in ipairs(s.formas) do formas[#formas + 1] = P.formaDePremio(f.premio) end
            j.forma = { tipo = "normal", formas = formas, color = s.colorPrincipal,
                        crea = #(s.creadas or {}) > 0 }
        else
            j.pasos = j.pasos + 1
            for _, f in ipairs(s.formas) do j.cascada[#j.cascada + 1] = P.formaDePremio(f.premio) end
        end
    end
end

-- Las pastillas que llegan al suelo durante el movimiento.
function P.sumarPastillas(j, n)
    j.pastillas = j.pastillas + (n or 0)
end

--== El calculo ============================================================

-- La forma de la jugada del dedo: nombre, nivel, base, mult y rango, ya con el
-- doble match resuelto.
local function formaDeJugada(forma, mods)
    if forma.tipo == "combo" then
        local def = C.COMBOS[forma.pareja] or C.COMBO_DEFECTO
        return { clave = "combo", nombre = def.nombre, nivel = 1, base = def.base,
                 mult = def.mult, rango = C.RANGO_COMBO, doble = false }
    end
    local base, mayor = 0, nil
    for _, clave in ipairs(forma.formas) do
        local f = P.forma(clave, mods)
        base = base + f.base
        if not mayor or f.rango > mayor.rango or (f.rango == mayor.rango and f.mult > mayor.mult) then
            mayor = f
        end
    end
    local doble = #forma.formas >= 2
    local nombre = mayor.nombre
    if doble then
        local cortos = {}
        for _, clave in ipairs(forma.formas) do cortos[#cortos + 1] = C.FORMAS[clave].corto end
        nombre = "Doble " .. table.concat(cortos, "+")
    end
    return { clave = mayor.clave, nombre = nombre, nivel = mayor.nivel, base = base,
             mult = mayor.mult, rango = mayor.rango, doble = doble }
end

-- El estado despues de esta jugada. Se actualiza ANTES de cobrar: la jugada
-- que alarga la racha de color ya cobra con ella.
local function avanzar(estado, forma, f, mods)
    local e = copiarEstado(estado)

    -- Afinidad de color. Los eslabones se cuentan siempre (Monocromo los mira);
    -- el Mult solo lo da Obsesion. Una jugada sin color (dos pelotas) no toca
    -- nada.
    local color = forma.color
    if color then
        local obs = mods.obsesion or 0
        if color == e.colorPrevio then
            e.eslabones = e.eslabones + 1
            e.afinidad = math.min(e.afinidad + C.OBSESION_SUBE * obs, C.OBSESION_TOPE * obs)
        else
            e.eslabones = 0
            -- Lealtad: cambiar de color deja la mitad en vez de nada.
            e.afinidad = (mods.lealtad or 0) > 0 and e.afinidad * C.LEALTAD or 0
        end
        e.colorPrevio = color
    end

    e.rangoPrevio = f.rango
    e.tresPrevio = (forma.tipo == "normal" and f.clave == "tres" and not f.doble)
    -- La cuenta de formas de la ronda, para Molde.
    e.usos[f.clave] = (e.usos[f.clave] or 0) + 1
    return e
end

-- Solo la Base, sin tocar el estado. Es lo que la pantalla ensena como
-- "pendiente" mientras la cascada sigue cayendo.
function P.base(j, mods)
    mods = mods or {}
    if not j.forma then
        -- Todavia no hay jugada (no deberia pasar): lo roto cuenta igual.
        local n = j.sinColor
        for _, k in pairs(j.gemas) do n = n + k end
        return n * C.GEMA
    end
    local total = 0
    for _, paso in ipairs(P.pasosBase(j, mods)) do total = total + paso.valor end
    return total
end

-- Los sumandos de la Base, en orden y con nombre.
function P.pasosBase(j, mods)
    mods = mods or {}
    local f = formaDeJugada(j.forma, mods)
    local pasos = { { fuente = f.nombre, valor = f.base } }

    local n = j.sinColor
    for _, k in pairs(j.gemas) do n = n + k end
    if n > 0 then pasos[#pasos + 1] = { fuente = string.format("%d galletas", n), valor = n * C.GEMA } end

    local colores = mods.colores or {}
    for color = 1, 6 do
        local nivel = colores[color] or 0
        local cuantas = j.gemas[color] or 0
        if nivel > 0 and cuantas > 0 then
            pasos[#pasos + 1] = { fuente = "color", color = color,
                                  valor = cuantas * C.GEMA_COLOR * nivel }
        end
    end

    if j.estorbos > 0 then
        pasos[#pasos + 1] = { fuente = "Limpieza",
                              valor = j.estorbos * (C.ESTORBO + C.FREGONA * (mods.fregona or 0)) }
    end
    if j.pastillas > 0 then
        pasos[#pasos + 1] = { fuente = "Pastilla", valor = j.pastillas * C.PASTILLA }
    end
    if #j.cascada > 0 then
        local b = 0
        for _, clave in ipairs(j.cascada) do b = b + P.forma(clave, mods).base end
        pasos[#pasos + 1] = { fuente = "Cascada", valor = b }
    end
    return pasos
end

-- El movimiento entero. `prevision` es para cuando la cascada no ha acabado o
-- no se conoce (la cuenta pendiente, el planificador del simulador): las
-- mejoras que dependen de ella (Cadena, Remanso) no se cuentan.
--
-- Devuelve
--   { nombre, nivel, clave, base, pasosBase, multForma, mult, pasosMult,
--     xmult, pasosX, total, estado }
-- donde cada paso es { fuente, valor } y el estado es el SIGUIENTE (el que se
-- pasa no se toca).
function P.calcular(j, estado, mods, prevision)
    mods = mods or {}
    estado = estado or P.nuevoEstado()
    if not j.forma then
        local base = P.base(j, mods)
        return { nombre = "", nivel = 1, clave = nil, base = base, pasosBase = {},
                 multForma = 1, mult = 1, pasosMult = {}, xmult = 1, pasosX = {},
                 total = base, estado = estado }
    end

    local f = formaDeJugada(j.forma, mods)
    local nuevo = avanzar(estado, j.forma, f, mods)

    -- 1. Base
    local pasosBase = P.pasosBase(j, mods)
    local base = 0
    for _, p in ipairs(pasosBase) do base = base + p.valor end

    -- 2. Mult
    local pasosMult = {}
    local function suma(fuente, valor)
        if valor and valor > 0 then pasosMult[#pasosMult + 1] = { fuente = fuente, valor = valor } end
    end
    if f.doble then
        suma("Doble", C.DOBLE_MULT)
        suma("Doblete", C.DOBLETE * (mods.doblete or 0))
    end
    suma("Afinidad", nuevo.afinidad)
    if (mods.preparacion or 0) > 0 and estado.tresPrevio and f.rango >= 2 then
        suma("Preparacion", C.PREPARACION * mods.preparacion)
    end
    if j.forma.crea then suma("Regalo", C.REGALO * (mods.regalo or 0)) end
    if not prevision then
        suma("Cadena", math.min(C.CADENA_TOPE, C.CADENA * (mods.cadena or 0) * j.pasos))
        if j.pasos == 0 then suma("Remanso", C.REMANSO * (mods.remanso or 0)) end
    end
    local mult = f.mult
    for _, p in ipairs(pasosMult) do mult = mult + p.valor end

    -- 3. xMult
    local pasosX = {}
    if j.forma.tipo == "combo" and (mods.fusion or 0) > 0 then
        pasosX[#pasosX + 1] = { fuente = "Fusion", valor = 1 + C.FUSION * mods.fusion }
    end
    if (mods.crescendo or 0) > 0 and estado.rangoPrevio and f.rango > estado.rangoPrevio then
        pasosX[#pasosX + 1] = { fuente = "Crescendo", valor = C.CRESCENDO }
    end
    if (mods.monocromo or 0) > 0 and nuevo.eslabones >= C.MONOCROMO_ESLABONES then
        pasosX[#pasosX + 1] = { fuente = "Monocromo", valor = C.MONOCROMO }
    end
    if (mods.molde or 0) > 0 and f.clave ~= "tres" then
        local mias, masUsada = nuevo.usos[f.clave] or 0, 0
        for clave, n in pairs(nuevo.usos) do
            if clave ~= "tres" and n > masUsada then masUsada = n end
        end
        if mias >= C.MOLDE_MINIMO and mias >= masUsada then
            pasosX[#pasosX + 1] = { fuente = "Molde", valor = C.MOLDE }
        end
    end
    local xmult = 1
    for _, p in ipairs(pasosX) do xmult = xmult * p.valor end

    return {
        nombre = f.nombre, nivel = f.nivel, clave = f.clave,
        base = base, pasosBase = pasosBase,
        multForma = f.mult, mult = mult, pasosMult = pasosMult,
        xmult = xmult, pasosX = pasosX,
        total = math.floor(base * mult * xmult),
        estado = nuevo,
    }
end

-- La jugada que saldria de intercambiar dos casillas, sin cascada: las formas
-- que se casarian y las galletas que tienen. `grupos` son los de
-- `Board:grupos()` con el intercambio hecho, cada uno con su `premio`.
function P.prever(grupos, estado, mods)
    local j = P.nuevaJugada()
    local formas, mayor, color = {}, 0, nil
    for _, g in ipairs(grupos) do
        formas[#formas + 1] = P.formaDePremio(g.premio)
        -- La casilla donde nace la especial no se rompe: se queda.
        j.gemas[g.color] = (j.gemas[g.color] or 0) + g.n - (g.premio and 1 or 0)
        if g.n > mayor then mayor, color = g.n, g.color end
    end
    local crea = false
    for _, g in ipairs(grupos) do if g.premio then crea = true end end
    j.forma = { tipo = "normal", formas = formas, color = color, crea = crea }
    return P.calcular(j, estado, mods, true)
end

-- Lo mismo para un combo: se sabe la pareja y poco mas.
function P.preverCombo(ea, eb, color, estado, mods)
    local j = P.nuevaJugada()
    j.forma = { tipo = "combo", pareja = P.clavePareja(ea, eb), color = color }
    return P.calcular(j, estado, mods, true)
end

-- Como se escribe un numero de Mult: sin decimales si no los tiene.
function P.fmt(v)
    if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) end
    return string.format("%.1f", v)
end

return P
