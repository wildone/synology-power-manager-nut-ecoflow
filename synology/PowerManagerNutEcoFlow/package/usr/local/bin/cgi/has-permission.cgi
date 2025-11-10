#!/usr/bin/python

import json
import subprocess

if __name__ == '__main__':
    print("Content-type: application/json\n")

    output = {
        'res_code': 0,
        'has_permission': True,
    }

    # 获取状态
    pkg_state = {
        "findDeviceState": "",
        "permissionState": "",
        "state": "start"
    }
    with open('../../usr/local/bin/nas/pkg_state.json', 'r') as json_file:
        # 处理文件内容
        data = json.load(json_file)

    # 无需实际进行权限判断，因为若无权限，请求该 CGI 会得到 403 Forbidden 错误

    # 更新状态
    if output['res_code'] != 0 or not output['has_permission']:
        pkg_state['permissionState'] = 'fail'
        pkg_state['state'] = 'hasFail'
    else:
        pkg_state['permissionState'] = 'success'
        pkg_state['state'] = 'starting'

    # 保存状态
    with open('../../usr/local/bin/nas/pkg_state.json', 'w') as json_file:
        json_file.write(json.dumps(pkg_state, indent=4))

    print(json.dumps(output, indent=4))
