import subprocess
import re

# 获取 vnstat 输出
def get_vnstat_output():
    try:
        # 执行 vnstat -m 命令并获取输出
        result = subprocess.run(['vnstat', '-m'], stdout=subprocess.PIPE, text=True)
        return result.stdout
    except Exception as e:
        print(f"无法获取 vnstat 输出: {e}")
        return None

# 从 vnstat 输出中提取 "estimated" 后面的总数据
def extract_total_data(vnstat_output):
    # 正则表达式匹配 "estimated" 后面的总数据
    pattern = r"estimated\s+[\d\.]+\s+MiB\s+\|\s+[\d\.]+\s+MiB\s+\|\s+([\d\.]+)\s+MiB"
    match = re.search(pattern, vnstat_output)
    
    if match:
        return float(match.group(1))  # 提取出总数据值并转换为浮动数字
    return None

# 将提取的总数据写入到文件
def write_to_file(total_data, file_path="/root/jk/jk.txt"):
    try:
        with open(file_path, 'w') as f:
            f.write(f"Total data: {total_data} MiB\n")
        print(f"数据已成功写入到 {file_path}")
    except Exception as e:
        print(f"无法写入文件: {e}")

# 执行关机操作
def shutdown_system():
    try:
        print("总数据超过阈值，正在关机...")
        subprocess.run(['sudo', 'shutdown', '-h', 'now'])
    except Exception as e:
        print(f"关机时发生错误: {e}")

# 主程序
def main():
    vnstat_output = get_vnstat_output()
    
    if vnstat_output:
        total_data = extract_total_data(vnstat_output)
        
        if total_data:
            write_to_file(total_data)  # 写入文件
            
            threshold = 3814697.27  # 设置阈值（MiB）
            print(f"当前总数据: {total_data} MiB")
            
            # 判断是否超过阈值
            if total_data > threshold:
                shutdown_system()  # 超过阈值时关机
            else:
                print(f"当前总数据 {total_data} MiB, 未超过阈值 {threshold} MiB")
        else:
            print("未找到匹配的总数据")
    else:
        print("无法获取 vnstat 输出")

if __name__ == "__main__":
    main()
