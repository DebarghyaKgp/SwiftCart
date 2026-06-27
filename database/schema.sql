-- SwiftCart Database Schema
-- Run: python scripts/init_db.py

PRAGMA foreign_keys = ON;

-- ─────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    email       TEXT    NOT NULL UNIQUE,
    password    TEXT    NOT NULL,          -- hashed
    full_name   TEXT    NOT NULL,
    role        TEXT    NOT NULL DEFAULT 'customer' CHECK(role IN ('customer','admin')),
    created_at  TEXT    NOT NULL DEFAULT (datetime('now')),
    is_active   INTEGER NOT NULL DEFAULT 1
);

-- ─────────────────────────────────────────
-- SUPPLIERS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS suppliers (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    name          TEXT    NOT NULL,
    contact_name  TEXT,
    email         TEXT,
    phone         TEXT,
    address       TEXT,
    lead_time_days INTEGER NOT NULL DEFAULT 7,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    is_active     INTEGER NOT NULL DEFAULT 1
);

-- ─────────────────────────────────────────
-- PRODUCTS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS products (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    sku           TEXT    NOT NULL UNIQUE,
    name          TEXT    NOT NULL,
    description   TEXT,
    category      TEXT    NOT NULL,
    price         REAL    NOT NULL CHECK(price >= 0),
    cost_price    REAL    NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
    supplier_id   INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
    image_url     TEXT,
    is_active     INTEGER NOT NULL DEFAULT 1,
    created_at    TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at    TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────
-- INVENTORY
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS inventory (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    product_id          INTEGER NOT NULL UNIQUE REFERENCES products(id) ON DELETE CASCADE,
    quantity_on_hand    INTEGER NOT NULL DEFAULT 0 CHECK(quantity_on_hand >= 0),
    quantity_reserved   INTEGER NOT NULL DEFAULT 0 CHECK(quantity_reserved >= 0),
    reorder_point       INTEGER NOT NULL DEFAULT 10,
    reorder_quantity    INTEGER NOT NULL DEFAULT 50,
    last_restocked_at   TEXT,
    updated_at          TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────
-- ORDERS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS orders (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id         INTEGER REFERENCES users(id) ON DELETE SET NULL,
    status          TEXT    NOT NULL DEFAULT 'pending'
                    CHECK(status IN ('pending','confirmed','processing','shipped','delivered','cancelled','refunded')),
    total_amount    REAL    NOT NULL DEFAULT 0,
    shipping_name   TEXT    NOT NULL,
    shipping_address TEXT   NOT NULL,
    shipping_city   TEXT    NOT NULL,
    shipping_zip    TEXT    NOT NULL,
    notes           TEXT,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────
-- ORDER ITEMS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS order_items (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id    INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id  INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity    INTEGER NOT NULL CHECK(quantity > 0),
    unit_price  REAL    NOT NULL CHECK(unit_price >= 0),
    subtotal    REAL    GENERATED ALWAYS AS (quantity * unit_price) STORED
);

-- ─────────────────────────────────────────
-- PURCHASE ORDERS (supplier restocking)
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_orders (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    supplier_id     INTEGER NOT NULL REFERENCES suppliers(id) ON DELETE RESTRICT,
    status          TEXT    NOT NULL DEFAULT 'draft'
                    CHECK(status IN ('draft','sent','confirmed','received','cancelled')),
    total_cost      REAL    NOT NULL DEFAULT 0,
    expected_date   TEXT,
    received_date   TEXT,
    notes           TEXT,
    created_at      TEXT    NOT NULL DEFAULT (datetime('now')),
    updated_at      TEXT    NOT NULL DEFAULT (datetime('now'))
);

-- ─────────────────────────────────────────
-- PURCHASE ORDER ITEMS
-- ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS purchase_order_items (
    id                  INTEGER PRIMARY KEY AUTOINCREMENT,
    purchase_order_id   INTEGER NOT NULL REFERENCES purchase_orders(id) ON DELETE CASCADE,
    product_id          INTEGER NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity_ordered    INTEGER NOT NULL CHECK(quantity_ordered > 0),
    quantity_received   INTEGER NOT NULL DEFAULT 0,
    unit_cost           REAL    NOT NULL CHECK(unit_cost >= 0)
);

-- ─────────────────────────────────────────
-- INDEXES
-- ─────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_products_category   ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_supplier   ON products(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_user         ON orders(user_id);
CREATE INDEX IF NOT EXISTS idx_orders_status       ON orders(status);
CREATE INDEX IF NOT EXISTS idx_order_items_order   ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_po_supplier         ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_inventory_product   ON inventory(product_id);