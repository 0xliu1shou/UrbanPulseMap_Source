import sys
import os
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

from flask import Flask
from flask_cors import CORS
from routes.routes import api_bp, admin_bp
from backend.config import Config  # 使用集中配置
from backend.database.models.news import news_model  # 使用绝对路径导入

def create_app():
    app = Flask(__name__)
    CORS(app)
    app.config.from_object(Config)
    app.register_blueprint(api_bp, url_prefix='/api')
    app.register_blueprint(admin_bp, url_prefix='/api/admin')
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(debug=True)