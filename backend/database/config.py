# database/config.py
# MongoDB 连接配置
from pymongo import MongoClient
from backend.config import Config  # 从集中配置文件导入MongoDB URI

class DatabaseConnection:
    def __init__(self):
        self.client = MongoClient(Config.MONGO_URI)
        self.db = self.client[Config.DATABASE_NAME]

    def get_collection(self, collection_name):
        return self.db[collection_name]

    def close_connection(self):
        self.client.close()

db_connection = DatabaseConnection()
