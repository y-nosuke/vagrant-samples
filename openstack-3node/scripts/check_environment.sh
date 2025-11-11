#!/bin/bash
# OpenStack学習環境の前提条件確認スクリプト (macOS/Linux)
#
# 機能:
#   - 仮想化支援機能の確認（Intel VT-x / AMD-V）
#   - VirtualBoxのインストール確認
#   - Vagrantのインストール確認
#   - ブリッジネットワークの確認
#
# 使用方法:
#   bash check_environment.sh
#   または
#   chmod +x check_environment.sh && ./check_environment.sh

set -e

echo "========================================"
echo "OpenStack学習環境 - 前提条件確認"
echo "========================================"
echo ""

# チェック結果を記録
ALL_CHECKS_PASSED=true

# ========================================
# [1/4] 仮想化支援機能の確認
# ========================================
echo "[1/4] 仮想化支援機能を確認中..."

if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    ARCH=$(uname -m)

    if [[ "$ARCH" == "arm64" ]]; then
        # Apple Silicon (M1/M2/M3など)
        echo "✓ Apple Silicon Macを検出しました ($ARCH)"
        echo "  注: Apple Siliconでは仮想化は常に有効です"
        echo ""

        # VirtualBoxのバージョンをチェック（インストールされている場合）
        if command -v VBoxManage &> /dev/null; then
            VBOX_VERSION=$(VBoxManage --version 2>/dev/null || echo "")
            if [[ -n "$VBOX_VERSION" ]]; then
                # バージョン番号を抽出（例: "7.2.4r170995" -> "7.2.4"）
                VBOX_MAJOR_MINOR=$(echo "$VBOX_VERSION" | cut -d'r' -f1 | cut -d'.' -f1-2)
                VBOX_MAJOR=$(echo "$VBOX_MAJOR_MINOR" | cut -d'.' -f1)
                VBOX_MINOR=$(echo "$VBOX_MAJOR_MINOR" | cut -d'.' -f2)

                # バージョン7.1以上でApple Silicon対応
                if [[ "$VBOX_MAJOR" -gt 7 ]] || [[ "$VBOX_MAJOR" -eq 7 && "$VBOX_MINOR" -ge 1 ]]; then
                    echo "✓ VirtualBox $VBOX_VERSION はApple Siliconに対応しています"
                    echo "  (VirtualBox 7.1以降でApple Siliconサポートが追加されました)"
                    echo ""
                    echo "  注意: 一部の機能やパフォーマンスに制限がある可能性があります"
                    echo "  - x86_64ゲストOSはエミュレーションモードで動作（パフォーマンス低下）"
                    echo "  - ARMゲストOS（Windows 11 ARM版など）はネイティブで動作"
                else
                    echo ":warning:  VirtualBox $VBOX_VERSION はApple Siliconに対応していません"
                    echo "  Apple SiliconサポートにはVirtualBox 7.1以降が必要です"
                    echo "  アップグレード方法: brew upgrade --cask virtualbox"
                    echo "  または公式サイト: https://www.virtualbox.org/wiki/Downloads"
                    echo ""
                    echo "  推奨される代替案:"
                    echo "    - UTM (https://mac.getutm.app/) - 無料、オープンソース"
                    echo "    - Parallels Desktop - 有料、高性能"
                    echo "    - VMware Fusion - 有料、企業向け"
                fi
            fi
        else
            echo ":information_source:  VirtualBoxがインストールされていません"
            echo "  VirtualBox 7.1以降をインストールすると、Apple Siliconに対応します"
            echo "  インストール方法: brew install --cask virtualbox"
            echo "  公式サイト: https://www.virtualbox.org/wiki/Downloads"
        fi
        # Apple Siliconでは仮想化は常に有効なので、チェックはパス
    elif [[ "$ARCH" == "x86_64" ]]; then
        # Intel Mac
        if sysctl -a 2>/dev/null | grep -q "machdep.cpu.features.*VMX"; then
            echo "✓ 仮想化支援機能が有効です (Intel VT-x)"
        else
            echo "× 仮想化支援機能が無効または確認できませんでした"
            echo "  警告: VirtualBoxでVMを実行するには、仮想化支援機能が必要です"
            echo ""
            echo "  対処方法:"
            echo "  1. Macを再起動し、起動音が聞こえたら Command(⌘) + R を押し続けて"
            echo "     リカバリーモードに入ります"
            echo "  2. メニューバーから「ユーティリティ」→「ターミナル」を選択"
            echo "  3. ターミナルで以下を実行（セキュリティ設定を一時的に無効化）:"
            echo "     csrutil disable"
            echo "  4. Macを再起動"
            echo "  5. 仮想化ソフトウェアをインストール・使用"
            echo "  6. 使用後、セキュリティを再度有効化するため、リカバリーモードで:"
            echo "     csrutil enable"
            echo ""
            echo "  注意: csrutil disableはセキュリティを低下させるため、"
            echo "        通常は推奨されません。まずは以下を確認してください:"
            echo "  - システム設定 > プライバシーとセキュリティで仮想化関連の設定を確認"
            echo "  - VirtualBoxの最新版を使用しているか確認"
            ALL_CHECKS_PASSED=false
        fi
    else
        echo "警告: 不明なアーキテクチャ ($ARCH) を検出しました"
        ALL_CHECKS_PASSED=false
    fi
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    if grep -qE '(vmx|svm)' /proc/cpuinfo; then
        CPU_FEATURE=$(grep -E '(vmx|svm)' /proc/cpuinfo | head -1 | grep -oE '(vmx|svm)')
        if [[ "$CPU_FEATURE" == "vmx" ]]; then
            echo "✓ 仮想化支援機能が有効です (Intel VT-x)"
        elif [[ "$CPU_FEATURE" == "svm" ]]; then
            echo "✓ 仮想化支援機能が有効です (AMD-V)"
        else
            echo "✓ 仮想化支援機能が有効です"
        fi
    else
        echo "× 仮想化支援機能が無効です"
        echo "  警告: VirtualBoxでVMを実行するには、BIOS/UEFIで仮想化支援機能を有効にする必要があります"
        ALL_CHECKS_PASSED=false
    fi
