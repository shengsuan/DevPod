#!/bin/bash
set -e
if [ -f /root/.coding-helper/config.template.yaml ]; then
    envsubst < /root/.coding-helper/config.template.yaml > /root/.coding-helper/config.yaml
    echo "✓ Generated coding-helper config with environment variables"
fi

# 设置 coding-helper 默认方案
if command -v coding-helper &> /dev/null; then
    coding-helper set codex ssy_cp_enterprise 2>/dev/null || true
    coding-helper set claude ssy_cp_enterprise 2>/dev/null || true
    coding-helper set aider ssy_cp_enterprise 2>/dev/null || true
    echo "✓ Set coding-helper default plans to ssy_cp_enterprise"
fi

# 启动 SSH 服务
exec "$@"
