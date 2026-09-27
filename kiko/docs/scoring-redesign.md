# Rediseño de la puntuación del arcade: Base × Mult

Fase 1: auditoría y plan. En esta fase no se tocó código del juego. Lo único que se
ejecutó fue un script de medición en el scratchpad (`estimar.lua`) que
carga el `src/board.lua` real con LuaJIT y juega rondas sin ventana. Sus cifras
se citan abajo como "medido". Son orientativas: 100-150 rondas por caso, sin
mejoras y con dos bots sencillos. La medición seria es la Fase 4.

Todo lo que sigue sale del `.love` que se subió (Kiko, el match-3 de
galletas), importado en `kiko/`.

---

## 1. Cómo se puntúa hoy

### Dónde se calcula

Todo el cálculo está en `src/board.lua`, que no dibuja nada y se puede probar
sin ventana. La pantalla solo suma lo que el tablero le devuelve.

| Qué | Dónde | Valor |
|---|---|---|
| Galleta rota | `Board.PUNTOS.galleta` (l. 89), `Board:valorGalleta` (l. 350) | 60 (+ mejora de color) |
| Barro / hielo / moho, por capa | `Board.PUNTOS` | 50 (+ Fregona) |
| Pastilla que llega al suelo | `Board:gravedad` (l. 1381) | 2000, fijo |
| Especial creada | `Board.PUNTOS.crear` | raya 120, estrella 150, envuelta 200, pelota 300 (× Regalo) |
| Multiplicador de cascada | `Board:resolver(preferidas, cascada)` (l. 1050) | ×1, ×2, ×3… con tope 6 (`CASCADA_MAX`, +2/+4 con Cadena) |
| Bonus de las mejoras | dentro de `resolver` | cuarteto/quinteto (suma fija por grupo), racha de color (150·n por eslabón, 3 como mucho) |
| Combo de dos especiales | `Board:combo` (l. 1160) | lo que rompa × Fusión |

### Cómo se resuelve un movimiento

1. `juego.lua: intentar(i, j)` (l. 924) lanza una corrutina en el `Director`.
   Mientras esa corrutina vive, el tablero no admite toques.
2. `Board:jugada` decide si el intercambio vale (`"normal"` o `"combo"`).
3. Si es `"combo"`, se llama a `Board:combo`. Después, en los dos casos, se
   llama a `resolverTodo` (l. 700), que repite este bucle:
   - `Board:resolver(preferidas, cascada)` busca los **grupos** (`Board:grupos`,
     l. 564). Las rachas cruzadas del mismo color se funden en un solo grupo, y
     los cuadrados 2×2 forman grupo aparte. De cada grupo sale su premio
     (`Board.premio`, l. 669):
     - 2×2 → **estrella**
     - racha de 5 o más → **pelota**
     - dos rachas cruzadas con 5 casillas o más (L/T) → **envuelta**
     - racha de 4 → **raya**
   - `_detonar` (l. 884) rompe por **ondas**: las especiales que caen dentro de
     la zona rota disparan su propia onda. **Cada** punto se multiplica por el
     multiplicador de cascada: galletas, barro, especiales creadas y bonus.
   - `asentar()` → `Board:gravedad` hasta que el tablero se queda quieto. Las
     pastillas que llegan al suelo suman 2000 ahí, sin multiplicador.
   - `cascada = cascada + 1` y vuelta a empezar.
4. `brotarMoho`, `barajarSiHaceFalta` y `comprobarFinal`. En el arcade, la
   ronda se corta en cuanto `progreso.puntos >= meta`.

### Cuándo se actualiza la interfaz

**En cada paso de la cascada, no al final.** `animarSuceso` (l. 512) hace
`progreso.puntos += suceso.puntos` y llama a `Efectos.contar(progreso.puntos,
cascada)`. Así, el marcador de la cabecera rueda con cada paso de la cadena y
se va poniendo dorado según avanza (`calor`). A la vez sale un número flotante
(`Efectos.numero`) con el `×multiplicador` al lado, y un rótulo a partir de la
3.ª cascada o cuando se cobra la racha de color. Las pastillas suman y ruedan
aparte, en `animarCaida` (l. 668).

### Diagnóstico

