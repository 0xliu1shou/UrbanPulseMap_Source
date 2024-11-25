#!/bin/bash

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 提示用户输入时区
read -p "请输入要设置的时区（例如：Asia/Shanghai）： " timezone

# 验证用户输入的时区是否有效
if timedatectl list-timezones | grep -q "^$timezone$"; then
  # 设置时区
  echo "正在设置时区为 $timezone ..."
  timedatectl set-timezone "$timezone"
  echo "时区设置完成！请重启服务器"
else
  echo "输入的时区无效，请重新运行脚本并输入正确的时区。"
  exit 1
fi