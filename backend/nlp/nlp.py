# ./backend/nlp/nlp.py
# 主代码，提取数据库中的news合集，调用事件、地点、时间提取的结果并更新到数据库
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'  # 只显示 ERROR 级别的日志
from transformers import logging
logging.set_verbosity_error()  # 设置日志级别为 ERROR，仅显示错误
import warnings
warnings.filterwarnings("ignore", message="Some weights of .* were not initialized")
from datetime import datetime
from backend.nlp.utils.event import identify_event_type
from backend.nlp.utils.loc import extract_locations, get_coordinates
from backend.nlp.utils.time import extract_time  # 调用 time.py 中的 extract_time
from backend.database.models.log import log_model
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

    logging.debug(  # 改为调试级别，默认不会显示
    f"Processed News Details: Title='{title}', Event='{event_info['event']}', Locations={event_info['locations']}, Time='{event_info['time']}'"
)
    return event_info

def process_news_events():
    """
    处理新闻事件
    """
    from concurrent.futures import ThreadPoolExecutor

     # 生成批次编号（使用时间戳）
    batch_id = datetime.now().strftime("%Y%m%d%H%M%S")  # 例如：20241115010513

    news_entries = news_model.read_news()
    logging.info(f"Found {len(news_entries)} news entries to process.")

    total_count = len(news_entries)  # 总条目数
    success_count = 0  # 成功处理计数
    failure_count = 0  # 失败处理计数

    def process_single_news(news):
        nonlocal success_count, failure_count  # 引用外部变量
        try:
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
            success_count += 1  # 成功处理计数器增加

            # 简化日志：仅显示新闻标题和成功信息
            logging.debug(f"Processed successfully: Title='{title}'")

        except Exception as e:
            logging.error(f"Failed to process: Title='{news.get('title', '')}', Error='{str(e)}'")
            failure_count += 1  # 失败计数器增加

    with ThreadPoolExecutor(max_workers=10) as executor:
        executor.map(process_single_news, news_entries)

        # 添加运行后日志总结
    logging.info(f"Processing Summary: Total={total_count}, Success={success_count}, Failure={failure_count}")

    # 调用 log_model 添加日志条目
    log_model.add_log(
        level="INFO",  # 日志级别
        message=f"Processing Summary: Total={total_count}, Success={success_count}, Failure={failure_count}",  # 组合日志内容
        operation="nlp_process",  # 操作类型
        batch_id=batch_id  # 如果有批次标识，可以替换为实际值
    )


if __name__ == "__main__":
    process_news_events()
