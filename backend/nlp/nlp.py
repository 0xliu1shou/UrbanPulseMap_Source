# ./backend/nlp/nlp.py
# 主代码，提取数据库中的news合集，调用事件、地点、时间提取的结果并更新到数据库
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
from backend.nlp.utils.event import identify_event_type
from backend.nlp.utils.loc import extract_locations, get_coordinates
from backend.nlp.utils.time import extract_time  # 调用 time.py 中的 extract_time
import spacy
from backend.database.models.news import news_model
import logging

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

nlp = spacy.load("pt_core_news_lg")

def extract_event_info(title, summary, extracted_time):
    """
    提取事件信息，支持多地点处理
    """
    text = f"{title}. {summary}. "
    doc = nlp(text)
    event_info = {
        "event": identify_event_type(doc),
        "locations": [],  # 保存多个地点
        "coordinates": [],  # 保存多个地点的经纬度
        "time": extracted_time  # 使用 extract_time 的返回结果
    }
    
    # 提取多个地点
    locations = extract_locations(doc)
    if locations:
        event_info["locations"] = locations
        event_info["coordinates"] = get_coordinates(locations)

    logging.info(
        f"Processed News: Title='{title}', Summary='{summary[:80]}...', "
        f"Event='{event_info['event']}', "
        f"Locations={[(loc['location'], loc['latitude'], loc['longitude']) for loc in event_info['coordinates']]}, "
        f"Time='{event_info['time']}'"
    )
    return event_info

def process_news_events():
    """
    处理新闻事件
    """
    from concurrent.futures import ThreadPoolExecutor

    news_entries = news_model.read_news()
    logging.info(f"Found {len(news_entries)} news entries to process.")

    def process_single_news(news):
        title = news.get("title", "")
        summary = news.get("summary", "")
        news_id = news.get("_id")  # 从新闻条目中获取 _id

        # 调用 time.py 中的 extract_time 函数
        doc = nlp(f"{title}. {summary}.")  # NLP 文本内容
        extracted_time = extract_time(doc, news_id)  # 获取提取的时间

        # 调用 extract_event_info
        event_info = extract_event_info(title, summary, extracted_time)
        
        # 构造更新数据，仅保留 location（包含名称和经纬度）、event 和 time 字段
        update_data = {
            "geo": event_info["coordinates"],  # 用 coordinates 表示地理信息
            "event": event_info["event"],
            "time": event_info["time"]
        }
        # 更新新闻数据库条目
        news_model.update_news(news["_id"], update_data)

    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(process_single_news, news_entries)

if __name__ == "__main__":
    process_news_events()
