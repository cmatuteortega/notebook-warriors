-- Scissors, and the cut they leave in the page.
--
-- The fourth way a tool can be used, and the only one that takes two presses. A
-- brush is held and dragged and the mark is wherever you dragged it; a pin is
-- tapped and lands where you tapped; a ruler is aimed and a compass is opened,
-- and both of those are one gesture that begins and ends inside a single press.
-- Scissors are *tapped twice*: the first tap says where the cut starts, the
-- second says which way it goes, and the page opens along the line between them.
--
-- Nothing is shown between the two taps but a cross where the anchor is, and
-- nothing happens at the second one all at once. The dotted line is printed when
-- that tap lands, and the blades then take it a pixel at a time -- a cut
-- *travels*, so what it cuts is the crowd as it stands when they reach it rather
-- than the crowd as it stood when you tapped. The far end of a long one is a
-- promise about where the blades will be, not a description of where they are.
-- The one thing that does not wait for them is the half of the page the last
-- level lifts off; see Scissors.new for why.
--
-- Which makes them the one tool that reaches anywhere. A ruler's line has to run
-- through you and a compass's circle has to be centred where you pressed, so
-- both of them are really about where you are standing; a cut is two points on
-- the paper and neither has anything to do with you. What that is paid for with
-- is the second tap: the horde keeps walking between the two, so the row of
-- blobs the first tap lined up is not the row the second one cuts. A cut is led
-- rather than aimed, which is the opposite skill from everything else on the
-- strip.
--
-- It is also the one thing on the strip that is not paid for on the press. The
-- ruler and the compass both charge the moment they are picked up because
-- letting go of either always lands it -- there is no putting one back down. An
-- anchor is not a cut and there is nothing here to land yet, so the ink is
-- charged by the tap that actually opens the paper, and tapping back on the
-- anchor puts the scissors away for nothing. See Game:openCut / Game:closeCut.
--
-- One fused row is the exception and it is the exception on purpose: blades
-- carrying wire drive a staple where the anchor lands (`cut.wire`, the HINGE in
-- src/tools.lua), so that tap *does* land something and is charged like a press.
-- The free anchor is a rule about a tap that does nothing rather than a rule about
-- scissors, and Game:openCut is where it expires.
--
-- **And nothing in this file knows who chose the two points.** Everything here is
-- handed a `def` -- a `cut` block on a tool row, or a `chord`, which is the same
-- block on a *brush* row under another name (Game:chordCut): four fused rows open
-- the page along a line something else decided, whether that is two pushpins, a
-- ruler landing, or the two ends of a smear you just dragged. Two fields exist for
-- those rows and both are read here rather than anywhere else -- `ignite` on the
-- block, which leaves what the blades cut burning (the SCORCH), and `sever.paste`,
-- which leaves what the offcut carried off stuck where it lands (the COLLAGE).
-- Neither costs a row that does not write it anything but a nil test.
--
-- The upgrade line is about the *line*, and it climbs one direction the whole
-- way: how much page one cut is. First the two taps may be any distance apart
-- (`reach`), then the stretch between them bites deeper and wider (`blades`), then
-- the cut stops ending at the second tap and runs on to both edges of the page
-- (`through`), and then the page really is in two and the half you are not
-- standing on is lifted off it (`sever`) -- **with everything on it**. That last
-- one is the only level in the game that does not do damage of any kind: what is
-- standing on the offcut is not hurt, it is *carried off the page with the paper
-- and put down again in the far corner of the half the page kept*. No gem, no xp,
-- no kill -- because nothing died -- and the same crowd at the same health now
-- walking the length of the page back at you. See Scissors:lift and
-- Game:liftEnemyTo for the argument, which is the whole of why a level this
-- absolute is allowed to be: what the run buys is the walk, not the fight. Every
-- level goes on
-- mattering at the next, which is the thing to preserve if any of them is ever
-- moved: unlimited reach is what lets you choose how much of a page-crossing cut
-- is the deep part, and a cut that crosses the page is what gives the last level
-- two halves to choose between.

local Palette = require("src.palette")
local Background = require("src.background")
local Camera = require("src.camera")
local util = require("src.util")

local Scissors = {}
Scissors.__index = Scissors

