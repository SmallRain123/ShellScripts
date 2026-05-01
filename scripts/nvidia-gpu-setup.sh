#!/bin/bash
set -euo pipefail

# ===================== 配置区 =====================
# 可选：指定驱动版本，留空自动安装推荐版本
NVIDIA_DRIVER_VERSION=""
# 是否锁定内核防止更新翻车 1=开启 0=关闭
LOCK_KERNEL=1
# ==================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "\n${GREEN}[INFO] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARN] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; exit 1; }

# 权限校验
if [[ $EUID -ne 0 ]]; then
    error "必须使用 sudo / root 执行本脚本"
fi

# 系统校验
if ! grep -Eqi "ubuntu|debian" /etc/os-release; then
    error "仅支持 Ubuntu / Debian 系列"
fi

info "开始前置环境准备"

# 1. 更新源 & 安装依赖
apt update -y
apt install -y build-essential gcc make linux-headers-$(uname -r)

# 2. 禁用 Nouveau 显卡冲突驱动
info "正在禁用 Nouveau 开源驱动（解决显卡冲突）"
cat > /etc/modprobe.d/blacklist-nouveau.conf <<EOF
blacklist nouveau
options nouveau modeset=0
EOF

# 3. 屏蔽其他开源显卡驱动
cat > /etc/modprobe.d/blacklist-amd-nouveau.conf <<EOF
blacklist radeon
blacklist amdgpu
blacklist nouveau
EOF

# 4. 更新内核镜像
update-initramfs -u

# 5. 卸载残留旧驱动
info "清理旧版NVIDIA驱动残留"
apt remove -y --purge nvidia-* 2>/dev/null || true
apt autoremove -y

# 6. 启用 Ubuntu 专有驱动源
info "启用 restricted 专有驱动仓库"
sed -i 's/main/main restricted universe multiverse/' /etc/apt/sources.list
apt update -y

# 7. 安装 NVIDIA 驱动
if [ -z "${NVIDIA_DRIVER_VERSION}" ]; then
    info "自动检测并安装系统推荐驱动版本"
    ubuntu-drivers autoinstall
else
    info "指定安装驱动版本: ${NVIDIA_DRIVER_VERSION}"
    apt install -y nvidia-driver-${NVIDIA_DRIVER_VERSION}
fi

# 8. 禁用 Wayland 避免桌面冲突
info "禁用 Wayland，强制使用 Xorg"
if [ -f /etc/gdm3/custom.conf ]; then
    sed -i 's/#WaylandEnable=false/WaylandEnable=false/' /etc/gdm3/custom.conf
fi

# 9. 锁定内核防止自动更新崩坏驱动
if [ ${LOCK_KERNEL} -eq 1 ]; then
    info "锁定内核版本，防止自动更新导致驱动失效"
    apt-mark hold linux-image-$(uname -r) linux-headers-$(uname -r)
fi

# 10. 完成提示
echo -e "\n============================================="
echo -e "${GREEN}✅ NVIDIA 驱动安装配置完成${NC}"
echo -e "✅ 已永久禁用 Nouveau 显卡冲突驱动"
echo -e "✅ 已禁用 Wayland、锁定内核防翻车"
echo -e "\n请执行重启命令生效：sudo reboot"
echo -e "重启后验证命令：nvidia-smi"
echo -e "============================================="