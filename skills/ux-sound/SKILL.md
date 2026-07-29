---
name: ux-sound
description: "Decide whether an interface element should make a sound, which kind, how loud, and where the audio comes from (synthesis, recording, or generation). Also audits an existing UI: inventories every trigger, deletes the decorative ones, re-levels the rest, and finds the playback bugs. Use when adding sound to a UI, auditing or reviewing a UI that already has sound, deciding whether a silent UI needs any, choosing between synthesizing and sampling, levelling sounds against each other, or syncing audio to animation. Triggers on: ui sound, ux sound, sonic ux, audio feedback, micro feedback, earcon, auditory icon, notification sound, alert sound, hover sound, click sound, sound effect, sfx, should this have sound, audit sounds, sound audit, review the sound, too loud, sounds cheap, sound doesn't fire, sound plays twice, sound generation."
license: MIT
metadata:
  author: jal-co
  version: "1.0.0"
---

# UX Sound

Sound design for interfaces. This skill decides **whether, what, how loud, and from where**. For the Web Audio mechanics of building a specific sound (oscillators, envelopes, filters, recipes), use the `ui-sound-design` skill alongside this one.

The distinction that organizes everything below:

- **UX sound** — the purpose and behaviour principles. Why, when, and where a sound exists at all.
- **UI sound** — the specific artifact attached to a specific element. What it is.

Most bad interface audio is a UI sound problem caused by skipping the UX sound question.

**Auditing a UI that already has sound (or has none)? Start at §10**, then come back to §1–§4 for each trigger it finds.

## 1. Should this element make a sound?

Walk this before writing any audio code. Most elements exit at the first branch.

```
Does the sound carry information the user cannot already see?
├── No
│   ├── Is the element the product's signature moment (one per product)?
│   │   ├── Yes → sound allowed, budget it against the one-per-product rule
│   │   └── No  → NO SOUND. Stop here.
│   └──
└── Yes
    ├── Did the user initiate this?
    │   ├── Yes → ACTIVE sound (micro feedback). Fires on their action.
    │   └── No  → PASSIVE sound (notification). System-initiated.
    └── Does it need intervention within seconds?
        ├── Yes → ALERT. Escalation level 3.
        └── No  → level 1 or 2 (see §4).
```

**Always** delete decorative sound that survives this tree by accident. A sound that does not inform is a sound the user will turn off, and they cannot turn off yours specifically — they turn off the tab.

**Never** play sound on page load, route change, or scroll. None of those are user-initiated at the moment they occur, and the browser will block them anyway (§7).

## 2. Which type

| Type | Trigger | Length | Use when |
|---|---|---|---|
| Micro feedback | User action | 10–120ms | Confirming a tap, toggle, send, copy |
| Earcon | Either | 200–600ms | An abstract motif that *means* something by convention (brand-owned) |
| Auditory icon | Either | 100–800ms | A recorded real-world sound whose source explains it (paper, camera, trash) |
| Notification | System | 300–900ms | New message, job finished, state changed |
| Identification | App start | 800–2500ms | Once per session, maximum |
| Alert | System | 400–1200ms | Requires intervention now |

**Earcon vs auditory icon** decides your sourcing route in §3. An earcon is learned, so it can be synthesized freely. An auditory icon claims to be a real object, so listeners hold it to a physical standard and synthesis usually loses (§3).

**Implicit vs explicit:** implicit sounds (touch feedback, indicators) must be quiet enough to be felt rather than heard. Explicit sounds (ringtone, alert) are meant to be noticed across a room. Never level them the same way.

## 3. Where the audio comes from

Three routes. Choose by measuring, not by taste.

```
Run the analyzer first:
  node <ui-sound-design skill>/tools/analyze-sound.mjs reference.mp3

Is noise_percent > 80% AND fewer than 4 harmonics?
├── Yes → SYNTHESIZE. It is filtered noise; a file adds bytes and buys nothing.
└── No
    ├── Does the sound sustain (hover, hold, drag, ambient bed)?
    │   └── Yes → SYNTHESIZE. Always. See "sustained sounds" below.
    └── Is it an auditory icon (claims to be a real object)?
        ├── Yes → RECORD or GENERATE. See the rule below.
        └── No  → SYNTHESIZE.
```

