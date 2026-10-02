-- The purse: the one thing a run pays out that the next run still has.
--
-- Everything else a run leaves behind is a *record* of it (src/records.lua) --
-- the longest run and the biggest body count, one line per lesson, a maximum a
-- bad run cannot take away. This is the other kind of thing entirely: it is
-- earned, it adds up, and it is going to be spent. So it is not kept against a
-- lesson at all -- there is one purse and the whole book shares it, because what
-- it is being saved up for is in the canteen and the canteen does not care which
-- page you were on.
--
-- **What a run is worth is one function and this is it**, and it is four terms
-- at a rate rather than one number because a run comes back with four different
-- kinds of fact about itself and one about the terms it did them under. Every screen that shows the number asks here for it, exactly as
-- both end cards ask src/mark.lua for the grade, and none of them knows what is
-- in the sum -- which is what let the last two terms be added without a line
-- changing in src/win.lua, src/over.lua or the canteen.
--
-- - **The body count**, over a hundred and floored. The effort term, and the floor
--   is the point of it: a run that killed ninety-nine is worth nothing, which is
--   what makes the hundredth kill worth something.
-- - **The levels sold back** (`SKIP` in the draft, src/perks.lua), ten a piece.
--   The one term a run *chooses*, and the only place in the game where something
--   a run earned is turned into something the book keeps.
-- - **The grade**, a coin a rung. The term that pays for having lasted rather
--   than for having killed -- the ladder is the run's length divided into
--   thirteen (src/mark.lua), so this is a coin every forty-six seconds and
--   nothing else, and a run that spent ten minutes hiding behind pen lines
--   finally comes back with something. It arrives as the *rung* rather than as
--   the letter, and the caller reads src/mark.lua for it -- which is where the
--   cap that stops an endless run farming it lives, and is also what keeps this
--   file out of a require loop: a course reaches the purse, and src/mark.lua
--   reads the spawner's own clock.
-- - **The eye**, eight a piece. The cliff. The three terms above it all climb
--   smoothly, so without this the last ten seconds of a ten-minute run -- the only
--   part of it that is a *fight* rather than a crowd -- would be worth no more than
--   any other ten. It is per eye rather than a bonus for winning, so ENDLESS goes
--   on paying for the thing it is a bet on.
--
-- And then the whole sum is multiplied by the **course** it was sat at
-- (src/course.lua), which is the one term here that is not a fact the run
-- counted. It is a multiplier rather than a fifth term for the reason a course is
-- one dial rather than five: what a harder class is worth is *everything you did*
-- reckoned at a higher rate, and a flat bonus for enrolling would pay a doctorate
-- for walking onto the page. Three times at the top of the ladder, which is what
-- makes the ladder a bargain rather than a badge -- a doctorate pays for the
-- perks that make a doctorate survivable.
--
-- Which is roughly five times what a run used to come back with, and that is
-- deliberate rather than drift: the counter it is spent over (src/perks.lua) is
-- four cheap lines today and is going to grow rows that lock parts of the book
-- behind them, so the faucet was opened for what is coming rather than for what is
-- there. The four prices already on it are untouched and are now the near end of
-- it -- a first reroll is a middling run rather than two good ones.
--
-- Coins go out one way and come in two: a run ending, and the counter's third
-- section handing back everything bought on it (src/refund.lua). The second is
-- not really a *source* -- it is a purchase read backwards, and every coin it
-- pays came in through the first one on some earlier afternoon.
--
-- **A run is paid out when it ends, and only then.** The two endings are dying
-- and `END` on the win card, which is the same pair that turns `Game.resumable`
-- off, and `Game:cashRun` is the one door. Walking out through the pause card
-- deliberately pays nothing -- it does not end a run, it leaves one, and the run
-- it left is still there to be finished properly. That is also why nothing here
-- has to remember what it has already paid for: ENDLESS is not an ending either,
-- so a run that shuts the eye at four hundred kills and dies at nine hundred is
-- paid once, for nine.
--
-- The file is written the way a record, a design and the options are: plain text
-- in the save directory, a key and one number, and a line the game cannot read is
-- a purse that opens empty rather than a game that will not start.

local Font = require("src.font")
local Scribble = require("src.scribble")
local Sprites = require("src.sprites")

local Purse = {}

local FILE = "purse.txt"

-- How many of them a coin is worth. A hundred is a couple of coins out of a run
-- that reaches the eye, which is meant to be the shape of it: a coin is a thing
-- you save up, not change handed back at the end of every page.
Purse.PER_COIN = 100

-- What one skipped level is sold back for. Ten is two or three times the kill
-- payout of a run that reaches the eye, which is deliberate and is why the canteen
-- prices the SKIP line the way it does (src/perks.lua): the only perk that *earns*
-- is the only one priced against what it earns, so buying it is a bet that pays off
-- over a handful of runs rather than a tap that prints money on the first one. Move
-- this and move those prices with it.
Purse.PER_SKIP = 10

-- What one rung of the grade ladder is worth (src/mark.lua). One, so the whole
-- ladder is twelve -- three times the kills of a run that reaches the eye, which
-- is the right way round: the page is paying for the ten minutes rather than for
-- what happened during them, and what happened during them is the term above.
Purse.PER_GRADE = 1

-- And one eye. Eight is deliberately most of a grade ladder for the last ten
-- seconds of a run: everything else here is smooth in the clock, so this is the
-- one term that says the fight at the end was a different thing from the crowd
-- before it. It is also two thirds of a first RETAKE, which is the shape the
-- counter wants -- shut the eye once and a second life is nearly in reach.
Purse.PER_EYE = 8

