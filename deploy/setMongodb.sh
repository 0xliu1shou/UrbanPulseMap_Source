# setMongodb.sh

# 设置 MongoDB 服务
echo "配置 MongoDB..."
# 检查是否已经安装 MongoDB
if ! command -v mongod &>/dev/null; then
    echo "MongoDB 未安装，正在安装 MongoDB..."

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

    # 安装 MongoDB
    echo "安装 MongoDB..."
    sudo apt-get install -y mongodb-org
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
    # 提示用户输入多个 IP 地址
    read -p "请输入额外的监听 IP 地址（多个地址用逗号分隔，默认 127.0.0.1）: " CUSTOM_IPS
    CUSTOM_IPS=${CUSTOM_IPS:-127.0.0.1}

    # 验证每个 IP 地址的格式
    for ip in $(echo "$CUSTOM_IPS" | tr ',' ' '); do
        if ! [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "输入的 IP 地址无效: $ip，请检查并重新输入。"
            exit 1
        fi
    done

    # 获取现有的 bindIp 配置
    CURRENT_BIND_IP=$(grep "^  bindIp:" "$MONGODB_CONF" | awk -F: '{print $2}' | xargs)

    # 合并现有配置和用户输入的 IP 地址
    NEW_BIND_IP=$(echo "$CURRENT_BIND_IP,$CUSTOM_IPS" | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')

    echo "更新 MongoDB 配置以监听地址: $NEW_BIND_IP"

    # 备份配置文件
    cp "$MONGODB_CONF" "$MONGODB_CONF.bak"

    # 更新配置文件
    sudo sed -i "s/^  bindIp:.*/  bindIp: $NEW_BIND_IP/" "$MONGODB_CONF"
    if [ $? -ne 0 ]; then
        echo "更新 MongoDB 配置文件失败，请检查权限或配置文件路径。"
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
