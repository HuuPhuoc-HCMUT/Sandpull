const $ = (id) => document.getElementById(id);

function formatClock(date) {
  return date.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
}

function endTime(minutes) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

function verbose(minutes) {
  if (minutes >= 60) {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    const hours = h === 1 ? "1 hour" : `${h} hours`;
    if (!m) return hours;
    return `${hours}, ${m === 1 ? "1 minute" : `${m} minutes`}`;
  }
  return minutes === 1 ? "1 minute" : `${minutes} minutes`;
}

function short(minutes) {
  if (minutes >= 60) {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    return m ? `${h}h ${m}m` : `${h}h`;
  }
  return `${minutes}m`;
}

function spoken(minutes) {
  if (minutes < 60) return `${minutes} min`;
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  if (!m) return h === 1 ? "1 hr" : `${h} hr`;
  return `${h} hr, ${m} min`;
}

// Same defaults as AppSettings / DurationMapper (Balanced, 24h).
const DEAD_ZONE = 112;
const SHORT_BAND = 0.18;
const MAX_SECONDS = 24 * 3600;

function mapped(t) {
  const t1 = SHORT_BAND;
  const rest = Math.max(0.01, 1 - t1);
  const hour = 3600;
  const midEnd = 3 * 3600;
  const longEnd = 8 * 3600;
  if (t <= t1) return (t / t1) * 1800;
  const t2 = t1 + rest * 0.10;
  const t3 = t2 + rest * 0.14;
  const t4 = t3 + rest * 0.28;
  if (t <= t2) return 1800 + ((t - t1) / (t2 - t1)) * (hour - 1800);
  if (t <= t3) return hour + ((t - t2) / (t3 - t2)) * (midEnd - hour);
  if (t <= t4) return midEnd + ((t - t3) / (t4 - t3)) * (longEnd - midEnd);
  return longEnd + ((t - t4) / Math.max(0.01, 1 - t4)) * (MAX_SECONDS - longEnd);
}

function usableHeight(screenHeight) {
  return Math.max(400, screenHeight - 24) - DEAD_ZONE;
}

function normalizedFromSeconds(seconds) {
  const target = Math.min(MAX_SECONDS, Math.max(60, seconds));
  let lo = 0;
  let hi = 1;
  for (let i = 0; i < 28; i += 1) {
    const mid = (lo + hi) / 2;
    if (mapped(mid) < target) lo = mid;
    else hi = mid;
  }
  return (lo + hi) / 2;
}

function pixelsFromSeconds(seconds, screenHeight) {
  return DEAD_ZONE + normalizedFromSeconds(seconds) * usableHeight(screenHeight);
}

function rawSecondsFromDistance(px, screenHeight) {
  const effective = px - DEAD_ZONE;
  if (effective <= 0) return 0;
  const t = Math.min(1, effective / usableHeight(screenHeight));
  return Math.min(MAX_SECONDS, Math.max(60, Math.round(mapped(t) / 60) * 60));
}

function clockSlot(seconds, every) {
  if (seconds <= 0) return null;
  const end = new Date(Date.now() + seconds * 1000);
  if (end.getMinutes() % every !== 0 || end.getSeconds() >= 2) return null;
  return end.getHours() * 60 + end.getMinutes();
}

function alignToClock(seconds) {
  const end = new Date(Date.now() + seconds * 1000);
  const rem = end.getMinutes() % 15;
  const toPrev = rem * 60 + end.getSeconds();
  const toNext = (15 - rem) * 60 - end.getSeconds();
  const notch = 98;
  let aligned = seconds;
  if (toPrev > 0 && toPrev <= notch && toPrev <= toNext) aligned = seconds - toPrev;
  else if (toNext <= notch) aligned = seconds + toNext;
  return Math.min(MAX_SECONDS, Math.max(60, aligned));
}

function stickToClockQuarter(seconds, px, screenHeight, heldQuarter) {
  if (seconds <= 0) return 0;
  const end = new Date(Date.now() + seconds * 1000);
  const rem = end.getMinutes() % 15;
  const toPrev = rem * 60 + end.getSeconds();
  const toNext = (15 - rem) * 60 - end.getSeconds();
  const prevDur = Math.max(60, seconds - toPrev);
  const nextDur = Math.min(MAX_SECONDS, seconds + toNext);
  let best = null;
  for (const candidate of [prevDur, nextDur]) {
    if (Math.abs(seconds - candidate) > 210) continue;
    const dist = Math.abs(px - pixelsFromSeconds(candidate, screenHeight));
    const slot = clockSlot(candidate, 15);
    const band = heldQuarter != null && slot === heldQuarter ? 36 : 22;
    if (dist <= band && (best == null || dist < best.dist)) {
      best = { dur: candidate, dist };
    }
  }
  return best ? best.dur : alignToClock(seconds);
}

