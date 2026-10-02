-- The world is an endless sheet of notebook paper: base colour, ruling and
-- margin, baked once into a repeating tile and drawn as a single wrapped quad.
-- One tile per subject (src/subjects.lua), all baked at load and never rebuilt,
-- which is what lets `drawAs` draw a page the run is not being played on.

local Palette = require("src.palette")
local Subjects = require("src.subjects")

local Background = {}

local pages = {}   -- { image, torn, quad, w, h } per subject key
local current      -- the one the run is being played on

-- The ruling is a pure function of position inside the tile (src/subjects.lua),
-- so baking is one pass over an ImageData and the same spec can be asked about a
-- single pixel anywhere else.
local function tile(w, h, at)
    local data = love.image.newImageData(w, h)

    data:mapPixel(function(x, y)
        local c = at(x, y)
        return c[1], c[2], c[3], 1
    end)

    local image = love.graphics.newImage(data)
    image:setFilter("nearest", "nearest")
    image:setWrap("repeat", "repeat")

    return image
end

-- Two tiles per page: the second is the same page with only its blank paper
-- greyed, the half a cut has lifted off (src/scissors.lua). Scissors take the
-- paper, not the printing, so the ruling stays put -- which is why this is a
-- bake and not a graphite fill, a fill having no way to know which pixels were
-- which.
local function bake(paper)
    return {
        image = tile(paper.w, paper.h, paper.at),
        -- Identity against the palette's own table, not three numbers: `at` may
        -- only answer with one of Palette.surfaces.
        torn = tile(paper.w, paper.h, function(x, y)
            local c = paper.at(x, y)
            if c == Palette.paper then return Palette.graphite end
            return c
        end),
        quad = love.graphics.newQuad(0, 0, paper.w, paper.h, paper.w, paper.h),
        w = paper.w,
        h = paper.h,
    }
end

function Background.load()
    for _, sub in ipairs(Subjects.list) do
        pages[sub.key] = bake(sub.paper)
    end
    current = Subjects.default.key
end

-- Which page the run is played on: set once when the subject is picked, rather
-- than threaded through everything that draws the page.
function Background.setSubject(key)
    if pages[key] then current = key end
end

-- World pixels: the caller has already applied the camera transform, so the
-- texture coordinates are simply the world coordinates.
function Background.drawAs(key, left, top, w, h)
    local page = pages[key] or pages[current]
    love.graphics.setColor(1, 1, 1)
    page.quad:setViewport(left, top, w, h, page.w, page.h)
    love.graphics.draw(page.image, page.quad, left, top)
end

function Background.draw(left, top, w, h)
    Background.drawAs(current, left, top, w, h)
end

-- One 1px-deep row of torn page, `w` wide at a world position: ruling as
-- printed, paper between it grey. A cut is a line at any angle, so the far half
-- is filled a row at a time by Scissors:drawSever and this is the only paper
-- that fill is made of. Quad wrapped in world coordinates, as for the page
-- itself: the texture *is* the world.
function Background.torn(x, y, w)
    local page = pages[current]
    love.graphics.setColor(1, 1, 1)
    page.quad:setViewport(x, y, w, 1, page.w, page.h)
    love.graphics.draw(page.torn, page.quad, x, y)
end

return Background
