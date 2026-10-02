-- The things you can buy, and what a run does with them.
--
-- Every other permanent thing in the save directory is either a *record* of what
-- happened (src/records.lua), a *thing you drew* (src/design.lua) or a *setting*
-- (src/options.lua). This is the fourth kind, and one of the two things the purse
-- is spent on: coins go in there and come out here, as lines you own a level of for
-- ever and spend a use of every run.
--
-- The other is three of the four heroes (src/characters.lua), which is the counter's
-- other section. The split between them is exactly the sentence below: a level here
-- is a *use*, and a level of a hero is a hero. What the two files have in common is
-- the five questions the canteen asks about a key -- `level`, `levels`, `priceOf`,
-- `canBuy`, `buy` -- and nothing else at all.
--
-- **A level is a use.** That is the whole of the arithmetic and it is deliberately
-- the same sentence twice: buying REROLL to level two means two rerolls in every
-- run from now on, and there is nothing else a level does. Which is what keeps
-- this out of src/upgrades.lua, where a level is written as a function of what it
-- changes and a line can sell four different things down its length -- here every
-- level of every line sells the same thing, one more of it, so the catalogue is
-- three rows of prices and nothing else.
--
-- **Where a use is spent is `spent` on the row**, and there are two answers to it.
-- Three of these are spent on the *draft* (src/levelup.lua) and one on the moment
-- the run would have ended, which is the whole of why the field exists: the draft
-- puts a button up for every line the run is carrying, and a button that pressed
-- would do nothing on that screen is a button that lies about what it is for. So
-- `spent` is read in exactly one place -- the draft's own button row -- and
-- everything else here goes on being a row with a price list on it.
--
-- The three drafts are written to be three different answers to *these three cards
-- are wrong*:
--
-- - **REROLL** asks again. Three more cards off the same catalogue, nothing spent
--   but the use.
-- - **SKIP** withdraws the question and sells the level back for coins
--   (`Purse.PER_SKIP`). The one perk that pays, and the only place in the game a
--   run turns something it earned into something the *book* keeps.
-- - **EXPEL** answers about one card rather than about the three: the line it
--   names is out of the run for good, and a fresh card takes its place. So it is
--   the only one of the three that needs a target, which is why it is the only one
--   that arms rather than acting on the press.
--
-- And the fourth is not about a draft at all:
--
-- - **RETAKE** is spent the frame the run would have ended. The hero gets up on
--   half a page of health with a couple of seconds nothing can touch him for
--   (`Player:revive`), and the run carries on with everything it had learned --
--   which makes it the first thing on this counter that changes how a run is
--   *played* rather than what it is offered. It is nobody's decision to spend, and
--   that is deliberate: a card asking whether to use your last life would be a
--   question with one sensible answer, and this book does not ask those. A run
--   holding one simply does not end yet, and the card that says so
--   (src/retake.lua) is an announcement rather than a question.
--
-- **Prices.** A run that reaches the eye is carrying four or five hundred kills,
-- so it pays two coins, maybe three or four. The rerolls and the expels are priced
-- off that -- a first one is a couple of runs, a full line is a dozen or so -- and
-- the SKIP line is priced off what it *pays* instead, which is the one thing here
-- that had to be argued about. Ten coins a skip is a whole run's kill payout two
-- or three times over, so a skip line priced like the other two would be bought
-- once and never cost anything again; priced at what three skips a run bring in
-- over a handful of runs, buying it is a bet on playing that way rather than a tap
-- that prints money. Move `Purse.PER_SKIP` and these move with it.
--
-- RETAKE is priced off neither, because what it sells is not a better draft but a
-- second run: a first one is most of an afternoon's coins and the second is dearer
-- than the whole reroll line. It is the top shelf of the counter on purpose -- the
-- three cheap lines are things you spend inside a run and this is the run itself,
-- so it should be the thing you are saving up for rather than the thing you pick
-- up on the way past. And it is **two levels rather than three**: the draft lays
-- three cards, which is what made three the natural length of a line spent on one,
-- and a run does not have three deaths in it -- two is already a run played twice
-- over, and a third would be a page nothing on it could close.
--
-- Written in src/purse.lua's shape: plain text in the save directory, a key and
-- one number a line, and a line the game cannot read costs that line its level
-- rather than the file. A perks file nobody can read is a book you have not spent
-- anything out of yet, which is the safe way for it to be wrong.

local Purse = require("src.purse")

local Perks = {}

local FILE = "perks.txt"

