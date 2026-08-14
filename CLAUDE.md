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
`star.txt` and `rocket.txt`, one line per row of the design (delete one to get the
drawing you are handed to draw over back).

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
`pixelart.line`, `pixelart.circleOutline`, `pixelart.circleFill`, or
`rectangle("fill", x, y, 1, 1)`. Sprite draws `math.floor` their position.
`Camera.bounds()` snaps to whole pixels for the same reason.

Nothing is ever drawn at an angle: no call passes a rotation to
`love.graphics.draw`, because a sprite turned at draw time samples off the grid.
The rocket points where it is going anyway, and the way it is allowed to is
`pixelart.turn` — the turn is baked into a new grid of characters up front and
what reaches the screen is an ordinary sprite at an ordinary integer position.

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
  than on it and is not overprinted.

### Game states

`src/game.lua` is one table with `self.state` ∈ `menu`, `studio`, `playing`,
`paused`, `levelup`, `dead`. `Game:update` and `Game:draw` both branch on it
first. `menu`, `studio`, `paused` and `levelup` each delegate to a module
(`menu.lua`, `studio.lua`, `pause.lua`, `levelup.lua`) that returns an answer
which `Game` acts on. A run is built by `Game:reset()` and held, not torn down,
by pausing or by levelling up — both go through `Game:holdRun`/`Game:releaseRun`,
which close any open stroke, land any paid-for aim, and take the thumb stick away
so the whole page is drawable.

`studio` is entered from two places and `Game.studioBack` is what says which:
`"run"` for the hero, drawn between the title screen and a run that has not been
built yet, and `"held"` for a weapon a draft has just handed over, where the run
underneath stays frozen exactly as `Game:openDraft` left it and
`Game:resumeRun` lets it go afterwards. Nothing of the run is drawn while the
board is up — a board is a whole page, not a card laid on one.

All four of those screens ask their question by making you draw the answer, and
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
  for a tool line the run's *copy of that tool*.
