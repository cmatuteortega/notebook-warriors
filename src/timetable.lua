-- The timetable: which page of the book this run is played on.
--
-- It sits between the title screen and the board your character is drawn on,
-- which is the only place it can sit. The subject decides how the page is ruled
-- and the ruling is what the drawing is read against (src/overprint.lua), so
-- picking it after the hero is drawn would mean drawing him against one page and
-- playing him on another.
--
-- It is a register: one stripe per subject down the page, the tool that lesson
-- hands you at each end of it, and the box you answer in out to the right. The
-- heading sits over that column of boxes rather than over the middle of the
-- screen, because the right-hand edge is the one every row lines up on and a
-- title is a thing you read before the list under it.
--
-- Nothing on a stripe is a picture of the page. It used to be -- this screen was
-- a grid of cards and every one carried a swatch of its own ruling -- and the reason it does not any more is
-- that **the page underneath is the answer, live**: whichever box is armed is
-- the paper the whole screen is standing on, so the ruling under the question is
-- already the ruling you are about to play on, at full size and across the whole
-- screen rather than in a 20px window. A swatch was a smaller second copy of
-- something the screen was showing anyway. What the stripe shows instead is the
-- half of a lesson the page cannot show: the tool it puts in your hand.
--
-- So the stripes are drawn *on* the page rather than on paper laid over it,
-- along with the heading and the hint. There is nothing here that has to hide
-- what is behind it -- which is the whole difference between this screen and the
-- draft, where a card is opaque because a frozen run is too busy to read
-- lettering against.
--
-- A box is answered the way everything in this game is answered
-- (src/scribble.lua): scribble in it, or tap the stripe and the scribble is
-- drawn for you.

local Palette = require("src.palette")
local Font = require("src.font")
local Background = require("src.background")
local Overprint = require("src.overprint")
local Input = require("src.input")
local Scribble = require("src.scribble")
local Sprites = require("src.sprites")
local Subjects = require("src.subjects")
local Upgrades = require("src.upgrades")
local util = require("src.util")

local Timetable = {}

local HEAD = "TODAYS LESSON"
local HEAD_SCALE = 2

local PAD = 4          -- stripe border to what is inside it
local ICON = 11        -- the tool's icon, and every icon in the game is 11x11
local NAME_GAP = 6     -- the least there may be between the lesson and its icon
local BOX_GAP = 6      -- stripe to the box out to its right
local ROW_GAP = 4      -- one stripe to the next
local EDGE = 4         -- and off the edge of the page
local HEAD_GAP = 6     -- the title to the lines under it
local LINE_GAP = 2     -- one of those lines to the next

-- Where the list starts across the page. The screen is two columns and this is
-- the seam: what the lesson is called and how to answer sits in the left two
-- thirds, and the register itself runs down the right third with its boxes
-- against the right margin.
--
-- The list is the narrower column on purpose. It is seven short rows, and rows
-- do not get better for being wider -- what they need is height, which is what
-- moving the heading and the hint off the top of the screen and into the column
-- beside it buys them: with nothing above or below, every row is the full 22 it
-- is allowed instead of the 17 it had.
local SPLIT = 2 / 3

-- A stripe is as tall as there is room for, between an icon with a pixel to
-- spare above and below it and about twice that. The box out to the right is
-- given the same height, because a row and its answer are one thing and a box
-- half the height of the row it belongs to reads as belonging to neither it nor
-- the next one.
local ROW_MIN, ROW_MAX = 13, 22

-- A stripe stops widening here even where a third of the page is wider than
-- this, because a name at one end of a rectangle and an icon at the other stop
-- reading as one row somewhere past about this. The seam stays at two thirds
-- when that happens: the stripe is anchored by its left edge and the margin
-- opens up on the right.
local STRIPE_MAX = 180

local STRIPE_TIME = 0.22 -- the stripes drawing themselves on as the screen opens
local CONFIRM = 0.34   -- the picked stripe flashing before the page turns

