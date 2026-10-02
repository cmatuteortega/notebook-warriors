-- The things the player draws rather than the game draws for them.
--
-- The hero is one, the star that orbits him is another and the rocket that
-- leaves him is a third, and they are the same thing at three sizes: a grid of
-- palette keys exactly as big as the sprite it becomes, so what is drawn on the
-- studio's board (src/studio.lua) is the sprite pixel for pixel -- nothing is
-- resampled, scaled or interpreted in between. Every change is pushed straight
-- into Sprites, which is what the rest of the game draws, so there is only ever
-- one of each: the hero the run walks, the title screen's doodle and the board's
-- life-size copy are one sprite, and so are the star on its orbit and the star
-- on the board it was drawn on.
--
-- A design is fixed at the size of the art it starts from, and that is the point
-- rather than a limitation: everything measured off a sprite -- the player's
-- radius, the star's reach -- would otherwise be at the mercy of what somebody
-- drew. You can change what a star looks like; you cannot draw a bigger one.
--
-- Each is written to its own file in the save directory and read back on the
-- next launch, so what you drew is still yours a week later. A file that has
-- been edited into something the game can't draw is ignored rather than trusted,
-- and you get back the one you were handed to draw over.

local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Characters = require("src.characters")

local Design = {}
Design.__index = Design

-- What a cell can hold. A design is a grid of palette keys and the file format
-- takes any of the eight, but only these three are on the board: three buttons
-- is a pencil case and eight is a paint set, and what a board is asking for is a
-- shape rather than a colour scheme.
--
-- Blue is the third because blue already means something in this game -- it is
-- the half of the palette that is yours, from the pen you draw walls with to the
-- bullets and the bomb's flash -- so a blue pixel on a
-- drawing reads as part of the thing rather than as a colour somebody picked.
-- Red is deliberately not offered: red is the horde's, and a hero drawn in it
-- would be the one mark on the page that lies about whose side it is on.
Design.BLANK = "."   -- bare paper: what the rubber puts back
Design.PENCIL = "o"  -- ink: the darkest thing on the page
Design.PEN = "b"     -- blue: the player's own half of the palette

-- Whether the game *asks* for a drawing when it hands you something new, or
-- takes what is already on the file and gets on with it. On by default, because
-- the board is the game: the first thing a run gives you is a blank grid and the
-- offer to put yourself in the book.
--
-- It is off for the player who has already drawn their sword and does not want
-- to draw it again -- a draft that stops the run dead on the board is a draft
-- that costs a hundred and fifty levels' worth of interruptions -- and it lives
-- here for the reason the language lives on I18n and the volumes live on Sfx
-- (src/options.lua): this is the module that knows what a board is. What it
-- governs is only the boards the game *opens for you* -- the weapon a draft has
-- just sold and the arm a character carries. `CUSTOM` on the timetable is a
-- board you went and asked for, and nothing may take that away.
Design.ask = true

--   sprite  the field in Sprites this design keeps up to date
--   source  the art it starts from, and what RESET puts back
--   file    where it is kept, in the save directory
--   legacy  an older file to fall back to while `file` does not exist yet, so a
--           drawing does not disappear because the game changed where it keeps
--           it. A list is tried in order, newest first
--   title   what the board calls it, under "DRAW YOUR"
--   hint    what the board says while it waits to be finished
--   walks   for something that stands on the page: the board's life-size copy
--           then gets the ground under it and the run's own walk bounce, and
--           something that floats gets neither
--   rim     for something drawn with a pale blue rim round it in the run: the
--           preview wears one too, so what the board shows is what floats past.
--           The cool S and the storm's bolt have one -- see Sprites.rim for why
--           they earn it, which is the same reason twice: a few thin strokes
--           crossing a page made of thin strokes
--   roster  for the board that is the character themselves rather than something
--           a character carries: the arrows between the drawing and the boxes,
--           which step through src/characters.lua. Only the hero's board has them, and the character
--           picked there is what decides whether the board hands straight on to
--           another one (`design` in src/characters.lua)
--   turns   for something that points where it is going: the sprite is kept at
--           all eight headings rather than one (Sprites.turned). Only worth it
--           for something with a heading -- a hero and a star are drawn one way
--           up and stay that way -- and it is not free, since the four diagonal
--           headings are the one place in the game where a drawing is resampled
--           rather than used as drawn (see pixelart.turn)
local function newDesign(spec)
    spec.w = #spec.source[1]
    spec.h = #spec.source
    return setmetatable(spec, Design)
end

local function fromRows(rows)
    local g = {}
    for y = 1, #rows do
        g[y] = {}
        for x = 1, #rows[y] do
            g[y][x] = rows[y]:sub(x, x)
        end
    end
    return g
end

--- the design -----------------------------------------------------------------

