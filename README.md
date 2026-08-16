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
| Every tool and weapon maxed, for testing | `T` on the pause screen | scribble in `DEV` on the pause screen |
| Take an upgrade | tap a card or scribble the box under it, or `1` / `2` / `3` | tap a card or scribble its box |
| Restart | `R` | tap anywhere |

`F11` or `alt+enter` toggles fullscreen, `Esc` quits.

The stick is drawn in the bottom-left corner, but it is not pinned there: press
anywhere in that corner and the ring jumps under your thumb, so you never have
to look for it. Push past the rim and the ring follows rather than running out
of travel. It is analogue — a small lean walks slowly — while the keyboard is
always full tilt. The trade-off is that a finger landing in the corner always
steers, so draw with the other hand.

## Asking by drawing

Four screens ask you a question — the title screen (`START?`), the drawing board
(`OK!` / `RESET`), the pause screen (`QUIT?`) and the draft you get for levelling
up — and they all ask it by making you draw the answer, so the asking lives in
one place, `src/scribble.lua`. Every one of them is a page you can draw the rest
of anyway.

Every one of them is a box you scribble in. It is not a button that happens to
look drawn: the box measures *ground covered*, on a 2px grid inside its border,
and six cells arm it — a line through the box, about a third of the way across.
What that rules out is a tap or a graze rather than a deliberate mark: a single
dab lands in one cell, and scrubbing back and forth over one spot re-marks
cells that are already marked.

The draft asks the same way, just three times: each of its cards has a box
under it, unlabelled because the card above it is the label. Scribble in the
box under the card you want — or tap the card itself, which draws the scribble
into its box for you, the same way the keyboard shortcuts do everywhere. Either
way the box is still answered the only way a box here is answered: by ink
covering it.

Every box makes the same bargain about *when* an answer counts. Drawing in one
only **arms** it; nothing is committed until the pen comes off the page. A line
that carries on into the next box changes the answer rather than being too
late — and the border warms from slate through blue to red as it fills, so you
can see the answer coming before you lift.

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

Whatever the run does to a drawing when it draws it, the life-size copy does
too, and it reads that off the design rather than knowing it: a thing that
stands on the page gets the ground under it and the walk bounce, a cool S gets
the blue rim it floats around wearing, a star gets neither and is shown exactly
as it will look going round you. A board that showed you something other than
what you were about to be handed would be the one thing this screen cannot
afford.

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
there is only one spot to reach for. The two arrangements — the column beside
the board, or the same pieces above and below it with the board spliced in — are
picked between by *which leaves the bigger cell to draw on*, beside on a tie.
That is a rule rather than a width test because the board is not always 15x19:
seven pixels of star would fit beside the column on a phone held upright, at
cells half the size the other arrangement gives them. The column is measured
from the longest string that can ever appear in it, so nothing shifts sideways
when the prompt changes.

A cell is capped at 12 pixels and floored at 4 — limits on the *cell*, not on
the board, which is what makes a small design look small. A cell is one pixel of
drawing and a finger is the same size on every board, so the star gets the same
size cell the hero does and a board a third the area, rather than the same board
with cells too big to read as pixels.

It is finished with the same boxes every other screen here asks with: `OK!`
hands the drawing over, `RESET` puts back what you were given to draw over. RESET
is answered in place rather than closing the screen, so the ink comes back out of
the box and it can be answered again. A stroke is latched on the press — one that
starts on the board draws on it for its whole length and can never answer a box,
and one that starts off the board can never reach it, so a scribble aimed at
`OK!` that overshoots cannot cost your hero a leg. Ink that lands outside both is
not part of the drawing, just ink on the page, and fades off it.

An empty board is refused: nothing drawn is nothing to play as, and it would be
saved and handed back on the next launch as well.

Every drawing is written to the save directory as one line per row — so opening
`hero.txt` in a text editor shows the character — and read back on the next
launch. A file that has been edited into something the game can't draw is ignored
rather than trusted, and you get the stick man back. There is only ever one hero:
the run draws it, the title screen's doodle draws it, and the board's life-size
copy draws it.

Dying restarts straight into the next run with the same character; the board
comes back round through the title screen.

### Drawing your weapons

The hero is not the only thing you draw. Almost every passive weapon sends you
back to the board the first time you take it: the same board with a star on it, a
rocket, a face, or a cool S, and the pixels you leave there are what goes round
you, launches off you, comes up in the corner or floats away across the page for
the rest of the run — and for every run after it, since they are kept in
`star.txt`, `rocket.txt`, `sun.txt` and `cools.txt` the way the hero is kept in
`hero.txt`. RESET puts the default back, exactly as it does for the stick man.

The laser beam is the one exception and the reason is worth stating: it is lines
rather than pixels. A pointer and a beam are both a length and a width the
upgrade line decides, drawn by `pixelart` at whatever angle you happen to be
walking, and there is nothing in that a board could hand you.

The rocket is the loosest of the five about what it wants: what has to survive
is the taper, so that the pointy end is still the end that goes first. A dart,
an arrow or a sharpened pencil is the same eleven by seven pixels and the same
board. Draw it nose-right, because that is heading one of eight.

The sun's is the odd one, and the only board that is not the whole of what it
draws. The disc, its rim and its rays are sized by the upgrade line and drawn
rather than authored — they are whatever the level says this second — so what
you are given is the *face* that goes on the middle of it: fifteen by nine,
sunglasses and a smile to start with, with a blank row at the top for whoever
wants to add hair. Everything left blank comes out as sun, which is the one
place in the game where the paper behind a drawing is not paper.

The cool S is the opposite case: the one board where the drawing already exists
and everybody is certain they know it. Nine by seventeen, a shade smaller than
the stick man, and what the board is really offering is the argument about how
the thing goes — where the middle line starts, which way the long diagonal
leans, how sharp the points are. The default is the version with the two outer
lines and the middle one four columns apart and the long diagonal crossing at
twice the angle of the other two, which is the version that makes it the cool S
rather than a lightning bolt.

#### Eight headings, four of them exact

The rocket is the only *drawing* in the game that points where it is going, so it
is the only one kept at more than one heading. What you leave on the board is
turned into a ring of eight (`pixelart.turn`) and a rocket picks the nearest of
them when it launches — once, since it flies a straight line.

Eight is a limit on sprites and on nothing else. The laser beam points where it
is going too and is aimed at any angle at all, because every part of it is
plotted by `pixelart` rather than drawn from a grid of pixels somebody authored —
which is the trade in both directions: the rocket can be redrawn and cannot be
aimed freely, and the beam can be aimed freely and cannot be redrawn.

The turning happens up front, into a new grid of characters, and never at draw
time. Nothing in this game passes a rotation to `love.graphics.draw`: a sprite
turned as it is drawn samples off the pixel grid, and the grid is the whole
point. What reaches the page is an ordinary sprite at an ordinary integer
position, exactly like every other sprite.

Half the ring is free and half is not, and it is worth knowing which:

- **The four quarter turns are exact.** A quarter turn is a permutation — every
  pixel lands on exactly one pixel — so right, down, left and up really are your
  drawing, whatever you drew.
- **The four diagonals cannot be.** There is no lossless 45° map on a square
  grid, so each destination pixel takes whichever source pixel it lands nearest.
  A solid shape comes through as the same shape with a staircased edge. Art made
  of single-pixel lines does not come through at all: draw a thin outlined arrow
  and it reads perfectly at four headings and as a blob at the other four.

That is the price of turning a drawing nobody authored, and it is why the
default rocket is a solid seven-pixel body rather than the five-pixel one it
started as — a chunky shape survives the diagonals, a needle does not. The
alternative was four headings instead of eight, which would have been exact
everywhere at 45° of error instead of 22.5°.

Only the *first* level of a line opens the board. The levels after it change what
the weapon does rather than what it looks like, and being sent back to redraw a
star you are happy with each time would be a toll rather than a moment. The card's
icon is not the drawing either: an icon says what is on offer, in the same 11x11
box every other line uses, and what it is offering is the chance to draw one.

