-- The word thrown up when one gesture puts more than a handful of the crowd
-- down at once -- the flourish a whole action earns, next to the number each
-- individual hit already gets (src/damage.lua). Same face, same outlined
-- construction, drawn over the finished page for the same reason a damage
-- number is: this is a readout and not a mark, and it must not change colour
-- because of what it happens to land over.
--
-- **A gesture is a press**, mostly. Game:updateDrawing already has the one
-- place a new press begins (`down and not self.wasDown`) and the one place it
-- ends (`elseif not down`), and every tool on the strip passes through both of
-- them whichever block it takes -- a brush, the compass's sweep, the
-- pushpin's drop, the ruler's snap, the scissors' cut. So that is what bounds
-- a gesture here too, rather than a second idea of one invented for this
-- file: Game calls `beginGesture` and `endGesture` at those two edges and
-- nothing else has to know a word can be said at all.
--
-- **Except that a press ending is not always a tool finishing.** A pushpin's
-- crater does not land the instant you tap -- it falls for a quarter of a
-- second first (`FALL`, src/pin.lua). A compass's ring does not cut on the
-- drag that set its width, it cuts while the arm spends real seconds coming
-- round after you have already let go (`Compass:swing`, src/compass.lua).
-- And the scissors' second tap only prints a dotted line -- the blades close
-- along it over the next several frames (`Scissors:strike`,
-- src/scissors.lua). All three finish well after the release edge above has
-- already run, so a straight press-to-release window would watch every pin,
-- every compass sweep and every cut in the game die silent. `hold` and
-- `release` are the fix: whatever spawns a kill that can only land after its
-- own press is over calls `hold` when it is spawned and `release` when it
-- finally resolves, and the window stays open -- independently of whether a
-- *new* press has started in the meantime -- until every hold still
-- outstanding has been matched.
--
-- One thing falls out of counting it that way and is worth being honest
-- about: a kill landed by an automatic weapon (a sword swinging on its own, a
-- sun long since risen) counts too, as long as it lands while some gesture or
-- some hold happens to be open. That is not a bug worth chasing down -- a run
-- holding the pointer through a crowd, or one whose pin has not landed yet, is
-- a run *doing something*, and crediting the windfall to it reads the way it
-- should. What it must never do is fire off a kill nobody's press is anywhere
-- near: a wall's ink coming off nine seconds after it was drawn (`pop`,
-- src/stroke.lua) lands with nothing open at all and is silently not
-- counted, which is correct.

local Palette = require("src.palette")
local Font = require("src.font")
local I18n = require("src.i18n")

local Multikill = {}
Multikill.__index = Multikill

-- More than this many kills in one gesture earns the word. Five is a burst
-- any tool can catch off a bad corner for the crowd; six is the gesture
-- actually working -- one more than the damage numbers' own lowest tier
-- ceiling (src/damage.lua), which is not a coincidence: both lines are
-- marking "this stopped being incidental".
local THRESHOLD = 5

-- Four words a lesson, so the same page does not say the same thing every
-- time. Every one of them is the bold face's own repertoire -- caps, digits
-- and punctuation (src/font.lua) -- because this is shouting in the same
-- voice a damage number already shouts in.
--
-- English is the key and is translated at the draw, never here: see
-- src/i18n.lua on why nothing in this game bakes a translation in early.
local WORDS = {
    science  = { "SCIENCE!", "EXTINCT", "DEAD", "ATOMIC!" },
    language = { "YEAH", "WOW", "HUH", "NICE!" },
    maths    = { "SUMMED", "SUBSTRACTED", "INTEGRATED", "FOURIER'D" },
    pe       = { "SWEAT!", "RUN!", "FASTER!", "GOAL!" },
    music    = { "FORTE", "PIANO", "ADAGIO", "ALLEGRO" },
    art      = { "ERASED", "INKED", "FINISHED", "PASTED" },
    finance  = { "ALIGNED", "PUMPED", "LIQUIDITY", "KPI'D" },
}

-- The size the ordinary damage tiers land at (6 to 24hp, src/damage.lua) and
-- not one of the tiers that pops bigger: the longest word here (SUBSTRACTED,
-- eleven letters) is already seventy-odd pixels wide at scale 1, and a whole
-- word popping in two sizes over that would run off the short edge of a
-- phone's canvas (main.lua). A damage number never has that problem because
-- it is never more than three digits.
local SCALE = 1

local RISE = 20    -- slower than a damage number's (src/damage.lua): a word
local FALL = 46    -- is read, not glanced at, and wants to hang in the air
                    -- rather than arc off the top of the screen.

