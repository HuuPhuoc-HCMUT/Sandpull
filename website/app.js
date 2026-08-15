const $ = (id) => document.getElementById(id);

function pad(n) {
  return String(n).padStart(2, "0");
}

function formatClock(date) {
  return `${pad(date.getHours())}:${pad(date.getMinutes())}`;
}

function endTime(minutes) {
  return new Date(Date.now() + minutes * 60 * 1000);
}

function verbose(minutes) {
  if (minutes >= 60) {
    const h = Math.floor(minutes / 60);
    const m = minutes % 60;
    if (!m) return h === 1 ? "1 hour" : `${h} hours`;
    return `${h}h ${m}m`;
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

function isQuarter(minutes) {
  const end = endTime(minutes);
  const slot = end.getMinutes() % 15;
  return slot === 0;
}

const DEAD_ZONE = 48;

function minutesFromDistance(px) {
  const effective = px - DEAD_ZONE;
  if (effective <= 0) return 0;
  const t = Math.min(1, effective / 340);
  const seconds = t <= 0.4
    ? (t / 0.4) * 1800
    : 1800 + ((t - 0.4) / 0.6) * 5400;
  return Math.min(120, Math.max(1, Math.round(seconds / 60)));
}

function placeDrag(root, line, glass, bubble, from, to, minutes) {
  const dx = to.x - from.x;
  const dy = to.y - from.y;
  const len = Math.hypot(dx, dy);
  const angle = Math.atan2(dy, dx) * (180 / Math.PI) - 90;
  line.style.opacity = "1";
  line.style.left = `${from.x}px`;
  line.style.top = `${from.y}px`;
  line.style.height = `${len}px`;
  line.style.transform = `translateX(-50%) rotate(${angle}deg)`;
  const dead = minutes <= 0;
  line.classList.toggle("faded", dead);
  glass.style.opacity = dead ? "0.35" : "1";
  glass.style.left = `${to.x}px`;
  glass.style.top = `${to.y}px`;
  glass.style.transform = `rotate(${Math.min(28, dy / 12)}deg)`;
  bubble.style.opacity = dead ? "0" : "1";
  bubble.style.left = `${to.x}px`;
  bubble.style.top = `${to.y}px`;
  bubble.classList.toggle("on-clock", !dead && isQuarter(minutes));
  const minsEl = bubble.querySelector("strong");
  const endEl = bubble.querySelector("span");
  if (minsEl) minsEl.textContent = short(minutes).replace("h", "h ").trim() + (minutes < 60 ? "" : "");
  if (minsEl) minsEl.textContent = minutes >= 60 ? short(minutes) : `${minutes} min`;
  if (endEl) endEl.textContent = formatClock(endTime(minutes));
}

function hideDrag(line, glass, bubble) {
  [line, glass, bubble].forEach((el) => {
    if (el) el.style.opacity = "0";
  });
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
      hideDrag(line, glass, bubble);
      cursor.style.opacity = "0";
      save.classList.remove("show");
      typed.textContent = "";
      saveBtn.classList.remove("pulse");
      status.textContent = "";

      const from = iconCenter(icon, play);
      cursor.style.left = `${from.x}px`;
      cursor.style.top = `${from.y}px`;
      cursor.style.opacity = "1";
      await wait(700);
      if (!running) break;

      const steps = 42;
      for (let i = 1; i <= steps; i += 1) {
        if (!running) break;
        const t = 1 - (1 - i / steps) ** 2;
        const to = { x: from.x, y: from.y + 16 + t * 220 };
        const minutes = minutesFromDistance(to.y - from.y);
        placeDrag(play, line, glass, bubble, from, to, minutes);
        cursor.style.left = `${to.x}px`;
        cursor.style.top = `${to.y}px`;
        $("filmMins").textContent = minutes >= 60 ? short(minutes) : `${minutes} min`;
        $("filmEnd").textContent = formatClock(endTime(minutes));
        $("filmVerbose").textContent = verbose(minutes);
        $("filmSaveEnd").textContent = formatClock(endTime(minutes));
        await wait(38);
      }
      await wait(900);
      if (!running) break;

      hideDrag(line, glass, bubble);
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
    else window.clearTimeout(timer);
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
  const save = $("trySave");
  const list = $("tryList");
  const rows = $("tryRows");
  const hint = $("tryHint");
  const field = $("tryField");
  if (!icon || !canvas) return;

  let dragging = false;
  let dragged = false;
  let minutes = 15;
  const timers = [];

  const setMinutes = (value) => {
    minutes = value;
    $("tryMins").textContent = minutes >= 60 ? short(minutes) : `${minutes} min`;
    $("tryEnd").textContent = formatClock(endTime(minutes));
    $("tryVerbose").textContent = verbose(minutes);
    $("tryShort").textContent = short(minutes);
    $("trySaveEnd").textContent = formatClock(endTime(minutes));
    $("trySlider").style.width = `${Math.min(100, (minutes / 90) * 100)}%`;
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
    setMinutes(minutesFromDistance(dist));
    placeDrag(canvas, line, glass, bubble, from, to, minutes);
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
    hideDrag(line, glass, bubble);
    window.removeEventListener("pointermove", onMove);
    window.removeEventListener("pointerup", onUp);
    if (dragged && minutes > 0) {
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
      const label = left < 60 ? `${left}s` : `${Math.floor(left / 60)}m`;
      return `<div class="row"><div class="grow"><b>${item.title}</b><small>${formatClock(item.ends)}</small></div><div class="pill">${label}</div></div>`;
    }).join("");
  }

  setInterval(() => {
    if (timers.length) render();
  }, 1000);
  setMinutes(15);
}

startFilm();
startTry();
