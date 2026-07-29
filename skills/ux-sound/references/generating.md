# Generating sound effects

Loaded on demand from `SKILL.md` §3. Everything here assumes §3's tree has
already told you generation is the right route — which, per that tree, means a
**one-shot auditory icon** you cannot record. Never a sustained bed.

## Choosing this route

Generation is one of three routes, not the default. Take it only when the sound
is an auditory icon you cannot record and cannot convincingly synthesize.

**Never sign the user up for a paid service to finish a task.** If no generator
is already configured, say so and offer the alternatives: record it (a phone mic
and a real object beats a generation more often than people expect), pull from a
free library (freesound.org, CC0 packs), or synthesize and accept the loss. Only
reach for a paid API if the user asks for it or a key is already in the
environment.

The example below uses ElevenLabs because it is the one with a text-to-sound-effects
endpoint worth documenting. Any generator with a duration parameter works the same
way; the prompt rules and the trim step below apply regardless of vendor.

**The user sets `ELEVENLABS_API_KEY` themselves.** The SDK reads it from the
environment with no arguments. Never hardcode it, never write it into a file,
never echo it. If it is missing, stop and offer the non-generation routes rather
than asking them to buy credits:

```bash
[ -n "$ELEVENLABS_API_KEY" ] || echo "No generator configured — record, use a CC0 library, or synthesize"
```

If the user does want this route, the vendor's own skill tracks the API more
closely than this file can:

```bash
npx skills add elevenlabs/skills --skill sound-effects
```

JavaScript — use `@elevenlabs/*` packages only:

```javascript
import { ElevenLabsClient } from "@elevenlabs/elevenlabs-js";
import { createWriteStream } from "fs";

const client = new ElevenLabsClient(); // reads ELEVENLABS_API_KEY
const audio = await client.textToSoundEffects.convert({
  text: "single dry mechanical latch click, close mic, no room",
  duration_seconds: 0.5,
  prompt_influence: 0.8,
});
audio.pipe(createWriteStream("/tmp/candidate.mp3"));
```

Python:

```python
from elevenlabs import ElevenLabs

client = ElevenLabs()  # reads ELEVENLABS_API_KEY
audio = client.text_to_sound_effects.convert(
    text="single dry mechanical latch click, close mic, no room",
    duration_seconds=0.5,
    prompt_influence=0.8,
)
with open("/tmp/candidate.mp3", "wb") as f:
    for chunk in audio:
        f.write(chunk)
```

| Param | Range | Set it to |
|---|---|---|
| `duration_seconds` | 0.5–30, null = auto | Always set it. Auto picks a length for video, not for a button |
| `prompt_influence` | 0–1, default 0.3 | **0.8** for UI sound. The default is loose enough to wander off a short, specific brief |
| `loop` | boolean, v2 only | `true` only for continuous beds (§3 tree) |
| `output_format` | query param or SDK arg | `mp3_44100_128`. `pcm_44100` is pointless once you trim to 60ms |

Errors: `401` bad key, `422` out-of-range params (check duration and
prompt_influence), `429` rate limited — back off, do not retry in a loop.

**The 0.5s floor shapes this whole route.** Micro feedback is 10–120ms and the
API will not go below 500ms. Generation is therefore always two steps: generate,
then find the transient and cut.

```bash
scripts/trim-to-transient.sh /tmp/candidate.mp3 public/sfx/click.mp3 0.06
```

It finds the onset, cuts 4ms before it so the attack is never clipped,
compresses and limits, and writes mono 44.1kHz. Clipping the attack is what
turns a click into a thud.

**Find the onset relative to the clip's own peak, not with silence detection.**
A generated clip usually opens with 30–60ms of room tone that is quiet but not
silent, so a dB-threshold detector skips it and reports the first real *gap*
instead — which is after the transient. The onset is the first sample above 8%
of peak. Measured on one chain-pull generation: silence detection said 0ms and
kept 35ms of dead head; 8%-of-peak found 34.7ms. `scripts/trim-to-transient.sh`
does this, and 35ms of inaudible head is 35ms of latency between the pointer and
the sound.

**Never ship the raw generation.** It arrives padded with silence and a room
tail, at a length chosen for video.

## Prompting for an animated element

The generator has no concept of "at 300ms". It does have a rough concept of
*start, middle, end*. So you get two levers, and neither is a number: a
**literal enumeration of events in order**, and **positional words** to anchor
them.

Measured, same object and model, four prompt styles:

| Style | Example | Events produced |
|---|---|---|
| Milliseconds | "a cluster of three flickers around 300ms, settling by 700ms" | 14 scattered, or 4 |
| Plain scene | "old fluorescent light turning on in an empty room" | **0** |
| Descriptive count | "three failed clicks, then it catches" | **0** |
| **Literal enumeration** | "electric crack, buzz, crack, buzz, crack, buzz, steady hum" | **7, evenly spread** |

Scene language, which every prompting guide recommends, produced a featureless
wash. Enumeration produced a rhythm.

**The structure:**

```
<event>, <texture>, <event>, <texture>, <event>, <resolution>. <recording>.
```

```
"electric crack, buzz, crack, buzz, crack, buzz, steady electrical hum.
 Close mic, dry, no room."
```

- **Enumerate one item per beat you want.** The count of commas is your only
  timing control. Seven items gave seven events; "three failed clicks" gave none,
  because a number in prose is not a beat.
- **Use onomatopoeia, not description.** "crack" and "buzz" are events. "failed
  restrike" is a concept, and concepts get rendered as texture.
- **Alternate event and texture.** Enumerating only events ("crack, crack,
  crack") gives you no bed between them, and the gaps come back as silence.
- **End with the resolution** ("steady hum"), or the clip stops dead.
- **Anchor with positional words, never numbers.** "at the very start",
  "through the middle", "by the end" measurably move energy. Appending *"It
  turns on immediately at the very start"* moved the peak from spread across
  the clip to 0.91 inside the first 20ms.

**Placement is probabilistic. Generate several and select by measurement.** The
same prompt, run twice, put its peak at 0ms and at 920ms. That is why the
three-candidate rule exists — not for taste, for placement. Expect roughly half
to miss.

## Looping beds

For anything under a looping animation — an idle flicker, a fan, a drone —
generate at the loop's cycle length with `loop: true` rather than synthesizing,
**unless the bed must react to interface state** (§3 tree).

Then verify the seam, because "seamless" is a claim the model makes, not a
guarantee:

```js
// compare the first and last 50ms; within ~10% is inaudible
const seam = rms(tail) / rms(head);   // 1.03 = seamless · 0.80 = audible bump
```

Measured on two 7.3s generations from one prompt: 1.03 and 0.80. Same prompt,
same params. Check every one.

**Set `duration_seconds` to the event's real length, not longer.** At 2.5s for a
1s event, the model front-loaded everything and left 2.1s of silence. The clip
length is a budget, not a canvas.

**Then measure and re-time (§8).** You are choosing the number of beats and their
order. The generator chooses where they land. The animation follows the file.

Prompt rules, because generators default to cinematic:

- **Always** name mic distance and room ("close mic, dry, no reverb"). Interface sounds have no room.
- **Never** put milliseconds or "first/then/after" timing in the prompt. Measured: it produces scatter, not placement.
- **Always** say "single" or "one" for micro feedback. Generators love giving you a sequence.
- **Never** use emotional adjectives ("satisfying", "premium"). Name the object and material: "small metal latch", "thin plastic tab", "paper edge".
- Generate 3 candidates per prompt and analyze all three. Pick by measurement, not by first impression.
