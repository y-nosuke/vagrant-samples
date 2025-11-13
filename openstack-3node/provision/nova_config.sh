#!/bin/bash
# Nova設定ファイルの編集とDB同期、Cell設定

set -euo pipefail

# 環境変数の設定（デフォルト値）
NOVA_DBPASS=${NOVA_DBPASS:-"password123"}
NOVA_PASS=${NOVA_PASS:-"password123"}
RABBIT_PASS=${RABBIT_PASS:-"rabbitmq123"}
PLACEMENT_PASS=${PLACEMENT_PASS:-"password123"}
PLACEMENT_DBPASS=${PLACEMENT_DBPASS:-"password123"}
MARIADB_ROOT_PASSWORD=${MARIADB_ROOT_PASSWORD:-"password123"}

CONFIG_FILE="/etc/nova/nova.conf"
BACKUP_FILE="${CONFIG_FILE}.orig"

echo "[nova-config] Nova設定ファイルの編集とDB同期中..."

# 設定ファイルのバックアップ
if [ ! -f "${BACKUP_FILE}" ]; then
    echo "  設定ファイルをバックアップ中..."
    sudo mv "${CONFIG_FILE}" "${BACKUP_FILE}"
    echo "✓ バックアップを作成しました: ${BACKUP_FILE}"
else
    echo "✓ バックアップファイルは既に存在します"
fi

# 設定ファイルの編集
echo "  設定ファイルを編集中..."
sudo tee "${CONFIG_FILE}" > /dev/null <<EOF
[DEFAULT]
osapi_compute_listen = 127.0.0.1
osapi_compute_listen_port = 8774
metadata_listen = 127.0.0.1
metadata_listen_port = 8775
log_dir = /var/log/nova
state_path = /var/lib/nova
transport_url = rabbit://openstack:${RABBIT_PASS}@controller:5672
my_ip = 172.16.100.10
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

# VNC設定
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 172.16.100.10
novncproxy_base_url = http://controller:6080/vnc_auto.html
novncproxy_host = 127.0.0.1
novncproxy_port = 6080

[glance]
api_servers = http://controller:9292

[api_database]
connection = mysql+pymysql://nova:${NOVA_DBPASS}@controller/nova_api

[database]
connection = mysql+pymysql://nova:${NOVA_DBPASS}@controller/nova

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

[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = https://controller:5000/v3
username = placement
password = ${PLACEMENT_PASS}
insecure = true
EOF
echo "✓ 設定ファイルを編集しました"

# 設定ファイルのパーミッション設定
echo "  設定ファイルのパーミッションを設定中..."
sudo chmod 640 "${CONFIG_FILE}"
sudo chgrp nova "${CONFIG_FILE}"
echo "✓ 設定ファイルのパーミッションを設定しました"

# データベースの同期
echo "  データベースを同期中..."

# nova_apiデータベースの同期
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE nova_api; SHOW TABLES;" 2>/dev/null | grep -q .; then
    echo "✓ nova_apiデータベーススキーマは既に同期されています"
else
    sudo su -s /bin/bash nova -c "nova-manage api_db sync"
    echo "✓ nova_apiデータベースを同期しました"
fi

# nova_cell0データベースの同期とCell0の登録
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE nova_cell0; SHOW TABLES;" 2>/dev/null | grep -q .; then
    echo "✓ nova_cell0データベーススキーマは既に同期されています"
else
    sudo su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0"
    echo "✓ nova_cell0データベースを同期し、Cell0を登録しました"
fi

# novaデータベースの同期
if sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE nova; SHOW TABLES;" 2>/dev/null | grep -q .; then
    echo "✓ novaデータベーススキーマは既に同期されています"
else
    sudo su -s /bin/bash nova -c "nova-manage db sync"
    echo "✓ novaデータベースを同期しました"
fi

# Cell1の作成
echo "  Cell1を作成中..."
if sudo su -s /bin/bash nova -c "nova-manage cell_v2 list_cells" 2>/dev/null | grep -q cell1; then
    echo "✓ Cell1は既に存在します"
else
    sudo su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"
    echo "✓ Cell1を作成しました"
fi

# Cellの確認
echo "  Cellを確認中..."
sudo su -s /bin/bash nova -c "nova-manage cell_v2 list_cells"

# データベーステーブルの確認
echo "  データベーステーブルを確認中..."
for db in nova_api nova nova_cell0; do
    TABLE_COUNT=$(sudo mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "USE ${db}; SHOW TABLES;" 2>/dev/null | wc -l)
    if [ "${TABLE_COUNT}" -gt 5 ]; then
        echo "✓ ${db}データベーステーブル: ${TABLE_COUNT}個"
    else
        echo "× ${db}データベーステーブルが不足しています"
        exit 1
    fi
done

echo "[nova-config] 完了"

