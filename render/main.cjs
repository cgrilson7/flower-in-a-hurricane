// Offline renderer for a Demoscene scene: every frame drawn at its exact time, encoded to H.264.
//   electron main.cjs --scene=flower.glsl --out=video.mp4 [--from=0 --to=248.9 --fps=30 --w=1080 --h=1920 --bitrate=16000000 --ss=1 --strips=1 --steps=220]
//   --ss=2 draws at twice the size and scales down (anti-aliasing); --strips=16 draws each frame in 16 strips (safe for heavy scenes)
//   electron main.cjs --scene=flower.glsl --stills=44.4,92.6 --outdir=stills   (JPEGs, to check framing)
const { app, BrowserWindow } = require('electron')
const path = require('path')
const fs = require('fs')
const { spawnSync } = require('child_process')
const { build } = require('./host.cjs')

const arg = Object.fromEntries(process.argv.filter((a) => a.startsWith('--') && a.includes('=')).map((a) => a.slice(2).split(/=(.*)/s).slice(0, 2)))
const num = (k, d) => (arg[k] === undefined ? d : Number(arg[k]))

app.commandLine.appendSwitch('ignore-gpu-blocklist')
app.commandLine.appendSwitch('disable-renderer-backgrounding')
app.commandLine.appendSwitch('disable-background-timer-throttling')

app.whenReady().then(async () => {
  try {
    const src = fs.readFileSync(path.resolve(arg.scene), 'utf8').replace(/^#define T0 .*$/m, '#define T0 0.0')
    const cfg = {
      frag: build(src),
      w: num('w', 1080), h: num('h', 1920), fps: num('fps', 30),
      from: num('from', 0), to: num('to', 248.9), bitrate: num('bitrate', 16e6), steps: num('steps', 220), ss: num('ss', 1), strips: num('strips', 1),
      stills: arg.stills ? arg.stills.split(',').map(Number) : null,
      outdir: path.resolve(arg.outdir || 'stills'),
      out264: arg.out ? path.resolve(arg.out).replace(/\.mp4$/, '') + '.h264' : null
    }
    if (cfg.stills) fs.mkdirSync(cfg.outdir, { recursive: true })
    const win = new BrowserWindow({
      show: false, width: 320, height: 320,
      webPreferences: { nodeIntegration: true, contextIsolation: false, backgroundThrottling: false }
    })
    win.webContents.on('console-message', (e, level, msg) => console.log(e?.message ?? msg))
    await win.loadFile(path.join(__dirname, 'page.html'))
    await win.webContents.executeJavaScript(`run(${JSON.stringify(cfg)})`)
    if (cfg.out264) {
      const out = path.resolve(arg.out)
      const r = spawnSync('ffmpeg', ['-v', 'error', '-y', '-i', cfg.out264, '-c', 'copy', '-bsf:v', `setts=pts=N/(${cfg.fps}*TB):dts=N/(${cfg.fps}*TB)`, '-video_track_timescale', String(cfg.fps * 1000), '-movflags', '+faststart', out], { stdio: 'inherit' })
      if (r.status !== 0) throw new Error('ffmpeg could not wrap the stream')
      fs.unlinkSync(cfg.out264)
      console.log('wrote ' + out)
    }
    app.exit(0)
  } catch (e) {
    console.error('FAILED: ' + (e?.message ?? e))
    app.exit(1)
  }
})
