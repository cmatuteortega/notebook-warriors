-- Makes the ruled lines show through everything drawn on top of them.
--
-- Nothing else in the game knows this is happening. The page and the ink that
-- lands on it go to separate canvases, and one pass at the end pairs them up:
-- for each pixel, the mark's colour and the surface underneath it are matched
-- against the palette and looked up in Palette.overprint.
--
-- Both layers are palette-locked and neither uses alpha, so every pixel is an
-- exact palette colour, the match is never ambiguous, and the result can only
-- ever be one of the eight -- the whole point of doing this as a lookup rather
-- than as a blend mode, which would invent colours off the palette.

local Palette = require("src.palette")

local Overprint = {}

local shader, lut, page, ink, target

-- The lookup lives in a texture rather than a uniform array: dynamically
-- indexing a uniform array from a fragment shader is not guaranteed on GLSL ES,
-- which is exactly where this game runs when it runs on a phone.
local SOURCE = [[
uniform Image pageTex;
uniform Image lut;
uniform vec3 marks[MARKS];
uniform vec3 surfaces[SURFACES];

// Squared distance is enough -- palette entries sit far apart, and the layers
// are exact palette colours to begin with, so this is a match and not a guess.
vec4 effect(vec4 tint, Image tex, vec2 tc, vec2 sc) {
    vec4 mark = Texel(tex, tc);
    vec4 sheet = Texel(pageTex, tc);

    if (mark.a < 0.5) {
        return vec4(sheet.rgb, 1.0);
    }

    int mi = 0;
    float best = 4.0;
    for (int i = 0; i < MARKS; i++) {
        vec3 d = mark.rgb - marks[i];
        float m = dot(d, d);
        if (m < best) { best = m; mi = i; }
    }

    int si = 0;
    best = 4.0;
    for (int i = 0; i < SURFACES; i++) {
        vec3 d = sheet.rgb - surfaces[i];
        float m = dot(d, d);
        if (m < best) { best = m; si = i; }
    }

    vec2 at = vec2((float(mi) + 0.5) / float(MARKS),
                   (float(si) + 0.5) / float(SURFACES));
    return vec4(Texel(lut, at).rgb, 1.0);
}
]]

local function buildLut()
    local w, h = #Palette.marks, #Palette.surfaces
    local data = love.image.newImageData(w, h)

    for x = 1, w do
        local row = Palette.overprint[Palette.marks[x]]
        for y = 1, h do
            local c = Palette[row[y]]
            assert(c, "overprint names a colour that is not in the palette")
            data:setPixel(x - 1, y - 1, c[1], c[2], c[3], 1)
        end
    end

    local img = love.graphics.newImage(data)
    img:setFilter("nearest", "nearest")
    return img
end

local function colors(names)
    local out = {}
    for i, name in ipairs(names) do out[i] = Palette[name] end
    return out
end

function Overprint.load()
    shader = love.graphics.newShader(
        ("#define MARKS %d\n#define SURFACES %d\n"):format(#Palette.marks, #Palette.surfaces)
        .. SOURCE)

    lut = buildLut()
    shader:send("lut", lut)
    shader:send("marks", unpack(colors(Palette.marks)))
    shader:send("surfaces", unpack(colors(Palette.surfaces)))
end

function Overprint.resize(w, h)
    page = love.graphics.newCanvas(w, h)
    ink = love.graphics.newCanvas(w, h)
    page:setFilter("nearest", "nearest")
    ink:setFilter("nearest", "nearest")
end

function Overprint.beginPage()
    target = love.graphics.getCanvas()
    love.graphics.setCanvas(page)
    love.graphics.clear(Palette.paper)
end

function Overprint.beginInk()
    love.graphics.setCanvas(ink)
    love.graphics.clear(0, 0, 0, 0)
end

function Overprint.finish()
    love.graphics.setCanvas(target)
    love.graphics.setShader(shader)
    shader:send("pageTex", page)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(ink)
    love.graphics.setShader()
end

return Overprint
