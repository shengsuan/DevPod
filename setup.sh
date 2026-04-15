#!/bin/bash

# ============================================
# AI Dev Environment - 快速启动脚本
# ============================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}"
echo "================================================"
echo "  AI Dev Environment - 快速启动"
echo "================================================"
echo -e "${NC}"

# 检查 Docker
echo -e "${YELLOW}[1/6] 检查 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker 未安装，请先安装 Docker${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker 已安装${NC}"

# 检查 Docker Compose
echo -e "${YELLOW}[2/6] 检查 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose 未安装${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Docker Compose 已安装${NC}"

# 检查 .env 文件
echo -e "${YELLOW}[3/6] 检查配置文件...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 .env 文件不存在，正在创建...${NC}"
    cp .env.example .env
    echo -e "${GREEN}✅ 已创建 .env 文件${NC}"

    # 提醒修改密码
    echo -e "${RED}"
    echo "⚠️  重要提醒："
    echo "   请编辑 .env 文件并修改默认密码！"
    echo "   vim .env"
    echo -e "${NC}"

    read -p "是否现在编辑 .env 文件？ (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-vim} .env
    fi
else
    echo -e "${GREEN}✅ .env 文件已存在${NC}"
fi

# 检查密码是否为默认值
if grep -q "DEVPOD_ROOT_PASSWORD=changeme" .env 2>/dev/null; then
    echo -e "${RED}"
    echo "⚠️  警告：检测到使用默认密码 'changeme'"
    echo "   强烈建议修改密码！"
    echo -e "${NC}"
fi

# 检查 SSH 公钥
echo -e "${YELLOW}[4/6] 检查 SSH 公钥...${NC}"
if [ ! -f id_rsa.pub ]; then
    echo -e "${YELLOW}ℹ️  未找到 SSH 公钥文件${NC}"

    if [ -f ~/.ssh/id_rsa.pub ]; then
        read -p "是否复制 ~/.ssh/id_rsa.pub？ (Y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            cp ~/.ssh/id_rsa.pub ./id_rsa.pub
            echo -e "${GREEN}✅ 已复制 SSH 公钥${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  跳过 SSH 密钥配置，将仅使用密码认证${NC}"
    fi
else
    echo -e "${GREEN}✅ SSH 公钥已存在${NC}"
fi

# 构建镜像
echo -e "${YELLOW}[5/6] 构建 Docker 镜像...${NC}"
echo "这可能需要几分钟时间..."

if [ -f id_rsa.pub ]; then
    DOCKER_BUILDKIT=1 docker-compose build
else
    echo -e "${YELLOW}ℹ️  没有 SSH 公钥，使用无密钥构建${NC}"
    DOCKER_BUILDKIT=1 docker-compose build --build-arg SKIP_SSH_KEY=true
fi

echo -e "${GREEN}✅ 镜像构建完成${NC}"

# 启动容器
echo -e "${YELLOW}[6/6] 启动容器...${NC}"
docker-compose up -d
echo -e "${GREEN}✅ 容器已启动${NC}"

# 等待容器就绪
echo -e "${YELLOW}等待容器就绪...${NC}"
sleep 3

# 显示状态
echo
echo -e "${GREEN}"
echo "================================================"
echo "  🎉 启动成功！"
echo "================================================"
echo -e "${NC}"

# 获取配置信息
SSH_PORT=$(grep DEVPOD_SSH_PORT .env | cut -d '=' -f2 || echo "1122")

echo "容器信息："
docker-compose ps

echo
echo -e "${GREEN}连接方式：${NC}"
echo
echo "1. 直接进入 bash："
echo -e "   ${YELLOW}docker-compose exec dev-pod bash${NC}"
echo -e "   或 ${YELLOW}make shell${NC}"
echo
echo "2. SSH 连接："
echo -e "   ${YELLOW}ssh -p ${SSH_PORT} root@localhost${NC}"
echo -e "   或 ${YELLOW}make ssh${NC}"
echo
echo "3. 查看日志："
echo -e "   ${YELLOW}docker-compose logs -f${NC}"
echo -e "   或 ${YELLOW}make logs${NC}"
echo
echo -e "${YELLOW}首次使用请在容器内执行：${NC}"
echo "  coding-helper init"
echo "  gh auth login"
echo
echo -e "${GREEN}更多命令请运行：${NC}"
echo -e "  ${YELLOW}make help${NC}"
echo
echo -e "${RED}⚠️  安全提醒：请阅读 SECURITY.md 了解安全最佳实践${NC}"
echo