local SNIP = 0.09   -- how long the blades' own flash lasts once they arrive
local DASH = 3      -- pixels of slit...
local GAP = 2       -- ...and pixels of paper between them
local TEAR = 1      -- and the same for the stretch past the taps, which is a
local TEAR_GAP = 3  -- tear running on rather than a pair of blades closing

-- How fast the blades close along the line, in pixels a second, with a floor
-- under how long that takes. A speed and not a duration, because a cut is the
-- same gesture at every length the line can be: the 128px it reaches by default
-- opens in about a sixth of a second and a cut running edge to edge takes nearly
-- half of one, which is the honest reading of a level that bought that much more
-- page rather than a penalty for having taken it. The floor is what keeps a short
-- snip from being over inside two frames.
local SPEED = 800
local MIN_SWEEP = 0.08

-- Pixels of cut per puff of fibre. Spaced by distance rather than dropped once a
-- frame, so a long cut sheds no more paper per pixel than a short one -- which at
-- SPEED comes out at about one puff a frame either way.
local FIBRE = 14

-- The circle asked of the horde has to hold the whole band plus the biggest body
-- that could be leaning into it, and 20 is the boss's radius -- the largest
-- thing on the page. The beam and the sword each keep one of these for the same
-- reason: there is no line query, so a line asks for a circle that contains it
-- and does the real test itself.
local SLACK = 20

-- A second tap this close to the first is not a cut, it is putting the scissors
-- down: the anchor is dropped and nothing is charged. That is deliberately the
-- same gesture as making a cut rather than a separate button to find in a panic,
-- and it is the whole of how a cut is called off.
Scissors.MIN = 6

-- Where the aimed stretch ends, which past the second level is wherever you
-- tapped. The reach is what keeps a tool that can be placed anywhere honest to
-- begin with: a cut can start on any pixel of the page but it can only run so
-- far, so up to that level the second tap is picking the *direction* rather than
-- the far end.
--
-- The level that lifts it writes `math.huge`, the cool S's trick for the cool
-- S's reason: every clause here goes on working untouched, and the bound that is
-- left is the honest one -- the pointer cannot leave the canvas, so "unlimited"
-- is a screen's diagonal rather than a promise about infinity.
local function clip(def, ax, ay, bx, by)
    local dx, dy = bx - ax, by - ay
    local d = util.len(dx, dy)
    if d <= def.reach then return bx, by end

    local s = def.reach / d
    return ax + dx * s, ay + dy * s
end

-- How far along the line through (ax, ay) the page's four edges are, as the two
-- parameters of the ray. Liang-Barsky: each edge is one inequality in t, and a
-- slab either moves an end of the range or -- for a line parallel to that edge
-- and outside it -- says there is no range at all.
local function clipToRect(ax, ay, dx, dy, left, top, right, bottom)
    local t0, t1 = -math.huge, math.huge

    local function slab(p, q)   -- p * t <= q
        if p == 0 then return q >= 0 end
        if p < 0 then t0 = math.max(t0, q / p) else t1 = math.min(t1, q / p) end
        return true
    end

    if not slab(-dx, ax - left) then return nil end
    if not slab(dx, right - ax) then return nil end
    if not slab(-dy, ay - top) then return nil end
    if not slab(dy, bottom - ay) then return nil end

    return t0, t1
end

-- The whole geometry of a cut, worked out from the anchor, the second point and
-- the page they are on: where the aimed stretch ends, where the cut itself
-- begins and ends once it is allowed to run past both taps, and where along that
-- run the aimed stretch sits.
--
-- One function, and it is worth keeping it one: the dotted line printed at the
-- second tap and the damage the blades do walking down it are the same
-- measurement rather than two that agree. The line the page is told to cut along
-- has to be the line the page is cut along.
function Scissors.measure(def, ax, ay, tx, ty)
    local bx, by = clip(def, ax, ay, tx, ty)

    -- Without `through` the cut *is* the aimed stretch, which is what makes the
    -- two-tier hit test and the two dash patterns below no-ops until that level
    -- lands rather than special cases anybody has to remember.
    if not def.through then return bx, by, ax, ay, bx, by, 0, 1 end

    local left, top, w, h = Camera.bounds()
    local dx, dy = bx - ax, by - ay
    local c0, c1 = clipToRect(ax, ay, dx, dy, left, top, left + w, top + h)
    if not c0 then return bx, by, ax, ay, bx, by, 0, 1 end

    -- Both taps are on screen by construction -- the pointer cannot be anywhere
    -- else -- so the clip can only widen the range. Held to that anyway, since a
    -- cut that failed to contain its own two taps would be one that missed what
    -- you aimed it at.
    c0, c1 = math.min(c0, 0), math.max(c1, 1)

    return bx, by,
           ax + dx * c0, ay + dy * c0,
           ax + dx * c1, ay + dy * c1,
           -c0 / (c1 - c0), (1 - c0) / (c1 - c0)
