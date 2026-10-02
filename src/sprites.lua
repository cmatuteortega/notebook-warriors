-- All game art, authored as ASCII pixel maps, one character per palette key:
--   .=transparent  w=paper  g=graphite  s=slate  o=ink  r=red  k=blush  b=blue  c=sky
-- Drawn 1:1 into the low-res canvas, so one character is exactly one game pixel.

local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Sprites = {}

-- The sprites in here that are not authored art: they are whatever was left on
-- the studio's board (src/studio.lua). These are only where a fresh one starts
-- from -- what you are handed to draw over, and what RESET puts back -- while
-- the design actually on the page belongs to src/design.lua. Their size is the
-- sprite's size, so nothing that is drawn can change shape underneath the
-- numbers measured off it.
Sprites.STICKMAN = {
    ".....ooooo.....",
    "...oo.....oo...",
    "..o.........o..",
    "..o.........o..",
    "..o..o...o..o..",
    "..o.........o..",
    "..o...ooo...o..",
    "...oo.....oo...",
    ".....ooooo.....",
    ".......o.......",
    "..ooooooooooo..",
    ".......o.......",
    ".......o.......",
    ".......o.......",
    "......o.o......",
    ".....o...o.....",
    "....o.....o....",
    "...o.......o...",
    "..oo.......oo..",
}

-- The four heroes' own opening drawings (src/design.lua), one per row of
-- Characters.list, keyed here by character key. A character used to open on
-- Sprites.STICKMAN, the same stick man for all four, until each was actually
-- drawn -- these are that: what RESET and a fresh save now put back is the
-- hero as drawn, not a placeholder. A character with no row here (a new one,
-- added and not yet drawn) falls back to Sprites.STICKMAN, same as before.
Sprites.HERO_SHOOTMAN = {
    "......ooo......",
    ".....obbbo.....",
    "....ooooooo....",
    "....o.b.b.o....",
    "....o.....o....",
    ".....o...o.....",
    "......ooo......",
    "...oooooooo....",
    "..o....o.oooooo",
    "..o.ooooobbbbbo",
    "oooobbbbbooooo.",
    "o...ooooo..oo..",
    "o..o...o.......",
    "ooo...ooo......",
    ".....ooooo.....",
    "....o.....o....",
    "....o.....o....",
    "....o.....o....",
    ".....o...o.....",
}
Sprites.HERO_SWORDSMAN = {
    "......ooo......",
    ".....obbbo.....",
    "....ob...bo....",
    "....o.ooo.o....",
    "....o..o..o....",
    ".....o.o.o.....",
    "...ooooooooo...",
    ".oobbbbbbbbboo.",
    ".o.obbbobbbo.o.",
    "o.ooooobooooo.o",
    "o...ob.o.bo...o",
    "o...o.ooo.o...o",
    "o...o.bob.o...o",
    ".o...o...o...o.",
    ".....ooooo.....",
    "....oo...oo....",
    "....o.....o....",
    "....o.....o....",
    ".....o...o.....",
}
Sprites.HERO_STARMAN = {
    ".....ooooo.....",
    "....o.....o....",
    "...o..ooo..o...",
    "...o.obbbo.o...",
    "...obobbbobo...",
    "...o.obbbo.o...",
    "...o..ooo..o...",
    "....o.....o....",
    "...obooooobo...",
    "..o.obbbbbo.o..",
    ".o...ooooo...o.",
    "oo.o...o...o.oo",
    "obo.o.....o.obo",
    ".o..o.bob.o..o.",
    "...obbooobbo...",
    "..o..o...o..o..",
    "..o.o.....o.o..",
    "..ooo.....ooo..",
    "...oo.....oo...",
}
Sprites.HERO_SKATEMAN = {
    "......ooo......",
    ".....obbbo.....",
    "....obbbbbo....",
    "....obooooo....",
    "....oo....o....",
    "..ooo.....o....",
    ".....o...o.....",
    "......ooo......",
    "....ooooooo....",
    "...o...o...o...",
    "..o....o....o..",
    "..o....o....o..",
    ".....ooooo.....",
    ".....obbbo.....",
    "....obbbbbo....",
    "....obbobbo....",
    "....ooo.ooo....",
    "....o.....o....",
    ".....o...o.....",
}

-- The star that orbits you (src/orbital.lua). Solid rather than outlined: at
-- seven pixels across an outline is three pixels of star and four of paper, and
-- this one has to be legible while it crosses a crowd.
Sprites.STAR = {
    "...o...",
    "..ooo..",
    "ooooooo",
    ".ooooo.",
    "..ooo..",
    "..o.o..",
    ".o...o.",
}

