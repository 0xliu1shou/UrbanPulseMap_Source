# ./backend/scheduler/scheduler.py
# 定时调度文件，每半小时调度执行一次爬虫和nlp数据处理脚本

import subprocess
import time
from datetime import datetime
import os

# 获取当前脚本所在目录的绝对路径
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# 定时调度任务
def run_task(command, description):
    """
    运行单个任务，并记录详细日志
    参数:
        command (str): 系统命令（例如: "python3 rss_aggregator.py"）。
        description (str): 任务描述，用于日志记录。
    """
    try:
        print(f"[{datetime.now()}] INFO: Starting task: {description} with command: {command}")
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        
        # 记录标准输出
        if result.stdout:
            print(f"[{datetime.now()}] INFO: Task {description} output:\n{result.stdout.strip()}")

        # 记录标准错误输出
        if result.stderr:
            print(f"[{datetime.now()}] WARNING: Task {description} error output:\n{result.stderr.strip()}")

        print(f"[{datetime.now()}] INFO: Task completed successfully: {description}")
    except subprocess.CalledProcessError as e:
        # 捕获任务失败信息
        print(f"[{datetime.now()}] ERROR: Task failed: {description}")
        print(f"[{datetime.now()}] ERROR: Command: {e.cmd}")
        print(f"[{datetime.now()}] ERROR: Return Code: {e.returncode}")
        if e.output:
            print(f"[{datetime.now()}] ERROR: Task {description} output:\n{e.output.strip()}")
        if e.stderr:
            print(f"[{datetime.now()}] ERROR: Task {description} error output:\n{e.stderr.strip()}")

if __name__ == "__main__":
    while True:
        print(f"[{datetime.now()}] INFO: Scheduler is starting a new cycle.")
        
        # 构建正确的脚本路径
        rss_aggregator_path = os.path.join(BASE_DIR, "../aggregator/rss_aggregator.py")
        nlp_path = os.path.join(BASE_DIR, "../nlp/nlp.py")

        # 执行爬虫任务
        run_task(f"python3 {rss_aggregator_path}", "Run RSS Aggregator")
        
        # 执行 NLP 任务
        run_task(f"python3 {nlp_path}", "Run NLP Analysis")

        print(f"[{datetime.now()}] INFO: Scheduler is sleeping for 30 minutes.")
        # 休眠半小时
        time.sleep(1800)