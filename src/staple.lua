-- A staple, driven into the page.
--
-- The pushpin's opposite number, and used identically: you tap the paper and
-- one lands where you tapped. Everything else about the two is the other way
-- round.
--
-- A pin is one big expensive decision -- most of half the meter, a quarter of a
-- second in the air, a 41px crater, and enough damage to kill everything caught
-- in it but the tank. A staple is a tenth of the meter, it lands the instant
-- you tap, it reaches 15px and it does 2, which is a bat and nothing else. It
-- is not an attack, it is a fastener. What it does is hold one thing to the
-- paper for two seconds, and the way you use it is to keep tapping: a row of
-- them across the front of the horde, or three into the blob about to reach
-- you.
--
-- Nothing about it is telegraphed, because there is nothing to dodge. The pin's
-- fall is what stops a tap on a moving target being a certainty; a staple has
-- no fall at all, and what keeps it honest instead is that hitting barely hurts
-- and the circle is small enough to miss with.
--
-- It goes in flat, or leaning a few degrees one way or the other, which is the
-- one thing a page full of them needs: twenty staples lying at exactly the same
-- angle read as a pattern printed on the paper rather than as twenty separate
-- decisions. The other thing a page full of them needs is `FOOTPRINT` below: the
-- page holds them one deep, so twenty separate decisions never pile into one
-- shape nobody made.
--
-- One fusion makes it sticky instead (`tacky` on the block, the CLINCH): the circle
-- is swept every four tenths of a second and anything standing in it is fastened
-- again, so the staple stops being a fastening aimed at one body and becomes a spot
-- on the page that holds whatever crosses it. Nothing else about the tool changes,
-- and the two endings below still end it.
--
-- One upgrade takes the fastening back (`prise` on the block). The hold runs out
-- the way it always did and then the wire is torn out of the paper instead of
-- being left in it -- biting a second time as it comes, and leaving nothing
-- behind. It is the one level written against everything above: the tool stops
-- being a fastener that stays and becomes a fastener that is removed, twice, and
-- what it buys with that is the only hit in the game that cannot miss. What the
-- crown caught two seconds ago is standing exactly where it was, because the
-- crown is the thing that has been holding it there.
--
-- And one fusion takes the *clock* off that (`Staple:snag`, the SNAG in
-- src/tools.lua). A rubber dragged across a stapled sheet catches the wire and
-- takes it with it, which is a thing that really happens to paper -- so on that
-- row the tear is not something the hold runs out into, it is something a rub
-- comes and does, whenever you decide to go and do it. Nothing about the tear
-- itself changes except the one thing a hand pulling a staple out sideways
-- deserves: the crit is certain rather than rolled. The two seconds stop being
-- how long the fastening lasts and become how long you have to get back to it.

local Palette = require("src.palette")
local pixelart = require("src.pixelart")

local Staple = {}
Staple.__index = Staple

local CROWN = 10    -- the bar across the top
local LEG = 3       -- how far the ends turn down into the paper

-- How near another one already in the page is too near (Game:dropCrowded). A
-- staple driven inside this of one that is already there does its work and is
-- then not kept -- the page has a staple at that spot and does not need two
-- drawings of it.
--
-- Six against a ten-pixel crown, so two of them lying end to end still both
-- stay and two lying across each other do not. It is deliberately well under
-- the seam's own spacing (`rake` in src/tools.lua, 12px) -- a level that ate
-- half of what it laid down would be a level arguing with itself.
Staple.FOOTPRINT = 6

-- How far the wire itself reaches from the anchor, for the one thing that has to
-- touch the *staple* rather than what the staple holds (`Game:snagDrops`, the
-- SNAG). Half the crown, which is the widest part of it.
--
-- Deliberately not `radius` above, and the pair is worth reading together: the
-- circle is the fastening -- 7 pixels of page the wire holds down -- and this is
-- the drawing. A rub that reached for the circle would take out staples it never
-- went near the wire of, which is the one thing a player has to be able to see
-- coming.
Staple.REACH = CROWN / 2

