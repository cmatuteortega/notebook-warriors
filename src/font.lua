-- Three bitmap faces. LÖVE's default vector font would be enormous inside a
-- 320x180 canvas and would break the pixel grid, so everything with lettering in
-- it uses these instead. Glyphs are stored white and tinted with
-- love.graphics.setColor at draw time.
--
-- The 3x5 face is the whole alphabet and is what the HUD, the cards and every
-- prompt are written in. The other two are digits only, with two-pixel strokes,
-- and both exist for the damage numbers (src/damage.lua) and nothing else so
-- far: `Font.bold` at 5x7, and `Font.boldSmall` at 5x5 for the tier of hits too
-- small to be worth the room (see below).
--
-- Two things about the bold faces are worth knowing, because both were arrived
-- at the hard way. They are the one piece of lettering in the game that is
-- *outlined*, and a 3x5 glyph with a pixel of ink all the way round it is more
-- outline than glyph -- at that weight the counter of an 8 fills in and a 1
-- comes out a bar, so the alphabet face could not be reused however convenient
-- that would be.
--
-- And the outline is baked into the atlas rather than drawn as offset copies of
-- the glyph, which is how the rest of the game does an outline (Sprites.rim,
-- Enemy:draw's bleach). Two reasons. Copies of a *glyph* offset by a pixel eat
-- one pixel off the pitch at each side, so at any sensible advance the digits of
-- a number fuse into a single dark plate with the figures knocked out of it --
-- readable, but it stops looking like numbers. And a number is up to three
-- glyphs redrawn eight times each: baked, it is one draw per ring per digit,
-- which is what makes a screenful of them free.

local Font = {}

local GW, GH, ADVANCE = 3, 5, 4

-- The pixel of outline round a bold glyph, and the only number here that is not
-- a property of one face. It cannot be anything but 1: a thicker ring would
-- close the counters, and there is nothing thinner than a pixel.
local BPAD = 1

local GLYPHS = {
    A = { ".#.", "#.#", "###", "#.#", "#.#" },
    B = { "##.", "#.#", "##.", "#.#", "##." },
    C = { ".##", "#..", "#..", "#..", ".##" },
    D = { "##.", "#.#", "#.#", "#.#", "##." },
    E = { "###", "#..", "##.", "#..", "###" },
    F = { "###", "#..", "##.", "#..", "#.." },
    G = { ".##", "#..", "#.#", "#.#", ".##" },
    H = { "#.#", "#.#", "###", "#.#", "#.#" },
    I = { "###", ".#.", ".#.", ".#.", "###" },
    J = { "..#", "..#", "..#", "#.#", ".#." },
    K = { "#.#", "##.", "#..", "##.", "#.#" },
    L = { "#..", "#..", "#..", "#..", "###" },
    M = { "#.#", "###", "###", "#.#", "#.#" },
    N = { "#.#", "##.", "###", ".##", "#.#" },
    O = { ".#.", "#.#", "#.#", "#.#", ".#." },
    P = { "##.", "#.#", "##.", "#..", "#.." },
    Q = { ".#.", "#.#", "#.#", "##.", ".##" },
    R = { "##.", "#.#", "##.", "#.#", "#.#" },
    S = { ".##", "#..", ".#.", "..#", "##." },
    T = { "###", ".#.", ".#.", ".#.", ".#." },
    U = { "#.#", "#.#", "#.#", "#.#", "###" },
    V = { "#.#", "#.#", "#.#", "#.#", ".#." },
    W = { "#.#", "#.#", "###", "###", "#.#" },
    X = { "#.#", "#.#", ".#.", "#.#", "#.#" },
    Y = { "#.#", "#.#", ".#.", ".#.", ".#." },
    Z = { "###", "..#", ".#.", "#..", "###" },
    ["0"] = { "###", "#.#", "#.#", "#.#", "###" },
    ["1"] = { ".#.", "##.", ".#.", ".#.", "###" },
    ["2"] = { "##.", "..#", ".#.", "#..", "###" },
    ["3"] = { "##.", "..#", ".#.", "..#", "##." },
    ["4"] = { "#.#", "#.#", "###", "..#", "..#" },
    ["5"] = { "###", "#..", "##.", "..#", "##." },
    ["6"] = { ".##", "#..", "###", "#.#", "###" },
    ["7"] = { "###", "..#", ".#.", ".#.", ".#." },
    ["8"] = { "###", "#.#", "###", "#.#", "###" },
    ["9"] = { "###", "#.#", "###", "..#", "##." },
    [":"] = { "...", ".#.", "...", ".#.", "..." },
    ["."] = { "...", "...", "...", "...", ".#." },
    ["-"] = { "...", "...", "###", "...", "..." },
    ["/"] = { "..#", "..#", ".#.", "#..", "#.." },
    ["!"] = { ".#.", ".#.", ".#.", "...", ".#." },
    ["?"] = { "##.", "..#", ".#.", "...", ".#." },
    ["+"] = { "...", ".#.", "###", ".#.", "..." },
    ["%"] = { "#.#", "..#", ".#.", "#..", "#.#" },
    [" "] = { "...", "...", "...", "...", "..." },
}

-- Digits only. Every stroke is two pixels thick and every counter is one, which
-- is what lets a glyph keep its shape under an outline drawn a pixel out all the
-- way round it -- and what makes the face read as heavier than the HUD's, which
-- is the point: these are numbers that are meant to feel like a thump.
--
-- Five is the narrowest a two-sided digit can be under those rules -- two of
-- stroke, one of counter, two of stroke -- so neither bold face is narrower than
-- the other and a number is the same width whichever one draws it.
local BOLD = {
    ["0"] = { "#####", "##.##", "##.##", "##.##", "##.##", "##.##", "#####" },
    ["1"] = { "..##.", ".###.", "..##.", "..##.", "..##.", "..##.", "#####" },
    ["2"] = { "#####", "...##", "...##", "#####", "##...", "##...", "#####" },
    ["3"] = { "#####", "...##", "...##", ".####", "...##", "...##", "#####" },
    ["4"] = { "##.##", "##.##", "##.##", "#####", "...##", "...##", "...##" },
    ["5"] = { "#####", "##...", "##...", "#####", "...##", "...##", "#####" },
    ["6"] = { "#####", "##...", "##...", "#####", "##.##", "##.##", "#####" },
    ["7"] = { "#####", "...##", "...##", "..##.", "..##.", ".##..", ".##.." },
    ["8"] = { "#####", "##.##", "##.##", "#####", "##.##", "##.##", "#####" },
    ["9"] = { "#####", "##.##", "##.##", "#####", "...##", "...##", "#####" },
}

-- The same rules two rows shorter: one counter row instead of two. Drawn a pixel
-- taller than the HUD's lettering and a pixel shorter than a blob, which is the
-- whole reason it exists -- the tier that uses it is chip damage, and a number
-- that stands taller than the monster it came off is not saying "this barely
-- happened".
--
-- 5x5 is the floor of this design and there is nothing under it. An 8 needs
-- three bars with a counter between each pair, so the height can only be 3 + 2c
-- -- 7 with two-pixel counters, 5 with one-pixel ones, and no value in between.
-- Going below would mean one-pixel strokes, which is the alphabet face, which
-- does not survive an outline. The cost is that 5, 6, 8 and 9 now differ by a
-- single row; it holds at this size, but there is no margin left in it.
--
-- All ten are authored even though the tier that draws them tops out at 5 and so
-- can only ever ask for five of them: a threshold moved in src/damage.lua should
-- change what a number looks like, never make one impossible to draw.
local BOLD_SMALL = {
    ["0"] = { "#####", "##.##", "##.##", "##.##", "#####" },
    ["1"] = { "..##.", ".###.", "..##.", "..##.", "#####" },
    ["2"] = { "#####", "...##", "#####", "##...", "#####" },
    ["3"] = { "#####", "...##", ".####", "...##", "#####" },
    ["4"] = { "##.##", "##.##", "#####", "...##", "...##" },
    ["5"] = { "#####", "##...", "#####", "...##", "#####" },
    ["6"] = { "#####", "##...", "#####", "##.##", "#####" },
    ["7"] = { "#####", "...##", "..##.", ".##..", ".##.." },
    ["8"] = { "#####", "##.##", "#####", "##.##", "#####" },
    ["9"] = { "#####", "##.##", "#####", "...##", "#####" },
}

local order, quads = {}, {}
local atlas

local function sortedKeys(glyphs)
    local out = {}
    for ch in pairs(glyphs) do out[#out + 1] = ch end
    table.sort(out)
    return out
end

local function newImage(data)
    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

-- One face into one strip of an image, white on nothing, plus a quad per glyph.
local function bake(glyphs, gw, gh, order, quads)
    local data = love.image.newImageData(#order * gw, gh)
    for i, ch in ipairs(order) do
        local rows = glyphs[ch]
        for y = 1, gh do
            assert(#rows[y] == gw, "glyph row is the wrong width")
            for x = 1, gw do
                if rows[y]:sub(x, x) == "#" then
                    data:setPixel((i - 1) * gw + x - 1, y - 1, 1, 1, 1, 1)
                end
            end
        end
    end

    local img = newImage(data)
    for i, ch in ipairs(order) do
        quads[ch] = love.graphics.newQuad((i - 1) * gw, 0, gw, gh, img:getDimensions())
    end
    return img
end

--- the bold faces --------------------------------------------------------------

-- A bold face is a size, not a global: there are two of them and a caller picks
-- one, so everything that used to be a module constant -- the cell, the pitch,
-- the two atlases -- hangs off the face itself.
local Bold = {}
Bold.__index = Bold

-- Baked twice: the glyphs sat in a padded cell, and the ring of pixels one step
-- outside each of them.
--
-- The ring is everything within a step of the glyph that is not the glyph, which
-- includes the counters -- the hole in a 0, both holes in an 8. That is on
-- purpose and it is what makes these faces readable at scale 1: a counter one
-- pixel wide comes out in the ring's colour rather than showing the page
-- through, so a 0 is a light figure with a dark bar down it and never a solid
-- block. It is also why they are authored with two-pixel strokes and one-pixel
-- counters and cannot be redrawn thinner.
--
-- The pitch is a pixel *less* than the cell, so neighbouring cells share the
-- column of padding between them and a two-digit number reads as one figure
-- rather than two things sitting near each other. What separates the digits is
-- then a single pixel of ring rather than a pixel of ring, a pixel of page and a
-- pixel of ring -- which is tight, and tight is what a number wants to be.
--
-- Two facts make that overlap safe and both have to hold. Only padding overlaps:
-- the figures sit in the middle five columns of a seven-wide cell, so at this
-- pitch they still have a clear column between them and nothing of a figure is
-- ever covered. And every ring of a number is drawn before any of its bodies, in
-- one colour (src/damage.lua), so ring landing on ring cannot show.
local function newBold(glyphs)
    local order = sortedKeys(glyphs)
    local gw, gh = #glyphs[order[1]][1], #glyphs[order[1]]
    local cw, ch = gw + BPAD * 2, gh + BPAD * 2

    local body = love.image.newImageData(#order * cw, ch)
    local ring = love.image.newImageData(#order * cw, ch)
    local quads = {}

    for i, key in ipairs(order) do
        local rows = glyphs[key]
        local at = (i - 1) * cw

        assert(#rows == gh, "bold glyph '" .. key .. "' is the wrong height")
        for y = 1, gh do
            assert(#rows[y] == gw, "bold glyph '" .. key .. "' row " .. y
                .. " is the wrong width")
        end

        local function ink(x, y) -- glyph coordinates, 1-based
            return x >= 1 and x <= gw and y >= 1 and y <= gh
                and rows[y]:sub(x, x) == "#"
        end

        for y = 1 - BPAD, gh + BPAD do
            for x = 1 - BPAD, gw + BPAD do
                local px, py = at + x - 1 + BPAD, y - 1 + BPAD
                if ink(x, y) then
                    body:setPixel(px, py, 1, 1, 1, 1)
                else
                    local touching = false
                    for dy = -BPAD, BPAD do
                        for dx = -BPAD, BPAD do
                            touching = touching or ink(x + dx, y + dy)
                        end
                    end
                    if touching then ring:setPixel(px, py, 1, 1, 1, 1) end
                end
            end
        end
    end

    local bodyImg, ringImg = newImage(body), newImage(ring)
    for i, key in ipairs(order) do
        quads[key] = love.graphics.newQuad((i - 1) * cw, 0, cw, ch,
            bodyImg:getDimensions())
    end

    return setmetatable({
        body = bodyImg, ring = ringImg, quads = quads,
        cw = cw, ch = ch, advance = cw - 1,
    }, Bold)
end

-- Both measure the *outlined* cell, since that is what is on the page: a caller
-- placing one of these is placing the number it can see, outline and all.
function Bold:width(text, scale)
    if #text == 0 then return 0 end
    return (#text * self.advance - (self.advance - self.cw)) * (scale or 1)
end

function Bold:tall(scale)
    return self.ch * (scale or 1)
end

-- Drawn at a whole-number scale and a whole-pixel position, so a number three
-- times the size is still on the same grid as everything else on the page --
-- which is why the pop these do (src/damage.lua) steps between whole scales
-- instead of easing through the fractions between them.
function Bold:draw(img, text, x, y, scale)
    scale = scale or 1
    x, y = math.floor(x), math.floor(y)
    for i = 1, #text do
        local q = self.quads[text:sub(i, i)]
        if q then
            love.graphics.draw(img, q,
                x + (i - 1) * self.advance * scale, y, 0, scale, scale)
        end
    end
end

-- The figure, and the outline round it. Same geometry, so a caller draws the
-- ring and then the body at the same place and gets an outlined number in two
-- colours -- and can skip the body to get a hollow one.
function Bold:print(text, x, y, scale)
    self:draw(self.body, text, x, y, scale)
end

function Bold:printRing(text, x, y, scale)
    self:draw(self.ring, text, x, y, scale)
end

function Font.load()
    order = sortedKeys(GLYPHS)
    atlas = bake(GLYPHS, GW, GH, order, quads)

    Font.bold = newBold(BOLD)
    Font.boldSmall = newBold(BOLD_SMALL)
end

function Font.width(text)
    if #text == 0 then return 0 end
    return #text * ADVANCE - 1
end

Font.height = GH
-- Pitch from one glyph to the next. The title screen blows the font up by a
-- whole number and places letters itself, so it needs to know the step.
Font.advance = ADVANCE

-- Draws with whatever colour is currently set. Unknown characters are skipped.
function Font.print(text, x, y)
    x, y = math.floor(x), math.floor(y)
    for i = 1, #text do
        local q = quads[text:sub(i, i):upper()]
        if q then
            love.graphics.draw(atlas, q, x + (i - 1) * ADVANCE, y)
        end
    end
end

function Font.printCentered(text, cx, y)
    Font.print(text, cx - Font.width(text) / 2, y)
end

function Font.printRight(text, rx, y)
    Font.print(text, rx - Font.width(text), y)
end

return Font
