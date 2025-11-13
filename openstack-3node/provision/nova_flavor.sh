#!/bin/bash
# Nova Flavorの作成

set -euo pipefail

echo "[nova-flavor] Nova Flavorの作成中..."

# admin-openrcの確認
if [ ! -f ~/admin-openrc ]; then
    echo "× エラー: ~/admin-openrc が見つかりません"
    echo "  Phase 3 (Keystone) を先に完了させてください"
    exit 1
fi

# 環境変数の読み込み
source ~/admin-openrc

# 標準Flavorの作成
echo "  標準Flavorを作成中..."

# m1.tiny
if openstack flavor show m1.tiny 2>/dev/null; then
    echo "✓ m1.tiny: 既に存在します"
else
    openstack flavor create --id 1 --ram 512 --disk 1 --vcpus 1 m1.tiny
    echo "✓ m1.tiny: 作成しました"
fi

# m1.small
if openstack flavor show m1.small 2>/dev/null; then
    echo "✓ m1.small: 既に存在します"
else
    openstack flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 m1.small
    echo "✓ m1.small: 作成しました"
fi

# m1.medium
if openstack flavor show m1.medium 2>/dev/null; then
    echo "✓ m1.medium: 既に存在します"
else
    openstack flavor create --id 3 --ram 4096 --disk 40 --vcpus 2 m1.medium
    echo "✓ m1.medium: 作成しました"
fi

# m1.large
if openstack flavor show m1.large 2>/dev/null; then
    echo "✓ m1.large: 既に存在します"
else
    openstack flavor create --id 4 --ram 8192 --disk 80 --vcpus 4 m1.large
    echo "✓ m1.large: 作成しました"
fi

# Flavor一覧の確認
echo "  Flavor一覧を確認中..."
openstack flavor list

echo "[nova-flavor] 完了"

