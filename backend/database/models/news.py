# ./backend/database/models/news.py
# 数据库 news 集合 CRUD 方法文件，供其他模块调用操作数据库

from bson import ObjectId  # 用于处理 MongoDB 的 ObjectId
from backend.database.connection import db_connection  # 从配置文件导入数据库连接配置
from pymongo import UpdateOne  # 用于批量操作中的单个更新操作

class NewsModel:
    def __init__(self):
        # 获取 MongoDB 中的 news 集合，用于存储新闻条目
        self.collection = db_connection.get_collection('news')

    def format_news_item(self, item):
        """
        格式化新闻条目，将数据库返回的文档转换为字典并处理 _id。
        参数:
            item (dict): 从数据库返回的新闻文档。
        返回:
            dict: 格式化后的新闻条目。
        """
        item['_id'] = str(item['_id'])  # 将 ObjectId 转换为字符串以便 JSON 序列化
        return item

    def create_news(self, news_data):
        """
        创建新的新闻条目。
        参数:
            news_data (dict): 包含新闻数据的字典。
        返回:
            str: 插入的新闻条目的 ID。
        """
        try:
            news_id = self.collection.insert_one(news_data).inserted_id
            return str(news_id)
        except Exception as e:
            print(f"Error creating news: {e}")
            return None

    def read_news(self, filter_criteria=None):
        """
        读取符合条件的新闻条目并返回格式化后的数据。
        参数:
            filter_criteria (dict, optional): 用于筛选新闻的条件，默认为 None 表示读取所有新闻。
        返回:
            list: 包含格式化新闻条目的列表。
        """
        try:
            news_list = list(self.collection.find(filter_criteria or {}))
            return [self.format_news_item(news) for news in news_list]
        except Exception as e:
            print(f"Error reading news: {e}")
            return []

    def update_news(self, news_id, update_data):
        """
        更新现有的新闻条目。
        参数:
            news_id (str): 要更新的新闻条目 ID。
            update_data (dict): 包含更新数据的字典。
        返回:
            int: 表示被修改的文档数量。
        """
        try:
            # 确保不会尝试更新 _id 字段
            update_data.pop('_id', None)

            result = self.collection.update_one({'_id': ObjectId(news_id)}, {'$set': update_data})
            if result.matched_count == 0:
                print(f"No news found with ID {news_id}.")
                return 0
            return result.modified_count
        except Exception as e:
            print(f"Error updating news with ID {news_id}: {e}")
            return 0


    def delete_news(self, news_id):
        """
        删除指定的新闻条目。
        参数:
            news_id (str): 要删除的新闻条目 ID。
        返回:
            int: 表示被删除的文档数量。
        """
        try:
            result = self.collection.delete_one({'_id': ObjectId(news_id)})
            return result.deleted_count
        except Exception as e:
            print(f"Error deleting news with ID {news_id}: {e}")
            return 0


    def bulk_create_or_update(self, entries):
        """
        批量插入或更新新闻条目，避免重复插入。
        使用新闻条目的 'link' 字段作为唯一标识。
        参数:
            entries (list): 包含多个新闻条目的列表，每个条目是一个字典。
        返回:
            dict: 包含插入和更新条目的统计信息。
        """
        operations = []
        inserted_count = 0
        updated_count = 0
        skipped_count = 0  # 新增：统计跳过的条目

        for entry in entries:
            try:
                # 检查数据库中是否存在相同 link 的条目
                existing_entry = self.collection.find_one({"link": entry["link"]})
                if existing_entry:
                    if existing_entry != entry:  # 如果内容不同，则需要更新
                        operations.append(UpdateOne({"_id": existing_entry["_id"]}, {"$set": entry}))
                        updated_count += 1
                    else:
                        skipped_count += 1
                else:
                    operations.append(UpdateOne({"link": entry["link"]}, {"$set": entry}, upsert=True))
                    inserted_count += 1
            except Exception as e:
                print(f"Error processing entry: {e}")

        if not operations:
            print("No operations to perform.")
            return {"inserted_count": inserted_count, "updated_count": updated_count, "skipped_count": skipped_count}

        try:
            self.collection.bulk_write(operations)
        except Exception as e:
            print(f"Error in bulk operation: {e}")

        return {"inserted_count": inserted_count, "updated_count": updated_count, "skipped_count": skipped_count}


# 实例化 NewsModel 供 API 和其他模块调用
news_model = NewsModel()