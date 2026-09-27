-- Lo que sobrevive a cerrar el juego: las estrellas de cada nivel, la mejor
-- puntuacion, la mejor partida de arcade y si el sonido esta puesto. Nada mas.
--
-- No se guarda la partida a medias A PROPOSITO. Un nivel de match-3 dura dos
-- minutos, y guardar el tablero obligaria a que TODO lo que lo toca supiera
-- migrar (las especiales, el barro, las pastillas a medio caer, la cascada en
-- vuelo) a cambio de ahorrarle al jugador dos minutos una vez cada muchas.
-- Salir de un nivel es perderlo, y eso se avisa antes de salir.
--
-- El archivo es texto plano de una linea por dato: se lee con los ojos, se
-- arregla a mano si algun dia hace falta, y una linea que no se entiende se
-- ignora en vez de tirar el guardado entero. Un guardado que revienta al
-- cargarlo es peor que no guardar.

local Session = {}

local ARCHIVO = "progreso.txt"
local VERSION = 1

-- [n] = { pasado = bool, estrellas = 0..3, puntos = n }
--
-- `pasado` y `estrellas` son cosas DISTINTAS y ese es el punto: pasar un nivel
-- es cumplir su objetivo, y las estrellas son puntos. Se puede pasar un nivel
-- con cero estrellas (cumpliendo el objetivo a la primera, con pocos puntos) y
-- se puede sacar dos estrellas sin pasarlo (muchos puntos y el barro sin
-- terminar). Mezclarlos obligaba a regalar una estrella al pasar, y entonces
-- la barra de la cabecera decia una cosa y el cartel del final otra.
--
-- Del arcade se guarda lo MISMO que de un nivel y por la misma razon: la
-- marca, no la partida. Una partida de arcade a medias tiene tablero, mejoras
-- y ronda, y guardar eso obligaria a que todo lo que las toca supiera migrar;
-- lo que el jugador recuerda de una partida es hasta donde llego.
Session.datos = {
    version = VERSION,
    sonido = true,
    niveles = {},
    arcade = { ronda = 0, puntos = 0 },
}

function Session.load()
    local datos = { version = VERSION, sonido = true, niveles = {},
                    arcade = { ronda = 0, puntos = 0 } }

    if love.filesystem.getInfo(ARCHIVO) then
        local texto = love.filesystem.read(ARCHIVO) or ""
        for linea in (texto .. "\n"):gmatch("(.-)\n") do
            local clave, valor = linea:match("^([%w%.]+)=(.*)$")
            if clave == "sonido" then
                datos.sonido = valor == "1"
            elseif clave == "arcade" then
                local ronda, puntos = valor:match("^(%d+),(%d+)$")
                if ronda then
                    datos.arcade = { ronda = tonumber(ronda), puntos = tonumber(puntos) }
                end
            elseif clave then
                local n = clave:match("^nivel%.(%d+)$")
                if n then
                    local pasado, estrellas, puntos = valor:match("^(%d+),(%d+),(%d+)$")
                    if not pasado then
                        -- Formato viejo (estrellas,puntos): tener estrellas
                        -- implicaba haberlo pasado. Se lee y se sube de
                        -- version sola al siguiente guardado.
                        estrellas, puntos = valor:match("^(%d+),(%d+)$")
                        pasado = (tonumber(estrellas or 0) > 0) and 1 or 0
                    end
                    if estrellas then
                        datos.niveles[tonumber(n)] = {
                            pasado = tonumber(pasado) == 1,
                            estrellas = tonumber(estrellas),
                            puntos = tonumber(puntos),
                        }
                    end
                end
            end
        end
    end

    Session.datos = datos
    return datos
end

function Session.save()
    local arcade = Session.datos.arcade or { ronda = 0, puntos = 0 }
    local lineas = { "version=" .. VERSION,
                     "sonido=" .. (Session.datos.sonido and 1 or 0),
                     string.format("arcade=%d,%d", arcade.ronda, arcade.puntos) }
    local maximo = 0
    for n in pairs(Session.datos.niveles) do maximo = math.max(maximo, n) end
    for n = 1, maximo do
        local d = Session.datos.niveles[n]
        if d then
            lineas[#lineas + 1] = string.format("nivel.%d=%d,%d,%d", n,
                                                d.pasado and 1 or 0, d.estrellas, d.puntos)
        end
    end
    love.filesystem.write(ARCHIVO, table.concat(lineas, "\n") .. "\n")
end

-- Apunta el resultado de un nivel. Solo mejora: volver a jugar un nivel y
-- hacerlo peor no puede quitarte una estrella que ya tenias, ni cerrarte un
-- nivel que ya habias pasado.
function Session.apuntar(nivel, pasado, estrellas, puntos)
    local d = Session.datos.niveles[nivel] or { pasado = false, estrellas = 0, puntos = 0 }
    d.pasado = d.pasado or pasado
    d.estrellas = math.max(d.estrellas, estrellas)
    d.puntos = math.max(d.puntos, puntos)
    Session.datos.niveles[nivel] = d
    Session.save()
end

-- La marca del arcade. Solo mejora, como la de un nivel: una partida corta no
-- borra la larga. La ronda manda sobre los puntos -- llegar mas lejos es lo
-- que se cuenta -- pero los puntos se guardan igual aunque la ronda no suba,
-- porque son dos maneras distintas de haber jugado bien.
function Session.apuntarArcade(ronda, puntos)
    local a = Session.datos.arcade or { ronda = 0, puntos = 0 }
    a.ronda = math.max(a.ronda, ronda)
    a.puntos = math.max(a.puntos, puntos)
    Session.datos.arcade = a
    Session.save()
end

function Session.arcade()
    return Session.datos.arcade or { ronda = 0, puntos = 0 }
end

function Session.pasado(nivel)
    local d = Session.datos.niveles[nivel]
    return d and d.pasado or false
end

function Session.estrellas(nivel)
    local d = Session.datos.niveles[nivel]
    return d and d.estrellas or 0
end

function Session.puntos(nivel)
    local d = Session.datos.niveles[nivel]
    return d and d.puntos or 0
end

-- El nivel mas alto abierto: el siguiente al ultimo pasado. Se deriva de lo
-- guardado en vez de apuntarse aparte, que es un dato menos que puede
-- contradecir al otro. Y depende de PASAR, no de las estrellas: un nivel que
-- cuesta pasar no puede ademas cerrarte el camino por haberlo pasado justo.
function Session.desbloqueado()
    local n = 1
    while Session.pasado(n) do n = n + 1 end
    return n
end

function Session.totalEstrellas()
    local total = 0
    for _, d in pairs(Session.datos.niveles) do total = total + d.estrellas end
    return total
end

function Session.reset()
    Session.datos = { version = VERSION, sonido = Session.datos.sonido, niveles = {},
                      arcade = { ronda = 0, puntos = 0 } }
    Session.save()
end

return Session
