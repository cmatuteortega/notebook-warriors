# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running

```sh
love .                  # run from the project root
```

Requires LÖVE 11.x (`t.version = "11.4"` in `conf.lua`), which means LuaJIT/Lua 5.1
semantics — `unpack` is a global (`src/overprint.lua` relies on it), not `table.unpack`.

There is no build step, no test suite and no dependency manifest. The closest
thing to a lint pass is a syntax check, which is worth running after a broad edit:

```sh
for f in main.lua conf.lua src/*.lua; do luac -p "$f" || echo "FAILED $f"; done
```

A distributable is just the tree zipped up with `main.lua` at the root:

```sh
zip -r game.love main.lua conf.lua src
```

`au.love` in the root is a previously built archive, not a source file.

`F11`/`alt+enter` toggles fullscreen, `Esc` quits. Everything the player has drawn
lives in `~/Library/Application Support/LOVE/notebook-survivors/` — `hero.txt`,
`star.txt`, `rocket.txt`, `sun.txt` and `cools.txt`, one line per row of the
design (delete one to get the drawing you are handed to draw over back).

`README.md` is the design document, and an unusually complete one — it explains
*why* every tool, number and layout decision is what it is. Read the relevant
section before changing behaviour, and update it when behaviour changes.

## Non-negotiable rendering rules

These four constraints run through every module. Breaking any one of them is
visible on screen immediately.

**Eight colours, no alpha.** `src/palette.lua` is the whole palette. Nothing
anywhere calls `love.graphics.setColor` with an alpha argument, and nothing
writes literal RGB. Fades are done by stepping down a colour ramp while
individual stamps drop out at random (dither), never by transparency — alpha
would blend paper and ink into a ninth colour and break the overprint lookup.

**Whole pixels only.** Everything renders into a low-res canvas scaled up by a
whole number (`main.lua`), so drawing must land on integer coordinates.
`love.graphics.circle` and `love.graphics.line` are never used — use
`pixelart.line`, `pixelart.band`, `pixelart.circleOutline`,
`pixelart.circleFill`, or `rectangle("fill", x, y, 1, 1)`. Sprite draws
`math.floor` their position. `Camera.bounds()` snaps to whole pixels for the
same reason.

Nothing is ever drawn at an angle: no call passes a rotation to
`love.graphics.draw`, because a sprite turned at draw time samples off the grid.
The rocket points where it is going anyway, and the way it is allowed to is
`pixelart.turn` — the turn is baked into a new grid of characters up front and
what reaches the screen is an ordinary sprite at an ordinary integer position.

That constraint is about *sprites*, and only sprites. Anything plotted by
`pixelart` goes down at any angle at all, which is why the laser beam is aimed
freely where the rocket is aimed at one of eight: it has no sprite to turn.

**Art is ASCII.** All sprites are tables of equal-length strings in
`src/sprites.lua`, one character per palette key (`.` = transparent), compiled by
`pixelart.newSprite`. Off-palette art asserts at load. Round brush tips past ~9px
across come from `pixelart.newDisc(radius)` instead of hand-authored ASCII, and
`pixelart.turn(rows, eighths)` turns a grid to one of eight headings — exactly on
the quarters, resampled on the diagonals.

**The canvas is not 320x180.** The zoom is picked off the *short* edge of the
window and the canvas is then made exactly as many game pixels as it takes to
cover it — 320x180 on 16:9, 400x180 on a 20:9 phone. Nothing is letterboxed or
stretched; a wider screen shows more page. Anything positioned against a screen
edge reads `Game.vw/vh` and the safe insets (`game.inset.l/t/r/b`), never a
hard-coded 320 or 180.

## Architecture

### The overprint pass

`src/overprint.lua` is why the ruled lines show through ink drawn over them, and
it shapes the whole draw order. `Game:draw` renders the page (background) into
one canvas and everything standing on it into another, then a shader pairs them
pixel by pixel through the `Palette.overprint` lookup table. Consequences:

- Between `Overprint.beginInk()` and `Overprint.finish()`, every pixel must be an
  exact palette colour or the nearest-match lookup guesses.
- `paper` is the one colour that *erases* rather than stacking — that is how the
  gluestick's smear wipes the ruling and why the studio board and the ruler body
  are drawn in paper.
- The HUD is drawn after `Overprint.finish()`, so it sits above the page rather
  than on it and is not overprinted. So are the damage numbers
  (`src/damage.lua`), and for a stronger reason than layering: a red number
  crossing a ruled line would come out slate and a blush one would come out red,
  so a readout run through the pass would mean one thing on blank paper and
  another on squared. They are the one thing in the game drawn *inside* the
  camera transform and *outside* the pass, since a number belongs to the enemy
  it came off and has to scroll with it.

