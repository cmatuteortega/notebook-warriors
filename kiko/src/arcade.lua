-- El arcade: una partida seguida de rondas que suben, con una mejora entre
-- ronda y ronda.
--
-- Es el mismo tablero de siempre -- las reglas estan en `src/board.lua` y no
-- hay una sola aqui -- con dos diferencias: la ronda se acaba EN CUANTO se
-- llega a la meta (no se juega entera, como un nivel de puntos de la campana)
-- y lo que se elige entre rondas cambia cuanto puntua lo que ya sabias hacer.
--
-- Este archivo es DATOS y cuentas, y no toca love: la lista de mejoras, la
-- lista de escalones de dificultad y las tres funciones que sacan de la ronda
-- N el nivel que toca. Por eso se puede medir una partida entera sin ventana
-- (`tests/test_arcade.lua`), que es la unica manera de saber si la curva de
-- metas esta puesta donde tiene que estar.
--
-- La regla que ordena todo lo de abajo: una MEJORA es una fila de una tabla
-- con lo que hace escrito una vez. Ni un `if` por mejora en la pantalla, ni
-- una regla nueva en el tablero -- las mejoras solo mueven numeros que el
-- tablero ya miraba (`Board.MODS`).

local Util    = require("src.util")
local Palette = require("src.palette")

local Arcade = {}

--== La curva ==============================================================

-- Los movimientos de la primera ronda, y lo que crece cada ronda siguiente.
--
-- Quince y uno mas por ronda: la ronda 1 tiene quince y la 25 treinta y nueve.
-- No es generosidad, es lo que hace que una partida de veinticinco rondas
-- pueda existir. Lo que puntua una ronda va con los movimientos casi en linea
-- recta (medido: subir de 15 a 26 movimientos multiplica los puntos por 1,77),
-- asi que un bol que crece es una capacidad que crece SOLA y encima de eso van
-- las mejoras.
--
-- Sin esto, la capacidad de una ronda es plana (ver `--capacidad`) y entonces
-- la curva de metas no mide como juegas: solo elige en que ronda te cruza.
-- Con esto, la partida tiene de donde crecer y las mejoras deciden CUANTO.
--
-- Quince y no diez porque los movimientos de mas de las rondas glotonas ya no
-- existen (ver `ESPECIALES`): lo que antes era un regalo de veintitantos
-- movimientos una ronda de cada cinco esta ahora repartido por TODAS, que es
-- la unica forma de que una ronda glotona no se juegue con otras reglas.
Arcade.MOVIMIENTOS = 15
Arcade.MOVIMIENTOS_RONDA = 1

-- La meta de la primera ronda es la del primer nivel, y por la misma razon:
-- cualquiera la pasa. Lo que hace un arcade no es empezar dificil, es SUBIR.
--
-- 2.800 y no 2.500 porque la primera ronda ya no tiene diez movimientos sino
-- quince: el bol de salida da mas, y una meta que no se entera de eso regala
-- las tres primeras rondas.
Arcade.META = 5000

-- Y sube en geometrica, que es lo que obliga a que la partida cambie de forma
-- en vez de durar mas: sumando una cantidad fija, la ronda doce se juega igual
-- que la tres con mas paciencia.
--
-- El numero esta MEDIDO, no elegido, y la medida que lo decide no es la de
-- cuanto aguanta el suelo sino esta otra: **lo que puntua una ronda NO crece
-- con las mejoras**. Jugando sin buscar nada y cogiendo una mejora al azar, la
-- ronda 1 da unos 12.000 y la ronda 14 unos 18.000 -- plano, con un bache a la
-- mitad cuando entra el sexto color. Contra una capacidad plana, una curva
-- geometrica no mide nada: solo elige en que ronda se cruza, y da igual lo que
-- el jugador elija por el camino. Cuanto mas empinada, antes deja de importar
-- lo que haces.
--
-- 1,25 es una curva EMPINADA y esta puesta a sabiendas. Contra la capacidad
-- medida -- unos doce mil en la primera ronda y unos dieciocho mil en la
-- decimocuarta -- una ronda de cada cuatro pide mas de lo que el bol puede dar
-- mucho antes de la veinticinco, asi que la partida se acaba pronto y lo que
-- decide hasta donde llegas es lo que compraste en las primeras pausas. Es una
-- decision de diseño y no una medida: `tests/test_arcade.lua` mide la otra
-- cosa -- que el suelo aterrice cerca de la ronda veinticinco -- y con este
-- numero esa prueba NO pasa. Esta escrito aqui para que quien la vea fallar
-- sepa que no es un descuido.
--
-- Subir la BASE en vez de bajar esto se probo y es peor: a 6.500 la primera
-- ronda ya se pierde, y la mitad de las partidas se acaban antes de la tercera
-- -- se pierde el arranque, que es lo unico que no se puede perder.
--
-- El techo esta lejos: con todas las mejoras cogidas, una ronda da treinta
-- veces lo que da pelada (409.000 contra 12.900), asi que quien construya algo
-- tiene sitio para llegar mucho mas alla de donde llega el suelo.
Arcade.CRECE = 1.25

-- Cada cuantas rondas cae una ESPECIAL. Cinco, y la primera es la quinta: las
-- cuatro de antes son las que ensenan el arcade -- misma forma, meta que sube,
-- una mejora entre medias -- y meter el objetivo de mas en la cuarta ponia la
-- primera ronda rara justo donde el jugador todavia esta entendiendo que va de
-- puntos. Ademas se ve venir: "cada cinco" se aprende en una partida y se
-- puede guardar una mejora para ella.
Arcade.RONDA_ESPECIAL = 5

