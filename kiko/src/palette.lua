-- Paleta cerrada. Todo lo que se dibuja sale de aqui: ni un RGB suelto en el
-- resto del codigo. Con una paleta corta los sprites generados conviven sin
-- que se note la costura, y cambiar el humor entero del juego es tocar tres
-- lineas de este archivo.
--
-- El humor es el de una cocina a media manana: galletas de colores pastel
-- dentro de un BOL DE ACERO sobre un mantel crema. Los pasteles son claros a
-- proposito -- el juego va de premiar a un perro, no de un escaparate de
-- neon -- y eso obliga a dos cosas: el metal del tablero tiene que ser mas
-- OSCURO que cualquier galleta (si no, las galletas se disuelven en el fondo)
-- y el contorno de tinta de cada sprite pasa de util a imprescindible.
--
-- Alpha: el arte NO lo usa nunca -- un pixel de galleta es opaco o no esta --
-- y los unicos sitios donde aparece son los velos de la interfaz, el rastro
-- de las particulas y los numeros que suben al romper. Los tres llevan su
-- alpha explicito donde se dibujan y ninguno pasa por debajo del tablero.
--
-- Las seis galletas son las seis primeras y NO se distinguen solo por color:
-- cada una tiene una silueta propia (hueso, borde ondulado, media luna de
-- limon, palo en cruz, huella y corazon). Un daltonismo
-- severo deja este juego jugable, y esa es la razon de que la forma no sea
-- decorativa. Y con pasteles lo es aun mas: al bajar la saturacion, dos
-- familias vecinas se parecen mas entre si de lo que se parecian en tonos
-- vivos, y lo unico que nunca se confunde es la silueta. Ver README.md.

local function hex(s)
    return {
        tonumber(s:sub(1, 2), 16) / 255,
        tonumber(s:sub(3, 4), 16) / 255,
        tonumber(s:sub(5, 6), 16) / 255,
        1,
    }
end

