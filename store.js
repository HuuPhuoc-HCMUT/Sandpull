const PALETTES = {
  teal: {
    name: "Teal",
    pack: null,
    swatch: "#2f7d8a",
    vars: {
      "--accent": "#2f7d8a",
      "--accent-deep": "#1a5560",
      "--line": "#6ad0d8",
      "--ink": "#1e3036",
      "--desktop": "#c8d6d8",
      "--menubar": "#b7c6c8",
      "--bubble": "#163038",
    },
  },
  graphite: {
    name: "Graphite",
    pack: "colorways",
    swatch: "#4a5560",
    vars: {
      "--accent": "#4a5560",
      "--accent-deep": "#2d3640",
      "--line": "#c5ced6",
      "--ink": "#1c2228",
      "--desktop": "#c5c9cf",
      "--menubar": "#b4b8bf",
      "--bubble": "#1c2228",
    },
  },
  matcha: {
    name: "Matcha",
    pack: "colorways",
    swatch: "#4f7a4a",
    vars: {
      "--accent": "#4f7a4a",
      "--accent-deep": "#2f4d2c",
      "--line": "#8fd084",
      "--ink": "#243026",
      "--desktop": "#c8d4c2",
      "--menubar": "#b6c4b0",
      "--bubble": "#1c2a1e",
    },
  },
  dusk: {
    name: "Dusk",
    pack: "colorways",
    swatch: "#5a4f86",
    vars: {
      "--accent": "#5a4f86",
      "--accent-deep": "#3a3458",
      "--line": "#b4a8e0",
      "--ink": "#2a2740",
      "--desktop": "#c9c3d4",
      "--menubar": "#b8b1c6",
      "--bubble": "#221e36",
    },
  },
  ember: {
    name: "Ember",
    pack: "colorways",
    swatch: "#a45a38",
    vars: {
      "--accent": "#a45a38",
      "--accent-deep": "#6e3a22",
      "--line": "#f0a06a",
      "--ink": "#3a2418",
      "--desktop": "#d8c4b6",
      "--menubar": "#c7b3a4",
      "--bubble": "#2e1a12",
    },
  },
};

const METALS = {
  brass: { name: "Brass", pack: null, swatch: "#8a6420", cap: "#8a6420", stroke: "#2f7d8a", glass: "#c5d8db" },
  silver: { name: "Silver", pack: "metals", swatch: "#9aa4ad", cap: "#8b959e", stroke: "#5a6570", glass: "#d5dde2" },
  ink: { name: "Ink", pack: "metals", swatch: "#1e3036", cap: "#1e3036", stroke: "#1e3036", glass: "#9eb0b6" },
  rose: { name: "Rose", pack: "metals", swatch: "#b87878", cap: "#a86868", stroke: "#8a5050", glass: "#ead4d4" },
};

const SANDS = {
  gold: { name: "Gold", pack: null, swatch: "#c49a4a", fill: "#c49a4a" },
  pale: { name: "Pale", pack: "sands", swatch: "#efe0b8", fill: "#efe0b8" },
  ember: { name: "Ember", pack: "sands", swatch: "#d07a3a", fill: "#d07a3a" },
  ocean: { name: "Ocean", pack: "sands", swatch: "#4aa3ad", fill: "#4aa3ad" },
};

const PRESETS = [
  { id: "classic", name: "Classic", palette: "teal", metal: "brass", sand: "gold" },
  { id: "night", name: "Night desk", palette: "graphite", metal: "silver", sand: "pale" },
  { id: "garden", name: "Garden", palette: "matcha", metal: "brass", sand: "gold" },
  { id: "theatre", name: "Theatre", palette: "dusk", metal: "ink", sand: "pale" },
  { id: "kiln", name: "Kiln", palette: "ember", metal: "rose", sand: "ember" },
];

const PACKS = {
  studio: {
    id: "studio",
    name: "Studio",
    price: 8,
    featured: true,
    blurb: "Every colorway, metal, and sand. The whole wardrobe, one unlock.",
    chips: ["#4a5560", "#4f7a4a", "#5a4f86", "#a45a38", "#9aa4ad", "#b87878", "#efe0b8", "#d07a3a"],
  },
  colorways: {
    id: "colorways",
    name: "Colorways",
    price: 4,
    blurb: "Graphite, Matcha, Dusk, and Ember on the line and windows.",
    chips: ["#4a5560", "#4f7a4a", "#5a4f86", "#a45a38"],
  },
  metals: {
    id: "metals",
    name: "Metals",
    price: 3,
    blurb: "Silver, Ink, and Rose caps on the hourglass.",
    chips: ["#9aa4ad", "#1e3036", "#b87878"],
  },
  sands: {
    id: "sands",
    name: "Sands",
    price: 3,
    blurb: "Pale, Ember, and Ocean sand in the glass.",
    chips: ["#efe0b8", "#d07a3a", "#4aa3ad"],
  },
};

const $ = (id) => document.getElementById(id);

