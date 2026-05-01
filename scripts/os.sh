#!/bin/bash

# ==================== 系统镜像下载脚本 os.sh ====================
# 功能：选择 Ubuntu / Debian / CentOS → 选版本 → 自动下载
# 依赖：curl wget dialog（脚本会自动安装）
# ===============================================================

# 设置语言环境避免乱码
export LANG=C LC_ALL=C

# 国内镜像源（阿里云，速度最快）
MIRROR="https://mirrors.aliyun.com"

# 检查依赖
check_deps() {
    local MISSING=""
    for cmd in dialog wget curl; do
        if ! command -v "$cmd" &> /dev/null; then
            MISSING="$MISSING $cmd"
        fi
    done

    if [ -n "$MISSING" ]; then
        echo "正在安装依赖工具$MISSING..."
        if [ -f /etc/debian_version ]; then
            apt update >/dev/null 2>&1
            apt install -y$MISSING >/dev/null 2>&1
        elif [ -f /etc/redhat-release ]; then
            yum install -y$MISSING >/dev/null 2>&1
        fi
    fi
}

# 下载函数
download_iso() {
    local NAME="$1"
    local URL="$2"
    local FILE=$(basename "$URL")

    clear
    echo "============================================="
    echo "  开始下载：$NAME"
    echo "  保存为：$FILE"
    echo "============================================="

    if ! wget -c --show-progress "$URL" -O "$FILE"; then
        echo -e "\n[错误] 下载失败，请检查网络或镜像地址"
        rm -f "$FILE"
        read -p "按回车返回主菜单"
        return 1
    fi

    if [ -f "$FILE" ] && [ -s "$FILE" ]; then
        echo -e "\n[成功] 下载完成：$FILE"
    else
        echo -e "\n[错误] 下载文件异常"
        rm -f "$FILE"
        read -p "按回车返回主菜单"
        return 1
    fi
    read -p "按回车返回主菜单"
}

# Ubuntu 版本选择
ubuntu_menu() {
    clear
    echo "===== Ubuntu 镜像下载 ====="
    echo "1) Ubuntu 22.04 LTS (推荐)"
    echo "2) Ubuntu 20.04 LTS"
    echo "3) Ubuntu 18.04 LTS"
    echo "0) 返回"
    read -p "请选择版本：" ub_ver

    case $ub_ver in
        1) download_iso "Ubuntu 22.04" "${MIRROR}/ubuntu-releases/22.04/ubuntu-22.04.4-live-server-amd64.iso" ;;
        2) download_iso "Ubuntu 20.04" "${MIRROR}/ubuntu-releases/20.04/ubuntu-20.04.6-live-server-amd64.iso" ;;
        3) download_iso "Ubuntu 18.04" "${MIRROR}/ubuntu-releases/18.04/ubuntu-18.04.6-live-server-amd64.iso" ;;
        0) return ;;
        *) echo "无效选项！" && sleep 1 ;;
    esac
}

# Debian 版本选择
debian_menu() {
    clear
    echo "===== Debian 镜像下载 ====="
    echo "1) Debian 12 (推荐)"
    echo "2) Debian 11"
    echo "3) Debian 10"
    echo "0) 返回"
    read -p "请选择版本：" de_ver

    case $de_ver in
        1) download_iso "Debian 12" "${MIRROR}/debian-cd/current/amd64/iso-cd/debian-12.7.0-amd64-netinst.iso" ;;
        2) download_iso "Debian 11" "${MIRROR}/debian-cd/11.9.0/amd64/iso-cd/debian-11.9.0-amd64-netinst.iso" ;;
        3) download_iso "Debian 10" "${MIRROR}/debian-cd/10.13.0/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso" ;;
        0) return ;;
        *) echo "无效选项！" && sleep 1 ;;
    esac
}

# CentOS 版本选择
centos_menu() {
    clear
    echo "===== CentOS 镜像下载 ====="
    echo "1) CentOS 7 (最后稳定版)"
    echo "2) CentOS Stream 9"
    echo "0) 返回"
    read -p "请选择版本：" ce_ver

    case $ce_ver in
        1) download_iso "CentOS 7" "${MIRROR}/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso" ;;
        2) download_iso "CentOS Stream 9" "${MIRROR}/centos-stream/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso" ;;
        0) return ;;
        *) echo "无效选项！" && sleep 1 ;;
    esac
}

# 主菜单
main() {
    check_deps
    while true; do
        clear
        echo "============================================="
        echo "           系统镜像下载工具 os.sh"
        echo "============================================="
        echo " 1) Ubuntu"
        echo " 2) Debian"
        echo " 3) CentOS"
        echo " 0) 退出"
        echo "============================================="
        read -p "请选择要下载的系统：" os

        case $os in
            1) ubuntu_menu ;;
            2) debian_menu ;;
            3) centos_menu ;;
            0) echo "退出脚本" && exit 0 ;;
            *) echo "无效选项！" && sleep 1 ;;
        esac
    done
}

# 启动
main
