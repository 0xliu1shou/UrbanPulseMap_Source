# ./backend/database/models/log.py
# 数据库 logs 集合 CRUD 方法文件，供其他模块调用操作数据库

from datetime import datetime
from backend.database.connection import db_connection  # 导入数据库连接配置


class LogModel:
    def __init__(self):
        # 获取 MongoDB 中的 logs 集合，用于存储日志条目
        self.collection = db_connection.get_collection('logs')

    def add_log(self, level, message, operation=None, batch_id=None):
        """
        将日志条目添加到数据库的 logs 集合。
        参数:
            level (str): 日志级别 (例如: INFO, ERROR)。
            message (str): 日志内容。
            operation (str, optional): 操作类型，例如 "fetch_data", "update_data" 等。
                                       如果未提供，默认为 'unknown'。
            batch_id (str, optional): 批次标识符，默认为 None。
                                      如果未提供，默认为 'untracked'。
        """
        # 确保 operation 和 batch_id 有默认值
        log_entry = {
            "level": level,
            "message": message,
            "timestamp": datetime.now(),  # 当前时间戳
            "operation": operation if operation else "unknown",  # 默认为 'unknown'
            "batch_id": batch_id if batch_id else "untracked"    # 默认为 'untracked'
        }

        # 插入日志记录到 logs 集合
        try:
            self.collection.insert_one(log_entry)
        except Exception as e:
            # 如果日志存储失败，在控制台输出错误日志
            print(f"Failed to store log: {e}")

    def get_logs(self, limit=100, level=None, operation=None, start_date=None, end_date=None, batch_id=None):
        """
        获取最近的日志条目，按时间戳降序排序并限制返回数量。
        参数:
            limit (int): 返回的最大日志条目数。默认为 100。
            level (str, optional): 日志级别过滤条件，默认为 None。
            operation (str, optional): 操作类型过滤条件，默认为 None。
            start_date (datetime, optional): 起始时间，默认为 None。
            end_date (datetime, optional): 结束时间，默认为 None。
            batch_id (str, optional): 批次ID过滤条件，默认为 None。
        返回:
            list: 包含日志条目的列表。
        """
        query = {}

        # 根据日志级别进行筛选
        if level:
            query["level"] = level

        # 根据操作类型进行筛选
        if operation:
            query["operation"] = operation

        # 根据时间范围进行筛选
        if start_date:
            query["timestamp"] = {"$gte": start_date}
        if end_date:
            query["timestamp"].update({"$lte": end_date}) if "timestamp" in query else query.update(
                {"timestamp": {"$lte": end_date}}
            )

        # 根据批次ID进行筛选
        if batch_id:
            query["batch_id"] = batch_id

        # 查询数据库并按 timestamp 字段降序排序，限制返回的条目数
        try:
            return list(self.collection.find(query).sort("timestamp", -1).limit(limit))
        except Exception as e:
            print(f"Failed to retrieve logs: {e}")
            return []

# 实例化 LogModel 供其他模块调用
log_model = LogModel()