- **Casi todo el valor está en el volumen.** Una línea de 3 da 180 y una de 5
  da 300 + 300 por la pelota = 600, es decir, 3,3 veces más, cuando es una
  jugada mucho más difícil. Una segunda cascada, en cambio, dobla **todo** lo
  que rompe, y eso no depende del jugador.
- Medido (sistema actual, 5 colores, 15 movimientos, sin mejoras): el bot al
  azar saca **16.300** y el codicioso **19.100**. Son apenas un **18 %** de
  diferencia. Pensar casi no se nota en el marcador.
- El comentario de `Arcade.CRECE` ya lo dice: *"lo que puntúa una ronda NO
  crece con las mejoras"*. Casi todas las mejoras suman una cantidad fija, así
  que la capacidad de una ronda es plana y la curva geométrica solo decide en
  qué ronda te cruzas con ella.

---

## 2. Inventario de mejoras

Todas están en `src/arcade.lua`, en `Arcade.MEJORAS` (l. 144). Las seis de
color se generan en el bucle de la l. 310. Son **21 en total**.

| # | id | Nombre | Qué hace hoy | Tope |
|---|---|---|---|---|
| 1 | `cuarteto` | Cuarteto | +300·n por cada línea de 4 | 3 |
| 2 | `quinteto` | Quinteto | +900·n por cada línea de 5 | 2 |
| 3 | `obsesion` | Obsesión | +150·n por eslabón al repetir color (hasta 3 eslabones) | 3 |
| 4 | `fusion` | Fusión | un combo de dos especiales puntúa ×(1 + 0,5·n) | 3 |
| 5 | `polvora` | Pólvora | la envuelta rompe 5×5 / 7×7 | 2 |
| 6 | `lluvia` | Lluvia | la estrella se parte en 3+n trozos | 3 |
| 7 | `mano` | Mano larga | +2·n movimientos por ronda | 3 |
| 8 | `regalo` | Regalo | crear una especial puntúa ×(1+n) | 2 |
| 9 | `cadena` | Cadena | el tope de cascada pasa de ×6 a ×8 / ×10 | 2 |
| 10 | `fregona` | Fregona | barro, hielo y moho valen 50+75·n | 2 |
| 11 | `estropajo` | Estropajo | cada golpe quita 2 capas de barro | 1 |
| 12 | `mecha` | Mecha | las rayas disparan en cruz | 1 |
| 13 | `eco` | Eco | la envuelta estalla 2+n veces | 2 |
| 14 | `suerte` | Suerte | el 2·n % de lo que cae trae una especial | 3 |
| 15 | `deshielo` | Deshielo | el hielo se rompe también en diagonal | 1 |
| 16-21 | `color1..6` | Fresa, Naranja, Limón… | esa galleta vale 60+60·n | 3 |

---

## 3. Qué pasa con cada mejora

Ejes: **+Base** (común), **+Mult** (media), **xMult** (rara) y **Mecánica**
(no toca la fórmula). El impacto es orientativo, para una ronda media de un
jugador que busca lo que la carta pide.

