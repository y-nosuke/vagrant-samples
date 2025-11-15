#!/bin/bash
# Placementサービスの起動

set -euo pipefail

echo "[placement-service] Placementサービスの起動中..."

# Placement APIはApacheのWSGIアプリケーションとして動作するため、Apacheサービスを再起動
echo "  Apacheサービスを再起動中（Placement APIはApacheで動作）..."
sudo systemctl restart apache2
sudo systemctl enable apache2
echo "✓ Apacheサービスを再起動しました"

# Apacheサービスの状態確認
echo "  サービスの状態を確認中..."
if sudo systemctl is-active --quiet apache2; then
    echo "✓ apache2: running (Placement APIを含む)"
else
    echo "× apache2: not running"
    echo "  ログを確認してください:"
    echo "    sudo journalctl -u apache2 -n 50"
    exit 1
fi

# ポートのリスニング確認
echo "  ポートのリスニングを確認中..."
sleep 2
if sudo ss -tlnp | grep -q "127.0.0.1:8778"; then
    echo "✓ ポート8778 (placement-api on Apache): listening on 127.0.0.1:8778"
else
    echo "× ポート8778: not listening on 127.0.0.1:8778"
    echo "  Apache設定を確認してください:"
    echo "    sudo systemctl status apache2"
    echo "    sudo cat /etc/apache2/sites-available/placement-api.conf"
    exit 1
fi

# OpenStackコマンドでの確認（admin-openrcが存在する場合）
if [ -f ~/admin-openrc ]; then
    echo "  OpenStackコマンドで動作確認中..."
    source ~/admin-openrc

    if openstack endpoint list --service placement >/dev/null 2>&1; then
        echo "✓ OpenStackコマンドでの確認: 成功"
    else
        echo "× OpenStackコマンドでの確認: 失敗"
        echo "  設定を確認してください"
    fi
fi

echo "[placement-service] 完了"

