#!/bin/bash
# Keystoneデータベースの作成（コントローラノード専用）

set -euo pipefail

# パスワード設定（環境変数から取得、デフォルト値あり）
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}
KEYSTONE_DBPASS=${KEYSTONE_DBPASS:-"keystone123"}

echo "[keystone-db] Keystoneデータベースの作成中..."
mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF || true
CREATE DATABASE IF NOT EXISTS keystone CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY '${KEYSTONE_DBPASS}';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY '${KEYSTONE_DBPASS}';
FLUSH PRIVILEGES;
EOF
echo "✓ Keystoneデータベースを作成しました"
