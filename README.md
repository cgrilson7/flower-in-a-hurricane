# 🌸 Flower In A Hurricane 🌀

**A whole music video in one fragment shader.** No models, no textures, no keyframes, no video editor.
Four musicians, a rock in the sea, a seven-metre cross and one stubborn flower, all computed from
65 KB of GLSL and cut to the beat of the song.

![Four frames: the stage in the storm, the singer, a DJ at the decks, and dawn](assets/hero.jpg)

| The cross ignites · 0:33 | The first drop · 0:47 | Hands on the decks · 0:52 |
|:---:|:---:|:---:|
| ![The golden cross flares as the drums come in](assets/gif/cross-ignites.gif) | ![The camera rushes the island as the beams come on](assets/gif/first-drop.gif) | ![A DJ's hands on the mixer, the cross running with veins behind him](assets/gif/dj-hands.gif) |

A fan-made visual for "Flower In A Hurricane". **The audio is not in this repository**, and neither is
the finished MP4: everything here is the picture, and the code that makes it.

## What you are looking at

Every pixel is a ray marched through a signed-distance field. There is no geometry anywhere, only a
function, `scene(p)`, that answers "how far is point `p` from the nearest surface?"

- **Four characters on one shared skeleton.** Shoulders, elbows, wrists, knees and ankles are solved
  with two-bone inverse kinematics from where the hands need to be: on the strings, round a mic, on
  a crossfader. Faces have brows, lids that blink, lips that move when they sing. Hands have
  fingers that curl.
- **The guitarist** strums in sixteenths and changes chord position every bar. His guitar has frets
  spaced by the twelfth root of two, six strings and a tortoiseshell guard.
- **The singer** wears a pinstripe suit whose stripes are computed in each limb's own coordinates,
  so they follow the cloth and fade out before they can shimmer.
- **The DJs** play a mixer with LEDs that blink on the beat, and a synth with all its keys.
- **The cross** is seven metres tall. It fades in as plain gold, and from the first drop it becomes
  a visualizer: veins of gold and silver run up it and flare on every kick.
- **The storm** is seen from inside its eye: cloud bands spiral in to a hole of stars overhead.
  Lightning forks. Rain falls in three layers. Puddles on the rock mirror the stage.
- **The sea** throws foam on the rocks, and at 1:46 it rears up and washes everything away.

| "Thunder crashes" · 1:37 | Washed away · 1:46 | The eye · 2:24 | The second drop · 2:43 |
|:---:|:---:|:---:|:---:|
| ![The guitarist's hands, lit by lightning](assets/gif/thunder.gif) | ![A wall of water closes on the island](assets/gif/the-wave.gif) | ![The camera tilts from the flower up into the eye of the storm](assets/gif/the-eye.gif) | ![The flower blooms and grows in a white flash](assets/gif/second-drop.gif) |

## The song, in pictures

Each still is the exact frame at that second of the song, with the line being sung then. The full
cue sheet, with every section, drum entry and timed line, is in [`cues.md`](cues.md).

<table>
<tr>
<td align="center"><img src="assets/stills/t66.50.jpg" width="200"><br><b>1:04</b><br><i>Only love never hesitates</i></td>
<td align="center"><img src="assets/stills/t73.50.jpg" width="200"><br><b>1:12</b><br><i>Like a flower in a hurricane</i></td>
<td align="center"><img src="assets/stills/t78.00.jpg" width="200"><br><b>1:15</b><br><i>We see the sun rise into another day</i></td>
<td align="center"><img src="assets/stills/t92.50.jpg" width="200"><br><b>1:30</b><br><i>I will die before I walk away</i></td>
</tr>
<tr>
<td align="center"><img src="assets/stills/t95.90.jpg" width="200"><br><b>1:35</b><br><i>Thunder crashes</i></td>
<td align="center"><img src="assets/stills/t102.00.jpg" width="200"><br><b>1:41</b><br><i>And my heart is aching</i></td>
<td align="center"><img src="assets/stills/t106.00.jpg" width="200"><br><b>1:46</b><br><i>Till I'm washed away</i></td>
<td align="center"><img src="assets/stills/t125.00.jpg" width="200"><br><b>2:02</b><br><i>Let's take it fast, just make it flash</i></td>
</tr>
<tr>
<td align="center"><img src="assets/stills/t139.00.jpg" width="200"><br><b>2:17</b><br><i>I'll be there to the very last breath</i></td>
<td align="center"><img src="assets/stills/t158.00.jpg" width="200"><br><b>2:36</b><br><i>Like a flower in a hurricane</i></td>
<td align="center"><img src="assets/stills/t179.00.jpg" width="200"><br><b>2:58</b><br><i>You know I think about it now and then</i></td>
<td align="center"><img src="assets/stills/t190.00.jpg" width="200"><br><b>3:08</b><br><i>Something beautiful coming to an end</i></td>
</tr>
<tr>
<td align="center"><img src="assets/stills/t12.00.jpg" width="200"><br><b>0:12</b><br>The island, before the drums</td>
<td align="center"><img src="assets/stills/t117.00.jpg" width="200"><br><b>1:57</b><br>Instrumental, from above</td>
<td align="center"><img src="assets/stills/t193.00.jpg" width="200"><br><b>3:12</b><br><i>And if we ever get through</i></td>
<td align="center"><img src="assets/stills/t221.00.jpg" width="200"><br><b>3:41</b><br>Dawn</td>
</tr>
</table>

## Where it started

The first version drew the band as capsules and spheres on a flat disc. It is still here, as
[`flower.v1.glsl`](flower.v1.glsl), and [`PLAN.md`](PLAN.md) is the plan that turned one into the other.
Left is before, right is after, at the same second of the song.

| The singer · 1:32 | The guitarist · 1:35 |
|:---:|:---:|
| ![Before and after: the singer](assets/before-after-singer.jpg) | ![Before and after: the guitarist](assets/before-after-guitarist.jpg) |
| **The island · 0:50** | **A DJ · 0:56** |
| ![Before and after: the island from the sea](assets/before-after-island.jpg) | ![Before and after: a DJ close-up](assets/before-after-dj.jpg) |

All 45 comparison frames are in [`shots/`](shots) (before) and [`shots-v2/`](shots-v2) (after).

## Sync

The song is 126 BPM, so a beat is 0.4762 s and a bar is 1.9048 s. One function, `direct(t)`, is the
whole edit: given the song's second it sets the camera, every light, the weather, the bloom of the
flower and the pose of each body. Frame `n` of the video is drawn at exactly `n / 30` seconds, so
nothing can drift.

| Second | What lands |
|---|---|
| 0:33.22 | The drums enter and the cross flares |
| 0:47.74 | First drop: beams on, veins start running |
| 1:35.8 · 1:38.0 · 1:40.0 | Three lightning strikes, on "crashes", "flows" and "flashes" |
| 1:46.2 | The wave hits |
| 2:08.4 | "Flash" |
| 2:42.97 | Second drop: the flower blooms and more than doubles in size |
| 3:29.5 | The storm breaks and the sun comes up |

## Run it

You need Node, `ffmpeg` and a GPU. Electron is used only as a headless WebGL 2 window.

```bash
npm install
./preview.sh sheet.jpg 33.4 53 92.5 163.6     # stills at those song seconds, tiled
W=1080 H=1920 SS=2 ./preview.sh frame.jpg 92.5 # one full-size, anti-aliased frame
./render.sh                                    # the whole video: 6,748 frames, 1080 × 1920, 30 fps, no audio
```

The full render is slow: about 1.2 frames a second on an Apple M-series GPU with the default 1.5×
supersampling, so roughly an hour and a half. `SS=1 ./render.sh` is more than twice as fast. It
renders in 25-second parts, so a run that stops can be started again where it left off. To hear it,
mux your own copy of the song:

```bash
ffmpeg -i flower-in-a-hurricane-9x16.mp4 -i your-copy-of-the-song.m4a -c copy -shortest with-sound.mp4
```

## What is here

```
flower.glsl       the video: bodies, island, sea, sky, timeline, light, grade (1,092 lines)
flower.v1.glsl    the first version, for comparison
cues.md           the song's sections, tempo and timed lines
PLAN.md           the plan that got from v1 to here
render/           the offline renderer: host.cjs wraps the scene in a shader, page.html draws
                  each frame in strips and feeds the hardware H.264 encoder, main.cjs drives it
preview.sh        stills at chosen seconds
render.sh         the full video
assets/           the stills and GIFs on this page
shots/ shots-v2/  45 frames before and after, at the same seconds
```

## Credits

Picture and code by Colin G. Wilson with Claude. The signed-distance techniques owe a great deal to
Íñigo Quílez's published work. The song and its words belong to their artists; this is an
unofficial fan visual, and the characters are stylised drawings, not likenesses.