-- The rocket that goes off into the page (src/rocket.lua). Drawn nose-right,
-- which is the first of the eight headings it is kept at: `Sprites.setDrawn`
-- turns this into a ring through `pixelart.turn` and a rocket flies one of them
-- exactly -- the eight the volley picks from *are* the eight this ring holds, so
-- nothing is rounded between the line it flies and the drawing that flies it.
-- Nothing is turned at draw time either -- the ring is ordinary sprites at
-- ordinary integer positions -- but the four diagonals of it are resampled, so
-- solid shapes come through and single-pixel lines do not, and a volley of four
-- or eight flies both kinds at once.
--
-- A dart rather than a rocket: a red shaft down the centre row with a wing
-- above and below it, the point closed off in ink at the right-hand end and a
-- single ink pixel marking the tail. The grid is still eleven by seven and the
-- top, bottom and outer columns are still part of it -- they are blank because
-- this drawing only reaches the middle three rows, not because the sprite got
-- smaller, and everything measured off it is unchanged. The trail behind the
-- tail is still particles (Rocket's exhaust), which is what says the thing is
-- under power rather than thrown -- the drawing itself no longer marks a
-- nozzle, and doesn't have to.
--
-- Thin art pays for itself on those four diagonals, and this is the drawing that
-- pays. A single-pixel line does not come through a resample whole the way a
-- solid body does, so the dart is scrappier at the corners than it is on the
-- quarters -- an accepted cost here rather than a bug, and filling the shaft
-- back in is what undoes it. Only the point has to survive a reskin: an arrow, a
-- rocket or a sharpened pencil is the same eleven by seven with the point still
-- on the right.
Sprites.ROCKET = {
    "...........",
    "...........",
    ".o..rrrr...",
    "rorrrrrrroo",
    ".o..rrrr...",
    "...........",
    "...........",
}

-- The cool S that floats off you and across the page (src/cools.lua). The one
-- piece of art in this game that did not have to be designed, because everybody
-- who has ever owned a notebook already knows it: six strokes, two points and a
-- crossing, and nobody can agree where it came from.
--
-- Nine by seventeen, which is a shade narrower and a shade shorter than the
-- stick man -- it is meant to read as something you drew in the margin at the
-- same scale as the hero, not as a bullet. It is drawn upright and stays
-- upright at every heading it flies: nothing in this game turns at draw time,
-- and a doodle floating past has no more business pointing where it is going
-- than the ruled lines do.
--
-- The geometry is exact and worth keeping if you redraw it: the two outer lines
-- and the middle one are four columns apart, the crossing takes the left line
-- to the middle, the middle to the right, and the right one all the way across
-- to the left at twice the angle. That last line is what makes it the cool S
-- rather than a lightning bolt.
Sprites.COOLS = {
    "....o....",
    "...o.o...",
    "..o...o..",
    ".o.....o.",
    "o...o...o",
    "o...o...o",
    "o...o...o",
    ".o...oo..",
    "..o.o.o..",
    "..oo...o.",
    "o...o...o",
    "o...o...o",
    "o...o...o",
    ".o.....o.",
    "..o...o..",
    "...o.o...",
    "....o....",
}

-- The bomb that drops at your feet and counts down (src/bomb.lua). Eleven by
-- thirteen: a round body filling nearly the whole grid, with a spark going off
-- the top-right corner.
--
-- The spark is what says which kind of ball, and it is why the body is set down
-- and left of centre rather than sitting in the middle of the grid. Four pixels
-- is all it gets and all it needs at this size -- a longer one would be drawn
-- out of the body, and a ball with no spark on it at all reads as a cherry.
--
-- All ink and no colour on purpose, and this is the one board where that is
-- advice rather than a default. The warning is not drawn here -- the last
-- stretch of the fuse flashes the sprite's own silhouette (`drawMask`) in blue,
-- so whatever anybody leaves on the board blinks -- and blue is on the board now
-- (see TOOLS in src/studio.lua). A bomb drawn in it is a bomb that looks lit
-- while it is still safe to stand next to, since the flash has nothing left to
-- change. Nothing stops you: it is your drawing and the blink still runs, which
-- is why this is written down here instead of being enforced anywhere.
--
-- Solid rather than outlined, for the star's reason and one of its own: a
-- silhouette flashed in one colour is a shape rather than a ring, so what the
-- blink shows has to be worth seeing filled in. The few gaps left in the body
-- are highlights and they blink as gaps, which reads while they are holes in a
-- shape and would stop reading the moment they joined up into an outline.
Sprites.BOMB = {
    ".........oo",
    "........o.o",
    "...ooooo...",
    "..oo..ooo..",
    ".oo.oooooo.",
    "oo.oooooooo",
    "ooooooooooo",
    "ooooooooooo",
    "ooooooooooo",
    "oo.oooooooo",
    ".ooooooooo.",
    "..ooooooo..",
    "...ooooo...",
}

-- The skate the run rides once it has drafted one (src/skate.lua). Fifteen by
-- three, and both of those numbers are the hero's rather than the board's: it is
-- exactly as wide as the grid the hero is drawn on, because it goes under his
-- feet and a board narrower than the man standing on it reads as a man standing
-- beside one. Three rows is all there is under a pair of feet at this scale, and
-- they are the three parts of a skateboard -- the kicked-up nose and tail, the
-- deck, and the wheels.
--
-- The deck is thirteen wide, which is the one measurement here that something
-- else is struck off: the trail is the same thirteen (`WIDTH` in src/skate.lua),
-- so what is left on the page is exactly the width of what left it, and the
-- hero standing on the board covers the whole of it.
--
-- The wheels are blue and the rest is ink, for the sword's reason read the other
-- way round: the grip is blue because it is the end you hold, and these are blue
-- because they are the end that touches the page -- blue is the half of the
-- palette that is yours and the trail is sky, the light end of it. Whatever
-- anybody draws here, the wheels are worth leaving in the colour of the line
-- they lay down.
Sprites.SKATE = {
    "o.............o",
    ".ooooooooooooo.",
    "...bb.....bb...",
}

-- The bolt the storm puts through the page (src/storm.lua). Seven by fifteen:
-- tall and thin, because the whole of what it is is the distance between the
-- cloud and the ground -- it is the one drawing in the game whose *height* is a
-- measurement something else is struck off, since the cloud hangs exactly a bolt
-- above whatever it is about to hit and a longer one hangs it higher.
--
-- Drawn with its point at the bottom of the middle column, and that is the one
-- thing worth keeping: the tip is where the strike lands, and the ring that
-- flashes round it is drawn from that same point. A bolt tapering to a corner
-- would be a bolt landing somewhere other than where it is pointing.
--
-- All ink, and for the cool S's reason rather than the bomb's: this is six thin
-- strokes on a page made of thin strokes, so what lifts it off the paper is the
-- pale blue rim it is drawn with (Sprites.rim) and the fact that it is only
-- there for a third of a second at a time. Whatever anybody draws here flashes.
Sprites.LIGHTNING = {
    "....ooo",
    "...ooo.",
    "..ooo..",
    ".ooo...",
    ".oooooo",
    "...ooo.",
    "..oooo.",
    "..ooo..",
    "..ooo..",
    "...ooo.",
    "...ooo.",
    "...oo..",
    "...oo..",
    "...o...",
    "...o...",
}

-- The bird a flock is made of (src/flock.lua). Seven by three, and the second
-- smallest board in the game after the pellet: what is being asked for is the
-- doodle everybody already draws along the top of a page -- two humps and a dip,
-- an m with its wings up -- and the empty bottom row is room to hang a tail off
-- it, exactly as the pellet's grid is bigger than the pellet on it.
--
-- All ink and no rim, which is the one place the cool S's argument is heard and
-- turned down. A bird is the same weight of line as everything else on the page
-- and it would be easier to follow with a pale blue outline round it -- but there
-- are up to fourteen of them at once, and fourteen rims is a cloud of sky laid
-- over the crowd they are supposed to be cutting.
--
-- It never turns: a bird wheels round you at every angle there is, so a drawing
-- with a front would be pointing the wrong way at most of them. Which is the
-- pellet's argument again, and an m does not even raise it.
Sprites.BIRD = {
    ".oo.oo.",
    "o..o..o",
    ".......",
}

-- The shot the shootman sends (src/bullet.lua). Five by five, and the drawing in
-- it reaches three: the grid is deliberately bigger than what is on it, exactly
-- as the dart's outer rows are part of the rocket's board without being drawn on
-- -- so there is room to make a shot heavier if you want one, and the pellet you
-- are handed is the small one this game was balanced with. `Bullet.radius` is the
-- grid's half-width either way, so filling the corners in changes what a shot
-- looks like and not what it touches.
--
-- Blue because it is yours: on this page red is what is coming at you and blue is
-- what you sent, and the eye's spit (Sprites.enemyShot) is the same diamond in the
-- other half of the palette with a dark rim round it. Which is the one thing worth
-- knowing before redrawing this: a shot drawn in ink is a shot you cannot tell
-- from the thing being spat back, and on the unruled page there is no overprint to
-- tell them apart either. Nothing stops you -- the sky pixel in the middle is not
-- even on the board's three buttons (see TOOLS in src/studio.lua), so a shot
-- rubbed out and redrawn is ink and blue -- but blue is what says whose it is.
--
-- It never turns. A shot flies at whatever angle the nearest thing happens to be
-- at, so a drawing with a front would point the wrong way at almost all of them --
-- the cool S's argument, and five pixels of pellet has even less to gain from
-- eight headings than seventeen of doodle does.
Sprites.SHOT = {
    ".....",
    "..b..",
    ".bcb.",
    "..b..",
    ".....",
}

-- The sword the swordsman swings (src/sword.lua). Three wide and eight long,
-- and the one drawing in the game that is *not* drawn nose-right: a sword is
-- held rather than flown, so what a board this shape asks for is a sword
-- standing on its pommel with the point at the top, and the swing turns the ring
-- of eight round from there (`POINT_UP` in src/sword.lua).
--
-- Blade, cross guard, grip, pommel, in the four rows, one row, two rows and one
-- row that three columns leave to spend on them. The guard is the whole of why
-- this reads as a sword at eight pixels long: it is the one row wider than the
-- blade, and with it gone -- a solid slab of blade was tried -- what is left
-- reads as a bullet.
--
-- The grip is blue, because blue is the half of the palette that is yours (the
-- pen, the bullets, the bomb's flash) and the grip is the end you are holding.
-- That is worth keeping whatever else anybody draws here: a cleaver, a bat or a
-- rolled-up ruler is the same eight rows, and the colour is what says which end
-- of it goes in the hand.
--
-- Thin art pays for itself on the four diagonal headings, exactly as the dart
-- does: a one-pixel blade does not come through a resample whole (see
-- pixelart.turn), so a sword swung to the corners is scrappier than one swung
-- square. That is the accepted price of a drawing nobody authored, and it is
-- paid here rather than at the square headings, where the guard and the point
-- are the two things anybody will actually recognise.
Sprites.SWORD = {
    ".o.",
    ".o.",
    ".o.",
    ".o.",
    "ooo",
    ".b.",
    ".b.",
    ".o.",
}

-- The sight the laser beam is aimed with (src/beam.lua). Drawn nose-right like
-- the rocket, and kept at the same ring of eight headings, because it points
-- down the line the beam is about to take and the beam only takes eight.
--
-- The face of the sun that comes up in the corner of the page (src/sun.lua).
-- The disc, its rim and its rays are drawn rather than authored -- they are
-- whatever size the upgrade line says this second -- so the only part of the
-- sun anybody draws is the face laid over the middle of it, which is why this
-- is a face and not a sun.
--
-- Sunglasses and a smile to start with, because the sun in the corner of a
-- school notebook has worn sunglasses since notebooks had corners. Fifteen by
-- nine is about a third of the disc across at its opening size: big enough to
-- letter, small enough that it still reads as a face on a sun rather than a
-- sun made of face. A blank top row is deliberate -- it is where hair, a hat or
-- a pair of eyebrows go for whoever wants them.
Sprites.SUNFACE = {
    "...............",
    ".ooooooooooooo.",
    ".ooo.o...ooo.o.",
    ".oo.oo...oo.oo.",
    "..ooo.....ooo..",
    "...............",
    ".....o...o.....",
    "......ooo......",
    "...............",
}

-- The eight headings of every drawn sprite that has them, by the key it is
-- filed under here. Two have them -- the rocket, which points where it is flying,
-- and the sword, which points where it is being swung; a hero, a star and a face
-- are drawn one way up and stay that way. The rocket's art is nose-right and is
-- read straight off this ring; the sword's is point-up and is read two eighths
-- round it (src/sword.lua), which is the only offset of its kind in the game. The laser beam points where it is going too and
-- is not here, because it has no sprite at all -- see src/beam.lua.
Sprites.turned = {}

-- Rebuilds a drawn sprite from a design, and its ring of headings if `turns`.
-- Called on every pixel the studio changes, so what is replaced is released
-- rather than left for the collector -- the images are small, but a long
-- session of drawing is a lot of them, and a ring is eight at a time.
--
-- A whole ring for an 11x7 design costs a quarter of a millisecond, which is
-- what makes it affordable here, on the cell, rather than deferred to the
-- moment the board is handed over. Nothing else is happening on that screen.
function Sprites.setDrawn(key, rows, turns)
    local old, oldRing = Sprites[key], Sprites.turned[key]

    Sprites[key] = pixelart.newSprite(rows)

    if turns then
        -- Heading one is the drawing as drawn, so the ring opens with the
        -- sprite everything that does not care about heading already uses.
        local ring = { Sprites[key] }
        for e = 1, 7 do
            ring[e + 1] = pixelart.newSprite(pixelart.turn(rows, e))
        end
        Sprites.turned[key] = ring
    end

    if old then
        old.img:release()
        old.mask:release()
    end
    if oldRing then
        for i = 2, #oldRing do -- the first is `old`, just let go of above
            oldRing[i].img:release()
            oldRing[i].mask:release()
        end
    end
end

-- The scrap of ground under someone standing on the page. Measured off the
-- sprite rather than written down as a number, because the player's is drawn by
-- the player and the sprite is whatever they left on the board.
function Sprites.shadow(sprite, x, y)
    local w = sprite.w - 2
    love.graphics.setColor(Palette.graphite)
    love.graphics.rectangle("fill",
        math.floor(x) - math.floor(w / 2),
        math.floor(y) + sprite.h - sprite.oy - 1, w, 1)
end

-- The board under someone riding one, in place of the scrap of ground above: a
-- skate is what the hero is standing on, so there is nothing left for a shadow
-- to be under (Player:draw).
--
-- Placed off the standing sprite for the shadow's own reason -- the hero is drawn
-- by the player and his feet are wherever they left them -- and off the *unbobbed*
-- position, which costs nothing today and is why it is worth saying: a run on a
-- board does not bounce, and a board that bounced with him would be a board
-- coming off the paper.
function Sprites.board(sprite, board, x, y)
    love.graphics.setColor(1, 1, 1)
    board:draw(x, math.floor(y) + sprite.h - sprite.oy - 1)
end

-- A pale blue rim one pixel out all the way round a drawing, drawn *before* the
-- drawing so nothing of what was drawn is covered.
--
-- The cool S wears one (src/cools.lua) because it is six thin strokes crossing a
-- page made of thin strokes and it has to be seen coming. Four offset copies of
-- the sprite's own silhouette rather than authored art, because the things that
-- want a rim are things the player drew and the rim has to fit whatever they
-- left on the board -- which is also why this lives here, next to the shadow,
-- rather than in the module that flies it: the studio's preview (src/studio.lua)
-- has to be able to draw the same rim on the same drawing.
--
-- It never changes what anything hits with. A rim marks out the drawing; the
-- numbers stay measured off the body inside it.
function Sprites.rim(sprite, x, y)
    love.graphics.setColor(Palette.sky)
    sprite:drawMask(x - 1, y)
    sprite:drawMask(x + 1, y)
    sprite:drawMask(x, y - 1)
    sprite:drawMask(x, y + 1)
end

-- Which page the crowd is being drawn on, and the one door to their art.
--
-- A module-level latch rather than an argument threaded through the draw, for
-- Design.applyHero's reason: whichever skin was applied last is the crowd the
-- game draws, so there has to be exactly one place that decides. Game:setSubject
-- is the only caller, beside Background.setSubject and for the same reason -- the
-- page and the crowd on it are one choice.
function Sprites.setSkin(key)
    Sprites.skin = Sprites.enemySkins and Sprites.enemySkins[key] or nil
end

-- Falls through to the unskinned crowd a name at a time rather than a page at a
-- time, so a lesson may reinterpret two of the ten and leave the rest as they
-- are: a page half drawn is a page you can look at, and a page that had to be
-- finished before any of it counted is a page nobody starts.
function Sprites.enemy(name)
    local skin = Sprites.skin
    return (skin and skin[name]) or Sprites.enemies[name]
end

-- The same body gone over in red pen (`fury` in src/spawner.lua): the drawing
-- reduced to two tones, red where it was mostly made of one mark and ink
-- everywhere else (pixelart.twoTone). Same silhouette, same origin, same
-- everything the game measures off a sprite -- an enraged arrival is a colour
-- and never a shape, which is what lets it stack with the two standouts that
-- *are* shapes.
--
-- Two tones because that is what makes it read at a glance in a crowd of two
-- hundred, which the champion's one-pixel rim of ink famously did not
-- (ELITE_GROW, src/spawner.lua). The rest of the page is drawn in a pencil
-- palette against blue ruling; a body that is red and black and nothing else is
-- the loudest thing this palette can say without spending a single extra pixel
-- of paper on it.
--
-- Two tones cannot keep three, and there is one place in the bestiary where that
-- is paid for: the eye and the red-eye are the same eleven pixels across and
-- differ only in the colour of the pupil, so enraged they are the same body. What
-- still tells them apart is the 34 against 9 on their legs, which is the louder
-- half of that distinction anyway -- and it is worth knowing rather than fixing,
-- because fixing it means a third tone on every other body in the game.
--
-- Baked at the first ask and kept on the sprite it came off, rather than built
-- for the whole crowd at load. A run that meets no enraged arrival pays nothing,
-- a run that meets a dozen bats pays once, and the twin is derived from
-- whichever sprite `Sprites.enemy` handed over -- so a page that reskins two of
-- the ten enrages its own art and not the art it replaced. It has to be lazy for
-- one more reason: a skin's origin is patched after it is compiled (Sprites.load),
-- and a twin baked before that would stand a pixel out of the body it is drawn
-- for.
--
-- Only ever asked of the crowd, whose sprites are compiled once at load. A
-- *drawn* sprite is rebuilt on every pixel the studio changes and lets go of the
-- images it replaced (Sprites.setDrawn), which a twin hanging off it would
-- outlive -- so if the player's own drawings ever want one, that release has to
-- learn about it.
function Sprites.enraged(sprite)
    local twin = sprite.enraged
    if not twin then
        assert(sprite.rows, "only ASCII art can be enraged")
        twin = pixelart.newSprite(pixelart.twoTone(sprite.rows, "r", "o"))
        twin.ox, twin.oy = sprite.ox, sprite.oy
        sprite.enraged = twin
    end
    return twin
end

function Sprites.load()
    -- One of each drawn sprite is always standing by, even if nothing has been
    -- drawn yet and nothing was saved from last time.
    Sprites.setDrawn("player", Sprites.STICKMAN)
    Sprites.setDrawn("star", Sprites.STAR)
    Sprites.setDrawn("rocket", Sprites.ROCKET, true)
    Sprites.setDrawn("sunface", Sprites.SUNFACE)
    Sprites.setDrawn("cools", Sprites.COOLS)
    Sprites.setDrawn("bomb", Sprites.BOMB)
    Sprites.setDrawn("sword", Sprites.SWORD, true)
    Sprites.setDrawn("bullet", Sprites.SHOT)
    Sprites.setDrawn("skate", Sprites.SKATE)
    Sprites.setDrawn("lightning", Sprites.LIGHTNING)
    Sprites.setDrawn("bird", Sprites.BIRD)

    Sprites.enemies = {
        -- Blob: the slow, common one.
        blob = pixelart.newSprite({
            "..ssss..",
            ".sggggs.",
            "sggggggs",
            "sgoggogs",
            "sggggggs",
            "sggooggs",
            ".sggggs.",
            "..s..s..",
        }),
        -- Bat: fast, fragile, arrives later. White membrane, red down the body:
        -- it used to be sky, and sky is the colour the ruling is drawn in, so a
        -- bat on a ruled page was a bat the colour of the page it was on. Paper is
        -- the furthest thing from a rule there is, which is what makes the wings
        -- read as a thing standing on the page -- the eye and the ruler body are
        -- white for the same reason -- and the red core says enemy at a glance the
        -- way every other threat now does.
        bat = pixelart.newSprite({
            "s.........s",
            "ss.......ss",
            "sws.sss.sws",
            "swwwrrrwwws",
            ".swworowws.",
            "..ssrrrss..",
            "....sss....",
        }),
        -- Eye: the late one, and the only enemy that attacks from range. Drawn
        -- as an eyeball in paper white -- like the ruler body, it wipes the
        -- ruling rather than stacking on it, which is what makes it read as a
        -- thing sitting on the page instead of another ink doodle. A shade
        -- bigger than the skull: a thing that shoots at you earns being the
        -- first thing you notice walking on.
        eye = pixelart.newSprite({
            "...sssss...",
            "..swwwwws..",
            ".swwwwwwws.",
            "swwwcccwwws",
            "swwcccccwws",
            "swwccoocwws",
            "swwccoocwws",
            "swwwcccwwws",
            ".swwwwwwws.",
            "..swwwwws..",
            "...sssss...",
        }),
        -- Bloodshot eye: the same eyeball with a red pupil -- the one tell,
        -- and it is enough, because red on an enemy means exactly one thing.
        -- Faster on its feet and quicker on the beat (Enemy.types).
        redeye = pixelart.newSprite({
            "...sssss...",
            "..swwwwws..",
            ".swwwwwwws.",
            "swwwcccwwws",
            "swwcccccwws",
            "swwccrrcwws",
            "swwccrrcwws",
            "swwwcccwwws",
            ".swwwwwwws.",
            "..swwwwws..",
            "...sssss...",
        }),
        -- The eye boss: the same eyeball at four times across, which is the
        -- whole of what says "boss" -- nothing else on the page is anywhere
        -- near this size, so it reads as one before it has done anything. The
        -- veins are the bloodshot eye's tell given room to be drawn properly
        -- rather than implied by a red pupil.
        --
        -- Authored with no pupil at all, and that is deliberate: the pupil is
        -- drawn every frame as a disc that slides across the iris towards the
        -- player (Enemy:draw), so the thing watches you. Baking one in and
        -- sliding another over it would leave two. The iris is 19 across and
        -- the pupil is 9, which is what sets how far it may slide -- five
        -- pixels, and the pupil never reaches the rim.
        bosseye = pixelart.newSprite({
            ".................sssssssss.................",
            "..............sssssssssssssss..............",
            "............sssssswwwwwwwssssss............",
            "..........sssswwrwwwwwwwwwwwwssss..........",
            ".........ssswwwwrwwwwwwwwwwwwwrsss.........",
            ".......sssswwwwwrwwwwwwwwwwwwrrwssss.......",
            "......ssswwwwwwwrwwwwwwwwwwwwrwwwwsss......",
            ".....ssswwwwwwwwrrwwwwwwwwwwwrwwwwwsss.....",
            ".....sswwwwwwwwwwrwwwwwwwwwwrwwwwwwwss.....",
            "....sswwwwwwwwwwwwwwwwwwwwwwrwwwwwwwwss....",
            "...ssswwwwwwwwwwwwwwwwwwwwwwrwwwwwwwwsss...",
            "...sswwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwss...",
            "..sswwwwwwwwwwwwwwcccccccwwwwwwwwwwwwwwss..",
            "..sswwwwwwwwwwwwcccccccccccwwwwwwwwwwwwss..",
            ".sswrrwwwwwwwwwcccccccccccccwwwwwwwwwwwwss.",
            ".sswwrrrrwwwwwcccccccccccccccwwwwwwwwwwwss.",
            ".sswwwwwrrrwwcccccccccccccccccwwwwwwwwwwss.",
            "ssswwwwwwwwwwcccccccccccccccccwwwwwwwwwwsss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwwwwwwwwss",
            "sswwwwwwwwwwcccccccccccccccccccwwwrrrwwwwss",
            "ssswwwwwwwwwwcccccccccccccccccwwwwwwrrwwsss",
            ".sswwwwwrwwwwcccccccccccccccccwwwwwwwwrrss.",
            ".ssrrrrrrwwwwwcccccccccccccccwwwwwwwwwwwss.",
            ".sswwwwwwwwwwwwcccccccccccccwwwwwwwwwwwwss.",
            "..sswwwwwwwwwwwwcccccccccccwwwwwwwwwwwwss..",
            "..sswwwwwwwwwwwwwwcccccccwwwwwwwwwwwwwwss..",
            "...sswwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwss...",
            "...ssswwwwwwwwrwwwwwwwwwwwwwwwwwwwwwwsss...",
            "....sswwwwwwwrrwwwwwwwwwwwwwwwwwwwwwwss....",
            ".....sswwwwwrrwwwwwwwwwwwwwwwwwwwwwwss.....",
            ".....ssswwwwrwwwwwwwwwwwwwwwwwwwwwwsss.....",
            "......ssswwrrwwwwwwwwwwwwwwwwwwwwwsss......",
            ".......ssssrwwwwwwwwwwwwwwwwwwwwssss.......",
            ".........ssswwwwwwwwwwwwwwwwwwwsss.........",
            "..........sssswwwwwwwwwwwwwwwssss..........",
            "............sssssswwwwwwwssssss............",
            "..............sssssssssssssss..............",
            ".................sssssssss.................",
        }),
        -- Skull: slow tank, arrives later still.
        skull = pixelart.newSprite({
            "..oooooo..",
            ".okkkkkko.",
            "okkkkkkkko",
            "okookkooko",
            "okookkooko",
            "okkkkkkkko",
            "okkkkkkkko",
            ".okkkkkko.",
            "..oooooo..",
            "...o..o...",
        }),
        -- Wad: a page somebody screwed up and threw away, and it came back.
        -- Round on purpose -- it is the one enemy in the game that commits to a
        -- heading and runs down it (`charge` in Enemy.types), and a thing that
        -- charges must not have a nose, because a sprite is never rotated and a
        -- nose pointing the wrong way during a dash would be worse than none.
        -- A ball is right at every angle.
        --
        -- Paper white with graphite shoulders and a fold ticked top and bottom,
        -- so it reads as a screwed-up sheet rather than as another blob, and the
        -- scribble that got it thrown away showing through the front.
        --
        -- That scribble is blush and not red, which was the page's doing rather
        -- than a preference: red laid over a ruled line comes out *slate*
        -- (Palette.overprint), and on the science page a line crossed this thing
        -- every ten pixels, so a red mark here read as a dark smudge exactly half
        -- the time. A body does not take the page's colour any more
        -- (Overprint.beginSolid), so the argument has gone and the colour has
        -- stayed on its own merits: blush against the white of a screwed-up sheet
        -- is biro, and red at this size would be blood.
        wad = pixelart.newSprite({
            "..sssss..",
            ".sgwswgs.",
            "sgwwwwwgs",
            "swowwwows",
            "swwkkkwws",
            "sgwkkkwgs",
            "swwwkwwws",
            ".sgwswgs.",
            "..sssss..",
        }),
        -- Blot: a bigger, darker blob, and that resemblance is the whole tell.
        -- It breaks into three droplets when it dies (`split`), so what it has
        -- to say from across the page is "the same again, only there will be
        -- more of it" -- which is what a fatter silhouette in solid ink over the
        -- blob's own outline says without a single new shape to learn.
        --
        -- The eyes are holes of paper rather than dots of ink: on a body this
        -- dark an ink feature is invisible, so the one place the page shows
        -- through is where the face is.
        blot = pixelart.newSprite({
            "...ssss...",
            "..soooos..",
            ".soooooos.",
            "soooooooos",
            "sowoooowos",
            "soooooooos",
            ".soooooos.",
            "..soooos..",
            "..s.s..s..",
        }),
        -- Drop: what a blot comes apart into, and nothing else spawns one. Half
        -- the blot in every direction and one eye instead of two, because at
        -- six pixels across a second eye is a smudge -- and because a thing this
        -- small wants to read as a *piece* of what it fell off rather than as a
        -- monster of its own.
        drop = pixelart.newSprite({
            "..ss..",
            ".soos.",
            "soooos",
            "sowoos",
            "soooos",
            ".soos.",
            "..ss..",
        }),
        -- Bulb: a pipette, which is the one piece of laboratory glass a science
        -- page is entitled to and the only enemy here that is an object rather
        -- than a creature. Everything it is for is in the fact that it is drawn
        -- *full*: it walks at you carrying a dose, and when it dies the dose
        -- goes on the page (`burst` in Enemy.types).
        --
        -- Blush glass with the dose pooled in the bottom of it in red, which is
        -- what a pipette looks like and, when it was drawn, what the ruling
        -- allowed: red is the one mark that loses its hue over a printed line --
        -- it comes out slate (Palette.overprint) -- so a body made of it wore a
        -- grey bar through the middle on ruled paper. A body is no longer read
        -- against the page at all (Overprint.beginSolid) and the pairing has kept
        -- its other job, which is the one it was always doing as well: pale glass
        -- around a dark dose is what says the thing is *full*.
        --
        -- The neck is what stops it being the skull at a glance: they are the
        -- only two things on the page built out of blush, and one of them has a
        -- stem and no jaw.
        bulb = pixelart.newSprite({
            "....o....",
            "...ooo...",
            "..okkko..",
            ".okkkkko.",
            "okwkkkwko",
            "okkkkkkko",
            "okrrrrrko",
            "okrrrrrko",
            ".okrrrko.",
            "..ooooo..",
        }),
        -- Grin: the skull's own doodle drawn properly, at fourteen across.
        --
        -- It is the biggest thing on the page short of the boss and the
        -- heaviest -- a shove barely moves it and glue barely holds it (`knock`
        -- and `hold` in Enemy.types) -- and size is the only thing saying so
        -- before it has shrugged anything off, which is why it is the one enemy
        -- allowed to be this big. Nothing else in the crowd reaches past eleven.
        --
        -- Black and white against a crowd that is not. The 10x10 skull is drawn
        -- in blush, like a thing sketched in pink pencil; this one is inked in and
        -- lit with paper -- the eye's trick, for the eye's reason. So the heaviest
        -- thing in the horde is also the one with the least page in it, and it
        -- reads as an object lying on the sheet rather than as another doodle
        -- drawn on it. Nothing in the crowd shows the ruling through it any more
        -- (Overprint.beginSolid), which takes nothing from this: what the paper
        -- was doing here was lighting a skull, and it still is.
        --
        -- What the extra four pixels buy is everything the small skull has no
        -- room for and has to imply: sockets deep enough to be holes, a nasal
        -- aperture, and a jaw with teeth in it instead of two pips hanging under
        -- the chin.
        grin = pixelart.newSprite({
            "...oooooooo...",
            "..owwwwwwwwo..",
            ".owwwwwwwwwwo.",
            "owwwwwwwwwwwwo",
            "owoooowwoooowo",
            "owoooowwoooowo",
            "owoooowwoooowo",
            "owwoowwwwoowwo",
            "owwwwwoowwwwwo",
            "owwwwoooowwwwo",
            ".owwwwwwwwwwo.",
            "..oooooooooo..",
            "..owowowowowo.",
            "..oooooooooo..",
        }),
    }

    -- What the crowd looks like on one particular page.
    --
    -- A lesson is a page and a tool (src/subjects.lua), and this is the third
    -- thing it may be: the crowd reinterpreted as whatever that lesson is
    -- about. It is a *skin* and nothing else -- every number the crowd
    -- is made of stays on the row in Enemy.types, so a blob on the music page is
    -- the same 4hp walking at the same 20px/s with the same 4px radius, and a
    -- build learned on one page reads on every other. Only the drawing changes.
    --
    -- A skin may be drawn *bigger* than the enemy it replaces, and only bigger:
    -- the extra is headroom for what the reinterpretation needs and the enemy
    -- itself does not have -- a stem, a pair of ears, a hat. The hit radius is
    -- still the number on the row, so the grid growing is the one thing here
    -- that changes nothing at all about the fight.
    --
    -- What makes that free is that the origin is pinned to the sprite being
    -- replaced rather than left at the middle of the grid. The rows go on the
    -- top and the columns are split between the sides, and `oy` moves with them,
    -- so `h - oy` -- which is what the shadow is struck off (Enemy:draw) -- comes
    -- out unchanged. The drawing grows upward out of the same feet.
    --
    -- A subject with no skin here is drawn with Sprites.enemies, which is what
    -- makes this cheap to grow: a page is either reinterpreted or it is the
    -- crowd everybody else fights, and there is no third state to keep in step.
    --
    -- The art is authored in art/<subject>/*.txt and baked in here by
    -- `lua art/bake.lua`, which is the one direction it travels. The txt files
    -- are the drawing board and this is the game: nothing reads art/ at runtime,
    -- so a distributable is still src plus two files.
    -- How much bigger than the enemy it replaces a skin may be drawn, in each
    -- direction. Headroom and not a resize: the hit radius does not move, so a
    -- skin drawn to the size it *feels* is a thing the player learns the
    -- silhouette of and then gets hit by four pixels of blank paper beside.
    -- Four is a stem, a pair of ears or a hat. Anything that wants more than
    -- that is a different enemy and wants its own row in Enemy.types.
    local SKIN_ROOM = 4

    -- BAKE:enemySkins begin
    Sprites.enemySkins = {
        art = {
            blob = pixelart.newSprite({
                "..ssss..",
                ".sggggs.",
                "sggggggs",
                "sgoggogs",
                "sggggggs",
                "sggooggs",
                ".sggggs.",
                "..s..s..",
            }),
            bat = pixelart.newSprite({
                "s.........s",
                "ss.......ss",
                "sws.sss.sws",
                "swwwrrrwwws",
                ".swworowws.",
                "..ssrrrss..",
                "....sss....",
            }),
            skull = pixelart.newSprite({
                "..oooooo..",
                ".okkkkkko.",
                "okkkkkkkko",
                "okookkooko",
                "okookkooko",
                "okkkkkkkko",
                "okkkkkkkko",
                ".okkkkkko.",
                "..oooooo..",
                "...o..o...",
            }),
            eye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccoocwws",
                "swwccoocwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
            redeye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccrrcwws",
                "swwccrrcwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
        },
        finance = {
            blob = pixelart.newSprite({
                "..ssss..",
                ".sggggs.",
                "sggggggs",
                "sgoggogs",
                "sggggggs",
                "sggooggs",
                ".sggggs.",
                "..s..s..",
            }),
            bat = pixelart.newSprite({
                "s.........s",
                "ss.......ss",
                "sws.sss.sws",
                "swwwrrrwwws",
                ".swworowws.",
                "..ssrrrss..",
                "....sss....",
            }),
            skull = pixelart.newSprite({
                "..oooooo..",
                ".okkkkkko.",
                "okkkkkkkko",
                "okookkooko",
                "okookkooko",
                "okkkkkkkko",
                "okkkkkkkko",
                ".okkkkkko.",
                "..oooooo..",
                "...o..o...",
            }),
            eye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccoocwws",
                "swwccoocwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
            redeye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccrrcwws",
                "swwccrrcwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
        },
        language = {
            blob = pixelart.newSprite({
                "..ssss..",
                ".sggggs.",
                "sggggggs",
                "sgoggogs",
                "sggggggs",
                "sggooggs",
                ".sggggs.",
                "..s..s..",
            }),
            bat = pixelart.newSprite({
                "s.........s",
                "ss.......ss",
                "sws.sss.sws",
                "swwwrrrwwws",
                ".swworowws.",
                "..ssrrrss..",
                "....sss....",
            }),
            skull = pixelart.newSprite({
                "..oooooo..",
                ".okkkkkko.",
                "okkkkkkkko",
                "okookkooko",
                "okookkooko",
                "okkkkkkkko",
                "okkkkkkkko",
                ".okkkkkko.",
                "..oooooo..",
                "...o..o...",
            }),
            eye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccoocwws",
                "swwccoocwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
            redeye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccrrcwws",
                "swwccrrcwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
        },
        maths = {
            blob = pixelart.newSprite({
                "ssssssss",
                "ssoggoss",
                ".sggggs.",
                ".sgoogs.",
                ".sggggs.",
                ".ss..ss.",
                ".ss...s.",
                ".ss....s",
            }),
            bat = pixelart.newSprite({
                "..ss.....ss..",
                ".swws...swws.",
                "swsswrrrwssws",
                "sws.srors.sws",
                "swsswrrrwssws",
                ".swws...swws.",
                "..ss.....ss..",
            }),
            wad = pixelart.newSprite({
                ".....s...",
                ".....ss..",
                "sssssssss",
                ".....ss..",
                ".....s...",
                "sss...sss",
                "sws...sws",
                ".sws.sws.",
                ".sws.sws.",
                "..skoks..",
                "..swkws..",
                "...sss...",
            }),
            blot = pixelart.newSprite({
                "...........o.o",
                "............o.",
                "....ssssss.o.o",
                "...soooooos...",
                "..soooooooos..",
                ".sooossssooos.",
                ".soowsssswoos.",
                ".soooooooooos.",
                ".soooooooooss.",
                ".soosssssssss.",
                ".sooossssooos.",
                "..soooooooos..",
                "...soooooos...",
            }),
            drop = pixelart.newSprite({
                ".....o.o",
                "......o.",
                "..ssso.o",
                ".sooos..",
                "soswsos.",
                "sooooos.",
                "sosssss.",
                ".soooo..",
                "..s.s...",
            }),
            skull = pixelart.newSprite({
                "....oo....",
                "...okoo...",
                "...okoo...",
                "..okkkoo..",
                "..okkkoo..",
                ".okkkkkoo.",
                ".okokokoo.",
                "okkkkkkkoo",
                "oooooooooo",
                "...o..o...",
            }),
            bulb = pixelart.newSprite({
                "....ooooo....",
                "......o......",
                "...ooooooo...",
                "..orkkkkkro..",
                ".orkwkkkwkro.",
                ".orkkkkkkkro.",
                "..orrrrrrro..",
                "...ooooooo...",
                "......o......",
                "....ooooo....",
            }),
            eye = pixelart.newSprite({
                "......ss...",
                ".....s..s..",
                ".....s.....",
                ".....s.....",
                "...sssss...",
                "..sssssss..",
                ".sswcccwss.",
                ".swwcscwws.",
                "..swcccws..",
                "...sssss...",
                ".....s.....",
                ".....s.....",
                "..s..s.....",
                "...ss......",
            }),
            grin = pixelart.newSprite({
                "oooooo.....ooo",
                "oooowo.....ooo",
                "ooo.owo....ooo",
                "ooo.owo....ooo",
                "ooo..owo...ooo",
                "ooo..owo...ooo",
                "ooo...owo..ooo",
                "ooo...owo..ooo",
                "ooo....owo.ooo",
                "ooo....owo.ooo",
                "ooo.....owoooo",
                "ooo.....owoooo",
                "ooo......owooo",
                "ooo......ooooo",
            }),
            redeye = pixelart.newSprite({
                "......ss...",
                ".....s..s..",
                ".....s.....",
                ".....s.....",
                "...sssss...",
                "..sssssss..",
                ".sswkkkwss.",
                ".swwkskwws.",
                "..swkkkws..",
                "...sssss...",
                ".....s.....",
                ".....s.....",
                "..s..s.....",
                "...ss......",
            }),
        },
        music = {
            blob = pixelart.newSprite({
                "......sss.",
                "......ss.s",
                "......ss.s",
                "......ss.s",
                "...sssss..",
                "..sggggs..",
                ".sgoggogs.",
                ".sggggggs.",
                ".sggooggs.",
                "..sggggs..",
                "...s..s...",
            }),
            bat = pixelart.newSprite({
                "..sssssssss..",
                "..swwwwwwws..",
                "..sssssssss..",
                "..ss.....ss..",
                ".sss....sss..",
                "srrs...srrs..",
                ".ss.....ss...",
            }),
            wad = pixelart.newSprite({
                ".s.......",
                ".s.......",
                ".s.......",
                ".sssssss.",
                ".sogwgos.",
                ".sgwwwgs.",
                ".swkkkws.",
                ".swwkwws.",
                ".sssssss.",
                ".......s.",
                ".......s.",
                ".......s.",
            }),
            blot = pixelart.newSprite({
                "..........sss.",
                "..........ssss",
                "..........os.s",
                ".....ssss.os..",
                "....soooosos..",
                "...sooooooos..",
                "..soooooooos..",
                "..sowoooowos..",
                "..soooooooos..",
                "...soooooos...",
                "....soooos....",
                "....s....s....",
            }),
            drop = pixelart.newSprite({
                ".......ss.",
                ".......s.s",
                "....ss.ss.",
                "...sooss.s",
                "..soooos..",
                "..sowoos..",
                "..soooos..",
                "...soos...",
                "....ss....",
            }),
            skull = pixelart.newSprite({
                "....oooooo....",
                "...okkkkkko...",
                "..okkokkokko..",
                "..okkkkkkkko..",
                "oooooooooooooo",
                "..okkkkkkkko..",
                "..okkkkkkkko..",
                "...okkkkkko...",
                "....oooooo....",
                ".....o..o.....",
            }),
            bulb = pixelart.newSprite({
                "..o.....o..",
                "..o.....o..",
                "..o.....o..",
                ".ooooooooo.",
                "..orkkkro..",
                "..owkkkwo..",
                "..okkkkko..",
                "..okrrrko..",
                ".ooooooooo.",
                "..o.....o..",
                "..o.....o..",
            }),
            eye = pixelart.newSprite({
                "....sss....",
                "....swws...",
                "....sws....",
                "....ss.....",
                "...s.s.....",
                "..s.ssss...",
                ".swscccws..",
                ".swscocwws.",
                ".swwcccwws.",
                ".sswwswws..",
                "...sssss...",
                ".....s.....",
                "..ss.s.....",
                "..sss......",
            }),
            grin = pixelart.newSprite({
                "....ssssssss....",
                "...swwwwwswws...",
                "..swwwssswwwws..",
                ".swwwswwswwwwws.",
                "swwwwwwwwwwwwwws",
                "swwooowwwwooowws",
                "swooooowwooooows",
                "swooooowwooooows",
                "swwwwowwwwowwwws",
                "swwwwwwoowwwwwws",
                ".swwwwwoowwwwws.",
                "..ssswwoowwsss..",
                "....swwwwwws....",
                "....swswwsws....",
                "....swswssws....",
            }),
            redeye = pixelart.newSprite({
                "...ssss....",
                "..swwwws...",
                ".swwwwwws..",
                "skkksswws.r",
                "skoks.sws..",
                "skkks.sws.r",
                ".sss..sws..",
                ".....sws...",
                "....sws....",
                "...sws.....",
                "...ss......",
                "..s........",
            }),
        },
        pe = {
            blob = pixelart.newSprite({
                "..ssss..",
                ".sggggs.",
                "sggggggs",
                "sgoggogs",
                "sggggggs",
                "sggooggs",
                ".sggggs.",
                "..s..s..",
            }),
            bat = pixelart.newSprite({
                "s.........s",
                "ss.......ss",
                "sws.sss.sws",
                "swwwrrrwwws",
                ".swworowws.",
                "..ssrrrss..",
                "....sss....",
            }),
            skull = pixelart.newSprite({
                "..oooooo..",
                ".okkkkkko.",
                "okkkkkkkko",
                "okookkooko",
                "okookkooko",
                "okkkkkkkko",
                "okkkkkkkko",
                ".okkkkkko.",
                "..oooooo..",
                "...o..o...",
            }),
            eye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccoocwws",
                "swwccoocwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
            redeye = pixelart.newSprite({
                "...sssss...",
                "..swwwwws..",
                ".swwwwwwws.",
                "swwwcccwwws",
                "swwcccccwws",
                "swwccrrcwws",
                "swwccrrcwws",
                "swwwcccwwws",
                ".swwwwwwws.",
                "..swwwwws..",
                "...sssss...",
            }),
        },
    }
    -- BAKE:enemySkins end

    for subject, skin in pairs(Sprites.enemySkins) do
        for name, sprite in pairs(skin) do
            local base = Sprites.enemies[name]
            assert(base, ("%s skin has no enemy called '%s'"):format(subject, name))

            local dw, dh = sprite.w - base.w, sprite.h - base.h
            assert(dw >= 0 and dh >= 0 and dw <= SKIN_ROOM and dh <= SKIN_ROOM,
                ("%s %s is %dx%d against a %dx%d enemy -- a skin may be up to %d "):format(
                    subject, name, sprite.w, sprite.h, base.w, base.h, SKIN_ROOM)
                .. "bigger in each direction and never smaller")
            -- Even, so the extra columns split exactly. An odd one is not broken
            -- but it has a side to it -- floor puts the spare column on the right
            -- and nothing in a grid of pixels says which side you drew it on --
            -- so it is refused rather than remembered. A skin therefore keeps its
            -- enemy's width parity: the blob grows 8 to 10 to 12, the bat 11 to
            -- 13 to 15, and both stay centred on what they collide with.
            assert(dw % 2 == 0,
                ("%s %s is %d wider than the enemy it replaces -- widen a skin "):format(
                    subject, name, dw) .. "by an even number so the padding splits evenly")

            -- Derived rather than declared in the txt, because the only thing
            -- that knows where the feet were is the sprite being replaced.
            sprite.ox = base.ox + math.floor(dw / 2)
            sprite.oy = base.oy + dh
        end
    end

    -- The eye's spit. Bigger than the player's bullet and red only at the
    -- core: red says danger, and the heavy ink rim is the second half of the
    -- same sentence -- the player's shot is blue to its edge, this one is dark
    -- to its edge. Colour tells the two apart at a glance now and the rim still
    -- tells them apart where colour cannot, on the one page (ART) that has no
    -- ruling to overprint against.
    Sprites.enemyShot = pixelart.newSprite({
        "..o..",
        ".oro.",
        "orrro",
        ".oro.",
        "..o..",
    })

    -- The boss's, and it is the same pellet grown the way the boss is the eye
    -- grown: same ink rim, same red body, with a blush core that the small one
    -- has no room for. Five of these come at once and they have to be told
    -- apart from the ordinary spit while they are in the air, because they hurt
    -- half again as much and there is no dodging them one at a time.
    Sprites.bossShot = pixelart.newSprite({
        "..ooo..",
        ".orrro.",
        "orrkrro",
        "orkkkro",
        "orrkrro",
        ".orrro.",
        "..ooo..",
    })

    -- A tear, which is the eye crying on the page rather than shooting at it.
    -- Blue where the pellets are red, because what it leaves behind is a puddle
    -- and the puddle is blue: you should be able to read what a thing in the air
    -- is going to become before it lands. Pointed at the top and heavy at the
    -- bottom, so it reads as falling however it is actually travelling -- it is
    -- never turned (see the rendering rules), and a teardrop is the one shape
    -- that looks right at any heading precisely because it always looks like it
    -- is going down.
    Sprites.tear = pixelart.newSprite({
        "..o..",
        "..o..",
        ".obo.",
        "obcbo",
        "obbbo",
        ".ooo.",
    })

    -- The one thing in the game that is an object rather than a mark: a pushpin
    -- driven into the paper. Its origin is the tip rather than the middle, so a
    -- pin's position is the point it goes into the page at -- which is what it
    -- is dropped on, and what its blast is measured from.
    Sprites.pin = pixelart.newSprite({
        "..ooo..",
        ".obcbo.",
        "obcccbo",
        "obbcbbo",
        ".obbbo.",
        "..ooo..",
        "...o...",
        "...o...",
    }, { oy = 7 })

    -- The cloud that rolls in over the page and drops a bolt through it
    -- (src/storm.lua). Authored rather than drawn by the player, and it is the
    -- half of that weapon nobody is asked to draw for one reason: the bolt is
    -- what the weapon *does* and the cloud is only what carries it in, so the
    -- board asks for the strike and hands you the weather.
    --
    -- Paper through the middle with an ink edge round it, which makes it the one
    -- thing in the sky that is opaque: paper is the only colour that covers
    -- (Palette.overprint), so a cloud wipes the ruling and whatever is standing
    -- under it. That is the sun's trade at a fifth of the size and it is taken on
    -- purpose -- a cloud you can see the page through is a doodle, and a cloud is
    -- the one thing on this page that is meant to be read as being *above* it.
    -- Twenty-three by twelve, which is the one number here worth stating: it is
    -- wider than the hero is tall and about a bat and a half across, so what
    -- parks over the crowd is plainly a piece of weather and not a doodle
    -- somebody left. The lumps are four overlapping discs on a flat bottom and
    -- the outline is exactly the pixels round them, so it closes everywhere --
    -- an unclosed edge would be paper touching the page with nothing between,
    -- which reads as a hole rather than as a cloud.
    Sprites.cloud = pixelart.newSprite({
        ".......oooooo..........",
        "......owwwwwwoooo......",
        ".....owwwwwwwwwwwoo....",
        "....owwwwwwwwwwwwwwo...",
        "...oowwwwwwwwwwwwwwoo..",
        "..owwwwwwwwwwwwwwwwwwo.",
        ".owwwwwwwwwwwwwwwwwwwwo",
        ".owwwwwwwwwwwwwwwwwwwwo",
        "owwwwwwwwwwwwwwwwwwwwwo",
        "owwwwwwwwwwwwwwwwwwwwwo",
        ".owwwwwwwwwwwwwwwwwwwwo",
        "..oooooooooooooooooooo.",
    })

    -- Brush tips. Only their silhouettes are used (drawMask), so the colours
    -- here are irrelevant -- each tool tints its own tip as it fades.
    Sprites.tips = {
        -- Ballpoint nib: a round 3px dot, laid one per pixel.
        pen = pixelart.newDisc(1),
        -- The nib its "broader nib" level swaps in (src/tools.lua, the pen's
        -- `broad` block): the same round dot at 7px. It is the wall's doubled
        -- reach drawn, which is the whole point of the level -- a fence that
        -- holds the crowd further off has to look like it does.
        penWide = pixelart.newDisc(3),
        -- No eraser head: the rubber is the one brush that stamps nothing at
        -- all, and what it sheds is particles rather than art.
        -- A chisel nib, held at 45 degrees like a real highlighter: sweeping
        -- across the page lays down a wide band, and the ends come out angled.
        marker = pixelart.newSprite({
            ".......oo",
            "......ooo",
            ".....ooo.",
            "....ooo..",
            "...ooo...",
            "..ooo....",
            ".ooo.....",
            "ooo......",
            "oo.......",
        }),
        -- The same nib one pixel fatter all round, drawn underneath so a rim of
        -- it survives on both edges of the band: the ink that pools at the
        -- edge of a real marker stroke.
        markerEdge = pixelart.newSprite({
            "........ooo",
            ".......oooo",
            "......ooooo",
            ".....ooooo.",
            "....ooooo..",
            "...ooooo...",
            "..ooooo....",
            ".ooooo.....",
            "ooooo......",
            "oooo.......",
            "ooo........",
        }),
        -- The same chisel nib two pixels fatter, for the upgrade that widens
        -- the band (src/tools.lua, the highlighter's `broad` block). Same 45
        -- degree hold, same pooled-ink rim one pixel proud all round.
        markerWide = pixelart.newSprite({
            "..........ooo",
            ".........oooo",
            "........ooooo",
            ".......ooooo.",
            "......ooooo..",
            ".....ooooo...",
            "....ooooo....",
            "...ooooo.....",
            "..ooooo......",
            ".ooooo.......",
            "ooooo........",
            "oooo.........",
            "ooo..........",
        }),
        markerWideEdge = pixelart.newSprite({
            "...........oooo",
            "..........ooooo",
            ".........oooooo",
            "........ooooooo",
            ".......ooooooo.",
            "......ooooooo..",
            ".....ooooooo...",
            "....ooooooo....",
            "...ooooooo.....",
            "..ooooooo......",
            ".ooooooo.......",
            "ooooooo........",
            "oooooo.........",
            "ooooo..........",
            "oooo...........",
        }),
        -- The gluestick's smear: a broad round head, and the same head a pixel
        -- fatter drawn underneath so a rim of it survives all the way round.
        glue = pixelart.newDisc(14),
        glueEdge = pixelart.newDisc(15),
        -- The fatter head its "wider smear" level swaps in: the same pair,
        -- half again as broad.
        glueWide = pixelart.newDisc(20),
        glueWideEdge = pixelart.newDisc(21),
        -- And the head a *pool* is laid with (`pool` in src/tools.lua, the TACK):
        -- one dab rather than a smear of them, so the dab has to be the whole
        -- mark. 25 is the pushpin's crater exactly -- what filled the hole is as
        -- wide as the hole -- which makes it the largest single stamp in the game
        -- at 51 across, and the reason it is a disc rather than a fifth pair of
        -- authored rows: `newDisc` is the same half-pixel bias at every size, so
        -- the rim really is one pixel all the way round.
        gluePool = pixelart.newDisc(25),
        gluePoolEdge = pixelart.newDisc(26),
        -- Wax crayon: a broad soft band with a darker edge where the wax piles
        -- up against the paper. Kept while the crayon sits in Tools.shelved,
        -- since two discs are a rounding error and the tool is one line from
        -- being back on the strip.
        crayon = pixelart.newDisc(6),
        crayonEdge = pixelart.newDisc(7),
        -- The skate's trail (src/skate.lua), and the one nib in the game that is
        -- an oval rather than a disc: a chisel tip that is never turned to face
        -- where you are going (see the rendering rules), so it draws its full
        -- width travelling straight down and only its flat edge travelling
        -- straight across. Six wide because thirteen is the deck of the board
        -- (Sprites.SKATE) -- what is left on the page at its widest is the width
        -- of what left it -- and three tall at the flat end, picked for how thin
        -- it reads (see `FOOT` in src/skate.lua for where it sits, which is a
        -- separate question). `skateEdge` is the same oval a pixel fatter on
        -- both axes, the crayon's rim by the same trick.
        skate = pixelart.newOval(6, 3),
        skateEdge = pixelart.newOval(7, 4),
    }

    Sprites.icons = {
        pencil = pixelart.newSprite({
            ".........o.",
            "........oro",
            ".......oro.",
            "......oro..",
            ".....oro...",
            "....oro....",
            "...oro.....",
            "..ogo......",
            ".ogo.......",
            ".oo........",
            "...........",
        }),
        pen = pixelart.newSprite({
            ".......ooo.",
            "......obbo.",
            ".....obbbo.",
            "....obbbo..",
            "...obbbo...",
            "..obbbo....",
            "..obbo.....",
            ".oobo......",
            ".obo.......",
            "oo.........",
            "...........",
        }),
        rubber = pixelart.newSprite({
            "...........",
            "...sssss...",
            "..skkkkks..",
            "..skkkkks..",
            "..sssssss..",
            "..sgggggs..",
            "..sgggggs..",
            "..sgggggs..",
            "..sssssss..",
            "...........",
            "...........",
        }),
        marker = pixelart.newSprite({
            "...ooooo...",
            "...obbbo...",
            "...obbbo...",
            "..ooooooo..",
            "..obbbbbo..",
            "..obbbbbo..",
            "..obbbbbo..",
            "..ooooooo..",
            "...okkko...",
            "..okkkkko..",
            "..ooooooo..",
        }),
        -- Upright, where the pencil and pen lie at 45 degrees: at 11x11 the
        -- silhouette is doing more work than the colours.
        crayon = pixelart.newSprite({
            "...........",
            "....ooo....",
            "...occco...",
            "...occco...",
            "..occccco..",
            "..obbbbbo..",
            "..obbbbbo..",
            "..occccco..",
            "..occccco..",
            "..ooooooo..",
            "...........",
        }),
        glue = pixelart.newSprite({
            "...ooooo...",
            "..owwwwwo..",
            "..owwwwwo..",
            ".ooooooooo.",
            ".occccccco.",
            ".occccccco.",
            ".occccccco.",
            ".occccccco.",
            ".occccccco.",
            ".ooooooooo.",
            "...........",
        }),
        -- Drawn the way it lands: paper body, ink edge, slate graduations down
        -- one side. The icon is the thing itself rather than a second drawing
        -- of it, so what you press for is what arrives on the page.
        ruler = pixelart.newSprite({
            "...........",
            "...........",
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "...........",
            "...........",
        }),
        -- Side on, the one angle a stapler is recognisable from: the arm on
        -- top, the gap you slide the paper into, the body, and a base plate a
        -- shade wider than both. The hinge is the three pixels at the back that
        -- close the gap -- without them the arm reads as a separate object
        -- floating above a box.
        stapler = pixelart.newSprite({
            "...........",
            "..ooooooo..",
            "..orrrrro..",
            "..ooooooo..",
            "......ooo..",
            "..ooooooo..",
            "..ossssso..",
            "..ooooooo..",
            ".ooooooooo.",
            "...........",
            "...........",
        }),
        -- Both legs splayed to about the width it draws at, hinge at the top:
        -- the silhouette says compass on its own, and the two tips say which
        -- leg is which -- red needle on one, graphite lead on the other, the
        -- same two colours they are drawn in on the page.
        compass = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.........g",
            "...........",
        }),
        -- The compass with a nib in its leg (the HALO, src/tools.lua), which is
        -- what the icon says and all it says: the same silhouette, the lead gone
        -- blue where it was graphite, and the band it now leaves lying under the
        -- whole figure. A fusion's icon is one of its parents wearing the other
        -- rather than a third drawing -- what the tool *is* is "the compass, but",
        -- and an icon you cannot place next to the two lines it ate is a card
        -- nobody reads as a fusion.
        halo = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.........b",
            ".ccccccccc.",
        }),
        -- The compass with a broadened lead in its leg (the LASSO,
        -- src/tools.lua), read the same way round as the halo above: the
        -- silhouette is the compass's, the lead is two pixels of graphite where
        -- the compass has one -- the point pressed harder -- and the ring lying
        -- under the whole figure is the graphite one it leaves, where the halo's
        -- is a band of sky. Two fusions off the same parent have to be told apart
        -- at a glance on the shelf, so what each one changed about the compass is
        -- exactly what its icon shows.
        lasso = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r........gg",
            ".ggggggggg.",
        }),
        -- And the compass with the stick in its leg (the MOAT, src/tools.lua),
        -- read the same way round again: the silhouette is the compass's, the
        -- lead is a fat paper head in an ink rim -- which is how the gluestick's
        -- own icon draws paste, and the only lead of the three wide enough to
        -- need a rim to be seen at all -- and what lies under the figure is the
        -- smear it leaves, paper rimmed the same way. Three fusions off one
        -- parent have to be told apart at a glance on the shelf, so each one
        -- shows what it changed about the compass and nothing else: a blue lead
        -- over a band of sky, a doubled graphite lead over a graphite ring, and
        -- a loaded head over a smear.
        moat = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.......owo",
            ".owwwwwwwo.",
        }),
        -- And the compass with a blade in its leg (the PUNCH, src/tools.lua).
        -- The lead is slate under an ink edge, which is how the scissors' own
        -- icon draws steel and how everything metal is drawn here, and what lies
        -- under the figure is the one thing none of the other three leaves: not a
        -- mark at all but a dotted line, the page opened rather than drawn on.
        -- Four fusions off one parent, and the bottom row of each is the whole
        -- difference between them -- a band of sky, a graphite ring, a paper
        -- smear, and cut along the dotted line.
        punch = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r........so",
            ".g.g.g.g.g.",
        }),
        -- And the compass with a pushpin for a lead (the SPINDLE,
        -- src/tools.lua). The lead is a blue head in an ink rim, which is how the
        -- pushpin's own icon draws a pinhead, and the bottom row is the one thing
        -- this fusion leaves that no other mark in the game leaves: not ink at all
        -- but the drag, in slate, with a pin standing in the page at the end of
        -- it. Five fusions off one parent and the bottom row is still the whole
        -- difference between them -- a band of sky, a graphite ring, a paper
        -- smear, a dotted line, and something nailed down where the arm stopped.
        spindle = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.......obo",
            ".ssssssssb.",
        }),
        -- And the compass with a pen in its leg (the CORRAL, src/tools.lua). The
        -- lead is two pixels of blue where the compass has one of graphite -- the
        -- ballpoint at twice its reach, which is the same doubling the lasso's
        -- icon shows in graphite -- and the bottom row is the one thing this
        -- fusion leaves that nothing else in the game leaves at all: not a mark
        -- fading but a solid unbroken line of ink, edge to edge, which is what a
        -- wall looks like when it is drawn. Six fusions off one parent and the
        -- bottom row is still the whole difference between them -- a band of sky,
        -- a graphite ring, a paper smear, a dotted line, something nailed down,
        -- and a fence.
        corral = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r........bb",
            ".bbbbbbbbb.",
        }),
        -- And the compass working a stapler (the HEM, src/tools.lua). The lead
        -- is the crown of a staple seen end-on -- three pixels of ink, which is
        -- how the stapler's own icon draws the arm that presses -- and the bottom
        -- row is the seam it leaves: staples, drawn as the crowns they are, with
        -- the paper showing between them. Seven fusions off one parent and the
        -- bottom row is still the whole difference between them -- a band of sky,
        -- a graphite ring, a paper smear, a dotted line, something nailed down, a
        -- fence, and a row of wire.
        hem = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.......ooo",
            "ooo.ooo.ooo",
        }),
        -- And the compass with a rubber in its leg (the CLEARING, src/tools.lua).
        -- The lead is a block of slate under an ink edge, which is how the
        -- rubber's own icon draws the thing, and the bottom row is the only one of
        -- the eight that is not something the tool left: it is the page *cleared*
        -- -- crumbs thrown out to both sides of a stretch of nothing, which is
        -- exactly what a rub leaves and exactly what this fusion does to the
        -- middle of its own circle. Eight fusions off one parent and the bottom
        -- row is still the whole difference between them: a band of sky, a
        -- graphite ring, a paper smear, a dotted line, something nailed down, a
        -- fence, a row of wire, and nothing at all with the dust still settling.
        clearing = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.......ooo",
            "r.......oso",
            "gg.g....g.g",
        }),
        -- And the compass carrying *nothing* (the FOLD, src/tools.lua), which is
        -- why this is the only fusion icon whose leg ends in the plain graphite
        -- lead the COMPASS's own icon has: what this one changed is not in the leg.
        -- The bottom row is a line ruled between two crossings -- ink, the ruler's
        -- own colour, and the only mark on the shelf that stops short of both
        -- edges, because where it stops is decided by two circles rather than by
        -- the tool. Nine fusions off one parent and the bottom row is still the
        -- whole difference between them: a band of sky, a graphite ring, a paper
        -- smear, a dotted line, something nailed down, a fence, a row of wire,
        -- nothing at all with the dust still settling, and a line with two ends.
        fold = pixelart.newSprite({
            "....ooo....",
            "...okkko...",
            "...oo.oo...",
            "...o...o...",
            "..o.....o..",
            "..o.....o..",
            ".o.......o.",
            ".o.......o.",
            "o.........o",
            "r.........g",
            "...ooooo...",
        }),
        -- Head-on, where the pin on the page is seen at the same angle
        -- everything else standing on it is: the icon is the thing itself, one
        -- size up, rather than a second drawing of it.
        pushpin = pixelart.newSprite({
            "....ooo....",
            "...obcbo...",
            "..obcccbo..",
            "..obbcbbo..",
            "..obbbbbo..",
            "...obbbo...",
            "....ooo....",
            ".....o.....",
            ".....o.....",
            ".....s.....",
            "...........",
        }),
        -- And the fusions off the pushpin (src/tools.lua), which are the
        -- first fusion icons that are not one instrument at all. Five of the
        -- seven string something between two pins and their icons say so: two
        -- pinheads seen head-on exactly as the pin above is seen, a head short of
        -- the pin's seven so that two of them fit the same eleven pixels, and a
        -- thread strung between the shafts. The nine compass fusions put the
        -- whole difference between them in the bottom row; these put it in the
        -- middle, because what this family changed is not what the tool leaves
        -- under itself -- it is what happens *between* two of them.
        --
        -- Graphite with the grain showing off both sides of it, which is how the
        -- pencil's own icon draws a line: the thread is the broad point pressed
        -- harder, and the two stray pixels are what a pencil does that no other
        -- nib on the page does.
        dots = pixelart.newSprite({
            "...........",
            ".ooo...ooo.",
            "occbo.occbo",
            "obbbo.obbbo",
            ".ooo...ooo.",
            "..o.....o..",
            "..o..g..o..",
            "..ogggggo..",
            "..o.g...o..",
            "..s.....s..",
            "...........",
        }),
        -- Two solid rows of blue, which is the CORRAL's bottom row turned into a
        -- rail: a ballpoint at twice its reach, unbroken, running post to post.
        -- Solid rather than fading is the whole of what a wall looks like when it
        -- is drawn, and the two posts are what this one has that the corral's
        -- ring does not.
        stockade = pixelart.newSprite({
            "...........",
            ".ooo...ooo.",
            "occbo.occbo",
            "obbbo.obbbo",
            ".ooo...ooo.",
            "..o.....o..",
            "..o.....o..",
            "..obbbbbo..",
            "..obbbbbo..",
            "..s.....s..",
            "...........",
        }),
        -- And a band of sky in a blue rim, which is how the highlighter's own nib
        -- is drawn and what the HALO's bottom row shows: the ink pools at the
        -- edges of the chisel and the middle is the pale wash. The widest of the
        -- three threads, because the marker's nib is the widest of the three nibs.
        cordon = pixelart.newSprite({
            "...........",
            ".ooo...ooo.",
            "occbo.occbo",
            "obbbo.obbbo",
            ".ooo...ooo.",
            "..o.....o..",
            "..obbbbbo..",
            "..occccco..",
            "..obbbbbo..",
            "..s.....s..",
            "...........",
        }),
        -- And the two pushpin fusions whose thread is not a mark at all but a
        -- whole second tool cast along the line the pins aim (src/tools.lua).
        -- Both put it in the *bottom rows* rather than between the shafts, which
        -- is the nine compass icons' arrangement and it is saying the same thing
        -- they say: what these two leave runs edge to edge and does not stop
        -- where the pins are.
        --
        -- The ruler is the RULER's own icon copied across -- paper body, ink
        -- edge, slate graduations down one side -- because that is what arrives
        -- on the page and the icon is the thing itself. It covers the shafts
        -- rather than dodging them, since paper is the one colour that wipes what
        -- is under it and a ruler lying on a page really does hide the pins it
        -- was laid against.
        snapline = pixelart.newSprite({
            ".ooo...ooo.",
            "occbo.occbo",
            "obbbo.obbbo",
            ".ooo...ooo.",
            "..o.....o..",
            "..o.....o..",
            "..s.....s..",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
        }),
        -- And the page opened along the line instead: a dashed slit, in graphite,
        -- edge to edge. The PUNCH's bottom row is the same idea in short dots
        -- because what a punch takes out is a circle; these are long dashes,
        -- because what this leaves is a *tear* across the whole page and the two
        -- have to be told apart on a shelf.
        tearline = pixelart.newSprite({
            ".ooo...ooo.",
            "occbo.occbo",
            "obbbo.obbbo",
            ".ooo...ooo.",
            "..o.....o..",
            "..o.....o..",
            "..o.....o..",
            "..s.....s..",
            "...........",
            "ggg.ggg.ggg",
            "...........",
        }),
        -- And the two that are one pin rather than two (`pool` in src/tools.lua),
        -- which is the whole of what their icons say before a word is read: the
        -- drawing is the PUSHPIN's own, head-on, unchanged, with what the pin
        -- leaves *under* it. That is the compass family's arrangement borrowed
        -- wholesale -- one silhouette, and the bottom rows are the difference.
        --
        -- Paste: paper in a graphite rim, spreading as it goes down, which is how
        -- the gluestick's own icon draws the stick and how its mark is drawn on
        -- the page. The shaft goes straight into it and the tip is not drawn at
        -- all, because paper covers what is under it.
        tack = pixelart.newSprite({
            "....ooo....",
            "...obcbo...",
            "..obcccbo..",
            "..obbcbbo..",
            "..obbbbbo..",
            "...obbbo...",
            "....ooo....",
            ".....o.....",
            "...ggggg...",
            ".gwwwwwwwg.",
            "gwwwwwwwwwg",
        }),
        -- And the one that leaves nothing: crumbs thrown out to both sides of a
        -- stretch of clear page, which is the CLEARING's bottom row for the
        -- CLEARING's reason -- a rubber does not put anything down, and what is
        -- left where it worked is the dust still settling and a gap in the middle
        -- where everything used to be standing.
        crater = pixelart.newSprite({
            "....ooo....",
            "...obcbo...",
            "..obcccbo..",
            "..obbcbbo..",
            "..obbbbbo..",
            "...obbbo...",
            "....ooo....",
            ".....o.....",
            ".....o.....",
            ".....s.....",
            "gg.g...g.gg",
        }),
        -- And the one that is neither strung nor pooled: three pins marching down
        -- the page, which is the seam a drag rakes. It is drawn out of the
        -- *thread* family's parts rather than the pushpin's -- the same head seen
        -- head-on, one row shorter so that three of them fit the diagonal -- and
        -- with **nothing between them**, which is the icon's whole statement. That
        -- is why the head had to be borrowed rather than invented: on five other
        -- cards these heads have a mark strung between the shafts, so a player who
        -- has seen one of those reads the empty page here as an absence and not as
        -- a gap. Three of them on a diagonal then says the rest -- what this tool
        -- has that its parent has not is *more pins*, laid along a line you drag,
        -- and a row of holes is what that leaves.
        volley = pixelart.newSprite({
            ".ooo.......",
            "occbo......",
            ".ooo.......",
            "...........",
            "....ooo....",
            "...occbo...",
            "....ooo....",
            "...........",
            ".......ooo.",
            "......occbo",
            ".......ooo.",
        }),

        -- The ruler's seven, and they are drawn the way the compass's nine and the
        -- pushpin's eight are: the gesture across the top and what it left on the
        -- page underneath. Four rows of straight edge -- the two long sides, the
        -- graduations down one of them, and the body between -- which is the RULER
        -- icon a row shorter so there is room for a mark below it. Every one of
        -- these is the same object doing the same thing, so the only thing that
        -- tells them apart at icon size is what is lying under it, which is exactly
        -- what tells them apart on the page.

        -- Two pencil lines, one either side, because that is where they go
        -- (`margins` in src/tools.lua). The only icon in the set with anything
        -- above the ruler as well as below it, and it has to be: a mark down one
        -- edge would read as any of the other six.
        margin = pixelart.newSprite({
            "...........",
            "ggggggggggg",
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "ggggggggggg",
            "...........",
            "...........",
        }),
        -- The pen's wall, in the solid blue the CORRAL and the STOCKADE already
        -- use for the same fence, and three rows of it: the broad nib is 7px on
        -- the page and this is the widest mark in the set, as it should be.
        spine = pixelart.newSprite({
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "bbbbbbbbbbb",
            "bbbbbbbbbbb",
            "bbbbbbbbbbb",
            "...........",
            "...........",
        }),
        -- The band, sky with the blue where the ink pools at the rim, which is the
        -- CORDON's two rows and the HALO's colours. Under the ruler and nowhere
        -- else, since the tool is called what it is for a reason.
        underline = pixelart.newSprite({
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "bbbbbbbbbbb",
            "ccccccccccc",
            "ccccccccccc",
            "bbbbbbbbbbb",
            "...........",
        }),
        -- Paste: paper with a graphite rim, the TACK's and the MOAT's language.
        -- Paper is the one colour that wipes what is under it rather than stacking
        -- with it, so the bar reads as something lying on the page exactly as the
        -- smear does.
        trench = pixelart.newSprite({
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "ggggggggggg",
            "wwwwwwwwwww",
            "wwwwwwwwwww",
            "ggggggggggg",
            "...........",
        }),
        -- The rubber leaves nothing, so there is nothing to draw under the ruler
        -- and the crumbs go *both* ways instead -- the CLEARING's broken bottom row,
        -- above and below, thrown away from the line. It is the only icon in the set
        -- where the mark is not a bar, which is right: the only one where there is
        -- no mark.
        parting = pixelart.newSprite({
            "..g.....g..",
            "...........",
            ".g...g...g.",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            ".g.....g...",
            "...........",
            "..g...g..g.",
            "...........",
        }),
        -- Wire, and it is the HEM's crown row with the legs added: a stapler seen
        -- from the side is a crown and two legs, and a seam of them is that repeated
        -- at the spacing the tool actually uses.
        seam = pixelart.newSprite({
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "ooooooooooo",
            "...........",
            "ooo.ooo.ooo",
            "o.o.o.o.o.o",
            "...........",
            "...........",
            "...........",
        }),
        -- The slit, in the TEAR LINE's dashes, and a red edge on the underside of
        -- the straight edge -- which is the one place in the set the ruler itself is
        -- drawn differently, because here it has a blade on it. Red is the colour
        -- the ruler is already drawn in for the first half of its slap (Ruler:draw),
        -- so it reads as the edge that lands rather than as a decoration.
        guillotine = pixelart.newSprite({
            "...........",
            "ooooooooooo",
            "oswswswswso",
            "owwwwwwwwwo",
            "rrrrrrrrrrr",
            "...........",
            "ggg.ggg.ggg",
            "...........",
            "...........",
            "...........",
            "...........",
        }),

        -- **The six off the PENCIL, and they are read the way the compass's nine
        -- are.** There the silhouette is always the compass and what changed is
        -- always the leg; here the silhouette is always the pencil -- the same
        -- diagonal shaft, the same red barrel, the same graphite point -- and what
        -- changed is always what is lying under it. A shelf of five fusions off one
        -- parent has to be told apart at a glance, so each icon shows exactly the
        -- one thing its row did to the pencil and nothing else.
        --
        -- Three of them are a *ring*, because three of them are about what closing
        -- a line does (`loop` in src/tools.lua): the fence that shuts them in, the
        -- ring that lights what it holds, and the hole the paper goes with. They
        -- share the ring and differ in its colour and its middle, which is the
        -- whole of the difference between the rows. The other two are not about the
        -- ring at all, so neither draws one, and nor does the sixth.
        --
        -- The pen's blue, and the ring drawn with gaps in it -- which is the one
        -- icon in the game whose outline is deliberately broken. A deckle edge is
        -- what an untrimmed sheet looks like, the row lays 3 ragged pixels where a
        -- ballpoint lays 7 smooth ones, and a solid ring here would have drawn the
        -- CORRAL. The red pixel in the middle is the one thing a pen has never been
        -- able to put there.
        deckle = pixelart.newSprite({
            "........oro",
            ".......oro.",
            "......oro..",
            ".....ogo...",
            "....ogo....",
            "...oo......",
            "..bb.bb....",
            ".b.....b...",
            ".b..r..b...",
            ".b.....b...",
            "..bb.bb....",
        }),
        -- The one of the five that changes the *top* of the pencil rather than
        -- what is under it, because that is where the tool's second half actually
        -- is: a blush nub at the ferrule end, which is a rubber crimped to a pencil
        -- and is the whole object the row is named for. What comes off the point is
        -- graphite crumbs rather than a mark, which is what the rubber leaves
        -- everywhere else in the game and the only thing the tap puts on the page.
        stub = pixelart.newSprite({
            "........oko",
            ".......oko.",
            "......oro..",
            ".....oro...",
            "....oro....",
            "...ogo.....",
            "..ogo......",
            ".oo........",
            "g..g...g...",
            "..g..g.....",
            "...........",
        }),
        -- The marker's sky for the ring and red for what is standing in it, which
        -- is the icon saying the trade in two colours: the band is the pale wash it
        -- always was, and the burning is inside it rather than on it. Red is the
        -- fire and not the horde -- an icon is drawn past the overprint pass, over
        -- the page rather than on it, and red there means the thing this does (see
        -- the bullseye below).
        bleed = pixelart.newSprite({
            "........oro",
            ".......oro.",
            "......oro..",
            ".....ogo...",
            "....ogo....",
            "...oo......",
            "..ccccc....",
            ".crrrrrc...",
            ".crrrrrc...",
            ".crrrrrc...",
            "..ccccc....",
        }),
        -- No ring, because this row is not about closing one: it is about the
        -- ground either side of the line. A graphite rule with four bodies falling
        -- in towards it from both sides, drawn in slate so they read as the crowd
        -- rather than as more of the mark -- the only icon in the game whose
        -- subject is the empty page around the ink.
        drag = pixelart.newSprite({
            "........oro",
            ".......oro.",
            "......oro..",
            ".....ogo...",
            "....ogo....",
            "...oo......",
            "..s.....s..",
            "...s...s...",
            ".ggggggggg.",
            "...s...s...",
            "..s.....s..",
        }),
        -- An ink ring with grey where the paper used to be, which is exactly what
        -- the scissors' offcut is drawn as (`Background.torn`) and the same grey
        -- for the same reason: what says a piece of page is gone is the white going
        -- out of it. The only filled ring of the three, because it is the only one
        -- whose middle is not page any more.
        cutout = pixelart.newSprite({
            "........oro",
            ".......oro.",
            "......oro..",
            ".....ogo...",
            "....ogo....",
            "...oo......",
            "..ooooo....",
            ".ogggggo...",
            ".ogggggo...",
            ".ogggggo...",
            "..ooooo....",
        }),
        -- And the sixth, which is the only one of the six that draws neither a ring
        -- nor a change to the pencil itself: a graphite line with a staple driven
        -- into each end of it. Slate under an ink cap is how everything metal is
        -- drawn here and how the stapler's own icon draws wire, and the two of them
        -- at the ends rather than along the line is the whole difference between
        -- this row and the seam its parent's finale runs.
        stitch = pixelart.newSprite({
            "........oro",
            ".......oro.",
            "......oro..",
            ".....ogo...",
            "....ogo....",
            "...oo......",
            "...........",
            ".ooo...ooo.",
            ".oso...oso.",
            ".ggggggggg.",
            "...........",
        }),

        -- And the three off two brushes with no pencil between them
        -- (src/tools.lua). The six above could all lean on one silhouette, because
        -- all six were a pencil and the icon only had to say what had been done to
        -- it. These three have no shared parent, so they follow the rule the rows
        -- themselves are written on: **the object drawn is the nib that lays the
        -- line -- the parent whose mark is the body -- and what is drawn under it is
        -- what the row does.** So the pen is the object twice and the marker once,
        -- which is the same count the rows have, and the second parent never appears
        -- as a thing: it appears as what is happening on the page.
        --
        -- The pen compressed to six rows the way the pencil was, blue all the way
        -- down where the pencil turns graphite at the point -- and then a blue fence
        -- with two bodies coming off it, slate so they read as the crowd rather than
        -- as more of the mark, with a graphite speck each where they left. The
        -- DRAG's icon is the same subject the other way round -- bodies falling in
        -- towards a line -- and the two are told apart by the colour of the line and
        -- by everything here being on one side of it, which is what a bounce is.
        bumper = pixelart.newSprite({
            "........obo",
            ".......obo.",
            "......obo..",
            ".....obo...",
            "....obo....",
            "...oo......",
            ".bbbbbbbbb.",
            "...........",
            "..g.....g..",
            ".s.......s.",
            "...........",
        }),
        -- The one icon in the game that draws a line at two widths, because that is
        -- the row: thin where it leaves the nib and swollen at the far end, which is
        -- a swelled rule and is what the tool leaves when your hand slows down. Red
        -- over the heavy end is the burn, and red for the marker's fire is the
        -- BLEED's precedent -- an icon is drawn past the overprint pass, over the
        -- page rather than on it, and red there means the thing this does.
        swell = pixelart.newSprite({
            "........obo",
            ".......obo.",
            "......obo..",
            ".....obo...",
            "....obo....",
            "...oo......",
            "......r.r..",
            ".....bbbbb.",
            ".bbbbbbbbb.",
            ".....bbbbb.",
            "...........",
        }),
        -- The marker's own silhouette, shifted off centre to leave the page room for
        -- what it lays: the sky band it always laid, with two graphite crumbs
        -- between the two. The crumbs are the whole of the second parent here, and
        -- they are the right whole -- a rubber's own icon is a block of blush and
        -- slate, and drawing that as well would have said the row is two tools you
        -- carry rather than one tool with two gestures. What a rub leaves is crumbs,
        -- which is what the tap puts on the page and the only thing it does that can
        -- be drawn lying still.
        scuff = pixelart.newSprite({
            ".ooooo.....",
            ".obbbo.....",
            "ooooooo....",
            "obbbbbo....",
            "ooooooo....",
            ".okkko.....",
            "...........",
            "..g.....g..",
            ".ccccccccc.",
            ".ccccccccc.",
            "...........",
        }),

        -- The gluestick's three. One silhouette between them the way the pencil's
        -- six shared one, because all three of these *are* the gluestick -- the
        -- stick compressed to six rows, white cap and sky barrel, exactly as its own
        -- icon draws it -- and what changes is the bar of paste underneath. Which is
        -- the rows' own argument drawn: the smear is the mark in all three and the
        -- second parent is a property of it, so the second parent is never an object
        -- here either.
        --
        -- Blue paste in an ink rim, which is the row's own recolouring -- terrain has
        -- to read as terrain -- with one body stuck inside it and one pressed against
        -- the outside face. That pair of pixels is the whole tool: nothing in,
        -- nothing out.
        pastedown = pixelart.newSprite({
            "...ooooo...",
            "..owwwwwo..",
            ".ooooooooo.",
            ".occccccco.",
            ".occccccco.",
            ".ooooooooo.",
            ".ooooooooo.",
            ".obbbbbbbo.",
            ".obbsbbbbo.",
            ".ooooooooo.",
            "......s....",
        }),
        -- The glue's own white paste in its own grey rim -- a rubber leaves nothing,
        -- so there is nothing of the second parent to colour -- with two bodies stuck
        -- in the bar and two more closing on it from outside. The DRAG's icon is the
        -- nearest thing to this and the difference is which is which: there four
        -- bodies fall in towards a 1px pencil line, and here two of them have already
        -- arrived and are in the paste.
        pulp = pixelart.newSprite({
            "...ooooo...",
            "..owwwwwo..",
            ".ooooooooo.",
            ".occccccco.",
            ".occccccco.",
            ".ooooooooo.",
            "..s.....s..",
            "..ggggggg..",
            "..gwswswg..",
            "..ggggggg..",
            "..s.....s..",
        }),
        -- Sky paste with the marker's blue at the rim where the ink pools, and red
        -- filling the middle of it: the BLEED's own reading, where red is the thing
        -- the tool does rather than the crowd it does it to. An icon is drawn past
        -- the overprint pass, over the page rather than on it, so red there is never
        -- mistaken for an enemy.
        mordant = pixelart.newSprite({
            "...ooooo...",
            "..owwwwwo..",
            ".ooooooooo.",
            ".occccccco.",
            ".occccccco.",
            ".ooooooooo.",
            "...........",
            ".bbbbbbbbb.",
            ".bcrrrrrcb.",
            ".bcrrrrrcb.",
            ".bbbbbbbbb.",
        }),

        -- The stapler's three, and they share a skeleton the way the gluestick's do:
        -- a seam of staples across the top -- three crowns with their legs turned
        -- down, which is how every icon in the game draws wire (the SEAM, the HEM) --
        -- and underneath it whatever the row hangs off that seam. The STOCKADE and
        -- the CORDON are the two icons to read these against: there two pushpin heads
        -- with a rail between them, here a *run* of staples with the same rail under
        -- it, which is the reach of the thread drawn rather than stated.
        --
        -- Solid blue three rows deep, because what this row strings is a wall, with
        -- the crowd held off the far side of it. The PALING and the WICK differ in
        -- exactly the band and in nothing else, which is the truth about the two
        -- rows.
        paling = pixelart.newSprite({
            "...........",
            "...........",
            "ooo.ooo.ooo",
            "o.o.o.o.o.o",
            "...........",
            ".bbbbbbbbb.",
            ".bbbbbbbbb.",
            ".bbbbbbbbb.",
            "...........",
            "..s.....s..",
            "...........",
        }),
        -- The marker's band in the marker's two colours -- blue where the ink pools
        -- at the rim, and the middle of it running red, which is the BLEED's reading
        -- of red as the thing the tool does rather than the crowd it does it to. No
        -- bodies held off this one: a wick does not stop anybody, and what it costs to
        -- cross is the whole row.
        wick = pixelart.newSprite({
            "...........",
            "...........",
            "ooo.ooo.ooo",
            "o.o.o.o.o.o",
            "...........",
            ".bbbbbbbbb.",
            ".crrrrrrrc.",
            ".bbbbbbbbb.",
            "...........",
            "...........",
            "...........",
        }),
        -- And the one of the three that strings nothing, so there is no band under the
        -- seam at all -- what is under it is the crowd, stuck to it. Slate bodies each
        -- on a shadow of sky, which is not a decision so much as a quotation: a held
        -- body in this game stops moving and grows a blue shadow, and that is the only
        -- thing a hold has ever looked like. Four of them, at two different distances,
        -- because the point of the row is that the wire goes on collecting things it
        -- never landed on.
        clinch = pixelart.newSprite({
            "...........",
            "ooo.ooo.ooo",
            "o.o.o.o.o.o",
            "...........",
            "..s.....s..",
            "..c.....c..",
            "...........",
            "...s...s...",
            "...c...c...",
            "...........",
            "...........",
        }),
        -- And the fourth, which is the one of them that draws no seam -- because the
        -- one thing that row does not have is `rake`, and a bar of staples across the
        -- top would have promised the gesture it gave up. Two staples instead, and
        -- the right-hand one is a row higher with a red pixel under it: the wire on
        -- its way out of the paper, which is what this tool does that no other does.
        --
        -- The rubber above it is the SCUFF's rule the other way up. There the second
        -- parent could not be drawn as an object -- a block of blush and slate beside
        -- a marker would have said "two tools you carry" -- and here it is the *first*
        -- parent and the object is the point: the rub is what comes and gets the
        -- staples, so the thing doing the getting is what the icon leads with. Its own
        -- five-pixel silhouette, blush over graphite in a slate rim, exactly as the
        -- rubber's own icon draws it at seven. The two graphite pixels along the
        -- bottom are the crumbs, which is what a rub leaves everywhere in this game.
        snag = pixelart.newSprite({
            ".sssss.....",
            ".skkks.....",
            ".sssss.....",
            ".sgggs.....",
            ".sssss.....",
            "...........",
            ".......ooo.",
            "..ooo..o.o.",
            "..o.o...r..",
            "..g.....g..",
            "...........",
        }),
        -- And the scissors' fifth and last, which is two rows this table already
        -- has, stacked: the blades crossing above (the SCISSORS' own top half, ink,
        -- with the pivot left in so it reads as a hinge of its own) and the SEAM's
        -- crown-and-legs row below it, over the TEAR LINE's dashed slit.
        --
        -- Three bands rather than two, which every other fusion in the set manages
        -- without -- and it is what the row is: the thing you tap with, the wire it
        -- leaves, and the tear the wire is sitting on. Reading it top to bottom is
        -- reading the gesture in order, which is the only icon here that can be
        -- read that way because it is the only one whose two halves happen one
        -- after the other rather than at once.
        --
        -- The staples are in phase with the dashes on purpose: a staple straddles
        -- the slit in the page, so a crown over a gap in the tear is a staple over
        -- a piece of paper that is not there, which is the one thing this drawing
        -- must not say.
        hinge = pixelart.newSprite({
            "..o.....o..",
            "...o...o...",
            "....o.o....",
            ".....o.....",
            "....o.o....",
            "...o...o...",
            "...........",
            "ooo.ooo.ooo",
            "o.o.o.o.o.o",
            "...........",
            "ggg.ggg.ggg",
        }),

        -- And the scissors against the four brushes, three of them written. All
        -- three are the *other* parent's object over the dashed tear, which is how
        -- every scissors fusion in the set says which half is the scissors: the
        -- TEAR LINE draws two pins over it, the GUILLOTINE a straight edge, the
        -- HINGE a seam of wire. The blades themselves are only ever drawn on the row
        -- where the taps are still the gesture, so on these three the tear is the
        -- whole of the scissors and the top half is what you are actually holding.
        --
        -- The gluestick's own body, unchanged from the PULP and the MORDANT, over a
        -- smear with the page opening under it. The smear is drawn as its rim and
        -- its middle for the band's reason -- paste is the one mark in the game the
        -- crowd stands *in* rather than on, so a solid bar would be saying the wrong
        -- thing about it.
        collage = pixelart.newSprite({
            "...ooooo...",
            "..owwwwwo..",
            ".ooooooooo.",
            ".occccccco.",
            ".occccccco.",
            ".ooooooooo.",
            "...........",
            ".ggggggggg.",
            ".gwwwwwwwg.",
            ".ggggggggg.",
            "ggg.ggg.ggg",
        }),
        -- The marker's own body, unchanged from the SCUFF, over a band alight: the
        -- BLEED's red inside a sky rim, which is what every burning mark in this set
        -- is drawn as. The tear is under the fire rather than through it, because
        -- what the blades leave is a body that walks away burning -- the flame is on
        -- the crowd and the tear is in the page, and they are two different things
        -- happening at the same moment.
        scorch = pixelart.newSprite({
            ".ooooo.....",
            ".obbbo.....",
            "ooooooo....",
            "obbbbbo....",
            "ooooooo....",
            ".okkko.....",
            "...........",
            ".ccccccccc.",
            ".crrrrrrrc.",
            "...........",
            "ggg.ggg.ggg",
        }),
        -- The rubber's own five-pixel silhouette, unchanged from the SNAG -- blush
        -- over graphite in a slate rim -- and then **no band at all**, which is the
        -- SNAG's rule for the SNAG's reason: the one thing a rub leaves on the page
        -- is crumbs, and drawing a mark under this one would promise a mark it does
        -- not make.
        --
        -- So what is under it is the tear with crumbs thrown off *both* sides of it,
        -- which is the PARTING's pattern and here it is the mechanic rather than a
        -- borrowing: the cut decides where the line is and the rub drives the crowd
        -- across it, one way or the other.
        shear = pixelart.newSprite({
            ".sssss.....",
            ".skkks.....",
            ".sssss.....",
            ".sgggs.....",
            ".sssss.....",
            "...........",
            "..g.....g..",
            "...g...g...",
            "ggg.ggg.ggg",
            "...g...g...",
            "..g.....g..",
        }),
        -- And the last pair the strip can make, which is the one icon in the set
        -- with **no tear in it at all** -- and that is the row rather than an
        -- omission: a deadline takes the paper away from nobody. The page under the
        -- line is whole, so drawing the dashes every other scissors fusion carries
        -- would be the drawing lying about the only thing that makes this row
        -- different.
        --
        -- The pen's own nib, in the DECKLE's six-row silhouette and the pen's own
        -- colours -- which is a quotation worth having, the same shape being the same
        -- hand holding a different tool. Then the crowd closing on the line at two
        -- distances, which is the CLINCH's way of saying "and it goes on happening",
        -- and the line itself edge to edge in pen blue.
        --
        -- **And one body in the corner**, which is the whole mechanic in a single
        -- pixel: nothing gets past the line, and what touched it turns up over
        -- there. It is the only icon in the game that draws where something *went*.
        deadline = pixelart.newSprite({
            "........obo",
            ".......obo.",
            "......obo..",
            ".....obo...",
            "....obo....",
            "...oo......",
            "...s...s...",
            "bbbbbbbbbbb",
            "...........",
            "s..........",
            "...........",
        }),

        -- From here down they are not tools. An upgrade names an icon out of
        -- this same table (src/upgrades.lua) and the draft card draws it in the
        -- same 11x11 box the selector uses, so a thing you are offered looks
        -- like a thing you already have. The ruler's upgrade has no icon of its
        -- own for that reason -- it names the tool's.
        --
        -- The SHOT line, and it is a bullseye rather than a pellet on purpose:
        -- what that line sells is not the thing that leaves you but the fact that
        -- it goes at whatever is nearest without being asked. A target says the
        -- aim; a pellet would only have said "blue dot", and the pellet you
        -- actually fire is whatever you left on the board (src/design.lua)
        -- anyway. Red rings inside an ink one, which is the one place red is not
        -- the horde -- an icon is drawn past the overprint pass, over the page
        -- rather than on it, and red there means the thing this does.
        bullseye = pixelart.newSprite({
            "...ooooo...",
            "..o.....o..",
            ".o.......o.",
            "o...rrr...o",
            "o..r...r..o",
            "o..r.r.r..o",
            "o..r...r..o",
            "o...rrr...o",
            ".o.......o.",
            "..o.....o..",
            "...ooooo...",
        }),
        -- Point up, guard across, grip under: the drawing on the board is three
        -- pixels wide and would be a line at this size, so the icon is the
        -- silhouette everyone already knows instead. Sky through the blade with
        -- an ink edge, which is how anything metal is drawn here, and the grip in
        -- slate so the guard reads as the guard rather than as the middle of a
        -- long blade.
        sword = pixelart.newSprite({
            "...........",
            ".....o.....",
            "....oco....",
            "....oco....",
            "....oco....",
            "....oco....",
            "..ooooooo..",
            "....oso....",
            "....oso....",
            "....ooo....",
            "...........",
        }),
        star = pixelart.newSprite({
            ".....o.....",
            "....ooo....",
            "....ooo....",
            "ooooooooooo",
            ".ooooooooo.",
            "..ooooooo..",
            "..ooooooo..",
            "..oo...oo..",
            ".oo.....oo.",
            ".o.......o.",
            "...........",
        }),
        -- Stood on its tail and lit, where the one on the page flies on its
        -- side: at eleven pixels the fins are what say rocket, and they only
        -- read as fins pointing down. The three red pixels under it are the
        -- burn -- the icon says what is on offer, and what is on offer is
        -- something that goes off on its own.
        rocket = pixelart.newSprite({
            ".....o.....",
            "....ooo....",
            "....oro....",
            "....oro....",
            "....oro....",
            "...ooroo...",
            "..o.oro.o..",
            "..o.oro.o..",
            "..ooooooo..",
            "....r.r....",
            ".....r.....",
        }),
        -- The cool S again, squeezed into eleven by eleven: the two points, the
        -- three verticals and the crossing, which is the least you can draw and
        -- still have everyone recognise it. The icon says what is on offer and
        -- the nine by seventeen you fly is yours.
        cools = pixelart.newSprite({
            ".....o.....",
            "...o...o...",
            ".o.......o.",
            ".o...o...o.",
            "..o...oo...",
            "....o...o..",
            ".o...o...o.",
            ".o...o...o.",
            "..o.....o..",
            "...o...o...",
            ".....o.....",
        }),
        -- The arrow that aims the beam, with the beam leaving its point. Both
        -- halves are needed: the arrow alone is a direction and the bar alone is
        -- a line, and what is on offer is a thing you point. The bar runs to the
        -- edge of the icon because that is what the beam does with the page.
        beam = pixelart.newSprite({
            "...........",
            "...........",
            ".o.........",
            ".oo........",
            ".ooo.rrrrrr",
            ".oooorrrrrr",
            ".ooo.rrrrrr",
            ".oo........",
            ".o.........",
            "...........",
            "...........",
        }),
        -- The disc with the rim it is drawn with on the page and four rays off
        -- the flat sides, four off the corners. The rays are what make it a sun
        -- rather than a ball, so they get the outermost ring of the icon to
        -- themselves and the body is kept small enough to leave it -- the same
        -- shape the thing takes in the corner of the page, seen whole rather
        -- than quartered.
        sun = pixelart.newSprite({
            ".....r.....",
            ".r.......r.",
            "....ooo....",
            "...okkko...",
            "..okkkkko..",
            "r.okkkkko.r",
            "..okkkkko..",
            "...okkko...",
            "....ooo....",
            ".r.......r.",
            ".....r.....",
        }),
        -- The bomb again, with the one thing the one on the page never has until
        -- it is too late: a lit fuse. The spark is the only colour in it, and it
        -- is red where the thing itself flashes blue, because an icon is not on
        -- the page -- it is the card saying a thing goes off on its own, which is
        -- exactly the pixel the rocket icon spends on its burn.
        bomb = pixelart.newSprite({
            "........r..",
            ".......o...",
            "......o....",
            "....ooo....",
            "...ooooo...",
            "..ooooooo..",
            ".ooooooooo.",
            ".ooooooooo.",
            "..ooooooo..",
            "...ooooo...",
            "...........",
        }),
        -- The skate, side on, with its trail laid under it. The board is the
        -- drawing (Sprites.SKATE) at the icon's own scale and the trail is the
        -- two sky rows below -- which is the one weapon icon that has to show
        -- two things, because a board on its own says "you go faster" and the
        -- whole of what the line sells is what it leaves behind.
        skate = pixelart.newSprite({
            "...........",
            "...........",
            "...........",
            "o.........o",
            ".ooooooooo.",
            "..bb...bb..",
            "...........",
            ".ccccccccc.",
            "...ccccc...",
            "...........",
            "...........",
        }),
        -- The cloud with the bolt already out of it, which is the one weapon
        -- icon that has to show the pair: a cloud on its own is weather and a
        -- bolt on its own is a scribble, and what the card is offering is the
        -- one arriving to deliver the other. The body is filled in paper like
        -- the cloud itself (Sprites.cloud), so the icon covers its box the way
        -- the thing covers the page.
        storm = pixelart.newSprite({
            "...........",
            "..oooo.....",
            ".owwwwoo...",
            "owwwwwwwo..",
            ".oooooooo..",
            "....oo.....",
            "...oo......",
            "..ooooo....",
            "....oo.....",
            "...oo......",
            "...........",
        }),
        -- Three of the doodle the flock is made of, at three places on the
        -- page, because one m on its own reads as a letter and three read as
        -- birds. What the line sells is that there are more of them every level.
        birds = pixelart.newSprite({
            "...........",
            ".oo.oo.....",
            "o..o..o....",
            "...........",
            ".....oo.oo.",
            "....o..o..o",
            "...........",
            "..oo.oo....",
            ".o..o..o...",
            "...........",
            "...........",
        }),
        -- Squared off rather than round, which is the one icon that is not a
        -- smaller version of the thing it stands for: eleven pixels of round
        -- spiral is a smudge with a hole in it, and what has to read here is the
        -- *winding* -- one unbroken line going all the way in.
        spiral = pixelart.newSprite({
            "ooooooooooo",
            "o.........o",
            "ooooooooo.o",
            "o.......o.o",
            "o.ooooo.o.o",
            "o.o...o.o.o",
            "o.o.ooo.o.o",
            "o.o.....o.o",
            "o.ooooooo.o",
            "o.........o",
            "ooooooooooo",
        }),
        -- A horseshoe magnet, poles down and painted the two colours every
        -- magnet in every cartoon is painted.
        magnet = pixelart.newSprite({
            "...ooooo...",
            "..o.....o..",
            ".o..ooo..o.",
            ".o.o...o.o.",
            ".o.o...o.o.",
            ".o.o...o.o.",
            ".o.o...o.o.",
            ".o.o...o.o.",
            ".ooo...ooo.",
            ".rrr...ccc.",
            "...........",
        }),
        -- Blades crossed above the handles: the X is the whole silhouette at
        -- this size, and the two loops underneath are what stop it reading as a
        -- letter.
        scissors = pixelart.newSprite({
            "..o.....o..",
            "..o.....o..",
            "...o...o...",
            "...o...o...",
            "....o.o....",
            ".....o.....",
            "....o.o....",
            "..ss...ss..",
            ".s..s.s..s.",
            ".s..s.s..s.",
            "..ss...ss..",
        }),
        -- A stick of bare lead, no wood on it: the pencil icon's diagonal with
        -- the red body taken away and a little dust shaken off the point.
        graphite = pixelart.newSprite({
            "........oo.",
            ".......oso.",
            "......oso..",
            ".....oso...",
            "....oso....",
            "...oso.....",
            "..oso......",
            ".oso.......",
            "oso........",
            "oo.........",
            "..g.g......",
        }),
        -- The blade band across the middle is the only part of a sharpener that
        -- is recognisably a sharpener rather than a red block.
        sharpener = pixelart.newSprite({
            "...........",
            ".ooooooooo.",
            ".orrrrrrro.",
            ".orrrrrrro.",
            ".ossssssso.",
            ".osoooooso.",
            ".ossssssso.",
            ".orrrrrrro.",
            ".orrrrrrro.",
            ".ooooooooo.",
            "...........",
        }),
        -- A paper dart, thrown to the right. Paper for the near wing and ink
        -- for the folds, which is the only way to say "folded" in eleven
        -- pixels.
        plane = pixelart.newSprite({
            "...........",
            "..........o",
            ".......oooo",
            "....ooowwwo",
            "..oooowwwo.",
            "oooowwwwoo.",
            "..oooowwo..",
            ".....oooo..",
            ".......oo..",
            "........o..",
            "...........",
        }),
        -- A page off the same pad the game is played on, ruling and all.
        page = pixelart.newSprite({
            "..ooooooo..",
            "..owwwwwo..",
            "..occccco..",
            "..owwwwwo..",
            "..occccco..",
            "..owwwwwo..",
            "..occccco..",
            "..owwwwwo..",
            "..ooooooo..",
            "...........",
            "...........",
        }),
        -- A roll of tape seen face on, with a length of it hanging off the
        -- bottom right. The ring alone is a doughnut; the tail is the whole
        -- difference between a roll of something and a hole in something.
        tape = pixelart.newSprite({
            "...ooooo...",
            "..occccco..",
            ".occcwccco.",
            ".occwwwcco.",
            ".occcwccco.",
            "..occccco..",
            "...ooooo...",
            "......ooo..",
            "......occo.",
            ".......occo",
            ".......ooo.",
        }),
        -- A plaster laid across the corner of the page: blush for the strip and
        -- paper for the pad, which is the one place in the icons where the two
        -- ends of the same idea sit next to each other -- the sellotape mends the
        -- page and this one mends you.
        bandaid = pixelart.newSprite({
            ".....ooooo.",
            ".....okkko.",
            "....okkko..",
            "....okwko..",
            "...owwwo...",
            "...owwwo...",
            "..owwwo....",
            "..okkko....",
            ".okkko.....",
            ".okkko.....",
            "ooooo......",
        }),
        -- A pot of ink, half full, with the neck open at the top -- the one
        -- angle at which a well reads as a thing you dip into rather than a jar.
        -- Paper above the line and blue below it is what says half full; a pot
        -- filled to the brim would just be a blue box.
        inkwell = pixelart.newSprite({
            "...........",
            "....ooo....",
            "....o.o....",
            "..ooooooo..",
            "..owwwwwo..",
            ".oowwwwwoo.",
            ".obbbbbbbo.",
            ".obbbbbbbo.",
            ".obbbbbbbo.",
            ".ooooooooo.",
            "...........",
        }),
        -- Lying on its side with the neck to the left, which is how one comes
        -- out of the box and the only way the shoulder reads as a shoulder.
        cartridge = pixelart.newSprite({
            "...........",
            "...........",
            "....ooooooo",
            "....obbbbbo",
            ".oooobbbbbo",
            ".obbbbbbbbo",
            ".oooobbbbbo",
            "....obbbbbo",
            "....ooooooo",
            "...........",
            "...........",
        }),
        -- A sheet with a blot soaking into it, feathered from an ink core out
        -- through slate: the page icon's outline with the ruling taken away, so
        -- the two read as the same object doing different jobs.
        blotter = pixelart.newSprite({
            ".ooooooooo.",
            ".owwwwwwwo.",
            ".owwsswwwo.",
            ".owsooswwo.",
            ".owsooooso.",
            ".owwsooswo.",
            ".owwwsswwo.",
            ".owwwwwwwo.",
            ".ooooooooo.",
            "...........",
            "...........",
        }),
        -- An aerosol, upright, with the mist coming off the nozzle to the right.
        -- The three graphite specks are the whole idea of the upgrade -- a can
        -- on its own is a can, and a can that is spraying is a thing being made
        -- to stay put.
        fixative = pixelart.newSprite({
            "..ooo......",
            "..o.o...g..",
            ".ooooo..g.g",
            ".ossso...g.",
            ".ossso.....",
            ".ooooo.....",
            ".ossso.....",
            ".ossso.....",
            ".ossso.....",
            ".ooooo.....",
            "...........",
        }),
        -- A sheet sealed in plastic, and the shine is the whole of what says so --
        -- the sheet under it is a sheet, and the page icon a few rows down is
        -- already a bordered rectangle with lines across it. So this one has no
        -- ruling at all and a sky streak straight across the face instead, which
        -- is the one thing a laminated card does that paper cannot: catch the
        -- light. The sleeve is slate rather than ink for the same separation --
        -- plastic is not a drawn line.
        laminate = pixelart.newSprite({
            "...........",
            ".sssssssss.",
            ".swwwwwccs.",
            ".swwwwccws.",
            ".swwwccwws.",
            ".swwccwwws.",
            ".swccwwwws.",
            ".sccwwwwws.",
            ".scwwwwwws.",
            ".sssssssss.",
            "...........",
        }),
        -- The music lesson's own object, and the only clock in the table. A
        -- metronome at rest is a wooden wedge and nothing else, so what says this
        -- one is *going* is the rod thrown over to one side. The case is an
        -- outline for the fixative's can's reason: filled, an eleven-pixel wedge
        -- is a solid triangle.
        --
        -- The weight is the two red pixels the rod runs through, and red because
        -- it is the part that says which beat you are on -- it is the tick, and a
        -- tick is red everywhere in this game.
        metronome = pixelart.newSprite({
            "........o..",
            ".......o...",
            ".....ror...",
            ".....o.....",
            "....o......",
            "...ooo.....",
            "..o...o....",
            ".o.....o...",
            ".o.....o...",
            ".ooooooo...",
            "...........",
        }),
        -- A teacher's tick, in the red every teacher's pen is. Nothing else in
        -- the icon table is a mark made *on* work rather than a thing you pick
        -- up, which is exactly what the line does: it is the only upgrade about
        -- what the run is worth rather than what it can do.
        tick = pixelart.newSprite({
            ".........rr",
            "........rr.",
            ".......rr..",
            "......rr...",
            ".....rr....",
            "r....rr....",
            "rr..rr.....",
            ".rr.rr.....",
            "..rrrr.....",
            "...rr......",
            "...........",
        }),

        -- HUD glyphs rather than tools, and drawn in a smaller box, so they are
        -- 5x5, 4x7 and 7x5 instead of the tools' 11x11.
        pause = pixelart.newSprite({
            "oo.oo",
            "oo.oo",
            "oo.oo",
            "oo.oo",
            "oo.oo",
        }),
        play = pixelart.newSprite({
            "o...",
            "oo..",
            "ooo.",
            "oooo",
            "ooo.",
            "oo..",
            "o...",
        }),
        -- The way out of a screen you did not come to a decision on: the
        -- timetable's corner button back to the title. It points the opposite way
        -- to the play triangle it shares that corner box with, so the one that
        -- goes on and the one that goes back read as a pair -- but it is drawn
        -- open rather than solid, one pixel of head per row. Filling the head in
        -- puts a block on the end of a line the same weight as the line, and at
        -- five rows across the whole icon that reads as a wedge rather than as
        -- something pointing.
        back = pixelart.newSprite({
            "..o....",
            ".oo....",
            "ooooooo",
            ".oo....",
            "..o....",
        }),
        -- The arrows either side of the studio's character selector
        -- (src/studio.lua). One glyph rather than two: it is three wide, so its
        -- origin is the middle column and drawing it flipped is an exact mirror
        -- rather than a resample -- the pair are the same drawing looked at from
        -- both sides, which is what a `<  >` is.
        --
        -- Open like the back arrow and for the same reason, with no shaft at all:
        -- at three columns a shaft would be most of the glyph, and what is wanted
        -- here is the head on its own.
        chevron = pixelart.newSprite({
            "..o",
            ".o.",
            "o..",
            ".o.",
            "..o",
        }),
        -- The settings button on the title screen (src/settings.lua). Two bars
        -- with a handle apiece, which is not a metaphor for the page behind it --
        -- it *is* the page behind it, since what settings holds is two bars you
        -- drag. A cog was drawn first and thrown away: at seven pixels a cog is
        -- teeth one pixel long round a ring one pixel thick, and what came out
        -- read as a snowflake.
        --
        -- The two handles sit at different places along their rails on purpose.
        -- Level with each other the glyph reads as a plus sign with a bar
        -- through it; offset, it reads as two things set to two amounts, which
        -- is the whole idea.
        sliders = pixelart.newSprite({
            ".oo....",
            "ooooooo",
            ".oo....",
            ".......",
            "....oo.",
            "ooooooo",
            "....oo.",
        }),
        -- What a run pays out (src/purse.lua), on the two cards a run ends on and
        -- on the canteen's own page. Nine across rather than the tools' eleven,
        -- because it is never picked up off a shelf -- it stands beside a number
        -- the way a currency symbol does, and in all three places it appears the
        -- number is the thing being read.
        --
        -- The palette has no metal in it and nothing at this size would say gold
        -- anyway, so what says coin is the rim, the fill and the figure struck
        -- inside it -- a 1, because one of these is one coin.
        --
        -- **Filled blush, with the figure in paper.** Blush is the light end of
        -- the red half of the palette, which everywhere else in the game means the
        -- other side of the fight -- but this is not a thing in the fight, it is a
        -- thing written on the page in the same red pen the lesson headings and
        -- the run's grade are written in, and that pen is the one a teacher hands
        -- things back in. The figure is paper because paper is the one colour that
        -- *covers*: the 1 stays white against the fill and wipes whatever is under
        -- it, while the fill stacks with the page like any other mark. So on a
        -- paper card the coin is flat pink, and on a ruled page a rule crossing it
        -- darkens the fill and leaves the 1 alone -- which is what a pink mark on
        -- ruled paper does, and is why the figure is the half of this drawn in the
        -- colour that erases.
        --
        -- **Nine and not seven, and the two pixels are the whole of why.** A 7x7
        -- rim leaves five columns of face with the corners cut off it, which is
        -- not enough for a numeral: drawn at one pixel the figure is a smudge, and
        -- drawn at two it fills the face and the coin comes out as a dark blob at
        -- every size. Nine leaves a 3x5 cell with a pixel of fill all round it,
        -- which is exactly the 3x5 face's own cell -- so the figure on the coin is
        -- the same size as the figure beside it, and the pair reads as a price.
        coin = pixelart.newSprite({
            "..ooooo..",
            ".okkkkko.",
            "okkkwkkko",
            "okkwwkkko",
            "okkkwkkko",
            "okkkwkkko",
            "okkwwwkko",
            ".okkkkko.",
            "..ooooo..",
        }),

        -- The three things the canteen sells and the draft spends
        -- (src/perks.lua): another deal, a level traded for coins, and a line
        -- thrown out of the run. 11x11 like the tools rather than 7x7 like the
        -- pause bars and the back arrow, because of the box they are pressed in:
        -- they sit in the tool selector's box (13 across) and not in the corner
        -- button's (11), so they are drawings on things you press with a picture
        -- on them rather than the corner's smaller glyphs. Which is also what
        -- lets the same drawing do for the canteen's counter, where it stands
        -- beside a name at the size a library shelf's icon does.
        --
        -- A die, five up. Two loop arrows were drawn before it and both were
        -- thrown away, and the reason is worth writing down because it will come
        -- up again: an arrow that comes back on itself is a *line*, and at seven
        -- pixels of one-pixel line an arc with two legs under it closes into a
        -- rectangle, with the arrowhead reading as a cross stuck on the corner of
        -- it. The head cannot be fixed either -- drawn on the outer column the
        -- barbs share an edge with the leg and come out as a hook, and drawn a
        -- column in the shaft runs through the barbs and comes out as a plus.
        --
        -- So it is mass instead of line, which is why the fast-forward beside it
        -- works: a rim, a white face and five pips is a shape rather than a stroke,
        -- and it reads at a glance on a page already made of thin lines. It is also
        -- honest about what the button does -- the draft *is* a roll
        -- (`Loadout:roll`), and pressing this asks for another one.
        --
        -- The face is paper, the one colour that covers, so the pips are read
        -- against white wherever this is drawn: on a ruled page it wipes the
        -- ruling, and inside the draft's paper-filled button it disappears into it
        -- and leaves the rim and the pips.
        --
        -- Four and not five, and the reason survived the resize: a five puts a pip
        -- in the middle, and at eleven pixels that is a fifth 2x2 block with the
        -- other four leaning on its corners -- which reads as an X rather than as a
        -- face. With the middle empty every pip has three clear pixels of white
        -- around it on all four sides.
        reroll = pixelart.newSprite({
            "ooooooooooo",
            "owwwwwwwwwo",
            "owoowwwoowo",
            "owoowwwoowo",
            "owwwwwwwwwo",
            "owwwwwwwwwo",
            "owwwwwwwwwo",
            "owoowwwoowo",
            "owoowwwoowo",
            "owwwwwwwwwo",
            "ooooooooooo",
        }),
        -- Two solid heads pointing the way out, which is the play triangle
        -- doubled -- the one glyph in the world that means *past this*. Solid
        -- rather than open like the back arrow, because there are two of them: an
        -- open pair at this size is four thin strokes and reads as a zigzag.
        skip = pixelart.newSprite({
            "...........",
            "o.....o....",
            "oo....oo...",
            "ooo...ooo..",
            "oooo..oooo.",
            "ooooo.ooooo",
            "oooo..oooo.",
            "ooo...ooo..",
            "oo....oo...",
            "o.....o....",
            "...........",
        }),
        -- The teacher's tick the other way round, and in the same red pen: a
        -- cross is what a marked page says about the answer it is next to, which
        -- is exactly what this button says about a card. Ten rows in an eleven-row
        -- box, exactly as the tick is: two-pixel arms on an odd grid cannot both
        -- meet in the middle and reach both ends, so the last row is given up
        -- rather than the crossing. It is the second mark in
        -- the icon table made *on* work rather than picked up off a desk, and the
        -- pair is deliberate -- the tick is the line about what the run is worth
        -- and this is the button that puts a line out of it.
        expel = pixelart.newSprite({
            "rr.......rr",
            ".rr.....rr.",
            "..rr...rr..",
            "...rr.rr...",
            "....rrr....",
            "....rrr....",
            "...rr.rr...",
            "..rr...rr..",
            ".rr.....rr.",
            "rr.......rr",
            "...........",
        }),
        -- A heart with a white 2 struck inside it, which is the coin's own device
        -- (a light face, an ink-coloured rim and a figure cut out of paper) put to
        -- the one other job in this game that is a *count* of something you have.
        -- Red rim and a blush face because that is what health is drawn in
        -- everywhere else -- the pickup that refills it is the same two colours --
        -- and this is the only icon in the table wearing them, which is fair: it
        -- is the only one that hands health back.
        --
        -- The 2 is the second life rather than the second level, and it is what the
        -- icon needed to stop being a heart. A plain heart is what a *pickup* is,
        -- and the counter would then have been selling the thing lying on the page
        -- three rooms away; a figure inside it says once more rather than more.
        --
        -- The notch is one pixel wide and the lobes meet on the row under it. At
        -- eleven across there is no room for a wider one: two pixels of notch and
        -- the two lobes read as a pair of circles with a gap, which is a cloud.
        retake = pixelart.newSprite({
            ".rrrr.rrrr.",
            "rkkkkrkkkkr",
            "rkkkkkkkkkr",
            "rkkkwwwkkkr",
            "rkkkkkwkkkr",
            "rkkkwwwkkkr",
            ".rkkwkkkkr.",
            "..rkwwwkr..",
            "...rkkkr...",
            "....rkr....",
            ".....r.....",
        }),
        -- The course ladder's row on the counter (src/course.lua): a mortarboard,
        -- which is the one object in a school building that means "a harder class
        -- than the last one" and is legible at eleven pixels because it is a
        -- diamond on a box. The tassel is the only red on it, for the reason red
        -- is the only colour a mark is ever in -- it is the part of a cap that
        -- says which year you are.
        cap = pixelart.newSprite({
            ".....o.....",
            "...ooooo...",
            ".ooooooooo.",
            "ooooooooooo",
            ".ooooooooor",
            "..o.....o.r",
            "..o.....o.r",
            "..ooooooo.r",
            ".........rr",
            "...........",
            "...........",
        }),
    }

    Sprites.gem = pixelart.newSprite({
        "..b..",
        ".bcb.",
        "bcccb",
        ".bcb.",
        "..b..",
    })

    -- The things scattered past the screen edge for you to walk to
    -- (src/pickup.lua). Each is drawn in the colour of what it refills -- red
    -- for health, blue for ink -- and the diamond is cut from paper: like the
    -- eye and the ruler body it wipes the ruling rather than stacking on it,
    -- which is what makes the rarest thing on the page read as an object lying
    -- on it rather than another ink doodle.
    Sprites.pickups = {
        heart = pixelart.newSprite({
            ".rrr.rrr.",
            "rkkkrkkkr",
            "rkkkkkkkr",
            "rkkkkkkkr",
            ".rkkkkkr.",
            "..rkkkr..",
            "...rkr...",
            "....r....",
        }),
        ink = pixelart.newSprite({
            "...b...",
            "...b...",
            "..bcb..",
            "..bcb..",
            ".bcccb.",
            ".bcwcb.",
            "bcccccb",
            "bcccccb",
            ".bbbbb.",
        }),
        diamond = pixelart.newSprite({
            "...sssssss...",
            "..swwcwwwws..",
            ".swwwwwwwwws.",
            "swwwwwwwwwwws",
            ".swwwwwwwwws.",
            "..swwwwwwws..",
            "...swwwwws...",
            "....swwws....",
            ".....sws.....",
            "......s......",
        }),
    }
end

return Sprites
