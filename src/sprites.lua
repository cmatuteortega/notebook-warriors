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

-- The eight headings of every drawn sprite that has them, by the key it is
-- filed under here. Only the rocket does; a hero and a star are drawn one way
-- up and stay that way.
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

function Sprites.load()
    -- One of each drawn sprite is always standing by, even if nothing has been
    -- drawn yet and nothing was saved from last time.
    Sprites.setDrawn("player", Sprites.STICKMAN)
    Sprites.setDrawn("star", Sprites.STAR)
    Sprites.setDrawn("rocket", Sprites.ROCKET, true)

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
        -- The gluestick's smear: a broad round head, and the same head a pixel
        -- fatter drawn underneath so a rim of it survives all the way round.
        glue = pixelart.newDisc(14),
        glueEdge = pixelart.newDisc(15),
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
end

return Sprites
