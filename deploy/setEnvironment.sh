#!/bin/bash
# setEnvironment.sh

# 请确保以 root 或具有 sudo 权限的用户执行

echo "配置后端与前端服务环境..."

# 检查是否以 root 或 sudo 权限运行
echo "正在检查是否以 root 用户或通过 sudo 执行此脚本..."
if ! sudo -n true 2>/dev/null; then
    echo "请以 root 用户或通过 sudo 执行此脚本。"
    exit 1
fi

# 询问用户输入变量
read -p "请输入项目根目录路径 (例如: /home/ubuntu/UrbanPulseMap_Source): " PROJECT_DIR
if [ -z "$PROJECT_DIR" ] || [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录无效或不存在，请检查路径后重新运行脚本。"
    exit 1
fi

FRONTEND_DIR="$PROJECT_DIR/frontend"
BACKEND_DIR="$PROJECT_DIR/backend"

echo "开始部署环境..."
echo "项目目录: $PROJECT_DIR"

# 检查项目目录是否存在
echo "检查项目目录 $PROJECT_DIR 是否存在..."
if [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录 $PROJECT_DIR 不存在，请检查输入路径"
    exit 1
fi


# 1. 配置后端环境
echo "配置后端环境..."
cd $BACKEND_DIR
python3 -m venv env
source env/bin/activate
pip install -r requirements.txt
deactivate

# 2. 配置前端环境
echo "配置前端环境..."
# 配置前端环境
cd "$FRONTEND_DIR" || { echo "无法进入前端目录 $FRONTEND_DIR，请检查路径。"; exit 1; }
if ! npm install; then
    echo "npm install 失败，请检查网络连接和依赖。"
    exit 1
fi