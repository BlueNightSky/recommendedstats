// RecommendedStats site: data explorer over docs/data (written by RecommendedStatsNode's `npm run site`).
// Route: #/<class>/<spec>/<raid|mplus>, e.g. #/druid/restoration/raid

const CLASSES = {
  DEATHKNIGHT: { name: "Death Knight", color: "#C41E3A", icon: "deathknight" },
  DEMONHUNTER: { name: "Demon Hunter", color: "#A330C9", icon: "demonhunter" },
  DRUID: { name: "Druid", color: "#FF7C0A", icon: "druid" },
  EVOKER: { name: "Evoker", color: "#33937F", icon: "evoker" },
  HUNTER: { name: "Hunter", color: "#AAD372", icon: "hunter" },
  MAGE: { name: "Mage", color: "#3FC7EB", icon: "mage" },
  MONK: { name: "Monk", color: "#00FF98", icon: "monk" },
  PALADIN: { name: "Paladin", color: "#F48CBA", icon: "paladin" },
  PRIEST: { name: "Priest", color: "#FFFFFF", icon: "priest" },
  ROGUE: { name: "Rogue", color: "#FFF468", icon: "rogue" },
  SHAMAN: { name: "Shaman", color: "#0070DD", icon: "shaman" },
  WARLOCK: { name: "Warlock", color: "#8788EE", icon: "warlock" },
  WARRIOR: { name: "Warrior", color: "#C69B6D", icon: "warrior" },
};
const SPEC_NAMES = { BEASTMASTERY: "Beast Mastery" };
const STATS = [
  { key: "haste", name: "Haste", color: "var(--haste)" },
  { key: "crit", name: "Critical Strike", short: "Crit", color: "var(--crit)" },
  { key: "mastery", name: "Mastery", color: "var(--mastery)" },
  { key: "versatility", name: "Versatility", short: "Vers", color: "var(--versatility)" },
];
const SLOTS = [
  ["HEAD", "Head"], ["NECK", "Neck"], ["SHOULDER", "Shoulders"], ["BACK", "Back"], ["CHEST", "Chest"],
  ["WRIST", "Wrists"], ["HANDS", "Hands"], ["WAIST", "Waist"], ["LEGS", "Legs"], ["FEET", "Feet"],
  ["FINGER_1", "Ring 1"], ["FINGER_2", "Ring 2"], ["TRINKET_1", "Trinket 1"], ["TRINKET_2", "Trinket 2"],
  ["MAIN_HAND", "Main Hand"], ["OFF_HAND", "Off Hand"],
];
const CONTENT = { RAID: { slug: "raid", name: "Raid" }, MYTHICPLUS: { slug: "mplus", name: "Mythic+" } };
const NEW_TAG_DAYS = 7; // matches the addon's BiSWindow.lua

const $ = (id) => document.getElementById(id);
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const titleCase = (s) => s.charAt(0) + s.slice(1).toLowerCase();
const specName = (spec) => SPEC_NAMES[spec] ?? titleCase(spec);
const classIcon = (cls) => `https://wow.zamimg.com/images/wow/icons/large/classicon_${CLASSES[cls]?.icon ?? cls.toLowerCase()}.jpg`;
const fmtPct = (v) => (v >= 100 ? v.toFixed(0) : v.toFixed(1)) + "%";
const fmtDate = (iso) => new Date(iso + "T00:00:00Z").toLocaleDateString(undefined, { month: "short", day: "numeric", timeZone: "UTC" });

let INDEX = null;
const detailCache = new Map();
const state = { cls: null, spec: null, content: "RAID", scope: "OVERALL" };

async function loadJson(url) {
  const res = await fetch(url, { cache: "no-cache" });
  if (!res.ok) throw new Error(`${url}: ${res.status}`);
  return res.json();
}
function loadDetail(id) {
  if (!detailCache.has(id)) detailCache.set(id, loadJson(`data/specs/${id}.json`));
  return detailCache.get(id);
}

function specsByClass() {
  const out = {};
  for (const [id, s] of Object.entries(INDEX.specs)) (out[s.cls] ??= []).push({ id, ...s });
  for (const list of Object.values(out)) list.sort((a, b) => specName(a.spec).localeCompare(specName(b.spec)));
  return out;
}

