#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
echo "安装vnstat和cron..."
sudo apt install -y vnstat cron

# 动态检测网卡名称
echo "检测网络接口..."
INTERFACE=$(ip route | grep default | awk '{print $5}')
if [ -z "$INTERFACE" ]; then
    echo "未找到有效的网络接口，请手动设置！"
    exit 1
fi
echo "检测到网络接口：$INTERFACE"

# 启动vnstat服务
echo "启动vnstat服务..."
sudo systemctl enable vnstat
sudo systemctl start vnstat

# 配置vnstat获取接口
echo "配置vnstat，初始化网络接口 $INTERFACE..."
sudo vnstat --create -i $INTERFACE 2>/dev/null
sudo systemctl restart vnstat

# 创建流量监控脚本
echo "创建流量监控脚本..."
cat > /usr/local/bin/check_traffic.sh << EOF
#!/bin/bash

# 动态检测网络接口
INTERFACE=\$(ip route | grep default | awk '{print \$5}')

# 获取当前月份的总流量（单位：MB）
total_usage=\$(vnstat -i \$INTERFACE -m | grep "\$(date +'%b')" | awk '{print \$2}' | sed 's/[^0-9]*//g')

# 如果获取的流量为空，则记录错误日志
if [ -z "\$total_usage" ]; then
    echo "\$(date): 无法获取流量数据，请检查vnstat配置或接口名称！" >> /var/log/traffic_monitor.log
    exit 1
fi

# 将5TB转换为MB (5TB = 5000GB = 5000000MB)
threshold=5000000

# 判断流量是否超过流量阈值
if [ "\$total_usage" -ge "\$threshold" ]; then
    echo "\$(date): 总流量已超过5TB，系统即将关机！" >> /var/log/traffic_monitor.log
    sudo shutdown -h now
else
    echo "\$(date): 当前总流量：\$total_usage MB，未超过5TB" >> /var/log/traffic_monitor.log
fi
EOF

# 赋予脚本执行权限
sudo chmod +x /usr/local/bin/check_traffic.sh

# 设置定时任务，每小时执行一次脚本
echo "配置定时任务，每小时检查一次流量..."
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/check_traffic.sh") | crontab -

# 每月1号重置vnstat的流量统计
echo "配置每月1号重置流量统计..."
(crontab -l 2>/dev/null; echo "0 0 1 * * vnstat --reset -i $INTERFACE") | crontab -

# 输出安装完成信息
echo "安装完成！系统已配置好流量监控，并且会每小时检查流量是否超过5TB。"
