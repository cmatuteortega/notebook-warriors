-- Pruebas de la puntuacion del arcade (Base x Mult). Sin ventana:
--
--     luajit tests/test_puntuacion.lua        (desde la carpeta kiko/)
--
-- Cubren las formas y sus niveles, el doble match, los combos, que sin
-- mejoras no hay Mult de estado, la afinidad de color (Obsesion), la cascada
-- (que solo suma Base), el orden de aplicacion y las mejoras. Al final, un par de pruebas contra el
-- tablero de verdad: que un suceso de `Board` se traduce a la forma correcta.

package.path = "./?.lua;" .. package.path

local P = require("src.puntuacion")
local C = require("src.puntuacion_config")
local Board = require("src.board")
local Arcade = require("src.arcade")

local fallos, pruebas = 0, 0

local function prueba(nombre, fn)
    pruebas = pruebas + 1
    local ok, err = pcall(fn)
    if not ok then
        fallos = fallos + 1
        print("FALLA  " .. nombre .. "\n       " .. tostring(err))
    end
end

local function igual(a, b, que)
    if type(a) == "number" and type(b) == "number" then
        if math.abs(a - b) > 1e-9 then
            error(string.format("%s: esperaba %s, salio %s", que or "valor", tostring(b), tostring(a)), 2)
        end
    elseif a ~= b then
        error(string.format("%s: esperaba %s, salio %s", que or "valor", tostring(b), tostring(a)), 2)
    end
end

-- Una jugada normal con estas formas, estas galletas de un color y nada mas.
local function jugada(formas, color, gemas, extra)
    local j = P.nuevaJugada()
    j.forma = { tipo = "normal", formas = formas, color = color, crea = extra and extra.crea }
    if gemas and gemas > 0 then j.gemas[color or 1] = gemas end
    if extra then
        j.cascada = extra.cascada or {}
        j.pasos = extra.pasos or #j.cascada
        j.estorbos = extra.estorbos or 0
        j.pastillas = extra.pastillas or 0
    end
    return j
end

