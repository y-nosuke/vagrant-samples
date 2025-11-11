#!/bin/bash

################################################################################
# VirtualBox Host-Only Network Setup Script
################################################################################
#
# 概要:
#   VirtualBoxのHost-Only Networkを作成・設定するスクリプト
#   macOS (特にM1/M2 Mac) と Linux/Windows で異なる方式に対応
#
# 使用方法:
#   ./setup_vbox_network.sh
#
# 対応環境:
#   - macOS (Intel/Apple Silicon) + VirtualBox 7.0以降: Host-Only Network方式
#   - Linux/古いmacOS + VirtualBox 6.x以前: Host-Only Adapter方式
#
# 作成されるネットワーク:
#   - ネットワーク名: vboxnet0
#   - ネットワークアドレス: 192.168.56.0/24
#   - DHCPサーバー範囲: 192.168.56.100 - 192.168.56.199
#
# 注意事項:
#   - VirtualBoxがインストールされている必要があります
#   - macOSの場合、VirtualBox 7.0以降が必要です
#   - 既存のネットワークがある場合は、そのまま使用されます
#
################################################################################

set -e

echo "=================================="
echo "VirtualBox Network Setup"
echo "=================================="
echo ""

# VirtualBoxのバージョン確認
echo "[1/4] Checking VirtualBox version..."
if ! command -v VBoxManage &> /dev/null; then
    echo "ERROR: VBoxManage command not found. Please install VirtualBox first."
    exit 1
fi

VBOX_VERSION=$(VBoxManage --version | cut -d 'r' -f 1)
VBOX_MAJOR=$(echo $VBOX_VERSION | cut -d '.' -f 1)
echo "VirtualBox version: $VBOX_VERSION"
echo ""

# OS判定
echo "[2/4] Detecting operating system..."
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macOS"
    ARCH=$(uname -m)
    echo "Operating System: $OS_TYPE ($ARCH)"
else
    OS_TYPE="Linux/Other"
    echo "Operating System: $OS_TYPE"
fi
echo ""

# ネットワーク設定の定数
NETWORK_NAME="vboxnet0"
NETWORK_CIDR="192.168.56.0/24"
HOST_IP="192.168.56.1"
NETMASK="255.255.255.0"
DHCP_SERVER_IP="192.168.56.2"
LOWER_IP="192.168.56.100"
UPPER_IP="192.168.56.199"

# macOS + VirtualBox 7.0以降: Host-Only Network方式
if [[ "$OS_TYPE" == "macOS" ]] && [[ $VBOX_MAJOR -ge 7 ]]; then
    echo "[3/4] Setting up Host-Only Network (New method for macOS)..."
    echo "Method: Host-Only Network (hostonlynet)"
    echo ""

    # 既存のHost-Only Networkをチェック
    if VBoxManage list hostonlynets | grep -q "Name:.*${NETWORK_NAME}"; then
        echo "✓ Host-Only Network '${NETWORK_NAME}' already exists."
        echo "  Skipping creation."
    else
        echo "Creating Host-Only Network '${NETWORK_NAME}'..."
        VBoxManage hostonlynet add \
            --name "${NETWORK_NAME}" \
            --netmask "${NETMASK}" \
            --lower-ip "${LOWER_IP}" \
            --upper-ip "${UPPER_IP}" \
            --enable

        if [ $? -eq 0 ]; then
            echo "✓ Host-Only Network created successfully."
        else
            echo "✗ Failed to create Host-Only Network."
            exit 1
        fi
    fi
    echo ""

    echo "[4/4] Verifying network configuration..."
    NETWORK_INFO=$(VBoxManage list hostonlynets | grep -A 10 "Name:.*${NETWORK_NAME}")

