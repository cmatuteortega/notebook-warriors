-- El tablero. Toda la reglas del juego viven aqui y NINGUNA dibuja.
--
-- Este modulo no puede requerir `love`: es lo que permite probarlo sin ventana
-- (`tests/test_board.lua`) y lo que hace que una semilla de un nivel de un
-- movil sea el mismo reparto en escritorio. El azar entra por `Util.rng` y por
-- ningun otro sitio.
--
-- La otra mitad del contrato es que el tablero no anima nada, pero tiene que
-- contarlo todo: cada llamada que cambia el estado devuelve un SUCESO con lo
-- que ha pasado y en que ORDEN, y la pantalla de juego lo unico que hace es
-- ponerle tiempo encima. Por eso las explosiones salen por ONDAS -- la onda 1
-- son las galletas que casaban, la 2 lo que reventaron las especiales que
-- habia dentro, la 3 lo que reventaron aquellas -- : sin las ondas, una
-- cadena de cinco envueltas se ve como un unico fogonazo y no se entiende.
--
-- Una casilla es:
--   { color = 1..6 | nil,
--     especial = nil|"rayaH"|"rayaV"|"envuelta"|"estrella"|"pelota",
--     pastilla = true|nil, hielo = true|nil, id = n }
-- El `id` es unico y no se reutiliza NUNCA: es como la pantalla sigue a una
-- galleta concreta mientras cae, y sin el, dos galletas del mismo color que se
-- cruzan en una columna se intercambian el sprite a media caida.
--
-- Sin color hay dos cosas: la PELOTA (no casa con nadie, se usa tocandola) y
-- la PASTILLA (la que hay que bajar hasta el suelo). Las dos cortan una racha,
-- que es justo lo que las hace estorbar. La pastilla se llamo KIKO en la
-- primera version y ese nombre ya no se usa para nada: Kiko es el perro, y es
-- el sprite de la cabecera.
--
-- Y con color pero sin poder usarlo esta el CUBITO (`hielo`): una galleta
-- encerrada. No casa y no se mueve -- corta la racha como la pastilla -- pero
-- sigue siendo una galleta, y en cuanto se rompe el hielo vuelve al juego con
-- su color y su `id` intactos. El hielo se quita rompiendo algo AL LADO, que
-- es lo unico que lo hace distinto de un agujero: un agujero es la forma del
-- nivel y un cubito es una tarea.
--
-- Y en el SUELO, debajo de las galletas, hay dos cosas: el BARRO -- una o dos
-- capas que se quitan rompiendo lo que tienen encima -- y el MOHO, que es lo
-- mismo con una regla de mas: si acabas una jugada y queda moho en el bol, se
-- extiende a una casilla limpia de al lado. Es el unico estorbo del juego que
-- EMPEORA si lo ignoras, y por eso es el unico que decide el ORDEN en que se
-- juega: el barro y los cubitos esperan toda la partida, el moho no.
--
-- Vive en el suelo y no en la galleta a proposito. Un estorbo que ocupara
-- casilla y no cayera dejaria incomunicado todo lo que quedara debajo -- que
-- es la unica forma de romper un tablero que esta casa se toma en serio (ver
-- `test_levels.lua`) -- y uno que cayera seria un cubito con otro color. En el
-- suelo no toca la gravedad, y lo unico que hace es pedir que bajes a limpiar.
--
-- La ESTRELLA es la unica especial que no sale de una racha: sale de un
-- CUADRADO de dos por dos, que es justo la forma de cuatro que el barrido de
-- filas y columnas NO ve -- en un cuadro no hay tres en linea en ninguna
-- direccion --, y por eso se busca aparte (`cuadrados`). Tampoco revienta un
-- area del tablero como las otras: se parte en TRES y cada trozo se va a
-- buscar una galleta de su color donde este. Por eso su suceso lleva los
-- DESTINOS dentro -- sin ellos la pantalla no sabria por donde dibujar el
-- viaje, y tres casillas sueltas reventando a la vez no se leen como tres
-- estrellas, se leen como un fallo.

local Util = require("src.util")

local Board = {}
Board.__index = Board

Board.ESPECIALES = { rayaH = true, rayaV = true, envuelta = true,
                     estrella = true, pelota = true }

-- En cuantos trozos se parte una estrella. Tres y no dos ni cuatro: con dos no
-- se lee como que se ha repartido, y con cuatro los viajes se pisan entre si y
-- el ojo ya no puede seguir ninguno.
Board.ESTRELLAS = 3

-- Las cuatro vecinas de una casilla. En diagonal no hay vecindad en este juego
-- -- ni para casar ni para romper hielo -- y tenerlas escritas una sola vez es
-- lo que evita que un dia las diagonales entren por descuido en un sitio y no
-- en el otro.
local VECINAS = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }

