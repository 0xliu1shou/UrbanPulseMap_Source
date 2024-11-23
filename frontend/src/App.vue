<!-- src/App.vue -->
<template>
  <router-view /> <!-- 渲染不同的布局，由路由控制 -->
</template>

<script>
export default {
  name: "App",
};
</script>

<style>
/* 全局样式或根组件样式 */
@import "@/styles/theme.css";
</style>