function minutesFromDistance(px, screenHeight, heldQuarter) {
  const raw = rawSecondsFromDistance(px, screenHeight);
  if (raw <= 0) return 0;
  return Math.round(stickToClockQuarter(raw, px, screenHeight, heldQuarter) / 60);
}

function isHalfHour(minutes) {
  return clockSlot(minutes * 60, 30) != null;
}

const TRASH_CANCEL = 58;

function trashCenter(root) {
  return { x: root.clientWidth / 2, y: root.clientHeight - 80 };
}

function trashState(root, to, minutes) {
  const center = trashCenter(root);
  const d = Math.hypot(to.x - center.x, to.y - center.y);
  const showDist = Math.max(root.clientHeight / 2, 200);
  const dead = minutes <= 0;
  if (dead || d >= showDist) {
    return { scale: 0, alpha: 0, inCancel: false };
  }
  const t = 1 - Math.max(0, d - TRASH_CANCEL) / (showDist - TRASH_CANCEL);
  const eased = t * t;
  const scale = 1.05 + eased * 1.05;
  return {
    scale,
    alpha: Math.min(1, (scale - 1.05) / 0.4 + 0.5),
    inCancel: d < TRASH_CANCEL,
  };
}

function setDim(el, on) {
  if (el) el.classList.toggle("on", !!on);
}

function placeTrash(el, state) {
  if (!el) return;
  if (state.scale < 0.01) {
    el.style.opacity = "0";
    el.classList.remove("on");
    return;
  }
  el.style.opacity = String(state.alpha);
  el.style.transform = `scale(${state.scale})`;
  el.classList.toggle("on", state.inCancel);
}

function placeDrag(root, line, glass, bubble, from, to, minutes, trash) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const len = Math.hypot(dx, dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI) - 90;
  const state = trash ? trashState(root, to, minutes) : { inCancel: false, scale: 0 };
  const dead = minutes <= 0;
  const faded = dead || state.inCancel;
  line.style.opacity = "1";
  line.style.left = `${from.x}px`;
  line.style.top = `${from.y}px`;
  line.style.height = `${len}px`;
  line.style.transform = `translateX(-50%) rotate(${angle}deg)`;
  line.classList.toggle("faded", faded);
  glass.style.opacity = faded ? "0.28" : "1";
  glass.style.left = `${to.x}px`;
  glass.style.top = `${to.y}px`;
  glass.style.transform = `rotate(${(len * 0.038) * (180 / Math.PI)}deg)`;
  const hideBubble = dead || state.inCancel;
  bubble.style.opacity = hideBubble ? "0" : "1";
  const bw = bubble.offsetWidth || 96;
  const bh = bubble.offsetHeight || 48;
  let bx = to.x - bw - 38;
  if (bx < 8) bx = to.x + 38;
  if (bx + bw > root.clientWidth - 8) bx = Math.max(8, to.x - bw - 38);
  let by = to.y - bh / 2;
  by = Math.max(8, Math.min(by, root.clientHeight - bh - 8));
  bubble.style.left = `${bx}px`;
  bubble.style.top = `${by}px`;
  bubble.classList.toggle("on-clock", !dead && !state.inCancel && isHalfHour(minutes));
  const minsEl = bubble.querySelector("strong");
  const endEl = bubble.querySelector("span");
  if (minsEl) minsEl.textContent = spoken(minutes);
  if (endEl) endEl.textContent = formatClock(endTime(minutes));
  placeTrash(trash, state);
  return state;
}

function hideDrag(line, glass, bubble, trash) {
  [line, glass, bubble, trash].forEach((el) => {
    if (el) el.style.opacity = "0";
  });
  if (trash) trash.classList.remove("on");
}

function iconCenter(icon, play) {
  const glyph = icon.querySelector(".hg") || icon;
  const a = glyph.getBoundingClientRect();
  const b = play.getBoundingClientRect();
  return { x: a.left + a.width / 2 - b.left, y: a.top + a.height / 2 - b.top };
}

