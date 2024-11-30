# setFdLimit.sh

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 设置软硬限制
echo "修改 /etc/security/limits.conf 文件..."
cat >> /etc/security/limits.conf <<EOL
* soft nofile 64000
* hard nofile 64000
EOL

# 确保 PAM 加载文件描述符限制
echo "检查 PAM 配置..."
grep -q "pam_limits.so" /etc/pam.d/common-session || echo "session required pam_limits.so" >> /etc/pam.d/common-session
grep -q "pam_limits.so" /etc/pam.d/common-session-noninteractive || echo "session required pam_limits.so" >> /etc/pam.d/common-session-noninteractive

# 修改 systemd 系统级限制
echo "修改 systemd 系统配置..."
sed -i '/DefaultLimitNOFILE/d' /etc/systemd/system.conf
sed -i '/DefaultLimitNOFILE/d' /etc/systemd/user.conf
echo "DefaultLimitNOFILE=64000" >> /etc/systemd/system.conf
echo "DefaultLimitNOFILE=64000" >> /etc/systemd/user.conf

# 如果是 MongoDB 服务，单独设置限制
echo "为 MongoDB 服务设置文件描述符限制..."
sudo mkdir -p /etc/systemd/system/mongod.service.d
cat > /etc/systemd/system/mongod.service.d/override.conf <<EOL
[Service]
LimitNOFILE=64000
EOL

# 重新加载 systemd 配置并重启 MongoDB 服务
echo "重新加载 systemd 配置..."
systemctl daemon-reexec
echo "重启 MongoDB 服务..."
systemctl restart mongod

echo "文件描述符限制已设置完成。请重启服务器！"