const FORMS = {
  classic: { name: "Starter", svg: `<path d="M9 6h24L23.3 21H18.7L9 6Z"/><path d="M9 36h24L23.3 21H18.7L9 36Z"/><path class="sand" d="M12 8h18L21 20Z"/><path class="sand" d="M11 35h20L21 25Z"/><rect class="cap" x="7" y="4" width="28" height="3.2" rx="1"/><rect class="cap" x="7" y="34.8" width="28" height="3.2" rx="1"/>` },
  needle: { name: "Needle", svg: `<path d="M17 5h8L22.2 21h-2.4L17 5Z"/><path d="M17 37h8L22.2 21h-2.4L17 37Z"/><path class="sand" d="M18.2 7h5.6L21 19Z"/><path class="sand" d="M18 36h6L21 26Z"/><rect class="cap" x="15" y="3.4" width="12" height="2.4" rx="1"/><rect class="cap" x="15" y="36.2" width="12" height="2.4" rx="1"/>` },
  twin: { name: "Twin", svg: `<path d="M4 8h14L14.2 21H7.8L4 8Z"/><path d="M4 34h14L14.2 21H7.8L4 34Z"/><path class="sand" d="M6 10h10L11 19Z"/><path class="sand" d="M6 33h10L11 25Z"/><rect class="cap" x="3" y="6.2" width="16" height="2.4" rx="1"/><rect class="cap" x="3" y="33.4" width="16" height="2.4" rx="1"/><path d="M24 8h14L34.2 21H27.8L24 8Z"/><path d="M24 34h14L34.2 21H27.8L24 34Z"/><path class="sand" d="M26 10h10L31 19Z"/><path class="sand" d="M26 33h10L31 25Z"/><rect class="cap" x="23" y="6.2" width="16" height="2.4" rx="1"/><rect class="cap" x="23" y="33.4" width="16" height="2.4" rx="1"/>` },
  orb: { name: "Orb", svg: `<circle cx="21" cy="13" r="8.2"/><circle cx="21" cy="29" r="8.2"/><path class="sand" d="M15 10.5a6.2 6.2 0 0 1 12 0c0 3-2.4 5.4-6 6.4-3.6-1-6-3.4-6-6.4Z"/><path class="sand" d="M15 33.2a6.2 6.2 0 0 0 12 0c0-2.6-2.2-4.6-6-5.4-3.8.8-6 2.8-6 5.4Z"/><rect class="cap" x="11" y="4" width="20" height="2.6" rx="1"/><rect class="cap" x="11" y="35.4" width="20" height="2.6" rx="1"/>` },
  monument: { name: "Monument", svg: `<path d="M6 7h30L24.5 21h-7L6 7Z"/><path d="M6 35h30L24.5 21h-7L6 35Z"/><path class="sand" d="M9 9h24L21 19Z"/><path class="sand" d="M8 34h26L21 26Z"/><rect class="cap" x="4" y="3.6" width="34" height="4" rx="1"/><rect class="cap" x="4" y="34.4" width="34" height="4" rx="1"/>` },
};

const FACES = {
  both: { name: "Glass + time" },
  sand: { name: "Sand only" },
  digits: { name: "Digits" },
  ring: { name: "Ring" },
};

const CHIMES = {
  hush: { name: "Hush", notes: [] },
  bell: { name: "Bell", notes: [784, 1176] },
  wood: { name: "Wood", notes: [196, 247] },
  glass: { name: "Glass", notes: [988, 1480] },
};

const PRESETS = [
  { id: "starter", name: "Starter", form: "classic", face: "both", chime: "hush" },
  { id: "needle", name: "Needle", form: "needle", face: "digits", chime: "glass" },
  { id: "twin", name: "Twin", form: "twin", face: "sand", chime: "wood" },
  { id: "orb", name: "Orb", form: "orb", face: "ring", chime: "bell" },
  { id: "monument", name: "Monument", form: "monument", face: "both", chime: "bell" },
];

const $ = (id) => document.getElementById(id);
const state = { form: "classic", face: "both", chime: "hush" };

function lookTitle() {
  return PRESETS.find((p) => p.form === state.form && p.face === state.face && p.chime === state.chime)?.name
    || `${FORMS[state.form].name} · ${FACES[state.face].name}`;
}

function applyLook() {
  const root = $("storePreview");
  root.dataset.face = state.face;
  root.dataset.form = state.form;
  const svg = `<svg class="hg-form" viewBox="0 0 42 42" aria-hidden="true">${FORMS[state.form].svg}</svg>`;
  $("storeIconGlass").innerHTML = svg;
  $("storeBigGlass").innerHTML = svg;
  $("lookName").textContent = lookTitle();
  $("applyLook").href = `sandpull://look?form=${state.form}&face=${state.face}&chime=${state.chime}`;
}

function renderChoices(host, items, selected, onPick, withGlyph) {
  host.innerHTML = "";
  for (const [id, item] of Object.entries(items)) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "opt" + (id === selected ? " on" : "");
    const glyph = withGlyph ? `<svg class="hg-form" viewBox="0 0 42 42">${item.svg}</svg>` : "";
    btn.innerHTML = `${glyph}<span>${item.name}</span>`;
    btn.addEventListener("click", () => onPick(id));
    host.appendChild(btn);
  }
}

function refresh() {
  applyLook();
  const current = PRESETS.find((p) => p.form === state.form && p.face === state.face && p.chime === state.chime);
  $("presets").innerHTML = PRESETS.map((p) =>
    `<button type="button" class="preset${current && current.id === p.id ? " on" : ""}" data-preset="${p.id}">${p.name}</button>`
  ).join("");
  $("presets").querySelectorAll("[data-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const p = PRESETS.find((x) => x.id === btn.dataset.preset);
      state.form = p.form;
      state.face = p.face;
      state.chime = p.chime;
      refresh();
      playChime(p.chime);
    });
  });
  renderChoices($("formChoices"), FORMS, state.form, (id) => { state.form = id; refresh(); }, true);
  renderChoices($("faceChoices"), FACES, state.face, (id) => { state.face = id; refresh(); });
  renderChoices($("chimeChoices"), CHIMES, state.chime, (id) => { state.chime = id; refresh(); playChime(id); });
}

let audio;
function playChime(id) {
  const spec = CHIMES[id];
  if (!spec || !spec.notes.length) return;
  audio = audio || new (window.AudioContext || window.webkitAudioContext)();
  if (audio.state === "suspended") audio.resume();
  const now = audio.currentTime;
  spec.notes.forEach((freq, i) => {
    const osc = audio.createOscillator();
    const gain = audio.createGain();
    osc.type = id === "wood" ? "triangle" : "sine";
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.16, now + 0.02 + i * 0.08);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.65 + i * 0.1);
    osc.connect(gain);
    gain.connect(audio.destination);
    osc.start(now + i * 0.08);
    osc.stop(now + 0.8 + i * 0.1);
  });
}

refresh();
