# Squid Proxy One-Key Installation Script

这是一个一键安装、配置和启动 Squid 代理服务器的脚本。

## 功能特性

- 🚀 **一键安装**: 自动检测操作系统并安装 Squid
- 🔧 **自动配置**: 使用优化的配置模板
- 🔐 **密码认证**: 内置用户名密码认证，避免开放代理
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

### 方法一：一键安装（自动生成随机密码）

```bash
curl -fsSL https://raw.githubusercontent.com/zwluoqi/proxy_config/refs/heads/main/squid_onekey_run.sh | sudo bash
```

安装完成后，用户名密码会显示在屏幕上，并保存到 `/etc/squid/proxy_credentials.txt`。

### 方法二：一键安装（自定义用户名密码）

```bash
curl -fsSL https://raw.githubusercontent.com/zwluoqi/proxy_config/refs/heads/main/squid_onekey_run.sh | sudo PROXY_USER=myuser PROXY_PASS=mypassword bash
```

### 方法三：下载后执行

```bash
# 下载脚本
curl -O https://raw.githubusercontent.com/zwluoqi/proxy_config/refs/heads/main/squid_onekey_run.sh

# 添加执行权限
chmod +x squid_onekey_run.sh

# 执行安装（自动生成密码）
sudo ./squid_onekey_run.sh

# 或者自定义用户名密码
PROXY_USER=myuser PROXY_PASS=mypassword sudo -E ./squid_onekey_run.sh
```

> **注意**: 脚本是完全独立的，包含了所有必要的配置，无需额外下载配置文件。

## 配置说明

脚本会自动配置以下设置：

- **监听端口**: 5566
- **用户认证**: Basic 认证（必须提供用户名密码）
- **隐私保护**: 关闭转发头信息
- **缓存设置**: 100MB 缓存空间
- **安全规则**: 基本的端口和方法限制

## 使用方法

安装完成后，代理服务器将在端口 5566 上运行，**需要用户名密码认证**：

```bash
# 使用 curl 测试代理（替换为实际的用户名、密码和服务器IP）
curl -x http://proxyuser:yourpassword@YOUR_SERVER_IP:5566 http://httpbin.org/ip

# 或者使用 --proxy-user 参数
curl --proxy-user proxyuser:yourpassword -x http://YOUR_SERVER_IP:5566 http://httpbin.org/ip

# 在浏览器中配置代理
HTTP 代理: YOUR_SERVER_IP:5566
用户名: proxyuser
密码: yourpassword
```

## 查看凭据

```bash
# 查看保存的用户名密码
sudo cat /etc/squid/proxy_credentials.txt
```

## 用户管理

```bash
# 添加新用户
sudo htpasswd /etc/squid/passwd newusername

# 删除用户
sudo htpasswd -D /etc/squid/passwd username

# 修改用户密码
sudo htpasswd /etc/squid/passwd existinguser

# 添加用户后重启服务
sudo systemctl restart squid
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

# 查看访问日志
sudo tail -f /var/log/squid/access.log
```

## 配置文件位置

- **主配置文件**: `/etc/squid/squid.conf`
- **密码文件**: `/etc/squid/passwd`
- **凭据记录**: `/etc/squid/proxy_credentials.txt`
- **缓存目录**: `/var/spool/squid`
- **日志目录**: `/var/log/squid/`

## 自定义配置

如需修改配置，请编辑 `/etc/squid/squid.conf` 文件，然后重启服务：

```bash
sudo nano /etc/squid/squid.conf
sudo systemctl restart squid
```

## 安全说明

✅ **已启用的安全措施**：
- 用户名密码认证（Basic Auth）
- 隐藏代理服务器信息
- 移除可追踪的 HTTP 头
- 限制安全端口

📝 **额外建议**：
1. **修改默认端口**: 建议修改默认端口 5566 为其他端口
2. **使用强密码**: 确保使用复杂的密码
3. **定期更换密码**: 定期更新代理密码
4. **监控日志**: 定期检查访问日志

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

### 认证问题排查
```bash
# 测试密码文件
sudo cat /etc/squid/passwd

# 测试认证程序
echo "username password" | /usr/lib/squid/basic_ncsa_auth /etc/squid/passwd
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

- v1.1.0: 添加用户名密码认证功能，避免开放代理
- v1.0.0: 初始版本，支持主流 Linux 发行版的一键安装
