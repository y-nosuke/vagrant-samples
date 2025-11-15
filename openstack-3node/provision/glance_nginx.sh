#!/bin/bash
# Glance Nginx設定（コントローラノード専用）

set -euo pipefail

echo "[glance-nginx] Glance Nginx設定中..."

# Glance WSGIファイルの確認
if [ ! -f /usr/bin/glance-wsgi-api ]; then
    echo "× エラー: /usr/bin/glance-wsgi-api が見つかりません"
    echo "  Glanceパッケージが正しくインストールされているか確認してください"
    exit 1
fi

echo "✓ Glance WSGIファイルを確認しました: /usr/bin/glance-wsgi-api"

# Nginx設定ファイルのバックアップ
if [ ! -f /etc/nginx/sites-available/glance-api.conf.backup ]; then
    if [ -f /etc/nginx/sites-available/glance-api.conf ]; then
        cp /etc/nginx/sites-available/glance-api.conf /etc/nginx/sites-available/glance-api.conf.backup
        echo "✓ 既存の設定ファイルをバックアップしました"
    fi
fi

# Nginx設定ファイルの作成
cat > /etc/nginx/sites-available/glance-api.conf <<'EOF'
upstream glance-api {
    server 127.0.0.1:9292;
}

server {
    listen 172.16.100.10:9292 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://glance-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✓ Nginx設定ファイルを作成しました"

# シンボリックリンクの作成（有効化）
if [ ! -L /etc/nginx/sites-enabled/glance-api.conf ]; then
    ln -s /etc/nginx/sites-available/glance-api.conf /etc/nginx/sites-enabled/
    echo "✓ Glanceサイトを有効化しました"
else
    echo "✓ Glanceサイトは既に有効化されています"
fi

# Nginx設定の構文チェック
if nginx -t >/dev/null 2>&1; then
    echo "✓ Nginx設定の構文チェック: OK"
else
    echo "× Nginx設定の構文エラー"
    nginx -t
    exit 1
fi

# Nginxサービスの再起動
systemctl restart nginx
echo "✓ Nginxサービスを再起動しました"

# サービスの状態確認
sleep 2
if systemctl is-active --quiet nginx; then
    echo "✓ Nginxが動作中"
else
    echo "× Nginxが起動していません"
    systemctl status nginx
    exit 1
fi

# ポートのリスニング確認
if ss -tlnp | grep -q ":9292"; then
    echo "✓ Glance APIがポート9292でリスニング中"
else
    echo "× ポート9292がリスニングしていません"
    exit 1
fi

echo "[glance-nginx] 完了"

