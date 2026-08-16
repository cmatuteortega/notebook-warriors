-- Which page of the book the run is played on.
--
-- The game is a notebook, and a notebook has more than one subject in it. A
-- subject is a *page* -- how it is ruled -- and a *class* -- who turns up to it.
-- Both are picked in the same breath, on the timetable (src/timetable.lua),
-- because they are the same decision: you are choosing which part of the book to
-- open.
--
-- The page is the bigger half of that, and not only because it is the half you
-- can see. Every mark in this game is read against the ruling it crosses
-- (src/overprint.lua): ink laid over a printed line comes out a step darker than
-- the same ink laid on blank paper. Squared paper, ruled both ways, darkens a
-- stroke about twice as often as ruled paper does; the unruled page has next to
-- nothing to darken against, so a run on it is drawn very nearly in the colours
-- the tools say they are and nothing else. None of that had to be written -- it
-- falls out of the overprint pass -- which is why a page is allowed to be
-- nothing but ruling and is still a different game to look at.
--
-- All four have something vertical on them a page width apart, and it is one
-- decision rather than four. Horizontal ruling cannot tell you that you are
-- moving: the sheet is infinite, and every line coming up the screen looks like
-- the one it replaced. Something that goes past once a page can -- which the
-- ruled page's margin was already doing and the other three were not, so the
-- staves got bar lines, the grid a doubled rule of its own, and the unruled page
-- the only furniture a page with no ruling is allowed, which is its punch holes.
--
-- The class is the smaller half on purpose. Every subject spawns from the same
-- table, with the same monsters unlocking at the same minutes (`TABLE` in
-- src/spawner.lua): a page that took a monster away would be the same game with
-- less in it, and the unlock times are what the whole ramp is written against. A
-- subject may only lean on that -- `crowd` multiplies the weight of a kind, so a
-- monster that was rare here is common, and `clock` scales the difficulty clock,
-- so the pressure that arrives at minute ten arrives sooner or later than it
-- otherwise would. Neither can make a monster that was not coming, and neither
-- touches the ten minutes the boss is on the other end of.

local Palette = require("src.palette")

local Subjects = {}

-- A page is baked into a repeating tile once at load (src/background.lua), so a
-- ruling is written as a pure function of where you are inside that tile. Two
-- rules, and both of them show up as a seam down the page if they are broken:
-- `w` and `h` have to be whole multiples of whatever the ruling repeats on, and
-- `at` may only answer with one of the three surfaces the overprint lookup knows
-- about (`Palette.surfaces`) -- blank paper, a ruled line, or the margin. A
-- fourth colour on the page is a colour the pass has to guess at.

-- The page this game was drawn on: 2px of blue every 10, and a blush margin
-- every 192 -- one page width. Where the two cross, the rule wins; a margin that
-- broke every ruled line would read as a dotted column rather than as the line
-- down the side of a page.
local RULED = {
    w = 192, h = 100,
    at = function(x, y)
        if y % 10 < 2 then return Palette.sky end
        if x == 24 then return Palette.blush end
        return Palette.paper
    end,
}

-- Ruled paper with the verticals added, which is what squared paper is. One
-- pixel rather than two: at the same 10px pitch a 2px grid is a fifth of the
-- page painted blue, and the page has to stay the thing everything else is read
-- against.
--
-- The margin is the same idea as the ruled page's, in the grid's own colour
-- rather than in blush -- squared paper is printed in one ink, and a red line
-- here would be a second thing on a page that already has two directions of
-- ruling on it. What marks it out as a margin instead of another grid line is
-- that it is *double*, the way the horizontal rules on the ruled page are, so
-- it reads as heavier than the line 4px away from it rather than as a colour of
-- its own. It sits at the same x as the ruled page's margin and repeats on the
-- tile, i.e. once a page width, and it falls between two grid lines rather than
-- on one so neither is thickened by it.
local SQUARED = {
    w = 180, h = 100,
    at = function(x, y)
        if x % 10 == 0 or y % 10 == 0 then return Palette.sky end
        if x >= 24 and x < 26 then return Palette.sky end
        return Palette.paper
    end,
}

