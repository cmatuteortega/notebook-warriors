-- La pizarra: donde se ENSENA la cuenta de un movimiento del arcade.
--
-- Vive en el faldon del bol, la franja de acero de debajo del tablero donde va
-- grabado el nombre: esta pegada a donde ha pasado la jugada y no tapa ni una
-- galleta. Tiene tres modos y nunca dos a la vez:
--
--   previa      con el dedo arrastrando, lo que daria el intercambio SIN la
--               cascada ("L / T · 45 x 5"): la cascada no se puede prever, y
--               ensenarla seria mentir la mitad de las veces
--   pendiente   mientras cae la cascada: la Base va subiendo con cada match y
--               el Mult se ve pero no se mueve. El total de la cabecera NO se
--               toca todavia
--   secuencia   con el tablero ya quieto, la cuenta paso a paso: forma y
--               nivel, la Base cuenta hasta su valor, aparece el Mult y cada
--               bonus se suma UNO A UNO con su nombre, "Base x Mult = total",
--               y el total vuela a la cabecera
--
-- Aqui no se calcula nada: el resultado llega hecho de `src/puntuacion.lua`,
-- con cada paso nombrado, y esto solo le pone tiempo encima. La secuencia dura
-- entre un segundo y segundo y medio; con muchos bonus cada paso se acorta, un
-- toque la acelera y un segundo toque la salta.

local Palette    = require("src.palette")
local Puntuacion = require("src.puntuacion")
local Sfx        = require("src.sfx")
local UI         = require("src.ui")

local Pizarra = {}

-- Tiempos de la secuencia. Medidos contra lo mismo que los del tablero: por
-- debajo, el paso no se lee; por encima, el juego se para a mirar su propia
-- cuenta. Con los bonus de serie (escalada y afinidad) la secuencia entera
-- dura ~1,3 s.
local T_NOMBRE = 0.16
local T_BASE   = 0.26
local T_MULT   = 0.12
local T_BONUS  = 0.16      -- lo que dura un bonus si hay pocos...
local T_BONUS_TOTAL = 0.48 -- ...y lo que duran todos juntos como mucho
local T_BONUS_MIN = 0.07
local T_TOTAL  = 0.32
local T_VUELO  = 0.28
local ACELERA  = 4         -- el primer toque

local previa, modo, pend, sec, vuelo

function Pizarra.reset()
    previa, modo, pend, sec, vuelo = nil, nil, nil, nil, nil
end
Pizarra.reset()

--== Entradas ==============================================================

-- `r` es un resultado de `Puntuacion.prever`, `{ invalida = true }` para un
-- intercambio que no casa, o nil para quitarla.
function Pizarra.previa(r)
    previa = r
end

-- Lo que lleva la cascada hasta ahora.
function Pizarra.pendiente(nombre, nivel, base, mult, combo)
    if modo ~= "pendiente" then
        pend = { vista = 0, pop = 0 }
        modo = "pendiente"
    end
    if base > (pend.base or 0) then pend.pop = 1 end
    pend.nombre, pend.nivel, pend.base, pend.mult, pend.combo = nombre, nivel, base, mult, combo
    previa = nil
end

local function paso(tipo, dur, extra)
    local p = extra or {}
    p.tipo, p.dur = tipo, dur
    return p
end