end

-- The line a pixel at a time, so it lands on the grid at every angle.
-- pixelart.line would plot it, but a cut is dashed rather than solid, the fade
-- drops pixels out of it, and the stretch past the taps is dashed differently
-- again -- all three read off the step index. The walk itself is that function's:
-- one sample per pixel of the longer axis, which is what stops a diagonal coming
-- out dotted.
local function eachPixel(ax, ay, bx, by, fn)
    local dx, dy = bx - ax, by - ay
    local steps = math.max(1, math.floor(math.max(math.abs(dx), math.abs(dy)) + 0.5))

    for i = 0, steps do
        local t = i / steps
        fn(i, math.floor(ax + dx * t), math.floor(ay + dy * t), t)
    end
end

-- The dash pattern down a cut: blades between the taps, a tear past them.
--
-- Which is the only thing on the page saying where the deep part of a cut is,
-- and it has to say it somewhere -- the compass's rule, that a choice you cannot
-- see is not one you can make. From the third level the stretch between your
-- taps is worth nearly twice the rest, and from the fourth there is a rest for it
-- to be worth more than, so the two are drawn as two different things: a cut,
-- and a page giving way on from it.
local function dashed(px, py, qx, qy, t0, t1, fn)
    eachPixel(px, py, qx, qy, function(i, x, y, t)
        local on, off = DASH, GAP
        if t < t0 or t > t1 then on, off = TEAR, TEAR_GAP end
        if i % (on + off) < on then fn(i, x, y) end
    end)
end

-- The anchor, waiting for its second tap: a cross, and nothing else at all.
--
-- Dotting the whole cut out from here, live off the pointer, is what this used
-- to do, and taking that away is the point rather than a saving. A guide you can
-- drag onto a blob turns a tool that is *led* into one that is aimed -- you line
-- the far end up on something and tap when it lights, which is the ruler's
-- gesture with an extra press in it. Without one the direction is something you
-- hold in your head, and the dotted line is printed at the moment the blades
-- follow it down (Scissors:draw). What it costs is that the reach becomes a bound
-- you cannot see, which is what doubling that reach to 128 pays for.
--
-- It is still the one guide in the game that outlives the press that started it
-- -- the anchor sits there until you take the second tap or put the scissors
-- away -- so it is drawn off the run's pending point rather than off an object,
-- there being no object until the cut is made. And the cross now carries all of
-- it: on a touch screen the pointer is left sitting on top of the anchor between
-- taps, so this is the only thing saying it is on the page at all.
function Scissors.drawPending(ax, ay)
    love.graphics.setColor(Palette.graphite)

    love.graphics.rectangle("fill", math.floor(ax) - 2, math.floor(ay), 5, 1)
    love.graphics.rectangle("fill", math.floor(ax), math.floor(ay) - 2, 1, 5)
end