-- Juega una serie de jugadas y devuelve los resultados.
local function serie(jugadas, mods)
    local e, out = P.nuevoEstado(), {}
    for _, j in ipairs(jugadas) do
        local r = P.calcular(j, e, mods)
        out[#out + 1] = r
        e = r.estado
    end
    return out, e
end

local function paso(lista, fuente)
    for _, p in ipairs(lista) do if p.fuente == fuente then return p.valor end end
    return nil
end

--== Formas ================================================================

prueba("tabla de formas de serie", function()
    for clave, esperado in pairs({ tres = { 15, 1 }, cuadrado = { 30, 3 }, cuatro = { 40, 3 },
                                   lt = { 50, 4 }, cinco = { 80, 6 } }) do
        local f = P.forma(clave)
        igual(f.base, esperado[1], clave .. " base")
        igual(f.mult, esperado[2], clave .. " mult")
        igual(f.nivel, 1, clave .. " nivel")
    end
end)

prueba("las formas suben de nivel", function()
    local f = P.forma("cuatro", { niveles = { cuatro = 2 } })
    igual(f.nivel, 3); igual(f.base, 60); igual(f.mult, 5)
    local g = P.forma("cinco", { niveles = { cinco = 1 } })
    igual(g.base, 100); igual(g.mult, 8)
    local r = P.calcular(jugada({ "lt" }), nil, { niveles = { lt = 1 } })
    igual(r.nombre, "L / T"); igual(r.nivel, 2); igual(r.multForma, 5)
end)

prueba("linea de 3 pelada: (15 + 3 galletas x 2) x 1", function()
    local r = P.calcular(jugada({ "tres" }, 1, 3))
    igual(r.base, 21, "base"); igual(r.mult, 1, "mult"); igual(r.total, 21, "total")
end)

prueba("sin mejoras no hay Mult de estado", function()
    -- cinco jugadas seguidas del mismo color, cada vez mejores: el Mult es el
    -- de la forma y nada mas
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "cuatro" }, 1), jugada({ "lt" }, 1),
                       jugada({ "cinco" }, 1), jugada({ "cinco" }, 1) })
    for k, r in ipairs(rs) do
        igual(#r.pasosMult, 0, "jugada " .. k .. " pasos")
        igual(#r.pasosX, 0, "jugada " .. k .. " xMult")
        igual(r.mult, r.multForma, "jugada " .. k .. " mult")
    end
end)

prueba("premio del tablero -> forma", function()
    igual(P.formaDePremio(nil), "tres")
    igual(P.formaDePremio("rayaH"), "cuatro")
    igual(P.formaDePremio("rayaV"), "cuatro")
    igual(P.formaDePremio("envuelta"), "lt")
    igual(P.formaDePremio("pelota"), "cinco")
    igual(P.formaDePremio("estrella"), "cuadrado")
end)

prueba("doble match: suma bases y +2 al mult de la forma mayor", function()
    local r = P.calcular(jugada({ "tres", "lt" }))
    igual(r.base, 65, "base")
    igual(r.multForma, 4, "mult de forma")
    igual(paso(r.pasosMult, "Doble"), 2, "doble")
    igual(r.mult, 6, "mult")
    igual(r.nombre, "Doble 3+L")
    local d = P.calcular(jugada({ "tres", "lt" }), nil, { doblete = 1 })
    igual(paso(d.pasosMult, "Doblete"), 2, "doblete")
end)

prueba("combos: clave de pareja y fila de la tabla", function()
    igual(P.clavePareja("rayaV", "rayaH"), "raya+raya")
    igual(P.clavePareja("envuelta", "rayaH"), "envuelta+raya")
    igual(P.clavePareja("rayaH", "envuelta"), "envuelta+raya")
    igual(P.clavePareja("pelota", nil), "galleta+pelota")
    igual(P.clavePareja("rayaH", "pelota"), "especial+pelota")
    igual(P.clavePareja("pelota", "pelota"), "pelota+pelota")
    local r = P.preverCombo("envuelta", "envuelta", 2)
    igual(r.base, C.COMBOS["envuelta+envuelta"].base)
    igual(r.multForma, C.COMBOS["envuelta+envuelta"].mult)
end)

--== Afinidad (Obsesion) ===================================================

prueba("afinidad: sin Obsesion no paga, pero cuenta los eslabones", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1), jugada({ "tres" }, 1) })
    igual(rs[3].estado.afinidad, 0); igual(rs[3].estado.eslabones, 2)
    igual(paso(rs[3].pasosMult, "Afinidad"), nil)
end)

prueba("afinidad: +n por jugada seguida del mismo color, cero al cambiar", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1), jugada({ "tres" }, 1),
                       jugada({ "tres" }, 2) }, { obsesion = 1 })
    igual(rs[1].estado.afinidad, 0); igual(rs[2].estado.afinidad, 1)
    igual(rs[3].estado.afinidad, 2); igual(rs[4].estado.afinidad, 0)
    igual(rs[3].mult, 3, "mult con afinidad")
    local dos = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1) }, { obsesion = 2 })
    igual(dos[2].estado.afinidad, 2, "nivel 2")
end)

prueba("afinidad: tope 4 por nivel", function()
    local js = {}
    for k = 1, 12 do js[k] = jugada({ "tres" }, 4) end
    local _, e = serie(js, { obsesion = 1 })
    igual(e.afinidad, C.OBSESION_TOPE)
    local _, e3 = serie(js, { obsesion = 3 })
    igual(e3.afinidad, 3 * C.OBSESION_TOPE)
end)

prueba("afinidad: una jugada sin color no la toca", function()
    local sin = P.nuevaJugada(); sin.forma = { tipo = "combo", pareja = "pelota+pelota" }
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1), sin, jugada({ "tres" }, 1) },
                     { obsesion = 1 })
    igual(rs[3].estado.afinidad, 1); igual(rs[4].estado.afinidad, 2)
