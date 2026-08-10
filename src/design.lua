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

local Design = {}
Design.__index = Design

Design.BLANK = "."   -- bare paper
Design.PENCIL = "o"  -- ink: the darkest thing on the page, and what a biro leaves

--   sprite  the field in Sprites this design keeps up to date
--   source  the art it starts from, and what RESET puts back
--   file    where it is kept, in the save directory
--   title   what the board calls it, under "DRAW YOUR"
--   hint    what the board says while it waits to be finished
--   walks   for something that stands on the page: the board's life-size copy
--           then gets the ground under it and the run's own walk bounce, and
--           something that floats gets neither
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

function Design:load()
    local rows
    local text = love.filesystem.read(self.file)
    if text then rows = parse(self, text) end

    self.grid = fromRows(rows or self.source)
    self:apply()
end

--- what there is to draw -------------------------------------------------------

-- The hero is drawn on the way into a run; everything else here is drawn when
-- the run first earns it, and an upgrade line names one of these to say so (see
-- `design` in src/upgrades.lua).
Design.by = {
    hero = newDesign({
        sprite = "player",
        source = Sprites.STICKMAN,
        file = "hero.txt",
        title = "HERO",
        hint = "SCRIBBLE OK! TO PLAY",
        walks = true,
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
}

function Design.loadAll()
    for _, design in pairs(Design.by) do
        design:load()
    end
end

return Design