-- Las ocho, y SOLO para romper hielo con la mejora de deshielo. En diagonal no
-- se casa ni se mueve nada en este juego: esta lista es la excepcion y tiene
-- que seguir siendolo, que es la razon de que sea otra tabla y no una version
-- larga de la de arriba.
local DIAGONALES = { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
                     { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }

-- Puntos. El 60 por galleta es el del original y el resto esta calibrado
-- contra el: una especial creada vale lo que dos galletas de mas, bajar una
-- pastilla vale una jugada entera. Ver README.md antes de tocarlos.
Board.PUNTOS = {
    galleta   = 60,
    barro    = 50,
    -- El cubito vale lo que una capa de barro porque es lo mismo: una capa que
    -- estorba y que se quita de un golpe. Cobrarlo mas caro convertiria un
    -- nivel con cubitos en un nivel de puntos facil.
    hielo    = 50,
    -- El moho vale lo que una capa de barro por la misma razon, y lo que lo
    -- hace caro no son sus puntos: es que mientras siga ahi, crece.
    moho     = 50,
    pastilla     = 2000,
    -- La estrella sale de cuatro galletas, como la rayada, y por eso cuesta
    -- casi lo mismo: lo que se paga de mas es que el premio APUNTA -- se va a
    -- buscar su color donde este en vez de limpiar la fila que le toco.
    crear    = { rayaH = 120, rayaV = 120, envuelta = 200,
                 estrella = 150, pelota = 300 },
}

-- Tope del multiplicador de cascada. Sin tope, una cadena afortunada de nueve
-- pasos en el nivel 3 se lleva el objetivo del 20, y el jugador no aprende
-- nada de eso.
Board.CASCADA_MAX = 6

-- Cuantos ESLABONES de la racha de color se cobran como mucho. Una racha de
-- color no es suerte -- se elige jugada a jugada, que es justo lo que paga --
-- pero el tope esta igual, y por una razon distinta a la del multiplicador de
-- cascada: la carta que la vende tiene que poder decir su propio numero. Un
-- premio que crece hasta que el color se acaba no se lee en la pausa de diez
-- segundos entre dos rondas, y una carta que no se lee no es una eleccion.
--
-- Tres, porque tres es lo que se ve venir: la jugada que repite, la que
-- repite otra vez y la de rematar. A partir de ahi lo que sigue subiendo es
-- cuantas VECES cobra, que es de lo que va la mejora.
Board.RACHA_COLOR_MAX = 3

-- Cada cuantas JUGADAS se extiende el moho una casilla.
--
-- Es el numero que decide si el moho es una tarea o una condena, y esta MEDIDO
-- con el jugador de mentira sobre el bol del escalon "El moho" (cuatro brotes,
-- treinta y cinco movimientos), contando cuantas rondas acaban con el bol a
-- cero y hasta donde llego la mancha:
--
--     cada 1 jugada    lo limpia el  8%   pico 10 casillas
--     cada 2 jugadas   lo limpia el 26%   pico  6
--     cada 3 jugadas   lo limpia el 48%   pico  4
--     cada 4 jugadas   lo limpia el 65%   pico  4
--
-- A una por jugada el bol se come al que juega arriba y la ronda se pierde sin
-- que se entienda por que -- diez casillas es el bol comido. A una cada tres
-- ya se limpia sola: la mitad de las rondas la arreglan sin ir a buscarla, y
-- entonces el moho es barro con animacion. Dos deja el pico en SEIS -- se ve
-- crecer, nunca desborda -- y el 26% esta donde tiene que estar: por encima
-- del 15% con el que esta casa declara roto un nivel (ver `test_balance.lua`)
-- y muy por debajo de regalado. Quien juega mirando la cuenta de la cabecera
-- lo limpia; quien se olvida dos jugadas, ya tiene mas que limpiar.
Board.MOHO_CADA = 2

-- Las MEJORAS del arcade entran por aqui y por ningun otro sitio.
--
-- Son numeros que se suman o multiplican a lo de arriba, y viven en el
-- TABLERO -- no en la pantalla -- porque lo que cambian son reglas: cuanto
-- vale una galleta, a cuantas casillas llega una envuelta, en cuantos trozos se
-- parte una estrella. Una mejora que la pantalla tuviera que recordar aplicar
-- seria una regla escrita en el sitio donde no se prueba.
--
-- Todas valen cero (o uno, las que multiplican) por defecto, asi que un
-- tablero sin `mods` es exactamente el tablero de siempre: la campana no se
-- entera de que esto existe.
Board.MODS = {
    -- Puntos de mas por galleta rota, POR FAMILIA: `galletas[3] = 100` quiere
    -- decir que cada limon vale cien de mas y los otros cinco siguen a
    -- sesenta. Es una tabla y no un numero porque asi la mejora tiene donde
    -- apuntar: subir un color es decirle al jugador a que galleta mirar, y eso
    -- es una decision; subirlas todas a la vez es solo una cifra mas grande.
    galletas   = {},
    barro     = 0,   -- puntos de mas por cada capa de barro o cubito
    racha4    = 0,   -- premio suelto por casar cuatro en linea
    racha5    = 0,   -- ...y cinco o mas
    -- Puntos de mas por cada ESLABON de la racha de color: una resolucion que
    -- se lleva por delante el mismo color que la anterior cobra uno, la
    -- siguiente dos, y de ahi no pasa (`RACHA_COLOR_MAX`). Es el unico numero
    -- de esta tabla que mira lo que paso en la jugada ANTERIOR, y por eso el
    -- tablero lleva la racha apuntada (`colorRacha`, `eslabones`).
    rachaColor = 0,
    crear     = 1,   -- x lo que se cobra al nacer una especial
    combo     = 1,   -- x lo que se cobra al juntar dos especiales
    radio     = 0,   -- casillas de mas de radio en envuelta, bombazo y cruz gorda
    estrellas = 0,   -- trozos de mas en los que se parte una estrella
    cascada   = 0,   -- tope de mas para el multiplicador de cascada
    -- Capas de barro DE MAS que se lleva cada golpe. Con una, un golpe limpia
    -- la doble capa entera. No es lo mismo que cobrar mas por el barro
    -- (`barro`): eso son puntos, y esto son movimientos -- lo que cambia es
    -- cuantas jugadas cuesta dejar el bol limpio.
    capas     = 0,
    -- Si el hielo se rompe tambien en DIAGONAL. El cubito se rompe cuando
    -- revienta una vecina, y sin esto vecina son las cuatro de siempre: un
    -- cubito en una esquina de un bloque solo se alcanza por dos lados.
    hieloDiagonal = false,
    -- Si las rayadas disparan en CRUZ: la fila y la columna, en vez de solo lo
    -- suyo. Es la unica de estas cifras que cambia lo que hace una pieza que
    -- ya estaba en el tablero, asi que el dibujo de la rayada deja de decir
    -- hacia donde dispara. Se acepta porque lo que hace es MAS y no otra cosa
    -- -- la fila que limpiaba la sigue limpiando -- y porque quien la coge lo
    -- ha elegido.
    mecha = false,
    -- Cuantas veces estalla una envuelta. Dos es lo de siempre (estalla, cae
    -- galleta nueva encima, y vuelve a estallar en el mismo sitio), y ese es su
    -- caracter: limpia poco pero lo limpia dos veces.
    envuelta = 2,
    -- Con que probabilidad una galleta NUEVA -- de las que entran por la boca
    -- de la columna -- baja con una especial puesta. Cero es lo de siempre.
    --
    -- Va sobre las que entran y no sobre el reparto inicial a proposito: el
    -- reparto se deshace hasta que no tiene rachas ni cuadrados hechos
    -- (`deshacerSobras`), y meter especiales ahi seria regalar la primera
    -- jugada antes de que nadie haya tocado nada.
    suerte = 0,
}

-- Lo que puede traer puesto una galleta con suerte, y en que proporcion: dos de
-- cada cinco una raya de cada, y una de cada cinco una envuelta. Ni estrella
-- ni pelota -- esas dos son el premio de una jugada buena, y caidas del
-- cielo se llevarian por delante la razon de buscarlas.
Board.REGALOS = { "rayaH", "rayaH", "rayaV", "rayaV", "envuelta" }

--== Construccion ==========================================================

-- opts:
--   cols, rows      tamano (por defecto los de Constants, pero no se requiere
--                   ese modulo aqui: el tablero no sabe de pantallas)
--   colores         cuantas familias de galleta entran en juego (4..6)
--   semilla         entero
--   mascara         funcion(c, r) -> bool, que casillas existen
--   barro           funcion(c, r) -> 0|1|2, capas de barro
--   hielo           funcion(c, r) -> bool, que casillas empiezan congeladas
--   pastillas           cuantos pastillas hay que soltar en todo el nivel
--   pastillasALaVez cuantas pueden estar en el bol a la vez (2 por defecto)
--   mods            mejoras del arcade (ver Board.MODS); sin ellas, el juego
--                   de siempre
function Board.nuevo(opts)
    opts = opts or {}
    local b = setmetatable({}, Board)
    b.cols = opts.cols or 8
    b.rows = opts.rows or 8
    b.colores = opts.colores or 6
    b.rnd = Util.rng(opts.semilla or 1)
    b.siguienteId = 1

    -- Las mejoras se COPIAN una a una desde los valores de serie: asi el
    -- tablero siempre tiene los nueve numeros puestos y nada de lo de abajo
    -- tiene que preguntar si existen. Y quien las pasa no se queda con una
    -- tabla que el tablero pueda cambiarle por detras.
    b.mods = {}
    for clave, valor in pairs(Board.MODS) do
        local dado = opts.mods and opts.mods[clave]
        if type(valor) == "table" then
            -- Las que son tabla se copian ENTRADA A ENTRADA. Quedarse con la
            -- que viene de fuera seria dejar que el arcade cambie los puntos
            -- de una partida a media ronda sin que nadie lo vea venir.
            local copia = {}
            for k, v in pairs(dado or {}) do copia[k] = v end
            b.mods[clave] = copia
        else
            b.mods[clave] = dado or valor
        end
    end

    b.celdas, b.mascara, b.barro, b.hieloInicial, b.moho = {}, {}, {}, {}, {}
    for r = 1, b.rows do
        for c = 1, b.cols do
            local i = (r - 1) * b.cols + c
            b.mascara[i] = (not opts.mascara) or opts.mascara(c, r) and true or false
            b.barro[i] = b.mascara[i] and (opts.barro and opts.barro(c, r) or 0) or 0
            -- El moho empieza donde diga el dibujo y a partir de ahi se lo
            -- monta solo (`crecerMoho`). Va en el suelo, como el barro.
            b.moho[i] = b.mascara[i] and (opts.moho and opts.moho(c, r) or false) or false
            -- El hielo es de la GALLETA y no de la casilla: el cubito cae con
            -- lo que hay dentro. Esta mascara dice solo donde empieza el
            -- reparto congelado, y no se vuelve a mirar despues.
            b.hieloInicial[i] = b.mascara[i] and (opts.hielo and opts.hielo(c, r) or false) or false
            b.celdas[i] = false
        end
    end

    -- La racha de color: que color llevaba la resolucion anterior y cuantas
    -- veces seguidas se ha repetido. Es el unico recuerdo que tiene el tablero
    -- de lo que ya paso, y vive aqui y no en la pantalla por la razon de
    -- siempre: es una regla, y una regla que la pantalla tuviera que llevar de
    -- la mano se rompe el dia que alguien resuelva el tablero desde otro sitio
    -- (la prueba lo hace, sin pantalla ninguna).
    b.colorRacha = nil
    b.eslabones = 0

    -- Las jugadas que lleva el moho sin extenderse. Es el otro recuerdo del
    -- tablero, y esta aqui por lo mismo que el de la racha de color: es una
    -- regla, y una regla que llevara la pantalla no se podria probar sin ella.
    b.mohoCuenta = 0

    b.pastillasPorSoltar = opts.pastillas or 0
    b.pastillasEnTablero = 0
    b.pastillasRecogidas = 0
    -- Dos a la vez como mucho: tres pastillas cayendo por columnas distintas
    -- bloquean el tablero de verdad, y el jugador no tiene forma de saber que
    -- le van a caer.
    --
    -- Se puede subir desde fuera, y el arcade lo hace en sus rondas de reto.
    -- Ahi el bol lleva movimientos de sobra para desatascarse y lo que decide
    -- la ronda es por DONDE cae la pastilla: con dos en el bol hay dos caminos
    -- y con tres hay tres, y eso se nota (medido: la ronda pasa del 60% al 70%
    -- con una pastilla, y del 60% al 80% con dos).
    b.pastillasALaVez = opts.pastillasALaVez or 2

    b:rellenarInicial()
    return b
end

function Board:idx(c, r)
    if c < 1 or c > self.cols or r < 1 or r > self.rows then return nil end
    return (r - 1) * self.cols + c
end

function Board:cr(i)
    local r = math.floor((i - 1) / self.cols) + 1
    return i - (r - 1) * self.cols, r
end

function Board:hueco(i) return self.mascara[i] end

function Board:en(c, r)
    local i = self:idx(c, r)
    return i and self.celdas[i] or false
end

function Board:nuevaGalleta(color)
    local id = self.siguienteId
    self.siguienteId = id + 1
    return { color = color or Util.dado(self.rnd, self.colores), id = id }
end

-- La galleta que entra por la boca de la columna, con la mejora de suerte:
-- puede bajar con una especial ya puesta.
--
-- El sorteo se salta ENTERO cuando la suerte es cero, y eso no es un atajo de
-- velocidad: el generador es el mismo para todo el tablero, asi que tirar un
-- dado de mas por cada galleta que entra cambiaria el reparto de una partida de
-- la campana. Una semilla tiene que dar el mismo tablero hoy que ayer.
function Board:_bendecir(cel)
    if self.mods.suerte <= 0 then return cel end
    if self.rnd() >= self.mods.suerte then return cel end
    cel.especial = Board.REGALOS[Util.dado(self.rnd, #Board.REGALOS)]
    return cel
end

-- Una casilla con cubito. La preguntan la pantalla (para no dejar que el dedo
-- la arrastre) y el simulador de balance (para apuntar a sus vecinas).
-- Lo que vale una galleta y lo que vale una capa, ya con las mejoras encima.
-- Se preguntan y no se escriben a mano en cada suma: son cuatro sitios y la
-- forma de que un dia se olvide una es tenerla escrita cuatro veces.
--
-- La galleta se pregunta POR COLOR. Sin color -- no todo lo que muere lo tiene
-- -- vale lo de siempre.
function Board:valorGalleta(color)
    return Board.PUNTOS.galleta + (color and self.mods.galletas[color] or 0)
end
function Board:valorBarro()  return Board.PUNTOS.barro  + self.mods.barro  end
function Board:valorHielo()  return Board.PUNTOS.hielo  + self.mods.barro  end
-- El moho paga como el barro y sube con la misma mejora (la fregona): las tres
-- cosas que se limpian del bol se cobran juntas, que es lo que hace que una
-- carta que paga por limpiar diga una sola cosa.
function Board:valorMoho()   return Board.PUNTOS.moho   + self.mods.barro  end

-- Quitar barro de una casilla y cobrarlo. Devuelve los puntos, y cero si no
-- habia barro. Esta escrito una vez porque el barro se limpia desde TRES
-- sitios (una casilla vacia por la que pasa un rayo, una galleta que muere
-- encima, y la casilla donde nace una especial) y una mejora de capas que se
-- aplicara solo en dos de los tres seria justo la clase de regla que no se ve
-- fallar: el bol se limpia igual, solo que mas despacio.
function Board:_limpiarBarro(idx, onda)
    local capas = self.barro[idx] or 0
    if capas <= 0 then return 0 end
    local quita = math.min(capas, 1 + self.mods.capas)
    self.barro[idx] = capas - quita
    onda.barro = onda.barro or {}
    onda.barro[#onda.barro + 1] = idx
    return quita * self:valorBarro()
end

-- El moho se quita de UN golpe y no por capas, y el estropajo (la mejora de
-- capas) no le hace nada: lo que cuesta del moho no es pelarlo, es llegar
-- antes de que se haya extendido. Una segunda capa solo lo convertiria en
-- barro que ademas crece, que son dos estorbos en uno y ninguno se lee.
function Board:_limpiarMoho(idx, onda)
    if not self.moho[idx] then return 0 end
    self.moho[idx] = false
    onda.moho = onda.moho or {}
    onda.moho[#onda.moho + 1] = idx
    return self:valorMoho()
end

-- En cuantos trozos se parte una estrella. Tres de serie y uno mas por cada
-- mejora de las suyas.
function Board:trozosEstrella() return Board.ESTRELLAS + self.mods.estrellas end

-- El tope del multiplicador de cascada de este tablero.
function Board:topeCascada() return Board.CASCADA_MAX + self.mods.cascada end

function Board:congelada(i)
    local cel = i and self.celdas[i]
    return (cel and cel.hielo) and true or false
end

function Board:nuevaPastilla()
    local id = self.siguienteId
    self.siguienteId = id + 1
    return { pastilla = true, id = id }
end

--== Rachas y grupos =======================================================

-- Dos casillas casan si las dos tienen color y es el mismo. Una pelota o una
-- pastilla no casan con nada: no tienen color, y eso corta la racha sin ningun
-- caso especial escrito.
local function casan(a, b)
    if not (a and b) then return false end
    -- Una galleta dentro de un cubito no casa. Tiene color y se ve, pero esta
    -- encerrada: dejarla casar seria dejar que se rompiera sola, y entonces el
    -- hielo no estorbaria nada.
    if a.hielo or b.hielo then return false end
    return a.color and b.color and a.color == b.color
end

-- Todas las rachas de 3 o mas, en fila y en columna. Cada racha es
-- { celdas = {i,...}, dir = "h"|"v", color = n }.
function Board:rachas()
    local out = {}

    -- `dir` entra como argumento y no se deduce despues: una racha de tres
    -- es igual de larga mirada por fila que por columna, y la unica manera de
    -- saber cual es cual es quien la encontro.
    local function barrer(lista, dir)
        local inicio = 1
        while inicio <= #lista do
            local fin = inicio
            while fin < #lista and casan(self.celdas[lista[fin]], self.celdas[lista[fin + 1]]) do
                fin = fin + 1
            end
            if fin - inicio + 1 >= 3 then
                local celdas = {}
                for k = inicio, fin do celdas[#celdas + 1] = lista[k] end
                out[#out + 1] = { celdas = celdas, dir = dir,
                                  color = self.celdas[lista[inicio]].color }
            end
            inicio = fin + 1
        end
    end

    for r = 1, self.rows do
        local fila = {}
        for c = 1, self.cols do
            local i = self:idx(c, r)
            -- Un agujero del tablero parte la fila en dos: una racha no puede
            -- saltar por encima de una casilla que no existe.
            if self.mascara[i] and self.celdas[i] then
                fila[#fila + 1] = i
            else
                barrer(fila, "h"); fila = {}
            end
        end
        barrer(fila, "h")
    end

    for c = 1, self.cols do
        local col = {}
        for r = 1, self.rows do
            local i = self:idx(c, r)
            if self.mascara[i] and self.celdas[i] then
                col[#col + 1] = i
            else
                barrer(col, "v"); col = {}
            end
        end
        barrer(col, "v")
    end

    return out
end

-- Los CUADRADOS de dos por dos, que son los que dan ESTRELLA. No se pueden
-- encontrar barriendo filas y columnas como las rachas: cuatro galletas en
-- cuadro no hacen tres en linea en ninguna direccion, y ese hueco es justo el
-- que la estrella viene a llenar.
--
-- `ocupadas` son las casillas que ya se ha llevado una racha. Un cuadrado que
-- toque una racha NO cuenta: es la misma jugada y ya tiene premio, y cobrarlo
-- dos veces daria dos especiales por un movimiento -- lo mismo que `grupos`
-- evita al fundir las rachas cruzadas.
function Board:cuadrados(ocupadas)
    local out, usadas = {}, {}
    for r = 1, self.rows - 1 do
        for c = 1, self.cols - 1 do
            local esquinas = { self:idx(c, r), self:idx(c + 1, r),
                               self:idx(c, r + 1), self:idx(c + 1, r + 1) }
            local vale = true
            for _, i in ipairs(esquinas) do
                -- Sin mascara no hay cuadrado: un agujero en una esquina lo
                -- parte igual que parte una fila.
                if not self.mascara[i] or usadas[i] or (ocupadas and ocupadas[i]) then
                    vale = false
                    break
                end
            end
            if vale then
                local a = self.celdas[esquinas[1]]
                for k = 2, 4 do
                    if not casan(a, self.celdas[esquinas[k]]) then vale = false break end
                end
            end
            if vale then
                -- `usadas` es lo que impide que un bloque de dos por tres se
                -- cuente como dos cuadrados solapados y pague dos estrellas.
                for _, i in ipairs(esquinas) do usadas[i] = true end
                out[#out + 1] = { celdas = esquinas, color = self.celdas[esquinas[1]].color }
            end
        end
    end
    return out
end

-- Si esta casilla forma parte de algun cuadrado. Lo pregunta `jugada`, que
-- tiene que decir si un intercambio vale ANTES de tocar el tablero: sin esto,
-- el movimiento cuyo unico resultado es un dos por dos se rechazaria por no
-- casar nada y la estrella no se podria hacer a proposito -- solo por suerte,
-- de rebote en una cascada.
--
-- Mira las cuatro ventanas que pasan por la casilla en vez de barrer el
-- tablero entero, que es lo que lo hace barato: `hayJugada` llama a `jugada`
-- por cada pareja de vecinas del tablero.
function Board:cuadradoEn(i)
    local c, r = self:cr(i)
    for dc = -1, 0 do
        for dr = -1, 0 do
            local esquinas = { self:idx(c + dc, r + dr), self:idx(c + dc + 1, r + dr),
                               self:idx(c + dc, r + dr + 1), self:idx(c + dc + 1, r + dr + 1) }
            local vale = true
            for _, k in ipairs(esquinas) do
                if not (k and self.mascara[k]) then vale = false break end
            end
            if vale then
                local a = self.celdas[esquinas[1]]
                for k = 2, 4 do
                    if not casan(a, self.celdas[esquinas[k]]) then vale = false break end
                end
                if vale then return true end
            end
        end
    end
    return false
end

-- Lo que no puede quedar en pie en un reparto recien hecho: las rachas y los
-- cuadrados. Los dos regalan un premio que el jugador no ha jugado, asi que el
-- reparto inicial y el barajado los deshacen igual y por eso se cuentan
-- juntos. Cada sobra trae sus `celdas`, que es lo unico que mira quien las
-- deshace.
function Board:sobras()
    local out = self:rachas()
    for _, q in ipairs(self:cuadrados()) do
        out[#out + 1] = { celdas = q.celdas, color = q.color }
    end
    return out
end

-- Las rachas que comparten casilla son la MISMA jugada: una T de cinco es una
-- racha de tres y una de tres cruzadas, y darle dos premios seria darle dos
-- especiales por un movimiento.
function Board:grupos()
    local rachas = self:rachas()
    local grupos = {}

    for _, racha in ipairs(rachas) do
        local destino = nil
        for _, g in ipairs(grupos) do
            if g.color == racha.color then
                for _, i in ipairs(racha.celdas) do
                    if g.set[i] then destino = g break end
                end
            end
            if destino then break end
        end
        if not destino then
            destino = { color = racha.color, set = {}, celdas = {}, rachas = {} }
            grupos[#grupos + 1] = destino
        end
        destino.rachas[#destino.rachas + 1] = racha
        for _, i in ipairs(racha.celdas) do
            if not destino.set[i] then
                destino.set[i] = true
                destino.celdas[#destino.celdas + 1] = i
            end
        end
    end

    -- Fusion en segunda pasada: una racha puede haber tocado dos grupos que
    -- hasta entonces no se conocian (una cruz formada por tres rachas).
    local cambiado = true
    while cambiado do
        cambiado = false
        for a = #grupos, 2, -1 do
            for bIdx = a - 1, 1, -1 do
                local ga, gb = grupos[a], grupos[bIdx]
                if ga.color == gb.color then
                    local tocan = false
                    for _, i in ipairs(ga.celdas) do
                        if gb.set[i] then tocan = true break end
                    end
                    if tocan then
                        for _, i in ipairs(ga.celdas) do
                            if not gb.set[i] then
                                gb.set[i] = true
                                gb.celdas[#gb.celdas + 1] = i
                            end
                        end
                        for _, racha in ipairs(ga.rachas) do
                            gb.rachas[#gb.rachas + 1] = racha
                        end
                        table.remove(grupos, a)
                        cambiado = true
                        break
                    end
                end
            end
            if cambiado then break end
        end
    end

    -- Y los cuadrados, que llegan ya cerrados: un dos por dos no se funde con
    -- nada -- si tocara una racha no estaria en la lista -- asi que entra como
    -- un grupo mas, sin rachas dentro y con la marca que lee `premio`.
    local ocupadas = {}
    for _, g in ipairs(grupos) do
        for _, i in ipairs(g.celdas) do ocupadas[i] = true end
    end
    for _, q in ipairs(self:cuadrados(ocupadas)) do
        local set = {}
        for _, i in ipairs(q.celdas) do set[i] = true end
        grupos[#grupos + 1] = { color = q.color, set = set, celdas = q.celdas,
                                rachas = {}, cuadrado = true }
    end

    return grupos
end

-- El premio de un grupo, y donde se pone.
--
-- Las reglas son las del original con una sola desviacion, deliberada: la
-- raya sale PARALELA a la racha que la ha creado (cuatro en fila -> raya
-- horizontal, que limpia la fila). En el original depende del sentido del
-- dedo y no de la racha, y eso deja al jugador sin forma de saber que va a
-- salir mirando el tablero. Aqui las rayas del dibujo apuntan a donde va a
-- disparar, y eso se puede leer.
--
-- La racha mas larga de un grupo y hacia donde va. Un cuadrado no tiene
-- ninguna y mide cero. Esta aparte porque la miran dos: el premio (que sale
-- de ella) y el bonus de las mejoras del arcade, que paga por casar cuatro o
-- cinco.
local function mayorRacha(grupo)
    local mayor, dirMayor = 0, "h"
    for _, racha in ipairs(grupo.rachas) do
        if #racha.celdas > mayor then
            mayor, dirMayor = #racha.celdas, racha.dir
        end
    end
    return mayor, dirMayor
end

-- Es de modulo y no local porque la pregunta "que saldria de esta jugada" se
-- hace desde fuera: el jugador de mentira que BUSCA especiales
-- (`tests/jugador.lua`) la necesita para elegir, y la alternativa era
-- reescribir aqui mismo la tabla de premios en un archivo de pruebas. Una
-- regla escrita dos veces es una regla que un dia dice dos cosas.
function Board.premio(grupo)
    -- El cuadrado de dos por dos da ESTRELLA, y se mira lo primero: un grupo de
    -- cuadrado no tiene rachas que medir, asi que todo lo de abajo no le sirve.
    if grupo.cuadrado then return "estrella" end

    local mayor, dirMayor = mayorRacha(grupo)
    if mayor >= 5 then return "pelota" end
    if #grupo.rachas >= 2 and #grupo.celdas >= 5 then return "envuelta" end
    if mayor == 4 then return dirMayor == "h" and "rayaH" or "rayaV" end
    return nil
end

--== Movimientos ===========================================================

function Board:adyacentes(i, j)
    local c1, r1 = self:cr(i)
    local c2, r2 = self:cr(j)
    return math.abs(c1 - c2) + math.abs(r1 - r2) == 1
end

-- Que tipo de jugada es intercambiar i y j, sin tocar el tablero.
-- Devuelve "normal", "combo" o nil.
function Board:jugada(i, j)
    if not (self.mascara[i] and self.mascara[j]) then return nil end
    if not self:adyacentes(i, j) then return nil end
    local a, b = self.celdas[i], self.celdas[j]
    if not (a and b) then return nil end
    if a.pastilla or b.pastilla then return nil end   -- no se mueve con el dedo
    if a.hielo or b.hielo then return nil end         -- ni el cubito, ni lo de dentro

    -- Dos especiales juntas, o una pelota con lo que sea, siempre valen:
    -- no necesitan casar nada.
    if a.especial and b.especial then return "combo" end
    if a.especial == "pelota" or b.especial == "pelota" then return "combo" end

    self.celdas[i], self.celdas[j] = b, a
    -- El cuadrado vale como jugada igual que la racha. Tiene que preguntarse
    -- aqui: es la unica forma de cuatro que el barrido de filas y columnas no
    -- ve, y sin esta linea el movimiento que hace una estrella se rechazaria
    -- por no casar nada.
    local hay = #self:rachas() > 0 or self:cuadradoEn(i) or self:cuadradoEn(j)
    self.celdas[i], self.celdas[j] = a, b
    return hay and "normal" or nil
end

-- Los grupos que casaria intercambiar i y j, sin tocar el tablero: uno por
-- grupo, con su premio, su color y cuantas casillas tiene. Es lo que ensena el
-- preview del arcade antes de soltar el dedo.
function Board:gruposDeIntercambio(i, j)
    self.celdas[i], self.celdas[j] = self.celdas[j], self.celdas[i]
    local out = {}
    for _, g in ipairs(self:grupos()) do
        out[#out + 1] = { premio = Board.premio(g), color = g.color, n = #g.celdas }
    end
    self.celdas[i], self.celdas[j] = self.celdas[j], self.celdas[i]
    return out
end

function Board:intercambiar(i, j)
    self.celdas[i], self.celdas[j] = self.celdas[j], self.celdas[i]
end

-- Un movimiento posible, si lo hay. Devuelve i, j.
function Board:hayJugada()
    for r = 1, self.rows do
        for c = 1, self.cols do
            local i = self:idx(c, r)
            local der = c < self.cols and self:idx(c + 1, r) or nil
            local aba = r < self.rows and self:idx(c, r + 1) or nil
            if der and self:jugada(i, der) then return i, der end
            if aba and self:jugada(i, aba) then return i, aba end
        end
    end
    return nil
end

--== Areas de las especiales ===============================================

-- A quien se lleva por delante una especial al detonar. Devuelve una lista de
-- indices, incluida la casilla de origen.
--
-- `destinos` solo lo usa la estrella, y viene de fuera a proposito: es lo unico
-- que esta funcion no puede calcular dos veces -- se eligen al azar, y
-- calcularlos aqui daria una lista distinta de la que la pantalla dibuja
-- volando.
function Board:area(i, tipo, colorObjetivo, destinos)
    local c, r = self:cr(i)
    local out = {}

    -- La mecha convierte cualquier rayada en una cruz. Se traduce AQUI, que es
    -- el unico sitio donde se decide a quien se lleva una especial por delante:
    -- hacerlo al crearla cambiaria el sprite (la rayada dibuja sus rayas hacia
    -- donde dispara) y hacerlo en la pantalla seria una regla fuera del
    -- tablero.
    if self.mods.mecha and (tipo == "rayaH" or tipo == "rayaV") then tipo = "cruz" end
    local function mete(idx)
        if idx and self.mascara[idx] then out[#out + 1] = idx end
    end

    if tipo == "rayaH" then
        for cc = 1, self.cols do mete(self:idx(cc, r)) end
    elseif tipo == "rayaV" then
        for rr = 1, self.rows do mete(self:idx(c, rr)) end
    elseif tipo == "envuelta" then
        -- El radio de serie es uno (tres por tres) y las mejoras lo engordan.
        -- Es el mismo numero para las tres explosiones con forma, y por eso se
        -- lee de un sitio: una polvora que agrandara la envuelta pero no el
        -- bombazo seria una regla que hay que memorizar.
        local radio = 1 + self.mods.radio
        for rr = r - radio, r + radio do
            for cc = c - radio, c + radio do mete(self:idx(cc, rr)) end
        end
    elseif tipo == "cruz" then
        for cc = 1, self.cols do mete(self:idx(cc, r)) end
        for rr = 1, self.rows do mete(self:idx(c, rr)) end
    elseif tipo == "cruzGorda" then
        -- Raya + envuelta: tres filas y tres columnas. Es la unica jugada del
        -- juego que puede limpiar medio tablero de un golpe y por eso la
        -- pantalla le da su propio rugido.
        local radio = 1 + self.mods.radio
        for rr = r - radio, r + radio do
            for cc = 1, self.cols do mete(self:idx(cc, rr)) end
        end
        for cc = c - radio, c + radio do
            for rr = 1, self.rows do mete(self:idx(cc, rr)) end
        end
    elseif tipo == "bombazo" then
        local radio = 2 + self.mods.radio
        for rr = r - radio, r + radio do
            for cc = c - radio, c + radio do mete(self:idx(cc, rr)) end
        end
    elseif tipo == "color" then
        for idx = 1, self.cols * self.rows do
            local cel = self.celdas[idx]
            if self.mascara[idx] and cel and cel.color == colorObjetivo then mete(idx) end
        end
        mete(i)
    elseif tipo == "estrella" then
        -- La estrella no tiene forma: son tres viajes. Muere ella y mueren las
        -- tres casillas a las que llega, y nada de lo que hay en medio -- que
        -- es lo que la distingue de un rayo y lo que la hace util en un
        -- tablero donde lo que estorba no esta en su fila.
        mete(i)
        for _, idx in ipairs(destinos or {}) do mete(idx) end
    elseif tipo == "todo" then
        for idx = 1, self.cols * self.rows do mete(idx) end
    end
    return out
end

-- El color mas repartido del tablero. Es a lo que apunta una pelota que
-- detona sin que nadie le haya dicho un color (la ha reventado una explosion
-- de al lado): ir a por el que mas hay es lo que mas se parece a lo que el
-- jugador habria elegido.
function Board:colorMasComun()
    local cuenta, mejor, mejorN = {}, nil, -1
    for i = 1, self.cols * self.rows do
        local cel = self.celdas[i]
        if cel and cel.color then
            cuenta[cel.color] = (cuenta[cel.color] or 0) + 1
            if cuenta[cel.color] > mejorN then mejor, mejorN = cel.color, cuenta[cel.color] end
        end
    end
    return mejor
end

-- A donde van los trozos de una estrella. Devuelve una lista de casillas, una
-- por trozo, sin repetir y sin contar la suya.
--
-- Van a por SU color, que es lo que hace que la estrella se pueda usar con
-- intencion: el jugador ve de que color es y sabe que va a limpiar. Y entre
-- las de su color, primero las que tienen BARRO debajo -- una estrella que
-- elige a ciegas se lee como un premio que se gasta solo, y apuntando al barro
-- se lee como que ha ido a por lo que estorbaba, que es lo que el jugador
-- queria de ella.
--
-- Si de su color no queda bastante (una cascada larga se puede haber llevado
-- la familia entera), completa con lo que haya: una estrella que se queda
-- quieta por no encontrar su color se ve como un premio roto.
--
-- `excluir` son casillas que no valen como destino aunque sigan ahi. Lo usa el
-- combo, que sabe que su pareja va a morir en la onda de antes: un trozo que
-- saliera a por ella se veria volar hacia un hueco.
function Board:destinosEstrella(origen, color, cuantas, excluir)
    cuantas = cuantas or self:trozosEstrella()
    local sucias, suyas, otras = {}, {}, {}
    for idx = 1, self.cols * self.rows do
        local cel = self.celdas[idx]
        if idx ~= origen and not (excluir and excluir[idx])
           and self.mascara[idx] and cel and cel.color then
            if cel.color ~= color then
                otras[#otras + 1] = idx
            elseif (self.barro[idx] or 0) > 0 then
                sucias[#sucias + 1] = idx
            else
                suyas[#suyas + 1] = idx
            end
        end
    end

    local out = {}
    for _, lista in ipairs({ sucias, suyas, otras }) do
        Util.barajar(lista, self.rnd)
        for _, idx in ipairs(lista) do
            if #out >= cuantas then return out end
            out[#out + 1] = idx
        end
    end
    return out
end

--== Detonaciones ==========================================================

-- El corazon del juego: quitar un puñado de casillas y dejar que lo que haya
-- dentro encadene. `semillas` es la lista de indices que mueren de entrada;
-- `protegidas` son las que NO se quitan aunque esten en la lista (la casilla
-- donde va a nacer una especial).
--
-- Devuelve las ondas y los puntos. Cada onda es
--   { celdas = { {i=, color=, especial=, pastilla=}, ... },
--     fuentes = { {i=, tipo=}, ... },
--     barro = { i, ... }, hielo = { {i=, id=}, ... } }
-- `fuentes` es lo que ha disparado esa onda, para que la pantalla sepa donde
-- nace el rayo o la explosion. La de una estrella lleva ademas sus `destinos`:
-- son las casillas a las que vuela cada trozo, y sin ellas la pantalla no
-- tendria por donde dibujar el viaje. `hielo` son los cubitos que se han roto en esa
-- onda: van con su `id` porque lo que hay que descongelar en pantalla es una
-- PIEZA, y las piezas se buscan por id y nunca por casilla.
function Board:_detonar(semillas, protegidas, multiplicador)
    multiplicador = multiplicador or 1
    protegidas = protegidas or {}
    local muertas, ondas, puntos = {}, {}, 0

    -- Romper el hielo de una casilla. Es idempotente a proposito: en la misma
    -- onda le puede llegar el golpe directo del rayo y la muerte de una
    -- vecina, y eso es un cubito roto, no dos.
    local function descongelar(idx, onda)
        local cel = self.celdas[idx]
        if not (cel and cel.hielo) then return false end
        cel.hielo = nil
        puntos = puntos + self:valorHielo() * multiplicador
        onda.hielo = onda.hielo or {}
        onda.hielo[#onda.hielo + 1] = { i = idx, id = cel.id }
        return true
    end

    local function quitar(idx, onda)
        if muertas[idx] or protegidas[idx] then return nil end
        local cel = self.celdas[idx]
        if not cel then
            -- Aunque no haya galleta, el barro de debajo si se lleva el
            -- golpe: un rayo que cruza una casilla vacia la limpia igual. Y el
            -- moho con el: es suelo, como el barro.
            puntos = puntos + self:_limpiarBarro(idx, onda) * multiplicador
            puntos = puntos + self:_limpiarMoho(idx, onda) * multiplicador
            return nil
        end
        if cel.hielo then
            -- El golpe se lo lleva el HIELO y no lo que hay dentro: el cubito
            -- se rompe, la galleta se queda y el barro de debajo tambien. Es lo
            -- que hace que un cubito sobre barro sean dos jugadas y no una, y
            -- lo que evita que una envuelta regale media pantalla de cubitos
            -- rotos con sus galletas por delante.
            descongelar(idx, onda)
            return nil
        end
        muertas[idx] = true
        self.celdas[idx] = false
        if cel.pastilla then
            -- Una pastilla no se rompe: se queda donde estaba. Explotarla seria
            -- regalar el objetivo del nivel con una envuelta.
            self.celdas[idx] = cel
            muertas[idx] = nil
            return nil
        end
        puntos = puntos + self:valorGalleta(cel.color) * multiplicador
        puntos = puntos + self:_limpiarBarro(idx, onda) * multiplicador
        puntos = puntos + self:_limpiarMoho(idx, onda) * multiplicador
        -- El `id` viaja con el suceso y no es un adorno: la pantalla borra
        -- piezas POR ID, y sin el tendria que adivinar cual estaba en esa
        -- casilla -- que es como se rompio la primera version, reventando en
        -- pantalla una galleta distinta de la que casaba.
        onda.celdas[#onda.celdas + 1] =
            { i = idx, id = cel.id, color = cel.color, especial = cel.especial }
        return cel
    end

    -- Lo que revienta AL LADO de un cubito lo rompe. Es la unica forma de
    -- quitarlo que no depende de la suerte: la galleta de dentro no casa y no
    -- se deja arrastrar, asi que si el hielo solo se rompiera con golpes
    -- directos, un cubito en una esquina se quedaria ahi toda la partida.
    --
    -- Va por onda y no al final de la cascada porque la pantalla lo anima por
    -- ondas: el cubito tiene que romperse a la vez que revienta su vecina, no
    -- tres ondas despues.
    local vecinas = self.mods.hieloDiagonal and DIAGONALES or VECINAS

    local function romperAlrededor(onda)
        for k = 1, #onda.celdas do
            local c, r = self:cr(onda.celdas[k].i)
            for _, d in ipairs(vecinas) do
                local j = self:idx(c + d[1], r + d[2])
                if j and self.mascara[j] then descongelar(j, onda) end
            end
        end
    end

    -- Onda 1: lo que muere de entrada.
    local onda = { celdas = {}, fuentes = {} }
    local pendientes = {}
    for _, s in ipairs(semillas) do
        local idx = type(s) == "table" and s.i or s
        local tipoForzado = type(s) == "table" and s.tipo or nil
        local cel = quitar(idx, onda)
        if tipoForzado then
            pendientes[#pendientes + 1] = { i = idx, tipo = tipoForzado,
                                            color = type(s) == "table" and s.color or nil,
                                            destinos = type(s) == "table" and s.destinos or nil,
                                            cuantas = type(s) == "table" and s.cuantas or nil,
                                            veces = type(s) == "table" and s.veces or nil }
        elseif cel and cel.especial and not cel.gastada then
            pendientes[#pendientes + 1] = { i = idx, tipo = cel.especial, color = cel.color }
        end
    end
    romperAlrededor(onda)
    ondas[1] = onda

    -- Y las siguientes, mientras las explosiones sigan encontrando especiales.
    -- El tope de 12 no es un numero de diseno, es un cinturon: una cadena mas
    -- larga que eso es un bucle, no una jugada.
    local vuelta = 0
    while #pendientes > 0 and vuelta < 12 do
        vuelta = vuelta + 1
        local siguiente = { celdas = {}, fuentes = {} }
        local nuevos = {}
        for _, p in ipairs(pendientes) do
            local tipo = p.tipo
            local color = p.color
            local destinos = p.destinos
            if tipo == "pelota" then
                color = color or self:colorMasComun()
                tipo = "color"
            elseif tipo == "estrella" then
                -- Los destinos se eligen AQUI, al disparar, y no cuando se
                -- metio la semilla: entre una onda y otra se ha muerto medio
                -- tablero, y una estrella que saliera a por una casilla ya
                -- vacia se veria irse a por nada. Los unicos que vienen dados
                -- son los del combo, que los necesita antes para cargarlos.
                color = color or self:colorMasComun()
                destinos = destinos or self:destinosEstrella(p.i, color, p.cuantas)
            end
            siguiente.fuentes[#siguiente.fuentes + 1] =
                { i = p.i, tipo = p.tipo, color = color, destinos = destinos }
            for _, idx in ipairs(self:area(p.i, tipo, color, destinos)) do
                local cel = quitar(idx, siguiente)
                if cel and cel.especial and not cel.gastada then
                    nuevos[#nuevos + 1] = { i = idx, tipo = cel.especial, color = cel.color }
                end
            end
            -- La envuelta estalla DOS veces, como en el original: la segunda
            -- una onda mas tarde y en el mismo sitio. Es lo que la distingue
            -- de una raya cruzada -- limpia poco pero lo limpia dos veces, y
            -- entre las dos ha caido galleta nueva encima.
            --
            -- Cuantas son sale de las mejoras (dos de serie). Se lleva la
            -- cuenta en la semilla y no con un si/no: con un booleano, "tres
            -- veces" no se puede escribir.
            local veces = p.veces or 1
            if p.tipo == "envuelta" and veces < self.mods.envuelta then
                nuevos[#nuevos + 1] = { i = p.i, tipo = "envuelta", veces = veces + 1 }
            end
        end
        romperAlrededor(siguiente)
        if #siguiente.celdas > 0 or #siguiente.fuentes > 0
           or (siguiente.hielo and #siguiente.hielo > 0) then
            ondas[#ondas + 1] = siguiente
        end
        pendientes = nuevos
    end

    return ondas, puntos
end

--== La ronda ==============================================================

-- Resuelve las rachas que haya EN ESTE momento. `preferidas` son las casillas
-- que ha tocado el jugador (las dos del intercambio, o ninguna en una
-- cascada): si una entra en un grupo, la especial nace ahi, que es donde el
-- jugador esta mirando. Sin esto, la especial aparece en el centro de la racha
-- y se lee como que ha salido sola.
--
-- Acepta un indice suelto o una lista.
--
-- Devuelve nil si no hay nada que resolver.
function Board:resolver(preferidas, cascada)
    local grupos = self:grupos()
    if #grupos == 0 then return nil end

    if type(preferidas) == "number" then preferidas = { preferidas } end
    preferidas = preferidas or {}

    local multiplicador = math.min(cascada or 1, self:topeCascada())
    local semillas, protegidas, creadas = {}, {}, {}
    -- Las formas que se han casado, una por grupo. La campana no las mira; el
    -- arcade puntua con ellas (`src/puntuacion.lua`), y se sacan aqui porque
    -- el premio de un grupo es una regla del tablero.
    local formas = {}

    -- El bonus de las mejoras: un premio suelto por casar cuatro o cinco, que
    -- se cobra UNA vez por grupo y no una por galleta. Es lo que hace que una
    -- mejora de racha se note al buscar la jugada larga en vez de al romper
    -- mucho, que es lo que ya paga la galleta.
    local bonus = 0

    -- La racha de color, que es el unico premio de este tablero que depende de
    -- lo que hiciste ANTES. Se mide por resolucion y no por grupo: dos rachas
    -- de fresa en el mismo paso son UNA jugada de fresa, igual que una T de
    -- cinco es un grupo y no dos. Y cuenta igual entre dos movimientos que
    -- entre dos pasos de una cascada, que es lo que hace que perseguir un
    -- color sea un plan y no una casualidad.
    --
    -- `sigue` mira si ese color muere AQUI, no si es el unico que muere: una
    -- cascada que se lleva fresa y menta a la vez no rompe la racha de fresa.
    -- Cortarla ahi castigaria al jugador por lo que caiga del cielo, que es
    -- justo lo que no decide el.
    local sigue, mayorColor, mayorCeldas = false, nil, 0

    for _, g in ipairs(grupos) do
        local tipo = Board.premio(g)
        local largo = mayorRacha(g)
        formas[#formas + 1] = { premio = tipo, color = g.color, n = #g.celdas }
        if largo >= 5 then bonus = bonus + self.mods.racha5
        elseif largo == 4 then bonus = bonus + self.mods.racha4 end
        if g.color == self.colorRacha then sigue = true end
        if #g.celdas > mayorCeldas then mayorColor, mayorCeldas = g.color, #g.celdas end
        local donde = nil
        if tipo then
            for _, pref in ipairs(preferidas) do
                if g.set[pref] then donde = pref break end
            end
            if not donde and #g.rachas == 0 then
                -- Un cuadrado no tiene racha mas larga que medir y sus cuatro
                -- esquinas estan igual de cerca del ojo: nace en la primera,
                -- que es la de arriba a la izquierda.
                donde = g.celdas[1]
            elseif not donde then
                -- El centro de la racha mas larga: es donde el ojo esta.
                local mayor = g.rachas[1]
                for _, racha in ipairs(g.rachas) do
                    if #racha.celdas > #mayor.celdas then mayor = racha end
                end
                donde = mayor.celdas[math.ceil(#mayor.celdas / 2)]
            end
            protegidas[donde] = true
            creadas[#creadas + 1] = { i = donde, especial = tipo,
                                      color = tipo == "pelota" and nil or g.color }
        end
        for _, i in ipairs(g.celdas) do semillas[#semillas + 1] = i end
    end

    -- Se apunta ANTES de detonar porque lo que la mueve son los grupos que se
    -- han casado, y no lo que la detonacion se lleve de rebote: una envuelta
    -- que revienta media fila no hace que el jugador este jugando a ese color.
    if sigue then
        self.eslabones = self.eslabones + 1
    else
        -- El color que mas ha roto, que es el que el jugador estaba mirando.
        -- La racha nueva empieza en cero eslabones: la primera fresa no es
        -- repetir nada, repetir es la segunda.
        self.colorRacha = mayorColor
        self.eslabones = 0
    end
    local eslabones = math.min(self.eslabones, Board.RACHA_COLOR_MAX)
    local bonusColor = self.mods.rachaColor * eslabones
    bonus = bonus + bonusColor

    local ondas, puntos = self:_detonar(semillas, protegidas, multiplicador)
    puntos = puntos + bonus * multiplicador

    -- Las especiales nacen DESPUES de que su grupo haya muerto, y se quedan en
    -- el tablero. La casilla estaba protegida, asi que sigue teniendo su
    -- galleta vieja: se le cambia la especial encima y conserva el `id`, que es
    -- lo que hace que la pantalla la vea crecer en vez de aparecer.
    for _, nueva in ipairs(creadas) do
        local cel = self.celdas[nueva.i] or self:nuevaGalleta(nueva.color)
        cel.color = nueva.color
        cel.especial = nueva.especial
        self.celdas[nueva.i] = cel
        nueva.id = cel.id
        puntos = puntos + math.floor((Board.PUNTOS.crear[nueva.especial] or 0)
                                     * self.mods.crear) * multiplicador
        -- El barro de debajo de una especial recien nacida tambien se
        -- limpia: la casilla ha reventado igual que sus vecinas.
        puntos = puntos + self:_limpiarBarro(nueva.i, ondas[1]) * multiplicador
    end

    -- `bonusColor` sale ya cobrado (con el multiplicador de la cascada puesto)
    -- porque es lo unico que la pantalla necesita para decidir si ensena el
    -- rotulo de la racha: sin mejora vale cero y no hay rotulo que ensenar. La
    -- pantalla no tiene que preguntar por la mejora ni saber que existe.
    return { ondas = ondas, creadas = creadas, puntos = puntos,
             multiplicador = multiplicador,
             colorRacha = self.colorRacha, eslabones = eslabones,
             bonusColor = bonusColor * multiplicador,
             formas = formas, colorPrincipal = mayorColor }
end

-- Un combo: dos especiales intercambiadas. Ya se han intercambiado en el
-- tablero cuando se llama; `i` es donde ha quedado la que movio el dedo, que
-- es de donde sale el fogonazo.
function Board:combo(i, j, cascada)
    local a, b = self.celdas[i], self.celdas[j]
    if not (a and b) then return nil end
    local multiplicador = math.min(cascada or 1, self:topeCascada())
    local ea, eb = a.especial, b.especial
    local semillas = {}
    -- El color de la jugada, para la afinidad del arcade: al que apunta la
    -- pelota, o el de la especial que ha movido el dedo. Dos pelotas no tienen.
    local colorCombo
    if ea == "pelota" and eb == "pelota" then colorCombo = nil
    elseif ea == "pelota" then colorCombo = b.color
    elseif eb == "pelota" then colorCombo = a.color
    else colorCombo = a.color or b.color end

    local function esRaya(e) return e == "rayaH" or e == "rayaV" end

    -- La especial que NO dispara el combo (la pareja) no se borra a mano: se
    -- marca como gastada y se mete en las semillas. Asi muere con su evento y
    -- la pantalla la ve romperse, en vez de evaporarse sin que nadie la haya
    -- roto. Gastada quiere decir que ya no encadena: su efecto esta dentro del
    -- combo y dispararla otra vez seria cobrarla dos veces.
    local function gastar(idx)
        local cel = self.celdas[idx]
        if cel then cel.gastada = true end
        return idx
    end

    if ea == "pelota" and eb == "pelota" then
        gastar(i); gastar(j)
        semillas = { { i = i, tipo = "todo" } }
    elseif ea == "pelota" or eb == "pelota" then
        local otra    = (ea == "pelota") and b or a
        local dondeP  = (ea == "pelota") and i or j
        local dondeO  = (ea == "pelota") and j or i
        if otra.especial and otra.especial ~= "pelota" then
            -- Pelota con especial: TODAS las de ese color se vuelven esa
            -- especial y estallan. Es la jugada mas cara del juego y tiene que
            -- verse asi: el tablero entero se enciende antes de romperse.
            local color = otra.color
            local tocadas = {}
            for idx = 1, self.cols * self.rows do
                local cel = self.celdas[idx]
                -- Lo que esta dentro de un cubito no se convierte: no se
                -- puede tocar, asi que tampoco se puede reclutar.
                if cel and cel.color == color and not cel.especial and not cel.hielo then
                    cel.especial = otra.especial
                    if otra.especial == "rayaH" and idx % 2 == 0 then cel.especial = "rayaV" end
                    tocadas[#tocadas + 1] = idx
                end
            end
            semillas = { { i = dondeO, tipo = otra.especial, color = color }, gastar(dondeP) }
            for _, idx in ipairs(tocadas) do semillas[#semillas + 1] = idx end
        else
            -- Pelota con galleta normal: se lleva todo su color.
            semillas = { { i = dondeO, tipo = "color", color = otra.color }, gastar(dondeP) }
        end
    elseif ea == "estrella" and eb == "estrella" then
        -- Dos estrellas: seis viajes en vez de tres. No hace falta inventar
        -- nada -- la estrella ya sabe partirse -- y seis salidas a la vez es
        -- exactamente lo que se espera al juntar dos de algo que se reparte.
        semillas = { { i = i, tipo = "estrella", color = a.color or b.color,
                       cuantas = self:trozosEstrella() * 2 }, gastar(j) }
    elseif ea == "estrella" or eb == "estrella" then
        -- Estrella con raya o con envuelta: los tres trozos salen CARGADOS con
        -- esa especial y la sueltan donde caen. Es la idea de la pelota con
        -- especial -- convertir y disparar -- pero en tres sitios elegidos en
        -- vez de en un color entero: la estrella apunta, y cargarla es lo que
        -- hace que juntarla con otra valga la pena.
        --
        -- Aqui los destinos SI se eligen antes de detonar, porque hay que
        -- pintarles la especial encima primero. Entre esto y el disparo solo
        -- muere la pareja, asi que ninguno se queda vacio por el camino.
        local estrella = (ea == "estrella") and a or b
        local otra     = (ea == "estrella") and b or a
        local dondeE   = (ea == "estrella") and i or j
        local dondeO   = (ea == "estrella") and j or i
        local destinos = self:destinosEstrella(dondeE, estrella.color, nil,
                                               { [dondeO] = true })
        for _, idx in ipairs(destinos) do
            local cel = self.celdas[idx]
            -- Lo que ya lleva especial se queda con la suya (la cadena la
            -- disparara igual) y lo que esta en un cubito no se toca: no se
            -- puede reclutar lo que no se puede tocar.
            if cel and not cel.especial and not cel.hielo then
                cel.especial = otra.especial
                if otra.especial == "rayaH" and idx % 2 == 0 then cel.especial = "rayaV" end
            end
        end
        semillas = { { i = dondeE, tipo = "estrella", color = estrella.color,
                       destinos = destinos }, gastar(dondeO) }
    elseif esRaya(ea) and esRaya(eb) then
        semillas = { { i = i, tipo = "cruz" }, gastar(j) }
    elseif (esRaya(ea) and eb == "envuelta") or (ea == "envuelta" and esRaya(eb)) then
        semillas = { { i = i, tipo = "cruzGorda" }, gastar(j) }
    elseif ea == "envuelta" and eb == "envuelta" then
        semillas = { { i = i, tipo = "bombazo" }, gastar(j) }
    else
        return nil
    end

    gastar(i)
    local ondas, puntos = self:_detonar(semillas, nil, multiplicador)
    -- La mejora de fusion se cobra sobre el combo ENTERO -- lo que ha reventado
    -- la cadena incluida -- y no sobre una lista de casillas: juntar dos
    -- especiales es una sola jugada, y lo que se mejora es esa jugada.
    puntos = math.floor(puntos * self.mods.combo)
    return { ondas = ondas, creadas = {}, puntos = puntos,
             multiplicador = multiplicador, combo = true,
             pareja = { ea, eb }, color = colorCombo }
end

-- Detonar una especial a dedo, sin intercambio (el remate del final del nivel,
-- y las especiales que se tocan sin mover).
function Board:detonar(i, cascada)
    local cel = self.celdas[i]
    if not (cel and cel.especial) then return nil end
    local multiplicador = math.min(cascada or 1, self:topeCascada())
    local ondas, puntos = self:_detonar({ i }, nil, multiplicador)
    return { ondas = ondas, creadas = {}, puntos = puntos, multiplicador = multiplicador }
end

--== Gravedad ==============================================================

-- Una pasada entera: todo lo que puede caer cae hasta el fondo, y por arriba
-- entra lo que haga falta. Devuelve nil si no se ha movido nada.
--
--   movimientos = { {de=, a=, id=} }
--   apariciones = { {a=, id=, color=, pastilla=, altura=n} }   altura en casillas
--                                                          POR ENCIMA del
--                                                          tablero
--   recogidos   = { {i=, id=} }   pastillas que han llegado al suelo
function Board:gravedad()
    local movimientos, apariciones = {}, {}

    for c = 1, self.cols do
        -- De abajo a arriba: cada casilla vacia se la queda la primera galleta
        -- que haya por encima.
        local destino = nil
        for r = self.rows, 1, -1 do
            local i = self:idx(c, r)
            if not self.mascara[i] then
                destino = nil     -- un agujero corta la columna: nada lo cruza
            elseif not self.celdas[i] then
                destino = destino or i
            elseif destino then
                local cel = self.celdas[i]
                self.celdas[destino] = cel
                self.celdas[i] = false
                movimientos[#movimientos + 1] = { de = i, a = destino, id = cel.id }
                -- El siguiente hueco es el de justo encima del que acabamos de
                -- llenar, si es que existe y es jugable.
                local dc, dr = self:cr(destino)
                destino = self:idx(dc, dr - 1)
                if destino and not self.mascara[destino] then destino = nil end
                if destino and self.celdas[destino] then destino = nil end
            end
        end

        -- Y lo que falte, por la BOCA de la columna: la primera casilla
        -- jugable bajando desde arriba. No es siempre la fila 1 -- un nivel
        -- con forma puede tener las dos de arriba en agujero -- y la boca es
        -- donde se ve caer la galleta nueva.
        --
        -- Solo se rellena el tramo que va de la boca al primer agujero que
        -- haya por debajo. Lo que quede mas abajo de ese agujero esta INCOMUNI-
        -- CADO: no le puede llegar nada desde arriba, y una casilla asi con
        -- barro hace el nivel imposible. `tests/test_board.lua` recorre
        -- todos los niveles comprobando justo eso, que es un fallo que no se
        -- ve leyendo el dibujo del nivel.
        local boca, fin = nil, nil
        for r = 1, self.rows do
            local i = self:idx(c, r)
            if self.mascara[i] then boca = r break end
        end
        if boca then
            fin = self.rows
            for r = boca, self.rows do
                if not self.mascara[self:idx(c, r)] then fin = r - 1 break end
            end
        end

        local altura = 1
        if boca then
            for r = boca, fin do
                local i = self:idx(c, r)
                if not self.celdas[i] then
                    local cel
                    if self.pastillasPorSoltar > 0 and self.pastillasEnTablero < self.pastillasALaVez
                       and self.rnd() < 0.22 then
                        cel = self:nuevaPastilla()
                        self.pastillasPorSoltar = self.pastillasPorSoltar - 1
                        self.pastillasEnTablero = self.pastillasEnTablero + 1
                    else
                        cel = self:_bendecir(self:nuevaGalleta())
                    end
                    self.celdas[i] = cel
                    -- `altura` escalona la entrada: la de mas arriba sale mas
                    -- arriba y llega mas tarde, que es lo que hace que una
                    -- columna vacia se rellene como una cascada y no como una
                    -- fila que aparece de golpe.
                    apariciones[#apariciones + 1] = { a = i, id = cel.id, color = cel.color,
                                                      pastilla = cel.pastilla, altura = altura }
                    altura = altura + 1
                end
            end
        end
    end

    -- Las pastillas que hayan llegado al fondo de su columna se recogen. Se mira
    -- DESPUES de compactar, y la casilla que dejan la rellena la pasada
    -- siguiente: por eso bajar una pastilla encadena una cascada gratis.
    local recogidos = {}
    for c = 1, self.cols do
        local suelo = nil
        for r = self.rows, 1, -1 do
            local i = self:idx(c, r)
            if self.mascara[i] then suelo = i break end
        end
        local cel = suelo and self.celdas[suelo]
        if cel and cel.pastilla then
            self.celdas[suelo] = false
            self.pastillasEnTablero = self.pastillasEnTablero - 1
            self.pastillasRecogidas = self.pastillasRecogidas + 1
            recogidos[#recogidos + 1] = { i = suelo, id = cel.id }
        end
    end

    if #movimientos == 0 and #apariciones == 0 and #recogidos == 0 then return nil end
    return { movimientos = movimientos, apariciones = apariciones, recogidos = recogidos,
             puntos = #recogidos * Board.PUNTOS.pastilla }
end

--== Relleno y barajado ====================================================

-- Reparto inicial: sin rachas hechas (regalarian puntos que el jugador no ha
-- jugado) y con al menos un movimiento posible.
function Board:rellenarInicial()
    local intentos = 0
    repeat
        intentos = intentos + 1
        for i = 1, self.cols * self.rows do
            if self.mascara[i] then
                self.celdas[i] = self:nuevaGalleta()
                -- El hielo se pone AQUI dentro, antes de que el bucle
                -- compruebe que el reparto tiene jugada: un tablero donde la
                -- unica jugada estuviera dentro de un cubito no tiene jugada.
                if self.hieloInicial[i] then self.celdas[i].hielo = true end
            else
                self.celdas[i] = false
            end
        end
        self:deshacerSobras()
    until self:hayJugada() or intentos > 40
end

-- Recolorea lo justo para que no quede ninguna racha NI ningun cuadrado en
-- pie. Los dos se deshacen igual porque los dos son lo mismo: un premio
-- servido en el reparto, que el jugador no ha jugado. Recolorear una casilla
-- puede crear otra sobra al lado, asi que se repite hasta que el tablero esta
-- limpio.
function Board:deshacerSobras()
    local vueltas = 0
    while vueltas < 60 do
        vueltas = vueltas + 1
        local sobras = self:sobras()
        if #sobras == 0 then return end
        for _, racha in ipairs(sobras) do
            local i = racha.celdas[math.ceil(#racha.celdas / 2)]
            local cel = self.celdas[i]
            if cel and cel.color then
                local nuevo = cel.color
                for _ = 1, 8 do
                    nuevo = Util.dado(self.rnd, self.colores)
                    if nuevo ~= cel.color then break end
                end
                cel.color = nuevo
            end
        end
    end
end

-- Baraja los colores que ya hay (no inventa ninguno) hasta que vuelva a haber
-- jugada. Barajar en vez de repartir de cero respeta lo que el jugador tenia
-- guardado: las especiales no se mueven de su casilla y siguen siendo suyas.
--
-- Un barajado a secas casi nunca sirve: en un 8x8 de seis colores, un reparto
-- al azar trae rachas hechas tres de cada cuatro veces, asi que insistir a
-- base de volver a barajar es tirar el dado esperando un 20. Lo que se hace es
-- barajar UNA vez y luego REPARAR, intercambiando las casillas que sobran con
-- otras del tablero: cada intercambio se queda solo si deja menos rachas que
-- antes, que es lo que hace que el arreglo termine en vez de dar vueltas.
function Board:barajar()
    local movibles = {}
    for i = 1, self.cols * self.rows do
        local cel = self.celdas[i]
        -- Ni las especiales ni los cubitos entran en el barajado: las
        -- primeras son del jugador y los segundos no se pueden tocar. Un
        -- cubito que cambiara de color al barajar diria que ahi dentro hay
        -- otra galleta, y ahi dentro hay la misma.
        if self.mascara[i] and cel and cel.color and not cel.especial and not cel.hielo then
            movibles[#movibles + 1] = i
        end
    end
    if #movibles < 3 then return nil end

    local antes = {}
    for _, i in ipairs(movibles) do antes[i] = self.celdas[i].color end

    local function restaurar()
        for _, i in ipairs(movibles) do self.celdas[i].color = antes[i] end
    end

    -- Deshace las sobras a base de intercambios. Devuelve true si ha dejado el
    -- tablero limpio. Cuenta rachas Y cuadrados: un barajado que dejara un dos
    -- por dos hecho regalaria una estrella justo cuando el juego acaba de
    -- decir que no habia jugadas.
    local function reparar()
        for _ = 1, 400 do
            local sobras = self:sobras()
            if #sobras == 0 then return true end
            local cuantas = #sobras
            local racha = sobras[1]
            local i = racha.celdas[math.ceil(#racha.celdas / 2)]
            local mejorado = false
            for _ = 1, 40 do
                local j = movibles[Util.dado(self.rnd, #movibles)]
                local a, bb = self.celdas[i], self.celdas[j]
                if j ~= i and a.color ~= bb.color then
                    a.color, bb.color = bb.color, a.color
                    if #self:sobras() < cuantas then mejorado = true break end
                    a.color, bb.color = bb.color, a.color
                end
            end
            -- Cuarenta parejas y ninguna mejora: este reparto no tiene arreglo
            -- por aqui y vale mas volver a barajar entero.
            if not mejorado then return false end
        end
        return #self:sobras() == 0
    end

    for intento = 1, 12 do
        local colores = {}
        for _, i in ipairs(movibles) do colores[#colores + 1] = antes[i] end
        Util.barajar(colores, self.rnd)
        for k, i in ipairs(movibles) do self.celdas[i].color = colores[k] end

        if reparar() and self:hayJugada() then
            local cambios = {}
            for _, i in ipairs(movibles) do
                cambios[#cambios + 1] = { i = i, color = self.celdas[i].color,
                                          id = self.celdas[i].id }
            end
            return { cambios = cambios, intentos = intento }
        end
    end

    -- Doce repartos sin sacar un tablero jugable (pasa de verdad con dos
    -- colores: no existe): se deja EXACTAMENTE como estaba. Quedarse con el
    -- ultimo revoltijo es peor que no barajar, porque el ultimo es justo el
    -- que acaba de fallar.
    restaurar()
    return nil
end

--== Cuentas del nivel =====================================================

-- Cuantos cubitos quedan sin romper. Es el gemelo de `barroVivo` y esta por
-- la misma razon: hay objetivos que se cumplen cuando esto llega a cero, y
-- contarlo desde la pantalla seria recorrer el tablero desde donde no se
-- pueden leer sus reglas.
function Board:hieloVivo()
    local n = 0
    for i = 1, self.cols * self.rows do
        local cel = self.celdas[i]
        if cel and cel.hielo then n = n + 1 end
    end
    return n
end

function Board:barroVivo()
    local n = 0
    for i = 1, self.cols * self.rows do n = n + (self.barro[i] or 0) end
    return n
end

function Board:mohoVivo()
    local n = 0
    for i = 1, self.cols * self.rows do if self.moho[i] then n = n + 1 end end
    return n
end

-- El moho se extiende: una casilla nueva cada `MOHO_CADA` jugadas, pegada a
-- una que ya lo tenga. Devuelve donde ha brotado, o nil si esta jugada no toca
-- o ya no queda moho.
--
-- Lo llama quien lleve la partida al terminar una jugada -- la pantalla de
-- juego y el jugador de mentira de las pruebas -- igual que llaman a
-- `resolver`, a `gravedad` y a `barajar`. La REGLA entera (cuando, donde,
-- cuanto) esta aqui dentro; lo unico que pone el de fuera es el momento, que
-- es lo que permite medir el moho sin ventana ninguna.
--
-- Tres decisiones, y las tres se ven jugando:
--
--   * Se APAGA al llegar a cero. Sin moho no hay de donde crecer, asi que
--     limpiarlo del todo es ganarle y no solo aguantarlo -- que es lo que hace
--     que "dejar el bol a cero" sea un objetivo y no una condena.
--   * Solo prende en casillas LIMPIAS: ni donde ya hay moho ni encima del
--     barro. Apiladas, el jugador tendria que acordarse de cuantas cosas hay
--     debajo de una galleta, y lo que hay debajo de una galleta tiene que
--     poder mirarse.
--   * Y una casilla rodeada de moho sale varias veces en la lista, asi que es
--     mas facil que le toque a ella. No es un descuido: es lo que hace que la
--     mancha crezca como una mancha en vez de saltar por el bol.
function Board:crecerMoho()
    if self:mohoVivo() == 0 then return nil end
    self.mohoCuenta = self.mohoCuenta + 1
    if self.mohoCuenta < Board.MOHO_CADA then return nil end
    self.mohoCuenta = 0

    local candidatas = {}
    for i = 1, self.cols * self.rows do
        if self.moho[i] then
            local c, r = self:cr(i)
            for _, d in ipairs(VECINAS) do
                local j = self:idx(c + d[1], r + d[2])
                if j and self.mascara[j] and not self.moho[j]
                   and (self.barro[j] or 0) == 0 then
                    candidatas[#candidatas + 1] = j
                end
            end
        end
    end
    -- Sin sitio donde crecer no pasa nada y la cuenta vuelve a empezar: el
    -- moho rodeado de barro no se guarda turnos para desquitarse cuando se
    -- abra un hueco. Guardarlos seria un castigo diferido por algo que el
    -- jugador no puede ver venir.
    if #candidatas == 0 then return nil end

    local donde = candidatas[Util.dado(self.rnd, #candidatas)]
    self.moho[donde] = true
    return { i = donde }
end

-- Un volcado en texto, para las pruebas y para la consola. Una letra por
-- color, mayuscula si lleva especial, `*` la pastilla, `+` un cubito de hielo
-- (con lo que sea que lleve dentro) y `.` el agujero.
function Board:volcar()
    local letras = "abcdef"
    local lineas = {}
    for r = 1, self.rows do
        local fila = {}
        for c = 1, self.cols do
            local i = self:idx(c, r)
            local cel = self.celdas[i]
            if not self.mascara[i] then fila[#fila + 1] = "."
            elseif not cel then fila[#fila + 1] = " "
            elseif cel.pastilla then fila[#fila + 1] = "*"
            elseif cel.hielo then fila[#fila + 1] = "+"
            elseif cel.especial == "pelota" then fila[#fila + 1] = "@"
            elseif cel.especial then fila[#fila + 1] = letras:sub(cel.color, cel.color):upper()
            else fila[#fila + 1] = letras:sub(cel.color, cel.color) end
        end
        lineas[#lineas + 1] = table.concat(fila)
    end
    return table.concat(lineas, "\n")
end

return Board
