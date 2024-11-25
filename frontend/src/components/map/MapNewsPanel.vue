<!-- ./frontend/src/components/map/MapNewsPanel.vue -->
<!-- 地图新闻面板，MapView 下的子组件，负责接收 MapContainer 点击事件传递回父组件的某地图标记上的事件，再传递给 MapNewsItem 进行展示 -->
<template>
  <div class="map-panel-content">
    <h3 class="map-panel-title">Eventos Locais</h3>
    <ul class="map-news-panel-list">
      <template v-if="events.length > 0">
        <MapNewsItem
          v-for="event in events"
          :key="event._id"
          :event="event"
        />
      </template>
      <template v-else>
        <p class="placeholder-text">
          Clique no marcador no mapa para ver os eventos ocorridos nesse local nas últimas 24 horas.
        </p>
      </template>
    </ul>
  </div>
</template>

<script>
import MapNewsItem from './items/MapNewsItem.vue'; // 导入 MapNewsItem 组件

export default {
  name: "MapPanel",
  components: {
    MapNewsItem, // 注册 MapNewsItem 组件
  },
  props: {
    events: {
      type: Array,
      required: true, // 确保事件数据从父组件传递
    },
  },
};
</script>

<style>
.map-panel-content {
  width: 100%; /* 占父容器的 30% */
  height: 100%;
  padding: 0px;
  margin: 0px;
  background: var(--accent-color-1);
  display: flex;
  flex-direction: column;
  border-radius: 15px; /* 设置组件的圆角 */
}

.map-panel-title {
  color: var(--font-color-light);
  text-align: center;
  font-size: 1.6em;
  margin-bottom: 20px;
  text-shadow: 1px 1px 6px rgba(146, 161, 194, 0.4);
  font-weight: bold;
}

.map-news-panel-list {
  list-style: none;
  padding: 0 0 0 0;
  margin: 0 0 10px 0;
  overflow-y: auto;
}

/* 占位文字样式 */
.placeholder-text {
  text-align: center;
  font-size: 1.2em;
  color: var(--background-color-light);
  padding: 20px;
  font-style: italic;
}

/* 滚动条整体样式 */
.map-news-panel-list::-webkit-scrollbar {
  height: 15px; /* 设置滚动条的宽度 */
  background: var(--accent-color-1); /* 滚动条背景颜色 */
  border-radius: 15px; /* 圆角 */
}

/* 滚动条滑块样式 */
.map-news-panel-list::-webkit-scrollbar-thumb {
  background: var(--background-light); /* 滑块颜色 */
  border-radius: 50px; /* 圆角 */
  background-clip: padding-box; /* 保留透明边框的效果 */
  border-right: 3px solid var(--accent-color-1);
  border-left: 3px solid var(--accent-color-1);
}

/* 滚动条在鼠标悬停时的样式 */
.map-news-panel-list::-webkit-scrollbar-thumb:hover {
  background: var(--primary-color); /* 鼠标悬停时滑块颜色 */
}

/* 滚动条轨道样式 */
.map-news-panel-list::-webkit-scrollbar-track {
  background: transparent; /* 轨道透明 */
  border-radius: 4px; /* 圆角 */
  padding: 2px;
  margin: 0 10px 0 0;
}
</style>