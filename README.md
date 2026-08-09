# Notebook Survivors

A LÖVE (love2d) survivors-like played out on an endless sheet of ruled notebook
paper. This is the base scaffolding: a moving character, a horde that walks in
from offscreen, a procedurally generated background, and the loop that ties them
together.

## Running

```sh
love .
```

Requires [LÖVE 11.x](https://love2d.org).

## Controls

| | Desktop | Touch |
| --- | --- | --- |
| Answer the title screen | scribble in a box, or `Y` / `N` | scribble in a box |
| Draw your character | hold left mouse on the board | drag on the board |
| Pencil / rubber | `1` / `2`, `P` / `E`, wheel | tap the selector on the right |
| Start the run with it | scribble in `OK!`, or `Enter` | scribble in `OK!` |
| Back to the stick man | scribble in `RESET`, or `R` | scribble in `RESET` |
| Move | `WASD` / arrows | thumb stick, bottom-left |
| Draw | hold left mouse | any other finger |
| Drop a pushpin | click where you want it | tap where you want it |
| Drive a staple | click where you want it, again and again | same, tapping |
| Aim the ruler | hold and drag to pivot, release to snap | same, with one finger |
| Open the compass | press to stand the needle, drag out the width, release | same, with one finger |
| Switch tool | `1`–`9`, `Q` / `E`, wheel | tap the selector on the right |
| Pause / resume | `P`, or the button in the top-left corner | tap the button in the top-left corner |
| Answer the pause screen | scribble in a box, or `Y` / `N` | scribble in a box |
| Restart | `R` | tap anywhere |

`F11` or `alt+enter` toggles fullscreen, `Esc` quits.

The stick is drawn in the bottom-left corner, but it is not pinned there: press
anywhere in that corner and the ring jumps under your thumb, so you never have
to look for it. Push past the rim and the ring follows rather than running out
of travel. It is analogue — a small lean walks slowly — while the keyboard is
always full tilt. The trade-off is that a finger landing in the corner always
steers, so draw with the other hand.

## Asking by drawing

Three screens ask you a question — the title screen (`START?`), the board your
character is drawn on (`OK!` / `RESET`) and the pause screen (`QUIT?`) — and
they all ask it the same way, so the asking lives in one place,
`src/scribble.lua`. Each is a labelled box you answer by scribbling in it, on a
page you can draw the rest of anyway.

It is not a button that happens to look drawn. The box measures *ground
covered*, on a 2px grid inside its border, and six cells arm it — a line through
the box, about a third of the way across. What that rules out is a tap or a
graze rather than a deliberate mark: a single dab lands in one cell, and
scrubbing back and forth over one spot re-marks cells that are already marked.

## The title screen

**NOTEBOOK WARRIORS**, and under it `START?` with a YES box and a NO box. You
answer it the way you do everything else here — by drawing. Scribble inside a
box and that is your answer: YES goes to the board your character is drawn on,
NO closes the book.

Armed is not answered. Nothing is committed until the pen comes off the page, so
a stroke that runs on into the other box changes its mind rather than being too
late — the last box drawn in is the one that answers — and the line under the
boxes reads `RELEASE TO CONFIRM` (`LIFT` on touch) while one is armed. Ink that
misses a box is just ink on the page and fades off it like any other mark. The
border warms slate → blue → red as the box fills. `Y` and `N` don't skip any of
that — they scribble the box in for you and then it answers.

Everything on it is drawn rather than laid out. The title writes itself on a
letter at a time with a puff of graphite off each one, the rule under it is a
pencil line that draws left to right, the boxes draw themselves a side at a
time, and the lettering wobbles a pixel a few times a second — a line redrawn
by hand every frame rather than a sprite being moved about. The boxes are the
exception: they are drawn wonky but with the same wonk every frame, because
they are what you are aiming at and a target should hold still. Answering dithers
the whole screen off the page, stamp by stamp, the way a mark fades; YES then
pulls the paper away into the run.

The page underneath is the game's own: the same ruled paper panning as if a
camera were following someone, the character you drew walking a lap of it, and
the same monsters the spawner uses strung out behind him — real `Enemy`
instances chasing a moving point, so they steer, bunch up and trail exactly as
they will in a minute's time. It goes through the same overprint pass too, so
the ruling shows through the title.

## Drawing your character

YES does not start the run. It hands you a stick man on a board, a pencil and a
rubber, and whatever you leave on the board is the sprite you play as:

```
title screen  ->  the board  ->  the run
```

The board *is* the sprite. It is 15x19 cells because the player is 15x19 pixels,
one cell per pixel, blown up by a whole number the way `main.lua` blows up the
whole canvas — so nothing is resampled, scaled or interpreted between what you
draw and what walks onto the page a second later. Every cell you fill in rebuilds
`Sprites.player` on the spot, which is why the life-size copy standing in the
margin is not a preview of the sprite so much as the sprite itself, at 1:1 with
the walk bounce on: the only honest way to show a character fifteen pixels
across. That makes the hero about twice a blob's height, which is deliberate —
at 9x11 there was no room to draw a face and a weapon, and `Player.radius` is
kept in proportion so contact lands where the drawing does.

The board is filled with `paper`, the one colour that does not overprint, so it
genuinely wipes the ruling off that patch of page and you are drawing on blank
paper. A cell is filled a pixel short of its square, leaving the lattice showing
between filled neighbours — without that gutter, fifteen pixels at nine times
the size read as one blob rather than as fifteen pixels.

The board is the biggest thing on the screen and everything else is set beside it
in a column — the title, the life-size copy, the boxes, the line saying what the
screen is waiting for. The board is pushed as far right as the tools allow rather
than centred against that column, because it is a fixed size once the zoom is
picked and the width left over is worth more around the writing than split
between the page margin and the gap to the tools. The pencil and the rubber are
pinned to the right edge of the safe area, on the run's own margin, in the run's
own 13px box, popping out
the same way when selected and tested for presses the same way: the tools are in
the same place on the page whether you are drawing the hero or playing him, so
there is only one spot to reach for. When there is not enough width for a column
that still leaves the board something worth drawing on — a phone held upright —
the column goes above and below the board instead, and the board keeps its size.
The column is measured from the longest string that can ever appear in it, so
nothing shifts sideways when the prompt changes.

It is finished with the same boxes every other screen here asks with: `OK!`
starts the run, `RESET` puts the stick man back. RESET is answered in place
rather than closing the screen, so the ink comes back out of the box and it can
be answered again. A stroke is latched on the press — one that starts on the
board draws on it for its whole length and can never answer a box, and one that
starts off the board can never reach it, so a scribble aimed at `OK!` that
overshoots cannot cost your hero a leg. Ink that lands outside both is not part
of the drawing, just ink on the page, and fades off it.

An empty board is refused: nothing drawn is nothing to play as, and it would be
saved and handed back on the next launch as well.

The design that starts a run is written to the save directory as
`hero.txt` — one line per row, so opening it in a text editor shows the
character — and read back on the next launch. A file that has been edited into
something the game can't draw is ignored rather than trusted, and you get the
stick man back. There is only ever one hero: the run draws it, the title screen's
doodle draws it, and the board's life-size copy draws it.

Dying restarts straight into the next run with the same character; the board
comes back round through the title screen.

## Pausing

The button sits in the top-left corner with the health bar starting to the right
of it, and turns red with a play arrow while the run is held. Pressing it again
lets the run go, and so does `P`. The HUD gets first refusal on every press,
ahead of the stick, whose grab zone is a generous quadrant rather than the ring
it draws.

That corner is where it ended up by elimination. The whole right margin belongs
to the tool column, which is nine tools tall and has nothing to spare; the
bottom-left corner belongs to the thumb stick. The gap to the health bar is six
pixels rather than four because the button's touch target reaches five past its
own box, and a health bar with that lying across its left end is a bar that
pauses the run when you press it.

Pausing holds the run where it stands: the clock, the horde, the ink and any
mark still fading are all exactly as you left them. An open stroke is closed off
at the freeze, so the nib can't rule a line across the page on the way back to
wherever the pointer wandered to while nothing was moving.

Up comes `QUIT?` with the same YES and NO boxes the title screen uses and the
same arm-then-lift mechanic. Scribbling YES hands the page back to the title
screen; NO lets the run go again. It is written on the page rather than laid
over it — no panel, no card, just lettering and two boxes — so the frozen run
shows through it, and the whole page stays drawable: ink that misses the boxes
is not an answer, just ink, and fades off exactly as it does on the title
screen. It costs nothing, since none of it touches the run underneath — the pen
only runs while the game is playing, so a paused page can be scribbled over
without spending ink or leaving a mark on the run.

Any press or key skips the intro straight to the boxes.

## On a phone

The game takes the whole screen and fills it, whatever shape it is. The scale
is a whole number picked from the short edge of the screen, and the canvas is
then made exactly as many game pixels as it takes to cover the window at that
scale — 320x180 on a 16:9 window, 400x180 on a 20:9 phone. Nothing is stretched
and nothing is letterboxed: a wider screen simply shows more page. Rotating the
device rebuilds the canvas at the new shape mid-run.

The HUD measures off `love.window.getSafeArea` rather than the screen edge, so
nothing sits under a notch or a gesture bar, and the level readout moves up
under the health bar on touch because the bottom-left corner belongs to the
stick.

The tool column has the whole right margin to itself and sits centred in it —
nothing else is drawn there and nothing else tests a press there, which is why
the pause button was moved out of that corner when the strip reached nine tools.

Shooting is automatic: the nearest enemy in range gets hit on a timer. Drawing
is the part you aim.

## Drawing

You draw on the page and the marks fight for you. A stroke is a chain of brush
stamps laid at a fixed spacing as the nib moves, so the line stays even however
fast you drag, and damage is tested against the *segment* between the old and
new nib position — a fast flick can't skip past an enemy between frames.

Marks are anchored in world space, not to the screen. They stay where you drew
them as the camera scrolls away, and holding the pointer still while you walk
keeps drawing, because the page slides underneath the nib.

| Tool | Feel | Does |
| --- | --- | --- |
| Pencil | thin, ragged | big damage, one hit per enemy per stroke |
| Pen | smooth, 3px | no damage: the line is a **wall** enemies must go around |
| Rubber | 15px sweep, shoving | hard knockback and chip damage, re-hits every 0.3s |
| Highlighter | wide band | lingers ~3.6s, damaging anything standing on it |
| Gluestick | 29px smear | no damage at all: anything caught stops dead |
| Pushpin | not drawn: **dropped** | 41px circle, 10 damage, and survivors are pinned 2.5s |
| Stapler | not drawn: **dropped** | 15px, 2 damage, holds what it catches 2s — ten a meter |
| Ruler | not drawn: **aimed** | 200px line through you, 8 damage, everything shoved clear |
| Compass | not drawn: **opened** | circle up to 108px across, 7 damage, cut as the arm reaches it |

The pen draws terrain. Its line is solid to enemies and open to you: walk over
it freely while the horde has to slide along it and round the ends, and nothing
is ever allowed to end up standing inside the ink, however hard the crowd
behind pushes. It lasts nine seconds, by far the longest of any mark, because a
wall is only worth drawing if it outlives the panic that made you draw it.

An enemy commits to a way round once it starts sliding, instead of re-deciding
every frame — otherwise it would settle at the point on the line nearest you
and shuffle back and forth forever, and a fence would be as good as a cage.
Enemies that meet a line dead-on split and go both ways, so a crowd piles into
it and peels off round both ends.

A full meter is 170px of pen, and a box drawn tight around yourself is about
160 of it. So you can wall yourself in completely — once, with nothing left for
anything else, for nine seconds. That is the intended panic button, not a
loophole: it costs the whole meter, does no damage, and the horde is waiting
right there when it fades.

The gluestick is deliberately the rubber's look at exactly twice its radius —
a 29px smear against a 15px sweep — and it sits on the page for six seconds. Freeze is re-applied every tick, so
an enemy that wanders in is held until the glue itself fades — it can't walk
out, it isn't shoved out by the crowd piling up behind it, and it drops any
knockback it was carrying so it doesn't lurch when it comes loose. It still
hurts anything that touches it, so a glued blob is a wall, not a safe space.
Glue plus pencil is the combination: pin the horde, then draw through it. At
this size one 90px smear holds about half of everything standing on top of you
— measured at 44 enemies frozen out of 89 within 60px — so the ink cost is what
keeps it honest, not the area.

The pushpin is the one tool that is not a brush. There is no line to draw: you
tap the page and a pin drops on that spot, falls for a quarter of a second, and
the landing punches a 41px circle out of the horde. Everything inside it takes
one hit of 10 — and 10 is deliberately one short of the 12hp skull, which is the
whole design in a number. Every blob and bat in the circle dies outright; the
tank is what walks out of the crater, except that it doesn't walk, because
anything that lives through the landing is pinned to the paper for 2.5 seconds.
Damage that killed everything would leave the pinning nothing to pin.

Holding the pointer down does nothing more, and dragging does not rake a line of
pins across the page — it is tapped, not drawn. The fall is not a delay for its
own sake: it is what turns the ring on the page into a promise rather than a
report. You can see where it is going to land before it lands, and so can the
bat walking out of it, which is about eleven pixels' worth of head start.

And then it stays there, exactly as it went in. The pushpin and the stapler are
the only two things in the game that are driven through the paper rather than
drawn on it, and they are the only two that never come off it: every mark fades,
these accumulate. Nor do they fade in place — fading is what ink does, and these
are not ink, so a pin looks the same on the last frame of the run as it did
going in. A long run leaves a trail of them behind it that reads back afterwards
as the places you were in trouble. They are also the one thing an eraser sweep
can wipe that you put there yourself.

That means a pin is not the timer on its own hold, which is fine, because the
enemy always was the better place to read it: a held one stops moving and grows
a sky-blue shadow, and that is what you are watching anyway.

Spent ones drop under the crowd, where the working ones are drawn over it: while
a pin is holding something you need to see it through the blob standing on it,
and once it is spent it is just paper. Nothing about a spent one ever changes
again, so it costs no update at all, and only the ones on screen are drawn.

There is no limit on how many a run accumulates. The cull is what buys that: a
20-minute run of nonstop stapling is about 2000 marks and costs 0.16ms a frame,
five times that costs 0.35ms, and the walk over the list only starts to show up
around 50,000 — hours of continuous tapping. Drawing them all instead of just
the ones in view is what would cost, not keeping them.

The stapler is the pushpin's opposite number, and used the same way: tap and one
lands where you tapped. Everything else about the two is reversed. Where a pin
is one big expensive decision — 0.45 of the meter, a quarter-second fall, a 41px
crater, damage enough to kill everything in it but the tank — a staple is 0.1 of
the meter, lands the instant you tap, reaches 15px and does 2. That is a bat and
nothing else. It is not an attack, it is a fastener: it holds one thing to the
paper for two seconds, and the way you use it is to keep tapping.

Ten a meter against the pin's two, so the same ink buys roughly the same page
either way — as one crater you place once, or as ten fastenings you have to land
one at a time on things that are moving. That is the whole choice the pair
offers, and it is a choice between one decision and ten.

Nothing about it is telegraphed, because there is nothing to dodge. The pin's
fall is what stops a tap on a moving target being a certainty; a staple has no
fall at all, and what keeps it honest instead is that hitting barely hurts and
the circle is small enough to miss with. Holding the pointer down does nothing
and dragging rakes no line of them: ten staples is ten separate presses, which
is what the tool costs instead of ink.

Freeze and life are the same number, the way they are for the pin — `life` is
only how long the thing is still worth updating, since a staple never comes out
of the paper and never fades. A page worked over with the stapler stays covered
in them. Each one goes in
flat, or leaning five to ten degrees one way or the other. That is not
decoration: twenty staples at exactly the same angle read as a pattern printed
on the page rather than as twenty separate decisions. The lean is kept that
small for the same reason it exists — a stapler is held very nearly square and
never far from it, and past about fifteen degrees the legs stop landing square
under the crown and the shape starts reading as an arrow. At ten it is a bar
with a single pixel of step in it, which is exactly what a hand-placed staple
looks like.

The ruler is the third way a tool can be used, and the only one you *point*.
Press and a dashed pencil band appears through you, drag and it pivots about
you, and the moment you let go the ruler comes down flat on everything lying
along it. The pivot is the player, so you can't reach across the page with it —
you can only choose which way the page gets swept — and the pivot follows you
while you aim, so walking is part of lining it up rather than something you have
to stop doing to use it.

At 200px long and 15px wide it has by a distance the longest reach in the game
and the narrowest, which is the whole trade: it can touch more of the page at
once than anything else, but only the part that happens to line up through you,
and you have to stand there turning it until it does. The 8 damage clears the
chaff, but the shove is the point — everything is thrown clear of the line and
off both sides at once, so a ruler that kills nothing still opens a corridor
straight through the middle of the horde.

Nothing about the aim is free. The press pays for it and the release lands it,
so there is no letting go of a ruler without hitting the page with it — and
anything else that takes the aim away, changing tool or pausing, snaps it down
rather than pocketing the ink. The horde keeps walking the whole time you are
lining it up.

The compass is the fourth way, and the only one that is *opened* rather than
drawn, placed or aimed. Press and the needle goes into the page right there;
drag and the pencil leg opens out to however wide you want the circle; let go
and it draws. One gesture, and the same one the real instrument is set with —
the needle stays where you put it while the other leg swings out from it.

Which makes it the only tool here where the mark is placed before it is sized.
Everywhere else the drag decides where the ink goes and the size is whatever the
drag came to; here the press fixes the centre and the drag only widens it. A
press with no drag in it at all is still a circle, at the minimum width.

Nothing lands on the release. The lead sets off from wherever you left it
resting and cuts what it passes over as it arrives there, taking 0.8s to come
all the way round however wide the circle is. So the far side of a big one has
most of a second to walk out — and can watch the arm coming the whole way. It is
the only attack in the game that is a promise rather than a report, which is
also what makes it the only one you can be walked out of.

The other half of it is that the needle goes wherever you tapped. Every other
tool starts at your hand: the ruler pivots through you, a stroke begins under the
nib. A compass can be stood in the middle of a crowd you are nowhere near, which
is the reach the tool is really for, and the screen edge is the whole of the
limit on it — the same deal the pushpin gets.

At 7 damage it is deliberately over the blob's 4 and under the skull's 12: the
biggest area in the game clears chaff and cannot touch a tank, where the pushpin
covers a quarter as much page and kills everything but one. The knock is
tangential rather than outward, so the leg drags what it catches round the circle
with it — a horde standing in one comes out stirred rather than scattered.
Scattering is the ruler's job, and a compass that did the same thing would just
be a round one.

The needle is what costs, and it is charged the moment it goes in. From there
the circle is coming: anything that takes the compass away — the release, a tool
change, the pause — swings it at whatever width it had reached rather than
handing the ink back.

The cooldown is an **ink meter**, the gauge beside the tool selector. It drains
by the pixel — a full meter is about 230px of pencil, 170 of pen, 150 of rubber,
120 of highlighter, 90 of glue — or by the use, for the four tools that aren't
brushes: 0.45 of the meter for a pin, 0.4 for a compass, 0.35 for a ruler, 0.1
for a staple. Two pins from full, about three rulers, or ten staples, and a
second or so of standing still to earn one back. It refills a beat after you
stop, and won't let
you start a new stroke while it is nearly empty. Long strokes cost you; short
deliberate ones don't.

A few touches make the marks feel like marks rather than shapes:

- **The pencil roughens itself.** Each stamp has a chance of a second pixel
  alongside the core, so a straight drag reads as graphite instead of a vector.
- **The pen's nib trails the pointer**, closing a third of the gap each frame.
  Hand jitter and the polygonal steps of a fast drag roll into the curve a
  ballpoint actually leaves, and corners come out rounded rather than kinked —
  a box drawn round yourself looks drawn, not stamped.
- **The rubber really erases.** It draws in paper, so a sweep wipes the ruled
  lines and doodles off the page and they fade back in behind it. Because paper
  on blank paper would be invisible, a broken-up ring of graphite dust rides
  outside the clean core, and crumbs spray off it.
- **The highlighter has a chisel nib** held at 45 degrees, like the real thing:
  sweeping across the page lays a wide band with angled ends, and a rim of red
  marks where the ink pooled at the edge.
- **Glued enemies stop animating** — no walk bounce — and their shadow turns
  into a wider smear of sky-blue glue. A clump going still while the rest of the
  horde streams past reads instantly, and a splash of blue specks marks the
  moment each one sticks.
- **The pushpin's shadow closes up under it** as it falls, on the page and under
  the crowd it is falling into, while the pin itself is drawn over everything —
  it is in the air on the way down and standing proud of the paper afterwards,
  and a pin you can't see behind a blob is a pin you can't aim the next one off.
  The landing inks the aiming ring and throws it outwards, and sprays paper
  fibres out of the puncture.
- **The ruler is a real ruler.** Paper body, ink edge, graduations down one
  side, red-edged for the first half of the slap. Because paper is the colour
  that doesn't overprint, a ruler lying on the page genuinely covers the ruling
  underneath, exactly as the thing itself would. It is drawn over everything it
  flattened — but *under* the player, because you are the one who brought it
  down, and the one thing you have to keep track of can't blink out at the
  moment the page is in chaos. Then it lifts, and what is left is a ruled pencil
  line that fades off like any other mark.
- **The compass draws its circle rather than revealing it.** The rim is plotted
  a pixel at a time on the same grid as the ruling, only as far round as the
  lead has actually got, with graphite flicking off the tip as it goes. While
  the width is being chosen the whole circle is ruled out in dashed pencil —
  what you are picking is a circle, so a circle is what you are shown; a radius
  read off the leg alone would be a number, not a target. The needle and the leg
  are drawn *over* the crowd, because a leg you can't see behind a blob is a
  width you can't judge, and both lift off the page the instant the circle
  closes.

Marks fade without ever leaving the palette. Alpha would blend paper and ink
into a ninth colour, so instead a stroke steps down a colour ramp
(ink → slate → graphite) while individual stamps drop out at random — a dither
fade. Every pixel on screen is always one of the eight.

Each tool decides how late in its life the dithering starts. The pen holds full
blue for the first three quarters and then goes visibly thin and pale, because
a wall you can't see is a trap: the fade has to be the warning that it is about
to stop stopping anything.

## Palette

Eight colours, and nothing else is allowed to appear on screen. They live in
`src/palette.lua`; the ASCII sprite maps reference them by single-letter key, so
off-palette art is impossible to author by accident.

| | hex | key | used for |
| --- | --- | --- | --- |
| paper | `#e6ecef` | `w` | the page |
| graphite | `#b2b1c0` | `g` | pencil grain, shadows |
| slate | `#5b4f6e` | `s` | mid ink |
| ink | `#280732` | `o` | outlines, letterbox |
| red | `#e15e6e` | `r` | player, shots, damage |
| blush | `#f3a8a8` | `k` | soft fills, margin line |
| blue | `#7194f0` | `b` | pen blue, XP |
| sky | `#abc9f1` | `c` | ruled lines, glue puddles |

## Pixel size

Everything renders into a 320x180 canvas which is then scaled up by a whole
number to fit the window (4x at the default 1280x720). One authored pixel is
always an exact square block of screen pixels — never blurred, never a
half-pixel off. Two things protect that:

- The canvas and every image use `nearest` filtering.
- The camera snaps to whole pixels before drawing (`Camera.bounds`). A
  fractional camera would make the ruled lines crawl.

So sprite art is authored 1:1 against the canvas: the player is 15x19 pixels
(drawn by the player rather than authored, but on the same grid), monsters are
8x8 to 11x10, and the ruled lines are 2 pixels thick on a 10 pixel pitch.

## The background

Generated at runtime, infinite in every direction, nothing stored:

1. **The paper** — base colour, ruling (2px of blue, 8px of paper, repeating), a
   blush margin line every 192px, and sparse graphite grain — is baked once into
   a 192x100 `ImageData` and drawn as a single texture-wrapped quad whose UVs
   are just the world coordinates.
2. **The doodles** — heart, cloud, bolt, inked sphere, sparkle, S-swash, face,
   squiggle — are placed by hashing cell coordinates through
   `util.hash01`. Placement is a pure function of position, so the page always
   regenerates identically without a seed table or any allocation.

Tune it with `RULE_THICKNESS`, `RULE_PERIOD`, `RULE_COLOR`, `MARGIN_X`, `GRAIN`,
`CELL` and `DOODLE_CHANCE` at the top of `src/background.lua`. `TILE_H` has to
stay a multiple of `RULE_PERIOD`.

## Layout

```
main.lua              canvas sized to the screen, whole-number zoom, safe area
conf.lua              window config
src/
  game.lua            state, update/draw order, spatial hash, collisions, ink
  palette.lua         the eight colours
  pixelart.lua        ASCII art -> palette-locked Image (+ mask, discs, circles)
  sprites.lua         all art, authored as ASCII pixel maps
  font.lua            3x5 bitmap font for the HUD
  background.lua      procedural notebook paper + doodles
  overprint.lua       pairs the page and the ink so the ruling shows through
  camera.lua          pixel-snapped follow camera
  input.lua           keyboard, mouse, thumb stick, drawing pointer
  tools.lua           the nine tool definitions, one table each (and the shelf)
  stroke.lua          one mark: brush stamps, damage, surface tests, fade
  pin.lua             the pushpin: dropped where you tap, not drawn
  staple.lua          the stapler: the same tap, small and cheap and repeated
  ruler.lua           the ruler: aimed about the player, snapped on release
  compass.lua         the compass: needle where you tap, swung on release
  walls.lua           spatial hash of pen lines, for enemies to steer around
  player.lua          movement, walk bob, auto-attack, XP and levels
  enemy.lua           enemy types table, chase, knockback
  spawner.lua         offscreen ring spawning, difficulty ramp
  bullet.lua          projectiles
  gem.lua             XP pickups with magnet
  particles.lua       one-pixel ink specks
  hud.lua             bars, timer, tool selector, thumb stick, pause button
  scribble.lua        the question every screen asks: a box you scribble in
  menu.lua            title screen: the chase behind it, and the boxes you draw in
  hero.lua            the player character as drawn, and its save file
  studio.lua          the board it is drawn on, between the title and the run
  pause.lua           the QUIT? the pause button writes on the held page
```

## Extending it

- **New enemy:** add a sprite to `Sprites.enemies` and a row to `Enemy.types`,
  then add it to `TABLE` in `src/spawner.lua` with an unlock time and weight.
- **New doodle:** append an ASCII map to `Sprites.doodles`; the background picks
  from the list automatically.
- **New tool:** append a row to `Tools.list` with an icon in `Sprites.icons`.
  Every tool is the same object shape — radius, damage, knockback, stamp
  spacing, ink cost, fade ramp, and a `stamp` function — and the selector, the
  number keys, the input routing and the ink meter all pick it up. The header
  comment in `src/tools.lua` documents each field, including the ones that turn
  a tool into something other than a weapon: `wall`, `slick`, `freeze`,
  `linger`, `smooth`. Marks that are surfaces rather than attacks answer
  `Stroke:covers(x, y)`, which rejects on a bounding box first, so a page with
  no wax on it costs nothing to stand on. Round brush tips past about nine pixels across come from
  `pixelart.newDisc(radius)` rather than ASCII, whole-pixel rings from
  `pixelart.circleOutline`, and whole-pixel bars at any angle from
  `pixelart.line`.
- **New tool that isn't a brush:** give it a `drop`, a `snap` or a `sweep` block
  instead of a `stamp` and none of the fields that describe a line apply — it
  carries its own numbers and `ink` is the flat price of one use. `drop` is
  *placed* (a tap puts one where you tapped); `snap` is *aimed*
  (press to pivot it about the player, release to land it, `src/ruler.lua`);
  `sweep` is *opened* (the press stands it where you pressed, the drag out of
  that same press sizes it, the release sets it going, `src/compass.lua`).
  `Game:updateDrawing` sends the press down one of the four paths on those three
  fields alone. Anything that is paid for before it lands also has to be landed
  from every route that can take it away — the release, a tool change, and the
  pause (`Game:snapRuler`, `Game:swingCompass`) — or the ink is spent on
  nothing. Anything that reads the pointer after the press edge also needs the
  guard those two have, or a press that was already down when the tool was
  switched gets claimed by a tool it was never meant for.
  The block says how a tool is *used*, not what it is, so two tools used the
  same way share one: the pushpin and the stapler are both `drop`, and the
  `lands` field inside the block names the module that turns up on the page
  (`src/pin.lua`, `src/staple.lua`). Both sit in one list, `game.drops`, and
  answer `update`, `drawMark` (the page layer) and `draw` (over the crowd).
  Returning false from `update` retires one to `game.spent` rather than
  destroying it: these two are the only tools whose marks stay on the page, and
  a spent one is never updated again and is drawn only when it is on screen.
- **Taking a tool off the strip:** move its row from `Tools.list` into
  `Tools.shelved` in `src/tools.lua`. Nothing addresses a tool by name or index
  — the selector, the number keys, the input routing and the ink meter all read
  the list — so it goes and comes back in one line. The crayon is sat there now.
- **Balance:** `SPEED` and the fire/damage fields in `src/player.lua`,
  `Enemy.types`, and the spawn interval in `src/spawner.lua`.

Enemies are separated and bullet hits are resolved through a spatial hash
(`Game:buildGrid`, 12px cells), rebuilt each frame, so the horde scales to a few
hundred without an n² pass. Pen lines get their own hash in `src/walls.lua`,
built from the strokes' coarse paths and rebuilt only while a wall is being
drawn or has just expired; segments are filed under every cell within reach of
them, so an enemy asks what is nearby with a single table lookup. A soak with
191 enemies and 500px of wall costs 0.4ms per update, of the 16.7 available.

## Not built yet

Levelling up currently just nudges fire rate and heals a little — there is no
upgrade draft screen and no audio. Tools are not upgradeable yet either: ink
capacity, stroke damage and radius are fixed for the whole run. Dying restarts
straight into the next run rather than going back to the title screen.

The **crayon** is written and working but is not on the strip at the moment — it
sits in `Tools.shelved`. It is a wax lane: a 13px band you run 1.75× along —
faster than anything in the game — while anything chasing you onto it loses its
footing, keeps the heading it arrived with and slides straight past. Moving its
row back into `Tools.list` puts it back in the game.
