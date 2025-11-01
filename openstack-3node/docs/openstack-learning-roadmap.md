# 🎯 OpenStack学習環境構築ロードマップ

## 📋 前提条件

- **採用構成**: 3ノード構成（コントローラ、ネットワーク、コンピュート）
- **環境**: Vagrant + VirtualBox
- **構築方法**: 手動構築（Server World参照）
- **目標**: OpenStackの仕組みを深く理解する
- **プロジェクトリポジトリ**: <https://github.com/y-nosuke/vagrant-samples>

---

## 📁 プロジェクト構成

```bash
vagrant-samples/
├── openstack-3node/
│   ├── Vagrantfile              # 3ノード構成定義
│   ├── README.md                # 環境構築手順
│   ├── provision/               # プロビジョニングスクリプト
│   │   ├── common.sh           # 全ノード共通設定
│   │   ├── controller.sh       # コントローラノード設定
│   │   ├── network.sh          # ネットワークノード設定
│   │   └── compute.sh          # コンピュートノード設定
│   ├── configs/                 # 設定ファイルテンプレート
│   │   ├── hosts               # hostsファイル
│   │   └── ntp.conf            # NTP設定
│   ├── scripts/                 # 運用スクリプト
│   │   ├── backup.sh           # バックアップスクリプト
│   │   ├── health-check.sh     # ヘルスチェック
│   │   └── cleanup.sh          # クリーンアップ
│   └── docs/                    # ドキュメント
│       ├── network-diagram.md  # ネットワーク構成図
│       ├── troubleshooting.md  # トラブルシューティング
│       └── learning-log.md     # 学習記録テンプレート
└── README.md                    # リポジトリ全体の説明
```

---

## ⚡ コアパス（最短ルート）

最小限の時間で一通りの機能を学び、実際にVMを起動できるまでの必須項目です。

### **Phase 1: 環境準備**

**目的**: VagrantでVM環境を構築

**Step 1-1: ホストマシンの準備** ⭐⭐⭐

- VirtualBoxのインストール
- Vagrantのインストール
- ディスク空き容量の確認（200GB以上推奨）
- 仮想化支援機能の確認（Intel VT-x / AMD-V）

**Step 1-2: プロジェクトのセットアップ** ⭐⭐⭐

- リポジトリのクローン

  ```bash
  git clone https://github.com/y-nosuke/vagrant-samples.git
  cd vagrant-samples/openstack-3node
  ```

- Vagrantfileの確認と必要に応じた調整
  - メモリ・CPU割り当て
  - ネットワーク設定（管理・オーバーレイ・外部）
  - 入れ子仮想化の有効化設定

**Step 1-3: VM起動と基本確認** ⭐⭐⭐

- 3ノードの起動

  ```bash
  vagrant up
  ```

- 各ノードへのSSH接続確認

  ```bash
  vagrant ssh controller
  vagrant ssh network
  vagrant ssh compute1
  ```

- ノード間の疎通確認（ping）

**学習ポイント**:

- 3つのネットワーク（管理・オーバーレイ・外部）の理解
- 入れ子仮想化の必要性
- IPアドレス割り当ての確認

---

### **Phase 2: 基盤構築**

**目的**: OpenStackの土台を作る

**Step 2-1: 全ノード共通設定** ⭐⭐⭐

- hostsファイルの設定（/etc/hosts）

  ```text
  192.168.100.10 controller
  192.168.100.20 network
  192.168.100.31 compute1
  ```

- NTPによる時刻同期設定
- OpenStackリポジトリの追加（Ubuntu 24.04 + Epoxy）
- パッケージの更新

**参考**: [Server World - Phase 2.1](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=1)

**Step 2-2: コントローラノードのデータベース構築** ⭐⭐⭐

- MariaDB / MySQLのインストール
- root用パスワード設定
- リモート接続の設定
- 文字コード設定（UTF-8）
- OpenStack用データベースの作成準備

**参考**: [Server World - Phase 2.2](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=2)

**Step 2-3: RabbitMQのインストール** ⭐⭐⭐

- RabbitMQのインストール
- openstack用ユーザーの作成
- 権限設定
- 動作確認

**Step 2-4: Memcachedのインストール** ⭐⭐

- Memcachedのインストール
- 設定ファイルの編集（リスン設定）
- サービスの起動

**Step 2-5: 基盤の動作確認** ⭐⭐⭐

- ノード間通信の確認
- データベース接続確認
- RabbitMQ動作確認
- Memcached動作確認

**学習ポイント**:

- RabbitMQの役割（メッセージキュー）
- データベースの重要性
- 各サービスの依存関係

---

### **Phase 3: コアサービス構築**

**目的**: 最小限のサービスでVMを起動

#### **Step 3-1: Keystone（認証サービス）の構築** ⭐⭐⭐

**3-1-1: Keystoneのインストール**

- keystoneデータベースの作成
- keystoneユーザーの作成と権限付与
- keystoneパッケージのインストール
- /etc/keystone/keystone.conf の設定
  - データベース接続設定
  - トークン設定
- データベースの同期
- Apache HTTP Serverの設定
- サービスの起動

**参考**: [Server World - Keystone](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=3)

**3-1-2: プロジェクト・ユーザー・ロールの作成**

- adminプロジェクトの作成
- adminユーザーの作成
- adminロールの作成
- サービスプロジェクトの作成
- 環境変数ファイル（admin-openrc）の作成
- 動作確認（openstack token issue）

**学習ポイント**:

- Keystoneの役割（認証・認可）
- プロジェクト、ユーザー、ロールの関係
- エンドポイントの概念

---

#### **Step 3-2: Glance（イメージサービス）の構築** ⭐⭐⭐

**3-2-1: Glanceのインストール**

- glanceデータベースの作成
- glanceユーザーの作成
- Keystoneでのサービス登録
- エンドポイントの作成
- glanceパッケージのインストール
- /etc/glance/glance-api.conf の設定
  - データベース接続
  - Keystone認証設定
  - ストレージバックエンド設定（ファイルシステム）
- データベースの同期
- サービスの起動

**参考**: [Server World - Glance](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=4)

**3-2-2: テストイメージのアップロード**

<details>
<summary><b>Command</b></summary>

```bash
# Ubuntu Cloud Imageのダウンロード
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Glanceへのイメージ登録
openstack image create \
  --disk-format qcow2 \
  --container-format bare \
  --public \
  --file jammy-server-cloudimg-amd64.img \
  ubuntu-22.04

# イメージ一覧の確認
openstack image list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/images.tf
resource "openstack_images_image_v2" "ubuntu_2204" {
  name             = "ubuntu-22.04"
  image_source_url = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
  container_format = "bare"
  disk_format      = "qcow2"
  visibility       = "public"

  properties = {
    os_distro  = "ubuntu"
    os_version = "22.04"
  }
}

output "ubuntu_image_id" {
  value = openstack_images_image_v2.ubuntu_2204.id
}
```

</details>

**学習ポイント**:

- Glanceのアーキテクチャ
- イメージストレージの仕組み
- クラウドイメージとは何か

---

#### **Step 3-3: Nova（コンピュートサービス）の構築** ⭐⭐⭐

**3-3-1: Novaコントローラ側のインストール**

- novaデータベースの作成（nova_api、nova、nova_cell0）
- novaユーザーの作成
- Keystoneでのサービス登録
- エンドポイントの作成
- Novaパッケージのインストール
  - nova-api
  - nova-conductor
  - nova-scheduler
  - nova-novncproxy
- /etc/nova/nova.conf の設定
  - データベース接続
  - RabbitMQ接続
  - Keystone認証設定
  - VNC設定
  - Neutron設定（後で追加）
- データベースの同期
- Cell0の登録
- Cell1の作成
- サービスの起動

**参考**: [Server World - Nova Controller](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=5)

**3-3-2: Novaコンピュート側のインストール**

- Novaパッケージのインストール（nova-compute）
- /etc/nova/nova.conf の設定
  - コントローラへの接続設定
  - ハイパーバイザー設定（KVM）
  - VNC設定
- libvirt / KVMの設定確認
- サービスの起動
- コントローラでのコンピュートノード登録確認

**参考**: [Server World - Nova Compute](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=6)

**3-3-3: Flavorの作成**

<details>
<summary><b>Command</b></summary>