-- `keepX/keepY` is where you are standing, and only the last level has any use
-- for it. It is read here and frozen here: which half of the page is the offcut
-- is decided when the blades close and never again, because a cut whose grey
-- half swapped over as you walked across your own line would be a page
-- flickering between two answers.
--
-- That half is also the one thing about a cut that does not wait for the blades.
-- It is off the page from the tap and it empties on its own clock from the tap,
-- because the travel is about the *cut* -- a line closing on a crowd that is
-- still walking -- and half a page that only came away once the blades reached
-- the far edge would spend the best part of a second being a finale that had not
-- happened yet. What that costs is a page in two along a line the blades are
-- still coming down, which reads as the tear leading them rather than as a
-- mistake.
function Scissors.new(def, ax, ay, tx, ty, keepX, keepY)
    local bx, by, px, py, qx, qy, t0, t1 = Scissors.measure(def, ax, ay, tx, ty)

    local cut = setmetatable({
        def = def,
        -- The stretch you aimed: the anchor, and the second tap.
        ax = ax, ay = ay, bx = bx, by = by,
        -- And the whole cut, which is those same two points until `through`.
        px = px, py = py, qx = qx, qy = qy,
        t0 = t0, t1 = t1,
        age = 0,
        snip = SNIP,
        seed = love.math.random() * 997,
        -- The blades' journey down that line: how far along they have closed,
        -- how long the whole length takes them, and the sword's `struck` set --
        -- one cut is worth one hit to a body however many frames it spends
        -- arriving. `age` does not start until they get there (Scissors:update).
        head = 0,
        sweepT = math.max(MIN_SWEEP, util.len(qx - px, qy - py) / SPEED),
        struck = {},
        fibres = 0,
    }, Scissors)

    if def.sever then
        local nx, ny = -(by - ay), bx - ax
        -- Zero rather than a full tick, so the first sweep of the offcut lands
        -- on the frame after the tap. The half is off the page from the moment
        -- the paper opens (Scissors:update says so, and it is the one part of a
        -- cut that does not wait for the blades) and the crowd standing on it
        -- should leave with it rather than half a second later -- that gap read
        -- as a bug every time it was watched.
        --
        -- **`follows` is a cut that goes on asking**, and it exists because one
        -- tool genuinely cannot answer the question here. "The half you are not
        -- standing on" is a sentence about a cut with you on one side of it, and a
        -- ruler's line goes *through* you (the GUILLOTINE in src/tools.lua): at the
        -- moment it lands you are standing on both halves, so there is no answer to
        -- freeze. What that row does instead is keep asking -- `Scissors:takeSides`
        -- re-reads it off your feet every frame -- so the half that goes is the half
        -- you walked away from, and while you are still straddling the slit neither
        -- goes. It is the same sentence read continuously rather than once.
        --
        -- Everything else is frozen at the tap, and should be: a cut you placed
        -- with two taps has a side you chose, and having it follow you afterwards
        -- would take a decision away rather than hand one over.
        if def.sever.follows then
            cut.severed = { nx = nx, ny = ny, want = 0, follows = true, tick = 0 }
        else
            -- Standing exactly on your own cut has to answer with something and
            -- either half is as good as the other; the >= is the arbitrary half of
            -- that, and it is arbitrary on purpose rather than by accident.
            local mine = (keepX - ax) * nx + (keepY - ay) * ny >= 0 and 1 or -1
            cut.severed = { nx = nx, ny = ny, want = -mine, tick = 0 }
        end
    end

    return cut
end

-- Is (x, y) on the offcut? The half the page keeps is the half you were standing
-- on, so this is the other one. The normal is left unnormalised, since only the
-- sign of this is ever asked for.
function Scissors:offcut(x, y)
    local sv = self.severed
    -- A `want` of zero is a cut that has not picked a half yet -- the strict `> 0`
    -- is what makes that mean "neither", with no clause of its own.
    return ((x - self.ax) * sv.nx + (y - self.ay) * sv.ny) * sv.want > 0
end

-- Which half the page keeps, re-read off the player's feet (`sever.follows`, set
-- above). Only a ruled cut asks -- everything else froze the answer at the tap.
--
-- **Straddling the slit keeps both halves**, and that is not a guard against
-- flicker so much as the honest answer: while any part of you is over the cut you
-- are standing on both sides of it, so there is no half you are not on and nothing
-- is lifted. `p.radius` rather than the cut's own `width` because the question is
-- about the body and not about the blades -- what the width measures is how far off
-- the line something may be and still be cut, which is a different question.
--
-- The normal is unnormalised, as it is everywhere else here, so the comparison is
-- scaled by its length rather than the dot product being divided by it: one
-- multiply against a square root, and the sign is all `offcut` ever asks for.
function Scissors:takeSides(game)
    local sv = self.severed
    local p = game.player
    local d = (p.x - self.ax) * sv.nx + (p.y - self.ay) * sv.ny
    local len = util.len(sv.nx, sv.ny)

    if len == 0 or math.abs(d) <= p.radius * len then
        sv.want = 0
    else
        sv.want = d > 0 and -1 or 1
    end
end