| Mejora | Veredicto | Cómo queda | Eje | Impacto aprox. |
|---|---|---|---|---|
| Cuarteto | **SE ADAPTA** | *Sube de nivel la Línea de 4*: +10 Base y +1 Mult de forma por nivel | forma (+Base, +Mult) | medio. Una 4 pasa de 25×2 a 45×4 en Nv3 |
| Quinteto | **SE ADAPTA** | *Sube de nivel la Línea de 5*: +20 Base y +2 Mult por nivel | forma | alto pero raro. La 5 es la jugada más difícil |
| Obsesión | **SE ADAPTA** | La afinidad de color pasa a ser una regla base. La carta la potencia: cada eslabón da **+0,5·n Mult de más** (Nv1 +1,0 por eslabón en vez de +0,5) | +Mult (estado) | alto para quien planifica color, casi nulo para quien no. Es justo lo que se busca |
| Fusión | **QUEDA** | Ya multiplica: **xMult ×1,5 / ×2 / ×2,5** en jugadas combo | xMult | alto pero condicionado a preparar dos especiales |
| Pólvora | **QUEDA** | Mecánica. Rompe más, así que suma algo de Base | Mecánica (+Base indirecto) | bajo en puntos: las gemas pesan poco en el sistema nuevo. Su valor pasa a ser limpiar barro |
| Lluvia | **QUEDA** | Igual que Pólvora | Mecánica | bajo en puntos |
| Mano larga | **QUEDA** | No es puntuación, son más oportunidades. Vale **más** que hoy, porque más movimientos son más pasos de escalada | — | medio-alto |
| Regalo | **SE ADAPTA** | Crear una especial ya *es* la forma (4 → raya, L/T → envuelta, 5 → pelota), así que ×2 sobre la creación pagaría dos veces lo mismo. Pasa a ser **+1·n Mult si la jugada crea una especial** | +Mult | medio. Premia buscar formas en general, no una en concreto |
| Cadena | **SE SUSTITUYE** | El multiplicador de cascada desaparece, así que la carta pierde su sentido. Se reescribe como la "mejora concreta" que el brief permite: **cada paso de cascada suma +0,25·n Mult** (tope +2) | +Mult (cascada) | bajo-medio. Sigue siendo azar, pero acotado y comprado a sabiendas |
| Fregona | **SE ADAPTA** | **+5·n Base por capa limpiada** (barro, hielo, moho) | +Base | bajo en rondas limpias, medio en las sucias. Igual que hoy |
| Estropajo | **QUEDA** | Mecánica | — | — |
| Mecha | **QUEDA** | Mecánica | — | — |
| Eco | **QUEDA** | Mecánica | — | — |
| Suerte | **SE ELIMINA** (recomendado) | Mete especiales al azar. Con la cascada limitada a sumar Base, lo que dan es Base aleatoria que no se decide, y encima puede cortar una afinidad. Es la carta que más premia el azar. Si se quiere conservar como mecánica, que salga poco | — | premia el azar |
| Deshielo | **QUEDA** | Mecánica | — | — |
| Colores ×6 | **SE ADAPTA** | **+3·n Base por cada gema de ese color** (la gema base vale 5). Además se propone una nueva carta de color xMult (ver §4, *Monocromo*) | +Base | bajo-medio. Encaja con la afinidad: dice qué color perseguir |

Resumen: **7 quedan** (5 mecánicas, Mano larga y Fusión), **11 se adaptan**
(Cuarteto, Quinteto, Obsesión, Regalo, Fregona y las 6 de color), **1 se
sustituye** (Cadena) y **1 se elimina** (Suerte). Las tres rarezas xMult serían
Fusión y dos de las nuevas.

---

## 4. Mejoras nuevas propuestas

Cada una se escribe como una fila de `Arcade.MEJORAS`. Siguen la regla del
archivo: la mejora mueve números que el cálculo ya mira, sin ningún `if` en la
pantalla.

| Nombre | Nivel | Qué hace | Eje | Micro-decisión que premia |
|---|---|---|---|---|
| **Escuadra** | común ×3 | Sube de nivel la **L/T**: +10 Base y +1 Mult | forma | ver la esquina |
| **Paciencia** | media ×2 | Una forma de 4 o más justo después de una línea de 3 da **+n de escalada extra** (redefinida para la regla B, ver §8) | +Mult (estado) | preparar un 3 para luego hacer un 5 |
| **Crescendo** | rara ×1 | La escalada suma **+2** en vez de +1 cuando la forma es **estrictamente mejor** que la anterior | xMult efectivo | subir la calidad jugada a jugada |
| **Monocromo** | rara ×1 | **×1,5 Mult** si la afinidad de color lleva 3 o más eslabones | xMult | mantener un color |
| **Doblete** | media ×2 | El doble match simultáneo da +2 Mult de más (Nv2 +4) | +Mult | ver dos grupos con un solo swap |
| **Remanso** | media ×2 | Si la jugada **no provoca cascada**, +2·n Mult | +Mult | jugar abajo y limpio en vez de tirar arriba a ver qué cae |
| **Molde** | rara ×1 | La forma **más usada** de la ronda gana ×1,5 Mult | xMult | tener una firma de juego |
| **Ancla** | común ×3 | Cuando la escalada se parte, se queda en al menos 1·n | +Mult (estado) | amortigua el castigo por arriesgar |

Remanso y Cadena apuntan a direcciones opuestas: un mazo va a cascadas y otro
va a jugadas limpias. Las dos pueden salir en la misma partida, y elegir entre
ellas es una decisión de verdad.

---

## 5. Sistema nuevo: detalle y problemas que he encontrado

### Fórmula y orden de aplicación (propuesta)

