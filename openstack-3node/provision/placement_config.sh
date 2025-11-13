#!/bin/bash
# Placement設定ファイルの編集とDB同期

set -euo pipefail

# 環境変数の設定（デフォルト値）
PLACEMENT_DBPASS=${PLACEMENT_DBPASS:-"password123"}
PLACEMENT_PASS=${PLACEMENT_PASS:-"password123"}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}

CONFIG_FILE="/etc/placement/placement.conf"
BACKUP_FILE="${CONFIG_FILE}.orig"

echo "[placement-config] Placement設定ファイルの編集とDB同期中..."

# 設定ファイルのバックアップ
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "  設定ファイルをバックアップ中..."
    sudo mv "${CONFIG_FILE}" "${BACKUP_FILE}"
    echo "✓ バックアップを作成しました: ${BACKUP_FILE}"
else
    echo "✓ バックアップファイルは既に存在します"
fi

# 設定ファイルの編集
echo "  設定ファイルを編集中..."
sudo tee "${CONFIG_FILE}" > /dev/null <<EOF
[placement_database]
connection = mysql+pymysql://placement:${PLACEMENT_DBPASS}@controller/placement

[api]
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = ${PLACEMENT_PASS}
insecure = true
EOF
echo "✓ 設定ファイルを編集しました"

# 設定ファイルのパーミッション設定
echo "  設定ファイルのパーミッションを設定中..."
sudo chmod 640 "${CONFIG_FILE}"
sudo chgrp placement "${CONFIG_FILE}"
echo "✓ 設定ファイルのパーミッションを設定しました"

# データベースの同期
echo "  データベースを同期中..."
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE placement; SHOW TABLES;" 2>/dev/null | grep -q .; then
    echo "✓ Placementデータベーススキーマは既に同期されています"
else
    sudo su -s /bin/bash placement -c "placement-manage db sync"
    echo "✓ Placementデータベースを同期しました"
fi

# データベーステーブルの確認
echo "  データベーステーブルを確認中..."
TABLE_COUNT=$(sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE placement; SHOW TABLES;" 2>/dev/null | wc -l)
if [ "${TABLE_COUNT}" -gt 5 ]; then
    echo "✓ placementデータベーステーブル: ${TABLE_COUNT}個"
else
    echo "× placementデータベーステーブルが不足しています"
    exit 1
fi

echo "[placement-config] 完了"

