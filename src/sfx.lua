-- Every sound in the game -- the foley and the one music track -- and the two
-- things that keep the foley from sounding like a machine: no two plays at the
-- same pitch, and no file at its own volume.
--
-- The recordings arrived at wildly different levels -- the ruler slap peaks at
-- full scale while the rubbing loop sits 46dB under it -- and a Source's
-- volume only goes *down*, so evening them out at play time is impossible for
-- the quiet ones. Instead every file is decoded once at load and its samples
-- are scaled in place to sit at the same perceived level (the gains below were
-- measured against the loudest 300ms of each file), which leaves one number in
-- front of the whole game -- MASTER, what it sounds like at full -- and the
-- player's own volume as a multiplier on that (see `Sfx.volume` below).
--
-- Pitch is randomised a few percent on every play. A pitch shift in OpenAL is
-- a speed change too, which is exactly right for foley: a slightly faster
-- swish is a slightly different swish, not a chipmunked one. The track is the
-- one voice exempt from both of those -- it is streamed rather than decoded, and
-- it is played at written pitch, music being the one thing here that a few
-- percent of speed would put out of tune rather than out of the ordinary.
--
-- Two sounds fire far more often than the rest of the game does -- a hit lands
-- on every enemy every weapon touches, and a gem is picked up on every kill --
-- and for those two the few percent is not enough drift and the common level is
-- too loud. Both take a wider pitch range and a minimum gap between plays,
-- written on their own rows below, so a horde being mown reads as a rattle at a
-- level you can play under rather than as one note held down.

local Sfx = {}

local DIR = "src/sfx/"
local MASTER = 0.9

-- The two knobs the settings page turns (src/settings.lua), both 0 to 1, and
-- both multiplied into MASTER rather than replacing it: MASTER is what the game
-- sounds like at full, and these are how loud the player wants full to be.
--
-- `music` opens a notch under `volume` rather than level with it, and that notch
-- is the whole of how both are audible at once: the track is a bed playing for as
-- long as the program is open and every effect is a transient laid on top of it,
-- so a bed level with the foley is the thing you hear and the foley is the thing
-- you miss. It is a *default* rather than a ceiling baked into the gain below --
-- the bar still goes all the way up for somebody who wants the music louder than
-- the game -- and it is why the page reads 70 against 100 rather than two
-- hundreds with a difference hidden behind them.
Sfx.volume = 1
Sfx.music = 0.7

-- What a voice is actually played at. Read at every play rather than worked out
-- once, so a bar dragged on the settings page is heard on the next sound rather
-- than on the next run.
local function level()
    return MASTER * Sfx.volume
end

-- How far a play may wander from written pitch, by default. Wide enough to
-- stop three staples in a row sounding stamped out, narrow enough that a
-- ruler still sounds like the ruler.
local PITCH_LO, PITCH_HI = 0.92, 1.08

-- gain: what the file's samples are multiplied by at load, to bring every
-- sound to one level. Re-measure rather than nudge: these came off the files.
-- loop: decoded the same way but played as one looping voice (Sfx.startLoop).
-- gap: the least time between two plays of it (Sfx.play).
-- pitch: the range a play may wander over, for the rows that want more drift
-- than PITCH_LO..PITCH_HI gives.
local DEFS = {
    accept      = { gain = 1.80 },
    transition  = { gain = 0.98 },
    transition2 = { gain = 0.48 },

    -- The draft's two doors, and the reason they are not two more transitions:
    -- the draft is the one screen a run is *interrupted* by rather than walked
    -- to, so a level landing mid-fight is worth announcing in a voice the menus
    -- do not use, and the way back out is worth closing in the same voice.
    levelup_enter = { gain = 0.18 },
    levelup_exit  = { gain = 0.15 },

    -- What happens to you, and what you walk onto. `hurt` sounds where the page
    -- is knocked (Player:hurt) because they are one event, and `item` covers all
    -- three of the things lying out there (src/pickup.lua) because from where
    -- the player is standing they are one kind of thing -- a prize reached.
    -- Both are rare enough to sit at the common level.
    hurt        = { gain = 0.26 },
    item        = { gain = 0.15 },

    -- The two that repeat -- see the head of this file. The gain is written as
    -- the level-matched figure times the duck rather than as the product, so a
    -- re-measure still lands on the first number and the decision to sit under
    -- it stays a separate thing you can see and argue with. The hit ducks
    -- further than the gem because it happens more often: a kill pays out one
    -- gem and takes as many hits as it takes.
    gem         = { gain = 0.22 * 0.55, gap = 0.05, pitch = { 0.88, 1.16 } },
    gethit      = { gain = 0.55 * 0.45, gap = 0.06, pitch = { 0.85, 1.15 } },

    ruler       = { gain = 0.23 },
    pin         = { gain = 1.10 },
    stapler     = { gain = 0.79 },
    glue1       = { gain = 2.40 },
    glue2       = { gain = 3.39 },

    brush1      = { gain = 0.69 },
    brush2      = { gain = 0.95 },
    brush3      = { gain = 1.70 },
    brush4      = { gain = 1.58 },
    brush5      = { gain = 1.68 },
    brush6      = { gain = 1.44 },

    -- The rubbing loop is nearly silent as recorded and plays for as long as
    -- the finger is down, so it is boosted a very long way and then aimed a
    -- little *under* the one-shots: it is ground for the eraser pop to land
    -- on, not an event of its own.
    rubbing     = { gain = 59, loop = true },
    eraser      = { gain = 0.89 },
}

