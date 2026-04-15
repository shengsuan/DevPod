.PHONY: help build up down restart logs shell ssh clean \
	k8s-build k8s-deploy k8s-delete k8s-restart k8s-logs k8s-status k8s-exec \
	k8s-create-secret k8s-update k8s-scale k8s-rollback k8s-port-forward \
	k8s-clean k8s-describe

help:
	@echo "AI Dev Environment - 可用命令："
	@echo ""
	@echo "Docker Commands:"
	@echo "  make build           - 构建 Docker 镜像"
	@echo "  make up              - 启动容器"
	@echo "  make down            - 停止并删除容器"
	@echo "  make restart         - 重启容器"
	@echo "  make logs            - 查看容器日志"
	@echo "  make shell           - 进入容器 bash shell"
	@echo "  make ssh             - 通过 SSH 连接容器"
	@echo "  make clean           - 清理所有容器、卷和镜像"
	@echo "  make prune           - 清理 Docker 系统缓存"
	@echo ""
	@echo "Kubernetes Commands:"
	@echo "  make k8s-build       - 构建 K8s 镜像"
	@echo "  make k8s-deploy      - 部署到 K8s"
	@echo "  make k8s-delete      - 删除 K8s 资源"
	@echo "  make k8s-restart     - 重启 K8s Pod"
	@echo "  make k8s-logs        - 查看 K8s Pod 日志"
	@echo "  make k8s-status      - 查看 K8s 状态"
	@echo "  make k8s-exec        - 进入 K8s Pod"
	@echo "  make k8s-create-secret - 创建 K8s Secret"
	@echo "  make k8s-update      - 更新 K8s 部署"
	@echo "  make k8s-scale       - 扩缩容 (REPLICAS=n)"
	@echo "  make k8s-rollback    - 回滚部署"
	@echo "  make k8s-port-forward - 端口转发 (PORT=1122)"
	@echo "  make k8s-clean       - 清理 K8s 资源和 Secret"
	@echo "  make k8s-describe    - 描述 Pod 详细信息"
	@echo ""

build:
	@echo "🔨 构建 Docker 镜像..."
	docker-compose build --no-cache

build-fast:
	@echo "⚡ 快速构建 Docker 镜像..."
	docker-compose build

up:
	@echo "🚀 启动容器..."
	docker-compose up -d
	@echo "✅ 容器已启动"
	@make status

down:
	@echo "⏹️  停止容器..."
	docker-compose down
	@echo "✅ 容器已停止"

restart:
	@echo "🔄 重启容器..."
	docker-compose restart
	@echo "✅ 容器已重启"

logs:
	docker-compose logs -f --tail=100

shell:
	docker-compose exec ai-dev bash

ssh:
	@echo "🔐 SSH 连接到容器..."
	@SSH_PORT=$$(grep AIDEV_SSH_PORT .env | cut -d '=' -f2 || echo "1122"); \
	ssh -p $$SSH_PORT root@localhost

status:
	@echo "📊 容器状态："
	@docker-compose ps

clean:
	@echo "🧹 清理所有资源..."
	docker-compose down -v
	docker rmi ai-dev || true
	@echo "✅ 清理完成"

prune:
	@echo "🧹 清理 Docker 系统缓存..."
	docker system prune -af
	@echo "✅ 清理完成"

check:
	@echo "🔍 检查配置..."
	@if [ ! -f .env ]; then \
		echo "❌ .env 文件不存在，请复制 .env.example 并配置"; \
		exit 1; \
	fi
	@echo "✅ 配置检查通过"

init: check
	@echo "📦 初始化项目..."
	@if [ -f .env ]; then \
		. ./.env && export SSH_KEY_PATH; \
		if [ ! -f "$${SSH_KEY_PATH:-./id_rsa.pub}" ]; then \
			echo "⚠️  未找到 SSH 公钥，将跳过 SSH key 配置"; \
		fi; \
	fi
	@make build-fast
	@make up
	@echo "🎉 初始化完成！"
	@echo ""
	@echo "使用以下命令连接容器："
	@echo "  make shell   # 直接进入 bash"
	@echo "  make ssh     # 通过 SSH 连接"

K8S_NAMESPACE ?= default
REPLICAS ?= 3
PORT ?= 1122
SSH_KEY_PATH ?= ./id_rsa.pub

k8s-build:
	@echo "🔨 构建 K8s 镜像..."
	docker build -t ai-dev:latest .
	@echo "✅ 镜像构建完成"

k8s-create-secret:
	@echo "🔐 创建 K8s Secret..."
	@if [ ! -f .env ]; then \
		echo "❌ .env 文件不存在"; \
		exit 1; \
	fi
	@. ./.env && kubectl create secret generic aidev-secrets \
		--namespace=$(K8S_NAMESPACE) \
		--from-literal=root-password="$${AIDEV_ROOT_PASSWORD:-changeme321}" \
		--from-literal=anthropic-api-key="$${ANTHROPIC_API_KEY:-}" \
		--from-literal=openai-api-key="$${OPENAI_API_KEY:-}" \
		--from-literal=github-token="$${GITHUB_TOKEN:-}" \
		--from-literal=shengsuanyun-api-key="$${SHENGSUANYUN_API_KEY:-}" \
		--from-literal=shengsuanyun-cp-api-key="$${SHENGSUANYUN_CP_API_KEY:-}" \
		--dry-run=client -o yaml | kubectl apply -f -
	@. ./.env && SSH_KEY="$${SSH_KEY_PATH:-./id_rsa.pub}"; \
	if [ -f "$$SSH_KEY" ]; then \
		kubectl create secret generic aidev-ssh-key \
			--namespace=$(K8S_NAMESPACE) \
			--from-file=authorized_keys="$$SSH_KEY" \
			--dry-run=client -o yaml | kubectl apply -f -; \
	else \
		echo "⚠️  SSH 公钥文件 $$SSH_KEY 不存在，跳过创建"; \
	fi
	@echo "✅ Secret 创建完成"

