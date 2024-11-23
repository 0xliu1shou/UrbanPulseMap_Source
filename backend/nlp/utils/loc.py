import os
import sys
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))
import logging
import spacy
from geopy.geocoders import Nominatim
from rapidfuzz import process, fuzz
from backend.nlp.dicts import PORTUGAL_LOCATIONS

nlp = spacy.load("pt_core_news_lg")

# 使用 Nominatim 地理编码器获取经纬度
geolocator = Nominatim(user_agent="news_analyzer")
location_cache = {}  # 缓存地点解析结果

def split_locations(text):
    """
    检查文本中的已知地点名，并尝试分割连续的地点
    """
    matched_locations = []
    start = 0
    while start < len(text):
        substring = text[start:start + 50]
        match = process.extractOne(substring, PORTUGAL_LOCATIONS, scorer=fuzz.ratio, score_cutoff=90)
        if match:
            matched_locations.append(match[0])
            start += len(match[0])
        else:
            break
    return matched_locations


def match_location_nlp(doc):
    """
    使用 NLP 分词器和模糊匹配，处理没有空格分隔的地点名
    """
    matched_locations = set()

    # 遍历 NLP 分词器分出来的 token
    for token in doc:
        match = process.extractOne(token.text, PORTUGAL_LOCATIONS, scorer=fuzz.ratio, score_cutoff=90)
        if match:
            matched_locations.add(match[0])

    return list(matched_locations)


def extract_locations(doc):
    """
    提取所有地点，支持多地点独立提取、模糊匹配和拼写修正
    """
    locations = set()

    def match_location(text):
        """
        在地点字典中进行模糊匹配
        """
        best_match = process.extractOne(text, PORTUGAL_LOCATIONS, scorer=fuzz.ratio, score_cutoff=90)
        if best_match:
            return best_match[0]
        return None

    # 1. 使用 NLP 提取地点实体
    for ent in doc.ents:
        if ent.label_ in {"LOC", "GPE", "ORG"}:
            matched_location = match_location(ent.text.strip())
            if matched_location:
                locations.add(matched_location.strip())

    # 2. 检测依存关系中可能的地点
    for token in doc:
        if token.dep_ in {"nmod", "pobj"} and token.head.text.lower() in {"em", "no", "na", "de", "da", "do"}:
            matched_location = match_location(token.text.strip())
            if matched_location:
                locations.add(matched_location.strip())

    # 3. 检测连续地点名
    split_matched_locations = split_locations(doc.text.strip())
    locations.update(split_matched_locations)

    return list(locations)


def get_coordinates(location_names):
    """
    获取多个地点的经纬度
    """
    results = []
    for location_name in location_names:
        if location_name in location_cache:
            lat, lon = location_cache[location_name]
        else:
            try:
                location = geolocator.geocode(location_name, country_codes="PT", timeout=10)
                if location:
                    lat, lon = location.latitude, location.longitude
                    location_cache[location_name] = (lat, lon)
                else:
                    lat, lon = None, None
            except Exception as e:
                logging.error(f"Error geocoding location '{location_name}': {e}")
                lat, lon = None, None

        results.append({
            "location": location_name,
            "latitude": lat,
            "longitude": lon,
        })
    return results


