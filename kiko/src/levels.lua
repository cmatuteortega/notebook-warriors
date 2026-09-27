-- Los niveles.
--
-- Un nivel es una fila de esta tabla y nada mas: no hay codigo por nivel en
-- ningun sitio. Anadir uno es escribir su fila; el mapa, el tablero, el HUD y
-- el guardado se enteran solos.
--
-- La FORMA del tablero y el barro van en un dibujo de ocho lineas, que es
-- la unica manera de escribir "esto es una cruz con doble capa en el centro"
-- y verlo al leerlo:
--
--     #  casilla normal          o  con una capa de barro
--     .  agujero (no existe)     O  con dos capas
--     x  galleta congelada        X  congelada y con una capa de barro debajo
--     m  con moho, que es el barro que CRECE (ver `Board:crecerMoho`): lo que
--        se escribe aqui es de donde sale, no cuanto habra
--
-- Objetivos, los cuatro:
--
--     puntos    llegar a `meta` antes de que se acaben los movimientos
--     recoger   romper N galletas de un color (o de varios: lista)
--     barro     limpiar hasta la ultima capa del dibujo
--     pastillas bajar N pastillas hasta el suelo, que se caen del bol
--
-- Y `extra`, que es un objetivo de MAS: hay que cumplirlo ADEMAS del suyo.
-- Nacio para las rondas glotonas del arcade y aqui hace el mismo trabajo, que
-- es el unico que no sabe hacer la lista de arriba -- pedir dos cosas a la vez
-- ("llega a tantos puntos Y limpia el barro"). No es un objetivo nuevo: es el
-- mismo, sumado.
--
-- `nombre` es una etiqueta INTERNA y no sale en ninguna pantalla: esta para
-- poder leer esta tabla, para las medidas y para que un fallo de
-- `test_levels.lua` diga de que nivel habla. Quien juega identifica un nivel
-- por su numero y por donde cae en el camino del mapa, y nada mas. Si alguna
-- vez vuelve a la interfaz, que sea una decision y no un descuido.
--
-- Las tres estrellas son SIEMPRE puntos, tambien en los niveles cuyo objetivo
-- no lo es: el objetivo dice si pasas, las estrellas dicen como. Separarlos es
-- lo que permite volver a un nivel ya pasado y tener algo que hacer.

local Levels = {}

