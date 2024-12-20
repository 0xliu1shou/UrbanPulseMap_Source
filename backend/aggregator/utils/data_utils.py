# ./backend/aggregator/utils/data_utils.py
# 爬虫工具文件，提供爬虫工作需要的获取、解析、封装、存储等模块化方法函数，供爬虫脚本调用

import feedparser
import time
import logging
from backend.database.models.news import news_model  # 导入 news_model 以支持数据库操作
from backend.database.models.log import log_model  # 导入 log_model 以支持日志记录

def fetch_rss_feed(url, retries=3, delay=5):
    """
    从指定的 RSS 源获取并返回原始 RSS 数据，支持重试机制。
    参数:
        url (str): RSS 源的 URL。
        retries (int): 重试次数。
        delay (int): 重试前的等待时间（秒）。
    返回:
        bytes: 获取的 RSS 数据（原始格式）。
    """
    for attempt in range(retries):
        try:
            logging.info(f"Fetching RSS feed from {url}, attempt {attempt + 1}")
            feed = feedparser.parse(url)
            if feed.bozo:
                raise Exception(f"Error parsing RSS feed: {feed.bozo_exception}")
            return feed
        except Exception as e:
            logging.error(f"Attempt {attempt + 1} failed to fetch RSS feed from {url}: {e}")
            if attempt < retries - 1:
                logging.info(f"Retrying in {delay} seconds...")
                time.sleep(delay)
    return None  # 在所有重试失败时返回 None

def parse_rss_feed(raw_feed):
    """
    解析原始 RSS 数据，将其转换为 FeedParserDict 格式。
    参数:
        raw_feed: 原始的 RSS 数据。
    返回:
        feedparser.FeedParserDict: 解析后的 RSS 数据。
    """
    if not raw_feed or not hasattr(raw_feed, "entries"):
        return None
    return raw_feed

def package_rss_feed(parsed_feed, source):
    """
    将解析后的 RSS 数据封装为标准化结构。
    参数:
        parsed_feed (feedparser.FeedParserDict): 解析后的 RSS 数据。
        source (str): 数据来源标识符。
    返回:
        list: 标准化后的新闻数据列表。
    """
    if not parsed_feed or not parsed_feed.entries:
        return []

    packaged_news = []
    for entry in parsed_feed.entries:
        news_item = {
            "title": entry.get("title", "No Title"),
            "link": entry.get("link", "No Link"),
            "publication_date": entry.get("published", "No Date"),
            "summary": entry.get("summary", entry.get("description", "No Summary")),  # 默认使用 description 作为 summary
            "source": source
        }
        packaged_news.append(news_item)
    return packaged_news

def store_news(news_data):
    """
    将标准化新闻数据存储到 news 集合。
    参数:
        news_data (list): 标准化后的新闻数据。
    返回:
        dict: 包含插入、更新、跳过的条目数量。
    """
    if not news_data:
        return {"inserted_count": 0, "updated_count": 0, "skipped_count": len(news_data)}

    try:
        results = news_model.bulk_create_or_update(news_data)
        inserted = results.get("inserted_count", 0)
        updated = results.get("updated_count", 0)
        skipped = len(news_data) - (inserted + updated)
        return {"inserted_count": inserted, "updated_count": updated, "skipped_count": skipped}
    except Exception as e:
        logging.error(f"Error storing news data: {e}")
        return {"inserted_count": 0, "updated_count": 0, "skipped_count": len(news_data)}

def store_logs(log_message, log_level="INFO", operation=None, batch_id=None):
    """
    将日志信息存储到 logs 集合。
    参数:
        log_message (str): 日志内容。
        log_level (str): 日志级别。
        operation (str): 操作类型。
        batch_id (str): 批次 ID。
    """
    try:
        log_model.add_log(log_level, log_message, operation, batch_id)
        logging.info(f"Log stored: {log_message}")
    except Exception as e:
        logging.error(f"Error storing log: {e}")

def process_rss_feed(url, source, batch_id=None):
    """
    完整处理 RSS 源数据的流程，包括获取、解析、封装和存储。
    参数:
        url (str): RSS 源的 URL。
        source (str): 数据来源标识符。
        batch_id (str): 批次 ID。
    """
    
    log_messages = []  # 用于记录每个步骤的日志信息
    
    # 获取 RSS 数据
    raw_feed = fetch_rss_feed(url)
    if raw_feed:
        log_messages.append("Successfully fetched RSS feed.")
    else:
        log_messages.append("Failed to fetch RSS feed.")
        store_logs(
            f"Process summary for {source} (Batch ID: {batch_id}): " + " | ".join(log_messages),
            "ERROR",
            "aggregator_process_summary",
            batch_id
        )
        return

    # 解析 RSS 数据
    parsed_feed = parse_rss_feed(raw_feed)
    if parsed_feed:
        log_messages.append("Successfully parsed RSS feed.")
    else:
        log_messages.append("No valid RSS feed data to parse.")
        store_logs(
            f"Process summary for {source} (Batch ID: {batch_id}): " + " | ".join(log_messages),
            "WARNING",
            "aggregator_process_summary",
            batch_id
        )
        return


    # 封装 RSS 数据
    packaged_data = package_rss_feed(parsed_feed, source)
    if packaged_data:
        log_messages.append(f"Successfully packaged {len(packaged_data)} news items.")
    else:
        log_messages.append("No entries to package.")
        store_logs(
            f"Process summary for {source} (Batch ID: {batch_id}): " + " | ".join(log_messages),
            "WARNING",
            "aggregator_process_summary",
            batch_id
        )
        return

    # 存储新闻数据
    store_results = store_news(packaged_data)
    log_messages.append(
        f"Bulk operation completed: {store_results['inserted_count']} inserted, "
        f"{store_results['updated_count']} updated, {store_results['skipped_count']} skipped."
    )
    
    # 写入最终总结日志
    store_logs(
        f"Process summary for {source} (Batch ID: {batch_id}): " + " | ".join(log_messages),
        "INFO",
        "aggregator_summary",
        batch_id
    )