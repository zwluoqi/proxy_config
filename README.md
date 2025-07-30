# Squid Proxy One-Key Installation Script

这是一个一键安装、配置和启动 Squid 代理服务器的脚本。

## 功能特性

- 🚀 **一键安装**: 自动检测操作系统并安装 Squid
- 🔧 **自动配置**: 使用优化的配置模板
- 🛡️ **隐私保护**: 内置隐私保护设置
- 🔥 **防火墙配置**: 自动配置防火墙规则
- 📊 **状态检测**: 安装后自动测试服务状态

## 支持的操作系统

- Ubuntu / Debian
- CentOS / RHEL / Rocky Linux / AlmaLinux
- Fedora
- openSUSE / SUSE
- Arch Linux
- Alpine Linux

## 快速安装

### 方法一：直接从 GitHub 下载并执行

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/proxy_config/main/squid_onekey_run.sh | sudo bash
```

### 方法二：下载后执行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/YOUR_USERNAME/proxy_config/main/squid_onekey_run.sh

# 添加执行权限
chmod +x squid_onekey_run.sh

# 执行安装
sudo ./squid_onekey_run.sh
```

### 方法三：使用 wget

```bash
wget https://raw.githubusercontent.com/YOUR_USERNAME/proxy_config/main/squid_onekey_run.sh && chmod +x squid_onekey_run.sh && sudo ./squid_onekey_run.sh
```

> **注意**: 脚本是完全独立的，包含了所有必要的配置，无需额外下载配置文件。

## 配置说明

脚本会自动配置以下设置：

- **监听端口**: 5566
- **隐私保护**: 关闭转发头信息
- **访问控制**: 允许所有访问（可根据需要修改）
- **缓存设置**: 100MB 缓存空间
- **安全规则**: 基本的端口和方法限制

## 使用方法

安装完成后，代理服务器将在端口 5566 上运行：

```bash
# 使用 curl 测试代理
curl -x http://YOUR_SERVER_IP:5566 http://httpbin.org/ip

# 在浏览器中配置代理
HTTP 代理: YOUR_SERVER_IP:5566
```

## 服务管理

```bash
# 启动服务
sudo systemctl start squid

# 停止服务
sudo systemctl stop squid

# 重启服务
sudo systemctl restart squid

# 查看状态
sudo systemctl status squid

# 查看日志
sudo tail -f /var/log/squid/access.log
```

## 配置文件位置

- **主配置文件**: `/etc/squid/squid.conf`
- **缓存目录**: `/var/spool/squid`
- **日志目录**: `/var/log/squid/`

## 自定义配置

如需修改配置，请编辑 `/etc/squid/squid.conf` 文件，然后重启服务：

```bash
sudo nano /etc/squid/squid.conf
sudo systemctl restart squid
```

## 安全建议

1. **修改默认端口**: 建议修改默认端口 5566 为其他端口
2. **访问控制**: 根据需要限制访问来源 IP
3. **认证设置**: 考虑添加用户认证
4. **防火墙**: 确保只开放必要的端口

## 故障排除

### 检查服务状态
```bash
sudo systemctl status squid
```

### 检查配置语法
```bash
sudo squid -k parse
```

### 查看错误日志
```bash
sudo tail -f /var/log/squid/cache.log
```

### 检查端口监听
```bash
sudo netstat -tlnp | grep 5566
# 或
sudo ss -tlnp | grep 5566
```

## 卸载

如需卸载 Squid：

```bash
# Ubuntu/Debian
sudo apt-get remove --purge squid

# CentOS/RHEL/Fedora
sudo yum remove squid
# 或
sudo dnf remove squid

# 删除配置和缓存文件
sudo rm -rf /etc/squid /var/spool/squid /var/log/squid
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！

## 更新日志

- v1.0.0: 初始版本，支持主流 Linux 发行版的一键安装