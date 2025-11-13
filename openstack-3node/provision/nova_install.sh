#!/bin/bash
# Novaパッケージのインストールとサービス登録

set -euo pipefail

# 環境変数の設定（デフォルト値）
NOVA_PASS=${NOVA_PASS:-"password123"}
PLACEMENT_PASS=${PLACEMENT_PASS:-"password123"}
ADMIN_PASS=${ADMIN_PASS:-"admin123"}

echo "[nova-install] Novaパッケージのインストールとサービス登録中..."

# admin-openrcの確認
if [ ! -f ~/admin-openrc ]; then
    echo "× エラー: ~/admin-openrc が見つかりません"
    echo "  Phase 3 (Keystone) を先に完了させてください"
    exit 1
fi

# 環境変数の読み込み
source ~/admin-openrc

# novaユーザーの作成
echo "  novaユーザーを作成中..."
if openstack user show nova 2>/dev/null; then
    echo "✓ novaユーザーは既に存在します"
else
    openstack user create --domain default --project service --password "${NOVA_PASS}" nova
    echo "✓ novaユーザーを作成しました"
fi

# novaユーザーにadminロールを付与
echo "  novaユーザーにadminロールを付与中..."
if openstack role assignment list --user nova --project service --names | grep -q admin; then
    echo "✓ adminロールは既に付与されています"
else
    openstack role add --project service --user nova admin
    echo "✓ adminロールを付与しました"
fi

# novaサービスの作成
echo "  novaサービスを作成中..."
if openstack service show nova 2>/dev/null; then
    echo "✓ novaサービスは既に存在します"
else
    openstack service create --name nova --description "OpenStack Compute service" compute
    echo "✓ novaサービスを作成しました"
fi

# エンドポイントの作成
echo "  エンドポイントを作成中..."

# public エンドポイント
if openstack endpoint list --service compute --interface public -f value -c ID | grep -q .; then
    echo "✓ publicエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne compute public https://controller:8774/v2.1
    echo "✓ publicエンドポイントを作成しました"
fi

# internal エンドポイント
if openstack endpoint list --service compute --interface internal -f value -c ID | grep -q .; then
    echo "✓ internalエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne compute internal https://controller:8774/v2.1
    echo "✓ internalエンドポイントを作成しました"
fi

# admin エンドポイント
if openstack endpoint list --service compute --interface admin -f value -c ID | grep -q .; then
    echo "✓ adminエンドポイントは既に存在します"
else
    openstack endpoint create --region RegionOne compute admin https://controller:8774/v2.1
    echo "✓ adminエンドポイントを作成しました"
fi

# placementユーザーの作成
echo "  placementユーザーを作成中..."
if openstack user show placement 2>/dev/null; then
    echo "✓ placementユーザーは既に存在します"
else
    openstack user create --domain default --project service --password "${PLACEMENT_PASS}" placement
    echo "✓ placementユーザーを作成しました"
fi

# placementユーザーにadminロールを付与
echo "  placementユーザーにadminロールを付与中..."
if openstack role assignment list --user placement --project service --names | grep -q admin; then
    echo "✓ adminロールは既に付与されています"
else
    openstack role add --project service --user placement admin
    echo "✓ adminロールを付与しました"
fi

# placementサービスの作成
echo "  placementサービスを作成中..."
if openstack service show placement 2>/dev/null; then
    echo "✓ placementサービスは既に存在します"
else
    openstack service create --name placement --description "OpenStack Placement service" placement
    echo "✓ placementサービスを作成しました"
fi

# placementエンドポイントの作成
echo "  placementエンドポイントを作成中..."

# public エンドポイント
if openstack endpoint list --service placement --interface public -f value -c ID | grep -q .; then
    echo "✓ publicエンドポイントは既に存在します"
    # 既存のエンドポイントをHTTPSに更新
    ENDPOINT_ID=$(openstack endpoint list --service placement --interface public -f value -c ID | head -1)
    openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
    echo "✓ publicエンドポイントをHTTPSに更新しました"
else
    openstack endpoint create --region RegionOne placement public https://controller:8778
    echo "✓ publicエンドポイントを作成しました"
fi

# internal エンドポイント
if openstack endpoint list --service placement --interface internal -f value -c ID | grep -q .; then
    echo "✓ internalエンドポイントは既に存在します"
    # 既存のエンドポイントをHTTPSに更新
    ENDPOINT_ID=$(openstack endpoint list --service placement --interface internal -f value -c ID | head -1)
    openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
    echo "✓ internalエンドポイントをHTTPSに更新しました"
else
    openstack endpoint create --region RegionOne placement internal https://controller:8778
    echo "✓ internalエンドポイントを作成しました"
fi

# admin エンドポイント
if openstack endpoint list --service placement --interface admin -f value -c ID | grep -q .; then
    echo "✓ adminエンドポイントは既に存在します"
    # 既存のエンドポイントをHTTPSに更新
    ENDPOINT_ID=$(openstack endpoint list --service placement --interface admin -f value -c ID | head -1)
    openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
    echo "✓ adminエンドポイントをHTTPSに更新しました"
else
    openstack endpoint create --region RegionOne placement admin https://controller:8778
    echo "✓ adminエンドポイントを作成しました"
fi

# Placementパッケージのインストール
echo "  Placementパッケージをインストール中..."
if dpkg -l | grep -q "^ii.*placement-api"; then
    echo "✓ Placementパッケージは既にインストールされています"
else
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y placement-api
    echo "✓ Placementパッケージをインストールしました"
fi

# Novaパッケージのインストール
echo "  Novaパッケージをインストール中..."
if dpkg -l | grep -q "^ii.*nova-api"; then
    echo "✓ Novaパッケージは既にインストールされています"
else
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y nova-api nova-conductor nova-scheduler nova-novncproxy
    echo "✓ Novaパッケージをインストールしました"
fi

# Keystoneでの確認
echo "  Keystoneでの登録を確認中..."
openstack user list | grep -q nova && echo "✓ novaユーザー: 登録済み"
openstack user list | grep -q placement && echo "✓ placementユーザー: 登録済み"
openstack service list | grep -q compute && echo "✓ novaサービス: 登録済み"
openstack service list | grep -q placement && echo "✓ placementサービス: 登録済み"
openstack endpoint list --service compute | grep -q controller && echo "✓ computeエンドポイント: 登録済み"
openstack endpoint list --service placement | grep -q controller && echo "✓ placementエンドポイント: 登録済み"

echo "[nova-install] 完了"

