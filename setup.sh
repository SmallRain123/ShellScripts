#!/bin/bash

# ==============================================
# 【环境变量 / 配置区】
# ==============================================
export GITHUB_USER="smallrain123"           # GitHub 用户名
export GITHUB_REPO="ShellScripts"           # 仓库名
export GITHUB_BRANCH="master"              # 分支
export SCRIPT_DIR="scripts"                   # 仓库内脚本目录（空则表示根目录）
export LOG_FILE="/tmp/script_run.log"      # 日志临时文件
# ==============================================

# 拼接 Raw 地址前缀（自动处理目录）
if [ -n "$SCRIPT_DIR" ]; then
    export RAW_PREFIX="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}/${SCRIPT_DIR}"
else
    export RAW_PREFIX="https://raw.githubusercontent.com/${GITHUB_USER}/${GITHUB_REPO}/${GITHUB_BRANCH}"
fi

# 检查依赖：dialog + curl
check_deps() {
    if ! command -v dialog &> /dev/null || ! command -v curl &> /dev/null; then
        echo "正在安装依赖 dialog curl ..."
        if [ -f /etc/debian_version ]; then
            apt update >/dev/null 2>&1
            apt install -y dialog curl >/dev/null 2>&1
        elif [ -f /etc/redhat-release ]; then
            yum install -y dialog curl >/dev/null 2>&1
        fi
    fi
}

# ====================== 修复：零报错 + 终端/Dialog 双重输出 ======================
run_script() {
    local script_name="$1"
    local script_url="${RAW_PREFIX}/${script_name}"

    # 初始化日志文件，避免空文件报错
    echo "=====================================" > "$LOG_FILE"
    echo "  开始执行：$script_name" >> "$LOG_FILE"
    echo "=====================================" >> "$LOG_FILE"

    dialog --title "执行中" --infobox "正在加载脚本：\n${script_name}\n\n即将打开日志窗口..." 8 60
    sleep 0.8

    # 核心：脚本输出同时写入日志 + 输出到终端
    (
        echo "[$(date +%H:%M:%S)] 开始执行：$script_name"
        curl -sSL --connect-timeout 15 "$script_url" 2>&1 | bash 2>&1
        echo -e "\n[$(date +%H:%M:%S)] 执行完成：$script_name"
        echo "====================================="
    ) 2>&1 | tee -a "$LOG_FILE" &
    local exec_pid=$!

    # 关键修复：从第一行读取 + 屏蔽错误，彻底解决 Cannot seek to end of file
    tail -n +1 -f "$LOG_FILE" 2>/dev/null | dialog --title "实时执行日志：${script_name}" --textbox /dev/stdin 24 90

    wait "$exec_pid" 2>/dev/null || true

    dialog --title "执行完成" --msgbox "✅ 脚本 ${script_name} 运行完毕！\n日志已保存到：$LOG_FILE" 7 60
}
# ====================================================================================

# 查看历史日志功能
view_log() {
    if [ ! -f "$LOG_FILE" ]; then
        dialog --title "提示" --msgbox "暂无日志文件，请先执行脚本！" 6 50
        return
    fi

    dialog --title "📋 历史执行日志 /tmp/script_run.log" --textbox "$LOG_FILE" 24 90
}

# 自定义输入脚本名
input_script() {
    local name
    name=$(dialog --inputbox "请输入仓库中的脚本文件名（例：test.sh）" 10 50 3>&1 1>&2 2>&3)
    if [ -n "$name" ]; then
        run_script "$name"
    fi
}

# 主菜单（优化版：带工具介绍 + 使用说明）
main_menu() {
    while true; do
        CHOICE=$(dialog --title "ShellScripts 在线执行工具 v1.0" \
        --no-shadow \
        --colors \
        --menu "
\Z4=============================================\Z0
\Z1   🚀 ShellScripts 在线执行工具\Z0
\Z4=============================================\Z0
\Z4 【工具介绍】\Z0
	- 这是一个基于ShellScripts 的在线脚本执行工具
	- 可直接从 GitHub 仓库拉取并运行 Shell 脚本
	- 支持实时日志查看和历史记录回放
\Z4 【使用说明】\Z0
	- 使用 ↑↓ 方向键选择选项
	- 按 Enter 确认执行
	- 按 ESC 或 q 退出日志窗口
	- 日志自动保存至：/tmp/script_run.log
\Z4=============================================\Z0
请选择要执行的操作：
" 30 75 12 \
        1 "🐳 安装 Docker 环境 (docker + docker-compose)" \
        2 "🎮 安装 NVIDIA 显卡驱动" \
        3 "📦 安装 NVIDIA Container Toolkit" \
        4 "⚙️ 运行 init.sh 初始化脚本" \
        5 "🐧 下载系统镜像" \
        6 "📝 自定义脚本名执行" \
        7 "📋 查看历史执行日志" \
        8 "🧹 清空日志文件" \
        q "🚪 退出工具" \
        3>&1 1>&2 2>&3)

        case "$CHOICE" in
            1) run_script "get-docker.sh" ;;
            2) run_script "nvidia-gpu-setup.sh" ;;
            3) run_script "nvidia-container-toolkit.sh" ;;
            4) run_script "os.sh";;
            5) run_script "init.sh" ;;
            6) input_script ;;
            7) view_log ;;
            8) 
                dialog --title "确认" --yesno "确定要清空日志文件吗？\n日志路径：/tmp/script_run.log" 7 50
                if [ $? -eq 0 ]; then
                    rm -f "$LOG_FILE"
                    dialog --msgbox "✅ 日志文件已清空！" 5 30
                fi
                ;;
            q) break ;;
            *) dialog --msgbox "无效选项，请重新选择" 5 30 ;;
        esac
    done
}

# 入口
clear
check_deps
main_menu
clear
rm -f "$LOG_FILE"
echo -e "\n✅ 已退出脚本工具\n"
