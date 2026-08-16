-- Two bitmap faces. LÖVE's default vector font would be enormous inside a
-- 320x180 canvas and would break the pixel grid, so everything with lettering in
-- it uses these instead. Glyphs are stored white and tinted with
-- love.graphics.setColor at draw time.
--
-- The 3x5 face is the whole alphabet and is what the HUD, the cards and every
-- prompt are written in. The second is digits only, 5x7 with two-pixel strokes,
-- and it exists for the damage numbers (src/damage.lua) and nothing else so far.
--
-- Two things about that face are worth knowing, because both were arrived at the
-- hard way. It is the one piece of lettering in the game that is *outlined*, and
-- a 3x5 glyph with a pixel of ink all the way round it is more outline than
-- glyph -- at that weight the counter of an 8 fills in and a 1 comes out a bar,
-- so the alphabet face could not be reused however convenient that would be.
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

-- The bold face: the glyph, the pixel of outline round it, and the pitch from
-- one outlined cell to the next. All in glyph pixels; the draw multiplies them
-- by a whole-number scale.
--
-- The pitch is a pixel *less* than the cell, so neighbouring cells share the
-- column of padding between them and a two-digit number reads as one figure
-- rather than two things sitting near each other. What separates the digits is
-- then a single pixel of ring rather than a pixel of ring, a pixel of page and a
-- pixel of ring -- which is tight, and tight is what a number wants to be.
--
-- Two facts make the overlap safe, and both have to hold. Only padding overlaps:
-- the glyph bodies sit in columns 2..6 of a 7-wide cell, so at this pitch they
-- still have a clear column between them and nothing of a figure is ever
-- covered. And every ring of a number is drawn before any of its bodies, in one
-- colour (src/damage.lua), so ring landing on ring cannot show.
local BW, BH, BPAD = 5, 7, 1
local BCELL_W, BCELL_H = BW + BPAD * 2, BH + BPAD * 2
local BADVANCE = BCELL_W - 1

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

local order, quads = {}, {}
local atlas
local boldOrder, boldQuads = {}, {}
local boldAtlas, boldRing

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

-- The bold face, twice: the glyphs sat in a padded cell, and the ring of pixels
-- one step outside each of them.
--
-- The ring is everything within a step of the glyph that is not the glyph, which
-- includes the counters -- the hole in a 0, both holes in an 8. That is on
-- purpose and it is what makes this face readable at scale 1: a counter one
-- pixel wide comes out in the ring's colour rather than showing the page
-- through, so a 0 is a light figure with a dark bar down it and never a solid
-- block. It is also why the face is authored with two-pixel strokes and
-- one-pixel counters and cannot be redrawn thinner.
local function bakeBold(glyphs, order, quads)
    local w = #order * BCELL_W
    local body = love.image.newImageData(w, BCELL_H)
    local ring = love.image.newImageData(w, BCELL_H)

    for i, ch in ipairs(order) do
        local rows = glyphs[ch]
        local at = (i - 1) * BCELL_W

        assert(#rows == BH, "bold glyph '" .. ch .. "' is the wrong height")
        for y = 1, BH do
            assert(#rows[y] == BW, "bold glyph '" .. ch .. "' row " .. y
                .. " is the wrong width")
        end

        local function ink(x, y) -- glyph coordinates, 1-based
            return x >= 1 and x <= BW and y >= 1 and y <= BH
                and rows[y]:sub(x, x) == "#"
        end

        for y = 1 - BPAD, BH + BPAD do
            for x = 1 - BPAD, BW + BPAD do
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
    for i, ch in ipairs(order) do
        quads[ch] = love.graphics.newQuad((i - 1) * BCELL_W, 0,
            BCELL_W, BCELL_H, bodyImg:getDimensions())
    end
    return bodyImg, ringImg
end

function Font.load()
    order = sortedKeys(GLYPHS)
    atlas = bake(GLYPHS, GW, GH, order, quads)

    boldOrder = sortedKeys(BOLD)
    boldAtlas, boldRing = bakeBold(BOLD, boldOrder, boldQuads)
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

--- the bold face ---------------------------------------------------------------

-- Both measure the *outlined* cell, since that is what is on the page: a caller
-- placing one of these is placing the number it can see, outline and all.
function Font.boldWidth(text, scale)
    if #text == 0 then return 0 end
    return (#text * BADVANCE - (BADVANCE - BCELL_W)) * (scale or 1)
end

function Font.boldTall(scale)
    return BCELL_H * (scale or 1)
end

-- Drawn at a whole-number scale and a whole-pixel position, so a number three
-- times the size is still on the same grid as everything else on the page --
-- which is why the pop these do (src/damage.lua) steps between whole scales
-- instead of easing through the fractions between them.
--
-- `ring` draws the outline instead of the figure; the two are the same
-- geometry, so a caller draws the ring and then the body at the same place and
-- gets an outlined number in two colours.
local function printFace(img, text, x, y, scale)
    scale = scale or 1
    x, y = math.floor(x), math.floor(y)
    for i = 1, #text do
        local q = boldQuads[text:sub(i, i)]
        if q then
            love.graphics.draw(img, q,
                x + (i - 1) * BADVANCE * scale, y, 0, scale, scale)
        end
    end
end

function Font.printBold(text, x, y, scale)
    printFace(boldAtlas, text, x, y, scale)
end

function Font.printBoldRing(text, x, y, scale)
    printFace(boldRing, text, x, y, scale)
end

return Font
