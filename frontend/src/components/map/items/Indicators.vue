<!-- src/components/map/items/Indicators.vue -->
<!-- 地图标记工具，用于提供单一标记和聚合标记的生成与工作方法，供MapContainer调用 -->
<template>
  <div>
    <!-- Indicator.vue 不直接渲染内容，只提供单一标记和聚合标记的逻辑 -->
  </div>
</template>

<script>
import L from "leaflet";

export default {
  name: "Indicators",
  props: {
    markers: {
      type: Array,
      default: () => [],
    },
  },
  methods: {
    /**
     * 创建单一标记
     * @param {Array} coordinates - 标记的经纬度数组 [latitude, longitude]
     * @param {Number} newsCount - 此标记的新闻条目数
     * @param {Function} onClick - 点击标记触发的回调函数
     * @returns {L.Marker} - Leaflet 单一标记
     */

    // 创建带新闻数量的单一标记自定义图标
    createSingleMarker(coordinates, newsCount, onClick) {
      const customIcon = L.divIcon({
        className: "custom-single-marker",
        html: `<div class="single-marker-icon">${newsCount}</div>`, // 动态显示新闻数量
        iconSize: [30, 30], // 图标大小
        iconAnchor: [15, 40], // 图标锚点
      });

      // 创建标记并使用自定义图标，即使经纬度是默认值，也应生成 marker
      const marker = L.marker(coordinates, { icon: customIcon });
      if (onClick) {
        marker.on("click", onClick);
      }
      return marker;
    },

    /**
     * 创建聚合标记
     * @param {Array} childMarkers - 聚合内的所有单一标记
     * @returns {L.DivIcon} - Leaflet 聚合标记
     */

    
    createClusterIcon(childMarkers) {
      try {
        // 计算所有单个标记的新闻条目的总和
        const totalNewsCount = childMarkers.reduce((sum, marker) => {
          // 从 marker.options.newsCount 或 icon.options.html 获取数量
          const newsCount = marker.options.newsCount || 
            parseInt(marker.options.icon.options.html.replace(/<[^>]*>/g, '')) || 0; // 去除 HTML 标签后解析
          return sum + newsCount;
        }, 0);

        // 创建自定义的聚合图标
        return L.divIcon({
          className: "custom-cluster-marker",
          html: `<div class="cluster-marker-icon">${totalNewsCount}</div>`,
          iconSize: [40, 40], // 自定义聚合图标大小
          iconAnchor: [20, 20], //锚点
        });
      } catch (error) {
        console.error("Error in createClusterIcon:", error);

        // 创建失败则提供默认的聚合图标
        return L.divIcon({
          className: "custom-cluster-marker",
          html: `<div class="cluster-marker-icon">0</div>`,
          iconSize: [40, 40], // 自定义聚合图标大小
          iconAnchor: [20, 20], //锚点
        });
      }
    },
  },
};
</script>

<style>
/* 单一标记样式 */
/* 圆头 */
.custom-single-marker {
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  background: var(--highlight-color);
  color: var(--font-color-light);
  border-radius: 15px 15px 12px 12px;
  box-shadow: 0 0 8px rgba(0, 0, 0, 0.3);
  width: 30px;
  height: 30px;
}

/* 尖底 */
.custom-single-marker::after {
  content: "";
  position: absolute;
  bottom: -10px; /* 与主体下边对齐 */
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 13px solid transparent; /* 左侧边框透明 */
  border-right: 13px solid transparent; /* 右侧边框透明 */
  border-top: 15px solid var(--highlight-color); /* 顶部颜色与主体一致 */
}

.single-marker-icon {
  text-align: center;
  line-height: 30px; /* 与容器高度一致确保数字居中 */
  font-family: "Shentox", sans-serif;
  font-weight: bold;
  font-size: 1em;
}

/* 聚合标记样式 */
.custom-cluster-marker {
  display: flex;
  justify-content: center;
  align-items: center;
  background: var(--accent-color-1);
  color: var(--font-color-light);
  border-radius: 50%;
  box-shadow: 0 0 10px rgba(0, 0, 0, 0.3);
  width: 40px;
  height: 40px;
}

.cluster-marker-icon {
  text-align: center;
  line-height: 40px;  /* 确保数字居中 */
  font-family: "Shentox", sans-serif;
  font-weight: bold;
  font-size: 1.2em;
}
</style>