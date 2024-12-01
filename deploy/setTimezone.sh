#!/bin/bash
# setTimezone.sh

# 检查是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "请以 root 权限运行此脚本。"
  exit 1
fi

# 提示用户输入时区
current_timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
echo "当前系统时区为：$current_timezone"

# 提供用户选择当前时区或手动输入
read -p "是否使用推荐时区 $current_timezone? (y/n): " use_current
if [[ "$use_current" == "y" ]]; then
    timezone=$current_timezone
else
    while true; do
        read -p "请输入要设置的时区（例如：Asia/Shanghai）： " timezone
        # 验证输入的时区是否有效
        if timedatectl list-timezones | grep -q "^$timezone$"; then
            break
        else
            echo "输入的时区无效，请确保时区名称正确。"
            echo "提示：可以运行 'timedatectl list-timezones' 查看所有有效时区。"
        fi
    done
fi

# 设置时区
echo "正在设置时区为 $timezone ..."
if timedatectl set-timezone "$timezone"; then
    echo "时区设置完成！请重启服务器。"
else
    echo "设置时区失败，请检查权限或系统配置。"
    exit 1
fi