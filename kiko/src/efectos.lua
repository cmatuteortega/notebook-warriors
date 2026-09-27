-- Lo que no es tablero ni interfaz: el temblor, los rayos, las ondas, los
-- numeros que suben y los rotulos.
--
-- Todo lo de aqui es DECORADO -- quitarlo entero deja el juego funcionando y
-- sin una sola regla distinta -- y a la vez es la mitad del juego, porque un
-- match-3 sin esto es una hoja de calculo con colores. La regla que siguen
-- todos: cada efecto dura MENOS que la animacion que acompana. Un rayo que
-- sigue ahi cuando ya ha caido la galleta nueva se lee como suciedad.
--
-- Dos espacios: los rayos, las ondas y el temblor van en pixeles de ARTE
-- (viven encima del tablero); los numeros y los rotulos van en VIRTUAL,
-- porque son texto y el texto necesita la resolucion fina.

local Constants = require("src.constants")
local Palette   = require("src.palette")
local Sfx       = require("src.sfx")

local Efectos = {}

local temblor = { fuerza = 0, t = 0 }
local rayos, ondas, numeros, rotulos, destellos = {}, {}, {}, {}, {}
local cometas = {}
local marcador = { valor = 0, desde = 0, hasta = 0, t = 0, dur = 0,
                   escala = 1, vel = 0, calor = 0, tic = 0 }

-- El aire entre la cifra que sube y su multiplicador.
local HUECO_MULT = 7

function Efectos.reset()
    temblor.fuerza, temblor.t = 0, 0
    rayos, ondas, numeros, rotulos, destellos = {}, {}, {}, {}, {}
    cometas = {}
    Efectos.marcador(0)
end

--== Temblor ===============================================================

-- El temblor se pide por FUERZA, no por duracion: quien lo pide sabe si ha
-- roto tres galletas o ha reventado media pantalla, y el tiempo sale de ahi.
-- Nunca se acumula por encima de 3 pixeles de arte: mas que eso y el tablero
-- deja de leerse, que es justo cuando el jugador esta mirandolo.
function Efectos.temblar(fuerza)
    temblor.fuerza = math.min(3, math.max(temblor.fuerza, fuerza))
    temblor.t = math.max(temblor.t, 0.12 + fuerza * 0.06)
end

-- Desplazamiento del fotograma, en pixeles de arte ENTEROS. Si no fueran
-- enteros el tablero entero se veria borroso justo en el momento en que mas
-- se mira.
function Efectos.sacudida()
    if temblor.t <= 0 then return 0, 0 end
    local f = temblor.fuerza * math.min(1, temblor.t * 6)
    return math.floor(love.math.random(-100, 100) / 100 * f + 0.5),
           math.floor(love.math.random(-100, 100) / 100 * f + 0.5)
end

--== Rayos =================================================================

-- El rayo de una galleta rayada: una barra que CRECE desde la casilla hacia
-- los dos lados y se apaga. No es un rectangulo de color plano: lleva un
-- nucleo de miga y dos bordes del color de la galleta, que es lo que lo hace
-- parecer luz en vez de una regla pintada.
function Efectos.rayo(x, y, horizontal, color, largo)
    rayos[#rayos + 1] = { x = x, y = y, h = horizontal, color = color,
                          largo = largo, t = 0, vida = 0.30 }
end

function Efectos.onda(x, y, radio, color)
    ondas[#ondas + 1] = { x = x, y = y, radio = radio, color = color,
                          t = 0, vida = 0.38 }
end

