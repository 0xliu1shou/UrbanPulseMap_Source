# check.sh

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

echo "开始验证部署状态..."

# 询问用户输入变量
read -p "请输入项目根目录路径 (例如: /home/ubuntu/UrbanPulseMap_Source): " PROJECT_DIR
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录无效或不存在，请检查路径后重新运行脚本。"
    exit 1
fi

FRONTEND_DIR="$PROJECT_DIR/frontend"
BACKEND_DIR="$PROJECT_DIR/backend"

# 1. 检查必要的依赖项是否已安装
echo "检查必要的依赖项..."
REQUIRED_PACKAGES=(
  "nginx"
  "python3.12"
  "python3-venv"
  "python3-pip"
  "certbot"
  "python3-certbot-nginx"
  "nodejs"
  "npm"
  "mongod"
)

for package in "${REQUIRED_PACKAGES[@]}"; do
  if ! command -v $package &>/dev/null; then
    echo "❌ 未检测到依赖项: $package，请确保安装正确。"
  else
    echo "✅ 依赖项已安装: $package"
  fi
done

# 2. 检查 Nginx 服务状态
echo "检查 Nginx 服务状态..."
if systemctl is-active --quiet nginx; then
  echo "✅ Nginx 服务正在运行。"
else
  echo "❌ Nginx 服务未运行，请检查配置。"
fi

if nginx -t &>/dev/null; then
  echo "✅ Nginx 配置语法无误。"
else
  echo "❌ Nginx 配置语法有误，请运行 'nginx -t' 检查错误。"
fi

# 3. 检查 Certbot SSL 证书部署状态
echo "检查 Certbot SSL 证书状态..."
if certbot certificates &>/dev/null; then
  echo "✅ Certbot SSL 证书部署成功。"
else
  echo "❌ Certbot SSL 证书未部署，请检查证书配置。"
fi

# 4. 检查 MongoDB 服务状态
echo "检查 MongoDB 服务状态..."
if systemctl is-active --quiet mongod; then
  echo "✅ MongoDB 服务正在运行。"
else
  echo "❌ MongoDB 服务未运行，请检查服务状态。"
fi

# 验证 MongoDB 文件描述符限制
echo "验证 MongoDB 文件描述符限制..."
MONGO_FD_LIMIT=$(grep -i "nofile" /etc/systemd/system/mongod.service.d/override.conf 2>/dev/null | awk -F= '{print $2}' | xargs)
if [[ "$MONGO_FD_LIMIT" -ge 64000 ]]; then
  echo "✅ MongoDB 文件描述符限制已正确设置为 $MONGO_FD_LIMIT。"
else
  echo "❌ MongoDB 文件描述符限制未正确设置，请检查配置。"
fi

# 5. 验证系统文件描述符限制
echo "验证系统文件描述符限制..."
SOFT_LIMIT=$(ulimit -Sn)
HARD_LIMIT=$(ulimit -Hn)
if [[ "$SOFT_LIMIT" -ge 64000 && "$HARD_LIMIT" -ge 64000 ]]; then
  echo "✅ 系统文件描述符限制已正确设置为 soft=$SOFT_LIMIT, hard=$HARD_LIMIT。"
else
  echo "❌ 系统文件描述符限制设置不正确，当前值为 soft=$SOFT_LIMIT, hard=$HARD_LIMIT。"
  echo "请检查 '/etc/security/limits.conf' 和 '/etc/systemd/system.conf' 的配置。"
fi

# 6. 检查 Python 环境和后端依赖
echo "检查 Python 环境和后端依赖..."
if [ -d "$BACKEND_DIR/env" ]; then
  echo "✅ Python 虚拟环境已创建。"
else
  echo "❌ Python 虚拟环境未创建，请检查后端配置。"
fi

if [ -f "$BACKEND_DIR/requirements.txt" ]; then
  source "$BACKEND_DIR/env/bin/activate"
  pip check &>/dev/null
  if [ $? -eq 0 ]; then
    echo "✅ 后端依赖已正确安装。"
  else
    echo "❌ 后端依赖未正确安装，请运行 'pip install -r requirements.txt'。"
  fi
  deactivate
else
  echo "❌ 后端依赖文件 requirements.txt 不存在，请检查后端配置。"
fi

# 7. 检查前端依赖和构建状态
echo "检查前端依赖和构建状态..."
if [ -d "$FRONTEND_DIR/node_modules" ]; then
  echo "✅ 前端依赖已正确安装。"
else
  echo "❌ 前端依赖未正确安装，请运行 'npm install'。"
fi

if [ -d "$FRONTEND_DIR/dist" ]; then
  echo "✅ 前端已成功构建。"
else
  echo "❌ 前端未成功构建，请运行 'npm run build'。"
fi

# 8. 检查 Nginx 配置文件和日志
echo "检查 Nginx 配置文件和日志..."
NGINX_LOG_DIR="/var/log/nginx"
if [ -d "$NGINX_LOG_DIR" ]; then
  echo "✅ Nginx 日志目录存在: $NGINX_LOG_DIR"
  if [ "$(ls -A $NGINX_LOG_DIR 2>/dev/null)" ]; then
    echo "✅ 检测到 Nginx 日志文件："
    ls -lh "$NGINX_LOG_DIR"
  else
    echo "❌ Nginx 日志目录为空，请检查是否有日志生成。"
  fi
else
  echo "❌ Nginx 日志目录不存在，请检查 Nginx 是否正确安装。"
fi

# 9. 检查系统时区
echo "检查系统时区..."
CURRENT_TIMEZONE=$(timedatectl | grep "Time zone" | awk '{print $3}')
if [ -z "$CURRENT_TIMEZONE" ]; then
  echo "❌ 无法检测到系统时区，请检查系统配置。"
else
  echo "✅ 当前系统时区为: $CURRENT_TIMEZONE"
  # 如果需要，可以添加时区建议或校验逻辑
  RECOMMENDED_TIMEZONE="UTC"
  if [ "$CURRENT_TIMEZONE" != "$RECOMMENDED_TIMEZONE" ]; then
    echo "⚠️ 建议将系统时区设置为 $RECOMMENDED_TIMEZONE。"
    echo "  设置时区命令: sudo timedatectl set-timezone $RECOMMENDED_TIMEZONE"
  fi
fi

# 总结
echo "----------------------------------------"
echo "验证已完成，请根据以上结果检查配置并修复可能存在的问题。"