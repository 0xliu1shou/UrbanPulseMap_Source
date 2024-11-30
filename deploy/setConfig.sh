# setConfig.sh

# 请确保以 root 或具有 sudo 权限的用户执行

echo "修改 Config 文件..."

# 检查是否以 root 或 sudo 权限运行
echo "正在检查是否以 root 用户或通过 sudo 执行此脚本..."
if ! sudo -n true 2>/dev/null; then
    echo "请以 root 用户或通过 sudo 执行此脚本。"
    exit 1
fi

# 询问用户输入变量
read -p "请输入您的域名 (例如: upmap.cc): " DOMAIN
if [ -z "$DOMAIN" ]; then
    echo "域名不能为空，请重新运行脚本并输入有效的域名。"
    exit 1
fi

read -p "请输入项目根目录路径 (例如: /home/ubuntu/UrbanPulseMap_Source): " PROJECT_DIR
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录无效或不存在，请检查路径后重新运行脚本。"
    exit 1
fi

BACKEND_PORT=${BACKEND_PORT:-5000}
MONGO_PORT=${MONGO_PORT:-27017}
FRONTEND_DIR="$PROJECT_DIR/frontend"
BACKEND_DIR="$PROJECT_DIR/backend"

echo "开始部署配置文件..."
echo "域名: $DOMAIN"
echo "项目目录: $PROJECT_DIR"
echo "后端端口: $BACKEND_PORT"
echo "MongoDB 端口: $MONGO_PORT"

# 检查项目目录是否存在
echo "检查项目目录 $PROJECT_DIR 是否存在..."
if [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录 $PROJECT_DIR 不存在，请检查输入路径"
    exit 1
fi

# 1. 设置 vite.config.js 配置
echo "配置 Vite 服务..."

VITE_CONFIG="$FRONTEND_DIR/vite.config.js"

# 检查前端目录是否存在
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "❌ 前端目录 $FRONTEND_DIR 不存在，请检查路径配置。"
    exit 1
fi

# 检查 vite.config.js 是否存在并备份
if [ -f "$VITE_CONFIG" ]; then
    BACKUP_FILE="$FRONTEND_DIR/vite.config.js.bak.$(date +%Y%m%d%H%M%S)"
    cp "$VITE_CONFIG" "$BACKUP_FILE"
    if [ $? -ne 0 ]; then
        echo "❌ 备份 vite.config.js 失败，请检查路径和权限。"
        exit 1
    fi
    echo "✅ 已备份现有 vite.config.js 为 $BACKUP_FILE"
else
    echo "ℹ️ 未检测到现有 vite.config.js 文件，跳过备份。"
fi

# 创建或覆盖 vite.config.js 文件
cat <<EOF > $VITE_CONFIG
import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import path from 'path'; // 导入 path 模块

export default defineConfig({
  plugins: [vue()],
  base: '/', // 确保资源以根路径加载
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'), // 配置路径别名
    },
  },
  build: {
    outDir: 'dist', // 指定输出目录
    assetsDir: 'assets', // 静态资源存放的子目录
    rollupOptions: {
      input: 'index.html', // 指定入口文件
    },
  },
  publicDir: 'public', // 确保 public 文件夹内容被复制到 dist
  optimizeDeps: {
    // 强制预构建 CommonJS 格式的依赖项
    include: ['axios', 'vue-router', 'vuex'], // 添加项目中的依赖项
  },
});
EOF
# 验证写入是否成功
if [ $? -ne 0 ]; then
    echo "vite.config.js 文件写入失败，请检查路径和权限。"
    exit 1
fi
echo "vite.config.js 配置已完成。"


# 2. 设置 Nginx 配置
echo "配置 Nginx..."
if [ -z "$DOMAIN" ]; then
    echo "域名未设置，请重新运行脚本并输入有效的域名。"
    exit 1
fi
NGINX_CONF="/etc/nginx/sites-available/$DOMAIN"
NGINX_ENABLED="/etc/nginx/sites-enabled/$DOMAIN"
# 检查 Nginx 安装状态
if ! command -v nginx >/dev/null; then
    echo "Nginx 未安装或安装失败，请检查安装步骤。"
    exit 1
fi
# 检查目录
if [ ! -d "/etc/nginx/sites-available" ] || [ ! -d "/etc/nginx/sites-enabled" ]; then
    echo "Nginx 配置目录不存在，请检查 Nginx 安装状态。"
    exit 1
fi
# 删除默认站点配置（如果存在）
if [ -f /etc/nginx/sites-enabled/default ]; then
    sudo rm -f /etc/nginx/sites-enabled/default
fi
# 创建新的 Nginx 配置
cat <<EOF | sudo tee $NGINX_CONF
# 配置 HTTP 跳转到 HTTPS
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;

    # 强制重定向到 HTTPS
    return 301 https://\$host\$request_uri;
}

# 配置 HTTPS
server {
    listen 443 ssl;
    server_name $DOMAIN www.$DOMAIN;

    # SSL 证书路径
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;

    # 前端页面
    root $FRONTEND_DIR/dist;
    index index.html;

    # 配置 favicon.ico
    location = /favicon.ico {
        log_not_found on;
        access_log on;
        root /home/ubuntu/UrbanPulseMap_Source/frontend/dist;
        types { image/x-icon ico; }
        default_type image/x-icon;
        try_files $uri =404;
    }

    # 配置前端路由
    location / {
        try_files \$uri /index.html;
    }

    # 后端 API 路由代理
    location /api/ {
        proxy_pass http://127.0.0.1:$BACKEND_PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }

    # 日志
    error_log /var/log/nginx/$DOMAIN\_error.log;
    access_log /var/log/nginx/$DOMAIN\_access.log;
}
EOF

# 创建符号链接到 sites-enabled
if [ -f "$NGINX_CONF" ]; then
    echo "创建 Nginx 配置文件成功，准备启用..."
    if [ ! -d "/var/log/nginx" ]; then
        sudo mkdir -p /var/log/nginx
    fi
    sudo ln -sf $NGINX_CONF $NGINX_ENABLED
else
    echo "Nginx 配置文件创建失败，请检查脚本逻辑。"
    exit 1
fi
# 测试 Nginx 配置语法
echo "测试 Nginx 配置语法..."
sudo nginx -t || { echo "Nginx 配置语法测试失败"; exit 1; }
# 重新加载 Nginx 服务
echo "重新加载 Nginx 服务..."
sudo systemctl reload nginx


# 3. 配置前端 config.js 文件
echo "配置前端 API 地址..."

CONFIG_JS="$FRONTEND_DIR/src/config.js"

# 检查 config.js 是否存在
if [ ! -f "$CONFIG_JS" ]; then
    echo "config.js 文件不存在，请检查路径：$CONFIG_JS"
    exit 1
fi
# 替换 config.js 文件中的生产环境 API 地址
cat <<EOF > $CONFIG_JS
// ./frontend/src/config.js
// api 接口配置文件，用于配置后端服务的 api 地址，供前端网页组件调用
const config = {
    apiBaseUrl: process.env.NODE_ENV === 'production'
      ? 'https://$DOMAIN' // 生产环境 API 地址
      : 'http://127.0.0.1:5000' // 开发环境 API 地址
  };
  
export default config;
EOF

# 验证写入是否成功
if [ $? -ne 0 ]; then
    echo "config.js 文件更新失败，请检查路径和权限。"
    exit 1
fi

echo "config.js 配置已更新，生产环境 API 地址设置为 https://$DOMAIN"