-- Cuantas veces se ha PARADO la curva antes de llegar a esta ronda.
--
-- La curva se para en seco la ronda en que entra un color nuevo, y esto sale
-- de la medida mas dura de todo el arcade: el sexto color se lleva el 41% de
-- la puntuacion (11.760 -> 6.960 con los mismos movimientos), y para volver al
-- punto de partida harian falta 26 movimientos en vez de 15. Un color nuevo no
-- es un escalon, es un acantilado -- y una curva que ademas sube esa ronda
-- pide el doble justo cuando el bol da la mitad.
--
-- Parar una ronda no lo arregla del todo (nada lo arregla del todo: el
-- escalon se paga tambien con movimientos, ver `ESCALONES`), pero es lo que
-- convierte esa ronda de muro en ronda dificil.
local function pausas(ronda)
    local n, anterior = 0, Arcade.ESCALONES[1].colores
    for _, e in ipairs(Arcade.ESCALONES) do
        if e.colores > anterior and e.desde <= ronda then n = n + 1 end
        anterior = e.colores
    end
    return n
end

-- La meta de una ronda, redondeada a cientos: una meta de 15.237 se lee como
-- un numero sacado de una formula, que es justo lo que es.
function Arcade.meta(ronda)
    local bruta = Arcade.META * Arcade.CRECE ^ (ronda - 1 - pausas(ronda))
    return math.floor(bruta / 100 + 0.5) * 100
end

--== Las mejoras ===========================================================

