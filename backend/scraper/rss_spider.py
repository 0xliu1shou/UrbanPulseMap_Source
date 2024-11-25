# ./backend/scraper/rss_spider.py
# RSS 源爬虫脚本，调用 data_utils 以从 RSS 新闻源爬取新闻数据


import os
import sys
from datetime import datetime

# 添加绝对路径寻找项目根目录
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../..')))

import logging
from backend.scraper.utils.data_utils import process_rss_feed  # 直接调用已封装的处理函数

# 定义 RSS 源及其对应的 source 标识符
RSS_SOURCES = {
    "https://feeds.feedburner.com/PublicoRSS": "pb",  # Publico RSS源
    "https://observador.pt/feed/": "ob",              # Observador RSS源
    "https://www.rtp.pt/noticias/rss": "rtp",         # RTP RSS源
    "https://www.record.pt/rss": "rc",               # Record RSS源
    "https://www.cmjornal.pt/rss": "cm"              # Correio da Manhã RSS源
}

# 日志配置，设置日志级别为 INFO
logging.basicConfig(level=logging.INFO)

def main():
    """
    主函数：处理所有定义的 RSS 源，完成获取、解析、封装和存储操作。
    """
    # 生成批次编号（使用时间戳）
    batch_id = datetime.now().strftime("%Y%m%d%H%M%S")  # 例如：20241115010513

    for url, source in RSS_SOURCES.items():
        logging.info(f"Starting process for source: {source} ({url}), Batch ID: {batch_id}")
        
        # 调用已封装的单源处理函数
        process_rss_feed(url, source, batch_id)
        
        logging.info(f"Completed process for source: {source} ({url}), Batch ID: {batch_id}")


# 当该文件作为脚本运行时，调用 main() 函数
if __name__ == "__main__":
    main()