k8s-deploy: k8s-build k8s-create-secret
	@echo "🚀 部署到 K8s..."
	kubectl apply -f k8s/namespace.yaml
	kubectl apply -f k8s/pvc.yaml --namespace=$(K8S_NAMESPACE)
	kubectl apply -f k8s/configmap.yaml --namespace=$(K8S_NAMESPACE)
	kubectl apply -f k8s/deployment.yaml --namespace=$(K8S_NAMESPACE)
	kubectl apply -f k8s/service.yaml --namespace=$(K8S_NAMESPACE)
	@echo "✅ 部署完成"
	@make k8s-status

k8s-delete:
	@echo "🗑️  删除 K8s 资源..."
	kubectl delete -f k8s/service.yaml --namespace=$(K8S_NAMESPACE) --ignore-not-found
	kubectl delete -f k8s/deployment.yaml --namespace=$(K8S_NAMESPACE) --ignore-not-found
	kubectl delete -f k8s/configmap.yaml --namespace=$(K8S_NAMESPACE) --ignore-not-found
	kubectl delete -f k8s/pvc.yaml --namespace=$(K8S_NAMESPACE) --ignore-not-found
	@echo "✅ 删除完成"

k8s-restart:
	@echo "🔄 重启 K8s Pod..."
	kubectl rollout restart deployment/aidev --namespace=$(K8S_NAMESPACE)
	kubectl rollout status deployment/aidev --namespace=$(K8S_NAMESPACE)
	@echo "✅ 重启完成"

k8s-logs:
	@echo "📋 查看 K8s Pod 日志..."
	kubectl logs -f --namespace=$(K8S_NAMESPACE) -l app=aidev --tail=100

k8s-status:
	@echo "📊 K8s 资源状态："
	@echo ""
	@echo "Pods:"
	@kubectl get pods --namespace=$(K8S_NAMESPACE) -l app=aidev
	@echo ""
	@echo "Services:"
	@kubectl get svc --namespace=$(K8S_NAMESPACE) -l app=aidev
	@echo ""
	@echo "Deployments:"
	@kubectl get deployment --namespace=$(K8S_NAMESPACE) -l app=aidev

k8s-exec:
	@echo "🔧 进入 K8s Pod..."
	@POD=$$(kubectl get pod --namespace=$(K8S_NAMESPACE) -l app=aidev -o jsonpath='{.items[0].metadata.name}'); \
	kubectl exec -it --namespace=$(K8S_NAMESPACE) $$POD -- bash

k8s-update:
	@echo "🔄 更新 K8s 部署..."
	kubectl apply -f k8s/configmap.yaml --namespace=$(K8S_NAMESPACE)
	kubectl apply -f k8s/deployment.yaml --namespace=$(K8S_NAMESPACE)
	kubectl apply -f k8s/service.yaml --namespace=$(K8S_NAMESPACE)
	kubectl rollout status deployment/aidev --namespace=$(K8S_NAMESPACE)
	@echo "✅ 更新完成"

k8s-scale:
	@echo "⚖️  扩缩容到 $(REPLICAS) 个副本..."
	kubectl scale deployment/aidev --namespace=$(K8S_NAMESPACE) --replicas=$(REPLICAS)
	@echo "✅ 扩缩容完成"

k8s-rollback:
	@echo "⏪ 回滚部署..."
	kubectl rollout undo deployment/aidev --namespace=$(K8S_NAMESPACE)
	kubectl rollout status deployment/aidev --namespace=$(K8S_NAMESPACE)
	@echo "✅ 回滚完成"

k8s-port-forward:
	@echo "🔌 端口转发 $(PORT):22..."
	@POD=$$(kubectl get pod --namespace=$(K8S_NAMESPACE) -l app=aidev -o jsonpath='{.items[0].metadata.name}'); \
	kubectl port-forward --namespace=$(K8S_NAMESPACE) $$POD $(PORT):22

k8s-clean:
	@echo "🧹 清理 K8s 资源..."
	@make k8s-delete
	kubectl delete secret aidev-secrets --namespace=$(K8S_NAMESPACE) --ignore-not-found
	kubectl delete secret aidev-ssh-key --namespace=$(K8S_NAMESPACE) --ignore-not-found
	@echo "✅ 清理完成"

k8s-describe:
	@echo "🔍 描述 K8s 资源..."
	@POD=$$(kubectl get pod --namespace=$(K8S_NAMESPACE) -l app=aidev -o jsonpath='{.items[0].metadata.name}'); \
	kubectl describe pod --namespace=$(K8S_NAMESPACE) $$POD
