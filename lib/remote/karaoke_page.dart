const karaokePageHtml = r'''
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Subsonica</title>
<style>
  :root {
    color-scheme: dark;
    --bg: #0E1014;
    --text: #F6F3EC;
    --muted: #A7ADBA;
    --accent: #F0B429;
  }
  * { box-sizing: border-box; }
  html, body {
    margin: 0;
    height: 100%;
    background: var(--bg);
    color: var(--text);
    font-family: "Segoe UI", Roboto, sans-serif;
  }
  body {
    min-height: 100%;
    display: flex;
    flex-direction: column;
    padding: 4vh 6vw 3vh;
  }
  header {
    display: flex;
    align-items: center;
    justify-content: flex-start;
    gap: clamp(16px, 2.2vw, 32px);
    min-height: 12vh;
    text-align: left;
  }
  #cover {
    width: clamp(84px, 16vh, 200px);
    height: clamp(84px, 16vh, 200px);
    border-radius: 12px;
    object-fit: cover;
    background: #171A21;
    flex: 0 0 auto;
  }
  #cover[hidden] { display: none; }
  .meta { min-width: 0; }
  #title {
    font-size: clamp(22px, 3.4vw, 48px);
    font-weight: 700;
  }
  #artist {
    margin-top: 0.4vh;
    color: var(--muted);
    font-size: clamp(16px, 2.2vw, 32px);
  }
  #stage {
    flex: 1;
    display: flex;
    flex-direction: column;
    justify-content: center;
    gap: 1.6vh;
    text-align: center;
    overflow: hidden;
  }
  .line {
    color: var(--muted);
    font-size: clamp(18px, 2.6vw, 36px);
    font-weight: 600;
    line-height: 1.25;
  }
  .line.near { opacity: 0.85; }
  .line.current {
    position: relative;
    color: #6f6756;
    font-size: clamp(32px, 5.6vw, 84px);
    font-weight: 800;
    line-height: 1.15;
  }
  .line.current .fill {
    position: absolute;
    inset: 0;
    color: var(--accent);
    clip-path: inset(0 calc(100% - var(--p, 0%)) 0 0);
  }
  .plain {
    white-space: pre-wrap;
    text-align: center;
    font-size: clamp(22px, 3.2vw, 44px);
    font-weight: 650;
    line-height: 1.45;
    color: var(--text);
    overflow: auto;
    max-height: 70vh;
  }
  .message {
    color: var(--muted);
    font-size: clamp(22px, 3vw, 42px);
  }
  #link {
    display: none;
    margin-top: 2vh;
    color: var(--muted);
    font-size: 14px;
  }
</style>
</head>
<body>
<header>
  <img id="cover" alt="" hidden>
  <div class="meta">
    <div id="title"></div>
    <div id="artist"></div>
  </div>
</header>
<main id="stage"></main>
<div id="link"></div>
<script>
const italian = (navigator.language || '').toLowerCase().startsWith('it');
const copy = italian ? {
  idle: 'Nessun brano in riproduzione',
  loading: 'Cerco il testo…',
  missing: 'Nessun testo trovato',
  unavailable: 'I testi non sono disponibili in questo momento.',
  instrumental: 'Questo brano è strumentale.',
  connecting: 'Connessione in corso…'
} : {
  idle: 'Nothing is playing',
  loading: 'Looking up lyrics…',
  missing: 'No lyrics found',
  unavailable: 'Lyrics are unavailable right now.',
  instrumental: 'This track is instrumental.',
  connecting: 'Connecting…'
};

const titleEl = document.getElementById('title');
const artistEl = document.getElementById('artist');
const coverEl = document.getElementById('cover');
const stage = document.getElementById('stage');
const linkEl = document.getElementById('link');

let state = { songId: '', title: '', artist: '', coverId: '', playing: false, speed: 1, positionMs: 0 };
let coverKey = '';
let coverTries = 0;
let doc = null;
let anchorMs = 0;
let anchorAt = 0;

function showMessage(text) {
  stage.replaceChildren();
  const node = document.createElement('div');
  node.className = 'message';
  node.textContent = text;
  stage.append(node);
}

function showPlain(text) {
  stage.replaceChildren();
  const node = document.createElement('div');
  node.className = 'plain';
  node.textContent = text;
  stage.append(node);
}

function positionNow() {
  if (!state.playing) return state.positionMs;
  const speed = Number(state.speed) || 1;
  return state.positionMs + (performance.now() - anchorAt) * speed;
}

function paintLines(position) {
  const lines = (doc && doc.lines) || [];
  let index = -1;
  for (let i = 0; i < lines.length; i++) {
    if (lines[i].timeMs <= position) index = i;
    else break;
  }
  stage.replaceChildren();
  const from = Math.max(0, index);
  const start = Math.max(0, from - 1);
  const end = Math.min(lines.length, Math.max(from + 1, 1) + 4);
  for (let i = start; i < end; i++) {
    const line = lines[i];
    const node = document.createElement('div');
    const current = i === index;
    node.className = current ? 'line current' : (Math.abs(i - index) <= 1 ? 'line near' : 'line');
    if (current) {
      const next = lines[i + 1];
      const endMs = next ? next.timeMs : line.timeMs + 5000;
      const span = Math.max(400, endMs - line.timeMs);
      const ratio = Math.max(0, Math.min(1, (position - line.timeMs) / span));
      node.style.setProperty('--p', (ratio * 100).toFixed(1) + '%');
      const base = document.createElement('span');
      base.textContent = line.text;
      const fill = document.createElement('span');
      fill.className = 'fill';
      fill.textContent = line.text;
      node.append(base, fill);
    } else {
      node.textContent = line.text;
    }
    stage.append(node);
  }
  if (!stage.childElementCount) showMessage(copy.missing);
}

function applyCover() {
  const id = state.coverId || '';
  if (!state.songId || !id) {
    coverKey = '';
    coverTries = 0;
    coverEl.removeAttribute('src');
    coverEl.hidden = true;
    return;
  }
  if (coverKey === id) return;
  coverKey = id;
  coverTries += 1;
  coverEl.hidden = false;
  coverEl.src = '/cover?id=' + encodeURIComponent(id);
}

coverEl.addEventListener('error', () => {
  coverEl.hidden = true;
  if (coverTries >= 2) return;
  const failed = coverKey;
  setTimeout(() => {
    if (state.coverId !== failed) return;
    coverKey = '';
    applyCover();
  }, 1200);
});

function render() {
  const songId = state.songId || '';
  titleEl.textContent = state.title || '';
  artistEl.textContent = state.artist || '';
  applyCover();
  if (!songId) {
    showMessage(copy.idle);
    return;
  }
  if (!doc || doc.songId !== songId || doc.status === 'loading') {
    showMessage(copy.loading);
    return;
  }
  if (doc.status === 'instrumental') {
    showMessage(copy.instrumental);
    return;
  }
  if (doc.status === 'unavailable') {
    showMessage(copy.unavailable);
    return;
  }
  if (doc.status === 'plain') {
    showPlain(doc.plain || '');
    return;
  }
  if (doc.status === 'synced') {
    paintLines(positionNow());
    return;
  }
  showMessage(copy.missing);
}

function applyState(next) {
  const previous = state.positionMs;
  state = Object.assign({ songId: '', title: '', artist: '', coverId: '', playing: false, speed: 1, positionMs: 0 }, next);
  if ((state.coverId || '') !== coverKey) coverTries = 0;
  if (state.positionMs !== previous || !state.playing) {
    anchorMs = state.positionMs;
    anchorAt = performance.now();
  }
}

function onMessage(raw) {
  let message;
  try { message = JSON.parse(raw); } catch (_) { return; }
  if (!message || message.jsonrpc !== '2.0' || !message.method) return;
  const params = message.params || {};
  if (message.method === 'playback.state') {
    applyState(params);
    anchorAt = performance.now();
    render();
  } else if (message.method === 'lyrics.document') {
    doc = params;
    render();
  } else if (message.method === 'lyrics.progress') {
    if (params.songId && params.songId === state.songId) {
      state.positionMs = Number(params.positionMs) || 0;
      if (typeof params.playing === 'boolean') state.playing = params.playing;
      if (params.speed != null) state.speed = Number(params.speed) || 1;
      anchorAt = performance.now();
    }
  }
}

function connect() {
  linkEl.style.display = 'block';
  linkEl.textContent = copy.connecting;
  const socket = new WebSocket((location.protocol === 'https:' ? 'wss://' : 'ws://') + location.host + '/ws');
  socket.addEventListener('open', () => { linkEl.style.display = 'none'; });
  socket.addEventListener('message', (event) => onMessage(event.data));
  socket.addEventListener('close', () => {
    linkEl.style.display = 'block';
    setTimeout(connect, 1000);
  });
}

connect();
render();
setInterval(() => {
  if (doc && doc.status === 'synced' && state.playing) render();
}, 50);
</script>
</body>
</html>
''';
