#!/bin/bash
# Placement Apache設定（コントローラノード専用）

set -euo pipefail

echo "[placement-apache] Placement Apache設定中..."

# Placement WSGIファイルの確認
if [ ! -f /usr/bin/placement-api ]; then
    echo "× エラー: /usr/bin/placement-api が見つかりません"
    echo "  Placementパッケージが正しくインストールされているか確認してください"
    exit 1
fi

echo "✓ Placement WSGIファイルを確認しました: /usr/bin/placement-api"

# Apache設定ファイルのバックアップ
if [ ! -f /etc/apache2/sites-available/placement-api.conf.backup ]; then
    if [ -f /etc/apache2/sites-available/placement-api.conf ]; then
        cp /etc/apache2/sites-available/placement-api.conf /etc/apache2/sites-available/placement-api.conf.backup
        echo "✓ 既存の設定ファイルをバックアップしました"
    fi
fi

# Apache設定ファイルの作成
cat > /etc/apache2/sites-available/placement-api.conf <<'EOF'
Listen 127.0.0.1:8778

<VirtualHost 127.0.0.1:8778>
    WSGIDaemonProcess placement-api processes=3 threads=1 user=placement group=placement display-name=%{GROUP}
    WSGIProcessGroup placement-api
    WSGIScriptAlias / /usr/bin/placement-api
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>
    ErrorLog /var/log/apache2/placement-api.log
    CustomLog /var/log/apache2/placement-api_access.log combined
    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>
EOF

echo "✓ Apache設定ファイルを作成しました"

# WSGIモジュールの有効化
a2enmod wsgi 2>/dev/null || true

# Apacheサイトの有効化
a2ensite placement-api 2>/dev/null || true

# Apacheサービスの再起動
systemctl restart apache2
echo "✓ Apacheサービスを再起動しました"

# サービスの状態確認
sleep 2
if systemctl is-active --quiet apache2; then
    echo "✓ Apacheが動作中"
else
    echo "× Apacheが起動していません"
    systemctl status apache2
    exit 1
fi

# ポートのリスニング確認
if ss -tlnp | grep -q ":8778"; then
    echo "✓ Placement APIがポート8778でリスニング中"
else
    echo "× ポート8778がリスニングしていません"
    exit 1
fi

echo "[placement-apache] 完了"

