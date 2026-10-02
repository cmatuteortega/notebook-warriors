-- Which hero the run is played as.
--
-- A subject is a page and a tool (src/subjects.lua); a character is the other
-- half of that question, and it is asked on the board rather than on the
-- timetable because it is a question about the drawing. The stick man you draw
-- is *who* you play; this is *what he opens the run holding*, and the two are
-- picked in the same breath -- the arrows under the boxes in the studio
-- (src/studio.lua), stepped rather than scribbled for, because choosing which
-- kind of hero to look at is no more a question than choosing which tab of the
-- timetable to look at is.
--
-- There are four, and each one is a different opening question about where the
-- fight happens. The shootman picks things off a third of the page away and the
-- swordsman has to be inside the crowd -- opposite halves of one idea, and the two
-- the game was built on. The starman opens with nothing that shoots at all: a star
-- turning round him, so what he has is a ring rather than a reach. The skateman
-- opens with a surface -- a trail that cuts whatever follows him down it -- so
-- what he has is only ever the ground he has just left, and standing still is the
-- one thing he cannot do.
--
-- None of them is a stat block dressed up. What changes is where you have to
-- stand, which is the only thing in this game a character could change and still
-- be the same run.
--
-- **One of the four is the book's and the other three are bought.** The swordsman
-- is the hero every book opens with -- the plainest of them, standing inside the
-- crowd with a sword, which is the run this game was written around -- and the
-- other three are rows on the canteen's counter (src/canteen.lua) at the same
-- price apiece. The same price on purpose: the roster is not a ladder. Not one of
-- these three is stronger than the others, so a price rising down the column would
-- be the counter saying the last one is the best one, which is the one thing four
-- openings are written *not* to be.
--
-- And a hero bought is not his weapon bought. A run is still handed whatever line
-- its character carries, whatever the book has opened (`issue` in
-- src/loadout.lua) -- but carrying it as somebody *else* waits until five minutes
-- have been survived as the hero it belongs to (src/collection.lua). That is the
-- lesson tool's own bargain: the pencil is a science tool until science has been
-- sat through, and the star is the starman's until the starman has lasted half a
-- lesson holding it. So a purchase opens a hero and the hero opens his weapon,
-- which is what keeps the counter from being three fresh cards sold for coins.
--
-- **A character is one line of the catalogue, issued.** It used to be three
-- numbers -- a reach, a damage multiplier and a beat -- read straight off this
-- row by src/player.lua, which meant the hands-free attack was something a hero
-- *was* rather than something a run *had*. Both attacks are passive weapon lines
-- now (SHOT and SWORD in src/upgrades.lua, flown by src/shot.lua and
-- src/sword.lua), those three numbers are on their blocks, and all that is left
-- here is which line the run is handed on the way in -- taken to level one by
-- Loadout.new, spending a weapon slot exactly as a drafted one would.
--
-- What falls out of that is the point of having done it: any hero can draft any
-- weapon, so the character is where a run *starts* rather than a wall around what
-- it can become. The two that open without a hands-free attack say it loudest --
-- a starman who drafts SHOT has spent a card on the thing a shootman was handed.
--
-- What a character still does not touch is deliberate. Speed, health, the ink
-- meter, the tool the lesson issues and every upgrade line are the same for all
-- four, so a build learned as one is a build that reads as the next.
--
-- **Two files, and two different kinds of fact.** `character.txt` is one line --
-- which hero was last picked -- and it is a setting: read back on the next launch,
-- and a key the game does not recognise, or one this book has not bought, is
-- ignored rather than trusted. `roster.txt` is the register beside it, one line per
-- hero the book has anything to say about: whether it has been paid for, and how
-- long the longest run as it lasted. Both of those are things that only ever go up
-- -- nothing takes a hero away and a best is a maximum, src/records.lua's rule --
-- so, as everywhere else here, a line edited into something unreadable costs that
-- hero what it says and nothing else.

local Purse = require("src.purse")
local Upgrades = require("src.upgrades")
local Dev = require("src.dev")

local Characters = {}

-- Which hero was last picked, and what the book has of the roster: see the header.
local FILE = "character.txt"
local ROSTER = "roster.txt"

