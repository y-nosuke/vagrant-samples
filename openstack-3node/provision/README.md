# プロビジョニングスクリプト

このディレクトリには、OpenStack学習環境を構築するための機能ごとのプロビジョニングスクリプトが含まれています。

## 📁 スクリプト一覧

### 全ノード共通設定

- `common_hosts.sh` - hostsファイルの設定（全ノード）
- `common_ntp.sh` - NTP（chrony）の設定（全ノード）
- `common_repository.sh` - OpenStackリポジトリの追加（全ノード）

### 基盤構築（コントローラノード専用）

- `foundation_mariadb.sh` - MariaDBのインストールと設定
- `foundation_rabbitmq.sh` - RabbitMQのインストールと設定
- `foundation_memcached.sh` - Memcachedのインストールと設定
- `foundation_nginx.sh` - Nginxのインストール（Glance用）

### Keystone構築（コントローラノード専用）

- `keystone_db.sh` - Keystoneデータベースの作成
- `keystone_install.sh` - Keystoneパッケージのインストール
- `keystone_config.sh` - Keystone設定ファイルの編集とDB同期
- `keystone_apache.sh` - Apache設定
- `keystone_bootstrap.sh` - Keystone Bootstrapとadmin-openrc作成

### Glance構築（コントローラノード専用）

- `glance_db.sh` - Glanceデータベースの作成
- `glance_install.sh` - Glanceパッケージのインストールとサービス登録
- `glance_config.sh` - Glance設定ファイルの編集とDB同期
- `glance_nginx.sh` - Nginx設定（Glance API用、リバースプロキシ）
- `glance_service.sh` - Glanceサービスの起動（Nginx経由）
- `glance_upload_image.sh` - テストイメージのアップロード（オプション）

## 🚀 使用方法

### Vagrantfileでのプロビジョニング

Vagrantfileに各プロビジョニングスクリプトが定義されています。不要なものはコメントアウトすることで実行をスキップできます。

```ruby
# プロビジョニング（機能ごと、コメントアウトで実行をスキップ可能）
# 全ノード共通設定
controller.vm.provision "hosts", type: "shell", path: "provision/common_hosts.sh"
controller.vm.provision "ntp", type: "shell", path: "provision/common_ntp.sh"
controller.vm.provision "repository", type: "shell", path: "provision/common_repository.sh"

# 基盤構築（コントローラノード専用）
controller.vm.provision "mariadb", type: "shell", path: "provision/foundation_mariadb.sh"
# controller.vm.provision "rabbitmq", type: "shell", path: "provision/foundation_rabbitmq.sh"  # コメントアウトでスキップ

# Glance構築（コントローラノード専用）
controller.vm.provision "glance-db", type: "shell", path: "provision/glance_db.sh"
controller.vm.provision "glance-install", type: "shell", path: "provision/glance_install.sh"
controller.vm.provision "glance-config", type: "shell", path: "provision/glance_config.sh"
controller.vm.provision "glance-service", type: "shell", path: "provision/glance_service.sh"
# controller.vm.provision "glance-upload-image", type: "shell", path: "provision/glance_upload_image.sh", privileged: false  # オプション
```

### 実行方法

#### 1. 初回VM起動時（全プロビジョニング実行）

```bash
vagrant up
```

#### 2. 特定のプロビジョニングのみ実行

```bash
# コントローラノードのhosts設定のみ実行
vagrant provision controller --provision-with hosts

# コントローラノードのKeystone関連をすべて実行
vagrant provision controller --provision-with keystone-db,keystone-install,keystone-config,keystone-apache,keystone-bootstrap
```

#### 3. 手動でSSH接続して実行

```bash
vagrant ssh controller
sudo bash /vagrant/provision/common_hosts.sh
sudo bash /vagrant/provision/foundation_mariadb.sh
```

### 環境変数でパスワードを設定

```bash
# パスワードを環境変数で指定してVM起動
export MARIADB_ROOT_PASSWORD="your_password"
export KEYSTONE_DBPASS="keystone_password"
export ADMIN_PASS="admin_password"
export RABBITMQ_PASSWORD="rabbitmq_password"

vagrant up
```

または、Vagrantfile内で環境変数を設定：

