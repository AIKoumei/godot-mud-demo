import datetime

# 获取当前系统时间，格式为yyyy-MM-dd HH:mm:ss
current_time = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
print(current_time)