# Linux/古いmacOS: Host-Only Adapter方式
else
    echo "[3/4] Setting up Host-Only Adapter (Traditional method)..."
    echo "Method: Host-Only Adapter (hostonlyif)"
    echo ""

    # 既存のアダプターをチェック
    if VBoxManage list hostonlyifs | grep -q "Name:.*${NETWORK_NAME}"; then
        echo "✓ Host-Only Adapter '${NETWORK_NAME}' already exists."
        echo "  Skipping creation."
        INTERFACE="${NETWORK_NAME}"
    else
        echo "Creating Host-Only Adapter..."
        CREATE_OUTPUT=$(VBoxManage hostonlyif create 2>&1)

        if [ $? -eq 0 ]; then
            INTERFACE=$(echo "$CREATE_OUTPUT" | grep -oE "vboxnet[0-9]+")
            echo "✓ Created interface: $INTERFACE"

            # IPアドレスの設定
            echo "  Configuring IP address..."
            VBoxManage hostonlyif ipconfig "$INTERFACE" \
                --ip "${HOST_IP}" \
                --netmask "${NETMASK}"

            # DHCPサーバーの設定（既存チェック）
            echo "  Configuring DHCP server..."
            if VBoxManage list dhcpservers | grep -q "NetworkName:.*HostInterfaceNetworking-${INTERFACE}"; then
                echo "  DHCP server already exists, removing old configuration..."
                VBoxManage dhcpserver remove --ifname "$INTERFACE" 2>/dev/null || true
            fi

            VBoxManage dhcpserver add \
                --ifname "$INTERFACE" \
                --ip "${DHCP_SERVER_IP}" \
                --netmask "${NETMASK}" \
                --lowerip "${LOWER_IP}" \
                --upperip "${UPPER_IP}" \
                --enable

            echo "✓ DHCP server configured successfully."
        else
            echo "✗ Failed to create Host-Only Adapter."
            echo "$CREATE_OUTPUT"
            exit 1
        fi
    fi
    echo ""

    echo "[4/4] Verifying network configuration..."
    NETWORK_INFO=$(VBoxManage list hostonlyifs | grep -A 10 "Name:.*${INTERFACE}")
fi

echo ""
echo "=================================="
echo "Network Setup Completed!"
echo "=================================="
echo ""
echo "Configuration Summary:"
echo "----------------------------------------"
if [[ "$OS_TYPE" == "macOS" ]] && [[ $VBOX_MAJOR -ge 7 ]]; then
    echo "Network Type    : Host-Only Network"
    echo "Network Name    : ${NETWORK_NAME}"
else
    echo "Network Type    : Host-Only Adapter"
    echo "Interface Name  : ${INTERFACE:-${NETWORK_NAME}}"
    echo "Host IP Address : ${HOST_IP}"
fi
echo "Network CIDR    : ${NETWORK_CIDR}"
echo "Subnet Mask     : ${NETMASK}"
echo "DHCP Range      : ${LOWER_IP} - ${UPPER_IP}"
echo "----------------------------------------"
echo ""

echo "Network Details:"
echo "----------------------------------------"
if [[ "$OS_TYPE" == "macOS" ]] && [[ $VBOX_MAJOR -ge 7 ]]; then
    VBoxManage list hostonlynets | grep -A 15 "Name:.*${NETWORK_NAME}" || echo "Network information not available"
else
    VBoxManage list hostonlyifs | grep -A 10 "Name:.*${INTERFACE:-${NETWORK_NAME}}" || echo "Interface information not available"
fi
echo "----------------------------------------"
echo ""

echo "Next Steps:"
echo "1. Run 'vagrant up' to start your virtual machines"
echo "2. VMs will automatically connect to this network"
echo "3. Use 'vagrant ssh' to access your VMs"
echo ""
echo "To verify the network:"
if [[ "$OS_TYPE" == "macOS" ]] && [[ $VBOX_MAJOR -ge 7 ]]; then
    echo "  VBoxManage list hostonlynets"
else
    echo "  VBoxManage list hostonlyifs"
    echo "  VBoxManage list dhcpservers"
fi
echo ""
echo "Setup completed successfully! ✓"
