# AI Dev Environment 🤖

一个功能完整的 AI 编程开发环境容器，内置多种 AI 工具和开发工具链。

## ✨ 特性

- ✅ **AI 编程工具**: Claude Code、Codex, Aider, Coding Helper
- ✅ **多语言支持**: Node.js、Python、Go、Rust
- ✅ **开发工具**: Git、GitHub CLI、Docker CLI、Kubernetes CLI
- ✅ **搜索工具**: ripgrep、fd、ag、jq
- ✅ **SSH 远程访问**: 支持密码和密钥认证
- ✅ **持久化配置**: 工具配置和工作目录持久化
- ✅ **资源管理**: 可配置的 CPU 和内存限制

---

## 🚀 快速开始

### 1. 准备环境

确保已安装：
- Docker >= 20.10
- Docker Compose >= 2.0

### 2. 配置环境变量

```bash
# 复制配置模板
cp .env.example .env

# 编辑配置（重要：修改默认密码！）
vim .env
```

### 3. （可选）准备 SSH 公钥

如果需要 SSH 密钥认证：

```bash
# 使用你的公钥
cp ~/.ssh/id_rsa.pub ./id_rsa.pub

# 或者在 .env 中指定路径
echo "SSH_KEY_PATH=~/.ssh/id_rsa.pub" >> .env
```

### 4. 启动容器

#### 方式一：使用 Makefile（推荐）

```bash
# 初始化并启动（首次使用）
make init

# 或者分步执行
make build    # 构建镜像
make up       # 启动容器
```

#### 方式二：使用 Docker Compose

```bash
# 构建镜像
docker-compose build

# 启动容器
docker-compose up -d
```

### 5. 连接到容器

```bash
# 方式一：直接进入 bash
make shell
# 或
docker-compose exec ai-dev bash

# 方式二：SSH 连接
make ssh
# 或
ssh -p 1122 root@localhost
```

---

## 📋 使用说明

### 可用命令（Makefile）

```bash
make help       # 显示帮助信息
make build      # 构建镜像
make up         # 启动容器
make down       # 停止容器
make restart    # 重启容器
make logs       # 查看日志
make shell      # 进入容器 bash
make ssh        # SSH 连接
make status     # 查看状态
make clean      # 清理所有资源
```

### 首次使用配置

进入容器后，需要初始化一些工具：

```bash
# 初始化 coding-helper
coding-helper init

# 登录 GitHub CLI
gh auth login

# 配置 Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 🛠️ 内置工具

### AI 编程工具
- **Aider**: AI 编程助手
- **Codex**: OpenAI 的 AI 编程助手
- **Claude Code**: Anthropic 的 AI 编程助手
- **Coding Helper**: API Key 和模型配置工具

### 开发语言
- **Node.js 24.x**: 包含 npm、yarn、pnpm
- **Python 3.x**: 包含 pip、poetry、black、ruff、mypy
- **Go 1.26**: 最新 Go 语言
- **Rust**: 包含 cargo

### 命令行工具
- **搜索**: `rg` (ripgrep), `ag`, `fd`, `grep`
- **文件**: `tree`, `jq`, `unzip`
- **网络**: `curl`, `wget`, `httpie`
- **版本控制**: `git`, `gh` (GitHub CLI)
- **编辑器**: `vim`, `nano`
- **系统**: `htop`, `tmux`

### DevOps 工具
- Docker CLI + Docker Compose
- kubectl (Kubernetes CLI)

---

## 📁 目录结构

```
.
├── Dockerfile              # Docker 镜像定义
├── docker-compose.yml      # Docker Compose 配置
├── .env.example            # 环境变量模板
├── .env                    # 环境变量（需创建）
├── .gitignore              # Git 忽略规则
├── .dockerignore           # Docker 构建忽略规则
├── .editorconfig           # 编辑器配置
├── Makefile                # 快捷命令
├── README.md               # 项目文档
├── SECURITY.md             # 安全注意事项
└── id_rsa.pub              # SSH 公钥（可选）
```

---

## 🔧 配置说明

### 环境变量

主要配置项（`.env` 文件）：

```bash
# SSH 配置
AIDEV_SSH_PORT=1122                    # SSH 端口
AIDEV_ROOT_PASSWORD=changeme           # Root 密码（务必修改！）

# 容器配置
AIDEV_CONTAINER_NAME=ai-dev            # 容器名称
AIDEV_WORKSPACE=/path/to/workspace     # 工作目录路径

# 资源限制
AIDEV_CPU_LIMIT=4                      # CPU 核心数
AIDEV_MEMORY_LIMIT=8g                  # 内存限制

# API Keys（可选）
ANTHROPIC_API_KEY=your_key             # Claude API Key
OPENAI_API_KEY=your_key                # OpenAI API Key
GITHUB_TOKEN=your_token                # GitHub Token
SHENGSUANYUN_API_KEY=your_token        # 胜算云 API Key
SHENGSUANYUN_CP_API_KEY=your_token     # 胜算云 coding plan API Key
```

### 持久化卷

以下目录会自动持久化：
- `/workspace` - 工作目录
- `/root/.ssh` - SSH 配置
- `/root/.claude` - Claude 配置
- `/root/.codex` - Codex 配置
- `/root/.npm` - npm 缓存
- `/root/.cache/pip` - pip 缓存
- `/root/.cargo` - Rust/Cargo 配置
- `/root/go` - Go 模块缓存

---

## 🔐 安全建议

⚠️ **重要提醒**：

1. **立即修改默认密码** - 不要使用 `changeme`
2. **不要暴露到公网** - SSH 端口仅在本地或可信网络使用
3. **使用 SSH 密钥** - 推荐密钥认证而非密码
4. **保护 .env 文件** - 包含敏感信息，不要提交到 Git
5. **谨慎挂载 Docker socket** - 会给予容器特权访问

详细安全指南请参考 [SECURITY.md](./SECURITY.md)

---

## 🐛 故障排除

### 构建失败

```bash
# 清理缓存重新构建
make clean
make build
```

### SSH 连接被拒绝

```bash
# 检查容器状态
make status

# 查看日志
make logs

# 检查端口映射
docker port ai-dev
```

### 权限问题

```bash
# 确保 .env 文件权限正确
chmod 600 .env

# 检查 SSH 公钥权限
chmod 644 id_rsa.pub
```

---

## 📝 开发建议

### 工作流示例

```bash
# 1. 启动容器
make up

# 2. 进入容器
make shell

# 3. 在容器内工作
cd /workspace
git clone https://github.com/your/repo.git
cd repo

# 4. 使用 AI 工具
claude code
# 或
coding-helper

# 5. 退出后停止容器
exit
make down
```

### 持久化配置

推荐在 `/workspace` 中工作，该目录会持久化到宿主机。

```bash
# 在 .env 中配置工作目录
AIDEV_WORKSPACE=/Users/you/projects
```

---

## 🔄 更新和维护

### 更新镜像

```bash
# 拉取最新代码
git pull

# 重新构建
make build

# 重启容器
make restart
```

### 清理资源

```bash
# 清理容器和卷
make clean

# 清理所有 Docker 资源
make prune
```

---

## 📚 相关资源

- [Claude Code 文档](https://docs.anthropic.com/claude/docs)
- [Docker 文档](https://docs.docker.com/)
- [GitHub CLI 文档](https://cli.github.com/manual/)

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

## 📄 许可证

MIT License
