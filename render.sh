#!/bin/zsh
# render.sh [out.mp4]: the whole video, 1080 x 1920, 30 fps, H.264, no audio, every frame at its exact song time.
# Drawn at SS x the size and scaled down (anti-aliasing), each frame in STRIPS strips so a heavy frame never trips the
# GPU watchdog. Rendered in 25 s parts (kept in parts/, so a run that stops can be started again), then joined.
# Slow: about 1.2 frames a second at SS=1.5 on an Apple M-series GPU (some 95 minutes); SS=1 is over twice as fast.
D=${0:A:h}; E=$D/node_modules/.bin/electron; [ -x $E ] || E=~/workshop/node_modules/.bin/electron; out=${1:-$D/flower-in-a-hurricane-9x16.mp4}; SS=${SS:-1.5}; P=$D/parts; mkdir -p $P
: > $P/list.txt
for a in $(seq 0 25 200); do
  b=$((a + 25)); [ $b -gt 224 ] && b=224.93
  f=$P/part-$(printf %03d $a).mp4
  if [ ! -s $f ]; then
    $E $D/render/main.cjs --scene=$D/flower.glsl --from=$a --to=$b --ss=$SS --strips=${STRIPS:-16} --steps=${STEPS:-260} --out=$f.tmp.mp4 2>&1 | grep --line-buffered -E "frame|encoded|wrote|FAILED|rror"
    [ -s $f.tmp.mp4 ] && mv $f.tmp.mp4 $f || { echo "part $a failed"; exit 1; }
  fi
  echo "file '$f'" >> $P/list.txt
done
ffmpeg -v error -y -f concat -safe 0 -i $P/list.txt -c copy -movflags +faststart $out && echo "wrote $out" && ffprobe -v error -count_frames -select_streams v:0 -show_entries stream=nb_read_frames,duration -of csv=p=0 $out
