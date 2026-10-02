# Survive School

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
| Answer the title screen | scribble in a box, or `Y` / `S` / `N` | scribble in a box |
| Go back to a run you quit | scribble in `CONTINUE`, or `C` — only there when there is one | scribble in `CONTINUE` |
| Open the settings page | the button in the top-left corner, or `O` | tap the button in the top-left corner |
| Change language | the `EN` / `ES` button in the bottom-left corner, or `L` | tap the `EN` / `ES` button in the bottom-left corner |
| Set a volume | drag the bar, or `↑` / `↓` then `←` / `→` | drag the bar |
| Change language in settings | the `<` `>` beside it, or `←` / `→` | tap the `<` `>` beside it |
| Close the settings page | the arrow in the top-left corner, or `Backspace` | tap the arrow in the top-left corner |
| Pick the subject | tap its tab, or `1`–`7` | tap its tab |
| Start the run on it | scribble in `GO!`, or `Enter` | scribble in `GO!` |
| Open the drawing board | scribble in `CUSTOM`, or `C` | scribble in `CUSTOM` |
| Open the library | tap the `LIBRARY` tab, or `L` | tap the `LIBRARY` tab |
| Open the homework | tap the `HOMEWORK` tab, or `H` | tap the `HOMEWORK` tab |
| Open the canteen | tap the `CANTEEN` tab, or `K` | tap the `CANTEEN` tab |
| Close either of those | the arrow in the top-left corner, or `Backspace` | tap the arrow in the top-left corner |
| Back to the title | the arrow in the top-left corner, or `Backspace` | tap the arrow in the top-left corner |
| Read a library entry | click its name | tap its name |
| Turn to another library shelf | drag the page sideways, or the `<` `>` at the foot of it, or `←` / `→` | drag the page sideways, or tap the `<` `>` |
| Turn a page on the homework or the canteen | drag the page sideways, or the `<` `>` at the foot of it, or `←` / `→` | drag the page sideways, or tap the `<` `>` |
| Walk the library shelf | `↑` / `↓` | tap another name |
| Close the library | the arrow in the top-left corner, or `Backspace` | tap the arrow in the top-left corner |
| Draw your character | hold left mouse on the board | drag on the board |
| Pencil / pen / rubber | `1`–`3`, `P` / `B` / `E`, wheel | tap the selector in the margin |
| Swap character | `←` / `→` | tap the arrows under the drawing |
| Start the run with it | scribble in `OK!`, or `Enter` | scribble in `OK!` |
| Back to the stick man | scribble in `RESET`, or `R` | scribble in `RESET` |
| Move | `WASD` / arrows | thumb stick, in a bottom corner |
| Draw | hold left mouse | any other finger |
| Drop a pushpin | click where you want it | tap where you want it |
| Drive a staple | click where you want it, again and again — or hold and drag, once the line has been finished | same, tapping or dragging |
| Aim the ruler | hold and drag to pivot, release to snap | same, with one finger |
| Open the compass | press to stand the needle, drag out the width, release | same, with one finger |
| Cut with the scissors | click to anchor, click again to cut from it | tap to anchor, tap again to cut from it |
| Put the scissors away | click back on the anchor | tap back on the anchor |
| Switch tool | `1`–`9`, `Q` / `E`, wheel | tap the selector in the margin |
| Pause / resume | `P`, or the button in the top-left corner | tap the button in the top-left corner |
| Answer the pause screen | scribble in a box, or `Y` / `N` | scribble in a box |
| Every tool maxed, for testing | `T` on the pause screen | scribble in `TOOLS` on the pause screen |
| Every passive weapon maxed, for testing | `W` on the pause screen | scribble in `WEAPONS` on the pause screen |
| Take an upgrade | scribble the box under the card, or `1` / `2` / `3` | scribble the box under the card |
| Reroll the draft | the die in the bottom corner, or `R` — only if you bought one | tap the die in the bottom corner |
| Skip the draft for coins | the `▶▶` in the bottom corner, or `S` — only if you bought one | tap the `▶▶` in the bottom corner |
| Throw a line out of the run | the red cross in the bottom corner (or `E`), then scribble a card's box | tap the red cross, then scribble a card's box |
| Get back up after dying | nothing — a retake spends itself, if you bought one | nothing |
| Buy any of the four | scribble the box on its row in the canteen, or `1` / `2` / `3` / `4` | scribble the box on its row |
| Answer the game over card | scribble in a box, or `1` / `2` | scribble in a box |

`F11` or `alt+enter` toggles fullscreen, `Esc` quits.

The stick is drawn in a bottom corner, but it is not pinned there: press
anywhere in that corner and the ring jumps under your thumb, so you never have
to look for it. Push past the rim and the ring follows rather than running out
of travel. It is analogue — a small lean walks slowly — while the keyboard is
always full tilt. The trade-off is that a finger landing in the corner always
steers, so draw with the other hand.

**Which corner is a setting** (`STICK`, see **Settings**), and it moves more than
the ring. One hand walks and the other draws, so everything you *press* belongs
to the thumb that is not on the stick: the tool selector crosses the page with
it, and the weapon column you read on a held screen takes the margin the tools
left. Left is the default, which is where a right-handed player's spare thumb
is. The corner button is the one piece of furniture that stays put — every screen
in the game has it in the top-left and none of the others has a stick to be
opposite, so a button that moved on one screen in six would be a button you have
to look for.

Three things are set against a thumb rather than against the page, and they are
one decision taken three times: **there is no speed above full tilt**, so every
millimetre a thumb travels past it is a millimetre of nothing.

- **The throw is a thumb's.** Full tilt is the knob's edge touching the rim, and
  the ring is 28 game pixels across the radius so that lands about a centimetre
  out. It used to be 13, which on a phone is four millimetres — under half a
  push — so the stick was at its ceiling before the thumb had finished setting
  off, and everything after that was drag.
- **The ring says when it is there.** It goes red with the knob pinned against
  it. Red means full tilt here and nothing else; having hold of the stick is the
  knob filling with blush, which is a separate thing and is drawn separately.
  A corner that cannot pay the instinct to push harder can at least answer it.
- **The following is on a leash.** A run is one long hold and a horde is fled in
  one direction for a while, so an origin that followed for ever would ratchet:
  each push past the rim displaces the ring for good, and after a minute of it
  your hand is in the middle of the page you are trying to draw on. It may
  follow a ring radius and a quarter from where the thumb landed, and then it
  slides sideways instead of further out. The room is deliberately mean: drift
  is what the stick does once the thumb has gone somewhere it should not have
  had to, so it is a concession rather than a feature.

And wherever it has drifted to, the ring keeps a margin off every edge of the
safe area — the same margin it keeps at rest, not a smaller one. A ring against
the edge of the screen is a thumb against the edge of the screen, which is the
one place a thumb cannot push out of, so the drift is not allowed to put it
there. The one thing that still can is your own grab: press right in the corner
of the phone and the ring appears right in the corner of the phone, because the
alternative is shoving the ring off your thumb as you take hold of it and
reading that as a sprint into the corner. It only ever gets better from there —
the box the ring may occupy is stretched to hold where the thumb landed, never
shrunk to it.

The leash is the one of the three with a price, and it is worth being exact
about what it is. Below about 55 pixels of wander — the leash plus the throw —
it costs nothing at all: a reversal answers after 23 pixels of thumb travel
whether you have wandered 20 or 55. Past that the ring stops keeping up, and a
turn costs the excess back before it answers. That is a lag in the one place a
lag is expensive, and it is deliberate: it is self-correcting, it only happens
where the thumb is already somewhere it cannot play from, and bringing the thumb
back where it belongs is both the fix and the thing the stick is trying to
teach. `STICK_LEASH` in `src/input.lua` is the number; `math.huge` is the old
behaviour, and `STICK_MARGIN` is the clearance.

## Asking by drawing

Seven screens ask you a question — the title screen (`START?`), the timetable
(`GO!` / `CUSTOM`), the drawing board (`OK!` / `RESET`), the pause screen
(`QUIT?`), the draft you get for levelling up, the win screen (`END` /
`ENDLESS`) and the game over screen (`RETRY` / `QUIT`) — and they all ask it by
making you draw the answer, so the asking lives in one place,
`src/scribble.lua`. Every one of them is a page you can draw
the rest of anyway.

Every one of them is a box you scribble in. It is not a button that happens to
look drawn: the box measures *ground covered*, on a 2px grid inside its border,
and six cells arm it — a line through the box, about a third of the way across.
What that rules out is a tap or a graze rather than a deliberate mark: a single
dab lands in one cell, and scrubbing back and forth over one spot re-marks
cells that are already marked.

The draft asks the same way, just three times: each of its cards has a box
under it, unlabelled because the card above it is the label. Scribble in the box
under the card you want. The card itself used to be tappable — a tap drew the
scribble into its box for you, the same way the keyboard shortcuts do everywhere
— and that is the one place the shortcut has been taken away, because the draft
is the one screen you do not choose to arrive at. See **Levelling up**.

The timetable is where the rule is worth stating from the other side. Its index
tabs are *not* boxes — you press one and the book opens there — nor is the back
arrow in its corner or the `LIBRARY` tab in the opposite one, and its `GO!` is an
ordinary labelled box you scribble in. The line between them is whether anything
is being decided: choosing which page to look at is not a question, backing out of
the screen without picking one is not a question, going off to read the catalogue
is not a question, and leaving for a run is. A screen that asked you to scribble
seven times while you made your mind up would be spending the gesture on
nothing, and a gesture spent on nothing stops meaning anything when it matters.

The library is that rule taken to its end: it is a whole screen with **no box on
it at all**, because there is nothing on it you could decide. You press a name to
read it, you press an arrow to turn to another shelf, and you press the corner to
close it. Nothing is spent, so nothing needs the ceremony of being drawn.

Every box makes the same bargain about *when* an answer counts. Drawing in one
only **arms** it; nothing is committed until the pen comes off the page. A line
that carries on into the next box changes the answer rather than being too
late — and the border warms from slate through blue to red as it fills, so you
can see the answer coming before you lift.

## The title screen

**SURVIVE SCHOOL**, and under it `START?` with a YES box and a NO box. You
answer it the way you do everything else here — by drawing. Scribble inside a
box and that is your answer: YES goes to the timetable, where you pick which
page of the book to play on, NO closes the book.

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

### The third box

Under those two there is sometimes a `CONTINUE` box, and it is there for exactly
one thing: a run you walked out of through the pause card. Scribble it in and you
get that run back — the page you had drawn on, the horde standing where it stood,
the ink you had left, the clock, the build, all of it.

Nothing is loaded to do that, because nothing was thrown away. Quitting from the
pause card banks the record and goes to the title, and that is *all* it does: a
run is only ever replaced by the next `GO!`, so while the title screen is up the
run is still sitting behind it, still held exactly the way the pause card held it,
on the very page the title is being drawn on. Answering the box is the pause
button's other half — the run is let go rather than rebuilt — which is why it is
free and why it is also honest: what comes back is not an approximation of the run
you left, it *is* the run you left.

It is only ever offered for a run that has not *ended*. Dying and taking `END` on
the win card are endings, and an ending has nothing behind it to go back to; the
first `GO!` of a new run takes the box away too, because the old run has just been
replaced.

#### And a bookmark behind that

Closing the program does take the page. But it does not take the run, because the
last thing the game does on the way out is leave a **bookmark** — one small text
file beside the drawings and the register, and the only file in the game about a
run rather than about the book.

It is called a bookmark rather than a save because that is honestly what it is. It
says which page you were on and how far down it you had got, and it does not keep
what was written there. Relaunch, scribble `CONTINUE`, and you come back **on
fresh paper**: at the minute you left, with the build you had, at the level you
had reached, with the health and the ink you had left, into a horde arriving at
exactly the pressure it was arriving at. What is gone is the page — the crowd that
was standing on you, the walls you had drawn, the pins holding things down, the
half you had cut off.

That split is not a corner cut, it is the two halves of a run costing wildly
different amounts to keep. **What you learned** is twenty-odd numbers, and it is
cheap for a reason the upgrade system already needed to be true: every level in the
catalogue is written as a function of what it changes rather than as a difference
from the level before it, so a run's whole stat block is a pure function of the
levels it reached. Hand back a list of lines and the levels on them and the build
rebuilds itself exactly, weapons and all. **The page** is a dozen tables of live
objects — the horde with each monster's walk offset and which way round a wall it
committed to, every stroke and its chain of stamps, the spent pins and staples
that stay on the paper for good, the puddles, the blades still travelling down a
cut — most of which mean nothing without the module that made them. Writing that
down is a different project, and a save file that quietly handed back a *different*
page from the one you closed would be worse than one that says up front it hands
back none.

So the two halves of `CONTINUE` are not equally good, and the better one always
wins: if the run is still in memory you get it whole, and the bookmark is only what
is left once the program has gone.

Three things worth knowing about when it is written. It is written when you close
the program — `Esc`, the window's close button, or `NO` on the title screen — and
also the moment you quit from the pause card, since that is the point you have said
you are done for now. It is **deleted** by the three things that end a run: dying,
`END`, and `GO!` starting the next one. And it is never deleted on the way out, so
closing the book without having played leaves the bookmark that was sitting there
when you opened it. What it does not survive is being killed from outside — a force
quit or a crash never reaches the code that writes it.

One case is handled rather than kept: a run bookmarked **during a boss fight** comes
back in the horde phase with the clock still past the ten minutes, so the eye walks
on again on the first frame and the fight starts over from the top. A bookmark
cannot keep the eye — it is a thing standing on the page — and the alternative was
a spawner stuck in a fight with nothing in it.

It is a box of its own rather than a third answer in the strip: it sits on its own
line under `YES` and `NO`, because those two are the halves of one question and
this is a separate offer. A stroke that runs out of one and into another still
changes its mind — the last box drawn in wins, whichever of the two questions it
belongs to. `C` scribbles it in the way `Y` and `N` scribble theirs, and the hint
line names the letter only when the box is there. It comes on on the same beat as
the other two, so the opening is the same length whether there is a run behind the
title or not, and answering it pulls the paper away exactly as `YES` does: starting
a run and going back to one are the same journey off this screen.

**Two things in the left margin are not page.** The top-left corner holds the
settings button — the same box the run's pause button lives in, wearing two
sliders, because two bars is what is behind it — and the bottom-left corner holds
the language switch, the same box at the other end of the same margin with `EN`
or `ES` written in it. Neither is a question: one opens a screen and the other
throws a switch where it stands, so both are *pressed* rather than scribbled, and
ink that lands on either is dropped rather than drawn — the timetable's rule for
the same pair of corners.

The switch is here, and not only inside settings, because it is the first thing
somebody who cannot read the title needs. Burying it one screen inside a page
written in the wrong language is burying it. Press it and the title, the question,
the boxes and the hint are all in the other language on the next frame.

The page underneath is the game's own: the same ruled paper panning as if a
camera were following someone, the character you drew walking a lap of it, and
the same monsters the spawner uses strung out behind him — real `Enemy`
instances chasing a moving point, so they steer, bunch up and trail exactly as
they will in a minute's time. It goes through the same overprint pass too, so
the ruling shows through the title — and the doodle and the monsters chasing him
stand on top of it rather than being printed into it, exactly as they do in a
run.

## Settings

The top-left corner of the title screen opens a page with six rows on it: how
loud the music is, how loud the sound is, what language the game is in, which
bottom corner the thumb stick sits in, how much of a hit the page says out loud,
and whether the game asks you to draw the things it hands you. It is
a loop off the side of the title screen rather than a step through it — the corner
button opens it and the corner button hands it back — and coming back lands on a
title that is already written on, because you did not re-open the book.

It takes the pause card's shape: one block of rows centred in the page, a heading
over it, a hint under it. What it does not take is the *card*. The pause card is
paper because there is a run underneath it that lettering cannot be read against;
here there is nothing underneath but the page you came in on, so this is written
straight onto it the way the timetable and the library are. The bars go out over
the top of the overprint pass with the corner button, for the timetable's tab
reason — a paper-filled box whose border lands on a rule comes out a step darker
and reads as a hole cut in the page rather than a thing lying on it.

**Nothing on this page is a question, so nothing on it is a box you scribble in.**
Every box in this game is a thing you cannot take back: it arms while you draw in
it, its border warms slate → blue → red, and lifting commits it. Every one of
those properties is wrong for a volume. A volume is not an answer you could get
wrong — it is a quantity, you can always move it again, and the only way to know
whether it is right is to *hear* it. So a bar is dragged, an arrow is pressed, and
ink that lands anywhere else is still ink and still fades off. That is the rule the
timetable's tabs and the whole of the library are already drawn along: choosing
what to look at, or how much of something you want, is not a question — only
leaving is.

Which bar you have hold of is latched on the press edge and held for the whole
drag, so straying off a seven-pixel track does not drop it. Each bar has a handle
standing a pixel proud of its own fill, which is what makes it read as a control
rather than as one of the HUD's readouts; the fill is blue, because the palette
splits the page between the two sides of the fight and a volume is about as yours
as anything in the game gets. The number beside it is drawn with the bar rather
than with the lettering — a bar and what it says are one object. Letting go of the
sound bar plays one sound at the level you have just set, and writes the file. The
file is written when a drag *ends*, never while it is happening.

The music bar is the one control on the page that demonstrates itself, and it is
first for that reason: the track is up from the frame the program read its options
file, so dragging that bar is heard while the finger is still down rather than when
it comes up. Nothing is played to announce it — an effect fired to show the *music*
volume would be showing the wrong number — and dragging it to nothing leaves the
track playing at zero instead of stopping it, because a stopped stream comes back
at the top of the file and turning the music down and up again would restart it
rather than turn it back on.

The bottom four rows are the library's footer arrows doing the library's job: two
arrows either side of the name of the thing they step. On the language row what is
written between them is the language's own name for itself — `ENGLISH`, `ESPAÑOL`
— because somebody looking for Spanish is looking for the word ESPAÑOL and not for
the word SPANISH. The same switch is on the title screen, in the bottom-left
corner, so it can be reached without reading anything. Every row's arrows are
struck off the widest word *any* of them can hold, so they line up with each
other as well as standing still while their own word is stepped.

`STICK` is `LEFT` or `RIGHT` and it is the one row on the page a phone needs and
a desktop never uses — see **Controls** for what it moves, which is the ring and
both margin columns with it. It is written down on every screen rather than
appearing when you touch one: the whole reason this page can be centred at all is
that six rows are six rows everywhere, and a row that came and went would be a
block whose height changed under you.

`DAMAGE NUMBERS` steps `ALL` → `BIG ONLY` → `NONE`, most to least, so a step
right is always less of it. See **Reading a hit** for where the cut falls. It
exists because a late build lands several hits a frame on a crowd and the page is
the thing you are meant to be reading; it ships on `ALL`, because a page filling
with fatter numbers is how a run reads its own progress.

`NEW DRAWINGS` is the last row of the four and it steps between `ASK` and `SKIP`. It is about
the boards the game opens *for* you rather than the ones you go and ask for: the
weapon a draft has just sold you, and the arm a character carries, handed on from
the hero's own board. On `SKIP` neither of them opens, and what arrives wears
whatever is already on its file — the drawing you made the last time you were
asked, or the one you were handed to draw over. `CUSTOM` on the timetable is
untouched, and that is the line the row is drawn along: a board you pressed a
button to get is not the game interrupting you, and nothing here may take it away.
So nothing is lost by turning the asking off — every board is still one `CUSTOM`
and one draft away — and what is bought is a run that does not stop dead on a
blank grid each time it levels. It ships on `ASK`, because the board is the game.

The two words are `ASK` and `SKIP` rather than `ON` and `OFF` for the reason the
row is worded the way it is: `ON` against a row that names a refusal is a double
negative you have to stop and work out, and a stepper is read at a glance or not
at all.

All six live in `options.txt` in the save directory, one setting a line, in the
same shape a record is kept in: a line the game cannot read costs that one setting
its default and nothing else. A garbled options file must never be a game that
will not start. A yes or no is written there as `1` or `0`, and a row that steps
through a list writes the value itself — read back against the list its own module
owns (`Damage.MODES`, `Input.SIDES`), so a word from a later version of the game
keeps the default rather than being trusted. Every line is a key and one token.

**And a seventh row that does not ship.** While the game is being made there is an
`UNLOCKS` row at the bottom of the page, stepping `EARNED` → `ALL` → `NONE`, and it
is the one row here that is not a setting: everything above it is a thing a player
chooses about the program and this is a thing a dev does to the game. `ALL` is the
book finished — every line in the draft, every page on the timetable, every hero on
the board. `NONE` is the first afternoon: one page, the handful of lines a fresh
book deals, the one hero it comes with — on a save with months of records in it,
which is otherwise a thing you only get to look at once.

It is an **override and never an edit**. Nothing it does writes a record, buys a
hero or spends a coin, so a book stepped to `ALL` and back is exactly the book it
was — which is the whole reason it is safe to leave lying about during development,
and the whole reason it can come straight out at launch. It deliberately does not
touch the purse or anything bought out of it: those are things you bought rather
than things the book opened, and the counter already has its own way back for them
(**Everything back**).

### Two languages

The game is playable in English and Spanish, and every line of *copy* a player can
read goes through one door on its way to the page. **The English string is the key.** There
is no table of `hud.kills.2`-style ids: an upgrade's copy stays written out, in
English, in the upgrade's own row, and `src/i18n.lua` maps that English to the
Spanish. Adding an upgrade is still one row in `Upgrades.list` and nothing else,
which is the promise the whole **Extending it** section is written on, and a string
nobody has translated yet reads as English copy rather than as a missing key.

The catalogue is never translated in place — the language can be changed from the
title screen and from the settings page, and `Upgrades.list` is the same table for
every run the program plays, so it holds English for ever and the screens ask for
the Spanish each time they draw. Which puts one rule over every layout in the
game: **a measurement and the draw it is for have to be of the same words.**
Nearly every screen here reserves room for the widest string it can ever hold —
the pause card, the timetable's stat block, the library's columns — and a block
measured on `HERO` and `TOOL` and then lettered `HEROE` and `UTIL` is a block the
lettering runs out of. Anything cached off the text is cached off the language
too: the draft and the library both break level text to a width once rather than
every frame, and both would otherwise still be showing the words they were last
read in.

Three things about how the Spanish is set, and all three are the 3x5 face
(**Reading a hit** has the rest of what that face can and cannot do):

- **No acute accents.** A capital in that face fills all five of its rows, so
  there is nowhere above one to put a mark and nowhere inside one it would not
  read as a smudge. It is `ORBITA` and `MUSICA`. Leaving the accent off a capital
  is ordinary in display lettering; drawing a mark into the letter is not.
- **N-tilde is drawn, and so are the two inverted marks.** N-tilde is a letter of
  the alphabet rather than an accented N — a word with `N` in its place is
  misspelt, not unaccented — so it is a glyph: the tilde takes the top row and the
  N below it is squeezed into four, the same move the digits already make to fit a
  two-pixel stroke into three columns. `¿` and `¡` open a sentence in Spanish and
  are each the closing mark turned over, which is exactly what they are. All three
  are two bytes in UTF-8, which is why nothing in the game measures or indexes a
  drawable string by the byte any more — `Font.width`, `Font.count`, `Font.at` and
  `Scribble.printBig` all walk letters. Getting that wrong does not misplace a
  word, it misplaces whatever block was measured off it.
- **No commas.** The face had no comma at all, which nine lines of English
  catalogue copy were quietly drawing a blank for; it has one now — the one mark
  that fits below a baseline in a face with no descenders, in the bottom row where
  the full stop already sits. The Spanish is written without them anyway, which is
  the rule a character blurb was already held to.

**Two things are deliberately left in one language, and they are the same thing: a
name is not a sentence.** The title on the front of the book is what the game is
called rather than a line of copy about it, so SURVIVE SCHOOL reads as SURVIVE
SCHOOL on both — the title screen draws its own constants and neither word is in
the dictionary. Which also keeps that screen's opening honest: the title writes
itself on a letter at a time over a clock struck off its own length, and a title
that came out shorter in one language than another would be an intro that ran at
two speeds. The other is a language's own name for itself in the switch, for the
reason already given — somebody looking for Spanish is looking for ESPAÑOL.

The one cost of keying on English is that two things meaning different things must
not be written the same way. Exactly one place hit that: the school subject
`LANGUAGE` against the settings row `LANGUAGE`, which are `LENGUA` and `IDIOMA`
and cannot share an entry. The lesson was reworded rather than the scheme worked
around — it is `GRAMMAR` now, which suits its paired-rule page better anyway,
since paired rules are handwriting lines. That is what to do if it ever happens
again.

## The timetable

A notebook has more than one subject in it, and `TODAYS LESSON` is where you say
which one this run is.

**The lessons are index tabs down the edge of the book.** That is the whole
arrangement, and it is the one thing on this screen that is not a metaphor: you
are choosing where to open a notebook, and the way a notebook offers you that
choice is a column of tabs sticking out of its edge. They run off the right of the
sheet, one per subject, stacked; the lesson is written on the tab with the icon of
the tool it hands you at the outside end; and the tab of the lesson you are on is
**pulled out** into the page, the way the one you have a finger in is.

The rest of the sheet is the run that lesson would be, and every last thing on it
is read straight down the middle: `TODAYS LESSON`, the lesson's own name under it
at the same size, the six rows of who is going out there and what he is given and
how the page has gone and which class you are sitting it as, and then the character
himself at twice the size he is played at. At the foot of the page, in a row of
their own, the two boxes: `CUSTOM` — the board on that lesson's page, which hands
the screen straight back here when you are done, so the character you are looking
at is the one you would walk out with and changing him is a detour rather than a
toll gate — and `GO!`, which starts the run there and then.

The character used to stand out in the *left* margin with `CUSTOM` beside him,
on the argument that he is not the thing being chosen and so is not what the sheet
should be centred on. What that actually bought was a hero standing in the margin
the `LIBRARY`, `HOMEWORK` and `CANTEEN` cards are stacked in, a hand span from a
column of card, with the sheet reading as two layouts that had been done
separately. In the column he is a row like the others, and the order the column
reads in says what the screen is on its own: what today is, which lesson, how it
has gone, which class, and who is going.

**And the two boxes are at the foot together rather than one under him and one
alone**, which is the newest decision on this screen and the one the rest of the
layout now rests on. `CUSTOM` sat directly under the character because it is the
door to *him* rather than to the lesson, and `GO!` sat alone at the very foot
because the one answer that spends a screen should be somewhere nothing else is.
Both of those are true, and between them they were taking twenty-eight pixels out
of the middle of the column — which is exactly where the drawing of the character
is, and twenty-eight pixels is the difference between him being drawn at twice the
size he is played at and at once. A word underneath him is a worse way of serving
him than a bigger drawing of him. What the two boxes lost by sharing a row, the
sheet spent on the two things it is actually about: which class you are sitting the
lesson as, and how big the hero is.

**And on a page held upright they go back to being apart**, which is not a
reversal of any of that but the other half of it. Every line of the argument above
is about a shortage of height: a box in the column costs 28 pixels and those
pixels are the drawing. A phone held upright has a hundred of them going spare and
is paying nothing, so there the two boxes are better off saying what they are.
`CUSTOM` goes back **under the character** — the thing it is the door to, which is
what it captioned before the pair — and `GO!` takes **the far corner** on its own,
the one the three cards in the other margin leave empty, diagonally across the foot
of the page from them — centred in what they leave and stood off the foot rather
than pushed into the angle of it. Which is what it was owed all along: it is the
one answer that spends the screen, and nothing else being anywhere near it is the
whole of how a page says so. The corner is taken only where it is a real corner — clear of the
cards, *under* the last lesson tab rather than beside it, and with the column still
able to carry `CUSTOM` on the end of it and have room left over. A wide page fails
that last test by about a hundred pixels, which is the same shortage that made the
pair in the first place.

They **stack** instead of pairing on a page too narrow to hold them side by side —
which happens around 240 pixels of width in Spanish, where the three cards in the
left margin and the lesson tabs down the right take two thirds of the page between
them. `CUSTOM` over `GO!`, both still at the foot, because a second row down there
costs 24 pixels and a box back in the column costs 28: the cheaper fallback is also
the one that keeps the column free of boxes either way, which is the whole point of
having moved them. And where the foot meets those cards at all, the page is asked
which of two moves it can afford. A wide one has no height to give, so the foot is
walked *sideways* off the middle line: losing a little symmetry on a page nobody
would call symmetrical is nothing, and lifting it there would cost the column every
row below the stats, the drawing included. A page held upright has more height than
the sheet has rows, so the lift is free and the boxes go over the top of the cards
instead — which is the better of the two moves by some way, since it keeps them on
the same middle line the heading and the drawing are on. An upright phone in
English gets the pair back on the strength of it.

**And nothing is written above `GO!` any more.** Three hint lines used to sit
there — what to scribble, which keys pick a tab, which keys answer what — and every
one of them named something that is on the page to be pressed. The space they took
is the space the character now stands in, which is a better use of it: a drawing of
who is going out there says more about the run than a paragraph explaining a box
does. What is left to say the page says itself, in the way every question in this
game says it — the box warms slate to blue to red as it fills.

**A tab is card, so it is opaque.** Every one of them is filled in
`Palette.paper` — the one colour in the game that covers what is under it rather
than stacking with it — so the ruling stops at a tab's edge the way it would at
the edge of a divider laid on the page. The column is also drawn *after* the
overprint pass, which is the other half of the same idea: the fill clears the
ruling, but the pass pairs every inked pixel with the page beneath it whatever
was drawn in between, so a border or a letter that happened to land on a rule
still came out a step darker and the tab read as a transparency with the lines
showing through its lettering. Out past the pass nothing is paired with anything,
and a tab is the flat colour it says it is. The picked one was left unfilled for a
while, on the argument that the page running through it says *this tab belongs to
this sheet*; on the pages with something to say — squared, the ledger's header
bands, the staves — what it actually said was that a hole had been cut in the tab,
with the ruling crossing the lesson written on it. A tab has exactly two things to
carry, a word and an icon, and a pattern running under them competes with both.

That leaves the pop and the colour to say which tab is open, and between them
that is plenty: it is the only one sticking out into the page and the only one in
red.

**And the book opens one page at a time.** A fresh notebook opens at `SCIENCE`
and nowhere else: every other lesson is opened by the lesson *above* it in the
column, and the bar climbs a minute a rung — two minutes on Science opens `P.E.`,
three on P.E. opens `GRAMMAR`, and so on down to seven on Maths for `ART`. The
column is therefore the term as well as the index, which is why the tabs are in
the order they are in (see [The term](#the-term)).

A shut tab is still a tab. It is drawn in graphite rather than slate, its tool is
a graphite silhouette of itself instead of the icon, and pressing it turns the
book to that page exactly like any other: the ruling under the whole screen
changes, the lesson's name goes up in graphite, and where the five rows of your
record would be it says why it will not open and what to go and do about it —
`ONLY AFTER MATHS`, and under it `SURVIVE 7 MINUTES THERE`. It is the library's
hole in the library's two colours, because it is the same kind of fact. The one
thing that is missing is `GO!`: there is nothing at the foot of the page, and the
room it had is left empty rather than closed up, since the column may not walk
about as you step the tabs. Red is missing too, and that is deliberate — red on
this column means *this is where the book is open*, so a shut tab pops out when
you pick it and stays grey.

**A tab is pressed, not answered.** Everything else this game asks you, you
answer by drawing — but a tab is not a question. It is where the book is open,
the same kind of thing as the tool selector down the side of a run: you put a
finger on one and the book falls open there, page and all. Nothing is spent and
nothing is decided, so nothing needs the ceremony of being drawn, and asking for
a scribble to change which page you are *looking* at would be asking you to
answer the same question seven times while making your mind up.

Picking a lesson and starting a run are two things rather than one, and that is
the whole point of the shape. Pressing a tab selects: the page under the entire
screen turns to that ruling, the panel fills in with that lesson's tool and
records, and nothing else happens. Only the two boxes are answered the way this
game answers things, and they are the only bordered things on the screen, because
they are the only things here that actually decide something. Seven tabs that went straight to the drawing board would
be seven doors with nothing written on them, and the thing worth writing on them
(what the lesson hands you, what you have already done with it) has to be
somewhere you can stand and read it. Change your mind as often as you like; the
book stays open at the last tab you touched until you scribble `GO!`.

**And there is a way back out of it.** A back arrow sits in the top-left corner
of the safe area, and it is not a box either — it is the same 11px button in the
same corner the run's pause button uses, drawn by the same code, with the same
touch allowance round it. Press it and the book closes back to the title
(`BACKSPACE` on a keyboard). It is pressed rather than scribbled for exactly the
reason a tab is: nothing is decided by it. `GO!` spends the screen and `CUSTOM`
spends a detour, but going back spends nothing, and it is the one way off this
screen that does not even settle which lesson you were on — the subject is left
at whatever page the book was already open at. Being the pause button's box in
the pause button's corner is the whole of what says so: that is the button that
backs out of wherever you are, and the timetable is a place you can be.

**And there are more tabs, off the other edge of the book.** They stack up out of
the bottom-left corner, diagonally opposite the lesson tabs and under the back
arrow, and they are the parts of the book that are not lessons: `LIBRARY` at the
bottom, which opens the catalogue — every tool, every weapon and every passive the
draft can ever offer, written out (see [The library](#the-library)) — and above it
`HOMEWORK`, the list of things the book asks you to go and do, and `CANTEEN`, the
shop (see [Homework and the canteen](#homework-and-the-canteen)). Read down the
page they are `CANTEEN`, `LIBRARY`, `HOMEWORK`, which is the order they stop being
about the next run: what you spend before one, what the run could be dealt, and
what is true of the book whatever you play. They are tabs rather than buttons because
that is exactly what they are: the subjects are index tabs down the right edge of
the book and these are the tabs off the *left*, at the bottom, where the reference
section of a school notebook goes. Everything a lesson tab is, they are — filled in
paper because a tab is card, drawn out past the overprint pass, and running off the
edge of the sheet so a tab reads as coming out of the book rather than being
squared off against the screen — mirrored, so only the corner of the rectangle goes
past the edge and nothing written on one ever does.

Each is also **cut to exactly a lesson tab**, the same width and the same height
whatever the page made those, and that is the one thing about them worth being firm
on. A tab is a piece of card in the edge of a book, and the whole of what says
these belong to the same book is that they are the same piece of card. Sized to
their own words they read as labels stuck on the corner; sized to the back arrow
above them, as more buttons that happened to have words in them. Neither is what
they are.

**The column is stacked flush**: every card at the same edge of the sheet, one gap
apart, stacked up from the bottom. They are the same piece of card in the same
place, the way the lesson tabs down the other edge are, and what says one from the
next is the gap between them and the word on each — exactly as it is over there. A
column that stepped its cards into the page would be claiming they are a stack with
an order to it, and these are three doors with nothing to do with each other. The
one thing on the sheet that has to stay clear of them is `GO!`, on a page narrow
enough that the middle of it and this corner are the same place; everything else is
centred down the middle of the page and nowhere near.

Three things are theirs rather than a lesson tab's. They are always slate, never
red, because red on a tab means *this is where the book is open* and the book is
never open at one of these. They carry no icon, because a lesson tab's icon is the
tool that lesson hands you and none of these hands you anything but somewhere to
go. And the word is centred on the card rather than flush to an edge: a lesson has
two things to place and puts one at each end, and these have one. `L`, `H` and `K`
on a keyboard — `C` is the drawing board.

Three things fall out of the pair of them and all three are in
`src/timetable.lua`. The margin gets first refusal on a press, ahead of the tabs
and the boxes both, because neither of those two is part of the question being
asked. Ink that crosses either is dropped the way ink that crosses a tab is — the
paper fill would hide the mark anyway, and the press that made it was a press.
And the sheet is fitted under the button rather than under the edge of the page,
so the heading cannot walk up beneath it; the tabs down the other edge are not
measured against either. `GO!` is fitted the other way round, from the foot of the
page up, and the tab in that corner is the one thing it is measured against: where
the two of them would meet, the box goes above the card.

A subject is a **page** and a **tool**:

| | The page | It hands you |
| --- | --- | --- |
| SCIENCE | ruled: 2px of blue every 10, blush margin every page width | the pencil |
| GRAMMAR | paired ruling: two lines 10 apart, then a gap the same again, blush margin every page width | the highlighter |
| P.E. | a calendar: day boxes 32×24, rows ruled heavier than columns, a blush week line every page width | the stapler |
| FINANCE | a spreadsheet: cells 40×12, with the lettered header band and the numbered header column filled solid | the ruler |
| MUSIC | staves: five lines four apart, then as much again of nothing, bar lines every page width | the pushpin |
| MATHS | squared: the same ruling with 1px verticals added, doubled blue margin every page width | the compass |
| ART | unruled: two punched holes a page width, and nothing else | the rubber |

**The crowd is the same at every lesson; the shape it arrives in is not.** Every
subject spawns from the same table, with the same monsters unlocking at the same
minutes and worth the same health when they do, and none of them turns either of
the two dials that would change that — `crowd`, which multiplies the weight of a
kind, and `clock`, which scales the difficulty clock. Both still work and the
spawner still reads them; nothing uses them.

What every lesson *does* say is which **drills** it deals and how often — which
of the five formations the horde may walk on in, and the seconds between them:

| | Deals | One every |
| --- | --- | --- |
| SCIENCE | the line, the ring, a little of the hot side | 60s |
| P.E. | the line and the pincer, and the hot side | 38s |
| GRAMMAR | the pincer and the line, then the hot side | 46s |
| FINANCE | the grid, then the line | 44s |
| MUSIC | the ring and the line | 40s |
| MATHS | the grid above all, then the ring | 42s |
| ART | all five, evenly | 34s |

Each hand is argued from the ruling rather than from difficulty, because the
ruling is the thing you are looking at. A ledger is rows and columns, so FINANCE
deals a table of figures walking at you four deep. Squared paper *is* a grid and
a compass draws circles, so MATHS deals the grid and the ring — the two shapes
its own page and its own tool already are. A stave is a chord and a scale, which
is the ring and the line and nothing lopsided, so MUSIC is the one page with no
hot side. P.E. is the word taken literally: a class drills, and a class drills in
lines, so it deals walls and pincers and never tiles. SCIENCE deals the two that
arrive earliest and deals them slowest, because it is the page a first run is on.
And ART, the unruled page, deals all five at the same weight and more often than
anywhere else — with no ruling to say what shape a thing should be, any of them
can be next and none is likelier.

That is a third dial and deliberately a weaker one than the other two: it can
only move where a monster is standing when you notice it, never what the monster
is or what it costs to kill. **A page may shape an arrival; it may never price
one.** Which is what lets two lessons be different games to play while staying
the same game to measure — a record set on one is worth comparing to a record set
on another.

Between them, the page, the tool and the drills are enough for two runs to be
different games: the first decides what every mark comes out as, the second
decides what the marks are, and the third decides what you are drawing them at.

Handing a tool over is not a special case of anything. A tool line's *first
level is its unlock*, so a lesson naming `pencil` means the run starts that line
at level one — it spends one of the four tool slots exactly as a drafted tool
does, and the draft goes on offering the line the four levels it has left. There
is no "this one was free" flag anywhere.

Three of the ten drafted tools are not handed out by any lesson. Two of them are
the
same refusal: the **pen** and the **gluestick** are what you draw to keep
something *out*, and a run that opened holding one would be defending before it
had anything to defend. They stay drafted until there is a lesson that is about
holding a line. The **scissors** are out for a different reason — they are the one
tool on the strip you have to be told how to use, since every other one does
something on the first press and a cut waits for the second — so a run is not
handed them before it has read the card that explains them.

There is an eleventh row in `Tools.list` that no lesson can hand out and no
draft can deal in the ordinary way: the **halo**, which is what a run gets for
finishing two other tool lines. See **Fusing two lines**.

Nothing on a tab is a picture of the page, and it used to be — this screen was a
grid of cards and every one carried a swatch of its own ruling. What replaced it
is better than it was: **the page the whole screen is standing on is the swatch**,
so the instant you touch a tab the ruling under everything turns into the one you
are about to play on, at full size and across the whole sheet rather than in a
20-pixel window. Trying one and trying the next costs a press, and a swatch was
only ever a smaller second copy of what the screen was already showing. What a tab
shows instead is the half of a lesson the page cannot: the lesson, and the tool it
puts in your hand.

The icon is the whole of what a tab says about the tool. It said the name too,
once, at the far end of a much wider stripe, and the word was the part worth
losing — the same eleven pixels of glyph is what the tool selector, the draft
card and the pause screen all use, so it is a thing you can already read by the
time you are picking a lesson. It is drawn in the tool's own colours rather than
as a silhouette, because a lesson hands you the thing and not a shadow of it —
the icon on the tab is the icon that will be in the selector a minute later. The
word is not gone, either: the panel spells out the tool the *selected* lesson
issues, which is the one place on the screen with room for it.

The tabs draw themselves on as the screen opens, one after the next down the
edge, and each icon is stamped on once its tab has finished. Only the border and
the fill run off the sheet: nothing written on a tab ever goes past the safe
edge, so a phone that hides those few pixels under a notch hides the corner of a
rectangle.

Apart from the tabs, everything here is drawn *on* the page rather than laid over
it, hero included — there is nothing else on this screen that has to hide what is
behind it, which is the difference between it and the draft, where a card is
opaque because a frozen run is too busy to read lettering against. The tabs are
the exception for the same reason the draft's cards are: they are things lying on
the page rather than things written on it.

The character in the panel is the one you drew, with the scrap of ground under him
and the walk bounce on — the drawing board's own preview, blown up to twice the
size he is played at. He is the one thing in the game shown at anything but 1:1,
and the room to the side of a centred column is what pays for it: at 1:1 he is
eleven pixels of stick man beside a heading ten pixels tall, and the whole point of
putting him here is that you can see who you drew. It is a whole-number scale
pushed round the same drawing rather than a second copy of anything, so he is still
on the pixel grid and his bounce is still one pixel of *his*.

Everything else is centred on the middle of the **screen** — not on the middle of
what the tabs left over, which is a different line by half a tab and reads as
slightly out rather than as centred. A tab is card in the edge of the book and runs
off the sheet at that edge, so the column of them is margin; the page it leaves is
still the whole page, and the thing the screen is about goes down the middle of it.
Where a page is narrow enough that a centred block would run under the tabs, the
line steps left by exactly as much as it takes to clear them, and everything
centred — the column, `GO!`, and the box `CUSTOM` falls back to — steps with it, so
they are still on one line as each other. Being on one line is the difference
between a screen about a lesson and a page of scattered lettering. Everything on it is measured at the widest and tallest it can ever be —
the longest lesson name in the book, the widest tool name, the longest character
name, every weapon in the roster, all five stat rows whether or not there is
anything to put in them — so nothing slides across the page as you move down the
tabs, and nothing walks up it when the pen goes down.

The column starts at the top of the page rather than under the back arrow, which is
the library's rule for the library's reason: it is centred while the arrow is out in
the margin, dozens of pixels away on every page the game is handed, so starting
under it spends that height on nothing — and that height is most of what fits the
character in. Where a page is narrow enough, or a heading long enough, that the two
would actually meet, the column steps down under the arrow, since the arrow is the
one thing here that cannot move.

`GO!` is the exception to the fitting, and deliberately: it is pinned to the foot
of the page rather than fitted under what is above it, as far from the rest as the
sheet allows. It is the one answer that spends the screen, and putting it where
nothing else is is what keeps it from reading as the last row of a list. On a page
narrow enough that the middle of it and the column of tabs in the left margin are
the same corner, the box goes above the column instead — a box with a card lying
across it is not a box you can answer.

**A page held upright is spread rather than centred, and filled the way a page of
a notebook actually is** — the writing at the top, the drawing and the box under
it floating in the middle, `GO!` in the far corner and the cards in the near one.
Centring the sheet as one block is right for a page it very nearly fills: there
the slack is a few pixels, and splitting it between the two ends is what sits the
sheet in the middle of the page rather than at the top of it. A phone held upright
has a hundred pixels of it, and the same sum turns that into two holes — one above
the heading and a second under the drawing — with the writing marooned across the
middle. So a page with that much to spare gets the writing at the top and the
drawing floating in the middle of everything left under it, with whatever the
column carries after the drawing floating along with it: a box that is under the
character has to stay under the character. The heading starts *below* the back
arrow there rather than level with it, which is the one thing the sheet buys with
height it is spending anyway: fifteen pixels of column is most of what fits the
character in on a wide page, and on this one it is fifteen pixels nobody wanted.

And the drawing takes the step up that the space is worth — three times the size he
is played at rather than twice. Two things stop that short of a hero who has eaten
the page. A step up has to **leave as much slack behind as the drawing's own row is
deep**, since a page filled to its edges has not been used so much as run out of;
and he may never come out wider than the widest line of the sheet, which is the
width the middle line was clamped off, so a taller page cannot move the heading
sideways. Between them they leave a 16:9 page exactly where it was — there the
third size fits by six pixels and leaves nothing behind, so twice is what it gets.

One tab per subject, always, with no second column to fall back on, so the only
thing that gives as subjects are added is how tall each tab is — and a tab's
height is not decoration, since the tab is the box: it is how much of the page
answers to that lesson. Seven fit the shortest page the game is ever handed with
room to spare, which is what this shape buys over the grid of cards it replaced —
that ran out of page at seven.

The tabs never give. What gives, in order, is all in the panel: the title and the
lesson's name drop from double to single size, then the character drops from twice
the size he is played at to 1:1, and then he goes altogether with whatever is in
his hand. A lesson you cannot read is worse than a panel with less room than it
wanted, and the panel is the half with somewhere to go. The character is the one
row of it that runs the other way too, up to three and four times the size he is
played at on a page with the height going spare — it is the same ladder read from
the other end, and he is on it at both ends because he is the one row here that can
be made any size at all.

The middle step is there because the hero is the player's own drawing and can be
any height the board allows: a tall one on a short page used to be a hero not shown
at all, and 1:1 is not really a compromise — it is the size he is drawn at
everywhere else in the game. `CUSTOM` cannot go with him — it is a way off this
screen — so when he goes it closes up under the stat rows, on the same gap the rest
of the column is written to, and the sheet loses a drawing rather than growing a
hole where one was.

### What a lesson remembers

Under the lesson's name, four of the six rows: the tool the lesson issues, the
longest run you have had on that page and the course that run was sat at, the most
you have killed on it, and the best mark it has ever come back with. The two
numbers are
as often as not two different runs — the twelve minutes spent hiding behind pen
lines is not the run that cleared four hundred in six — which is exactly why
they are kept apart rather than rolled into a score. A lesson you have never
played says `--` three times rather than `0:00`, `0` and `F`, because a run that
lasted no time and killed nothing is a thing that could have happened — and an `F`
is a mark you were *given*, which is worse than never having sat the lesson.

The mark is the one row in red, and the last, and both of those are the same point.
It is not another thing the run counted; it is what a teacher wrote over the top of
the two rows above it, so it goes under them in the colour a mark is in everywhere
else in the game (see **The mark**). It is also the only row that is worked out
rather than kept: the grade a run gets is a function of how far it got, so the best
mark is that same function asked about the longest run — nothing extra is filed,
and a rung added to the ladder re-marks all seven pages at once. Which is the
answer to why the panel shows a letter it never wrote down: a page you got eight
minutes out of has a `B` on it whether or not anyone recorded one.

The `BEST` row reads `8:31  PHD`, and the course is on that row rather than on one
of its own because it is a label on the clock. Eight and a half minutes means one
thing on a page you sat at high school and another on the page you sat at a
doctorate, so they are one fact and belong on one line.

**It got a row of its own first, and that row cost the character half his size.**
Every row in this block is five pixels and a two-pixel gap, so one more is seven
pixels of column — and seven pixels was the difference between the drawing below
being at twice the size he is played at and being at once, on a 16:9 page and on
most of the others. That is the whole argument for the layout of this screen in one
number: the block is the thing that squeezes the hero, the hero is the part that
gives, and a second *label* is not worth a smaller drawing of who is walking out
there. So the course rides along the row it is about — and the seven pixels went to
the row underneath instead, which is the one row of the block you can change.

It is also the one thing this register keeps that can go *down*, and it is allowed
to because it moves with the clock and only with the clock. Beat your best on the
easiest course in the book and the row says so, in both halves, because the
alternative is a page claiming a doctorate about a run that was nothing of the
kind. That is safe only because nothing is unlocked off it — the library's
collection asks this file for times, kills and bosses, and never for a course.

The register keeps a third number the panel shows only through that letter: the most
bosses one run on that page has put down. It is the second half of what the mark
reads — a win is a mark *awarded* rather than measured — and beyond that nothing on
this screen prints it, because it is what the
library's collection is keyed to (see **The collection**), where the last quest of
the seventeen is having put one down on every page in the book. It is called
`bosses` in the register and `eyes` in the run, which is on purpose: a run may name
what it is fighting because it only ever fights one thing, and the register outlives
seven of them.

They are one of the three things besides your drawings that outlive a run
(`src/records.lua`): one line per subject in a text file in the save directory,
written the way a design is, and a line edited into something unreadable is
skipped rather than trusted — it costs that lesson's record and nothing else. A
record is a **maximum**, which is what lets every way out of a run bank one:
dying, beating the eye and walking out through the pause card are all the same
fact, that this is how far the run got. Winning banks the ten minutes, and
`ENDLESS` carrying on and dying at nineteen banks nineteen over the top of it. A
bad run can never take something away from you. Which is also what lets the
library's collection be keyed to this file and keep none of its own: an unlock read
off a maximum is an unlock nothing can undo.

Every one of the seven pages has something **vertical** on it a page width apart,
and that is one decision rather than seven. Horizontal ruling cannot tell you
that you are walking: the page scrolls under you and every line on it looks
exactly like the line it just replaced, so an infinite sheet of it reads as
standing still. A mark that comes past *once a page* does tell you — the margin
was already doing it on the ruled page, and nothing else had anything. Bar lines
are what a stave has instead of a margin, three per tile so they go by often
enough to count; the squared page's is the grid's own colour but *doubled*, since
squared paper is printed in one ink and what makes a line a margin there is
weight rather than hue; the calendar's is a single blush pixel down the week
boundary, on a line the day grid was drawing anyway; the spreadsheet's is its
filled row-number column, which it was going to have regardless; and the unruled
page has punched holes, which is the only page furniture a page with no ruling
on it is allowed.

The paired ruling on `GRAMMAR` is the same idea turned ninety degrees. An even
field of lines looks identical however far up it you are, so a page of pairs
tells you something a page of singles cannot — and it changes how a stroke comes
out depending on where in the group you start it, which is a milder version of
what the staves do on a page that still reads as ordinary ruled paper.

The page is not decoration, because of the overprint pass: a mark laid over a
printed line comes out a step darker than the same mark on blank paper. Squared
paper darkens a stroke about twice as often as ruled paper does. `FINANCE`'s two header
bands are the only place any page prints a *solid* area of ruling, so they are
a strip where everything you draw comes out heavier — the crossing turned into a
block. `ART` has almost nothing to darken against, so it is very nearly the page
where every mark is exactly the colour its tool says it is — quieter, and harder to judge a
distance across, since the ruling is what you normally read a gap against. The
`almost` is the punch holes, and they are sparse enough that laying a mark
across one is a thing that happens to a run rather than a thing it is played on.
Staves do it in bands: a line drawn across one darkens five times in seventeen
pixels and then not once for the next twenty. None of that had to be written. It
falls out of `src/overprint.lua`, which is why a page is allowed to be nothing
but ruling and is still a different game to look at.

One thing on the page is exempt, and it is the thing you spend the run looking
at. A mark is *printed into* the page and takes the page's colour where it
crosses a rule — that is the whole idea — but a monster is not printed into the
page, it is standing on it, and for a long time the ruling ran straight through
the horde. A blob crossing a stave came out banded. On a page that reinterprets
its crowd the enemies wore the pattern of the paper they were walking on, and the
hero did too. The word for that is tracing paper, and it was the one place the
trick read as a mistake rather than as ink. So a character now blanks its own
silhouette out of the page before drawing itself: the page under a blob is blank
paper whatever is printed there, and the blob comes out in the colours it was
drawn in on every page in the book. It costs the rest of the idea nothing — the
ruling still shows through every mark you make, the shadow under the blob still
darkens over a rule, the puddles and the trails and the pencil lines are all
unchanged — and what it buys is that the crowd reads as being *on* the sheet
instead of in it.

The dials a subject is *allowed* over the horde are deliberately narrow, which is
why leaving them all at rest costs the design nothing. A page that took a monster
away would be the same game with less in it, and the unlock times are what the
whole difficulty ramp is written against — so `crowd` may only multiply the
weight of a kind and `clock` may only scale the difficulty clock. Neither can
make a monster that was not already coming, and neither touches the ten minutes
the boss is on the other end of.

That narrowness is the whole reason there is a *second* axis instead of a wider
first one. A page may shape an arrival and may never price one, because pricing it
is what would stop a record on `MUSIC` being worth comparing to a record on
`MATHS`. What prices one is the course, and a course cannot shape a single
arrival — see below.

The drawing board is reached *from* the timetable rather than the other way
round, and that is not an arrangement of screens: the ruling is what a drawing is
read against, so a hero drawn on one page and played on another is a hero you
sized against the wrong lines. Going through the lesson first is what guarantees
the board is standing on the page the run will be.

They are in no particular order of difficulty, because they are all the same
difficulty. `SCIENCE` is first because first is the default: it is the page the
title screen stands on before anything has been picked, the plain ruling this
game was drawn on, and the pencil every other number in the game is written
against.

`RETRY` on the game over card keeps the page — you are retrying the lesson
rather than picking another one — and quitting to the title screen leaves the book open where
it was, so the title screen is played on the paper you last chose and the
timetable opens on it. It is only ever the timetable that turns the page.

### The course you sit it as

Every other axis this game has is *sideways*. A lesson changes what the page is
ruled with and what is in your hand. A hero changes who walks out there. A perk
changes what a draft may be asked. None of them makes the run harder, and after a
dozen afternoons that is the thing the book has run out of ways to be: you have
beaten the eye on seven pages and the eighth is the same eye.

So there is one dial that is allowed to price the crowd, and it is a **course** —
which class you are sitting the lesson as. `HIGH SCHOOL`, `BACHELOR`, `MASTERS`,
`PHD`. The metaphor is doing real work rather than decorating a number: a harder
difficulty in most games is a modifier you switch on, and a course is something you
*enrol* in, *pay* for, and are afterwards said to have *sat*. All three of those
turned out to be things this book already knew how to do — the canteen sells it, the
purse pays for it, and the register files it against the page.

**High school is not the easy setting. It is the game.** Every number argued for
anywhere else in this document, every measurement the bestiary was tuned by, and
the only course a fresh book has. The three above it are written as multiples of
it, and there are eight of those multiples:

| | bachelor | masters | phd |
| --- | --- | --- | --- |
| how many bodies | 1.2× | 1.4× | 1.65× |
| how much health, flat | 1.25× | 1.6× | 2.1× |
| how fast that gets away from you | 1.08× | 1.16× | 1.25× |
| how fast they walk (before the run's own climb) | 1.04× | 1.08× | 1.12× |
| how fast champions reach their ceiling | 1.25× | 1.6× | 2× |
| how soon the next one is drawn three times the size | 3× | 9× | 60× |
| how soon the next one walks on enraged | — | — | 60× |
| **what the run pays** | **1.4×** | **2×** | **3×** |

Which comes out as a blob — 4 health, the pencil's own number — being 5, 6 and 8
before the ramp has started, and 19, 28 and 40 by the time the eye walks on against
high school's 14. And an eye of 1260 being 2646 at the top. At a fixed rate of
damage a doctorate clears 44% of the bodies high school does in the same ten
minutes.

**The first rung is where the game's most basic sentence stops being true.** Four
health times 1.25 is 5, so a bachelor's pencil no longer kills a blob in one hit.
That is as loud a thing as a first purchase could possibly say, and it is allowed
to say it for exactly two reasons: you chose it, and there is a card in the margin
of the timetable saying which class you are in. Everywhere else in this game an
enemy that stopped dying to one hit without anything on screen saying why would be
a bug.

**What a course does not touch is what a hit costs you.** Every monster's damage is
the number it always was, at every rung. It would have been easy to move — a course
is a step rather than a slope, which is the objection to a continuous damage curve
— and the reason it doesn't is worth being exact about, because a course changes
plenty else a player has learned. What a harder class may take away is *time*: a
blob you could kill in one now takes two, a crowd you could outwalk now nearly
keeps up with you. What it may not take away is the arithmetic you count your own
page of health in. The blob's 6 is a quarter of you in every class in the building,
and a doctorate that quietly made it a third would be a doctorate you die to for a
reason nothing ever said out loud.

The seventh row is the exception that proves that last clause rather than a hole in
it. An enraged monster does hit for half again (see **Fury**), and every word of
the paragraph above survives it, because what it forbids is the word *quietly*: a
doctorate's blob still hits for 6, and the one that hits for 9 is red and black
from head to foot, is one arrival in a hundred, and said its own name the first
time it walked on. What may not be learned is a number that moved behind you.

**One of the seven is a dial the run turns as well.** How fast they walk is a
multiplier on a number that is already climbing — the horde walks towards a speed
eighteen percent over its own and never arrives (see **And eighteen percent in the
legs**) — and a course multiplies that rather than replacing it, so 4% a rung is
4% a rung at every minute of every run. The ceiling that keeps the crowd walking
slower than you belongs to the run's half of that product; on the whole of it,
every class would top out at the same speed and this row would buy you nothing
past the third minute.

**Champions and giants are the two dials that had to be measured rather than
argued.** Both are read once per arrival, and a harder course hands you fewer
arrivals — so a chance doubled against an arrival count halved is a course that
meets no more of them than the easy one, which is exactly what the first attempt at
each of them did. They are answered in two different places now.

A champion is capped at one arrival in seven, and that cap is priced against what a
champion costs the *page* rather than against how often it is interesting: the mark
is the body drawn double, so a seventh of the horde at four times the paper is
already most of what a page can carry. A course is not allowed to buy its way past
that — a harder book may be harder and may not be a book made of double bodies. So
what it buys instead is *reaching* the cap sooner: a doctorate is at one in seven
by minute seven and a half where high school gets there around minute eleven, which
over a whole cycle is a champion in every 40 arrivals against high school's one in
59. Half again as many, and nothing extra in an endless run's later cycles — which
is the right shape for it, since every course is sitting on the cap by then.

A giant is an **event**, a handful in a whole run, so the unit is how many you
meet, and that is what the last-but-one row of the table is tuned against: 1.24,
1.48 and 1.62 times as many per cycle. The 60 looks absurd beside the 2.1 above it
and is not — a giant is *overdue* rather than rolled for, and how far apart they
are goes as the square root of how fast that overdueness climbs, so four times the
dial is twice as often and the falling arrival count then takes most of it back.
Past about there the ceiling on the idea answers instead of the dial and a bigger
number buys nothing, which is the same restraint the champions are under reached
from the other end.

**The seventh row is not a dial at all. It is a door.** Fury is the one thing a
doctorate has that the classes below it do not have a slower version of, so its
row is a dash three times and then the giant's own number — the giant's, because
what fury was priced at is a giant's *rarity*, and that inherits the whole
argument above, square root and falling arrival count included. Measured, it comes
out at one arrival in a hundred and ten against the giant's one in a hundred —
which is the same cadence, and is meant to be. A dash is
a zero, and a zero works because fury is metered exactly as a giant is: a meter
that never climbs is a chance that never comes up, so there is no rung named
anywhere in the spawner and no second question asked at a spawn. The day it is
worth meeting one before a doctorate, this row grows a number and nothing else
changes.

**The xp is deliberately identical at every rung.** A monster is worth what it
costs to kill, so a horde that takes twice as long to clear pays twice as much per
body — which means a doctorate reaches the same level and sees the same number of
drafts as high school in the same ten minutes. A course changes how hard a run is
and not how much of the catalogue it gets to see, and that is the right way round:
the ladder is a harder version of this game, not a longer one.

**It is bought rather than earned**, and that is the one decision here worth being
firm about. Everything the library's collection opens is opened by *playing* — a
lesson by the lesson above it, a line by a milestone. A harder book cannot work
that way, because the milestone it would have to ask for is "beat the game", and a
player who has beaten the game and is told to beat it again before the book will
get harder has been told the wrong thing. So the ladder is a row on the canteen
counter beside the rerolls and the heroes: 15, 40 and 90 coins, one rung at a time,
and the counter's `REFUND` hands it all back like anything else there. A won run at
high school pays about 26 coins, so a first rung is half an afternoon and a
doctorate is a fortnight — and every rung pays for the next one faster than the
last did, which is what the payout column is for. That column is also the whole
answer to *why enrol*: a doctorate is not a badge, it is where the coins are.

It is one row with three levels rather than three rows with one, because a course
ladder is a ladder. Buying a master's before a bachelor's is not a thing this book
should have to have an opinion about, and a line whose level *is* how far up you
are cannot express it.

**Picking it is the last row of that block.** `COURSE` in the column the labels
are in and `<` the course `>` in the column the figures are in, right-aligned like
every number above it and sitting directly above the drawing of the character. The
word is in ink because in that block ink is what a value is written in and slate is
what a label is — the five rows above it say so — and the two chevrons are bare
three-pixel glyphs rather than the boxes the library's footer arrows sit in, which
is what makes the whole control 57 pixels and lets it fit inside the value column
the clock row had already reserved. What you press is still a square the size of the
back arrow's box: the target is a corner of the sheet and the drawing is a glyph,
and they are allowed to be different sizes. The word between them is not pressable
— everywhere else on this screen a label presses the thing it names, but this label
says which of four the setting is on, and a press on it could only mean one of the
two arrows. `left` and `right` step it on a keyboard, matching the library's own
footer.

**Where it went took three goes, and the two versions it is not are worth
describing.** It was a column of four short cards down the left margin first, high
school at the top, in the lesson tabs' own palette — the picked one red and stuck
out into the page, an unbought rung in graphite — which showed you the whole ladder
at once, locked rungs and all. That is genuinely more than a stepper says. It also
cost fifty pixels of left margin, and on any page narrower than a desktop one those
fifty are fifty the *sheet* then has to be walked out of, which comes out of the one
part of the sheet that gives: the drawing of the hero. Then it was a stepper in that
margin, under the back arrow, which cost the sheet nothing at all but sat with the
furniture, a page-width away from the thing it is about. It is a row of the block
now because that is what it is: everything in that column is what this run would
be, and which class you are sitting it as is exactly that.

What a stepper cannot show you is the rungs you have not bought, so the `>` says it
instead: slate where there is a rung to step onto, **red** where the ladder goes on
but has not been paid for, and graphite at the top of it where there is nothing
further. Red because that is how the rest of this book writes a thing you have to go
and do something about — the same red the timetable writes *why a lesson will not
open yet* in. A book that has bought nothing shows a graphite `<` and a red `>`,
which is the whole of what tells you the ladder exists.

**Both end cards print it**, in slate under the clock and the body count: `SAT AT
MASTERS`. That is a labelled line rather than the timetable's bare word, because
there is no clock beside it for the course to be a label *on* — the card has room
and the panel did not. Always, including at high school — a card that only named the course when
it was above the easy one would make the plain run the run with something missing
from it, and a player who has never bought a rung would never once be shown the row
that says the ladder is there.

## The library

The `LIBRARY` tab in the bottom-left corner of the timetable opens the catalogue:
every tool, every passive weapon and every passive line the draft can ever offer,
with all of its levels written out in the order they are taken — and, for the three
quarters of them the book has not opened yet, what each is asking for instead (see
**The collection**).

It exists because of an asymmetry the rest of the game is built on and never
addressed. A run is a hundred and fifty-nine levels deep and a draft shows you
three cards at a time, so everything you never happened to be dealt is
information the game simply withholds — you cannot decide whether the pushpin is
worth one of your four tool slots if you have never seen what its four levels do,
and you cannot decide it in the two seconds a card is on the page either. The
library is the back of the book, read before the lesson starts, and it costs the
run nothing: it hangs off the side of the timetable exactly the way the drawing
board does, so it is a detour rather than a toll gate.

**It is the one screen in the game with no box on it.** Everything else asks you
something and makes you draw the answer; this asks nothing, so there is nothing
here to scribble. You press a name to read it, you press an arrow to turn to
another shelf, you press the corner to close it, and ink that lands anywhere else
is ink on a page and fades off it like any other. That is the timetable's tab rule
— choosing what to *look* at is not a question — applied to a screen where looking
is the whole of it.

**And it is a spread rather than a page.** There is a crease down the middle and
two facing leaves: the index on the left one and the entry it opens on the right,
which is what a reference book has always done with exactly this pair of things.
Before the fold they were stacked — the shelf across the top and the entry under
it — and stacked is still what a phone held upright gets, because half of a
180-pixel page is not a page of anything. On anything wider the two stop competing
for the same vertical room, and the entry gets the whole height of a leaf to be as
long as it is. See **Turning the page** below for what the crease is really for.

Four blocks across the spread:

**The shelf** is the index, on the left-hand page: every line of the shelf you are
on, its icon and its name, in as many columns as the leaf will take — two on a 16:9
desktop window, one at the narrowest — bar the forty-five fusions,
which are behind the toggle below. Press one and the block
under it turns over to that entry. The name you are reading is the one in red,
which is what red means everywhere else in this game's furniture, and it is all it
has to mean here because the entry underneath says the same thing at twice the
size.

**And it is written in the order the book gets the lines.** The ones a fresh save
already has come first, and then the rest in the order the ladder opens them — one
list saying both when a line arrives and where it is shelved, so the two can never
disagree. So the top of a shelf is what a run can be dealt today and everything
under it is the queue, in the order the queue moves. Before this it was catalogue
order, which is the order the lines happened to be *written*: a fresh book's weapons
shelf had its four playable lines sitting second, fourth, sixth and eighth in a
column of graphite, and there was no reading of the page that told you which four
they were except going along squinting at the colour.

The order is fixed. It is worked out from the catalogue — has this line a gate, and
where does that gate sit — and not from what you happen to have opened, so it is the
same on run one and run four hundred. A shelf that sorted the open ones to the top
would rearrange itself under the finger of the player who just opened something,
which is the one moment they are most likely to be looking at it, and it would undo
the whole reason this page is laid out from the top down. What you learn the shape
of is what stays.

**The entry** is the line in full, on the right-hand page: its icon and name, then
one numbered row per level. The numbering is the point rather than decoration on it. A draft card tells
you what a single level does; what a *line* is is the shape of all of them, and the
only way to read that is to see the fourth level sitting under the three you would
have to take to get to it. `1` on a tool line is always the unlock — the level that
hands you the tool and spends one of four permanent slots — so the whole of what
that slot buys is on one screen before you spend it.

**The footer** is `<` `TOOLS` `>` at the foot of the page: the arrows either side of
the name of the thing they step, which is the studio's character selector doing the
same job in the same box. Tools, then what fights for you, then the numbers about
you — the order the catalogue itself is written in. On a keyboard the left and right
arrows step the shelf and up and down walk it, `E` throws the toggle, `RETURN` picks
the name you are on while it is up, and `BACKSPACE` is the corner button.

**The toggle** is the word `EVOLUTIONS` in the bottom-left corner, and it is the one
thing on the page that changes what the page *is* rather than which part of it you
are reading. Down, the fusions are not on the tool shelf at all. Up, the shelf stops
being an index and becomes a pair of picks: press two tools and the block underneath
is what those two make of each other. It is drawn only on a shelf that has
evolutions on it, which today is the tool shelf and only ever will be a shelf whose
lines can fuse — a word offering nothing is worse than no word. See
**Evolutions**.

**The page is read from the top down rather than centred**, and that is the layout
decision worth stating. The heading is in the top row, level with the back arrow
— it can be, because the title is centred on the page while the arrow is out in the
margin, so on any page the game is handed they are dozens of pixels apart — then
the shelf, then the entry, and whatever is left over is blank page above the footer,
which is what blank page looks like. It is given more room off the top edge than
anything else on the page is given off any edge: a title has nothing above it, and
without that room it reads as a line that ran out of page rather than as the top of
one.

Centring it was worse for two separate reasons. Everything on this screen is a list
whose length the catalogue decides, so there is no block to centre that is the same
height twice, and a page that recentred itself would move the heading and every name
on the shelf each time you pressed an arrow. And centring costs room: the reserve
has to be the worst of two shelves that pull opposite ways — the passives are the
fullest list with the shortest entries, fourteen lines of four levels, and the
weapons the shorter list with the tallest, twelve lines of which ten are five
levels long, carrying the two wordiest
strings in the game — and on a squarish window that reserve was the difference
between the last level of a line being on the page and being cut off it. Read from
the top, none of it applies. Column width is still the widest name in the whole
book and the footer arrows are still struck off the widest shelf name, so nothing
across the page moves as you step through it either.

**The shelf is given the room the fullest shelf needs, not the room the one showing
needs**, which is that same rule turned down the page. Tools, weapons and passives
are three lists of three lengths, so a shelf measured to itself is a different
number of rows tall on each one — and the entry underneath, its icon and its name at
twice the size and every level under that, would start in a different place on each
one. Pressing an arrow to compare two lines would move the thing you were comparing.
Reserving the tallest costs the emptiest shelf a row or two of blank page, which is
the cheaper of the two: blank page is what blank page looks like, and a heading you
have to find again is not.

The endless lines are deliberately not a fourth shelf. They are nine variations on
lines that already have one, they only turn up once the catalogue has dried up, and
a page of them would be a page repeating the passives shelf with no last level on
it. That they exist at all is the draft's news to break, and it breaks it at the
moment it matters.

And it is written on the page rather than laid over it, like the timetable and the
drawing board: the ruling shows through the lettering, and the ruling is the lesson
you opened it from. The book is still open there — you have turned to the back, not
closed it.

### Turning the page

The library, the homework page and the canteen all step a short list of sections
with `<` name `>` at the foot of the page, and for a long time that step was a
*cut*: one shelf on one frame and another on the next. Which is the right furniture
for a list and the wrong furniture for a book, and all three of these are books —
they are read off the back of the same notebook the run is played on, they are
stepped in a fixed order, and the one gesture a phone has for "the next of these" is
the one your hand already makes over a page.

So there is a crease down the middle, two leaves either side of it, and **you turn
the page with your finger.** Drag sideways and the leaf lifts off the fold, bends,
carries across and lays itself down on the other side — with the section you were
reading printed on the front of it and the one you are going to on the back, which
is what a leaf of a book actually is. Let go past halfway and it finishes the turn;
let go short of it and it falls back where it came from. The arrows still work, and
so do `←` and `→`; they now play the same turn rather than cutting.

**The whole of it is one arc.** The sheet stands at an angle, bows a little over its
length, and every column of it is drawn one whole pixel wide at a whole pixel
position — where that column *lands* is the only thing the bend changes. There is no
rotation anywhere and nothing is sampled at an angle, because that would break the
one rule the rest of this game is drawn under. The paper turning away from you
catches less light, and less light in an eight-colour palette with no alpha is a
step down the same ramp an ink mark takes when it crosses a ruled line — dithered
between steps with a 4x4 comb, because there is no colour between paper and
graphite and there never will be. Quantised to flat bands instead, a bending page
came out as three grey slabs with straight edges, and straight edges are the one
thing a curve must not have.

**The fold decides where the drag starts, and the drag decides what it costs.**
Every one of these pages can be drawn on, so a finger coming down has to be read as
either a line or a page turn, and the reading has to be over in the first few
pixels or the page stops answering the pen. Land within twenty pixels of the outer
edge of a leaf and it is a turn on the frame it lands — that is where a hand reaches
for a page, and it is the one strip of these screens with nothing printed on it.
Land anywhere else and it has five pixels or a tenth of a second to prove itself:
sideways and it is a turn, anything else and it is a line, and the pen catches up.
The bias is towards the line on purpose. A page turn is a fast gesture and a drawn
line usually is not, so the two sort themselves; and where they do not, there are
still two arrows and two page edges that will turn it.

**A leaf keeps its margins, and the writing gives way instead.** This is the one
thing the fold cost something real. A page has room round the writing on every
other screen in this game, and halving the page was an invitation for three of
them to quietly take it back and print to the edge of the paper — which reads as a
page that did not fit rather than as a page. So the margin is the book's rather
than any screen's, and the rule the other way is that **a row may have as many
lines as it likes.** The homework page, whose rows were a name, a demand and a
figure laid across, now stacks all three; the canteen puts what you own and what
it costs on a second line under the name, which costs nothing at all down the page
because the box at the end of a row was already deeper than two lines of lettering.
On a phone held upright, where a page is a page, both go back to lying flat.

**And a leaf that has no room is not a leaf.** A phone held upright gives the page
about a hundred and eighty pixels across, and half of that is not a page of
anything — so under a threshold the crease goes, the two halves stack the way they
always did, and the same drag lifts the whole page away to show the next one
underneath. Half a turn rather than a whole one, because with one leaf showing
there is no back of the sheet to land on: what is under it is already where you are
going.

### Evolutions

The forty-five fusions are in the library from the first run and they are not on the
shelf. `EVOLUTIONS` in the bottom-left corner is where they are, and the reason is
that a fusion is not a line you can be dealt.

The tool shelf is the index of what a draft deals. Fifty-five names on it — ten
tools and forty-five fusions, one icon and one name apiece, laid out in the same
grid at the same size — says that a run can ask for any of the fifty-five, and
forty-five of them it can never ask for at all: a fusion is what two *finished* lines turn into,
ten levels and two permanent slots into a run. There are more fusions now than there
are tools to make them out of, so on the shelf they would be most of the page. The
shelf was quietly making the same promise about a thing you draft and a thing you
arrive at.

Thrown, the shelf keeps the ten tools and stops being an index. Press two of them
and the block under the shelf is the fusion those two make, written out by exactly
the same entry a tool gets — its icon, its name at twice the size, its four
numbered levels — or a graphite line saying **NOTHING COMES OF THESE TWO** if
nobody has drawn that pair yet. Press one and it says **PICK TWO TOOLS**.

Which is the one question the rest of the book cannot answer. Every other page here
is about a line; this is about *two* of them, and there is nowhere on a page of
single entries to ask it. It is also the shape of the answer a player actually
wants: not "what is the LASSO", which is a name they have no reason to know, but
"I have the pencil and the compass — is there anything in that".

**The picks are marked on the icons, in blush.** Not in the red the shelf already
spends on the name you are reading — two colours, one meaning each: red is where
you are, blush is a tool going *into* a fusion. And blush already meant that. It is
the fill of the one card in the draft that offers a fusion, and the plate a fused
tool's icon wears everywhere in the game afterwards (see **Fusing two lines**), so
a picked pencil going pink is the same colour saying the same thing one step
earlier.

Small decisions worth writing down. A third press replaces the *second* pick and
not the first, because every fusion in the book has either the compass or the
pushpin in it: what a player does with this screen is hold one of those still and
run down the shelf against it, which is one press per pair instead of two. Pressing a name already picked takes it
back off, which is the only way to move the first one. The toggle goes back down
when you turn to another shelf — the mode belongs to the shelf it was thrown on,
and the other two have nothing to pair. And the count in the top-right corner still
counts the fusions, though no shelf carries them: what it counts is the book, and a
fusion is a page of it — a collection that appeared to shrink by every fusion in
the game because a screen was rearranged would be lying about the save, and would
go on quietly shrinking every time one was added.

It says nothing about *why* two tools make nothing, and that is deliberate. The only
honest answer is that nobody has drawn that one yet, and a book that explained
itself there would be a book making promises about a page that does not exist.

### The collection

Nine lines of eighty-one are in the book on a fresh save.

Everything else is held back, and the library is the screen that says which and what
it costs. A line the book has not opened is drawn as the hole it is — its icon as a
silhouette, its name in graphite — and where its levels would have been read there
are two lines instead: why there is nothing to read, in graphite, and what to go and
do about it, in red. The count — `9/36` on a fresh save — hangs in the top right
corner at 1:1, level with the back arrow, the canteen's purse readout in the
canteen's corner and for the canteen's reason: how much of the book there is is a
fact about the book rather than part of the page, so it does not move as you step a
shelf, and it goes red the day there is nothing left to find. It counts what the
screen is showing — the thirty-six on the shelves, or the forty-five fusions behind
the toggle — because the two fill at completely different rates, and added together
they were a number that said nothing about either.

Which is the difference between a catalogue and a collection. The library was
written because a draft of three cards withholds everything it did not happen to
deal you; a library with holes in it is the same page answering the next question
along — not *what is there* but *what is there that you have not got to yet*.

**The name is deliberately not hidden.** A shelf of question marks is a wall, and
what makes a hole worth filling is knowing the shape of it: the whole book is
legible from the first run, and the only thing a lock takes away is the reading of
what each level does.

#### What a fresh book is handed

Four weapons, five passives, and the tool the lesson puts in your hand.

| free from the first frame | |
| --- | --- |
| **SWORD** | an arc through what is close |
| **BOMB** | drops at your feet and blows up what is still there |
| **ROCKET** | two, in directions nobody picked |
| **COOL S** | a line through where you stand |
| **SHARPENER** | +20% damage from what you draw |
| **GRAPHITE** | +20% damage from what fights for you |
| **INKWELL** | +30 ink |
| **FRESH PAGE** | +20 health |
| **MAGNET** | XP from further off |

Four weapons is a third of twelve and five passives is a third of fourteen, which is
the floor. What makes it the *right* nine is the two things underneath it.

**Four different shapes, so taking all four is itself the lesson.** Swing at what is
close, drop where you are, fire outward at nobody, cut a line through where you
stand — a first run that ends up holding every weapon in the book has still been
taught four different ways to answer a crowd. And all four carry a drawing board, so
the studio — the strangest thing this game does — opens on run one instead of at
minute two. The COOL S is in there for a reason beyond its shape: it is the single
most recognisable thing anyone has ever drawn in a school notebook, and a game that
saves it for a 100% most players never see is a game that has hidden its own face.

**One passive per family, so no build starts empty.** The ink side gets the
sharpener, the ally side the graphite, the ink economy the inkwell, and staying
alive gets the page — with the magnet over the whole loop.

Two numbers keep the set honest. It is **45 levels** against the 28 to 35 a
ten-minute run reaches, so a first run can absorb most of it and max none of it. And
the passive strip caps at five, which the free set fills exactly — so the first real
*decision* in the game, the first time you have to leave something on the table,
happens on the first run, the moment the paper plane lands at three minutes.

#### Seventeen quests, one line each

Everything else is keyed to something the book already remembers, and it comes in
five parts. The first is the ladder of quests, and it is what the library's shelves
are written in the order of.

| what the book asks for | what it opens |
| --- | --- |
| Last 1:30 in one run | the pen |
| 300 kills in one lesson | the gluestick |
| Last 3:00 in one run | the paper plane |
| 1,000 kills in one lesson | top marks |
| Last 5:00 in one run | sellotape |
| Last 7:30 in one run | the sun |
| 2,500 kills in one lesson | the blotter |
| Last 9:00 in one run | the cartridge |
| Sit a lesson to the end | the metronome |
| Sit 2 lessons to the end | the laser beam |
| 4,000 kills in one lesson | the spirals |
| Sit 4 lessons to the end | the fixative |
| Sit 6 lessons to the end | the m birds |
| Sit every lesson to the end | the laminate |
| Beat a lesson | the scissors |
| Beat 3 lessons | the bandaid |
| Beat every lesson | the storm |

Five things about that table are decisions rather than arrangement.

**One feat, one line.** It used to be ten quests of two — a weapon and a passive
together, so that every unlock changed two shelves at once — and the two halves were
welded: a player who wanted the pen was told to survive two minutes and handed a
bomb as well, and neither half could be re-priced or retired without moving the
other. Seventeen rows of one say the same thing at the same rate, and each of them
can be moved on its own. It is also what makes a shelf readable: one hole, one
price, one thing behind it.

**The four things it can ask for pull in different directions.** The longest run
anywhere asks you to last. The biggest body count on one page asks you to fight —
and quietly asks *where*, because some pages hand you four kills a second and some
ten, so a big number is a page you went and found. How many lessons you have sat all
the way through asks you to go round the book rather than get better at one page of
it. And how many you have *beaten* asks you to win, in more than one place. The
ladder alternates between them: three time quests in a row would be one quest with
three prices on it.

**Nothing on it can be got by accident.** Opening every page in the book costs a
seven-minute run at the deepest rung, so the last two time quests are priced above
that — 7:30 and 9:00 — and every count is priced past what walking the term hands
you. Before this was re-cut, six runs of nothing over seven minutes, with no boss
ever reached, cleared **eight of the ten milestones** and read sixty-seven of
eighty-one lines open. The same six runs now clear five of seventeen and read
fifteen. A reward you cannot miss is not a reward.

**Only three of them ask about a boss, and that is a ceiling.** The eye is
provisional — one fight standing in for seven, six of which nobody has drawn yet —
so a ladder leaning on it is a ladder nobody can balance. *Sitting* a lesson is the
half of the same question that does not care what walks on at minute ten, and it
carries five quests to beating's three. Sit all seven and beat none and you are
still holding twenty-nine of the thirty-six shelved lines and thirty-six of the
forty-five fusions, which is what keeps the game tunable while six bosses are
missing.

**The first two land inside the first run.** A collection has to be seen filling
before it is worth filling, so ninety seconds and three hundred kills are things a
first afternoon does by accident — and the last of the seventeen is the whole book
beaten, which is the only thing in this game that deserves to be called finished.

#### Every lesson keeps its own tool

The other half is the seven tools the lessons hand out, and it is a different kind
of lock: not on *having* the thing, but on **carrying it anywhere else**.

A lesson still opens holding its tool whatever the book has opened — being handed a
line does not go through the collection at all — so the pencil is a science tool.
You draw with it on that page as much as you like, the draft will not deal it to you
on any other page, and the library says which page it belongs to rather than
pretending the thing does not exist. **Sit the whole of that lesson** — ten minutes,
which is when the boss walks on — and it is yours everywhere.

*Sitting* and *beating* are two different words everywhere in this book, and this is
the one that matters most. To sit a lesson is to still be on the page at minute ten;
to beat it is to put down what walks on. The tool is behind the first and not the
second, deliberately: six of the seven bosses have not been drawn yet, and hanging
seven tools and the whole fusion shelf off fights that do not exist is not a ladder
anybody could balance. When they are real, moving the tool behind beating its own
lesson is the obvious next thing — it is the cleanest possible reading of "each
lesson has its own exam" — and it is a one-word change here.

Which is the fiction the whole book is built on doing something at last: a lesson
teaches one tool, and what passing it earns you is the right to take that tool to
the rest of the timetable. It also gives the seven pages a reason to be played in
their own right rather than as seven ways of shuffling the same catalogue: the
compass is behind maths and nothing else, so a run on maths is how you get one.

| lesson | its tool |
| --- | --- |
| Science | the pencil |
| PE | the stapler |
| Grammar | the highlighter |
| Finance | the ruler |
| Music | the pushpin |
| Maths | the compass |
| Art | the rubber |

That is the order of the term as well as the order of the table (see
[The term](#the-term)), which is what makes the column read as a course: the two
plainest tools are the two you are handed first, and the compass and the rubber
are behind six lessons because they are the two that do something nothing else on
the strip does.

Those seven are not written down anywhere — they are read off the timetable, so a
lesson gates the tool it issues and a new lesson gates its own with nothing to keep
in step. It quietly enforces the one rule about lessons that nothing else checked,
too: two lessons issuing the same tool now fails at load, because a line may only be
gated once.

The three tools no lesson issues — the pen, the gluestick and the scissors — have
no lesson to be the local tool of, so they sit on the quest ladder with the
weapons.

#### And every hero keeps his own weapon

The third part is the same bargain with the roster in place of the timetable. The
book comes with one hero and the other three are bought at the canteen (see
**Which character**), which is what makes the weapons they carry lockable at all: a
lock on a line *every* run is handed locks nothing, and a lock on a line only some
runs are handed is a lock on carrying it as anybody else.

So a bought hero opens holding his weapon from the first frame he is played, and the
draft will not deal that line to anybody else until **five minutes have been
survived as him** — half a lesson rather than the whole of one, because a page is a
thing you sit through and a hero is a thing you play: five minutes in is where how a
run opened has stopped being most of what it is, which is the moment the opening is
worth handing on. Until then the library says whose it is, and says which of the two
things is still owed — buy that hero, or last with him.

| its weapon | whose it is |
| --- | --- |
| the sword | the swordsman, and everybody's from the start |
| the shot | the shootman |
| the stars | the starman |
| the skate | the skateman |

Those three are read off the roster rather than written down, exactly as the seven
tools are read off the timetable — a hero gates the weapon he carries, so a fourth
hero to buy brings his own lock with him. The swordsman's is the one weapon in the
game gated by nothing at all, and it cannot be otherwise: every book has him from the
first frame, so his sword is what a fresh book's first draft has to deal.

**What that makes a first run** is the nine free lines and the tool the lesson
handed over — ten lines and forty-five levels, against the twenty-eight to
thirty-five a ten-minute run reaches. So a first run can take most of the book it
has and finish none of it, and the drawing half of the game is one tool until you
have earned a second, which is what makes the second one an event.

#### The term

And the fifth thing the collection holds back is not a line at all. It is the
timetable.

Seven lessons a fresh book could sit in any order were seven doors with the same
nothing written on them. The page and the tool are the widest choice in the game —
they decide what every mark comes out as and what the marks *are* — and the first
run had to make it having never seen a page or held a tool. So the book opens one
page at a time, in the order the tabs are in, and each lesson asks for a minute
more of the lesson above it than the one before did:

| lesson | what opens it |
| --- | --- |
| Science | open, always — it is what a fresh book has |
| P.E. | survive 2 minutes on Science |
| Grammar | survive 3 minutes on P.E. |
| Finance | survive 4 minutes on Grammar |
| Music | survive 5 minutes on Finance |
| Maths | survive 6 minutes on Music |
| Art | survive 7 minutes on Maths |

**A minute a rung, rather than one bar for all six**, because the ladder is also
the difficulty curve the game does not otherwise have: the front of the book is a
page you are handed and the back of it is a page you are good enough for. And the
last rung stops three minutes short of a sitting, so that *opening* the deepest page
and *sitting it out* stay two different afternoons.

Which makes it the lesson tools' lock read from the other end, and the two are one
ladder rather than two. A tool is freed by sitting the whole of its own page; a
page is opened by sitting some of the page before it. The run that opens Maths is
the run that is most of the way to owning the pushpin everywhere, and the seven
pages stop being seven ways of shuffling the same catalogue: they are a course,
and you are somewhere in it.

Nothing about it is written down either. The rung a lesson sits on is its place in
`Subjects.list` — so the tabs, the order of the term and the ladder are one list,
a new lesson brings its own rung, and a chain read off an order cannot be written
into a circle the way a chain written out can. It is also why the list is now in
the order it is in: Science, P.E., Grammar, Finance, Music, Maths, Art is the
plainest page and the plainest tool first and the three pages that look least like
paper you write on last. Ten pages is as far as the arithmetic goes, since the
tenth rung would be a whole lesson.

And it is what retired an axis. The quest ladder used to ask `PLAY N LESSONS`, and
that stopped meaning anything the day the timetable went behind a ladder of its own:
a lesson you have played is a lesson you unlocked by playing the one above it, so
`PLAY 3 LESSONS` became a demand nobody could miss. Being round the book is what the
term is for now; what the quests ask instead is how far *into* the pages you got,
which the term cannot hand you.

One thing it costs, and it is a kindness. A book that had already been round the
timetable before there was a term keeps every page it has written on: an unlock read
off a maximum is never taken away, and that promise is older than this ladder.

The draft finds out in exactly one place (`Loadout:candidates`), beside the ban
`EXPEL` leaves and for the same reason: what the draft may reach is one list and
one question rather than something every deal has to remember. And a line the run
is already carrying is offered its levels whatever the collection says, exactly as
it is offered them whatever the slots say — nothing a run is holding is ever taken
off it.

#### And the fusions are behind their own parts

The fourth part is the forty-five fusions, and until now not one of them was held
back by anything — so a fresh book's library read fifty-one lines of eighty-one open
while the draft could reach nine. That was the counter lying rather than the ladder
being generous: a fusion has never been dealable without both its tools finished on
the strip, so what was missing was the book *saying* so.

A fusion is in the book when everything it is made of is — both tools and the
catalyst passive it does not consume, since a book with the pen and the pushpin but
no cartridge cannot reach what they make. Read off the fusion's own `needs`, so a new
one brings its own lock and there is no second list to keep in step, and the shelf
names the pair rather than pretending the thing is missing: *made of pen and pushpin*
over *open the pen first*.

What it changes is what the book says, not what a run can hold. There is one
exemption in the draft and it is there for one case: a lesson *hands* you its tool
long before the book has opened it, so the pencil crossed with the pen is buildable
on a Science page while the collection still calls the pencil shut. The shelf is
answering what could ever be built; the draft is answering what can be taken now.

It also turns the tool ladder into the engine of the whole late game. Fusions are
every pair of the ten tools, so what a new tool is worth is not one line but every
line it can pair with: your fourth tool brings six fusions, your eighth brings
twenty-eight, and the tenth brings all forty-five. A flat price — ten minutes on a
page — with a payoff that accelerates on its own is exactly the shape the middle of
this game was missing.

It is all one file, `src/collection.lua`. Two of the doors it was built for are open
now and both went in exactly where they were meant to — the canteen sells a hero and
the hero's weapon is another kind of quest answered in the same function; the fusions
are a third. Whatever the next door is, it goes in the same way — the homework page
is deliberately not one of them, and [Homework and the
canteen](#homework-and-the-canteen) says why.

## Homework and the canteen

The two tabs above `LIBRARY` open the two parts of the book that are not lessons.
The left margin of the timetable is where the book keeps everything that is not
one, and a school notebook with a reference section and nothing else would be
missing the two halves of a school day that are not lessons — what you take home
and where you eat.

**Homework** is the list of things the book asks you to go and do. It was a heading
and a line saying there was nothing there for as long as that was true, and it moved
out of `src/blank.lua` the moment it wasn't — the canteen's own path, and the rule
that module exists to hold: a page with nothing on it is one module with a heading,
and a page with anything of its own is its own module. `blank.lua` is still there,
and nothing instances it; it is what the next tab that opens onto nothing costs.

**It began as the library said twice, and it isn't any more.** For a while the page
was the seventeen quests with a meter against each — the one thing the shelf could
not print, `3966/4000`, because a hole in the catalogue is open or shut and there is
no honest way to draw four fifths of one. That was a whole screen existing to carry
one column, and the column has moved: it hangs under the demand in the library, in
slate, on the line below the red. A hole, its price, and how much of the price you
have paid read as one paragraph, and the middle of those three means very little
without the last.

**What is here instead is the half the register could never ask for.** Everything
the book remembers about a lesson is a *maximum* — the longest run, the biggest body
count — so a quest can only ever ask you to have had a better afternoon. Four
thousand kills on one page. Nine minutes in one sitting. Nothing in that register
adds up, and the things worth asking a player for after their fiftieth run all do:
fifty thousand blobs is four hundred afternoons and no single one of them, and the
whole timetable beaten at a doctorate is seven wins nobody had in an evening. So the
book now keeps a second kind of memory beside the first — a tally rather than a
record — and this page is what it is for.

**Nothing here unlocks anything, and it never will.** That is the one rule worth
arguing for, because it is the tempting thing to do and it would quietly break
something. Every reward in this game is already a door with a screen behind it: a
line in the catalogue, a page on the timetable, a hero at the counter. A challenge
that handed one over would be a second ladder pointing at the same doors, and the
first thing it would cost is the library's promise that a shelf is the whole of
what there is to open. So a challenge pays in the only currency a checklist has:
the box goes red. It is the part of the book that is about the player rather than
about the game, and it has to be allowed to be exactly that.

**A row is a name, a row of little boxes, a demand and a figure.** Most challenges
come in threes — five hundred blobs, five thousand, fifty thousand — and three rows
saying BLOB with different numbers on them would be a list nobody can run their eye
down. So it is one row with three boxes, and each fills red as its rung falls. The
row shows the lowest rung still standing and how close you are to it, because what
a list like this is for is being nearly finished with something.

The bestiary's three numbers are the same ladder divided by what the monster is
worth, which is why a grin asks for sixty and a blob for five hundred. Every row
then says the same *sentence* — go and kill a great many of these — instead of the
same number, and fifty thousand of the slowest thing in the game is not a demand
anybody would ever have written on purpose.

**Four sections, one to a spread** (see **Turning the page**), because this list is
going to keep growing and a page is a page. On two leaves the ten rows are split
down the crease, five and five — down the middle rather than filled to the foot of
the left page and spilled, because five and five reads as a spread and nine and one
reads as a page that ran out — and a finger drag turns to the next section. On a
phone held upright they go back in a column exactly as they were.

A row on a spread stacks: the name, the demand under it, and how far along you are
under that. Laid flat it is wider than half a page, and the page keeps its margin
rather than the row keeping its line (see **Turning the page**). It is also the
library's own shape for the same three things — a demand, and what has been paid
off it on the line below with nothing between them, because there the two are one
sentence. `BESTIARY` is one body count per monster —
per monster and not one figure over the lot, because a single ALL KILLS challenge
is one demand with ten prices and a run would learn to farm whichever page pays
fastest. `TERM` is the bosses, the hours, and one row per rung of the course ladder
asking for the whole timetable beaten at that class or harder. `COLLECTION` is the
catalogue as four sets rather than eighty-one lines — the tools, the weapons, the
passives, and the drawings that are in your own handwriting rather than the book's,
which is the only challenge here you can finish without playing. `EVOLUTIONS` is
one row per tool, asking for every fusion built on it.

Every one of those is *derived*. A new monster brings its own row and prices its
own three rungs; so does a new lesson, a new course, a new tool, a new fusion and a
new drawing board. That is not tidiness for its own sake — homework out of step
with the game would be the book asking for something that does not exist.

**The box is the tick.** Every other screen in this game answers a question by
having a hand-drawn box scribbled in, so a row here is an exercise with boxes
beside it and a fallen rung is a box filled — drawn rather than scribbled, because
nothing on this page is answered by standing on it. A box is five pixels, the
height of the lettering beside it, so a row is one line and not one line and a
picture.

The colours are the library's, meaning the same two things. What you have finished
is ink, what you have not is graphite, and the red is on the demand — the one thing
on the page that is the book asking you for something. It is not written at all
once a row is finished, because then there is nothing being asked.

**The canteen** was the other instance of that module until it had something to
say, and what it grew first was the purse — laid out as *furniture* rather than as
the page: the amount you have hangs small in the top right corner, the back
arrow's own margin mirrored to the other end of the same edge and level with it.
What you have is a readout and belongs in a corner with the other things you press
and read; what there is to spend it on is the page. Standing the figure large in
the middle was tried first and it said the wrong thing — a number alone in the
centre of a page reads as the point of the page, and the point of a canteen is
what is on the counter.

What is on the counter now is eight things, and the split held: buying does not
move the readout, and the readout does not move for a purse that has reached a
hundred, because the room it keeps is measured off four figures rather than off the
number showing.

### The counter

Four sections, one to a spread (see **Turning the page**) — `<` the section `>` at
the foot of it, or a finger dragged across the page — and each of them rows of an
icon, a name, what it does, how many of it you own out of how many there are, what
the next one costs, and a box.

**The goods are on the left-hand page and what they do is on the right.** That one
is not an arrangement invented for the fold; it is the only one the fold allows.
On a spread the row itself stacks too — the name on one line, then how many you own
and what the next one costs on the line under it, left and right of the same column
— because the goods laid flat are wider than half a page. That one is free: the box
at the end of a row was already deeper than two lines of lettering, so the second
line goes inside the height the row already had.
The widest sentence on this counter is wider than everything else in a row put
together, so with it sitting under the name a leaf cannot hold a row at all, and
the counter would have degraded to a column of prices with nothing saying what they
buy. Facing pages are what a book does with exactly that problem, and it turns out
to read better than the stacked version had: the left page is the transaction and
the right page is the argument for it. On one leaf nothing moves — the sentence goes
back under the name where it always was.

`PERKS` is four rows. Three of them — `REROLL`, `SKIP` and `EXPEL` — are spent on a
draft and are described under **Three things you can do to a draft**. The fourth is
`RETAKE`, which is spent on the moment the run would have ended and is described
under **The retake**. `HEROES` is the other three of the four characters (see
**Which character**), one row apiece at the same price.

`COURSES` is one row with three levels on it, wearing a mortarboard: how hard the
whole book is (see **The course you sit it as**). It is the dearest thing here and
the last thing on the counter that is actually sold — 15, 40 and 90 coins — and it
is the section furthest from the run itself, which is why it sits where it does. A
perk is spent inside a run, a hero plays one, and a course is which book the whole
afternoon comes out of.

And `REFUND` is the fourth, which sells nothing: see **Everything back** below.

**Why four sections rather than one list of eight.** The one line under the counter
says what a level of the thing you are looking at *is*, and that is where the kinds
part company: a perk's level is a use a run spends, a hero's level is a hero bought
once and yours for good, and a course's level is a harder book. A page printing
EVERY LEVEL IS ONE USE A RUN over a row selling the starman would be the counter
lying about its own goods. The split also happens to be what makes the page fit — a
box is twenty pixels deep, so eight rows in one column hangs off the bottom of a
sixteen-by-nine page — but that is a consequence and not the reason. The reason is
the note.

The counter does not care which section it is drawing, and that is worth saying
because it is the reason a row costs one line to add: a row is an icon, a name, a
price and a box whatever the thing at the end of it turns out to do. A row carries
which catalogue to ask about it and nothing more, and every catalogue answers the
same five questions about a key — what level you have, how many there are, what the
next one costs, whether you can afford it, buy it. The one field that says where a
*use* goes is read in a single place — the draft, deciding which of them get a button
down there.

The body of the page is the settings page's shape rather than the library's — one
fixed block, centred — and it can be for the settings page's reason: each section is
as many rows as its catalogue has in both languages and in every purse, so there is
something here whose height is the same twice. The block is reserved at the fullest
section and every column is measured across all of them, so nothing on the
page moves when the footer is stepped either — which is the library's rule about its
three shelves, for the same reason. The library reads from the top instead because the
catalogue decides how long its lists are and a page that recentred itself would
move every name on the shelf each time an arrow was pressed. Nothing on this
counter can change height at all.

Every column is measured at the widest thing that could ever stand in it — the
longest name in the language it will be lettered in, two figures of price, `MAX` —
so nothing in a row moves as a line is bought up. It degrades one
way and only one: the blurbs go first, because a row is an icon, a name, what it
does, what you own, what it costs and a box to answer, and the only one of those a
narrow page can do without is the sentence. That is the difference between the
counter fitting a phone held upright and the prices hanging off the edge of it.

**Buying is the one thing in the margins of this book that is answered rather than
pressed.** Everywhere else back here a press is a press: a tab is pressed, a name
in the library is pressed, a volume is dragged, on the rule that choosing what to
look at is not a question and a quantity you can always move again is not an
answer. A purchase is neither of those. It is a thing you cannot take back, and a
box you scribble in is how this game asks about one — so each row ends in a box,
the border warms slate → blue → red as it fills, the coins come out when the pen
lifts, and a scribble that carries on out of the box changes its mind. Afterwards
the box is *wiped* rather than left full, which is what the drawing board's `RESET`
already does and for the same reason: a counter you can only buy one thing at is a
counter you have to leave and come back to.

A hero is bought the same way and for good: his row then reads `1/1` and `MAX`, the
studio's arrows have somewhere new to step, and the run that opens as him opens
holding his weapon. Turning the page with a box part-scribbled leaves the scribble
exactly where it was — turning a page is not changing your mind — though whatever was
*armed* is disarmed the moment the leaf starts moving, since nothing is bought until
the pen lifts and the pen is about to lift on another page. The moment the leaf
starts moving, and not the moment it lands: a page that has begun to turn is a page
you have stopped answering.

A row with nothing left to sell, or nothing in the purse to buy it with, has no box
drawn at all — the price beside it goes grey, or turns into `MAX`, and ink that
lands where the box would have been is just ink on the page. The one line under the
counter says which of those the section showing is in — there is something to buy, you
cannot afford any of it, there is none of it left — rather than printing an
instruction whatever is true. A page telling you to scribble a box when there is no
box on it is a page arguing with itself.

#### Everything back

The third section is one row, and it is the only thing on the counter that hands
coins *to* you: `REFUND ALL` gives back every perk level and every hero you have
bought, at exactly what you paid for them, and its figure wears the `+` the two end
cards' payouts wear so it cannot be misread as a price.

**It is one row rather than a row per thing on purpose.** A counter you could unpick
a level at a time is a counter you would shop on — buy the second reroll for one
afternoon and sell it back for the next — and every price back here is written
against a line you commit to rather than one you rent. All of it or none of it is not
a trade. It is the sentence *start again*, which is the only thing anybody actually
wants from a refund: forty coins of skateman is a week's play, and a week is a long
time to be wrong about a hero you have never played.

**There is no fee and no rounding.** The two things a refund could be are a decision
you take back and a tax on having changed your mind, and this game does not charge
for the second one. A refunded book is exactly the book you would have had if you
had walked past the counter on the way in.

**A course goes back like anything else**, and it is the one row here with a
consequence past the coins: the book is put back to high school and the *pick* goes
with it. A run sat at a doctorate that was never paid for is the one thing a refund
must not be able to leave behind.

**What it does not hand back is what a hero did.** The five minutes as the starman
that took his line out of his hands and into everybody else's draft (see **The
collection**) stay yours after his row goes back to `0/1`. You bought him, you
played him, and what the book learned from that is not for sale back — a refund must
never be a way of *losing* something you had opened. Nor does it reach into a run
that is already standing: a run is handed its uses when it starts, and nothing is
ever taken off a run once it is carrying it.

It is a section rather than a row at the bottom of one because it is about all
three of the others at once, and a row on the perks page that also sold your heroes
back would be the counter's own split broken by the one row that cannot respect
it. The
page under it says `YOU GET EVERY COIN BACK`, and when there is nothing to give back
the row simply reads `+0` in grey with no box on it, and the line under the counter
says `NOTHING TO REFUND` rather than telling you to come back with more coins.

### The purse

A run pays out, and it is paid for four different things:

- **One coin per hundred killed**, floored.
- **Ten for every level it sold back** at the draft.
- **One for every rung of the grade** it came back with — nought for an `F` and
  twelve for an `A+` (see **The mark**).
- **Eight for every eye it put down.**

And then the whole of it **at the rate of the course it was sat at** — a doctorate
pays three times what high school does (see **The course you sit it as**). A rate
rather than a fifth term, because what a harder class is worth is everything you
did reckoned higher, where a flat bonus for enrolling would pay a doctorate for
walking onto the page.

All of it banked into a purse the next run still has: one number, in one file,
shared by the whole book.

The four are four different kinds of fact about the same run, and that is the
point of there being four rather than one. The kills are what it *did*, and the
floor on them is the only thing about that term worth arguing over — a run that
killed ninety-nine is worth nothing, which is what makes the hundredth kill worth
something. The skips are the one term the run *chose*. The grade is what it
*lasted*: the ladder is the ten minutes divided into thirteen, so this is a coin
every forty-six seconds and nothing else, and a run that spent the whole page
hiding behind pen lines finally comes back with something for it. And the eye is
the **cliff** — everything else climbs smoothly with the clock, so without it the
last ten seconds of a ten-minute run, the only part that is a fight rather than a
crowd, would pay exactly what any other ten seconds paid.

A run that reaches the eye and shuts it comes back with about twenty-four: four
for the body count, twelve for the `A+` and eight for the eye. A run that dies at
five minutes with two hundred kills comes back with eight. A run that dies on the
way in comes back with nothing at all, which is what a run that did nothing should
come back with. The same won run is thirty-three at a bachelor's, forty-eight at a
master's and seventy-two at a doctorate, which is what makes the ladder a bargain
rather than a badge: a rung pays for the next one faster than the last one did.

That is roughly five times what a run used to be worth, and the inflation is
deliberate rather than drift. The counter has four cheap lines on it today and is
going to grow rows that lock parts of the book behind them, so the faucet was
opened for what is coming rather than for what is there; the four prices already
on it are untouched and are now the near end of it. A first reroll is a middling
run rather than two good ones, and the whole counter is about eleven winning runs
rather than sixty-six.

It is not kept against a lesson, and that is the difference between this and the
register (see **What a lesson remembers**). A record is a fact about a page —
the longest run and the biggest body count, a maximum, per lesson, and a bad run
cannot take one away. A purse is a thing you *have*: it adds up across lessons,
across characters and across launches, because what it is being saved up for is in
the canteen and the canteen does not care which page you were on.

**A run is paid when it ends, and only then.** The two endings are dying and `END`
on the win card — the same pair that takes the `CONTINUE` box off the title screen
and clears the bookmark (see **The third box**). Walking out through the pause card
pays nothing on purpose: that does not end a run, it leaves one, and the run it
left is still sitting there to be finished properly. `ENDLESS` is not an ending
either, which is what keeps the arithmetic honest without anything having to
remember what it has already paid for — a run that shuts the eye at four hundred
kills and dies at nine hundred is paid once, for nine. It also means the number
the win card shows is a bet rather than a receipt: `END` collects it, and `ENDLESS`
is a wager that it will be bigger by the time it is collected.

The sum lives in exactly one function (`Purse.forRun`, `src/purse.lua`) for the
mark's reason, and the last two terms are that promise being cashed rather than
made: the grade and the eye were both added without a line changing in the win
card, the death card or the canteen, because none of the three knows what is in
the number it prints. The run is handed over as a table of what it *is* — kills,
skips, grade, eyes — and `Game:runWorth` is the one place that fills it in, so a
fifth term is a field there and a line here. The grade it hands over is the grade
the card prints, awarded on a win and measured off the clock otherwise: the letter
and the figure under it are two readings of one run, and a card whose grade and
payout disagreed would be a card arguing with itself.

A skip is banked on the run as a *count* rather than paid into the purse when it
happens, and that follows from the paragraph above: a level sold back is something
the run earned, and nothing a run earned is collected until the run has ended. The
bookmark carries the tally for the same reason — a run picked up again after the
program was closed is still owed for the levels it sold.

The coin itself is drawn rather than written: nine pixels across, an ink rim, a
light red face and a white `1` struck inside it.

Red is the other side of the fight everywhere else in the game, and this is the
palette's one standing exception — the interface. A coin is not a thing in the
fight, it is a thing written on the page in the same red pen the lesson headings
and the run's grade are written in, which is the pen a teacher hands work back in.
The figure is paper because paper is the one colour in the palette that *covers*:
the `1` stays white against the fill and wipes whatever is under it, while the
fill stacks with the page like any other mark. So the coin is flat pink on a paper
card, and on a ruled page a rule crossing it darkens the fill and leaves the
figure alone — which is what a pink mark on ruled paper does. The readable half of
the drawing being the half in the colour that erases is the point rather than a
side effect.

Nine across and not seven, and the two pixels are the whole of why: a 7x7 rim
leaves five columns of face with the corners cut off, which is not enough for a
numeral — at one pixel the figure is a smudge and at two it fills the face and the
coin comes out a dark blob at every size. Nine leaves a 3x5 cell with a pixel of
fill all round it, which is the 3x5 face's own cell, so the figure on the coin is
the same size as the figure beside it and the pair reads as a price. The pair
scales as one drawing too — the hero's trick, an integer `love.graphics.scale`
with the sprite unchanged inside it — so a screen that doubles the figure gets a
doubled coin rather than a 1x coin standing in front of it like a bullet point.

## Drawing your character

`CUSTOM` on the timetable hands you a stick man on a board, a pencil, a pen and a
rubber, and whatever you leave on the board is the sprite you play as. `OK!` hands
the screen back to the timetable, where `GO!` is — so the board is a loop off the
side of the way in rather than a step along it:

```
title screen  ->  the timetable  ->  the run
                    |        ^
                    v        |
                  CUSTOM -> the board -> OK!
```

A run therefore starts with the hero you already have. Most runs do: you draw one
the first time, or the day you want a different one, and after that `GO!` is the
whole of the way in. Drawing a character every single time you started would be a
toll on the thing you do most often, paid to a screen that only has something to
say when you have something to change.

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
between the page margin and the gap to the tools. The pencil, the pen and the
rubber are
pinned to the right edge of the safe area, on the run's own margin, in the run's
own 13px box, popping out
the same way when selected and tested for presses the same way: the tools are in
the same place on the page whether you are drawing the hero or playing him, so
there is only one spot to reach for. The two arrangements — the column beside
the board, or the same pieces above and below it with the board spliced in — are
picked between by *which leaves the bigger cell to draw on*, beside on a tie.

**Three tools and not eight.** A design is a grid of palette keys and the save
files have always accepted any of the eight, so the number of buttons on the
board is a decision rather than a limit: three is a pencil case and eight is a
paint set, and what a board is asking you for is a shape. The three are the
pencil (ink), the pen (blue) and the rubber (paper, which is what a cell goes
back to). Blue is the one that earns its place, because blue is not a colour
here so much as a side — it is the pen you draw walls with, the bullets, the
bomb's flash, the burn it leaves and the skate's wheels — so a blue pixel in a
drawing reads as part of the thing rather than as a colour somebody liked. Red
is deliberately not on offer for the same reason from the other end: red belongs
to the horde, and a hero drawn in it would be the one mark on the page lying
about whose side it is on.

The one drawing to be careful with is the bomb, and it is not stopped from being
drawn badly: the last stretch of its fuse flashes the sprite's own silhouette
blue, so a bomb drawn *in* blue is one that looks lit the whole time it is safe.
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
`hero-shootman.txt` in a text editor shows the character — and read back on the next
launch. A file that has been edited into something the game can't draw is ignored
rather than trusted, and you get the stick man back. There is only ever one hero
*at a time*: the run draws it, the title screen's doodle draws it, and the board's
life-size copy draws it, all off the one `Sprites.player`.

**But there is a hero per character.** The shootman you drew and the swordsman you
drew are separate drawings in separate files (`hero-shootman.txt`,
`hero-swordsman.txt`, `hero-starman.txt`, `hero-skateman.txt`), and
the arrows step between the ones you own: change the archetype and the board changes with it,
so a run's hero is the one you drew *for that archetype*. They all start from the
same stick man, which is a default rather than a rule — the point of a file each is
that they stop being the same drawing the moment you touch one. A board with no
file of its own yet falls back down a short list: the file that character was kept
under before it was renamed, and then the single `hero.txt` the game used to keep.
So neither the split nor the day the shooter became the shootman takes a drawing
away — it turns up on the new board, and the first `OK!` writes it under the new
name.

Stepping away from a board you have drawn on **keeps** it. `OK!` is still the only
thing that answers the screen, but the drawing you are leaving and the one you are
arriving at are different files, and a step that quietly threw the last ten strokes
away would be the one place in this game where drawing something loses it. A blank
board is not saved, for the reason `OK!` refuses one: an empty file is an invisible
hero.

`RETRY` on the game over card goes straight into the next run with the same
character; the board comes back round through the title screen.

### Which character

Between the drawing and the two boxes there is a third question, and it is the
only thing on this screen that is *pressed* rather than drawn in: which kind of
hero the drawing is going to be. Two arrows with a name between them, the way an
index tab on the timetable works — choosing which one to look at is not a
decision, `OK!` is, and you can change your mind as many times as you like before
you answer.

That is also why it sits where it does. The screen reads top to bottom as *what*,
*who*, *answer*: the title, the board with the life-size copy beside it, the name
of the hero it is going to be, and then `OK!` and `RESET` with the line that talks
about them directly underneath. Both arrangements — the column beside the board, or
the same pieces above and below it on a phone — keep that order.

There are four, and each is a different answer to *where the fight happens*
rather than a stat block. **One of them is the book's and the other three are
bought** — see below:

| | opens the run holding | what that is | what it asks of you |
| --- | --- | --- | --- |
| `SHOOTMAN` | `SHOT` | a pellet at whatever is nearest, 96px off, every 0.7s | nothing: it fires over the crowd |
| `SWORDSMAN` | `SWORD` | an arc through everything at arm's length, double damage, every 0.825s | you have to be inside the thing trying to touch you |
| `STARMAN` | `STARS` | a star turning round you, cutting what touches it | you have no reach at all: it is a ring, and what you decide is what you let close |
| `SKATEMAN` | `SKATE` | a trail behind you that cuts whatever follows you down it | you cannot stand still — the ground you left *is* the weapon |

**The swordsman is the one every book comes with.** The other three are rows on the
canteen's `HEROES` section at forty coins apiece — about two good runs each — and
until one is bought the arrows have nowhere to step, so a fresh book's studio shows
the swordsman with two grey arrows either side of his name. Grey rather than gone,
for the reason a spent button on the draft is grey rather than gone: a column that
lost a row would move everything under it.

The swordsman is the base because he is the plainest of them — standing inside the
crowd with a sword is the run this game was written around — and because a first
afternoon should be spent finding out what the crowd does rather than what a trail
does. Buying one is what turns the studio's arrows into a choice, and it is the first
thing on the counter that changes what a *run* is rather than what a draft offers.

They are all **the same price**, and that is the one decision here worth defending.
The roster is not a ladder: not one of the three is stronger than the others, they
are three different questions about where to stand, and a price rising down the
column would be the counter saying the last one is the best one. If a hero is ever
added that genuinely asks more of you than the rest, that is the day to write a
second number down and say why.

**A hero bought is not his weapon bought.** He opens the run holding his line from
the first frame he is played — being handed a line has never gone through the
collection — but the draft will not deal that line to anybody *else* until five
minutes have been survived as him. That is the lesson tools' bargain with the roster
in place of the timetable, and it is the whole of what a purchase leads to: buy the
starman and you can play him; play him for five minutes and everybody can carry a
star. See **And every hero keeps his own weapon**.

**A character is one line of the catalogue, issued.** The hands-free attack used
to be something a hero *was*: a reach, a damage multiplier and a beat sat on his
row and a clock inside the player read them. Those are two passive weapon lines
now — `SHOT` and `SWORD`, in the draft beside the stars and the rocket, with the
numbers on their own blocks — and picking a character is being handed *some* line
at level one before the run is built, exactly the way the lesson hands over a
tool. It spends one of the five weapon slots to do it, and it is counted in the
`1/5` under the weapon column from the first frame rather than being an attack
nobody was ever told about.

Which is what the last two rows of that table are: once the opening attack is an
ordinary card, a hero who opens with something that is not an attack at all costs
nothing but a row. The starman opens with the stars line and the skateman with the
skate line, both at level one, and neither has anything that shoots. They are also
the two whose opening weapon was for a while the only *unfinished* one: `SHOT` and
`SWORD` were an unlock and nothing after it, so a shootman's first weapon was the
last level of it he would ever see while a starman's was a line the draft could go
on selling him four more times. All four are five levels long now, and the
difference has gone.

What those two lines sell is worth being exact about, and the table's fourth column
is the better guide to it than the numbers in the third: a line sells whatever its
weapon is short of. A pellet has no shape at all — a point going in a
straight line at the thing that matters — so `SHOT` sells the four numbers a pellet
*is*, in the order you notice them: the beat, then how fast one flies, then what it
is worth, then two of them at once. An arc is nothing but shape, so `SWORD` sells
the shape and never once sharpens the blade — a longer arm, a wider turn, a shove
on whatever lived through the cut, and finally the whole circle.

The one place that costs somebody something is the shootman's opening, and it is
deliberate. `SHOT`'s unlock now sits *below* the beat the rest of the game was
balanced against — 2 damage every 0.7s at 80px a second, against the 3 every 0.55s
at 110 that used to be the whole of the line — so his first minute is softer than
it was and the pellet is slow enough that a bat crossing in front of him can be
missed. Level two hands the beat back, level three the flight, and level four
doubles the damage past where it started; a shootman four levels into his own line
is half again the shot he used to arrive holding. What he no longer is, is finished
before the first frame.

It also makes the table a starting position rather than a wall. A shootman can
draft `SWORD` and spend the rest of the run swinging one at whatever walked all the
way in; a swordsman can draft `SHOT` and have something for whatever will not
come; a starman can draft either and stop being the hero with no reach. Nothing is
a special case — they are cards like any other, dealt by the same draft on the same
terms, and a run carrying two of them has spent two of its five weapon slots.

Everything else is the same for all four, deliberately. Same speed, same health,
same ink meter, the same tool the lesson hands out and the same 190 upgrade levels,
so a build learned as one run reads as the next. What a character sets is *where
you have to stand on the first minute*, and a stat hung on one of them to make it
feel different would be an upgrade in the wrong place.

The beat is where the arc is paid for, and it is worth being exact about why. A
swing is worth double *and* cuts everything standing in it, which against a packed
crowd is several times a shot rather than twice one — so the price is charged
where you feel it as the character rather than taken off the damage, which would
just be a shot with a different number on it. Half again as long between
swings is a stretch you have to survive standing in among what you have just hit,
which is the whole of what the swordsman is: the reach is what makes the arc worth
having, and the gap is what makes standing there a decision.

Which upgrades touch it follows from that, and it follows without a special case
anywhere — rather more literally than it used to, since both attacks are now
weapons like the stars and the rocket. The swing sits on exactly the axes the shot
sits on: **graphite** sharpens it (`passiveDamage` — neither attack is aimed, so
both are "what fights for you"), and every global damage multiplier lands on it. The **sharpener** does not, for the same reason it never touched the shot:
that is the other axis, what you draw with. A build sheet reads the same for every
hero.

The *beat* is for sale, and it is sold by the same card that sells every other
beat in the game. There used to be a passive that shortened these two and only
these two, on the grounds that they were the only attacks a run had not asked
for; it went when the scissors became a tool and the sharpener's name moved onto
the drawing half of the damage split. What replaced it is the **metronome**,
which multiplies the gap on every weapon block there is — so the swordsman's
half-again gap is still half again after it, because a rate multiplies both sides
of a comparison and leaves the trade exactly where it was. That is the point of
selling cadence globally rather than per attack: it makes a run faster without
making one character's opening into another's.

The sword is not aimed, any more than the shot is: it goes at
the nearest thing in reach on the same beat, and what you are deciding is how
close to stand. The swing opens as an arc of about 140 degrees turned through the
crowd, and it cuts *everything* standing in it — one blob or five for the same
beat, which is the other half of what the reach is paid for.

Both of those numbers are the line's now rather than the module's, which is the
whole of what `SWORD`'s four levels sell: the arm goes seven pixels further out
(and seven pixels further out is also seven more pixels of edge at every point of
the sweep, the arc having widened without moving), then the turn passes a half
circle, then whatever lived through the cut is shoved back, and then the swing goes
all the way round. What no level touches is the damage — a weapon that already
takes everything standing in the arc does not need sharpening, and a run that wants
one buys the passive that sells damage to everything it owns. Nor does any level
touch how *long* the arm is out: a wider sweep is a faster edge over more ground,
so the last one is a spin rather than a pose.

It is swept rather than stamped. The arc is walked over about a sixth of a second
and each frame cuts only the wedge it has just crossed, so the far side of the arc
is reached later than the near side and one swing can never hit the same thing
twice. The pivot is where you are *this* frame rather than where you were when the
arm went, so a swing carries with you while you walk out of the crowd you are
cutting — a swing you had to stand still for would be the one thing in this game
that stopped you moving.

The trail is drawn at exactly the radius that cuts, in the pale blue that fades to
the brighter blue at the edge doing the work, and the blade's point rides on that
same radius: the arc you can see is the arc that killed, which is the bomb's
blast ring by another name. A reach nobody can see is a reach nobody can learn.

**And you draw what the character fights with.** `OK!` on the hero's board does
not go back to the timetable — it hands the screen straight on to a second board,
whichever character is picked (and it is the same board the weapon line opens when
somebody drafts it instead, since it is the same drawing either way):

```
                  CUSTOM -> the hero's board -> OK!
                                                 |
                    the board of whatever he carries -> OK! -> the timetable
```

On `SKIP` (see **Settings**) that second arrow is not taken: `OK!` on the hero
lands back on the timetable, since the arm is a board the game opened for you and
the hero is one you asked for.

The swordsman's is 3 cells wide and 8 tall with the sword on it; the shootman's is
5 by 5 with the pellet it sends; the starman's is the star that will be going round
him and the skateman's is the board he will be standing on. A sword he swings and a
shot he sends are as much of him as his own outline is, so it is one visit to the
studio rather than a second screen to go and find, and no character is the one that
gets a board. They are kept like every other drawing, one line per row in the save
directory (`sword.txt`, `shot.txt`, `star.txt`, `skate.txt`), so the second board is
usually a board you press `OK!` on and walk past.

The shot's grid is bigger than the pellet drawn on it — a blue diamond three
pixels across in a five-pixel box, the same trick as the dart's blank outer rows —
so there is room to draw a heavier-looking shot, and `Bullet.radius` is the grid's
half-width either way: a shot drawn out to the corners hits exactly where the
small one does. The one thing worth knowing before redrawing it is the colour.
Blue is what you sent and red is what is coming at you, and the eye's spit is this
same diamond in red with a dark rim; a shot drawn in ink is a shot you cannot tell
from the thing being spat back at you, and on the unruled page there is no
overprint to tell them apart either. Nothing stops you — the sky pixel in the
middle is not even one of the board's three buttons — but blue is what says whose
it is.

Neither of these turns, and for the shot that is a decision rather than an
oversight: it flies at whatever angle the nearest thing happens to be at, so a
drawing with a front would point the wrong way at nearly all of them. The sword
does turn, because a swing has one heading at a time and you are looking straight
at it.

Three cells across is not much, and what fits in it is the four things that make
a stick read as a sword: four rows of blade, one row of cross guard — the one row
wider than the blade, and the whole reason it reads at all — two rows of grip and
a pommel. The grip is blue, because blue is the half of the palette that is yours
and the grip is the end you are holding; that is worth keeping whatever else
anybody draws there, since a cleaver, a bat or a rolled-up ruler is the same eight
rows and the colour is what says which end goes in the hand.

The sword is the second thing in the game kept at all eight headings, and the one
exception to the nose-right rule the rocket set: a sword is *held*, so it is drawn
point-up and read two eighths round the ring. It pays the same price on the four
diagonals that the dart does — a one-pixel blade does not survive a resample — and
it is paid there rather than at the four square headings, where the guard and the
point are the two things anybody will actually recognise.

Which character you picked is remembered the way a drawing is: one line in a text
file, read back on the next launch, and a line the game does not recognise falls
back to the shootman rather than to nothing. `RETRY` on the game over card goes
straight into the next run as the same hero, sword and all.

It is also written on the timetable, twice. As the first row of the panel —
`HERO`, then `TOOL`, `BEST`, `KILLED` and `MARK`: who is going out there, what the lesson
hands him, and how the page went last time. And as the thing in his hand: the
sword, the pellet, the star or the board you drew, beside him at his own scale and
on his own walk bounce, so the character standing there is holding the drawing he
fights with. The stats start at
the same pixel whichever it is — the column is as wide as the widest weapon in the
roster, which is the skateman's fifteen-pixel deck — and the drawing is dropped
along with the hero on a screen too narrow for
either, since a sword floating beside a panel with nobody holding it says less than
nothing. That row is the one line in the panel that is not
the lesson's, and it is written in the same label-and-value the other three are,
because which hero you are is not a stranger fact than which tool you have. It is
first because it is the one thing on that screen you would otherwise have to go
two screens away to find out.

### Drawing your weapons

The hero is not the only thing you draw. Almost every passive weapon sends you
back to the board the first time you take it: the same board with a star on it, a
bird, a
rocket, a face, a cool S, a bomb, a skate or a lightning bolt, and the pixels you
leave there are
what goes
round you, wheels about near you, launches off you, comes up in the corner, floats
away across the page,
sits at your feet counting down, goes under those feet or comes down out of a
cloud for
the rest of the run — and for every run after it, since they are kept in
`star.txt`, `bird.txt`, `rocket.txt`, `sun.txt`, `cools.txt`, `bomb.txt`,
`skate.txt` and
`lightning.txt` the
way the heroes
are kept in `hero-shootman.txt` and the rest of the roster's files. RESET puts the default
back, exactly as it does for the stick man.

None of it happens if `NEW DRAWINGS` is on `SKIP` in the settings — see
**Settings**. The board is still there and `CUSTOM` still opens the hero's, but a
draft stops handing you one and the weapon turns up wearing whatever is on its
file already.

The sword and the shot belong to this list too, approached from the other end.
They are weapons like the rest of these now (`SWORD` and `SHOT`), so drafting one
opens its board mid-run exactly as taking a star does — it is only that most runs
never see it happen, because the character you picked was handed one of the two on
the way in and drew it there, on the board that follows the hero's own. Same
boards, same `sword.txt` and `shot.txt`, whichever way you arrived at them.

The laser beam and the spirals are the two exceptions and the reason is the same
one twice: they are lines rather than pixels. A pointer and a beam are both a
length and a width the upgrade line decides, drawn by `pixelart` at whatever angle
you happen to be walking; a spiral is a number of arms and a number of turns wound
either way and spinning. There is nothing in either a board could hand you — and
being nothing but plotted lines is exactly what lets both of them go down at any
angle at all rather than at one of eight.

The rocket is the loosest of them about what it wants: what has to survive
is the taper, so that the pointy end is still the end that goes first. A dart,
an arrow or a sharpened pencil is the same eleven by seven pixels and the same
board. Draw it nose-right, because that is heading one of eight.

The bomb is the one board whose drawing is shown in **a colour nobody drew it
in**. It sits on the page in your own ink and then flashes its own silhouette blue
over the last stretch of its fuse, which is the only warning it gives, so what
the board is really asking for is a shape worth seeing filled in — an outline
blinks as a ring, and a ring does not read as a thing about to go off. Blue is
also why the shape has to carry the warning rather than the colour: half the marks
on the page are already blue, so what makes a flash read is a silhouette going
solid at a stroke. Eleven by
thirteen, a round body filling nearly the whole of it with four pixels of spark
going off the top-right corner, and the spark is what the size is for: a ball is
a ball at any scale, and a ball with nothing lit on it reads as a cherry. The
handful of gaps left in the body are highlights, and they blink as gaps — which
works while they are holes in a shape and stops the moment they join up into an
outline.

The skate is the one board that goes **under another drawing**. It is drawn at
the hero's feet in place of his shadow, so it is fifteen by three — fifteen
because that is the width of the grid the hero is drawn on, and a board narrower
than the man standing on it reads as a man standing beside one; three because
that is all there is under a pair of feet at this scale, and it is exactly the
three parts of a skateboard: the kicked-up nose and tail, the deck, and the
wheels. The deck is thirteen wide and that is the one measurement here anything
else is struck off — the trail is the same thirteen, so what is left on the page
is the width of what left it.

The wheels are blue, and it is the sword's grip read the other way round: the
grip is blue because it is the end you hold, and these are blue because they are
the end that touches the page. Whatever anybody draws here, they are worth
leaving in the colour of the line they lay down.

It is also the only board that refuses `walks` rather than simply not wanting it.
Everything else that stands on the page gets the run's own one-pixel bounce in its
preview; a skate *is* the ground the hero is standing on, and having one is
exactly what stops him bouncing. A preview that bobbed would be advertising the
one thing the weapon takes away.

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

The lightning bolt is a board of its own, and it is half of a weapon rather than
all of one. The storm is a cloud and a bolt; the cloud is authored and yours is
the thing that comes out of it, because the bolt is what the weapon *does* and
the cloud is only what carries it in. Seven by fifteen, tall and thin, drawn with
its point at the bottom of the middle column — the point is where the strike
lands and the ring that flashes round it is drawn from that same spot, so a bolt
tapering into a corner would be a bolt landing somewhere other than where it is
pointing.

It is also the one board where the *height* of what you draw is a measurement
something else is struck off. The cloud floats exactly a bolt above whatever it
is about to hit, so a longer bolt is a cloud hanging higher, and nothing has to
be kept in step by hand. Like the cool S it is drawn with a pale blue rim in the
run and in the preview both: a few thin strokes on a page made of thin strokes,
on the page for a third of a second at a time.

The bird is the smallest board after the pellet, and the one with the most copies
of what is on it: seven by three, and whatever you leave there is every bird in
the swarm — fourteen of them at the top of the line, which is worth knowing before
drawing something busy. The default is the doodle everybody already draws along
the top of a page: two humps and a dip, an m with its wings up, with the bottom
row left empty for a tail. It gets no rim, and it is the one thing on the page
that would most like one — a bird is the same weight of line as everything it is
flying through — but fourteen pale blue outlines would be a cloud of sky laid over
the crowd they are supposed to be cutting.

#### Eight headings, four of them exact

Two *drawings* in the game point where they are going, so those two are the ones
kept at more than one heading. What you leave on either board is turned into a
ring of eight (`pixelart.turn`): a rocket is *fired* down one of them, so the
heading and the drawing are one choice and nothing is rounded between them, and a
sword picks one every frame of the swing it is being turned through.

The rocket is drawn nose-right and read straight off that ring. The sword is the
one exception in the game, and the reason is that a sword is *held*: its board is
three cells wide and eight tall with the point at the top, so the swing reads the
ring two eighths round from where it was drawn. That offset is one constant in
`src/sword.lua` and lives nowhere else.

Eight is a limit on sprites and on nothing else. The laser beam points where it
is going too and is aimed at any angle at all, because every part of it is
plotted by `pixelart` rather than drawn from a grid of pixels somebody authored —
which is the trade in both directions: the rocket can be redrawn and is stuck
with the eight, and the beam is aimed at any angle there is and cannot be
redrawn.

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
  and it reads perfectly at four headings and as a blob at the other four. The
  default sword pays exactly that: its one-pixel blade is scrappy at the corners,
  and it is drawn thin anyway because the cross guard and the point are the two
  things that make eight pixels read as a sword at all, and both of them are
  square-heading detail.

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
`SHOT` is the plainest case of that split — its card carries a bullseye, because
what the line sells is that something goes at whatever is nearest without being
asked, while the pellet that actually leaves is the five pixels you drew.

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

That corner is where it ended up by elimination. Both side margins belong to the
two columns and are claimed at full width whether the run is holding one tool or
four; a bottom corner belongs to the thumb stick, and which one is the player's
to say. The gap to the
health bar is six
pixels rather than four because the button's touch target reaches five past its
own box, and a health bar with that lying across its left end is a bar that
pauses the run when you press it.

The button also sets the height of the two bars either side of it. They used to
be six pixels against its eleven, which made the top of the page three things
that happened to share an edge; cut to the button's own height it is one row,
and the button reads as the third readout in it rather than as something dropped
on top. Both numbers and the clock are struck off that height rather than off a
line of their own, so the row can be made taller or shorter in one place.

Pausing holds the run where it stands: the clock, the horde, the ink and any
mark still fading are all exactly as you left them. An open stroke is closed off
at the freeze, so the nib can't rule a line across the page on the way back to
wherever the pointer wandered to while nothing was moving.

Up comes `QUIT?` with the same YES and NO boxes the title screen uses and the
same arm-then-lift mechanic. Scribbling YES hands the page back to the title
screen; NO lets the run go again.

YES is not the end of the run, though — it is the one route out of one that is
not. It banks the record and leaves, and because leaving does not tear anything
down, the run is still standing there behind the title screen with a `CONTINUE`
box offering it back (see **The third box**). It writes the bookmark too, so the
run survives the program being closed as well, minus the page. Dying and taking
`END` on the win card are the two endings, and neither leaves anything to go back
to — both clear the box and the file.

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

The card also carries the game's development switches. `T` takes every tool line
to its top level at once — lines the run never started and lines it was part-way
through alike — and `W` does the same for every passive weapon line; pressing
either again restores each of its lines to exactly the level the run had really
reached, so nothing the run earned is touched. They exist for playtesting one
line as it plays fully upgraded without drafting a run all the way to it, and
they deliberately walk straight past both four-slot caps; the slot counters on
the held screens go red rather than pretend otherwise.

A lent column does not fit on the paper, and that is the one thing the switches
had to change about the page rather than about the run. Thirty-four tool lines
is thirty-four boxes, five hundred and forty pixels of them down a page a
hundred and eighty tall: every tool the switch lent you was drawn and none of
them could be read, and the ones off the bottom could not be picked up at all.
So a column asked to draw more than it has room for becomes a **window** onto its
list instead — as many boxes as fit, seven on the shortest page the game runs on,
with a small arrowhead in graphite at whichever end it cut, pointing the way the
list goes on. What decides seven is the page rather than the column: a column at
full length runs into the furniture at the ends of its own margin — the corner
button at one end, the experience bar across the whole of the bottom edge, the draft's row of
bought buttons in that same corner — all of it drawn on the very screens the
column is read on. A window drops its slot counter for the same reason it grew a
mark, and loses nothing by it: a column only becomes a window when a switch has
lent it every line of its kind, which is exactly the case where the four-slot
rule that counter is there to teach is suspended. The rule is written in terms of
room and not in terms of the switch: a column that does not fit is a column that
does not fit, and a drafted run — four slots of each kind against room for
seven — never meets it.

The strip's window keeps the tool in your hand in the middle of it, which is the
whole of how it scrolls: the wheel and `Q`/`E` and the number keys move the pick,
and the window slides after it, so the seven tools around the one you are holding
are the seven you can see. On touch the same rule is the reach — pressing a box
picks that tool and brings it to the middle, so a press near either end of the
window walks three tools along the strip, and a handful of presses covers the
length of it. A press always hands you the tool you pressed, even though the
column under your thumb has moved after it. The weapon column has no pick to
follow, being a thing you read rather than press, so on the pause card — and only
there, since on the draft the whole page belongs to the three cards — a press in
its margin or a turn of the wheel turns the page of it, wrapping at the end
rather than stopping dead.

Two switches rather than one, because the two kinds are not *looked* at the same
way. A tool is judged by what your hand does with it, and a page already carrying
every passive weapon is a page where nothing your hand does can be seen at all —
so a single switch that lent both was a switch that could not show you either.
Borrowing one half leaves the other half of the run exactly as it was drafted,
which is what makes the strip readable while the weapons are off, and the weapons
readable while the strip is a pencil.

Those two kinds and not the passives, because those two are what a run
*carries* — the strip down one margin and the weapons down the other, both
drafted rather than issued, and both things you have to look at to judge. A
passive is a number about the player, and a playtest that wants one wants a
particular one rather than all fifteen at once.

On touch there are no keys to press, and a phone is the thing most worth
playtesting on, so each switch becomes what every other question on this screen
already is: a box you scribble in. `TOOLS` and `WEAPONS`, small and set apart
from `YES` and `NO` by a gap, with `ON` or `OFF` beside each reading out which way
it is set — red while that half is lent, the same red the slot counters go. They
are boxes of their own rather than more boxes in the `YES` / `NO` strip, since a
box in that strip that did something other than answer would be a box that ends
the run when it is misread; and they sit in one row rather than stacked, because
the canvas is only ever 180 game pixels tall and a second row of boxes costs
height the card does not have to spare.

Handing a half back is exact in one more way that only matters for weapons: a weapon
the run had genuinely started keeps the very same instance across the whole
round trip, so an orbit that has been turning for two minutes is still at the
angle it was. One the switch had only *lent* gives its instance up along with
its levels — otherwise a sun the toggle lent you would still be part-way round
its cycle if the draft later offered that line for real, and the first level of a
weapon is meant to show you what you just bought.

## When the run ends

Two things end a run and they end it on the same card. Killing the eye puts up
`THE EYE IS SHUT` / `YOU WIN` with `END` and `ENDLESS` under it; being killed
puts up `CLASS DISMISSED` / `GAME OVER` with `RETRY` and `QUIT`. Same paper card
lying on the frozen page, same two boxes, same arm-then-lift, same `1` / `2` on
the keyboard — because a run that has just been killed is looking at a page in
exactly the state a won one is, and the only difference between the two moments
is which question it is fair to ask.

`RETRY` builds the next run there and then: same lesson, same hero, nothing
walked back through. `QUIT` hands the page back to the title screen. Dying used
to be a small flat panel with `TAP TO RESTART` written under it, which made the
end of a run the one moment in the game where the page told you what to do
instead of asking you something — and it had exactly one way out, so leaving
meant restarting a run you did not want and then quitting out through its pause
card. Both of those are endings either way: neither leaves a `CONTINUE` box on
the title screen and neither leaves a bookmark on disk (see **The third box**).

Everything outside the card is page, as on the pause screen. The whole of it
stays drawable, ink that misses the boxes is just ink, and the thumb stick goes
away — there is nobody left to walk, and a box sitting in the stick's own corner
would be a box whose scribble was swallowed on the way in.

Directly under the clock and the body count both cards print the course it was sat
at — `SAT AT MASTERS`, in slate (see **The course you sit it as**). It goes there
rather than in the heading because it is not how the run went, it is the terms the
run went under, and the numbers above it mean something different at every rung. It
is printed at high school too: a card that only named the course when it was above
the easy one would make the plain run the run with something missing from it, and a
player who has never bought a rung would never once be shown the row that says the
ladder is there.

Under that, both cards print what the run earned — the
coin and a `+` and a figure, in ink like the numbers it is worked out from, since
the colour on either card is spent on the title and the grade. On the death card
that has already been banked; on the win card it is what `END` will collect (see
**The purse**).

One thing the death card deliberately does not do is speak twice. It arrives on
the same quiet sound the win card arrives on, and the rub loop of a stroke that
was open when you died is stopped silently rather than closed off properly: the
eraser's tidy little pop over the death burst would say the crumbs had been
swept rather than that you had been killed.

### The retake

A run that bought a retake at the canteen does not put the death card up the first
time it is killed. It puts up a third card — `ANOTHER CHANCE` / `RETAKING`, with
how many charges are left under it — the hero gets back up where he fell on half a
page of health with two seconds nothing can touch him for, and the run carries on.
The page, the ink, the level, the marks, the horde and the tool in your hand are all
exactly where they were. That is what a retake *is*: the only thing that changed is
that the run did not stop.

It is the same card as the other two, deliberately — paper laid on the frozen page,
the small heading over the big word — because the whole point of it is that you are
looking at the page you were about to lose, so it had better be the page you were
about to lose. What is taken out of it is the question. **It is the one card in the
game that asks nothing**, and nothing reaches it: no boxes, no keys, and a press
lands on nothing rather than starting a line. It draws itself on, it is read, and
after a second and a half it lifts off.

Which is the exception the rule needed. Everywhere else this game stops a run it
stops it with a question, on the rule that the page asks and never instructs — but
there is no question here to ask. A card offering to spend the last life you bought
weeks ago would be a question with one sensible answer, and a game that asks those
is teaching you that answering it does not matter. You bought a retake so that the
run would not end; it has not ended; that is the whole of the news, and a second and
a half is what it is worth.

Two seconds of grace rather than the 0.6 an ordinary hit buys, and that is the whole
of what makes it a chance: you come back standing exactly where you died, which is
by definition the worst place on the page. A hero who got up on the same window
everything else gets would be killed again by the same blob before he had taken a
step. Those two seconds do not start running while the card is up, either — the run
is frozen behind it — so the beat spent reading it is not a beat spent spending it.

Half a page of health rather than a full one, because a full bar would make it a
fourth life bought with coins instead of a second chance. What you are handed back
is enough to get out of the crowd that killed you and not enough to stand in it.

The burst you come back in is **blue** where the death burst is red, and that is
the palette doing the work rather than a flourish: red is the other side of the
fight everywhere in this game and getting up is yours, so the colour has said what
happened before a letter is drawn. The lettering goes the other way — it is the
death card's ink and not the win card's blue, because blue lettering means the eye
is down and is the only blue lettering in the game. This is not a win. The whole of
the colour on the card is spent on the count under the title, which goes red on the
last charge: that is the one thing on the page you have to act on, since the next
time it goes quiet like this it will not.

Two levels and no more. Three is the natural length of a line spent on a three-card
draft, and a run does not have three deaths in it — two is already a run played
twice over, and a third would be a page nothing on it could close.

### The mark

Both cards carry a letter in red between the title and the score, `F` up to
`A+`, and it is the one readout in the game that is not a number. The timetable
carries one too — the best a lesson has ever come back with, as the last of its
stat rows (see **What a lesson remembers**) — which is the same letter asked about
your best run on that page rather than about the run just finished. The clock and
the kill count say how far the run got; those are things you compare with the
last run. A mark is something you are *given* — this is a book of school pages,
and what a school page comes back with on it is a letter in red pen at the top —
so the card says how the run went twice over, once in the numbers the run was
keeping itself and once in the one character a teacher would have written.

The ladder is thirteen steps — `F`, `D-`, `D`, `D+`, `C-`, `C`, `C+`, `B-`, `B`,
`B+`, `A-`, `A`, `A+` — and today the run's length picks one of them, linearly.
`F` for dying on the way in, `A+` for the ten minutes it takes to reach the eye,
and the eleven between them share that out evenly at about forty-six seconds a
grade. Winning is an `A+` outright rather than by the clock: on the win card the
grade is awarded, not measured.

Which means, today, that dying with the eye on the page marks the same as
beating it. That is deliberate and it is temporary. The length of the run is the
only thing the mark reads at the moment, and the whole reason it lives behind
one function (`Mark.forRun`, `src/mark.lua`) is that the things it *should* read
— the body count, the level reached, which lesson it was — can be folded in
without either card knowing that the sum changed. Whether the eye actually went
down has since been folded in somewhere else instead, and deliberately so: it is
worth eight coins rather than a grade (see **The purse**), because a grade is
measured out of ten minutes and beating the eye is a thing that either happened or
did not.

**The ladder is also a price list.** A rung of it is a coin, so the thirteen steps
are the one term of a run's payout that is about having lasted rather than about
having killed — which is what finally pays a run that spent ten minutes hiding
behind pen lines. A step added in the middle re-prices every grade above it, and
`Mark.rung` is the one door to that.

It is drawn in the bold outlined face the damage numbers use (`Font.bold`)
rather than the 3x5 one every other word in the game is written in, because a
mark is not a line of copy, it is a thing written on the page — and it is the
one place in the game that face goes down **without its ring**. The outline
exists for one-pixel figures thrown up over a page full of marks, where a
counter that showed the page through would close up and a `0` would read as a
solid block. A grade is three times that size and it is lying on paper with
nothing behind it, so the ring buys nothing and costs the letter its edge:
outlined, it comes out as a soft blush-haloed shape rather than a stroke of red
pen, and red pen has no outline.

Red, because that is the colour that has been hitting you for ten minutes, spent
once here on the one thing that is finally about you. And it is not translated:
a grade is a letter, not a word, and an `A` is an `A` on either page of the
book.

## Levelling up

Every level holds the run and lays three cards on the page, each with a
selection box under it. You scribble in the box under the card you want, and
that is the only way past them: there is no pause button while they are up,
because a level has to be spent before the run will take another instruction.
The cards are the one thing in the game drawn on paper rather than in ink: they
are laid *on* the page and cover the frozen run underneath, so they can be read
over whatever chaos was happening when the level landed. Everything else about
them is drawn — a wonky border that warms as the box under it fills, and the
scribble sitting in the box the way ink sits on paper. Ink that misses every box
is not an answer, just ink, and goes under the cards and fades.

### The cards arrive, they do not appear

A draft is the only screen in the game you did not ask for. Every other one is
opened by a box you scribbled or a corner you pressed; this one lands in the
middle of a fight, in the second you happen to reach the level, with your finger
already down on the page laying tool strokes at whatever is chasing you. Cards
that simply appeared under that finger were being answered by it — a fifth of a
second of a run you were winning, spent on a card you had not read.

So the cards **slide on**. Laid across the page they come up off the bottom
edge; stacked down it, on a phone held upright, they come in past the left —
each along the axis it is thinnest on, so it is clear of the page in the fewest
pixels and spends the whole slide actually moving. A fifth of a second, which is
the same fifth of a second the wonky borders take to draw themselves on, so a
card finishes being drawn at the instant it lands.

That fifth of a second is not decoration. **Nothing on the screen can be
answered while it runs** — not the boxes, not the three bought buttons in the
corner, not the number keys — and a finger that is down when it ends is stale
just as a finger that was down when it started is: it has to come off the page
and go back on before the draft will look at it. The first thing a draft ever
reads is a press made at cards that were already there to be pressed.

And when one is answered they slide back off the same way, quicker, still
flashing — the answer leaves on the card it was written on. Which is what makes
a reroll read as one deal of cards replacing another rather than as three cards
quietly changing what they say.

The same worry is why **a card is not a target any more**. Tapping one used to
draw the scribble into its box for you, exactly as the number keys do, and that
was a lovely gesture on a screen you walked into deliberately — but a card is a
third of the page across, and one dab of a finger that was mid-stroke could
spend a level on it. What is left is the box, which cannot be answered by a dab:
it measures ground covered, and six cells of it. The tap is still in the code
behind a flag, because the day the draft stops interrupting a fight it is the
right gesture again.

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
asked. On a fusion they are the same thing — one level by nature, so the
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

### Three things you can do to a draft

A run that has been to the canteen has buttons in the bottom corner, one for each
thing it bought there *that is spent here*, with the number of uses it has left
written over it. The counter sells one thing that is not — a retake, spent on the
frame the run would have ended (see **The retake**) — and it has no button on this
screen, because a button you can press that does nothing is worse than no button at
all: it would read as a use the draft was refusing. They
are three different answers to *these three cards are wrong*, and keeping them
different is the point of having three:

- **Reroll** asks again. Three fresh cards off the same catalogue, and nothing is
  spent but the use — the level is still there to be spent on whatever comes up.
- **Skip** withdraws the question. The level is gone, and ten coins are added to
  what the run pays out at the end of it. It is the only one of the three that
  *pays*, and the only place in the game a run turns something it earned into
  something the book keeps.
- **Expel** answers about one card instead of about the three. The line it names is
  out of the run for good — the draft will never offer it again, at any level — and
  one fresh card takes its place. The other two stay exactly where they are, which
  is the whole difference between this and a reroll: expelling is an opinion about
  one card, so it may not quietly re-ask the other two.

Expelling deliberately does not give back the levels of that line the run had
already taken. It is a refusal of the *rest* of a line, not an undo — a run with
two levels of the orbit that throws the line out still has two levels of orbit.

**A level is a use.** Each of the three can be bought up to three times, and every
level buys one more use per run and nothing else — which is exactly why they are
not upgrade lines, where a level is written as whatever it changes and one line can
sell four different things down its length.

The buttons are **pressed rather than answered**, on a screen where everything else
is a box you scribble in, and that looks like the one place this game breaks its own
rule until you look at what pressing one does: it does not answer the question, it
changes what the question is. Reroll asks again, skip withdraws it, and expel turns
the three boxes from three ways of saying yes into three ways of saying never again
— so the one part of it that cannot be taken back is still taken the only way
anything on this screen is taken, by scribbling a box. Which is also why expel is
the only one that *arms* on the press instead of acting: it is the only one with a
target. Pressing it again puts the boxes back, and while it is armed the button goes
red and the line under the cards says what a box now means.

All three take the use the moment they are pressed. A reroll that deals three worse
cards is still a reroll spent, exactly as a level taken on a line that turned out
wrong is still a level — a perk that only charged you when you liked the result
would be a perk with no decision in it.

They sit in the corner **opposite the thumb stick**, which is the tool selector's
own rule: one hand walks and the other draws, so everything you press belongs to
the thumb that is not on the stick. There is no stick while a run is held, but a
corner you have spent the last ten minutes not putting your thumb in is still the
corner to put a button in. The row reads *out of* that corner, so the first of them
is nearest the thumb whichever corner it is, and it keeps a wider margin off the
edge than the corner button does — that one is alone at the top of the page, and
this is three thumb targets in the corner a thumb comes at from off the screen.
That margin is measured off the experience bar and not off the edge itself. The
bar runs the whole width of the foot of the page, so the bottom of the safe area
is a readout rather than free page, and a row of the widest touch targets in the
game standing on it would take the finger five pixels before the box did.

Each is the tool selector's box with a tool-sized drawing in it, which is what the
row is: a die, a fast-forward and the red cross that is the teacher's tick the other
way round. They are that size and not the corner button's smaller one because a
thing you press with a picture on it is a box this game already has, and it is the
one in the margins.

**The cards do not move to make room for them.** They were given a reserve at first
and it was taken away again: it meant a run that had been to the canteen read its
cards a dozen pixels higher up the page than a run that had not, so where the
question sat depended on what you had bought weeks ago. The cards are the question
and they get the middle of the page in every run, with or without a corner full of
buttons.

A button with nothing left in it goes grey, keeps its place and shows a `0`. A line
the run never bought has no button at all: these are things you have, not things the
screen is offering, and a run that has bought nothing sees exactly the draft it
always did.

### The ladder

A level costs `0.9 × level² + level + 5` experience, and the shape of that —
quadratic, not exponential — is the whole reason a run gets anywhere.

It used to be a ratio: every level 1.35× the cost of the one before. That sounds
gentle and is not. A ratio compounds, so by level 30 one level wanted 40,000
experience — six minutes of a horde at full tilt for a single card — and a run
simply stopped levelling somewhere around 28 however long you survived. Which
put the real ceiling on a run nowhere near the draft's: the slot caps below
leave room for **63 picks**, so over half of what a run was *allowed* to learn
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
— it is the level at which a run has learned everything its five weapons, four
tools and five passives can teach it, and the point where the draft starts
offering the endless lines instead. It is 63 picks and not 65: one weapon slot
and one tool slot are spent before the first frame, and neither of those two
levels is a pick. It was level 60 and 59 picks until `SHOT` and `SWORD` grew four
levels each — those eight pushed the last real pick four rungs up the ladder, and
the minute it lands on out with it.

**You are not meant to get there before you win.** The eye boss walks on at
minute 10, and a run that kills it wins with roughly two thirds of a build:

| Build | Level at the minute-10 boss | Picks taken |
| --- | --- | --- |
| Slow clear | 37 | 36 of 63 |
| Middling | 40 | 39 of 63 |
| Fast clear | 44 | 43 of 63 |

That is the intended shape rather than a shortfall. Winning is something you do
with the run you have managed to build in ten minutes, and a finished build is
what `ENDLESS` is for — carrying on past the first boss reaches level 60 somewhere
between minute 16 and minute 25 depending on how fast the build clears.

Which is what makes one number in `Enemy.new` load-bearing: **experience scales
with the hp multiplier.** Health compounds 15% a minute, so a blob in the
fifteenth minute takes seven times as long to kill as one in the first and a run
clears a seventh as many; if it still paid the 1xp written in `Enemy.types` the
horde would quietly pay less every minute while the ladder went on asking for
more, and a run would stop levelling somewhere in the second cycle however well it
was going. Tying the two together keeps experience-per-second flat — the ladder
still slows as it climbs, which it should, but it slows because levels cost more
and never because the page stopped paying. It is also the line that lets the
health curve be as steep as it is: make it steeper tomorrow and the xp follows on
its own.

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
  (`src/rocket.lua`) leaves — a volley of them, down some of the eight compass
  headings, picked out of a hat rather than aimed at anybody. The sun (`src/sun.lua`) is
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
  how often everything that fights for you comes round, how far xp comes to you
  and what it is worth when it gets there,
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
sharpener, `scaleCost` for the blotter, `scalePersistence` for the fixative, and
`scaleKnock` for the shove, which is the one of the four at rest: the elastic
band was the line that moved it and it is off the roster, so the walk is the
identity until something is written on that axis again. Landing last is what makes them compose
properly with a tool's own line: the blotter discounts the ruler you have,
including the ruler level that already put its price down to 0.22.

Two more do the same job on the **weapon blocks**, in the same place and for the
same reason — `scaleWeaponPersistence` for the other half of the fixative and
`scaleCadence` for the metronome, both landing after every weapon's own levels,
so the metronome shortens the gap the bomb's own line already halved. Writing
into those blocks is safe for exactly the reason the tool copies are: the replay
builds them fresh out of `Upgrades.baseStats` every time, so nothing shared is
ever scaled and nothing is scaled twice. It is also the one difference worth
knowing between the two kinds of global multiplier: a weapon reads
`passiveDamage` at the moment it uses it, because damage is a number a rocket
carries away with it, and it never reads either of these at all, because a clock
is a number the weapon is still standing next to.

All four multiply rather than add, and in two of them that is doing real work
rather than just being tidy. A knock of 0 stays 0, so the three tools written
without a shove would keep not having one whatever was put on that axis — which
is why the walk stays written as a multiplication with nothing selling it. And a
`life` of 0 stays 0, which is what
keeps the rubber — the one brush that leaves nothing behind — leaving nothing
behind however much fixative a run has taken.

### What is in the draft

Thirty-seven lines, a hundred and fifty-nine levels between them, three
offered at a time. A
line whose tool has been shelved is never offered — taking a row out of
`Tools.list` takes its upgrades out of the draft with it, the same way it takes
it off the selector.

All thirty-seven are readable before the run starts, on their own shelves and with
every level written out, in [the library](#the-library) off the timetable. Three
cards at a time out of a hundred and fifty-nine levels means most of the
catalogue is something a run is never told about; that is the screen that tells
you.

**A run cannot carry all of them.** There are five slots for passive weapons,
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
column, `1/5` under the weapon column and `3/5` under the row of passives**, in
slate until the kind is full and in red once it is. That last state is the one
worth having — full is the moment the rule starts applying, and without it a
card that stops coming up reads as luck rather than as a rule. The counters are
drawn even at `0/5`, which is where the passives start and where the weapons and
the tools no longer do: a run opens holding one of each, so those two columns open
at `1/5` and `1/4` with the thing the character and the lesson handed over already
in them. A readout that only appeared once you owned something would be explaining
the rule to the people who had already worked it out.

They follow the same rule the levels do: held screens only. Mid-run the page is
the thing you are reading, and a number in the margin is a number in the way.
Nothing moves when they appear — a counter hangs *below* its column rather than
being centred with it, so pausing does not slide the selector you were pressing
up the page to make room.

The tool cap is the tightest of the three, and it is a different kind of rule
from the other two, because **a tool line's first level hands you the tool
itself**. The strip is drafted, not issued. A run does not begin holding ten
tools — it begins holding whichever one the lesson hands it (`tool` in
`src/subjects.lua`), taken as the run is built, and the other three slots are
empty until the draft fills them.
So what those four slots are really offering is three.

That is the whole reason for unlocking them. Ten tools you can all reach are ten
tools none of which you had to choose between: the strip was a menu, and a menu
is not a decision. Four are a hand.

The weapon cap is the tool cap's rule word for word now, and for the same reason:
**a weapon line's first level is the weapon turning up**, so the sky is drafted
rather than issued too. A run does not begin with twelve weapons or with none — it
begins with whichever one its character carries (`weapon` in
`src/characters.lua`), taken as the run is built, and the other four slots are
empty until the draft fills them. Which is why the number went from four to five
when `SHOT` and `SWORD` became lines: a run drafts as many weapons as it always
did, and the one it came in with is now counted honestly instead of riding along
outside the rules.

All three caps bite. Twelve lines for five slots means every run gives seven
weapons up and the choice is which — and the cap stays a step under the catalogue on
purpose, because a cap level with it is a rule nobody ever meets. The passive cap
bites hardest by count (fourteen lines competing for five slots) and the tool cap
hardest by consequence (ten for four, one of them spent before the first frame).
The one way a slot ever comes *back* is a fusion, and it is covered in its own
section below. There are forty-five of them — one for every pair the ten lines can
make — in four families: nine off the compass, eight off the pushpin, seven off the
ruler and twenty-one off the stroke, the seam and the scissors' own taps, six of those
the pencil's — and a fusion eats the two lines it is
made of, so a run that
went down that road is choosing between them rather than collecting them. Two that
share no ingredient can be held at once, which is the only route to a strip with two
fusions on it.

What that costs is worth being plain about. A run can reach 20 of passives, 25 of
passive weapon and 20 of tools — so **65 of the 190
in the catalogue**, a little over a third of it. It is exact for all three now
that every tool line is five long too, where the tool end used to be a range: no
line in the catalogue is an unlock and nothing after it any more except the
fusions, which are one level by nature. A run down the fusion road reaches a
little past 65, since a fusion hands a slot back. The catalogue dries up at that point, which on a long run
happens while the horde is very much still arriving. That is the intended end
state rather than a corner case, and it is the price of a draft that makes you
choose.

What happens *after* it is the endless lines, and they are covered in their own
section below. The short of it is that the draft goes on coming up: a level
reached past the last real pick is still a level, and is still asked about.

| Line | Kind | Levels |
| --- | --- | --- |
| **SHOT** | passive weapon | the shot you draw yourself going out at whatever is nearest, on its own slow beat, from a third of the page away — then coming round half again as often, then flying half again as fast, then hitting twice as hard, then two pellets on every beat |
| **SWORD** | passive weapon | the sword you draw yourself cutting a 140-degree arc through everything at arm's length for double, on a beat half again as long — then reaching seven pixels further out, then sweeping wider than a half circle, then knocking back whatever lived through the cut, then going all the way round |
| **STARS** | passive weapon | a star you draw yourself orbiting you, then two, twice as fast, three in a triangle, an orbit that breathes in and out |
| **ROCKET** | passive weapon | two rockets you draw yourself going off down two of the eight compass headings nobody picked and through whatever is standing in the way, then four at once each going through two, then through three, then every one of them bursting in a circle where it stops, then eight at once — one every way |
| **COOL S** | passive weapon | a cool S you draw yourself coming in off the page from a direction nobody picked, crossing it through where you stand and cutting everything on the line — then bouncing off the far edge, then twice as often, then bouncing off your own pen lines too, then one that stays on the page for good and never stops bouncing |
| **SUN** | passive weapon | a sun with a face you draw yourself rising in a corner of the screen and burning what it covers, then burning deeper and staying up longer, then reaching further and pulsing as it burns, then a second sun in the opposite corner, then sunrays shooting out of it across the page |
| **LASER BEAM** | passive weapon | a pointer turning with you to say where you are walking, a hairline flashing down that line, and a beam firing along it to the edge of the page at any angle at all — then holding instead of flashing, then coming round twice as often, then cutting a wider band, then a second beam out behind you |
| **BOMB** | passive weapon | a bomb you draw yourself dropping at your feet, sitting there while its own outline flashes blue, and blowing up everything still standing in the circle — then a crater half again as wide, then one dropping twice as often, then a fuse burning twice as fast, then a crater that goes on burning after the bang |
| **SKATE** | passive weapon | a skate you draw yourself, drawn under your feet in place of your shadow, leaving a light blue trail behind you that cuts whatever is following you down it — then a trail that takes their footing, then one that cuts far deeper, then a fresh end that carries *you* faster, then every gem lying on it coming to you |
| **STORM** | passive weapon | a cloud rolling in from off the page in a direction nobody picked, following somebody chosen at random out of the crowd, filling up over them and putting the lightning bolt you drew yourself through the paper — then a wider circle taken with it, then a second cloud, then a cloud that stays and strikes three times instead of leaving, then a bolt that everything it fails to kill hands on to whoever is standing near it, and on again for as long as the crowd carries it |
| **M BIRDS** | passive weapon | one m-shaped bird you draw yourself wheeling round you and nicking one point off whatever it brushes past — then a flock of five, then a bite three times as deep, then three more with a couple of them peeling off to fetch the gems you walked away from, then a swarm you are standing inside instead of a loose shell following you about |
| **SPIRALS** | passive weapon | a spiral winding itself onto the page somewhere near you and drawing everything nearby into the middle of it — then two at once and twice as often, then a wider reach, then a longer stay and a hold nothing walks out of, then one round your own feet for the rest of the run that pushes instead of pulling |
| **PENCIL** | tool | the tool you start the run holding, and the one slot of four you never chose — then a deeper scratch, a broader point pressed harder, lines that get cheaper the longer they run, and a closed loop cutting everything inside |
| **PEN** | tool | the pen itself, then a broader nib laying a thicker wall, a line that stings whatever leans on it, a line that takes the crowd with it when it goes, and a last line that stays until you draw another |
| **STAPLER** | tool | the stapler itself, then a deeper drive, one staple in five going straight through, every staple torn back out of the page two seconds later for a second bite, and a held finger running a seam of them instead of a tap placing one |
| **RUBBER** | tool | the rubber itself, then a longer throw, a tip that shoves at rest, half-price re-rubbing, and what it sends flying knocking down what it hits |
| **MARKER** | tool | the highlighter itself, then a wider band, a deeper burn, layers that stack where you draw over your own ink, and anything that touches the band catching fire |
| **GLUESTICK** | tool | the gluestick itself, then a wider smear, deeper cuts into whatever it holds, a tear on the way loose, and a smear that pulls everything near it in |
| **PUSHPIN** | tool | the pushpin itself, then a longer hold, a wider circle, double on the body the point falls on, and every kill under the circle driving the point deeper into the survivors |
| **RULER** | tool | the ruler itself, then wider, harder, longer and wider again, and long enough to rule the whole page |
| **COMPASS** | tool | the compass itself, then wider, biting double where the lead sets off, twice round and cutting far deeper, and a second leg coming the other way |
| **SCISSORS** | tool | the scissors themselves, then a cut as long as you tap, then blades that bite deeper and wider between your two taps, then a cut that runs on past both of them to the edges of the page, and then the half of the page you are not standing on cut off it |
| **HALO** | tool (fusion) | the marker put in the compass, which you cannot be offered until MARKER, COMPASS and FIXATIVE are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and left burning on the page the way a finished marker's band burns |
| **LASSO** | tool (fusion) | the pencil put in the compass, which you cannot be offered until PENCIL, COMPASS and SELLOTAPE are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and closing on everything standing *inside* it the way a finished pencil's loop does |
| **MOAT** | tool (fusion) | the gluestick put in the compass, which you cannot be offered until GLUESTICK, COMPASS and SELLOTAPE are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and left lying on the page as a band of paste that holds, softens, tears and pulls exactly the way a finished smear does |
| **PUNCH** | tool (fusion) | the scissors put in the compass, which you cannot be offered until SCISSORS, COMPASS and TOP MARKS are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and whose middle *lifts off the page* the way a finished cut lifts off the half you are not standing on |
| **SPINDLE** | tool (fusion) | the pushpin put in the compass, which you cannot be offered until PUSHPIN, COMPASS and FIXATIVE are all finished, and which eats the first two — a circle you open the way you open a compass, whose leg carries the pin's whole crater round the rim instead of dropping it, picks up the first thing it fails to kill, drags it round impaled on the point, and drives a real pin through it into the page where the arm stops |
| **CORRAL** | tool (fusion) | the pen put in the compass, which you cannot be offered until PEN, COMPASS and SELLOTAPE are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and left lying on the page as a *wall*: the pen's own fence with no ends on it, stinging whatever leans on it, popping when it goes, and staying there until you swing the next one |
| **HEM** | tool (fusion) | the stapler put in the compass, which you cannot be offered until STAPLER, COMPASS and FIXATIVE are all finished, and which eats the first two — a circle you open the way you open a compass, cut the way a finished compass cuts it, and *stapled the whole way round* as the leg travels: one every 12px of rim, so the wider you open it the more staples it holds and the more the cast costs, and the drag can only open as far as the meter can pay for |
| **CLEARING** | tool (fusion) | the rubber put in the compass, which you cannot be offered until RUBBER, COMPASS and MAGNET are all finished, and which eats the first two — a circle you open the way you open a compass, and the one that touches nothing but its own *middle*: as the leg comes round, everything inside the disc it has swept is thrown straight out of the ring and launched, at the rubber's own 240, and the page is left exactly as it was found. The nine compass fusions all share the compass, so a run may only ever make one of them |
| **FOLD** | tool (fusion) | the ruler put in the compass, which you cannot be offered until RULER, COMPASS and CARTRIDGE are all finished, and which eats the first two — the plain compass, unchanged, with nothing on the leg at all: draw a second circle while the first is still on the page and, where the two rims cross, the ruler comes down flat on the line between the two crossings. The nine compass fusions all share the compass, so a run may only ever make one of them |
| **DOT TO DOT** | tool (fusion) | the pencil joined to the pushpin, which you cannot be offered until PENCIL, PUSHPIN and CARTRIDGE are all finished, and which eats the first two — a pin you tap and drop the way you tap and drop a pushpin, with the pencil joining up the ones that land within 80px of each other: a graphite line between every pair, scratching at the pencil's own 9, and a *circuit* of them cutting everything the shape holds the way a finished pencil's loop does. The seven pushpin fusions all share the pushpin, so a run may only ever make one of them — but nothing stops one of these and one compass fusion being on the same strip |
| **STOCKADE** | tool (fusion) | the pen joined to the pushpin, which you cannot be offered until PEN, PUSHPIN and CARTRIDGE are all finished, and which eats the first two — the same tap and drop, with the pen joining the pins instead: every rail is the pen's own fence, stinging whatever leans on it and popping when it goes, and every post is a 51px crater with a pinned tank in it. A fence in whatever shape you tapped it, standing for as long as its posts are driven |
| **CORDON** | tool (fusion) | the highlighter joined to the pushpin, which you cannot be offered until MARKER, PUSHPIN and CARTRIDGE are all finished, and which eats the first two — the same tap and drop, with a 15px band of sky strung between the pins: it stops nobody and burns at the marker's own 5 a tick to whatever stands on it, setting alight anything that so much as crosses. Tape between two posts, and a crater at every corner |
| **SNAP LINE** | tool (fusion) | the ruler aimed by the pushpin, which you cannot be offered until RULER, PUSHPIN and CARTRIDGE are all finished, and which eats the first two — the same tap and drop, and what appears between two close pins is the *finished ruler*: not the hundred and twenty pixels between them but the whole page, corner to corner, at 13 across with a 210 shove off both sides at once. The pins do not bound the line, they aim it, so a hundred-and-twenty-pixel baseline decides where four hundred pixels of it land |
| **TEAR LINE** | tool (fusion) | the scissors driven into the page, which you cannot be offered until SCISSORS, PUSHPIN and CARTRIDGE are all finished, and which eats the first two — two pins are the scissors' two taps, so the page opens along the line through them and runs on to both edges: 20 across 6 between the pins, 12 across 3 the rest of the way, and the half you are not standing on lifted off with everything on it. The scissors' first tap used to be free and do nothing; now it is a 51px crater you can see while you choose the second |
| **TACK** | tool (fusion) | the gluestick poured round the pushpin, which you cannot be offered until GLUESTICK, PUSHPIN and SELLOTAPE are all finished, and which eats the first two — one pin rather than two, and no thread: a 51px pool of paste exactly the width of the crater, so what the pin killed is cleared and what it spared is stuck in the paste, softened by half again, torn on the way loose, with everything free dragged in from a hundred pixels across |
| **VOLLEY** | tool (fusion) | the pushpin worked like a stapler, which you cannot be offered until STAPLER, PUSHPIN and FIXATIVE are all finished, and which eats the first two — the only fusion whose two parents already share a gesture, so nothing is strung or pooled and what is fused is the tap itself: the crater lands **the instant you tap**, with no fall to dodge and one hit in five going straight through at triple, and holding the pointer down rakes a seam of them 48 apart, which is where the parent's own circles just stop overlapping. A tap is still one pin. A quarter of a meter each, so a meter is four |
| **CRATER** | tool (fusion) | the rubber packed into the pushpin, which you cannot be offered until RUBBER, PUSHPIN and MAGNET are all finished, and which eats the first two — one pin again, and nothing is left on the page at all: everything the circle caught and did not kill is thrown straight out of it at the rubber's own 240, twenty-seven pixels, and knocks down whatever it lands on for 5. The pin's own row has called its circle a crater since it was written; this is the row that makes it one |
| **MARGIN** | tool (fusion) | the pencil ruled against the ruler, which you cannot be offered until PENCIL, RULER and SELLOTAPE are all finished, and which eats the first two — the finished ruler, unchanged, and then a graphite line ruled down **both long edges** of the band it landed on, page-wide, at the pencil's own 9. Which is the pair of dashed lines a ruler's aim has always drawn made real, and it puts the graphite exactly where a ruler was weakest: inside the band you took 12 and a pixel outside it you took nothing. The only one of the seven that costs the corridor nothing |
| **SPINE** | tool (fusion) | the pen ruled against the ruler, which you cannot be offered until PEN, RULER and SELLOTAPE are all finished, and which eats the first two — the page's whole diagonal as *wall*, laid in the frame you let go, against the hundred and seventy pixels a pen draws from a full meter. The page is in two. It has no clock on it: ruling the next spine is what lets the last go, and the old one comes off the paper all at once and takes the rank leaning on it. What holds it down is the camera — it divides where you *were* |
| **UNDERLINE** | tool (fusion) | the highlighter ruled against the ruler, which you cannot be offered until MARKER, RULER and FIXATIVE are all finished, and which eats the first two — a 13px burning band from one edge of the page to the other, under everything else on it, at 5 a tick with layers where they cross. And the ruler's shove is what feeds it: everything in the band is thrown out *across* the fire on the way, and touching it at all is two seconds of burning that travels with the body |
| **TRENCH** | tool (fusion) | the gluestick ruled against the ruler, which you cannot be offered until GLUESTICK, RULER and SELLOTAPE are all finished, and which eats the first two — a page-wide bar of paste, and the one fusion here that does *not* open a lane: paste holds, a held body drops the shove it was given, so what lands is 12 across the band and the whole crowd standing exactly where it was, stuck fast for six seconds, cut half again as deep by everything else you own, torn on the way loose, with the free dragged in |
| **PARTING** | tool (fusion) | the rubber run along the ruler, which you cannot be offered until RUBBER, RULER and MAGNET are all finished, and which eats the first two — a rubber leaves nothing, so nothing is left in the lane and the *band comes off the block instead*: what this lands on is every enemy within the ruler's own length of the line, which on a page-wide ruler is the page. The whole crowd, chipped for 2 and thrown straight away from the line you pointed, bowling each other over for 5 on the way. What you choose is an axis |
| **SEAM** | tool (fusion) | the stapler run along the ruler, which you cannot be offered until STAPLER, RULER and SELLOTAPE are all finished, and which eats the first two — one staple every twelve pixels of the line, so a page diagonal is a little over thirty of them: 6 each with a fifth going straight through at 18, everything caught fastened to the paper, and the whole line pulled back out two seconds later for another 6 apiece. It does not shove, and at 0.9 it is the dearest single press in the game, because wire cannot be free |
| **GUILLOTINE** | tool (fusion) | the scissors run along the ruler, which you cannot be offered until SCISSORS, RULER and TOP MARKS are all finished, and which eats the first two — the page cut open along the same line, edge to edge, with the blades travelling down it. 12 from the band and 20 from the blades is 32, the deepest single hit in the game and two short of the grin. And the half you are not standing on goes with everything on it — except that a ruler's line goes *through* you, so this is the one cut that never stops asking: straddle the slit and neither half goes, step off it and the half you left goes, cross back and it is the other one |
| **SHARPENER** | passive | +20/25/30/40% damage from everything you *draw* |
| **GRAPHITE** | passive | the same four steps, for everything that *fights for you* |
| **METRONOME** | passive | everything that fights for you comes round sooner, four times over |
| **MAGNET** | passive | xp comes to you from 44px, then 62, 80, 104 |
| **TOP MARKS** | passive | every gem is worth more, four times over |
| **PAPER PLANE** | passive | you move faster, four times over |
| **FRESH PAGE** | passive | +20 max health, handed over full |
| **SELLOTAPE** | passive | you heal on your own, four times over |
| **BANDAID** | passive | you heal off what your *weapons* deal, four times over |
| **INKWELL** | passive | +30 ink in the meter, handed over full |
| **CARTRIDGE** | passive | ink comes back faster, and starts sooner |
| **BLOTTER** | passive | everything you draw costs less ink |
| **FIXATIVE** | passive | what you *draw* lasts longer, and holds what it caught longer |
| **LAMINATE** | passive | the same four steps, for what *fights for you* leaves lying on the page |

Every line taken to the end would be 1.39× as fast, 190 health mending at 1.8 a
second, hitting 2.73× as hard with both halves of the
game and coming round 1.73× as often, levelling 1.83× as fast, holding 2.3 meters
of ink that costs 0.58× as much
and comes back 2.28× as quickly, leaving marks that last 2.16× as long, with a
sun up for 15 seconds out of 18 and a crater burning for
nearly nine, three
stars going round it at a turn every 1.2 seconds and
eight rockets going out every second and a bit, each through four things and
bursting in a circle where it stops.

No run gets all of that any more, and that is the point of the slots above: five
of the twelve weapons and four of the ten drafted tools — one of each decided for
you, by
the character and by the lesson — and five of the fourteen passive lines. The numbers above are what
each line is worth to the run that spends a slot on it.

The four ink lines are where the draft grew most, and the reason is that until
they existed the whole drawing half of the game answered to one meter that no
upgrade could touch: the sharpener made what you drew hit harder, and nothing
made you able to draw more of it. They are deliberately four rather than one,
because they are four different things — how much you can hold (**inkwell**),
how fast it comes back (**cartridge**), how far it goes (**blotter**) and how
long what you drew goes on working once it is down (**fixative**). A bigger well
does not refill any faster, which is the trade that keeps the first two apart;
taken together they land almost exactly on top of each other, a well 2.3× the
size refilling from empty in 3.36 seconds against the 3.33 it always took.

**Fixative** is the one that is not about the meter at all — it is grouped with
them because what it stretches is what the meter paid for. It moves how long a
mark stays on the page and how long it holds whatever it caught, which are the
same idea read off either end — a glue smear that lasts longer sticks things
down for longer by definition. It is worth the most to the two tools that do no
damage at all: a pen wall drawn in a panic goes from 9 seconds to 19, and the
gluestick's hold from 0.55 to 1.19.

What it deliberately does *not* stretch is the ruled line a ruler leaves or the
circle a compass leaves — those landed their hit on the swing and have already
done everything they are going to do, so lengthening them would put nothing on the
page but old pencil. The highlighter's burn is out for the sharper version of the
same reason: a longer freeze *holds* for longer, but a longer burn just deals
more, and damage bought through the persistence card is the sharpener's job
wearing the fixative's. A hold lengthens; a burn does not.

**Laminate** is the fixative's other half, and the two are separate lines for the
reason the sharpener and the graphite are: a run that draws for a living and a run
that stands still and lets the page fight for it are two builds, and one card
worth taking to both is a card neither of them had to choose. Its four steps are
the fixative's to the decimal — two halves of one axis climbing at different rates
would be a run reading the same sentence twice and getting two different numbers
out of it, which is exactly what the two damage lines share `RISING` to avoid.

What it moves is **how long the thing is there**, which is the metronome's rule
read the other way round: that line sells the gap between one thing a weapon does
and the next, this one sells the thing. Between them they cover every length of
time on a weapon block and they never reach the same field, so a run holding both
cards can tell what each of them bought.

Five of the twelve weapons have something for it, and what those five have in
common is that all of them put something on the paper and leave it there:

| | | |
| --- | --- | --- |
| **SPIRAL** | 5s on the page → 10.8, and its grip on what it caught 1.5s → 3.2 | the least arguable of the five: this weapon does no damage at all, so a hold is the entire thing there is to lengthen |
| **SKATE** | a stamp of trail 3s → 6.5 | where the line is worth the most of anything it touches, since the trail is the only thing in the game whose *size* is a length of time — and on a run that also took the paper plane that is most of a page of line behind you instead of half of one |
| **BOMB** | the crater smoulders 4s → 8.6 | ground you took away, so what the seconds buy is how long that stretch of page is somewhere the crowd cannot walk |
| **SUN** | 7s at full height → 15.1 | `stay` only. Rising and setting are transitions, so stretching those would slow the animation down instead of leaving the disc there for longer |
| **LASER BEAM** | the light is across the page 0.9s → 1.9 | worth nothing at all until that line's second level turns the flash into a beam, and then worth as much as anything here |

The other seven *happen* and are over — a rocket goes up, a bolt comes down, a
swing takes the arc it takes — so there is nothing on them to sell. What the line
deliberately does not reach is a journey or a wait: a rocket's `life` is time of
flight, so stretching it would be **range** — which with the aiming gone is most
of what an unaimed volley is worth, and is exactly why this is the entry here it
would be easiest to talk yourself into. Its own line sells the shape of the volley
instead, on purpose; a fuse and a wind-up are each the half of their weapon you *play*, and
both are sold by their own line on purpose; a cool S has no life at all, since
what ends one is the viewport running out from under it; and every `tick`
everywhere is a rate rather than a length — how often something already on the
page hurts, which is what the graphite is for.

The one duration a card like this must never touch is the sun's `soak`, the
seconds under the disc before a survivor carries the bleach out. Multiplying that
up makes the mark *harder* to earn. It is the compass's `sweep.turn` again — the
second length of time in this game where more is worse, and the second reason both
persistence passes are lists rather than walks over anything that looks like a
number of seconds.

It also raises the same question the fixative's exclusions do, and from the
opposite side: the highlighter's burn is left out of the fixative and the bomb's
crater is in here, and from a distance those look like the same thing. They are
not. `ignite` is a *body* burning — something that touched the band is on fire, and
how long it burns is how much damage that one hit ends up doing, which is the
sharpener's to sell. A crater is a *place*. One is damage with a duration attached;
the other is ground, and ground is what this axis is for.

**Metronome** is the third axis of the same thing the two damage lines are: not
what a hit is worth but how often one lands. Until it existed only the first half
was for sale — each weapon line decides how often that weapon comes round, and
nothing pointed at all of them at once. Its four steps are the blotter's to the
decimal, and that is the whole of how they were picked: those are the two lines in
the catalogue that make a number *smaller*, so they make it smaller at the same
rate. Taken to the end everything comes round 1.73× as often, which is well under
the 2.73 either damage line is worth — the right way round, since a rate
multiplies whatever those did.

What it moves is the **gap** and never the thing itself. The nine `every` fields,
the sun's `gap` below the page, the sunrays' volley, and the star's and the flock's
`rehit` — the interval between one cut of the same enemy and the next, which is the
only cadence either of those two has — are all one idea and all move. A wind-up, a
fuse, a sun's time up, the length of a beam and every *tick* something already on
the page hurts on do not: a shorter fuse is a level of the bomb's own line and this
must not quietly sell it twice, and a faster tick is damage per second wearing a
cadence's card, which is the fixative's exclusion rule read the other way round.

One place it pays out more than anywhere else, and it is allowed to. The beam's
rest is what is left of its period once the wind-up and the light have taken
theirs, so shortening the period comes out of the gap alone — and a run holding
the whole of both lines has 1.45 seconds of period against 0.6 of charge and 0.9
of beam, which is no gap at all. `Beam:rest` was already written to floor there
rather than run backwards, so what that run gets is a weapon that is never idle:
the pointer starts winding up on the frame the last beam goes out.

Not a beam that never stops, which is worth being exact about — the wind-up is a
phase of its own and the rest is what runs out, so a floored rest still has 0.6
seconds of charge behind every beam, and this line still refuses to sell that. The
**laminate** reaches the same floor from the other side, by lengthening the beam
rather than shortening the period, and neither of them can go past it.

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

**Nothing points at the shove**, and that is a removal rather than a gap. The
elastic band did — a passive multiplying the knock on every tool copy, four
levels of it — and it is off the roster, catalogue line and endless answer both.
Only three tools have a shove worth scaling (the ruler, the rubber and the
compass), so it was a passive that behaved like a tool line: a run drawing pen
walls got nothing from it at all, and the sharpener already makes that trade
against a run that only fights with what it was given. One of those is a fair
price for a deep draft and two is a passive shelf you learn to read past. The
axis itself is still plumbed — `stats.knock` is at 1 and `scaleKnock` walks it —
so putting it back on sale is a row in `Upgrades.list` and nothing else.

The numbers that matter most are the ones that say what a line *is* rather than
how big it is. The stars start at 4 damage — a blob outright, a skull in three —
so the first level of a passive weapon is worth taking without being worth
taking over everything else. Their sixth and last level is the one that changes
the weapon rather than its numbers: a ring only ever touches things at one
distance, and a ring that breathes sweeps everything between two, which is why
that level and not another buys eleven pixels of amplitude.

The rocket is the same shape of line pointed the other way, and the one thing to
know about it is that **it is not aimed at anything**. A volley goes off down
some of the eight compass headings, picked out of a hat, so what a rocket costs
the crowd is standing in the way rather than being the nearest thing on the page.
It used to fly at whatever was closest inside 110px, and giving that up is the
whole line: every level is now about the shape of the volley, and none of them
sharpens a rocket at all.

The eight are exactly the eight headings the drawing is kept at, which is the one
quiet gain in the change — nothing is rounded any more. A rocket used to fly at
whatever angle its target happened to be at and be drawn with the *nearest* of
eight sprites, so the drawing pointed a few degrees off its own line; now the
line is a heading and the drawing points along it exactly. Four of the eight are
the drawing as drawn and four are resampled, so a volley of four or eight flies
both kinds at once and a board drawn thin shows that cost rather than hiding it.

A volley takes headings it has not already taken, never the same one twice: two
rockets down one line are one rocket with a bigger number on it, and the finale
is not a lucky roll but the whole compass, every time.

The trade runs the other way from every other weapon's opening level, and that is
worth saying plainly: this is now worth **less** against one straggler than it
was and considerably more against a crowd. So it opens as two rockets rather than
one, each already going through the first thing it meets — an unaimed rocket that
stopped at a blob would be a level you took and could not see. 8 damage is
untouched and stays untouched: it clears a blob or a bat outright and leaves a
skull on 4, and a run that wants each one landing harder buys the graphite rather
than a level of this.

The second level doubles the volley and the pierce at once, which the old line
spent two separate levels on and could afford to while a rocket was fired *at*
somebody: four of the eight is the first volley that is more of the compass than
not. The third finishes that shape at four through three. The fourth is the one
that changes what the weapon is, and it is the answer to the single thing an
unaimed volley is bad at — a rocket that found nobody used to just stop being
there, and now it **bursts in a 14px circle where it stops**. Half the bomb's
opening crater, which is the honest size for something landing two to eight at a
time against one bomb every four and a half seconds, and 4 damage: a blob or a
bat outright and a skull still standing, so the burst clears the chaff round
whatever the rocket itself was worth without quietly becoming the damage level
this line refuses to sell. The ring it flashes for two or three frames is exactly
the ring that killed, the bomb's rule and for the bomb's reason — a blast with a
radius nobody drew is a blast nobody can learn.

The finale is the plainest one in the catalogue: eight at once, one every way. A
volley stops being a couple of directions the run was dealt and becomes a ring
going out of you.

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
pierce the rocket buys a level at a time is what this weapon *is* — and why one
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
*held* rather than spent, exactly as the storm holds a cloud with nobody to send
it after:
the next one sets off the moment the last leaves. Once the run owns the S that
never leaves there is never room again, which is how that level quietly ends the
clock.

Being uncontrolled is what keeps it honest at the top. A permanent S bouncing
off your own ink is a great deal of damage over a run, and not one pass of it is
pointed anywhere you chose.

The laser beam is the fifth, and it breaks the rule the rest are built on:
**it is the one weapon you aim**. A star turns where it turns, a volley of
rockets goes off down headings nobody picked, the sun owns whichever corner it
came up in and a cool S arrives from a direction nobody chose. All four fight while your hands are busy drawing, and
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
2. **The flash.** Over the last 0.45s before the shot, a one-pixel line in sky
   runs the whole way the beam is about to go, blinking faster as it comes —
   0.15s between blinks down to 0.05s, an accelerating flicker rather than a
   clock, saying *going to* and then *about to*. It is the shot drawn thin:
   what it covers is exactly what the beam will cover.
3. **The beam**, five pixels across the same line: sky through the middle
   with a one-pixel blue edge either side. It leaves from the **tip of the
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
treatment of its disc and works here for the same reason: sky alone is pale
enough to lose against the paper, and blue alone is a solid bar you cannot see
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

The bomb is the sixth, and it is the only one that makes you **wait**. Every
other weapon resolves the instant it acts: a star cuts what it turns through, a
rocket leaves, a beam is a flash, an S crosses. All five are things that happen
*to* the crowd, and none of them leaves anything on the page except a body. A
bomb is put down at your feet and then does nothing at all for a couple of
seconds — so the ground you just walked off becomes somewhere, the crowd walks in
while you walk out, and the most interesting square on the paper is the one you
have just left.

It is not aimed, and the aim is your feet a second ago. That is the cool S's
bargain approached from the other end: an S is a line drawn through where you
were standing, and a bomb is a hole in it. Both are weapons you position by
walking, which is why neither has a targeting rule of any kind — and why the two
sit so differently in a build, since one arrives from off the page and this one is
somewhere you chose to be.

**The fuse is the weapon, and the line is written down it.** It opens at 2.2
seconds, which is a number set against your own walking speed: 58px a second gets
you clear of a 22px crater with time to spare, and leaves whatever was chasing you
inside it. Under a second and it goes off where you *are* rather than where you
were; much over two and the crowd simply arrives after it. 6 damage — a blob or a
bat outright and a skull in two, the beam's opening number — because this covers
an area rather than a line, and the crowd was given a couple of seconds to be
somewhere else. The crater opens at exactly 22px, which is the stars' orbit: the
first bomb takes the ring you already know the size of.

Then **half again as far out**, which is well over twice the paper and the level
that turns the crater from the ring round your feet into a piece of the page.
Then **twice as often**, the plainest level in the line, which turns it from a
thing you place into a rhythm you walk. Then the **fuse halved**, which is really
a level about the crowd rather than about the bomb: half the wait is half the page
the horde gets to cross before it goes off, so what you had to lead things into
starts catching whatever was already following you.

Then the finale, the crater **going on burning** — four seconds of it, cutting
twice a second whatever stands in it. That is the same blot the eye boss drags
behind it (`src/puddle.lua`) in the other half of the palette: sky over blue where
the boss's is blush over red, because this is ground *you* took away rather than
ground taken away from you. It is exactly the crater, so the level that widened
the blast widens the burn without saying so, and the two of them together are what
turn a bomb from a moment the horde has to survive into ground it has to go round.
2 a tick is deliberately the smallest number anything in the game hits for: what
the level sells is the ground, and a burn that killed on its own would make the
bang the part you waited through.

**The blink is the whole readout.** Over the last nine tenths of a second of any
fuse the sprite's own silhouette flashes blue — `drawMask`, the trick the sun's
bleach and the S's rim are built out of — accelerating from a blink every 0.16s to
one every 0.05s, which is the laser beam's flash by another name: an accelerating
flicker says *going to* and then *about to*, and nobody has to count anything. The
nine tenths is a constant rather than a number on the block, and that is what
keeps the short-fuse level honest: it makes bombs go off sooner without ever
making one go off unannounced.

**The whole weapon is blue**, and that is the palette's own rule rather than a
preference: red is the other side of the fight — enemies, their shots, the boss's
puddles — and blue is yours, from the pen and the bullets to the beam. A bomb
flashing red read as something the horde had left on the page
rather than the one thing on it you had put there. So the flash is blue, the blast
throws blue with sky spatter round its rim, and the burn it leaves is sky over
blue — one event in three stages in one half of the palette. What it costs is the
easy contrast a red flash had for free, and the answer to that is the silhouette:
a solid shape going blue at a stroke is not a mark you could have drawn. The one
red left anywhere near it is the speck off something taking a hit, which is red
everywhere in this game and belongs to the thing being hit rather than to the bomb.

The **blast ring** is the other half of the readout. For two or three frames after
the bang a one-pixel blue circle sits at exactly the radius that was damaged, and it is
the only account the player ever gets of how far a bomb reached — the damage lands
in a single instant on things that are dead before you could have looked at them,
so the level that widens the crater would be unreadable without it. It is an
outline and not a filled disc, which is the sun's rule the other way up: the sun
is allowed to hide what is standing under it because not being able to see into
the safe corner is the trade its whole line is written around, and nothing else in
the game may cover the crowd it is killing.

Nothing about a bomb hurts you. It is the one weapon that puts a hazard on the
page, and it is deliberately not one: blue is yours and red is theirs, and a bomb
that could kill you would be a bomb you had to aim away from your own feet, which
is the one place this one is allowed to go.

There is no cap on how many are on the page, which is the cool S's rule not
applying rather than being ignored. An S lives until the page walks out from under
it and three of its five levels make that longer, so a cap is the only thing
keeping the page legible; a fuse is a length written on the block, and no level
makes it longer than the gap between drops. What is on the page is one bomb, or
two for the last fiftieth of a second of a fuse.

The skate is the seventh, and it is the only one that is a **surface**. Every
other weapon is a thing that happens and is over — a star cuts what it turns
through, a rocket leaves, a beam flashes, an S crosses, a bomb goes off — and the
closest any of them comes to this is the crater the bomb's last level leaves
smouldering, which is one round patch of ground somewhere you had already decided
to be. A skate turns the whole line you have walked into that patch, continuously,
for as long as you keep walking.

Which makes it the one weapon aimed with your feet and aimed **behind** you. That
is not the laser beam's question over again: the beam asks whether you will turn
and face a crowd, and this asks whether you will let one follow you. And it is a
question the horde cannot decline, because whatever is closest to catching you is
by definition walking its own centre down the line your centre just left, and
chasing is all the crowd does. Nothing else in the game is paid for by being
chased.

**The line sells that bargain getting better rather than the damage getting
bigger.** It opens at 2 damage every half second, which is the smallest number in
the game on the tick the bomb's burn hits on — and both of those are the point
rather than timidity. This is the only damage anywhere in the game that lands on
the crowd continuously and without being aimed at all, so what the first level
buys is the trail existing.

Then **their footing**, which is the biggest step in the line for what it does to
the shape of a fight rather than to a number: a crowd chasing you arrives in a
lump, and a crowd chasing you down a line that takes two fifths of its legs
arrives strung out along the line, fastest first, which is a fight you can walk
backwards through. It is the crayon's wax pointed at speed instead of at
steering — and unlike the wax it is not a lane you had to draw first.

Then the **cut that finishes them**, 2 to 5, which is the one place in this line
where a number simply gets bigger and it comes third because it is worth most
after the level above it: a crowd standing in the trail for longer is a crowd the
trail has time to kill. Then **the fresh end carrying you**, at 1.45×, which is
the one level that pays *you* for going back over your own line — and deliberately
only the wet end of it, because the stretch you laid four seconds ago is a trap
for the crowd and the stretch you laid one second ago is a road. What that buys is
turning back into your own trail rather than laying a lap and living on it.

Then the finale, **every gem on the trail coming to you**, which is the magnet's
other half in the way top marks is: the magnet buys a radius round where you are
and this buys the shape of where you have *been*, so a lap of the page collects
the lap. It is the one level in any weapon line that pays in xp rather than in
damage, and it can be, because this is the one weapon that leaves a map of the run
behind it.

**The trail is thirteen pixels wide and it fades by getting shorter.** Thirteen
because that is the deck of the board you drew, so what is left on the page is the
width of what left it. The fade is the one on the page that does not dither out:
stamps expire in the order they were laid, so the trail is always one unbroken
chain, and a trail getting *shorter* is what a trail does anyway. It is drawn in
sky with a blue rim, which is the bomb's burn again and the palette's own pairing
for anything of yours — the boss's blot is the same shape in the other half of it.

**The rim is the readout for the boost.** The stretch drawn with its rim on is
exactly the stretch the boost is paid over, and that is one constant in one place
rather than a number the levels can move — a weapon that lied about where its own
boost was would be a weapon you could not learn. Everything else about the
appearance is the overprint doing its job: the trail is sky, so where it crosses a
ruled line it comes out blue, and the rim is blue, so where *that* crosses one it
comes out slate. A band laid across a ruled page is striped by the page it is laid
on, exactly like every other mark.

**The band is laid at your centre and not under the board**, four pixels down, and
that is a compromise rather than a measurement. Every surface in this game is
tested against a body's *centre* — the crowd under a crater, you in a puddle,
anything standing on wax — so a band laid at the wheels would be a band a follower
walked along the top of and never touched. Four pixels is far enough down that the
trail reads as coming out from under the board rather than from behind the hero's
head, since the middle of a nineteen-pixel doodle is his shoulders, and near
enough that a follower is well inside it.

**The hero stops bouncing.** The one-pixel walk bounce is the whole animation
budget of a doodle and having a skate takes it away, which is the whole of what
this weapon looks like from the outside: there is no muzzle, no arc and nothing in
the air, so the animation *is* the readout. A hero who slides instead of bobbing,
with a board where his shadow was.

The m birds are the ninth, and they are the first weapon that is not an *event*.
Everything else that fights for you arrives on a beat you can learn: a star comes
round, a rocket goes up, a bomb goes off, a cloud parks itself overhead. This is a
handful of small things milling about near you all the time, taking a pixel off
whatever they brush past. It opens on the smallest attack in the game — **one
bird, one point of damage** — and it opens there on purpose: nothing else in the
catalogue deals 1, and the whole line is five levels of there being more of it.

**It is the stars read the other way round rather than a second orbit**, and the
difference is that nothing here has an angle. A star sits on a ring bolted to you:
it has a phase, the phase advances, and where it will be in a second is something
you could work out. A bird picks somewhere near the flock to be, banks towards it,
turns as fast as a bird turns, and picks somewhere else when it arrives — so what
it draws on the page is a path, and no two of them are drawing the same one. The
flock's own centre is only *chasing* you on top of that, fourteen pixels behind at
a walk, so the loose knot of them swings wide of a corner and folds back over you
when you stop. A crowd walking into that is cut in a dozen places nobody chose.

Two details are what stop the wandering closing back up into the thing it is
trying not to be. Each next goal is **stepped on** from the last rather than drawn
fresh — a third to two thirds of the way round the flock, usually the way that
particular bird leans — because a fresh random point every time is a fly in a jar
rather than a bird going somewhere. And one step in four goes the *other* way,
which is the part that matters: a bird that always stepped the same way comes all
the way round eventually, and the envelope of its path is a ring however scattered
the points on it were. One doubling back in four leaves no ring in it at all.

The other measured number is the leash. Banking costs forward speed, so a bird
wandering behind a walking run loses ground even though it flies faster than the
run does — and fifty pixels back is a weapon that has stopped touching anything
near you. Past about half again the flock's reach a bird gives up flying prettily
and goes straight home, which it can always win: the slowest bird in the flock is
quicker than the fastest the paper plane can make you.

**Two of the five levels change what a bird is rather than how many there are.**
The fourth puts a couple of them to work: a carrier peels off the wheel, flies out
to a gem lying too far off for the magnet to have noticed, taps it, and the gem
comes home. Anything already inside the magnet is left alone, so this is reach on
your *income* rather than a second magnet level — what it fetches is the xp you
killed something for and then walked away from. The gem travels the way every
other one does, because what a carrier hands over is a *reach* and not a second
kind of pull: exactly how the skate's last level collects off its trail. The
fifth is the swarm, and it is the *room* doing the work rather than the count — a
bird may be sent anywhere from your own feet to the edge of a flock half again as
wide, so fourteen of them are a cloud you are standing inside where five were
something following you about. Every other weapon covers ground by reaching
further; this is the one that covers it by filling in what it already reached.

The spirals are the tenth, and the only weapon in the game that **does no damage
at all**. Every other one is a way of putting a number on something. This one
moves the horde and leaves you to it: a spiral winds itself onto the page
somewhere near you, everything inside it walks into the middle, and what happens
to them in there is whatever else the run is carrying. Which makes it worth the
most next to the others and the least on its own — a run with a sun, a crater or a
swarm *and* a spiral is a run that chooses where the killing happens, and a run
with only this has drawn a very good hole in the page.

**The pull is a decision and the push is a force.** A spiral hands whatever is
standing in it somewhere else to walk to, which is a thing the enemy then does: it
keeps walking, keeps jostling its neighbours and keeps hurting you if you are
standing where it is going. The last level's spiral — the one round your own feet
for the rest of the run — could not work the same way, because something told to
walk away from you would never come back and a weapon that made a run
untouchable would be the end of the run. So that one *shoves*, and a shove decays:
what it buys is a treadmill. A blob loses most of its ground, a bat loses some of
it, and the boss walks in as though none of it were happening, since `knock` on
its row already says what a shove is worth against it and this asks through the
same door as everything else that pushes. It is held as lightly as it is shoved,
and for the same reason: `hold` on that row is what being stuck is worth against
it — written for the gluestick — and being lured is being held, so at the opening
of the line the boss leans into a spiral between beats and never parks in one.

**It is the second weapon with no board**, and the beam is the other. A spiral is
arithmetic — one arm or two, a turn and a half to two and a half of them, wound
either way, spinning — and a drawing is a fixed grid of pixels used exactly as
drawn. There is nothing in a winding for a board to hold. It is plotted with
`pixelart` at whatever angle it has got to, which is also why it is free of the
eight headings a sprite would have been rounded to. Everything it draws goes down
in the ground pass, under the crowd: it is ink on the paper rather than an object
standing on it, and the things being drawn into it have to be legible on top of
it. It goes pale and then dotted as it dies, which is the ramp every fade in this
game is made of and never alpha.

**Bandaid** is the sellotape's other half, and the two are worth carrying together
rather than being the same level twice: the tape mends you for being alive and
this mends you for what your weapons are doing to the crowd. One pays a run for
walking away and the other pays it for standing in the middle of the page, which
makes it the first line in the catalogue that rewards the position the whole game
is about.

It is a fraction of the damage the run's *weapons* dealt and deliberately not of
what you draw. Ink already has a meter and a price — the trade for a stroke is
paid at the nib — and healing for drawing would be an ink bar quietly filling a
health bar. What this buys instead is the thing no other passive sells: a reason
to keep drawing while the page kills for you. A run carrying nothing that fights
for it gets nothing at all from the card, and that is allowed, because every run
arrives holding a weapon.

**What it earns is owed rather than paid.** The rate is capped at 4 health a
second, and capping that where the damage *lands* would have been capping a
burst: this game's damage arrives in bursts, and a chained bolt or a crater going
off in a crowd is several hundred points inside one frame with nothing either side
of it. So the cut goes into a debt and the debt is paid down at the rate, which
throws none of it away and reads better too — a bomb in a crowd is a couple of
seconds of mending afterwards. The debt is itself capped at two seconds' worth,
since one enormous frame should not be a long tail of healing the run is no longer
doing anything to deserve. Taken to the end of the line against a build putting a
couple of hundred points a second into a crowd it is a few health a second, which
is the sellotape's own last level and change — for a line that has to earn every
second of it.

The two oldest weapon lines used to be longer — eight and nine — and what came
out of them was repetition rather than content. Two levels that each shaved a fraction off
the same timer became one that halves it, and two that each added to the same
damage number became one that makes the jump on its own; the stars land within a
hair of where they always did (rate 5.2 against 5.278, everything else exact).
The rocket was the one place a maxed endpoint really moved in that trim, from 20
damage down to 13, and that was a correction rather than a cut: nothing in the
game has more than 12 health, so a rocket past 13 was buying overkill against
something already dead. A line is better for stopping on the last number that
does something — and the rocket has since gone one further and stopped selling
damage at all, since a volley nobody aims is short of coverage rather than of a
bigger number (see [the rocket](#what-is-in-the-draft) above).

The sharpener and the graphite are deliberately the same line pointed at the two
halves of the game, so a run that has committed to drawing and a run that has
committed to being drawn *for* both have somewhere to put a level. (The sharpener
is the line that used to be called the scissors, renamed when the scissors turned
out to be a tool — see below. A sharpener is what you put a pencil in, so what it
buys reads straight off the name: every mark on the page biting deeper.) They are
four steps rather than the five they started as, opening at +20% instead of +15%,
and those are one decision: they were the longest passive lines in the draft, the
pool is fourteen lines deep against five slots, and a run is correspondingly less
likely to finish either — so what a single pick is worth matters more than what the whole
line is worth. The end of the line comes down from 3.14× to 2.73×, which is what
the first pick being worth a third more costs.

Health is the one stat handed over as a difference rather than left to be found:
a bigger bar you then have to go and fill is not a reward, it is homework
(`Player:applyStats`).

### Fusing two lines

There are twenty-four cards in the draft that take something *off* a run, and they
are the only ones. Nine put a tool in the compass: the **HALO**, the marker; the
**LASSO**, the pencil; the **MOAT**, the gluestick; the **PUNCH**, the scissors;
the **SPINDLE**, the pushpin; the **CORRAL**, the pen; the **HEM**, the stapler;
the **CLEARING**, the rubber; and the **FOLD**, the ruler — which is the one of the
nine with nothing in the leg at all. Eight go with the pushpin: **DOT TO
DOT**, the pencil; the **STOCKADE**, the pen; the **CORDON**, the highlighter; the
**SNAP LINE**, the ruler; the **TEAR LINE**, the scissors; the **TACK**, the
gluestick; the **CRATER**, the rubber; and the **VOLLEY**, the stapler — which is
the one of the eight that strings nothing and pools nothing, because the stapler is
the one parent in the list that has no nib to lend. And seven go with the ruler:
the **MARGIN**, the pencil; the **SPINE**, the pen; the **UNDERLINE**, the
highlighter; the **TRENCH**, the gluestick; the **PARTING**, the rubber; the
**SEAM**, the stapler; and the **GUILLOTINE**, the scissors — the ruler's other two
pairings being the FOLD and the SNAP LINE, which are the two rows where somebody
else is doing the fusing.

**Which finishes all three families.** Every pair of tools in the game that shares a
gesture worth borrowing now has a fusion; the twenty-one pairs left over are two
brushes, or a brush and a block with no line in it, and there is nothing in either
for the other to borrow. All twenty-one are written anyway, by the fourth
family, which borrows the stroke instead — the six off the pencil, the six off two
brushes with no pencil between them, four that borrow the stapler's *drag* rather than
a stroke, four the scissors take by the ends of the line rather than its middle, and
one where the line needs no scissors at all because the line *is* the cut, all below.

Three families, and the reason there are three rather than twelve is a fact about
those three tools rather than a rule about fusions. **A fusion needs a gesture worth
borrowing** because a fusion of two brushes would be two marks in the same place,
which is a bigger brush and not a new tool. For a long time the compass was the only
tool in the game that qualified — it is the only one that reaches away from you —
and this section said so. It was half right twice over. A pushpin also lands
wherever you tapped and never where your hand is; what a pin has never had is a
**line**, because a point cannot be a shape, a fence or a band however far off you
put it. And a ruler is the one tool you *point*: its line does go through your own
feet, which is its whole limitation, but it is the only gesture in the game that
crosses the entire page in one press, and what it has never had is anything worth
leaving on the line it crosses. So the three families are one idea from three sides:
the compass borrows a nib and its *ring* becomes a mark, the pushpin borrows one and
its *pins* become one, and the ruler borrows one and its *reach* does.

A fusion is a tool line with two extra fields on it. `needs` says which lines
must every one be at their **last** level before the card may be dealt at all —
for the halo, MARKER, COMPASS and SELLOTAPE. `fuses` says which of those the run
actually hands over — the marker and the compass. Their tools come off the strip,
their slots come back, and the halo takes one place where two used to be. So a run
that fused two tools has a free place on the strip and the rest of the draft to
fill it with.

**The two fields are separate on purpose.** A fusion that asked only for the two
tools it eats would be a thing a run walked into by drafting greedily. Asking for
a third line the run cannot spend on either tool is what makes it a *build* rather
than a coincidence — and the sellotape is the right third, because it is the card
that pays a run for time, which is exactly what a run that put ten levels into two
tools has been spending. It is a condition and not an ingredient: the healing is
still there afterwards, because the run earned it and the fusion did not eat it.

**Finished, not merely started**, and the whole feature is in that word. A fusion
is what a run does with lines it has nothing left to spend on, so it can never be
a shortcut past them. Which is also why the levels of a fused line are not handed
back and never could be: they are what the fusion is made of.

**And a line already spent cannot be spent again.** `Loadout:ready` refuses a
fusion whose `fuses` names something an earlier one already ate — which makes each
family a *choice* rather than a shopping list. Nine fusions eat the compass and
there is one compass, so a run that finished the pencil, the marker, the gluestick,
the scissors, the pushpin, the pen, the stapler, the rubber, the ruler, the compass
and the tape has all nine of those cards live in the draft and gets exactly one of
them; take any and the other eight stop being dealt for the rest of the run. That is
one clause, and it is the clause that keeps the mechanic's whole shape honest: two
tools in and one out. Without it the second fusion would eat a line that was
already gone and cost the strip nothing.

**The clause is per ingredient, not per family**, and that is why a run can end up
carrying two fusions. DOT TO DOT eats the pencil and the pushpin; the CORRAL eats
the pen and the compass; nothing is shared, so both may be made — the only route in
the game to a strip with two made tools on it, and it costs four finished tool lines
and two catalysts — the cartridge and the tape, since those two rows no longer want the
same third line. Nothing was written for that. What the clause forbids is spending a
line twice, which is all it ever meant.

The card is **blush**, where a tool unlock is sky and everything else is paper.
Three cards go down and you have to know which one you are choosing *about*
before you have read a line — that is the same argument the sky card is made on,
and this is that argument one step further along, because a fusion is a run being
decided *and* two finished lines being spent on the decision. It costs the border
its red warm step, which is a real price and the right card to pay it on: an
unlock turns up in every run and several times over, and this turns up once.

**And the blush follows the tool off the card.** A fused tool's icon is drawn on a
plate of blush wherever it appears afterwards — in the selector column down the
margin, on the library's shelf, in its own entry — and inside the selector's box
it lands exactly, since the box is thirteen with a one-pixel border and every icon
in this game is eleven across. It is one function (`Hud.drawIcon`) that every icon
in the game goes down through and one derived set of icon names, so *where* it
happens is a fact about the game rather than a list of screens that remembered, and
a new fusion is marked out by existing. What it buys is that the strip reads at a
glance: three tools you drafted and one you *made*, in a game where a fused tool is
the single most expensive thing a run can be carrying. On the card that is the
fusion it lands on blush and cannot be seen, which is right — the whole card is
already saying it — and where it shows is the second, third and fourth levels of a
fused line, dealt on the same paper card as everything else.

Which leaves one problem, and the library is the answer to it. A fusion is only
ever dealt once its lines are finished, so the draft card is the one place a
player can never find out that it exists — by the time it turns up, knowing would
have been the useful part. So the library carries all thirty from the first run, and
it carries them the way they are actually reached: not down the tool shelf beside
the ten tools a draft can deal, but behind **EVOLUTIONS** in the corner of the page,
where you press two tools and the book says what they make of each other (see
**Evolutions**). And what comes back says what it is made of, above its levels and
in the red the book writes all its demands in: **FINISH MARKER COMPASS FIXATIVE
FIRST**. All three names, though two of them are the pair just pressed, because the
pair asked what these two make and this answers what the run has to *finish* before
it is offered — which is those two and the catalyst nobody would have thought to
press. Pairing every tool against the compass — and then against the pushpin — is how
a player finds out, before ever being offered one, that each family is a set of
alternatives to each other.

**And the third name is worth pressing for on its own**, because it is not the same
name every time. It was once: for twenty-four rows the answer was SELLOTAPE, which
made that line a toll a run paid once rather than a thing the page was telling you.
Seven catalysts are in use now and the third name is a sentence about the row — the
fixative on a ring that burns, the cartridge on a shape you build post by post, the
magnet on a rub that throws its own xp out of reach, top marks on a cut that credits
nothing. A player reading down the compass with the pushpin picked up learns which
half of their own economy each pair is asking about, which is a different and better
thing to learn than *finish the tape*.

#### What the halo is

The marker and the compass are the pair because they are the two lines that end
up wanting the same thing and cannot both have it. The marker's band is the best
ground in the game and the worst to place — it goes where your hand goes, which is
to say where *you* are, and the crowd it is for is the crowd you are trying not to
be standing in. The compass is the one tool that reaches away from you and the one
that leaves nothing behind: a circle drawn round a horde you are nowhere near,
that cuts once and is gone. Each is exactly what the other is missing.

What you get for them is the band drawn where the circle went. You open it the
way you open a compass — the needle goes in where you press, the drag out of that
press opens the leg, letting go swings it — and the leg comes round doing
everything a finished compass's leg does: twice round at 12, double where the lead
set off, a second leg the other way. What it leaves behind is not a pencil circle.
It is a finished marker's band, 13 pixels wide, burning at 5 a tick where anything
stands on it, and setting alight anything that so much as crosses it.

The two halves cover **exactly** the same stretch of page, and that is the one
number in the fused row not simply copied from a parent: the halo's `sweep.width`
is 7 where the compass rules 3, because 7 is the band's own radius. The leg is
carrying a 13-pixel nib rather than a lead, so the ring burns everywhere it bit
and bit everywhere it burns. A fused tool taking one parent's number from the
other parent's body is what fusing is meant to look like.

Every number in it is a number that was already balanced somewhere else. Nothing
was invented for the fused tool, and nothing should be for the next one: requiring
two finished lines is what buys the right to copy their finished numbers across
without a nudge. The day the marker's fourth level changes, this changes with it.

Two things are worth saying plainly about it. It is the strongest thing on the
strip, and it is meant to be — it costs ten levels across two lines. And it is the
first tool in the game that is two shapes at once: a brush *and* a block. The
block is what the press is routed on, so the gesture is the compass's to the
letter; the brush is what the leg draws with, and `src/compass.lua` drags a real
stroke round behind each lead exactly as your own hand drags one. Which means the
ring ticks, stacks, burns and fades on the marker's own terms without a line of
code anywhere knowing that a compass drew it.

It costs half a meter — two casts on a full one, the pushpin's rate. More than the
compass's 0.4, because a swing now leaves a burning ring on the page as well as
cutting one; less than the 0.85 the two tools cost cast one after the other, which
is the trade the fusion makes.

#### What the lasso is

The pencil and the compass are a pair for a reason that is written into the
compass three times over: **a compass cuts the line it draws and never the middle
of it.** The inside of one is the safest place on the page, and that is not a hole
in the tool — it is the tool. It is why opening the circle out is a real trade
rather than free area, and why the second leg is worth a level. The compass draws
a fence.

The pencil's own last level is the same idea drawn from the other end. Close a
pencil line on itself and everything the ring holds is cut, and it is worth only 4
because you have to draw the ring yourself, by hand, badly, around a crowd that is
walking away from you while you do it. It is the one thing in the game that claims
an *area* by drawing its border, and its whole cost is how hard the border is to
draw.

Fuse them and the border draws itself. You open it the way you open a compass, the
leg comes round doing everything a finished compass's leg does — twice round at 12,
double where the lead set off, a second leg the other way — and every time the
circle *closes*, everything standing inside it is cut. Perfect, at whatever width
you dragged, around a crowd you are nowhere near. The fence becomes a net, and the
safest place on the page stops being anywhere.

Two laps means the ring closes twice, so the inside is cut twice — and 1.6 seconds
apart, which matters: what is inside the second time is largely not what was inside
the first. The compass's own third level is written on exactly that observation
about the rim, and it turns out to be truer of the middle.

What it leaves on the page is a graphite circle rather than a burning band, because
what is in the leg is a pencil: a real `Stroke`, 4 pixels of pressed point wide,
scratching 9 off anything the lead passes over and ageing off the page on the
pencil's own 1.4 seconds. Its `sweep.width` is 4 where the compass rules 3 and the
halo rules 7, which is the halo's rule and not a new one — **the rim a sweep cuts
is as wide as whatever the leg is carrying.** A pressed pencil is three pixels of
graphite against a chisel's thirteen, so this rules the thinner ring of the two
fusions and spends the difference inwards.

Every number in it is a finished parent's, copied across without a nudge. The one
number that is *not* copied is the pencil's `flow` — the discount for a line that
keeps going — and leaving it out is the halo's rule about unread numbers rather
than a nudge: nothing here is dragged, the whole price is paid at the needle, and a
number nothing reads is worse than a number left out.

It costs 0.45 of the meter — under the halo's 0.5 and over the compass's 0.4. More
than a bare compass because the swing now leaves a ring *and* takes the inside of
it; less than the halo because graphite is the cheapest ink in the game, 1/230
against the marker's 1/120.

And the price that is not ink: **the pencil is the tool every run opens holding.**
This is the one card in the draft that can leave you without one. That is the right
price for the only tool in the game that claims an area at reach, and it is the
sharpest of the three prices — the halo costs you a marker you drafted and the moat
a gluestick, and this costs you the pencil you were given.

#### What the moat is

This is the fusion with the least invention in it and, run for run, probably the
most consequence — and the two facts are the same fact.

The smear is the strongest thing a run can put on the page. Anything standing on it
stops dead for as long as the paste is there, what it holds takes half again the
damage, what comes loose comes away torn, and the free are dragged towards the ink.
It is also, by a distance, the hardest thing to put anywhere useful, because where
it wants to be is *under the crowd* — and the only way to get it there is to drag
your own hand through the crowd, which is the one place a run spends its whole time
trying not to be. Every level of the line sharpens that contradiction rather than
softening it: a wider head, deeper cuts on what it holds, a tear on the way loose
and a field that pulls the crowd in are all reasons to want the paste further away
from you than your arm reaches.

The compass is the only tool in the game that reaches away from you. So the fusion
is one sentence: the glue goes where you are not. The ring is laid round a crowd
you are nowhere near, and it holds.

Nothing about the glue changed to make that work, and nothing in the game was
taught about it. `Stroke:apply` freezes what the mark touches, `Enemy:freeze` hangs
the tool off the body it caught, `Enemy:hurt` reads the softening off it,
`Game:updateGlue` tears on release and pulls the free towards the ink, and the pull
field switches itself on because the game asks the strokes on the page each frame
whether any of them has one. Not a line of that knows a compass drew it.

**And the drag now picks between two different tools.** The rim a sweep cuts is as
wide as whatever the leg is carrying, which is the halo's rule; here the leg is
carrying a 41-pixel head of paste, so `sweep.width` is 20 against a smallest circle
of 16. Open it at the minimum and the ring closes over its own middle: what lands
is a filled plug of paste 36 pixels across, a pushpin's crater that holds instead
of hitting. Open it all the way out to 66 and the same ring is a 40-pixel-thick
wall with clear page inside it. One is dropped on a crowd, the other is drawn round
one, and the difference is how far you dragged. That is the only genuinely new
decision in any of the three fusions, and even it came out of copied numbers rather
than being invented.

The one place the two parents genuinely disagree is what the leg does on its way
past. The gluestick cuts nothing and shoves nothing, because that is what a
gluestick is; the compass's leg has always cut 12 and dragged what it caught round
the circle with it. Both are kept, because they answer different questions — the
brush fields are what the *mark* does and the block is what the *arm* does — so the
leg stirs the crowd it cuts and the paste it has just laid sets them where the stir
left them. They cannot fight, either: a shove is dropped the moment a body is
glued.

It costs 0.6 of the meter, which makes it the dearest single use in the game, over
the halo's 0.5 and the pushpin's 0.45. Glue is the most expensive ink there is per
pixel, the mark it leaves lives the longest of anything on the page, and it covers
more paper than anything else in the game. It is also the one fusion where the usual
comparison — what the two tools cost cast one after the other — does not apply: a
full meter of gluestick draws ninety pixels of smear, and one swing of this lays
eight hundred. What the fusion sells here is not a discount. It is a mark no meter
could ever have paid for.

#### What the punch is

A hole punch: the piece of stationery whose entire job is taking a circle out of
paper.

This one was asked for rather than demanded by its pair, and the difference is
worth saying out loud. The other three each fill a hole in the compass that exactly
one other line was shaped for. This one fills a hole in the *draft* — a run that
had spent ten levels on the scissors and the compass had nothing to spend them on
together, and four fusions off one parent is four builds where there were three.

The pair is still a real pair, and the argument is a shape rather than a number.
The scissors reach anywhere, and their last level is the only thing in the game
that writes into the page itself rather than onto it: the cut runs edge to edge and
the half you are not standing on lifts off. What they cannot do is choose *which*
half. A cut is a straight line, so the only region a pair of scissors can take is a
half-plane — and half a page is an enormous amount of page to be deciding about
with two taps. The compass is the only tool that draws a closed line. Put the
blades in its leg and the offcut stops being half the paper and becomes a disc you
sized with the drag. The same finale, aimed.

**It will feel like the lasso, and it must not be one.** Both are a ring that does
something to the middle of itself, which is the one thing a compass had never done.
For a long while the difference was a number — the lasso cut the middle once and
hard, this one wore it down at a point every half second — and the honest reading
of that is that the PUNCH was a slow, worse lasso wearing the scissors' clothes.
Two cards arguing about *how hard* are the same card twice.

So the middle of this one is not damaged at all. **Everything inside the ring is
taken off the page and set down in the corner of it furthest from you** — moved,
not killed and not deleted: no gem, no xp, no kill on the tally, nothing split and
nothing burst, because nothing was hurt. The lasso's middle is a hit and this one's
is *a place the horde is not*, which is the same distinction the compass's own third
level turned on, taken literally. It is the one tool in the game that buys nothing
but room.

**And the room is paid for in the shape of what comes back.** The disc does not
spend the crowd it holds, it *stacks* it: the same bodies at the same health,
standing in one corner, walking back at you together. So a punch is a fight
postponed and gathered rather than a fight cancelled, and a build that reaches for
it whenever the meter fills is a build that keeps handing itself a clean circle to
stand in and a single column of monsters to answer — which is a real bargain rather
than a free one. Nothing had to be tuned to make that true; it falls out of moving
the crowd instead of removing it, which is the whole mechanism, and it is the same
mechanism the parent's own finale runs on. It is still a panic button rather than a
rotation: the right time to buy yourself the length of the page is when the
alternative is fighting where you are standing.

**Two numbers the parents already agreed on**, which is the clearest sign yet that
a pair is the right pair. `width` is 3 on both, and the compass's own block says
why in as many words — it took the scissors' number for the scissors' reason,
because a lead is a point and a blade is an edge and neither reaches off the line it
rules. `damage` is 12 on both, arrived at twice from opposite directions: the
scissors' 12 is the skull's whole health along a line nothing is standing on unless
you put it there, and the compass's 12 came from the level that stopped the longest
line in the game being unable to touch a tank. There was nothing to reconcile.

**One they did not**, and the scissors win it. The compass's leg drags what it
catches round the circle with it, because a lead drags; a blade separates, and the
scissors' `knock = 0` is written down rather than left out precisely so that no
multiplier can ever move it. Keeping the compass's shove would also have fought the
tool's own point: what the ring takes is decided by where bodies are *standing* when
it closes, and shoving them out of the disc first is the one thing that could stop
that mattering.

It is also the first fusion that is **not** two shapes of tool at once. There are
no brush fields on the row at all, because blades put nothing on the page — so the
arm draws no stroke and the compass rules its own ring, which makes this the one
fused row that keeps `life`, `fade` and `ramp` on its block instead of handing them
to a mark. What it rules is a slit: dashed, in paper, with the dark edge of the page
lifting one pixel outward. Paper is the one colour that wipes the ruling instead of
stacking with it, so the page really does stop at the line — and while the compass
is still being set, what you are shown is the graphite dotted circle it has always
drawn, which on this tool reads as *cut along the dotted line*.

And it costs 0.4, the compass's own price to the pixel — the only fusion that costs
exactly what one parent did. There is nothing extra to charge for. The other three
each pay for something the arm leaves lying on the page; blades leave no ink at
all. The scissors are the cheapest single use on the strip for that same reason, and
a compass carrying them spends its meter on exactly what a compass always spent it
on: the needle going in.

#### What the spindle is

A spindle is the spike on a desk that paper gets pushed onto, and it is also the
axis a thing turns about. Both meanings are this tool.

The pushpin and the compass are the only two tools in the game that *reach*.
Everything else happens where your hand is; a pin is tapped onto any spot on the
page and a circle is stood wherever you press. What makes them a pair rather than
two ways of doing one thing is that they disagree about **when**. A pin is a single
instant — a quarter-second fall you can watch coming, a crater, and the one thing
that lived through it stuck to the paper — and all three happen at once, so the
tool reads as one event. The compass is the opposite: the slowest thing in the game
to bring to bear and the only one whose hit you can watch travel, most of a second
of promise.

Fuse them and the pushpin's two halves come apart in time.

The crater is dragged instead of dropped. The rim sweeps at the point's own 25
pixels, punching holes out of the crowd the whole way round — and at the smallest
circle it closes over its own middle, so the same tool is a plug of holes 41 pixels
across or, opened out to 66, a 50-pixel-thick wall of them with clear page inside.
Then the point picks up the first body it fails to kill, carries it round impaled on
the lead — in front of you, for a whole turn, frozen and still dangerous to touch —
and drives a real pin through it into the page wherever the arm happens to stop. A
tapped pushpin does the crater and the pinning in the same frame; this does them a
turn apart, and the second half is a promise you can see being kept.

And you watch it happen, which took one more thing than the mechanic did: the leg
draws the pushpin itself on its end rather than the ink dot every other compass leg
ends in — the same 7x8 drawing a dropped one uses, origin on its own point, so the
point sits exactly where the lead would have been. It is on the arm from the moment
you press, before you have committed to a width, because a leg is a line that may
be pencil-faint before you mean it and a pin is an object that is simply there. The
instrument is lifted off the frame the turn closes and the driven pin is drawn a
line earlier in the same pass, so the pin you watched come round is the pin left
standing in the page. A tool whose whole finale is *watch this travel, then watch it
land* cannot have the travelling half drawn as a dot.

**The sharpest number choice in any of the nine is `damage`.** Both parents have
written one down and they disagree: the compass cuts 12, which is the skull's whole
health, and the pin punches 10, which is deliberately one short of it. The pushpin's
own row argues for its own number better than anything here could — *anything that
killed outright would leave the pinning with nothing to pin* — and that sentence is
this tool's whole design. So the fused row takes the **weaker** of the two numbers,
because the stronger one would delete its finale. A copied number beating a chosen
one that plainly looks better is the clearest evidence yet that these rows are read
off their parents rather than balanced by hand.

The shove goes the other way and stays the compass's 130, where the pushpin's block
has no knock at all. That is the moat's split again: the block is what goes into the
page and the sweep is what the arm does on the way past. A landed pin is not going
anywhere, which is why the pushpin never needed the field; a pin on the end of a
moving arm drags what it catches round the circle with it — and this is the one tool
where the compass's knock stops being a figure of speech for one body and stays one
for everybody else.

There is one more coincidence worth pointing at, because it was already written
down before either of these tools met. The pushpin's third level, *the point bites
double what it falls on*, is described in `src/upgrades.lua` as "the compass's bite
fallen from above". It is the same level. Two lines each bought a copy of it, and on
the fused row one `bite = 2` pays for both.

It is also the first row in the game with **two blocks** on it, and that needed no
new rule: the block tested first is the gesture and everything else on the row is
what the arm is carrying, which is exactly what the brush fields were on the other
three. Making the pin's numbers a real `drop` block rather than three loose fields
is what lets the sharpener and the fixative reach them for free — a maxed fixative
takes the hold from 4 seconds to 8.6 — and it is the reason this fusion needs no
unlock code at all.

It costs 0.55: over the halo's 0.5, under the moat's 0.6, and against the 0.85 the
two tools cost cast one after the other, which for the first time since the halo is
a real comparison because both parents charge per use. The pushpin is the
second-dearest single use on the strip because one tap is one crater. This is that
crater dragged twice round a circle, and what it leaves behind is the only thing in
the game that never comes off the page.

#### What the corral is

A corral is a pen. That is the whole tool, and it is the rarest thing in this
document: a pun that is also a mechanic.

The pen and the compass are a pair because the pen has two limits and the compass
answers both of them in one gesture. The first every tool but the compass has — a
fence is drawn by dragging your own hand down the line you want it on, which means
walking the length of the wall you wanted through the crowd you wanted it against.
The second is the pen's alone and is far worse: **its line has ends.** Enemies round
the ends of a wall on purpose (`Enemy:avoidWalls`), so a hand-drawn fence is
something the crowd flows past rather than something it is stopped by, and in the
whole history of the tool the pen has never once enclosed anything. The compass is
the only tool that reaches away from you and the only one that draws a *closed*
line. Put the pen in the leg and both limits go at once: the wall is laid where you
are not, and it has no ends at all.

So this is the fusion that changes the shape of a fight rather than the numbers in
it, and it is one of only two of the nine that do. The others are things that
happen *to* the crowd — a ring that burns, closes, holds, lifts out, drags and pins
— and every one of them is over in a second or two. This one leaves a **place**. A
closed pen ring is somewhere the crowd is: inside it or outside it, and it does not
get to choose which afterwards. With the pen's finale on it the ring has no clock
at all — the last circle you swung stays until you swing the next.

What it costs is what the pen has always charged for a wall: the crowd is *held*
rather than hurt. Two points a second to whatever is leaning on the ink and nothing
at all to whatever is not, so a run that fenced the horde off has bought itself time
and not one kill. Every number is a finished parent's, as they all are — the 7px
nib, the sting with its two pixels of slack, the 4-damage pop when the ink goes, and
the 12 the arm cuts on its way past — with two exceptions worth naming.

**`knock` is 0**, where the compass's leg drags what it catches round the circle at
130. The pen writes its zero down rather than leaving it out precisely so no
multiplier can move it, which is the scissors' rule and the argument the punch won;
here it is stronger than on either of them. What a closed fence does is decide who
is inside it. A leg that swept bodies tangentially round the rim as it laid the wall
would be dragging the crowd *across* the line it was drawing.

**And the pen's `smooth` is dropped**, which is the only omission in any fused row
that is not merely a number nothing would read. A ballpoint nib trails the pointer
by design — it is what rolls hand jitter into a curve — and there is no hand here:
the lead runs the rim at some 500 pixels a second at full width, so a nib chasing it
at 26 would lag twenty pixels behind and *inside* the arc, ruling a smaller spiral
than the guide promised and stopping short of closing when the arm stopped. A number
left out is a number nothing reads; this is one that would be read and would lie.

It cost two lines of code, and both are about a wall being laid by something that is
not a hand. `Walls:rebuild` runs only when the index is dirty and only the drawing
pass was dirtying it, so `Compass:layBands` says so as it lays; and the pen's hold is
claimed for **both** halves of the ring from `Compass:swing`, because a finished
compass rules the circle as one mark per leg and half a ring held would be a fence
with a hole in it. That is what turned the one held wall into a list. Everything else
— the sting, the fade, the pop, the fence itself — is machinery that has never heard
of a compass.

It is also the one card in the draft that can leave a run **boxed in on purpose**,
and that is worth saying out loud rather than patching out. You cross your own ink
freely, so a ring drawn round yourself is a fortress for as long as you stand still
in it. Standing still is the one thing a run cannot afford: the gems are on the floor
outside, the eyes shoot over ink, and the boss has to be killed rather than waited
out. The pen's own last level was written with that same sentence in it. What this
does is make it cheap enough to reach for, which turns a theory into a decision.

It costs 0.55, level with the spindle: blue ink is dearer than graphite and cheaper
than paste, and the mark outlives every other mark in the game by a factor of three
before the finale takes its clock off altogether. The moat's comparison is the honest
one again rather than the sum of two prices — a full meter of pen draws 170 pixels of
fence, and one press of this lays eight hundred of it in a shape no hand can draw.

#### What the hem is

A hem is what you get when the edge is fastened all the way round. This one is the
corral's argument told in wire.

The stapler is the most repetitive tool on the strip: ten a meter, one press each,
and every press a 15px circle you have to land on something that is walking. All
four of its levels are about making a press worth more — 6 instead of 2, one in
five going straight through at 18, and a boost to whatever crosses one afterwards —
until the last, which sells the ten presses back as a single drag and calls the
result a **seam**. But a dragged seam is still a seam your own hand has to walk, in
a straightish line, through the crowd you wanted it in front of. Give the stapler
to the arm and the seam is raked round a circle you are nowhere near, evenly, at
whatever width you dragged — and it closes. A seam that meets itself is a hem.

One staple every 12 pixels of rim, which is the stapler's own seam spacing
unchanged and read from the same field (`rake.every`) by an arm instead of by a
finger. The crowns are 12 apart and each reaches 7, so the circles just overlap and
the ring is continuous — that is the parent's arithmetic, not a second decision. A
circle at the minimum holds 8 staples; opened right out it holds 34.

**And that is the first price in the game the drag decides.** Every other sweep
costs one number at the needle and opens as wide as you like for free. Wire cannot
be free here, because the stapler's whole line is written on the price of a staple
never changing — its finale buys presses, not page. So the row carries a second
price of two hundredths per staple: 0.4 at the needle for the smallest ring and its
eight, up to 0.92 for the widest and its thirty-four. Eight tapped staples alone
would be 0.8, and the fifth you are no longer paying is the aiming.

The drag is capped by the meter, which is the part that had to feel right rather
than merely be correct: **the leg stops opening where the ink runs out.** It is not
an error and there is no failed cast — it is the tool telling you how much wire is
left in it, the same answer the meter gives a brush that runs dry mid-line, and the
one place in the game where a tool's reach is something you can run out of
mid-gesture. Half a meter opens it to about 53; a full one opens it all the way.

Nothing a staple does was touched. Landing on the frame it is placed, biting for 6,
critting one in five for 18, holding what survives for two seconds, and then either
staying in the paper for the rest of the run or being torn back out of it are all
`src/staple.lua`'s, and not one of them was told a compass was involved. The best
thing here is the one nobody designed: those 34 staples went into the ring on the
same frame, so they come out of it on the same frame. **The hem closes on a crowd,
holds every body in it for two seconds, and then unfastens the whole rim at once
for another 6 each.**

The arm keeps the compass's cut and shove — 12 and 130 — on the moat's split: the
block is what goes into the page and the sweep is what the arm does on its way
past. They cannot fight, for the moat's reason too: a shove is dropped the moment a
body is held, and the staple that lands on it holds it. So the leg stirs the crowd
and the wire sets them where the stir left them.

Two small things it needed. A press has to be *heard* — and 34 of one sound in
under a second is a machine gun, not a stapler — so the seam is heard at most ten
times a second while every press still lands. And the slots are worked out up front
from the final width rather than accumulated as the arm goes, so the spacing is
exactly even, the count is exactly what the price was charged for, and whichever
leg reaches a slot first is the one that presses it: the page holds staples one deep
(`FOOTPRINT` in `src/staple.lua`), so a second press on a spot that already has one
is a press nobody sees and a meter charged for nothing.

#### What the clearing is

A clearing is a circle of ground with nothing standing in it, and it is the only
fusion named after the middle of the ring rather than the ring.

The rubber is the tool that moves the crowd, and it can only move the crowd that is
already on top of you. A rub shoves — 240 is a 27-pixel throw, and the finale makes
whatever it throws a weapon until it slows — and every pixel of that has to be
delivered by dragging your own hand through the thing you are trying to get away
from. The compass reaches away from you. But this is the one fusion that does not
want the reach: it wants the compass's *shape*, and the shape is a closed ring you
can stand in the middle of.

So the leg sweeps and **everything inside the disc it has passed goes straight out
of the circle**, launched. Not round it — the compass's own knock drags what it
catches along the rim, because a lead drags, and a rubber shoves away from itself.
Away from the needle is the only direction a disc has. Plant it on your own feet and
the rank that had reached you leaves; plant it round a crowd and the crowd is
scattered outwards instead of stirred. The middle of a compass was the safest place
on the page, and three of its four levels are written on that fact. This is the card
that makes the middle the only thing it touches.

**This is the disc the compass's hit test was fixed for**, and that is worth saying
plainly because the code says it too. There was a day when the leg swept the page
like a radar wiper and took everything behind it: the angle test did all the work
and the distance test only asked whether a body was inside. That was a bug — it made
the tool a delayed pushpin with a bigger crater and cost three of its four levels
their argument. Restoring it here is legitimate for one reason: what this deals is
the rubber's 2, not the compass's 12. The area is not buying damage for free, it is
buying a *shove*, which is the one thing that has to reach an area to mean anything
at all. And the tool it borrows was never an edge — you do not cut with a rubber,
you clear the patch you went over with one, and a rubber that only touched what
stood exactly on a ruled line would not be a rubber.

**Nothing dies**, and that is what pays for touching everything at once. 2 a body, 4
where the leg bites, which is what a rubber has always dealt and the one number its
own line never moved. What you buy is a second and a half of empty page, and the
only thing here that can actually kill is the crowd hitting the crowd — the ram, at
5 a collision, bowling the inside rank through the outside one on its way past.

**And it leaves nothing at all.** Every other fusion puts something on the paper: a
band, a graphite ring, a smear, a hole, a pin, a fence, a row of staples. A rubber's
mark is over the moment you let go, and `life = 0` was copied straight across — so
the circle is drawn in graphite as the arm follows it and gone with the arm. It is
the only sweep that leaves the page exactly as it found it, which also makes it the
only one drawn in pencil rather than ink: what you are being shown is where the tip
is travelling, not something going down.

Two of the rubber's four levels have nothing to land in, which is more than any
other fusion drops. `lean` is a tip that keeps hitting while it *rests*, and an arm
never rests; `scrub` is half price over ground already covered, and there is no
per-pixel price here to halve — the whole cost is paid at the needle. Both are about
the wrist and the meter, and a sweep has neither. What crosses over is the shove and
the ram, and the level that quietly loses its argument is the compass's own third:
"twice round, cutting far deeper" is 12 on the parent and stays 2 here, so a second
lap buys a second wipe of whatever walked back in rather than a deeper cut.

It costs 0.4 — the compass's own price, and the second fusion to cost exactly what
one parent did, for the punch's reason: there is nothing left on the page to charge
for.

#### What the fold is

A fold is the crease a sheet of paper takes when it is folded, and this is the only
fusion where **nothing goes in the leg**.

The ruler and the compass are the two instruments in a geometry set, and there is a
thing you do with the two of them together that anybody who has ever held them
already knows: two arcs from two centres cross at two points, and the straight edge
goes through those two points. It is the first construction anyone is taught. This is
the only fusion in the game whose two halves were designed to be used together by
somebody other than us.

What each one is missing is not reach — both of these already reach. **A ruler's line
goes through you.** That is its one real limitation and no level of it moves: it is
200px long and the last level makes it 400, and every pixel of that lies on a line
through your own feet, so what you get to choose is which *way* the page gets swept
and never where. The compass is the only tool that goes somewhere you are not, but
all it can ever draw is a closed ring. Put the two together and the ruler's line
becomes a **chord**: square to the line joining the two needles, half way along it,
and nowhere near you.

So the whole `sweep` block is the finished compass copied across without a number
moved — a bare lead, a 3px rim, the plain pencil ring — which no other fused row can
say. What the fusion added is not on the instrument at all. It is on the *page*:
swing a second circle while the first is still lying there and, where the two rims
cross, the ruler falls flat on the line between the two crossings and throws
everything within 13px of it off both sides at once, for 12 and a 210 shove.

**It is the first tool whose second half is a relationship between two marks.**
Everything else on the strip is a gesture landing: a mark, a drop, a swing, and the
page is whatever that left. A fold needs two swings, and neither is worth anything on
its own — one circle rules nothing at all. That is also where its price is, and it is
a price nothing else here charges: **the meter is asked for the compass's plain 0.4
twice over.** Most of a full meter and two presses, for one line.

**And the aiming is real, it is just indirect.** Both ends of that line were placed
by placing two needles, which makes this the one thing on the strip you aim by
drawing something else twice. The line is as long as the overlap is deep, and the
numbers fall out of the geometry rather than out of a table: two circles at the full
66 with their needles 40 apart rule 126 pixels; 66 apart rules 114; 100 apart rules
86; 125 apart rules 42. Two circles nearly on top of each other rule a near-diameter,
which is the longest line available at 132 and lands straight across both middles —
so a tight pair concentrates and a wide pair covers, and that is a decision you make
with the second needle.

**Fresh is the ring's own life and not a clock anybody invented.** A compass is on
the page for exactly as long as the circle it drew, 2.2 seconds past the arm
stopping, and the pairing window is precisely that: swing the second circle while you
can still see the first. Nothing had to be written down for that to be the rule,
which is the best thing about it — the tool is legible off the paper rather than off a
number, and a ring you can watch fading is a timer. The line comes down every time a
ring *closes*, so a finished compass rules the chord twice, half a turn apart.

What it refuses is worth knowing, because all of it is what a schoolchild would call
not crossing: circles too far apart, one inside the other, two that touch at a single
point, and two needles less than four pixels apart — that last being the same
argument the ruler's own aiming makes about a pointer sat on the pivot, since the
chord's direction is read off the line joining the needles. And one rule that is
about drawing rather than about geometry: a chord shorter than the 13px band that
lands on it is refused, because what would come down on a graze is the whole hit
wrapped round a single point, which is a pushpin nobody asked for.

One parent level has nothing to land in, and it is the ruler's finale: how far this
ruler reaches is not the tool's to decide any more, and 132 is a third of what "IT
RULES THE WHOLE PAGE END TO END" buys. The reach is what was sold and the position is
what was bought. Everything else of the ruler's is here to the digit — 13 across, 12
damage, the 210 that opens a corridor, and the ruled pencil line it leaves behind for
a second and a half.

#### What the eight pushpin fusions are

Here the borrowed gesture is the tap. You tap the page, a pin falls for a quarter of
a second, it punches a 51px crater and pins whatever walks out of it — the pushpin,
exactly, down to the last digit of its finished line. And then a second pin dropped
**within a hundred and twenty pixels of the first is joined to it**: a line appears
between the two, whole, on the frame the second one lands.

**A hundred and twenty is three eighths of the narrowest page, and the range is drawn
on it.** It used to be fifty, and fifty had the prettier argument: a finished pin
punches 25 about the point, so two pins fifty apart are two craters whose rims are
exactly touching — the tool drew its own range and no guide was needed. If you could
see the two circles kiss, the pins were joined.

It did not survive being played, and neither did eighty after it. A pin costs half a
meter and holds for four seconds, so the second and third of a set are placed in a
hurry, and three taps inside a fifty-pixel circle is a shape you build by accident or
not at all. That is a fusion with a knack in it, which is the wrong thing for a card a
run spends ten levels and two tools reaching.

**What settled the number in the end was the triangle rather than the line**, and
that is worth being explicit about because it is easy to tune the wrong one. Two pins
need a range; three need *room*. Three pins that are pairwise within eighty have to
sit inside a circle forty-six across, and at a hundred and twenty they sit in one
sixty-nine across — which is the difference between a shape you have to plan and a
shape you can simply mean. And the triangle is the half of this family that matters:
four of the five threading tools are only really interesting closed. DOT TO DOT cuts
what it encloses. The STOCKADE is a fence, and a fence wants a corner. The CORDON is
a band you want to walk something into. A range tuned so that a straight line is easy
and a triangle is hard is a range tuned against the tool.

So the guide is drawn instead of inferred. **Every pin that is still holding carries
a faint graphite ring at exactly the reach** — the same pencil circle the pin already
draws while it is in the air, several sizes up — and it is only ever drawn round the
pins that can still be linked. At this radius the ring is most of the reason the tool
is legible at all: the craters' rims are seventy pixels apart at full stretch, so two
pins can be joined without looking, to a player, as though they ought to be. Which makes it two facts in one drawing: where the next pin
may go, and how long you have to put it there. A range you can see is worth more than
an arithmetic coincidence you cannot, and it is the same argument the pen's fade
makes ("a wall you can't see is a trap").

What appears between the pins is the whole of the difference, and it is whichever
tool the fusion ate, at its finished numbers. **Five of the eight string something
between two pins**, and for three of those the something is a mark:

- **DOT TO DOT** strings the pencil, and it is the name of the puzzle rather than a
  description of the tool. Every thread scratches at the pencil's own 9, and then the
  finale the pencil has been arguing for since it was written arrives with the loop
  closed by taps: **join three pins into a circuit and everything the circuit holds
  is cut.** The pencil's own version of that level is cheap and vague on purpose —
  the ring is yours to draw, badly, around a crowd that is walking away from you
  while you draw it. This one cannot be vague. The corners are pins, the pins are
  exactly where you tapped, and each corner punched a crater and pinned a tank on
  the way in, so the shape is built out of three hits that were worth taking on
  their own. It is also the dearest ring in the game: three taps and a meter and a
  half, against the LASSO's one press. Four pins and five pins close too, and what
  gets cut is the tightest circuit the landing closed.
- The **STOCKADE** strings the pen, and every thread is a **wall** — the pen's own
  fence, stinging what leans on it, popping when it finally comes off the page. It
  is the CORRAL's argument with the other answer at the end of it. A hand-drawn
  fence goes where your hand goes and has *ends*, so the pen has never been able to
  hold ground it was not standing on or to enclose anything at all. A corral fixes
  both by ruling a closed circle at reach — a shape the tool chooses and you place.
  A stockade fixes both by driving posts: a line across a corridor, a spur off the
  fence you laid ten seconds ago, a triangle round a spawn, closed if and only if
  you close it. And **every post is worth driving on its own**, which is the half
  the corral cannot match: a tool whose whole cost was walking to where the wall had
  to be now pays you a crater and a pinned tank for standing each end of it up.
- The **CORDON** strings the highlighter: fifteen pixels of sky that stops nobody
  and burns at 5 a tick to whatever stands on it, setting alight anything that so
  much as crosses. A cordon is tape strung between two posts to say a stretch of
  ground is not to be crossed, and this one really does let the crowd through. It is
  what walking through costs. Where two threads cross, the crowd takes both — which
  is the marker's stacking level arriving through the tool's own geometry instead of
  through a number, and the reason a run drops pins in a lattice rather than in a
  line.

And for the other two it is not a mark at all but **a whole second tool, cast along
the line the pins make**. That is the FOLD's idea borrowed wholesale — there the two
points were two circles crossing, here they are two pins — and neither of them
needed a new mechanic, only the parent let go of its own gesture:

- The **SNAP LINE** casts the *finished ruler*, and the pins do not bound it — they
  **aim** it. What comes down is not the hundred and twenty pixels between them but
  the whole page, corner to corner, thirteen across, shoving everything clear of the line off
  both sides at once. Which is the ruler's one real limitation taken off it and
  nothing else touched: a ruler's line goes *through you*, no level moves that, and
  what you get to choose is which way the page is swept and never where. The FOLD is
  the other answer to that same sentence, and the pair is worth reading together —
  there the reach was sold to buy the position, because a chord can never pass 132.
  Here the reach is kept and what is paid instead is **precision**, which is the
  better half of the trade because it is a skill rather than a number. Put the second
  pin one pixel off and the far end of the line moves a little over three — and every
  time the family's reach went up, this row got *more* forgiving rather than less,
  because a longer baseline is a steadier one. It is iron sights, the
  near sight is a 51px crater, and the ring round it says where the rear sight may
  go.
- The **TEAR LINE** opens the page along it instead — and this is the one fusion in
  the game whose two halves were *already the same gesture*. Scissors are tapped
  twice: the first tap anchors, the second says which way it runs, the page comes
  apart between them. Two pins are two taps. So nothing about how it is used is new
  to either parent, and what the fusion fixes is that **the scissors' first tap was
  free and did nothing**. The whole price of a tool you can place anywhere on the
  page was the gap between the taps — the horde keeps walking through it, so the row
  of blobs the first tap lined up is not the row the second one cuts. Here the first
  tap is the biggest single hit in the game and it leaves an object standing in the
  page you can see while you choose the second. The gap stops being the cost and
  becomes the tool. Twenty across six between the pins, twelve across three out to
  both edges, and the half you are not standing on lifted off with everything on it.

**And two of the eight do not string anything, because two of the parents are not
line tools.** You do not string paste between two points — paste is a blob — and a
rubber's shove goes outwards, not along. So the mark pools round a single pin, at the
crater's own width:

- The **TACK** is a pushpin in a 51px pool of paste, and it is the sharpest pair of
  the seven because the gluestick **deals no damage at all**. That is its whole
  identity and its whole problem: the smear holds everything and kills nothing, so it
  has never had anything to be holding things *for*. A pushpin is exactly the missing
  half — ten damage in a 51px circle, placed anywhere, killing everything caught but
  the toughest thing in the game — and *that* is what the paste then holds. The
  crater sorts the crowd and the pool keeps what is left, softened by half again so
  everything else the run owns cuts deeper into it, torn on the way loose, with the
  free dragged in from a hundred pixels across. The name is the pun and the pun is
  the tool: a *tack* is a pushpin, and *tacky* is what glue is.
- The **CRATER** empties one instead. The pin's own row has called its circle a
  crater since the day it was written, and what has always actually happened in there
  is that things walk out of it — "anything that killed outright would leave the
  pinning with nothing to pin" is the pushpin's entire design. Load it with a rubber
  and nothing walks out: everything the circle caught and did not kill is thrown
  straight out at 240, twenty-seven pixels, and knocks down what it lands on for 5.
  The rubber's limitation is not the one the others have — the others go where your
  hand goes, a rubber goes where your *wrist* goes, only working while the tip is
  travelling at a fifteen-pixel reach, which means standing in the crowd and
  scrubbing at it. And the two halves land in the right order without being told to:
  the crater kills everything but the tank first, so what gets thrown is exactly
  what survived, straight into whatever is walking in behind it.

**And the eighth strings nothing, pools nothing and adds no second mark to the page
at all, because it is the only fusion in the game whose two parents already share a
gesture.**

Every other pairing in this family works the same way: the pin brings a *reach* and
the other tool brings a *nib* — a line, a band, a wall, a pool — and the fusion is
the nib arriving somewhere a hand cannot go. The stapler has no nib. It is placed
with the same tap as the pushpin, it arrives through the same code, and the two tools
have differed in nothing but their numbers since the day they were written. There is
nothing to string.

What there is, is that those numbers are **opposites field for field**, and that is
worth more than a nib. A pin is one big telegraphed decision: fifty-one pixels of
crater, ten damage, half a meter, a quarter of a second in the air. A staple is a
hundred small ones: fifteen pixels, two damage, a tenth of a meter, and instant.
There is exactly one interesting way to read the pair — take the pin's numbers and
the staple's *gesture* — because reading it the other way gives you a staple that
makes you wait a quarter of a second for it, which is nothing at all.

- The **VOLLEY** is that reading, and it is the stapler's *hand* rather than its
  ammunition. A tap still lands one pin. Hold the pointer down and drag, and it rakes
  a seam of craters across the page. And each of the three things it takes from the
  stapler *retires* a pushpin level rather than sitting next to it, which is what
  makes it a fusion rather than a pile.

  **The fall goes**, and that is the biggest single thing on the card. The pushpin's
  quarter-second in the air is the most carefully argued number in the game: it is
  what turns the ring on the page into a promise rather than a report, it is about
  eleven pixels of bat, and it is the only reason a tap on a moving target is not a
  certainty. All of which is true, and all of which is precisely what a stapler does
  not have — a stapler goes down and it is done. So the crater lands where you
  pointed it, and a walking blob no longer gets a vote. It is also the thing that
  makes the drag possible at all: a raked pin that took a quarter of a second to
  arrive would land a quarter of a second behind your finger, which is a seam laid
  where you *were*.

  **The tap becomes a drag**, which is the stapler's own finale and the only level in
  the whole catalogue that changes a gesture. Nothing about it is rewritten here — it
  is the same field running through the same code — and the one number that moves is
  the spacing: forty-eight pixels where a staple's is twelve. That is the parent's
  own rule read at the pin's size. The stapler's twelve is set so that its
  fifteen-pixel bites just overlap; forty-eight is where a fifty-one-pixel crater
  does the same. So a seam comes out as a **chain of holes** rather than a stripe, no
  enemy is ever standing inside two craters at once, and the pushpin's "kills
  everything caught but the tank" goes on being true one crater at a time.

  **The point's double becomes the stapler's roll.** The pushpin's third level
  doubles the one body the point itself came down on: a level about *aim*. It cannot
  survive a tool whose gesture is a drag, because what you aim in a seam is a line —
  which body each forty-eight-pixel step happens to put its point on is luck, so the
  level would only ever pay out on the one press in a rake that is still a tap. What
  replaces it is the stapler's one-in-five triple, which works exactly the same on a
  tap as on the fortieth pin of a seam. And that is the trade the two tools have
  already argued out in their own upgrade lines. The stapler's crit is written on the
  claim that a one-in-five is only a **rate** when the sample is large — "where the
  same roll on a pin you get two of from a full meter would only ever be a story
  about one pin". Four a meter, raked, is the sample that makes it a rate. So the
  drag is what legitimises the crit, and the crit is what pays for the aim the drag
  gave up. Neither half works without the other, which is the test a fusion should
  have to pass.

  **And a seam is how the pushpin's finale finally means something.** Its last level
  turns kills under a crater into weight on that crater's survivors, and its own row
  is careful about the limit: "a pin dropped on a *lone* skull changes nothing at
  all" — the exception to "the tank walks out of the crater" has to be earned through
  the crowd standing round it. A rake is how you get a crowd under a circle on
  purpose. Nothing here doubles up, since the craters do not overlap, so what a seam
  does to a grin is hit it as it goes past and again on the next step. The tank dies
  to being **raked across** rather than to a lucky crater, which is a thing you do
  rather than a thing that happens.

  It is priced per pin rather than per press, so the meter and not a count is the real
  cap and a rake on a nearly-dry meter simply stops where the ink did. A quarter of a
  meter each — half what every other fusion in this family charges for a press, and a
  little over half the pushpin's own forty-five. So a full meter is four craters
  against the pushpin's two and the stapler's ten: between its parents, where a fusion
  of them belongs, and countable, which matters more than it looks. Four is few enough
  that you know what a seam costs before you lay it. And the halving is exactly what
  the stapler brings, because its own four levels are written on the one invariant
  none of them touches — ten a meter stays ten a meter — so what it lends a fusion was
  never a discount. It is the *rate*.

**A strung or pooled mark is on the page for as long as its posts are.** That is the one
rule the family adds, and it is what makes the marks legible: a pin holds what it
caught for four seconds, so the shape you built out of pins stands for as long as the
pins do, and it starts fading — on its own nib's clock, down its own nib's colours —
the moment either end comes out. It is also what bounds the thing. A page cannot be
latticed shut by a player who keeps tapping, because the posts keep coming out. It
says nothing about the ruler or the cut, and does not have to: those two land on the
frame they are cast and leave on their own clocks, exactly as they do for the tools
they were taken from.

One parent level has nothing to land in, and it is the pen's finale: "THE LAST LINE
STAYS UNTIL YOU DRAW ANOTHER" is a rule about one gesture's worth of wall, and a
fence built pin by pin is not one gesture — it would let go of every rail but the
newest as you built the thing. What that level bought is bought here by the posts
instead, and bounded by something you can watch rather than by a rule.

Half a meter a tap, on seven of the eight, which is two taps from a full one — the
pushpin's own count, unchanged, with the second tap of a pair now coming with
something attached. The honest comparison is not the two prices added up but what a
hand would have paid for the same page: a pin at 0.45 plus a hundred and twenty pixels
of whatever the nib is, which is 0.97 in graphite, 1.16 in blue and 1.45 in marker
ink — more than a run can even hold, in the last case. The number is the same on every
row because the *gesture* is the same on every row, and no hand laid any of it. (The
eighth is the VOLLEY, which charges a quarter of a meter, and it is the only one in
the family priced per *pin* rather than per press — because it is the only one whose
press is not a fixed amount of tool.)

The two that cast a tool are the interesting prices. A hand would pay 0.45 for a pin
and 0.35 for a ruler *through itself* — 0.80 for one crater and one badly placed
line — where this asks 1.00 for two craters and one line placed anywhere. Dearer, and
it should be, because what is bought is the thing the parent could never sell. And
the third pin is where all five thread rows turn: three pins pairwise inside 120
are three *pairs*, so a triangle of taps rules three page-crossing lines through one
patch of paper, or tears the page into ribbons, or closes a shape. The pencil makes
the third pin into a corner; the ruler makes it into an asterisk.

**The stapler was the last one in, and it needed its own idea rather than this one
repeated** — it is the one parent whose gesture is already the pushpin's, so what it
brings is not something to string. The VOLLEY is that idea, and it is above: the
stapler's *hand* on the pushpin's numbers.

**Many more are meant to come**, and the shape is built for them rather than for
these forty-five: some will keep one tool's draw style and take the other's
properties, some will be neither, the punch is a gesture and nothing else, the
spindle carries a whole second tool on the end of the arm, the corral's mark is not
an attack at all, the hem's price is decided by the drag, the clearing changes what
a sweep *reaches*, the fold hangs nothing on the arm and pairs two marks instead,
five string something between two pins and two pool round one, two of that five
string a whole second tool rather than a mark, and the last seven are ruled along a
straight edge — one of which rules its mark down *both* edges of the band, one of
which presses a whole second tool into the page one level inside its own block, and
one of which leaves nothing on the page at all and throws the whole of it clear of
the line instead — and one of which is a pair of scissors carrying a whole second tool
inside its own block the same way, pressed along the line between its two taps. A
fusion is a row in `Tools.list`
and a `fusionLine` in `src/upgrades.lua`, and nothing else in the game had to be
told they exist — the blush plate on the icon and the pairing screen in the
library are both read off `fuses` rather than written down anywhere. What the
families have in common is the test any fourth one will have to pass, and it is
worth being plain about — or rather, it *was*: **a fusion needs a gesture that goes
somewhere your hand is not.** The compass reaches away from you, a pin lands where
you tapped, and a ruler crosses the page.

That sentence was true of the first twenty-four and it was also the thing standing
between the catalogue and the other twenty-one pairs, because a pencil and a pen have
no reach to lend each other and never will. All twenty-one exist today regardless. The fourth family is what happens when
you stop treating that as a requirement and notice what was hiding behind it: **the
stroke is a gesture too.** A line you drag has a length, an inside once it closes,
and a mark left lying on the page afterwards — three things a ring has and a tap does
not — and it goes exactly where your hand goes, which turns out never to have been
the point. The six off the pencil are below, after the seven; the six off two brushes
with no pencil in the pair are after those; then the four that had to stop borrowing a
stroke, because their second parent has none; then the one where *neither* parent has a
stroke to lend and the scissors' own two taps carry it instead; then the three where what
the stroke lends is neither its length nor its inside but its two *ends*; and last the
one where the mark needs no carrier because the mark **is** the region.

#### What the seven ruler fusions are

The third family, and the one with the shortest argument behind it. **A ruler's mark
does nothing.**

Everything the band covers is hit once and thrown clear of the line to both sides at
once, and what that leaves is a corridor across the page — with a ruled pencil line
down the middle of it, which is not terrain, not fire, not paste and not a fence. So
the corridor closes the moment the crowd walks back into it. The ruler is the only
tool in the game that touches the whole page in one press, and it has never been
able to keep any of it.

That is what these seven fix, and they fix it the same way the other two families
fixed their parent: the second tool is what gets left behind. Nothing about the
gesture changes — press, the line appears through you; drag, it pivots about you;
let go and it comes down flat on everything lying along it, at the finished ruler's
13 across and 210 of shove. And then whatever else is on the row is ruled along the
line it landed on.

**Every one of the seven crosses the whole page**, and that is not seven decisions.
The ruler's own last level is "IT RULES THE WHOLE PAGE END TO END" — half a screen
diagonal, the only number in the game measured off the window rather than written
down — and a fusion is never dealt until both its lines are finished. A fusion built
on a finished ruler cannot land any other way. Which is what makes the family read as
one thing from the strip: whatever this card is carrying, you are about to draw it
across the entire page, through yourself, in one press.

**The MARGIN** is the pencil, and it is the only one of the seven that costs the
corridor nothing, because graphite costs nothing. What it rules is the band's **two
long edges** rather than its middle — which is the pair of dashed lines the ruler's
own aim has drawn since the tool was written, made real, and which puts the graphite
exactly where a ruler has always been weakest. Inside the band you take 12; a pixel
outside it you took nothing at all; now you take 9. The band does not get wider so
much as it stops having a cliff at the edge of it.

**The SPINE** is the pen, and it answers a question nobody had asked: *how long can a
fence be?* A pen draws about a hundred and seventy pixels of wall from a full meter,
at the speed of your own hand, through the crowd that is walking into you while you
draw it. This lays the page's whole diagonal in the frame you let go. The page is in
two — and it has no clock on it, because the pen's last level is that the line you
drew last stays until you draw another, and a ruler is one gesture exactly. Ruling
the next spine is what drops the last, and the one it drops comes off the paper all
at once and takes the rank leaning on it. What keeps this from being a run nothing
can reach is the camera: the wall divides where you *were*, the page keeps scrolling,
and the horde spawns off the ring beyond it. It is the one fence in the game you use
by walking away from it.

**The UNDERLINE** is the highlighter, and it is the row where the ruler's shove turns
out to be doing the work rather than being spent. Everything in the band is thrown
clear of the line — *across* thirteen pixels of burning nib on the way out, and
touching the band at all is two seconds of fire that goes with the body and keeps
ticking after it has left. The corridor is opened by throwing the crowd through the
thing that is holding it open. Nothing was written for that; it is the parent's shove
and the parent's burn landing in the same frame.

**The TRENCH** is the gluestick, and it is the one that does not do the family's job
— which is the clearest case in the game of a fusion being both parents rather than a
compromise between them. Paste holds, and a held body drops the shove it was carrying
before it is ever spent. So the ruler's shove, which is the whole tool, simply does
not happen to anything this catches. What lands is 12 across the band and a page-wide
bar of glue with the crowd standing in it: softened by half again so everything else
the run owns cuts deeper, torn on the way loose, and collecting whatever strays within
twenty-six pixels. The gluestick has never shoved anything and says so on its own row.
The ruler decides *where* the page stops, and a straight edge turns out to be a very
good way to decide it — a crowd does not walk round a bar of paste the way it walks
round a fence. It walks into it and stays.

**The PARTING** is the rubber, and it is the second panic button in the game after the
CLEARING. A rubber leaves nothing, so there is nothing to leave in the lane — and what
the rubber does instead is take the *band off the ruler*. What this lands on is not
everything within thirteen pixels of the line, it is everything within the ruler's own
length of it, and the ruler's own length is half a page diagonal. So it lands on the
page. The whole crowd, wherever it is standing, chipped for 2 and thrown straight away
from the line you pointed, bowling each other over for 5 on the way. What you are
choosing is an *axis* rather than a place, which is the only decision in it and is a
real one: turn it wrong and half the crowd is thrown at the half of the page you were
about to walk into. It kills almost nothing. What it buys is time and room, which is
the trade the rubber has always made and the only reason a tool is allowed to touch
every enemy on the page at once.

**The SEAM** is the stapler, and it is the third different way that tool has been let
out of its own repetition. Ten a meter, one press each, every one aimed by hand at a
15px circle on something that is moving: the stapler's own last level sells the ten
presses back as one drag, the HEM has an arm walk the drag for you and close it, and
this has a straight edge walk it and not close it. One staple every twelve pixels of
the line, so a page diagonal is a little over thirty — within one or two of what a
fully opened HEM lays round its rim. Like the trench it does not shove: the band takes
12, the wire takes 6 on top with a fifth going straight through at 18, and everything
caught is fastened to the paper before the push it was given is spent. And then the
whole line lets go at once: the wire comes back out two seconds later for a second 6,
so what the row really is is a straight edge that hits, holds, and hits again. At 0.9
it is the dearest single press in the game, and the reason is the
stapler's own invariant: every level in that line is written on "ten a meter is still
ten a meter", so wire is the one thing a fusion of it cannot get for free.

**The GUILLOTINE** is the scissors, and it is a real object in a real stationery
cupboard rather than the one everybody pictures: a straight edge with a blade hinged
to run down it. The scissors' whole price is the *gap* between their two taps — the
horde walks through it, so the row of blobs the first tap lined up is not the row the
second one cuts, and a cut has to be led rather than aimed. A ruler has no gap. So
what this buys is a cut that can be **aimed**, and what it pays with is the one thing
a ruler cannot give: a line that goes anywhere but through your own feet. 12 from the
band and 20 from the blades is 32 — the deepest single hit in the game, and the grin
has 34, so the tank goes on walking out of everything, which is its job.

And then the scissors' finale, which is the level this card is really about — and
the one that had to be *re-read* rather than copied. "THE HALF YOU ARE NOT ON GOES,
AND THEY GO WITH IT" is a sentence about a cut with you on one side of it, and a
ruler's line goes *through* you: at the moment the page opens there is no half you
are not standing on. Every other cut in the game settles that question at the tap
that placed it. Settling it here would pick a half off a rounding error, which is a
page-wide finale decided by nothing.

So this one never stops asking. **Straddle the slit and neither half goes. Step off
it and the half you left goes, with everything standing on it. Walk back across and
it is the other half instead.** Which turns the ruler's one central fact from the
thing that breaks the level into the thing that aims it: the pivot is your feet, so
the offcut is wherever your feet are not, and choosing which half of the page to keep
is *walking* rather than tapping. Nothing else in the game is aimed by where you
stand a second after you used it.

It is the same move the TEAR LINE made on the same level from the other end — three
pins are three cuts each choosing their own half, so what is left is a page in
ribbons — and neither takes anything from the parent. An ordinary cut still settles
its half at the tap, because a cut you placed with two taps has a side you *chose*,
and having it follow you afterwards would take a decision away rather than hand one
over.

The FOLD is still the row to read beside this one. It gave up the ruler's own finale
for the mirror image of the same fact — how far a chord reaches is not the tool's to
decide — and between them the two say the one thing worth knowing about fusing
anything into a ruler: the pivot is your own feet, and every parent level that
assumed otherwise has to be looked at. One of the two survived the look.

#### What the six pencil fusions are

The fourth family, and the first one that is not a gesture at all.

The twenty-four above are three tools lending their reach: a compass draws where you
are not, a pin lands where you tapped, a ruler crosses the page. Twenty-four of the
forty-five pairs the strip can make, and the twenty-one left over were the ones with
nothing to lend — a pencil and a pen are both a line you drag, and no amount of
looking at them turns either into a thing that reaches.

**The way in is to stop asking what the gesture reaches and start asking what the
line is.** A stroke has three things a ring has: a length, an inside once you close
it, and a mark that stays on the paper after you lift your finger. The pencil owns
all three — it is the cheapest ink in the game, it is what every run opens holding,
and its finale is the only thing on the strip that claims an *area* by drawing the
border round it. So the pencil is the fourth carrier, and the second tool is either
what the line is made of or what closing one means.

None of the six changes the drawing. Press, drag, lift, charged by the pixel — and
that is deliberate rather than lazy, because the whole family is about a gesture you
already have. What changes is what is under your finger.

**DECKLE** is the pencil and the pen, which is the pair you were issued on the first
day and the only fusion in the book that eats both of them. The pen cannot hurt
anything; the pencil cannot keep what it ringed. Each one is the other's ceiling, so
this is the row that says so out loud: a wall that scratches at 9 while you draw it,
in blue, 3 ragged pixels where a ballpoint lays 7 smooth ones, on the page for the
pen's nine seconds — and stinging for 1 a tick the whole time anything is pressed
against it, which is the pen's own contact level and the pen's own number. Close it
and everything inside is cut, and then *stays* inside, because a graphite ring is
not terrain and this one is. Drawing a ring, cutting it, and drawing the next ring
inside the first is a thing nothing else in the game can do.

It also keeps the pen's finale, so the last ring you drew has no clock on it at all
and drawing the next is what lets it go — and then the old one fades and *pops*
along its whole length, which makes replacing your own ring an attack. What holds
all of that down is the two damage numbers rather than a rule: 9 is being drawn
over and 1 is standing against the fence, and at 1 a permanent ring is a pen line
that happens to be closed. One field would have had to pick, and both picks are
wrong — a pencil that scratches for nothing, or a wall you can keep forever dealing
a skull a second to a rank with nowhere to go.

**STUB** is the pencil and the rubber, and it is one object rather than two: a pencil
with an eraser crimped to the end of it. It is the first of two tools on the strip
that do a different thing depending on whether you move. Drag and it is the pencil, every
number untouched. Tap — press and lift without going anywhere — and it is the whole
finished rubber at once, a circle at the point with 240 of shove thrown out of it and
what that sends flying knocking down what it lands on. Two complaints cancelling:
a pencil has no gesture for "not now", so the finger is down and the crowd is
arriving and all you can do is keep drawing; a rubber *is* that gesture and nothing
else, and its own trouble is that it has to be scrubbed, so it is only ever a weapon
in the hand of a run that was already holding it.

Both of the tap-or-drag tools ask the same question and they ask it of your *hand*,
which sounds obvious and was not. A mark lives on the page and the pointer lives on
the screen, so a finger held perfectly still while you walk is a finger the page is
sliding under — and the line it lays is real line, as long as you kept walking. Judged
on the mark, a panicked tap taken on the run reads as a deliberate stroke and the tool
does the wrong thing, which is precisely the moment either of these exists for. So
what decides is how far the finger travelled and how long it was down: a tap is brief
and it is still, and it has to be both.

**BLEED** is the pencil and the marker, and the trade is one sentence: the band gives
up touching and buys surrounding. A finished marker sets alight anything that crosses
it and lays 13 pixels of page doing it. This is the nib the marker was written with,
9 across, and *nothing* that walks over it catches. What catches is whatever you draw
a border round — the whole ring of them, standing in the middle of the band rather
than on it, and **the middle floods with the band's own sky when it closes**, so
you can see what you caught. That is not decoration. The tool asks you to judge an
area you drew the border of, and a border with nothing inside it is a line: you
cannot see what you enclosed, where a body has to be to be enclosed next, or
whether a ring that crossed itself counted. The wash is the tool telling you what
it thinks it enclosed, painted by the same test the burn is resolved with. A band that ignited on contact and on enclosure would have bought nothing
with the pencil, because everything inside a ring you just drew has already been
touched by the drawing of it.

**DRAG** is the pencil and the gluestick, and the name is the tool: to drag is what
your finger does and what the line does back. Exactly one of the gluestick's four
levels acts on something the smear has *not* caught, and it is the finale — the field
that pulls everything free towards the nearest ink. On a gluestick that gathers a
crowd into a hold that cannot hurt it. On a pencil the same field is feeding a blade.
So the hold, the softening and the tear all go, and that is the argument rather than
a trim: something dragged onto a pencil line does not need holding there. The field
it throws is the finished gluestick's to the pixel — the range went from 26 to 42
because the head went from 20 wide to 4, which puts its edge in the same place.

The line is grey rather than graphite-black, and that is the one place this row does
not look like the pencil it is. A tool whose whole job is to drag the crowd onto its
own line has to let you see the line with a crowd standing on it, and ink is the one
colour a body covers completely. Grey is the paste the gluestick lends, read as a
line: pale enough to stay visible underneath something, and the colour a smear goes
at its rim. What comes off the point is white flecks — paste, not lead.

**CUTOUT** is the pencil and the scissors, and nothing inside the ring is hurt. It is
taken off the paper with the paper and put down again in the far corner of the page —
no gem, no xp, nothing, because nothing died. **The middle of the ring is drawn
as page that is not there**, the same grey the offcut is: the ruling exactly where
it was printed and the white gone from between it, because scissors take the paper
and not the printing on it. And it is a *hole* rather than one pass — anything that
walks into it afterwards goes too, for as long as the ring is on the paper, which is
the scissors' own contract and what makes the grey honest. There is page missing for
exactly as long as you can see it missing. Which means it inherits the
scissors' bargain along with the scissors' effect, and the bargain is the point: a
border you can draw round *anything* cannot be allowed to kill anything, so it moves
what it rings instead — a ring is a broom, and you get everything back out of one
corner. The pencil's own
lasso claims an area for 4 damage — chaff, a chip off a skull — because the ring
costs nothing beyond the line you were already paying for. Four of these five ask
"what if the ring did more". This one asks what if it did something else, and it is
the only one that stops the pencil being a weapon at all.

**The catalyst changed with the family, and that is on purpose.** A catalyst is a
third line a fusion asks for and does not eat, so that a fusion is aimed at a build
rather than at a pair of tools. Every fusion above these once asked for a finished
SELLOTAPE. What the tape pays a run for is *time*, which is what a run that put ten
levels into two tools has been spending — but it says nothing about a line. These six
ask for the INKWELL instead: all of them are priced by the pixel, three of them need
one long unbroken gesture to work, and the meter is the only thing standing between a
pencil and the whole page. A run that finished the well is a run that has been
drawing, which is the run this family is for.

**And this family's argument was eventually turned back on the twenty-four above it.**
Twenty-eight of forty-five rows asking for the same card is not a condition, it is a
toll: a run that finished the tape opened half the book at once, and the library
printed the same word on twenty-eight pages. So each of the twenty-four was re-read
against the one question this family had asked first — *which line is this row's
economy actually about* — and eighteen had a better answer:

- **Six ask the FIXATIVE**, for a clock they leave running. HALO, UNDERLINE and WICK
  leave a burning band on the page for 3.6 seconds; SPINDLE, HEM and VOLLEY leave a
  pin or a staple carrying `freeze` and `life`. `scalePersistence` reaches every one
  of those numbers, so a finished fixative is the difference between a ring you drew
  round a horde and a ring the horde is still standing in. None of the six needs it:
  the band ticks and the staple bites either way.
- **Six ask the CARTRIDGE**, for the next press. Five are the threading rows —
  DOT TO DOT, STOCKADE, CORDON, SNAP LINE, TEAR LINE — where half a meter is two taps
  and therefore exactly one thread. The tempting read is that those want a bigger
  well, and the numbers say no: a pin stands for 4 seconds and a 0.5 press comes back
  in about 1.9, so the chain already crosses wells at base and what gates the shape is
  the trickle. FOLD is the sixth, because a fold is *two* presses and a base meter
  holds one.
- **Three ask the MAGNET**, for xp thrown out of reach. CLEARING, CRATER and PARTING
  are the rubber's three block fusions, and on all three the only field that can kill
  is `ram` — damage the crowd deals to itself, out past wherever you were standing.
  Every gem they earn lands where you launched it.
- **Three ask TOP MARKS**, for xp that never existed. PUNCH, GUILLOTINE and HINGE are
  the three whose signature is a cut, and a cut credits nothing: no gem, no xp, no
  kill on the tally. A run that answers every crowd by opening the paper under it has
  stopped levelling while the difficulty clock has not, and this is the one line that
  answers that. It is the price the DEADLINE's own section names and nobody was
  charging for.

**Ten still ask the tape, and what they have in common is the point.** LASSO, MOAT,
CORRAL, TACK, MARGIN, SPINE, TRENCH, SEAM, PALING and CLINCH are the rows where every
line with something to say would also be the row's own prerequisite — the MOAT is six
seconds of paste, so the fixative is what it cannot play without — or where nothing has
anything to say at all: a flat price is out of the blotter's reach, and a single
gesture has no chain to fit and no next one to hurry. **That is the tape's job.** It is
the catalyst for a row no economy line can speak to without becoming a tax, and asking
it of ten rows is a sentence where asking it of twenty-eight was a toll.

The SEAM is the clearest case, because it argues hardest for an ink line and must not
be given one: 0.9 is the dearest single press in the game, and the three seconds of
standing still it takes to afford the next one is *the only thing holding back a run
that would otherwise wire the whole page shut*. The cartridge halves that wait and the
well buys the second press outright. Either would be a catalyst that pays a run for
dismantling the row's own brake.

**STITCH** is the pencil and the stapler, and it is the STUB with its arguments the
other way round. There the tap is the panic and the drag is the work; here the tap
*is* the work — it is a stapler, used exactly as a stapler is used — and the drag is
what the work gets fastened to. Tap and a staple lands. Drag and you draw the
finished pencil's line, with a staple driven into each end of it, which is what a
stitch is: the folded wire a stapler makes, and a line held to the page at both ends.
The near staple goes in the instant you press, not when you let go — a stapler has no
fall and nothing to telegraph, and that is most of what the tool is, so the line grows
out of a staple that is already in the paper rather than arriving after one.

Every one of those staples goes straight through, and that is the parent's own
argument rather than a gift. The stapler rolls one in five, and its row says why in
as many words: a one-in-five on something you tap dozens of times a page is a *rate*,
honest because the sample is large — where the same roll on a pushpin you get two of
from a full meter would only ever be a story about that one pin. This gets two per
gesture. So the chance goes to 1 for exactly the reason it was set to a fifth, and
what is kept is the sentence rather than the number.

What pays for it is the level this row cannot have. The stapler's finale is the one
card in the game that changes a *gesture* — hold and drag and you run a seam of them,
ten a meter, a third of the page — and the drag here is already spent, on the pencil.
So the trade is a field that is missing rather than one that was nudged: thirty
staples along a line you dragged, or two at the ends of one you drew, and those two
go through whatever they land on.

#### What the six brush fusions are

The same family with the pencil taken out of it, and it finishes the brushes: six
pairs of them exist and all six have a row. **BUMPER** is the pen and the rubber,
**SWELL** the pen and the marker, **SCUFF** the rubber and the marker, and then the
gluestick's three — **PASTEDOWN** with the pen, **PULP** with the rubber, **MORDANT**
with the marker.

Nothing about the drawing changes in these either — press, drag, lift, charged by the
pixel — but one thing that was free with a pencil in the pair stops being free.
**With two ordinary brushes, nothing says which of them is the line.** The pencil
could never lose that argument: it is the cheapest ink in the game, it is what every
run opens holding, and its finale is the only thing on the strip that claims an area
by drawing the border round it. Put the pen and the marker together and you have two
nibs, each with a width, a price, a clock and a thing its mark does after you lift
your finger, and no reason to prefer either. Written without an answer, a fused brush
comes out as two rows averaged — some middle width in a colour neither parent uses,
doing a bit of both jobs — and a run holding it could not tell you what it had.

**The answer these six settle on: one parent's mark is the body, the other is what
happens at it, and the body is whichever of them is a *place*.** A pen line is
terrain and a marker band is a surface — both are somewhere a body can be standing.
A rub is an event that happens to whatever is under the tip and is nowhere at all
once it is over. So in the first three the pen is the line twice and the marker once,
and the rubber — in both of the pairs it is in — is what the place *does* to whatever
arrives at it.

Then the gluestick, which is three more pairs and the case that makes the rule say
what it means. A smear is a place too, so the pen and the gluestick are two places
and the sentence above settles nothing. **What settles it is that paste is the
stronger place:** a fence says where a body may not stand, and paste says where a
body *is* standing and will go on standing. So the smear is the mark in all three of
the gluestick's rows and the second parent becomes a property of it — the pen makes
the paste solid, the rubber turns it into a drain, the marker makes it burn. Worth
having in that order, because the fence is the one parent that could have argued the
point and it lost to the one thing a fence has never been able to do.

**BUMPER** is the pen and the rubber, and it says out loud the one sentence the pen
was written against. The pen's own row is blunt about it: a fence that shoves is not
a fence, because the shove would be worst exactly where the tool is best, throwing
the crowd back out of the corner you had just walled them into. That is true of a
pen and false of a wall, and the difference is which way the push points. A nib
shoves along its own travel and away from wherever your hand happens to be; a wall
shoves *out of itself*, and out of a wall is the one direction on the page that never
needs aiming, because the fence already knows which side of it you are on.

So the crowd does not lean on this fence, it comes off it — 240 of throw, twenty-seven
pixels of it, the finished rubber's own number. The damage is almost all second-hand:
2 for touching the ink, and 5 to whatever a launched body runs into while it is still
truly flying, which is where a rank pressed against a wall by the rank behind it
becomes a magazine of projectiles aimed at its own crowd. It keeps the pen's finale
too, so the last fence you drew has no clock on it — and a permanent wall that hits
back is only fair because drawing the next one is what lets the last one go, and the
one you released fades out and *pops* along its whole length on the way.

Three of the rubber's numbers are missing and none of them for balance. Leaning the
tip on something is what a rubber needs to stop being a tool you have to scrub — and
this mark already hits everything against it, along its whole length, on its own
clock, for nine seconds after your finger has gone; a resting hit at the nib would be
that same hit priced twice. The scrub discount prices a back-and-forth, and you do
not rub a fence back and forth: you draw it once and leave. And the crumbs a rubber
sheds off its travelling tip belong to a rubber travelling — a fence that shed eraser
crumbs down its whole length would be lying about what drew it.

**SWELL** is the pen and the marker, the two tools that share a colour and have never
once been mistaken for each other: three pixels of solid blue you draw to keep
something out, against thirteen of pale band laid under the crowd to burn it. What
they turn out to share is the thing neither can do alone. A pen's mark lasts nine
seconds and does almost nothing to anybody; a marker's mark does a great deal and is
gone in three and a half. **Nine seconds of burning band is the fusion in one
number**, and it is the pen's number rather than a new one — the burn itself is the
marker's finale untouched, two seconds on whatever crosses the ink, because what the
pen sells here is the life of the *mark* and not the length of a fire.

**Then the second half, which is the only mechanic in the family about your hand
rather than about the ink.** A swelled rule is a printer's rule that is heavy in the
middle and tapers to nothing at its ends — the shape a soft nib actually leaves,
since the faster it travels the less of it touches the paper. This row is that. Drag
slowly and you lay the pen's broad nib, seven pixels of blue, at the pen's full price
by the pixel. Flick and you lay the ballpoint the tool was written with, three pixels
wide, for half the ink.

Which is **the first choice the drawing has ever offered inside one stroke.** Every
other brush in the game is priced by the pixel and nothing else: a line costs what
its length costs, and how you moved your hand along it changed the shape of the mark
and never its worth. Here the same meter buys either a short heavy band you meant to
put somewhere, or a long thin one you got out of the way with — and both readings are
correct, because a thin stretch still burns whatever crosses it, on the same clock,
for the same nine seconds. What it will not do is both at once.

It is a threshold rather than a smooth taper, and that is honest rather than lazy: a
line you are *placing* — across a doorway, round the front of a crowd — is drawn at
something under a hundred pixels a second, and a line you are getting rid of, a flick
to put ink between yourself and something, is three or four hundred. There is very
little traffic in between. The tool has two states because the hand has two
intentions.

One marker level is missing and the nib is why. Layers stacking where you draw over
your own ink is only a card you can use if you can *see* where the ink is doubled,
and what makes it visible on a marker is the rim: a second pass pools, and the pooled
colour is the map of where the burn will land twice. A ballpoint has no rim — it is
one flat colour by design — so on this row the level would have been an invisible
tripling wherever two stretches of line happened to cross. The marker's own row
already says it: a choice you cannot see is not one you can make.

**SCUFF** is the rubber and the marker, and it is the STUB's shape on the other pair
it fits. Swipe and it is the finished marker, every number of it: thirteen pixels of
band under the crowd, 5 a tick to whatever stands on it, layers where the passes
cross, and anything that so much as touches it alight. Tap — press and lift without
travelling — and it is the finished rubber instead, the whole of it in one press: a
7px circle at the point your finger landed on, 240 of shove thrown radially out of
it, and what that sends flying knocking down what it lands on.

**Which turns the tap/drag split from a coincidence into a rule.** The STUB earned it
with an argument about a pencil — a line you commit to, with no gesture in the tool
for "not now" — and the argument turns out to have been about the *rubber* all along.
A rub is an event at a point, and there is no honest way to fold one into a mark that
has to be somewhere: a band that shoved would be a band nobody could be made to stand
on, which is the only thing a marker's four levels are about, and a nib that shoved as
it went past is a rubber you have to scrub, which is the rubber you already had. So
the pair gets a gesture each, and the marker keeps all four of its levels, because
nothing was taken off it to pay for the tap. (The SNAG, further down, is the third row
to take the split and the only one that takes it the other way up: there the drag is
the rub and the *tap* is a staple, which is what a pair with no mark to lend has to
do.)

What pays for it is the meter. The band is the dearest ink in the catalogue by the
pixel and the tap is a flat tenth of the well on top of it, so the two gestures draw
on one well and a page you have scribbled over is a page you cannot shove anybody
off. That is the whole of the tension in the row — and it is the STUB's too, against
the *cheapest* ink in the game, which is exactly what makes that one a panic button
and this one a decision.

**PASTEDOWN** is the pen and the gluestick: paste that has set hard, and both halves
of that are one flag. What is inside stays inside because it is *stuck* — the glue
unchanged, its freeze re-applied every tick, so what the smear caught is held for as
long as the smear is on the paper. What is outside stays outside because the paste is
a *wall*, filed as terrain at the head's own radius, so the crowd steers round it and
anything that reaches it is parked at the ink's edge.

And then the two halves fit together without a line of code being written for them,
which is the test a fusion of two finished lines is supposed to pass. The wall code
already refuses to move a *frozen* body — it was written that way so the crowd would
jam up against a glued thing instead of squeezing it out of the smear — so the bodies
the paste has caught are exactly the bodies the wall does not push out. The hold and
the fence agree about who is inside without either of them being told about the other.

The crowd outside gets stuck to the outside face, and that is the two finales meeting.
The gluestick's last level hauls everything free within reach towards the ink; the
wall stops it at the rim; and the tick that would have caught it in the middle of the
smear catches it there instead — held against the outside of the paste, taking the
pen's 1 a tick for leaning on it. A rank stuck to a wall is a rank that has stopped
walking, which is a second fence made out of the crowd.

It is dark blue rather than the glue's white, and that is not decoration: the mark is
terrain now and the crowd has to be able to read it as terrain the way it reads a pen
line. It fades on the pen's own schedule too — full colour for most of its life, pale
in the last stretch — which matters more here than it does on a fence, because what a
body does when *this* mark goes is walk out of a prison. And it keeps the pen's last
level, so the last one you drew has no clock on it at all. What holds that down is the
meter: 41 pixels of paste at the dearest ink in the game means one that encloses
anything is most of a full well, so what is being kept is one stroke's worth of page
rather than a fortress.

**PULP** is the rubber and the gluestick, and it is the CLEARING read backwards. That
row puts the rubber on a compass and everything inside the swept disc is thrown
straight out of it, because a rubber shoves away from itself. This one points the same
idea at the mark instead: everything near the paste is hauled *into* it and stuck
there. One row empties a place and the other fills one, and they are the same tool
reversed rather than two ideas.

**The reversal could not be a shove, and finding out why is what wrote the row.** The
obvious version is the rubber's push with its sign flipped — towards the line rather
than away from it — and it does nothing at all, because the hit knocks and *then*
freezes in the same breath, and a frozen body drops whatever push it was carrying. A
shove that lands a body in paste is a shove the paste cancels. So the shove had to
become a haul, and the gluestick already had the field for one: the rubber's 240 read
as a *speed* instead of an impulse, where the glue's own haul is 30. The reach does
not move — a 240 shove throws a body twenty-seven pixels, and the glue's field already
reaches twenty-six past the ink, which is the same arm's length measured from the
other end. The rubber does not reach further than the paste. It pulls harder.

Which turns out to be the better tool anyway, because a throw is over in a fifth of a
second and a haul goes on for as long as the paste is on the page. What the row does
is drag the crowd in continuously, hold it, and let you scrub the pile — and the
scrub discount is kept here where the BUMPER dropped it, for exactly the reason the
BUMPER dropped it. You draw a fence once and leave. You rub a pile until it is dead.
What pays for the reversal is the rubber's own last level, which cannot be here:
nothing is flying, so there is nothing for it to make a weapon of.

**MORDANT** is the marker and the gluestick: paste that bites. A mordant is the size a
gilder lays down to make gold stick, and the word is *mordere*, to bite — an adhesive
whose name means biting, which is the row before anybody wrote a number in it.

The trade is the shortest in the family. The gluestick is the strongest crowd control
in the game and deals nothing at all, on purpose, and three of its four levels are
written so that the damage comes from *somewhere else*: what it holds takes deeper
cuts, what comes loose comes away torn, and neither of those is the smear hurting
anybody. This row is the somewhere else. 5 a tick, the marker's own number on the
marker's own cadence, delivered by 41 pixels of paste that has already stopped
whatever it is delivering to — and the softening applies to it like it applies to
everything, so a body held in its own paste takes 7.5 rather than 5.

Two marker levels are missing and both are the pairing having already bought what
they were for. Setting fire to what touches the band exists to hurt something that
*kept walking*, and nothing that touches this mark keeps walking — it is stuck, in the
middle of a band that is already ticking at it. And the level that pays for drawing
over your own ink stops meaning anything on a head this wide: on a 13px band, coming
back over your own ground is a deliberate second pass, and on a 41px one it is any
curve at all, so it would read as a permanent tripling rather than as a reward for a
motion you chose.

**Their catalysts are picked per row, and that is the one thing the pencil's
six do not do.** All six of those ask for a finished INKWELL, which reads as one
sentence about a family whose rows differ in what they draw. These six differ in how
they are paid for, so each asks for the ink line its own row is about: the FIXATIVE
for the fence that has to outlive the panic it was drawn in and for the paste whose
whole worth is per second it is on the page, the BLOTTER for the nib that charges by
its own width, the CARTRIDGE for the rows spending one meter on two gestures or on
one you never want to lift, and the INKWELL for the widest mark in the game, where
the well is the difference between a bar of paste and a prison. It costs a run the
same four levels either way; a catalyst is a condition and is never consumed, so two
of them naming the same line costs nothing.

**Nine pairs were still missing after those and every one of them is a brush with a
block** — a tool with no line in it at all — which is the shape of what was left
rather than a coincidence. All nine are below: the stapler's four, then the five off
the scissors, which finished the catalogue.

#### What the four stapler fusions are

**PALING** is the pen and the stapler, **WICK** the marker and the stapler, **CLINCH**
the gluestick and the stapler, **SNAG** the rubber and the stapler. They are the first
rows in this family whose gesture is
not a stroke, and the reason is the sentence the nine leftover pairs all run into:
**you cannot make the stroke the carrier when one parent has no stroke.** A stapler
does not draw. It is tapped.

**What they borrow instead is the one block gesture that is a drag.** The stapler's
finale is the only card in the game that changes a gesture: hold and drag and a staple
lands every twelve pixels for as long as you hold it. That is a path across the page,
laid by a hand, at a fixed spacing — which is a stroke in everything but the name, and
it turns out to be all the family needed. Two of these hang a mark off that path and
the third puts paste on the wire. The fourth is the one that could not borrow it at
all, and it is the last of the four below.

Which makes them the pushpin's threading family with a single number changed, and the
two are worth reading side by side. A thread joins two of the tool's own drops that are
within reach of each other, and the reach is a hundred and twenty for a pin and
fourteen for a staple. At a hundred and twenty every pair of posts inside the range
gets a rail, so a handful of taps is **a shape you build** — the STOCKADE's triangle
round a spawn, the CORDON's Y across a corridor. At fourteen a post can only see the
next one in its own seam, so thirty presses raked along a drag come out as **one
continuous mark**. Same field, same code, opposite feel; and the pairing needed nothing
written for it, because a raked staple goes into the page through exactly the same door
a tapped one does.

**PALING** is the pen's third answer to the question it has been asking since it was
written, and the three answers are worth having together. The CORRAL is a fence with no
ends, ruled where your hand is not. The STOCKADE is a fence you build, post by post.
This is a fence you *drag* — and that is the one shape the other two cannot make, since
a corral is whatever circle the compass opened and a stockade is a rail between two
taps you placed one at a time, deliberately, slowly enough that the crowd walks between
the posts while you are still placing them. Here the posts land every twelve pixels of
your own drag and the rail follows them, so a hundred and seventy pixels of fence is one
gesture at the speed of a hand. A paling fence is exactly that object: a run of stakes
with rails between them, put up in one pass.

What it costs against the STOCKADE is the corner and the crater. A pin punches
fifty-one pixels of page and holds a tank for four seconds, and two of them from a full
meter buy you one rail; a staple is fifteen pixels and a 6, and fifteen of them from a
full meter buy fourteen rails in a row. So the pushpin's fence is a shape with teeth at
the corners and this one is a length of fence with wire all the way down it — the same
field read at the other end of its range. It keeps the pen's third level, which is worth
reading here: a rail comes off the page when either of its staples finishes, so a seam
left to run out pops along its own length, a staple at a time.

**WICK** is the CORDON dragged instead of placed, and the name is the row: a wick is a
cord that burns along its length and is held in place while it does. Being held is
precisely what the marker's band has always been short of — its band is the best ground
in the game and the worst to place, because it goes where your hand goes, which is
where you are, and the crowd it is for is the crowd you are trying not to be standing
in. The HALO answers that with reach and the CORDON with two chosen ends; this answers
it with a seam. Fifteen presses lay a hundred and seventy pixels of burning line, and
every one of them killed the chaff standing where it landed on the way in. The band
does not stop anybody and is not meant to: the crowd may walk through it, and what
walking through costs is the band and the staple both.

**CLINCH** is the only one of the three that strings nothing, and it is the gluestick's
contract moved onto a fastener. A smear holds everything standing in it for as long as
it is on the paper, because the hold is *re-applied* rather than handed out once. A
staple has never worked that way: it bites the frame it lands, holds whatever was
standing there, and everything that wanders onto the wire afterwards walks straight
over it. That difference is the whole fusion — every four tenths of a second the
circle is swept again and anything in it is stuck to the wire, for as long as the staple
is in the page.

Which turns the tool inside out without moving a number. A staple used to be a
fastening you aimed at one body; this one is a *spot on the page* that fastens whatever
crosses it, and a raked seam of them is a line the crowd sticks to. Nobody has to be
hit for it to work, which has never been true of this tool before — and it is what the
gluestick's own finale says out loud one tool over, the level that acts on what the
smear has *not* caught.

And then the ending was already written. The stapler's third level tears the wire back
out of the paper for a second bite, and on this row that bite lands on five seconds'
worth of collection, every body standing exactly where it was stuck — because the thing
holding it there is the thing coming out. 6 apiece, a fifth of them 18, and half again
on both from the paste, which is the gluestick's second level riding on the body the way
it always does. The glue's own tear is deliberately not here: coming loose costing
something is what the tear-out already *is*, and paying the same event twice would be
the row arguing with itself. The staples last five seconds rather than two, which is
between the pushpin's four and the smear's six — longer than the thing that punches a
hole, shorter than the paste itself.

**SNAG** is the rubber and the stapler, and it is the row this family was stuck on for
a long time — long enough that the file said so out loud. The trouble was real. A rub is
an event at a point and a staple is a fastener at the same point, so a seam of staples
raked along a rub is either two things happening in the same place or, worse, a shove
undoing the fastening laid next to it. Both readings are a row arguing with itself, and
a row nobody can describe in a sentence is a row that should wait.

What unstuck it is that the second reading is not a fault, it is the tool. **If a rub
undoes a fastening, then the rub is what takes the staple out** — and the stapler
already had a card about exactly that: its third level tears the wire back out of the
paper and bites on the way. So the seam is given up, and the carrier goes back to the
one the STUB found: a gesture each.

Tap and a staple lands, exactly as it lands off a stapler — 6 through a fifteen-pixel
circle, one in five going straight through, and the wire holding whatever survived for
two seconds. Drag and it is the finished rubber, unchanged in every number: 240 of shove
out of the line, chip damage, half price over ground you have already scrubbed, and what
it sends flying knocking down what it lands on. **And the rub takes the staples with
it.** Every one the tip crosses is torn out of the page on the spot, early, and that
bite lands with the crit *certain* rather than rolled: 18 through everything the wire is
holding, which is a skull, an eye or a blot outright and leaves the grin standing.

So the row is the only two-step gesture on the strip. Staple the front of the crowd down
a tap at a time, then sweep the rubber across the lot and collect. Nothing about it is
free: the staple is still small enough to miss with, the hold is still two seconds, and
the collecting is a second gesture out of the same well — so you have to *go back*,
across a page the crowd is still walking over, before the wire comes out on its own for
a fifth of the damage.

**What each parent gave up is one fact said twice: each loses the level that wanted the
gesture the other one took.** The stapler has no seam, because the drag is the rub —
which is the STITCH's trade word for word. The rubber cannot be leaned on, because the
press is the staple: leaning is a tip that keeps hitting where it rests, and it lands on
the press *itself*, so on this row it would shove the thing you were fastening a moment
before the staple arrived. Two levels out and one certainty in.

**The PALING and the CLINCH ask for a finished SELLOTAPE** — the ninth and tenth rows
to, and the last. It is not a lapse. The ink lines were the right ask for the twelve
rows a hand draws, because every one of those is priced by the pixel and the meter is
the only thing between a brush and the whole page. Neither of these is priced by the
pixel — they are priced by the press, 0.14 and 0.15, ten to a meter exactly as their
parent is — so a discount per pixel cannot reach them, a bigger well answers a question
they never ask, and a faster trickle buys a run that already gets ten presses a meter
nothing it will notice. The tape's qualification here is that it has nothing to say
about a press, which on this row is the whole of it.

**The WICK is the exception among the three, and it asks the FIXATIVE.** It is the only
one of them that hangs a clock off the wire: a marker's burning band at `life` 3.6 over
staples at `life` 2, and `scalePersistence` walks both. What a wick is worth is how long
it stays lit.

**The SNAG is priced both ways, and that is what puts it on a different line: it asks
for the INKWELL.** What it needs is not a discount and not a faster trickle, it is
*room* — the unit of play here is a chain of gestures rather than one gesture, and the
chain has to fit in a single well or it does not happen at all, because the hold is two
seconds and the meter does not come back inside two. The cartridge would only get you to
the next chain sooner. The fixative is the line the row wants most of all, since it
stretches the hold and the hold is the window you have to get the rubber back across —
which is exactly why it is not the ask, for the reason the CLINCH gives: a catalyst that
is the line a row cannot play without is a tax rather than a choice.

#### What the scissors and the stapler make

**HINGE** is the scissors and the stapler, needing SCISSORS, STAPLER and TOP MARKS
and eating the first two. It is the forty-first fusion, the last pair the ten tools
can make that anybody has written, and the only one of the scissors' five that keeps
the scissors' *gesture*.

The other four all took the taps away. Two pins cast the cut between them (the TEAR
LINE), a ruler lands it (the GUILLOTINE), a compass rings it (the PUNCH), a hand
draws round it (the CUTOUT). Here you still tap twice and the page still opens along
the line between the taps. **What changes is what the taps leave behind:** a staple
goes into the paper where each one lands, and the stretch between them fills with
more of them at the stapler's own twelve-pixel spacing. Then the blades come down
that line.

**Which answers the parent's one real weakness from the opposite end to the TEAR
LINE.** A cut is two taps with a gap between them, and the whole price of a tool you
can place anywhere on the page is that the horde keeps walking through the gap — the
row of blobs the first tap lined up is never the row the second one cuts. The TEAR
LINE's answer is to make the first tap a crater: kill what you lined up. This one's
is to make the line *hold*. Every staple is 6 through a 7px circle with one in five
going straight through at 18, and it fastens whatever it catches to the paper for two
seconds; the blades take a beat to travel, so what they arrive at is a row of bodies
that cannot step aside. A stapler is the tool that stops things moving and the
scissors are the tool that needs things to stand still. Nothing about that had to be
invented — it is two finished lines put in the right order.

And the wire outlives the cut, which is the part worth watching for. The slit closes
in a second and a half and the staples are in the page for good, so what is left
behind is a row of fasteners across the paper with half the page gone on one side of
them. That is what the name is: a line of wire along the line a page comes apart on,
and the page swinging off it.

**`sever` is the one parent level here that needed no re-reading at all**, and no
other scissors fusion can say that. The finale is a sentence about a cut with you on
one side of it; the TEAR LINE had to generalise it to three cuts at once and the
GUILLOTINE had to make it ask again every frame. These are still the parent's two
taps, so the half you are not standing on is simply the half you are not standing on.

**The price moved, and it is the only row in the game that moves one.** The scissors
are the one thing on the strip not paid for on the press: the anchor is free because
an anchor does nothing. Here it drives a staple, so it is charged like the press it
now is — 0.45 a tap, 0.9 the gesture, which is the SEAM's own price for the same
object arrived at from the other side, and the TEAR LINE's bargain in the same shape
(two presses, and the cut comes with the second one). Leaving the anchor free would
have paid out an unlimited stapler, since putting the scissors away is free and
always was: anchor, tap back on the anchor, repeat. Charging it closes that and makes
the cancel honest at the same time — you paid for a press and you got a press.

**What is deliberately not priced is the length.** A flat price per tap buys as much
wire as you were willing to put between the taps, which the HEM would have priced by
the pixel of rim. It is left alone because the choice is meant to be *where* the wire
goes rather than how much of it there is: a long line is staples spread thin over
ground nobody is standing on, and a short one is the whole seam through the crowd in
front of you.

#### What the scissors' three brushes make

**COLLAGE** (gluestick), **SCORCH** (marker) and **SHEAR** (rubber) — the last three
written, and one idea between them. The question the CUTOUT left standing was *what
carries a cut when there is no ring to close it with*, and the answer is the mark's own
**two ends**: you drag, the ink goes down, and when you let go the page comes apart
along the straight line between where you pressed and where you stopped.

Which is worth saying plainly, because it is a whole gesture nobody had used. A pair of
scissors is two taps with a gap between them and the gap is the price — the horde keeps
walking through it. Here the gap is *the line you were drawing anyway*. You are not
choosing two points and waiting; you are laying paste or fire or nothing at all across
the crowd, and the cut lands at the far end of that motion, on the page you just
covered.

**A line drawn back to where it started opens nothing**, and that is the shape rather
than a hole in it. A ring has no chord. The pencil is the tool that closes rings, so
the CUTOUT cuts what it *encloses* and these three cut between two ends — draw a circle
with one of them and you have drawn a circle.

**COLLAGE** is cut and paste, and the name is the mechanic. The smear pulls the crowd
onto the line while you are still drawing it, holds them there, makes everything
standing in it take half again, and then the blades come down the middle at 20. And
what the offcut carries off arrives **stuck**: four seconds of paste, laid on the crowd
in the far corner by the region that moved it. It is the hardest single piece of crowd
control a run can buy, and it is the reason the smear itself does no damage at all.

**SCORCH** sets fire to what the blades cut, so everything the offcut then carries to
the corner arrives burning and burns the whole way back. **This row could not have
existed a week ago**, and it is the clearest thing the reposition change bought: fire is
damage over seconds and a despawn is the end of them, so a cut that emptied half a page
would have been taking bodies out of the fire the same tool had just lit. The two halves
of the pairing would have spent the frame undoing each other. A cut that *moves* the
crowd hands the fire the one thing it wants, which is time.

**SHEAR** is the one that cannot use its own line, and the rule that says so is the same
one the six brush pairs settled on: a rub is an event that is nowhere at all once it is
over, so there is no mark left lying between two ends. So it keeps the parent's taps and
gives the drag to the rubber — **tap twice and the page comes apart, sweep and it is the
whole finished rubber** — which makes it the fifth row in the game that is a different
tool depending on whether your finger moves. What the pair is *for* is the one thing the
scissors are written never to do: `knock = 0` is on every cut in the game precisely so
no upgrade can move it, because a blade separates and does not shove. The rubber is the
biggest shove there is. Cut the page, then sweep the crowd over the slit and let the
missing paper put them in the corner. Both parents are tools of removal and neither
touches the other's leavings — a rubber cannot rub a hole shut, and must not be able to.

And that leaves none: the pen against the scissors is below, and it was the last pair
the strip could make.

#### What the pen and the scissors make

**DEADLINE** is the last pair the ten tools can make, and the only tool in the game
where the line you draw **is** the trap. Anything that touches it is off the page and
back in the corner furthest from you — and the pen's last level means the line stays
there until you draw another one.

So what a run holds is a **permanent line across the page that the horde cannot
cross**. Not a wall they path around: a tripwire they walk into. That is the trade,
and it is the sharpest one in the catalogue — **the pen gives up its wall for it.** A
wall is a line the crowd steers *around*, so a row that walled and lifted at the same
time would hardly ever fire; the only bodies to touch the ink would be the ones the
crowd's own shoving pressed into it, and the two halves of the tool would spend the run
undoing each other. Give the wall up and the line becomes invisible to them, and then
it is stronger than a fence ever was. The pen loses the level that made its mark
terrain and gets the level that makes its mark a place bodies cannot be.

Everything else the pen finished with still works and none of it argues. The line
stings for 1 a tick at whatever leans on it in the half-second before the lift takes
it. `pop` takes 4 off the crowd when the line finally goes — which on this row is the
moment you draw the next one. And the nib is the pen's own broad one, at the pen's own
price by the pixel, which is the only thing the meter ever asks this tool: **how much
page can one line reach across?** That is why the catalyst is the blotter rather than
the well — a discount per pixel is that question answered every time, where a bigger
well answers it once.

**And the price is the xp, harder here than anywhere.** Nothing the line lifts is
killed, so a run that hides behind one earns nothing at all while the difficulty clock
goes on climbing — and nothing leaves the horde either, so the page does not refill:
the same crowd comes back out of the same corner, over and over, for as long as you
stand there earning nothing. Then at ten minutes the eye walks on, and the eye is the
one thing the line does not touch. The tool postpones every fight except the one that
ends the run.

### When the catalogue runs out

Around minute 15 to 20 a run takes its 59th pick, and the catalogue has nothing
left it is allowed to offer. The horde is nowhere near finished — the spawner is
still turning the pressure up and will go on doing it — so the question is what
a level is worth from there.

It used to be worth nothing. `Game:openDraft` returned false, the level landed
in silence, and the run carried on unasked; the number in the corner went up and
meant less each time. The **endless lines** are what it is asked instead.

There are seven, and one level of one of them is deliberately small — a few
percent, the size of number the catalogue *opens* a line with rather than the one
it ends on:

| Line | Each level | Answers |
| --- | --- | --- |
| **PRESS HARDER** | +6% damage, on everything | sharpener *and* graphite |
| **MORE PAGE** | +15 max health, handed over full | fresh page |
| **FASTER STILL** | +3% move speed | paper plane |
| **SWEEP UP** | +12 magnet range, gems worth +4% | magnet *and* top marks |
| **TOP UP** | +10 ink in the well, filling 8% faster | inkwell, cartridge |
| **PATCH UP** | +0.25 health a second | sellotape |
| **STAYS LONGER** | what you left lasts and holds longer | fixative *and* laminate |

Seven rather than one because the draft lays down three cards and three cards
should still be a choice; one endless line offering the same thing three times
over would be a level-up you press through rather than answer, and every screen
in this game is built not to be that.

The seven answer eleven of the fourteen passive lines, and what is missing from
the list is missing on a rule rather than by oversight: **nothing endless may
multiply a number downwards.** Three numbers would have to — the blotter's ink
cost, the cartridge's delay before the meter refills, and the metronome's gap —
and a few percent off any of them taken for ever converges on free ink that comes
back instantly and a page where everything fires every frame. That is not an
upgrade to the meter or to the clock, it is neither of them being in the game any
more. The drawing half of this is built on paying for what you put on the page and
the fighting half on waiting for the next beat, and the last place either should
quietly be bought out is a line with no last level.

(The bandaid is the one line with no endless answer for no reason at all. Its
`mend` is an addition on a number with no bad limit, so one could be written; it
simply has not been.)

Everything in the table above is therefore an addition, or a multiplier heading
*up* from a number that has no bad limit — and where the catalogue line it
answers is written as a multiplication, the endless one is usually written as an
addition instead. That is the difference between four levels and none: ×1.2 four
times is 2.16 and stops, while ×1.2 for ever is a mark that never leaves the page.
Adding to the multiplier climbs in a straight line rather than a curve, so twenty
picks of **STAYS LONGER** is +1.2 rather than ×38.

There is no exception in the table, and there used to be one. A rate is an
interval, so faster means smaller, and the endless line that sold it was floored
at four times the rate a run starts on — a floor being the only honest way to
write a downward line with no last level, and an admission that it should not have
been one. It went with the catalogue line whose axis it was, when the scissors
became a tool and the sharpener's name moved onto the drawing half of the damage
split.

The **metronome** is that axis back in the catalogue, where a line has a last
level and 0.88 four times is a number you can write down. It is deliberately *not*
back past it: the one thing the endless lines may never do is what a floored
version of this would have to keep pretending it was not doing.

Three rules keep them out of the way of the game proper, and they are the whole
design:

- **They are not in `Upgrades.list`.** A line in that table is a candidate from
  the first draft onwards, and three percent of nothing offered against a weapon
  on level three would be a wasted card. They live in `Upgrades.endless`, and
  `Loadout:roll` reaches for them only after it has run out of real ones — so
  they fill what is left over and never take a place a genuine candidate could
  have had. In practice the first one appears somewhere between the 56th pick and
  the 64th, depending on how many unlock-only tools the run drafted.
- **They do not touch the slots.** The five-weapon, four-tool and five-passive
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

## What walks on

For a long time the horde was one axis and one binary. The axis was health,
speed and damage traded against each other — a blob, a faster blob, a tougher
blob — and the binary was whether it shot at you. Every enemy in the game
answered the same question, *walk at the player*, and every one of them was
answered by the same two verbs: outwalk it, or put damage in front of it.

That is a defensible place for a game like this to be. The *tools* are where the
variety lives, and the horde is deliberately the flat surface they are
demonstrated against. But it meant the ten minutes only ever got harder, never
different, and that a run's whole difficulty curve was a number going up
somewhere the player could not see it. What a player can see is the minute a
shape they have never met walks over the edge. There should be one of those left
for as long as the cycle lasts — and the old table spent its last unlock at 4:30
and then had nothing to say for two and a half minutes.

Five new things, and each of them exists to ask for something nothing else on the
page asks for. They are ordered by what they want from you rather than by how
hard they are.

### The wad, at 2:00 — the first thing that asks for a reaction

Everything else in the game is answered by *position over seconds*. The wad is
answered in half of one. Every three seconds or so, if you are inside 96 pixels,
it stops dead, wears a blinking red outline for half a second, and then runs 165
pixels a second down the heading it locked **at the start of that half second**.

The staleness is the whole attack. The outline is not saying "I am about to hit
you", it is saying *where the line is going to be*, and stepping off the line is
free if you are looking. It walks slower than a blob the rest of the time (18),
so it is never a chase; the dash is three times your own speed, so it is never a
chase either — it is a line drawn across the page that you are standing on or
not. It hits for 10, one short of the skull's 12, because being caught by one
should be the worst thing an ordinary monster does to you short of a skull
walking into you, and it should be, because it is the only one you could have
avoided.

Six health, so the answer to a wad you *saw* is often just to kill it while it is
standing still telegraphing. And a wad that dashes from point-blank sails
straight past you and has to walk back, which is the right thing to happen: it
disengages rather than grinding.

It is drawn as a screwed-up page — round on purpose, because a sprite in this
game is never rotated and a charger with a nose would spend half its dashes
pointing the wrong way. A ball is right at every angle.

### The blot, at 3:20 — the first that asks what your damage is *shaped* like

Almost everything a build buys here is area: the sword arc, the bomb, the sun,
the storm, the beam. Area is not really a choice in this game, it is the default,
and nothing on the page had ever made anyone feel that. A blot killed by a stroke
that also caught its three drops cost one swing. A blot killed by a single pellet
is three more things walking at you.

It is deliberately the blob's own silhouette, fatter and in solid ink, because
what it has to say across a page is "the same again, only there will be more of
it" — and that is a thing a shape can say without a single new idea to learn. It
pays 1xp itself and lets the drops carry the rest, so ignoring one is not a way
to be paid for it. The drops are quick (30) so the three of them get *past* you,
which is what makes a blot killed in the wrong place a mistake you are still
living with a moment later.

### The bulb, at 6:00 — the first that makes *where* you fight matter

Every build in this game ends up killing the crowd at arm's length. That is what
an aura, an orbit and a swing all are, and until now there was no cost to it
whatsoever. A bulb bursts when it **dies** — 14 damage inside 26 pixels, which is
the hardest single hit anything short of the boss lands and comfortably wider
than any melee radius in the game — and leaves a blot of ink on the page behind
it, so the ground the fight was on stops being ground.

It bursts on death and not on a fuse of its own, and that one rule is the whole
design: there is no second timer to read, no windup to learn, and a bulb caught
in another bulb's blast chains on the same frame. What keeps a wall of them from
being fatal is your own invulnerability window — four going off together is one
hit, exactly as wading through four puddles is.

The burst hits you and nobody else, and that is not an oversight. A burst that
thinned the crowd would turn the one enemy written to punish clearing at arm's
length into a *reward* for it.

It walks quicker than a blob (26), because a bulb that never reaches you is a
bulb you only ever kill at range, and then it is not a decision at all. Eight
health, so it is easy to kill early and easy to kill **by accident** late, which
is the joke.

### The grin, at 8:00 — the first your crowd control cannot answer

Half of what a built run does to the horde is *move* it. The pushpin and the
ruler shove, the spiral lures, the gluestick and the staple hold, the rubber
launches — and against everything that had ever walked on, all of those worked
completely. `knock` and `hold` were written for the boss for exactly that reason:
a boss that can be bowled across the page by a pin is a boss you never have to
look at. The grin is that idea at horde size, and it is the only row in the
bestiary that is a fact about *your build* rather than about a monster's attack.

A quarter of a shove and a bit under half a glueing, rather than none of either,
for the boss's reason: a tool that visibly does nothing is worse than one that
does a little, and every level of the gluestick line should still buy something
against it.

Thirty-four health is nearly three skulls and 11 speed is the slowest thing in
the game, and that is the trade the whole row is built on — it can always be
walked away from, and it can never be walked away from *cheaply*, because the
page it is standing on is page you have given up. It hits for 16, the hardest
contact hit in the table: the one thing you must not do is let the slow one catch
you.

It is the skull's own doodle drawn properly, at fourteen across — the biggest
thing on the page short of the boss, and the only enemy allowed past eleven.
Size is doing real work there. Nothing about being unshovable can be *seen*, so
the silhouette has to promise it before the first pushpin bounces off: half a
second of watching a build fail to move something is the worst possible way to
learn a rule.

And it is the one thing in the crowd drawn in black and white. The small skull
is blush, a thing sketched in pink pencil; this one is inked in and lit with
paper, and paper wipes the ruling rather than stacking on it — the eye's trick,
for the eye's reason. So the heaviest enemy in the game is also the one the page
shows through least, and it reads as an object lying on the sheet rather than as
another doodle drawn on it. The extra four pixels are everything the 10x10 skull
has to imply and has no room for: sockets deep enough to be holes, a nasal
aperture, and a jaw with teeth in it instead of two pips under the chin.

### And the bloodshot eye stopped coming to you

The redeye used to be the eye that walked in faster and fired more often, which
made it a *harder eye* rather than a different one. Anything that clears its own
melee radius — which is most of what a build sells — never had to think about
either of them, because both delivered themselves into the grinder.

Now it closes to 80 pixels, circles there, and backs off inside 56. The pellets
keep coming from a distance you have to **choose** to cross. It is twice as quick
as it was (34) so that it can actually hold that ring, and still well under your
own 58, so walking one down always works and always costs you the walk — that
price is the entire design. The fire rate did not rise with the range, because a
shooter you are crossing a page to reach is already firing for longer.

It is the one enemy in the game that will not come to you, and the red pupil now
means something more specific than "this eye is worse".

### Fifteen percent a minute

The horde's health is the one number in the game that goes up on its own, and for
a long time it went up too slowly to be the difficulty curve it was supposed to
be. It compounded 40% over a cycle's ten minutes — about three and a half percent
a minute — which meant a blob you one-shot in the first minute was a blob you
still nearly one-shot in the tenth, while a build that started with one weapon
finished with five. The ramp the player was actually climbing was made entirely
of *how many* things walked on, and health was decoration on it.

It compounds 15% a minute now, and the whole curve is that one number:

| minute | health × | a blob is | swings of a 4-damage pencil |
| --- | --- | --- | --- |
| 1 | 1.00 | 4 | 1 |
| 5 | 1.75 | 7 | 2 |
| 10 | 3.52 | 14 | 4 |
| 15 | 7.08 | 28 | 7 |
| 20 | 14.2 | 57 | 15 |

What that buys is the sentence at the top and the bottom of the table. **The blob
you meet in the first minute dies to one hit of the tool you were handed, and the
same blob in the fifteenth takes seven.** Both ends matter and they matter for
different reasons. The first is the game teaching you what a hit is worth on the
simplest thing it owns — the pencil deals 4, the blob has 4, the blob dies — and
that is a sentence a player reads once and keeps. The second is what makes a
build a *build*: at seven hits a blob, the four things you drafted are not
decoration on a pencil that was already enough, they are the reason the page is
still clearing.

**Per minute, not per cycle**, because the minute is the unit the player is
reading. It is the clock in the top of the HUD, so a health curve written in
minutes is one whose steepness you can check against the thing on screen; a curve
written per ten-minute cycle is a curve whose shape only the source knows. Damage
stays per cycle and steps once, for exactly the reason health cannot: a blob that
hits for a fraction more every minute is a blob nobody can learn, while a blob
that takes a fraction longer to kill every minute is just a fight.

**The first minute is flat**, and that minute is doing real work rather than
tidying the curve. A run at ten seconds has no draft behind it and a player still
working out which way the gesture goes, and any multiplier above 1.0 there costs
that opening sentence a second hit for no reason anything on screen could
explain. Scaled health is also rounded to a whole number now, which is the same
argument one level down: what a player learns about a monster is *how many hits*,
and 4.14 health is a fraction they cannot see and can only lose to.

**And the eye is not on this curve at all.** The boss's 900 is the one enemy
number in the game set by measurement rather than by design — it is what makes
the fight half a minute long for a strong run — and 15% a minute would have
handed the first one three thousand health and a fight of several minutes. So the
eye kept the per-cycle curve the horde used to be on: the first one is the 1260 it
was tuned to, and each one after it is 40% heavier than the last. Which is the
right unit for it anyway. There is one eye per cycle and you meet it once; what
should be true of it is that this cycle's is harder than last cycle's, not that
it grew while you walked over to it.

The one thing this does not change is the xp, and that is worth saying because it
is the reason the curve can be this steep at all. Experience already rides the
health multiplier, so a blob worth seven times the health is worth seven times the
xp — the horde takes longer to clear and pays proportionally more for it, and
experience per second comes out flat. The ladder still slows as it climbs, because
levels cost more; it never slows because the page quietly stopped paying.

### And eighteen percent in the legs

Health was the only number the horde had that went up on its own, and for a while
that was the whole answer: a longer fight is a harder fight, and the crowd walking
at you can stay the crowd you learned in the first minute. What it left out is
that the horde's difficulty is not only how long a body takes to kill — it is how
much of the page you are allowed to *walk away from*, and that number was fixed
for the length of a run however long the run went on.

So the legs climb too, and the shape of that climb is the entire content of the
decision, because speed is the one number here that cannot compound. A blob taking
15% longer to kill every minute is just a fight. A blob 15% quicker every minute is
not a fight at all — after enough minutes it is faster than you, and the moment
anything in the horde is faster than you the one counterplay the *whole* crowd has
is gone. Not a weapon's counterplay, not a build's: the horde's, the one every
player finds in their first thirty seconds, which is that you can leave.

And the room is smaller than it looks. You walk 58px a second and the fastest
thing in the game is the bat's 38 — two thirds of you, and that is the widest gap
any curve here has to play inside. One percent a minute, which sounds like
nothing, draws them level at minute 32. One and a half gets there at minute 21.
Both of those are inside an endless run rather than past the end of one, and a
player who has drafted the paper plane four times only pushes it out another
eleven minutes. Driven with a player who does nothing but run away, one and a half
percent a minute has a doctorate's third cycle touching him two thousand times a
minute — which is not a harder run, it is a run with the horde taken out of it and
a wall of bodies left in its place.

**So the horde walks towards a speed it never reaches.** Eighteen percent above
the row's own number, and every six minutes it covers half of what is left of the
gap:

| minute | speed × | a bat is | at a doctorate |
| --- | --- | --- | --- |
| 0 | 1.00 | 38 | 42.6 |
| 6 | 1.09 | 41 | 46.4 |
| 20 | 1.16 | 44 | 49.5 |
| 60 | 1.18 | 45 | 50.2 |

Against your 58, all the way down. The bottom row is the one the number was
chosen off: 50.2 is where a doctorate's bat converges and it is 87% of you, so the
hardest class in the building at the end of an hour is still a class you can walk
out of — and it converges rather than passing through, so there is no minute at
which that stops being true.

**An approach rather than a capped climb**, and the difference is a minute you
could point at. A ceiling reached by an exponent is flat afterwards, and where it
would land — around minute seven — is early enough that most of an endless run
would be spent on the far side of it, with the horde's legs the one thing in the
game that had visibly stopped moving. A curve that never arrives has no such
minute in it. Nothing is flat, nothing is ever quite as bad as it is going to get,
and the last few percent are spread over an hour nobody will play in one sitting.

**The ceiling belongs to the run and not to the course.** The two multiply: what a
class buys is 4% a rung at every minute of the run (see **The course you sit it
as**), and what the minute adds sits on top of that. Capping the *product* instead
is one character shorter and quietly deletes the course's row — a doctorate would
reach the shared cap by minute three and a half, high school by minute nine, and
from there on all four classes would walk at exactly the same speed. The dial you
paid for would be a dial that bought you the first three minutes.

The one number in the bestiary this had to be checked against is the wad, because
it has two speeds and both of them scale — what it walks at, and what it *falls
forward* at. Its lunge is 165px a second for 0.42 seconds, which is 69px of the
96px range that triggers it: the charge closes distance and never crosses the
whole of it, so a wad that picks you at the edge of its range still has a walk
left afterwards. At the very top of both curves that lunge is 92px, four short of
the range. Which is the invariant surviving on purpose rather than by luck, and
the reason it is written down here.

### Champions

A champion is not a row in the table and never will be. It is the same monster
drawn twice the size, at 3.6× the health, and it costs no art, no behaviour and no
unlock time — which also means every enemy added from here on is a champion-able
one the day it lands.

The reward comes for free too, because xp already rides the health multiplier:
something 3.6 times as long to kill is worth 3.6 times as much, and there is no
second number to keep in step.

**The mark used to be ink and is now the page.** For most of this game's life a
champion was the same body gone over a second time in heavier ink, and on paper
that is the better idea: ink is the darkest mark available, it reads at any
distance, and it costs no page at all. What it does not survive is the crowd it
has to be read in. The page holds two hundred bodies and a champion is one arrival
in seven; a one-pixel rim on a blob touching four other blobs is a rim you go
looking for, and a mark you have to look for is not a mark, it is a detail.

A size cannot be missed, and it brings a second sentence the rim never had. The
radius grows with the drawing, so a champion is not only longer to kill — it is
harder to miss with a pellet and harder to squeeze past in a gap. Which is what a
target should be. The rim only ever said "this will take a while"; the body says
that *and* "you are going to have to deal with me", and the second half is the
half that changes where you stand.

What it costs is the one thing the rim was free of: page. Every seventh arrival
past 3:30 now stands on four times the paper it did, and that is why the ceiling
below matters more than it used to.

3.6 health against only 1.25 damage is still a deliberate mismatch. What an elite
should be is a *target* — something in the crowd worth turning towards and
spending a cooldown on — and that wants health, not damage. An elite bat that hit
like a skull would be a thing that killed you from off screen; an elite bat that
takes eight times as long to die is a thing you noticed. The damage moves at all
only so that walking into one still reads as a mistake.

None before 3:30, because a champion in the third minute is just a blob that took
a while, and then a chance climbing to one in seven and stopping there. That
ceiling was a nicety when the mark was ink and is load-bearing now that it is a
size: past one in seven the double body stops meaning "that one" and starts being
how big the horde is. The boss is never one: the eye already is what a champion is
pretending to be, and 3.6 times 900 is not a fight anybody finishes.

### Blow-ups

The same trick again, taken to the far end of the same axis: the same monster at
**three** times the size, on five times the health and twice the damage. Nine
times the paper, and — because experience rides the health multiplier — five times
the reward.

It used to be one number for all of it: twice the drawing was twice the health,
twice the damage and twice the reward, and there was nothing priced separately to
keep in step. That was the better shape and it stopped being available the day the
champion took the ×2, because a giant then had to be ×3 and three times the
health is not a fight. Three times across, dying before you have finished walking
round it, is a giant that never got to be in the way of anything.

So five. And five rather than six or seven, because a giant is *not* the longest
fight on the page — a champion is nearly that already at 3.6, and the gap between
3.6 and 5 is deliberately much smaller than the gap between 2 and 3. What a
champion is is health. What a giant is is **space**. Something that was the biggest
body *and* the longest fight would be a mini-boss wearing a monster's art, and the
game has a mini-boss and it has an eye on it.

The damage stayed where twice the drawing had put it, and is now the one number
here that neither of the other two moved. Three times a grin's 16 is most of a
health bar in a single contact hit — from the slowest thing in the game, wearing
the loudest silhouette in the game, after a line of text has appeared with its
name on it. Anything that telegraphs that hard and hits that hard is not a
monster, it is a punishment for a misread. So the champion's mismatch applies
here too, one step further out: the standouts buy health, and the damage moves
only enough that walking into one still reads as a mistake.

**The pair is one axis now, and that is the real cost of the change.** The two
used to be told apart by *kind* — ink against paper, a health bar against a shape
— and are now told apart by *how much*, which is a weaker thing to ask anybody to
read in a crowd of two hundred. Two things that were already here buy it back.
The first is rarity: a champion is a seventh of the horde and a giant is a handful
in a whole run, so the ×3 is almost always standing next to the ×2s rather than
lost among them, and you have probably not seen one for a minute. The second is
that a giant is the one of the two that says its own name — which is what the
line of text was always for, and it earns its keep now in a way it did not when
nothing else on the page had changed size.

They stay mutually exclusive, and that is no longer a judgement call. Together
they would be eighteen times the row's health at six times across: a blob
standing on more page than the boss does, in a box a boss fight would not hold.
It is not slower. The obvious version of this idea is a lumbering giant you walk
away from, and that version is a wall rather than a monster: what makes a big bat
frightening is that it is still a bat.

What makes it fair is the radius. The body grows with the drawing, and every hit
radius, every separation pass, the box, the pen lines and both spatial hashes
read the radius off the monster rather than off its row — so a thing three times
the size is three times as hard to miss and three times as hard to squeeze past,
and not one weapon in the game had to be told the idea exists. It is also what
stops there ever being a third standout: a sprite scale is a whole number, so
there is no room between 2 and 3 to put one. A monster you could miss by
shooting at it, or walk through the middle of, would be the one unfair thing on
the page.

**And what it throws is as big as it is.** For a long time the rule was the
opposite: a giant bulb's blast and a giant eye's pellet were the numbers written
on the row, and only the damage grew. That was defensible while a standout was ×2
and it stopped being defensible at ×3, because a monster drawn three times the
size promises a three-times-the-size attack and delivering a ring barely wider
than its own silhouette is the art telling a lie. It is the same argument the hit
radius already won: a body that grew had to be harder to miss, or it was cheating
in the player's favour and looked wrong doing it.

So there is a `reach` on every arrival, equal to its size, and it multiplies how
**big** an attack is — the bulb's blast, its wet, a pellet, a tear, the puddle a
tear leaves, and how far a split throws its children. What it deliberately does
not touch is *when* an attack comes or *where from*: firing range, pellet speed,
the beat between shots, the wad's charge distance, the redeye's standoff. A giant
eye fires a bigger pellet from the same distance on the same beat. That is one new
thing to learn about a giant; four would be a different monster.

The pellet's hitbox and its drawn size come off the one number, and that is not
tidiness — it is the rule that a silhouette may never lie about what it will hit,
which this game keeps everywhere else too.

**The bulb is where this gets loud, and the number is worth seeing.** Its blast
radius is 26, which was chosen to be comfortably wider than any melee reach in the
game so that a bulb dying at your feet is a hit you take. Tripled it is 78 — a
circle 156 pixels across on a page that is 320 wide and 180 tall. Half the screen.

Which may well be right. It is one hit of about 28 against a hundred, it goes off
through the invulnerability window like everything else, *you* killed it, and it
needs a blow-up roll to land on the one enemy in nine whose whole design is that
killing it costs something — call it one in a thousand arrivals. A lightbulb three
times the size going off and taking half the page with it is a thing a run should
get to see once and talk about. But it is a different enemy from the one the 26
was written for, and if it turns out to be too much the number to bend is the
blast and never the pellet: a hitbox has to match its art, a blast radius answers
to nothing but taste.

**A giant blot leaves blots.** Everywhere else in this game what comes off a
monster is as hard as the monster was — a blot's drops carry the blot's own scale,
so a champion blot leaves three double-size drops and that is exactly right. At
three times the size it stops being right. A drop is six pixels across with two
health; tripled it is a body wider than a grin that dies to anything at all, which
is debris rather than three more fights, and it makes the biggest version of this
enemy the *least* interesting one.

So the row says what a blow-up of it leaves instead, and what a giant blot leaves
is three ordinary blots — which then do what a blot does. One giant becomes three
blots becomes nine drops. The row is saying the same sentence at both sizes — this
thing is two fights — and the enormous one says it twice: the area you needed the
first time you met a blot is the area you need three times over, arriving in
waves.

It cannot run away with itself, because the children arrive at the ordinary scale
and so are not blow-ups of anything. Three levels, never four. And they arrive as
monsters of the minute they land in rather than of the minute their parent walked
on, which is the one place the game breaks its own rule about inherited difficulty
— worth the break, because the alternative is carrying a second unmultiplied scale
on all two hundred bodies on the page to serve a single row.

**The chance is a meter rather than a probability**, and this is the part worth
arguing for. Every arrival adds a hundredth of a percent to a number, that number
*is* the chance, and it goes back to nothing the moment a blow-up lands.

A flat chance would fail in both directions at once. It clumps: two giants in the
same second is a thing a flat roll does regularly, and a thing the player reads
as the game having changed the rules. And it droughts: a run can go four minutes
without one and the idea quietly stops existing. A rising meter can do neither.
The arrival right after a blow-up is the least likely thing in the game to be
another one, and the climb goes on until something gives — capped only to bound
the wait, at a ceiling that puts the worst roll in the game at about two minutes.

Counting arrivals rather than seconds is deliberate too. The page spawns ten a
second while it is filling and almost nothing while it is full, so seconds are
not the honest unit — monsters are. It also means how often you meet one is
partly a fact about your build: a run clearing the page twice as fast is being
handed twice as many arrivals and therefore twice as many giants. That is the
same bargain the floor already offers — clearing the page buys more page — and it
is the right way round.

Nothing before minute five, on the same clock the drills read, so cycle two opens
past the gate and endless runs need no second rule; and the rise leans up a fifth
every cycle, so a tenth cycle meets them oftener as well as harder. It comes out
at nine in the back half of a first cycle and a little over twice that in a
fifth. The ceiling never moves, for the champion's reason — which is now the same
reason twice over, since both marks are sizes: a size you see too often stops
being a size at all and just becomes how big the crowd is.

And it gave `MORE OF THE SAME` the punchline it was waiting for. The rise is four
times as fast while that surge runs — twenty seconds is the one stretch of the
run where the page has stopped varying *what* it sends, so what it varies instead
is how big one of them is. It works out at about one giant per surge, which is
likely rather than certain, and that is on purpose: a surge that guaranteed one
would be a fourth kind of schedule in a game that already has three.

Two small things fall out for free. A blot blown up bursts into blown-up drops,
because what comes off a monster is exactly as hard — and now exactly as big — as
the monster was. And what does *not* double is reach: a big bulb's burst covers
the same ground and a big redeye's pellet is the same pellet, with only the
damage riding the multiplier. That is the bargain the per-cycle damage step
already makes, where a cycle-three pellet looks exactly like a cycle-one one.

### Fury

A champion is the same monster at twice the size. A giant is the same monster at
three times it. There is no four: a sprite scale has to be a whole number to keep
the drawing on the pixel grid, and four times a grin is wider than the boss. So
the size axis is finished, and the third thing an arrival can be had to be
something else entirely.

What it is is the thing the other two deliberately are not. Both of them are
*slower to kill* — a champion is 3.6 times the health and a giant five, and both
move their damage barely at all, because a standout should be something you turn
towards and spend a cooldown on rather than something that kills you from off
screen. That is the right call twice over and it leaves an obvious gap. Nothing in
the horde has ever arrived **angry**: quicker than its row walks, hitting harder
than its row hits, and no longer to kill than its row takes.

That is a fury, and it is the same monster gone over in red pen. A quarter again
on its legs, half again on its damage, exactly the row's health, and the whole
body redrawn in two colours: red where the drawing was mostly made of one mark,
black everywhere else.

**The mark is the whole body, because the champion taught that lesson already.**
A champion used to wear a one-pixel rim of heavier ink and it did not work — a rim
on a body touching four others is a rim you have to hunt for, which is why a
champion is now a *size*. Fury cannot be a size, so it is the loudest thing left:
this page is a pencil palette on blue ruling, and a body that is red and black and
nothing else is louder than any rim and costs not one extra pixel of paper. Which
is what pays for the other half of the idea — fury is allowed to land *on top of*
a champion or a giant, where those two can never land on each other. Two sizes
together would be eighteen times a row's health on a body standing on more page
than the boss; a colour on top of a size is just a big monster that is also angry.

**The numbers are aimed at one row.** A bat is 38 and the fastest thing in the
horde, against a player's 58. Run 38 through a doctorate's class and the run's own
climb and this, and it comes out at 60 — *over* the player, which is the whole
point and the first time the game has ever done it. The horde's one universal
counterplay is that you can leave; an enraged bat is the one arrival you cannot,
and a bat is 2 health, which is exactly what makes that fair. Everything else
stays under: an enraged blob is 31 and an enraged skull 24, so for the rest of the
horde a quarter is a shorter breath between you and it rather than a chase.

Half again on damage is more than either standout gets, and it is the champion's
mismatch read backwards. A champion buys health because what it should be is a
target. Fury buys none, so what it has to be instead is a threat — an arrival that
came faster and hit for what the row always hit for would be a champion with the
interesting half taken out. An enraged skull is 18 of your hundred and an enraged
grin 24.

Health is untouched, which settles the reward without a second number anywhere.
Experience rides the health multiplier, and an enraged blob is not a longer fight,
so it pays exactly a blob. A run is paid for the killing and never for the fright.

**How often is the giant's own meter, run twice.** The same hundredth of a percent
added at every arrival, the same ceiling, the same lean per cycle — with its own
number to climb, so the two are independent rolls rather than one roll with two
outcomes, and an enraged giant is the product of two rare things. Nothing before
minute three, which is earlier than a giant because this costs the page nothing,
and not from minute zero because the first minutes are where you learn what an
ordinary body of each row does — a red one before then has nothing to be read
against. And it says its own name the first time one walks on, once, like a giant
and like every drill: `GONE OVER IN RED PEN`.

**It only happens at a doctorate**, and that is the one fact here that is not
about an arrival. Every other rung of the course ladder is the same game with the
numbers moved; this is the one thing the top of the ladder has that the rest of the
book does not have at all. The boss is never one either — an eye would take a fury
perfectly well, and may not have one because the fight is a fixed thing you have
learned, and a boss that was quicker across its box and hit for half again on some
runs and not others would be the one encounter in the game whose rules changed
behind you.

**The two colours are worked out from the art rather than written down**, and that
matters more than it sounds. There is no table saying what each of the eight
colours becomes, because no such table can exist: ink is the *fill* of a blot and
a drop and the *detail* of every other monster in the game, so any fixed answer
either leaves the two black-bodied rows unchanged or blacks out everybody else's
eyes. So the drawing is asked instead — whichever mark it is mostly made of
*inside its own outline* becomes the red, and everything else becomes the black.
Inside matters: this game outlines everything, and counting the whole drawing
hands the majority to the edge and turns a bat and a grin inside out.

Which means every enemy ever added is enrageable the day it lands, with no second
palette drawn for it — and so is every reskin a lesson does to the crowd, so
music's clefs and quavers go red in their own shapes. It costs
one thing, once: the eye and the red-eye are the same eleven pixels and differ only
in the colour of the pupil, so enraged they are the same body. What still tells
them apart is 34 against 9 on their legs, which was always the louder half of that
distinction anyway.

### What the boss brings with it

The escort gained a wad and a bulb, two apiece against the bat's five, because
those two are the ones the arena changes the most. A wad's dash is dodgeable on
an open page by walking off the line it drew; inside a box the line has a wall at
the end of it and the room to dodge into is room the eye is also using. A bulb is
worse — its burst is ground taken away, and the whole point of the box is that
there is only so much ground. Both stay low, because either at bat weights would
make it a fight about the escort rather than about the eye.

### The weights held still

Blob and bat are still half the horde between them and everything else is trim.
Nine kinds sharing the other half means no single one of them is common, which is
correct: the wad, the bulb and the grin are all *events*, and an event that
happens six times a minute is weather.

### The page has no directions

There is a thing wrong with this game at minute six and it took a long time to
name. The ramp is fine — health is climbing 15% a minute, the horde has a floor
that rises, the wave timer is winding down — and the run is still getting harder
in a way you can feel. But it has stopped getting *different*. The wave timer
bottoms out at 0.22 seconds somewhere around minute five and never moves again,
the page is sitting at its cap, and everything the spawner has left to say is the
same sentence louder.

The deeper version of the same problem is that **the page has no directions in
it.** Every monster in this game walks on from a uniformly random bearing on a
ring just outside the camera. Averaged over a second that is pressure from
everywhere at once, which means there is no such thing as a good place to stand
and no such thing as a bad one, and running is a thing you do to buy a second
rather than a decision about anything. A page where every direction is the same
direction is a page with one axis, and after minute five that axis is spent.

So: **drills.** Five shapes an arrival can have, and each of them is a different
question the page is now able to ask.

**The line** is a wall along one edge, marching in step. It is first and it is
the one everything else is measured against, because its counterplay is visible
from the moment it walks on: a wall has *ends*, and if you commit early you can
be past one before it closes. Fourteen of them fifteen pixels apart is two
hundred pixels of page, which on any screen this game runs on is a wall you can
get round and a decision about whether to.

**The ring** is the same event with the ends taken away. Twenty of them at even
angles, closing. There is no round it, only through it, and it is the only drill
whose shape the chase itself draws rather than fights — a ring of things walking
at you is already a ring closing, so it needs nothing but the spawn.

**The grid** is a block, four by four, marching. It is the only one of the five
that is dangerous for a reason other than its shape: a block is *deep*. A wall
you cut a hole in is a wall you are through; a block you cut a hole in has
another rank behind it, so it is the one you cannot finish before it arrives.

**The pincer** is two walls on opposite edges walking through each other over
wherever you were standing when it started. It is specifically the punishment for
the habit the hot side teaches, which is why it arrives after it.

**The hot side** is the odd one out and the subtlest: for eighteen seconds every
ordinary arrival comes over one edge. It is not a thing that happens, it is a
thing that is *true for a while* — the only drill you can be inside for several
seconds without noticing, and eighteen seconds of the whole horde coming from one
place is a bigger event than any single wall, spent slowly.

The marching is the part that surprised me by being free. `Enemy:lure` already
existed for the spiral — give a monster somewhere else to walk to for a while —
and a wall is just every member lured at *its own* point straight across the
page, offset by exactly the amount it was spawned by. Lure them all at the same
point and you get a funnel that collapses onto the player in the first second;
offset them and you get a wall that stays a wall. And the lure *lapsing* turns
out to be the whole event: it holds for seven seconds, a blob walks twenty pixels
a second, so a wall covers about two thirds of the way in and then, all at once,
every one of them turns and remembers you are there.

One rule sits over all of it and it is what keeps the game measurable: **a page
may shape an arrival; it may never price one.** A drill spawns through the same
path everything else does, so what walks on is that minute's horde at that
minute's health with that minute's champions in it. What a drill changes is where
the crowd is standing when you look up.

### What the bell means

Drills belong to the page. The other half of this belongs to everybody, because
some things should mean the same in every lesson.

**The bell rings** and for fifteen seconds the floor lifts by 60% and the batch
doubles. Then — and this is the part worth arguing for — **the room settles**,
and for eight seconds almost nothing arrives.

That lull is the only place this game breaks its own rule that clearing the page
buys you more page and never a rest. The floor exists precisely so that a build
which empties the screen is answered with more horde instead of quiet, so that
kill speed converts into experience rather than into calm. Breaking that once, on
a schedule, would be a bug. Breaking it *only ever as the back half of a swarm*
is a feature, because it makes both halves legible: a lull nobody earned is just
a gap in the game, while a lull that arrives when the swarm ends **is the swarm
ending**, and that is a thing worth being able to feel.

It also scales itself, which an absolute number never would. Nothing despawns, so
a quiet does not empty the page — it stops the refill. What the eight seconds are
actually worth is however much of the swarm you can clear in them: a run that is
winning gets a breather, a run that is drowning gets almost nothing, and neither
case needed a number.

The third one is **more of the same**: for twenty seconds the horde is about 95%
one kind, drawn from whatever has unlocked. This is the axis the bestiary is
already written along — the blot asks what your damage is *shaped* like, the
skull asks whether you have any single-target at all — and twenty seconds of
nothing but skulls asks that question with the volume up. Twenty seconds of
nothing but bats asks the exact opposite one. The blob is kept out of the hat,
because twenty seconds of the default is not an event.

Mechanically it is the `crowd` dial no subject has ever turned, turned by the
clock instead and then let go of.

### Taught once, then trusted

Every drill and every surge says its own name the **first time it happens in a
run**, over the bottom of the page where the run says what you just took, and
never again. A LINE ACROSS THE PAGE. THE BELL RINGS. THE ROOM SETTLES.

That is the whole of how these are taught, and the once is deliberate on both
counts. Once, because a wall crossing the page is not a subtle thing and a player
looking at one while being told what it is called does not need telling twice —
and because at one every forty seconds a permanent banner would become furniture
inside two minutes. But *at least* once, because two of the five are genuinely
hard to notice from inside: the hot side is a statistical fact about the last
eighteen seconds, and the quiet is an absence. Neither announces itself.

The nice consequence is that an endless run's second cycle is silent by
construction. It has already spent every name it owns, which is correct — by then
none of it is news.

### Bigger, and closer together

Both schedules are keyed to *minutes of horde* rather than to the wall clock,
which is the same number the health curve reads, and one line falls out of that
for free: **minute ten is cycle two's minute nought.** A run that carries on past
the eye arrives at its second cycle with all five drills already in the bag and
never sees the unlock ladder again. The first cycle teaches them one at a time;
every cycle after it is the exam.

On top of which a drill grows 30% a cycle and the gap between them closes to 88%
of what it was, floored at one every eighteen seconds — past that an event is not
an event, it is the weather. The growth is the number that matters, and it
matters because it eventually takes the counterplay away: that fourteen-wide wall
with ends you can get round is, three cycles later, wider than the page. Which is
the ring's lesson arriving a second time, at the one moment in a run when you
have the damage to have an opinion about it.

Health, meanwhile, has quadrupled underneath all of it. Only one of those two
numbers is written in the drill.

### Forty out of two hundred and sixty

One thing had to be given up for any of this to work, and it is worth saying
plainly because it is a real cost.

Past about minute five the horde is not being held down by the floor or by the
wave timer. It is being held down by the cap — two hundred and sixty monsters,
and the page is sitting on it. Which means a drill scheduled for minute eight,
the exact half of the run drills were added for, would find no room at all and
walk on as four monsters. The feature would have quietly stopped existing where
it was most needed, and it did, in the first version: a ring at minute five
arrived as two.

So the ordinary horde now stops forty short of the ceiling and drills spend the
difference. The page holds forty fewer bodies of undifferentiated crowd in
exchange for the shapes always arriving whole, and that is the right way round —
forty out of two hundred and sixty is not a difference anybody can see, and a
wall crossing the page is.

Forty in the first cycle, and it grows at the same rate the drills do, which is a
fix for the same bug arriving later and quieter. Drills widen 30% a cycle, so a
ring is forty-four bodies by the fifth — bigger than a fixed reserve, meaning
rings would simply stop happening in the runs that had earned them. Growing the
reserve alongside them means the page tilts further towards shaped arrivals every
cycle, which is the direction it should tilt: by cycle five health is up
twentyfold and an undifferentiated body is the least interesting thing on the
page.

And a drill that cannot arrive whole does not arrive at all, and does not say its
name when it doesn't. Being told a wall is crossing the page and then watching
four monsters walk on would spend the one announcement that shape ever gets on
the version of it that isn't one.

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
nothing sits under a notch or a gesture bar. Nothing in it moves with the input
any more: the experience bar used to sit in the bottom-left corner on desktop and
tuck up under the health bar on touch, because that corner belongs to the stick,
which was two layouts for one readout. It runs along the whole foot of the page
on both now, clear of the stick's ring either side of it.

That bar is the one thing measured off the canvas rather than the safe area, and
it is the exception that proves the rule. The safe area exists so that nothing
you have to *read* ends up under a notch, and a bar has nothing in it to read: it
is a length, and a length that stops short of the corners is a length with two
meaningless gaps at the ends. Run edge to edge it is the screen itself filling
up. The one thing on it that is read — the level — is lettering in the middle of
the page, the furthest point on that edge from either inset, and the bar still
stands *on* the bottom inset rather than under it, so a gesture bar cuts across
nothing.

The health bar and the ink meter shrink to fit rather than being a number. Sixty
pixels is what each is worth on a landscape page and the most either is ever
drawn at, but a page held in portrait is a hundred and eighty pixels across at
the widest, and two sixty-pixel bars with their numbers on the inside meet in the
middle of that, on top of the clock. So the clock keeps the middle of the page
and a gap either side of itself, each bar takes what is left between that and its
own end of the row, and both are cut to the shorter of the two — they are twins,
and a health bar longer than the ink meter beside it is a health bar that reads
as fuller than it is. The two ends are not the same length, which is why both are
worked out rather than one being halved: the clock is centred on the page while
the row starts clear of the pause button, so the health end is a button and a gap
shorter than the ink end. A portrait phone lands on forty.

Both the clock and the two figures are given the widest they will ever be rather
than what they happen to say, the same rule the canteen keeps room for its purse
by. Bars that grew a pixel as the clock ticked past ten minutes, or as a hit took
health from three digits to two, would be bars whose length was answering two
questions at once.

The tool column has a whole margin to itself and sits centred in it —
nothing else is drawn there and nothing else tests a press there, which is why
the corner button was moved out of that corner. It holds only what the run has
unlocked, so it is one box tall on the first frame and four at the most; the
margin around it does not change with it, for the same reason the weapon column
opposite claims its width while empty. Both also leave room for the level that
appears beside each box while the run is held — always on the page side of its
own box, so the two columns face each other across the page rather than both
reading left to right. That is why the draft measures its cards
off the safe area *minus* both columns (`Hud.rightMargin`, `Hud.leftMargin`): a
card underneath either is a card you can only see part of. Which column is in
which margin follows the stick (see **Controls**); the two swap wholesale, so the
width between them never changes. The three cards go
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
| Compass | not drawn: **opened** | a ring up to 108px across, 7 damage on the rim and nothing inside it, cut as the arm reaches it |
| Scissors | not drawn: **tapped twice** | a 128px cut anywhere on the page, 12 damage, nothing shoved — and it travels |

The pencil is what `SCIENCE` starts you holding, and its upgrade line is the
one line a run can finish — so nothing in it changes what the pencil *is*.
It stays the cheap ragged line you kill with by drawing over things; the four
levels make drawing over things deeper (6 to 9), broader (a 3px diamond of
graphite pressed harder, with double the reach), and cheaper the longer you
keep drawing them. That third level pays a *style*: the price per pixel eases exponentially towards half while the finger
stays down and snaps back the moment it lifts, so the player who draws in one
long cursive line draws nearly twice as much of it, the player who dabs gets
nothing, and the floor is the cap that keeps a lap of the page from becoming
free pencil. The flat ink discount and the one-in-ten crit both went in the trim
to four: the blotter sells the first to every tool at once, and the sharpener
sells the depth the second was really buying. The finale is the most pencil thing in
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

All of which has to be delivered by your own hand, through the crowd you are
shoving. That is what the rubber's fusion is for: see **What the clearing is**.

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

Its four upgrades all sell the *fence*, and none of them sells a swing: the pen
that has taken everything still shoves nothing and still holds the crowd off
rather than going through it. What it stops being is cheap and temporary.

**A broader nib lays a thicker wall.** 7px of blue instead of 3, and the wall's
reach doubled with it — the spatial hash files a segment at the tool's own
radius and an enemy clears it by that plus its own body, so a broader line holds
the crowd further off the ink and rounds the ends of the fence wider. It is
still priced by the pixel of *path*, so the page one stroke covers doubles for
nothing, which is why the line opens on it.

**The line stings whatever leans on it.** The first damage the pen has ever
done, and it is the wall doing it rather than the pen: 1 a tick to anything
pressed against the ink, which is a blob in four hits and a skull in twelve.
Slight on purpose — the crowd walks the length of a fence rather than standing
on it, so this is paid out over the whole line for as long as the line lasts,
and a pen that killed anything promptly would be a pencil that also stops
people. It borrows the highlighter's lingering tick wholesale, plus two pixels
of slack: a wall parks bodies at *exactly* the ink's edge, so a tick measured at
the ink's own radius would land or miss on floating-point luck.

**When the line goes it takes the crowd with it.** Up to here the end of a pen
line was the one moment it was worth nothing — the fade is the warning that the
fence is about to stop stopping anything, and this is what the warning is now
warning about. 4 damage, a blob exactly, along the whole length of the line at
once rather than in a circle somewhere on it, because a fence has no centre. A
wall drawn across the front of the horde and left to run out takes the rank
leaning on it with it, and it is the one thing in the game a timer the *player*
started is the trigger for.

**The last line stays until you draw another.** The finale is the tool's own
argument taken as far as it goes: the wall you drew last has no clock on it at
all. It changes what the pen is — a stroke you spend and redraw becomes a fence
you place and keep — and it changes what the meter is for, since holding ground
stops costing anything per second. One line is the whole of what holds it down:
drawing the next is what lets the last one go, so the page cannot be latticed
shut, and what is released is *let go* rather than wiped — it fades out on the
ordinary nine seconds, and then pops if the level above was taken, which makes
replacing a wall a thing you can aim. A run that does box itself in has spent
its whole meter on ground it can never move, and it is still standing on a page
the eyes shoot over and the boss has to be killed on.

And a fence still has ends, which is the one thing four levels never fixed and
what the pen's fusion is for: see **What the corral is**.

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

The highlighter is the brush that keeps working after you let go: a wide sky
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
back over the stroke's own band come out in the edge's blue rather than sky —
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

**But the page holds them one deep.** One driven inside the footprint of one
already there — 5px for a pin, 6px for a staple, which is the size of the two
drawings rather than anything about the tools — punches its crater, pays its
refund, holds what it caught, and is then not kept. That is the same idea as the
record rather than an exception to it: two pins inside each other record one spot
twice and read as neither, and a pile of them is a shape nobody drew. The
distances are well under the stapler's own seam spacing, so a raked line never
eats itself; it is tapping the same spot twice, raking back over your own seam
and the SPINDLE nailing two enemies standing shoulder to shoulder that stop
smudging. Nothing is refunded for it — the tap did its job, and a discount would
be the tool paying you to spam one spot.

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
the tool really is, then **a wider circle** (41px to 51, the compass takes no
area at all now, so the pin's crater is uncontested as the biggest single patch of
page anything covers at once). The rest is the deeper hits
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

Both of those last two sentences are the *written* tool, and its four upgrades
are where each is bought back. The pushpin's line refuses to raise its crater or
shorten its fall, because that tool's design is one big telegraphed decision.
This one is a hundred small ones, so its line sells what a hundred small ones can
be: a rate, and a page you have worked over.

**It drives in deeper.** 2 to 6, which is the biggest single step in the line and
first for that reason: 2 is a bat and nothing else, and 6 is a blob, a bat, a
drop and a wad outright and half a skull. The tool stops being something you
spend to hold a body still for whatever else you own and starts being something
that clears what it landed on. Still nowhere near the pin's 10, and it should not
be — that is a 41px circle for four and a half times the ink, and this is 15px of
page for a tenth of the meter, landed ten times a meter on things that are
moving.

**One in five goes straight through.** The crit the pencil used to buy, finally
given the tool it was waiting for: a one-in-five on something you tap dozens of
times a page is a *rate* — 1.4× the damage over a page, and the arithmetic is
honest because the sample is large — where the same roll on a pin you get two of
from a full meter is only ever a story about one pin. Triple on 6 is 18, which
takes a skull, an eye and a blot outright and leaves the grin standing: the one
enemy written to survive everything a build does to move the crowd survives this
too.

**It tears back out and bites again.** Everything above this is the staple going
in; this is the only thing in the game about one coming back out. The hold runs
its two seconds exactly as it always did, and instead of the page keeping the
wire the wire is pulled out of the page — another 6, a fifth of those going
straight through at 18 as well, and six pixels of it lifting off the paper on its
way to nowhere.

It is the one hit in the game that cannot miss, and the hold is what earns that.
Everything else the crowd can walk out of; what a crown caught two seconds ago is
standing exactly where it was, because the crown is the thing holding it there.
So the honest way to read the level is not "twice the damage" but "the second 6
lands on precisely what the first one failed to kill" — a staple that killed on
the way in tears out of an empty circle, and a fastener with nothing under it is
worth nothing at all.

What it costs is the page. A staple used to be the one drop that stayed, and a
run holding this level staples a page it does not get to keep: the spent pile
stops filling with wire, and the record of where the trouble was is pins from
there on. The tool stops being something that leaves a page behind it and becomes
something that happens twice and is gone.

**Hold and drag to run a seam of them.** The finale, and the one level in the
catalogue that changes a *gesture*: tapped not drawn, ten separate decisions, a
held finger is none — all of it sold back. It is last because the three above it
are what make a seam worth having, a line of staples now being a line of 6s, a
fifth of them 18, and a lane you can run down. They land 12px apart, so the
circles just overlap and a full meter is ten of them: about 120px of seam, a third
of the page. Each is charged the tool's own price, so what the level buys is
*presses* rather than page — the meter still owns exactly how much stapling a run
can do, and it always did.

A seam is still a line your hand has to walk, though, and it still has two ends.
Both of those are what the stapler's fusion is for: see **What the hem is**.

Freeze and life are the same number, the way they are for the pin — `life` is
only how long the thing is still worth updating, since a staple never comes out
of the paper and never fades. (Its third level is where that stops being true,
and it is the only thing in the line that argues with this paragraph: there the
same two seconds are the clock on a fastening that gets *undone*.) A page worked
over with the stapler stays covered in them — one deep, since one driven where there is already one leaves the
drawing alone (see the pushpin), so a seam raked twice over the same ground
reads as a seam and not as a stripe. Each one goes in
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

The one limitation none of its four levels touches is that the line goes through
you, and that is exactly what its fusion is for: see **What the fold is**.

The compass is the fourth way, and the only one that is *opened* rather than
drawn, placed or aimed. Press and the needle goes into the page right there;
drag and the pencil leg opens out to however wide you want the circle; let go
and it draws. One gesture, and the same one the real instrument is set with —
the needle stays where you put it while the other leg swings out from it.

Which makes it the only tool here where the mark is placed before it is sized.
Everywhere else the drag decides where the ink goes and the size is whatever the
drag came to; here the press fixes the centre and the drag only widens it. A
press with no drag in it at all is still a circle, at the minimum width.

**What it cuts is the line it draws.** A body has to be standing on the rim —
three pixels off it, plus its own radius — and the middle of the circle is not
cut at all. So this is the one tool in the game that reaches a *perimeter* rather
than an area: everything else takes a patch of page, and this takes a closed line
around one, which at the widest it opens is by a distance the longest line in the
game. A compass is a fence, not a blast, and the inside of one is the safest place
on the page.

It was the whole filled disc until recently, and that was a bug wearing the shape
of a feature — the hit test only asked whether a body was *inside*, so the leg
swept the page like a radar wiper. It made the tool a delayed pushpin with a
bigger crater, and it quietly cost three of its four levels their argument. A ring
is what the tool has always been described as and drawn as; the hit test agrees
with the drawing now.

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
longest line in the game clears chaff and cannot touch a tank, where the pushpin
takes a whole disc of page at once and kills everything in it but one. The two
are one trade read off either end — a crater you drop on the crowd against a
fence you draw round it — which is why neither number moved when the fence
stopped being a crater. The knock is
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

The first of them, **it opens out wider**, used to be the one level in the
catalogue with no trade in it: while the cut was a disc, opening out bought area
on a squared law and the leg still took the same 0.8s. Now it buys *fence*, which
climbs in a straight line rather than a curve, and it costs you something — a ring
at 16 is dropped on a crowd, a ring at 66 has to be placed so the crowd is
standing on it, and every extra pixel of radius is more page they can be standing
in the middle of instead. Wider is still better and it is no longer free.

The other three move where on the turn the cut lands, how many turns there
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
exactly a skull: the level where the longest line in the game stops being unable
to touch a tank. The second lap is also worth more than "the same cut twice" now
that the cut is a rim — 1.6s is long enough for the crowd to walk across a line
three pixels wide, so what comes round the second time is largely not what was
cut the first. It is the level that turns the ring from a hit into a place.

The last one changes the shape rather than the numbers. **A second leg sets off
the other way** from the same rest point, so the two meet on the far side and a
lap closes in half the time without the arm moving any faster — the two laps the
level before it bought now come to the same 0.8s a single leg used to spend on
one. The pair share one hit list, because what they buy is the far side being
*reached* sooner rather than everything being cut twice, and they drag what they
catch opposite ways, each the way its own leg is going. The far side was the
safe place to be standing while the promise was made, and now there isn't one.

It is the level that gained most when the cut became a rim, and it is worth
knowing why: while the disc was the hit, halving the promise only bought tempo,
because anything that stepped off the line was still inside the circle and was cut
anyway. Now stepping off the line is the counterplay, and this is the level that
takes half of it away — the thin ring's own weakness and its own answer, which is
where a finale belongs.

The scissors are the fifth way, and the only one whose gesture spans more than
one press: you **tap twice**. The first tap anchors the cut and puts a small
graphite cross on the page, and nothing else at all; the second says which way
the cut runs, and *that* is what prints the dotted line — the "cut along the
dotted line" the paper itself would carry. The page then comes apart along it,
and everything lying on it is cut for 12.

Which makes them the only thing on the strip that reaches *anywhere*. The
ruler's line has to run through you and the compass's circle has to be centred
on the press, so both of those are really about where you are standing; a cut is
two points on the paper and neither has anything to do with you. What pays for
that is the gap between the taps. The horde keeps walking through it, so the row
of blobs the first tap lined up is not the row the second one cuts — a cut is
*led* rather than aimed, which is the opposite skill from everything else here.

**A cut travels.** The blades do not close along the whole line at once — they
go down it at 800px a second, cutting the stretch they have just crossed each
frame, which is the sword's swing written straight rather than curved (and, like
the swing, with a `struck` set, so one cut is worth one hit to a body however
many frames it spends arriving). At the default reach that is about a sixth of a
second; a cut that runs edge to edge is nearly half of one. It is a *speed* and
not a duration on purpose: a cut is the same gesture at every length the line can
be, so a longer one taking longer is the honest reading of the level that bought
that much more page rather than a penalty for having taken it.

What that buys is the tool's whole idea taken one step further. A cut was already
*led* rather than aimed, because the horde walks between your two taps; now it
walks while the blades are coming, so what a cut takes is the crowd as it stands
when they reach it. The far end of a long one is a promise about where the blades
will be, not a description of where they are. Behind them the page is already
open, drawn solid and red the way an impact is drawn everywhere else on the page;
ahead of them the dotted line is waiting to be followed. And the whole length
flashes red once, for two frames, at the moment they arrive — which is the moment
the cut is a cut.

**Nothing is drawn between the two taps but the cross.** The whole cut used to be
dotted out live from the anchor, following the pointer, and taking that away is
the point rather than a saving: a guide you can drag onto a blob turns a tool that
is led into one that is aimed — you line the far end up on something and tap when
it lights, which is the ruler's gesture with an extra press in it. Without one the
direction is something you hold in your head and commit to. It costs the cross the
job of carrying the anchor on its own (on a touch screen the pointer is sitting on
top of it between taps, so there is nothing else there), and it costs the reach
being a bound you can see, which is what doubling that reach pays for.

Three numbers hold it. **12 damage** is the pushpin's 10 pointed the other way:
the pin is one short of killing the toughest thing in the crowd and clears a
41px crater doing it, and this kills a skull outright along a line nothing is
standing on unless you put it there. The **reach is 128px**, against the ruler's
200px line, which is the price of being able to place it anywhere — past that the
second tap picks the direction rather than the far end, so the cut runs 128px
towards where you tapped. It is twice what it was, and the two taps showing you
nothing in between is what it is twice for: a cap you can see the end of is one
you can work with, and a cap you cannot is one you find out about by having a cut
stop short of the blob you meant it for. 128 is most of a screen height, far
enough that it is rarely what a cut runs out of. And the **knock is 0**, written down rather than left
out, on the pen's terms: not shoving is the point of it, and the shove is scaled
by a multiplier, so it stays at 0 whatever is ever written on that axis. That last one is what
keeps this from being a narrow ruler — the ruler's shove is what opens a corridor
across the page, and a cut leaves the crowd standing exactly where it was with a
gap through the middle of it.

It is also the one tool that is **not paid for on the press**, and that follows
from the same fact. A ruler and a compass charge the moment they are picked up
because letting go of either always lands it — there is no changing your mind —
and an anchor is not a cut. So the ink is charged by the tap that opens the paper,
and a **tap back on the anchor puts the scissors away for nothing**: the anchor
goes, no cut is made, and nothing is spent. That is deliberately the same gesture
as making a cut rather than a second control to find in a panic. Anything else
that takes the pointer away — a tool change, or the run being held for a pause or
a draft — drops the anchor too, and for the aim's reason on a longer clock: an
anchor tapped before the freeze and closed after it would cut a line across a
page the horde had spent a whole draft screen walking over.

What is left behind is the page opened. The slit is drawn in **paper**, the one
colour that wipes what is under it rather than stacking with it, so the ruling
really does stop where the blades went — and it is drawn with a graphite pixel
alongside, because paper on paper shows up nowhere but where it crosses a rule,
which on the unruled page is nowhere at all. Two pixels is what a cut in paper
looks like anyway: the opening, and the dark edge of it lifting. It fades like
every other mark, down a ramp that is the page closing — open paper, then a
graphite crease with nothing left open to cast an edge, then gone. A cut left
there for good would be a page with the ruling permanently missing out of it,
and the pushpin and the staple are the only two things allowed to stay.

It is also the one tool no lesson hands out, and that is not the pen's and the
gluestick's reason: it is the only tool on the strip you have to be *told* how to
use, since every other one does something on the first press. A run is not handed
it before it has read the card.

Its four upgrades are all about the *line* rather than about the number, and they
climb one direction the whole way: how much page one cut is.

**The cut runs as far as the second tap.** The 128px cap comes off rather than
moving up, and what is left holding the length is the pointer — a tap cannot land
off the canvas, so the longest cut in the game is a screen's diagonal and the
meter charges the same 0.3 for it. It is written as `math.huge`, the cool S's
trick for the cool S's reason: every clause that reads the reach goes on working
untouched. It is also the level that makes the travel worth something: up to here
the blades are down the line inside a sixth of a second, and past it a cut can be
long enough that the crowd is walking while it opens.

**It bites deeper and wider between your taps.** 20 across a band of 6, where the
cut is 12 across 3 — and it applies to the stretch between the two taps and not
to the rest, which is the compass's `bite` by another name: the part of the shape
you got to choose is the part that is worth something. 20 rather than the obvious
24, and the width doubling instead, are the same decision: 12 already kills the
toughest thing in the crowd outright, so a bigger number buys almost nothing
against what this tool is for, where 6 against 3 is the difference between having
to thread a cut down a line of blobs and being able to lay it near one. It is
deliberately an absolute number and not a multiplier — doubling would keep pace
with the sharpener forever, where a flat lead is one the rest of the cut closes as
a run gets stronger, which is the right way round for a level bought early.

**It runs on past both taps to the edges.** The cut stops ending where you tapped:
from here the two taps are a *line* rather than a pair of ends, and it carries on
from both of them to the edges of the page at the written 12 across the written 3.
Which is what the level before it turns out to have been for — the cut crosses the
page whatever you do with the taps, so what they are placing from then on is the
deep part of it. The two are drawn as two different things, because a choice you
cannot see is not one you can make: the stretch between the taps is dashed like a
pair of blades closing, and the run-on is a sparser dotted tear running away from
it. Clipped to the viewport rather than to the world, the sun's rule and the
beam's: nothing is killed off the page.

**The half you are not on is cut off the page.** The finale, and the one thing in
the game that draws into the *page* rather than onto it. The cut goes all the way
across, so the page really is in two, and the half you are not standing on is
lifted off it: the paper between the rules gone grey, and the ruling itself
printed exactly where it always was. The scissors take the *paper* away, not the
printing on it, so what is left is the page's own lines standing on nothing —
which on a page that is mostly white is most of the page gone. It is drawn as a
second bake of the same tile at the same world coordinates (`Background.torn`),
so the ruling lines up across the cut with nothing having to arrange it.
Everything standing on the offcut **goes with it** — and comes back down in the
corner of the page that is still there, furthest from where you are standing. Not
withers, not dies, and not vanishes either: it is *moved*. Nothing at all is
credited for it, no gem, no xp, no kill, nothing split and nothing burst, because
nothing died and nothing was even hurt. This is the only level in the game a run
can finish without buying a single point of damage, and the only mechanism in the
game that takes an enemy off ground the player can see and puts it back somewhere
else on the same page.

**It used to despawn them, and the reason it does not any more is worth writing
down, because the version that did looked correct.** Its price was the xp: a page
you empty is a page of gems you never pick up, so a build that kept half the page
lifted traded its own levelling for room to stand, and met the boss behind a build
that fought for the same ground. That is a real cost and it is legible the first
time anybody watches a champion vanish leaving nothing behind. What it was not was
a cost you *felt in the moment*, and the moment is what the level is for. Whatever
the tally said, half a page of monsters had stopped existing: it was a get out of
jail free card, and the more trouble you were in when you cut, the more it gave you.

And one thing about the despawn was quietly wrong rather than merely painless: it
put the horde under the spawner's floor, so the run refilled from off-screen while
the page was still open. A cut *replaced* the crowd it took. Now nothing leaves the
horde, so nothing is topped up, and what walks back at you is the same monsters.

So the paper still goes and the crowd still goes with it, and then the crowd is
standing in the corner. What the cut sells is the length of the page — the seconds
it takes them to walk back — and what it charges is the shape of the walk: they
arrive out of *one corner, together*, at the health they had, instead of from the
ring they were spread round before. A cut is the longest-reaching piece of crowd
control in the game and it is no longer an eraser. It is also, now, a wall: the
offcut goes on answering for whatever walks onto it, so walking the horde into it
puts the horde back in the corner, which is the honest reading of a piece of page
that is not there. The boss is the one exception and always was: it is never
lifted, for the same reason it is never despawned at range — half a page of
distance handed back twice a second is a fight you would never have to have.

Where the corner is, is asked once per sweep and asked of the *run* rather than of
the cut, so the whole crowd arrives in one place and so the answer is clear of
every hole on the page rather than only this one — three pins are three cuts (the
TEAR LINE) and a spiral leaves four holes at once (the CUTOUT), and a cut that only
knew its own half would be handing bodies to the hole next door twice a second.
Walk out onto your own offcut, so that there is no paper left on screen to put
anybody down on, and the cut lifts nobody at all until you walk back.

Three things about that last one, and a fourth that is really about the travel:
the severed half is the one part of a cut that does **not** wait for the blades.
It is off the page from the tap and it empties on its own clock from the tap,
because the travel is about the cut — a line closing on a crowd that is still
walking — and half a page that only came away once the blades reached the far edge
would spend the best part of a second being a finale that had not happened yet.
What that costs is a page in two along a line the blades are still coming down,
which reads as the tear leading them rather than as a mistake.

**Which half** is decided when the blades close and frozen there, from where you
were standing — walk across your own cut afterwards and the grey does not swap
over, because a page flickering between two answers is not a page. The one row that
re-reads it every frame is the GUILLOTINE, whose line goes through your own feet
and so has no half to freeze. And the offcut lasts **exactly as long as the cut
does**, so keeping half a page lifted is something a run does by going on cutting;
the ink meter is then what limits how much page you can own, which is where a limit
like that belongs.

Grey is a fourth *page surface* for this and nothing else (`Palette.surfaces`), so
ink landing on the offcut stacks on it exactly the way ink stacks on blank paper
and nothing in the overprint pass has to guess. Filling it into the ink layer
instead would have made it a mark, which is a different thing in two ways that
both show: the pass would pair the grey with the page beneath it, so it would
come out as some other colour wherever it crossed a rule, and ink laid on top
afterwards would go on stacking against the paper the grey had covered rather
than against the grey.

The cooldown is an **ink meter**, drawn as the health bar's mirror image: the
same bar at the same size in the opposite top corner, hung
off the right edge of the page with its number on the inside, so the pair of
them empty towards the middle. It used to be a thin gauge stood on end beside
the tool column — which is where you look to *change* tool, not where you look
mid-stroke. As the health bar's twin it is read the way health is read: at a
glance, off the length of it. It goes blush once there is too little left to
start a stroke with, the one thing about it you have to catch without reading
it.

It fills in **grey**, not the blue of the pen it pays for. Blue on this page
means the player's side of the fight and is already spent on the marks
themselves — the nib, the shots, the rocket, the beam — so a blue meter is the
readout claiming to be one of them. Grey is what the readout actually is:
furniture, read for its length and not for its colour. It also leaves the blush
at the bottom of the meter as the only colour it ever takes, and so the only
thing about it that can shout.

It drains by the pixel — a full meter is about 230px of pencil, 170 of pen, 150
of rubber, 120 of highlighter, 90 of glue — or by the use, for the five tools
that aren't brushes: 0.45 of the meter for a pin, 0.4 for a compass, 0.35 for a
ruler, 0.3 for a cut, 0.1 for a staple. Two pins from full, about three rulers or
three cuts, or ten staples,
and a second or so of standing still to earn one back. (There is one exception to
"by the pixel or by the use", and it is a fusion: the **hem** charges 0.4 at the
needle and then two hundredths per staple the drag adds to the ring, so the widest
one costs 0.92 and the meter is what caps how wide it opens. See **What the hem
is**.) It refills a beat after
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

- **The scissors cut the page rather than marking it.** What a cut leaves is a
  dashed slit drawn in paper — the colour that erases — with a graphite pixel
  alongside it, which is the opening and the dark edge of it lifting; paper on
  paper would show up nowhere but where it crossed a rule. Before any of that the
  blades travel: graphite dots down the whole line, red laid over as much of it as
  they have closed, and then the whole length flashing red for two frames as they
  arrive — the ruler's red for the ruler's reason. And where the finale has taken half the page off, that half is not a
  mark at all: it is filled into the page layer, so the ruling is simply not
  there any more.

Marks fade without ever leaving the palette. Alpha would blend paper and ink
into a ninth colour, so instead a stroke steps down a colour ramp
(ink → slate → graphite) while individual stamps drop out at random — a dither
fade. Every pixel on screen is always one of the eight.

Each tool decides how late in its life the dithering starts. The pen holds full
blue for the first three quarters and then goes visibly thin and pale, because
a wall you can't see is a trap: the fade has to be the warning that it is about
to stop stopping anything.

## Reading a hit

Every hit throws a number up off the thing it landed on (`src/damage.lua`).
Before it did, the whole account the page gave of a hit was a flash and two red
specks — which says *that* something landed and never says how hard, so a draft
that doubled a tool's damage looked exactly like one that did nothing, and the
upgrade half of the game was invisible while you were playing it. The flash has
since grown into a proper flinch (below), but the division of labour is the same
one: the monster says it was touched, and the number says how hard.

**How big it is, is what it says.** There are six tiers and the table is the
whole design:

| damage | size | filled | ringed | pops |
| --- | --- | --- | --- | --- |
| 1–5 | 1x, small face | blush | red | no |
| 6–12 | 1x | blush | ink | no |
| 13–24 | 1x | red | ink | yes |
| 25–35 | 2x | paper | red | yes |
| 36–49 | 2x | paper | ink | yes |
| 50 and up | 3x | blush | ink | yes |

The bottom tier is the only one drawn in the small face — 5x5 rather than 5x7,
so seven pixels tall in its outlined cell instead of nine. A blob is eight
pixels tall, so every other tier stands taller than the monster it came off and
this one does not, which is the whole of what it is saying. It is also the only
one ringed in red rather than ink, and so the only one that does not fully hold
itself off the page: blush ringed in red is two neighbouring pinks, since `red`
is already the bottom of that ramp and there is no darker red to reach for. Same
intent both times — a hit that barely happened should be the thing your eye
skips over. The top tier goes back to blush for the opposite reason: a figure
three times the size is unmissable on its size alone, so nothing about its
colour has to do that work.

The thresholds are absolute rather than relative to what was hit, and that is
the point: a run getting stronger *looks* like the page filling with bigger,
heavier, whiter numbers, and nothing has to be read for that to land. A crit
(the pencil's line multiplies damage rather than adding to it) jumps a tier or
two on its own, so the starburst it already threw is now backed by a number
three times the size of the ones around it. Numbers are rounded up from
whatever the real figure was — every multiplier a run owns is a float, so almost
nothing hits for a round number — and floored at 1, because a tick that took a
tenth of a point off something still happened and a `0` floating off an enemy
reads as a bug.

**How much of this the page says is a setting** (`DAMAGE NUMBERS`, see
**Settings**): every number, only the big ones, or none at all. `BIG ONLY` is cut
off the table above rather than off a number of points — it keeps the tiers that
pop and grow and drops the three one-scale ones, which are most of what a busy
frame throws — so moving a tier's size moves the setting with it. A number that
is not going to be drawn is refused where it is added rather than where it is
drawn, so it never gets built, never ages and never takes a place in the list off
one that would have been shown.

**The pop steps between whole sizes.** Nothing in the game is drawn at a
fractional scale (see *Pixel size*), so a number can't ease up out of nothing
the way one in an ordinary game does. It arrives one whole step *over* the size
it lands at, drops to it, and on the way out drops one step under and goes
**hollow** — the ring drawn and the figure inside it left empty, so the fill
lifts off the page and the outline follows a moment later. Three sizes, no
tweening: it reads as a stamp rather than a zoom, which is the right feel for a
page made of pixels, and it is the only shape of pop the rendering rules allow.
Going hollow is also the only exit the three 1x tiers have at all, since there
is no size under 1 to drop to. Filling the figure with its own ring colour
instead was tried, and is a solid rectangle at every size the face is drawn at —
a number that ends its life as a blob reads as a bug.

**The two bottom tiers don't pop at all**, and that is deliberate. The overshoot
doubles a number for the length of its first beat, and on a 1x tier that means
the first thing you see of it is a figure more than twice as tall as the enemy
underneath. Those tiers are most of the numbers a run throws, so popping them
was the whole page shouting about chip damage. The pop is worth having where the
hit is worth announcing, so it starts at 13 and the two tiers below simply
appear at their size — which makes arriving big the thing that marks the step
up, rather than the colour change alone.

**One number per hit, not per source.** A built run has four passive weapons, a
mark on the ground and a tool all landing on the same enemy within a few frames
of each other, and six numbers stacked on one blob says less than the one number
they add up to. So damage is *banked* on the enemy — `Enemy:hurt` is the single
door everything goes through — and `Game:spendHits` puts the total on the page
once it has stood still for 80ms. A killing blow doesn't wait for that window:
a moment later there is nothing left to hang it off.

**They are drawn over the page rather than on it**, after the overprint pass,
alongside the HUD and the draft's cards. That is not just layering. Inside the
pass a red number crossing a ruled line would come out slate and a blush one
would come out red (see *Palette*), so the tiers above would mean one thing on
blank paper and another on squared — and the one thing a readout may not do is
change colour because of what is printed underneath it. They are still world
space, though: a number belongs to the enemy it came off and scrolls with it,
which makes this the only thing in the game drawn under the camera transform and
outside the pass.

The numbers are drawn in their own face (`src/font.lua`) — 5x7, two-pixel
strokes, one-pixel counters — and they had to be, because this is the one piece
of lettering in the game that is outlined and the 3x5 HUD face does not survive
it: at that weight the counter of an 8 fills in and a 1 comes out a bar. There is
a second one at 5x5 for the bottom tier, one counter row instead of two, and it is
the floor of the design rather than a first step: an 8 needs three bars with a
counter between each pair, so the height can only be 3 + 2c — 7 or 5, with
nothing in between and nothing under it short of one-pixel strokes, which is the
face that already failed. The width can't move either, since two of stroke, one
of counter and two of stroke is the narrowest a two-sided digit gets. So both
faces are five wide and a number is the same width whichever draws it. The
outline
is baked into the atlas rather than drawn as offset copies of the glyph the way
`Sprites.rim` does it, for two reasons. Copies of a glyph shifted a pixel each
way eat a pixel off the pitch at both sides, so at any sensible advance the
digits of a number fuse into one dark plate with the figures knocked out of it —
readable, but it stops looking like numbers. And a number is up to three glyphs
redrawn eight times each; baked, it is two draws per digit, which is what makes
a screenful of them free. The ring deliberately includes the counters, so a `0`
at 1x is a light figure with a dark bar down it rather than a solid block.

The pitch is a pixel *less* than the outlined cell, so neighbouring digits share
the column of padding between them and a two- or three-digit number reads as one
figure instead of two or three things sitting near each other: what separates
them is a single pixel of ring. Two facts make that overlap safe and both have
to hold — only padding overlaps, since the figures themselves sit in the middle
five columns of a seven-wide cell and still have a clear column between them;
and every ring of a number is drawn before any of its bodies, in one colour, so
ring landing on ring cannot show.

Both faces are the whole printable ASCII repertoire rather than the ten digits
they started as — caps, figures and punctuation, at 5x7 and 5x5 — so that
anything the page wants to *shout* rather than state can be shouted in the face
a hit is announced in, at the same two sizes, with the same outline round it.
Lowercase is folded to caps at draw time the way the 3x5 face does it; there is
one case here.

Three things about the alphabet are worth knowing before editing a glyph. **A
curve is a cut corner** — B, D, P and R lose the last column of their bars, and
C, G, J, O, Q, S and U lose the first and last pixel of theirs. That is the only
shape of curve five columns will hold, and it is load-bearing rather than
decorative: the digits are square-cornered and cannot move, so without it O would
be exactly 0, S exactly 5 and G one row away from 6. **Five columns will not hold
three stems**, so M and N cannot draw their diagonals as diagonals — there is
exactly one column between the two stems. Both move the *weight* instead: M fills
that column near the top, N walks the fat side from left to right down the glyph
and crosses in the middle. At 5x5 that gets tighter still, and M, H and W are
told apart by nothing but which single row is solid — row 2, row 3 and row 4
respectively, the widest three letters can be separated at that height. And **a
handful of symbols are lattices drawn at one pixel** — `#`, `*`, `%`, `&`, `@`,
and the apexes of V, X and the arrows. There is no two-pixel hash in five
columns. They survive because the ring is baked round whatever is there, so a
one-pixel stroke still comes out held off the page; they are simply lighter than
the rest of the face, which is the right way round for punctuation.

Numbers start a few pixels off centre and drift as they arc, so a stream of hits
on one enemy sprays instead of redrawing in place, and bigger ones hang about
longer than small ones — a `3` is gone before you have finished reading it and a
`60` is up long enough to be looked at. A page thick with them is the intended
state; the cap in the module is only there so that a pathological frame can't
turn into a few thousand draws.

### The flinch

The number says how hard. **The monster itself says that it was touched**, and it
is a separate job: a number is thrown from the enemy and drifts off up the page,
so a tenth of a second after a hit it is no longer telling you *which* thing in
the crowd took it. Two hundred monsters walking through a screenful of drifting
figures is a page where you cannot tell what your damage is actually landing on.

So a hit does two things to the body it landed on, and they are one effect.

**It blows out white, inside a red edge.** For about a tenth of a second the
sprite is drawn as a flat silhouette — `paper` for the first couple of frames,
dropping to `blush` for the rest — with a one-pixel red rim round it. Paper is
the page's own colour, so that first step is literally a hole in the shape of the
monster, and the rim is what gives the hole an edge. Neither half works alone:
a white silhouette on white paper is a monster that briefly vanished, and a rim
with the art still inside it is a monster wearing a highlight. Together they are
a shape punched out of the page, which is what a hit ought to look like in a
notebook. It steps down a ramp rather than switching on and off because that is
how every fade in this game is done (see *Palette*) — flat blush alone, which is
what it was, is a monster that changed colour rather than a monster that was
struck.

Red for the rim rather than blue, because red is *theirs* everywhere else on the
page and the spark that comes off anything taking a hit is already red. And it
outranks the three outlines an enemy can already wear — sun-bleached,
lightning-struck, winding up — because for that tenth of a second what it is
doing matters less than what just happened to it. (The champion's ink used to be
a fourth, and was the only one on the list that was not something happening to
the monster; it says itself with the page now, and every rim left is temporary.)

**And it kicks backwards.** Three pixels away from the blow, sliding home over
0.12s. Linearly, and that is the whole trick at this resolution: 3, 2, 1, 0 is
four held frames all travelling the same way, where an eased curve would spend
most of its life on the same pixel and read as a wobble. Its shadow stays where
it was — the shadow is on the paper and the body is what was hit — so the
monster visibly comes off its own feet and settles back onto them.

**Neither of them moves it.** The kick is a drawing offset and never touches the
enemy's position, because position is what every hit radius, both spatial hashes
and the crowd's separation pass are reading, and a monster you could miss by
shooting it would be the one unfair thing in the game. Which way it flinches is
taken off the monster rather than off the weapon: it goes backwards along the way
it was walking, and it is walking at you, so for nearly every hit on the page
that is away from where the hit came from — and it costs the thirty different
things that deal damage nothing at all to be right about it.

**And neither is tuned per monster.** A hit on a paper clip and a hit on the boss
flinch identically. A boss that flinched less would read as a boss that was not
hit, rather than as a boss that is heavy — how much a hit was worth is the
number's job, and this one only ever has to say *that it happened*, the same way
every time, so it can be read out of the corner of your eye in a crowd of two
hundred.

### When it is you that gets hit

Something bumps the desk and **the whole page jumps** for a third of a second
(`Camera.knock`). It is the other half of the flinch and it is built the opposite
way round, on purpose.

The monster's flinch is the same size every time, because the number thrown off
it already says how hard. **You get no number** — you get a bar, in a corner,
which is the last place you are looking while something is chasing you. So this
one is the only thing in the frame that says how much of your page just went, and
it says it in the middle of the screen where you cannot miss it: the knock is
worth **two pixels for a graze and five for a hit you will remember**, measured
as a share of the bar rather than in points. Which means a skull's 12 is most of
a knock on a fresh page and rather less of one thirty levels later — being
tougher ought to feel like something, and this is the only place in the game
where it does.

It is a **wobble on two axes at two rates**, not a jitter. A random offset every
frame is how this is usually done and it is wrong at this size: the whole shake
is four pixels across, so random lands on the same handful of values over and
over and reads as the drawing buzzing rather than the page being struck. Two
waves whose rates don't divide into each other trace a loop that never quite
closes — a hard sideways snap on the first frame, then a decaying orbit — and
because they are functions of the clock rather than a die, the same hit shakes
the same way every time.

**It never adds up.** A second hit inside a knock restarts it at whichever of the
two was worth more, rather than stacking, because the one thing this has to stay
is readable: a screen that never settles is a screen you stop being able to play
on, which is the opposite of what a warning is for. And it is over — it decays to
nothing in about a quarter of a second, well inside the invulnerability window,
so it is a punctuation mark and not a state.

**The HUD doesn't move and neither does your pen.** The HUD sits above the page
rather than on it, so it stays nailed down while everything under it jumps —
which is what makes the jump legible at all. And where your finger is on the page
is read without the shake (`Camera.steady`), because a cosmetic effect may not
decide where a pen line lands: a knock is worth four pixels, and a wall drawn
four pixels off because something bit you is a bug you would never be able to see
the cause of. Everything that is *drawn* moves; the two things you *read* and
*aim* with do not.

## Sound

Every sound effect is stationery foley (`src/sfx/`, played through
`src/sfx.lua`), and two rules keep sixteen short recordings from sounding like a
machine. Every play
is pitch-shifted a few percent at random — in OpenAL a pitch shift is a speed
change too, so a slightly higher swish is a slightly *different* swish rather
than the same one replayed. And every file is brought to one perceived level at
load: the recordings arrived tens of decibels apart (the ruler slap peaks at
full scale, the rubbing loop sits 46dB under it), and a Source's volume only
goes down, so the samples themselves are scaled once at load and `MASTER` in
`src/sfx.lua` becomes the one number in front of the whole game. The gains in the
module were measured against the loudest 300ms of each file — re-measure rather
than nudge.

`Sfx.volume` is the player's own knob on top of that, set from the settings page
(see **Settings**) and multiplied into `MASTER` at every play: `MASTER` is what
the game sounds like at full, and this is how loud the player wants full to be.
It is read at every play rather than worked out once, so a bar dragged on the
settings page is heard on the next sound and not on the next run. `Sfx.retune`
is for the voices that can be *playing* while the bar moves and so cannot wait for
the next play: the track, always, and the rubbing loop while it is not mid-cut —
since a fade is a volume on its way to zero and must not be argued back up.

What plays when follows the input model rather than decorating it:

- **Crossing a box** plays `accept`, once, on the frame the answer commits —
  which is every screen's `commit`/`choose`/`answer`, so the studio's RESET and
  the pause card's dev switch tick exactly like a YES.
- **Changing screens** plays a transition, and the two files split by what kind
  of change it is: the long one (`transition2`) is the page turning — title to
  timetable to board to run, quitting, restarting, the win card — and the short
  one (`transition`) is the run being held and let go — pause, unpause, the
  draft opening and closing.
- **The placed and aimed tools** speak once, when the thing lands: `pin` and
  `stapler` on the tap, `ruler` when the slap comes down — from *every* route
  that brings it down, since the snap on a tool change or a pause is the same
  snap.
- **The brushes** are the drawn line made audible. A swish (`brush1`–`6`,
  shortest to longest) is chosen by how fast the nib has actually been moving —
  a flick gets the short sharp one, a careful line the long soft one — and the
  next fires only when the last has finished, so a held stroke sounds
  continuous without ever stacking. A nib holding still fires nothing, and
  lifting the finger cuts the swish where it stands (a fade of a few
  hundredths, just long enough not to click): the sound is the line being
  drawn, so it exists exactly while the drawing does.
- **Drawing on a screen that asks you something** is the same swish, and has to
  be: a screen with a box on it is a page like any other (see **Scribbling an
  answer**), so the title screen, the board, the draft, the timetable and the
  settings page all sound like being drawn on. The pen in `src/scribble.lua`
  fires the brushes exactly as a run does — one at a time, picked off how fast
  the nib has actually been moving, cut when the finger comes off — because it
  is the same rule and not a second copy of it. What it is fired off is the
  *ink* rather than the pointer: a screen's `mark` answers whether the stamp
  became a line, and everything on these pages that is furniture rather than
  page swallows what crosses it, so a tab, a margin button and a volume bar
  dragged the width of the screen are all silent. That last one is the reason
  the distinction is worth the return value — a swish laid over the volume the
  player is trying to hear would be the page talking over the very thing it was
  asked to demonstrate.
- **The scribble drawn for you** — the keyboard's answer, and a tapped card's —
  is a stroke of a length known before it starts, so it borrows the compass's
  trick below instead of a speed: one swish picked to fit its 0.4 seconds
  exactly. A box that fills itself in still has to sound filled in by hand.
- **The compass** borrows the brushes: its swing is a drawn line, so it plays
  the swish whose length best fits the swing and pitches it to fit exactly —
  the one place a pitch is chosen rather than rolled.
- **The scissors** borrow them the same way and for a weaker reason: there is no
  snip recorded yet, so a cut asks for the swish that best fits a tenth of a
  second and gets the shortest brush pitched as far up as it still sounds like
  itself. It is a blade through paper by family resemblance rather than by
  recording, and it is the first thing to replace when there is a snip to
  replace it with.
- **The glue** ignores speed — a smear is a smear — and its two recordings
  (`glue1`, `glue2`) take turns at random, starting on the press because a dab
  is already a smear. It is cut on the lift like the brushes are, and for the
  same reason: the squelch is the smear being laid.
- **The rubber** is the one brush with a beginning and an end: the rub itself
  is a loop (`rubbing`) that starts with the stroke and stops with it, and the
  release plays `eraser` — the crumbs swept off. The pop has to be earned: it
  only plays once the rub has covered a few tip-widths of ground
  (`RUB_HEARD`), because a tap sheds no crumbs and a player tapping the rubber
  at the horde should not be drummed at. It fires from every route that ends a
  stroke (lift, tool change, holding the run), with one exception: dying
  mid-rub stops the loop silently, because the eraser's tidy little pop over
  the death burst would say the wrong thing entirely.

### The track

One file (`src/music/ost.mp3`), streamed, looping, playing from the frame the
options are read to the frame the program quits. The music is not a run's, a
screen's or a lesson's — it is what the book sounds like while it is open — so
nothing anywhere starts or stops it and the only thing that ever touches it again
is the settings bar.

It is the one voice that breaks both of the foley rules, and for the same reason
each time. It is played at written pitch, because a few percent of speed on music
is out of tune rather than out of the ordinary. And it is brought to level by its
Source's volume rather than by having its samples scaled at load, because
decoding four minutes of music whole to save a multiply is a hundred megabytes of
RAM — which it can get away with precisely because the file arrived mastered to
full scale, and a Source's volume only ever needs to go *down*. That was the whole
problem with the quiet foley and it is not a problem here.

`MUSIC_GAIN` was struck the way every gain in the module was, off the loudest
300ms: the track sits at 0.19 RMS there against about 0.056 for every effect in
the game, so 0.29 is the track playing at exactly the level an effect plays at.
That is the reference point rather than the answer. How far *under* the effects the
bed sits is `Sfx.music`, which belongs to the player and opens at 0.7 against the
sound's 1 — the track plays for as long as the program is open and every effect is
a transient laid on top of it, so a bed level with the foley is the thing you hear
and the foley is the thing you miss. It is a default and not a ceiling baked into
the gain: the bar still goes all the way up for somebody who wants the music
louder than the game, and the page reads 70 against 100 rather than two hundreds
with the difference hidden behind them.

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
| red | `#e15e6e` | `r` | enemies, their shots, the boss's puddles, hit sparks |
| blush | `#f3a8a8` | `k` | soft fills, margin line, damage numbers, fused icons |
| blue | `#7194f0` | `b` | the player: pen, shots, beam, XP |
| sky | `#abc9f1` | `c` | ruled lines, light player fills, glue puddles, the skate's trail |

Red and blue divide the page between the two sides of the fight, and the split
is the same in every module: **red is the other side** — the bat's body, the
eye's spit, the wet trail the boss drags behind it, and the spark that comes off
anything taking a hit — and **blue is yours**, from the pen and the highlighter
through the pushpin and the compass needle to the bullets, the beam
and the trail a skate leaves. Blush and sky are the light end of each, and they are a matched pair
rather than two unrelated tints: blush darkens to red over a rule exactly as sky
darkens to blue, so anything drawn as light-through-the-middle-with-a-darker-edge
keeps its shape when it is recoloured from one side to the other. That is what
made the beam, the highlighter and the puddles a straight swap. It is also what
an enraged monster is made of and nothing else (see **Fury**): red and ink are the
two ends of the other side's ramp, so a body reduced to just those two is the
loudest sentence this palette can say about something that is still an enemy.

The one thing outside the split is the interface. Red also means *armed*, *hot*
or *full* on the HUD and on the boxes you scribble in, and that is not an enemy
— it is the readout, drawn after the overprint pass and never on the page, so it
is never read against a run in the first place.

Three of the eight can be the *page* rather than a mark on it — paper, sky and
blush, which is blank, ruled and margin — and `Palette.overprint` is the whole
eight-by-three interaction the pass looks up. Graphite is a fourth, and the only
one that is not printed on the page: it is the half of it the scissors' last level
lifts off, and every mark stacks on it exactly as it stacks on a ruled line. That
column is deliberately a copy of the ruled one and carries no new information —
it is there so nothing has to *guess*, since graphite happens to sit nearest sky
in the palette as written and the shader's nearest-match would land somewhere else
entirely the day graphite is retuned. Both the shader and its lookup texture are
sized off the two lists, so a fifth surface is a column and nothing else.

## Pixel size

Everything renders into a 320x180 canvas which is then scaled up by a whole
number to fit the window (4x at the default 1280x720). One authored pixel is
always an exact square block of screen pixels — never blurred, never a
half-pixel off. Two things protect that:

- The canvas and every image use `nearest` filtering.
- The camera snaps to whole pixels before drawing (`Camera.bounds`) — and it
  snaps against *the hero it is following*, not against the world. A fractional
  camera would make the ruled lines crawl; a camera snapped on its own account
  put the hero between two pixels instead. Everything in the world is drawn at
  `floor(world) - left`, so while `left` was `floor(Camera.x - w/2)` the same
  quantity was being floored twice independently, and the hero's own fraction of
  a pixel survived into the subtraction: his position came out as a constant
  plus "is his fraction below the camera's", and the follow lag holds that
  comparison right on the edge, so it flipped for as long as he walked. On the
  diagonal it flipped thirteen times a second against a cardinal two — 58px/s
  along the diagonal is only 41 on each axis, a fraction that drifts round its
  pixel ten times faster — and both axes crossed on the same frame, so the
  drawing jumped corner to corner and read as a smear rather than a shake.
  Taking the *lag* to a whole number subtracts his fraction from itself. What
  steps instead is the paper, in whole pixels, timed by his fraction rather than
  the camera's — and the paper is a ruling that repeats, so there is nothing on
  it for a step to be read against. The thing you are looking at is the thing
  kept still.

So sprite art is authored 1:1 against the canvas: the player is 15x19 pixels
(drawn by the player rather than authored, but on the same grid), monsters are
8x8 to 11x10, and the ruled lines are 2 pixels thick on a 10 pixel pitch.

## The background

Generated at runtime, infinite in every direction, nothing stored. A page's
ruling is written as a pure function of where you are inside one tile
(`src/subjects.lua`), baked once into an `ImageData` and drawn as a single
texture-wrapped quad whose UVs are just the world coordinates. One image, one
draw call, however far you walk.

There is one of those per subject and all of them are baked at load, none ever
rebuilt — a page is a couple of hundred kilobytes and there are seven, so keeping
them all costs less than the branch that would decide when to throw one
away, and it is what lets the timetable stand the whole screen on a page the run
is not being played on — whichever lesson is being answered.
`Background.setSubject` picks which is the page; `Background.drawAs` draws any of
them.

Two rules on a ruling, and both of them show up as a seam down the page if they
are broken: the tile's width and height have to be whole multiples of whatever
the ruling repeats on, and it may only paint one of the three surfaces a ruling is
allowed — blank paper, a ruled line, or the margin. A colour on the page outside
those is a colour the pass has to guess at.

There is a fourth surface in `Palette.surfaces` and it is not for ruling with.
Graphite is the paper of the half a page the scissors' last level lifts off. Each
page is baked twice at load — as printed, and again with every paper pixel swapped
for graphite — and the second tile is what a cut lays down over the first, after
the background and before the ink. So the offcut keeps its ruling and loses its
white. A lesson ruled in graphite would be a lesson played on a permanently
severed page.

It is deliberately plain. An earlier version scattered doodles across the page —
heart, cloud, bolt, sparkle — placed by hashing cell coordinates, and sprinkled
graphite grain through the paper. Both are gone. The page is the one surface
everything else is read against: every mark you make, every enemy, and the ruling
showing through the ink. Anything printed on it competes with the thing you are
actually meant to be looking at, and at this size there is no room for both. A
notebook page you have not drawn on yet is blank, and the drawing is the game.
It is also why four of the seven subjects differ by their ruling and by nothing
else: a
page with something printed on it would be competing with the run being played
on it, whatever the page was called.

`ART`'s punched holes are the one thing on any page that is not ruling, and they
are held to the same bar. A hole is not a doodle — it is what the page is *for*,
the same class of thing as a margin, and there are two of them per tile against
the ruled page's several hundred pixels of blue. What buys them their place is
the job in the subject table above: an unruled page has nothing on it that moves
past you, and a page you cannot tell you are crossing is a worse page than one
with two rings on it.

Tune a page by editing its spec at the top of `src/subjects.lua` — the ruling is
a few lines of arithmetic with the tile size beside it.

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
  font.lua            three bitmap faces: 3x5 for the HUD, the cards and every
                      prompt, and 5x7 and 5x5 outlined faces for the damage
                      numbers. Counts letters, not bytes -- the 3x5 face carries
                      an N-tilde and the two inverted marks for the Spanish
  i18n.lua            every line of copy the player reads, keyed by its English
  options.lua         options.txt: the language, the two volumes, the stick's
                      corner, the damage numbers and whether a new drawing is
                      asked for
  settings.lua        the settings page: two bars and four steppers
  damage.lua          what a hit was worth, thrown up off the thing it hit
  subjects.lua        the pages of the book: how each is ruled, who is in it
  background.lua      procedural notebook paper: one tile baked per subject
  overprint.lua       pairs the page and the ink so the ruling shows through
                      -- and blanks the page under anything standing on it
  camera.lua          pixel-snapped follow camera
  input.lua           keyboard, mouse, thumb stick, drawing pointer
  tools.lua           the ten tool definitions, one table each (and the shelf)
  stroke.lua          one mark: brush stamps, damage, surface tests, fade
  pin.lua             the pushpin: dropped where you tap, not drawn
  staple.lua          the stapler: the same tap, small and cheap and repeated
  ruler.lua           the ruler: aimed about the player, snapped on release
  compass.lua         the compass: needle where you tap, swung on release
  scissors.lua        the scissors: two taps and the page cuts between them
  walls.lua           spatial hash of pen lines, for enemies to steer around
  player.lua          movement, walk bob, XP and levels: what a hero is once
                      nothing he fights with belongs to him
  characters.lua      who you play as: the weapon each opens the run holding
  upgrades.lua        the catalogue: every upgrade line and what its levels do
  loadout.lua         what one run has learned: its stats, tool copies, weapons
  levelup.lua         the draft: three cards on the page, and you pick one
  shot.lua            the shot that goes out on its own: a passive weapon, and
                      the shootman's until he has drafted another
  sword.lua           the arc swung at what is close: the swordsman's, on the
                      same terms
  orbital.lua         the stars: a passive weapon bolted to you
  rocket.lua          the rockets: a passive weapon that goes off in eight
                      directions
  sun.lua             the sun: a passive weapon that owns a corner of the screen
  cools.lua           the cool S: a passive weapon that floats off in a line
  beam.lua            the laser beam: the one passive weapon you aim, down the
                      line you are walking
  bomb.lua            the bomb: a passive weapon you put down and wait for
  skate.lua           the skate: a passive weapon that is a surface, and the
                      trail it lays behind you
  storm.lua           the storm: a cloud that arrives to do a job, and the bolt
                      it puts through the page when it gets there
  flock.lua           the m birds: a passive weapon that holds no formation
  spiral.lua          the spirals: the one passive weapon that hurts nothing,
                      and moves the crowd instead
  puddle.lua          a blot of ground: the boss's wet trail, a bomb's burn
  enemy.lua           enemy types table, chase, knockback
  spawner.lua         offscreen ring spawning, difficulty ramp
  bullet.lua          projectiles
  gem.lua             XP pickups with magnet
  pickup.lua          hearts, ink and diamonds: fixed spots on the page, plus
                      a scatter past the screen edge
  particles.lua       one-pixel ink specks
  hud.lua             bars, timer, tool selector, thumb stick, corner button
  scribble.lua        the question every screen asks: a box you scribble in
  menu.lua            title screen: the chase behind it, and the boxes you draw in
  timetable.lua       which page of the book, what it hands you and which class
                      you sit it as: index tabs down one edge, the run that
                      lesson would be down the middle with a < course > stepper
                      as the last row of it, CUSTOM and GO! side by side at the
                      foot, a back arrow in one corner to go no further and a
                      column of tabs in the other to go and read
  library.lua         the catalogue: every tool, weapon and passive with all of
                      its levels, the shelf on one page and the entry facing it
  spread.lua          the book the back pages are read in: two leaves, a crease
                      between them, and a leaf you turn with your finger
  blank.lua           a page that is not written yet: a heading and the way back,
                      which nothing instances today
  homework.lua        the checklist: four sections of challenges one to a spread,
                      a ladder of boxes per row, and how close the rung still
                      standing is
  challenges.lua      what is on it -- the bestiary, the term, the collection
                      and the evolutions, every row derived off some other table
  canteen.lua         the canteen: what the purse holds and the four sections it
                      is spent over, on the lesson's page
  course.lua          course.txt: how hard the book is -- the four rungs of the
                      difficulty ladder, how far up it has been bought, and
                      which one the next run is sat at
  records.lua         the longest run and the biggest body count on each page,
                      and the hardest class each has been beaten at
  tally.lua           tally.txt: the same register the other way round -- what
                      every run so far did, added up rather than the best of it
  characters.lua      who you play as: which hero is picked, which of them have
                      been bought, and how long the longest run as each lasted
  purse.lua           purse.txt: what every run so far earned, and the coin it
                      is counted in
  design.lua          the things the player draws, and their save files
  studio.lua          the board: hero, sword, shot, star, bird, rocket, sun's
                      face, cool S, bomb, skate, lightning
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
  Five more blocks do the rest of what an enemy can be, and each is read in one
  place: `keep` holds a range instead of closing, `charge` telegraphs and then
  commits to a stale heading, `split` leaves smaller things behind, `burst`
  makes killing it cost something, and `knock`/`hold` are what a shove and a
  glueing are worth against it. See **What walks on** for why each exists.
  A reference copy of the art belongs in `art/vanilla/<name>.txt`, with its size
  added to `BASE` and its name to `ORDER` in `art/bake.lua` and
  `art/preview.py` — otherwise no lesson can ever reskin it and there is no way
  to look at it against a ruling before it ships. And red is a poor choice for a
  *fill*: it comes out slate over a printed rule, so a body made of it wears a
  grey bar through the middle on ruled paper. Blush darkens to red instead and
  keeps its shape, which is why the skull, the wad and the bulb are all built
  out of it.
- **The same enemy, harder:** already exists, and is not a new row. A champion
  is a multiplied difficulty scale rolled per arrival in `src/spawner.lua` — 3.6×
  health at twice the size — so anything in `Enemy.types` is one the day it lands.
- **The same enemy, bigger:** also already exists, and also not a new row. Both
  standouts carry a whole-number size on the same multiplied scale — a champion at
  2 and a blow-up at 3 — and that number is the sprite scale and the radius
  multiplier at once, so anything in `Enemy.types` is one the day it lands, at no
  second size of art. Check the width first, though: anything wider than the
  grin's 14 pixels is wider than the boss eye when it is blown up.
- **The same enemy, angrier:** already exists too, and is the one of the three
  that is not a size — a fury is a quarter on the legs, half again on the damage
  and the whole body recoloured to red and black, rolled per arrival at a
  doctorate (see **Fury**). The two colours are worked out from the drawing, so
  there is nothing to author and nothing to add: anything in `Enemy.types` is
  enrageable the day it lands, and so is any reskin of it a lesson brings.
- **New fusion:** a row in `Tools.list` written at the *combined* numbers of the
  lines it is made of, an icon in `Sprites.icons`, and a `fusionLine` in
  `src/upgrades.lua` naming that row plus two fields — `needs`, the lines that
  must all be at their last level before it may be dealt, and `fuses`, which of
  those it spends. Nothing else. It is a tool line, so the strip, the library, the
  selector column and the slot counter already know what to do with it;
  `Loadout:ready` and the fused set in `Loadout:rebuild` are the two clauses
  that make it a fusion. Three more things come off `fuses` on their own and none
  of them is a line you write: the blush plate its icon wears everywhere it is
  drawn (`Upgrades.fused`, read by `Hud.drawIcon`), its place behind `EVOLUTIONS`
  in the library rather than on the tool shelf, and its answer when a player pairs
  the two tools it eats. `fuses` must be a subset of `needs` and must include at
  least one line of the fusion's own kind, which is what lets the draft deal one
  past a full strip: it hands back at least as many places as it takes.
  Requiring finished lines is what buys the right to *copy* their finished
  numbers rather than invent new ones — do that, and there is nothing new to
  balance. The one thing a fused row may not do is write down a table
  `scaleDamage` reaches into (`ignite`, `ram`, `loop`, `crit`, and inside a block
  `blades`): `Tools.copy` copies the row and its blocks one level deep,
  so a shared table one level further in compounds. Those are built by the unlock's
  own `apply` instead, which is what `fusionLine` allows and an ordinary `toolLine`
  does not.
  A fused row may carry a block *and* brush fields, and four of the nine do — see
  **Fusing two lines**. It may carry two *blocks* instead, and there are three
  readings of the second one: what the arm is holding (the spindle), what it works
  as it travels (the hem), and what the circle it drew *casts* when a second circle
  crosses it (the fold). Where the two parents disagree about a field, ask which
  parent's *body* decides it: a rim's width is the nib's, and the moat keeps the
  compass's cut and shove beside a brush that does neither, because one is what the
  arm does on its way past and the other is what the mark does. Leave out a
  parent's number the fused row would never read (the lasso drops the pencil's
  `flow`), and *definitely* leave out one that would be read and would lie (the
  corral drops the pen's `smooth`: a nib that trails a hand cannot trail an arm).
  What the fused brush lays need not be an attack — the corral's is terrain, and
  the only thing that cost is two lines in `src/compass.lua`. A second *block* is
  how a row says what the arm is carrying, and there are two readings of that which
  the block itself picks between: carried and driven in at the end (the spindle) or
  pressed as the arm travels (the hem, on `rake` being there). And a fused row may
  price its own gesture — `sweep.per` charges the hem by the staple, which is the
  one place a drag is capped by the meter (`Game:sweepReach`) — or change what its
  block *reaches*, which is `sweep.wipe`: the clearing hits the disc the leg has
  swept instead of the line it drew, and shoves outward instead of along. And `Loadout:ready`
  refuses a fusion whose `fuses` names a line an earlier fusion already ate, so
  fusions sharing an ingredient are mutually exclusive without any of them saying
  so: name the shared line and the choice comes for free.
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
- **New tool that isn't a brush:** give it a `drop`, a `snap`, a `sweep` or a
  `cut` block instead of a `stamp` and none of the fields that describe a line
  apply — it carries its own numbers and `ink` is the flat price of one use.
  `drop` is *placed* (a tap puts one where you tapped); `snap` is *aimed*
  (press to pivot it about the player, release to land it, `src/ruler.lua`);
  `sweep` is *opened* (the press stands it where you pressed, the drag out of
  that same press sizes it, the release sets it going, `src/compass.lua`); `cut`
  is *tapped twice* (the first press anchors and the second says which way it
  runs, `src/scissors.lua`). A block may also list fields only its upgrade line
  ever writes, at their off values, so that the tool's own header says what can
  happen to it — the scissors' `blades`, `through` and `sever`, and the bomb's
  `burn = nil` before them. Watch the names: `scaleDamage` reaches into every
  block by field name, so the scissors' deep stretch is `blades` and not `bite`,
  the compass's `bite` being a bare multiplier and one generic walk away from
  being indexed as a table.
  `Game:updateDrawing` sends the press down one of the five paths on those four
  fields alone. Anything that is paid for before it lands also has to be landed
  from every route that can take it away — the release, a tool change, and the
  pause (`Game:snapRuler`, `Game:swingCompass`) — or the ink is spent on
  nothing. Anything that reads the pointer after the press edge also needs the
  guard those two have, or a press that was already down when the tool was
  switched gets claimed by a tool it was never meant for. A block whose gesture
  spans more than one press has the same obligation shaped differently: the
  scissors charge on the *second* tap, since there is nothing to land after the
  first, so what every route has to drop is the anchor rather than a paid-for aim
  (`Game:dropCut`).
  Anything a tool leaves that is the page *not being there* goes in the page
  pass instead, between `Overprint.beginPage()` and `beginInk()` — which today is
  the scissors' severed half and nothing else. A grey half in the ink layer would
  be a mark, and the pass would faithfully show the ruling through it.
  The block says how a tool is *used*, not what it is, so two tools used the
  same way share one: the pushpin and the stapler are both `drop`, and the
  `lands` field inside the block names the module that turns up on the page
  (`src/pin.lua`, `src/staple.lua`). Both sit in one list, `game.drops`, and
  answer `update`, `drawMark` (the page layer) and `draw` (over the crowd).
  Returning false from `update` retires one to `game.spent` rather than
  destroying it: these two are the only tools whose marks stay on the page, and
  a spent one is never updated again and is drawn only when it is on screen.
  Unless it landed inside the footprint of one already on the page, in which case
  it is dropped on the frame it lands instead of being retired — see the pushpin.
- **Taking a tool off the strip:** move its row from `Tools.list` into
  `Tools.shelved` in `src/tools.lua`. Nothing addresses a tool by name or index
  — the selector, the number keys, the input routing and the ink meter all read
  the list — so it goes and comes back in one line. The crayon is sat there now.
  Its upgrades, if it had any, would go with it: the draft never offers a line
  whose tool is not on the strip, and the library never lists one — a catalogue
  that promised something the game cannot deal would be worse than no catalogue.
- **New upgrade:** append a row to `Upgrades.list` in `src/upgrades.lua` with an
  icon in `Sprites.icons`, and give each level a line of text and an `apply`.
  What `apply` is handed depends on the row: the run's stat block for a passive
  or a weapon, and the run's *copy of the named tool* for a tool line, plus the
  canvas for anything that has to be measured off the page. Nothing else needs
  touching — the draft offers whatever still has a level left, the loadout replays
  it, and the library lists it in full on the shelf its `kind` puts it on. Write
  levels as functions of what they change and never as differences from what the
  previous level did, because every level is re-run from scratch on every pick.
  Do write the level text so it reads on its own, though: the library prints all
  of a line's levels one under another, so a level that only makes sense as the
  card after the one before it is a level that reads as a repeat there.
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
  is no line query and a circle round the muzzle is one. If it leaves something
  lying on the *page* rather than standing over it — the bomb's burning crater,
  the skate's trail —
  give it an optional `drawGround(game)` as well: that pass goes down with the
  marks and the boss's puddles so the crowd walks over the top of it, since a
  filled patch drawn in the weapon layer would hide the things it is hurting.
  `draw` is optional on the same terms read the other way round: a weapon that is
  *all* surface has nothing standing over the page at all. And if the rest of the
  frame has to ask the weapon something — what the player is standing on, what a
  gem is lying on — put one named accessor on the loadout (`Loadout:trail`,
  `Loadout:flock`) rather than having anything reach into `live` by stat name.
  A weapon does not have to hurt anything: one that *moves* the crowd hands an
  enemy somewhere else to walk to (`Enemy:lure`, the spirals) or shoves it
  (`Enemy:knockback`), and both are handed over rather than read off the page,
  since the weapons are stepped after the crowd has already moved.
- **Something drawn at eight headings:** add `turns = true` to the design. It is
  only worth it for something that points where it is going (the rocket, the
  sword), it
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
- **New subject:** append a row to `Subjects.list` in `src/subjects.lua` — a
  `paper` (tile size and a function saying what colour is at a position inside
  it), a `name` for its tab, a `tool` naming the tool line it
  hands the run, and optionally the two dials a lesson is allowed over the
  horde: `crowd`, which
  multiplies the weight of a kind in the spawn table, and `clock`, which scales
  the difficulty clock. No lesson turns either today. A lesson that wants to be
  *harder* rather than different wants a course instead (see below): a page may
  shape an arrival and may never price one, which is what keeps a record on one
  page worth comparing to a record on another. Nothing else has to be touched: the
  page is baked at load with the rest, the timetable grows a line, and the
  number keys go up to as many (nine, after which a lesson is scribbled for rather
  than pressed). Keep the ruling to `Palette.surfaces` and the tile size to whole
  multiples of whatever it repeats on, give it something vertical a page width
  apart, and give the lesson a `tool` — a tool line's id from `src/upgrades.lua`
  — that no other lesson already hands out.
- **New course:** append a row to `Course.list` in `src/course.lua` — a `key`, a
  `name` for its card, and the seven dials, all of them written as multiples of
  high school's row of ones: `clock` (how many bodies), `hp` and `ramp` (how much
  health, flat and compounding), `speed` (how fast they walk), `elite` (how many
  champions reach their ceiling), `blown` (how soon the next giant) and `pay` (what
  the run is worth). The last two are multiples of a *rate of change* rather than
  of a chance, which is why they look larger than they act.
  Then one more price in `Course.price` and one line of Spanish for the name. Where
  the row goes in the list is the order it is bought in, since the counter's one
  row opens the next rung down. Nothing else: the timetable grows a card, the
  counter's figure grows by one, the register files it against the page, both end
  cards print it and the refund hands it back — every one of those off the list
  alone. Two things to *check* rather than write. **Measure `elite` and `blown`
  instead of reasoning about them**: both are read once per arrival and a harder
  course hands you fewer arrivals, so a multiplier that looks like more can come
  out flat. And **leave enemy damage where it is** — what a course may take away is
  time, never the arithmetic a player counts their own health in. A dial that is
  not a multiple of something the spawner already works out is the sign the idea
  belongs somewhere else: a course has no business naming a kind, a shape or a
  minute, because those belong to the page.
- **New character:** append a row to `Characters.list` in `src/characters.lua` — a
  `key`, a `name` and a one-line `blurb` for the studio's selector and the canteen's
  counter, a `weapon` naming the weapon line in `src/upgrades.lua` the run opens
  holding, a `price` (a list of one, `PRICE`) unless it is the row the book comes
  with, and a
  `design` naming a row in `src/design.lua` so the hero's board hands straight on
  to that one. The `price` is what puts it on the counter's `HEROES` section *and*
  what locks the weapon it carries until five minutes have been survived as it —
  both read off the row, so a fifth hero costs the canteen and the collection nothing
  each. The weapon is the whole of how a character fights: where it has to
  stand, what a hit is worth and how often one comes round are numbers on that
  line's block, read once, by the weapon — so a character is a weapon line plus a
  row here saying who is issued it, and any hero can end up flying any of them. A
  `weapon` naming a line that already exists costs nothing but the row: the starman
  and the skateman are the stars line and the skate line issued at level one, and
  neither of them needed a word of code.
  **Renaming** one wants a `was` field naming the key it used to have, so the hero
  board drawn for it follows it to the new file instead of turning back into the
  default stick man. Nothing else has to be touched: the selector measures itself off the widest
  name and the longest blurb in the list, so another character costs that screen
  no width and moves nothing on it. Keep the blurb inside 24 characters, and out
  of the punctuation the 3x5 face does not have — a glyph the face is missing comes
  out as a space the width of a letter. It has a comma now, and an N-tilde, and
  the two inverted marks; it has no acute accents and cannot have any, since a
  capital in it fills all five of its rows.
- **Something the book has to be earned to reach:** add a row to
  `Collection.gates` in `src/collection.lua` — a `need` naming one of the four
  columns (`time`, `kills`, `sat`, `beat`) and the single `line` it opens. Nothing
  else: the draft's pool asks the same one question the library's shelf does
  (`Collection.has`), the count in the corner is measured off the shelves, and the
  words a locked entry prints come off the `need` through `Collection.why`, with
  how far along you are on the line under them — so a new quest reads out on the
  shelf by existing. A gate naming a line that does not exist asserts at
  load rather than quietly locking nothing, and so does a line gated twice.

  Five rules worth keeping. **One feat, one line** — `line` is singular, and the
  reason is that a quest you cannot re-price without moving something else is a
  quest nobody will ever re-price. **Price a `time` row above the term's ceiling**:
  seven minutes or less arrives while the player is opening pages, and a reward you
  cannot miss is not a reward. **Keep the boss count low** — three of seventeen ask
  `beat`, because six of the seven bosses do not exist yet and `sat` asks the same
  question without them. Never put a **character's weapon** behind a quest — a
  bought hero's line has a lock of its own already, read off the roster, and the
  base hero's may have none at all, since his weapon is what a fresh book's first
  draft has to deal. And a **lesson's tool** needs no row, nor does a **fusion**:
  each has one already, read off the timetable and off the fusion's own `needs`.

  A new kind of `need` wants a branch in `Collection.met`, a pair of phrases in
  `Collection.why`, a case in `Collection.progress` if there is a meter the homework
  page can draw, and keys in `src/i18n.lua`: a key and what goes in its slots, never
  a sentence built in Lua and looked up afterwards, which is a mistake the English
  draws perfectly.
- **Anything the player reads:** write it in English where it belongs — the
  upgrade's row, the tool's name, the screen's own constant — and add one line to
  the `ES` table in `src/i18n.lua` keyed by that English. Then check that the place
  which *draws* it puts it through `I18n.t`, and that anything measuring it for a
  layout measures the translation rather than the key. Avoid a comma and any acute
  accent in the Spanish; N-tilde and the inverted marks are fine.
- **A language:** a row in `I18n.langs` — a `key`, a two-letter `code` for the
  title screen's switch, and the language's own name for itself, which is never
  translated — and a table beside `ES`. Both the switch and the settings stepper
  step the list, so a third costs neither of them anything. Check the new words
  against the 3x5 face first: a letter it has no glyph for draws as a blank.
- **Balance:** `SPEED` at the top of `src/player.lua` — the loadout only ever
  scales what is written there — the level tables of the `SHOT` and `SWORD` lines
  in `src/upgrades.lua`, which are where every number either hands-free attack has
  now lives: how far it reaches, what a hit is worth, the gap between one and the
  next (three numbers that sat on a character until those two attacks became
  lines), how fast a pellet flies and how many leave at once, and the arc's own
  `reach` and `sweep` — where the reach sets how *wide* the arc is as well as how
  far it goes, the sweep being an angle. `TIME` at the top of `src/sword.lua` is
  the one piece of the swing that is not on the block and is not meant to be: how
  long the arm is out is the half of the weapon you play, so a wider sweep is a
  faster edge rather than a longer wait.
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
and that is the last you see of it. There are twelve passive weapons (the shot, the sword, the stars,
the m birds, the rocket, the sun, the cool S, the laser beam, the bomb, the
skate, the spirals and the storm) for five
slots, one of which the character spends on the way in, so a run gives seven up
whether it means to or not. Every line in the catalogue is filled in now — the
pen's and the stapler's were the last two that were an unlock and nothing after
it, and both are five long, which is the shape `SHOT` and `SWORD` were filled
into once their four each were written. No *card* in
the draft ever takes anything away — the one thing that does is `EXPEL`, which is
a button and has to be bought.

Dying puts up a card with `RETRY` on it, and taking it goes straight into the
next run rather than back through the title screen.

The canteen sells seven things and gives them all back (see **The counter**). Three are about the draft, the
fourth is the retake — the first thing on the counter that changed how a run is
*played* rather than what it is offered — and the other three are heroes, which are
the first thing on it that the *collection* also cares about: buying one is what
makes the weapon he carries something the rest of the book can earn. The seventeen
quests are still keyed to the register alone, so the coin and the collection meet
over the roster and nowhere else yet. The achievements the homework page grew
instead are keyed to a second memory again — a tally rather than a record — and
they are deliberately outside all of this: they open nothing, and **Homework and
the canteen** argues for why.

The **crayon** is written and working but is not on the strip at the moment — it
sits in `Tools.shelved`. It is a wax lane: a 13px band you run 1.75× along —
faster than anything in the game — while anything chasing you onto it loses its
footing, keeps the heading it arrived with and slides straight past. Moving its
row back into `Tools.list` puts it back in the game.