end)

prueba("Lealtad: cambiar de color deja la mitad", function()
    local js = { jugada({ "tres" }, 1), jugada({ "tres" }, 1), jugada({ "tres" }, 1),
                 jugada({ "tres" }, 2) }
    local rs = serie(js, { obsesion = 1, lealtad = 1 })
    igual(rs[4].estado.afinidad, 1)
    igual(serie(js, { obsesion = 1 })[4].estado.afinidad, 0, "sin lealtad")
end)

--== Cascada ===============================================================

prueba("cascada: suma Base y no Mult", function()
    local sola = P.calcular(jugada({ "tres" }, 1, 3))
    local con = P.calcular(jugada({ "tres" }, 1, 9, { cascada = { "cuatro", "tres" } }))
    igual(con.mult, sola.mult, "mult sin cambiar")
    igual(con.base, 15 + 9 * C.GEMA + 40 + 15, "base con cascada")
    igual(paso(con.pasosBase, "Cascada"), 55)
end)

prueba("cascada: la base de sus formas usa sus niveles", function()
    local r = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "cuatro" } }), nil,
                         { niveles = { cuatro = 1 } })
    igual(paso(r.pasosBase, "Cascada"), 50)
end)

prueba("Cadena: +0,25 por paso y nivel, tope 2", function()
    local r = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "tres", "tres" } }), nil, { cadena = 1 })
    igual(paso(r.pasosMult, "Cadena"), 0.5)
    local js = {}
    for k = 1, 12 do js[k] = "tres" end
    local t = P.calcular(jugada({ "tres" }, 1, 0, { cascada = js }), nil, { cadena = 2 })
    igual(paso(t.pasosMult, "Cadena"), 2)
end)

prueba("Remanso: solo sin cascada, y nunca en la cuenta pendiente", function()
    local r = P.calcular(jugada({ "tres" }, 1), nil, { remanso = 1 })
    igual(paso(r.pasosMult, "Remanso"), 2)
    local c = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "tres" } }), nil, { remanso = 1 })
    igual(paso(c.pasosMult, "Remanso"), nil)
    local pv = P.calcular(jugada({ "tres" }, 1), nil, { remanso = 1 }, true)
    igual(paso(pv.pasosMult, "Remanso"), nil)
end)

prueba("estorbos, pastillas y colores suman Base", function()
    local r = P.calcular(jugada({ "tres" }, 2, 3, { estorbos = 2, pastillas = 1 }), nil,
                         { fregona = 1, colores = { [2] = 2 } })
    igual(paso(r.pasosBase, "Limpieza"), 2 * (C.ESTORBO + C.FREGONA))
    igual(paso(r.pasosBase, "Pastilla"), C.PASTILLA)
    igual(paso(r.pasosBase, "color"), 3 * C.GEMA_COLOR * 2)
end)

--== Orden de aplicacion ===================================================

prueba("orden: Base, luego +Mult, luego xMult", function()
    local j = P.nuevaJugada()
    j.forma = { tipo = "combo", pareja = "raya+raya", color = 1 }
    local r = P.calcular(j, nil, { fusion = 1 })
    -- (40) x (3) x 1,5
    igual(r.base, 40); igual(r.mult, 3); igual(r.xmult, 1.5); igual(r.total, 180)
    igual(r.pasosX[1].fuente, "Fusion")
end)