function Design:rows()
    local rows = {}
    for y = 1, self.h do
        rows[y] = table.concat(self.grid[y])
    end
    return rows
end

function Design:get(x, y)
    return self.grid[y][x]
end

-- Returns true if the page actually changed, so a drag that crosses the same
-- cell forty times only rebuilds the sprite once.
function Design:set(x, y, ch)
    if self.grid[y][x] == ch then return false end
    self.grid[y][x] = ch
    self:apply()
    return true
end

-- Nothing drawn is nothing to play as. The board refuses to hand an empty grid
-- over rather than letting an invisible hero out onto the page.
function Design:isBlank()
    for y = 1, self.h do
        for x = 1, self.w do
            if self.grid[y][x] ~= Design.BLANK then return false end
        end
    end
    return true
end

function Design:reset()
    self.grid = fromRows(self.source)
    self:apply()
end

-- Whether this is the player's drawing or the one they were handed. Struck off
-- the source rather than off whether a file exists, and that is the whole of what
-- makes it worth asking: a board opened, looked at and scribbled OK! on writes a
-- file that is the default pixel for pixel, and a homework list that counted it
-- would be a list you could finish without drawing anything (src/challenges.lua).
--
-- One pixel is enough. What is being asked is whether you put yourself in the
-- book, and the smallest possible answer to that is still an answer -- the book
-- has no business grading a drawing.
function Design:isCustom()
    -- A board that has not been read off disk yet is the book's own drawing, not
    -- yours. It cannot happen in the game -- `Design.loadAll` runs before any
    -- screen does -- and answering rather than indexing a nil grid is what keeps
    -- this safe to ask from anywhere.
    if not self.grid then return false end

    for y = 1, self.h do
        for x = 1, self.w do
            if self.grid[y][x] ~= self.source[y]:sub(x, x) then return true end
        end
    end
    return false
end

function Design:apply()
    Sprites.setDrawn(self.sprite, self:rows(), self.turns)
end

--- the save file --------------------------------------------------------------

