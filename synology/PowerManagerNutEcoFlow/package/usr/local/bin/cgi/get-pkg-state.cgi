#!/usr/bin/python

import json
import subprocess

if __name__ == '__main__':
    print("Content-type: application/json\n")

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
        'pkg_state': pkg_state,
    }

    print(json.dumps(output, indent=4))