function Timetable:enter(key)
    self.t = 0
    self.phase = "asking"  -- asking -> confirm
    self.chosen = nil
    self.confirmT = 0
    self.current = key or Subjects.default.key
    self.seed = love.math.random() * 997
    self.marks = Scribble.newMarks(self.seed)

    -- A pointer still down from the title screen's YES is not this screen's to
    -- read: it draws nothing and taps nothing until it has been lifted.
    self.stale = Input.pointerDown
    self.pen = Scribble.newPen()

    -- One unlabelled box per stripe -- the stripe beside it is the label.
    local defs = {}
    for i, sub in ipairs(Subjects.list) do
        defs[i] = { key = sub.key }
    end
    self.choice = Scribble.newChoice(defs, 1)

    self.stripes = {}
    for i = 1, #Subjects.list do
        self.stripes[i] = { box = self.choice.boxes[i] }
    end

    -- Nothing to walk here, and the corner the stick lives in is page like any
    -- other: you have to be able to scribble anywhere.
    Input.stickEnabled = false
end

--- layout --------------------------------------------------------------------

-- Every stripe is the same width and the names all start at the same pixel, so
-- the column reads as a list rather than as seven labels of different sizes.
local function nameWidth()
    local w = 0
    for _, sub in ipairs(Subjects.list) do
        w = math.max(w, Font.width(sub.name))
    end
    return w
end

-- Two columns. The register goes down the right, anchored so its boxes sit on
-- the right margin; the heading and the hint go down the left, centred against
-- the height of the list rather than sat on top of it.
--
-- The seam is at two thirds wherever the page can afford it. Where it cannot --
-- a narrow portrait canvas -- the list wins and the seam moves left, because a
-- lesson you cannot read is worse than a title that has less room than it wanted
-- and the title has somewhere to go: it drops to single size.
function Timetable:layout(game)
    local ins = game.inset
    local availW = game.vw - ins.l - ins.r
    local availH = game.vh - ins.t - ins.b

    local left = ins.l + EDGE
    local right = ins.l + availW - EDGE
    local usable = right - left

    local lay = {}
    local n = #self.stripes

    -- The stripe holds the lesson at one end and the tool's icon at the other,
    -- and this is the least it can be and still hold both.
    local nameW = nameWidth()
    local least = PAD + nameW + NAME_GAP + ICON + PAD

    lay.listX = left + math.floor(usable * SPLIT)
    lay.stripeW = math.min(right - lay.listX - BOX_GAP - Scribble.BOX_W, STRIPE_MAX)
    if lay.stripeW < least then
        lay.stripeW = least
        lay.listX = right - (least + BOX_GAP + Scribble.BOX_W)
    end

    -- Rows have the whole height to share now that nothing is stacked above or
    -- below them.
    lay.rowH = util.clamp(math.floor((availH - ROW_GAP * (n - 1)) / n),
                          ROW_MIN, ROW_MAX)

    local gridH = n * lay.rowH + ROW_GAP * (n - 1)
    lay.rows = math.max(ins.t, math.floor(ins.t + (availH - gridH) / 2))

    for i, stripe in ipairs(self.stripes) do
        stripe.x = lay.listX
        stripe.y = lay.rows + (i - 1) * (lay.rowH + ROW_GAP)
        stripe.w, stripe.h = lay.stripeW, lay.rowH

        -- The box is the row's own height rather than the 20 every other box in
        -- the game is. Coverage is counted on a grid inside it (src/scribble.lua)
        -- and reads its size off the box, so a shorter one is answered by a
        -- shorter scribble and nothing else has to know.
        stripe.box.h = lay.rowH
        self.choice:place(stripe.box, stripe.x + stripe.w + BOX_GAP, stripe.y)
    end

    -- The left column, and the title is the one thing on this screen that gets
    -- smaller rather than being dropped: it is the question, so it cannot go,
    -- and it is the only thing here with a size to spend.
    lay.textX = left
    lay.textW = lay.listX - BOX_GAP - left
    lay.headScale = Font.width(HEAD) * HEAD_SCALE <= lay.textW and HEAD_SCALE or 1

    -- Measured with every line present even though two of them come and go with
    -- what is happening, so the block does not walk up the page when the pen
    -- goes down.
    local headH = Font.height * lay.headScale
    local blockH = headH + HEAD_GAP + Font.height * 3 + LINE_GAP * 2

    lay.head = math.max(ins.t, math.floor(ins.t + (availH - blockH) / 2))
    lay.hint = lay.head + headH + HEAD_GAP

    self.lay = lay
    return lay