A design is fixed at the size of the art it starts from, which is the whole
bargain — you can change what a star looks like, and you cannot draw a bigger
one. Everything measured off a sprite (`Player.radius`, the orbit's 4px reach)
stays true whatever anybody draws. The rest is shared: `src/design.lua` is one
drawing and `src/studio.lua` is the board any of them is drawn on, sized from the
design rather than from anything written down, so a second thing to draw is a row
in `Design.by` and a `design` field on an upgrade line.

While the board is up mid-run, the run is held exactly as the draft left it —
frozen, and not drawn at all. A board is a whole page, not a card laid on one.

## Pausing

The button sits in the top-left corner with the health bar starting to the right
of it, and turns red with a play arrow while the run is held. Pressing it again
lets the run go, and so does `P`. The HUD gets first refusal on every press,
ahead of the stick, whose grab zone is a generous quadrant rather than the ring
it draws.

That corner is where it ended up by elimination. The whole right margin belongs
to the tool column and is claimed at full width whether the run is holding one
tool or four; the bottom-left corner belongs to the thumb stick. The gap to the
health bar is six
pixels rather than four because the button's touch target reaches five past its
own box, and a health bar with that lying across its left end is a bar that
pauses the run when you press it.

Pausing holds the run where it stands: the clock, the horde, the ink and any
mark still fading are all exactly as you left them. An open stroke is closed off
at the freeze, so the nib can't rule a line across the page on the way back to
wherever the pointer wandered to while nothing was moving.

Up comes `QUIT?` with the same YES and NO boxes the title screen uses and the
same arm-then-lift mechanic. Scribbling YES hands the page back to the title
screen; NO lets the run go again.

It is asked on a card, where the title screen's own asking is written straight
on the page. The difference is what is underneath: a title screen is a page with
a doodle walking round it, and a paused run is whatever was happening at the
moment you stopped it — a horde, a wall of ink, half an eraser sweep — and
lettering laid over that is lettering you cannot read. The card is paper, which
is the one colour that covers what is under it rather than stacking with it, so
it really is a card lying on the page rather than a panel in front of it, and
its border is drawn on the same wonky line and over the same quarter second as
the boxes inside it. It is sized to the widest thing it can ever hold rather
than to what is on it now, so it doesn't twitch when the prompt changes as a box
arms.

Everything outside the card is still page. The whole of it stays drawable: ink
that misses the boxes is not an answer, just ink, and fades off exactly as it
does on the title screen. It costs nothing, since none of it touches the run
underneath — the pen only runs while the game is playing, so a paused page can
be scribbled over without spending ink or leaving a mark on the run.

Any press or key skips the intro straight to the boxes.

The card also carries the game's one development switch: `T` takes every tool
line **and every passive weapon line** to its top level at once — lines the run
never started and lines it was part-way through alike — and pressing it again
restores each to exactly the level the run had really reached, so nothing it
earned is touched. It exists for playtesting one of them as it plays fully
upgraded without drafting a run all the way to it, so it is keyboard-only and
deliberately walks straight past both four-slot caps; the slot counters on the
held screens go red rather than pretend otherwise.

Those two kinds and not the passives, because those two are what a run
*carries* — the strip down one margin and the weapons down the other, both
drafted rather than issued, and both things you have to look at to judge. A
passive is a number about the player, and a playtest that wants one wants a
particular one rather than all thirteen at once.

Handing it back is exact in one more way that only matters for weapons: a weapon
the run had genuinely started keeps the very same instance across the whole
round trip, so an orbit that has been turning for two minutes is still at the
angle it was. One the run had only *borrowed* gives its instance up along with
its levels — otherwise a sun the toggle lent you would still be part-way round
its cycle if the draft later offered that line for real, and the first level of a
weapon is meant to show you what you just bought.

## Levelling up

Every level holds the run and lays three cards on the page, each with a
selection box under it. You scribble in the box under the card you want — or
just tap the card, which draws the scribble for you — and that is the only way
past them: there is no pause button while they are up, because a level has to
be spent before the run will take another instruction. The cards are the one
thing in the game drawn on paper rather than in ink: they are laid *on* the
page and cover the frozen run underneath, so they can be read over whatever
chaos was happening when the level landed. Everything else about them is
drawn — a wonky border that warms as the box under it fills, and the scribble
sitting in the box the way ink sits on paper. Ink that misses every box is not
an answer, just ink, and goes under the cards and fades.

One card is not paper. A tool line's first level hands you the tool itself and
spends one of the four places on the strip, and it is the only pick in the
draft that costs a run something it does not get back — everything else is a run
being added to, and that is a run being decided. So the card it is offered on is
**sky** rather than paper, which is read across the whole page before a word on
any of the three has been: you know which one you are choosing *about* before
you know what it is. The card still says `NEW` in red, as the first level of any
line does; the colour is what separates the first level of a *tool* from the
first level of a passive you can always take another of. Sky and not blush,
which is the palette's other light fill: the border warms slate → blue → red as
the box fills, and a blush card would swallow the red — the step that says
the answer has landed. Sky only costs the blue halfway step, which is the one
you never stop on.

A pick that *finishes* a line says so too, but in words rather than in the
colour of the card: `MAX` in red, beside the `LV 5` it is completing. Colour is
spoken for by the pick above — the one that costs a run something it does not
get back — and a last level costs nothing, so it stays on paper like every other
card that is only adding to a run. There is nowhere for a third card colour to
come from in any case: sky is taken, and blush is the fill that would swallow
the border's red.

It is said beside the level rather than instead of it, because which level this
is and whether it is the last one are two different things the card is being
asked. On the pen and the stapler they are the same thing — one level, so the
card reads `NEW MAX` — and that is the card the marker is really for: it says
the tool has nothing after it *before* you spend one of three permanent slots
reaching it. With lines four and five long the marker comes up often, which is
the other half of why it is worth having.

A big enough pickup can carry two levels. The second draft comes up after the
first is answered rather than being swallowed by it, which is why levels are
*banked* on the player and spent by the game rather than applied where they are
earned. A pick that sends you to the board — the first level of the stars or of
the rocket — goes in between: the run stays held through the board and the next
draft, if there is one, comes up after it.

### The ladder

A level costs `0.9 × level² + level + 5` experience, and the shape of that —
quadratic, not exponential — is the whole reason a run gets anywhere.

It used to be a ratio: every level 1.35× the cost of the one before. That sounds
gentle and is not. A ratio compounds, so by level 30 one level wanted 40,000
experience — six minutes of a horde at full tilt for a single card — and a run
simply stopped levelling somewhere around 28 however long you survived. Which
put the real ceiling on a run nowhere near the draft's: the slot caps below
leave room for **59 picks**, so over half of what a run was *allowed* to learn
was never once put on a card. The ladder was the wall, not the catalogue.

A curve keeps the shape and loses the wall. A level still costs more than the one
before it, and always by more than it did last time, so the late ones are still
earned — what it no longer does is outrun the page. The two curves sit within a
few percent of each other up to about level 10, which is the stretch anyone has
ever actually felt; they part company after it and never meet again.

| Level | This level costs | Total to reach it |
| --- | --- | --- |
| 2 | 6 | 6 |
| 10 | 86 | 342 |
| 20 | 348 | 2,499 |
| 30 | 790 | 8,266 |
| 40 | 1,412 | 19,443 |
| 50 | 2,214 | 37,830 |
| **60** | **3,196** | **65,227** |
| 80 | 5,700 | 154,251 |

The 0.9 is set against what the horde actually pays out rather than picked for
its shape. The spawner's floor and batch size have a run earning somewhere
between 85 and 140 experience a second once every enemy is unlocked, which puts
the 59th and last real pick — every slot full, every line finished — between
**minute 15 and minute 20**, depending on how fast the build clears. A run that
kills slowly gets there later or not at all, which is the right way round: the
last few picks should be something a build earns.

Level 60 is therefore the number to know. It is not a cap — nothing stops there
— it is the level at which a run has learned everything its four weapons, four
tools and five passives can teach it, and the point where the draft starts
offering the endless lines instead.

### What you are carrying

Both screens that hold the run — the pause screen and the draft — show what the
run has picked up, and neither shows it during play. Mid-run the page is the
thing you are reading, and every pixel of margin spent on a summary is a pixel
of page you cannot see; the moment the run stops is exactly the moment you want
to know.

The **passive weapons** go down the left margin, in the same boxes, at the same
size and struck off the same midline as the tools down the right, with the level
beside each. The two columns are the two halves of what a run is made of — what
you draw with, and what draws for you — so they are drawn the same way and read
the same way.

The left margin is claimed at all times, empty or not, exactly as the tool
column's is. Handing the width back while the column has nothing in it would be
free, and is deliberately not done: the draft's cards would then be wider on
every draft before your first weapon than on every draft after it, and the
layout would rearrange itself underneath the thing you were about to pick on
the one draft you were guaranteed to be looking at it. A margin that is only
sometimes there is worse than a margin.

Everything else — the passives, and whatever a tool has been taught — goes in
one line under the question, well clear of it, each in a box of its own with its
level over the top. Those are not things a run *carries* so much as things it
*is*, which is why they get a line at the bottom rather than a column of their
own. A tool line sits there too rather than against its tool on the right: the
right column is what you can pick up, and an upgrade is not something you pick
up.

All three sets of icons are drawn in the same box, and for the same reason the
pause question is asked on a card — a page this busy cannot be read against. A
bare icon over a horde is a shape with a horde behind it; the box's paper fill
is what makes it a thing on the page instead. Only the levels are placed
differently. A weapon's sits beside its box, so the column stays exactly as tall
as the tool column it mirrors and the two keep lining up; a passive's sits on
top of its own, where a line of them has all the height it wants and no
alignment to keep.

The draft's cards are laid out between the two margins, so a card is never half
under a column of icons.

### The shape of an upgrade

Every upgrade is a **line**: a row in `src/upgrades.lua` with a list of levels,
taken one at a time and always in order. There are three kinds, and the card
says which by what it is:

- **A passive weapon.** Something that fights while your hands are busy
  drawing. Five are built, and each answers the same question differently. Two
  are deliberately opposite halves of one idea: the stars (`src/orbital.lua`)
  are bolted to you and only ever touch what comes to them, and the rocket
  (`src/rocket.lua`) leaves and picks something off. The sun (`src/sun.lua`) is
  not about where the fight is at all — it comes up in a corner of the *screen*,
  burns whatever is under it and sinks again, so it is played around rather than
  aimed. The cool S (`src/cools.lua`) is the one with no relationship to the
  horde whatsoever: it floats off you in a direction nobody picked and cuts
  everything on the line it happens to take. The laser beam (`src/beam.lua`) is
  the odd one out of all four: it is the only weapon you *aim*, firing down the
  line you are walking after a pointer and a flash have said where. The first
  level of any of them sends you to the board to draw the thing — except the
  beam, which is lines rather than pixels and has nothing to draw.
- **A tool upgrade.** Numbers inside a row of `Tools.list` — the ruler's is
  built. Worth nothing if you never pick that tool up, which is the trade.
- **A passive.** A number about you: move speed, health, how fast you mend,
  attack speed, how far xp comes to you and what it is worth when it gets there,
  how hard a whole half of the game hits, how far what you draw throws things,
  and the four that answer to the ink meter — how much it holds, how fast it
  comes back, what a tool charges against it, and how long what you drew with it
  goes on working.

What a level does is written as a function of the thing it changes rather than
as a patch applied once, because the run's loadout (`src/loadout.lua`) **replays
every level it has ever taken, from scratch, on every change**. Taking the fifth
level of the ruler re-runs levels one to five over a fresh copy of the tool. That
costs nothing at the rate a run levels up and buys three things: no level has to
know what the ones before it did, a multiplier applied a hundred times cannot
drift, and a number measured off something outside the run comes out right again
when that changes — which is how the ruler that reaches corner to corner is
re-measured when the window is dragged or a phone is rotated.

The run's tools are **copies**. `Tools.list` is shared by every run the program
plays and upgrades move the numbers in it, so `Game:updateDrawing` asks
`Loadout:tool` for the row rather than `Tools.get`, and everything downstream —
the stroke, the drop, the ruler that comes down — is handed the copy and never
has to know upgrades exist. It is also what makes a line that applies to *every*
tool at once one line of code: the multiplier lands on every copy at the end, on
top of whatever that tool's own upgrades did to it. There are four of them, and
`Loadout:rebuild` walks the copies once applying all four — `scaleDamage` for the
scissors, `scaleKnock` for the elastic band, `scaleCost` for the blotter,
`scalePersistence` for the fixative. Landing last is what makes them compose
properly with a tool's own line: the blotter discounts the ruler you have,
including the ruler level that already put its price down to 0.22.

All four multiply rather than add, and in two of them that is doing real work
rather than just being tidy. A knock of 0 stays 0, so the three tools written
without a shove keep not having one. And a `life` of 0 stays 0, which is what
keeps the rubber — the one brush that leaves nothing behind — leaving nothing
behind however much fixative a run has taken.

### What is in the draft

Twenty-seven lines, a hundred and fourteen levels between them, three offered at
a time. A
line whose tool has been shelved is never offered — taking a row out of
`Tools.list` takes its upgrades out of the draft with it, the same way it takes
it off the selector.

**A run cannot carry all of them.** There are four slots for passive weapons,
five for passives and **four for tools** (`Loadout.SLOTS`), and a line takes its
slot the moment its first level is taken and never gives it back. Once a kind's
slots are full, the lines of that kind the run has *never touched* stop being
offered; the ones it has started carry on coming up until they are finished. So a
run stops collecting and starts committing, and two runs that were offered the
same cards can end up built differently.

The one clause that matters there is that a started line is always offered,
however full the slots are. Without it, filling the last slot could strand a line
on level one with no way ever to finish it — and the cap would be punishing a run
for the order it happened to be offered things in rather than for anything it
chose.

All three counts are on screen while the run is held: **`2/4` under the tool
column, `1/4` under the weapon column and `3/5` under the row of passives**, in
slate until the kind is full and in red once it is. That last state is the one
worth having — full is the moment the rule starts applying, and without it a
card that stops coming up reads as luck rather than as a rule. The counters are
drawn even at `0/4`, because the first draft of a run is exactly when being told
there are four places to put a weapon is worth something, and a readout that only
appeared once you owned one would be explaining the rule to the people who had
already worked it out.

They follow the same rule the levels do: held screens only. Mid-run the page is
the thing you are reading, and a number in the margin is a number in the way.
Nothing moves when they appear — a counter hangs *below* its column rather than
being centred with it, so pausing does not slide the selector you were pressing
up the page to make room.

The tool cap is the tightest of the three, and it is a different kind of rule
from the other two, because **a tool line's first level hands you the tool
itself**. The strip is drafted, not issued. A run does not begin holding nine
tools — it begins holding a pencil, marked `start` in the catalogue and taken as
the run is built, and the other three slots are empty until the draft fills them.
So what those four slots are really offering is three.

That is the whole reason for unlocking them. Nine tools you can all reach are
nine tools none of which you had to choose between: the strip was a menu, and a
menu is not a decision. Four are a hand.

All three caps bite now. The weapon cap is the newest of the three to do it —
five lines for four slots, so every run gives one weapon up and the choice is
which — and it is the reason the number is four rather than five: a cap level
with the catalogue is a rule nobody ever meets. The passive cap bites hardest by
count (thirteen lines competing for five slots) and the tool cap hardest by
consequence (nine for four, one of them spent before the first frame).

What that costs is worth being plain about. A run can reach 20 levels of passive
weapon, 20 of passives and somewhere between 12 and 20 of tools — the pencil's
full line is always in reach, and the rest depends on whether the three tools it
drafts have their upgrades written — so **52 to 60 of the 114 in the catalogue**,
a little under half of it at worst and a little over at best. The first two of
those are exact rather than a range because every weapon and every passive line
is the same length; only the tools differ, and that is the pen's and the
stapler's doing. The catalogue dries up at that point, which on a long run
happens while the horde is very much still arriving. That is the intended end
state rather than a corner case, and it is the price of a draft that makes you
choose.

What happens *after* it is the endless lines, and they are covered in their own
section below. The short of it is that the draft goes on coming up: a level
reached past the last real pick is still a level, and is still asked about.

| Line | Kind | Levels |
| --- | --- | --- |
| **STARS** | passive weapon | a star you draw yourself orbiting you, then two, twice as fast, three in a triangle, an orbit that breathes in and out |
| **ROCKET** | passive weapon | a rocket you draw yourself launching at whatever is nearest, then two at once, going through what they hit, twice as often, three at once through four things each |
| **COOL S** | passive weapon | a cool S you draw yourself coming in off the page from a direction nobody picked, crossing it through where you stand and cutting everything on the line — then bouncing off the far edge, then twice as often, then bouncing off your own pen lines too, then one that stays on the page for good and never stops bouncing |
| **SUN** | passive weapon | a sun with a face you draw yourself rising in a corner of the screen and burning what it covers, then burning deeper and staying up longer, then reaching further and pulsing as it burns, then a second sun in the opposite corner, then sunrays shooting out of it across the page |
| **LASER BEAM** | passive weapon | a pointer turning with you to say where you are walking, a hairline flashing down that line, and a beam firing along it to the edge of the page at any angle at all — then holding instead of flashing, then coming round twice as often, then cutting a wider band, then a second beam out behind you |
| **PENCIL** | tool | the tool you start the run holding, and the one slot of four you never chose — then a deeper scratch, a broader point pressed harder, lines that get cheaper the longer they run, and a closed loop cutting everything inside |
| **PEN**, **STAPLER** | tool | the tool itself, and nothing after it yet |
| **RUBBER** | tool | the rubber itself, then a longer throw, a tip that shoves at rest, half-price re-rubbing, and what it sends flying knocking down what it hits |
| **MARKER** | tool | the highlighter itself, then a wider band, a deeper burn, layers that stack where you draw over your own ink, and anything that touches the band catching fire |
| **GLUESTICK** | tool | the gluestick itself, then a wider smear, deeper cuts into whatever it holds, a tear on the way loose, and a smear that pulls everything near it in |
| **PUSHPIN** | tool | the pushpin itself, then a longer hold, a wider circle, double on the body the point falls on, and every kill under the circle driving the point deeper into the survivors |
| **RULER** | tool | the ruler itself, then wider, harder, longer and wider again, and long enough to rule the whole page |
| **COMPASS** | tool | the compass itself, then wider, biting double where the lead sets off, twice round and cutting far deeper, and a second leg coming the other way |
| **SCISSORS** | passive | +20/25/30/40% damage from everything you *draw* |
| **GRAPHITE** | passive | the same four steps, for everything that *fights for you* |
| **MAGNET** | passive | xp comes to you from 44px, then 62, 80, 104 |
| **TOP MARKS** | passive | every gem is worth more, four times over |
| **SHARPENER** | passive | the auto-shot fires faster, four times over |
| **PAPER PLANE** | passive | you move faster, four times over |
| **FRESH PAGE** | passive | +20 max health, handed over full |
| **SELLOTAPE** | passive | you heal on your own, four times over |
| **INKWELL** | passive | +30 ink in the meter, handed over full |
| **CARTRIDGE** | passive | ink comes back faster, and starts sooner |
| **BLOTTER** | passive | everything you draw costs less ink |
| **FIXATIVE** | passive | marks last longer, and hold what they caught longer |
| **ELASTIC BAND** | passive | what you draw throws things further |

Every line taken to the end would be 1.39× as fast, 190 health mending at 1.8 a
second, shooting 1.7× as often, hitting 2.73× as hard with both halves of the
game, levelling 1.83× as fast, holding 2.3 meters of ink that costs 0.58× as much
and comes back 2.28× as quickly, leaving marks that last 2.16× as long and shove
2.64× as hard, with three stars going round it at a turn every 1.2 seconds and
three rockets a second each going through four things on the way.

No run gets all of that any more, and that is the point of the slots above: four
of the five weapons, five of the thirteen passive lines, and four of the nine
tools — one of which was decided for you. The numbers above are what
each line is worth to the run that spends a slot on it.

The four ink lines are where the draft grew most, and the reason is that until
they existed the whole drawing half of the game answered to one meter that no
upgrade could touch: the scissors made what you drew hit harder, and nothing
made you able to draw more of it. They are deliberately four rather than one,
because they are four different things — how much you can hold (**inkwell**),
how fast it comes back (**cartridge**), how far it goes (**blotter**) and how
long what you drew goes on working once it is down (**fixative**). A bigger well
does not refill any faster, which is the trade that keeps the first two apart;
taken together they land almost exactly on top of each other, a well 2.3× the
size refilling from empty in 3.36 seconds against the 3.33 it always took.

**Fixative** is the one that is not about the meter at all. It moves how long a
mark stays on the page and how long it holds whatever it caught, which are the
same idea read off either end — a glue smear that lasts longer sticks things
down for longer by definition. It is worth the most to the two tools that do no
damage at all: a pen wall drawn in a panic goes from 9 seconds to 19, and the
gluestick's hold from 0.55 to 1.19. What it deliberately does *not* stretch is
the ruled line a ruler leaves or the circle a compass leaves — those landed
their hit on the swing and have already done everything they are going to do, so
lengthening them would put nothing on the page but old pencil.

**Sellotape** is the other half of the fresh page, and the half the run did not
have: a bigger bar is worth nothing once it is empty, and nothing in the game put
health back at all. It is deliberately slow — at the end of the line it is a
skull's worth of damage back every seven seconds — and it does not switch off
while you are being hit, because there is no "out of combat" in a game where the
horde never stops arriving, and a heal that waited for one would never run.

**Top marks** is the magnet's other half in the same way: the magnet changes how
far a gem comes, this changes what it is worth when it arrives. That makes it the
only line that changes the *pace* of a run rather than anything inside it —
every other upgrade improves the run you are having, and this one gets you to the
next draft sooner.

**Elastic band** points at the shove, which nothing pointed at before. Only three
tools have one, and they are what the line is for: the ruler, where the knock
*is* the tool — 8 damage clears the chaff, but it is the shove that opens a
corridor across the page — the rubber, and the compass, which drags what it
catches round the circle rather than out of it. Taken to the end it turns the
ruler's 23px shove into 61px, the rubber's 18 into 48 and the compass's 14 into
38. It multiplies rather than adds, and that is load-bearing rather than
incidental: the pen, the highlighter and the gluestick are all written with a
knock of 0 because *not* shoving is the point of them — a wall that pushed things
off it would not be a wall — and multiplying leaves all three at zero where
adding would hand a shove to the three tools designed around not having one.

That does make it a passive that behaves like a tool line: a run drawing pen
walls gets nothing from it at all. It is the same trade the scissors make against
a run that only fights with what it was given, and it stays fair only as long as
the draft is deep enough to offer somewhere else to put the level.

The numbers that matter most are the ones that say what a line *is* rather than
how big it is. The stars start at 4 damage — a blob outright, a skull in three —
so the first level of a passive weapon is worth taking without being worth
taking over everything else. Their sixth and last level is the one that changes
the weapon rather than its numbers: a ring only ever touches things at one
distance, and a ring that breathes sweeps everything between two, which is why
that level and not another buys eleven pixels of amplitude.

The rocket is the same shape of line pointed the other way. It starts at 8
damage, which clears a blob or a bat outright and leaves a skull on 4 — so the
thing you were actually worried about takes two rockets, and the damage level
that takes it to 13 is the one that closes that gap. Its own turning point is
the third: up to there a rocket is one enemy's problem, and past it a volley is
a line drawn through the crowd. Three rockets go up at three separate things
rather than stacked, because three down one line are one rocket with a bigger
number on it — a volley picks as many targets as it has rockets, nearest first,
and only doubles up when the crowd runs out. What doubles up is fanned about the
target it shares, so the last enemy on the page still takes three spread across
its front.

The sun is the third of them and does not follow either shape, because it is the
one weapon that is not aimed at anything. It comes up in a corner of the
*screen*, which is a place rather than a target: you are always in the middle of
the page and the horde always walks in at you, so what a disc in the corner is
really worth is the slice of the ways in that it blocks. 60 pixels out of the 184
to the corner is a slice about forty degrees wide, which is why the level that
takes it to 80 is the biggest single step in the line — an extra twenty pixels of
radius is a third again of the arrivals.

Its last level is the one that reaches off the disc, and it is written as the
drawing leaving rather than as a second weapon fired from behind it. The twelve
rays the sun has been drawn with since level one stretch by seven pixels over
the four tenths of a second before a volley, then come off and fly straight out
along the way they were pointing at 150px — quicker than the biro, since a thing
made of light should not be outrun — for 130px, cutting each victim once and
carrying on. So the wind-up is a warning you can read in the sun itself, which
is the only warning anything in this game gives, and what crosses the page is
the same line that was turning round the corner a moment earlier.

Its damage is the lowest of the three and deliberately so: 3 a tick, twice a
second, is two thirds of what one star does to the one thing it touches, and it
lands on everything in the corner at once. The line stops at 5 rather than going
further, and that ceiling is load-bearing rather than shy. Anything that lives
through two ticks under the disc is **bleached** and carries a grey ghost of its
own outline for the rest of its life (`Enemy:sunburn`), and at 6 a tick a skull
dies in two — so a hotter sun would quietly delete the one thing the weapon has
to show for itself.

That mark is the whole of what the sun tells you, and it is there because the
disc is *solid*. It covers what is standing under it, and you are not meant to
be able to read that corner while the sun is in it: the safest quarter of the
page is the one you cannot see into. What walks back out marked is the only
account you get of what happened in there — the same trick spent pins play, page
memory rather than a number on a bar. A blob burns away before it can be marked
and a skull comes out scorched, which is the right way round.

The cool S is the fourth, and it is the only weapon in the game with no
relationship at all to where the enemies are. It is not aimed and it does not
seek: what a run buys is a straight line drawn clean through whatever is on it,
at full damage, every single thing, however many that is. That is why it opens
at 5 damage where the rocket opens at 8 — nothing stops one of these, so the
pierce the rocket has to spend a level on is what this weapon *is* — and why one
only comes in every seven seconds, by a long way the slowest thing in the game.

It comes in **off the edge of the page** rather than out of the player, and the
whole difference is what that does to the line it draws. One that left your hand
would only ever cover the half of the page you happened to be standing at the
edge of. One that comes in from outside, aimed at where you were standing as it
arrives, crosses the *whole* page and goes through the crowd on both sides of
you. The aim is taken once, at the edge, and never corrected — so it cuts the
line you were standing on a second ago rather than following you, and stepping
out of your own S's way is a thing you can do.

**The line is a line about bounces.** The first S a run drafts has none: it comes
in, crosses the page once through where you were standing, and is gone. That is
the weakest this weapon is ever allowed to be, and it is what makes everything
after it read as one idea — every level is the edge of the page refusing a little
harder to be an ending.

The first bounce is the biggest single step in it, because one bounce is not a
longer S, it is a there *and* a back: it cuts the line you were standing on and
then cuts it again from the other side, and the second pass goes through a crowd
that spent the first one walking into where it landed. Then it comes round twice
as often. Then your own pen lines turn it too.

That ink level is a *choice* rather than a gift, and deliberately so. The pen is
the one tool that leaves something solid (`wall` in `src/tools.lua`), so it is
the one tool that can turn an S — the ink an enemy has to walk around is the ink
an S comes off — but ink costs a bounce exactly as the page does. A run holding
one bounce spends it on the wall it drew or on the edge it was already heading
for, and drawing that wall in the right place is the whole skill of the level.

Then the finale, which is the one thing in the game that **never leaves the
page**: the budget stops being a budget, and a single S stays up for the rest of
the run, coming off every edge and every pen line it meets, cutting the crowd
again on every pass. It is a trade rather than a straight upgrade and worth being
plain about which way it goes. What a run gives up is arrivals — the page is full
and never empties, so the clock stops mattering and `every` is a number that
level retires. What it gets is a permanent line loose on the page. One that is
there is worth more than two that are coming: you learn where it is, you fight
around it, and the pen stops being a wall you draw against the horde and becomes
the shape you keep an S inside.

It is the one level in the game that ends with the page holding something
forever, which is why it is also the one that drops the cap to a single S. Two
would be a room with two things loose in it; one is a thing you have learned the
path of.

**Speed is one number the whole way up.** 70 against the player's 58 — a shade
quicker than you walk, which is what makes it something you can watch cross, walk
a crowd into, and step out of the way of. There is no acceleration in the line at
all: the line an S draws is the same line at any speed and a fast one simply
draws it sooner, so there is nothing there worth a level.

It is the one thing in the game drawn with a **pale blue rim** — one pixel out
all the way round, underneath the drawing so nothing of what you drew is
covered, and on the board's life-size copy as well as on the page. Everything on this page is ink, and an S is the same colour and the
same weight of line as the hero, the crowd and every mark you have left behind:
six thin strokes crossing a page made of thin strokes. The rim is what lifts it
off all that, and from across the page you see the blue coming before you read
the S. Blue rather than any other colour because it is the page's own — the
ruling is drawn in it — so what floats past reads as a thing on the paper rather
than a thing added on top of it. Like the bleach mark the sun leaves, it is four
offset copies of the sprite's own silhouette rather than authored art, because
the S is a drawing the player made and the rim has to fit whatever they left on
the board. It does not change what the thing cuts with.

**Never more than two are on the page at once**, whatever the clock says — and
exactly one once the finale is taken. Frequency compounds with how long one
*lives*, and three of the five levels make them live longer, so without a cap a
run was putting five or six across the page at a time. That is not the weapon
getting better, it is the weapon getting hard to look at.

The cap costs nothing but the surplus, because a launch with nowhere to go is
*held* rather than spent, exactly as a rocket holds a shot with nothing in range:
the next one sets off the moment the last leaves. Once the run owns the S that
never leaves there is never room again, which is how that level quietly ends the
clock.

Being uncontrolled is what keeps it honest at the top. A permanent S bouncing
off your own ink is a great deal of damage over a run, and not one pass of it is
pointed anywhere you chose.

The laser beam is the fifth, and it breaks the rule the other four are built on:
**it is the one weapon you aim**. A star turns where it turns, a rocket picks its
own target, the sun owns whichever corner it came up in and a cool S arrives from
a direction nobody chose. All four fight while your hands are busy drawing, and
none of them asks you anything. The beam fires down the line you are *walking* —
so the half of the game you were already playing with your feet is suddenly also
how you shoot, and the run that lines it up is the run that turns and walks into
the crowd rather than away from it.

What it charges for that is the **wind-up**, and the wind-up is really the whole
weapon. It is three states you read in order:

1. **The pointer**, always. A short slate line off your shoulder, turning as you
   turn, saying which way the next beam goes — and there is **one per arm the
   run has bought**, so a run firing out of its back and both sides is told so
   before the shot rather than after it. It is up in every phase, including
   while a beam is out: by then it is the only part of the sight still following
   your feet, so it is already pointing at the next one. It goes down before the
   flash and the beam so that they cover it rather than the other way round — a
   pointer lying on top of its own beam would read as a scratch through it, and
   the frames where you want to see it are the ones where you have turned since
   the shot, on which it is somewhere else on the page anyway.
2. **The flash.** Over the last 0.45s before the shot, a one-pixel line in blush
   runs the whole way the beam is about to go, blinking faster as it comes —
   0.15s between blinks down to 0.05s, an accelerating flicker rather than a
   clock, saying *going to* and then *about to*. It is the shot drawn thin:
   what it covers is exactly what the beam will cover.
3. **The beam**, five pixels across the same line: blush through the middle
   with a one-pixel red edge either side. It leaves from the **tip of the
   pointer**, rounded off at that end, rather than from the middle of the hero —
   so the sight is the barrel, and the one thing on the page you have to keep
   track of is never lying underneath its own weapon.

The aim is live through the first two and latched at the instant the beam
leaves, so the flash is a promise the beam keeps. None of it is a warning to the
horde, which cannot read it: it is a sight. Six tenths of a second of wind-up is
long enough to read it, turn on it and still be pointing where you meant.

**It is aimed at any angle**, which nothing else in the game is. Every other
heading in here rounds to eight, because a sprite cannot be turned at draw time
and has to be kept at the eight it was baked at. The beam has no sprite: the
pointer, the flash and the beam are all plotted a pixel at a time by `pixelart`
along whatever heading your feet last handed over, so there is nothing to round
and nothing to lie. A keyboard can still only express eight of those headings; a
thumb stick can express all of them.

The band is drawn by `pixelart.band`, one span per pixel of the longer axis
rather than a pixel at a time along the perpendicular — which is a correctness
fix rather than an optimisation, though it is both. Plotting the perpendicular
pixel by pixel leaves holes in the band at angles like 27°, because the points
that lands on do not tile; and a span opened out by the slope is what keeps the
beam exactly five pixels thick at every angle instead of thinning as you turn.

The beam itself is instantaneous and stops where the page does: `Camera.bounds()`
is asked every time it fires rather than the length being a number on the block,
for the sun's reason — what happens off the edge of the screen is invisible, and
a weapon that killed out there would be doing most of its work in the one place
the player has no way of looking. A wider window is a longer beam, the same
bargain every screen-measured thing in the game makes.

Starting at the pointer's tip buys the readable picture at a real price, and the
price is a **dead zone**: the damage starts where the drawing starts, so nothing
inside the sight is cut at all. A thing already touching you is the stars' problem
and not this weapon's. Paying it the other way — drawing from the tip but cutting
from the muzzle — would be a weapon killing things in a gap it visibly is not in,
which is the same dishonesty as killing off the edge of the page.

It is also why `pixelart.band` cuts its ends square to the *line* rather than to
the axis. The cheaper cut leaves a step of overhang at each end, which nothing
could see while both ends were hidden — one inside the player, one off the page —
and which hangs off a diagonal beam as a visible nub the moment one end is out in
the open. A cut square to the line is also what lets a disc of the band's own
half-width round that end off exactly, with nothing poking out from under it.

It opens at 6 damage — a blob or a bat outright and a skull in two — which is
above the cool S's 5 because a beam is half the line an S draws: it leaves you,
where an S crosses the whole page through you. It is five pixels across rather
than three because it is the one thing on the page made of light rather than of
biro, and at three it read as another pencil line laid over a page already full
of them.

It is drawn light in the middle and darker at the edges, which is the sun's
treatment of its disc and works here for the same reason: blush alone is pale
enough to lose against the paper, and red alone is a solid bar you cannot see
anything through. The edge is the same band drawn two pixels narrower on top
rather than two lines laid beside it — a line placed separately would have to
agree with `pixelart.band`'s rounding at every angle the beam can be aimed at,
and everywhere it disagreed the beam would come apart at the seam. Every arm's
edge goes down before any arm's middle, so that where two beams meet, one beam's
edge never sits in another's light; the cool S draws its rim the same way round
and for the same reason.

**Its line never touches the damage.** 6 a tick from the first level to the
last, and what the four upgrades sell instead is the beam being *there* — for
longer, more often, over more of the page, and finally out of both ends of the
line. A run that wants it cutting deeper buys the graphite that sharpens
everything, which is the passive written for exactly that.

Its turning point is the **second** level. Up to there the beam is a *flash*, on
the page for two or three frames, which is exactly one tick — it catches whatever
the line was lying across at one instant. Past it the beam *holds* for nine
tenths of a second and cuts again every fifth of one, so it stops being a thing
you land on a crowd and becomes a thing the crowd has to walk through, and the
wind-up starts buying a place you can hold rather than a moment you have to time.
That is five times the damage of a shot for one card, which is why it comes
before the clock rather than with it.

Then the same beam **twice as often**, which is the plainest level in the line
and wants to be: it comes after the one that made a shot worth waiting for, and
it is what turns the weapon from an event into a rhythm you can walk to. The two
of them together take the page from under a beam 3% of the time to 36%.

Then a **wider band**, nine pixels rather than five, and it is the one level that
changes what a beam *catches* rather than when it is there. The weapon is aimed
with your feet and feet are not precise, so the honest thing to sell is
forgiveness: half again as wide is a crowd you had to line up a little less
exactly, and against a horde walking across the line those two pixels either side
are worth more than more damage down the middle of it would be.

Then the finale, the **beam behind you**, which answers the half of the page a
single beam turns its back on — and is what makes walking *through* a crowd
rather than away from one a way to play. Both ends of one line and not a cross,
which it was for a while: a perpendicular pair only pays when you are stood
exactly between two crowds, which is not a thing anyone can arrange, and four
beams out of a hero standing in the middle of them stops reading as something you
aimed at all.

The wind-up never shortens, which is the one thing the line refuses to sell. It
is not a cost the weapon is apologising for, it is the half of the weapon you
play: a beam you could not read coming would be a beam you could not aim.

The two oldest weapon lines used to be longer — eight and nine — and what came
out of them was repetition rather than content. Two levels that each shaved a fraction off
the same timer became one that halves it, and two that each added to the same
damage number became one that makes the jump on its own; the stars land within a
hair of where they always did (rate 5.2 against 5.278, everything else exact).
The rocket is the one place a maxed endpoint really moved, from 20 damage down to
13, and that is a correction rather than a cut: nothing in the game has more than
12 health, so a rocket past 13 was buying overkill against something already
dead. A line is better for stopping on the last number that does something.

The scissors and the graphite are deliberately the same line pointed at the two
halves of the game, so a run that has committed to drawing and a run that has
committed to being drawn *for* both have somewhere to put a level. They are four
steps rather than the five they started as, opening at +20% instead of +15%, and
those are one decision: they were the longest passive lines in the draft, the
pool is now fifteen lines deep, and a run is correspondingly less likely to
finish either — so what a single pick is worth matters more than what the whole
line is worth. The end of the line comes down from 3.14× to 2.73×, which is what
the first pick being worth a third more costs.

Health is the one stat handed over as a difference rather than left to be found:
a bigger bar you then have to go and fill is not a reward, it is homework
(`Player:applyStats`).

### When the catalogue runs out

Around minute 15 to 20 a run takes its 59th pick, and the catalogue has nothing
left it is allowed to offer. The horde is nowhere near finished — the spawner is
still turning the pressure up and will go on doing it — so the question is what
a level is worth from there.

It used to be worth nothing. `Game:openDraft` returned false, the level landed
in silence, and the run carried on unasked; the number in the corner went up and
meant less each time. The **endless lines** are what it is asked instead.

There are six, and one level of one of them is deliberately small — a few
percent, the size of number the catalogue *opens* a line with rather than the one
it ends on:

| Line | Each level |
| --- | --- |
| **PRESS HARDER** | +6% damage, on everything |
| **MORE PAGE** | +15 max health, handed over full |
| **FASTER STILL** | +3% move speed |
| **SWEEP UP** | +12 magnet range, and gems worth +4% |
| **TOP UP** | +10 ink in the well, filling 8% faster |
| **PATCH UP** | +0.25 health a second |

Six rather than one because the draft lays down three cards and three cards
should still be a choice; one endless line offering the same thing three times
over would be a level-up you press through rather than answer, and every screen
in this game is built not to be that.

Three rules keep them out of the way of the game proper, and they are the whole
design:

- **They are not in `Upgrades.list`.** A line in that table is a candidate from
  the first draft onwards, and three percent of nothing offered against a weapon
  on level three would be a wasted card. They live in `Upgrades.endless`, and
  `Loadout:roll` reaches for them only after it has run out of real ones — so
  they fill what is left over and never take a place a genuine candidate could
  have had. In practice the first one appears on the 60th pick, not before.
- **They do not touch the slots.** The four-weapon, four-tool and five-passive
  caps are exactly what they were, and still decide what a run *is*. What the
  endless lines change is only what happens after a run has finished deciding.
- **They have no last level.** `Upgrades.levelsIn` answers infinity for one, so
  nothing is ever equal to it and `MAX` never appears on one of their cards. The
  climbing `LV` is the only thing such a card has to say, and it is enough.

Mechanically an endless line is a `forever(n)` function where an ordinary line
has a written-out `levels` table — it builds the level it is asked for instead of
having it authored. Everything downstream goes through `Upgrades.levelAt`, so the
replay in `Loadout:rebuild`, the text on a draft card and the level counters all
handle both shapes without knowing which they are holding.

They are drawn with the passive lines' own icons rather than new ones, and that
is deliberate too: an endless line is not a new idea, it is an old one that
refuses to stop, so an icon saying which axis it pushes is the right thing for it
to say. By the time they come up, the line each icon was borrowed from is
finished and out of the pool, so the two are almost never on a page together.

The numbers are small enough that this is not a second game bolted on the end. A
run that lives to minute 25 takes perhaps ten or fifteen of them. What it buys is
not a new thing to do — it is more of what the run already does, which is the
honest thing to sell someone who has already learned everything the page has to
teach. The one watched number is `PATCH UP`: the sellotape line's own warning
applies harder to something with no last level, since a heal that outruns what is
hitting you ends a run's difficulty rather than easing it. A quarter of what the
tape's first level gives is the rate at which it stays sustain rather than
immunity.

## Scattered on the page

Pickups arrive two ways. Every five seconds, if fewer than eight scattered ones
are already out there, the page drops one just past a random edge of the screen
— never in view when it lands, always a short walk from being in view. And
underneath that clock, the page itself holds pickups at *fixed spots* — one in
roughly every third 260px cell, placed and typed by `util.hash01` the same way
the background places everything, so a spot is a pure function of where it is.
A fixed spot materialises as you come near (440px, just under the despawn
distance so a spot on the boundary doesn't flicker), is still there if you
leave and come back, and once taken is gone for the run. It is a place on the
page rather than a beat on a clock, and knowing where one is is worth
something. The layout is seeded per run rather than truly global, because every
run starts at (0, 0): a layout shared by all runs would hand every one of them
the same opening pickups — the same diamond a hundred pixels from the start,
every time — and an opening you can memorise is an opening, not a discovery.

A gem is thrown at your feet by a kill you already made; these are the opposite
half of that idea, something that pays a run for *moving*. A survivors run left
to its own devices settles into holding one patch of ground and grinding the
horde on it, and the pickups are the standing argument against that — there is
always something just past the edge of the screen worth turning for, and the
horde follows you to it.

The scatter deliberately does not land on the enemy spawn ring. That ring
clears the *corner* of the screen, which up or down — where the view is half as
tall as it is wide — is a hundred pixels of blind walking, and a pickup nobody
ever sees promotes nothing. These hug the visible rim instead, 24 to 94 pixels
past whichever edge the roll picks, with the side rolled in proportion to its
length so the scatter is even along the whole rim.

No two pickups stand within 30px of each other — two on one spot read as one,
and the second is a prize nobody knows they won. The scatter rerolls its spot a
few times and skips a beat rather than stack; a fixed spot with a scattered
pickup sitting on it just waits its turn. Fixed spots can never crowd each
other, because each is held away from its cell's borders by more than the gap.

None of them comes to you. The magnet ignores them and there is no pull at all,
because touched means touched: a pickup the magnet hauled in would be a gem
with a different sprite, and the walk is the point. Walk far enough away
(480px, wider than the enemies' despawn) and one is abandoned rather than
hoarded — a scattered one for good, a fixed one until the next visit. Touching
one always consumes it, even when the bar it refills has no room: a heart that
refused a full bar hung around holding one of the eight slots, quietly
throttling the scatter for as long as you stayed healthy.

Three kinds, weighted 4 : 4 : 1:

- **A heart** heals 25 — a quarter of the base bar.
- **An ink droplet** refills half the well — half of whatever the well *is*, so
  an inkwell build drinks deeper from the same droplet.
- **A diamond** is a whole level, banked exactly the way an earned one is
  (`Player:levelUp`) and spent through the ordinary draft at the end of the
  frame. It keeps the xp already saved towards the next level — the ladder
  steps up underneath it, but nothing the horde paid out is thrown away. It is
  a draft in disguise, which is why it is the rare one: at these weights one
  turns up about every 45 seconds, and spotting one stays an event rather than
  an errand.

Each is drawn in the colour of what it refills — red for health, blue for ink —
and the diamond is cut from paper, so like the eye and the ruler body it wipes
the ruling rather than stacking on it: the rarest thing on the page reads as an
object lying on it, not another ink doodle.

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
the pause button was moved out of that corner. It holds only what the run has
unlocked, so it is one box tall on the first frame and four at the most; the
margin around it does not change with it, for the same reason the weapon column
opposite claims its width while empty. Both also leave room for the level that
appears beside each box while the run is held — hung off the inside edge on the
right and the outside edge on the left, so the two read outwards from the page
rather than both reading left to right. That is why the draft measures its cards
off the safe area *minus* both columns (`Hud.rightMargin`, `Hud.leftMargin`): a
card underneath either is a card you can only see part of. The three cards go
across the page when there is width for three and down it when there is not,
which on a phone held upright is where the room is anyway — a column of cards
between two columns of icons, which is the tightest page the game has to lay
out.

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
| Rubber | 15px sweep, shoving, no mark | hard knockback and chip damage, re-hits every 0.3s |
| Highlighter | wide band | lingers ~3.6s, damaging anything standing on it |
| Gluestick | 29px smear | no damage at all: anything caught stops dead |
| Pushpin | not drawn: **dropped** | 41px circle, 10 damage, and survivors are pinned 2.5s |
| Stapler | not drawn: **dropped** | 15px, 2 damage, holds what it catches 2s — ten a meter |
| Ruler | not drawn: **aimed** | 200px line through you, 8 damage, everything shoved clear |
| Compass | not drawn: **opened** | circle up to 108px across, 7 damage, cut as the arm reaches it |

The pencil is the tool every run starts holding, and its upgrade line is the
one line every run can finish — so nothing in it changes what the pencil *is*.
It stays the cheap ragged line you kill with by drawing over things; the four
levels make drawing over things deeper (6 to 9), broader (a 3px diamond of
graphite pressed harder, with double the reach), and cheaper the longer you
keep drawing them. That third level pays a *style*: the price per pixel eases exponentially towards half while the finger
stays down and snaps back the moment it lifts, so the player who draws in one
long cursive line draws nearly twice as much of it, the player who dabs gets
nothing, and the floor is the cap that keeps a lap of the page from becoming
free pencil. The flat ink discount and the one-in-ten crit both went in the trim
to four: the blotter sells the first to every tool at once, and the scissors sell
the depth the second was really buying. The finale is the most pencil thing in
the game: **close the line
on itself and everything inside the loop is cut** — a lasso, drawn. The head
has to come back within a few pixels of the stroke's own earlier path with at
least ~40px of line between the two, so a wiggle is not a lasso; the cut is
slight on purpose (4 — a blob or a bat, a chip off a skull) because the ring
costs nothing beyond the line you were already paying for and can be drawn
round a whole crowd; and a close spends the path behind it, so one circle is
one cut and a spiral has to keep travelling to keep cutting. It changes what
the tool *is* the way a finale should: the pencil stops being only an edge you
drag through things and becomes the one tool that can claim an area by drawing
its border.

The rubber's line reads the tool the same way the tool was designed: the shove
is the weapon and the damage was always chip, so the line opens on the shove —
the 18px throw becomes 27 (knock 165 to 240; a push decays at exp(−9t), so
distance is force over nine). The second level removes the wrist from the
equation: until then the rubber only works
while the tip is travelling, and now **the resting tip keeps shoving** on the
same 0.3s cadence, so pinning something against a corner is leaning on it
rather than scrubbing at it. It is not a way around the meter: each resting
hit is priced as nine pixels of rub — about five seconds of leaning on a full
meter — so leaning is the cheap sustained option against the scrub's expensive
burst, and a dry nib just waits. The third prices the motion the tool is actually
used with: ground the stroke has already covered costs **half**, which is the
second and every later pass of a back-and-forth rub — dragging the rubber
somewhere new pays full price the whole way, so the discount rewards rubbing
harder, not roaming further. Then the finale makes the shove itself do the
killing: **anything the rubber sends flying knocks
down what it lands on** — for the fifth of a second and twenty-odd pixels it
is truly flying, it shoves and damages whatever it runs into, 5 damage being a
blob dead on arrival — so a rub delivered into the front rank of a crowd bowls
it through the second. Victims are shoved on but never become projectiles
themselves: one rub is one volley of pins, not a chain reaction.

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

The gluestick is a 29px paper-coloured smear, twice the rubber's radius, and it
sits on the page for six seconds. It is the look the rubber used to have and
gave up: a pale shape lying on the paper afterwards is exactly wrong for
something you rubbed off and exactly right for something you smeared on.
Freeze is re-applied every tick, so
an enemy that wanders in is held until the glue itself fades — it can't walk
out, it isn't shoved out by the crowd piling up behind it, and it drops any
knockback it was carrying so it doesn't lurch when it comes loose. It still
hurts anything that touches it, so a glued blob is a wall, not a safe space.
Glue plus pencil is the combination: pin the horde, then draw through it. At
this size one 90px smear holds about half of everything standing on top of you
— measured at 44 enemies frozen out of 89 within 60px — so the ink cost is what
keeps it honest, not the area.

Its four upgrades never once let the smear hurt what it holds — that stays the
tool's whole identity — and they read the hold the way the highlighter's read
the band. **A wider smear first** — the round head swaps for one half again as
broad, 29px of smear to 41. Then the crowd-control payoff written as a
number: **whatever the glue holds takes half again as much from everything**,
so the combination above becomes official — a broad pencil's 9 lands as 13.5 on
a stuck skull, past its 12, while the compass's 7 lands as 10.5 and still can't
touch a tank, which its design depends on. The third is the first damage in the
line, and the glue still isn't dealing it: **coming loose is what tears** — 4,
a blob exactly, paid once when the hold ends however long it lasted, so the
chaff a smear held never walks away from it. And the finale turns a patch of
page into a field: **everything free near the smear is dragged towards the
ink**, at a speed picked between a skull's legs and a bat's — the heavy things
cannot walk out of the field, the fast things can, and a smear thrown into a
crowd sorts it.

The highlighter is the brush that keeps working after you let go: a wide blush
band that lingers on the page and ticks damage into anything standing on it
every 0.35s. Its whole trade is against the pencil — the pencil hits once, hard,
where the nib is now; the band hits gently, everywhere it was, for as long as
the ink stays wet. Which is why it is drawn under every other mark: it would
bury the pencil lines it is meant to sit behind.

Its four upgrades read the tool the same way. **A wider band first** — the
chisel nib swaps for one two pixels fatter, 9px of band to 13, and the hit reach
grows with it — and then **a deeper burn**, 3 a tick to 5, which is a blob in
one tick instead of two: the band stops being something chaff walks across and
starts being something it dies standing on. The third level makes drawing over
your own ink mean something: **layers stack**, each separate pass of the stroke
lying over an enemy ticking as its own layer, up to three — so scrubbing a patch
triples the burn where the passes cross, and the cap is what stops a tight
scribble being a one-stroke pushpin. The worked-over ink shows it: dabs laid
back over the stroke's own band come out in the edge's red rather than blush —
the deepening a real highlighter shows on a second pass, and a map of exactly
where the layers will burn together. And the finale buys the one thing the tool
could never do — hurt something that
kept walking: **anything that touches the band catches fire** for two seconds,
shedding embers and taking 2 every 0.4s, and the fire leaves the page with it.
Ignition is checked every frame rather than on the tick, because a bat crosses a
13px band in less time than a tick and "crossed it" is the point; the burn
refreshes while it stands in the ink and starts its two seconds the moment it
leaves. The embers rise — the one particle in the game that does — red with the
odd blush spark, so a burning enemy reads at a glance against a horde that
isn't.

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

Its four upgrades pay the three skills a tapped tool has — where the point
lands, when the crowd is thickest, and whether the spot deserves the biggest
single spend in the game — and two levels are deliberately absent. Nothing
shortens the fall, which is the bat's head start and the tool's whole
counterplay; and nothing raises the crater's 10, because one short of a skull
is the design. **A longer hold first** (2.5s to 4), because the hold is what
the tool really is, then **a wider circle** (41px to 51, still well under the
compass's claim to the biggest area in the game). The rest is the deeper hits
you have to earn. **The point
bites double what it falls on**: the one body the point itself comes down on —
its own width plus two pixels of slack, through a quarter-second fall — takes
20, which kills a skull or an eye outright and is the only pin that ever will;
a level about aim wearing a damage number. And the finale: **what the crater kills drives the point deeper**. The landing is the
game's one instantaneous area hit, so it is the one place a crowd converts
into depth — every kill under the circle adds 2 to a second hit on the
survivors, so one kill finishes the skull that took the crater and two finish
an eye, while a pin dropped on a lone skull changes nothing at all. The
exception to "the tank walks out" is not for sale by itself: it has to be
earned through the crowd standing round it, which is exactly what the glue
finale gathers — the two ends of the draft meet in one play.

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

Its four upgrades are all about that journey rather than about the circle being
bigger or the number being higher, and the one level the tool obviously wants is
deliberately not among them: **nothing shortens the 0.8s**. The far side having
most of a second to walk out is the tool, not a fault in it, and a compass that
landed on the release would just be a round pushpin.

What they move instead is where on the turn the cut lands, how many turns there
are, and how many legs are making them. **The lead bites double over the first
sixth of each lap**, which finally gives the drag a second job: up to then the
direction you dragged in only decided which part of the circle got cut first,
which mattered to nobody, and now it decides which part gets cut twice as deep.
It is drawn — the pencil guide rules that stretch in the needle's own red while
you are still setting the width, the lead is pressed a pixel fatter while it is
over it, and the graphite it throws off comes off red — because a choice you
cannot see is not one you can make.

Then **twice round**, which comes with 12 damage, because a second full lap is
only worth waiting 1.6s for if what comes round is worth being cut by, and 12 is
exactly a skull: the level where the biggest area in the game stops being unable
to touch a tank.

The last one changes the shape rather than the numbers. **A second leg sets off
the other way** from the same rest point, so the two meet on the far side and a
lap closes in half the time without the arm moving any faster — the two laps the
level before it bought now come to the same 0.8s a single leg used to spend on
one. The pair share one hit list, because what they buy is the far side being
*reached* sooner rather than everything being cut twice, and they drag what they
catch opposite ways, each the way its own leg is going. The far side was the
safe place to be standing while the promise was made, and now there isn't one.

The cooldown is an **ink meter**, drawn as the health bar's mirror image: the
same bar at the same size in the opposite top corner, blue instead of red, hung
off the right edge of the page with its number on the inside, so the pair of
them empty towards the middle. It used to be a thin gauge stood on end beside
the tool column — which is where you look to *change* tool, not where you look
mid-stroke. As the health bar's twin it is read the way health is read: at a
glance, off the length of it. It goes blush once there is too little left to
start a stroke with, the one thing about it you have to catch without reading
it. The kills count moved to the foot of the page under the clock to make room,
which is where the two of them belong anyway — they are the score, and they are
read together on the game over card.

It drains by the pixel — a full meter is about 230px of pencil, 170 of pen, 150
of rubber, 120 of highlighter, 90 of glue — or by the use, for the four tools
that aren't brushes: 0.45 of the meter for a pin, 0.4 for a compass, 0.35 for a
ruler, 0.1 for a staple. Two pins from full, about three rulers, or ten staples,
and a second or so of standing still to earn one back. It refills a beat after
you stop, and won't let you start a new stroke while it is nearly empty. Long
strokes cost you; short deliberate ones don't.

Every number in that paragraph is a starting number, and three upgrade lines move
them: how much the meter holds, how fast and how soon it refills, and what a tool
charges. All three are read off the run rather than written down — `Game:spendInk`
is the one place ink leaves the meter, and what a tool charges was already
discounted once when the run's copy of it was built, so nothing downstream has to
know. Two details survive being upgraded. The floor that stops you starting a
stroke stays an *absolute* amount of ink rather than a fraction of the meter, so
what it takes to begin a line does not change because you can carry more — which
means a big well goes blush further down the bar. And the bar itself shows how
full the meter is while the number beside it shows how much is actually in it, so
the number reads past 100 on a run that has taken the inkwell. That is exactly
the health bar's arrangement, which is the point of drawing them as twins: a
fresh page grows one maximum, an inkwell grows the other, and both are still read
at a glance off the length.

A few touches make the marks feel like marks rather than shapes:

- **The pencil roughens itself.** Each stamp has a chance of a second pixel
  alongside the core, so a straight drag reads as graphite instead of a vector.
- **The pen's nib trails the pointer**, closing a third of the gap each frame.
  Hand jitter and the polygonal steps of a fast drag roll into the curve a
  ballpoint actually leaves, and corners come out rounded rather than kinked —
  a box drawn round yourself looks drawn, not stamped.
- **The rubber leaves crumbs, not a mark.** It is the one brush that puts
  nothing on the page at all. It used to sweep in paper — the colour that
  erases rather than stacking — which genuinely wiped the ruling off and let it
  fade back in behind you, but the pale band lying there for a second read as
  glue: something smeared on rather than rubbed off. So the mark is gone and
  the crumbs are the whole tool. They come off the sides of the tip as it
  travels, thrown out across the rub and carried a little way along it, and
  they brake hard and vanish within half a second — a rub reads as the spray it
  is throwing, and stops existing the moment you let go. The hit is unchanged:
  same 15px reach, same shove, same chip damage every 0.3s.
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

Generated at runtime, infinite in every direction, nothing stored. Base colour,
ruling (2px of blue, 8px of paper, repeating) and a blush margin line every 192px
are baked once into a 192x100 `ImageData` and drawn as a single texture-wrapped
quad whose UVs are just the world coordinates. One image, one draw call, however
far you walk.

It is deliberately plain. An earlier version scattered doodles across the page —
heart, cloud, bolt, sparkle — placed by hashing cell coordinates, and sprinkled
graphite grain through the paper. Both are gone. The page is the one surface
everything else is read against: every mark you make, every enemy, and the ruling
showing through the ink. Anything printed on it competes with the thing you are
actually meant to be looking at, and at this size there is no room for both. A
notebook page you have not drawn on yet is blank, and the drawing is the game.

Tune it with `RULE_THICKNESS`, `RULE_PERIOD`, `RULE_COLOR` and `MARGIN_X` at the
top of `src/background.lua`. `TILE_H` has to stay a multiple of `RULE_PERIOD`.

## Layout

```
main.lua              canvas sized to the screen, whole-number zoom, safe area
conf.lua              window config
src/
  game.lua            state, update/draw order, spatial hash, collisions, ink
  palette.lua         the eight colours
  pixelart.lua        ASCII art -> palette-locked Image (+ mask, discs, circles,
                      and the eight headings a drawing can be turned to)
  sprites.lua         all art, authored as ASCII pixel maps
  font.lua            3x5 bitmap font for the HUD
  background.lua      procedural notebook paper: ruling and margin, tiled
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
  upgrades.lua        the catalogue: every upgrade line and what its levels do
  loadout.lua         what one run has learned: its stats, tool copies, weapons
  levelup.lua         the draft: three cards on the page, and you pick one
  orbital.lua         the stars: a passive weapon bolted to you
  rocket.lua          the rocket: a passive weapon that leaves
  sun.lua             the sun: a passive weapon that owns a corner of the screen
  cools.lua           the cool S: a passive weapon that floats off in a line
  beam.lua            the laser beam: the one passive weapon you aim, down the
                      line you are walking
  enemy.lua           enemy types table, chase, knockback
  spawner.lua         offscreen ring spawning, difficulty ramp
  bullet.lua          projectiles
  gem.lua             XP pickups with magnet
  pickup.lua          hearts, ink and diamonds: fixed spots on the page, plus
                      a scatter past the screen edge
  particles.lua       one-pixel ink specks
  hud.lua             bars, timer, tool selector, thumb stick, pause button
  scribble.lua        the question every screen asks: a box you scribble in
  menu.lua            title screen: the chase behind it, and the boxes you draw in
  design.lua          the things the player draws, and their save files
  studio.lua          the board: hero, star, rocket, sun's face, cool S
  pause.lua           the QUIT? the pause button writes on the held page
```

## Extending it

- **New enemy:** add a sprite to `Sprites.enemies` and a row to `Enemy.types`,
  then add it to `TABLE` in `src/spawner.lua` with an unlock time and weight.
  A `shot` block on the row (range, period, pellet speed, pellet damage) makes
  it a shooter like the eye: it still walks at the player, but it also spits a
  pellet on its own beat whenever the player is in range. Pellets fly over pen
  walls the way bullets do — a shooter is the one pressure a wall can't hold
  off. The bloodshot eye is this recipe applied twice: the eye's row copied
  with a red pupil, a quicker walk and a shorter beat, unlocked later and
  weighted rarer. Red on the pupil is the whole tell, and it is enough,
  because red on an enemy means exactly one thing — the same reason the
  pellet is red only at its core, inside an ink rim: the player's shot is red
  to its edge, so a thing that is dark at its edge is flying *at* you.
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
  Its upgrades, if it had any, would go with it: the draft never offers a line
  whose tool is not on the strip.
- **New upgrade:** append a row to `Upgrades.list` in `src/upgrades.lua` with an
  icon in `Sprites.icons`, and give each level a line of text and an `apply`.
  What `apply` is handed depends on the row: the run's stat block for a passive
  or a weapon, and the run's *copy of the named tool* for a tool line, plus the
  canvas for anything that has to be measured off the page. Nothing else needs
  touching — the draft offers whatever still has a level left, and the loadout
  replays it. Write levels as functions of what they change and never as
  differences from what the previous level did, because every level is re-run
  from scratch on every pick.
- **New passive weapon:** an upgrade row whose first level puts a block on the
  stats, a module with `new`, `configure`, `update(dt, game, grid)` and
  `draw(game)`, and a row in `WEAPONS` in `src/loadout.lua` pairing the two. The
  block turning up is what brings the weapon into the run; the instance is built
  once and reconfigured after that, so an orbit that has been turning for two
  minutes keeps its angle when the upgrade that speeds it up lands. Hit things
  through `Game:eachNear` rather than by walking `game.enemies`, and kill them
  with `Game:killEnemyAt`. Something that covers ground rather than touching a
  point — the sun's disc — is wider than the nine cells `eachNear` looks in, and
  asks `Game:eachWithin` instead: the whole horde, on a tick a couple of times a
  second rather than every frame. Anything the weapon *throws* is back to being
  a small thing at a point, and asks the hash like every other projectile. A
  weapon that reaches across the whole page — the beam — asks `eachWithin` for a
  circle big enough to hold its line and then tests the band itself, since there
  is no line query and a circle round the muzzle is one.
- **Something drawn at eight headings:** add `turns = true` to the design. It is
  only worth it for something that points where it is going (the rocket), it
  costs eight sprites instead of one, and the four diagonals are the one place in
  the game where a drawing is resampled rather than used as drawn — so the art
  wants to be solid. Anything that aims such a drawing must round its own heading
  to the same eight before either the drawing or the thing it points at reads it,
  or the sight will lie about where the shot is going. The way out of all of that
  is to have no sprite: something plotted by `pixelart` (the beam) goes down at
  any angle and rounds nothing.
- **Something for the player to draw:** a row in `Design.by` in
  `src/design.lua` naming the field in `Sprites` it keeps up to date, the art it
  starts from (which fixes its size, and is what `RESET` puts back), its save
  file, and what the board should call it. To have it drawn when a run earns it
  rather than on the way in, add a `design` field to the upgrade row naming it;
  the board then opens on the first level of that line. `src/studio.lua` needs
  nothing: it sizes itself off the design it is handed.
- **Balance:** `SPEED`, `FIRE_RATE`, `DAMAGE` and `RANGE` at the top of
  `src/player.lua` — the loadout only ever scales what is written there —
  `Enemy.types`, the spawn interval and the min-alive floor (`FLOOR_RATE`) in
  `src/spawner.lua`, and the level tables in `src/upgrades.lua`. The floor is
  what makes the late game relentless: whenever the horde is smaller than the
  difficulty clock says it should be, the spawner refills it immediately, so
  clearing the screen buys xp rather than calm.

Enemies are separated and bullet hits are resolved through a spatial hash
(`Game:buildGrid`, 12px cells), rebuilt each frame, so the horde scales to a few
hundred without an n² pass. Pen lines get their own hash in `src/walls.lua`,
built from the strokes' coarse paths and rebuilt only while a wall is being
drawn or has just expired; segments are filed under every cell within reach of
them, so an enemy asks what is nearby with a single table lookup. A soak with
191 enemies and 500px of wall costs 0.4ms per update, of the 16.7 available.

## Not built yet

No audio. What you are carrying is only visible while the run is held — during
play the name of an upgrade flashes along the bottom of the page as it is taken
and that is the last you see of it. There are five passive weapons (the stars,
the rocket, the sun, the cool S and the laser beam) for four slots, so a run
gives one up whether it means to or not, and of the nine tool lines the pen's and the stapler's are still
unwritten: both are an unlock and nothing after it, so drafting either is the
last decision that tool ever asks you for. The shape they are waiting to be
filled into is five — the unlock and four — and `toolLine` in
`src/upgrades.lua` takes them as a list. The crit the pencil used to buy is
unused rather than gone: `crit = { chance, mult }` is still read by `Stroke` and
still drawn by `Particles:crit`, so it is a level waiting for a tool. Nothing in the draft ever
takes anything away or offers a choice you can regret.

Dying restarts straight into the next run rather than going back to the
title screen.

The **crayon** is written and working but is not on the strip at the moment — it
sits in `Tools.shelved`. It is a wax lane: a 13px band you run 1.75× along —
faster than anything in the game — while anything chasing you onto it loses its
footing, keeps the heading it arrived with and slides straight past. Moving its
row back into `Tools.list` puts it back in the game.
