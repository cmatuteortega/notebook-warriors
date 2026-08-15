local Palette = require("src.palette")
local Sprites = require("src.sprites")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Camera = require("src.camera")
local Player = require("src.player")
local Enemy = require("src.enemy")
local Bullet = require("src.bullet")
local Gem = require("src.gem")
local Pickup = require("src.pickup")
local Particles = require("src.particles")
local Spawner = require("src.spawner")
local Hud = require("src.hud")
local Menu = require("src.menu")
local Studio = require("src.studio")
local Pause = require("src.pause")
local LevelUp = require("src.levelup")
local Loadout = require("src.loadout")
local Design = require("src.design")
local Input = require("src.input")
local Tools = require("src.tools")
local Stroke = require("src.stroke")
local Ruler = require("src.ruler")
local Compass = require("src.compass")
local Walls = require("src.walls")
local util = require("src.util")

local Game = {}

-- The canvas is sized to whatever screen the game ended up on, so these are
-- only defaults: main.lua sets both before the first frame and again on every
-- resize or rotation.
Game.vw, Game.vh = 320, 180
Game.inset = { l = 0, t = 0, r = 0, b = 0 }

local GRID_CELL = 12   -- spatial hash cell, a bit wider than the biggest enemy
local DESPAWN_DIST = 420
local SEPARATION = 0.35 -- how hard overlapping enemies shove each other apart
local RESTART_DELAY = 0.7 -- before a tap counts as "restart", so the press that
                          -- happened to be down when you died doesn't skip it
local SPENT_PAD = 20      -- how far off screen a spent mark is still drawn
local DRAFT_SIZE = 3      -- upgrades offered per level
local NOTICE_TIME = 1.8   -- how long the run says what you just took

local function cellKey(cx, cy)
    return cx * 100000 + cy
end

function Game:load(vw, vh)
    self:resize(vw, vh)

    Sprites.load()
    Font.load()
    Background.load()
    Overprint.load()

    -- Whatever was drawn last time, or what you are handed to draw over if this
    -- is the first time.
    Design.loadAll()

    -- Both outlive any one run: they are things on top of the game rather than
    -- part of the run they happen to be holding.
    self.pause = Pause.new()
    self.draft = LevelUp.new()

    -- A press that lands on the tool selector switches tools instead of
    -- starting a stroke.
    Input.onPointerDown = function(cx, cy)
        -- The title screen is drawn on, not pressed: every pointer that lands
        -- on it is a pen, wherever it lands.
        if self.state == "menu" then return false end

        -- The studio is drawn on too, apart from the two tool buttons beside
        -- the board, which have to be pressable mid-stroke.
        if self.state == "studio" then return Studio:pointerDown(cx, cy) end

        -- Dead, and on a phone there is no R key to press. Anywhere on the
        -- page starts the next run.
        if self.state == "dead" then
            if self.deadFor >= RESTART_DELAY then self:reset() end
            return true
        end

        -- Levelling up: the whole page belongs to the three cards, and the only
        -- way out of it is to circle one. Nothing else on the screen is
        -- pressable, the button in the corner included -- every press draws.
        if self.state == "levelup" then return false end

        -- The button holds the run and lets it go again, so it is checked in
        -- both states before anything else can claim the press.
        if Hud.pauseAt(self, cx, cy) then
            self:togglePause()
            return true
        end

        -- Held: the pause screen is a page like any other and every press on it
        -- draws. Nothing reaches the run underneath, since the pen is only run
        -- while the game is playing.
        if self.state == "paused" then return false end

        local index = Hud.selectorAt(self, cx, cy)
        if index then
            self:setTool(index)
            return true
        end
        return false
    end

    self:reset()
    self:toMenu()
end

-- The title screen owns the same page the run does, so it is a state of the
-- game rather than a screen in front of it. A run is built and waiting behind
-- it either way, which is what lets YES start one on the frame it is answered.
function Game:toMenu()
    self.state = "menu"
    Menu:enter()

    -- Whatever was being held when the run was closed does not carry over: a
    -- finger still down from the scribble that quit would otherwise skip the
    -- title's intro the instant it appeared.
    Input.releaseAll()
end

-- The drawing board, which the game goes to twice. Between the title screen and
-- the run it is the player character: the run behind it is not built until the
-- board is handed over, so the hero it starts with is the one that was just
-- drawn. Mid-run it is a weapon the draft has just given you, and the run stays
-- held underneath exactly as the draft left it.
--
-- `back` is what to do when the board is handed over -- "run" to start the run
-- waiting behind it, "held" to let the held one go again.
function Game:toStudio(design, back)
    self.state = "studio"
    self.studioBack = back
    Studio:enter(design)

    -- The pen that answered the screen before -- the title's YES, the draft's
    -- loop -- is not the first stroke of the drawing.
    Input.releaseAll()
end

-- The window changed shape: a desktop drag, or a phone rotating. The canvas is
-- a different number of game pixels now, so the camera shows a different slice
-- of the page and the HUD re-anchors to the new edges.
function Game:resize(vw, vh)
    self.vw, self.vh = vw, vh
    Camera.setViewport(vw, vh)
    Overprint.resize(vw, vh)

    -- One upgrade is measured off the page you can see rather than written
    -- down -- the ruler that reaches corner to corner -- so a run that is
    -- already holding it has that number worked out again at the new shape.
    if self.loadout then self.loadout:rebuild(vw, vh) end
end

function Game:setSafeInsets(l, t, r, b)
    self.inset = { l = l, t = t, r = r, b = b }
end

