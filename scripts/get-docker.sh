#!/bin/bash
set -e

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}[INFO] 开始通过官方 get-docker.sh 安装 Docker...${NC}"

# 1. 官方脚本安装 Docker
curl -fsSL https://get.docker.com | bash

# 2. 自动获取最新版 docker-compose（从 latest 地址）
echo -e "${GREEN}[INFO] 获取最新版 docker-compose (latest)...${NC}"
LATEST_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -o '"tag_name": ".*"' | sed 's/"tag_name": "//' | sed 's/"//')
echo -e "${GREEN}[INFO] 最新版本：$LATEST_VERSION${NC}"

# 下载（走 GitHub 代理，国内可直接用）
curl -L "https://ghp.ci/https://github.com/docker/compose/releases/download/${LATEST_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose

# 加执行权限
chmod +x /usr/local/bin/docker-compose

# 创建软链接
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# 3. 将当前用户加入 docker 组
usermod -aG docker $USER

# 4. 自定义 daemon.json 配置（可自由修改）
echo -e "${GREEN}[INFO] 写入自定义 daemon.json 配置...${NC}"
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  },
  "default-runtime": "runc",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "storage-driver": "overlay2"
}
EOF

# 5. 重启 Docker 生效
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

# 6. 输出结果
echo -e "\n${GREEN}=============================================${NC}"
echo -e "${GREEN}✅ 安装成功！${NC}"
docker -v
docker-compose -v
docker compose version
echo -e "\n${YELLOW}注意：退出终端重新登录后，无需 sudo 即可使用 docker${NC}"
echo -e "${GREEN}=============================================${NC}"