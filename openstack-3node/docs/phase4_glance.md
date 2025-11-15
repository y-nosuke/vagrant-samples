# Phase 4: Glance（イメージサービス）

## 目次

- [Phase 4: Glance（イメージサービス）](#phase-4-glanceイメージサービス)
  - [目次](#目次)
  - [📋 概要](#-概要)
    - [Glanceの主な機能](#glanceの主な機能)
    - [Glanceの主要コンポーネント](#glanceの主要コンポーネント)
  - [🎯 前提条件](#-前提条件)
  - [📐 Glanceのアーキテクチャ](#-glanceのアーキテクチャ)
    - [Step 4-1の詳細フロー](#step-4-1の詳細フロー)
  - [📝 Step 4-1: Glanceデータベースの作成](#-step-4-1-glanceデータベースの作成)
  - [📝 Step 4-2: Keystoneでのサービス登録](#-step-4-2-keystoneでのサービス登録)
  - [📝 Step 4-3: Glanceパッケージのインストール](#-step-4-3-glanceパッケージのインストール)
  - [📝 Step 4-4: Glance設定ファイルの編集](#-step-4-4-glance設定ファイルの編集)
    - [データベースの同期](#データベースの同期)
  - [📝 Step 4-6: Nginx HTTPS Serverの設定](#-step-4-6-nginx-https-serverの設定)
  - [📝 Step 4-7: Glanceサービスの起動](#-step-4-7-glanceサービスの起動)
  - [📝 Step 4-8: Glanceの動作確認](#-step-4-8-glanceの動作確認)
  - [📝 Step 4-9: テストイメージのアップロード](#-step-4-9-テストイメージのアップロード)
    - [Ubuntu Cloud Imageのダウンロード](#ubuntu-cloud-imageのダウンロード)
    - [Glanceへのイメージ登録](#glanceへのイメージ登録)
    - [軽量テストイメージ（Cirros）の追加（オプション）](#軽量テストイメージcirrosの追加オプション)
    - [イメージの保存先確認](#イメージの保存先確認)
  - [✅ Phase 4 完了チェックリスト](#-phase-4-完了チェックリスト)
  - [⚠️ トラブルシューティング](#️-トラブルシューティング)
    - [問題1: Glance APIに接続できない（Nginx設定の問題）](#問題1-glance-apiに接続できないnginx設定の問題)
    - [問題2: イメージのアップロードが失敗する](#問題2-イメージのアップロードが失敗する)
    - [問題3: エンドポイントが見つからない](#問題3-エンドポイントが見つからない)
    - [問題5: イメージのダウンロードが遅い](#問題5-イメージのダウンロードが遅い)
  - [📚 次のステップ](#-次のステップ)
  - [📝 学習記録](#-学習記録)
  - [🔗 関連ドキュメント](#-関連ドキュメント)

---

## 📋 概要

**Phase 4の目的**: VMイメージの管理システムを構築する

**Glance（イメージサービス）**は、OpenStackの**イメージ管理サービス**です。仮想マシン（VM）の起動に必要なOSイメージを保存・管理します。

### Glanceの主な機能

| 機能                       | 説明                                               |
| -------------------------- | -------------------------------------------------- |
| **イメージ登録**           | OSイメージのアップロード                           |
| **イメージ取得**           | VM作成時のイメージ取得                             |
| **イメージメタデータ管理** | イメージの情報管理                                 |
| **イメージストレージ**     | ファイルシステムまたはオブジェクトストレージに保存 |

### Glanceの主要コンポーネント

```mermaid
graph TB
    subgraph "コントローラノード"
        API[glance-api<br/>APIサーバー]
        DB[(Database<br/>メタデータ)]
        Storage[/var/lib/glance/images/<br/>イメージストレージ]
    end

    User[ユーザー] --> API
    API --> DB
    API --> Storage
    Nova[Nova<br/>コンピュートサービス] --> API

    style API fill:#ffffba
    style Storage fill:#e1bee7
```

**コンポーネントの説明**:

- **glance-api**: REST APIを提供するサーバー
- **Database**: イメージのメタデータを保存
- **Storage Backend**: 実際のイメージファイルを保存（今回はファイルシステム）

---

## 🎯 前提条件

Phase 4を開始する前に、以下が完了していることを確認してください：

- ✅ **Phase 1（環境準備）** が完了している
- ✅ **Phase 2（基盤構築）** が完了している
- ✅ **Phase 3（Keystone）** が完了している
- ✅ Controllerノードにログインできる
- ✅ `admin-openrc` ファイルが作成されている
- ✅ `openstack token issue` でトークンが取得できる

**確認コマンド**:

```bash
vagrant ssh controller
source ~/admin-openrc
openstack token issue
```

---

## 📐 Glanceのアーキテクチャ

```mermaid
graph LR
    Start[Phase 3完了] --> Step1[Step 4-1<br/>Glanceのインストール]
    Step1 --> Step2[Step 4-2<br/>テストイメージのアップロード]
    Step2 --> End[Phase 4完了]

    style Step1 fill:#c8e6c9
    style Step2 fill:#c8e6c9
```

### Step 4-1の詳細フロー

```mermaid
graph TB
    A[データベース作成] --> B[ユーザー・サービス登録]
    B --> C[エンドポイント作成]
    C --> D[パッケージインストール]
    D --> E[設定ファイル編集]
    E --> F[DB同期]
    F --> G[サービス起動]
```

---

## 📝 Step 4-1: Glanceデータベースの作成

このStepでは、Glance用のデータベースとユーザーを作成します。

**📌 プロビジョニングファイル**: `provision/glance_db.sh`

**コントローラノードにSSH接続**:

```bash
vagrant ssh controller
```

**MariaDBにrootユーザーで接続**:

```bash
sudo mysql -u root -p
```

パスワードを入力します（Phase 2で設定したrootパスワード）。

**glanceデータベースの作成**:

```sql
CREATE DATABASE glance CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- glance用のデータベースユーザーと権限の作成
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'localhost' IDENTIFIED BY 'GLANCE_DBPASS';
GRANT ALL PRIVILEGES ON glance.* TO 'glance'@'%' IDENTIFIED BY 'GLANCE_DBPASS';

-- 権限の反映
FLUSH PRIVILEGES;

-- データベース接続の確認
SHOW DATABASES;
SELECT host, user FROM mysql.user WHERE user = 'glance';

-- MariaDBから退出
EXIT;
```

**🔐 セキュリティノート**:

- 本番環境では `GLANCE_DBPASS` をより強力なパスワードに変更してください
- パスワードは環境変数やシークレット管理システムで管理することを推奨します

**📌 使用するパスワード**:

- `GLANCE_DBPASS`: Glanceデータベース用（任意の値）
- `GLANCE_PASS`: GlanceユーザーのKeystoneパスワード（任意の値）
- `RABBIT_PASS`: RabbitMQのopenstackユーザーパスワード（Phase 2で設定したもの）

---

## 📝 Step 4-2: Keystoneでのサービス登録

このStepでは、GlanceサービスをKeystoneに登録します。

**📌 プロビジョニングファイル**: `provision/glance_install.sh`（一部）

```bash
# admin-openrcファイルを読み込む:
source ~/admin-openrc

# glanceユーザーの作成:
openstack user create --domain default --project service --password GLANCE_PASS glance

# glanceユーザーにadminロールを付与:
openstack role add --project service --user glance admin

# glanceサービスの作成:
openstack service create --name glance --description "OpenStack Image service" image

# エンドポイントの作成:
openstack endpoint create --region RegionOne image public https://controller:9292
openstack endpoint create --region RegionOne image internal https://controller:9292
openstack endpoint create --region RegionOne image admin https://controller:9292
```

**📌 serviceプロジェクトについて**: Phase 3で作成した `service` プロジェクトを使用します。

**確認**:

```bash
openstack user list
openstack service list
openstack endpoint list --service image
```

**期待される出力**:

```bash
# openstack service list
+----------------------------------+----------+----------+
| ID                               | Name     | Type     |
+----------------------------------+----------+----------+
| ...                              | keystone | identity |
| ...                              | glance   | image    |
+----------------------------------+----------+----------+

# openstack endpoint list --service image
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                       |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ...                              | RegionOne | glance       | image        | True    | public    | https://controller:9292   |
| ...                              | RegionOne | glance       | image        | True    | internal  | https://controller:9292   |
| ...                              | RegionOne | glance       | image        | True    | admin     | https://controller:9292   |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
```

---

## 📝 Step 4-3: Glanceパッケージのインストール

このStepでは、Glanceパッケージと必要な依存パッケージをインストールします。

**📌 プロビジョニングファイル**: `provision/glance_install.sh`（一部）

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y glance
```

**インストール確認**:

```bash
dpkg -l | grep glance
```

---

## 📝 Step 4-4: Glance設定ファイルの編集

このStepでは、Glanceの設定ファイルを編集します。

**📌 プロビジョニングファイル**: `provision/glance_config.sh`（一部）

**設定ファイルのバックアップ**:

```bash
sudo mv /etc/glance/glance-api.conf /etc/glance/glance-api.conf.orig
```

**設定ファイルの新規作成**:

```bash
sudo vi /etc/glance/glance-api.conf
```

**以下の内容を記述**:

```ini
[DEFAULT]
bind_host = 127.0.0.1
transport_url = rabbit://openstack:password@controller:5672
enabled_backends = fs:file

[glance_store]
default_backend = fs

[fs]
filesystem_store_datadir = /var/lib/glance/images/

[database]
connection = mysql+pymysql://glance:GLANCE_DBPASS@controller/glance

[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = glance
password = GLANCE_PASS
insecure = true

[paste_deploy]
flavor = keystone

[oslo_policy]
enforce_new_defaults = true
```

**📌 設定項目の説明**:

- **bind_host**: ローカルホストのみリスン（セキュリティ向上）
- **transport_url**: RabbitMQへの接続（Phase 2で設定したもの）
- **enabled_backends**: 使用するストレージバックエンド
- **[fs]**: ファイルシステムバックエンドの設定
- **insecure**: SSL証明書の検証（false=検証する）
- **enforce_new_defaults**: 新しいポリシーデフォルトを使用

**📌 重要な設定項目**:

- **bind_host = 127.0.0.1**: セキュリティのためローカルのみリスン（Nginx経由でアクセス）
- **transport_url**: RabbitMQへの接続（Phase 2で設定）
- **enabled_backends**: 新しいバックエンド設定方式（複数バックエンド対応）
- **[fs]セクション**: ファイルシステムバックエンドの個別設定
- **insecure = false**: SSL証明書を検証する（本番環境推奨）

---

### データベースの同期

**データベーススキーマの同期**:

```bash
sudo su -s /bin/bash glance -c "glance-manage db_sync"
```

**📌 コマンド解説**: `glance-manage db_sync`

- **目的**: Glanceデータベースのスキーマを作成または更新します
- **動作**: データベース接続設定に基づいて、必要なテーブルを作成します
- **実行タイミング**: 初回インストール時、またはGlanceのバージョンアップ時に実行します

**データベースにテーブルが作成されたことを確認**:

```bash
sudo mysql -u root -p glance -e "SHOW TABLES;"
```

**期待される出力**:

多数のテーブルが作成されていることを確認します：

```bash
+----------------------------------+
| Tables_in_glance                 |
+----------------------------------+
| alembic_version                  |
| image_locations                  |
| image_members                    |
| image_properties                 |
| image_tags                       |
| images                           |
| metadef_namespace_resource_types |
| metadef_namespaces               |
| metadef_objects                  |
| metadef_properties               |
| metadef_resource_types           |
| metadef_tags                     |
| migrate_version                  |
| task_info                        |
| tasks                            |
+----------------------------------+
```

---

## 📝 Step 4-6: Nginx HTTPS Serverの設定

このStepでは、Glance APIをNginxでリバースプロキシするための設定を行います。

**📌 プロビジョニングファイル**: `provision/glance_nginx.sh`

GlanceはNginxをリバースプロキシとして使用し、`glance-api`サービスを起動します。Keystoneと同様にHTTPSで通信するため、SSL証明書を使用してNginxを設定します。

**📌 参考**: [Server World - Glance設定](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=5)

**📌 注意**:

- Nginxパッケージは、Phase 2で既にインストールされています。未インストールの場合は、Phase 2の手順を参照してください。
- SSL証明書は、Phase 3のKeystone設定で作成したものを使用します（`/etc/ssl/certs/keystone/keystone-cert.pem`と`/etc/ssl/private/keystone/keystone-key.pem`）

**Glance用のNginx設定ファイルの作成**:

```bash
sudo vim /etc/nginx/sites-available/glance-api.conf
```

**以下の内容を追加**:

```nginx
upstream glance-api {
    server 127.0.0.1:9292;
}

server {
    listen 172.16.100.10:9292 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://glance-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

> **📌 注意**:
>
> - `listen 172.16.100.10:9292 ssl`: 管理ネットワークのIPアドレスでHTTPSリスニング（SSL終端）
> - `ssl_certificate` / `ssl_certificate_key`: Keystoneで作成したSSL証明書を使用（Phase 3で作成）
> - `client_max_body_size 0`: 大容量ファイル転送のため、リクエストボディサイズを無制限に設定
> - `client_header_buffer_size 64k`: クライアントヘッダーバッファサイズ（OpenStackの長い認証トークンに対応）
> - `large_client_header_buffers 4 64k`: 大きなクライアントヘッダー用のバッファ（4個、各64KB）
> - `upstream glance-api`: glance-apiサービス（127.0.0.1:9292）へのプロキシ設定（バックエンドはHTTP）
> - `proxy_pass http://`: バックエンド（glance-api）はHTTPで接続（SSL終端はNginxで行う）
> - `proxy_set_header`: リバースプロキシで必要なHTTPヘッダーを設定

**Nginx設定の構文チェック**:

```bash
sudo nginx -t
```

**期待される出力**:

```bash
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

エラーが表示された場合は、設定ファイルを確認してください。

**Glanceサイトの有効化**:

```bash
sudo ln -s /etc/nginx/sites-available/glance-api.conf /etc/nginx/sites-enabled/
```

**Nginx設定のリロード**:

```bash
sudo systemctl reload nginx
```

---

## 📝 Step 4-7: Glanceサービスの起動

このStepでは、Glanceサービスを起動します。

**📌 プロビジョニングファイル**: `provision/glance_service.sh`

**glance-apiサービスの起動**:

`bind_host = 127.0.0.1`に設定されているため、glance-apiサービスはlocalhostでリッスンします。Nginxがリバースプロキシとして外部からのアクセスを受け付けます。

```bash
sudo systemctl restart glance-api
sudo systemctl enable glance-api
```

**サービスの状態確認**:

```bash
sudo systemctl status glance-api
```

**期待される出力**:

```bash
● glance-api.service - OpenStack Image Service (glance-api)
     Loaded: loaded (/lib/systemd/system/glance-api.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
```

**Nginxサービスの状態確認**:

```bash
sudo systemctl status nginx
```

**Nginxが正常に起動していることを確認**:

```bash
sudo systemctl enable nginx
sudo systemctl restart nginx
```

**ポートの確認**:

```bash
sudo ss -tlnp | grep :9292
```

**期待される出力例**:

```bash
LISTEN 0      511          172.16.100.10:9292    0.0.0.0:*    users:(("nginx",pid=XXXX,fd=X))
LISTEN 0      511          127.0.0.1:9292        0.0.0.0:*    users:(("glance-api",pid=XXXX,fd=X))
```

- Nginxが`172.16.100.10:9292`でリスニング（管理ネットワーク経由でアクセスを受け付け）
- glance-apiサービスが`127.0.0.1:9292`でリスニング（Nginxからのプロキシを受け付け）

**Glance APIの動作確認**:

Glance APIのバージョン情報を取得します：

```bash
curl -k -s https://controller:9292/ | python3 -m json.tool
```

**期待される出力例**:

```bash
{
    "versions": [
        {
            "id": "v2.25",
            "status": "CURRENT",
            "updated": "2024-XX-XXT00:00:00Z",
            "links": [
                {
                    "rel": "self",
                    "href": "https://controller:9292/v2/"
                }
            ]
        }
    ]
}
```

JSONレスポンスが返ってくることを確認します。

**ログの確認**:

```bash
# glance-apiサービスのログ
sudo journalctl -u glance-api -n 20

# Nginxのアクセスログ
sudo tail -20 /var/log/nginx/access.log
```

---

## 📝 Step 4-8: Glanceの動作確認

このStepでは、Glanceが正常に動作していることを確認します。

Controllerノードで実行します。

```bash
# admin-openrcを読み込む
source ~/admin-openrc

# サービスリストの確認
openstack service list

# エンドポイントの確認
openstack endpoint list --service image

# イメージリストの確認（現時点では空）
openstack image list
```

**期待される出力**:

```bash
# openstack service list
+----------------------------------+----------+----------+
| ID                               | Name     | Type     |
+----------------------------------+----------+----------+
| ...                              | keystone | identity |
| ...                              | glance   | image    |
+----------------------------------+----------+----------+

# openstack endpoint list --service image
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                       |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ...                              | RegionOne | glance       | image        | True    | public    | https://controller:9292   |
| ...                              | RegionOne | glance       | image        | True    | internal  | https://controller:9292   |
| ...                              | RegionOne | glance       | image        | True    | admin     | https://controller:9292   |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+

# openstack image list
# (空のリストが表示される)
```

---

## 📝 Step 4-9: テストイメージのアップロード

このStepでは、テスト用のVMイメージをGlanceにアップロードします。

**📌 プロビジョニングファイル**: `provision/glance_upload_image.sh`

### Ubuntu Cloud Imageのダウンロード

**作業ディレクトリの作成**:

```bash
# 作業ディレクトリを作成
mkdir -p ~/images
cd ~/images
```

**Ubuntu 24.04 (Noble) Cloud Imageのダウンロード**:

```bash
wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
```

**📌 イメージサイズ**: 約400-600MB程度です。ダウンロードに数分かかる場合があります。

**ファイルサイズの確認**:

```bash
ls -lh noble-server-cloudimg-amd64.img
```

**その他の推奨イメージ**:

| OS                         | URL                                                                             |
| -------------------------- | ------------------------------------------------------------------------------- |
| **Ubuntu 24.04**           | <https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img> |
| **Ubuntu 22.04**           | <https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img> |
| **Cirros（軽量テスト用）** | <https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img>          |

---

### Glanceへのイメージ登録

**admin-openrcを読み込む**:

```bash
source ~/admin-openrc
```

**イメージをGlanceに登録**:

```bash
openstack image create "Ubuntu-24.04" \
  --file ~/images/noble-server-cloudimg-amd64.img \
  --disk-format qcow2 \
  --container-format bare \
  --public
```

**パラメータの説明**:

| パラメータ           | 説明                                            |
| -------------------- | ----------------------------------------------- |
| `--file`             | アップロードするファイルパス                    |
| `--disk-format`      | ディスクフォーマット（qcow2, raw, vdi, vmdk等） |
| `--container-format` | コンテナフォーマット（bare推奨）                |
| `--public`           | 全てのプロジェクトで使用可能にする              |

**イメージリストの確認**:

```bash
openstack image list
```

**期待される出力**:

```bash
+--------------------------------------+--------------+--------+
| ID                                   | Name         | Status |
+--------------------------------------+--------------+--------+
| xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | Ubuntu-24.04 | active |
+--------------------------------------+--------------+--------+
```

**イメージの詳細確認**:

```bash
openstack image show "Ubuntu-24.04"
```

**期待される出力**:

```bash
+------------------+------------------------------------------------------+
| Field            | Value                                                |
+------------------+------------------------------------------------------+
| checksum         | ...                                                  |
| container_format | bare                                                 |
| created_at       | ...                                                  |
| disk_format      | qcow2                                                |
| file             | /v2/images/.../file                                  |
| id               | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx                 |
| min_disk         | 0                                                    |
| min_ram          | 0                                                    |
| name             | Ubuntu-24.04                                         |
| owner            | ...                                                  |
| properties       | ...                                                  |
| protected        | False                                                |
| schema           | /v2/schemas/image                                    |
| size             | ...                                                  |
| status           | active                                               |
| tags             |                                                      |
| updated_at       | ...                                                  |
| visibility       | public                                               |
+------------------+------------------------------------------------------+
```

**📌 Statusについて**: `active` になっていればアップロード成功です。

---

### 軽量テストイメージ（Cirros）の追加（オプション）

開発・テスト用に、軽量なCirrosイメージも登録しておくと便利です。

**Cirrosイメージのダウンロード**:

```bash
cd ~/images
wget https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
```

**Glanceに登録**:

```bash
source ~/admin-openrc
openstack image create "Cirros-0.6.2" \
  --file ~/images/cirros-0.6.2-x86_64-disk.img \
  --disk-format qcow2 \
  --container-format bare \
  --public
```

**確認**:

```bash
openstack image list
```

**Cirrosの特徴**:

- サイズ: 約13MB（非常に軽量）
- 起動時間: 数秒
- テスト用途に最適

---

### イメージの保存先確認

```bash
# イメージファイルの確認
sudo ls -lh /var/lib/glance/images/

# ディスク使用量の確認
sudo du -sh /var/lib/glance/images/
```

**期待される出力**:

```bash
# ls -lh /var/lib/glance/images/
total 500M
-rw-r----- 1 glance glance 500M ... xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

# du -sh /var/lib/glance/images/
500M    /var/lib/glance/images/
```

---

## ✅ Phase 4 完了チェックリスト

以下を確認してください：

- [ ] Step 4-1: glanceデータベースが作成されている
- [ ] Step 4-2: glanceユーザーがKeystoneに登録されている
- [ ] Step 4-2: glanceサービスがKeystoneに登録されている
- [ ] Step 4-2: glanceエンドポイントが作成されている（public, internal, admin）
- [ ] Step 4-3: Glanceパッケージがインストールされている
- [ ] Step 4-4: Glance設定ファイルが適切に設定されている
- [ ] Step 4-5: データベーススキーマが同期されている
- [ ] Step 4-6: Nginx設定ファイルが作成されている
- [ ] Step 4-6: Glanceサイトが有効化されている
- [ ] Step 4-7: Nginxサービスが正常に起動している
- [ ] Step 4-7: glance-apiサービスが正常に起動している
- [ ] Step 4-8: ポート9292がNginx経由でリスニングしている
- [ ] Step 4-8: `curl -k https://controller:9292/` でJSONレスポンスが返ってくる
- [ ] Step 4-8: `openstack image list` でイメージリストが表示される
- [ ] Step 4-9: Ubuntu Cloud Imageがアップロードされ、statusが `active` になっている
- [ ] Step 4-9: `/var/lib/glance/images/` にイメージファイルが保存されている

**確認コマンド例**:

```bash
# Controllerノードで実行
vagrant ssh controller
source ~/admin-openrc

# サービスの確認
openstack service list | grep image
openstack endpoint list --service image

# イメージリストの確認
openstack image list

# Nginxサービスの状態確認
sudo systemctl status nginx

# glance-apiサービスの状態確認
sudo systemctl status glance-api

# ポート9292のリスニング確認
sudo ss -tlnp | grep :9292

# Glance APIの直接確認
curl -k -s https://controller:9292/ | python3 -m json.tool

# イメージファイルの確認
sudo ls -lh /var/lib/glance/images/
```

---

## ⚠️ トラブルシューティング

> **📌 注意**: 認証エラーなどの汎用的な問題については、[トラブルシューティングガイド](./appendix_b_troubleshooting.md)を参照してください。

### 問題1: Glance APIに接続できない（Nginx設定の問題）

**症状**:

```bash
openstack image list
# Failed to contact the endpoint at https://controller:9292 for discovery.
# The image service for : exists but does not have any supported versions.
```

**解決策**:

1. Nginxサービスが起動しているか確認:

   ```bash
   sudo systemctl status nginx
   ```

2. glance-apiサービスが起動しているか確認:

   ```bash
   sudo systemctl status glance-api
   ```

3. Nginx設定の構文を確認:

   ```bash
   sudo nginx -t
   ```

4. Glanceサイトが有効化されているか確認:

   ```bash
   ls -la /etc/nginx/sites-enabled/glance-api.conf
   # シンボリックリンクが存在することを確認
   
   # 存在しない場合は作成
   sudo ln -s /etc/nginx/sites-available/glance-api.conf /etc/nginx/sites-enabled/
   sudo systemctl reload nginx
   ```

5. ポート9292がリスニングしているか確認:

   ```bash
   sudo ss -tlnp | grep :9292
   ```

   以下の2つが表示されることを確認:
   - `0.0.0.0:9292` (Nginx)
   - `127.0.0.1:9292` (glance-apiサービス)

6. Nginxエラーログを確認:

   ```bash
   sudo tail -50 /var/log/nginx/error.log
   ```

7. glance-apiサービスのログを確認:

   ```bash
   sudo journalctl -u glance-api -n 50
   ```

8. Glance APIの直接確認:

   ```bash
   curl -k -s https://controller:9292/ | python3 -m json.tool
   ```

   JSONレスポンスが返ってくることを確認します。

---

### 問題2: イメージのアップロードが失敗する

**症状**:

```bash
openstack image create ...
# Error: ...
```

**解決策**:

1. ディスク容量を確認:

   ```bash
   df -h /var/lib/glance/images/
   ```

2. ディレクトリの権限を確認:

   ```bash
   ls -ld /var/lib/glance/images/
   # drwxr-x--- 2 glance glance ... /var/lib/glance/images/
   ```

3. 権限がない場合は修正:

   ```bash
   sudo chown -R glance:glance /var/lib/glance/images/
   sudo chmod 750 /var/lib/glance/images/
   ```

---

### 問題3: エンドポイントが見つからない

**症状**:

```bash
openstack image list
# Could not find endpoint for image
```

**解決策**:

1. エンドポイントを確認:

   ```bash
   openstack endpoint list --service image
   ```

2. エンドポイントがない場合は再作成:

   ```bash
   source ~/admin-openrc
   openstack endpoint create --region RegionOne image public https://controller:9292
   openstack endpoint create --region RegionOne image internal https://controller:9292
   openstack endpoint create --region RegionOne image admin https://controller:9292
   ```

---

### 問題5: イメージのダウンロードが遅い

**解決策**:

1. ミラーサイトを使用:

   ```bash
   # 日本のミラー（JAIST）
   wget https://ftp.jaist.ac.jp/pub/Linux/ubuntu-cloud-images/noble/current/noble-server-cloudimg-amd64.img
   ```

2. または軽量なCirrosイメージでテスト:

   ```bash
   wget https://download.cirros-cloud.net/0.6.2/cirros-0.6.2-x86_64-disk.img
   ```

---

**その他の問題**: 認証エラーなどの汎用的な問題については、[トラブルシューティングガイド](./appendix_b_troubleshooting.md)を参照してください。

---

## 📚 次のステップ

Phase 4が完了したら、Phase 5（Nova - コンピュートサービス）に進んでください：

**Phase 5: Nova（コンピュートサービス）**

- Novaコントローラ側のインストール
- Novaコンピュート側のインストール
- Flavorの作成
- 詳細: [Phase 5: Nova構築](phase5_nova.md)

**学習のポイント**:

- Glanceで登録したイメージを使用してVMを作成します
- Novaは複数のノード（Controller、Compute）に分散配置されます
- ハイパーバイザー（KVM）の理解が重要です

---

## 📝 学習記録

Phase 4の学習が完了したら、以下のテンプレートに記録してください：

```markdown
### 実施日
YYYY/MM/DD

### 完了したStep
- [x] Step 4-1: Glanceデータベースの作成
- [x] Step 4-2: Keystoneでのサービス登録
- [x] Step 4-3: Glanceパッケージのインストール
- [x] Step 4-4: Glance設定ファイルの編集
- [x] Step 4-5: データベースの同期
- [x] Step 4-6: Nginx HTTPS Serverの設定
- [x] Step 4-7: Glanceサービスの起動
- [x] Step 4-8: Glanceの動作確認
- [x] Step 4-9: テストイメージのアップロード

### 使用した方法
- [x] Command

### 学んだこと
- Glanceがイメージの管理を行うこと
- イメージのメタデータとファイルが分離されていること
- ストレージバックエンドの概念
- Cloud Imageの特徴（cloud-init対応）

### 遭遇した問題と解決策
**問題**: 
**解決策**: 

### 参考にしたリンク
- [Server World - Glance](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=5)

### 次回への引き継ぎ事項
- アップロードしたイメージのID
- 追加でアップロードしたいイメージ
```

---

## 🔗 関連ドキュメント

- **Phase 3: Keystone構築** - [phase3_keystone.md](phase3_keystone.md)（前のPhase）
- **Phase 5: Nova構築** - [phase5_nova.md](phase5_nova.md)（次のPhase）
- **ロードマップ** - [openstack-learning-roadmap.md](openstack-learning-roadmap.md)
- **Server World - Glance** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=5>
- **Server World - Add VM Images** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=6>
- **OpenStack公式ドキュメント - Glance** - <https://docs.openstack.org/glance/>

---

**Good luck with Phase 4! 🚀**
