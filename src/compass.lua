-- A pair of compasses, stood in the page and swung.
--
-- The fourth way a tool can be used. A brush is dragged and the mark is
-- wherever you dragged it; a pin is tapped and lands where you tapped; a ruler
-- is aimed about the player and comes down when you let go. A compass is
-- *opened*: press and the needle goes into the page right there, drag and the
-- pencil leg opens out to however wide you want the circle, let go and it
-- draws.
--
-- One gesture, and the same one the real instrument is set with -- the needle
-- stays where you put it and the other leg swings out from it. It also means
-- the circle is placed before it is sized, which is the opposite way round from
-- every other tool here: everywhere else you commit to where a mark goes by
-- dragging, and the size is whatever the drag came to.
--
-- **What it cuts is the line it draws**, and nothing inside it. A body has to be
-- standing on the rim -- `width` off it, plus its own radius -- so the circle is
-- a fence rather than a blast, and the middle of one is the safest place on the
-- page to be. That is the whole shape of the tool: everything else here reaches
-- an area and this reaches a *perimeter*, which at the widest it opens is by a
-- long way the longest line in the game and the only closed one. (Five tools take
-- that back and every one of them costs a fusion: the LASSO cuts the middle when
-- the ring closes -- see `Compass:ring` -- the PUNCH takes it off the page
-- altogether, crowd and all -- see `Compass:lift` -- the MOAT's and the
-- SPINDLE's rims are wider than the smallest circle they can draw, so opened
-- right down they cover their own middles, and the
-- CLEARING drops the rim test outright and empties the whole disc it has swept --
-- see `wipe` in `Compass:cut`. None of them is the plain compass, and none of them
-- is free.)
--
-- Which makes it the slowest thing in the game to bring to bear, and the only
-- one whose hit you can watch travel. Nothing happens at the moment you release:
-- the lead sets off from wherever you left it resting and cuts what it passes
-- over as it arrives there, so the far side of a wide circle has most of a turn
-- to walk out of it -- and can see the arm coming the whole way round. It is
-- the one attack in the game that is a promise for most of a second.
--
-- It is also the only tool that reaches away from the player. The ruler pivots
-- about you and the crayon lane starts under your feet; a compass is stood
-- wherever you tapped, which means the circle can be drawn round a crowd you
-- are not standing in. The screen is the whole of the limit on that, exactly as
-- it is for the pushpin.
--
-- The needle is what costs. It goes in on the press and the ink goes with it,
-- so a compass that has been opened always draws its circle: if something else
-- takes it away first -- a tool change, the pause -- it swings at whatever width
-- it had reached rather than handing the ink back.
--
-- Everything the upgrade line adds is a variation on that one journey rather
-- than a new thing the tool does: the leg bites hardest over the first stretch
-- of it, it may go round more than once, and a second leg may set off the other
-- way. All three are read off the sweep block, and none of them changes what the
-- gesture is.
--
-- **And what the leg is carrying is not always a bare lead.** A tool that is a
-- brush as well as a sweep -- four of the fusions, a marker or a pencil or a
-- gluestick or a pen put into the compass (the HALO, the LASSO, the MOAT and the
-- CORRAL, src/tools.lua) -- puts a nib on the end of the arm, and then the arm draws: one Stroke per leg, dragged round behind the lead
-- exactly as your own hand drags one, so the ring it leaves is a real mark with
-- the brush's own life, linger, stacking and fire on it and nothing here has to
-- know what any of that does. A compass drawing a mark rules no circle of its own
-- at all -- the mark *is* the ring, it ages off the page on the brush's terms,
-- and the block's `life`, `fade` and `ramp` are the bare pencil circle's and go
-- unwritten.
--
-- **And the mark is not always an attack.** A leg carrying the pen lays *terrain*
-- -- a line the crowd cannot cross -- and that is the only thing a leg has ever
-- carried that this file owes two lines to rather than none. A wall is only a wall
-- once it is in the segment index, and that index is rebuilt when it is dirty:
-- Game:updateDrawing dirties it for the line your hand is drawing, and nothing was
-- dirtying it for a line an arm draws, so `Compass:layBands` says so as it lays.
-- And the pen's last level holds the wall laid last with no clock on it, so
-- `Compass:swing` claims that hold for both halves of its ring exactly as a hand
-- claims it for one line (Game:holdWalls). Everything else the fence does -- the
-- sting, the fade, the pop as it goes -- belongs to the mark, and none of it is
-- here.
--
-- **And what the leg is carrying need not be a nib either.** A row may put a
-- whole tapped tool on the end of the arm -- a `drop` block beside the sweep (the
-- SPINDLE, src/tools.lua) -- and then the leg is a pushpin: the rim punches the
-- crater's own width out of the horde the whole way round, the point picks up the
-- first body it fails to kill and carries it, and the turn ends with a real pin
-- driven through it into the page. `Compass:pickUp` is one clause of `Compass:cut`,
-- and `Compass:haul` and `Compass:nail` are the other half. It is the only thing
-- in this file that reaches out and *moves* an enemy rather than hitting or
-- shoving one, and the reason it is allowed to is that a carried body is frozen
-- every frame it is carried: what moves it is the only thing moving it.
--
-- **And what it is carrying may be a tool that puts nothing anywhere at all.** A
-- rubber is the one brush in the game with no mark to leave (the CLEARING,
-- src/tools.lua), and a leg carrying one does not cut the line it draws: it empties
-- the disc behind it, throwing what it finds straight out of the circle and
-- launching it. That is one branch in `Compass:cut` and one in `Compass:fleck`, and
-- it is the only row that changes what a sweep *reaches* rather than by how much --
-- the geometry the comment on `Compass:cut` calls a bug, restored deliberately for
-- the one tool whose hit was never an edge.
--
-- **And one row hangs nothing on the arm at all.** The leg carries the bare lead
-- it always did, the ring it rules is the plain pencil circle, and what the fusion
-- added is not on the instrument -- it is on the *page* (the FOLD, src/tools.lua).
-- Two circles that overlap cross at exactly two points, and a `snap` block beside
-- the sweep is what says the ruler comes down on the line between them: so a ring
-- closing looks round for another one still lying on the paper, and the pair of
-- them rule the chord. `Compass:crossed` and `Compass:crease` are the whole of it,
-- and they are the only place in this file that has ever looked at a *second*
-- compass. Everything else a sweep does, it does alone.
--
-- **The one thing a nib brings back here** is `Compass:ring`: a leg carrying the
-- pencil's last level closes a lasso every lap, and what a compass closed is a
-- circle, so the sweep resolves it off the radius it already has rather than
-- leaving a stroke to notice its own path coming back round. It is the only place
-- in this file that reads a field off the row rather than off the block, and the
-- comment there says why the stroke cannot be the one to do it.

local Palette = require("src.palette")
local Background = require("src.background")
local Camera = require("src.camera")
local Sprites = require("src.sprites")
local pixelart = require("src.pixelart")
local Stroke = require("src.stroke")
local util = require("src.util")

local Compass = {}
Compass.__index = Compass

