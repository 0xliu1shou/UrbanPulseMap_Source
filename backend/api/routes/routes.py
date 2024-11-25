# ./backend/api/routes/routes.py
# Flask API 的路由文件

from flask import Blueprint, jsonify, request
from collections import OrderedDict
from backend.database.models.news import news_model
from backend.database.models.log import log_model

api_bp = Blueprint('api', __name__)
admin_bp = Blueprint('admin', __name__)

def format_news_item(item):
    """
    格式化新闻条目，将数据库返回的文档转为 OrderedDict 并控制字段顺序。
    """
    return OrderedDict([
        ("_id", item["_id"]),
        ("event", item.get("event", "")),
        ("location", item.get("location", "")),
        ("time", item.get("time", "")),
        ("title", item.get("title", "")),
        ("summary", item.get("summary", "")),
        ("publication_date", item.get("publication_date", "")),
        ("link", item.get("link", "")),
        ("source", item.get("source", "Unknown"))
    ])

# 公用api
@api_bp.route('/news', methods=['GET'])
def get_news():
    """
    获取数据库中的新闻条目列表。可以使用 `formatted` 查询参数控制返回格式。
    """
    formatted = request.args.get('formatted', 'false').lower() == 'true'
    news_list = news_model.read_news()
    
    # 如果需要格式化输出，使用 format_news_item；否则直接返回原始数据
    if formatted:
        formatted_news = [format_news_item(item) for item in news_list]
        return jsonify(formatted_news)
    return jsonify(news_list), 200


# admin api
@admin_bp.route('/news', methods=['GET', 'POST'])
def get_all_or_create_news():
    """
    GET: 获取所有新闻条目，供管理页面使用。
    POST: 接收新新闻条目数据，并在数据库中创建新记录。
    """
    if request.method == 'GET':
        news_list = news_model.read_news()
        return jsonify(news_list), 200
    elif request.method == 'POST':
        data = request.json
        news_id = news_model.create_news(data)
        return jsonify({"message": "News created", "id": str(news_id)}), 201

@admin_bp.route('/news/<news_id>', methods=['PUT'])
def update_news(news_id):
    """
    根据提供的新闻条目 ID 更新数据库中的新闻数据。
    """
    data = request.json
    modified_count = news_model.update_news(news_id, data)
    if modified_count == 1:
        return jsonify({"message": "News updated"}), 200
    else:
        return jsonify({"message": "News not found"}), 404

@admin_bp.route('/news/<news_id>', methods=['DELETE'])
def delete_news(news_id):
    """
    根据提供的新闻条目 ID 删除数据库中的记录。
    """
    deleted_count = news_model.delete_news(news_id)
    if deleted_count == 1:
        return jsonify({"message": "News deleted"}), 200
    else:
        return jsonify({"message": "News not found"}), 404

@admin_bp.route('/logs', methods=['GET'])
def get_logs():
    """
    从数据库中获取日志条目并返回给前端。可选择设置数量限制、日志级别过滤、操作类型过滤、以及批次过滤。
    """
    level = request.args.get('level')  # 获取日志级别参数
    operation = request.args.get('operation')  # 获取操作类型参数
    limit = int(request.args.get('limit', 100))  # 获取日志数量限制，默认为 100
    start_date = request.args.get('start_date')  # 获取起始日期参数
    end_date = request.args.get('end_date')  # 获取结束日期参数
    batch_id = request.args.get('batch_id')  # 获取批次 ID 参数

    # 调用 LogModel 的 get_logs 方法，传递过滤条件
    logs = log_model.get_logs(limit=limit, level=level, operation=operation, start_date=start_date, end_date=end_date, batch_id=batch_id)
    
    # 格式化日志输出
    formatted_logs = [
        OrderedDict([
            ("timestamp", log.get("timestamp")),
            ("level", log.get("level")),
            ("message", log.get("message")),
            ("operation", log.get("operation", "N/A")),  # 显示操作类型，如果没有则显示 "N/A"
            ("batch_id", log.get("batch_id", "N/A"))  # 显示批次ID，如果没有则显示 "N/A"
        ]) for log in logs
    ]
    return jsonify(formatted_logs), 200