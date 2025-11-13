#!/bin/bash
# Novaサービスの起動（コントローラ側）

set -euo pipefail

echo "[nova-service] Novaサービスの起動中..."

# Novaサービスの一時停止（既に起動している場合、ポート競合を回避）
echo "  Novaサービスを一時停止中（ポート競合を回避）..."
sudo systemctl stop nova-api nova-metadata-api nova-novncproxy 2>/dev/null || true

# Apache2とNginxの再起動
echo "  Apache2とNginxを再起動中..."
sudo systemctl restart apache2 nginx
echo "✓ Apache2とNginxを再起動しました"

# Novaサービスの起動
echo "  Novaサービスを起動中..."
sudo systemctl restart nova-api nova-conductor nova-scheduler nova-novncproxy
sudo systemctl enable nova-api nova-conductor nova-scheduler nova-novncproxy
echo "✓ Novaサービスを起動しました"

# サービスの状態確認
echo "  サービスの状態を確認中..."
for service in nova-api nova-conductor nova-scheduler nova-novncproxy; do
    if sudo systemctl is-active --quiet "${service}"; then
        echo "✓ ${service}: running"
    else
        echo "× ${service}: not running"
        echo "  ログを確認してください:"
        echo "    sudo journalctl -u ${service} -n 50"
        exit 1
    fi
done

# ポートのリスニング確認
echo "  ポートのリスニングを確認中..."
sleep 2
if sudo ss -tlnp | grep -q ":8774"; then
    echo "✓ ポート8774 (nova-api): listening"
else
    echo "× ポート8774: not listening"
    exit 1
fi

if sudo ss -tlnp | grep -q ":6080"; then
    echo "✓ ポート6080 (nova-novncproxy): listening"
else
    echo "× ポート6080: not listening"
    exit 1
fi

# OpenStackコマンドでの確認（admin-openrcが存在する場合）
if [ -f ~/admin-openrc ]; then
    echo "  OpenStackコマンドで動作確認中..."
    source ~/admin-openrc

    if openstack compute service list >/dev/null 2>&1; then
        echo "✓ OpenStackコマンドでの確認: 成功"
    else
        echo "× OpenStackコマンドでの確認: 失敗"
        echo "  設定を確認してください"
    fi
fi

echo "[nova-service] 完了"

