FROM ubuntu:22.04

# 基础环境配置
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# 安装基础工具和运行时依赖（合并层以减少镜像大小）
RUN apt-get update && apt-get install -y --no-install-recommends \
    # 核心工具
    curl \
    wget \
    git \
    vim \
    nano \
    unzip \
    zip \
    ca-certificates \
    gnupg \
    lsb-release \
    # 构建工具
    build-essential \
    make \
    cmake \
    pkg-config \
    # 搜索和文件工具
    ripgrep \
    fd-find \
    silversearcher-ag \
    jq \
    tree \
    gettext-base \
    # 系统工具
    htop \
    tmux \
    screen \
    # 网络工具
    net-tools \
    iputils-ping \
    dnsutils \
    httpie \
    # Python 运行时
    python3 \
    python3-pip \
    python3-venv \
    # SSH 服务
    openssh-server \
    # 清理缓存
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ---- Node.js (for Codex CLI / Claude Code ecosystem) ----
ENV NVM_DIR=/root/.nvm \
    NODE_VERSION=24.1.0

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash && \
    bash -c "source $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default"

ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin:${PATH}"

# ---- npm global tools ----
RUN npm install -g --no-optional \
    yarn \
    pnpm \
    @coohu/coding-helper \
    @openai/codex

RUN echo 'alias ch="coding-helper"' >> "$HOME/.bashrc" && \
    echo 'alias python="python3"' >> "$HOME/.bashrc" && \
    echo 'export PATH="/root/.local/bin:$PATH"' >> "$HOME/.bashrc"

# ---- GitHub CLI ----
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update && apt-get install -y gh

# ---- Go ----
RUN curl -LO https://dl.google.com/go/go1.26.2.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go1.26.2.linux-amd64.tar.gz \
    && rm go1.26.2.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# ---- Rust ----
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# ---- Docker CLI (可选，用于在容器内管理宿主机 Docker) ----
# 注意：不推荐安装 docker.io，应该通过 volume 挂载宿主机的 docker.sock
# 如需 docker CLI，只安装 CLI 工具：
RUN apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# ---- Kubernetes CLI (optional) ----
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" \
    && install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# ---- Claude Code CLI ----
RUN curl -fsSL -o /tmp/claude_install.sh https://claude.ai/install.sh && \
    chmod +x /tmp/claude_install.sh && \
    /tmp/claude_install.sh && \
    rm /tmp/claude_install.sh

# ---- 常用 Python 工具 ----
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir \
    virtualenv \
    pipx \
    poetry \
    black \
    ruff \
    mypy \
    pytest \
    aider-install \
    ipython

ENV PATH="/root/.local/bin:${PATH}"
RUN aider-install

RUN mkdir -p /root/.coding-helper
COPY coding-helper.config.template.yaml /root/.coding-helper/config.template.yaml
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# ---- SSH 服务配置 ----
RUN mkdir -p /var/run/sshd /root/.ssh && \
chmod 700 /root/.ssh

# 使用 BuildKit secret 挂载 SSH 公钥
RUN --mount=type=secret,id=ssh_key \
if [ -f /run/secrets/ssh_key ]; then \
cat /run/secrets/ssh_key > /root/.ssh/authorized_keys && \
chmod 600 /root/.ssh/authorized_keys; \
fi

# 配置 SSH 服务
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
CMD pgrep sshd || exit 1

# ---- 工作目录和 Shell 配置 ----
WORKDIR /workspace
SHELL ["/bin/bash", "-c"]
# 持久化配置目录（可选）
VOLUME ["/workspace", "/root/.ssh"]

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
