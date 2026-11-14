"""Original instrumental bed for the Matscape films (synthesised, no samples).
Calm 'precise instrument' feel: soft pad, plucked arpeggio, light pulse.
Usage: python3 make_music.py <seconds> <out.wav> [calm|pulse] [cut times, comma-separated]
'pulse' is a brighter, faster variant; cut times add a soft whoosh into each cut."""
import math, random, struct, sys, wave

SR = 44100
secs = float(sys.argv[1]); out = sys.argv[2]
n = int(SR * secs)
L = [0.0] * n; R = [0.0] * n
style = sys.argv[3] if len(sys.argv) > 3 else 'calm'
cuts = [float(x) for x in sys.argv[4].split(',')] if len(sys.argv) > 4 and sys.argv[4] else []
random.seed(7 if style == 'calm' else 23)
bpm = 96.0 if style == 'calm' else 112.0; beat = 60.0 / bpm; bar = 4 * beat
# Cmaj9 · Am9 · Fmaj7#11 · G6 — two-bar loop of four chords (one per bar)
chords = [[48, 55, 64, 71, 74], [45, 52, 60, 67, 71], [41, 48, 57, 64, 71], [43, 50, 59, 64, 69]]
if style == 'pulse':  # Dmaj9 · Bm9 · Gmaj7 · Asus/E
    chords = [[50, 57, 66, 73, 76], [47, 54, 62, 69, 73], [43, 50, 59, 66, 69], [45, 52, 61, 64, 71]]
f = lambda m: 440.0 * 2 ** ((m - 69) / 12.0)

def add(buf_l, buf_r, start, data, pan):
    gl = math.cos(pan * math.pi / 2); gr = math.sin(pan * math.pi / 2)
    s = int(start * SR)
    for i, v in enumerate(data):
        j = s + i
        if 0 <= j < n:
            buf_l[j] += v * gl; buf_r[j] += v * gr

def pad(freq, dur, amp):
    m = int(dur * SR); a = int(0.9 * SR); r = int(1.2 * SR)
    out = []
    for i in range(m):
        t = i / SR
        env = min(1.0, i / a) * (1.0 if i < m - r else max(0.0, (m - i) / r))
        v = math.sin(2 * math.pi * freq * t) + 0.5 * math.sin(2 * math.pi * freq * 1.003 * t) + 0.18 * math.sin(2 * math.pi * freq * 2 * t)
        out.append(amp * env * v)
    return out

def pluck(freq, amp):
    m = int(0.9 * SR); out = []
    for i in range(m):
        t = i / SR
        env = math.exp(-t * 5.5) * min(1.0, i / 60.0)
        v = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(2 * math.pi * freq * 2 * t) * math.exp(-t * 9) + 0.12 * math.sin(2 * math.pi * freq * 3 * t) * math.exp(-t * 14)
        out.append(amp * env * v)
    return out

def kick(amp):
    m = int(0.22 * SR); out = []; ph = 0.0
    for i in range(m):
        t = i / SR
        fr = 48 + 70 * math.exp(-t * 28)
        ph += 2 * math.pi * fr / SR
        out.append(amp * math.sin(ph) * math.exp(-t * 16))
    return out

def tick(amp):
    m = int(0.05 * SR); out = []; prev = 0.0
    for i in range(m):
        x = random.uniform(-1, 1); hp = x - prev; prev = x
        out.append(amp * hp * math.exp(-i / SR * 90))
    return out

nbars = int(math.ceil(secs / bar)) + 1
K = kick(0.42); T = tick(0.06)
for b in range(nbars):
    t0 = b * bar
    if t0 >= secs: break
    ch = chords[b % 4]
    for k, m in enumerate(ch[:4]):
        add(L, R, t0, pad(f(m), bar + 0.6, 0.035), 0.3 + 0.13 * k)
    # arpeggio: eighth notes walking up the chord an octave higher
    seq = [ch[1] + 12, ch[2] + 12, ch[3] + 12, ch[4] + 12, ch[3] + 12, ch[2] + 12, ch[4] + 12, ch[3] + 24]
    for s, m in enumerate(seq):
        add(L, R, t0 + s * beat / 2, pluck(f(m), 0.07 if s % 2 == 0 else 0.05), 0.25 if s % 2 == 0 else 0.75)
    if b >= 1:
        for q in range(4):
            if q % 2 == 0 or style == 'pulse': add(L, R, t0 + q * beat, K, 0.5)
            add(L, R, t0 + q * beat + beat / 2, T, 0.6)
            if style == 'pulse': add(L, R, t0 + q * beat + beat / 4 * 3, tick(0.03), 0.35)

def whoosh(dur, amp):
    m = int(dur * SR); out = []; lp = 0.0
    for i in range(m):
        k = i / m; x = random.uniform(-1, 1)
        a = 0.02 + 0.25 * k  # filter opens as it rises
        lp += a * (x - lp)
        out.append(amp * lp * (k ** 2) * (1 - max(0.0, (k - 0.92) / 0.08)))
    return out
for c in cuts:
    add(L, R, max(0.0, c - 0.55), whoosh(0.6, 0.5), 0.35)
    add(L, R, max(0.0, c - 0.55), whoosh(0.6, 0.5), 0.65)
    add(L, R, c, kick(0.3), 0.5)

# fades + gentle limiter
fi = int(0.4 * SR); fo = int(1.6 * SR)
peak = 1e-9
for i in range(n):
    g = min(1.0, i / fi) * min(1.0, (n - i) / fo)
    L[i] *= g; R[i] *= g
    peak = max(peak, abs(L[i]), abs(R[i]))
norm = 0.72 / peak
with wave.open(out, 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    frames = bytearray()
    for i in range(n):
        frames += struct.pack('<hh', int(max(-1, min(1, math.tanh(L[i] * norm * 1.2))) * 32000), int(max(-1, min(1, math.tanh(R[i] * norm * 1.2))) * 32000))
    w.writeframes(bytes(frames))
print('wrote', out, secs, 's')
