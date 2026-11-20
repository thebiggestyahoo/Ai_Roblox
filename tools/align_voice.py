"""Align the delivered recording against the supplied verbatim script."""
import re
import subprocess
import sys
from pathlib import Path
from pocketsphinx import Decoder

audio, script = map(Path, sys.argv[1:3])
pcm = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(audio), "-ar", "16000", "-ac", "1", "-f", "s16le", "-"])
lines = script.read_text().strip().split("\n\n")
tokens = [re.findall(r"[a-z]+(?:'[a-z]+)*", line.lower()) for line in lines]
decoder = Decoder(samprate=16000, loglevel="ERROR")
decoder.add_word("treehouse", "T R IY HH AW S", False)
decoder.set_align_text(" ".join(word for line in tokens for word in line))
for pass_number in range(2):
    decoder.start_utt()
    decoder.process_raw(pcm, full_utt=True)
    decoder.end_utt()
    if pass_number == 0:
        decoder.set_alignment()
entries = [entry for entry in decoder.get_alignment() if entry.name not in {"<s>", "</s>", "<sil>"}]
assert len(entries) == sum(map(len, tokens)), len(entries)
i = 0
for line in tokens:
    group = entries[i:i+len(line)]
    print(group[0].start/100, (group[-1].start+group[-1].duration)/100, " ".join(e.name for e in group))
    print(" ".join(f"{e.name}={e.start/100:.2f}" for e in group))
    i += len(line)
