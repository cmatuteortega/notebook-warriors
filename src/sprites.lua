-- All game art, authored as ASCII pixel maps.
--   .=transparent  w=paper  g=graphite  s=slate  o=ink  r=red  k=blush  b=blue  c=sky
-- Everything is drawn at 1:1 into the 320x180 low-res canvas, so one character
-- here is exactly one game pixel (and 4 screen pixels at the default window size).

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

-- The rocket that launches itself at things (src/rocket.lua). Drawn nose-right,
-- which is the first of the eight headings it is kept at: `Sprites.setDrawn`
-- turns this into a ring through `pixelart.turn` and a rocket flies the nearest
-- one. Nothing is turned at draw time -- the ring is ordinary sprites at
-- ordinary integer positions -- but the four diagonals of it are resampled, so
-- solid shapes come through and single-pixel lines do not.
--
-- Seven tall rather than five, which is the whole difference between a rocket
-- and a dart: an outline top and bottom leaves one row of body at five, and one
-- row of body is a needle whatever is drawn round it. Being solid is also what
-- gets it through those four diagonals in one piece. The one red pixel off the
-- back is the nozzle -- the trail behind it is particles (Rocket's exhaust), and
-- the two together are what say the thing is under power rather than thrown.
-- Only the taper has to survive a reskin: an arrow, a dart or a sharpened pencil
-- is the same eleven by seven with the point still on the right.
Sprites.ROCKET = {
    ".oo........",
    ".oooooooo..",
    ".orrrrrroo.",
    "rorrrrrrroo",
    ".orrrrrroo.",
    ".oooooooo..",
    ".oo........",
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
    ".ooooo.o.ooooo.",
    ".ooooo.o.ooooo.",
    "..ooo.....ooo..",
    "...............",
    "..o.........o..",
    "...o.......o...",
    "....ooooooo....",
}

-- The eight headings of every drawn sprite that has them, by the key it is
-- filed under here. Only the rocket does; a hero, a star and a face are drawn
-- one way up and stay that way. The laser beam points where it is going too and
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

function Sprites.load()
    -- One of each drawn sprite is always standing by, even if nothing has been
    -- drawn yet and nothing was saved from last time.
    Sprites.setDrawn("player", Sprites.STICKMAN)
    Sprites.setDrawn("star", Sprites.STAR)
    Sprites.setDrawn("rocket", Sprites.ROCKET, true)
    Sprites.setDrawn("sunface", Sprites.SUNFACE)
    Sprites.setDrawn("cools", Sprites.COOLS)

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
        -- Bat: fast, fragile, arrives later.
        bat = pixelart.newSprite({
            "s.........s",
            "ss.......ss",
            "scs.sss.scs",
            "scccccccccs",
            ".sccococcs.",
            "..sscccss..",
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
    }

    Sprites.bullet = pixelart.newSprite({
        ".r.",
        "rkr",
        ".r.",
    })

    -- The eye's spit. Bigger than the player's bullet and red only at the
    -- core: red says danger, but the heavy ink rim is what keeps a pellet
    -- flying *at* you from reading as one of yours flying away -- the
    -- player's shot is red to its edge, this one is dark to its edge.
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

    -- The one thing in the game that is an object rather than a mark: a pushpin
    -- driven into the paper. Its origin is the tip rather than the middle, so a
    -- pin's position is the point it goes into the page at -- which is what it
    -- is dropped on, and what its blast is measured from.
    Sprites.pin = pixelart.newSprite({
        "..ooo..",
        ".orkro.",
        "orkkkro",
        "orrkrro",
        ".orrro.",
        "..ooo..",
        "...o...",
        "...o...",
    }, { oy = 7 })

    -- Brush tips. Only their silhouettes are used (drawMask), so the colours
    -- here are irrelevant -- each tool tints its own tip as it fades.
    Sprites.tips = {
        -- Ballpoint nib: a round 3px dot, laid one per pixel.
        pen = pixelart.newDisc(1),
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
        -- Wax crayon: a broad soft band with a darker edge where the wax piles
        -- up against the paper. Kept while the crayon sits in Tools.shelved,
        -- since two discs are a rounding error and the tool is one line from
        -- being back on the strip.
        crayon = pixelart.newDisc(6),
        crayonEdge = pixelart.newDisc(7),
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
        -- Head-on, where the pin on the page is seen at the same angle
        -- everything else standing on it is: the icon is the thing itself, one
        -- size up, rather than a second drawing of it.
        pushpin = pixelart.newSprite({
            "....ooo....",
            "...orkro...",
            "..orkkkro..",
            "..orrkrro..",
            "..orrrrro..",
            "...orrro...",
            "....ooo....",
            ".....o.....",
            ".....o.....",
            ".....s.....",
            "...........",
        }),

        -- From here down they are not tools. An upgrade names an icon out of
        -- this same table (src/upgrades.lua) and the draft card draws it in the
        -- same 11x11 box the selector uses, so a thing you are offered looks
        -- like a thing you already have. The ruler's upgrade has no icon of its
        -- own for that reason -- it names the tool's.
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
        -- A band drawn back rather than a band lying flat: pinched to a point on
        -- the left, bulging to a loop on the right, with two red pixels off the
        -- pinch for the direction it is about to go. A relaxed elastic band is a
        -- ring, and there is already a ring in this table -- the roll of tape --
        -- so what makes this one legible is the tension rather than the shape.
        elastic = pixelart.newSprite({
            "...........",
            ".......ooo.",
            "......o...o",
            ".....o....o",
            "....o.....o",
            "rr.o......o",
            "....o.....o",
            ".....o....o",
            "......o...o",
            ".......ooo.",
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
        -- 7x5 and 4x7 instead of the tools' 11x11.
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
