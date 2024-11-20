#!/bin/bash

# 更新系统
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# 安装必要的软件包
echo "安装vnstat和crontab..."
sudo apt install -y vnstat cron

# 启动vnstat服务
echo "启动vnstat服务..."
sudo systemctl enable vnstat
sudo systemctl start vnstat

# 配置vnstat获取接口
echo "配置vnstat，选择网络接口..."
# 替换为你的网卡名称（通常是eth0，wlan0等，可以用ifconfig查看）
INTERFACE="eth0" 
sudo vnstat -u -i $INTERFACE

# 创建脚本来检查流量并关机
echo "创建流量监控脚本..."
cat > /usr/local/bin/check_traffic.sh << 'EOF'
#!/bin/bash

# 获取当前月份的总流量（单位：MB）
total_usage=$(vnstat -i eth0 -m | grep "$(date +'%b')" | awk '{print $2}' | sed 's/[^0-9]*//g')

# 将5TB转换为MB (5TB = 5000GB = 5000000MB)
threshold=5000000

# 判断流量是否超过流量阈值
if [ "$total_usage" -ge "$threshold" ]; then
    echo "总流量已超过5TB，系统即将关机！"
    sudo shutdown -h now
else
    echo "当前总流量：$total_usage MB，未超过5TB"
fi
EOF

# 赋予脚本执行权限
sudo chmod +x /usr/local/bin/check_traffic.sh

# 设置定时任务，每小时执行一次脚本
echo "配置定时任务，每小时检查一次流量..."
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/check_traffic.sh") | crontab -

# 每月1号重置vnstat的流量统计
echo "配置每月1号重置流量统计..."
(crontab -l 2>/dev/null; echo "0 0 1 * * vnstat -r") | crontab -

# 输出安装完成信息
echo "安装完成！系统已配置好流量监控，并且会每小时检查流量是否超过5TB。"