// --- Product film ----------------------------------------------------------

function startFilm() {
  const play = $("filmPlay");
  const icon = $("filmIcon");
  const line = $("filmLine");
  const glass = $("filmGlass");
  const bubble = $("filmBubble");
  const cursor = $("filmCursor");
  const trash = $("filmTrash");
  const dim = $("filmDim");
  const save = $("filmSave");
  const typed = $("filmTyped");
  const saveBtn = $("filmSaveBtn");
  const status = $("filmStatus");
  const toggle = $("filmToggle");
  if (!play || !icon) return;

  let running = true;
  let timer = 0;

  const tickClock = () => {
    $("filmClock").textContent = formatClock(new Date());
  };
  tickClock();
  setInterval(tickClock, 10000);

  const wait = (ms) => new Promise((resolve) => {
    timer = window.setTimeout(resolve, ms);
  });

  async function loop() {
    while (running) {
      hideDrag(line, glass, bubble, trash);
      setDim(dim, false);
      cursor.style.opacity = "0";
      save.classList.remove("show");
      typed.textContent = "";
      saveBtn.classList.remove("pulse");
      status.textContent = "";

      const from = iconCenter(icon, play);
      const screenH = play.clientHeight;
      const target = pixelsFromSeconds(25 * 60, screenH);
      const driftX = Math.min(36, target * 0.22);
      const driftY = Math.sqrt(Math.max(0, target * target - driftX * driftX));
      cursor.style.left = `${from.x}px`;
      cursor.style.top = `${from.y}px`;
      cursor.style.opacity = "1";
      await wait(700);
      if (!running) break;

      setDim(dim, true);
      const steps = 42;
      for (let i = 1; i <= steps; i += 1) {
        if (!running) break;
        const t = 1 - (1 - i / steps) ** 2;
        const to = { x: from.x - t * driftX, y: from.y + t * driftY };
        const minutes = minutesFromDistance(Math.hypot(to.x - from.x, to.y - from.y), screenH);
        placeDrag(play, line, glass, bubble, from, to, minutes, trash);
        cursor.style.left = `${to.x}px`;
        cursor.style.top = `${to.y}px`;
        $("filmMins").textContent = spoken(minutes);
        $("filmEnd").textContent = formatClock(endTime(minutes));
        $("filmVerbose").textContent = spoken(minutes);
        $("filmSaveEnd").textContent = formatClock(endTime(minutes));
        await wait(38);
      }
      await wait(900);
      if (!running) break;

      hideDrag(line, glass, bubble, trash);
      setDim(dim, false);
      cursor.style.opacity = "0";
      save.classList.add("show");
      await wait(600);
      const word = "Focus";
      for (const ch of word) {
        if (!running) break;
        typed.textContent += ch;
        await wait(160);
      }
      await wait(500);
      saveBtn.classList.add("pulse");
      await wait(700);
      save.classList.remove("show");
      status.textContent = "25m";
      await wait(1800);
    }
  }

  toggle.addEventListener("click", () => {
    running = !running;
    toggle.textContent = running ? "Pause" : "Play";
    toggle.setAttribute("aria-pressed", String(running));
    if (running) loop();
    else {
      window.clearTimeout(timer);
      setDim(dim, false);
    }
  });

  if (!window.matchMedia("(prefers-reduced-motion: reduce)").matches) {
    loop();
  } else {
    save.classList.add("show");
    typed.textContent = "Focus";
    toggle.textContent = "Play";
    running = false;
  }
}

// --- Interactive pull ------------------------------------------------------