local Palette = {
    -- Las seis galletas: base, luz y sombra de cada una. El brillo especular
    -- es siempre `miga`, comun a todas, que es lo que las hermana en la
    -- misma bandeja. En pastel, la sombra de cada familia es la que hace el
    -- trabajo de distinguirlas: es el tono mas saturado de las tres y es el
    -- que sobrevive al mirar el tablero de lejos.
    fresaDark  = hex("c2687f"), fresa  = hex("f59ab0"), fresaLite  = hex("ffc8d6"),
    naranjaDark= hex("c57c4d"), naranja= hex("f7ae7a"), naranjaLite= hex("ffd6b2"),
    limonDark  = hex("c0a04a"), limon  = hex("f0d478"), limonLite  = hex("ffeeb0"),
    mentaDark  = hex("5ea888"), menta  = hex("93dcb4"), mentaLite  = hex("c4f0da"),
    moraDark   = hex("6c8cbd"), mora   = hex("9dc0ec"), moraLite   = hex("cfe3fb"),
    uvaDark    = hex("8e73bb"), uva    = hex("c0a4e8"), uvaLite    = hex("e3d4ff"),

    miga    = hex("fffdf6"),   -- el brillo de todas y las migas de fondo
    -- La pastilla que hay que bajar: una capsula mitad roja mitad crema. El
    -- rojo es el UNICO rojo saturado que queda en el tablero -- las galletas
    -- son pasteles -- y eso es lo que hace que se vea entrar desde arriba sin
    -- mirarla: no compite con ninguna familia porque no se parece a ninguna.
    pastilla     = hex("e8746a"),
    pastillaLite = hex("ff9d92"),
    pastillaDark = hex("a84a45"),
    pastillaCrema= hex("fdf6ef"),
    pastillaSombra=hex("d5c8bc"),

    -- El bol. Cuatro grises de acero y en ese orden se leen como metal y no
    -- como plastico gris: el salto de `metal` a `metalShine` es grande y
    -- corto -- el brillo ocupa poquisimos pixeles -- y es justo lo que hace
    -- que una superficie parezca pulida.
    metalDark = hex("6a7683"),
    metal     = hex("9aa6b3"),
    metalLite = hex("c7d1db"),
    metalShine= hex("edf3f8"),

    ink      = hex("36292a"),   -- el contorno de todo y el velo de la interfaz
    hueco    = hex("79838f"),   -- fondo del bol: casilla vacia del tablero
    huecoAlt = hex("85909d"),   -- la de al lado, para el damero
    -- El barro de las patas del perro: lo que hay que limpiar del bol. Marron
    -- y no gris: sobre el acero, cualquier mancha grisacea se lee como una
    -- casilla mas oscura -- como parte del tablero -- y no como suciedad.
    barro    = hex("a87c4e"),   -- una capa, ya medio seca
    barro2   = hex("6d4c2c"),   -- dos capas, recien pisado
    barroLite= hex("c49b64"),   -- la costra que se levanta por los bordes

    -- El MOHO: lo que sale en el bol si lo dejas. Verde OLIVA y no el verde de
    -- la menta, y la razon es la de siempre en esta paleta -- que dos cosas
    -- distintas no se parezcan: el moho vive en el suelo del bol, debajo de
    -- las galletas, y un verde pastel ahi abajo se leeria como una menta caida
    -- detras del tablero. Este es mas oscuro que cualquier familia y esta
    -- tirado hacia el amarillo, que es el color de lo que lleva demasiado
    -- tiempo en un sitio.
    moho     = hex("7d9b4e"),
    mohoLite = hex("a9c46d"),   -- los brotes del borde, que son los mas vivos

    -- Kiko NO esta en esta tabla, y es la unica cosa del juego que no lo esta:
    -- sus sesenta y cuatro caras vienen dibujadas a mano en `art/kiko.png` con
    -- sus propios marrones (ver "La hoja de Kiko" en `src/art.lua`). Los cinco
    -- tonos de perro que habia aqui se fueron con el generador que los usaba.
    --
    -- Lo que si sigue siendo cosa de la paleta es que el perro y el barro no se
    -- parezcan: los dos marrones del juego se ven a la vez -- el barro en el
    -- bol y el perro justo encima -- y un perro del color de la suciedad no es
    -- el perro de nadie. La hoja esta dibujada mas clara y mas amarilla que
    -- `barro` por eso, y es lo que hay que mirar si algun dia se retoca el
    -- barro de aqui arriba.

    -- El hielo del cubito. Azules mas CLAROS que cualquier galleta, y eso no
    -- es gusto: el cubito se dibuja ENCIMA de la galleta, asi que si el hielo
    -- cayera dentro del rango de los pasteles, un cubito sobre la mora seria
    -- una mancha azul encima de otra mancha azul y no se leeria que hay algo
    -- encerrado. El canto oscuro es lo unico que tiene saturacion, y esta ahi
    -- para darle arista: un bloque sin canto es escarcha, no un cubito.
    hielo     = hex("cfeef7"),
    hieloLite = hex("f4feff"),
    hieloDark = hex("7fb6d4"),

    -- El mantel: las bandas anchas del fondo, detras de todo.
    fondo    = hex("f3e3d3"),
    fondoAlt = hex("e9d6c4"),

    -- Interfaz.
    gold    = hex("e8a83c"),
    red     = hex("ec7f7f"),
    green   = hex("74cfa0"),
    -- La barra de hambre esta dibujada como un sprite mas -- luz arriba, base,
    -- sombra abajo -- y por eso el oro y el verde tienen sus tres tonos. Un
    -- relleno de un solo color se lee como una barra de instalador; con las
    -- tres franjas se lee como pixel art, que es lo que hay a su alrededor.
    goldLite  = hex("f7c968"),
    goldDark  = hex("b87d26"),
    greenLite = hex("a3e6c2"),
    greenDark = hex("4aa87c"),
    -- El rojo tiene sus tres tonos por lo mismo que el oro y el verde: un
    -- boton es una galleta de interfaz -- luz arriba, base, sombra abajo -- y
    -- un tono al que le falten la luz y la sombra sale plano justo al lado de
    -- otro que las tiene.
    redLite   = hex("f8a7a7"),
    redDark   = hex("b45555"),
    uiBack  = hex("f7ece0"),
    uiPanel = hex("fffaf3"),
    uiLine  = hex("c2a893"),
    text    = hex("46332c"),
    dim     = hex("9a8475"),
    sombra  = hex("a98d76"),   -- la sombra de una letra sobre un panel claro
}