```bash
# 標準Flavorの作成
openstack flavor create --ram 512 --disk 1 --vcpus 1 m1.tiny
openstack flavor create --ram 2048 --disk 20 --vcpus 1 m1.small
openstack flavor create --ram 4096 --disk 40 --vcpus 2 m1.medium
openstack flavor create --ram 8192 --disk 80 --vcpus 4 m1.large

# Flavor一覧の確認
openstack flavor list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/flavors.tf
resource "openstack_compute_flavor_v2" "m1_tiny" {
  name      = "m1.tiny"
  ram       = "512"
  vcpus     = "1"
  disk      = "1"
  is_public = true
}

resource "openstack_compute_flavor_v2" "m1_small" {
  name      = "m1.small"
  ram       = "2048"
  vcpus     = "1"
  disk      = "20"
  is_public = true
}

resource "openstack_compute_flavor_v2" "m1_medium" {
  name      = "m1.medium"
  ram       = "4096"
  vcpus     = "2"
  disk      = "40"
  is_public = true
}

resource "openstack_compute_flavor_v2" "m1_large" {
  name      = "m1.large"
  ram       = "8192"
  vcpus     = "4"
  disk      = "80"
  is_public = true
}
```

</details>

**3-3-4: Nova動作確認**

```bash
# サービス一覧の確認
openstack compute service list

# ハイパーバイザー一覧の確認
openstack hypervisor list
```

**学習ポイント**:

- Novaのアーキテクチャ（API、Scheduler、Conductor、Compute）
- スケジューラーの役割
- ハイパーバイザー（KVM）の理解
- Cellの概念

---

#### **Step 3-4: Neutron（ネットワークサービス）の構築** ⭐⭐⭐

**3-4-1: Neutronサーバーの構築**

- neutronデータベースの作成
- neutronユーザーの作成
- Keystoneでのサービス登録
- エンドポイントの作成
- Neutronパッケージのインストール（neutron-server、neutron-plugin-ml2）
- /etc/neutron/neutron.conf の設定
  - データベース接続
  - RabbitMQ接続
  - Keystone認証設定
  - Nova通知設定
- /etc/neutron/plugins/ml2/ml2_conf.ini の設定
  - タイプドライバ（flat、vxlan）
  - テナントネットワークタイプ（vxlan）
  - メカニズムドライバ（openvswitch）
  - VXLANの設定
- データベースの同期
- サービスの起動

**参考**: [Server World - Neutron Controller](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=7)

**3-4-2: ネットワークノードの構築**

- Neutronパッケージのインストール
  - neutron-l3-agent
  - neutron-dhcp-agent
  - neutron-metadata-agent
  - neutron-openvswitch-agent
- Open vSwitchのインストールと設定
- /etc/neutron/neutron.conf の設定
- /etc/neutron/l3_agent.ini の設定（L3 Agent）
- /etc/neutron/dhcp_agent.ini の設定（DHCP Agent）
- /etc/neutron/metadata_agent.ini の設定（Metadata Agent）
- /etc/neutron/plugins/ml2/openvswitch_agent.ini の設定
  - ブリッジマッピング（外部ネットワーク）
  - トンネル設定（VXLAN）
- OVSブリッジの作成

  ```bash
  ovs-vsctl add-br br-ex
  ovs-vsctl add-port br-ex eth2
  ```

- サービスの起動

**参考**: [Server World - Neutron Network Node](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=8)

**3-4-3: コンピュートノードのNeutronエージェント**

- Neutronパッケージのインストール（neutron-openvswitch-agent）
- Open vSwitchのインストール
- /etc/neutron/neutron.conf の設定
- /etc/neutron/plugins/ml2/openvswitch_agent.ini の設定
  - トンネル設定（VXLAN）
- Nova設定の更新（/etc/nova/nova.conf）
  - Neutron連携設定の追加
- サービスの再起動

**参考**: [Server World - Neutron Compute Node](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=9)

**3-4-4: 外部ネットワークの作成（FLAT）**

<details>
<summary><b>Command</b></summary>

```bash
# プロバイダーネットワーク（external）の作成
openstack network create \
  --provider-network-type flat \
  --provider-physical-network physnet1 \
  --external \
  external-network

# サブネットの作成
openstack subnet create \
  --network external-network \
  --subnet-range 192.168.1.0/24 \
  --gateway 192.168.1.1 \
  --allocation-pool start=192.168.1.201,end=192.168.1.220 \
  --dns-nameserver 8.8.8.8 \
  external-subnet

# ネットワーク一覧の確認
openstack network list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/networks.tf
resource "openstack_networking_network_v2" "external" {
  name           = "external-network"
  admin_state_up = true
  external       = true
  segments {
    network_type     = "flat"
    physical_network = "physnet1"
  }
}

resource "openstack_networking_subnet_v2" "external" {
  name            = "external-subnet"
  network_id      = openstack_networking_network_v2.external.id
  cidr            = "192.168.1.0/24"
  ip_version      = 4
  gateway_ip      = "192.168.1.1"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]

  allocation_pool {
    start = "192.168.1.201"
    end   = "192.168.1.220"
  }
}
```

</details>

**3-4-5: テナントネットワークの作成（VXLAN）**

<details>
<summary><b>Command</b></summary>

```bash
# プライベートネットワークの作成
openstack network create private-network

# サブネットの作成
openstack subnet create \
  --network private-network \
  --subnet-range 10.0.0.0/24 \
  --gateway 10.0.0.1 \
  --dns-nameserver 8.8.8.8 \
  private-subnet

# ネットワーク一覧の確認
openstack network list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/networks.tf (続き)
resource "openstack_networking_network_v2" "private" {
  name           = "private-network"
  admin_state_up = true
}

resource "openstack_networking_subnet_v2" "private" {
  name            = "private-subnet"
  network_id      = openstack_networking_network_v2.private.id
  cidr            = "10.0.0.0/24"
  ip_version      = 4
  gateway_ip      = "10.0.0.1"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}
```

</details>

**3-4-6: ルーターの作成**

<details>
<summary><b>Command</b></summary>

```bash
# ルーターの作成
openstack router create router1

# 外部ネットワークへのゲートウェイ設定
openstack router set \
  --external-gateway external-network \
  router1

# プライベートネットワークの接続
openstack router add subnet router1 private-subnet

# ルーター一覧の確認
openstack router list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/routers.tf
resource "openstack_networking_router_v2" "router1" {
  name                = "router1"
  admin_state_up      = true
  external_network_id = openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "router1_interface" {
  router_id = openstack_networking_router_v2.router1.id
  subnet_id = openstack_networking_subnet_v2.private.id
}
```

</details>

**3-4-7: Neutron動作確認**

```bash
# ネットワークエージェントの確認
openstack network agent list

# ネットワーク一覧の確認
openstack network list
openstack subnet list
openstack router list
```

**学習ポイント**:

- Neutronのアーキテクチャ（Server、L3/DHCP/Metadata Agent）
- プロバイダーネットワーク vs テナントネットワーク
- VXLANによるネットワーク分離の仕組み
- Open vSwitchの役割
- Floating IPの前提となるルーター設定

---

### **Phase 4: 初回VM起動**

**目的**: 初めてのVM起動を成功させる

**Step 4-1: SSH鍵ペアの作成** ⭐⭐⭐

<details>
<summary><b>Command</b></summary>

```bash
# SSH鍵ペアの生成
ssh-keygen -t rsa -b 2048 -f ~/.ssh/openstack-key

# OpenStackへの鍵登録
openstack keypair create --public-key ~/.ssh/openstack-key.pub mykey

# 鍵ペア一覧の確認
openstack keypair list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/keypairs.tf
resource "openstack_compute_keypair_v2" "mykey" {
  name       = "mykey"
  public_key = file("~/.ssh/openstack-key.pub")
}

output "keypair_name" {
  value = openstack_compute_keypair_v2.mykey.name
}
```

</details>

**Step 4-2: セキュリティグループの設定** ⭐⭐⭐

<details>
<summary><b>Command</b></summary>

