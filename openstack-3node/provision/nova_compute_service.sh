#!/bin/bash
# Nova Computeサービスの起動（コンピュートノード）

set -euo pipefail

echo "[nova-compute-service] Nova Computeサービスの起動中..."

# Nova Computeサービスの起動
echo "  nova-computeサービスを起動中..."
sudo systemctl restart nova-compute
sudo systemctl enable nova-compute
echo "✓ nova-computeサービスを起動しました"

# サービスの状態確認
echo "  サービスの状態を確認中..."
if sudo systemctl is-active --quiet nova-compute; then
    echo "✓ nova-compute: running"
else
    echo "× nova-compute: not running"
    echo "  ログを確認してください:"
    echo "    sudo journalctl -u nova-compute -n 50"
    exit 1
fi

# ログの確認（エラーチェック）
echo "  ログを確認中..."
if sudo journalctl -u nova-compute -n 20 --no-pager | grep -i error | head -5; then
    echo "  警告: ログにエラーが含まれています"
    echo "  詳細を確認してください:"
    echo "    sudo journalctl -u nova-compute -n 50"
else
    echo "✓ ログに重大なエラーは見つかりませんでした"
fi

echo "[nova-compute-service] 完了"

