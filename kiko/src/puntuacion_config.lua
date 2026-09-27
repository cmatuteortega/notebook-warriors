-- Los numeros de la puntuacion del arcade, todos en un sitio.
--
-- El arcade puntua con Base x Mult (ver `src/puntuacion.lua` y
-- `docs/scoring-redesign.md`): la Base dice CUANTO se ha roto y la forma de
-- la jugada, el Mult dice COMO se ha jugado -- la forma, la escalada, el
-- color que se mantiene -- y las mejoras raras multiplican el producto. Este
-- archivo es solo datos: cambiar un numero aqui no puede romper ninguna regla,
-- solo el equilibrio, y el equilibrio lo mide `tests/simular.lua`.
--
-- La campana NO lee nada de aqui. Sigue cobrando con `Board.PUNTOS` y sus
-- estrellas estan medidas contra eso.

local C = {}

--== La Base ===============================================================

-- Lo que vale cada galleta rota, en toda la jugada (cascada incluida). Es poco
-- a proposito: si una galleta valiera lo que una forma, el volumen volveria a
-- mandar sobre la decision, que es justo lo que se viene a quitar.
C.GEMA = 5
-- Lo que suma cada nivel de una mejora de color, por cada galleta de ese color.
C.GEMA_COLOR = 3
-- Cada capa de barro, cubito o mancha de moho quitada, y lo que sube por nivel
-- de Fregona.
C.ESTORBO = 10
C.FREGONA = 5
-- Una pastilla que llega al suelo durante la jugada.
C.PASTILLA = 100

--== Las formas ============================================================

-- `rango` ordena las formas para la escalada: una forma sube la escalada si su
-- rango es igual o mayor que el de la ultima forma que la movio. La linea de
-- tres (rango 1) es NEUTRA -- ni sube ni parte -- y eso es la regla B: sin
-- ella, quien solo hace lineas de tres escala para siempre y quien hace una L
-- y luego un tres pierde la mitad (medido: el bot al azar escalaba MAS que el
-- codicioso).
--
-- `subir` es lo que gana la forma por cada nivel de mas (las mejoras de forma).
C.FORMAS = {
    tres     = { nombre = "Linea de 3", corto = "3",   base = 10, mult = 1, rango = 1,
                 subir = { base = 5,  mult = 0.5 } },
    cuadrado = { nombre = "Cuadrado",   corto = "2x2", base = 20, mult = 2, rango = 2,
                 subir = { base = 10, mult = 1 } },
    cuatro   = { nombre = "Linea de 4", corto = "4",   base = 25, mult = 2, rango = 2,
                 subir = { base = 10, mult = 1 } },
    lt       = { nombre = "L / T",      corto = "L",   base = 30, mult = 3, rango = 3,
                 subir = { base = 10, mult = 1 } },
    cinco    = { nombre = "Linea de 5", corto = "5",   base = 50, mult = 4, rango = 4,
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

--== El Mult de estado =====================================================

-- Escalada (regla B). Una forma de rango 2 o mas que iguala o supera a la
-- ultima que movio la escalada suma ESCALADA_SUBE; una peor la multiplica por
-- ESCALADA_CORTE.
C.RANGO_ESCALA = 2
C.ESCALADA_SUBE = 1
C.ESCALADA_CORTE = 0.5

-- Afinidad de color: cada jugada seguida cuyo color principal es el mismo que
-- el de la anterior suma esto, hasta el tope. Cambiar de color la pone a cero.
C.AFINIDAD_SUBE = 0.5
C.AFINIDAD_TOPE = 3

--== Mejoras (los numeros; las filas estan en src/arcade.lua) ==============

C.OBSESION_SUBE = 0.5     -- afinidad de mas por eslabon y nivel
C.OBSESION_TOPE = 1       -- tope de afinidad de mas por nivel
C.FUSION = 0.5            -- xMult de combo: 1 + esto por nivel
C.REGALO = 1              -- +Mult por nivel si la jugada crea una especial
C.CADENA = 0.25           -- +Mult por paso de cascada y nivel...
C.CADENA_TOPE = 2         -- ...con este tope
C.REMANSO = 2             -- +Mult por nivel si la jugada no encadena nada
C.DOBLETE = 2             -- +Mult de mas por nivel en el doble match
C.CRESCENDO = 2           -- escalada que suma una forma estrictamente mejor
C.MONOCROMO = 1.5         -- xMult con la afinidad en 3 eslabones o mas...
C.MONOCROMO_ESLABONES = 3
C.MOLDE = 1.5             -- xMult a la forma mas usada de la ronda (sin el tres)...
C.MOLDE_MINIMO = 2        -- ...cuando ya se ha hecho al menos estas veces

--== La curva de metas =====================================================

-- meta(r) = META * CRECE^(e - k) * CRECE_FINAL^k, con e = r - 1 - pausas (las
-- rondas en que entra un color nuevo no suben) y k = rondas pasada la
-- DESDE_FINAL. Mas suave que la de antes al principio y mas dura al final: con
-- Base x Mult las mejoras se COMPONEN, asi que una buena partida crece en
-- geometrica y una mala se queda plana -- y la curva mide eso.
C.META = 2500
C.CRECE = 1.22
C.CRECE_FINAL = 1.30
C.DESDE_FINAL = 20

return C
