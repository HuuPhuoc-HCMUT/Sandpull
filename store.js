const FORMS = {
  classic: {
    name: "Starter",
    pack: null,
    blurb: "The free glass",
    svg: `<path d="M9 6h24L23.3 21H18.7L9 6Z"/><path d="M9 36h24L23.3 21H18.7L9 36Z"/><path class="sand" d="M12 8h18L21 20Z"/><path class="sand" d="M11 35h20L21 25Z"/><rect class="cap" x="7" y="4" width="28" height="3.2" rx="1"/><rect class="cap" x="7" y="34.8" width="28" height="3.2" rx="1"/>`,
  },
  needle: {
    name: "Needle",
    pack: "forms",
    blurb: "A thin spine",
    svg: `<path d="M17 5h8L22.2 21h-2.4L17 5Z"/><path d="M17 37h8L22.2 21h-2.4L17 37Z"/><path class="sand" d="M18.2 7h5.6L21 19Z"/><path class="sand" d="M18 36h6L21 26Z"/><rect class="cap" x="15" y="3.4" width="12" height="2.4" rx="1"/><rect class="cap" x="15" y="36.2" width="12" height="2.4" rx="1"/>`,
  },
  twin: {
    name: "Twin",
    pack: "forms",
    blurb: "Two glasses",
    svg: `<path d="M4 8h14L14.2 21H7.8L4 8Z"/><path d="M4 34h14L14.2 21H7.8L4 34Z"/><path class="sand" d="M6 10h10L11 19Z"/><path class="sand" d="M6 33h10L11 25Z"/><rect class="cap" x="3" y="6.2" width="16" height="2.4" rx="1"/><rect class="cap" x="3" y="33.4" width="16" height="2.4" rx="1"/><path d="M24 8h14L34.2 21H27.8L24 8Z"/><path d="M24 34h14L34.2 21H27.8L24 34Z"/><path class="sand" d="M26 10h10L31 19Z"/><path class="sand" d="M26 33h10L31 25Z"/><rect class="cap" x="23" y="6.2" width="16" height="2.4" rx="1"/><rect class="cap" x="23" y="33.4" width="16" height="2.4" rx="1"/>`,
  },
  orb: {
    name: "Orb",
    pack: "forms",
    blurb: "Round bowls",
    svg: `<circle cx="21" cy="13" r="8.2"/><circle cx="21" cy="29" r="8.2"/><path class="sand" d="M15 10.5a6.2 6.2 0 0 1 12 0c0 3-2.4 5.4-6 6.4-3.6-1-6-3.4-6-6.4Z"/><path class="sand" d="M15 33.2a6.2 6.2 0 0 0 12 0c0-2.6-2.2-4.6-6-5.4-3.8.8-6 2.8-6 5.4Z"/><rect class="cap" x="11" y="4" width="20" height="2.6" rx="1"/><rect class="cap" x="11" y="35.4" width="20" height="2.6" rx="1"/>`,
  },
  monument: {
    name: "Monument",
    pack: "forms",
    blurb: "A heavy glass",
    svg: `<path d="M6 7h30L24.5 21h-7L6 7Z"/><path d="M6 35h30L24.5 21h-7L6 35Z"/><path class="sand" d="M9 9h24L21 19Z"/><path class="sand" d="M8 34h26L21 26Z"/><rect class="cap" x="4" y="3.6" width="34" height="4" rx="1"/><rect class="cap" x="4" y="34.4" width="34" height="4" rx="1"/>`,
  },
};

const FACES = {
  both: { name: "Glass + time", pack: null, blurb: "The starter face" },
  sand: { name: "Sand only", pack: "faces", blurb: "Just the pour" },
  digits: { name: "Digits", pack: "faces", blurb: "A quiet countdown" },
  ring: { name: "Ring", pack: "faces", blurb: "A circle that empties" },
};

const CHIMES = {
  hush: { name: "Hush", pack: null, blurb: "System default", notes: [440] },
  bell: { name: "Bell", pack: "chimes", blurb: "A clear strike", notes: [784, 1176] },
  wood: { name: "Wood", pack: "chimes", blurb: "A low knock", notes: [196, 247] },
  glass: { name: "Glass", pack: "chimes", blurb: "A thin ring", notes: [988, 1480, 1976] },
};

const PRESETS = [
  { id: "starter", name: "Starter", form: "classic", face: "both", chime: "hush" },
  { id: "needle", name: "Needle watch", form: "needle", face: "digits", chime: "glass" },
  { id: "twin", name: "Twin desk", form: "twin", face: "sand", chime: "wood" },
  { id: "orb", name: "Orb ring", form: "orb", face: "ring", chime: "bell" },
  { id: "monument", name: "Monument", form: "monument", face: "both", chime: "bell" },
];

