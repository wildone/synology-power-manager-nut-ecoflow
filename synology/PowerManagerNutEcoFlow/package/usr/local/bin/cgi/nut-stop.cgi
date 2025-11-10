#!/usr/bin/python

import json
import subprocess
import logging
from logging.handlers import TimedRotatingFileHandler
import os
from datetime import datetime

# 创建日志文件夹，如果不存在的话
log_dir = "../../usr/local/bin/nas/log"
if not os.path.exists(log_dir):
    os.makedirs(log_dir)

# 创建日志记录器
logger = logging.getLogger("MyLogger")
logger.setLevel(logging.INFO)

# 获取当前日期
date_str = datetime.now().strftime("%Y-%m-%d")
# 构建日志文件路径
log_file = os.path.join(log_dir, f"{date_str}.log")
handler = TimedRotatingFileHandler(log_file, when="midnight", interval=1, backupCount=7)
handler.suffix = "%Y-%m-%d.log"  # 设置文件后缀为日期

# 设置日志格式
formatter = logging.Formatter('%(asctime)s - %(message)s')
handler.setFormatter(formatter)

# 将 handler 加入到 logger
logger.addHandler(handler)

# 每次写入日志时，可以加上一些自定义的标记，增加日志的可辨识度
def write_log(message):
    logger.info(f"\n{message}")

if __name__ == '__main__':
    print("Content-type: application/json\n")

    # sudo命令，使用-S选项读取密码
    command = ["/usr/local/bin/spm-exec", "pkill", "ups"]

    # 执行命令
    subprocess.run(command, shell=False, capture_output=True, text=True)
    command = ["ps aux | grep ups"]
    # 执行命令，捕获输出
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    # 获取标准输出和标准错误的合并结果
    run_output = (result.stdout or "") + "\n" + (result.stderr or "")
    write_log(run_output)

    # 获取状态
    pkg_state = {
        "findDeviceState": "",
        "permissionState": "",
        "state": "start"
    }
    with open('../../usr/local/bin/nas/pkg_state.json', 'r') as json_file:
        pkg_state = json.load(json_file)

    output = {
        'res_code': 0,
        'res_msg': run_output,
    }

    # 更新状态
    if output['res_code'] == 0:
        pkg_state['state'] = 'start'
        pkg_state['findDeviceState'] = ''
        pkg_state['permissionState'] = ''
    else:
        pkg_state['state'] = 'bootSuccess'

    # 保存状态
    with open('../../usr/local/bin/nas/pkg_state.json', 'w') as json_file:
        json_file.write(json.dumps(pkg_state, indent=4))

    print(json.dumps(output, indent=4))
