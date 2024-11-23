import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
from bson import ObjectId
from datetime import datetime
from dateutil import parser as date_parser
import logging
from backend.database.models.news import news_model



def extract_time(doc, news_id):
    """
    提取时间信息。
    如果 NLP 未能从新闻内容中找到时间，则回退到数据库中的 publication_date。
    参数:
        doc (Doc): NLP 解析后的文档对象。
        news_id (str): 新闻条目在数据库中的 ID。
    返回:
        str: 格式化后的时间字符串。
    """
    extracted_time = None

    # Step 1: 尝试从 NLP 文档中提取时间实体
    try:
        for ent in doc.ents:
            if ent.label_ == "DATE":
                try:
                    extracted_time = date_parser.parse(ent.text, fuzzy=True)
                    logging.info(f"Extracted date from text: {ent.text} -> {extracted_time}")
                    break  # 找到第一个有效时间后退出
                except Exception as e:
                    logging.error(f"Error parsing date '{ent.text}': {e}")
    except Exception as e:
        logging.error(f"Error processing NLP document: {e}")

    # Step 2: 如果没有从 NLP 文档中提取到时间，回退到数据库中的 publication_date
    if not extracted_time:
        try:
            news_item = news_model.read_news({"_id": ObjectId(news_id)})
            logging.debug(f"Database query result: {news_item}")
            if news_item and len(news_item) > 0 and "publication_date" in news_item[0]:
                publication_date = news_item[0]["publication_date"]
                try:
                    # 尝试将 publication_date 转换为 datetime 对象
                    extracted_time = date_parser.parse(publication_date, fuzzy=True)
                    logging.info(f"Using publication_date from database as fallback: {extracted_time}")
                except Exception as e:
                    logging.error(f"Error parsing publication_date '{publication_date}': {e}")
            else:
                logging.warning(f"No publication_date found in database for news ID {news_id}")
        except Exception as e:
            logging.error(f"Error retrieving publication_date from database for news ID {news_id}: {e}")

    # Step 3: 如果数据库中也没有时间，使用当前时间作为最后的回退值
    if not extracted_time:
        extracted_time = datetime.now()
        logging.info(f"Using current datetime as fallback: {extracted_time}")

    # 返回格式化的时间
    return extracted_time.strftime('%Y-%m-%d %H:%M') if isinstance(extracted_time, datetime) else None