-- Una mejora es una fila: que hace, hasta donde sube y como se cuenta.
--
--   id       la clave con la que se guarda lo subida que esta
--   nombre   lo que se lee en la carta
--   icono    un sprite YA existente (la pantalla lo resuelve; aqui es texto)
--   tope     cuantas veces se puede coger. Una mejora de una sola vez es un
--            tope de uno, y no hace falta otra clase de mejora.
--   texto    lo que hara si se coge AHORA, escrito con el nivel al que subiria
--   aplicar  escribe en la tabla de mejoras el valor ABSOLUTO del nivel n
--
-- `aplicar` escribe absolutos y no sumas a proposito: la tabla se calcula
-- entera desde cero cada vez que hace falta (`Arcade.mods`), asi que una
-- mejora cogida dos veces vale lo que diga su nivel dos y no lo que quede de
-- haber sumado dos veces. Es lo que permite ensenar "60 -> 90" en la carta y
-- que sea verdad.
--
-- Las lineas largas (tope 3) son las que se pueden perseguir toda la partida;
-- las de tope 2 son las que cambian la forma de jugar de golpe y no pueden
-- ademas repetirse cinco veces.
Arcade.MEJORAS = {
    {
        -- Paga por la racha de cuatro, que es la primera jugada que hay que
        -- BUSCAR: tres en linea salen solas.
        id = "cuarteto", nombre = "Cuarteto", icono = "galleta.limon.rayaH", tope = 3,
        texto = function(n) return string.format("+%d por cada cuatro en linea", 300 * n) end,
        aplicar = function(m, n) m.racha4 = 300 * n end,
    },
    {
        id = "quinteto", nombre = "Quinteto", icono = "pelota", tope = 2,
        texto = function(n) return string.format("+%d por cada cinco en linea", 900 * n) end,
        aplicar = function(m, n) m.racha5 = 900 * n end,
    },
    {
        -- Paga por REPETIR color: cada resolucion que se lleva por delante el
        -- mismo color que la anterior cobra un eslabon, y la siguiente dos
        -- (`Board.RACHA_COLOR_MAX`). Cuenta igual entre dos movimientos que
        -- entre dos pasos de una cascada, y eso es lo que la hace distinta de
        -- todo lo demas de esta lista: es la unica carta que no paga una
        -- jugada sino una SEGUIDA de jugadas.
        --
        -- No es la mejora de color con otro nombre. Aquella dice a que galleta
        -- mirar y no cambia en toda la partida; esta no dice a ninguna -- paga
        -- el color que el bol te este dando ahora, asi que se juega mirando lo
        -- que hay y no lo que elegiste hace diez rondas. Juntas se llevan
        -- bien, y eso tambien esta bien: es la unica pareja de este pool que
        -- apunta a lo mismo desde dos sitios.
        --
        -- 150 esta MEDIDO, y lo que lo decide no es cuanto da sino la
        -- DISTANCIA entre sus dos medidas: jugando sin pensar en el color, la
        -- linea entera sube la ronda un 25% (por debajo del cuarteto, que sube
        -- un 30); jugando a repetir color a proposito, un 50% (por debajo de
        -- la mejora de color, que sube un 45 sin que haya que hacer nada). Esa
        -- es la forma que se buscaba: una carta que paga el doble a quien
        -- juega a lo que pide, y que a quien no, no le regala la ronda.
        --
        -- Subirla mas se probo y rompe justo eso: a 250 el suelo ya sube un
        -- 41% y entonces la carta se coge por lo que da sola, que es lo que
        -- hace la mejora de color -- y una segunda mejora de color no hace
        -- falta.
        id = "obsesion", nombre = "Obsesion", icono = "galleta.fresa", tope = 3,
        texto = function(n) return string.format("+%d por repetir color (hasta +%d)",
                                                 150 * n, 150 * n * 3) end,
        aplicar = function(m, n) m.rachaColor = 150 * n end,
    },
    {
        -- Lo que cobra el combo, que es la jugada que hay que preparar dos
        -- movimientos antes. Multiplica en vez de sumar porque lo que se
        -- mejora es una jugada que ya era grande.
        id = "fusion", nombre = "Fusion", icono = "galleta.mora.envuelta", tope = 3,
        texto = function(n) return string.format("Juntar dos especiales puntua x%.1f",
                                                 1 + 0.5 * n) end,
        aplicar = function(m, n) m.combo = 1 + 0.5 * n end,
    },
    {
        -- Una casilla mas de radio es una envuelta de cinco por cinco: no es
        -- "un poco mas", es el doble largo de tablero. Por eso el tope es dos.
        id = "polvora", nombre = "Polvora", icono = "galleta.naranja.envuelta", tope = 2,
        texto = function(n) return n == 1 and "Las envueltas revientan 5x5 en vez de 3x3"
                                          or "Las envueltas revientan 7x7" end,
        aplicar = function(m, n) m.radio = n end,
    },
    {
        id = "lluvia", nombre = "Lluvia", icono = "galleta.menta.estrella", tope = 3,
        texto = function(n) return string.format("La estrella se parte en %d trozos", 3 + n) end,
        aplicar = function(m, n) m.estrellas = n end,
    },
    {
        -- Movimientos. No es un numero del tablero: es del arcade, y por eso
        -- se queda en la misma tabla pero con una clave que `Board` no mira.
        id = "mano", nombre = "Mano larga", icono = "kiko.15", tope = 3,
        texto = function(n) return string.format("%d movimientos por ronda",
                                                 Arcade.MOVIMIENTOS + 2 * n) end,
        aplicar = function(m, n) m.movimientos = 2 * n end,
    },
    {
        id = "regalo", nombre = "Regalo", icono = "galleta.uva.rayaV", tope = 2,
        texto = function(n) return string.format("Crear una especial puntua x%d", 1 + n) end,
        aplicar = function(m, n) m.crear = 1 + n end,
    },
    {
        -- El tope del multiplicador de cascada. Sube el techo de lo que puede
        -- dar una cadena con suerte, que es lo unico de este juego que ya se
        -- parece a un arcade.
        id = "cadena", nombre = "Cadena", icono = "estrellita", tope = 2,
        texto = function(n) return string.format("La cascada multiplica hasta x%d", 6 + 2 * n) end,
        aplicar = function(m, n) m.cascada = 2 * n end,
    },
    {
        -- Lo que estorba, cobrado. Es la mejora que hace que las rondas sucias
        -- -- barro y cubitos, que es a donde va la partida -- den algo a cambio
        -- del movimiento que cuestan.
        id = "fregona", nombre = "Fregona", icono = "barro1", tope = 2,
        -- Los TRES, y se nombran los tres aunque el moho no salga hasta la
        -- ronda 21: la carta dice lo que hace, no lo que hace hoy. Es lo mismo
        -- que ya pasaba con el hielo, que se puede comprar en la ronda dos.
        texto = function(n) return string.format("El barro, el hielo y el moho valen %d",
                                                 50 + 75 * n) end,
        aplicar = function(m, n) m.barro = 75 * n end,
    },
    {
        -- Y lo que estorba, QUITADO. No es la fregona con otro nombre: la
        -- fregona paga por el barro y esto cambia cuantas jugadas cuesta
        -- limpiarlo -- una capa doble deja de ser dos movimientos. En una
        -- ronda sucia, donde el objetivo es dejar el bol limpio, es la
        -- diferencia entre llegar y no llegar; en una ronda normal no hace
        -- casi nada, y eso es justo lo que la hace una decision.
        id = "estropajo", nombre = "Estropajo", icono = "barro2", tope = 1,
        texto = function() return "Cada golpe se lleva dos capas de barro" end,
        aplicar = function(m) m.capas = 1 end,
    },
    {
        -- La rayada disparando en CRUZ. Es la mejora que mas se ve de todas:
        -- cada rayada que sale a partir de aqui limpia una fila Y una columna,
        -- y la envuelta deja de ser la unica que limpia en dos direcciones. De
        -- una sola vez -- no hay medio disparar en cruz.
        id = "mecha", nombre = "Mecha", icono = "galleta.limon.rayaV", tope = 1,
        texto = function() return "Las rayadas disparan en cruz" end,
        aplicar = function(m) m.mecha = true end,
    },
    {
        -- La envuelta ya estalla DOS veces de serie -- esa es su gracia: no
        -- limpia mucho, limpia dos veces y entre medias ha caido galleta nueva
        -- encima. Asi que esta linea empieza en TRES: una mejora cuyo primer
        -- nivel es lo que ya hacia seria una carta que no hace nada.
        id = "eco", nombre = "Eco", icono = "galleta.fresa.envuelta", tope = 2,
        texto = function(n) return string.format("La envuelta estalla %d veces", 2 + n) end,
        aplicar = function(m, n) m.envuelta = 2 + n end,
    },
    {
        -- Especiales caidas del cielo. Es poco -- una de cada cincuenta al
        -- principio -- y por eso funciona: lo que cambia no es la cuenta de
        -- especiales, es que de vez en cuando baja una rayada por una columna
        -- donde no habia nada que hacer. Nunca estrella ni pelota: esas dos
        -- son el premio de una jugada buena y regaladas quitarian la razon de
        -- buscarlas (`Board.REGALOS`).
        id = "suerte", nombre = "Suerte", icono = "estrella", tope = 3,
        texto = function(n) return string.format("El %d%% de lo que cae trae especial", 2 * n) end,
        aplicar = function(m, n) m.suerte = 0.02 * n end,
    },
    {
        -- El cubito se rompe cuando revienta una VECINA, y vecina son las
        -- cuatro de siempre. Con esto tambien por la esquina, que es la unica
        -- forma de alcanzar el centro de un bloque de hielo sin pelarlo fila a
        -- fila. En diagonal no se casa ni se mueve nada en este juego: esta es
        -- la excepcion, y por eso es una mejora y no una regla.
        id = "deshielo", nombre = "Deshielo", icono = "hielo", tope = 1,
        texto = function() return "El hielo tambien se rompe en diagonal" end,
        aplicar = function(m) m.hieloDiagonal = true end,
    },
}

