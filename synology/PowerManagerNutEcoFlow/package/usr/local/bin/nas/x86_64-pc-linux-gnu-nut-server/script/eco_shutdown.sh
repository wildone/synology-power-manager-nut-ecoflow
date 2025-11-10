#!/bin/bash

# 群晖NAS虚拟机管理脚本（使用virsh）
# 功能：先正常关闭所有运行中的虚拟机，若仍有未关闭的则强制关机
# 使用方法：sudo ./vm_shutdown_virsh.sh

# 执行NAS关机
poweroff_nas() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 正在写入日志..."
    # 覆盖写入ps命令的完整输出
    ps -aux > /usr/local/bin/eco_shutdown.log
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 正在准备关闭NAS系统..."
    if /sbin/shutdown -h +0; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 关机指令已发送"
        exit 0
    else
        echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] 错误：执行关机命令失败"
        exit 1
    fi
}

# 检查是否为root或sudo运行
check_sudo() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "错误：此脚本必须使用sudo或root权限运行" >&2
        poweroff_nas
        exit 1
    fi
}

# 检查virsh命令是否存在
check_virsh() {
    if ! command -v virsh &> /dev/null; then
        echo "错误：未找到virsh命令，请确保libvirt已安装"
        poweroff_nas
        exit 1
    fi
}

# 获取所有运行中的虚拟机ID和名称
get_running_vms() {
    virsh list --state-running --name | awk 'NF && $1 !~ /^$/ {print $1}'
}

# 正常关闭虚拟机
graceful_shutdown() {
    local vm_id=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 正在正常关闭虚拟机 $vm_id..."
    virsh shutdown "$vm_id"
    
    # 等待虚拟机优雅关闭（最多10秒）
    local timeout=10
    while [ $timeout -gt 0 ]; do
        if ! virsh list --state-running --name | grep -q "^${vm_id}$"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 虚拟机 $vm_id 已正常关闭"
            return 0
        fi
        sleep 1
        ((timeout--))
    done
    
    return 1
}

# 强制关闭虚拟机
force_shutdown() {
    local vm_id=$1
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 正在强制关闭虚拟机 $vm_id..."
    virsh destroy "$vm_id"
    sleep 2  # 短暂等待确保操作完成
}

# 主执行流程
main() {
    # 日志目录和文件名
    LOG_DIR="/var/packages/PowerManagerNutEcoFlow/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/log"
    LOG_FILE="$LOG_DIR/$(date '+%Y-%m-%d').log"

    # 创建目录（若不存在）
    mkdir -p "$LOG_DIR"

    # 将所有输出（stdout 和 stderr）追加到日志文件
    exec >> "$LOG_FILE" 2>&1

    # 获取 ups.status 的值
    status=$(/var/packages/PowerManagerNutEcoFlow/target/usr/local/bin/nas/x86_64-pc-linux-gnu-nut-server/bin/upsc ups@localhost:3493 ups.status 2>/dev/null)

    # 如果获取成功 且 状态包含 OL 或 CHRG，则退出
    if [[ -n "$status" ]] && echo "$status" | grep -qE '\bOL\b|\bCHRG\b'; then
        exit 0
    fi

    check_sudo

    check_virsh

    # 第一阶段：获取并正常关闭所有虚拟机
    running_vms=$(get_running_vms)
    
    if [ -z "$running_vms" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 当前没有运行中的虚拟机"
        poweroff_nas
        exit 0
    fi

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 检测到运行中的虚拟机:"
    echo "$running_vms" | while read -r vm; do echo "  - $vm"; done
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始正常关机流程..."
    
    for vm_id in $running_vms; do
        if ! graceful_shutdown "$vm_id"; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告：虚拟机 $vm_id 正常关闭超时"
        fi
    done

    # 第二阶段：检查并强制关闭剩余虚拟机
    remaining_vms=$(get_running_vms)
    
    if [ -n "$remaining_vms" ]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 以下虚拟机未正常关闭:"
        echo "$remaining_vms" | while read -r vm; do echo "  - $vm"; done
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始强制关机..."
        
        for vm_id in $remaining_vms; do
            force_shutdown "$vm_id"
        done

        # 最终确认
        still_running=$(get_running_vms)
        if [ -n "$still_running" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 警告：以下虚拟机仍处于运行状态:"
            echo "$still_running" | while read -r vm; do echo "  - $vm"; done
            poweroff_nas
            exit 1
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 所有虚拟机已成功强制关闭"
        fi
    else
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 所有虚拟机已正常关闭"
    fi

    poweroff_nas
}

main
