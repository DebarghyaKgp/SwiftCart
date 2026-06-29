"""
backend/models/db.py — SQLite connection helper for SwiftCart.

Every route module imports `get_db` and `query` from here.
Flask's `g` object ensures one connection per request.
"""

import sqlite3
import os
from flask import g


DB_PATH = os.environ.get(
    "DATABASE_PATH",
    os.path.join(os.path.dirname(__file__), "..", "..", "database", "swiftcart.db")
)


def get_db() -> sqlite3.Connection:
    """Return the per-request DB connection, creating it if needed."""
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH, detect_types=sqlite3.PARSE_DECLTYPES)
        g.db.row_factory = sqlite3.Row          # rows act like dicts
        g.db.execute("PRAGMA foreign_keys = ON")
        g.db.execute("PRAGMA journal_mode = WAL")
    return g.db


def close_db(e=None) -> None:
    """Teardown: close connection at end of request."""
    db = g.pop("db", None)
    if db is not None:
        db.close()


def query(sql: str, params: tuple = (), one: bool = False):
    """
    Convenience wrapper for SELECT queries.

    Args:
        sql:    SQL string with ? placeholders.
        params: Tuple of values for placeholders.
        one:    If True, return a single Row (or None); else return list.

    Returns:
        sqlite3.Row or list[sqlite3.Row] or None.
    """
    cur = get_db().execute(sql, params)
    result = cur.fetchone() if one else cur.fetchall()
    return result


def mutate(sql: str, params: tuple = ()) -> int:
    """
    Convenience wrapper for INSERT / UPDATE / DELETE.

    Returns the lastrowid (useful for INSERTs).
    Caller is responsible for committing (or rolling back) the transaction.
    """
    db  = get_db()
    cur = db.execute(sql, params)
    return cur.lastrowid


def row_to_dict(row) -> dict:
    """Convert a sqlite3.Row to a plain dict (JSON-serialisable)."""
    return dict(row) if row else None


def rows_to_list(rows) -> list:
    """Convert a list of sqlite3.Row objects to a list of dicts."""
    return [dict(r) for r in rows]


def init_app(app):
    """Register the teardown handler with the Flask app."""
    app.teardown_appcontext(close_db)