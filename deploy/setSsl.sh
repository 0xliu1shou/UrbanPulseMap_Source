# setSsl.sh

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 检查并安装必备工具
echo "正在检查并安装必要的工具..."
apt update && apt install -y software-properties-common

# 添加 Certbot 的官方 PPA 并安装 Certbot 和 Nginx 插件
echo "正在安装 Certbot 和 Nginx 插件..."
add-apt-repository -y universe
add-apt-repository -y ppa:certbot/certbot
sudo apt install -y certbot python3-certbot-nginx

# 提示用户输入域名
read -p "请输入您的域名（例如 example.com）: " domain
read -p "请输入您的电子邮件地址（用于 Certbot 注册和通知）: " email

# 检查 Nginx 是否安装
if ! command -v nginx >/dev/null 2>&1; then
  echo "未检测到 Nginx，正在安装 Nginx..."
  apt install -y nginx
  systemctl enable nginx
  systemctl start nginx
fi

# 配置 Nginx 默认站点
nginx_conf="/etc/nginx/sites-available/$domain"
echo "正在配置 Nginx 默认站点..."
cat > "$nginx_conf" <<EOF
server {
    listen 80;
    server_name $domain;

    location / {
        root /var/www/html;
        index index.html;
    }
}
EOF

# 创建符号链接启用站点并重新加载 Nginx
ln -sf "$nginx_conf" /etc/nginx/sites-enabled/
nginx -t && systemctl reload nginx

# 使用 Certbot 获取免费证书
echo "正在为 $domain 部署免费 SSL 证书..."
certbot --nginx --non-interactive --agree-tos -m "$email" -d "$domain"

# 设置证书自动续期
echo "正在设置证书自动续期..."
systemctl enable certbot.timer
systemctl start certbot.timer

# 提示部署完成
echo "免费 SSL 证书已成功部署！请 sudo certbot certificates 检查。"