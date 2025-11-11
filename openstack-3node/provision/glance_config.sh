#!/bin/bash
# Glance設定ファイルの編集とDB同期

set -euo pipefail

# 環境変数の設定（デフォルト値）
GLANCE_DBPASS=${GLANCE_DBPASS:-"password123"}
GLANCE_PASS=${GLANCE_PASS:-"password123"}
RABBIT_PASS=${RABBIT_PASS:-"rabbitmq123"}

CONFIG_FILE="/etc/glance/glance-api.conf"
BACKUP_FILE="${CONFIG_FILE}.orig"

echo "[glance-config] Glance設定ファイルの編集とDB同期中..."

# 設定ファイルのバックアップ（mv方式）
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "  設定ファイルをバックアップ中..."
    sudo mv "${CONFIG_FILE}" "${BACKUP_FILE}"
    echo "✓ バックアップを作成しました: ${BACKUP_FILE}"
else
    echo "✓ バックアップファイルは既に存在します"
fi

# 設定ファイルの新規作成
echo "  設定ファイルを作成中..."
sudo tee "${CONFIG_FILE}" > /dev/null <<EOF
[DEFAULT]
bind_host = 127.0.0.1
transport_url = rabbit://openstack:${RABBIT_PASS}@controller:5672
enabled_backends = fs:file

[glance_store]
default_backend = fs

[fs]
filesystem_store_datadir = /var/lib/glance/images/

[database]
connection = mysql+pymysql://glance:${GLANCE_DBPASS}@controller/glance

[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = ${GLANCE_PASS}
insecure = true

[paste_deploy]
flavor = keystone

[oslo_policy]
enforce_new_defaults = true
EOF
echo "✓ 設定ファイルを作成しました"

# イメージ保存ディレクトリの権限確認
echo "  イメージ保存ディレクトリの権限を確認中..."
if [ ! -d "/var/lib/glance/images" ]; then
    sudo mkdir -p /var/lib/glance/images
    echo "✓ イメージディレクトリを作成しました"
fi

sudo chown -R glance:glance /var/lib/glance/images
sudo chmod 750 /var/lib/glance/images
echo "✓ イメージディレクトリの権限を設定しました"

# データベースの同期
echo "  データベースを同期中..."
if sudo mysql -u root -p"${GLANCE_DBPASS}" -e "USE glance; SHOW TABLES;" 2>/dev/null | grep -q images; then
    echo "✓ データベーススキーマは既に同期されています"
else
    sudo -u glance glance-manage db_sync
    echo "✓ データベースを同期しました"
fi

# データベーステーブルの確認
echo "  データベーステーブルを確認中..."
TABLE_COUNT=$(sudo mysql -u root -p"${GLANCE_DBPASS}" -e "USE glance; SHOW TABLES;" 2>/dev/null | wc -l)
if [ "${TABLE_COUNT}" -gt 5 ]; then
    echo "✓ データベーステーブル: ${TABLE_COUNT}個"
else
    echo "× データベーステーブルが不足しています"
    exit 1
fi

echo "[glance-config] 完了"
