# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running

```sh
love .                  # run from the project root
```

Requires LÖVE 11.x (`t.version = "11.4"` in `conf.lua`), which means LuaJIT/Lua 5.1
semantics — `unpack` is a global (`src/overprint.lua` relies on it), not `table.unpack`.

There is no build step, no test suite, no linter and no dependency manifest. A
distributable is just the tree zipped up with `main.lua` at the root:

```sh
zip -r game.love main.lua conf.lua src
```

`au.love` in the root is a previously built archive, not a source file.

`F11`/`alt+enter` toggles fullscreen, `Esc` quits. The saved hero design lives at
`~/Library/Application Support/LOVE/notebook-survivors/hero.txt` (delete it to get
the stick man back).

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

**Art is ASCII.** All sprites are tables of equal-length strings in
`src/sprites.lua`, one character per palette key (`.` = transparent), compiled by
`pixelart.newSprite`. Off-palette art asserts at load. Round brush tips past ~9px
across come from `pixelart.newDisc(radius)` instead of hand-authored ASCII.

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
  rubber wipes the ruling and why the studio board and the ruler body are drawn
  in paper.
- The HUD is drawn after `Overprint.finish()`, so it sits above the page rather
  than on it and is not overprinted.

### Game states

`src/game.lua` is one table with `self.state` ∈ `menu`, `studio`, `playing`,
`paused`, `dead`. `Game:update` and `Game:draw` both branch on it first. `menu`,
`studio` and `paused` each delegate to a module (`menu.lua`, `studio.lua`,
`pause.lua`) that returns an answer string which `Game` acts on. A run is built by
`Game:reset()` and held, not torn down, by pausing.

All three of those screens ask their question the same way — a labelled box you
scribble in — and that shared mechanic lives in `src/scribble.lua`: coverage is
counted on a 2px grid, a box is *armed* while drawn in and only *answers* on
release, and ink that misses a box is just ink that fades off the page.

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
documents each field. Nothing addresses a tool by name or index — the selector,
number keys, input routing and ink meter all read `Tools.list` — so moving a row
between `Tools.list` and `Tools.shelved` adds or removes a tool in one line (the
crayon is shelved now).

There are two shapes of tool, and `Game:updateDrawing` routes the press on field
presence alone:

- **Brushes** carry a `stamp` function and line fields (radius, spacing, ink per
  pixel, ramp, fade…). One mark is a `Stroke` (`src/stroke.lua`): a chain of
  stamps at fixed spacing, with damage tested against the *segment* between the
  old and new head so a fast flick can't tunnel past an enemy.
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
player sorted by `y` → live drops and compasses *over* the crowd → rulers → the
player again if a ruler is mid-slap → bullets → particles.

### Determinism and allocation

The background (`src/background.lua`) is infinite and stores nothing: the paper
is baked once into a 192x100 `ImageData` (`TILE_H` must stay a multiple of
`RULE_PERIOD`) and drawn as a single texture-wrapped quad whose UVs are the world
coordinates. Everywhere else that wants variation uses `util.hash01`, a pure
function of its inputs — per-stamp pencil grain seeded off the stroke seed and
stamp index, an enemy's walk-cycle offset and preferred way round a wall, the
hand-drawn wobble in `scribble.lua` — so nothing needs a stored seed or a random
table.

Note: `README.md`'s background section is out of sync here. It describes doodles
(`Sprites.doodles`, `DOODLE_CHANCE`, `CELL`) and graphite grain (`GRAIN`) that no
longer exist in `src/background.lua`; the tile is currently paper, ruling and
margin only.

### The hero

The player sprite is drawn by the player. `src/studio.lua` is the board (15x19
cells, one cell per sprite pixel, no resampling anywhere); `src/hero.lua` owns the
design grid, rebuilds `Sprites.player` on every changed cell — releasing the old
images — and persists it to `hero.txt` in the save directory, ignoring a file it
can't draw. There is only ever one hero: the run, the title screen's doodle and
the studio's life-size preview all draw the same sprite.

## Extending

- **Enemy:** sprite in `Sprites.enemies` + row in `Enemy.types` + row in `TABLE`
  in `src/spawner.lua` (unlock time, weight).
- **Tool:** append a row to `Tools.list` with an icon in `Sprites.icons`.
- **Balance:** `SPEED` and the fire/damage fields in `src/player.lua`,
  `Enemy.types`, spawn interval and `TABLE` in `src/spawner.lua`, ink costs in
  `Tools.list`.
- **Paper:** `RULE_THICKNESS`, `RULE_PERIOD`, `RULE_COLOR`, `MARGIN_X` at the top
  of `src/background.lua`.

## Style

Comments here explain *why* a thing is the way it is — the trade-off, the bug it
prevents, the feel it produces — rather than restating the code, and modules open
with a paragraph framing what they are. Match that when editing; a change that
invalidates one of those paragraphs should update it. Numbers that encode a design
decision (the pushpin's 10 damage sitting one short of the skull's 12hp, for
instance) are documented in `README.md` and should not be nudged casually.
