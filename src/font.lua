-- A 3x5 bitmap font. LÖVE's default vector font would be enormous inside a
-- 320x180 canvas and would break the pixel grid, so the HUD uses this instead.
-- Glyphs are stored white and tinted with love.graphics.setColor at draw time.

local Font = {}

local GW, GH, ADVANCE = 3, 5, 4

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

local order, quads = {}, {}
local atlas

function Font.load()
    for ch in pairs(GLYPHS) do
        order[#order + 1] = ch
    end
    table.sort(order)

    local data = love.image.newImageData(#order * GW, GH)
    for i, ch in ipairs(order) do
        local rows = GLYPHS[ch]
        for y = 1, GH do
            for x = 1, GW do
                if rows[y]:sub(x, x) == "#" then
                    data:setPixel((i - 1) * GW + x - 1, y - 1, 1, 1, 1, 1)
                end
            end
        end
    end

    atlas = love.graphics.newImage(data)
    atlas:setFilter("nearest", "nearest")

    for i, ch in ipairs(order) do
        quads[ch] = love.graphics.newQuad((i - 1) * GW, 0, GW, GH, atlas:getDimensions())
    end
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