function Game:reset()
    -- Everything the run has learned, and the only thing the player is built
    -- from: speed, health, how hard anything hits and what fights alongside it
    -- all come off this, so it exists before the player does.
    self.loadout = Loadout.new(self.vw, self.vh)

    self.player = Player.new(0, 0, self.loadout)
    self.enemies = {}
    self.bullets = {}
    self.shots = {} -- enemy fire: the eye's pellets (Game:updateEnemyShots)
    self.gems = {}
    -- Hearts, ink and diamonds (src/pickup.lua): fixed spots baked into the
    -- page for this run, plus a scatter past the screen edge. The first
    -- scattered one lands half a clock in, so a fresh run has somewhere to go
    -- before the horde has given it a reason to.
    self.pickups = {}
    self.pickupTimer = Pickup.EVERY * 0.5
    self.pickupSeed = love.math.random(2 ^ 20)
    self.pickupTaken = {} -- fixed spots spent this run, by cell key
    self.strokes = {}
    self.stroke = nil
    -- Everything that was tapped onto the page rather than drawn on it: pins
    -- and staples, in the order they were put there. `drops` is the ones still
    -- holding something; `spent` is the ones that have finished and stay on the
    -- paper for good.
    self.drops = {}
    self.spent = {}
    self.rulers = {}
    self.ruler = nil
    self.compasses = {}
    self.compass = nil
    self.walls = Walls.new()
    self.wallsDirty = false
    self.hasSlick = false
    self.hasFire = false
    self.hasPull = false
    self.particles = Particles.new()
    self.spawner = Spawner.new()
    self.time = 0
    self.kills = 0
    self.state = "playing"
    self.deadFor = 0

    self.tool = 1
    self.toolLabel = 0
    self.notice, self.noticeT = nil, 0
    self.ink = self.loadout.stats.inkMax
    self.inkDelay = 0
    self.drawBlocked = false
    self.wasDown = false

    -- The menu takes the stick away, since there is nothing to walk on a title
    -- screen and the corner it lives in has to be drawable.
    Input.stickEnabled = true

    Camera.set(self.player.x, self.player.y)
end

-- Stopping the run, whatever stopped it: the pause button, or a level landing.
-- The run is held where it stands rather than torn down -- the page, the horde,
-- the ink you had left and the clock are all exactly as you left them when it
-- starts moving again.
--
-- A stroke can't be left open across the freeze, or the nib would pick up
-- wherever the pointer had wandered to in the meantime and rule a line across
-- the page on the way back to it. An aim can't either: it would come down along
-- whatever angle the pointer had drifted to while nothing was moving. Nor can a
-- compass, for the same reason and one more -- a needle left in the paper
-- across a freeze is ink the run has already paid for and can no longer see.
function Game:holdRun()
    self:endStroke()
    self:snapRuler()
    self:swingCompass()
    self.wasDown = false

    -- Nothing to walk while the run is held, and the stick's corner is page
    -- like any other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

function Game:releaseRun()
    Input.stickEnabled = true

    -- A pointer still down was drawing on the screen that held the run, not on
    -- the run, so the page stays shut to it until it comes off and presses
    -- again.
    self.wasDown = Input.pointerDown
    self.drawBlocked = Input.pointerDown
end

function Game:togglePause()
    if self.state == "playing" then
        self.state = "paused"
        self.pause:open()
        self:holdRun()
    elseif self.state == "paused" then
        self.state = "playing"
        self:releaseRun()
    end
end

--- levelling up --------------------------------------------------------------

-- A level was reached, so the run stops and asks what to do with it. Returns
-- false when there is nothing left to offer, which is the caller's cue that the
-- run simply carries on: the levels still land, they just stop costing the run
-- its momentum once it has finished everything it has room to carry. Which comes
-- a good deal sooner than it used to, now that a run may only start so many
-- lines (`Loadout.SLOTS`) -- a long one runs out of things to be asked about
-- while the horde is still arriving, and that is the intended end state rather
-- than a corner case.
function Game:openDraft()
    local offer = self.loadout:roll(DRAFT_SIZE)
    if #offer == 0 then
        self.player.pending = 0
        return false
    end

    self.state = "levelup"
    self:holdRun()
    self.draft:open(self, offer)
    return true
end

-- The card that was circled. Everything the run knows is rebuilt off the new
-- level before the player is told to catch up with it.
function Game:takeUpgrade(id)
    local was = self.loadout.stats.inkMax

    local up = self.loadout:take(id, self)
    self.player:applyStats()
    self.player.pending = self.player.pending - 1

    -- A bigger well arrives with the new room already in it, exactly as a fresh
    -- page arrives with the health already in it and for the same reason: a
    -- meter you have to go and stand still to fill is not a reward. Nothing is
    -- topped up when the well has not grown, so this cannot quietly refill the
    -- ink a run spent right before it levelled.
    local grew = self.loadout.stats.inkMax - was
    if grew > 0 then
        self.ink = math.min(self.loadout.stats.inkMax, self.ink + grew)
    end

    self.notice, self.noticeT = up.name, NOTICE_TIME

    -- A weapon you draw rather than one you are handed: the first level of the
    -- line sends you to the board before the run starts moving again. Only the
    -- first, because the levels after it change what the thing does and not what
    -- it looks like -- and the run is already held, so the board simply carries
    -- on holding it.
    if up.design and self.loadout:levelOf(id) == 1 then
        self:toStudio(Design.by[up.design], "held")
        return
    end

    self:resumeRun()
end

-- Back to the run that the draft, and the board after it, were holding. The next
-- banked level -- a big pickup can carry two -- opens its own draft rather than
-- being swallowed by the one just spent.
function Game:resumeRun()
    if self.player.pending > 0 and self:openDraft() then return end

    self.state = "playing"
    self:releaseRun()
end

