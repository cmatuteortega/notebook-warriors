-- All game art, authored as ASCII pixel maps.
--   .=transparent  w=paper  g=graphite  s=slate  o=ink  r=red  k=blush  b=blue  c=sky
-- Everything is drawn at 1:1 into the 320x180 low-res canvas, so one character
-- here is exactly one game pixel (and 4 screen pixels at the default window size).

local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Sprites = {}

-- The player is the one thing in here that is not authored art: it is whatever
-- was drawn in the studio (src/studio.lua). This is only where a fresh one
-- starts from -- the stick man you are handed to draw over -- while the design
-- actually on the page belongs to src/hero.lua.
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

-- Rebuilds the player from a design. Called on every pixel the studio changes,
-- so the old pair is released rather than left for the collector -- the images
-- are small, but a long session of drawing is a lot of them.
function Sprites.setPlayer(rows)
    local old = Sprites.player
    Sprites.player = pixelart.newSprite(rows)
    if old then
        old.img:release()
        old.mask:release()
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
    -- A hero is always standing by, even if nothing has been drawn yet and
    -- nothing was saved from last time.
    Sprites.setPlayer(Sprites.STICKMAN)

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
        -- Round eraser head, and the same head a pixel fatter for the smudge of
        -- graphite dust it drags along outside the clean core.
        rubber = pixelart.newDisc(7),
        rubberEdge = pixelart.newDisc(8),
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
        -- The gluestick lays down the same kind of smear as the eraser, just a
        -- lot wider: twice the radius, so four times the mess.
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
