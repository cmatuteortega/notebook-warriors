-- Checks hand-authored enemy art against what the game will accept, and prints
-- the block that goes into src/sprites.lua. Run it before handing a drawing
-- over: every rule it enforces is a rule that asserts at load or silently
-- moves something the rest of the game measured off the sprite.
--
--   lua art/check.lua            -- every subject folder under art/
--   lua art/check.lua music      -- one of them
--
-- The grid may not change size. The hit radius and the shadow width live on the
-- row in Enemy.types, and the shadow is drawn at floor(sprite.h / 2) below the
-- body, so a taller drawing is a shadow that has come off the feet.

local KEYS = "wgsorkbc."

-- The size of the enemy each skin replaces, and the most a skin may be drawn
-- over it. A skin is headroom rather than a resize: the hit radius stays on the
-- row in Enemy.types, the extra rows go on the top and the extra columns split
-- between the sides, and the origin is pinned so the body stands on the same
-- feet (Sprites.enemySkins). Sprites.load asserts the same three things, and
-- this is here so a bad grid is a refusal now rather than a crash on launch.
local ROOM = 4
local BASE = {
    blob   = { 8, 8 },
    bat    = { 11, 7 },
    skull  = { 10, 10 },
    eye    = { 11, 11 },
    redeye = { 11, 11 },
}
local ORDER = { "blob", "bat", "skull", "eye", "redeye" }

local function rows(path)
    local out, f = {}, io.open(path)
    if not f then return nil end
    for raw in f:lines() do
        local line = raw:gsub("%s+$", "")
        -- '#' is a note to yourself; a transparent row is written as dots, so a
        -- blank line is a mistake rather than an empty one.
        if line:sub(1, 1) ~= "#" then out[#out + 1] = line end
    end
    f:close()
    return out
end

local bad = 0
local function fail(path, msg)
    print(("  FAIL %s: %s"):format(path, msg))
    bad = bad + 1
end

local function check(subject, name)
    local path = ("art/%s/%s.txt"):format(subject, name)
    local art = rows(path)
    if not art then return end

    local bw, bh = BASE[name][1], BASE[name][2]
    local w, h = #art[1], #art
    if h < bh or h > bh + ROOM then
        fail(path, ("%d rows, expected %d to %d"):format(h, bh, bh + ROOM))
        return
    end
    if w < bw or w > bw + ROOM then
        fail(path, ("%d wide, expected %d to %d"):format(w, bw, bw + ROOM))
        return
    end
    if (w - bw) % 2 ~= 0 then
        fail(path, ("%d wide is %d over a %d-wide enemy -- widen by an even ")
            :format(w, w - bw, bw) .. "number so the padding splits evenly")
        return
    end
    for y, row in ipairs(art) do
        if #row ~= w then
            fail(path, ("row %d is %d wide, expected %d"):format(y, #row, w))
            return
        end
        for x = 1, w do
            local ch = row:sub(x, x)
            if not KEYS:find(ch, 1, true) then
                fail(path, ("row %d col %d is '%s', not a palette key (%s)")
                    :format(y, x, ch, KEYS))
                return
            end
        end
    end

    print(("  ok   %s"):format(path))
    return art
end

local function emit(subject, name, art)
    print(("        %s = pixelart.newSprite({"):format(name))
    for _, row in ipairs(art) do print(('            "%s",'):format(row)) end
    print("        }),")
end

local subjects = { ... }
if #subjects == 0 then
    local p = io.popen("ls -1 art")
    for entry in p:lines() do
        if not entry:match("%.lua$") then subjects[#subjects + 1] = entry end
    end
    p:close()
end

for _, subject in ipairs(subjects) do
    print(subject .. ":")
    local built = {}
    for _, name in ipairs(ORDER) do
        local art = check(subject, name)
        if art then built[name] = art end
    end
    if bad == 0 then
        print("")
        for _, name in ipairs(ORDER) do
            if built[name] then emit(subject, name, built[name]) end
        end
    end
end

os.exit(bad == 0 and 0 or 1)