-- Staves: five lines four apart, then a gap the same height again before the
-- next one. It repeats on 40, and the tile is three of them tall.
--
-- The gap is the point. Ruled paper is an even field and squared paper is an
-- even grid, so on both of them the ruling under a mark is roughly the same
-- wherever the mark is; here it comes in bands, and a stroke drawn across a
-- stave darkens five times in seventeen pixels and then not at all for the next
-- twenty. It is the one page where where you draw changes how the drawing comes
-- out.
--
-- The bar lines are what the page has instead of a margin, on the same spacing
-- as the ruled page's -- once a tile, which is once a page width. They only
-- cross the stave rather than running the height of the tile, because that is
-- what a bar line is: the gap between two staves is the gap between two systems
-- and nothing is written in it. Three of them go past per tile rather than one,
-- so the page reads as moving under you the way the horizontal rules cannot.
local STAVES = {
    w = 192, h = 120,
    at = function(x, y)
        local at = y % 40
        if at < 20 and at % 4 == 0 then return Palette.sky end
        if x == 24 and at <= 16 then return Palette.sky end
        return Palette.paper
    end,
}

-- A one-pixel ring, which is what a punched hole looks like printed: the edge of
-- it and nothing else. Radius 3 -- seven pixels across, the smallest circle that
-- still comes out round rather than as a square with the corners off.
local function punch(x, y, cx, cy)
    local dx, dy = x - cx, y - cy
    local d2 = dx * dx + dy * dy
    return d2 >= 6.25 and d2 <= 12.25
end

-- Unruled, which is a real page in a real notebook and is very nearly the
-- control case for the whole overprint pass: with no lines to stack with, a mark
-- on this page stays the exact colour its tool says it is nearly everywhere it
-- is put. The run is quieter to look at and harder to read a distance off, since
-- the ruling is what a sprite is normally sized against.
--
-- The `nearly` is the punch holes, and they are the whole of what is printed
-- here. A page with no ruling at all has nothing on it that passes you: walking
-- across it is walking on the same pixel, and the one page you draw on freely is
-- the one that never tells you you are moving. Two holes a tile down the same
-- column the other pages keep their margin in is the least that fixes that -- a
-- thing the eye can count going by, on a page that otherwise gives it nothing --
-- and it is sparse enough that the control case survives it: a mark has to be
-- laid across one of these rings to come out a step darker, and almost none are.
--
-- The first one sits high in the tile rather than in the middle of it, and that
-- is for the timetable rather than for the run: a swatch is read from the tile's
-- own origin and is only 16px deep (src/timetable.lua), so a hole any lower down
-- would leave this subject's card showing a blank rectangle and no account at all
-- of what its page is. Where a tile repeats forever the phase is free, so it may
-- as well be the phase the card can see.
local BLANK = {
    w = 192, h = 100,
    at = function(x, y)
        if punch(x, y, 24, 8) or punch(x, y, 24, 58) then return Palette.sky end
        return Palette.paper
    end,
}

-- In the order they are laid out on the timetable, which is the order they get
-- harder in. The first is the game as it was written; each one after it leans on
-- the horde a little further.
--
-- `says` is the one line the card gets under the name, and it says what is
-- different about the *class* rather than about the page -- the page is on the
-- card already, as a piece of itself.
Subjects.list = {
    {
        key = "language",
        name = "LANGUAGE",
        says = "THE USUAL LOT",
        paper = RULED,
        clock = 1,
    },
    {
        key = "music",
        name = "MUSIC",
        says = "MOSTLY BATS",
        paper = STAVES,
        clock = 1,
        -- Bats are the one enemy in the table that is faster than you, so a
        -- class made mostly of them is the same clock played at a different
        -- distance: nothing here can be walked away from, and the page is
        -- decided at arm's length instead of across the room. x2.5 puts them a
        -- little over half the horde once they unlock at minute one, which is
        -- enough to change what a run does without emptying the rest of the
        -- table out.
        crowd = { bat = 2.5 },
    },
    {
        key = "maths",
        name = "MATHS",
        says = "MORE SKULLS",
        paper = SQUARED,
        -- Skulls are the weight that has to be spent damage on rather than
        -- walked around, and eyes are the one that punishes standing still. Both
        -- unlock late -- minute five and minute seven and a half -- so this is a
        -- subject whose first half is very nearly LANGUAGE and whose second half
        -- is the thing the extra clock was already promising.
        clock = 1.15,
        crowd = { skull = 3, eye = 1.5 },
    },
    {
        key = "art",
        name = "ART",
        says = "FASTER CROWD",
        paper = BLANK,
        -- The same crowd, arriving at the pressure a normal run would be under
        -- three minutes later. Nothing is over-represented, because the page is
        -- already the odd one out: with no ruling to darken it, a run here is
        -- read entirely off the marks, and the honest way to make that harder is
        -- more of everything rather than more of one thing.
        clock = 1.3,
    },
}

Subjects.default = Subjects.list[1]

function Subjects.get(key)
    for _, sub in ipairs(Subjects.list) do
        if sub.key == key then return sub end
    end
    return Subjects.default
end

return Subjects
