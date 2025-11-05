#!/bin/bash
# Keystone Bootstrap（コントローラノード専用）

set -euo pipefail

# パスワード設定（環境変数から取得、デフォルト値あり）
ADMIN_PASS=${ADMIN_PASS:-"admin123"}

echo "[keystone-bootstrap] Keystone Bootstrapの実行中..."
if ! openstack project list 2>/dev/null | grep -q admin; then
    export controller=controller
    keystone-manage bootstrap --bootstrap-password "${ADMIN_PASS}" \
      --bootstrap-admin-url https://$controller:5000/v3/ \
      --bootstrap-internal-url https://$controller:5000/v3/ \
      --bootstrap-public-url https://$controller:5000/v3/ \
      --bootstrap-region-id RegionOne
    echo "✓ Keystone Bootstrapを完了しました"
else
    echo "✓ Keystone Bootstrapは既に実行済みです（スキップ）"
fi

# admin-openrcファイルの作成
echo "[keystone-bootstrap] admin-openrcファイルの作成中..."
cat > ~/admin-openrc <<EOF
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=${ADMIN_PASS}
export OS_AUTH_URL=https://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
EOF
chmod 600 ~/admin-openrc
echo "✓ admin-openrcファイルを作成しました"


