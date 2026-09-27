-- Pruebas de la puntuacion del arcade (Base x Mult). Sin ventana:
--
--     luajit tests/test_puntuacion.lua        (desde la carpeta kiko/)
--
-- Cubren las formas y sus niveles, el doble match, los combos, la escalada
-- (regla B), la afinidad de color, la cascada (que solo suma Base), el orden de
-- aplicacion y las mejoras nuevas. Al final, un par de pruebas contra el
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
    for clave, esperado in pairs({ tres = { 10, 1 }, cuadrado = { 20, 2 }, cuatro = { 25, 2 },
                                   lt = { 30, 3 }, cinco = { 50, 4 } }) do
        local f = P.forma(clave)
        igual(f.base, esperado[1], clave .. " base")
        igual(f.mult, esperado[2], clave .. " mult")
        igual(f.nivel, 1, clave .. " nivel")
    end
end)

prueba("las formas suben de nivel", function()
    local f = P.forma("cuatro", { niveles = { cuatro = 2 } })
    igual(f.nivel, 3); igual(f.base, 45); igual(f.mult, 4)
    local g = P.forma("cinco", { niveles = { cinco = 1 } })
    igual(g.base, 70); igual(g.mult, 6)
    local r = P.calcular(jugada({ "lt" }), nil, { niveles = { lt = 1 } })
    igual(r.nombre, "L / T"); igual(r.nivel, 2); igual(r.multForma, 4)
end)

prueba("linea de 3 pelada: (10 + 3 galletas x 5) x 1", function()
    local r = P.calcular(jugada({ "tres" }, 1, 3))
    igual(r.base, 25, "base"); igual(r.mult, 1, "mult"); igual(r.total, 25, "total")
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
    igual(r.base, 40, "base")
    igual(r.multForma, 3, "mult de forma")
    igual(paso(r.pasosMult, "Doble"), 2, "doble")
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

--== Escalada (regla B) ====================================================

prueba("escalada: la linea de 3 es neutra", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 2), jugada({ "tres" }, 3) })
    for k, r in ipairs(rs) do igual(r.estado.escalada, 0, "jugada " .. k) end
end)

prueba("escalada: igual o mejor suma, peor parte por la mitad", function()
    local seq = { "cuatro", "cuatro", "lt", "tres", "cuatro", "cinco" }
    local esperado = { 1, 2, 3, 3, 1.5, 2.5 }
    local js = {}
    for k, f in ipairs(seq) do js[k] = jugada({ f }, k % 5 + 1) end
    local rs = serie(js)
    for k, r in ipairs(rs) do igual(r.estado.escalada, esperado[k], "jugada " .. k) end
    -- y la jugada que sube ya cobra con ella
    igual(paso(rs[3].pasosMult, "Escalada"), 3)
end)

prueba("escalada: el cuadrado cuenta como una linea de 4", function()
    local rs = serie({ jugada({ "cuatro" }, 1), jugada({ "cuadrado" }, 2) })
    igual(rs[2].estado.escalada, 2)
end)

prueba("escalada: un combo es rango 4", function()
    local j = P.nuevaJugada(); j.forma = { tipo = "combo", pareja = "raya+raya", color = 1 }
    local rs = serie({ jugada({ "cinco" }, 2), j, jugada({ "lt" }, 3) })
    igual(rs[2].estado.escalada, 2); igual(rs[3].estado.escalada, 1)
end)

--== Afinidad ==============================================================

prueba("afinidad: +0,5 por jugada seguida del mismo color, cero al cambiar", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1), jugada({ "tres" }, 1),
                       jugada({ "tres" }, 2) })
    igual(rs[1].estado.afinidad, 0); igual(rs[2].estado.afinidad, 0.5)
    igual(rs[3].estado.afinidad, 1.0); igual(rs[4].estado.afinidad, 0)
    igual(rs[3].mult, 2, "mult con afinidad")
end)

prueba("afinidad: tope 3, y Obsesion sube paso y tope", function()
    local js = {}
    for k = 1, 12 do js[k] = jugada({ "tres" }, 4) end
    local _, e = serie(js)
    igual(e.afinidad, C.AFINIDAD_TOPE)
    local rs, e2 = serie(js, { obsesion = 1 })
    igual(rs[2].estado.afinidad, 1.0, "paso con obsesion")
    igual(e2.afinidad, C.AFINIDAD_TOPE + 1, "tope con obsesion")
end)

prueba("afinidad: una jugada sin color no la toca", function()
    local sin = P.nuevaJugada(); sin.forma = { tipo = "combo", pareja = "pelota+pelota" }
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "tres" }, 1), sin, jugada({ "tres" }, 1) })
    igual(rs[3].estado.afinidad, 0.5); igual(rs[4].estado.afinidad, 1.0)
end)

--== Cascada ===============================================================

