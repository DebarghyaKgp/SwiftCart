"""
app.py — SwiftCart Flask application entry point.

Run:
    python app.py
    # or
    flask --app app run --debug
"""

import os
from flask import Flask, jsonify
from dotenv import load_dotenv

load_dotenv()

from backend.models.db import init_app as init_db


def create_app() -> Flask:
    app = Flask(
        __name__,
        template_folder="frontend/templates",
        static_folder="frontend/static",
    )

    app.config["SECRET_KEY"] = os.environ.get("SECRET_KEY", "dev-secret-change-me")
    app.config["DATABASE_PATH"] = os.environ.get("DATABASE_PATH", "database/shopflow.db")

    # ── Register DB teardown ──────────────────────────────────────────
    init_db(app)

    # ── Register blueprints (uncomment as you build each phase) ──────
    # from backend.routes.products  import bp as products_bp
    # from backend.routes.orders    import bp as orders_bp
    # from backend.routes.admin     import bp as admin_bp
    # from backend.routes.suppliers import bp as suppliers_bp
    # app.register_blueprint(products_bp,  url_prefix="/api/products")
    # app.register_blueprint(orders_bp,    url_prefix="/api/orders")
    # app.register_blueprint(admin_bp,     url_prefix="/api/admin")
    # app.register_blueprint(suppliers_bp, url_prefix="/api/suppliers")

    # ── Health check ─────────────────────────────────────────────────
    @app.get("/api/health")
    def health():
        return jsonify({"status": "ok", "version": "1.0.0"})

    # ── Root → serve storefront (Phase 2+) ───────────────────────────
    @app.get("/")
    def index():
        return jsonify({"message": "ShopFlow API running. Frontend coming in Phase 2."})

    return app


app = create_app()

if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "1") == "1"
    app.run(debug=debug, port=5000)