```bash
# デフォルトセキュリティグループの確認
openstack security group list

# SSH許可ルールの追加
openstack security group rule create \
  --protocol tcp \
  --dst-port 22 \
  --remote-ip 0.0.0.0/0 \
  default

# ICMP許可ルールの追加
openstack security group rule create \
  --protocol icmp \
  default

# HTTP許可ルールの追加（後の演習用）
openstack security group rule create \
  --protocol tcp \
  --dst-port 80 \
  default

# セキュリティグループルールの確認
openstack security group rule list default
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/security_groups.tf
data "openstack_networking_secgroup_v2" "default" {
  name = "default"
}

resource "openstack_networking_secgroup_rule_v2" "ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = data.openstack_networking_secgroup_v2.default.id
}

resource "openstack_networking_secgroup_rule_v2" "icmp" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "icmp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = data.openstack_networking_secgroup_v2.default.id
}

resource "openstack_networking_secgroup_rule_v2" "http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = data.openstack_networking_secgroup_v2.default.id
}
```

</details>

**Step 4-3: VM（インスタンス）の作成** ⭐⭐⭐

<details>
<summary><b>Command</b></summary>

```bash
# インスタンスの作成
openstack server create \
  --flavor m1.small \
  --image ubuntu-22.04 \
  --network private-network \
  --key-name mykey \
  --security-group default \
  test-vm

# インスタンス一覧の確認
openstack server list

# インスタンスの詳細確認
openstack server show test-vm
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/instances.tf
resource "openstack_compute_instance_v2" "test_vm" {
  name            = "test-vm"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-22.04"
  key_pair        = openstack_compute_keypair_v2.mykey.name
  security_groups = ["default"]

  network {
    name = openstack_networking_network_v2.private.name
  }
}

output "test_vm_id" {
  value = openstack_compute_instance_v2.test_vm.id
}

output "test_vm_private_ip" {
  value = openstack_compute_instance_v2.test_vm.network[0].fixed_ip_v4
}
```

</details>

**Step 4-4: Floating IPの割り当て** ⭐⭐⭐

<details>
<summary><b>Command</b></summary>

```bash
# Floating IPの作成
openstack floating ip create external-network

# Floating IPの割り当て
openstack server add floating ip test-vm <FLOATING_IP>

# 割り当て確認
openstack server list
openstack floating ip list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/floating_ips.tf
resource "openstack_networking_floatingip_v2" "test_vm_fip" {
  pool = "external-network"
}

resource "openstack_compute_floatingip_associate_v2" "test_vm_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.test_vm_fip.address
  instance_id = openstack_compute_instance_v2.test_vm.id
}

output "test_vm_floating_ip" {
  value = openstack_networking_floatingip_v2.test_vm_fip.address
}
```

</details>

**Step 4-5: SSH接続確認** ⭐⭐⭐

```bash
# pingによる疎通確認
ping <FLOATING_IP>

# SSH接続
ssh -i ~/.ssh/openstack-key ubuntu@<FLOATING_IP>

# VM内での動作確認
hostname
ip addr
df -h
```

**学習ポイント**:

- VMが起動するまでの一連の流れ
- セキュリティグループの重要性
- Floating IPの役割
- プライベートIPとFloating IPの関係

---

### **Phase 5: 基本演習**

**目的**: 実践的なスキルを身につける

#### **Step 5-1: 演習1 - Webサーバー構築** ⭐⭐⭐

**5-1-1: インスタンスの作成**

<details>
<summary><b>Command</b></summary>

```bash
# Webサーバー用インスタンスの作成
openstack server create \
  --flavor m1.small \
  --image ubuntu-22.04 \
  --network private-network \
  --key-name mykey \
  --security-group default \
  web-server

# Floating IPの作成と割り当て
FIP=$(openstack floating ip create external-network -f value -c floating_ip_address)
openstack server add floating ip web-server $FIP

# 確認
openstack server list
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/web_server.tf
resource "openstack_compute_instance_v2" "web_server" {
  name            = "web-server"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-22.04"
  key_pair        = openstack_compute_keypair_v2.mykey.name
  security_groups = ["default"]

  network {
    name = openstack_networking_network_v2.private.name
  }
}

resource "openstack_networking_floatingip_v2" "web_server_fip" {
  pool = "external-network"
}

resource "openstack_compute_floatingip_associate_v2" "web_server_fip_assoc" {
  floating_ip = openstack_networking_floatingip_v2.web_server_fip.address
  instance_id = openstack_compute_instance_v2.web_server.id
}

output "web_server_floating_ip" {
  value = openstack_networking_floatingip_v2.web_server_fip.address
}
```

</details>

**5-1-2: Nginxのインストール**

```bash
# SSH接続
ssh -i ~/.ssh/openstack-key ubuntu@<FLOATING_IP>

# パッケージの更新
sudo apt update
sudo apt upgrade -y

# Nginxのインストール
sudo apt install -y nginx

# サービスの起動確認
sudo systemctl status nginx
```

**5-1-3: 動作確認**

```bash
# ブラウザでアクセス
# http://<FLOATING_IP>

# カスタムページの作成
echo "<h1>Hello from OpenStack!</h1>" | sudo tee /var/www/html/index.html
```

**学習ポイント**:

- インスタンスの作成フロー
- ネットワークの仕組み
- Floating IPの実際の動作

---

#### **Step 5-2: 演習4 - ボリューム管理** ⭐⭐⭐

**5-2-1: Cinderのインストール（コントローラ）**

- cinderデータベースの作成
- cinderユーザーの作成
- Keystoneでのサービス登録
- Cinderパッケージのインストール（cinder-api、cinder-scheduler）
- /etc/cinder/cinder.conf の設定
- データベースの同期
- サービスの起動

**参考**: [Server World - Cinder](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=10)

**5-2-2: Cinder Volumeのインストール（コントローラ兼用）**

- LVMのインストールと設定
- ボリュームグループの作成
- cinder-volumeのインストール
- /etc/cinder/cinder.conf の設定（ボリュームバックエンド）
- サービスの起動

**5-2-3: ボリュームの作成と接続**

<details>
<summary><b>Command</b></summary>

```bash
# Cinderボリュームの作成
openstack volume create --size 10 data-volume

# ボリューム一覧の確認
openstack volume list

# インスタンスへの接続
openstack server add volume web-server data-volume

# VM内でボリュームの確認
ssh -i ~/.ssh/openstack-key ubuntu@<FLOATING_IP>
lsblk

# フォーマットとマウント
sudo mkfs.ext4 /dev/vdb
sudo mkdir /mnt/data
sudo mount /dev/vdb /mnt/data

# データの書き込みテスト
sudo bash -c "echo 'Persistent data test' > /mnt/data/test.txt"
cat /mnt/data/test.txt

# /etc/fstabへの追加（永続化）
echo '/dev/vdb /mnt/data ext4 defaults 0 0' | sudo tee -a /etc/fstab
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/volumes.tf
resource "openstack_blockstorage_volume_v3" "data_volume" {
  name = "data-volume"
  size = 10
}

resource "openstack_compute_volume_attach_v2" "data_volume_attach" {
  instance_id = openstack_compute_instance_v2.web_server.id
  volume_id   = openstack_blockstorage_volume_v3.data_volume.id
}

output "data_volume_id" {
  value = openstack_blockstorage_volume_v3.data_volume.id
}
```

**注意**: Terraformではボリュームの接続まで自動化できますが、VM内でのフォーマット・マウントは別途実施が必要です。
</details>

**5-2-4: スナップショットの作成**

<details>
<summary><b>Command</b></summary>

```bash
# スナップショットの作成
openstack volume snapshot create \
  --volume data-volume \
  data-snapshot

# スナップショット一覧の確認
openstack volume snapshot list

# スナップショットからボリュームを作成
openstack volume create \
  --snapshot data-snapshot \
  --size 10 \
  restored-volume
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/snapshots.tf
resource "openstack_blockstorage_volume_v3" "data_snapshot" {
  name       = "data-snapshot"
  source_vol_id = openstack_blockstorage_volume_v3.data_volume.id
  size       = 10
}
```

</details>

**学習ポイント**:

- エフェメラルディスクとCinderボリュームの違い
- 永続ストレージの重要性
- ボリュームのライフサイクル管理
- スナップショットによるバックアップ

---

## 🔧 オプション学習項目（深掘り用）

コアパスを完了後、興味や必要性に応じて学習する項目です。

---

### **カテゴリA: 管理機能強化**

**こんな人におすすめ**:

