"""Generate short narration previews and export the matching Luau cue sheet."""
import argparse
from array import array
import json
import math
import random
import re
import subprocess
import tempfile
import textwrap
import wave
from pathlib import Path

root = Path(__file__).resolve().parents[1]
stories = json.loads((root / "media/stories.json").read_text())
output = {}
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--model", type=Path)
parser.add_argument("--voices", type=Path)
args = parser.parse_args()
if bool(args.model) != bool(args.voices):
    parser.error("Supply both Kokoro files, or omit both for the Flite fallback.")
voice_engine = None
if args.model:
    import numpy as np
    import onnxruntime as ort
    from kokoro_onnx import Kokoro
    options = ort.SessionOptions()
    options.intra_op_num_threads = 2
    options.inter_op_num_threads = 1
    inference = ort.InferenceSession(str(args.model), options, providers=["CPUExecutionProvider"])
    voice_engine = Kokoro.from_session(inference, str(args.voices))

try:
    from pocketsphinx import Decoder
except ImportError:
    Decoder = None

def words(text):
    return re.findall(r"[a-z]+(?:'[a-z]+)*",text.lower())

def forced_starts(path, line):
    if Decoder is None:
        return None
    decoder = Decoder(samprate=16000, loglevel="ERROR")
    for term, pronunciation in {
        "milo":"M AY L OW","eli":"IY L AY","crosswalk":"K R AO S W AO K",
        "bookshop":"B UH K SH AA P","cupcake":"K AH P K EY K","frosting":"F R AO S T IH NG",
        "playtime":"P L EY T AY M"}.items():
        if not decoder.lookup_word(term): decoder.add_word(term, pronunciation, False)
    tokens = words(line)
    if not all(decoder.lookup_word(token) for token in tokens):
        return None
    pcm = subprocess.check_output(["ffmpeg","-v","error","-i",str(path),"-ar","16000","-ac","1","-f","s16le","-"])
    try:
        decoder.set_align_text(" ".join(tokens))
        for attempt in range(2):
            decoder.start_utt()
            decoder.process_raw(pcm, full_utt=True)
            decoder.end_utt()
            if attempt==0: decoder.set_alignment()
        alignment = [part for part in decoder.get_alignment() if not part.name.startswith("<")]
    except RuntimeError:
        return None
    if len(alignment)!=len(tokens):
        return None
    return [part.start/100 for part in alignment]

