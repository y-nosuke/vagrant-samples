#!/bin/bash
# Glanceパッケージのインストールとサービス登録

set -euo pipefail

# 環境変数の設定（デフォルト値）
GLANCE_PASS=${GLANCE_PASS:-"password123"}
ADMIN_PASS=${ADMIN_PASS:-"admin123"}

echo "[glance-install] Glanceパッケージのインストールとサービス登録中..."

# admin-openrcの確認
if [ ! -f ~/admin-openrc ]; then
    echo "× エラー: ~/admin-openrc が見つかりません"
    echo "  Phase 3 (Keystone) を先に完了させてください"
    exit 1
fi

# 環境変数の読み込み
source ~/admin-openrc

# glanceユーザーの作成
echo "  glanceユーザーを作成中..."
if openstack user show glance 2>/dev/null; then
    echo "✓ glanceユーザーは既に存在します"
else
    openstack user create --domain default --project service --password "${GLANCE_PASS}" glance
    echo "✓ glanceユーザーを作成しました"
fi

# glanceユーザーにadminロールを付与
echo "  glanceユーザーにadminロールを付与中..."
if openstack role assignment list --user glance --project service --names | grep -q admin; then
    echo "✓ adminロールは既に付与されています"
else
    openstack role add --project service --user glance admin
    echo "✓ adminロールを付与しました"
fi

# glanceサービスの作成
echo "  glanceサービスを作成中..."
if openstack service show glance 2>/dev/null; then
    echo "✓ glanceサービスは既に存在します"
else
    openstack service create --name glance --description "OpenStack Image service" image
    echo "✓ glanceサービスを作成しました"
fi

# エンドポイントの作成
echo "  エンドポイントを作成中..."

# public エンドポイント
if openstack endpoint list --service glance --interface public -f value -c ID | grep -q .; then
    echo "✓ publicエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne image public https://controller:9292
    echo "✓ publicエンドポイントを作成しました"
fi

# internal エンドポイント
if openstack endpoint list --service glance --interface internal -f value -c ID | grep -q .; then
    echo "✓ internalエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne image internal https://controller:9292
    echo "✓ internalエンドポイントを作成しました"
fi

# admin エンドポイント
if openstack endpoint list --service glance --interface admin -f value -c ID | grep -q .; then
    echo "✓ adminエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne image admin https://controller:9292
    echo "✓ adminエンドポイントを作成しました"
fi

# Glanceパッケージのインストール
echo "  Glanceパッケージをインストール中..."
if dpkg -l | grep -q glance; then
    echo "✓ Glanceパッケージは既にインストールされています"
else
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y glance
    echo "✓ Glanceパッケージをインストールしました"
fi

# Keystoneでの確認
echo "  Keystoneでの登録を確認中..."
openstack user list | grep -q glance && echo "✓ glanceユーザー: 登録済み"
openstack service list | grep -q image && echo "✓ glanceサービス: 登録済み"
openstack endpoint list --service image | grep -q controller && echo "✓ エンドポイント: 登録済み"

echo "[glance-install] 完了"
