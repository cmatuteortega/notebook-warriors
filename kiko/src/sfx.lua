-- Sonido, SINTETIZADO al arrancar. No hay ni un archivo de audio en el
-- proyecto, igual que no hay ni un PNG.
--
-- Un match-3 sin sonido no esta acabado: el golpe es la mitad de la sensacion
-- de romper algo, y la escala que sube con la cascada es lo que convierte una
-- racha larga en una racha larga QUE SE NOTA. Por eso el juego suena, al
-- reves que Rumbo, que es mudo a proposito por ser un idle.
--
-- Las reglas que hacen que esto no suene a maquina son tres:
--
--   * Ni dos golpes al mismo tono. Cada disparo se mueve un poco (y en
--     OpenAL el tono es tambien velocidad, que para foley es lo que se
--     quiere: un pop mas rapido es otro pop, no el mismo con voz de pito).
--   * La cascada SUBE por una escala pentatonica, que no tiene semitonos y
--     por eso no puede sonar mal sea cual sea la nota en la que caiga una
--     cadena de nueve.
--   * Todo se desvanece. Una envolvente que corta en seco chasca, y ese chasco
--     es lo que hace que un sonido sintetizado suene sintetizado.

local Sfx = {}

local TASA = 44100
local MASTER = 0.55

local sonidos = {}
local cargado = false
Sfx.activo = true

--== Sintesis ==============================================================

-- Todas las voces se construyen igual: una funcion que, dado el instante `t`
-- y la duracion, devuelve la muestra en [-1, 1]. La envolvente va aparte y se
-- multiplica encima, asi que ninguna voz tiene que acordarse de apagarse.

local function envolvente(t, dur, ataque, curva)
    ataque = ataque or 0.004
    if t < ataque then return t / ataque end
    local k = (t - ataque) / (dur - ataque)
    return math.exp(-(curva or 5) * k)
end

local function seno(f, t) return math.sin(2 * math.pi * f * t) end

-- Un triangulo suena a hueco y una sierra a sierra: el armonico impar que
-- le falta al triangulo es justo el que hace metalico al resto.
local function triangulo(f, t)
    local x = (f * t) % 1
    return 4 * math.abs(x - 0.5) - 1
end

-- Ruido con memoria: la media con la muestra anterior le quita el filo de
-- arriba, que es lo que separa una explosion de un siseo de radio.
local function ruidoSuave()
    local anterior = 0
    return function()
        local n = love.math.random() * 2 - 1
        anterior = (anterior + n) * 0.5
        return anterior
    end
end

local function construir(dur, fn)
    local n = math.floor(TASA * dur)
    local data = love.sound.newSoundData(n, TASA, 16, 1)
    for i = 0, n - 1 do
        local t = i / TASA
        local s = fn(t, dur)
        if s > 1 then s = 1 elseif s < -1 then s = -1 end
        data:setSample(i, s)
    end
    return data
end

--== Las voces =============================================================

local voces = {}

-- El pop de una galleta. Dos senos a la quinta con un golpe de ruido cortisimo
-- delante: el ruido es el "chas" de la galleta partiendose y los senos son el
-- cuerpo. Sin el ruido suena a videojuego de 1980; sin los senos, a estatica.
function voces.pop()
    local ruido = ruidoSuave()
    return construir(0.16, function(t, dur)
        local env = envolvente(t, dur, 0.002, 9)
        local cuerpo = seno(660, t) * 0.55 + seno(990, t) * 0.30
        local chas = t < 0.012 and ruido() * 0.9 or 0
        return (cuerpo + chas) * env * 0.8
    end)
end

-- El dedo al arrastrar una galleta: un toque corto y grave, mas percusion que
-- nota. Suena en CADA intercambio, asi que tiene que ser lo bastante discreto
-- para oirlo doscientas veces sin cansarse.
function voces.mover()
    return construir(0.09, function(t, dur)
        local f = 420 * (1 - t * 1.6)
        return triangulo(f, t) * envolvente(t, dur, 0.003, 14) * 0.5
    end)
end

-- La jugada que no vale: dos notas que BAJAN. Bajar es lo que se lee como
-- "no", y es lo unico del juego que lo hace.
function voces.nada()
    return construir(0.22, function(t, dur)
        local f = t < 0.09 and 240 or 180
        return triangulo(f, t) * envolvente(t, dur, 0.004, 6) * 0.45
    end)
end

