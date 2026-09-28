"""
Aura Runway City sound pack generator.

Synthesises every instrument sample (grand piano, acoustic guitar, electric
guitar, violin and a 9-piece drum kit) from scratch — no third-party audio,
so it is 100% yours to upload to Roblox.

Everything is written into ONE audio file (build/AuraSoundPack.ogg). The game
plays each note by jumping to its slice with Sound.PlaybackRegion, so you only
upload a single asset and paste a single ID into src/shared/Config.luau.

    pip install numpy scipy soundfile
    python tools/make_soundpack.py
"""
import json
import os
import numpy as np
from scipy import signal
import soundfile as sf

SR = 44100
GAP = 0.3  # silence between slices (s)
rng = np.random.default_rng(7)
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def midi_hz(m):
    return 440.0 * 2 ** ((m - 69) / 12)


def t_axis(sec):
    return np.arange(int(sec * SR)) / SR


def norm(x, peak=0.89):
    m = np.max(np.abs(x)) + 1e-9
    return x / m * peak


def fade(x, fin=0.002, fout=0.08):
    n_in, n_out = int(fin * SR), int(fout * SR)
    x = x.copy()
    if n_in:
        x[:n_in] *= np.linspace(0, 1, n_in)
    if n_out:
        x[-n_out:] *= np.linspace(1, 0, n_out)
    return x


def lp(x, hz, order=2):
    b, a = signal.butter(order, min(hz, SR * 0.45) / (SR / 2), "low")
    return signal.lfilter(b, a, x)


def hp(x, hz, order=2):
    b, a = signal.butter(order, hz / (SR / 2), "high")
    return signal.lfilter(b, a, x)


def bp(x, lo, hi, order=2):
    b, a = signal.butter(order, [lo / (SR / 2), min(hi, SR * 0.45) / (SR / 2)], "band")
    return signal.lfilter(b, a, x)


def peak_eq(x, f0, q, gain_db):
    a_ = 10 ** (gain_db / 40)
    w0 = 2 * np.pi * f0 / SR
    alpha = np.sin(w0) / (2 * q)
    b = [1 + alpha * a_, -2 * np.cos(w0), 1 - alpha * a_]
    a = [1 + alpha / a_, -2 * np.cos(w0), 1 - alpha / a_]
    return signal.lfilter(b, a, x)


def room(x, seconds=0.9, mix=0.12):
    """Small, soft room: exponentially decaying filtered noise impulse."""
    n = int(seconds * SR)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * seconds / 5))
    ir = lp(ir, 5000)
    ir[0] = 0
    ir = ir / np.sqrt(np.sum(ir ** 2))
    wet = signal.fftconvolve(x, ir)[: len(x)]
    return x + mix * wet * (np.max(np.abs(x)) / (np.max(np.abs(wet)) + 1e-9))


# ---------------------------------------------------------------- piano
def piano(m, dur=3.6, vel=0.8):
    f0 = midi_hz(m)
    t = t_axis(dur)
    B = 0.00012 * (1 + (m - 21) / 30) ** 2  # inharmonicity grows with pitch
    out = np.zeros_like(t)
    n_max = int(min(40, (SR * 0.45) / f0))
    strike = 1 / 7.5  # hammer position
    detunes = [-0.9, 0.0, 0.8] if m > 40 else ([-0.6, 0.6] if m > 28 else [0.0])
    for n in range(1, n_max + 1):
        fn = n * f0 * np.sqrt(1 + B * n * n)
        if fn > SR * 0.45:
            break
        amp = (abs(np.sin(np.pi * n * strike)) + 0.08) / n ** (1.25 - 0.35 * vel)
        tau_slow = (2.6 - (m - 36) * 0.022) / (1 + 0.14 * n)
        tau_fast = 0.35 / (1 + 0.25 * n)
        env = 0.45 * np.exp(-t / max(tau_fast, 0.02)) + 0.55 * np.exp(-t / max(tau_slow, 0.08))
        for d in detunes:
            f = fn * 2 ** (d / 1200)
            out += amp * env * np.sin(2 * np.pi * f * t + rng.uniform(0, 2 * np.pi)) / len(detunes)
    # hammer thump + felt noise
    n_h = int(0.012 * SR)
    ham = rng.standard_normal(n_h) * np.exp(-np.linspace(0, 6, n_h))
    ham = bp(ham, 300, 3000 + f0)
    out[:n_h] += ham * 0.25 * vel * np.max(np.abs(out))
    out = lp(out, 3500 + f0 * 4)  # brightness
    out = peak_eq(out, 220, 0.9, 2.5)  # soundboard warmth
    out = room(out, 1.1, 0.16)
    return fade(norm(out, 0.9), 0.001, 0.25)


