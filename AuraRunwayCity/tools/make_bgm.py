#!/usr/bin/env python3
"""
Aura Runway background music — two ORIGINAL tracks, synthesised from scratch
(no samples, no third-party music => 100% license-free, you own it).

  1. "Blush Café"  – relaxing lofi / jazzy electric piano, 78 BPM
  2. "Runway Glow" – upbeat, soft fashion-house groove, 116 BPM

Both are written into ONE file, build/AuraMusic.ogg, and a region map is
written to src/shared/MusicTracks.luau. Upload the .ogg to Roblox once and put
its id in Config.BGMId.

Usage: python3 tools/make_bgm.py
"""
import os
import numpy as np
from scipy import signal
import soundfile as sf

SR = 44100
rng = np.random.default_rng(7)


def hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def lp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = signal.butter(order, f / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), hi / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def env(n, a=0.005, d=0.3, s=0.0, r=0.05, hold=None):
    """attack / exponential decay towards sustain / release"""
    t = np.arange(n) / SR
    e = np.where(t < a, t / max(a, 1e-4), s + (1 - s) * np.exp(-(t - a) / max(d, 1e-4)))
    if hold is not None and hold < t[-1]:
        k = t >= hold
        e[k] *= np.exp(-(t[k] - hold) / max(r, 1e-4))
    return e


def reverb(x, seconds=1.8, mix=0.25, bright=4000):
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / SR * (6.0 / seconds))
    ir = lp(ir, bright)
    ir[: int(0.012 * SR)] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    wet = signal.fftconvolve(x, ir)[: len(x)]
    return x * (1 - mix) + wet * mix * 0.9


class Track:
    def __init__(self, seconds):
        self.n = int(seconds * SR) + SR * 4  # tail room, wrapped later
        self.buses = {}

    def bus(self, name):
        if name not in self.buses:
            self.buses[name] = np.zeros(self.n)
        return self.buses[name]

    def add(self, name, t, x, gain=1.0):
        b = self.bus(name)
        i = int(t * SR)
        if i >= self.n:
            return
        j = min(self.n, i + len(x))
        b[i:j] += x[: j - i] * gain


# ------------------------------------------------------------------ voices
def rhodes(m, dur, vel=0.7):
    n = int((dur + 1.2) * SR)
    t = np.arange(n) / SR
    f = hz(m)
    idx = 1.4 * vel * np.exp(-t / 0.35) + 0.25
    mod = np.sin(2 * np.pi * f * t)
    body = np.sin(2 * np.pi * f * t + idx * mod)
    tine = 0.12 * vel * np.sin(2 * np.pi * f * 7.0 * t) * np.exp(-t / 0.05)
    x = (body + tine) * env(n, 0.004, 1.6, 0.18, 0.35, hold=dur)
    x *= 1 + 0.12 * np.sin(2 * np.pi * 4.2 * t)  # soft tremolo
    return lp(x, 2600) * vel


def softlead(m, dur, vel=0.5):
    n = int((dur + 0.4) * SR)
    t = np.arange(n) / SR
    f = hz(m)
    vib = 1 + 0.004 * np.sin(2 * np.pi * 5.0 * t) * np.clip(t / 0.3, 0, 1)
    ph = 2 * np.pi * np.cumsum(f * vib) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    x += 0.02 * lp(rng.standard_normal(n), 3000)  # breath
    return lp(x * env(n, 0.06, 0.9, 0.55, 0.2, hold=dur), 3200) * vel


def upright_bass(m, dur, vel=0.8):
    n = int((dur + 0.3) * SR)
    t = np.arange(n) / SR
    f = hz(m)
    x = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(4 * np.pi * f * t) * np.exp(-t / 0.15)
    x = np.tanh(1.4 * x)
    return lp(x * env(n, 0.01, 0.7, 0.25, 0.12, hold=dur), 900) * vel


def saw(f, t, detune=0.0):
    ph = (f * (1 + detune)) * t
    return 2 * (ph - np.floor(ph + 0.5))