### Game states

`src/game.lua` is one table with `self.state` ∈ `menu`, `timetable`, `studio`,
`playing`, `paused`, `levelup`, `dead`. `Game:update` and `Game:draw` both branch
on it first. `menu`, `timetable`, `studio`, `paused` and `levelup` each delegate
to a module (`menu.lua`, `timetable.lua`, `studio.lua`, `pause.lua`,
`levelup.lua`) that returns an answer which `Game` acts on.

The way into a run is `menu` → `timetable` → `studio` → `playing`, and the
timetable's place in that order is load-bearing: it picks the page the run is
played on (see **Subjects**), and the ruling is what a drawing is read against,
so the hero has to be drawn on the page he will be walking on. A run is built by `Game:reset()` and held, not torn down,
by pausing or by levelling up — both go through `Game:holdRun`/`Game:releaseRun`,
which close any open stroke, land any paid-for aim, and take the thumb stick away
so the whole page is drawable.

`studio` is entered from two places and `Game.studioBack` is what says which:
`"run"` for the hero, drawn between the title screen and a run that has not been
built yet, and `"held"` for a weapon a draft has just handed over, where the run
underneath stays frozen exactly as `Game:openDraft` left it and
`Game:resumeRun` lets it go afterwards. Nothing of the run is drawn while the
board is up — a board is a whole page, not a card laid on one.

All of those screens ask their question by making you draw the answer, and
that shared mechanic lives in `src/scribble.lua`: **a box you scribble in**
(`Scribble.newChoice`), coverage counted on a 2px grid inside the border. The
draft's three answers are the same boxes, one placed under each card
(`Choice:place`); tapping a card fills its box the way the keyboard shortcut
does (`Choice:autoFill`).

A box is *armed* while drawn in and only *answers* on release, warms its
border slate → blue → red through `Scribble.boxColor`, has a keyboard route
that draws the answer rather than jumping past it, and ink that misses
everything is just ink that fades off the page.

A screen that asks a question owns almost nothing of its own. It holds a
`Scribble.newChoice` (the boxes), a `Scribble.newMarks` (ink that missed) and a
`Scribble.newPen` (the pointer, turned into a line), and each frame hands the pen
`down, x, y` plus a `mark` callback and an optional press-edge callback. What is
latched on that press edge is latched for the whole stroke — the studio decides
there whether a stroke is drawing on the board or answering a box. Border colour
is `Scribble.boxColor(box, chosen, confirmT)`; don't reimplement it per screen.

### Subjects

`src/subjects.lua` is the four pages of the book and `src/timetable.lua` is the
screen that picks one, in the same split as the upgrade catalogue and the draft.
A subject is a **page** — how it is ruled — and a **class** — who turns up.

