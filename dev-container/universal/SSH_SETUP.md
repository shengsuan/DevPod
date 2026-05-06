# SSH Configuration for Universal Dev Container

## 概述

`setup-user` feature 现在会自动配置SSH服务器，支持密码和SSH密钥两种登录方式。

## 自动配置内容

容器构建时会自动完成以下配置：

1. **设置用户密码**：为 `codespace` 用户设置密码（默认：`codespace`）
2. **创建 .ssh 目录**：自动创建 `~/.ssh` 目录并设置正确的权限
3. **配置 SSH 服务器**：
   - 监听端口 22（容器内部）
   - 启用密码认证（PasswordAuthentication）
   - 启用公钥认证（PubkeyAuthentication）
   - 启用键盘交互认证（KbdInteractiveAuthentication）

## 使用方法

### 端口映射

在 `devcontainer.json` 中已配置端口映射：
```json
"appPort": ["2222:22"]
```

这将容器内部的22端口映射到主机的2222端口。

### 登录方式

#### 方式1：使用密码登录

```bash
ssh codespace@localhost -p 2222
# 输入密码: codespace
```

#### 方式2：使用SSH密钥登录

1. 将你的公钥添加到容器：
   ```bash
   # 从主机复制公钥到容器
   cat ~/.ssh/id_ed25519.pub | docker exec -i <容器名> bash -c "cat >> /home/codespace/.ssh/authorized_keys"

   # 或在容器内手动添加
   docker exec -it <容器名> bash
   echo "your-public-key-here" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

2. 使用密钥登录：
   ```bash
   ssh codespace@localhost -p 2222
   ```

### 自定义密码

如果想使用不同的密码，可以在构建时设置环境变量：

```json
// 在 devcontainer.json 中
"build": {
    "args": {
        "USER_PASSWORD": "your-custom-password"
    }
}
```

或在 `install.sh` 中直接修改默认密码：
```bash
USER_PASSWORD="${USER_PASSWORD:-your-custom-password}"
```

## 安全建议

1. **生产环境**：建议禁用密码认证，仅使用SSH密钥
2. **修改默认密码**：如果使用密码认证，请修改默认密码
3. **密钥管理**：妥善保管SSH私钥，不要提交到版本控制

## 故障排查

### SSH连接被拒绝

```bash
# 检查SSH服务状态
docker exec <容器名> service ssh status

# 查看SSH配置
docker exec <容器名> cat /etc/ssh/sshd_config | grep -E "(PasswordAuthentication|PubkeyAuthentication)"

# 检查端口监听
docker exec <容器名> netstat -tlnp | grep :22
```

### 密码登录失败

```bash
# 检查用户密码状态
docker exec <容器名> passwd -S codespace

# 重置密码
docker exec -u root <容器名> bash -c 'echo "codespace:newpassword" | chpasswd'
```

### SSH密钥登录失败

```bash
# 检查 authorized_keys 权限
docker exec <容器名> ls -la ~/.ssh/

# 验证公钥内容
docker exec <容器名> cat ~/.ssh/authorized_keys
```
