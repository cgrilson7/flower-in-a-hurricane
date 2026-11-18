#!/bin/zsh
# preview.sh <out.jpg> t1 t2 ... : render the video at those song seconds (portrait, offline), tiled 4 across.
# SS=2 supersamples (as the full render does), STRIPS and STEPS as in render/main.cjs.
# W/H set the still size (default 270 x 480). OUTDIR keeps the single stills (t<seconds>.jpg); default a new temp folder.
D=${0:A:h}; E=$D/node_modules/.bin/electron; [ -x $E ] || E=~/workshop/node_modules/.bin/electron; out=$1; shift; W=${W:-270}; H=${H:-480}; O=${OUTDIR:-$(mktemp -d)}
$E $D/render/main.cjs --scene=$D/flower.glsl --stills=${(j:,:)@} --outdir=$O --w=$W --h=$H --ss=${SS:-1} --strips=${STRIPS:-8} --steps=${STEPS:-220} 2>&1 | grep -E "stills:|t=|FAILED|rror"
args=(); ins=""; lay=(); i=0
for t in "$@"; do f=$O/t$(printf %.2f $t).jpg; [ -f $f ] || continue; args+=(-i $f); ins="${ins}[${i}:v]"; lay+=("$(( (i%4)*W ))_$(( (i/4)*H ))"); i=$((i+1)); done
if [ $i -gt 1 ]; then ffmpeg -v error -y $args -filter_complex "${ins}xstack=inputs=${i}:layout=${(j:|:)lay}:fill=black" $out; elif [ $i -eq 1 ]; then cp $args[2] $out; fi