```
Base = Σ gemas·5 (+ mejoras de color)
     + Σ estorbos·10 (+ Fregona)
     + Base de la forma o formas de la jugada (con su nivel)
     + Base de cada forma que se casa en la cascada
     + pastillas·100

Mult = Mult de la forma de la jugada (con su nivel)
     + 2 si es un doble match
     + Escalada + Afinidad (estado)
     + los +Mult de las mejoras, en el orden de la lista

Total = floor(Base × Mult × Π xMult en el orden de la lista)
```

El orden fijo es: 1) todas las +Base, 2) todas las +Mult, 3) las xMult de una
en una. Es el mismo orden en que la secuencia visual las enseña.

### ⚠️ Problema 1: la Escalada tal como está escrita premia jugar mal

Regla literal: *"si la forma es igual o mejor que la anterior, +1; si es peor,
se reduce a la mitad"*. Una línea de 3 seguida de otra línea de 3 es "igual",
así que suma. El jugador que **solo** hace líneas de 3 escala para siempre, y
el que hace una L y luego una línea de 3 pierde la mitad. Medido:

| Bot | Escalada media, regla literal | Escalada media, regla B |
|---|---|---|
| azar | **4,56** | 0,93 |
| codicioso | 2,59 | 2,72 |

Con la regla literal, el bot al azar escala **más** que el codicioso.

**Regla B, que propongo:** las líneas de 3 son neutras (ni suman ni parten).
Una forma de 4 o más que iguala o supera a la **última forma de 4 o más** suma
+1. Si es peor, la escalada se parte por la mitad. Así, preparar con un 3 no
se castiga y escalar exige hacer formas de verdad.

### Problema 2: la tabla no cubre todas las jugadas de este juego

- **Cuadrado 2×2 (estrella):** no está en la tabla. Propuesta: base 20, mult 2,
  entre la línea de 3 y la de 4.
- **Combos de dos especiales** (raya+raya, envuelta+pelota, etc.): no son una
  forma. Propuesta: una fila "Combo" con base y mult según la pareja (de raya
  y raya 40×3 a pelota y pelota 100×6), y ahí se aplica Fusión.
- **Pastillas:** hoy suman 2000 fijos, fuera de todo multiplicador. Propuesta:
  +100 de Base a la jugada en la que caen.
- **Doble match:** "sumas las bases, +2 mult". ¿El mult de forma es el
  **máximo** de las dos formas + 2? (Es lo que he supuesto.)
- **Color principal:** el color del grupo más grande de la jugada del jugador.
  En un combo con pelota, el color al que apunta.

### Problema 3: el tablero lo comparte la campaña

`Board` puntúa igual la campaña (60 niveles con umbrales de estrellas medidos)
y el arcade. Cambiar la puntuación del tablero descalibra todas las estrellas
de la campaña. Propuesta: el cálculo nuevo vive en un módulo puro aparte
(`src/puntuacion.lua` + `src/puntuacion_config.lua`) que solo el arcade usa. La
campaña sigue con `suceso.puntos`, que no cambia.

### Problema 4: la escala de los números cambia

Una línea de 3 pasa de 180 puntos a 25, más o menos. Medido, con 5 colores, 15
movimientos, sin mejoras y la regla B:

| Bot | Sistema viejo | Sistema nuevo | Nuevo / viejo |
|---|---|---|---|
| azar | 16.300 | 3.100 | 0,19 |
| codicioso | 19.100 | 10.700 | 0,56 |
| codicioso / azar | **1,18×** | **3,45×** | |

La brecha entre jugar sin pensar y jugar a formas pasa de 1,18 a 3,45 veces
antes de meter al planificador. Es buena señal, pero obliga a rehacer las metas.

---

## 6. Curva de metas

**Hoy:** `meta(r) = 5000 × 1,25^(r − 1 − pausas)`, redondeada a cientos, donde
`pausas` es 1 desde la ronda 14 (entra el sexto color). Los movimientos son
`15 + (r − 1)`, más 4 desde la ronda 14.

La curva ya es exponencial, pero choca con una capacidad que **no crece con
las mejoras** (el propio comentario del código lo dice). Con Base × Mult pasa
lo contrario: los niveles de forma, los +Mult y sobre todo las xMult se
**componen**. Una buena build crece de forma geométrica y una mala se queda
plana. Con eso, una curva geométrica ya mide cómo construyes la partida, y no
solo cuánto aguantas.

