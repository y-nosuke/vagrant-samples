#!/bin/bash
# Nova/novncproxy Nginx設定（コントローラノード専用）

set -euo pipefail

echo "[nova-nginx] Nova/novncproxy Nginx設定中..."

# Nginx設定ファイルのバックアップ
for conf_file in nova-api.conf nova-metadata-api.conf placement-api.conf novncproxy.conf; do
    if [ ! -f /etc/nginx/sites-available/${conf_file}.backup ]; then
        if [ -f /etc/nginx/sites-available/${conf_file} ]; then
            cp /etc/nginx/sites-available/${conf_file} /etc/nginx/sites-available/${conf_file}.backup
            echo "✓ 既存の設定ファイルをバックアップしました: ${conf_file}"
        fi
    fi
done

# Placement API用のNginx設定ファイルの作成（Apacheで動作するPlacement APIをプロキシ）
cat > /etc/nginx/sites-available/placement-api.conf <<'EOF'
upstream placement-api {
    server 127.0.0.1:8778;
}

server {
    listen 172.16.100.10:8778 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://placement-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Nova API用のNginx設定ファイルの作成
cat > /etc/nginx/sites-available/nova-api.conf <<'EOF'
upstream nova-api {
    server 127.0.0.1:8774;
}

server {
    listen 172.16.100.10:8774 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://nova-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Nova Metadata API用のNginx設定ファイルの作成
cat > /etc/nginx/sites-available/nova-metadata-api.conf <<'EOF'
upstream nova-metadata-api {
    server 127.0.0.1:8775;
}

server {
    listen 172.16.100.10:8775 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://nova-metadata-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Nova VNC Proxy用のNginx設定ファイルの作成
cat > /etc/nginx/sites-available/novncproxy.conf <<'EOF'
upstream novncproxy {
    server 127.0.0.1:6080;
}

server {
    listen 172.16.100.10:6080 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://novncproxy;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

echo "✓ Nginx設定ファイルを作成しました"

# シンボリックリンクの作成（有効化）
for conf_file in nova-api.conf nova-metadata-api.conf placement-api.conf novncproxy.conf; do
    if [ ! -L /etc/nginx/sites-enabled/${conf_file} ]; then
        ln -s /etc/nginx/sites-available/${conf_file} /etc/nginx/sites-enabled/
        echo "✓ ${conf_file} サイトを有効化しました"
    else
        echo "✓ ${conf_file} サイトは既に有効化されています"
    fi
done

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
for port in 8774 8775 8778 6080; do
    if ss -tlnp | grep -q ":${port}"; then
        echo "✓ ポート${port}でリスニング中"
    else
        echo "× ポート${port}がリスニングしていません"
    fi
done

echo "[nova-nginx] 完了"