const PACKS = {
  atelier: {
    id: "atelier",
    name: "Atelier",
    price: 11,
    featured: true,
    blurb: "Every form, face, and chime. The desk you keep looking at.",
  },
  forms: {
    id: "forms",
    name: "Forms",
    price: 5,
    blurb: "Needle, Twin, Orb, Monument. A different object in the menu bar.",
  },
  faces: {
    id: "faces",
    name: "Faces",
    price: 4,
    blurb: "Sand only, digits, and the emptying ring.",
  },
  chimes: {
    id: "chimes",
    name: "Chimes",
    price: 4,
    blurb: "Bell, wood, and glass when a timer ends.",
  },
};

const $ = (id) => document.getElementById(id);

const state = {
  form: "classic",
  face: "both",
  chime: "hush",
  cart: loadCart(),
};

function loadCart() {
  try {
    const raw = JSON.parse(localStorage.getItem("sandpull.cart") || "[]");
    return raw.filter((id) => PACKS[id]);
  } catch {
    return [];
  }
}

function saveCart() {
  localStorage.setItem("sandpull.cart", JSON.stringify(state.cart));
}

function packsForLook() {
  const needed = new Set();
  if (FORMS[state.form].pack) needed.add(FORMS[state.form].pack);
  if (FACES[state.face].pack) needed.add(FACES[state.face].pack);
  if (CHIMES[state.chime].pack) needed.add(CHIMES[state.chime].pack);
  return [...needed];
}

function lookPrice() {
  if (state.cart.includes("atelier")) return 0;
  return packsForLook()
    .filter((id) => !state.cart.includes(id))
    .reduce((sum, id) => sum + PACKS[id].price, 0);
}

function cartTotal() {
  if (state.cart.includes("atelier")) return PACKS.atelier.price;
  return state.cart.reduce((sum, id) => sum + PACKS[id].price, 0);
}

function activePreset() {
  return PRESETS.find((p) =>
    p.form === state.form && p.face === state.face && p.chime === state.chime
  );
}

function lookTitle() {
  return activePreset()?.name
    || `${FORMS[state.form].name} · ${FACES[state.face].name} · ${CHIMES[state.chime].name}`;
}

function formMarkup() {
  return `<svg class="hg-form" viewBox="0 0 42 42" aria-hidden="true">${FORMS[state.form].svg}</svg>`;
}

function applyLook() {
  const root = $("storePreview");
  root.dataset.face = state.face;
  root.dataset.form = state.form;
  $("storeIconGlass").innerHTML = formMarkup();
  $("storeBigGlass").innerHTML = formMarkup();
}

function money(n) {
  return `$${n}`;
}

function renderChoices(host, items, selected, onPick) {
  host.innerHTML = "";
  for (const [id, item] of Object.entries(items)) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "choice" + (id === selected ? " on" : "");
    const lock = item.pack ? `<em>${money(PACKS[item.pack].price)}</em>` : "<em>In</em>";
    btn.innerHTML = `<strong>${item.name}</strong><span>${item.blurb}</span>${lock}`;
    btn.addEventListener("click", () => onPick(id));
    host.appendChild(btn);
  }
}

function renderPresets() {
  const current = activePreset();
  $("presets").innerHTML = PRESETS.map((p) => `
    <button type="button" class="preset${current && current.id === p.id ? " on" : ""}" data-preset="${p.id}">
      ${p.name}${p.id === "starter" ? "" : ""}
    </button>
  `).join("");
  $("presets").querySelectorAll("[data-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const p = PRESETS.find((x) => x.id === btn.dataset.preset);
      state.form = p.form;
      state.face = p.face;
      state.chime = p.chime;
      refresh();
      if (p.chime !== "hush") playChime(p.chime);
    });
  });
}

function renderControls() {
  renderChoices($("formChoices"), FORMS, state.form, (id) => {
    state.form = id;
    refresh();
  });
  renderChoices($("faceChoices"), FACES, state.face, (id) => {
    state.face = id;
    refresh();
  });
  renderChoices($("chimeChoices"), CHIMES, state.chime, (id) => {
    state.chime = id;
    refresh();
    playChime(id);
  });
}

function renderTotal() {
  $("lookName").textContent = lookTitle();
  const needed = packsForLook().filter((id) => !state.cart.includes(id) && !state.cart.includes("atelier"));
  if (!needed.length) {
    $("storeTotal").textContent = "This one is free, or already in your cart";
    $("addLook").hidden = true;
  } else {
    $("storeTotal").textContent = `Unlock ${needed.map((id) => PACKS[id].name).join(" + ")} to keep it · ${money(lookPrice())}`;
    $("addLook").hidden = false;
    $("addLook").textContent = `Keep this on the Mac · ${money(lookPrice())}`;
  }
}

