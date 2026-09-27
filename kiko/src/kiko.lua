-- Kiko: en que animo esta el perro y que cara le toca.
--
-- El perro es lo unico del juego que se mueve sin que nadie lo toque y sin
-- estar contando nada. La barra de hambre dice cuanto falta, la cifra dice los
-- movimientos; la cara no dice ningun numero, dice COMO va la cosa. Por eso
-- vive en su propio archivo y no dentro de la cabecera: es lo que hace que la
-- portada, el mapa, la cabecera y el cartel del final ensenen el mismo perro
-- con el mismo reloj en vez de cuatro perros parecidos.
--
-- Aqui no se decide NADA de la partida: quien sabe si quedan dos movimientos o
-- si falta poco es la pantalla de juego, y lo unico que hace es pedir un animo
-- por su nombre (`perro:pon("nervioso")`). Lo que hay en este archivo es la
-- lista de caras de cada animo y el reloj que las pasa.
--
-- Las caras son fotogramas de `art/kiko.png` y se nombran con su numero de la
-- hoja -- decena la columna, unidad la fila (ver `Art.idKiko`). Se escriben
-- tal cual: el numero es lo que se lee mirando la hoja, y cualquier otro
-- nombre obligaria a traducir para elegir una cara nueva.

local Art = require("src.art")

local Kiko = {}

-- Los animos, en orden de lo que cuentan.
--
-- El paso es UNO para todo el animo, y no hay tiempos por fotograma. Lo que
-- hace que el perro se quede tieso un buen rato y de golpe haga un gesto no es
-- un reloj con excepciones ni una lista con la misma cara repetida ocho veces:
-- son DOS animos que se turnan -- uno de una sola cara y paso largo, otro corto
-- con el gesto dentro. El ritmo se escribe en la tabla, no en el `update`.
--
-- `sigue` es a donde VUELVE un animo cuando se le acaban las caras, y es lo que
-- hace ese turno posible. Lo llevan tres. El bostezo, que pasa UNA vez y vuelve
-- a lo suyo -- un bostezo en bucle es un perro roto --, y el par
-- `reposo`/`quieto`, que se turnan para siempre (ver ahi).
Kiko.ANIMOS = {
    -- Abajo del umbral el perro esta quieto DE VERDAD: una sola cara, sin mover
    -- un pixel, y cada cinco segundos un parpadeo. Son dos animos y no una
    -- lista larga con la cara fija repetida, porque el paso es uno por animo:
    -- con un solo numero para las dos cosas, o el parpadeo va a camara lenta o
    -- la cara fija se cambia por si misma sesenta veces para no cambiar nada.
    --
    -- El que se PIDE es `reposo` -- es el estado --; `quieto` es el gesto y se
    -- llega a el solo. Van y vienen con `sigue`, que es el mecanismo que ya
    -- estaba ahi para el bostezo.
    reposo   = { paso = 3.40, caras = { 11 }, sigue = "quieto" },
    quieto   = { paso = 0.42, caras = { 16, 26, 36, 46 }, sigue = "reposo" },

    -- Con el bol casi lleno: la cabeza de un lado a otro, sin parar. Es el
    -- unico animo que va mas rapido que el pulso del juego, y esa es la idea:
    -- se nota por el rabillo del ojo sin mirar la cabecera.
    nervioso = { paso = 0.16, caras = { 12, 32, 52, 62, 72, 63, 73 } },

    -- El ultimo movimiento: una sola cara y quieta. Un perro que deja de
    -- moverse llama mas la atencion que uno que se mueve, y aqui lo que hace
    -- falta es que se mire la cifra de al lado.
    ultimo   = { paso = 1.00, caras = { 67 } },

    -- Aburrido -- nadie casa nada desde hace un rato -- y en DOS versiones, como
    -- el idle: las mismas dos mitades del bol que separan `reposo` de
    -- `nervioso` separan tambien estas dos, y por la misma razon. Con el bol a
    -- medias el perro sigue teniendo hambre: bosteza, y se queda mirando. Con
    -- el bol casi lleno ya ha comido bastante y se echa a DORMIR, que es lo que
    -- hace un perro lleno al que nadie le hace caso.
    --
    -- El bostezo pasa UNA vez y vuelve al REPOSO (`sigue`) -- a la cara fija, no
    -- al parpadeo: encadenar un bostezo con un parpadeo los lee como un solo
    -- gesto largo. El sueno da vueltas, porque un perro dormido sigue dormido.
    bostezo  = { paso = 0.17, caras = { 17, 27, 37, 47, 67 }, sigue = "reposo" },
    dormido  = { paso = 0.85, caras = { 68, 77 } },

    -- El final. La cara de ganar es una sola porque el cartel ya se mueve
    -- entero al salir; la de perder son dos, que es lo que la convierte en una
    -- pregunta -- mira al suelo, levanta la cabeza -- en vez de en un dibujo
    -- triste puesto ahi.
    gana     = { paso = 1.00, caras = { 75 } },
    fallo    = { paso = 0.70, caras = { 28, 24 } },

    -- La pregunta de dejar el nivel. Una sola cara, de frente y con las dos
    -- orejas tiesas: el cartel pregunta y el perro MIRA, que es lo que
    -- convierte un velo con dos botones en alguien esperando una respuesta. Y
    -- quieta a proposito, porque debajo de la pregunta lo que tiene que
    -- llevarse la mirada son los botones.
    duda     = { paso = 1.00, caras = { 53 } },

    -- El mapa. Quieto del todo: el camino ya se arrastra, los nodos se hunden
    -- y las migas cuentan por donde vas; un perro parpadeando ahi en medio es
    -- una cosa mas moviendose en la pantalla mas movida del juego.
    mapa     = { paso = 1.00, caras = { 15 } },
}