function startTry() {
  const icon = $("tryIcon");
  const canvas = $("tryCanvas");
  const line = $("tryLine");
  const glass = $("tryGlass");
  const bubble = $("tryBubble");
  const trash = $("tryTrash");
  const dim = $("tryDim");
  const save = $("trySave");
  const list = $("tryList");
  const rows = $("tryRows");
  const hint = $("tryHint");
  const field = $("tryField");
  if (!icon || !canvas) return;

  let dragging = false;
  let dragged = false;
  let inCancel = false;
  let heldQuarter = null;
  let minutes = 15;
  const timers = [];

  const setMinutes = (value) => {
    minutes = value;
    $("tryMins").textContent = spoken(minutes);
    $("tryEnd").textContent = formatClock(endTime(minutes));
    $("tryVerbose").textContent = spoken(minutes);
    $("trySaveEnd").textContent = formatClock(endTime(minutes));
    $("trySlider").style.width = `${normalizedFromSeconds(minutes * 60) * 100}%`;
    canvas.querySelectorAll("[data-mins]").forEach((btn) => {
      btn.classList.toggle("on", Number(btn.dataset.mins) === minutes);
    });
  };

  const origin = () => iconCenter(icon, canvas);

  const onMove = (event) => {
    if (!dragging) return;
    const box = canvas.getBoundingClientRect();
    const from = origin();
    const to = { x: event.clientX - box.left, y: event.clientY - box.top };
    const dist = Math.hypot(to.x - from.x, to.y - from.y);
    if (dist > DEAD_ZONE) dragged = true;
    const screenH = canvas.clientHeight;
    setMinutes(minutesFromDistance(dist, screenH, heldQuarter));
    const slot = clockSlot(minutes * 60, 15);
    heldQuarter = minutes > 0 ? slot : null;
    const state = placeDrag(canvas, line, glass, bubble, from, to, minutes, trash);
    if (state.inCancel && !inCancel && navigator.vibrate) navigator.vibrate(12);
    inCancel = state.inCancel;
    hint.textContent = inCancel ? "Release to cancel" : "Further down, longer timer";
  };

  const showList = () => {
    save.classList.remove("show");
    list.hidden = false;
    list.classList.add("show");
    hint.textContent = timers.length ? "Active timers" : "Drag the hourglass, or Add below";
    render();
  };

  const onUp = () => {
    if (!dragging) return;
    dragging = false;
    const cancelled = inCancel;
    inCancel = false;
    heldQuarter = null;
    setDim(dim, false);
    hideDrag(line, glass, bubble, trash);
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
    if (cancelled) {
      hint.textContent = "Cancelled. Pull again";
    } else if (dragged && minutes > 0) {
      save.classList.add("show");
      list.hidden = true;
      hint.textContent = "Name it, then Save";
      field.focus();
    } else {
      showList();
    }
  };

  icon.addEventListener("pointerdown", (event) => {
    event.preventDefault();
    dragging = true;
    dragged = false;
    inCancel = false;
    heldQuarter = null;
    setDim(dim, true);
    save.classList.remove("show");
    list.hidden = true;
    hint.textContent = "Further down, longer timer";
    icon.setPointerCapture(event.pointerId);
    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    onMove(event);
  });

  canvas.querySelectorAll("[data-mins]").forEach((btn) => {
    btn.addEventListener("click", () => setMinutes(Number(btn.dataset.mins)));
  });
  canvas.querySelectorAll("[data-label]").forEach((btn) => {
    btn.addEventListener("click", () => {
      field.value = btn.dataset.label;
      canvas.querySelectorAll("[data-label]").forEach((b) => b.classList.toggle("on", b === btn));
    });
  });

  $("tryCancel").addEventListener("click", () => {
    save.classList.remove("show");
    hint.textContent = "Drag the hourglass down";
  });

  const addTimer = () => {
    const title = field.value.trim() || "Timer";
    timers.unshift({ title, minutes, ends: endTime(minutes) });
    field.value = "";
    save.classList.remove("show");
    list.hidden = false;
    list.classList.add("show");
    hint.textContent = "Saved. Pull again to add another";
    render();
  };

  $("tryAdd").addEventListener("click", addTimer);
  field.addEventListener("keydown", (event) => {
    if (event.key === "Enter") addTimer();
  });

  function render() {
    if (!timers.length) {
      rows.innerHTML = `<p class="list-empty">Drag the menu bar icon or start a timer below</p>`;
      return;
    }
    rows.innerHTML = timers.map((item) => {
      const left = Math.max(0, Math.round((item.ends - Date.now()) / 1000));
      const mins = Math.max(1, Math.round(left / 60));
      return `<div class="row"><div class="grow spoken-block"><p><span>in</span> <strong>${spoken(mins)}</strong></p><p><span>at</span> <strong>${formatClock(item.ends)}</strong></p><small>${item.title}</small></div></div>`;
    }).join("");
  }

  setInterval(() => {
    if (timers.length) render();
  }, 1000);
  setMinutes(15);
}

startFilm();
startTry();