local LIMPIO = [[
########
########
########
########
########
########
########
########]]

-- Los umbrales de estrellas de abajo NO estan escritos a mano: los MIDE
-- `tests/test_balance.lua`, que juega sesenta partidas de cada nivel con un
-- jugador que apunta al objetivo y no hace nada mas, y los pone en 0,7 / 1,0 /
-- 1,45 veces la mediana de lo que saca. En los niveles de puntos, la meta es
-- ademas la primera estrella: pasar y sacar la primera son lo mismo.
--
-- Por eso hay numeros que parecen raros de un nivel a otro (el 3 pide menos
-- puntos que el 2): un nivel de objetivo se ACABA cuando el objetivo esta
-- hecho, asi que sus partidas son mas cortas y puntuan menos. La medida lo
-- sabe; la intuicion, no.
--
-- Tras tocar un nivel: `luajit tests/test_balance.lua --tabla` y volver a
-- calibrar. Un nivel que el jugador de mentira no termina ni el 15% de las
-- veces es un nivel roto, y la prueba lo dice.
--
--== Los cuatro bloques ====================================================
--
-- Cien niveles no son cien ideas: son cuatro tandas, y cada una entra cuando
-- la anterior ya se sabe. El orden es el curso y por eso esta escrito aqui
-- arriba y no en un documento aparte.
--
--     1..15    el bol limpio. Las cuatro maneras de ganar (puntos, un color,
--              pastillas) y la FORMA del tablero. Ni una capa de barro: lo
--              unico que hay que aprender es que juntar tres da puntos y que
--              un agujero cambia por donde cae lo nuevo.
--    16..30    el barro. Una capa, dos capas, en tiras, en marco, en las
--              esquinas de un cuenco -- y al final, barro con otra cosa
--              encima (una pastilla que bajar, un color que recoger).
--    31..45    el hielo, y SIN barro debajo a proposito: un cubito solo, para
--              que se vea que se rompe al lado y que CAE. Mezclarlo con el
--              barro desde el primero esconderia cual de las dos cosas es la
--              que estorba.
--    46..100   todo junto. Barro bajo el hielo, boles partidos en dos,
--              columnas sueltas de una casilla, torres, diamantes, pozos, y
--              los objetivos dobles del `extra`. Aqui ya no se ensena nada
--              nuevo: se combina, que es lo que aguanta cincuenta niveles.
Levels.lista = {
    --== 1..15  El bol limpio ==============================================
    {
        nombre = "Primer bol",
        movimientos = 16, colores = 5,
        -- La meta del primero esta DEBAJO de su primera estrella (8400) y es
        -- el unico nivel donde eso pasa: la primera partida de cualquiera
        -- tiene que acabar en "superado". Se mide: `test_balance.lua` exige
        -- que el jugador de mentira lo pase el 95% de las veces.
        objetivo = { tipo = "puntos", meta = 5000 },
        estrellas = { 8400, 12000, 17400 },
        dibujo = LIMPIO,
    },
    {
        nombre = "Mostrador",
        movimientos = 20, colores = 5,
        objetivo = { tipo = "puntos", meta = 11600 },
        estrellas = { 11600, 16600, 24000 },
        dibujo = LIMPIO,
    },
    {
        nombre = "Fresas",
        movimientos = 20, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 1, n = 18 } } },
        estrellas = { 7300, 10500, 15200 },
        dibujo = LIMPIO,
    },
    {
        -- La forma del tablero, y lo primero que se aprende de ella: en un
        -- embudo las columnas de fuera son cortas y lo nuevo entra por
        -- arriba a distinta altura en cada una.
        nombre = "Embudo",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "puntos", meta = 10500 },
        estrellas = { 10500, 15000, 21800 },
        dibujo = [[
########
########
.######.
.######.
..####..
..####..
..####..
..####..]],
    },
    {
        nombre = "Dos sabores",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 3, n = 20 }, { color = 5, n = 20 } } },
        estrellas = { 10200, 14600, 21200 },
        dibujo = LIMPIO,
    },
    {
        nombre = "La pastilla",
        movimientos = 26, colores = 5,
        objetivo = { tipo = "pastillas", n = 1 },
        estrellas = { 13900, 19900, 28800 },
        dibujo = LIMPIO,
        pastillas = 1,
    },
    {
        nombre = "Despensa",
        movimientos = 24, colores = 6,
        objetivo = { tipo = "puntos", meta = 7700 },
        estrellas = { 7700, 11100, 16100 },
        dibujo = LIMPIO,
    },
    {
        nombre = "Dos pastillas",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "pastillas", n = 2 },
        estrellas = { 10000, 14300, 20800 },
        dibujo = [[
##....##
##....##
########
########
########
########
##....##
##....##]],
        pastillas = 2,
    },
    {
        nombre = "Uva sola",
        movimientos = 26, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 6, n = 24 } } },
        estrellas = { 8100, 11600, 16900 },
        dibujo = LIMPIO,
    },
    {
        -- Una banda en diagonal: ninguna columna llega a las ocho y la boca
        -- de cada una esta a distinta altura, asi que lo que entra nuevo
        -- entra escalonado. Con seis colores, la forma es medio nivel.
        nombre = "Escalera",
        movimientos = 26, colores = 6,
        objetivo = { tipo = "puntos", meta = 7600 },
        estrellas = { 7600, 10900, 15900 },
        dibujo = [[
....####
..######
########
########
########
########
######..
####....]],
    },
    {
        nombre = "Tres pastillas",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "pastillas", n = 3 },
        estrellas = { 20300, 29000, 42100 },
        dibujo = [[
#.####.#
#.####.#
########
########
########
########
########
########]],
        pastillas = 3,
    },
    {
        -- Cuatro colores en el bol y tres en el objetivo: la menta que sobra
        -- es la que estorba, y con solo cuatro colores sale en una casilla de
        -- cada cuatro. Pide ciento veintiseis galletas en DIECIOCHO
        -- movimientos, que leido parece un error: con cuatro colores las
        -- cascadas salen sin buscarlas y una jugada revienta el triple que en
        -- un nivel de seis. Es la unica manera de ensenar lo que pesa el
        -- numero de colores -- ponerlo en el extremo y dejar que se vea.
        --
        -- Y son tres y no cuatro por la cabecera: `Hud.objetivo` reparte el
        -- panel entre los colores pedidos, y a cuatro el icono de uno se come
        -- el contador del de al lado.
        nombre = "Cuatro sabores",
        movimientos = 18, colores = 4,
        objetivo = { tipo = "recoger", lista = { { color = 1, n = 42 }, { color = 2, n = 42 },
                                                 { color = 3, n = 42 } } },
        estrellas = { 25100, 35900, 52100 },
        dibujo = LIMPIO,
    },
    {
        -- Al contrario que el embudo: aqui lo que falta es el SUELO de en
        -- medio, y una columna que acaba antes se rellena antes. Seis
        -- colores porque el objetivo son puntos y la forma ya estorba.
        nombre = "Puente",
        movimientos = 26, colores = 6,
        objetivo = { tipo = "puntos", meta = 7200 },
        estrellas = { 7200, 10200, 14900 },
        dibujo = [[
########
########
########
########
########
###..###
##....##
##....##]],
    },
    {
        -- Dos colores de seis: la mitad de lo que revienta no cuenta para
        -- nada. Es el mismo objetivo del 5 con un color mas en el bol, y ese
        -- color de mas es la diferencia entre repartir la atencion y tener
        -- que buscar.
        nombre = "Mora y menta",
        movimientos = 30, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 4, n = 18 }, { color = 5, n = 18 } } },
        estrellas = { 7900, 11300, 16400 },
        dibujo = LIMPIO,
    },
    {
        -- Cuatro pastillas, y solo dos caben en el bol a la vez: son dos
        -- tandas y no hay prisa que valga. El bol es una BANDEJA -- cinco
        -- filas y seis columnas -- y eso es lo que lo hace posible: la
        -- pastilla que cae cruza cinco casillas en vez de ocho. La medida fue
        -- tajante aqui: con el bol entero, cuatro pastillas no bajan ni con
        -- cincuenta movimientos.
        nombre = "Cuatro pastillas",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "pastillas", n = 4 },
        estrellas = { 16000, 22800, 33100 },
        dibujo = [[
........
........
........
.######.
.######.
.######.
.######.
.######.]],
        pastillas = 4,
    },

    --== 16..30  El barro ==================================================
    {
        -- El primero con barro, y va en el centro: las cuatro casillas del
        -- medio son por donde pasa casi cualquier racha, asi que la primera
        -- capa se limpia sin buscarla. Lo que ensena no es a limpiar, es que
        -- hay algo DEBAJO del tablero.
        nombre = "Huellas",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 11700, 16700, 24300 },
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
        nombre = "Charco",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 17500, 25000, 36300 },
        dibujo = [[
########
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
########]],
    },
    {
        -- Justo lo contrario del charco: aqui el barro esta donde menos pasa
        -- una racha -- el canto del bol -- y el centro esta limpio. Es la
        -- primera vez que el nivel no se gana jugando en el medio.
        nombre = "Marco",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19400, 27700, 40200 },
        dibujo = [[
oooooooo
o######o
o######o
o######o
o######o
o######o
o######o
oooooooo]],
    },
    {
        -- Barro en tiras, y las tiras son de una casilla de ancho: una racha
        -- horizontal limpia cuatro tiras a la vez y una vertical solo una.
        -- Es el primer nivel donde la ORIENTACION de la jugada importa mas
        -- que el sitio.
        nombre = "Reja",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 17500, 25000, 36300 },
        dibujo = [[
#o#oo#o#
#o#oo#o#
#o#oo#o#
#o#oo#o#
#o#oo#o#
#o#oo#o#
#o#oo#o#
#o#oo#o#]],
    },
    {
        -- Barro salteado: ninguna casilla sucia toca a otra. Una racha de
        -- tres limpia dos capas como mucho, nunca tres, y eso hace que
        -- limpiar sea cuestion de CUANTAS jugadas y no de donde.
        nombre = "Damero",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 22200, 31800, 46100 },
        dibujo = [[
o#o#o#o#
#o#o#o#o
o#o#o#o#
#o#o#o#o
o#o#o#o#
#o#o#o#o
o#o#o#o#
#o#o#o#o]],
    },
    {
        nombre = "Doble capa",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 18300, 26200, 37900 },
        dibujo = [[
########
#oooooo#
#oOOOOo#
#oOOOOo#
#oOOOOo#
#oOOOOo#
#oooooo#
########]],
    },
    {
        -- Un cuenco: las cuatro columnas de en medio empiezan dos filas mas
        -- abajo. El barro de las esquinas de un cuenco es lo mas caro que hay
        -- en este juego -- casi ninguna racha pasa por ahi --, asi que la
        -- forma es la dificultad y el resto se queda de serie: cinco colores
        -- y los movimientos justos.
        nombre = "Cuenco",
        movimientos = 26, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 12100, 17300, 25200 },
        dibujo = [[
##....##
###..###
##oooo##
#oooooo#
#oooooo#
#oooooo#
#oooooo#
########]],
    },
    {
        -- El barro de la escalera. Las dos puntas son de cuatro casillas y no
        -- tienen vecina por un lado: ahi solo limpian las rachas verticales,
        -- y son las ultimas dos manchas que quedan siempre.
        nombre = "Escalera sucia",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 17200, 24600, 35700 },
        dibujo = [[
....oooo
..oooooo
oooooooo
oooooooo
oooooooo
oooooooo
oooooo..
oooo....]],
    },
    {
        nombre = "Barrizal",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 20000, 28600, 41400 },
        dibujo = [[
########
#oooooo#
#oOOOOo#
#oOOOOo#
#oOOOOo#
#oOOOOo#
#oooooo#
########]],
    },
    {
        -- Cuatro torres de una casilla de ancho, y en una torre no hay
        -- rachas horizontales: las casillas de al lado no existen. El barro
        -- de arriba solo se limpia con rachas VERTICALES que suban desde la
        -- fila de abajo, y eso no se ve mirando el dibujo, se descubre
        -- intentandolo. Cuatro colores porque con cinco no se limpia: una
        -- racha vertical dentro de una columna de cuatro casillas es
        -- practicamente la unica jugada util que tiene el nivel.
        nombre = "Torres",
        movimientos = 28, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 24700, 35300, 51200 },
        dibujo = [[
o.o.o.o.
o.o.o.o.
o.o.o.o.
oooooooo
########
########
########
########]],
    },
    {
        -- Dos islas de dos columnas colgando sobre un suelo comun. Dos
        -- columnas no dan rachas horizontales -- hacen falta tres --, asi que
        -- arriba se juega en vertical y abajo, donde el suelo es ancho, en
        -- las dos direcciones.
        nombre = "Islas",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 12000, 17200, 24900 },
        dibujo = [[
oo..oo..
oo..oo..
oo..oo..
oo..oo..
oooooooo
oooooooo
########
########]],
    },
    {
        -- El primer objetivo DOBLE: la pastilla no basta y el barro tampoco.
        -- Y las dos cosas tiran en direcciones distintas -- la pastilla pide
        -- jugar debajo de ella, el barro pide jugar donde esta sucio --, que
        -- es justo el motivo de que exista `extra`.
        nombre = "Pastilla en el fango",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "pastillas", n = 2 },
        extra = { { tipo = "barro" } },
        estrellas = { 20300, 29000, 42100 },
        dibujo = [[
########
##oooo##
##oooo##
########
########
##oooo##
##oooo##
########]],
        pastillas = 2,
    },
    {
        -- El mismo cruce que el anterior con la otra pareja: un color que
        -- recoger y el barro por debajo. El barro esta arriba y abajo del
        -- todo, que son las dos filas por las que menos pasa una racha
        -- buscada a proposito.
        nombre = "Fresas en el fango",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 1, n = 24 } } },
        extra = { { tipo = "barro" } },
        estrellas = { 22500, 32200, 46700 },
        dibujo = [[
oooooooo
oooooooo
########
########
########
########
oooooooo
oooooooo]],
    },
    {
        nombre = "Cierre",
        movimientos = 45, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 29200, 41800, 60600 },
        dibujo = [[
oooooooo
oooooooo
ooOOOOoo
ooOOOOoo
ooOOOOoo
ooOOOOoo
oooooooo
oooooooo]],
        pastillas = 2,
    },
    {
        -- La reja, pero de dos capas: la misma tira que antes se limpiaba de
        -- una pasada ahora pide dos. Es el ultimo del bloque del barro y no
        -- trae nada nuevo a proposito -- solo el doble de lo mismo, que es
        -- como se comprueba si lo de antes se aprendio.
        nombre = "Cuadricula",
        movimientos = 38, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 27800, 39700, 57600 },
        dibujo = [[
#O#OO#O#
#O#OO#O#
#O#OO#O#
#O#OO#O#
#O#OO#O#
#O#OO#O#
#O#OO#O#
#O#OO#O#]],
    },

    --== 31..45  El hielo ==================================================
    --
    -- Quince niveles con cubitos y NINGUNO con barro, que es la decision del
    -- bloque: un cubito sobre barro son dos jugadas y dos cosas que aprender
    -- a la vez. Aqui el cubito va solo, para que se vea lo unico que hay que
    -- saber de el -- que se rompe reventando AL LADO, y que despues CAE como
    -- cualquier otra galleta.
    {
        -- Cuatro cubitos sueltos en mitad del bol limpio, y el objetivo son
        -- puntos: se pueden ignorar. Por eso el `extra` -- sin el, el primer
        -- nivel de hielo se pasaria sin tocar un cubito.
        nombre = "Cubitos",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "puntos", meta = 14700 },
        extra = { { tipo = "hielo" } },
        estrellas = { 14700, 21100, 30600 },
        dibujo = [[
########
########
##x##x##
########
########
##x##x##
########
########]],
    },
    {
        -- Hielo repartido en tiras de una casilla. Un cubito suelto se rompe
        -- con cualquier racha al lado; lo que ensena es que el cubito CAE,
        -- asi que a la segunda cascada ya no esta donde lo dejo el dibujo.
        nombre = "Congelador",
        movimientos = 26, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 2, n = 34 } } },
        estrellas = { 13200, 18900, 27400 },
        dibujo = [[
########
########
#x#xx#x#
########
########
########
########
########]],
    },
    {
        -- Un bloque de seis, y dentro de un bloque de hielo no revienta nada:
        -- se pela de fuera adentro. Los de en medio no se pueden tocar hasta
        -- que caen los de los cantos.
        nombre = "Carambano",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "puntos", meta = 12300 },
        extra = { { tipo = "hielo" } },
        estrellas = { 12300, 17600, 25500 },
        dibujo = [[
###xx###
###xx###
###xx###
########
########
########
########
########]],
    },
    {
        -- Una fila entera congelada, y una fila entera no corta el tablero:
        -- se rompe desde arriba o desde abajo, y en cuanto cae un cubito, el
        -- hueco lo rellena una galleta normal que ya sirve de vecina.
        nombre = "Muralla",
        movimientos = 22, colores = 5,
        objetivo = { tipo = "puntos", meta = 12000 },
        extra = { { tipo = "hielo" } },
        estrellas = { 12000, 17200, 24900 },
        dibujo = [[
########
xxxxxxxx
########
########
########
########
########
########]],
    },
    {
        -- Treinta y dos moras entre seis colores y con cuatro cubitos
        -- estorbando: un color de seis sale una vez de cada seis, asi que
        -- casi todo lo que revientas no cuenta para nada. Los cubitos son lo
        -- que impide jugar de memoria -- la casilla que te hacia falta esta
        -- congelada -- y hay que romperlos aunque no den mora.
        nombre = "Granizo",
        movimientos = 30, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 5, n = 32 } } },
        estrellas = { 9800, 14100, 20400 },
        dibujo = [[
########
########
##x##x##
########
##x##x##
########
########
########]],
    },
    {
        nombre = "Bloque de hielo",
        movimientos = 24, colores = 5,
        objetivo = { tipo = "puntos", meta = 15100 },
        extra = { { tipo = "hielo" } },
        estrellas = { 15100, 21500, 31200 },
        dibujo = [[
########
########
##xxxx##
##xxxx##
########
########
########
########]],
    },
    {
        -- Pastillas y hielo, y los dos estorban de la misma manera: ninguno
        -- casa con nada. La diferencia es que la pastilla hay que bajarla y
        -- el cubito hay que romperlo, asi que la misma casilla vale para
        -- cosas contrarias segun lo que tenga encima.
        nombre = "Pastilla con hielo",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "pastillas", n = 2 },
        extra = { { tipo = "hielo" } },
        estrellas = { 18500, 26500, 38400 },
        dibujo = [[
########
##x##x##
########
########
########
########
##x##x##
########]],
        pastillas = 2,
    },
    {
        -- Cubitos dentro de torres de una casilla: ahi no hay vecina a los
        -- lados, asi que un cubito de una torre solo se rompe con lo que
        -- revienta encima o debajo de el, en la misma columna.
        nombre = "Cumbres",
        movimientos = 24, colores = 4,
        objetivo = { tipo = "puntos", meta = 25400 },
        extra = { { tipo = "hielo" } },
        estrellas = { 25400, 36400, 52700 },
        dibujo = [[
x.#.#.x.
#.#.#.#.
#.x.x.#.
########
########
########
########
########]],
    },
    {
        nombre = "Las esquinas",
        movimientos = 26, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 2, n = 30 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 14100, 20200, 29300 },
        dibujo = [[
x######x
########
########
########
########
########
########
x######x]],
    },
    {
        nombre = "Nevada",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "puntos", meta = 18200 },
        extra = { { tipo = "hielo" } },
        estrellas = { 18200, 26100, 37800 },
        dibujo = [[
#x#x#x#x
########
x#x#x#x#
########
#x#x#x#x
########
x#x#x#x#
########]],
    },
    {
        -- El hielo en la boca del cuenco: las cuatro columnas de en medio
        -- empiezan ahi, asi que lo primero que entra nuevo se encuentra un
        -- cubito. Se rompe desde abajo, que es justo al reves de como se
        -- mira.
        nombre = "Cuenco helado",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 3, n = 30 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 10600, 15100, 22000 },
        dibujo = [[
##....##
###..###
##xxxx##
########
########
########
########
########]],
    },
    {
        nombre = "Pastillas y hielo",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "pastillas", n = 3 },
        extra = { { tipo = "hielo" } },
        estrellas = { 12900, 18500, 26800 },
        dibujo = [[
........
........
........
.#x##x#.
.######.
.######.
.#x##x#.
.######.]],
        pastillas = 3,
    },
    {
        nombre = "Escalera de hielo",
        movimientos = 26, colores = 6,
        objetivo = { tipo = "puntos", meta = 8400 },
        extra = { { tipo = "hielo" } },
        estrellas = { 8400, 12000, 17400 },
        dibujo = [[
....x###
..x#####
########
###xx###
########
########
#x####..
###x....]],
    },
    {
        -- Ocho cubitos en diagonal: ninguno toca a otro y cada uno esta en
        -- una fila y en una columna distintas. No hay una sola jugada que se
        -- lleve dos, y eso hace que el nivel sea largo sin ser dificil --
        -- justo antes del que cierra el bloque, que es al reves.
        nombre = "Aludes",
        movimientos = 28, colores = 5,
        objetivo = { tipo = "recoger", lista = { { color = 1, n = 20 }, { color = 4, n = 20 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 12500, 17900, 25900 },
        dibujo = [[
x#######
#x######
##x#####
###x####
####x###
#####x##
######x#
#######x]],
    },
    {
        -- Todo el canto del bol congelado. Es el bloque de hielo mas grande
        -- del juego y se pela como todos: las cuatro esquinas son las
        -- ultimas, porque cada una toca a dos cubitos y a ninguna galleta.
        nombre = "Congelacion",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "puntos", meta = 23900 },
        extra = { { tipo = "hielo" } },
        estrellas = { 23900, 34200, 49600 },
        dibujo = [[
xxxxxxxx
x######x
x######x
x######x
x######x
x######x
x######x
xxxxxxxx]],
    },

    --== 46..100  Todo junto ===============================================
    --
    -- De aqui al final no hay ninguna pieza nueva: estan las cuatro de
    -- siempre y las combinaciones que faltaban. Lo que cambia de un nivel al
    -- siguiente es DONDE aprieta -- la forma del bol, lo que hay debajo, o
    -- que se pidan dos cosas a la vez -- y por eso los dibujos son la mitad
    -- del diseno de este tramo.
    {
        -- Barro en TODO el bol y seis cubitos por encima. Cada cubito son dos
        -- jugadas -- una para el hielo, otra para la capa -- y ahi es donde
        -- se entiende que el golpe se lo lleva el hielo: la casilla sigue
        -- sucia despues de romperlo.
        nombre = "Escarcha",
        movimientos = 37, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 25200, 36100, 52400 },
        dibujo = [[
oooooooo
oXoooXoo
oooooooo
ooXooXoo
oooooooo
oXoooXoo
oooooooo
oooooooo]],
    },
    {
        nombre = "Nevera",
        movimientos = 26, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 11300, 16200, 23500 },
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
        -- Ocho cubitos en bloque, y dentro de un bloque de hielo no revienta
        -- nada: se deshiela de fuera adentro, fila a fila. Debajo, doble
        -- capa, que es la razon de los movimientos que tiene.
        nombre = "Bloque",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 21600, 30800, 44700 },
        dibujo = [[
########
#oooooo#
#oXXXXo#
#oXXXXo#
#oOOOOo#
#oOOOOo#
#oooooo#
########]],
    },
    {
        -- El hielo arriba, tapando la boca de las columnas del centro: lo
        -- nuevo entra por ahi y lo primero que se encuentra es un cubito. Se
        -- rompe desde abajo, que es justo al reves de como se mira.
        nombre = "Iglu",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 16700, 23900, 34700 },
        dibujo = [[
##xxxx##
#xooooX#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
########]],
    },
    {
        -- Doble capa en el centro, cubitos con barro debajo en medio de la
        -- doble capa, pastillas cayendo sin que las pida nadie y las esquinas
        -- de arriba limpias. Nada nuevo -- solo todo lo de antes en el mismo
        -- bol.
        nombre = "El bol",
        movimientos = 42, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 23600, 33700, 48900 },
        dibujo = [[
##oooo##
#oOOOOo#
#oOXXOo#
#oOXXOo#
#oOOOOo#
#oOOOOo#
#oooooo#
########]],
        pastillas = 3,
    },
    {
        -- El puente con barro hasta el borde: las dos columnas cortas del
        -- centro acaban tres filas antes, asi que su barro se limpia con
        -- rachas horizontales o no se limpia.
        nombre = "Puente helado",
        movimientos = 46, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 22800, 32600, 47200 },
        dibujo = [[
oooooooo
oXooooXo
oooooooo
oooooooo
oooooooo
ooo..ooo
oo....oo
oo....oo]],
    },
    {
        nombre = "Cuenco sucio",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 13800, 19700, 28600 },
        dibujo = [[
##....##
###..###
##XooX##
#oooooo#
#oOOOOo#
#oOOOOo#
#oooooo#
########]],
    },
    {
        nombre = "Columnas",
        movimientos = 28, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 24900, 35600, 51600 },
        dibujo = [[
o.o.o.o.
o.X.o.X.
o.o.o.o.
oooooooo
########
########
########
########]],
    },
    {
        -- El barro esta en diagonal y las pastillas caen por donde quieren:
        -- la jugada que limpia casi nunca es la que baja, y hay que repartir
        -- los movimientos entre las dos cosas sabiendo que ninguna espera.
        nombre = "Rosario",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "pastillas", n = 3 },
        extra = { { tipo = "barro" } },
        estrellas = { 26500, 37800, 54900 },
        dibujo = [[
########
#o####o#
##o##o##
###oo###
###oo###
##o##o##
#o####o#
########]],
        pastillas = 3,
    },
    {
        -- Un rombo: las columnas de los cantos tienen dos casillas y las del
        -- centro ocho. En una columna de dos no hay racha vertical posible,
        -- asi que sus dos capas solo se limpian con las rachas horizontales
        -- de las filas del medio.
        nombre = "Diamante",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 15800, 22600, 32900 },
        dibujo = [[
...oo...
..oooo..
.oooooo.
oooooooo
ooOOOOoo
.oooooo.
..oooo..
...oo...]],
    },
    {
        nombre = "Cruz",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 18600, 26600, 38500 },
        dibujo = [[
..oooo..
..oXXo..
oooooooo
ooOOOOoo
ooOOOOoo
oooooooo
..oXXo..
..oooo..]],
    },
    {
        nombre = "Doble reja",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 27300, 39000, 56500 },
        dibujo = [[
#O#OO#O#
#O#OO#O#
#X#XX#X#
#O#OO#O#
#O#OO#O#
#X#XX#X#
#O#OO#O#
#O#OO#O#]],
    },
    {
        nombre = "Ventisca",
        movimientos = 30, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 3, n = 30 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 10600, 15200, 22000 },
        dibujo = [[
#x#x#x#x
########
x#x#x#x#
########
#x#x#x#x
########
x#x#x#x#
########]],
    },
    {
        -- Las sesenta y cuatro casillas sucias y doce congeladas por encima.
        -- No hay una esquina donde esconderse: cualquier jugada sirve y
        -- ninguna sobra, que es lo contrario de casi todos los de antes.
        nombre = "Alfombra",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 26700, 38100, 55300 },
        dibujo = [[
oooooooo
oXoXoXoX
oooooooo
XoXoXoXo
oooooooo
oXoXoXoX
oooooooo
oooooooo]],
    },
    {
        nombre = "Gran bol",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 27700, 39700, 57500 },
        dibujo = [[
oooooooo
oooooooo
ooOOOOoo
ooOOOOoo
ooOOOOoo
ooOOOOoo
oooooooo
oooooooo]],
        pastillas = 2,
    },
    {
        nombre = "Torres heladas",
        movimientos = 32, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 27800, 39700, 57500 },
        dibujo = [[
X.o.o.X.
o.o.o.o.
o.X.X.o.
oooooooo
oooooooo
########
########
########]],
    },
    {
        nombre = "Escalera de barro",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19200, 27400, 39800 },
        dibujo = [[
....oooo
..oooooo
ooXooXoo
oooooooo
oooooooo
ooXooXoo
oooooo..
oooo....]],
    },
    {
        -- Un pozo: dos columnas del centro empiezan tres filas mas abajo y el
        -- barro las rodea. Lo de dentro del pozo no se toca con una racha
        -- horizontal larga -- no hay sitio -- y hay que bajar a limpiarlo.
        nombre = "Pozo",
        movimientos = 38, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 20100, 28800, 41700 },
        dibujo = [[
ooo..ooo
ooo..ooo
ooo..ooo
oooooooo
oooooooo
oooooooo
oooooooo
oooooooo]],
    },
    {
        nombre = "Cuatro islas",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 11700, 16800, 24300 },
        dibujo = [[
oo..oo..
oo..oo..
oo..oo..
oo..oo..
oooooooo
oooooooo
oooooooo
########]],
    },
    {
        -- Doce cubitos en dos filas seguidas y barro en las sesenta y cuatro.
        -- Las dos filas congeladas parten el bol en dos por un rato: hasta
        -- que no se rompe un cubito, lo de arriba y lo de abajo no se tocan.
        nombre = "Bloque helado",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 25800, 36900, 53600 },
        dibujo = [[
oooooooo
oooooooo
oXXXXXXo
oXXXXXXo
oooooooo
oooooooo
oooooooo
oooooooo]],
    },
    {
        nombre = "Dos pastillas en hielo",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "pastillas", n = 2 },
        extra = { { tipo = "hielo" } },
        estrellas = { 20400, 29100, 42300 },
        dibujo = [[
########
#x####x#
##x##x##
########
########
##x##x##
#x####x#
########]],
        pastillas = 2,
    },
    {
        nombre = "Meseta",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 18600, 26600, 38700 },
        dibujo = [[
..oooo..
..oooo..
.oooooo.
.oooooo.
oooooooo
oooooooo
oooooooo
oooooooo]],
    },
    {
        -- La reja tumbada. Es el mismo dibujo del 19 girado noventa grados y
        -- se juega al reves: ahi limpiaba la racha horizontal, aqui la
        -- vertical -- y la vertical es la que hay que buscar, porque las
        -- cascadas caen en esa direccion y deshacen media jugada.
        nombre = "Vetas",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 20100, 28700, 41700 },
        dibujo = [[
oooooooo
########
oXoooXoo
########
ooXoooXo
########
oooooooo
########]],
    },
    {
        -- Cuatro columnas de ancho y ocho de alto: el bol mas estrecho del
        -- juego. Una racha horizontal necesita tres de las cuatro columnas, y
        -- eso convierte casi todas las jugadas en verticales.
        nombre = "Cajon",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 11600, 16600, 24100 },
        dibujo = [[
..oooo..
..oXXo..
..oooo..
..oooo..
..oOOo..
..oOOo..
..oooo..
..oooo..]],
    },
    {
        -- Y el contrario: ocho de ancho y cinco de alto. Las cascadas son
        -- cortas -- lo que cae recorre cinco casillas -- y por eso limpiar de
        -- una pasada sale mas caro que en un bol hondo.
        nombre = "Medio bol",
        movimientos = 30, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 14000, 20000, 29100 },
        dibujo = [[
........
........
........
########
oooooooo
oOOOOOOo
oOOOOOOo
oooooooo]],
    },
    {
        nombre = "Bajo el hielo",
        movimientos = 32, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 2, n = 24 }, { color = 6, n = 24 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 10700, 15300, 22200 },
        dibujo = [[
########
##x##x##
########
#x####x#
########
##x##x##
########
#x####x#]],
    },
    {
        nombre = "Arco",
        movimientos = 42, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 27500, 39300, 56900 },
        dibujo = [[
oooooooo
oXooooXo
oooooooo
oooooooo
oooooooo
oooooooo
o.oooo.o
o.oooo.o]],
    },
    {
        -- Cinco pastillas, la bandeja aun mas plana -- cuatro filas -- y
        -- ancha entera. Es el otro extremo del 15: alli el bol era estrecho y
        -- hondo, aqui es ancho y bajo. Ancho quiere decir mas columnas por
        -- las que puede salir una pastilla, y bajo quiere decir que cualquiera
        -- de ellas la entrega en cuatro casillas.
        nombre = "Cinco pastillas",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "pastillas", n = 5 },
        extra = { { tipo = "hielo" } },
        estrellas = { 19100, 27300, 39600 },
        dibujo = [[
........
........
........
........
#x####x#
########
########
##x##x##]],
        pastillas = 5,
    },
    {
        -- Dos boles de tres columnas que no se tocan NUNCA: las columnas
        -- cuarta y quinta no existen, asi que nada cruza de un lado al otro
        -- ni cayendo ni casando. Son dos partidas a la vez con los mismos
        -- movimientos, y repartirlos es el nivel entero.
        nombre = "Dos boles",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 14500, 20700, 30000 },
        dibujo = [[
ooo..ooo
ooo..ooo
oOo..oOo
oOo..oOo
oOo..oOo
oOo..oOo
ooo..ooo
ooo..ooo]],
    },
    {
        nombre = "Muralla de hielo",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 27500, 39400, 57100 },
        dibujo = [[
oooooooo
XXXXXXXX
oooooooo
oooooooo
XXXXXXXX
oooooooo
oooooooo
oooooooo]],
    },
    {
        -- Puntos Y barro, con seis colores. Los puntos salen de las jugadas
        -- gordas y el barro de las jugadas colocadas, y con seis colores no
        -- suelen ser la misma.
        nombre = "Puntos en el fango",
        movimientos = 32, colores = 6,
        objetivo = { tipo = "puntos", meta = 11500 },
        extra = { { tipo = "barro" } },
        estrellas = { 11500, 16500, 23900 },
        dibujo = [[
########
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
########]],
    },
    {
        nombre = "Islas heladas",
        movimientos = 32, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 13100, 18800, 27300 },
        dibujo = [[
oo..oo..
oX..oX..
oo..oo..
oo..oo..
oooooooo
oooooooo
oooooooo
oooooooo]],
    },
    {
        -- Dos picos y un valle: las columnas suben, bajan y vuelven a subir,
        -- asi que hay tres alturas de boca distintas y lo nuevo entra por
        -- seis sitios a la vez.
        nombre = "Sierra",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 17100, 24400, 35400 },
        dibujo = [[
.#....#.
.##..##.
.######.
oooooooo
oooooooo
oooooooo
oooooooo
oooooooo]],
    },
    {
        nombre = "Pastillas en el cuenco",
        movimientos = 46, colores = 5,
        objetivo = { tipo = "pastillas", n = 3 },
        extra = { { tipo = "barro" } },
        estrellas = { 24900, 35600, 51600 },
        dibujo = [[
##....##
###..###
##oooo##
#oooooo#
#oooooo#
#oooooo#
#oooooo#
########]],
        pastillas = 3,
    },
    {
        nombre = "Todo el bol",
        movimientos = 46, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 31300, 44800, 65000 },
        dibujo = [[
oooooooo
oXooooXo
ooOOOOoo
ooOXXOoo
ooOOOOoo
ooOOOOoo
oXooooXo
oooooooo]],
    },
    {
        nombre = "Diamante helado",
        movimientos = 38, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19200, 27500, 39900 },
        dibujo = [[
...oo...
..oXXo..
.oooooo.
ooOOOOoo
ooOOOOoo
.oooooo.
..oXXo..
...oo...]],
    },
    {
        -- El barro en cuadros de dos por dos. Una racha de tres cruza dos
        -- cuadros como mucho, y los cuadros van al tresbolillo: no hay una
        -- fila ni una columna que los recorra todos.
        nombre = "Cuadros",
        movimientos = 34, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 22600, 32400, 46900 },
        dibujo = [[
oo##oo##
oo##oo##
##oo##oo
##oo##oo
oo##oo##
oo##oo##
##oo##oo
##oo##oo]],
    },
    {
        -- Tres colores de seis, que es la mitad del bol, y con cubitos por
        -- medio. Es el hermano mayor del 12 (alli eran tres de cuatro): el
        -- mismo reparto de atencion con el doble de ruido.
        nombre = "Seis sabores",
        movimientos = 34, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 2, n = 30 }, { color = 4, n = 30 },
                                                 { color = 6, n = 30 } } },
        estrellas = { 12200, 17400, 25300 },
        dibujo = [[
########
##x##x##
########
########
########
########
##x##x##
########]],
    },
    {
        nombre = "Embudo helado",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 18300, 26200, 38000 },
        dibujo = [[
oooooooo
oooooooo
.oooooo.
.oXooXo.
..oooo..
..oOOo..
..oooo..
..oooo..]],
    },
    {
        nombre = "Pozo profundo",
        movimientos = 38, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19800, 28300, 41000 },
        dibujo = [[
oXo..oXo
ooo..ooo
ooo..ooo
oooooooo
ooOOOOoo
ooOOOOoo
oooooooo
oooooooo]],
    },
    {
        -- El barro solo en las cuatro esquinas, y las esquinas de un bol son
        -- el sitio por donde menos pasa una racha: tienen la mitad de vecinas
        -- que el centro. Veinticuatro capas que cuestan mas que las sesenta
        -- y cuatro del 59.
        nombre = "Cuatro esquinas",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 22300, 31800, 46200 },
        dibujo = [[
Xoo##ooX
oo####oo
o######o
########
########
o######o
oo####oo
Xoo##ooX]],
    },
    {
        -- Tres islas de DOS columnas, y dos columnas no dan una racha
        -- horizontal: hacen falta tres. Aqui no hay ni una jugada horizontal
        -- en todo el bol, y es el unico nivel del juego del que eso se puede
        -- decir. Cuatro colores, porque con cinco no se limpia.
        nombre = "Tres islas",
        movimientos = 36, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 11500, 16500, 23900 },
        dibujo = [[
oo.oo.oo
oo.oo.oo
oo.oo.oo
oo.oo.oo
oo.oo.oo
oo.oo.oo
oo.oo.oo
oo.oo.oo]],
    },
    {
        nombre = "Cuatro pastillas heladas",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "pastillas", n = 4 },
        extra = { { tipo = "hielo" } },
        estrellas = { 16900, 24100, 35000 },
        dibujo = [[
........
........
........
.#x##x#.
.######.
.######.
.#x##x#.
.######.]],
        pastillas = 4,
    },
    {
        nombre = "Granizada",
        movimientos = 34, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 5, n = 36 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 12800, 18300, 26600 },
        dibujo = [[
x#x#x#x#
########
#x#x#x#x
########
x#x#x#x#
########
#x#x#x#x
########]],
    },
    {
        nombre = "Bol de hierro",
        movimientos = 46, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 32200, 46100, 66800 },
        dibujo = [[
oooooooo
oooooooo
ooOOOOoo
ooOXXOoo
ooOXXOoo
ooOOOOoo
oooooooo
oooooooo]],
    },
    {
        -- Dos torres de UNA columna, una a cada lado, y en medio un bol de
        -- cuatro. Las torres no se tocan con nada: lo que cae en ellas se
        -- queda ahi, y sus ocho capas salen solo de rachas verticales de esa
        -- misma columna.
        nombre = "Islote",
        movimientos = 42, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 28800, 41200, 59700 },
        dibujo = [[
o.oooo.o
o.oooo.o
o.oooo.o
o.oooo.o
o.oooo.o
o.oooo.o
o.oooo.o
o.oooo.o]],
    },
    {
        nombre = "Puente de barro",
        movimientos = 44, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 23800, 34000, 49400 },
        dibujo = [[
oooooooo
oOOOOOOo
oOOOOOOo
oooooooo
oooooooo
ooo..ooo
oo....oo
oo....oo]],
    },
    {
        nombre = "Recoger en la ventisca",
        movimientos = 34, colores = 6,
        objetivo = { tipo = "recoger", lista = { { color = 1, n = 26 }, { color = 3, n = 26 } } },
        extra = { { tipo = "hielo" } },
        estrellas = { 12200, 17500, 25400 },
        dibujo = [[
#x#x#x#x
########
x#x#x#x#
########
########
#x#x#x#x
########
x#x#x#x#]],
    },
    {
        nombre = "Cruz helada",
        movimientos = 36, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 20300, 29100, 42200 },
        dibujo = [[
..XooX..
..oooo..
oooooooo
ooOOOOoo
ooOOOOoo
oooooooo
..oooo..
..XooX..]],
    },
    {
        nombre = "Ultimo cuenco",
        movimientos = 42, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19400, 27800, 40300 },
        dibujo = [[
##....##
###..###
##XooX##
#oOOOOo#
#oOOOOo#
#oOOOOo#
#oOOOOo#
########]],
        pastillas = 2,
    },
    {
        nombre = "Marco doble",
        movimientos = 48, colores = 5,
        objetivo = { tipo = "pastillas", n = 3 },
        extra = { { tipo = "barro" } },
        estrellas = { 32300, 46200, 67000 },
        dibujo = [[
oooooooo
oOOOOOOo
oo####oo
oo####oo
oo####oo
oo####oo
oOOOOOOo
oooooooo]],
        pastillas = 3,
    },
    {
        nombre = "Diamante negro",
        movimientos = 40, colores = 5,
        objetivo = { tipo = "barro" },
        estrellas = { 19500, 27900, 40400 },
        dibujo = [[
...oo...
..oXXo..
.oOOOOo.
oOOOOOOo
oOOOOOOo
.oOOOOo.
..oXXo..
...oo...]],
    },
    {
        nombre = "Torres del final",
        movimientos = 38, colores = 4,
        objetivo = { tipo = "barro" },
        estrellas = { 34400, 49200, 71300 },
        dibujo = [[
X.O.O.X.
o.O.O.o.
o.X.X.o.
oooooooo
oOOOOOOo
oooooooo
########
########]],
    },
    {
        -- Tres objetivos a la vez -- puntos, barro y hielo -- y seis colores.
        -- Es el unico nivel del juego que pide las tres cosas, y va aqui y no
        -- en el 100 porque el ultimo tiene que poder ganarse jugando bien y
        -- no leyendo la cabecera tres veces.
        nombre = "Puntos de oro",
        movimientos = 38, colores = 6,
        objetivo = { tipo = "puntos", meta = 15300 },
        extra = { { tipo = "barro" }, { tipo = "hielo" } },
        estrellas = { 15300, 21900, 31800 },
        dibujo = [[
########
#oXooXo#
#oooooo#
#oooooo#
#oooooo#
#oooooo#
#oXooXo#
########]],
    },
    {
        -- El ultimo. Un bol con las cuatro esquinas comidas, doble capa en
        -- casi todo, cuatro cubitos en el centro de la doble capa y tres
        -- pastillas que ademas hay que bajar. No trae nada que no se haya
        -- visto: trae todo a la vez, que es de lo que iban los cien.
        nombre = "El bol de Kiko",
        movimientos = 54, colores = 5,
        objetivo = { tipo = "barro" },
        extra = { { tipo = "pastillas", n = 3 } },
        estrellas = { 31900, 45600, 66200 },
        dibujo = [[
..oooo..
.oOOOOo.
oOOXXOOo
oOOXXOOo
oOOOOOOo
oOOOOOOo
.oOOOOo.
..oooo..]],
        pastillas = 3,
    },
}

Levels.total = #Levels.lista

--== Lectura del dibujo ====================================================

local function filas(dibujo)
    local out = {}
    for linea in (dibujo .. "\n"):gmatch("(.-)\n") do
        if #linea > 0 then out[#out + 1] = linea end
    end
    return out
end

function Levels.get(n)
    return Levels.lista[math.max(1, math.min(n, #Levels.lista))]
end

-- Las dos funciones que pide `Board.nuevo`, sacadas del dibujo. Van juntas
-- porque leen el mismo caracter: separarlas invitaria a que un nivel tuviera
-- barro en una casilla que no existe.
function Levels.mascara(nivel)
    local f = filas(nivel.dibujo)
    return function(c, r)
        local ch = f[r] and f[r]:sub(c, c) or "#"
        return ch ~= "." and ch ~= ""
    end
end

function Levels.barro(nivel)
    local f = filas(nivel.dibujo)
    return function(c, r)
        local ch = f[r] and f[r]:sub(c, c) or "#"
        if ch == "o" or ch == "X" then return 1 elseif ch == "O" then return 2 end
        return 0
    end
end

-- Donde empieza congelada la galleta. El cubito viaja con la galleta y no con
-- la casilla -- cae con ella --, asi que esto es el reparto de salida y no una
-- propiedad del tablero: en cuanto rueda la primera cascada, los cubitos que
-- queden ya no estan donde los puso el dibujo.
-- El moho del dibujo: de donde SALE. A partir de ahi lo decide el tablero, que
-- lo extiende una casilla cada dos jugadas mientras quede alguna. Por eso un
-- bol con moho se escribe con dos o tres manchas y sitio libre alrededor: sin
-- sitio no crece, y entonces el moho es barro con otro color.
function Levels.moho(nivel)
    local f = filas(nivel.dibujo)
    return function(c, r)
        local ch = f[r] and f[r]:sub(c, c) or "#"
        return ch == "m"
    end
end

function Levels.hielo(nivel)
    local f = filas(nivel.dibujo)
    return function(c, r)
        local ch = f[r] and f[r]:sub(c, c) or "#"
        return ch == "x" or ch == "X"
    end
end

-- Cuantas estrellas dan estos puntos.
function Levels.estrellas(nivel, puntos)
    local n = 0
    for _, umbral in ipairs(nivel.estrellas) do
        if puntos >= umbral then n = n + 1 end
    end
    return n
end

-- El texto del objetivo, para el HUD y para la pantalla de antes de empezar.
--
-- `nivel.extra` es un objetivo de MAS, que hay que cumplir ademas del suyo
-- (las rondas glotonas del arcade). Se escribe aqui y no en el arcade porque
-- una frase de objetivo es una frase de objetivo: tenerla en dos sitios es la
-- forma de que un dia digan cosas distintas.
function Levels.textoObjetivo(nivel)
    local Palette = require("src.palette")
    local o = nivel.objetivo
    local mas = ""
    for _, e in ipairs(nivel.extra or {}) do
        if e.tipo == "pastillas" then
            mas = mas .. (e.n == 1 and " y dale 1 pastilla a Kiko"
                                   or string.format(" y dale %d pastillas a Kiko", e.n))
        elseif e.tipo == "barro" then
            mas = mas .. " y limpia el barro"
        elseif e.tipo == "hielo" then
            mas = mas .. " y rompe los cubitos"
        elseif e.tipo == "moho" then
            -- "Acaba con el moho" y no "limpia el moho": el barro se limpia y
            -- se queda limpio, y con este hay que llegar a cero antes de que
            -- se extienda otra vez. La frase tiene que sonar a carrera.
            mas = mas .. " y acaba con el moho"
        end
    end
    -- El `mas` se pega SIEMPRE, sea cual sea el objetivo de la casa. Antes
    -- solo se pegaba al de puntos, porque en el arcade una ronda no tiene
    -- otro; en la campana hay niveles que piden un color y ademas el barro, y
    -- una frase que se callara la mitad del objetivo seria la peor de las
    -- mentiras posibles -- la que se descubre al perder.
    if o.tipo == "puntos" then
        return string.format("Llega a %d puntos", o.meta) .. mas
    elseif o.tipo == "barro" then
        return "Limpia todo el barro" .. mas
    elseif o.tipo == "pastillas" then
        -- "Dale" y no "baja": la pastilla no se queda en la ultima fila, se
        -- cae del bol y se la toma el perro. El texto cuenta lo que se ve.
        return (o.n == 1 and "Dale 1 pastilla a Kiko"
                         or string.format("Dale %d pastillas a Kiko", o.n)) .. mas
    elseif o.tipo == "recoger" then
        local partes = {}
        for _, r in ipairs(o.lista) do
            partes[#partes + 1] = string.format("%d de %s", r.n, Palette.galletas[r.color].nombre)
        end
        return "Recoge " .. table.concat(partes, " y ") .. mas
    end
    return "?"
end

return Levels
