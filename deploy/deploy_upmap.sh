#!/bin/bash

# 项目部署脚本
# 请确保以 root 或具有 sudo 权限的用户执行

echo "欢迎使用项目部署脚本！"

# 日志记录
LOG_FILE="/var/log/project_deploy.log"
if [ ! -w "$LOG_FILE" ]; then
    if ! sudo touch "$LOG_FILE" || ! sudo chmod 644 "$LOG_FILE"; then
        echo "无法创建或修改日志文件 $LOG_FILE，请检查权限。"
        exit 1
    fi
fi
exec > >(tee -i "$LOG_FILE") 2> >(tee -i "$LOG_FILE" >&2)

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

echo "开始部署项目..."
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

# 1. 更新系统并安装必要软件
echo "更新系统并安装必要的软件..."
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y python3.12 python3-venv python3-pip nodejs npm mongodb-org-shell screen

# 2. 设置 MongoDB 服务
echo "配置 MongoDB..."
# 检查是否已经安装 MongoDB
if ! command -v mongod &>/dev/null; then
    echo "MongoDB 未安装，正在安装 MongoDB..."

    # 确保 apt 已更新
    echo "更新系统软件包索引..."
    sudo apt update -y

    # 添加 MongoDB 官方密钥
    echo "添加 MongoDB 官方 GPG 密钥..."
    wget -qO - https://pgp.mongodb.com/server-6.0.asc | sudo gpg --dearmor -o /usr/share/keyrings/mongodb-org-6.0.gpg
    if [ $? -ne 0 ]; then
        echo "添加 MongoDB 官方密钥失败，请检查网络连接。"
        exit 1
    fi
    # 添加 MongoDB 官方仓库
    echo "添加 MongoDB 官方软件源..."
    OS_VERSION="jammy"  # 替换为适合您的版本（如 jammy 对应 Ubuntu 22.04）
    echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-org-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $OS_VERSION/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

    # 更新软件包索引
    sudo apt-get update

    # 安装 MongoDB
    echo "安装 MongoDB..."
    sudo apt install -y mongodb-org
    if [ $? -ne 0 ]; then
        echo "MongoDB 安装失败，请检查软件源配置或网络连接。"
        exit 1
    fi

    # 检查安装结果
    if ! command -v mongod &>/dev/null; then
        echo "MongoDB 安装失败，请检查网络连接或安装过程。"
        exit 1
    fi
fi
# 启用并启动 MongoDB 服务
sudo systemctl enable mongod
sudo systemctl start mongod
# 检查 MongoDB 配置文件
MONGODB_CONF="/etc/mongod.conf"
if [ ! -f "$MONGODB_CONF" ]; then
    echo "MongoDB 配置文件 $MONGODB_CONF 不存在，请检查 MongoDB 是否正确安装。"
    exit 1
fi
# 询问用户是否需要自定义监听 IP
read -p "是否需要自定义 MongoDB 监听地址 (y/n)? " CUSTOM_BIND_IP
if [[ "$CUSTOM_BIND_IP" =~ ^[yY]$ ]]; then
    read -p "请输入额外的监听 IP 地址 (例如: 内网 IP 10.0.0.1): " CUSTOM_IP
    if [[ "$CUSTOM_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "更新 MongoDB 配置以监听地址 127.0.0.1 和 $CUSTOM_IP"
        sudo sed -i "s/^  bindIp:.*/  bindIp: 127.0.0.1,$CUSTOM_IP/" "$MONGODB_CONF"
    else
        echo "输入的 IP 地址无效，请检查并重新输入。"
        exit 1
    fi
else
    echo "保持默认 MongoDB 监听地址 127.0.0.1"
fi
# 重启 MongoDB 服务
sudo systemctl enable mongod
sudo systemctl restart mongod
# 检查 MongoDB 服务状态
echo "检查 MongoDB 服务状态..."
sudo systemctl status mongod --no-pager

# 3. 配置后端环境
echo "配置后端环境..."
cd $BACKEND_DIR
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
deactivate

# 4. 配置前端环境
echo "配置前端环境..."
# 配置前端环境
cd "$FRONTEND_DIR" || { echo "无法进入前端目录 $FRONTEND_DIR，请检查路径。"; exit 1; }
if ! npm install; then
    echo "npm install 失败，请检查网络连接和依赖。"
    exit 1
fi

# 5. 设置 vite.config.js 配置
echo "配置 Vite 服务..."
if [ ! -d "$FRONTEND_DIR" ]; then
    echo "前端目录 $FRONTEND_DIR 不存在，请检查路径配置。"
    exit 1
fi
VITE_CONFIG="$FRONTEND_DIR/vite.config.js"
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


# 6. 设置 Nginx 配置
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

# 7. 配置 Nginx 静态网页文件
echo "配置 Nginx 静态网页文件..."
# 创建 Nginx 静态网页文件
if npm run build; then
    echo "前端构建完成，静态文件已生成。"
else
    echo "npm run build 失败，请检查前端代码或配置。"
    exit 1
fi


# 脚本完成
echo "项目部署完成！"
echo "----------------------------------------"
echo "后端服务: 已配置完成，监听端口 $BACKEND_PORT"
echo "MongoDB: 已配置完成，监听端口 $MONGO_PORT"
echo "请开启后端服务 scheduler 和 api"
echo "前端页面: 请访问 https://$DOMAIN 确认服务是否正常运行。"
echo "----------------------------------------"
exit 0
