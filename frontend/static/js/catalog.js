/* SwiftCart — catalog.js */

const grid       = document.getElementById("product-grid");
const searchBox  = document.getElementById("search");
const catSelect  = document.getElementById("category-filter");
const sortSelect = document.getElementById("sort");
const countLabel = document.getElementById("count-label");
const alertBanner = document.getElementById("low-stock-banner");
const alertText   = document.getElementById("low-stock-text");

const CATEGORY_ICONS = {
  Electronics: "💻",
  Clothing:    "👕",
  Home:        "🏠",
  Office:      "🖊️",
};

let debounceTimer;

// ── Boot ─────────────────────────────────────────────────────
async function init() {
  await Promise.all([loadCategories(), loadProducts(), checkLowStock()]);
}

// ── Categories ───────────────────────────────────────────────
async function loadCategories() {
  try {
    const res  = await fetch("/api/products/categories");
    const data = await res.json();
    data.categories.forEach(({ category, product_count }) => {
      const opt = document.createElement("option");
      opt.value       = category;
      opt.textContent = `${category} (${product_count})`;
      catSelect.appendChild(opt);
    });
  } catch (e) {
    console.error("Failed to load categories", e);
  }
}

// ── Low-stock alert ──────────────────────────────────────────
async function checkLowStock() {
  try {
    const res  = await fetch("/api/products/low-stock");
    const data = await res.json();
    if (data.count > 0) {
      const names = data.low_stock_items.slice(0, 3).map(i => i.name).join(", ");
      const extra = data.count > 3 ? ` +${data.count - 3} more` : "";
      alertText.textContent = `${data.count} item(s) need restocking: ${names}${extra}`;
      alertBanner.classList.remove("hidden");
    }
  } catch (e) {
    console.error("Failed to load low-stock", e);
  }
}

// ── Products ─────────────────────────────────────────────────
async function loadProducts() {
  showSkeletons();

  const params = new URLSearchParams();
  const q      = searchBox.value.trim();
  const cat    = catSelect.value;
  const sort   = sortSelect.value;

  if (q)   params.set("q",        q);
  if (cat) params.set("category", cat);
  if (sort)params.set("sort",     sort);

  try {
    const res  = await fetch(`/api/products?${params}`);
    const data = await res.json();
    renderProducts(data.products);
    countLabel.textContent = `${data.count} product${data.count !== 1 ? "s" : ""}`;
  } catch (e) {
    grid.innerHTML = `<div class="empty-state"><h3>Could not load products</h3><p>${e.message}</p></div>`;
  }
}

// ── Render ───────────────────────────────────────────────────
function renderProducts(products) {
  if (!products.length) {
    grid.innerHTML = `<div class="empty-state"><h3>No products found</h3><p>Try a different search or filter.</p></div>`;
    return;
  }

  grid.innerHTML = products.map(p => {
    const icon        = CATEGORY_ICONS[p.category] || "📦";
    const badgeClass  = { in_stock: "badge-in", low_stock: "badge-low", out_of_stock: "badge-out" }[p.stock_status];
    const badgeLabel  = { in_stock: "In stock", low_stock: "Low stock", out_of_stock: "Out of stock" }[p.stock_status];
    const isOut       = p.stock_status === "out_of_stock";

    return `
      <div class="card">
        <div class="card-img">${icon}</div>
        <span class="card-category">${p.category}</span>
        <p class="card-name">${escHtml(p.name)}</p>
        <p class="card-sku">SKU: ${escHtml(p.sku)}</p>
        <p class="card-price">$${Number(p.price).toFixed(2)}</p>
        <div class="card-footer">
          <span class="badge ${badgeClass}">${badgeLabel} (${p.quantity_on_hand})</span>
          <button class="btn-cart" ${isOut ? "disabled" : ""} onclick="addToCart(${p.id}, '${escHtml(p.name)}')">
            ${isOut ? "Unavailable" : "Add to cart"}
          </button>
        </div>
      </div>`;
  }).join("");
}

// ── Skeleton loaders ─────────────────────────────────────────
function showSkeletons() {
  grid.innerHTML = Array(8).fill(`
    <div class="skeleton-card">
      <div class="skeleton" style="height:120px"></div>
      <div class="skeleton" style="height:12px;width:50%"></div>
      <div class="skeleton" style="height:16px;width:80%"></div>
      <div class="skeleton" style="height:12px;width:40%"></div>
      <div class="skeleton" style="height:18px;width:35%;margin-top:auto"></div>
    </div>`).join("");
}

// ── Cart (stub — wired up in Phase 3) ────────────────────────
function addToCart(productId, name) {
  const btn = event.target;
  btn.textContent = "Added!";
  btn.style.background = "#16a34a";
  setTimeout(() => {
    btn.textContent = "Add to cart";
    btn.style.background = "";
  }, 1200);
  console.log(`Cart: added product ${productId} — ${name}`);
}

// ── Utils ─────────────────────────────────────────────────────
function escHtml(str) {
  return String(str).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;").replace(/"/g,"&quot;");
}

// ── Event listeners ──────────────────────────────────────────
searchBox.addEventListener("input", () => {
  clearTimeout(debounceTimer);
  debounceTimer = setTimeout(loadProducts, 300);
});
catSelect.addEventListener("change",  loadProducts);
sortSelect.addEventListener("change", loadProducts);

init();