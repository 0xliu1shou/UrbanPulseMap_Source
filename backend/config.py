# backend/config.py
# 集中管理后端全部配置
import os

class Config:
    DEBUG = True
    MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017/")
    DATABASE_NAME = "urban_pulse_map"
