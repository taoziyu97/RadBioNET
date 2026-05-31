#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# RadBioNET 国内服务器部署脚本
# 适用系统: Ubuntu 22.04
# 用法: sudo bash scripts/deploy_server.sh
# ============================================================

# ---- 配置（改成你的信息）----
DOMAIN="radbionet.com"
APP_NAME="RadBioNET"
SHINY_PORT=3838  # Shiny Server 默认端口，无需改

# ---- 1. 系统更新 + 依赖 ----
apt update && apt upgrade -y
apt install -y --no-install-recommends \
    build-essential \
    libssl-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    libcairo2-dev \
    libxt-dev \
    cmake \
    wget \
    git \
    nginx \
    certbot \
    python3-certbot-nginx

# ---- 2. 安装 R (最新稳定版) ----
# 使用 CRAN 镜像（国内用清华源）
apt install -y --no-install-recommends software-properties-common dirmngr
wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | \
    gpg --dearmor -o /usr/share/keyrings/cran-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cran-archive-keyring.gpg] https://mirrors.tuna.tsinghua.edu.cn/CRAN/bin/linux/ubuntu jammy-cran40/" > /etc/apt/sources.list.d/cran.list
apt update
apt install -y r-base r-base-dev

# ---- 3. 安装 Shiny Server ----
wget https://download3.rstudio.org/ubuntu-18.04/x86_64/shiny-server-1.5.22.988-amd64.deb -O /tmp/shiny-server.deb
gdebi -n /tmp/shiny-server.deb
rm /tmp/shiny-server.deb

# ---- 4. 安装 R 包 ----
R --no-save --no-restore << 'EOF'
packages <- c(
    "dplyr", "data.table", "tidyr",
    "shiny", "shinydashboard", "shinyWidgets", "shinycssloaders", "shinyjs",
    "ggplot2", "ggthemes", "RColorBrewer", "scales", "plotly",
    "DT", "visNetwork",
    "htmltools", "httr", "jsonlite", "readxl"
)
for (pkg in packages) {
    if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
        install.packages(pkg, repos = "https://mirrors.tuna.tsinghua.edu.cn/CRAN")
    }
}
EOF

# ---- 5. 部署 RadBioNET ----
cd /srv/shiny-server
git clone https://github.com/taoziyu97/RadBioNET.git "$APP_NAME"

# 没有 git 仓库则手动上传：
# 注释掉上面 git clone，用这行，在本地执行 scp：
# scp -r /path/to/RadBioNET ubuntu@<服务器IP>:/srv/shiny-server/

# ---- 6. 配置 Shiny Server ----
# 确保 app 在 /srv/shiny-server/RadBioNET 下
chown -R shiny:shiny /srv/shiny-server/"$APP_NAME"

# ---- 7. 配置 Nginx 反向代理 ----
cat > /etc/nginx/sites-available/"$APP_NAME" << NGINX
server {
    listen 80;
    server_name $DOMAIN;

    # 可选：Shiny Server 后台管理（限制 IP 访问）
    location / {
        proxy_pass http://127.0.0.1:$SHINY_PORT/$APP_NAME/;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 20d;
        proxy_send_timeout 20d;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/"$APP_NAME" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

# ---- 8. HTTPS 证书 ----
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@"$DOMAIN"

# ---- 9. 设置 LLM API 环境变量（可选）----
# 编辑 /etc/shiny-server/shiny-server.conf 在顶部加入：
# env RADBIO_API_URL https://api.deepseek.com
# env RADBIO_API_KEY sk-your-key
# env RADBIO_MODEL deepseek-chat
# 然后 systemctl restart shiny-server

echo ""
echo "=== 部署完成 ==="
echo "访问地址: https://$DOMAIN"
echo "Shiny Server 管理: http://服务器IP:$SHINY_PORT"
echo ""
echo "如果使用自定义 LLM API，请手动配置环境变量："
echo "  sudo nano /etc/shiny-server/shiny-server.conf"
echo "  sudo systemctl restart shiny-server"
