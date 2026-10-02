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
local Damage = require("src.damage")
local Multikill = require("src.multikill")
local Spawner = require("src.spawner")
local Hud = require("src.hud")
local Menu = require("src.menu")
local Timetable = require("src.timetable")
local Library = require("src.library")
local Homework = require("src.homework")
local Canteen = require("src.canteen")
local Spread = require("src.spread")
local Settings = require("src.settings")
local Subjects = require("src.subjects")
local Studio = require("src.studio")
local Pause = require("src.pause")
local Win = require("src.win")
local Over = require("src.over")
local Retake = require("src.retake")
local LevelUp = require("src.levelup")
local Puddle = require("src.puddle")
local Arena = require("src.arena")
local Loadout = require("src.loadout")
local Design = require("src.design")
local Characters = require("src.characters")
local Input = require("src.input")
local Tools = require("src.tools")
local Stroke = require("src.stroke")
local Ruler = require("src.ruler")
local Compass = require("src.compass")
local Scissors = require("src.scissors")
local Walls = require("src.walls")
local Records = require("src.records")
local Tally = require("src.tally")
local Mark = require("src.mark")
local Purse = require("src.purse")
local Perks = require("src.perks")
local Course = require("src.course")
local Bookmark = require("src.bookmark")
local Sfx = require("src.sfx")
local I18n = require("src.i18n")
local Options = require("src.options")
local Dev = require("src.dev")
local pixelart = require("src.pixelart")
local util = require("src.util")

local Game = {}

-- Defaults only: main.lua sets both before the first frame and again on every
-- resize or rotation.
Game.vw, Game.vh = 320, 180
Game.inset = { l = 0, t = 0, r = 0, b = 0 }

local GRID_CELL = 12   -- spatial hash cell, a bit wider than the biggest enemy
local DESPAWN_DIST = 420
local SEPARATION = 0.35 -- how hard overlapping enemies shove each other apart
local SPENT_PAD = 20      -- how far off screen a spent mark is still drawn
local DRAFT_SIZE = 3      -- upgrades offered per level
local NOTICE_TIME = 1.8   -- how long the run says what you just took
local RUB_HEARD = 24      -- pixels of rubbing before the release earns its pop:
                          -- a few tip-widths of travel, so a tap stays silent

local function cellKey(cx, cy)
    return cx * 100000 + cy
end

function Game:load(vw, vh)
    self:resize(vw, vh)

    Sprites.load()
    Font.load()
    Background.load()
    Overprint.load()
    Spread.load()
    Sfx.load()

    -- First off disk: the language decides what every string below is drawn as
    -- and the volumes decide what the first transition sounds like. After
    -- Sfx.load only because a volume needs voices to be a volume of.
    Options.load()

    -- The track plays from here to the end of the program -- it is the book
    -- being open, not a run's or a screen's -- so nothing else starts or stops
    -- it; only the settings bar touches it again.
    Sfx.startMusic()

    -- Before Design.loadAll: every character has a hero board of his own and
    -- they all write the same sprite, so the drawings cannot be applied until
    -- it is settled which one is the player. Before Game:reset too, since the
    -- waiting run's player is built from this.
    Characters.load()

    -- Whatever was drawn last time, or the starting drawing to draw over.
    Design.loadAll()

    -- What was done to each page last time -- what the timetable has to say
    -- about a lesson before you have picked it.
    Records.load()

    -- And what every run before this one *did*, added up rather than kept as a
    -- best (src/tally.lua). Beside the register because it is the register's other
    -- half: one says how good a page went and this says how many times it went.
    Tally.load()

    -- What every run before this one earned; the canteen spends it.
    Purse.load()

    -- The rerolls, skips and expulsions a run starts with. After the purse,
    -- because buying one spends out of it.
    Perks.load()

    -- Which courses are enrolled in and which the next run sits at. After the
    -- purse (a rung is bought out of it) and before the bookmark, which names a
    -- course and is clamped to what has been paid for.
    Course.load()

    -- Where the last run got to, if the program was closed on one. Read rather
    -- than applied -- offering it is the title screen's business and taking it
    -- is Game:continueRun's. After Characters and Subjects, which it validates
    -- against.
    Bookmark.load()

    -- A run is built and waiting behind the title screen from the first frame,
    -- so the page it is played on must be settled before Game:reset runs.
    self:setSubject(Subjects.default.key)

    -- The two small pages off the timetable's left margin. One table rather
    -- than a branch apiece: they answer the same three things (`enter`,
    -- `update` returning "back", `draw`) and are keyed by the state they are,
    -- which is all `Game:toPage` needs. src/blank.lua is the page with nothing
    -- on it; nothing instances it today.
    self.pages = {
        homework = Homework.new(),
        canteen = Canteen.new(),
    }

    -- Both outlive any one run: they are things on top of the game rather than
    -- part of the run they happen to be holding.
    self.pause = Pause.new()
    self.draft = LevelUp.new()
    self.win = Win.new()
    self.over = Over.new()
    -- The card the death card is replaced by for a run that bought its way out of
    -- one (src/retake.lua). Beside the other two rather than on the run, for the
    -- same reason they are: it is a thing laid over whatever run is underneath.
    self.retake = Retake.new()

    -- A press that lands on the tool selector switches tools instead of
    -- starting a stroke.
    Input.onPointerDown = function(cx, cy)
        -- The title screen is drawn on, not pressed: every pointer that lands
        -- on it is a pen, wherever it lands.
        if self.state == "menu" then return false end

        -- The timetable is a page of written lines, and every press on it taps a
        -- tab, presses the corner button or draws -- and it sorts those out
        -- itself, on the pen's press edge, so that a press which starts a stroke
        -- is not swallowed here first.
        if self.state == "timetable" then return false end

        -- And the library, which sorts its own presses out on the pen's press
        -- edge exactly as the timetable does: a name, an arrow, the corner
        -- button, or the start of a line.
        if self.state == "library" then return false end

        -- And the two pages off the timetable's other margin -- the canteen and
        -- the homework page -- which sort their own presses out on the pen's press
        -- edge as well: a footer arrow, the corner button, or the start of a line.
        if self.pages[self.state] then return false end

        -- And the settings page, for the same reason again: a bar, an arrow, the
        -- corner button, or the start of a line, all sorted out on the press edge
        -- by the screen itself (src/settings.lua).
        if self.state == "settings" then return false end

        -- The studio is drawn on too, apart from the two tool buttons beside
        -- the board, which have to be pressable mid-stroke.
        if self.state == "studio" then return Studio:pointerDown(cx, cy) end

        -- Dead, and the same rule the win card is under: there are two boxes
        -- and no way past them, so every press on the page is a pen.
        if self.state == "dead" then return false end

        -- Retaking, and it is the one screen in the book that is the other way
        -- round: nothing on it can be pressed *and* nothing on it can be drawn on,
        -- since it asks nothing and is gone in a second and a half. So the press is
        -- swallowed outright -- the alternative is a stroke begun on a card and
        -- landing on the page it lifts off, which is the line across the paper
        -- Game:holdRun exists to prevent.
        if self.state == "retaking" then return true end

        -- Levelling up: the whole page belongs to the three cards, and the only
        -- way out of it is to circle one. Nothing else on the screen is
        -- pressable, the button in the corner included -- every press draws.
        if self.state == "levelup" then return false end

        -- Won, and the same rule: there are two boxes and no way past them, so
        -- every press on the page is a pen.
        if self.state == "won" then return false end

        -- The button holds the run and lets it go again, so it is checked in
        -- both states before anything else can claim the press.
        if Hud.cornerAt(self, cx, cy) then
            self:togglePause()
            return true
        end

        -- Held: the pause screen is a page like any other and every press on it
        -- draws. Nothing reaches the run underneath, since the pen is only run
        -- while the game is playing.
        --
        -- With one exception, and it only ever exists with a dev switch thrown:
        -- the weapon column, which is a thing to read rather than press, is a
        -- window when it is lent every weapon at once, and pressing its margin
        -- turns the page of it. The draft is deliberately not given the same
        -- press -- there the whole page belongs to the three cards -- so this
        -- is the screen the long column is read on.
        if self.state == "paused" then
            if Hud.weaponAt(self, cx, cy) then
                self:scrollCarry()
                return true
            end
            return false
        end

        local index = Hud.selectorAt(self, cx, cy)
        if index then
            self:setTool(index)
            return true
        end
        return false
    end

    self:reset()
    -- ...which is scaffolding rather than a run: it exists so that a run is built
    -- and waiting behind the title screen from the first frame, and nobody has
    -- played it. So it is the one reset that does not leave something to go back
    -- to -- without this the first title screen of every launch would offer to
    -- continue a run that had never happened, and closing the program would
    -- bookmark it over the real one.
    self.resumable = false
    self:toMenu()
end

-- The title screen owns the same page the run does, so it is a state of the
-- game rather than a screen in front of it. A run is built and waiting behind
-- it either way, which is what lets YES start one on the frame it is answered.
-- `written` skips the intro and hands back a title already on the page, which is
-- what coming back from the settings page wants: you did not re-open the book,
-- you looked at the inside of the cover and came back. Every other route in
-- (starting the program, quitting a run) is opening it, and gets the intro.
function Game:toMenu(written)
    self.state = "menu"
    Menu:enter(self:canContinue())
    if written then Menu:skip() end

    -- Whatever was being held when the run was closed does not carry over: a
    -- finger still down from the scribble that quit would otherwise skip the
    -- title's intro the instant it appeared.
    Input.releaseAll()
end

-- The settings page (src/settings.lua): how loud the game is and what language it
-- is in. A loop off the side of the title screen rather than a step through it --
-- the same shape as the library off the timetable, and for the same reason:
-- nothing on it is part of starting a run, and it hands nothing over. What it
-- changes it changes where it stands and saves for itself.
function Game:toSettings()
    self.state = "settings"
    Sfx.play("transition2")
    Settings:enter()

    -- The press that opened the button is not the first mark on this page.
    Input.releaseAll()
end

-- Which page of the book the run is played on (src/subjects.lua): how it is
-- ruled, and who turns up to it. The ruling is set here rather than carried
-- around, because the page is a fact about the book being open at a particular
-- place -- the title screen, the board and the run are all drawn on whichever
-- one it is.
--
-- The crowd half is read by the spawner, which takes it when a run is built, so
-- changing subject mid-run is not a thing that can happen: you pick the page and
-- then the run is made on it.
function Game:setSubject(key)
    self.subject = Subjects.get(key)
    Background.setSubject(self.subject.key)
    -- The crowd is skinned per page (Sprites.enemySkins), and the page and the
    -- crowd standing on it are one choice, so it is set here or nowhere.
    Sprites.setSkin(self.subject.key)
end

-- The timetable (src/timetable.lua), which is both the way into a run and the way
-- back from the drawing board.
--
-- The board is reached from here rather than the other way round, and that is not
-- an arrangement of screens: the ruling is what a drawing is read against, so a
-- hero drawn on one page and played on another is a hero you sized against the
-- wrong lines. Going through the lesson first is what guarantees the board is
-- standing on the page the run will be.
function Game:toTimetable()
    self.state = "timetable"
    -- The long transition is the page turning; the short one is the run being
    -- held and let go. Everything that moves between whole pages -- title to
    -- timetable, out to the board and back, timetable to run -- gets this one.
    Sfx.play("transition2")
    Timetable:enter(self.subject.key)

    -- The scribble that answered the title screen is not the first mark on this
    -- one.
    Input.releaseAll()
end

-- The drawing board, which the game goes to from two places. From the timetable
-- it is the player character, asked for by `CUSTOM` rather than handed to you on
-- the way in: a run starts with the hero you already have, and the board is where
-- you go when you want a different one -- so it hands the screen straight back to
-- the timetable, where `GO!` is. Mid-run it is a weapon the draft has just given
-- you, and the run stays held underneath exactly as the draft left it.
--
-- `back` is what to do when the board is handed over -- "timetable" to go back to
-- the lesson it was opened from, "held" to let the held run go again.
function Game:toStudio(design, back)
    self.state = "studio"
    self.studioBack = back
    Sfx.play("transition2")
    Studio:enter(design)

    -- The pen that answered the screen before -- the title's YES, the draft's
    -- loop -- is not the first stroke of the drawing.
    Input.releaseAll()
end

-- The catalogue, read from the timetable and handed straight back to it. It is a
-- loop off the side of the lesson rather than a step on the way through one --
-- the same shape as the drawing board, and for the same reason: what is on it is
-- worth reading *before* the run and is not part of starting one.
--
-- Nothing about the run is passed in or comes back out, because there is no run:
-- the library is the catalogue rather than the loadout, and the page it is drawn
-- on is whichever lesson you were looking at when you opened it.
-- The canteen (src/canteen.lua) and the homework page (src/homework.lua), read from
-- the timetable and handed straight back to it, on exactly the library's terms:
-- loops off the side of the lesson rather than steps on the way through one,
-- nothing passed in and nothing coming back out. `key` is both the state and
-- which page it is, which is why one door does for both of them however
-- differently they grow.
function Game:toPage(key)
    self.state = key
    Sfx.play("transition2")
    self.pages[key]:enter()

    -- The press that opened the tab is not the first mark on this page.
    Input.releaseAll()
end

function Game:toLibrary()
    self.state = "library"
    Sfx.play("transition2")
    Library:enter()

    -- The press that opened the tab is not the first mark on this page.
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

-- How far the run got, kept against the page it was played on
-- (src/records.lua), which is the only thing in this game that outlives a run
-- apart from what you drew.
--
-- Called from every route out of a run rather than from one -- dying, beating
-- the eye, and walking out through the pause card are all the same fact, that
-- this is where the run stopped -- and it is safe to call twice because a record
-- is a maximum: a win banks the ten minutes, and ENDLESS carrying on and dying
-- at nineteen banks nineteen over the top of it.
function Game:bankRun()
    if not self.subject or not self.time then return end
    -- The course goes with it, and the register files it against the clock rather
    -- than as a fourth maximum (src/records.lua): what it says is which class the
    -- longest run on this page was sat in.
    Records.submit(self.subject.key, self.time, self.kills, self.eyes,
        self.course and self.course.key)

    -- And the same fact filed against the hero rather than the page
    -- (src/characters.lua): how long the longest run as him lasted, which is what
    -- takes the weapon he carries out of his own hands and puts it in everybody
    -- else's draft (src/collection.lua). Banked here beside the record and not
    -- beside the coins because it is a maximum rather than a payment -- every route
    -- out of a run may submit it, and submitting twice cannot be worth anything.
    Characters.submit(Characters.current.key, self.time)

    -- And the third register, which is not a maximum at all: what the book has
    -- done, added up (src/tally.lua). Called from here rather than from
    -- Game:cashRun, though a tally and a payout are the same kind of number,
    -- because they are owed at different moments -- a run walked out of through
    -- the pause card is paid nothing and has still killed everything it killed.
    self:bankTally()
end

-- The difference between what the run holds and what it has already paid in, and
-- then the watermark moved up to meet it. Every number here only ever goes up, so
-- this is exactly the work done since the last time it was called -- which is what
-- makes it as safe to call as everything above it: twice in a row hands over
-- nothing, and a run walked out of and carried on hands over the second half only.
function Game:bankTally()
    local paid = self.tallied
    local hand = { kills = {}, bosses = self.eyes - paid.bosses,
                   time = self.time - paid.time }

    for kind, n in pairs(self.killsBy) do
        hand.kills[kind] = n - (paid.kills[kind] or 0)
        paid.kills[kind] = n
    end
    paid.bosses, paid.time = self.eyes, self.time

    Tally.add(hand)
end

-- What the run is paid for (src/purse.lua), and the one door to it.
--
-- Deliberately *not* Game:bankRun, though the two are a line apart. A record is a
-- maximum and can be submitted from anywhere as often as you like; coins add up,
-- so paying one out twice for the same kills is money made out of nothing. So
-- this is called from the two places a run actually *ends* -- dying, and `END` on
-- the win card -- which is the same pair that turns `self.resumable` off, and
-- never from the pause card: walking out does not end a run, it leaves one, and
-- the run it left is still there to be finished. ENDLESS is not an ending either,
-- which is what keeps this honest without a watermark of what has been paid --
-- a run that shuts the eye and carries on is paid once, at the end, for
-- everything it did, both eyes included.
function Game:cashRun()
    if not self.time then return end
    Purse.earn(self:runWorth())
end

-- What the run is worth in coins (src/purse.lua), and the one place the run is
-- turned into the four things the sum is made of. Three callers -- the money
-- actually being paid, and the two cards printing what it was -- so the terms are
-- gathered here rather than three times over, and the day the sum grows a fifth
-- term this is the only place that has to hand it over.
--
-- The grade is worked out the way the card that prints it works it out
-- (src/mark.lua): awarded on a win, measured off the clock otherwise. Which is
-- what keeps the letter and the figure under it talking about the same run --
-- they are two readings of one thing, and a card whose grade and payout
-- disagreed would be a card arguing with itself. It is handed over as the *rung*
-- rather than as the letter because the purse is arithmetic on numbers and a
-- letter is not one; asking src/mark.lua here is the same call the cards make.
--
-- And the rate the whole sum is reckoned at, which is the course the run was sat
-- at (src/course.lua). Off the run rather than off the pick, for the reason it is
-- on the run at all: a run walked out of through the pause card and continued
-- after a trip to the timetable must be paid for the class it was sat in.
function Game:runWorth(won)
    return Purse.forRun({
        kills = self.kills,
        skips = self.skipped,
        rung = Mark.rung(Mark.forRun(self.time or 0, won or false)),
        eyes = self.eyes,
        pay = (self.course or Course.default).pay,
    })
end

-- The program is closing (love.quit in main.lua), which is the last chance to
-- leave a bookmark for the next launch (src/bookmark.lua).
--
-- It writes and it never clears, and that asymmetry is the whole of it: closing
-- the book without having played must not throw away the bookmark that was
-- sitting there when it was opened. So the three things that clear the file are
-- the three ways a run *ends* -- dying, `END`, and `GO!` starting the next one --
-- and this only ever has something to say when there is a run worth keeping.
--
-- It is not the only write. Walking out through the pause card writes too, even
-- though the run is still in memory and CONTINUE would hand that back instead: a
-- deliberate exit is the moment worth spending a file write on, and being killed
-- from outside -- a force quit, a crash -- never reaches here at all.
function Game:closing()
    if self.resumable then Bookmark.save(self) end
end

