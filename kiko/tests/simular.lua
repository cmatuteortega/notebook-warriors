-- Simulacion sin ventana: tres bots, el sistema de puntos viejo contra Base x
-- Mult, y la curva de metas del arcade.
--
--     luajit tests/simular.lua                 (desde kiko/; ~300 partidas por caso)
--     luajit tests/simular.lua --partidas 100  (mas rapido)
--     luajit tests/simular.lua --arcade        (ademas, partidas de arcade enteras)
--
-- Los bots:
--
--   azar          una jugada valida cualquiera
--   codicioso     la jugada que mas casa AHORA (casillas, y una especial cuenta
--                 como cinco de mas). No mira el sistema de puntos: es el mismo
--                 en los dos, que es lo que lo hace la vara de medir
--   planificador  mira dos jugadas: puntua cada intercambio con el sistema con
--                 el que juega (el viejo o Base x Mult, con su escalada y su
--                 afinidad) y le suma, rebajada, la mejor jugada que quedaria
--                 despues. La segunda la mira en una COPIA del tablero con otro
--                 azar para lo que cae: sabe lo que queda, no lo que va a caer
--
-- Una "partida" es una ronda de arcade en un bol limpio con los movimientos y
-- colores del escenario, sin mejoras: lo que se compara es el sistema de
-- puntos, no lo que se compra. Azar y codicioso juegan UNA vez y se cuentan
-- con los dos sistemas a la vez (las jugadas no dependen de los puntos); el
-- planificador juega dos veces, una optimizando cada sistema.

package.path = "./?.lua;" .. package.path

local Board = require("src.board")
local Util = require("src.util")
local P = require("src.puntuacion")
local Arcade = require("src.arcade")

local args = {}
do
    local k = 1
    while arg[k] do
        if arg[k] == "--partidas" then args.partidas = tonumber(arg[k + 1]); k = k + 1
        elseif arg[k] == "--arcade" then args.arcade = true
        elseif arg[k] == "--solo-arcade" then args.arcade, args.soloArcade = true, true
        elseif arg[k] == "--ajuste" then args.ajuste = arg[k + 1]; k = k + 1 end
        k = k + 1
    end
end
local N = args.partidas or 300

-- `--ajuste archivo.lua` corre ese archivo con la config de la puntuacion como
-- argumento antes de simular: es como se prueban tablas de formas distintas
-- sin tocar `src/puntuacion_config.lua` (p. ej. `local C = ...; C.GEMA = 3`).
if args.ajuste then assert(loadfile(args.ajuste))(P.C) end

--== Jugar un movimiento, como la pantalla pero sin pantalla ================

