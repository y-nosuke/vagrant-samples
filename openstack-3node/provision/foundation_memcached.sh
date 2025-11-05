#!/bin/bash
# Memcachedのインストールと設定（コントローラノード専用）

set -euo pipefail

echo "[memcached] Memcachedのインストールと設定中..."
if ! command -v memcached &> /dev/null; then
    apt-get install -y memcached python3-memcache

    # 設定ファイルの編集（localhost:11211でリスン）
    sed -i 's/-l 127.0.0.1/-l 127.0.0.1,::1/' /etc/memcached.conf

    # Memcachedサービスの起動
    systemctl enable memcached
    systemctl restart memcached

    echo "✓ Memcachedをインストール・設定しました"
else
    echo "✓ Memcachedは既にインストール済みです"
    systemctl enable memcached
    systemctl restart memcached
fi

systemctl is-active --quiet memcached && echo "✓ Memcachedが動作中"
