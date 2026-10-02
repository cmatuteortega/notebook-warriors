-- One mark on the page.
--
-- A stroke is a chain of brush stamps laid down at a fixed spacing as the head
-- moves, which is what keeps the line even no matter how fast the pointer
-- travels. Damage is applied to the *segment* between the old and new head, so
-- a fast flick can't tunnel past an enemy between frames.
--
-- Marks are anchored in world space: they stay on the paper where you drew
-- them while the camera scrolls away.

local Palette = require("src.palette")
local pixelart = require("src.pixelart")
local Background = require("src.background")
local Camera = require("src.camera")
local util = require("src.util")

local Stroke = {}
Stroke.__index = Stroke

local PATH_STEP = 4    -- how coarsely the path is recorded for lingering damage
local DITHER_START = 0.55 -- fraction of life after which stamps start dropping out

function Stroke.new(tool, x, y)
    return setmetatable({
        tool = tool,
        x = x, y = y,       -- the head
        tx = x, ty = y,     -- smoothed target, for nibs that trail the pointer
        -- A tool can be pure utility (the pen is), in which case there is no
        -- reason to ever run the hit test.
        touches = tool.damage > 0 or tool.knock > 0 or tool.freeze ~= nil,
        stamps = {},
        path = { x, y },    -- coarse polyline, used by lingering tools
        -- Everything the mark has covered, so asking "am I standing on it"
        -- is four comparisons in the overwhelmingly common case of "no".
        minX = x, minY = y, maxX = x, maxY = y,
        hit = {},           -- enemy -> time last hit by this stroke
        seed = love.math.random() * 997,
        i = 0,              -- stamp counter, doubles as each stamp's noise seed
        carry = 0,          -- leftover distance, keeps spacing even across frames
        drawn = 0,          -- total pixels of line so far, for tools with `flow`
        leanTick = 0,       -- next resting-tip hit is due at once: see update
        loopFrom = 1,       -- oldest path index a loop may still close against
        -- Whether a ring closed in this mark cuts what it holds -- the pencil's
        -- `loop`. A field rather than a straight read of the tool, because one
        -- mark is not laid by a hand: a compass leg carrying a pencil (the LASSO,
        -- src/tools.lua) rules a ring that closes as a *lap*, and the sweep
        -- resolves it there off the geometry it already has (Compass:ring). Being
        -- surrounded is one event, so the stroke dragged round behind the lead
        -- must not also claim it -- src/compass.lua clears this on the marks it
        -- opens.
        lassos = tool.loop ~= nil,
        -- The rings this mark has closed, kept only by the two rows whose ring
        -- leaves something lying in its middle (`loop.wash`, `loop.lift`). Each
        -- one is the flat pairs of the stretch of path that closed it, copied out
        -- rather than referenced: `loopFrom` spends the path behind a close, so a
        -- ring that went on pointing into a list the stroke keeps extending would
        -- be a shape that grew after it was drawn.
        --
        -- A list rather than one, because a spiral closes several and each is its
        -- own hole. They die with the mark and are held by nothing else, which is
        -- the scissors' rule for a severed region arriving for free: the page is
        -- open for as long as what opened it is on the paper and no longer.
        rings = nil,
        -- Which of a paced row's two nibs is on the page right now (`pace` in
        -- src/tools.lua, the SWELL) -- set off the nib's own travel each time the
        -- head advances, and read by everything that has to know how wide this mark
        -- is at the moment: the dab, the hit, and the price.
        thin = false,
        -- The nib's radius at each recorded path point, for a mark whose width
        -- varies along its own length. Beside the path rather than in it, because
        -- the path is flat pairs and four things step through it two at a time
        -- (insidePath, Walls:rebuild, pixelart.fillPolygon, the walks below) -- a
        -- third number per point would have to be understood by all of them to be
        -- skipped by any of them. Only a paced row keeps one; for everything else
        -- the tool's own `radius` is the answer everywhere and always was.
        pathR = tool.pace and { tool.radius } or nil,
        age = 0,
        active = true,
        -- Set by Game:updateDrawing on a mark whose tool has `keep`, and
        -- cleared there when the next one is drawn: while it is true this
        -- stroke neither ages nor is culled.
        kept = false,
        -- The same effect, owned by somebody else. Set on a mark that is not a
        -- line anybody drew but one the page's own pushpins are holding up
        -- (`thread` and `pool` in src/tools.lua): Game:stringThreads strings one
        -- between two of them and Game:poolAt pools one round a single one, and
        -- Game:unstring lets go of either the moment a post comes out.
        --
        -- Its own field rather than a second writer on `kept`, because the two
        -- are different holds with different owners and one list cannot express
        -- both: `kept` is one gesture's worth of wall and Game:holdWalls releases
        -- every stroke on the page each time a new one is laid, where a thread
        -- answers to its own two posts and to nothing else. A run holding a pen
        -- beside a threading tool would otherwise drop every thread on the page
        -- the frame it drew a fence.
        strung = false,
        tick = 0,
    }, Stroke)
end

