#!/bin/bash
set -e
if [ -f /root/.coding-helper/config.template.yaml ]; then
    envsubst < /root/.coding-helper/config.template.yaml > /root/.coding-helper/config.yaml
    echo "✓ Generated coding-helper config with environment variables"
fi

if command -v coding-helper &> /dev/null; then
    coding-helper set codex pay_as_you_go 2>/dev/null || true
    coding-helper set claude pay_as_you_go 2>/dev/null || true
    coding-helper set aider pay_as_you_go 2>/dev/null || true
    echo "✓ Set coding-helper default plans to pay_as_you_go"
fi

if [ -n "$AIDEV_ROOT_PASSWORD" ]; then
    echo "root:${AIDEV_ROOT_PASSWORD}" | chpasswd
fi

exec /usr/sbin/sshd -D
exec "$@"
