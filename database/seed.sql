-- SwiftCart Seed Data
-- Realistic sample data for development and testing

PRAGMA foreign_keys = ON;

-- ─── USERS ───────────────────────────────
-- Passwords are bcrypt hashes of 'password123'
INSERT INTO users (email, password, full_name, role) VALUES
('admin@shopflow.com',    '$2b$12$placeholder_hash_admin',    'Admin User',       'admin'),
('alice@example.com',     '$2b$12$placeholder_hash_alice',    'Alice Mensah',     'customer'),
('bob@example.com',       '$2b$12$placeholder_hash_bob',      'Bob Krishnamurthy','customer'),
('carol@example.com',     '$2b$12$placeholder_hash_carol',    'Carol Osei',       'customer');

-- ─── SUPPLIERS ───────────────────────────
INSERT INTO suppliers (name, contact_name, email, phone, address, lead_time_days) VALUES
('TechParts Ltd',       'James Owusu',      'james@techparts.com',   '+233-55-001-0001', '14 Industrial Ave, Accra, Ghana',        7),
('GlobalGoods Co.',     'Priya Sharma',     'priya@globalgoods.io',  '+91-98-200-0002',  '22 Export Zone, Mumbai, India',           14),
('QuickStock Supplies', 'Emily Larsson',    'emily@quickstock.se',   '+46-70-300-0003',  '5 Lagerhuset, Stockholm, Sweden',         5),
('EcoSource Africa',    'Kwame Asante',     'kwame@ecosource.gh',    '+233-24-400-0004', '3 Green Road, Kumasi, Ghana',             10);

-- ─── PRODUCTS ────────────────────────────
INSERT INTO products (sku, name, description, category, price, cost_price, supplier_id) VALUES
-- Electronics
('ELEC-001', 'Wireless Bluetooth Headphones', 'Over-ear noise-cancelling headphones, 30h battery', 'Electronics', 89.99,  42.00, 1),
('ELEC-002', 'USB-C Fast Charger 65W',        '65W GaN charger with 3 ports, foldable plug',       'Electronics', 34.99,  14.00, 1),
('ELEC-003', 'Mechanical Keyboard TKL',        'Tenkeyless RGB mechanical keyboard, blue switches', 'Electronics', 74.99,  31.00, 1),
('ELEC-004', 'Portable Power Bank 20000mAh',   'PD 22.5W fast charge, dual output',                'Electronics', 49.99,  19.00, 1),
-- Clothing
('CLTH-001', 'Classic Cotton T-Shirt',         '100% organic cotton, unisex, sizes S–2XL',         'Clothing',    19.99,   6.50, 3),
('CLTH-002', 'Slim Fit Chino Pants',           'Stretch chino, 5-pocket, machine washable',        'Clothing',    44.99,  15.00, 3),
('CLTH-003', 'Waterproof Rain Jacket',         'Lightweight packable rain jacket, DWR coated',     'Clothing',    69.99,  28.00, 3),
-- Home & Kitchen
('HOME-001', 'Bamboo Cutting Board Set',       'Set of 3 bamboo boards, juice groove',             'Home',        29.99,   9.00, 4),
('HOME-002', 'Stainless Steel Water Bottle',   '1L vacuum insulated, 24h cold / 12h hot',         'Home',        24.99,   8.50, 4),
('HOME-003', 'Ceramic Pour-Over Coffee Set',   'Dripper, carafe, and filters kit',                 'Home',        54.99,  20.00, 4),
-- Office
('OFFC-001', 'Ergonomic Lumbar Cushion',       'Memory foam back support, adjustable strap',       'Office',      39.99,  14.00, 2),
('OFFC-002', 'Desk Organiser 6-Slot',          'Bamboo desktop organiser with phone stand',        'Office',      22.99,   7.50, 4),
('OFFC-003', 'Laptop Stand Aluminium',         'Adjustable angle, fits 10–17 inch laptops',       'Office',      44.99,  17.00, 2);

-- ─── INVENTORY ───────────────────────────
-- (product_id, qty_on_hand, qty_reserved, reorder_point, reorder_qty)
INSERT INTO inventory (product_id, quantity_on_hand, quantity_reserved, reorder_point, reorder_quantity) VALUES
(1,  120,  5, 20, 100),   -- Headphones
(2,  200, 10, 30, 150),   -- Charger
(3,   45,  3, 15,  75),   -- Keyboard
(4,   8,   2, 20, 100),   -- Power Bank   ← below reorder_point!
(5,  350, 20, 50, 200),   -- T-Shirt
(6,   60,  5, 25,  80),   -- Chino Pants
(7,   7,   1, 15,  60),   -- Rain Jacket  ← below reorder_point!
(8,  180,  0, 30, 120),   -- Cutting Board
(9,  210,  8, 40, 150),   -- Water Bottle
(10,  22,  2, 10,  50),   -- Coffee Set
(11,  55,  3, 15,  60),   -- Lumbar Cushion
(12,  95,  0, 20,  80),   -- Desk Organiser
(13,  6,   1, 10,  40);   -- Laptop Stand  ← below reorder_point!

-- ─── ORDERS ──────────────────────────────
INSERT INTO orders (user_id, status, total_amount, shipping_name, shipping_address, shipping_city, shipping_zip) VALUES
(2, 'delivered',  124.98, 'Alice Mensah',      '12 Accra Road',    'Accra',   'GA-123'),
(3, 'shipped',     89.99, 'Bob Krishnamurthy', '7 Marine Drive',   'Mumbai',  '400001'),
(2, 'processing',  54.99, 'Alice Mensah',      '12 Accra Road',    'Accra',   'GA-123'),
(4, 'confirmed',  114.98, 'Carol Osei',        '3 Independence St','Kumasi',  'AH-045'),
(3, 'pending',     44.99, 'Bob Krishnamurthy', '7 Marine Drive',   'Mumbai',  '400001');

-- ─── ORDER ITEMS ─────────────────────────
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
-- Order 1: Alice — headphones + charger
(1, 1, 1, 89.99),
(1, 2, 1, 34.99),
-- Order 2: Bob — headphones
(2, 1, 1, 89.99),
-- Order 3: Alice — coffee set
(3, 10, 1, 54.99),
-- Order 4: Carol — keyboard + charger
(4, 3, 1, 74.99),
(4, 2, 1, 34.99),  -- wait, 74.99+34.99=109.98, but order says 114.98 (chino pants too)
(4, 6, 1, 44.99),
-- Order 5: Bob — chino pants
(5, 6, 1, 44.99);

-- Fix order 4 total (3 items)
UPDATE orders SET total_amount = 154.97 WHERE id = 4;

-- ─── PURCHASE ORDERS ─────────────────────
INSERT INTO purchase_orders (supplier_id, status, total_cost, expected_date, notes) VALUES
(1, 'sent',      1900.00, date('now', '+7 days'),  'Urgent restock for power banks and laptop stands'),
(3, 'confirmed',  960.00, date('now', '+5 days'),  'Rain jacket restock before rainy season');

-- ─── PURCHASE ORDER ITEMS ────────────────
INSERT INTO purchase_order_items (purchase_order_id, product_id, quantity_ordered, unit_cost) VALUES
-- PO 1: TechParts — power banks + laptop stands
(1, 4,  100, 19.00),
(1, 13,  40, 17.00),
-- PO 2: QuickStock — rain jackets
(2, 7,   60, 28.00);