# ---------------------------------------------------------------- plucked strings
def karplus(m, dur, damping, bright, pick_pos=0.18):
    f0 = midi_hz(m)
    n = int(dur * SR)
    # the two-point averaging loop filter adds half a sample of delay
    period = SR / f0 - 0.5
    N = int(np.floor(period))
    frac = period - N
    if frac < 0.1:  # keep the allpass coefficient well-behaved
        N -= 1
        frac += 1
    # allpass coefficient for fractional delay (tuning)
    c = (1 - frac) / (1 + frac)
    burst = rng.standard_normal(N)
    burst = lp(burst, bright)
    # pick position comb
    d = max(1, int(N * pick_pos))
    burst[d:] -= burst[:-d]
    buf = np.zeros(n + N + 2)
    buf[:N] = burst
    y = np.zeros(n)
    ap_x1 = 0.0
    ap_y1 = 0.0
    idx = N
    prev = 0.0
    for i in range(n):
        s = buf[i]
        # loop filter: averaging lowpass with damping
        v = damping * (0.5 * s + 0.5 * prev)
        prev = s
        # allpass fractional delay
        ap = c * v + ap_x1 - c * ap_y1
        ap_x1, ap_y1 = v, ap
        buf[idx] = ap
        idx += 1
        y[i] = s
    return y


def acoustic_guitar(m, dur=3.0):
    y = karplus(m, dur, 0.9965 - max(0, m - 60) * 0.00025, 6500, 0.16)
    # wooden body resonances
    body = 0.6 * y + 0.9 * bp(y, 90, 130) + 0.7 * bp(y, 190, 260) + 0.4 * bp(y, 380, 520)
    body = peak_eq(body, 2600, 1.2, 3)
    body = room(body, 0.8, 0.13)
    return fade(norm(body, 0.88), 0.0005, 0.3)


def electric_guitar(m, dur=3.2):
    y = karplus(m, dur, 0.9985 - max(0, m - 60) * 0.0002, 9000, 0.12)
    # single-coil pickup comb + presence
    d = int(SR * 0.00045)
    y = y[:]
    y[d:] += 0.6 * y[:-d]
    y = peak_eq(y, 1800, 1.0, 4)
    y = hp(y, 80)
    y = room(y, 0.6, 0.08)
    return fade(norm(y, 0.86), 0.0005, 0.3)


# ---------------------------------------------------------------- violin (bowed)
def violin(m, dur=5.0):
    f0 = midi_hz(m)
    t = t_axis(dur)
    vib_depth = np.clip((t - 0.35) / 0.6, 0, 1) * 0.28  # semitones, delayed vibrato
    vib = vib_depth * np.sin(2 * np.pi * 5.6 * t + 0.4 * np.sin(2 * np.pi * 0.7 * t))
    inst_f = f0 * 2 ** (vib / 12) * (1 + 0.002 * rng.standard_normal(len(t)).cumsum() / np.sqrt(len(t)))
    phase = 2 * np.pi * np.cumsum(inst_f) / SR
    # band-limited sawtooth (additive)
    x = np.zeros_like(t)
    for n in range(1, int((SR * 0.45) / f0) + 1):
        if n > 45:
            break
        x += np.sin(n * phase) / n * (1.0 if n < 12 else 0.7)
    env = np.clip(t / 0.14, 0, 1) ** 1.5 * (0.92 + 0.08 * np.sin(2 * np.pi * 0.5 * t))
    x *= env
    # bow noise
    noise = hp(rng.standard_normal(len(t)), 2500) * 0.02 * env
    x = x + noise * np.max(np.abs(x))
    # violin body formants + bridge hill
    y = 0.4 * x + 1.0 * bp(x, 250, 330) + 0.8 * bp(x, 420, 520) + 0.5 * bp(x, 900, 1300) + 1.1 * bp(x, 2400, 4200)
    y = lp(y, 7000)
    y = room(y, 1.4, 0.2)
    return fade(norm(y, 0.8), 0.003, 0.25)


# ---------------------------------------------------------------- drums
def env_exp(t, tau):
    return np.exp(-t / tau)


def metal(t, base=320):
    ratios = [1.0, 1.342, 1.2312, 1.6532, 1.9523, 2.1523]
    x = np.zeros_like(t)
    for r in ratios:
        x += signal.square(2 * np.pi * base * r * t + rng.uniform(0, 6))
    return x


def kick():
    t = t_axis(0.9)
    f = 45 + 110 * np.exp(-t / 0.045)
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env_exp(t, 0.32)
    click = hp(rng.standard_normal(len(t)), 1500) * env_exp(t, 0.004) * 0.4
    return fade(norm(lp(x + click, 5000)), 0.0005, 0.1)


def snare():
    t = t_axis(0.7)
    tone = (np.sin(2 * np.pi * 185 * t) + 0.5 * np.sin(2 * np.pi * 330 * t)) * env_exp(t, 0.07)
    noise = bp(rng.standard_normal(len(t)), 1200, 9000) * env_exp(t, 0.16)
    return fade(norm(room(0.6 * tone + 1.0 * noise, 0.5, 0.2)), 0.0005, 0.1)


def hat(open_=False):
    t = t_axis(1.2 if open_ else 0.35)
    x = hp(metal(t, 330) + 0.6 * rng.standard_normal(len(t)), 7000)
    x *= env_exp(t, 0.45 if open_ else 0.045)
    return fade(norm(x, 0.7), 0.0005, 0.1)