-- El rayo de una rayada: un barrido de ruido que se abre. Es el unico sonido
-- con direccion, y por eso dura lo que tarda el rayo en cruzar el tablero.
function voces.rayo()
    local ruido = ruidoSuave()
    return construir(0.34, function(t, dur)
        local env = envolvente(t, dur, 0.006, 5)
        local barrido = seno(200 + 2600 * t, t)
        return (ruido() * 0.7 + barrido * 0.5) * env * 0.75
    end)
end

-- La envuelta: golpe seco y grave, el unico sonido con cuerpo de bombo. Es lo
-- que justifica el temblor de pantalla que lo acompana.
function voces.bum()
    local ruido = ruidoSuave()
    return construir(0.45, function(t, dur)
        local env = envolvente(t, dur, 0.002, 4.5)
        local golpe = seno(110 * (1 - t * 0.7), t) * 0.9
        return (golpe + ruido() * 0.55 * math.exp(-18 * t)) * env * 0.95
    end)
end

-- La pelota: un barrido que SUBE y se abre en dos voces. Sube porque se
-- lleva el tablero entero por delante y todo lo que sube se lee como que algo
-- gordo viene detras.
function voces.pelota()
    return construir(0.70, function(t, dur)
        local env = envolvente(t, dur, 0.01, 3.2)
        local f = 220 + 900 * t * t
        return (seno(f, t) * 0.5 + seno(f * 1.5, t) * 0.35 + triangulo(f * 0.5, t) * 0.2) * env * 0.8
    end)
end

-- El trozo de estrella que sale volando. Un pitido corto que SUBE, y suenan
-- tres seguidos con el tono un poco mas alto cada vez: tres notas subiendo es
-- lo que convierte tres bultos que se mueven en un reparto, y es la unica
-- razon por la que este sonido no es el de la rayada -- el de la rayada tiene
-- direccion pero no tiene cuenta, y aqui lo que hay que oir es "una, dos y
-- tres".
--
-- El armonico de arriba entra a la mitad y se va antes: es lo que le da el
-- destello de miga sin que llegue a sonar a campana, que es lo que anuncia
-- una estrella del final de nivel y no puede confundirse con esto.
function voces.estrella()
    return construir(0.26, function(t, dur)
        local env = envolvente(t, dur, 0.004, 7)
        local f = 520 + 1500 * t
        return (seno(f, t) * 0.5 + seno(f * 2.02, t) * 0.22 * math.exp(-9 * t)
                + triangulo(f * 0.5, t) * 0.18) * env * 0.6
    end)
end

-- La galleta que aterriza. Cortisima y suave: suenan seis a la vez y lo que
-- importa no es ninguna, es el redoble que hacen juntas al caer la columna.
function voces.toque()
    return construir(0.06, function(t, dur)
        return seno(330, t) * envolvente(t, dur, 0.002, 16) * 0.35
    end)
end

-- El cubito que se rompe. Es el sonido mas AGUDO del juego y el mas corto, y
-- las dos cosas por lo mismo: suena a la vez que el pop de la galleta que lo ha
-- roto, y tiene que oirse por debajo de el. Si compitiera, la jugada se leeria
-- como que se ha roto el cubito -- y lo que se ha roto es una racha al lado.
--
-- El cristal es ruido con la cola cortada mas dos parciales altos y no
-- armonicos: los armonicos enteros suenan a campana, y una campana es lo que
-- este sonido no puede ser (ya hay una, y anuncia una estrella).
function voces.hielo()
    local ruido = ruidoSuave()
    return construir(0.18, function(t, dur)
        local env = envolvente(t, dur, 0.001, 12)
        local chas = ruido() * 0.8 * math.exp(-30 * t)
        return (seno(2400, t) * 0.32 + seno(3250, t) * 0.18 + chas) * env * 0.5
    end)
end

-- La estrella del final. Campana: un seno con su armonico no entero, que es
-- lo que hace que suene a metal y no a flauta.
function voces.campana()
    return construir(1.10, function(t, dur)
        local env = envolvente(t, dur, 0.004, 3)
        return (seno(880, t) * 0.5 + seno(1320, t) * 0.3 + seno(2093, t) * 0.2) * env * 0.7
    end)
end