/* Routing */
function readHash() {
  const [cls, spec, content] = location.hash.replace(/^#\/?/, "").split("/");
  if (!cls || !spec) return false;
  const id = `${cls.toUpperCase()}_${spec.toUpperCase()}`;
  if (!INDEX.specs[id]) return false;
  state.cls = cls.toUpperCase();
  state.spec = spec.toUpperCase();
  state.content = content === "mplus" ? "MYTHICPLUS" : "RAID";
  return true;
}
// A section anchor (#download, #features) is left alone until the visitor picks a spec themselves.
const isSectionHash = () => location.hash.length > 1 && !location.hash.startsWith("#/");
function writeHash({ userPicked = true } = {}) {
  if (!userPicked && isSectionHash()) return;
  const h = `#/${state.cls.toLowerCase()}/${state.spec.toLowerCase()}/${CONTENT[state.content].slug}`;
  if (location.hash !== h) history.replaceState(null, "", h);
}

/* Hero */
function renderHero() {
  const meta = INDEX.meta ?? {};
  const set = (k, v) => { const el = document.querySelector(`[data-stat="${k}"]`); if (el) el.textContent = v; };
  set("specs", Object.keys(INDEX.specs).length);
  set("sample", meta.sampleSize ?? 20);
  set("patch", meta.gamePatch ?? "");
  if (meta.updated) set("updated", fmtDate(meta.updated));
  if (meta.updated) $("heroStatus").textContent = `Data updated ${fmtDate(meta.updated)} · Patch ${meta.gamePatch}`;
}

/* Pickers */
function renderClassGrid() {
  const byClass = specsByClass();
  const order = Object.keys(byClass).sort((a, b) => (CLASSES[a]?.name ?? a).localeCompare(CLASSES[b]?.name ?? b));
  $("classGrid").innerHTML = order.map((cls) => `
    <button type="button" class="class-btn" role="tab" data-cls="${cls}" style="--c:${CLASSES[cls]?.color ?? "var(--gold)"}"
      aria-selected="${cls === state.cls}">
      <img src="${classIcon(cls)}" alt="" loading="lazy" onerror="this.style.visibility='hidden'">
      <span>${esc(CLASSES[cls]?.name ?? titleCase(cls))}</span>
    </button>`).join("");
  $("classGrid").onclick = (e) => {
    const btn = e.target.closest("[data-cls]");
    if (!btn) return;
    state.cls = btn.dataset.cls;
    state.spec = byClass[state.cls][0].spec;
    state.scope = "OVERALL";
    update();
  };
  return byClass;
}

function renderSpecRow(byClass) {
  $("specRow").innerHTML = (byClass[state.cls] ?? []).map((s) => `
    <button type="button" class="spec-btn" role="tab" data-spec="${s.spec}" aria-selected="${s.spec === state.spec}">${esc(specName(s.spec))}</button>`).join("");
  $("specRow").onclick = (e) => {
    const btn = e.target.closest("[data-spec]");
    if (!btn) return;
    state.spec = btn.dataset.spec;
    state.scope = "OVERALL";
    update();
  };
  for (const b of $("classGrid").children) b.setAttribute("aria-selected", b.dataset.cls === state.cls);
}

/* Stats */
function renderStats(info) {
  const t = info?.targets;
  if (!t) {
    $("statBars").innerHTML = `<p class="slot-empty">No stat targets for this content yet.</p>`;
    $("priority").innerHTML = "";
    return;
  }
  $("statBars").innerHTML = STATS.map((s) => {
    const target = t[s.key] ?? 0, high = t[s.key + "High"] ?? target;
    const scale = Math.max(high, target, 1) * 1.25;
    const pos = (v) => Math.min(100, (v / scale) * 100);
    return `
      <div class="stat-row" style="--sc:${s.color}">
        <div class="stat-top">
          <span class="stat-name">${s.name}</span>
          <span class="stat-val">${fmtPct(target)}<small>top ${fmtPct(high)}</small></span>
        </div>
        <div class="track" title="Target ${fmtPct(target)}, 90th percentile ${fmtPct(high)}">
          <span class="band" style="left:${pos(target)}%;width:${Math.max(0, pos(high) - pos(target))}%"></span>
          <span class="fill" data-w="${pos(target)}"></span>
          <span class="tick" style="left:calc(${pos(target)}% - 1.5px)"></span>
        </div>
      </div>`;
  }).join("");
  requestAnimationFrame(() => {
    for (const f of $("statBars").querySelectorAll(".fill")) f.style.width = f.dataset.w + "%";
  });

  // Same ordering as the addon's CharacterPanel.lua: weights sorted descending. -999 marks a stat
  // nobody in the sample carries.
  const w = info.weights;
  if (!w) {
    $("priority").innerHTML = `<span class="priority-label">Priority</span><span class="fine" style="margin:0">Not enough players to rank stats yet.</span>`;
    return;
  }
  const order = STATS.filter((s) => w[s.key] != null && w[s.key] > -999).sort((a, b) => w[b.key] - w[a.key]);
  $("priority").innerHTML = `<span class="priority-label" title="How tightly top players converge on each stat, not a simulation">Priority</span>` +
    order.map((s) => `<span class="prio" style="--sc:${s.color}">${s.short ?? s.name}</span>`).join(`<span class="prio-sep">›</span>`);
}

/* Talents */
function renderTalents(detail, info) {
  const names = state.content === "RAID" ? INDEX.names?.bosses : INDEX.names?.dungeons;
  const scoped = detail?.scoped ?? {};
  const sel = $("scopeSelect");
  const label = state.content === "RAID" ? "all bosses" : "all dungeons";
  sel.innerHTML = `<option value="OVERALL">Overall (${label})</option>` +
    (names ?? []).map((n) => `<option value="${esc(n.slug)}">${esc(n.name)}${scoped[n.slug] ? "" : " (overall build)"}</option>`).join("");
  if (![...sel.options].some((o) => o.value === state.scope)) state.scope = "OVERALL";
  sel.value = state.scope;
  sel.onchange = () => { state.scope = sel.value; renderTalents(detail, info); };

  const entry = state.scope !== "OVERALL" ? scoped[state.scope] : null;
  const builds = entry?.builds ?? detail?.talents ?? [];
  const total = entry?.n ?? info?.sample ?? builds.reduce((a, b) => a + b.n, 0);

  let note;
  if (state.scope === "OVERALL") note = `Spec-wide builds from ${total} top players.`;
  else if (entry) {
    const diff = entry.difficulty ? `${titleCase(entry.difficulty)} kills, ` : "";
    const src = entry.source === "current" ? " (current loadouts)" : "";
    note = `${diff}${entry.n} players${src}.`;
  } else note = `Not enough players here yet, showing the overall build.`;
  $("scopeNote").textContent = note;

  if (!builds.length) {
    $("builds").innerHTML = `<li class="slot-empty">No talent data for this content yet.</li>`;
    return;
  }
  $("builds").innerHTML = builds.map((b, i) => {
    const pct = total ? Math.round((b.n / total) * 100) : 0;
    return `
      <li class="build">
        <div class="build-top">
          <span class="build-rank">${i + 1}</span>
          <span class="build-share"><strong>${b.n}</strong> of ${total} players${i === 0 ? " · most common" : ""}</span>
        </div>
        <div class="build-meter"><span style="width:${pct}%"></span></div>
        <div class="build-code" title="${esc(b.code)}">${esc(b.code)}</div>
        <div class="build-actions">
          <button type="button" class="mini-btn primary" data-copy="${esc(b.code)}">
            <svg viewBox="0 0 24 24"><path d="M16 1H4a2 2 0 0 0-2 2v14h2V3h12V1Zm3 4H8a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2V7a2 2 0 0 0-2-2Zm0 16H8V7h11v14Z"/></svg>
            Copy loadout
          </button>
          <a class="mini-btn" href="https://www.wowhead.com/talent-calc/blizzard/${encodeURIComponent(b.code)}" target="_blank" rel="noopener">View tree</a>
        </div>
      </li>`;
  }).join("");
}

/* BiS */
function whLink(itemID, { bonusIDs, ilvl, enchantID, gemID } = {}, small = false) {
  const params = [];
  if (bonusIDs?.length) params.push(`bonus=${bonusIDs.join(":")}`);
  if (ilvl) params.push(`ilvl=${ilvl}`);
  if (enchantID) params.push(`ench=${enchantID}`);
  if (gemID) params.push(`gems=${gemID}`);
  return `<a href="https://www.wowhead.com/item=${itemID}" data-wowhead="${params.join("&amp;")}" ${small ? ` data-wh-icon-size="small"` : ""} target="_blank" rel="noopener">Item ${itemID}</a>`;
}

function renderBiS(detail) {
  const bis = detail?.bis ?? {};
  const updated = INDEX.meta?.updated ? new Date(INDEX.meta.updated + "T00:00:00Z") : new Date();
  const isNew = (d) => d && (updated - new Date(d + "T00:00:00Z")) / 86400000 <= NEW_TAG_DAYS;

  $("bisGrid").innerHTML = SLOTS.map(([slot, label]) => {
    const e = bis[slot];
    if (!e?.itemID) {
      return `<div class="slot"><div class="slot-label">${label}</div><div class="slot-item slot-empty">No clear pick</div></div>`;
    }
    const chips = [];
    if (e.ilvl) chips.push(`<span>ilvl ${e.ilvl}</span>`);
    if (e.enchantID) chips.push(`<span class="chip">Enchant ${e.enchantPct ?? "?"}%</span>`);
    if (e.gemID) chips.push(`<span class="chip">${whLink(e.gemID, {}, true)} ${Math.min(100, e.gemPct ?? 0)}%</span>`);
    const alt = e.altItemID
      ? `<div class="slot-alt">Also worn: ${whLink(e.altItemID, { bonusIDs: e.altBonusIDs, ilvl: e.altIlvl }, true)} · ${e.altPct}%</div>`
      : "";
    return `
      <div class="slot">
        <div class="slot-label">${label}${isNew(e.changedAt) ? `<span class="new-tag" title="Top pick changed ${esc(e.changedAt)}">NEW</span>` : ""}</div>
        <div class="slot-item">${whLink(e.itemID, e)}</div>
        <div class="ring" style="--p:${e.pct ?? 0}" title="${e.pct ?? 0}% of sampled top players"><span>${e.pct ?? 0}%</span></div>
        <div class="slot-meta">${chips.join("")}</div>
        ${alt}
      </div>`;
  }).join("");

  const wh = window.$WowheadPower ?? window.WH?.Tooltips;
  wh?.refreshLinks?.();
}

/* Main render */
let renderToken = 0;
async function update({ userPicked = true } = {}) {
  const byClass = specsByClass();
  renderSpecRow(byClass);
  const id = `${state.cls}_${state.spec}`;
  const spec = INDEX.specs[id];
  if (!spec.content[state.content]) state.content = spec.content.RAID ? "RAID" : "MYTHICPLUS";
  writeHash({ userPicked });

  document.documentElement.style.setProperty("--class", CLASSES[state.cls]?.color ?? "var(--gold)");
  $("bannerIcon").src = classIcon(state.cls);
  $("bannerTitle").textContent = `${specName(state.spec)} ${CLASSES[state.cls]?.name ?? titleCase(state.cls)}`;

  for (const b of $("contentToggle").querySelectorAll("button")) {
    b.setAttribute("aria-selected", b.dataset.content === state.content);
    b.disabled = !spec.content[b.dataset.content];
  }

  const info = spec.content[state.content];
  const bits = [`${CONTENT[state.content].name}`, `${info?.sample ?? 0} top players`];
  if (info?.difficulty) bits.push(`${titleCase(info.difficulty)} difficulty`);
  $("bannerSub").textContent = bits.join(" · ");

  const badge = $("sampleBadge");
  badge.textContent = `${info?.sample ?? 0} / ${INDEX.meta?.sampleSize ?? 20} players`;
  badge.classList.toggle("warn", (info?.sample ?? 0) < (INDEX.meta?.sampleSize ?? 20) || (info?.difficulty && info.difficulty !== "mythic"));

  renderStats(info);
  $("specPanel").hidden = false;

  const token = ++renderToken;
  try {
    const detail = (await loadDetail(id))[state.content];
    if (token !== renderToken) return;
    renderTalents(detail, info);
    renderBiS(detail);
  } catch (err) {
    if (token !== renderToken) return;
    $("bisGrid").innerHTML = `<p class="error">Couldn't load gear for this spec (${esc(err.message)}).</p>`;
  }
}

/* Small UI bits */
function toast(msg) {
  const t = $("toast");
  t.textContent = msg;
  t.classList.add("show");
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => t.classList.remove("show"), 2200);
}

