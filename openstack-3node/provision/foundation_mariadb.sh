#!/bin/bash
# MariaDBのインストールと設定（コントローラノード専用）
#
# 注意: セキュリティ設定について
# - 現在の実装: SQLを直接実行してセキュリティ設定を行う（依存関係なし、シンプル）
# - 代替方法: mysql_secure_installationを使う場合は、expectパッケージが必要
#   例: apt-get install -y expect
#   その後、expectスクリプトでmysql_secure_installationを自動実行可能

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

    # セキュリティ設定（mysql_secure_installation相当の処理）
    # 注意: mysql_secure_installationを使う場合はexpectが必要ですが、
    #       現在の方法（SQL直接実行）は依存関係が少なく、シンプルです
    mysql -u root -p"${MARIADB_ROOT_PASSWORD}" <<EOF || true
-- 匿名ユーザーの削除
DELETE FROM mysql.user WHERE User='';
-- リモート接続用rootユーザーの削除（セキュリティ強化）
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
-- testデータベースの削除
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
-- 権限テーブルの再読み込み
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
