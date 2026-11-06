#!/bin/bash

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "[-] 请使用 root 权限运行此脚本 (例如: sudo bash deploy.sh)"
  exit 1
fi

echo "=== Telegram Web 代理全自动一键部署脚本 ==="

# 1. 交互式输入域名
read -p "请输入你的域名: " DOMAIN
if [ -z "$DOMAIN" ]; then
  echo "[-] 错误：域名不能为空！"
  exit 1
fi

# 2. 自动生成 32 位随机十六进制 Telegram Secret
SECRET=$(openssl rand -hex 16)
BACKEND_PORT=2398

echo "[+] 已自动生成 Telegram Secret: ${SECRET}"

echo "[+] 正在更新系统并安装必要依赖 (curl, caddy, docker)..."
apt update && apt install -y curl caddy docker.io
systemctl enable --now docker

# 3. 自动从 telegramdesktop/tproxy-server 官方 Releases 下载最新版主程序
if [ ! -f "/usr/local/bin/tproxy-server" ]; then
  echo "[+] 正在从官方 GitHub 仓库下载 tproxy-server 主程序..."
  TPROXY_URL="https://github.com/telegramdesktop/tproxy-server/releases/latest/download/tproxy-server-linux-amd64"
  
  curl -L -o /usr/local/bin/tproxy-server "$TPROXY_URL"
  if [ $? -ne 0 ] || [ ! -f "/usr/local/bin/tproxy-server" ]; then
    echo "[-] 错误：下载 tproxy-server 失败！请检查网络或官方 Release 命名。"
    exit 1
  fi
  chmod +x /usr/local/bin/tproxy-server
  echo "[+] tproxy-server 下载并授权成功！"
fi

echo "[+] 创建网页静态目录与配置目录..."
mkdir -p /var/www/html
mkdir -p /etc/tproxy-server

# 生成高颜值伪装首页
cat << 'EOF' > /var/www/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Cloud Edge - High Performance Web Gateway</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      background: #0d1117;
      color: #c9d1d9;
      display: flex;
      justify-content: center;
      align-items: center;
      min-height: 100vh;
      overflow: hidden;
    }
    .background-glow {
      position: absolute;
      width: 400px;
      height: 400px;
      background: radial-gradient(circle, rgba(56, 189, 248, 0.15) 0%, rgba(0,0,0,0) 70%);
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      z-index: 0;
    }
    .container {
      position: relative;
      z-index: 1;
      text-align: center;
      padding: 2.5rem;
      background: rgba(22, 27, 34, 0.8);
      border: 1px solid rgba(48, 54, 61, 0.8);
      border-radius: 16px;
      backdrop-filter: blur(12px);
      box-shadow: 0 20px 40px rgba(0, 0, 0, 0.4);
      max-width: 480px;
      width: 90%;
    }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 8px;
      padding: 6px 14px;
      background: rgba(46, 160, 67, 0.15);
      border: 1px solid rgba(46, 160, 67, 0.4);
      border-radius: 20px;
      color: #3fb950;
      font-size: 0.85rem;
      font-weight: 500;
      margin-bottom: 1.5rem;
    }
    .status-dot {
      width: 8px;
      height: 8px;
      background-color: #3fb950;
      border-radius: 50%;
      box-shadow: 0 0 8px #3fb950;
    }
    h1 {
      font-size: 1.8rem;
      color: #f0f6fc;
      margin-bottom: 0.8rem;
      font-weight: 600;
    }
    p {
      color: #8b949e;
      font-size: 0.95rem;
      line-height: 1.6;
      margin-bottom: 2rem;
    }
    .footer-text {
      font-size: 0.75rem;
      color: #484f58;
      border-top: 1px solid rgba(48, 54, 61, 0.5);
      padding-top: 1rem;
    }
  </style>
</head>
<body>
  <div class="background-glow"></div>
  <div class="container">
    <div class="status-badge">
      <span class="status-dot"></span>
      Service Operational
    </div>
    <h1>Cloud Edge Gateway</h1>
    <p>High-performance edge proxy routing service with end-to-end security protocol validation.</p>
    <div class="footer-text">
      HTTP/2 & HTTP/3 Protocol Enabled &bull; Secure TLS Tunnel
    </div>
  </div>
</body>
</html>
EOF

echo "[+] 启动本地 MTProxy 后端容器 (Docker)..."
docker rm -f mtproxy-backend &>/dev/null
docker run -d --name mtproxy-backend \
  --restart=always \
  -p 127.0.0.1:${BACKEND_PORT}:443 \
  -e SECRET="${SECRET}" \
  mtproxy/mtproxy

echo "[+] 写入 tproxy-server 主配置文件 (config.json)..."
cat << EOF > /etc/tproxy-server/config.json
{
  "listen": "127.0.0.1:8080",
  "public_hostname": "${DOMAIN}",
  "public_dir": "/var/www/html"
}
EOF

echo "[+] 写入密钥与后端配置文件 (profiles.json)..."
cat << EOF > /etc/tproxy-server/profiles.json
{
  "profiles": [
    {
      "name": "default",
      "secret": "${SECRET}",
      "backend": "127.0.0.1:${BACKEND_PORT}"
    }
  ]
}
EOF

# 严格收紧权限（核心安全要求）
chmod 600 /etc/tproxy-server/profiles.json
echo "[+] 已将 profiles.json 权限收紧为 600 (-rw-------)"

echo "[+] 配置 Systemd 服务..."
cat << 'EOF' > /etc/systemd/system/tproxy-server.service
[Unit]
Description=Telegram Web Proxy Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/tproxy-server -config /etc/tproxy-server/config.json -profiles-file /etc/tproxy-server/profiles.json
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now tproxy-server

echo "[+] 配置 Caddy 反向代理..."
cat << EOF > /etc/caddy/Caddyfile
${DOMAIN} {
    reverse_proxy 127.0.0.1:8080
}
EOF

systemctl restart caddy

echo ""
echo "=================================================="
echo "🎉 部署全部完成！"
echo "--------------------------------------------------"
echo "📋 请保存以下 Telegram 代理连接信息："
echo "  - 服务器 (Server) : ${DOMAIN}"
echo "  - 密钥 (Secret)   : ${SECRET}"
echo "=================================================="
