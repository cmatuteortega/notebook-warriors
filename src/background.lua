-- The world is an endless sheet of ruled notebook paper: base colour, ruled
-- lines, and margin, baked once into a repeating tile and drawn as a single
-- wrapped quad.

local Palette = require("src.palette")

local Background = {}

-- Ruling: 2px of blue, 8px of paper, repeating. TILE_H must stay a multiple of
-- RULE_PERIOD or the pattern breaks where the tile wraps.
local RULE_THICKNESS = 2
local RULE_PERIOD = 10
local RULE_COLOR = Palette.sky

local TILE_W, TILE_H = 192, 100 -- one "page" wide, ten ruled lines tall
local MARGIN_X = 24             -- pink margin line, measured from the page edge

local tile, quad

function Background.load()
    local data = love.image.newImageData(TILE_W, TILE_H)

    data:mapPixel(function(x, y)
        local c = Palette.paper
        if y % RULE_PERIOD < RULE_THICKNESS then
            c = RULE_COLOR
        elseif x == MARGIN_X then
            c = Palette.blush
        end
        return c[1], c[2], c[3], 1
    end)

    tile = love.graphics.newImage(data)
    tile:setFilter("nearest", "nearest")
    tile:setWrap("repeat", "repeat")

    quad = love.graphics.newQuad(0, 0, TILE_W, TILE_H, TILE_W, TILE_H)
end

-- All coordinates here are world pixels; the caller has already applied the
-- camera transform, so the paper is drawn at the camera's top-left corner and
-- its texture coordinates are simply the world coordinates.
function Background.draw(left, top, w, h)
    love.graphics.setColor(1, 1, 1)
    quad:setViewport(left, top, w, h, TILE_W, TILE_H)
    love.graphics.draw(tile, quad, left, top)
end

return Background