local Perro = {}
Perro.__index = Perro

-- Sin decir animo se arranca en `reposo` y no en `quieto`: quien no pide nada
-- -- la portada, la cabecera al empezar -- quiere el perro parado, y entrar por
-- el gesto lo ensena parpadeando antes de haberse estado quieto una vez.
function Kiko.nuevo(animo)
    local p = setmetatable({}, Perro)
    p:arrancar(animo or "reposo")
    p.pedido = animo or "reposo"
    return p
end

function Perro:arrancar(animo)
    self.animo = animo
    self.cara  = 1
    self.reloj = 0
end

-- Pedir el animo que ya esta puesto NO lo reinicia. Es lo que permite que la
-- pantalla de juego diga el animo entero cada fotograma -- que es la unica
-- forma de que la cara no se quede colgada de un estado viejo -- sin que el
-- perro se pase la partida repitiendo el primer fotograma.
--
-- Y se compara contra lo PEDIDO y no contra lo que se esta viendo, que ahora
-- cambia solo todo el rato: `reposo` y `quieto` se turnan sin que nadie lo
-- pida, y el bostezo vuelve al reposo por su cuenta. Comparando contra la cara
-- de turno cada fotograma volveria a empezar en cuanto acabara -- el perro se
-- pasaria el rato muerto bostezando sin parar, que es justo lo que `sigue` evita. Asi bosteza
-- una vez por cada rato muerto, y el siguiente llega cuando se vuelve a casar
-- algo y a parar.
function Perro:pon(animo)
    if self.pedido == animo then return end
    self.pedido = animo
    self:arrancar(animo)
end

function Perro:update(dt)
    self.reloj = self.reloj + dt
    local a = Kiko.ANIMOS[self.animo]
    while self.reloj >= a.paso do
        self.reloj = self.reloj - a.paso
        self.cara = self.cara + 1
        if self.cara > #a.caras then
            if a.sigue then
                self:arrancar(a.sigue)
                return
            end
            self.cara = 1
        end
    end
end

-- El id del sprite que toca. Lo piden los sitios que ademas necesitan MEDIRLO
-- antes de pintarlo, como la cabecera.
function Perro:id()
    return Art.idKiko(Kiko.ANIMOS[self.animo].caras[self.cara])
end

-- A escala ENTERA y en posicion entera, como todo el arte del juego: la cara
-- es lo mas grande que se dibuja fuera del tablero y medio pixel de sobra se
-- le ve en el canto de una oreja.
function Perro:dibujar(x, y, escala)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Art.get(self:id()), math.floor(x), math.floor(y), 0, escala, escala)
end

return Kiko
