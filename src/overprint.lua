-- Makes the ruled lines show through everything drawn over them: page and ink go
-- to separate canvases, and one pass at the end looks each pixel's mark colour
-- and the surface under it up in Palette.overprint. Both layers are palette-
-- locked and neither uses alpha, so the match is never ambiguous and the result
-- is always one of the eight -- the point of a lookup rather than a blend mode,
-- which would invent colours off the palette.

local Palette = require("src.palette")

local Overprint = {}

local shader, lut, page, ink, target

-- The lookup lives in a texture rather than a uniform array: dynamically
-- indexing a uniform array from a fragment shader is not guaranteed on GLSL ES,
-- which is where this runs on a phone.
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

-- A window drag fires a resize every frame and these two are screen-sized, so
-- the pair they replace is released here rather than left to the collector.
function Overprint.resize(w, h)
    if page then page:release() end
    if ink then ink:release() end

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

-- Reaches into the page layer mid-ink-pass, blanks a shape out of it, and hands
-- the ink layer back. A monster is standing on the page rather than printed into
-- it, so it stamps its own silhouette in paper first -- the blank column of
-- Palette.overprint is the identity -- and its body then comes out in the
-- colours it was drawn in, without the shader knowing characters exist. The
-- transform is deliberately left alone so a caller stamps at the coordinates it
-- is already drawing at (the hero on the timetable sits inside a scale nothing
-- else knows about). Each pair costs two canvas switches, so it goes round a
-- whole crowd; order inside a pair is free.
function Overprint.beginSolid()
    love.graphics.setCanvas(page)
end

function Overprint.endSolid()
    love.graphics.setCanvas(ink)
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