- Web UIで管理したい
- ストレージ管理をもっと深く理解したい

#### **項目A-1: Horizon（ダッシュボード）** ⭐⭐

**Step A-1-1: Horizonのインストール**

- Horizonパッケージのインストール
- Apache HTTP Serverの設定
- /etc/openstack-dashboard/local_settings.py の設定
  - OPENSTACK_HOST設定
  - セッション設定
- サービスの起動

**Step A-1-2: ダッシュボードへのアクセス**

- ブラウザでアクセス（<http://controller/horizon）>
- adminユーザーでログイン
- 各種操作の確認
  - インスタンス管理
  - ネットワーク管理
  - ボリューム管理

**学習内容**: Web UIによる管理

---

#### **項目A-2: Cinderの詳細設定** ⭐⭐⭐

**Step A-2-1: 複数ボリュームタイプの設定**

- ボリュームタイプの作成（SSD、HDD）
- QoSの設定
- バックエンドの追加設定

**Step A-2-2: ボリュームの詳細操作**

- ボリュームのリサイズ
- ボリュームの転送
- マルチアタッチの設定

**Step A-2-3: バックアップとリストア**

- Cinder Backup Serviceのインストール
- バックアップの作成
- リストアの実行

**学習内容**: ボリューム管理の詳細

---

#### **項目A-3: Quota（クォータ）の設定** ⭐⭐

**Step A-3-1: プロジェクトクォータの設定**

<details>
<summary><b>Command</b></summary>

```bash
# 現在のクォータ確認
openstack quota show

# クォータの変更
openstack quota set --instances 20 --cores 40 --ram 81920 <project>

# 特定プロジェクトのクォータ確認
openstack quota show <project>
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/quotas.tf
resource "openstack_compute_quotaset_v2" "project_quota" {
  project_id = var.project_id
  instances  = 20
  cores      = 40
  ram        = 81920

  # ネットワーククォータ
  # 注: Neutron quotaは別のリソースタイプが必要
}
```

</details>

**Step A-3-2: クォータのテスト**

- 制限を超えたリソース作成の試行
- エラーメッセージの確認

**学習内容**: プロジェクトごとのリソース制限

---

### **カテゴリB: ネットワーク深掘り**

**こんな人におすすめ**:

- ネットワークエンジニア
- 高可用性・スケーラビリティを学びたい

#### **項目B-1: 演習2 - ロードバランサー構築** ⭐⭐

**Step B-1-1: Octaviaのインストール**

- Octaviaのインストールと設定
- アンフィラインスタンス（管理用VM）の構築

**Step B-1-2: Webサーバー2台の構築**

- インスタンスの作成（web1、web2）
- Nginxのインストール
- 異なるコンテンツの配置

**Step B-1-3: ロードバランサーの作成**

<details>
<summary><b>Command</b></summary>

```bash
# ロードバランサーの作成
openstack loadbalancer create \
  --name lb1 \
  --vip-subnet-id private-subnet

# プールの作成
openstack loadbalancer pool create \
  --name pool1 \
  --lb-algorithm ROUND_ROBIN \
  --protocol HTTP \
  --loadbalancer lb1

# メンバーの追加
openstack loadbalancer member create \
  --address 10.0.0.10 \
  --protocol-port 80 \
  pool1

openstack loadbalancer member create \
  --address 10.0.0.11 \
  --protocol-port 80 \
  pool1

# リスナーの作成
openstack loadbalancer listener create \
  --name listener1 \
  --protocol HTTP \
  --protocol-port 80 \
  --default-pool pool1 \
  lb1

# Floating IPの割り当て
FIP=$(openstack floating ip create external-network -f value -c floating_ip_address)
openstack floating ip set --port <LB_VIP_PORT_ID> $FIP
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/loadbalancer.tf
resource "openstack_lb_loadbalancer_v2" "lb1" {
  name          = "lb1"
  vip_subnet_id = openstack_networking_subnet_v2.private.id
}

resource "openstack_lb_pool_v2" "pool1" {
  name        = "pool1"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb1.id
}

resource "openstack_lb_member_v2" "web1" {
  pool_id       = openstack_lb_pool_v2.pool1.id
  address       = openstack_compute_instance_v2.web1.network[0].fixed_ip_v4
  protocol_port = 80
}

resource "openstack_lb_member_v2" "web2" {
  pool_id       = openstack_lb_pool_v2.pool1.id
  address       = openstack_compute_instance_v2.web2.network[0].fixed_ip_v4
  protocol_port = 80
}

resource "openstack_lb_listener_v2" "listener1" {
  name            = "listener1"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.lb1.id
  default_pool_id = openstack_lb_pool_v2.pool1.id
}

resource "openstack_networking_floatingip_v2" "lb_fip" {
  pool    = "external-network"
  port_id = openstack_lb_loadbalancer_v2.lb1.vip_port_id
}

output "lb_floating_ip" {
  value = openstack_networking_floatingip_v2.lb_fip.address
}
```

</details>

**Step B-1-4: 負荷分散の確認**

- 複数回アクセスして負荷分散を確認

**学習内容**: スケールアウトの実践、高可用性の基礎

---

#### **項目B-2: 演習3 - マルチテナント分離** ⭐⭐⭐

**Step B-2-1: 複数プロジェクトの作成**

<details>
<summary><b>Command</b></summary>

```bash
# プロジェクトA、Bの作成
openstack project create project-A
openstack project create project-B

# 各プロジェクト用のユーザー作成
openstack user create --project project-A --password password user-A
openstack user create --project project-B --password password user-B

# ロールの割り当て
openstack role add --project project-A --user user-A member
openstack role add --project project-B --user user-B member
```

</details>

**Step B-2-2: 各プロジェクトでネットワークを作成**

<details>
<summary><b>Command</b></summary>

```bash
# project-Aのネットワーク
openstack network create --project project-A network-A
openstack subnet create --project project-A --network network-A \
  --subnet-range 10.1.0.0/24 subnet-A

# project-Bのネットワーク
openstack network create --project project-B network-B
openstack subnet create --project project-B --network network-B \
  --subnet-range 10.2.0.0/24 subnet-B
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/multi_tenant.tf
resource "openstack_identity_project_v3" "project_a" {
  name = "project-A"
}

resource "openstack_identity_project_v3" "project_b" {
  name = "project-B"
}

resource "openstack_networking_network_v2" "network_a" {
  name       = "network-A"
  tenant_id  = openstack_identity_project_v3.project_a.id
}

resource "openstack_networking_subnet_v2" "subnet_a" {
  name       = "subnet-A"
  network_id = openstack_networking_network_v2.network_a.id
  cidr       = "10.1.0.0/24"
  tenant_id  = openstack_identity_project_v3.project_a.id
}

resource "openstack_networking_network_v2" "network_b" {
  name       = "network-B"
  tenant_id  = openstack_identity_project_v3.project_b.id
}

resource "openstack_networking_subnet_v2" "subnet_b" {
  name       = "subnet-B"
  network_id = openstack_networking_network_v2.network_b.id
  cidr       = "10.2.0.0/24"
  tenant_id  = openstack_identity_project_v3.project_b.id
}
```

</details>

**Step B-2-3: 各ネットワークにVMを配置**

- 各プロジェクトでインスタンスを作成

**Step B-2-4: ネットワーク分離の確認**

- 異なるプロジェクトのVM間で通信できないことを確認
- VXLAN VNIの確認

**学習内容**: VXLANによる分離、マルチテナントの仕組み

---

#### **項目B-3: VLANネットワークの構築** ⭐

**Step B-3-1: VLAN設定の変更**

- ml2_conf.iniの変更（VLANタイプの追加）
- 物理スイッチ側のVLAN設定

**Step B-3-2: VLANプロバイダーネットワークの作成**

<details>
<summary><b>Command</b></summary>

```bash
# VLANネットワークの作成
openstack network create \
  --provider-network-type vlan \
  --provider-physical-network physnet1 \
  --provider-segment 100 \
  vlan-network
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/vlan_network.tf
resource "openstack_networking_network_v2" "vlan" {
  name = "vlan-network"
  segments {
    network_type     = "vlan"
    physical_network = "physnet1"
    segmentation_id  = 100
  }
}
```

</details>

**Step B-3-3: 動作確認**