local POP = 0.09     -- how long it is drawn a size over the one it lands at
local SHRINK = 0.16  -- and how long it is drawn a size under it, on the way out
local LIFE = 1.05    -- long enough that a multi-letter word is actually read

-- One at a time is the whole of what this is for -- a second multikill inside
-- the same gesture would be the same word twice, which reads as a glitch
-- rather than as a second flourish -- so `fired` latches the moment the first
-- one goes up and nothing built here ever needs a list of more than one.
-- Kept as a list of one anyway, and not a single field, so draw and update
-- read exactly like Damage's own.
function Multikill.new()
    return setmetatable({
        list = {},
        kills = 0,
        fired = false,
        pressed = false, -- a press is currently down (beginGesture..endGesture)
        pending = 0,     -- holds still waiting on a release (see the file note)
    }, Multikill)
end

-- The window a kill is allowed to land in: either a press is down right now,
-- or something spawned during a press is still waiting to resolve.
function Multikill:isOpen()
    return self.pressed or self.pending > 0
end

-- Called once, on the press edge every tool shares (Game:updateDrawing).
-- `pending` is deliberately untouched: it belongs to whatever is still
-- falling or sweeping from a *previous* gesture, and a fresh press starting
-- before that has resolved must not forget about it.
function Multikill:beginGesture()
    self.kills = 0
    self.fired = false
    self.pressed = true
end

-- Called once, after the release edge has resolved everything a lifted
-- finger can still trigger (a tap, a chord cut, the ruler's and the
-- compass's own finish). The window can stay open past this if a `hold` is
-- still outstanding -- see the file note.
function Multikill:endGesture()
    self.pressed = false
end

-- Called by whatever just spawned something that can only land after its own
-- press may already be over (a falling pin, a compass mid-swing) -- keeps the
-- window open until the matching `release`.
function Multikill:hold()
    self.pending = self.pending + 1
end

-- The other half of `hold`, called the moment that pin lands or that arm
-- stops. Floored at zero rather than trusted to balance, so a caller that
-- somehow released twice cannot leave the window stuck open.
function Multikill:release()
    self.pending = math.max(0, self.pending - 1)
end

-- `subjectKey` rather than a whole subject, because this is the one place in
-- the run that reads a lesson's identity purely to pick which four words it
-- is allowed to say -- everything else about a subject (Game:killEnemy's
-- caller) has no reason to know this module exists.
function Multikill:noteKill(x, y, subjectKey)
    if self.fired or not self:isOpen() then return end

    self.kills = self.kills + 1
    if self.kills <= THRESHOLD then return end
    self.fired = true

    local words = WORDS[subjectKey] or WORDS.science
    local text = words[love.math.random(#words)]

    self.list[#self.list + 1] = {
        text = text,
        x = x, y = y,
        dy = -RISE,
        life = LIFE, born = LIFE,
    }
end

function Multikill:update(dt)
    for i = #self.list, 1, -1 do
        local n = self.list[i]
        n.y = n.y + n.dy * dt
        n.dy = n.dy + FALL * dt
        n.life = n.life - dt
        if n.life <= 0 then table.remove(self.list, i) end
    end
end

-- The same three-beat pop a heavy damage number does (src/damage.lua): a size
-- over what it lands at, the size it lands at, and a size under it -- hollow,
-- ring only -- on the way out. Floored at 1, exactly as Damage's own `beat`
-- is, since there is no size under it to drop to.
local function beat(n)
    local age = n.born - n.life
    if age < POP then return SCALE + 1, false end
    if n.life < SHRINK then return math.max(1, SCALE - 1), true end
    return SCALE, false
end

-- Drawn in world space, exactly where Game:draw calls Damage:draw and for the
-- same reason: after Overprint.finish(), so nothing here can be read against
-- whatever ruling it happens to be sitting over, and still inside the camera
-- transform, so it scrolls with the spot the gesture actually happened at.
function Multikill:draw()
    local face = Font.bold
    for _, n in ipairs(self.list) do
        local scale, hollow = beat(n)
        local text = I18n.t(n.text)
        local x = math.floor(n.x - face:width(text, scale) / 2)
        local y = math.floor(n.y) - face:tall(scale)

        -- Red on ink, the same fill and ring the 12-24hp damage tier lands at
        -- (src/damage.lua) -- the tier this now shares a size with, so a word
        -- reads as one more damage number rather than as a second kind of
        -- readout the page has to learn.
        love.graphics.setColor(Palette.ink)
        face:printRing(text, x, y, scale)

        if not hollow then
            love.graphics.setColor(Palette.red)
            face:print(text, x, y, scale)
        end
    end
end

return Multikill