-- Y una mejora por FAMILIA de galleta, generadas de la lista de siempre.
--
-- Una por color y no una para todas: subir una familia es decirle al jugador a
-- que galleta mirar, y eso es una decision que dura toda la partida -- se juega
-- distinto cuando la fresa vale el doble que el limon. Una sola mejora para
-- las seis es la misma cifra mas grande y no cambia una jugada.
--
-- Sesenta por nivel porque el punto de partida son sesenta: la primera vez que
-- se coge, esa galleta vale EL DOBLE que las demas. Una subida que no se note
-- al mirar el tablero no vale para apuntar a nada.
--
-- Solo se ofrecen las que estan EN EL BOL: la uva no entra hasta la ronda seis
-- (ver los escalones), y una carta que sube un color que no sale es una carta
-- tirada -- de tres, la peor cosa que puede pasar.
for indice, familia in ipairs(Palette.galletas) do
    local nombre = familia.nombre:sub(1, 1):upper() .. familia.nombre:sub(2)
    Arcade.MEJORAS[#Arcade.MEJORAS + 1] = {
        id = "color" .. indice,
        nombre = nombre,
        icono = "galleta." .. familia.key,
        tope = 3,
        texto = function(n) return string.format("Cada %s vale %d en vez de 60",
                                                 familia.nombre, 60 + 60 * n) end,
        aplicar = function(m, n)
            m.galletas = m.galletas or {}
            m.galletas[indice] = 60 * n
        end,
        disponible = function(run, ronda) return indice <= Arcade.escalon(ronda).colores end,
    }
end

-- Cuantas cartas se ofrecen. Tres: con dos no hay eleccion que contar y con
-- cuatro la pantalla deja de leerse de un vistazo en un movil.
Arcade.CARTAS = 3

Arcade.porId = {}
for _, m in ipairs(Arcade.MEJORAS) do Arcade.porId[m.id] = m end

--== Las rondas especiales =================================================

