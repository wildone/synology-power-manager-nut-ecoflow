#!/usr/bin/python

import json
import subprocess
import re

if __name__ == '__main__':
    print("Content-type: application/json\n")
    
    # 配置环境
    command = ["/usr/local/bin/spm-exec", "sh", "./x86_64-pc-linux-gnu-nut-server/script/setup_env.sh"]
    subprocess.run(command, shell=False, capture_output=True, text=True, cwd="../../usr/local/bin/nas")

    # sudo命令，使用-S选项读取密码
    command = ["/usr/local/bin/spm-exec", "./x86_64-pc-linux-gnu-nut-server/bin/nut-scanner", "-U"]

    # 执行命令，捕获输出
    result = subprocess.run(command, shell=False, capture_output=True, text=True, cwd="../../usr/local/bin/nas")

    # 获取标准输出和标准错误的合并结果
    run_output = (result.stdout or "") + "\n" + (result.stderr or "")

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
        'res': True,
    }

    # 使用正则表达式匹配所有以 [ 开头并以 ] 结尾的部分
    matches = re.findall(r'\[.*?\]', run_output)
    # 判断设备数量
    if len(matches) != 1:
        output['res'] = False

    # 更新状态
    if output['res_code'] != 0 or not output['res']:
        pkg_state['findDeviceState'] = 'fail'
        pkg_state['state'] = 'hasFail'
    else:
        pkg_state['findDeviceState'] = 'success'
        pkg_state['state'] = 'starting'

    # 保存状态
    with open('../../usr/local/bin/nas/pkg_state.json', 'w') as json_file:
        json_file.write(json.dumps(pkg_state, indent=4))

    print(json.dumps(output, indent=4))
