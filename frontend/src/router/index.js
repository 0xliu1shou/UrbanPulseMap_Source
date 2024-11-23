// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router';

// 导入页面组件
import MapView from '@/views/MapView.vue';

const routes = [

  { path: '/', component: MapView }, // 直接指向 MapView 页面
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;