-- (nx, ny) is the direction the head is travelling, which only a tool that
-- sheds debris rather than laying a dab has any use for.
function Stroke:addStamp(x, y, game, nx, ny)
    self.i = self.i + 1

    -- A brush can leave nothing on the page at all -- the rubber does. The walk
    -- along the segment still paces what comes off it, there is just no dab to
    -- keep.
    if self.tool.stamp then
        local stamp = { x = math.floor(x), y = math.floor(y), i = self.i }
        -- Stacked ink shows: with `stack`, a dab laid back over ground this
        -- stroke has already covered is marked, and draw() paints it in the
        -- pooled-ink colour -- so where the band will burn double is exactly
        -- where it reads deeper. A choice you cannot see is not one you can
        -- make.
        if self.tool.stack and self:revisits(x, y) then
            stamp.over = true
        end
        -- Which nib laid this dab (`pace`). Carried on the dab because a stamp
        -- function is the only thing in the drawing that sees one: Stroke:draw
        -- walks the whole mark in a single pass, so a mark laid with two nibs has
        -- to be a pass that asks each dab which it was -- see `pacedStamp` in
        -- src/tools.lua.
        if self.thin then stamp.thin = true end
        self.stamps[#self.stamps + 1] = stamp
    end

    if x < self.minX then self.minX = x elseif x > self.maxX then self.maxX = x end
    if y < self.minY then self.minY = y elseif y > self.maxY then self.maxY = y end

    local speck = self.tool.speck
    if speck and util.hash01(self.i, self.seed, 21) < speck.chance then
        game.particles:burst(x, y, 1, speck.color)
    end

    local crumbs = self.tool.crumbs
    if crumbs and util.hash01(self.i, self.seed, 22) < crumbs.chance then
        game.particles:crumb(x, y, nx, ny, self.tool.radius, crumbs.color)
    end
end

-- Advances the head towards (x, y), spending at most `budget` pixels of line.
-- Returns how much was actually drawn.
function Stroke:extend(x, y, budget, game, dt)
    -- A smoothed nib chases the pointer instead of snapping to it, so shaky
    -- input and sharp direction changes come out as curves rather than kinks.
    if self.tool.smooth then
        local k = 1 - math.exp(-self.tool.smooth * dt)
        self.tx = self.tx + (x - self.tx) * k
        self.ty = self.ty + (y - self.ty) * k
        x, y = self.tx, self.ty
    end

    local dx, dy = x - self.x, y - self.y
    local dist = math.sqrt(dx * dx + dy * dy)
    if dist < 0.35 or budget <= 0 then return 0 end

    local used = math.min(dist, budget)
    local nx, ny = dx / dist, dy / dist
    local ax, ay = self.x, self.y
    local bx, by = ax + nx * used, ay + ny * used

    -- A paced nib, decided before a single dab of this stretch goes down (`pace`
    -- in src/tools.lua). Measured off `used` rather than off the pointer's own
    -- travel, which is the smoothing above being taken seriously: the nib is what
    -- is on the paper, and a flick the nib never made should not buy the thin line.
    -- The floor under dt is for the one caller that lays a whole stroke on a single
    -- frame with none (`Game:stringThreads`) -- no threading row is paced, and a
    -- division by zero is not the way to find out if one ever is.
    if self.tool.pace then
        self.thin = used / math.max(dt or 0, 1 / 240) >= self.tool.pace.over
    end

    local t = self.carry
    while t <= used do
        self:addStamp(ax + nx * t, ay + ny * t, game, nx, ny)
        t = t + self.tool.spacing
    end
    self.carry = t - used

    if self.touches then
        self:damageSegment(game, ax, ay, bx, by)

        -- And the same stretch of rub taking the page's own staples back out of it
        -- (`snag` in src/tools.lua, the SNAG). It is the only thing a mark in this
        -- game does to something the page is already holding rather than to
        -- something standing on it, so it belongs to whatever can see both -- which
        -- is `Game:snagDrops` and not this file, exactly as a thread between two
        -- pins belongs to the game and not to src/pin.lua.
        --
        -- Inside the same guard rather than beside it, because the two halves of a
        -- rub commit together: a press that might still turn out to be a *tap* is
        -- not rubbing anything yet, and on the one row carrying this the tap is what
        -- puts the staples in (`fasten.tapped`, Game:updateDrawing).
        if self.tool.snag then
            game:snagDrops(self, ax, ay, bx, by)
        end
    end

    self.x, self.y = bx, by
    self.drawn = self.drawn + used
    local px, py = self.path[#self.path - 1], self.path[#self.path]
    if util.len(bx - px, by - py) >= PATH_STEP then
        self.path[#self.path + 1] = bx
        self.path[#self.path + 1] = by
        if self.pathR then self.pathR[#self.pathR + 1] = self:reach() end
        if self.lassos then
            self:tryCloseLoop(game)
        end
    end

    -- A tip that is travelling is scrubbing, not leaning: any real movement
    -- holds the resting hit back by a full cadence, so `lean` only pays and
    -- fires once the tip has genuinely come to rest.
    if self.tool.lean then
        self.leanTick = math.max(self.leanTick, self.tool.rehit)
    end

    return used
end

-- Even-odd ray cast over the tail of the path from `from`, treated as a closed
-- polygon (the last point joins back to the first). Enough geometry for a
-- hand-drawn lasso: a point grazing the ink itself lands either way, and at
-- pencil scale neither answer matters.
--
-- On the module rather than local to this file because there are two ways to
-- close a ring with a pencil now and only one of them is a path coming back to
-- itself. Game:cutCircuit hands it a polygon whose corners are pushpins
-- (`thread` in src/tools.lua) -- flat pairs, the same shape a path is, so the
-- one test answers both and neither caller has to know what drew the other.
function Stroke.insidePath(px, py, path, from)
    local inside = false
    local n = #path
    local x1, y1 = path[n - 1], path[n]
    for p = from, n - 1, 2 do
        local x2, y2 = path[p], path[p + 1]
        if (y2 > py) ~= (y1 > py) then
            if px < x1 + (py - y1) / (y2 - y1) * (x2 - x1) then
                inside = not inside
            end
        end
        x1, y1 = x2, y2
    end
    return inside
end

-- The pencil's last level: a line closed on itself deals with everything inside.
--
-- Checked each time a path point lands. A closing point must be old enough
-- that the ring has real perimeter -- MIN_LOOP points, so a wiggle is not a
-- lasso -- and no older than the last loop this stroke already closed: a close
-- spends the path behind it, so one circle is one cut and a spiral has to keep
-- travelling to keep cutting. The cut bypasses the stroke's hit list on
-- purpose -- being ringed and being scratched are different events, and an
-- enemy the line grazed on the way round is still inside the ring it drew.
--
-- **What a ring does to what it holds is three fields and the row picks**, which
-- is what the pencil's own family of fusions is about (src/tools.lua): `damage`
-- cuts, `ignite` sets alight, `lift` takes off the page with the paper. Written
-- as three tested fields rather than as a kind, because a row may want more than
-- one and because none of them is a default -- the BLEED writes no `damage` at
-- all and the CUTOUT deals none, so a walk that assumed one would be indexing a
-- nil the first time either of them closed a circle.
--
-- The order matters exactly once and it is the last of the three: `lift` moves
-- the body across the page (Game:liftEnemyTo), so anything done to it
-- afterwards would be landing on a thing that is no longer where the ring was --
-- a burst of red thrown in the corner for a hit that happened in the middle of
-- the page. `lift` going last means a row writing both gets the hit in where the
-- ring drew it, and only then hands the body its corner.
local MIN_LOOP = 10   -- path points between the closing pair: ~40px of perimeter
local CLOSE_GAP = 4   -- how far past the radius still reads as "came back to it"

function Stroke:tryCloseLoop(game)
    local path = self.path
    local hx, hy = path[#path - 1], path[#path]
    local reach = self.tool.radius + CLOSE_GAP

    local from
    for p = self.loopFrom, #path - MIN_LOOP * 2, 2 do
        if util.len(path[p] - hx, path[p + 1] - hy) < reach then
            from = p
            break
        end
    end
    if not from then return end

    -- Everything from the touched point to the head is the ring, and it is
    -- spent the moment it closes.
    self.loopFrom = #path + 1
    game.particles:burst(hx, hy, 5, Palette.ink)

    -- Kept only by the two rows whose ring leaves something in its middle: the
    -- BLEED floods it with the band's own ink and the CUTOUT takes the page out
    -- of it. Copied rather than pointed at -- see `rings` in Stroke.new.
    local loop = self.tool.loop
    if loop.wash or loop.lift then
        local ring = {}
        for p = from, #path do ring[#ring + 1] = path[p] end
        self.rings = self.rings or {}
        self.rings[#self.rings + 1] = ring
    end

    -- Where a lifted body goes, asked once for the whole walk (`Game:clearCorner`)
    -- -- and asked after the ring above was added to `self.rings`, which matters:
    -- the corner has to be clear of the hole this close has just made as well as
    -- of every other one on the page. Nil is a page with no paper left on screen,
    -- and then the ring hits and burns as usual and lifts nobody.
    local corner = loop.lift and game:clearCorner() or nil

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if Stroke.insidePath(e.x, e.y, path, from) then
            if loop.damage then
                game.particles:burst(e.x, e.y, 2, Palette.red)
                if e:hurt(loop.damage) then
                    game:killEnemy(i)
                end
            end
            -- The burn travels with the body and outlives the ring, the way it
            -- outlives the band that set it -- being surrounded is the event, and
            -- what it leaves behind is a lit enemy walking away from where the
            -- ring was.
            if loop.ignite and not e.gone then
                game.particles:flame(e.x, e.y)
                e:ignite(loop.ignite)
            end
            -- The paper going, not a body being hurt -- so nothing sparks red and
            -- nothing is counted a kill: what is inside is carried off with the
            -- page and put down again in the furthest clear corner of it, which is
            -- `Game:liftEnemyTo`'s whole contract. The ring goes on answering for
            -- arrivals afterwards (`Stroke:sweepRings`), the way the offcut does: a
            -- hole you can see and can walk into is not one that only cleared
            -- itself once.
            if corner and not e.gone then
                game:liftEnemyTo(e, corner)
            end
        end
    end
end

-- Is (x, y) back over ground this stroke has already been over? The stretch
-- just behind the head doesn't count -- a stroke is always standing on its own
-- tail -- so the skip is measured off the reach: everything nearer along the
-- path than the radius could reach in a straight line is ignored, and only ink
-- old enough that the head must have *left and come back* answers. Used by
-- tools with `scrub` (Game:updateDrawing) to price a re-rub cheaper.
function Stroke:revisits(x, y)
    local path, reach = self.path, self.tool.radius
    local skip = math.ceil(reach / PATH_STEP) + 1
    local last = #path - 3 - skip * 2

    for p = 1, last, 2 do
        if util.distToSegment(x, y, path[p], path[p + 1], path[p + 2], path[p + 3]) < reach then
            return true
        end
    end
    return false
end

-- Is (x, y) standing on this mark? Used by surfaces rather than weapons, so it
-- answers for a point rather than resolving a hit.
--
-- `reach` overrides how far off the ink still counts, for the one caller that
-- is not asking about a point standing on the line: Stroke:pop wants the ink's
-- radius plus its own spread plus the body's, and the bounding box has to
-- refuse against the same number or the box would be tighter than the test.
function Stroke:covers(x, y, reach)
    reach = reach or self.tool.radius
    if x < self.minX - reach or x > self.maxX + reach
        or y < self.minY - reach or y > self.maxY + reach then
        return false
    end

    local path = self.path
    for p = 1, #path - 3, 2 do
        if util.distToSegment(x, y, path[p], path[p + 1], path[p + 2], path[p + 3]) < reach then
            return true
        end
    end

    -- The path is only recorded every few pixels; the head runs on past it.
    local n = #path
    return util.distToSegment(x, y, path[n - 1], path[n], self.x, self.y) < reach
end

-- Which way (x, y) would be dragged into this mark, if it is close enough to
-- feel it: the direction to the nearest recorded point of the path, or nothing
-- outside `range` of the ink's edge. The gluestick's last level asks this
-- every frame for every free enemy, so the bounding box does the refusing for
-- almost all of them, the same way it does for covers -- and the path's
-- recorded points are near enough for a drag that a segment projection would
-- buy nothing.
function Stroke:pullTowards(x, y, range)
    local reach = self.tool.radius + range
    if x < self.minX - reach or x > self.maxX + reach
        or y < self.minY - reach or y > self.maxY + reach then
        return
    end

    local path = self.path
    local best, bx, by
    for p = 1, #path - 1, 2 do
        local dx, dy = path[p] - x, path[p + 1] - y
        local d = dx * dx + dy * dy
        if not best or d < best then
            best, bx, by = d, path[p], path[p + 1]
        end
    end
    -- Nothing to pull towards, out of reach, or already standing on the spot
    -- it would be pulled to -- a direction from a point to itself is noise.
    if not best or best > reach * reach or best < 1 then return end
    return util.normalize(bx - x, by - y)
end

-- How far this mark reaches from its centre line *now*. The tool's own radius for
-- every row but a paced one, where the nib is two nibs and which of them is on the
-- page is a fact about how fast the hand was moving when it got here.
function Stroke:reach()
    local pace = self.tool.pace
    if pace and self.thin then return pace.thin end
    return self.tool.radius
end

-- What a pixel of this line costs, as a fraction of the price written on the row:
-- a nib laying half as much ink is charged half. The ratio of the two nibs rather
-- than a number of its own, so a row cannot say one thing about its width and
-- another about its cost. Read by Game:updateDrawing, a frame behind the nib it is
-- pricing -- the same lag `flow` is priced with, on a fraction that only ever has
-- two values.
function Stroke:paceRate()
    return self:reach() / self.tool.radius
end

function Stroke:canHit(enemy, time)
    local last = self.hit[enemy]
    if not last then return true end
    return self.tool.rehit ~= nil and time - last >= self.tool.rehit
end

-- `layers` is how many passes of the mark are lying over the enemy at once --
-- only ever above 1 for a lingering tool with `stack` (see lingerTick below) --
-- and it multiplies the damage alone: two layers of ink do not shove or hold
-- any harder than one.
function Stroke:apply(game, enemy, index, ax, ay, bx, by, layers, lingering)
    local tool = self.tool
    self.hit[enemy] = game.time

    if tool.knock > 0 then
        -- Push away from the line itself, so an eraser sweep shoves the horde
        -- sideways instead of along the direction you happened to be drawing.
        local vx, vy = bx - ax, by - ay
        local len2 = vx * vx + vy * vy
        local t = 0
        if len2 > 0 then
            t = ((enemy.x - ax) * vx + (enemy.y - ay) * vy) / len2
            t = t < 0 and 0 or (t > 1 and 1 or t)
        end
        local px, py = util.normalize(enemy.x - (ax + vx * t), enemy.y - (ay + vy * t))
        if px == 0 and py == 0 then px, py = util.normalize(-vy, vx) end
        enemy:knockback(px, py, tool.knock)

        -- The rubber's last level: this shove is hard enough that what it
        -- sends flying is itself a weapon until it slows back down.
        if tool.ram then
            enemy:launch(tool.ram)
        end
    end

    -- The tool goes with the freeze: the gluestick's upper levels read their
    -- victim off the enemy afterwards (Enemy:hurt, Game:updateGlue).
    if tool.freeze and enemy:freeze(tool.freeze, tool) then
        game.particles:burst(enemy.x, enemy.y, 3, Palette.sky)
    end

    -- A tool can be pure crowd control; don't flash an enemy that took nothing.
    --
    -- `sting` is what the *mark* does where that is not what the nib does, and one
    -- row writes it: the DECKLE is a pencil laying a pen's wall, so 9 is what
    -- being drawn over costs and 1 is what leaning on the finished fence costs.
    -- Two numbers because two tools wrote them, and it is the placement `pop` and
    -- `loop` already use -- what a mark does after the stroke is over has never
    -- been the same field as what the stroke does. Read here rather than in
    -- lingerTick so that every path into a tick gets it, and defaulted to
    -- `damage` so that nothing else in the catalogue changes.
    local base = tool.damage
    if lingering and tool.sting then base = tool.sting end

    if base > 0 then
        local damage = base * (layers or 1)
        -- The pencil's crit level. Rolled live per hit, like a particle spawn,
        -- rather than hashed: a crit is an event that happens once, not stored
        -- variation that has to come out the same twice. It multiplies after
        -- the layers, and it is always announced -- a big number nobody saw
        -- land is indistinguishable from a bug.
        if tool.crit and love.math.random() < tool.crit.chance then
            damage = damage * tool.crit.mult
            game.particles:crit(enemy.x, enemy.y)
        end
        game.particles:burst(enemy.x, enemy.y, 2, Palette.red)
        if enemy:hurt(damage) then
            game:killEnemy(index)
        end
    end
end

function Stroke:damageSegment(game, ax, ay, bx, by)
    local radius = self:reach()
    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if self:canHit(e, game.time)
            and util.distToSegment(e.x, e.y, ax, ay, bx, by) < radius + e.radius then
            self:apply(game, e, i, ax, ay, bx, by)
        end
    end
end

-- Everything standing on the mark takes a tick of damage: the highlighter's
-- band, and the pen's line once its contact level has been taken.
--
-- With `stack`, ink laid over your own ink counts. What is counted is *passes*,
-- not segments: the path is recorded every few pixels, so a straight band over
-- an enemy is many covering segments in a row and has to read as one layer --
-- a new layer starts only where the path left the enemy and came back, which
-- is exactly what scribbling over a patch does. Capped at `stack`, or a tight
-- enough scribble would be a one-stroke pushpin. Without `stack` the first
-- covering segment settles it, exactly as before.
--
-- `graze` widens the reach, and only a mark that is also a wall wants it: see
-- the field in src/tools.lua for why a fence cannot be measured at its own
-- radius. The bounding box refuses for almost every enemy before the walk, the
-- way it already does for Stroke:covers -- worth having now that the longest
-- marks in the game tick, and that one of them can be held on the page
-- indefinitely (`keep`).
function Stroke:lingerTick(game)
    local path, radius = self.path, self.tool.radius
    if #path < 4 then return end
    local stack = self.tool.stack or 1
    local graze = self.tool.graze or 0
    -- A mark whose width varies along it (`pace`): the tick reaches as far as the
    -- stretch of line the body is standing on, not as far as the widest stretch
    -- somewhere else on the same mark. The bounding box above goes on refusing at
    -- the row's own radius, which is the widest either nib can be, so what the
    -- box lets through is a superset either way.
    local pathR = self.pathR

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        local reach = radius + graze + e.radius
        if self:canHit(e, game.time)
            and e.x >= self.minX - reach and e.x <= self.maxX + reach
            and e.y >= self.minY - reach and e.y <= self.maxY + reach then
            local layers, over = 0, false
            local ax, ay, bx, by
            for p = 1, #path - 3, 2 do
                -- (p + 1) / 2 is the point number this segment starts at: the path
                -- is flat pairs, so point n is at 2n - 1.
                local r = pathR and pathR[(p + 1) / 2] or radius
                local covers = util.distToSegment(e.x, e.y,
                    path[p], path[p + 1], path[p + 2], path[p + 3]) < r + graze + e.radius
                if covers and not over then
                    layers = layers + 1
                    if layers == 1 then
                        ax, ay, bx, by = path[p], path[p + 1], path[p + 2], path[p + 3]
                    end
                    if layers >= stack then break end
                end
                over = covers
            end
            if layers > 0 then
                self:apply(game, e, i, ax, ay, bx, by, layers, true)
            end
        end
    end
end

-- The pen's third level: a line does not fade quietly off the page, it comes
-- off all at once. Everything within `pop.reach` of the ink takes the hit,
-- which for a fence is everything that was leaning on it and a little past.
--
-- The whole line rather than a circle somewhere on it, because a fence has no
-- centre: what is being drawn and what is being hit are both the mark. That is
-- also why the puffs walk the path -- a burst at one end of 170px of wall would
-- read as something going off *near* the pen line rather than as the pen line
-- going. Blue, the ink's own colour, on the bomb's reasoning: this is the mark
-- leaving, not the crowd being caught, and what it kills sparks red on its own.
--
-- One scan in the life of a mark, on the frame Game:updateDrawing culls it, so
-- it costs nothing on any clock. The hit list is bypassed for the lasso's
-- reason -- being leaned on and being blown off the page are different events.
local POP_EVERY = 2   -- path points between puffs: ~8px of line each

function Stroke:pop(game)
    local pop = self.tool.pop
    local path = self.path

    for p = 1, #path - 1, 2 * POP_EVERY do
        game.particles:burst(path[p], path[p + 1], 2, Palette.blue)
    end

    local reach = self.tool.radius + pop.reach
    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if self:covers(e.x, e.y, reach + e.radius) then
            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(pop.damage) then
                game:killEnemy(i)
            end
        end
    end
end

-- A press that never went anywhere -- the STUB's `tap` (src/tools.lua), and the
-- one gesture a brush row can carry.
--
-- It is a rub delivered as a single event: a circle at the point the finger
-- landed on, everything in it shoved radially out of the middle of it, and what
-- that sends flying knocking down what it lands on if the row has a `ram`. Which
-- is the finished rubber doing exactly what the finished rubber does -- the
-- numbers are its own -- with the scrub taken off, since there is nothing to
-- scrub when the whole gesture is one press.
--
-- **The hit list is bypassed, for the lasso's and the pop's reason**: being
-- rubbed at and being drawn over are different events, and an enemy the line
-- happened to graze on the way in has still just been shoved. It costs nothing to
-- allow, because a tap is a press that laid no line -- there is nothing in the
-- list for a mark that was never drawn.
--
-- The crumbs are thrown here rather than left to the brush's own per-stamp rate,
-- and that is the CRATER's lesson: `crumbs` is debris shed by a *travelling* tip
-- and a tap does not travel, so a rate written on the row would either spend
-- itself on the single stamp a press lays or shed eraser crumbs down the length
-- of every pencil line the tool ever drew. A ring of them off the point, once,
-- with no direction -- Particles:crumb rolls its own axis when it is handed none,
-- which is what debris out of a rubbed spot should do anyway.
local TAP_CRUMBS = 7

function Stroke:tap(game)
    local tap = self.tool.tap
    local x, y = self.x, self.y

    for _ = 1, TAP_CRUMBS do
        game.particles:crumb(x, y, nil, nil, tap.radius, Palette.graphite)
    end

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if util.len(e.x - x, e.y - y) < tap.radius + e.radius then
            -- Radially out of the point. A body standing exactly on it has no
            -- direction to be thrown in, so it is given one -- the same fallback
            -- Stroke:apply makes for a hit square on its own segment.
            local nx, ny = util.normalize(e.x - x, e.y - y)
            if nx == 0 and ny == 0 then nx, ny = 0, -1 end
            e:knockback(nx, ny, tap.knock)
            if tap.ram then e:launch(tap.ram) end

            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(tap.damage) then
                game:killEnemy(i)
            end
        end
    end
end

-- The rings this mark has closed, still answering for whatever has walked into
-- them since -- the CUTOUT's `loop.lift`.
--
-- It is the offcut's contract with a shape instead of a half-plane
-- (`Scissors:lift`), and a clock rather than one pass for the same reason: a hole
-- in the page is not a thing that emptied itself once, it is a piece of page that
-- is not there, so it has to go on answering for arrivals. Which is also what
-- makes the fill honest -- there is grey on the paper for as long as this runs and
-- not a frame longer, so what you can see is exactly what will take you.
--
-- Clipped to the viewport, the offcut's rule and the sun's: nothing is hauled
-- across a page away from anybody looking at it, and a corner nobody can see is
-- not a place a crowd can be watched arriving out of.
--
-- Where what a ring holds goes is the run's question and not this mark's
-- (`Game:clearCorner`): a spiral leaves four holes lying on top of each other and
-- a cut may have taken half the page besides, so the corner has to be clear of all
-- of them and not of the ring that caught the body. Asked once for the whole sweep,
-- so a mark full of holes empties into one corner rather than scattering the crowd
-- ring by ring -- and nil is a screen with no paper left on it, which lifts nobody.
function Stroke:sweepRings(game)
    local corner = game:clearCorner()
    if not corner then return end

    local left, top, w, h = Camera.bounds()

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if e.x >= left and e.x <= left + w and e.y >= top and e.y <= top + h then
            for _, ring in ipairs(self.rings) do
                if Stroke.insidePath(e.x, e.y, ring, 1) then
                    game:liftEnemyTo(e, corner)
                    break
                end
            end
        end
    end
end

-- The line itself, and everything touching it (`lift` on the row, the DEADLINE in
-- src/tools.lua). The offcut's contract with the thinnest region in the game:
-- what a cut does with half a page and a punch with a disc, this does with a pen
-- line you drew by hand.
--
-- **The fourth shape a severed region comes in, and the first that is not an
-- area.** A half-plane, a disc and a ring are all somewhere a body can be *inside*;
-- a line is somewhere a body can only be *on*, which is why the test is
-- `Stroke:covers` -- the same question the wall, the wax, the glue and the linger
-- all ask of a mark, bounding box first, and no new geometry anywhere. Measured
-- against the ink's radius plus the body's, so what answers is a body *touching*
-- the line rather than one standing with its centre on it: the line is a pixel or
-- four wide and a blob is eight across, so a centre test would be a line most
-- things walk over.
--
-- Clipped to the viewport, the offcut's rule: a page-crossing line that a run keeps
-- (`keep`) goes on being a line long after the camera has walked away from it, and
-- lifting bodies out of ground nobody is looking at is the horde's budget going
-- somewhere nobody can see it go.
--
-- Where they go is the run's question and asked once for the whole sweep
-- (`Game:clearCorner`), which is what makes this a *tool* rather than a wall: the
-- crowd does not pile up against the line, it comes back out of one corner, and the
-- line is only worth what you drew it between.
function Stroke:sweepLine(game)
    local corner = game:clearCorner()
    if not corner then return end

    local left, top, w, h = Camera.bounds()
    local reach = self.tool.radius

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        if e.x >= left and e.x <= left + w and e.y >= top and e.y <= top + h
            and self:covers(e.x, e.y, reach + e.radius) then
            game:liftEnemyTo(e, corner)
        end
    end
end

-- The middle of a closed ring, flooded with the mark's own ink -- the BLEED's
-- `loop.wash`.
--
-- Drawn as spans a row at a time (`pixelart.fillPolygon`) for the offcut's
-- reason: a filled shape at an angle plotted a pixel at a time does not tile and
-- comes out with holes in it. It goes down before the stamps and under the rim, so
-- the band still reads as the border of the patch rather than as a stripe through
-- the middle of it -- and the row that carries it is `under`, so the whole thing
-- lands beneath everything standing on it, which is where a wash belongs.
--
-- **The fade is rows rather than pixels**, and that is the palette rule doing it
-- rather than a saving: there is no alpha, so a wash cannot thin -- it can only
-- step down the ramp or stop being there. Stepping the ramp is what the body
-- already does and a one-colour ramp has nowhere to step, so what is left is
-- dropping ink, and a span is the unit this has. Rows going out of a patch reads
-- as a wash drying in stripes, which is what a marker actually does on paper.
local WASH_STEP = 3   -- rows in a dither band: coarse enough to read as drying

function Stroke:drawWash()
    local tool = self.tool
    local f = self.age / tool.life
    local start = tool.fade or DITHER_START
    local dither = f > start and (f - start) / (1 - start) or 0

    love.graphics.setColor(
        tool.ramp[math.min(#tool.ramp, math.floor(f * #tool.ramp) + 1)])

    local left, top, w, h = Camera.bounds()
    for _, ring in ipairs(self.rings) do
        pixelart.fillPolygon(ring, top, top + h, function(x, y, len)
            if dither == 0
                or util.hash01(math.floor(y / WASH_STEP), self.seed, 41) > dither then
                local from = math.max(x, math.floor(left))
                local to = math.min(x + len - 1, math.floor(left + w))
                if to >= from then
                    love.graphics.rectangle("fill", from, y, to - from + 1, 1)
                end
            end
        end)
    end
end

-- And the same middle with the page taken out of it instead -- the CUTOUT's
-- `loop.lift`.
--
-- This is the *page* layer and not the ink layer, which is the one thing about it
-- that is not a choice: grey laid as a mark would be paired with the page under it
-- by the overprint pass, so it would come out as some other colour wherever it
-- crossed a rule, and ink laid on top would go on stacking against the paper it
-- had covered. What goes down is the page itself rebaked -- the ruling exactly
-- where it was printed and grey where the white used to be (`Background.torn`) --
-- because scissors take the paper and not the printing on it, and a ring is not
-- a different kind of hole.
--
-- Called from the same place in `Game:draw` as the cuts' and the compasses' own,
-- and it knows about neither: all three are spans of rebaked page, so a ring
-- inside a severed half is the same grey laid twice.
function Stroke:drawTorn(left, top, w, h)
    for _, ring in ipairs(self.rings) do
        pixelart.fillPolygon(ring, top, top + h, function(x, y, len)
            local from = math.max(x, math.floor(left))
            local to = math.min(x + len - 1, math.floor(left + w))
            if to >= from then
                Background.torn(from, y, to - from + 1)
            end
        end)
    end
end

function Stroke:finish()
    self.active = false
end

-- Returns false once the mark has faded off the page.
function Stroke:update(dt, game)
    -- A held mark does not age -- the pen's last level, `keep` in src/tools.lua.
    -- Not ageing is the whole of it: the fade is read off the age (draw), the
    -- cull is read off the age (below), so a wall that is still the last one
    -- drawn goes on standing there at full ink with nothing else told about it.
    if not self.active and not self.kept and not self.strung then
        self.age = self.age + dt
    end

    if self.tool.linger then
        self.tick = self.tick - dt
        if self.tick <= 0 then
            self.tick = self.tool.tickRate
            self:lingerTick(game)
        end
    end

    -- The holes this mark has cut in the page, on their own clock -- the offcut's,
    -- and a separate one from `linger` above because the row that carries it is
    -- not a lingering tool and never will be: what happens inside a ring is not
    -- what happens on the ink.
    local lift = self.rings and self.tool.loop.lift
    if type(lift) == "table" then
        self.lifted = (self.lifted or 0) - dt
        if self.lifted <= 0 then
            self.lifted = lift.tick
            self:sweepRings(game)
        end
    end

    -- And the same verb with the *ink* as the region rather than what it encloses
    -- (`lift` on the row, the DEADLINE): a line nothing may cross, on the offcut's
    -- own half-second. Its own clock rather than `linger`'s above, which the row
    -- also carries -- the two are asking different questions of the same mark, one
    -- of them being what the line does to whatever leans on it and the other being
    -- what the *page* does with it, and pacing a lift off a sting would tie the
    -- scissors' number to the pen's.
    --
    -- Same word as `loop.lift` and deliberately: the CUTOUT lifts what a ring
    -- encloses and this lifts what the line touches, which is one verb at two
    -- shapes. Nothing carries both and nothing needs to.
    local trip = self.tool.lift
    if trip then
        self.tripped = (self.tripped or 0) - dt
        if self.tripped <= 0 then
            self.tripped = trip.tick
            self:sweepLine(game)
        end
    end

    -- The rubber's lean level: while the stroke is held down and the tip is at
    -- rest (extend pushes this timer back whenever the head moves), the tip
    -- itself keeps hitting where it sits -- a zero-length segment, so the
    -- shove goes radially off the tip -- and the hit list is shared with the
    -- moving stroke, so `rehit` paces the pair of them together. Starting at
    -- zero means the press itself lands one: touching them with the rubber is
    -- enough.
    --
    -- Each resting hit is priced as `lean.px` pixels of the tool's own ink, so
    -- the meter owns leaning the way it owns everything else -- through
    -- tool.ink, where the blotter's discount already lives. Too poor to pay
    -- and the tick simply waits, retrying as the meter creeps back.
    if self.active and self.tool.lean then
        self.leanTick = self.leanTick - dt
        if self.leanTick <= 0 then
            local price = self.tool.lean.px * self.tool.ink
            if game.ink >= price then
                self.leanTick = self.tool.rehit
                game:spendInk(price)
                self:damageSegment(game, self.x, self.y, self.x, self.y)
            end
        end
    end

    -- A stroke being drawn is never culled, whatever its life -- which is what
    -- lets a mark that leaves nothing behind set a life of zero and go the
    -- instant you let go. Nor is a held one, which is `kept` doing the only
    -- other thing it does.
    return self.active or self.kept or self.age < self.tool.life
end

function Stroke:draw()
    local tool = self.tool
    if not tool.stamp then return end   -- nothing to draw: see Stroke:addStamp

    local f = self.age / tool.life

    -- Fading happens in two palette-safe ways at once: the colour steps down
    -- the ramp, and individual stamps start dropping out. No alpha, so nothing
    -- ever blends into a ninth colour.
    local start = tool.fade or DITHER_START
    local dither = 0
    if f > start then
        dither = (f - start) / (1 - start)
    end

    -- `over` filters by the stacked-ink mark: nil takes every stamp, false
    -- only the first pass, true only the dabs laid back over the stroke's own
    -- ink.
    local stamps = self.stamps
    local function pass(stamp, color, rough, over)
        love.graphics.setColor(color)
        local threshold = math.max(dither, rough or 0)
        for i = 1, #stamps do
            local s = stamps[i]
            if (over == nil or not s.over == not over)
                and (threshold == 0 or util.hash01(s.i, self.seed, 31) > threshold) then
                stamp(s, self)
            end
        end
    end

    -- Under the rim and under the body: the wash is the patch and the band is its
    -- border, so a border drawn under its own patch would not be one.
    if self.rings and tool.loop.wash then
        self:drawWash()
    end

    if tool.edge then
        pass(tool.edge.stamp, tool.edge.color, tool.edge.rough)
    end

    local body = tool.ramp[math.min(#tool.ramp, math.floor(f * #tool.ramp) + 1)]
    if tool.stack then
        -- Where the band was worked over it is drawn in the edge's colour --
        -- the ink that pooled -- which for the highlighter is red over blush:
        -- the same deepening a real one shows on a second pass, and the map of
        -- exactly where the layers will burn together.
        pass(tool.stamp, body, tool.rough, false)
        pass(tool.stamp, tool.edge and tool.edge.color or body, tool.rough, true)
    else
        pass(tool.stamp, body, tool.rough)
    end

    -- Painted over the top of the finished mark, for texture the fill itself
    -- can't carry.
    if tool.holes then
        pass(tool.holes.stamp, tool.holes.color, tool.holes.rough)
    end
end

return Stroke