-- The index is a slot on the strip, so it wraps around what this run has
-- actually unlocked rather than around the catalogue: a run holding two tools
-- cycles between two, and the wrap is what makes the scroll wheel and Q/E work
-- without any of them knowing how many that is.
function Game:setTool(index)
    local n = #self.loadout.equipped
    if n == 0 then return end

    index = (index - 1) % n + 1
    if index ~= self.tool then
        self:endStroke()
        self:snapRuler()
        self:swingCompass()
        self.tool = index
        self.toolLabel = 1.4
    end
end

-- The dev toggle, for playtesting: every tool at once, granted and taken back
-- from the pause screen (T). The run is already held when this can fire, so no
-- stroke or aim is open to be orphaned by the strip changing under it -- but
-- handing the tools back can shrink the strip, so the slot in hand is clamped
-- back onto what is left. The pencil is always there to be clamped to.
function Game:toggleAllTools()
    if self.loadout.devTools then
        self.loadout:revokeDevTools(self.vw, self.vh)
        self.tool = math.min(self.tool, #self.loadout.equipped)
    else
        self.loadout:grantAllTools(self.vw, self.vh)
    end
end

--- spawning -----------------------------------------------------------------

function Game:spawnEnemy(kind, x, y)
    self.enemies[#self.enemies + 1] = Enemy.new(kind, x, y)
end

function Game:spawnBullet(x, y, dx, dy, damage)
    self.bullets[#self.bullets + 1] = Bullet.new(x, y, dx, dy, damage)
end

--- update -------------------------------------------------------------------

-- Rebuilt every frame. With a few hundred enemies this is far cheaper than the
-- n^2 pass it replaces, and both separation and bullet hits query it.
function Game:buildGrid()
    local grid = {}
    for _, e in ipairs(self.enemies) do
        local k = cellKey(math.floor(e.x / GRID_CELL), math.floor(e.y / GRID_CELL))
        local bucket = grid[k]
        if not bucket then
            bucket = {}
            grid[k] = bucket
        end
        bucket[#bucket + 1] = e
    end
    return grid
end

local function eachNeighbour(grid, x, y, fn)
    local cx, cy = math.floor(x / GRID_CELL), math.floor(y / GRID_CELL)
    for oy = -1, 1 do
        for ox = -1, 1 do
            local bucket = grid[cellKey(cx + ox, cy + oy)]
            if bucket then
                for i = 1, #bucket do
                    if fn(bucket[i]) then return end
                end
            end
        end
    end
end

-- The same nine cells, for anything outside this file that hits something small
-- at a point: a star on its orbit (src/orbital.lua) and a rocket in the air
-- (src/rocket.lua) reach no further than a bullet does, so they ask the same
-- question of the same index rather than walking the whole horde every frame.
function Game:eachNear(grid, x, y, fn)
    eachNeighbour(grid, x, y, fn)
end

-- The nearest enemy within `range` of a point, or nil. This one *is* the whole
-- horde rather than the nine cells around it: everything that aims itself picks
-- a target far further off than a cell is wide, and it does so a couple of times
-- a second rather than every frame -- the auto-shot (src/player.lua) and the
-- rockets both hold their shot and look again shortly when there is nothing out
-- there, which is what makes walking into a fresh crowd answered at once.
function Game:nearestEnemy(x, y, range)
    local best, bestDist

    for _, e in ipairs(self.enemies) do
        local d = util.len(e.x - x, e.y - y)
        if d <= range and (not bestDist or d < bestDist) then
            best, bestDist = e, d
        end
    end

    return best
end

-- Everything inside a circle, for a weapon that covers ground rather than
-- touching a point. The sun (src/sun.lua) burns a quarter of the page at a time
-- and shoots rays most of the way across it, both of which are far wider than
-- the nine cells `eachNear` looks in -- so it asks this instead, on a tick a
-- couple of times a second rather than every frame, the same bargain
-- `nearestEnemy` makes.
--
-- Walked backwards because `fn` is entitled to kill what it was handed: a
-- table.remove behind the walk would step over the next one along. Returning
-- true from `fn` stops the walk, exactly as it does from `eachNear`.
function Game:eachWithin(x, y, r, fn)
    local r2 = r * r

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        local dx, dy = e.x - x, e.y - y
        if dx * dx + dy * dy <= r2 and fn(e) then return end
    end
end

function Game:updateEnemies(dt, grid)
    local player = self.player

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        e:update(dt, player, self.walls, self.hasSlick and self:slickAt(e.x, e.y) or nil)

        -- Keep the horde from stacking into a single pixel. Glued enemies are
        -- immovable, so the crowd jams up against them instead of squeezing
        -- them out of the smear.
        if e.frozen <= 0 then
            eachNeighbour(grid, e.x, e.y, function(other)
                if other == e then return end
                local dx, dy = e.x - other.x, e.y - other.y
                local d2 = dx * dx + dy * dy
                local min = e.radius + other.radius
                if d2 > 0 and d2 < min * min then
                    local d = math.sqrt(d2)
                    local push = (min - d) * SEPARATION
                    e.x = e.x + (dx / d) * push
                    e.y = e.y + (dy / d) * push
                end
            end)
        end

        -- Last word on where it ended up: whatever the chase and the crowd did,
        -- it does not get to be standing inside a pen line.
        if self.walls.count > 0 then
            e:resolveWalls(self.walls)
        end

        -- Contact damage, rate-limited per enemy.
        local dist = util.len(player.x - e.x, player.y - e.y)
        if dist < e.radius + player.radius and e.hitCooldown <= 0 then
            if player:hurt(e.def.damage) then
                e.hitCooldown = 0.6
                self.particles:burst(player.x, player.y, 6, Palette.red)
            end
        end

        -- Shooters fire on their own beat, seeded at spawn. The clock keeps
        -- running while the player is out of range and the beat just passes
        -- unspent -- if it only ran in range, stepping into view of a crowd of
        -- eyes would be answered with an instant volley from all of them.
        local shot = e.def.shot
        if shot and e.frozen <= 0 then
            e.shotT = e.shotT - dt
            if e.shotT <= 0 then
                e.shotT = shot.every
                if dist < shot.range then
                    local nx, ny = util.normalize(player.x - e.x, player.y - e.y)
                    self.shots[#self.shots + 1] = {
                        x = e.x, y = e.y, dx = nx, dy = ny,
                        speed = shot.speed, damage = shot.damage, life = 3,
                    }
                end
            end
        end

        if dist > DESPAWN_DIST then
            table.remove(self.enemies, i)
        end
    end
end

-- What counts as still flying, for a launched enemy: below this push speed it
-- is just being shoved like anything else and stops being a projectile. From
-- the rubber's upgraded 240 the decay gives it a fifth of a second and about
-- twenty pixels of bowling before it drops under, so a ram is something that
-- happens *into* a crowd standing right behind the one you hit.
local RAM_SPEED = 55

-- The rubber's last level: enemies its shove sent flying knock down what they
-- land on. A separate pass after the crowd has moved rather than a clause
-- inside updateEnemies, because a victim can die here, and pulling one out of
-- the list mid-walk would hand the walk a neighbour it had already updated.
-- Each launch carries its own hit list, so one flight hits one victim once;
-- the shove passed on is a share of the speed left at impact, so the elastic
-- band reaches this level through the launch without being asked. The victim
-- is shoved but never marked launched itself -- one rub buys one volley of
-- pins, not a chain reaction.
function Game:updateRams(grid)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if e.ram then
            local speed = util.len(e.pushX, e.pushY)
            if speed < RAM_SPEED then
                e.ram = nil
            else
                local nx, ny = e.pushX / speed, e.pushY / speed
                eachNeighbour(grid, e.x, e.y, function(other)
                    if other ~= e and not e.ram.hit[other] then
                        local dx, dy = other.x - e.x, other.y - e.y
                        local min = e.radius + other.radius
                        if dx * dx + dy * dy < min * min then
                            e.ram.hit[other] = true
                            other:knockback(nx, ny, speed * 0.8)
                            self.particles:burst(other.x, other.y, 3, Palette.red)
                            -- By identity: the victim came off the grid, which
                            -- may already be a frame out of date.
                            if other:hurt(e.ram.damage) then
                                self:killEnemyAt(other)
                            end
                        end
                    end
                end)
            end
        end
    end
end

function Game:killEnemy(index)
    local e = self.enemies[index]
    self.kills = self.kills + 1
    self.particles:burst(e.x, e.y, 7, Palette.slate)
    self.gems[#self.gems + 1] = Gem.new(e.x, e.y, e.def.xp)
    table.remove(self.enemies, index)
end

-- By identity rather than by index, for anything that found what it hit through
-- the spatial hash and so never had one -- a bullet, a star on its orbit. A
-- miss is not a problem: two things can land on the same enemy in the same
-- frame, and the second only finds it already gone.
function Game:killEnemyAt(enemy)
    for i = #self.enemies, 1, -1 do
        if self.enemies[i] == enemy then
            self:killEnemy(i)
            return
        end
    end
end

function Game:updateBullets(dt, grid)
    for i = #self.bullets, 1, -1 do
        local b = self.bullets[i]
        b:update(dt)

        if not b.dead then
            local hit
            eachNeighbour(grid, b.x, b.y, function(e)
                local dx, dy = e.x - b.x, e.y - b.y
                local min = e.radius + b.radius
                if dx * dx + dy * dy < min * min then
                    hit = e
                    return true
                end
            end)

            if hit then
                b.dead = true
                self.particles:burst(b.x, b.y, 3, Palette.red)
                if hit:hurt(b.damage) then
                    self:killEnemyAt(hit)
                end
            end
        end

        if b.dead then table.remove(self.bullets, i) end
    end
end

-- The eye's pellets. Not a Bullet: a bullet asks the enemy grid what it hit,
-- and these only ever care about one point -- the player. Like a bullet, a
-- pellet is in the air rather than on the page, so pen walls don't stop it;
-- a shooter is the one pressure a wall can't hold off.
function Game:updateEnemyShots(dt)
    local player = self.player
    for i = #self.shots, 1, -1 do
        local s = self.shots[i]
        s.x = s.x + s.dx * s.speed * dt
        s.y = s.y + s.dy * s.speed * dt
        s.life = s.life - dt

        if util.len(player.x - s.x, player.y - s.y) < player.radius + 3 then
            s.life = 0
            if player:hurt(s.damage) then
                self.particles:burst(player.x, player.y, 6, Palette.red)
            end
        end

        if s.life <= 0 then table.remove(self.shots, i) end
    end
end

function Game:updateGems(dt)
    local magnet = self.loadout.stats.magnet
    for i = #self.gems, 1, -1 do
        local g = self.gems[i]
        g:update(dt, self.player, magnet)
        if g.dead then table.remove(self.gems, i) end
    end
end

-- The scatter clock keeps ticking while the page is at its cap, so a full page
-- does not queue up a volley of pickups against the moment one is taken -- the
-- next lands a beat after that, the same as always. Only scattered pickups
-- count against the cap: the fixed ones are the page's, and walking into a
-- rich patch of it must not switch the scatter off.
function Game:updatePickups(dt)
    Pickup.materialize(self)

    self.pickupTimer = self.pickupTimer - dt
    if self.pickupTimer <= 0 then
        self.pickupTimer = Pickup.EVERY

        local scattered = 0
        for _, p in ipairs(self.pickups) do
            if not p.cell then scattered = scattered + 1 end
        end
        if scattered < Pickup.MAX then
            -- Nil when every roll landed on something already out there; the
            -- clock simply tries again on its next beat.
            self.pickups[#self.pickups + 1] = Pickup.scatter(self)
        end
    end

    for i = #self.pickups, 1, -1 do
        local p = self.pickups[i]
        p:update(dt, self)
        if p.dead then table.remove(self.pickups, i) end
    end
end

-- The slippery surface underfoot, if any. Guarded by hasSlick at every call
-- site, so a page with no wax on it costs nothing.
function Game:slickAt(x, y)
    for _, s in ipairs(self.strokes) do
        if s.tool.slick and s:covers(x, y) then
            return s.tool.slick
        end
    end
end

-- The burning band under (x, y), if any: the slick lookup's twin, guarded by
-- hasFire at the call site for the same reason.
function Game:fireAt(x, y)
    for _, s in ipairs(self.strokes) do
        if s.tool.ignite and s:covers(x, y) then
            return s.tool.ignite
        end
    end
end

-- Fire, from the highlighter's last level. Ignition is checked every frame
-- rather than on the linger tick, because "crossed it" is the point of the
-- upgrade: a bat is over a 13px band in less time than a tick, and the tick
-- would let it through dry. The burn then travels with the enemy and keeps
-- ticking after the band itself has faded -- which is why the walk itself
-- cannot hide behind hasFire the way ignition can; a burn may outlive every
-- mark on the page. What it costs a page with no fire on it is one comparison
-- per enemy.
--
-- Runs before the grid is built, so anything the fire finishes off never
-- enters it and nothing downstream can find a dead enemy through it.
function Game:updateBurning(dt)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if self.hasFire then
            local burn = self:fireAt(e.x, e.y)
            if burn then e:ignite(burn) end
        end

        if e.burnT > 0 then
            e.burnT = e.burnT - dt
            e.burnTick = e.burnTick - dt
            -- Embers stream off the whole time it burns; the damage lands in
            -- pulses, and each pulse throws a couple more.
            if love.math.random() < dt * 10 then
                self.particles:flame(e.x, e.y)
            end
            if e.burnTick <= 0 then
                e.burnTick = e.burn.tick
                self.particles:flame(e.x, e.y)
                self.particles:flame(e.x, e.y)
                if e:hurt(e.burn.damage) then
                    self:killEnemy(i)
                end
            end
        end
    end
end

-- Glue, from the gluestick's upper levels. Two things happen to an enemy here
-- and both are about the hold rather than the smear. The tear lands the frame
-- the hold ends: coming loose is what the glue charges for, so it fires
-- exactly once however long the enemy sat there -- and while a live smear
-- keeps re-freezing whatever stands on it, nothing standing on one ever comes
-- loose until the smear itself has faded. The pull drags whatever is still
-- free towards the nearest ink, and its speed is the design: between a
-- skull's legs and a bat's, so the heavy things cannot walk out of the field,
-- the fast things can, and the smear sorts the crowd it was thrown into.
--
-- Runs before the grid is built, for updateBurning's reason: anything the
-- tear finishes off never enters it. What it costs a page with no glue on it
-- is one comparison per enemy.
function Game:updateGlue(dt)
    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if e.frozen <= 0 then
            local died = false
            if e.glue then
                local tear = e.glue.tear
                e.glue = nil
                if tear then
                    self.particles:burst(e.x, e.y, 3, Palette.red)
                    died = e:hurt(tear)
                    if died then self:killEnemy(i) end
                end
            end
            if self.hasPull and not died then
                for _, s in ipairs(self.strokes) do
                    local pull = s.tool.pull
                    if pull then
                        local nx, ny = s:pullTowards(e.x, e.y, pull.range)
                        if nx then
                            e.x = e.x + nx * pull.speed * dt
                            e.y = e.y + ny * pull.speed * dt
                        end
                    end
                end
            end
        end
    end
end

function Game:endStroke()
    if self.stroke then
        self.stroke:finish()
        self.stroke = nil
    end
end

-- Every way of spending ink goes through here, because all four of them do the
-- same two things: take it out of the meter, and stop the meter refilling for a
-- moment. The pause is what makes the meter a resource rather than a trickle --
-- it is the difference between drawing and having drawn -- and the cartridge
-- upgrade shortens it, so it is read off the run rather than written down.
--
-- What the tool charges is not scaled here. That already happened, once, when
-- the run's copy of the tool was built (src/loadout.lua): the blotter discounts
-- the row, and everything downstream simply pays what the row says.
function Game:spendInk(cost)
    self.ink = math.max(0, self.ink - cost)
    self.inkDelay = Tools.DELAY * self.loadout.stats.inkDelay
end

-- A tap rather than a stroke, so the whole price is paid up front -- before the
-- thing has landed, and whether or not it lands on anything. What turns up is
-- the tool's business, not this function's: the drop block names the module,
-- which is the only difference between a pushpin and a staple as far as the
-- input is concerned.
function Game:dropOne(tool, x, y)
    self:spendInk(tool.ink)

    local drop = tool.drop
    local d = drop.lands.new(drop, x, y)
    -- What this one cost, stamped on it for the pin level that gives a slice
    -- back on a full crater -- read off the tool now, while it is still the
    -- tool in hand: the strip may have moved on by the time it lands.
    d.price = tool.ink
    self.drops[#self.drops + 1] = d
end

-- A pin and a staple are the only two things in the game that are driven into
-- the paper rather than drawn on it, and they are the only two that do not come
-- off it. Every mark fades; these stay, and stay looking exactly as they did
-- going in. So when one finishes holding what it caught it is not thrown away --
-- it stops being updated at all and joins the page. A long run leaves a trail of
-- them behind it, which is a record of where the trouble was.
function Game:updateDrops(dt)
    for i = #self.drops, 1, -1 do
        local d = self.drops[i]
        if not d:update(dt, self) then
            table.remove(self.drops, i)
            self.spent[#self.spent + 1] = d
        end
    end
end

-- The spent marks in view. There is no limit on how many a run puts down and
-- none is wanted -- they are the page's memory of it -- so this is the one thing
-- that has to hold up: they are spread over far more paper than the camera can
-- show, and only the handful actually on screen is worth drawing.
--
-- That cull is what makes keeping them free. A run's worth is 0.16ms a frame
-- with it and would be several times that without, and the walk itself stays
-- under a third of a millisecond well past any length of run.
function Game:eachSpent(fn)
    local left, top, w, h = Camera.bounds()
    for i = 1, #self.spent do
        local d = self.spent[i]
        if d.x >= left - SPENT_PAD and d.x <= left + w + SPENT_PAD
            and d.y >= top - SPENT_PAD and d.y <= top + h + SPENT_PAD then
            fn(d)
        end
    end
end

-- Aiming starts on the press and is paid for there, so it is never free to
-- change your mind: a ruler that has been picked up always comes down.
function Game:beginRuler(tool, x, y)
    self:spendInk(tool.ink)

    self.ruler = Ruler.new(tool.snap, self.player.x, self.player.y)
    self.ruler:aimAt(x, y)
    self.rulers[#self.rulers + 1] = self.ruler
end

-- Lifting the pointer lands it, and so does anything else that takes the aim
-- away -- changing tool, or holding the run. The ink is already spent, so the
-- alternative would be pocketing it.
function Game:snapRuler()
    if self.ruler then
        self.ruler:strike(self)
        self.ruler = nil
    end
end

function Game:updateRulers(dt)
    for i = #self.rulers, 1, -1 do
        if not self.rulers[i]:update(dt, self) then
            table.remove(self.rulers, i)
        end
    end
end

-- The needle goes in on the press and the whole price goes in with it. From
-- here the circle is coming; the only thing left to decide is how wide, and the
-- drag out of the press is what decides it.
function Game:plantCompass(tool, x, y)
    self:spendInk(tool.ink)

    self.compass = Compass.new(tool.sweep, x, y)
    self.compasses[#self.compasses + 1] = self.compass
    self.particles:burst(x, y, 5, Palette.graphite) -- fibres off the puncture
end

-- Lifting the pointer swings it, and so does anything else that takes it away
-- -- a tool change, holding the run -- at whatever width it had got to. The
-- same bargain the ruler makes: the needle is already paid for, so the
-- alternative is pocketing the ink.
function Game:swingCompass()
    if self.compass then
        self.compass:swing()
        self.compass = nil
    end
end

function Game:updateCompasses(dt)
    for i = #self.compasses, 1, -1 do
        if not self.compasses[i]:update(dt, self) then
            table.remove(self.compasses, i)
        end
    end
end

-- The pointer is tracked in canvas space and converted to world space here,
-- every frame. That means holding the pointer still while you walk keeps
-- drawing: the page slides under the nib, exactly like dragging paper beneath
-- a pen.
function Game:updateDrawing(dt)
    -- The run's own copy of the tool rather than the row it was written down
    -- as: an upgrade may have made this ruler longer or this pencil sharper,
    -- and everything downstream of here -- the stroke, the drop, the ruler that
    -- comes down -- is handed the copy and never has to know.
    local tool = self.loadout:tool(self.tool)
    if not tool then return end

    local left, top = Camera.bounds()
    local down = Input.pointerDown

    if down and not self.wasDown then
        -- A brush wants enough in the meter to be worth starting a line with; a
        -- pin, a ruler or a compass wants exactly its own price, since there is
        -- no half of any of them.
        local flat = tool.drop or tool.snap or tool.sweep
        self.drawBlocked = self.ink < (flat and tool.ink or Tools.MIN_INK)
    end

    if down and not self.drawBlocked then
        local wx, wy = Input.pointerX + left, Input.pointerY + top

        if tool.sweep then
            -- One gesture: the press puts the needle in where it landed and the
            -- drag out of it opens the leg. The needle is set once and never
            -- follows the pointer afterwards, which is the whole difference from
            -- the ruler -- there the pivot is you and the drag only turns it,
            -- here the pivot is wherever you pressed and the drag only widens it.
            if not self.wasDown then
                self:plantCompass(tool, wx, wy)
            end
            -- Guarded, because the tool can be switched to this one with the
            -- pointer already down, and that press is not this tool's to take.
            if self.compass then
                self.compass:reachTo(wx, wy)
            end

        elseif tool.snap then
            if not self.wasDown then
                self:beginRuler(tool, wx, wy)
            end
            -- Guarded, because the tool can be switched to this one with the
            -- pointer already down, and that press is not this tool's to take.
            if self.ruler then
                self.ruler:follow(self.player.x, self.player.y)
                self.ruler:aimAt(wx, wy)
            end
        elseif tool.drop then
            -- One per press. Holding the pointer down does nothing more, and
            -- dragging it does not rake a line of them across the page: these
            -- tools are tapped, not drawn. That is what makes the stapler cost
            -- taps rather than ink -- ten of them is ten separate decisions,
            -- and a held finger is none.
            if not self.wasDown then
                self:dropOne(tool, wx, wy)
            end
        else
            if not self.stroke then
                self.stroke = Stroke.new(tool, wx, wy)
                self.strokes[#self.strokes + 1] = self.stroke
            end

            -- The pencil's flow level: a line that keeps going gets cheaper by
            -- the pixel, easing towards the floor as it lengthens -- and the
            -- discount dies with the stroke, so lifting the finger is what it
            -- costs. Priced per frame off how much line the stroke has already
            -- drawn; the discount moves slowly enough for that to be exact
            -- for all practical purposes.
            local rate = tool.ink
            if tool.flow then
                rate = rate * (tool.flow.floor + (1 - tool.flow.floor)
                    * math.exp(-self.stroke.drawn / tool.flow.over))
            end
            -- The rubber's re-rub level: ground this stroke has already been
            -- over is charged at a discount, which is most of what a rub is --
            -- back-and-forth over one patch -- while a rubber dragged off
            -- somewhere new pays full price the whole way there.
            if tool.scrub and self.stroke:revisits(self.stroke.x, self.stroke.y) then
                rate = rate * tool.scrub
            end

            local budget = self.ink / rate
            local used = self.stroke:extend(wx, wy, budget, self, dt)
            if used > 0 then
                self:spendInk(used * rate)
                -- The line just grew, so the fence it makes has to grow with it.
                self.wallsDirty = self.wallsDirty or tool.wall
            end
            if self.ink <= 0 then
                self:endStroke()
                self.drawBlocked = true
            end
        end
    elseif not down then
        self:endStroke()
        self:snapRuler()
        self:swingCompass()
        self.drawBlocked = false
    end

    self.wasDown = down

    -- The well refills at its own rate whatever size it is, so an inkwell taken
    -- to the end holds more than twice as much and takes more than twice as long
    -- to fill from empty. That is the trade the line makes, and the cartridge is
    -- the line that undoes it.
    local stats = self.loadout.stats
    if self.inkDelay > 0 then
        self.inkDelay = self.inkDelay - dt
    else
        self.ink = math.min(stats.inkMax,
            self.ink + Tools.REGEN * stats.inkRegen * dt)
    end

    self.hasSlick = false
    self.hasFire = false
    self.hasPull = false
    for i = #self.strokes, 1, -1 do
        local s = self.strokes[i]
        if not s:update(dt, self) then
            self.wallsDirty = self.wallsDirty or s.tool.wall
            table.remove(self.strokes, i)
        else
            if s.tool.slick then self.hasSlick = true end
            if s.tool.ignite then self.hasFire = true end
            if s.tool.pull then self.hasPull = true end
        end
    end

    -- Only ever while a wall is being drawn or has just faded off the page;
    -- the rest of the time the index sits still.
    if self.wallsDirty then
        self.walls:rebuild(self.strokes)
        self.wallsDirty = false
    end

    self.toolLabel = math.max(0, self.toolLabel - dt)
end

function Game:update(dt)
    if self.state == "menu" then
        local answer = Menu:update(dt, self)
        if answer == "yes" then
            self:toStudio(Design.by.hero, "run")
        elseif answer == "no" then
            love.event.quit()
        end
        return
    end

    if self.state == "studio" then
        if Studio:update(dt, self) == "done" then
            if self.studioBack == "run" then
                self:reset()
            else
                self:resumeRun()
            end
        end
        return
    end

    -- Nothing moves, nothing ages and no ink comes back; the only thing running
    -- is the card asking whether to quit.
    if self.state == "paused" then
        local answer = self.pause:update(dt, self)
        if answer == "quit" then
            self:toMenu()
        elseif answer == "resume" then
            self:togglePause()
        elseif answer == "dev" then
            -- The touch route to what T does on a keyboard. Thrown in place:
            -- the card is still up afterwards, with the strip behind it longer
            -- or shorter than it was.
            self:toggleAllTools()
        end
        return
    end

    -- Held the same way, by the three cards instead. There is no way past them
    -- but to circle one, which is why this state has no button out of it.
    if self.state == "levelup" then
        local picked = self.draft:update(dt, self)
        if picked then self:takeUpgrade(picked) end
        return
    end

    if self.state == "playing" then
        self.time = self.time + dt

        self.player:update(dt, self)
        self.spawner:update(dt, self)
        self:updateDrawing(dt)
        self:updateDrops(dt)
        self:updateRulers(dt)
        self:updateCompasses(dt)
        self:updateBurning(dt)
        self:updateGlue(dt)

        local grid = self:buildGrid()
        self:updateEnemies(dt, grid)
        self:updateRams(grid)
        self:updateBullets(dt, grid)
        self:updateEnemyShots(dt)
        -- What fights for you while your hands are busy drawing. After the
        -- crowd has moved, so a star cuts and a rocket goes off where things
        -- actually are.
        self.loadout:updateWeapons(dt, self, grid)
        self:updateGems(dt)
        self:updatePickups(dt)

        self.noticeT = math.max(0, self.noticeT - dt)

        if self.player.hp <= 0 then
            self.state = "dead"
            self.deadFor = 0
            self.particles:burst(self.player.x, self.player.y, 16, Palette.red)
        elseif self.player.pending > 0 then
            -- Only once the frame is otherwise finished, and never over a run
            -- that has just ended: dying on the level that would have promoted
            -- you is dying.
            self:openDraft()
        end
    else
        self.deadFor = self.deadFor + dt
    end

    self.particles:update(dt)
    Camera.follow(self.player.x, self.player.y, dt)
end

--- draw ---------------------------------------------------------------------

local function byDepth(a, b)
    return a.y < b.y
end

function Game:draw()
    if self.state == "menu" then
        Menu:draw(self)
        return
    end

    if self.state == "studio" then
        Studio:draw(self)
        return
    end

    local left, top, w, h = Camera.bounds()

    -- The page and everything standing on it are drawn separately so that
    -- Overprint can pair them pixel by pixel: the ruling shows through the ink
    -- laid over it instead of being painted out. The HUD is drawn afterwards,
    -- outside the pass -- it sits above the page rather than on it.
    Overprint.beginPage()
    Camera.attach()
    Background.draw(left, top, w, h)
    Camera.detach()

    Overprint.beginInk()
    Camera.attach()

    -- Spent pins and staples are the oldest thing on the page and the only
    -- thing on it that will still be there at the end of the run, so everything
    -- else is drawn over them -- including an eraser sweep, which wipes them the
    -- way it wipes the ruling. They go under the crowd too, unlike the ones
    -- still holding something: while a pin is working you need to see it through
    -- the blob standing on it, and once it is spent it is just paper.
    self:eachSpent(function(d)
        d:drawMark()
        d:draw()
    end)

    -- Marks belong to the page, so they go under everything that stands on it.
    -- The wide soft bands first -- the highlighter and the glue mark
    -- themselves `under` -- because they would otherwise bury the thin lines
    -- they are meant to sit behind. Keyed on `under` rather than on `linger`:
    -- where a mark sits is about how it looks, whether it still hits is about
    -- what it does, and the two must stay free to differ.
    for _, s in ipairs(self.strokes) do
        if s.tool.under then s:draw() end
    end
    for _, s in ipairs(self.strokes) do
        if not s.tool.under then s:draw() end
    end

    -- A pin's ring and a staple's crease are drawn on the page, so they go under
    -- the crowd -- the things themselves are not, and come later. Same for the
    -- pencil a ruler is aimed with, and the line it leaves behind; and same for
    -- a compass's circle, drawn or still only promised.
    for _, d in ipairs(self.drops) do d:drawMark() end
    for _, r in ipairs(self.rulers) do r:drawGuide() end
    for _, c in ipairs(self.compasses) do c:drawGuide() end

    for _, p in ipairs(self.pickups) do p:draw() end
    for _, g in ipairs(self.gems) do g:draw() end

    -- Painter's order, so a monster standing lower on the page overlaps one
    -- standing higher up.
    table.sort(self.enemies, byDepth)
    local pending = self.state ~= "dead"
    for _, e in ipairs(self.enemies) do
        if pending and e.y > self.player.y then
            self.player:draw()
            pending = false
        end
        e:draw()
    end
    if pending then self.player:draw() end

    -- Over the crowd rather than sorted into it: one of these may be in the air
    -- on its way down, and the rest are standing proud of the paper. A pin you
    -- cannot see behind a blob is a pin you cannot aim the next one off -- and
    -- for the stapler that is the whole of how the tool is used, since every
    -- tap is aimed off where the last one went. A compass leg you cannot see is
    -- a width you cannot judge. A ruler lying on the page covers whatever it
    -- has just flattened, which is the whole of what it looks like.
    for _, d in ipairs(self.drops) do d:draw() end
    for _, c in ipairs(self.compasses) do c:draw() end

    -- Over the crowd for the same reason, and one more: nothing here stands on
    -- the page at all. A star is attached to you and a rocket is in the air over
    -- it, so both belong in front of the things they are going through rather
    -- than sorted in among them.
    self.loadout:drawWeapons(self)

    local slapping = false
    for _, r in ipairs(self.rulers) do
        r:draw()
        slapping = slapping or r.slap > 0
    end

    -- You are the one who brought it down, so you are above it: without this
    -- the ruler covers the player along with everything it flattened, and the
    -- one thing you have to keep track of blinks out for an eighth of a second
    -- at the exact moment the page is in chaos.
    if slapping and self.state ~= "dead" then
        self.player:draw()
    end

    for _, b in ipairs(self.bullets) do b:draw() end
    love.graphics.setColor(1, 1, 1)
    for _, s in ipairs(self.shots) do
        Sprites.enemyShot:draw(s.x, s.y)
    end
    self.particles:draw()
    Camera.detach()

    Overprint.finish()

    Hud.draw(self)
    if self.state == "paused" then self.pause:draw(self) end
    if self.state == "levelup" then self.draft:draw(self) end
end

function Game:keypressed(key)
    if self.state == "menu" then
        Menu:keypressed(key)
        return
    end

    if self.state == "studio" then
        Studio:keypressed(key)
        return
    end

    -- Ahead of everything, pause included: a level has to be spent before the
    -- run will take another instruction.
    if self.state == "levelup" then
        self.draft:keypressed(key)
        return
    end

    if key == "p" then
        self:togglePause()
        return
    end
    if self.state == "paused" then
        -- T is the dev toggle: every tool at once, for playtesting.
        if key == "t" then
            self:toggleAllTools()
            return
        end
        -- Y and N answer the card, the same as they answer the title screen.
        self.pause:keypressed(key)
        return
    end

    local slot = tonumber(key)
    if key == "r" and self.state == "dead" then
        self:reset()
    elseif slot and slot >= 1 and slot <= #self.loadout.equipped then
        self:setTool(slot)
    elseif key == "q" then
        self:setTool(self.tool - 1)
    elseif key == "e" then
        self:setTool(self.tool + 1)
    end
end

function Game:wheelmoved(dy)
    if self.state == "studio" then
        Studio:wheelmoved(dy)
        return
    end
    if self.state == "menu" or self.state == "paused" or self.state == "levelup" then
        return
    end
    if dy ~= 0 then
        self:setTool(self.tool - (dy > 0 and 1 or -1))
    end
end

return Game