-- One line per row of the design, which makes the file the drawing: opening it
-- in a text editor shows the character.
local function parse(design, text)
    local rows = {}
    for line in text:gmatch("[^\r\n]+") do
        rows[#rows + 1] = line
    end
    if #rows ~= design.h then return nil end

    for _, row in ipairs(rows) do
        if #row ~= design.w then return nil end
        for i = 1, #row do
            local ch = row:sub(i, i)
            if ch ~= Design.BLANK and not Palette.key[ch] then return nil end
        end
    end

    return rows
end

function Design:save()
    return love.filesystem.write(self.file, table.concat(self:rows(), "\n"))
end

-- `legacy` is a file -- or a list of them, newest first -- this design used to be
-- kept in, read only when its own is not there yet. Two things have moved so far:
-- the hero was one drawing in `hero.txt` before he was one per character, and a
-- character that has been renamed leaves its board behind under the old key
-- (`was` in src/characters.lua). Somebody who drew a stick man last week should
-- get him back rather than be handed the default, whichever of those happened.
-- None of them is ever written, so the first `OK!` on the board quietly retires
-- the lot.
local function readLegacy(legacy)
    if type(legacy) == "string" then return love.filesystem.read(legacy) end

    for _, file in ipairs(legacy) do
        local text = love.filesystem.read(file)
        if text then return text end
    end
end

function Design:load()
    local rows
    local text = love.filesystem.read(self.file)
    if not text and self.legacy then text = readLegacy(self.legacy) end
    if text then rows = parse(self, text) end

    self.grid = fromRows(rows or self.source)
    self:apply()
end

--- what there is to draw -------------------------------------------------------

-- Everything here is drawn when the run first earns it, and an upgrade line names
-- one of these to say so (see `design` in src/upgrades.lua). The sword and the
-- shot are named twice over: by the weapon lines that hand them out like any
-- other, and by a *character* (`design` in src/characters.lua), whose board hands
-- straight on to one of them on the way into a run. Two routes to the same board
-- and the same file -- what a shootman draws before a run is exactly what a
-- swordsman who drafts SHOT is put in front of. The heroes themselves are not in
-- here at all -- see Design.heroes.
Design.by = {
    -- What SWORD swings (src/sword.lua). Opened by what a run has earned like
    -- every other board here, and also by *who you are*: picking the swordsman
    -- under the hero's board hands the screen straight on to this one, because a
    -- sword he swings is as much of him as his own outline is.
    --
    -- Three wide and eight long, and the one drawing in the game not drawn
    -- nose-right: a sword is held, so it is drawn point-up and read two eighths
    -- round the ring (see Sprites.SWORD and POINT_UP in src/sword.lua). `turns`
    -- all the same -- it points where it is being swung, and it pays the thin-art
    -- price on the four diagonals for it.
    sword = newDesign({
        sprite = "sword",
        source = Sprites.SWORD,
        file = "sword.txt",
        title = "SWORD",
        hint = "SCRIBBLE OK! TO KEEP IT",
        turns = true,
    }),
    -- What SHOT sends (src/bullet.lua), and the other half of the sword: both
    -- characters draw the thing they fight with, and the board they are drawn on
    -- opens straight after the hero's own. The smallest board in the
    -- game, and it is meant to be: what is being asked for is a pellet, and the
    -- grid is bigger than the one you are handed so there is room to make a
    -- heavier one (see Sprites.SHOT, which also says why it wants to stay blue).
    --
    -- No `turns`: a shot goes at whatever angle the nearest thing is at, and a
    -- drawing with a front would point the wrong way at nearly all of them.
    bullet = newDesign({
        sprite = "bullet",
        source = Sprites.SHOT,
        file = "shot.txt",
        title = "SHOT",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
    star = newDesign({
        sprite = "star",
        source = Sprites.STAR,
        file = "star.txt",
        title = "STAR",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
    -- Eleven by seven of pointy, drawn nose-right, which is heading one of the
    -- eight the ring is turned to. The default is a rocket and the shape is the
    -- loosest thing here -- a dart, an arrow or a sharpened pencil is the same
    -- board and the same pixels -- but thin art pays for that looseness on the
    -- four diagonal headings, which are the only resampled thing in the game.
    rocket = newDesign({
        sprite = "rocket",
        source = Sprites.ROCKET,
        file = "rocket.txt",
        title = "ROCKET",
        hint = "SCRIBBLE OK! TO KEEP IT",
        turns = true,
    }),
    -- The one board that is not the whole of what it draws: the sun's disc, rim
    -- and rays are sized by the upgrade line and drawn rather than authored, and
    -- what you are drawing here is the face laid over the middle of it. Which is
    -- why it is the only design with something behind it -- everything left
    -- blank comes out as sun.
    sun = newDesign({
        sprite = "sunface",
        source = Sprites.SUNFACE,
        file = "sun.txt",
        title = "SUN FACE",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
    -- The biggest board of the four, and the one people will change least: the
    -- cool S is already the drawing, and what the board is really offering is
    -- the argument about how it goes -- how far the middle line drops, which
    -- way the long diagonal leans, whether the points are sharp. Everybody
    -- draws it slightly wrong and everybody is sure they draw it right.
    cools = newDesign({
        sprite = "cools",
        source = Sprites.COOLS,
        file = "cools.txt",
        title = "COOL S",
        hint = "SCRIBBLE OK! TO KEEP IT",
        rim = true,
    }),
    -- What the run rides once it has drafted one (src/skate.lua), and the only
    -- drawing in the game that goes *under* another one: it is drawn at the
    -- hero's feet in place of his shadow, which is why the board it is drawn on
    -- is as wide as the hero's own (see Sprites.SKATE).
    --
    -- No `walks`, and it is the one board where that field is refused rather than
    -- simply not wanted. Everything else that has it stands on the page and gets
    -- the bounce a run walks with; a skate *is* the ground the hero is standing
    -- on, and the whole of what the weapon looks like is that he stops bouncing
    -- and starts sliding (Player:draw). A preview that bobbed would be advertising
    -- the one thing having one takes away.
    skate = newDesign({
        sprite = "skate",
        source = Sprites.SKATE,
        file = "skate.txt",
        title = "SKATE",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
    -- The one drawing that is shown in a colour it was not drawn in. A bomb sits
    -- on the page in whatever ink you left on the board and then flashes its own
    -- silhouette blue over the last stretch of its fuse (src/bomb.lua), so what
    -- the board is really asking for is a shape that reads filled in -- the
    -- blink is the drawing in one colour, and an outline blinks as a ring. Blue
    -- rather than red because the bomb is yours (see src/bomb.lua), which is also
    -- what makes the shape carry the warning rather than the colour: the page is
    -- already half full of blue marks you drew.
    --
    -- No `walks` and no `rim`: it is neither something that stands up nor
    -- something that floats past. It is put down, and it stays where it was put.
    bomb = newDesign({
        sprite = "bomb",
        source = Sprites.BOMB,
        file = "bomb.txt",
        title = "BOMB",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
    -- What the storm puts through the page (src/storm.lua), and the one board
    -- where the *height* of what is drawn on it is a measurement: the cloud
    -- hangs exactly a bolt above whatever it is about to hit, so a longer bolt
    -- is a cloud floating higher and nothing has to be kept in step by hand.
    -- What the strike takes is a circle round the tip either way -- you can
    -- change what a bolt looks like, you cannot draw one that reaches further.
    --
    -- `rim` for the cool S's reason, which is the reason it is only the second
    -- thing to have one: a bolt is a few thin strokes on a page made of thin
    -- strokes, and it is only on the page for a third of a second at a time. The
    -- preview wears the same pale blue rim so the board shows what strikes.
    lightning = newDesign({
        sprite = "lightning",
        source = Sprites.LIGHTNING,
        file = "lightning.txt",
        title = "LIGHTNING",
        hint = "SCRIBBLE OK! TO KEEP IT",
        rim = true,
    }),
    -- One bird out of the flock that wheels round you (src/flock.lua), and the
    -- board with the most copies of what is on it: whatever is drawn here is
    -- every bird in the swarm, up to fourteen of them at once, which is worth
    -- knowing before drawing something busy on it.
    --
    -- No `turns` and no `rim`. It flies round you at every angle there is, so a
    -- drawing with a front would point the wrong way at most of them -- and see
    -- Sprites.BIRD for why the one thing on the page that would most like an
    -- outline is not allowed one.
    bird = newDesign({
        sprite = "bird",
        source = Sprites.BIRD,
        file = "bird.txt",
        title = "M BIRD",
        hint = "SCRIBBLE OK! TO KEEP IT",
    }),
}

--- the heroes ------------------------------------------------------------------

-- One hero board per character, and they are separate drawings kept in separate
-- files: the shootman you drew and the swordsman you drew are two people, and
-- stepping the roster on the board (src/studio.lua) steps between them rather
-- than recolouring one. Each opens on its own drawing (`Sprites.HERO_<KEY>` in
-- src/sprites.lua) rather than a shared stick man now that all four have been
-- drawn -- a character with no drawing of its own yet falls back to
-- `Sprites.STICKMAN`, the same default every one of them used to open on.
--
-- They are built off `Characters.list` rather than written out, so a third
-- character brings its own board with it and nothing here has to be edited.
--
-- All of them write the same sprite (`Sprites.player`), which is the one thing to
-- be careful about: only the picked one may be *applied*, or whichever was
-- applied last would be the hero the game draws. `Design.applyHero` is the one
-- place that decides, and everything that changes who is picked calls it.
Design.heroes = {}

-- Named `HERO_<KEY>` in src/sprites.lua, upper-cased because that is how every
-- other authored default in that file is written.
local HERO_SOURCES = {
    shootman = Sprites.HERO_SHOOTMAN,
    swordsman = Sprites.HERO_SWORDSMAN,
    starman = Sprites.HERO_STARMAN,
    skateman = Sprites.HERO_SKATEMAN,
}

for _, char in ipairs(Characters.list) do
    -- The board this character used to be kept under first, if it has been
    -- renamed, and the one-hero-for-everybody file behind that: a rename must not
    -- be a drawing quietly turning back into the default.
    local legacy = { "hero.txt" }
    if char.was then table.insert(legacy, 1, "hero-" .. char.was .. ".txt") end

    Design.heroes[char.key] = newDesign({
        sprite = "player",
        source = HERO_SOURCES[char.key] or Sprites.STICKMAN,
        file = "hero-" .. char.key .. ".txt",
        legacy = legacy,
        title = "HERO",
        hint = "SCRIBBLE OK! TO KEEP HIM",
        walks = true,
        roster = true,
    })
end

-- The board of whoever is picked, which is what `CUSTOM` opens and what the
-- roster's arrows step.
function Design.hero()
    return Design.heroes[Characters.current.key]
end

function Design.applyHero()
    Design.hero():apply()
end

--- how much of the book is in your handwriting ---------------------------------

-- Every board there is, the things a run carries and the heroes who carry them,
-- as one list. Built on the way past rather than written out, for `Design.by`'s
-- own reason: a new drawing is a row in one of the two tables above and nothing
-- else, and a screen that counts boards must not be the second place that has to
-- be told about it.
--
-- The heroes are in it and they should be. A character you never play is still a
-- person in this book, and the whole of what the drawing challenge asks is that
-- nothing in it is somebody else's handwriting.
function Design.boards()
    local all = {}
    for _, design in pairs(Design.by) do all[#all + 1] = design end
    for _, design in pairs(Design.heroes) do all[#all + 1] = design end
    return all
end

-- And how many of them you have actually drawn on.
function Design.drawn()
    local n = 0
    for _, design in ipairs(Design.boards()) do
        if design:isCustom() then n = n + 1 end
    end
    return n
end

-- Read every drawing back off disk. The heroes go through the same `load`, which
-- means each of them applies itself on the way past and the last one wins by
-- accident -- so the picked one is applied again, on purpose, last. Two designs
-- and one release apiece: cheaper than a second way of loading.
--
-- Which character is picked therefore has to be settled before this runs; it is
-- (see Game:load).
function Design.loadAll()
    for _, design in pairs(Design.by) do
        design:load()
    end
    for _, design in pairs(Design.heroes) do
        design:load()
    end
    Design.applyHero()
end

return Design
