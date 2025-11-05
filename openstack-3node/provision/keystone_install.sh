#!/bin/bash
# Keystoneのインストール（コントローラノード専用）

set -euo pipefail

echo "[keystone-install] Keystoneパッケージのインストール中..."
if ! dpkg -l | grep -q "^ii.*keystone"; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y keystone python3-openstackclient apache2 libapache2-mod-wsgi-py3 python3-oauth2client
    echo "✓ Keystoneパッケージをインストールしました"
else
    echo "✓ Keystoneパッケージは既にインストール済みです"
fi

# Keystoneユーザーの作成
id -u keystone > /dev/null 2>&1 || adduser --system --group --shell /bin/false keystone
echo "✓ Keystoneユーザーを作成しました"


