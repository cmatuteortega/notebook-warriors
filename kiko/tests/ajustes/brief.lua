-- La tabla de formas del brief, antes de que la simulacion la cambiara.
--
--     luajit tests/simular.lua --ajuste tests/ajustes/brief.lua
--
-- La de serie (`src/puntuacion_config.lua`) es la que salio de medir esta: la
-- galleta a 2 y no a 5, mas base en las formas y mas distancia de Mult entre
-- ellas. Con esta, lo que trae la cascada por azar pesa tanto que el
-- planificador apenas saca ventaja al codicioso en la primera ronda (ver
-- `docs/scoring-redesign.md`, seccion 9).
local C = ...
C.GEMA = 5
C.FORMAS.tres.base, C.FORMAS.cuadrado.base, C.FORMAS.cuatro.base = 10, 20, 25
C.FORMAS.lt.base, C.FORMAS.cinco.base = 30, 50
C.FORMAS.cuadrado.mult, C.FORMAS.cuatro.mult, C.FORMAS.lt.mult, C.FORMAS.cinco.mult = 2, 2, 3, 4
