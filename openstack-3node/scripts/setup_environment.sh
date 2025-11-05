#!/bin/bash
# OpenStack学習環境の構築スクリプト (macOS/Linux)
#
# 機能:
#   - Host-Only Networkの作成
#   - ブリッジネットワークの確認
#   - Vagrant VMの起動（vagrant up）
#
# 使用方法:
#   bash setup_environment.sh
#   または
#   chmod +x setup_environment.sh && ./setup_environment.sh
#
# 注意:
#   - cleanup_environment.shの逆の操作を行います

set -e

echo "========================================"
echo "OpenStack学習環境 - 環境構築"
echo "========================================"
echo ""

# スクリプトのディレクトリを取得
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SETUP_NETWORK_SCRIPT="$SCRIPT_DIR/setup_vbox_network.sh"

# VBoxManageの存在確認
if ! command -v VBoxManage &> /dev/null; then
    echo "エラー: VBoxManageが見つかりません。"
    echo "VirtualBoxがインストールされているか確認してください。"
    echo "確認スクリプトを実行: bash scripts/check_environment.sh"
    exit 1
fi

# Vagrantの存在確認
if ! command -v vagrant &> /dev/null; then
    echo "エラー: vagrantコマンドが見つかりません。"
    echo "Vagrantがインストールされているか確認してください。"
    echo "確認スクリプトを実行: bash scripts/check_environment.sh"
    exit 1
fi

# Vagrantfileの存在確認
if [ ! -f "$PROJECT_DIR/Vagrantfile" ]; then
    echo "エラー: Vagrantfileが見つかりません。"
    echo "プロジェクトディレクトリ ($PROJECT_DIR) にVagrantfileが存在するか確認してください。"
    exit 1
fi

# ========================================
# [1/3] Host-Only Networkの作成
# ========================================
echo "[1/3] Host-Only Networkを設定中..."

if [ -f "$SETUP_NETWORK_SCRIPT" ]; then
    bash "$SETUP_NETWORK_SCRIPT"
    if [ $? -eq 0 ]; then
        echo "✓ Host-Only Networkの設定が完了しました"
    else
        echo "× ネットワーク設定スクリプトの実行に失敗しました"
        echo "  手動で setup_vbox_network.sh を実行してください"
        exit 1
    fi
else
    echo "× ネットワーク設定スクリプトが見つかりません: $SETUP_NETWORK_SCRIPT"
    echo "  手動で setup_vbox_network.sh を実行してください"
    exit 1
fi

echo ""

# ========================================
# [2/3] ブリッジネットワークの確認
# ========================================
echo "[2/3] ブリッジネットワークを確認中..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    DEFAULT_ROUTE=$(route get default 2>/dev/null | grep interface | awk '{print $2}' || echo "")
    if [ -n "$DEFAULT_ROUTE" ]; then
        INTERFACE_NAME=$(ifconfig "$DEFAULT_ROUTE" 2>/dev/null | grep "^[a-z]" | awk '{print $1}' | sed 's/:$//' || echo "")
        if [ -n "$INTERFACE_NAME" ]; then
            echo "✓ 使用可能な物理ネットワークアダプタ:"
            echo "  - $INTERFACE_NAME (デフォルトルート)"
        fi
    fi

    # すべての物理インターフェースをリスト
    ALL_INTERFACES=$(ifconfig -l | tr ' ' '\n' | grep -E '^en[0-9]|^eth[0-9]' || echo "")
    if [ -n "$ALL_INTERFACES" ]; then
        echo "  その他のインターフェース:"
        echo "$ALL_INTERFACES" | while read -r iface; do
            echo "  - $iface"
        done
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    PHYSICAL_ADAPTERS=$(ip link show | grep -E "^[0-9]+: (en|eth|wl)" | awk -F: '{print $2}' | awk '{print $1}' || echo "")
    if [ -n "$PHYSICAL_ADAPTERS" ]; then
        echo "✓ 使用可能な物理ネットワークアダプタ:"
        echo "$PHYSICAL_ADAPTERS" | while read -r adapter; do
            echo "  - $adapter"
        done
    else
        echo "警告: 使用可能な物理ネットワークアダプタが見つかりませんでした"
        echo "  ブリッジネットワークを使用する場合は、物理アダプタが必要です"
    fi
fi

echo ""
echo "  注: Vagrantfileで自動検出を試みます"
echo "  自動検出が失敗する場合は、環境変数で指定してください:"
echo "    export BRIDGE_INTERFACE=\"アダプタ名\""
echo "    その後、このスクリプトを再実行してください"
echo ""