-- El fogonazo blanco de una casilla justo antes de romperse.
function Efectos.destello(x, y, id)
    destellos[#destellos + 1] = { x = x, y = y, id = id, t = 0, vida = 0.10 }
end

--== Cometas ===============================================================

-- El trozo de estrella que sale volando a buscar una galleta.
--
-- Es el unico efecto del juego que VIAJA, y es lo que obliga a que sea un
-- efecto y no un tween sobre una pieza: no es una galleta que se mueve, es un
-- premio que va a por otra, y tiene que poder salir de una casilla que en ese
-- momento ya se esta rompiendo.
--
-- Va en ARCO y no en linea recta, y la curva alterna de lado por trozo: tres
-- estrellas en linea recta desde el mismo sitio se ven como un abanico que se
-- abre y no se puede seguir ninguna. Con arcos a un lado y a otro, cada una
-- dibuja su propio camino.
--
-- `retardo` escalona las salidas. Es lo que hace que se lean TRES y no una
-- mancha: salen a un suspiro una de otra, como una rafaga.
function Efectos.cometa(x0, y0, x1, y1, color, retardo, vuelo, curva)
    cometas[#cometas + 1] = { x0 = x0, y0 = y0, x1 = x1, y1 = y1, color = color,
                              curva = curva or 0, t = -(retardo or 0), vida = vuelo or 0.34 }
end

--== El marcador ==========================================================

-- El contador de puntos de la cabecera no SALTA: rueda.
--
-- La cifra de verdad la lleva la pantalla (`progreso.puntos`, que es lo que
-- miran las reglas y el objetivo); esto es solo lo que se ve, corriendo
-- detras. Toda la sensacion esta en la diferencia entre las dos: un numero
-- que pasa de 1.200 a 3.400 en un fotograma no se lee como haber ganado 2.200
-- puntos, se lee como que el marcador ha cambiado de valor. Rodando, la
-- ganancia DURA -- medio segundo de cifras pasando y clics subiendo -- y lo
-- que dura se siente.
--
-- Por eso vive aqui y no en el HUD ni en el tablero: es decorado. Quitarlo
-- entero deja la cabecera diciendo el numero bueno, sin una regla distinta.
--
-- Lleva tres cosas y las tres las pinta la cabecera sin saber que existen:
-- la cifra, el ACHUCHON (lo que se hincha la letra al cobrar, que es un
-- MUELLE -- ver abajo) y el CALOR (lo alto que va la cadena, que tine la cifra
-- de oro). El achuchon es de la jugada y se queda quieto enseguida; el calor
-- es de la cadena y aguanta, porque lo que cuenta una cadena de seis no es
-- cada eslabon, es que sigue viva.

-- La cuenta entera nunca dura menos ni mas que esto. Por debajo de 0,22 s no
-- da tiempo a leer que ha rodado -- se ve un borron y ya esta el numero
-- nuevo -- y por encima de 0,5 s el eslabon siguiente de la cadena empieza con
-- el marcador todavia contando el anterior, y las dos cuentas se pisan.
local CUENTA_MIN, CUENTA_MAX = 0.22, 0.50

-- Lo que hay que ganar de golpe para que la cuenta dure el maximo. Una racha
-- de tres son 180 puntos y una pastilla 2.000: con el tope aqui en medio, lo
-- corriente rueda corto y lo gordo rueda largo, que es justo lo que hace que
-- lo gordo se note sin tener que anunciarlo.
local CUENTA_TOPE = 1800

-- El MUELLE del achuchon. La cifra no se hincha y se desinfla: REBOTA. Se
-- pasa de largo, se hunde un pelin por debajo de su tamano y se para, y ese
-- rebote es toda la diferencia entre un numero que crece y un numero que da un
-- golpe -- un desinflado recto se lee como una transicion, y un rebote se lee
-- como que algo ha impactado.
--
-- Es la ley de Hooke con Euler de toda la vida: fuerza contra lo desplazado,
-- menos el rozamiento. Los dos numeros estan MEDIDOS y no elegidos: con estos,
-- la cifra llega a su pico en 0,05 s, se hunde hasta el 97,6% y esta quieta a
-- los 0,25 s -- dentro de lo que tarda en venir el eslabon siguiente, que es la
-- condicion de que el rebote se vea y no estorbe.
local RIGIDEZ, AMORTIGUA = 500, 18

-- Lo que se empuja el muelle al cobrar, y lo que sube por eslabon de cadena.
-- La relacion entre empujon y lo que se hincha la cifra es una recta y tambien
-- esta medida: cada punto de empujon son dos centesimas de escala. Asi que una
-- jugada suelta es un +8% y el sexto eslabon un +16%.
--
-- Y AQUI SI SE ACUMULA, al reves que todo lo demas de este archivo: cobrar con
-- el muelle todavia en marcha empuja mas fuerte, que es exactamente lo que se
-- quiere de un combo. Lo que lo mantiene en su sitio no es dejar de sumar, es
-- el muelle: a medio segundo por eslabon una cadena de seis se queda en +17%,
-- medido, porque entre uno y otro ya ha tirado hacia abajo.
local EMPUJON, EMPUJON_ESLABON = 4.2, 0.8

-- Dos topes, y hacen falta los dos. El de la velocidad sujeta el empujon de un
-- fotograma; el de la escala sujeta lo que pasa cuando los empujones vienen
-- fotograma tras fotograma -- el remate del final, o una pastilla que cae
-- dentro de una cascada -- porque ahi el muelle no llega a tirar hacia abajo
-- entre uno y otro y la cifra sube andando aunque la velocidad este topada
-- (medido: sin el segundo tope, veinte cobros seguidos la ponen a 1,60 y se
-- sale de la cabecera). Al tocar el techo la velocidad se pone a cero: contra
-- una pared, un muelle deja de empujar.
--
-- 1,22 no lo toca una cadena de verdad -- la mas gorda medida se queda en
-- 1,17 -- y es lo que cabe: a cuerpo gigante, seis cifras hinchadas un 22%
-- todavia acaban a la derecha de los movimientos.
local EMPUJON_MAX = 9
local ESCALA_MAX = 1.22

-- Un dt enorme -- el movil volviendo de segundo plano -- revienta un muelle
-- integrado asi: con esta rigidez el limite esta medido en 1/11 de segundo, y
-- pasado eso la escala se va a infinito en tres fotogramas. Se recorta a 1/20,
-- que es el mismo tope que `main.lua` le pone a flux y por la misma razon, y
-- deja el margen de sobra. Ojo: a este archivo le llega el dt SIN recortar
-- (`ScreenManager.update(dt)`), asi que el tope tiene que estar aqui.
local DT_MAX = 1 / 20

-- Cada cuanto suena un clic mientras rueda. Cuarenta y cinco milisegundos son
-- unos veintidos por segundo: bastante para que se oiga como un rodillo y no
-- como notas sueltas, y poco para que las ocho voces de `cuenta` no se pisen.
local TIC = 0.045

-- Pone la cifra donde se le diga, sin contar nada. Es para empezar un nivel y
-- para el final, donde el cartel dice el total: con el marcador rodando por
-- detras, la cabecera y el cartel se contradirian delante del jugador.
function Efectos.marcador(puntos)
    marcador.valor, marcador.desde, marcador.hasta = puntos, puntos, puntos
    marcador.t, marcador.dur = 0, 0
    marcador.escala, marcador.vel = 1, 0
    marcador.calor, marcador.tic = 0, 0
end

-- Rueda hasta el total nuevo. `cascada` es el eslabon de la cadena que lo ha
-- dado, y es lo unico que separa una jugada suelta de un combo: sube el
-- achuchon y, sobre todo, sube el calor.
function Efectos.contar(puntos, cascada)
    cascada = cascada or 1
    local salto = puntos - marcador.valor
    -- Hacia atras no se cuenta: no pasa en el juego, y si pasara, un marcador
    -- que baja rodando se lee como una penalizacion que nadie ha impuesto.
    if salto <= 0 then return Efectos.marcador(puntos) end

    marcador.desde, marcador.hasta = marcador.valor, puntos
    marcador.t = 0
    -- El primer clic suena YA, en el mismo fotograma que el pop que lo ha
    -- dado. Heredando lo que quedara del tic anterior podia salir hasta 45 ms
    -- tarde, y a esa distancia ya no se oye como el mismo golpe.
    marcador.tic = 0
    marcador.dur = CUENTA_MIN + math.min(1, salto / CUENTA_TOPE) * (CUENTA_MAX - CUENTA_MIN)

    -- El empujon al muelle: se SUMA a lo que ya lleve. Cobrar con la cifra
    -- todavia botando del cobro anterior pega mas fuerte, y eso es un combo.
    marcador.vel = math.min(EMPUJON_MAX,
                            marcador.vel + EMPUJON + (cascada - 1) * EMPUJON_ESLABON)
    -- El calor si sube a saltos y baja despacio (ver `update`): es lo que hace
    -- que el sexto eslabon se encuentre la cifra ya dorada del quinto en vez
    -- de tener que encenderla otra vez desde cero.
    marcador.calor = math.min(1, math.max(marcador.calor, (cascada - 1) / 5))
end

-- Lo que la cabecera pinta. Se devuelve resuelto -- cifra, escala y color --
-- para que el HUD siga sin decidir nada: no sabe que hay una cuenta en marcha.
--
-- El color va de la tinta de siempre al oro de la barra de hambre que hay
-- justo debajo, y mezclar dos entradas de la paleta no abre la paleta: no
-- aparece ningun tono que no estuviera ya en los dos extremos. Que sea EL ORO
-- DE LA BARRA y no otro es lo que hace que en una cadena larga la cifra y la
-- barra se enciendan como una sola cosa, que es lo que son.
local tinte = { 0, 0, 0, 1 }
function Efectos.cuenta()
    -- Lo hinchada que esta la cifra AHORA, de 0 a 1 contra el achuchon mas
    -- gordo que puede darse. Sale del muelle y no de un contador aparte: hay
    -- una sola cosa que mide el golpe, y asi el color no puede ir por un lado
    -- y el tamano por otro.
    local hinchado = math.max(0, math.min(1, (marcador.escala - 1) / 0.18))
    local k = math.min(1, marcador.calor + hinchado * 0.3)
    for i = 1, 3 do
        tinte[i] = Palette.text[i] + (Palette.gold[i] - Palette.text[i]) * k
    end
    return math.floor(marcador.valor), marcador.escala, tinte
end

local function correrMarcador(dt)
    dt = math.min(dt, DT_MAX)

    if marcador.dur > 0 then
        marcador.t = marcador.t + dt
        local k = math.min(1, marcador.t / marcador.dur)
        -- Casi lineal, con la frenada solo en el ultimo tramo. Con un ease de
        -- verdad los clics se amontonan al principio y la cuenta se arrastra
        -- al final; lo que se quiere oir es un rodillo a paso constante que se
        -- para en seco.
        local avance = 1 - (1 - k) ^ 1.6
        marcador.valor = marcador.desde + (marcador.hasta - marcador.desde) * avance
        if k >= 1 then marcador.valor, marcador.dur = marcador.hasta, 0 end

        marcador.tic = marcador.tic - dt
        if marcador.tic <= 0 then
            marcador.tic = TIC
            -- El clic SUBE mientras la cifra rueda, y arranca mas arriba
            -- cuanto mas caliente esta la cadena. Es la misma idea que el pop
            -- de la cascada y por la misma razon: una cuenta a tono fijo dice
            -- que el marcador esta ocupado, una que sube dice que esta
            -- ganando.
            Sfx.play("cuenta", 1 + avance * 0.85 + marcador.calor * 0.45, 0.3)
        end
    end

    -- El muelle. Se integra SIEMPRE, tambien con la cuenta parada: lo que lo
    -- para es que llegue a su sitio, no que haya terminado de contar -- la
    -- cifra sigue botando un pelin despues de que el numero ya este puesto, y
    -- ese resto es lo que remata el golpe.
    local fuerza = -RIGIDEZ * (marcador.escala - 1)
    marcador.vel = marcador.vel + (fuerza - AMORTIGUA * marcador.vel) * dt
    marcador.escala = marcador.escala + marcador.vel * dt
    if marcador.escala > ESCALA_MAX then
        marcador.escala, marcador.vel = ESCALA_MAX, 0
    end

    -- El calor tarda algo mas de un segundo en apagarse del todo: el dorado de
    -- una cadena larga sigue ahi cuando llega el eslabon siguiente, y se apaga
    -- despues de que al jugador le haya dado tiempo a verlo.
    marcador.calor = math.max(0, marcador.calor - dt * 0.9)
end

--== Texto =================================================================

-- Los puntos que suben desde donde se han ganado. Van en virtual y con el
-- tamano segun lo gordo que sea el numero: los de tres cifras se leen igual
-- que los de cinco si todos miden lo mismo, y entonces no dicen nada.
--
-- `mult` es el multiplicador de cascada con el que se han cobrado, y no es
-- adorno: es el numero por el que el tablero ha multiplicado de verdad
-- (`suceso.multiplicador`). Sale escrito al lado de la cifra porque es lo
-- unico de una cadena que el jugador no puede deducir mirando -- ve reventar
-- mas galletas, pero no ve que cada una vale el triple -- y porque es lo que
-- convierte una cascada afortunada en algo que se ha GANADO.
function Efectos.numero(x, y, valor, color, mult)
    numeros[#numeros + 1] = { x = x, y = y, valor = valor, color = color or Palette.text,
                              t = 0, vida = 0.85, grande = valor >= 1000,
                              mult = mult or 1 }
end

-- El rotulo de una cascada: "¡Woof!", "¡Dale Kiko!". Entra de golpe, se queda
-- un suspiro y se va. Solo puede haber UNO: dos rotulos a la vez no se leen
-- ninguno, asi que el nuevo echa al viejo.
function Efectos.rotulo(texto, color)
    rotulos = { { texto = texto, color = color or Palette.gold, t = 0, vida = 0.95 } }
end

--== Ciclo =================================================================

local function correr(lista, dt)
    for i = #lista, 1, -1 do
        local e = lista[i]
        e.t = e.t + dt
        if e.t >= e.vida then table.remove(lista, i) end
    end
end

function Efectos.update(dt)
    if temblor.t > 0 then
        temblor.t = temblor.t - dt
        if temblor.t <= 0 then temblor.fuerza = 0 end
    end
    correr(rayos, dt); correr(ondas, dt); correr(numeros, dt)
    correr(rotulos, dt); correr(destellos, dt); correr(cometas, dt)
    correrMarcador(dt)
end

--== Dibujo en espacio de ARTE =============================================

function Efectos.drawArte()
    local Art = require("src.art")

    for _, d in ipairs(destellos) do
        local k = d.t / d.vida
        love.graphics.setColor(1, 1, 1, 1 - k * 0.3)
        Art.drawBlanco(d.id, d.x, d.y, 1 + k * 0.35)
    end

    for _, r in ipairs(rayos) do
        local k = r.t / r.vida
        -- Crece durante el primer tercio y se apaga el resto: un rayo que
        -- crece hasta el final llega a los bordes cuando ya no hay nada que
        -- romper.
        local avance = math.min(1, k * 3)
        local alcance = r.largo * avance
        local desvanece = 1 - math.max(0, (k - 0.33)) / 0.67
        local grosor = math.max(1, math.floor(5 * desvanece + 0.5))
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], 0.55 * desvanece)
        if r.h then
            love.graphics.rectangle("fill", r.x - alcance, r.y - grosor, alcance * 2, grosor * 2)
        else
            love.graphics.rectangle("fill", r.x - grosor, r.y - alcance, grosor * 2, alcance * 2)
        end
        local nucleo = math.max(1, math.floor(grosor * 0.5))
        love.graphics.setColor(Palette.miga[1], Palette.miga[2], Palette.miga[3], desvanece)
        if r.h then
            love.graphics.rectangle("fill", r.x - alcance, r.y - nucleo, alcance * 2, nucleo * 2)
        else
            love.graphics.rectangle("fill", r.x - nucleo, r.y - alcance, nucleo * 2, alcance * 2)
        end
    end

    -- Los cometas van despues de los rayos y antes de las ondas: por delante
    -- de la luz que los ha soltado y por detras del anillo de lo que revientan
    -- al llegar.
    for _, c in ipairs(cometas) do
        -- Mientras `t` es negativo el trozo todavia no ha salido: existe en la
        -- lista para que su retardo corra, pero no se dibuja.
        if c.t >= 0 then
            local k = math.min(1, c.t / c.vida)
            -- Bezier de tres puntos: el de en medio esta apartado del camino
            -- por su perpendicular, y eso es todo el arco.
            local mx, my = (c.x0 + c.x1) / 2, (c.y0 + c.y1) / 2
            local dx, dy = c.x1 - c.x0, c.y1 - c.y0
            local largo = math.max(1, math.sqrt(dx * dx + dy * dy))
            local cx = mx - dy / largo * c.curva
            local cy = my + dx / largo * c.curva
            local u = 1 - k
            local x = u * u * c.x0 + 2 * u * k * cx + k * k * c.x1
            local y = u * u * c.y0 + 2 * u * k * cy + k * k * c.y1

            -- La cola: dos copias mas pequenas un poco por detras. Son
            -- OPACAS y no medio transparentes a proposito -- el resto del
            -- juego no desvanece nada que sea arte -- y el que se lean como
            -- cola y no como tres estrellas es cosa del tamano.
            for _, cola in ipairs({ { 0.16, 0.45 }, { 0.08, 0.7 } }) do
                local kk = math.max(0, k - cola[1])
                local uu = 1 - kk
                local tx = uu * uu * c.x0 + 2 * uu * kk * cx + kk * kk * c.x1
                local ty = uu * uu * c.y0 + 2 * uu * kk * cy + kk * kk * c.y1
                love.graphics.setColor(c.color)
                Art.drawBlanco("estrellita", tx, ty, cola[2])
            end

            -- Y la cabeza: un halo del color de la familia y el nucleo de
            -- miga con su canto encima. Dos dibujos y no uno tintado porque
            -- un trozo entero del color de la galleta se pierde sobre el
            -- damero, y uno entero blanco no dice de quien es.
            love.graphics.setColor(c.color)
            Art.drawBlanco("estrellita", x, y, 1.45)
            love.graphics.setColor(1, 1, 1, 1)
            Art.drawScaled("estrellita", x, y, 1)
        end
    end

    for _, o in ipairs(ondas) do
        local k = o.t / o.vida
        local r = o.radio * (0.2 + k * 0.9)
        local grosor = math.max(1, math.floor(4 * (1 - k) + 0.5))
        love.graphics.setColor(o.color[1], o.color[2], o.color[3], (1 - k) * 0.9)
        -- Un anillo dibujado como cuatro barras: `circle` interpola y a esta
        -- escala el borde sale a medio pixel. Cuatro rectangulos en cruz dan
        -- un anillo cuadrado, que en pixel art es lo que se espera ver.
        love.graphics.rectangle("fill", o.x - r, o.y - r, r * 2, grosor)
        love.graphics.rectangle("fill", o.x - r, o.y + r - grosor, r * 2, grosor)
        love.graphics.rectangle("fill", o.x - r, o.y - r, grosor, r * 2)
        love.graphics.rectangle("fill", o.x + r - grosor, o.y - r, grosor, r * 2)
    end

    love.graphics.setColor(1, 1, 1, 1)