local TAU = math.pi * 2
local DASH = 3        -- pencil dashes the guide circle is ruled out with
-- Both ways round, for the passes that do not care whether the second leg
-- exists: a leg carrying nothing is nothing to do, and a table walked every
-- frame is a table worth not allocating every frame.
local LEGS = { 1, -1 }
-- How long a body impaled on a moving point stays put, renewed every frame it is
-- carried (Compass:haul). Short on purpose: it is the *carry* rather than the
-- hold, so a rider the arm somehow never nails shakes it off in a quarter second
-- -- and it has to survive a frame at the worst `hold` a boss brings to it, which
-- is what stops this being 0.05.
local CARRY = 0.25
-- The least time between two presses of a seam being *heard* (Compass:seams). A
-- rim at full width holds thirty-four of them and comes round in under a second,
-- and thirty-four of one sound in a second is not a stapler, it is a machine gun.
-- Nine hundredths is about ten a second, which is a stapler being worked as fast
-- as a hand could work one -- and every press still lands, it is only the sound
-- that thins out.
local CLACK = 0.09
-- The least two needles may be apart and still be two needles (Compass:crossed).
-- The chord a pair of circles rules is square to the line joining their centres,
-- so that line is where its direction comes from -- and a direction read off a gap
-- of four pixels is not a direction, it is a rounding error. It is the same number
-- and the same argument as `DEAD` in src/ruler.lua, which is the distance a pointer
-- has to be off the pivot before it is taken to be aiming at all.
--
-- Which also disposes of the one degenerate pair the two inequalities there let
-- through: the same circle drawn twice over. Two rings on top of each other overlap
-- everywhere and cross nowhere, and what the arithmetic returns for them is a
-- diameter's worth of ruler lying at whatever angle the last pixel of drift
-- happened to point.
local APART = 4
local SPECK = TAU / 10 -- radians between flecks of graphite off the lead
local NEEDLE = 5      -- how far the needle stands out of the page

-- How many points get plotted round the rim. Fixed for a given radius, so a
-- point keeps its index for the whole life of the mark -- which is what lets
-- the dither pick the same ones every frame as it fades, instead of boiling.
local function stepsFor(r)
    return math.max(24, math.floor(TAU * r * 1.5))
end

-- How many presses a rim of this radius holds, one every `every` pixels of it.
-- The stapler's seam spacing read round a circle instead of along a drag (the HEM
-- in src/tools.lua), so a wider circle really is more staples and not the same
-- number spread thinner -- which is what makes the drag worth pricing.
--
-- At least one, so the arithmetic has no hole in it at a radius nothing can
-- actually draw: the smallest circle a compass opens is 16 and holds eight.
function Compass.seamCount(r, every)
    return math.max(1, math.floor(TAU * r / every))
end

-- And the widest rim that holds exactly `n` of them, which is the inverse and has
-- one caller: the cap on how far the drag may open (Game:sweepReach). Exact rather
-- than a search, and exact in the direction that matters -- the radius it returns
-- floors to `n` presses on the nose, so the price the drag was capped against is
-- the price the swing charges.
function Compass.seamRadius(n, every)
    return n * every / TAU
end

-- The whole tool rather than just its block, because a leg carrying a nib draws
-- with the brush fields on the row beside it. `def` stays the name everything
-- else here (and Game:swingCompass) reads the sweep numbers off.
function Compass.new(tool, x, y)
    local def = tool.sweep
    return setmetatable({
        tool = tool,
        def = def,
        x = x, y = y,       -- the needle: wherever you tapped
        radius = def.minR,
        start = 0,          -- where the lead rests, and so where it sets off from
        steps = stepsFor(def.minR),
        setting = true,     -- still open in your hand
        swept = 0,          -- radians come round so far
        -- A lap is the circle closed, not a leg going all the way round: two
        -- legs each walk half of it and meet on the far side. That is what
        -- makes the second leg worth a level -- the rim is finished in half the
        -- time -- and it is why nothing below measures a lap against TAU.
        span = TAU / (def.counter and 2 or 1),
        total = TAU * def.laps / (def.counter and 2 or 1),
        lap = 0,            -- which time round the hit list belongs to
        -- The disc the closed ring has taken off the page, if the leg is carrying
        -- blades (`sever` in the block, the PUNCH in src/tools.lua), and the
        -- clock it clears on. Opened by the first lap to close and never closed
        -- again: the page is in two for as long as the cut is on it, which here is
        -- until the ring itself has faded and this object is dropped.
        severed = false,
        severT = 0,
        -- What each leg is carrying, if the leg has a point on the end of it
        -- rather than a nib or a lead (`drop` on the row, the SPINDLE in
        -- src/tools.lua): dir -> the body impaled on it. One per leg and never
        -- more, which is the pushpin's own reading of a point -- it takes the one
        -- body it came down on and the crater takes the rest.
        rider = {},
        -- Where a leg that *presses as it travels* is due to press next, if the
        -- tool on the arm is one that rakes (`drop.rake`, the HEM in
        -- src/tools.lua): a list of {at, dir} in the order the arm reaches them,
        -- built once the width is known (Compass:loadSeam) and walked with a
        -- cursor rather than searched. Nothing here for a leg carrying its drop
        -- rather than working it.
        seam = nil,
        next = 1,
        clack = 0,
        -- And what the point has killed this lap, which is weight behind it
        -- (`drive`). Reset with the hit list, since a lap is the unit a compass
        -- measures everything in.
        kills = 0,
        age = 0,
        hit = {},
        speck = SPECK,
        seed = love.math.random() * 997,
    }, Compass)
end

-- How far you have dragged from the needle is how wide it is, and the direction
-- you dragged in is where the lead is left resting -- which is where it sets off
-- from. So one drag picks the size of the circle and which part of it gets cut
-- first, and there is nothing else to aim.
--
-- The drag starts on the needle, so a press with no drag in it at all is a
-- circle at the minimum width: the quickest thing the tool can do, and still a
-- deliberate one, since the whole meter price was paid to press at all.
-- `reach` is how far the drag is allowed to open it, for the one row whose width
-- is priced rather than free (`sweep.per`, the HEM in src/tools.lua): the meter
-- decides how much wire the arm is carrying, so the leg stops opening where the
-- ink runs out. Everything else passes nothing and opens to `maxR`.
function Compass:reachTo(px, py, reach)
    local dx, dy = px - self.x, py - self.y
    local d = util.len(dx, dy)

    local most = math.min(self.def.maxR, reach or self.def.maxR)
    self.radius = util.clamp(d, self.def.minR, math.max(self.def.minR, most))
    self.steps = stepsFor(self.radius)

    -- A pointer sat on the needle has no direction in it; keeping the last
    -- angle is what stops the leg spinning as the drag leaves the anchor.
    if d > 1 then self.start = math.atan2(dy, dx) end
end

