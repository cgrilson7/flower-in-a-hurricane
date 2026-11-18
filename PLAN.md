# Flower In A Hurricane: a plan to raise the video's fidelity

The music video for "Flower In A Hurricane" (Justice, Tame Impala, SZA, King Gizzard) is one GLSL
scene for workshop's Demoscene tile, rendered offline to a 9:16 MP4. It works and stays in sync with
the song, but the characters are capsule-and-sphere dolls and the island is a flat disc. This plan is
for raising both, without breaking the timeline or the sync.

## What is here

```
flower.glsl        the whole video: scene, characters, timeline (direct()), sky, lights, render()
cues.md            the song's timing: sections, every sung line, who sings what, tempo
render/main.cjs    offline renderer (Electron): stills or the full video, frame n drawn at n/30 s
render/page.html   its WebGL2 page: draws a frame, hands it to the hardware H.264 encoder
preview.sh         stills at chosen song seconds, tiled into one contact sheet
render.sh          the full video → ~/Downloads/flower-in-a-hurricane-9x16.mp4 (about 2¼ min today)
shots/             the baseline: 45 stills (t<seconds>.jpg, 360 × 640) and sheet1–4.jpg. Compare against these.
transcript/        whisper.cpp word timings (sec_a = +64 s, b = +122, c = +148, d = +176, e = +188, f = +160)
```

The source audio is `~/billy/flower.m4a`; the stems are in `~/billy/separated/` and `~/billy/stems/`.
The character references are `~/billy/djs.jpg`, `djswithcross.jpeg`, `female_vocalist.jpeg` and
`guitarist_and_male_vocalist.jpeg`. Look at them before you model anyone.

## How to work

```bash
cd ~/billy/videos/flower-in-a-hurricane
./preview.sh /tmp/sheet.jpg 66 92 124 163.5            # stills at those seconds, tiled 4 across (270 × 480 each)
W=540 H=960 ./preview.sh /tmp/face.jpg 92              # one bigger still, for faces and hands
OUTDIR=shots-v2 W=360 H=640 ./preview.sh shots-v2/all.jpg 8 20 30 …   # a new baseline set
./render.sh                                            # the full video, only when the stills are right
```

Then Read the JPEG to see it. Nothing needs the tile to be on: `render/main.cjs` builds the shader
with the tile's own `~/workshop-tiles/demoscene/dist/scene.js` and draws it in a hidden window. The
tile's guide (`~/workshop-tiles/demoscene/dist/guide.md`) is the scene contract: GLSL ES 3.00,
floats with a point, don't redefine the helpers (`hash noise fbm rot smin smax sdSphere sdBox
sdTorus sdCapsule sdCylinder pal PI`), `map(p)` must stay a true distance (multiply down when a
displacement overstates it, or rays pass through).

**The sync is sacred.** `direct(t)` is the timeline: every shot, light cue and event is keyed to
song seconds in `cues.md`. Change what is drawn, not when. If a shot is reframed, keep its start
and end times.

## Is this possible in the Demoscene tile?

Yes, up to stylised-but-detailed, not photoreal. Signed-distance characters can have shaped
faces, hands, folded cloth and real hair volume. Íñigo Quílez's Shadertoy work ("Selfie Girl",
"Happy Jumping") is the proof and the best reference for technique. What makes this practical
here is that the video is rendered **offline**: a frame may take as long as it needs, because nothing
plays in real time.

- **Speed today:** about 50 frames a second at 1080 × 1920; the full video renders in 135 s.
  A 20× more expensive scene is still a 45-minute render, which is fine.
- **The GPU watchdog is the real limit.** macOS resets the GPU if one draw call runs for more than
  a couple of seconds. Before frames get that heavy, change `render/page.html` to draw each frame
  in horizontal strips: `gl.scissor` plus one `drawArrays` per strip, with a `gl.finish()` between.
  Do this as step 0 of anything heavy.
- **The tile itself will not keep up** with a detailed version at 30 fps, and the 4 KB demoscene
  budget is long gone (18.4 KB minified now; expect 40–60 KB). If the tile should still play it
  live, keep a `#define LITE` path that drops the detail (see step 7). The MP4 is the product.

