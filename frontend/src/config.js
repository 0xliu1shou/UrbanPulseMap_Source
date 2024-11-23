// src/config.js
const config = {
    apiBaseUrl: process.env.NODE_ENV === 'production'
      ? 'https://your-production-api.com' // 生产环境 API 地址
      : 'http://127.0.0.1:5000' // 开发环境 API 地址
  };
  
  export default config;