The page is baked at load, one tile per subject, all of them kept
(`Background.setSubject` picks which is the page, `Background.drawPatch` draws a
swatch of any of them for the timetable's cards). A ruling is a pure function of
position inside its tile, and two rules on it both show up as a seam down the
page: the tile's `w`/`h` have to be whole multiples of whatever the ruling
repeats on, and `at` may only answer with one of `Palette.surfaces`.

The page is not decoration, because of the overprint pass: squared paper darkens
a stroke about twice as often as ruled paper does, the unruled page has next to
nothing to darken against, and staves do it in bands. Nothing was written to make
that true.

Every page also carries something **vertical** a page width apart — the ruled
page's blush margin, the staves' bar lines, the grid's own doubled rule, and the
punch holes on the unruled page. Horizontal ruling cannot tell you that you are
walking, since every line coming up the screen looks like the one before it; a
mark that goes past once a page can. Anything added to a ruling wants to keep
that.

The class half is deliberately smaller, and the constraint to keep is that
**every subject spawns from the same table with the same unlock times**. A
subject may only lean on it — `crowd` multiplies a kind's weight, `clock` scales
the difficulty clock — so it changes how much of the horde there is, never what
is in it. `Spawner.new` takes the subject once when the run is built, because the
page is decided before the run exists and cannot change while it is going on.

### Coordinates

`src/input.lua` reports one movement vector and one drawing pointer in **canvas
pixels**, whatever produced them (keyboard/mouse or thumb stick/finger). World
space is canvas space plus `Camera.bounds()`'s `left, top`, converted in
`Game:updateDrawing` every frame — which is what makes holding the pointer still
while walking keep drawing. Marks are stored in world space.

`Input.onPointerDown` is the HUD's first refusal on every press: return true to
swallow it so it doesn't also start a stroke. It runs ahead of the thumb stick,
whose grab zone is a generous quadrant rather than the ring it draws.

Safe-area insets are measured in `main.lua` and pushed into both `Input` and
`Game`; `main.lua` also re-runs the whole fit on every resize/rotation, which
rebuilds the canvas and calls `Game:resize`.

### Tools

`src/tools.lua` holds every tool as a row in one table, and its header comment
documents each field. Nothing addresses a tool by name or index, so moving a row
between `Tools.list` and `Tools.shelved` adds or removes a tool in one line (the
crayon is shelved now) — and takes its upgrade line out of the draft with it.

What the player is *holding* is not `Tools.list` but `loadout.equipped`, the
three-slot strip this run has unlocked. `Game.tool` is a slot on that strip, the
selector and number keys range over it, and `Loadout:tool(slot)` is what hands
out the row. A tool with no line in `src/upgrades.lua` can never be reached.

There are two shapes of tool, and `Game:updateDrawing` routes the press on field
presence alone:

- **Brushes** carry the line fields (radius, spacing, ink per pixel, ramp,
  fade…) and usually a `stamp`. One mark is a `Stroke` (`src/stroke.lua`): a
  chain of stamps at fixed spacing, with damage tested against the *segment*
  between the old and new head so a fast flick can't tunnel past an enemy. A
  brush with no `stamp` keeps no stamps and draws nothing — the rubber is one,
  and all it leaves is `crumbs`, particles shed sideways off the moving tip.
- **Non-brushes** carry `drop`, `snap` or `sweep` instead, and `ink` becomes the
  flat price of one use. `drop` is placed (`src/pin.lua`, `src/staple.lua` — both
  share the block, differing only in the `lands` module), `snap` is aimed
  (`src/ruler.lua`), `sweep` is opened (`src/compass.lua`).

Two rules apply to anything paid for before it lands: it must be landed from
*every* route that can take it away — release, tool change, and pause
(`Game:snapRuler`, `Game:swingCompass`) — or the ink is spent on nothing; and
anything reading the pointer after the press edge needs the `if self.ruler`/
`if self.compass` guard, or a press that was already down when the tool changed
gets claimed by a tool it was never meant for.

Marks that are surfaces rather than attacks (`wall`, `slick`, `freeze`, `linger`)
answer `Stroke:covers(x, y)`, which rejects on a bounding box first.

### Upgrades

Three modules, and the split between them is the whole design:

- `src/upgrades.lua` is the catalogue and nothing else. Every upgrade is a
  *line* — a row with a list of levels, taken in order — and each level is
  `{ text, apply }`. `apply(target, screen)` is handed the run's stat block, or
  for a tool line the run's *copy of that tool*. A line in `Upgrades.endless`
  carries a `forever(n)` that *builds* the level it is asked for instead of
  having one written down; read every level through `Upgrades.levelAt` and every
  length through `Upgrades.levelsIn`, and neither shape has to be special-cased.
- `src/loadout.lua` is what one run has learned. It holds the level reached on
  each line and turns that into `stats`, `tools` (the run's copies) and
  `weapons`, and it **replays every level from scratch** on every change. So a
  level must be written as a function of what it changes, never as a difference
  from what the level before it did. That replay is also what makes the one
  screen-measured number (the full-page ruler) correct again after a resize —
  `Game:resize` calls `Loadout:rebuild`.
- `src/levelup.lua` is the draft screen and knows nothing about what any
  upgrade does; it hands back an id.

A run may only *start* so many lines of each kind — `Loadout.SLOTS`, four
passive weapons, five passives and four tools. `Loadout:candidates` is the one
place that applies it, and the clause to preserve there is that a line already
under way is offered whatever the slots say: without it, filling the last slot
could strand a line on level one forever. The catalogue therefore dries up around
52 to 60 of the 114 levels rather than at the end of itself — 59 exactly, if the
three tools a run drafts all have their upgrades written.

**The draft does not dry up with it.** `Loadout:roll` pads whatever the
catalogue cannot fill with the endless lines (`Upgrades.endless`, nine of them,
uncapped, a few percent each), so it always returns three cards and a level
always costs the run its momentum. Two rules there: real candidates are drawn
first and always, so the padding can never take a place a genuine line could have
had; and the endless lines stay *out* of `Upgrades.list`, because anything in
that table is a candidate from the first draft onward. `Game:openDraft` returning
false is now only reachable with an empty endless table.

The XP ladder is `0.9 × level² + level + 5` (`src/player.lua`), quadratic rather
than the exponential it was, and the two facts are one decision: the old ratio
walled a run off around level 28, well short of the 59 picks the slots allow, so
half the catalogue was never offered. The 0.9 is set against what the spawner
actually pays out — changing either one without the other moves where a run ends
up.

A run is **not** meant to finish its build before it wins. The boss arrives at
minute 10 (`Spawner.BOSS_AT`) and a winning run is level 37 to 44 — around two
thirds of the 59 picks. Level 60 belongs to `ENDLESS`, and lands between minute
16 and 25.

That only holds because **xp scales with the hp multiplier** in `Enemy.new`,
which is the one number tying the two systems together. `HP_PER_CYCLE` compounds
(1.4), so a run clears proportionally fewer enemies a minute each cycle; paying
the flat `def.xp` would mean income *falling* while level costs rise, and a run
stalling in cycle two whatever it did. Scale one and the other has to follow.

Tools are drafted, not issued, and that is what the tool cap is really about: a
tool line's **first level is the unlock**, so `levelOf(line) > 0` is the whole
of "is this tool equipped" and there is no separate flag to keep in step.
`toolLine` in `src/upgrades.lua` builds one; `opts.start` marks the tool a run
begins holding (the pencil), which `Loadout.new` takes before the run is built
and which costs a slot like any other. `Loadout:syncEquipped` turns the taken
lines into `loadout.equipped`, in unlock order, and that list is append-only —
which is what lets `Game.tool` stay a *slot number* that goes on meaning the
same tool when a new one is unlocked mid-run.

Two rules fall out of this and are easy to break:

- **Nothing reads a tool's numbers off `Tools.list` mid-run.** `Tools.list` is
  shared by every run the program plays and upgrades move its numbers, so
  `Game:updateDrawing` takes the row from `Loadout:tool` and everything
  downstream is handed that copy. `Tools.get` is for names, icons and counts.
- **A level is banked, not applied where it is earned.** `Player:addXp` counts
  levels into `player.pending`; `Game:update` opens the draft once the frame is
  otherwise finished, and only if the run did not just end. Taking one opens the
  next draft rather than letting a double level-up swallow a pick.

What a run is carrying is drawn by `hud.lua` (`Hud.drawWeapons`,
`Hud.drawPassives`) and called from the two screens that hold the run —
`pause.lua` and `levelup.lua` — never during play. Weapons go down the left
margin in the tool selector's own boxes on the same midline, level beside the
box; passives go in one line under the question, same box, level above it; tools
are the selector column itself, which grows its levels while the run is held.
The draft lays its cards out between `Hud.leftMargin()` and `Hud.rightMargin()`,
both of which are fixed and claimed whether or not there is anything in the
column — a margin that appears the moment you take your first weapon would move
the cards under the pointer that was about to pick one.

Each of the three carries a slot counter under it (`2/4`, red once full), drawn
on held screens only and drawn even when the count is zero. Two rules keep them
honest: a counter hangs *below* its column rather than being centred with it, so
nothing moves when it appears; and `Hud.passiveRow` — which is what both screens
reserve height from — has to keep agreeing with what `Hud.drawPassives` actually
lays out, counter included, or the block will overlap whatever is under it.

Anything laid over a held run is drawn on paper rather than straight on the
page — the draft's cards, the pause card, and the boxes those icons sit in.
Paper is the only colour that covers what is under it, and a frozen run is far
too busy to read lettering against. The pause card is sized to the widest string
it can ever hold, not the current one, so it doesn't twitch when the prompt
changes.

A passive weapon is a stat block that appears when its first level is taken, a
module, and a row in `WEAPONS` in `loadout.lua` pairing the two. The instance
outlives reconfiguration, so an orbit keeps its angle when it is upgraded and a
rocket already in the air keeps the numbers it was fired with. It hits through
`Game:eachNear` (the same nine cells a bullet asks about) and kills through
`Game:killEnemyAt`, which finds the victim by identity rather than index. What
aims itself asks `Game:nearestEnemy` — or `Game:nearestEnemies` where one volley
wants a target per shot rather than a target for the volley — the whole horde,
not the nine cells, because a target is picked far further off than a cell is
wide and only a couple of times a second.

Two of the five built are opposite halves of one idea and are worth keeping
that way: `orbital.lua` is bolted to you and only touches what comes to it,
`rocket.lua` leaves and picks something off. `sun.lua` is neither — it is
anchored to a *corner of the screen* rather than to anything in the world, so it
reads `Camera.bounds()` every frame in both `update` and `draw`, rises and sets
on its own clock and moves to another corner each cycle. It is also the one
weapon that covers ground rather than touching points, so its burn asks
`Game:eachWithin` (the whole horde, on a tick) rather than `Game:eachNear` --
the sunrays its last level throws are ordinary projectiles and ask the hash like
anything else. Its disc is solid: it hides what is standing under it, which is
the trade the whole line is written around. What survives two ticks is bleached
(`Enemy:sunburn`) and keeps a graphite ghost of its outline until it dies —
which is the only account the player gets of what happened under there, so the
sun's damage ceiling (5 a tick, against a 12hp skull) exists to keep that
reachable and should not be nudged up.

`cools.lua` is the fourth and the loosest of all: a cool S that comes in from
*off* the page in a random direction, aimed once at where the player was
standing as it set off, and cuts everything on the line it takes until the
viewport runs out from under it -- so it reads `Camera.bounds()` every frame
like the sun does, both to spawn outside it and to die outside it. Coming in
from outside rather than out of the player is what makes the line a whole chord
of the page instead of a radius, and it means an S is not on the page until all
of it is (`arrived`): until then no edge rule applies at all, or it would bounce
straight back out of the page it was arriving on. It is bigger than a point --
9x17, and it never turns -- so it hits through a box test rather than a radius,
and asks `Game:eachWithin` because the nine 12px cells `eachNear` looks in only
guarantee 12px of reach.

Its whole line is about **bounces**: none at all on the first level, so the first
one a run drafts crosses the page once and is gone; then one; then more often;
then off pen walls too (`game.walls`, the only solid ink there is), which costs a
bounce exactly as an edge does and so is a choice rather than a gift; and then
the finale, which is the one thing in the game that never leaves the page. That
last level is written as `bounces = math.huge` at launch rather than as a flag,
so every edge rule -- is there one left, take one away -- goes on working
untouched.

Speed is one number the whole way up (70, against the player's 58) and nothing
in the line moves it: the line an S draws is the same line at any speed, so
there is nothing there worth a level.

`MAX_LIVE` in the module (2) is how many may be on the page at once whatever the
clock says, since frequency compounds with how long one lives and a run without
it was putting five or six across the page. `CoolS:cap` drops that to **one**
once `forever` is on the block: a permanent S is a thing you learn the path of,
and two would be a room with two things loose in it. A launch with nowhere to go
is *held* rather than spent, the way a rocket holds a shot with nothing in range
(`CoolS:launch` returns false and the clock comes back as `FULL_LOOK`) -- which
is also how the finale quietly ends the clock, since the page is full from then
on and never empties.

It is also the one thing in the game drawn with a one-pixel `Palette.sky` rim
under the sprite, and that is why: an S is the same colour and the same weight
of line as the hero, the crowd and every mark on the page, so without the rim it
is six thin strokes crossing a page made of thin strokes. Four offset
`drawMask` calls rather than authored art, since the S is whatever was left on
the board -- the same trick `Enemy:draw` bleaches with -- and it does not move
`HIT_W`/`HIT_H`. The rim is drawn for every live S before any of their bodies
are, so one S's rim can never sit on another's ink. It lives in `Sprites.rim`
next to `Sprites.shadow` rather than in `cools.lua`, because the studio's
life-size preview has to draw the same rim on the same drawing -- `rim = true`
on the design (src/design.lua) is what asks for it, exactly as `walks` asks for
the ground and the bounce.

`beam.lua` is the fifth and the only one that is *aimed*: it fires down the line
the player is walking (`player.headX/headY`, the last non-zero input vector).
The sight is two things and neither is a sprite -- a short slate pointer per arm
that turns with you at all times, and a one-pixel `blush` line down each of
those arms that flashes over the last stretch of the wind-up. The aim is live
through both and latched at the shot, which makes the flash a promise rather
than a warning. The beam itself is `blush` with a one-pixel `red` edge, drawn as
the band twice -- the second pass two pixels narrower -- so the edge is the
band's own outermost pixels rather than a line that has to agree with it.

It is also the one weapon with **no board and no sprite at all**, and the two
facts are the same fact: a pointer and a beam are both lines the levels size, so
there is nothing here a drawing could be -- and because nothing here is a
sprite, nothing has to round its heading to eight. It is aimed at *any* angle,
which is the one place in the game that is true. `pixelart.band` is what draws
it: one span per pixel of the longer axis, because plotting a perpendicular
pixel at a time leaves holes at angles like 27 degrees. Both its ends are cut
square to the line rather than to the axis, which is what lets a disc of the
band's own half-width round one off exactly -- the beam leaves from the tip of
the pointer rather than from the middle of the hero, so that end is on show.

Three rules hold it together and are easy to break: the line stops at
`Camera.bounds()` for the sun's reason, so nothing is killed off-screen; one
shot hits a thing once however many arms cross it (`struck`), which nothing can
reach while the arms are two ends of one line starting clear of you, and which
stays because both of those are numbers; and the flash, the beam and the damage
all come off `Beam:eachLine`, so they are the same line by construction rather
than by three places agreeing about it.

Its line never moves the damage: what the four upgrades sell is the beam being
*there* -- holding instead of flashing, twice as often, a wider band, and then
out of both ends of the line. `charge` is the one number the line refuses to
sell, since the wind-up is the half of the weapon you play. It covers a whole page-width
line, so it asks `Game:eachWithin` for a circle round the muzzle and tests the
band itself -- there is no line query -- on a tick rather than every frame.

Four of the five are drawn by the player rather than authored (see below), the
beam being the exception, though the sun's board is only its *face*: the disc,
rim and rays are sized by the levels. The rocket is the one drawn thing in the
game with a heading, so it is the one kept at more than one: `pixelart.turn`
builds a ring of eight and a rocket picks the nearest when it launches, once,
since it flies a straight line. Nothing turns at draw time — see the rendering
rules, and note that this is exactly why the beam, which has no sprite, is free
of the eight.

### Spatial hashes

Two, with different rebuild policies:

- `Game:buildGrid` — 12px cells, rebuilt every frame, used for enemy separation
  and bullet hits.
- `src/walls.lua` — 16px cells of pen-line segments, rebuilt only when
  `wallsDirty` (a wall stroke grew or expired), so it sits still most of the
  time. Segments are filed under every cell within reach, so an enemy queries
  with a single lookup.

Enemies commit to a way round a wall for `SLIDE_HOLD` seconds rather than
re-deciding each frame, and `Enemy:resolveWalls` gets the last word so nothing
ends up standing inside ink.

### Draw layering

`Game:draw`'s order is load-bearing and commented at each step: spent
pins/staples (page memory, culled to the camera by `Game:eachSpent`) → lingering
marks → other marks → drop marks/ruler guides/compass guides → gems → enemies and
player sorted by `y` → live drops and compasses *over* the crowd → passive
weapons (none of them stands on the page: a star is attached to you, a rocket is
in the air over it, the sun is above the page entirely -- its disc is solid and
hides the corner it is in, which is deliberate -- a cool S is a doodle floating
over the lot, and a beam is light laid across all of it) → rulers → the player
again if a ruler is mid-slap →
bullets → particles → (after the overprint pass, still under the camera) damage
numbers.

The pause card and the draft are drawn after `Overprint.finish()`, alongside the
HUD, so they sit above the page rather than on it. That is also why the draft's
cards can be filled in `Palette.paper` and read as opaque paper lying on the
page. The damage numbers go down there too, between the pass and the HUD — over
the page, under the readouts.

### Damage numbers

`src/damage.lua` throws a number up off whatever a hit landed on, and the tier
table in it is the whole design: six rows climbing from a soft blush digit in
the small face ringed red, through blush and then red ringed ink, to paper at
twice the size ringed red and then ink, and finally blush at three times the
size. The
thresholds are absolute rather than measured against what was hit, deliberately
— a run getting stronger is *supposed* to look like the page filling with bigger
numbers, and a crit jumps a tier or two on its own. Only the two ends of the
table are ringed anything but ink, and both on purpose: the smallest is meant to
be skippable and the biggest does not need colour to be seen.

Three rules hold it together:

- **Damage is banked, not announced.** `Enemy:hurt` is the one door every hit in
  the game goes through, so it adds to `enemy.took` and nothing more;
  `Game:spendHits` runs once the frame's damage has all landed and spends the
  total after `HIT_HOLD`. That is what makes four weapons landing on one blob in
  the same breath read as one number instead of four stacked on the same pixel.
  `Game:killEnemy` flushes immediately — a moment later there is nothing left to
  hang the number off. Nothing else may reset `took`.
- **The pop steps between whole scales.** A size over, the size, a size under
  and hollow — the ring alone, fill lifted off. Never a fractional scale, for
  the same reason nothing else in the game has one; `Bold:print` takes a
  whole-number scale and floors its position. Hollow rather than filled-in-one-
  colour because the latter is a solid rectangle at every size the face draws
  at, and it is the only exit the three 1x tiers have at all. A `steady` tier
  skips the overshoot entirely: doubling a 1x number puts a figure twice the
  height of the enemy on screen, and on the tiers that make up most of a run's
  numbers that is the page shouting about chip damage.
- **The outline is baked into the face, not drawn as offset copies.** The
  `Sprites.rim` trick eats a pixel off the pitch at each side, which fuses the
  digits of a number into one plate, and it costs eight draws a glyph instead of
  two. `Bold:print`/`Bold:printRing` are the same geometry in two colours, and
  the ring includes the counters on purpose — that is what keeps a `0` from
  reading as a solid block at 1x. The pitch is one pixel *tighter* than the
  outlined cell so neighbouring digits share their padding and a number reads as
  one figure; that only works while every ring is drawn before every body, in a
  single colour, so don't reorder `Damage:draw`.

There are two bold faces and a tier picks one with `small` — `Font.bold` at 5x7
and `Font.boldSmall` at 5x5, the same width so a number is placed identically
either way. 5x5 is the floor: an 8 wants `3 + 2c` rows, so 7 or 5 and nothing
between, and nothing below without dropping to one-pixel strokes, which is the
HUD face and does not survive being outlined.

Both carry the whole printable ASCII repertoire, not just the ten digits the
damage numbers ask for, so the same outlined face at the same two sizes is there
for anything the page wants to *shout* rather than state. Three rules hold the
alphabet inside a five-column cell and each is documented at the table it
governs in `src/font.lua`: a curve is a cut corner (which is the only thing
keeping O off 0, S off 5 and G off 6, since the digits are square and cannot
move); M and N move their *weight* rather than drawing a diagonal, there being
one column between the stems, and at 5x5 that leaves M, H and W separated by
nothing but which single row is solid; and a few symbols are lattices authored at
one pixel, since there is no two-pixel hash in five columns.

### Determinism and allocation

The background (`src/background.lua`) is infinite and stores nothing: each
subject's paper is baked once into an `ImageData` and drawn as a single
texture-wrapped quad whose UVs are the world coordinates. Everywhere else that wants variation uses `util.hash01`, a pure
function of its inputs — per-stamp pencil grain seeded off the stroke seed and
stamp index, an enemy's walk-cycle offset and preferred way round a wall, the
hand-drawn wobble in `scribble.lua` — so nothing needs a stored seed or a random
table.

The page is deliberately plain — no doodles, no grain, ruling and page furniture
only (the margins, the bar lines, the punch holes). That is a design decision,
not a gap: the page is what every mark, enemy and overprinted rule is read
against, and anything printed on it competes with what you are meant to be
looking at. See the README's background section before adding
anything to it.

GPU resources that are replaced rather than kept are released explicitly rather
than left to the collector — `Sprites.setDrawn` on every changed studio cell,
and the three screen-sized canvases in `main.lua`/`Overprint.resize`, which a
window drag reallocates every frame.

### The things you draw

The player sprite is drawn by the player, and so is the star that orbits him, the
rocket that leaves him, the face on the sun that comes up over him and the cool S
that floats away from him -- the sun's being the only design that is part of a
thing rather than all of it, since the disc it sits on is sized by the upgrade
line and drawn rather than authored. The laser beam is the one weapon with no
board at all: it is lines the levels size, and there is nothing in it a drawing
could be. `src/design.lua` is one of these drawings — the grid
of palette keys, the sprite it keeps up to date through `Sprites.setDrawn`
(releasing the old images), and its own file in the save directory, ignoring a
file it can't draw. `Design.by` is all of them. `src/studio.lua` is the board any
of them is drawn on: one cell per sprite pixel, no resampling anywhere, sized
from `design.w/h` rather than from anything written down.

A design is fixed at the size of the art it starts from, and that is what keeps
everything measured off a sprite honest — `Player.radius`, the orbit's `HIT_R`,
the rocket's. You can change what a star looks like; you cannot draw a bigger
one. The rocket is the loosest about *what* is drawn — a dart, an arrow or a
sharpened pencil is the same board — as long as the point is the right-hand end,
which is heading one of the eight it is turned to.

A design with `turns = true` is kept at all eight headings rather than one, in
`Sprites.turned[key]`, rebuilt by `Sprites.setDrawn` on every changed cell (a
quarter of a millisecond for an 11x7 design, and nothing else is happening on
that screen). Only give it to something with a heading *and* a sprite: it costs
eight sprites instead of one, and it is the only place in the game where a
drawing is not used exactly as drawn. The four quarter turns are exact
permutations; the four diagonals resample, so solid shapes come through and
single-pixel lines do not. That is a known, accepted cost — see `pixelart.turn`.
Something with a heading and no sprite has no reason to round to eight at all,
which is how the beam is aimed anywhere.

An upgrade line asks for a board by naming a design in its `design` field
(`src/upgrades.lua`), and `Game:takeUpgrade` opens it on the *first* level of
that line only: the levels after it change what the thing does, not what it
looks like. The card's icon is not the drawing — the icons say what is on offer
and are all the same 11x11 glyph.

## Extending

- **Enemy:** sprite in `Sprites.enemies` + row in `Enemy.types` + row in `TABLE`
  in `src/spawner.lua` (unlock time, weight).
- **Tool:** append a row to `Tools.list` with an icon in `Sprites.icons`, *and* a
  `toolLine` in `Upgrades.list` naming it — the line's first level is what
  unlocks it, so a tool without one can never be drafted and never reaches the
  strip. Its six upgrade levels go in `opts.levels`.
- **Upgrade:** append a row to `Upgrades.list` with an icon in `Sprites.icons`.
  Nothing else; the draft offers whatever still has a level left and a slot for.
  A row in `Upgrades.endless` instead of `Upgrades.list` is one with no last
  level, offered only once the catalogue has run out — `endlessLine` builds it,
  and its numbers want to be a few percent rather than a finale's worth. The
  rule there is that **nothing endless may multiply a number downwards**: ink
  cost and the refill delay have no endless line because a few percent off
  either, for ever, converges on the meter not being in the game. Where a
  catalogue line multiplies, its endless answer usually adds instead, so it
  climbs in a line rather than a curve; the one number that has to fall (the
  auto-shot's interval) is floored.
- **Passive weapon:** an upgrade row whose first level puts a block on the
  stats, a module answering `new`/`configure`/`update(dt, game, grid)`/
  `draw(game)`, and a row in `WEAPONS` in `src/loadout.lua`. Hit small things at
  a point through `Game:eachNear`; anything covering more ground than the nine
  12px cells that looks in asks `Game:eachWithin` instead, on a tick rather than
  every frame. There is no line query: something reaching across the page (the
  beam) asks for a circle that holds its line and tests the band itself.
- **Something the player draws:** a row in `Design.by` in `src/design.lua`
  naming the `Sprites` field it keeps up to date, the art it starts from, its
  save file and what the board calls it — plus, to be drawn when a run earns it
  rather than on the way in, a `design` field on the upgrade row naming it. Add
  `turns = true` only if the thing has a heading; it is drawn nose-right and
  read out of `Sprites.turned[key]`. Whatever aims it rounds its own heading to
  the same eight first, or the drawing points somewhere the thing is not going —
  which is a reason to consider drawing the thing with `pixelart` instead, as
  the beam does, and keeping every angle.
- **Balance:** `SPEED`, `FIRE_RATE`, `DAMAGE`, `RANGE` in `src/player.lua` (the
  loadout only scales what is written there), `Enemy.types`, spawn interval,
  min-alive floor (`FLOOR_RATE`) and `TABLE` in `src/spawner.lua`, ink costs in
  `Tools.list`, level tables in `src/upgrades.lua`. `XP_RISE` in
  `src/player.lua` is how fast a run levels, and it is set against what the
  spawner pays out rather than chosen on its own — move one and re-check the
  other, or the last real pick stops landing between minute 15 and 20.
- **Subject:** a row in `Subjects.list` — a `paper` (tile size and what colour is
  at a position inside it), a `name` and `says` for the card, and the two dials a
  class gets, `crowd` and `clock`. Nothing else: the page is baked with the rest
  at load, the timetable lays out however many cards there are, and the number
  keys go up to as many.
- **Paper:** the specs at the top of `src/subjects.lua`.

## Style

Comments here explain *why* a thing is the way it is — the trade-off, the bug it
prevents, the feel it produces — rather than restating the code, and modules open
with a paragraph framing what they are. Match that when editing; a change that
invalidates one of those paragraphs should update it. Numbers that encode a design
decision (the pushpin's 10 damage sitting one short of the skull's 12hp, for
instance) are documented in `README.md` and should not be nudged casually.
