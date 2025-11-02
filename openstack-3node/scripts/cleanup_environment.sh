#!/bin/bash
# OpenStack学習環境のクリーンアップスクリプト (macOS/Linux)
#
# 機能:
#   - Vagrant VMの削除
#   - VirtualBox Host-Only Networkアダプタの削除
#   - その他のリソースのクリーンアップ
#
# 使用方法:
#   bash cleanup_environment.sh
#   または
#   chmod +x cleanup_environment.sh && ./cleanup_environment.sh
#
# 警告:
#   このスクリプトは全てのVMとネットワークを削除します。
#   実行前に必要なデータのバックアップを取ってください。

set -e

echo "========================================"
echo "OpenStack学習環境 - クリーンアップ"
echo "========================================"
echo ""
echo "警告: このスクリプトは以下のリソースを削除します:"
echo "  - 全てのVagrant VM (controller, network, compute1)"
echo "  - VirtualBox Host-Only Network (172.16.100.0/24)"
echo ""
read -p "続行してもよろしいですか? (yes/no): " -r
echo ""
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "クリーンアップをキャンセルしました。"
    exit 0
fi

# VBoxManageの存在確認
if ! command -v VBoxManage &> /dev/null; then
    echo "警告: VBoxManageが見つかりません。"
    echo "VirtualBoxがインストールされていない可能性があります。"
    echo "Vagrant VMの削除のみ続行します。"
    SKIP_VBOX=true
else
    SKIP_VBOX=false
fi

# Vagrantの存在確認
if ! command -v vagrant &> /dev/null; then
    echo "警告: vagrantコマンドが見つかりません。"
    echo "Vagrant VMの削除をスキップします。"
    SKIP_VAGRANT=true
else
    SKIP_VAGRANT=false
fi

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "[1/3] Vagrant VMを削除中..."

if [ "$SKIP_VAGRANT" = false ]; then
    # Vagrantfileがあるディレクトリに移動
    cd "$PROJECT_DIR"

    if [ -f "Vagrantfile" ]; then
        # Vagrant VMを強制削除
        vagrant destroy -f 2>&1 | grep -v "default: Are you sure" || true
        echo "✓ Vagrant VMを削除しました"

        # Vagrantボックスのクリーンアップ（オプション）
        echo ""
        read -p "未使用のVagrantボックスも削除しますか? (yes/no): " -r
        if [[ $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
            echo "未使用のVagrantボックスを削除中..."
            vagrant box prune -f || true
            echo "✓ 未使用のVagrantボックスを削除しました"
        fi
    else
        echo "× Vagrantfileが見つかりません。スキップします。"
    fi
else
    echo "× Vagrantが見つからないため、VM削除をスキップします。"
fi

echo ""
echo "[2/3] VirtualBox Host-Only Networkを削除中..."

if [ "$SKIP_VBOX" = false ]; then
    # 既存のHost-Only Networkアダプタをリスト取得
    HOSTONLYIFS=$(VBoxManage list hostonlyifs 2>/dev/null || echo "")

    if [ -n "$HOSTONLYIFS" ]; then
        # 172.16.100.1が設定されているアダプタを探す
        if echo "$HOSTONLYIFS" | grep -q "IPAddress:.*172\.16\.100\.1"; then
            # 上に遡ってName行を探す
            ADAPTER_NAME=$(echo "$HOSTONLYIFS" | grep -B 3 "IPAddress:.*172\.16\.100\.1" | grep "^Name:" | awk '{print $2}' | head -1)
        else
            ADAPTER_NAME=""
        fi

        if [ -n "$ADAPTER_NAME" ]; then
            echo "削除対象のアダプタが見つかりました: $ADAPTER_NAME"

            # DHCPサーバーを削除（存在する場合）
            echo "  - DHCPサーバーを削除中..."
            VBoxManage dhcpserver remove --netname "HostInterfaceNetworking-$ADAPTER_NAME" 2>/dev/null || true

            # Host-Only Networkアダプタを削除
            echo "  - Host-Only Networkアダプタを削除中..."
            VBoxManage hostonlyif remove "$ADAPTER_NAME" 2>/dev/null || {
                # エラーが発生した場合は、VMが接続されている可能性がある
                echo "警告: アダプタの削除に失敗しました。"
                echo "       VMが完全に削除されたことを確認してください。"
                echo "       手動で削除する場合は、VirtualBox GUIから削除してください。"
            }
            echo "✓ VirtualBox Host-Only Networkを削除しました"
        else
            echo "✓ 削除対象のHost-Only Networkアダプタが見つかりませんでした（既に削除済み）"
        fi
    else
        echo "× Host-Only Networkアダプタのリストを取得できませんでした"
    fi
else
    echo "× VBoxManageが見つからないため、ネットワーク削除をスキップします。"
fi

echo ""
echo "[3/3] その他のリソースをクリーンアップ中..."

if [ "$SKIP_VBOX" = false ]; then
    # VirtualBoxの内部ネットワーク（overlay-net）が使用されているかチェック
    # 通常、VMが削除されると自動的にクリーンアップされる
    echo "✓ VirtualBox内部ネットワークのクリーンアップ完了（VM削除時に自動削除）"
fi

# Vagrantの一時ファイルのクリーンアップ（オプション）
if [ "$SKIP_VAGRANT" = false ] && [ -f "$PROJECT_DIR/Vagrantfile" ]; then
    cd "$PROJECT_DIR"
    if [ -d ".vagrant" ]; then
        echo "  - Vagrantメタデータを削除中..."
        rm -rf .vagrant
        echo "✓ Vagrantメタデータを削除しました"
    fi
fi

echo ""
echo "========================================"
echo "クリーンアップ完了"
echo "========================================"
echo ""
echo "削除されたリソース:"
echo "  ✓ Vagrant VM (controller, network, compute1)"
echo "  ✓ VirtualBox Host-Only Network (172.16.100.0/24)"
echo "  ✓ Vagrantメタデータ (.vagrant)"
echo ""
echo "注意:"
echo "  - VirtualBox GUIからVMが完全に削除されたことを確認してください"
echo "  - 再度環境を構築する場合は、setup_vbox_network.shを実行してください"
echo ""