def cymbal(ride=False):
    t = t_axis(2.6 if not ride else 2.2)
    x = hp(metal(t, 440 if ride else 380) * (0.5 if ride else 0.8) + rng.standard_normal(len(t)), 4000 if ride else 3000)
    if ride:
        x += 0.5 * np.sin(2 * np.pi * 2350 * t) * env_exp(t, 0.6)
    x *= env_exp(t, 0.9 if ride else 1.3) * (1 - np.exp(-t / 0.003))
    return fade(norm(room(x, 1.0, 0.2), 0.7), 0.0005, 0.3)


def tom(hz):
    t = t_axis(0.9)
    f = hz * (1 + 0.5 * np.exp(-t / 0.05))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.sin(ph) * env_exp(t, 0.28) + 0.2 * bp(rng.standard_normal(len(t)), 300, 3000) * env_exp(t, 0.03)
    return fade(norm(room(x, 0.6, 0.15)), 0.0005, 0.12)


# ---------------------------------------------------------------- build pack
def main():
    slices = []  # (instrument, key, note, audio, loop)
    for m in range(36, 97, 6):
        slices.append(("Piano", "Piano", m, piano(m), None))
    for m in range(40, 77, 6):
        slices.append(("Guitar", "Guitar", m, acoustic_guitar(m), None))
    for m in range(40, 77, 6):
        slices.append(("Electric", "Electric", m, electric_guitar(m), None))
    for m in range(55, 92, 6):
        slices.append(("Violin", "Violin", m, violin(m), (1.0, 4.2)))
    drums = [
        ("Crash", cymbal(False)), ("Ride", cymbal(True)), ("HiHat", hat(False)), ("Tom1", tom(210)),
        ("Tom2", tom(160)), ("Floor", tom(105)), ("Snare", snare()), ("Kick", kick()), ("OpenHat", hat(True)),
    ]
    for name, audio in drums:
        slices.append(("Drums", name, None, audio, None))

    gap = np.zeros(int(GAP * SR))
    parts = [gap]
    cursor = GAP
    table = {"Piano": [], "Guitar": [], "Electric": [], "Violin": [], "Drums": {}}
    for inst, key, note, audio, loop in slices:
        start = cursor
        length = len(audio) / SR
        parts.append(audio.astype(np.float32))
        parts.append(gap)
        cursor += length + GAP
        entry = {"Start": round(start, 4), "Length": round(length, 4)}
        if loop:
            entry["LoopStart"] = round(start + loop[0], 4)
            entry["LoopEnd"] = round(start + loop[1], 4)
        if inst == "Drums":
            table["Drums"][key] = entry
        else:
            entry["Note"] = note
            table[inst].append(entry)
    pack = np.concatenate(parts)
    out_dir = os.path.join(ROOT, "build")
    os.makedirs(out_dir, exist_ok=True)
    ogg = os.path.join(out_dir, "AuraSoundPack.ogg")
    # libsndfile's Vorbis encoder can crash on huge single writes; stream in blocks
    with sf.SoundFile(ogg, "w", SR, 1, format="OGG", subtype="VORBIS") as f:
        for i in range(0, len(pack), 4096):
            f.write(pack[i : i + 4096])
    # Luau map
    lines = [
        "--!nonstrict",
        "-- AUTO-GENERATED by tools/make_soundpack.py — slice map of build/AuraSoundPack.ogg",
        "-- (times in seconds). Upload the .ogg once and paste its ID in Config.SoundPackId.",
        "return {",
        f"\tDuration = {round(cursor, 3)},",
    ]
    for inst in ["Piano", "Guitar", "Electric", "Violin"]:
        lines.append(f"\t{inst} = {{")
        for e in table[inst]:
            extra = ""
            if "LoopStart" in e:
                extra = f", LoopStart = {e['LoopStart']}, LoopEnd = {e['LoopEnd']}"
            lines.append(f"\t\t{{ Note = {e['Note']}, Start = {e['Start']}, Length = {e['Length']}{extra} }},")
        lines.append("\t},")
    lines.append("\tDrums = {")
    for k, e in table["Drums"].items():
        lines.append(f"\t\t{k} = {{ Start = {e['Start']}, Length = {e['Length']} }},")
    lines.append("\t},")
    lines.append("}")
    with open(os.path.join(ROOT, "src", "shared", "SoundPack.luau"), "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"wrote {ogg}: {cursor:.1f}s, {os.path.getsize(ogg) / 1e6:.2f} MB, {len(slices)} slices")
    # individual previews for listening
    prev = os.path.join(out_dir, "soundpack_preview")
    os.makedirs(prev, exist_ok=True)
    for inst, key, note, audio, loop in slices:
        name = f"{key}_{note}" if note is not None else key
        sf.write(os.path.join(prev, name + ".wav"), audio.astype(np.float32), SR)


if __name__ == "__main__":
    main()