-- The stretch of line the blades have just crossed, and everything standing on
-- it. Called once a frame while the cut is travelling rather than once when the
-- cut is made, which is the sword's rule for the sword's reason: it is swept,
-- not stamped, and the `struck` set is what makes one cut worth one hit to a
-- body however many frames it spends arriving. What walks onto the line behind
-- the blades has walked into a slit, not into a pair of scissors.
--
-- Nothing is shoved. The knock is written as 0 in src/tools.lua rather than left
-- out, on the pen's terms: a cut separates rather than pushes, and the shove is
-- scaled by a multiplier (`scaleKnock` in src/loadout.lua), so the line stays at
-- 0 whatever is ever written on that axis. It is also the whole of what stops
-- this being a thin ruler. The ruler's shove is
-- what opens a corridor across the page; this leaves the crowd standing exactly
-- where it was with a gap cut through the middle of it.
--
-- Two tiers, one pass. The stretch between the two taps is the one you aimed, so
-- from the third level it hits harder and reaches further off the line than the
-- rest of the cut does; anything outside that band is tested against the cut at
-- the written numbers. Which is the compass's `bite` by another name -- the part
-- of the shape you got to choose is the part that is worth something -- and it is
-- what keeps the second level alive once the fourth has landed: the cut runs to
-- both edges whatever you do with the taps, so what they are really placing from
-- then on is the deep part. The blades arrive somewhere in an order now, so the
-- tier a body is cut by is whichever of the two got to it first.
--
-- Called `blades` and not `bite` on purpose. The compass's block already carries
-- a `bite`, that one is a bare multiplier, and `scaleDamage` walks every block in
-- src/tools.lua looking for damage by name -- so two fields of one name and two
-- shapes is one generic walk away from indexing a number. The word is also the
-- better one: between the taps is where the blades closed, and past them is where
-- the page tore.
--
-- The circle asked of the horde holds this frame's stretch rather than the whole
-- cut -- the beam's and the sword's bargain at a fraction of the size -- and that
-- is where the travel pays for itself. A cut running edge to edge used to ask for
-- a circle that was most of the page, once; it now asks thirty times for one a
-- dozen pixels across.
function Scissors:strike(game, u0, u1)
    local def = self.def
    local px, py = self.px, self.py
    local dx, dy = self.qx - px, self.qy - py

    local x0, y0 = px + dx * u0, py + dy * u0
    local x1, y1 = px + dx * u1, py + dy * u1
    local run = util.len(x1 - x0, y1 - y0)

    -- Fibres coming off the paper at the blades rather than all along the cut at
    -- once, which is the whole of what a travelling cut has to say for itself:
    -- the page is coming apart *where they are*.
    self.fibres = self.fibres + run
    while self.fibres >= FIBRE do
        self.fibres = self.fibres - FIBRE
        game.particles:burst(x1, y1, 2, Palette.graphite)
    end

    local deep, deepW = def.damage, def.width
    if def.blades then deep, deepW = def.blades.damage, def.blades.width end

    -- As much of the aimed stretch as this frame's run holds. Without `through`
    -- the aimed stretch *is* the cut, so this is all of it at every step and the
    -- two tiers stay the no-op they were until that level lands.
    local a0, a1 = math.max(u0, self.t0), math.min(u1, self.t1)
    local ax0, ay0, ax1, ay1
    if a1 > a0 then
        ax0, ay0 = px + dx * a0, py + dy * a0
        ax1, ay1 = px + dx * a1, py + dy * a1
    end

    game:eachWithin((x0 + x1) / 2, (y0 + y1) / 2,
                    run / 2 + math.max(def.width, deepW) + SLACK, function(e)
        if self.struck[e] then return end

        local hit
        if ax0 and util.distToSegment(e.x, e.y, ax0, ay0, ax1, ay1) < deepW + e.radius then
            hit = deep
        elseif util.distToSegment(e.x, e.y, x0, y0, x1, y1) < def.width + e.radius then
            hit = def.damage
        end

        if hit then
            self.struck[e] = true
            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(hit) then
                game:killEnemyAt(e)
            elseif def.ignite then
                -- Blades that leave what they cut burning (`ignite` on the block,
                -- the SCORCH in src/tools.lua): the marker's own burn block,
                -- delivered by the cut instead of by the band.
                --
                -- Only what survived the cut, which is the `elseif` and is the
                -- CUTOUT's rule (`loop.ignite` past `not e.gone`): setting fire to
                -- something that died on the same frame is a flame thrown for a
                -- body that is not there to carry it.
                --
                -- And the fire *is* carried -- it rides on the body and outlives
                -- the slit, so it goes with whatever the offcut then lifts into the
                -- corner (Game:liftEnemyTo). That is the pairing: the cut hands the
                -- crowd the length of the page to walk back, on fire.
                game.particles:flame(e.x, e.y)
                e:ignite(def.ignite)
            end
        end
    end)