def pad(ms, dur, vel=0.5, cutoff=1800):
    n = int((dur + 0.8) * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for m in ms:
        f = hz(m)
        for d in (-0.004, 0.0, 0.0045):
            x += saw(f, t + rng.random(), d)
    x /= len(ms) * 3
    x = lp(x, cutoff, 2)
    return x * env(n, 0.35, 1.0, 0.85, 0.5, hold=dur) * vel


def pluck(m, vel=0.5, cutoff=3200):
    n = int(0.5 * SR)
    t = np.arange(n) / SR
    f = hz(m)
    x = 0.6 * saw(f, t) + 0.4 * np.sign(np.sin(2 * np.pi * f * t)) * 0.5
    x = lp(x, cutoff, 2) * np.exp(-t / 0.11)
    return x * vel


def synth_bass(m, dur, vel=0.8):
    n = int((dur + 0.05) * SR)
    t = np.arange(n) / SR
    f = hz(m)
    x = 0.7 * np.sin(2 * np.pi * f * t) + 0.3 * lp(saw(f, t), 700)
    return np.tanh(1.3 * x) * env(n, 0.004, 0.22, 0.5, 0.03, hold=dur) * vel


def kick(soft=True):
    n = int(0.45 * SR)
    t = np.arange(n) / SR
    f = 48 + 70 * np.exp(-t / 0.035)
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / (0.22 if soft else 0.3))
    click = lp(rng.standard_normal(n), 1800) * np.exp(-t / 0.004) * 0.15
    return lp(x + click, 3000)


def snare_brush():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    x = bp(rng.standard_normal(n), 900, 5000) * np.exp(-t / 0.09)
    x += 0.3 * np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.05)
    return lp(x, 4500) * 0.6


def clap():
    n = int(0.4 * SR)
    t = np.arange(n) / SR
    nz = bp(rng.standard_normal(n), 900, 3800)
    e = np.zeros(n)
    for k, off in enumerate((0.0, 0.011, 0.022)):
        i = int(off * SR)
        e[i:] += np.exp(-(t[i:] - off) / (0.012 if k < 2 else 0.12))
    return lp(nz * e, 6000) * 0.5


def hat(open_=False):
    n = int((0.25 if open_ else 0.08) * SR)
    t = np.arange(n) / SR
    x = hp(rng.standard_normal(n), 7500) * np.exp(-t / (0.07 if open_ else 0.018))
    return lp(x, 11000) * 0.35


def shaker():
    n = int(0.07 * SR)
    t = np.arange(n) / SR
    x = bp(rng.standard_normal(n), 5000, 10000) * np.sin(np.pi * t / t[-1]) ** 2
    return x * 0.18


# ------------------------------------------------------------------ helpers
def chord_notes(root, quality):
    Q = {
        "maj9": [0, 4, 7, 11, 14],
        "maj7": [0, 4, 7, 11],
        "m7": [0, 3, 7, 10],
        "m9": [0, 3, 7, 10, 14],
        "9sus": [0, 5, 7, 10, 14],
        "7": [0, 4, 7, 10],
        "m": [0, 3, 7],
        "M": [0, 4, 7],
        "add9": [0, 4, 7, 14],
    }
    return [root + i for i in Q[quality]]


def finish(tr, loop_s, master_lp=10000, peak=0.8):
    mix = np.zeros(tr.n)
    for x in tr.buses.values():
        mix += x
    mix = hp(mix, 30)
    mix = lp(mix, master_lp)
    # wrap the tail onto the start so the loop is seamless
    L = int(loop_s * SR)
    tail = mix[L:]
    out = mix[:L].copy()
    out[: len(tail)] += tail[: L]
    # gentle glue: soft-knee saturation then normalise
    out = np.tanh(out / (np.max(np.abs(out)) + 1e-9) * 1.6) / np.tanh(1.6)
    out *= peak / (np.max(np.abs(out)) + 1e-9)
    return out


