#!/bin/bash
# Glanceデータベースの作成

set -euo pipefail

# 環境変数の設定（デフォルト値）
GLANCE_DBPASS=${GLANCE_DBPASS:-"password123"}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}

echo "[glance-db] Glanceデータベースの作成中..."

# データベースの存在確認
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE glance;" 2>/dev/null; then
    echo "✓ glanceデータベースは既に存在します"
else
    echo "  glanceデータベースを作成中..."
    sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE glance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY '${GLANCE_DBPASS}';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY '${GLANCE_DBPASS}';
FLUSH PRIVILEGES;
EOF
    echo "✓ glanceデータベースを作成しました"
fi

# データベースとユーザーの確認
echo "  データベースとユーザーを確認中..."
sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES;" | grep -q "glance" && echo "✓ glanceデータベース: 存在"
sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT host, user FROM mysql.user WHERE user = 'glance';" | grep -q "glance" && echo "✓ glanceユーザー: 存在"

# データベース接続テスト
if mysql -h controller -u glance -p"${GLANCE_DBPASS}" -e "USE glance;" 2>/dev/null; then
    echo "✓ データベース接続テスト: 成功"
else
    echo "× データベース接続テスト: 失敗"
    exit 1
fi

echo "[glance-db] 完了"
