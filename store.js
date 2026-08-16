const PALETTES = {
  teal: {
    name: "Teal",
    pack: null,
    swatch: "#2f7d8a",
    vars: {
      "--accent": "#2f7d8a",
      "--accent-deep": "#1a5560",
      "--line": "#4aa3ad",
      "--ink": "#1e3036",
      "--desktop": "#d5e4e6",
      "--menubar": "#c5d2d4",
      "--bubble": "#1e3036",
    },
  },
  graphite: {
    name: "Graphite",
    pack: "colorways",
    swatch: "#4a5560",
    vars: {
      "--accent": "#4a5560",
      "--accent-deep": "#2d3640",
      "--line": "#8a97a3",
      "--ink": "#1c2228",
      "--desktop": "#d8dce2",
      "--menubar": "#c5cad1",
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
      "--line": "#7aaa6e",
      "--ink": "#243026",
      "--desktop": "#d9e4d4",
      "--menubar": "#c5d2c0",
      "--bubble": "#243026",
    },
  },
  dusk: {
    name: "Dusk",
    pack: "colorways",
    swatch: "#5a4f86",
    vars: {
      "--accent": "#5a4f86",
      "--accent-deep": "#3a3458",
      "--line": "#8b80b8",
      "--ink": "#2a2740",
      "--desktop": "#ddd8e8",
      "--menubar": "#c9c3d6",
      "--bubble": "#2a2740",
    },
  },
  ember: {
    name: "Ember",
    pack: "colorways",
    swatch: "#a45a38",
    vars: {
      "--accent": "#a45a38",
      "--accent-deep": "#6e3a22",
      "--line": "#d4895c",
      "--ink": "#3a2418",
      "--desktop": "#ead8cc",
      "--menubar": "#d8c4b6",
      "--bubble": "#3a2418",
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

const PACKS = {
  colorways: { id: "colorways", name: "Colorways", price: 4, blurb: "Graphite, Matcha, Dusk, and Ember for the line, list, and windows." },
  metals: { id: "metals", name: "Metals", price: 3, blurb: "Silver, Ink, and Rose caps on the hourglass." },
  sands: { id: "sands", name: "Sands", price: 3, blurb: "Pale, Ember, and Ocean sand in the glass." },
  studio: { id: "studio", name: "Studio", price: 8, blurb: "Every colorway, metal, and sand. One unlock." },
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
    btn.innerHTML = `<i></i><span>${item.name}${item.pack ? "" : " · in"}</span>`;
    btn.addEventListener("click", () => onPick(id));
    host.appendChild(btn);
  }
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
  const needed = packsForLook().filter((id) => !state.cart.includes(id) && !state.cart.includes("studio"));
  if (!needed.length) {
    $("storeTotal").textContent = "This look is in your cart, or it is included.";
    $("addLook").hidden = true;
  } else {
    $("storeTotal").textContent = `Packs for this look: ${needed.map((id) => PACKS[id].name).join(", ")} · ${money(lookPrice())}`;
    $("addLook").hidden = false;
    $("addLook").textContent = `Add packs · ${money(lookPrice())}`;
  }
}

function renderPacks() {
  $("packGrid").innerHTML = Object.values(PACKS).map((pack) => {
    const owned = state.cart.includes(pack.id) || (pack.id !== "studio" && state.cart.includes("studio"));
    return `
    <li>
      <h3>${pack.name}</h3>
      <p>${pack.blurb}</p>
      <p class="store-total">${money(pack.price)}</p>
      <button type="button" class="btn-save" data-pack="${pack.id}">${owned ? "In cart" : "Add"}</button>
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
    return;
  }
  cart.hidden = false;
  $("cartRows").innerHTML = state.cart.map((id) => `
    <li>
      <span>${PACKS[id].name}</span>
      <span>${money(PACKS[id].price)}</span>
      <button type="button" class="cancel" data-remove="${id}">Remove</button>
    </li>
  `).join("");
  $("cartTotal").textContent = `Total ${money(cartTotal())}`;
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
  for (const id of packsForLook()) addPack(id);
}

function refresh() {
  applyLook();
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
