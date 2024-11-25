// ./frontend/src/config.js
// api 接口配置文件，用于配置后端服务的 api 地址，供前端网页组件调用
const config = {
    apiBaseUrl: process.env.NODE_ENV === 'production'
      ? 'https://your-production-api.com' // 生产环境 API 地址
      : 'http://127.0.0.1:5000' // 开发环境 API 地址
  };
  
  export default config;