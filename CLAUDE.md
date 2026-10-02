# CLAUDE.md

Guidance for Claude Code (claude.ai/code) when working in this repository.

## Where the documentation is

This file is the short operational brief. Two long documents sit beside it and
neither is optional reading before a behavioural change:

- **`DESIGNDOC.md`** — the architecture reference. Every subsystem in one place:
  the overprint pass, game states, subjects, courses, the purse, the library, the
  collection, the tally and the homework list, settings and language, characters,
  coordinates, tools, upgrades,
  spatial hashes, draw layering, damage numbers, determinism, and an
  **Extending** section that lists exactly which tables a new enemy / tool /
  upgrade / weapon / character / subject / course / perk / language needs a row
  in.
- **`README.md`** — the design document, and an unusually complete one. It
  explains *why* every tool, number and layout decision is what it is.

Read the relevant section of both before changing behaviour, and update them
when behaviour changes. A number that encodes a design decision (the pushpin's
10 damage sitting one short of the skull's 12hp) is argued for in `README.md` —
do not nudge it casually.

## Running

```sh
love .                  # from the project root
```

LÖVE 11.x (`t.version = "11.4"` in `conf.lua`) — so LuaJIT / Lua 5.1 semantics:
`unpack` is a global, not `table.unpack`.

No build step, no test suite, no dependency manifest. The closest thing to a
lint pass is a syntax check, worth running after any broad edit:

```sh
for f in main.lua conf.lua src/*.lua; do luac -p "$f" || echo "FAILED $f"; done
```

Page skins are baked from `art/<subject>/*.txt` with `lua art/bake.lua`.
A distributable is the tree zipped with `main.lua` at the root:

```sh
zip -r game.love main.lua conf.lua src art
```

`au.love` in the root is a previously built archive, not a source file.

The Android APK is built by `.github/workflows/android.yml` (any push that is not
docs or `art/`, `v*` tags as Releases, or by hand), in the same shape as
auto-chest's and demomino's: it embeds `main.lua conf.lua src` in love-android
pinned to a commit on its LÖVE 12 line, applies `love-android-audio.patch` to
that engine, and bakes the launcher icon out of `Sprites.COOLS` with
`android/icon.py` (ink on white, whole-number scales only). Unlike those two it
pins no orientation: `fullUser` in the manifest, and the settings page's SCREEN
row (`src/orient.lua`) decides at run time. The artifact is `Survive School.apk`.
Signing uses the `ANDROID_KEYSTORE_BASE64` / `ANDROID_KEYSTORE_PASSWORD` /
`ANDROID_KEY_ALIAS` / `ANDROID_KEY_PASSWORD` secrets when set, and a throwaway
key per run otherwise.

`F11` / `alt+enter` toggles fullscreen, `Esc` quits. Save state lives in
`~/Library/Application Support/LOVE/notebook-survivors/`: `options.txt`,
`bookmark.txt`, `records.txt`, `tally.txt`, `course.txt`, and one `.txt` per drawn design (`hero-*.txt`,
`sword.txt`, `star.txt`, `rocket.txt`, `sun.txt`, `cools.txt`, `skate.txt`,
`bomb.txt`, `lightning.txt`, `bird.txt`, `shot.txt`) — one line per row of the
design. Delete one to be handed the starting drawing again.

## Non-negotiable rendering rules

These four run through every module. Breaking any one is visible on screen
immediately. `DESIGNDOC.md` has the long form.

**Eight colours, no alpha.** `src/palette.lua` is the whole palette. Never pass
an alpha argument to `love.graphics.setColor`, never write literal RGB. Fades
step down a colour ramp while individual stamps drop out at random (dither) —
alpha would blend paper and ink into a ninth colour and break the overprint
lookup.

**Whole pixels only, never at an angle.** Everything renders into a low-res
canvas scaled by a whole number (`main.lua`). `love.graphics.circle` and
`love.graphics.line` are never used — use `pixelart.line`, `pixelart.band`,
`pixelart.circleOutline`, `pixelart.circleFill`, or
`rectangle("fill", x, y, 1, 1)`. No call passes a rotation to
`love.graphics.draw`; a sprite that needs a heading is baked to one of eight by
`pixelart.turn` up front. That constraint is about *sprites* only — anything
plotted by `pixelart` (the laser beam) goes down at any angle at all. A *whole*
scale is fine and is not the same thing: `Sprite:draw`'s optional `s` is how a
blown-up enemy is twice the size (`src/spawner.lua`), and an integer scale at a
floored position with nearest filtering lands on exactly the same grid. The rule
is about angles.

**Art is ASCII.** Sprites are tables of equal-length strings in
`src/sprites.lua`, one character per palette key (`.` = transparent), compiled
by `pixelart.newSprite`. Off-palette art asserts at load. Round tips past ~9px
across come from `pixelart.newDisc(radius)`.

**The canvas is not 320x180.** Zoom is picked off the *short* window edge and
the canvas is made as many game pixels as it takes to cover it — 320x180 on
16:9, 400x180 on a 20:9 phone. Nothing is letterboxed or stretched; a wider
screen shows more page. Anything positioned against a screen edge reads
`Game.vw/vh` and the safe insets (`game.inset.l/t/r/b`), never a hard-coded 320
or 180.

**Anything the player reads goes through `I18n.t`.** Write it in English where
it belongs (the upgrade's row, the tool's name, the screen's own constant), add
one line to the `ES` table in `src/i18n.lua` keyed by that English, and make
sure whatever measures it for layout measures the translation and not the key.

## Where things live

- **Entry and frame:** `main.lua` (fit, canvas, resize, safe insets),
  `conf.lua`, `src/game.lua` (the state machine and the draw order),
  `src/camera.lua`, `src/input.lua`, `src/util.lua`. `src/dev.lua` is the one
  module here that does not ship: the settings page's `UNLOCKS` row, read by
  `Collection.has`, `Collection.lessonOpen` and `Characters.owns` and by nothing
  else, so taking it out at launch is three calls and a file.
- **Rendering:** `src/palette.lua`, `src/overprint.lua`, `src/pixelart.lua`,
  `src/sprites.lua`, `src/font.lua`, `src/background.lua`, `src/particles.lua`.
- **Screens:** `menu`, `settings`, `timetable`, `studio`, `library`, `canteen`,
  `homework` (the challenge list, read off `challenges`), `blank` (the page with
  nothing on it, which nothing instances today), `pause`, `levelup`, `win`,
  `over`, `retake`, `hud`, `scribble` (hand-drawn boxes), `spread` (the book the
  library, the canteen and the homework page are read in: two leaves, a crease,
  and a leaf you turn with your finger), `bookmark`, `records`, `tally`,
  `options`, `i18n`.
- **Run content:** `player`, `enemy`, `spawner`, `subjects`, `course` (how hard
  the book is: the four rungs of the difficulty ladder and what each multiplies),
  `characters`, `tools`, `upgrades`, `loadout`, `perks`, `purse`, `refund`,
  `collection` (what the book has opened, off `records`), `challenges` (what it
  asks you to go and do, off `tally`), `design`.
- **Weapons and tools:** `shot`, `sword`, `star`/`orbital`, `flock`, `rocket`,
  `sun`, `cools`, `bomb`, `skate`, `spiral`, `storm`, `beam`, `scissors`,
  `ruler`, `compass`, `pin`, `staple`, `puddle`, `arena`.
- **World bookkeeping:** `stroke`, `mark`, `walls`, `bullet`, `gem`, `pickup`,
  `damage`, `sfx` (+ `src/sfx/`, `src/music/`).

`Game:buildGrid` is a 12px hash rebuilt every frame (enemy separation, bullet
hits); `src/walls.lua` is a 16px hash of pen-line segments rebuilt only when
dirty. Hit small things at a point through `Game:eachNear`; anything covering
more ground than nine 12px cells asks `Game:eachWithin`, on a tick rather than
every frame.

## Style

Comments here explain *why* a thing is the way it is — the trade-off, the bug it
prevents, the feel it produces — rather than restating the code, and modules
open with a paragraph framing what they are. Match that when editing; a change
that invalidates one of those paragraphs should update it.

Prefer adding a row to an existing table over adding a branch: nearly every
system in this game is driven off a list (`Tools.list`, `Upgrades.list`,
`Characters.list`, `Subjects.list`, `Course.list`, `Perks.list`,
`Collection.gates`, `Challenges.sections`, `Design.by`, `I18n.langs`), measured off that list, and costs
its screens nothing when it grows -- a section added to any of the three back
pages grows its book's page count by being in the list and is told nothing. `DESIGNDOC.md`'s **Extending** section says which table
each kind of new thing belongs in, and what else it owes.