const state = {
  palette: "teal",
  metal: "brass",
  sand: "gold",
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
  const palettePack = PALETTES[state.palette].pack;
  const metalPack = METALS[state.metal].pack;
  const sandPack = SANDS[state.sand].pack;
  if (palettePack) needed.add(palettePack);
  if (metalPack) needed.add(metalPack);
  if (sandPack) needed.add(sandPack);
  return [...needed];
}

function lookPrice() {
  if (state.cart.includes("studio")) return 0;
  return packsForLook()
    .filter((id) => !state.cart.includes(id))
    .reduce((sum, id) => sum + PACKS[id].price, 0);
}

function cartTotal() {
  if (state.cart.includes("studio")) return PACKS.studio.price;
  return state.cart.reduce((sum, id) => sum + PACKS[id].price, 0);
}

function activePreset() {
  return PRESETS.find((p) =>
    p.palette === state.palette && p.metal === state.metal && p.sand === state.sand
  );
}

function lookTitle() {
  const preset = activePreset();
  if (preset) return preset.name;
  return `${PALETTES[state.palette].name} · ${METALS[state.metal].name} · ${SANDS[state.sand].name}`;
}

function applyLook() {
  const root = $("storePreview");
  const palette = PALETTES[state.palette];
  const metal = METALS[state.metal];
  const sand = SANDS[state.sand];
  const vars = {
    ...palette.vars,
    "--hg-glass": metal.glass,
    "--hg-stroke": state.metal === "brass" ? palette.vars["--accent"] : metal.stroke,
    "--hg-cap": metal.cap,
    "--hg-sand": sand.fill,
  };
  for (const [key, value] of Object.entries(vars)) {
    root.style.setProperty(key, value);
  }
}

function money(n) {
  return `$${n}`;
}

function renderSwatches(host, items, selected, onPick) {
  host.innerHTML = "";
  for (const [id, item] of Object.entries(items)) {
    const btn = document.createElement("button");
    btn.type = "button";
    btn.className = "swatch" + (id === selected ? " on" : "");
    btn.style.setProperty("--swatch", item.swatch);
    const tag = item.pack ? "" : "<em>In</em>";
    btn.innerHTML = `<i></i><span>${item.name}</span>${tag}`;
    btn.addEventListener("click", () => onPick(id));
    host.appendChild(btn);
  }
}

function renderPresets() {
  const current = activePreset();
  $("presets").innerHTML = PRESETS.map((p) => `
    <button type="button" class="preset${current && current.id === p.id ? " on" : ""}" data-preset="${p.id}">
      <i style="background:${PALETTES[p.palette].swatch}"></i>
      ${p.name}
    </button>
  `).join("");
  $("presets").querySelectorAll("[data-preset]").forEach((btn) => {
    btn.addEventListener("click", () => {
      const p = PRESETS.find((x) => x.id === btn.dataset.preset);
      state.palette = p.palette;
      state.metal = p.metal;
      state.sand = p.sand;
      refresh();
    });
  });
}

function renderControls() {
  renderSwatches($("paletteSwatches"), PALETTES, state.palette, (id) => {
    state.palette = id;
    refresh();
  });
  renderSwatches($("metalSwatches"), METALS, state.metal, (id) => {
    state.metal = id;
    refresh();
  });
  renderSwatches($("sandSwatches"), SANDS, state.sand, (id) => {
    state.sand = id;
    refresh();
  });
}

function renderTotal() {
  $("lookName").textContent = lookTitle();
  const needed = packsForLook().filter((id) => !state.cart.includes(id) && !state.cart.includes("studio"));
  if (!needed.length) {
    $("storeTotal").textContent = "Included, or already in your cart";
    $("addLook").hidden = true;
  } else {
    $("storeTotal").textContent = `${needed.map((id) => PACKS[id].name).join(" + ")} · ${money(lookPrice())}`;
    $("addLook").hidden = false;
    $("addLook").textContent = `Add ${needed.map((id) => PACKS[id].name).join(" + ")} · ${money(lookPrice())}`;
  }
}

function renderPacks() {
  $("packGrid").innerHTML = Object.values(PACKS).map((pack) => {
    const owned = state.cart.includes(pack.id) || (pack.id !== "studio" && state.cart.includes("studio"));
    const chips = pack.chips.map((c) => `<i style="background:${c}"></i>`).join("");
    return `
    <li class="${pack.featured ? "featured" : ""}">
      <div class="pack-chips">${chips}</div>
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
  if (id === "studio") {
    state.cart = ["studio"];
  } else if (!state.cart.includes("studio") && !state.cart.includes(id)) {
    state.cart.push(id);
  }
  saveCart();
  refresh();
}

function addLook() {
  if (state.cart.includes("studio")) return;
  for (const id of packsForLook()) {
    if (!state.cart.includes(id)) state.cart.push(id);
  }
  saveCart();
  refresh();
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
$("addStudio").addEventListener("click", () => addPack("studio"));

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
    look: { palette: state.palette, metal: state.metal, sand: state.sand },
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