end

--- update --------------------------------------------------------------------

function Timetable:commit(box)
    self.phase = "confirm"
    self.chosen = box
    self.confirmT = 0
end

-- Ink that lands in a box is the answer and is counted there; ink that misses is
-- just ink on the page, and fades off it.
function Timetable:mark(x, y, quiet)
    if self.choice:mark(x, y, quiet) then return end
    self.marks:add(x, y)
end

-- A press that lands on a stripe draws the scribble into the box out to its
-- right rather than jumping past it, exactly as the keyboard does. The stripe is
-- the target because it is the part that says what you are picking; the box is
-- there to be drawn in.
function Timetable:tap(x, y)
    for _, stripe in ipairs(self.stripes) do
        if x >= stripe.x and x < stripe.x + stripe.w
            and y >= stripe.y and y < stripe.y + stripe.h then
            self.choice:autoFill(stripe.box)
            return
        end
    end
end

-- The page the whole screen is standing on: the one being answered while a box
-- is armed or picked, and the one the book was last open at until then.
function Timetable:pageKey()
    local box = self.chosen or self.choice.armed
    return box and box.key or self.current
end

-- Returns the key of the subject that was picked, on the frame the pick takes
-- hold, and nothing at all until then.
function Timetable:update(dt, game)
    self:layout(game)
    self.t = self.t + dt
    self.marks:update(dt)

    if self.phase == "confirm" then
        self.confirmT = self.confirmT + dt
        if self.confirmT >= CONFIRM then return self.chosen.key end
        return
    end

    -- The keyboard and a tap both draw the scribble rather than jumping past it,
    -- and there is no pen to lift, so that answer stands as soon as the box
    -- fills.
    local filled = self.choice:update(dt)
    if filled then
        self:commit(filled)
        return
    end

    local down = Input.pointerDown
    if self.stale then
        self.stale = down
        down = false
    end

    self.pen:track(down, Input.pointerX, Input.pointerY,
        function(mx, my) self:mark(mx, my) end,
        function(px, py) self:tap(px, py) end)

    -- Armed, not answered: nothing is picked until the pen comes off the page,
    -- so a line that carries on into the next box changes its mind.
    if self.choice.armed and not down then
        self:commit(self.choice.armed)
    end
end

function Timetable:keypressed(key)
    if self.phase ~= "asking" then return end

    local slot = tonumber(key)
    if slot and self.stripes[slot] then
        self.choice:autoFill(self.stripes[slot].box)
    end
end

--- draw ----------------------------------------------------------------------

