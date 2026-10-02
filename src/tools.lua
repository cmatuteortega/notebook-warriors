-- What you can draw with.
--
-- Every tool is the same object shape, so adding another is a matter of
-- appending a row here plus an icon in src/sprites.lua:
--
--   radius     how far from the stroke's centre line it can touch an enemy
--   damage     per hit
--   knock      knockback impulse applied away from the stroke
--   freeze     seconds a caught enemy is held in place (nil = never)
--   wall       solid: enemies steer around the line instead of crossing it --
--              filed at the tool's own radius by Walls:rebuild, whether the
--              line was laid by a hand or by a compass leg (the CORRAL below)
--   slick      slippery surface: {boost} for the player, {turn} for enemies
--   spacing    pixels between brush stamps along the path
--   smooth     how tightly the nib follows the pointer (nil = exactly)
--   ink        meter cost per pixel of line drawn (per drop, for a dropped one)
--   life       seconds the mark stays on the page after the stroke ends
--   ramp       colours the mark passes through as it fades, in order
--   fade       fraction of life before stamps start dropping out (dither)
--   rough      fraction of stamps missing from the off, for a broken mark
--   rehit      seconds before the same enemy can be hit again (nil = once)
--   linger     keep hitting enemies standing on the mark after it is drawn
--   tickRate   seconds between those ticks
--   stack      linger only: how many separate passes of one stroke may tick at
--              once over the same spot (nil = layers never stack). A pass is a
--              stretch of the path, so scribbling back over your own band is
--              what earns the extra layers -- see Stroke:lingerTick. Stacked
--              ink is visible: dabs laid back over the stroke's own ground are
--              drawn in the edge's colour (Stroke:draw), so where the layers
--              will bite is exactly where the band reads deeper.
--   graze      linger only: extra pixels of reach for the tick, over the ink's
--              own radius. For a mark that is also a wall, which is the pen's
--              contact level and the ring a compass carrying one rules:
--              Enemy:resolveWalls parks a body
--              at *exactly* the ink's edge, so a tick measured at the radius
--              alone would land or miss on floating-point luck. Two pixels of
--              slack is the difference between a fence that stings what leans
--              on it and one that stings whatever the arithmetic felt like.
--   pop        the mark does not fade quietly: on the frame its life runs out
--              it comes off the page all at once, and everything within
--              `reach` of the ink takes `damage`. The whole line rather than a
--              circle somewhere on it -- a fence has no centre -- see
--              Stroke:pop, called from Game:updateDrawing as the stroke is
--              culled.
--   keep       the marks of this tool are held on the page for as long as they
--              are the last ones laid: they do not age and they do not fade.
--              Laying another is what lets them go, and they are *let go*
--              rather than wiped -- they fade out on the life every other mark
--              gets. Marks rather than a mark, because one gesture is not
--              always one line: a compass carrying a pen (the CORRAL below)
--              rules its ring as one mark per leg and holds the pair of them.
--              See `Game:holdWalls`.
--   ignite     anything the mark covers catches fire: {time, tick, damage}.
--              The burn travels with the enemy and keeps ticking after it has
--              left the mark -- crossing the band is enough -- see
--              Game:updateBurning.
--   soften     freezing tools only: while this tool's hold has an enemy stuck,
--              everything that hits it hits this many times harder. Carried on
--              the enemy rather than read off the page -- see Enemy:hurt.
--   tear       freezing tools only: damage paid the moment the hold ends.
--              Coming loose is what costs, so it lands exactly once however
--              long the enemy sat there -- see Game:updateGlue.
--   pull       free enemies within `range` of the ink's edge are dragged
--              towards the nearest ink at `speed` px/s. See Game:updateGlue
--              and Stroke:pullTowards.
--   broad      a fatter nib for an upgrade to swap in: {radius, stamp, edge}.
--              Authored here rather than in src/upgrades.lua because what a
--              tool looks like is the tool's business; the level only says the
--              band gets it.
--   crit       a chance for any one hit to land far deeper: {chance, mult}.
--              Rolled per hit and announced when it lands -- see Stroke:apply
--              and Particles:crit. It means the same thing wherever it is
--              written, and it is written in two places now: on a brush, where
--              the stroke rolls it, and inside a `drop`, where what lands rolls
--              it (Staple:bite). A tool tapped dozens of times is the one place
--              in the game a one-in-five comes out as a rate rather than as a
--              story about that one staple.
--   flow       brushes only: the line gets cheaper the longer it runs without
--              the finger lifting. The cost per pixel eases exponentially from
--              the written price towards `floor` (a fraction of it, the cap
--              that keeps a long line from becoming free) over about `over`
--              pixels of line. Charged in Game:updateDrawing, reset with the
--              stroke.
--   under      drawn in the first pass, beneath every mark without it: for the
--              wide soft bands that would otherwise bury the thin lines laid
--              over them. See Game:draw.
--   lean       the tip keeps hitting where it rests while the stroke is held:
--              a zero-length segment at the head, every `rehit` seconds, held
--              back whenever the head is actually travelling. It is what lets
--              a tool that hits by being scrubbed be rested against something
--              instead -- and it is not free: {px} is what one resting hit
--              costs, in pixels of the tool's own ink, so the meter owns
--              leaning the way it owns drawing. Needs `rehit`. See
--              Stroke:update.
--   scrub      brushes only: what a pixel costs while the head is back over
--              ground this same stroke has already covered, as a fraction of
--              `ink`. A rub is back-and-forth by nature, so this discounts the
--              motion the tool is actually used with -- see Stroke:revisits.
--   pace       brushes only: the nib's weight follows the hand. Two nibs and one
--              threshold -- {over, thin} -- and which of them is on the page is
--              decided per dab, off how fast the *nib* was travelling when it
--              landed: at or above `over` pixels a second it is the thin one,
--              `thin` pixels of reach, and under that it is the row's own
--              `radius`. The nib and not the pointer, because `smooth` is what a
--              fast hand actually gets -- pricing the hand would sell the thin
--              line for a flick the nib never made.
--
--              It moves three things and they are one fact said three times: the
--              dab (`pacedStamp` below, since a stamp function is the only thing
--              in the drawing that ever sees an individual dab), the reach of the
--              hit (`Stroke:reach`), and the price by the pixel, which is the
--              ratio of the two nibs rather than a number of its own
--              (`Stroke:paceRate`) -- half as much ink on the page is half as
--              much out of the meter, and a row cannot say one thing about its
--              width and another about its cost. A mark whose width varies along
--              its own length also has to remember it, so the radius at each
--              recorded path point is kept beside the path (`pathR` in
--              src/stroke.lua): a tick off the finished line reaches as far as
--              the stretch of it the body is actually standing on, not as far as
--              the widest stretch somewhere else. What `ignite` tests is
--              deliberately the widest nib (Stroke:covers, Game:updateBurning) --
--              a burn is a body that touched the ink, and two pixels of slack
--              there is the pen's `graze` argument.
--   ram        what this tool's shove sends flying is itself a weapon while it
--              flies: {damage}. A launched enemy shoves and damages whatever
--              it runs into until its push speed drops back under the
--              threshold in Game:updateRams.
--   tap        the release reads this on a press that never went anywhere: a
--              radial hit at the point the finger landed on, {radius, damage,
--              knock, ram, ink, slack, hold}. `slack` and `hold` are what makes
--              it a tap -- how far the *finger* travelled in screen pixels and
--              how long the press lasted, both of them, and neither of them the
--              line: a finger held still while the player walks lays real world
--              line, so measuring the mark asks whether the page moved rather
--              than whether the hand did (Game:wasTap). `ink` is a flat price
--              like a tapped tool's, because that is what this is -- the one
--              gesture in the game a brush row can carry without giving up the
--              routing, since `drop` would beat the brush fields outright (see
--              the precedence list at the top of Game:updateDrawing) and a row
--              with both would never lay a line at all. `ram` means what it
--              means on the row above, and it is written in here rather than
--              out there so that the only shove hard enough to matter is the
--              one that reads it. See Stroke:tap, fired from the release branch
--              of Game:updateDrawing -- a press is not a tap until it has ended
--              without travelling, so nothing but the release can tell.
--   loop       close the line on itself and what is inside the ring is dealt
--              with once. Checked as the path is laid down; a close needs
--              real perimeter behind it and spends the path it used, so a
--              wiggle is not a lasso and a spiral has to keep travelling. See
--              Stroke:tryCloseLoop. A row where nothing is drawn by a hand
--              means the ring by something other than a path coming back to
--              itself -- a lap, for a compass (`Compass:ring`), or a circuit of
--              pins, for a row with `thread` below (`Game:stringThreads`) -- and
--              in both cases the mark the arm or the tap lays has `lassos`
--              cleared on it, because being surrounded happens once.
--
--              **What being ringed costs is three fields, and a row picks.**
--              `damage` is the pencil's own and the cheapest: everything inside
--              is cut once. `ignite` is a burn block ({time, tick, damage}) set
--              on everything inside instead, which is the marker's last level
--              delivered by the border rather than by contact (the BLEED below).
--              `lift` is {tick}: the ring is a hole in the page and goes on
--              taking what walks into it off the paper for as long as the mark
--              is on it, putting each one down again in the furthest clear corner
--              of the page -- the scissors' last level and the scissors' own
--              contract, `Game:liftEnemyTo`: a reposition, not a kill, so no
--              gem and no xp because nothing died (the CUTOUT).
--              A row may write more than one and they are independent; what none
--              of them may do is be assumed, which is why the walk in
--              `scaleDamage` asks for `loop.damage` by name before scaling it.
--
--              **And one field says the ring is drawn rather than only tested.**
--              `wash` floods the middle with the mark's own ink
--              (`Stroke:drawWash`), and `lift` lays rebaked page into it instead
--              (`Stroke:drawTorn`, called from the page layer in `Game:draw`
--              beside the offcut's own spans). Both walk the ring a row at a time
--              through `pixelart.fillPolygon`, and both use the same even-odd
--              test the hit is resolved with -- what is painted is exactly what
--              will be taken, which is the only reason a border is worth drawing
--              the inside of. A ring is kept on the stroke (`rings` in
--              src/stroke.lua) only by a row that writes one of these two.
--   fasten     a whole `drop` block on the row without being the row's block: what
--              a stroke drives into the page at its own two ends when the finger
--              lifts (the STITCH). It is the SEAM's `snap.wire` one storey out and
--              means the same thing -- a drop that something other than a tap is
--              pressing -- with the something being the stroke rather than a
--              straight edge. `ink` is the flat price of one, charged per staple
--              and refused rather than clamped; `slack` and `hold` are the tap
--              test above, and mean the same thing here. **The two ends go in at
--              the two moments**: the near one on the press, because a stapler
--              lands the instant you tap and putting a wind-up on the one tool
--              written without one stopped a tap feeling like a tap, and the far
--              one on the release if the finger actually travelled -- so a tap
--              fastens once because only one moment happened. See
--              Game:fastenEnds. `scaleDamage` and `scalePersistence` both reach
--              into it by name, as they do the wire.
--
--              **`tapped` reads the same test the other way round** (the SNAG):
--              nothing goes in at the press and nothing at the far end, and the
--              one staple lands *because* the finger never went anywhere. Which
--              is the whole of how a row can have a drop for one gesture and a
--              brush for the other: on that row the drag is a rub and a rub is
--              the thing that takes staples back out, so a press that fastened
--              first would put a staple at the head of every stroke and then tear
--              it straight out again. It also holds the mark's own hit back while
--              the press could still be a tap (`Stroke.touches`, set in
--              Game:updateDrawing) -- a stapler being pressed does not shove.
--   lift       {tick} -- **the ink itself is a severed region**: anything touching
--              this mark is lifted off the page and put down in the corner
--              furthest from you, on that clock, for as long as the mark is there
--              (`Stroke:sweepLine`, `Game:liftEnemyTo`). The scissors' finale with
--              a line for a shape, and the fourth shape one comes in after the
--              half-plane, the disc and the ring -- the first that is not an area,
--              and the only one that leaves the page underneath it whole. Same word
--              as `loop.lift` on purpose: that one lifts what a ring *encloses* and
--              this lifts what the line *touches*, which is one verb at two shapes.
--              No damage in it, so it may be written on the row (the PUNCH's rule)
--              and `scaleDamage` has no reason to reach it. One row (the DEADLINE),
--              and it is written with no `wall` beside it for a reason the row
--              spells out.
--   chord      a whole `cut` block on the row without being the row's block: the
--              page opened along the straight line between the mark's own two
--              ends when the finger lifts (the COLLAGE, the SCORCH). `fasten`'s
--              arrangement one shape over, and the rename is the whole point of
--              either field -- `cut` is in `Game:updateDrawing`'s precedence list,
--              so a brush row carrying one would *be* a pair of scissors and would
--              never lay a line. Every field a `cut` takes is read here too
--              (`Scissors.new` never learns which field it came out of), plus
--              `ink`, the flat price of one, refused rather than clamped and
--              undiscounted by the blotter for the STITCH's staples' reason.
--              See Game:chordCut.
--
--              **`tapped` turns the gesture over exactly as it does on `fasten`**
--              (the SHEAR): the two *taps* make the cut and the drag is the brush.
--              A row needs it when its mark has no two ends worth cutting between
--              -- a rub is an event that is nowhere once it is over -- and it is
--              the same field, read by the same `wasTap`, so it also wants the
--              `slack` and `hold` pair.
--   snag       this row's mark takes the page's own staples back out of it as it
--              travels: every one the stroke crosses is prised on the spot,
--              early, and its tear-out bite crits for certain (`Staple:snag`,
--              `Game:snagDrops`). A flag and nothing more -- what comes out, how
--              deep it bites and how it leaves are the drop's own numbers, and
--              only a drop whose module can be taken out of the page answers at
--              all, so a pushpin refuses without being named. It is also what
--              the rub's own two sounds read past the icon (Game:endStroke),
--              being only ever written on a row whose mark *is* a rub.
--   sting      what a *mark* does to whatever leans on it, where that is not what
--              the nib does going past. `damage` is one field and two tools may
--              write it meaning two different things: the DECKLE is a pencil
--              laying a pen's wall, so 9 is being drawn over and 1 is standing
--              against the finished fence. Read by Stroke:apply on a lingering
--              tick only, and defaulted to `damage`, so no other row changes.
--   thread     nothing here is drawn by a hand: it is *strung*, between two
--              things this same tool has already driven into the page. {reach}
--              is how far apart two of them may be and still be joined. Only a
--              row that also carries `drop` has any use for it, and today that
--              is five of the fusions off the pushpin at the foot of the list.
--              See Game:stringThreads.
--
--              **`reach` is what says whether this is a shape or a line**, and the
--              two numbers in the catalogue are 120 and 14 (`THREAD` and `LINK`
--              above). At the pushpin's range every pair of posts inside the reach
--              gets a rail, so a handful of taps is a shape you build. At the
--              stapler's a post can only see the next one in its own seam, so
--              thirty presses raked along a drag come out as one continuous mark --
--              which is `thread` and `rake` on the same row, a pairing no row had
--              before the stapler's three fusions and one that needed no new code
--              at all: a raked drop goes through Game:dropOne like a tapped one and
--              is stamped and strung exactly the same way.
--
--              **What gets strung is whatever else is on the row**, and that is
--              the same rule the blocks are routed by, one storey down. A row
--              with brush fields strings a Stroke built off them, laid whole on
--              the frame a drop lands -- so a `wall` thread is a fence between
--              two posts (the STOCKADE) and a `linger` one is a band strung
--              between them (the CORDON). A row with a second *block* strings
--              that instead, cast rather than pressed for, exactly as the FOLD's
--              `snap` is cast by two circles crossing: a `snap` is a ruler along
--              the line the two pins aim (the SNAP LINE) and a `cut` is the page
--              coming apart along it (the TEAR LINE). One field, three readings,
--              and the row picks between them by what else it carries.
--
--              **A strung mark is on the page for as long as both of its posts
--              are.** That is this field's own rule rather than any parent's
--              `keep`, and it is what makes the rows legible: a pin holds what
--              it caught for four seconds, so a shape built out of pins is on
--              the paper for as long as the pins are, and it begins ageing -- on
--              the tool's own `life`, down the tool's own `ramp` -- the moment
--              either end of it comes out. See `strung` in src/stroke.lua for
--              why that hold is not `kept`. It says nothing about a ruler or a
--              cut, and does not have to: those two land on the frame they are
--              cast and leave on their own block's clock, the way they do for the
--              tools they were taken from.
--   pool       the same idea at *one* post rather than between two: the brush is
--              laid as a single dab centred on the drop, on the frame it lands.
--              A flag and nothing more -- how wide the dab is is the brush's own
--              `radius`, as it is everywhere else -- and the two rows that carry
--              it write that radius at the crater's own 25, because a pool is not
--              a nib: it is what filled the hole, so it is as wide as the hole.
--              See Game:poolAt.
--
--              **One stamp is the whole mark, and two fields have to know it.**
--              The dither that takes a mark off the page drops *stamps*, and a
--              fraction of one stamp is either all of it or none -- so a pooled
--              row writes `fade = 1` and fades down its ramp alone, or it would
--              vanish at a random moment in its last half. `edge.rough` is the
--              same arithmetic on the rim and goes the same way. Both are in the
--              TACK's row where they were paid for.
--   margins    a ruled row only: the mark this row carries is laid down *both*
--              long edges of the band rather than along its centre line, which
--              is the pair of dashed lines a ruler's aim has always drawn made
--              real (the MARGIN, `Ruler:drawGuide`, `Game:trailRuler`). On the
--              row rather than in the block because it says where the *mark*
--              goes, which is the mark's business; `edge` one line down is the
--              brush's own rim and the two have nothing to do with each other.
--   stamp      draws one brush dab in the currently set colour. A brush may
--              have none, in which case it leaves no mark at all -- see crumbs
--   edge       second pass drawn underneath the core: {stamp, color, rough}
--   holes      third pass drawn over the top of it, same shape as edge
--   speck      particles thrown off while drawing: {chance, color}
--   crumbs     debris rubbed off the tip instead of a mark, thrown out to the
--              sides of the stroke rather than every way at once: {chance,
--              color}, chance per stamp step
--
-- Five of the tools are not brushes at all, and none of them draws a line, so
-- none of the fields above describe them. Each carries one of four blocks
-- instead -- the block says how the tool is *used*, not what it is -- and for
-- all of them `ink` is the flat price of one use rather than a cost per pixel:
--
--   drop   placed. A tap puts one where you tapped: {lands, radius, damage,
--          freeze, life}. `lands` is the module that turns up on the page, and
--          it is the only thing separating the pushpin from the stapler --
--          those two are used in exactly the same way, so they share the block
--          and the code path, and differ in what arrives and by how much. See
--          src/pin.lua and src/staple.lua. A row where the block is not the
--          gesture may add `sprite`, the name of what the thing is seen being
--          carried as: the SPINDLE's leg has a pushpin on the end of it rather
--          than a lead, and Compass:drawLeg draws that instead. The pin's upgrade line adds three
--          more, all resolved in Pin:land: `point` multiplies the hit on the
--          one body the point itself came down on, `refund` gives {frac} of
--          the price back when {count} or more were under the circle, and
--          `drive` is damage per kill added to the hit on the survivors.
--
--          The stapler's line adds three of its own. `crit` is the field above,
--          rolled by what lands rather than by a stroke. `prise` is the one that
--          changes the *ending*: instead of the page keeping the staple when its
--          hold runs out, the wire is torn back out of the paper, biting a second
--          time on the way and leaving nothing behind -- see src/staple.lua and
--          the `lifted` branch of Game:updateDrops. And `rake` is {every}, the one
--          field here that changes the *gesture*: while the pointer is held
--          another one lands every `every` pixels it travels (Game:rakeDrops), so
--          a tapped tool becomes a dragged one.
--
--          A fusion adds a fourth, and one row carries it (the CLINCH). `tacky`
--          is seconds between *catches*: everything standing in the circle is
--          stuck to the wire again, on that cadence, for as long as the staple is
--          in the page -- which is the gluestick's own contract (a hold
--          re-applied rather than a hold handed out once) on a fastener instead of
--          on a smear. A catch is not a bite: no damage and no crit, because a
--          staple that hit everything on it every four tenths of a second would be
--          a weapon and this is a fastener. What it costs the crowd is that it is
--          still standing there when the wire comes out. See `Staple:catch`.
--
--          It is also the one thing in the game that hands a *block* to
--          `Enemy:freeze` as the thing doing the sticking, which is how a run's
--          `soften` beside it rides on the body rather than on the wire
--          (`Enemy:hurt`) -- a staple's hold has always passed nothing, and this is
--          the exception the comment there names.
--
--          `rake` is the one of the stapler's three a *fusion* writes as well, and
--          the VOLLEY below is it: the same field, the same code, at four and a half
--          times the price and four times the spacing, because what the field
--          says is "this gesture is a drag" and that is true of a pin exactly as
--          it is true of a staple. One more field is written by that row and by
--          nothing else -- `instant` takes the pushpin's fall off, so the crater
--          lands on the frame you tap it. It is the one flag in the catalogue
--          that removes a telegraph rather than adding an effect. See `Pin.new`,
--          which reads it beside the flag a compass leg sets.
--   snap   aimed. Press and it pivots about the player, release and it comes
--          down: {length, width, damage, knock, life, ramp, fade}. See
--          src/ruler.lua. A row where the block is not the gesture means
--          something else by it, exactly as `drop` does: the FOLD's is the ruler
--          two of its own circles cast between their crossings
--          (`Compass:crease`), which is the one block in the catalogue nobody
--          ever presses for. Its `length` goes unwritten there, because the chord
--          decides how far it reaches and a number nothing reads is a number that
--          would lie -- see the row.
--
--          The ruler's own family of fusions adds three, and all three are about
--          the *line* rather than about the ruler, which is why they are here and
--          not on the row. `wipe` takes the band off: what the block reaches is
--          every body within the ruler's own length of the line rather than within
--          its width, so a straight edge ruling the whole page parts the whole page
--          (the PARTING). It is the compass's field of the same name in the other
--          block and it means the same thing -- what a block reaches, not by how
--          much. `wire` is a whole `drop` block one level in: what the straight edge
--          presses into the page as it comes down, one every `rake.every` pixels
--          of the line (the SEAM). It is inside the block rather than on the row
--          because `drop` and `snap` are the one pair in the catalogue that borrow
--          each other's gesture in both directions and a precedence list cannot say
--          so -- see the note at the top of `Game:updateDrawing`. The first is read
--          by `Ruler:strike` and the second by `Game:trailRuler`, and the row's own
--          `margins` below is the third of the set.
--   sweep  opened. Press and the needle goes into the page there, drag to open
--          it out to the width you want, release and it swings: {minR, maxR,
--          width, damage, knock, turn, life, ramp, fade}, plus the three the
--          upgrade line moves -- `laps` times round (`turn` is seconds for one
--          of them), `bite` times the damage over the first `biteArc` radians of
--          each lap, and `counter` for a second leg going the other way. One
--          fused row (the PUNCH) also carries `sever` -- {tick} for the
--          disc the closed ring takes off the page, which is the scissors' own
--          last level with a circle round it instead of a half-plane, and the
--          only thing a sweep does to the middle of its own circle. Another (the
--          SPINDLE) carries `drive`, damage per kill added to what the point
--          reaches next, and a `drop` block beside the sweep saying what the leg
--          is carrying. Three rows carry a second block now and no two of them
--          mean the same thing by it: what the leg is holding (the SPINDLE), what
--          it works as it travels (the HEM), and what the circle it drew casts
--          when a second circle crosses it (the FOLD).
--          `width` is the ruler's and the scissors' word for the same thing --
--          how far off the line a body's centre may be before its own radius
--          stops reaching -- and here the line is the *rim*: what a compass cuts
--          is the circle it draws and never the middle of it. See
--          src/compass.lua.
--   cut    tapped twice. The first tap anchors, the second says which way it
--          goes, and the page opens along the line between them: {reach, width,
--          damage, knock, life, ramp, fade}. The only block whose gesture spans
--          more than one press, and so the only one whose `ink` is charged by
--          the second tap rather than the first -- unless the blades are carrying
--          wire, and then it is charged by both (see `wire` below) -- and the only
--          one that does
--          not land the moment it is paid for, since the blades then travel the
--          length of that line rather than closing along all of it at once. See
--          src/scissors.lua and Game:openCut. Its upgrade line adds three more, all resolved in
--          Scissors: `blades` is {damage, width} for the stretch between the two
--          taps, which from then on is worth more than the rest of the cut the
--          way the compass's `bite` is worth more than the rest of a lap -- and
--          it is deliberately not called `bite` too, since that one is a bare
--          multiplier and scaleDamage walks these blocks by field name;
--          `through` runs the cut on past both taps to the edges of the page;
--          and `sever` is {tick} for the half of the page the cut takes
--          off it, the one thing in the game that writes into the *page* layer
--          rather than onto it. It takes one more field, and only one row writes
--          it: `follows` makes the cut re-read which half you are standing on
--          every frame instead of freezing it at the tap, which is what a cut
--          ruled through your own feet needs and what nothing else does (the
--          GUILLOTINE below, `Scissors:takeSides`).
--          Two more are read by fused rows only and both are nil everywhere else:
--          `ignite` is a burn block ({time, tick, damage}) set on whatever the
--          blades cut and survive it, which is the marker's finale delivered by a
--          pair of scissors (the SCORCH, `Scissors:strike`); and `sever.paste` is
--          seconds of glue laid on whatever the offcut carries into the corner,
--          which is the gluestick's (the COLLAGE, `Scissors:lift`). The second is
--          the only thing in the game done to a body by the region that *moved* it
--          rather than by the ground it landed on.
--          One fused row adds a fourth (the HINGE): `wire` is a whole `drop`
--          block one level in, exactly as the SEAM's is inside `snap`, and it is
--          the same wire read against a different line -- a staple where each tap
--          landed and the stretch between them filled at `rake.every` pixels
--          (Game:openCut, Game:closeCut, Game:seamAlong). It is inside the block
--          rather than on the row for the SEAM's reason: a `drop` on the row
--          *would* be the gesture, and this one is what the blades are carrying --
--          see the note at the top of `Game:updateDrawing`. It is also the one
--          field in the game that moves where a price is charged, because a tap
--          that drives a staple is not the free anchor the parent's rule was
--          written about.
--
-- **A row may carry more than one shape**, and most fusions at the foot of the
-- list do. Thirteen are a brush and a block at once: four a brush and a sweep --
-- the HALO, the LASSO, the MOAT and the CORRAL -- four a brush and a *snap*, which
-- is the newest of the three families -- the MARGIN, the SPINE, the UNDERLINE and
-- the TRENCH -- and five a brush and a `drop`: DOT TO DOT, the STOCKADE, the
-- CORDON, the TACK and the CRATER. Six carry *two blocks* apiece -- the SPINDLE,
-- the HEM, the FOLD, the SNAP LINE, the TEAR LINE and the GUILLOTINE. And five
-- carry a single shape, every one of them for a reason worth reading rather than
-- because there was nothing to add: the PUNCH and the CLEARING are a sweep and
-- nothing else, because the scissors' half of one and the rubber's half of the
-- other live entirely inside the block; the PARTING and the SEAM are a snap and
-- nothing else for the same two reasons one family over, the rubber's shove being
-- a field on the block and the stapler's wire being a block *inside* it; and the
-- VOLLEY is a `drop` and nothing else, because both of its parents are already
-- that block and what it fuses is the block's own fields. The rule that makes all
-- of them work
-- is the same one and it never had to change: the block tested first is the
-- gesture, and whatever else is on the row is what the arm is carrying. Nothing had to be
-- taught that -- the press is routed on field presence and the blocks are tested
-- before the brush fields (Game:updateDrawing), so a row with a block is used as
-- that block, and its brush fields are simply there for whatever wants them.
-- What wants them here is the compass: a leg carrying a nib rather than a lead
-- drags a Stroke round behind it built off this same row (src/compass.lua), so
-- the mark it leaves is the brush written above, laid by the arm instead of by
-- your hand. That is what a *fusion* is made of (`needs` and `fuses` in
-- src/upgrades.lua): two finished lines both still doing exactly what they always
-- did, at once. And what the brush fields are is not always an attack: the
-- CORRAL's are the pen's, so the mark the arm leaves is *terrain* -- a wall with
-- no ends, laid where your hand is not, which is both of the things the pen has
-- never been able to do. The first nine are that same compass wearing
-- something else -- bar one, and the FOLD is worth reading for it: nothing is on
-- the arm there at all, and the tool's second half is a thing that happens
-- *between two marks* on the page.
--
-- **And then the pushpin, which is the second thing on the strip worth borrowing
-- a gesture from, and the reason the paragraph above used to end differently.**
-- It said the nine were all the compass because the compass is the only tool
-- that reaches away from you. That was half right. A pin also lands wherever you
-- tapped and never where your hand is -- what a pin has never had is a **line**.
-- It is a point, and a point cannot be a shape, a fence or a band however far off
-- you put it. So the rows at the foot of the list are the compass's argument
-- through the mirror: there, a gesture that reached borrowed a nib and its *ring*
-- became a mark; here, a gesture that reaches borrows a nib and the *pins* become
-- one.
-- Nothing about the tap changes -- it is the pushpin's tap, the pushpin's
-- quarter-second fall and the pushpin's crater -- and then a second pin dropped
-- near the first is joined to it by whatever nib the fusion ate (`thread` above,
-- Game:stringThreads). One field, and it is the same field on five of the eight
-- rows: what makes DOT TO DOT a shape, the STOCKADE a fence, the CORDON a strip of
-- burning page, the SNAP LINE a ruled diameter and the TEAR LINE a page in two is
-- only what is written beside it, exactly as the compass's nine differ only in what
-- is in the leg. Two more carry `pool` instead, which is the same idea at one
-- pin rather than between two -- because two of those parents are not line tools,
-- and you do not string paste between two points.
--
-- **And then the eighth, which is neither, and which is the one row that breaks
-- the sentence three paragraphs up.** "Nothing about the tap changes" is true of
-- all seven above: they are the pushpin's tap, the pushpin's quarter-second fall
-- and the pushpin's crater, with something new happening near the pin afterwards.
-- The VOLLEY changes only the tap, and nothing happens near the pin at all.
--
-- Which is the pushpin fused with the one tool on the strip that shares its
-- gesture. Everywhere else in this family the second parent brings a *nib* or a
-- second block -- something the pin has never had -- and the pin brings the reach.
-- Here both parents are already a `drop`, so there is no nib to borrow and no
-- shape to string: the two rows differ in nothing but the numbers and flags inside
-- one block, and the fusion is those two sets of fields laid over each other. It
-- is the only fusion in the game that is one block deep, and it is why what it
-- fuses -- a `rake`, a `crit`, and the fall taken off -- are fields on the block
-- rather than shapes on the row.
--
-- **And then the ruler, which is the third gesture worth borrowing from and the
-- one the other two had already borrowed *first*.** The FOLD casts a ruler
-- between two compass circles and the SNAP LINE casts one between two pins, so by
-- the time these seven rows were written the ruler had been on the receiving end
-- of both families and had never once been the tool doing the fusing. Which is
-- odd, because it is the only gesture on the strip that is *aimed*: a brush goes
-- where your hand goes, a pin and a cut go where you tapped, a compass opens
-- where you pressed, and a ruler is the one thing you point.
--
-- What it points is a line through your own feet, and that is the tool's whole
-- limitation -- you choose which way the page is swept and never where. The two
-- fusions cast *at* it are both answers to that sentence: the FOLD sells the reach
-- to buy the position and the SNAP LINE keeps the reach and pays in precision.
-- These seven leave the limitation exactly where it is and answer the other
-- complaint, the one nobody had written down: **a ruler's mark does nothing.**
-- Everything within the band is hit once and thrown clear of the line to both
-- sides, and what that leaves is a corridor across the page with a ruled pencil
-- line down the middle of it -- and the corridor closes the moment the crowd walks
-- back in, because a pencil line is not terrain, not fire, not paste and not a
-- fence. The ruler opens a lane and has never been able to keep one.
--
-- So the second parent is what gets left in the lane. Nothing about the gesture
-- changes -- the press pays, the pivot follows you, the drag turns it, the release
-- lands it, and the band comes down at the finished ruler's 13 across and 210 of
-- shove -- and then whatever else is on the row is ruled along the line it landed
-- on (`Game:trailRuler`). Two graphite lines down the band's own edges, a fence,
-- a burning band, a bar of paste, a seam of wire, the page opened, or -- for the
-- one parent that leaves nothing on paper at all -- the page itself parting. It is
-- the compass's argument in a straight line: there a gesture that reached borrowed
-- a nib and its *ring* became a mark, here a gesture that spans borrowed one and
-- its *reach* did.
--
-- **Every one of them is the whole page**, which is the ruler's own finale doing
-- the work rather than a decision taken seven times. "IT RULES THE WHOLE PAGE END
-- TO END" is half a screen diagonal, the only number in the game measured off the
-- window, so a finished ruler already lands corner to corner and a fusion built on
-- a finished ruler cannot land any other way. That is what makes the family read
-- as one idea from the strip: whatever this row is carrying, you are about to draw
-- it across the entire page, through yourself, in one press.
--
-- **And two of them do not shove**, which is the family's one real interaction and
-- is worth knowing before writing an eighth. A held body drops the push it was
-- carrying (`frozen` in Enemy:update), so a ruler that fastens is a ruler that does
-- not open anything: the TRENCH's paste and the SEAM's wire both catch what the
-- band caught and hold it exactly where it was standing. Which is the gluestick
-- and the stapler being themselves rather than a rule breaking -- neither has ever
-- shoved anything, and both rows say so.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Pin = require("src.pin")
local Staple = require("src.staple")
local util = require("src.util")

local Tools = {}

Tools.MIN_INK = 0.18  -- can't start a stroke below this
Tools.REGEN = 0.3     -- meter per second
Tools.DELAY = 0.25    -- pause before the meter starts refilling

-- Pencil: a 1px core roughened up with a second pixel alongside it, which is
-- what makes a straight line read as graphite instead of a vector.
local function pencilStamp(s, stroke)
    love.graphics.rectangle("fill", s.x, s.y, 1, 1)
    local r = util.hash01(s.i, stroke.seed, 11)
    if r > 0.55 then
        local a = util.hash01(s.i, stroke.seed, 12)
        love.graphics.rectangle("fill",
            s.x + (a < 0.5 and -1 or 1),
            s.y + (r > 0.8 and 1 or 0), 1, 1)
    end
end

-- Pressed harder: a 3px diamond core in place of the single pixel, roughened
-- the same way but throwing its stray pixel further out, for the upgrade that
-- broadens the point (the pencil's `broad` block below). Still procedural
-- rather than a sprite, because the grain is the tool.
local function pencilBroadStamp(s, stroke)
    love.graphics.rectangle("fill", s.x - 1, s.y, 3, 1)
    love.graphics.rectangle("fill", s.x, s.y - 1, 1, 3)
    local r = util.hash01(s.i, stroke.seed, 11)
    if r > 0.45 then
        local a = util.hash01(s.i, stroke.seed, 12)
        love.graphics.rectangle("fill",
            s.x + (a < 0.5 and -2 or 2),
            s.y + (r > 0.75 and 1 or -1), 1, 1)
    end
end

local function tipStamp(name)
    return function(s)
        Sprites.tips[name]:drawMask(s.x, s.y)
    end
end

local penStamp = tipStamp("pen")
local penWideStamp = tipStamp("penWide")
local crayonStamp = tipStamp("crayon")
local crayonEdge = tipStamp("crayonEdge")

-- A nib whose weight follows the pace of the hand (`pace` above, the SWELL): the
-- row's own nib and a thinner one, chosen per dab rather than per stroke. One
-- stamp function rather than two draw passes, because a dab is the only thing that
-- knows which nib laid it -- Stroke:draw walks the whole mark in a single pass and
-- has never had to care what any one stamp is.
local function pacedStamp(slow, fast)
    return function(s, stroke)
        if s.thin then fast(s, stroke) else slow(s, stroke) end
    end
end

-- Pinholes where the wax skipped the tooth of the paper. They are painted on
-- top of the band rather than left out of it: stamps are laid 2px apart and
-- are 13px across, so an omitted one is simply filled in by its neighbours --
-- a gap in a wide mark has to be drawn, not skipped.
local function crayonHoles(s, stroke)
    local function at(seed) return math.floor(util.hash01(s.i, stroke.seed, seed) * 9) - 4 end
    love.graphics.rectangle("fill", s.x + at(42), s.y + at(43), 1, 1)
    if util.hash01(s.i, stroke.seed, 44) > 0.55 then
        love.graphics.rectangle("fill", s.x + at(45), s.y + at(46), 1, 1)
    end
end
local markerStamp = tipStamp("marker")
local markerEdge = tipStamp("markerEdge")
local markerWideStamp = tipStamp("markerWide")
local markerWideEdge = tipStamp("markerWideEdge")
local glueStamp = tipStamp("glue")
local glueEdge = tipStamp("glueEdge")
local glueWideStamp = tipStamp("glueWide")
local glueWideEdge = tipStamp("glueWideEdge")
-- The one dab a pool is laid with (`pool` below, the TACK): the same paste at the
-- crater's own 25, which makes it the widest stamp in the game.
local gluePoolStamp = tipStamp("gluePool")
local gluePoolEdge = tipStamp("gluePoolEdge")

-- The finished PUSHPIN's `drop` block, and one table rather than three copies of
-- it because it is one tool: the three fusions at the foot of the list all eat the
-- same parent and not one of them moves a number in it. `radius` and `damage` are
-- the pushpin's own -- a 51px crater and 10, one short of a skull -- `freeze` and
-- `life` are its first level's pair, which are the same number written twice and
-- have to stay together, `point` is its third and `drive` its fourth.
--
-- Safe to share for the reason a `broad` block is: Tools.copy lifts every block
-- onto the run's own copy before a single upgrade level or multiplier sees it, so
-- what gets scaled is never this.
--
-- `sound` is written down rather than left to the icon, and it is not decoration:
-- Game:dropOne reads the block first and the tool's icon only after. Three rows
-- called something other than PUSHPIN still drive a pin through paper, and a
-- fusion that landed silent because its icon had a new name would be a bug with
-- nothing on screen to show for it.
local PIN = {
    lands = Pin, sound = "pin",
    radius = 25, damage = 10,
    freeze = 4, life = 4,
    point = 2, drive = 2,
}

-- How far apart two pins may be and still be joined (`thread` above), and one
-- table rather than five copies of the number: what a thread reaches is a fact
-- about the *gesture* and not about the nib on the end of it, so raising it raises
-- it for a graphite line, a fence, a burning band, a ruled diameter and a tear at
-- once. Which is what the field was for -- it is a table rather than a bare number
-- so that a row has somewhere to disagree, and so far none of them wants to.
--
-- **It was 50, then 80, and both were too tight.** 50 had a lovely argument -- a
-- finished pin punches 25 about the point, so two pins fifty apart are two craters
-- whose rims are exactly touching, which meant the tool drew its own range and no
-- guide was needed. It did not survive playing, and neither did the compromise
-- after it. Three taps inside a fifty-pixel circle is a shape you build by
-- accident or not at all: a pin costs half a meter and holds for four seconds, so
-- the second and third of them are placed in a hurry, and a range that small turns
-- every one of the five tools into a thing that mostly does not go off. A fusion
-- should not have a knack.
--
-- **120 is the number that stops it being one.** It is three eighths of the
-- narrowest page the game is ever drawn on, where 50 was a sixth and 80 a quarter,
-- and the difference is what a *triangle* costs: three pins pairwise inside 80
-- have to sit in a circle 46 across, which is a shape you have to plan, where at
-- 120 they sit in one 69 across and the shape is one you can simply mean. That
-- matters more than the reach itself, because four of the five threading tools are
-- only interesting closed -- DOT TO DOT cuts what it encloses, the STOCKADE is a
-- fence you want a corner in, and the CORDON is a band you want to walk somebody
-- into. A range that makes a straight line easy and a triangle hard is a range
-- aimed at the wrong half of the family.
--
-- What every step up costs is the arithmetic that used to draw the range for free:
-- the rims are seventy pixels apart at full stretch now, so there is a lot of
-- clear page between two pins that are still going to be joined. **So it is
-- drawn.** Every pin still holding shows a graphite ring at this radius, which is
-- the same pencil circle the pin already draws while it is falling, several sizes
-- up -- see the page pass in Game:draw. The ring is on the page for exactly as
-- long as the pin can still be linked, so it is the range and the clock in one
-- drawing, and a range you can see is worth more than an arithmetic coincidence
-- you cannot. At this radius the ring is also most of the reason the tool is
-- readable at all: 120 is far enough that two pins can be joined without looking
-- to a player as though they ought to be.
--
-- Shared and read-only for PIN's reason.
local THREAD = { reach = 120 }

-- The same field at the other end of its own range, and the three stapler fusions
-- at the foot of the list are what it is for (`thread` above). A seam lays a staple
-- every twelve pixels (`rake`), so a reach of fourteen joins each one to the one
-- before it and to nothing else: the mark follows the seam instead of latticing it.
--
-- **That is the difference between the two numbers said as a shape.** At 120 a
-- handful of taps is a *shape you build* -- a triangle, a Y, a spur off the fence
-- you laid ten seconds ago -- and every pair inside the reach gets a rail, which is
-- what the pushpin's family is. At 14 thirty presses are a *line you drag*, and the
-- rail is the seam itself. Same function, same code (Game:stringThreads), and the
-- only thing that changed is how far a post can see.
--
-- It also has to be under twice the spacing or the seam would lattice itself: at 25
-- every staple would rail to the one two along as well, and a fence would come out
-- doubled down its whole length. Fourteen leaves eleven pixels of slack under that
-- ceiling and two over the spacing, which is enough that a hand raking a curve
-- still joins up.
local LINK = { reach = 14 }

-- The finished STAPLER's `drop` block, and one table rather than four copies of it
-- for PIN's reason: it is one tool, and the rows that eat it whole do not move a
-- number in it. `damage` is its first level, `crit` its second, `prise` its third
-- and `rake` its fourth, over the written 7px circle and two-second hold.
--
-- `sound` is named here rather than left to the icon, and it is not decoration:
-- Game:dropOne reads the block first and the tool's icon only after, so a row called
-- PALING or WICK still drives a real staple through paper and is heard doing it.
-- Safe to share on PIN's terms -- Tools.copy lifts every block onto the run's own
-- copy before an upgrade level or a multiplier sees it, and `crit` and `rake` one
-- level further in are never written by anything.
local WIRE = {
    lands = Staple, sound = "stapler",
    radius = 7, damage = 6, freeze = 2, life = 2,
    crit = { chance = 0.2, mult = 3 },
    prise = true,
    rake = { every = 12 },
}

-- The finished RULER's `snap` block, and one table rather than eight copies of it
-- for PIN's reason: it is one tool, and not one of the eight rows that cast or
-- carry a ruler moves a number in it. 13 across and 165 either side are the third
-- level, 12 is the second, and the 210 shove and the ruled pencil line it leaves
-- are the row it was always written on. Shared and read-only on PIN's terms --
-- Tools.copy lifts every block onto the run's own copy before a single upgrade
-- level or multiplier sees it, so what gets scaled is never this, and so is what
-- the two rows that write into their own snap on the way past write into.
--
-- **`length` is written down, and that one field is the whole difference between
-- the two things a cast can mean.** `Ruler.cast` reads it where the FOLD leaves it
-- out: with it, two points *aim* the line and the reach is the tool's own, so the
-- ruler runs on past both of them to the corners of the page; without it, the two
-- points are the ends and the gap between them is the reach. Which is why the FOLD
-- is the one ruler in the catalogue that does not use this table -- a chord is as
-- long as the chord is, and a number here would be read by nothing and would say
-- something false about the tool to anybody reading the row.
--
-- The 165 is a placeholder for the run's own screen. Every line that unlocks one
-- of these overwrites it with half a diagonal every rebuild (`rulesThePage` in
-- src/upgrades.lua), which is the ruler's own finale and the only number in the
-- game measured off the window. Left at the third level rather than at nil so that
-- a row nobody has rebuilt yet still rules a real line, and at a number the tool
-- actually has rather than an invented one.
local RULE = {
    length = 165, width = 13,
    damage = 12, knock = 210,
    life = 1.6, fade = 0.55,
    ramp = { Palette.ink, Palette.slate, Palette.graphite },
}

Tools.list = {
    {
        name = "PENCIL",
        icon = "pencil",
        radius = 2, damage = 6, knock = 24,
        spacing = 1, ink = 1 / 230, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- The point the "pressed harder" level swaps in: same graphite, three
        -- pixels of it. Read-only and shared, like the highlighter's.
        broad = { radius = 4, stamp = pencilBroadStamp },
    },
    {
        name = "PEN",
        icon = "pen",
        -- The pen doesn't fight. Its line is solid to enemies -- they have to
        -- walk around it, and round the ends of it -- while the player crosses
        -- freely. It is a fence you can draw, and it lasts far longer than
        -- anything else, because a wall is only useful if it outlives the
        -- panic that made you draw it.
        --
        -- Its own line never takes that back. What the upgrades sell is the
        -- *fence*: a broader one, one the crowd pays for leaning on, one that
        -- comes off the page all at once when its time is up, and one that
        -- stays until you draw the next -- so a pen that has taken everything
        -- still shoves nothing and still holds the crowd off rather than going
        -- through it. `damage` and `knock` are written down at zero rather than
        -- left out, the scissors' rule: the row says up front what the line may
        -- do to it, and the shove is the one axis nothing here ever moves.
        radius = 2, damage = 0, knock = 0,
        wall = true,
        -- Round nib, one stamp per pixel: an even 3px line at any angle,
        -- against the pencil's deliberately ragged 1px.
        spacing = 1, ink = 1 / 170, life = 9,
        -- The nib trails the pointer slightly, which rolls hand jitter and the
        -- polygonal steps of a fast drag into the smooth curve a ballpoint
        -- actually leaves. Higher is tighter.
        smooth = 26,
        -- A wall you can't see is a trap, so the line holds full ink for most
        -- of its life and then goes visibly thin and pale in the last stretch:
        -- the fade is the warning that it is about to stop stopping anything.
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penStamp,
        -- The nib the "broader nib" level swaps in: the same ballpoint at
        -- twice the reach, 7px of blue instead of 3. Read-only and shared,
        -- like the pencil's and the highlighter's -- the level assigns these
        -- fields, it never writes into this block.
        --
        -- It buys more than a thicker line. `Walls:rebuild` files a segment at
        -- the tool's own radius and `Enemy:avoidWalls` clears it by that plus
        -- the body's own, so a broader nib holds the crowd further off the ink
        -- and rounds the ends of the fence wider -- and the whole line is
        -- still priced by the pixel of *path*, so the page it covers doubles
        -- for nothing.
        broad = { radius = 4, stamp = penWideStamp },
    },
    {
        name = "RUBBER",
        icon = "rubber",
        -- The one brush that puts nothing on the page. It used to sweep in
        -- paper, which really did wipe the ruling off -- but a pale shape lying
        -- there for a second afterwards reads as something smeared on rather
        -- than something rubbed off, which is to say it looked like the
        -- gluestick at half the size.
        --
        -- What a rubber actually leaves is crumbs, so crumbs are all this
        -- leaves: they come off the sides of the tip as it travels and they are
        -- gone before the stroke is. Nothing outlives the rub, hence a life of
        -- zero -- the mark is over the moment you let go.
        radius = 7, damage = 2, knock = 165,
        spacing = 2, ink = 1 / 150, life = 0,
        rehit = 0.3,
        crumbs = { chance = 0.7, color = Palette.graphite },
    },
    {
        name = "HIGHLIGHTER",
        icon = "marker",
        radius = 5, damage = 3, knock = 0,
        spacing = 2, ink = 1 / 120, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        -- Blue, like everything else the player puts on the page. It shares its
        -- two colours with the pen and is in no danger of being read as one: a
        -- pen line is 3px of solid blue you draw to keep something out, and this
        -- is an 11px sky band with the blue only where the ink pools at the rim,
        -- laid *under* the crowd rather than across it. Sky over the ruling
        -- comes out blue and blue comes out slate (Palette.overprint), so the
        -- band still darkens over a rule exactly as much as it did in blush.
        ramp = { Palette.sky },
        stamp = markerStamp,
        edge = { stamp = markerEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- The nib the "wider band" level swaps in: the same chisel two pixels
        -- fatter, with its own pooled-ink rim. Read-only and shared, like the
        -- stamps themselves -- the upgrade assigns these fields, it never
        -- writes into this block.
        broad = {
            radius = 7,
            stamp = markerWideStamp,
            edge = { stamp = markerWideEdge, color = Palette.blue },
        },
    },
    {
        name = "GLUESTICK",
        icon = "glue",
        -- Deliberately the eraser's look at exactly twice its radius. It deals
        -- no damage at all: the whole point is that anything caught in the smear
        -- stops dead for as long as the smear is on the page, which is a long
        -- time. Freeze is re-applied on every tick, so a stuck enemy stays
        -- stuck until the glue itself fades.
        radius = 14, damage = 0, knock = 0,
        -- Tight spacing relative to the fat tip, or the rim shows up as a row
        -- of overlapping arcs instead of one smooth edge.
        spacing = 2, ink = 1 / 90, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        ramp = { Palette.paper },
        stamp = glueStamp,
        edge = { stamp = glueEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        -- The head the "wider smear" level swaps in. 20 keeps the tool's
        -- written identity -- twice the rubber's radius -- true against a
        -- rubber that has taken its own wider level to 10.
        broad = {
            radius = 20,
            stamp = glueWideStamp,
            edge = { stamp = glueWideEdge, color = Palette.graphite, rough = 0.45 },
        },
    },
    {
        name = "PUSHPIN",
        icon = "pushpin",
        -- Not a brush: there is no line to draw, so nothing above applies. You
        -- tap and a pin falls on that spot.
        --
        -- The damage is deliberately one short of the toughest thing in the
        -- game (the skull's 12hp), which is the whole design in a number: a pin
        -- clears every blob and bat inside a 41px circle outright, and the tank
        -- is what walks out of the crater -- except that it doesn't walk, it is
        -- stuck to the paper. Kill it and it dies; survive it and you are
        -- pinned. Anything that killed outright would leave the pinning with
        -- nothing to pin.
        --
        -- The pin does not come out and does not fade: one driven through paper
        -- stays in it, looking the way it did going in, for the rest of the run.
        -- Which means the pin is not the timer on its own hold -- the enemy is,
        -- and always was the better place to read it, since a held enemy stops
        -- moving and grows a blue shadow.
        drop = { lands = Pin, radius = 20, damage = 10, freeze = 2.5, life = 2.5 },
        -- Charged per pin, not per pixel: two from a full meter, and about a
        -- second and a half of standing still to earn each one back. It is the
        -- biggest single thing you can do to the page, so it is priced like it.
        ink = 0.45,
    },
    {
        name = "STAPLER",
        icon = "stapler",
        -- Placed, exactly like the pushpin -- you tap and one lands where you
        -- tapped -- and the pin turned inside out in every other respect.
        --
        -- A pin is one big expensive decision: most of half the meter, a
        -- quarter of a second in the air, a 41px crater, and enough damage to
        -- kill everything caught in it but the tank. A staple is a tenth of the
        -- meter, it lands the instant you tap, it reaches 15px and it does 2,
        -- which is a bat and nothing else. It is not an attack, it is a
        -- fastener: it holds one thing to the paper for two seconds, and the
        -- way you use it is to keep tapping.
        --
        -- Ten from a full meter against the pin's two, so the same ink buys
        -- roughly the same page either way -- as one crater you place once, or
        -- as ten fastenings you have to land one at a time on things that are
        -- moving. That is the whole choice the pair offers.
        --
        -- Nothing is telegraphed, because there is nothing to dodge. The pin's
        -- fall is what stops a tap on a moving target being a certainty; a
        -- staple has no fall at all, and what keeps it honest instead is that
        -- hitting barely hurts and the circle is small enough to miss with.
        --
        -- Freeze and life are the same number on purpose, the way they are for
        -- the pin -- life is only how long it is still worth updating, since a
        -- staple never comes out of the paper and never fades. A page you have
        -- worked over stays covered in them -- one deep, since one driven where
        -- there is already one does its work and then leaves the drawing alone
        -- (`FOOTPRINT` in src/staple.lua, Game:dropCrowded), so a seam raked
        -- twice over the same ground reads as a seam and not as a stripe.
        --
        -- Which is the written tool, and its third level is the one place in the
        -- game that argument is bought back: `prise` makes life the clock on a
        -- fastening that is *undone* rather than one that simply stops being
        -- watched, and the same two seconds end with the wire torn out of the page
        -- for a second bite. A page worked over by that run stays clean.
        --
        -- Two of the paragraphs above are the *written* tool rather than the
        -- finished one, and its line is where each is bought back. "Hitting
        -- barely hurts" is true at 2 and stops being true at 6 with one hit in
        -- five going straight through -- the fastener becomes a fastener that
        -- also kills, which is what raising the first number in a row this cheap
        -- has to mean. And "ten of them is ten separate decisions" is true right
        -- up to the last level, which sells the decisions back as one gesture:
        -- `rake` makes the tap a drag. What survives all four is the price. Ten
        -- a meter is still ten a meter, so every staple in a seam is charged
        -- exactly what a tapped one was, and the page a full meter buys never
        -- changes -- only how many presses it takes to lay it.
        drop = { lands = Staple, radius = 7, damage = 2, freeze = 2, life = 2 },
        ink = 0.1,
    },
    {
        name = "RULER",
        icon = "ruler",
        -- Not a brush either, and not placed: aimed. It pivots about the player
        -- while you hold, and lands when you let go.
        --
        -- 200px long against a 15px band -- by a distance the longest reach in
        -- the game, and the narrowest. That is the trade the whole tool is: it
        -- can touch more of the page at once than anything else can, but only
        -- the part of it that happens to line up through you, and you have to
        -- stand there turning it until it does.
        --
        -- The knockback is what it is for. 8 damage clears the chaff, but it is
        -- the shove that matters: everything is thrown clear of the line and
        -- off both sides at once, so a ruler that kills nothing still opens a
        -- corridor across the page through the middle of the horde.
        snap = {
            length = 100, width = 7,
            damage = 8, knock = 210,
            -- The mark left behind is a ruled pencil line and leaves the page
            -- like one.
            life = 1.6, fade = 0.55,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- Cheaper than a pin, because it has to be lined up and the horde does
        -- not wait while you do it: about three from a full meter.
        ink = 0.35,
    },
    {
        name = "COMPASS",
        icon = "compass",
        -- Not a brush, not placed and not aimed: opened. The needle goes into
        -- the page where you press, and how far you drag out of that press is
        -- how wide the circle is. Let go and the leg comes round.
        --
        -- The slowest thing in the game to bring to bear, and the only one
        -- whose hit you can watch travel. Nothing lands on the release: the
        -- lead sets off from wherever you left it and cuts what it passes over
        -- as it arrives there, so the far side of a wide circle has most of a
        -- turn to walk out -- and can see the arm coming the whole way.
        --
        -- It is also the only tool that reaches away from the player, which is
        -- what it is really for: a circle drawn round a crowd you are not
        -- standing in. And what it cuts is that circle and not the middle of it
        -- -- the leg takes what is standing on the line it draws, so this is the
        -- one tool in the game that reaches a perimeter rather than an area, and
        -- the inside of a compass is the safest place on the page.
        --
        -- 7 damage is deliberately over the blob's 4 and under the skull's 12:
        -- the longest line in the game clears chaff and cannot touch a tank,
        -- where the pushpin takes a whole disc of page at once and kills
        -- everything in it but one. The two are the same trade read off either
        -- end -- a crater you drop on the crowd against a fence you draw round
        -- it -- which is why neither number moved when the fence stopped being a
        -- crater.
        --
        -- The knock is tangential rather than outward, so what the leg catches
        -- is dragged round the circle with it. A horde standing in one comes
        -- out of it stirred rather than scattered; scattering is the ruler's
        -- job, and a compass that did the same thing would be a round one.
        sweep = {
            minR = 16, maxR = 54,
            -- The scissors' number, for the scissors' reason: a lead is a point
            -- and the rim it rules is a pixel wide, so a body has to be genuinely
            -- standing on the line rather than near it. It is what stops a ring
            -- being a disc by the back door -- anything much wider and a small
            -- circle would close over its own middle again.
            width = 3,
            damage = 7, knock = 130,
            turn = 0.8,   -- seconds for a turn's worth of arm, however it is spent
            -- The three the upgrade line moves, written here at the values that
            -- mean "off" so the levels can read as one assignment each. What
            -- they buy is all measured in that one turn's worth: a lap and a
            -- half costs half again as long to land, and a second leg closes a
            -- lap in half the time because the two of them share it. The bite
            -- is the only part of the circle you get to aim, and it starts
            -- wherever you left the leg resting.
            laps = 1, bite = 1, biteArc = math.pi / 3, counter = false,
            -- What it leaves behind is a ruled pencil circle, and it goes off
            -- the page like one.
            life = 2.2, fade = 0.5,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- Between a ruler and a pin: two and a half from a full meter. It
        -- reaches further across the page than anything else and takes the
        -- longest to land, and both of those are in the price.
        ink = 0.4,
    },
    {
        name = "SCISSORS",
        icon = "scissors",
        -- Not a brush, not placed, not aimed and not opened: tapped twice. The
        -- first tap anchors the cut, the second says which way it runs, and the
        -- page comes apart along the line between them (src/scissors.lua).
        --
        -- It is the only thing on the strip that reaches anywhere at all. The
        -- ruler's line goes through you and the compass's circle is centred
        -- where you pressed, so both are really about where you are standing;
        -- a cut is two points on the paper and neither is anything to do with
        -- you. What pays for that is the gap between the taps -- the horde
        -- keeps walking through it, so the row of blobs the first tap lined up
        -- is not the row the second one cuts, and a cut has to be led.
        --
        -- 12 damage, which is the skull's whole health and one short of the
        -- eye's, is the pushpin's 10 pointed the other way: the pin is one
        -- short of killing the toughest thing in the crowd and clears a 41px
        -- crater doing it, and this kills the skull outright along a line
        -- nothing is standing on unless you put it there. `width` is the
        -- ruler's kind of number -- how far off the line a body's centre may be
        -- before its own radius stops reaching -- and at 3 against the ruler's
        -- 7 this is by a distance the narrowest thing in the game. A cut only
        -- takes a second body when the two are genuinely lined up.
        --
        -- The knock is 0 and written down rather than left out, on the pen's
        -- terms: not shoving is the point, and the shove is scaled by a
        -- multiplier (`scaleKnock` in src/loadout.lua), so it stays at 0
        -- whatever is ever written on that axis. It is also what keeps
        -- this from being a narrow ruler -- the ruler's shove is what opens a
        -- corridor, and a cut leaves the crowd exactly where it was standing.
        --
        -- `reach` is 128px, and it is the number the missing guide is paid for
        -- with. The whole cut used to be dotted out live between the two taps,
        -- so a short cap was a thing you could see the end of; nothing is drawn
        -- between them now (src/scissors.lua), and a cap you cannot see is one
        -- you find by having a cut stop short of the blob you meant it for.
        -- Twice the old 64 is most of a screen height -- far enough that the cap
        -- is rarely what a cut runs out of, and the first upgrade takes it off
        -- altogether.
        cut = {
            reach = 128, width = 3,
            damage = 12, knock = 0,
            -- The three the upgrade line adds, written here at nothing so the
            -- levels can read as one assignment each and so a tool's own
            -- header says what can happen to it -- the bomb's `burn = nil`,
            -- for the bomb's reason. They are built fresh on the run's copy
            -- every rebuild (src/loadout.lua), which is what makes them safe
            -- for `scaleDamage` to write into.
            blades = nil,     -- {damage, width} between the two taps
            through = false,  -- runs on past both taps to the page's edges
            sever = nil,      -- {tick} for the half it takes off, and
                              -- everything standing on it (Scissors:lift)
            -- What is left is the page opened: a dashed slit that closes back
            -- up over a second and a half, paper first and then a graphite
            -- crease. Paper is the one colour that wipes the ruling, which is
            -- why the slit reads as a slit -- see src/scissors.lua.
            life = 1.6, fade = 0.6,
            ramp = { Palette.paper, Palette.paper, Palette.graphite },
        },
        -- Three from a full meter, the ruler's price. It takes two decisions
        -- instead of one and cannot be dragged into a second cut, and the
        -- price is charged by the tap that opens the paper rather than by the
        -- one that anchors -- so an anchor you think better of costs nothing.
        ink = 0.3,
    },
    {
        name = "HALO",
        icon = "halo",
        -- The first fusion, and the first row here that is two shapes of tool at
        -- once: a brush *and* a sweep. Everything above is one or the other --
        -- the field presence is what Game:updateDrawing routes the press on --
        -- and this carries both sets, which is exactly what fusing a marker into
        -- a compass comes to. `sweep` wins the routing (it is tested first), so
        -- the gesture is the compass's to the letter: the needle goes in where
        -- you press, the drag opens the leg, letting go swings it. What the
        -- brush fields are for is the mark the leg leaves behind -- the leg is
        -- carrying a highlighter now, so instead of ruling a pencil circle it
        -- lays a band, and src/compass.lua drags a Stroke round behind each lead
        -- exactly as your own hand would drag one.
        --
        -- Which is the whole of what a fusion is meant to be: not a third set of
        -- numbers, but the two lines it is made of both still doing what they
        -- always did, in the same place at the same time. The numbers below are
        -- the marker's and the compass's *finished* lines copied across without
        -- a nudge -- the marker at its four levels (a 13px nib, 5 a tick, layers
        -- that stack, and the fire) and the compass at its four (opened out to
        -- 66, a double bite, twice round at 12, and the second leg) -- because a
        -- fusion is only offered once both of those lines are finished
        -- (`needs` in src/upgrades.lua). There is nothing here to tune that is
        -- not already tuned somewhere else, and that is deliberate: the day the
        -- marker's fourth level changes, this changes with it.
        --
        -- It is the strongest thing on the strip and it is meant to be. It costs
        -- ten levels across two lines, and what it hands back is one of the four
        -- places on the strip (`fuses`) -- so the run that reaches it is a run
        -- that spent most of its draft on two tools and gets a third place to
        -- put something else.
        radius = 7, damage = 5, knock = 0,
        spacing = 2, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true, stack = 3,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- Written here at nothing and built by the line's own first level
        -- (src/upgrades.lua), which is not a stylistic choice: `scaleDamage`
        -- *writes into* this table, and Tools.copy only copies the row and its
        -- blocks one level deep. A table the sharpener reaches has to be built
        -- fresh on the run's copy every rebuild or the multiplier compounds into
        -- the shared row -- which is why every other one in the catalogue (the
        -- marker's own ignite, the rubber's ram, the pencil's loop) is assigned
        -- by a level and never written down on a row.
        ignite = nil,
        sweep = {
            minR = 16, maxR = 66,
            -- The band's own radius exactly, where the compass rules 3. The leg
            -- is carrying a 13px nib rather than a lead, so what it cuts and what
            -- it paints are the same stretch of page to the pixel: the ring
            -- burns everywhere it bit and bit everywhere it burns. A fused tool
            -- inheriting one parent's number from the other parent's body is what
            -- fusing is meant to look like.
            width = 7,
            damage = 12, knock = 130,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- No `life`, `fade` or `ramp`, and their absence is the load-bearing
            -- part of this block. Those three are how a *pencil* circle leaves
            -- the page, and this leg is not carrying a pencil: the band is the
            -- mark now, it ages off the page on the brush fields above like
            -- every other band in the game, and a compass with a band draws no
            -- ring of its own at all (src/compass.lua). Writing them anyway
            -- would be three numbers nothing reads.
        },
        -- Half a meter: more than the compass's 0.4, because a swing now leaves
        -- a burning ring on the page as well as cutting one, and less than the
        -- 0.85 the two tools cost cast one after the other -- which is the trade
        -- the fusion makes. Two from a full meter, the pushpin's rate.
        ink = 0.5,
    },
    {
        name = "LASSO",
        icon = "lasso",
        -- The second fusion, and the same shape as the first: a brush and a
        -- sweep at once, the sweep winning the routing, the brush being what the
        -- leg draws with. What is in the leg this time is the pencil at the end
        -- of its own line -- a broadened point that scratches at 9 and closes a
        -- ring on whatever it surrounds -- so the gesture is the compass's to
        -- the letter and what comes round is a graphite circle that takes the
        -- middle of itself.
        --
        -- Which is the one thing a compass has never been able to do, and the
        -- reason this pair is a pair at all. A compass cuts the line it draws and
        -- never the middle of it: the inside of one is the safest place on the
        -- page, and three of the compass's four levels are written against that
        -- fact (see the sweep block in the COMPASS row above). The pencil's
        -- finale is the other half of the same idea from the other end -- close a
        -- line on itself and everything inside is cut -- and it is cheap because
        -- you have to draw the ring by hand, badly, around a crowd that is
        -- walking. Put the two together and the ring is drawn *for* you, perfect,
        -- at whatever width you dragged, around a crowd you are nowhere near.
        -- The fence becomes a net.
        --
        -- Every number below is a finished parent's, copied across without a
        -- nudge, exactly as the halo's are: the pencil at its four (9 damage and
        -- the broad point) and the compass at its four (opened out to 66, a
        -- double bite, twice round at 12, and the second leg). The one thing that
        -- is *not* copied is the pencil's `flow`, and that is the halo's rule
        -- about unread numbers rather than a nudge: `flow` prices a line by how
        -- far your finger has dragged it, and nothing here is dragged -- the
        -- whole price is paid at the needle and the arm draws on a budget of
        -- `math.huge` (Compass:layBands). A number nothing reads is worse than a
        -- number left out.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- Written here at nothing and built by the line's own first level
        -- (src/upgrades.lua), for the halo's `ignite` reason: `scaleDamage`
        -- writes into this table and Tools.copy is one level deep, so a table the
        -- sharpener reaches has to be built fresh on the run's copy every rebuild
        -- or the multiplier compounds into the shared row.
        loop = nil,
        sweep = {
            minR = 16, maxR = 66,
            -- The broad point's own radius, where the compass rules 3 and the
            -- halo rules 7 -- and it is the halo's rule, not a new one: the rim a
            -- sweep cuts is as wide as whatever the leg is carrying. A pressed
            -- pencil is three pixels of graphite against a chisel's thirteen, so
            -- the ring this rules is a thin one and the tool's reach is inwards
            -- rather than along the line.
            width = 4,
            damage = 12, knock = 130,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- No `life`, `fade` or `ramp`, for the halo's reason: those three are
            -- how a compass's *own* pencil circle leaves the page, and this leg
            -- is drawing a real mark instead. The ring is a Stroke in the run's
            -- list and ages off on the brush fields above -- which for a pencil
            -- is the same ramp and nearly the same second, so nothing is lost by
            -- letting the mark own it.
        },
        -- Under the halo's 0.5 and over the compass's 0.4. A swing still leaves a
        -- ring on the page and now cuts the inside of it, so it is worth more than
        -- a bare compass; graphite is the cheapest ink in the game (1/230 against
        -- the marker's 1/120), so the ring it leaves is worth less than a band.
        -- Two and a bit from a full meter.
        ink = 0.45,
    },
    {
        name = "MOAT",
        icon = "moat",
        -- The third fusion, and the one the other two make obvious: the compass
        -- again, with the gluestick in the leg. Same shape as the first two -- a
        -- brush and a sweep on one row, the sweep winning the routing, the brush
        -- being what the leg draws with -- and the widest mark in the game by a
        -- long way, because what is loaded into the leg is a 41px head of paste.
        --
        -- What it does is what the glue has always done, in a place the glue
        -- could never reach. A smear is the strongest crowd control in the game
        -- and the hardest to deliver: it stops everything it touches dead for as
        -- long as it is on the page, it makes what it holds take deeper cuts, it
        -- tears whatever comes loose off it, and it drags the free towards the
        -- ink -- and every one of those is worth nothing unless the paste is
        -- under the crowd, which means dragging your own hand through the crowd
        -- to put it there. The compass is the one tool that reaches away from
        -- you. So the ring is laid where you are not, round a crowd you are
        -- nowhere near, and it holds.
        --
        -- Nothing below is new. The freeze, the softening, the tear and the pull
        -- are the gluestick's finished line copied across, and they are read
        -- exactly where they have always been read: `Stroke:apply` freezes,
        -- `Enemy:freeze` hangs this tool off the body it caught, `Enemy:hurt`
        -- softens off `glue.soften`, and Game:updateGlue tears and pulls. Not a
        -- line of that knows a compass drew it, which is the whole of what a
        -- fusion is.
        --
        -- **And the drag now picks between two tools.** `width` is 20 -- the
        -- head's own radius, on the halo's rule -- against a `minR` of 16, so
        -- opened at the minimum the ring closes over its own middle and what
        -- lands is a filled plug of paste 36px across; opened out to 66 the same
        -- ring is a 40px-thick wall with clear page inside it. That is the one
        -- genuinely new decision in any of the three fusions, and it comes out of
        -- copied numbers rather than being written: a plug you drop on the crowd
        -- or a wall you draw round it.
        radius = 20, damage = 0, knock = 0,
        spacing = 2, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        -- The gluestick's upper three, and all three are safe to write on a
        -- shared row where the halo's `ignite` and the lasso's `loop` were not:
        -- `soften` is read and never written, `tear` is a bare number so the
        -- sharpener multiplies the run's copy of it rather than a table inside
        -- it, and nothing anywhere writes into `pull`. Which makes this the first
        -- fusion whose unlock level has nothing to apply -- see `fusionLine` in
        -- src/upgrades.lua for why the other two do.
        soften = 1.5,
        tear = 4,
        pull = { range = 26, speed = 30 },
        ramp = { Palette.paper },
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        sweep = {
            minR = 16, maxR = 66,
            -- The loaded head's own radius, where the compass rules 3, the lasso
            -- 4 and the halo 7. It is the same rule every time -- the rim a sweep
            -- cuts is as wide as whatever the leg is carrying -- and this is the
            -- one tool it takes past `minR`, which is a case Compass:cut used to
            -- be able to say could not happen. The comment there says what
            -- happens now instead.
            width = 20,
            -- The compass's arm, unchanged, and the one place the two parents
            -- genuinely disagree. The gluestick deals nothing and shoves nothing
            -- because that is what a gluestick is; the compass's leg has always
            -- cut 12 and dragged what it caught round the circle with it. Both
            -- are kept, because they are answers to two different questions: the
            -- brush fields above are what the *mark* does, and these are what the
            -- *arm* does on its way past. So the leg stirs the crowd it cuts and
            -- the paste it just laid sets them where the stir left them -- a shove
            -- is dropped the moment a body is glued (Enemy:update), so the two
            -- land in that order and never fight.
            damage = 12, knock = 130,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- No `life`, `fade` or `ramp`, for the halo's and the lasso's reason:
            -- the mark is the ring and ages off the page on the brush fields
            -- above, which here is the longest life of any mark in the game.
        },
        -- The dearest single use in the game -- over the halo's 0.5, the pushpin's
        -- 0.45 and the compass's 0.4 -- and it should be, on three counts: glue is
        -- the most expensive ink there is per pixel (1/90 against the marker's
        -- 1/120), the mark it leaves lives longest (6s against the band's 3.6),
        -- and it covers more page than anything else in the game. It is also the
        -- one fusion where the honest comparison is not "what the two tools cost
        -- cast one after the other": a full meter of gluestick draws ninety pixels
        -- of smear, and this lays eight hundred. What the fusion sells is not a
        -- discount, it is a mark no meter could ever have paid for.
        ink = 0.6,
    },
    {
        name = "PUNCH",
        icon = "punch",
        -- The fourth fusion, and the first one that is *not* a brush and a block
        -- at once. There are no brush fields on this row at all, because what is
        -- in the leg is a pair of blades and blades put nothing on the page --
        -- they take page away. So the arm draws no Stroke (Compass:swing needs a
        -- `stamp` to open one), the compass rules the ring itself exactly as a
        -- bare pencil one does, and everything different about this row is inside
        -- the one block it has.
        --
        -- A hole punch, which is the piece of stationery whose entire job is
        -- removing a circle of paper, and the two parents come to it from
        -- opposite ends. The scissors are the one tool that reaches anywhere and
        -- the one whose last level writes into the *page* rather than onto it: a
        -- cut runs edge to edge and the half you are not standing on lifts off.
        -- What it cannot do is choose a shape -- a cut is a straight line, so the
        -- only region it can take is a half-plane, and half a page is a great deal
        -- of page. The compass is the one tool that draws a closed line. Put the
        -- blades in the leg and the offcut stops being half the paper and becomes
        -- a disc you sized with the drag.
        --
        -- **Two numbers the parents already agree on**, which is the clearest
        -- sign yet that a fusion is the right pair. `width` is 3 on both, and the
        -- compass's own block says why in as many words -- it took the scissors'
        -- number for the scissors' reason, because a lead is a point and a blade
        -- is an edge and neither reaches off the line it rules. `damage` is 12 on
        -- both, arrived at twice from opposite arguments: the scissors' 12 is the
        -- skull's whole health along a line nothing is standing on unless you put
        -- it there, and the compass's 12 came from the level that stopped the
        -- longest line in the game being unable to touch a tank. There was nothing
        -- to reconcile.
        --
        -- **And one they do not**, which is `knock`, and the scissors win it. The
        -- compass's leg drags what it catches round the circle with it (130,
        -- tangential) because a lead *drags*; a blade separates, and the scissors'
        -- 0 is written down rather than left out precisely so that no multiplier
        -- can ever move it (see the SCISSORS row above). Keeping the compass's
        -- shove here would also fight the tool's own point: what the ring takes is
        -- decided by where bodies are *standing* when it closes, and shoving them
        -- out of the disc first is the one thing that could stop it mattering.
        --
        -- What is left out is the scissors' `blades` -- deeper and wider over the
        -- stretch between the two taps. Half of it is already here under another
        -- name: `bite` is the same idea and the scissors' own comment says so, so
        -- the aimed arc is worth double exactly as the aimed stretch of a cut is.
        -- The other half, the aimed stretch being *wider*, has no field on a
        -- sweep to land in -- and inventing one would be the lasso's `flow` in
        -- reverse, a number written down for nothing to read. It is named here
        -- because it is the one thing a future level could pick up.
        sweep = {
            minR = 16, maxR = 66,
            width = 3,
            damage = 12, knock = 0,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- Written on the row rather than built by the line's first level,
            -- which the halo's `ignite` rule would otherwise forbid -- and it is
            -- allowed here because there is no longer a number in it for the
            -- sharpener to compound. A severed region does no damage at all now:
            -- what it holds is carried off the page and set down in the far corner
            -- of it, not hurt, so `sever` is a clock and nothing else,
            -- `scaleDamage` has no reason to reach it and
            -- the fused line needs no `apply` (src/upgrades.lua). Half a second,
            -- the scissors' own tick, and it is a tick rather than one pass
            -- because the hole goes on being a hole for whatever walks in.
            sever = { tick = 0.5 },
            -- The one fused row that keeps `life`, `fade` and `ramp` on its
            -- block, and for the same reason the other three drop them: the block
            -- owns the ring only when nothing else is drawing it. There is no
            -- Stroke here, so the compass draws the rim itself -- and what it
            -- draws is the scissors' slit rather than a pencil circle. Paper
            -- first, because paper is the one colour that wipes the ruling
            -- instead of stacking with it, so the page really does stop at the
            -- line; then a graphite crease; then closed. See Compass:drawRim for
            -- the dashes and the lifting edge.
            life = 1.6, fade = 0.6,
            ramp = { Palette.paper, Palette.paper, Palette.graphite },
        },
        -- The compass's own price to the pixel, and the only fusion that costs
        -- exactly what one parent did. There is nothing to charge for: the other
        -- three all pay for a mark the arm leaves lying on the page -- a band, a
        -- graphite ring, a smear -- and blades leave no ink at all. A cut is the
        -- page opened, the scissors are the cheapest single use on the strip for
        -- that reason (0.3), and a compass carrying them spends its meter on
        -- exactly what a compass always spent it on: the needle going in.
        ink = 0.4,
    },
    {
        name = "SPINDLE",
        icon = "spindle",
        -- The fifth fusion, and the first row in the game that carries *two
        -- blocks*. Everything about that is the halo's arrangement one storey up:
        -- the block tested first is the gesture (`sweep`, in Game:updateDrawing)
        -- and everything else on the row is what the arm is carrying. Three
        -- fusions put a nib on the leg and got a mark; the punch put a blade on it
        -- and got an opening; this puts a whole *tapped tool* on it, and what a
        -- compass leg carrying a pushpin does is what a pushpin has always done,
        -- moving.
        --
        -- So the pin's crater is dragged rather than dropped. It sweeps the rim at
        -- the crater's own width, punching out the chaff the whole way round --
        -- and at the smallest circle it closes over its own middle, which is the
        -- moat's arithmetic again: a 25px point against a 16px circle is a plug,
        -- and opened out to 66 it is a 50px-thick wall of holes with clear page
        -- inside.
        --
        -- **And then the finale, which is the pushpin's own and had nowhere to
        -- happen until now.** The pushpin is not really the crater; it is the
        -- thing that walks out of the crater and is stuck to the paper instead.
        -- What this adds is the turn in between: the point picks up the first body
        -- it fails to kill, carries it round the circle impaled on the lead, and
        -- drives a real pin through it into the page where the arm stops. The two
        -- halves of the pushpin -- the crater and the pinning -- are separated by
        -- the one thing the compass has that nothing else does, which is a hit you
        -- can watch travel. See Compass:pickUp, Compass:haul and Compass:nail.
        --
        -- **10 damage, and it is the sharpest number choice in any of the five.**
        -- Both parents have written one down and they disagree: the compass cuts
        -- 12, which is the skull's whole health, and the pin punches 10, which is
        -- deliberately one short of it. The pushpin's own row argues for its own
        -- number better than anything here could -- "anything that killed outright
        -- would leave the pinning with nothing to pin" -- and that sentence is
        -- this tool's whole design, so 10 wins. A fused row taking the *weaker* of
        -- two numbers because the stronger one would delete its finale is the
        -- clearest case yet that these are copied rather than chosen.
        --
        -- The shove stays the compass's 130, where the pushpin's block has no
        -- knock at all, and the split is the same one the moat makes: the drop
        -- block is what goes into the page and the sweep is what the arm does on
        -- the way past. A landed pin is not going anywhere, which is why the
        -- pushpin never needed the field; a pin on the end of a moving arm drags
        -- what it catches round the circle with it, which is what the compass's
        -- knock has always been -- and this is the one tool where it stops being a
        -- figure of speech for one body and stays one for everybody else.
        sweep = {
            minR = 16, maxR = 66,
            -- The crater's own radius, on the halo's rule: the rim is as wide as
            -- whatever the leg is carrying. This is the widest point in the game
            -- swung on the longest arm in it.
            width = 25,
            damage = 10, knock = 130,
            turn = 0.8,
            -- `bite` is doing double duty and it is not a coincidence: the
            -- pushpin's third level is *written down* in src/upgrades.lua as "the
            -- compass's bite fallen from above", so the point biting double what
            -- it falls on and the lead biting double where it sets off are one
            -- level that two lines each bought a copy of. 20 over the arc you
            -- aimed kills a skull or an eye outright, exactly as the pushpin's
            -- point does, and the rest of the rim still cannot -- which is the
            -- pushpin's balance restated on a circle.
            bite = 2, biteArc = math.pi / 3,
            laps = 2, counter = true,
            -- The pushpin's finale, and it needed a travelling crater to make
            -- sense of. On the pin it is one instantaneous area hit, so a crowd
            -- converts into depth once; here the point gets heavier *as it goes*,
            -- and what it has already killed this lap is weight behind what it
            -- reaches next. Reset with the lap, for the reason the hit list is:
            -- a lap is the unit a compass measures everything in, and an
            -- unbounded counter over a rim that sweeps most of the page would be
            -- a number with no argument behind it.
            drive = 2,
            -- What it rules is a pencil circle, as a bare compass does, because a
            -- pin is not a nib and leaves no line -- what it leaves is holes and
            -- the guide the arm followed.
            life = 2.2, fade = 0.5,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- What is on the end of the arm, and it is a real `drop` block rather than
        -- three loose fields for a reason worth keeping: `drop` is in Tools.BLOCKS,
        -- so `scaleDamage` and `scalePersistence` already know how to reach into
        -- it -- the sharpener finds the numbers it should and the fixative
        -- stretches the hold, with nothing added to either walk. `lands` is the
        -- module that goes into the page (src/pin.lua) exactly as it is on the
        -- pushpin's own row, and `freeze` and `life` are the pushpin's finished
        -- pair, which are the same number written twice and have to stay together.
        --
        -- No `radius` and no `damage`, and both absences are the lasso's `flow`
        -- rule: the crater's width is read off `sweep.width` above and the point's
        -- damage off `sweep.damage`, because it is the *rim* that punches holes
        -- here. This pin arrives already through the paper and never lands a
        -- crater of its own (`driven` in src/pin.lua), so a second copy of either
        -- number would be a number nothing reads.
        --
        -- `sprite` is what the leg is *seen* carrying, and it is a name rather
        -- than the sprite itself because every sprite in the game is built at
        -- load (`Sprites.load`) and this row is written long before that: it is
        -- the same late lookup `icon` already is, one table along. Compass:drawLeg
        -- draws it at the lead in place of the ink square every other leg ends
        -- in, so what comes round the circle is the pushpin itself -- and the pin
        -- left standing in the page when the arm stops is that same drawing, one
        -- frame later and one list earlier in the same pass (Compass:nail,
        -- Game:driveDrop). A tool whose whole finale is "watch this thing travel,
        -- then watch it land" cannot have the travelling half drawn as a dot.
        drop = { lands = Pin, sprite = "pin", sound = "pin", freeze = 4, life = 4 },
        -- Over the halo's 0.5 and under the moat's 0.6, and this is the one fusion
        -- since the halo where the usual comparison genuinely works: both parents
        -- charge per use, so the 0.85 they cost cast one after the other is a real
        -- number, and 0.55 against it is the trade the fusion makes. The pushpin
        -- is the second-dearest single use on the strip because one tap is one
        -- crater; this is that crater dragged twice round a circle, and what it
        -- leaves behind is the only thing in the game that never comes off the
        -- page.
        ink = 0.55,
    },
    {
        name = "CORRAL",
        icon = "corral",
        -- The sixth fusion, and the first one whose leg is carrying something
        -- that is not a weapon. Five fusions put a nib, a blade or a point on
        -- the end of the arm and the ring they leave is an attack of some shape;
        -- this puts a *pen* there, and what a pen leaves is not a mark on the
        -- page so much as a change to the page: a line the crowd cannot cross.
        -- So the circle stops being something that happens to the horde and
        -- becomes somewhere the horde is -- inside it or outside it, and it does
        -- not get to choose which afterwards.
        --
        -- Which is the whole of why these two are a pair. The pen is terrain and
        -- terrain is only worth anything where the fight is; a fence you draw is
        -- drawn by dragging your own hand along the line you want it on, which
        -- for a run means walking the length of the wall it wanted through the
        -- crowd it wanted it against. Worse than that, the pen's line is *open*.
        -- A fence with two ends is a fence the crowd walks round -- Enemy:avoidWalls
        -- rounds the ends of one deliberately -- so the tool has never once been
        -- able to enclose anything. The compass is the only tool that reaches away
        -- from you and the only one that draws a **closed** line. Put the pen in
        -- the leg and both of the pen's limits go at once: the wall is laid where
        -- you are not, and it has no ends.
        --
        -- The name is the joke and the joke is the tool: a pen is what a closed
        -- fence is called when there is something inside it.
        --
        -- Every number below is a finished parent's, exactly as the other five
        -- are. The pen at its four -- the broad nib, the line that stings what
        -- leans on it, the pop when it goes, and the last line staying until you
        -- draw another -- and the compass at its four: out to 66, a double bite,
        -- twice round, and the second leg.
        radius = 4, damage = 1, knock = 0,
        -- What makes it terrain, and it is one field, because the fence is not a
        -- property of the pen: it is a property of any mark that says `wall`. So
        -- `Walls:rebuild` files this ring's path exactly as it files a line you
        -- drew, at the nib's own radius, and the crowd walks round it without
        -- being told anything about compasses. The one thing that did have to be
        -- said is *when* -- the index rebuilds only when it is dirty and nothing
        -- was dirtying it for a mark no hand was drawing. See Compass:layBands.
        wall = true,
        spacing = 1, life = 9,
        -- The pen's second level: a point of damage to whatever is pressed
        -- against the ink, twice a second, with two pixels of slack because
        -- Enemy:resolveWalls parks a body at exactly the ink's edge and a tick
        -- measured at the radius alone lands on floating-point luck. It is the
        -- longest tick in the game to walk now (Stroke:lingerTick): a ring at
        -- full width is four hundred-odd path points per leg per lap, and a body
        -- leaning on the ink stops the walk at the first covering segment while
        -- one standing in the middle of the circle pays for all of it. Bounded by
        -- the box, twice a second, and the same shape of cost the pen's own line
        -- already carried -- the pen's row says so in as many words.
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        -- The pen's finale, and the one field on any fused row that changes what
        -- the *page* is rather than what a swing does: the last ring you drew has
        -- no clock on it at all. Swinging again is the whole of what lets one go,
        -- so a run cannot lattice the page shut with them, and what is released
        -- fades on its ordinary nine seconds and then pops. Held per *leg* rather
        -- than per swing, because a finished compass rules the circle as one mark
        -- for each of them -- Compass:swing hands both to Game:holdWalls, and half
        -- a ring held would be a fence with a hole in it.
        keep = true,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        -- Written here at nothing and built by the line's own unlock
        -- (src/upgrades.lua), which is the halo's `ignite` rule for the fourth
        -- time and is not optional: `scaleDamage` writes `pop.damage`, and
        -- Tools.copy is one level deep, so a `pop` written on this row would
        -- compound the sharpener into it every rebuild.
        pop = nil,
        -- And **the pen's `smooth` is not copied across**, which is the lasso's
        -- `flow` rule at its sharpest. A ballpoint nib trails the pointer by
        -- design -- it is what rolls hand jitter into a curve -- and there is no
        -- hand here: the lead runs the rim at 500 pixels a second at full width,
        -- so a nib chasing it at 26 would lag some twenty pixels behind and
        -- *inside* the arc, ruling a smaller spiral than the guide promised and
        -- stopping short of closing when the arm did. The other numbers left out
        -- of a fused row are numbers nothing would read; this is one that would
        -- be read and would lie.
        sweep = {
            minR = 16, maxR = 66,
            -- The broad nib's own radius, on the halo's rule -- the rim a sweep
            -- cuts is as wide as whatever the leg is carrying -- which here is
            -- the pencil's 4 arrived at from the other side: a ballpoint at twice
            -- its reach is 7px of blue, and the wall the crowd is held off is
            -- filed at this same number.
            width = 4,
            -- The compass's cut, and the pen's shove. Which is the moat's split
            -- read twice over: the brush fields above are what the *mark* does
            -- and these are what the *arm* does on its way past, so the leg goes
            -- on cutting 12 -- the pen's own line is written at 0 damage and its
            -- second level moves it to 1, so damage was never the axis the tool
            -- refused.
            --
            -- `knock` is, and it is the one place these two parents disagree. The
            -- pen's row writes its 0 down rather than leaving it out precisely so
            -- that no multiplier can move it -- the scissors' rule, and the
            -- scissors won the same argument on the PUNCH for the same reason.
            -- Here it is stronger than either: what a closed fence does is decide
            -- who is inside it, and a leg that dragged bodies tangentially round
            -- the rim as it laid the wall would be sweeping the crowd *across*
            -- the line it was drawing. The one tool whose point is where things
            -- are standing cannot be the tool that moves them first.
            damage = 12, knock = 0,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- No `life`, `fade` or `ramp`, for the halo's reason: those three are
            -- how a compass's own pencil circle leaves the page, and this leg is
            -- laying a real mark instead. The ring is a Stroke in the run's list,
            -- it is a wall for as long as it is on the page, and it leaves on the
            -- pen's nine seconds -- or does not leave at all, which is a thing no
            -- number on a sweep block could ever have said.
        },
        -- Over the halo's 0.5 and level with the spindle, under the moat's 0.6.
        -- Blue is dearer ink than graphite and cheaper than paste (1/170 against
        -- 1/230 and 1/90), and the mark outlives every other mark in the game by
        -- a factor of three before the finale takes the clock off it altogether.
        -- The moat's comparison is the honest one again rather than the sum of two
        -- prices: a full meter of pen draws a hundred and seventy pixels of fence,
        -- and one press of this lays eight hundred of it in a shape a hand cannot
        -- draw. What the fusion sells is not a discount.
        ink = 0.55,
    },
    {
        name = "HEM",
        icon = "hem",
        -- The seventh fusion, and the second row in the game with two blocks on
        -- it -- the SPINDLE's arrangement with the other reading of what a whole
        -- tapped tool on the end of an arm should do. That one is *carried*: the
        -- pushpin rides the lead all the way round and goes into the page once,
        -- where the arm stopped. This one **presses as it travels**. A stapler on
        -- the end of a moving arm is a stapler being worked, and what it leaves
        -- behind is not one fastening but a line of them -- which is a thing the
        -- stapler's own last level already has a name and a spacing for (`rake`,
        -- 12px, src/upgrades.lua). The arm rakes the seam instead of your finger,
        -- and a seam raked round a circle closes: a seam that meets itself is a
        -- hem, and a hem is what you get when the edge is fastened the whole way
        -- round.
        --
        -- Which is the pair's argument, and it is the corral's told with wire
        -- instead of ink. The stapler is the cheapest, most repetitive tool on the
        -- strip: ten a meter, one press each, every one of them aimed by hand at
        -- something that is moving, and the whole skill of it is landing a 15px
        -- circle on a body that will not stand still. Its finale sells the ten
        -- presses back as one gesture -- but a dragged seam is still a seam your
        -- own hand has to walk, in a straight-ish line, through the crowd you
        -- wanted it in front of. The compass is the only tool that reaches away
        -- from you and the only one that draws a closed line. So the seam is laid
        -- round a crowd you are nowhere near, evenly, at whatever width you
        -- dragged, and it has no ends for anything to walk round.
        --
        -- **And it is the first tool in the game whose price is decided by the
        -- drag.** Every other sweep costs one number: the needle goes in, the
        -- meter pays, and how far you open it afterwards is free. Here what the
        -- drag is buying is *staples* -- one every 12 pixels of rim, so a circle
        -- at the minimum holds eight and one opened right out holds thirty-four --
        -- and wire is the one thing on this row that cannot be free, because the
        -- stapler's whole line is written on the price staying what it was (see
        -- the STAPLER row above: "the page a full meter buys never changes"). So
        -- the row carries a second price, `sweep.per`, and the compass can only be
        -- opened as wide as the meter can still pay for -- see Game:sweepReach.
        -- Running out is not a failed cast: the leg simply stops opening, which is
        -- the tool telling you how much wire is left in it.
        --
        -- Everything else is a finished parent's, as every fused row's is: the
        -- stapler at its four (6 a press, one in five going straight through at
        -- 18, the wire torn back out two seconds later for a second bite, and the
        -- seam's 12px spacing) and the compass at its four (out to 66, a double
        -- bite, twice round, and the second leg).
        --
        -- `prise` is worth reading against what this row leaves behind, because a
        -- hem is the one place in the game where thirty-four staples come out at
        -- once: the ring holds the crowd it closed round for two seconds and then
        -- unfastens all of it, hitting the whole rim a second time. What it does
        -- not leave is the ring -- the guide fades like any pencil circle and the
        -- wire goes with it, so a page a hem was cast on is a page again.
        sweep = {
            minR = 16, maxR = 66,
            -- The staple's own bite radius, on the halo's rule: the rim a sweep
            -- cuts is as wide as whatever the leg is carrying. It is also exactly
            -- what makes the ring continuous -- the crowns are 12 apart and each
            -- reaches 7, so the circles just overlap, which is the stapler's own
            -- arithmetic for its seam and not a second decision.
            width = 7,
            -- The compass's cut and the compass's shove, both kept, which is the
            -- moat's split: the block below is what goes into the page and this is
            -- what the arm does on its way past. The two land in that order and
            -- never fight, for the moat's reason as well -- a shove is dropped the
            -- moment a body is held (Enemy:update), and the staple that lands on
            -- it holds it, so the leg stirs the crowd and the wire sets them where
            -- the stir left them.
            damage = 12, knock = 130,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- Ink per staple past the eight the smallest circle holds, which is
            -- the only field of its kind in the catalogue: `ink` below is a flat
            -- price paid at the needle like every other sweep's, and this is what
            -- the drag adds to it. A fifth of what a tapped staple costs, and the
            -- fifth is the aiming -- what you are no longer doing is landing a
            -- 15px circle on something that is moving, thirty-four times. What
            -- you are buying instead is thirty-four staples on a *line you chose*,
            -- and how many of them find a body is the whole of what the drag
            -- decides. A hem round nothing is a hem round nothing, at full price.
            per = 0.02,
            -- What it rules is a pencil circle, as a bare compass does and for the
            -- SPINDLE's reason: a stapler is not a nib and leaves no line. What it
            -- leaves is wire and the guide the arm followed.
            life = 2.2, fade = 0.5,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- What the leg is working, and it is the stapler's finished block itself --
        -- `WIRE` at the head of this file, shared with the three stapler fusions at
        -- the foot of it, because not one of the four moves a number in it. It was
        -- written out here first and hoisted the day there were four; nothing about
        -- the row changed, which is what a shared block is supposed to cost.
        --
        -- `rake` is the one field in it that has changed *reader* rather than value. Nothing routes on it any
        -- more (the gesture is the sweep, and Game:updateDrawing never reaches the
        -- drop branch on this row), so the seam is not dragged by a finger; the
        -- number it carries is read by Compass:loadSeam instead, and it means what
        -- it always meant -- how far apart along a path the presses go. A field
        -- that survives a fusion by being read from somewhere else is the clearest
        -- case there is for copying rather than choosing.
        --
        -- `rake` is also what tells this row apart from the SPINDLE's, and the
        -- distinction is field presence exactly as everything else here is: a leg
        -- whose drop can rake **presses as it travels**, and one whose cannot is
        -- **carrying** its drop and drives it in at the end (Compass:seams and
        -- Compass:carries). Two honest readings of a tapped tool on an arm, and
        -- the block says which without a flag having to be invented for it.
        --
        -- `sound` -- in the block, with the rest of it -- is what a press is
        -- *heard* as when something other than a tap places it, and it is a name for
        -- `sprite`'s reason: the row is written long before anything is loaded. See
        -- Game:driveDrop, and Compass:seams for why a seam is not heard thirty-four
        -- times a second.
        --
        -- No `sprite`: what the arm is carrying is a machine that presses rather
        -- than an object standing in the page, there is no 7x8 drawing of a
        -- stapler to put on the lead, and what you actually watch travel is the
        -- wire appearing behind it. So the leg ends in the lead every other leg
        -- ends in (Compass:drawLeg).
        drop = WIRE,
        -- The needle, and the eight staples the smallest circle holds. Which is
        -- the compass's own price to the pixel -- so the cheapest thing this tool
        -- can do costs exactly what a compass costs, and a full meter opens it all
        -- the way out for 0.92: 0.4 here and 0.52 of wire (see `per` above).
        -- Eight tapped staples would be 0.8 on their own.
        --
        -- It is charged on the press like every sweep's, because the needle going
        -- in is still the decision that cannot be taken back, and Game:sweepReach
        -- is what stops the drag promising wire the meter cannot pay for.
        ink = 0.4,
    },
    {
        name = "CLEARING",
        icon = "clearing",
        -- The eighth fusion, and the one that takes the compass's central fact
        -- away from it on purpose.
        --
        -- **What a compass cuts is the line it draws and never the middle of it.**
        -- Three of its four levels are written against that (see the COMPASS row
        -- above) and Compass:cut has a long comment about the day the middle *was*
        -- being taken -- the angle test was doing all the work, the leg swept the
        -- page like a radar wiper, and the tool was a delayed pushpin with a bigger
        -- crater. That was a bug. This row is the same geometry as a *feature*, and
        -- the reason it is allowed here is the whole of what the rubber is: a
        -- rubber's hit is not an edge, it is the patch it went over. You do not cut
        -- with one, you clear an area with one, and a rubber that only touched what
        -- was standing exactly on a line it ruled would not be a rubber at all.
        --
        -- So the leg wipes the disc as it comes round -- everything inside the
        -- circle it has swept past so far, thrown **straight out of it** and
        -- launched. Not round it: the compass's own knock drags what it catches
        -- along the rim (130, tangential) because a lead drags, and a rubber
        -- *shoves away from itself*. Away from the needle is the only direction a
        -- disc has, and it is what makes the tool a place being emptied rather than
        -- a crowd being stirred.
        --
        -- Which is a panic button, and the first one on the strip. Every other
        -- sweep is aimed at a crowd you are nowhere near -- that is what the
        -- compass is *for* -- and this is the one you plant on your own feet: the
        -- ring opens round you and the rank that had reached you goes over the
        -- horizon of it. Nothing dies (2 a body, 4 where the leg bites), so what it
        -- buys is time and never kills, which is exactly the trade the rubber has
        -- always made and the only reason it can be allowed to touch everything at
        -- once.
        --
        -- **Two of the rubber's four levels are deliberately not here**, which is
        -- more than any other fusion leaves behind, and both are the lasso's `flow`
        -- rule rather than a nudge: `lean` is a tip that keeps hitting while it
        -- *rests* and an arm never rests, and `scrub` is half price over ground the
        -- stroke has already covered and there is no per-pixel price to halve --
        -- the whole cost is paid at the needle. Both are about the wrist and the
        -- meter, and a sweep has neither. What does come across is the shove (240,
        -- the line's first level, and the number everything below it stands on) and
        -- the ram, which is the finale.
        sweep = {
            minR = 16, maxR = 66,
            -- The rubber's own tip, on the halo's rule: the reach a sweep has is
            -- as wide as whatever the leg is carrying. It is measured from the
            -- *disc* here rather than from the line -- out to the rim and this
            -- much past it -- but it means exactly what it means everywhere else,
            -- which is how far off the ink a body's centre may be before its own
            -- radius stops reaching. A tip 15 across clears a little past the
            -- circle it ruled, because it is 15 across.
            width = 7,
            -- The rubber's chip and the rubber's throw, both unchanged. 2 is what
            -- a rubber has always done and the one number its line never moved:
            -- the damage was always chip, the chip level was the one that went,
            -- and a rub that killed things would be a pencil that also shoved. 240
            -- is a 27px throw (the push decays at exp(-9t), so distance is
            -- force/9), and it is the number the ram below is timed against.
            damage = 2, knock = 240,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- The disc rather than the band, and the one field in the catalogue
            -- that changes what a block *reaches* instead of by how much. See
            -- Compass:cut, which grew one branch for it and shoves outward instead
            -- of along wherever it is set.
            --
            -- It also costs the compass's third level most of its argument, and
            -- that is worth being straight about: "twice round, cutting far
            -- deeper" is 12 on the parent and stays 2 here, so what a second lap
            -- buys this tool is a second wipe of whatever walked back in rather
            -- than a deeper cut. The other three levels are untouched -- wider is
            -- more page emptied, the bite is still the arc you aimed, and the
            -- second leg still halves the wait.
            wipe = true,
            -- **A rub leaves nothing**, which is the rubber's own `life = 0` and
            -- the only zero of its kind in the catalogue: the mark is over the
            -- moment you let go. So there is no ring left behind and no fade to
            -- write -- the graphite circle you see is the path the arm is on,
            -- ruled as it goes and gone with the arm (Compass:drawGuide returns
            -- early on a life of nothing, and Compass:update drops the object on
            -- the frame after the turn closes).
            --
            -- Graphite rather than the ink every other pencil ring is drawn in,
            -- for the same reason: what you are being shown is where the tip is
            -- travelling, not something being put on the paper. It is the colour
            -- the guide dashes were already in, so the line reads as the aiming
            -- being completed rather than as a mark going down.
            life = 0,
            ramp = { Palette.graphite },
        },
        -- The rubber's finale: anything this shove sends flying shoves and damages
        -- whatever it runs into while it is still truly flying (Game:updateRams).
        -- 5 is a blob dead on arrival, and the victims never become projectiles
        -- themselves -- one rub is one volley and not a chain -- which on a disc
        -- being emptied outwards means the inside rank is bowled through the
        -- outside one on its way past. It is the only damage this tool does that
        -- can kill anything, and it is dealt by the crowd to itself.
        --
        -- On the row rather than in the block, and that is the one placement
        -- decision here: `scaleDamage` reaches `tool.ram` by name and nothing walks
        -- into a table inside a block, so this is where the sharpener already
        -- looks. Which also means it must be built by the unlock's `apply` and not
        -- written down -- Tools.copy is one level deep, so a `ram` on the row would
        -- compound the multiplier into it every rebuild. It is the lasso's `loop`
        -- exactly, and Compass:cut reads it off the row the way Compass:ring reads
        -- that one.
        ram = nil,
        -- The compass's own price to the pixel, and the second fusion to cost
        -- exactly what one parent did -- for the punch's reason, which is the only
        -- reason that has ever justified it: there is nothing left on the page to
        -- charge for. The other five all pay for something the arm leaves lying
        -- there; blades leave no ink and a rubber leaves less than that. What the
        -- meter buys here is the needle going in, exactly as it always did.
        ink = 0.4,
    },
    {
        name = "FOLD",
        icon = "fold",
        -- The ninth fusion, and the only one where nothing goes in the leg.
        --
        -- Every other one is the compass wearing something: a nib, a blade, a
        -- point, a stapler, a rubber. Here the leg carries the bare lead it always
        -- did and rules the same pencil circle it always ruled -- the whole `sweep`
        -- block below is the finished COMPASS copied across without one number
        -- moved, which no other fused row can say. What was added is not on the
        -- instrument. It is on the **page**: draw a second circle while the first
        -- one is still lying there and, where the two rims cross, the ruler comes
        -- down flat on the line between the two crossings.
        --
        -- Which is the construction both of these instruments are in the pencil
        -- case for. Two arcs from two centres and a straight edge through where
        -- they meet is the first thing anybody is ever taught to do with a compass
        -- and a ruler together, and it is the only fusion in the game whose two
        -- halves were designed to be used together by somebody other than us.
        --
        -- **The first tool whose second half is a relationship between two marks.**
        -- Everything else on the strip is one gesture landing: a mark, a drop, a
        -- swing, and the page is whatever that left. A fold needs two swings and
        -- the *gap* between them to be short enough, and neither swing is worth
        -- anything on its own -- one circle rules nothing at all. That is also
        -- where the price is, and it is a price nothing else here charges: the
        -- meter is asked for the compass's plain 0.4 twice over, so a fold costs
        -- most of a full meter and two presses, and what it buys is one line.
        --
        -- **Fresh is the ring's own life and not a clock anybody invented.** A
        -- compass is on the page for as long as the circle it drew (2.2s past the
        -- arm stopping, and nothing in the draft stretches it), and the pairing
        -- window is exactly that: swing the second circle while you can still see
        -- the first. Nothing had to be written down for that to be the rule, which
        -- is the best thing about it -- the tool is legible off the paper rather
        -- than off a number, and a ring you can see fading is a timer.
        --
        -- **And the aiming is real, it is just indirect.** A ruler's line goes
        -- through you: that is the tool's whole limitation, and it means you can
        -- only ever choose which *way* the page gets swept and never where. This
        -- line goes nowhere near you. It sits square to the line joining the two
        -- needles, half way along it, and it is as long as the overlap is deep --
        -- two circles well over each other rule a long line and two grazing rule a
        -- short one. So both ends are placed by placing two needles, which is the
        -- one thing on the strip you aim by drawing something else twice.
        --
        -- That trade is where the ruler's finale went, and it is worth being plain
        -- about rather than quiet: "IT RULES THE WHOLE PAGE END TO END" is the one
        -- parent level here with nothing to land in, because how far this ruler
        -- reaches is not the tool's to decide. Two circles this compass draws can
        -- be 66 across at the widest, so the chord can never pass 132 -- two thirds
        -- of what a plain ruler covers and a third of what a finished one does. The
        -- reach is what was sold, and *position* is what was bought.
        sweep = {
            minR = 16, maxR = 66,
            -- A bare lead, and so the compass's own 3: this is the one fused rim
            -- that was not widened by whatever the leg is holding, because the leg
            -- is holding nothing.
            width = 3,
            damage = 12, knock = 130,
            turn = 0.8,
            laps = 2, bite = 2, biteArc = math.pi / 3, counter = true,
            -- The plain pencil circle, and here it is doing a second job: the ring
            -- is what the *next* circle will be paired against, so the fade is the
            -- window closing and the tool is read off the page.
            life = 2.2, fade = 0.5,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- The ruler, and the block is here to be *cast* rather than pressed for --
        -- the sweep wins the routing (Game:updateDrawing tests it first), so
        -- nothing can ever aim this one. `Compass:crease` is what lands it, once
        -- every time the circle closes, which is the lasso's rule for the lasso's
        -- reason: coming round again is the unit a compass measures everything in,
        -- and a finished line rules the chord twice half a turn apart.
        --
        -- Every number in it is the ruler's own finished line: 13 across from the
        -- third level, 12 from the second, and the 210 shove and the ruled pencil
        -- line it leaves from the row it was always written on. The shove is the
        -- whole point of a ruler and it is untouched -- everything within the band
        -- is thrown clear of the line and off *both* sides at once, so the fold
        -- opens a corridor exactly as the parent does, through a crowd nowhere near
        -- you.
        --
        -- `length` is deliberately not written down. It is the one field a cast
        -- ruler does not have an opinion about -- the chord is as long as the chord
        -- is -- and a number here would be read by nothing and would say something
        -- false about the tool to anybody reading the row. Ruler.new takes it as an
        -- argument for exactly this, which is the same courtesy the catalogue pays
        -- anywhere else it leaves a parent's field out (the LASSO's `flow`).
        snap = {
            width = 13,
            damage = 12, knock = 210,
            life = 1.6, fade = 0.55,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- The compass's own price, and the third fusion to cost exactly what one
        -- parent did -- but for a reason neither of the other two could use. The
        -- punch and the clearing charge one parent's price because there is nothing
        -- left on the page to charge for; this charges it because **it is charged
        -- twice**. A fold is two needles and 0.8 of a full meter before a single
        -- line is ruled, which is more than any other tool on the strip asks for
        -- one hit, and the ruler that arrives is free only in the sense that the
        -- second circle already paid for it.
        ink = 0.4,
    },
    {
        name = "DOT TO DOT",
        icon = "dots",
        -- The tenth fusion, and the first one in the catalogue that is not the
        -- compass. The paragraph at the top of this file argues the family out in
        -- full; the short of it is that a pin reaches away from you exactly as a
        -- compass leg does and has never had a line, so what this row does is put
        -- the pencil back in the hand that is dropping pins.
        --
        -- Nothing about the tap changes. It is the pushpin's tap, it falls for the
        -- pushpin's quarter of a second, it punches the pushpin's 51px crater and
        -- it pins what walks out. And then a second pin dropped within fifty
        -- pixels of the first is *joined* to it: a graphite line appears between
        -- the two, whole, on the frame the second one lands, and everything
        -- standing on it takes 9 (`thread` above, Game:stringThreads).
        --
        -- **Which is where the pencil's finale was always going.** Join three pins
        -- into a circuit and everything the circuit holds is cut -- "CLOSE THE
        -- LINE IN A LOOP: EVERYTHING INSIDE IS CUT", with the loop closed by taps
        -- instead of by a wrist. The parent's version is cheap and vague on
        -- purpose: the ring is yours to draw, badly, around a crowd that is
        -- walking away from you while you draw it. This one cannot be vague. The
        -- corners are pins, the pins are exactly where you tapped, and each corner
        -- punched a crater and pinned a tank on the way in -- so the shape is
        -- built out of three hits that were worth taking on their own, and the
        -- enclosure is what you get for having taken them in a triangle.
        --
        -- It is also the dearest way to close a ring in the game, and it should
        -- be. The LASSO buys the same level a perfect circle at reach for one
        -- press; this is three presses and a meter and a half, and the ring can be
        -- any shape at all -- four pins and five pins close too, and the circuit
        -- that gets cut is the tightest one the landing closed.
        --
        -- Every number is a finished parent's. The pencil at its four -- the broad
        -- point at 9, and the loop -- and the pushpin at its four, in PIN above.
        -- Where they look like they disagree they are not even talking about the
        -- same thing, which is the MOAT's split: `damage` is what the *mark* does
        -- to what stands on it and `drop.damage` is what goes into the *page*, so
        -- 9 along the thread and 10 under the point sit side by side exactly as
        -- they did on two separate rows.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- Written here at nothing and built by the line's own unlock
        -- (src/upgrades.lua), which is the HALO's rule and is not optional:
        -- `scaleDamage` writes `loop.damage`, and Tools.copy is one level deep, so
        -- a `loop` written on this row would compound the sharpener into it every
        -- rebuild.
        loop = nil,
        -- **The pencil's `flow` is not copied across**, and it is the LASSO's
        -- reason word for word: the price eases the longer the finger stays down,
        -- and no finger is down. Nothing here is charged by the pixel, so a floor
        -- and a distance to reach it are two numbers nothing in the game would
        -- ever read.
        thread = THREAD,
        drop = PIN,
        -- Half a meter, which is two taps and therefore exactly one thread.
        --
        -- The honest comparison is not the two prices added up, it is what a hand
        -- would have paid for the same page: a pin at 0.45 plus the hundred and
        -- twenty pixels of broad pencil the thread is, at 1/230 a pixel, is most of
        -- a full meter.
        -- So the fusion is a discount, and it is the same number on the two rows
        -- below for the reason the gesture is the same on all three -- what
        -- separates them is what the line *is*, not what laying it cost, and a
        -- hand laid none of it. Two from a full meter is also the pushpin's own
        -- count, unchanged, which is the thing to hold on to when reading the
        -- price: the second tap of the pair now comes with a line attached.
        ink = 0.5,
    },
    {
        name = "STOCKADE",
        icon = "stockade",
        -- The eleventh, and the second answer the pen has been given to the same
        -- question. The CORRAL's is a fence with no ends, ruled where your hand is
        -- not; this one is a fence you *build* -- posts driven one tap at a time
        -- and a rail strung between any two of them that are close enough.
        --
        -- Which is the pen's two limits taken off it from the other side. Its line
        -- goes where your hand goes, and its line is open, so the tool has never
        -- been able to enclose anything or to hold ground it was not standing on.
        -- A compass answers both at once by drawing a closed circle at reach. Pins
        -- answer them one tap at a time, and the difference between the two answers
        -- is the whole reason a run gets to pick: a corral is a shape the tool
        -- chooses and you place, and a stockade is a shape *you* choose -- a line
        -- across a corridor, a triangle round a spawn, a spur off the fence you
        -- laid ten seconds ago -- with a crater and a pinned tank at every corner.
        --
        -- And every post is worth dropping on its own, which no fence post has
        -- ever been. That is the fusion: a tool whose whole cost was walking the
        -- length of the wall it wanted now pays you a 51px crater for standing
        -- each end of it up.
        --
        -- Every number is a finished parent's. The pen at its four -- the broad
        -- nib, the line that stings what leans on it, the pop when it goes, and
        -- the clock coming off it -- and the pushpin at its four, in PIN above.
        radius = 4, damage = 1, knock = 0,
        -- One field, and it is the same one field it is on the CORRAL: the fence
        -- is not a property of the pen, it is a property of any mark that says
        -- `wall`. Walls:rebuild files a thread's path at the nib's own radius
        -- exactly as it files a line you drew, and the crowd walks round it
        -- without being told that anything was strung rather than drawn --
        -- Game:stringThreads dirties the index as it lays, which is the one thing
        -- nothing was doing for a mark no hand was drawing.
        wall = true,
        spacing = 1, life = 9,
        -- The pen's second level, unchanged and including the two pixels of slack:
        -- Enemy:resolveWalls parks a body at exactly the ink's edge, so a tick
        -- measured at the radius alone lands on floating-point luck.
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        -- Written at nothing and built by the unlock, the HALO's rule again:
        -- `scaleDamage` reaches `pop.damage`.
        pop = nil,
        -- **The pen's `keep` is not copied across, and it is the one parent level
        -- in the catalogue that a fused row already had.** `thread` holds every
        -- mark this tool lays for as long as both its posts are in the page --
        -- that is the field's own rule, on every row in the family, whether the
        -- pen bought it or not -- so writing `keep` here would be paying for something the
        -- row has, in a form that reads the wrong list: Game:holdWalls holds one
        -- gesture's worth of wall and lets the last one go every time a new one is
        -- laid, and a fence built pin by pin is not one gesture. It would drop
        -- every rail but the newest as you built the thing. What the level bought
        -- the pen is bought here by the posts, and it is bounded the way `keep` is
        -- bounded, by something better than a rule: a pin holds for four seconds,
        -- so the page cannot be latticed shut by a player who keeps tapping.
        --
        -- **And the pen's `smooth` has to go rather than merely being left out**,
        -- which is the CORRAL's sharpest paragraph and it applies harder here. A
        -- ballpoint nib trails the pointer by design -- it is what rolls hand
        -- jitter into a curve -- and a thread is laid whole between two fixed
        -- points in one frame. A nib chasing at 26 would cover a fraction of the
        -- gap and stop, so the rail would not reach the far post at all: not a
        -- number nothing reads, a number that would lie and take the fence with
        -- it.
        thread = THREAD,
        drop = PIN,
        -- Half a meter, on the row above's argument. A hand would have paid 0.45
        -- for the pin and a hundred and twenty pixels of blue at 1/170 for the rail,
        -- which is over a full meter -- and what a full meter buys here is two posts
        -- and the one rail between them, against the hundred and seventy pixels of
        -- open fence the pen draws for the same meter. So the fusion sells most of a
        -- pen's worth of wall
        -- and sells it closed, at reach, with a crater under each end. What a
        -- fusion sells is not a discount on pixels.
        ink = 0.5,
    },
    {
        name = "CORDON",
        icon = "cordon",
        -- The twelfth, and the marker's second answer as well. The HALO makes the
        -- rim of a circle worth standing on; this makes the *line between two
        -- pins* worth standing on, which is a worse shape and a better place --
        -- because you chose both ends of it.
        --
        -- The marker's band is the best ground in the game and the worst to place:
        -- it goes where your hand goes, which is to say where you are, and the
        -- crowd it is for is the crowd you are trying not to be standing in. That
        -- is the HALO's opening argument and it is this row's too. What differs is
        -- the shape the reach comes in. A halo is a ring you open out and swing
        -- once; a cordon is a strip you can lay across a doorway, or a Y, or a
        -- triangle with a burning edge and a crater at each corner -- and every
        -- corner of it was a tap that already killed the chaff standing there.
        --
        -- The name is what the tool is. A cordon is tape strung between two posts
        -- to say a stretch of ground is not to be crossed, and this one does not
        -- stop anybody: it is fifteen pixels of sky that burns 5 a tick to
        -- whatever stands on it and sets alight anything that so much as crosses
        -- it. The crowd may walk through. It is what walking through costs.
        --
        -- Every number is a finished parent's. The marker at its four -- the wider
        -- band, the deeper burn, and the fire -- and the pushpin at its four, in
        -- PIN above.
        radius = 7, damage = 5, knock = 0,
        spacing = 2, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- Written at nothing and built by the unlock, exactly as the HALO writes
        -- the same field for the same reason: `scaleDamage` reaches
        -- `ignite.damage`, and Tools.copy is one level deep.
        ignite = nil,
        -- **The marker's `stack` is not copied across.** Layers land where one
        -- stroke has passed back over its own ink, and a thread is a straight line
        -- between two pins: it never crosses itself, so the cap of three would
        -- never once be reached and Stroke:revisits would be walked for nothing.
        -- The LASSO's `flow` rule -- a number nothing here would read.
        --
        -- Two threads crossing is not that. They are two marks, they both tick,
        -- and where they cross the crowd takes both -- which is the level's payoff
        -- arriving through the tool's own geometry instead of through a field, and
        -- the reason a run drops pins in a lattice rather than in a line.
        thread = THREAD,
        drop = PIN,
        -- Half a meter, and this is the row where the discount is biggest of the
        -- five that string, because marker ink is the dearest of the nibs: a hand
        -- would have paid 0.45 for the pin and a hundred and twenty pixels at 1/120
        -- for the band, which is a meter and a half -- more than a run can hold. Still the same 0.5 as every other row in this family, for the
        -- reason given there -- the gesture is one gesture on all of them, and no
        -- hand laid any of the line.
        ink = 0.5,
    },
    {
        name = "SNAP LINE",
        icon = "snapline",
        -- The thirteenth fusion, and the first pushpin row whose thread is not a
        -- mark at all. Three rows above this string a nib between two pins and
        -- get a line of ink; this strings a whole second *tool* between them, and
        -- the rule it needed was already written for the FOLD: a block that is not
        -- the gesture is a block that is **cast**. There the two points were two
        -- circles crossing; here they are two pins.
        --
        -- A snap line is a cord pinned at both ends and snapped flat against a
        -- surface, and it is the one way anybody has ever ruled a line longer than
        -- their ruler. Which is exactly the trade: the pins do not bound the line,
        -- they *aim* it (`Ruler.cast`). Fifty pixels of baseline decide an angle,
        -- and the ruler that comes down on it is the finished ruler -- the whole
        -- page, corner to corner, at 13 across and a 210 shove off both sides at
        -- once.
        --
        -- **Which is the ruler's one real limitation taken off it, and the tool
        -- has nothing else wrong with it.** A ruler's line goes through you. No
        -- level moves that and no level ever could -- 200px becomes 400 and every
        -- pixel of it still lies on a line through your own feet, so what you get
        -- to choose is which way the page is swept and never where. This line goes
        -- nowhere near you. The FOLD is the other answer to the same sentence and
        -- the pair of them are worth reading together: there the reach was sold to
        -- buy the position, because a chord can never pass 132. Here the reach is
        -- **kept** -- and what is paid instead is precision, which is the better
        -- trade to have to make because it is a skill rather than a number.
        --
        -- **A hundred-and-twenty-pixel baseline aiming a four-hundred-pixel line is
        -- the whole tool.** Put the second pin one pixel off where you meant it and
        -- the far end of the line moves a little over three. Nothing about that is hidden -- both craters
        -- are on the page, the ring round the first one says where the second may
        -- go, and the line is the line through them -- and nothing about it is
        -- forgiving, which is what stops a page-crossing hit placed anywhere from
        -- being a page-crossing hit placed anywhere. It is iron sights, and the
        -- near sight is a 51px crater. The range went from 50 to 80 to 120 partly for
        -- this row, and it is the one place in the family where every step up made
        -- the tool *easier*: a longer baseline is a steadier one, so the sights got
        -- more forgiving at the same time as they got easier to set up. Five pixels
        -- of error at the far end became three.
        --
        -- And it is the first row in this family where the *third* pin is worth
        -- more than the second. Three pins pairwise inside 120 are three pairs, so a
        -- triangle of taps rules three lines through one patch of page and sweeps
        -- everything off six directions at once. The pencil's
        -- threads make a shape out of the third pin; this makes an asterisk.
        -- The finished ruler, in RULE above -- including the written `length`,
        -- which is what makes this a cast that *aims* rather than one that is
        -- bounded: `Ruler.cast` reads the field where the FOLD leaves it out, so
        -- the reach is the tool's and the two pins decide only the angle. This was
        -- the first row to need that and is the reason the table exists.
        snap = RULE,
        thread = THREAD,
        drop = PIN,
        -- Half a meter, the family's price, and the comparison is not the one the
        -- three brush rows make. A hand would pay 0.45 for a pin and 0.35 for a
        -- ruler through itself: 0.80 for one crater and one badly placed line.
        -- This is 1.00 for two craters and one line placed anywhere -- dearer, and
        -- it should be, because what is bought is the one thing the parent could
        -- never sell. The third pin is where the price turns: 1.50 for three
        -- craters and three lines.
        ink = 0.5,
    },
    {
        name = "TEAR LINE",
        icon = "tearline",
        -- The fourteenth, and the SNAP LINE's argument with the other instrument
        -- cast between the pins. The `cut` block is not the gesture here (the
        -- press is routed to `drop` first, Game:updateDrawing) so it is cast, and
        -- what is cast is the page coming apart along the line the two pins are
        -- standing in.
        --
        -- **These two were always the same gesture.** Scissors are tapped twice:
        -- the first tap anchors, the second says which way it runs, and the page
        -- opens between them. A pushpin is tapped once and lands. Two pins are two
        -- taps, so nothing about the way this is used is new to either parent --
        -- which is the rarest thing a fusion can say, and the reason this row
        -- needed no new idea at all, only the two halves let go of each other.
        --
        -- **What it fixes is that the scissors' first tap was free and did
        -- nothing.** The whole price of a tool that can be placed anywhere on the
        -- page was the *gap* between the taps: the horde keeps walking through it,
        -- so the row of blobs the first tap lined up is not the row the second one
        -- cuts, and a cut has to be led rather than aimed. Here the first tap is
        -- the biggest single hit in the game. It punches a 51px crater, it pins
        -- whatever survives, and it leaves an object standing in the page you can
        -- see while you decide where the second one goes. The gap between the taps
        -- stops being a cost and becomes the tool.
        --
        -- And the parent's own levels line up behind that without a number moving.
        -- `blades` bites 20 across 6 over "the stretch between the two taps" --
        -- which is now the stretch between the two pins, a hundred and twenty pixels
        -- at the most,
        -- so the deep part of the cut is exactly the part you placed. `through`
        -- runs the rest of it out to both edges of the page at the written 12
        -- across 3. And `sever` lifts the half you are not standing on off the
        -- page with everything on it.
        --
        -- **The sever is worth being plain about, because it is the one parent
        -- field here whose premise this row generalises rather than keeps.** The
        -- scissors' finale reads "the page is in two and the half you are not
        -- standing on is lifted off it", and that is a sentence about *one* cut.
        -- Three pins are three cuts, each choosing its own half, and what is left
        -- is the union of them -- the page in four or five pieces with a wedge
        -- round your feet. That is not a rule breaking; it is a page cut to
        -- ribbons, which is what three tears through one patch of paper does. The
        -- level is kept because it is the finale of a finished line and because
        -- the parent does it *better*: two taps and 0.3 for a cut aimed anywhere
        -- against two pins and 1.0 for one aimed by a hundred and twenty pixels. What this buys
        -- is never the sever. It is the two craters under it.
        cut = {
            -- The cap off, the parent's first level: a tap cannot land off the
            -- canvas, so "unlimited" is a screen's diagonal and nothing here has
            -- to think about infinity. It also means the aimed stretch really is
            -- pin to pin rather than clipped short of the second one.
            reach = math.huge, width = 3,
            damage = 12, knock = 0,
            -- Written at nothing and built by the line's own unlock, the HALO's
            -- rule: `scaleDamage` reaches `cut.blades.damage` by name, and
            -- Tools.copy is one level deep.
            blades = nil,
            -- These two the row may say outright, and it is the PUNCH's reason:
            -- one is a boolean and the other is {tick} with no damage in it at
            -- all -- what a severed half does to the crowd is carry it off the page
            -- and set it down in the far corner rather than hurt it -- so there is
            -- nothing here for the sharpener to find and nothing shared for it to
            -- compound.
            through = true,
            sever = { tick = 0.25 },
            life = 1.6, fade = 0.6,
            ramp = { Palette.paper, Palette.paper, Palette.graphite },
        },
        thread = THREAD,
        drop = PIN,
        -- Half a meter, the family's price. A hand would pay 0.45 for one pin and
        -- 0.3 for a whole cut: this asks 1.0 for two pins and gets the cut for
        -- nothing, which is the same shape of bargain the FOLD strikes -- the
        -- second half of the tool is paid for in a second press of the first half.
        ink = 0.5,
    },
    {
        name = "TACK",
        icon = "tack",
        -- The fifteenth, and the first fusion off the pushpin that is **one pin
        -- rather than two**. Nothing is strung here; the mark pools where the pin
        -- went in (`pool` above, Game:poolAt).
        --
        -- Which is the gluestick being what it is rather than an exception being
        -- made for it. You do not string paste between two points -- paste is a
        -- blob, and a line of it is a line of glue on your fingers. What a
        -- gluestick leaves is a patch, so what a pin loaded with one leaves is a
        -- patch round the hole.
        --
        -- The name is the pun and the pun is the tool: a *tack* is a pushpin, and
        -- *tacky* is what glue is. It is the CORRAL's kind of name -- one word that
        -- is both parents at once -- and unlike the corral's it does not survive
        -- the border, so the Spanish names the blob instead (src/i18n.lua).
        --
        -- **The pair is the sharpest in the family, because the gluestick deals no
        -- damage at all.** That is its whole identity and its whole problem: the
        -- smear holds everything and kills nothing, so it has always needed
        -- something else to be holding things *for*. And it goes where your hand
        -- goes, at the dearest ink on the strip, which means the patch is laid
        -- where you are standing and the crowd it is for is the crowd you are
        -- trying not to be standing in. A pushpin is exactly the missing half:
        -- 10 damage in a 51px circle, placed anywhere, killing everything caught
        -- but the toughest thing in the game -- and *that* is what the paste is
        -- then holding. The crater sorts the crowd and the pool keeps what is
        -- left. Softened by half again (`soften`), so everything else a run owns
        -- cuts deeper into it; torn on the way loose (`tear`); and the free
        -- dragged in from 26 past the rim, which at this radius is a field 102
        -- across.
        --
        -- 25 rather than the glue's own finished 20, and this is the halo's rule
        -- read from the other end. There the rim a sweep cuts is as wide as
        -- whatever the leg is carrying; here the pool a pin leaves is as wide as
        -- **the crater it punched**, because a pool is not a nib. It is what
        -- filled the hole. So what the paste holds is exactly what the circle
        -- caught, one number rather than two, and the tool is legible off the page
        -- for the reach's reason: the crater you can see is the paste.
        radius = 25, damage = 0, knock = 0,
        spacing = 2, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        -- The glue's three upper levels, written on the row rather than built by
        -- the unlock, and it is the MOAT's reason: `tear` is a bare number the
        -- sharpener multiplies on the run's own copy, `pull` is a table nothing
        -- ever writes into, and `soften` is a scalar. There is no shared table
        -- here for a multiplier to compound, so the row may say all of it.
        soften = 1.5, tear = 4,
        pull = { range = 26, speed = 30 },
        ramp = { Palette.paper },
        stamp = gluePoolStamp,
        -- **`fade = 1`, and the row is where that number is paid for.** A pooled
        -- mark is one stamp, and the dither that takes a mark off the page drops
        -- stamps: a fraction of one stamp is either all of it or none, so a pool
        -- left on the ordinary 0.55 would sit at full paste and then vanish at a
        -- uniformly random moment somewhere in its last two and a half seconds.
        -- Which is not a fade, it is a bug with a die in it. At 1 the dither never
        -- starts and the pool leaves the page the only other way a mark can, down
        -- its ramp -- and paste has one colour, so what it does is hold and then
        -- go. Which is also what a blob of glue does: it does not thin out.
        fade = 1,
        -- And the rim's own roughness goes with it, for the same arithmetic. 0.45
        -- of a broken edge is what a *smear* of overlapping discs looks like where
        -- it ran out; 0.45 of one stamp is a coin flip on whether the pool has a
        -- rim at all.
        edge = { stamp = gluePoolEdge, color = Palette.graphite },
        speck = { chance = 0.08, color = Palette.sky },
        pool = true,
        drop = PIN,
        -- Half a meter, the family's price, and the biggest discount in it after
        -- the cordon's: paste is the dearest ink in the game at 1/90 a pixel, and
        -- a hand cannot lay a disc at all -- the nearest thing is a hundred and
        -- twenty pixels of smear, which with the pin is nearly two full meters. Half of one, for
        -- a patch no hand could make, placed where your hand is not.
        ink = 0.5,
    },
    {
        name = "CRATER",
        icon = "crater",
        -- The sixteenth, the second that is one pin rather than two, and the row
        -- that finally makes the pushpin's oldest word true. Its own row has
        -- called the circle a *crater* since it was written; what has always
        -- actually happened there is that things walk out of it. Load the pin with
        -- a rubber and nothing walks out: everything the circle caught and did not
        -- kill is thrown straight out of it, hard, and lands as a weapon.
        --
        -- **Which is the rubber's own limitation taken off it, and it is a
        -- different limitation from every other tool's in this family.** The
        -- others go where your hand goes. A rubber goes where your *wrist* goes:
        -- it only works while the tip is travelling, at a 15px reach, which means
        -- standing in the crowd and scrubbing at it. The one thing it does is the
        -- best shove in the game -- 240, a 27px throw, and what it launches knocks
        -- down whatever it hits for 5 -- and the tool has never been able to
        -- deliver that anywhere but under its own hand. This delivers it as one
        -- tap, at reach, radially, out of a circle you chose.
        --
        -- And the two halves land in the right order without being told to. The
        -- pin's crater goes off first and kills everything in it but the tank
        -- (Pin:land, from Game:updateDrops); the pool is laid on the frame after
        -- it lands. So what gets thrown is exactly *what survived* -- the one body
        -- the pushpin was written to leave standing -- straight into whatever is
        -- walking in behind it. A tool whose finale is "what it sends flying knocks
        -- down what it hits" and a tool whose whole design is "the tank walks out
        -- of the crater" turn out to be the same sentence read from two ends.
        --
        -- 25 on the TACK's rule -- the pool is as wide as the crater, not as wide
        -- as the nib -- and here it is doing more work than it does there: at the
        -- rubber's own 7 the pool would sit *inside* the circle the pin had
        -- already cleared and shove nothing but corpses. What a pool has to reach
        -- is what the crater caught.
        radius = 25, damage = 2, knock = 240,
        -- Nothing outlives the rub, which is the parent's own life of zero and
        -- means exactly what it says here: the shove lands on the frame the pool
        -- is laid and the mark is culled the same frame (Stroke:update). There is
        -- no stamp either, so there was never anything to leave -- what comes off
        -- a rubber is crumbs, and they are thrown out to the sides of the tip and
        -- gone before it is.
        spacing = 2, life = 0,
        rehit = 0.3,
        crumbs = { chance = 0.7, color = Palette.graphite },
        -- Written at nothing and built by the line's own unlock, which is the
        -- CLEARING's placement for the CLEARING's reason: `scaleDamage` reaches
        -- `tool.ram` by name at the top level, and a table it writes into cannot
        -- be on a row Tools.copy only copies one level deep.
        ram = nil,
        -- **Two of the rubber's four levels are unread, which is what the CLEARING
        -- dropped too and for the same two sentences.** `lean` is a tip that keeps
        -- hitting while it rests, and nothing rests here -- there is no tip and no
        -- finger. `scrub` is half price over ground this stroke has already
        -- covered, and nothing here is charged by the pixel. Both are about the
        -- wrist and the meter, and a tap has neither.
        pool = true,
        drop = PIN,
        -- Half a meter, the family's price. A hand would pay 0.45 for the pin and
        -- most of a meter to rub a hundred and twenty pixels of page at a
        -- fifteen-pixel reach: well over a full meter, for a shove delivered where
        -- it is standing. This
        -- is half of one for the same shove out of a 51px circle placed anywhere,
        -- and it is the cheapest thing in the family to *aim*, because a radial
        -- shove out of a point has no angle to get wrong.
        ink = 0.5,
    },
    {
        name = "VOLLEY",
        icon = "volley",
        -- The seventeenth, the last off the pushpin, and the only fusion in the
        -- game whose two parents already share a gesture. Everywhere else in this
        -- family the pin brings the reach and the other tool brings a nib; the
        -- STAPLER has no nib to bring. It is a `drop`, exactly as the pushpin is,
        -- placed by exactly the same tap and arriving through exactly the same
        -- code path -- the two rows have differed in nothing but the contents of
        -- one block since the day they were written (see `drop` at the top of this
        -- file). So there is nothing to string and nothing to pool. What this row
        -- is, is those two blocks laid over one another.
        --
        -- **And they are opposites field for field, which is what makes the
        -- overlay mean something.** A pin is one big telegraphed decision: a
        -- 51px crater, 10 damage, most of half the meter, a quarter of a second in
        -- the air. A staple is a hundred small ones: 15px, 2 damage, a tenth of the
        -- meter, and instant. Pick the pin's numbers and the staple's gesture and
        -- you have this. Pick them the other way round and you have a staple that
        -- takes a quarter of a second, which is nothing at all -- there is exactly
        -- one interesting way to read the pair, and this is it.
        --
        -- Three things come across from the stapler, and each of them retires a
        -- pushpin level rather than sitting beside it:
        --
        -- **`instant`** takes the fall off (Pin.new). This is the biggest single
        -- thing on the row and it is the one flag in the catalogue that removes a
        -- telegraph. The pin's own file argues the fall carefully -- it is "what
        -- turns the ring on the page into a promise rather than a report", about
        -- eleven pixels of bat, "what stops a tap on a moving target from being a
        -- certainty" -- and every word of that is true and is exactly what a
        -- stapler does not have. So the crater lands on the frame you tap it, and
        -- a moving target is no longer a lead you have to guess. It is also what
        -- makes the drag below possible at all: a raked pin with a quarter-second
        -- fall would land a quarter of a second behind your finger, which is a
        -- seam laid where you *were*.
        --
        -- **`rake`** is the gesture, and it is the stapler's finale unchanged --
        -- the one level in the catalogue that turns a tap into a drag, working
        -- here through exactly the same `Game:rakeDrops` it works through there.
        -- A tap still lands one pin, and that matters: the tool is the pushpin
        -- until you hold the pointer down, so nothing about the way you already
        -- used it is taken away. Hold and drag and it rakes a seam of craters.
        --
        -- 48 apart against the staple's 12, which is the stapler's own written
        -- rule read at this size: there `every` is set so the circles just
        -- overlap at a 7px bite, and here it is set so they just overlap at a
        -- 25px one. So the seam is a chain of holes rather than a stripe, no body
        -- is inside two craters at once, and the pin's "kills everything caught
        -- but the tank" survives per crater exactly as written. A meter is four
        -- pins, so a drag is about 145 pixels of seam, 51 wide.
        --
        -- **`crit`** replaces the pin's `point`, and that swap is the whole
        -- argument of the fusion rather than a balance decision. Both are a
        -- multiplier on one hit; they differ in what decides it. `point` doubles
        -- the body the point itself came down on -- a level about *aim*, and it
        -- cannot survive a tool whose gesture is a drag: what you choose in a
        -- seam is a line, and which body each 48-pixel step happens to land its
        -- point on is luck. Writing it here would be a level that pays out on the
        -- one press in a rake that is still a tap. `crit` triples on a roll
        -- instead, and a roll works identically on a tap and on the fortieth pin
        -- of a seam. Which is the trade the two tools' own upgrade lines have
        -- already argued out: the stapler's says a one-in-five is only a *rate*
        -- if the sample is large, "where the same roll on a pin you get two of
        -- from a full meter would only ever be a story about one pin". Four a
        -- meter, raked, is the sample that makes it a rate. **The drag is what
        -- makes the crit legitimate**, and the crit is what pays for the aim the
        -- drag gave up.
        --
        -- What survives from the pin is `radius`, `damage`, the freeze/life pair
        -- and `drive` -- and `drive` is where a seam pays off in a way a tap never
        -- could. It is the pin's own finale, converting kills under a circle into
        -- weight on that circle's survivors, and its row is careful that "a pin
        -- dropped on a *lone* skull changes nothing at all". A rake is how you
        -- get a crowd under a circle on purpose. Nothing here doubles up -- the
        -- craters do not overlap -- so what a seam does to a grin is hit it once
        -- as it goes past and again on the next step, which is the tank dying to
        -- being *raked across* rather than to a lucky crater. One of the
        -- stapler's four levels has nothing to land in, on the CLEARING's terms:
        -- `prise` is wire coming back out of the paper, and what this row drives
        -- into it is a pin, which is a hole and has nothing to pull.
        drop = {
            -- Not PIN, and it is the only pushpin fusion whose block is not. The
            -- other seven eat the parent whole and move nothing inside it, which is
            -- what let one shared table do for all of them; this one is the row
            -- that changes how a pin *arrives*, so it drops a field the shared
            -- table has and adds three it does not. `crit` and `rake` are tables
            -- Tools.copy leaves shared one level down, which is safe for the TACK's
            -- reason: nothing ever writes into either. `crit.mult` in particular is
            -- a multiplier on damage the sharpener has already scaled, so
            -- scaleDamage steps over it by name (src/loadout.lua).
            lands = Pin, sound = "pin",
            radius = 25, damage = 10,
            freeze = 4, life = 4,
            drive = 2,
            instant = true,
            crit = { chance = 0.2, mult = 3 },
            rake = { every = 48 },
        },
        -- **The one row in the family that is not half a meter**, and it is the one
        -- row in the family that is priced per *pin* rather than per press --
        -- because it is the one whose press is not a fixed amount of tool. A drag
        -- is charged as it goes (Game:rakeDrops), so the meter and not a count is
        -- what caps the seam, and a rake that runs dry simply stops where the ink
        -- did.
        --
        -- A quarter of a meter, which is **half what every other fusion in this
        -- family charges for a press** and a little over half the pushpin's own
        -- 0.45. So a full meter is four craters where the pushpin gets two and the
        -- stapler gets ten -- between its parents, which is where a fusion of them
        -- belongs, and countable, which matters more than it looks: four is few
        -- enough that a player knows what a seam costs before laying it.
        --
        -- The halving is exactly what the stapler brings. Its own four levels are
        -- written on the one invariant they never touch -- "ten a meter is still
        -- ten a meter" -- so what it lends a fusion is not a discount it never
        -- had. It is the *rate*: the pin stops being a thing you spend half a
        -- meter on twice and becomes a thing you spend a meter on in one gesture.
        ink = 0.25,
    },
    {
        name = "MARGIN",
        icon = "margin",
        -- The eighteenth, and the first fusion in the game off the *ruler*. The
        -- paragraph at the top of this file argues the family out in full; the
        -- short of it is that a ruler opens a lane across the page and has never
        -- been able to keep one, because what it leaves down the middle of that
        -- lane is a pencil line and a pencil line is not terrain. So the second
        -- parent is what gets left in the lane, and here the second parent is the
        -- pencil -- which leaves nothing at all except the fact of having been
        -- drawn.
        --
        -- Which is why this one is not terrain either, and is the family's odd
        -- row read in the right order: it is the only one of the seven that keeps
        -- the ruler's whole promise. A fence, a burning band, a bar of paste and
        -- a seam of wire all cost the lane something -- two of them stop the shove
        -- outright -- and graphite costs it nothing. The corridor opens exactly as
        -- it always did and there are simply two more lines in it.
        --
        -- **Both edges rather than the middle, and that is the whole design in one
        -- flag** (`margins` above). The ruler's aim has dashed its two long edges
        -- in pencil since the tool was written -- what you are aiming is the band
        -- it covers rather than a hairline that turns out to be thirteen pixels
        -- wide -- and this rules those two dashed lines for real. Which puts the
        -- graphite exactly where a ruler has always been weakest: everything
        -- inside the band takes 12 and everything a pixel outside it takes
        -- nothing, and now the pixel outside it takes 9. The band does not get
        -- wider so much as it stops having a cliff at the edge of it, and a body
        -- standing on the shoulder takes both.
        --
        -- **Two of the pencil's four levels are deliberately not here**, and both
        -- are the LASSO's `flow` rule rather than a nudge. `flow` is a price per
        -- pixel that eases while the finger stays down, and there is no finger and
        -- no per-pixel price -- the whole cost is paid at the press. And `loop`
        -- closes a ring by drawing one, which two parallel lines will never do
        -- however long they run: a lasso is a thing a hand does, and nothing here
        -- is drawn by a hand. What comes across is the point and the depth, which
        -- between them are what a pencil *is*.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- Down both long edges of the band, which is the field this row is named
        -- for and the only row in the catalogue that carries it.
        margins = true,
        -- The finished ruler, unchanged, in RULE above.
        snap = RULE,
        -- Half a meter, and it is the family's price for the family's reason: a
        -- hand would pay 0.35 for a ruler through its own feet, and what this asks
        -- for is the same line with two more ruled beside it. The comparison the
        -- graphite makes is the one worth doing, though, and it is not close --
        -- two page-wide pencil lines at 1/230 a pixel are most of *four* full
        -- meters drawn by hand, and no hand could draw them straight. What a
        -- fusion sells is never a discount on pixels; it is that these two are
        -- exactly parallel, exactly thirteen apart, and land on the frame the
        -- ruler does.
        ink = 0.5,
    },
    {
        name = "SPINE",
        icon = "spine",
        -- The nineteenth, and the pen's third answer to the same two complaints:
        -- its line goes where its hand goes, and its line is open. The CORRAL
        -- answers both at once with a fence that has no ends, drawn where you are
        -- not. The STOCKADE answers them a post at a time, with a crater under
        -- every corner. This answers neither of them and answers a third thing
        -- nobody had asked -- **how long a fence can be** -- which turns out to be
        -- the one that changes what the tool does.
        --
        -- A pen draws about a hundred and seventy pixels of wall from a full
        -- meter, and it draws them at the speed of your own hand through a crowd
        -- that is walking into you while you do it. This lays the page's whole
        -- diagonal in one press, through your own feet, in the frame you let go.
        -- The page is in two. That is the name: a spine is the one line on a
        -- notebook a page cannot be crossed at, and it is not a metaphor for what
        -- this does -- the crowd walks the length of it and round the end, and the
        -- end is off the paper.
        --
        -- **What holds it down is the camera and not a rule**, and it is worth
        -- being plain about because it is the only thing standing between this row
        -- and a run that cannot be reached. The line is half a diagonal either
        -- side of where you were standing when you let go; the page keeps
        -- scrolling and the horde spawns off the ring beyond it, so a wall that
        -- divided the screen is a wall in the middle of the world about four
        -- seconds later. It divides where you *were*. Which makes it the one
        -- fence in the game you use by walking away from it.
        --
        -- Every number is a finished parent's. The pen at its four -- the broad
        -- nib, the line that stings what leans on it, the pop when it goes, and
        -- the clock coming off it -- and the ruler at its four, in RULE above.
        radius = 4, damage = 1, knock = 0,
        -- One field, and it is the same one field it is on the CORRAL and the
        -- STOCKADE: the fence is not a property of the pen, it is a property of
        -- any mark that says `wall`. Walls:rebuild files a ruled line's path at
        -- the nib's own radius exactly as it files a line you drew, and the crowd
        -- walks round it without being told which of the three laid it --
        -- Game:trailRuler dirties the index as it rules.
        wall = true,
        spacing = 1, life = 9,
        -- The pen's second level, unchanged and including the two pixels of slack:
        -- Enemy:resolveWalls parks a body at exactly the ink's edge, so a tick
        -- measured at the radius alone lands on floating-point luck.
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        -- **The pen's `keep` is here, and this is the one fused row it lands on
        -- cleanly.** The level holds one gesture's worth of wall and lets the last
        -- one go every time a new one is laid (Game:holdWalls), and a ruler is one
        -- gesture exactly -- one press, one line, one release -- so ruling the next
        -- fence is what drops the last, the way drawing the next line is for a hand
        -- and swinging the next circle is for an arm. The STOCKADE had to leave it
        -- out for precisely this reason and says so at length: a fence built pin by
        -- pin is not one gesture, and `keep` would have dropped every rail but the
        -- newest as you built the thing. Which is the difference between the pen's
        -- two answers rather than an accident -- a stockade is held up by its posts
        -- and a spine is held up by being the last thing you ruled.
        keep = true,
        -- Written at nothing and built by the unlock, the HALO's rule: `scaleDamage`
        -- reaches `pop.damage`. And it is worth what it costs here more than
        -- anywhere else -- the whole page's worth of line comes off at once, so
        -- replacing a spine is an attack along the old one, aimed by where you were
        -- standing a moment ago.
        pop = nil,
        -- **And the pen's `smooth` has to go rather than merely being left out**,
        -- which is the CORRAL's paragraph and the STOCKADE's after it. A ballpoint
        -- nib trails the pointer by design -- it is what rolls hand jitter into a
        -- curve -- and a ruled line is laid whole between two fixed points in one
        -- frame. A nib chasing at 26 would cover a fraction of the page and stop:
        -- not a number nothing reads, a number that would lie and take the fence
        -- with it.
        snap = RULE,
        -- Half a meter, the family's price. A hand would pay 0.35 for the ruler and
        -- most of two and a half meters for the blue, and would still have drawn it
        -- by hand.
        ink = 0.5,
    },
    {
        name = "UNDERLINE",
        icon = "underline",
        -- The twentieth, and the marker's third answer as well. The HALO makes the
        -- rim of a circle worth standing on and the CORDON makes the line between
        -- two pins worth standing on; this makes a line across the *whole page*
        -- worth standing on, which is a worse shape than either and by a distance
        -- the most of it.
        --
        -- The band is the best ground in the game and the worst to place. It goes
        -- where your hand goes, which is to say where you are, and the crowd it is
        -- for is the crowd you are trying not to be standing in. Every fusion the
        -- marker has is an answer to that sentence and they differ only in the
        -- shape: a ring you draw round them, a strip you pin between two craters,
        -- and this -- a band through your own feet that reaches both edges of the
        -- paper. It is the only one that does not solve the placement at all. What
        -- it sells instead is that there is no placing left to do: a line through
        -- you at an angle you chose crosses everything, and what it crosses catches
        -- fire.
        --
        -- **Which is the one row in the family where the ruler's shove is doing the
        -- work rather than being spent.** Everything within the band takes 12 and
        -- is thrown clear of the line to both sides -- *across* the band on the way
        -- out, at 13 across the nib and 5 a tick, and touching it at all is two
        -- seconds of burning that travels with the body and keeps ticking after it
        -- has left (`ignite`, Game:updateBurning). The corridor is opened by
        -- throwing the crowd through the fire that is holding it open. Nothing had
        -- to be written for that; it is the parent's shove and the parent's burn
        -- landing in the same frame.
        --
        -- The name is what a student does with these two objects and what the tool
        -- does with the fields: `under` puts the band beneath every other mark on
        -- the page (Game:draw), which is why a thing this wide never buries the
        -- thin lines laid across it, and it has been on the marker since long
        -- before there was a ruler to draw it against. The Spanish names the band
        -- instead, because SUBRAYADOR is already the parent (src/i18n.lua).
        radius = 7, damage = 5, knock = 0,
        spacing = 2, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true, stack = 3,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- `stack` is kept on the HALO's terms: it is the parent's finished line
        -- copied across without a nudge, and a ruled line no more crosses itself
        -- than a compass ring does. It is not a number that lies -- what it says is
        -- what happens where the passes of one stroke cross, and here there are
        -- none -- so it stays where the day the marker's third level changes finds
        -- it.
        --
        -- Written at nothing and built by the line's own unlock, which is not a
        -- stylistic choice: `scaleDamage` writes into this table and Tools.copy is
        -- one level deep.
        ignite = nil,
        snap = RULE,
        -- Half a meter, the family's price, and the same half meter the HALO
        -- charges -- which is the comparison that matters, since the two rows are
        -- the same band on the two gestures that reach. A ring you place round a
        -- crowd against a line you point through one.
        ink = 0.5,
    },
    {
        name = "TRENCH",
        icon = "trench",
        -- The twenty-first, and the gluestick's third answer. The MOAT is a ring of
        -- paste the tool places for you, the TACK is a disc of it round a crater you
        -- placed, and this is a bar of it from one edge of the page to the other.
        --
        -- **It is also the one fusion in this family that does not open a lane.**
        -- Read the family's own paragraph at the top of this file: a ruler throws
        -- everything within the band clear of the line to both sides at once, and
        -- that shove is the whole tool. Paste holds. A held body drops the push it
        -- was carrying the same frame (`frozen` in Enemy:update, which is the HEM's
        -- rule one gesture over), so what this lands is 12 across the band, a shove
        -- that never happens, and everything that was standing in the lane still
        -- standing in it and stuck to the paper for six seconds.
        --
        -- Which is not a rule breaking. It is the gluestick being exactly what it
        -- has always been -- it deals nothing, it shoves nothing, and the whole
        -- point is that what it smears stops dead -- and a fusion is both parents
        -- still doing what they always did. The ruler decides *where* the page
        -- stops, and it turns out that a straight edge is a very good way to decide
        -- it: the crowd does not walk round a bar of glue the way it walks round a
        -- fence, it walks into it and stays there, so what the page ends up with is
        -- not two halves but one line the horde arrives at and does not leave.
        --
        -- Every one of the gluestick's four lands and three of them are what make
        -- the line worth having, since paste on its own is a delay. `soften` cuts
        -- everything the run owns half again as deep into whatever is stuck -- a
        -- whole page of crowd, held still, at 1.5 -- `tear` takes a blob's worth off
        -- each of them on the way loose, and `pull` drags the free within
        -- twenty-six pixels of the ink *into* it, which on a line this long is the
        -- difference between a bar the crowd has to be walking at and a bar that
        -- collects. There is no damage in any of that but the tear, and there should
        -- not be.
        radius = 20, damage = 0, knock = 0,
        spacing = 2, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        ramp = { Palette.paper },
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        -- The gluestick's second, third and fourth, written on the row rather than
        -- built by a level, which is the TACK's reason word for word: `soften` and
        -- `tear` are bare numbers the sharpener multiplies on the run's own copy,
        -- and `pull` is a table nothing in the game ever writes into. Only the
        -- tables `scaleDamage` reaches have to be built fresh every rebuild.
        soften = 1.5,
        tear = 4,
        pull = { range = 26, speed = 30 },
        snap = RULE,
        -- Half a meter, the family's price, and the dearest ink on the strip is
        -- what makes it look like a bargain: a hand would pay 1/90 a pixel for
        -- paste, so the page's diagonal in glue is over four full meters and it
        -- would be a smear rather than a line. What is bought is the straightness
        -- and the reach, as it is everywhere in this family.
        ink = 0.5,
    },
    {
        name = "PARTING",
        icon = "parting",
        -- The twenty-second, and the second panic button on the strip. The
        -- CLEARING is the first: a compass leg that wipes the disc it swept
        -- instead of cutting the rim it drew, planted on your own feet, so the
        -- rank that had reached you goes over the horizon of it. This is the same
        -- idea with no horizon at all.
        --
        -- **A rubber leaves nothing**, which is the one thing that makes this row
        -- different from the four above it. Every other ruler fusion is a mark left
        -- in the lane; there is nothing to leave here, so the rubber's half lives
        -- entirely inside the block -- and what it does to that block is take the
        -- band off it (`wipe` above, Ruler:strike). What a ruler with one lands on
        -- is not everything within thirteen pixels of the line, it is everything
        -- within the ruler's own *length* of it, and the ruler's own length is half
        -- a page diagonal. So it reaches the page. The whole crowd, wherever it is
        -- standing, chipped for 2 and thrown straight away from the line you
        -- pointed.
        --
        -- Which is the same word doing the same job in the other block, and the two
        -- rows are worth reading together: `sweep.wipe` gives the compass the disc
        -- instead of the rim, `snap.wipe` gives the ruler the page instead of the
        -- band. Neither changes a number, both change what the block *reaches*, and
        -- both are only allowed because a rubber's hit was never an edge -- you do
        -- not cut with one, you clear an area with one.
        --
        -- **The aim is the one thing it cannot show you**, and Compass:drawGuide
        -- already lives with the same problem: the dashed band a ruler draws while
        -- you turn it is the object, not the reach, and the reach is not a thing
        -- this tool was ever going to be able to draw. What you are actually
        -- choosing is an *axis* -- everything on one side of the line goes that way
        -- and everything on the other side goes the other -- so the aim is the only
        -- decision in it and it is a real one. Turn it wrong and half the crowd is
        -- thrown at the half you were about to walk into.
        --
        -- Two of the rubber's four are not here and both are the CLEARING's
        -- omissions for the CLEARING's reasons: `lean` is a tip that keeps hitting
        -- while it rests and a straight edge does not rest on anything, and `scrub`
        -- is half price over ground the stroke has covered when the whole price was
        -- paid at the press. What comes across is the shove -- 240, the line's first
        -- level, the number everything below it stands on -- and the ram, which is
        -- the finale.
        snap = {
            length = 165, width = 13,
            -- The rubber's chip and the rubber's throw, both unchanged, exactly as
            -- the CLEARING carries them: 2 is what a rubber has always done and the
            -- one number its line never moved, and 240 is a 27px throw (the push
            -- decays at exp(-9t), so distance is force/9) and the number the ram
            -- below is timed against. The ruler's own 12 and 210 are the two
            -- numbers this row does *not* keep, which is the MOAT's split read the
            -- other way round: there the arm's cut and the mark's hold were two
            -- different things landing in order, and here there is only one thing
            -- landing and the rubber is what is doing it.
            damage = 2, knock = 240,
            -- The page rather than the band, and the one field in the catalogue
            -- that changes what a block *reaches* instead of by how much. See
            -- Ruler:strike, which grew one line for it.
            wipe = true,
            -- What it leaves is the ruler's own ruled pencil line, and that is not
            -- an oversight the way the CLEARING's `life = 0` was a decision. A
            -- compass carrying a rubber has no ring to draw because the graphite
            -- circle you watch is the *path the arm is on*; a ruler is an object
            -- that comes down flat on the paper whatever is being rubbed along it,
            -- and the line it rules is the ruler's own. There is nothing of the
            -- rubber's to put on the page, so the ruler's mark stands.
            life = 1.6, fade = 0.55,
            ramp = { Palette.ink, Palette.slate, Palette.graphite },
        },
        -- The rubber's finale: anything this shove sends flying shoves and damages
        -- whatever it runs into while it is still truly flying (Game:updateRams). 5
        -- is a blob dead on arrival, and the victims never become projectiles
        -- themselves -- one rub is one volley and not a chain -- which on a page
        -- being thrown open along a line means the ranks nearest the line are bowled
        -- through the ranks behind them, both ways at once. It is the only damage
        -- this tool does that can kill anything, and it is dealt by the crowd to
        -- itself.
        --
        -- On the row rather than in the block, the CLEARING's placement for the
        -- CLEARING's reason: `scaleDamage` reaches `tool.ram` by name and nothing
        -- walks into a table inside a block. Which also means it must be built by
        -- the unlock's `apply` -- Tools.copy is one level deep, so a `ram` written
        -- here would compound the multiplier into it every rebuild.
        ram = nil,
        -- Half a meter, the family's price, and it is the one row in the seven where
        -- the price is not really about what it lays down: nothing is laid down. It
        -- kills almost nothing -- 2 a body on a page of things with four to twelve
        -- health -- so what half a meter buys is time and room, which is the trade
        -- the rubber has always made and the only reason a tool is allowed to touch
        -- every enemy on the page at once.
        ink = 0.5,
    },
    {
        name = "SEAM",
        icon = "seam",
        -- The twenty-third, and the stapler's third answer. The HEM runs a seam
        -- round a circle until it closes, the VOLLEY sells the pin's tap back as a
        -- drag, and this runs one straight across the page in a single press.
        --
        -- **The stapler is the most repetitive tool on the strip** and every fusion
        -- it has is a different way of not doing the repeating. Ten a meter, one
        -- press each, every one aimed by hand at a 15px circle on something that is
        -- moving. Its own last level sells the ten presses back as one gesture, but
        -- a dragged seam is still a seam your own hand has to walk, through the
        -- crowd you wanted it in front of. An arm walks it for you and closes it. A
        -- straight edge walks it for you and does not: what you get is a line of
        -- wire with two ends, at an angle you chose, through your own feet, from one
        -- edge of the paper to the other.
        --
        -- **Two-thirds of a meter of wire in one press, and it is the dearest press
        -- in the game** (see `ink` below). That is the row's whole balance and it is
        -- the stapler's own invariant doing it: every level in that line is written
        -- against "ten a meter is still ten a meter", so wire is the one thing on
        -- this row that cannot be free. The HEM answers the same problem with a
        -- second price the drag pays as it opens (`sweep.per`); here the count is
        -- decided by the screen rather than by the player, so there is nothing for a
        -- drag to buy and the whole of it is written down as one number.
        --
        -- **And a seam of staples does not shove**, which it shares with the TRENCH
        -- and which is the family's one real interaction. The band takes 12 and the
        -- wire takes 6 on top of it -- a fifth of those going straight through at 18
        -- -- and everything the wire catches is fastened to the paper for two
        -- seconds, so the push it was given the same frame is dropped before it is
        -- ever spent. The ruler opens the lane and the wire keeps what was standing
        -- in it, which is what a stapler is for.
        --
        -- And then it takes it back. `prise` is the stapler's third level and this
        -- is the row that shows it whole: thirty staples land in one press, hold the
        -- lane for two seconds, and come out of the paper together for a second 6 --
        -- a straight line across the page that hits, waits, and hits again. Nothing
        -- is left afterwards, which is the trade the level makes everywhere it is
        -- taken: a seam is an event rather than a track.
        snap = RULE,
        -- What the straight edge presses into the page as it comes down, one every
        -- twelve pixels of the line it landed on (Game:seamAlong) -- so a page
        -- diagonal holds a little over thirty of them, which is within one or two of
        -- what a fully opened HEM lays round its rim. The two rows are the same
        -- length of seam, straight and closed.
        --
        -- Written at nothing and built by the line's own unlock, and here that is
        -- doubly required: `scaleDamage` reaches `snap.wire.damage` by name
        -- (src/loadout.lua) and Tools.copy is one level deep, so a whole block
        -- written one level in would compound every rebuild. The fixative reaches
        -- it by name too -- a staple's hold is a staple's hold whether a finger, an
        -- arm or a straight edge drove it (`scalePersistence`). See the row's
        -- `fusionLine` for the block itself -- the stapler's finished four, to the
        -- number, including the `rake.every` that decides the spacing and is the
        -- one field here that has changed *reader* rather than value. A finger
        -- reads it, an arm reads it, and now a straight edge does.
        wire = nil,
        -- **The dearest single press in the game**, and it is deliberately dearer
        -- than the FOLD's two. 0.9 against the family's 0.5 is 0.4 of wire for a
        -- little over thirty staples, which is the HEM's rate to within a rounding
        -- -- a fifth of what a tapped staple costs, and the fifth is the aiming.
        -- What you are no longer doing is landing a 15px circle on something that is
        -- moving, thirty times; what you are buying instead is thirty staples on a
        -- *line you chose*, and how many of them find a body is the whole of what
        -- the aim decides. A seam ruled across empty paper is a seam ruled across
        -- empty paper, at full price.
        --
        -- Which also means this is the one tool in the game a full meter barely
        -- affords, and that is the point rather than a side effect: three seconds of
        -- standing still per press is a real clock, and it is the only thing holding
        -- back a run that would otherwise wire the whole page shut.
        ink = 0.9,
    },
    {
        name = "GUILLOTINE",
        icon = "guillotine",
        -- The twenty-fourth, the last of the ruler's seven, and the scissors' third
        -- answer. The PUNCH takes a disc out of the page, the TEAR LINE tears it
        -- between two pins, and this trims it: a straight edge and a blade running
        -- down it, which is a real object in a real stationery cupboard and does
        -- exactly this to a page.
        --
        -- **The two halves are one gesture and it is the ruler's.** The scissors'
        -- whole price is the *gap* between their two taps -- the horde keeps walking
        -- through it, so the row of blobs the first tap lined up is not the row the
        -- second one cuts, and a cut has to be led rather than aimed. A ruler has no
        -- gap: it is held, turned and released, and the cut opens along the line it
        -- landed on in the same frame it landed. So what this row buys is a cut that
        -- can be *aimed* -- and pays for it with the one thing a ruler cannot give,
        -- which is a line that goes anywhere but through your own feet.
        --
        -- 12 across the band from the ruler and 20 from the blades on top of it is
        -- **32, the deepest single hit in the game**, and the grin has 34. That is
        -- not a coincidence and it is the pushpin's number pointed a third way: the
        -- pin is one short of a skull, this is two short of the tank, and the one
        -- enemy written to survive everything a build does to move the crowd goes on
        -- surviving. It is thrown clear of the line at 210 like everything else, and
        -- it walks back.
        --
        -- **The scissors' finale is here and it had to be re-read to get here**,
        -- which makes it the clearest case in the catalogue of a parent level that
        -- neither survived unchanged nor was left out. `sever` lifts "the half you
        -- are not standing on" off the page with everything on it, and a ruler's
        -- line goes *through* you: at the moment this lands there is no half you are
        -- not standing on. Freezing an answer at the cast -- which is what every
        -- other cut in the game does, off the tap that placed it -- would pick a
        -- half off a floating-point sign, which is a page-wide finale decided by
        -- nothing.
        --
        -- So it keeps asking (`follows`, src/scissors.lua). The cut re-reads your
        -- feet every frame: straddle the slit and neither half goes, step off it and
        -- the half you left goes with everything on it, walk back across and it is
        -- the other half instead. Which is the same sentence read *continuously*
        -- rather than once, and it turns the ruler's one central fact from the thing
        -- that broke the level into the thing that aims it -- the pivot is your own
        -- feet, so the offcut is wherever your feet are not.
        --
        -- It is the family's own version of what the TEAR LINE did to the same
        -- level: there three pins are three cuts each choosing their own half and
        -- what is left is a page in ribbons, which is the sentence generalised to
        -- more than one cut; here it is generalised to a cut that has no side to be
        -- on. Neither is a rule breaking, and both cost the parent nothing -- an
        -- ordinary cut still freezes its half at the tap, because a cut you placed
        -- with two taps has a side you *chose* and having it follow you afterwards
        -- would take a decision away rather than hand one over.
        --
        -- The FOLD is still worth reading beside this. It had to leave the ruler's
        -- own finale behind for the mirror image of the same fact -- how far a chord
        -- reaches is not the tool's to decide -- and between them the two rows say
        -- the thing worth knowing about fusing anything into a ruler: **the pivot is
        -- your own feet, and every parent level that assumed otherwise has to be
        -- looked at.** One of the two survived that look.
        snap = RULE,
        -- The page opened along the same line, cast between the ruler's two ends
        -- (Game:trailRuler). The blades then travel the length of it rather than
        -- closing along all of it at once, which is the parent's own behaviour and
        -- is worth more here than anywhere: a page diagonal is long enough that the
        -- crowd walks while the cut is opening, so the far end of one is genuinely a
        -- lead rather than a place.
        cut = {
            -- The cap off, the parent's first level. It is doing nothing here and is
            -- written down anyway, on the scissors' own rule that a tool's row says
            -- up front what may happen to it: the two points are the ends of a ruler
            -- that already reaches the corners, so there was never a cap to reach.
            reach = math.huge, width = 3,
            damage = 12, knock = 0,
            -- Written at nothing and built by the line's own unlock, the TEAR LINE's
            -- rule: `scaleDamage` reaches `cut.blades.damage` by name and Tools.copy
            -- is one level deep.
            blades = nil,
            -- **`through` is false and the false is the argument.** The parent's
            -- third level runs the cut on past both taps to the edges of the page,
            -- and what it is running on past here are the two ends of a straight
            -- edge that is already lying corner to corner. There is nowhere to run
            -- on to. Which is not a level lost -- it is a level *arrived at*: what
            -- `through` buys the scissors is a cut that crosses the page, and this
            -- row starts there. Written down at false rather than left out so that
            -- nobody reads the absence as an oversight.
            through = false,
            -- The finale, with the one field that makes it answerable on a tool
            -- whose line goes through its own pivot. On the row rather than built
            -- by a level for the PUNCH's reason: there is no damage in it at all --
            -- what a severed half does to the crowd is take it off the page rather
            -- than hurt it -- so there is nothing here for the sharpener to find
            -- and nothing shared for it to compound.
            sever = { tick = 0.5, follows = true },
            -- What is left is the page opened: a dashed slit that closes back up
            -- over a second and a half, paper first and then a graphite crease.
            life = 1.6, fade = 0.6,
            ramp = { Palette.paper, Palette.paper, Palette.graphite },
        },
        -- Half a meter, the family's price. A hand would pay 0.35 for the ruler and
        -- 0.3 for the cut and would get two badly aimed lines for the 0.65; this is
        -- 0.5 for one line that is both. It is also the only row in the seven where
        -- the second parent is cheaper than the first, which is why it is the only
        -- one where the fusion costs less than the pair -- everywhere else the
        -- family price is a discount on a brush and here it is a discount on a tool.
        ink = 0.5,
    },

    -- **The twenty-fifth, and the first of five off the PENCIL -- which is the
    -- first family in the game with no carrier in it at all.**
    --
    -- The twenty-four above are one shape borrowed three ways. A compass reaches
    -- away from you and its ring became a mark; a pin lands where you tapped and
    -- the line between two of them became one; a ruler is aimed and the lane it
    -- opens became one. Every one of those is a *gesture* worth borrowing, and the
    -- second parent is what the gesture is carrying. Pair two tools with no such
    -- gesture between them -- a pencil and a pen, a pencil and a rubber -- and
    -- there is nothing to carry and nothing to cast, which is exactly why those
    -- pairings were the ones left.
    --
    -- So the shape these five borrow is the **stroke itself**. A line you drag is
    -- a shape as much as a ring or a ruled diameter is: it has a length, an
    -- inside once it closes, and a mark left lying on the page afterwards. The
    -- pencil is the tool that owns all three -- it is the cheapest ink in the
    -- game, it is the one every run opens holding, and its finale is the only
    -- thing on the strip that claims an *area* by drawing its border. What the
    -- second parent brings is what the drawn line is made of, or what closing one
    -- means.
    --
    -- Which makes the family the compass's argument for a third time and from the
    -- nearest possible distance: there a gesture that reached borrowed a nib, and
    -- here the nib borrows everything else. Nothing about the drawing changes in
    -- any of the five -- press, drag, lift, and the line is charged by the pixel
    -- the way a line always was.
    --
    -- **`loop` is the field the family is really about**, and three of these five
    -- rewrite what it means. Up to here closing a ring has meant one thing (cut
    -- what is inside, `Stroke:tryCloseLoop`) and the only question a fusion asked
    -- of it was who drew the ring. Here the ring is always yours and the question
    -- is what it *does*: cut them, ring them in fire, or lift them off the page
    -- with the paper. The pencil's own answer is the cheapest of the three, which
    -- is what makes it the one you start with.
    {
        name = "DECKLE",
        icon = "deckle",
        -- PENCIL and PEN, which is the pair every run opens holding and the one
        -- fusion in the book that eats both of the tools you were issued.
        --
        -- A deckle edge is what the rim of handmade paper looks like before
        -- anybody trims it: a fence with a torn edge rather than a ruled one, and
        -- that is the row exactly. What is drawn is the pen's line -- solid to the
        -- crowd, filed as a wall at the nib's own radius (`Walls:rebuild`), and on
        -- the paper for the pen's nine seconds rather than the pencil's second and
        -- a half -- and what draws it is the pencil: 3px of ragged point where a
        -- ballpoint lays 7 of smooth blue, scratching at 9 the whole way.
        --
        -- **The two halves are one idea and it is the pencil's finale.** A ring
        -- closed with a pencil cuts what it holds *once*, and then everything in
        -- it walks out, because a graphite line is not terrain. That is the
        -- finale's whole ceiling, and this is the one tool that lifts it: the ring
        -- you close is a fence, so what was cut is still standing in it when you
        -- come round again. Drawing a ring, cutting it, and drawing the next ring
        -- inside the first is a thing no other row in the game can do.
        --
        -- Blue, because the mark is a wall and the crowd has to be able to read it
        -- as one -- the pen's ramp and the pen's `fade`, so the line still goes
        -- visibly thin and pale in its last stretch and the warning still means
        -- what it always meant. Graphite would be a fence the colour of every
        -- scribble on the page.
        radius = 4, damage = 9, knock = 0,
        wall = true,
        -- The pen's contact level, and the whole of the pen's machinery unchanged:
        -- a tick every half second to whatever is pressed against the ink, with
        -- `graze` for the two pixels of slack a wall needs to be measurable at all
        -- (Enemy:resolveWalls parks a body at *exactly* the ink's edge, so a tick
        -- measured at the radius alone lands on floating-point luck).
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        -- **The one number on this row that neither parent could have written**,
        -- and the reason it exists is that the two of them disagree about `damage`
        -- and both are right. 9 is what the pencil costs to be *drawn over* -- the
        -- nib doing what a nib does, once, as it goes past. 1 is what the pen
        -- charges for leaning on a finished fence, paid out over the whole line for
        -- as long as the line lasts. Collapsing them would have to pick, and both
        -- picks are wrong: at 1 this is a pencil that scratches for nothing, and at
        -- 9 it is a permanent wall dealing a skull a second to a rank that has
        -- nowhere to go -- which is what `keep` below would turn it into.
        --
        -- So the row says both, and it is the placement `pop` and `loop` already
        -- use: what a mark does after the stroke is over has never been the same
        -- field as what the stroke does. Read in Stroke:apply.
        sting = 1,
        -- The pen's, not the pencil's. Both parents write a number here and they
        -- disagree, so the *body* decides it the way it decides everywhere else
        -- (the MOAT's rim above): there is one body on this row and it is terrain.
        -- A fence that shoves is not a fence -- and the shove would be worst
        -- exactly where the row is best, throwing the crowd back out of a ring
        -- while you were still closing it.
        spacing = 1, ink = 1 / 170, life = 9,
        -- The pen's price by the pixel and the pencil's discount on it. Both are
        -- read here and both mean what they meant: a wall is the expensive ink,
        -- and `flow` pays a *style* -- one long line that keeps going -- which is
        -- what closing a ring by hand is. Half price at the far end of a long one,
        -- so the ring is affordable and the short defensive stroke is not
        -- discounted at all.
        flow = { over = 150, floor = 0.5 },
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        -- The pencil's broadened point in the pen's ink: 3 pixels of blue with a
        -- stray one thrown out beside it, against the ballpoint's even 7. It is
        -- the one place the two parents' looks could not both survive, and the
        -- grain wins because the grain is the pencil -- `pencilBroadStamp` is
        -- procedural and draws in whatever colour is set, so this costs no art.
        --
        -- The wall is filed at 4 and the ink is 3 across, which leaves a pixel of
        -- slack either side. That is the pencil's own arithmetic unchanged -- a
        -- broad point has always reached a pixel past its darkest pixel -- and it
        -- errs the safe way for a fence: the crowd stands off the ink rather than
        -- inside it.
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.sky },
        -- The pencil's finale and the pen's third level, both built by the line's
        -- own unlock (src/upgrades.lua) rather than written here: `scaleDamage`
        -- reaches into both tables by name and `Tools.copy` is one level deep, so
        -- a table the sharpener writes into has to be built fresh on the run's
        -- copy every rebuild or the multiplier compounds into this shared row.
        loop = nil,
        pop = nil,
        -- The pen's finale, and the row is written at both parents finished the
        -- way every fusion in the book is. `keep` holds the line you drew last on
        -- the page with no clock on it at all, and one gesture is one line here --
        -- a hand-drawn ring is exactly what the level was written for, where the
        -- STOCKADE had to leave it out because a fence built pin by pin is not one
        -- gesture.
        --
        -- **What holds it down is `sting` and not a clause.** A ring you can keep
        -- forever is only a problem if standing in it costs the crowd nothing to
        -- be in and everything to touch; at 1 a tick it is a pen line that happens
        -- to be closed, which is what it says on the row. And drawing the next ring
        -- is what lets the last go, so the page cannot be latticed shut -- what is
        -- released fades on its ordinary nine seconds and then pops, which makes
        -- replacing your own ring an attack along the whole of the old one.
        keep = true,
    },
    {
        name = "STUB",
        icon = "stub",
        -- PENCIL and RUBBER, which is one object: a pencil with an eraser on the
        -- end of it. A stub is both halves of that -- the nub of rubber crimped to
        -- the ferrule, and what is left of a pencil that has been used properly.
        --
        -- **It is the only tool on the strip that does two different things
        -- depending on whether you move.** Drag and it is the pencil, unchanged in
        -- every number: a broad point at 9 that cuts what it is drawn over and
        -- closes a ring on what it surrounds. Tap -- press and lift without
        -- travelling -- and it is the finished rubber instead, the whole of it at
        -- once: a 7px circle at the tip, 240 of shove thrown radially out of it,
        -- and what that sends flying knocking down whatever it lands on.
        --
        -- Which is the one thing a pencil has never had and the one thing the
        -- rubber was always short of. A pencil is a line you commit to -- the
        -- finger is down, the crowd is closing, and there is no gesture in the
        -- tool for "not now". A rubber is that gesture and nothing else, and its
        -- own trouble is the opposite one: it has to be scrubbed, so it is a
        -- weapon you have to already be holding when the crowd arrives. Put them
        -- on one row and the panic press stops costing you the line.
        --
        -- The tap is not a `drop`. It looks like one -- a tap, a radius, a
        -- number -- and it cannot be one, because `drop` beats the brush fields in
        -- the routing at the top of `Game:updateDrawing` and a row carrying both
        -- would never draw a line at all. So it is a field on the row that the
        -- *release* reads (`tap` below, `Stroke:tap`), which is also the only
        -- place that can tell a tap from a drag: a press is not a tap until it
        -- has ended without going anywhere.
        --
        -- **And "anywhere" is the finger's own screen, not the page.** This row is
        -- the one the mistake showed up on first: a mark is in world coordinates
        -- and the pointer is in screen ones, so a finger held perfectly still while
        -- the player *walks* is a finger the page is sliding under, laying real
        -- line the whole time. A tap taken while running therefore read as a drag
        -- and did nothing, which is precisely the moment the tool exists for. What
        -- decides is `slack` and `hold` on the block below -- how far the hand went
        -- and how long it was down -- see Game:wasTap.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, ink = 1 / 230, life = 1.4,
        flow = { over = 150, floor = 0.5 },
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- The rubber's `crumbs` is deliberately not on this row, and it is the
        -- CRATER's lesson written down in advance: it is a rate *per brush stamp*
        -- of debris shed by a travelling tip, and a pencil laying a line is not a
        -- rubber travelling -- a graphite line that shed eraser crumbs the whole
        -- way down itself would be saying something false about what was drawing
        -- it. The tap throws its own ring of them instead, once, from the point it
        -- landed on (`Stroke:tap`), which is where the rubbing actually happened.
        --
        -- Built by the line's own unlock for the DECKLE's reason -- `scaleDamage`
        -- reaches `loop.damage`, `tap.damage` and `tap.ram.damage` by name, and
        -- `Tools.copy` is one level deep.
        loop = nil,
        tap = nil,
    },
    {
        name = "BLEED",
        icon = "bleed",
        -- PENCIL and HIGHLIGHTER, and the trade is stated in one sentence: the
        -- band gives up *touching* and buys *surrounding*.
        --
        -- A finished marker sets alight anything that so much as crosses its band,
        -- which is the level that let the tool hurt something that kept walking,
        -- and it lays 13 pixels of page to do it. This is the marker before it was
        -- broadened -- 9 across, the nib the tool was written with -- and nothing
        -- that walks over it catches at all. What catches is whatever the line
        -- *closes on*. Ring a crowd and the whole ring's worth of it is alight,
        -- standing in the middle of the band rather than on it, with the burn
        -- travelling with each body afterwards the way a burn always has.
        --
        -- So the row carries no `ignite` and its `loop` carries one instead, and
        -- that is the whole of the fusion. It is the CLEARING's kind of change --
        -- a fused row taking a *central* fact off a parent rather than adding to
        -- it -- and the argument is the same shape: a marker that both ignited on
        -- contact and ignited what it enclosed would have bought nothing with the
        -- pencil, since everything inside a ring you just drew has been touched by
        -- the drawing of it.
        --
        -- A bleed is what printers call ink running past the edge of the area it
        -- was laid for, which is what the tool does to whatever it draws a border
        -- round.
        radius = 5, damage = 5, knock = 0,
        spacing = 2, ink = 1 / 150, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        -- The marker's third level, and it is worth more here than it is there:
        -- the band is thinner, so scrubbing a patch is how you cover one, and the
        -- pooled-ink colour that marks a doubled pass is the only map of where the
        -- ring you are drawing has crossed itself.
        stack = 3,
        -- The pencil's, and this is the row that wants it most: the ring has to be
        -- drawn in one gesture to close at all, and this is the dearest ink of the
        -- five. Full price for the defensive scribble, half at the far end of a
        -- ring drawn round a crowd.
        flow = { over = 150, floor = 0.5 },
        -- Between the marker's 1/120 and the pencil's 1/230, because that is what
        -- the tool is: still a band of ink, and four pixels narrower than the one
        -- the marker's price was written for.
        ramp = { Palette.sky },
        stamp = markerStamp,
        edge = { stamp = markerEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- `loop.ignite` -- the marker's own burn, unnudged, delivered by the ring
        -- instead of by the band -- and `loop.wash`, which is the same event seen
        -- rather than felt: the middle of the ring floods with the band's own sky
        -- (`Stroke:drawWash`). It is not decoration. What this tool asks the player
        -- to do is judge an *area* they have drawn the border of, and a border with
        -- nothing inside it is a line -- you cannot see what you have caught, you
        -- cannot see where a body has to be to be caught next, and a ring that
        -- crossed itself looks exactly like one that did not. The wash is the tool
        -- telling you what it thinks it enclosed, and it is drawn by the same
        -- even-odd test the ignite is resolved with, so what is painted is what
        -- will burn.
        --
        -- Built by the line's own unlock for the DECKLE's reason: `scaleDamage`
        -- reaches `loop.ignite.damage` by name.
        loop = nil,
    },
    {
        name = "DRAG",
        icon = "drag",
        -- PENCIL and GLUESTICK, and the pun is the tool: to drag is what your
        -- finger does and what the line does back.
        --
        -- One of the gluestick's four levels acts on things the smear has *not*
        -- caught, and it is the finale -- everything free within reach of the ink
        -- is pulled towards the nearest of it. On a gluestick that is a way of
        -- gathering a crowd into a hold that cannot hurt it. Put the same field on
        -- a pencil and the field is feeding a *blade*: what it drags in lands on a
        -- line that cuts at 9, and goes on landing on it, because the ink does not
        -- stop being there.
        --
        -- So the hold, the softening and the tear are all gone, and that is the
        -- argument rather than a trim. The gluestick's whole written identity is
        -- that the smear never hurts what it holds -- three of its four levels are
        -- about what happens to something stuck -- and a thing dragged onto a
        -- pencil line does not need to be held there. What survives is the one
        -- level that was never about the hold.
        radius = 4, damage = 9, knock = 0,
        spacing = 1, life = 1.4,
        -- The gluestick's, and the reason is that the field is what you are
        -- buying, not the graphite: this is a pencil that charges paste prices.
        -- With `flow` it eases to 1/180 down a long line, which is the shape the
        -- tool wants -- one committed stroke through the middle of a crowd, not a
        -- page full of short ones.
        ink = 1 / 90,
        flow = { over = 150, floor = 0.5 },
        -- The gluestick's, and the row cannot work without it: a pencil hits an
        -- enemy once and never again, so a line that dragged the crowd onto itself
        -- and then cut each body a single time would be a worse pencil. On the
        -- gluestick's own cadence, so the line keeps cutting for as long as the
        -- field keeps feeding it.
        rehit = 0.4,
        -- 42 where the gluestick writes 26, and it is the same field measured off
        -- a different nib rather than a number that was nudged. `Stroke:pullTowards`
        -- reaches `radius + range`, and a finished gluestick is a 20px head with 26
        -- of range on it: 46 from the ink. This is a 4px point, so 42 puts the edge
        -- of the field in exactly the same place. The reach the crowd feels is the
        -- gluestick's to the pixel; what changed is that the ink at the middle of
        -- it is sharp.
        pull = { range = 42, speed = 30 },
        -- **Grey, and one colour rather than a ramp**, which is the one place this
        -- row does not look like the pencil it is. A tool that drags the crowd onto
        -- its own line has to let you see the line under a crowd standing on it,
        -- and ink -- the darkest thing on the page -- is the one colour a body
        -- covers completely. Graphite is the paste the gluestick lends read as a
        -- line: pale enough to stay visible with something on top of it, and the
        -- colour a smear goes at its rim.
        --
        -- One entry for the highlighter's and the gluestick's reason: a wash has
        -- nowhere to step, so the fade is the dither alone and the line simply
        -- thins out of the paper rather than darkening on its way off it, which
        -- would be the wrong way round for something drying.
        ramp = { Palette.graphite },
        stamp = pencilBroadStamp,
        -- Paper rather than graphite, and it is the one flake in the game that is
        -- lighter than the mark it comes off: what the point is shedding is paste,
        -- not lead.
        speck = { chance = 0.10, color = Palette.paper },
        -- The pencil's, not the gluestick's 0 and not the pencil's own 24. Both
        -- parents write a number here and this is the one field where the
        -- fusion's own argument settles it rather than either parent: a shove
        -- throws back out what the field just pulled in, so the two halves of the
        -- tool would be spending the frame undoing each other.
        loop = nil,
    },
    {
        name = "CUTOUT",
        icon = "cutout",
        -- PENCIL and SCISSORS, and it is the scissors' last level with a shape you
        -- drew round it instead of a straight line through the page.
        --
        -- **Nothing inside the ring is hurt.** It is taken off the paper with the
        -- paper and put down again in the corner of the page furthest from you --
        -- no gem, no xp, no kill, nothing split and nothing burst, because nothing
        -- died (`Game:liftEnemyTo` is the whole contract, and it is the same call
        -- the offcut makes). Which means the row inherits the scissors' bargain
        -- along with the scissors' effect, and the bargain is the point: a cutout
        -- does not spend the crowd it rings, it *stacks* it, so what you get back
        -- is one clump walking in from one direction instead of a page full of
        -- monsters -- and you get it back.
        --
        -- The pencil's finale was already the one thing on the strip that claims an
        -- area by drawing its border, and it claimed it for 4 damage -- chaff, a
        -- chip off a skull -- because the ring costs nothing beyond the line you
        -- were already paying for. This says the quiet part: a border you can draw
        -- round anything at all cannot be allowed to *kill* anything at all, so it
        -- does something absolute instead and pays for it in the only currency the
        -- run cannot buy back.
        --
        -- What a hand can ring is smaller than what a cut can halve, and that is
        -- the trade against the parent rather than a limitation: the scissors take
        -- half a page in one tap and cannot choose its shape, and this chooses the
        -- shape exactly and has to walk round it while the crowd walks too.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, ink = 1 / 230, life = 1.4,
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- **The pencil's `flow` is the one parent's number this family throws
        -- away**, and it is the CORRAL's rule rather than the LASSO's: it would be
        -- read here, and it would lie. A discount that deepens the longer the line
        -- runs is a discount on *how much page you ring*, and on a row that lifts
        -- what it rings that is the one axis nothing may sell. The meter is what
        -- limits how much page a run can take off the page -- the scissors' own
        -- argument in their own last level -- and a level that makes the biggest
        -- ring the cheapest one per pixel would be undoing it.
        --
        -- What is left is the pencil's flat 1/230, which is a real price at this
        -- shape: a ring wide enough to hold a crowd is most of a full meter of
        -- perimeter, and you are drawing it while they walk.
        --
        -- Written here rather than built by the line's unlock, which makes it the
        -- one row of the five that may say what its ring does outright -- and it is
        -- the PUNCH's reason above, one shape over. What a severed region does to
        -- the crowd is move it rather than hurt it, so there is no damage in this
        -- table for `scaleDamage` to find and nothing shared for it to compound.
        --
        -- **`tick` rather than a flag, and it is the scissors' own number and the
        -- scissors' own contract.** A hole in the page is not a thing that emptied
        -- itself once -- it is a piece of page that is not there, so it goes on
        -- answering for whatever walks into it, on the same half-second the offcut
        -- uses (`Stroke:sweepRings`). Which is also what makes the grey honest:
        -- there is page missing for exactly as long as the ring is on the paper,
        -- and the mark's own second and a half is the meter's limit on how much
        -- page a run can take away, which is where that limit belongs.
        loop = { lift = { tick = 0.5 } },
    },
    {
        name = "STITCH",
        icon = "stitch",
        -- PENCIL and STAPLER, the sixth of the family and the second row in it
        -- that is a different tool depending on whether your finger moves.
        --
        -- The STUB got there first and it got there the other way round: a pencil
        -- with a rubber on the end, so the tap is the *panic* and the drag is the
        -- work. Here the tap is the work and the drag is what the work is *for*.
        -- Tap and a staple lands, exactly as it lands off a stapler. Drag and you
        -- draw the finished pencil's line, with a staple driven at each end of it.
        --
        -- **A stitch is what a stapler makes** -- the trade calls the folded wire a
        -- stitch, and a saddle-stitched book is a sheaf held by two of them through
        -- the fold. That is the row: a line fastened at both ends, which is a thing
        -- a person actually does to paper and the only shape in this family that is
        -- not a ring.
        --
        -- **Every staple crits, and it is the stapler's own argument turned round
        -- rather than a number being handed out.** The parent rolls one in five,
        -- and its row says why in as many words: a one-in-five on something you tap
        -- dozens of times a page is a *rate*, honest because the sample is large,
        -- where the same roll on a pin you get two of from a full meter would only
        -- ever be a story about that one pin. This tool gets two per gesture. So a
        -- fifth here would be exactly the thing the pushpin's row refuses, and the
        -- chance goes to 1 for the reason it was set to 0.2 -- the roll has to match
        -- the sample. Nothing else about the staple moves: 6 through a triple is the
        -- parent's 18, which takes a skull, an eye and a blot outright and leaves
        -- the grin standing, and the tank of the table goes on being the thing you
        -- cannot staple your way out of.
        --
        -- **What pays for it is `rake`.** The stapler's finale is the one level in
        -- the catalogue that changes a gesture -- hold and drag and you run a seam,
        -- ten a meter, a third of the page. This row does not have it and could not:
        -- the drag is already spent, on the pencil. So the trade is stated in the
        -- one field that is missing rather than in a number -- thirty staples along
        -- a line you dragged, or two at the ends of one you drew, and the two of
        -- them go through whatever they land on.
        radius = 4, damage = 9, knock = 24,
        spacing = 1, ink = 1 / 230, life = 1.4,
        flow = { over = 150, floor = 0.5 },
        ramp = { Palette.ink, Palette.slate, Palette.graphite },
        stamp = pencilBroadStamp,
        speck = { chance = 0.10, color = Palette.graphite },
        -- The pencil's finale, built by the line's own unlock for the DECKLE's
        -- reason, and it is worth having here for a reason none of the other four
        -- share: a ring drawn with this is a ring with a staple at the place it
        -- closed, so the one body that was standing where your finger stopped is
        -- held there while everything inside is cut.
        loop = nil,
        -- And the staple itself, also built by the unlock -- `scaleDamage` reaches
        -- `fasten.damage` by name and Tools.copy is one level deep, which is the
        -- SEAM's `snap.wire` exactly one storey out.
        --
        -- On the *row* rather than inside a block, because there is no block on this
        -- row: the gesture is the stroke, and `fasten` is what the stroke is
        -- fastened down with. It is the same reading the ruler's family gives a
        -- second shape -- what the gesture leaves along the line it laid -- with the
        -- line drawn by a hand instead of ruled, and the two ends of it rather than
        -- the whole. `Game:fastenEnds` is the whole of what reads it.
        fasten = nil,
    },
    -- **The same family with the pencil taken out of it**, which is the other
    -- fifteen pairs and the one question all fifteen ask.
    --
    -- The six above are the stroke as a carrier, and the pencil owned that family
    -- because it owned all three of the things a drawn line is: it is the cheapest
    -- ink in the game, it is the tool every run opens holding, and its finale is
    -- the only level on the strip that claims an *area* by drawing the border of
    -- one. Pair it with anything and the answer writes itself -- the pencil is the
    -- body, and the second parent is what the line is made of or what closing it
    -- means. Nothing about the drawing changes in any of the six.
    --
    -- Take the pencil out and that decision stops being free. Two brushes, both of
    -- them a nib with a price and a clock and a thing the mark does afterwards, and
    -- **nothing in the pair says which of them is the line.** Written blind, a
    -- fused brush is two rows averaged: a nib of some middle width in a colour
    -- neither parent uses, doing a bit of both jobs, and the honest thing to say
    -- about it is that a run holding one could not tell you what it had.
    --
    -- So the three rows below are one rule tried three times, and it is the MOAT's
    -- rule off the arm and onto the page: **one parent's mark is the body, and the
    -- other parent is what happens at it.** Which one is the body is not a
    -- preference -- it is whichever parent's mark is a *place*. A pen line is
    -- terrain, a marker band is a surface, and both of those are somewhere a body
    -- can be; a rub is an event that happens to whatever is under the tip and is
    -- nowhere at all once it is over. So the pen writes the body twice here and the
    -- marker writes it once, and the rubber -- which is nobody's body, in either of
    -- the pairs it is in -- writes what the place does to whatever comes to it.
    --
    -- **And when the second parent cannot be what happens at the place, it becomes
    -- the other gesture.** That is the STUB's shape and the SCUFF below is the
    -- second row in the game to take it: a rub delivered *by* a band would either
    -- be the band shoving, which is a band nobody can stand on, or the nib shoving
    -- as it goes past, which is a rubber that has to be scrubbed and is a rubber
    -- already. Tap and drag are two gestures and the release can tell them apart
    -- (`Game:wasTap`), so a pair with nothing to give each other inside one mark
    -- gets one each.
    {
        name = "BUMPER",
        icon = "bumper",
        -- PEN and RUBBER, and it is the one sentence the pen has been arguing
        -- against since it was written: a fence that shoves.
        --
        -- The row it is fused from says so in as many words -- "a fence that shoves
        -- is not a fence" -- and that is still true of a *pen*, where the shove
        -- would be worst exactly where the tool is best, throwing the crowd back
        -- out of the corner you had just walled them into. What makes it true there
        -- and false here is which way the shove points. A nib shoves along its own
        -- travel and away from wherever the hand happens to be; a *wall* shoves out
        -- of itself, and out of a wall is the one direction on the page that never
        -- needs aiming, because the fence already knows which side of it you are
        -- on. `Stroke:apply` has always pushed away from the line rather than along
        -- it, for the eraser's sake, and this row is that arithmetic finally being
        -- the point of something.
        --
        -- So the crowd does not lean on this fence: it comes off it. 240 out of the
        -- ink is the finished rubber's throw, 27 pixels of it, and what that sends
        -- flying knocks down whatever it lands on -- which is the fusion's whole
        -- damage and the reason the numbers on the row are so small. A rank pressed
        -- against a wall by the rank behind it is a magazine of projectiles aimed
        -- at its own crowd, and the fence is what keeps the magazine loaded.
        --
        -- A bumper is what a printer calls the guard that stops a sheet running
        -- past its stop, and what everything else calls the thing you bounce off.
        radius = 4, damage = 2, knock = 240,
        wall = true,
        -- The pen's contact level and the whole of its machinery unchanged, because
        -- the tick is what delivers the bounce: `graze` is the two pixels of slack
        -- a wall needs to be measurable at all (Enemy:resolveWalls parks a body at
        -- *exactly* the ink's edge), and `rehit` is what makes one bounce one
        -- event -- half a second is longer than it takes a shoved body to land and
        -- start walking back, so nothing is juggled on the spot.
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        -- 2 is the rubber's own chip and there is no `sting` beside it, which is
        -- the DECKLE's field being *unnecessary* rather than forgotten. It exists
        -- because a pencil charges 9 to be drawn over and a pen charges 1 to be
        -- leaned on, and nine times is a difference a row has to say out loud. Here
        -- the nib chips 2 and the fence chips 2, and on this row they are the same
        -- event twice over: bumping into the line and being drawn over by it are
        -- both the ink arriving where a body was. The damage was never this tool's
        -- job in either parent -- the pen's line does 1 and the rubber's line does
        -- 2, and both of them are terrain with a temper.
        spacing = 1, ink = 1 / 170, life = 9,
        smooth = 26,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        speck = { chance = 0.10, color = Palette.sky },
        -- **Two of the rubber's four levels are deliberately not here**, and both
        -- are missing for the same reason rather than for balance. `lean` is the
        -- tip going on hitting where it rests, which is what a rubber needs to stop
        -- being a tool you have to scrub -- and this row's mark already hits
        -- everything against it on its own clock, along its whole length, for nine
        -- seconds after the finger has gone. A resting hit at the nib would be the
        -- same hit, priced twice. `scrub` is half price over ground this stroke has
        -- already covered, which prices a back-and-forth: you do not rub a fence
        -- back and forth, you draw it once and leave, so the discount would sit on
        -- the row describing a motion the tool cannot make. The LASSO's rule --
        -- leave out a parent's number nothing on the fused row would read.
        --
        -- The rubber's `crumbs` goes for the CRATER's reason, spelled out on the
        -- STUB: it is a rate per brush stamp of debris off a travelling tip, and a
        -- ballpoint laying a wall is not a rubber travelling. A fence that shed
        -- eraser crumbs down its whole length would be saying something false about
        -- what drew it.
        --
        -- The pen's third level and the rubber's finale, both built by the line's
        -- own unlock (src/upgrades.lua) rather than written here: `scaleDamage`
        -- reaches `pop.damage` and `ram.damage` by name and `Tools.copy` is one
        -- level deep, so a table the sharpener writes into has to be built fresh on
        -- the run's copy every rebuild or the multiplier compounds into this shared
        -- row.
        pop = nil,
        ram = nil,
        -- The pen's finale, and this is the row that wants it most of the three
        -- that have it. `keep` holds the last line you drew with no clock on it at
        -- all, and what is held here is not a wall you have to keep paying for --
        -- it is a wall that is *doing* something to everything the horde walks into
        -- it. Held down by the same clause as everywhere else: drawing the next one
        -- is what lets the last go, so the page cannot be latticed shut, and what
        -- is released fades on its ordinary nine seconds and then pops.
        keep = true,
    },
    {
        name = "SWELL",
        icon = "swell",
        -- PEN and MARKER, the two tools that share a colour and have never once
        -- been mistaken for each other -- 3 pixels of solid blue you draw to keep
        -- something out, against 13 of sky band laid under the crowd to burn it.
        -- What they turn out to share is the thing neither of them can do alone: a
        -- pen's mark lasts nine seconds and does almost nothing to anybody, and a
        -- marker's mark does a great deal and is gone in three and a half.
        --
        -- **So the body is the pen and the clock is the pen's, and what the mark
        -- does is the marker's.** Nine seconds of burning band is the fusion in one
        -- number, and it is the pen's number rather than a new one.
        --
        -- **Then the second half, which is the only mechanic in the family that is
        -- about the hand rather than about the ink.** A swelled rule is a printer's
        -- rule that is heavy in the middle and tapers to nothing at its ends, and
        -- it is the shape a nib with a soft tip actually leaves: press on, and the
        -- faster it travels the less of it touches the paper. This row is that.
        -- Drag slowly and you lay the pen's broad nib, 7 pixels of blue, at the
        -- pen's full price by the pixel; flick and you lay the ballpoint the tool
        -- was written with, 3 pixels wide, for half the ink (`pace` at the head of
        -- this file).
        --
        -- Which is a *choice inside a stroke*, and it is the first one the drawing
        -- has ever had. Every other brush in the game is priced by the pixel and
        -- nothing else: a line costs what its length costs, and how you moved your
        -- hand along it changed the shape of the mark and never its worth. Here the
        -- same meter buys either a short heavy band you meant to put somewhere or a
        -- long thin one you got out of the way with, and both readings are correct
        -- -- a thin stretch still burns whatever crosses it, on the same clock, for
        -- the same nine seconds. What it will not do is both at once, which is what
        -- makes it a decision rather than an upgrade.
        radius = 4, damage = 5, knock = 0,
        -- The marker's second level (5 is a blob in one tick instead of two) on the
        -- marker's own cadence, and the pen's price, spacing, nib-lag and clock.
        -- Both parents write `ink` and the pen's is dearer, which is the body
        -- deciding it the way the body decides everywhere in this family: what is
        -- being laid is a pen line, and a pen line has always cost what it costs.
        rehit = 0.35, linger = true, tickRate = 0.35,
        spacing = 1, ink = 1 / 170, life = 9,
        smooth = 26,
        -- 130 pixels a second is the threshold, and it is picked off the two things
        -- a hand does on this page rather than out of the air: a line you are
        -- *placing* -- across a doorway, round the front of a crowd -- is drawn at
        -- something under a hundred, and a line you are getting rid of, a flick
        -- across the screen to put ink between you and something, is three or four
        -- hundred. There is very little traffic in between, which is what makes a
        -- threshold honest here where a continuous taper would only have been
        -- prettier: the tool has two states because the hand has two intentions.
        pace = { over = 130, thin = 2 },
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = pacedStamp(penWideStamp, penStamp),
        speck = { chance = 0.06, color = Palette.sky },
        -- **The marker's `stack` is not here and the omission is the pace's fault**,
        -- which is worth writing down because it looks like a level going missing.
        -- Layers stacking where you draw over your own ink is only a level a player
        -- can use if they can see where the ink is doubled, and what makes it
        -- visible on a marker is the *rim*: a dab laid back over the band's own
        -- ground is drawn in the pooled-ink colour (Stroke:draw). A ballpoint has
        -- no rim to pool in -- the pen's nib is one flat colour by design -- so on
        -- this row the level would be an invisible tripling of the burn wherever
        -- two stretches of line happened to cross. The marker's own row says it: a
        -- choice you cannot see is not one you can make.
        --
        -- The marker's finale, built by the line's own unlock for the BUMPER's
        -- reason -- `scaleDamage` reaches `ignite.damage` by name.
        ignite = nil,
    },
    {
        name = "SCUFF",
        icon = "scuff",
        -- RUBBER and MARKER, and the third row in the game that is a different tool
        -- depending on whether your finger moves. The STUB was the first and this is
        -- its mirror: there a pencil with a rubber crimped to the ferrule, here the
        -- same nub on the end of a marker, which is the other object on the desk
        -- that has one.
        --
        -- Drag and it is the finished marker, unchanged in every number: 13 pixels
        -- of band laid under the crowd, 5 a tick to whatever stands on it, layers
        -- where the passes cross, and anything that so much as touches it alight
        -- for two seconds. Tap -- press and lift without travelling -- and it is
        -- the finished rubber instead, the whole of it in one press: a 7px circle
        -- at the point your finger landed on, 240 of shove thrown radially out of
        -- it, and what that sends flying knocking down what it lands on.
        --
        -- **It is the tap/drag split being a rule rather than a coincidence.** The
        -- STUB earned it by argument -- a pencil is a line you commit to and has no
        -- gesture for "not now", a rubber is that gesture and nothing else -- and
        -- the argument turns out to be about the *rubber* and not about the pencil.
        -- A rub is an event at a point, and there is no honest way to fold one into
        -- a mark that has to be somewhere: a band that shoved would be a band
        -- nobody could be made to stand on, which is the only thing a marker's
        -- levels are about, and a nib that shoved as it went past is a rubber you
        -- have to scrub, which is the rubber you already had. So the pair gets a
        -- gesture each, and the marker keeps every one of its four levels because
        -- nothing was taken off it to pay for the tap.
        --
        -- What pays for it is the meter. The band is the dearest ink in the
        -- catalogue by the pixel and the tap is a flat tenth of the well on top of
        -- it, so the two gestures are drawing on one well and a page you have
        -- scribbled over is a page you cannot shove anybody off. That is the whole
        -- of the tension in the row, and it is the STUB's too -- there against the
        -- cheapest ink in the game, which is why that one is a panic button and
        -- this one is a decision.
        --
        -- A scuff is the mark a rubber leaves on paper it has been dragged over
        -- rather than rubbed at, which is the pair of them in one word.
        radius = 7, damage = 5, knock = 0,
        spacing = 2, ink = 1 / 120, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        stack = 3,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- The rubber's `crumbs` is not on this row for the STUB's reason, and it
        -- reads even more plainly here: a rate per brush stamp of debris shed by a
        -- travelling tip, on a tool whose travelling tip is a chisel laying a wet
        -- band. The tap throws its own ring of them, once, from the point it landed
        -- on (`Stroke:tap`) -- which is where the rubbing actually happened.
        --
        -- The marker's finale and the whole of the finished rubber, both built by
        -- the line's own unlock for the BUMPER's reason: `scaleDamage` reaches
        -- `ignite.damage`, `tap.damage` and `tap.ram.damage` by name, and
        -- `Tools.copy` is one level deep.
        ignite = nil,
        tap = nil,
    },
    -- **The gluestick's three, and they finish the brushes.** With these on the
    -- list every pair of brushes in the game has a row -- pen, rubber, marker and
    -- gluestick, six pairs, all six written -- and every pair still missing is a
    -- brush with a *block*: four with the stapler, four with the scissors, and the
    -- stapler with the scissors.
    --
    -- They are also the rule above tested where it is hardest, because the
    -- gluestick wins the body against all three of the others and one of those
    -- three is a *fence*. A pen line is terrain and a smear is a hold, and both of
    -- those are places, so "whose mark is a place" cannot settle PEN + GLUESTICK on
    -- its own. What settles it is that a smear is the stronger place: a fence says
    -- where a body may not stand, and paste says where a body *is standing and will
    -- go on standing*. So the paste is the mark in all three rows, and the second
    -- parent turns into a property of it rather than a shape of its own -- the pen
    -- makes the paste solid, the rubber turns it into a drain, the marker makes it
    -- burn. That is the honest version of the rule and it is worth having in this
    -- order: the fence is the one parent that could have argued, and it lost to the
    -- one thing a fence has never been able to do.
    --
    -- **All three are the widest mark a hand can draw, and that is the ceiling they
    -- share.** 20px of head is 41 across, at the dearest ink in the catalogue by the
    -- pixel, which means a hand-drawn ring of any of these is most of a full meter
    -- and no run gets two. Nothing had to be balanced against that; it is the
    -- gluestick's own price doing what it has always done, and it is why these three
    -- can afford to be the strongest crowd control on the strip.
    {
        name = "PASTEDOWN",
        icon = "pastedown",
        -- PEN and GLUESTICK: paste that has set hard. Nothing gets in and nothing
        -- gets out, and both halves of that are one flag.
        --
        -- **What is inside stays inside because it is stuck**, which is the glue
        -- unchanged -- the freeze is re-applied on every tick, so a body caught in
        -- the smear is held for as long as the smear is on the paper. **What is
        -- outside stays outside because the paste is a wall**, which is the pen: the
        -- mark is filed as terrain at the head's own radius (`Walls:rebuild`), so
        -- the crowd steers round it and `Enemy:resolveWalls` parks anything that
        -- reaches it at the ink's edge rather than letting it through.
        --
        -- And then the two fit together without a line of new code, which is the
        -- test a fusion of two finished lines is supposed to pass. `Enemy:resolveWalls`
        -- returns early on a *frozen* body -- it was written that way so the crowd
        -- could jam up against a glued thing instead of squeezing it out of the
        -- smear -- so the bodies the paste has caught are exactly the bodies the wall
        -- does not eject. The hold and the fence agree about who is inside.
        --
        -- **The crowd outside gets stuck to the outside face**, and that is the
        -- glue's finale meeting the pen's: `pull` hauls everything free within reach
        -- towards the ink, the wall stops it at the rim, and the tick that would
        -- have caught it in the middle of the smear catches it there instead -- held
        -- against the outside of the paste, taking 1 a tick for leaning on it. A
        -- rank stuck to the wall is a rank that has stopped walking, which is a
        -- second fence made out of the crowd.
        radius = 20, damage = 0, knock = 0,
        wall = true,
        spacing = 2, ink = 1 / 90, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        -- The pen's contact level, and the DECKLE's field is what carries it: this
        -- row's `damage` is the gluestick's 0 -- being drawn over by paste has never
        -- hurt anybody and must not start -- and `sting` is the 1 a tick the pen
        -- charges for leaning on a finished fence. Two numbers because two tools
        -- wrote them, and the placement is the one `pop` and `loop` already use.
        -- `graze` is the two pixels of slack the tick needs to be measurable at all,
        -- for the pen's own reason: a body parked at *exactly* the ink's edge lands
        -- or misses on floating-point luck.
        graze = 2,
        sting = 1,
        -- The gluestick's line, whole. Safe on the row for the MOAT's reasons:
        -- `soften` is read and never written, `tear` is a bare number so the
        -- sharpener multiplies the run's own copy of it, and nothing anywhere writes
        -- into `pull`.
        freeze = 0.55,
        soften = 1.5,
        tear = 4,
        pull = { range = 26, speed = 30 },
        -- **Dark blue, and the ramp is the pen's rather than a colour picked.** The
        -- glue's own paste is paper -- white, with a grey rim -- and white is the
        -- one thing this mark must not be: it is terrain now, and the crowd has to
        -- read it as terrain the way it reads a pen line. Blue for most of its life
        -- and pale sky in the last stretch, on the pen's `fade`, so the fence still
        -- goes visibly thin before it stops stopping anything -- which matters more
        -- here than it does on a pen line, because what a body does when this mark
        -- goes is walk out of a prison. The rim is ink rather than the glue's
        -- graphite: grey on blue is two mid-tones and the edge of a wall is not a
        -- thing to be vague about.
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.ink, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        -- The pen's third level, built by the line's own unlock (src/upgrades.lua)
        -- because `scaleDamage` reaches `pop.damage` by name and `Tools.copy` is one
        -- level deep. It is worth more here than on any other row that has it: what
        -- the paste comes off the page with is everything it was holding, and 4
        -- along the whole line lands on a crowd that has not moved since it was
        -- caught.
        pop = nil,
        -- The pen's finale. One gesture's worth of paste held with no clock on it,
        -- and drawing the next is what lets the last go -- so the page cannot be
        -- latticed shut, and what is released fades on its ordinary six seconds and
        -- then pops, which makes replacing your own prison the way you empty it.
        --
        -- **What holds it down is the meter and not a clause.** A wall of paste is
        -- 41 pixels across at 1/90 a pixel, so one that encloses anything at all is
        -- most of a full well: a run cannot draw a second while the first is up, and
        -- the thing being kept is one stroke's worth of page rather than a fortress.
        keep = true,
    },
    {
        name = "PULP",
        icon = "pulp",
        -- RUBBER and GLUESTICK, and it is the CLEARING read backwards.
        --
        -- That row is the rubber on a compass: the leg wipes the disc as it comes
        -- round and everything inside is thrown *straight out of it*, because a
        -- rubber shoves away from itself and away from the needle is the only
        -- direction a disc has. This one points the same idea at the mark instead:
        -- everything near the paste is hauled *into* it and stuck there. One row
        -- empties a place, the other fills one, and the two are the same tool
        -- reversed rather than two ideas.
        --
        -- **The reversal could not be a `knock`, and finding out why is what wrote
        -- this row.** The obvious version is the rubber's shove with its sign
        -- flipped -- push towards the line rather than away from it -- and it does
        -- nothing at all: `Stroke:apply` knocks and *then* freezes, in that order,
        -- in the same call, and a frozen body drops the push it was carrying on its
        -- next update (`Enemy:update`). A shove that lands a body in paste is a
        -- shove the paste cancels. So the shove had to become a haul, and the
        -- gluestick already had the field for one.
        --
        -- Which turns out to be the better tool anyway: 240 is the rubber's throw,
        -- and a throw is over in a fifth of a second where a haul goes on for as
        -- long as the paste is on the page. What the row does is drag the crowd in
        -- continuously, hold it, and let you scrub the pile.
        radius = 20, damage = 2, knock = 0,
        spacing = 2, ink = 1 / 90, life = 6,
        -- The rubber's cadence rather than the glue's, and the two are doing
        -- different jobs: `tickRate` is the mark re-applying a hold every 0.4, and
        -- `rehit` is how often the *tip* may hit the same body -- which on this row
        -- is the whole of the damage, so it is the rubber's 0.3 and not the paste's.
        rehit = 0.3, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        soften = 1.5,
        tear = 4,
        -- **The rubber's 240 as a speed instead of an impulse, pointed the other
        -- way.** The gluestick's own haul is 30 -- picked to sit between a skull's
        -- legs and a bat's, so the heavy things cannot walk out of the field and the
        -- fast ones can -- and this one is the shove, so nothing walks out of it at
        -- all. `range` does not move: a 240 shove throws a body 27 pixels (the push
        -- decays at exp(-9t), so distance is force/9) and the glue's field already
        -- reaches 26 past the ink, which is the same arm's length read from the
        -- other end. The rubber does not reach further than the paste, it pulls
        -- harder.
        pull = { range = 26, speed = 240 },
        -- **The one place the rubber's `scrub` is the right field on the row**, and
        -- the BUMPER is the contrast worth reading beside it. There the discount
        -- priced a back-and-forth a fence cannot make -- you draw a wall once and
        -- leave. Here back-and-forth is the entire tool: the paste is laid, the
        -- crowd is hauled into it, and what you do next is rub the same patch until
        -- the pile is dead. Half price over ground this stroke has already covered
        -- is a discount on the motion this row is actually used with.
        scrub = 0.5,
        -- The glue's own paste, unchanged: what a rubber leaves is nothing, so there
        -- is nothing of the rubber to see and no reason to recolour a smear. Its
        -- `crumbs` stay off the row for the STUB's reason -- a rate per brush stamp
        -- of debris shed by a travelling tip, on a tip that is a 41px head of wet
        -- paste.
        ramp = { Palette.paper },
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        -- **The rubber's finale is not here and cannot be.** `ram` makes what a
        -- shove sends flying a weapon while it flies, and this row's shove does not
        -- send anything flying -- it brings it, and what arrives is frozen the
        -- moment the tick catches it. `Game:updateRams` measures a push speed and
        -- there is no push: `Enemy:launch` would be set on a body that never has one
        -- and cleared unread. So the trade is a missing field rather than a nudged
        -- number, the STITCH's shape -- the finale is what pays for the reversal,
        -- and the reversal is the row.
        --
        -- Which leaves nothing for an unlock to build, the MOAT's case exactly:
        -- every table on this row is read and never written, so there is no `apply`
        -- on the line at all (src/upgrades.lua).
    },
    {
        name = "MORDANT",
        icon = "mordant",
        -- MARKER and GLUESTICK: paste that bites.
        --
        -- A mordant is the size a gilder lays down to make gold stick, and the word
        -- is *mordere* -- to bite. It is the one name in the catalogue that was
        -- already both halves of its own row before anybody used it for a tool: an
        -- adhesive whose name means biting, on a row that is an adhesive that bites.
        --
        -- The trade is the shortest in the family. The gluestick is the strongest
        -- crowd control in the game and deals nothing -- that is its whole identity,
        -- and three of its four levels are written so that the *damage comes from
        -- somewhere else*: what it holds takes deeper cuts, what comes loose comes
        -- away torn, and neither is the smear hurting anybody. This row is the
        -- somewhere else. 5 a tick is the marker's second level, on the marker's own
        -- cadence, delivered by 41 pixels of paste that has already stopped whatever
        -- it is delivering to -- and the softening applies to it like it applies to
        -- everything, so a body held in its own paste takes 7.5 rather than 5.
        --
        -- Sky, with the band's blue where the ink pools at the rim: the marker's two
        -- colours on the gluestick's shape, which is what the tool is. The overprint
        -- pass does the rest -- sky over the ruling comes out blue and blue comes out
        -- slate -- so the smear darkens over a rule exactly as the marker's band
        -- always has.
        radius = 20, damage = 5, knock = 0,
        spacing = 2, ink = 1 / 90, life = 6,
        -- The marker's, not the glue's, and for the PULP's reason read the other
        -- way: on that row the tick is a hold being re-applied and the damage is the
        -- tip's, so the cadence is the rubber's; here the tick *is* the damage, so
        -- the cadence is the marker's, which is the pace the number 5 was written
        -- against.
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        freeze = 0.55,
        soften = 1.5,
        tear = 4,
        pull = { range = 26, speed = 30 },
        ramp = { Palette.sky },
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.blue, rough = 0.45 },
        -- Blue rather than the glue's sky: a sky speck thrown off a sky band is a
        -- particle nobody can see.
        speck = { chance = 0.08, color = Palette.blue },
        -- **Two of the marker's four levels are deliberately not here**, and both
        -- are the pairing making them redundant rather than a trim.
        --
        -- `ignite` is the finale, and the marker's own line says what it is for in
        -- as many words: it buys the one thing the tool could never do -- hurt
        -- something that *kept walking*. Nothing that touches this mark keeps
        -- walking. It is stuck, in the middle of a band that is already ticking at
        -- it, for as long as the band is on the page. A burn that travels with the
        -- body would be travelling nowhere, which is the BLEED's argument arriving
        -- from the other side: a fused row may take a central fact off a parent when
        -- the pairing has already bought what that fact was for.
        --
        -- `stack` is the level that pays for drawing over your own ink, and on a
        -- head this wide the test that drives it stops meaning what it means.
        -- `Stroke:revisits` asks whether the head is back over ground this stroke
        -- has already covered; on a 13px band at 2px spacing that is a *deliberate*
        -- second pass, and on a 41px one it is any curve at all -- steer a smear a
        -- few pixels sideways and nearly every dab lands on covered ground. The
        -- level would read as a permanent tripling rather than as a reward for a
        -- motion, and the pooled-ink colour that is supposed to be the map of it
        -- would be most of the mark.
        --
        -- So nothing is left for an unlock to build here either: no `ignite`, no
        -- table on the row that the sharpener writes into, and no `apply` on the
        -- line (src/upgrades.lua).
    },
    -- **The stapler's four, and they are the first rows in this family whose
    -- gesture is not a stroke.** The twelve above are all a line you drag: the
    -- pencil's six and the six brush pairs, press-drag-lift, charged by the pixel.
    -- Nine pairs were left over after those and every one of them is a brush with a
    -- *block* -- a tool with no line in it at all -- which is the wall the family
    -- was always going to hit. You cannot make the stroke the carrier when one
    -- parent has no stroke.
    --
    -- **So the carrier goes back to being the gesture, and what is new is which
    -- one.** The stapler is the only block on the strip whose gesture is a *drag*:
    -- `rake` is its finale and it lays a staple every twelve pixels for as long as
    -- you hold. That is a path across the page, laid by a hand, at a fixed spacing
    -- -- which is a stroke in everything but name, and it is the thing these rows
    -- borrow. Two of them hang a mark off it (`thread` with `LINK`'s fourteen-pixel
    -- reach, so each staple rails to the next one and to nothing else) and the
    -- third puts paste on the wire instead.
    --
    -- Which makes them the pushpin's threading family with one number changed, and
    -- the pair is worth reading together: at the pin's 120 a handful of taps is a
    -- *shape you build*, and at the stapler's 14 thirty presses are a *line you
    -- drag*. Same field, same function, same code. The STOCKADE and the CORDON are
    -- the shapes; the PALING and the WICK are the lines.
    --
    -- **The first three ask for a finished SELLOTAPE**, which the twelve above do not, and
    -- the switch back is the honest one. The ink lines were the right catalyst for
    -- rows a hand draws -- every one of the twelve is priced by the pixel, and the
    -- meter is the only thing between a brush and the whole page. Not one of these
    -- three is priced by the pixel: they are priced by the press, ten to a meter,
    -- exactly as their parent is. (The fourth is priced *both* ways, which is what
    -- sends it to a different line -- see the SNAG.) What the tape pays a run for is
    -- *time*, which is what a run that put ten levels into two tools has been
    -- spending, and it is
    -- given back untouched on its own terms.
    --
    -- RUBBER + STAPLER is the fourth, and it is the one this family could not write
    -- for a long time. The trouble was real: a rub is an event at a point and a
    -- staple is a fastener at a point, so a *seam* of them is either two things
    -- happening in the same place or -- worse -- a shove that undoes the fastening it
    -- was raked beside. Both readings are a row arguing with itself.
    --
    -- What settled it is that the second reading is not a bug, it is the tool. If a
    -- rub undoes a fastening then the rub is what *takes the staple out*, and the
    -- stapler already had a level about the wire coming out and biting on the way
    -- (`prise`). So the seam was the wrong carrier and the answer was the STUB's:
    -- a gesture each. See the SNAG at the foot of this family.
    {
        name = "PALING",
        icon = "paling",
        -- PEN and STAPLER, and the pen's *third* answer to the same question. The
        -- CORRAL is a fence with no ends, ruled where your hand is not; the STOCKADE
        -- is a fence you build post by post; this is a fence you **drag**.
        --
        -- Which is the one shape the other two cannot make. A corral is whatever
        -- circle the compass opened, and a stockade is a rail between two taps you
        -- placed one at a time -- deliberate, expensive, and slow enough that the
        -- crowd gets to walk between the posts while you are still placing them.
        -- Here the posts land every twelve pixels of your own drag and the rail
        -- follows them, so a hundred and forty pixels of fence is one gesture and
        -- goes down at the speed of a hand. A paling fence is exactly that object:
        -- a run of stakes with rails between them, put up in one pass.
        --
        -- **What it costs against the STOCKADE is the corner and the crater.** A pin
        -- punches 51 pixels of page and holds a tank for four seconds, and two of
        -- them from a full meter buy one rail. A staple is 15 pixels and 6, and
        -- fifteen of them from a full meter buy fourteen rails in a row. So the
        -- pushpin's fence is a shape with teeth at the corners and this one is a
        -- length of fence with wire all the way down it: the same field, read at the
        -- other end of its range.
        radius = 4, damage = 1, knock = 0,
        -- One field, and it is the same one field it is on the CORRAL and the
        -- STOCKADE: the fence is not a property of the pen, it is a property of any
        -- mark that says `wall`. Walls:rebuild files a thread's path at the nib's
        -- own radius exactly as it files a line a hand drew, and Game:stringThreads
        -- dirties the index as it lays -- so fourteen rails strung in one drag are
        -- one rebuild and the crowd walks round all of them without being told
        -- anything was strung rather than drawn.
        wall = true,
        spacing = 1, life = 9,
        -- The pen's second level, unchanged, including the two pixels of slack:
        -- Enemy:resolveWalls parks a body at exactly the ink's edge, so a tick
        -- measured at the radius alone lands on floating-point luck.
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        -- No `smooth`, which is `Game:layLine`'s rule rather than a choice: a nib
        -- that trails the pointer is for a hand, and nothing here is drawn by one.
        -- And no `keep`, which is the STOCKADE's argument unchanged -- `thread`
        -- already holds every mark this row lays for as long as both its posts are
        -- in the page, and Game:holdWalls holds *one gesture's worth* and lets the
        -- last go each time a new one is laid, which on a row that strings fourteen
        -- rails at once would drop thirteen of them.
        --
        -- The pen's third level, built by the line's own unlock (src/upgrades.lua)
        -- because `scaleDamage` reaches `pop.damage` by name and Tools.copy is one
        -- level deep. It is worth reading on this row: a rail comes off the page
        -- when either of its staples finishes, and what pops is that twelve pixels
        -- of fence and whatever was leaning on it -- so a seam left to run out goes
        -- off along its own length, a staple at a time.
        pop = nil,
        thread = LINK,
        drop = WIRE,
        -- **Priced per staple, like the CRATER and unlike the five that thread**,
        -- because a drag is charged as it goes (Game:rakeDrops): the meter and not
        -- a count is what caps the seam, and one that runs dry stops where the ink
        -- did. 0.14 is the staple's own 0.1 and half of what a hand would have paid
        -- for the twelve pixels of finished pen between this staple and the last
        -- (12/170, halved, is 0.035) -- the same half-price on a strung mark that
        -- every row in the pushpin's family charges, worked out per press instead
        -- of per gesture. So a full meter is fifteen staples and a hundred and
        -- seventy pixels of fence, against the stapler's own twenty-two bare ones.
        ink = 0.14,
    },
    {
        name = "WICK",
        icon = "wick",
        -- MARKER and STAPLER, and it is the CORDON at the other end of the same
        -- field: there a strip of burning band between two pins you placed, here a
        -- continuous one you drag, pinned to the paper every twelve pixels.
        --
        -- A wick is a cord that burns along its length and is held in place while
        -- it does, which is the row in one word -- and the marker's own trouble is
        -- exactly the being held. Its band is the best ground in the game and the
        -- worst to place: it goes where your hand goes, which is where you are, and
        -- the crowd it is for is the crowd you are trying not to be standing in.
        -- The HALO answers that with reach, the CORDON with two chosen ends, and
        -- this with a *seam* -- fifteen presses of a stapler lay a hundred and
        -- seventy pixels of burning line, and every one of them killed the chaff
        -- standing where it landed on the way in.
        --
        -- The band does not stop anybody and is not meant to. 15 pixels of sky
        -- burning 5 a tick, setting alight anything that so much as crosses it, with
        -- a 6 and a one-in-five 18 in the wire holding it down. The crowd may walk
        -- through it. What it pays for walking through is the band and the staple
        -- both.
        radius = 7, damage = 5, knock = 0,
        spacing = 2, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- Written at nothing and built by the unlock, the CORDON's rule for the
        -- CORDON's reason: `scaleDamage` reaches `ignite.damage` and Tools.copy is
        -- one level deep.
        ignite = nil,
        -- **The marker's `stack` is not copied across**, and it is the CORDON's
        -- argument word for word: layers land where one stroke has passed back over
        -- its own ink, and each mark here is a straight twelve pixels between two
        -- staples. It never crosses itself, so the cap of three would never be
        -- reached and Stroke:revisits would be walked for nothing.
        --
        -- Two seams crossing is not that. They are separate marks, they both tick,
        -- and the crowd standing where they cross takes both -- the level's payoff
        -- arriving through the tool's own geometry rather than through a field.
        thread = LINK,
        drop = WIRE,
        -- The PALING's arithmetic with the marker's dearer ink: 0.1 for the staple
        -- and half of the 12/120 a hand would have paid for the band between it and
        -- the last one, which is 0.05. A full meter is fourteen presses, so the
        -- burning line a run can afford in one drag is a little shorter than the
        -- fence -- which is the two nibs' own prices doing what they have always
        -- done.
        ink = 0.15,
    },
    {
        name = "CLINCH",
        icon = "clinch",
        -- GLUESTICK and STAPLER, and the only one of the three that leaves no mark
        -- at all. A clinch is the trade's word for what a stapler actually does to
        -- the wire -- the legs fold flat against the underside of the sheet, and a
        -- staple that has clinched properly is one nothing is getting off the page.
        --
        -- **It is the gluestick's contract moved onto a fastener.** A smear holds
        -- everything standing in it for as long as it is on the paper, because the
        -- freeze is re-applied on every tick rather than handed out once. A staple
        -- has never worked that way: it bites the frame it lands, holds what was
        -- standing there, and whatever wanders into the circle afterwards walks
        -- straight over the wire. `tacky` is that difference and nothing else --
        -- every four tenths of a second the circle is swept and anything in it is
        -- stuck to the wire again, for as long as the staple is in the page.
        --
        -- Which turns the tool inside out without touching a number. A staple used
        -- to be a fastening you aimed at one body; this one is a *spot on the page*
        -- that fastens whatever crosses it, and a raked seam of them is a line the
        -- crowd sticks to. Nobody has to be hit for it to work, which is the first
        -- time that has been true of this tool -- and it is exactly what the
        -- gluestick's finale says out loud, one tool over: the level that acts on
        -- what the smear has *not* caught.
        --
        -- **And then the ending is already written.** `prise` is the stapler's third
        -- level -- the wire torn back out of the paper for a second bite -- and on
        -- this row that second bite lands on everything the wire has collected over
        -- five seconds, standing exactly where it was stuck, because the thing
        -- holding it there is the thing coming out. 6 a body, a fifth of them 18,
        -- and half again on both from the paste (`soften`), which is the gluestick's
        -- second level riding on the body the way it always does (Enemy:hurt). The
        -- glue's `tear` is deliberately not here: coming loose costing something is
        -- what `prise` already is, and paying the same event twice would be the row
        -- arguing with itself.
        radius = 20, damage = 0, knock = 0,
        drop = {
            -- Not `WIRE`, and it is the only stapler fusion whose block is not --
            -- the CRATER's case exactly. The other two eat the parent whole and move
            -- nothing inside it, which is what one shared table is for; this is the
            -- row that changes how a staple *holds*, so it adds three fields the
            -- shared one does not have and moves one number in it.
            lands = Staple, sound = "stapler",
            radius = 7, damage = 6,
            crit = { chance = 0.2, mult = 3 },
            prise = true,
            rake = { every = 12 },
            -- **`freeze` and `life` stop being the same number, and that is the
            -- fusion in two fields.** They are written twice on every other drop in
            -- the game because a hold handed out once *is* the clock on it -- there
            -- is nothing to update afterwards. Here the hold is re-applied while the
            -- wire is in the page, so `life` is how long the staple goes on
            -- fastening and `freeze` is only how long the last catch lasts: what it
            -- holds is held for five seconds and comes free two after the wire
            -- leaves, which is a staple's own hold and always was.
            --
            -- 5 is between the pushpin's four and the gluestick's six, which is
            -- where a staple with paste on it belongs -- longer than the thing that
            -- punches a hole, shorter than the paste itself. It is also the one
            -- number a run cannot buy anywhere else: the FIXATIVE stretches a hold
            -- (scalePersistence), so this is the row where that line is worth the
            -- most, and it is why the catalyst is not that line.
            freeze = 2, life = 5,
            tacky = 0.4,
            -- The gluestick's second level, inside the block because the block is
            -- what holds -- `Staple:catch` hands it to `Enemy:freeze` as the thing
            -- doing the sticking, and from there `Enemy:hurt` finds it on the body.
            -- Read and never written, so it is safe where a `tear` would also have
            -- been (the MOAT's rule).
            soften = 1.5,
        },
        -- **The gluestick's other two levels have nowhere to go, and both misses are
        -- honest.** The wider smear is 41 pixels of paste, and what this row lays is
        -- wire: a staple's circle being small enough to miss with is the whole of
        -- what keeps a tool this cheap honest, and a fusion's job is not to take a
        -- parent's counterplay off it. The pull is a field read off *strokes*
        -- (Game:updateGlue reads `s.tool.pull`, and `hasPull` is set walking the
        -- page's marks), and there is no stroke on this row -- but its idea is the
        -- one thing that did come across, as `tacky`, which is the same sentence
        -- about bodies the tool never caught.
        --
        -- The brush fields above it are what a row with a block always has: nothing.
        -- `radius` is written at the paste's own 20 and read by nobody, which is the
        -- CORRAL's rule turned round -- it would be read if this row ever grew a
        -- mark, and until then it says what the fusion is made of.
        --
        -- Nothing for an unlock to build: `scaleDamage` walks Tools.BLOCKS and finds
        -- `drop.damage` on the run's own copy of the block, `crit.mult` is stepped
        -- over by name, and `soften` and `tacky` are read by nobody who writes.
        ink = 0.15,
    },
    {
        name = "SNAG",
        icon = "snag",
        -- RUBBER and STAPLER, the fourth of the family and the one the note above
        -- this list said was not settled. It is settled by giving up the seam.
        --
        -- The other three borrow `rake` and hang something off it, because `rake` is
        -- the one block gesture in the game that is a drag. This row cannot: the
        -- rubber has no shape to hang and its whole gesture *is* the drag. And a
        -- staple raked out beside a rub would be a shove undoing the fastening laid
        -- next to it, which is the reading that stopped the row being written. So the
        -- carrier is the STUB's instead, and this is the fourth row in the game that
        -- is a different tool depending on whether your finger moves -- **and the
        -- first where the two gestures are the other way up.**
        --
        -- Tap and a staple lands, exactly as it lands off a stapler: 6 through a
        -- 15px circle, one in five going straight through, and the wire holding
        -- whatever survived it for two seconds. Drag and it is the finished rubber,
        -- unchanged in every number: a 7px tip, 240 of shove out of the line, 2 of
        -- chip, half price over ground you have already covered, and what it sends
        -- flying knocking down what it lands on.
        --
        -- **And then the one thing neither parent had: the rub takes the staples back
        -- out** (`snag` below). A rubber dragged across a stapled sheet catches the
        -- wire and rips it out, tearing the paper -- which is a thing that really
        -- happens and the only honest way these two tools meet. Every staple the rub
        -- crosses is prised on the spot, early, and its tear-out bite lands with the
        -- crit *certain* rather than rolled: 18 through everything the wire is
        -- holding, which takes a skull, an eye and a blot outright and leaves the
        -- grin standing.
        --
        -- So the row is a two-step gesture and the only one on the strip: fasten the
        -- front of the crowd down a tap at a time, then sweep the rubber across the
        -- lot and collect. What the parents each gave up buys it, and the two losses
        -- are one fact said twice -- **each parent loses the level that wanted the
        -- gesture the other one took.** The stapler has no `rake`, because the drag is
        -- the rub (the STITCH's trade, word for word). The rubber has no `lean`,
        -- because the press is the staple: a tip that hits where it rests would hit
        -- on the press itself -- the level's own words -- and this is the one row
        -- where the press is the *other gesture*, so the lean would shove the thing
        -- you were fastening a moment before the staple arrived. Two levels out, one
        -- certainty in.
        --
        -- The two circles are the same size, 7 and 7, and that is the parents'
        -- arithmetic rather than a decision: a rub reaches exactly as far as a staple
        -- holds, so the sweep that touches the wire covers what the wire caught.
        --
        -- What keeps the whole thing honest is that a staple is still small enough to
        -- miss with, still two seconds, and the collecting is a second gesture out of
        -- the same meter -- so the run has to *go back*, across a page the crowd is
        -- still walking over, before the wire comes out on its own for a fifth of the
        -- damage.
        radius = 7, damage = 2, knock = 240,
        spacing = 2, ink = 1 / 150, life = 0,
        rehit = 0.3,
        -- The rubber's third level. It is worth more here than on the parent, and
        -- for the row's own reason rather than a number: the rub you actually make
        -- with this tool is back and forth over the staples you placed, which is
        -- precisely the motion `scrub` discounts (Stroke:revisits).
        scrub = 0.5,
        -- Crumbs and no dab, which is the rubber whole -- the one brush in the game
        -- that puts nothing on the page, so `life` is zero and the mark is over the
        -- moment you let go. Kept where the STUB and the SCUFF had to leave it out:
        -- there the travelling tip is a pencil or a chisel and a rate per stamp of
        -- eraser debris would have been saying something false about what was
        -- drawing. Here the travelling tip *is* the rubber.
        crumbs = { chance = 0.7, color = Palette.graphite },
        -- The half of the row that is new, and it is a flag: the mark takes the
        -- page's own staples out as it goes. See the field at the top of this file
        -- and `Game:snagDrops`.
        snag = true,
        -- The rubber's finale and the whole finished stapler, both built by the
        -- line's own unlock (src/upgrades.lua) rather than written here for the
        -- BUMPER's reason: `scaleDamage` reaches `ram.damage` and `fasten.damage` by
        -- name, `scalePersistence` reaches `fasten.freeze` and `fasten.life`, and
        -- `Tools.copy` is one level deep -- `fasten` is a block on the row without
        -- being one of `Tools.BLOCKS`, so nothing lifts it but the level that makes
        -- it. Which is the STITCH's arrangement exactly, being the other row whose
        -- staple is a `fasten`.
        ram = nil,
        fasten = nil,
    },
    {
        name = "HINGE",
        icon = "hinge",
        -- SCISSORS and STAPLER, the forty-first and the last pair in the
        -- catalogue -- and the scissors' fifth, which finishes the one line that
        -- was still short of its nine.
        --
        -- **The gesture is the scissors' whole, and it is the only fusion off them
        -- that keeps it.** The other four all took the taps away and gave the cut
        -- to something else: two pins cast it (the TEAR LINE), a ruler lands it
        -- (the GUILLOTINE), a compass rings it (the PUNCH), a hand draws round it
        -- (the CUTOUT). Here you still tap twice and the page still opens between
        -- the taps. What changes is what the taps *leave*: a staple goes into the
        -- paper at each one, and the stretch between them is filled with more of
        -- them at the stapler's own twelve-pixel spacing, so the line the blades
        -- are about to come down is stitched to the page before they get there.
        --
        -- **What it fixes is the parent's one real weakness, and it is the same
        -- weakness the TEAR LINE fixed from the other end.** A cut is two taps
        -- with a gap between them and the horde keeps walking through the gap, so
        -- the row of blobs the first tap lined up is never the row the second one
        -- cuts. The TEAR LINE answered that by making the first tap a crater --
        -- kill what you lined up. This answers it by making the line *hold*: every
        -- staple is 6 through a 7px circle with one in five going straight through
        -- at 18, and it pins whatever it catches to the paper for two seconds. The
        -- blades take a beat to travel (Game:updateCuts), and what they arrive at
        -- is a row of bodies that cannot walk out of the way. A stapler is the tool
        -- that stops things moving and the scissors are the tool that needs things
        -- to stand still; nothing about that had to be invented.
        --
        -- And the hold outlives the cut, which is the half worth reading twice.
        -- The slit closes in a second and a half; the wire is in the page for good
        -- (`prise` takes it back out two seconds later for a second 6, and after
        -- that the staple is a drawing). So what a hinge leaves behind is a line
        -- of fasteners across the paper with half the page gone on one side of it
        -- -- which is what the name is: a row of wire along the line a page comes
        -- apart on, and the page swinging away from it.
        --
        -- **The wire and the sever land on the same bodies and do not argue**, which
        -- is worth writing down because it looks as though they should. A staple
        -- holds a body to the paper; the offcut takes the paper away. What happens
        -- is the honest thing -- the body goes with the page it was pinned to
        -- (Game:liftEnemyTo) and the staple stays in the page where it was driven,
        -- still holding, still counting down. So the crowd arrives in the corner
        -- glued: the hold rides on the body the way the burn and the storm's mark
        -- do, and it goes on running there. The alternative -- wire that refuses to
        -- let the sever move what it caught -- would be the seam undoing the cut it
        -- was laid for, which is the one thing this pairing must not do.
        --
        -- **`sever` is kept whole and needed no re-reading at all**, which is the
        -- one thing this row can say that no other scissors fusion can. The
        -- parent's finale is a sentence about a cut with you on one side of it and
        -- the taps are still the parent's taps, so the half you are not standing on
        -- is the half you are not standing on. The TEAR LINE had to generalise it
        -- to three cuts and the GUILLOTINE had to make it keep asking; here it is
        -- copied across and it means what it always meant.
        cut = {
            -- The parent's finished line, and a fusion is only dealt once both its
            -- lines are finished: the cap is off (`reach`), the deep stretch bites
            -- between the taps (`blades`), the rest runs on to both edges
            -- (`through`) and the half you are not on comes away (`sever`).
            --
            -- Unlimited reach is doing more here than it does on the parent,
            -- because it is what the *seam* is measured against: how long a line
            -- of wire one press buys is how far apart you were willing to put the
            -- taps. See the price below, which is where that trade actually lands.
            reach = math.huge, width = 3,
            damage = 12, knock = 0,
            -- Both built by the line's own unlock rather than written here, the
            -- HALO's rule and for the HALO's reason: `scaleDamage` reaches
            -- `cut.blades.damage` and `cut.wire.damage` by name off `Tools.BLOCKS`,
            -- `scalePersistence` reaches `cut.wire.freeze` and `cut.wire.life`, and
            -- `Tools.copy` copies the row and its blocks one level deep -- so a
            -- table a level further in that was shared with this row would compound
            -- its multiplier on every rebuild. `wire` is the SEAM's arrangement
            -- exactly, being the other row whose staple lives inside a block.
            blades = nil,
            wire = nil,
            -- These two the row may say outright, the PUNCH's reason: one is a
            -- boolean and the other is {tick} with no damage in it at all -- what a
            -- severed half does to the crowd is carry it off the page and set it
            -- down in the far corner rather than hurt it -- so there is nothing
            -- here for the sharpener to find and nothing shared for it to compound.
            --
            -- The tick is the parent's own 0.5 rather than the quarter-second the
            -- other two tapped cuts carry, and the argument is that nothing about
            -- this row makes the missing paper hungrier: it is one cut, placed by
            -- hand, the same shape and the same size as the one the scissors make.
            through = true,
            sever = { tick = 0.5 },
            life = 1.6, fade = 0.6,
            ramp = { Palette.paper, Palette.paper, Palette.graphite },
        },
        -- **Charged on both taps, which is this row's one genuinely new thing** --
        -- and it is the free anchor's premise expiring rather than an exception.
        -- The parent charges the second tap only *because* the first one does
        -- nothing; here the first tap drives a staple, and a press that lands
        -- something is charged like one (Game:openCut says the rest, including the
        -- unlimited stapler the old rule would have paid out).
        --
        -- 0.45 a tap is 0.9 the gesture, which is the SEAM's own price arrived at
        -- from the other side: a hand would pay 0.3 for the cut, and the SEAM
        -- decided what a line of wire across a page is worth by charging 0.9 for a
        -- ruler that costs 0.35 on its own. Same object, same total. It is also
        -- the TEAR LINE's bargain in the same shape -- two presses, and the cut
        -- comes with the second one for nothing.
        --
        -- **The length is not priced and that is deliberate.** A flat price for a
        -- seam the player measures out means a long cut is more wire per press than
        -- a short one, which is the HEM's one axis (`sweepPrice` in src/game.lua)
        -- left un-taken here on purpose: what a long line buys is staples spread
        -- thin over ground nobody is standing on, and what a short one buys is the
        -- whole seam through the crowd in front of you. The choice is where the
        -- wire goes rather than how much of it there is, and pricing the length
        -- would flatten that into arithmetic.
        ink = 0.45,
    },
    {
        name = "COLLAGE",
        icon = "collage",
        -- GLUESTICK and SCISSORS, and the name is the mechanic: cut and paste. What
        -- you cut comes away and is *stuck down somewhere else*, which is what a
        -- severed region has done to the crowd since it stopped being a despawn
        -- (Game:liftEnemyTo).
        --
        -- **The smear is the mark and the cut is what happens at it**, which is the
        -- gluestick's own rule from its other three rows: paste is the stronger
        -- place -- a fence says where a body may not stand and paste says where a
        -- body *is* standing and will go on standing -- so the smear is the body in
        -- every pairing the stick is in and the second parent is a property of it.
        -- Here that property is the whole of the scissors: you drag a smear, and
        -- when you let go the page opens along the line between the two ends of it
        -- (`chord`, Game:chordCut).
        --
        -- Which makes the gesture read in one motion. `pull` drags the crowd onto
        -- the line while you are still drawing it, the paste holds them there,
        -- `soften` means everything standing in it takes half again, and then the
        -- blades come down the middle of it at 20. The scissors' whole weakness is
        -- that the horde walks out of the line between two taps; the gluestick is
        -- the tool that stops things walking and pulls them in on the way.
        --
        -- **And what leaves goes stuck** (`sever.paste` below). Half a page of crowd
        -- is carried into the far corner and set down glued, so the reposition stops
        -- being only a walk back and becomes four seconds of nothing at all -- the
        -- single hardest piece of crowd control a run can buy, and the reason this
        -- row wants no damage of its own on the smear.
        radius = 20, damage = 0, knock = 0,
        spacing = 2, ink = 1 / 90, life = 6,
        rehit = 0.4, linger = true, tickRate = 0.4, under = true,
        freeze = 0.55,
        soften = 1.5,
        tear = 4,
        pull = { range = 26, speed = 30 },
        ramp = { Palette.paper },
        stamp = glueWideStamp,
        edge = { stamp = glueWideEdge, color = Palette.graphite, rough = 0.45 },
        speck = { chance = 0.08, color = Palette.sky },
        -- The whole finished pair of scissors, built by the line's own unlock
        -- (src/upgrades.lua) rather than written here for the STITCH's reason:
        -- `chord` is a block on the row without being one of `Tools.BLOCKS`, so
        -- nothing lifts it onto the run's copy but the level that makes it -- and
        -- `scaleDamage` writes into it.
        chord = nil,
    },
    {
        name = "SCORCH",
        icon = "scorch",
        -- MARKER and SCISSORS. The band is the place and the cut is what happens at
        -- it, the COLLAGE's arrangement with the weaker of the two surfaces: a
        -- marker band is somewhere a body can be, so it is the mark, and the
        -- scissors are what the mark then does.
        --
        -- **The blades set fire to what they cut** (`ignite` on the chord,
        -- `Scissors:strike`), which is the marker's finale delivered by a pair of
        -- scissors instead of by contact -- and it is the same burn block the band
        -- itself sets, so a body can only be lit once and the sharpener only finds
        -- the number once.
        --
        -- **This pairing did not work at all until the offcut stopped despawning,
        -- and that is worth writing down.** Fire is damage over time and a despawn
        -- is the end of time: a cut that emptied half the page would have been
        -- taking bodies *out of* the fire the same tool had just lit, so the two
        -- halves of the row spent the frame undoing each other. A cut that carries
        -- the crowd to the corner instead hands the fire the one thing it wants,
        -- which is the seconds to work in -- everything the blades touch arrives at
        -- the far corner burning and burns the whole way back. The burn rides on the
        -- body and outlives the slit, which is the same sentence the CUTOUT's ring
        -- already says about a shape you draw round something.
        radius = 7, damage = 5, knock = 0,
        spacing = 2, ink = 1 / 120, life = 3.6,
        rehit = 0.35, linger = true, tickRate = 0.35, under = true,
        stack = 3,
        ramp = { Palette.sky },
        stamp = markerWideStamp,
        edge = { stamp = markerWideEdge, color = Palette.blue },
        speck = { chance = 0.04, color = Palette.sky },
        -- Both built by the unlock, the HALO's rule -- and the *same table* twice
        -- over, which is the one thing to keep if either is ever touched: the burn
        -- the band sets and the burn the blades set are one block, so
        -- `scaleDamage` scales `ignite.damage` once through the row and the chord
        -- reads what it wrote. Two copies would be two numbers drifting apart with
        -- every sharpener a run takes, for a distinction nobody could see.
        ignite = nil,
        chord = nil,
    },
    {
        name = "SHEAR",
        icon = "shear",
        -- RUBBER and SCISSORS, and the one row of the four brushes against the
        -- scissors that cannot hand the cut to its own line. **A rub is an event
        -- that is nowhere at all once it is over** -- that is the rule the six
        -- brush pairs settled on and it decides this row too: there is no mark left
        -- lying between two ends, so there are no two ends to open the page
        -- between.
        --
        -- So it keeps the parent's taps and gives the drag to the rub (`tapped` on
        -- the chord, Game:chordCut). **Tap twice and the page comes apart; drag and
        -- it is the whole finished rubber.** That is the SNAG's shape and the fifth
        -- row in the game that is a different tool depending on whether your finger
        -- moves -- and the SCUFF's reason for taking that shape rather than a
        -- number: a rub delivered *by* a cut is not a thing a cut can deliver.
        --
        -- **What the pair is for is the one thing the scissors are written never to
        -- do.** `knock = 0` is on every cut block in the game and it is written down
        -- rather than left out precisely so no multiplier can ever move it -- a
        -- blade separates, it does not shove. The rubber is the biggest shove in the
        -- game. So the loop is: cut the page, then sweep 240 of rubber across the
        -- crowd to drive them *over* the slit, where the missing paper picks them up
        -- and puts them down in the far corner (Game:liftEnemyTo). The offcut stopped
        -- being an eraser when it stopped despawning, and this row is what happens
        -- when you hand somebody a broom for it: the cut decides where the line is
        -- and the rub decides who crosses it and when.
        --
        -- It is also the one pairing where both parents are *removal* -- one takes
        -- the paper away and the other takes the mark away -- and neither does a
        -- thing to the other's leavings, which is the honest answer rather than a
        -- gap. A rubber cannot rub a hole shut and must not be able to: the offcut
        -- is the level the scissors spent three levels earning.
        radius = 7, damage = 2, knock = 240,
        spacing = 2, ink = 1 / 150, life = 0,
        rehit = 0.3,
        -- The rubber's third level, worth what it is worth on the parent: the rub
        -- this tool actually makes is back and forth over the line you just cut,
        -- which is precisely the motion `scrub` discounts (Stroke:revisits).
        scrub = 0.5,
        crumbs = { chance = 0.7, color = Palette.graphite },
        -- **`lean` is deliberately never built, and it is the SNAG's trade word for
        -- word.** Leaning is a tip that keeps hitting where it rests, and it lands
        -- on the press *itself* -- and on this row the press is the tap that anchors
        -- or closes a cut. A lean would shove the crowd off the line in the frame
        -- between the two taps, which is the one thing the whole pairing exists to
        -- stop. One level out, and the parent keeps it.
        lean = nil,
        -- The rubber's finale and the whole finished pair of scissors, both built by
        -- the unlock for the STITCH's reason. `ram` because `scaleDamage` reaches
        -- `ram.damage` by name; `chord` because nothing lifts a block that is not
        -- one of `Tools.BLOCKS` but the level that makes it.
        ram = nil,
        chord = nil,
    },
    {
        name = "DEADLINE",
        icon = "deadline",
        -- PEN and SCISSORS, the forty-fifth and the last pair the ten tools can
        -- make. And the one row in the game where **the mark is the region**: the
        -- line you draw is a line the horde cannot cross, and anything that touches
        -- it is off the page and back in the corner (`lift` below).
        --
        -- **Which is the scissors' verb attached to a shape it has never had.** The
        -- offcut is a half-plane, the punch is a disc, the cutout is a ring -- all
        -- three are areas, and all three are drawn by *taking the paper away*. This
        -- is a line, the page under it is untouched, and it is the only region in the
        -- game you can put exactly where you want it and leave there.
        --
        -- **The pen gives up its wall for it, and that trade is the whole design.**
        -- A wall is a line the crowd steers around (`Enemy:avoidWalls`), so a row
        -- that walled *and* lifted would almost never fire -- the only bodies that
        -- ever touched the ink would be the ones the crowd's own jostling pressed
        -- into it, and the two halves of the tool would spend the run undoing each
        -- other. That is the SCORCH's sentence about fire and despawning, and the
        -- CLEARING's about a shove and a fastening, arriving a third time.
        --
        -- Without the wall the line is invisible to the crowd's steering, and then it
        -- is not a fence, it is a **tripwire**: they walk at you, they cross it, and
        -- they come out in the corner. Which is a stronger fence than a fence, and
        -- the pen paid the honest price for it -- the level that made its mark
        -- terrain, given up for the level that makes its mark a place bodies cannot
        -- be.
        --
        -- **And `keep` is what the pen brings that nothing else could.** The last
        -- line stays until you draw another (Game:holdWalls, which is now reached by
        -- `keep` rather than by `wall` for this row's sake), so what a run holds is a
        -- permanent, page-crossing line the horde may not cross -- replaced rather
        -- than stacked, one gesture's worth at a time, which is the pen's own bounded
        -- bargain doing the limiting exactly where the parent already put it.
        --
        -- What is left of the pen still works and none of it argues: `sting` bites 1
        -- a tick off whatever leans on the line in the half-second before the lift
        -- takes it, and `pop` takes 4 off the crowd when the line finally goes --
        -- which on this row is the moment you draw the next one.
        --
        -- **The price is the xp, and it is the steepest version of the offcut's own
        -- bargain.** Nothing the line lifts is killed, so a run that hides behind one
        -- is a run that earns nothing while the difficulty clock goes on climbing --
        -- and the boss ignores the line entirely (`Game:liftEnemyTo` refuses it), so
        -- the fight the tool postpones is the one fight it cannot postpone. That is
        -- the whole counterweight and it wants watching before a number here moves.
        radius = 4, damage = 1, knock = 0,
        linger = true, tickRate = 0.5, rehit = 0.5, graze = 2,
        spacing = 1, ink = 1 / 170, life = 9,
        smooth = 26,
        ramp = { Palette.blue, Palette.blue, Palette.sky },
        fade = 0.78,
        stamp = penWideStamp,
        keep = true,
        -- **Written at nothing and it is the row's argument, not an omission.** See
        -- the paragraphs above: this is the one thing the pen gives up, and a row
        -- whose header did not say so outright would read as a fence that forgot to
        -- fence.
        wall = nil,
        -- The scissors' finale at the thinnest shape it has ever had, on the
        -- parent's own half-second. Written on the row rather than built by the
        -- unlock, which is the PUNCH's rule: there is no damage in it for
        -- `scaleDamage` to find and nothing shared for it to compound -- what a
        -- severed region does to the crowd is move it, not hurt it.
        lift = { tick = 0.5 },
        -- The pen's third level, built by the unlock for the HALO's reason:
        -- `scaleDamage` reaches `pop.damage` by name and `Tools.copy` is one level
        -- deep.
        pop = nil,
    },
}

-- Off the strip for now. Nothing here is broken -- it is a whole tool, drawn
-- and balanced -- it is just not on the column at the moment. Move a row back
-- into Tools.list above and it is a tool again; nothing else in the game knows
-- the difference, because nothing addresses a tool by name or by index.
Tools.shelved = {
    {
        name = "CRAYON",
        icon = "crayon",
        -- Wax: the only mark that does nothing to an enemy's health at all.
        -- It is a surface. You move half again as fast along it, and anything
        -- chasing you loses its footing on it -- it keeps the heading it came
        -- in with and can only turn slowly, so it slides straight past you and
        -- has to come back round. Cheap per pixel, because a lane is only
        -- worth having if it is long enough to run down.
        radius = 6, damage = 0, knock = 0,
        spacing = 2, ink = 1 / 200, life = 7,
        slick = { boost = 1.75, turn = 0.8 },
        ramp = { Palette.sky },
        fade = 0.7,
        stamp = crayonStamp,
        -- A broken outline: wax piles up unevenly against the paper rather
        -- than ruling a clean border, and a continuous one made the band read
        -- as a user-interface capsule instead of something drawn.
        edge = { stamp = crayonEdge, color = Palette.blue, rough = 0.4 },
        holes = { stamp = crayonHoles, color = Palette.paper, rough = 0.25 },
        speck = { chance = 0.06, color = Palette.blue }, -- flakes of wax
    },
}

-- The four blocks that turn a tool into something other than a brush. Named
-- here because two other things have to walk them: the copy below, and the
-- upgrade that sharpens every damage number a run owns (src/loadout.lua).
Tools.BLOCKS = { "drop", "snap", "sweep", "cut" }

-- A tool a run can change its mind about.
--
-- These rows are shared by every run the program plays, and upgrades move the
-- numbers in them -- the ruler grows, the sharpener deepens everything you draw
-- -- so a run works from copies rather than from the rows themselves and hands
-- those copies out through Loadout:tool. What is copied is what carries
-- numbers; ramps, stamps and the module a drop lands as are read-only, and are
-- shared.
function Tools.copy(tool)
    local out = {}
    for k, v in pairs(tool) do out[k] = v end

    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block then
            local copy = {}
            for k, v in pairs(block) do copy[k] = v end
            out[name] = copy
        end
    end

    return out
end

-- The tool as it was written down, which is what the selector draws and what a
-- run's copy starts from. Anything reading a tool's *numbers* mid-run wants
-- Loadout:tool instead: this one has never heard of an upgrade.
function Tools.get(index)
    return Tools.list[index]
end

return Tools
