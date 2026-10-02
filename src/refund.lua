-- The way back off the canteen counter: one row that hands back everything ever
-- bought (src/perks.lua, src/characters.lua, src/course.lua) at what was paid, no
-- fee. All of it or none. A refund must never lose an unlock or a run's uses.

local Purse = require("src.purse")
local Perks = require("src.perks")
local Characters = require("src.characters")
local Course = require("src.course")

local Refund = {}

-- The counter's row is `{ key = Refund.KEY, shop = Refund }` like any other.
Refund.KEY = "all"

-- Every priced line on the counter as (levels owned, price table), so a section
-- that grows a row is refunded without a word being said here.
local function each(fn)
    for _, row in ipairs(Perks.list) do
        fn(Perks.level(row.key), row.price)
    end
    for _, char in ipairs(Characters.list) do
        if char.price then fn(Characters.level(char.key), char.price) end
    end
    -- One call: the ladder is one line with three levels (src/course.lua).
    fn(Course.level(), Course.price)
end

-- What was actually paid, level by level, so a price list that changes between
-- versions refunds at today's prices.
function Refund.worth()
    local coins = 0
    each(function(level, price)
        for i = 1, level do coins = coins + (price[i] or 0) end
    end)
    return coins
end

-- The largest refund possible, the whole counter bought; the canteen asks only to
-- reserve room for the figure.
function Refund.most()
    local coins = 0
    each(function(_, price)
        for _, p in ipairs(price) do coins = coins + p end
    end)
    return coins
end

--- the counter ---------------------------------------------------------------

-- The five questions the canteen asks of a row (src/canteen.lua), answered about
-- the counter as a whole, so it goes red when full as a maxed perk line does.
function Refund.level()
    local levels = 0
    each(function(level) levels = levels + level end)
    return levels
end

function Refund.levels()
    local most = 0
    each(function(_, price) most = most + #price end)
    return most
end

-- What comes back rather than what is asked for; the canteen draws it with the
-- payout sign. Nought rather than nil, since this row always has an offer.
function Refund.priceOf()
    return Refund.worth()
end

-- No coins needed, so the only way this row is shut is an empty book.
function Refund.canBuy()
    return Refund.worth() > 0
end

-- Everything back. The purse is credited last, after both registers are emptied
-- and written, so a book that died mid-write loses coins rather than being paid.
function Refund.buy()
    local coins = Refund.worth()
    if coins <= 0 then return false end

    Perks.owned = {}
    Perks.save()

    for _, char in ipairs(Characters.list) do
        if char.price then Characters.bought[char.key] = nil end
    end
    Characters.saveRoster()
    -- `Characters.pick` clamps to the roster, so the book cannot walk onto the
    -- page as a hero it no longer owns.
    Characters.pick(Characters.current.key)

    -- Same clamp for the ladder, and it bites harder: a book refunded while sat
    -- at a doctorate would otherwise go on playing one, at a doctorate's payout.
    Course.open = 0
    Course.pick(Course.current.key)

    Purse.earn(coins)
    return true
end

return Refund
