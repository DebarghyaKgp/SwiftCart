"""
init_db.py — Create and seed the SwiftCart database.

Usage:
    python scripts/init_db.py           # create schema + seed data
    python scripts/init_db.py --schema  # schema only (no seed)
    python scripts/init_db.py --reset   # drop everything and start fresh
"""

import sqlite3
import sys
import os

DB_PATH = os.path.join(os.path.dirname(__file__), '..', 'database', 'swiftcart.db')
SCHEMA_PATH = os.path.join(os.path.dirname(__file__), '..', 'database', 'schema.sql')
SEED_PATH   = os.path.join(os.path.dirname(__file__), '..', 'database', 'seed.sql')


def get_connection(path: str) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.execute("PRAGMA foreign_keys = ON")
    conn.execute("PRAGMA journal_mode = WAL")   # better concurrent reads
    conn.row_factory = sqlite3.Row
    return conn


def run_sql_file(conn: sqlite3.Connection, path: str, label: str) -> None:
    print(f"  Running {label}...", end=" ")
    with open(path, 'r') as f:
        sql = f.read()
    try:
        conn.executescript(sql)
        print("done.")
    except sqlite3.Error as e:
        print(f"\n  ERROR: {e}")
        raise


def reset_db(conn: sqlite3.Connection) -> None:
    print("  Dropping all tables...")
    tables = [
        "purchase_order_items", "purchase_orders",
        "order_items", "orders",
        "inventory", "products",
        "suppliers", "users",
    ]
    for t in tables:
        conn.execute(f"DROP TABLE IF EXISTS {t}")
    conn.commit()
    print("  Done.\n")


def print_summary(conn: sqlite3.Connection) -> None:
    tables = ["users", "suppliers", "products", "inventory",
              "orders", "order_items", "purchase_orders", "purchase_order_items"]
    print("\n  Database summary:")
    for t in tables:
        count = conn.execute(f"SELECT COUNT(*) FROM {t}").fetchone()[0]
        print(f"    {t:<25} {count:>3} rows")

    print("\n  Low-stock alerts:")
    rows = conn.execute("""
        SELECT p.name, i.quantity_on_hand, i.reorder_point
        FROM   inventory i
        JOIN   products  p ON p.id = i.product_id
        WHERE  i.quantity_on_hand <= i.reorder_point
        ORDER  BY i.quantity_on_hand
    """).fetchall()
    for r in rows:
        print(f"    ⚠  {r['name']:<35} qty={r['quantity_on_hand']}  (reorder at {r['reorder_point']})")
    if not rows:
        print("    None — all stock levels are healthy.")


def main():
    args = sys.argv[1:]
    schema_only = "--schema" in args
    reset       = "--reset"  in args

    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)

    print(f"\nShopFlow DB initializer")
    print(f"  Target: {os.path.abspath(DB_PATH)}\n")

    conn = get_connection(DB_PATH)

    if reset:
        reset_db(conn)

    run_sql_file(conn, SCHEMA_PATH, "schema.sql")

    if not schema_only:
        try:
            run_sql_file(conn, SEED_PATH, "seed.sql")
        except sqlite3.IntegrityError:
            print("  Seed data already present — skipping (run with --reset to reload).")

    conn.commit()
    print_summary(conn)
    conn.close()
    print("\n  ✓ Database ready.\n")


if __name__ == "__main__":
    main()