-- The swishes in play order: fastest stroke first, and each one longer than
-- the last. Sfx.brushForSpeed and Sfx.brushFor both walk this list.
local BRUSHES = { "brush1", "brush2", "brush3", "brush4", "brush5", "brush6" }

-- A flick and a careful line are different sounds. The thresholds are in
-- canvas pixels a second of line actually laid down: the player walks at 58,
-- so the long swishes belong to a nib moving about walking pace and the short
-- ones to a stroke thrown across the screen.
local BRUSH_SPEEDS = { 360, 260, 180, 110, 60 }

local sounds = {}

-- Decode, scale in place, and clamp -- a gain over 1 may push a stray peak
-- past full scale, and a clipped sample is quieter trouble than a wrapped one.
local function loadOne(name, def)
    local data = love.sound.newSoundData(DIR .. name .. ".mp3")

    local gain = def.gain or 1
    if gain ~= 1 then
        local total = data:getSampleCount() * data:getChannelCount()
        for i = 0, total - 1 do
            local s = data:getSample(i) * gain
            data:setSample(i, s > 1 and 1 or (s < -1 and -1 or s))
        end
    end

    local base = love.audio.newSource(data, "static")
    if def.loop then base:setLooping(true) end

    sounds[name] = {
        base = base,
        duration = data:getDuration(),
        loop = def.loop,
        gap = def.gap,
        -- Far enough back that the first play is never inside its own gap.
        lastAt = -math.huge,
        lo = def.pitch and def.pitch[1] or PITCH_LO,
        hi = def.pitch and def.pitch[2] or PITCH_HI,
        voices = {},
    }
end

--- the track ----------------------------------------------------------------

-- One file, streamed, looping, and playing from the frame the program has read
-- its options to the frame it quits (src/game.lua). It is not a row in DEFS and
-- could not be: every sound above is decoded whole so its samples can be scaled
-- in place, which for four minutes of music is a hundred megabytes of RAM spent
-- to save a multiply. So this is the one voice in the game brought to level by
-- its Source's volume instead, and it can be because the file arrived mastered
-- to full scale -- the only direction a gain has to take it is down, which is
-- the very thing that made scaling the quiet foley in place necessary.
--
-- MUSIC_GAIN was struck the way the gains above were, off the loudest 300ms:
-- ost.mp3 sits at 0.19 RMS there against about 0.056 for every effect in the
-- game, so 0.29 is the track playing at exactly the level an effect plays at.
-- That is the reference point and not the answer -- how far under the effects the
-- bed actually sits is `Sfx.music`, which belongs to the player. Re-measure
-- rather than nudge.
local MUSIC = "src/music/ost.mp3"
local MUSIC_GAIN = 0.29

local track

local function musicLevel()
    return MASTER * MUSIC_GAIN * Sfx.music
end

function Sfx.load()
    for name, def in pairs(DEFS) do
        loadOne(name, def)
    end

    track = love.audio.newSource(MUSIC, "stream")
    track:setLooping(true)
    track:setVolume(musicLevel())