document.addEventListener("click", async (e) => {
  const copy = e.target.closest("[data-copy]");
  if (copy) {
    try {
      await navigator.clipboard.writeText(copy.dataset.copy);
      toast("Loadout copied. In game: Talents › Import");
    } catch {
      toast("Couldn't copy, select the code and copy it manually");
    }
    return;
  }
  const shot = e.target.closest(".screen-grid img");
  if (shot) {
    const box = document.createElement("div");
    box.className = "lightbox";
    box.innerHTML = `<img src="${shot.src}" alt="${esc(shot.alt)}">`;
    box.onclick = () => box.remove();
    document.body.appendChild(box);
  }
});
document.addEventListener("keydown", (e) => { if (e.key === "Escape") document.querySelector(".lightbox")?.remove(); });

$("contentToggle").addEventListener("click", (e) => {
  const btn = e.target.closest("[data-content]");
  if (!btn || btn.disabled) return;
  state.content = btn.dataset.content;
  state.scope = "OVERALL";
  update();
});
window.addEventListener("hashchange", () => { if (readHash()) { renderClassGrid(); update(); } });

(async () => {
  try {
    INDEX = await loadJson("data/index.json");
  } catch (err) {
    $("loading").className = "error";
    $("loading").textContent = "Couldn't load the latest data. Try refreshing.";
    return;
  }
  $("loading").remove();
  renderHero();
  if (!readHash()) {
    const byClass = specsByClass();
    const first = Object.keys(byClass).sort((a, b) => (CLASSES[a]?.name ?? a).localeCompare(CLASSES[b]?.name ?? b))[0];
    state.cls = first;
    state.spec = byClass[first][0].spec;
  }
  renderClassGrid();
  await update({ userPicked: false });
  // The explorer sits above the other sections, so filling it in pushed the anchor the browser
  // already jumped to further down. Jump again now that the layout has settled.
  if (isSectionHash()) document.getElementById(location.hash.slice(1))?.scrollIntoView();
})();
