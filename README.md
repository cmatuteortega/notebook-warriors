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
| Take an upgrade | circle a card, or `1` / `2` / `3` | circle a card |
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

The first three are a labelled box you scribble in. It is not a button that
happens to look drawn: the box measures *ground covered*, on a 2px grid inside
its border, and six cells arm it — a line through the box, about a third of the
way across. What that rules out is a tap or a graze rather than a deliberate
mark: a single dab lands in one cell, and scrubbing back and forth over one spot
re-marks cells that are already marked.

The draft is the other shape of question, because it has three answers rather
than two: three cards, and you **circle the one you want**. What it measures is
not area but *angle*. The ring round each card is cut into twelve sectors and
nine of them have to have been drawn in, so a loop answers and nothing else
does — a line straight across a card covers two, and scrubbing up one edge of it
covers two. The dead middle of the card is not counted at all, and has to be:
close to the centre a straight line swings through every angle there is, so
scrubbing across the middle would otherwise read as going round. That middle is
the card shrunk about its own centre rather than a circle drawn in it, since a
round hole in a card twice as wide as it is tall would swallow the top and
bottom of a loop drawn just inside the border while leaving the ends of it live.

Both shapes make the same bargain about *when* an answer counts. Drawing in one
only **arms** it; nothing is committed until the pen comes off the page. A line
that carries on into the next box, or a loop that carries on round the next
card, changes the answer rather than being too late — and the border warms from
slate through blue to red as it fills, so you can see the answer coming before
you lift.

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

The hero is not the only thing you draw. Both passive weapons send you back to
the board the first time you take them: the same board with a star on it, or
with a rocket on it, and the pixels you leave there are what goes round you or
launches off you for the rest of the run — and for every run after it, since
they are kept in `star.txt` and `rocket.txt` the way the hero is kept in
`hero.txt`. RESET puts the default back, exactly as it does for the stick man.

The rocket is the loosest of the three about what it wants: what has to survive
is the taper, so that the pointy end is still the end that goes first. A dart,
an arrow or a sharpened pencil is the same eleven by seven pixels and the same
board. Draw it nose-right, because that is heading one of eight.

#### Eight headings, four of them exact

The rocket is the only thing in the game that points where it is going, so it is
the only thing kept at more than one heading. What you leave on the board is
turned into a ring of eight (`pixelart.turn`) and a rocket picks the nearest of
them when it launches — once, since it flies a straight line.

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
tool or three; the bottom-left corner belongs to the thumb stick. The gap to the
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

## Levelling up

Every level holds the run and lays three cards on the page. You circle one, and
that is the only way past them — there is no pause button while they are up,
because a level has to be spent before the run will take another instruction.
The cards are the one thing in the game drawn on paper rather than in ink: they
are laid *on* the page and cover the frozen run underneath, so they can be read
over whatever chaos was happening when the level landed. Everything else about
them is drawn — a wonky border that warms as you go round it, and the loop you
drew sitting on top of the card the way ink sits on paper. Ink that misses every
card is not an answer, just ink, and goes under them and fades.

One card is not paper. A tool line's first level hands you the tool itself and
spends one of the three places on the strip, and it is the only pick in the
draft that costs a run something it does not get back — everything else is a run
being added to, and that is a run being decided. So the card it is offered on is
**sky** rather than paper, which is read across the whole page before a word on
any of the three has been: you know which one you are choosing *about* before
you know what it is. The card still says `NEW` in red, as the first level of any
line does; the colour is what separates the first level of a *tool* from the
first level of a passive you can always take another of. Sky and not blush,
which is the palette's other light fill: the border warms slate → blue → red as
you go round a card, and a blush card would swallow the red — the step that says
the answer has landed. Sky only costs the blue halfway step, which is the one
you never stop on.

A big enough pickup can carry two levels. The second draft comes up after the
first is answered rather than being swallowed by it, which is why levels are
*banked* on the player and spent by the game rather than applied where they are
earned. A pick that sends you to the board — the first level of the stars or of
the rocket — goes in between: the run stays held through the board and the next
draft, if there is one, comes up after it.

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
layout would rearrange itself underneath the thing you were about to circle on
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
  drawing. Two are built, and they are deliberately opposite halves of one idea:
  the stars (`src/orbital.lua`) are bolted to you and only ever touch what comes
  to them, and the rocket (`src/rocket.lua`) leaves and picks something off. The
  first level of either sends you to the board to draw the thing, rather than
  handing you one.
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

Twenty-four lines, seventy-nine levels between them, three offered at a time. A
line whose tool has been shelved is never offered — taking a row out of
`Tools.list` takes its upgrades out of the draft with it, the same way it takes
it off the selector.

**A run cannot carry all of them.** There are five slots for passive weapons,
five for passives and **three for tools** (`Loadout.SLOTS`), and a line takes its
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

All three counts are on screen while the run is held: **`2/3` under the tool
column, `1/5` under the weapon column and `3/5` under the row of passives**, in
slate until the kind is full and in red once it is. That last state is the one
worth having — full is the moment the rule starts applying, and without it a
card that stops coming up reads as luck rather than as a rule. The counters are
drawn even at `0/5`, because the first draft of a run is exactly when being told
there are five places to put a weapon is worth something, and a readout that only
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
the run is built, and the other two slots are empty until the draft fills them.
So what those three slots are really offering is two.

