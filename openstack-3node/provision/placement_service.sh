#!/bin/bash
# Placementサービスの起動

set -euo pipefail

echo "[placement-service] Placementサービスの起動中..."

# Placementサービスの起動
echo "  placement-apiサービスを起動中..."
sudo systemctl restart placement-api
sudo systemctl enable placement-api
echo "✓ placement-apiサービスを起動しました"

# サービスの状態確認
echo "  サービスの状態を確認中..."
if sudo systemctl is-active --quiet placement-api; then
    echo "✓ placement-api: running"
else
    echo "× placement-api: not running"
    echo "  ログを確認してください:"
    echo "    sudo journalctl -u placement-api -n 50"
    exit 1
fi

# ポートのリスニング確認
echo "  ポートのリスニングを確認中..."
sleep 2
if sudo ss -tlnp | grep -q ":8778"; then
    echo "✓ ポート8778 (placement-api): listening"
else
    echo "× ポート8778: not listening"
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

