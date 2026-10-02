-- The mark: what the run gets written on it in red when it is over.
--
-- Every other readout in this game is a number -- the clock, the kills, the
-- level -- and a number is something you compare with the last one. A mark is
-- something you are *given*, which is the whole reason it is here: this is a
-- book of school pages, and what a school page comes back with on it is a
-- letter in red pen at the top. So the card a run ends on says how it went twice
-- over, once in the numbers the run itself was keeping and once in the one
-- character a teacher would have written.
--
-- **The ladder is thirteen steps and the run length picks one, linearly.** F for
-- dying on the way in, A+ for the ten minutes it takes to reach the eye
-- (`Spawner.BOSS_AT`), and the eleven between them share the time out evenly --
-- about forty-six seconds a grade. Winning is an A+ outright and does not go
-- through the clock at all, though a run that got that far would have earned one
-- anyway: the win is the mark being awarded rather than measured.
--
-- Which means, today, that dying with the eye on the page marks the same as
-- beating it. That is deliberate and it is temporary -- the length of the run is
-- the only thing the mark reads, and the whole point of putting it behind one
-- function is that the things it *should* read (the body count, the level, the
-- lesson, whether the eye went down) can be folded in here without any screen
-- knowing that the sum changed. `Mark.forRun` is the only door.
--
-- **The grade is now paid for as well as printed.** A rung of this ladder is a
-- coin (`Purse.PER_GRADE`, src/purse.lua), which is what makes it the one term of
-- a run's payout that is about having *lasted* rather than about having killed --
-- so a run spent hiding behind pen lines finally comes back with something. It
-- also means the ladder is a price list, and `Mark.rung` is the one door to that:
-- a step added in the middle is a step every grade above it is re-priced by.
--
-- **A third screen reads it, and it is not a card.** The timetable's panel prints
-- the best mark a lesson has come back with (src/timetable.lua), and it gets it
-- from `Mark.forRun` asked about the register's best run rather than from anything
-- filed: the mark is a function of how far a run got, so a maximum in the register
-- is a maximum on the ladder, and no grade is ever written to disk. It draws the
-- letter itself in the 3x5 face, because there it is the value of a stat row and
-- not a thing written on the page -- everything below about the bold face is about
-- the two cards.
--
-- It is drawn in the bold face (`Font.bold`) rather than the 3x5 one every other
-- word in the game is written in, and that is the point of it too: a mark is not
-- a line of copy, it is a thing written on the page, so it gets the one face in
-- the game that can shout. In red, which is the colour that has been hitting you
-- for ten minutes, spent once here on the one thing that is finally about you.
--
-- **The one place in the game that face is drawn without its ring.** The outline
-- is there for the damage numbers -- one-pixel figures thrown up over a page full
-- of marks, where a counter that showed the page through would close up and a 0
-- would read as a block. A grade is three times that size and it is lying on
-- paper with nothing behind it, so the ring buys nothing and costs the letter its
-- edge: outlined, it comes out as a soft blush-haloed shape rather than a stroke
-- of red pen. Red pen has no outline.
--
-- Nothing here is translated. A grade is a letter, not a word: an A is an A on
-- either page of the book.

local Font = require("src.font")
local Palette = require("src.palette")
local Spawner = require("src.spawner")
local util = require("src.util")

local Mark = {}

-- Low to high, and the two ends are fixed by what they mean: the first is what a
-- run that never got going comes back with and the last is what the eye is
-- worth. Adding a step anywhere in the middle re-spaces the bands on its own,
-- since the time is divided by however many there are.
Mark.ladder = {
    "F", "D-", "D", "D+", "C-", "C", "C+", "B-", "B", "B+", "A-", "A", "A+",
}

Mark.TOP = Mark.ladder[#Mark.ladder]

-- Where a grade sits on the ladder, counted up from the bottom: F is nought and
-- A+ is twelve. One thing outside this file asks -- what the run is *paid* for
-- the grade it got (src/purse.lua) -- and it asks for a rung rather than reading
-- `ladder` itself, so a step added in the middle re-prices every grade above it
-- on its own and nothing has to be told that it did.
--
-- An unknown grade is the bottom of the ladder rather than an error: this is
-- asked in the middle of paying a run out, and a letter nobody recognises is
-- worth nothing rather than worth stopping for.
function Mark.rung(grade)
    for i, step in ipairs(Mark.ladder) do
        if step == grade then return i - 1 end
    end
    return 0
end

-- The most rungs there are to climb, which is what the top grade is worth. Read
-- rather than written down for the same reason as above.
function Mark.rungs()
    return #Mark.ladder - 1
end

-- How big it is drawn. One number rather than a per-screen choice: the two cards
-- that show a mark are showing the same mark, and a grade that was bigger on one
-- of them would read as a different kind of thing.
Mark.SCALE = 3

-- The mark for a run, and the only place the sum lives.
--
-- `won` is passed rather than inferred from the clock because the two are
-- different facts -- ENDLESS can be nineteen minutes deep and still be a run
-- that is going to end by dying -- and because the win being an award rather
-- than a measurement is the thing to keep true when this grows more terms.
function Mark.forRun(time, won)
    if won then return Mark.TOP end

    local n = #Mark.ladder
    -- floor of an even split, so every grade holds the same stretch of clock:
    -- the last band is the run that was all but at the eye, and it gets the
    -- same treatment as the first band gets for being all but off the page.
    local band = math.floor(util.clamp(time / Spawner.BOSS_AT, 0, 1) * n)
    return Mark.ladder[util.clamp(band + 1, 1, n)]
end

--- drawing -------------------------------------------------------------------

-- Measured off the padded cell the face is baked in rather than off the ink in
-- it, which is a pixel wider each side than what is drawn. That is the honest
-- number for a card to reserve: it is the cell the next glyph is placed off, so a
-- two-character grade measures exactly the run of page it occupies.
function Mark.width(grade, scale)
    return Font.bold:width(grade, scale or Mark.SCALE)
end

function Mark.height(scale)
    return Font.bold:tall(scale or Mark.SCALE)
end

-- The widest a mark can ever be, which is what a card is measured on: the ladder
-- is one letter or two and the pair has to be the one reserved for, or a card
-- struck off an F is a card an A+ hangs out of.
function Mark.widest(scale)
    local w = 0
    for _, grade in ipairs(Mark.ladder) do
        w = math.max(w, Mark.width(grade, scale))
    end
    return w
end

-- The body and nothing else -- see the header. Nothing here has to worry about
-- the order src/damage.lua is careful of, since that rule is about rings landing
-- on neighbouring bodies and there are no rings.
function Mark.draw(grade, cx, y, scale)
    scale = scale or Mark.SCALE
    local x = math.floor(cx - Mark.width(grade, scale) / 2)

    love.graphics.setColor(Palette.red)
    Font.bold:print(grade, x, y, scale)
end

return Mark