def soundtrack(path, length, cues, film):
    """Quiet score, street/court atmosphere and beat-specific foley under the narration."""
    sample_rate = 22050
    bed = array("f", [0]) * round(sample_rate*length)
    rng = random.Random(312)
    noise = 0
    for i in range(len(bed)):
        t = i/sample_rate
        noise = .97*noise + .03*rng.uniform(-1,1)
        bed[i] = noise*.024*min(1,t*3,(length-t)*3)
    def note(time, hz, duration, volume, shape):
        first = round(time*sample_rate)
        count = min(round(duration*sample_rate),len(bed)-first)
        for i in range(count):
            t = i/sample_rate
            env = min(1,t*65,(duration-t)*12)*math.exp(-t*shape)
            bed[first+i] += (math.sin(math.tau*hz*t) + .19*math.sin(math.tau*hz*2.009*t))*volume*env
    palette = [196,246.94,293.66,369.99] if film=="last-bus" else [174.61,220,261.63,329.63]
    for i in range(0,20,2):
        start = cues[i]["start"]
        for j in range(4):
            note(start+j*.46,palette[(j+i//2)%4],2.5,.017 if i<14 else .025,1.7)
    if film=="last-bus":
        for scene,frequency in ((0,89),(2,82),(7,79),(8,87),(11,75),(17,112)):
            start = cues[scene]["start"]
            for j in range(4):
                note(start+.24+j*.31,frequency+j*4,.25,.037,10)
        note(cues[12]["start"]+.44,638,.82,.034,4)
    else:
        for scene,offset,frequency in ((0,.3,158),(7,2.5,275),(8,.71,75),(16,2.21,791),(17,.71,91)):
            note(cues[scene]["start"]+offset,frequency,.36,.045,8)
    with wave.open(str(path),"wb") as score:
        score.setparams((1,2,sample_rate,0,"NONE","not compressed"))
        score.writeframes(array("h",(round(x*32767) for x in bed)).tobytes())
for story in stories:
    with tempfile.TemporaryDirectory() as directory:
        scratch = Path(directory)
        clips = []
        alignment = []
        for i, line in enumerate(story["lines"]):
            line_path = scratch / f"line-{i}.txt"
            clip = scratch / f"line-{i}.wav"
            line_path.write_text(line)
            if voice_engine:
                voice = "af_heart" if story["id"]=="last-bus" else "am_michael"
                samples, sample_rate = voice_engine.create(line, voice=voice, speed=1.06, lang="en-us")
                spoken = scratch/f"synth-{i}.wav"
                with wave.open(str(spoken),"wb") as out:
                    out.setparams((1,2,sample_rate,0,"NONE","not compressed"))
                    out.writeframes((np.clip(samples,-.98,.98)*32767).astype("<i2").tobytes())
                source = ["-i",str(spoken)]
                tempo = "atempo=1.00"
            else:
                source = ["-f","lavfi","-i",f"flite=textfile={line_path}:voice={story['voice']}"]
                tempo = "atempo=1.06"
            subprocess.run(["ffmpeg","-v","error","-y",*source,"-af",
                            tempo+",silenceremove=start_periods=1:start_threshold=-49dB:start_duration=0.04,"
                            "areverse,silenceremove=start_periods=1:start_threshold=-48dB:start_duration=0.042,areverse,"
                            "apad=pad_dur=0.15", "-ar","44100","-ac","1",str(clip)],check=True)
            alignment.append(forced_starts(clip,line))
            clips.append(clip)

        wav_path = scratch / "preview.wav"
        cues = []
        with wave.open(str(wav_path), "wb") as audio:
            audio.setparams((1, 2, 44100, 0, "NONE", "not compressed"))
            start = 0
            for line, clip, word_starts in zip(story["lines"], clips, alignment, strict=True):
                with wave.open(str(clip), "rb") as part:
                    frames = part.getnframes()
                    audio.writeframes(part.readframes(frames))
                finish = start + frames
                captions = []
                pieces = textwrap.wrap(line, width=29, break_long_words=False, break_on_hyphens=False)
                weights = [len(piece)+len(piece.split())*2 for piece in pieces]
                duration = frames/44100
                ordinal = 0
                marks = [0]
                for j,piece in enumerate(pieces[:-1]):
                    ordinal += len(words(piece))
                    estimate = duration*sum(weights[:j+1])/sum(weights)
                    hit = word_starts[ordinal]-.032 if word_starts and ordinal<len(word_starts) else estimate
                    if not (marks[-1]+.34 <= hit <= duration-(len(pieces)-j-1)*.34):
                        hit = estimate
                    marks.append(hit)
                marks.append(duration)
                for j,piece in enumerate(pieces):
                    captions.append([round(start/44100+marks[j],3),round(start/44100+marks[j+1],3),piece])
                cues.append({"start": round(start / 44100, 3), "finish": round(finish / 44100, 3),
                             "line": line, "captions": captions})
                start = finish
            audio.writeframes(bytes(round(.35 * 44100) * 2))
        audio_file = root / "media" / (story["id"] + "-mix.mp3")
        score_path=scratch/"score.wav"
        soundtrack(score_path,start/44100 + .35,cues,story["id"])
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(wav_path),"-i",str(score_path),
                        "-filter_complex", "[0:a][1:a]amix=inputs=2:duration=first:normalize=0,loudnorm=I=-18:TP=-1.5:LRA=11", "-ar", "44100",
                        "-b:a", "96k", str(audio_file)], check=True)
        runtime=round(start/44100 + .35,3)
        assert 90 <= runtime <= 120, (story["id"],runtime)
        print(story["id"],runtime,f"{sum(value is not None for value in alignment)}/{len(cues)} narration beats aligned")
        output[story["id"]] = {"finish":runtime, "cues":cues}

def stamp(seconds):
    ms = round(seconds*1000)
    return f"{ms//3600000:02d}:{ms//60000%60:02d}:{ms//1000%60:02d},{ms%1000:03d}"

for film,data in output.items():
    subs = [item for cue in data["cues"] for item in cue["captions"]]
    (root/"media"/f"{film}.srt").write_text("\n".join(
        f"{i}\n{stamp(first)} --> {stamp(last)}\n{text}\n"
        for i,(first,last,text) in enumerate(subs,1)))

lines = ["-- Generated from rendered preview narration.", "return {"]
for film, data in output.items():
    lines.append(f'["{film}"]={{finish={data["finish"]}, cues={{')
    for cue in data["cues"]:
        captions=",".join("{"+f"{a},{b},"+json.dumps(text)+"}" for a,b,text in cue["captions"])
        lines.append("{"+f'{cue["start"]},{cue["finish"]},'+"{"+captions+"}},")
    lines.append("}},")
(root / "src/NarrationTiming.luau").write_text("\n".join(lines+["}",""]))
(root / "media/timings.json").write_text(json.dumps(output, indent=2)+"\n")