prueba("orden: los +Mult y los xMult van en su orden fijo", function()
    local e = P.nuevoEstado(); e.colorPrevio = 1; e.eslabones = 2; e.tresPrevio = true; e.rangoPrevio = 1
    e.usos = { cuatro = 1 }
    local r = P.calcular(jugada({ "cuatro", "tres" }, 1, 0, { crea = true }), e,
                         { doblete = 1, obsesion = 1, preparacion = 1, regalo = 1, remanso = 1,
                           crescendo = 1, monocromo = 1, molde = 1 })
    local orden = {}
    for _, p in ipairs(r.pasosMult) do orden[#orden + 1] = p.fuente end
    igual(table.concat(orden, ","), "Doble,Doblete,Afinidad,Preparacion,Regalo,Remanso")
    local ox = {}
    for _, p in ipairs(r.pasosX) do ox[#ox + 1] = p.fuente end
    igual(table.concat(ox, ","), "Crescendo,Monocromo,Molde")
end)

prueba("calcular no toca el estado que se le pasa", function()
    local e = P.nuevoEstado()
    P.calcular(jugada({ "lt" }, 1), e, { obsesion = 1 })
    igual(e.afinidad, 0); igual(e.colorPrevio, nil); igual(next(e.usos), nil)
end)

--== Mejoras ===============================================================

prueba("Preparacion: una forma justo despues de un 3", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "cuatro" }, 2), jugada({ "cuatro" }, 3) },
                     { preparacion = 1 })
    igual(paso(rs[2].pasosMult, "Preparacion"), 2)
    igual(paso(rs[3].pasosMult, "Preparacion"), nil, "sin tres delante")
    local tres = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 2) }, { preparacion = 1 })
    igual(paso(tres[2].pasosMult, "Preparacion"), nil, "un tres no es una forma")
end)

prueba("Crescendo: x1,5 solo cuando la forma es mejor que la de antes", function()
    local rs = serie({ jugada({ "cuatro" }, 1), jugada({ "cuatro" }, 2), jugada({ "lt" }, 3),
                       jugada({ "tres" }, 4) }, { crescendo = 1 })
    igual(rs[1].xmult, 1, "la primera no tiene con que compararse")
    igual(rs[2].xmult, 1, "igual no basta")
    igual(rs[3].xmult, 1.5, "mejor")
    igual(rs[4].xmult, 1, "peor")
end)

prueba("Monocromo: x1,5 a partir de la cuarta jugada del mismo color", function()
    local js = {}
    for k = 1, 4 do js[k] = jugada({ "tres" }, 3) end
    local rs = serie(js, { monocromo = 1 })
    igual(rs[3].xmult, 1); igual(rs[4].xmult, 1.5)
end)

prueba("Molde: la forma mas usada de la ronda (sin el tres)", function()
    local rs = serie({ jugada({ "cuatro" }, 1), jugada({ "tres" }, 2), jugada({ "tres" }, 3),
                       jugada({ "cuatro" }, 4), jugada({ "lt" }, 5) }, { molde = 1 })
    igual(rs[1].xmult, 1, "una vez no basta")
    igual(rs[3].xmult, 1, "el tres no cuenta")
    igual(rs[4].xmult, 1.5, "segunda linea de 4")
    igual(rs[5].xmult, 1, "L usada una vez")
end)

--== Contra el tablero =====================================================

-- Un tablero sin rachas: el color de (c, r) es ((c + 2r) mod 5) + 1, que no
-- repite ni en fila ni en columna. El 6 queda libre para dibujar formas.
local function tableroLimpio()
    local b = Board.nuevo({ cols = 8, rows = 8, colores = 6, semilla = 7 })
    for r = 1, 8 do
        for c = 1, 8 do
            local cel = b.celdas[b:idx(c, r)]
            cel.color, cel.especial, cel.hielo = (c + 2 * r) % 5 + 1, nil, nil
        end
    end
    return b
end

local function pinta(b, lista, color, especial)
    for _, cr in ipairs(lista) do
        local cel = b.celdas[b:idx(cr[1], cr[2])]
        cel.color, cel.especial = color, especial
    end
end

prueba("tablero: una L se cobra como L / T", function()
    local b = tableroLimpio()
    pinta(b, { { 1, 1 }, { 2, 1 }, { 3, 1 }, { 1, 2 }, { 1, 3 } }, 6)
    local s = b:resolver(nil, 1)
    local j = P.nuevaJugada(); P.sumarSuceso(j, s)
    igual(j.forma.formas[1], "lt"); igual(j.forma.color, 6); igual(j.forma.crea, true)
    -- cuatro y no cinco: la casilla donde nace la envuelta no se rompe
    igual(j.gemas[6], 4)
end)

