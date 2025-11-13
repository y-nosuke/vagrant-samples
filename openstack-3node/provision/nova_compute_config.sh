#!/bin/bash
# Nova Compute設定ファイルの編集（コンピュートノード）

set -euo pipefail

# 環境変数の設定（デフォルト値）
NOVA_PASS=${NOVA_PASS:-"password123"}
RABBIT_PASS=${RABBIT_PASS:-"rabbitmq123"}

CONFIG_FILE="/etc/nova/nova.conf"
BACKUP_FILE="${CONFIG_FILE}.orig"

echo "[nova-compute-config] Nova Compute設定ファイルの編集中..."

# 設定ファイルのバックアップ
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "  設定ファイルをバックアップ中..."
    sudo cp "${CONFIG_FILE}" "${BACKUP_FILE}"
    echo "✓ バックアップを作成しました: ${BACKUP_FILE}"
else
    echo "✓ バックアップファイルは既に存在します"
fi

# 設定ファイルの編集
echo "  設定ファイルを編集中..."
sudo tee "${CONFIG_FILE}" > /dev/null <<EOF
[DEFAULT]
log_dir = /var/log/nova
state_path = /var/lib/nova
transport_url = rabbit://openstack:${RABBIT_PASS}@controller:5672
my_ip = 172.16.100.31
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 172.16.100.31
novncproxy_base_url = http://controller:6080/vnc_auto.html

[glance]
api_servers = http://controller:9292

[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = ${NOVA_PASS}
insecure = true

[oslo_concurrency]
lock_path = /var/lib/nova/tmp

[libvirt]
virt_type = kvm
EOF
echo "✓ 設定ファイルを編集しました"

# libvirt/KVMの確認
echo "  libvirt/KVMの確認中..."

# KVMモジュールの確認
if lsmod | grep -q kvm; then
    echo "✓ KVMモジュール: 読み込み済み"
else
    echo "× KVMモジュール: 読み込まれていません"
    echo "  KVMモジュールを読み込んでください:"
    echo "    sudo modprobe kvm"
    echo "    sudo modprobe kvm_intel  # Intel CPUの場合"
    echo "    または"
    echo "    sudo modprobe kvm_amd    # AMD CPUの場合"
fi

# CPU仮想化支援機能の確認
CPU_VIRT=$(egrep -c '(vmx|svm)' /proc/cpuinfo || echo "0")
if [ "${CPU_VIRT}" -gt 0 ]; then
    echo "✓ CPU仮想化支援機能: 有効 (${CPU_VIRT}コア)"
else
    echo "× CPU仮想化支援機能: 無効"
    echo "  VirtualBoxの設定で入れ子仮想化を有効化してください"
fi

# libvirtサービスの確認
if sudo systemctl is-active --quiet libvirtd; then
    echo "✓ libvirtサービス: running"
else
    echo "  libvirtサービスを起動中..."
    sudo systemctl enable libvirtd
    sudo systemctl start libvirtd
    if sudo systemctl is-active --quiet libvirtd; then
        echo "✓ libvirtサービス: 起動しました"
    else
        echo "× libvirtサービス: 起動失敗"
        echo "  ログを確認してください:"
        echo "    sudo journalctl -u libvirtd -n 50"
    fi
fi

echo "[nova-compute-config] 完了"

