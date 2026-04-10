# ============================================
# AI Dev Environment - Makefile
# ============================================
# 简化 Docker 操作的快捷命令

.PHONY: help build up down restart logs shell ssh clean

# 默认目标：显示帮助信息
help:
	@echo "AI Dev Environment - 可用命令："
	@echo ""
	@echo "  make build         - 构建 Docker 镜像"
	@echo "  make up            - 启动容器"
	@echo "  make down          - 停止并删除容器"
	@echo "  make restart       - 重启容器"
	@echo "  make logs          - 查看容器日志"
	@echo "  make shell         - 进入容器 bash shell"
	@echo "  make ssh           - 通过 SSH 连接容器"
	@echo "  make clean         - 清理所有容器、卷和镜像"
	@echo "  make prune         - 清理 Docker 系统缓存"
	@echo ""

# 构建镜像
build:
	@echo "🔨 构建 Docker 镜像..."
	docker-compose build --no-cache

# 快速构建（使用缓存）
build-fast:
	@echo "⚡ 快速构建 Docker 镜像..."
	docker-compose build

# 启动容器
up:
	@echo "🚀 启动容器..."
	docker-compose up -d
	@echo "✅ 容器已启动"
	@make status

# 停止容器
down:
	@echo "⏹️  停止容器..."
	docker-compose down
	@echo "✅ 容器已停止"

# 重启容器
restart:
	@echo "🔄 重启容器..."
	docker-compose restart
	@echo "✅ 容器已重启"

# 查看日志
logs:
	docker-compose logs -f --tail=100

# 进入容器 shell
shell:
	docker-compose exec ai-dev bash

# SSH 连接
ssh:
	@echo "🔐 SSH 连接到容器..."
	@SSH_PORT=$$(grep AIDEV_SSH_PORT .env | cut -d '=' -f2 || echo "1122"); \
	ssh -p $$SSH_PORT root@localhost

# 查看容器状态
status:
	@echo "📊 容器状态："
	@docker-compose ps

# 清理容器和卷
clean:
	@echo "🧹 清理所有资源..."
	docker-compose down -v
	docker rmi ai-dev || true
	@echo "✅ 清理完成"

# 清理 Docker 系统缓存
prune:
	@echo "🧹 清理 Docker 系统缓存..."
	docker system prune -af
	@echo "✅ 清理完成"

# 检查配置
check:
	@echo "🔍 检查配置..."
	@if [ ! -f .env ]; then \
		echo "❌ .env 文件不存在，请复制 .env.example 并配置"; \
		exit 1; \
	fi
	@echo "✅ 配置检查通过"

# 初始化项目
init: check
	@echo "📦 初始化项目..."
	@if [ ! -f id_rsa.pub ]; then \
		echo "⚠️  未找到 SSH 公钥，将跳过 SSH key 配置"; \
	fi
	@make build-fast
	@make up
	@echo "🎉 初始化完成！"
	@echo ""
	@echo "使用以下命令连接容器："
	@echo "  make shell   # 直接进入 bash"
	@echo "  make ssh     # 通过 SSH 连接"