-- The three lines under the title, in the order they are stacked. The second and
-- third are the ways in rather than what is happening, so they go while the pen
-- is down and the first line is saying something more urgent than they are.
--
-- A line that will not fit the column goes too, rather than running into the
-- list beside it. The column is only ever that narrow on a page the list has
-- already had to take room from, and a lesson you cannot read is worse than a
-- caption you have to work out -- which is the same order of priority the whole
-- screen degrades in: the boxes, then the lessons, then the title, then the
-- words about how to answer.
function Timetable:hintLines()
    local all = {}

    if self.choice.armed then
        all[1] = Input.usingTouch and "LIFT TO CONFIRM" or "RELEASE TO CONFIRM"
    else
        all[1] = "TAP A LESSON"
        all[2] = "OR SCRIBBLE ITS BOX"
        -- Counted off the stripes rather than written out, so a subject added to
        -- the book is offered a key without this line having to be remembered.
        -- It stops at nine because `keypressed` reads a single digit; a tenth
        -- lesson is scribbled for rather than pressed, which is the route the
        -- screen is built around anyway.
        if not Input.usingTouch then
            all[3] = "OR PRESS 1-" .. math.min(#self.stripes, 9)
        end
    end

    local lines = {}
    for _, line in ipairs(all) do
        if Font.width(line) <= self.lay.textW then lines[#lines + 1] = line end
    end
    return lines
end

-- One line of the register: the lesson at the left of the row, the icon of the
-- tool it hands you at the right of it, and the box it is answered in beyond
-- that. The stripe and its box warm and flash as one thing, both taking their
-- colour from the box, because they are one answer drawn in two pieces.
--
-- The icon is the whole of what the row says about the tool. It used to say the
-- name as well, at the far end of a much wider stripe, and the word was the part
-- worth losing: the same eleven pixels of glyph is what the tool selector, the
-- draft card and the pause screen all use, so it is a thing you already know how
-- to read by the time you are choosing a lesson.
function Timetable:drawStripe(i, stripe)
    local sub = Subjects.list[i]
    local up = Upgrades.byId[sub.tool]
    local progress = util.clamp(self.t / STRIPE_TIME, 0, 1)
    local color = Scribble.boxColor(stripe.box, self.chosen, self.confirmT)

    Scribble.drawBox(stripe, progress, color, 20 + i * 3, 0)

    -- Both centred on the row's midline rather than sat on its top edge, since
    -- the row's height is whatever the screen could spare and theirs is not.
    local midY = stripe.y + math.floor(stripe.h / 2)

    love.graphics.setColor(Palette.ink)
    Font.print(sub.name, stripe.x + PAD, midY - math.floor(Font.height / 2))
    Sprites.icons[up.icon]:draw(stripe.x + stripe.w - PAD - ICON / 2, midY)

    Scribble.drawBox(stripe.box, progress, color, 40 + i * 3, 0)
    Scribble.drawMarks(stripe.box.marks, Palette.ink, self.seed, 0)
end

function Timetable:draw(game)
    local lay = self:layout(game)

    -- The whole screen is written on the page rather than laid over it, stripes
    -- included, so the ruling shows through the question the same way it shows
    -- through a pencil line drawn mid-run -- and the ruling it shows through is
    -- the one being answered. There is nothing on this screen that has to cover
    -- what is behind it, which is why nothing here is drawn after the pass.
    Overprint.beginPage()
    Background.drawAs(self:pageKey(), 0, 0, game.vw, game.vh)

    Overprint.beginInk()
    self.marks:draw(0)

    -- Both columns are set flush to their own left edge, which is what makes
    -- them read as two columns rather than as two things that happen to be side
    -- by side.
    Scribble.printBig(HEAD, lay.textX + Font.width(HEAD) * lay.headScale / 2,
        lay.head, lay.headScale, Palette.red,
        { shadow = Palette.blush, wobble = true, t = self.t, seed = 3 })

    for i, stripe in ipairs(self.stripes) do
        self:drawStripe(i, stripe)
    end

    if self.phase == "asking" then
        local armed = self.choice.armed ~= nil
        local y = lay.hint

        for i, line in ipairs(self:hintLines()) do
            local color = Palette.graphite
            if i == 1 then color = armed and Palette.red or Palette.slate end

            Scribble.printBig(line, lay.textX + Font.width(line) / 2, y, 1,
                color, { seed = 60 + i })
            y = y + Font.height + LINE_GAP
        end
    end

    Overprint.finish()
end

return Timetable