-- The hero the book comes with, and so the one row on the list with no price on
-- it. Everything that cannot answer *which* hero it means falls back here.
local BASE = "swordsman"

--   key     what is written in the save file, and what the hero board drawn for
--           this character is kept under (`hero-<key>.txt`, src/design.lua)
--   was     a key this character used to be filed under, if it has been renamed:
--           the hero board falls back to that file while the new one does not
--           exist, so renaming a character does not take somebody's drawing away
--   name    what the studio's selector calls it
--   blurb   the one line under the arrows saying how it fights. Kept inside 24
--           characters, which is what the studio's column is already as wide as
--           (its longest hint), so a character costs that screen no width. Caps,
--           digits and a full stop only: the 3x5 face has no comma, and a glyph
--           it does not have comes out as a space (src/font.lua)
--   weapon  the id of the weapon line in src/upgrades.lua the run opens holding,
--           at level one. This is the whole of how the heroes fight differently:
--           where you have to stand, how hard it lands and how often are all
--           numbers on that line's block, so they are read once, by the weapon,
--           and a hero who later drafts another line flies it exactly as the hero
--           it came from does
--   price   what the canteen charges for this hero, written as a list of one so
--           that a row of the roster and a row of src/perks.lua answer the same
--           five questions about a price. Absent on the one hero the book comes
--           with, which is also how the counter knows not to put it on the page
--   icon    not written here: filled in below off the weapon line, since a hero's
--           icon on the counter is the icon of the thing he fights with
--   design  what this character *also* has to be drawn, by name in
--           src/design.lua: the hero's board hands straight on to it. Every row
--           has one and it is the same drawing the weapon line names, which is
--           what makes the handoff worth having -- you draw what you fight with
--           on the way in rather than being sent to the board by a card for
--           something you already had

-- What a hero costs, and it is one number for all three of them.
--
-- A run that reaches the eye pays about two dozen coins (src/purse.lua), so this is
-- a couple of good afternoons apiece and all three are most of a week -- dearer
-- than the whole reroll line and about a retake and a half, which is where a hero
-- belongs: the perks are things you spend inside a run and this is the run itself
-- turning up as somebody else.
--
-- One number rather than three because none of the three is better than the others
-- (see the header). If a fourth is ever added that genuinely asks more of you than
-- the rest, it wants a sentence here saying so rather than quietly costing more.
local PRICE = 40

Characters.list = {
    {
        key = "shootman",
        -- He was `shooter` until the roster grew and the names went to one shape.
        -- The board he was drawn on is still called that on disk until the next
        -- `OK!` writes the new file (src/design.lua).
        was = "shooter",
        name = "SHOOTMAN",
        blurb = "SHOOTS WHAT IS NEAREST",
        price = { PRICE },
        weapon = "shot",
        design = "bullet",
    },
    {
        key = "swordsman",
        name = "SWORDSMAN",
        blurb = "DOUBLE DAMAGE UP CLOSE",
        weapon = "sword",
        design = "sword",
    },
    {
        -- The first hero who opens with no hands-free attack at all. A star is a
        -- ring you carry rather than a reach you point, so what he decides is
        -- what he lets close rather than what he picks off -- and unlike SHOT
        -- and SWORD his line has four more levels in it, so the weapon he starts
        -- with is also one the draft can go on selling him.
        key = "starman",
        name = "STARMAN",
        blurb = "A STAR ORBITS HIM",
        price = { PRICE },
        weapon = "star",
        design = "star",
    },
    {
        -- And the one whose weapon is the ground. A trail only exists behind
        -- somebody who is moving, so this is the one hero who cannot stand still
        -- and fight -- what he leaves is the attack, which is the plainest
        -- version of "a character is where you have to stand" the roster has.
        key = "skateman",
        name = "SKATEMAN",
        blurb = "CUTS WHAT FOLLOWS HIM",
        price = { PRICE },
        weapon = "skate",
        design = "skate",
    },
}