function renderPacks() {
  $("packGrid").innerHTML = Object.values(PACKS).map((pack) => {
    const owned = state.cart.includes(pack.id) || (pack.id !== "atelier" && state.cart.includes("atelier"));
    return `
    <li class="${pack.featured ? "featured" : ""}">
      <h3>${pack.name}</h3>
      <p>${pack.blurb}</p>
      <div class="pack-foot">
        <p class="store-total">${money(pack.price)}</p>
        <button type="button" class="btn-save" data-pack="${pack.id}">${owned ? "In cart" : "Add"}</button>
      </div>
    </li>`;
  }).join("");
  $("packGrid").querySelectorAll("[data-pack]").forEach((btn) => {
    btn.addEventListener("click", () => addPack(btn.dataset.pack));
  });
}

function renderCart() {
  const cart = $("cart");
  if (!state.cart.length) {
    cart.hidden = true;
    document.body.classList.remove("has-cart");
    return;
  }
  cart.hidden = false;
  document.body.classList.add("has-cart");
  $("cartRows").innerHTML = state.cart.map((id) => `
    <li>
      <span>${PACKS[id].name}</span>
      <span>${money(PACKS[id].price)}</span>
      <button type="button" class="cancel" data-remove="${id}">Remove</button>
    </li>
  `).join("");
  $("cartTotal").textContent = money(cartTotal());
  cart.querySelectorAll("[data-remove]").forEach((btn) => {
    btn.addEventListener("click", () => {
      state.cart = state.cart.filter((id) => id !== btn.dataset.remove);
      saveCart();
      refresh();
    });
  });
}

function addPack(id) {
  if (id === "atelier") {
    state.cart = ["atelier"];
  } else if (!state.cart.includes("atelier") && !state.cart.includes(id)) {
    state.cart.push(id);
  }
  saveCart();
  refresh();
}

function addLook() {
  if (state.cart.includes("atelier")) return;
  for (const id of packsForLook()) {
    if (!state.cart.includes(id)) state.cart.push(id);
  }
  saveCart();
  refresh();
}

let audio;
function playChime(id) {
  const spec = CHIMES[id];
  if (!spec || id === "hush") return;
  audio = audio || new (window.AudioContext || window.webkitAudioContext)();
  if (audio.state === "suspended") audio.resume();
  const now = audio.currentTime;
  spec.notes.forEach((freq, i) => {
    const osc = audio.createOscillator();
    const gain = audio.createGain();
    osc.type = id === "wood" ? "triangle" : "sine";
    osc.frequency.value = freq;
    gain.gain.setValueAtTime(0.0001, now);
    gain.gain.exponentialRampToValueAtTime(0.18, now + 0.02 + i * 0.08);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 0.7 + i * 0.12);
    osc.connect(gain);
    gain.connect(audio.destination);
    osc.start(now + i * 0.08);
    osc.stop(now + 0.85 + i * 0.12);
  });
}

function refresh() {
  applyLook();
  renderPresets();
  renderControls();
  renderTotal();
  renderPacks();
  renderCart();
}

$("addLook").addEventListener("click", addLook);
$("addStudio").addEventListener("click", () => addPack("atelier"));

$("openCheckout").addEventListener("click", () => {
  $("checkoutSummary").textContent = state.cart
    .map((id) => `${PACKS[id].name} ${money(PACKS[id].price)}`)
    .join(" · ") + ` · ${money(cartTotal())}`;
  $("checkout").showModal();
});

$("closeCheckout").addEventListener("click", () => $("checkout").close());

$("checkoutForm").addEventListener("submit", (event) => {
  event.preventDefault();
  const order = {
    id: `SP-${Date.now().toString(36).toUpperCase()}`,
    name: $("orderName").value.trim(),
    email: $("orderEmail").value.trim(),
    items: [...state.cart],
    total: cartTotal(),
    look: { form: state.form, face: state.face, chime: state.chime },
    at: new Date().toISOString(),
  };
  const prev = JSON.parse(localStorage.getItem("sandpull.orders") || "[]");
  prev.push(order);
  localStorage.setItem("sandpull.orders", JSON.stringify(prev));
  state.cart = [];
  saveCart();
  $("checkout").close();
  const done = $("orderDone");
  done.hidden = false;
  done.textContent = `Order ${order.id} saved for ${order.email}. A license email will follow when card checkout is live.`;
  refresh();
});

refresh();