function Game:reset()
    -- Everything the run has learned, and the only thing the player is built
    -- from: speed, health, how hard anything hits and what fights alongside it
    -- all come off this, so it exists before the player does.
    -- Two lines the run is handed rather than offered: the lesson's tool and the
    -- character's weapon (src/subjects.lua, src/characters.lua). Both are taken
    -- to level one here and both spend a slot, which is why they are the loadout's
    -- business and not the player's -- a hero no longer carries an attack of his
    -- own (src/player.lua).
    self.loadout = Loadout.new(self.vw, self.vh,
        self.subject.tool, Characters.current.weapon)

    self.player = Player.new(0, 0, self.loadout)
    self.enemies = {}
    -- The eye boss while one is on the page, so the HUD can hang a bar off it
    -- and the spawner can be asked whether the fight is still going. Held by
    -- reference like everything else that found its victim through the hash --
    -- Game:killEnemy is what clears it.
    self.boss = nil
    self.bullets = {}
    self.shots = {} -- enemy fire: the eye's pellets (Game:updateEnemyShots)
    -- The eye boss's wet trail (src/puddle.lua): ground that has stopped being
    -- safe. Page-level, like the marks, and it dries off on its own clock.
    self.puddles = {}
    -- The box the boss fight happens in (src/arena.lua), and nil every other
    -- minute of a run: an open page is the normal state and the box is the
    -- exception, so everything that asks about it asks `if self.arena`.
    self.arena = nil
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
    -- paper for good -- everything but a staple the run bought the level to pull
    -- back out again (`prise` in src/staple.lua), which reaches the end of its
    -- hold and then leaves the page rather than joining it.
    self.drops = {}
    self.spent = {}
    self.rulers = {}
    self.ruler = nil
    self.compasses = {}
    self.compass = nil
    -- Cuts still closing over, and the anchor a first tap left on the page
    -- waiting for its second. `cutFrom` is the only thing in the game one press
    -- leaves behind for the next one -- see Game:openCut.
    self.cuts = {}
    self.cutFrom = nil
    self.walls = Walls.new()
    self.wallsDirty = false
    -- Where the last staple of a seam went, while one is being raked
    -- (Game:rakeDrops); nothing while the pointer is up, so a press that began
    -- under another tool rakes nothing, exactly as it aims nothing.
    self.rakeX, self.rakeY = nil, nil
    self.hasSlick = false
    self.hasFire = false
    self.hasPull = false
    self.particles = Particles.new()
    -- What the run is doing to the horde, in numbers thrown up off it
    -- (src/damage.lua). A run thing rather than a page thing: it is a readout,
    -- so nothing it draws is a mark and none of it survives the run.
    self.damage = Damage.new()
    -- The fun word a wide gesture earns, next to the numbers each hit inside
    -- it already gets (src/multikill.lua). A run thing for the same reason
    -- `self.damage` is: a readout, so nothing it draws is a mark and none of
    -- it survives the run.
    self.multikill = Multikill.new()
    -- Which class this run is being sat as (src/course.lua), taken off the pick
    -- once and then belonging to the run rather than to the book. That is the
    -- whole reason it is copied here instead of being read where it is wanted: the
    -- pick is a setting on a screen, and a run walked out of through the pause
    -- card, changed on the timetable and then continued would otherwise be paid
    -- and recorded at a course it was never played at.
    self.course = Course.at()
    -- The horde is half of what a subject is, and the spawner is where that half
    -- lives. Handed over once, here, with the course beside it: the page a run is
    -- played on and the class it is sat as are both decided before the run exists
    -- and neither can change while it is going on.
    self.spawner = Spawner.new(self.subject, self.course)
    self.time = 0
    self.kills = 0
    -- And the same body count broken out by what died, which is the one thing the
    -- register has never kept and the homework page is entirely made of
    -- (src/challenges.lua). A run thing exactly as `kills` is -- counted in
    -- Game:killEnemy beside it, and handed over to src/tally.lua when the run says
    -- what it did.
    self.killsBy = {}
    -- What of the above has already been paid into the book's lifetime counters.
    -- A tally adds up where a record is a maximum, so `Game:bankTally` may not
    -- simply resubmit: it hands over the difference, and this is the watermark it
    -- is struck off. Everything in it only ever goes up, so a difference is always
    -- the work done since the last bank -- see src/tally.lua for why the awkward
    -- half of that lives here and the rest of the game knows nothing about it.
    self.tallied = { kills = {}, bosses = 0, time = 0 }
    -- How many eyes this run has put down. A run thing exactly as `kills` is, and
    -- kept as a count rather than read off the spawner's cycle because the two are
    -- different facts for the length of the win card: the eye is down and the cycle
    -- has not turned. It is the fourth term of what the run pays out
    -- (`Game:runWorth`) and the third number the register keeps (src/records.lua),
    -- where it is also the milestone the last of the collection's gates asks for.
    self.eyes = 0
    -- What the run may do to a draft, and what it has done with it
    -- (src/perks.lua). A fresh count of uses per line bought, and a tally of the
    -- levels sold back -- which is the second term of what the run pays out
    -- (`Purse.forRun`), so it is run state exactly as `kills` is and is banked with
    -- it. Only lines actually bought are in the table, so a book that has never
    -- been to the canteen hands the draft no corner at all.
    self.perks = Perks.forRun()
    self.skipped = 0
    self.state = "playing"
    self.pendingWin = false
    -- Whether this run is worth going back to, which is the one question both
    -- halves of CONTINUE are asked (Game:continueRun, src/bookmark.lua): it is
    -- what puts the box on the title screen for a run still standing in memory,
    -- and it is what says whether closing the program should leave a bookmark
    -- behind. True from here on, because a run being built is a run being
    -- played; the three things that make it false are the three ways a run
    -- *ends* -- dying, `END` on the win card, and the scaffolding run Game:load
    -- builds before the title has drawn a letter, which nobody played.
    --
    -- Walking out through the pause card is deliberately not one of them. That is
    -- the whole feature: quitting to the title does not end a run, it leaves one.
    self.resumable = true

    self.tool = 1
    self.toolLabel = 0
    -- Which weapon stands at the top of the weapon column, for the one case that
    -- column is longer than the page (Game:scrollCarry). Zero on every real run,
    -- since a drafted one never fills it.
    self.carryScroll = 0
    self.notice, self.noticeT = nil, 0
    self.ink = self.loadout.stats.inkMax
    self.inkDelay = 0
    self.drawBlocked = false
    self.wasDown = false
    -- What the current stroke sounds like: the swish it last fired, and how
    -- fast the nib has been moving lately (canvas px/s), which is what picks
    -- the next one. See Game:strokeSwish.
    self.strokeVoice = nil
    self.drawSpeed = 0

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
--
-- Half a cut goes too, and that one is not the same bargain: nothing has been
-- paid for an anchor, so there is no ink to pocket. What it would be instead is
-- a line cut across a page the horde had spent a whole draft screen walking
-- over, which is the aim's problem wearing a longer clock.
function Game:holdRun()
    self:endStroke()
    self:snapRuler()
    self:swingCompass()
    self:dropCut()
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
        Sfx.play("transition")
        self.pause:open()
        self:holdRun()
    elseif self.state == "paused" then
        self.state = "playing"
        Sfx.play("transition")
        self:releaseRun()
    end
end

-- The book put down mid-lesson: the phone locked, or the app sent to the
-- background. Android freezes the program where it stands -- SDL blocks the
-- thread the whole game runs on until the app is opened again -- so nothing is
-- lost while it is away and no enemy gets a free second on a player who is not
-- there. But nothing is *held* either, and without this the run would come back
-- live the instant the screen does, with the horde already touching a thumb that
-- is nowhere near the stick. So it comes back on the pause card instead, which
-- is the answer this game gives every other interruption, and waits to be asked
-- before it starts again.
--
-- Only a run can be put down. Every other state is either a question already
-- waiting to be answered or a screen with nothing running on it, and both of
-- those survive being left perfectly well.
--
-- The desktop is not just along for the ride here: a minimised window goes on
-- updating (LOVE does not stop for it the way Android does), so on that side
-- this is what stops a run playing itself out while nobody is watching.
function Game:putDown()
    if self.state == "playing" then self:togglePause() end
end

--- levelling up --------------------------------------------------------------