-- What is in the purse. Loaded once at startup (`Game:load`) and written the
-- moment it changes, since the only thing that changes it is a run ending and a
-- run ends once.
Purse.total = 0

-- The one place the sum lives. Floored rather than rounded -- a coin is a whole
-- thing and a page cannot be handed three quarters of one.
--
-- One table rather than a row of arguments, and that is the whole of how a term
-- gets added without anything being told: the run is handed over as what it is
-- (`Game:runWorth` is the one place it is built) and a term nobody filled in is
-- worth nothing. A missing rung is the bottom of the ladder for the same reason,
-- and a missing course is high school -- which pays at one, so a caller that has
-- never heard of the ladder gets the sum this function always gave.
--
-- Floored at the end rather than on the kills, which is where it used to be. The
-- reason is the course: every term above was already whole coins, so the only
-- fraction in here was the body count -- and a rate of 1.4 makes a fraction of
-- all four of them. A coin is still a whole thing and a page still cannot be
-- handed three quarters of one; there is simply one place now where that is
-- settled instead of one term that needed it.
function Purse.forRun(run)
    run = run or {}
    local coins = math.floor((run.kills or 0) / Purse.PER_COIN)
        + (run.skips or 0) * Purse.PER_SKIP
        + (run.rung or 0) * Purse.PER_GRADE
        + (run.eyes or 0) * Purse.PER_EYE
    return math.floor(coins * (run.pay or 1))
end

function Purse.save()
    love.filesystem.write(FILE, ("coins %d"):format(math.floor(Purse.total)))
end

-- No file at all is a first run rather than an error, and so is a line that has
-- been edited into something unreadable: either way the purse is empty and
-- nothing is written until something is actually earned.
function Purse.load()
    Purse.total = 0

    local text = love.filesystem.read(FILE)
    if not text then return end

    local coins = tonumber(text:match("^coins%s+(%d+)"))
    if coins then Purse.total = math.floor(coins) end
end

-- Banked, and written on the spot. A run worth nothing writes nothing: there is
-- no difference on disk between a purse that has not changed and one that has
-- had zero added to it, and a file write is worth spending on a change.
--
-- Two things come in through here now: what a run was worth, and what the counter
-- hands back when everything bought on it is returned (src/refund.lua). One door
-- rather than two, because a coin is a coin however it arrived -- this file has
-- never known what it was being paid for and does not start now.
function Purse.earn(n)
    n = n or 0
    if n <= 0 then return 0 end

    Purse.total = Purse.total + n
    Purse.save()
    return n
end

-- The other way coins move, and the only one: the canteen buying a perk
-- (src/perks.lua). It refuses rather than clamps, and refusing is the whole of
-- what makes it safe to call -- a purse cannot be talked into going negative by a
-- screen that measured the price wrong, and the caller finds out by being told no
-- rather than by reading the total back.
--
-- Written the moment it changes, like `earn`, and for the same reason: coins are
-- the one thing in the book that adds up, so the file has to agree with the number
-- on the page before anything else can happen to either.
function Purse.spend(n)
    n = math.floor(n or 0)
    if n <= 0 or n > Purse.total then return false end

    Purse.total = Purse.total - n
    Purse.save()
    return true
end

--- drawing -------------------------------------------------------------------

-- The coin and a number, drawn as one thing, because that is what they are: the
-- glyph says which currency and the figure says how much of it, and neither is
-- worth reading on its own. Three screens show one -- the two cards a run ends on
-- and the canteen -- so it is written here once rather than three times, the way
-- src/mark.lua owns how a grade is drawn.
--
-- The text is passed in rather than built from a number, since the same pair says
-- two different things: what this run just earned (`+3`) and what the purse holds
-- (`3`).

local GAP = 3  -- the coin to the figure beside it, which is the library's gap
               -- from an icon to the name of the thing: a pixel less and the
               -- coin's rim touches the figure, a pixel more and the pair reads
               -- as two things rather than a price

-- The pair is one drawing and `scale` blows all of it up, coin and gap included,
-- rather than standing a 1:1 coin next to a doubled figure -- which was drawn and
-- read as a bullet point in front of a number. It is the hero's own trick and the
-- one the 3x5 face is scaled by (`Scribble.printBig`): an integer
-- `love.graphics.scale` with the sprite drawn unchanged inside it, so every
-- coordinate stays whole and nothing is resampled.
function Purse.width(text, scale)
    scale = scale or 1
    return (Sprites.icons.coin.w + GAP) * scale + Font.width(text) * scale
end

function Purse.height(scale)
    scale = scale or 1
    return math.max(Sprites.icons.coin.h, Font.height) * scale
end

-- Centred on `cx` as a pair, with the shorter of the two sitting in the middle of
-- the taller. Which is always the same way round -- the coin is nine deep and the
-- face is five -- so what this really says is that the figure rides level with the
-- middle of the coin, the way a price is set beside a symbol.
function Purse.draw(text, cx, y, color, scale)
    scale = scale or 1

    local coin = Sprites.icons.coin
    local h = Purse.height(scale)
    local x = math.floor(cx - Purse.width(text, scale) / 2)

    love.graphics.setColor(1, 1, 1)
    love.graphics.push()
    love.graphics.translate(x, y + math.floor((h - coin.h * scale) / 2))
    love.graphics.scale(scale, scale)
    coin:draw(coin.ox, coin.oy)
    love.graphics.pop()

    Scribble.printBig(text,
        x + (coin.w + GAP) * scale + Font.width(text) * scale / 2,
        y + math.floor((h - Font.height * scale) / 2), scale, color, { seed = 71 })
end

return Purse
