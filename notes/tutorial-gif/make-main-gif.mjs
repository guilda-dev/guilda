// Make _GUILDAdocPages/images/tutorial/main.gif from main-mock.html (see notes/tutorial-assets.md §7).
// usage (from the repository root): node notes/tutorial-gif/make-main-gif.mjs [px-per-frame=4] [fps=30] [colors=64]
// Needs Google Chrome and ffmpeg. Opens the mock in headless Chrome at 960x600, scrolls #doc (only the
// Main.mlx document; the rest of the desktop stays still) a few pixels per frame (eased at both ends), holds at the top and the bottom, then writes the GIF
// with an ffmpeg palette. The GIF loops: after the hold at the bottom it starts again at the top.
import { spawn, execFileSync } from 'node:child_process';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const root = path.resolve(here, '..', '..');
const mock = path.join(here, 'main-mock.html');
const out = path.join(root, '_GUILDAdocPages', 'images', 'tutorial', 'main.gif');
const step = Number(process.argv[2] || 4);   // pixels per frame
const fps = Number(process.argv[3] || 30);
const colors = Number(process.argv[4] || 64); // palette size chosen by ffmpeg over all frames
const holdTop = Math.round(fps * 1.2);      // frames held at the top
const holdBottom = Math.round(fps * 1.8);   // frames held at the bottom
const ease = Math.round(fps * 0.6);         // frames to speed up and to slow down
const W = 960, H = 600;

const chromeBin = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
const ffmpeg = fs.existsSync('/opt/homebrew/bin/ffmpeg') ? '/opt/homebrew/bin/ffmpeg' : 'ffmpeg';
const keep = process.env.KEEP_FRAMES;          // a folder: keep the PNG frames there
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'guilda-main-gif-'));
const frames = path.join(work, 'frames');
fs.mkdirSync(frames);

const port = 9500 + Math.floor(Math.random() * 400);
const chrome = spawn(chromeBin, ['--headless=new', `--remote-debugging-port=${port}`, '--hide-scrollbars',
  '--allow-file-access-from-files', `--user-data-dir=${path.join(work, 'profile')}`, `--window-size=${W},${H}`, 'about:blank'], { stdio: 'ignore' });
const sleep = ms => new Promise(r => setTimeout(r, ms));
try {
  let list;
  for (let i = 0; i < 50 && !list; i++) { try { list = await (await fetch(`http://127.0.0.1:${port}/json`)).json(); } catch { await sleep(200); } }
  const ws = new WebSocket(list.find(t => t.type === 'page').webSocketDebuggerUrl);
  await new Promise(r => { ws.onopen = r; });
  let id = 0; const pend = {};
  ws.onmessage = e => { const m = JSON.parse(e.data); if (m.id && pend[m.id]) { pend[m.id](m.result); delete pend[m.id]; } };
  const send = (method, params = {}) => new Promise(r => { const i = ++id; pend[i] = r; ws.send(JSON.stringify({ id: i, method, params })); });
  const evaluate = async expr => (await send('Runtime.evaluate', { expression: expr, returnByValue: true })).result.value;

  await send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: false });
  await send('Page.navigate', { url: 'file://' + mock });
  await sleep(1500);
  const max = await evaluate('setScroll(0)');

  // Scroll positions: hold, ease in, constant speed, ease out, hold.
  const ys = Array(holdTop).fill(0);
  const rampDist = step * ease / 2;              // distance covered while easing (each end)
  const cruise = Math.max(0, Math.ceil((max - 2 * rampDist) / step));
  let y = 0;
  for (let i = 1; i <= ease; i++) { y += step * i / ease; ys.push(y); }
  for (let i = 0; i < cruise; i++) { y += step; ys.push(y); }
  for (let i = ease; i >= 1; i--) { y += step * i / ease; ys.push(y); }
  for (let i = 0; i < holdBottom; i++) ys.push(max);

  let n = 0, last = null;
  for (const v of ys) {
    const yy = Math.min(max, Math.round(v));
    const file = path.join(frames, `f${String(n++).padStart(5, '0')}.png`);
    if (yy === last) { fs.copyFileSync(path.join(frames, `f${String(n - 2).padStart(5, '0')}.png`), file); continue; }
    await evaluate(`setScroll(${yy})`);
    const shot = await send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(file, Buffer.from(shot.data, 'base64'));
    last = yy;
  }
  ws.close();

  const palette = path.join(work, 'palette.png');
  const input = ['-y', '-loglevel', 'error', '-framerate', String(fps), '-i', path.join(frames, 'f%05d.png')];
  execFileSync(ffmpeg, [...input, '-vf', `palettegen=max_colors=${colors}:stats_mode=full`, palette]);
  execFileSync(ffmpeg, [...input, '-i', palette, '-lavfi', 'paletteuse=dither=none:diff_mode=rectangle', '-loop', '0', out]);
  const size = fs.statSync(out).size;
  console.log(`${out}: ${n} frames, ${(n / fps).toFixed(1)} s at ${fps} fps, ${step} px/frame, ${colors} colors, scroll ${max} px, ${(size / 1024 / 1024).toFixed(2)} MB`);
} finally {
  chrome.kill();
  if (keep) { fs.rmSync(keep, { recursive: true, force: true }); fs.renameSync(frames, keep); }
  fs.rmSync(work, { recursive: true, force: true });
}