end

-- Started separately from being built, because the level it starts at is read off
-- disk (src/options.lua) and that happens once every voice in the game exists.
function Sfx.startMusic()
    if not track then return end
    track:setVolume(musicLevel())
    track:play()
end

--- off the page --------------------------------------------------------------

-- The page going out of sight takes the sound with it. SDL sends the window
-- MINIMIZED on the way out and RESTORED on the way back, which arrive here as
-- love.visible (main.lua). Visibility rather than focus is the honest line:
-- a minimised window is out of sight and goes quiet, while a window merely
-- clicked away from is still on the screen, still running its horde, and still
-- owes the player the sound of it.
--
-- This is the desktop's half of the problem, and the only half a game can reach.
-- A phone put in a pocket is the same bug and cannot be fixed from Lua at all:
-- Android blocks the thread the whole program runs on the moment the activity
-- pauses, and it blocks *inside* the event pump that posts MINIMIZED, so neither
-- that event nor any callback of ours is reached until the app is back on the
-- screen -- while OpenAL, mixing on a thread of its own, plays the bed on into
-- the pocket. That half is fixed in the engine instead: the APK's LOVE is
-- patched to pause the OpenAL device from an SDL event watch, the one thing that
-- does run inside the pause handler (love-android-audio.patch, beside
-- build-android.sh). What reaches this file on a phone is both events at once on
-- the way back in, which cancel each other out -- the audio is already sounding
-- again by then, and the run has already been put down.
--
-- `love.audio.pause()` with nothing named pauses every voice that is playing and
-- hands back the list of them, which is exactly the list to give love.audio.play
-- on the way back in: everything that was sounding resumes where it stopped, the
-- streamed track included, and everything that had already finished stays
-- finished. Pausing rather than turning the volume down is also what stops four
-- minutes of music being decoded to nobody for as long as the phone is away.
local silenced = false
local held = {}

function Sfx.silence()
    -- Guarded because a second pause would hand back an empty list and lose the
    -- real one, and nothing promises the way out is signalled exactly once.
    if silenced then return end
    silenced = true
    held = love.audio.pause()
end

function Sfx.resume()
    if not silenced then return end
    silenced = false
    if #held > 0 then love.audio.play(held) end
    held = {}
end

