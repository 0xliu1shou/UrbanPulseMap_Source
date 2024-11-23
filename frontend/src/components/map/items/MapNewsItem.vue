<!-- src/components/map/items/MapNewsItem.vue -->
<!-- 地图新闻组件，为MapNewsPanel子组件，负责将父组件传递过来的点击事件的数据逐一展示 -->
<template>
  <li class="map-news-item">
    <!-- 使用 v-html 渲染 HTML 格式的标题内容 -->
    <h4 class="map-news-title" v-html="event.title">
    </h4>
    
    <!-- 使用 v-html 渲染 HTML 格式的新闻摘要，并根据是否展开进行截断 -->
    <p class="map-news-summary" :class="{ expanded: isExpanded }">
      <span v-html="isExpanded 
        ? (event.summary || 'Resumo indisponível') 
        : truncateHTML(event.summary || 'Resumo indisponível')">
      </span>
    </p>
    
    <!-- 发布日期 发布源 -->
    <p class="map-publication-date">
      {{ event.publication_date }}
      <a class="news-source"
       @click.stop="openLink(event.link)" style="cursor: pointer;"> 
        Fonte: {{ event.source }} </a>
    </p>

    <!-- 展开/收起按钮 -->
    <BaseButton 
      @click.stop="toggleExpand" 
      type="primary">
      {{ isExpanded ? "Recolher" : "Expandir" }}
    </BaseButton>
  </li>
</template>

<script>
import BaseButton from "@/components/common/BaseButton.vue";

export default {
  name: "MapNewsItem",
  components: {
    BaseButton,
  },
  props: {
    event: Object
  },
  data() {
    return {
      isExpanded: false, // 控制新闻摘要的展开状态
    };
  },
  methods: {
    // 截断新闻摘要的 HTML 内容
    truncateHTML(htmlContent) {
      const div = document.createElement("div");
      div.innerHTML = htmlContent;
      const textContent = div.innerText || div.textContent || "";
      return textContent.length > 120 ? `${textContent.substring(0, 120)}...` : textContent;
    },

    // 切换新闻摘要的展开状态
    toggleExpand() {
      console.log("Summary:", this.event.summary);
      console.log("Truncated:", this.truncateHTML(this.event.summary));
      this.isExpanded = !this.isExpanded;
      console.log("Toggle Expand:", this.isExpanded);
    },
    // 在新标签页中打开新闻链接
    openLink(link) {
      window.open(link, "_blank");
    }
  }
};
</script>

<style>
@import "@/styles/theme.css";

.map-news-item {
  background: var(--background-light);
  margin: 10px 15px 10px 15px !important;
  padding: 15px;
  border-radius: 8px;
  box-shadow: 0px 4px 8px rgba(0, 0, 0, 0.2);
  transition: transform 0.3s, box-shadow 0.3s;
  display: flex;
  flex-direction: column;
}

/* 鼠标悬停时缩放和阴影效果 */
.map-news-item:hover {
  transform: scale(1.02);
  box-shadow: 0px 6px 12px rgba(0, 0, 0, 0.3);
}

/* 新闻标题样式 */
.map-news-title {
  color: var(--secondary-color);
  font-size: 1.2em;
  margin-bottom: 10px;
  text-shadow: 1px 1px 4px rgba(146, 161, 194, 0.4); /* 提高文字可读性 */
}

/* 新闻摘要样式 */
.map-news-summary {
  color: var(--font-color-dark);
  font-size: 1em;
  line-height: 1.5;
  margin-bottom: 10px;
  max-height: 3.6em; /* 初始显示为两行高度 */
  overflow: hidden;
  transition: max-height 0.3s ease;
}

/* 展开状态下显示完整内容 */
.map-news-summary.expanded {
  max-height: none !important;
}

/* 发布日期样式 */
.map-publication-date {
  color: var(--highlight-color); /* 使用强调色，便于用户快速识别日期 */
  font-size: 0.85em;
  margin-bottom: 10px;
  font-style: italic;
  display: flex; /* 使用 Flexbox 布局 */
  justify-content: space-between; /* 左右对齐 */
  align-items: center; /* 垂直居中对齐 */
}

/* 新闻发布源样式 */
.news-source {
  font-weight: bold;
  font-size: 1.1em;
  color: var(--highlight-color);
  text-align: right; /* 文字靠右对齐 */
  cursor: pointer;
  transition: color 0.3s, text-decoration 0.3s; /* 添加平滑过渡效果 */
}

/* 新闻发布源悬停样式 */
.news-source:hover {
  color: var(--secondary-color); /* 悬停时改变颜色 */
  text-decoration: underline; /* 悬停时添加下划线 */
  transform: scale(1.05); /* 可选：悬停时放大一点点 */
}
</style>