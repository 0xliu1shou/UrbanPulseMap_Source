<!-- ./frontend/src/views/MapView.vue -->
<!-- 地图页面父组件，负责从 vuex 获取格式化后的最近24小时数据，并在各子组件之间传递，另有加载页面功能 -->
<template>
  <div class="map-view">
    <!-- 左半部分 -->
    <div class="left-section">
      <!-- 上半部分：地图 -->
      <div class="map-container">
        <MapContainer :events="sortedEvents" @marker-click="handleMarkerClick" />
      </div>
      <!-- 下半部分：新闻面板 -->
      <div class="total-news-panel">
        <TotalNewsPanel :events="sortedEvents" />
      </div>
    </div>

    <!-- 右半部分：地图新闻面板 -->
    <div class="map-news-panel">
      <MapNewsPanel :events="selectedEvents" />
    </div>

    <!-- 加载页面 -->
    <div v-if="isLoading" class="loading-page">
      <div class="loading-animation">
        <!-- 使用 logo 替代原先的加载动画 -->
        <img src="@/assets/logo/logo-main.svg" alt="Loading Logo" class="loading-logo" />
        <!-- 新增炫酷的加载进度条 -->
        <div class="progress-bar">
          <div class="progress"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import MapContainer from '@/components/map/MapContainer.vue';
import MapNewsPanel from '@/components/map/MapNewsPanel.vue';
import TotalNewsPanel from '@/components/map/TotalNewsPanel.vue';
import { mapState, mapActions } from 'vuex';

export default {
  name: "MapView",
  components: {
    MapContainer,
    MapNewsPanel,
    TotalNewsPanel,
  },
  data() {
    return {
      isLoading: true, // 初始状态为加载中
      selectedEvents: [], // 存储点击标记后的事件
    };
  },

  computed: {
    ...mapState(['recentEvents']),
    sortedEvents() {
      return this.recentEvents; // 保持 Vuex 数据为最终格式化结果
    }, 
  },

  mounted() {
    // 模拟加载过程，5秒后关闭加载页面并获取事件数据
    setTimeout(() => {
      this.isLoading = false;
      this.fetchEvents();
    }, 5000); // 加载时间延长至5秒
  },
  methods: {
    ...mapActions(['fetchEvents']),
    /**
     * 处理并传递地图标记点击事件
     * @param {Object} markerDetails - 选中的标记详细信息
     */
    handleMarkerClick(events) {
      this.selectedEvents = events; // 更新选中标记的事件数据
    },
  },
};
</script>

<style>
.map-view {
  display: flex; /* 使用 flex 布局 */
  height: 100vh;
  overflow: hidden; /* 防止内容超出视口 */
  padding: 0px 0px 0px 0px;
}

/* 左半部分 */
.left-section {
  display: flex;
  flex-direction: column; /* 垂直布局 */
  width: 70%; /* 占据 70% 宽度 */
  height: 100%;
  padding: 10px 5px 0px 10px;
}

/* 地图容器（左上部分） */
.map-container {
  flex: 0 0 65%; /* 左半部分的 65% 高度 */
  background-color: var(--background-light);
  border-bottom: 1px solid var(--border-color);
  border-radius: 15px; /* 设置组件的圆角 */
  overflow: hidden; /* 防止溢出 */
  padding: 0px;
  margin: 0 0 5px 0;
}

/* 新闻面板（左下部分） */
.total-news-panel {
  flex: 0 0 35%; /* 左半部分的 35% 高度 */
  background-color: var(--background-dark);
  border-radius: 15px; /* 设置组件的圆角 */
  overflow-y: hidden; /* 启用垂直滚动 */
  padding: 0 0 0 0; /* 增加内边距 */
  margin: 5px 0 0 0;
}

/* 右半部分 */
.map-news-panel {
  width: 30%; /* 右侧占据 30% 宽度 */
  height: 98%;
  background-color: var(--background-light-alt);
  border-radius: 15px; /* 设置组件的圆角 */
  overflow-y: auto; /* 启用垂直滚动 */
  padding: 10px 10px 0px 5px; /* 增加内边距 */
  margin: 0px 0px 0px 0px;
}

/* 加载页面样式 */
.loading-page {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100vh;
  display: flex;
  justify-content: center;
  align-items: center;
  background-color: var(--background-light);
  z-index: 1000;
}

/* 加载动画样式 */
.loading-animation {
  text-align: center;
}

/* 加载 logo 样式 */
.loading-logo {
  width: 500px;
  height: auto;
  animation: pulse 1.5s infinite; /* 添加轻微的缩放和闪烁动画 */
  margin-bottom: 20px;
}

/* pulse 动画定义 */
@keyframes pulse {
  0%, 100% {
    opacity: 1;
    transform: scale(1);
  }
  50% {
    opacity: 0.5;
    transform: scale(1.1);
  }
}

/* 进度条容器样式 */
.progress-bar {
  width: 80%;
  height: 8px;
  background-color: rgba(255, 255, 255, 0.2); /* 背景颜色，稍微透明 */
  border-radius: 4px;
  overflow: hidden; /* 让进度条边界内的内容不可见 */
  margin: 0 auto;
}

/* 动态加载进度条 */
.progress {
  width: 0%; /* 初始宽度为 0 */
  height: 100%;
  background-color: var(--accent-color-1); /* 使用主题的强调色 */
  animation: loading 5s infinite; /* 进度条动画 */
  transition: width 0.3s ease; /* 平滑的过渡效果 */
}

/* 定义进度条动画 */
@keyframes loading {
  0% {
    width: 0%;
  }
  10% {
    width: 20%;
  }
  15% {
    width: 30%;
  }
  25% {
    width: 45%;
  }
  60% {
    width: 60%;
  }
  85% {
    width: 70%;
  }
  100% {
    width: 100%;
  }
}
</style>