-- A stopped voice is reused rather than left for the collector: a busy stroke
-- retriggers a few times a second and should not shed a Source every time.
local function freeVoice(sound)
    for _, v in ipairs(sound.voices) do
        if not v:isPlaying() then return v end
    end
    local v = sound.base:clone()
    sound.voices[#sound.voices + 1] = v
    return v
end

-- One play. `pitch` overrides the default wander for the caller that has a
-- pitch in mind (the compass, fitting a swish to its own swing); everything
-- else takes the drift written on the sound's own row, or the few percent every
-- other sound takes, which is what keeps repeats from stamping.
-- Returns the voice, so a caller can ask isPlaying() before starting another.
function Sfx.play(name, pitch)
    -- Nothing new starts while the page is away. It cannot on the phone, where
    -- the program is not running at all, but a minimised desktop window plays
    -- its run out -- and a voice started then is one `held` has never heard of,
    -- sounding on into a window nobody is looking at.
    if silenced then return end

    local sound = sounds[name]
    if not sound then return end

    -- Too soon after the last one of this name, on the rows that ask for a gap.
    -- Dropped rather than queued, which is the whole point: a volley that landed
    -- on six bodies in one frame is one thing that happened, and six of one
    -- sound stacked on one instant is louder than any of them and says less. It
    -- also caps the voice pool -- `freeVoice` clones whenever nothing is free,
    -- and an unthrottled hit would shed a Source per body per frame.
    --
    -- Measured on the wall clock rather than on the run's, because a sound
    -- belongs to what you can hear and not to what the page is doing: a frame
    -- that took twice as long is still one moment to the ear.
    if sound.gap then
        local now = love.timer.getTime()
        if now - sound.lastAt < sound.gap then return end
        sound.lastAt = now
    end

    local v = freeVoice(sound)
    v:setPitch(pitch or (sound.lo + love.math.random() * (sound.hi - sound.lo)))
    v:setVolume(level())
    v:play()
    return v
end

function Sfx.duration(name)
    local sound = sounds[name]
    return sound and sound.duration or 0
end

-- A voice being cut off, and how fast. The finger coming off the page ends the
-- swish *now* -- a stroke you have stopped drawing must not go on sounding
-- drawn -- but a Source stopped dead mid-wave clicks, so "now" is a fade just
-- long enough to not be one: over in a few hundredths, under any ear's notice
-- as a fade.
local CUT_TIME = 0.05
local fading = {}

function Sfx.cut(voice)
    if voice and voice:isPlaying() then
        fading[#fading + 1] = voice
    end
end

-- The two voices that can be *playing* while a bar is dragged, retuned where
-- they stand: everything else is over in a fraction of a second and the next one
-- is already at the new level.
--
-- The track is always one of them, which is what makes the music bar the only
-- control on the settings page that demonstrates itself. It is left playing at
-- zero rather than stopped, and that is deliberate: a stopped stream comes back
-- at the top of the file, so dragging the bar down and up again would restart the
-- music instead of turning it back on. The cost is decoding a stream nobody can
-- hear.
--
-- The rubbing loop is the other, and only while it is not being cut: a fade is a
-- volume on its way to zero and must not be argued back up.
function Sfx.retune()
    if track then track:setVolume(musicLevel()) end

    for _, sound in pairs(sounds) do
        if sound.loop then
            local v = sound.voices[1]
            if v and v:isPlaying() then
                local cutting = false
                for _, f in ipairs(fading) do cutting = cutting or f == v end
                if not cutting then v:setVolume(level()) end
            end
        end
    end
end

-- Runs every frame whatever the game is doing, so a cut started on the last
-- frame of a state still finishes. A faded voice is stopped, which is what
-- hands it back to its pool.
--
-- The page going out of sight is the one thing that holds it, and the reason is
-- that stop: a voice stopped while it is on the held list is one love.audio.play
-- would start again from the top on the way back in. So a fade waits where it
-- stands and finishes when the page returns -- which on a phone is no wait at
-- all, nothing here running while the program is frozen anyway.
function Sfx.update(dt)
    if silenced then return end

    for i = #fading, 1, -1 do
        local v = fading[i]
        local vol = v:getVolume() - level() * dt / CUT_TIME
        if vol <= 0 or not v:isPlaying() then
            v:stop()
            table.remove(fading, i)
        else
            v:setVolume(vol)
        end
    end
end

-- The loop is one voice, started and stopped rather than fired: there is only
-- ever one finger rubbing. The pitch is rolled at the start and held for the
-- whole rub -- a loop that wandered mid-stroke would sound like a hand
-- changing size.
function Sfx.startLoop(name)
    if silenced then return end  -- as Sfx.play: nothing starts off the page

    local sound = sounds[name]
    if not sound then return end

    local v = sound.voices[1]
    if not v then
        v = sound.base:clone()
        sound.voices[1] = v
    end
    v:setPitch(sound.lo + love.math.random() * (sound.hi - sound.lo))
    v:setVolume(level())
    v:play()
end

-- Safe to call with nothing playing, so every route that can end a stroke may
-- call it without asking first.
function Sfx.stopLoop(name)
    local sound = sounds[name]
    local v = sound and sound.voices[1]
    if v then v:stop() end
end

-- The swish whose length best fits `seconds`, pitched to fit it exactly: a
-- pitch shift is a speed change, so a 0.78s swish at 0.98 lasts the compass's
-- 0.8s swing. Clamped to what still sounds like the same brush.
function Sfx.brushFor(seconds)
    local best, bestDiff
    for _, name in ipairs(BRUSHES) do
        local diff = math.abs(Sfx.duration(name) - seconds)
        if not bestDiff or diff < bestDiff then best, bestDiff = name, diff end
    end

    local pitch = Sfx.duration(best) / seconds
    pitch = pitch * (0.97 + love.math.random() * 0.06)
    return best, math.min(1.3, math.max(0.75, pitch))
end

-- The swish for a nib moving this fast, in canvas pixels of line a second.
function Sfx.brushForSpeed(speed)
    for i, at in ipairs(BRUSH_SPEEDS) do
        if speed >= at then return BRUSHES[i] end
    end
    return BRUSHES[#BRUSHES]
end

return Sfx
