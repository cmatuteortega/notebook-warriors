-- The player character, as drawn by the player.
--
-- The design is a grid of palette keys exactly the size of the sprite it
-- becomes, so what is drawn on the studio's board is the sprite pixel for
-- pixel -- nothing is resampled, scaled or interpreted in between. Every change
-- is pushed straight into Sprites.player, which is what the run draws, what the
-- title screen's doodle draws, and what the studio's own life-size preview
-- draws: there is only ever one hero.
--
-- The last design committed is written to the save directory and read back on
-- the next launch, so the character you drew is still yours a week later. A
-- file that has been edited into something the game can't draw is ignored
-- rather than trusted, and you get the stick man back.

local Palette = require("src.palette")
local Sprites = require("src.sprites")

local Hero = {}

local FILE = "hero.txt"

Hero.W = #Sprites.STICKMAN[1]
Hero.H = #Sprites.STICKMAN

Hero.BLANK = "."   -- bare paper
Hero.PENCIL = "o"  -- ink: the darkest thing on the page, and what a biro leaves

local grid -- [y][x] = palette key

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

function Hero.rows()
    local rows = {}
    for y = 1, Hero.H do
        rows[y] = table.concat(grid[y])
    end
    return rows
end

--- the design ----------------------------------------------------------------

function Hero.get(x, y)
    return grid[y][x]
end

-- Returns true if the page actually changed, so a drag that crosses the same
-- cell forty times only rebuilds the sprite once.
function Hero.set(x, y, ch)
    if grid[y][x] == ch then return false end
    grid[y][x] = ch
    Hero.apply()
    return true
end

-- Nothing drawn is nothing to play as. The studio refuses to hand an empty
-- board to the run rather than letting an invisible hero out onto the page.
function Hero.isBlank()
    for y = 1, Hero.H do
        for x = 1, Hero.W do
            if grid[y][x] ~= Hero.BLANK then return false end
        end
    end
    return true
end

function Hero.reset()
    grid = fromRows(Sprites.STICKMAN)
    Hero.apply()
end

function Hero.apply()
    Sprites.setPlayer(Hero.rows())
end

--- the save file --------------------------------------------------------------

-- One line per row of the design, which makes the file the drawing: opening it
-- in a text editor shows the character.
local function parse(text)
    local rows = {}
    for line in text:gmatch("[^\r\n]+") do
        rows[#rows + 1] = line
    end
    if #rows ~= Hero.H then return nil end

    for _, row in ipairs(rows) do
        if #row ~= Hero.W then return nil end
        for i = 1, #row do
            local ch = row:sub(i, i)
            if ch ~= Hero.BLANK and not Palette.key[ch] then return nil end
        end
    end

    return rows
end

function Hero.save()
    return love.filesystem.write(FILE, table.concat(Hero.rows(), "\n"))
end

function Hero.load()
    local rows
    local text = love.filesystem.read(FILE)
    if text then rows = parse(text) end

    grid = fromRows(rows or Sprites.STICKMAN)
    Hero.apply()
end

return Hero
