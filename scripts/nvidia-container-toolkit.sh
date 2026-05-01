#!/bin/bash
set -euo pipefail

# ==================== 配置区 ====================
# GitHub 公益代理 (任选其一，默认ghp.ci)
GH_PROXY="https://ghp.ci/"
# 备选代理：https://ghproxy.net/  https://gh-proxy.com/

# 是否启用中科大镜像兜底 1=启用 0=关闭
USE_USTC_MIRROR=0
# ================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }

# 检查是否root
if [[ $EUID -ne 0 ]]; then
    error "请以 root 或 sudo 执行此脚本"
    exit 1
fi

# 检查系统
if ! grep -Eqi "debian|ubuntu" /etc/os-release; then
    error "仅支持 Debian/Ubuntu 系列系统"
    exit 1
fi

info "开始安装 NVIDIA Container Toolkit 高级版"

# 安装依赖
info "安装基础依赖 curl ca-certificates"
apt update -y
apt install -y curl ca-certificates

# 定义源文件路径
SOURCE_FILE="/etc/apt/sources.list.d/nvidia-container-toolkit.list"
KEYRING="/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg"

# 导入GPG密钥
info "导入 NVIDIA GPG 密钥(通过GitHub代理)"
curl -fsSL "${GH_PROXY}https://nvidia.github.io/libnvidia-container/gpgkey" \
| gpg --dearmor -o "${KEYRING}"

# 写入软件源
info "生成 NVIDIA 软件源配置"
rm -f "${SOURCE_FILE}"

if [ ${USE_USTC_MIRROR} -eq 1 ]; then
    # 使用中科大镜像
    curl -s -L "https://mirrors.ustc.edu.cn/libnvidia-container/stable/deb/nvidia-container-toolkit.list" \
    | sed 's#deb https://nvidia.github.io#deb [signed-by='"${KEYRING}"'] https://mirrors.ustc.edu.cn#g' \
    | tee "${SOURCE_FILE}"
else
    # 使用GitHub代理官方源
    curl -s -L "${GH_PROXY}https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list" \
    | sed 's#deb https://#deb [signed-by='"${KEYRING}"'] '"${GH_PROXY}"'https://#g' \
    | tee "${SOURCE_FILE}"
fi

# 更新缓存并安装
info "更新apt缓存并安装 nvidia-container-toolkit"
apt update -y
apt install -y nvidia-container-toolkit

# 配置Docker Runtime
info "配置 Docker 默认使用 NVIDIA 容器运行时"
nvidia-ctk runtime configure --runtime=docker

# 重启Docker
info "重启 Docker 服务"
systemctl restart docker || service docker restart

# 验证安装
info "安装完成，开始校验环境"
if command -v nvidia-ctk &>/dev/null; then
    GREEN
    echo "============================================="
    echo "✅ NVIDIA Container Toolkit 安装成功"
    echo "版本信息："
    nvidia-ctk --version
    echo ""
    echo "👉 测试GPU容器命令："
    echo "docker run --rm --gpus all nvidia/cuda:latest nvidia-smi"
    echo "============================================="
    NC
else
    error "安装失败，请检查网络或代理地址"
    exit 1
fi