-- El clic del marcador contando. Es el sonido mas corto y mas flojo del juego,
-- y no suena una vez: suenan diez o quince seguidos mientras la cifra rueda.
-- Lo que se oye no es el clic, es el RODILLO que hacen juntos, y por eso es un
-- triangulo pelado sin cuerpo ninguno -- con cuerpo, quince seguidos taparian
-- los pops de la cascada, que es lo que de verdad hay que oir. Va agudo por lo
-- mismo: por encima del pop, en un sitio donde no le quita nada.
function voces.cuenta()
    return construir(0.035, function(t, dur)
        return triangulo(1500, t) * envolvente(t, dur, 0.001, 24) * 0.22
    end)
end

--== Carga y reproduccion ==================================================

local DEFS = {
    pop      = { voces.pop, voces = 8 },
    mover    = { voces.mover, voces = 3 },
    nada     = { voces.nada, voces = 2 },
    rayo     = { voces.rayo, voces = 4 },
    bum      = { voces.bum, voces = 4 },
    pelota = { voces.pelota, voces = 2 },
    toque    = { voces.toque, voces = 8 },
    campana  = { voces.campana, voces = 3 },
    estrella = { voces.estrella, voces = 6 },
    hielo    = { voces.hielo, voces = 4 },
    -- Ocho voces porque la cuenta dispara una cada cuarenta y cinco
    -- milisegundos: con menos, el rodillo se come a si mismo.
    cuenta   = { voces.cuenta, voces = 8 },
}

-- La escala de la cascada: pentatonica mayor, en semitonos. Sin semitonos no
-- hay nota mala, asi que una cadena larga sigue sonando a musica en el octavo
-- eslabon. Pasado el ultimo se sigue subiendo de octava.
local ESCALA = { 0, 2, 4, 7, 9, 12, 14, 16, 19, 21, 24 }

local function semitono(n)
    return 2 ^ (n / 12)
end

function Sfx.load()
    if cargado then return end
    local t0 = love.timer and love.timer.getTime() or 0
    local ok, err = pcall(function()
        for nombre, def in pairs(DEFS) do
            local data = def[1]()
            local fuente = love.audio.newSource(data, "static")
            local reserva = {}
            for _ = 1, def.voces do reserva[#reserva + 1] = fuente:clone() end
            sonidos[nombre] = { base = fuente, reserva = reserva, siguiente = 1 }
        end
    end)
    if not ok then
        -- Sin audio (un puerto sin OpenAL) el juego sigue, callado. Todas las
        -- funciones de abajo salen solas si no hay sonido cargado.
        print("[sfx] sin sonido: " .. tostring(err))
        sonidos = {}
        return
    end
    cargado = true
    local n = 0
    for _ in pairs(DEFS) do n = n + 1 end
    print(string.format("[sfx] %d voces sintetizadas en %.2f s", n,
                        (love.timer and love.timer.getTime() or 0) - t0))
end

-- Reserva circular: la voz mas vieja es la que se pisa. Es lo correcto para
-- foley -- si suenan ocho pops a la vez, el que sobra es el primero, que ya
-- casi no se oye -- y evita crear Sources en mitad de una cascada.
local function voz(nombre)
    local s = sonidos[nombre]
    if not s then return nil end
    local v = s.reserva[s.siguiente]
    s.siguiente = s.siguiente % #s.reserva + 1
    v:stop()
    return v
end

-- tono: multiplicador; vol: 0..1. Los dos opcionales.
function Sfx.play(nombre, tono, vol)
    if not Sfx.activo then return end
    local v = voz(nombre)
    if not v then return end
    local variacion = 1 + (love.math.random() - 0.5) * 0.06
    v:setPitch(math.max(0.1, (tono or 1) * variacion))
    v:setVolume(MASTER * (vol or 1))
    v:play()
    return v
end

-- El pop de la cascada numero `n`. Es la funcion mas importante de este
-- archivo: es lo que hace que una cadena de siete se sienta como una cadena de
-- siete y no como siete cosas que pasan.
function Sfx.cascada(n)
    local grado = ESCALA[math.min(n, #ESCALA)] + math.max(0, n - #ESCALA) * 2
    Sfx.play("pop", semitono(grado))
end

-- La vibracion del movil. Va aqui y no en la pantalla porque es lo mismo que
-- el sonido: le dice al dedo que ha pasado algo. En escritorio no existe y la
-- llamada se calla.
function Sfx.vibrar(segundos)
    if not Sfx.activo then return end
    if love.system and love.system.vibrate then
        pcall(love.system.vibrate, segundos or 0.02)
    end
end

function Sfx.silenciar(valor)
    Sfx.activo = not valor
    if valor then love.audio.stop() end
end

return Sfx
