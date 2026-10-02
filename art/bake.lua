-- Bakes art/<subject>/*.txt into the Sprites.enemySkins block in
-- src/sprites.lua, which is the one direction the art travels: the txt files are
-- the drawing board and sprites.lua is the game. Nothing reads art/ at runtime,
-- so a distributable is still `zip -r game.love main.lua conf.lua src`.
--
--   lua art/bake.lua            -- every subject folder under art/
--   lua art/bake.lua music      -- one of them
--
-- It refuses on anything art/check.lua would refuse on, since a bad grid in here
-- is an assert on the next launch rather than a wonky drawing.

local SRC = "src/sprites.lua"
local BEGIN = "    -- BAKE:enemySkins begin"
local FINISH = "    -- BAKE:enemySkins end"

local KEYS = "wgsorkbc."

-- The size of the enemy each skin replaces, and the most a skin may be drawn
-- over it. A skin is headroom rather than a resize: the hit radius stays on the
-- row in Enemy.types, the extra rows go on the top and the extra columns split
-- between the sides, and the origin is pinned so the body stands on the same
-- feet (Sprites.enemySkins). Sprites.load asserts the same three things; these
-- are here so a bad grid is a refusal at the bake rather than a crash on launch.
local ROOM = 4
local BASE = {
    blob   = { 8, 8 },
    bat    = { 11, 7 },
    wad    = { 9, 9 },
    blot   = { 10, 9 },
    drop   = { 6, 7 },
    skull  = { 10, 10 },
    bulb   = { 9, 10 },
    eye    = { 11, 11 },
    grin   = { 14, 14 },
    redeye = { 11, 11 },
}
-- Roughly the order the run meets them (TABLE in src/spawner.lua), so a folder
-- half drawn is drawn from the front. `drop` sits next to the blot it falls off
-- rather than where it is first seen, since it is never spawned on its own.
local ORDER = { "blob", "bat", "wad", "blot", "drop", "skull", "bulb", "eye",
                "grin", "redeye" }

-- Not every folder under art/ is a subject: `vanilla` is the crowd as it stands,
-- kept there to draw against rather than to be baked over the top of itself.
local SKIP = { vanilla = true }

local function art(path)
    local f = io.open(path)
    if not f then return nil end
    local rows = {}
    for raw in f:lines() do
        local line = raw:gsub("%s+$", "")
        if line:sub(1, 1) ~= "#" then rows[#rows + 1] = line end
    end
    f:close()
    return rows
end

local function verify(path, name, rows)
    local bw, bh = BASE[name][1], BASE[name][2]
    local w, h = #rows[1], #rows

    if h < bh or h > bh + ROOM then
        error(("%s: %d rows, expected %d to %d"):format(path, h, bh, bh + ROOM), 0)
    end
    if w < bw or w > bw + ROOM then
        error(("%s: %d wide, expected %d to %d"):format(path, w, bw, bw + ROOM), 0)
    end
    if (w - bw) % 2 ~= 0 then
        error(("%s: %d wide is %d over a %d-wide enemy -- widen by an even number ")
            :format(path, w, w - bw, bw) .. "so the padding splits evenly", 0)
    end
    for y, row in ipairs(rows) do
        if #row ~= w then
            error(("%s: row %d is %d wide, expected %d"):format(path, y, #row, w), 0)
        end
        for x = 1, w do
            local ch = row:sub(x, x)
            if not KEYS:find(ch, 1, true) then
                error(("%s: row %d col %d is '%s', not a palette key (%s)")
                    :format(path, y, x, ch, KEYS), 0)
            end
        end
    end
end

local function subjects()
    local out = {}
    local p = io.popen("ls -1 art")
    for entry in p:lines() do
        if not entry:match("%.lua$") and not entry:match("%.py$")
            and not entry:match("%.png$") and not SKIP[entry] then
            out[#out + 1] = entry
        end
    end
    p:close()
    return out
end

local wanted = { ... }
if #wanted == 0 then wanted = subjects() end

local body, drawn = {}, 0
body[#body + 1] = "    Sprites.enemySkins = {"
for _, subject in ipairs(wanted) do
    local rows = {}
    for _, name in ipairs(ORDER) do
        local grid = art(("art/%s/%s.txt"):format(subject, name))
        if grid then
            verify(("art/%s/%s.txt"):format(subject, name), name, grid)
            rows[#rows + 1] = { name, grid }
        end
    end
    if #rows > 0 then
        body[#body + 1] = ("        %s = {"):format(subject)
        for _, row in ipairs(rows) do
            body[#body + 1] = ("            %s = pixelart.newSprite({"):format(row[1])
            for _, line in ipairs(row[2]) do
                body[#body + 1] = ('                "%s",'):format(line)
            end
            body[#body + 1] = "            }),"
            drawn = drawn + 1
        end
        body[#body + 1] = "        },"
        print(("%s: %d sprites"):format(subject, #rows))
    end
end
body[#body + 1] = "    }"

local f = assert(io.open(SRC))
local src = f:read("*a")
f:close()

local head = src:find(BEGIN, 1, true)
local tail = src:find(FINISH, 1, true)
assert(head and tail, "the BAKE:enemySkins markers are gone from " .. SRC)

local out = src:sub(1, head + #BEGIN)
    .. table.concat(body, "\n") .. "\n"
    .. src:sub(tail)
f = assert(io.open(SRC, "w"))
f:write(out)
f:close()

print(("baked %d sprites into %s"):format(drawn, SRC))