end

-- Everything standing on the offcut, once a tick, while the page is in two --
-- and what happens to it is that it *goes*.
--
-- Not a death and not damage. The paper is off the page and so is whatever was
-- standing on it -- carried off with it and set down again in the far corner of
-- the half the page kept, whole: no gem, no xp, nothing split and nothing burst,
-- because nothing was hurt. Game:liftEnemyTo is the whole contract and the
-- argument for it. What the level sells is the *walk back*, which is a thing this
-- game has never sold before -- every other way of clearing ground in here either
-- kills for it or shoves for a moment.
--
-- It stays a clock rather than becoming one event, and that is the half worth
-- reading twice: the offcut goes on lifting whatever walks onto it for as long as
-- the cut is on the page, so the half you are not standing on is not *cleared*,
-- it is shut. Walk the crowd at it and the crowd comes out in the corner. The
-- first tick fires on the frame after the tap (`tick = 0` in Scissors.new), so
-- the page clears when the paper does rather than half a second behind it.
--
-- Twice a second rather than every frame, which is affordable for the bomb's
-- reason rather than the sun's -- and it is still a clock rather than a single
-- pass because the region has to keep answering for arrivals, which is the same
-- thing it was a clock for when it was damage. Nothing ping-pongs on that clock:
-- a body is put down where the offcut is not, so the next tick only finds it
-- again if it has walked back over the slit on its own feet.
--
-- The viewport rather than a circle round something: a half-plane has no centre
-- and there is no query in the game shaped like one, so this asks for the circle
-- that holds the page and does the real test itself -- the beam's bargain with a
-- much bigger shape.
--
-- And it is clipped to what is on screen, which is the sun's rule and matters
-- more here than anywhere else it is applied. Half a page has no far end, so
-- without the clip this would quietly be hauling bodies a page and a half away
-- into a corner nobody is looking at -- and it would be doing it to a crowd the
-- player was walking *away* from, which is the horde's budget being spent to no
-- effect anyone can see.
--
-- Where the crowd is put down is asked once for the whole sweep and not once per
-- body (`Game:clearCorner`), which is what makes them all arrive out of the same
-- corner -- and it is asked of the *run* rather than of this cut, so the corner is
-- clear of every hole on the page and not just of this one. A page in ribbons is a
-- real thing (three pins are three cuts, the PUNCH), and a cut that only knew its
-- own half would be handing bodies to the hole next door twice a second.
--
-- Nowhere clear means nothing is lifted at all this tick, and the sweep is skipped
-- rather than run to no purpose: that is the page having no paper left on screen,
-- which is you standing out on your own offcut.
function Scissors:lift(game)
    local corner = game:clearCorner()
    if not corner then return end

    local left, top, w, h = Camera.bounds()
    -- What the offcut does to the crowd *on arrival*, which is one field and only
    -- one row writes it (`sever.paste`, the COLLAGE in src/tools.lua): the paste
    -- goes with the paper, so what is set down in the corner is set down stuck.
    -- It is the one thing in the game done to a body by the region that moved it
    -- rather than by the ground it landed on, and it is the gluestick being itself
    -- -- a cut that carries the crowd off is a cut that can carry paste with it.
    --
    -- No glue block is handed over with the seconds, and that is deliberate rather
    -- than an omission: `Enemy:freeze` leaves whatever glue the body is already
    -- carrying in place, so a body the smear had pasted before the cut keeps its
    -- softening while it stands in the corner, and one the cut caught on clean
    -- paper is simply stuck. The paste is on the page you cut; the hold is what
    -- travels.
    local paste = self.def.sever.paste

    game:eachWithin(left + w / 2, top + h / 2, util.len(w, h) / 2, function(e)
        if not self:offcut(e.x, e.y) then return end
        if e.x < left or e.x > left + w or e.y < top or e.y > top + h then return end

        -- Asked rather than assumed: the door refuses the boss, and gluing the one
        -- thing it would not move is holding the eye still where it already stood.
        if game:liftEnemyTo(e, corner) and paste then e:freeze(paste) end
    end)
end