Dos ajustes:

1. **Bajar la META inicial a la escala nueva.** 2.500, que con el codicioso
   pelado (unos 10.700) pone la ronda 1 donde está hoy (5.000 contra unos
   19.000, más o menos un 25 %). El bot al azar ya no la pasa de sobra.
2. **Crecimiento algo más suave al principio y más duro al final**, al estilo
   de Balatro: ×1,22 hasta la ronda 19 y ×1,30 desde la 20. Al principio se
   aprende; al final, sin xMult no se llega.

| Ronda | Movs | Meta actual | Meta propuesta |
|---|---|---|---|
| 1 | 15 | 5.000 | 2.500 |
| 3 | 17 | 7.800 | 3.700 |
| 5 | 19 | 12.200 | 5.500 |
| 8 | 22 | 23.800 | 10.100 |
| 10 | 24 | 37.300 | 15.000 |
| 13 | 27 | 72.800 | 27.200 |
| 14 (6.º color) | 32 | 72.800 | 27.200 |
| 16 | 34 | 113.700 | 40.500 |
| 18 | 36 | 177.600 | 60.200 |
| 20 | 38 | 277.600 | 89.600 |
| 22 | 40 | 433.700 | 151.500 |
| 25 | 43 | 847.000 | 332.800 |

Estos valores son **provisionales**. El objetivo de calibración para la Fase 4
es: con mejoras elegidas por cada bot, que el codicioso muera hacia la ronda
10-12 y el planificador llegue a la 20-25. Los números finales saldrán de esa
simulación y quedarán en `src/puntuacion_config.lua` junto a la tabla de
formas.

---

## 7. Plan de implementación (tras aprobar)

**Fase 2, lógica** (un commit):
- `src/puntuacion_config.lua`: la tabla de formas, sus niveles, las constantes
  de escalada y afinidad, el valor de gema y estorbo, y la curva.
- `src/puntuacion.lua`: funciones puras.
  - `clasificar(grupos)` → la forma de la jugada.
  - `puntuar(jugada, estado, mods)` → `{base, mult, xmult, total, pasos = {…}, estado' }`.

  `pasos` es la lista ordenada de bonus con su fuente, y es lo que la Fase 3
  enseña uno a uno.
- `Board:resolver` y `Board:combo` devuelven además los `grupos` y el recuento
  de gemas y estorbos. Lo que ya devuelven para la campaña no cambia.
- `Arcade.MEJORAS` se reescribe según §3 y §4.
- `tests/test_puntuacion.lua` (LuaJIT, sin love): formas, doble match, escalada
  (regla B), afinidad, cascada que solo suma Base y orden de aplicación.

**Fase 3, presentación** (un commit): el contador "pendiente" junto al tablero
durante la cascada, la secuencia de 1-1,5 s (forma y nivel → Base cuenta → Mult
y bonus uno a uno → `Base × Mult = total` → vuelo al marcador), un toque para
acelerar o saltar, el input bloqueado (ya lo está por `Director`, que se
extiende hasta el final de la secuencia) y el preview de la forma y del
cálculo al arrastrar.

**Fase 4, validación** (un commit): `tests/simular.lua` con tres bots (azar,
codicioso, planificador a 1-2 jugadas), cientos de rondas con el sistema viejo
y con el nuevo, y la tabla de media y varianza.

---

## 8. Decisiones (aprobado)

- El código de Kiko se importa del `.love` en `kiko/` de este repo y se trabaja ahí.
- **Solo arcade.** La campaña sigue puntuando con `suceso.puntos` como siempre.
- **Escalada con la regla B.**
- Cuadrado, combos y pastillas, como en §5. Doble match: el mult es el de la
  forma mayor + 2.
- El estado (escalada y afinidad) se reinicia en cada ronda. La afinidad tiene
  tope +3, y cada nivel de Obsesión lo sube en +1.
- Suerte sale del pool.
- **Paciencia se redefine.** Con la regla B, la línea de 3 ya es neutra, así
  que la carta tal como se propuso no haría nada. Pasa a ser: *una forma de 4 o
  más justo después de una línea de 3 da +n de escalada extra*. Premia
  exactamente "preparar un 3 para luego hacer un 5".
