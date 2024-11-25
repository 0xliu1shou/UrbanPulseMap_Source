// ./frontend/src/main.js
import { createApp } from 'vue'; 
import App from './App.vue';
import 'leaflet/dist/leaflet.css'; 
import router from './router'; 
import store from './store'; 
import './styles/theme.css'; 
import axios from 'axios'; 
import config from './config'; // 从 config.js 引入配置

// 使用 config 中的 apiBaseUrl 设置 axios 的全局基础路径
axios.defaults.baseURL = config.apiBaseUrl;

// 创建并挂载 Vue 应用实例，并使用路由和 store
const app = createApp(App);
app.use(router);
app.use(store); 
app.mount('#app');