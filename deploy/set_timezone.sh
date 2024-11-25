#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 显示可用时区
echo "以下是可用的时区列表："
timedatectl list-timezones

# 提示用户输入时区
read -p "请输入要设置的时区（例如：Asia/Shanghai）： " timezone

# 验证用户输入的时区是否有效
if timedatectl list-timezones | grep -q "^$timezone$"; then
  # 设置时区
  echo "正在设置时区为 $timezone ..."
  timedatectl set-timezone "$timezone"

echo "时区设置完成！请重启服务器！"