- VMの作成とアクセス確認

**学習内容**: プロバイダーネットワークのVLAN版

---

#### **項目B-4: セキュリティグループ詳細** ⭐⭐

**Step B-4-1: カスタムセキュリティグループの作成**

<details>
<summary><b>Command</b></summary>

```bash
# Web用セキュリティグループ
openstack security group create web-sg --description "Security group for web servers"
openstack security group rule create --protocol tcp --dst-port 80 web-sg
openstack security group rule create --protocol tcp --dst-port 443 web-sg

# DB用セキュリティグループ
openstack security group create db-sg --description "Security group for database servers"
openstack security group rule create --protocol tcp --dst-port 3306 --remote-group web-sg db-sg
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/security_groups_advanced.tf
resource "openstack_networking_secgroup_v2" "web_sg" {
  name        = "web-sg"
  description = "Security group for web servers"
}

resource "openstack_networking_secgroup_rule_v2" "web_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_v2" "db_sg" {
  name        = "db-sg"
  description = "Security group for database servers"
}

resource "openstack_networking_secgroup_rule_v2" "db_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.web_sg.id
  security_group_id = openstack_networking_secgroup_v2.db_sg.id
}
```

</details>

**Step B-4-2: 詳細なルール設定**

- 送信元セキュリティグループの指定
- ポート範囲の指定
- プロトコルの詳細設定

**Step B-4-3: セキュリティグループのテスト**

- ルールの効果確認

**学習内容**: ファイアウォールルールの詳細設定

---

### **カテゴリC: 運用・監視**

**こんな人におすすめ**:

- 運用エンジニア
- 本番環境を見据えた学習をしたい

#### **項目C-1: バックアップとリストア** ⭐⭐⭐

**Step C-1-1: 設定ファイルのバックアップ**

- バックアップスクリプトの作成

  ```bash
  #!/bin/bash
  BACKUP_DIR=/backup/openstack-$(date +%Y%m%d)
  mkdir -p $BACKUP_DIR

  # 設定ファイルのバックアップ
  cp -r /etc/keystone $BACKUP_DIR/
  cp -r /etc/glance $BACKUP_DIR/
  cp -r /etc/nova $BACKUP_DIR/
  cp -r /etc/neutron $BACKUP_DIR/
  cp -r /etc/cinder $BACKUP_DIR/

  # tarで圧縮
  tar -czf $BACKUP_DIR.tar.gz $BACKUP_DIR
  ```

**Step C-1-2: データベースのバックアップ**

- データベースのダンプ

  ```bash
  mysqldump --all-databases > $BACKUP_DIR/openstack-db.sql
  # または特定のデータベースのみ
  mysqldump keystone nova glance neutron cinder > $BACKUP_DIR/openstack-db.sql
  ```

**Step C-1-3: リストアのテスト**

- テスト環境でのリストア実施

  ```bash
  mysql < /backup/openstack-db.sql
  ```

**学習内容**: 設定ファイル・DBバックアップ

---

#### **項目C-2: ログ管理** ⭐⭐

**Step C-2-1: ログの場所の確認**

- 各サービスのログファイル
  - /var/log/keystone/
  - /var/log/nova/
  - /var/log/neutron/
  - /var/log/glance/
  - /var/log/cinder/

**Step C-2-2: ログレベルの調整**

- DEBUG、INFO、WARNINGレベルの設定

**Step C-2-3: ログローテーションの設定**

- logrotateの設定

**学習内容**: 各サービスのログ確認方法

---

#### **項目C-3: 監視設定（基本）** ⭐⭐

**Step C-3-1: サービス稼働確認コマンド**

- サービス状態の確認スクリプト作成

  ```bash
  #!/bin/bash
  echo "=== Compute Services ==="
  openstack compute service list

  echo "=== Network Agents ==="
  openstack network agent list

  echo "=== Volume Services ==="
  openstack volume service list
  ```

**Step C-3-2: ヘルスチェックスクリプト**

- 定期的なヘルスチェックスクリプトの作成
- cronでの定期実行設定

**Step C-3-3: アラート設定（基本）**

- サービスダウン時のメール通知

**学習内容**: サービス稼働確認コマンド

---

#### **項目C-4: Prometheus + Grafana監視** ⭐

**Step C-4-1: Prometheusのインストール**

- Prometheusのインストールと設定
- OpenStack Exporterの設定

**Step C-4-2: Grafanaのインストール**

- Grafanaのインストール
- データソースの設定

**Step C-4-3: ダッシュボードの作成**

- OpenStack用ダッシュボードのインポート
- カスタムダッシュボードの作成

**学習内容**: 本格的な監視システム構築

---

### **カテゴリD: スケーラビリティ**

**こんな人におすすめ**:

- 大規模環境を想定した学習
- スケールアウトの仕組みを理解したい

#### **項目D-1: コンピュートノードの追加** ⭐⭐⭐

**Step D-1-1: 新しいコンピュートノードの準備**

- Vagrantfileの編集（compute2追加）
- VM起動

**Step D-1-2: Nova Computeのインストール**

- Phase 3と同様の手順でインストール

**Step D-1-3: スケールアウトの確認**

- 複数のVMを作成し、異なるコンピュートノードに分散されることを確認

  ```bash
  # 複数インスタンスの一括作成
  for i in {1..10}; do
    openstack server create \
      --flavor m1.small \
      --image ubuntu-22.04 \
      --network private-network \
      vm-$i
  done

  # 配置先の確認
  openstack server list --long
  ```

**学習内容**: 水平スケーリングの実践

---

#### **項目D-2: ホストアグリゲートの設定** ⭐⭐

**Step D-2-1: ホストアグリゲートの作成**

<details>
<summary><b>Command</b></summary>

```bash
# SSD搭載ノード用アグリゲート
openstack aggregate create ssd-aggregate
openstack aggregate add host ssd-aggregate compute2
openstack aggregate set --property ssd=true ssd-aggregate

# メタデータを使用したFlavorの作成
openstack flavor create --ram 2048 --disk 20 --vcpus 2 m1.ssd
openstack flavor set --property ssd=true m1.ssd
```

</details>

<details>
<summary><b>Terraform</b></summary>

```hcl
# terraform/aggregates.tf
resource "openstack_compute_aggregate_v2" "ssd_aggregate" {
  name = "ssd-aggregate"
  hosts = ["compute2"]

  metadata = {
    ssd = "true"
  }
}

resource "openstack_compute_flavor_v2" "m1_ssd" {
  name  = "m1.ssd"
  ram   = "2048"
  vcpus = "2"
  disk  = "20"

  extra_specs = {
    "ssd" = "true"
  }
}
```

</details>

**Step D-2-2: Flavorの紐付け**

- メタデータを使用したFlavorとアグリゲートの紐付け

**Step D-2-3: 動作確認**

- 特定のアグリゲートにVMが配置されることを確認

**学習内容**: ノードのグループ化

---

#### **項目D-3: ライブマイグレーション** ⭐

**Step D-3-1: ライブマイグレーション設定**

- 共有ストレージの設定（NFS等）
- nova.confの設定

**Step D-3-2: ライブマイグレーションの実行**

<details>
<summary><b>Command</b></summary>

```bash
# 稼働中のVMを別のコンピュートノードに移動
openstack server migrate --live compute2 test-vm

# マイグレーション状態の確認
openstack server show test-vm | grep migration
```

</details>

**Step D-3-3: 動作確認**

- サービス無停止での移動を確認

**学習内容**: VMの無停止移動

---

### **カテゴリE: 自動化・IaC**

**こんな人におすすめ**:

- DevOpsエンジニア
- インフラのコード化を学びたい

#### **項目E-1: Terraform連携** ⭐⭐⭐

**Step E-1-1: Terraformのインストール**

- Terraformのインストール
- OpenStack Providerの設定

**Step E-1-2: Terraform設定ファイルの作成**

