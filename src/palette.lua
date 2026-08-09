-- The only colours allowed in the game. Nothing may be drawn outside this list,
-- so every module pulls from here instead of writing literal rgb values.

local function hex(s)
    return {
        tonumber(s:sub(1, 2), 16) / 255,
        tonumber(s:sub(3, 4), 16) / 255,
        tonumber(s:sub(5, 6), 16) / 255,
    }
end

local Palette = {
    paper    = hex("e6ecef"), -- page background
    graphite = hex("b2b1c0"), -- pencil grey, shadows, grain
    slate    = hex("5b4f6e"), -- mid ink
    ink      = hex("280732"), -- darkest ink, outlines
    red      = hex("e15e6e"), -- margin line, player, hits
    blush    = hex("f3a8a8"), -- soft pink fill
    blue     = hex("7194f0"), -- pen blue
    sky      = hex("abc9f1"), -- ruled lines, light blue fill
}

-- Single-character keys used by the ASCII pixel-art in src/sprites.lua.
Palette.key = {
    w = Palette.paper,
    g = Palette.graphite,
    s = Palette.slate,
    o = Palette.ink,
    r = Palette.red,
    k = Palette.blush,
    b = Palette.blue,
    c = Palette.sky,
}

-- Ink is not paint. A mark laid over a printed rule does not hide it: the two
-- pigments stack, and the crossing comes out one step darker than the mark
-- alone -- which is why a biro line over the blue ruling of a notebook goes
-- nearly black. Hue survives wherever the palette has a darker shade of it;
-- where it doesn't, the mix falls back to the neutral ramp.
--
-- Two colours are absolute and never move: ink is already the darkest thing on
-- the page, and paper is not an ink at all but an eraser, so it wipes whatever
-- it lands on rather than stacking with it.
--
-- The page can only ever be blank, ruled, or margin, so this is the whole
-- interaction -- eight marks by three surfaces. src/overprint.lua applies it.
Palette.marks = { "paper", "graphite", "slate", "ink", "sky", "blue", "blush", "red" }
Palette.surfaces = { "paper", "sky", "blush" }

Palette.overprint = {
    --           blank       ruled line  margin line
    paper    = { "paper",    "paper",    "paper" },    -- erases; never stacks
    graphite = { "graphite", "slate",    "slate" },
    slate    = { "slate",    "ink",      "ink" },
    ink      = { "ink",      "ink",      "ink" },      -- already the darkest
    sky      = { "sky",      "blue",     "blue" },
    blue     = { "blue",     "slate",    "slate" },    -- no darker blue exists
    blush    = { "blush",    "red",      "red" },
    red      = { "red",      "slate",    "slate" },    -- no darker red exists
}

return Palette
