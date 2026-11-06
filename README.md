# telegram-web-proxy
# Telegram Web Proxy Deployment Script一个基于 **Caddy + tproxy-server + Docker (MTProxy)** 的 Telegram Web 代理一键部署脚本。实现了 443 端口 HTTPS 流量伪装、网页托管与底层代理的高效解耦。## 🛠️ 架构设计
[Telegram 客户端]
│ (Port 443 HTTPS)
▼
┌───────────┐
│   Caddy   │ 自动申请 SSL 证书，提供 443 伪装网页
└─────┬─────┘
│ (Reverse Proxy: 127.0.0.1:8080)
▼
┌───────────┐
│  tproxy-  │ 区分普通 HTTP 网页流量与 Telegram 代理流量
│  server   │


脚本会自动：
​交互式引导输入你的域名。
​自动生成 32 位安全的随机 Telegram Secret。
​安装并配置 Docker、Caddy 及本地 MTProxy 后端。
​配置 Systemd 后台守护进程并自动收紧配置文件权限 (chmod 600)。
​打印最终的 Telegram 代理连接信息。
└─────┬─────┘
│ (Backend Forward: 127.0.0.1:2398)
▼
┌───────────┐
│  MTProxy  │ Docker 后端，处理 Telegram 底层 MTProto 协议
└───────────┘