That is the whole reason for unlocking them. Nine tools you can all reach are
nine tools none of which you had to choose between: the strip was a menu, and a
menu is not a decision. Three are a hand.

The weapon cap does not bite yet — there are only two passive weapons to want —
so today it is a rule waiting for content rather than one a run runs into. The
passive cap bites hard (thirteen lines competing for five slots) and the tool cap
hardest of all (nine for three, one of them spent before the first frame).

What that costs is worth being plain about. A run can reach 12 levels of passive
weapon, 20 of passives and somewhere between 3 and 9 of tools depending on
whether it drafts the one tool that has upgrades written — so **35 to 41 of the
79 in the catalogue**, or roughly half. The draft dries up at that point and the
run carries on levelling in silence (`Game:openDraft` returns false and the
levels simply land), which on a long run happens while the horde is still
arriving. That is the intended end state rather than a corner case, and it is the
price of a draft that makes you choose.

| Line | Kind | Levels |
| --- | --- | --- |
| **STARS** | passive weapon | a star you draw yourself orbiting you, then two, twice as fast, cutting far deeper, three in a triangle, an orbit that breathes in and out |
| **ROCKET** | passive weapon | a rocket you draw yourself launching at whatever is nearest, then two at once, going through what they hit, harder, twice as often, three at once through four things each |
| **PENCIL** | tool | the tool you start the run holding, and the one slot of three you never chose |
| **PEN**, **RUBBER**, **MARKER**, **GLUESTICK**, **PUSHPIN**, **STAPLER**, **COMPASS** | tool | the tool itself, and nothing after it yet |
| **RULER** | tool | the ruler itself, then longer, wider, harder, cheaper, longer and wider again, and long enough to rule the whole page |
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

No run gets all of that any more, and that is the point of the slots above: both
weapons are reachable in full, five of the thirteen passive lines, and three of
the nine tools — one of which was decided for you. The numbers above are what
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
a line drawn through the crowd. Three rockets go up fanned rather than stacked,
because three down one line are one rocket with a bigger number on it.

Both weapon lines used to be longer — eight and nine — and what came out of them
was repetition rather than content. Two levels that each shaved a fraction off
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
unlocked, so it is one box tall on the first frame and three at the most; the
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
  levelup.lua         the draft: three cards on the page, and you circle one
  orbital.lua         the stars: a passive weapon bolted to you
  rocket.lua          the rocket: a passive weapon that leaves
  enemy.lua           enemy types table, chase, knockback
  spawner.lua         offscreen ring spawning, difficulty ramp
  bullet.lua          projectiles
  gem.lua             XP pickups with magnet
  particles.lua       one-pixel ink specks
  hud.lua             bars, timer, tool selector, thumb stick, pause button
  scribble.lua        the question every screen asks: a box you scribble in
  menu.lua            title screen: the chase behind it, and the boxes you draw in
  design.lua          the things the player draws, and their save files
  studio.lua          the board they are drawn on: the hero, the star, the rocket
  pause.lua           the QUIT? the pause button writes on the held page
```

## Extending it

- **New enemy:** add a sprite to `Sprites.enemies` and a row to `Enemy.types`,
  then add it to `TABLE` in `src/spawner.lua` with an unlock time and weight.
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
  with `Game:killEnemyAt`.
- **Something for the player to draw:** a row in `Design.by` in
  `src/design.lua` naming the field in `Sprites` it keeps up to date, the art it
  starts from (which fixes its size, and is what `RESET` puts back), its save
  file, and what the board should call it. To have it drawn when a run earns it
  rather than on the way in, add a `design` field to the upgrade row naming it;
  the board then opens on the first level of that line. `src/studio.lua` needs
  nothing: it sizes itself off the design it is handed.
- **Balance:** `SPEED`, `FIRE_RATE`, `DAMAGE` and `RANGE` at the top of
  `src/player.lua` — the loadout only ever scales what is written there —
  `Enemy.types`, the spawn interval in `src/spawner.lua`, and the level tables
  in `src/upgrades.lua`.

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
and that is the last you see of it. There are two passive weapons (the stars and
the rocket), and of the nine tool lines only the ruler's six upgrades are
written: every other tool line is its unlock and nothing after it, so drafting
one of those tools is the last decision that tool ever asks you for. The shape
they are waiting to be filled into is seven — the unlock and six — and
`toolLine` in `src/upgrades.lua` takes them as a list. Nothing in the draft ever
takes anything away or offers a choice you can regret.

Dying restarts straight into the next run rather than going back to the
title screen.

The **crayon** is written and working but is not on the strip at the moment — it
sits in `Tools.shelved`. It is a wax lane: a 13px band you run 1.75× along —
faster than anything in the game — while anything chasing you onto it loses its
footing, keeps the heading it arrived with and slides straight past. Moving its
row back into `Tools.list` puts it back in the game.
