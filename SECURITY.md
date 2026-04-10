# 安全注意事项

## ⚠️ 重要安全提醒

### 1. SSH 配置安全

- **强密码**: 务必在 `.env` 中设置强密码，不要使用默认的 `changeme`
- **SSH Key**: 推荐使用 SSH 密钥认证而非密码认证
- **端口映射**: 不要将 SSH 端口映射到公网，仅在本地或可信网络使用
- **防火墙**: 如果必须暴露端口，使用防火墙限制访问来源

### 2. 敏感信息管理

- **API Keys**: 所有 API keys 应保存在 `.env` 文件中，该文件已被 `.gitignore` 忽略
- **不要提交**: 永远不要将 `.env` 文件提交到 Git 仓库
- **定期轮换**: 定期更换密码和 API keys
- **权限控制**: 确保 `.env` 文件权限设置为 `600` (仅所有者可读写)

```bash
chmod 600 .env
```

### 3. Docker Socket 挂载

⚠️ 挂载宿主机 Docker socket (`/var/run/docker.sock`) 会给容器完全访问宿主机 Docker 的权限，存在以下风险：

- 容器可以创建、删除、修改宿主机上的所有容器
- 可以访问宿主机上其他容器的数据
- 可能导致容器逃逸

**建议**:
- 仅在开发环境中使用
- 生产环境禁止挂载 Docker socket
- 如果需要，考虑使用 Docker-in-Docker (DinD) 方案

### 4. Root 用户运行

当前配置以 root 用户运行容器，这在开发环境可以接受，但在生产环境中应：

- 创建非 root 用户
- 使用最小权限原则
- 考虑使用 rootless 容器

### 5. 网络安全

- 容器默认连接到自定义桥接网络
- 如果需要访问外部服务，确保使用安全的连接（HTTPS, TLS）
- 不要在容器内存储未加密的敏感数据

### 6. 镜像安全

- 定期更新基础镜像 (`ubuntu:22.04`)
- 扫描镜像漏洞：

```bash
docker scan ai-dev
```

- 使用官方源安装软件包
- 最小化安装的软件包

### 7. 资源限制

已在 `docker-compose.yml` 中配置资源限制：

- CPU 限制：防止容器占用过多 CPU
- 内存限制：防止内存溢出影响宿主机

### 8. 日志和审计

- 定期检查容器日志
- 监控异常活动
- 记录重要操作

```bash
# 查看日志
make logs

# 实时监控
docker stats ai-dev
```

### 9. 备份

定期备份重要数据：

```bash
# 备份持久化卷
docker run --rm --volumes-from ai-dev -v $(pwd):/backup ubuntu tar czf /backup/backup.tar.gz /workspace

# 恢复
docker run --rm --volumes-from ai-dev -v $(pwd):/backup ubuntu tar xzf /backup/backup.tar.gz -C /
```

### 10. 生产环境建议

如果要在生产环境使用，建议：

1. 使用非 root 用户
2. 禁用密码登录，仅使用 SSH key
3. 启用 fail2ban 防止暴力破解
4. 使用 TLS/SSL 加密通信
5. 实施网络隔离
6. 定期安全审计
7. 使用专业的密钥管理服务
8. 配置日志聚合和监控

## 快速安全检查清单

- [ ] 已修改默认密码
- [ ] `.env` 文件权限已设置为 600
- [ ] 不暴露 SSH 端口到公网
- [ ] 已配置 SSH 密钥认证
- [ ] 已检查是否需要挂载 Docker socket
- [ ] 已配置适当的资源限制
- [ ] 定期更新基础镜像
- [ ] 已备份重要数据
