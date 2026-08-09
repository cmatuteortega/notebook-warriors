-- Turns ASCII art into palette-locked images. Every sprite in the game is
-- authored as a table of equal-length strings where each character is a key
-- from Palette.key ('.' = transparent), so no colour can sneak in off-palette.

local Palette = require("src.palette")

local pixelart = {}

local Sprite = {}
Sprite.__index = Sprite

function pixelart.newSprite(rows, opts)
    opts = opts or {}
    local h = #rows
    local w = #rows[1]

    local data = love.image.newImageData(w, h)
    -- A white silhouette of the same art, used for the flat "just got hit"
    -- flash. Tinting the sprite itself would only multiply its colours darker.
    local mask = love.image.newImageData(w, h)

    for y = 1, h do
        local row = rows[y]
        assert(#row == w, ("pixel-art row %d is %d wide, expected %d"):format(y, #row, w))
        for x = 1, w do
            local ch = row:sub(x, x)
            if ch ~= "." then
                local c = Palette.key[ch]
                assert(c, "unknown palette key '" .. ch .. "'")
                data:setPixel(x - 1, y - 1, c[1], c[2], c[3], 1)
                mask:setPixel(x - 1, y - 1, 1, 1, 1, 1)
            end
        end
    end

    return pixelart.fromData(data, mask, opts)
end

function pixelart.fromData(data, mask, opts)
    opts = opts or {}
    local w, h = data:getDimensions()

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")

    local maskImg = love.graphics.newImage(mask)
    maskImg:setFilter("nearest", "nearest")

    return setmetatable({
        img = img,
        mask = maskImg,
        w = w,
        h = h,
        -- Origin defaults to the centre so entity positions are body centres.
        ox = opts.ox or math.floor(w / 2),
        oy = opts.oy or math.floor(h / 2),
    }, Sprite)
end

-- A filled circle. Past about nine pixels across, hand-authoring a round brush
-- tip in ASCII is all transcription and no design, so the big ones are
-- generated. The half-pixel bias keeps the rim from looking cut off flat.
function pixelart.newDisc(radius)
    local size = radius * 2 + 1
    local data = love.image.newImageData(size, size)
    local mask = love.image.newImageData(size, size)
    local limit = (radius + 0.4) * (radius + 0.4)
    local c = Palette.ink

    for y = 0, size - 1 do
        for x = 0, size - 1 do
            local dx, dy = x - radius, y - radius
            if dx * dx + dy * dy <= limit then
                data:setPixel(x, y, c[1], c[2], c[3], 1)
                mask:setPixel(x, y, 1, 1, 1, 1)
            end
        end
    end

    return pixelart.fromData(data, mask)
end

--- pixel-grid shapes ----------------------------------------------------------

-- love.graphics.circle and love.graphics.line would draw smooth polygons at
-- whatever sub-pixel positions the maths lands on. These plot whole pixels in
-- the currently set colour instead, so a ring or a bar sits on the same grid as
-- everything else on the page. The thumb stick is drawn with them, and so is
-- the ring a pushpin marks its landing with, the leg of a compass, and every
-- staple.

-- One sample per pixel of the longer axis, which is what makes a line at any
-- angle come out as an unbroken run of single pixels rather than a dotted one.
--
-- One sample per pixel of the longer axis, which is what makes a line at any
-- angle come out as an unbroken run of single pixels rather than a dotted one.
function pixelart.line(x0, y0, x1, y1)
    local dx, dy = x1 - x0, y1 - y0
    local steps = math.max(1, math.floor(math.max(math.abs(dx), math.abs(dy)) + 0.5))

    for i = 0, steps do
        local t = i / steps
        love.graphics.rectangle("fill",
            math.floor(x0 + dx * t), math.floor(y0 + dy * t), 1, 1)
    end
end

function pixelart.circleOutline(cx, cy, r)
    cx, cy = math.floor(cx), math.floor(cy)

    local x, y, err = r, 0, 1 - r
    while x >= y do
        love.graphics.rectangle("fill", cx + x, cy + y, 1, 1)
        love.graphics.rectangle("fill", cx + y, cy + x, 1, 1)
        love.graphics.rectangle("fill", cx - y, cy + x, 1, 1)
        love.graphics.rectangle("fill", cx - x, cy + y, 1, 1)
        love.graphics.rectangle("fill", cx - x, cy - y, 1, 1)
        love.graphics.rectangle("fill", cx - y, cy - x, 1, 1)
        love.graphics.rectangle("fill", cx + y, cy - x, 1, 1)
        love.graphics.rectangle("fill", cx + x, cy - y, 1, 1)

        y = y + 1
        if err < 0 then
            err = err + 2 * y + 1
        else
            x = x - 1
            err = err + 2 * (y - x) + 1
        end
    end
end

function pixelart.circleFill(cx, cy, r)
    cx, cy = math.floor(cx), math.floor(cy)

    for dy = -r, r do
        local dx = math.floor(math.sqrt(r * r - dy * dy))
        love.graphics.rectangle("fill", cx - dx, cy + dy, dx * 2 + 1, 1)
    end
end

--- sprites --------------------------------------------------------------------

function Sprite:draw(x, y, flip)
    love.graphics.draw(self.img, math.floor(x), math.floor(y), 0,
        flip and -1 or 1, 1, self.ox, self.oy)
end

-- Draws the silhouette in the current colour.
function Sprite:drawMask(x, y, flip)
    love.graphics.draw(self.mask, math.floor(x), math.floor(y), 0,
        flip and -1 or 1, 1, self.ox, self.oy)
end

return pixelart
