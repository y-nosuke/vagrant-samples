#!/bin/bash
# Keystone設定ファイルの編集（コントローラノード専用）

set -euo pipefail

# パスワード設定（環境変数から取得、デフォルト値あり）
KEYSTONE_DBPASS=${KEYSTONE_DBPASS:-"keystone123"}

echo "[keystone-config] Keystone設定ファイルの設定中..."
if [ ! -f /etc/keystone/keystone.conf.backup ]; then
    cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.backup
fi

# databaseセクションの設定
sed -i '/^\[database\]/,/^\[/ { 
    /^connection =/d
    /^\[database\]/a connection = mysql+pymysql://keystone:'"${KEYSTONE_DBPASS}"'@controller/keystone
}' /etc/keystone/keystone.conf

# tokenセクションの設定
sed -i '/^\[token\]/,/^\[/ {
    /^provider =/d
    /^#provider =/d
    /^\[token\]/a provider = fernet
}' /etc/keystone/keystone.conf

# cacheセクションの設定（memcache_servers）
if ! grep -q "^\[cache\]" /etc/keystone/keystone.conf; then
    echo "" >> /etc/keystone/keystone.conf
    echo "[cache]" >> /etc/keystone/keystone.conf
    echo "memcache_servers = controller:11211" >> /etc/keystone/keystone.conf
else
    sed -i '/^\[cache\]/,/^\[/ {
        /^memcache_servers =/d
        /^#memcache_servers =/d
        /^\[cache\]/a memcache_servers = controller:11211
    }' /etc/keystone/keystone.conf
fi

echo "✓ Keystone設定ファイルを更新しました"

# データベースの同期
echo "[keystone-config] データベーススキーマの同期中..."
su -s /bin/bash keystone -c "keystone-manage db_sync"
echo "✓ データベーススキーマを同期しました"

# FernetキーとCredentialキーの生成
echo "[keystone-config] Fernet/Credentialキーの生成中..."
if [ ! -d /etc/keystone/fernet-keys ]; then
    keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
    echo "✓ Fernetキーを生成しました"
else
    echo "✓ Fernetキーは既に生成済みです"
fi

if [ ! -d /etc/keystone/credential-keys ]; then
    keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
    echo "✓ Credentialキーを生成しました"
else
    echo "✓ Credentialキーは既に生成済みです"
fi