-- Let go, and the arm sets off. A leg with a nib on it opens a stroke at the
-- lead's rest point on the way -- the band starts where the lead is standing,
-- not at the needle -- and it goes into the run's own stroke list rather than
-- being held here, so from the moment it exists it is one more mark on the page:
-- it ticks, it burns, it fades and it is drawn under the crowd with all the
-- others, and this file never touches any of that again.
--
-- One per leg. The two share nothing, which is the honest reading of a second
-- leg -- there really are two nibs on the paper -- and it is what makes the
-- counter level worth as much to a banded compass as it is to a pencil one.
function Compass:swing(game)
    self.setting = false

    -- The arm has been paid for and planted, but every hit it deals -- a band
    -- cutting through the crowd, a seam of staples, a pin driven off the end
    -- of it -- is still `def.turn` seconds of real time away, all of it after
    -- the press that started this gesture has already been released
    -- (Game:swingCompass is called from the release edge). Held open here so
    -- a wide sweep still earns its word instead of arriving after
    -- Multikill has already closed the gesture; released the frame the arm
    -- actually stops (below, where `self.swept` reaches `self.total`).
    game.multikill:hold()

    -- Before the early return below, because a leg that works a stapler has no
    -- nib and no mark: the width is final now, and the width is what says how
    -- many presses there are and where (Compass:loadSeam).
    if self:seams() then self:loadSeam() end

    if not self.tool.stamp then return end

    self.bands = {}
    for _, dir in ipairs(self.def.counter and { 1, -1 } or { 1 }) do
        local ox, oy = self:leadAt(dir)
        local band = Stroke.new(self.tool, self.x + ox, self.y + oy)
        -- A ring the arm rules closes as a *lap*, and `Compass:ring` below is
        -- what resolves it: the sweep knows the circle exactly, where a stroke
        -- has to notice its own path coming back to itself. So a mark opened here
        -- never claims that event, however much `loop` its tool carries -- with
        -- two legs neither stroke has closed anything at the moment the circle
        -- has, and being surrounded is one thing happening once.
        band.lassos = false
        game.strokes[#game.strokes + 1] = band
        self.bands[#self.bands + 1] = { stroke = band, dir = dir }
    end

    -- And a leg carrying a *pen* has just laid a fence, so the ring claims the
    -- pen's own last level exactly as a line drawn by hand claims it (`keep`, the
    -- CORRAL in src/tools.lua): the last ring swung stays on the page with no
    -- clock on it, and swinging again is what lets it go. Both halves are handed
    -- over together, because a finished compass rules the circle as one mark per
    -- leg and half a ring held would be a fence with a hole in it.
    --
    -- Asked on `wall` rather than on `keep`, which is Game:updateDrawing's own
    -- order and load-bearing for its reason: laying a wall releases the held one
    -- whether or not the new one is held in its turn, or a run that lost the tool
    -- would leave a fence nothing could ever release.
    if self.tool.wall then
        local held
        if self.tool.keep then
            held = {}
            for _, band in ipairs(self.bands) do
                held[#held + 1] = band.stroke
            end
        end
        game:holdWalls(held)
    end
end

-- The nibs dragged up to where their leads now are. Called once a frame off the
-- swept angle rather than stepped round with the cut, because the lead's
-- position is a pure function of that angle: a frame's worth of arc is a few
-- pixels of chord at the widest the tool opens, which is under a pixel off the
-- circle and well inside the width of the band being laid.
--
-- The budget is unbounded because the meter was already emptied at the needle:
-- the whole price of a sweep is paid on the press, and a band the arm ran out of
-- half way round would be a tool charging twice for one gesture.
function Compass:layBands(game, dt)
    if not self.bands then return end

    for _, band in ipairs(self.bands) do
        local ox, oy = self:leadAt(band.dir)
        band.stroke:extend(self.x + ox, self.y + oy, math.huge, game, dt)
    end

    -- The fence grew with the arc, so the index the crowd walks by has to be
    -- rebuilt with it -- the one thing Game:updateDrawing does for a line your
    -- hand is drawing that nothing was doing for a line an arm draws (`wall`, the
    -- CORRAL in src/tools.lua). The flag rather than the rebuild, because that is
    -- how a drawn line asks too: the whole point of Walls:rebuild being dirty-
    -- driven is that it happens once a frame at most however many marks grew.
    --
    -- It is picked up at the top of the *next* frame, since the drawing pass runs
    -- before this one -- so the crowd feels a new stretch of ink one frame after
    -- it goes down. That is a few pixels of arc, on a body that Enemy:resolveWalls
    -- lifts back off the ink the moment the segment does arrive.
    if self.tool.wall then game.wallsDirty = true end
end

-- Everything the leg passed over between one frame and the last, and *passed
-- over* is meant literally: what a compass cuts is the line it draws. A body has
-- to be standing on the rim -- within `width` of it, plus its own radius, which
-- is the ruler's and the scissors' word for the same measurement -- and the
-- middle of the circle is not cut at all.
--
-- It used to be the whole filled disc, and that was a bug wearing the shape of a
-- feature: the angle test was doing all the work and the distance test only
-- asked whether a body was *inside*, so the leg swept the page like a radar
-- wiper and took everything behind it. Which made the tool a delayed pushpin
-- with a bigger crater, and quietly cost three of its four levels their
-- argument -- opening the circle out bought area for free, so the first level had
-- no trade in it at all, and the second leg bought nothing but tempo because
-- stepping off the rim left you inside the disc anyway. A ring is what the tool
-- was always described as and drawn as; this is the hit test agreeing.
--
-- **One row asks for that disc back and gets it** (`wipe`, the CLEARING in
-- src/tools.lua), and none of the four objections above survives the asking. What
-- it deals is the rubber's 2 rather than the compass's 12, so the area is not
-- buying damage for free -- it is buying a *shove*, which is the one thing that has
-- to reach an area to mean anything, and it kills nothing on its own. The tool it
-- borrows was never an edge: a rubber clears the patch it went over, and one that
-- touched only what stood exactly on a line it ruled would not be a rubber. The
-- level that does lose its argument is the compass's third -- cutting far deeper on
-- the second lap -- and the row says so out loud rather than quietly.
--
-- The stretch of turn is measured round from where the lead set off rather than
-- in absolute angles, so it only ever runs forwards and the stretches tile the
-- turn exactly: nothing is cut twice, and nothing is skipped however fast the
-- arm is moving. An enemy that wanders in behind the lead is not cut, because
-- the lead has been past.
--
-- A second leg, if the run has drafted one, covers the same band measured the
-- other way round -- so the two of them set off together and meet on the far
-- side, and the circle is closed in half a turn instead of a whole one. They
-- share the hit list, because what the two legs buy is the far side being
-- reached sooner rather than everything being cut twice.
--
-- `closes` says this band finishes the lap, and it is what keeps the promise
-- above honest once there are two legs: they divide the turn at exactly one
-- angle each, and something standing dead on the join would otherwise fall
-- between the two of them rather than be cut by either.
function Compass:cut(game, from, to, closes)
    local def = self.def

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        -- Nor anything already on the point. A rider travels *with* the lead, so
        -- it sits on the rim at every angle the leg ever reaches -- it would be
        -- re-cut every lap, or not, depending on which side of a float the leading
        -- edge fell, which is no way to decide a hit. Being carried is the hit it
        -- took.
        if not self.hit[e] and not self:rides(e) then
            local dx, dy = e.x - self.x, e.y - self.y
            -- On the rim rather than inside it, which for every tool but one
            -- means the middle of the circle is out of reach of its own edge.
            -- The one is the MOAT (src/tools.lua): its rim is as wide as the
            -- 20px head of paste the leg is carrying, against a smallest circle
            -- of 16, so opened at the minimum the ring genuinely does close over
            -- its own middle. What that costs is a body standing exactly on the
            -- needle, where there is no direction to read: `atan2(0, 0)` is 0, so
            -- it is taken to be resting at absolute zero and gets cut when
            -- whichever leg covers that angle arrives -- once a lap, at a moment
            -- nobody can point at, in the middle of a disc that is entirely paste
            -- either way. A wrong-looking answer would need a right-looking one to
            -- be visible, and at that radius there is no visible difference.
            local d = util.len(dx, dy)

            -- Standing on the rim -- or anywhere inside it, for the one row that
            -- empties the disc instead of cutting the line round it (`wipe`, the
            -- CLEARING in src/tools.lua). That is the geometry the paragraph above
            -- calls a bug, restored on purpose for the one tool whose hit was never
            -- an edge: you do not cut with a rubber, you clear the patch you went
            -- over with one. `width` still means what it means everywhere else,
            -- measured from the disc rather than from the line -- out to the rim and
            -- that much past it, because a tip 15 across clears a little past the
            -- circle it ruled.
            local reaches
            if def.wipe then
                reaches = d <= self.radius + def.width + e.radius
            else
                reaches = math.abs(d - self.radius) <= def.width + e.radius
            end

            if reaches then
                local a = math.atan2(dy, dx)
                local round = (a - self.start) % TAU

                -- Which leg reached it, and how far round that leg had come
                -- when it did. Nothing is left of the second one when the tool
                -- has only the one, since `back` is never tested.
                local dir, at
                if round >= from and (round < to or (closes and round <= to)) then
                    dir, at = 1, round
                elseif def.counter then
                    local back = (-round) % TAU
                    if back >= from and (back < to or (closes and back <= to)) then
                        dir, at = -1, back
                    end
                end

                if dir then
                    self.hit[e] = true

                    -- Dragged round the circle rather than shoved out of it:
                    -- the leg takes what it catches with it, the way that leg
                    -- is going. A horde standing in one comes out stirred
                    -- rather than scattered, which is what keeps this from
                    -- being a round ruler.
                    --
                    -- Unless what the leg is carrying is a rubber, which shoves
                    -- away from itself and never along (the CLEARING). Away from
                    -- the needle is the only direction a disc has, and `a` already
                    -- is it: it is the angle the body stands at, so its cosine and
                    -- sine are the outward unit vector. A body exactly on the
                    -- needle has no direction to read and `atan2(0, 0)` is 0, so it
                    -- goes out along absolute zero -- defined, arbitrary, and the
                    -- same shrug the MOAT's comment above makes about the same
                    -- pixel.
                    if def.wipe then
                        e:knockback(math.cos(a), math.sin(a), def.knock)
                        -- And the rubber's finale, off the row rather than the
                        -- block because that is where `scaleDamage` looks for a
                        -- `ram` (src/tools.lua, and Compass:ring reads `loop` off
                        -- the row for the same reason). What it sends flying is a
                        -- weapon until it slows, so a disc emptied outwards bowls
                        -- its inside rank through its outside one.
                        if self.tool.ram then e:launch(self.tool.ram) end
                        -- Paper dust off the body being scrubbed, thrown sideways
                        -- off the way it is going -- the rubber's own particle and
                        -- the rubber's own colour (`crumbs` in src/tools.lua).
                        game.particles:crumb(e.x, e.y,
                            math.cos(a), math.sin(a), e.radius, Palette.graphite)
                    else
                        e:knockback(-math.sin(a) * dir, math.cos(a) * dir, def.knock)
                    end

                    -- The lead bites deepest over the stretch it sets off on,
                    -- and that stretch is the one thing about a compass you get
                    -- to aim: the drag picks the width, and the direction you
                    -- dragged in is where the biting starts. Measured per lap,
                    -- so going round again bites again.
                    local damage = def.damage
                    if at < def.biteArc then damage = damage * def.bite end

                    -- And what the point has already killed this lap is weight
                    -- behind it (`drive`, the pushpin's finale). On the pin that
                    -- conversion happens once, because the landing is one
                    -- instantaneous area hit; on an arm it happens as it goes, so
                    -- a rim that has been through a crowd arrives at the far side
                    -- heavier than it set off.
                    if def.drive then damage = damage + self.kills * def.drive end

                    game.particles:burst(e.x, e.y, 2, Palette.red)
                    if e:hurt(damage) then
                        self.kills = self.kills + 1
                        game:killEnemy(i)
                    elseif self:carries() and not self.rider[dir] then
                        -- It lived, and this leg has a free point: it is picked up
                        -- rather than left standing. Blue, which is the pinhead's
                        -- own colour and what the player put on the page.
                        self.rider[dir] = e
                        game.particles:burst(e.x, e.y, 4, Palette.blue)
                    end
                end
            end
        end
    end
end

-- The lap came round, and a leg carrying a pencil takes the middle of what it
-- just closed: the LASSO (src/tools.lua), the pencil's own last level being
-- drawn by an arm instead of by your hand.
--
-- It is the pencil's rule and the pencil's number (`loop` in src/upgrades.lua)
-- resolved off geometry the sweep already has, rather than by Stroke's ray cast
-- over a hand-drawn path: what a compass closed is a circle, so being inside it
-- is one distance from the needle. Which is the only reason this lives here at
-- all -- `Stroke:tryCloseLoop` would answer the same question, later and less
-- exactly, and with two legs it would answer it at the wrong moment: each leg
-- draws half the circle per lap, so the ring is closed by the *pair* of them
-- meeting and neither stroke has come back to its own start. `Compass:swing`
-- clears `lassos` on the marks it opens for that reason.
--
-- Once a lap, so twice a swing on a finished line, and measured per lap the way
-- `bite` is: going round again closes the ring again, and what has walked inside
-- since is inside.
--
-- The rim cut is a separate event and both land on the same body, on the
-- pencil's own terms -- being surrounded and being scratched are different things
-- that happened, and the hit lists are separate for exactly that reason. There is
-- no `hit` bookkeeping here at all: one call is one closure.
function Compass:ring(game)
    local ox, oy = self:leadAt(1)
    game.particles:burst(self.x + ox, self.y + oy, 5, Palette.ink)

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        -- The centre inside the circle, and nothing softer. A body standing on
        -- the line is half in and half out, and the rim has already had it.
        if util.len(e.x - self.x, e.y - self.y) < self.radius then
            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(self.tool.loop.damage) then
                game:killEnemy(i)
            end
        end
    end
end

-- The newest other circle on the page this one genuinely crosses, and how far
-- apart the two needles are. Nothing, if there is no such circle.
--
-- Newest first, because the freshest pairing is the one the player just drew --
-- and *one* partner rather than every partner: three circles on the page would
-- otherwise rule a lattice off a single closing, where what the tool promises is
-- a line between two.
--
-- **Genuinely** crosses, which is two strict inequalities and no epsilon: circles
-- further apart than their radii add to never meet, one entirely inside the other
-- never meets, and the two boundary cases -- touching at a single point, and the
-- same circle drawn twice -- fall out of the same strictness. So a pair this
-- returns has two crossings and not one or infinitely many, which is what lets
-- `Compass:crease` below do plain arithmetic and trust it.
--
-- And the partner has to have come round at least once. A circle the arm is still
-- drawing is not a circle yet, and the crossings of an arc that has not arrived
-- are two points on blank paper -- one lap is the whole ring however many legs
-- shared it, which is what `span` means everywhere else in this file.
function Compass:crossed(game)
    for i = #game.compasses, 1, -1 do
        local c = game.compasses[i]
        if c ~= self and c.tool.snap and c.swept >= c.span then
            local d = util.len(c.x - self.x, c.y - self.y)
            if d > APART
                and d < self.radius + c.radius
                and d > math.abs(self.radius - c.radius) then
                return c, d
            end
        end
    end
end

-- The ring closed, and if another one it crosses is still on the page the ruler
-- comes down between the two places they cross: the FOLD (src/tools.lua).
--
-- It is the schoolroom construction, and it is the one the two instruments in the
-- pencil case were both bought for -- two arcs from two centres, and a straight
-- edge laid through where they meet. Nothing else in the game is made of two
-- gestures a page apart.
--
-- **Fresh is not a clock this had to invent.** A compass is in `game.compasses`
-- for exactly as long as the circle it ruled is on the paper and drops itself the
-- moment that fades (Compass:update), so the window is the ring's own `life` and
-- the rule reads off the screen: draw the second circle while you can still see
-- the first.
--
-- Once a lap, exactly as `Compass:ring` is and for the same reason -- the crossing
-- points are a fact about two rings, and coming round again is the unit a compass
-- measures everything in. So a finished line rules the chord twice, half a turn
-- apart, which is what keeps its third level worth something to this tool.
function Compass:crease(game)
    local other, d = self:crossed(game)
    if not other then return end

    -- Where the two rims meet. `a` is how far along the line joining the needles
    -- the crossings sit and `h` is how far off that line they are either way, so
    -- the middle of the chord is a point on it and the two ends are square to it.
    local r1, r2 = self.radius, other.radius
    local a = (d * d + r1 * r1 - r2 * r2) / (2 * d)
    -- Positive, by the two inequalities `Compass:crossed` insisted on -- and
    -- floored anyway, because what guarantees it is a subtraction of squares and a
    -- subtraction of squares one float off a boundary is how a square root gets
    -- asked for a NaN.
    local h = math.sqrt(math.max(0, r1 * r1 - a * a))

    -- A ruler shorter than it is wide is not a ruler, it is a blot. Two circles
    -- meeting at a graze have a chord of almost nothing, and what would come down
    -- on it is the whole 13px band, the whole 12 and the whole shove wrapped round
    -- a single point -- a pushpin drawn by accident. So the chord has to be at
    -- least as long as the band that lands on it, which is the one number here
    -- that is a drawing rule rather than a fact about circles.
    local snap = self.tool.snap
    if h * 2 < snap.width then return end

    local ux, uy = (other.x - self.x) / d, (other.y - self.y) / d
    local mx, my = self.x + ux * a, self.y + uy * a
    local ax, ay = mx - uy * h, my + ux * h
    local bx, by = mx + uy * h, my - ux * h

    -- Ink off both crossings, which is where the line came *from* rather than
    -- where it landed -- the slap throws its own graphite down the length of it
    -- (Ruler:strike), and these two points are the pair that decided what the
    -- length was.
    game.particles:burst(ax, ay, 3, Palette.ink)
    game.particles:burst(bx, by, 3, Palette.ink)
    game:castRuler(self.tool, ax, ay, bx, by)
end

-- What the leg does with the whole tapped tool on the end of it, when the row has
-- one (`drop`, and only a fusion has ever had one). There are two honest readings
-- of a tapped tool on a moving arm and the block says which without a flag having
-- to be invented for it -- field presence, which is how everything else in this
-- game is routed:
--
--   it **presses as it travels** if the drop can rake, because raking is what a
--   tool that presses along a path does, and it already carries the spacing to do
--   it with (the stapler's own `rake.every`, the HEM). What it leaves behind is a
--   line of them -- a seam, closed into a hem by the circle;
--
--   otherwise it is **carried** on the point and driven in once, where the arm
--   stopped (the SPINDLE). One thing goes into the page per leg, at the end.
--
-- Nothing may do both, and nothing should want to: a tool that stapled its way
-- round *and* nailed what it caught at the end would be two finales.
function Compass:seams()
    local drop = self.tool.drop
    return drop ~= nil and drop.rake ~= nil
end

function Compass:carries()
    local drop = self.tool.drop
    return drop ~= nil and drop.rake == nil
end

-- Where the presses go, worked out once the width is known and never again.
--
-- Fixed slots rather than a distance the arm accumulates as it goes, for
-- `stepsFor`'s reason one level up: a slot keeps its place for the whole swing, so
-- the spacing is exactly even, the count is exactly what the price was charged
-- for, and a slow frame cannot drift or drop one. Each slot is stored as the
-- *swept angle at which some leg first reaches it* -- leg 1 reaches the slot at
-- offset `o` when it has come round `o`, and leg 2, going the other way, reaches
-- the same spot at `TAU - o` -- so the list comes out in the order the arm works
-- and is walked with a cursor.
--
-- Whichever leg gets there first is the one that presses, and the other never
-- presses that slot at all. That is not an optimisation, it is the rule: the page
-- holds staples one deep (`FOOTPRINT` in src/staple.lua), so a second press on a
-- spot that already has one is a press nobody sees -- and the meter was charged
-- for thirty-four staples on the page, not for sixty-eight presses of which half
-- are thrown away.
function Compass:loadSeam()
    local every = self.tool.drop.rake.every
    local n = Compass.seamCount(self.radius, every)
    local counter = self.def.counter

    self.seam = {}
    for k = 0, n - 1 do
        local off = k * TAU / n
        -- The other leg's arrival at the same spot, if there is another leg.
        local back = counter and (TAU - off) % TAU or math.huge
        if off <= back then
            self.seam[#self.seam + 1] = { at = off, dir = 1 }
        else
            self.seam[#self.seam + 1] = { at = back, dir = -1 }
        end
    end

    table.sort(self.seam, function(a, b) return a.at < b.at end)
end

-- The presses the arm has just travelled over, driven into the page.
--
-- One at a time off the cursor, so this costs nothing on a frame that reached no
-- slot -- which is most frames at the smallest width and none at all at the
-- widest. The staple goes in at the slot's own angle rather than at wherever the
-- lead happens to be this frame, which is the same choice the slots themselves
-- are: the spacing is the tool, and a press a frame late is a press half a crown
-- out of line.
--
-- Nothing about a body is asked here. A staple bites what it lands on when it
-- lands on it (Staple:bite, through Game:driveDrop), exactly as a tapped one does,
-- and the leg's own cut is a separate event that already happened as it passed --
-- being cut by the arm and being fastened to the paper are two things, on the
-- pencil's rule about being scratched and being surrounded.
function Compass:seamPress(game, dt)
    local drop = self.tool.drop
    self.clack = math.max(0, self.clack - dt)

    while true do
        local press = self.seam[self.next]
        if not press or press.at > self.swept then return end
        self.next = self.next + 1

        local a = self.start + press.dir * press.at
        local x, y = self.x + math.cos(a) * self.radius, self.y + math.sin(a) * self.radius
        -- Heard at most every CLACK, laid every time.
        local hush = self.clack > 0
        if not hush then self.clack = CLACK end
        game:driveDrop(drop, x, y, hush)
    end
end

-- Is this body already on a point? At most two ever are, so the two comparisons
-- are the whole search and there is no second table to keep in step with `rider`.
function Compass:rides(e)
    return self.rider[1] == e or self.rider[-1] == e
end

-- The riders dragged up to where their points now are, once a frame off the swept
-- angle exactly as the bands are (Compass:layBands) -- and for the same reason:
-- the lead's position is a pure function of that angle, so there is nothing to
-- integrate and nothing to drift.
--
-- Held rather than walked round. A frame's worth of freeze renewed every frame is
-- what being impaled *is* here, and it costs nothing to write because Enemy:update
-- already knows what a frozen body does: it does not chase, it does not drift, it
-- drops whatever shove it was carrying, and it still hurts the player who walks
-- into it. Which is the honest reading of a monster on the end of a moving arm --
-- it is not out of the fight, it is a hazard on rails.
--
-- `gone` is the one thing that has to be watched, and it is watched the way
-- src/storm.lua watches it for a cloud following a body it marked: this holds a
-- reference across frames, and dropping out of the horde -- killed by something
-- else, or walked so far off the page it was forgotten -- is not something a walk
-- of the list can tell it about afterwards.
function Compass:haul()
    for _, dir in ipairs(LEGS) do
        local e = self.rider[dir]
        if e then
            if e.gone then
                self.rider[dir] = nil
            else
                local ox, oy = self:leadAt(dir)
                e.x, e.y = self.x + ox, self.y + oy
                e:freeze(CARRY)
            end
        end
    end
end

-- The turn is over, and whatever came round on the point is nailed to the page
-- where the arm stopped: the pushpin's own finale, arriving a whole turn after the
-- crater that earned it.
--
-- This is what the fusion is *for*, and it is worth being clear about which half
-- of each parent is doing what. The pin brings the hold and the object that never
-- comes off the paper; the compass brings the one thing in the game you can watch
-- a hit travel down. A tapped pushpin punches a crater and pins the survivor in
-- the same frame, so the two halves read as one event. Here they are a turn apart,
-- and the second half is a promise you can see being kept -- the blob is right
-- there on the end of the arm the whole way round, and the page it is going to be
-- stuck to is wherever the leg happens to stop.
--
-- Nothing is nailed if nothing was carried, which is why a swing that caught only
-- chaff leaves no pin at all. The page's memory of a run is a record of where the
-- trouble was (src/pin.lua), and a pin through nothing would be a false entry in
-- it.
--
-- `wasFree` is not asked, unlike Pin:land. A rider has been held every frame since
-- it was picked up, so of course it was not free -- the event worth marking here is
-- the pin going in, not the hold beginning.
function Compass:nail(game)
    if not self:carries() then return end
    local drop = self.tool.drop

    for _, dir in ipairs(LEGS) do
        local e = self.rider[dir]
        self.rider[dir] = nil
        if e and not e.gone then
            local ox, oy = self:leadAt(dir)
            local px, py = self.x + ox, self.y + oy

            e:freeze(drop.freeze)
            -- Paper fibres off the puncture and blue on the body, which are the
            -- two halves Pin:land spends on the same event: one belongs to the
            -- page and one to the thing that is not going anywhere.
            game.particles:burst(px, py, 9, Palette.graphite)
            game.particles:burst(e.x, e.y, 3, Palette.sky)
            game:driveDrop(drop, px, py)
        end
    end
end

-- The disc clearing while it is off the page: the scissors' last level with a
-- circle round it instead of a half-plane (Scissors:lift, and the contract is the
-- same contract).
--
-- Everything inside the ring is **taken off the page and put down again in the
-- furthest corner of it**, not killed. No gem, no xp, no kill on the tally,
-- nothing split and nothing burst -- because nothing was hurt, and
-- Game:liftEnemyTo is the whole of it. The hole in the paper is a hole the
-- crowd is not in, and the crowd that was in it is standing in the corner of the
-- page walking back at you.
--
-- **This is what makes the PUNCH a tool rather than a second LASSO**, and it is
-- worth saying where a reader will look. Both are a ring that does something to
-- its own middle, which is the one thing a compass has never done; the lasso's
-- middle is a *hit*, 4 damage the instant the line closes, and this one's is a
-- *place the horde is not*. The difference is not a number -- it could not be,
-- because the two would then only be arguing about how hard -- it is a different
-- verb. The scissors were always the tool that reached anywhere and could only
-- ever choose half a page with it; the compass gives them a disc you sized with
-- the drag. What comes out of that is the only thing in the game that buys
-- nothing but room.
--
-- And the price is the room. Nothing is taken out of the run -- the disc moves
-- the crowd, it does not spend it -- so what a punch costs is that everything it
-- held arrives back out of one corner at once, together, at the health it had.
-- A build opening one every time the meter fills is a build that keeps handing
-- itself a clean circle to stand in and a single line of monsters to answer, over
-- and over, and that is a real bargain rather than a free one: the fight it
-- postponed is the fight it gets, in one place, thirty seconds later.
--
-- Twice a second rather than every frame, which is the sun's rule and the bomb's,
-- and a clock rather than one pass because the disc has to answer for whatever
-- walks into it while it is open -- the hole stays a hole for as long as the rim
-- is on the paper.
--
-- `eachWithin` is the disc test itself, so unlike the scissors there is no
-- `offcut` to write: what the ring holds is one distance from the needle. Where
-- what it holds *goes* is the run's question rather than this object's
-- (`Game:clearCorner`) -- asked once for the whole sweep, so the disc empties into
-- one corner, and answered against every hole on the page rather than only this
-- one, so a punch opened inside a cut's offcut does not hand its crowd straight
-- back to the paper the cut took.
--
-- Nowhere clear means nothing is lifted this tick, and the sweep is skipped rather
-- than run to no purpose.
--
-- The on-screen clip is kept even so. It is doing far less here than it does for
-- the offcut -- a disc is 66 pixels at the widest where half a page has no far end
-- at all -- but the rule it enforces is the same one, and a hole the camera has
-- walked away from should not go on hauling bodies into a corner where nobody can
-- see it happen.
function Compass:lift(game)
    local corner = game:clearCorner()
    if not corner then return end

    local left, top, w, h = Camera.bounds()

    game:eachWithin(self.x, self.y, self.radius, function(e)
        if e.x < left or e.x > left + w or e.y < top or e.y > top + h then return end

        game:liftEnemyTo(e, corner)
    end)
end

-- One speck off a lead.
--
-- Or a spray of **crumbs**, for a tip that is rubbing rather than drawing (`wipe`,
-- the CLEARING in src/tools.lua): what comes off a rubber is not pigment jumping
-- off a point, it is paper dust thrown out to the sides of the thing travelling --
-- which is the rubber's own reading of itself, and `Particles:crumb` is the call it
-- already makes. Thrown off the *tangent*, because that is the way the tip is
-- going, and as wide as the tip is (`width`).
--
-- Paced by arc rather than by the pixel either way (`SPECK`), which is a compass's
-- rule and not a brush's: a hand paces its debris by how far it has dragged, and an
-- arm has only ever had an angle to count.
function Compass:fleck(game, dir, color)
    local ox, oy = self:leadAt(dir)

    if self.def.wipe then
        local a = self.start + dir * self.swept
        game.particles:crumb(self.x + ox, self.y + oy,
            -math.sin(a) * dir, math.cos(a) * dir, self.def.width, color)
        return
    end

    game.particles:burst(self.x + ox, self.y + oy, 1, color)
end

-- Where a leg's lead is now, as an offset from the needle. `dir` is 1 for the
-- leg that goes with the turn and -1 for the second one, which comes round the
-- other way from the same rest point.
function Compass:leadAt(dir)
    local a = self.start + dir * self.swept
    return math.cos(a) * self.radius, math.sin(a) * self.radius
end

-- The leg moved on, and everything under it cut. The band is walked a lap at a
-- time rather than in one go, because the hit list is what a lap *is*: coming
-- round a second time only means anything if what was cut on the way past can
-- be cut again. The arm always moves at a whole turn per `turn` seconds, so a
-- circle that goes round twice takes twice as long and one closed by two legs
-- takes half -- the promise gets longer or shorter, never the arm faster.
function Compass:advance(dt, game)
    local target = math.min(self.total, self.swept + TAU * dt / self.def.turn)

    while self.swept < target do
        local lap = math.floor(self.swept / self.span)
        local base = lap * self.span

        if lap ~= self.lap then
            self.lap = lap
            self.hit = {}
            self.kills = 0
        end

        local edge = math.min(target, base + self.span)
        local closes = edge >= base + self.span
        self:cut(game, self.swept - base, edge - base, closes)
        if closes then
            if self.tool.loop then self:ring(game) end
            -- And another circle still lying on the page is a pair of crossings,
            -- which is a ruler waiting to be dropped between them (the FOLD).
            if self.tool.snap then self:crease(game) end
            -- And the page comes away the first time the ring closes rather than
            -- when the arm finally stops, which is the scissors' own rule: the
            -- offcut is off from the moment there is a closed line round it, and a
            -- disc that waited for the second lap would be a finale that had not
            -- happened yet through the half of the swing you were watching for it.
            if self.def.sever and not self.severed then
                self.severed = true
                -- Zero rather than a full tick, the scissors' number for the
                -- scissors' reason: the disc is off the page the instant the
                -- ring closes, and the crowd standing in it should go with the
                -- paper rather than half a second after it. On a two-legged
                -- compass the ring closes half way through the swing, so this
                -- is the frame the player is watching for.
                self.severT = 0
            end
        end
        self.swept = edge
    end
end

-- Returns false once the circle it drew has faded off the page -- or, for a
-- banded one, the moment the arm stops, since the mark it made is a stroke
-- ageing in the run's own list and there is nothing left here to draw or wait
-- for. Nothing ages while it is open either way: a compass held on the page
-- waits as long as you hold it, and the horde keeps walking the whole time.
function Compass:update(dt, game)
    if self.setting then return true end

    -- Before the two branches below rather than inside either, because a disc is
    -- off the page from the moment the ring closed and the arm is very often still
    -- coming round when that happens -- with two legs the first lap is closed half
    -- way through the swing.
    if self.severed then
        self.severT = self.severT - dt
        if self.severT <= 0 then
            self.severT = self.def.sever.tick
            self:lift(game)
        end
    end

    if self.swept < self.total then
        local from = self.swept
        self:advance(dt, game)
        self:layBands(game, dt)
        -- Whatever the points are carrying, brought up to where they are now --
        -- after the arm has moved, so a rider is never a frame behind the lead it
        -- is impaled on. And then, on the one frame the turn completes, the pin
        -- that ends the journey: it goes in *here* rather than in the closed
        -- branch below so that it lands the instant the arm stops rather than the
        -- frame after, which is the frame the player is looking at.
        self:haul()
        -- And the presses the arm has just gone over, if what it is working is a
        -- stapler rather than a point it is carrying (the HEM). After `advance`
        -- for `haul`'s reason -- a press belongs where the arm *is*, not where it
        -- was -- and before the two lines below only because reading them in the
        -- order the frame happens is easier than reading them in any other.
        if self.seam then self:seamPress(game, dt) end
        if self.swept >= self.total then
            self:nail(game)
            -- The frame the arm stops is the frame nothing here can cut, seam
            -- or drive any more -- see the hold in Compass:swing.
            game.multikill:release()
        end

        -- Graphite jumping off the lead, so the arm reads as drawing the line
        -- rather than uncovering one that was already there. Red off the
        -- stretch it bites on, which is the blue the needle's head is drawn in:
        -- the parts of the figure that are doing something rather than being
        -- somewhere.
        self.speck = self.speck - (self.swept - from)
        if self.speck <= 0 then
            self.speck = SPECK

            -- Graphite off a lead; off a nib it is whatever that tool sheds as
            -- it draws (`speck`), since what is coming off the tip is what the
            -- tip is laying down. Read off `speck` rather than off the first
            -- colour of the ramp, which is what this used to do and was one
            -- fusion away from being wrong: the halo's ramp and the halo's speck
            -- are both sky, but the MOAT's ramp is *paper*, and paper flecks
            -- thrown onto paper are a particle nobody can see. What a gluestick
            -- sheds is sky, and it says so on the row.
            local nib = self.bands and self.tool.speck
            local color = nib and nib.color
                or (self.bands and self.tool.ramp[1] or Palette.graphite)
            if self.swept % self.span < self.def.biteArc and self.def.bite > 1 then
                color = Palette.blue
            end

            self:fleck(game, 1, color)
            if self.def.counter then self:fleck(game, -1, color) end
        end
        return true
    end

    -- Closed. A banded compass is finished the moment the arm stops: the mark it
    -- made is a stroke in the run's own list now and ages there, so there is
    -- nothing left here to draw or to wait for. A pencil one stays as long as the
    -- circle it ruled, because that circle is drawn from this object.
    if self.bands then
        for _, band in ipairs(self.bands) do band.stroke:finish() end
        return false
    end

    self.age = self.age + dt
    return self.age < self.def.life
end

-- The rim, plotted a pixel at a time on the grid rather than as a polygon, so
-- the circle sits on the same lattice as the ruling under it. `a0` and `a1` are
-- how far round from where the lead set off the stretch runs -- past a full turn
-- is clamped to one, since a second lap goes over ink that is already there --
-- `dash` leaves the gaps a pencil guide is drawn with, `dither` drops points out
-- exactly the way a fading stroke drops stamps, and `dir` is which way round,
-- for the second leg.
--
-- `dr` nudges the whole ring out by a pixel, and it has exactly one caller: the
-- dark edge of a slit lifting beside the opening (Compass:drawRim). The step count
-- is left at the radius the ring was measured for, which is what keeps the edge on
-- the same lattice as the opening it belongs to -- and a ring one pixel bigger
-- sampled at the smaller ring's density is still sampled a step and a half per
-- pixel, so nothing opens up a gap.
function Compass:plot(a0, a1, dash, dither, dir, dr)
    local n = self.steps
    local first = math.max(0, math.ceil(a0 / TAU * n))
    local last = math.min(n - 1, math.floor(a1 / TAU * n))
    local cx, cy, r = self.x, self.y, self.radius + (dr or 0)
    dir = dir or 1

    for i = first, last do
        if (not dash or i % (dash * 2) < dash)
            and (not dither or util.hash01(i, self.seed, 31) > dither) then
            local a = self.start + dir * TAU * i / n
            love.graphics.rectangle("fill",
                math.floor(cx + math.cos(a) * r),
                math.floor(cy + math.sin(a) * r), 1, 1)
        end
    end
end

-- The page's share of it: where the circle is going to go, the part of it that
-- has been drawn so far, and the finished ring fading. All three are marks, so
-- all three go under everything standing on the page.
function Compass:drawGuide()
    local def = self.def

    if self.setting then
        -- Ruled out in pencil first, the way the ruler's band is. What is being
        -- chosen is a circle, so a circle is what you are shown -- a radius
        -- read off the leg alone would be a number, not a target.
        love.graphics.setColor(Palette.graphite)
        self:plot(0, TAU, DASH, nil)

        -- And the stretch that bites, in the needle's own blue, over the top of
        -- it. The drag is choosing two things at once and this is the second of
        -- them: turning the leg round the crowd puts the deep cut where you
        -- want it, and without the blue the choice would be invisible.
        if def.bite > 1 then
            love.graphics.setColor(Palette.blue)
            self:plot(0, def.biteArc, DASH, nil)
            if def.counter then self:plot(0, def.biteArc, DASH, nil, -1) end
        end
        return
    end

    -- A leg carrying a nib has already put the line on the page -- the band is
    -- the mark, and it is drawn with the other marks rather than from here -- so
    -- there is nothing left for this to plot. Plotting the rim as well would be
    -- a pencil circle ruled down the middle of a highlighter band.
    if self.bands then return end

    if self.swept < self.total then
        -- Still coming round, and full ink: this is the line being drawn.
        self:drawRim(self.swept, def.ramp[1], nil)
        return
    end

    -- Closed, and for one row there is nothing left: a rub leaves the page exactly
    -- as it found it (`life = 0`, the CLEARING in src/tools.lua -- the rubber's own
    -- number). The object itself goes on the next update, so this is the one frame
    -- in between, and the fade below would be dividing by that zero.
    if def.life <= 0 then return end

    -- Closed, and leaving the page the way every other mark does -- down a
    -- ramp, dithering out, never through an alpha that would invent a ninth
    -- colour.
    local f = self.age / def.life
    local ramp = def.ramp
    local dither
    if f > def.fade then dither = (f - def.fade) / (1 - def.fade) end

    self:drawRim(TAU, ramp[math.min(#ramp, math.floor(f * #ramp) + 1)], dither)
end

-- One stretch of the rim, both legs of it, in whatever the leg is laying down.
--
-- A lead rules a line of pigment and that is the whole of it. A **blade** opens
-- the page instead, and an opening cannot be drawn the way a line is: paper is the
-- one colour that wipes what is under it rather than stacking with it, which is
-- exactly what makes a slit read as the ruling stopping -- and it also means paper
-- laid on paper shows up nowhere at all except where it happens to cross a rule.
-- So a slit is drawn the way src/scissors.lua draws one, and for the same two
-- reasons:
--
--   dashed, because a cut is where the blades closed and the gaps between are
--   where they were opening again -- the same 3 this file already dots its guide
--   with, which is the same 3 a cut is dashed with;
--
--   and with the dark edge of the page lifting one pixel to the side of the
--   opening, which is the half that makes it visible on an unruled page at all.
--   *Outward*, here. A straight cut has to round its perpendicular to an axis to
--   find that side; on a circle the outward direction is the perpendicular, so
--   this is the one place this file has an easier job than the scissors do.
--
-- Both are decided by identity against the palette rather than off a flag, which
-- is the scissors' own test: the question is whether what the leg is laying down
-- is an opening, and the ramp's colour is the honest answer to it. The edge stops
-- when the ramp steps off paper, because a crease has nothing left open to cast
-- one.
function Compass:drawRim(a1, core, dither)
    local slit = self.def.ramp[1] == Palette.paper
    local dash = slit and DASH or nil
    -- A closed ring is a whole turn either way round, so the second leg would be
    -- plotting the first leg's pixels a second time. Only a stretch still being
    -- drawn has two of them.
    local legs = self.def.counter and a1 < TAU

    if slit and core == Palette.paper then
        love.graphics.setColor(Palette.graphite)
        self:plot(0, a1, dash, dither, 1, 1)
        if legs then self:plot(0, a1, dash, dither, -1, 1) end
    end

    love.graphics.setColor(core)
    self:plot(0, a1, dash, dither)
    if legs then self:plot(0, a1, dash, dither, -1) end
end

-- The disc the ring has taken off the page, laid into the *page* layer rather
-- than into the ink over it -- because it is not a mark, it is the page not being
-- there. Called from the page pass in Game:draw beside the scissors' own half,
-- and everything true of that one is true of this: what goes down is the page
-- rebaked (`Background.torn`), the ruling exactly where it was printed and grey
-- where the paper between it used to be, so a rule that ran through the disc still
-- runs through it and what says the page is gone is the white going out of it.
--
-- Filled a row at a time for `Scissors:drawSever`'s reason -- a span is contiguous
-- by construction where a shape plotted a pixel at a time is not -- and a circle
-- makes that easier rather than harder: every row's span is a chord, so there is
-- one square root per row and no boundary case anywhere. A row the circle misses
-- is a row whose chord is empty and is never asked for.
function Compass:drawSever(left, top, w, h)
    if not self.severed then return end

    local cx, cy, r = self.x, self.y, self.radius
    local x0, y0 = math.floor(left), math.floor(top)
    local x1, y1 = x0 + w, y0 + h

    for y = math.max(y0, math.ceil(cy - r)), math.min(y1, math.floor(cy + r)) do
        local dy = y - cy
        local half = math.sqrt(math.max(0, r * r - dy * dy))
        local from = math.max(x0, math.ceil(cx - half))
        local to = math.min(x1, math.floor(cx + half))
        if to >= from then
            Background.torn(from, y, to - from + 1)
        end
    end
end

-- The instrument itself, for as long as it is standing in the page. It is an
-- object on the paper rather than a mark in it, so it is drawn over the top of
-- everything -- including whatever is standing in the circle, because a leg you
-- cannot see behind a blob is a leg you cannot tell the width of. The moment the
-- circle closes the compass is lifted off and only the line it drew is left.
function Compass:draw()
    if not self.setting and self.swept >= self.total then return end

    local cx, cy = math.floor(self.x), math.floor(self.y)

    self:drawLeg(1)
    if self.def.counter then self:drawLeg(-1) end

    -- The needle. Blue-headed, because it is the one point of the whole figure
    -- that never moves and the only part of it you placed by hand -- and what
    -- you placed by hand is blue everywhere on this page.
    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", cx, cy - NEEDLE, 1, NEEDLE)
    love.graphics.setColor(Palette.blue)
    love.graphics.rectangle("fill", cx - 1, cy - NEEDLE - 2, 3, 2)
end

-- One leg, out to its lead. Plotted a pixel at a time for the same reason the
-- rim is. Pencil-pale while it is being set, inked once it is drawing.
function Compass:drawLeg(dir)
    local ox, oy = self:leadAt(dir)

    love.graphics.setColor(self.setting and Palette.graphite or Palette.slate)
    pixelart.line(self.x, self.y, self.x + ox, self.y + oy)

    -- Whether this stretch is the one the lead bites on, which is the only
    -- warning anything standing there gets that this part of the circle is worth
    -- twice the rest of it.
    local wide = not self.setting and self.def.bite > 1
        and self.swept % self.span < self.def.biteArc
    local lx, ly = math.floor(self.x + ox), math.floor(self.y + oy)

    -- What is on the end of the arm, when it is an *object* rather than a point.
    -- A row carrying a `drop` block has a whole tapped tool on the leg (the
    -- SPINDLE, src/tools.lua) and names the sprite it is seen carrying, so what
    -- comes round the circle is drawn as the pushpin itself: the same 7x8 drawing
    -- a dropped one uses, whose origin is its own point, so the point sits exactly
    -- where the lead would have been. It is the thing itself rather than a second
    -- drawing of it, which is the rule every icon in this game is authored on --
    -- and here it is what makes the finale legible. The pin you watch travel is
    -- the pin left standing in the page when the arm stops: this stops being
    -- drawn the frame the turn closes (Compass:draw) and the driven one starts,
    -- one list earlier in the same pass (Game:driveDrop).
    --
    -- Drawn while the compass is still being set, too, where the leg itself goes
    -- pale. A leg is a line and a line may be pencil-faint before you commit to
    -- it; a pushpin is an object on the arm, and objects do not get paler for
    -- being undecided -- which is src/pin.lua's own rule about a pin looking the
    -- same whatever it happens to be doing.
    local drop = self.tool.drop
    local point = drop and drop.sprite and Sprites[drop.sprite]
    if point then
        -- Outlined over the stretch it bites on, a pixel out on all four sides,
        -- which is how everything in this game says "that one" (`outline` in
        -- src/enemy.lua) -- and in the blue the guide dots that same arc in and
        -- the flecks come off the lead in. A pin cannot be pressed harder into
        -- the paper the way a lead can, so the tell goes round it instead of
        -- into it.
        if wide then
            love.graphics.setColor(Palette.blue)
            point:drawMask(lx - 1, ly)
            point:drawMask(lx + 1, ly)
            point:drawMask(lx, ly - 1)
            point:drawMask(lx, ly + 1)
        end

        love.graphics.setColor(1, 1, 1)
        point:draw(lx, ly)
        return
    end

    -- The lead, pressed into the paper at the end of it -- and pressed harder
    -- over the stretch that bites.
    local w = wide and 3 or 2

    love.graphics.setColor(Palette.ink)
    love.graphics.rectangle("fill", lx - 1, ly - 1, w, w)
end

return Compass
