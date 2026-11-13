// Monora website — one orchestrated wake-up moment, then stillness.

(() => {
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ---- wave painter (the splash's signature sine) ----
  function paintWave(canvas, phase, alpha) {
    const ctx = canvas.getContext('2d');
    const { width: w, height: h } = canvas;
    ctx.clearRect(0, 0, w, h);
    ctx.beginPath();
    for (let x = 0; x <= w; x += 3) {
      const t = x / w;
      // amplitude fades toward the edges, like the app splash
      const envelope = 3.2 * Math.max(0, 1 - Math.abs(t - 0.5) * 2);
      const y = h / 2 + envelope * Math.sin(t * 4 * Math.PI - phase);
      if (x === 0) ctx.moveTo(x, y); else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = `rgba(196, 138, 74, ${alpha})`;
    ctx.lineWidth = 2.5;
    ctx.lineCap = 'round';
    ctx.stroke();
  }

  const waves = [
    { el: document.getElementById('wave'), phase: 0, raf: 0, alpha: 0.9 },
    { el: document.querySelector('.foot-wave'), phase: 0, raf: 0, alpha: 0.55 },
  ];

  function startWave(w) {
    if (reduceMotion || !w.el) return;
    const t0 = performance.now();
    const tick = (now) => {
      w.phase = ((now - t0) / 1000) * Math.PI * 2;
      paintWave(w.el, w.phase, w.alpha);
      w.raf = requestAnimationFrame(tick);
    };
    w.raf = requestAnimationFrame(tick);
  }
  function stopWave(w) { cancelAnimationFrame(w.raf); if (w.el) paintWave(w.el, 0, w.alpha); }

  // Draw the wave once immediately (also covers reduce-motion).
  waves.forEach((w) => paintWave(w.el, 0, w.alpha));
  // Then animate — wave only animates while the hero is on screen.
  const hero = document.querySelector('.hero');
  if ('IntersectionObserver' in window && !reduceMotion) {
    const io = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) startWave(waves[0]); else stopWave(waves[0]);
    }, { threshold: 0.05 });
    io.observe(hero);
  } else {
    startWave(waves[0]);
  }

  // ---- phone mock wake-up: seek bar fills, cover breathes, then play/pause ----
  const phone = document.getElementById('phone');
  const fill = document.getElementById('seek-fill');
  const thumb = document.getElementById('seek-thumb');
  const timeNow = document.getElementById('time-now');
  const playBtn = document.getElementById('mock-play');
  const iconPlay = document.getElementById('icon-play');
  const iconPause = document.getElementById('icon-pause');

  // 47% of 3:14
  const SONG_SECONDS = 194;
  const START_AT = Math.round(SONG_SECONDS * 0.47);
  const fmt = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;

  function setSeek(fraction) {
    const pct = `${Math.round(fraction * 100)}%`;
    fill.style.width = pct;
    thumb.style.left = pct;
  }

  if (reduceMotion) {
    setSeek(0.47);
    timeNow.textContent = fmt(START_AT);
    phone.classList.add('is-playing');
  } else {
    // the single load moment: fill 0 → 47% over 1.4s, ticking the clock
    const t0 = performance.now();
    const DURATION = 1400;
    const tick = (now) => {
      const t = Math.min(1, (now - t0) / DURATION);
      const eased = 1 - Math.pow(1 - t, 3); // easeOutCubic
      setSeek(0.47 * eased);
      timeNow.textContent = fmt(START_AT * eased);
      if (t < 1) requestAnimationFrame(tick);
    };
    requestAnimationFrame(tick);
    phone.classList.add('is-playing');
  }

  playBtn.addEventListener('click', () => {
    const nowPlaying = phone.classList.toggle('is-playing');
    // playing → show the pause icon; paused → show the play icon
    iconPlay.classList.toggle('hidden', nowPlaying);
    iconPause.classList.toggle('hidden', !nowPlaying);
    playBtn.setAttribute('aria-label', nowPlaying ? 'Pause' : 'Play');
  });

  // the collapse button in the mock is decorative — give it the squish only
  document.getElementById('mock-collapse').addEventListener('click', () => {});

  // ---- download metadata: fetch size + sha256 from the GitHub release ----
  async function hydrateApkMeta() {
    const sizeSpots = [document.getElementById('apk-size'), document.getElementById('apk-size-2')];
    const shaSpot = document.getElementById('apk-sha');
    const shaMatch = shaSpot?.textContent?.trim();
    try {
      const res = await fetch(
        'https://api.github.com/repos/explorefaith/Monora/releases/latest',
        { headers: { Accept: 'application/vnd.github+json' } }
      );
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      const rel = await res.json();
      const asset = (rel.assets || []).find((a) => a.name.endsWith('.apk'));
      if (asset) {
        const mb = (asset.size / (1024 * 1024)).toFixed(1);
        sizeSpots.forEach((el) => el && (el.textContent = `${mb} MB`));
        if (shaSpot && !shaMatch?.match(/^[0-9a-f]{64}$/)) {
          shaSpot.textContent = `${asset.name} · ${asset.download_count} downloads`;
        }
      }
    } catch {
      // offline or release not yet published — leave the static fallback text
    }
  }
  hydrateApkMeta();
})();