-- Las seis familias, en el orden en que el tablero las numera. `color` es el
-- indice y todo el juego habla en indices; los nombres estan aqui para la
-- interfaz y para los objetivos ("recoge 20 de fresa").
Palette.galletas = {
    { key = "fresa", nombre = "fresa",  base = Palette.fresa, lite = Palette.fresaLite, dark = Palette.fresaDark },
    { key = "naranja", nombre = "naranja", base = Palette.naranja, lite = Palette.naranjaLite, dark = Palette.naranjaDark },
    { key = "limon", nombre = "limón",  base = Palette.limon, lite = Palette.limonLite, dark = Palette.limonDark },
    { key = "menta", nombre = "menta",  base = Palette.menta, lite = Palette.mentaLite, dark = Palette.mentaDark },
    { key = "mora",  nombre = "mora",   base = Palette.mora,  lite = Palette.moraLite,  dark = Palette.moraDark  },
    { key = "uva",   nombre = "uva",    base = Palette.uva,   lite = Palette.uvaLite,   dark = Palette.uvaDark   },
}

-- Mezcla dos colores. Solo para generar sprites y para los velos: en pantalla
-- se dibuja un color de la tabla, nunca uno interpolado en vivo.
function Palette.mix(a, b, t)
    return {
        a[1] + (b[1] - a[1]) * t,
        a[2] + (b[2] - a[2]) * t,
        a[3] + (b[3] - a[3]) * t,
        1,
    }
end

-- El mismo color con alpha. Devuelve una tabla nueva: nadie puede escribir
-- sobre la paleta por accidente.
function Palette.alpha(c, a)
    return { c[1], c[2], c[3], a }
end

--== Los tonos de la botonera ==============================================

-- Un boton esta dibujado como una GALLETA: canto oscuro, cuerpo, una fila de
-- luz arriba y una de sombra abajo. Eso son cuatro colores por tono, y aqui
-- es donde viven -- en la paleta y no en `src/ui.lua` -- porque la regla es
-- que ni un color se decide fuera de este archivo.
--
-- `letra` va en la fila porque no se deduce del tono: sobre el oro y sobre la
-- crema la letra es el marron de siempre, pero sobre el verde y el rojo, que
-- son los dos tonos oscuros, ese marron se apaga y hay que subir a la miga.
-- Es el unico sitio del juego donde el color del texto depende de lo que tiene
-- debajo, y por eso se escribe en vez de calcularse.
--
-- La tabla se indexa por el PROPIO color que se pasa como tono (`Palette.gold`
-- es una sola tabla en todo el programa, asi que sirve de llave). Un tono que
-- no este -- una mezcla, una familia de galleta -- se deriva mezclando, que
-- sale peor que estos cuatro escritos a mano pero nunca se queda sin luz.
local TONOS = {}

-- `llave` es el color que la pantalla pasa como `opts.tono`; `base` es la cara
-- del boton. Son distintos en uno solo -- el neutro -- y por eso van separados.
local function tono(llave, base, luz, sombra, letra)
    TONOS[llave] = { base = base, luz = luz, sombra = sombra,
                     canto = sombra, letra = letra }
end

tono(Palette.gold,  Palette.gold,  Palette.goldLite,  Palette.goldDark,  Palette.text)
tono(Palette.green, Palette.green, Palette.greenLite, Palette.greenDark, Palette.miga)
tono(Palette.red,   Palette.red,   Palette.redLite,   Palette.redDark,   Palette.miga)
-- El tono neutro -- el de "Atras", "Salir", "Dejarlo" -- no es un caramelo
-- apagado: es el panel de siempre con el canto marron. Un boton secundario
-- tiene que leerse como PAPEL al lado de uno de caramelo, y para eso lo que
-- cambia no es el brillo, es el material.
tono(Palette.uiLine, Palette.uiPanel, Palette.miga, Palette.uiLine, Palette.text)

function Palette.tono(c)
    return TONOS[c] or {
        base   = c,
        luz    = Palette.mix(c, Palette.miga, 0.45),
        sombra = Palette.mix(c, Palette.ink, 0.30),
        canto  = Palette.mix(c, Palette.ink, 0.30),
        letra  = Palette.text,
    }
end

return Palette