**For one-shot physical events, a real recording beats a synthesis of it** —
even a synthesis built from the recording's own measured envelope and spectrum.
Physical objects carry instability that survives being described accurately.
Budget one attempt at synthesizing an auditory icon; if it loses the A/B against
the reference, ship the recording and stop.

**The reverse is true for sustained sounds.** A recorded or generated bed loses
to a synthesized one, and the reason is not realism — it is that you cannot take
anything out of a recording. See below.

**Never layer synthesized transients on top of a recording of the same event.** The recording already contains them, and every tick doubles.

### Sustained sounds are always synthesized

A one-shot is over before the ear can object. A bed plays for as long as someone
reads the page, and that changes which source wins.

**You cannot remove a frequency from a recording, only from a synthesis.** A
generated hum arrives with whatever the model put in it. If part of that content
fatigues, your options are a filter that guts the whole sound or a different
generation that has its own problems. With synthesis you simply never make the
offending partial.

**Nothing sustained should carry energy in 2–5kHz.** That is where the ear is
most sensitive, and sensitivity that is a feature for a 12ms click is an injury
over ninety seconds. Two versions of one hum failed this way before it was fixed:

- three partials at 10.8–11.1kHz, detuned so they beat against each other,
  which is the worst case because the beating keeps re-drawing attention
- a generated bed whose crackle sat in the same region

Both were described as "ringing my ears" by the listener. The fix was a 900Hz
lowpass and nothing above 291Hz.

**Verify it, do not trust the design.** Render offline and measure the share of
energy above 2kHz. Under 1% for anything that sustains:

```js
// after rendering the bed through its real chain
let high = 0, total = 0;
for (let f = 100; f < 16000; f *= 1.3) {
  const m = magnitudeAt(f);      // any DFT bin
  total += m;
  if (f > 2000) high += m;
}
// high / total < 0.01
```

**Generation is for texture, not for placement or for beds.** Across this
skill's test runs it produced usable crackle and ambience, never a usable
transient at a chosen moment, and never a bed that could be levelled without
fatigue.

### The GENERATE route (optional)

Generation is one of three routes, not the default, and §3's tree narrows it
hard: only a **one-shot auditory icon** you cannot record. Never a bed.

**Never sign the user up for a paid service to finish a task.** If no generator
is configured, say so and offer the alternatives: record it (a phone mic and a
real object beats a generation more often than people expect), pull from a free
library, or synthesize and accept the loss.

The three findings that decide whether it works at all:

- **Enumerate beats literally, never in milliseconds.** Measured across four
  prompt styles: only literal enumeration produced structure. "crack, buzz,
  crack, buzz, steady hum" gave 7 evenly-spread events; "three failed clicks"
  gave 0.
- **Anchor with positional words** ("at the very start", "through the middle").
  Numbers never place anything; these measurably do.
- **Placement is probabilistic.** The same prompt twice put its peak at 0ms and
  at 920ms. Generate three, select by measurement.

Full method — API key handling, SDK calls, params, the 0.5s floor, onset
trimming, and looping beds: **[references/generating.md](references/generating.md)**

## 4. Levels

Level by **measured dBFS peak**, never by gain number. Gain values are not comparable across sources: `0.05` on a synthesized 12ms burst and `0.5` on a normalized 700ms sample can be 30dB apart in perceived loudness.

Measure by rendering through an `OfflineAudioContext` with the real signal chain and comparing peaks:

```js
const peak = (buf) => {
  const d = buf.getChannelData(0);
  let m = 0;
  for (let i = 0; i < d.length; i++) m = Math.max(m, Math.abs(d[i]));
  return 20 * Math.log10(m + 1e-12);
};
```

Escalation ladder. Each step is a target peak, and the gaps are what make escalation legible:

| Level | Class | Target peak |
|---|---|---|
| 0 | Continuous (hum, drone, hold) | −40 dBFS or below |
| 1 | Implicit micro feedback (hover) | −38 dBFS |
| 1 | Explicit micro feedback (press, send) | −27 dBFS |
| 2 | Notification | −20 dBFS |
| 3 | Alert | −12 dBFS |