-- How far off flat it can land: nothing, or a lean of a few degrees either way.
--
-- A staple goes into the page the way the stapler was held, which is very
-- nearly square and never far from it. The lean is there so that twenty of them
-- do not read as a pattern printed on the paper, and it is kept this small for
-- the same reason it exists -- past about fifteen degrees the legs stop landing
-- square under the crown and the shape reads as an arrow instead of a staple.
-- At ten it is a bar with a pixel of slope in it, which is exactly what a
-- hand-placed staple looks like.
local LEAN_MIN = math.rad(5)
local LEAN_MAX = math.rad(10)

-- The tear-out: how long the wire takes to come off the page, how far it rises
-- on the way, and how far the yank turns it off the angle it went in at.
--
-- Short and steep, because a staple is not lifted off paper, it is levered out
-- of it in one movement. The rise is squared, so it barely moves for the first
-- half of the fifth of a second and is gone by the end of it, and the lean opens
-- as it goes -- which is what stops six pixels of travel reading as the page
-- scrolling rather than as the staple leaving.
local PRISE = 0.2
local RISE = 6
local YANK = math.rad(20)

local function pickLean()
    -- Flat as often as either lean, so the upright one stays the one you read
    -- the tool by.
    local which = love.math.random(3)
    if which == 1 then return 0 end

    local a = LEAN_MIN + love.math.random() * (LEAN_MAX - LEAN_MIN)
    return which == 2 and a or -a
end

function Staple.new(def, x, y)
    return setmetatable({
        def = def,
        x = x, y = y,
        angle = pickLean(),
        age = 0,
        landed = false,
    }, Staple)
end

-- Everything inside the small circle at once, which in practice is one thing.
-- Backwards, because a kill takes an enemy out of the list underneath us.
--
-- `hold` is the whole difference between the two bites. Going in, whatever is
-- left standing is fastened to the paper; coming back out (`prise`) the same
-- circle does the same damage and holds nothing, there being nothing left in the
-- page to hold anything with. The damage is the staple's own number both times
-- rather than a second one on the block -- so what the sharpener scaled is what
-- comes back out -- and the crit is rolled again, since a crit is an event that
-- happens once and the tear is a second event.
--
-- `sure` is that roll taken out of the tear's hands, and one thing passes it: a
-- rub that has caught the wire (`Staple:snag`, the SNAG in src/tools.lua). It is
-- the block's own crit either way -- the chance is what is stepped over, never the
-- multiplier -- so a run that sharpened its staples tears out exactly as deep as
-- it drove them in.
function Staple:bite(game, hold, sure)
    local def = self.def

    game.particles:burst(self.x, self.y, 3, Palette.graphite) -- fibres

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        local dx, dy = e.x - self.x, e.y - self.y
        local reach = def.radius + e.radius

        if dx * dx + dy * dy < reach * reach then
            -- The stapler's crit level. Rolled live per staple rather than
            -- hashed, exactly as the brush one is (Stroke:apply) -- a crit is an
            -- event that happens once, not stored variation that has to come out
            -- the same twice -- and always announced, because a big number
            -- nobody saw land is indistinguishable from a bug.
            --
            -- This is the tool the field was waiting for. A one-in-five on a
            -- thing you tap dozens of times a page comes out as a *rate* you can
            -- build around; the same roll on a pin you get two of from a full
            -- meter would only ever be a story about one pin.
            local damage = def.damage
            if def.crit and (sure or love.math.random() < def.crit.chance) then
                damage = damage * def.crit.mult
                game.particles:crit(e.x, e.y)
            end

            game.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(damage) then
                game:killEnemy(i)
            elseif hold and e:freeze(def.freeze, def.tacky and def or nil) then
                -- Only the ones still standing get held, and only the first
                -- time each -- the same splash of blue the gluestick spends.
                game.particles:burst(e.x, e.y, 3, Palette.sky)
            end
        end
    end
end