# ------------------------------------------------------------------ track 1
def blush_cafe():
    bpm = 78
    beat = 60 / bpm
    bar = 4 * beat
    swing = 0.14 * beat  # lazy swung 8ths
    prog = [(53, "maj9"), (52, "m7"), (50, "m9"), (48, "maj9"), (46, "maj7"), (45, "m7"), (43, "m9"), (48, "9sus")]
    bars = 32
    tr = Track(bars * bar)
    for b in range(bars):
        t0 = b * bar
        root, q = prog[b % 8]
        notes = [n + 12 for n in chord_notes(root, q)]
        # EP comping: beat 1 + the "and" of 2 (lazy strum)
        for k, n in enumerate(notes):
            tr.add("ep", t0 + k * 0.012, rhodes(n, bar * 0.55, 0.5), 0.28)
        if b % 2 == 1:
            for k, n in enumerate(notes[1:]):
                tr.add("ep", t0 + 1.5 * beat + swing + k * 0.01, rhodes(n + 0, beat * 1.2, 0.32), 0.2)
        # bass: root on 1, fifth on 3, walk-up pickup
        tr.add("bass", t0, upright_bass(root - 12, beat * 1.6, 0.9), 0.55)
        tr.add("bass", t0 + 2 * beat, upright_bass(root - 5, beat * 1.3, 0.75), 0.5)
        nxt = prog[(b + 1) % 8][0] - 12
        tr.add("bass", t0 + 3.5 * beat + swing, upright_bass(nxt - 1, beat * 0.4, 0.5), 0.35)
        # drums (soft, brushed) — rest for the first 2 bars
        if b >= 2:
            tr.add("drums", t0, kick(), 0.55)
            tr.add("drums", t0 + 2.5 * beat + swing, kick(), 0.35)
            tr.add("drums", t0 + beat, snare_brush(), 0.35)
            tr.add("drums", t0 + 3 * beat, snare_brush(), 0.35)
            for e in range(8):
                tt = t0 + e * beat / 2 + (swing if e % 2 else 0)
                tr.add("drums", tt, hat(), 0.16 if e % 2 else 0.1)
    # melody: gentle pentatonic phrases in bars 8-15 and 24-31
    phrase = [
        (0, 72, 1.0), (1, 74, 0.5), (1.5, 77, 1.5), (4, 76, 1.0), (5, 74, 1.0), (6, 72, 2.0),
        (8, 69, 1.0), (9, 72, 0.5), (9.5, 74, 1.5), (12, 72, 1.0), (13, 70, 1.0), (14, 69, 2.0),
        (16, 77, 1.0), (17, 79, 0.5), (17.5, 81, 1.5), (20, 79, 1.0), (21, 77, 1.0), (22, 76, 2.0),
        (24, 74, 1.5), (25.5, 72, 0.5), (26, 70, 1.0), (27, 69, 1.0), (28, 72, 3.5),
    ]
    for start_bar in (8, 24):
        for (bt, m, d) in phrase:
            tr.add("lead", start_bar * bar + bt * beat, softlead(m, d * beat * 0.95, 0.5), 0.2)
    tr.buses["ep"] = reverb(tr.buses["ep"], 2.2, 0.3, 3500)
    tr.buses["lead"] = reverb(tr.buses["lead"], 2.4, 0.35, 3500)
    tr.buses["drums"] = reverb(lp(tr.buses["drums"], 7000), 0.9, 0.15)
    return finish(tr, bars * bar, master_lp=8500, peak=0.72)


