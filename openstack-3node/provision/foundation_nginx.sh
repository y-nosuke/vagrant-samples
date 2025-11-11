#!/bin/bash
# Nginxのインストール（コントローラノード専用）

set -euo pipefail

echo "[nginx] Nginxのインストール中..."

# Nginxのインストール
if ! command -v nginx &> /dev/null; then
    apt-get update
    apt-get install -y nginx libnginx-mod-stream
    echo "✓ Nginxをインストールしました"
else
    echo "✓ Nginxは既にインストール済みです"
fi

# デフォルトサイトの無効化
if [ -L /etc/nginx/sites-enabled/default ]; then
    unlink /etc/nginx/sites-enabled/default
    echo "✓ デフォルトサイトを無効化しました"
else
    echo "✓ デフォルトサイトは既に無効化されています"
fi

# Nginxサービスの起動
systemctl enable nginx
systemctl restart nginx
echo "✓ Nginxサービスを起動しました"

# サービスの状態確認
sleep 2
if systemctl is-active --quiet nginx; then
    echo "✓ Nginxが動作中"
else
    echo "× Nginxが起動していません"
    systemctl status nginx
    exit 1
fi

echo "[nginx] 完了"

