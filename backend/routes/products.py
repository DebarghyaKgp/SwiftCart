"""
backend/routes/products.py — SwiftCart product catalog & inventory API.
 
Endpoints:
    GET  /api/products                 list products (search, filter, sort)
    GET  /api/products/<id>            single product with inventory
    GET  /api/products/categories      distinct category list
    PATCH /api/products/<id>/stock     adjust stock quantity
    GET  /api/inventory/low-stock      products at or below reorder point
"""

from flask import Blueprint, jsonify, request
from backend.models.db import query, mutate, rows_to_list, row_to_dict, get_db
bp = Blueprint("products", __name__)


# ─────────────────────────────────────────────────────────────
# GET /api/products
# Query params: q, category, sort, in_stock
# ─────────────────────────────────────────────────────────────
@bp.get('/')
def list_products():
    q = request.args.get('q', '').strip()
    category = request.args.get('category', '').strip()
    sort = request.args.get('sort', 'name')         # name | rice_asc | price_desc | stock
    in_stock = request.args.get('in_stock', '')     # '1' = only show items with stock > 0
    allowed_sorts = {
        "name" : "p.name ASC",
        'price_asc' : 'p.price ASC',
        'price_desc' : 'p.price DESC',
        'stock' : 'i.quantity_on_hand DESC'
    }

    order_clause = allowed_sorts.get(sort, 'p.name ASC')

    sql = (
        "SELECT p.id, p.sku, p.name, p.description, p.category,"
        " p.price, p.cost_price, p.image_url, p.is_active,"
        " s.name AS supplier_name,"
        " i.quantity_on_hand, i.quantity_reserved, i.reorder_point,"
        " (i.quantity_on_hand - i.quantity_reserved) AS available_stock,"
        " CASE"
        " WHEN i.quantity_on_hand = 0 THEN 'out_of_stock'"
        " WHEN i.quantity_on_hand <= i.reorder_point THEN 'low_stock'"
        " ELSE 'in_stock'"
        " END AS stock_status"
        " FROM products p"
        " LEFT JOIN inventory i ON i.product_id = p.id"
        " LEFT JOIN suppliers s ON s.id = p.supplier_id"
        " WHERE p.is_active = 1"
    )
    params = []

    if q:
        sql += ' AND (p.name LIKE ? OR p.sku LIKE ? OR p.description LIKE ?)'
        like = f'%{q}%'
        params += [like, like, like]

    if category:
        sql += ' AND p.category = ?'
        params.append(category)
    
    if in_stock == '1':
        sql += ' AND i.quantity_on_hand > 0'
    
    sql += f' ORDER BY {order_clause}'
    rows = query(sql, tuple(params))
    return jsonify({'products': rows_to_list(rows), 'count': len(rows)})


# ─────────────────────────────────────────────────────────────
# GET /api/products/categories
# ─────────────────────────────────────────────────────────────
@bp.get('/categories')
def list_categories():
    rows = query((
            "SELECT DISTINCT category, COUNT(*) as product_count"
            " FROM products"
            " WHERE is_active = 1"
            " GROUP BY category"
            " ORDER BY category"
            ))
    return jsonify({'categories': rows_to_list(rows)})


# ─────────────────────────────────────────────────────────────
# GET /api/products/<id>
# ─────────────────────────────────────────────────────────────
@bp.get('/<int:product_id>')
def get_product(product_id):
    row = query((
        "SELECT "
            "p.*,"
            "s.name AS supplier_name,"
            "s.email AS supplier_email,"
            "s.lead_time_days,"
            "i.quantity_on_hand,"
            "i.quantity_reserved,"
            "i.reorder_point,"
            "i.reorder_quantity,"
            "i.last_restocked_at,"
            "(i.quantity_on_hand - i.quantity_reserved) AS available_stock,"
            " CASE"
                " WHEN i.quantity_on_hand = 0 THEN 'out_of_stock'"
                " WHEN i.quantity_on_hand <= i.reorder_point THEN 'low_stock'"
                " ELSE 'in_stock'"
            " END AS stock_status"
        " FROM products p"
        " LEFT JOIN inventory i ON i.product_id = p.id"
        " LEFT JOIN suppliers s ON s.id = p.supplier_id"
        " WHERE p.id = ? and p.is_active = 1"
    ), (product_id,), one = True)

    if not row:
        return jsonify({"error": "product not found"}), 404
    
    return jsonify({'product': row_to_dict(row)})


# ─────────────────────────────────────────────────────────────
# PATCH /api/products/<id>/stock
# Body: { "adjustment": <int>, "reason": <str> }
# Positive = restock, negative = manual reduction
# ─────────────────────────────────────────────────────────────
@bp.patch('/<int:product_id>/stock')
def adjust_stock(product_id):
    data = request.get_json(force = True) or {}
    adjustment = data.get('adjustment')
    reason = data.get('reason', 'manual adjustment')
    if adjustment is None or not isinstance(adjustment, int):
        return jsonify({'error': "'adjustment' must be an integer"}), 400
    
    inv = query(
        'SELECT quantity_on_hand FROM inventory WHERE product_id = ?', (product_id,), one = True
    )
    if not inv:
        return jsonify({'error': 'inventory record not found'}),404
    
    new_qty = inv['quantity_on_hand'] + adjustment
    if new_qty < 0:
        return jsonify({'error': f'Adjustment would result in negative stock ({new_qty})'}), 400
    
    db = get_db()
    db.execute((
            "UPDATE inventory"
            " SET quantity_on_hand = ?,"
                "updated_at = datetime('now')"
            " WHERE product_id = ?"
    ), (new_qty, product_id))
    db.commit()

    return jsonify({
        'product_id': product_id,
        'old_quantity': inv['quantity_on_hand'],
        'adjustment': adjustment,
        'new_quantity': new_qty,
        'reason': reason
        })


# ─────────────────────────────────────────────────────────────
# GET /api/inventory/low-stock
# ─────────────────────────────────────────────────────────────
@bp.get("/low-stock")
def low_stock():
    rows = query((
        "SELECT "
            "p.id, p.sku, p.name, p.category,"
            "i.quantity_on_hand,"
            "i.reorder_point,"
            "i.reorder_quantity,"
            "s.name AS supplier_name,"
            "s.lead_time_days"
        " FROM inventory i "
        " JOIN products p on p.id = i.product_id "
        " LEFT JOIN suppliers s on s.id = p.supplier_id "
        " WHERE i.quantity_on_hand <= i.reorder_point "
            " AND p.is_active= 1"
        " ORDER BY i.quantity_on_hand ASC"
    ))

    return jsonify({'low_stock_items': rows_to_list(rows), 'count': len(rows)})




