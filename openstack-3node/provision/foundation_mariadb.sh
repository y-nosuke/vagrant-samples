#!/bin/bash
# MariaDBのインストールと設定（コントローラノード専用）

set -euo pipefail

# パスワード設定（環境変数から取得、デフォルト値あり）
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}

echo "[mariadb] MariaDBのインストールと設定中..."
if ! command -v mysql &> /dev/null; then
    # MariaDBのインストール
    DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server mariadb-client python3-pymysql

    # MariaDBサービスの起動
    systemctl enable mariadb
    systemctl start mariadb

    # rootパスワードの設定
    mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${MARIADB_ROOT_PASSWORD}');" || \
    mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MARIADB_ROOT_PASSWORD}';" || true

    # リモート接続の設定
    mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF || true
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF

    # 文字コード設定（UTF-8）
    sed -i '/\[mysqld\]/a character-set-server = utf8mb4\ncollation-server = utf8mb4_unicode_ci' /etc/mysql/mariadb.conf.d/50-server.cnf

    systemctl restart mariadb
    echo "✓ MariaDBをインストール・設定しました"
else
    echo "✓ MariaDBは既にインストール済みです"
fi

systemctl is-active --quiet mariadb && echo "✓ MariaDBが動作中"