end

--== Dibujo en espacio VIRTUAL =============================================

function Efectos.drawVirtual()
    for _, n in ipairs(numeros) do
        local k = n.t / n.vida
        local font = n.grande and Fonts.medium or Fonts.small
        local texto = tostring(n.valor)
        local w, h = font:getWidth(texto), font:getHeight()
        -- Sube deprisa y frena: el numero tiene que estar quieto y legible
        -- justo cuando se esta apagando.
        local subida = (1 - (1 - k) * (1 - k)) * 46
        local alpha = k < 0.7 and 1 or (1 - (k - 0.7) / 0.3)

        -- Y ENTRA DE GOLPE: nace hinchado y se encoge a su tamano en la quinta
        -- parte de su vida. Un numero que aparece ya del tamano bueno se ve
        -- asomar; uno que se encoge se ve LLEGAR, y es lo que lo ata al pop
        -- que acaba de sonar. El pico sube con el multiplicador, que es lo que
        -- hace que el sexto eslabon de una cadena se vea distinto del primero
        -- sin cambiar ni un color.
        local pico = 0.4 + (n.mult - 1) * 0.16
        local escala = k < 0.2 and (1 + pico * (1 - k / 0.2)) or 1

        -- El multiplicador va al lado y en pequeno, y los dos se centran
        -- JUNTOS: centrado solo el numero, el "x3" empuja el bloque y la cifra
        -- deja de salir de la casilla que la ha dado.
        local mtexto = n.mult > 1 and ("x" .. n.mult) or nil
        local wm = mtexto and (HUECO_MULT + Fonts.small:getWidth(mtexto)) or 0
        local x0 = math.floor(-(w + wm) / 2)

        love.graphics.push()
        love.graphics.translate(math.floor(n.x), math.floor(n.y - subida + h / 2))
        love.graphics.scale(escala, escala)

        love.graphics.setFont(font)
        love.graphics.setColor(Palette.ink[1], Palette.ink[2], Palette.ink[3], alpha)
        love.graphics.print(texto, x0 + 2, math.floor(-h / 2) + 2)
        love.graphics.setColor(n.color[1], n.color[2], n.color[3], alpha)
        love.graphics.print(texto, x0, math.floor(-h / 2))

        if mtexto then
            -- Siempre en oro, tambien cuando la cifra va en tinta: el oro es
            -- el color de lo que se cobra en este juego (la barra, las
            -- estrellas), y el multiplicador es lo que mas se cobra.
            local fm = Fonts.small
            love.graphics.setFont(fm)
            local xm = x0 + w + HUECO_MULT
            local ym = math.floor(-fm:getHeight() / 2)
            love.graphics.setColor(Palette.ink[1], Palette.ink[2], Palette.ink[3], alpha)
            love.graphics.print(mtexto, xm + 2, ym + 2)
            love.graphics.setColor(Palette.gold[1], Palette.gold[2], Palette.gold[3], alpha)
            love.graphics.print(mtexto, xm, ym)
        end

        love.graphics.pop()
    end

    for _, r in ipairs(rotulos) do
        local k = r.t / r.vida
        -- Entra de golpe con rebote, aguanta, y se va hacia arriba.
        local escala = k < 0.25 and (0.4 + (k / 0.25) * 0.75) or 1.15
        if k > 0.75 then escala = 1.15 - (k - 0.75) / 0.25 * 0.2 end
        local alpha = k < 0.75 and 1 or (1 - (k - 0.75) / 0.25)
        local font = Fonts.large
        love.graphics.setFont(font)
        local w = font:getWidth(r.texto)
        local cx = Constants.GAME_WIDTH / 2
        local cy = Constants.GAME_HEIGHT * 0.34 - k * 40
        love.graphics.push()
        love.graphics.translate(math.floor(cx), math.floor(cy))
        love.graphics.scale(escala, escala)
        love.graphics.setColor(Palette.ink[1], Palette.ink[2], Palette.ink[3], alpha)
        love.graphics.print(r.texto, math.floor(-w / 2) + 3, 3)
        love.graphics.setColor(r.color[1], r.color[2], r.color[3], alpha)
        love.graphics.print(r.texto, math.floor(-w / 2), 0)
        love.graphics.pop()
    end

    love.graphics.setColor(1, 1, 1, 1)
end

return Efectos