```hcl
# terraform/provider.tf
terraform {
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
  }
}

provider "openstack" {
  auth_url    = "http://192.168.100.10:5000/v3"
  user_name   = "admin"
  password    = var.admin_password
  tenant_name = "admin"
  domain_name = "Default"
}

# terraform/variables.tf
variable "admin_password" {
  description = "Admin password for OpenStack"
  type        = string
  sensitive   = true
}

# terraform/main.tf
resource "openstack_compute_instance_v2" "example" {
  name            = "terraform-example"
  flavor_name     = "m1.small"
  image_name      = "ubuntu-22.04"
  key_pair        = openstack_compute_keypair_v2.mykey.name
  security_groups = ["default"]

  network {
    name = "private-network"
  }
}

# terraform/outputs.tf
output "instance_ip" {
  value = openstack_compute_instance_v2.example.network[0].fixed_ip_v4
}
```

**Step E-1-3: リソースのデプロイ**

- terraform init、plan、applyの実行

  ```bash
  terraform init
  terraform plan
  terraform apply
  ```

**Step E-1-4: リソースの管理**

- terraform destroyでの削除
- stateファイルの管理

**学習内容**: IaCによるインフラ管理

---

#### **項目E-2: Ansible連携** ⭐⭐⭐

**Step E-2-1: Ansibleのインストール**

- Ansibleのインストール
- インベントリファイルの作成

**Step E-2-2: Playbookの作成**

```yaml
# playbooks/webserver.yml
---
- name: Setup Web Server
  hosts: webservers
  become: yes
  tasks:
    - name: Update apt cache
      apt:
        update_cache: yes

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Start Nginx service
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Deploy custom index.html
      copy:
        content: "<h1>Deployed by Ansible</h1>"
        dest: /var/www/html/index.html
```

**Step E-2-3: 実行とテスト**

- ansible-playbookコマンドでの実行

  ```bash
  ansible-playbook -i inventory playbooks/webserver.yml
  ```

- 冪等性の確認

**学習内容**: VM内の構成管理自動化

---

#### **項目E-3: Heat（オーケストレーション）** ⭐⭐

**Step E-3-1: Heatのインストール**

- Heatのインストールと設定

**Step E-3-2: テンプレートの作成**

```yaml
# heat/webapp_stack.yaml
heat_template_version: 2018-08-31

description: Web Application Stack

parameters:
  image:
    type: string
    default: ubuntu-22.04
  flavor:
    type: string
    default: m1.small
  key_name:
    type: string
    default: mykey

resources:
  private_network:
    type: OS::Neutron::Net

  private_subnet:
    type: OS::Neutron::Subnet
    properties:
      network: { get_resource: private_network }
      cidr: 10.10.0.0/24

  web_server:
    type: OS::Nova::Server
    properties:
      name: heat-web-server
      flavor: { get_param: flavor }
      image: { get_param: image }
      key_name: { get_param: key_name }
      networks:
        - network: { get_resource: private_network }

outputs:
  server_ip:
    description: IP address of the web server
    value: { get_attr: [web_server, first_address] }
```

**Step E-3-3: スタックのデプロイ**

<details>
<summary><b>Command</b></summary>

```bash
# スタックの作成
openstack stack create -t heat/webapp_stack.yaml web-app-stack

# スタック一覧の確認
openstack stack list

# スタックの詳細確認
openstack stack show web-app-stack

# スタックの削除
openstack stack delete web-app-stack
```

</details>

**学習内容**: OpenStack標準のIaCツール

---

#### **項目E-4: CI/CDパイプライン** ⭐

**Step E-4-1: GitLab Runnerのセットアップ**

- GitLab Runnerのインストール

**Step E-4-2: .gitlab-ci.ymlの作成**

```yaml
# .gitlab-ci.yml
stages:
  - validate
  - deploy
  - test

variables:
  OS_AUTH_URL: "http://192.168.100.10:5000/v3"
  OS_PROJECT_NAME: "admin"
  OS_USERNAME: "admin"
  OS_DOMAIN_NAME: "Default"

validate:
  stage: validate
  script:
    - terraform init
    - terraform validate

deploy:
  stage: deploy
  script:
    - terraform apply -auto-approve
  only:
    - main

test:
  stage: test
  script:
    - ansible-playbook -i inventory test.yml
```

**Step E-4-3: パイプラインの実行**

- コミット時の自動デプロイ

**学習内容**: GitLab CI/CDとの統合

---

### **カテゴリF: 次世代への移行**

**こんな人におすすめ**:

- 本番環境の構築・運用を目指す
- エンタープライズ向けの知識が必要

#### **項目F-1: Kolla-Ansibleへの移行** ⭐⭐⭐

**Step F-1-1: Kolla-Ansibleのインストール**

- Kolla-Ansibleのインストール
- 仮想環境の準備

  ```bash
  python3 -m venv kolla-venv
  source kolla-venv/bin/activate
  pip install kolla-ansible
  ```

**Step F-1-2: インベントリとglobals.ymlの設定**

- multinode、all-in-oneインベントリの作成
- globals.ymlでの各種設定

**Step F-1-3: デプロイの実行**

- prechecks、bootstrap-servers、deploy

  ```bash
  kolla-ansible -i inventory bootstrap-servers
  kolla-ansible -i inventory prechecks
  kolla-ansible -i inventory deploy
  ```

**Step F-1-4: 動作確認**

- コンテナ化されたOpenStackの確認
- 手動構築環境との違いの理解

**学習内容**: コンテナ化されたOpenStack

---

#### **項目F-2: アップグレード実践** ⭐⭐

**Step F-2-1: アップグレード計画の作成**

- リリースノートの確認
- 互換性の確認

**Step F-2-2: 手動構築環境のアップグレード**

- パッケージの更新
- データベーススキーマの更新

  ```bash
  apt update
  apt upgrade openstack-*

  nova-manage db sync
  neutron-db-manage upgrade heads
  glance-manage db_sync
  cinder-manage db sync
  ```

**Step F-2-3: Kolla-Ansible環境のアップグレード**

- kolla-ansible upgradeコマンドの実行

  ```bash
  kolla-ansible -i inventory upgrade
  ```

**学習内容**: OpenStackバージョンアップ

---

#### **項目F-3: HA構成の構築** ⭐

**Step F-3-1: HA環境の設計**

- 3台のコントローラノード構成
- HAProxy、Keepalivedの設計

**Step F-3-2: コントローラの冗長化**

- MariaDB Galera Clusterの構築
- RabbitMQクラスタの構築
- HAProxyとKeepalivedの設定

**Step F-3-3: 動作確認**

- フェイルオーバーのテスト

**学習内容**: 高可用性構成（3台構成）

**Step B-1-1: Octaviaのインストール**

- Octaviaのインストールと設定
- アンフィラインスタンス（管理用VM）の構築

**Step B-1-2: Webサーバー2台の構築**

- インスタンスの作成（web1、web2）
- Nginxのインストール
- 異なるコンテンツの配置

**Step B-1-3: ロードバランサーの作成**

- ロードバランサーの作成

  ```bash
  openstack loadbalancer create \
    --name lb1 \
    --vip-subnet-id private-subnet
  ```

- プールの作成

  ```bash
  openstack loadbalancer pool create \
    --name pool1 \
    --lb-algorithm ROUND_ROBIN \
    --protocol HTTP \
    --loadbalancer lb1
  ```

- メンバーの追加

  ```bash
  openstack loadbalancer member create \
    --address 10.0.0.10 \
    --protocol-port 80 \
    pool1
  ```

- リスナーの作成
- Floating IPの割り当て

**Step B-1-4: 負荷分散の確認**

- 複数回アクセスして負荷分散を確認

**学習内容**: スケールアウトの実践、高可用性の基礎

---

#### **項目B-2: 演習3 - マルチテナント分離**（2時間）⭐⭐⭐

**Step B-2-1: 複数プロジェクトの作成**

- プロジェクトA、Bの作成

  ```bash
  openstack project create project-A
  openstack project create project-B
  ```

- 各プロジェクト用のユーザー作成

**Step B-2-2: 各プロジェクトでネットワークを作成**

- project-Aのネットワーク

  ```bash
  openstack network create --project project-A network-A
  openstack subnet create --project project-A --network network-A \
    --subnet-range 10.1.0.0/24 subnet-A
  ```

- project-Bのネットワーク

  ```bash
  openstack network create --project project-B network-B
  openstack subnet create --project project-B --network network-B \
    --subnet-range 10.2.0.0/24 subnet-B
  ```

**Step B-2-3: 各ネットワークにVMを配置**

- 各プロジェクトでインスタンスを作成

**Step B-2-4: ネットワーク分離の確認**

