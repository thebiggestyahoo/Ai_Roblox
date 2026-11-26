"""Render original EggCourier loops and cues as upload-ready Ogg Vorbis files."""
import argparse
from array import array
import math
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory
import wave

RATE = 24000
TAU = math.tau
# World arrangements use independent note patterns, tempos, and harmonic colors.
# Each comprises eight two-beat phrases, with the final chord resolving into the loop.
MUSIC = {
    "Music": (116, (48, 45, 41, 43), (72, 76, 79, 76, 74, 72, 67, 71), "bell"),
    "temple": (100, (45, 41, 43, 40), (69, 72, 76, 74, 72, 69, 67, 68), "wood"),
    "pirate": (124, (50, 46, 53, 45), (74, 77, 81, 79, 77, 74, 72, 73), "reed"),
    "prehistoric": (108, (43, 46, 41, 38), (67, 70, 74, 70, 65, 69, 62, 65), "wood"),
    "factory": (132, (48, 51, 46, 43), (79, 75, 72, 67, 72, 75, 77, 71), "bell"),
    "frozen": (94, (50, 45, 46, 48), (86, 81, 77, 74, 82, 77, 79, 76), "bell"),
    "cloud": (106, (53, 48, 50, 46), (77, 81, 84, 81, 79, 77, 74, 76), "reed"),
    "neon": (138, (45, 48, 43, 40), (81, 77, 76, 72, 79, 76, 71, 68), "synth"),
    "galactic": (114, (47, 43, 50, 45), (83, 78, 74, 71, 81, 76, 73, 76), "synth"),
}
CUES = {
    "Countdown": ((68,), 0.16),
    "Start": ((67, 72, 79), 0.13),
    "Crack": ((38, 35), 0.045),
    "Break": ((44, 36, 29), 0.055),
    "Out": ((65, 61, 56), 0.11),
    "Restart": ((61, 65, 68), 0.08),
    "Coins": ((77, 81, 86), 0.055),
    "Shove": ((42, 37), 0.055),
    "Finish": ((72, 76, 79, 84), 0.12),
    "Victory": ((60, 67, 72, 76, 79, 84), 0.125),
    "Click": ((76,), 0.07),
    "CartonCommon": ((72, 76), 0.10),
    "CartonUncommon": ((67, 74, 79), 0.10),
    "CartonRare": ((72, 76, 79, 86), 0.11),
    "CartonEpic": ((64, 71, 76, 79, 83), 0.12),
    "CartonLegendary": ((60, 67, 72, 76, 79, 88), 0.14),
    "CartonMythic": ((59, 66, 71, 75, 78, 83, 90), 0.16),
}

def note(samples, start, duration, midi, volume, kind):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    begin = round(start * RATE)
    length = round(duration * RATE)
    for tick in range(length):
        time = tick / RATE
        phase = time * TAU * frequency
        attack = min(time / 0.018, 1)
        release = min((duration - time) / 0.08, 1)
        if kind == "wood":
            tone = (0.82 * math.sin(phase) + 0.18 * math.sin(phase * 2.76) * math.exp(-12 * time)) * math.exp(-3.5 * time)
        elif kind == "bell":
            tone = (0.72 * math.sin(phase) + 0.17 * math.sin(phase * 2) + 0.11 * math.sin(phase * 3.94)) * math.exp(-2.7 * time)
        elif kind == "reed":
            tone = math.sin(phase + 0.015 * math.sin(time * TAU * 4.8)) * 0.76 + 0.18 * math.sin(phase * 3)
        else:
            tone = math.sin(phase) * 0.7 + math.sin(phase * 2) * 0.18 + math.sin(phase * 4) * 0.07
        samples[(begin + tick) % len(samples)] += volume * attack * release * tone

def loop(bpm, bass, melody, color):
    beat = 60 / bpm
    samples = [0.0] * round(16 * beat * RATE)
    for phrase in range(8):
        base = bass[phrase % len(bass)]
        start = phrase * 2 * beat
        note(samples,start,1.62 * beat,base,0.16,"synth")
        note(samples,start + 0.75 * beat,0.49 * beat,base + 12,0.10,"wood")
        note(samples,start + beat,0.79 * beat,base + 19,0.075,"reed")
        note(samples,start,1.72 * beat,melody[phrase],0.23,color)
        extra = melody[(phrase + 1) % 8] - (12 if phrase % 2 else 0)
        note(samples,start + 1.53 * beat,0.43 * beat,extra,0.13,color)
        for step in (0,1):
            note(samples,start + step * beat,0.11,31 + step * 4,0.065,"wood")
    return samples

def cue(notes, space):
    duration = len(notes) * space + 0.19
    samples = [0.0] * round(duration * RATE)
    for index, pitch in enumerate(notes):
        note(samples,index * space,min(space * 2 + 0.10, duration - index * space),
             pitch,0.29,"wood" if pitch < 50 else "bell")
    return samples

def write_ogg(samples, target, temp):
    pcm = array("h",(round(max(-0.96,min(0.96,sample))*32767) for sample in samples))
    with wave.open(str(temp),"wb") as stream:
        stream.setparams((1,2,RATE,0,"NONE",""))
        stream.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg","-hide_banner","-loglevel","error","-y","-i",str(temp),
                    "-c:a","libvorbis","-q:a","2",str(target)],check=True)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory",type=Path)
    args = parser.parse_args()
    args.directory.mkdir(parents=True,exist_ok=True)
    with TemporaryDirectory() as scratch:
        temp = Path(scratch) / "render.wav"
        for name, arrangement in MUSIC.items():
            write_ogg(loop(*arrangement),args.directory / f"{name}.ogg",temp)
        for name, arrangement in CUES.items():
            write_ogg(cue(*arrangement),args.directory / f"{name}.ogg",temp)

if __name__ == "__main__":
    main()
