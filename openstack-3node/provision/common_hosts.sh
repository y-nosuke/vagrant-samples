#!/bin/bash
# hostsファイルの設定（全ノード共通）

set -euo pipefail

echo "[hosts] hostsファイルの設定中..."
if ! grep -q "172.16.100.10.*controller" /etc/hosts; then
    cat >> /etc/hosts <<EOF

# OpenStack Hosts
172.16.100.10   controller
172.16.100.20   network
172.16.100.31   compute1
EOF
    echo "✓ hostsファイルを更新しました"
else
    echo "✓ hostsファイルは既に設定済みです"
fi

# 名前解決の確認
ping -c 1 controller > /dev/null 2>&1 && echo "✓ controllerに到達可能" || true
ping -c 1 network > /dev/null 2>&1 && echo "✓ networkに到達可能" || true
ping -c 1 compute1 > /dev/null 2>&1 && echo "✓ compute1に到達可能" || true