- 異なるプロジェクトのVM間で通信できないことを確認
- VXLAN VNIの確認

**学習内容**: VXLANによる分離、マルチテナントの仕組み

---

#### **項目B-3: VLANネットワークの構築**（3時間）⭐

**Step B-3-1: VLAN設定の変更**

- ml2_conf.iniの変更（VLANタイプの追加）
- 物理スイッチ側のVLAN設定

**Step B-3-2: VLANプロバイダーネットワークの作成**

- VLANネットワークの作成

  ```bash
  openstack network create \
    --provider-network-type vlan \
    --provider-physical-network physnet1 \
    --provider-segment 100 \
    vlan-network
  ```

**Step B-3-3: 動作確認**

- VMの作成とアクセス確認

**学習内容**: プロバイダーネットワークのVLAN版

---

#### **項目B-4: セキュリティグループ詳細**（2時間）⭐⭐

**Step B-4-1: カスタムセキュリティグループの作成**

- Web用セキュリティグループ
- DB用セキュリティグループ

**Step B-4-2: 詳細なルール設定**

- 送信元セキュリティグループの指定
- ポート範囲の指定
- プロトコルの詳細設定

**Step B-4-3: セキュリティグループのテスト**

- ルールの効果確認

**学習内容**: ファイアウォールルールの詳細設定

---

### **カテゴリC: 運用・監視**（+2-3日）

**こんな人におすすめ**:

- 運用エンジニア
- 本番環境を見据えた学習をしたい

#### **項目C-1: バックアップとリストア**（3時間）⭐⭐⭐

**Step C-1-1: 設定ファイルのバックアップ**

- バックアップスクリプトの作成

  ```bash
  #!/bin/bash
  BACKUP_DIR=/backup/openstack-$(date +%Y%m%d)
  mkdir -p $BACKUP_DIR

  # 設定ファイルのバックアップ
  cp -r /etc/keystone $BACKUP_DIR/
  cp -r /etc/glance $BACKUP_DIR/
  cp -r /etc/nova $BACKUP_DIR/
  cp -r /etc/neutron $BACKUP_DIR/
  cp -r /etc/cinder $BACKUP_DIR/
  ```

**Step C-1-2: データベースのバックアップ**

- データベースのダンプ

  ```bash
  mysqldump --all-databases > $BACKUP_DIR/openstack-db.sql
  ```

**Step C-1-3: リストアのテスト**

- テスト環境でのリストア実施

**学習内容**: 設定ファイル・DBバックアップ

---

#### **項目C-2: ログ管理**（2時間）⭐⭐

**Step C-2-1: ログの場所の確認**

- 各サービスのログファイル
  - /var/log/keystone/
  - /var/log/nova/
  - /var/log/neutron/
  - /var/log/glance/
  - /var/log/cinder/

**Step C-2-2: ログレベルの調整**

- DEBUG、INFO、WARNINGレベルの設定

**Step C-2-3: ログローテーションの設定**

- logrotateの設定

**学習内容**: 各サービスのログ確認方法

---

#### **項目C-3: 監視設定（基本）**（2時間）⭐⭐

**Step C-3-1: サービス稼働確認コマンド**

- サービス状態の確認スクリプト作成

  ```bash
  openstack compute service list
  openstack network agent list
  openstack volume service list
  ```

**Step C-3-2: ヘルスチェックスクリプト**

- 定期的なヘルスチェックスクリプトの作成
- cronでの定期実行設定

**Step C-3-3: アラート設定（基本）**

- サービスダウン時のメール通知

**学習内容**: サービス稼働確認コマンド

---

#### **項目C-4: Prometheus + Grafana監視**（4時間）⭐

**Step C-4-1: Prometheusのインストール**

- Prometheusのインストールと設定
- OpenStack Exporterの設定

**Step C-4-2: Grafanaのインストール**

- Grafanaのインストール
- データソースの設定

**Step C-4-3: ダッシュボードの作成**

- OpenStack用ダッシュボードのインポート
- カスタムダッシュボードの作成

**学習内容**: 本格的な監視システム構築

---

### **カテゴリD: スケーラビリティ**（+2-4日）

**こんな人におすすめ**:

- 大規模環境を想定した学習
- スケールアウトの仕組みを理解したい

#### **項目D-1: コンピュートノードの追加**（3時間）⭐⭐⭐

**Step D-1-1: 新しいコンピュートノードの準備**

- Vagrantfileの編集（compute2追加）
- VM起動

**Step D-1-2: Nova Computeのインストール**

- Phase 3と同様の手順でインストール

**Step D-1-3: スケールアウトの確認**

- 複数のVMを作成し、異なるコンピュートノードに分散されることを確認

**学習内容**: 水平スケーリングの実践

---

#### **項目D-2: ホストアグリゲートの設定**（2時間）⭐⭐

**Step D-2-1: ホストアグリゲートの作成**

- SSD搭載ノード用アグリゲート

  ```bash
  openstack aggregate create ssd-aggregate
  openstack aggregate add host ssd-aggregate compute2
  ```

**Step D-2-2: Flavorの紐付け**

- メタデータを使用したFlavorとアグリゲートの紐付け

**Step D-2-3: 動作確認**

- 特定のアグリゲートにVMが配置されることを確認

**学習内容**: ノードのグループ化

---

#### **項目D-3: ライブマイグレーション**（4時間）⭐

**Step D-3-1: ライブマイグレーション設定**

- 共有ストレージの設定（NFS等）
- nova.confの設定

**Step D-3-2: ライブマイグレーションの実行**

- 稼働中のVMを別のコンピュートノードに移動

  ```bash
  openstack server migrate --live compute2 test-vm
  ```

**Step D-3-3: 動作確認**

- サービス無停止での移動を確認

**学習内容**: VMの無停止移動

---

### **カテゴリE: 自動化・IaC**（+3-5日）

**こんな人におすすめ**:

- DevOpsエンジニア
- インフラのコード化を学びたい

#### **項目E-1: Terraform連携**（4時間）⭐⭐⭐

**Step E-1-1: Terraformのインストール**

- Terraformのインストール
- OpenStack Providerの設定

**Step E-1-2: Terraform設定ファイルの作成**

- main.tf、variables.tf、outputs.tfの作成
- ネットワーク、インスタンス、セキュリティグループの定義

**Step E-1-3: リソースのデプロイ**

- terraform init、plan、applyの実行

**Step E-1-4: リソースの管理**

- terraform destroyでの削除
- stateファイルの管理

**学習内容**: IaCによるインフラ管理

---

#### **項目E-2: Ansible連携**（4時間）⭐⭐⭐

**Step E-2-1: Ansibleのインストール**

- Ansibleのインストール
- インベントリファイルの作成

**Step E-2-2: Playbookの作成**

- VM内の構成管理Playbookの作成
- Webサーバーの自動構築Playbook

**Step E-2-3: 実行とテスト**

- ansible-playbookコマンドでの実行
- 冪等性の確認

**学習内容**: VM内の構成管理自動化

---

#### **項目E-3: Heat（オーケストレーション）**（5時間）⭐⭐

**Step E-3-1: Heatのインストール**

- Heatのインストールと設定

**Step E-3-2: テンプレートの作成**

- HOT（Heat Orchestration Template）の作成
- ネットワーク、VM、ボリュームを含むスタック定義

**Step E-3-3: スタックのデプロイ**

- openstack stack createコマンドでのデプロイ
- スタックの更新と削除

**学習内容**: OpenStack標準のIaCツール

---

#### **項目E-4: CI/CDパイプライン**（5時間）⭐

**Step E-4-1: GitLab Runnerのセットアップ**

- GitLab Runnerのインストール

**Step E-4-2: .gitlab-ci.ymlの作成**

- OpenStackへのデプロイパイプラインの定義

**Step E-4-3: パイプラインの実行**

- コミット時の自動デプロイ

**学習内容**: GitLab CI/CDとの統合

---

### **カテゴリF: 次世代への移行**（+5-10日）

**こんな人におすすめ**:

- 本番環境の構築・運用を目指す
- エンタープライズ向けの知識が必要

#### **項目F-1: Kolla-Ansibleへの移行**（8時間）⭐⭐⭐

**Step F-1-1: Kolla-Ansibleのインストール**