-- Arranca la secuencia de un resultado de `Puntuacion.calcular`.
function Pizarra.secuencia(r)
    local bonus = {}
    for _, p in ipairs(r.pasosMult) do bonus[#bonus + 1] = { fuente = p.fuente, valor = p.valor } end
    for _, p in ipairs(r.pasosX) do bonus[#bonus + 1] = { fuente = p.fuente, valor = p.valor, x = true } end

    -- Con muchos bonus se acelera todo, no solo los bonus: la secuencia tiene
    -- que seguir cabiendo en segundo y medio.
    local nb = #bonus
    local k = nb > 3 and 0.8 or 1
    local tb = math.max(T_BONUS_MIN, math.min(T_BONUS, T_BONUS_TOTAL / math.max(1, nb)))

    local pasos = { paso("nombre", T_NOMBRE * k), paso("base", T_BASE * k), paso("mult", T_MULT * k) }
    for i, b in ipairs(bonus) do pasos[#pasos + 1] = paso("bonus", tb, { bonus = b, n = i }) end
    pasos[#pasos + 1] = paso("total", T_TOTAL * k)
    pasos[#pasos + 1] = paso("vuelo", T_VUELO)

    sec = { r = r, pasos = pasos, i = 1, t = 0, vel = 1,
            baseDesde = (modo == "pendiente" and pend and pend.vista) or 0,
            mult = r.multForma, pop = 0, bonus = nil, esNivel = r.clave ~= "combo" }
    modo, previa, pend = "secuencia", nil, nil
    Sfx.play("toque", 1.0, 0.8)
end

-- Libre = no hay secuencia en marcha. Es lo que espera el director antes de
-- sumar el total y dejar jugar.
function Pizarra.libre() return modo ~= "secuencia" end
function Pizarra.enSecuencia() return modo == "secuencia" end

-- Un toque acelera; el segundo la salta entera.
function Pizarra.saltar()
    if modo ~= "secuencia" then return end
    if sec.vel == 1 then
        sec.vel = ACELERA
    else
        modo, sec, vuelo = nil, nil, nil
    end
end

--== Reloj =================================================================

local function entrar(p)
    if p.tipo == "base" then
        Sfx.play("cuenta", 1.0, 0.6)
    elseif p.tipo == "mult" then
        sec.pop = 1
        Sfx.play("toque", 1.2, 0.8)
    elseif p.tipo == "bonus" then
        local b = p.bonus
        if b.x then sec.mult = sec.mult * b.valor else sec.mult = sec.mult + b.valor end
        sec.bonus, sec.pop = b, 1
        -- Cada bonus una nota mas alta: una lista de cinco se oye subir.
        Sfx.play("toque", 1.25 + p.n * 0.12, 0.9)
    elseif p.tipo == "total" then
        sec.bonus, sec.pop = nil, 1
        Sfx.play("campana", 1.1, 0.8)
    elseif p.tipo == "vuelo" then
        vuelo = { total = sec.r.total, t = 0 }
    end
end

function Pizarra.update(dt)
    if modo == "pendiente" and pend then
        -- La Base pendiente no salta: corre hasta su valor, como el marcador.
        local falta = pend.base - pend.vista
        if falta > 0 then pend.vista = math.min(pend.base, pend.vista + math.max(1, falta * dt * 10)) end
        pend.pop = math.max(0, pend.pop - dt * 6)
    end

    if modo ~= "secuencia" then return end
    sec.pop = math.max(0, sec.pop - dt * 5)
    if sec.i == 1 and sec.t == 0 then entrar(sec.pasos[1]) end
    sec.t = sec.t + dt * sec.vel
    while sec and sec.t >= sec.pasos[sec.i].dur do
        sec.t = sec.t - sec.pasos[sec.i].dur
        sec.i = sec.i + 1
        if sec.i > #sec.pasos then
            modo, sec, vuelo = nil, nil, nil
            return
        end
        entrar(sec.pasos[sec.i])
    end
    if vuelo then vuelo.t = sec.t / sec.pasos[sec.i].dur end
end

--== Dibujo ================================================================

local function ease(k) return 1 - (1 - k) * (1 - k) end

-- Texto con escala. `ancla` es "izq", "der" o "centro", y la escala crece
-- desde ese mismo punto: un nombre pegado al canto izquierdo que creciera desde
-- su centro se saldria del faldon por la izquierda.
local function texto(str, x, y, color, font, escala, ancla)
    escala = escala or 1
    local w, h = font:getWidth(str), font:getHeight()
    local ox = (ancla == "der" and w) or (ancla == "centro" and w / 2) or 0
    love.graphics.push()
    love.graphics.translate(math.floor(x), math.floor(y + h / 2))
    love.graphics.scale(escala, escala)
    UI.texto(str, -ox, -h / 2, color, font)
    love.graphics.pop()
    return w
end

local function nombreCon(nombre, nivel, combo)
    if combo or not nivel then return UI.mayus(nombre) end
    return UI.mayus(string.format("%s · Nv%d", nombre, nivel))
end

-- Dibuja la pizarra dentro de `rect` (virtual). Devuelve true si ha dibujado
-- algo; si no, el faldon ensena su nombre grabado como siempre. `fondo` es
-- para cuando no hay faldon y la pizarra va encima del tablero.
function Pizarra.draw(rect, fondo)
    local activo = (modo == "secuencia" and sec and sec.pasos[sec.i].tipo ~= "vuelo")
                   or modo == "pendiente" or previa
    if not activo then return false end

    if fondo then UI.panel(rect.x, rect.y, rect.w, rect.h) end
    local fm, fs = Fonts.medium, Fonts.small
    if rect.h < fm:getHeight() then fm = fs end
    local izq, der = rect.x + 20, rect.x + rect.w - 20
    local yM = rect.y + math.floor((rect.h - fm:getHeight()) / 2)
    local yS = rect.y + math.floor((rect.h - fs:getHeight()) / 2)

    if modo == "secuencia" then
        local p = sec.pasos[sec.i]
        local k = math.min(1, sec.t / p.dur)
        local r = sec.r
        if p.tipo == "total" then
            -- "Base x Mult = total", centrado y con el total en oro dando el golpe.
            local cuenta = string.format("%d × %s = ", r.base, Puntuacion.fmt(sec.mult))
            local tot = tostring(r.total)
            local ancho = fm:getWidth(cuenta) + fm:getWidth(tot)
            local x = rect.x + rect.w / 2 - ancho / 2
            texto(cuenta, x, yM, Palette.ink, fm)
            texto(tot, x + fm:getWidth(cuenta), yM, Palette.gold, fm, 1 + 0.5 * sec.pop)
            return true
        end

        local escalaNombre = p.tipo == "nombre" and (1.35 - 0.35 * ease(k)) or 1
        texto(nombreCon(r.nombre, r.nivel, not sec.esNivel), izq, yS, Palette.ink, fs, escalaNombre)
        if p.tipo == "nombre" then return true end

        -- La derecha se escribe de derecha a izquierda: Mult y luego Base.
        local base = p.tipo == "base"
            and math.floor(sec.baseDesde + (r.base - sec.baseDesde) * ease(k)) or r.base
        local x = der
        if p.tipo ~= "base" then
            local m = Puntuacion.fmt(sec.mult)
            x = x - texto(m, x, yM, Palette.gold, fm, 1 + 0.4 * sec.pop, "der")
            x = x - texto(" × ", x, yM, Palette.ink, fm, 1, "der")
        end
        texto(tostring(base), x, yM, Palette.ink, fm, p.tipo == "base" and 1.1 or 1, "der")

        -- El bonus que se acaba de sumar, con su fuente, colgando del faldon.
        if sec.bonus then
            local b = sec.bonus
            local etiqueta = b.x and string.format("×%s %s", Puntuacion.fmt(b.valor), b.fuente)
                                  or string.format("+%s %s", Puntuacion.fmt(b.valor), b.fuente)
            texto(UI.mayus(etiqueta), rect.x + rect.w / 2, rect.y + rect.h + 16,
                  b.x and Palette.red or Palette.gold, fs, 1 + 0.3 * sec.pop, "centro")
        end
        return true
    end

    if modo == "pendiente" then
        texto(nombreCon(pend.nombre, pend.nivel, pend.combo), izq, yS, Palette.ink, fs)
        local x = der
        x = x - texto(Puntuacion.fmt(pend.mult), x, yM, Palette.gold, fm, 1, "der")
        x = x - texto(" × ", x, yM, Palette.ink, fm, 1, "der")
        texto(tostring(math.floor(pend.vista)), x, yM, Palette.ink, fm, 1 + 0.2 * pend.pop, "der")
        return true
    end

    -- La previa: el nombre apagado y la cuenta en tinta, sin oro. El oro es
    -- de lo que se cobra, y esto todavia es una promesa.
    if previa.invalida then
        texto("NO CASA", rect.x + rect.w / 2, yS, Palette.dim, fs, 1, "centro")
        return true
    end
    texto(nombreCon(previa.nombre, previa.nivel, previa.clave == "combo"), izq, yS, Palette.ink, fs)
    local cuenta = string.format("%d × %s", previa.base, Puntuacion.fmt(previa.mult * previa.xmult))
    texto(cuenta, der, yM, Palette.ink, fm, 1, "der")
    return true
end

-- El total volando a la cabecera. Va DESPUES de la cabecera en el dibujo, por
-- encima de todo. `desde` es el centro del faldon y `hasta` la cifra de puntos.
function Pizarra.drawVuelo(dx, dy, hx, hy)
    if not vuelo then return end
    local k = math.min(1, vuelo.t)
    local e = k * k
    local str = "+" .. vuelo.total
    local font = Fonts.large
    local w = font:getWidth(str)
    local x = dx + (hx - w / 2 - dx) * e
    local y = dy + (hy - dy) * e - math.sin(k * math.pi) * 60
    texto(str, x, y - font:getHeight() / 2, Palette.gold, font, 1.2 - 0.5 * k, "centro")
end

return Pizarra