-- Returns false once the page has closed back up.
--
-- Which is also when the offcut comes back, and that is the finale rather than a
-- limitation of it: the page is in two *for as long as the cut is on it*, so
-- keeping half a page lifted is something you do by going on cutting rather than
-- something one tap buys outright. The ink meter is then what limits how much of
-- a page a run can keep severed, which is the right place for that limit to sit.
function Scissors:update(dt, game)
    -- The travel is its own clock and the fade's does not run under it. A cut
    -- whose life started at the tap would be one whose slit was already going
    -- grey behind the blades by the time they reached the far edge -- and the
    -- longer the cut, the more of its own life it would have spent closing.
    if self.head < 1 then
        local from = self.head
        self.head = math.min(1, from + dt / self.sweepT)
        self:strike(game, from, self.head)
        -- The frame the blades arrive is the frame nothing more can be cut --
        -- matches the hold taken out in Game:closeCut / Game:chordCut, see
        -- src/multikill.lua.
        if self.head >= 1 then game.multikill:release() end
    else
        self.age = self.age + dt
        self.snip = math.max(0, self.snip - dt)
    end

    local sv = self.severed
    if sv then
        if sv.follows then self:takeSides(game) end
        sv.tick = sv.tick - dt
        if sv.tick <= 0 then
            sv.tick = self.def.sever.tick
            -- Nothing to sweep while the cut has not picked a half: `offcut` would
            -- answer false for the whole page, and asking the horde for a circle
            -- the size of the page to be told so is the one cost worth skipping.
            if sv.want ~= 0 then self:lift(game) end
        end
    end

    return self.age < self.def.life
end

-- The half of the page this cut has taken off it, laid into the *page* layer
-- rather than into the ink over it -- because it is not a mark, it is the page
-- not being there.
--
-- What goes down is not a colour but the page itself, rebaked: the ruling
-- exactly where it was printed and grey where the paper between it used to be
-- (`Background.torn`). The scissors take the paper away and not the printing on
-- it, so a rule that ran across the offcut still runs across the offcut -- which
-- includes the vertical mark every page in the book carries a page width apart,
-- the one thing that tells you you are walking, so the offcut goes on telling
-- you that too. What says the half is gone is the white going out of it, and on
-- a page that is mostly white that is most of the page.
--
-- Graphite is a page surface for exactly that reason (`Palette.surfaces`), so
-- ink landing on the offcut stacks on it the way ink stacks on blank paper and
-- nothing in the overprint pass has to guess. It has to be laid here and not in
-- the ink layer for the same reason: grey drawn as a *mark* would be paired with
-- the page under it, so it would come out as some ninth thing over a rule, and
-- ink laid on top of it afterwards would go on stacking against the paper it had
-- covered.
--
-- Filled a row at a time, one stripe per row, which is `pixelart.band`'s trick
-- and for its reason: a half-plane at an angle plotted a pixel at a time does
-- not tile and comes out with holes in it, where a span is contiguous by
-- construction. It also lands on whole pixels with no rotation anywhere near it,
-- and it is what lets each row be a slice of a wrapped texture -- the page and
-- its offcut are the same world coordinates, so the ruling lines up across the
-- cut with nothing having to arrange it.
function Scissors:drawSever(left, top, w, h)
    local sv = self.severed
    -- No half picked, so no half is missing. Guarded here rather than left to the
    -- arithmetic below, which would read a `want` of zero as one of the two signs
    -- and tear off whichever it happened to be.
    if not sv or sv.want == 0 then return end

    local ax, ay = self.ax, self.ay
    local nx, ny, want = sv.nx, sv.ny, sv.want
    local x0, y0 = math.floor(left), math.floor(top)
    local x1, y1 = x0 + w, y0 + h

    -- A cut with no run in y crosses no row of the page, so every row is wholly
    -- in or wholly out -- there is no boundary to solve for, and solving for one
    -- would be dividing by nothing.
    if nx == 0 then
        for y = y0, y1 do
            if (y - ay) * ny * want > 0 then
                Background.torn(x0, y, w + 1)
            end
        end
        return
    end

    -- Which end of a row the offcut is on follows from two signs together: which
    -- side of the line the page keeps, and whether the line's own measure grows
    -- or shrinks across the page.
    local rightward = (nx > 0) == (want > 0)

    for y = y0, y1 do
        local bound = ax - (y - ay) * ny / nx
        if rightward then
            local from = math.max(x0, math.floor(bound))
            if from <= x1 then
                Background.torn(from, y, x1 - from + 1)
            end
        else
            local to = math.min(x1, math.ceil(bound))
            if to >= x0 then
                Background.torn(x0, y, to - x0 + 1)
            end
        end
    end