- Kolla-Ansibleのインストール
- 仮想環境の準備

**Step F-1-2: インベントリとglobals.ymlの設定**

- multinode、all-in-oneインベントリの作成
- globals.ymlでの各種設定

**Step F-1-3: デプロイの実行**

- prechecks、bootstrap-servers、deploy

  ```bash
  kolla-ansible -i inventory bootstrap-servers
  kolla-ansible -i inventory prechecks
  kolla-ansible -i inventory deploy
  ```

**Step F-1-4: 動作確認**

- コンテナ化されたOpenStackの確認
- 手動構築環境との違いの理解

**学習内容**: コンテナ化されたOpenStack

---

#### **項目F-2: アップグレード実践**（4時間）⭐⭐

**Step F-2-1: アップグレード計画の作成**

- リリースノートの確認
- 互換性の確認

**Step F-2-2: 手動構築環境のアップグレード**

- パッケージの更新
- データベーススキーマの更新

  ```bash
  nova-manage db sync
  neutron-db-manage upgrade heads
  ```

**Step F-2-3: Kolla-Ansible環境のアップグレード**

- kolla-ansible upgradeコマンドの実行

**学習内容**: OpenStackバージョンアップ

---

#### **項目F-3: HA構成の構築**（10時間）⭐

**Step F-3-1: HA環境の設計**

- 3台のコントローラノード構成
- HAProxy、Keepalivedの設計

**Step F-3-2: コントローラの冗長化**

- MariaDB Galera Clusterの構築
- RabbitMQクラスタの構築
- HAProxyとKeepalivedの設定

**Step F-3-3: 動作確認**

- フェイルオーバーのテスト

**学習内容**: 高可用性構成（3台構成）

---

## 📊 学習ロードマップ全体図

```bash
開始
 ↓
[コアパス]
 ├─ Phase 1: 環境準備
 ├─ Phase 2: 基盤構築
 ├─ Phase 3: コアサービス構築
 ├─ Phase 4: 初回VM起動
 └─ Phase 5: 基本演習
 ↓
さらに学習する？
 ├─ [Yes] → オプション学習項目
 │    ├─ カテゴリA: 管理機能強化
 │    ├─ カテゴリB: ネットワーク深掘り
 │    ├─ カテゴリC: 運用・監視
 │    ├─ カテゴリD: スケーラビリティ
 │    ├─ カテゴリE: 自動化・IaC
 │    └─ カテゴリF: 次世代への移行
 └─ [No] → 学習完了
```

---

## 🎯 学習の進め方のコツ

### **1. コアパスは必ず完了させる**

最初にVMが起動するまでを確実に習得しましょう。これがすべての基盤になります。

### **2. CommandとTerraformの使い分け**

**Commandで学ぶべきこと**:

- OpenStackの内部動作の理解
- トラブルシューティング能力
- 各コンポーネントの依存関係

**Terraformで学ぶべきこと**:

- インフラのコード化（IaC）
- 再現可能な環境構築
- バージョン管理されたインフラ

**推奨アプローチ**:

1. 最初はCommandで構築し、仕組みを理解する
2. 理解できたらTerraformでコード化する
3. 両方を併記しているので、自分の学習スタイルに合わせて選択

### **3. オプションは興味に応じて選択**

自分の目的や興味に応じて、カテゴリを選んで深掘りしてください。全部やる必要はありません。

### **4. 推奨学習順序（コアパス後）**

**ステップ1**: カテゴリC（運用・監視）

- 環境を安定させる
- バックアップとログ管理は重要

**ステップ2**: カテゴリB（ネットワーク）またはカテゴリD（スケーラビリティ）

- 本質的な理解を深める
- ネットワークエンジニア → カテゴリB
- インフラエンジニア → カテゴリD

**ステップ3**: カテゴリE（IaC）

- 実務的なスキル
- DevOps志向の方は優先的に
- TerraformとAnsibleの組み合わせ

**ステップ4**: カテゴリF（次世代移行）

- 本番環境を見据えた学習
- Kolla-Ansibleは本番での標準

### **5. つまずいたら**

- **付録B（トラブルシューティング）を参照**
  - プロジェクトのdocs/troubleshooting.mdに記録

- **Server Worldのコメント欄を確認**
  - 同じ問題に遭遇した人の解決策

- **ログファイルを必ず確認する習慣をつける**

  ```bash
  # エラーが出たら必ずログを確認
  sudo journalctl -u nova-compute -f
  tail -f /var/log/nova/nova-compute.log
  ```

- **学習記録をつける**
  - docs/learning-log.mdに日々の進捗を記録
  - 問題と解決策を記録

### **6. Terraformの活用ポイント**

**Terraformが特に有効なケース**:

- ネットワーク・サブネット・ルーターの構築
- 複数インスタンスの一括作成
- セキュリティグループの管理
- 環境の破棄と再作成

**Terraformのベストプラクティス**:

```bash
# ファイル構成の例
terraform/
├── provider.tf        # プロバイダー設定
├── variables.tf       # 変数定義
├── terraform.tfvars   # 変数値（.gitignoreに追加）
├── networks.tf        # ネットワーク関連
├── instances.tf       # インスタンス定義
├── security_groups.tf # セキュリティグループ
└── outputs.tf         # 出力定義

# 基本的なワークフロー
terraform init         # 初期化
terraform fmt          # フォーマット
terraform validate     # 検証
terraform plan         # 実行計画の確認
terraform apply        # 適用
terraform destroy      # 削除
```

---

## 📝 学習記録テンプレート

各Phaseの最後に以下の項目を記録することをおすすめします：

```markdown
## Phase X: [フェーズ名]

### 実施日
YYYY/MM/DD

### 完了したStep
- Step X-1: [ステップ名] ✅
- Step X-2: [ステップ名] ✅

### 使用した方法
- [ ] Command
- [ ] Terraform
- [ ] 両方

### 学んだこと
-
-

### 遭遇した問題と解決策
**問題**:
**解決策**:

### 参考にしたリンク
-

### 次回への引き継ぎ事項
-
```

---

## 🔗 参考リンク

### 必須リンク

- **Server World**: <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy>
- **OpenStack公式ドキュメント**: <https://docs.openstack.org/>
- **プロジェクトリポジトリ**: <https://github.com/y-nosuke/vagrant-samples>

### IaC関連

- **Terraform OpenStack Provider**: <https://registry.terraform.io/providers/terraform-provider-openstack/openstack/latest/docs>
- **Terraform Examples**: <https://github.com/terraform-provider-openstack/terraform-provider-openstack/tree/main/examples>

### オプションリンク

- **Kolla-Ansible**: <https://docs.openstack.org/kolla-ansible/>
- **Ansible OpenStack Collection**: <https://docs.ansible.com/ansible/latest/collections/openstack/cloud/>
- **OpenStack Community**: <https://www.openstack.org/community/>

---

## 📚 Terraformサンプルの全体構成

学習を進める際に、以下のようなTerraform構成を作成することをおすすめします：

```bash
terraform/
├── README.md                  # Terraform使用ガイド
├── .gitignore                 # 機密情報を除外
├── provider.tf                # OpenStack Provider設定
├── variables.tf               # 変数定義
├── terraform.tfvars.example   # 変数値のサンプル
├── outputs.tf                 # 全体の出力定義
│
├── network/                   # ネットワーク関連
│   ├── networks.tf
│   ├── subnets.tf
│   ├── routers.tf
│   └── outputs.tf
│
├── security/                  # セキュリティ関連
│   ├── security_groups.tf
│   ├── keypairs.tf
│   └── outputs.tf
│
├── compute/                   # コンピュート関連
│   ├── flavors.tf
│   ├── images.tf
│   ├── instances.tf
│   ├── floating_ips.tf
│   └── outputs.tf
│
├── storage/                   # ストレージ関連
│   ├── volumes.tf
│   ├── volume_attachments.tf
│   └── outputs.tf
│
└── advanced/                  # 応用編
    ├── loadbalancer.tf
    ├── aggregates.tf
    └── multi_tenant.tf
```

**基本的な.gitignoreファイル**:

```bash
# Terraform
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
terraform.tfvars

# SSH Keys
*.pem
*.pub

# Backup files
*.bak
```

---

**Good luck with your OpenStack learning journey! 🚀**
