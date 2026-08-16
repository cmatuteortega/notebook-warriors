-- The world is an endless sheet of notebook paper: base colour, ruling and
-- margin, baked once into a repeating tile and drawn as a single wrapped quad.
--
-- One tile per subject (src/subjects.lua), all of them baked at load and none of
-- them ever rebuilt. A page is a couple of hundred kilobytes and there are four,
-- so keeping them all costs less than the branch that would decide when to throw
-- one away -- and it is what lets the timetable draw a swatch of a page you are
-- not playing on beside the one you are.

local Palette = require("src.palette")
local Subjects = require("src.subjects")

local Background = {}

local pages = {}   -- { image, quad, w, h } per subject key
local current      -- the one the run is being played on

-- The ruling is a pure function of position inside the tile (src/subjects.lua),
-- so baking it is one pass over an ImageData and the same spec can be asked
-- about a single pixel anywhere else.
local function bake(paper)
    local data = love.image.newImageData(paper.w, paper.h)

    data:mapPixel(function(x, y)
        local c = paper.at(x, y)
        return c[1], c[2], c[3], 1
    end)

    local image = love.graphics.newImage(data)
    image:setFilter("nearest", "nearest")
    image:setWrap("repeat", "repeat")

    return {
        image = image,
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

-- Which page the run is played on. Set once when the subject is picked, rather
-- than passed down through everything that draws the page: the paper is a fact
-- about the book being open at a particular place, not about any one frame.
function Background.setSubject(key)
    if pages[key] then current = key end
end

-- All coordinates here are world pixels; the caller has already applied the
-- camera transform, so the paper is drawn at the camera's top-left corner and
-- its texture coordinates are simply the world coordinates.
function Background.drawAs(key, left, top, w, h)
    local page = pages[key] or pages[current]
    love.graphics.setColor(1, 1, 1)
    page.quad:setViewport(left, top, w, h, page.w, page.h)
    love.graphics.draw(page.image, page.quad, left, top)
end

function Background.draw(left, top, w, h)
    Background.drawAs(current, left, top, w, h)
end

-- A piece of a page, laid where the screen wants it rather than where the world
-- says it goes: the timetable's cards are each a torn-off square of the subject
-- they offer. Read from the tile's own origin, so every swatch starts on the
-- same line of ruling and four of them side by side line up.
function Background.drawPatch(key, x, y, w, h)
    local page = pages[key] or pages[current]
    love.graphics.setColor(1, 1, 1)
    page.quad:setViewport(0, 0, w, h, page.w, page.h)
    love.graphics.draw(page.image, page.quad, x, y)
end

return Background
