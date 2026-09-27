-- Los numeros de la puntuacion del arcade, todos en un sitio.
--
-- El arcade puntua con Base x Mult (ver `src/puntuacion.lua` y
-- `docs/scoring-redesign.md`): la Base dice CUANTO se ha roto y la forma de
-- la jugada, el Mult dice COMO se ha jugado -- la forma, y lo que las mejoras
-- premien -- y las mejoras raras multiplican el producto. Este
-- archivo es solo datos: cambiar un numero aqui no puede romper ninguna regla,
-- solo el equilibrio, y el equilibrio lo mide `tests/simular.lua`.
--
-- La campana NO lee nada de aqui. Sigue cobrando con `Board.PUNTOS` y sus
-- estrellas estan medidas contra eso.

local C = {}

--== La Base ===============================================================

-- Lo que vale cada galleta rota, en toda la jugada (cascada incluida). Es poco
-- a proposito: si una galleta valiera lo que una forma, el volumen volveria a
-- mandar sobre la decision, que es justo lo que se viene a quitar. Dos y no
-- cinco (lo que decia el brief) porque esta medido: a cinco, lo que trae la
-- cascada por azar pesa tanto que el planificador apenas saca ventaja al
-- codicioso en la primera ronda (ver `docs/scoring-redesign.md`, seccion 9).
C.GEMA = 2
-- Lo que suma cada nivel de una mejora de color, por cada galleta de ese color.
C.GEMA_COLOR = 3
-- Cada capa de barro, cubito o mancha de moho quitada, y lo que sube por nivel
-- de Fregona.
C.ESTORBO = 10
C.FREGONA = 5
-- Una pastilla que llega al suelo durante la jugada.
C.PASTILLA = 100

--== Las formas ============================================================

-- La tabla que salio de la simulacion (la del brief era 10x1, 20x2, 25x2,
-- 30x3, 50x4): mas base en la forma y mas distancia de Mult entre una forma
-- buscada y cualquier cosa que case.
--
-- `rango` ordena las formas de peor a mejor. Lo miran dos cosas: cual manda en
-- un doble match (la de rango mayor pone el Mult) y la mejora Crescendo.
--
-- `subir` es lo que gana la forma por cada nivel de mas (las mejoras de forma).
C.FORMAS = {
    tres     = { nombre = "Linea de 3", corto = "3",   base = 15, mult = 1, rango = 1,
                 subir = { base = 5,  mult = 0.5 } },
    cuadrado = { nombre = "Cuadrado",   corto = "2x2", base = 30, mult = 3, rango = 2,
                 subir = { base = 10, mult = 1 } },
    cuatro   = { nombre = "Linea de 4", corto = "4",   base = 40, mult = 3, rango = 2,
                 subir = { base = 10, mult = 1 } },
    lt       = { nombre = "L / T",      corto = "L",   base = 50, mult = 4, rango = 3,
                 subir = { base = 10, mult = 1 } },
    cinco    = { nombre = "Linea de 5", corto = "5",   base = 80, mult = 6, rango = 4,
                 subir = { base = 20, mult = 2 } },
}

-- Dos grupos a la vez con un solo intercambio: se suman las bases y el mult es
-- el de la forma mayor mas este.
C.DOBLE_MULT = 2

-- Juntar dos especiales. No es una forma que se case, asi que lleva su propia
-- fila por pareja. Cuentan como rango 4 (lo mismo que la linea de cinco): hay
-- que haber hecho dos especiales antes, que es la jugada mas preparada del
-- juego.
C.RANGO_COMBO = 4
C.COMBOS = {
    ["raya+raya"]           = { nombre = "Cruz",          base = 40,  mult = 3 },
    ["envuelta+raya"]       = { nombre = "Cruz gorda",    base = 60,  mult = 4 },
    ["envuelta+envuelta"]   = { nombre = "Bombazo",       base = 70,  mult = 4 },
    ["estrella+raya"]       = { nombre = "Estrella+raya", base = 50,  mult = 3 },
    ["envuelta+estrella"]   = { nombre = "Estrella+bomba", base = 55, mult = 3 },
    ["estrella+estrella"]   = { nombre = "Lluvia",        base = 60,  mult = 3 },
    ["galleta+pelota"]      = { nombre = "Pelota",        base = 50,  mult = 3 },
    ["especial+pelota"]     = { nombre = "Pelota loca",   base = 90,  mult = 5 },
    ["pelota+pelota"]       = { nombre = "Todo",          base = 100, mult = 6 },
}
C.COMBO_DEFECTO = { nombre = "Combo", base = 40, mult = 3 }

--== Mejoras (los numeros; las filas estan en src/arcade.lua) ==============

-- No hay Mult de estado de serie: cada jugada se cobra por lo que es. Lo que
-- recuerda la ronda entre jugada y jugada (el color de la anterior, su forma)
-- solo lo cobran las mejoras que lo dicen.
--
-- Afinidad de color (la mejora Obsesion). Cada jugada seguida cuyo color
-- principal es el de la anterior suma OBSESION_SUBE por nivel, hasta
-- OBSESION_TOPE por nivel. Cambiar de color la pone a cero (a la mitad con
-- Lealtad).
C.OBSESION_SUBE = 1
C.OBSESION_TOPE = 4
C.LEALTAD = 0.5           -- lo que se queda la afinidad al cambiar de color

C.FUSION = 0.5            -- xMult de combo: 1 + esto por nivel
C.REGALO = 1              -- +Mult por nivel si la jugada crea una especial
C.CADENA = 0.25           -- +Mult por paso de cascada y nivel...
C.CADENA_TOPE = 2         -- ...con este tope
C.REMANSO = 2             -- +Mult por nivel si la jugada no encadena nada
C.DOBLETE = 2             -- +Mult de mas por nivel en el doble match
C.PREPARACION = 2         -- +Mult por nivel a una forma justo despues de un tres
C.CRESCENDO = 1.5         -- xMult a una forma mejor que la de la jugada anterior
C.MONOCROMO = 1.5         -- xMult con el mismo color principal 4 jugadas seguidas...
C.MONOCROMO_ESLABONES = 3 -- ...que son tres eslabones despues de la primera
C.MOLDE = 1.5             -- xMult a la forma mas usada de la ronda (sin el tres)...
C.MOLDE_MINIMO = 2        -- ...cuando ya se ha hecho al menos estas veces

--== La curva de metas =====================================================

-- meta(r) = META * CRECE^(e - k) * CRECE_FINAL^k, con e = r - 1 - pausas (las
-- rondas en que entra un color nuevo no suben) y k = rondas pasada la
-- DESDE_FINAL. Mas suave que la de antes al principio y mas dura al final: con
-- Base x Mult las mejoras se COMPONEN, asi que una buena partida crece en
-- geometrica y una mala se queda plana -- y la curva mide eso.
--
-- Los numeros estan MEDIDOS con `tests/simular.lua --solo-arcade` (partidas
-- enteras, eligiendo mejoras) y el blanco era el del plan: el codicioso se
-- queda hacia la ronda 12 y el planificador llega hacia la 20. Con estos da
-- 11,9 y 19,8 de media. Sin escalada una ronda pelada da menos y crece poco
-- con los movimientos, asi que lo que sube la partida son las mejoras: por eso
-- la curva crece mas despacio que la de antes (1,22).
C.META = 2200
C.CRECE = 1.17
C.CRECE_FINAL = 1.25
C.DESDE_FINAL = 20

return C
