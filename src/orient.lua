-- Which way up the page is held -- the settings page's SCREEN row. AUTO hands
-- it back to the phone and its own rotation lock; WIDE and TALL pin it. The
-- canvas never cared (main.lua takes the zoom off the short edge and every
-- screen reads `Game.vw/vh`); what was missing was permission to turn at all.
--
-- LOVE has no orientation call. The Android activity is asked for one only by
-- SDL, in `Android_SetWindowResizable`, which fires when the resizable flag
-- CHANGES and passes on the `SDL_ORIENTATIONS` hint: landscape only gets
-- USER_LANDSCAPE, portrait only USER_PORTRAIT, naming nothing falls through to
-- all four. So `apply` sets the hint, then flips the flag off and back on.
-- `love.window.setMode` cannot do it -- Android implements no `SetWindowSize`
-- (`SDL_androidvideo.c`), so `window->w/h` keep the screen's own size and SDL
-- asks for the orientation the phone is already in. Hence the FFI, three
-- symbols out of the SDL already running the window, all behind pcall: a build
-- that cannot resolve them leaves `sdl` nil and the row a no-op, which is what
-- it also is on iOS and desktop. Going direct also avoids LOVE's `setWindow`,
-- which drops fullscreen and rebuilds the graphics mode on Android.

local Orient = {}

-- The order the settings page steps them in: free first, then the two locks.
Orient.MODES = { "auto", "wide", "tall" }
Orient.mode = "auto"

-- The strings `SDLActivity.setOrientationBis` greps for. Both rotations of a
-- side are named or a player holding the phone the other way reads upside down;
-- naming nothing is how AUTO falls through to "all four".
local HINT = {
    auto = "",
    wide = "LandscapeLeft LandscapeRight",
    tall = "Portrait PortraitUpsideDown",
}

-- What the phone was last asked for. "auto" because that is what SDL asked for
-- itself at window creation (conf.lua opens resizable with no hint set).
local applied = "auto"

-- nil on desktop and on any build whose symbols do not resolve; nothing below
-- ever runs then.
local ffi, sdl

local function connect()
    if love.system.getOS() ~= "Android" then return end

    local ok, mod = pcall(require, "ffi")
    if not ok then return end

    -- SDL_GetWindows returns an array we own the spine of, hence SDL_free.
    -- LuaJIT's bool matches the C99 one SDL 3 uses.
    ok = pcall(mod.cdef, [[
        bool SDL_SetHint(const char *name, const char *value);
        bool SDL_SetWindowResizable(void *window, bool resizable);
        void **SDL_GetWindows(int *count);
        void SDL_free(void *mem);
    ]])
    if not ok then return end

    -- The APK ships libSDL3.so, so this handles what is already in the process;
    -- the fallback namespace is for a build that linked it in instead.
    local lib
    ok, lib = pcall(mod.load, "SDL3")
    if not ok then lib = mod.C end

    -- Proved once here, so everything after can call without its own pcall.
    if not pcall(function() return lib.SDL_GetWindows end) then return end

    ffi, sdl = mod, lib
end

connect()

-- Looked up per call: a kept pointer to a window LOVE rebuilt is a crash.
local function window()
    local count = ffi.new("int[1]")
    local list = sdl.SDL_GetWindows(count)
    if list == nil then return nil end

    local win = nil
    if count[0] > 0 then win = list[0] end
    sdl.SDL_free(list)  -- the array, not the window it names

    return win
end

-- Ask the phone to turn. Safe to call twice: an already-applied mode returns.
function Orient.apply()
    if not sdl then return end
    if Orient.mode == applied then return end

    local win = window()
    if win == nil then return end

    sdl.SDL_SetHint("SDL_ORIENTATIONS", HINT[Orient.mode])

    -- Off and straight back on: SDL asks the activity on the CHANGE, not the
    -- value, so both land and the second leaves the window resizable, the state
    -- conf.lua opened in and the rest of the game expects.
    sdl.SDL_SetWindowResizable(win, false)
    sdl.SDL_SetWindowResizable(win, true)

    applied = Orient.mode
end

return Orient