local LIMPIO = [[
########
########
########
########
########
########
########
########]]

-- Cada cinco rondas, una PASTILLA encima de lo que ya pedia la ronda.
--
-- Eso es todo lo que hay aqui, y el que no haya nada mas es el cambio: estas
-- filas llegaron a traer su propio bol, y el bol es justo lo que no pueden
-- traer. La dificultad de este modo la lleva una sola escalera -- la de
-- `ESCALONES`, donde ningun peldano quita nada -- y un bol aparte una ronda de
-- cada cinco la agujerea por los dos lados: la glotona salia mas sucia que su
-- vecina unas veces y mas limpia otras, y en las dos el jugador veia el fondo
-- del bol dar un salto que no venia de ningun sitio.
--
-- Asi que la glotona se juega en el bol que tocaba, con lo que ese bol pida
-- limpiar (`Arcade.extras` lo lee del dibujo), y ademas la pastilla. Lo que
-- cambia no es QUE hay que hacer sino cuantas cosas a la vez con los mismos
-- movimientos, que es la unica forma que tiene este modo de subir sin inventar
-- mecanicas nuevas.
--
-- La pastilla es lo unico que el bol no puede pedir por si solo: el barro y los
-- cubitos se ven en el dibujo y se piden solos, y una pastilla hay que
-- soltarla. Bajarla es ademas lo unico de este juego que no se puede comprar en
-- la pausa -- se juega DEBAJO de ella, no donde mas revienta --, y por eso es
-- la ronda que mide si has comprado movimientos.
--
-- La lista se recorre en orden y se vuelve a empezar, asi que sale en las
-- rondas 5, 10, 15, 20 y 25, y va de una pastilla a tres. El "poco a poco" no
-- necesita ninguna regla aparte: es la lista.
--
--   pastillas  cuantas hay que darle a Kiko. Y es lo unico que lleva una fila:
--              ni dibujo (lo pone el escalon) ni movimientos.
--
-- Movimientos de mas NO llevan. Los llevaron -- mas del doble de los de la
-- ronda, porque bajar pastillas cuesta jugadas que no dan puntos -- y era un
-- parche: una ronda que trae el doble de bol es una ronda que se juega con
-- otras reglas, y el jugador aprendia a guardarse las mejoras para ella en vez
-- de a jugarla. Esos movimientos estan ahora en la base de TODAS las rondas
-- (`MOVIMIENTOS`), asi que la glotona pide mas con el mismo bol que su vecina,
-- que es exactamente lo que se queria que fuese: la ronda dificil.
Arcade.ESPECIALES = {
    -- La primera pide una sola, y lo unico nuevo que trae es la pastilla: el
    -- bol que le toca (la Salpicadura, cuatro casillas de barro) lleva dos
    -- rondas puesto y ya esta aprendido.
    { nombre = "Ronda glotona", pastillas = 1 },
    { nombre = "Ronda glotona", pastillas = 1 },
    { nombre = "Ronda glotona", pastillas = 2 },
    { nombre = "Ronda glotona", pastillas = 2 },
    { nombre = "Ronda glotona", pastillas = 3 },
}

-- Lo que pide una ronda ademas de la meta, como lista, leido de su DIBUJO.
--
-- La regla es que un bol que trae un estorbo pide quitarlo, y vale para todas
-- las rondas y no solo para las glotonas. Antes solo lo pedian ellas y el
-- barro de las demas era puntos con retraso: una ronda del Barrizal se ganaba
-- reventando arriba, sin bajar nunca a fregar, y entonces medio juego --
-- el barro, los cubitos y las mejoras que los limpian -- era decorado. Ahora
-- el bol que se ve es el objetivo que se pide, que ademas es lo que ya se leia
-- mirando la ronda.
--
-- Se lee del dibujo y no de una casilla mas en la fila porque entonces las dos
-- podrian contradecirse, y de las dos maneras en silencio: pedir barro en un
-- bol limpio es una ronda que no se puede ganar, y no pedir el que hay es la
-- ronda regalada que este cambio viene a quitar.
--
-- La pastilla va siempre la primera: es la que manda en su ronda -- las otras
-- dos se limpian jugando y esa hay que ir a buscarla.
function Arcade.extras(dibujo, piden)
    local out = {}
    if piden > 0 then out[#out + 1] = { tipo = "pastillas", n = piden } end
    -- `X` es cubito CON barro debajo, asi que cuenta en las dos listas: son
    -- dos jugadas en la misma casilla (el golpe se lo lleva el hielo y no lo
    -- de dentro) y por eso son dos cosas que pedir.
    if dibujo:find("[oOX]") then out[#out + 1] = { tipo = "barro" } end
    if dibujo:find("[xX]") then out[#out + 1] = { tipo = "hielo" } end
    -- El moho va el ULTIMO de la lista y no es un capricho de orden: es lo
    -- unico que se pide que puede cambiar mientras juegas, asi que es el
    -- numero de la cabecera que hay que mirar dos veces.
    if dibujo:find("m") then out[#out + 1] = { tipo = "moho" } end
    return out
end

-- La especial que toca, o nil si esta ronda es normal.
function Arcade.especial(ronda)
    if ronda % Arcade.RONDA_ESPECIAL ~= 0 then return nil end
    local k = ronda / Arcade.RONDA_ESPECIAL
    return Arcade.ESPECIALES[(k - 1) % #Arcade.ESPECIALES + 1]
end

--== Los escalones de dificultad ===========================================

-- El fondo del bol, ronda a ronda, y la regla que ordena esta tabla entera:
-- **cada escalon ANADE y ninguno quita**. Lo que trajo el anterior sigue ahi, y
-- encima va lo de este. Se empieza con el bol a estrenar (ronda 1), cae un poco
-- de barro (3), ese barro crece (6), le salen cubitos encima (8), el barro
-- crece otra vez (11), entra el sexto color sin tocar el fondo (14), se cierran
-- las filas de hielo (16), el barro llega de lado a lado (18) y al final brota
-- el moho encima de todo lo demas (21).
--
-- Que no quite nada no es una manera de escribirlo: es LO QUE SE VE. El fondo
-- del bol es lo unico de una ronda que se mira antes de hacer nada, asi que es
-- de donde el jugador saca la sensacion de que la partida va subiendo -- cada
-- ronda es el bol de ayer con una cosa mas. Con escalones que limpiaban (los
-- hubo: el sexto color llegaba con el bol a estrenar) esa lectura se rompe una
-- vez y ya no vuelve, porque un bol mas limpio que el de la ronda anterior no
-- se lee como un respiro, se lee como que la dificultad no la lleva nadie.
--
-- Y por lo mismo las rondas glotonas ya no traen bol propio: la pastilla se
-- pide ENCIMA del bol que tocaba (ver `ESPECIALES`). Un bol aparte una ronda de
-- cada cinco es un agujero en la escalera, y de los dos lados a la vez -- mas
-- sucio que el de al lado en unas y mas limpio en otras.
--
-- La comprueba `tests/test_arcade.lua` escalon contra escalon: ni una capa de
-- barro de menos, ni un cubito de menos, ni un brote de moho de menos.
--
-- El dibujo de cada escalon cumple las mismas reglas que un nivel de la
-- campana -- una columna es UN tramo, ningun cubito encerrado -- y eso lo
-- comprueba `tests/test_arcade.lua` escalon por escalon, igual que
-- `test_levels.lua` hace con los niveles.
--
-- Ninguno empieza en una ronda glotona, y eso esta puesto a mano: estrenar el
-- sexto color en la misma ronda que vuelve la pastilla son dos cosas nuevas a
-- la vez, y entonces no se aprende ninguna -- se pierde y no se sabe por cual
-- de las dos. Por la misma razon la Salpicadura entra en la TRES y no en la
-- cuatro: el barro tiene que estar aprendido cuando llegue la cinco.
-- El `nombre` de cada escalon NO se le ensena a nadie: es la etiqueta de la
-- tabla de `tests/test_arcade.lua --tabla`, para poder leer de un vistazo en
-- que bol se muere. Una ronda de arcade no tiene nombre (ver `Arcade.nivel`).
--
-- `movimientos` son los que ese escalon anade a TODAS sus rondas, y existen
-- por el sexto color: es el unico cambio de estos que se lleva por delante casi
-- la mitad de lo que puntua una ronda, y los movimientos son la unica moneda
-- con la que se puede pagar algo asi.
Arcade.ESCALONES = {
    { desde = 1, nombre = "Primer bol", colores = 5, dibujo = LIMPIO },
    {
        -- El primer barro, y son cuatro casillas: lo justo para que se vea que
        -- el fondo del bol tiene algo y que reventar encima lo quita. Cuatro y
        -- no el charco entero porque esta es la ronda que ENSENA el barro, y lo
        -- que ensena tiene que poder limpiarse sin proponerselo.
        --
        -- En la tres y no en la cuatro para que no sea lo nuevo de la CINCO: la
        -- cinco estrena la pastilla y no puede estrenar ademas el barro.
        desde = 3, nombre = "Salpicadura", colores = 5,
        dibujo = [[
########
########
########
###oo###
###oo###
########
########
########]],
    },
    {
        -- El charco: la misma mancha, mas grande. No hay nada nuevo que
        -- aprender aqui y por eso puede subir sola -- es el escalon que dice
        -- que lo de abajo va a seguir creciendo.
        desde = 6, nombre = "Charco", colores = 5,
        dibujo = [[
########
########
##oooo##
##oooo##
##oooo##
##oooo##
########
########]],
    },
    {
        -- Los primeros cubitos, y encima del barro que ya habia: `X` es hielo
        -- CON barro debajo, asi que la casilla son dos jugadas y el charco no
        -- ha perdido ni una capa. Lo nuevo es que hay casillas que no se pueden
        -- tocar hasta que revienta algo al lado.
        --
        -- Cuatro y en las esquinas del charco: pegados al borde limpio, que es
        -- por donde se rompen. Un bloque en el centro se pela de fuera adentro
        -- y eso son seis jugadas seguidas en el mismo sitio.
        desde = 8, nombre = "Nevera", colores = 5,
        dibujo = [[
########
########
##XooX##
##oooo##
##oooo##
##XooX##
########
########]],
    },
    {
        -- El barro crece por los dos sitios a la vez: hacia fuera (un anillo
        -- que llega casi al borde) y hacia abajo (doble capa en el centro). Los
        -- cubitos siguen donde estaban.
        desde = 11, nombre = "Barrizal", colores = 5,
        dibujo = [[
########
#oooooo#
#oXooXo#
#ooOOoo#
#ooOOoo#
#oXooXo#
#oooooo#
########]],
    },
    {
        -- Y la uva, en la ronda catorce. Se pidio en la quince y esta en la
        -- catorce por la regla de esta tabla: la quince es una ronda glotona, y
        -- estrenar el sexto color el mismo dia que vuelve la pastilla son dos
        -- cosas nuevas a la vez.
        --
        -- El sexto color es el escalon mas caro que tiene este juego y esta
        -- medido: se lleva el 41% de lo que puntua una ronda (11.760 -> 6.960
        -- con los mismos movimientos) y harian falta veintiseis movimientos en
        -- vez de quince para volver al punto de partida. No es un escalon, es
        -- un acantilado. Puesto en la sexta ronda, diecinueve de cada cuarenta
        -- partidas se acababan exactamente ahi; en la undecima seguia siendo
        -- la ronda donde moria todo el que llegaba.
        --
        -- Asi que ademas de llegar el ultimo se paga de otras dos maneras: la
        -- curva se PARA esa ronda (ver `pausas`) y el escalon trae cuatro
        -- movimientos para siempre.
        --
        -- Lo que NO se hace ya es limpiarle el bol. Se hacia -- este escalon
        -- llegaba con el bol a estrenar mientras el anterior tenia barro y
        -- cubitos -- y era la unica marcha atras de toda la tabla: el fondo del
        -- bol solo va en una direccion, y una ronda que amanece mas limpia que
        -- la de ayer se lee como un fallo de cuentas y no como un respiro. El
        -- bol se queda EXACTAMENTE como estaba, que ya es toda la tregua que
        -- hace falta: lo nuevo de esta ronda es el color, y es lo unico nuevo.
        desde = 14, nombre = "Despensa", colores = 6, movimientos = 4,
        dibujo = [[
########
#oooooo#
#oXooXo#
#ooOOoo#
#ooOOoo#
#oXooXo#
#oooooo#
########]],
    },
    {
        -- Mas hielo, y por donde ya lo habia: las dos filas de cubitos se
        -- cierran enteras. El barro no se mueve -- este escalon es el del
        -- hielo, igual que el Charco era el del barro.
        desde = 16, nombre = "Congelador", colores = 6,
        dibujo = [[
########
#oooooo#
#oXXXXo#
#ooOOoo#
#ooOOoo#
#oXXXXo#
#oooooo#
########]],
    },
    {
        -- El bol entero: doble capa de barro de lado a lado y las dos filas de
        -- cubitos dentro. Es todo lo que cabe sin tocar el borde, y el borde se
        -- queda limpio a proposito -- ahi es donde entra el moho tres rondas
        -- despues, y donde se rompen los cubitos mientras tanto.
        desde = 18, nombre = "El bol", colores = 6,
        dibujo = [[
########
#oOOOOo#
#oXXXXo#
#oOOOOo#
#oOOOOo#
#oXXXXo#
#oOOOOo#
########]],
    },
    {
        -- El MOHO, encima de todo lo anterior. Es lo ultimo que entra y lo mas
        -- caro del modo: es el unico estorbo que CRECE mientras juegas (una
        -- casilla cada dos jugadas, `Board.MOHO_CADA`), asi que es el unico que
        -- no se puede dejar para el final de la ronda.
        --
        -- El bol de abajo no cambia ni una casilla respecto al escalon
        -- anterior, y eso no es pereza: la ronda 21 ya pide barro, hielo y
        -- moho a la vez, que son las tres cosas que este juego sabe pedir. Lo
        -- nuevo es el moho y no hace falta nada mas.
        --
        -- Los cuatro brotes van en el BORDE, que es la unica parte del bol que
        -- quedo limpia, y por una regla y no por sitio: el moho solo prende en
        -- casillas limpias (`Board:crecerMoho`). Metido en el centro no tendria
        -- donde crecer y un moho que no crece es barro verde. En el borde tiene
        -- el anillo entero -- arriba, abajo y las dos columnas de fuera -- asi
        -- que la mancha da la vuelta al bol y el objetivo es un recorrido.
        --
        -- Cuatro y separados: una sola mancha se limpia de una jugada
        -- afortunada y ya no vuelve. Separados hay que ir a los cuatro sitios,
        -- que es lo que hace que la cuenta de la cabecera suba y baje.
        --
        -- No estrena en la VEINTE, que seria lo redondo, porque la veinte es
        -- una ronda glotona: la regla de esta tabla es que nada nuevo empieza
        -- en una, y la prueba lo comprueba.
        desde = 21, nombre = "El moho", colores = 6,
        dibujo = [[
#m####m#
#oOOOOo#
#oXXXXo#
#oOOOOo#
#oOOOOo#
#oXXXXo#
#oOOOOo#
#m####m#]],
    },
}

-- El escalon de una ronda: el ultimo cuyo `desde` ya ha pasado.
function Arcade.escalon(ronda)
    local out = Arcade.ESCALONES[1]
    for _, e in ipairs(Arcade.ESCALONES) do
        if ronda >= e.desde then out = e end
    end
    return out
end

--== La partida ============================================================

function Arcade.nuevo(semilla)
    semilla = semilla or 1
    return {
        ronda = 1,
        puntos = 0,          -- los de la partida entera, sumando rondas
        mejoras = {},        -- [id] = nivel cogido
        oferta = nil,        -- las cartas de la pausa de AHORA, si la hay
        semilla = semilla,
        rnd = Util.rng(semilla),
    }
end

-- Todas las mejoras cogidas, sumadas. Sale una tabla con las claves de
-- `Board.MODS` (que el tablero copia) y ademas `movimientos`, que es del
-- arcade: el tablero no sabe que existen los movimientos.
function Arcade.mods(run)
    local m = { movimientos = 0 }
    for _, mejora in ipairs(Arcade.MEJORAS) do
        local nivel = run.mejoras[mejora.id]
        if nivel and nivel > 0 then mejora.aplicar(m, nivel) end
    end
    return m
end

-- Los movimientos de una ronda. Una ronda glotona NO anade nada por serlo: pide
-- mas con el mismo bol, y de ahi que sea la dificil. Lo que si anaden son los
-- escalones, que es como se paga un color nuevo.
--
-- Y se suman TODOS los que ya han pasado, no solo el del escalon de turno. Lo
-- que compensa el sexto color no puede caducar cuando entre el escalon
-- siguiente -- eran cuatro movimientos "para siempre" y duraban dos rondas: de
-- la 14 a la 15 se jugaba con 32 y en la 16 con 30, con el bol mas sucio. Los
-- movimientos son el unico numero de la ronda que el jugador lee como una
-- promesa, y uno que baja mientras el bol empeora no se lee como un escalon, se
-- lee como una cuenta mal hecha.
--
-- Sumandolos, un escalon nuevo con `movimientos` va encima de lo que ya habia y
-- no en lugar de ello, que es la misma regla con la que crece el bol.
function Arcade.movimientos(run, ronda)
    ronda = ronda or run.ronda
    local escalones = 0
    for _, e in ipairs(Arcade.ESCALONES) do
        if ronda >= e.desde then escalones = escalones + (e.movimientos or 0) end
    end
    return Arcade.MOVIMIENTOS + (ronda - 1) * Arcade.MOVIMIENTOS_RONDA
           + Arcade.mods(run).movimientos + escalones
end

-- El nivel de la ronda de turno, con la misma forma que una fila de
-- `Levels.lista`: asi la pantalla de juego, el HUD y `Levels.mascara` no se
-- enteran de que esto no es un nivel de la campana.
--
-- Lo que no lleva es `estrellas`, y es a proposito: en el arcade no hay
-- estrellas que sacar, hay una meta que pasar. El HUD dibuja su barra contra
-- la meta cuando no encuentra umbrales.
function Arcade.nivel(run)
    local ronda = run.ronda
    local e = Arcade.escalon(ronda)
    local especial = Arcade.especial(ronda)

    -- Una pastilla, y dos a partir de la ronda doce. Mas de dos a la vez
    -- bloquean el tablero de verdad, y aqui no hay cuarenta movimientos para
    -- desatascarlo como en los niveles de pastillas de la campana.
    local piden = 0
    local pastillas = 0
    if especial then
        piden = especial.pastillas or 0
        -- Y el bol suelta DOS DE MAS de las que Kiko pide, y deja que esten
        -- las tres a la vez. No es generosidad: una pastilla sola cae por la
        -- columna que le toca y si esa columna se atasca no hay jugada que lo
        -- arregle -- una ronda que se pierde por donde cayo la pastilla no se
        -- lee como dificil, se lee como mala suerte. Cada una de mas es un
        -- camino mas y la eleccion vuelve a ser del jugador: se juega debajo
        -- de la que lo tenga mas claro.
        --
        -- Medido, de una en una: 30% con una sola, 60% con dos, 70% con tres.
        pastillas = piden + 2
    end

    -- El bol primero, porque de el sale lo que la ronda pide limpiar.
    --
    -- Y es SIEMPRE el del escalon, tambien en una ronda glotona: la pastilla se
    -- pide encima del bol que tocaba y no en uno suyo. Es lo que mantiene la
    -- escalera de `ESCALONES` entera -- un bol aparte cada cinco rondas la
    -- partiria, y el fondo del bol es de donde se lee que la partida sube.
    local dibujo = e.dibujo
    local extra = Arcade.extras(dibujo, piden)

    return {
        -- Sin nombre, y ya no hace falta decir por que: tampoco lo lleva un
        -- nivel de la campana. El `nombre` de `Levels.lista` es una etiqueta
        -- interna que no sale en ninguna pantalla, asi que aqui no se echa de
        -- menos nada. Lo que hay que saber de la ronda lo dice el objetivo,
        -- que ya esta debajo de la barra, y quien decide si la cabecera pone
        -- "Ronda" o "Nivel" es `arcade`, ahi abajo.
        movimientos = Arcade.movimientos(run),
        colores = e.colores,
        objetivo = { tipo = "puntos", meta = Arcade.meta(ronda) },
        -- Los objetivos de MAS de la ronda, y son una LISTA porque muchas
        -- piden dos cosas a la vez. Se piden ademas de la meta: son las
        -- rondas que no se pasan jugando solo a lo que da mas puntos.
        -- `barro` y `hielo` no llevan cuenta -- se pide TODO, como en la
        -- campana: medio bol limpio no es una cosa que se pueda mirar y saber
        -- si vas bien, y todo limpio si.
        extra = (#extra > 0) and extra or nil,
        dibujo = dibujo,
        pastillas = pastillas,
        -- Todas en el bol a la vez: sin esto, las de repuesto esperan turno y
        -- no son ningun camino de mas. Con tope de cuatro: por encima de eso
        -- lo que hay en el bol no son caminos, son estorbos.
        pastillasALaVez = (pastillas > 0) and math.min(pastillas, 4) or nil,
        -- La marca que lee la pantalla de juego: sin estrellas que apuntar, y
        -- la ronda se corta en cuanto la meta esta hecha (un nivel de puntos de
        -- la campana se juega entero, porque alli la meta no es el final sino
        -- la primera estrella).
        arcade = true,
    }
end

--== La pausa entre rondas =================================================

-- Las tres cartas de esta pausa. Se guardan en la partida y no se vuelven a
-- sortear: la pantalla se dibuja sesenta veces por segundo y unas cartas que
-- se sortearan al dibujar cambiarian delante del jugador.
--
-- Solo entran las que todavia pueden subir. Cuando quedan menos de tres, se
-- ofrecen las que haya: una pausa sin cartas se salta sola.
function Arcade.ofrecer(run)
    -- La ronda que se mira es la que VIENE: lo que se elige aqui se juega en
    -- la siguiente, y una carta que sube la uva la ronda antes de que la uva
    -- entre en el bol seria una carta que no hace nada.
    local siguiente = run.ronda + 1
    local candidatas = {}
    for _, m in ipairs(Arcade.MEJORAS) do
        if (run.mejoras[m.id] or 0) < m.tope
           and (not m.disponible or m.disponible(run, siguiente)) then
            candidatas[#candidatas + 1] = m
        end
    end
    Util.barajar(candidatas, run.rnd)

    local oferta = {}
    for k = 1, math.min(Arcade.CARTAS, #candidatas) do oferta[k] = candidatas[k] end
    run.oferta = oferta
    return oferta
end

-- El nivel al que subiria una mejora si se cogiera ahora.
function Arcade.siguienteNivel(run, id)
    return (run.mejoras[id] or 0) + 1
end

-- Coger una carta: sube su linea, tira la oferta y pasa a la ronda siguiente.
-- Pasar de ronda ocurre AQUI y no al ganar la anterior: mientras se elige, la
-- ronda que se esta mirando en la cabecera todavia es la que se acaba de
-- jugar, y la meta que se ensena abajo es la que viene.
function Arcade.tomar(run, id)
    local mejora = Arcade.porId[id]
    if not mejora then return false end
    local nivel = Arcade.siguienteNivel(run, id)
    if nivel > mejora.tope then return false end
    run.mejoras[id] = nivel
    run.oferta = nil
    run.ronda = run.ronda + 1
    return true
end

-- Pasar de ronda sin coger nada. Pasa cuando ya no queda ninguna mejora que
-- subir: la pausa se queda sin cartas y lo unico que puede hacer es dejar
-- seguir. No es un caso raro que haya que evitar -- es el final natural de una
-- partida muy larga, y quedarse encallado ahi seria peor que no tener mejoras.
function Arcade.saltar(run)
    run.oferta = nil
    run.ronda = run.ronda + 1
end

-- Una ronda ganada: se apuntan sus puntos y se sacan las cartas.
function Arcade.rondaGanada(run, puntos)
    run.puntos = run.puntos + puntos
    Arcade.ofrecer(run)
end

return Arcade