-- The sticky wire (`tacky` on the block, the CLINCH in src/tools.lua): everything
-- standing in the circle is fastened to the staple again, on the gluestick's own
-- cadence, for as long as the staple is in the page.
--
-- **A catch is not a bite, and the difference is the whole field.** No damage and no
-- crit: a staple that hit everything on it every four tenths of a second would be a
-- weapon, and this is a fastener. What it costs the crowd is that whatever wandered
-- onto the wire is still standing there when the wire comes out -- `prise` is what
-- collects, and it collects five seconds of arrivals rather than the one body the
-- landing caught.
--
-- The block goes to `Enemy:freeze` as the thing doing the sticking, which is the one
-- place in the game a *block* is handed over as a glue. A staple's hold has always
-- passed nothing; this one passes itself, so a `soften` written beside `tacky` rides
-- on the body the way the gluestick's does (Enemy:hurt) instead of having to be known
-- to everything that hits.
function Staple:catch(game)
    local def = self.def

    for i = #game.enemies, 1, -1 do
        local e = game.enemies[i]
        local dx, dy = e.x - self.x, e.y - self.y
        local reach = def.radius + e.radius

        if dx * dx + dy * dy < reach * reach and e:freeze(def.freeze, def) then
            game.particles:burst(e.x, e.y, 3, Palette.sky)
        end
    end
end

-- Returns false once it has finished holding -- which is not the same as being
-- finished with. Like the pushpin it is driven through the paper rather than
-- drawn on it, and unless the run bought otherwise it never comes back out: the
-- game moves it to the spent pile and stops updating it, and it stays on the page
-- for the rest of the run.
--
-- It bites on the frame it is placed. There is no fall to wait out, which is
-- the whole feel of the tool: a stapler goes down and it is done.
--
-- `prise` is the other ending, and it is bolted on after the hold rather than
-- written into it: the two seconds run exactly as they always did, and what
-- changes is what happens at the end of them. One more bite on the frame it comes
-- free, a fifth of a second of it lifting off the paper, and then `lifted` --
-- which is Game:updateDrops' word for a drop the page is not to keep.
--
-- The second bite is here rather than at the end of the lift, for the reason the
-- first is on the frame it lands: the tear is the hit, and a hit that arrived
-- after its own animation is a hit nobody can connect to anything.
--
-- And on one row the tear is not an ending the hold runs into at all -- it is a
-- rub that came and got it (`Staple:snag`). So what the two seconds mean depends
-- on the row: how long the fastening lasts everywhere else, how long you have to
-- get back to it there.
function Staple:update(dt, game)
    if not self.landed then
        self.landed = true
        self:bite(game, true)
    end

    self.age = self.age + dt

    -- A sticky one goes on collecting (`tacky`). Held off for a full cadence after
    -- the landing, because the bite that just ran has already fastened everything in
    -- the circle -- the first catch is for whatever arrives next, not for what was
    -- already there.
    local tacky = self.def.tacky
    if tacky then
        self.tack = (self.tack or tacky) - dt
        if self.tack <= 0 then
            self.tack = tacky
            self:catch(game)
        end
    end

    -- **The tear is asked about before the hold is**, and that order is the SNAG:
    -- a wire a rub has already caught is coming out whether or not its two seconds
    -- are up, so the clock only gets a say while nothing has started pulling. Every
    -- other staple in the game reaches the two lines below in the order they were
    -- always in, because nothing has.
    if not self.prised then
        if self.age < self.def.life then return true end
        if not self.def.prise then return false end
        self:prise(game, false)
    end

    self.prised = self.prised + dt
    if self.prised < PRISE then return true end

    self.lifted = true
    return false
end

-- The wire coming out of the paper, and the bite it takes on the way.
--
-- Two things start it and they differ in exactly one field. The hold running out
-- on a run that bought `prise` rolls the crit like any other bite; a rubber that
-- has caught the wire does not (`sure`, below). Everything else about the tear is
-- the same either way -- the same damage, the same fifth of a second of lifting,
-- the same nothing left behind -- because it is the same event, and which of the
-- two brought it on is not something the page should be able to tell.
function Staple:prise(game, sure)
    self.prised = 0
    -- Tugged further the way it already leans, so the yank reads as a hand
    -- taking it out rather than as the staple straightening up on its way.
    self.yank = self.angle >= 0 and 1 or -1
    self:bite(game, false, sure)
end

-- A rubber has caught the wire (`snag` in src/tools.lua, `Game:snagDrops`): the
-- tear happens now instead of whenever the hold would have run out, and the crit
-- is certain.
--
-- **The certainty is what the gesture is for and it is not a number handed out.**
-- Every other crit in the game is a rate -- one in five, honest because you tap
-- dozens of staples a page and the sample is large. This one is not rolled at all,
-- because it is not luck: the staple was placed, the hold was spent getting the
-- rub back over to it, and a hand levering wire out of paper sideways through
-- something fastened to it does not miss. What it costs is the second gesture.
--
-- Refused on one already coming out, so a rub scrubbed back and forth over the
-- same seam collects each staple once rather than once a frame -- and on one that
-- has not landed yet, which has bitten nothing and has nothing to give back.
-- Returns whether this call is what took it, which is what the sound is paced off.
function Staple:snag(game)
    if self.prised or not self.landed then return false end

    self:prise(game, true)
    return true