Characters.byKey = {}
for _, char in ipairs(Characters.list) do
    Characters.byKey[char.key] = char

    -- Read off the weapon rather than written on the row: a hero's icon on the
    -- counter is the icon of the thing he fights with, and one written here would
    -- be a second place for it to be wrong. The assert is the one
    -- src/collection.lua makes of a gate, for the same reason -- a row naming a
    -- line the catalogue does not have is a typo the game would otherwise carry all
    -- the way to the first run built out of it.
    local line = assert(Upgrades.byId[char.weapon],
        "character carries an unknown weapon line: " .. char.weapon)
    char.icon = line.icon
end

-- The hero the book comes with. `default` is that row rather than the first of the
-- list, since the first of the list is one you have to buy: everything that cannot
-- answer which hero it means lands here, and what it lands on has to be a hero
-- every save has.
Characters.base = assert(Characters.byKey[BASE], "no base character: " .. BASE)
Characters.default = Characters.base

-- Whoever is picked. A row rather than a key, because everything that asks wants
-- something off it -- Game:reset reads the weapon it is handed, the studio prints
-- its name and the board hands on to its design.
Characters.current = Characters.default

-- What the roster file holds: which heroes have been paid for, and how long the
-- longest run as each of them lasted. The second is a maximum on src/records.lua's
-- terms, and it is kept here rather than in the register because the register keeps
-- one line per *lesson* -- this is a fact about a hero, true of him on every page
-- of the book.
Characters.bought = {}
Characters.times = {}

function Characters.get(key)
    -- A key the book no longer has -- a hero renamed between versions -- lands on
    -- the base rather than on the row that used to be called that, which is the
    -- answer this wants now anyway: a hero you have not bought is not one an old
    -- file gets to hand you. `was` is still what the *drawing* follows
    -- (src/design.lua), so a rename costs nobody a board.
    return Characters.byKey[key] or Characters.default
end

function Characters.index(char)
    for i, row in ipairs(Characters.list) do
        if row == char then return i end
    end
    return 1
end

--- who the book has ----------------------------------------------------------

-- Whether this hero is in the book at all: the base always is, without ever having
-- been paid for, and the other three are once they have been.
--
-- The one door, which is what lets the dev switch (src/dev.lua) stand in front of
-- the roster the way it stands in front of the catalogue: a book with every hero
-- on the board, or with only the one it came with, without a coin moving either
-- way. The base is outside it -- a book with nobody to play is not a state worth
-- being able to look at.
function Characters.owns(key)
    if key == Characters.base.key then return true end
    return Dev.opened(Characters.bought[key] == true)
end

-- How many there are to step between, which is the one thing the studio's arrows
-- have to know: two arrows on a roster of one are two buttons lying about what they
-- do, so there they are drawn grey and step nothing (src/studio.lua).
function Characters.count()
    local n = 0
    for _, char in ipairs(Characters.list) do
        if Characters.owns(char.key) then n = n + 1 end
    end
    return n
end

--- the counter ---------------------------------------------------------------

-- The five questions the canteen asks about a row (src/canteen.lua), answered here
-- exactly as src/perks.lua answers them about a perk. That is the whole of what
-- those two files have in common and it is deliberately all of it: the counter
-- holds a list of rows and a `shop` to ask about each one, so a hero and a reroll
-- are the same transaction as far as that screen goes -- a name, a price and a box.
--
-- What is *behind* them is the difference the note under the counter says out loud.
-- A perk's level is a use a run spends; a hero's is a hero, bought once and yours
-- for good. Which is why a price is a list of one: there is no second level of
-- being in the roster.
function Characters.level(key)
    return Characters.bought[key] and 1 or 0
end

function Characters.levels(key)
    local char = Characters.byKey[key]
    return char and char.price and #char.price or 0
end

function Characters.priceOf(key)
    local char = Characters.byKey[key]
    if not char or not char.price then return nil end
    return char.price[Characters.level(key) + 1]
end

function Characters.canBuy(key)
    local price = Characters.priceOf(key)
    return price ~= nil and Purse.total >= price
end