local function asentar(b, jugada)
    local puntos = 0
    for _ = 1, 40 do
        local caida = b:gravedad()
        if not caida then break end
        puntos = puntos + (caida.puntos or 0)
        if jugada then P.sumarPastillas(jugada, #caida.recogidos) end
    end
    return puntos
end

-- Devuelve los puntos VIEJOS del movimiento y la jugada para Base x Mult.
local function jugar(b, i, j)
    local jugada = P.nuevaJugada()
    local viejos = 0
    local tipo = b:jugada(i, j)
    b:intercambiar(i, j)
    local preferidas = { j, i }
    if tipo == "combo" then
        local s = b:combo(j, i, 1)
        viejos = viejos + s.puntos
        P.sumarSuceso(jugada, s)
        viejos = viejos + asentar(b, jugada)
        preferidas = nil
    end
    local cascada = 1
    while true do
        local s = b:resolver(preferidas, cascada)
        if not s then break end
        preferidas = nil
        viejos = viejos + s.puntos
        P.sumarSuceso(jugada, s)
        viejos = viejos + asentar(b, jugada)
        cascada = cascada + 1
    end
    b:crecerMoho()
    for _ = 1, 5 do
        if b:hayJugada() then break end
        if not b:barajar() then break end
    end
    return viejos, jugada
end

local function jugadas(b)
    local out = {}
    for i = 1, b.cols * b.rows do
        local c, r = b:cr(i)
        local der = c < b.cols and b:idx(c + 1, r) or nil
        local aba = r < b.rows and b:idx(c, r + 1) or nil
        if der and b:jugada(i, der) then out[#out + 1] = { i, der } end
        if aba and b:jugada(i, aba) then out[#out + 1] = { i, aba } end
    end
    return out
end

-- Una copia del tablero con OTRO azar: lo que cae en la copia no es lo que
-- caera de verdad.
local function copiar(b, semilla)
    local c = setmetatable({}, getmetatable(b))
    for k, v in pairs(b) do
        if type(v) == "table" then
            local t = {}
            for kk, vv in pairs(v) do
                if type(vv) == "table" then
                    local u = {}
                    for a, z in pairs(vv) do u[a] = z end
                    t[kk] = u
                else
                    t[kk] = vv
                end
            end
            c[k] = t
        else
            c[k] = v
        end
    end
    c.rnd = Util.rng(semilla)
    return c
end

--== Como valora cada sistema un intercambio (sin cascada) ==================

local CREAR = Board.PUNTOS.crear

local function valorViejo(b, m)
    if b:jugada(m[1], m[2]) == "combo" then return 1500 end
    local v = 0
    for _, g in ipairs(b:gruposDeIntercambio(m[1], m[2])) do
        v = v + g.n * Board.PUNTOS.galleta + (g.premio and CREAR[g.premio] or 0)
    end
    return v
end

-- Devuelve el valor y el estado de despues.
local function valorNuevo(b, m, estado)
    local r
    if b:jugada(m[1], m[2]) == "combo" then
        local a, c = b.celdas[m[1]], b.celdas[m[2]]
        r = P.preverCombo(a.especial, c.especial, a.color or c.color, estado)
    else
        r = P.prever(b:gruposDeIntercambio(m[1], m[2]), estado)
    end
    return r.total, r.estado
end

local function tamano(b, m)
    if b:jugada(m[1], m[2]) == "combo" then return 40 end
    local n = 0
    for _, g in ipairs(b:gruposDeIntercambio(m[1], m[2])) do n = n + g.n + (g.premio and 5 or 0) end
    return n
end

--== Los bots ==============================================================

local REBAJA = 0.6   -- lo que vale la segunda jugada frente a la primera

local BOTS = {}

function BOTS.azar(b, _, _, rnd)
    local js = jugadas(b)
    return js[Util.dado(rnd, #js)]
end

function BOTS.codicioso(b, _, _, rnd)
    local mejor, elegida = -1, nil
    for _, m in ipairs(jugadas(b)) do
        local t = tamano(b, m) + rnd() * 0.01
        if t > mejor then mejor, elegida = t, m end
    end
    return elegida
end

function BOTS.planificador(b, sistema, estado, rnd)
    local js = jugadas(b)
    -- Solo se miran a dos jugadas las mas prometedoras: todas a dos jugadas
    -- son cuarenta por cuarenta resoluciones por movimiento.
    local cands = {}
    for _, m in ipairs(js) do
        local v, e
        if sistema == "viejo" then v = valorViejo(b, m) else v, e = valorNuevo(b, m, estado) end
        cands[#cands + 1] = { m = m, v = v, e = e }
    end
    table.sort(cands, function(x, y) return x.v > y.v end)
    local mejor, elegida = -math.huge, cands[1] and cands[1].m
    for k = 1, math.min(8, #cands) do
        local c = cands[k]
        local copia = copiar(b, math.floor(rnd() * 1e9))
        jugar(copia, c.m[1], c.m[2])
        local siguiente = 0
        for _, m2 in ipairs(jugadas(copia)) do
            local v2
            if sistema == "viejo" then v2 = valorViejo(copia, m2) else v2 = valorNuevo(copia, m2, c.e) end
            if v2 > siguiente then siguiente = v2 end
        end
        local total = c.v + REBAJA * siguiente
        if total > mejor then mejor, elegida = total, c.m end
    end
    return elegida
end

--== Una ronda =============================================================

-- Juega una ronda y devuelve { viejo, nuevo } (los dos sistemas). `sistema` es
-- el que optimiza el bot (solo lo mira el planificador).
local function ronda(semilla, bot, movs, colores, sistema, mods, opts)
    opts = opts or {}
    local b = Board.nuevo({ semilla = semilla, colores = colores, mods = mods,
                            mascara = opts.mascara, barro = opts.barro, hielo = opts.hielo,
                            moho = opts.moho })
    local rnd = Util.rng(semilla * 7919 + 17)
    local estado = P.nuevoEstado()
    local viejo, nuevo = 0, 0
    for _ = 1, movs do
        if opts.meta and nuevo >= opts.meta then break end
        local m = BOTS[bot](b, sistema, estado, rnd)
        if not m then break end
        local v, jugada = jugar(b, m[1], m[2])
        viejo = viejo + v
        local r = P.calcular(jugada, estado, mods)
        estado = r.estado
        nuevo = nuevo + r.total
    end
    return viejo, nuevo
end

local function stats(lista)
    local s, n = 0, #lista
    for _, v in ipairs(lista) do s = s + v end
    local media = s / n
    local q = 0
    for _, v in ipairs(lista) do q = q + (v - media) ^ 2 end
    local var = q / math.max(1, n - 1)
    return media, var, math.sqrt(var)
end

local function escenario(nombre, movs, colores)
    local res = { viejo = {}, nuevo = {} }
    for _, bot in ipairs({ "azar", "codicioso", "planificador" }) do
        res.viejo[bot], res.nuevo[bot] = {}, {}
    end
    for s = 1, N do
        for _, bot in ipairs({ "azar", "codicioso" }) do
            local v, n = ronda(s, bot, movs, colores)
            table.insert(res.viejo[bot], v)
            table.insert(res.nuevo[bot], n)
        end
        local v = ronda(s, "planificador", movs, colores, "viejo")
        local _, n = ronda(s, "planificador", movs, colores, "nuevo")
        table.insert(res.viejo.planificador, v)
        table.insert(res.nuevo.planificador, n)
    end

    print(string.format("\n### %s (%d movimientos, %d colores, %d partidas por bot)\n",
                        nombre, movs, colores, N))
    print("| Sistema | Bot | Media | Varianza | Desv. tipica | CV |")
    print("|---|---|---:|---:|---:|---:|")
    local resumen = {}
    for _, sis in ipairs({ "viejo", "nuevo" }) do
        resumen[sis] = {}
        for _, bot in ipairs({ "azar", "codicioso", "planificador" }) do
            local media, var, sd = stats(res[sis][bot])
            resumen[sis][bot] = { media = media, sd = sd }
            print(string.format("| %s | %s | %.0f | %.3g | %.0f | %.2f |", sis, bot, media, var, sd, sd / media))
        end
    end
    print("\n| Sistema | planificador / codicioso | codicioso / azar | (plan - codicioso) / desv. tipica |")
    print("|---|---:|---:|---:|")
    for _, sis in ipairs({ "viejo", "nuevo" }) do
        local r = resumen[sis]
        local sdc = math.sqrt((r.planificador.sd ^ 2 + r.codicioso.sd ^ 2) / 2)
        print(string.format("| %s | %.2fx | %.2fx | %.2f |", sis,
            r.planificador.media / r.codicioso.media, r.codicioso.media / r.azar.media,
            (r.planificador.media - r.codicioso.media) / sdc))
    end
    return resumen
end

--== Partidas de arcade enteras ============================================

-- Que carta coge cada bot. El planificador prefiere lo que multiplica y lo que
-- sube formas; los otros dos cogen cualquiera.
local PREFERENCIA = { xmult = 4, mult = 3, base = 2, mecanica = 1 }

local function elegir(bot, oferta, rnd)
    if bot ~= "planificador" then return oferta[Util.dado(rnd, #oferta)] end
    local mejor, elegida = -1, nil
    for _, m in ipairs(oferta) do
        local v = (PREFERENCIA[m.eje] or 0) + (m.id == "mano" and 2.5 or 0) + rnd() * 0.5
        if v > mejor then mejor, elegida = v, m end
    end
    return elegida
end

-- Cuantas rondas pasa un bot con la curva nueva. Solo la meta de puntos: los
-- objetivos de limpiar el bol no son lo que se mide aqui (el bol si se juega,
-- con su barro y sus cubitos, y el color nuevo de la 14 tambien).
local function partidaArcade(semilla, bot)
    local run = Arcade.nuevo(semilla)
    local rnd = Util.rng(semilla * 31 + 5)
    for ronda0 = 1, 30 do
        local def = Arcade.nivel(run)
        local mods = Arcade.mods(run)
        local Levels = require("src.levels")
        local _, puntos = ronda(semilla * 100 + ronda0, bot, def.movimientos, def.colores, "nuevo", mods,
                               { meta = def.objetivo.meta, mascara = Levels.mascara(def),
                                 barro = Levels.barro(def), hielo = Levels.hielo(def),
                                 moho = Levels.moho(def) })
        if puntos < def.objetivo.meta then return ronda0 - 1 end
        Arcade.rondaGanada(run, puntos)
        if #run.oferta > 0 then
            Arcade.tomar(run, elegir(bot, run.oferta, rnd).id)
        else
            Arcade.saltar(run)
        end
    end
    return 30
end

local function arcade()
    local NA = math.max(20, math.floor(N / 5))
    print(string.format("\n### Arcade con la curva nueva (%d partidas por bot, solo meta de puntos)\n", NA))
    print("| Bot | Rondas pasadas (media) | Mediana | Min | Max |")
    print("|---|---:|---:|---:|---:|")
    for _, bot in ipairs({ "azar", "codicioso", "planificador" }) do
        local l = {}
        for s = 1, NA do l[#l + 1] = partidaArcade(s, bot) end
        table.sort(l)
        local media = stats(l)
        print(string.format("| %s | %.1f | %d | %d | %d |", bot, media, l[math.ceil(#l / 2)], l[1], l[#l]))
    end
end

--== Adelante ==============================================================

local t0 = os.clock()
if not args.soloArcade then
    escenario("Ronda 1", 15, 5)
    escenario("Ronda 14 (sexto color)", 32, 6)
end
if args.arcade then arcade() end
print(string.format("\n(%.0f s)", os.clock() - t0))
