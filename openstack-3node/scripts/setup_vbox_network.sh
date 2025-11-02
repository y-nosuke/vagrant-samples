#!/bin/bash
# OpenStack学習環境用 VirtualBox Host-Only Network セットアップスクリプト (macOS/Linux)
#
# 機能:
#   - VirtualBox Host-Only Networkアダプタの作成
#   - 管理ネットワーク (172.16.100.0/24) の設定
#   - DHCPサーバーの無効化
#
# 使用方法:
#   bash setup_vbox_network.sh
#   または
#   chmod +x setup_vbox_network.sh && ./setup_vbox_network.sh

set -e

echo "========================================"
echo "OpenStack学習環境 - ネットワーク設定"
echo "========================================"
echo ""

# VBoxManageの存在確認
if ! command -v VBoxManage &> /dev/null; then
    echo "エラー: VBoxManageが見つかりません。"
    echo "VirtualBoxがインストールされているか確認してください。"
    exit 1
fi

echo "[1/4] 既存のHost-Only Networkアダプタを確認中..."

# 既存のHost-Only Networkアダプタをリスト取得
HOSTONLYIFS=$(VBoxManage list hostonlyifs)

# 172.16.100.1のアダプタが既に存在するか確認
if echo "$HOSTONLYIFS" | grep -q "IPAddress:.*172\.16\.100\.1"; then
    ADAPTER_NAME=$(echo "$HOSTONLYIFS" | grep -B 3 "IPAddress:.*172\.16\.100\.1" | grep "^Name:" | awk '{print $2}')
    echo "✓ 管理ネットワーク用アダプタが既に存在します: $ADAPTER_NAME"
    ADAPTER_EXISTS=true
else
    echo "× 管理ネットワーク用アダプタが見つかりません。"
    ADAPTER_EXISTS=false
fi

if [ "$ADAPTER_EXISTS" = false ]; then
    echo ""
    echo "[2/4] Host-Only Networkアダプタを作成中..."

    # Host-Only Networkアダプタを作成
    CREATE_OUTPUT=$(VBoxManage hostonlyif create 2>&1)

    # 作成されたアダプタ名を取得
    ADAPTER_NAME=$(echo "$CREATE_OUTPUT" | grep -oE "vboxnet[0-9]+|'[^']+'" | tr -d "'")

    if [ -z "$ADAPTER_NAME" ]; then
        echo "エラー: アダプタ名の取得に失敗しました"
        echo "$CREATE_OUTPUT"
        exit 1
    fi

    echo "✓ アダプタを作成しました: $ADAPTER_NAME"

    echo ""
    echo "[3/4] IPアドレスを設定中..."

    # IPアドレスとネットマスクを設定
    VBoxManage hostonlyif ipconfig "$ADAPTER_NAME" --ip 172.16.100.1 --netmask 255.255.255.0
    echo "✓ IPアドレスを設定しました: 172.16.100.1/24"

    echo ""
    echo "[4/4] DHCPサーバーを無効化中..."

    # DHCPサーバーを無効化（静的IP使用のため）
    # エラーが出ても続行（DHCPサーバーが存在しない場合）
    VBoxManage dhcpserver remove --netname "HostInterfaceNetworking-$ADAPTER_NAME" 2>/dev/null || true
    echo "✓ DHCPサーバーを無効化しました"
fi

echo ""
echo "========================================"
echo "設定完了"
echo "========================================"
echo ""
echo "管理ネットワーク設定:"
echo "  ネットワーク: 172.16.100.0/24"
echo "  ゲートウェイ: 172.16.100.1 (ホストOS)"
echo "  アダプタ名: $ADAPTER_NAME"
echo ""
echo "ノードIPアドレス:"
echo "  Controller: 172.16.100.10"
echo "  Network:    172.16.100.20"
echo "  Compute1:   172.16.100.31"
echo ""
echo "次のステップ:"
echo "  1. vagrant up を実行してVMを起動"
echo "  2. ssh vagrant@172.16.100.10 でControllerノードに接続可能"
echo ""