**Continuous sounds sit below every transient**, because they are present the whole time the user is reading. A drone at the level of a click is unbearable within ten seconds.

**When in doubt on a bed, go quieter than the ladder.** −40 is a ceiling, not a
target. A hum at −42 sits 26dB under its own trigger sound: audible in a quiet
room, gone in a noisy one, which is the right way round for a sound nobody asked
for. Every round of feedback on a continuous sound in practice has been "quieter",
never "louder".

**A deliberate gesture may sit up to 9dB above the ambient one it accompanies, never more.** Beyond that the two stop reading as the same instrument and the louder one feels like a different app.

## 5. Personality

Pick one per product and write it down. It resolves every later argument about whether a sound is "too much".

- **The butler** — discreet, never speaks first. Only ever confirms what the user did. Micro feedback only, level 1 maximum, no notifications without an explicit setting.
- **The buddy** — offers help. Notifications allowed, warmer timbres, wider pitch variation.

The personality sets the default answer for §1's first branch. A butler product answers "no sound" far more often than a buddy product.

## 6. Accessibility

Sound is the one channel a user may not be able to receive, may have turned
off at the OS, or may be in a room where using it is antisocial. Assume it is
missing and design so nothing breaks.

**Every sound has a visual equivalent.** Never let a sound be the only carrier
of information. Most users will never hear it: muted tabs, headphones out,
autoplay policy not yet satisfied (§7). If the sound is the only signal that a
message sent, the message silently did not send for most of your users.

**Ship a mute control, persisted.** Not a settings page — a control the user can
find in the moment the sound annoys them. Persist it and read it before every
play, not at load:

```js
let muted = typeof localStorage !== "undefined" && localStorage.getItem("sfx") === "off";

export function setSfxMuted(next) {
  muted = next;
  localStorage.setItem("sfx", next ? "off" : "on");
  if (next) stopAllContinuous(); // a drone must stop the instant it is muted
}
```

**`prefers-reduced-motion: reduce` mutes sound by default.** The query is about
motion, but the intent is calm, and someone who asked an interface to stop
moving did not ask it to start talking. When the sound accompanies an animation
that reduced-motion has already disabled, it has also lost its referent and is
now a noise with no cause.

```js
const calm = window.matchMedia("(prefers-reduced-motion: reduce)").matches;
if (calm && localStorage.getItem("sfx") === null) muted = true;
```

Read `localStorage` first, so an explicit opt-in still wins.

**Never sound on typing or keyboard navigation.** Both are high-frequency and
sustained. A sound that fires 90 times a minute stops being feedback and becomes
a texture the user has to endure.

### The hover exception

Hover sound is decorative by default and the default is no. It is allowed only
when **every** one of these holds:

- The sound is at or below −35 dBFS peak (§4, level 0-1)
- It is mouse-only (`pointerType === "mouse"`)
- It is debounced ≥90ms (§7)
- It can be muted, and is muted under reduced-motion
- The element is a signature moment, not a list of twelve

**Write the exception down where the code lives.** Hover sound that nobody
decided on is the kind that ships, annoys, and never gets attributed to a
decision, because there wasn't one.

## 7. Implementation rules

These are failure modes, each of which will cost an hour if rediscovered.

**Arm the gesture unlock at module import, not on first use.** An `AudioContext` starts suspended and only a real gesture resumes it. Hovering is not a gesture. If the unlock listener is installed lazily on first hover, a user who loads the page and moves the mouse never unlocks anything and nothing ever plays.

```js
if (typeof window !== "undefined") {
  document.addEventListener("pointerdown", unlock);
  document.addEventListener("keydown", unlock);
}
```

**Decode every clip on the unlock gesture, not on first hover.** A clip that starts loading when it is needed is silent the first time it is needed. Every clip added later must be added to this prefetch — this is the single most repeated bug in sound layers.

**Check readiness before spending the retrigger guard.** Guard order matters:

```js
if (!ctx || !buffer) { prime(); return; }   // bail without spending it
if (!allowed(key, minGapMs)) return;         // now spend it
```

Reversed, the first hover (which can only ever start the fetch) also blocks the next one.