prueba("cascada: suma Base y no Mult", function()
    local sola = P.calcular(jugada({ "tres" }, 1, 3))
    local con = P.calcular(jugada({ "tres" }, 1, 9, { cascada = { "cuatro", "tres" } }))
    igual(con.mult, sola.mult, "mult sin cambiar")
    igual(con.base, 10 + 9 * C.GEMA + 25 + 10, "base con cascada")
    igual(paso(con.pasosBase, "Cascada"), 35)
end)

prueba("cascada: la base de sus formas usa sus niveles", function()
    local r = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "cuatro" } }), nil,
                         { niveles = { cuatro = 1 } })
    igual(paso(r.pasosBase, "Cascada"), 35)
end)

prueba("Cadena: +0,25 por paso y nivel, tope 2", function()
    local r = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "tres", "tres" } }), nil, { cadena = 1 })
    igual(paso(r.pasosMult, "Cadena"), 0.5)
    local js = {}
    for k = 1, 12 do js[k] = "tres" end
    local t = P.calcular(jugada({ "tres" }, 1, 0, { cascada = js }), nil, { cadena = 2 })
    igual(paso(t.pasosMult, "Cadena"), 2)
end)

prueba("Remanso: solo sin cascada, y nunca en el preview", function()
    local r = P.calcular(jugada({ "tres" }, 1), nil, { remanso = 1 })
    igual(paso(r.pasosMult, "Remanso"), 2)
    local c = P.calcular(jugada({ "tres" }, 1, 0, { cascada = { "tres" } }), nil, { remanso = 1 })
    igual(paso(c.pasosMult, "Remanso"), nil)
    local pv = P.prever({ { premio = nil, color = 1, n = 3 } }, nil, { remanso = 1 })
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
    -- (40) x (3 + escalada 1) x 1,5
    igual(r.base, 40); igual(r.mult, 4); igual(r.xmult, 1.5); igual(r.total, 240)
    igual(r.pasosX[1].fuente, "Fusion")
end)

prueba("orden: los +Mult van en su orden fijo", function()
    local e = P.nuevoEstado(); e.colorPrevio = 1; e.rangoPrevio = 1
    local r = P.calcular(jugada({ "cuatro", "tres" }, 1, 0, { crea = true }), e,
                         { doblete = 1, regalo = 1, remanso = 1 })
    local orden = {}
    for _, p in ipairs(r.pasosMult) do orden[#orden + 1] = p.fuente end
    igual(table.concat(orden, ","), "Doble,Doblete,Escalada,Afinidad,Regalo,Remanso")
end)

prueba("calcular no toca el estado que se le pasa", function()
    local e = P.nuevoEstado()
    P.calcular(jugada({ "lt" }, 1), e)
    igual(e.escalada, 0); igual(e.colorPrevio, nil); igual(next(e.usos), nil)
end)

--== Mejoras nuevas ========================================================

prueba("Paciencia: un 3 y luego una forma da escalada extra", function()
    local rs = serie({ jugada({ "tres" }, 1), jugada({ "cuatro" }, 2) }, { paciencia = 1 })
    igual(rs[2].estado.escalada, 2)
    local sin = serie({ jugada({ "cuatro" }, 1), jugada({ "cuatro" }, 2) }, { paciencia = 1 })
    igual(sin[2].estado.escalada, 2, "sin tres delante no hay extra")
end)

prueba("Ancla: el corte no baja de n", function()
    local js = { jugada({ "cinco" }, 1), jugada({ "cinco" }, 2), jugada({ "cinco" }, 3),
                 jugada({ "cinco" }, 4), jugada({ "cuatro" }, 5) }
    local rs = serie(js, { ancla = 3 })
    igual(rs[5].estado.escalada, 3)
    local sin = serie(js)
    igual(sin[5].estado.escalada, 2)
end)

prueba("Crescendo: +2 solo cuando la forma es estrictamente mejor", function()
    local rs = serie({ jugada({ "cuatro" }, 1), jugada({ "cuatro" }, 2), jugada({ "lt" }, 3) },
                     { crescendo = 1 })
    igual(rs[1].estado.escalada, 2); igual(rs[2].estado.escalada, 3); igual(rs[3].estado.escalada, 5)
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
    igual(r.nombre, "Linea de 3"); igual(r.total, 25)
end)

--== Arcade ================================================================

prueba("arcade: la curva nueva", function()
    igual(Arcade.meta(1), 2500)
    igual(Arcade.meta(14), Arcade.meta(13), "el sexto color para la curva")
    igual(Arcade.meta(20), 89600)
    igual(Arcade.meta(21), 116500)
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
    -- y la tabla completa sigue siendo un tablero valido
    Board.nuevo({ mods = mods })
end)

print(string.format("%d pruebas, %d fallos", pruebas, fallos))
os.exit(fallos == 0 and 0 or 1)