# ------------------------------------------------------------------ track 2
def runway_glow():
    bpm = 116
    beat = 60 / bpm
    bar = 4 * beat
    s16 = beat / 4
    prog = [(57, "m"), (53, "add9"), (48, "add9"), (55, "M")]  # Am  F  C  G
    bars = 32
    tr = Track(bars * bar)
    duck = np.ones(tr.n)
    for b in range(bars):
        t0 = b * bar
        root, q = prog[b % 4]
        notes = chord_notes(root, q)
        section = 0 if b < 4 else (1 if b < 16 else 2)
        # pad (always), ducked by the kick later
        tr.add("pad", t0, pad([n for n in notes] + [notes[0] + 12], bar, 0.5, 1500 if section == 0 else 2200), 0.32)
        # kick four-on-the-floor + sidechain envelope
        if section >= 1:
            for k in range(4):
                tk = t0 + k * beat
                tr.add("drums", tk, kick(soft=False), 0.62)
                i = int(tk * SR)
                w = int(0.24 * SR)
                if i + w < tr.n:
                    duck[i : i + w] = np.minimum(duck[i : i + w], 0.45 + 0.55 * (np.arange(w) / w) ** 0.7)
            tr.add("drums", t0 + beat, clap(), 0.4)
            tr.add("drums", t0 + 3 * beat, clap(), 0.4)
            # bass on the offbeats
            for k in range(4):
                tr.add("bass", t0 + k * beat + beat / 2, synth_bass(root - 24 if root > 50 else root - 12, beat * 0.42, 0.8), 0.5)
        for k in range(4):
            tr.add("drums", t0 + k * beat + beat / 2, hat(open_=True), 0.11 if section else 0.07)
        for k in range(16):
            tr.add("drums", t0 + k * s16, shaker(), 0.22 if k % 2 else 0.12)
        # pluck arpeggio (up-down)
        if section >= 1:
            arp = [notes[0] + 12, notes[1] + 12, notes[2] + 12, notes[0] + 24, notes[2] + 12, notes[1] + 12]
            for k in range(16):
                if k % 4 == 3 and section == 1:
                    continue
                tr.add("arp", t0 + k * s16, pluck(arp[k % len(arp)], 0.5), 0.2)
    # lead hook in the last 16 bars (catchy, simple, in A minor)
    hook = [
        (0, 76, 0.75), (0.75, 74, 0.75), (1.5, 72, 1.0), (2.5, 69, 1.5),
        (4, 72, 0.75), (4.75, 74, 0.75), (5.5, 76, 1.0), (6.5, 79, 1.5),
        (8, 77, 0.75), (8.75, 76, 0.75), (9.5, 74, 1.0), (10.5, 72, 1.5),
        (12, 74, 1.0), (13, 76, 1.0), (14, 71, 2.0),
    ]
    for rep in (16, 20, 24, 28):
        for (bt, m, d) in hook:
            tr.add("lead", rep * bar + bt * beat, softlead(m, d * beat * 0.9, 0.55), 0.17)
    # sidechain pump on pad + arp
    for k in ("pad", "arp"):
        tr.buses[k] *= duck
    # stereo-ish delay feel on the arp, then space
    arp = tr.buses["arp"]
    d = int(beat * 0.75 * SR)
    arp[d:] += 0.3 * arp[:-d]
    tr.buses["arp"] = reverb(arp, 1.4, 0.2, 5000)
    tr.buses["pad"] = reverb(tr.buses["pad"], 2.0, 0.25, 4000)
    tr.buses["lead"] = reverb(tr.buses["lead"], 1.8, 0.3, 4500)
    tr.buses["drums"] = reverb(lp(tr.buses["drums"], 8500), 0.7, 0.08)
    return finish(tr, bars * bar, master_lp=9500, peak=0.7)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    a = blush_cafe()
    b = runway_glow()
    gap = np.zeros(int(0.5 * SR))
    out = np.concatenate([a, gap, b, gap])
    path = os.path.join(root, "build", "AuraMusic.ogg")
    # write in chunks (libsndfile's vorbis encoder can crash on huge single writes)
    with sf.SoundFile(path, "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        data = out.astype(np.float32)
        for i in range(0, len(data), SR):
            f.write(data[i : i + SR])
    la, lb = len(a) / SR, len(b) / SR
    sa = 0.0
    sb = la + 0.5
    lua = [
        "--!nonstrict",
        "-- AUTO-GENERATED by tools/make_bgm.py — regions inside build/AuraMusic.ogg (seconds).",
        "-- Original music made for this game: license-free.",
        "return {",
        f"\tDuration = {len(out) / SR:.3f},",
        f'\tCafe = {{ Name = "Blush Café", Start = {sa:.3f}, Length = {la:.3f} }},',
        f'\tRunway = {{ Name = "Runway Glow", Start = {sb:.3f}, Length = {lb:.3f} }},',
        "}",
        "",
    ]
    with open(os.path.join(root, "src", "shared", "MusicTracks.luau"), "w") as f:
        f.write("\n".join(lua))
    print(f"wrote {path}: {len(out) / SR:.1f}s ({os.path.getsize(path) / 1e6:.2f} MB)  cafe={la:.1f}s runway={lb:.1f}s")


if __name__ == "__main__":
    main()
