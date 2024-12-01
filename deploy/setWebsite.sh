#!/bin/bash
# setWebsite.sh

# 配置 Nginx 静态网页文件
echo "配置 Nginx 静态网页文件..."

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

echo "开始配置权限并构建静态文件..."
echo "项目目录: $PROJECT_DIR"

# 检查项目目录是否存在
echo "检查项目目录 $PROJECT_DIR 是否存在..."
if [ ! -d "$PROJECT_DIR" ]; then
    echo "项目目录 $PROJECT_DIR 不存在，请检查输入路径"
    exit 1
fi

# 设置父目录和项目目录权限
HOME_DIR=$(dirname "$PROJECT_DIR")

echo "设置 /home/ubuntu 目录的访问权限..."
sudo chmod o+x "$HOME_DIR" && sudo chown "$USER:www-data" "$HOME_DIR" && sudo chmod 750 "$HOME_DIR"
if [ $? -ne 0 ]; then
    echo "设置 /home/ubuntu 的权限失败，请检查权限或路径。"
    exit 1
fi

# 确保 Nginx 和当前用户对项目根目录拥有全部权限
echo "设置项目根目录权限..."
NGINX_USER="www-data"

# 确保项目根目录及子目录对 Nginx 和当前用户开放权限
chown -R "$USER:$NGINX_USER" "$PROJECT_DIR"
chmod -R 775 "$PROJECT_DIR"

# 确认权限设置
if [ $? -eq 0 ]; then
    echo "权限设置完成：$PROJECT_DIR 目录现在对 $USER 和 $NGINX_USER 开放。"
else
    echo "权限设置失败，请检查目录路径和用户配置。"
    exit 1
fi

# 在前端项目目录下执行 npm run build
FRONTEND_DIR="$PROJECT_DIR/frontend"

echo "切换到前端目录: $FRONTEND_DIR"
if [ -d "$FRONTEND_DIR" ]; then
    cd "$FRONTEND_DIR" || { echo "切换到前端目录失败，请检查目录路径。"; exit 1; }
    echo "正在构建前端项目..."
    if npm run build; then
        echo "前端构建完成，静态文件已生成。"
    else
        echo "npm run build 失败，请检查前端代码或配置。"
        exit 1
    fi
else
    echo "前端目录不存在: $FRONTEND_DIR，请检查项目目录路径。"
    exit 1
fi

# 脚本完成
echo "前端服务部署完成！"
echo "----------------------------------------"
echo "请在开始项目前启动后端服务脚本 starter.py 和 app.py"
echo "----------------------------------------"
exit 0
