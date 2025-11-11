#!/bin/bash
# Glanceサービスの起動（Nginx経由）

set -euo pipefail

echo "[glance-service] Glanceサービスの起動中..."

# glance-apiサービスの起動（Nginxがリバースプロキシとして使用）
echo "  glance-apiサービスを起動中..."
sudo systemctl restart glance-api
sudo systemctl enable glance-api
echo "✓ glance-apiサービスを起動しました"

# glance-apiサービスの状態確認
echo "  サービスの状態を確認中..."
if sudo systemctl is-active --quiet glance-api; then
    echo "✓ glance-apiサービス: running"
else
    echo "× glance-apiサービス: not running"
    echo "  ログを確認してください:"
    echo "    sudo journalctl -u glance-api -n 50"
    exit 1
fi

# Nginxサービスの状態確認
echo "  Nginxサービスの状態を確認中..."
if sudo systemctl is-active --quiet nginx; then
    echo "✓ Nginxサービス: running"
else
    echo "× Nginxサービス: not running"
    echo "  Nginxを起動してください:"
    echo "    sudo systemctl start nginx"
    exit 1
fi

# Nginxサービスの自動起動を有効化
echo "  Nginxサービスの自動起動を有効化中..."
sudo systemctl enable nginx
echo "✓ Nginx自動起動を有効化しました"

# ポートのリスニング確認（Nginx経由）
echo "  ポート9292のリスニングを確認中..."
sleep 2
if sudo ss -tuln | grep -q ":9292"; then
    echo "✓ ポート9292: listening (Nginx経由)"
    # glance-apiサービスもlocalhostでリスニングしていることを確認
    if sudo ss -tlnp | grep -q "127.0.0.1:9292"; then
        echo "✓ glance-apiサービス: listening on 127.0.0.1:9292"
    else
        echo "× glance-apiサービス: not listening on 127.0.0.1:9292"
        exit 1
    fi
else
    echo "× ポート9292: not listening"
    echo "  Nginx設定を確認してください:"
    echo "    sudo nginx -t"
    echo "    sudo systemctl status nginx"
    exit 1
fi

# OpenStackコマンドでの確認（admin-openrcが存在する場合）
if [ -f ~/admin-openrc ]; then
    echo "  OpenStackコマンドで動作確認中..."
    source ~/admin-openrc

    if openstack image list >/dev/null 2>&1; then
        echo "✓ OpenStackコマンドでの確認: 成功"
    else
        echo "× OpenStackコマンドでの確認: 失敗"
        echo "  設定を確認してください"
    fi
fi

echo "[glance-service] 完了"