**Always debounce identical sounds by 90ms minimum.** `pointerenter` fires again as the pointer crosses child elements inside one row, so one visual hover becomes two plays. For sounds longer than 300ms, debounce by the sound's own length instead.

**Hover sounds are mouse-only.** `if (event.pointerType !== "mouse") return;` — a coarse pointer has no hover, so on touch the hover sound fires on the tap that also navigates.

**Never ramp gain to 0.** `exponentialRampToValueAtTime(0)` throws. Ramp to `0.0001`.

**Stop and disconnect long-lived nodes.** Oscillators for a continuous sound must be `stop()`ed and their gain node `disconnect()`ed after the fade, or they accumulate on every hover.

**Re-entry must not stack.** A continuous sound needs a singleton guard (`if (running) return`), or three hovers create three drones.

## 8. Syncing sound to animation

Sound and animation are one event. The authority passes between them in one
direction, and going the other way costs you the sound.

```
1. STORYBOARD    Count the beats you need, in order. Not their times —
                 the generator cannot honour times (§3).
                   crack → flicker → flicker → flicker → settle
                   = 5 beats

2. PROMPT        Enumerate those beats literally, one comma each, and set
                 duration_seconds to the event's real length (§3).

3. MEASURE       scripts/transients.mjs clip.mp3 --keyframes
                 Prints each transient as a keyframe percentage of the
                 clip length, ready to paste.

4. RE-TIME       Convert those milliseconds to keyframe percentages and
                 replace the animation's timings with them. Set the
                 animation duration to the clip length exactly.
```

**Step 4 is not optional and it always overrides step 1.** The generator will
not hit your storyboard precisely, and a 40ms drift between a flicker and its
tick is audible as wrongness even though nobody can name it. The waveform wins.

**Never re-time the audio to fit an existing animation.** Stretching changes
pitch, trimming cuts the tail, and both are irreversible. Keyframe percentages
are free to move; recordings are not. If the animation is already built, treat
its beats as the storyboard for step 1 and regenerate.

**A flicker with no tick reads as a CSS animation. A tick with no flicker reads
as a glitch.** Both halves come from the same table of measured times, so keep
that table in one file and derive both from it.

## 9. Verification

Never claim a sound works without one of these:

- **Did it play?** Patch `createBufferSource`/`createOscillator` and count `start()` calls. Console silence is not evidence.
- **How loud, in dBFS?** Render offline and measure. "Sounds about right" is not a level.
- **Does it double?** Fire the trigger three times in 200ms and assert the play count is 1.
- **A/B against the reference.** Build a preview page with both, 400ms apart, before defending a synthesis.

Synthetic `pointerover` events dispatched by test harnesses frequently do not reach React's `onPointerEnter`. Call the handler directly through the element's react props when verifying, or you will chase a bug that does not exist.

## 10. Auditing an existing UI

An audit is a subtraction pass. Assume the layer is too loud and has too many
sounds, because that is what almost every one of them is. The output is a list
of deletions first, fixes second, additions last (usually empty).

### Step 1 — inventory every trigger

Read the code before listening to anything. Ears rationalize; a list does not.

```bash
rg -n "new Audio\(|AudioContext|\.play\(\)|playSound|useSound|howler|<audio" --type-add 'web:*.{ts,tsx,js,jsx,vue,svelte}' -t web
rg -n --files -g '*.{mp3,wav,ogg,m4a,webm}'
```

Build one row per **trigger**, not per file. Two components importing the same
click are two rows, because they can disagree about level and debounce.

| Element | Event | Asset | Type (§2) | Measured peak | Verdict |
|---|---|---|---|---|---|

If the UI has no sound at all, the inventory is empty and you skip to step 5.

### Step 2 — run every row through §1

For each trigger ask the first branch only: does it carry information the user
cannot already see? Mark it `DELETE` the moment the answer is no. Do not soften
this into "lower it" — a decorative sound at −45 dBFS is still a sound the user
did not ask for.

Expect to delete hover sounds, tab switches, page transitions, and everything
firing on scroll. These are the four that show up in nearly every layer.

**One signature moment survives the tree without informing.** If two do, the
second is a deletion; name which one you kept and why.

