<!-- ./frontend/src/components/map/MapContainer.vue -->
<!-- 地图容器，为 MapView 下的子组件，负责将从父组件获取的数据用地图标记的方式进行展示，并提供点击地图标记传递该标记上的新闻回父组件功能 -->
<template>
  <div id="map-container">
    <!-- 地图容器，调用Indicators中的地图标记部件 -->
    <Indicators ref="indicator" />
    <!-- 提供重置视图按钮 -->
    <div class="reset-button-wrapper">
      <BaseButton @click="resetMapView" type="primary">Reset</BaseButton>
    </div>
  </div>

</template>

<script>
import L from "leaflet";
import "leaflet/dist/leaflet.css";
import "leaflet.markercluster";
import "leaflet.markercluster/dist/MarkerCluster.css";
import "leaflet.markercluster/dist/MarkerCluster.Default.css";
import Indicators from "./items/Indicators.vue";
import BaseButton from "@/components/common/BaseButton.vue";

export default {
  name: "MapContainer",
  components: {
    Indicators,
    BaseButton,
  },
  emits: ["marker-click"], // 添加此行，声明自定义事件
  props: {
    events: {
      type: Array,
      default: () => [],
    },
  },
  props: {
    events: {
      type: Array,
      default: () => [],
    },
  },
  data() {
    return {
      map: null, // 地图实例
      markers: null, // MarkerCluster 实例
    };
  },
  mounted() {
    // 初始化地图
    this.initMap();
    // 初始化 MarkerCluster 实例
    this.initMarkerCluster();
    // 加载事件数据到聚合层
    this.loadMarkers(this.events);
  },
  beforeUnmount() {
    if (this.map) {
      this.map.off(); // 移除所有监听器
      this.map.remove(); // 销毁地图实例
      this.map = null;
    }

    if (this.markers) {
      this.markers.clearLayers(); // 清理所有标记
      this.markers = null;
    }
  },
  watch: {
    events: {
      immediate: true,
      handler(newEvents) {
        if (this.map && this.markers) {
          // 清空现有标记
          this.loadMarkers(newEvents);
        }
      },
    },
  },
  methods: {
    /**
     * 初始化地图
     */
    initMap() {
      this.map = L.map("map-container", {
        zoomAnimation: true,
        duration: 0.3,
        inertia: true,
      }).setView([39.813597, -7.495726], 5);

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: '&copy; <a href="https://osm.org/copyright">OpenStreetMap</a> contributors',
      }).addTo(this.map);
    },

    /**
     * 初始化 MarkerCluster 实例
     */
    initMarkerCluster() {
      try {
        this.markers = L.markerClusterGroup({
          /// 使用 Indicators 的 createClusterIcon 方法
          iconCreateFunction: (cluster) => {
            const markers = cluster.getAllChildMarkers(); // 获取聚合中的所有标记
            return this.$refs.indicator.createClusterIcon(markers); // 调用 Indicators 子组件的cluster marker方法
          },
        });

        this.map.addLayer(this.markers);
      } catch (error) {
        console.error("Error in initMarkerCluster:", error);
      }
    },

    /**
     * 加载事件数据到 MarkerCluster
     * @param {Array} events - 事件数据数组
     */
    loadMarkers(events) {
      try {
        // 清理旧标记
        if (this.markers) {
          this.markers.clearLayers();
        }

        // 过滤掉无效坐标的事件
        const validEvents = events.filter((event) => !isNaN(event.latitude) && 
        !isNaN(event.longitude) && 
        event.latitude !== null && 
        event.longitude !== null);
        
        // 按地理位置分组事件
        const groupedEvents = this.groupByCoordinates(validEvents);
        groupedEvents.forEach(({ coordinates, events }) => {
          let [latitude, longitude] = coordinates;
          
          const marker = this.$refs.indicator.createSingleMarker(
            [latitude, longitude],
            events.length, // 使用事件分组的数量
            () => {
              this.$emit("marker-click", events); // 点击事件传递当前事件
            }
          );

          // 为每个标记设置新闻数量，以便后续聚合标记使用
          marker.options.newsCount = events.length;

          this.markers.addLayer(marker);
        });
      } catch (error) {
        console.error("Error in loadMarkers:", error);
      }
    },

    /**
     * 按地理位置分组事件
     * @param {Array} events - 事件数据数组
     * @returns {Array} - 分组后的事件数据
     */
    groupByCoordinates(events) {
      const grouped = {};
      events.forEach((event) => {
        let { latitude, longitude } = event;
   
      // 忽略无效坐标
      if (isNaN(latitude) || isNaN(longitude) || latitude === null || longitude === null) {
        return;
      }

        const key = `${latitude},${longitude}`;
        if (!grouped[key]) {
          grouped[key] = [];
        }
        grouped[key].push(event);
      });
      return Object.keys(grouped).map((key) => ({
        coordinates: key.split(",").map(Number),
        events: grouped[key],
      }));
    },

    /**
     * 重置地图视图到默认位置
     */
    resetMapView() {
      if (this.map) {
        this.map.setView([39.813597, -7.495726], 5);
      }
    },
  },
};
</script>

<style>
/* 地图容器样式 */
#map-container {
  width: 100%;
  height: 100%;
  background: var(--background-color);
  border-radius: 15px; /* 设置组件的圆角 */
  padding: 0px;
  position: relative; /* 为子元素的绝对定位提供参考点 */
}

/* 控制按钮容器的布局样式 */
.reset-button-wrapper {
  position: absolute;
  bottom: 20px;
  left: 20px;
  z-index: 1000;
}
</style>