## What the baseline shows (shots/sheet1–4.jpg)

- **Characters are dolls.** Capsule limbs with no hands, feet or shoes. Faces are bare spheres
  with two dots. Torsos are rounded boxes. Arms barely move. The female vocalist's mic hand
  covers her face in most front shots (1:06, 1:32, 2:04, 2:15). DJ B's "varsity lettering" reads as
  a glitch pattern.
- **The stage is a hockey puck.** A flat disc with painted rings on a barely visible cylinder.
  From the sea (0:08, 0:50, 1:46, 1:54) it reads as a platform, not an island.
- **The sea is flat and featureless.** There's no foam, spray or wave crests, and the "washed away"
  wave at 1:46 is lost in the mist.
- **The sky barely reads as a hurricane.** The spiral eyewall should be the signature image of the
  wide shots (1:54, 2:00).
- **Lighting is flat.** It's all ambient plus point lights: no rim light separating the characters
  from the dark, no specular on wet rock or skin, and no shadows from the stage lights.
- **Some framings are weak:** the DJ close-ups at 0:56, 2:59 and 3:20 sit too low, so the booth top
  fills the frame; the truss beam cuts across the tilt-up at 1:17 and the final sunrise (3:37, 3:41).
- **No anti-aliasing:** edges, rain and pinstripes shimmer.

## The plan, in order

### 0. Render headroom (do first)
- Strip-rendering in `render/page.html` (above), so frames can get heavy safely.
- Supersampling: render at 2× (2160 × 3840) and let the encoder's input be a downscaled canvas,
  or average 4 jittered rays inside `render()`. Either kills the shimmer on edges, rain and stripes.
- Raise `--steps` (march iterations) once detail arrives; keep `uSteps` in mind as the cap of 300.

### 1. The island: a rocky outcrop, not a disc
- Replace the rock cylinder (`scene()`, id 1) with a sculpted mass: a tall rock with a flat,
  worn top, built from an `fbm`-displaced ellipsoid or box `smax`-ed with planes. Give it ledges,
  overhangs, cracks (ridged noise, `1 - abs(noise)`) and scattered boulders (domain repetition with
  `hash` per cell). The top must stay flat enough to stand on around `y = 0` where the band is.
- The stage becomes part of the rock: a natural shelf, maybe with a few planks or road-case
  flooring under the booth, not a disc. Lose the concentric rings in `material()` id 2.
- Material: dark basalt with wet sheen (specular), lighter lichen on top faces (`n.y`), dark
  waterline band, puddles on the flat top that mirror the cross and the beams.
- Keep `map` honest: displaced rock overstates distance, so scale it (`*0.5–0.7`), and put a cheap
  bound around it.
- Check against 0:08, 0:20, 0:50, 1:46, 1:54 and 3:37: it should read as an island from the sea.

### 2. Sea and storm
- Sea: sharper, wind-driven crests (a few rotated, choppy Gerstner-style sine octaves), foam where
  crests break and around the rock (proximity to `scene` id 1), and spray particles in the wind.
  The 1:46 "washed away" wave (`ring`) should rear up as a visible wall and break over the
  rock's edge, with spray across the stage.
- Sky: make the eyewall a readable spiral from above (1:54–2:00): banded clouds swirling toward
  the clear eye, lit from inside by the lightning. The bolt should branch.
- Rain: keep it screen-space, but add depth (three layers, nearer ones thicker and blurred) and
  splashes on the stage top.

### 3. A shared character rig
Write one humanoid function with parameters (height, build, pose angles per joint), used by all
four characters, instead of four hand-placed capsule sets:
- Torso from blended ellipsoids (chest, waist, hips) with `smin`. Neck, collarbones, shoulders.
- Limbs as round cones (tapered capsules) with real elbow and knee joints driven by angles, so
  arms can animate: strum, fret, hold a mic, twist a knob.
- Hands: palm box plus four finger capsules and a thumb, curled by one parameter. Only at close range.
- Feet and shoes.
- Animation from `T` and `pul` (beat pulse): head nods, shoulder bounce, weight shifts, the
  female vocalist's free hand gesturing, the DJs reaching across the decks.