# ========================================
# [3/3] Vagrant VMの起動
# ========================================
echo "[3/3] Vagrant VMを起動中..."

# VirtualBox VMsフォルダのパスを動的に取得
echo "  VirtualBox VMsフォルダを検出中..."
VMS_FOLDER=""

# VBoxManage list systemproperties でデフォルトマシンフォルダを取得
if SYSTEM_PROPS=$(VBoxManage list systemproperties 2>/dev/null); then
    DEFAULT_MACHINE_FOLDER=$(echo "$SYSTEM_PROPS" | grep "Default machine folder:" | cut -d: -f2 | sed 's/^[[:space:]]*//')
    if [ -n "$DEFAULT_MACHINE_FOLDER" ]; then
        VMS_FOLDER="$DEFAULT_MACHINE_FOLDER"
        echo "  ✓ VirtualBox VMsフォルダ: $VMS_FOLDER"
    else
        echo "  × VirtualBox VMsフォルダの検出に失敗しました"
        echo "    デフォルトパスを使用します"
        # デフォルトパス（環境変数または標準パス）
        if [ -n "$VBOX_USER_HOME" ]; then
            VMS_FOLDER="$VBOX_USER_HOME/VirtualBox VMs"
        else
            VMS_FOLDER="$HOME/VirtualBox VMs"
        fi
    fi
else
    echo "  × VirtualBox VMsフォルダの検出中にエラーが発生しました"
    echo "    デフォルトパスを使用します"
    # デフォルトパス（環境変数または標準パス）
    if [ -n "$VBOX_USER_HOME" ]; then
        VMS_FOLDER="$VBOX_USER_HOME/VirtualBox VMs"
    else
        VMS_FOLDER="$HOME/VirtualBox VMs"
    fi
fi

# 既存のVMフォルダを削除（Vagrantfileで定義されているVM名）
VM_NAMES=("openstack-controller" "openstack-network" "openstack-compute1")
DELETED_COUNT=0

if [ -n "$VMS_FOLDER" ] && [ -d "$VMS_FOLDER" ]; then
    echo "  既存のVMフォルダを確認中..."
    for VM_NAME in "${VM_NAMES[@]}"; do
        VM_FOLDER_PATH="$VMS_FOLDER/$VM_NAME"
        if [ -d "$VM_FOLDER_PATH" ]; then
            echo "    既存のVMフォルダを削除中: $VM_NAME"
            if rm -rf "$VM_FOLDER_PATH" 2>/dev/null; then
                echo "    ✓ 削除しました: $VM_NAME"
                DELETED_COUNT=$((DELETED_COUNT + 1))
            else
                echo "    × 削除に失敗しました: $VM_NAME"
                echo "      手動で削除してください: $VM_FOLDER_PATH"
            fi
        fi
    done
    if [ $DELETED_COUNT -eq 0 ]; then
        echo "  ✓ 既存のVMフォルダは見つかりませんでした"
    else
        echo "  ✓ $DELETED_COUNT 個の既存VMフォルダを削除しました"
    fi
else
    echo "  × VirtualBox VMsフォルダが見つかりません: $VMS_FOLDER"
    echo "    既存VMフォルダの削除をスキップします"
fi

echo ""

# プロジェクトディレクトリに移動
cd "$PROJECT_DIR"

echo "  初回起動は20-30分かかります..."
echo "  ベースイメージのダウンロードとVM作成が行われます"
echo ""

# vagrant upを実行
vagrant up
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo "✓ Vagrant VMの起動が完了しました"
else
    echo "× Vagrant VMの起動に失敗しました (終了コード: $EXIT_CODE)"
    echo "  エラーメッセージを確認してください"
    exit $EXIT_CODE
fi

echo ""
echo "========================================"
echo "環境構築完了"
echo "========================================"
echo ""
echo "作成されたリソース:"
echo "  ✓ VirtualBox Host-Only Network (172.16.100.0/24)"
echo "  ✓ Vagrant VM (controller, network, compute1)"
echo ""
echo "次のステップ:"
echo "  1. vagrant status でVM状態を確認"
echo "  2. vagrant ssh controller でControllerノードに接続"
echo "  3. docs/phase1_environment_setup.md を参照してネットワーク疎通確認"
echo ""
echo "参考:"
echo "  - ドキュメント: docs/phase1_environment_setup.md"
echo "  - Vagrantfile: Vagrantfile"
echo ""