### Step 3 — measure, do not listen

For each surviving row, get a real number:

```bash
node scripts/transients.mjs public/sfx/click.mp3
```

For synthesized sounds, render the real chain through an `OfflineAudioContext`
and measure the peak (§4). Then check three things:

1. Each peak against the §4 ladder for its class.
2. **The gaps between classes**, which matter more than the absolute values. If
   the notification and the alert are within 4dB, escalation is broken and the
   user cannot tell urgent from routine.
3. Continuous sounds sit below every transient.

Report as `−31 dBFS, ladder says −27, +4 too quiet`. Never `feels quiet`.

### Step 4 — check the failure modes

Walk §6 against the code. In audit order, most-found first:

1. Clips decoded lazily instead of on the unlock gesture → first play is silent.
2. Retrigger guard spent before the readiness check → first hover eats the second.
3. No debounce, or under 90ms → `pointerenter` doubles across child elements.
4. Hover sounds not gated on `pointerType === "mouse"` → fires on touch taps.
5. Continuous sounds with no singleton guard or no `disconnect()` → drones stack.

Verify each by the §8 methods. A layer that "seems fine" while clicking around
is how all five of these survive to production.

### Step 5 — additions, last and few

Only after deletions and fixes. Run candidates through §1 like anything else, and
hold the total: **most products need three sounds or fewer**. If the audit
proposes more additions than deletions, the audit is wrong.

For a silent UI, the honest answer is usually "it does not need sound". Say that
plainly instead of inventing a reason to build a layer.

### Report format

```
SOUND AUDIT — <product>
Personality: butler | buddy (inferred, confirm this)

DELETE (n)     element · event · why it fails §1
FIX (n)        element · symptom · rule from §6 · one-line fix
RELEVEL (n)    element · measured → target dBFS
ADD (n)        element · type · route
```

Lead with the count of deletions. It is the number that tells the user how the
layer got where it is.

## Scripts

| Script | Does |
|---|---|
| `scripts/transients.mjs` | Lists transient times in ms, or `--keyframes` for CSS percentages. Also prints peak dBFS for §4 levelling |
| `scripts/trim-to-transient.sh` | Turns a raw generation into a shippable UI sound: onset detection, 4ms pre-roll, compress, limit, mono 44.1kHz |

Both degrade with a message if `ffmpeg` is missing.

## Checklist

- [ ] Every sound survives §1's tree; decorative ones deleted
- [ ] Every sound has a visual equivalent; none is the only signal
- [ ] Mute control exists, is persisted, and stops continuous sounds instantly
- [ ] `prefers-reduced-motion` mutes by default; explicit opt-in overrides it
- [ ] No sound on typing or keyboard navigation
- [ ] Any hover sound meets all five conditions in §6
- [ ] Type chosen from §2; implicit and explicit levelled differently
- [ ] Route chosen by analyzer output, not preference
- [ ] No synthesized transients layered over a recording of the same event
- [ ] Levels set by measured dBFS peak against the §4 ladder
- [ ] Continuous sounds below every transient sound
- [ ] Sustained sounds are synthesized, not recorded or generated
- [ ] Sustained sounds measure <1% of their energy above 2kHz
- [ ] Unlock armed at import; every clip decoded on first gesture
- [ ] Readiness checked before the retrigger guard is spent
- [ ] Hover sounds mouse-only; identical sounds debounced ≥90ms
- [ ] Continuous sounds are singletons and disconnect on stop
- [ ] Generation only after record/library/synthesize were offered; API key set by the user, never hardcoded
- [ ] Generation prompt enumerates beats literally (onomatopoeia, one per comma), never milliseconds
- [ ] Raw generations trimmed to the transient before shipping
- [ ] Animation keyframes derived from measured audio transients, not the reverse
- [ ] Playback verified by counting `start()` calls, not by absence of errors

Audit-only:

- [ ] Inventory built from code, one row per trigger, before any listening
- [ ] Every row run through §1; decorative triggers marked DELETE, not lowered
- [ ] Levels reported as measured dBFS against the ladder, with the class gaps checked
- [ ] All five §6 failure modes checked and verified by §8 methods
- [ ] Additions proposed last, and fewer than deletions