```ruby
controller.vm.provision "mariadb", type: "shell", path: "provision/foundation_mariadb.sh",
  env: {
    "MARIADB_ROOT_PASSWORD" => "your_password"
  }
```

## 📋 実行順序

推奨される実行順序：

1. **全ノード共通設定**（controller、network、compute1）
   - hosts
   - ntp
   - repository

2. **基盤構築**（controllerのみ）
   - mariadb
   - rabbitmq
   - memcached

3. **Keystone構築**（controllerのみ）
   - keystone-db
   - keystone-install
   - keystone-config
   - keystone-apache
   - keystone-bootstrap

4. **Glance構築**（controllerのみ）
   - glance-db
   - glance-install
   - glance-config
   - glance-service
   - glance-upload-image（オプション）

## ✅ 冪等性

各スクリプトは冪等性を持っています。つまり、何度実行しても同じ結果になります。
既に設定済みの項目はスキップされます。

## 🔐 デフォルトパスワード

環境変数を設定しない場合、以下のデフォルトパスワードが使用されます：

- MariaDB root: `password123`
- RabbitMQ openstack: `rabbitmq123`
- Keystone DB: `keystone123`
- Admin User: `admin123`
- Glance DB: `password123`
- Glance User: `password123`

**本番環境では必ず強力なパスワードに変更してください。**

## 💡 使用例

### 例1: 途中から再実行

Phase 2まで完了していて、Phase 3（Keystone）だけやり直したい場合：

```bash
# VagrantfileでPhase 3以外をコメントアウト
# その後、Keystone関連のプロビジョニングのみ実行
vagrant provision controller --provision-with keystone-db,keystone-install,keystone-config,keystone-apache,keystone-bootstrap
```

### 例2: 特定の機能だけ実行

MariaDBだけ再設定したい場合：

```bash
vagrant provision controller --provision-with mariadb
```

### 例3: 手動で段階的に実行

```bash
vagrant ssh controller

# 1. hosts設定
sudo bash /vagrant/provision/common_hosts.sh

# 2. MariaDB設定
sudo bash /vagrant/provision/foundation_mariadb.sh

# 3. Keystone DB作成
sudo bash /vagrant/provision/keystone_db.sh
```

### 例4: Phase 4（Glance）だけ実行

Phase 3まで完了していて、Phase 4（Glance）だけやり直したい場合：

```bash
# VagrantfileでPhase 4以外をコメントアウト
# その後、Glance関連のプロビジョニングのみ実行
vagrant provision controller --provision-with glance-db,glance-install,glance-config,glance-service

# イメージアップロードも含める場合
vagrant provision controller --provision-with glance-db,glance-install,glance-config,glance-service,glance-upload-image
```

### 例5: イメージアップロードのみ実行

Glanceの設定は完了していて、追加のイメージをアップロードしたい場合：

```bash
vagrant provision controller --provision-with glance-upload-image
```

## ⚠️ トラブルシューティング

### プロビジョニングが実行されない

```bash
# Vagrantfileのプロビジョニング設定を確認
grep "vm.provision" Vagrantfile

# 手動で実行してエラーを確認
vagrant ssh controller -c 'sudo bash /vagrant/provision/common_hosts.sh'
```

### エラーが発生した場合

1. エラーメッセージを確認
2. 該当するPhaseのドキュメント（`docs/phase*.md`）を参照
3. トラブルシューティングセクションを確認

### プロビジョニングを完全に無効化

```bash
# Vagrantfileですべてのプロビジョニングをコメントアウト
# または、--no-provisionオプションで起動
vagrant up --no-provision
```

## 📚 次のステップ

Phase 3が完了したら、以下のコマンドで動作確認を行ってください：

```bash
vagrant ssh controller
source ~/admin-openrc
openstack token issue
openstack project list
openstack user list
openstack role list
openstack endpoint list
```

Phase 4が完了したら、以下のコマンドで動作確認を行ってください：

```bash
vagrant ssh controller
source ~/admin-openrc
openstack service list | grep image
openstack endpoint list --service image
openstack image list
sudo systemctl status glance-api
```

Phase 5以降のプロビジョニングスクリプトは、必要に応じて追加予定です。
