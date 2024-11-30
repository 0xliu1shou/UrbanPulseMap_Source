# ./backend/nlp/utils/event.py
# 用预训练模型处理新闻文本并提取新闻事件关键词
import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
import logging
from backend.nlp.dicts import LABEL_TO_EVENT_TYPE, EVENT_TYPE_KEYWORDS
from transformers import pipeline, AutoTokenizer, AutoModelForSequenceClassification
import torch

device = 0 if torch.cuda.is_available() else -1  # 确保模型使用 GPU（如果可用）

# 加载分类模型
tokenizer = AutoTokenizer.from_pretrained("neuralmind/bert-base-portuguese-cased")
model = AutoModelForSequenceClassification.from_pretrained("neuralmind/bert-base-portuguese-cased")
event_classifier = pipeline("text-classification", model=model, tokenizer=tokenizer, device=device)


def identify_event_type(doc):
    """
    提取事件类型，优先使用 spaCy 匹配、关键词匹配和预训练模型分类
    """
    try:
        # 使用预训练分类模型预测事件类型
        text = " ".join([ent.text for ent in doc.ents if ent.label_ == "EVENT"] or [doc.text])
        classification = event_classifier(text)[0]
        label = classification['label']

        # 调试信息：检查分类输出
        logging.debug(f"Model classification output: {classification}")

        # 使用 dicts.py 中的 LABEL_TO_EVENT_TYPE 进行映射
        event = LABEL_TO_EVENT_TYPE.get(label, "unknown")

        if event != "unknown":
            logging.debug(f"Mapped event type: {event}")
            return event

    except Exception as e:
        logging.error(f"Error in event classification: {e}")
        return "unknown"

    # 使用关键词匹配
    for token in doc:
        lemma = token.lemma_.lower()
        if lemma in EVENT_TYPE_KEYWORDS:
            logging.debug(f"Matched keyword: {lemma}")
            return lemma

    # 使用全文模糊匹配
    for keyword in EVENT_TYPE_KEYWORDS:
        if keyword in doc.text.lower():
            logging.debug(f"Matched keyword in text: {keyword}")
            return keyword

    logging.debug(f"No match found for text: {doc.text}")
    return "unknown"


