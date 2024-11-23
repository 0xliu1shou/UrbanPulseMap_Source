<!-- src/components/map/items/TotalNewsItem.vue -->
<!-- 全部新闻组件，为TotalNewsPanel下的子组件，负责将父组件传递过来的新闻事件逐一展示 -->
<template>
  <li class="total-news-item">
    <!-- 使用 v-html 渲染截断后的标题内容 -->
    <h4 class="total-news-title" v-html="truncateTitle(event.title)">
    </h4>

    <!-- 发布日期 -- 新增竖线和“ver artigo original” -->
    <p class="total-publication-date">
      {{ event.publication_date }}
      <span class="map-news-divider"></span>
      <a @click.stop="openLink(event.link)" class="view-original-link">ver artigo original</a>
    </p> 
  </li>
</template>

<script>
export default {
  name: "TotalNewsItem",
  props: {
    event: Object,
  },
  methods: {
    /**
     * 截断标题到 60 字符以内
     * @param {string} title - 新闻标题
     * @returns {string} - 截断后的标题
     */
    truncateTitle(title) {
      return title.length > 60 ? `${title.substring(0, 60)}...` : title;
    },
    // 在新标签页中打开新闻链接
    openLink(link) {
      window.open(link, "_blank");
    },
  },
};
</script>

<style>
@import "@/styles/theme.css";

.total-news-item {
  min-width: 30%;
  background: var(--accent-color-2);
  margin: 0 5px 10px 5px;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.2);
  transition: transform 0.3s, box-shadow 0.3s;
  display: flex;
  flex-direction: column;
}

/* 鼠标悬停时缩放和阴影效果 */
.total-news-item:hover {
  transform: scale(1.02);
  box-shadow: 0px 6px 12px rgba(0, 0, 0, 0.3);
}

/* 新闻标题样式 */
.total-news-title {
  color: var(--font-color-light);
  font-size: 1.2em;
  margin-bottom: 10px;
  cursor: pointer;
  text-shadow: 1px 1px 4px rgba(146, 161, 194, 0.4); /* 提高文字可读性 */
}

/* 发布日期样式 */
.total-publication-date {
  margin-top: auto; /* 将其推到父容器的底部 */
  color: var(--background-light);
  font-size: 0.85em;
  margin-bottom: 10px;
  margin-left:5px;
  font-style: italic;
  display: flex; /* 将内容并排显示 */
  justify-content: space-between;
  align-items: center;
}

.map-news-divider {
  width: 2px;
  height: 12px;
  background-color: var(--highlight-color); /* 竖线颜色 */
  margin: 0 10px; /* 竖线左右留一定间距 */
}

.view-original-link {
  color: var(--background-light);
  text-decoration: none;
  font-size: 1.1em;
  font-weight: bold;
  cursor: pointer;
  transition: color 0.3s;
  margin-right:30px;
}

.view-original-link:hover {
  color: var(--primary-color);
  text-decoration: underline; /* 悬停时添加下划线 */
  transform: scale(1.05); /* 可选：悬停时放大一点点 */
}
</style>