end

-- The cut, on the page and under everything standing on it.
--
-- The opening is drawn in paper, which is the one colour that wipes what is
-- under it rather than stacking with it (src/overprint.lua): the ruling really
-- does stop at the slit, so what is there is the page opened rather than a pale
-- line laid on top of it. Dashed, because a cut is where the blades closed and
-- the bits between are where they were opening again.
--
-- And the opening is only half of it. Paper on paper shows up nowhere but where
-- it happens to cross a ruling, which on the unruled page is nowhere at all, so
-- the mark is two pixels: the opening and the dark edge of it lifting, one pixel
-- to the side. That is what a cut in paper looks like and it is what makes this
-- readable on every page in the book.
--
-- It still fades, down a ramp and dithering out like every other mark, and the
-- ramp is the page closing: open paper, then a graphite crease with nothing left
-- open to cast an edge, then gone. A cut left there for good would be a page with
-- the ruling permanently missing out of it, and the pushpin and the staple are
-- the only two things in the game allowed to stay.
function Scissors:draw()
    -- The blades on their way down the line. Ahead of them is the dotted line
    -- printed at the second tap -- "cut along the dotted line", in graphite, in
    -- the same two dash patterns the slit itself will fade out in, so what is
    -- promised is drawn as the thing that arrives. Behind them is red, solid, for
    -- the ruler's reason: the flash is the impact rather than the mark, and red
    -- is what an impact is everywhere else on the page.
    --
    -- The whole line is dotted every frame and the red laid over it, rather than
    -- the dots being drawn from the head forward. A dash pattern is counted from
    -- the start of whatever it is given, so a guide redrawn each frame from a
    -- moving head would shimmer its way down the page.
    if self.head < 1 then
        love.graphics.setColor(Palette.graphite)
        dashed(self.px, self.py, self.qx, self.qy, self.t0, self.t1,
            function(_, x, y) love.graphics.rectangle("fill", x, y, 1, 1) end)

        love.graphics.setColor(Palette.red)
        eachPixel(self.px, self.py,
            self.px + (self.qx - self.px) * self.head,
            self.py + (self.qy - self.py) * self.head,
            function(_, x, y) love.graphics.rectangle("fill", x, y, 1, 1) end)
        return
    end

    -- And then the whole length at once for the two frames after they arrive,
    -- which is the moment the cut is a cut: closed along all of it, before the
    -- page starts closing back up.
    if self.snip > 0 then
        love.graphics.setColor(Palette.red)
        eachPixel(self.px, self.py, self.qx, self.qy, function(_, x, y)
            love.graphics.rectangle("fill", x, y, 1, 1)
        end)
        return
    end

    local def = self.def
    local f = self.age / def.life
    local ramp = def.ramp
    local core = ramp[math.min(#ramp, math.floor(f * #ramp) + 1)]

    local dither = 0
    if f > def.fade then dither = (f - def.fade) / (1 - def.fade) end

    local function eachDash(fn)
        dashed(self.px, self.py, self.qx, self.qy, self.t0, self.t1,
            function(i, x, y)
                if dither > 0 and util.hash01(i, self.seed, 31) <= dither then return end
                fn(x, y)
            end)
    end

    -- The edge first, so each colour goes down in one pass and the opening is
    -- what is on top of it. The offset is the perpendicular rounded to an axis,
    -- which for a single pixel is exactly what the perpendicular is.
    --
    -- Tested by identity against the palette rather than off the fraction: the
    -- ramp holds the palette's own tables, so this really is asking whether the
    -- slit is still open rather than agreeing separately with where the ramp
    -- steps.
    if core == Palette.paper then
        local ox, oy = 0, 1
        if math.abs(self.qx - self.px) < math.abs(self.qy - self.py) then
            ox, oy = 1, 0
        end
        love.graphics.setColor(Palette.graphite)
        eachDash(function(x, y)
            love.graphics.rectangle("fill", x + ox, y + oy, 1, 1)
        end)
    end

    love.graphics.setColor(core)
    eachDash(function(x, y) love.graphics.rectangle("fill", x, y, 1, 1) end)
end

return Scissors