- `src/loadout.lua` is what one run has learned. It holds the level reached on
  each line and turns that into `stats`, `tools` (the run's copies) and
  `weapons`, and it **replays every level from scratch** on every change. So a
  level must be written as a function of what it changes, never as a difference
  from what the level before it did. That replay is also what makes the one
  screen-measured number (the full-page ruler) correct again after a resize —
  `Game:resize` calls `Loadout:rebuild`.
- `src/levelup.lua` is the draft screen and knows nothing about what any
  upgrade does; it hands back an id.

A run may only *start* so many lines of each kind — `Loadout.SLOTS`, five
passive weapons, five passives and three tools. `Loadout:candidates` is the one
place that applies it, and the clause to preserve there is that a line already
under way is offered whatever the slots say: without it, filling the last slot
could strand a line on level one forever. The draft therefore dries up around 41
to 53 of the 115 levels rather than at the end of the catalogue, and
`Game:openDraft` returning false is the ordinary end state of a long run.

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

Each of the three carries a slot counter under it (`2/3`, red once full), drawn
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
aims itself asks `Game:nearestEnemy` — the whole horde, not the nine cells,
because a target is picked far further off than a cell is wide and only a couple
of times a second.

The two built are opposite halves of one idea and are worth keeping that way:
`orbital.lua` is bolted to you and only touches what comes to it, `rocket.lua`
leaves and picks something off. Both are drawn by the player rather than
authored (see below). The rocket is the one thing in the game with a heading, so
it is the one thing kept at more than one: `pixelart.turn` builds a ring of
eight and the rocket picks the nearest when it launches, once, since it flies a
straight line. Nothing turns at draw time — see the rendering rules.

### What the page scatters

`src/pickup.lua` is the other half of the gem: a gem is thrown at your feet by a
kill you already made, and a pickup is out there and pays you for walking to it.
Three kinds — a heart, an ink droplet, a diamond worth a whole level — and the
design rule they all obey is that **they land out of view and there is no pull
at all**. The magnet stat is a gem thing; a pickup is taken by touching it.
Adding attraction would collapse the two into the same reward.

They arrive in two layers, and the split is the point:

- **The scatter**, a clock in `Game:updatePickups`, drops one just past the
  screen edge every `Pickup.EVERY` seconds. It clears the edge by far less than
  the enemy ring does — that ring clears the *corner*, which above or below is a
  hundred pixels of blind walking, and a pickup nobody ever sees promotes
  nothing.
- **The fixed layer**, `Pickup.materialize`, is the page's own: one spot in
  roughly every third `CELL`, hashed out of the cell coordinates the way the
  ruling is, so it is a *place* rather than a beat on a clock. It wakes when you
  come near, is still there if you leave and come back, and once taken is spent
  for the run (`game.pickupTaken`, keyed by cell). Knowing where one is is worth
  something.

Three rules hold that arrangement together and are easy to break:

- **Only scattered pickups count against `Pickup.MAX`.** The fixed ones are the
  page's, so walking into a rich patch must not switch the scatter off. The
  clock also keeps ticking at the cap rather than banking a volley to fire the
  moment one is taken.
- **The seed is per run, not global.** Every run starts at (0, 0), so one shared
  layout would hand every run the same opening diamond in the same spot — an
  opening you can memorise is an opening, not a discovery. Within a run it never
  moves.
- **A pickup is always consumed, even when it can do nothing.** A heart that
  bounced off a full bar sat there holding one of the `MAX` slots and quietly
  throttled the clock. `TAKE` is the one table to add a kind to; the diamond
  banks its level through `Player:levelUp` and the run spends it the ordinary
  way, in `Game:update`.

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
marks → other marks → drop marks/ruler guides/compass guides → pickups → gems →
enemies and player sorted by `y` → live drops and compasses *over* the crowd →
passive weapons (none of them stands on the page: a star is attached to you and a
rocket is in the air over it) → rulers → the player again if a ruler is mid-slap
→ bullets → particles.

The pause card and the draft are drawn after `Overprint.finish()`, alongside the
HUD, so they sit above the page rather than on it. That is also why the draft's
cards can be filled in `Palette.paper` and read as opaque paper lying on the
page.

### Determinism and allocation

The background (`src/background.lua`) is infinite and stores nothing: the paper
is baked once into a 192x100 `ImageData` (`TILE_H` must stay a multiple of
`RULE_PERIOD`) and drawn as a single texture-wrapped quad whose UVs are the world
coordinates. Everywhere else that wants variation uses `util.hash01`, a pure
function of its inputs — per-stamp pencil grain seeded off the stroke seed and
stamp index, an enemy's walk-cycle offset and preferred way round a wall, the
hand-drawn wobble in `scribble.lua`, the fixed layer of pickups — so nothing
needs a stored seed or a random table. The pickups are the one of those that
carries a seed at all (`game.pickupSeed`), and it is per run rather than per
program: what it buys is a page whose prizes sit still while you play it and are
somewhere else next time.

The page is deliberately plain — no doodles, no grain, ruling and margin only.
That is a design decision, not a gap: the page is what every mark, enemy and
overprinted rule is read against, and anything printed on it competes with what
you are meant to be looking at. See the README's background section before adding
anything to it.

GPU resources that are replaced rather than kept are released explicitly rather
than left to the collector — `Sprites.setDrawn` on every changed studio cell,
and the three screen-sized canvases in `main.lua`/`Overprint.resize`, which a
window drag reallocates every frame.

### The things you draw

The player sprite is drawn by the player, and so is the star that orbits him and
the rocket that leaves him. `src/design.lua` is one of these drawings — the grid
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
that screen). Only give it to something with a heading: it costs eight sprites
instead of one, and it is the only place in the game where a drawing is not used
exactly as drawn. The four quarter turns are exact permutations; the four
diagonals resample, so solid shapes come through and single-pixel lines do not.
That is a known, accepted cost — see `pixelart.turn`.

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
- **Passive weapon:** an upgrade row whose first level puts a block on the
  stats, a module answering `new`/`configure`/`update(dt, game, grid)`/
  `draw(game)`, and a row in `WEAPONS` in `src/loadout.lua`.
- **Pickup:** a sprite in `Sprites.pickups`, a row in `KINDS` in
  `src/pickup.lua` (weight) and a function in `TAKE` under the same key. Both
  layers read the one weighted table, so a kind added there is scattered *and*
  baked into the page. `TAKE` must always consume — see the pickups section.
- **Something the player draws:** a row in `Design.by` in `src/design.lua`
  naming the `Sprites` field it keeps up to date, the art it starts from, its
  save file and what the board calls it — plus, to be drawn when a run earns it
  rather than on the way in, a `design` field on the upgrade row naming it. Add
  `turns = true` only if the thing has a heading; it is drawn nose-right and
  read out of `Sprites.turned[key]`.
- **Balance:** `SPEED`, `FIRE_RATE`, `DAMAGE`, `RANGE` in `src/player.lua` (the
  loadout only scales what is written there), `Enemy.types`, spawn interval,
  min-alive floor (`FLOOR_RATE`) and `TABLE` in `src/spawner.lua`, ink costs in
  `Tools.list`, level tables in `src/upgrades.lua`.
- **Paper:** `RULE_THICKNESS`, `RULE_PERIOD`, `RULE_COLOR`, `MARGIN_X` at the top
  of `src/background.lua`.

## Style

Comments here explain *why* a thing is the way it is — the trade-off, the bug it
prevents, the feel it produces — rather than restating the code, and modules open
with a paragraph framing what they are. Match that when editing; a change that
invalidates one of those paragraphs should update it. Numbers that encode a design
decision (the pushpin's 10 damage sitting one short of the skull's 12hp, for
instance) are documented in `README.md` and should not be nudged casually.
