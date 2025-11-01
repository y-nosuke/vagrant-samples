# 付録B: トラブルシューティング

**[OpenStack学習資料]**

---

このドキュメントでは、OpenStackの構築・運用時によく遭遇する問題とその解決方法をまとめています。問題発生時の第一歩として活用してください。

---

## 📑 目次

- [基本的なトラブルシューティングの流れ](#基本的なトラブルシューティングの流れ)
- [構築フェーズの問題](#構築フェーズの問題)
- [ネットワーク関連の問題](#ネットワーク関連の問題)
- [ストレージ関連の問題](#ストレージ関連の問題)
- [VM（インスタンス）関連の問題](#vmインスタンス関連の問題)
- [パフォーマンス関連の問題](#パフォーマンス関連の問題)
- [認証・権限の問題](#認証権限の問題)
- [ログの確認方法](#ログの確認方法)
- [便利なデバッグコマンド集](#便利なデバッグコマンド集)

---

## 基本的なトラブルシューティングの流れ

OpenStackで問題が発生した際は、以下の流れで調査を進めます。

### 1. **現象の特定** 🔍

```
□ どのサービスで問題が起きているか？
□ いつから問題が発生したか？
□ 再現性はあるか？
□ エラーメッセージは何か？
```

### 2. **ログの確認** 📋

```bash
# 各サービスのログを確認
sudo journalctl -u openstack-nova-compute -f
sudo tail -f /var/log/nova/nova-compute.log
```

### 3. **サービスの状態確認** ⚙️

```bash
# サービスが正常に動作しているか
sudo systemctl status openstack-nova-compute
openstack compute service list
openstack network agent list
```

### 4. **接続性の確認** 🌐

```bash
# ネットワーク疎通確認
ping <target-ip>
telnet <target-ip> <port>
curl -v http://<api-endpoint>
```

### 5. **設定ファイルの確認** 📄

```bash
# 設定ファイルに誤りがないか
sudo cat /etc/nova/nova.conf | grep -v "^#" | grep -v "^$"
```

### 6. **リソースの確認** 💻

```bash
# CPU、メモリ、ディスクの使用状況
top
df -h
free -h
```

---

## 構築フェーズの問題

### 問題1: コンポーネント間の通信エラー

**症状**:

- `Connection refused` エラー
- `Unable to establish connection to <service>` エラー

**原因**:

- サービスが起動していない
- ファイアウォールでポートがブロックされている
- 設定ファイルのエンドポイントURLが間違っている

**解決方法**:

```bash
# 1. サービスの起動状態を確認
sudo systemctl status openstack-nova-api
sudo systemctl status rabbitmq-server
sudo systemctl status mariadb

# 2. ポートが開いているか確認
sudo netstat -tlnp | grep <port>
sudo ss -tlnp | grep <port>

# 3. ファイアウォールの確認（Ubuntu）
sudo ufw status
sudo ufw allow <port>/tcp

# 4. エンドポイント設定の確認
openstack endpoint list
grep -r "auth_url" /etc/nova/nova.conf
```

### 問題2: データベース接続エラー

**症状**:

- `Can't connect to MySQL server`
- `Access denied for user`

**原因**:

- データベースサービスが起動していない
- 接続情報（ホスト、ユーザー、パスワード）が間違っている
- データベースユーザーの権限が不足

**解決方法**:

```bash
# 1. MariaDB/MySQLの起動確認
sudo systemctl status mariadb

# 2. データベース接続テスト
mysql -u <user> -p<password> -h <host> <database>

# 3. 設定ファイルの接続文字列確認
grep "connection = mysql" /etc/nova/nova.conf

# 正しい形式の例:
# connection = mysql+pymysql://nova:PASSWORD@controller/nova

# 4. データベースユーザーの権限確認
mysql -u root -p
MariaDB> SELECT User, Host FROM mysql.user WHERE User='nova';
MariaDB> SHOW GRANTS FOR 'nova'@'%';

# 5. 権限がない場合は付与
MariaDB> GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'PASSWORD';
MariaDB> FLUSH PRIVILEGES;
```

### 問題3: RabbitMQ接続エラー

**症状**:

- `Connection to AMQP server failed`
- `Socket closed`

**原因**:

- RabbitMQが起動していない
- 認証情報が間違っている
- ネットワーク設定の問題

**解決方法**:

```bash
# 1. RabbitMQの起動確認
sudo systemctl status rabbitmq-server

# 2. RabbitMQユーザーの確認
sudo rabbitmqctl list_users

# 3. 設定ファイルの確認
grep "transport_url" /etc/nova/nova.conf

# 正しい形式の例:
# transport_url = rabbit://openstack:PASSWORD@controller:5672/

# 4. RabbitMQユーザーの作成・権限設定（必要な場合）
sudo rabbitmqctl add_user openstack PASSWORD
sudo rabbitmqctl set_permissions openstack ".*" ".*" ".*"

# 5. RabbitMQ接続テスト
telnet controller 5672
```

### 問題4: Keystoneの認証エラー

**症状**:

- `HTTP 401 Unauthorized`
- `The request you have made requires authentication`

**原因**:

- 環境変数が設定されていない
- 認証情報が間違っている
- Keystoneサービスが起動していない

**解決方法**:

```bash
# 1. 環境変数の確認
env | grep OS_

# 2. 認証情報を再読込
source ~/admin-openrc

# admin-openrcの内容例:
# export OS_PROJECT_DOMAIN_NAME=Default
# export OS_USER_DOMAIN_NAME=Default
# export OS_PROJECT_NAME=admin
# export OS_USERNAME=admin
# export OS_PASSWORD=ADMIN_PASS
# export OS_AUTH_URL=http://controller:5000/v3
# export OS_IDENTITY_API_VERSION=3
# export OS_IMAGE_API_VERSION=2

# 3. Keystoneサービスの確認
sudo systemctl status openstack-keystone

# 4. 手動で認証テスト
openstack token issue

# 5. エンドポイントの確認
openstack catalog list
```

---

## ネットワーク関連の問題

### 問題5: VMにFloating IPが割り当てられない

**症状**:

- Floating IPの割り当てに失敗
- `No more IP addresses available on network`

**原因**:

- 外部ネットワークのIPアドレスプールが枯渇
- ネットワークノードのL3 Agentが停止

**解決方法**:

```bash
# 1. Floating IPプールの確認
openstack floating ip list
openstack network show <external-network>

# 2. L3 Agentの状態確認
openstack network agent list
sudo systemctl status neutron-l3-agent

# 3. 外部ネットワークのサブネット確認
openstack subnet show <external-subnet>

# 4. IPアドレスプールの拡張（必要な場合）
openstack subnet set --allocation-pool \
  start=192.168.100.100,end=192.168.100.200 <external-subnet>

# 5. 未使用のFloating IPを削除
openstack floating ip delete <floating-ip-id>
```

### 問題6: VMが外部と通信できない

**症状**:

- VMから外部へpingが通らない
- 外部からVMへアクセスできない

**原因**:

- セキュリティグループでICMP/TCPがブロックされている
- ルーターが正しく設定されていない
- NATが機能していない

**解決方法**:

```bash
# 1. セキュリティグループの確認
openstack security group list
openstack security group rule list <security-group>

# 2. ICMP（ping）を許可
openstack security group rule create --proto icmp <security-group>

# 3. SSH（TCP 22）を許可
openstack security group rule create --proto tcp --dst-port 22 <security-group>

# 4. HTTP（TCP 80）を許可
openstack security group rule create --proto tcp --dst-port 80 <security-group>

# 5. ルーターの状態確認
openstack router list
openstack router show <router-name>
openstack port list --router <router-name>

# 6. ネットワークノードでNATの確認
# ネットワークノードにログイン
sudo ip netns list
sudo ip netns exec qrouter-<router-id> iptables -t nat -L -n -v

# 7. L3 Agentのログ確認
sudo journalctl -u neutron-l3-agent -f
```

### 問題7: VMのDHCPが機能しない

**症状**:

- VMがIPアドレスを取得できない
- `DHCP discovery timeout`

**原因**:

- DHCP Agentが停止している
- DHCPポートが作成されていない

**解決方法**:

```bash
# 1. DHCP Agentの状態確認
openstack network agent list --agent-type dhcp
sudo systemctl status neutron-dhcp-agent

# 2. ネットワークのDHCP有効化確認
openstack network show <network-name> | grep dhcp_enabled

# 3. DHCPポートの確認
openstack port list --network <network-id> --device-owner network:dhcp

# 4. DHCP Agentの再起動
sudo systemctl restart neutron-dhcp-agent

# 5. ネットワークノードでdnsmasqプロセスの確認
sudo ip netns list
sudo ip netns exec qdhcp-<network-id> ps aux | grep dnsmasq

# 6. ログの確認
sudo journalctl -u neutron-dhcp-agent -f
```

### 問題8: Open vSwitchブリッジの設定エラー

**症状**:

- VMのネットワーク接続が不安定
- `ovs-vsctl: command not found`

**原因**:

- Open vSwitchがインストールされていない
- ブリッジの設定が間違っている

**解決方法**:

```bash
# 1. Open vSwitchのインストール確認
dpkg -l | grep openvswitch
sudo apt install openvswitch-switch

# 2. Open vSwitchサービスの確認
sudo systemctl status openvswitch-switch

# 3. ブリッジの確認
sudo ovs-vsctl show

# 4. ブリッジの作成（br-ex: 外部ネットワーク用）
sudo ovs-vsctl add-br br-ex
sudo ovs-vsctl add-port br-ex <physical-interface>

# 5. インターフェースの状態確認
sudo ovs-vsctl list-ports br-ex
ip link show <physical-interface>

# 6. ネットワークエージェントの再起動
sudo systemctl restart neutron-openvswitch-agent
```

---

## ストレージ関連の問題

### 問題9: Cinderボリュームの作成に失敗

**症状**:

- ボリューム作成が `error` 状態になる
- `No valid backend found`

**原因**:

- Cinder Volumeサービスが起動していない
- バックエンドストレージの設定が間違っている
- LVMのボリュームグループが不足

**解決方法**:

```bash
# 1. Cinderサービスの状態確認
openstack volume service list
sudo systemctl status openstack-cinder-volume

# 2. 設定ファイルの確認
sudo cat /etc/cinder/cinder.conf | grep -A 10 "\[lvm\]"

# 3. LVMボリュームグループの確認
sudo vgs
sudo pvs

# 4. ボリュームグループの作成（必要な場合）
sudo pvcreate /dev/sdb
sudo vgcreate cinder-volumes /dev/sdb

# 5. エラーステータスのボリュームを削除
openstack volume list --status error
openstack volume delete <volume-id>

# 6. ログの確認
sudo tail -f /var/log/cinder/cinder-volume.log
```

### 問題10: ボリュームがVMにアタッチできない

**症状**:

- `Error attaching volume`
- ボリュームが `attaching` 状態で停止

**原因**:

- VMとボリュームが異なるアベイラビリティゾーンにある
- Nova Computeとの通信エラー

**解決方法**:

```bash
# 1. VMとボリュームの状態確認
openstack server show <vm-id>
openstack volume show <volume-id>

# 2. アベイラビリティゾーンの確認
openstack availability zone list

# 3. ボリュームを強制的にデタッチ
openstack volume set --state available <volume-id>

# 4. 再度アタッチを試行
openstack server add volume <vm-id> <volume-id>

# 5. Nova Computeのログ確認
sudo journalctl -u openstack-nova-compute -f
```

---

## VM（インスタンス）関連の問題

### 問題11: VMの起動に失敗

**症状**:

- VM作成が `ERROR` 状態になる
- `No valid host was found`

**原因**:

- コンピュートノードのリソース不足
- Flavorの要求リソースが大きすぎる
- Placementサービスの問題

**解決方法**:

```bash
# 1. コンピュートノードのリソース確認
openstack hypervisor list
openstack hypervisor show <hypervisor-name>

# 2. Flavorの確認
openstack flavor show <flavor-name>

# 3. より小さいFlavorで再試行
openstack flavor list
openstack server create --flavor m1.tiny ...

# 4. Placementサービスの確認
openstack resource provider list
sudo systemctl status openstack-placement-api

# 5. Nova Schedulerのログ確認
sudo journalctl -u openstack-nova-scheduler -f

# 6. Nova Computeの再起動
sudo systemctl restart openstack-nova-compute
```

### 問題12: VMにSSH接続できない

**症状**:

- `Connection refused` または `Connection timed out`
- SSH鍵認証が失敗

**原因**:

- セキュリティグループでSSHポートがブロックされている
- SSH鍵が正しく設定されていない
- VMの起動が完了していない

**解決方法**:

```bash
# 1. セキュリティグループの確認
openstack server show <vm-id> | grep security_groups
openstack security group rule list <security-group>

# 2. SSHポート（22番）が許可されているか確認
# 許可されていない場合は追加
openstack security group rule create --proto tcp --dst-port 22 <security-group>

# 3. VMのコンソールログを確認（起動完了しているか）
openstack console log show <vm-id>

# 4. SSH鍵の確認
openstack keypair list
openstack keypair show <keypair-name>

# 5. 正しい鍵でSSH接続を試行
ssh -i ~/.ssh/your-key.pem ubuntu@<floating-ip>

# 6. VMの内部からネットワークをデバッグ（Horizonコンソール経由）
# VMのWebコンソールにログインして確認
ip addr show
ip route show
ping 8.8.8.8
```

### 問題13: VMのコンソールアクセスができない

**症状**:

- Horizon Webコンソールが接続できない
- `noVNC` エラー

**原因**:

- Nova Novaconsproxy サービスの問題
- ファイアウォールでVNCポートがブロックされている

**解決方法**:

```bash
# 1. Nova Novaconsproxy の状態確認
sudo systemctl status openstack-nova-novncproxy

# 2. VNCコンソールURLの取得
openstack console url show <vm-id>

# 3. ファイアウォールでVNCポート（6080）を許可
sudo ufw allow 6080/tcp

# 4. Nova設定の確認
grep -A 5 "\[vnc\]" /etc/nova/nova.conf

# 正しい設定例:
# [vnc]
# enabled = true
# server_listen = 0.0.0.0
# server_proxyclient_address = <compute-node-ip>
# novncproxy_base_url = http://<controller-ip>:6080/vnc_auto.html

# 5. サービスの再起動
sudo systemctl restart openstack-nova-compute
sudo systemctl restart openstack-nova-novncproxy
```

---

## パフォーマンス関連の問題

### 問題14: VMのパフォーマンスが低い

**症状**:

- VMの応答が遅い
- ディスクI/Oが遅い

**原因**:

- オーバーコミットが過剰
- ホストのリソース不足
- ディスクI/Oのボトルネック

**解決方法**:

```bash
# 1. ホストのリソース使用状況確認
# コンピュートノードで実行
top
iostat -x 1
sar -u 1 10

# 2. VMのリソース割り当て確認
openstack server show <vm-id>

# 3. オーバーコミット設定の確認
grep -E "(cpu_allocation_ratio|ram_allocation_ratio)" /etc/nova/nova.conf

# デフォルト値:
# cpu_allocation_ratio = 16.0
# ram_allocation_ratio = 1.5

# 4. ディスクI/Oパフォーマンスの確認
# VM内で実行
sudo dd if=/dev/zero of=/tmp/test bs=1M count=1024

# 5. VMの配置を別のコンピュートノードに変更（ライブマイグレーション）
openstack server migrate --live <target-compute-node> <vm-id>
```

### 問題15: API応答が遅い

**症状**:

- OpenStackコマンドの実行に時間がかかる
- Horizonの動作が重い

**原因**:

- データベースのパフォーマンス低下
- Memcachedが機能していない

**解決方法**:

```bash
# 1. データベースのスロークエリ確認
mysql -u root -p
MariaDB> SHOW VARIABLES LIKE 'slow_query_log';
MariaDB> SET GLOBAL slow_query_log = 'ON';
MariaDB> SET GLOBAL long_query_time = 2;

# スロークエリログの確認
sudo tail -f /var/log/mysql/mysql-slow.log

# 2. Memcachedの状態確認
sudo systemctl status memcached
echo stats | nc localhost 11211

# 3. データベースの最適化
sudo mysqlcheck -u root -p --optimize --all-databases

# 4. APIプロセス数の調整
# /etc/apache2/sites-available/keystone.conf (Ubuntu)
# WSGIDaemonProcess の processes と threads を調整

# 5. ログレベルの調整（デバッグログを減らす）
# 各サービスの設定ファイルで:
# debug = false
```

---

## 認証・権限の問題

### 問題16: ユーザーがリソースにアクセスできない

**症状**:

- `HTTP 403 Forbidden`
- `You are not authorized to perform this action`

**原因**:

- ユーザーのロールが不足
- プロジェクトに所属していない

**解決方法**:

```bash
# 1. ユーザーの所属プロジェクト確認
openstack user show <username>
openstack role assignment list --user <username>

# 2. ユーザーにロールを付与
openstack role add --user <username> --project <project-name> member

# 3. プロジェクトのメンバー一覧確認
openstack role assignment list --project <project-name>

# 4. ロールの確認
openstack role list
```

### 問題17: サービスアカウントのトークンエラー

**症状**:

- サービス間通信でトークンエラー
- `Token has expired`

**原因**:

- Keystoneの設定問題
- NTPで時刻がずれている

**解決方法**:

```bash
# 1. 各ノードの時刻確認
date

# 2. NTPサービスの確認
sudo systemctl status systemd-timesyncd
timedatectl status

# 3. 時刻同期の強制実行
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd

# 4. トークン有効期限の確認
grep "expiration" /etc/keystone/keystone.conf

# デフォルト: expiration = 3600（1時間）
```

---

## ログの確認方法

### 主要なログファイルの場所

#### **Systemdサービスのログ**

```bash
# Nova関連
sudo journalctl -u openstack-nova-api -f
sudo journalctl -u openstack-nova-scheduler -f
sudo journalctl -u openstack-nova-compute -f

# Neutron関連
sudo journalctl -u neutron-server -f
sudo journalctl -u neutron-l3-agent -f
sudo journalctl -u neutron-dhcp-agent -f
sudo journalctl -u neutron-openvswitch-agent -f

# その他
sudo journalctl -u openstack-keystone -f
sudo journalctl -u openstack-glance-api -f
sudo journalctl -u openstack-cinder-volume -f
```

#### **ファイルベースのログ**

```bash
# Ubuntu/Debian
/var/log/nova/
/var/log/neutron/
/var/log/keystone/
/var/log/glance/
/var/log/cinder/
/var/log/apache2/keystone.log

# 最近のエラーを検索
sudo grep -i error /var/log/nova/nova-compute.log | tail -20
```

### ログレベルの調整

デバッグモードを有効にして詳細なログを出力：

```ini
# /etc/nova/nova.conf (他のサービスも同様)
[DEFAULT]
debug = true
verbose = true
```

設定変更後はサービスを再起動：

```bash
sudo systemctl restart openstack-nova-compute
```

---

## 便利なデバッグコマンド集

### OpenStack CLIでのデバッグ

```bash
# デバッグ情報付きでコマンド実行
openstack --debug server list

# 詳細情報の表示
openstack server show <vm-id>
openstack volume show <volume-id>
openstack network show <network-id>

# JSON形式で出力（プログラマブル）
openstack server list -f json
```

### ネットワークデバッグ

```bash
# ネットワーク名前空間の確認
sudo ip netns list

# 名前空間内でコマンド実行（例: ping）
sudo ip netns exec qrouter-<router-id> ping 8.8.8.8

# 名前空間内のインターフェース確認
sudo ip netns exec qrouter-<router-id> ip addr show

# 名前空間内のiptables確認
sudo ip netns exec qrouter-<router-id> iptables -L -n -v

# パケットキャプチャ
sudo tcpdump -i <interface> -n -v
```

### リソース使用状況の確認

```bash
# コンピュートノード一覧
openstack hypervisor list

# 詳細なリソース情報
openstack hypervisor show <hypervisor-name>

# Quotaの確認
openstack quota show <project-name>

# 使用中のリソース確認
openstack limits show --absolute
```

### データベース直接確認（上級者向け）

```bash
mysql -u root -p

# Novaデータベース
MariaDB> USE nova;
MariaDB> SELECT uuid, display_name, vm_state, power_state FROM instances;

# Neutronデータベース
MariaDB> USE neutron;
MariaDB> SELECT id, name, status FROM networks;

# Cinderデータベース
MariaDB> USE cinder;
MariaDB> SELECT id, display_name, status FROM volumes;
```

---

## 🆘 さらに助けが必要な場合

### 公式リソース

- **OpenStack Docs - Troubleshooting**: <https://docs.openstack.org/operations-guide/ops-maintenance.html>
- **OpenStack Log Analysis**: <https://docs.openstack.org/openstack-ansible/latest/admin/maintenance-tasks.html>

### コミュニティ

- **OpenStack Ask**: <https://ask.openstack.org/>
- **IRC**: #openstack on OFTC
- **メーリングリスト**: <openstack-discuss@lists.openstack.org>

### 日本語リソース

- **Server World**: <https://www.server-world.info/>
- **OpenStack日本ユーザ会**: <https://openstack.jp/>

---

## 📚 関連ドキュメント

- [Part 5: 運用・セキュリティ設計](05_operations_security.md)
- [Part 6: 実践ガイドと構成例](06_practical_guide.md)
- [付録A: 用語集](appendix_a_glossary.md)
- [付録C: 参考リンク集](appendix_c_references.md)

---

**OpenStack学習資料** - Powered by Server World + OpenStack Documentation  
**最終更新**: 2025年10月