-- One row per thing, in the order they are read on the counter, and the order is
-- how far each of them is from answering the question: another deal, no deal, a
-- deal with one card struck off it -- and then the one that is not about the
-- question at all, last, because it is the only thing here you spend on the run
-- rather than on a screen the run has stopped for. Which is also what keeps the
-- number keys meaning what they have always meant.
--
-- `name` and `blurb` are English because English is the key (src/i18n.lua), and
-- the blurb is held to the character blurb's rule -- short, and out of punctuation
-- the 3x5 face does not have.
Perks.list = {
    {
        key = "reroll", name = "REROLL", icon = "reroll", spent = "draft",
        blurb = "THREE NEW CARDS",
        price = { 5, 12, 22 },
    },
    {
        key = "skip", name = "SKIP", icon = "skip", spent = "draft",
        blurb = "SELL THE LEVEL BACK",
        price = { 12, 30, 60 },
    },
    {
        key = "expel", name = "EXPEL", icon = "expel", spent = "draft",
        blurb = "ONE LINE OUT OF THE RUN",
        price = { 8, 18, 34 },
    },
    {
        key = "retake", name = "RETAKE", icon = "retake", spent = "death",
        blurb = "BACK UP ON HALF HEALTH",
        price = { 20, 45 },
    },
}

Perks.byKey = {}
for _, row in ipairs(Perks.list) do Perks.byKey[row.key] = row end

-- What has been bought, by key. Loaded once in `Game:load` and written the moment
-- it changes, since the only thing that changes it is a purchase.
Perks.owned = {}

function Perks.level(key)
    return Perks.owned[key] or 0
end

-- How long a line is, which is how many uses a run can end up with. Read through
-- here rather than off `price`, so the day one of the three is longer than the
-- others nothing has to be told.
function Perks.levels(key)
    local row = Perks.byKey[key]
    return row and #row.price or 0
end

-- What the next level of a line costs, or nil for a line with nothing left to
-- sell. One door, so nothing anywhere indexes `price` itself and no screen has to
-- know what happens at the end of a row.
function Perks.priceOf(key)
    local row = Perks.byKey[key]
    if not row then return nil end
    return row.price[Perks.level(key) + 1]
end

-- Whether the counter can sell you the next one: there is one, and you have the
-- coins for it. Both halves in one question, because a row that cannot be bought
-- reads the same either way -- the box is not drawn and the price says why.
function Perks.canBuy(key)
    local price = Perks.priceOf(key)
    return price ~= nil and Purse.total >= price
end

-- Bought. The purse refuses rather than clamping (`Purse.spend`), so the level
-- only goes up if the coins actually came out -- which is what makes this safe to
-- call from a screen that measured the price a frame ago.
function Perks.buy(key)
    local price = Perks.priceOf(key)
    if not price or not Purse.spend(price) then return false end

    Perks.owned[key] = Perks.level(key) + 1
    Perks.save()
    return true
end

-- What one run is handed: a fresh count of uses per line, keyed the way the rows
-- are, and only for the lines that have been bought at all. A line nobody owns is
-- absent rather than zero, which is what keeps a run that has bought nothing from
-- drawing grey buttons on every draft -- these are things you have, and the draft
-- only has a corner in it once there is something to put there.
--
-- The lines spent somewhere other than the draft are in here on the same terms:
-- what a run is carrying is one table whatever any of it is for, and `spent` is
-- only asked about by the screen that would draw a button for it.
function Perks.forRun()
    local uses = {}
    for _, row in ipairs(Perks.list) do
        local level = Perks.level(row.key)
        if level > 0 then uses[row.key] = level end
    end
    return uses
end

function Perks.save()
    local out = {}
    for _, row in ipairs(Perks.list) do
        local level = Perks.level(row.key)
        if level > 0 then
            out[#out + 1] = ("%s %d"):format(row.key, level)
        end
    end
    love.filesystem.write(FILE, table.concat(out, "\n"))
end

-- No file at all is a book nothing has been bought out of yet. A line naming a
-- row this version no longer has is dropped, and a level past the end of a row is
-- clamped to it -- the same leniency src/bookmark.lua reads a saved level with,
-- and for the same reason: this is a file a later version can disagree with, and
-- no disagreement may cost more than the line it is about.
function Perks.load()
    Perks.owned = {}

    local text = love.filesystem.read(FILE)
    if not text then return end

    for line in text:gmatch("[^\r\n]+") do
        local key, value = line:match("^(%S+)%s+(%d+)$")
        local row = key and Perks.byKey[key]
        if row then
            Perks.owned[key] = math.min(math.floor(tonumber(value)),
                Perks.levels(key))
        end
    end
end

return Perks
