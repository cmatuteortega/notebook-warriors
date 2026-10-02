# Renders the txt art onto the subject's own page, through the overprint table,
# and writes a scaled PNG. Not part of the game -- it is here so a drawing can
# be looked at against the ruling it will actually be read against before it
# goes anywhere near src/sprites.lua.
#
#   python3 art/preview.py music
import sys, zlib, struct, os

PAL = {'w':(0xe6,0xec,0xef),'g':(0xb2,0xb1,0xc0),'s':(0x5b,0x4f,0x6e),
       'o':(0x28,0x07,0x32),'r':(0xe1,0x5e,0x6e),'k':(0xf3,0xa8,0xa8),
       'b':(0x71,0x94,0xf0),'c':(0xab,0xc9,0xf1)}
# mark x surface -> what comes out. src/palette.lua, blank/ruled/margin columns
# -- the ruled and margin columns are identical there, so 'k' reuses 'c'.
OVER = {'w':{'w':'w','c':'w'},'g':{'w':'g','c':'s'},'s':{'w':'s','c':'o'},
        'o':{'w':'o','c':'o'},'c':{'w':'c','c':'b'},'b':{'w':'b','c':'s'},
        'k':{'w':'k','c':'r'},'r':{'w':'r','c':'s'}}
for _mark in OVER: OVER[_mark]['k'] = OVER[_mark]['c']

def staves(x, y):                      # STAVES in src/subjects.lua
    at = y % 40
    if at < 20 and at % 4 == 0: return 'c'
    if x % 192 == 24 and at <= 16: return 'c'
    return 'w'

def squared(x, y):                     # SQUARED in src/subjects.lua
    if x % 10 == 0 or y % 10 == 0: return 'c'
    if 24 <= x % 180 < 26: return 'c'
    return 'w'

def ruled(x, y):                       # RULED in src/subjects.lua
    if y % 10 < 2: return 'c'
    if x % 192 == 24: return 'k'
    return 'w'

def grouped(x, y):                     # GROUPED in src/subjects.lua
    at = y % 30
    if at < 2 or (10 <= at < 12): return 'c'
    if x % 192 == 24: return 'k'
    return 'w'

def calendar(x, y):                    # CALENDAR in src/subjects.lua
    if y % 24 < 2: return 'c'
    if x % 224 == 0: return 'k'
    if x % 32 == 0: return 'c'
    return 'w'

def ledger(x, y):                      # LEDGER in src/subjects.lua
    lx, ly = x % 210, y % 128
    if ly < 8: return 'c'
    if lx < 10: return 'c'
    if (ly - 8) % 12 == 0: return 'c'
    if (lx - 10) % 40 == 0: return 'c'
    return 'w'

def blank(x, y):                       # BLANK in src/subjects.lua
    lx, ly = x % 192, y % 100
    def punch(cx, cy):
        dx, dy = lx - cx, ly - cy
        d2 = dx * dx + dy * dy
        return 6.25 <= d2 <= 12.25
    if punch(24, 8) or punch(24, 58): return 'c'
    return 'w'

# Each subject renders on its own page (src/subjects.lua): a re-skin is judged
# against the page it will actually be read on.
#
# `vanilla` is the exception: it is not a re-skin of anything, it is the crowd
# every other page falls back to, and the page it is read on is the science one
# it was drawn for.
PAGES = {'music': staves, 'vanilla': ruled, 'maths': squared, 'pe': calendar,
         'language': grouped, 'finance': ledger, 'art': blank}
ORDER = ['blob', 'bat', 'wad', 'blot', 'drop', 'skull', 'bulb', 'eye',
         'grin', 'redeye']
# The enemy each skin replaces: grid size, and the shadow width off the row in
# Enemy.types. A skin may be drawn bigger, and where it stands is derived the way
# Sprites.load derives it -- ox/oy pinned to the base -- so what this draws is
# where the game puts it, headroom and all.
BASE = {'blob': (8, 8, 6), 'bat': (11, 7, 7), 'wad': (9, 9, 7),
        'blot': (10, 9, 9), 'drop': (6, 7, 5), 'skull': (10, 10, 8),
        'bulb': (9, 10, 8), 'eye': (11, 11, 9), 'grin': (14, 14, 13),
        'redeye': (11, 11, 9)}

