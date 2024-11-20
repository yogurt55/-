#!/bin/bash

# 定义流量阈值：4TB = 4 * 1024 * 1024 * 1024 MB
THRESHOLD=$((4 * 1024 * 1024 * 1024))  # 4TB in MB

# 获取所有活动的网卡（忽略回环接口）
INTERFACE=$(ip -o link show | grep -v lo | awk -F': ' '{print $2}')

# 获取当前流量：使用vnstat或ifstat
# 确保系统已安装 vnstat
# 获取指定网卡的已用流量（单位为字节）
CURRENT_USAGE=$(vnstat -i $INTERFACE --json | jq '.interfaces[0].traffic.total.rx.bytes + .interfaces[0].traffic.total.tx.bytes')

# 如果没有安装 vnstat, 可以使用 ifstat 作为替代
# CURRENT_USAGE=$(ifstat -i $INTERFACE 1 1 | tail -n 1 | awk '{print $1 + $2}')

# 检查流量是否超过阈值
if [ $CURRENT_USAGE -gt $THRESHOLD ]; then
    echo "流量超过 4TB, 正在关闭服务器..."
    sudo shutdown -h now
else
    echo "当前流量：$CURRENT_USAGE 字节，未超过阈值，继续运行..."
fi
