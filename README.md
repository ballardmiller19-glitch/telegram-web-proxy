# Telegram Web Proxy

一个基于 **Caddy + tproxy-server (Telegram Desktop 官方开源核心) + Docker (MTProxy)** 的 Telegram Web 代理全自动一键部署方案。

该项目将 **HTTPS 流量伪装（前端网页托管）**、**流量智能识别与桥接（tproxy-server）** 以及 **Telegram 底层 MTProto 协议处理（Docker 后端）** 进行了高效解耦，具备极高的隐蔽性、稳定系与抗封锁能力。

---

## 🔗 引用与致谢 (Credits & Upstream)

本项目的核心流量智能分流与桥接能力，构建于以下优秀的开源项目之上：
* **核心后端路由引擎**：[telegramdesktop/tproxy-server](https://github.com/telegramdesktop/tproxy-server) —— 由 Telegram Desktop 官方团队开源的高性能代理服务器，负责精准剥离并桥接 HTTPS 网页流量与 Telegram 代理流量。
* **前端网关与证书托管**：[Caddy](https://caddyserver.com/) —— 提供现代化、自动化的 HTTPS 证书申请与高性能反向代理。
* **底层协议处理**：[MTProxy](https://github.com/TelegramMessenger/MTProxy) —— 处理底层的 MTProto 加密协议握手。

---

## 🛠️ 架构设计

```text
[Telegram 客户端 / 浏览器] 
       │ (Port 443 HTTPS 流量 / 现代暗黑科技风伪装网页)
       ▼
 ┌───────────┐
 │   Caddy   │ 自动申请并托管 SSL 证书，提供 443 端口 TLS 伪装
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
​真·一键部署：脚本会自动拉取系统依赖、从官方 Releases 动态下载最新版 tproxy-server 主程序并完成全套配置。
​零 Go 环境负担：直接使用官方编译好的二进制静态程序，VPS 上无需配置繁琐的 Go 语言开发环境。
​高颜值伪装主页：内置现代化暗黑科技风（Cloud Edge Gateway）响应式首页，拒绝简陋的默认测试页，具备极佳的视觉隐蔽性。
​安全随机密钥：通过 openssl 自动生成符合规范的 32 位十六进制安全 Telegram Secret。
​严格权限控制：自动对包含密钥的 profiles.json 设置 600 权限，保障系统运行合规与安全。
​🚀 快速开始
​在一台全新干净的 Linux VPS 上（需拥有公网 IP 且已将域名正确解析至该 VPS），直接在终端执行以下一行命令即可完成全自动部署：
bash <(curl -sL https://raw.githubusercontent.com/ballardmiller19-glitch/telegram-web-proxy/main/deploy.sh)

交互引导：
​运行后，脚本会提示输入：
​请输入你的域名
​脚本将自动完成剩余所有操作，并在最后在终端打印出专属的 Telegram 代理连接信息。
​📱 Telegram 客户端配置
​部署完成后，在 Telegram 客户端的代理设置中填入以下信息并启用：
​服务器 (Server)：你的域名
​密钥 (Secret)：脚本最后输出的 32 位随机十六进制字符串
​⚠️ 核心配置规范说明（避坑指南）
​配置文件职责分离：
​config.json：仅存放基础网络监听、域名及静态网页目录。
​profiles.json：独立存放 secret 和 backend。
​严格的文件权限：
​profiles.json 必须保持 chmod 600 权限，否则 tproxy-server 会因安全校验失败而报错拒绝启动。
​后端回环指向：
​profiles.json 中的 backend 必须指向本地实际监听端口（如 127.0.0.1:2398），切勿指向 443 端口以免造成流量死循环。
