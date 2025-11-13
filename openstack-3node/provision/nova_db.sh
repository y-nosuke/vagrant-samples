#!/bin/bash
# Novaデータベースの作成

set -euo pipefail

# 環境変数の設定（デフォルト値）
NOVA_DBPASS=${NOVA_DBPASS:-"password123"}
PLACEMENT_DBPASS=${PLACEMENT_DBPASS:-"password123"}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}

echo "[nova-db] Novaデータベースの作成中..."

# Novaデータベースの存在確認と作成
for db in nova_api nova nova_cell0; do
    if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE ${db};" 2>/dev/null; then
        echo "✓ ${db}データベースは既に存在します"
    else
        echo "  ${db}データベースを作成中..."
        sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE ${db} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON ${db}.* TO 'nova'@'localhost' IDENTIFIED BY '${NOVA_DBPASS}';
GRANT ALL PRIVILEGES ON ${db}.* TO 'nova'@'%' IDENTIFIED BY '${NOVA_DBPASS}';
FLUSH PRIVILEGES;
EOF
        echo "✓ ${db}データベースを作成しました"
    fi
done

# Placementデータベースの存在確認と作成
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE placement;" 2>/dev/null; then
    echo "✓ placementデータベースは既に存在します"
else
    echo "  placementデータベースを作成中..."
    sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF
CREATE DATABASE placement CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY '${PLACEMENT_DBPASS}';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY '${PLACEMENT_DBPASS}';
FLUSH PRIVILEGES;
EOF
    echo "✓ placementデータベースを作成しました"
fi

# データベースとユーザーの確認
echo "  データベースとユーザーを確認中..."
for db in nova_api nova nova_cell0 placement; do
    sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW DATABASES;" | grep -q "${db}" && echo "✓ ${db}データベース: 存在"
done
sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT host, user FROM mysql.user WHERE user = 'nova';" | grep -q "nova" && echo "✓ novaユーザー: 存在"
sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SELECT host, user FROM mysql.user WHERE user = 'placement';" | grep -q "placement" && echo "✓ placementユーザー: 存在"

# データベース接続テスト
for db in nova_api nova nova_cell0; do
    if mysql -h controller -u nova -p"${NOVA_DBPASS}" -e "USE ${db};" 2>/dev/null; then
        echo "✓ ${db}データベース接続テスト: 成功"
    else
        echo "× ${db}データベース接続テスト: 失敗"
        exit 1
    fi
done

# placementデータベース接続テスト
if mysql -h controller -u placement -p"${PLACEMENT_DBPASS}" -e "USE placement;" 2>/dev/null; then
    echo "✓ placementデータベース接続テスト: 成功"
else
    echo "× placementデータベース接続テスト: 失敗"
    exit 1
fi

echo "[nova-db] 完了"

