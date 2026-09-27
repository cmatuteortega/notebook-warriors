-- La tabla de formas que propone la Fase 4 (ver docs/scoring-redesign.md, §9).
--
--     luajit tests/simular.lua --ajuste tests/ajustes/propuesta.lua
--
-- Tres cambios, y los tres empujan hacia lo mismo: que puntue la DECISION y no
-- el volumen.
--   * La galleta vale 2 y no 5, y las formas llevan mas base: lo que la cascada
--     trae por azar pesa menos frente a la forma que se ha buscado.
--   * Mas distancia de Mult entre formas (1 / 3 / 3 / 4 / 6): buscar la forma
--     buena paga mas que casar cualquier cosa.
--   * La afinidad de color sube 1 por jugada seguida (tope 4): mantener un
--     color es la micro-decision que el codicioso nunca toma.
local C = ...
C.GEMA = 2
C.FORMAS.tres.base, C.FORMAS.cuadrado.base, C.FORMAS.cuatro.base = 15, 30, 40
C.FORMAS.lt.base, C.FORMAS.cinco.base = 50, 80
C.FORMAS.cuadrado.mult, C.FORMAS.cuatro.mult, C.FORMAS.lt.mult, C.FORMAS.cinco.mult = 3, 3, 4, 6
C.AFINIDAD_SUBE, C.AFINIDAD_TOPE = 1.0, 4
