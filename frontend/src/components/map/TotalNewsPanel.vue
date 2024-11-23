<!-- src/components/map/TotalNewsPanel.vue -->
<!-- 全部新闻面板，MapView下的子组件，负责将从父组件获得的数据传递给TotalNewsItem组件进行展示 --> 
<template>
  <div class="total-news-panel-content">
    <h3 class="total-news-panel-title">Aconteceu Hoje</h3>
    <ul class="total-news-panel-list">
      <TotalNewsItem
        v-for="event in events"
        :key="event._id"
        :event="event"
      />
    </ul>
  </div>
</template>

<script>
import TotalNewsItem from './items/TotalNewsItem.vue';

export default {
  name: "TotalNewsPanel",
  components: {
    TotalNewsItem
  },
  props: {
    events: {
      type: Array,
      default: () => []
    }
  }
};
</script>

<style>

.total-news-panel-content {
  height: 90%;
  max-width: 100%;
  overflow-y: auto; /* 启用垂直滚动 */
  padding: 0 15px 0 10px;
  background-color: var(--background-light) !important;
  display: flex;
  flex-direction: column;
  border-radius: 15px; /* 设置组件的圆角 */
}

.total-news-panel-title {
  font-size: 1.3em;
  margin: 0 0 20px 0;
  padding: 2% 0 0 0%;
  text-align: center;
  color: var(--secondary-color);
  font-family: 'Shentox', sans-serif;
  font-weight: bold;
}

.total-news-panel-list {
  list-style: none; /* 去除列表样式 */
  padding: 0;
  margin: 0;
  display: flex; /* 使用 Flexbox 以实现横向排列 */
  flex-wrap: nowrap; /* 禁止换行，强制横向滚动 */
  gap: 5px; /* 子元素间距 */
  overflow-x: auto; /* 启用横向滚动 */
}

/* 滚动条整体样式 */
.total-news-panel-list::-webkit-scrollbar {
  height: 13px; /* 设置滚动条的高度（横向滚动条） */
  background: var(--primary-color); /* 滚动条背景颜色 */
  border-radius: 15px; /* 圆角 */
}

/* 滚动条滑块样式 */
.total-news-panel-list::-webkit-scrollbar-thumb {
  width: 15%;
  background: var(--highlight-color); /* 滑块颜色 */
  border-radius: 50px; /* 圆角 */
  border-bottom: 2px solid var(--background-light);
  border-top: 2px solid var(--background-light);
}

/* 滚动条在鼠标悬停时的样式 */
.total-news-panel-list::-webkit-scrollbar-thumb:hover {
  background: var(--secondary-color); /* 鼠标悬停时滑块颜色 */
}

/* 滚动条轨道样式 */
.total-news-panel-list::-webkit-scrollbar-track {
  background: var(--background-light); /* 轨道背景颜色 */
  border-radius: 15px; /* 圆角 */
}
</style>