### 4. Faces
- Head as a skull shape (blended spheres and ellipsoids), not a ball: brow ridge, eye sockets
  with eyeballs and lids, a nose, cheekbones, lips, jaw and chin, ears. Characterful, not
  realistic; aim for "a well-made animated film", not a likeness.
- Beards with noise displacement for texture, on the guitarist and DJ A.
- **The mic must not hide her face:** hold it lower and to the side, at the chin, like the
  reference, and angle the shots so the face reads.

### 5. Hair and clothing, from the references
- **Guitarist / male vocalist:** long straight hair past the shoulders, center part, strands as
  repeated thin ridges along the fall (domain repetition in angle around the head) moving in the
  wind. White T-shirt with soft folds (low-amplitude sine displacement), dark jeans, a
  cream/butterscotch guitar with pickguard, pickups, bridge, strings, headstock and tuners.
- **Female vocalist:** very voluminous long curly red hair to mid-back. Build it from spiral
  curls (repeated helices) or layered noise on an envelope, not a bumpy ellipsoid. Oversized grey
  pinstripe jacket with real lapels, big shoulders and rolled cuffs; wide pinstripe trousers; a
  yellow-green top showing under the jacket, rings, a handheld mic.
- **DJ A:** big curly dark-brown hair, full beard, dark jacket, head down over the decks.
- **DJ B:** dark hair, black varsity jacket with white block lettering across the chest: either
  proper letter shapes (2D SDF boxes) or a clean stripe, never noise.
- Stripes and lettering come from coordinates local to the character (as the pinstripes now use
  the angle around her body), so they don't swim.

### 6. Light and materials
- Replace the stock `shade()` call in `render()` with your own: key light, a strong rim/back
  light from the truss behind the band (this separates characters from the storm), fill from the
  cross. Soft shadows from the two front spots, not only from `SUN`.
- Specular: wet rock and stage, guitar lacquer, skin sheen. A fake subsurface tint on skin (warm
  wrap lighting) and on the flower's petals (backlit glow when the cross is behind them).
- Volumetric look: the beams exist (`beam()`), so add light shafts from the cross through the
  rain and a soft bloom on bright things (cheap: add a blurred halo around bright emitters, as the
  cross does now).
- Grade: per-section palettes from `cues.md` (cyan/magenta drop, amber chorus, magenta bridge,
  white/gold final drop, gold dawn); a touch of film grain and chromatic aberration at the drops.

### 7. Cost control
- Every character, the booth and the flower sit behind a bounding sphere already (see
  `scene()`): keep that pattern, and add level of detail: fingers, face features and hair strands
  only within a few metres of the camera (pass the camera position in a global set by `direct`).
- `material()` and `glow()` call `scene()` again to find the material id. When the scene gets
  heavier, compute the id once after the march instead (in your own shade function).
- Optional: `#define LITE` that drops detail so the tile can still play it live.

### 8. Shots
- **Reframe:** the DJ close-ups (0:56, 2:59, 3:20) higher, past the cross. Move the truss out of the
  1:17 tilt-up and the final sunrise, or start the sunrise crane from in front of the truss.
- **Use the new detail:** add close-ups of the guitar hands on "thunder crashes" (1:34–1:41) and of
  DJ hands on the decks in the drops. Keep the cut times.

### 9. Check and render
- After each step, a sheet at the same 45 times as `shots/`, side by side with the baseline.
  Check the cue moments in particular (from `cues.md`): 0:33.22 cross ignites, 1:35.8 / 1:38 /
  1:40 lightning, 1:46.2 wave, 2:08.4 flash, 2:43 drop and bloom, 3:29.5 dawn begins, 3:44.9 end.
- Then `./render.sh`, and `ffprobe` that the result has 6748 frames and lasts 224.94 s.

## Acceptance

- Each character reads as their reference: the hair, clothes, instrument and pose make them
  recognisable at a glance in a wide shot, and faces read in close-ups.
- From the sea, the island reads as a rock outcrop in a storm.
- No sync change: every cue still lands on its frame.
- No shimmer on edges or stripes in the 1080 × 1920 output.
- The full render finishes without a GPU reset.
