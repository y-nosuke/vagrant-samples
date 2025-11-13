#!/bin/bash
# Nova Computeパッケージのインストール（コンピュートノード）

set -euo pipefail

echo "[nova-compute-install] Nova Computeパッケージのインストール中..."

# Nova Computeパッケージのインストール
echo "  Nova Computeパッケージをインストール中..."
if dpkg -l | grep -q "^ii.*nova-compute"; then
    echo "✓ Nova Computeパッケージは既にインストールされています"
else
    sudo apt update
    sudo DEBIAN_FRONTEND=noninteractive apt install -y nova-compute
    echo "✓ Nova Computeパッケージをインストールしました"
fi

# インストール確認
if dpkg -l | grep -q "^ii.*nova-compute"; then
    echo "✓ Nova Computeパッケージ: インストール済み"
else
    echo "× Nova Computeパッケージ: インストール失敗"
    exit 1
fi

echo "[nova-compute-install] 完了"

