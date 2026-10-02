-- DEV ONLY: this module does not ship. An override rather than an edit, which
-- is why it is safe to leave in while the game is made -- it writes nothing.
-- `Collection.has`, `Collection.lessonOpen` and `Characters.owns` ask
-- `Dev.opened` before they ask the register, so stepping back to EARNED
-- restores exactly what the book remembers. Three states because ALL (a
-- finished book, for balancing a late run) and NONE (the first afternoon, on a
-- save full of records) are not opposites. The purse and the perks bought out
-- of it are deliberately untouched: those are purchases, and src/refund.lua is
-- their way back. Nothing is on the page until the word SETTINGS is tapped
-- three times (`Dev.showing`).
--
-- TAKING IT OUT AT LAUNCH is three calls, two guards and a file: the last row
-- of `ROWS` in src/settings.lua, the `Dev.opened` calls in `Collection.has`,
-- `Collection.lessonOpen` and `Characters.owns`, the `unlocks` and `dev` lines
-- src/options.lua writes, the `Dev.showing` guards in src/pause.lua and
-- src/game.lua's `keypressed` -- and then this file.

local Dev = {}

-- The order the settings row steps in; EARNED first, the shipping answer.
Dev.MODES = { "earned", "all", "none" }

-- Stepped on the settings page and saved with the rest (src/options.lua); a
-- file naming a state this build lacks keeps this default, like every option.
Dev.unlocks = "earned"

-- Whether any of it is on the page. Saved too (src/options.lua), so the gesture
-- is done once; off on a book nobody has done it on.
Dev.shown = false

-- Asked by the two screens before they draw any of it. Not simply `Dev.shown`:
-- a book left in ALL with the row put away would be lying with no visible way
-- back, so being off the shipping answer shows the controls regardless. That
-- also covers an older options file with an `unlocks` line and no `dev` line.
function Dev.showing()
    return Dev.shown or Dev.unlocks ~= "earned"
end

-- The one question the three readers ask. On EARNED it hands the register's own
-- answer straight back.
function Dev.opened(earned)
    if Dev.unlocks == "all" then return true end
    if Dev.unlocks == "none" then return false end
    return earned
end

return Dev
