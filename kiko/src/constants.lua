-- Resolucion, escala y margenes seguros.
--
-- Hay tres espacios de coordenadas y conviene tenerlos claros:
--
--   ventana  -> pixeles reales del dispositivo. Solo main.lua los toca.
--   virtual  -> lienzo de 540 de ancho (GAME_WIDTH/GAME_HEIGHT). Toda la
--               interfaz (texto, botones, paneles) vive aqui.
--   arte     -> virtual dividido por ART (4). El tablero, las galletas y
--               cualquier sprite se dibujan aqui, en enteros, y suben a
--               virtual con un scale() entero. Es lo que mantiene el pixel
--               crujiente.
--
-- El lienzo NO es 540x960 fijo: la altura se estira para cubrir la pantalla
-- del movil (un 20:9 da 540x1215). Nada se posiciona contra un 960 escrito a
-- mano; se lee GAME_HEIGHT / ART_H.

local Constants = {}

Constants.BASE_WIDTH  = 540
Constants.BASE_HEIGHT = 960

Constants.GAME_WIDTH  = 540
Constants.GAME_HEIGHT = 960

-- Escala de interfaz respecto a la resolucion base (1.0 en un movil 9:16).
Constants.SCALE = 1

-- El tablero. 8x8 y no el 9x9 del original: con 540 de ancho, nueve columnas
-- dejan la galleta en 56 pixeles virtuales y el dedo tapa dos. Ocho columnas de
-- 16 pixeles de arte son 128, que caben en los 135 del lienzo a escala 4 y
-- dejan aire a los lados sin que la casilla baje de los ~11 mm en un movil
-- normal. Ver README.md.
Constants.COLS = 8
Constants.ROWS = 8
Constants.TILE = 16          -- lado de la casilla en pixeles de ARTE

-- Un pixel de arte son ART pixeles virtuales. Entero siempre: es la unica
-- forma de que un sprite de 16px no se interpole. Tambien es el zoom del
-- tablero, asi que bajarlo encoge el juego entero sin tocar un sprite.
Constants.ART = 4
Constants.ART_W = 135
Constants.ART_H = 240

-- La escalera de fuentes, toda en multiplos de ocho (la rejilla de
-- Pixellari). GIANT es el cuerpo de los puntos de la cabecera y el unico que
-- no se usa en ningun otro sitio: son el numero que se mira al acabar una
-- jugada, y a menos cuerpo que este no ganan la mirada al tablero que tienen
-- debajo. Ochenta y ocho y no setenta y dos porque la cifra se pinta CENTRADA
-- contra la cara de Kiko, que mide noventa y seis: a setenta y dos sobraba
-- hueco por arriba y por abajo, y lo que se leia era un numero pequeno dentro
-- de una franja grande.
Constants.FONT_SIZES = { GIANT = 88, HUGE = 64, LARGE = 48, MEDIUM = 32, SMALL = 24, TINY = 16 }
Constants.BASE_FONT_SIZES = { GIANT = 88, HUGE = 64, LARGE = 48, MEDIUM = 32, SMALL = 24, TINY = 16 }

-- Margenes seguros (notch / barra de navegacion) en coordenadas virtuales.
Constants.SAFE_TOP, Constants.SAFE_BOTTOM = 0, 0
Constants.SAFE_LEFT, Constants.SAFE_RIGHT = 0, 0

function Constants.updateResolution(windowWidth, windowHeight)
    local aspect = windowWidth / windowHeight

    -- Ancho fijo, alto segun el aspecto: una pantalla mas larga ensena mas
    -- mantel en vez de deformar o poner bandas negras.
    Constants.GAME_WIDTH  = Constants.BASE_WIDTH
    Constants.GAME_HEIGHT = math.floor(Constants.BASE_WIDTH / aspect)

    -- Si la ventana es apaisada (escritorio) invertimos el criterio para no
    -- generar un lienzo absurdamente bajo.
    if aspect > (Constants.BASE_WIDTH / Constants.BASE_HEIGHT) then
        Constants.GAME_HEIGHT = Constants.BASE_HEIGHT
        Constants.GAME_WIDTH  = math.floor(Constants.BASE_HEIGHT * aspect)
    end

    Constants.SCALE = math.min(Constants.GAME_WIDTH / Constants.BASE_WIDTH,
                               Constants.GAME_HEIGHT / Constants.BASE_HEIGHT)

    -- ART se queda en 4 salvo que el lienzo sea tan estrecho que el tablero no
    -- quepa; entonces baja de escalon en vez de recortarlo. El area de arte se
    -- deriva de ART, nunca al reves.
    local minArtW = Constants.COLS * Constants.TILE
    Constants.ART = math.max(2, math.min(4, math.floor(Constants.GAME_WIDTH / minArtW)))
    Constants.ART_W = math.floor(Constants.GAME_WIDTH  / Constants.ART)
    Constants.ART_H = math.floor(Constants.GAME_HEIGHT / Constants.ART)

    -- Las fuentes se ajustan a multiplos de 8, la rejilla de Pixellari: un
    -- tamano intermedio la renderiza a medio pixel y se ve sucia.
    local function snap(base, min)
        return math.max(min, math.floor(base * Constants.SCALE / 8) * 8)
    end
    for name, base in pairs(Constants.BASE_FONT_SIZES) do
        Constants.FONT_SIZES[name] = snap(base, name == "TINY" and 8 or 16)
    end
end

function Constants.updateSafeInsets(sx, sy, sw, sh, windowW, windowH)
    local kx = windowW / Constants.GAME_WIDTH
    local ky = windowH / Constants.GAME_HEIGHT
    Constants.SAFE_LEFT   = sx / kx
    Constants.SAFE_TOP    = sy / ky
    Constants.SAFE_RIGHT  = (windowW - sx - sw) / kx
    Constants.SAFE_BOTTOM = (windowH - sy - sh) / ky
end

-- Esquina de arriba a la izquierda del tablero, en pixeles de ARTE.
--
-- Horizontal: centrado. Vertical: NO centrado. El tablero se apoya hacia abajo
-- porque la cabecera (movimientos, objetivo, puntos y barra) pide mas sitio
-- que el pie, y porque el dedo llega peor a lo de arriba de un movil que a lo
-- de abajo: el 58% del hueco que sobra va arriba y el 42% abajo, que es lo que
-- deja el boton de salir bajo el pulgar sin pegarlo al canto.
function Constants.boardOrigin()
    local w = Constants.COLS * Constants.TILE
    local h = Constants.ROWS * Constants.TILE
    local safeTop = math.floor(Constants.SAFE_TOP / Constants.ART)
    local safeBot = math.floor(Constants.SAFE_BOTTOM / Constants.ART)
    local libre = (Constants.ART_H - safeTop - safeBot) - h
    return math.floor((Constants.ART_W - w) / 2),
           safeTop + math.floor(libre * 0.58)
end

return Constants
