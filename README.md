# Telegram Web Proxy

一个基于 **Caddy + tproxy-server + Docker (MTProxy)** 的 Telegram Web 代理一键部署脚本。

该项目将 **HTTPS 流量伪装（前端网页托管）**、**流量智能识别与桥接（tproxy-server）** 以及 **Telegram 底层 MTProto 协议处理（Docker 后端）** 进行了高效解耦，具备极高的隐蔽性与稳定性。

---

## 🛠️ 架构设计

```text
[Telegram 客户端 / 浏览器] 
       │ (Port 443 HTTPS 流量 / 伪装网页访问)
       ▼
 ┌───────────┐
 │   Caddy   │ 自动申请并托管 SSL 证书，提供 443 端口 TLS 伪装网页
 └─────┬─────┘
       │ (Reverse Proxy: 127.0.0.1:8080)
       ▼
 ┌───────────┐
 │  tproxy-  │ 智能识别并区分普通网页流量与 Telegram 代理加密流量
 │  server   │ (读取权限严格为 600 的 profiles.json 密钥配置)
 └─────┬─────┘
       │ (Backend Forward: 127.0.0.1:2398)
       ▼
 ┌───────────┐
 │  MTProxy  │ Docker 后端容器，处理 Telegram 底层 MTProto 协议握手
 └───────────┘
✨ 项目特性
​全自动部署：一键完成系统更新、依赖安装、Caddy 配置、Docker 容器拉取及 Systemd 服务注册。
​安全随机密钥：脚本运行时刻自动生成符合规范的 32 位十六进制安全 Telegram Secret。
​严格权限控制：自动对包含密钥的 profiles.json 设置 600 权限，防止信息泄露。
​完美伪装：正常访问域名展示自定义网页，代理流量走后端隧道，抗封锁能力强。
​📋 准备工作
​在运行脚本前，请确保你的 VPS 满足以下条件：
1）拥有独立的公网双栈 IP 及指向该 VPS 的解析域名。
2）已将 tproxy-server 主程序二进制文件放置于 /usr/local/bin/tproxy-server 目录下，并赋予执行权限：
chmod +x /usr/local/bin/tproxy-server
🚀 快速开始
​在 VPS 上以 root 权限执行以下命令下载并运行一键部署脚本：
# 1. 下载脚本（或者直接从你的 GitHub 仓库克隆/下载）
curl -O [https://raw.githubusercontent.com/你的GitHub用户名/telegram-web-proxy/main/deploy.sh](https://raw.githubusercontent.com/你的GitHub用户名/telegram-web-proxy/main/deploy.sh)

# 2. 赋予执行权限
chmod +x deploy.sh

# 3. 运行脚本
sudo bash deploy.sh

交互引导：
​脚本运行后会提示你输入：
​域名
​脚本会自动完成剩余所有配置，并在最后在终端打印出专属的 Telegram 代理连接信息。
​📱 Telegram 客户端配置
​部署完成后，在 Telegram 客户端的代理设置中填入以下信息并启用：
​服务器 (Server)：你的域名
​密钥 (Secret)：脚本最后输出的 32 位随机十六进制字符串
​⚠️ 核心配置规范说明（避坑指南）
​配置文件职责分离：
​config.json：仅存放基础网络监听、域名及静态网页目录。
​profiles.json：独立存放 secret 和 backend，避免配置耦合。
​严格的文件权限：
​profiles.json 必须保持 chmod 600 权限，否则 tproxy-server 会因安全校验失败而拒绝启动。
​后端回环指向：
​profiles.json 中的 backend 必须指向本地实际监听端口（如 127.0.0.1:2398），切勿指向 443 端口以免造成流量死循环。