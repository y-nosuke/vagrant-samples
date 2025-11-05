#!/bin/bash
# OpenStackリポジトリの追加（全ノード共通）

set -euo pipefail

echo "[repository] OpenStackリポジトリの追加中..."
if ! grep -q "cloud-archive:epoxy" /etc/apt/sources.list /etc/apt/sources.list.d/* 2>/dev/null; then
    apt-get update
    apt-get upgrade -y

    # add-apt-repositoryコマンドに必要なパッケージのインストール
    if ! command -v add-apt-repository &> /dev/null; then
        apt-get install -y software-properties-common
    fi

    add-apt-repository cloud-archive:epoxy -y
    apt-get update
    echo "✓ OpenStack Epoxyリポジトリを追加しました"
else
    echo "✓ OpenStack Epoxyリポジトリは既に追加済みです"
    apt-get update
fi

# OpenStackクライアントのインストール
if ! command -v openstack &> /dev/null; then
    apt-get install -y python3-openstackclient
    echo "✓ OpenStackクライアントをインストールしました"
else
    echo "✓ OpenStackクライアントは既にインストール済みです"
fi