-- A level was reached, so the run stops and asks what to do with it.
--
-- It has something to ask however long the run has gone on. The catalogue does
-- still run out -- a run may only start so many lines (`Loadout.SLOTS`) and it
-- reaches the last level it has room for while the horde is very much still
-- arriving -- but `Loadout:roll` fills what the catalogue cannot with the
-- endless lines (src/upgrades.lua), so past that point the draft goes on coming
-- up and a level goes on costing the run its momentum. A level that landed and
-- was never asked about used to be the ordinary end state of a long run; now
-- there is no such level.
--
-- The false return is kept for the one thing that can still produce it: an empty
-- endless table, which is a catalogue nobody has finished writing rather than a
-- run that has finished being played. The run carries on unasked, exactly as it
-- used to, rather than stopping on a draft with no cards on it.
function Game:openDraft()
    local offer = self.loadout:roll(DRAFT_SIZE)
    if #offer == 0 then
        self.player.pending = 0
        return false
    end

    self.state = "levelup"
    -- A door of its own rather than the transition every other screen is walked
    -- through, because this is the one screen a run does not walk to: it lands
    -- on you mid-fight, out of a kill you were not thinking about, and the sound
    -- is the first thing that says the horde has stopped moving.
    Sfx.play("levelup_enter")
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

    -- A fusion is the one card that takes tools *off* the strip (`fuses` in
    -- src/upgrades.lua), so it is the one card after which the slot in hand is no
    -- longer the tool that was in it. Land on the thing just made: it is what the
    -- card was about, and a run that fused two tools and came back holding a
    -- third one it did not pick would have to go and find the new one. The clamp
    -- underneath is the safety net the dev toggle already needed -- the strip can
    -- only ever have shrunk here, and the lesson's tool is always there to land
    -- on.
    if up.fuses then
        for i, slot in ipairs(self.loadout.equipped) do
            if slot.up.id == up.id then self.tool = i end
        end
    end
    self.tool = math.min(self.tool, math.max(1, #self.loadout.equipped))

    self:say(up.name)

    -- A weapon you draw rather than one you are handed: the first level of the
    -- line sends you to the board before the run starts moving again. Only the
    -- first, because the levels after it change what the thing does and not what
    -- it looks like -- and the run is already held, so the board simply carries
    -- on holding it.
    --
    -- Unless the player has turned the asking off (`Design.ask`, set on the
    -- settings page): then the weapon arrives wearing whatever is already on its
    -- file, which is either what they drew the last time they were asked or the
    -- drawing they were handed to draw over. Nothing is lost by not being asked --
    -- the board is still there, one `CUSTOM` and one draft away -- and what is
    -- bought is a run that does not stop dead on a blank grid every time it
    -- levels.
    if up.design and self.loadout:levelOf(id) == 1 and Design.ask then
        self:toStudio(Design.by[up.design], "held")
        return
    end

    self:resumeRun()
end

--- what a run may do to a draft -----------------------------------------------

-- The three things the canteen sells (src/perks.lua), spent here. The draft itself
-- knows what was pressed and nothing about what it costs -- it hands back a word
-- and these three are what the word means -- which is the same split the cards are
-- already under: src/levelup.lua does not know what any upgrade does either.
--
-- All three take the use *first* and unconditionally. A use spent on a deal that
-- turned out no better is still a use spent, exactly as a level taken on a line
-- that turned out wrong is still a level, and a perk that only charged you when you
-- liked the result would be a perk with no decision in it.

-- REROLL: three more cards off the same catalogue. `player.pending` is untouched,
-- because the level has not been spent -- it is still being asked about.
function Game:rerollDraft()
    -- The one thing that can come back empty is the thing Game:openDraft guards
    -- against too: a catalogue and an endless table with nothing left in them
    -- between them. The use is still spent -- it was pressed -- but the cards on
    -- the table are left where they are rather than swapped for nothing.
    local offer = self.loadout:roll(DRAFT_SIZE)
    self.perks.reroll = self.perks.reroll - 1
    Sfx.play("transition")
    self.draft:open(self, #offer > 0 and offer or self.draft.offer)
end

-- SKIP: the level is sold back for coins instead of spent on a card. The level is
-- spent -- it is gone off `pending` like any other -- and `skipped` is what turns
-- it into money at the end of the run (`Purse.forRun`), which is why it is banked
-- as a count here rather than paid into the purse on the spot: a run that is
-- walked out of through the pause card has not ended, and nothing it did is paid
-- for until it has.
function Game:skipDraft()
    self.perks.skip = self.perks.skip - 1
    self.skipped = self.skipped + 1
    self.player.pending = self.player.pending - 1
    -- No sound of its own, unlike the two perks either side of it. Those press a
    -- button and stay on the page, so they owe you a noise saying it did
    -- something; this one presses a button and walks straight out, and the door
    -- shutting behind it (Game:resumeRun) is already that noise. Two at once used
    -- to be two transitions stacked, which read as one loud transition and hid
    -- the doubling; against a door with a voice of its own it would not.
    self:resumeRun()
end

-- EXPEL: the line named is out of the run for good, and one fresh card takes its
-- place. The two cards still lying on the table stay exactly where they are, which
-- is the whole difference between this and a reroll -- expelling is an opinion
-- about one card, so it may not quietly re-ask the other two.
--
-- The replacement is rolled with the survivors passed as `avoid`, so it can be
-- neither of them, and after the ban, so it cannot be the line just thrown out. A
-- catalogue with nothing left to deal comes back empty and the draft goes on with
-- two cards rather than three -- which is why the button refuses to throw out the
-- last card on the table (`LevelUp:usable`): two is a question and none is a run
-- with no way out of a screen.
function Game:expelLine(id)
    local keep = {}
    for _, up in ipairs(self.draft.offer) do
        if up.id ~= id then keep[#keep + 1] = up end
    end

    self.loadout:expel(id)
    for _, up in ipairs(self.loadout:roll(1, keep)) do
        keep[#keep + 1] = up
    end

    self.perks.expel = self.perks.expel - 1
    Sfx.play("transition")
    self.draft:open(self, keep)
end

-- Back to the run that the draft, and the board after it, were holding. The next
-- banked level -- a big pickup can carry two -- opens its own draft rather than
-- being swallowed by the one just spent.
function Game:resumeRun()
    if self.player.pending > 0 and self:openDraft() then return end

    -- Which door the run comes back through, asked off the state on the way in
    -- rather than told by the caller. Five things call this and only two of them
    -- are the draft being left -- a card taken (Game:takeUpgrade) and a level
    -- sold (Game:skipDraft); the other three are the win card taking ENDLESS, the
    -- drawing board handing a weapon back, and the retake card timing out, and
    -- each of those is its own event with its own screen behind it. So the draft
    -- shuts in the voice it opened in, everything else comes back on the
    -- transition it always did, and no caller has to say which it is.
    --
    -- The early return above is the third case and wants neither: a second banked
    -- level opens its own draft on this frame, and a page you never left has no
    -- door to shut.
    local fromDraft = self.state == "levelup"

    self.state = "playing"
    Sfx.play(fromDraft and "levelup_exit" or "transition")
    self:releaseRun()
end

-- Whether the title screen has a third box on it. Two quite different things can
-- put it there and the box says CONTINUE for both, because from where the player
-- is standing they are one offer -- go back to the run you were on.
--
-- What they are not is equally good, which is why the live one is asked about
-- first everywhere: a run still in memory comes back whole, page and all, and a
-- bookmark comes back on fresh paper (src/bookmark.lua).
function Game:canContinue()
    return self.resumable or Bookmark.run ~= nil
end

-- The third box was answered. Two routes and the order between them is the whole
-- of the rule: whatever is still in memory beats whatever is on disk, always,
-- because it is the same run rather than a description of one.
function Game:continueRun()
    if self.resumable then
        self:resumeHeldRun()
    else
        self:openBookmark()
    end
end

-- The run the title screen was standing in front of, given back exactly as it
-- was walked out of. Nothing here rebuilds anything, because nothing was torn
-- down: Game:reset is the only thing that replaces a run, and walking out
-- through the pause card does not call it -- the page, the horde, the ink that
-- was left, the clock and the marks are all still sitting there behind the
-- title, on the very page the title is drawn on.
--
-- So this is Game:togglePause's other half rather than a load: the pause card
-- already held the run (Game:holdRun), and all that is owed is letting it go.
-- Which also means the record has already been banked -- Game:bankRun ran on
-- the way out and a record is a maximum, so carrying on and going further banks
-- the further number over the top of it.
--
-- Straight back into play rather than onto the pause card, for the reason the
-- dead page restarts on a tap: you have just answered a box asking to carry on,
-- and landing on a card asking whether to quit would be the game asking the
-- opposite question. The run-up is the title screen pulling the page away, the
-- same three quarters of a second YES gets.
function Game:resumeHeldRun()
    self.state = "playing"
    Sfx.play("transition2")
    self:releaseRun()
end

-- And the other half: no run in memory, so one is built from the bookmark the
-- last launch left (src/bookmark.lua). This is a fresh run that has been told
-- what the last one had learned, and every line of it is a deliberate overwrite
-- of something Game:reset just decided.
--
-- The order is the load-bearing part:
--
-- 1. The **page and the hero first**, because Game:reset builds the loadout off
--    the lesson's tool and the character's weapon and the player off the loadout.
--    Setting them after would be a run wearing one hero and holding another's
--    arm.
-- 2. Then **reset**, which is what makes this a run at all -- the spawner, the
--    grid, the walls, the empty page, and `resumable` going true again.
-- 3. Then the **levels**, replayed from scratch (`Loadout:restore`), and
--    `applyStats` so the player catches up with the health they buy.
-- 4. Then the **numbers the run had reached**, health and ink and ladder last of
--    all, since they are clamped against what step 3 worked out.
--
-- What is deliberately *not* put back is the page: no marks, no horde, no pins,
-- no puddles, nothing that was standing on the paper. See src/bookmark.lua for
-- why that is the shape of the feature rather than a corner cut.
function Game:openBookmark()
    local mark = Bookmark.run
    if not mark then return end

    self:setSubject(mark.subject)
    Characters.pick(mark.character)
    -- And the class it was being sat as, before `reset` copies the pick onto the
    -- run. Clamped to what has been paid for (`Course.pick`), so a bookmark
    -- written before a refund comes back at the top of what is left rather than at
    -- a doctorate the book no longer owns.
    Course.pick(mark.course)
    Design.applyHero()

    self:reset()

    self.loadout:restore(mark.lines, self.vw, self.vh)
    for _, id in ipairs(mark.banned) do self.loadout:expel(id) end
    self.player:applyStats()
    self.player:restore(mark.level, mark.xp, mark.pending, mark.hp)

    self.ink = math.min(mark.ink, self.loadout.stats.inkMax)
    -- A slot on the strip rather than a row of the catalogue, so it is clamped to
    -- what this run actually unlocked -- which is the same list it was written
    -- from, unless the catalogue changed under it.
    self.tool = util.clamp(mark.tool, 1, math.max(1, #self.loadout.equipped))

    self.time = mark.time
    self.kills = mark.kills
    -- And the watermark with them, because these two are numbers the run *already
    -- paid in* on the afternoon it was bookmarked: walking out through the pause
    -- card banks (Game:bankRun), and a tally banked twice is time and bodies made
    -- out of nothing. `killsBy` is deliberately left empty on both sides of the
    -- comparison -- a bookmark does not carry it, and an empty watermark against an
    -- empty count is the right answer rather than a gap.
    self.tallied.time = mark.time
    -- Derived rather than written down, and it is the honest number rather than
    -- the cheap one: a bookmark drops the page and everything standing on it, the
    -- eye included, so a run that comes back has to shut whatever eye was up all
    -- over again. `cycleStart` is what sends it (see src/bookmark.lua), and the
    -- cycle only turns once one has actually gone down and ENDLESS has been taken
    -- -- so cycles completed is exactly the eyes this run still has to its name.
    self.eyes = mark.cycle - 1
    self.tallied.bosses = self.eyes
    -- What it had left to spend on a draft, and what it had already sold back
    -- (src/perks.lua). Replaced rather than merged, exactly as the levels are:
    -- Game:reset has just handed this run a full set out of what the *book* owns,
    -- and the bookmark is what the run had actually got down to.
    self.skipped = mark.skipped
    for key, left in pairs(mark.perks) do
        -- Only for a line the book still owns, and never more of it than the book
        -- owns: a bookmark written before a perk was refunded -- or edited by hand
        -- -- may not hand a run something it never bought.
        if self.perks[key] then
            self.perks[key] = math.min(left, self.perks[key])
        end
    end
    -- The difficulty clock, which is the whole of why a bookmark is worth having:
    -- coming back at minute seven has to mean coming back to minute seven's
    -- horde. `cycleStart` is also what re-sends the eye for a run bookmarked
    -- during a boss fight -- see the note in src/bookmark.lua.
    self.spawner.cycle = mark.cycle
    self.spawner.cycleStart = mark.cycleStart

    Sfx.play("transition2")
end

--- the arena -------------------------------------------------------------------

-- The ten minutes are up. Somebody boxes off the part of the page you are
-- standing on (src/arena.lua), and the eye walks into it.
--
-- Pinned on the player rather than on the boss, and measured off the viewport
-- rather than written down in pixels, so the box is the same fraction of what
-- you can see on a phone as on a desktop. `Spawner:sendBoss` is what calls this,
-- because what phase a run is in is a fact the spawner owns.
function Game:openArena()
    self.arena = Arena.new(self.player.x, self.player.y, self.vw, self.vh)
end

-- ENDLESS, or a run being built fresh. The next ten minutes are horde again, and
-- the horde is the half of this game that is played on an open page -- a box
-- round a run with no boss in it would just be a smaller game.
function Game:closeArena()
    self.arena = nil
end

--- ending ---------------------------------------------------------------------

-- Whether the run has bought its way out of the next ending (RETAKE,
-- src/perks.lua). One question, asked in one place -- the frame the health runs
-- out -- and it is the only thing standing between Game:openRetake and
-- Game:openDeath, which is what keeps the two of them from having to agree about
-- anything.
function Game:canRetake()
    return (self.perks.retake or 0) > 0
end

-- The health ran out and the run had a retake left, so it does not end. The hero
-- gets up where he fell on half a page of health with a couple of seconds nothing
-- can touch him for (`Player:revive`), and a card says so and lifts off
-- (src/retake.lua).
--
-- **This is Game:holdRun and not Game:openDeath, and the difference is everything
-- either of them does.** Dying takes the stick and leaves the run where it lies
-- because there is nothing to give back; this is the pause card's freeze with a
-- different card on it, because every bit of it is about to be given back -- so the
-- open stroke is closed, the paid-for aims are landed and the anchor is dropped,
-- exactly as they are for a level landing. A stroke left open across this would
-- come back down wherever the pointer had wandered to, and the whole point of a
-- retake is that the page you get back is the page you left.
--
-- The burst is **blue**, which is the one place this differs from being killed. Red
-- is the other side of the fight and a red burst is what dying looks like; getting
-- up is yours, and the run's own colour is what says so before a letter has been
-- drawn.
--
-- The use is spent here and unconditionally, the way the three at the draft are:
-- there is nothing to refuse and nobody to ask. And it is spent *before* the card
-- is opened, so what the card prints is what is left rather than what was left.
function Game:openRetake()
    self.state = "retaking"
    self.perks.retake = self.perks.retake - 1

    self.player:revive()
    self.particles:burst(self.player.x, self.player.y, 16, Palette.blue)
    -- The card's own arrival, the same paper being laid over the same run the win
    -- and death cards are announced with -- and the quiet one of the pair for the
    -- death card's reason, since this is a card laid on a page rather than a thing
    -- happening on one.
    Sfx.play("transition2")

    self:holdRun()
    self.retake:open(self.perks.retake, Perks.level("retake"))
end

-- The run is over, and there is a card to answer (src/over.lua): RETRY builds the
-- next one, QUIT hands the page back to the title screen.
--
-- **Not Game:holdRun, and the difference is the sound.** A run that has been
-- killed is not a run being held -- there is nothing here to give back -- and the
-- one thing holding does that this must not is speak: it ends the open stroke
-- through Game:endStroke, and the rubber's release pop fired over the death burst
-- would say the crumbs had been swept rather than that you had been killed. So
-- the rub's loop is stopped by hand and silently, and the stroke is left where it
-- was; nothing updates it again.
--
-- What is taken is the thumb stick, which is the one thing the card genuinely
-- needs: there is nobody left to walk, and a box under the stick's own quadrant
-- is a box whose scribble would be swallowed on the way in.
function Game:openDeath()
    self.state = "dead"
    self:bankRun()
    -- An ending, so there is nothing to go back to: the box comes off the title
    -- screen and the bookmark comes off the disk. Both halves of CONTINUE are the
    -- same offer and a run that is over is not it.
    self.resumable = false
    Bookmark.clear()
    Sfx.stopLoop("rubbing")
    self.particles:burst(self.player.x, self.player.y, 16, Palette.red)
    -- The win card's own sound, since it is the win card's own arrival: a page
    -- being laid over the run. Under the burst rather than over it, which is why
    -- it is the quiet one of the two.
    Sfx.play("transition2")

    self.wasDown = false
    Input.stickEnabled = false

    -- Paid before the card is opened, so what it prints is what is in the purse
    -- rather than what would be if you were paid.
    self:cashRun()
    self.over:open(self.time, self.kills, self:runWorth(),
        (self.course or Course.default).name)
end

--- winning --------------------------------------------------------------------

-- The eye is down. The run is held the way the pause card holds it -- the page,
-- the horde that walked in with the boss, the ink you had left -- because one of
-- the two answers on the card gives all of it back.
function Game:openWin()
    self.pendingWin = false
    self.state = "won"
    Sfx.play("transition2")
    self:bankRun()
    self:holdRun()
    -- What the run is worth is shown but not yet paid: the eye going down is not
    -- the end of a run, `END` is (Game:cashRun), and ENDLESS is a bet that the
    -- number on the card will be bigger by the time it is collected.
    self.win:open(self.time, self.kills, self.spawner.cycle, self:runWorth(true),
        (self.course or Course.default).name)
end

-- ENDLESS. Another ten minutes and another eye at the end of them, with the
-- horde picking up where it left off rather than starting over: the difficulty
-- clock is the run's, and only the cycle's own count of hp and damage steps up
-- (`Spawner:nextCycle`).
--
-- Through resumeRun rather than straight back to playing, because the boss is
-- worth a level or two on its own and those are banked: the draft comes up
-- immediately after the card, the same way it does after the drawing board.
function Game:beginNextCycle()
    self.spawner:nextCycle(self)
    self:resumeRun()
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
        self:dropCut()
        self.tool = index
        self.toolLabel = 1.4
    end
end

-- One half of the dev toggle, for playtesting: every line of one kind at once,
-- granted and taken back from the pause screen. `kind` is a switch's kind off
-- `Pause.DEV` -- "tool" or "weapon" -- and the two are independent, so a playtest
-- can borrow the strip without burying the page under thirteen weapons, or the
-- other way round.
--
-- The run is already held when this can fire, so no stroke or aim is open to be
-- orphaned by the strip changing under it -- but handing the tools back can
-- shrink the strip, so the slot in hand is clamped back onto what is left. The
-- pencil is always there to be clamped to. Clamped for either kind rather than
-- just the tools: handing weapons back leaves the strip alone, so the clamp
-- finds nothing to do and asking which kind it was would only be a branch that
-- has to stay in step with the strip.
function Game:toggleDev(kind)
    if self.loadout:lent(kind) then
        self.loadout:revoke(kind, self.vw, self.vh)
        self.tool = math.min(self.tool, #self.loadout.equipped)
    else
        self.loadout:grant(kind, self.vw, self.vh)
    end
end

-- The other half of a lent column: the weapon column has nothing in it that is
-- picked, so the window over it (Hud.weaponWindow) is turned by hand. A page at
-- a time rather than a box at a time -- twelve weapons against room for ten is
-- two presses to see all of them and a third back to the start -- and it wraps,
-- because a column that stops scrolling is a column you have to know is finished.
function Game:scrollCarry()
    local first, shown, count = Hud.weaponWindow(self)
    if shown >= count then return end

    -- A page on, unless the window is already against the foot of the list, in
    -- which case it goes back to the top: a last page that is half a page is
    -- still a page you have to be able to see all of, so it is clamped to the
    -- end rather than skipped over on the way round.
    local last = count - shown
    local at = first - 1
    self.carryScroll = at >= last and 0 or math.min(last, at + shown)
end

--- spawning -----------------------------------------------------------------

-- How much harder than written down anything spawning right now is: how many
-- minutes of horde the run has been through, worked out by the spawner. Asked
-- once per spawn and baked into the monster, so nothing already walking changes.
--
-- `kind` is passed on because the eye is priced on a different curve to the
-- horde (src/spawner.lua), and it is forwarded rather than special-cased here
-- for the usual reason: this function's job is to ask, and which curve the
-- answer comes off is the spawner's business alone.
function Game:enemyScale(kind)
    return self.spawner:scale(self.time, false, kind)
end

-- The one line of text the run says over the page (drawn by src/hud.lua, which
-- puts it through I18n.t on the way). It is one method rather than two fields
-- set in three places because there is now a fourth caller and it is not in this
-- file: the spawner names a drill the first time it happens (Spawner:announce).
-- Last one wins, deliberately -- if a wall walks on in the same second you took
-- a level, the wall is the more urgent thing to have said.
function Game:say(text)
    self.notice, self.noticeT = text, NOTICE_TIME
end

-- `scale` is optional and is how hard this *one* arrival is, which is not always
-- how hard the run currently is: a blot's drops carry the blot's own scale
-- (Game:splitEnemy) and a champion carries a multiplied one (src/spawner.lua).
-- Left out, it is the run's, which is what every ordinary spawn wants -- and
-- which is what a *blow-up's* children get, deliberately: see Game:splitEnemy.
function Game:spawnEnemy(kind, x, y, scale)
    -- Everything walks on from the ring, and during a boss fight the ring is
    -- mostly outside the box. Putting the arrival back inside here rather than
    -- at each call site means the spawner goes on picking a point on a circle
    -- and knows nothing about the box at all.
    if self.arena then x, y = self.arena:clamp(x, y, 10) end

    local e = Enemy.new(kind, x, y, scale or self:enemyScale(kind))
    self.enemies[#self.enemies + 1] = e

    -- There is only ever one, and the run has to be able to find it without
    -- walking the horde: the HUD reads its health every frame.
    if e.def.boss then
        self.boss = e
        self:say("THE EYE IS OPEN")
    end

    -- Handed back for the drills (src/spawner.lua), which spawn a shape and then
    -- have to tell every monster in it where to march. Nothing else uses it, and
    -- nothing else should have to: an ordinary arrival is finished the moment it
    -- is on the page.
    return e
end

-- `speed` is optional and the block that fired the pellet is what says it (see
-- src/bullet.lua): the SHOT line sells how fast one goes, so it is carried on the
-- bullet rather than being a constant everything in the air shares.
function Game:spawnBullet(x, y, dx, dy, damage, speed)
    self.bullets[#self.bullets + 1] = Bullet.new(x, y, dx, dy, damage, speed)
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
-- a second rather than every frame -- the shot (src/shot.lua) holds its beat and
-- looks again shortly when there is nothing out there, which is what makes
-- walking into a fresh crowd answered at once.
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

-- The `n` nearest enemies within `range`, nearest first, in a list that may be
-- shorter than `n` and may be empty. A storm cloud with strikes left works its
-- way along the crowd it is already over rather than crossing the page to
-- somebody it picked out of a hat, so it asks for the two nearest and takes
-- whichever of them it is not already holding (src/storm.lua).
--
-- Insertion into a list of at most `n` rather than a sort of the whole horde:
-- `n` is two, and this is asked about once a strike on the same terms
-- `nearestEnemy` is.
function Game:nearestEnemies(x, y, range, n)
    local out, dist, count = {}, {}, 0

    for _, e in ipairs(self.enemies) do
        local d = util.len(e.x - x, e.y - y)
        -- Past the first `n`, only something nearer than the furthest one held
        -- is worth placing -- and placing it is what drops that furthest one.
        if d <= range and (count < n or d < dist[count]) then
            if count < n then count = count + 1 end
            local i = count
            while i > 1 and dist[i - 1] > d do
                out[i], dist[i] = out[i - 1], dist[i - 1]
                i = i - 1
            end
            out[i], dist[i] = e, d
        end
    end

    return out
end

-- One enemy at random from those standing inside a rectangle, or nil. The
-- rectangle is always the viewport, and the storm (src/storm.lua) is the only
-- thing that asks: it is the one weapon in the game that picks a target and
-- picks *nobody in particular*, since what a cloud is looking for is somewhere
-- worth being rather than the thing that matters most. Off the page is out of
-- the question for the sun's reason -- nothing may be killed where it cannot be
-- seen -- and it is the caller that holds the viewport, so the caller passes it.
--
-- Reservoir sampling rather than a list and a pick: one pass over the horde, no
-- table built and thrown away, and every candidate equally likely. It is asked
-- once every few seconds, on the terms `nearestEnemy` is asked on.
--
-- `skip` is an optional table keyed by enemy, for a caller that has somebody in
-- mind it does not want offered again -- the storm passes the marks its other
-- cloud is already on, so two of them never park over the same blob.
function Game:randomEnemyIn(left, top, w, h, skip)
    local pick, seen = nil, 0

    for _, e in ipairs(self.enemies) do
        if not (skip and skip[e])
            and e.x >= left and e.x <= left + w
            and e.y >= top and e.y <= top + h then
            seen = seen + 1
            if love.math.random(seen) == 1 then pick = e end
        end
    end

    return pick
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
        -- them out of the smear -- and so is the boss, which is the same clause
        -- for the same reason: a 40px body being shoved by every blob that walks
        -- into it would be carried across the page by its own escort.
        if e.frozen <= 0 and not e.def.boss then
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

        -- And the box gets the word after that (src/arena.lua). It is a clamp
        -- rather than something to path around, so it goes last and always wins
        -- -- which is also what makes it a surface worth shoving things against:
        -- a ruler swing into the edge of the box has nowhere to send the crowd.
        if self.arena then
            e.x, e.y = self.arena:clamp(e.x, e.y, e.radius)
        end

        -- Contact damage, rate-limited per enemy. Off the enemy rather than off
        -- its row in the table: what it hits for was fixed when it spawned
        -- (Enemy.new), so a cycle rolling over doesn't sharpen the horde already
        -- standing on the page.
        local dist = util.len(player.x - e.x, player.y - e.y)
        if dist < e.radius + player.radius and e.hitCooldown <= 0 then
            if player:hurt(e.damage) then
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
                    self:fireEnemyShot(e, shot)
                end
            end
        end

        -- The boss wets the page behind it (src/puddle.lua). The clock only pays
        -- out once it has walked clear of the last blot, so a boss held still --
        -- glued, or just stood over you -- leaves one puddle rather than a
        -- growing pool it is standing in the middle of.
        local trail = e.def.trail
        if trail and e.frozen <= 0 then
            e.trailT = e.trailT - dt
            if e.trailT <= 0 and (e.trailX == nil
                or util.len(e.x - e.trailX, e.y - e.trailY) >= trail.gap) then
                e.trailT = trail.every
                e.trailX, e.trailY = e.x, e.y
                self.puddles[#self.puddles + 1] = Puddle.new(e.x, e.y, trail,
                    e.trailDamage, love.math.random(2 ^ 20), e.reach)
            end
        end

        -- And it cries, which is the half of the same idea it does not have to
        -- walk to. Frozen stops it exactly as it stops the trail: a glued eye
        -- is a held eye, and the whole bargain of the hold is that it buys a
        -- moment of the boss not doing anything.
        if e.def.tears and e.frozen <= 0 then
            self:updateTears(dt, e)
        end

        -- The boss is the one thing on the page that cannot be walked away
        -- from: everything else the page can afford to forget once it is four
        -- hundred pixels behind you, and the fight cannot.
        if dist > DESPAWN_DIST and not e.def.boss then
            e.gone = true
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
-- the shove passed on is a share of the speed left at impact, so anything
-- scaling the rub's own knock reaches this level through the launch without
-- being asked. The victim
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

-- How long a running total is allowed to keep growing before the page says it.
--
-- Nothing in the game hits faster than a few times a second on purpose -- a
-- stroke has `rehit`, the sun, the beam and a burn all work on a tick -- so this
-- is not really a throttle. What it is for is the *other* axis: a built run has
-- four passive weapons, a mark on the ground and a tool all landing on the same
-- enemy within a few frames of each other, and six numbers stacked on one blob
-- says less than the one number they add up to. Short enough that the figure
-- still feels like it came off the hit that caused it, long enough that a volley
-- reads as a volley.
local HIT_HOLD = 0.08

-- One reading, spent. The number is hung off the top of the enemy rather than
-- its middle: the middle is where the sprite is, and a number is no use written
-- across the thing it is about.
function Game:showHit(e)
    self.damage:add(e.x, e.y - e.radius - 3, e.took)
    e.took, e.tookAt = 0, 0
end

-- Called once the frame's damage has all landed, so every source that found this
-- enemy has already been added in. Enemies that despawned holding a total lose
-- it, which is correct -- they were off the page and so was the number.
function Game:spendHits()
    for _, e in ipairs(self.enemies) do
        if e.took > 0 then
            if e.tookAt == 0 then e.tookAt = self.time end
            if self.time - e.tookAt >= HIT_HOLD then self:showHit(e) end
        end
    end
end

function Game:killEnemy(index)
    local e = self.enemies[index]
    -- The killing blow is the one number that cannot wait for the window to
    -- close: a moment later there is nothing left to hang it off.
    if e.took > 0 then self:showHit(e) end
    self.kills = self.kills + 1
    -- And against what it was. One line rather than a hook, for the reason the
    -- split and the burst are read here: this is the one door every kill in the
    -- game comes through, so the bestiary's homework needs nothing added to any of
    -- the dozen things that could have done it.
    self.killsBy[e.kind] = (self.killsBy[e.kind] or 0) + 1
    -- Counted against whatever gesture is open (nil most of the time), off
    -- the same spot a damage number would hang its own reading -- see
    -- src/multikill.lua for what "open" means and why an automatic weapon's
    -- kill can count too.
    self.multikill:noteKill(e.x, e.y - e.radius - 3, self.subject.key)
    self.particles:burst(e.x, e.y, 7, Palette.slate)
    self.gems[#self.gems + 1] = Gem.new(e.x, e.y, e.xp)
    -- Said on the enemy as well as taken out of the list, for the one thing that
    -- holds onto one across frames: a storm's cloud is a second or two arriving
    -- over the enemy it marked (src/storm.lua), and dropping out of the horde is
    -- not something a walk of the list can tell it about afterwards.
    e.gone = true
    table.remove(self.enemies, index)

    -- What it leaves behind, both of which are read here and nowhere else --
    -- this is the one door every kill in the game comes through, so a monster
    -- whose whole design is what happens when it dies needs no second hook and
    -- no clause in any of the dozen things that could have killed it.
    --
    -- After the removal rather than before it, so the arrivals append to a list
    -- the corpse has already left. Both are safe inside a walk of the horde
    -- because every such walk goes backwards (Game:updateEnemies, eachWithin):
    -- an index above the one being stepped is an index already passed.
    if e.def.split then self:splitEnemy(e, e.def.split) end
    if e.def.burst then self:burstEnemy(e, e.def.burst) end

    -- The eye going down is the end of the run, and it is noticed here rather
    -- than watched for anywhere else: every weapon in the game kills through
    -- this one door, so there is exactly one place that has to know.
    --
    -- Banked rather than acted on, exactly as a level is (Player:addXp): this
    -- can be reached from inside a stroke's own damage pass, and a screen that
    -- froze the run half way through one would close the stroke out from under
    -- the code still walking it. Game:update spends it once the frame is
    -- finished.
    if e == self.boss then
        self.boss = nil
        self.pendingWin = true
        -- Counted here for the same reason the win is noticed here: this is the
        -- one door every kill in the game comes through, so it is the one place
        -- that has to know an eye is worth something (`Game:runWorth`).
        self.eyes = self.eyes + 1
        self.particles:burst(e.x, e.y, 40, Palette.blue)
    end
end

-- A blot comes apart (`split` in src/enemy.lua). Thrown out on an even ring with
-- a little slop in the angle, so three drops read as a burst rather than as a
-- formation, and far enough out that they are not born inside each other -- the
-- separation pass would spend the next second untangling them, which looks like
-- a mistake rather than like a thing bursting.
--
-- They carry the parent's own scale rather than the run's. What came off a
-- monster is exactly as hard as the monster was, which is the same rule that
-- makes the horde standing on the page when a cycle rolls over stay the horde
-- that cycle spawned (Enemy.new).
function Game:splitEnemy(e, split)
    -- What comes off, and the one arrival in the game whose children are not
    -- simply what it was made of. A blow-up hands on its own scale like anything
    -- else -- what came off a monster is as hard as the monster was -- and at
    -- three times the size that rule produces debris rather than a fight: a drop
    -- is 2 health and 6 pixels across, and three times that is a body wider than
    -- a grin that dies to anything at all.
    --
    -- So a row may name what a blow-up of it leaves instead (`split.blown` in
    -- Enemy.types), and the children arrive at the *run's* own scale rather than
    -- the parent's -- ordinary monsters of the minute they land in. Which is the
    -- one place the "as hard as the monster was" rule is broken on purpose, and
    -- the trade is worth naming: it is broken by at most the health the horde
    -- gained while the parent stood on the page, and what it buys is not needing
    -- to carry a second, unmultiplied scale on all two hundred bodies to serve
    -- one row.
    --
    -- Enemy:isBlown is false on every child, since none of them carries a `grow`
    -- -- so the generation below takes the plain `into` and the cascade stops of
    -- its own accord. One giant blot is three blots is nine drops, and never a
    -- fourth level.
    local blown = split.blown and e:isBlown()
    local into = blown and split.blown or split.into
    local scale = not blown and e.scale or nil

    -- Thrown clear of the body that left them rather than a flat six pixels: a
    -- giant's children all landing inside its own footprint would be a pile the
    -- separation pass has to sort out over the next second, which reads as one
    -- thing shivering instead of three things arriving.
    local spread = split.spread * e.grow

    for i = 1, split.count do
        local a = (i - 1) / split.count * math.pi * 2
            + love.math.random() * 0.7
        self:spawnEnemy(into,
            e.x + math.cos(a) * spread,
            e.y + math.sin(a) * spread,
            scale)
    end
end

-- A bulb goes off (`burst` in src/enemy.lua), which is one hit and one wet
-- patch, delivered in that order for the boss's tear's reason: it hurts on the
-- way and it wets where it stopped, and the two are different numbers.
--
-- It hits the player and nobody else, deliberately. A burst that thinned the
-- crowd would turn the enemy whose whole point is that killing it costs
-- something into a thing you go looking for, and the build that clears the
-- crowd at arm's length -- which is most of them -- would be *rewarded* by the
-- one row written to punish exactly that.
--
-- Nothing here reads a fuse or a clock. The burst is the death, so a bulb caught
-- in another bulb's blast chains on the same frame, and what stops a wall of
-- them being fatal is the player's own invulnerability window (Player:hurt):
-- four going off together is one hit, the way standing in four puddles is.
function Game:burstEnemy(e, burst)
    self.particles:burst(e.x, e.y, 16, Palette.red)

    local px, py = e.x, e.y
    -- Back inside the box before it lands, exactly as a tear is: a bulb killed
    -- against the line would otherwise wet page nobody can stand on, and
    -- cornering the crowd would quietly disarm them. Cleared by the wet's own
    -- scaled width and not the row's, or a giant bulb's blot would hang over the
    -- line by the amount it grew.
    local wet = burst.puddle.radius * e.reach
    if self.arena then px, py = self.arena:clamp(px, py, wet) end
    self.puddles[#self.puddles + 1] = Puddle.new(px, py, burst.puddle,
        e.wetDamage, love.math.random(2 ^ 20), e.reach)

    -- `e.burstRadius` rather than `burst.radius`: how wide the blast is belongs to
    -- the bulb that walked on, not to the row -- the same rule the damage a line
    -- above keeps (Enemy.new).
    local player = self.player
    local dx, dy = player.x - e.x, player.y - e.y
    if dx * dx + dy * dy < e.burstRadius * e.burstRadius then
        if player:hurt(e.burstDamage) then
            self.particles:burst(player.x, player.y, 8, Palette.red)
        end
    end
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

-- The widest body a severed region will ever put down, which is the grin's 7 -- the
-- boss is 20 across and is refused at the door (Game:liftEnemyTo). Read only when a
-- *line* is the region: a hole has an inside and a corner is either in it or not,
-- where a line has to be cleared by a whole body or the arrival is standing on it.
local TRIP_SLACK = 7

-- Is (x, y) somewhere a severed region would take a body standing on it?
--
-- Four shapes answer, and the first three are the ones that write into the *page*
-- layer -- asked in the order the page pass draws them and by the same tests it
-- draws them with (Game:draw): the half a cut took off (`Scissors:offcut`), the
-- disc a punch pulled out of it, and every ring a cutout closed. The fourth is a
-- line rather than a hole: the ink of a mark that lifts what touches it (`lift` in
-- src/tools.lua, the DEADLINE, `Stroke:sweepLine`), which leaves the page under it
-- perfectly intact.
--
-- **What is being kept true is not "is this grey" but "can the player see it".**
-- Three of the four are missing paper and the fourth is a blue line, and either
-- way it is on the screen: a region this door does not know about is one the game
-- would quietly put the crowd down inside, and one nobody can see is one the
-- player would be blamed for.
--
-- Which is also why this is one question on the run and not a method on each of
-- the four. A page can be in ribbons -- three pins are three cuts (the PUNCH), a
-- spiral leaves four holes on top of each other -- and none of those objects knows
-- the others exist, deliberately, because that is what makes them safe to overlap
-- in the page layer. Somebody has to add them up, and it is the thing that owns
-- all the lists.
function Game:severed(x, y)
    for _, c in ipairs(self.cuts) do
        -- `severed` is the block, and `offcut` already answers false for a cut
        -- straddling your feet -- while neither half is the one you are not
        -- standing on, neither half is gone (Scissors:takeSides).
        if c.severed and c:offcut(x, y) then return true end
    end

    for _, c in ipairs(self.compasses) do
        if c.severed and util.len(x - c.x, y - c.y) <= c.radius then return true end
    end

    for _, m in ipairs(self.strokes) do
        -- A ring is kept by two rows and only one of them takes the page away:
        -- the BLEED's rings are ink flooded into the middle of a shape, which is
        -- a mark like any other and is nothing to stand clear of.
        if m.rings and m.tool.loop.lift then
            for _, ring in ipairs(m.rings) do
                if Stroke.insidePath(x, y, ring, 1) then return true end
            end
        end

        -- And the ink itself, on the one row where the line is the region. The
        -- widest body the door will move is added to the ink's own width, because
        -- what the sweep answers is a body *touching* the line (`Stroke:sweepLine`)
        -- and a corner clear by less than that is a corner the next tick empties
        -- again -- which is the one way this could ping-pong, and the whole reason a
        -- line belongs in this function at all.
        if m.tool.lift and m:covers(x, y, m.tool.radius + TRIP_SLACK) then
            return true
        end
    end

    return false
end

-- How far in off the two edges a lifted body is put down, and how far into the
-- page from there the arrivals are spread. The pad keeps a corner drop on the page
-- rather than half off the edge of it; the spread is what stops a swept crowd
-- being one stack of bodies on a single pixel -- the separation pass would tease
-- that apart over the next second anyway, but a second of one blob is a second of
-- the page lying about how many things are standing in the corner.
local CORNER_PAD = 10
local CORNER_SPREAD = 14


-- Where on the visible page a severed region can put the crowd it is holding: the
-- corner of the screen furthest from the player that no missing paper covers.
--
-- Furthest from the player, so a cut is always breathing room and never a crowd
-- folded into your lap -- and asked once per sweep rather than once per body, which
-- is what makes the whole crowd arrive out of the *same* corner. That is the tool's
-- real cost and it wants to be legible: what a cut sells is the length of the page,
-- and what it charges is a horde that comes back in one clump from one direction
-- instead of the ring it was spread round before.
--
-- A corner rather than anywhere clear at all, because a corner is the one place on
-- a page you can point at without measuring, and the whole read of this has to
-- happen in the second the paper opens: half the page goes grey and everything
-- that was on it is over *there*.
--
-- Nil is nowhere to put anybody -- the whole screen is missing paper, which is what
-- has happened when you have walked out onto the offcut yourself. Every caller then
-- lifts nothing at all that tick. Refused rather than answered with a fallback,
-- because every fallback here is a crowd being shuffled about inside a hole twice
-- a second, and the honest reading of standing in a hole with the horde is that
-- there is nowhere left to send it.
--
-- The box gets its word in before the region does (src/arena.lua): during a boss
-- fight the corners of the screen are often outside it, so what has to be tested
-- for missing paper is where a body would really land and not where it was aimed.
function Game:clearCorner()
    local left, top, w, h = Camera.bounds()
    local px, py = self.player.x, self.player.y
    local best, far

    for sx = 0, 1 do
        for sy = 0, 1 do
            local x = sx == 0 and left + CORNER_PAD or left + w - CORNER_PAD
            local y = sy == 0 and top + CORNER_PAD or top + h - CORNER_PAD
            if self.arena then x, y = self.arena:clamp(x, y, CORNER_PAD) end

            if not self:severed(x, y) then
                local d = util.len(x - px, y - py)
                if not far or d > far then
                    far = d
                    -- `inx, iny` is which way is *into* the page from there, for
                    -- the spread: nothing is nudged towards the two edges it has
                    -- just been put in front of.
                    best = { x = x, y = y,
                             inx = sx == 0 and 1 or -1,
                             iny = sy == 0 and 1 or -1 }
                end
            end
        end
    end

    return best
end

-- The other thing that can happen to a body standing on a piece of paper that is
-- no longer there, and the only event in the game that is neither a death nor
-- damage: it is picked up with the paper and put down again in the corner of the
-- page that is still there (`Game:clearCorner`, and the caller asked for that
-- corner once for the whole sweep).
--
-- **It is a reposition and not a despawn, and that is the whole balance of the
-- scissors' last level.** Nothing is credited and nothing is taken: no gem, no xp,
-- no kill on the tally, nothing split and nothing burst -- not as a price, but
-- because nothing died here and nothing was even hurt. The body arrives with the
-- health it walked in with, still walking at you, and the only thing that has
-- changed about it is where it is standing.
--
-- It used to be a despawn, and the trouble with that was never the ledger. A cut
-- that emptied half a page paid for itself in the xp of everything it emptied,
-- which is a real price and reads perfectly well written down -- and in the hand it
-- was a get out of jail free card anyway, because whatever the tally said, the page
-- was clear and the fight was over. So the cut buys the same second of empty paper
-- and never the way out of the fight: the same bodies, the same health, walking
-- back at you from the far corner. It is crowd control with the longest reach in
-- the game, and it is no longer an eraser.
--
-- One thing falls out of that which is worth knowing before anybody tunes a
-- number here: **the spawner is no longer answered by a cut.** A despawned offcut
-- put the horde under the floor, so the run was refilled from the offscreen ring
-- while the page was still open (`FLOOR_RATE`, `REFILL` in src/spawner.lua) --
-- which quietly meant a cut *replaced* the crowd it took. Nothing leaves the horde
-- now, so the floor has nothing to top up and what walks back at you is the same
-- crowd rather than a fresh one. Fewer moving parts, and the tool means one thing.
--
-- And the region goes on answering for arrivals for as long as it is on the page --
-- every caller stays a clock -- which makes the missing paper a *wall*: walk the
-- crowd into it and the crowd comes out in the corner. That is a better reading of
-- a piece of page that is not there than a hole things fell out of the run
-- through, and it is the one the drawing was always making.
--
-- The boss is never lifted, for the reason it is never despawned at range
-- (Game:updateEnemies): it is the one thing on the page that cannot be walked away
-- from, and half a page of distance handed back every half second is a fight you
-- would never have to have. Refused here rather than at any of the four callers,
-- so this is the one door and there is one place that has to know.
--
-- Nothing here asks about pen lines, and it does not have to: a body put down
-- inside one is pushed out of it by `Enemy:resolveWalls` on the next frame, which
-- is the same last word ink already gets over a shove and over a wad's dash.
--
-- Returns whether the body actually moved, which the boss makes worth asking:
-- one caller has something to do to what it has just put down (`sever.paste`, the
-- COLLAGE in src/tools.lua) and doing it to the one thing this door refused would
-- be gluing the eye to the page it is standing on.
function Game:liftEnemyTo(e, corner)
    if e.def.boss then return end

    -- Spread off the corner, seeded off where it was standing rather than rolled
    -- (`util.hash01`, the game's rule everywhere it wants variation): two bodies
    -- lifted out of the same tick land in different places and nothing has to keep
    -- a seed.
    local x = corner.x + corner.inx * util.hash01(e.x, e.y, 31) * CORNER_SPREAD
    local y = corner.y + corner.iny * util.hash01(e.x, e.y, 37) * CORNER_SPREAD
    if self.arena then x, y = self.arena:clamp(x, y, e.radius) end
    -- Into the page is towards the middle of it, which is where the cut usually
    -- is, so the spread is the one part of this that can land back on missing
    -- paper. Asked rather than assumed, and the bare corner is the answer when it
    -- does: that point was clear, and a stack of bodies is a smaller lie than a
    -- body being swept twice out of the same hole.
    if self:severed(x, y) then x, y = corner.x, corner.y end

    -- Paper dust at both ends: graphite rather than the slate a kill throws, and
    -- never red -- red is a thing taking a hit and nothing here was hit. Bigger
    -- where the paper went than where the body lands, because the tear is the
    -- event and the arrival is only the end of it.
    self.particles:burst(e.x, e.y, 5, Palette.graphite)
    self.particles:burst(x, y, 3, Palette.graphite)

    e.x, e.y = x, y

    -- Everything it was carrying that was a fact about where it was standing: the
    -- shove its neighbours were giving it, the way round a pen line it had picked,
    -- the spiral it was walking into, the wax under its feet and the footing it had
    -- lost on it. A wind-up it was half way through goes for the glue's own reason
    -- (Enemy:update): a heading locked before it was moved is a line drawn from
    -- somewhere it no longer is, so it winds up again where it has landed. None of
    -- this is state about the *body*, which is why the health, the burn, the glue
    -- and the storm's mark all ride along untouched.
    e.pushX, e.pushY = 0, 0
    e.slideX, e.slideY, e.slideT = 0, 0, 0
    e.lureX, e.lureY, e.lureT = 0, 0, 0
    e.slipT, e.slipTurn = 0, 0
    e.chill, e.chillT = 1, 0
    e.chargePhase, e.phaseT = nil, 0

    return true
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

-- One beat of a shooter's fire. A `spread` on the block fans that many pellets
-- across `arc` radians centred on the player instead of sending one down the
-- line, which is the whole difference between the eye and the eye boss: a
-- pellet is dodged by stepping aside and a fan has to be walked out of.
--
-- An even spread has no pellet down the middle, which is the right shape for
-- this: standing still and holding the line is what the fan punishes.
function Game:fireEnemyShot(e, shot)
    local player = self.player
    local aim = math.atan2(player.y - e.y, player.x - e.x)
    local n = shot.spread or 1
    local step = n > 1 and shot.arc / (n - 1) or 0
    local from = aim - (n - 1) * step / 2

    -- The pellet is as big as whatever fired it (`reach` in Enemy.new), and the
    -- hitbox and the drawing take the same number so the art cannot lie about the
    -- radius -- which is the one thing this game will not do (Enemy:outlineColour
    -- makes the same argument about a rim). What does *not* grow is the speed or
    -- the range: a giant eye fires a bigger pellet from the same distance on the
    -- same beat, so there is one new fact to read rather than three.
    for i = 0, n - 1 do
        local a = from + i * step
        self.shots[#self.shots + 1] = {
            x = e.x, y = e.y, dx = math.cos(a), dy = math.sin(a),
            speed = shot.speed, damage = e.shotDamage, life = 3,
            sprite = shot.sprite, radius = (shot.hit or 3) * e.reach,
            grow = e.grow,
        }
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

        if util.len(player.x - s.x, player.y - s.y) < player.radius + s.radius then
            s.life = 0
            if player:hurt(s.damage) then
                self.particles:burst(player.x, player.y, 6, Palette.red)
            end
        end

        -- A tear is the one piece of enemy fire that leaves something behind:
        -- where it stops, the page is wet (src/puddle.lua). Which includes
        -- stopping on *you* -- the hit above sets the life to zero like any
        -- other, so a tear you failed to dodge puddles at your feet and the
        -- mistake costs twice.
        if s.life <= 0 then
            if s.wet then
                -- Put the wet back inside the box before it lands. A tear thrown
                -- from a cornered eye would otherwise puddle on the far side of
                -- the line, where it is page nobody can stand on anyway -- and
                -- half a ring would quietly do nothing every time the fight ended
                -- up against a wall. Clamped rather than dropped, so backing the
                -- eye into a corner wets that corner instead of disarming it.
                local px, py = s.x, s.y
                local wet = s.wet.radius * (s.wetReach or 1)
                if self.arena then px, py = self.arena:clamp(px, py, wet) end
                self.puddles[#self.puddles + 1] = Puddle.new(px, py, s.wet,
                    s.wetDamage, love.math.random(2 ^ 20), s.wetReach)
            end
            table.remove(self.shots, i)
        end
    end
end

-- One tear, thrown to land `dist` away along `angle`. It is an ordinary piece
-- of enemy fire the whole way -- same table, same collision with the player,
-- same drawing -- carrying two extra fields that say what to leave where it
-- stops. Life is worked out from the distance rather than written down, which is
-- what makes "land there" the thing a caller asks for.
function Game:throwTear(e, tears, angle, dist)
    self.shots[#self.shots + 1] = {
        x = e.x, y = e.y,
        dx = math.cos(angle), dy = math.sin(angle),
        speed = tears.speed, damage = e.tearDamage,
        life = dist / tears.speed,
        -- As big as whatever threw it, hitbox and drawing off the one number, for
        -- the pellet's reason (Game:fireEnemyShot). Dead weight on the only row
        -- that has tears today, since the boss is guarded out of both standout
        -- rolls -- but it is a line rather than a branch, and the day anything
        -- else in Enemy.types cries it is already true.
        sprite = tears.sprite, radius = (tears.hit or 3) * e.reach,
        grow = e.grow,
        -- What it becomes. `wetDamage` rides the boss's own scaled number for
        -- the reason the trail's does: a puddle keeps what it was made with, and
        -- `wetReach` is how wide it was made.
        wet = tears.puddle, wetDamage = e.tearWet, wetReach = e.reach,
    }
end

-- The eye's three ways of crying, all of them the same tear.
--
-- The scatter and the lane are clocks; the rings are thresholds. Keeping them
-- apart matters: two of these are weather you learn the rhythm of and the third
-- is the fight answering you for winning, and a ring on a timer would be neither.
function Game:updateTears(dt, e)
    local tears = e.def.tears

    -- The weather. Anywhere in the box, near or far, aimed at nobody -- which is
    -- what stops the middle of the arena being a safe place to stand just
    -- because the eye is over by the wall.
    local scatter = tears.scatter
    e.scatterT = e.scatterT - dt
    if e.scatterT <= 0 then
        e.scatterT = scatter.every
        for _ = 1, scatter.count do
            self:throwTear(e, tears, love.math.random() * math.pi * 2,
                scatter.near + love.math.random() * (scatter.far - scatter.near))
        end
    end

    -- The lane, laid down the line to the player and landing at rising
    -- distances, so it draws a wall across the way you were going rather than
    -- shooting at where you are. Aimed at the ground, which is why nothing about
    -- it is dodged by stepping aside -- you have to not be down that line.
    local lane = tears.lane
    e.laneT = e.laneT - dt
    if e.laneT <= 0 then
        e.laneT = lane.every
        local aim = math.atan2(self.player.y - e.y, self.player.x - e.x)
        for i = 0, lane.count - 1 do
            self:throwTear(e, tears, aim, lane.from + i * lane.step)
        end
    end

    -- The two turns. Every threshold this hit has taken it past fires, so a shot
    -- big enough to cross both throws both rings rather than swallowing one --
    -- the same rule the draft follows when a pickup carries two levels.
    local ring = tears.ring
    while e.rings < #ring.at and e.hp / e.maxHp <= ring.at[e.rings + 1] do
        e.rings = e.rings + 1
        local turn = love.math.random() * math.pi * 2
        for i = 0, ring.count - 1 do
            self:throwTear(e, tears, turn + i * math.pi * 2 / ring.count, ring.radius)
        end
        self.particles:burst(e.x, e.y, 12, Palette.blue)
    end
end

-- The boss's wet trail. Standing in one hurts on the player's own
-- invulnerability window rather than on a clock of its own (Player:hurt), which
-- is exactly how contact damage is rate-limited -- so wading through a blot is
-- one hit and living in one is a hit every six tenths of a second, whether it is
-- one puddle or four overlapping.
function Game:updatePuddles(dt)
    local player = self.player
    local wet = false

    for i = #self.puddles, 1, -1 do
        local p = self.puddles[i]
        if not p:update(dt) then
            table.remove(self.puddles, i)
        elseif not wet and p:covers(player.x, player.y) then
            wet = true
            if player:hurt(p.damage) then
                self.particles:burst(player.x, player.y, 5, Palette.blue)
            end
        end
    end
end

-- The magnet is a radius round where you are standing; the skate's last level is
-- a *shape* -- the line you walked -- and a gem lying on it comes to you however
-- far off it is (src/skate.lua). Handed over as a reach rather than as a special
-- kind of pull so that a hauled gem sets off and snaps in exactly like every
-- other one: what the level buys is being noticed, not a second way of arriving.
function Game:updateGems(dt)
    local magnet = self.loadout.stats.magnet
    local trail = self.loadout:trail()
    -- And the flock's carriers, which is the same level again as a *fetch*
    -- rather than as a shape: a bird goes out to something lying too far off to
    -- have been noticed and taps it, and what comes back is a reach, so a
    -- fetched gem travels home exactly like every other one (src/flock.lua).
    local flock = self.loadout:flock()

    for i = #self.gems, 1, -1 do
        local g = self.gems[i]
        local reach = magnet
        if trail and trail:pullsAt(g.x, g.y) then reach = math.huge end
        if flock and flock:hauls(g) then reach = math.huge end
        g:update(dt, self.player, reach)
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

-- The marks the pen's last level is holding on the page, and the only thing that
-- ever lets one go: the next wall being laid. Handed the strokes to hold, or
-- nothing at all.
--
-- Held rather than deleted, which is the level's whole feel: what is released
-- gets its ordinary nine seconds back, so replacing a fence in a panic never
-- leaves you standing in the open for a frame -- and what expires still pops, if
-- the level below it was taken.
--
-- **The release happens whether or not anything is held in its turn**, and that
-- order is load-bearing: a run can lose the level with a held wall down -- the dev
-- switch handing the tools back, or EXPEL -- and a fence nothing left could
-- release would be on the paper for the rest of the run.
--
-- A *list*, and released by clearing `kept` off every mark on the page rather
-- than off a registry of the ones this held. Two reasons, and the first is that
-- one gesture is not always one line: a compass leg carrying a pen rules the ring
-- as one mark per leg (the CORRAL in src/tools.lua, Compass:swing), and holding
-- half a ring would be holding a fence with a hole in it. The second is that
-- nothing else in the game ever sets `kept`, so the page itself is the honest
-- record of what is being held -- there is no reference to keep in step with the
-- stroke list, and nothing to go stale when a run ends on a page that was holding
-- one.
function Game:holdWalls(strokes)
    for _, s in ipairs(self.strokes) do
        s.kept = false
    end

    for _, s in ipairs(strokes or {}) do
        s.kept = true
    end
end

function Game:endStroke()
    if self.stroke then
        -- The rubber is the one brush with something to say on the release --
        -- the rub stops and the crumbs are swept off. Fired here rather than
        -- where the pointer lifts, because a stroke ends by tool change and by
        -- holding the run too, and the rub is over on all of them.
        --
        -- **`crumbs` is the field that says the travelling tip is a rubber**, and it
        -- is asked here instead of the icon for `Game:dropOne`'s reason in the other
        -- direction: there a block names its own sound so a staple driven under the
        -- name PALING is still heard going in, and here one field says what an icon
        -- plus a list of exceptions was saying. It is exactly the right question --
        -- the STUB and the SCUFF leave `crumbs` off precisely because *their*
        -- travelling tip is a pencil or a chisel (see their rows) -- so every row
        -- whose mark is a rub is heard rubbing without being named: the RUBBER, the
        -- SNAG and the SHEAR today, and whatever is written next.
        if self.stroke.tool.crumbs then
            Sfx.stopLoop("rubbing")
            -- The pop is the crumbs being swept off, and a tap sheds none: the
            -- release only speaks once the rub has actually covered ground, so
            -- rapid taps with the rubber don't drum the pop into the player.
            if self.stroke.drawn >= RUB_HEARD then
                Sfx.play("eraser")
            end
        elseif self.stroke.tool.stamp then
            -- A stroke's sound is the line being drawn, so it stops when the
            -- drawing does: a brush swish or a glue squelch still going after
            -- the finger has lifted is a line nobody is laying.
            Sfx.cut(self.strokeVoice)
        end
        self.strokeVoice = nil
        self.stroke:finish()
        self.stroke = nil
    end
end

-- The sound of a line being laid down. One swish is fired at a time, chosen by
-- how fast the nib has actually been moving -- a flick gets the short sharp
-- one, a careful line the long soft one -- and the next is only fired once the
-- last has finished, so a held stroke sounds continuous without ever stacking.
-- The glue does not care about speed: a smear is a smear, and its two
-- recordings simply take turns at random. A nib holding still fires nothing,
-- which is right: no line, no sound.
function Game:strokeSwish(tool, used, dt)
    if dt > 0 then
        -- Smoothed over about an eighth of a second, so one janky frame does
        -- not decide which swish plays.
        self.drawSpeed = self.drawSpeed
            + (used / dt - self.drawSpeed) * math.min(1, dt * 8)
    end

    if used <= 0 then return end
    if self.strokeVoice and self.strokeVoice:isPlaying() then return end

    if tool.icon == "glue" then
        self.strokeVoice = Sfx.play(love.math.random() < 0.5 and "glue1" or "glue2")
    elseif tool.stamp and self.drawSpeed > 25 then
        self.strokeVoice = Sfx.play(Sfx.brushForSpeed(self.drawSpeed))
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

-- Is there already something driven into the page at this spot?
--
-- A pin and a staple are the only two things that stay on the paper for good --
-- barring the one level that takes a staple back out of it (`prise` in
-- src/staple.lua) -- which is what the page's memory of a run is made of, and it
-- is also the one way this game can end up with a shape on screen that nobody
-- drew: tap the same
-- spot twice, rake a seam back over itself, or let the SPINDLE nail two enemies
-- standing shoulder to shoulder, and what is left is not two pins, it is a
-- smudge. So one that lands on top of one already there does its work and is
-- then not kept (Game:updateDrops).
--
-- The distance is the *drawing's* business rather than the tool's, so each module
-- writes its own down (`FOOTPRINT` in src/pin.lua and src/staple.lua) -- a crown
-- is wide and flat and a pin is a dot on a stick, and neither number has anything
-- to do with what the thing does when it arrives.
--
-- Both lists, because being spent is exactly when one stops being anything but a
-- drawing. Asked once per drop rather than per frame, and the box refuses in four
-- comparisons -- the same bargain Game:eachSpent makes over the same list.
function Game:dropCrowded(drop, x, y)
    local reach = drop.lands.FOOTPRINT
    if not reach then return false end

    local function near(list)
        for i = #list, 1, -1 do
            local d = list[i]
            if x >= d.x - reach and x <= d.x + reach
                and y >= d.y - reach and y <= d.y + reach then
                return true
            end
        end
        return false
    end

    return near(self.drops) or near(self.spent)
end

-- A tap rather than a stroke, so the whole price is paid up front -- before the
-- thing has landed, and whether or not it lands on anything. What turns up is
-- the tool's business, not this function's: the drop block names the module,
-- which is the only difference between a pushpin and a staple as far as the
-- input is concerned.
--
-- The price is paid either way, and so is the damage: `crowded` is only about
-- whether the page keeps the drawing afterwards. A tap that cost you a tenth of
-- the meter and killed what it landed on has done its job; there is no refund for
-- the paper being crowded and there should not be, or the tool would pay you for
-- spamming one spot.
function Game:dropOne(tool, x, y)
    self:spendInk(tool.ink)

    local drop = tool.drop

    -- Named on the block where a row says so, and read off the icon otherwise --
    -- the icon being the tool's name for itself everywhere else. The block comes
    -- first for the fusions (src/tools.lua): eight of them drive a real pushpin
    -- into the paper under a name that is not PUSHPIN, and a tool that arrived
    -- silent because its icon had been renamed would be a bug with nothing on
    -- screen to show for it. It is the same field Game:driveDrop already reads for
    -- what a compass leg is carrying. A drop with neither simply arrives silent
    -- until it is given a sound.
    if drop.sound then
        Sfx.play(drop.sound)
    elseif tool.icon == "stapler" then
        Sfx.play("stapler")
    elseif tool.icon == "pushpin" then
        Sfx.play("pin")
    end

    -- Asked before this one joins the list, or it would find itself.
    local crowded = self:dropCrowded(drop, x, y)

    local d = drop.lands.new(drop, x, y)
    d.crowded = crowded
    -- What this one cost, stamped on it for the pin level that gives a slice
    -- back on a full crater -- read off the tool now, while it is still the
    -- tool in hand: the strip may have moved on by the time it lands.
    d.price = tool.ink
    -- And the tool itself, for a row that strings threads between the things it
    -- drives into the page (`thread` in src/tools.lua). Stamped for the same
    -- reason the price is and one better: a thread is laid a quarter of a second
    -- after the tap, out of the *brush* written on the row, and by then the strip
    -- may be holding something else entirely.
    --
    -- Only when the row has any use for it, so this is the field Game:updateDrops
    -- routes on and every other drop in the game is untouched by all of it. Two
    -- fields ask for it and they are the two readings of the same idea: `thread`
    -- lays the mark between two of these and `pool` lays it round one.
    if tool.thread or tool.pool then d.tool = tool end

    -- A pin's landing is real seconds away (`FALL`, src/pin.lua) and a staple's
    -- bite is not (`Staple:update` lands on its own first tick), so only the
    -- one that can actually still be falling after the gesture has been
    -- released needs to keep the word's window open -- see src/multikill.lua.
    if d.fall and d.fall > 0 then
        self.multikill:hold()
        d.heldMultikill = true
    end

    self.drops[#self.drops + 1] = d
end

-- The stapler's last level: while the pointer is held down, another staple lands
-- every `rake.every` pixels it has travelled.
--
-- Walked *along the segment* the pointer covered rather than dropped wherever it
-- ended up, for Stroke:extend's reason: a seam has to come out evenly spaced
-- whether the finger was thrown across the page or crept along it. The leftover
-- travel is carried in `rakeX, rakeY` -- the last spot actually stapled -- so the
-- spacing stays even across frames instead of restarting at each one, which is
-- `Stroke.carry` by another name.
--
-- Every staple in the seam is charged the tool's full price, so this level does
-- not make a staple cheaper: it makes ten of them one gesture instead of ten.
-- Too poor to pay and the seam simply stops where the meter ran out, picking up
-- again if it creeps back while the finger is still down -- the rubber's lean
-- rule, and the reason nothing here touches `drawBlocked`, which is a decision
-- about starting rather than about continuing.
function Game:rakeDrops(tool, x, y)
    local every = tool.drop.rake.every
    local dx, dy = x - self.rakeX, y - self.rakeY
    local dist = util.len(dx, dy)
    if dist < every then return end

    local nx, ny = dx / dist, dy / dist
    local t = every
    while t <= dist do
        if self.ink < tool.ink then break end
        self:dropOne(tool, self.rakeX + nx * t, self.rakeY + ny * t)
        t = t + every
    end

    -- Where the last one actually went, which on an ink-starved frame is where
    -- the seam stopped rather than how far the finger got.
    self.rakeX = self.rakeX + nx * (t - every)
    self.rakeY = self.rakeY + ny * (t - every)
end

-- A drop that nobody tapped: driven into the page by something already on it,
-- which today is either a compass leg carrying a pushpin for a lead (the SPINDLE
-- in src/tools.lua, `Compass:nail`) or one working a stapler as it travels (the
-- HEM, `Compass:seamPress`). No ink is spent *here*, because a sweep's price is
-- paid at the needle and by the drag -- and the drop arrives already through the
-- paper rather than falling onto it, so it punches no second crater out of ground
-- the rim has just swept (`driven` in src/pin.lua; a staple has no fall to skip,
-- so it ignores the flag). Everything after that is the same: it joins the same
-- list, holds for the same clock, and ends up on the same page.
--
-- The sound is named on the block rather than read off the tool's icon the way a
-- tapped one is (Game:dropOne), because what arrives here is a block and not a
-- tool -- and `hush` is the caller saying "not this one": a seam presses
-- thirty-four times in under a second and thirty-four of one sound in a second is
-- a machine gun. The press still lands; only the sound thins out, and the caller
-- that runs a seam owns the rate (`CLACK` in src/compass.lua).
function Game:driveDrop(drop, x, y, hush)
    if drop.sound and not hush then Sfx.play(drop.sound) end

    -- The page holds these one deep, and both drivers want it: a full turn nails a
    -- pin per body it passed and bodies stand shoulder to shoulder, and a seam run
    -- twice over the same ground is a seam and not a stripe.
    local crowded = self:dropCrowded(drop, x, y)

    local d = drop.lands.new(drop, x, y, true)
    d.crowded = crowded
    self.drops[#self.drops + 1] = d
    return d
end

-- Did the player *tap*, or did they draw?
--
-- **This cannot be asked of the line**, and it took a bug to make that obvious.
-- The pointer is in screen pixels and a mark is in world ones (`Camera.bounds`),
-- so a finger held perfectly still while the player walks is a finger the page is
-- sliding under -- and the stroke it lays is real line, real ink and real length.
-- Measuring `Stroke.drawn` therefore answers "did the page move" and not "did the
-- finger", which meant that on the one occasion the distinction matters -- a
-- panicked tap taken while running -- the tool read a drag and did the wrong
-- thing. It is the same class of mistake as reading a tool's numbers off
-- `Tools.list`: the right value in the wrong frame of reference.
--
-- So the two numbers this asks about are both the finger's own (Game:updateDrawing
-- accumulates them at the top, in screen space, for every press whether or not it
-- drew anything), and there are two of them because either alone is wrong. Travel
-- alone calls a slow deliberate short line a tap. Time alone calls a flick a tap,
-- which is the fastest real stroke anybody draws. A tap is *brief* and it is
-- *still*, and it has to be both.
--
-- Accumulated travel rather than the distance from press to release: a wiggle that
-- came back to where it started moved, and the question is whether the finger moved.
function Game:wasTap(spec)
    return (self.pressTravel or 0) < spec.slack
        and (self.pressT or 0) < spec.hold
end

-- One end of a stroke, fastened to the page -- the STITCH's `fasten`
-- (src/tools.lua), and the third thing in the game that drives a drop nobody
-- tapped for.
--
-- **The two ends go in at the two ends**, which is to say at the two moments: the
-- near one at the press, from the brush branch of `Game:updateDrawing`, and the far
-- one at the release. It used to lay both at the release and that was wrong for a
-- reason worth writing down -- a stapler lands the instant you tap, with no fall
-- and nothing to telegraph, and that is most of what the tool *is*. Holding the
-- first staple back until the finger lifted put a wind-up on the one tool in the
-- game written not to have one, so a tap stopped feeling like a tap. Now the press
-- fastens and the drag is the line growing out of a staple that is already in the
-- paper.
--
-- Which also settles what a tap does here without a branch: the press lays one, the
-- release asks `Game:wasTap` and lays the second only if the finger really went
-- somewhere. A tap is one staple because only one moment happened.
--
-- Priced and refused per staple, the way every price in the game is
-- (`Purse.spend` is the same argument one screen over): a meter that can afford
-- the press and not the release fastens the near end and leaves the line hanging,
-- which is the honest failure -- you can see what you got.
function Game:fastenEnds(mark, x, y)
    local fasten = mark.tool.fasten
    if self.ink < fasten.ink then return end

    self:spendInk(fasten.ink)
    -- Hushed after the first of a gesture, `Game:seamAlong`'s rule: two staples a
    -- second apart at either end of one line are one gesture, and one gesture is
    -- one sound. The mark carries the flag rather than the game, because what the
    -- pair belongs to is the stroke.
    self:driveDrop(fasten, x, y, mark.fastened)
    mark.fastened = true
end

-- The page opened along the line you just drew: `chord` in src/tools.lua, which is
-- a whole `cut` block on a brush row without being the row's block (the COLLAGE,
-- the SCORCH, the SHEAR).
--
-- **It is `fasten`'s arrangement with a cut in place of the two staples**, and the
-- rename is the whole reason either field exists. `cut` is in
-- `Game:updateDrawing`'s precedence list, so a brush row carrying one *would be a
-- pair of scissors* and would never lay a line -- the same sentence the SNAG's
-- staple is not a `drop` for. A block that might be the gesture cannot live on the
-- row; under another name it can.
--
-- **What answers the question the CUTOUT left open.** The pencil could cut what it
-- ringed because a pencil closes rings; the other four brushes do not, so the
-- carrier here is the mark's own *two ends*. You drag, the ink goes down, and the
-- page comes apart along the straight line between where you pressed and where you
-- stopped. Which is the GUILLOTINE's cast-along-the-line for a hand instead of a
-- straight edge, and the STITCH's "the two ends of a line are two points" with the
-- scissors in the place of the wire. `Game:castCut` was already the function for
-- it: a cut has always been two points and nothing about who chose them.
--
-- **`tapped` is the same field the SNAG reads, and it turns the gesture over.** A
-- rub is an event that is nowhere once it is over, so it has no two ends worth
-- cutting between -- the rubber's row therefore keeps the parent's *taps* and gives
-- the drag to the rub (the SHEAR). One field, two shapes, and between them every
-- answer a brush can give: the line is the cut, or the line is what you do instead
-- of cutting.
--
-- Priced on the block rather than off the row, because the row's `ink` is a price
-- per pixel and this is a press. Undiscounted by the blotter for the same reason
-- the STITCH's staples are -- `scaleCost` reaches the row's `ink` and not a number
-- one level in -- and refused rather than clamped, which is `Game:fastenEnds`'s
-- rule and the tap's: a cut you could not afford simply does not happen, and the
-- mark you drew still stands. The check is ahead of *both* taps on a tapped chord,
-- which is the parent's own behaviour -- there is no anchoring a cut you cannot pay
-- to close, and the anchor survives a press the meter refused.
function Game:chordCut(mark)
    local chord = mark.tool.chord
    if self.ink < chord.ink then return end

    -- Two taps, the parent's gesture exactly, through the parent's own two doors.
    if chord.tapped then
        if not self:wasTap(chord) then return end

        if self.cutFrom then
            self:closeCut(chord, chord.ink, mark.x, mark.y)
        else
            self:openCut(chord, chord.ink, mark.x, mark.y)
        end
        return
    end

    -- Or the line's own two ends: where the finger went down (the head of the
    -- path, which is where `Stroke.new` put it) and where it came up.
    --
    -- The length is asked here rather than left to `Game:castCut`, which refuses
    -- the same number silently: this is the one caller that has a price to spend,
    -- and spending it on a cut that was never made is the difference between a
    -- refusal and a robbery.
    --
    -- **Which also means a line drawn back to where it started opens nothing**, and
    -- that is the right way round rather than a hole. A ring has no chord; the one
    -- brush that can cut what it *encloses* is the pencil, because the pencil is the
    -- tool that closes rings (`loop`, the CUTOUT). These three draw lines, and a
    -- line's two ends are the whole of what they have to aim with -- so drawing a
    -- circle with one of them is drawing a circle, and the page stays whole.
    local ax, ay = mark.path[1], mark.path[2]
    if util.len(mark.x - ax, mark.y - ay) < Scissors.MIN then return end

    self:spendInk(chord.ink)
    self:castCut(chord, ax, ay, mark.x, mark.y)
    -- The blades are still travelling the line (Game:updateCuts), same as a
    -- tapped cut's (Game:closeCut) -- held open for the same reason.
    self.multikill:hold()
end

-- A rub crossing the staples the page is holding, and every one it touches comes
-- out of the paper (`snag` in src/tools.lua, `Staple:snag`, the SNAG).
--
-- **This is the fourth relationship between a mark and something driven into the
-- page, and it is the first that goes the other way.** A thread is strung between
-- two drops, a pool is laid round one, a seam is pressed along a line -- all three
-- are a mark arriving because a drop is there. This is a mark arriving and taking
-- the drop *away*, which is why it lives here for the threads' reason rather than
-- in src/stroke.lua or src/staple.lua: neither of those can see both, and the wire
-- coming out is a fact about the pair.
--
-- What may be snagged is the drop's own business and not the row's -- a module
-- answering `snag` can be taken out of the page and one that cannot has no
-- business being asked, which is the same duck the block's `lands` already is. A
-- pushpin therefore refuses in one comparison, and is right to: a pin is a spike
-- through paper and a rubber is not going to lift it.
--
-- Measured against the *wire* rather than against what the wire holds
-- (`Staple.REACH`), so what comes out is what the rub actually went over. And
-- against the live list only: a spent staple is a drawing the page decided to
-- keep, it holds nothing, and nothing goes on updating it -- there is no tear for
-- it to animate and nothing for the tear to bite.
--
-- One clack per call however many come out at once, which is `Game:seamAlong`'s
-- rule again: a rub that crosses three staples in one frame is one movement of a
-- hand, and three of one sound on one frame is a machine gun. Consecutive frames
-- speak again, so a rub dragged down a row of them still comes out as a rip.
function Game:snagDrops(mark, ax, ay, bx, by)
    local reach = mark:reach()
    local heard = false

    for i = #self.drops, 1, -1 do
        local d = self.drops[i]
        local wire = d.snag and d.def.lands.REACH

        if wire and util.distToSegment(d.x, d.y, ax, ay, bx, by) < reach + wire
            and d:snag(self) then
            if not heard and d.def.sound then Sfx.play(d.def.sound) end
            heard = true
        end
    end
end

-- A whole mark, laid between two points in one frame by something that is not a
-- hand.
--
-- Two things want it and they want exactly the same six lines: a thread strung
-- between two pins (Game:strand) and a line ruled against a straight edge
-- (Game:trailRuler). Neither has a finger to follow, neither is smoothed, and
-- both are paid for before the first pixel goes down -- so both want a stroke
-- opened, extended the whole way on one call and finished on the frame it was
-- begun. What they disagree about is what happens to it *afterwards*, which is
-- why that is the caller's and not this function's: a thread is held while its
-- posts stand, and a ruled line simply starts ageing.
--
-- The budget is unbounded, which is Compass:layBands' rule: the meter was emptied
-- at the press, and a line that ran out of ink half way across the page would be
-- a tool charging twice for one gesture.
function Game:layLine(tool, ax, ay, bx, by)
    local s = Stroke.new(tool, ax, ay)
    -- A straight line between two fixed points never comes back to itself, so it
    -- can never be the thing that notices a ring closing. Compass:swing clears the
    -- same flag on the marks a leg drags for the same reason -- being surrounded
    -- happens once, and where a ring can still be closed it is resolved by
    -- whatever can see both ends (Game:cutCircuit).
    s.lassos = false
    self.strokes[#self.strokes + 1] = s
    -- `dt` is 0 because nothing here is smoothed -- every row that lays a line
    -- this way has had the pen's `smooth` taken off it, and the row says why.
    s:extend(bx, by, math.huge, self, 0)
    -- Finished on the frame it was begun, because it was: a stroke nobody ever
    -- finishes never ages (Stroke:update), and there is no finger to lift here.
    s:finish()
    -- The wall index is the caller's to dirty and not this function's, because
    -- the callers already own it for their own reasons: a thread dirties it once
    -- for however many rails one pin strung (Game:stringThreads), and a ruled
    -- fence dirties it once for however many lines one cast ruled.
    return s
end

-- One thread, strung between two pins (`thread` in src/tools.lua).
--
-- **What gets strung is whatever else is on the row**, which is the same rule the
-- press itself is routed by one storey up: a row with a second *block* strings
-- that block, cast rather than pressed for, and a row with brush fields strings a
-- mark. Both branches are somebody else's finished code with the two pins where
-- its own two points used to be -- the FOLD taught `Ruler.cast` to be cast by a
-- pair of points and the scissors were always two taps -- so neither of them is a
-- special case anybody has to remember.
function Game:strand(tool, a, b)
    if tool.snap then
        -- The SNAP LINE. `Ruler.cast` reads `snap.length`, so the pins aim the
        -- line rather than bounding it and what comes down runs to the corners of
        -- the page; the FOLD leaves that field out and gets the chord. It lands in
        -- the same call, which is what a cast is.
        return self:castRuler(tool, a.x, a.y, b.x, b.y)
    end
    if tool.cut then
        -- And the TEAR LINE, which is the one branch here that is not new *at
        -- all*: a cut has always been two taps with the page opening between them.
        return self:castCut(tool.cut, a.x, a.y, b.x, b.y)
    end

    local s = self:layLine(tool, a.x, a.y, b.x, b.y)
    -- Held, for as long as both ends of it are standing in the page. Which is
    -- this branch's own rule rather than anything `layLine` knows: a mark ruled
    -- against a straight edge has no posts to outlive and ages from the frame it
    -- was laid (Game:trailRuler).
    s.strung = true

    a.links = a.links or {}
    b.links = b.links or {}
    a.links[#a.links + 1] = { stroke = s, pin = b }
    b.links[#b.links + 1] = { stroke = s, pin = a }
end

-- A post has come out, so every rail on it comes loose: the threads it was
-- holding begin ageing this frame and fade off the page on the tool's own life.
--
-- The link goes from *both* ends, so what is left is a graph of exactly the
-- threads standing between pins that are still holding -- which is what
-- circuitBetween walks, and the reason it never has to wonder whether a corner of
-- a ring is still there.
function Game:unstring(pin)
    -- The pool it left, if it left one. A pool is strung to the *one* post it
    -- pooled round (`pool` in src/tools.lua), so there is no far end to take a
    -- link off -- which is why it is its own field rather than a link with a hole
    -- in it.
    if pin.pooled then
        pin.pooled.strung = false
        pin.pooled = nil
    end

    for _, link in ipairs(pin.links or {}) do
        link.stroke.strung = false
        local theirs = link.pin.links
        for i = #theirs, 1, -1 do
            if theirs[i].pin == pin then table.remove(theirs, i) end
        end
    end
    pin.links = nil
end

-- The other reading of the same idea, and the shorter one: the mark is laid round
-- the *one* pin that has just landed rather than between two (`pool` in
-- src/tools.lua). One dab, at the brush's own radius -- which on both rows that
-- carry it is the crater's 25, because a pool is what filled the hole.
--
-- The order this happens in is the whole of why the CRATER works and is worth not
-- breaking: `Pin:land` has already run by the time this is called (it fires inside
-- the drop's own update, and this fires after it returns), so the crater has
-- killed what it was going to kill and what a pool finds is the survivors.
function Game:poolAt(pin)
    local tool = pin.tool
    local s = Stroke.new(tool, pin.x, pin.y)
    -- A dab cannot close a ring, and nothing here would want it to.
    s.lassos = false
    self.strokes[#self.strokes + 1] = s

    -- The dab itself. A brush with no `stamp` leaves nothing and this is where
    -- that stays true -- the rubber puts no paste down and never did.
    s:addStamp(pin.x, pin.y, self)

    -- **The path is the same point twice**, and that is not a curiosity: a path is
    -- a chain of segments and the walks that measure one are written against
    -- segments, so a dab has to be a segment of no length rather than a lone
    -- point. `Stroke:lingerTick` refuses a path shorter than two points outright,
    -- which would have left the paste never re-freezing anything.
    s.path[3], s.path[4] = pin.x, pin.y

    -- One hit, now, off a zero-length segment -- so the shove goes radially out of
    -- the pin, which is `lean`'s geometry (src/stroke.lua) and exactly what the
    -- CRATER wants. What lingers afterwards is the ordinary tick.
    if s.touches then
        s:damageSegment(self, pin.x, pin.y, pin.x, pin.y)
    end

    -- And the debris, all at once, because there is no travel to spread it over.
    -- `crumbs.chance` is a rate *per stamp* and a pool is one stamp, so the row's
    -- 0.7 buys most of a single crumb off a 51px hole -- which is the same
    -- arithmetic the TACK's `fade = 1` is written against, one stamp being a thing
    -- you cannot have a fraction of. Here it is spent as a broken ring instead: a
    -- spoke every 45 degrees, each one kept at that chance, so the spray is uneven
    -- the way every other edge in this game is uneven rather than a tidy octagon.
    -- Each crumb rolls its own axis (Particles:crumb, which is where the direction
    -- a dab has not got is dealt with), so what comes off is a hole throwing out
    -- what was in it.
    local crumbs = tool.crumbs
    if crumbs then
        for i = 1, 8 do
            if util.hash01(i, s.seed, 23) < crumbs.chance then
                self.particles:crumb(pin.x, pin.y, nil, nil,
                    tool.radius, crumbs.color)
            end
        end
    end

    s:finish()
    -- Held while the post is in the page, the same rule a thread answers to. A row
    -- with no life at all is culled on its first update regardless, which is the
    -- rubber's own "nothing outlives the rub" arriving without a clause.
    s.strung = true
    pin.pooled = s

    self.wallsDirty = self.wallsDirty or tool.wall
end

-- The tightest way round from `a` to `b` through the threads already on the page,
-- not counting the pin that has just landed. Breadth-first, so what comes back is
-- the *smallest* circuit that landing closed rather than whichever one the walk
-- happened to find first -- which matters, because a page with five pins on it has
-- more than one ring in it and the shape you were building is the small one.
--
-- Tiny by construction and deliberately not defended against being large: a pin
-- holds for four seconds and costs half a meter, so a page carries three or four
-- live ones and the graph is that many nodes with three or four edges.
local function circuitBetween(a, b, skip)
    -- Visited, and the parent to walk back through; `false` is "visited, no
    -- parent", which is what stops the walk and what keeps the new pin out of the
    -- ring it is closing.
    local from = { [a] = false, [skip] = false }
    local queue, head = { a }, 1

    while head <= #queue do
        local at = queue[head]
        head = head + 1

        for _, link in ipairs(at.links or {}) do
            local to = link.pin
            if from[to] == nil then
                from[to] = at
                if to == b then
                    local walk, node = { b }, at
                    while node do
                        walk[#walk + 1] = node
                        node = from[node]
                    end
                    return walk
                end
                queue[#queue + 1] = to
            end
        end
    end
end

-- The pencil's finale closed by taps rather than by a wrist: everything inside a
-- ring of pins is cut once (`loop` in src/tools.lua, and the DOT TO DOT row for
-- what the level is doing here).
--
-- The ring is *exact*, which is the whole difference from Stroke:tryCloseLoop.
-- There a path has to be caught coming back near itself, and the rules about
-- perimeter and spent path exist because a hand-drawn wiggle is not a lasso. Here
-- the corners are the pins themselves and a circuit either exists in the graph or
-- does not -- so there is nothing to decide, and the geometry left over is the
-- same even-odd test either way (Stroke.insidePath).
function Game:cutCircuit(tool, ring)
    local path = {}
    for _, pin in ipairs(ring) do
        path[#path + 1] = pin.x
        path[#path + 1] = pin.y
    end

    -- Off the pin that closed it, which is the last corner in the walk: the burst
    -- is the pencil's own (Stroke:tryCloseLoop throws the same one), and it is
    -- thrown where the player is looking rather than at the middle of a shape
    -- nobody drew a centre for.
    self.particles:burst(ring[#ring].x, ring[#ring].y, 5, Palette.ink)

    for i = #self.enemies, 1, -1 do
        local e = self.enemies[i]
        if Stroke.insidePath(e.x, e.y, path, 1) then
            self.particles:burst(e.x, e.y, 2, Palette.red)
            if e:hurt(tool.loop.damage) then
                self:killEnemy(i)
            end
        end
    end
end

-- The other half of five of the eight fusions off the pushpin (`thread` in
-- src/tools.lua): a pin that has just arrived is joined to every pin of the same
-- tool already standing in the page within reach of it. The other two pool round a
-- single pin instead -- Game:poolAt above.
--
-- **Every one of them, not the nearest.** That is what makes a shape possible at
-- all -- the third pin of a triangle has to reach both of the first two on the way
-- in -- and it is bounded by the tool rather than by a cap: two taps is a full
-- meter and a pin holds for four seconds, so a page has three or four live pins on
-- it and a landing strings two or three threads at the very most.
--
-- Live ones only, and there are three separate reasons pulling the same way. A pin
-- still falling is not in the page yet. A pin the page did not keep (Game:dropCrowded)
-- is a crater that already happened and no drawing at all, so a thread hanging off
-- one would hang off nothing. And a *spent* pin is the page's memory of the run --
-- there is no limit on how many of those there are and there must not be, so a rule
-- that threaded to them would lattice the whole page shut over a long run, which is
-- exactly the thing the pen's own `keep` is bounded to prevent.
--
-- Same tool by identity on the run's copy, which is the cheapest honest test there
-- is: it excludes a staple, which is a drop like any other and would be a thread
-- strung between a pin and a crown, and it excludes a pin a compass leg drove in
-- (the SPINDLE), which came from a different row entirely.
function Game:stringThreads(pin)
    local tool = pin.tool
    local reach = tool.thread.reach
    local joined

    for _, other in ipairs(self.drops) do
        if other ~= pin and other.tool == tool
            and other.landed and not other.crowded then
            local dx, dy = other.x - pin.x, other.y - pin.y
            if dx * dx + dy * dy <= reach * reach then
                joined = joined or {}
                joined[#joined + 1] = other
                self:strand(tool, pin, other)
            end
        end
    end

    if not joined then return end

    -- A fence grew, so the index the crowd walks by has to be rebuilt with it --
    -- the one thing Game:updateDrawing does for a line a hand draws that nothing
    -- was doing for a line nobody drew. The flag rather than the rebuild, because
    -- that is how a drawn line asks too (the STOCKADE in src/tools.lua).
    self.wallsDirty = self.wallsDirty or tool.wall

    -- And the ring, if this landing closed one. Two threads at least, or there is
    -- nothing for a circuit to run between; the tightest of whatever it closed,
    -- and only one of them, because being surrounded is one thing happening once.
    if tool.loop and #joined > 1 then
        local best
        for i = 1, #joined - 1 do
            for j = i + 1, #joined do
                local ring = circuitBetween(joined[i], joined[j], pin)
                if ring and (not best or #ring < #best) then best = ring end
            end
        end
        if best then
            best[#best + 1] = pin
            self:cutCircuit(tool, best)
        end
    end
end

-- A pin and a staple are the only two things in the game that are driven into
-- the paper rather than drawn on it, and they are the only two that do not come
-- off it. Every mark fades; these stay, and stay looking exactly as they did
-- going in. So when one finishes holding what it caught it is not thrown away --
-- it stops being updated at all and joins the page. A long run leaves a trail of
-- them behind it, which is a record of where the trouble was.
--
-- Two exceptions, and both are about the record rather than about the rule. A
-- drop that came down where the page already has one is not kept, because two of
-- them inside each other are not a record of anything -- they are a smudge, and
-- it has already done everything it was paid to do by then (Game:dropCrowded).
-- And a drop that says it has `lifted` took itself off the page on the way out:
-- the stapler's third level tears its wire back out of the paper for a second
-- bite (`prise` in src/staple.lua), and wire that has been pulled out is not a
-- record of where the trouble was, it is wire in a bin. That run's page keeps its
-- pins and forgets its staples, which is the trade the level is.
function Game:updateDrops(dt)
    for i = #self.drops, 1, -1 do
        local d = self.drops[i]
        local fell = not d.landed
        local holding = d:update(dt, self)

        -- The frame a pin arrives is the frame the page gains a post, so it is the
        -- frame anything strung off it goes down (`thread` in src/tools.lua).
        --
        -- Here rather than at the foot of Pin:land, and the reason is what the
        -- second half of those three fusions *is*: not something the gesture
        -- carries but a relationship between two things already on the paper, which
        -- is the FOLD's shape and belongs to whatever can see both of them. So
        -- src/pin.lua does not have a line about threads in it and does not want
        -- one -- a pin knows how to fall, punch and hold, and it has never had to
        -- know what else is lying near it.
        --
        -- `d.tool` is only ever stamped on a drop by a row that strings
        -- (Game:dropOne), so every other drop in the game refuses here in one
        -- comparison.
        if fell and d.landed and d.tool and not d.crowded then
            if d.tool.pool then self:poolAt(d) end
            if d.tool.thread then self:stringThreads(d) end
        end

        -- One that came down on a spot the page already has one in goes the frame
        -- it has landed, rather than at the end of its hold (Game:dropCrowded).
        -- Landed rather than placed, because the landing is the whole of what it
        -- was paid for -- a pin still falls, still punches its crater and still
        -- pays its refund -- and the hold it leaves behind is carried on the enemy
        -- rather than by the thing on the paper, which is why letting go of the
        -- drawing costs nothing: what a hold is doing is read off the body that
        -- has stopped moving and grown a blue shadow.
        if d.crowded and d.landed then
            table.remove(self.drops, i)
        elseif not holding then
            table.remove(self.drops, i)
            -- A post that has finished holding is a drawing and nothing else, so
            -- the rails on it come loose and start fading. Ahead of the spent pile
            -- rather than after it, so nothing is ever threaded to a pin that has
            -- already stopped being updated.
            if d.links or d.pooled then self:unstring(d) end
            if not d.lifted then self.spent[#self.spent + 1] = d end
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
    -- The whole row on the object, where Ruler.new only ever wanted the block.
    -- Same stamp Game:dropOne puts on a pin and for the same reason: what a
    -- straight edge is *carrying* is written on the row beside the block, and the
    -- thing that lands is the only thing still holding both by the time anybody
    -- asks (Game:trailRuler).
    self.ruler.tool = tool
    self.ruler:aimAt(x, y)
    self.rulers[#self.rulers + 1] = self.ruler
end

-- Lifting the pointer lands it, and so does anything else that takes the aim
-- away -- changing tool, or holding the run. The ink is already spent, so the
-- alternative would be pocketing it.
function Game:snapRuler()
    if self.ruler then
        Sfx.play("ruler")
        self.ruler:strike(self)
        self:trailRuler(self.ruler)
        self.ruler = nil
    end
end

-- A ruler nobody aimed and nobody paid for here, dropped flat between two points
-- the page worked out for itself: the FOLD (src/tools.lua), where two compass
-- circles crossing rule the line between their two crossings. `Compass:crease` is
-- the whole of the geometry and this is the whole of the landing.
--
-- It lands in the same call it is made in, which is what makes it a cast rather
-- than an aim -- there is no pointer holding it up and nothing to release. So it
-- never goes in `self.ruler`: that slot is the one being held, and every route
-- that takes the pointer away lands *it* (Game:snapRuler). This one has already
-- landed by the time anything else can look.
--
-- No ink. The needle was charged for at the press exactly as it always is, and
-- the second half of this tool is paid for in a *second press of the first half*
-- -- one circle rules nothing at all, so the price of a fold is two swings and
-- the timing between them, which is a price nothing else on the strip charges.
function Game:castRuler(tool, ax, ay, bx, by)
    local ruler = Ruler.cast(tool.snap, ax, ay, bx, by)
    ruler.tool = tool
    self.rulers[#self.rulers + 1] = ruler

    Sfx.play("ruler")
    ruler:strike(self)
    -- A cast ruler is carrying whatever an aimed one would be. Nothing does
    -- today -- the two rows that cast are the FOLD and the SNAP LINE and neither
    -- has a second thing on it -- but the alternative is a rule that holds for the
    -- ruler you aim and quietly does not for the one the page works out, which is
    -- the kind of hole a fusion falls into a year later.
    self:trailRuler(ruler)
end

-- What the straight edge was carrying, ruled along the line it has just landed
-- on: the seven rows at the foot of src/tools.lua.
--
-- **The ruler opens a lane and these keep it open**, which is the family's whole
-- argument and the reason it is one function. A ruler's mark is a ruled pencil
-- line that does nothing at all -- everything within the band is hit once, thrown
-- clear of the line to both sides, and the corridor that leaves closes again the
-- moment the crowd walks back into it. So the tool has always been a shove with
-- nothing behind it, and every row here is the same fix: whatever the second
-- parent leaves on paper, left along that line.
--
-- **After the strike and never before**, which is `Game:poolAt`'s order for
-- `poolAt`'s reason: the ruler has already killed what it was going to kill by
-- the time this runs, so what a trail finds is the survivors. The two are on the
-- same frame either way -- a shove is an impulse `Enemy:update` spends on the
-- *next* one, so nothing has moved between them -- and the one thing the order
-- does decide is what the crowd is standing in when the damage lands, which is
-- the answer the crater already argued for.
--
-- The one interaction worth knowing before writing another row: **a ruler that
-- fastens is a ruler that does not shove.** A held body drops the push it was
-- carrying (`frozen` in Enemy:update, the HEM's paragraph about a leg working a
-- stapler), so the two rows here that hold -- the TRENCH's paste and the SEAM's
-- wire -- forfeit the shove on everything they catch. That is not a bug to route
-- around; it is the gluestick and the stapler being what they are, and both rows
-- say so.
--
-- Field presence, exactly as everything else here is routed. A row with none of
-- these is a plain ruler and this costs it one nil test -- which the FOLD and the
-- SNAP LINE both are.
function Game:trailRuler(ruler)
    local tool = ruler.tool
    if not tool then return end

    local def, ax, ay, bx, by = ruler.def, ruler:ends()

    -- The page opened along the same line (the GUILLOTINE). Cast between the two
    -- ends rather than aimed by them, which is the FOLD's reading of a cast and
    -- not the SNAP LINE's: a ruler that already reaches the corners has nowhere
    -- left to run on to.
    if tool.cut then self:castCut(tool.cut, ax, ay, bx, by) end

    -- Wire pressed in along it (the SEAM). Inside the block rather than on the
    -- row, and `Game:updateDrawing`'s precedence list is the whole reason -- see
    -- the note there about the one pair of blocks whose borrowing goes both ways.
    if def.wire then self:seamAlong(def.wire, ax, ay, bx, by) end

    -- And a mark ruled along it, which is four of the seven. `stamp` is the test
    -- Compass:swing uses for the same question one gesture over: a leg with no nib
    -- draws no band, and a straight edge with nothing to rule against it rules
    -- nothing.
    if tool.stamp then
        if tool.margins then
            -- Both long edges rather than the centre line (`margins`, the MARGIN
            -- in src/tools.lua). Which is the pair of dashed lines the aim has
            -- been drawing all along (Ruler:drawGuide) turned into two real ones --
            -- and the band's own edge is exactly the place a ruler has always been
            -- weakest, since a body a pixel outside it takes nothing at all.
            local nx, ny = -math.sin(ruler.angle), math.cos(ruler.angle)
            local w = def.width
            self:layLine(tool, ax + nx * w, ay + ny * w, bx + nx * w, by + ny * w)
            self:layLine(tool, ax - nx * w, ay - ny * w, bx - nx * w, by - ny * w)
        else
            local s = self:layLine(tool, ax, ay, bx, by)
            -- The pen's last level, and the one place in the family it lands
            -- cleanly: one cast is one gesture, so ruling the next fence is what
            -- lets the last one go, exactly as drawing the next line is for a hand
            -- (Game:updateDrawing) and swinging the next circle is for an arm
            -- (Compass:swing). The STOCKADE could not have this -- a fence built
            -- pin by pin is not one gesture -- and that is the difference between
            -- the pen's two answers rather than an accident.
            if tool.wall or tool.keep then
                self:holdWalls(tool.keep and { s } or nil)
            end
        end
        self.wallsDirty = self.wallsDirty or tool.wall
    end
end

-- A seam of staples pressed into the page along a straight line between two
-- points, one every `rake.every` pixels of it: the line a ruler landed on (the
-- SEAM in src/tools.lua) or the line between a pair of scissors' two taps (the
-- HINGE).
--
-- The stapler's own spacing read against a line instead of round a rim
-- (Compass:loadSeam) or under a finger (Game:rakeDrops), which is the third
-- reader of one field and the reason it stayed a field: what `every` says is how
-- far apart along a path the presses go, and a path is a path. This function
-- knows nothing about what drew the line it is filling, which is why the second
-- caller cost it two points and an argument rather than a copy of itself.
--
-- Nothing is charged here. The whole price was paid at the gesture, and a seam
-- that ran out of wire half way along would be a tool charging twice for one
-- press -- so the count is decided by the line. For the ruler the line is decided
-- by the screen, which is what lets that row write one flat price down and mean
-- it; for the scissors it is decided by how far apart the two taps went, which is
-- the one place in the game where a flat price buys a length the player chose.
-- The HINGE's row argues that trade rather than pricing around it.
--
-- Heard once. Thirty-odd presses landing inside one frame is not a sound, it is a
-- click, and Compass:seamPress already had to thin the same seam out over time to
-- keep it one; here there is no time to thin it over, so the first press speaks
-- for all of them. `hush` is a caller that has already spoken for the seam:
-- Game:closeCut drives the staple the player's own tap put in and then fills the
-- line behind it, and two clacks in one frame is the thing this paragraph is
-- about.
function Game:seamAlong(wire, ax, ay, bx, by, hush)
    local every = wire.rake.every
    local dx, dy = bx - ax, by - ay
    local dist = util.len(dx, dy)
    if dist < every then return end

    local nx, ny = dx / dist, dy / dist
    -- Started half a step in and walked to the far end, so the seam is centred on
    -- the line rather than hanging off one end of it: the two ends of a ruler are
    -- the same end as far as anything using it is concerned, and a seam that began
    -- exactly at one of them would put a staple on the corner of the page and
    -- leave half a gap at the other. It is what the scissors want too, one reason
    -- along: both ends of that line already have a staple in them, driven by the
    -- taps themselves, so the seam is the *filling* and must not start on top of
    -- one of them.
    local t = every / 2
    while t <= dist do
        self:driveDrop(wire, ax + nx * t, ay + ny * t, hush)
        hush = true
        t = t + every
    end
end

function Game:updateRulers(dt)
    for i = #self.rulers, 1, -1 do
        if not self.rulers[i]:update(dt, self) then
            table.remove(self.rulers, i)
        end
    end
end

-- How wide the meter can still afford to open a sweep, and how much the width it
-- was opened to costs on top of the needle. One row in the catalogue answers
-- anything but "all the way" and "nothing": the HEM (src/tools.lua), whose leg is
-- working a stapler and whose drag is therefore buying *wire* -- one staple every
-- `rake.every` pixels of rim, so a wider circle is more of them.
--
-- Which makes it the one tool whose price is not settled by the press, and these
-- two are the whole of what that took. The cap is asked every frame of the drag so
-- the leg simply stops opening where the ink runs out -- a legible thing rather
-- than an error, and the same answer the meter gives a brush that runs dry
-- mid-line. The price is charged once, at the release, off the width that was
-- actually reached.
--
-- The pair cannot disagree, and that is the reason the cap is a radius rather than
-- a count: `seamRadius` floors to exactly the number of presses it was handed, so
-- the widest circle the drag allows is the widest circle the meter can pay for,
-- and nothing else spends ink while a pointer is down on a compass. So the
-- compass's own promise holds -- letting go always draws the circle.
function Game:sweepReach(tool)
    local sweep = tool.sweep
    if not sweep.per then return sweep.maxR end

    local every = tool.drop.rake.every
    local paid = Compass.seamCount(sweep.minR, every)
        + math.floor(self.ink / sweep.per)
    return math.min(sweep.maxR, Compass.seamRadius(paid, every))
end

function Game:sweepPrice(tool, radius)
    local sweep = tool.sweep
    if not sweep.per then return 0 end

    local every = tool.drop.rake.every
    return sweep.per * (Compass.seamCount(radius, every)
        - Compass.seamCount(sweep.minR, every))
end

-- The needle goes in on the press and the price of the smallest circle goes in
-- with it. From here the circle is coming; the only thing left to decide is how
-- wide, and the drag out of the press is what decides it -- and on one row it is
-- also what the rest of the price is decided by (Game:sweepReach above).
function Game:plantCompass(tool, x, y)
    self:spendInk(tool.ink)

    self.compass = Compass.new(tool, x, y)
    self.compasses[#self.compasses + 1] = self.compass
    self.particles:burst(x, y, 5, Palette.graphite) -- fibres off the puncture
end

-- Lifting the pointer swings it, and so does anything else that takes it away
-- -- a tool change, holding the run -- at whatever width it had got to. The
-- same bargain the ruler makes: the needle is already paid for, so the
-- alternative is pocketing the ink.
function Game:swingCompass()
    if self.compass then
        -- The lead coming round is a drawn line, so it borrows the brushes:
        -- the swish whose length best fits this swing, pitched to fit it
        -- exactly. The swing lasts `turn` seconds a lap, and two legs share
        -- the turn between them.
        local def = self.compass.def
        local name, pitch =
            Sfx.brushFor(def.turn * def.laps / (def.counter and 2 or 1))
        Sfx.play(name, pitch)

        -- What the width cost, for the one row that charges for it (the HEM).
        -- Charged here rather than as the drag opened, so it is one spend for one
        -- gesture and a drag that opened out and thought better of it pays for the
        -- circle it actually drew. Nothing can make this unaffordable: the drag was
        -- capped against the same arithmetic every frame it grew (Game:sweepReach).
        self:spendInk(self:sweepPrice(self.compass.tool, self.compass.radius))

        -- Handed the run, because a leg carrying a nib opens a stroke as it sets
        -- off and that stroke belongs on the page with every other mark.
        self.compass:swing(self)
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

-- The first tap of a cut. Nothing is charged here and nothing is on the page but
-- a mark saying where the blades are: an anchor is not a cut, and the cut is what
-- costs.
--
-- Which makes this the one gesture on the strip that is paid for afterwards. The
-- ruler and the compass both charge on the press because letting go of either
-- always lands it -- there is no picking one up and changing your mind -- and
-- there is nothing here to land yet. It is also the one press that leaves state
-- behind it for the next press to find, which is why every route that takes the
-- pointer away has to call Game:dropCut.
--
-- **Unless the blades are carrying wire (`cut.wire`, the HINGE in src/tools.lua),
-- and then the anchor is a press that lands something and is charged like one.**
-- A staple goes into the page where you tapped, so half the price goes with it --
-- the row writes the half and the meter is checked against the same number on
-- both taps (Game:updateDrawing), which is what makes the gesture two equal
-- presses of a stapler with a cut thrown in for the second one.
--
-- That is not a special case so much as the free anchor's premise expiring. The
-- anchor is free *because* it does nothing, and the moment it does something the
-- old rule pays out an unlimited stapler: tap to anchor, tap back on the anchor
-- to put the scissors away (see Game:closeCut), and repeat for a staple a tap
-- with nothing spent. Charging the tap that drives the staple closes that and
-- makes the cancel honest at the same time -- you paid for a press and you got a
-- press, which is a better answer than the parent's "nothing for nothing".
--
-- **The block and its price are handed in rather than read off the tool**, and
-- that is what lets a row whose gesture is *not* a cut still make one. A brush
-- carries the scissors as `chord` -- a whole `cut` block that is not the row's
-- block, the `fasten` trick one shape over -- and the SHEAR's chord is tapped for
-- exactly like the parent's (`Game:chordCut`). Neither of these two functions has
-- any business knowing which field it came out of, and there is one price rather
-- than a rule for finding one: the row's `ink` for a pair of scissors, the
-- chord's own for a brush that also cuts.
function Game:openCut(def, cost, x, y)
    self.cutFrom = { x = x, y = y }

    local wire = def.wire
    if wire then
        self:spendInk(cost)
        self:driveDrop(wire, x, y)
    end
end

-- The second tap, which is where something actually happens and therefore where
-- the price is paid. The cut runs from the anchor towards the tap and no further
-- than the tool's reach, so past that the tap is choosing the direction rather
-- than the far end (Scissors.clip).
--
-- What happens is the dotted line being printed, though: nothing is cut here.
-- The blades close along that line over the next several frames and
-- Game:updateCuts is what walks them down it, so what a cut takes is the crowd
-- as it stands when they arrive rather than the crowd this tap was aimed at.
--
-- A tap back on the anchor is putting the scissors away instead: the anchor goes
-- and nothing is spent. That is deliberately the same gesture as making a cut
-- rather than a second control to find in a panic.
function Game:closeCut(def, cost, x, y)
    local from = self.cutFrom
    self.cutFrom = nil

    local ax, ay = from.x, from.y
    if util.len(x - ax, y - ay) < Scissors.MIN then return end

    self:spendInk(cost)

    -- The player's position goes in because the finale needs to know which half
    -- of the page you are standing on, and that is settled here, once. Everything
    -- else about the cut's shape -- how far the aimed stretch reaches, how far it
    -- runs on past both taps, how long the blades take to get down it -- the cut
    -- measures for itself off the page it is being made on.
    local cut = Scissors.new(def, ax, ay, x, y, self.player.x, self.player.y)
    self.cuts[#self.cuts + 1] = cut

    -- The blades still have to travel the line (Game:updateCuts) and this tap
    -- has already landed, so held open exactly as a falling pin is -- see
    -- src/multikill.lua -- and released once Scissors:update says they have
    -- arrived.
    self.multikill:hold()

    -- And the wire, if the blades are carrying any (the HINGE): a staple where
    -- this tap landed, and then the stretch between the two taps filled in at the
    -- stapler's own spacing. The anchor already has one -- Game:openCut drove it
    -- on the press that placed it -- so what is left is this end and the middle.
    --
    -- **Before the cut is anything but a dotted line, and that is the whole
    -- interaction.** The blades take a beat to travel (Game:updateCuts), and what
    -- they arrive at is a row of bodies the wire has just pinned to the paper: the
    -- seam holds the crowd along the line and the cut comes down it a moment
    -- later. Nothing had to arrange that, and it is the reason these two parents
    -- go together at all -- the scissors' one weakness is that the horde walks out
    -- of the line between the taps, and a stapler is the tool that stops things
    -- walking.
    --
    -- Read off the *cut* rather than off the two taps, which is the same two
    -- points today and would not be on a row with a finite `reach`: what the cut
    -- kept is the aimed stretch after the clip (`Scissors.measure`), and the wire
    -- has to run exactly where the blades bite deeper (`blades`) rather than out
    -- to a tap the reach refused.
    --
    -- Hushed after this one press, `Game:seamAlong`'s rule: what the player did
    -- was tap, and thirty clacks is not a tap.
    local wire = def.wire
    if wire then
        self:driveDrop(wire, cut.bx, cut.by)
        self:seamAlong(wire, cut.ax, cut.ay, cut.bx, cut.by, true)
    end

    -- Borrowed from the brushes until there is a snip of its own, the way the
    -- compass borrows one for its swing: the swish that best fits how long the
    -- blades will be closing, pitched to fit it exactly. Which is why it is asked
    -- for after the cut is built rather than before -- a cut running edge to edge
    -- takes three times as long to open as a short one, and a sound that ran out
    -- halfway down the line would be one saying the cut was over when it wasn't.
    Sfx.play(Sfx.brushFor(cut.sweepT))
end

-- A cut nobody tapped twice and nobody paid for here: opened between two pushpins
-- standing in the page (the TEAR LINE, `thread` in src/tools.lua). Game:closeCut
-- above minus the anchor and minus the ink -- the pins were charged for as pins,
-- and the second half of that tool is paid for in a second tap of the first half.
--
-- It keeps the parent's own refusal, and the number with it: two points closer
-- together than `Scissors.MIN` are not a cut, because a cut needs a direction and
-- six pixels of baseline is not one. Two pins can just about land that close --
-- Game:dropCrowded refuses a *box* five wide, which a pair five and a half apart
-- on the diagonal slips past -- so the guard is real rather than defensive.
function Game:castCut(def, ax, ay, bx, by)
    if util.len(bx - ax, by - ay) < Scissors.MIN then return end

    local cut = Scissors.new(def, ax, ay, bx, by, self.player.x, self.player.y)
    self.cuts[#self.cuts + 1] = cut
    Sfx.play(Sfx.brushFor(cut.sweepT))
end

-- Anything that takes the pointer away drops the anchor: a tool change, or the
-- run being held. Free, because the anchor was.
function Game:dropCut()
    self.cutFrom = nil
end

function Game:updateCuts(dt)
    for i = #self.cuts, 1, -1 do
        if not self.cuts[i]:update(dt, self) then
            table.remove(self.cuts, i)
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

    -- Steady rather than `bounds`: this is the one place a screen position is
    -- turned into a page position, and it must not read the knock a hit put in
    -- the camera (Camera.steady). Everything else in the frame moves with the
    -- shake; the point of the page your finger is on does not.
    local left, top = Camera.steady()
    local down = Input.pointerDown

    if down and not self.wasDown then
        -- A new gesture, whichever block below ends up carrying it -- see
        -- src/multikill.lua for why this is the edge that starts one.
        self.multikill:beginGesture()

        -- A brush wants enough in the meter to be worth starting a line with; a
        -- pin, a ruler, a compass or a pair of scissors wants exactly its own
        -- price, since there is no half of any of them. The scissors are checked
        -- on both of their taps and the anchor survives a blocked one, so a cut
        -- lined up with an empty meter waits for the ink rather than being lost.
        local flat = tool.drop or tool.snap or tool.sweep or tool.cut
        self.drawBlocked = self.ink < (flat and tool.ink or Tools.MIN_INK)

        -- What the *finger* did, which is a different question from what the line
        -- did and the only honest way to ask whether a press was a tap. See
        -- Game:wasTap.
        self.pressT, self.pressTravel = 0, 0
        self.pressX, self.pressY = Input.pointerX, Input.pointerY
    end

    -- Accumulated every frame the pointer is down, in *screen* pixels, whether or
    -- not this tool is drawing anything -- a press blocked by an empty meter is
    -- still a press somebody made, and the travel is what says what they meant by
    -- it. Accumulated rather than measured end to end, so a wiggle that came back
    -- to where it started is not a tap: what is being asked is whether the finger
    -- moved, not whether it ended up somewhere else.
    if down then
        self.pressT = (self.pressT or 0) + dt
        self.pressTravel = (self.pressTravel or 0)
            + util.len(Input.pointerX - (self.pressX or Input.pointerX),
                       Input.pointerY - (self.pressY or Input.pointerY))
        self.pressX, self.pressY = Input.pointerX, Input.pointerY
    end

    if down and not self.drawBlocked then
        local wx, wy = Input.pointerX + left, Input.pointerY + top

        -- **The order of these four is a precedence list, not an arbitrary
        -- order**, and it earns its keep the moment a row carries two blocks. The
        -- first one a row has is the gesture and the rest are what that gesture is
        -- *carrying* or *casting* -- so the two tools whose gesture is worth
        -- borrowing come first, and they come in the order they borrow from each
        -- other. A sweep beats everything, because the compass fusions put a drop
        -- on the end of the arm (the SPINDLE, the HEM). A drop beats a snap and a
        -- cut, because the pushpin fusions cast a ruler and a pair of scissors
        -- between two pins (the SNAP LINE, the TEAR LINE) and nothing has ever
        -- gone the other way. `Tools.BLOCKS` is a different list for a different
        -- job -- what the multipliers have to walk -- and the two are not required
        -- to agree.
        --
        -- **One pair of blocks borrows both ways, and a list cannot say so.** The
        -- pushpin casts a ruler between two pins (the SNAP LINE, so `drop` has to
        -- beat `snap`) and the ruler presses a seam of staples along the line it
        -- lands on (the SEAM, so `snap` would have to beat `drop`). There is no
        -- order that is both. The fix is not a flag and not a special case: the
        -- SEAM's staples are written *inside* its `snap` block (`wire`, and
        -- Game:trailRuler is what reads it), which says in the shape of the row
        -- what a flag would have had to say in a branch -- that the wire is what
        -- the straight edge is carrying and never the gesture. A block that is not
        -- the gesture may live one level in; a block that might be cannot.
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
                self.compass:reachTo(wx, wy, self:sweepReach(tool))
            end

        elseif tool.drop then
            -- One per press, and for the pushpin that is the whole of it:
            -- holding the pointer down does nothing more and dragging it rakes
            -- no line of them across the page. It is what makes a tapped tool
            -- cost taps rather than ink -- ten of them is ten separate
            -- decisions, and a held finger is none.
            --
            -- The stapler's last level buys exactly that rule off it (`rake`),
            -- and so does the fusion of the two tools that share this block (the
            -- VOLLEY, src/tools.lua) -- which is the same field doing the same
            -- thing at four and a half times the price and four times the width,
            -- and the reason it is a field rather than a branch. The drag is guarded on
            -- the anchor the press edge left rather than on `wasDown` alone,
            -- which is the ruler's and the compass's guard for their reason: a
            -- press that was already down when the tool changed is not this
            -- tool's press, and a seam run from wherever the *last* press ended
            -- would staple a line across a page nobody dragged over.
            if not self.wasDown then
                self:dropOne(tool, wx, wy)
                self.rakeX, self.rakeY = wx, wy
            elseif tool.drop.rake and self.rakeX then
                self:rakeDrops(tool, wx, wy)
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
        elseif tool.cut then
            -- Two presses, and the only gesture on the strip that spans more
            -- than one. Nothing happens while the finger is down -- dragging a
            -- cut would make it a stroke, and taking two taps is the whole
            -- price of a tool that can be placed anywhere: the horde gets to
            -- walk between them.
            if not self.wasDown then
                if self.cutFrom then
                    self:closeCut(tool.cut, tool.ink, wx, wy)
                else
                    self:openCut(tool.cut, tool.ink, wx, wy)
                end
            end
        else
            if not self.stroke then
                self.stroke = Stroke.new(tool, wx, wy)
                self.strokes[#self.strokes + 1] = self.stroke
                self.drawSpeed = 0

                -- The pen's last level (`keep` in src/tools.lua): the wall you
                -- drew last is held on the page, and drawing this one is what
                -- lets it go. One gesture's worth held at a time is the whole of
                -- the level -- a run cannot lattice the page shut, and a page it
                -- did box itself into is still a page the eyes shoot over
                -- (Game:updateBullets) and the boss has to be killed on. See
                -- Game:holdWalls for the rest of it, including why laying a wall
                -- releases the old one whether or not this one is held in its
                -- turn.
                --
                -- A hand is not the only thing that lays a fence: a compass leg
                -- carrying a pen claims the hold the same way from
                -- Compass:swing.
                -- **`or tool.keep`, because one row is held without being a
                -- fence.** The DEADLINE gives up the pen's wall -- a wall is a line
                -- the crowd steers around and that row's whole payload is what
                -- happens when they touch it -- and keeps `keep`, which is what
                -- makes it a line that stays. The hold is a fact about the
                -- *gesture* rather than about walls, and it always was; the guard
                -- said `wall` only because until now every row that kept anything
                -- kept a fence.
                if tool.wall or tool.keep then
                    self:holdWalls(tool.keep and { self.stroke } or nil)
                end

                -- The near end of a line that fastens itself down (the STITCH).
                -- On the press and not on the release, because a stapler lands the
                -- instant you tap and always has -- see Game:fastenEnds. The far
                -- end is laid when the finger lifts, and only if it travelled.
                --
                -- `tapped` is the one row that fastens neither end (the SNAG): there
                -- the staple *is* the tap and the drag is the other gesture
                -- entirely, so nothing can go in until the release has said which of
                -- the two the player just made. A press that fastened first would
                -- put a staple at the head of every rub -- and then tear it straight
                -- back out, the rub being the thing that takes staples out.
                if tool.fasten and not tool.fasten.tapped then
                    self:fastenEnds(self.stroke, wx, wy)
                end

                -- A rub is continuous, so its sound is too: the loop starts
                -- with the stroke and Game:endStroke is what stops it. The
                -- glue speaks on the press because a dab is already a smear;
                -- the other brushes wait for the nib to actually move
                -- (Game:strokeSwish).
                --
                -- The icon and not `snag`, which is the one place those two come
                -- apart: a row whose press might be a *staple* has nothing to start
                -- yet (`fasten.tapped`, the SNAG), because a tap there is a clack
                -- and nothing else and a tenth of a second of rubbing under it would
                -- be the wrong tool being heard. It is the one press in the game
                -- where what the sound should be is not known yet, so that row
                -- starts its loop where the gesture commits instead -- below.
                if tool.icon == "rubber" then
                    Sfx.startLoop("rubbing")
                elseif tool.icon == "glue" then
                    self.strokeVoice =
                        Sfx.play(love.math.random() < 0.5 and "glue1" or "glue2")
                end
            end

            -- **A row whose press means something else does not rub until the press
            -- has stopped being one** -- `fasten.tapped` on the SNAG, where the
            -- press might be a staple, and `chord.tapped` on the SHEAR, where it
            -- might be the tap that anchors or closes a cut. `touches` is already
            -- the field for "does this mark hit anything at all" (src/stroke.lua),
            -- and these are the rows where the answer is not a fact about the tool
            -- but a fact about the gesture so far: while the press could still turn
            -- out to be a tap it is a stapler being pressed or a pair of scissors
            -- being placed, and neither of those shoves.
            --
            -- Which matters for the reason `Game:wasTap` exists at all. A finger
            -- held still while the player *walks* lays real world line, so without
            -- this a tap taken on the run would rub the few pixels the page slid
            -- under it -- throwing the thing you were about to fasten twenty-seven
            -- pixels clear of the staple, on the one press the tool is for. On the
            -- SHEAR it is worse than cosmetic and it is the whole row: the crowd
            -- would be shoved off the line in the gap between the two taps, which is
            -- the one thing that pairing exists to stop. Set every frame rather than
            -- latched, which costs nothing: both numbers `wasTap` reads only ever
            -- grow, so it goes false once and stays.
            --
            -- Whichever block carries the flag is the one asked, since a row has at
            -- most one press to be ambiguous about.
            local held = (tool.fasten and tool.fasten.tapped and tool.fasten)
                or (tool.chord and tool.chord.tapped and tool.chord)
            if held then
                local rubbing = not self:wasTap(held)
                -- And the rub is heard from the same instant it starts landing,
                -- which is what the press could not do: `touches` flips once and
                -- stays, so testing it is what says "this frame is the one". The
                -- loop is stopped by Game:endStroke either way, which is safe to
                -- call with nothing playing (`Sfx.stopLoop`). `crumbs` for the
                -- reason Game:endStroke asks it: both rows with an ambiguous press
                -- happen to be rubs, and one field rather than that coincidence is
                -- what keeps a third row from starting an eraser it is not holding.
                if rubbing and not self.stroke.touches and tool.crumbs then
                    Sfx.startLoop("rubbing")
                end
                self.stroke.touches = rubbing
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
            -- The SWELL's paced nib (`pace` in src/tools.lua): what is on the page
            -- is thinner, so what comes out of the meter is less -- the ratio of
            -- the two nibs, so the price cannot disagree with the width. Priced off
            -- the nib the last frame's travel picked, which is `flow`'s own lag on
            -- a fraction that only ever has two values.
            if tool.pace then
                rate = rate * self.stroke:paceRate()
            end

            local budget = self.ink / rate
            local used = self.stroke:extend(wx, wy, budget, self, dt)
            if used > 0 then
                self:spendInk(used * rate)
                -- The line just grew, so the fence it makes has to grow with it.
                self.wallsDirty = self.wallsDirty or tool.wall
            end
            self:strokeSwish(tool, used, dt)
            if self.ink <= 0 then
                self:endStroke()
                self.drawBlocked = true
            end
        end
    elseif not down then
        -- The STUB's tap (`tap` in src/tools.lua), and this is the only place in
        -- the game that can fire it: a press is not a tap until it has ended
        -- without going anywhere, so nothing before the release knows which of the
        -- two gestures the player just made. `slack` is how much line still counts
        -- as none -- the rubber's own release already draws that same line for its
        -- sound (`RUB_HEARD`), because a rub that covered no ground did not happen.
        --
        -- Priced flat, like a tapped tool, and refused rather than clamped the way
        -- every other price in the game is: a tap you could not afford simply did
        -- not land. It is charged here rather than on the press because the press
        -- had no way of knowing, and `MIN_INK` already stopped the stroke starting
        -- on an empty meter.
        --
        -- Ahead of endStroke, which is what makes the reading of `drawn` honest:
        -- the stroke is still the one the finger was holding.
        local mark = self.stroke
        if mark and mark.tool.tap and self:wasTap(mark.tool.tap)
            and self.ink >= mark.tool.tap.ink then
            self:spendInk(mark.tool.tap.ink)
            mark:tap(self)
        end

        -- And the far end of a line that fastens itself down (the STITCH). The
        -- near end went in at the press, where the finger was -- see the brush
        -- branch above -- so what is left for the release is the end you stopped
        -- at, and only if you actually went anywhere. See Game:fastenEnds.
        --
        -- `tapped` is the same question read the other way round (the SNAG): the
        -- one staple goes in *because* the finger never went anywhere, and a press
        -- that turned into a drag fastens nothing, having spent itself rubbing. One
        -- field, two rows, and between them every answer a gesture with one end and
        -- a gesture with two can give -- which is why it is a field on the block and
        -- not a second branch beside `tap`.
        if mark and mark.tool.fasten then
            local fasten = mark.tool.fasten
            if self:wasTap(fasten) then
                if fasten.tapped then self:fastenEnds(mark, mark.x, mark.y) end
            elseif not fasten.tapped then
                self:fastenEnds(mark, mark.x, mark.y)
            end
        end

        -- And the page opened along the line, or by the two taps that never drew
        -- one: `chord` in src/tools.lua and Game:chordCut, which is the clause
        -- above one field over -- both are a whole block on a brush row, both are
        -- read at the release because a press is not a tap until it has ended, and
        -- both let `tapped` decide which of the two gestures they belong to.
        if mark and mark.tool.chord then self:chordCut(mark) end

        self:endStroke()
        self:snapRuler()
        self:swingCompass()
        self.drawBlocked = false
        -- The seam ends with the press. Cleared rather than left where it was,
        -- so the next press has to lay its own anchor -- see the drop branch.
        self.rakeX, self.rakeY = nil, nil

        -- After everything above, which is the last of what a lifted finger
        -- can still trigger -- a tap, a chord cut, the ruler's and the
        -- compass's own finish. Safe to call every frame the pointer is up,
        -- same as the clears above it: it is already false past the first.
        self.multikill:endGesture()
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
            -- The pen's third level: the mark's life running out is an event
            -- rather than a fade. A held wall never reaches here while it is
            -- held, so what pops is either a line you let expire or the one you
            -- replaced, nine seconds after replacing it.
            if s.tool.pop then s:pop(self) end
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
    -- Ahead of every state branch, so a swish cut on the same press that
    -- paused or ended the run still fades out instead of hanging mid-cut.
    Sfx.update(dt)

    if self.state == "menu" then
        local answer = Menu:update(dt, self)
        if answer == "yes" then
            self:toTimetable()
        elseif answer == "no" then
            love.event.quit()
        elseif answer == "continue" then
            self:continueRun()
        elseif answer == "settings" then
            self:toSettings()
        end
        return
    end

    -- The settings page hands nothing over: the one thing it can answer with is
    -- the corner button, and it has already saved whatever was changed. The title
    -- comes back with its lettering already on -- see Game:toMenu.
    if self.state == "settings" then
        if Settings:update(dt, self) == "back" then
            Sfx.play("transition2")
            self:toMenu(true)
        end
        return
    end

    -- The timetable answers with what was asked for and the lesson it was asked
    -- about. `GO!` opens the book at that page and starts the run on it; `CUSTOM`
    -- opens the book at it and hands you the board instead, which comes back here
    -- when it is done. Either way the subject is set first, because the board has
    -- to be drawn on the page the drawing will be read against.
    --
    -- `back` is the corner button rather than a box, and it is the one answer
    -- that does *not* set the subject: nothing was decided, so the book closes on
    -- whatever page it was already open at.
    if self.state == "timetable" then
        local answer, key = Timetable:update(dt, self)
        if answer == "back" then
            Sfx.play("transition2")
            self:toMenu()
            return
        end

        if answer then self:setSubject(key) end

        if answer == "go" then
            Sfx.play("transition2")
            -- Before the run, not after: the bookmark on disk is about the last
            -- run and this is the frame it stops being the most recent thing that
            -- happened. Clearing it here rather than inside Game:reset is what
            -- keeps the scaffolding reset in Game:load from deleting a bookmark on
            -- every launch.
            Bookmark.clear()
            self:reset()
        elseif answer == "custom" then
            self:toStudio(Design.hero(), "timetable")
        elseif answer == "library" then
            self:toLibrary()
        elseif self.pages[answer] then
            self:toPage(answer)
        end
        return
    end

    -- The library hands nothing over: the one thing it can answer with is the
    -- corner button, and the lesson is exactly where it was left.
    if self.state == "library" then
        if Library:update(dt, self) == "back" then
            Sfx.play("transition2")
            self:toTimetable()
        end
        return
    end

    -- And the canteen and the homework page, on the same terms.
    local page = self.pages[self.state]
    if page then
        if page:update(dt, self) == "back" then
            Sfx.play("transition2")
            self:toTimetable()
        end
        return
    end

    if self.state == "studio" then
        -- Which board was handed over comes back with the answer rather than
        -- being remembered from `toStudio`: the hero's board can change which
        -- design it is showing while it is up, since the roster's arrows step
        -- between one hero drawing and another (src/design.lua).
        local answer, design = Studio:update(dt, self)
        if answer == "done" then
            -- A character who carries something drawn hands the board straight on
            -- to it instead of going back to the timetable: the swordsman's sword
            -- and the shootman's shot are as much of them as their own outline, so
            -- the two boards are one visit to the studio rather than a second
            -- screen to go and find. Only from the timetable -- a board opened
            -- mid-run is a weapon the draft just gave you, and the run underneath
            -- is waiting.
            -- `Design.ask` is the same clause the draft is guarded by: a board
            -- the game opens *for* you is a board that can be turned off, and
            -- this is one -- you asked for the hero, not for what he is holding.
            local carried = self.studioBack == "timetable"
                and Design.ask
                and design.roster
                and Characters.current.design

            if carried then
                self:toStudio(Design.by[carried], "timetable")
            elseif self.studioBack == "timetable" then
                self:toTimetable()
            else
                self:resumeRun()
            end
        end
        return
    end

    -- Nothing moves, nothing ages and no ink comes back; the only thing running
    -- is the card asking whether to quit.
    if self.state == "paused" then
        local answer, devKind = self.pause:update(dt, self)
        if answer == "quit" then
            Sfx.play("transition2")
            -- A run walked out of is still a run that got this far, and the
            -- timetable is the next thing you will see.
            self:bankRun()
            -- And it is the one route out of a run that does not end it: nothing
            -- here is torn down, so `resumable` stays true and the title screen
            -- offers the run straight back (Game:resumeHeldRun). The bookmark is
            -- written as well, for the launch after this one -- the run in memory
            -- is the better of the two and will be preferred while it lasts, but
            -- this is the moment the player has told us they are done for now.
            Bookmark.save(self)
            self:toMenu()
        elseif answer == "resume" then
            self:togglePause()
        elseif answer == "dev" then
            -- The touch route to what T and W do on a keyboard, and the second
            -- return says which switch was thrown. Thrown in place: the card is
            -- still up afterwards, with the strip behind it longer or shorter
            -- than it was.
            self:toggleDev(devKind)
        end
        return
    end

    -- Held the same way, by the three cards instead. There is no way past them
    -- but to circle one, which is why this state has no button out of it.
    if self.state == "levelup" then
        -- Four answers, and the pair is what says which: a word, and the line it
        -- is about for the two words that name one (src/levelup.lua).
        local act, id = self.draft:update(dt, self)
        if act == "take" then
            self:takeUpgrade(id)
        elseif act == "expel" then
            self:expelLine(id)
        elseif act == "reroll" then
            self:rerollDraft()
        elseif act == "skip" then
            self:skipDraft()
        end
        return
    end

    -- Won: two boxes, and the run underneath is still standing there in case
    -- ENDLESS gives it back.
    if self.state == "won" then
        local answer = self.win:update(dt, self)
        if answer == "end" then
            Sfx.play("transition2")
            -- The other ending, and treated exactly as death is: ENDLESS is the
            -- answer that keeps the run, and this is the one that finishes it --
            -- which is what collects the coins the card has been showing.
            self:cashRun()
            self.resumable = false
            Bookmark.clear()
            self:toMenu()
        elseif answer == "endless" then
            self:beginNextCycle()
        end
        return
    end

    if self.state == "playing" then
        self.time = self.time + dt

        self.player:update(dt, self)

        -- The box has the last word on where the player ended up, exactly as it
        -- does for the horde. After the player has moved rather than inside the
        -- move, so nothing about walking has to know it is there: you walk into
        -- the edge and stop, and the stopping is not a wall you can be pushed
        -- through by anything else that happens this frame.
        if self.arena then
            self.arena:update(dt)
            self.player.x, self.player.y =
                self.arena:clamp(self.player.x, self.player.y, self.player.radius)
        end

        self.spawner:update(dt, self)
        self:updateDrawing(dt)
        self:updateDrops(dt)
        self:updateRulers(dt)
        self:updateCompasses(dt)
        self:updateCuts(dt)
        self:updateBurning(dt)
        self:updateGlue(dt)

        local grid = self:buildGrid()
        self:updateEnemies(dt, grid)
        self:updateRams(grid)
        -- What the run's own fire is worth back to it, which the bandaid takes a
        -- cut of (Loadout:mend). The number is read off the one running total
        -- every hit in the game passes through (Enemy.dealt) either side of the
        -- four passes below, and those four are exactly the run's fire: the
        -- pellets a shot sent and the weapons themselves. Nothing between them
        -- touches the crowd -- the eye's fan and the boss's blots are aimed at
        -- the player -- and everything a *tool* did landed back in updateDrawing,
        -- which is what keeps the ink out of a line that says weapons.
        local fought = Enemy.dealt

        self:updateBullets(dt, grid)
        self:updateEnemyShots(dt)
        self:updatePuddles(dt)
        -- What fights for you while your hands are busy drawing. After the
        -- crowd has moved, so a star cuts and a rocket goes off where things
        -- actually are.
        self.loadout:updateWeapons(dt, self, grid)
        self.loadout:mend(dt, self, Enemy.dealt - fought)
        -- After everything that can hit has hit, so a frame in which a rocket, a
        -- star and the mark underfoot all land on one blob is one number rather
        -- than three.
        self:spendHits()
        self:updateGems(dt)
        self:updatePickups(dt)

        self.noticeT = math.max(0, self.noticeT - dt)

        if self.player.hp <= 0 then
            -- A run carrying a retake does not end here (src/perks.lua): it stops
            -- for a card, gets up and carries on. Asked before anything is banked
            -- or paid, because until this line is answered nobody knows whether
            -- this was an ending at all.
            if self:canRetake() then
                self:openRetake()
            else
                self:openDeath()
            end
        elseif self.pendingWin then
            -- Ahead of the draft, though the eye is worth a level or two on its
            -- own: the win is the bigger event and the levels are banked, so
            -- taking ENDLESS opens them straight afterwards and taking END
            -- never needed them.
            self:openWin()
        elseif self.player.pending > 0 then
            -- Only once the frame is otherwise finished, and never over a run
            -- that has just ended: dying on the level that would have promoted
            -- you is dying.
            self:openDraft()
        end
    elseif self.state == "dead" then
        -- The card, and nothing of the run: the page is where you left it and
        -- the only thing still running on it is the question of what to do next.
        -- The burst you died in goes on falling, since the tail of this function
        -- is outside the branch.
        local answer = self.over:update(dt, self)
        if answer == "retry" then
            Sfx.play("transition2")
            -- The same lesson and the same hero, which are both still set: this
            -- is the next run rather than a way back to the timetable.
            self:reset()
        elseif answer == "quit" then
            Sfx.play("transition2")
            self:toMenu()
        end
    elseif self.state == "retaking" then
        -- A clock and nothing else: the card asks nothing, so the only thing that
        -- can come back from it is that it has been up long enough. Through
        -- Game:resumeRun rather than straight back to playing, since the hit that
        -- would have killed you may well have been the one that levelled you up --
        -- and a level banked on the frame you got back up is a level you get to
        -- spend, where dying on it is dying.
        if self.retake:update(dt) == "done" then self:resumeRun() end
    end

    self.particles:update(dt)
    -- Outside the playing branch with the particles, and for the same reason:
    -- what is already in the air when a run ends should finish falling rather
    -- than freeze on the frame you died.
    self.damage:update(dt)
    self.multikill:update(dt)
    Camera.follow(self.player.x, self.player.y, dt)
    Camera.settle(dt)
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

    if self.state == "timetable" then
        Timetable:draw(self)
        return
    end

    if self.state == "library" then
        Library:draw(self)
        return
    end

    if self.pages[self.state] then
        self.pages[self.state]:draw(self)
        return
    end

    if self.state == "settings" then
        Settings:draw(self)
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
    -- The scissors' finale, and the only thing in the game drawn into the page
    -- rather than onto it: the half of the page a cut has taken off, which is
    -- that page rebaked with the paper between its rules greyed out
    -- (`src/scissors.lua`, `Background.torn`). It has to be here -- a grey half
    -- laid in the ink layer would be a *mark*, and the pass would then pair it
    -- with the page under it, so the grey would come out as some other colour
    -- wherever it crossed a rule and ink laid on top would go on stacking
    -- against the paper it had covered. Nothing a cut leaves is a mark except
    -- its slit, and that goes down with the others.
    for _, c in ipairs(self.cuts) do c:drawSever(left, top, w, h) end
    -- And the same thing with a circle round it: a compass carrying the scissors
    -- (the PUNCH, src/tools.lua) takes a disc off the page instead of a half of
    -- it. Two callers, one page layer, and neither knows about the other -- both
    -- are just spans of rebaked page, so a hole inside a severed half is the same
    -- grey laid twice.
    for _, c in ipairs(self.compasses) do c:drawSever(left, top, w, h) end
    -- And a third caller with the same spans: a ring closed by hand (the CUTOUT,
    -- `loop.lift` in src/tools.lua), which is the offcut's shape drawn rather than
    -- tapped for. Three things now write into the page layer and none of them
    -- knows about the other two, which is what makes them safe to overlap -- a
    -- hole inside a severed half is the same grey laid twice.
    for _, m in ipairs(self.strokes) do
        if m.rings and m.tool.loop.lift then m:drawTorn(left, top, w, h) end
    end
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

    -- The boss's wet trail, over your marks rather than under them. It is the
    -- one thing on the page that is not yours and has to be read before you walk
    -- into it, and a puddle laid under a highlighter band is a puddle you find
    -- out about by losing health.
    -- The box, under the wet and over everything the page is made of. It is a
    -- line drawn on the paper rather than an object standing on it, so it goes
    -- down with the marks and the crowd walks over the top of it -- and a puddle
    -- spreading across the edge should read as being on the same page as it.
    if self.arena then self.arena:draw() end

    for _, p in ipairs(self.puddles) do p:draw() end

    -- And the other half of that: ground a weapon of yours has taken away rather
    -- than ground the boss has -- the bomb's burning crater, which is the boss's
    -- blot in your own colours. It goes down here for the same reason the puddle
    -- does: it is on the page rather than standing on it, so the crowd walks over
    -- the top of it and stays readable while it burns. Everything else a passive
    -- weapon draws comes much later, over the crowd.
    self.loadout:drawGround(self)

    -- A pin's ring and a staple's crease are drawn on the page, so they go under
    -- the crowd -- the things themselves are not, and come later. Same for the
    -- pencil a ruler is aimed with, and the line it leaves behind; and same for
    -- a compass's circle, drawn or still only promised.
    --
    -- A cut is all page and has nothing standing over it, so this is the whole
    -- of what the scissors draw: the slits already made and the blades still
    -- coming down them, and then the cross of an anchor that has not had its
    -- second tap yet. Nothing is dotted out of that cross -- the line is printed
    -- when the second tap lands, and what prints it is the cut coming down it.
    -- The anchor is read off the tool in hand rather than off an object, there
    -- being no object until that tap -- and guarded on the tool still being the
    -- scissors for the same reason the aims are guarded, since the strip can
    -- move while an anchor is down.
    for _, d in ipairs(self.drops) do
        d:drawMark()
        -- And the reach a thread will stretch, round every pin that is still
        -- holding (`thread` in src/tools.lua). The same graphite circle the pin
        -- itself draws while it is falling, one size up -- and it is here rather
        -- than in src/pin.lua for the reason the threading is: how far a mark
        -- reaches is the tool's business and not the drawing's, and a pin has
        -- never had to know what is lying near it.
        --
        -- **This list and not the spent pile**, which is the whole of why it is a
        -- loop here instead of a line inside Pin:drawMark: a thread needs two
        -- posts that are still holding (Game:stringThreads), so a ring round a
        -- pin that has finished holding would be a promise the page cannot keep.
        -- Which makes the ring the range and the clock at once -- it is on the
        -- paper for exactly as long as the pin can still be joined to another --
        -- and that is worth more than either drawing on its own.
        --
        -- Graphite, so it reads as the construction line it is: the palest ink in
        -- the palette, laid under everything standing on the page, going one step
        -- darker over a rule like every other mark (Palette.overprint). No fade
        -- and no dither, because it is not a mark that is leaving -- it goes when
        -- the pin stops being a post, all at once, which is the same frame the
        -- pin stops being one.
        local thread = d.landed and d.tool and d.tool.thread
        if thread then
            love.graphics.setColor(Palette.graphite)
            pixelart.circleOutline(d.x, d.y, thread.reach)
        end
    end
    for _, r in ipairs(self.rulers) do r:drawGuide() end
    for _, c in ipairs(self.compasses) do c:drawGuide() end
    for _, c in ipairs(self.cuts) do c:draw() end
    if self.cutFrom then
        local tool = self.loadout:tool(self.tool)
        if tool and tool.cut then
            Scissors.drawPending(self.cutFrom.x, self.cutFrom.y)
        end
    end

    for _, p in ipairs(self.pickups) do p:draw() end
    for _, g in ipairs(self.gems) do g:draw() end

    -- The page blanked out under the crowd before any of it is drawn
    -- (Overprint.beginSolid). Everything else on this layer is a mark and is
    -- paired with the page beneath it -- that is what makes a pencil line read as
    -- pencil on paper -- but a monster is not printed on the page, it is standing
    -- on it, and a ruled line coming through its body made the horde look like
    -- tracing paper. Blanking first means every character comes out in the
    -- colours it was drawn in, whatever page the run is being played on.
    --
    -- One pair of canvas switches round the whole crowd rather than a pair each,
    -- which is why this is a loop of its own here instead of a line inside the
    -- draw below: where a silhouette lands in the page layer does not depend on
    -- what else is already there, so the order inside the pair is free and the
    -- sort below does not apply to it.
    Overprint.beginSolid()
    for _, e in ipairs(self.enemies) do e:drawSolid() end
    if self.player.hp > 0 then self.player:drawSolid() end
    Overprint.endSolid()

    -- Painter's order, so a monster standing lower on the page overlaps one
    -- standing higher up.
    table.sort(self.enemies, byDepth)
    -- Hung off the hero rather than off which screen is up: he is not drawn
    -- because he is dead, and QUIT from the death card leaves the page he died on
    -- sitting behind the title screen (Game:toMenu).
    local pending = self.player.hp > 0
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
    --
    -- The arm of a run that has drafted one (src/sword.lua) is drawn in here too,
    -- first of them, where it used to be drawn by hand a few lines above this:
    -- it is over the crowd for the pin's reason and one of its own, being the only
    -- thing on the page telling a melee run whether it is standing close enough.
    -- Its order is `WEAPONS` in src/loadout.lua, and it is at the head of that
    -- list so that the blade goes down before the things floating over the page do.
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
    if slapping and self.player.hp > 0 then
        self.player:draw()
    end

    for _, b in ipairs(self.bullets) do b:draw() end
    love.graphics.setColor(1, 1, 1)
    for _, s in ipairs(self.shots) do
        (s.sprite and Sprites[s.sprite] or Sprites.enemyShot)
            :draw(s.x, s.y, nil, s.grow)
    end
    self.particles:draw()
    Camera.detach()

    Overprint.finish()

    -- What the last few hits were worth, over the finished page rather than in
    -- it. A damage number is a readout and not a mark: run it through the
    -- overprint pass and its colours would shift with whatever ruling it happens
    -- to be crossing (src/damage.lua), which is the one thing a readout may not
    -- do. It is still world-space, though -- it belongs to the enemy it came off
    -- and has to scroll with it -- so this is the only thing in the game drawn
    -- under the camera and outside the pass.
    Camera.attach()
    self.damage:draw()
    self.multikill:draw()
    Camera.detach()

    Hud.draw(self)
    if self.state == "paused" then self.pause:draw(self) end
    if self.state == "levelup" then self.draft:draw(self) end
    if self.state == "won" then self.win:draw(self) end
    if self.state == "dead" then self.over:draw(self) end
    if self.state == "retaking" then self.retake:draw(self) end
end

function Game:keypressed(key)
    if self.state == "menu" then
        Menu:keypressed(key)
        return
    end

    if self.state == "timetable" then
        Timetable:keypressed(key)
        return
    end

    if self.state == "library" then
        Library:keypressed(key)
        return
    end

    if self.pages[self.state] then
        self.pages[self.state]:keypressed(key)
        return
    end

    if self.state == "settings" then
        Settings:keypressed(key)
        return
    end

    if self.state == "studio" then
        Studio:keypressed(key)
        return
    end

    -- Ahead of everything, pause included: a level has to be spent before the
    -- run will take another instruction. The win card is the same -- there is
    -- nothing to pause while the question on the page is whether the run goes on
    -- at all.
    if self.state == "levelup" then
        self.draft:keypressed(key)
        return
    end

    if self.state == "won" then
        self.win:keypressed(key)
        return
    end

    -- And the death card, for the same reason: the run is over and the only
    -- instruction it will take is which of the two boxes to fill in.
    if self.state == "dead" then
        self.over:keypressed(key)
        return
    end

    -- And the retake card takes no instruction at all, pause included: it is not a
    -- question, it is a second and a half, and there is nothing to pause because
    -- the run is already held.
    if self.state == "retaking" then return end

    if key == "p" then
        self:togglePause()
        return
    end
    if self.state == "paused" then
        -- The dev toggle's two switches, off the same rows the touch card draws
        -- its boxes from: T lends every tool, W every passive weapon. Behind the
        -- same gesture the card's boxes are (src/dev.lua) -- a key that worked
        -- while the lines saying so were hidden would be a game a stranger could
        -- break by leaning on the keyboard.
        if Dev.showing() then
            for _, row in ipairs(Pause.DEV) do
                if key == row.key then
                    self:toggleDev(row.kind)
                    return
                end
            end
        end
        -- Y and N answer the card, the same as they answer the title screen.
        self.pause:keypressed(key)
        return
    end

    local slot = tonumber(key)
    if slot and slot >= 1 and slot <= #self.loadout.equipped then
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
    -- Held, the wheel turns the one column the wheel can turn there: a lent
    -- weapon column's window. The strip is not offered the wheel while the run
    -- is held, since changing tool is a thing a run does and not a thing a card
    -- does.
    if self.state == "paused" then
        if dy ~= 0 then self:scrollCarry() end
        return
    end
    if self.state ~= "playing" then return end
    if dy ~= 0 then
        self:setTool(self.tool - (dy > 0 and 1 or -1))
    end
end

return Game