else
    echo "警告: このOSタイプ ($OSTYPE) での仮想化支援機能確認は未対応です"
fi

echo ""

# ========================================
# [2/4] VirtualBoxのインストール確認
# ========================================
echo "[2/4] VirtualBoxのインストールを確認中..."

if command -v VBoxManage &> /dev/null; then
    VBOX_VERSION=$(VBoxManage --version)
    echo "✓ VirtualBoxがインストールされています: $VBOX_VERSION"
    VBOX_INSTALLED=true
else
    echo "× VirtualBoxがインストールされていません"
    echo "  インストール方法:"
    echo "    macOS: brew install --cask virtualbox"
    echo "    Linux: ディストリビューションのパッケージマネージャーを使用"
    echo "    公式サイト: https://www.virtualbox.org/wiki/Downloads"
    ALL_CHECKS_PASSED=false
    VBOX_INSTALLED=false
fi

echo ""

# ========================================
# [3/4] Vagrantのインストール確認
# ========================================
echo "[3/4] Vagrantのインストールを確認中..."

if command -v vagrant &> /dev/null; then
    VAGRANT_VERSION=$(vagrant --version)
    echo "✓ Vagrantがインストールされています: $VAGRANT_VERSION"
    VAGRANT_INSTALLED=true
else
    echo "× Vagrantがインストールされていません"
    echo "  インストール方法:"
    echo "    macOS: brew install --cask vagrant"
    echo "    Linux: ディストリビューションのパッケージマネージャーを使用"
    echo "    公式サイト: https://www.vagrantup.com/downloads"
    ALL_CHECKS_PASSED=false
    VAGRANT_INSTALLED=false
fi

echo ""

# ========================================
# [4/4] ブリッジネットワークの確認
# ========================================
echo "[4/4] ブリッジネットワークを確認中..."

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
    fi
fi

echo ""
echo "  注: Vagrantfileで自動検出を試みます"
echo "  自動検出が失敗する場合は、環境変数で指定してください:"
echo "    export BRIDGE_INTERFACE=\"アダプタ名\""
echo ""

# ========================================
# 確認結果のサマリー
# ========================================
echo "========================================"
if [ "$ALL_CHECKS_PASSED" = true ]; then
    echo "確認完了 - 全ての前提条件を満たしています"
    echo "========================================"
    echo ""
    echo "次のステップ:"
    echo "  1. setup_environment.sh を実行して環境を構築"
    echo "  2. または、手動で setup_vbox_network.sh を実行後に vagrant up"
else
    echo "確認完了 - 未完了の項目があります"
    echo "========================================"
    echo ""
    echo "未完了の項目があります。上記のエラーメッセージを確認し、必要なインストールや設定を行ってください。"
    echo ""
    echo "必要な作業:"
    if [ "$VBOX_INSTALLED" != true ]; then
        echo "  - VirtualBoxのインストール"
    fi
    if [ "$VAGRANT_INSTALLED" != true ]; then
        echo "  - Vagrantのインストール"
    fi
    echo ""
    echo "全ての項目が完了したら、このスクリプトを再度実行して確認してください。"
fi

echo ""

