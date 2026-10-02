# DESIGNDOC.md

The architecture reference for this repository: how every subsystem is put
together and which table a new thing belongs in. `CLAUDE.md` is the short
operational brief that points here; `README.md` is the design document that
explains *why* each number and layout decision is what it is.

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
lives in `~/Library/Application Support/LOVE/notebook-survivors/` —
`hero-shootman.txt`, `hero-swordsman.txt`, `hero-starman.txt` and
`hero-skateman.txt` (one hero per character, built off `Characters.list`),
`sword.txt`, `shot.txt`, `star.txt`, `bird.txt`, `rocket.txt`, `sun.txt`,
`cools.txt`, `bomb.txt`, `skate.txt` and `lightning.txt`, one line per row of the design (delete one to get the drawing you are
handed to draw over back). A hero board with no file of its own yet falls back
down a list (`legacy` in `src/design.lua`): the file the character was kept under
before it was renamed (`was` on the row), and then the old single `hero.txt`, so
neither the split nor a rename ever takes a drawing away. `character.txt` beside them is
which hero was last picked and `roster.txt` is which heroes the book has bought
and how long the longest run as each of them lasted (see **Characters**),
`records.txt` is what each
page remembers -- and, through it, which of the catalogue the book has opened at
all (see **The collection**) -- `tally.txt` is the same register the other way
round, what every run so far *did* added up rather than the best of it (see
**The tally**), `purse.txt` is what every run so far earned (see
**The purse**),
`perks.txt` is what has been bought out of it (see **What the purse buys**),
`course.txt` is how far up the difficulty ladder the book has enrolled and which
rung the next run is sat at (see **Courses**), `options.txt` is the language, the two volumes, the stick's
corner, how much of a hit the page says out loud and whether a new drawing is
asked for (see **Settings and language**), and `bookmark.txt` is
where the last run got to (see **Game states**). That last one is the only file
here about a *run*, and it is deliberately not a save: twenty-odd numbers, no
page. The music the second of those turns is one streamed,
looping file, `src/music/ost.mp3`, started once in `Game:load` and never stopped:
it is what the book sounds like while it is open rather than a run's, a screen's or
a lesson's, so the settings bar is the only thing that touches it again.

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
same reason — but it snaps against *what it is following* rather than against
the world, and that is not a detail. Everything is drawn at
`floor(world) - left`, so a `left` of `floor(Camera.x - w/2)` floors the same
quantity twice independently and leaves the hero's own fraction of a pixel in
the result: he flips between two pixels for as long as he walks, thirteen times
a second on the diagonal and on both axes at once, which reads as a smear. Take
the *lag* to a whole number and his fraction is subtracted from itself. Whatever
`bounds()` follows must therefore be the thing the player is looking at.

Nothing is ever drawn at an angle: no call passes a rotation to
`love.graphics.draw`, because a sprite turned at draw time samples off the grid.
The rocket points where it is going anyway, and the way it is allowed to is
`pixelart.turn` — the turn is baked into a new grid of characters up front and
what reaches the screen is an ordinary sprite at an ordinary integer position.

That constraint is about *sprites*, and only sprites. Anything plotted by
`pixelart` goes down at any angle at all, which is why the laser beam is aimed
freely where the rocket flies one of eight: it has no sprite to turn.

Scaling is not turning. `Sprite:draw` takes an optional whole-number `s` — the
flip has always been a negative one — and a standout arrival (**Champions** and
**Blow-ups**, below) is drawn at 2 or 3. An integer scale, a floored position and
nearest filtering put every pixel of the result on the same grid as everything
else, which is what the rule actually asks for; sampling off the grid is what a rotation does and what a
fractional scale would do.

**Lettering is counted in letters.** The 3x5 face carries an N-tilde and the two
inverted marks for the Spanish (see **Settings and language**), and in UTF-8 those
are two bytes each. So `Font.width`, `Font.print`, `Font.count`, `Font.at` and
`Scribble.printBig` all walk *glyphs*; nothing that will be drawn is ever measured
or indexed with `#text`. Getting this wrong does not misplace a word, it misplaces
whatever block was measured off it.

**Art is ASCII.** All sprites are tables of equal-length strings in
`src/sprites.lua`, one character per palette key (`.` = transparent), compiled by
`pixelart.newSprite`. Off-palette art asserts at load. Round brush tips past ~9px
across come from `pixelart.newDisc(radius)` instead of hand-authored ASCII, and
`pixelart.turn(rows, eighths)` turns a grid to one of eight headings — exactly on
the quarters, resampled on the diagonals. The grid a sprite was compiled from is
kept on it (`Sprite.rows`), so the same drawing can be compiled again in other
colours: `pixelart.twoTone(rows, fill, rest)` returns it in two, whatever it is
mostly made of inside its own outline in `fill` and every other mark in `rest`,
which is how an enraged arrival is drawn (**Fury**).

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
- **The page layer is not only the background.** There are four surfaces, not
  three (`Palette.surfaces`), and the fourth is `graphite`: the half of the page
  the scissors' last level lifts off, laid in between `Overprint.beginPage()` and
  `beginInk()` and so over the ruling rather than under it. What goes down there
  is not a colour but a *second bake of the same page* — the ruling exactly where
  it was printed, graphite where the paper between it used to be (`Background.torn`,
  `Scissors:drawSever`). The scissors take the paper and not the printing on it,
  so a rule crossing the offcut still crosses it; what says the half is gone is
  the white going out of it. It is still the page layer and not the ink layer for
  a reason of its own: a grey half laid in with the marks would be paired with
  the page under it, coming out as some other colour wherever it crossed a rule,
  and ink laid on top of it afterwards would go on stacking against the paper it
  had covered. Both the shader and the LUT are sized off
  `Palette.marks`/`Palette.surfaces`, so a fifth surface is a column in
  `Palette.overprint` and nothing else — but a *ruling* still only gets the first
  three (see `src/subjects.lua`).
- **Characters are not overprinted.** A mark is printed *into* the page and takes
  the page's colour where it crosses a rule; a monster or the hero is *standing on*
  the page and does not. A ruled line coming through a blob's body read as tracing
  paper, and on a printed skin (`src/subjects.lua`) the horde took the page's
  pattern with it. So every character stamps its own silhouette into the page
  layer in `paper` first — `Overprint.beginSolid()` reaches back to the page canvas
  from the middle of the ink pass and `Overprint.endSolid()` hands the ink layer
  back, with the transform untouched so the caller stamps at the coordinates it is
  already drawing at. The blank column of `Palette.overprint` is the identity, so
  the body then comes out in exactly the colours it was drawn in and the shader
  never has to know that characters exist. `Enemy:drawSolid` and
  `Player:drawSolid` are the silhouettes (body plus its outline, since an outline
  is part of the shape — but never the shadow or the skateboard, which really are
  on the paper), and the three callers are `Game:draw` (one pair of canvas
  switches round the whole crowd, so it is a loop of its own before the depth
  sort), `Menu:drawChase` and `Timetable:drawHero`. The stamp must cover exactly
  the pixels the ink is about to cover and no more, or the surplus prints as a
  hole in the ruling — which is why the hero's invulnerability blink
  (`Player:blinked`) and the wad's wind-up flash (`Enemy:outlineColour`) are each
  answered once and read twice.
- The HUD is drawn after `Overprint.finish()`, so it sits above the page rather
  than on it and is not overprinted. So is the timetable's column of tabs, which
  is what keeps a tab reading as card laid on the page rather than as a
  transparency the ruling shows through. So are the damage numbers
  (`src/damage.lua`), and for a stronger reason than layering: a red number
  crossing a ruled line would come out slate and a blush one would come out red,
  so a readout run through the pass would mean one thing on blank paper and
  another on squared. They are the one thing in the game drawn *inside* the
  camera transform and *outside* the pass, since a number belongs to the enemy
  it came off and has to scroll with it.

### Game states

`src/game.lua` is one table with `self.state` ∈ `menu`, `settings`, `timetable`,
`studio`, `library`, `homework`, `canteen`, `playing`, `paused`, `levelup`,
`won`, `dead`, `retaking`. `Game:update` and
`Game:draw` both branch on it first. `menu`, `settings`, `timetable`, `studio`,
`library`, `paused`, `levelup`, `won`, `dead` and `retaking` each delegate to a
module
(`menu.lua`, `settings.lua`, `timetable.lua`, `studio.lua`, `library.lua`,
`pause.lua`, `levelup.lua`, `win.lua`, `over.lua`, `retake.lua`) that returns an
answer which `Game` acts on. `homework` and
`canteen` are two small pages held in `Game.pages`, keyed by the state itself,
which is what makes them one branch apiece rather than two of everything: they
answer the same three things (`enter`, an `update` that returns `"back"`, `draw`)
and `Game:toPage(key)` is the one door. `canteen` is `canteen.lua` and is the one
of the two that has grown a counter -- it reads the purse and spends it
(`src/perks.lua`); `homework` is `homework.lua`, the challenge list read off
`src/challenges.lua`. Both grew out of `blank.lua` -- a page with nothing on it and a heading
passed in -- and nothing instances it today; it stays for the next tab that opens
onto nothing.

**The two ways a run ends are one card twice.** `won` is `src/win.lua` (`END` /
`ENDLESS`) and `dead` is `src/over.lua` (`RETRY` / `QUIT`), and the second is the
first with the other question on it: paper laid on the frozen page, two
`Scribble` boxes, arm-then-lift, `1` and `2` on the keyboard, and everything
outside the card still drawable. `Game:openDeath` is the one door into it and is
deliberately **not** `Game:holdRun` -- holding a run ends the open stroke through
`Game:endStroke`, which speaks, and the rubber's release pop over the death burst
would say the crumbs had been swept rather than that you had been killed. So the
rub's loop is stopped by hand and silently, the stroke is left where it was
(nothing updates it again), and the one thing actually taken is the thumb stick,
since a box under its own quadrant is a box whose scribble is swallowed on the
way in. `RETRY` is `Game:reset` on the same lesson and hero; `QUIT` is
`Game:toMenu`, and the hero is not drawn on the page it leaves behind because
`Game:draw` hangs that on `player.hp` rather than on which screen is up.

Both cards also print what the run **earned** under the score -- the coin, a `+`
and a figure, in ink, drawn by `Purse.draw` (see **The purse**). It is banked
already on the death card and not yet on the win card, which is what `END` is for.

**And there is a third card, which is the death card not happening.** `retaking`
is `src/retake.lua`, put up by `Game:openRetake` in place of `Game:openDeath` when
the health runs out and the run still has a RETAKE charge (see **What the purse
buys**). It is the same object again -- paper over the frozen page, the heading over
the big word -- with two things taken out of it and nothing put in: **it asks
nothing**, and **nothing reaches it**. No boxes, no pen, no marks, no keys, and
`Input.onPointerDown` swallows the press outright rather than passing it to a pen,
since a stroke begun on a card that lifts a second later is the line across the page
`Game:holdRun` exists to prevent. All it can answer with is `"done"`, on a clock
(`HOLD`), and `Game:resumeRun` is what that means -- the same door a draft and the
drawing board come back through, so a level banked on the frame you got back up is
still a level you get to spend.

Three things about it are decisions rather than details. It **is** `Game:holdRun`,
where the death card deliberately is not: every bit of the run is about to be given
back, so the open stroke has to be closed and the paid-for aims landed exactly as
they are for a level landing. Its burst is **blue** where the death burst is red,
which is the palette's own rule doing the work -- red is the other side and getting
up is yours. And its lettering is the **death card's** and not the win card's: blue
lettering means the eye is down and is the only blue lettering in the game, so this
card's title is ink and still, and the whole of its colour is spent on the count
under it, which goes red on the last charge.

Both of the two cards a run actually ends on carry the **mark** (`src/mark.lua`): a
letter from `F` to `A+` in red,
which is the one readout in the game that is not a number. Thirteen grades, and
today the run's length picks one linearly against `Spawner.BOSS_AT` -- a win is
`A+` outright, since there the grade is awarded rather than measured. That sum is
meant to grow more terms and `Mark.forRun` is the only door to it, so neither card
knows what it reads. The timetable is the third reader and asks the same door about
a *record* rather than a run -- `Mark.forRun(rec.time, rec.bosses >= 1)`, the best
mark a lesson has come back with -- which is why no grade is ever filed: the
register already keeps everything the sum reads, so a rung added to the ladder
re-marks every page in the book at once. It is the one reader that does not use
`Mark.draw`: a stat row is 3x5 lettering like the four rows above it and only the
colour is the mark's. It is also the one place `Font.bold` is drawn without its
ring: the outline is for one-pixel figures over a busy page, and at three times
that size on paper it only costs the letter its edge (see the module header).

The way into a run is `menu` → `timetable` → `playing`. `studio`, `library` and
the two blank pages are all loops off the side of the timetable rather than steps
on the way —
`CUSTOM` opens the board and `OK!` hands the screen back, the `LIBRARY` tab opens
the catalogue and the corner button hands it back — so a run starts with the hero
you already have, the board is where you go when you want a different one, and
the library is where you go to find out what the draft can even offer. The timetable's
place in that order is still load-bearing: it picks the page the run is played on,
the tool it opens holding (see **Subjects**) *and* the course it is sat at (see
**Courses**), and the ruling is what a drawing is read against, so the board is
only ever opened once a lesson is picked, and it is drawn on that lesson's page. A run is built by `Game:reset()`
and held, not torn down, by pausing or by levelling up — both go through
`Game:holdRun`/`Game:releaseRun`,
which close any open stroke, land any paid-for aim, and take the thumb stick away
so the whole page is drawable.

**`Game:reset()` is the only thing that ever replaces a run.** Quitting from the
pause card banks the record and goes to `menu`, and nothing else: the run is still
sitting behind the title screen, still held the way the pause card held it, on the
page the title is drawn on. That is what the title's third box is built on
(`CONTINUE`, `src/menu.lua`), and it is why the box has **two** things behind it —
`Game:canContinue` is the one question and `Game:continueRun` is the one door, but
what is on the other side of it is either of:

- **The run in memory** (`Game:resumeHeldRun`) — `Game:togglePause`'s other half,
  `state = "playing"` plus `releaseRun`, nothing rebuilt. It hands back the page,
  the horde, the ink and the marks, because none of them ever went anywhere.
- **A bookmark** (`Game:openBookmark`, `src/bookmark.lua`) — what the last launch
  left on disk, once the program has closed and the run in memory is gone. Twenty
  numbers: the lesson, the character, the course, the level on each line, the
  clock, the ladder, the health, the ink and the tool slot. It comes back **on
  fresh paper**.

The live one always wins, and every check goes in that order. A run's *build* is
cheap to keep because a level is written as a function of what it changes rather
than as a difference from the level before it (see **Upgrades**), so `stats` is a
pure function of the levels reached and `Loadout:restore` is a list of ids plus a
`rebuild`. A run's *page* is not: the horde, every stroke and its stamps, the pins
that stay for good, the puddles, the blades mid-cut, the half the scissors took.
Dropping it is the shape of the feature rather than a corner cut, and
`src/bookmark.lua`'s header is where that is argued out.

`Game.resumable` is what both halves hang off, and it means **this run is worth
keeping**: true from `Game:reset`, false in the three places a run *ends* — dying,
`END` on the win card, and the scaffolding reset in `Game:load` that nobody
played. Walking out through the pause card is deliberately not one of them. It
also decides whether closing the program leaves a bookmark (`Game:closing`, called
from `love.quit`), which **writes and never clears**: the file is cleared by those
same three endings plus `GO!` starting the next run, so closing the book without
having played cannot throw away the bookmark that was there when it was opened.
`Menu:enter` reads the answer once and is told nothing about which kind it is.

One thing a bookmark may not keep is the boss phase, and that is a fix rather than
an omission: `Spawner:updateBoss` only leaves the phase when the eye dies, so a
spawner restored mid-fight with no eye on the page would drip escort for ever. A
bookmark is always in the horde phase, and `cycleStart` is what makes that come
out right — if the clock says the ten minutes are up, the eye is sent again on the
first frame.

`studio` is entered from two places and `Game.studioBack` is what says which:
`"timetable"` for the hero, asked for by `CUSTOM` and handed straight back to the
lesson it was opened from, and `"held"` for a weapon a draft has just given you,
where the run underneath stays frozen exactly as `Game:openDraft` left it and
`Game:resumeRun` lets it go afterwards. Nothing of the run is drawn while the
board is up — a board is a whole page, not a card laid on one.

`settings` is the third loop of that shape and it hangs off the *title screen*
rather than the timetable: the top-left corner button opens it and the corner
button hands the screen back. It is reached from there because what it holds --
how loud the game is and what language it is in -- is true of the program rather
than of a run, so it belongs before the book is opened rather than inside it. It
answers with `"back"` and nothing else, and coming back lands on the title with
its lettering already written on (`Game:toMenu(true)`), since you did not
re-open the book. See **Settings and language**.

Three of its rows reach out of this file. `Input.stickSide` moves the thumb
stick's corner and the two margin columns with it (see **Tools** and
`Hud.toolSide`); `Damage.show` is what `Damage:add` refuses on, cut off the tier
table so that "big" follows the tiers rather than a number of points; and
`Design.ask` is what says
whether a board the game opens *for* you opens at all -- the weapon a draft has
just sold (`Game:takeUpgrade`) and the arm a character carries (the `carried`
clause in the `studio` branch). `CUSTOM` is deliberately not guarded by it: a
board you pressed a button to get is not the game interrupting you, and the rule
worth keeping is that the flag only ever cancels a board nobody asked for.

`library` is the simplest state in the game apart from the two beside it, and
deliberately so: it is entered
from one place, it hands nothing over, and the only thing it can answer with is
`"back"`. It reads no run and writes nothing — the catalogue is the same table for
every run the program plays — so `Game:toLibrary` takes no argument and coming
back is `Game:toTimetable()` landing on the lesson `setSubject` was already given.
See **The library**.

`homework` and `canteen` started as the same shape with the catalogue taken out: a
heading, a line, and the corner button. `Game.pages` holds one instance per state
and `Game:toPage(key)` is the one door, so each of them costs `Game` one branch in
`update`, `draw`, `keypressed` and `Input.onPointerDown` rather than two of each --
and a new page off that column costs a row in the table and nothing else.

`src/blank.lua` is the shape both of them left: a page with **nothing on it**, the
heading an argument and the line under it saying there is nothing there yet. It
opens a page rather than nothing because a tab that opens nothing reads as broken,
and nothing instances it today -- it is kept for the next tab that opens onto
nothing, which is what its own header asks for.

`homework` is `src/homework.lua`, the second of the two to move out (see
**Homework**): four sections of challenges, a ladder of pips per row and how far
along the rung still standing is in the right-hand column.

`canteen` is `src/canteen.lua`, which is what that module's other instance became
the day it had something to say -- the rule being that a page with nothing on it is
`blank.lua` with a heading and a page with anything of its own is its own module.
What it has is the purse (see **The purse**) and the things it sells --
the perks (see **What the purse buys**) and three of the four heroes (see
**Characters**) -- and the split it is laid out along is that
**the purse is furniture and not content**: the readout hangs at 1:1 off the
top right of the page -- the corner button's own margin mirrored to the other end
of the same top edge, and level with it -- while the body of the page is the
counter, read down the middle. That split is why buying does not move
the readout and the readout does not move for a purse that has reached a hundred:
the heading's clearance is the library's guard doubled (it steps below *both*
corners) and the room the readout keeps is struck off four digits rather than off
the figure showing.

**The counter has four sections**, stepped with the library's own footer (`<` the
section `>`, pinned to the foot of the page): `PERKS` is `Perks.list`, `HEROES` is
every row of `Characters.list` with a `price` on it, `COURSES` is the one row of
`src/course.lua`, and `REFUND` sells nothing at all. Separate sections because the
one line under the counter saying what a level *is* -- a use a run spends, a hero
you have for good, or a harder book -- stops being true halfway down a merged list,
and a page that printed EVERY LEVEL IS ONE USE A RUN over a row selling the starman
would be the counter lying about its own goods. It is also what makes the page fit:
a box is 20px deep, so seven rows in one column runs off the bottom of a 180px
page. A row is a name, a blurb, an icon and a `shop` -- `Perks`, `Characters`,
`Course` or `Refund`, which answer the same five questions about a key (`level`,
`levels`, `priceOf`, `canBuy`, `buy`) -- so one function draws a reroll, a hero and
a doctorate, and nothing on the counter knows which kind it is. One `Scribble.newChoice` per section, since a box belongs to the row it
is at the end of.

The body is the settings page's shape rather than the library's -- one fixed block,
**centred** -- and it can be because the block is reserved at the fullest section's
row count in both languages and in every purse: nothing on the counter changes
height, which is the one thing the library never has. Every column is measured
across *every* section for the same reason the library measures across all three
shelves -- nothing may move as the footer is stepped either. It degrades one way and only one, the blurbs going first, so
a phone held upright keeps the whole transaction and loses the sentence about it.

**Buying is the one thing in the margins of this book that is answered rather than
pressed**, and it is the one exception to the rule the tabs, the library and the
settings page are all drawn along. A press is for choosing what to look at and for
setting a quantity; a purchase is neither -- it cannot be taken back, and a
`Scribble` box is how this game asks about one. So each row ends in a box, it warms
slate → blue → red, the coins come out when the pen lifts, and the box is *wiped*
afterwards (`Choice:clear`, the studio's RESET) so the next level can be bought in
it. A row with nothing left to sell, or nothing in the purse to buy it with, has no
box drawn at all, is not hit-tested, and ink that lands there is ink on the page.
The one line under the counter says which of those three states it is in rather
than printing an instruction whatever is true.

It reads the purse and the perks and hands nothing back, so like the library it
takes no argument -- what it changes belongs to the *book* rather than to a run.
See the README's **Homework and the canteen**.

One board may hand straight on to another, and exactly one does: the hero's, to
whatever the picked character carries (`design` on the row in
`src/characters.lua` — the swordsman's sword, the shootman's shot, the starman's
star, the skateman's board). `Studio:update`
returns `"done"` **and the design that was on the board**, which is what `Game`
answers that with: the board cannot be remembered from the way in, because the
roster's arrows swap it for another hero's while the screen is up. The follow-on is
only taken from the `"timetable"` route, since a board opened mid-run is a weapon
the draft has just sold and the run underneath is waiting -- and only while
`Design.ask` is set, the arm being a board the game opens for you rather than one
you asked for.

All of those screens ask their question by making you draw the answer, and
that shared mechanic lives in `src/scribble.lua`: **a box you scribble in**
(`Scribble.newChoice`), coverage counted on a 2px grid inside the border. The
draft's three answers are the same boxes, one placed under each card
(`Choice:place`), and a box is now the *only* way to answer it: tapping the card
itself used to fill its box the way the keyboard shortcut does
(`Choice:autoFill`), and that route is flagged off (`TAP_CARDS` in
`src/levelup.lua`) rather than deleted. A draft interrupts a fight, so a finger
already mid-stroke could spend a level on a target a third of the page across --
see **The draft arrives and leaves**.

A box is *armed* while drawn in and only *answers* on release, warms its
border slate → blue → red through `Scribble.boxColor`, has a keyboard route
that draws the answer rather than jumping past it, and ink that misses
everything is just ink that fades off the page.

A screen that asks a question owns almost nothing of its own. It holds a
`Scribble.newChoice` (the boxes), a `Scribble.newMarks` (ink that missed) and a
`Scribble.newPen` (the pointer, turned into a line), and each frame hands the pen
`dt, down, x, y` plus a `mark` callback and an optional press-edge callback. What
is latched on that press edge is latched for the whole stroke — the studio decides
there whether a stroke is drawing on the board or answering a box. Border colour
is `Scribble.boxColor(box, chosen, confirmT)`; don't reimplement it per screen.

**The pen is also what these screens sound like.** A page you can draw on has to
sound drawn on, so `Pen:swish` fires the pencil's own brushes (`src/sfx.lua`) by
the same three rules a run does (`Game:strokeSwish`): one swish at a time, picked
off how fast the nib has actually been moving, and cut on the lift. That is what
`dt` is for and the only thing it is for. And it is fired off the *ink* rather
than off the pointer, which is why `mark` answers: `false` from it means the
stamp was swallowed — by a tab, a margin button, a bar being dragged — and a
swallowed stamp was never a line, so it must not sound like one. A screen that
grows a new piece of furniture returns `false` for it or the page will swish at
somebody dragging a volume. The one scribble no finger lays — the keyboard's
answer and a tapped card's, `Choice:autoFill` — is a stroke of a length known in
advance, so it takes the compass's `Sfx.brushFor` instead.

### Subjects

`src/subjects.lua` is the seven pages of the book and `src/timetable.lua` is the
screen that picks one, in the same split as the upgrade catalogue and the draft.
A subject is a **page** — how it is ruled — and a **tool** — the one thing the run
opens holding.

The page is baked at load, one tile per subject, all of them kept
(`Background.setSubject` picks which is the page; `Background.drawAs` can draw
any of them, which is how the timetable stands the whole screen on whichever
lesson is being answered). A ruling is a pure function of position inside its
tile, and two rules on it both show up as a seam down the page: the tile's `w`/`h`
have to be whole multiples of whatever the ruling repeats on, and `at` may only
answer with one of `Palette.surfaces`.

The page is not decoration, because of the overprint pass: squared paper darkens
a stroke about twice as often as ruled paper does, the unruled page has next to
nothing to darken against, staves do it in bands, and the spreadsheet's filled
header bands do it across a block instead of at a crossing. Nothing was written
to make that true.

Every page also carries something **vertical** a page width apart — the ruled and
paired pages' blush margin, the staves' bar lines, the grid's own doubled rule,
the calendar's week line, the spreadsheet's filled header column, and the punch
holes on the unruled page. Horizontal ruling cannot tell you that you are
walking, since every line coming up the screen looks like the one before it; a
mark that goes past once a page can. Anything added to a ruling wants to keep
that.

**The list is the term.** `Subjects.list` used to be an order to read the seven
rows in; it is now the one thing about that file another module is written
against. A lesson is opened by the lesson above it in the list, a minute more
being asked at each rung (`Collection.rungs` — see **The collection**), so moving
a row moves the ladder and the tabs down the edge of the timetable read in the
same order because they are the same list. `Subjects.default` is the first row and
has to be: it is the page the title screen stands on, and the one lesson a fresh
book may sit.

**The crowd is the same at every lesson.** Every subject spawns from the same
table with the same unlock times and the same health curve, and no subject turns
either of the two dials that would change that — `crowd` (multiplies a kind's
weight) and `clock` (scales the difficulty clock). Both are still read,
defensively, by `Spawner.new`/`Spawner`, which takes the subject once when the run
is built. Leaving them at rest is the design, not an omission: don't turn one to
make a lesson read better.

**But the shape it arrives in is the page's own.** A third dial, `drills`, is
turned by all seven subjects: `{ every = <seconds>, of = { <drill> = <weight> } }`,
read by `Spawner:beginDrill` and `Spawner:pickDrill` — see **Drills and surges**.
It is a weaker dial on purpose, and the rule that makes it weak is worth keeping:
**a page may shape an arrival, never price one.** A drill spawns through
`Spawner:dropAt`, so what walks on is that minute's horde with that minute's
health, unlocks and champions, standing somewhere a random bearing would not have
put it. A subject with no `drills` gets `DRILL_MIX` (an even hand) at
`DRILL_EVERY`, so a new row works before it has an opinion.

**But it may not look the same.** A lesson may reinterpret the crowd --
`Sprites.enemySkins` in `src/sprites.lua`, keyed by subject, and on the music page
the blob is a quarter note, the bat two beamed quavers, the skull a whole note and
the two eyes the two clefs. It is a **skin and nothing else**, which is what keeps
it on the right side of the paragraph above: every number the crowd is made of
stays on the row in `Enemy.types`, so a blob on the music page is the same 4hp
walking at the same 20px/s, and a build learned on one page reads on every other.
Only the drawing changes. Four things hold it together:

- **The grid may be bigger, and only bigger.** A skin may be drawn up to
  `SKIN_ROOM` (4) over the enemy it replaces in each direction, and the extra is
  *headroom* rather than a resize: the hit radius is a number on the row in
  `Enemy.types` and does not move, so what the room buys is the part of a
  reinterpretation the enemy has no space for — a quarter note's stem, a pair of
  ears, a hat. What makes it free is that the origin is pinned to the sprite
  being replaced: the rows go on the top and the columns split between the sides,
  `oy` moves with them, and `h - oy` — which is what the shadow is struck off —
  comes out unchanged, so the drawing grows upward out of the same feet. Two
  guards, both asserted at load the way off-palette art is: never smaller or
  further over than the room allows, and **the extra width must be even**, since
  `floor` puts an odd column on the right and nothing in a grid of pixels says
  which side it was drawn on. So a skin keeps its enemy's width parity — the blob
  goes 8 to 10 to 12, the bat 11 to 13 to 15.
- **The shadow is struck off `h - oy`, not off half the height.** That is
  `Sprites.shadow`'s own expression and now the one rule in the game for where a
  thing stands. Half the height was the same number for every enemy authored at
  its own centre and stops being one the moment a skin has headroom; it was also
  putting the shadow one pixel *inside* the odd-height enemies, so unifying the
  two moved the bat, both eyes and the boss down a pixel onto their own feet.
- **`Sprites.enemy(name)` is the one door and `Sprites.setSkin` the one latch**,
  called from `Game:setSubject` beside `Background.setSubject` and for the same
  reason: the page and the crowd standing on it are one choice. It falls through
  to `Sprites.enemies` a *name* at a time rather than a page at a time, so a
  lesson may reinterpret two of the ten and leave the rest -- a page half drawn
  is a page you can look at, and a page that had to be finished before any of it
  counted is a page nobody starts.
- **The art is authored in `art/<subject>/*.txt` and baked in by
  `lua art/bake.lua`**, which is the one direction it travels. `art/check.lua`
  validates a grid and `art/preview.py` renders it onto that subject's own ruling
  through the overprint table, since a re-skin is judged against the page it will
  be read on. Nothing reads `art/` at runtime -- a distributable is still
  `main.lua`, `conf.lua` and `src` -- and `art/vanilla/` is the unskinned crowd
  kept there to draw against rather than to be baked over itself.

A skin used to be authored against the overprint pass — paper (`w`) wiped the
ruling and sky (`c`) came out blue wherever it crossed a rule — and that is no
longer the constraint it was: a character blanks the page out under itself, so a
drawing keeps the colours it was drawn in whatever page it is read on. What is
left is the plainer question of what it stands *beside*. Sky is the colour a rule
is drawn in, so a sky-heavy skin on a ruled page reads as a gap in the crowd
rather than a thing in it, and paper is the furthest thing from a rule there is.
`art/preview.py` renders the crowd onto its subject's own ruling with the blanking
in it, which is where that is judged.

The tool is a **line id in `src/upgrades.lua`**, not a row in `src/tools.lua`,
because a tool line's first level is its unlock — issuing a tool is taking that
line to level one. `Loadout.new(vw, vh, startTool)` does it before the run is
built, `Game:reset` passes `self.subject.tool`, it costs one of the four tool
slots exactly as a drafted tool does, and the draft goes on offering the line its
remaining levels. Three tools are deliberately unissued: the pen and the gluestick
are what you draw to keep something *out*, so a run cannot open holding one, and the
scissors take half the page away.

**The tool a lesson issues is that lesson's until the lesson is sat out.** The gate
is derived from this row rather than written anywhere (see **The collection**): the
run it is issued to holds it whatever the book has opened, and no other page's draft
can deal it until ten minutes have been sat on this one. Which is the reason the
rule above it -- give a lesson a tool no other lesson hands out -- is finally
enforced rather than asked for: two lessons naming one line is two gates on it, and
that asserts at load.

`src/timetable.lua` is a column of **index tabs** hung off the right edge of the
sheet, one per subject, and everything else read straight down the middle of the
screen, all of it centred on `lay.cx`: the heading, the selected lesson's name
under it at the same scale, its five stat rows, then the hero with his ground, his
walk bounce and what he is carrying, and `CUSTOM` directly under him. He is a row
of that column rather than something standing beside it — he used to be out in the
left margin, which put him a hand span from the column of cards stacked there and
made the sheet read as two layouts — and the order says what the screen is:
what today is, which lesson, how it has gone, who is going, and the door to change
him. `GO!` is alone at the foot of the page, centred, and **nothing is written
above it**: the three hint lines that used to sit there were a paragraph of
instructions naming things that are all on the page to be pressed, and the space
they took is the space the hero now stands in. What a box does is said by the box
warming slate → blue → red as it fills, the same as everywhere else. The two boxes are a `Scribble.newChoice` apiece rather than one two-box
choice — different label scales, different kinds of answer, two places on the page,
and arming one must not disarm the other — and `Timetable:update` returns
`answer, key` so `Game` knows which was taken and about which lesson.

**A shut lesson is a tab you can still turn to.** `Timetable:enter` asks
`Collection.lessonOpen` once per tab and holds the answer on the tab row — nothing
can be earned while this screen is up, so the answer cannot change under it — and
`Timetable:openHere()` is what the rest of the screen reads. A shut tab is
graphite whether or not it is picked (red on this column means *this is where the
book is open*, which is the one thing it may not say about a page that will not
open) and wears its tool as a graphite silhouette through `Hud.drawIcon`, the
library's own locked icon. Picked, the page under the whole screen still turns to
its ruling, the lesson's name is written in graphite without its shadow, and
`Timetable:drawShut` puts the two phrases of `Collection.lessonWhy` where the five
stat rows would be — graphite head, red demand, wrapped to the widest a block
centred on `lay.cx` can be. `GO!` is the one thing conditional on any of it: five
places ask `openHere()` before touching that box — the ink that lands in it
(`mark`), the press that fills it (`press`), the key that answers it
(`keypressed`), the two commits in `update`, and the `drawAct` that draws it — and
the room it had is left empty rather than closed up, because the column may not
move as you step the tabs. `Timetable:enter` also falls back to
`Subjects.default` if it is handed a shut key, which only a hand-edited
`records.txt` can do.

**Two more ways off the screen live in the left margin**, one at each end of it,
and both are *pressed* rather than answered: `Timetable:press` checks them ahead
of the tabs and the boxes, `Timetable:mark` drops any mark that lands on either,
and `update` hands the answer back the moment it is hit rather than after a flash.
`self.pressed` is the one-frame latch that carries which, and both come back as
`answer, self.current`.

- **The corner button**, top-left, a back arrow to the title. It is the run's
  pause button's box in the pause button's corner, and that is enforced rather
  than agreed: `Hud.cornerBox`/`cornerTarget`/`cornerAt`/`cornerBottom`/
  `drawCorner` are the one definition and every screen with one calls them. Keyed
  to `backspace`, and the one answer `Game` does *not* pass to `setSubject`, since
  nothing was decided.
- **The column of tabs**, bottom-left, stacked up out of the corner and read
  down the page as `CANTEEN` into the shop (`src/canteen.lua`), `LIBRARY` into the
  catalogue (`src/library.lua`) and `HOMEWORK` into the challenge list
  (`src/homework.lua`) -- which is the order they stop being about the next run:
  what you spend before one, what the run could be dealt, and what is true of the
  book whatever you play. They are one
  table (`SIDE`, listed bottom-up, so the table reads `homework`, `library`,
  `canteen`) and one rectangle apiece in `self.sides`,
  placed in `Timetable:layout`, hit-tested by `Timetable:sideAt` and drawn by
  `Timetable:drawSide`; each answers with its own `answer` string, which is also
  the state `Game` puts up. Every card is at the same edge and `TAB_GAP` apart --
  the lesson tabs' column mirrored and read from the bottom -- so what says one
  card from the next is the gap and the word on it, as it is over there. `GO!` is
  the one thing in the panel measured against them, off the column's own corner
  (`lay.sideRight`/`lay.sideTop`); everything else is centred down the middle of
  the page.
  Every one of them is a lesson tab mirrored — paper fill, wonky border, drawn
  out past `Overprint.finish()`, running `TAB_OVER` off the safe *left* edge — and
  each is cut to **exactly a lesson tab**, `lay.tabW` across and `lay.tabH` down,
  whatever the page made those. That is the one thing about them to be firm on: a
  tab is a piece of card in the edge of a book, and the whole of what says these
  belong to the same book is that they are the same piece of card. Sized to their
  own words they read as labels stuck on the corner; sized to the corner button
  above them, as more buttons with words in them. Two things they do not copy: they
  are always slate and carry no icon (red on a tab means *this is where the book is
  open* and the book is never open at one of these; a lesson tab's icon is the tool
  that lesson hands you and these hand you nothing), and the word is centred on the
  card both ways rather than flush to an edge, since a lesson has two things to
  place and puts one at each end while these have one. Keyed to `l`, `h` and `k`,
  and advertised nowhere: this screen carries no instructions at all any more.

The first is why `Timetable:panel` is handed `lay.buttonRight`/`lay.underButton`:
the column starts at the top of the page, since it is centred while the button is
out in the margin (the library's rule, and the room it buys is what fits the hero
in), and steps down under the button only where the two would meet. The second is
measured against once, by the foot: the row of boxes is pinned to `bottom` and
moved only where the centred row and the column of cards are the same corner. It is
moved two ways and the page decides which. `canLift` asks whether the column could
still print at `HERO_SCALE` with the foot dropped to `lay.sideTop - EDGE`; where it
can the foot is **lifted** and keeps the middle line, where it cannot the row is
walked sideways to `lay.sideRight + EDGE` as before, and a page with neither width
nor height to give gets the stack, lifted. Nothing else in the panel is anything to
either of them any more, the hero having moved to the middle. The lesson tabs are
down the other edge and ignore both.

**There is a third arrangement, `lay.corner`, and a page held upright gets it**:
`CUSTOM` back in the column under the drawing and `GO!` alone in the far corner,
centred across what the cards leave (`lay.sideRight` to `lay.tabRight`) and stood
`CORNER_GAP` off the foot so it sits in that corner rather than wedged into it. It
is taken only when all three of these hold — the corner clears `lay.sideRight +
EDGE`, it sits below
`lay.tabBottom + EDGE` (the foot of the lesson tabs, which is why `layout` records
it), and `liftedY(0) - top >= blockMin + HERO_GAP + actH + SPARE`, i.e. the column
can carry the box on its end and still have room to spare, standing entirely above
the cards. A wide page fails the last by about a hundred pixels, which is the
shortage that made the pair in the first place. `tailH` is what the arrangement
costs the column (`HERO_GAP + actH`, zero otherwise) and is added into every height
the column is measured by — the hero ladder, `blockH` and the band the drawing
floats in — so `CUSTOM` is a row of the block rather than something it is kept
clear of, and `lay.customY` is set after `heroY` because there is nothing to put it
under until the drawing has landed.

`lay.underButton` has a second reader on an upright page. `panel` centres the block
in what the foot left it while the slack is small, and **spreads** it where the
slack is at least the drawing's own row deep (`SPARE`): `lay.head` goes to
`lay.underButton`, `lay.heroY` and the `tailH` under it float together in the
middle of everything below the stats (they float as one thing because a box that is
under the character has to stay under the character),
and the sheet reads heading, stats, drawing, boxes down a page rather than sitting
as one block in the middle of it with a hole at each end. Fifteen pixels spent on
clearing the button is worth nothing on a wide page and worth having on this one.

**A tab is pressed, not answered**, so the tabs are plain rectangles in
`self.tabs` rather than `Scribble` boxes: `Timetable:press` (the pen's press-edge
callback) selects whatever is under the point, and the number keys call
`Timetable:select` outright. The rule the screen is drawn along is that choosing
which page to *look* at is not a question — only leaving is — and if that ever
gets blurred the screen loses the thing that makes `GO!` mean anything. What holds
the rest together:

- The picked tab is **pulled out** (`TAB_POP`) by moving the rectangle itself, so
  what you press is the tab as drawn.
- **Every** tab is filled `Palette.paper` (the only colour that covers), picked
  one included, so no ruling runs under the lettering. Leaving the picked one
  unfilled was tried and read as a hole cut in the tab on squared, ledger and
  stave pages; the pop and the red are what say which tab is open.
- The whole column is drawn **after `Overprint.finish()`**, so nothing on a tab is
  paired with the page under it. The fill alone is not enough: the pass pairs
  inked pixels with the page whatever was drawn in between, so borders and letters
  landing on a rule came out a step darker and the tab read as see-through. Keep
  them out past the pass; everything else on this screen stays inside it.
- A tab carries a `fill` of 1 or 0 for one reason: so its colour can come off
  `Scribble.boxColor` like everything else that is picked, hot or stepping aside
  — red when out, slate when not, and flashing/graphite once `flash` is passed.
- `Timetable:mark` **drops any mark that lands on a tab**. The fill would hide it
  anyway, and a press on a tab was taken as a press, not as the start of a line.
- Both fill and border run `TAB_OVER` past the safe right edge so a tab is off the
  sheet rather than squared off against it; nothing *written* on a tab goes past
  that edge (the icon is placed from `lay.tabRight` in).

`Timetable:commit(what)` is what ends the screen, and `update` hands back that
`what` plus `self.current` rather than the answered box's key, because the boxes
are `go` and `custom` and neither is a lesson. Two details there: the tabs only
flash for `go` (`CUSTOM` is not leaving the lesson, so the tabs have no news), and
where one stroke armed both boxes the one it was in last wins (`lastAct`), since
they are stacked a few pixels apart.

The page under the whole screen is `self.current` — pressing a tab turns it on the
spot, which is what replaced the swatches this screen used to carry.

One thing in `src/scribble.lua` changed on the way here and is worth keeping: the
drawn-for-you scribble is sampled off `autoLength(box)` rather than a flat count,
so it lays a stamp a pixel whatever size the box is instead of coming out as a
dashed line on a big one.

Everything in the panel is centred on `lay.cx`, which is `lay.pageCx` -- the middle
of the safe area, tabs and all -- walked left only where a centred block would run
under the tabs, and by exactly enough to clear them. The tabs are card off the edge
of the sheet, so what they take is margin rather than page, and a heading centred
in what they left reads as slightly out rather than as centred; `lay.textX/textW`
are what a centred block has to *clear*, not what it is centred in. The clamp is
struck off the widest centred thing there is (the column — hero and `CUSTOM`
included, the hero at the biggest scale he could be drawn at — and `GO!`) so all of
them stay on one line. Every part of the panel is measured at its widest and
tallest — the longest lesson name, the widest tool name, the longest character
name, every weapon in the roster, all five stat rows — so nothing moves as the
selection changes. The tabs take their width first and never give; the degradation
is all in the panel and runs down the page: the heading and the lesson's
name drop from double to single size, then the hero drops from `HERO_SCALE` to 1:1
(the drawing is the player's own and can be any height, so a tall hero on a short
page is worth a step rather than a hole), and then he is dropped altogether with
the arm in his hand and `CUSTOM` closes up under the stats.

The hero's rung is the one that runs *up* as well, and `panel`'s ladder is written
`{ 4, 3, HERO_SCALE, 1 }` for it. A scale past `HERO_SCALE` is taken only if the
block still leaves `SPARE` behind (`heroH * HERO_SCALE` — a page filled to its
edges has been run out of rather than used) and only if `heroW * scale <= colW`,
the widest line of the sheet. The second is what keeps the middle line still:
`colW` is measured with the hero at `HERO_SCALE` and `lay.cx` is clamped off it, so
a drawing that stays inside that width cannot push the heading sideways because the
page got taller. Both tests together leave a 16:9 page at `HERO_SCALE` — 3 fits
there by six pixels and leaves nothing behind — and hand an upright phone a hero at
three times the size he is played at.

The hero is the one drawing in the game shown at anything but 1:1, and the way he
is scaled is the way `Scribble.printBig` scales the 3x5 face: `drawHero` pushes an
integer `love.graphics.scale` and draws the sprite unchanged inside it, so every
coordinate stays whole and the bounce stays one *drawing* pixel. Past that
translate there is one coordinate system and it is the sprite's — which is why
`lay.heroX/heroY` are the hero's canvas corner and `lay.armX/armY` are in the
drawing's own pixels.

`src/records.lua` is what the panel's two numbers come from: the longest run and
the most killed on each page, one line per subject in a save-directory text file,
loaded once in `Game:load` and banked by `Game:bankRun` from every route out of a
run — death, the win card and quitting from the pause card. A record is a
maximum, so banking twice is harmless and a bad run cannot take one away. It keeps
a third number no panel shows — `bosses`, the most bosses one run on that page put
down — for its second reader, which is what says how much of the catalogue the book
has opened (see **The collection**). It is `bosses` here and `game.eyes` in the run
on purpose: a run may name what it is fighting because it only ever fights one
thing, and this file outlives seven of them.

Two counts are derived off it and neither is stored. `Records.best().beat` is how
many *different* pages have had a boss put down, and `Records.sat(seconds)` is how
many have been played far enough in that one walked on — kept apart from `best`
because it has to be told the bar, and how long a lesson runs for is the spawner's
business. Both are counts of maxima, so both can only go up, which is what makes
them safe to gate on.

It keeps a fourth field which is not a number of anything: `course`, the course the
best *time* on that page was sat at (see **Courses**). It is a label on the clock
rather than a record of its own — the timetable prints the two on **one row**,
`BEST  8:31  PHD` — and it is the one place this file bends its own
rule: it moves with `time` and only with `time`, so beating your best on the
easiest course in the book relabels the row, because the alternative is a register
reading 8:31 at a doctorate about a run that was nothing of the kind. That is safe
precisely because **nothing gates on it**: the collection asks this file for times,
kills, bosses and counts of pages clearing a bar, and never once for a course. A
field that can go down may live here as long as no unlock is written against it,
and if one ever is, this is the field that has to change first.

And a fifth that is the course again, kept the honest way: `won`, the hardest
class this lesson's boss has ever been put down at, as a course key on disk and an
index through `Records.wonAt`. It is the one field here a gate *is* written
against -- the four COMPLETE EVERY CLASS rows of the homework list (see
**Homework**) -- which is exactly why it cannot be the field above it. So it is a
maximum on the ladder's order and nothing else: it moves only upwards, only when a
boss actually goes down, and it never looks at the clock beside it. Two fields
naming a course and one meaning: a page you played, and a page you won, and
neither is derivable from the other since the longest run on a page need not be
the one that shut the eye. `Records.beatAt(index)` is the count of pages beaten at
that rung or better, the third count of pages beside `best.beat` and
`Records.sat`, and a maximum on their terms.

The file is positional and lenient both ways, so `won` costs no migration: it is
written last as `-` when there is none, and a line from before the column existed
reads back as a page never beaten rather than guessing from the `course` beside
it. A page you played at a doctorate is not a page you beat there, so an old save
asks for its hardest wins again -- which is the safe way round.

#### The tally

`src/tally.lua` is `src/records.lua` read the other way round, and they are two
files rather than more columns on one. A **record** is a maximum kept per lesson
and the whole of what makes it safe is that it cannot go down and cannot be paid
twice. A **tally** adds up -- it is the purse's kind of number -- and everything
awkward about it comes from that one difference: banked twice for the same kills,
it is kills made out of nothing.

It exists because the homework page stopped asking what your best run did (see
**Homework**). Three things are counted, and they are the three a run finishes
holding: `kills[kind]`, one body count per row of `Enemy.types`, keyed by the
spawner's own name for the monster so a new row brings its own counter;
`bosses`, how many have gone down ever, where the register keeps the most one run
managed; and `time`, how long the book has been played across every page and
every run.

**A watermark, not a hook.** Nothing in `src/tally.lua` is called when something
dies. The run counts what it counts -- `Game.killsBy[kind]` is one line in
`Game:killEnemy`, beside the split and the burst and for the same reason, since
that is the one door every kill in the game comes through -- and `Game:bankTally`
hands over the *difference* between what the run holds and what `Game.tallied`
says it has already paid in. Every number a run counts only goes up, so a
difference is always the work done since the last bank, which makes it exactly as
safe to call as `Game:bankRun` beside it: twice in a row adds nothing, and a run
walked out of through the pause card and carried on adds the second half only.
`Game:openBookmark` sets the watermark from the restored clock and cycle for that
reason -- those two were paid in on the afternoon the bookmark was written --
while `killsBy` is deliberately empty on both sides, since a bookmark does not
carry it. It is banked from `Game:bankRun` rather than from `Game:cashRun`,
though a tally and a payout are the same kind of number, because they are owed at
different moments: a run walked out of is paid nothing and has still killed
everything it killed. `Tally.stamp` is `Records.stamp`'s twin, and
`Challenges.have` caches off the pair of them.

One row rather than two, and the seven pixels that buys are worth knowing about
before anything else is added to `statRows`: every row of that block is
`Font.height` plus `LINE_GAP`, and seven pixels is the kind of margin
`Timetable:panel`'s hero test turns on. The block *does* have a sixth row now — the
course selector — and what paid for it was moving both boxes to the foot of the
page (see below).

### Courses

`src/course.lua` is the other half of what a run is built from, and the split
between it and a subject is one sentence: **a page may shape an arrival and may
never price one; a course prices every arrival and cannot shape a single one.**
That is what keeps seven lessons comparable to each other while making the ladder
a fact about the run rather than about the page.

Four rungs — `HIGH SCHOOL`, `BACHELOR`, `MASTERS`, `PHD` — and the first is not
the easy setting, it is *the game*: every dial on its row is 1, so it is every
number argued for in `README.md` and every measurement the bestiary was tuned by.
The three below it are written as multiples of it.

| dial | what it multiplies | bachelor | masters | phd |
| --- | --- | --- | --- | --- |
| `clock` | the difficulty clock (`Spawner:update`) | 1.2 | 1.4 | 1.65 |
| `hp` | every arrival's health, flat | 1.25 | 1.6 | 2.1 |
| `ramp` | the exponent under `HP_PER_MINUTE` | 1.08 | 1.16 | 1.25 |
| `speed` | how fast a monster walks (and dashes) — the run multiplies it again | 1.04 | 1.08 | 1.12 |
| `elite` | divides `ELITE_RAMP` — how fast the champion chance tops out | 1.25 | 1.6 | 2 |
| `blown` | `BLOWN_RISE`, the blow-up meter | 3 | 9 | 60 |
| `fury` | `FURY_RISE`, the enraged meter — a gate, not a lean | 0 | 0 | 60 |
| `pay` | the whole of what a run is worth | 1.4 | 2 | 3 |

Which comes out as a blob of 4 health being 5, 6 and 8 in the grace minute and 19,
28 and 40 by the time the eye walks on against high school's 14; an eye of 1260
being 1575, 2016 and 2646; and a run at a fixed damage-per-second clearing 76%,
61% and 46% of the bodies it would have cleared at high school in the same ten
minutes.

**Six of the seven dials are read in `src/spawner.lua` and one in
`src/purse.lua`**, and none of them is a branch. `clock` is one more factor on the
line that already had the subject's; `hp` and `ramp` are two factors in
`Spawner:scale`; `elite` divides `ELITE_RAMP` in `Spawner:elite` and deliberately
never touches `ELITE_MOST`; `blown` multiplies the rise in `Spawner:swell` and deliberately
never `BLOWN_MOST`; `speed` rides out on the scale like everything else and is
baked onto the arrival in `Enemy.new`. `pay` multiplies the sum in `Purse.forRun`.

Four things about that are worth knowing before touching any of it:

- **`speed` is the one number on an arrival a scale had never touched.** It used
  to be read as `self.def.speed` every frame; it is now baked in `Enemy.new` as
  `speed` and `dashSpeed`, for the reason every other number on an arrival is
  baked — what walked on at a doctorate in cycle three goes on being that, and
  nothing standing on the page changes because the class did or because a minute
  went by. Both, because a wad has two speeds and they are different kinds of
  thing: what it walks at and what it *falls forward* at. A course that scaled
  only the first would leave the one enemy whose whole point is a sudden closing
  of distance exactly where it was.

  It is also the one dial here the **run** turns as well (`SPEED_MOST`, see
  **Health is a per-minute curve**): the minute multiplies this row rather than
  replacing it, and the ceiling that keeps the horde under the player sits on the
  run's half of the product. Put it on the whole product instead and this row
  stops meaning anything — a doctorate would reach the cap by minute three and a
  half and all four classes would walk at the same speed thereafter.
- **`elite` and `blown` are read per *arrival*, and a harder course has fewer** —
  a doctorate's horde takes over twice as long to clear, so a chance-per-arrival
  doubled against an arrival count halved is a course that meets no more of them.
  That is what a first pass at both of these measured. They lean on the curve in
  two different places, and which place is the whole content of the pair.

  **`elite` divides `ELITE_RAMP` and must never lift `ELITE_MOST`.** The
  one-in-seven ceiling is priced against what a champion costs the *page*: the mark
  is the body drawn double (`ELITE_GROW`), so a seventh of the horde at four times
  the paper is most of what the page can carry, and the note over that constant says
  out loud that past it a double body stops meaning "that one". A course may buy a
  harder run and may not buy its way past that — an earlier version of this dial
  multiplied the ceiling too, and that did not survive the mark changing from a rim
  of ink to a size. So a doctorate reaches the same ceiling in half the time: capped
  by minute seven and a half instead of minute eleven, which measures out over one
  cycle as a champion in every 40 arrivals against high school's one in 59. Nothing
  extra in the cycles past the first, which is the right shape for it — an endless
  run sits on the ceiling whatever course it is, so the only thing left to sell was
  the middle of a run.

  **`blown` is tuned against the count, and that had to be measured.** A blow-up is
  an *event*, a handful in a whole run, so the unit is how many you meet rather
  than what fraction of the page they are: 3/9/60 come out at 1.24, 1.48 and 1.62
  times as many per cycle as high school. They look out of scale with the rest of
  the table because the meter is quadratic in its rise (four times the rise is
  twice as often) and the falling arrival count takes most of it back. Past about
  there `BLOWN_MOST` answers instead of the rise and a bigger number buys nothing —
  the same restraint `elite` is under, reached from the other side.
- **xp comes out flat across the whole ladder**, and that is the design working
  rather than a coincidence. `xp` rides the hp multiplier (`Enemy.new`), so a horde
  that takes twice as long to clear pays twice as much per body: measured over two
  cycles at a fixed damage-per-second, the four courses bank 95.8k, 98.7k, 94.4k
  and 96.1k. A course therefore changes how hard a run is and **not** how many
  drafts it sees, which is what keeps `XP_RISE` and the whole of `Upgrades.list`
  out of this.
- **What a course does not touch is what a hit costs you.** Enemy damage is
  exactly where `src/enemy.lua` wrote it. A course *could* have moved it — it is a
  step rather than a slope, which is the objection to a continuous damage curve —
  and the reason it doesn't is that what a harder class may take away is *time*,
  never the arithmetic a player counts their own page of health in. The blob's 6 is
  a quarter of you in every class in the building.

**It is bought, not unlocked.** Everything the collection opens is opened by
playing, and a harder book cannot work that way: the milestone it would have to ask
for is "beat the game", and telling a player who has beaten the game to beat it
again is telling them the wrong thing. So the ladder is a row on the canteen
(`COURSES`, one row with three levels at 15/40/90) answering the same five `shop`
questions a perk does, `src/refund.lua` hands it back like anything else there, and
**nothing here goes through `src/dev.lua`** — a course is a purchase and not an
unlock, which is exactly the line that file draws around the purse. It is one row
with three levels rather than three rows with one because a course ladder is a
ladder: buying a master's before a bachelor's is not a thing the book should have
to have an opinion about, and a line whose level *is* how far up you are cannot
express it.

**The pick belongs to the book and the course belongs to the run.**
`Course.current` is a setting, saved in `course.txt` beside the rung count and
clamped on load to what has been paid for; `Game.course` is copied off it once in
`Game:reset` and is what the spawner, the payout, the register and the end cards
all read. The two have to be separate for one reason: a run walked out of through
the pause card, changed on the timetable and then continued would otherwise be paid
and recorded at a class it was never sat in. A bookmark writes the *run's* course
for the same reason, and `Course.pick` clamps it on the way back in — so a bookmark
written before a refund comes back at the top of what is left.

The ladder is picked on the timetable, as a **stepper on the sixth row of the stat
block**: the label `COURSE` in the column the labels are in and `<` the course `>`
in the column the figures are in, right-aligned like all of them, directly above
the drawing of the character. The chevrons are `Sprites.icons.chevron` drawn
through `drawMask` (the art is palette-locked, so there is no colour to set on the
sprite — `Hud.drawIcon` has the same problem and answers it the same way) and drawn
**bare** rather than in the library footer's 11px boxes: the glyph is three columns
wide, so the whole control is 57 pixels and fits inside the value column the clock
row had already reserved. Each arrow's *target* is still a box the size of the
corner button's; the word between them is deliberately not pressable, because a
press on it could only mean one of the two arrows and either choice would be wrong
half the time. `left`/`a` and `right`/`d` step it, matching the library's own
footer. It is drawn *inside* the overprint pass with the rest of the block, because
it is a row of the sheet and not furniture lying on it.

What a stepper cannot say is that there is more ladder, so the `>` says it — slate
where there is a rung to step onto, **red** where the ladder goes on but has not
been paid for (the colour this book writes a go-and-do-something-about-it in),
graphite at the top of it. A book that has bought nothing shows a graphite `<` and
a red `>`, which is the whole of what tells you the ladder exists.

Where it went took three goes and the answer is a fact about the whole screen. It
was a column of four cards down the left margin first, showing the whole ladder at
once, locked rungs and all — genuinely more than a stepper says, and fifty pixels
of margin, which on any page narrower than a desktop one is fifty pixels the
*sheet* then has to be walked out of. Then it was a stepper in the margin under the
corner button, which cost the sheet nothing but sat with the furniture, away from
the thing it is about. It is a row of the block now because that is what it is:
everything in that column is what this run would be.

**What paid for the row is the foot of the page.** `Timetable:panel` used to put
`CUSTOM` in the column under the character and `GO!` alone at the very foot; both
are now at the foot together, which hands the column back twenty-eight pixels
against the seven a stat row costs. The foot has two arrangements and picks between
them by laying the first out and looking:

- **Paired** — `CUSTOM` then `GO!` side by side, `ACT_GAP` apart, centred on the
  sheet's own middle line. About 120 pixels in English and 150 in Spanish.
- **Stacked** — `CUSTOM` over `GO!`, each centred on its own width, where the pair
  would run into the three cards at the foot of the left margin. That happens
  around 240 pixels of width in Spanish, where the doors and the lesson tabs take
  two thirds of the page between them.

Stacking rather than putting `CUSTOM` back in the column is the point: a second row
at the foot costs 24 pixels and a box in the column costs 28, so the stack is the
cheaper fallback *and* it keeps the column free of boxes in both arrangements.
Where even the stack meets the cards, the foot is **walked right** off the middle
line before it is ever lifted over them — sliding costs the sheet a little symmetry
on a page nobody would call symmetrical, and lifting costs the column every row
below the stats.

Measured across nine page shapes in both languages, the hero is at `HERO_SCALE` on
every landscape page the game is realistically handed, including the notched
400x180 phone where it used to drop to 1.

### The horde

`Enemy.types` in `src/enemy.lua` is the whole bestiary and `TABLE` in
`src/spawner.lua` is when each of it turns up. Nine kinds walk on over a cycle's
ten minutes, plus one that is never spawned and one that only arrives at the end:

| kind | at | weight | hp / speed / dmg | what it is |
| --- | --- | --- | --- | --- |
| `blob` | 0 | 10 | 4 / 20 / 6 | the page |
| `bat` | 45 | 7 | 2 / 38 / 4 | the page, quicker |
| `wad` | 120 | 4 | 6 / 18 / 10 | charges (`charge`) |
| `blot` | 200 | 3 | 11 / 16 / 8 | splits into three (`split`) |
| `drop` | — | — | 2 / 30 / 4 | what a blot splits into |
| `skull` | 280 | 3 | 12 / 15 / 12 | the wall |
| `bulb` | 360 | 3 | 8 / 26 / 5 | bursts when killed (`burst`) |
| `eye` | 420 | 2 | 14 / 9 / 10 | shoots (`shot`) |
| `grin` | 480 | 2 | 34 / 11 / 16 | shrugs off shoves (`knock`/`hold`) |
| `redeye` | 540 | 2 | 14 / 34 / 10 | shoots and holds range (`keep`) |
| `bosseye` | 600 | — | 900 / 26 / 20 | the cycle boss |

Every row walks at the player and every block is a way of not *only* doing that.
The header comment over `Enemy.types` is the field reference; what matters
architecturally is **where each block is read**, because each is read in exactly
one place and nothing else in the game knows it exists:

- **`shot`** and **`trail`** and **`tears`** — `Game:updateEnemies`.
- **`keep`** — inside `Enemy:update`'s chase, as a *turn* applied to the heading
  everything else already computed. That placement is the whole reason it is
  cheap: a shooter holding its distance still rounds a pen line, still skids on
  wax and still keeps a heading through a shove, because there is no second way
  of walking in the file. It sits *below* the lure, so a spiral overrules it.
- **`charge`** — `Enemy:charge`, which returns whether it has taken the movement
  for this frame and is the only thing in the file that ever does. Three phases
  (`chargePhase` ∈ `wind`/`dash`/`rest`, nil for "walking") with `phaseT`
  counting down whichever it is in. The heading is locked at the *top* of the
  wind and never looked at again, which is what makes the attack dodgeable. A
  glueing drops a wind-up the way it drops a knockback; a lure cancels it
  outright.
- **`split`** and **`burst`** — `Game:killEnemy`, the one door every kill in the
  game comes through, which is why a monster whose entire design is what happens
  when it dies needs no second hook and no clause in any of the dozen things
  that could have killed it. Both run *after* the `table.remove`, and both are
  safe inside a walk of the horde because every such walk goes backwards.
  `Game:splitEnemy` hands the children the parent's own `scale`; `Game:burstEnemy`
  hits the player and nobody else, then drops a `Puddle`.
- **`knock`** and **`hold`** — `Enemy:knockback` and `Enemy:freeze`, both of
  which already rode on the enemy rather than on the dozen things that shove and
  stick. The grin is the horde-sized version of what went in for the boss.

### Drills and surges

`TABLE` and the two taps (`FLOOR_RATE`, and the wave timer in `Spawner:update`)
answer *how many* and *what*. **Drills answer *from where*, and surges answer
*more or less than usual*.** They exist because the ramp runs out of things to
say around minute five — the wave timer is pinned at its 0.22s floor, the page is
at its cap, and the only variable left is more of the same at once — and because
a uniformly random spawn bearing makes the page *isotropic*, so running buys a
second but is never a decision.

**Five drills, all in `DRILLS` in `src/spawner.lua`.** A row carries `at` (the
minute of horde it unlocks), `shape` (which function runs it), its first-cycle
`count`/`gap` or `lasts`, and the `notice` the run calls it by:

| drill | at | shape | first cycle | what it asks |
| --- | --- | --- | --- | --- |
| `line` | 1.5 | `wall` | 14, 15px apart | a wall with ends — go round it? |
| `ring` | 3.0 | `circle` | 20 on the ring | the same with the ends taken away |
| `grid` | 4.5 | `block` | 16, 4×4, 18px | a block is *deep* — you can't finish it |
| `pincer` | 6.0 | `pincer` | 2 × 8 | two walls; the answer to running from one |
| `side` | 7.5 | `bias` | 18 seconds | a *condition*, not an event: one hot edge |

`SHAPES` maps `shape` → a function, so a drill is a row plus a function and no
branch anywhere. Three constraints on the ladder, all of them learned the hard
way and all of them worth keeping:

- **Nothing unlocks after 7.5 minutes.** A page deals only from what has
  unlocked, so a shape arriving at 8.5 gets ninety seconds of a cycle to exist
  in — the grid was there first, and the two subjects built on the grid dealt it
  about once a run.
- **The order is sorted by how much the *pages* need a shape**, not only by
  difficulty. `line`/`ring`/`grid` are some page's signature and unlock early;
  `side` is nobody's signature and unlocks last.
- **A page's hand must hold two of the first three.** P.E. held only `line`, so
  its first four and a half minutes dealt the wall six times running with nothing
  for the no-repeat rule to pick instead.

**Marching is `Enemy:lure` and nothing new.** Every member of a wall is lured at
*its own* point straight across the page, offset along the wall by exactly the
amount it was spawned by — which is what keeps the wall parallel rather than a
funnel collapsing on the player in the first second. The lure lapses rather than
being cancelled, and that moment is the event: `MARCH_HOLD` is 7 seconds and a
blob walks 20px/s, so a wall covers about 140 of the 207px ring and then every
one of them turns and remembers you. It also overrules `keep`, so a redeye in a
wall marches instead of hanging back — the one place in the game a shooter is
somewhere it did not choose to be.

**The taps stop at `Spawner:hordeMost`, and the rest of `MAX_ENEMIES` is the
drills'.** Past minute five the page is held down by the cap and not by either
tap, so a drill scheduled for minute eight — the half of the run drills were
added for — would find no room and walk on as four monsters. `DRILL_ROOM` is 40
in the first cycle (so the taps stop at 220) and **grows at `DRILL_GROWTH` like
the drills do**, because a fixed reserve fails quietly and late: a ring widens to
44 bodies by cycle five and would never fit again, so rings would stop happening
in exactly the runs that earned them. Floored at half the ceiling — the horde is
still the game. The mix therefore shifts towards shaped arrivals as cycles go on,
which is the right direction, since by then health is up twentyfold and
undifferentiated bodies are the half of the page with least left to say.

**A drill that cannot arrive whole does not arrive**, and is not announced or
remembered when it doesn't (`Spawner:beginDrill` compares `Spawner:many`'s wanted
count against its clamped one). Being told a wall is crossing the page and then
seeing four monsters would spend the single announcement that shape gets for the
whole run on the version of it that isn't one. It retries on a shortened gap.

**Three surges, in `SURGES`, and they are everybody's.** Where a drill belongs to
the page, these are the same on every lesson at the same minutes, because they
are the run's pulse rather than the page's character: `swarm` (2.5 min, 15s,
`floor` ×1.6 and `batch` ×2), `only` (5.5 min, 20s, one kind at ~95% via
`ONLY_LIFT`/`ONLY_DROP` inside `Spawner:weight`), and `quiet` — 8s at `floor`
×0.3 and `batch` 0, which **only ever runs as the back half of a swarm**
(`self.after`). That is the single place this game breaks its own rule that
clearing the page buys more page and never a rest, and it breaks it on purpose:
a lull nobody earned is a gap in the game, while a lull that arrives when the
swarm ends *is* the swarm ending. It is self-scaling too, since nothing
despawns — a quiet stops the refill, so what the eight seconds are worth is
however much of the swarm you can clear in them.

**The multipliers lean on the floor and the batch, never on the difficulty
clock.** Multiplying `time` would drag the interval and the unlock-independent
knobs along with it and make a fifteen-second swarm briefly a different minute of
the game. `batchMul` is what actually makes a quiet quiet, because past minute
five the wave tap and not the floor is the binding constraint.

**Endless runs escalate with no second rule**, because both schedules gate on
`Spawner:minutes` — minutes of *horde*, which is the same clock the health curve
reads. Minute 10 is cycle two's minute nought, so a run that carries on past the
eye arrives at its second cycle with all five drills already in the bag and never
sees the ladder again: the first cycle teaches them one at a time, every cycle
after it is the exam. On top of that `DRILL_GROWTH` widens a drill 30% a cycle
(a 14-wide wall has ends you can get round; the same wall three cycles later is
wider than the page) and `DRILL_HURRY` closes the gap between them to 88%,
floored at `DRILL_LEAST` — past one every twenty seconds an event is not an
event, it is the weather.

**Three smaller rules.** `Spawner:pickDrill` never deals the same shape twice
running unless the page has unlocked only one — a bag that can repeat deals two
walls in a row often enough to read as the game having a single idea.
`Spawner:announce` names a drill the *first time it happens in a run* and is
silent after, via `self.seen`, which is the whole of how these are taught (and
which makes cycle two silent by construction, since every name is spent).
`Spawner:settle` pushes both clocks out so two events never overlap: the value of
naming a shape is that the page is briefly *about* that shape.

`Spawner:clearEvents` wipes all of it at both ends of a boss fight. The fight is
the fight, and the next cycle should open on its own terms rather than halfway
through the last one's weather.

**Champions are a scale, not a row.** `Spawner:elite` rolls one per arrival and
`Spawner:scale(time, elite, kind, grow)` returns a multiplied version of the
run's own difficulty scale, so an elite costs no art, no behaviour, no unlock
time and no new field anywhere — and every kind added later is elite-able the day
it lands. It is `ELITE_HP` (3.6) on health, `ELITE_DAMAGE` (1.25) on damage and
`ELITE_GROW` (2) on the drawing. The reward is free for the same reason the
multipliers are: `xp` rides the hp multiplier in `Enemy.new`, so something 3.6× as
long to kill is worth 3.6× as much without a second number. The boss is guarded
out explicitly.

The mark used to be a rim of heavier ink and is now the size, which is the one
part of a champion that is no longer free — every seventh arrival past
`ELITE_FROM` now stands on four times the paper. What it buys is a mark legible in
the crowd it has to be read in: a one-pixel rim on a body touching four others is
a rim you hunt for. It also gives a champion a second sentence it never had, since
the radius grows with the drawing — one is now harder to miss and harder to
squeeze past as well as longer to kill. `Enemy.elite` is now read **nowhere**; see
**Champions and blow-ups differ only in degree** below.

**Blow-ups are the same trick further along the same axis.** `Spawner:blown` rolls
the other standout: the same monster at `BLOWN_GROW` (3) times the drawing, on
`BLOWN_HP` (5) times the health and `BLOWN_DAMAGE` (2) times the damage. Those
used to be one number — the size *was* the multiplier — and they came apart when
the champion took the other size. `BLOWN_HP` sits above the 3 the size would have
priced (three times across dying before you have walked round it is not a
blow-up), and above a champion's 3.6 by much less than 3 is above 2: what a
blow-up is for is being **in the way**, and something that was also the longest
fight on the page would be a mini-boss wearing a monster's art. `BLOWN_DAMAGE`
stayed where twice the drawing had put it — three times a grin's 16 would be most
of a health bar from the slowest thing in the game, wearing the loudest
silhouette, after a line of text with its name on it.

`Enemy.new` reads `scale.grow`, multiplies `def.radius` by it and stores it on the
instance, and that single field is the whole feature for both — `Sprite:draw`
takes a whole-number scale (nearest filtering, floored position, no rotation, so
still exactly the same pixel grid), and every hit radius, separation pass, wall
clearance, box clamp and damage-number anchor in the game already reads
`e.radius` off the instance rather than `e.def.radius`. Nothing else in any weapon
knows the idea exists. It is also what bounds the pair at two: a sprite scale is a
whole number, so there is no room between 2 and 3 for a third standout.

**Champions and blow-ups differ only in degree**, which is the cost of putting
both on the size axis and is worth knowing before touching either. They used to be
told apart by *kind* — ink against paper, a health bar against a shape — and are
now told apart by *how much*, a weaker thing to ask a player to read in a crowd of
two hundred. Two things already in the design buy it back: rarity (a champion is a
seventh of arrivals, a blow-up a handful in a whole run, so the ×3 is standing
next to the ×2s rather than among them), and the fact that a blow-up is the one of
the two that says its own name (`BLOWN_NOTICE`). `Enemy.elite` survives as the
only record on the monster of which roll produced it, read by nothing — it is
where a second mark would be read from if either standout ever wants one back.

The two are still **mutually exclusive**, decided in `Spawner:dropAt`, and that is
now structural rather than a judgement call: a champion roll only happens when the
blow-up roll came up empty, because together they would be 18× the row's health at
6× across — a blob on more page than the boss stands on, in a box a boss fight
would not hold. The champion roll is skipped rather than overruled, so a blow-up
does not quietly eat a random number.

Neither is **slower**, and that is deliberate: the lumbering giant is a wall
rather than a monster, and what makes a big bat frightening is that it is still a
bat. `out.speed` rides out past all three branches of `Spawner:scale` for that
reason. `grow` is likewise flat in both branches — a champion that grew with the
minute would put a cycle-four blob on more page than the boss; health is what a
curve is for.

The **largest bodies** the pair can produce are worth checking against the art
before adding a big enemy: a ×2 grin is 28px across on a 14px sprite, and a ×3 one
is 42px at radius 21 — a hair under the boss eye's 43px sprite and a pixel past
its radius of 20. That is the intended extreme of "in the way" and it is rare
(the grin is 2 of 37 weight, and blow-ups are ~1% of arrivals), but any kind added
wider than the grin will exceed the boss at ×3.

**The chance is a meter, not a probability.** `BLOWN_RISE` is added to
`Spawner.due` at *every arrival* and the meter **is** the chance; it resets to
nothing the moment one lands. Two consequences, both wanted. The unit is
monsters rather than seconds, which is the honest unit on a page that spawns ten
a second when it is filling and almost nothing when it is full — and it makes how
often you meet one partly a fact about your build, since a run clearing twice as
fast is handed twice as many arrivals. And it cannot clump or drought: the
arrival after a blow-up is the least likely thing in the game to be another one,
and `BLOWN_MOST` caps the climb only to bound the wait (about two minutes, worst
roll). `BLOWN_HURRY` leans on the rise per cycle — the meter, never the ceiling,
so this can never become how the horde looks. `BLOWN_ONLY` multiplies the rise
four-fold while a `MORE OF THE SAME` surge runs, which is the joke that surge was
waiting for: the one stretch where the page has stopped varying *what* it sends
is the stretch where it varies how big one of them is. Measured: nine in the back
half of a first cycle, a little over twice that in a fifth, and about one per
`only` surge. `Spawner.due` is the one piece of event state `clearEvents` does
*not* wipe — it is a fact about the horde, and a meter that reset every ten
minutes would put a drought at the opening of every cycle.

Gated on `Spawner:minutes` (`BLOWN_FROM`, 5) like the drills, so cycle two starts
past the gate and endless runs need no second rule.

**Fury is the third fact about an arrival, and the first that is not a size.**
`Spawner:fury` rolls it, `Spawner:scale` prices it and `Sprites.enraged` draws it:
the same row at the same size on exactly the row's health, `FURY_SPEED` (1.25) on
its legs and `FURY_DAMAGE` (1.5) on its damage, with the whole body recoloured to
two tones — red where the art was mostly made of one mark, ink everywhere else.

It exists because the size axis is used up. A sprite scale is a whole number, so
there is no room between ×2 and ×3, and ×4 is wider than the boss. What was left
to vary is the thing both standouts deliberately do not touch: they are *slower to
kill*, neither is quicker and neither hits for much more, because the note over
`ELITE_DAMAGE` is that a standout should be a target and not an ambush. An
enraged arrival is the monster that was missing from that — one that gets to you
sooner and takes more off you when it does.

**It stacks with both standouts, and that is structural too.** The champion and
the blow-up are mutually exclusive because they are both bodies and would add up
to one the page cannot hold; fury is a colour and two multipliers, so it costs no
paper at all and adds to either. An enraged champion is a legible amount of
monster; an enraged blow-up is the loudest thing this game can put on a page, and
is the product of two rare rolls rather than a third chance to keep in step. The
roll happens at every arrival rather than being skipped like the champion's — the
two *sizes* are what cannot be added together.

**Health is untouched, which settles the reward with no second number.** `xp`
rides the hp multiplier in `Enemy.new`, and an enraged blob is not a longer fight,
so it pays a blob. A run is paid for the killing and never for the fright.

**The numbers.** 1.25 on the legs is measured against the one row it matters for:
a bat is 38, the fastest walker in the horde, and 38 through a doctorate's class,
the run's own approach and this comes out at 60 by minute ten and 62.8 in the
limit — against a player's 58. Over the player is deliberate and is the whole
point of the row: an enraged bat is the one arrival you cannot walk away from, and
a bat is 2 health, which is what makes that fair. Everything else stays under —
an enraged blob is 31 and an enraged skull 24 — so what the multiplier buys the
rest of the horde is a shorter breath rather than a chase.

1.5 on damage is above both standouts' (1.25 and 2) and is the champion's mismatch
read the other way round: a champion buys health because it should be a *target*,
fury buys none, so what it has to be instead is a *threat*. An enraged skull is 18
of a hundred and an enraged grin 24. It is also the one thing in the game that
moves what a hit costs you, which `src/course.lua` forbids a class from doing —
and the restraint survives it, because what that forbids is the word *quietly*: a
doctorate's blob still hits for 6, and the one that hits for 9 is red and black
from head to foot, is one arrival in a hundred, and said its own name the first
time it walked on (`FURY_NOTICE`, "GONE OVER IN RED PEN").

**The chance is the blow-up's own meter run twice** — same rise, same ceiling,
same lean per cycle, its own accumulator (`Spawner.rage`), so the two roll
independently. Measured at a doctorate over 40,000 arrivals: one in 111, against
the blow-up's one in 98 — the same cadence to within the noise of the roll. The constants are written again rather than shared because they are
the same today and are not the same fact — the blow-up's rise is priced against
how much paper the page can carry, fury's against how often a page should hand you
something you cannot outrun. Gated at `FURY_FROM` (3 minutes of horde), earlier
than the blow-up because it costs the page nothing, and not from zero because the
opening minutes are where the ordinary body of each row is learned and a red one
has nothing to be read against.

**And it is a doctorate's**, gated by the course's own `fury` dial rather than by
a rung named in the spawner: 0 on the first three rows and 60 on `PHD`. Zero is
how you spell "never" for something metered — a meter that never climbs is a
chance that never comes up — so the ladder stays one table of numbers, and the day
fury is worth having lower down it is one `0` becoming a `20`. The boss is guarded
out, and for once not for the pair's reason (an eye has no size left to grow
into): it would take a fury perfectly well, and may not because the fight is a
fixed thing you have learned. A boss a quarter quicker across its box, hitting for
half again, on some runs and not others is the one encounter whose rules changed
behind you.

**The mark is derived from the art, never authored** (`pixelart.twoTone`). The
fill is the commonest mark *inside* the drawing — pixels whose four neighbours are
all opaque — which is two decisions. Commonest rather than lightest, because a
blot is ink with two pixels of paper in it and a two-pixel highlight is not a
body; and inside, because this game outlines everything, so counting every pixel
gives the majority to the *edge* and turns a bat and a grin inside out. A fixed
colour-for-colour map cannot work at all: `o` is the fill of a blot and a drop and
the detail of the other eight, so any table either leaves the ink-bodied rows
unchanged or blacks out everyone else's eyes. Deriving it instead means every kind
added later is enrageable the day it lands, and a page's own reskin of the crowd
(`Sprites.enemySkins`) enrages its own art — the same bargain the four offset
masks of an outline make.

Two tones cannot keep three, and the bestiary pays for that in exactly one place:
the eye and the red-eye are the same eleven pixels and differ only in the colour
of the pupil, so enraged they are the same body. What still tells them apart is 34
against 9 on their legs, which was always the louder half of that distinction.
The twin is baked at the first ask and cached on the sprite it came off (`Sprites.
enraged`), so a run that meets none pays nothing and a skin's patched origin is
already in place when it is built.

**`reach` scales what a standout throws.** `Spawner:scale` sets `out.reach =
out.grow or 1` past all three branches, so it tracks the drawing exactly and is a
restatement of `grow` rather than a fourth thing to tune. It is a separate field
because `grow` is a *sprite scale* and the whole-pixels rule allows it only whole
numbers, where this is a plain multiplier on distances; reading `grow` at a blast
radius would weld a drawing constraint onto a geometry one. `Enemy.new` bakes
`reach` and `burstRadius` alongside the damages, so what a bulb goes off at is
what it walked on with.

Where it is spent, and nowhere else:

| | |
|---|---|
| bulb's blast | `e.burstRadius` in `Game:burstEnemy` (was `burst.radius`) |
| bulb's wet | `Puddle.new(…, e.reach)` — the arena clamp reads the scaled width too |
| pellet | `radius = (shot.hit or 3) * e.reach` and `grow = e.grow` on the shot, `Game:fireEnemyShot` |
| tear + its wet | same two fields plus `wetReach`, `Game:throwTear` |
| boss trail | `Puddle.new(…, e.reach)` |
| split throw | `split.spread * e.grow`, `Game:splitEnemy` |

`Puddle.new(x, y, def, damage, seed, reach)` takes it optionally and defaults to
1, exactly as it already takes `damage` rather than reading `def.damage` — a blot
keeps the numbers it was dropped with. The pellet's hitbox and its drawn size come
off the same multiplier deliberately: art that lied about a radius is the one
unfair thing this game will not do. The tear and trail rows are dead weight today
(only `bosseye` has them and the boss is guarded out of both rolls) and are wired
anyway, because a line is cheaper than a branch and the day another row cries it
is already true.

**What `reach` does not touch is *when* or *where from*.** `shot.range`,
`shot.speed`, `shot.every`, `shot.spread`, `shot.arc`, `charge.*` and `keep.at`
are the numbers on the row for every arrival. A giant eye fires a bigger pellet
from the same distance on the same beat — one new fact to read rather than four.

Measured, on the two rows that have any of it:

| | plain | champion ×2 | giant ×3 |
|---|---|---|---|
| bulb body radius | 5 | 10 | 15 |
| bulb blast radius | 26 | 52 | **78** |
| bulb wet radius | 11 | 22 | 33 |
| eye pellet radius | 3 | 6 | 9 |

The 78 is worth a second look before it ships: the canvas is 320×180 at its
narrowest, so a giant bulb's blast is 156px across — half the screen wide and
most of it tall. That is one hit of ~28 through the invulnerability window on the
rarest arrival in the game (a blow-up roll *and* the bulb's 3-of-37 weight, so
well under one in a thousand), and it is the intended shape of "where you clear
the crowd is a decision" taken to its extreme. If it proves too much, the number
to bend is the blast and not the pellet — a hitbox has to match its art, a blast
radius does not, so `out.reach` could go sub-linear (`1 + (grow - 1) * 0.5` gives
39 and 52) with a second field for the projectiles.

**A blow-up that splits leaves something else.** `Game:splitEnemy` reads
`split.blown` — what a *blow-up* of the row leaves instead of `split.into` — and
hands those children the **run's** own scale rather than the parent's.
`Enemy:isBlown()` (`self.grow > 1 and not self.elite`) is the one question
anything asks about which roll produced an arrival, and it is why `Enemy.elite`
still exists now that no rim reads it.

The blot is the only row that wants one. At ×3 its drops would come off at ×3 too
— a body wider than a grin carrying 2 health, which reads as debris rather than as
three more fights — so a giant blot leaves three **ordinary blots**, and those
split as blots do: one giant is three blots is nine drops. The cascade cannot run
away, because the children carry no `grow`, so `isBlown()` is false on every one
of them and the second generation takes the plain `into`. Three levels, never
four.

That is the one place the "what came off a monster is as hard as the monster was"
rule is broken on purpose. The cost is bounded by whatever health the horde gained
while the parent stood on the page; what it buys is not carrying a second,
unmultiplied scale on all two hundred bodies to serve one row. A champion blot is
unchanged and still hands on its own scale — three ×2 drops.

**Four things wear an outline** — and no *arrival* fact is one of them: a size is
already the sentence, and fury says itself with the whole body (**Fury**). All four are the same four offset `drawMask`
calls (`outline` in `src/enemy.lua`), and the offsets stay one pixel whatever the
body's scale: the rim is a word rather than a decoration, so it has to look the
same on a bat as on a grin three times the size of one. Drawn *under* the body so
what they say is "that one" about something that still reads as what it was, and
in this order so each overwrites the last: sun-bleached (graphite), struck by
lightning (blue), winding up or dashing (red — blinking during the wind, solid
during the dash, which is the whole tell), just hit (red). The champion's ink used
to head that list and was the one entry on it that was not a state or an event;
with it gone, every rim an enemy can wear is something happening to it or being
done by it. `Enemy:outlineColour` ranks them and answers once; `Enemy:drawSolid`
reads the same answer, so the blank stamped into the page grows by the same pixel
and no outline leaves a paper rim.

**Health is a per-minute curve, damage is a per-cycle step, and speed is an
approach to a ceiling.** `Spawner:scale` returns the multipliers everything on the
page is priced with — three of them now, health, damage and how fast it walks —
and all three are read in different units on purpose. hp is `HP_PER_MINUTE` (1.15)
to the power of `Spawner:minutes` — cycles completed plus how far through this one
we are, times ten — less the first minute, which `HP_GRACE` (60s) leaves flat.
Damage is `DAMAGE_PER_CYCLE` (1.18) to the power of cycles completed, and steps
once. Speed is `1 + SPEED_MOST × (1 - 0.5 ^ (minutes / SPEED_HALF))` — 18% over
the row's own number, half of what is left of that gap every six minutes, and
never the whole of it.

| minute | hp × | a blob | hits from a 4-damage pencil |
| --- | --- | --- | --- |
| 1 | 1.00 | 4 | 1 |
| 5 | 1.75 | 7 | 2 |
| 10 | 3.52 | 14 | 4 |
| 15 | 7.08 | 28 | 7 |
| 20 | 14.2 | 57 | 15 |

Four things hang off that, and none of them is a branch anywhere:

- **The minute is the unit the player is reading** — it is the clock in the HUD —
  so the steepness of the health curve can be checked against what is on screen.
  Damage cannot be continuous for the opposite reason: a blob that hits for a
  fraction more every minute is a blob nobody can learn.
- **`Spawner:minutes` is minutes of *horde*, not of the run.** `Spawner:progress`
  sticks at 1 while the eye is up, so the clock stops with it: an escort does not
  get tougher over the minute you spend on the boss, and a slow fight does not
  hand the next cycle a stronger horde as a penalty. In a first run the two
  clocks are the same number; after that the horde's runs a boss fight behind.
- **There is no step at the cycle join**, because the exponent never restarts —
  the same reason the old per-cycle version had none.
- **Speed cannot compound and does not.** hp can climb for ever because a tougher
  blob is a longer fight; a blob quicker than the player is not a longer fight, it
  is the end of the only counterplay the whole horde has, which is that you can
  leave. The margin is thin — the fastest walker in the game is the bat's 38
  against a player's 58 — so an exponent as small as 1% a minute draws the two
  level by minute 32 and 1.5% by minute 21, cycle four and cycle three, both
  inside an endless run. Measured against a player who does nothing but run away,
  1.5% a minute has a doctorate's cycle three touching him two thousand times a
  minute. Hence the approach rather than a climb, and hence its two properties:
  there is no minute at which it stops (a capped exponent goes flat around minute
  seven, which reads as the game giving up), and **the ceiling is on the ramp and
  not on the product**, so it multiplies the course's `speed` instead of
  competing with it. A ceiling on the product deletes that dial — every class
  would arrive at the same top speed, a doctorate merely sooner.

  | minute | speed × | a bat, at high school | at a doctorate |
  | --- | --- | --- | --- |
  | 0 | 1.00 | 38 | 42.6 |
  | 6 | 1.09 | 41 | 46.4 |
  | 20 | 1.16 | 44 | 49.5 |
  | 60 | 1.18 | 45 | 50.2 |

  Against a player's 58, and 50.2 is where a doctorate's bat converges — 87%, and
  it never gets past it. The lunge keeps its own invariant too: 165px a second for
  0.42s is 69px of a 96px trigger range at the row's speed and 92 at the top of
  everything, so a wad's charge closes distance and never crosses its whole range
  in one go.
- **The eye is off the health curve and on the speed one.** `kind` is the third
  argument to `Spawner:scale` and the only thing it changes: a row with `boss` is
  priced at `BOSS_HP_PER_CYCLE` (1.4) to the power of the cycle, which leaves the
  first eye at exactly the 1260 its half-minute fight was measured against. A per-minute
  curve would have handed it 3170. It is read there rather than as a field on the
  row because it is not a fact about the monster — it is which *curve* an arrival
  is priced on, and that is the one function that prices an arrival.

A further thing hangs off it and is not in the table: **the course multiplies both
ends of the health curve and neither end of the damage step** (see **Courses**).
`hp` is a flat factor on the whole thing and `ramp` steepens the exponent, so a
doctorate's blob is 8 in the grace minute and 40 by the eye. The damage step is
untouched at every rung, and `speed` is the one dial the run and the class both
turn — the class buys 4% a rung at every minute, the minute adds its approach on
top, and the two multiply. Neither *size* an arrival can be has an opinion about
any of it: a champion is deliberately not quicker and a blow-up deliberately not
slower, which is why `out.speed` rides out past all three branches of the
function. **Fury** is the one arrival fact that reaches the legs, and it is
applied after those branches for that reason — on top of the speed all three of
them share, whichever one ran.

**Scaled health is rounded to a whole number and scaled damage is not**
(`wholeHp` in `src/enemy.lua`). What a player learns about a monster is how many
hits it takes, and at these sizes — a bat is 2 — an unrounded multiplier turns
that into a fraction they can only lose to: a blob on 4.14 takes two swings of a
4-damage pencil and nothing on screen says why. To nearest rather than down, so
the curve is not quietly discounted. Damage stays fractional because it is read
off a health bar, which is happy with one.

### Getting hit

**A hit is two things at once and they are one effect** (`HIT_*` in
`src/enemy.lua`). The body **blows out to paper for ~0.06s and drops back through
blush** over the rest of `HIT_FLASH` (0.14s) — two steps down the ramp, like every
other fade in the game, so it reads as a flash going off rather than a light
switching on. Paper is the page's own colour, so the first step draws a *hole* in
the shape of the thing; the red rim above is what gives that hole an edge, which
is why neither half works alone. And the body **kicks `HIT_BUMP` (3) pixels
backwards and slides home linearly** over `HIT_BUMP_TIME` (0.12s) — linear because
on a whole-pixel grid 3/2/1/0 is four held frames all going one way, where an
eased curve would spend most of them on the same pixel.

Both are **drawings and not facts**. The recoil is folded in by `Enemy:footing`
and never touches `x/y`: position is what every hit radius, both spatial hashes
and the separation pass read, and a monster you could miss by shooting it would
be the one unfair thing on the page. `footing` is also where the blank under the
body comes from, so the two can never drift apart. The shadow is drawn at the
unbumped position — it is on the paper, the body is what was hit, and the body
kicking off its own shadow is most of what sells the flinch.

**The direction comes off the thing that was hit, not the thing that hit it.**
`Enemy:hurt` is handed a number and nothing else by all thirty of its callers, so
it flinches backwards along its own heading (`headX/headY`) — it is walking at
you, so that is away from the hit for nearly every hit on the page, and it costs
those callers nothing. No heading at all (gathered on a spiral, hit on the frame
it walked on) jolts downwards, because a hit that moves nothing reads as a miss.

Neither half is a number on the row. A hit on a paper clip and a hit on the boss
are the same event — *something landed* — and how much it was worth is what the
damage number says (`src/damage.lua`). The death particles are separate and
unchanged (`Game:killEnemy`).

`Game:spawnEnemy(kind, x, y, scale)` takes an optional scale; left out it is the
run's (`Game:enemyScale`). Three callers pass one: the spawner (which may make it
a champion or a blow-up), and `Game:splitEnemy` (which passes the parent's).

### The purse

`src/purse.lua` is the other thing a run leaves behind, and it is the opposite
kind of thing to a record. A record is a fact about a *page* and a maximum; a
purse is a thing you **have**, one number for the whole book, kept in `purse.txt`
and loaded once in `Game:load`. It is not filed against a lesson because what it is
being saved for is in the canteen and the canteen does not care which page you
were on.

**`Purse.forRun(run)` is the one place the sum lives**, and it is four terms of
four different kinds at a rate -- the body count over `PER_COIN` (100) floored,
`PER_SKIP` (10) for every level the run sold back, `PER_GRADE` (1) for every rung
of the grade, `PER_EYE` (8) for every eye put down, and then the whole of it
multiplied by the course's `pay` (see **Courses**) and floored. The rate is a
multiplier rather than a fifth term because what a harder class is worth is
*everything you did* reckoned higher, where a flat bonus for enrolling would pay a
doctorate for walking onto the page. Read the payout through it and nothing else.

The grade arrives as the **rung** rather than as the letter, and the caller reads
`Mark.rung` for it. That is a require loop rather than a preference: a course
reaches the purse and `src/mark.lua` reads the spawner's own `BOSS_AT`, so a purse
that required `src/mark.lua` closed the ring. It is also the better layering --
the purse is arithmetic on numbers the run counted, and a letter is not one. It takes a *table* rather than a row of
arguments, which is how the last two were added without a line changing in
`win.lua`, `over.lua` or the canteen: none of the three knows what is in the number
it prints, so a fifth term is a field in `Game:runWorth` and a line here.

**`Game:runWorth(won)` is the one place the run is turned into those terms**, and
the grade it hands over is the grade the card prints -- awarded on a win, measured
off the clock otherwise -- so the letter and the figure under it are two readings of
one run. The rate comes off `self.course` rather than off `Course.current`, which
is the run-versus-pick split under **Courses**. `game.eyes` is counted in `Game:killEnemy`, where the eye going down is
already noticed, and a restored bookmark derives it as `cycle - 1`: a bookmark drops
the page and the eye standing on it, so whatever eye was up has to be shut again.

**`Purse.spend` is the only other way coins move**, and it refuses rather than
clamping -- a purse cannot be talked into going negative by a screen that measured
a price wrong, and the caller finds out by being told no. `Perks.buy` is its only
caller.

**A run is paid when it ends, and `Game:cashRun` is the one door.** It is
deliberately *not* `Game:bankRun`, though the two sit a line apart: a record is a
maximum and can be submitted from anywhere as often as you like, while coins add
up, so paying twice for the same kills is money made out of nothing. So it is
called from the two places a run actually ends -- dying, and `END` on the win card
-- which is the same pair that turns `Game.resumable` off, and **never** from the
pause card, since walking out does not end a run. `ENDLESS` is not an ending
either, and that is what keeps this correct with no watermark of what has been
paid: a run that shuts the eye at four hundred kills and dies at nine hundred is
paid once, for nine, and neither the win card's number nor a restored bookmark can
be paid for twice. Anything that adds a third way for a run to end has to decide
which of those two it is.

Which is also why a skip is banked on the run as a *count* (`Game.skipped`) rather
than paid into the purse when it happens: a level sold back is something the run
earned, and nothing a run earned is collected until the run has ended. A bookmark
carries the tally for the same reason.

`Purse.draw` is how a coin count is drawn, everywhere it is drawn, the way
`Mark.draw` owns a grade: the coin glyph (`Sprites.icons.coin`, 9x9) and a figure
beside it, centred as one pair. The *text* is passed in rather than a number,
because the same pair says two things -- `+3` for what a run earned and `3` for
what the purse holds. It only knows how to centre, so a screen that wants the pair
against an edge (the canteen's corner) centres it on the middle of the room it
takes. `scale` blows up all of it, gap included, through an integer
`love.graphics.scale` with the sprite unchanged inside it (the hero's trick), so a
screen that doubles the figure gets a doubled coin rather than a 1x coin standing
in front of it like a bullet point -- though nothing asks for that today.

The coin is filled **blush** with the figure in **paper**, and the two halves of
that are different kinds of decision. Blush is the red half of the palette, which
everywhere else means the other side of the fight -- but a coin is not in the
fight, it is a thing written on the page in the same red pen the lesson headings
and the grade are, so it is furniture and the palette's own exception for
furniture applies. Paper is the one colour that *covers*, so the figure wipes what
is under it while the fill stacks like any other mark: flat pink on a paper card,
and a rule crossing it on the page darkens the fill and leaves the 1 white. That
is the right way round rather than an accident of it -- the readable half of the
drawing is the half in the colour that erases.

### What the purse buys

`src/perks.lua` is the first of the three things the purse buys: lines you own a level of for ever
and spend a use of every run, bought on the canteen's `PERKS` section. It is the
fourth kind of thing in the save directory -- not a record of what happened, not a
drawing, not a setting, but a thing you *bought*.

The second is three of the four heroes (`price` in `src/characters.lua`, the
counter's `HEROES` section) and the third is the course ladder (`src/course.lua`,
the `COURSES` section, and see **Courses**). They are deliberately not one list: a
perk's level is a use a run spends, a hero's is a hero and a course's is a harder
book, so what a level *means* is different on each and the note under the counter
says which you are looking at. What they share is the five questions a price needs
answering -- `level`, `levels`, `priceOf`, `canBuy`, `buy`, about a key -- which is
the whole of what the canteen needs to draw a row.

**A section is a spread** (see **The book**), and the canteen is the one of the
three screens where the fold *decided* a layout rather than just receiving one.
The widest blurb on the counter is wider than everything else in a row put
together, so with the sentence in the words column a leaf cannot hold a row at
all: a spread would have degraded to prices with nothing saying what they buy.
Facing pages are what a book does with exactly that problem -- the goods on the
verso (icon, name, `n/n`, price, box) and the sentence facing each row on the
recto, with the two lines under the counter beneath them -- and it reads better
than the stacked version, the left page being the transaction and the right page
the argument for it. On one leaf nothing moves: the sentence goes back under the
name, and drops entirely on a leaf too narrow even for that, which is the
degradation order this counter has always had.

**`lay.stack` is the same trade on the counter, and it costs nothing down the
page.** A row is an icon, a name, `n/n`, a price and a box, and there are three
arrangements: `wide` (the sentence under the name, only ever offered where the
sentence is on this page at all, i.e. one leaf), `plain` (the same without it) and
`stack` (the name on one line, `n/n` and the price on the next, left and right of
the name's own column). `142px` of goods do not go into `141px` of leaf with a
margin left over, so a spread stacks. The luck in it is vertical: the box at the
end of a row is 20 deep and two lines of lettering are 12, so the second line goes
*inside* the height the row already had and a stacked counter is exactly as tall
as a flat one.

Two things follow from the fold. `Canteen:layout` places **every** section's boxes
and not only the section showing, because two spreads are real at once while a
leaf is in the air; and the boxes are drawn inside `drawPage` after
`Overprint.finish` -- out past the pass, so a paper-filled box is opaque, but
still inside the leaf, so a box goes round the fold with the row it is at the end
of. `Canteen:leaving` is hung off `Book.onTurn`: a box half scribbled in is
disarmed and a box still flashing a purchase is wiped as the page lifts, while
`self.choice` is still the section it was bought on.

**`spent` on the row is where the use goes, and there are two answers.** Three of
the four are spent on the draft and the fourth on the frame the run would have
ended, and that one field is the whole of what anything has to know about the
difference -- it is read in exactly one place, the draft's own button row
(`src/levelup.lua`), because a button that pressed would do nothing on that screen
is worse than no button at all. Everything else here, and the whole of the counter,
goes on treating a row as a name, a price list and a box.

**A level is a use, and that is the whole of the arithmetic.** REROLL at level two
means two rerolls in every run from now on and nothing else, which is exactly why
this is not a line in `src/upgrades.lua`: there a level is written as a function of
what it changes and one line can sell four different things down its length, and
here every level of every line sells one more of the same thing. So the catalogue
is three rows of prices and nothing else.

The three drafts are written to be three different answers to *these three cards
are wrong*, and keeping them different is the point:

- **REROLL** asks again -- three fresh cards off the same catalogue.
- **SKIP** withdraws the question and sells the level back for coins
  (`Purse.PER_SKIP`). It is the only one that pays, and the only place in the game
  a run turns something it earned into something the *book* keeps.
- **EXPEL** answers about one card rather than about the three: that line is out of
  the run for good (`Loadout:expel`) and one fresh card takes its place. The other
  two stay exactly where they are, which is the whole difference between this and a
  reroll -- expelling is an opinion about one card, so it may not quietly re-ask
  the other two.

And the fourth is not about a draft at all:

- **RETAKE** is spent the frame the health runs out. `Game:canRetake` is the one
  question and `Game:openRetake` is the one door; `Player:revive` is what it does
  -- half of `maxHp` back and a couple of seconds nothing can touch you for, both
  numbers living on `src/player.lua` because health and the invulnerability window
  are the two numbers that file owns. Nothing else about the run is touched, which
  is what a retake *is*: the page, the ink, the level, the marks and the tool in
  hand are all still yours and the only thing that changed is that the run did not
  stop. It is the first thing on the counter that changes how a run is *played*
  rather than what it is offered, and it is **two levels rather than three** --
  three is the length of a line spent on a three-card draft, and a run does not have
  three deaths in it.

  Two things about it are deliberate and easy to undo by accident. It is
  **not a question**: a card offering to spend the last life you bought weeks ago
  would be a question with one sensible answer, and a game that asks those teaches
  you that answering does not matter. And the grace is paid at the *right end* --
  the player is only stepped while the state is `playing`, so the second and a half
  spent reading the card is not a second and a half of the two seconds.

**The prices are set against three different things and that asymmetry is
deliberate.** They were struck when a run that reached the eye paid two to four
coins; it pays about twenty-four now (the grade and the eye, see **The purse**) and
they were deliberately left where they were, so these four lines are the near end of
a counter that is going to grow rows locking parts of the book behind them. The
reroll and expel lines are priced off that old number -- a first one is a middling
run now rather than a couple of good ones. The skip line is priced off what it *pays* instead: ten coins a skip
is a whole run's kill payout several times over, so a skip line priced like the
other two would be bought once and never cost anything again. Priced at what three
skips a run bring in over a handful of runs, buying it is a bet on playing that way.
Move `Purse.PER_SKIP` and those prices move with it. And the retake line is priced
off neither, because what it sells is not a better draft but a second run: 20 and
45, so the first one is most of an afternoon's coins and the second is dearer than
the whole reroll line. It is meant to be the thing you are saving up for rather
than the thing you pick up on the way past. A hero is priced off none of the three
and against the other heroes only: one number for all of them (`PRICE`, 40), since
none of the three is better than the others and a rising price would say one was.

**Where each half lives.** `Perks.list` is the catalogue and the file;
`Perks.forRun` hands a run a fresh count of uses, and only for the lines that have
been *bought* -- a line nobody owns is absent rather than zero, which is what keeps
a book that has never been to the canteen from putting grey buttons on every
draft. What a run is carrying is one table whatever any of it is for, and `spent`
is only ever asked about by the screen that would draw a button for it. `Loadout.banned` is what a run has thrown out and `Loadout:candidates` is
where it is applied, so a ban is one fact about what the draft may reach rather
than a filter each deal has to remember; the endless padding in `Loadout:roll` is
under the same rule, or a reroll's fourth card would be the line just expelled. A
ban deliberately does **not** give back the levels already taken: expelling is a
refusal of the *rest* of a line.

**The buttons on the draft** (`src/levelup.lua`, up to three of them -- the lines
whose `spent` is `"draft"`) are `Hud`'s own box drawn
through `Hud.drawButton` -- the *tool selector's* (`Hud.SEL_SIZE`, 13) rather than
the corner button's (11), since what stands in one is a tool-sized 11x11 drawing --
and they are **pressed rather than answered**, on a screen where everything else is
a box you scribble in.
That is not the exception it looks like: pressing one does not answer the question,
it changes what the question is. REROLL asks again, SKIP withdraws it, and EXPEL
turns the three boxes from three ways of saying yes into three ways of saying never
again -- so the one part of it that cannot be taken back is still taken the only
way anything on that screen is taken, by scribbling a box. Which is also why EXPEL
is the only one that *arms* rather than acting on the press: it is the only one
with a target.

They sit in the bottom corner **opposite the thumb stick** (`Hud.toolSide`), the
tool column's own ergonomic rule, and the row reads *out of* that corner so the
first of them is nearest the thumb whichever corner it is. `BTN_EDGE` is wider than
the corner button's own margin because this is three thumb targets in the corner a
thumb comes at from off the screen, where that one is alone at the top of the page.
It is struck off `Hud.xpTop` rather than off the safe inset: the experience bar
runs the whole width of the foot of the page, so the bottom of the safe area is a
readout and not free page, and these are the widest touch targets in the game --
the finger reaching for one would land on the bar five pixels before the box.

**The card stack is not told about them**, and that is a decision that was made
twice. They were given a height reserve at first, and it meant a run that had been
to the canteen read its cards a dozen pixels higher than a run that had not -- where
the question sits on the page depending on what was bought weeks ago. The cards are
the question and they get the middle of the page in every run. What it costs is the
corner: on a short screen with a long carry row the buttons sit close under it, and
they win because they are drawn last. Both are centred and the buttons are hard in
the corner, so they do not actually meet at any shape the game is handed.

A button with no uses left is drawn grey with its icon as a silhouette rather than
dropped, since a row that shrank as it was spent would move the buttons beside it.

**Nothing in `levelup.lua` knows what any of it costs.** It hands back a word and
the line the word is about -- `"take"`, `"expel"`, `"reroll"`, `"skip"` -- and
`Game:rerollDraft`, `Game:skipDraft` and `Game:expelLine` are what those mean,
which is the same split the cards are already under. All three take the use first
and unconditionally: a use spent on a deal that turned out no better is still a use
spent, and a perk that only charged you when you liked the result would be a perk
with no decision in it.

Two guards, both about not stranding a run on a screen with no way out: EXPEL
refuses to throw out the last card on the table (`LevelUp:usable`), and a reroll
whose roll comes back empty leaves the cards where they are.

**The way back off the counter** is `src/refund.lua`, the canteen's third section:
everything bought on the other two handed back at exactly what was paid for it, and
the coins returned to the purse through `Purse.earn` -- the same door a run's payout
comes in by, because a coin is a coin however it arrived.

Four things about it are decisions rather than conveniences:

- **One row rather than a row per thing.** A counter you could unpick a level at a
  time is a counter you would *shop* on -- buy the second reroll for one afternoon
  and sell it back for the next -- and the perk prices are written against a line
  you commit to rather than one you rent. All of it or none of it is not a trade;
  it is the sentence "start again", which is the only thing anybody wants from
  this.
- **No fee and no rounding.** The two things a refund could be are a decision you
  take back and a tax on having changed your mind, and this game does not charge
  for the second. A refunded book is exactly the book you would have had if you had
  walked past the counter.
- **It hands back purchases and never records.** `Characters.times` stays where it
  is, so the five minutes that took the starman's line out of his hands and into
  everybody else's draft (**The collection**) survive the refund. A refund must
  never be a way of *losing* an unlock, which is the one thing here worth guarding.
- **A run already under way keeps its uses.** `Perks.forRun` hands a run a fresh
  count when it starts and nothing is ever taken off a run once it is carrying it,
  which is the collection's own rule kept rather than made an exception of.

It answers the same five questions a perk row does, so the section costs the canteen
nothing: `level`/`levels` are how much of the *counter* is owned out of how much
there is (red at the top of the column, like a full line), `priceOf` is what would
come back, and `canBuy` is whether there is anything to come back. The one thing the
screen is told about it is `back` on the row, which makes the figure read `+40`
rather than `40` -- the sign the two end cards' payouts wear, since it is money
going the other way. It is a section rather than a row at the bottom of one because
it is about both of the others at once, and `SECTIONS` grew two optional lines
(`touch`, `shut`) for the same reason: COME BACK WITH MORE COINS is true of a
counter and nonsense about a refund.

### The book

`src/spread.lua` is the three back pages read as a bound book: two leaves side by
side with a crease down the middle, and a leaf you turn with your finger. The
library, the canteen and the homework page each hold one `Spread.new()`; nothing
else in the game does.

**A section is a spread, not a page.** All three screens step a fixed list of
sections (`KINDS`, `SECTIONS`, `Challenges.sections`) with `<` name `>` in the
footer, and that stepping used to be a cut -- one thing on one frame and another
on the next. It is a page turn now, and each section is laid across two facing
leaves: the library's index on the verso and the entry it opens on the recto, the
canteen's goods on the verso and what they do on the recto, the homework page's
ten rows split five and five. `Book:leaf(1)` and `Book:leaf(2)` are what a screen
lays out into, and they answer with the **printable** rect -- `INNER` of gutter
margin off the spine side of each and `OUTER` off the other, so the two are the
same width and are mirror images about the fold.

**The margins are the book's and not a screen's**, which is what stops three
screens quietly printing to the edge of the paper. A leaf is half a page, and
every one of these layouts wanted the room back: the answer is that a row may have
as many lines as it likes and may not have the margin. Both the canteen and the
homework page pick between two or three arrangements of a row -- flat, then with
one thing dropped under another, then fully stacked -- and take the widest that
fits. See those two sections; the library needed neither, its two blocks being a
page each already.

**A leaf that has no room is not a leaf.** Under `MIN_LEAF * 2` of page (a phone
held upright) `Book:spread()` is false, both leaves answer with the whole page,
and every screen falls back to the stacked layout it had before there was a fold.
That is the only branch a screen carries.

**The geometry is three numbers and one integral.** The sheet stands at `mid`,
bows by `phi` over its length, and so runs from `psi = mid - phi/2` at the root to
`mid + phi/2` at the free edge; a point `u` along the paper lies at
`theta = psi + phi*u`, and

    x(u) = W * (sin(theta) - sin(psi)) / phi

is where it has got to across the page. `cos(theta)` is how square-on it is, which
decides both which face you are looking at -- the front while it is positive, the
back once it is not -- and how much light it has. `mid` is `acos(1 - 2p)` rather
than `p * pi`, and the bow hangs either side of it rather than off the root, and
both are there for one reason: **the free edge has to go where the finger goes.**
Bent away from a root at the drag angle the sheet projects far wider than the drag
asked for, so the page hangs back and then whips across at the end.

**It is blitted a column at a time**, every column one whole pixel wide at a whole
pixel position, which is the only way to bend a page without breaking **Whole
pixels only, never at an angle** (see the rules at the top of this file). There is
no perspective and no vertical foreshortening; the bend is entirely in which
source column lands where. Columns are walked root first, which is back to front:
the far end of a bowed sheet is the end nearest you, so where the bend has folded
it back over the near end, the columns that arrive later are the ones in front.
That loop order *is* the hidden-surface solve.

**Shading steps down the palette and dithers between rungs.** `Palette.overprint`
already says what a colour becomes one rung darker (its ruled-line column), so
that is the ramp, walked twice -- with one exception: paper, which that table
leaves alone because an eraser does not stack, and which shade must darken to
graphite or nothing between the rules gets darker at all. Fractions of a rung are
paid in pixels through a 4x4 ordered comb, because there is no colour between
paper and graphite and never will be; quantised to three flat bands a bending page
came out as three grey slabs with straight edges. The crease itself is the same
idea in Lua rather than in a shader: graphite dithered off a 4x4 comb, drawn
**inside** the ink pass so it prints -- graphite over a ruled line is slate, so the
gutter darkens the ruling and the paper under it together, which is the difference
between a fold in a page and a grey stripe drawn on one.

**Two canvases, and only while a leaf is moving.** `Book:draw(game, page)` calls
the screen's `page(section)` straight onto the screen at rest, and into `bufA` and
`bufB` mid-turn -- `Overprint.finish` puts its result back on whatever canvas was
set when the pass opened, so setting one is the whole of rendering a spread
off-screen. Both are redrawn every frame rather than frozen at the grab: these
pages have ink fading off them and lettering that wobbles. The four faces of a
turn come out of those two buffers as sub-rects -- under the sheet, the verso of
one spread beside the recto of the other; on it, the face you are leaving on the
front and the face you are going to on the back. That is a real leaf, and it is
why a moment of every turn shows one page of one section beside one page of the
next.

**What does not turn is not on the page.** Each screen's `drawPage` is one whole
overprint pass holding only what belongs to the leaf; the heading, the corner
count, the footer, the arrows and the corner button are drawn after `Book:draw`
returns and stay put. That split already existed for a rendering reason (see
**Draw layering**: a box filled in `Palette.paper` has to go out past the pass or
it reads as a transparency), and the page turn is what made it load-bearing.

**The gesture.** Everything here is drawn on, so every press is read as a line or
a turn and the reading is over in the first few pixels. Within `GRAB` of a leaf's
outer edge it is a turn on the frame it lands -- that is where a hand reaches for
a page and the one strip of these screens with nothing printed on it -- and which
edge decides which way. Anywhere else it is undecided for at most `SLIP` pixels of
travel or `HOLD` seconds: sideways and it is a turn, anything else and it is a
line. While it is undecided the pen lays nothing, which is what the gesture costs.
The bias is towards the line, deliberately: a page turn is fast and a drawn line
usually is not, and where the two are confusable there are still two arrows and
two page edges. `Book:eating()` is what a screen's `mark` and `press` ask.

`Book:track` is called once a frame **ahead of the pen**, so the frame a stroke
becomes a turn is a frame the pen lays nothing. Let go past halfway, or fast
enough to be a flick, and the turn finishes itself; short of both it runs `p` back
to 0 and the sheet is drawn coming home. `Book:at` -- the section every screen
reads -- only moves when the leaf **lands**, so nothing a screen measures moves
under it while the page is moving, and the footer names neither page halfway
through. A screen with something live on the page it is leaving hangs it off
`Book.onTurn`, which fires as the leaf lifts: the canteen disarms a half-scribbled
box there, the library drops its picks and its `EVOLUTIONS` mode.

### The library

`src/library.lua` is the catalogue written out, reached by the timetable's
`LIBRARY` tab and handed straight back to it. It is the one screen in the game
that **asks nothing**, and that is the whole shape of it: the draft deals three
cards out of a hundred and fifty-nine levels and never mentions the rest, so without
this the catalogue is only learnable by being dealt it.

Nothing here is a `Scribble` box, because a box is a thing you cannot take back
and there is nothing here to take back. Everything is *pressed* — a name, an
arrow, the corner button — which is the timetable's tab rule applied to a screen
where looking is all there is. Ink that lands anywhere else is still ink and still
fades (`Scribble.newMarks`), and a mark on a name, an arrow or the corner button is
dropped exactly as the timetable drops one on a tab.

**A section is a spread** (see **The book**): the shelf on the verso and the
entry it opens on the recto, which is what a reference book has always done with
exactly this pair of things. Where there is only one leaf -- a phone held upright
-- they stack, the shelf above and the entry under it, which is where they both
were before there was a fold. `lay.blockX`/`blockW` are the shelf's leaf and
`lay.entryX`/`entryW` the entry's, and they are the same pair of numbers in the
one-leaf case. The arrows turn a leaf and so does a finger dragged across the
page; `Library:leaving` is hung off `Book.onTurn` and is where the index, the
picks and the toggle are dropped.

Four blocks, and the split between them is what holds the page still:

- **The shelf** is every line of the section, `Sprites.icons` plus the name, in as
  many columns as the page takes (one is the floor, which is a phone in portrait) —
  bar the fusions, which `build` sorts out of the shelf and into `fusions` off
  `up.fuses`. Pressing one is `Library:select`; the picked name is the only one in
  red. It is ordered by **when the book gets the line**, not by catalogue order —
  see the third layout rule below.
- **The entry** is the picked line in full: its icon and name at `NAME_SCALE`, then
  one numbered row per level in the order they are taken. The numbering is the
  point rather than decoration — a card shows you one level, and what a *line* is
  is the shape of all of them. `Library:drawLine` writes out whichever line it is
  handed and `Library:drawEntry` decides which that is, because there are two ways
  to arrive: a name on the shelf, or a pair of picks.
- **The footer** is `<` the section `>` plus one hint line, pinned to the foot of
  the page rather than centred with the rest. The arrows are the studio's roster
  recipe and the studio's job (`Library:arrowBox`/`arrowAt`/`step`): two boxes
  either side of the name of the thing they step.
- **The toggle** is the word `EVOLUTIONS` at `lay.evoX`/`lay.evoY`, in the footer's
  bottom-left corner and level with the arrows. Page lettering rather than a box,
  pressed the way a name on the shelf is, and drawn only where `Library:evolvable`
  says the section showing has something that fuses. See **Evolutions in the
  library** below.

Three layout rules, and the last two are the ones that will bite if they are
changed:

- Column width is the widest name in the **whole book** and the footer arrows are
  struck off the widest section name, so nothing across the page moves as an arrow
  is pressed. The shelf is reserved at the **fullest section's** row count
  (`lay.rows`) for the same reason down the page: the three sections are three
  lengths, and a shelf measured to itself would start the entry — icon, name at
  `NAME_SCALE`, every level — somewhere different on each one.
- **The page is read from the top down, not centred.** Everything on it is a list
  whose length the catalogue decides, so there is no block to centre that is the
  same height twice, and a page that recentred itself would move the heading and
  every name on the shelf each time an arrow was pressed. It also buys back the room
  a centred page was spending: centring against the fullest section reserved the
  worst of two shelves that pull opposite ways — the passives are the fullest list
  with the shortest entries, the weapons the emptiest with the tallest — and on a
  squarish window that reserve was the difference between the last level of a line
  being on the page and being cut off it. Nothing measures `rewrap`'s output any
  more; `lay.entryBottom` is the backstop for a page short enough that even reading
  from the top overruns the footer.
- **A shelf is ordered by when the book gets the line, and it never resorts.**
  `shelfOrder` sorts each `shelves[i]` on `Collection.rank[up.id]` — a line's place
  in the one list of gates (`Collection.gates`) — with the catalogue index as the
  tiebreaker, since `table.sort` is not stable in LuaJIT. A free line has no rank,
  so the whole free block lands on top: the shelf is not sorted into open and shut,
  it is sorted by *when*, and never having been shut is the earliest when there is.

  Both keys are facts about the catalogue rather than about the register, so the
  order is the same on run one and run four hundred and it is computed once in
  `build`. That is the point rather than an optimisation. A shelf ordered by what is
  *currently* open would rearrange itself under the finger of the player who just
  filled a hole in it — the layout rule above, broken at the one moment the player
  has most reason to be looking at the page.

  What it buys is a shelf that answers two questions in the order you ask them:
  what can I be dealt today (the block on top) and what is coming, in what order
  (the block under it). It also groups the derived gates for free, since they are
  appended to `Collection.gates` in blocks — the tools shelf reads as the two the
  quests hand over, then the scissors, then the seven the timetable does, and the
  weapons shelf ends on the three that belong to heroes you have not bought.
  `fusions` is deliberately **not** sorted: it is not a column, nothing indexes into
  it but `Library:pairing`'s scan, and all 45 are shut on a fresh book anyway.

The heading is the one thing that sits *level with* the corner button rather than
below it, and it can because it is centred on the page while the button is out in
the margin — dozens of pixels apart on every page the game is handed, with a guard
in `Library:layout` for the narrow page or long heading where they would meet. It
is worth the guard: starting the title under the button cost the whole page that
height, which on a tall screen put the title a fifth of the way down a page it is
the top of. The shelf still clears the button either way.

Everything is drawn on the page inside the overprint pass except the two arrows
and the corner button, which are boxes lying in the margin and go out past
`Overprint.finish()` with the timetable's tabs and for the same reason. The page it
is drawn on is whatever lesson you opened it from — the book is still open there,
you have turned to the back rather than closed it.

#### Evolutions in the library

A fusion is not a line the draft can deal (see **Upgrades**), so it is not on the
shelf. `EVOLUTIONS` is where it is instead, and the whole of it is five short
pieces:

- `build` puts a row with `fuses` on it into `fusions` rather than into
  `shelves[i]`. Off the field rather than off a list of names, so a new fusion is
  behind the toggle by existing — and still filtered by `toolLive` on the way past.
- `Library:evolvable` asks whether any fusion shares the showing section's `kind`,
  which is what decides whether the toggle is drawn and whether `evoAt` answers at
  all. Written that way rather than as "section one" so a weapon that fuses one day
  takes the toggle to the weapons shelf.
- `Library:pick` keeps two and no more, and a third press replaces the **second**:
  every fusion today has a *carrier* in it — the compass, the pushpin, the ruler or
  the pencil — so the gesture the screen is for is holding one of those four still
  and running down the shelf against it. Pressing a picked
  name takes it back off, which is the only way to move the first. The sentence was
  written when there were two carriers and it has survived a third and a fourth
  without a line changing, which is the test of it: what the rule actually says is
  that the *second* pick is the cheap one to change, and that is true of any
  catalogue where fusions cluster on a few parents rather than spreading evenly.
- `Library:pairing` matches the two picks against each fusion's `fuses` — not its
  `needs`, since the catalyst is what the entry already writes out on its own — and
  counts over the fusion's own list rather than comparing two ids both ways round,
  so a three-line fusion is never answered by two of them.
- `Library:drawEntry` writes out what came back, or one graphite sentence: `PICK
  TWO TOOLS`, or `NOTHING COMES OF THESE TWO`. Graphite and not red, because
  neither is a demand — the red on this page is spent on where you are reading and
  on what a locked line wants.

The picks are marked on the **icons**, in blush, by forcing `Hud.drawIcon`'s plate
(see **Upgrades**): red on this page already means where you are reading, and blush
already means fused, so a picked tool going pink is the fusion's own colour one step
earlier. Nothing on the shelf is a fusion any more, so the forced plate can never
collide with an automatic one — and it is forced even on a line the book has not
opened, since which two you picked is not a thing a lock has business hiding.

Two things it deliberately does **not** change. `rewrap` is keyed by the line's own
id rather than by section and index, because a fusion has neither. And `tally`
counts the fusions along with the shelves: what the count in the corner counts is
the book, and a collection that appeared to shrink by every fusion in the game
because a screen was rearranged would be lying about the save — and would go on
quietly shrinking every time one was added.

The toggle goes back down in `Library:step`, along with the picks: the mode belongs
to the shelf it was thrown on, the picks are indices into that shelf, and two of the
three sections have nothing to pair. It is `E` on a keyboard, with `RETURN`/`SPACE`
picking the name the cursor is on — two presses rather than one, since arrows that
picked as they passed would hand the book a pair nobody asked for on the way to the
one they wanted. `lay.evoX` reserves nothing and needs to: the widest translation is
eleven letters at 43px, and the left arrow is struck off the middle of the page with
the widest section name beside it, which leaves 12px between the two on the
narrowest page the game is handed (180 across) and most of the page on anything
wider.

The endless lines (`Upgrades.endless`) are deliberately not a fourth section: they
are seven variations on lines that already have one, with no last level to list.
Anything added to `Upgrades.list` turns up here on its own, in catalogue order,
with no change to this file — a tool line whose tool has been shelved is the one
thing filtered out (`toolLive`), so the library can never promise something the
draft cannot deal.

**Three quarters of the shelf is a hole** on a fresh save — 9 lines of 36, the
whole tools shelf included — which is what makes this a collection rather than a
catalogue (see **The collection**). A line the book has not opened is drawn as its own silhouette in
graphite — `icon:drawMask`, the draft's grey button and the bomb's fuse — with its
name in graphite beside it, and its entry is two phrases and a figure instead of its levels: why there is
nothing to read, in graphite, and what to go and do about it, in red
(`Collection.why`), and then how far along that demand you are, in slate
(`Collection.meterOf` -- `3966/4000`, or `7:30/9:00` for a stretch of time).
There is a blank line between the first two, so the demand reads as an answer to
the head rather than as the rest of the sentence, and none between the last two,
because there they *are* one sentence: what is owed and what has been paid off it.
The figure is simply absent for a gate with no meter -- a lesson tool, a hero's
weapon, a fusion -- which is honest rather than a gap, since a page is sat or it
is not. It lived on a screen of its own until recently, and that screen was this
one's seventeen rows listed again to carry one column (see **Homework**). The levels are the reading a lock takes away, so a locked entry
may not list them; the *name* is deliberately still there, since a shelf of question
marks is a wall and what makes a hole worth filling is knowing the shape of it. Red
still means *this is the one you are reading*, locked or not.

All three are wrapped to the block the way a level's own text is, since the
lesson tools' demand is the longest string on this screen and a phone in portrait is
one column wide. And they are assembled at the *draw* — `I18n.t(key):format(arg)`,
never the other way round, and a lesson's name in the slot is itself translated.

The count (`9/36` on a fresh save) hangs in the top right at 1:1, level with the corner button —
the canteen's purse readout in the canteen's corner and for the canteen's reason —
so the heading's clearance guard now steps below *both* corners rather than one. It
is measured off four figures rather than the two showing and goes red when there is
nothing left to find, and it is counted over the shelves rather than over
`Collection.gates`, since those are what decide what is in the book at all.

**It counts what the screen is showing**, which is the shelves down and the fusions
up (`Library:tally`, following `self.evo`). One figure per mode rather than one over
everything, because the two halves fill at completely different rates: the 36 open
one at a time and the 45 come in a flood, nine at once, every time the tool shelf
grows. Added together they were a number that said nothing about either — and,
before the fusions were gated at all, a number that read 51/81 to a fresh book whose
draft could reach nine. `tallyWidth` is a max over both modes so the heading's guard
never moves when the toggle is pressed.

`Font.wrap` lives in `src/font.lua` rather than here because the draft wants the
same greedy break; two copies of it would be two places for a character to be
counted differently.

### The collection

`src/collection.lua` is which of the catalogue the book has opened, and it is the
other half of what the library is for: the draft deals three cards out of eighty-one
lines, the library reads them all out, and this is what makes seventy-two of them
something you arrive at rather than something that was always there.

**It is keyed to `src/records.lua` and has no file of its own**, and that is the
shape of the feature rather than a saving. Every number in the register is a
*maximum*, so an unlock read off one can never be taken away, can never disagree
with anything and costs nothing to keep in step -- there is no owned-set to write and
no order to replay. `Records.best` is one of the two reads: the longest run
anywhere, the biggest body count on one page, the most bosses one run put down, and
how many pages have had one put down (`beat`). `Records.sat` is beside it, counting
pages sat out, and `Collection`'s cached `register()` folds the two into one table
on one stamp so `met` has one place to look. The other read is `Records.get`, one
lesson at a time, which is what a `lesson` gate asks -- nine minutes on every page
in the book is not ten minutes on any of them, so that one may not go through the
best of them. The register grew the boss count for this (a third number on the line,
optional on the way in so an older file reads as a book that never put one down),
and `Records.stamp` is what lets the answer be held between the hundred times a
frame the library's shelf asks for it.

**`Collection.has(id)` is the one door.** `Loadout:candidates` asks it beside the
ban `EXPEL` leaves and for the same reason -- what the draft may reach is one list
and one question, not a filter every deal has to remember -- and the clause to
preserve there is `level > 0 or Collection.has(...)`: a line the run is already
carrying is offered its levels whatever this says, exactly as it is offered them
whatever the slots say. `Loadout:grant` deliberately does not ask at all, since
the dev toggle is looking at the game rather than at one save file's progress
through it.

**It is five ladders, and they lock five different things.**

The **written** one is seventeen quests of **one line each**, in `Collection.gates`,
easiest first. It used to be ten of two — a weapon and a passive together, so that
every unlock changed two of the library's shelves at once — and the two halves were
never separable afterwards: a player who wanted the pen was told to survive two
minutes and handed a bomb as well, and neither half could be re-aimed, re-priced or
retired without moving the other. Seventeen rows with one `line` apiece say the same
thing at the same rate and each is a row that can be moved on its own, which is what
the homework page reads out and what makes it readable at all — a checklist where
one tick means one thing.

**The order of that table is read twice.** `Collection.rank` is built beside
`Collection.gateOf` — id → the row's index — and it is the key the library shelves
every name by, so the ladder's order and the shelves' order are the same fact
written once. Moving a quest up the list moves it up the shelf as well, and the two
screens cannot disagree about which of two locked lines comes first. It is why the
seventeen are kept in the order they are *expected to fall* rather than grouped by
which column they ask about.

The four things a quest's `need` may name pull in different directions on purpose:

| `need` | asks | quests |
| --- | --- | --- |
| `time` | the longest run anywhere — last | 1:30, 3:00, 5:00, 7:30, 9:00 |
| `kills` | the biggest body count on one page — fight, and quietly *where* | 300, 1000, 2500, 4000 |
| `sat` | pages played far enough in that the boss walked on | 1, 2, 4, 6, 7 |
| `beat` | pages whose boss went down | 1, 3, 7 |

The ladder alternates between them; three time quests in a row would be one quest
with three prices on it. Two numbers there are load-bearing.

The last two `time` bars sit **above the term's own ceiling**. Opening every page
costs a seven-minute run at the deepest rung, so a quest priced at seven minutes or
less arrives while you are doing something else, and a reward you cannot miss is not
a reward. Before the axes were re-cut, walking the term at minimum cost — six runs,
nothing over 7:00, no boss ever reached — cleared **eight of the ten milestones** and
read 67 of 81 lines open. It now clears five of seventeen and reads 15.

And only **three of the seventeen ask about a boss**, which is a ceiling rather than
a shortage of ideas. The eye is provisional: one fight standing in for seven, six of
which nobody has drawn. A ladder leaning on it is a ladder that cannot be tuned
until they all exist, so `sat` — the half of the same question that does not care
what walks on at minute ten — carries five quests to `beat`'s three. All seven pages
sat and none beaten still reads 29/36 and 36/45, which is the property that keeps
the game tunable while six bosses are missing. When they are real, the obvious move
is to put the *lesson tools* behind beating their own lesson rather than sitting it;
today that would hang forty-three of the eighty-one lines off fights that do not
exist.

`played` used to be one of the four and is not a question any more. It counted
lessons opened at all, and it stopped meaning anything the day the timetable itself
went behind a ladder: a lesson you have played is a lesson you unlocked by playing
the one above it, so `PLAY 3 LESSONS` was a demand that could not be missed. Being
round the book is what the term is for; what is asked here instead is how far *into*
the pages you got.

The **derived** one is the seven lesson tools, and it is not a lock on *having* one
at all. `issue` in `src/loadout.lua` does not come through here, so a lesson still
opens holding its tool whatever this says -- which is what makes the gate mean
something else: `{ lesson = <lesson> }` locks **carrying it anywhere else** until
that lesson has been sat all the way through (`Collection.SIT`, which is
`Spawner.BOSS_AT`). The pencil is a science tool, and you draw with it on that page
as much as you like; the draft will not deal it on any other page and the library
says which page it belongs to rather than pretending it does not exist. Sit the
lesson out and it is yours everywhere.

**SIT and BEAT are kept apart everywhere in the file**: SIT is being still on the
page when the boss walks on, BEAT is putting it down. They used to be one word,
`PASS`, which meant the first and read as the second — and which was going to read
worse still once each lesson had a boss of its own.

Those seven are **derived from `Subjects.list` rather than written out**, which is
the thing to preserve: a lesson gates the tool it issues, so a new lesson gates its
own with nothing to keep in step. It also enforces the rule the README asks for and
nothing else checks -- two lessons issuing one tool line -- since a line may only be
gated once and that is asserted at load. Ids are asserted against the catalogue on
the same pass, the way off-palette art is: a gate naming a line that does not exist
locks nothing at all, which is the one kind of typo the game would go on running
perfectly with.

And the **third** is the other three character weapons, which is the `pass` bargain
again with the roster in place of the timetable. The book comes with one hero and the
other three are bought at the canteen (`price` on the row in `src/characters.lua`),
which is what makes their weapons gateable at all: a lock on a line *every* run is
handed locks nothing, and a lock on a line only some runs are handed locks carrying
it as anybody else. So `{ hero = <character> }` holds SHOT, STARS and SKATE until
five minutes have been survived as the hero who carries each -- `Collection.RIDE`,
which is `Spawner.BOSS_AT / 2`, half a lesson rather than all of one because a page
is a thing you sit through and a hero is a thing you play. Derived from
`Characters.list` for the lesson tools' reason, read off `Characters.best(key)` (the
per-hero register in `roster.txt`, banked by `Game:bankRun`) rather than off
`Records`, since where you played him is the timetable's question and not this one.
Its two demands are two: an unbought hero's line says to buy him, a bought one's
says to last.

The **fourth** is the forty-five fusions, derived off `needs` for the same reason
the other two derived ladders are: a new fusion brings its own gate, and there is no
second list to keep in step. `{ made = <ids> }` is answered by asking
`Collection.has` of each of them — the whole of `needs` and not just the pair in
`fuses`, since a fusion wants a catalyst passive it does not consume and a book
missing the cartridge cannot reach the nine built on one. It recurses exactly one
level and can never recurse further: nothing a fusion is made of is itself a fusion.

They had no gate at all until now, and that was the counter lying rather than the
ladder being generous — a fresh book's library read **51 of 81** while the draft
could reach nine. `Loadout:ready` has always refused a fusion whose parents are not
finished on the strip, so what was missing was the book *saying* so.

**And it changes nothing a run may be dealt, because of one word in
`Loadout:candidates`:** `level > 0 or up.needs ~= nil or Collection.has(up.id)`. A
fusion is exempt from the collection at the draft, because `ready` already asks a
strictly stronger question than the book having its parents. The one case where the
two disagree is the case the exemption is for — a lesson *issues* its tool to the
run that opens on it long before the book has opened that tool anywhere else, so
PENCIL crossed with PEN is buildable on a science page while `Collection.has` still
calls the pencil shut. Two different questions: what could ever be built, and what
can be taken now. Gate a fusion in both places and you quietly take away the first
fusion a fresh book can reach.

And the **fifth** is not a line in the catalogue at all: it is the timetable.
Seven lessons a fresh book could sit in any order was the widest choice in the
game made blind, by a player who had never seen a page or held a tool, so a lesson
is opened by the lesson *above* it in `Subjects.list` and the bar climbs a rung
each time — `Collection.rungs`, built off the list index, `i * Collection.STEP`
with `STEP` a tenth of `Spawner.BOSS_AT`. Two minutes on science opens P.E., three
on P.E. opens grammar, seven on maths opens art, and the last rung stops three
minutes short of a `SIT` so that opening the deepest page and sitting it out stay
two different afternoons. Derived off the order for the lesson tools' reason and one
more of its own: a chain written out can be written into a circle, and read off
the list it cannot be, since every rung points at a lower index. Ten pages is as
far as the arithmetic reaches — the tenth rung is a whole lesson — and a book that
grew past that wants a smaller `STEP` rather than a special case.

`Collection.lessonOpen(key)` is that door and `Collection.lessonWhy(key)` is what
a shut page says, in the lesson tool's own two phrases read from the other end
(`ONLY AFTER %s` over `SURVIVE %d MINUTES THERE`, which is the tool's second line
word for word — the head names the page so the demand can say "there"). Read
straight off `Records.get(rung.after)` rather than through `Records.best`, for the
`lesson` gate's reason: two minutes on science is not two minutes on the rest of the
book. It carries one clause that a book born with the ladder can never reach —
`Records.played(key)` opens a page you have already written on — which is this
file's promise (an unlock read off a maximum is never taken away) kept across the
version that added the term, since the only way to hold a record on a page is to
have opened it once.

The two ladders meet: a page is opened by getting *some* of the way through the
page before it and a tool is freed by sitting the whole of its own, so the run
that opens maths is most of the way to owning the pushpin everywhere. And the
written ladder now meets them both, since `sat` counts exactly the pages the tool
ladder frees a tool on: sitting your fourth lesson hands you that lesson's tool
*and* FIXATIVE. Two ladders, two questions, one crescendo — not a doubled payout.

**The base hero's weapon is the only thing in the catalogue gated by nothing**, and
it cannot be: every book has that hero from the first frame, so it is what a fresh
book's first draft has to deal. Never put a character's weapon behind a milestone
either -- the gate a hero's line wants is his own.

**What a fresh book's one draft is: four weapons, five passives and the one tool
the lesson handed over** -- ten lines and 45 real levels, against 28 to 35 in a
ten-minute run. A first run can absorb most of that and max none of it, which is the
size this set is cut to. The four weapons are SWORD (the base hero's, and it has to
be free), BOMB, ROCKET and COOL S: four different shapes -- swing at what is close,
drop where you are, fire outward at nobody, cut a line through where you stand -- so
taking all four is itself the lesson, and all four carry a drawing board, so the
studio opens on run one. The five passives are SHARPENER, GRAPHITE, INKWELL, PAGE
and MAGNET: one per family, so no build direction starts empty.

Two numbers keep that set honest. Free weapons are 4 of 12 and free passives 5 of 14
-- **a third of each**, which is the floor. And the passive strip caps at five, which
the free set fills exactly, so the first exclusion decision in the game happens on
the first run, the moment PAPER PLANE lands at three minutes.

A gate is a `need` and nothing else, which is what let the hero ladder and then the
fusion ladder go in without a line above `Collection.met` changing. The one door
still missing is a homework page that *awards* an unlock -- the page exists now and
reads the ladder out, but it hands nothing over, and when it does it will be another
kind of `need` answered in the same place.

**`Collection.why(id)` is what a hole says**, and it answers with two *phrases*
rather than two strings: a key, and what goes in its slot. English is the key
(src/i18n.lua), so a sentence assembled here and looked up later is looked up under
words no dictionary has -- `SURVIVE 6 MINUTES` is not a key and `SURVIVE %d MINUTES`
is. The slot is therefore filled after the translation, where it is drawn, and a
string in a slot is itself a key: a number is a number in every language and a
lesson's name is not. Getting that wrong is silent -- the English draws perfectly.
Which is why filling one is `I18n.say(phrase)` rather than a local on the screen
that draws it: there are two of those now (the library's holes and the timetable's
shut pages), and the rule is a rule about translation.

**`src/dev.lua` is a switch in front of all of it, and it does not ship.** The
settings page's last row steps `Dev.unlocks` between EARNED, ALL and NONE, and three
readers ask `Dev.opened` before they answer: `Collection.has`,
`Collection.lessonOpen` and `Characters.owns`. That is the whole feature, and it is
three lines rather than thirty because each of those is the *one door* its question
is asked through.

It is an **override rather than an edit**: nothing it does writes a record, buys a
hero or fills a purse, so a book stepped to ALL and back is exactly the book it was.
ALL is the game finished -- every line in the draft, every page on the timetable,
every hero on the board; NONE is the first afternoon on a save with months of
records in it, which is otherwise impossible to look at twice. It deliberately does
not touch the purse or the levels bought out of it -- those are things you bought
rather than things the book opened, and the counter has its own way back for them
(**What the purse buys**).

Taking it out at launch is the row at the bottom of `ROWS` in `src/settings.lua`,
the three `Dev.opened` calls, the `unlocks` line in `src/options.lua`, and the file.

### Homework

`src/homework.lua` is behind the `HOMEWORK` tab in the timetable's bottom-left
corner, and `src/challenges.lua` is what it reads. It was `Blank.new("HOMEWORK")`
until it had something to say and moved out the moment it did, which is the
canteen's own path and the rule `src/blank.lua`'s header asks for.

**It used to be the library said twice, and is not any more.** The page began as
the seventeen quests of `Collection.gates` with a meter against each -- the one
thing the shelf could not print, `3966/4000`, since a hole in the catalogue is
open or shut and there was no honest way to draw four fifths of one. That was a
whole screen existing to carry one column. The column moved: `Collection.meterOf`
hangs the figure under the demand in `Library:drawLine`, in slate, one line below
the red, with no blank line between them because there the two *are* one sentence
-- what is owed and what has been paid off it. Nothing at all for a gate with no
meter (a lesson tool, a hero's weapon, a fusion), which is honest rather than a
gap: a page is sat or it is not.

**What is here instead is what a register of maxima cannot ask for.** A record is
a maximum per lesson, so a quest can only ever ask you to have a better afternoon
-- four thousand kills on one page, nine minutes in one sitting. A challenge is
answered by *every* run: fifty thousand blobs is four hundred afternoons and no
one of them, and every class beaten at a doctorate is seven wins nobody had in an
evening. Neither number exists anywhere in `src/records.lua`, which is the whole
reason `src/tally.lua` does.

**Nothing here unlocks anything.** Every reward in this game is already a door
with a screen behind it -- a line in the catalogue, a page on the timetable, a
hero at the counter -- so a challenge that handed one over would be a second
ladder pointing at the same doors, and the first thing it would cost is the
library's promise that a shelf is the whole of what there is to open. A challenge
pays in the only currency a checklist has: the box goes red.

**Four sections, one to a spread** (see **The book**). On two leaves the ten rows
are split down the crease, five and five -- down the middle rather than filled to
the foot of the verso and spilled, because five and five reads as a spread and
nine and one reads as a page that ran out -- and a finger drag turns to the next
section. On one leaf they go back in a column exactly as they were.

**`lay.lines` is how many lines a row is, and the page decides it.** A row holds
the ladder, the name, the demand and the figure, and there are three arrangements
of those four, each narrower than the last: flat (`136px` in English), the demand
dropped under the name with the figure still hung on the right edge (`136`), and
fully stacked -- name, then demand, then figure, all in the name's own column
(`111`). The widest that fits `availW` wins, and on a spread that is the third,
because a leaf is about `141` of printable page and the demand alone is `91` of it.
The stack is the library's own shape for exactly this trio (`Library:drawLine`):
the demand, and the figure on the line under it with no blank line between them,
because there the two *are* one sentence. `ROW_GAP` has to stay comfortably above
`LINE_GAP` now -- with a row up to three lines deep, the gap between two rows is
the only thing saying where one of them stops.

**A row is a name, a ladder of pips, a demand and a figure.** Three rungs is the
usual shape and the row shows the lowest one still standing, with a pip filled for
each that has fallen. One row however long the ladder -- three rows saying BLOB
with different numbers on them is a list you cannot run your eye down -- and a row
with one rung draws one pip and needs no special case, since what makes a row long
is how many numbers are in `want`. `Challenges.tier` is the first unmet rung,
`Challenges.done` is how many have fallen, `Challenges.meterRoom` is the *last*
rung's figure at its widest, which is what the column is cut to, so clearing a
rung never moves the list.

**Four sections, stepped by the canteen's footer arrows** (`Homework:arrowBox`,
`arrowAt`, `step`, `drawArrow` -- the same recipe, left/right on the keyboard, the
section name in red between two chevron boxes). The list is going to keep growing
and a page is a page: ten rows a section fits the shortest window this game is
handed with seven to spare, forty in a column would not.

- **BESTIARY** -- one body count per row of `Enemy.types`, ordered by `hp`
  ascending with the key breaking a tie (`table.sort` in LuaJIT is not stable).
  Per monster and not one figure over all of them, because a single ALL KILLS
  challenge is one demand with ten prices and a run would learn to farm whichever
  page pays fastest. The ladder is `{500, 5000, 50000}` divided by the row's own
  `xp` and rounded to one figure, so a grin asks for sixty and a blob for five
  hundred -- the same *sentence* on every row rather than the same number. The
  boss is not on it; it has a row of its own in TERM.
- **TERM** -- `{5, 50, 500}` bosses, `{5 min, 5 hours, 50 hours}` played, and one
  row per rung of `Course.list` asking for the whole timetable beaten at that
  class or harder (`Records.beatAt`). The four courses are separate rows rather
  than one four-rung ladder, and that is the one place the ladder shape is
  deliberately refused: a ladder asks for more of the same thing, and beating the
  book at a doctorate is not five hundred times beating it at high school.
- **COLLECTION** -- the catalogue as four sets rather than eighty-one lines:
  tools, weapons, passives (`Upgrades.list` by `kind`, fusions excluded) and
  `DRAWINGS`, which is `Design.drawn()` over `Design.boards()` and the only
  challenge in the book you can finish without playing.
- **EVOLUTIONS** -- one row per tool, asking for every fusion built on it, read
  off `fuses` rather than `needs`. Named by the tool alone because the section
  under the arrows already says EVOLUTIONS, which is also what keeps the name
  column narrow enough for a phone held upright.

**Everything on all four is derived.** A new monster, lesson, course, tool,
fusion or drawing board brings its own row and there is no list to keep in step --
which matters more here than anywhere, since homework out of step with the game
would be the book asking for something that does not exist. Adding one that is
*not* derived is a row in the section it belongs to: a `name`, a `want` ladder, a
`have` reading some register, and an `ask` written as a phrase rather than a
string. Every `name` is a phrase too, including the one-word ones, so `I18n.say`
draws them all and the screen knows one way of writing a name.

**Measured across every section, never across the one showing.** `columns()`
walks all four for the widest name, the widest demand at *any* rung, the widest
meter and the longest ladder, so no column moves as the footer is pressed or as a
row is finished. That is the library's rule and it matters here for the library's
reason: this is a screen you read by running your eye down it. In English the
widest row comes to 233 of the 312 pixels a 320-wide page offers; in Spanish 245.

**The row is one line if the page is wide and two if it is tall.** A phone held
upright gives 180 across and hundreds down, and a demand, a name and a figure will
not sit in a row that narrow -- so the demand drops under the name, indented to
it, and the list gets taller. `lay.wide` is that decision, and the narrow row
comes to 136 English / 144 Spanish of 172.

**The box is the tick.** Every other screen in the game answers a question by
having a hand-drawn box scribbled in, so a row here is an exercise with boxes
beside it and a fallen rung is a box filled -- drawn rather than scribbled,
because *nothing here is answered, so nothing here is scribbled*, which is the
rule inherited from the library and the blank page before it. A pip is five
pixels, cut to the height of the lettering beside it, so a row is one line tall
and not one line and a picture.

Colour says done and undone in the vocabulary the library already spends: what
you have finished is ink and what you have not is graphite, and the demand is red
because red on every screen in this book is the book asking for something. It is
not drawn at all once the ladder is finished, since then there is nothing being
asked. The meter is slate -- a live number about a live demand. The count in the
top right is the library's corner exactly, and it counts **rungs of the section
showing** rather than rows or the whole page: three pips of a bestiary row are
three separate afternoons, and a count that only moved when the last of them fell
would sit still for a month.

### Settings and language

Three modules, in the split the rest of the game uses -- the data, the file and
the screen:

- `src/i18n.lua` is the dictionary and `I18n.t` is the one door every string goes
  through on its way to the page. **The English string is the key.** There is no
  table of symbolic ids: a line of copy stays written out in English in the
  module it belongs to -- the upgrade's own row, the tool's name, the prompt at
  the top of the screen -- and this file maps that English to Spanish. Which is
  what keeps the whole **Extending** section below true: adding an upgrade is
  still one row in `Upgrades.list` and nothing else. A string with no translation
  falls through to the English, so a gap reads as English copy rather than as a
  missing key. The cost is that two things meaning different things must not be
  written the same way in English; the one place that bit was the school subject
  `LANGUAGE` against the settings row `LANGUAGE`, and the fix was to reword the
  lesson (it is `GRAMMAR` now), which is what to do if it happens again.
- `src/options.lua` is the file, `options.txt`, in `records.lua`'s shape: it owns
  no value, it knows the format. The language lives on `I18n` because that is
  what knows which languages exist; the volumes live on `Sfx` because that is
  what knows what a volume does to a voice; `Input.stickSide`, `Damage.show` and
  `Design.ask` live on `Input`, `Damage` and `Design` for the same reason again.
  Each of those modules also owns the *list* of values its setting may take
  (`Input.SIDES`, `Damage.MODES`), which is what a line is read back against: an
  unknown word keeps the default. A yes or no is written as `1` or `0`, so every
  line stays a key and one token. A bad line costs that one setting its
  default -- a garbled options file must never be a game that will not start.
  `Sfx.music` opens at 0.7 against the sound's 1, and that notch is the whole of
  how the track and the foley are both audible: a bed playing for as long as the
  program is open, level with the transients laid on top of it, is the thing you
  hear instead of them. It is a default and not a ceiling baked into
  `MUSIC_GAIN` -- the bar still reaches the top -- so the page reads 70 against
  100 rather than two hundreds with the difference hidden behind them.
- `src/settings.lua` is the screen. Two bars and four steppers, the pause
  card's shape (one fixed block, centred, heading over and hint under) written
  straight on the page rather than on a card, since there is no run underneath.
  A stepped row is three functions on its row in `ROWS` -- the word to write
  between its arrows, the widest word it could ever write there, and what a step
  does -- and `text`/`widest` must be of the same words in the same language or
  the row is measured on one and lettered in the other. Every row's arrows are
  struck off the widest word *any* of them can hold (`choiceWidth`), so the
  pairs line up with each other as well as standing still. The page holds only
  the *word* for each value; the values and the order they step in belong to the
  module that owns them, so a module that grows a mode grows a word here and
  nothing else.

**A name is not a sentence, and two names stay in one language.** The title on the
title screen is the game's name, so `menu.lua` draws `TITLE_TOP`/`TITLE_BOTTOM`
directly and neither is a key -- which is also what keeps its opening a fixed
clock, since the intro writes the title on over a length struck off those two
strings. A language's own `name` in `I18n.langs` is the other. Anything else a
player reads is a key.

**Translation happens at the draw, never at load.** The language can be changed
while a screen is up, and the catalogue is the same table for every run the
program plays, so nothing is ever baked. Two things follow, and both were bugs
before they were rules:

- **A measurement and the draw it is for must be of the same words.** Nearly
  every screen here reserves room for the *widest* string it can ever hold, so a
  block measured on the English and lettered in the Spanish is a block the
  lettering runs out of. Every `Font.width` in a layout goes through `I18n.t`,
  `Scribble.label(box)` is the one place a box's label is translated (the strip
  widths are struck off it), and `Timetable:statRows` translates at the source
  because that table *is* what the panel is measured from.
- **Anything cached off the text is cached off the language too.** The draft and
  the library both break level text to a width once rather than every frame
  (`self.wrapped`), and both now key that on `I18n.lang` as well.

**Nothing on the settings page is a question, so nothing on it is a box you
scribble in.** That is the timetable's tab rule and it holds harder here: a
`Scribble` box arms, warms slate to red and commits when you lift, and every one
of those is wrong for a volume. A volume is a quantity you can always move again
and the only way to know it is right is to hear it. So a bar is dragged -- with
the row latched on the press edge, so straying off a seven-pixel track does not
drop it -- an arrow is pressed, and the corner button closes the page. The file
is written when a drag *ends*, and releasing the sound bar plays one sound at the
level you just set.

The music bar is the one control here that demonstrates itself, and it is first
for that reason: the track is up from the frame the options were read, so the bar
is heard while the finger is still down. Nothing is played to announce it -- an
effect fired to show the *music* volume would be showing the wrong number -- and a
bar dragged to nothing leaves the track playing at zero rather than stopping it,
since a stopped stream comes back at the top of the file and turning the music
down and up again would restart it instead of turning it back on.

**Two buttons in the title screen's left margin**, both pressed rather than
answered and both `Hud`'s own definitions: the settings button in the corner
button's box (`Hud.cornerBox`, the `sliders` icon) and the language switch in the
same box at the other end of the same margin (`Hud.footBox`/`footTarget`/
`footAt`/`drawFoot`, which carries a *word* where the corner takes an icon).
`Menu:mark` drops ink that lands on either. The switch is on the title screen and
not only in settings because it is the first thing somebody who cannot read the
title needs.

Three things about how the Spanish is **set**, all forced by the 3x5 face:

- **No acute accents.** A capital fills all five rows, so there is nowhere above
  one to put a mark: ORBITA, MUSICA.
- **N-tilde and the two inverted marks are drawn.** N-tilde is a letter rather
  than an accented N -- a word with N in its place is misspelt -- and the
  inverted marks open a sentence. All three are two bytes in UTF-8, which is why
  `src/font.lua` counts **letters, not bytes**: `Font.count`, `Font.at` and
  `Font.width` walk glyphs, and so does `Scribble.printBig`. Nothing anywhere may
  go back to `#text` for a string that will be drawn -- the tab column's
  write-on animation did, and cut every Spanish lesson name short.
- **No commas** in the Spanish. The face had no comma at all until now (nine
  English lines were drawing a blank where one should be); it has one, and the
  Spanish is written without them anyway, which is the rule a character blurb is
  already held to.

### Characters

`src/characters.lua` is who you play as, in the same split the subjects are in: a
row per character, its own files in the save directory, and one screen that picks
between them. That screen is the **studio**, not the timetable — the arrows on the hero's board,
between the drawing and the boxes (`roster` on the design; `Studio:arrowBox`,
`arrowAt`, `step`, `drawRoster`) — because it is a question about the drawing, and
because picking one of them means there is a second thing to draw.

**One of the four is the book's and the other three are bought.** `Characters.base`
is the swordsman — the row with no `price` on it, `Characters.default`, and what
everything that cannot answer *which* hero it means falls back to. The other three
are rows on the canteen's `HEROES` section at `PRICE` (40) apiece, and the one price
for all three is the point: the roster is not a ladder, so a price rising down the
column would be the counter saying the last hero is the best one. `Characters.owns`
is the one question, `Characters.buy` the one door, and `Characters.pick` clamps to
it — a key naming a hero nobody paid for (an old `character.txt`, a bookmark from
another save) lands on the base rather than handing over something unpaid for.
`Characters.step` walks *over* what has not been bought, so the studio's arrows step
between the heroes you have; on a roster of one they step nothing and are drawn grey
with a silhouette chevron, the draft's own spent button.

A hero bought is **not** his weapon bought. A run is still handed whatever line its
character carries (`issue` in `src/loadout.lua` never asks the collection), but
carrying it as anybody else waits until five minutes have been survived as him — the
lesson tool's bargain with the roster in place of the timetable (see **The
collection**). `roster.txt` is the register that answers it: one line per hero,
whether it has been paid for and the longest run as it, banked from `Game:bankRun`
beside the lesson's record and on the same terms — a maximum, submitted from every
route out of a run.

A character is **which weapon line it opens the run holding**, and that is the
whole row: `weapon` names a line in `src/upgrades.lua` and `Loadout.new` takes it
to level one before the run is built, spending a weapon slot exactly as the
lesson's tool spends a tool slot. Four rows, four openings -- the shootman's
`shot`, the swordsman's `sword`, the starman's `star` and the skateman's `skate`
-- and the last two are the ones that show what the split bought: they open with
no hands-free attack at all, one carrying a ring and one carrying the ground
behind him, which was unsayable while attacking was something `Player` did.

All four issued lines are five long, so every character opens on a weapon the
draft can go on selling it -- SHOT and SWORD were an unlock and nothing after it
for a while and are not any more. Nothing anywhere was ever written to that
difference, which is why closing it cost two level tables and no code: a line
cannot tell whether it was issued or drafted, and `Loadout:candidates` offers a
started line whatever the slots say.

The two lines are written from opposite ends, and that is the thing to preserve
about them. **A line sells whatever its weapon is short of.** A pellet has no
shape -- a point going in a straight line at the thing that matters -- so SHOT
sells the four numbers a pellet *is* (the beat, the flight speed, the damage, and
then two at once) and no geometry at all. An arc is nothing but shape, so SWORD
sells `reach` and `sweep` and never sharpens the blade: doubling six on a weapon
that already takes everything standing in the arc is not a level. SHOT's unlock is
also deliberately *below* the beat the rest of the balance was set against -- 2
every 0.7s at 80px/s, against the 3 every 0.55s at 110 that used to be the whole
line -- so a shootman earns his own weapon back over levels two to four instead of
arriving finished.

`was` on a row is the only concession to history here: a character that has been
renamed keeps a fallback to the file its hero board used to live in (see
**The things you draw**), because a rename must not be somebody's drawing quietly
turning back into the default stick man. `shootman` carries `was = "shooter"`. A
`character.txt` still saying `shooter` now lands on the *base* rather than on the row
that used to be called that, which is the answer this wants anyway: a hero nobody
bought is not one an old file gets to hand you, and the drawing follows the rename
either way.

`icon` on a row is not written on it: it is filled in at load off the weapon line the
row names (asserted against `Upgrades.byId` on the same pass), since a hero's icon on
the counter is the icon of the thing he fights with.

There is no `melee` flag, no `range`, no `damage` and no `beat` here any more --
those three numbers are on the weapon's own block, where SHOT opens picking
something off at 96px for 2 on a 0.7s beat and SWORD has to be inside the crowd
for 6 across a 17px arc on 0.825s. The beat each attack comes on is its line's, and the only
thing that moves it is METRONOME -- which moves every other beat in the game by
the same multiplier, so the swordsman's half-again gap is still half again
afterwards and the trade between the two openings is untouched.

That split is the point rather than tidiness. The hands-free attack used to live
in `src/player.lua` as a clock every hero carried, which made it the one weapon in
the game that could not be drafted, could not be doubled up and did not appear in
any counter. Now `src/shot.lua` and `src/sword.lua` are passive weapons like the
star and the rocket, so a shootman can draft SWORD, a swordsman can draft SHOT, a
run can carry both, and `Player` fires nothing at all. It is also what let the
roster grow past the two: a character is one line of the catalogue issued at level
one, so a hero who opens with a star or a skate is a row, not a code path.

The gap between swings is where the arc is paid for, and that is the one balance
decision here worth keeping: a swing is double damage *and* takes everything
standing in it, which against a crowd is several times a shot rather than twice
one. Trimming the damage instead would make SWORD a shot with a different number
on it; the longer gap is the thing the weapon is actually about -- a stretch you
have to survive standing in among what you just hit. It is also why no level of
the line moves either number: what the four after the unlock sell is the arc.

Speed, health, the ink meter, the lesson's tool and every upgrade line are
identical for both heroes, so a build learned as one run reads as the other. Don't
hang a stat on a character to make it "feel" different -- a character is one card
dealt before the first frame, and everything else is the draft's job.

The swing itself is `src/sword.lua`, and three things about it are load-bearing.
It is **swept, not stamped**: the arc is walked over `TIME` and each frame cuts
the wedge it has just crossed, with a `struck` set so one swing hits a thing once
(the beam's rule). Its **pivot is live** — the wedge is measured off where the
player is this frame, so a swing carries with you rather than being anchored to
the ground you left. And the **arc that flashes is the arc that killed**: the
trail is plotted at exactly the block's `reach`, and `holdFor` is that less half
the drawing's length so the blade's point lands on the same radius — the bomb's
ring by another name — so the level that lengthens the arm moves both and says
nothing about either. It asks `Game:eachWithin`
for the sun's reason (even the opening 17px reach is wider than the nine 12px
cells `eachNear` looks in, and the line sells 24) and can afford to for the bomb's
(ten frames every three quarters of a second).

**`reach` and `sweep` are on the block and `TIME` is not**, and that split is the
line: the arc is what the four levels after the unlock sell — longer, wider, a
shove on what lived, then the whole circle — while how long the arm is out is the
half of the weapon you play and no level may touch it. So a wider sweep is a
faster edge rather than a longer wait, and the finale is a spin rather than a
pose. Two things fall out of the full circle and both are in the module: every
angle in it is **unwrapped** (measured off `from`, allowed to run past a turn)
rather than folded into (-pi, pi], since an arc's two ends are the same angle the
moment it closes and a sweep of 2pi folded down is a sweep of nothing; and a
body's bearing is folded *forwards*, into [0, 2pi) off the near edge of the wedge,
which is why a closed circle needs no clause of its own — once the wedge and its
slack come to a turn, nothing is outside it. The knockback level shoves only what
`Enemy:hurt` says survived, handed over through `Enemy:knockback` and scaled by
`stats.knock` the spiral's way: a push is bought time, and time is worth nothing
against something already dead.

Its clock and its target are its own -- `nearestEnemy` inside `range`,
the beat held rather than spent when nothing is in reach -- and `src/shot.lua` is
the same three things with a bullet at the end instead of an arc, which is all
that module is.

The sword is the second thing in the game kept at eight headings, and the one
exception to *drawn nose-right*: a sword is held, so the board is 3x8 with the
point at the top and the ring is read two eighths round (`POINT_UP`). That offset
lives in one place and nowhere else.

**Each character has a hero drawing of his own.** `Design.heroes` is one board per
row of `Characters.list`, keyed by character key and kept in `hero-<key>.txt`, so
the shootman you drew and the swordsman you drew are two people rather than one
sprite with two weapons. They all write `Sprites.player`, which is the only
thing to be careful about: whichever was applied last would be the hero the game
draws, so `Design.applyHero` is the one place that decides and everything that
changes who is picked goes through it — `Design.loadAll` at the end (which is why
`Characters.load()` runs *before* it in `Game:load`) and `Studio:step` on the
board. A step also saves the board it is leaving unless it is blank: `OK!` is still
the only thing that answers the screen, but the two boards are two files and a
step that dropped your last ten strokes would be the one place here where drawing
something loses it.

**Every character draws what it fights with**, and it is the same clause doing it:
`design` on the row, taken by the hero's board on its way out. It names the same
design the weapon line names, so the board a shootman is handed on the way in is
the board a swordsman who drafts SHOT is put on -- two routes, one drawing, one
file. The starman's and the skateman's are `star` and `skate`, boards the draft
opens for everybody else.
The swordsman's is `sword`, the shootman's is `bullet` (5x5, `Sprites.SHOT`, `src/bullet.lua`) — no
`turns` on that one, since a shot flies at whatever angle the nearest thing is at
and a drawing with a front would point the wrong way at nearly all of them. Its
grid is bigger than the pellet drawn on it, the rocket's trick, so a heavier shot
can be drawn without `Bullet.radius` moving: the radius is the *grid's*
half-width, which is what keeps every measurement off a drawn sprite honest.

The column is ordered title → drawing → selector → boxes → hint in both of the
studio's arrangements (`Studio:columnStack`, `layoutStacked`): the board and the
1:1 copy are the *what*, the name under them is the *who*, and the boxes answer
for the pair, so anything answerable is last with the line that talks about it
directly under it.

Which character is picked is also on the timetable, twice: as the first of the
panel's five stat rows (`HERO`, then `TOOL`, `BEST`, `KILLED`, `MARK` — who, with
what, how it went) and as the drawing in his hand, the sword or the pellet at 1:1 beside
him on his own walk bounce. Both are measured across the whole roster rather than
for the character showing — `statWidth` takes every character name, `armSize`
every carried design's grid — because everything in that panel is measured at its
widest or stepping the roster and coming back would move it. The arm belongs to the
hero block and is dropped with him on a narrow screen: a sword floating beside a
panel with nobody holding it says less than nothing.

### Coordinates

`src/input.lua` reports one movement vector and one drawing pointer in **canvas
pixels**, whatever produced them (keyboard/mouse or thumb stick/finger). World
space is canvas space plus `Camera.steady()`'s `left, top`, converted in
`Game:updateDrawing` every frame — which is what makes holding the pointer still
while walking keep drawing. Marks are stored in world space.

`Camera.steady()` and `Camera.bounds()` return the same rectangle except during a
knock (below): `bounds()` carries the shake, `steady()` does not. Everything that
*draws* wants `bounds()` — that is genuinely the rectangle on screen. The pointer
conversion is the only caller that wants `steady()`, because a cosmetic shake may
not move where your pen lands.

### The knock

**When the player is hit the page jumps** (`Camera.knock`, called from
`Player:hurt` — the one door, as with `Enemy:hurt`, so a fifth thing that can
hurt you shakes for free). It is a decaying wobble on two axes at two
incommensurate rates (`SHAKE_X` 46 rad/s, `SHAKE_Y` 31) over `SHAKE_TIME` (0.3s),
rounded to whole pixels: `cos` on x so it snaps sideways on the first frame,
`sin` on y so the loop only opens up once you have felt the hit. Not a per-frame
random offset — at three or four pixels of travel random reads as buzz — and not
a single straight kick, which returns the same way every time. Being a function
of the clock rather than a die also keeps it deterministic.

**Amplitude scales with the share of the bar the hit took** (`SHAKE_SOFT` 2px →
`SHAKE_HARD` 5px, full at `SHAKE_FULL` = 15% of `maxHp`), which is the exact
opposite of the enemy flinch and for a stated reason: an enemy gets a damage
number thrown off it saying how hard, so its flinch only says *that* it happened;
the player gets no number, only a bar in a corner they are not looking at. Being
tougher therefore makes the same hit shake less, which is the right feel.

`Camera.knock` **takes the larger** of the running and incoming magnitudes rather
than summing — a screen that never settles is one you cannot play on. It is run
down by `Camera.settle(dt)`, called beside `Camera.follow` at the tail of
`Game:update` and so outside the playing branch: a knock taken on the frame you
died finishes falling, like the particles and the damage numbers. `Camera.set`
clears it, so a new run never starts crooked. The HUD does not shake (drawn
outside `Camera.attach`); damage numbers do (world space, under the transform).

`Input.onPointerDown` is the HUD's first refusal on every press: return true to
swallow it so it doesn't also start a stroke. It runs ahead of the thumb stick,
whose grab zone is a generous quadrant off its own bottom corner rather than the
ring it draws. Which corner is `Input.stickSide`, a setting, and the HUD reads it
too: everything you *press* belongs to the thumb that is not on the stick, so
`Hud.toolSide` puts the tool column in the margin opposite and the weapon column
takes the other. Both margins are claimed at full width either way, so the swap
moves nothing laid out between them.

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
presence alone — **blocks first, in a written precedence order** (`Game:updateDrawing`:
sweep, drop, snap, cut), so a row carrying both is used as its block and its brush
fields are left for whatever else wants them (twenty-five of the forty-five fusions,
see **Fusions**) — and six rows carry two *blocks* on the same principle, the first
tested winning the gesture (the SPINDLE, the HEM, the FOLD, the SNAP LINE, the
TEAR LINE and the GUILLOTINE). The order is a precedence list rather than an accident: the two
gestures worth borrowing come first, in the order they borrow from each other — a
sweep beats a drop because the compass fusions put a drop on the arm, and a drop
beats a snap and a cut because the pushpin fusions cast those between two pins.
`Tools.BLOCKS` is a separate list for a separate job (what the multipliers walk)
and the two need not agree:

- **Brushes** carry the line fields (radius, spacing, ink per pixel, ramp,
  fade…) and usually a `stamp`. One mark is a `Stroke` (`src/stroke.lua`): a
  chain of stamps at fixed spacing, with damage tested against the *segment*
  between the old and new head so a fast flick can't tunnel past an enemy. A
  brush with no `stamp` keeps no stamps and draws nothing — the rubber is one,
  and all it leaves is `crumbs`, particles shed sideways off the moving tip.

  **A brush row may carry one gesture, and `tap` is it.** A press that ends
  without going anywhere is a radial hit at the point it landed on —
  `{radius, damage, knock, ram, ink, slack, hold}`, read by `Stroke:tap` and fired
  from the *release* branch of `Game:updateDrawing`, which is the only place that
  can tell a tap from a drag. It cannot be a `drop`: `drop` beats the brush fields
  in the precedence list above, so a row with both would never lay a line at all.
  `ink` is a flat price like a tapped tool's and is refused rather than clamped;
  `ram` is written inside the block so that only a shove hard enough to matter
  ever reads one. Two rows carry it (the STUB, the SCUFF) — see **The pencil's
  six**.

  **`pace` is the nib's weight following the hand** — `{over, thin}`, one row
  (the SWELL). At or above `over` pixels a second the nib is `thin` wide, under it
  the row's own `radius`, decided per dab off how fast the *nib* was travelling and
  not the pointer. It is read in four places (`pacedStamp`, `Stroke:reach`,
  `Stroke:paceRate`, `Stroke.pathR`) and they are one fact said four times: the dab,
  the hit, the price and the finished mark's own varying width. See **The three
  without a pencil**.

  **`fasten` is a whole `drop` block on the row without being the row's block** —
  what a stroke drives into the page at its own two ends (the STITCH). It is the
  SEAM's `snap.wire` one storey out: a drop something other than a tap is
  pressing, with the something being the stroke. The two staples go in at the two
  *moments* — the near one on the press, the far one on the release if the finger
  travelled — so a tap fastens once because only one moment happened.

  **What makes a press a tap is `Game:wasTap`, and it asks about the finger.**
  `slack` is accumulated *screen* travel and `hold` is how long the press lasted,
  and it has to be both: travel alone calls a slow short line a tap, time alone
  calls a flick one. It cannot be asked of the line, and that took a bug to make
  obvious — the pointer is in screen pixels and a mark is in world ones, so a
  finger held perfectly still while the player *walks* is a finger the page is
  sliding under, laying real line the whole time. Reading `Stroke.drawn` answers
  "did the page move", not "did the hand", which broke exactly the case the
  gesture exists for: a panicked tap taken while running.

  **`loop` is three payloads and a row picks.** Closing a line on itself cuts
  what is inside (`loop.damage`), sets it alight (`loop.ignite`, a burn block) or
  takes it off the page with the paper (`loop.lift` `{tick}`, `Game:liftEnemyTo` —
  put down again in the furthest clear corner, no gem and no xp because nothing
  died, and it keeps answering for arrivals). They are tested fields
  rather than a kind and a row may write more than one, which is why `scaleDamage`
  asks for `loop.damage` by name instead of reading it blind. `loop.lift` is
  outside that walk on `sever`'s reasoning. Two of them also *draw* the middle —
  `loop.wash` in the ink layer and `loop.lift` in the page layer, both through
  `pixelart.fillPolygon` and both by the even-odd test the hit uses, so what is
  painted is what will be taken.

  **`sting` is what a mark does to whatever leans on it**, where that is not what
  the nib does going past — one row writes it (the DECKLE, a pencil laying a pen's
  wall) because `damage` is one field and two tools may write it meaning two
  different things. Read by `Stroke:apply` on a lingering tick only, defaulted to
  `damage`.

  **`fasten` is a whole `drop` block on the row without being the row's block** —
  what a stroke drives into the page at its own two ends when the finger lifts (the
  STITCH). It is the SEAM's `snap.wire` one storey out: a drop something other than
  a tap is pressing, with the something being the stroke. `Game:fastenEnds` reads
  it; `slack` decides one end or two, `ink` is charged per staple at the release,
  and both scaling walks reach into it by name as they do the wire.

  **`lift` is `{tick}` and makes the ink itself a severed region** — anything
  touching this mark is lifted off the page and put down in the far corner, for as
  long as the mark is there (the DEADLINE; `Stroke:sweepLine`, `Game:liftEnemyTo`).
  Same word as `loop.lift` on purpose: that one takes what a ring *encloses* and
  this takes what the line *touches*, one verb at two shapes. It is the fourth shape
  a severed region comes in and the only one that leaves the page under it whole,
  which is why the row that carries it also gives up `wall` — see **The line that is
  a region**.

  **`chord` is the same trick with a `cut`** — the page opened along the straight
  line between the mark's own two ends when the finger lifts (the COLLAGE, the
  SCORCH, the SHEAR; `Game:chordCut`). Both fields are renamed for one reason: the
  block they are a copy of is in `Game:updateDrawing`'s precedence list, so a brush
  row carrying it under its own name would be that tool and would never lay a line.
  `ink` is the flat price of one cut, `tapped` turns the gesture over exactly as it
  does on `fasten` (the SHEAR's taps make the cut and the drag is the rub), and the
  block is built by the unlock's `apply` because nothing lifts a block that is not
  one of `Tools.BLOCKS`.
- **Non-brushes** carry `drop`, `snap`, `sweep` or `cut` instead, and `ink`
  becomes the flat price of one use. `drop` is placed (`src/pin.lua`,
  `src/staple.lua` — both share the block and the code path, and the row is what
  says which module lands and how hard), `snap` is aimed (`src/ruler.lua`) — or, on the
  one row where it is not the gesture, *cast*: the FOLD's `snap` is the ruler two
  of its own circles drop between their crossings, and `Ruler.cast` builds one
  already lying on a chord with no aim to hold (which is why `length` is per ruler
  rather than per tool — the chord decides it, so the field goes unwritten
  on that row),
  `sweep` is opened (`src/compass.lua`), `cut` is tapped twice
  (`src/scissors.lua`) — and a `cut` may carry a `wire` one level in, which is the
  SEAM's field read against the line between the two taps instead of the line a
  ruler landed on (the HINGE, `Game:seamAlong`). It is also the one field in the
  game that moves *where* a price is charged: a tap that drives a staple is not the
  free anchor the scissors' rule was written about, so `Game:openCut` spends on it.
  A cut block need not be the row's block at all: three brush rows carry the same
  thing as `chord` and cast it between their own mark's two ends (**The scissors'
  three brushes**), which is why `Game:openCut`, `Game:closeCut` and `Game:castCut`
  all take the block and its price as arguments — nothing in `src/scissors.lua`
  knows which field a cut came out of. Two fields only those rows write are read
  there: `ignite` (blades that leave what they cut burning) and `sever.paste`
  (a crowd that arrives in the corner glued).

  **A drop is the one thing that stays on the page**, so it is the one thing that
  can end up a shape nobody drew. `Game:updateDrops` retires a finished drop to
  `game.spent` and never touches it again — unless `Game:dropCrowded` found one
  already within the new one's `FOOTPRINT` (a constant each module writes down,
  since the distance is the drawing's business and not the tool's), in which case
  it is dropped on the frame it *lands* instead. Landing is when it has done
  everything it was paid for, and the hold it leaves is carried on the enemy
  rather than by the thing on the paper, so letting go of the drawing costs
  nothing. Ink is never refunded for it.

  **One level buys that back**, and it is the stapler's third: `prise` on the block
  makes the end of the hold a second event rather than a retirement. `Staple:update`
  bites again on the frame the hold expires — same damage, same crit roll, no
  freeze, since there is nothing left in the page to hold anything with — spends a
  fifth of a second lifting the wire six pixels off the paper on a squared rise and
  a widening lean, and then sets `lifted`, which is the word `Game:updateDrops`
  reads to mean "do not keep this one". It is the only hit in the game that cannot
  miss, because the thing it hits is the thing the staple has been holding still;
  what it pays is the page, since that run's `spent` pile stops filling with wire.
  The `prise` bite is written to reuse `def.damage` rather than carry a number of
  its own, so every scaling walk that already reaches a staple (`scaleDamage` on
  `drop`, a block's `wire` and `fasten`) reaches the second bite for free.

  **One fusion makes a staple sticky instead of aiming it**, and it is the CLINCH's
  `tacky` — seconds between *catches*. `Staple:catch` sweeps the circle on that
  cadence and fastens anything standing in it again, for as long as the wire is in
  the page, which is the gluestick's contract (a hold re-applied) on a fastener. A
  catch is not a bite: no damage and no crit, since a staple that hit everything on
  it three times a second would be a weapon rather than a fastener. It is also the
  one thing in the game that hands a *block* to `Enemy:freeze` as the thing doing
  the sticking, so a `soften` written beside it rides on the body — see **The
  stapler's four**.

  **And one fusion takes the clock off the tear**, which is the SNAG's `snag` — a
  field on the *mark* rather than on the block. A rubber dragged over a stapled sheet
  catches the wire and takes it with it, so on that row the tear is not something the
  hold runs out into, it is something a rub comes and does: `Game:snagDrops` walks the
  live drops against the stroke's segment, and any whose module answers `snag`
  (`Staple:snag`, and nothing else does) is prised on the spot with the crit certain
  rather than rolled. Which is why `Staple:prise` exists as a function and why
  `Staple:update` asks about the tear *before* the hold — a wire something has already
  caught is coming out whether or not its two seconds are up. The two seconds stop
  being how long the fastening lasts and become how long you have to get back to it.
  See **The stapler's four**.

  **And because a drop stays on the page, one or two of them can be a
  relationship.** Two fields on a row that also carries `drop` say the mark is not
  drawn by a hand at all, and they are the same idea at two counts. `thread` strings
  it between two things this tool has driven into the paper within `reach` of each
  other (`Game:stringThreads`); `pool` lays it as a single dab round one
  (`Game:poolAt`). **`reach` is what says whether the result is a shape or a line**:
  at the pushpin's 120 every pair inside it gets a rail, and at the stapler's 14
  (`LINK`) a post can only see the next one in its own raked seam — so `thread` on a
  row that also carries `rake` comes out as one continuous mark, which needed no new
  code at all. Both fire from `Game:updateDrops` on the frame a drop lands, and
  both are held on the page for as long as their posts are (`Stroke.strung`), ageing
  on the tool's own `life` once a post comes out.

  **What gets strung is whatever else is on the row**, which is the block-precedence
  rule one storey down. Brush fields string a `Stroke` laid whole and `finish`ed the
  same frame — so a thread is whichever nib the fusion ate, and a `wall` one is a
  fence between two posts while a `linger` one is a band that burns. A second
  *block* is strung instead, **cast** rather than pressed for, exactly as the FOLD's
  `snap` is cast by two circles crossing: `snap` is a ruler along the line the pins
  aim (`Game:castRuler`) and `cut` is the page coming apart along it
  (`Game:castCut`). Neither is new code in the parent's module — `Ruler.cast`
  already took two points, and a cut has always been two taps.

  A `pool` is a flag and nothing more: how wide the dab is is the brush's own
  `radius`, and both rows that carry it write that at the crater's 25, because a
  pool is not a nib — it is what filled the hole. One stamp is then the whole mark,
  which two fields have to know: the dither that takes a mark off the page drops
  *stamps*, and a fraction of one stamp is all of it or none, so a pooled row writes
  `fade = 1` and `edge.rough` goes. See **Fusions**.

  **An upgrade level may change the gesture itself, and one does.** The stapler's
  `rake` makes a tapped tool a dragged one: `Game:updateDrawing` still routes the
  press on block presence, and the drag branch inside it is guarded on the anchor
  the press edge left (`Game.rakeX`) rather than on `wasDown`, which is the
  ruler's and the compass's guard for the same reason — a press already down when
  the tool changed is not this tool's press. `Game:rakeDrops` walks the segment
  the pointer covered and carries the leftover travel, so spacing survives frame
  boundaries the way `Stroke.carry` makes it survive them for a brush, and it
  charges the tool's full `ink` per drop: the level buys presses, not page. Three of the four carry a `width` and it
  means one thing in all three — how far off the line a body's centre may be
  before its own radius stops reaching. For `sweep` **that line is the rim**: a
  compass cuts the circle it draws and never the middle of it, so it is the one
  tool in the game that reaches a perimeter rather than an area — unless a fusion
  paid to take that back, and five did: a `loop` on the same row cuts the middle
  when the ring closes (the LASSO), a `sever` in the block takes the middle off the
  page entirely — crowd and all (the PUNCH), a `width` past `minR` covers the middle outright at
  the smallest circle (the MOAT at 20 and the SPINDLE at 25), and `wipe` drops the
  rim test altogether so the hit is the whole disc the leg has swept, thrown out of
  it (the CLEARING). See **Fusions**. A block may also carry fields only its
  upgrade line ever writes, at their off values, so that a tool's own header says
  what can happen to it: the scissors' `blades`, `through` and `sever` are that.
  `blades` is spelt so rather than `bite` because the compass's block already has
  a `bite` that is a bare number, and `scaleDamage` reaches into every block by
  field name -- two fields of one name and two shapes is one generic walk away
  from indexing a number.

  **One block prices its own gesture**, and it is the only place `ink` is not the
  whole story: the HEM's `sweep.per` is ink per staple past the ones the smallest
  circle holds, so the drag buys wire. `Game:sweepReach` caps how far the drag may
  open against the meter every frame and `Game:sweepPrice` charges the width at the
  release, and the two cannot disagree because `Compass.seamRadius` is the exact
  inverse of `Compass.seamCount` -- which is what keeps the compass's promise that
  letting go always draws the circle.

Two rules apply to anything paid for before it lands: it must be landed from
*every* route that can take it away — release, tool change, and pause
(`Game:snapRuler`, `Game:swingCompass`) — or the ink is spent on nothing; and
anything reading the pointer after the press edge needs the `if self.ruler`/
`if self.compass` guard, or a press that was already down when the tool changed
gets claimed by a tool it was never meant for.

**The `cut` block is the one gesture that spans two presses, and it is paid for
on the second.** Which is not an exception to the rule above but the reason it
does not apply: the first tap only anchors, so there is nothing to land and no
ink to pocket, and `Game:closeCut` charges the tap that actually opens the paper.
A tap back on the anchor (inside `Scissors.MIN`) is putting the scissors away and
costs nothing. What every route that takes the pointer away has to do instead is
drop the anchor — `Game:dropCut`, called from `setTool` and `holdRun` beside the
two landings — since an anchor tapped before a freeze and closed after it would
cut a line across a page the horde had spent a whole draft screen walking over.
What is drawn off `game.cutFrom` between the two taps is a graphite cross and
nothing else — no line is dotted out of the anchor, since a guide you can drag
onto a blob makes an aimed tool out of a led one — and it is guarded on the tool
in hand still being the scissors for the aims' reason.

**And it is the one block that does not land the moment it is paid for.** The
second tap prints the dotted line and builds the cut; the blades then travel down
it at `SPEED`, cutting the stretch they crossed each frame with a `struck` set,
which is `src/sword.lua`'s swing written straight instead of curved. So
`Game:closeCut` no longer strikes — `Game:updateCuts` walks the blades — and what
a cut takes is the crowd as it stands when they arrive. Two things fall out of
that. The travel is its own clock and the mark's `life` does not run under it, or
a long cut's slit would be going grey behind the blades before they reached the
far edge. And the severed half (`sever`) is the one part of a cut that is *not*
swept: it comes off the page at the tap and empties on its own tick from the tap,
because half a page that waited for the blades would spend the best part of a
second being a finale that had not happened yet. The tick is seeded at 0 so the
first sweep lands the frame after the tap rather than half a second behind the
paper.

**A severed region repositions rather than kills or despawns**, and it is the only
thing in the game that does either. `Scissors:lift`, `Compass:lift`,
`Stroke:tryCloseLoop` and `Stroke:sweepRings` all ask `Game:clearCorner()` once per
sweep and then hand each body they hold to `Game:liftEnemyTo(e, corner)`. Nothing
leaves the horde: the enemy keeps its health, its burn, its glue and the storm's
mark on it, and credits *nothing* either — no gem, no xp, no `kills`, and neither
`split` nor `burst`, because nothing died and nothing was even hurt. Graphite is
thrown at both ends (paper dust, not the slate a kill throws) and everything the
body was carrying that was a fact about *where it stood* is dropped: the
separation shove, the way round a wall it had picked, a spiral's lure, the wax
underfoot and a charge it was half way through. The boss is refused at that one
door, for the reason it is exempt from the range despawn — half a page of distance
handed back twice a second is a fight you never have to have.

`Game:clearCorner` picks the corner of the *visible* page (inset `CORNER_PAD`,
arena-clamped) furthest from the player that `Game:severed(x, y)` says is not
missing paper, and returns it once for the whole sweep — so a region empties into
one corner and the crowd comes back as one clump from one direction. Each body is
spread up to `CORNER_SPREAD` *into* the page off that corner, seeded off where it
stood with `util.hash01`, falling back to the bare corner if the spread lands on
missing paper. Nil — no clear corner at all — means the sweep lifts nobody, which
is what has happened when you have walked out onto your own offcut.

`Game:severed(x, y)` is the run's own question and mirrors the page pass exactly:
every cut's `Scissors:offcut`, every compass's disc, every `loop.lift` stroke's
rings. It has to be the run's and not each region's, because a page can be in
ribbons (three pins are three cuts; a spiral leaves four holes) and a region that
only knew its own shape would hand its crowd to the hole next door twice a second.
**A fourth kind of missing paper owes this function a clause as well as the page
pass one** — the two are meant to answer the same question, and a shape that is
drawn as torn but not counted here is a shape the game will put bodies down inside.

The spawner is no longer answered by a severed region either, and that is worth
knowing before anybody tunes it: a despawned offcut put the horde under the floor
and the run was refilled from the offscreen ring while the page was still open
(`FLOOR_RATE`, `REFILL`), so a cut quietly *replaced* the crowd it took. Nothing
leaves the horde now, so the floor has nothing to top up and what walks back is the
same crowd rather than a fresh one.

The balance is no longer in missing credit. What a cut sells is the length of the
page — the seconds it takes the crowd to walk back — and what it charges is that
they arrive together, out of one corner, instead of from the ring they were spread
round before. That is why a region this absolute needs no number tuning at all, and
it is still why `sever` carries a clock and nothing else, and so is the one
sub-table inside a block that `scaleDamage` does *not* reach.

Marks that are surfaces rather than attacks (`wall`, `slick`, `freeze`, `linger`)
answer `Stroke:covers(x, y)`, which rejects on a bounding box first. It takes an
optional `reach`, for the one caller not asking whether a point is standing on
the line: `Stroke:pop`, which wants the ink's radius plus its own spread plus the
body's, and needs the box to refuse against the same number it tests with.

**Surfaces underfoot are read in `Player:update` and there are two**, each gated
so a run that owns neither pays nothing: `game.hasSlick` → `Game:slickAt` (the
crayon's wax) and `Loadout:trail` → `Skate:boostAt` (the wet end of the trail).
Both apply only while you are standing on them, and they stack rather than
choosing between themselves — a run holding a crayon and a skate should not have
to pick.

**Two marks in the game do not live on their `life`, and both are the pen's.**
A stroke with `kept` set neither ages nor is culled (`Stroke:update`), which is
`keep` on the tool: `Game:holdWalls` is the whole of the bookkeeping — it clears
`kept` off every mark on the page and sets it on the ones it was handed, called
when a wall stroke begins (`Game:updateDrawing`) and when a wall-laying arm swings
(`Compass:swing`). So replacing a fence hands the old one its ordinary clock back
rather than deleting it. It takes a *list* because one gesture is not always one
line — a compass carrying a pen rules its ring as one mark per leg (the CORRAL)
and holding half a ring would be holding a fence with a hole in it — and the
release is a walk of the stroke list rather than a registry, so there is no
reference to keep in step and nothing to go stale. The release is keyed on the new
mark being a `wall` at all rather than on it being held in its turn, which matters
for the run that *loses* the level with a held wall down (the dev switch,
`EXPEL`): a fence nothing could release would sit on the paper for the rest of
the run. And `pop` makes the end of a
life an *event*: `Game:updateDrawing` calls `Stroke:pop` on the frame it culls
the stroke, which hits along the whole path rather than in a circle on it. The
pair compose in the one direction that matters — a held wall never pops while it
is held, so what pops is either a line you let expire or the one you replaced,
nine seconds after replacing it.

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
  `Game:resize` calls `Loadout:rebuild`. The replay is also why the six
  whole-loadout multipliers can be written straight into the numbers they scale:
  four walk the tool copies (`scaleDamage`, `scaleKnock`, `scaleCost`,
  `scalePersistence`) and two walk the **weapon blocks**
  (`scaleWeaponPersistence` for the laminate, `scaleCadence` for the
  metronome), all six landing after every line's own levels, so nothing shared is
  ever scaled and nothing is scaled twice. Which is the one difference between
  the two kinds of global multiplier worth knowing: a weapon module reads
  `passiveDamage` at the point it uses it, because damage is a number a rocket
  carries away with it, and it reads neither of these two at all, because a clock
  and a lifetime are numbers the weapon is still standing next to.
- `src/levelup.lua` is the draft screen and knows nothing about what any
  upgrade does; it hands back an id.

**The draft arrives and leaves.** `LevelUp` runs four phases -- `arriving` ->
`asking` -> `confirm` -> `leaving` -- and the two outer ones are a slide rather
than a fade: the cards, and the boxes under them that move with them, come up off
the bottom edge when they are laid across the page and in past the left when they
are stacked down it (`SLIDE_IN` = 0.22s in, `SLIDE_OUT` = 0.14s out).
`LevelUp:away` is the whole animation -- a 0..1 fraction of the full offset,
squared one way arriving and the other way leaving -- and `LevelUp:layout` is the
only thing that turns it into pixels, so the offset is floored once and the three
cards travel as one sheet.

Two things hang off `arriving`, and both are the same worry: a level landing while
a finger is on the page laying tool strokes.

- **Nothing is readable until the cards land.** The pen is not tracked,
  `pressPerk` and `keypressed` refuse any phase but `asking`, and `stale` is
  re-taken on every frame of the slide -- so a press that begins mid-slide has to
  be lifted too, and the first thing the draft ever reads is a press made at cards
  that were already there.
- **A card is not a target** (`TAP_CARDS`, above).

`leaving` is entered from `confirm` (a box was answered) and straight off the
press edge for REROLL and SKIP, which have no box to flash. All four answers reach
`Game` when the slide finishes rather than when the act was decided, so `Game`
never resumes a run under a draft that is still on the page -- and `confirmT` goes
on running through `leaving`, so the answered box is still flashing as it goes.

A run may only *start* so many lines of each kind — `Loadout.SLOTS`, five
passive weapons, five passives and four tools. `Loadout:candidates` is the one
place that applies it, and the clause to preserve there is that a line already
under way is offered whatever the slots say: without it, filling the last slot
could strand a line on level one forever. The same clause covers the collection
(see **The collection**), which is the other thing that file asks about what the
draft may reach: `level > 0` bypasses both, so nothing a run is carrying is ever
taken off it. The catalogue therefore dries up around
65 of the 190 levels rather than at the end of itself, and it is a flat number
rather than a range now that every tool line is five long too — a run down the
fusion road reaches a little past it, since a fusion hands a slot back.

Weapons are five rather than four because a run now arrives holding one: the
character's line is taken to level one before the first frame, exactly as the
lesson's tool is, so a run drafts the same four weapons it always did and the one
it came with is counted rather than invisible. All twelve weapon lines are five
long, SHOT and SWORD included, so the weapon half of what a run can reach is a
flat 25 again and only the tool end is a range.

**The draft does not dry up with it.** `Loadout:roll` pads whatever the
catalogue cannot fill with the endless lines (`Upgrades.endless`, seven of them,
uncapped, a few percent each), so it always returns three cards and a level
always costs the run its momentum. Two rules there: real candidates are drawn
first and always, so the padding can never take a place a genuine line could have
had; and the endless lines stay *out* of `Upgrades.list`, because anything in
that table is a candidate from the first draft onward. `Game:openDraft` returning
false is now only reachable with an empty endless table.

The XP ladder is `0.9 × level² + level + 5` (`src/player.lua`), quadratic rather
than the exponential it was, and the two facts are one decision: the old ratio
walled a run off around level 28, well short of the 63 picks the slots allow, so
half the catalogue was never offered. The 0.9 is set against what the spawner
actually pays out — changing either one without the other moves where a run ends
up.

A run is **not** meant to finish its build before it wins. The boss arrives at
minute 10 (`Spawner.BOSS_AT`) and a winning run is level 37 to 44 — around two
thirds of the 63 picks. Level 64 is where `ENDLESS` starts: it was level 60 until
SHOT and SWORD grew four levels each, and those eight pushed the last real pick
four levels up the ladder and the minute it lands on out with it.

That only holds because **xp scales with the hp multiplier** in `Enemy.new`,
which is the one number tying the two systems together. `HP_PER_MINUTE` compounds
(1.15 a minute), so a run clears proportionally fewer enemies a minute as the
clock runs; paying the flat `def.xp` would mean income *falling* while level costs
rise, and a run stalling in the second cycle whatever it did. Scale one and the
other has to follow — and the steeper the health curve gets, the more load that
one line is carrying: xp per kill and seconds per kill rise by the same factor,
so xp per second comes out flat and the 0.9 above goes on meaning what it meant.
Note it rides the *unrounded* multiplier, not the whole number the health was
rounded to: a bat held at 2 health for a minute of the curve is still paid for
the minute.

Tools are drafted, not issued, and so are weapons — the two caps are one rule
written twice: a tool line's **first level is the unlock** and a weapon line's is
the block turning up, so `levelOf(line) > 0` is the whole of "is this equipped"
and there is no separate flag to keep in step.
`toolLine` in `src/upgrades.lua` builds one. Which tool a run begins holding is
the *lesson's* to say — `tool` on the subject row names a line id, and
`Loadout.new` takes it to level one before the run is built, costing a slot like
any other and leaving the rest of the line for the draft to sell. Which weapon a
run begins with is the *character's* to say on identical terms — `weapon` on the
row in `src/characters.lua` names a weapon line, and `issue` in
`src/loadout.lua` is the one function that takes both. The catalogue
has no "this one is free" flag, and a line cannot tell whether it was issued or
drafted. `Loadout:syncEquipped` turns the taken
lines into `loadout.equipped`, in unlock order, and that list is append-only
except where a fusion has eaten a line (below) —
which is what lets `Game.tool` stay a *slot number* that goes on meaning the
same tool when a new one is unlocked mid-run.

**Fusions.** A tool line may carry two more fields, and they are the whole of the
mechanic:

- `needs` — line ids that must every one be at their **last** level before the
  draft will deal this line at all (`Loadout:ready`). A condition and only a
  condition; nothing is taken from a line for being named here.
- `fuses` — which of those the run actually spends. Their tools come off the
  strip and their slots come back (`self.fused`, worked out at the top of
  `Loadout:rebuild` and read by `syncEquipped` and `slotsUsed`). Always a subset
  of `needs`, and always at least one line of the fusion's own kind, which is
  what lets `Loadout:candidates` deal a fusion **past a full strip**: it hands
  back at least as many places as it takes, so refusing it at the cap would mean
  the four-slot rule locking out the one card that relieves it.

`Loadout:ready` also refuses a fusion whose `fuses` names a line that is already
in `self.fused`, which is what makes **fusions sharing an ingredient mutually
exclusive**. Nine of the forty-five eat the compass and there is one compass, so a run
that finished PENCIL, MARKER, GLUESTICK, SCISSORS, PUSHPIN, PEN, STAPLER, RUBBER,
RULER, COMPASS and SELLOTAPE is dealt all nine of those cards and gets exactly one
of them. Without that clause the second would eat a line already gone and cost the
strip nothing, where the whole shape of the mechanic is two tools in and one out.
It reads `self.fused`, so the dev toggle's tool switch suspends it along with the
eating.

**The clause is per ingredient rather than per family, and that started to matter
the day the pushpin got fusions of its own.** DOT TO DOT eats PENCIL and PUSHPIN;
CORRAL eats PEN and COMPASS; the two share nothing, so a long enough run can hold
both — the first pair of fusions in the game that can be on one strip at once, and
the first time the four tool slots have had two of them in. Nothing was added for
it. What the clause forbids is spending a line twice, which is the only thing it
ever meant.

The split is the design. A fusion may ask for a line it does not consume — the
HALO wants a finished SELLOTAPE and gives it back untouched — which is how one is
aimed at a *build* rather than at a pair of tools. The levels of a consumed line
are never refunded and could not be: they are what the fusion is made of, and the
line keeps its level so that a bookmark, which is a list of levels and nothing
else, restores to exactly the same strip. Nothing records that a fusion happened.

The fused tool is a row in `Tools.list` like any other, written at the *combined*
numbers of its finished parents rather than at new ones — there is nothing to
balance that is not already balanced somewhere else, which is only safe because a
fusion is never dealt before those lines are finished. The one thing it may not do
is write down a table `scaleDamage` reaches into (`ignite`, `ram`, `loop`,
`crit`): `Tools.copy` is one level deep, so those have to be built fresh on the
run's copy every rebuild, which is why `fusionLine` lets a fusion's unlock level
carry an `apply` where an ordinary tool line's never does.

**Two screens read `fuses` on their own.** `Upgrades.fused` is a set of icon
names derived at the bottom of `src/upgrades.lua`, and `Hud.drawIcon` — which every
icon in the game is drawn through — puts a plate of blush behind any icon in it.
Keyed by icon rather than by line because that is the only name for a line the
selector column has: it is handed a tool off the strip, not the row that unlocked
it. So a fused tool is marked out in the selector column, on the library's shelf and
in its own entry without any of those being told what a fusion is, and inside the
selector's 13px box the plate lands exactly — every icon in the game is 11 across
and the border is one. On the draft's fusion card it lands on blush and cannot be
seen, which is right; where it shows is the second, third and fourth levels of a
fused line, dealt on the same paper card as anything else. The other reader is the
library, which keeps fusions off the shelf entirely and answers them as a pair of
picks instead (see **Evolutions in the library**). Both are derived, so a new
fusion gets both by existing.

`Game:takeUpgrade` lands the player on the new tool, since a fusion is the one
card after which the slot in hand is not the tool that was in it. **The dev
toggle's tool switch suspends the eating**, the way it already suspends the
four-slot caps: `grant` hands over fusions along with everything else, and
`rebuild` leaves `self.fused` empty while `Loadout:lent("tool")` is true, so a dev
strip is every tool *and* every fusion rather than the fusions instead of their
parents. The weapon switch is not asked, since nothing it lends touches the
strip.

**The catalogue is complete**: forty-five fusions, one for every pair the ten tool
lines can make, in four families. The first three
are one per *gesture* worth borrowing and all three are complete: every pair of tool
lines that shares a borrowable gesture has a fusion. That accounted for twenty-four
of the forty-five pairs the ten tool lines can make, and the twenty-one left over
were the ones with nothing to borrow — two brushes, or a brush and a nib-less block.

**The fourth family is those twenty-one being answered rather than excused, and it
does it by making the stroke itself the carrier.** A line you drag has a length, an
inside once it closes, and a mark left lying on the page afterwards, which is as
much a shape as a ring or a ruled diameter is — and the pencil is the one tool that
owns all three, which is why the family opens on it: six of the twenty-one are the
pencil's (**PENCIL × PEN, RUBBER, MARKER, GLUESTICK, SCISSORS and STAPLER**, under
**The pencil's six** below).

The fifteen pairs left have no pencil in them, and all fifteen are written too.
**Six are brush against brush** (PEN × RUBBER, PEN × MARKER, RUBBER × MARKER, PEN ×
GLUESTICK, RUBBER × GLUESTICK and MARKER × GLUESTICK, under **The six without a
pencil**), which is every pair of brushes in the game. What they add to the family is
the question a pencil answered for free: with two ordinary brushes, *which* of them is
the line? The rule they settle it on is whose mark is a **place** — a pen line is
terrain, a marker band is a surface and a smear is a hold, where a rub is an event
that is nowhere at all once it is over — so one parent's mark is the body and the
other is what happens at it.

**Four more are the stapler's** (PEN, MARKER, GLUESTICK and RUBBER, under **The
stapler's four**), and they are the family admitting that the stroke cannot always be
the carrier: the nine pairs left after the brushes were all a brush with a *block*, and a
tool with no line in it has no stroke to lend. What the first three borrow instead is the
one block gesture that is a drag — `rake`, a staple every twelve pixels for as long as you
hold — which makes them the pushpin's threading family with `thread.reach` read at the
other end of its range. The fourth (the **SNAG**) is the one that could not: a seam of
staples raked beside a *rub* is a shove undoing the fastening laid next to it, so it
gives the drag to the rubber and takes the STUB's shape instead — a gesture each, and
the rub is what pulls the staples back out. **A fifth pair is the stapler's without
being one of those four** (the **HINGE**, STAPLER × SCISSORS, under **The scissors' own
gesture**): neither parent has a stroke *or* a spare gesture to lend, so the carrier is
the scissors' own `cut` with the wire inside the block.

**And four are the scissors'** (under **The scissors' three brushes** and **The line
that is a region**), which is the family's last shape and the answer to the CUTOUT's
open question: the stroke is the carrier again, but what it lends is neither its length
nor its inside — it is its **two ends**, cast as the two taps a cut has always been
(`chord`). Three of the four brushes leave a mark with two ends; the rubber does not,
so it keeps the parent's taps and gives the drag to the rub, which is the SNAG's split
one tool over. The fourth, PEN × SCISSORS, does not use the carrier at all: **the mark
itself is the region** (`lift`), which is the last pair the strip can make and the one
that closed the catalogue.

**Nine are the compass** — eight of them wearing something else, and one (the FOLD)
wearing nothing and paired with a second circle instead. **Eight are the pushpin**,
and until they existed the paragraph here read "all nine are the compass, and that
is a fact about the compass rather than a rule about fusions: it is the only tool
that reaches away from the player." That was half right, and the missing half is
the whole of the second family: a pin also lands wherever you tapped and never
where your hand is. What a pin has never had is a **line** — it is a point, and a
point cannot be a shape, a fence or a band however far off you put it. So the two
families are one argument from two sides. The compass borrows a nib and its *ring*
becomes a mark; the pushpin borrows a nib and its *pins* become one.

**And seven are the ruler**, which was the third gesture all along and is the one
the other two had already borrowed *from*: the FOLD casts a ruler between two
compass circles and the SNAP LINE casts one between two pins, so the ruler had been
fused into twice before it did any fusing. What it has that nothing else has is that
it is *aimed* — a brush goes where your hand goes, a pin and a cut go where you
tapped, a compass opens where you pressed, and a ruler is the one thing you point.
Those seven are a different argument from the first two families, and the paragraph
that names it is under **The ruler's seven** below. Every other pairing in the
catalogue really would be two marks laid where your hand already was. The **HALO**
is the marker fused into the compass, needing MARKER, COMPASS
and SELLOTAPE all finished and eating the first two. It is the
first row in `Tools.list` that is a brush *and* a block at once: the `sweep`
block wins the routing in `Game:updateDrawing` (blocks are tested before brush
fields), so the gesture is the compass's exactly, and the brush fields are what
the leg draws with. `src/compass.lua` opens one `Stroke` per leg at swing and
drags it round behind the lead, so the ring is a real mark with the marker's own
life, linger, stacking and fire on it and nothing in that file knows what any of
those do. **A compass drawing a mark rules no circle of its own** — the mark *is*
the ring, so `Compass:drawGuide` plots nothing once the arm is moving, the object
drops itself the frame the arm stops rather than outliving a ring it did not draw,
and the block's `life`, `fade` and `ramp` go unwritten.

The **LASSO** is the pencil fused into that same compass, needing PENCIL, COMPASS
and SELLOTAPE and eating the first two, and it is the halo's recipe with the other
parent in the leg: the same both-shapes row, the same one `Stroke` per leg, and a
graphite circle at the pencil's finished numbers (9 damage, a 4px pressed point)
where the halo lays a band. `sweep.width` is 4 on the halo's rule — **the rim a
sweep cuts is as wide as whatever the leg is carrying** — and the pencil's `flow`
is deliberately *not* copied across, since nothing here is dragged and the whole
price is paid at the needle (`Compass:layBands` draws on a budget of `math.huge`).

What it adds to `src/compass.lua` is one method. **`Compass:ring` is the pencil's
`loop` resolved as a lap:** every time the circle closes, everything whose centre
is inside the radius takes `tool.loop.damage`, which is the one thing a compass has
never done. It lives in the sweep rather than in the stroke for two reasons — a
compass knows its circle exactly where a `Stroke` has to notice its own path coming
back round, and with `counter` set each leg draws only *half* the circle per lap, so
the ring is closed by the pair of them meeting while neither stroke has closed
anything. `Stroke.lassos` exists for that: it starts as `tool.loop ~= nil` and
`Compass:swing` clears it on every mark it opens, so being surrounded is resolved
once and in one place. The rim cut is a separate event and both land — being
surrounded and being scratched are different things that happened, which is the
pencil's own rule for its hand-drawn lasso.

The **MOAT** is the gluestick fused into the same compass, needing GLUESTICK,
COMPASS and SELLOTAPE and eating the first two, and it is the least new code of the
three: nothing was added anywhere. Everything the glue does is already read off the
tool hanging on the body it caught — `Stroke:apply` freezes, `Enemy:freeze` stores
the tool, `Enemy:hurt` softens off `glue.soften`, and `Game:updateGlue` tears on
release and pulls the free towards the ink (`Game.hasPull` is derived from the
strokes on the page each frame, so a compass-laid ring turns the field on by
existing). It is also the first fusion whose unlock level wants no `apply`: the
gluestick's three upper levels are a bare number the sharpener multiplies on the
run's own copy (`tear`) and two tables nothing ever writes into (`pull`, and
`soften` is a scalar), so the row may say all of it.

Its `sweep.width` is 20 on the same rule — the head of paste is 20 across — and it
is **the one tool that takes a rim past `minR`**. Opened at the minimum the ring
closes over its own middle and lands as a filled plug of paste; opened out to 66
the same ring is a 40px-thick wall with clear page inside it. The comment in
`Compass:cut` documents what that costs: a body standing exactly on the needle has
no direction to read, `atan2(0, 0)` is 0, and it is cut once a lap at an arbitrary
moment inside a disc that is entirely paste either way. That invariant used to hold
for the whole catalogue; anything else widening a rim should read it.

The **PUNCH** is the scissors fused into the same compass, needing SCISSORS,
COMPASS and SELLOTAPE and eating the first two, and it is the first fusion that is
**not** two shapes at once. There are no brush fields on the row at all: blades put
nothing on the page, so `Compass:swing` opens no `Stroke` (it needs a `stamp`), the
sweep rules its own ring exactly as a bare pencil one does, and everything the
fusion is lives inside the one block — which is also why it is the one fused row
that *keeps* `life`, `fade` and `ramp` there. Two of its numbers needed no
reconciling at all: `width` is 3 on both parents (the compass's block took the
scissors' number for the scissors' reason and says so) and `damage` is 12 on both,
reached twice from opposite arguments. `knock` is the one they disagree on and the
scissors win it — a lead drags what it catches, a blade separates, and shoving
bodies out of the disc before the ring closed would be the one thing that could
stop the tool mattering.

Its `sever` block is the scissors' last level with a circle round it instead of a
half-plane, and it is where the new code went:

- `Compass:lift` is `Scissors:lift` with the `offcut` half-plane test replaced
  by `Game:eachWithin`, which *is* the disc test — what a ring holds is one
  distance from the needle. Where what it holds *goes* is not this object's
  question: it asks `Game:clearCorner()` once per sweep like every other severed
  region. The on-screen clip is kept even though a disc is bounded where half a
  page is not: without it the disc would go on hauling bodies into a corner the
  camera has walked away from.
- What the disc does to what it holds is **reposition** it (`Game:liftEnemyTo`),
  not damage it and not despawn it, and that is the whole of what separates the
  PUNCH from the LASSO — both are a ring that acts on its own middle, but the
  lasso's middle is a hit and this one's is a place the horde is not. `sever` is
  `{tick}` with no damage in it, which is why the PUNCH is one of the fusions that
  needs no `apply`: there is nothing for `scaleDamage` to compound, so the row
  carries it directly.
- `Compass:drawSever` is `Scissors:drawSever` with chords instead of half-rows —
  one square root per row, no boundary case — and `Game:draw` calls it from the
  page pass beside the cuts. Both are just spans of `Background.torn`, so a hole
  inside a severed half is the same grey laid twice.
- `Compass:drawRim` is new and the ring's drawing now goes through it. A slit
  cannot be drawn the way a line is: paper wipes the ruling rather than stacking
  with it, which is what makes a slit read as the page stopping — and it also means
  paper on paper is invisible except where it crosses a rule. So a slit is dashed
  and carries the dark edge of the page lifting one pixel *outward*, both decided
  by the same identity-against-the-palette test the scissors use on their own ramp.
  `Compass:plot` gained a `dr` argument for that edge and has exactly one caller
  that passes it.
- The hole opens on the **first** lap to close, not when the arm stops, which is
  the scissors' rule: the offcut is off from the moment there is a closed line
  round it. With two legs that is half way through the swing.

The **SPINDLE** is the pushpin fused into the same compass, needing PUSHPIN,
COMPASS and SELLOTAPE and eating the first two, and it is the first row in the game
with **two blocks** on it. That needed no new rule: `Game:updateDrawing` tests
`sweep` before `drop`, so the sweep is the gesture and the drop block is what the
arm is carrying — the halo's arrangement one storey up, with a whole tapped tool on
the end of the leg instead of a nib.

It is the only fusion that *invents* a behaviour, and the invention is the carrying:

- `Compass:cut` gained three clauses — skip a body already on a point (a rider sits
  on the rim at every angle the leg reaches, so whether it got re-cut would come
  down to which side of a float the leading edge fell on), add `self.kills *
  def.drive` to the hit, and pick up the first survivor a free leg meets.
- `Compass:haul` drags each rider to its leg's lead off the swept angle, exactly as
  `layBands` does and for the same reason, and re-freezes it every frame. That
  freeze is the whole implementation of "impaled": `Enemy:update` already knows a
  frozen body does not chase, does not drift, drops its shove and still hurts the
  player who walks into it. It watches `e.gone` the way `src/storm.lua` does, since
  it holds a reference across frames.
- `Compass:nail` ends the turn by freezing the rider for `drop.freeze` and driving
  a real pin into the page at the lead. Nothing is nailed if nothing was carried:
  the pins on a page are a record of where the trouble was, and a pin through
  nothing would be a false entry.
- `Compass:drawLeg` draws the drop's own sprite at the lead instead of the ink
  square every other leg ends in — named on the block (`sprite = "pin"`) rather
  than held, because sprites are built at load and rows are written before that,
  which is the late lookup `icon` already is. It is drawn while the compass is
  still being set too, where the leg itself goes pale: a leg is a line and may be
  pencil-faint before you commit, an object on the arm is not. Over the bite arc it
  gets a blue outline a pixel out on all four sides (`outline` in `src/enemy.lua`),
  because a pin cannot be pressed harder into the paper the way a lead can. The
  instrument is lifted off the frame the turn closes and the driven pin is drawn
  one list earlier in the same pass, so the pin you watched travel *is* the pin
  standing in the page.
- `Pin.new` gained a `driven` flag — already through the paper, no fall and no
  `land`, so no second crater is punched out of ground the rim has just swept — and
  `Game:driveDrop` is the no-ink path onto `self.drops`.

The **CORRAL** is the pen fused into the same compass, needing PEN, COMPASS and
SELLOTAPE and eating the first two, and it is the halo's shape — a brush and a
sweep, the sweep winning the routing, the brush being what the leg lays — with the
one difference that **the mark is not an attack**. What the pen lays is terrain: a
line the crowd cannot cross, at the pen's finished numbers (a 7px nib, a point of
sting twice a second to whatever leans on it with `graze = 2` of slack, `pop` when
it goes, and `keep`). `sweep.width` is 4 on the halo's rule and `sweep.damage`
stays the compass's 12 on the moat's split, but `sweep.knock` is **0** — the
scissors' argument on the PUNCH, and stronger here: a leg that dragged bodies
tangentially round the rim as it laid the wall would sweep the crowd across the
line it was drawing, and what a closed fence does is decide who is inside it. The
pen's `smooth = 26` is deliberately *not* copied, and it is the one omission in any
fused row that is not merely unread: the lead runs the rim at ~500px/s at full
width, so a nib chasing it would lag some 20px behind and inside the arc, ruling a
smaller spiral than the guide promised and stopping short of closing.

It is the fusion that fixes the tool it ate. A hand-drawn fence has **ends**, and
`Enemy:avoidWalls` rounds them deliberately, so the pen has never been able to
enclose anything; a compass draws the only closed line in the game, and it draws it
where your hand is not. Two lines of new code were the whole of it:

- `Compass:layBands` sets `game.wallsDirty` when the row is a `wall`. The index is
  dirty-driven and only `Game:updateDrawing` was dirtying it, so a fence an arm
  laid would have been ink nothing walked around. The drawing pass runs first, so a
  frame's worth of new arc is felt a frame late — a few pixels, on a body
  `Enemy:resolveWalls` lifts off the ink when the segment does arrive.
- `Compass:swing` hands both bands to `Game:holdWalls` when the row has `keep`,
  asked on `wall` rather than on `keep` so that swinging always releases whatever
  was held — the same order and the same reason `Game:updateDrawing` has it. That
  is what turned `Game.heldWall` into a list; see **Marks**.

Nothing else. The sting is `Stroke:lingerTick`, the fence is `Walls:rebuild` filing
the ring's path at the tool's own radius, the hold is `Stroke.kept`, and the pop as
it goes is `Stroke:pop` along the whole ring — none of which has heard of a compass.
It is also the longest walk `lingerTick` has ever had (a full-width ring is ~830
stamps and ~100 path points, and both legs are on the page), bounded by the box, at
most twice a second, and early-out at the first covering segment for the bodies
that are actually leaning on it.

The **HEM** is the stapler fused into the same compass, needing STAPLER, COMPASS and
SELLOTAPE and eating the first two, and it is the second row with two blocks on it —
the SPINDLE's arrangement with the other reading of a tapped tool on a moving arm.
That one is **carried** and driven in once at the end; this one **presses as it
travels**, and the block picks between them on field presence like everything else
here: `Compass:seams()` is `drop.rake ~= nil` and `Compass:carries()` is its
negation, which gate the pickup clause in `Compass:cut` and `Compass:nail`
respectively. `rake` is the stapler's own finale field, unchanged in value and
changed only in *reader* — nothing routes on it now (the gesture is the sweep), so
the 12px spacing is read by `Compass:loadSeam` instead of by `Game:rakeDrops`.

- `Compass:loadSeam` works the press slots out at swing, when the width is final:
  one every `rake.every` pixels of rim, stored as the swept angle at which some leg
  *first* reaches each — leg 1 at offset `o`, leg 2 at `TAU - o` — sorted, and
  walked with a cursor. Fixed slots for `stepsFor`'s reason: exactly even spacing,
  exactly the count the price was charged for, and no drift on a slow frame.
  Whichever leg arrives first presses; the other never presses that slot, because
  the page holds staples one deep (`FOOTPRINT`) and the meter was charged for
  staples on the page rather than for presses thrown away.
- `Compass:seamPress` drives them through `Game:driveDrop` as the arm passes, at the
  slot's own angle rather than at this frame's lead. It also owns the sound rate:
  `CLACK` is the least time between two presses being *heard*, because 34 of one
  sound in under a second is a machine gun — hence `driveDrop`'s `hush` argument.
- `Game:driveDrop` grew the block-named `sound` (icons belong to tools, and what
  arrives here is a block), since a staple driven by an arm would otherwise press in
  silence. The stapler's third level needs nothing here at all: `prise` is read by
  `Staple:update` and by the `lifted` branch of `Game:updateDrops`, so a hem that
  fastened thirty-four bodies unfastens all thirty-four two seconds later without the
  compass, the driver or the row knowing it happened.
- `sweep.per` and the capped `Compass:reachTo(px, py, reach)` are the priced drag —
  see **Tools**. It is the first tool in the game whose reach is something the meter
  can run out of mid-gesture, and running out is drawn rather than refused: the leg
  simply stops opening.

Nothing a staple does was touched. `Staple:bite` lands, crits, holds and either
stays for the rest of the run or tears back out of it exactly as a tapped one does,
and it ignores `driven` because it has no fall to skip.

The **CLEARING** is the rubber fused into the same compass, needing RUBBER, COMPASS
and SELLOTAPE and eating the first two, and it is the second sweep-only row (the
rubber has no mark to leave, so `Compass:swing` opens no `Stroke`). It is the one row
that changes what a sweep **reaches**: `sweep.wipe` drops the rim test, so the hit is
the whole disc the leg has swept and what it catches is shoved *outward* from the
needle instead of round the rim. That is the geometry `Compass:cut`'s own comment
calls a bug, restored deliberately — and the four objections in that comment are
answered by the row rather than ignored: it deals the rubber's 2 rather than the
compass's 12, so the area buys a shove and not damage; the tool it borrows was never
an edge; and the level that does lose its argument (the compass's third, "cutting far
deeper") is named out loud on the row.

- `Compass:cut` grew two branches, both on `def.wipe`: `d <= radius + width +
  e.radius` for the reach (`width` still means what it always meant, measured from
  the disc), and `knockback(cos a, sin a, knock)` for the shove — `a` is already the
  body's angle, so its cosine and sine *are* the outward unit vector, and a body on
  the needle goes out along absolute zero (`atan2(0, 0)` is 0, the MOAT's shrug about
  the same pixel). It also calls `e:launch(self.tool.ram)`.
- `ram` is on the **row**, not the block, which is the LASSO's `loop` placement for
  the same reason: `scaleDamage` reaches `tool.ram` by name and walks into no table
  inside a block, so that is where the sharpener already looks — and being reachable
  is exactly why it must be built by the unlock's `apply`.
- `Compass:fleck` is new and is the old inline speck code plus one branch: what comes
  off a rubbing tip is not pigment jumping off a point, it is `Particles:crumb` —
  paper dust thrown out to the sides of the tangent, as wide as the tip. Wiped bodies
  shed one too.
- `sweep.life = 0` is the rubber's own number and means what it says: nothing is left.
  `Compass:update` drops the object on the frame after the turn closes, and
  `Compass:drawGuide` returns early on a life of nothing — the guard matters, because
  the fade below it would be dividing by that zero. The ring is drawn in **graphite**
  while the arm is on it: what you are shown is where the tip is travelling.

Two of the rubber's four levels are deliberately unread, which is more than any other
fusion drops: `lean` is a tip that keeps hitting while it rests and an arm never
rests, and `scrub` halves a per-pixel price that does not exist here. Both are about
the wrist and the meter, and a sweep has neither.

The **FOLD** is the ruler fused into the same compass, needing RULER, COMPASS and
SELLOTAPE and eating the first two, and it is the one fusion where **nothing is on
the arm**. The whole `sweep` block is the finished COMPASS copied across without a
number moved — a bare lead, a 3px rim, the plain pencil ring — which no other
fused row can say. What the fusion added is not on the instrument, it is a
*relationship between two marks*: swing a second circle while the first is still on
the page and, where the two rims cross, the ruler comes down flat on the line
between the two crossings.

- `Compass:crossed` is the pairing, and it is the only place in `src/compass.lua`
  that has ever looked at a second compass. Newest crossing partner first (one
  line, not a lattice), and three tests: the needles must be more than `APART`
  (4px, the ruler's own `DEAD` for the ruler's own reason) so the join has a
  direction to be square to, and two strict inequalities — `d < r1 + r2` and
  `d > |r1 - r2|` — which between them exclude disjoint, nested, tangent and
  drawn-twice. The partner must also have `swept >= span`: an arc the arm has not
  finished is not a circle, and the crossings of one are two points on blank paper.
- `Compass:crease` is the geometry and the cast: `a = (d^2 + r1^2 - r2^2) / 2d`
  along the join, `h = sqrt(r1^2 - a^2)` square to it (floored at zero — a
  subtraction of squares one float off a boundary is how a square root gets asked
  for a NaN), and one drawing rule on top of the arithmetic: a chord shorter than
  `snap.width` is refused, because a 13px band with the whole 12 and the whole
  shove wrapped round a single point is a pushpin drawn by accident.
- It is called from the `closes` branch of `Compass:advance`, beside
  `Compass:ring` and once per lap for the same reason — so a finished line rules
  the chord twice, half a turn apart, which is what keeps the compass's third
  level worth something to this tool.
- `Game:castRuler` lands it in the call that makes it, so it never goes in
  `self.ruler`: that slot is the one being *held*, and every route that takes the
  pointer away lands that one. It charges no ink — the second half of this tool
  is paid for in a second press of the first half, which is the only price in the
  game charged in gestures.
- `src/ruler.lua` grew two things and neither is a special case. `length` is per
  ruler rather than read off the block (`Ruler.new(def, x, y, length)`), and
  `Ruler.cast(def, ax, ay, bx, by)` puts the pivot at the middle of the gap with
  half of it as the reach — so `Ruler:ends` comes out at exactly the two points
  it was handed, and nothing else in the file had to learn what a chord is.

**Fresh is the ring's own life and not a clock anybody invented.** A compass is in
`game.compasses` for exactly as long as the circle it ruled and drops itself the
frame that fades, so the pairing window is `sweep.life` — 2.2s past the arm
stopping, and nothing in the draft stretches it (`scalePersistence` walks top-level
fields and the `drop` block only). The tool is legible off the paper rather than off
a number: a ring you can watch fading is a timer.

One parent level has nothing to land in, and it is the ruler's finale. How far this
ruler reaches is not the tool's to decide — the chord can never pass 132, twice
the widest circle, against the 400 that level buys — and the trade is written out
on the row: the reach was sold and the *position* was bought, because a ruler's line
goes through the player and this one goes nowhere near them.

**DOT TO DOT**, the **STOCKADE** and the **CORDON** are the second family, and they
are the pushpin fused with the pencil, the pen and the marker: needing PENCIL /
PEN / MARKER, PUSHPIN and SELLOTAPE all finished, eating the first two of each.
They are the halo's shape with the other gesture underneath it — a brush and a
block on one row, the block winning the routing — so the tap is the pushpin's tap
exactly, down to the quarter-second fall, the 51px crater and the pinned tank, and
the brush fields are what a *thread* is made of. All three share one `drop` table
(`PIN` in `src/tools.lua`, the finished pushpin) and one `thread` table (`THREAD`,
`{reach = 120}`), which is the point of the family: the rows differ only in what is
written beside them — a nib for three of them, a whole second block for two more,
and `pool` in place of `thread` for the last two.

**The reach is 120 and it is drawn.** It was 50, which had the nicer argument — a
finished pin punches 25 about the point, so two pins fifty apart are two craters
whose rims are exactly touching, and the tool drew its own range for free. That did
not survive playing, and neither did 80 after it: three taps inside a fifty-pixel
circle is a shape you build by accident or not at all, given that a pin costs half a
meter and holds for four seconds.

**What set the final number is the triangle rather than the line.** Three pins
pairwise inside 80 have to sit in a circle 46 across; at 120 they sit in one 69
across, which is the difference between a shape you plan and a shape you can simply
mean. That is the half of the family that matters — four of the five threading tools
are only interesting closed (DOT TO DOT cuts what it encloses, the STOCKADE wants a
corner, the CORDON is a band you walk somebody into) — so a range tuned to make a
straight line easy and a triangle hard was tuned against the wrong half. 120 is
three eighths of the narrowest page, where 50 was a sixth and 80 a quarter.

What every step up costs is the free guide, so the guide is drawn: the page pass in
`Game:draw` puts a graphite `circleOutline` at `thread.reach` round every pin **in
`self.drops`** — the same circle the pin already draws while falling, several sizes
up. At 120 that ring is most of the reason the tool is readable at all, the rims now
being seventy pixels apart at full stretch: two pins can be joined without looking to
a player as though they ought to be.
The list matters and is why it is a loop in `Game:draw` rather than a line in
`Pin:drawMark`, which the spent pile also calls: a thread needs two posts still
holding, so a ring round a retired pin would be a promise the page cannot keep. It
therefore doubles as the clock — the ring is on the paper for exactly as long as the
pin can still be joined to another. No fade and no dither, since it is not a mark
that is leaving; it goes the frame the pin stops being a post. It also happens to
make the SNAP LINE *easier* to aim rather than harder, since a longer baseline is a
steadier one — five pixels of error at the far end of the line became three.

The new code is four functions in `src/game.lua` and one field in
`src/stroke.lua`, and none of it is in `src/pin.lua` — which is the FOLD's lesson
applied: the second half of these three is not something the gesture carries, it is
a relationship between two things already on the paper, and that belongs to
whatever can see both of them. A pin knows how to fall, punch and hold, and has
never had to know what is lying near it.

- `Game:dropOne` stamps `d.tool = tool` when the row has `thread` (and nothing
  else in the game gains a field), for the reason it already stamps `d.price`: a
  thread is laid a quarter of a second after the tap, out of the *brush* on the
  row, and by then the strip may be holding something else. That stamp is also the
  routing test — `Game:updateDrops` refuses every other drop in the game in one
  comparison. `dropOne` now also reads `drop.sound` ahead of the tool's icon, the
  field `Game:driveDrop` already had, because three rows drive a real pin into
  paper under a name that is not PUSHPIN.
- `Game:stringThreads` joins the landing pin to **every** pin of the same tool
  already standing in the page within reach — not the nearest, because the third
  pin of a triangle has to reach both of the first two on the way in. It is
  bounded by the tool and not by a cap: two taps is a full meter and a pin holds
  four seconds, so a page carries three or four live pins and a landing strings two
  or three threads at the very most. *Live* ones only, and three reasons pull the
  same way: a falling pin is not in the page yet, a pin the page did not keep
  (`Game:dropCrowded`) is a crater that happened and no drawing at all, and a
  **spent** pin is the page's memory of the run — there is no limit on how many of
  those there are, so threading to them would lattice the whole page shut over a
  long run, which is exactly what the pen's `keep` is bounded to prevent. Same tool
  by identity on the run's copy, which excludes a staple (a drop like any other)
  and a pin a compass leg drove in (the SPINDLE).
- `Game:strand` lays one thread: a `Stroke` off the fused row, `lassos` cleared
  (`Compass:swing`'s line, for its reason — a straight line between two fixed
  points can never notice a ring closing), extended the whole length in one
  unbudgeted call (`Compass:layBands`' rule — the meter was emptied at the tap),
  `finish`ed on the frame it was begun since there is no finger to lift, and then
  `strung`. It records the pair on both pins as `pin.links`, which is the graph the
  circuit walks.
- `Game:unstring` releases a post's rails when it retires to `spent`: the threads
  start ageing and fade on the tool's own life, and the link goes from *both* ends,
  so what is left is a graph of exactly the threads standing between pins that are
  still holding. That is why the circuit walk never has to wonder whether a corner
  is still there.
- `circuitBetween` (a local) is a breadth-first walk from one of the landing's new
  neighbours to another, skipping the pin that just landed, so what comes back is
  the **tightest** circuit that landing closed — a page with five pins on it has
  more than one ring in it and the shape you were building is the small one. Tiny
  by construction and deliberately undefended against being large.
- `Game:cutCircuit` is the pencil's `loop` closed by taps. The ring is *exact*,
  which is the whole difference from `Stroke:tryCloseLoop`: there a path has to be
  caught coming back near itself, and the rules about minimum perimeter and spent
  path exist because a hand-drawn wiggle is not a lasso. Here a circuit either is in
  the graph or is not, so there is nothing to decide and the only geometry left is
  the even-odd test — which is why `insideLoop` came off the file's locals and is
  now `Stroke.insidePath`, one polygon test with two callers that pass it flat pairs
  and neither of which knows what drew the other's. One cut per landing, whatever
  else the tap closed: being surrounded is one thing happening once, which is
  `Compass:swing`'s sentence for `Compass:ring`'s reason.
- `Stroke.strung` is the hold, and it is its own field rather than a second writer
  on `Stroke.kept`. The two are the same effect with different owners and one list
  cannot express both: `kept` is one gesture's worth of wall and `Game:holdWalls`
  clears it on every stroke on the page each time a new one is laid, where a thread
  answers to its own two posts. A run holding DOT TO DOT beside a PEN — legal, since
  they share no ingredient — would otherwise drop every thread on the page the frame
  it drew a fence.

**The SNAP LINE** and the **TEAR LINE** are the same family with the *other* thing
strung between the pins, and they cost the two parents' modules almost nothing:

- The SNAP LINE (RULER + PUSHPIN) casts a ruler along the line the pins aim, and
  the whole change is **one `or` in `Ruler.cast`**: the reach is `def.length` where
  the row wrote one and half the gap where it did not. That single field is the
  difference between a cast *bounded* by two points (the FOLD — the chord decides,
  so `snap.length` goes unwritten) and a cast *aimed* by them (this — the pins are
  a pair of sights and the ruler is the tool's own length, corner to corner). No
  flag, no new argument, and `Game:castRuler` was not touched. The unlock's `apply`
  is the ruler's own finale, which makes this the one fused row whose `apply` needs
  the screen: `snap.length` is half a window diagonal, the only number in the game
  measured off the canvas, and without the level the pins would rule a stub.
- The TEAR LINE (SCISSORS + PUSHPIN) is the one fusion whose two halves were
  **already the same gesture** — scissors are two taps with the page opening
  between them, and two pins are two taps — so `Game:castCut` is `Game:closeCut`
  minus the anchor and minus the ink, keeping the parent's `Scissors.MIN` refusal
  (two points that close together have no direction in them, and `Game:dropCrowded`
  refuses a five-wide *box*, which a pair five and a half apart on the diagonal
  slips past). What it fixes is that the scissors' first tap was free and did
  nothing: the whole price of a tool placeable anywhere was the gap between the
  taps, and here the first tap is a 51px crater with a pinned tank in it. `blades`
  bites over "the stretch between the two taps", which is now pin to pin; `through`
  runs the rest to the page's edges; `sever` is the one parent field this row
  *generalises* rather than keeps — its premise is a sentence about one cut, and
  three pins are three cuts each choosing their own half, so what is left is the
  union of them. That is a page in ribbons rather than a page in two, and it is
  kept because the parent still does it three times cheaper and better aimed. The
  union is also why the drop point is asked of the run and not of a cut
  (`Game:severed`): each of the three would otherwise put its crowd down on one of
  the other two's offcuts.

**The TACK** and the **CRATER** are `pool` rather than `thread`, and the field
exists because two of the seven parents are not line tools. You do not string paste
between two points — paste is a blob — and a rubber's shove is radial. So the mark
is one dab centred on the pin, at the crater's own 25.

- `Game:poolAt` is short and three lines of it are load-bearing. **The path is the
  same point twice**, because `Stroke:lingerTick` refuses a path under two points
  outright and every walk that measures a mark is written against segments — a dab
  has to be a segment of no length, not a lone point, or the paste would never
  re-freeze anything. The one hit is a zero-length `damageSegment`, which is
  `lean`'s geometry and puts the shove radially out of the pin. And it fires
  **after** `Pin:land` (which runs inside the drop's own update, where this runs
  after it returns), so what a pool finds is the *survivors* — which is the whole of
  why the CRATER works: the crater kills everything but the tank and then throws the
  tank into whatever is walking in behind it.
- The TACK (GLUESTICK + PUSHPIN) is the sharpest pair in the family because the
  gluestick deals **no damage at all** — it has never had anything to be holding
  things for — and it needs no `apply`, the MOAT's reason exactly. Its two
  one-stamp fields (`fade = 1`, no `edge.rough`) are argued on the row.
- The CRATER (RUBBER + PUSHPIN) drops `lean` and `scrub`, which is what the CLEARING
  drops and for the same two sentences: nothing rests and nothing is charged by the
  pixel. `ram` is built by the unlock because `scaleDamage` reaches `tool.ram`.
  `life = 0` means the mark is culled on its first update even while `strung`, which
  is the rubber's own "nothing outlives the rub" arriving without a clause.

**The VOLLEY** (STAPLER + PUSHPIN) is the last of the family and the odd one in it:
the only fusion in the catalogue whose two parents **already share a gesture**. Both
are a `drop`, placed by the same tap, arriving down the same code path; the two rows
have differed in nothing but the contents of one block since the day they were
written. So there is no nib to borrow, nothing to string and nothing to pool. The
fusion is the two blocks laid over one another — which is worth doing because they
are opposites field for field. A pin is one big telegraphed decision (51px, 10
damage, half a meter, a quarter-second in the air); a staple is a hundred small ones
(15px, 2 damage, a tenth of a meter, instant). Take the pin's numbers and the
staple's gesture and you have a tool; take them the other way round and you have a
staple that makes you wait, which is nothing at all. There is exactly one
interesting way to read the pair.

Three fields come across from the stapler and **each retires a pushpin level rather
than sitting beside it**:

- **`instant`** takes the fall off, and it is the one flag in the catalogue that
  removes a *telegraph* rather than adding an effect. `Pin.new` reads it beside the
  `driven` flag a compass leg sets, and they are deliberately different halves of
  one idea: a driven pin was never tapped and never lands, where an instant one is
  tapped and lands normally with nothing to wait out. So `landed` stays false and
  the landing happens the ordinary way — in fact on the same frame, since
  `Game:updateDrawing` runs immediately before `Game:updateDrops`, so a pin tapped
  with no fall punches its crater inside the `Game:update` that created it and is
  never drawn in the air. The shock ring is then the whole of the event rather than
  its tail, which is why that ring exists separately from the falling one. It is
  also what makes the drag below work at all: a raked pin with a quarter-second fall
  would land a quarter-second behind your finger, which is a seam laid where you
  *were*.
- **`rake`** is the gesture, and it is the stapler's own finale unchanged, running
  through the same `Game:rakeDrops`. **A tap is still one pin** — the tool is the
  pushpin until you hold the pointer down, so nothing about how you already used it
  is taken away — and holding and dragging rakes a seam of craters. `every = 48`
  against the staple's 12 is the parent's written rule read at this size: there the
  spacing is set so the circles just overlap at a 7px bite, here so they just
  overlap at a 25px one. So a seam is a chain of holes rather than a stripe, **no
  body is ever inside two craters at once**, and the pin's "kills everything caught
  but the tank" survives per crater exactly as written. A meter is four pins, so a
  drag is about 145px of seam, 51 wide.
- **`crit`** replaces the pin's `point`, and the swap is the fusion's argument
  rather than a balance decision. Both are a multiplier on one hit and they differ
  only in what decides it; `point` doubles the body the point came down on, and
  *aim* cannot decide anything on a tool whose gesture is a drag — what you choose
  in a seam is a line, and which body each 48px step lands its point on is luck, so
  the level would pay out on the one press in a rake that is still a tap. A roll
  works identically on a tap and on the fortieth pin of a seam. What makes it
  legitimate is the rate: the stapler's own crit level is written on the claim that
  a one-in-five is a *rate* only when the sample is large, "where the same roll on a
  pin you get two of from a full meter would only ever be a story about one pin".
  Four a meter, raked, is that sample. The drag legitimises the crit and the crit
  pays for the aim the drag gave up.

What survives from the pin is the crater, the hold and `drive` — and `drive` is where
a seam pays off in a way a tap never could. Its own row is careful that "a pin dropped
on a *lone* skull changes nothing at all": the exception to "the tank walks out of the
crater" has to be earned through the crowd standing round it, and a rake is how a
crowd gets under a circle on purpose. Nothing doubles up, the craters not overlapping,
so what a seam does to a grin is hit it as it goes past and again on the next step.
**The tank dies to being raked across.**

Two more things are specific to this row:

- **It is charged per pin, not per press**, and it is the only row in the family
  whose press is not a fixed amount of tool. A drag is charged as it goes
  (`Game:rakeDrops`), so the meter and not a count caps the seam and a rake that runs
  dry stops where the ink did. `ink = 0.25` is **half what every other fusion in the
  family charges for a press** and a little over half the pushpin's own 0.45, so a
  meter is four craters against the pushpin's two and the stapler's ten — between its
  parents, and countable, which matters more than it looks. The halving is what the
  stapler brings: its own four levels are written on the one invariant they never
  touch ("ten a meter is still ten a meter"), so what it lends is not a discount it
  never had, it is the *rate*.
- **It is the one pushpin fusion whose `drop` is not the shared `PIN` table.** The
  other seven eat the parent whole and move nothing inside it, which is what let one
  table do for all of them; this one drops a field `PIN` has and adds three it does
  not. `crit` and `rake` stay shared one level down on `Tools.copy`'s terms, for the
  TACK's reason — nothing ever writes into either, and `scaleDamage` steps over
  `crit.mult` by name because it is a multiplier on damage already scaled. So the row
  needs no unlock `apply`.

One of the stapler's four levels has nothing to land in, on the CLEARING's terms:
`prise` is wire pulled back out of the paper for a second bite, and what this row
drives in is a pin — a hole, with nothing to pull.

**One routing change was needed and it is a real one.** `Game:updateDrawing` used to
test `sweep, snap, drop, cut`; it now tests `sweep, drop, snap, cut`, or a row
carrying `drop` and `snap` would be *aimed*. The order is a precedence list rather
than an accident: the two gestures worth borrowing come first, in the order they
borrow from each other — a sweep beats a drop because the compass fusions put a drop
on the arm, and a drop beats a snap and a cut because the pushpin fusions cast those
between two pins. Nothing else moved; no existing row carries two blocks whose order
this changes.

**Three parent fields are dropped and each for a different one of the three
reasons the catalogue already had.** The pencil's `flow` and the marker's `stack`
are the LASSO's `flow` rule — numbers nothing here would read, since nothing is
charged by the pixel and a straight line never crosses its own ink. (Two threads
crossing is not `stack`: they are two marks, they both tick, and where they cross
the crowd takes both — the level's payoff arriving through the tool's geometry
instead of through a field, and the reason a run drops pins in a lattice rather
than in a line.) The pen's `smooth` is the CORRAL's rule, harder: a thread is laid
whole between two fixed points in one frame, so a nib chasing at 26 would cover a
fraction of the gap and the rail would never reach the far post — a number that
would be read and would lie. And the pen's `keep` is the one parent level in the
catalogue that **a fused row already had**: `thread` holds every mark on all three
rows for as long as both its posts are in the page, whether the parent paid for it
or not. Writing `keep` there would buy a rule the row has, in a form that reads the
wrong list — a fence built pin by pin is not one gesture, and `holdWalls` would drop
every rail but the newest as you built the thing. What it bought is bounded better
by the posts than by the rule: a pin holds four seconds, so a player who keeps
tapping still cannot lattice the page shut.

Everything else falls out. `Walls:rebuild` files a thread's path at the nib's own
radius exactly as it files a line you drew (`stringThreads` dirties the index as it
lays, which is `Compass:layBands`' one line for its one reason), `Stroke:lingerTick`
stings whatever leans on a rail and burns whatever stands on a cordon,
`Game:updateBurning` sets alight whatever crosses one, `Stroke:pop` takes the rank
with a rail when it finally goes, and `scalePersistence` reaching both `tool.life`
and `drop.life` means the fixative lengthens the fade *and* the posts holding it up.

**A second block being a real block is load-bearing**, not tidiness. Every name in
`Tools.BLOCKS` is already walked, so the SPINDLE's `drop` gets the sharpener's
damage and the fixative's hold (4s becomes 8.6s on a maxed run) and the FOLD's
`snap` gets the sharpener's 12 and the knock multiplier, with nothing added to any
of those walks. Loose fields would have got none of it. It is also why neither row
needs an unlock `apply`: `Tools.copy` makes both of a row's blocks fresh every
rebuild, so there is no shared table for a multiplier to compound into.

The numbers are all parents', including the one place the parents disagree:
`damage` is the pushpin's **10** and not the compass's 12, because the pushpin's own
row argues for it — "anything that killed outright would leave the pinning with
nothing to pin" — and that sentence is this tool's entire design. `knock` goes the
other way (the compass's 130 where the pushpin's block has none) on the moat's
split: the block is what goes into the page, the sweep is what the arm does on the
way past. And `bite` is doing double duty by coincidence rather than by design —
the pushpin's third level is written down as "the compass's bite fallen from
above", so the two lines each bought a copy of one level.

#### The ruler's seven

The third family, and the one whose argument is the shortest to state. **A ruler's
mark does nothing.** Everything within the band takes the hit and is thrown clear of
the line to both sides at once, and what that leaves is a corridor across the page
with a ruled pencil line down the middle of it — and the corridor closes the moment
the crowd walks back into it, because a pencil line is not terrain, not fire, not
paste and not a fence. The ruler opens a lane and has never been able to keep one.
So the second parent is what gets left in the lane.

Nothing about the gesture changes: the press pays, the pivot follows you, the drag
turns it, the release lands it. `Game:trailRuler` then rules whatever *else* is on
the row along the line the ruler landed on, which is the same sentence the other two
families are built out of one storey down — what a compass leg carries becomes the
ring, what two pins can reach becomes a thread, and what a straight edge is holding
becomes the line.

**Every one of the seven is the whole page**, and that is the ruler's own finale
doing the work rather than a decision taken seven times. "IT RULES THE WHOLE PAGE
END TO END" is half a screen diagonal — the only number in the game measured off the
window — and a fusion is only dealt once both its lines are finished, so a fusion
built on a finished ruler cannot land any other way. All seven `apply` the same
`rulesThePage` helper, which is also what the SNAP LINE has always applied.

**After the strike and never before.** The trail is laid once `Ruler:strike` has
returned, which is `Game:poolAt`'s order for `poolAt`'s reason: the ruler has killed
what it was going to kill, so what a trail finds is the survivors. The two are on
the same frame either way — a shove is an impulse `Enemy:update` spends on the
*next* one, so nothing has moved between them — and what the order actually decides
is what the crowd is standing in when each hit lands.

**The one interaction to know before writing an eighth: a ruler that fastens is a
ruler that does not shove.** A held body drops the push it was carrying (`frozen` in
`Enemy:update`, which is the HEM's rule one gesture over), so the TRENCH's paste and
the SEAM's wire both forfeit the shove on everything they catch. That is the
gluestick and the stapler being themselves — neither has ever shoved anything — and
both rows say so.

Four of the seven are a brush and a snap at once, on the HALO's shape:

- **The MARGIN** (PENCIL + RULER) is the only one that costs the corridor nothing,
  because graphite costs it nothing. It rules the band's **two long edges** rather
  than its centre (`margins` on the row, the one row in the catalogue that carries
  it), which is the pair of dashed lines a ruler's aim has drawn since the tool was
  written, made real. It puts the graphite exactly where a ruler has always been
  weakest: inside the band you take 12 and a pixel outside it you took nothing.
  The pencil's `flow` and `loop` are both left behind on the LASSO's rule — there is
  no per-pixel price and two parallel lines never close.
- **The SPINE** (PEN + RULER) is the page's whole diagonal as wall, laid in the frame
  you let go, against the hundred and seventy pixels a pen draws from a full meter.
  What holds it down is **the camera and not a rule**: it divides where you *were*,
  the page keeps scrolling, and the horde spawns off the ring beyond it. It is also
  the one fused row the pen's `keep` lands on cleanly — a ruler is one gesture
  exactly, so ruling the next spine drops the last, where the STOCKADE had to leave
  the level out because a fence built pin by pin is not one gesture. With `pop`,
  replacing your own wall is an attack along the length of the old one. `smooth`
  goes for the CORRAL's reason.
- **The UNDERLINE** (MARKER + RULER) is the one row where the ruler's shove is doing
  the work rather than being spent: everything in the band is thrown out *across*
  thirteen pixels of burning nib, and touching the band at all is two seconds of fire
  that travels with the body. The corridor is opened by throwing the crowd through
  the thing holding it open, and nothing was written for that. Its Spanish is the
  band rather than the pun, because SUBRAYADO is the marker's own name with a letter
  off.
- **The TRENCH** (GLUESTICK + RULER) is the fusion that does not do the family's job,
  and it is the clearest case of a fusion being both parents rather than a
  compromise. Paste holds, so the shove does not happen; what lands is a page-wide
  bar of glue with the crowd standing in it, softened by half again, torn on the way
  loose, and collecting whatever comes within twenty-six pixels.

Three carry no brush at all:

- **The PARTING** (RUBBER + RULER) is the second panic button, after the CLEARING.
  A rubber leaves nothing, so there is nothing to leave in the lane and the rubber's
  half lives inside the block — where it takes the band off. `snap.wipe` is
  `sweep.wipe` in the other block and means the same thing: **what a block reaches,
  not by how much.** The reach becomes the ruler's own `length`, which on a finished
  ruler is half a page diagonal, so the whole crowd is chipped for 2 and thrown
  straight away from the line, wherever it was standing. What you are choosing is an
  *axis* rather than a place. Like the CLEARING it leaves the rubber's `lean` and
  `scrub` behind, and like it it builds `ram` in the unlock's `apply`.
- **The SEAM** (STAPLER + RULER) presses one staple every twelve pixels of the line
  (`Game:seamAlong`), which on a page diagonal is a little over thirty — within one
  or two of what a fully opened HEM lays round its rim. `rake.every` is the one field
  in the catalogue with **three readers**: a finger (`Game:rakeDrops`), an arm
  (`Compass:loadSeam`) and now a straight edge. It is **the dearest single press in
  the game** at 0.9, and the stapler's own invariant is why — every level in that
  line is written on "ten a meter is still ten a meter", so wire cannot be free. The
  HEM answers that with a price the drag pays as it opens (`sweep.per`); here the
  count is decided by the screen rather than by the player, so the whole of it is one
  number on the row. Its wire carries `prise` like every other finished stapler
  block, so a ruled seam holds the lane for two seconds and then comes out of it in
  one go for a second 6.
- **The GUILLOTINE** (SCISSORS + RULER) casts a cut along the same line. The
  scissors' whole price is the *gap* between their two taps and a ruler has no gap,
  so what this buys is a cut that can be **aimed** — paid for with the one thing a
  ruler cannot give, a line that goes anywhere but through your own feet. 12 from the
  band and 20 from the blades is 32, the deepest single hit in the game, two short of
  the grin's 34. `through` is written at **false** and the false is the argument:
  what it buys the scissors is a cut that crosses the page, and this row starts
  there.

  **And `sever` is the level this row is really about, because it had to be re-read
  to land at all.** It lifts "the half you are not standing on", and a ruler's line
  goes *through* you: at the moment the cut opens there is no such half. Every other
  cut in the game freezes the answer at the tap that placed it, off the sign of one
  dot product; freezing one here would decide a page-wide finale on a floating-point
  coin toss. So this one keeps asking. `sever.follows` — one field, one row —
  makes `Scissors:update` call `Scissors:takeSides` every frame instead, which
  re-reads the half off the player's live position: **straddle the slit and neither
  half goes, step off it and the half you left goes with everything on it, cross
  back and it is the other half instead.** The straddle is measured against
  `player.radius` rather than the cut's `width`, because the question is about the
  body and not about the blades, and a `want` of zero means "neither" everywhere it
  is read — `Scissors:offcut`'s strict `> 0` answers false with no clause of its
  own, `Scissors:update` skips the sweep rather than asking the horde for a
  page-sized circle to be told so, and `Scissors:drawSever` returns early, since
  the arithmetic below it would read a zero as one of the two signs and tear off
  whichever it happened to be.

  It is the same move the TEAR LINE made on the same level from the other side —
  three pins are three cuts each picking their own half, so what is left is a page
  in ribbons — and neither costs the parent anything: an ordinary cut still freezes
  its half, because a cut you placed with two taps has a side you *chose*, and
  having it follow you afterwards would take a decision away rather than hand one
  over. What this turns is the ruler's own central fact from the thing that broke
  the level into the thing that aims it: the pivot is your feet, so the offcut is
  wherever your feet are not, and choosing it is **walking** rather than tapping.

  The FOLD is still the row to read beside this one, since it gave up the ruler's
  own finale for the mirror image of the same fact — how far a chord reaches is not
  the tool's to decide. Between them: **the pivot is your own feet, and every parent
  level that assumed otherwise has to be looked at.** One of the two survived the
  look.

**The one routing problem this family created has no answer in a list.** The pushpin
casts a ruler between two pins, so `drop` must beat `snap`; the ruler presses a seam
of staples along its line, so `snap` would have to beat `drop`. There is no order
that is both. The fix is not a flag: the SEAM's staples are written *inside* its
`snap` block as `wire`, which says in the shape of the row what a flag would have had
to say in a branch — that the wire is what the straight edge is carrying and never
the gesture. A block that is not the gesture may live one level in; a block that
might be cannot. `scaleDamage` then finds `wire.damage` on its `Tools.BLOCKS` walk,
and for `cut.blades.damage`'s reason the block is built by the unlock's `apply` rather
than written on the row. `scalePersistence` walks the same list for it: a staple's hold
is a staple's hold whether a finger, an arm, a straight edge or a pair of scissors
drove it.

**And the shape generalised, which is the argument for having written it that way.**
The HINGE (STAPLER × SCISSORS) is the same field inside a `cut` — a staple where each
of the scissors' two taps lands and a seam filling the line between — and it cost the
catalogue one rename and one walk (see **The scissors' own gesture**). The rule "a
block that is not the gesture may live one level in" was written for one row and is
now what two rows are.

#### The pencil's six

The fourth family, and the first with no carrier in it. The three above are one
gesture apiece — a compass reaches away from you, a pin lands where you tapped, a
ruler is aimed — and the second parent is always what the borrowed gesture is
carrying. That covers twenty-four of the forty-five pairs the strip can make. The
twenty-one left are exactly the pairs where neither tool has a gesture worth
lending: **a pencil and a pen have no reach to give each other**, so there was
nothing to carry, cast or string, and for a long time that was the whole reason
those pairings did not exist.

**The answer is a fourth carrier rather than twenty-one exceptions: the stroke
itself.** A line you drag has a length, an inside once it closes, and a mark left
lying on the page afterwards — as much a shape as a ring is — and the pencil is the
one tool that owns all three of those. So the second parent is what the drawn line
is *made of*, or what closing one *means*, and the gesture never changes in any of
the six: press, drag, lift, charged by the pixel. There is no new routing, because
none of these six carries a block at all — every one of them lands in the `else`
branch of `Game:updateDrawing` that a brush has always landed in.

**`loop` is the field the family is really about, and it grew from one payload to
three.** Up to here, closing a ring meant one thing — cut everything inside — and
the only question a fusion asked of it was who drew the ring (a hand, a compass lap,
a circuit of pins). Here the ring is always yours and the question is what it does:

| field | what being ringed costs | row |
| --- | --- | --- |
| `loop.damage` | cut once, the pencil's own | LASSO, DOT TO DOT, DECKLE, STUB, DRAG, STITCH |
| `loop.ignite` | set alight — a burn block, the marker's finale delivered by the border rather than by contact | BLEED |
| `loop.lift` | `{tick}` — the ring is a hole in the page and goes on taking what walks into it off the paper for as long as the mark is on it, putting each one down in the furthest clear corner of the page (`Stroke:sweepRings`, `Game:liftEnemyTo`) — no gem and no xp, because nothing died | CUTOUT |

**And one more field says the ring is drawn rather than only tested.** `loop.wash`
floods the middle with the mark's own ink (`Stroke:drawWash`, in the ink layer,
under the rim); `loop.lift` lays rebaked page into it instead (`Stroke:drawTorn`,
in the *page* layer, beside the cuts' and the compasses' own spans — grey drawn as
a mark would be paired with the page under it and come out as some ninth thing over
a rule). Both walk the ring a row at a time through `pixelart.fillPolygon`, which
is `pixelart.band`'s and the offcut's argument for a shape that is not a half-plane:
a filled polygon plotted a pixel at a time does not tile and comes out holed, where
a span is contiguous by construction. Both use the **same even-odd test the hit is
resolved with** (`Stroke.insidePath`), so what is painted is exactly what will be
taken — the only reason a border is worth drawing the inside of. A ring is kept on
the stroke (`Stroke.rings`) only by a row that writes one of the two, and dies with
the mark, which is the offcut's rule arriving for free.

They are three tested fields rather than a kind, and a row may write more than one.
That cost one real thing: **`scaleDamage` used to read `loop.damage` blind and now
asks for it by name**, because the BLEED writes no damage at all and the CUTOUT
deals none. `loop.lift` is deliberately outside the walk on `sever`'s reasoning —
there is no damage in moving something across the page — which is also what lets the
CUTOUT write its `loop` on the row where the other four have to build theirs in the
unlock's `apply`.

**One new field, and it is the only gesture a brush row can carry.** The STUB is the
pencil fused with the rubber, and it is the one row on the strip that is a different
tool depending on whether your finger moves: drag and it is the pencil unchanged,
tap and it is the whole finished rubber at once — a 7px circle at the point, 240 of
shove thrown radially out of it, and `ram` on what that sends flying. That cannot be
a `drop`: `drop` beats the brush fields in the precedence list at the top of
`Game:updateDrawing`, so a row carrying both would never lay a line. So it is `tap`
on the row — `{radius, damage, knock, ram, ink, slack}` — read by `Stroke:tap` and
fired from the *release* branch of `Game:updateDrawing`, which is the only place
that can tell the two gestures apart: **a press is not a tap until it has ended
without going anywhere**. `slack` is the rubber's own `RUB_HEARD`, already the line
that file draws between a rub that happened and one that did not, and `ink` is a
flat price like a tapped tool's, refused rather than clamped. `ram` is written
*inside* the block rather than out on the row so that only the shove hard enough to
matter ever reads one — a pencil's own 24 would set it and `Game:updateRams` would
clear it unread the next frame.

**The catalyst is the INKWELL and not SELLOTAPE, and that is the family saying which
family it is.** The tape was once the third line of all twenty-four above, and it was
the right one while a fusion was a gesture wearing a payload: what the tape pays a run
for is *time*, which is the currency a run that committed ten levels to two tools
has already been spending. It says nothing about a *line*. The well does — all six
of these are priced by the pixel, three want one long unbroken gesture to work at
all, and the meter is the only thing between a pencil and the whole page. It is
given back untouched on the tape's own terms. Nothing was written for this: `needs`
minus `fuses` has always been the catalyst, and naming a different line there is one
edit to one row.

**And that argument was eventually turned on the twenty-four themselves.** Twenty-eight
of forty-five rows asking for one card is a toll rather than a sentence: a run that
finished the tape opened half the book at once, and `Library:drawEntry` printed the
same word on twenty-eight pages. Each of the twenty-four was re-read against the
question *which line is this row's economy actually about*, and eighteen of them had a
better answer than the tape:

| Catalyst | n | The question it asks | Rows |
|---|---|---|---|
| SELLOTAPE | 10 | *Nothing — and that is the job* | LASSO, MOAT, CORRAL, TACK, MARGIN, SPINE, TRENCH, SEAM, PALING, CLINCH |
| INKWELL | 10 | Does the whole thing fit inside one well? | the pencil's six, PASTEDOWN, SNAG, COLLAGE, SHEAR |
| CARTRIDGE | 9 | How soon does the next one come round? | DOT TO DOT, STOCKADE, CORDON, SNAP LINE, TEAR LINE, FOLD, SCUFF, SCORCH, PULP |
| FIXATIVE | 8 | How long does what you left last? | HALO, UNDERLINE, WICK, SPINDLE, HEM, VOLLEY, BUMPER, MORDANT |
| MAGNET | 3 | Where does the reward land? | CLEARING, CRATER, PARTING |
| TOP MARKS | 3 | Does the reward exist at all? | PUNCH, GUILLOTINE, HINGE |
| BLOTTER | 2 | How much page can one mark reach across? | SWELL, DEADLINE |

Three rules fell out of doing it, and they are the ones to hold a new fusion to:

- **A catalyst that is the line a row cannot play without is a tax, not a choice**
  (the CLINCH's rule). It is what keeps the fixative off MOAT, CORRAL, TRENCH and
  SPINE — rows whose whole worth is per second they are on the page — and what puts
  the SELLOTAPE there instead. The tape's qualification is that it says nothing: it
  is the catalyst for a row where every line with something to say would also be
  that row's prerequisite.
- **The blotter is structurally small.** It discounts by the pixel and flat block
  prices are undiscounted by it (`ink` on a `drop`, a `cut`, a `fasten`), so only the
  seventeen per-pixel rows can hear it at all, and fifteen of those have a stronger
  claim from another line. Two rows is not a gap.
- **The window against the refill is what separates the well from the trickle.** The
  SNAG asks the INKWELL because its hold is two seconds and the meter does not come
  back inside two; the five threading rows ask the CARTRIDGE because `PIN.life` is 4
  and a 0.5 press comes back in about 1.9 (`Tools.REGEN` 0.3, `Tools.DELAY` 0.25), so
  their chain already crosses wells at base. Same test, opposite answers.

The six, and what each one settles:

- **DECKLE** (PENCIL + PEN) — the pen's line drawn with the pencil's point: a wall,
  filed at the nib's radius, on the paper for the pen's nine seconds, scratching at
  9 the whole way, in blue on the pen's ramp and `fade` so the fence still warns
  before it goes. The two halves are one idea and it is the pencil's finale: a
  graphite ring cuts what it holds *once* and then everything walks out, because a
  pencil line is not terrain. Here the ring is a fence, so what was cut is still
  standing in it — and goes on paying for standing there, since the row carries the
  pen's contact level and its `pop` and its `keep` too. It is written at both
  parents finished with nothing left out of either, and what it drops is only what
  would have *lied*: the pen's `smooth` (a nib that trails a hand cannot draw a
  ragged line) and the pencil's `knock` (a fence that shoves is not a fence).

  **It is also the row that needed a field, and `sting` is it.** `damage` is one
  field and the two parents write it meaning two different things: 9 is what being
  drawn over costs — the nib going past, once — and 1 is what leaning on a finished
  fence costs, paid out over the whole line for as long as it stands. Collapsing
  them has to pick and both picks are wrong: at 1 this is a pencil that scratches
  for nothing, and at 9 it is a wall you can keep indefinitely dealing a skull a
  second to a rank with nowhere to go. So the row says both, in the placement `pop`
  and `loop` already use — what a mark does after the stroke is over has never been
  the same field as what the stroke does. `Stroke:apply` takes a `lingering` flag
  and prefers `sting` when there is one, defaulted to `damage`, so no other row in
  the catalogue changes.
- **STUB** (PENCIL + RUBBER) — one object rather than two, and two complaints that
  cancel: a pencil has no gesture for "not now", and a rubber has to be scrubbed so
  it is only a weapon in the hand of a run already holding it.
- **BLEED** (PENCIL + MARKER) — the band gives up *touching* and buys *surrounding*.
  The row carries no `ignite`, so `hasFire` stays false and nothing that crosses the
  band catches; `loop.ignite` carries the marker's own burn unnudged. It is the
  CLEARING's kind of fusion — a fused row taking a *central* fact off a parent — and
  the argument is that a band which ignited on contact *and* on enclosure would have
  bought nothing, since everything inside a ring you just drew has been touched by
  the drawing of it.
- **DRAG** (PENCIL + GLUESTICK) — the one gluestick level that acts on what the
  smear has *not* caught, feeding a blade instead of a hold. The hold, the softening
  and the tear all go, which is the argument rather than a trim: a body dragged onto
  a pencil line does not need to be held there. `pull.range` is 42 against the
  gluestick's 26 and that is the same field measured off a different nib rather than
  a nudged number — `Stroke:pullTowards` reaches `radius + range`, so a 4px point
  with 42 puts the field's edge exactly where a 20px head with 26 does.
- **CUTOUT** (PENCIL + SCISSORS) — the scissors' finale with a shape you drew round
  it. **Nothing inside is hurt**; it is taken off the paper with the paper, so the
  row inherits the scissors' price along with the effect and the price is the point:
  a border you can draw round anything at all cannot be allowed to kill anything at
  all. It is also the only one of the six that drops the pencil's `flow`, and that
  is the CORRAL's rule rather than the LASSO's — the number would be read here and
  would *lie*, since a discount that deepens the longer the line runs is a discount
  on how much page you ring. `loop.lift` is `{tick}` rather than a flag, on the
  scissors' own contract and the scissors' own half-second: a hole in the page is
  not something that emptied itself once, it is page that is not there, so it goes
  on answering for arrivals — which is what makes the grey honest, since there is
  page missing for exactly as long as the ring is on the paper.

- **STITCH** (PENCIL + STAPLER) — the STUB's shape with the arguments swapped: there
  the tap is the panic and the drag is the work, here the tap *is* the work and the
  drag is what the work gets fastened to. Tap and a staple lands; drag and you draw
  the finished pencil's line with a staple driven into each end. Every one of them
  crits, and that is the parent's own reasoning rather than a number handed out —
  the stapler rolls one in five because a rate is honest when the sample is large,
  and two staples a gesture is not a large sample, so the chance goes to 1 for
  exactly the reason it was set to 0.2. What pays for it is the stapler's *finale*:
  `rake` cannot be here, because the drag is already spent on the pencil, so the
  trade is a missing field rather than a nudged number.

  It needed one field, `fasten` — a whole `drop` block on the row without being the
  row's block, which is the SEAM's `snap.wire` one storey out and means the same
  thing: a drop something other than a tap is pressing. **The two ends go in at the
  two moments**: the near one from the brush branch on the press, the far one from
  the release branch if `Game:wasTap` says the finger travelled. It laid both at the
  release first and that was wrong for a reason worth keeping — a stapler lands the
  instant you tap, with no fall and nothing to telegraph, and that is most of what
  the tool *is*; holding the first staple back until the finger lifted put a wind-up
  on the one tool written not to have one. Each is priced and refused on its own, so
  a meter that can afford the press and not the release fastens the near end and
  leaves the line hanging, which is the failure you can see.

#### The six without a pencil

The other fifteen pairs, six of them written: **BUMPER** (PEN + RUBBER), **SWELL**
(PEN + MARKER), **SCUFF** (RUBBER + MARKER), **PASTEDOWN** (PEN + GLUESTICK),
**PULP** (RUBBER + GLUESTICK) and **MORDANT** (MARKER + GLUESTICK) — which is every
pair of brushes in the game. Same family and same carrier — the stroke, no block,
the `else` branch of `Game:updateDrawing` — and one thing genuinely new, which is
the decision the pencil used to make for free.

**With two ordinary brushes, nothing in the pair says which of them is the line.**
The pencil could never lose that argument: cheapest ink in the game, the tool every
run opens holding, and the only finale on the strip that claims an *area* by drawing
its border. Take it out and both parents are a nib with a price, a clock and a thing
the mark does afterwards. Written blind, a fused brush is two rows averaged — a nib
of some middle width in a colour neither parent uses, doing a bit of both jobs — and
a run holding one could not tell you what it had.

**The rule is the MOAT's, off the arm and onto the page: one parent's mark is the
body, the other is what happens at it — and the body is whichever parent's mark is a
*place*.** A pen line is terrain and a marker band is a surface; both are somewhere a
body can be. A rub is an event that happens to whatever is under the tip and is
nowhere at all once it is over. So of the first three the pen writes the body twice
and the marker once, and the rubber — in both pairs it is in — writes what the place
*does* to whatever arrives at it. And where the second parent cannot be that, it becomes the
other gesture: the SCUFF is the STUB's tap/drag split, taken because a rub delivered
*by* a band would either be a band nobody can be made to stand on or a nib you have
to scrub, which is the rubber you already had. The SNAG is the third and the only one
that turns the split the other way up — there the *drag* is the rub and the tap is a
staple — which is what a pair with no mark to lend at all has to do: see **The
stapler's four**.

**Then the gluestick arrived and made the rule say what it actually means.** A smear
is a place too, so PEN + GLUESTICK is two places and "whose mark is a place" settles
nothing on its own. What settles it is that **paste is the stronger place**: a fence
says where a body may not stand, and paste says where a body *is* standing and will
go on standing. So the smear is the mark in all three of the gluestick's rows and
the second parent becomes a property of it — the pen makes the paste solid, the
rubber turns it into a drain, the marker makes it burn. That ordering is worth
keeping, because the fence is the one parent that could have argued and it lost to
the one thing a fence has never been able to do.

- **BUMPER** (PEN + RUBBER) — the sentence the pen was written against: a fence that
  shoves. What makes that false for a pen and true here is which way the shove
  points. A nib shoves along its own travel, away from wherever the hand happens to
  be; a wall shoves *out of itself*, and out of a wall is the one direction on the
  page that never needs aiming, because the fence already knows which side of it you
  are on. `Stroke:apply` has always pushed away from the line rather than along it,
  for the eraser's sake, and this row is that arithmetic being the point of
  something. 240 out of the ink is the finished rubber's throw and `ram` is where the
  damage actually comes from: a rank pressed against a wall by the rank behind it is
  a magazine of projectiles aimed at its own crowd. It takes the pen's `pop` and
  `keep` and contact tick, and leaves out three of the rubber's numbers on the
  LASSO's rule — `lean` would be the tick's own hit priced twice, `scrub` prices a
  back-and-forth a fence cannot make, and `crumbs` is the CRATER's lesson (a rate per
  stamp off a travelling tip, on a ballpoint laying a wall). **No `sting`**, and that
  is the DECKLE's field being unnecessary rather than forgotten: 9 against 1 is a
  difference a row has to say out loud, where the nib's 2 and the fence's 2 are the
  same event twice.
- **SWELL** (PEN + MARKER) — nine seconds of burning band, which is the pen's clock
  on the marker's mark and not a new number anywhere: `ignite` is the marker's
  finale unnudged, and what lasts longer is the *mark*. Stretching the burn as well
  would be inventing rather than combining, and a burn is a body on fire rather than
  ink on paper — the one duration the fixative deliberately does not sell either.
  It drops the marker's `stack`, and the omission is `pace`'s fault rather than a
  level going missing: layers stacking where you draw over your own ink is only
  usable if you can *see* the doubled ink, and what makes it visible on a marker is
  the rim pooling (`Stroke:draw`). A ballpoint has no rim, so the level would be an
  invisible tripling wherever two stretches crossed.
- **SCUFF** (RUBBER + MARKER) — the finished marker on the drag, the finished rubber
  on the tap, and nothing taken off either, because the two are never doing anything
  at the same moment. What pays for it is one meter under two gestures: the band is
  the dearest ink in the catalogue by the pixel and the tap is a flat tenth of the
  well on top of it, so a page you have scribbled over is a page you cannot shove
  anybody off. The STUB is the same shape against the *cheapest* ink in the game,
  which is what makes that one a panic button and this one a decision. Its `tap` is
  the STUB's to the number and written out again rather than shared — a table two
  rows point at is a table the sharpener multiplies twice.
- **PASTEDOWN** (PEN + GLUESTICK) — paste that has set hard: nothing in, nothing
  out, and both halves are one flag. What is inside stays inside because it is
  *stuck* (the freeze is re-applied every tick); what is outside stays outside
  because the paste is filed as terrain at the head's own radius. **The two fit
  together with no new code, which is the test a fusion is supposed to pass**:
  `Enemy:resolveWalls` returns early on a frozen body — written that way so the crowd
  could jam against a glued thing instead of squeezing it out of the smear — so the
  bodies the paste caught are exactly the bodies the wall does not eject. The hold and
  the fence agree about who is inside. Outside, `pull` hauls the crowd to the rim, the
  wall stops it there and the tick catches it there, so a rank ends up *stuck to the
  outside face* taking the pen's 1 a tick — a second fence made of the crowd. It
  carries `sting = 1` against `damage = 0`, which is the DECKLE's field doing exactly
  what it was added for, and the pen's ramp and `fade` rather than the glue's paper,
  because terrain has to read as terrain and the fade is the warning that a prison is
  about to open.
- **PULP** (RUBBER + GLUESTICK) — the CLEARING read backwards: that row throws
  everything out of a swept disc, this one hauls everything into the paste and holds
  it. **The reversal could not be a `knock`, and finding out why wrote the row**:
  `Stroke:apply` knocks and *then* freezes, in the same call, and a frozen body drops
  its push on the next update — so a shove that lands a body in paste is a shove the
  paste cancels. The shove became a haul instead, in a field the gluestick already
  had: `pull.speed` is the rubber's own 240 read as a speed rather than an impulse,
  where the glue's is 30, and `pull.range` does not move because a 240 shove throws a
  body 27 pixels and the field already reaches 26 — the same arm's length from the
  other end. `scrub` is kept here where the BUMPER dropped it, and the contrast is the
  point: you draw a fence once and leave, and you rub a pile until it is dead. The
  rubber's `ram` is the missing field that pays for the reversal — nothing is flying,
  so there is nothing for it to read.
- **MORDANT** (MARKER + GLUESTICK) — paste that bites, and the name is the row: a
  mordant is the size a gilder lays to make gold stick, from *mordere*. The gluestick
  deals nothing on purpose and three of its four levels are written so the damage
  comes from *somewhere else*; this is the somewhere else. 5 a tick on the marker's
  own cadence, softened to 7.5 by the paste's own hold. It drops two marker levels and
  both are the pairing making them redundant: `ignite` buys the one thing the marker
  could not do — hurt something that kept walking — and nothing that touches this
  mark keeps walking, which is the BLEED's argument arriving from the other side. And
  `stack` fails on a head this wide, because `Stroke:revisits` asks whether the head
  is back over covered ground: on a 13px band at 2px spacing that is a deliberate
  second pass, and on a 41px one it is any curve at all, so the level would read as a
  permanent tripling rather than as a reward for a motion.

**One new field, `pace`, and it is the first choice the drawing has ever offered
inside a single stroke.** `{over, thin}`: at or above `over` pixels a second the nib
is the thin one, under it the row's own `radius`, decided per dab off how fast the
*nib* was travelling — the nib and not the pointer, because `smooth` is what a fast
hand actually gets, and pricing the hand would sell the thin line for a flick the nib
never made. It has four readers and they are one fact said four times:

| reader | what it does |
| --- | --- |
| `pacedStamp` (`src/tools.lua`) | one stamp function that asks each dab which nib laid it — `Stroke:draw` walks the whole mark in a single pass, so a stamp function is the only thing that ever sees an individual dab |
| `Stroke:reach` | how wide the mark is *now*, for the hit off the travelling nib (`Stroke:damageSegment`) |
| `Stroke:paceRate` | the price by the pixel, as the ratio of the two nibs rather than a number of its own — half as much ink on the page is half as much out of the meter, and a row cannot say one thing about its width and another about its cost |
| `Stroke.pathR` | the nib's radius at each recorded path point, so a tick off the finished line reaches as far as the stretch the body is standing on. Beside the path rather than in it: the path is flat pairs and four things step through it two at a time |

What `ignite` tests is deliberately the widest nib (`Stroke:covers`,
`Game:updateBurning`) — a burn is a body that touched the ink, and two pixels of
slack there is the pen's `graze` argument.

**Their catalysts are picked per row, which is the one thing the pencil's six do
not do.** All six of those ask for a finished INKWELL, and that reads as one sentence
about a family whose rows differ in what they *draw*. These six differ in how they
are *paid for*, so each asks for the ink line its own row is about: the FIXATIVE for
the fence that has to outlive the panic and for the paste whose whole worth is
per-second (BUMPER, MORDANT), the BLOTTER for the nib that charges by its own width
(SWELL), the CARTRIDGE for the rows spending one meter on two gestures or on one you
never want to lift (SCUFF, PULP), and the INKWELL for the widest mark in the game,
where the well is the difference between a bar of paste and a prison (PASTEDOWN).
A catalyst is a condition and is never consumed, so two of them naming the same line
costs nothing — what it is for is aiming the card at a build.

**With the six above, every pair of brushes in the game has a row**, and everything
left is a brush with a nib-less block. Three of those are written and they are the
next section.

#### The stapler's four

**PALING** (PEN + STAPLER), **WICK** (MARKER + STAPLER), **CLINCH** (GLUESTICK +
STAPLER) and **SNAG** (RUBBER + STAPLER) — the first rows in the fourth family whose
gesture is not a stroke.

The twelve above are all a line you drag, and that is exactly why the nine pairs left
over were stuck: **you cannot make the stroke the carrier when one parent has no
stroke.** What these borrow instead is the one *block* gesture that is a drag. `rake`
is the stapler's finale — a staple every twelve pixels for as long as you hold — which
is a path across the page, laid by a hand, at a fixed spacing: a stroke in everything
but name. Two of them hang a mark off it and the third puts paste on the wire. The
fourth borrows nothing and hands the drag back to its brush instead — see **SNAG**.

**Which makes them the pushpin's threading family with one number changed**, and
`LINK` in `src/tools.lua` is the number. `thread.reach` is 120 for the pin and 14 for
the staple, and that difference is the whole of the shape: at 120 every pair of posts
inside the reach gets a rail, so a handful of taps is a *shape you build* (the
STOCKADE, the CORDON); at 14 a post can only see the next one in its own seam, so
thirty presses raked along a drag come out as one continuous mark (the PALING, the
WICK). Same field, same `Game:stringThreads`, no new code — `thread` and `rake` had
simply never been on the same row, and a raked drop goes through `Game:dropOne` and
gets stamped and strung exactly as a tapped one does.

- **PALING** (PEN + STAPLER) — the pen's third answer to the same question, after a
  fence ruled where your hand is not (CORRAL) and a fence built post by post
  (STOCKADE): a fence you **drag**. What it trades against the STOCKADE is the corner
  and the crater — a pin is 51px of page and a four-second hold, and two of them from
  a full meter buy one rail, where fifteen staples buy fourteen rails in a row. It
  keeps the pen's `pop` (so a seam left to run out goes off along its own length, a
  staple at a time) and drops `keep` on the STOCKADE's argument: `thread` already
  holds every rail while both its staples stand, and `Game:holdWalls` holds *one
  gesture's worth* — on a row that strings fourteen rails at once it would drop
  thirteen.
- **WICK** (MARKER + STAPLER) — the CORDON dragged instead of placed, and the name is
  the row: a cord that burns along its length and is held down while it does, which is
  the being-held the marker's band has always been short of. `stack` is left out for
  the CORDON's reason, word for word — a straight twelve pixels between two staples
  never crosses itself.
- **CLINCH** (GLUESTICK + STAPLER) — the only one of the three that strings nothing,
  and the gluestick's contract moved onto a fastener. A smear holds what stands in it
  for as long as it is on the paper *because the freeze is re-applied every tick*; a
  staple bites once and whatever wanders in afterwards walks over the wire. **`tacky`
  is that difference and nothing else**: every 0.4s the circle is swept and anything
  in it is fastened again, for as long as the staple is in the page (`Staple:catch`).
  A catch is deliberately not a bite — no damage, no crit, because a staple that hit
  everything on it three times a second would be a weapon and this is a fastener. What
  collects is the stapler's own third level: `prise` tears the wire out at five seconds
  and bites everything still standing where it was stuck, at 6, a fifth of them 18, and
  half again on both from the paste's `soften`. The glue's `tear` is left out because
  `prise` already *is* coming loose costing something.
- **SNAG** (RUBBER + STAPLER) — the one of the four that borrows no seam, and the row
  this family was stuck on for a long time. A rub is an event at a point and a staple
  is a fastener at a point, so a seam of them raked beside a rub is either two things
  happening in the same place or *a shove undoing the fastening laid next to it*. The
  fix was noticing that the second reading is the tool: if a rub undoes a fastening
  then **the rub is what takes the staple out**, and the stapler already had a level
  about the wire coming out and biting on the way (`prise`). So the seam is given up
  and the carrier is the STUB's — a gesture each. Tap and a staple lands, at the
  stapler's own numbers and the stapler's own one-in-five; drag and it is the finished
  rubber, unchanged, *and* every staple the rub crosses is prised on the spot, early,
  with the crit **certain** rather than rolled (18 through everything the wire holds).
  The row is therefore the only two-step gesture on the strip: fasten the front of the
  crowd down a tap at a time, then sweep across the lot and collect.

**What `SNAG` needed, and it is the shape to copy for a block against a brush that
cannot share a gesture.** Three fields and one function, none of them a special case:

- `fasten.tapped` — `fasten` (the STITCH) is a whole `drop` block on the row driven at
  the *stroke's ends*: the near one on the press, the far one on the release if the
  finger travelled. `tapped` reads the same `Game:wasTap` the other way round —
  nothing at the press, nothing at the far end, one staple *because* the finger never
  went anywhere. That is the whole of how a row can be a drop for one gesture and a
  brush for the other, and it is why the staple is not a `drop`: `drop` beats the brush
  fields in `Game:updateDrawing`'s precedence list and the row would never lay a line.
- **The mark's own hit is held back while the press could still be a tap.**
  `Stroke.touches` already means "does this mark hit anything"; on this row it is the
  one place the answer is a fact about the gesture rather than about the tool, so
  `Game:updateDrawing` sets it from `wasTap` every frame (it goes false once and stays,
  both numbers only growing). Without it a tap taken *while running* rubs the few
  pixels the page slid under a still finger — throwing the thing you were about to
  fasten twenty-seven pixels clear of the staple, on the exact press the tool is for.
  It is `Game:wasTap`'s own lesson arriving one storey down.
- `snag` on the row + `Game:snagDrops` — **the fourth relationship between a mark and
  something driven into the page, and the first that goes the other way.** A thread is
  strung between two drops, a pool is laid round one and a seam is pressed along a
  ruled line; all three are a mark arriving *because* a drop is there. This is a mark
  arriving and taking the drop away, so it lives in `src/game.lua` for the threads'
  reason — neither `src/stroke.lua` nor `src/staple.lua` can see both. What may be
  snagged is the *drop's* business: a module answering `snag` can come out of the page
  and one that cannot is never asked, so a pushpin refuses in one comparison without
  being named. Measured against the wire (`Staple.REACH`, half the crown) rather than
  against the circle the wire holds, so what comes out is what the rub actually went
  over.
- `Staple:prise(game, sure)` — the tear pulled out of `Staple:update` so two things can
  start it, and the tear is now asked about *before* the hold: a wire something has
  already caught is coming out whether or not its two seconds are up. `sure` is the
  crit not being rolled, and only the rub passes it.

Two levels are missing from the row and **the two omissions are one fact said twice:
each parent loses the level that wanted the gesture the other one took.** The stapler
has no `rake` because the drag is the rub (the STITCH's trade, word for word); the
rubber has no `lean` because the press is the staple — a tip that hits where it rests
hits *on the press itself*, which on this row would shove the thing you were fastening
a moment before the staple arrived. What is bought with the two is the certainty.

**And the catalyst is the INKWELL, which is the one of the four ink lines this row can
be aimed at.** The unit of play here is not a gesture, it is a *chain* of them, and the
chain has to fit in one well or it does not happen: the hold is two seconds and the
meter does not come back inside two. The cartridge would only get you to the next
chain sooner. The blotter is the one that *looks* right on a row charged by the press
and by the pixel at once and is the one that cannot be — `scaleCost` discounts the
row's `ink` and a staple's price is `fasten.ink`, one level in, which it does not reach
(the STITCH's staples are undiscounted for the same reason). And the fixative is the
line the row wants most, since it stretches the hold and the hold is the window you
have to get the rub back across — which is exactly why it is not the ask, the CLINCH's
rule: a catalyst that is the line the row cannot play without is a tax, not a choice.

**Two things in `CLINCH` are worth knowing before writing a fifth.** `freeze` and
`life` stop being the same number — they are written twice on every other drop in the
game because a hold handed out once *is* the clock on it, and here the hold is
re-applied, so `life` is how long the wire goes on fastening (5, between the pin's four
and the smear's six) and `freeze` is only how long the last catch lasts. And it is the
one place in the game that hands a **block** to `Enemy:freeze` as the thing doing the
sticking, which is how a `soften` written beside `tacky` rides on the body
(`Enemy:hurt`) — a staple's hold has always passed nothing, and the comment there
names this as the exception. Nothing minds: what is read off `enemy.glue` afterwards is
`soften` and `tear` by name, and a block may carry either.

**The first three ask for a finished SELLOTAPE**, where the twelve stroke rows ask for
an ink line, and the switch back is the honest one rather than a lapse. The ink lines
were right for rows priced by the *pixel*; not one of those three is — they are priced
by the press, ten to a meter, exactly as their parent is. What the tape pays a run for
is time, which is what a run that put ten levels into two tools has been spending. The
SNAG is priced *both* ways and asks for the INKWELL instead, which is the whole of why
it is on a different line: see its entry.

The scissors' own four are written below: STAPLER × SCISSORS under **The scissors' own
gesture**, three of the brushes under **The scissors' three brushes** after it, and the
pen under **The line that is a region** after that — which was the last pair in the
catalogue.

#### The scissors' own gesture

**HINGE** (SCISSORS + STAPLER) — the forty-first, and the only row in the fourth
family whose carrier is neither a stroke nor a drag.

Both parents are blocks, so there is no line to lend and no `rake` to hang anything off.
What carries it is the **`cut` itself**: the scissors' two taps are the gesture,
untouched, and the stapler's wire rides inside the block as `cut.wire` — the SEAM's
arrangement to the field, with the two taps in place of the ruler's landing. It is the
first row in the game where a `cut` is the gesture rather than something cast between
two other things (the TEAR LINE, the SNAP LINE, the FOLD), and it needed no new
carrier: a staple where each tap lands (`Game:openCut`, `Game:closeCut`) and the
stretch between them filled at the stapler's own twelve-pixel spacing
(`Game:seamAlong`, which is the SEAM's own function with the two points handed in).

**The mechanical point is the order of two things that were already there.** The blades
travel (`Game:updateCuts`), and the seam lands the frame the second tap does — so what
the blades arrive at is a row of bodies the wire has just pinned to the paper. The
scissors' one real weakness is that the horde walks out of the gap between the taps; a
stapler is the tool that stops things walking. The TEAR LINE answers the same weakness
by killing what the first tap lined up, and this one by holding it.

Three things are worth knowing before touching it:

- **`sever` is inherited whole and needed no re-reading**, which no other scissors
  fusion can say. The taps are still the parent's taps, so "the half you are not
  standing on" still has an answer; the TEAR LINE had to generalise the sentence to
  three cuts and the GUILLOTINE had to make it re-ask every frame. The row carries
  `through = true` (the offcut is a half-plane through the taps, so the drawn slit has
  to reach the edges or the page would come apart along a line that stops) and the
  parent's own `tick = 0.5`.
- **It is the one row in the game that moves where a price is charged.** The scissors'
  anchor is free *because* it does nothing, and here it drives a staple — so
  `Game:openCut` spends `tool.ink` when `cut.wire` is present, and the row's 0.45 is
  half the gesture rather than all of it. Without that the old rule pays out an
  unlimited stapler: anchor, tap back on the anchor to cancel (which is free and
  always was), repeat. It also makes the cancel honest — you paid for a press and got
  a press.
- **The seam's length is not priced**, unlike the HEM's rim (`Game:sweepPrice`). A flat
  0.45 a tap buys as much wire as you were willing to put between the taps, which is
  deliberate: a long line is staples spread thin over ground nobody is standing on and
  a short one is the whole seam through the crowd in front of you. The choice is where
  the wire goes, not how much of it there is.

`Game:rulerSeam` was renamed `Game:seamAlong` when this row was written, since a
function the scissors call cannot be named after the ruler. `scalePersistence` now
walks `Tools.BLOCKS` for a `wire` instead of reaching `snap.wire` by name — two blocks
carry one now, and the walk is what makes a third cost nothing. `scaleDamage` needed
nothing at all: its BLOCKS walk already finds `block.wire.damage`.

#### The scissors' three brushes

**COLLAGE** (GLUESTICK + SCISSORS), **SCORCH** (MARKER + SCISSORS) and **SHEAR**
(RUBBER + SCISSORS) — the forty-second, forty-third and forty-fourth, and the answer
to the
question the CUTOUT left open: **what carries a cut when there is no ring to close
it with is the mark's own two ends.**

The carrier is one field, `chord` — a whole `cut` block on a brush row without being
the row's block, cast between where the finger went down and where it came up when it
lifts (`Game:chordCut`). It is `fasten`'s arrangement one shape over and the rename is
the whole point of both fields: `cut` is in `Game:updateDrawing`'s precedence list, so
a brush row carrying one *would be* a pair of scissors and would never lay a line —
the same sentence the SNAG's staple is not a `drop` for. `Game:castCut` was already
the function (a cut has always been two points and nothing about who chose them), so
the carrier cost one clause at the release, one `chord` clause each in
`scaleDamage`/`scalePersistence`, and a shared `trimsTheLine` in `src/upgrades.lua`
that writes the parent's finished line onto a row. Two consequences worth knowing:

- **A line drawn back to its own start opens nothing.** A ring has no chord. The one
  brush that cuts what it *encloses* is the pencil, because the pencil is the tool
  that closes rings — so the CUTOUT is not a precedent these three failed to reach,
  it is a different shape, and drawing a circle with one of these is drawing a circle.
- **`chord.ink` is priced on the block**, the parent's own flat 0.3, because the row's
  `ink` is a price per pixel and this is a press. Undiscounted by the blotter for the
  STITCH's staples' reason (`scaleCost` reaches the row's `ink`, not a number one level
  in) and refused rather than clamped: an unaffordable cut simply does not happen and
  the mark you drew still stands.

`tapped` — the field `fasten` already has, read by the same `Game:wasTap` — is what
lets one carrier answer both shapes. Three of the four brushes leave a mark with two
ends; a rub does not, being an event that is nowhere once it is over, so the SHEAR
keeps the parent's *taps* and gives the drag to the rubber. It is the fifth row in the
game that is a different tool depending on whether the finger moves, and the `touches`
clause the SNAG needed is now read off whichever block carries the flag: while a press
could still be a tap it is a pair of scissors being placed, and placing scissors does
not shove. On the SHEAR that is not cosmetic — a shove in the gap between the two taps
would push the crowd off the line the pairing exists to cut.

What each row then argues about is what the ink does with the cut, and no two answer
the same way. Two new fields on the block carry it, both read in `src/scissors.lua` and
both nil everywhere else:

- **`ignite`** (the SCORCH) — a burn block set on whatever the blades cut *and*
  survive, in `Scissors:strike`, past the `elseif` for the CUTOUT's reason. It is the
  same table as the row's own `ignite`, deliberately: the burn the band sets and the
  burn the blades set are one burn, so `scaleDamage` scales it once through the row and
  the chord reads what it wrote. **This pairing could not have existed while a severed
  region despawned** — fire is damage over seconds and a despawn is the end of them, so
  the two halves of the row would have spent the frame undoing each other. A region
  that *carries* the crowd to a corner hands the fire exactly what it wants.
- **`sever.paste`** (the COLLAGE) — seconds of glue laid on whatever the offcut sets
  down, in `Scissors:lift`, which is the first thing in the game done to a body by the
  region that *moved* it rather than by the ground it landed on. `Game:liftEnemyTo`
  gained a return value for it, because the boss is refused at that door and gluing the
  one thing it would not move is holding the eye still where it already stood. No glue
  *block* goes with the seconds: `Enemy:freeze` leaves whatever the body already
  carries, so a body the smear had pasted keeps its softening in the corner and one
  caught on clean paper is simply stuck. `paste` rather than a second `hold` because
  the chord already has one and it is the tap window.

The SHEAR needs no new field at all, and that is the point of it: `knock = 0` is
written on every cut block in the game so no multiplier can move it — a blade
separates, it does not shove — and the rubber is the biggest shove there is. Cut the
page, then sweep the crowd *over* the slit and let the missing paper do the rest.

Two couplings had to learn about these rows and both got narrower rather than wider:
`Game:endStroke` asks `tool.crumbs` instead of `icon == "rubber" or tool.snag` (crumbs
is the field that means *the travelling tip is a rubber* — the STUB and the SCUFF leave
it off precisely because theirs is a pencil or a chisel), and `Game:openCut` /
`Game:closeCut` / `Game:castCut` take the block and its price as arguments instead of
reading `tool.cut` and `tool.ink`, so nothing in `src/scissors.lua` knows which field a
cut came out of.

#### The line that is a region

**DEADLINE** (PEN + SCISSORS) — the forty-fifth, the last pair the ten tool lines can
make, and the only row in the game where **the mark is the region**. The line you draw
is a line the horde cannot cross: anything touching it is lifted off the page and put
down in the corner furthest from you, on the offcut's own half-second, for as long as
the line is there — which the pen's `keep` makes *until you draw the next one*.

**It is the fourth shape a severed region comes in and the first that is not an area.**
A half-plane, a disc and a ring all have an inside; a line has only an on. So the test
is `Stroke:covers` — the question the wall, the wax, the glue and the linger already ask
of a mark, bounding box first — measured against the ink's radius *plus the body's*, so
what answers is a body touching the line rather than one with its centre on it. No new
geometry anywhere. `lift = {tick}` on the row (no damage in it, so it may be written
there — the PUNCH's rule), `Stroke:sweepLine` is the sweep, and it runs on its own clock
beside `linger`'s rather than under it: the two are asking different questions of the
same mark, and pacing a lift off a sting would tie the scissors' number to the pen's.

**The row gives up the pen's `wall`, and that is the design rather than a saving.** A
wall is a line the crowd steers *around* (`Enemy:avoidWalls`), so a row that walled and
lifted at once would almost never fire — the only bodies to touch the ink would be the
ones the crowd's own jostling pressed into it, and the two halves of the tool would
spend the run undoing each other. It is the SCORCH's sentence about fire and despawning
arriving a third time (the CLEARING's about a shove and a fastening is the second).
Without the wall the line is invisible to the crowd's steering — `src/walls.lua` indexes
only `tool.wall` strokes — and then it is not a fence but a **tripwire**, which is the
stronger of the two and the honest price for a level given up.

Two small things fell out of it, both of which made an existing rule more true:

- **`Game:holdWalls` is now reached by `keep` rather than by `wall`.** The hold was
  always a fact about the *gesture* — one gesture's worth of mark held at a time — and
  the guard said `wall` only because until now everything that kept anything kept a
  fence. Both call sites (the hand in `Game:updateDrawing`, the straight edge in
  `Game:trailRuler`) read `tool.wall or tool.keep`.
- **`Game:severed` is no longer only about missing paper.** Its question is "would a
  severed region take a body standing here", and the invariant it keeps is not *is this
  grey* but *can the player see it* — three of the four shapes are holes and this one is
  a blue line. The corner has to clear the line by a whole body (`TRIP_SLACK`, the
  grin's 7, the widest thing the door will move), which is the one way this could
  ping-pong and the whole reason a line belongs in that function.

The balance is the offcut's own bargain at its steepest, and it wants watching before a
number moves. Nothing the line lifts is killed, so a run hiding behind one earns no xp
at all while the difficulty clock keeps climbing; nothing leaves the horde either, so
the spawner's floor never refills and what comes back is the same crowd out of the same
corner. And the boss ignores the line entirely (`Game:liftEnemyTo` refuses it), so the
one fight the tool cannot postpone is the one that ends the run.

Everything else was already there. `Game:layLine` is the six lines a thread and a
ruled line both wanted — a stroke opened, extended the whole way on one call and
finished on the frame it was begun — pulled out of `Game:strand` with the one thing
the two callers disagree about (a thread is held while its posts stand; a ruled line
starts ageing) left with the callers. `Ruler.new` gained nothing; the row is stamped
onto the object by `Game:beginRuler` and `Game:castRuler`, which is `Game:dropOne`'s
stamp for `Game:dropOne`'s reason.

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
`pause.lua` and `levelup.lua` — never during play. Weapons go down one side
margin in the tool selector's own boxes on the same midline, level beside the
box; passives go in one line under the question, same box, level above it; tools
are the selector column itself, in the *other* margin, which grows its levels
while the run is held. Which column is in which margin is `Hud.toolSide` and
follows the thumb stick (see **Coordinates**); a level is always on the page side
of its own box, so the two columns face each other whichever way round they are.
The draft lays its cards out between `Hud.leftMargin()` and `Hud.rightMargin()`,
both of which are fixed and claimed whether or not there is anything in the
column — a margin that appears the moment you take your first weapon would move
the cards under the pointer that was about to pick one.

**A column longer than the page becomes a window onto its list.** `columnRoom`
is how many boxes fit between the safe insets once each end has been left
`columnSlack`: the cut mark, and `EDGE_KEEP` for the furniture that stands at the
ends of a margin (the corner button, the experience bar along the whole bottom
edge, and the deepest of them, the draft's row of bought buttons). A windowed column draws no
slot counter — the mark is in its place, and a lent column has nothing left to
count — so the counter is not in the slack. `columnWindow` is the slice shown,
seven boxes on a 16:9 page. Only a dev switch can trigger it — four slots of each
kind against room for seven — but the rule is written in terms
of room rather than in terms of the switch, so nothing in `hud.lua` has to know
why a column is long.
The strip's window is kept centred on `Game.tool`, which is how it scrolls with no
scroll state at all: the wheel, `Q`/`E`, the number keys and a press on a box all
move the pick, and the window follows. The weapon column has no pick, so it has
the one scroll offset in the HUD, `Game.carryScroll` — stepped a page at a time
by `Game:scrollCarry`, clamped to the foot of the list before it wraps so a last
half page is still seen whole, off a press in its margin (`Hud.weaponAt`,
claimed in `Game:pointerDown` on the paused state only) or the wheel while held,
and clamped in `Hud.weaponWindow` rather than where it is set so a column that
gets shorter or a window that gets taller brings itself back on screen. A cut end
carries a 5-3-1 arrowhead in graphite, drawn on the boxes' own line rather than
the popped one's so it stays put as the pick slides out.

Each of the three carries a slot counter under it (`2/4`, red once full), drawn
on held screens only and drawn even when the count is zero — which today only the
passives ever are, since a run opens holding one tool and one weapon. Two rules keep them
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

**One passive reads what the run's weapons did, and it is the only line in the
catalogue that reads anything.** BANDAID pays a fraction of the damage the run's
own weapons dealt back as health (`mend` on the stats, `Loadout:mend`), and the
number it is a fraction of is measured in exactly one place: `Enemy.dealt` is a
running total of every point that has gone through `Enemy:hurt`, and `Game:update`
reads it either side of the passes that are the run's fire -- `updateBullets`
through `updateWeapons`. Two things about that are load-bearing. Nothing between
those passes touches the crowd (the eye's fan and the boss's blots are aimed at
the player), and everything a *tool* did landed earlier in the frame in
`updateDrawing`, which is the whole of how a line that says weapons means weapons
-- so anything new that hurts an enemy has to go on the correct side of that
window. And what is earned is **owed rather than paid**: the rate ceiling
(`MEND_MOST` in `src/loadout.lua`) is applied to a debt that is paid down over
time, because a ceiling taken out of each frame on its own is a ceiling on a
*burst*, and a chained bolt or a crater in a crowd is several hundred points
inside one frame with nothing either side of it.

A passive weapon is a stat block that appears when its first level is taken, a
module, and a row in `WEAPONS` in `loadout.lua` pairing the two. The instance
outlives reconfiguration, so an orbit keeps its angle when it is upgraded and a
rocket already in the air keeps the numbers it was fired with. It hits through
`Game:eachNear` (the same nine cells a bullet asks about) and kills through
`Game:killEnemyAt`, which finds the victim by identity rather than index. What
aims itself asks `Game:nearestEnemy` — or `Game:nearestEnemies` where a cloud
with strikes left wants the nearest one it is not already holding — the whole
horde, not the nine cells, because a target is picked far further off than a cell
is wide and only a couple of times a second.

Twelve are built and the first two are the hands-free attacks: `shot.lua` is a
pellet at whatever is nearest on a beat and `sword.lua` is an arc through whatever
is close on a longer one, and they are the two a *character* hands over rather
than the draft (see **Characters**). Both are ordinary weapons in every other
respect, and they are first in `WEAPONS` because that list is also the order
weapons are drawn in -- the arm has to go down before the things that float over
the page do, which is where `Game:draw` used to draw it by hand.

Two more are opposite halves of one idea and are worth keeping
that way: `orbital.lua` is bolted to you and only touches what comes to it,
`rocket.lua` leaves -- a volley of rockets down some of the eight headings the
drawing is kept at, picked out of a hat rather than aimed at anybody, so what it
is worth is the ground it covers. Which makes it the cool S read from the other
end (a volley leaves *from* you, an S arrives from off the page), and it leaves
`shot.lua` as the weapon that answers the thing that matters. `sun.lua` is neither — it is
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
is *held* rather than spent, the way the storm holds a cloud with nobody to send
it after (`CoolS:launch` returns false and the clock comes back as `FULL_LOOK`) -- which
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

It is also one of the two weapons with **no board and no sprite at all** (the
spirals are the other), and the two facts are the same fact: a pointer and a beam
are both lines the levels size, so there is nothing here a drawing could be -- and because nothing here is a
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

`bomb.lua` is the sixth and the only one that makes the player *wait*: the other
five resolve the instant they act, and this one is put down at the player's feet
and does nothing for a couple of seconds, which turns the ground you just left
into somewhere the crowd walks into. Not aimed at all -- the aim is your feet a
second ago, the cool S's bargain from the other end -- so the whole line is the
**fuse**: a wider crater, dropped more often, a shorter fuse, and then a crater
that goes on burning. It is asked of `Game:eachWithin` for the sun's reason (a
crater is far wider than nine 12px cells) and it is cheap for the opposite one:
once when a bomb goes off, not twice a second for as long as one is up. A thing is
caught by its *centre* being inside the ring, exactly as under the sun's disc, so
the ring that flashes is the ring that killed.

Three things about it are load-bearing. `BLINK` is a constant in the module and
not a number on the block: whatever the fuse is, its last nine tenths of a second
are spent flashing the sprite's own silhouette blue (`drawMask`, the sun's bleach
trick), so the level that halves the fuse can never make one go off unannounced.
The whole weapon is blue -- the flash, the blast's own particles, and the burn --
because red is the other side and this is yours, which costs it the easy contrast
and is why the *silhouette* going solid is what reads rather than the hue. The
blast ring is an *outline* and lasts two or three frames -- it is the only
account the player gets of how far a bomb reached, and it may not be a filled disc
because only the sun is allowed to cover the crowd it is killing. And nothing here
hurts the player: blue is yours and red is theirs, and a bomb you had to aim away
from your own feet would have nowhere to go.

Its last level is the one thing a passive weapon leaves lying on the *page*
rather than standing over it -- a burning crater, which is the boss's blot
(`src/puddle.lua`) in the other half of the palette: sky over blue where the
boss's is blush over red, and exactly the crater's radius, so the level that
widened the blast widens the burn without saying so. Which is what
`Loadout:drawGround` exists for: a weapon with an optional `drawGround` is drawn
down with the marks and the puddles instead of over the crowd, since a filled
patch in the weapon layer would hide the things it is burning. It hurts on a clock
of its own because nothing in the crowd carries the invulnerability window the
player's own hazards are rate-limited by, and 2 a tick is deliberately the
smallest number in the game: the level sells the ground, not the damage.

`skate.lua` is the ninth of the twelve and the only one that is a **surface**. Every other
one is a thing that happens and is over — the nearest any of them comes to this
is the bomb's burning crater, which is one round patch of ground somewhere you
had already decided to be — and this turns the whole line you have walked into
that patch, for as long as you keep walking. So it is the one weapon aimed
*behind* you, which is not the beam's question again: the beam asks whether you
will turn and face a crowd, this asks whether you will let one follow you.

Four things about it are load-bearing:

- **The band is laid at the player's centre plus `FOOT` (4px), not at the
  wheels.** Everything in this game that is a surface is tested against a body's
  *centre* — the crowd under a crater, the player in a puddle, anything standing
  on wax — and everything chasing you walks its centre through where your centre
  was, so a band laid at the board would be a band a follower walked along the
  top of and never touched. Four pixels down is the whole of the compromise: far
  enough that the trail reads as coming out from under the board rather than from
  behind the hero's head, near enough that a follower's centre is well inside the
  13px band. Testing feet instead would mean asking every sprite in the game how
  tall it is, at every query, to answer a question nothing else on the page asks.
- **The fade is the tail being eaten, and it is the one mark on the page that
  does not dither.** Stamps expire in the order they were laid, so the trail is
  always one unbroken chain and getting *shorter* is what a trail does anyway —
  and a dropped stamp out of a 13px band is filled in by its neighbours (see the
  crayon's painted-on pinholes).
- **`FRESH` is a constant in the module, the bomb's `BLINK` argument.** The
  stretch the boost level is paid over is exactly the stretch drawn with its blue
  rim on, because that rim is the only readout the boost gets: a level that moved
  one without the other would be a weapon lying about where its own boost was.
- **The slow is handed to the enemy rather than read off the page.** The weapons
  are stepped *after* the crowd has moved, so `Skate:cut` sets `chill`/`chillT`
  and `Enemy:update` spends it — the wax's `slipT` doing the same job for the
  same reason, and what lets one walk over the horde a frame do both jobs. A run
  with neither the slow taken nor a tick due does not walk at all.

It is also the only weapon anything outside `loadout.lua` asks a question of, and
three parts of the frame have to: `Player:update` reads what it is standing on,
`Player:draw` swaps his shadow for the board and stops his walk bounce, and
`Game:updateGems` asks whether a gem is lying on the trail. `Loadout:trail()` is
the one door to it. It is correspondingly the only weapon with **no `draw` at
all** — its trail is ground and goes down in `drawGround`, and the board is drawn
by the hero standing on it, because that has to be *under* him and he is sorted
into the crowd by depth. `Loadout:drawWeapons` therefore treats `draw` as
optional exactly as it treats `drawGround`.

`storm.lua` is the tenth and the only one that **arrives to do a job**. A cloud
comes in off the edge of the page, parks over somebody, fills up, drops a bolt
through the paper and drifts off the other side — which makes it the cool S read
the other way round, and the pair is worth keeping opposite: an S comes in from
outside aimed at *you* and cuts a whole line it never corrects, the storm comes in
from outside aimed at *them* and takes one small circle it stopped over. A line
and no target against a target and no line.

Four things about it are load-bearing:

- **Who it strikes is nobody in particular.** `Game:randomEnemyIn` is a door
  written for this one weapon and it is the only aim in the game that is not
  "nearest": a cloud is weather rather than a promise, and what a run buys is a
  bolt landing *somewhere* in the crowd every few seconds whatever its hands are
  doing. It is the viewport it picks from, for the sun's reason — nothing may be
  killed where it cannot be seen — and the caller passes the rectangle in, since
  the caller is the one holding `Camera.bounds()`.
- **What it marks, it keeps.** The cloud follows its enemy all the way in and
  goes on following it while it fills up, snapping onto it at the strike, so this
  is the one weapon in the game that cannot miss what it aimed at — which is what
  makes it worth carrying next to a bomb at your feet and a beam down your line,
  both of which are answers to where *you* are. The crowd standing with it is a
  different question: a circle is something you can walk out of. `speed` has two
  floors under it and neither is a taste — it must beat the quickest thing in the
  crowd (the bat, 38) or a cloud could not hold station, and it must beat the
  player (58) or one could be walked to the edge and held on the page for ever.
- **It is the only thing in the game that holds an enemy across frames**, so it
  is the only thing that has to be told when one stops being on the page. `gone`
  on the enemy (`src/enemy.lua`) is set by both routes out of the horde — killed
  and walked-far-enough-behind-you — and a cloud whose mark is taken from it looks
  for another and leaves if there is none. A bolt into bare paper is the one thing
  this weapon must never spend itself on.
- **It arrives from any direction and leaves on the same heading**, the cool S's
  entrance: a random angle, far enough out that the whole of it starts off the
  page. That distance is measured from the *station* and not from the middle of
  the viewport (`offPage`), since a station hangs a bolt above its target and one
  near the top of the page is above the page — struck off the centre, a cloud can
  pop into existence in the far corner instead of arriving.
- **The cloud hangs exactly a bolt above whoever it is over.** `boltY`/`hoverY` are
  struck off the two sprites rather than written down, which makes the bolt's the
  one board in the game where the *height* of what is drawn is a measurement:
  draw a longer bolt and the cloud floats higher, with nothing to keep in step.
- **What it leaves is on the crowd, not on the page.** Whatever a bolt caught
  wears its own outline in blue for a second (`Enemy:shock`) — the sun's bleach
  trick with an expiry on it, and the only reason it is needed is that the strike
  itself is a third of a second of flashing on a page already full of marks. Blue
  because the bolt is yours; a sunburn is what a thing carries for the rest of its
  life and this is what it is wearing now.

The cloud is the one thing in the sky filled in `paper`, so it covers the ruling
and whatever is standing under it. That is the sun's trade at a fifth of the size
and it is taken on purpose: a cloud you can see the page through is a doodle. It
is also why the storm is **last in `WEAPONS`** — that list is the draw order, and
the highest thing on the page goes down after everything it is meant to be above.

**The line is written down the visit rather than down the damage**, and nothing
in it makes a bolt hit harder: a wider circle, a second cloud (`clouds` on the
block, read by `Storm:cap`, capped at two because three is a page you cannot
read), a cloud that stays and strikes three times (`bolts`), and then the chain.
`damage` is the number the graphite line is for, and this line never touches it.

A cloud that has struck and has strikes left does **not** re-roll at random:
`Storm:linger` takes whoever is *nearest*, so a storm bought the time to stay
works its way along the crowd it is already over instead of crossing the page to
somebody it picked out of a hat. That is a different question from the one
`Storm:remark` answers — a cloud that has lost its mark before striking has no
attachment to anybody and picks again at random — and the two want to stay
different.

**The chain is the only damage in the game that spreads**, and three rules hold
it together:

- **It runs along the living.** `zap` returns whether the thing it hit is still
  standing, and only what survives passes the bolt on — so a chain stops at every
  kill as well as at every gap. That is what keeps it from being a screen-clear,
  and it quietly makes it the one level in the game that pays a run for hitting
  *softly*: a strong run kills the first rank and the zap never leaves it.
- **Nothing bounds the hops but the damage.** `falloff` on the block takes three
  fifths at each jump and `MIN_ZAP` (1, in the module) is where it stops being
  worth an arc — five jumps off an unsharpened bolt, more off a sharpened one,
  since the falloff runs off what the run actually deals. `hit` keeps anything
  from being zapped twice in one strike, which is what bounds the work: one
  `eachWithin` per thing reached, once per strike rather than per frame.
- **The arcs are drawn in `blue`, not the sky the rest of the flash is in.** Sky
  is what the ruling is drawn in, so a pale line laid across a ruled page is one
  you have to look for — and an arc is the same event as the blue outline it
  leaves at both ends of itself. It is the only place in the game where the damage
  a weapon did is drawn as a *path*, which it can be because the path is the whole
  of what the level sells. Straight lines and only on the lit beats: a jag redrawn
  every frame shimmers, and one drawn once starts reading as a mark on the page.

`flock.lua` is the eleventh and the only one that is not an *event*. Every other
one arrives on a beat you can learn -- a star comes round, a rocket goes up, a
bomb goes off, a cloud parks itself overhead -- and this is a handful of small
things milling about near the player taking a pixel off whatever they brush past.
Which makes it the star read the other way round rather than a second orbit, and
that is the one thing about it worth protecting: **nothing here has an angle**. A
star is on a ring and where it will be in a second is arithmetic; a bird picks
somewhere near the flock to be, banks towards it (`TURN`), and picks somewhere
else on arrival -- so what it draws is a path rather than a circle. Four things
keep that honest and each is a constant in the module with its reasoning on it:
the next goal is *stepped on* from the last by a third to two thirds of a turn
rather than drawn fresh (a fresh angle is a fly in a jar), one step in four goes
the other way (`REVERSE`, without which the envelope of a one-way drift closes
into a ring however scattered its points), goals are kept as offsets from the
flock's centre so they walk with the player, and a bird left too far behind
(`LEASH`) stops flying prettily and goes straight home, since banking costs
forward speed and a flock strung out fifty pixels back has stopped reaching
anything. It asks `Game:eachNear` like a bullet, since seven pixels of bird cannot
reach past the nine cells the hash looks in, and its rehit list is **per bird**
rather than shared across the flock -- which is the one place it deliberately
differs from the orbit, where three stars on one ring sweep a crowd as a single
pass.

Two of its five levels change what a bird *is*. `carriers` puts a couple of them
on errands: a carrier leaves the wheel, flies to a gem lying outside the magnet,
taps it and the gem comes home -- handed over as a *reach* (`Flock:hauls`, asked
by `Game:updateGems` through `Loadout:flock`), which is the skate's magnet level
done the same way for the same reason: what the level buys is being noticed, not a
second way of arriving. And the finale is the *room* rather than the count: at a
spread of 0.9 a bird may be sent anywhere from the hero's own feet to the edge of
a flock half again as wide, so fourteen of them are a cloud you are standing
inside. Every other weapon covers ground by reaching further; this one covers it
by filling in what it already reached.

`spiral.lua` is the twelfth and the only one that **does no damage at all**. What
it sells is where the fight is, which is the one thing none of the other eleven
can arrange -- a bomb at your feet, a beam down your line and a bolt out of a
cloud are all answers to where the crowd already is. Three things about it are
load-bearing:

- **The pull is a decision and the push is a force**, and both are handed to the
  enemy rather than read off the page, for the skate's reason: the weapons are
  stepped after the crowd has moved. A spiral *lures* (`Enemy:lure`), so what it
  catches goes on walking, jostling and hurting whoever is standing where it is
  going. The last level's spiral -- the one round the player, for the rest of the
  run -- *shoves* (`Enemy:knockback`) and could not lure: something told to walk
  away would never come back, and a run nothing could reach is a run with no
  difficulty. A shove decays, so what that level buys is a treadmill. The boss
  needs no clause of its own at either end: `knock` on its row already says what a
  shove is worth against it and `hold` already says what being held is worth, and
  a lure is a hold -- both arrive here for nothing.
- **It has no board**, and it is the second weapon with none (`beam.lua` is the
  other). A spiral is arithmetic -- so many arms, so many turns, wound either way,
  spinning -- and a design is a fixed grid of pixels used exactly as drawn. Being
  plotted rather than stamped is also what frees it from the eight headings, the
  beam's freedom by the same route.
- **All of it is drawn in the ground pass** (`drawGround` and no `draw` at all,
  the skate's shape): it is ink on the paper rather than an object standing on it,
  and the crowd being drawn into it has to be legible on top of it. It fades by
  going pale and then dotted -- the ramp plus dropout every fade in this game is
  made of, never alpha -- and the pixel count is watched in the module, since
  `pi x turns x radius x arms` is the same order of work as the laser beam, which
  is the only other thing here drawing in the hundreds of pixels a frame.

Ten of the twelve are drawn by the player rather than authored (see below), the
beam and the spirals being the exceptions -- both are lines the levels size, and
there is nothing in a line a drawing could be -- though the sun's board is only its *face* (the disc,
rim and rays are sized by the levels), the bomb's drawing is the one shown in
a colour nobody drew it in and the skate's is the one that goes *under* another
drawing rather than being all of something, and the storm's is only its *bolt*
— the cloud that carries it in is authored, since the bolt is what the weapon
does and the cloud is only what brings it. Two of the ten are usually drawn
before the run rather than during one, since the character hands them over: the
sword and the pellet SHOT sends. The rocket and the sword are the drawn things in
the game with a heading, so they are the ones kept at more than one: `pixelart.turn`
builds a ring of eight and a rocket is fired down one of them, so the heading and
the drawing are one choice with no rounding step in between. Nothing turns at draw time — see the rendering
rules, and note that this is exactly why the beam, which has no sprite, is free
of the eight.

### Spatial hashes

Two, with different rebuild policies:

- `Game:buildGrid` — 12px cells, rebuilt every frame, used for enemy separation
  and bullet hits.
- `src/walls.lua` — 16px cells of pen-line segments, rebuilt only when
  `wallsDirty` (a wall stroke grew or expired), so it sits still most of the
  time. Set by `Game:updateDrawing` for a line a hand is drawing and by
  `Compass:layBands` for one an arm is (the CORRAL) — the drawing pass runs first,
  so a stretch laid by an arm enters the index a frame later. Segments are filed under every cell within reach, so an enemy queries
  with a single lookup.

Enemies commit to a way round a wall for `SLIDE_HOLD` seconds rather than
re-deciding each frame, and `Enemy:resolveWalls` gets the last word so nothing
ends up standing inside ink.

### Draw layering

The **page** pass is short and has exactly two things in it: `Background.draw`,
and then the half of the page each live cut has taken off it
(`Scissors:drawSever`). Everything else drawn into the page rather than onto it
goes down from inside the ink pass through `Overprint.beginSolid()` — the
silhouettes the crowd and the hero blank out under themselves, which is a loop of
its own just before the depth sort. Both are explained under **The overprint
pass**.

`Game:draw`'s ink order is load-bearing and commented at each step: spent
pins/staples (page memory, culled to the camera by `Game:eachSpent`) → lingering
marks → other marks → the arena box → the boss's puddles → what a weapon has left
lying on the page (`Loadout:drawGround`, the bomb's burning crater, the
skate's trail and every spiral) → drop marks/ruler guides/compass guides/cuts (the blades still
travelling down one included) and the cross an anchor is waiting on → gems →
enemies and
player sorted by `y` (the hero draws his own board at his feet if the run has a
skate, in place of the shadow; the crowd has already blanked the page out under
itself a step earlier, see **The overprint pass**) → live drops and compasses *over* the crowd → passive
weapons (nothing a weapon draws up here stands on the page: the sword a run is
mid-swing with is over the crowd for the pin's reason and one of its own, being
the only thing on the page telling that run whether it is standing close enough --
and it is first in `WEAPONS` so that it goes down before the rest; a star is
attached to
you, a rocket is in the air over it, the sun is above the page entirely -- its
disc is solid and hides the corner it is in, which is deliberate -- a cool S is a
doodle floating over the lot, a beam is light laid across all of it, and a bomb is
an object sitting proud of the paper, drawn over the crowd for the pin's reason:
one you cannot see behind a blob is one you cannot walk away from; the skate has
nothing here at all, and the storm is last of the lot because a cloud is filled in
paper and covers what it floats over, which is the highest anything on this page
gets) → rulers → the
player again if a ruler is mid-slap →
bullets → particles → (after the overprint pass, still under the camera) damage
numbers.

The ground pass is the one place a *weapon* draws under the crowd, and it is the
split it sounds like: a bomb is an object and its crater is a surface, so the
object goes over the horde and the surface goes under it. A filled patch in the
weapon layer would hide the things standing in it, which only the sun may do. The
skate's trail is the same rule with nothing on the other side of it: the whole
weapon is a surface, so it has nothing in the weapon pass at all — the board is
drawn by the hero standing on it (`Player:draw`), in place of his shadow, because
that has to go *under* him and he is sorted into the crowd by depth.

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

`Damage.show` (`all`/`big`/`none`, a setting) is refused in `Damage:add` rather
than at the draw, so a number nobody will see is never built and never takes a
place in the list off one that would have been. `big` is cut on `tier.scale`
rather than on a number of points -- the tiers already say which hits are worth
announcing -- so moving a tier's size moves the setting with it.

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

The player sprite is drawn by the player, and so is the sword a run swings, the
pellet it sends, the star that orbits him, the bird every one of the flock that
wheels round him is a copy of, the
rocket that leaves him, the face on the sun that comes up over him, the cool S
that floats away from him, the bomb he puts down, the skate he rides and the bolt
the storm puts through the page -- the
sun's and the storm's being the only designs that are part of a thing rather than
all of it, since the disc the face sits on is
sized by the upgrade line and drawn rather than authored and the cloud the bolt
comes out of is authored outright (the bolt is what the weapon does and the cloud
is only what carries it in), and the bomb's the only
one shown in a colour it was not drawn in, since the fuse flashes its silhouette
blue, red being the other side of the fight (so draw something worth seeing filled
in, since half the marks on the page are already blue). The skate is the only one
that goes *under* another drawing: it is drawn at the hero's feet in place of his
shadow, which is why its board is as wide as the hero's own and why it is the one
design that refuses `walks` rather than simply not wanting it -- having a skate is
what stops the hero bouncing, and a preview that bobbed would advertise the one
thing the weapon takes away. The bolt is the one whose *height* is a measurement
something else is struck off: the cloud hangs exactly a bolt above whatever it is
about to hit, so a longer one is a cloud floating higher. The laser beam and the spirals are the
two weapons
with no board at all, and for one reason twice: both are lines the levels size --
a pointer and a band, a number of arms and a number of turns -- and there is
nothing in a line a drawing could be. `src/design.lua` is one of these drawings — the grid
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
looks like. It opens it at all only while `Design.ask` is set (see **Settings and
language**); off, the thing arrives wearing whatever is on its file. The card's icon is not the drawing — the icons say what is on offer
and are all the same 11x11 glyph.

## Extending

- **Enemy:** sprite in `Sprites.enemies` + row in `Enemy.types` + row in `TABLE`
  in `src/spawner.lua` (unlock time, weight). A reference copy of the art goes in
  `art/vanilla/<name>.txt` with its size in `BASE` and its place in `ORDER` in
  both `art/bake.lua` and `art/preview.py`, or no page can ever reskin it and
  nothing can draw it against a ruling before it ships. The row's `name` is the
  one field on it a run never reads: it is what the *book* calls the thing, for
  the homework page's bestiary (see **Homework**), so it is written in English
  like every other string and wants a line in `src/i18n.lua` -- and that is the
  whole of what a new monster owes the challenge list, which prices its own three
  rungs off the row's `xp` and counts its own kills off `Game.killsBy`. No library
  entry and no collection gate. What it *does* beyond walking is a block on the
  row — see **The horde** for the six that exist and the one place each is read.
  It does not want a new behaviour flag threaded through anything: if the new
  idea is "the same monster, harder", that is a champion and already exists; if
  it is "the same monster, bigger still", that is a blow-up and also already
  exists; if it is "the same monster, angrier" — quicker and hitting harder — that
  is a fury and also already exists. All three are facts about an *arrival*: two
  of them are sizes (×2 and ×3) and the third is a recolour derived from the art,
  so a new kind is elite-able, blow-up-able and enrageable the day it lands, with
  no art at any scale and no second palette. Check its width against the grin first: a sprite wider than 14
  is wider than the boss eye at ×3. Every distance on the row (a burst radius, a
  pellet's `hit`, a puddle, a `spread`) is multiplied by `reach` for a standout
  and needs nothing said; every range and every timing is the row's for all
  three. A row that splits may name `split.blown` if what it leaves stops making
  sense scaled up; if it is "what happens when
  it dies", that is `Game:killEnemy` and nothing else.
- **Tool:** append a row to `Tools.list` with an icon in `Sprites.icons`, *and* a
  `toolLine` in `Upgrades.list` naming it — the line's first level is what
  unlocks it, so a tool without one can never be drafted and never reaches the
  strip. Its four upgrade levels go in `opts.levels`, and a line may be the
  unlock and nothing else — no tool line is any more, but `toolLine` still takes
  `opts.levels` as a list and a new tool can be landed unlock-first. Moving the
  row to `Tools.shelved` takes it out of the library with the rest of the game,
  since the shelf filters on the tool still being in `Tools.list`. A block that is
  not a brush also wants adding to `Tools.BLOCKS`, or nothing scales the damage,
  knock or cost inside it (`src/loadout.lua`).
- **Fusion:** a tool row in `Tools.list` written at the *combined* numbers of the
  lines it is made of, an icon in `Sprites.icons`, and a `fusionLine` in
  `Upgrades.list` naming it plus `needs` (ids that must all be finished before it
  is dealt) and `fuses` (which of those it spends — a subset, including at least
  one line of its own kind). **`needs` minus `fuses` is the catalyst**, and picking
  it is the one judgement call in the row: name the line the row's own economy is
  about, hold it to the three rules under **What the pencil's six settle** (a line
  the row cannot play without is a tax; the blotter cannot reach a flat price; the
  well against the trickle is decided by the row's window against its refill), and
  check the ladder in `Collection.gates` — a catalyst is gated, and the fusion is
  gated on its whole `needs` (`{ made = ... }`), so the catalyst decides how early
  in a player's collection the fusion can exist at all. That gate is derived and
  wants nothing written. Nothing else: it is a tool line, so the strip, the
  library, the selector column and the slot counter all already handle it,
  and `Loadout:ready` and the `self.fused` set in `Loadout:rebuild` are the two
  clauses that make it a fusion. Three more things come off `fuses` with nothing
  written: the blush plate its icon wears wherever it is drawn (`Upgrades.fused`,
  read by `Hud.drawIcon`), its place behind `EVOLUTIONS` in the library rather than
  on the tool shelf, and its answer when a player pairs the two tools it eats
  (`Library:pairing`). A table `scaleDamage` writes into (`ignite`, `ram`, `loop`,
  `pop`, and inside a block `blades`) must be built by
  the unlock's `apply` rather than written on the row — `Tools.copy` copies the row
  and its blocks one level deep, so a shared table one level further in compounds.
  **Check the walk rather than guessing**, because the tables it deliberately steps
  over may sit on the row: `crit.mult` and the pushpin's `point` are multipliers on
  damage it has already scaled, so it leaves both alone by name — which is why the
  VOLLEY writes `crit` on the row where the CRATER has to build `ram` in an `apply`.
  **A field a fused row inherits may reach code its parent never reached**, and this
  is the one place a fusion in this game has actually crashed rather than merely
  balanced badly. The CRATER carries the rubber's `crumbs`, which is a rate *per
  stamp* of debris thrown out to the sides of a travelling tip — and `Game:poolAt`
  lays its one stamp with no direction, because a dab has none, so
  `Particles:crumb` divided by a nil the first time a run landed one. The fix was to
  make the direction optional (a crumb without one rolls its own axis, which is what
  debris out of a hole should do anyway) and to throw the ring from `poolAt` rather
  than let a per-stamp rate spend itself on the single stamp a dab has — the same
  arithmetic the TACK's `fade = 1` is written against. When a row inherits a field,
  check every function that reads it against the *new* gesture, not the old one.
  Prefer combining what the parents *do* over inventing numbers: the point of
  requiring finished lines is that there is nothing new to balance — and leave out
  a parent's number that nothing on the fused row would read, the way the LASSO
  leaves out the pencil's `flow`. Where the two parents genuinely disagree about a
  field, ask which parent's *body* decides it: a rim's width is the nib's, and the
  MOAT keeps the compass's `sweep.damage`/`knock` beside a brush that deals and
  shoves nothing, because one is what the arm does on its way past and the other is
  what the mark does. **For two brushes with no carrier between them the body is
  whichever parent's mark is a *place*** — a fence and a band are somewhere a body
  can be, a rub is an event that is nowhere once it is over — and the other parent
  is what happens at it, or, where it cannot be that, the other gesture (`tap`).
  See **The six without a pencil**. When they disagree about the *same* field, the number that
  wins is the one the fusion's finale depends on: the SPINDLE takes the pushpin's
  weaker 10 over the compass's 12 because 12 would leave it nothing to pin. And a
  second *block* on the row is a legal way to say "this is what the arm carries" —
  it costs nothing, because the first block tested is the gesture and `Tools.BLOCKS`
  already scales the rest — and there are two readings of a second block, which the
  block itself picks between on field presence: carried and driven in at the end
  (the SPINDLE) or pressed as the arm travels (the HEM, on `rake`). A second block
  need not be on the arm at all: the FOLD's `snap` is *cast*, by two of its own
  circles crossing, which makes it the first fused row whose second half is a
  relationship between two marks rather than something the gesture carries — and
  it cost the parent's module one argument for the one number the page decides
  (`Ruler.cast`) and nothing else anywhere. Seven of the eight pushpin fusions are
  that same reading with the *first* block as the gesture: `thread` on a row that also carries
  `drop` strings a mark between two things the tool has driven into the page, which
  put five functions in `src/game.lua` and one field in `src/stroke.lua` and not one
  line in `src/pin.lua` — a relationship between two drops belongs to whatever can
  see both of them, not to either. What is strung is then whatever *else* is on the
  row, so a second block there is cast between the two pins rather than carried (the
  SNAP LINE's `snap`, the TEAR LINE's `cut`) — and `pool` is the same field at one
  post instead of two, for a parent that is not a line tool (the TACK, the CRATER).
  The eighth carries no second shape at all, because its second parent has no nib to
  lend: the VOLLEY is the pushpin fused with the *stapler*, which is already the same
  block, so what is fused is the block's own fields (`rake`, `crit`, `instant`) and
  the row is one shape deep. It is the only fusion in the catalogue that is, and it
  is the shape to reach for when the two parents share a gesture: there is nothing to
  carry, cast or string, so the work goes into the *block's* fields instead. **The
  ruler's seven are the third family and the shape to reach for when the gesture is
  *aimed*:** the row keeps the block untouched (all seven share one `RULE` table, on
  `PIN`'s terms) and whatever else is on the row is ruled along the line the ruler
  landed on, after the strike, by `Game:trailRuler`. Four carry a brush, one carries a
  `cut`, one carries a `drop` one level in, and one carries nothing but a flag on the
  block. Two of
  those fields are just the second parent's own (`rake`, `crit`), which is the whole
  point — the fusion is one block laid over another — and the one new thing that row
  needed is `instant`, a flag that removes a parent's *telegraph* rather than adding
  an effect, which is the honest way to fuse in a tool whose identity is that it has
  no wind-up. **A fused row may also take a parent's level off the table by making it
  meaningless rather than by leaving it out**, which is `point` there: aim cannot
  decide a multiplier when the gesture is a drag, so the level is replaced by the
  other parent's roll and the swap is the fusion's argument.
  **If you add a block to a row that already has one, check the precedence order at
  the top of `Game:updateDrawing`**: it decides which block is the gesture, and it
  is a written list rather than an accident. A fused row may
  also price its own gesture, which is what `sweep.per` is: the HEM charges by the
  staple, and `Game:sweepReach` caps the drag against the meter so the price and the
  width can never disagree. And it may change what its block *reaches* rather than by
  how much, which is what `sweep.wipe` is: the CLEARING hits the disc instead of the
  rim and shoves out of it, which is the one place a fused row has taken a *central*
  fact off a parent -- read the comment on `Compass:cut` before writing another. Naming a line an existing fusion also `fuses` makes them
  mutually exclusive for free (`Loadout:ready`), which is how the nine compass
  fusions — and the six off the pencil — are one choice rather than nine picks — and, since the clause is per
  ingredient rather than per family, how two fusions that share nothing (DOT TO DOT
  and the CORRAL) can be on one strip at once without anything being written for it. A parent's number that would be
  read and would *lie* has to go rather than merely being left out — the CORRAL
  drops the pen's `smooth`, since a nib that trails a hand cannot trail an arm.
  And what the fused brush lays need not be an attack at all: the CORRAL's is
  terrain, which cost two lines in `src/compass.lua` (dirty the wall index as the
  arm lays, and claim the pen's hold for both legs) and nothing anywhere else.
  **The fourth family is the shape to reach for when neither parent has a gesture
  worth borrowing**, which is every pair left in the catalogue: the carrier is the
  *stroke*, so the row is a brush and nothing else and lands in the `else` branch of
  `Game:updateDrawing` that a brush has always landed in. The second parent is what
  the drawn line is made of (the DECKLE's wall, the DRAG's `pull`) or what closing
  one means (`loop`, which is three payloads and a row picks: `damage`, `ignite`,
  `lift` — which is also why `scaleDamage` now asks for `loop.damage` by name
  instead of reading it blind). It is also the family that shows a catalyst is a
  *choice*: the six off the pencil ask for the INKWELL where all twenty-four before
  them once asked for SELLOTAPE, and that is one edit to one row, because `needs`
  minus `fuses` has always been the whole definition — which is also why the
  twenty-four could later be re-cut across seven catalysts for the price of eighteen
  such edits. Pick the one that describes what the row's economy is about — the well
  pays a run for drawing, the trickle for coming back, the fixative for what is still
  there, and the tape for nothing at all, which is its qualification.
  A fused brush may still want a gesture no parent's shape can carry, and there are
  two precedents: `tap` (a press that never travelled) and `fasten` (a whole `drop`
  block driven at the stroke's own ends, which `fasten.tapped` reads the other way
  round — nothing at either end, one drop *because* the finger never went anywhere,
  the SNAG). Both are read from the *release* branch of
  `Game:updateDrawing`, which is the shape to copy — how many ends a gesture has, and
  whether it was a gesture at all, are not questions the press can answer. A row whose
  press means the other gesture also has to hold its *mark* back while the press could
  still be a tap, which is `Stroke.touches` set from `wasTap` every frame rather than
  from the tool: see the SNAG under **The stapler's four**. Read the
  fields in `src/tools.lua` for why neither can be a `drop`, and check the precedence
  list before adding a third. **Ask `Game:wasTap` rather than the mark**: a press is a
  tap by how far the *finger* went and how long it was down, never by how much line
  came out, because a still finger over a walking player lays line the whole time.
  Keep the name short
  enough for a draft card and give it a row in the `ES` table.
- **Upgrade:** append a row to `Upgrades.list` with an icon in `Sprites.icons`.
  Nothing else; the draft offers whatever still has a level left and a slot for,
  and the library (`src/library.lua`) lists it, in full, on the shelf its `kind`
  puts it on — so the text on every level is read out loud somewhere the player is
  standing still, not only on a card in the middle of a run. A new line is in the
  book from the first run unless a row of `Collection.gates` names it -- and a
  fusion is never in it from the first run, since it is gated on its parts.
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
  `draw(game)`, and a row in `WEAPONS` in `src/loadout.lua`. **Call the gap
  between one thing it does and the next `every`** (or `gap`, or `rehit` if the
  weapon is simply *there* and has no launch to space out) — `scaleCadence` walks
  those three names on every block and nothing else, so an interval called
  anything else is a weapon the metronome silently cannot reach. Write it in
  plain seconds and read it straight off the block: the multiplier was already
  spent on it before the run started, which is why no module multiplies a clock
  by anything. A `tick` is deliberately *not* one of the three — that is how fast
  something already landed goes on hurting, which is damage per second and
  belongs to the damage lines. If the weapon *leaves* something lying on the page
  that goes on working — a hold, not a burn — name it in `WEAPON_PERSISTENCE`
  beside it, which is a list rather than a walk because `life` means three
  different things across the blocks and only one of them is persistence: a
  rocket's is time of flight and a crater's is damage over time, and the laminate
  must reach neither. Hit small things at
  a point through `Game:eachNear`; anything covering more ground than the nine
  12px cells that looks in asks `Game:eachWithin` instead, on a tick rather than
  every frame. There is no line query: something reaching across the page (the
  beam) asks for a circle that holds its line and tests the band itself. Anything
  it leaves lying on the page rather than standing over it goes in an optional
  `drawGround(game)` instead, which is drawn under the crowd (see **Draw
  layering**) -- and `draw` is optional on the same terms, for a weapon that is
  *all* surface and has nothing standing over the page (the skate).
  Anything a weapon needs the rest of the frame to ask it -- what the player is
  standing on, what a gem is lying on -- goes through one named accessor on the
  loadout rather than being reached for by stat name (`Loadout:trail`,
  `Loadout:flock`). A weapon does not have to hurt anything at all: one that
  *moves* the crowd hands an enemy somewhere else to walk to (`Enemy:lure`) or
  shoves it (`Enemy:knockback`), both handed over rather than read off the page,
  since the weapons are stepped after the crowd has already moved.
- **Something a character draws:** the same row plus a `design` field on the
  character (see **Character** above). Every row has one, so a board is never a
  thing only part of the game sees.
- **Something the player draws:** a row in `Design.by` in `src/design.lua`
  naming the `Sprites` field it keeps up to date, the art it starts from, its
  save file and what the board calls it — plus, to be drawn when a run earns it
  rather than on the way in, a `design` field on the upgrade row naming it. Add
  `turns = true` only if the thing has a heading; it is drawn nose-right and
  read out of `Sprites.turned[key]`. Whatever aims it rounds its own heading to
  the same eight first, or the drawing points somewhere the thing is not going —
  which is a reason to consider drawing the thing with `pixelart` instead, as
  the beam does, and keeping every angle.
- **Balance:** `SPEED` in `src/player.lua` (the
  loadout only scales what is written there), the level tables of the SHOT and
  SWORD lines in `src/upgrades.lua`, which hold every number either hands-free
  attack has -- where a hero attacks from, what it is worth, how often it comes
  round (three numbers that sat on a character until those two attacks became
  lines), how fast a pellet flies, how many leave at once, and the arc's own
  `reach` and `sweep`, where the reach is the width of the arc as well as its
  reach since the sweep is an angle -- plus `TIME` at the top of `src/sword.lua`,
  the one piece of the swing deliberately not on the block,
  `Enemy.types`, spawn interval,
  min-alive floor (`FLOOR_RATE`) and `TABLE` in `src/spawner.lua`, ink costs in
  `Tools.list`, level tables in `src/upgrades.lua`. `XP_RISE` in
  `src/player.lua` is how fast a run levels, and it is set against what the
  spawner pays out rather than chosen on its own — move one and re-check the
  other, or the last real pick stops landing between minute 15 and 20.
- **Character:** a row in `Characters.list` in `src/characters.lua` -- a `key`, a
  `name` and a `blurb` for the studio's selector and the canteen's counter, a
  `weapon` naming the weapon line in `src/upgrades.lua` the run opens holding, a
  `price` (a list of one, `PRICE`) unless it is the row the book comes with, and a
  `design` naming something in `src/design.lua` that the hero's board then hands
  straight on to (the same design that line names, so both routes reach one board).
  The `price` is what puts it on the counter's `HEROES` section *and* what gates the
  weapon it carries (`ride` in `src/collection.lua`), both derived off the row, so a
  fifth hero costs neither the canteen nor the collection a line. How it fights is entirely the
  weapon's -- reach, damage and beat are on that block -- so a character is a
  weapon line plus a row here saying who is issued it, and a `weapon` naming a line
  that already exists (the starman's `star`, the skateman's `skate`) costs nothing
  but the row. Nothing else:
  the selector is measured off the widest name and the longest blurb in the list,
  so another character costs that screen nothing. Keep the blurb inside 24
  characters and out of punctuation the 3x5 face does not have (no comma), and add
  `was` if you are renaming an existing row rather than adding one, so its hero
  board follows it (`legacy` in `src/design.lua`).
- **Subject:** a row in `Subjects.list` — a `paper` (tile size and what colour is
  at a position inside it), a `name` for its tab, a `tool` naming a tool line in
  `src/upgrades.lua`, a hand of `drills` (`{ every = <seconds>, of = { <drill> =
  <weight> } }` — see **Drills and surges**; a row without one gets `DRILL_MIX`
  at `DRILL_EVERY`, and a hand must hold two of `line`/`ring`/`grid` or the page
  stutters before minute six), and optionally the two dials `crowd` and `clock`
  (no subject turns either). Argue the drill weights from the *ruling* rather
  than from difficulty — the ruling is the thing the player is looking at, and a
  page dealing the shapes its own lines already suggest is what makes a lesson
  feel like a lesson rather than like a difficulty setting. **Where the row goes in the list is a design decision
  now**, not an ordering: the list is the term, so a row is opened by the row
  above it and asks for a minute more than that one did (`Collection.rungs`, and
  see **The collection**). A new lesson therefore brings its own rung with it and
  pushes every rung below it down one, which is the thing to look at before
  inserting one in the middle — and past ten pages the arithmetic runs out, since
  the tenth rung is a whole lesson. Nothing else: the page is baked with the rest
  at load, the timetable adds a tab and the number keys go up to as many (nine,
  after which a lesson is scribbled for rather than pressed). Give the ruling
  something vertical a page width apart, and give the lesson a tool no other
  lesson hands out — that one *is* caught, at load, since the tool it issues is
  gated on it and a line may only be gated once. Optionally a
  **skin**: a folder of `.txt` grids under `art/<key>/` baked in with
  `lua art/bake.lua` (see **Subjects**). A page with no skin is drawn with the
  crowd everybody else fights, so this is never a thing a new lesson owes.
- **Drill:** a row in `DRILLS` in `src/spawner.lua` (`at`, `shape`, `count`/`gap`
  or `lasts`, `notice`) plus an entry in `SHAPES` keyed by that `shape`, plus one
  line in the `ES` table for the notice. Then give at least three subjects a
  weight for it, or nothing ever deals it. `at` must be **6.0 or earlier if any
  page is going to be built on it** and never later than 7.5 — see the three
  ladder constraints under **Drills and surges**. Nothing else: it spawns through
  `Spawner:dropAt`, so it gets the minute's health, unlocks and champions for
  free, and `Spawner:many` gives it its per-cycle growth and its share of
  `DRILL_ROOM`. A drill that wants to march wants `Enemy:lure` and not a new
  behaviour — lure every member at *its own* point, offset by the amount it was
  spawned by, or the shape collapses into a funnel.
- **Surge:** a row in `SURGES` with `at`, `lasts` and either `floor`/`batch`
  multipliers or nothing (which makes it an `only`-style kind bias), plus the
  `ES` line. Surges are deliberately **not** per-subject: they are the run's
  pulse, so somebody who has learnt what the bell means can take that to any page
  in the book. Anything that hands the player a rest belongs behind a swarm the
  way `quiet` does, never on a schedule of its own.
- **Course:** a row in `Course.list` in `src/course.lua` -- a `key`, a `name`, and
  the eight dials (`clock`, `hp`, `ramp`, `speed`, `elite`, `blown`, `fury`,
  `pay`), all of them multiples of high school's row -- which is a row of ones
  except for `fury`, whose zero is a gate rather than a lean -- and note that
  `elite`, `blown` and `fury` are multiples of a *rate of change* rather than of a
  chance, so they look larger than they act -- plus one more price in
  `Course.price` and one `ES` line for the name. Where it goes in the list is the
  order it is bought in, since a level of the counter's one row opens the next row
  down. Nothing else: the timetable's stepper measures itself off the widest name
  in the list, the counter's figure grows by one, the register files it, both end
  cards print it and the refund hands it back, every one of those off the list
  alone. Two things to *check* rather than write.
  **Measure `elite`, `blown` and `fury` instead of reasoning about them** -- all
  three are read per arrival and a harder course has fewer of those, so a
  multiplier that looks like more can come out flat (see **Courses**). And leave
  enemy damage alone: what a course may take away is time, never the arithmetic a
  player counts their own health in -- `fury` is not a hole in that, since what it
  turns on is one arrival in a hundred wearing red and black while it hits harder. A dial that is not a multiple of something the spawner already
  computes is the sign that the idea belongs somewhere else -- a course has no
  business naming a kind, a shape or a minute, because those are the page's
  (`src/subjects.lua`) and the page may not price a thing.
- **Paper:** the specs at the top of `src/subjects.lua`.
- **A section on one of the three back pages:** a row in `KINDS`
  (`src/library.lua`), `SECTIONS` (`src/canteen.lua`) or `Challenges.sections`,
  and one `ES` line for its name. It is a *spread* rather than a page (see **The
  book**), and the book is measured off the list -- `Book:fit(game, #list)` is
  handed the count every frame -- so the footer, the arrows, the keys and the
  finger drag all grow with it and none of them is told anything. What a new
  section owes is the rule all three screens already hold to: every column on the
  page is cut to the widest thing that can *ever* stand in it across **every**
  section, never the one showing, or turning to it moves the page under the reader.
- **A fourth screen read as a book:** one `Spread.new()` on the screen, `Book:fit`
  in its layout, `Book:track` in its update **ahead of the pen**, and its draw cut
  in two -- a `drawPage(game, section)` holding one whole overprint pass and
  nothing that does not turn, called through `Book:draw`, and everything else
  after it. Three things it owes beyond that: a `furniture(x, y)` predicate so the
  book does not take a press meant for a button, a `book:eating()` guard at the top
  of `mark` and `press`, and a layout that asks `Book:leaf(1)`/`leaf(2)` for its
  two halves and stacks them when `Book:spread()` is false. Anything live on the
  page it is leaving hangs off `Book.onTurn`.
- **Something the canteen sells:** a hero is a row in `Characters.list` with a
  `price` on it and nothing else (see **Character** below). Anything else is a row
  in `Perks.list` (`src/perks.lua`) -- a
  `key`, a `name`, a short `blurb`, an 11x11 `icon` in `Sprites.icons`, a
  `price` per level and a `spent` saying where the use goes -- plus the one thing
  the row cannot say, which is what spending it *does*. For `spent = "draft"` that
  is a branch in `LevelUp:pressPerk` if it acts on the press, and a
  `Game:...` beside `rerollDraft`/`skipDraft`/`expelLine` for what the answer
  means; for anything else it is a `Game:can...`/`Game:open...` pair at the moment
  the use is spent, the way RETAKE's sit beside `Game:openDeath`, and no button
  on the draft at all. The counter grows a row, the draft grows a button and the bookmark
  carries it, all off the row alone -- every one of those is measured off the list
  and the number keys go up to as many. The one line that is *not* off the list is
  the counter's key hint, which spells the figures out because English is the key
  (`src/i18n.lua`): a row adds a figure to its own section's `keys` in
  `src/canteen.lua` and to the Spanish beside it. A whole new *kind* of thing to sell
  is another `SECTIONS` row plus a module answering the five `shop` questions
  (`level`, `levels`, `priceOf`, `canBuy`, `buy`) about a key -- which is exactly
  what the refund is (`src/refund.lua`, and it sells nothing at all) and what the
  course ladder is (`src/course.lua`, one row with three levels), so there are two
  worked examples to copy -- and between them they cover both shapes, a section
  that sells nothing and a section whose whole list is one line. A section whose rows cannot be shut for the counter's two
  reasons writes its own line in `shut`, and one the word BUY is wrong about writes
  its own `touch`. The icon is a tool's 11x11 rather than one
  of the corner's small glyphs, since it is drawn in the tool selector's box and
  beside a name on the counter. And a level has to mean *one more use* --
  anything else belongs in `Upgrades.list`, where a level is a function of what it
  changes.
- **Something the book has to be earned to reach:** add a row to
  `Collection.gates` (`src/collection.lua`) -- a `need` naming one of the four
  columns (`time`, `kills`, `sat`, `beat`) and the single `line` it opens -- and
  bump nothing else. The draft's pool and the library's shelf ask the same one
  question (`Collection.has`), the count in the library's corner is measured off the
  shelves, and the words a locked entry prints come off the `need` through
  `Collection.why`, with how far along you are under them through
  `Collection.meterOf` -- so a new quest reads out on the shelf by existing.

  **Where you put the row in the table is where the line lands on the shelf.** The
  library sorts every shelf on `Collection.rank`, which is just the row's index, so
  a quest written between two others slots its line between theirs in the library
  too. Insert it at the difficulty it is priced at rather than appending it, and
  keep new written rows above the three derived blocks at the foot of the table.

  Five rules. **One feat, one line** -- `line` is singular and a second gate on the
  same id asserts at load, as does an id the catalogue does not have. **Price it
  above the term's ceiling** if it is a `time` row: seven minutes or less is a
  reward that arrives while the player is opening pages, and one that cannot be
  missed is not a reward. **Keep the boss count low** -- three of seventeen ask
  `beat`, because six of the seven bosses do not exist yet and `sat` asks the same
  question without them. Never put a **character's weapon** behind a quest -- a
  bought hero's line already has a gate of its own, derived from `Characters.list`,
  and the base hero's may not have one at all, since it is what a fresh book's first
  draft has to deal. And a **lesson's tool** does not want a row either -- it
  already has one, derived from `Subjects.list`, gating it on that lesson being sat
  (`lesson`); nor does a **fusion**, which has one derived off its own `needs`.

  If a new kind of `need` is added, it wants a branch in `Collection.met`, a pair of
  phrases in `Collection.why`, a case in `Collection.progress` if it has a meter the
  shelf can draw under the demand, and keys in `src/i18n.lua` -- a *key* and its
  slots, never a sentence built here and looked up later. Adding a column to
  `Records.best` is the same shape: a maximum, or a count of pages whose maximum
  clears a bar, so that it can only ever go up.
- **Something the book asks you to go and do:** a row in one of the four sections
  of `Challenges.sections()` (`src/challenges.lua`) -- a `name` and an `ask`
  written as *phrases* (a key and its slots, never a finished string), a `want`
  ladder of one or more rungs, a `have` reading some register, and `how = "span"`
  if the figures are stretches of time rather than counts. The homework page
  measures every column across all four sections and draws whatever is there, so
  nothing else has to be told. Three rules. **Unlock nothing** -- every reward in
  this game is a door with a screen behind it, and a second ladder pointing at the
  same doors would cost the library its promise that a shelf is the whole of what
  there is to open. **Derive it if you can**: the bestiary is read off
  `Enemy.types`, the courses off `Course.list`, the collections off
  `Upgrades.list` and `Design.boards`, so every one of those grows on its own and
  there is no list to fall out of step with the game. And **read a maximum or a
  tally, never invent a third register**: if the number does not exist, it belongs
  in `src/tally.lua` as a counter the run already holds, banked through
  `Game:bankTally`'s watermark rather than through a hook on whatever produces it.
- **Anything the player reads:** write it in English where it belongs -- the
  upgrade's row, the tool's name, the screen's own constant -- and add one line to
  the `ES` table in `src/i18n.lua` keyed by that English. Then make sure the place
  that *draws* it puts it through `I18n.t`, and that anything measuring it for
  layout measures the translation and not the key. Avoid a comma in the Spanish
  and avoid an acute accent anywhere; N-tilde and the inverted marks are fine.
- **A language:** a row in `I18n.langs` (a `key`, a two-letter `code` for the
  title screen's switch, and the language's own `name` for itself, which is never
  translated) and a table beside `ES` in `DICT`. The switch and the settings
  stepper both step the list, so a third costs neither of them anything -- but
  check the new words against the 3x5 face first: a letter it has no glyph for
  draws as a blank the width of a letter.

## Style

Comments here explain *why* a thing is the way it is — the trade-off, the bug it
prevents, the feel it produces — rather than restating the code, and modules open
with a paragraph framing what they are. Match that when editing; a change that
invalidates one of those paragraphs should update it. Numbers that encode a design
decision (the pushpin's 10 damage sitting one short of the skull's 12hp, for
instance) are documented in `README.md` and should not be nudged casually.
