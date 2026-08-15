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
local Sun = require("src.sun")

local Loadout = {}
Loadout.__index = Loadout

-- Passive weapons: the stat block an upgrade line puts on the run, and the
-- module that flies it. The block turning up is what brings the weapon in.
local WEAPONS = {
    { stat = "star", module = Orbital },
    { stat = "rocket", module = Rocket },
    { stat = "sun", module = Sun },
}

function Loadout.new(vw, vh)
    local self = setmetatable({
        taken = {},      -- id -> level reached
        order = {},      -- ids, in the order they were first taken
        stats = {},
        tools = {},
        equipped = {},   -- the tools unlocked, in the order they were unlocked
        weapons = {},
        live = {},       -- stat name -> the weapon flying it, kept across rebuilds
    }, Loadout)

    -- What a run is handed before it has been asked anything. A run does not
    -- start holding the strip -- it starts holding a pencil, and the other two
    -- slots are empty until the draft fills them. The starting tool is marked in
    -- the catalogue rather than named here, so which tool it is stays a decision
    -- of src/upgrades.lua like every other decision about a line.
    for _, up in ipairs(Upgrades.list) do
        if up.start then
            self.taken[up.id] = 1
            self.order[#self.order + 1] = up.id
        end
    end

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
    -- The highlighter's burn, the rubber's ram, the pencil's loop and the
    -- gluestick's tear are damage like any other, so the scissors reach them.
    -- Safe to write into: the upgrade levels build these fresh on the run's
    -- copy every rebuild, so nothing shared is ever scaled twice.
    if tool.ignite then tool.ignite.damage = tool.ignite.damage * mult end
    if tool.ram then tool.ram.damage = tool.ram.damage * mult end
    if tool.loop then tool.loop.damage = tool.loop.damage * mult end
    if tool.tear then tool.tear = tool.tear * mult end
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block and block.damage then
            block.damage = block.damage * mult
        end
        -- The pushpin's drive is damage too; its `point` is a multiplier on
        -- damage already scaled here, so it is left alone the way crit.mult is.
        if block and block.drive then
            block.drive = block.drive * mult
        end
    end
end

-- The elastic band, and knock sits in exactly the places damage sits, so this is
-- the same walk. Multiplying rather than adding is load-bearing: the pen, the
-- highlighter and the gluestick are written with a knock of 0 because not
-- shoving is what they are, and a multiplier leaves all three at 0. It also
-- keeps `Stroke.touches` honest, since that asks whether the knock is above zero
-- to decide whether a stroke touches anything at all.
local function scaleKnock(tool, mult)
    if tool.knock then tool.knock = tool.knock * mult end
    for _, name in ipairs(Tools.BLOCKS) do
        local block = tool[name]
        if block and block.knock then
            block.knock = block.knock * mult
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
--
-- The compass's `sweep.turn` is left alone for a stronger reason than that, and
-- anyone adding a duration here should know it: the leg cuts what it passes over
-- as it arrives, so a slower turn gives the far side of the circle *longer to
-- walk out*. It is the one length of time in the game where more is worse, and a
-- blanket "things last longer" that reached it would quietly make the compass
-- worse every time the card was taken.
--
-- The highlighter's `ignite.time` is also left alone, for the freeze's reason
-- inverted: a longer freeze holds for longer, but a longer burn just deals
-- more -- it is a hit still landing, not a hold -- and damage bought through
-- the persistence line is the scissors' job wearing the fixative's card.
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
        scaleKnock(tool, self.stats.knock)
        scaleCost(tool, self.stats.inkCost)
        scalePersistence(tool, self.stats.markLife)
    end

    self:syncWeapons()
    self:syncEquipped()
end

-- The tools this run has unlocked, in the order it unlocked them.
--
-- A tool line's first level is the unlock and has nothing to apply, so having
-- taken any level of it at all *is* what equips the tool -- there is no separate
-- flag to keep in step with the levels. Order is the order lines were first
-- taken, which makes this list append-only: a tool unlocked mid-run lands on the
-- end and never moves anything already in it, so the index the player is holding
-- goes on meaning the tool they were holding.
--
-- A line whose tool has been shelved contributes nothing, exactly as it is never
-- offered in the first place.
function Loadout:syncEquipped()
    self.equipped = {}

    for _, id in ipairs(self.order) do
        local up = Upgrades.byId[id]
        if up.kind == "tool" then
            local tool = toolNamed(self.tools, up.tool)
            if tool then
                self.equipped[#self.equipped + 1] = {
                    tool = tool, up = up, level = self:levelOf(id),
                }
            end
        end
    end
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
--
-- The index is a slot on the strip -- 1, 2 or 3 -- and not a row of Tools.list.
-- Which tool is in which slot is a fact about this run, so it is a fact this
-- object owns; nothing outside it should be indexing Tools.list to find out what
-- the player is holding.
function Loadout:tool(index)
    local slot = self.equipped[index]
    return slot and slot.tool
end

--- the draft -----------------------------------------------------------------

-- How many *lines* of each kind one run can carry. A kind missing from here is
-- uncapped; nothing is, at the moment.
--
-- The cap is on how many lines a run may *start*, not on how many levels it may
-- take. That is the whole mechanic: once the slots are full the lines a run has
-- never touched stop being offered, and the ones it has carry on coming up until
-- they are finished. A run stops collecting and starts committing.
--
-- Three tools is the tightest of the three caps by a distance, because a tool
-- line's first level hands you the tool itself: the strip is drafted, not
-- issued. One of the three is gone before the run starts -- the pencil is marked
-- `start` in the catalogue and is taken as the run is built -- so what the draft
-- is really offering is the other two. Nine tools you can all reach would be
-- nine tools none of which you had to choose between.
Loadout.SLOTS = { weapon = 5, passive = 5, tool = 3 }

-- What the run has started, by kind. A line occupies its slot from the moment
-- its first level is taken and never gives it back -- `order` is exactly the
-- list of lines that have been started, which is why it is what gets counted.
function Loadout:slotsUsed()
    local used = {}
    for _, id in ipairs(self.order) do
        local kind = Upgrades.byId[id].kind
        used[kind] = (used[kind] or 0) + 1
    end
    return used
end

-- Used and total for one kind, for anything that wants to say so out loud.
-- `cap` is nil for a kind that has no limit.
function Loadout:slots(kind)
    return self:slotsUsed()[kind] or 0, Loadout.SLOTS[kind]
end

-- Every line the draft is allowed to offer: one with a level left in it, whose
-- tool is still on the strip if it names one, and which the run either has room
-- to start or has already started.
--
-- That last clause is the one that matters. A line already under way is always
-- offered, however full the slots are -- otherwise filling the last slot could
-- strand a line on level one with no way to finish it, and the cap would be
-- punishing a run for the order it happened to be offered things in rather than
-- for what it chose.
function Loadout:candidates()
    local out = {}
    local used = self:slotsUsed()

    for _, up in ipairs(Upgrades.list) do
        local level = self:levelOf(up.id)
        local left = level < #up.levels
        local cap = Loadout.SLOTS[up.kind]
        local room = level > 0 or cap == nil or (used[up.kind] or 0) < cap

        if left and room and (not up.tool or toolNamed(self.tools, up.tool)) then
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

-- The dev toggle's two halves, reached from the pause screen and from nowhere
-- else: every tool line at its top level at once, for playtesting a tool as it
-- plays fully upgraded without drafting a run all the way to it.
--
-- Granting maxes every tool line that has a level left -- ones the run never
-- started and ones it was part-way through alike -- straight past the
-- three-slot cap; the counters on the held screens go red rather than lie
-- about it. `devTools` remembers the level each line really stood at, so
-- handing the tools back restores exactly that and nothing the run earned is
-- touched. A maxed line has no level left, so the draft cannot invest in one
-- while the toggle is on -- which is what keeps the restore honest.
function Loadout:grantAllTools(vw, vh)
    self.devTools = {}

    for _, up in ipairs(Upgrades.list) do
        if up.kind == "tool" and self:levelOf(up.id) < #up.levels then
            self.devTools[up.id] = self:levelOf(up.id)
            self.taken[up.id] = #up.levels
            if self.devTools[up.id] == 0 then
                self.order[#self.order + 1] = up.id
            end
        end
    end

    self:rebuild(vw, vh)
end

-- Every granted line drops back to the level the run had really reached; one
-- it had never started leaves the strip entirely. The replay in rebuild makes
-- restoring as safe as granting was, since nothing has to be undone, only not
-- replayed.
function Loadout:revokeDevTools(vw, vh)
    for id, level in pairs(self.devTools) do
        if level == 0 then
            self.taken[id] = nil
            for i = #self.order, 1, -1 do
                if self.order[i] == id then
                    table.remove(self.order, i)
                    break
                end
            end
        else
            self.taken[id] = level
        end
    end

    self.devTools = nil
    self:rebuild(vw, vh)
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