end

-- How far off the page it is: the rise, and how far the yank has turned it. Zero
-- for every staple in a run that never took the level, and for every staple in
-- one that did until something starts pulling -- its hold running out, or a rub.
function Staple:lift()
    if not self.prised then return 0, 0 end

    local t = math.min(1, self.prised / PRISE)
    return RISE * t * t, YANK * t * self.yank
end

-- Where the crown and the legs are, given the tilt it went in at -- and the
-- further tilt the yank has put on it, if it is on its way out of the page.
function Staple:span()
    local _, turn = self:lift()
    local ca, sa = math.cos(self.angle + turn), math.sin(self.angle + turn)
    return ca * CROWN / 2, sa * CROWN / 2,  -- half the crown, along it
           -sa * LEG, ca * LEG              -- a leg, square to it
end

-- The page's share of it: the scrap of ground it stands on, the same bar every
-- monster gets. It belongs to the page, so it goes under everything standing on
-- it -- a shadow painted over the top of the crowd would be a shadow on the
-- crowd.
--
-- Deliberately not the shape of the staple. A graphite copy of the crown offset
-- a pixel reads as a doubled line at this size rather than as a shadow, and on
-- the diagonals it fills in the gap that makes the shape legible at all.
--
-- It stays where the staple went in while the staple leaves, which is the whole
-- of what makes six pixels read as height: the wire rises off its own shadow and
-- the shadow does not follow, so the gap between them is the tear. Both go on
-- the same frame -- there is no hole in the paper afterwards, because a hole is
-- something the page would have to remember and a prised staple is the one thing
-- in this game that is taken back.
function Staple:drawMark()
    local hx, hy, lx, ly = self:span()

    -- As wide as the staple actually is, and directly under its lowest pixel.
    -- Both change with the tilt: a fixed bar sits out to one side of the ones
    -- standing on their end and reads as a smudge rather than as ground.
    local w = math.max(3, math.floor(math.abs(hx) * 2 + math.abs(lx) + 0.5))
    local drop = math.floor(math.abs(hy) + math.max(0, ly)) + 1

    -- The crown is centred on the anchor but the legs hang off one side of it,
    -- so the shape's middle is half a leg over from where the staple is.
    love.graphics.setColor(Palette.graphite)
    love.graphics.rectangle("fill",
        math.floor(self.x + lx / 2) - math.floor(w / 2),
        math.floor(self.y) + drop, w, 1)
end

-- The staple itself is an object above the paper rather than a mark in it, so
-- it is drawn with the things that stand on the page. Same reasoning as the
-- pin: a staple you cannot see behind a blob is one you cannot aim the next one
-- off, and aiming the next one off the last is the whole of how this tool is
-- used.
--
-- The same staple whatever it is doing. It does not fade as its hold runs out
-- and it does not fade afterwards -- fading is what ink does, and a staple is
-- not ink, it is wire through paper. What the hold is doing is read off the
-- enemy instead, which stops moving and grows a blue shadow.
--
-- Which is also why the tear is movement and nothing else (`prise`): the wire
-- comes off the page whole, at full ink, leaning further as it goes, and then it
-- is not there. A staple that dissolved on the way out would be a staple made of
-- ink after all.
function Staple:draw()
    local hx, hy, lx, ly = self:span()
    local rise = self:lift()
    local y = self.y - rise

    love.graphics.setColor(Palette.ink)

    -- The crown, then a leg down from each end of it. At this lean the crown is
    -- a flat run with a single pixel of step in it and the legs come out square,
    -- which is the whole reason the lean is kept small.
    pixelart.line(self.x - hx, y - hy, self.x + hx, y + hy)
    pixelart.line(self.x - hx, y - hy, self.x - hx + lx, y - hy + ly)
    pixelart.line(self.x + hx, y + hy, self.x + hx + lx, y + hy + ly)
end

return Staple