-- Bought, and the purse is what refuses (`Purse.spend` never clamps), so a hero
-- only arrives if the coins actually came out -- which is what makes this safe to
-- call from a screen that measured the price a frame ago.
function Characters.buy(key)
    local price = Characters.priceOf(key)
    if not price or not Purse.spend(price) then return false end

    Characters.bought[key] = true
    Characters.saveRoster()
    return true
end

--- what each hero has done ---------------------------------------------------

-- How long the longest run as this hero lasted, which is the whole of what the
-- collection asks about one (src/collection.lua): five minutes as him is what takes
-- the weapon he carries out of his own hands and puts it in everybody else's draft.
function Characters.best(key)
    return Characters.times[key] or 0
end

-- Banked by Game:bankRun, beside the lesson's record and on the same terms: a
-- maximum, submitted from every route out of a run, so submitting it twice cannot
-- be worth anything and a bad run cannot take an unlock away.
function Characters.submit(key, time)
    if not Characters.byKey[key] then return false end
    if time <= Characters.best(key) then return false end

    Characters.times[key] = time
    Characters.saveRoster()
    return true
end

--- the pick ------------------------------------------------------------------

-- Whoever is picked, clamped to what this book actually has: a key naming a hero
-- nobody paid for -- a bookmark from a save that had him, a hand-edited file, a
-- hero who was free in an older version of the game -- lands on the base instead.
-- One door, so nothing else has to remember to ask.
function Characters.pick(key)
    local char = Characters.get(key)
    if not Characters.owns(char.key) then char = Characters.base end

    Characters.current = char
    love.filesystem.write(FILE, char.key)
    return Characters.current
end

-- One step along the roster, wrapping, and **over whatever has not been bought**.
-- The arrows step between the heroes you have rather than showing you the ones you
-- do not: the counter is where a hero is named and priced, and a board you could
-- draw on but not play would be the studio offering something it cannot hand over.
--
-- `dir` is -1 or 1. Saved on the step rather than when the board is handed over:
-- the arrows are pressed and not answered, so there is no later moment to save at
-- -- and a character stepped to and then walked away from is still the one you last
-- chose to look at. A roster of one does not move, and says so by handing back the
-- hero it was already on.
function Characters.step(dir)
    local n = #Characters.list
    local i = Characters.index(Characters.current)

    for _ = 1, n - 1 do
        i = (i - 1 + dir) % n + 1
        local char = Characters.list[i]
        if Characters.owns(char.key) then return Characters.pick(char.key) end
    end
    return Characters.current
end

--- the files -----------------------------------------------------------------

-- One line per hero the book has anything to say about: the key, whether it has
-- been paid for, and the longest run as it. Two facts on one line because they are
-- two facts about the same hero and neither can go down -- and written in
-- src/records.lua's shape, so the time is optional on the way in and a line the
-- game cannot read costs that hero what it says and nothing else.
--
-- A hero with neither is not written at all, which is what a fresh book looks like:
-- no file, nothing bought, nothing played.
function Characters.saveRoster()
    local out = {}
    for _, char in ipairs(Characters.list) do
        local bought = Characters.bought[char.key] and 1 or 0
        local time = Characters.times[char.key]
        if bought == 1 or time then
            out[#out + 1] = ("%s %d %.1f"):format(char.key, bought, time or 0)
        end
    end
    love.filesystem.write(ROSTER, table.concat(out, "\n"))
end

-- The roster first and the pick second, because a pick is clamped to what the
-- roster says.
--
-- Not through `pick`: a launch that read the file should not write it back.
function Characters.load()
    Characters.bought = {}
    Characters.times = {}

    local roster = love.filesystem.read(ROSTER)
    if roster then
        for line in roster:gmatch("[^\r\n]+") do
            local key, bought, time = line:match("^(%S+)%s+(%d+)%s*([%d%.]*)$")
            if key and bought and Characters.byKey[key] then
                Characters.bought[key] = tonumber(bought) == 1
                Characters.times[key] = tonumber(time) or 0
            end
        end
    end

    local text = love.filesystem.read(FILE)
    local key = text and text:match("^%s*(%S+)")
    local char = key and Characters.get(key) or Characters.default
    Characters.current = Characters.owns(char.key) and char or Characters.base
end

return Characters
