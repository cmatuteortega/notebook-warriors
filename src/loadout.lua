-- What a run has learned.
--
-- One of these is built by Game:reset and thrown away with the run. It holds
-- the level a run has reached on every upgrade line (src/upgrades.lua) and
-- turns that into three things the rest of the game reads:
--
--   stats    every number about the player, from move speed to how far xp comes
--   tools    the run's *own copy* of Tools.list, with the upgrades applied
--   weapons  the passive weapons that fight for you, live
--
-- All three are rebuilt from scratch every time an upgrade is taken, by
-- replaying every level from the ground up. That costs nothing at the rate a
-- run levels up, and it buys two things worth far more than it: no level has to
-- undo anything, and a number that depends on the shape of the window comes out
-- right again when the window changes shape.
--
-- The tools are copies because Tools.list is shared by every run the program
-- plays and upgrades change the numbers in it. The weapons are *not* rebuilt:
-- an orbit that has been turning for two minutes keeps its angle when the
-- upgrade that speeds it up lands, and a rocket already in the air keeps the
-- numbers it was fired with.

local Tools = require("src.tools")
local Upgrades = require("src.upgrades")
local Orbital = require("src.orbital")
local Rocket = require("src.rocket")

local Loadout = {}
Loadout.__index = Loadout

-- Passive weapons: the stat block an upgrade line puts on the run, and the
-- module that flies it. The block turning up is what brings the weapon in.
local WEAPONS = {
    { stat = "star", module = Orbital },
    { stat = "rocket", module = Rocket },
}

function Loadout.new(vw, vh)
    local self = setmetatable({
        taken = {},      -- id -> level reached
        order = {},      -- ids, in the order they were first taken
        stats = {},
        tools = {},
        weapons = {},
        live = {},       -- stat name -> the weapon flying it, kept across rebuilds
    }, Loadout)

    self:rebuild(vw, vh)
    return self
end

function Loadout:levelOf(id)
    return self.taken[id] or 0
end

--- building it ---------------------------------------------------------------

local function toolNamed(tools, name)
    for _, tool in ipairs(tools) do
        if tool.name == name then return tool end
    end
end

-- Damage multipliers land once, at the end, on top of whatever the tool's own
-- upgrades did to its numbers -- so the scissors sharpen the ruler you have
-- rather than the ruler you started with.
local function scaleDamage(tool, mult)
    if tool.damage then tool.damage = tool.damage * mult end
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block and block.damage then
            block.damage = block.damage * mult
        end
    end
end

-- The blotter, on the same terms and for the same reason: whatever the tool
-- charges after its own upgrades have had their say, charged less. One field,
-- because `ink` means the same thing on a brush and on a tool that is tapped --
-- per pixel there, per use here -- and a discount applies to both alike.
local function scaleCost(tool, mult)
    tool.ink = tool.ink * mult
end

-- The fixative. What moves is what goes on *working* after the stroke is over:
-- how long a mark stays on the page, and how long it holds what it caught.
--
-- Which is why this walks the top-level fields and the drop block and stops
-- there. A brush's `life` is exactly how long it keeps hitting, walling or
-- lingering, and the gluestick's `freeze` is its whole point. A pin's hold and
-- its life are one number written twice (src/tools.lua) and have to stay that
-- way, so both move together. But the line a ruler leaves and the circle a
-- compass leaves have already done everything they are ever going to do -- the
-- hit landed on the swing -- so stretching those would put nothing on the page
-- but old pencil.
local function scalePersistence(tool, mult)
    if tool.life then tool.life = tool.life * mult end
    if tool.freeze then tool.freeze = tool.freeze * mult end

    local drop = tool.drop
    if drop then
        if drop.freeze then drop.freeze = drop.freeze * mult end
        if drop.life then drop.life = drop.life * mult end
    end
end

function Loadout:rebuild(vw, vh)
    local screen = { w = vw, h = vh }

    self.stats = Upgrades.baseStats()

    self.tools = {}
    for i, tool in ipairs(Tools.list) do
        self.tools[i] = Tools.copy(tool)
    end

    for _, up in ipairs(Upgrades.list) do
        local level = self.taken[up.id]
        local target = self.stats
        if up.tool then target = toolNamed(self.tools, up.tool) end

        if level and target then
            for l = 1, level do
                up.levels[l].apply(target, screen)
            end
        end
    end

    -- The three multipliers that apply to every tool at once, landing after
    -- every tool's own upgrades rather than before them.
    local mult = self.stats.toolDamage * self.stats.damage
    for _, tool in ipairs(self.tools) do
        scaleDamage(tool, mult)
        scaleCost(tool, self.stats.inkCost)
        scalePersistence(tool, self.stats.markLife)
    end

    self:syncWeapons()
end

-- A weapon whose block has appeared is built once and reconfigured forever
-- after. Nothing here ever takes one away: no upgrade has taken anything away
-- yet, and if one ever does, this is where it would go.
function Loadout:syncWeapons()
    self.weapons = {}

    for _, spec in ipairs(WEAPONS) do
        local block = self.stats[spec.stat]
        if block then
            local weapon = self.live[spec.stat]
            if not weapon then
                weapon = spec.module.new()
                self.live[spec.stat] = weapon
            end
            weapon:configure(block)
            self.weapons[#self.weapons + 1] = weapon
        end
    end
end

-- The run's version of a row in Tools.list. Every part of the game that reads a
-- tool's numbers mid-run goes through here rather than through Tools.get, which
-- is what makes an upgrade to a tool land on the thing the tool leaves behind
-- without any of those places knowing upgrades exist.
function Loadout:tool(index)
    return self.tools[index]
end

--- the draft -----------------------------------------------------------------

-- Every line with a level left in it. A tool line whose tool has been shelved
-- is not one of them: taking a row out of Tools.list takes its upgrades out of
-- the draft with it, the same way it takes it off the selector.
function Loadout:candidates()
    local out = {}

    for _, up in ipairs(Upgrades.list) do
        local left = self:levelOf(up.id) < #up.levels
        if left and (not up.tool or toolNamed(self.tools, up.tool)) then
            out[#out + 1] = up
        end
    end

    return out
end

-- Up to n distinct lines, weighted. Fewer than n only when the run has nearly
-- learned everything, and none at all when it has.
function Loadout:roll(n)
    local pool = self:candidates()
    local offer = {}

    while #offer < n and #pool > 0 do
        local total = 0
        for _, up in ipairs(pool) do total = total + (up.weight or 1) end

        local r = love.math.random() * total
        for i, up in ipairs(pool) do
            r = r - (up.weight or 1)
            if r <= 0 then
                offer[#offer + 1] = up
                table.remove(pool, i)
                break
            end
        end
    end

    return offer
end

-- Takes the next level of a line and rebuilds everything off it. Returns the
-- line, for whoever wants to say what was just taken.
function Loadout:take(id, game)
    local level = self:levelOf(id) + 1
    self.taken[id] = level
    if level == 1 then self.order[#self.order + 1] = id end

    self:rebuild(game.vw, game.vh)
    return Upgrades.byId[id]
end

--- the weapons ---------------------------------------------------------------

function Loadout:updateWeapons(dt, game, grid)
    for _, weapon in ipairs(self.weapons) do
        weapon:update(dt, game, grid)
    end
end

function Loadout:drawWeapons(game)
    for _, weapon in ipairs(self.weapons) do
        weapon:draw(game)
    end
end

return Loadout