prueba("tablero: dos grupos a la vez son un doble", function()
    local b = tableroLimpio()
    pinta(b, { { 1, 1 }, { 2, 1 }, { 3, 1 } }, 6)
    pinta(b, { { 6, 6 }, { 6, 7 }, { 6, 8 }, { 6, 5 } }, 6)
    local s = b:resolver(nil, 1)
    local j = P.nuevaJugada(); P.sumarSuceso(j, s)
    igual(#j.forma.formas, 2)
    local r = P.calcular(j)
    igual(paso(r.pasosMult, "Doble"), 2)
    igual(r.clave, "cuatro")
end)

prueba("tablero: el segundo suceso es cascada", function()
    local b = tableroLimpio()
    pinta(b, { { 1, 1 }, { 2, 1 }, { 3, 1 } }, 6)
    local j = P.nuevaJugada()
    P.sumarSuceso(j, b:resolver(nil, 1))
    local b2 = tableroLimpio()
    pinta(b2, { { 4, 4 }, { 5, 4 }, { 6, 4 }, { 7, 4 } }, 6)
    P.sumarSuceso(j, b2:resolver(nil, 2))
    igual(j.forma.formas[1], "tres"); igual(j.pasos, 1); igual(j.cascada[1], "cuatro")
end)

prueba("tablero: combo de dos rayas", function()
    local b = tableroLimpio()
    pinta(b, { { 4, 4 } }, 2, "rayaH")
    pinta(b, { { 5, 4 } }, 3, "rayaV")
    b:intercambiar(b:idx(4, 4), b:idx(5, 4))
    local s = b:combo(b:idx(5, 4), b:idx(4, 4), 1)
    local j = P.nuevaJugada(); P.sumarSuceso(j, s)
    igual(j.forma.tipo, "combo"); igual(j.forma.pareja, "raya+raya")
    igual(P.calcular(j).nombre, "Cruz")
end)

prueba("tablero: el preview de un intercambio no toca el tablero", function()
    local b = tableroLimpio()
    pinta(b, { { 1, 1 }, { 2, 1 }, { 4, 1 } }, 6)
    local antes = b:volcar()
    local grupos = b:gruposDeIntercambio(b:idx(3, 1), b:idx(4, 1))
    igual(b:volcar(), antes)
    igual(#grupos, 1); igual(grupos[1].n, 3)
    local r = P.prever(grupos)
    igual(r.nombre, "Linea de 3"); igual(r.total, 21)
end)

--== Arcade ================================================================

prueba("arcade: la curva nueva", function()
    igual(Arcade.meta(1), 2200)
    igual(Arcade.meta(14), Arcade.meta(13), "el sexto color para la curva")
    igual(Arcade.meta(20), 37100)
    igual(Arcade.meta(21), 46400)
    igual(Arcade.metaVieja(1), 5000)
end)

prueba("arcade: todas las cartas se leen y se aplican", function()
    local run = Arcade.nuevo(1)
    for _, m in ipairs(Arcade.MEJORAS) do
        run.mejoras[m.id] = m.tope
        for n = 1, m.tope do assert(type(m.texto(n)) == "string", m.id) end
    end
    local mods = Arcade.mods(run)
    igual(mods.niveles.cuatro, 3); igual(mods.niveles.lt, 3); igual(mods.niveles.cinco, 2)
    igual(mods.colores[1], 3); igual(mods.fusion, 3)
    assert(not Arcade.porId.suerte, "Suerte ya no esta en el pool")
    assert(not Arcade.porId.ancla and not Arcade.porId.paciencia, "se fueron con la escalada")
    -- y la tabla completa sigue siendo un tablero valido
    Board.nuevo({ mods = mods })
end)

print(string.format("%d pruebas, %d fallos", pruebas, fallos))
os.exit(fallos == 0 and 0 or 1)