def load(path):
    rows = []
    for line in open(path):
        line = line.rstrip('\n').rstrip()
        if line[:1] != '#': rows.append(line)
    return rows

def png(path, px, w, h, scale):
    raw = b''
    for y in range(h * scale):
        raw += b'\x00'
        for x in range(w * scale):
            raw += bytes(px[y // scale][x // scale])
    def chunk(tag, data):
        c = tag + data
        return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c))
    out = b'\x89PNG\r\n\x1a\n'
    out += chunk(b'IHDR', struct.pack('>IIBBBBB', w * scale, h * scale, 8, 2, 0, 0, 0))
    out += chunk(b'IDAT', zlib.compress(raw, 9))
    out += chunk(b'IEND', b'')
    open(path, 'wb').write(out)

subject = sys.argv[1] if len(sys.argv) > 1 else 'music'
page = PAGES.get(subject, staves)
art = {n: load('art/%s/%s.txt' % (subject, n))
       for n in ORDER if os.path.exists('art/%s/%s.txt' % (subject, n))}

def place(name, rows):
    """Where the sprite sits relative to its origin, as Sprites.load pins it."""
    bw, bh, shadow = BASE[name]
    h, w = len(rows), len(rows[0])
    oy = bh // 2 + (h - bh)
    ox = bw // 2 + (w - bw) // 2
    return ox, oy, shadow

PAD, GAP, SCALE = 6, 7, 9
placed = [(n, art[n]) + place(n, art[n]) for n in ORDER if n in art]

# One baseline for the lot, so the headroom shows as headroom: the tallest thing
# above its own origin sets the top, and the shadows all land on the same row.
above = max(oy for _, _, _, oy, _ in placed)
below = max(len(r) - oy for _, r, _, oy, _ in placed)
H = PAD * 2 + above + below
W = PAD * 2 + sum(len(r[0]) for _, r, _, _, _ in placed) + GAP * (len(placed) - 1)
# Two layers, the way src/overprint.lua has them: the page underneath, and one
# ink layer over it where a later mark simply covers an earlier one. Marks stack
# against the *page* and never against each other, which is why the shadow goes
# in here rather than being blended into the paper.
#
# The body is the exception and does not stack at all: a monster is standing on
# the page rather than printed into it, so in the game it blanks its own
# silhouette out of the page layer first (Overprint.beginSolid) and the ruling
# stops at its edge. That is done below by writing paper into `surface` under
# every opaque pixel of the drawing -- which is what makes this preview worth
# looking at, since it is the one place the ruling still shows.
surface = [[page(x, y) for x in range(W)] for y in range(H)]
ink = [[None] * W for _ in range(H)]
baseline = PAD + above

x0 = PAD
for name, rows, ox, oy, shadow in placed:
    # The shadow first, so ink laid over it stacks the way the game's does.
    sy = baseline + len(rows) - oy - 1
    for x in range(shadow):
        gx = x0 + ox - shadow // 2 + x
        if 0 <= gx < W: ink[sy][gx] = 'g'
    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch == '.': continue
            ink[baseline - oy + y][x0 + x] = ch
            # Standing on the ruling, not printed into it. The shadow is left out
            # of this on purpose: it is the one part of the drawing that really is
            # on the paper.
            surface[baseline - oy + y][x0 + x] = 'w'
    x0 += len(rows[0]) + GAP

grid = [[OVER[ink[y][x]][surface[y][x]] if ink[y][x] else surface[y][x]
         for x in range(W)] for y in range(H)]

px = [[PAL[c] for c in row] for row in grid]
out = 'art/%s.png' % subject
png(out, px, W, H, SCALE)
print('%s  %dx%d at %dx' % (out, W, H, SCALE))
