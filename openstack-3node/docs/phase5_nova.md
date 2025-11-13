# Phase 5: Nova（コンピュートサービス）

## 📋 目次

- [Phase 5: Nova（コンピュートサービス）](#phase-5-novaコンピュートサービス)
  - [📋 目次](#-目次)
  - [概要](#概要)
    - [Novaの主な機能](#novaの主な機能)
    - [Novaのアーキテクチャ](#novaのアーキテクチャ)
  - [前提条件](#前提条件)
  - [Phase 5の構成図](#phase-5の構成図)
    - [Step 5-1の詳細フロー](#step-5-1の詳細フロー)
  - [📝 Step 5-1: Novaコントローラ側のインストール](#-step-5-1-novaコントローラ側のインストール)
    - [データベースの作成](#データベースの作成)
    - [Keystoneでのサービス登録](#keystoneでのサービス登録)
    - [Placementパッケージのインストール](#placementパッケージのインストール)
    - [Novaパッケージのインストール](#novaパッケージのインストール)
    - [Placement設定ファイルの編集](#placement設定ファイルの編集)
    - [Apache2とNginxの設定](#apache2とnginxの設定)
    - [Nova設定ファイルの編集](#nova設定ファイルの編集)
    - [データベースの同期とCellの設定](#データベースの同期とcellの設定)
    - [Novaサービスの起動](#novaサービスの起動)
    - [Novaの動作確認](#novaの動作確認)
  - [📝 Step 5-2: Novaコンピュート側のインストール](#-step-5-2-novaコンピュート側のインストール)
    - [Novaパッケージのインストール](#novaパッケージのインストール-1)
    - [Nova設定ファイルの編集](#nova設定ファイルの編集-1)
    - [libvirt / KVMの設定確認](#libvirt--kvmの設定確認)
    - [Nova Computeサービスの起動](#nova-computeサービスの起動)
    - [コントローラでのコンピュートノード登録確認](#コントローラでのコンピュートノード登録確認)
  - [📝 Step 5-3: Flavorの作成](#-step-5-3-flavorの作成)
    - [標準Flavorの作成](#標準flavorの作成)
    - [Flavorの確認](#flavorの確認)
  - [✅ Phase 5 完了チェックリスト](#-phase-5-完了チェックリスト)
  - [⚠️ トラブルシューティング](#️-トラブルシューティング)
    - [問題1: Nova APIに接続できない（502 Bad Gateway）](#問題1-nova-apiに接続できない502-bad-gateway)
    - [問題2: nova-conductorがPlacementサービスに接続できない](#問題2-nova-conductorがplacementサービスに接続できない)
    - [問題3: コンピュートノードが登録されない](#問題3-コンピュートノードが登録されない)
    - [問題4: KVMが有効になっていない](#問題4-kvmが有効になっていない)
    - [問題4: データベース同期エラー](#問題4-データベース同期エラー)
    - [問題5: Cellの登録エラー](#問題5-cellの登録エラー)
  - [📚 次のステップ](#-次のステップ)
  - [📝 学習記録](#-学習記録)
  - [🔗 関連ドキュメント](#-関連ドキュメント)

---

## 概要

**Phase 5の目的**: 仮想マシンの管理システムを構築する

**Nova（コンピュートサービス）**は、OpenStackの**仮想マシン管理サービス**です。VMの作成、起動、停止、削除などのライフサイクル管理を行います。

### Novaの主な機能

| 機能                     | 説明                                       |
| ------------------------ | ------------------------------------------ |
| **VMの作成・管理**       | インスタンスの作成、起動、停止、削除       |
| **スケジューリング**     | 適切なコンピュートノードへのVM配置         |
| **ハイパーバイザー管理** | KVM、QEMU、Xen等のハイパーバイザーとの連携 |
| **リソース管理**         | CPU、メモリ、ディスクの割り当てと管理      |
| **Flavor管理**           | VMのインスタンスタイプ（サイズ）の定義     |
| **コンソールアクセス**   | VNC/SPICEによるVMコンソールへのアクセス    |

### Novaのアーキテクチャ

```mermaid
graph TB
    subgraph "コントローラノード"
        NovaAPI[nova-api<br/>APIサーバー]
        NovaScheduler[nova-scheduler<br/>スケジューラー]
        NovaConductor[nova-conductor<br/>コンダクター]
        NovaVNC[nova-novncproxy<br/>VNCプロキシ]
        NovaDB[(Database<br/>nova_api, nova, nova_cell0)]
    end

    subgraph "コンピュートノード"
        NovaCompute[nova-compute<br/>コンピュートエージェント]
        Libvirt[libvirt / KVM<br/>ハイパーバイザー]
    end

    User[ユーザー] --> NovaAPI
    NovaAPI --> NovaScheduler
    NovaScheduler --> NovaConductor
    NovaConductor --> NovaCompute
    NovaCompute --> Libvirt
    NovaAPI --> NovaDB
    NovaConductor --> NovaDB
    NovaCompute --> NovaDB
    User --> NovaVNC
    NovaVNC --> NovaCompute

    style NovaAPI fill:#ffffba
    style NovaScheduler fill:#c8e6c9
    style NovaConductor fill:#b3e5fc
    style NovaCompute fill:#ffccbc
    style Libvirt fill:#e1bee7
```

**主要コンポーネント**:

- **nova-api**: REST APIを提供するサーバー（コントローラノード）
- **nova-scheduler**: 適切なコンピュートノードを選択（コントローラノード）
- **nova-conductor**: データベースアクセスを仲介（コントローラノード）
- **nova-compute**: 実際にVMを管理するエージェント（コンピュートノード）
- **nova-novncproxy**: VNCコンソールへのアクセスを提供（コントローラノード）
- **Database**: インスタンス情報、リソース情報を保存（3つのデータベース: nova_api、nova、nova_cell0）

---

## 前提条件

Phase 5を開始する前に、以下が完了していることを確認してください：

- ✅ **Phase 1（環境準備）** が完了している
- ✅ **Phase 2（基盤構築）** が完了している
- ✅ **Phase 3（Keystone）** が完了している
- ✅ **Phase 4（Glance）** が完了している
- ✅ Controllerノードにログインできる
- ✅ Compute1ノードにログインできる
- ✅ `admin-openrc` ファイルが作成されている
- ✅ `openstack token issue` でトークンが取得できる
- ✅ Glanceにイメージが登録されている（Phase 4でアップロードしたイメージ）

**確認コマンド**:

```bash
vagrant ssh controller
source ~/admin-openrc
openstack token issue
openstack image list
```

---

## Phase 5の構成図

```mermaid
graph LR
    Start[Phase 4完了] --> Step1[Step 5-1<br/>Novaコントローラ側のインストール]
    Step1 --> Step2[Step 5-2<br/>Novaコンピュート側のインストール]
    Step2 --> Step3[Step 5-3<br/>Flavorの作成]
    Step3 --> End[Phase 5完了]

    style Step1 fill:#c8e6c9
    style Step2 fill:#c8e6c9
    style Step3 fill:#c8e6c9
```

### Step 5-1の詳細フロー

```mermaid
graph TB
    A[データベース作成<br/>nova_api, nova, nova_cell0, placement] --> B[ユーザー・サービス登録<br/>nova, placement]
    B --> C[エンドポイント作成<br/>compute, placement]
    C --> D[パッケージインストール<br/>placement-api, nova-api, nova-scheduler,<br/>nova-conductor, nova-novncproxy]
    D --> E[設定ファイル編集<br/>placement, nova]
    E --> F[DB同期<br/>placement, nova]
    F --> G[Cell0登録]
    G --> H[Cell1作成]
    H --> I[サービス起動<br/>nova-api, etc.<br/>（placement-apiは自動起動）]
```

---

## 📝 Step 5-1: Novaコントローラ側のインストール

### データベースの作成

**コントローラノードにSSH接続**:

```bash
vagrant ssh controller
```

**MariaDBにrootユーザーで接続**:

```bash
sudo mysql -u root -p
```

パスワードを入力します（Phase 2で設定したrootパスワード）。

**Nova用データベースの作成**:

Novaは3つのデータベースを使用します。また、Placementサービス用のデータベースも作成します：

```sql
-- nova_apiデータベースの作成
CREATE DATABASE nova_api CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- novaデータベースの作成
CREATE DATABASE nova CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- placementデータベースの作成
CREATE DATABASE placement CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- nova_cell0データベースの作成
CREATE DATABASE nova_cell0 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- nova用のデータベースユーザーと権限の作成
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_api.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';

GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';

GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'localhost' IDENTIFIED BY 'PLACEMENT_DBPASS';
GRANT ALL PRIVILEGES ON placement.* TO 'placement'@'%' IDENTIFIED BY 'PLACEMENT_DBPASS';

GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova_cell0.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';

-- 権限の反映
FLUSH PRIVILEGES;

-- データベース接続の確認
SHOW DATABASES;
SELECT host, user FROM mysql.user WHERE user = 'nova';
SELECT host, user FROM mysql.user WHERE user = 'placement';

-- MariaDBから退出
EXIT;
```

> **🔐 セキュリティノート**:
>
> - 本番環境では `NOVA_DBPASS` をより強力なパスワードに変更してください
> - パスワードは環境変数やシークレット管理システムで管理することを推奨します
>
> **📌 使用するパスワード**:
>
> - `NOVA_DBPASS`: Novaデータベース用（任意の値）
> - `NOVA_PASS`: NovaユーザーのKeystoneパスワード（任意の値）
> - `PLACEMENT_DBPASS`: Placementデータベース用（任意の値）
> - `PLACEMENT_PASS`: PlacementユーザーのKeystoneパスワード（任意の値）
> - `RABBIT_PASS`: RabbitMQのopenstackユーザーパスワード（Phase 2で設定したもの）

> **📌 データベースの説明**:
>
> - **nova_api**: API関連のデータ（エンドポイント、サービス情報など）
> - **nova**: インスタンス情報、リソース情報（Cell1用）
> - **placement**: Placementサービス用（リソースの割り当て情報を管理）
> - **nova_cell0**: 未配置のインスタンス情報（Cell0用）

> **📌 参考**: [Server World - Nova の設定 #1](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=7) では、placementデータベースの作成も含まれています。

---

### Keystoneでのサービス登録

**admin-openrcファイルを読み込む**:

```bash
source ~/admin-openrc
```

**novaユーザーの作成**:

```bash
openstack user create --domain default --project service --password NOVA_PASS nova
```

> **📌 serviceプロジェクトについて**: Phase 3で作成した `service` プロジェクトを使用します。

**novaユーザーにadminロールを付与**:

```bash
openstack role add --project service --user nova admin
```

**novaサービスの作成**:

```bash
openstack service create --name nova --description "OpenStack Compute service" compute
```

**エンドポイントの作成**:

```bash
# 公式推奨形式（%(tenant_id)sなし）
openstack endpoint create --region RegionOne compute public https://controller:8774/v2.1
openstack endpoint create --region RegionOne compute internal https://controller:8774/v2.1
openstack endpoint create --region RegionOne compute admin https://controller:8774/v2.1
```

> **📌 注意**: Server Worldの手順では`https://controller:8774/v2.1/%(tenant_id)s`という形式を使用していますが、公式ドキュメントによると、Nova API v2.1では`%(tenant_id)s`は不要です。上記の形式（`%(tenant_id)s`なし）が公式推奨です。

> **📌 エンドポイントURLの`%(tenant_id)s`について**:
>
> - **公式ドキュメントの見解**:
>   - **Nova API v2.1では、エンドポイントURLに`%(tenant_id)s`を含める必要はありません**
>   - v2.1では、テナントIDは認証トークンを通じて提供されるため、URLパスに含める必要がなくなりました
>   - 推奨される形式: `https://controller:8774/v2.1`（`%(tenant_id)s`なし）
> - **Server Worldの手順について**:
>   - Server Worldの手順では`https://controller:8774/v2.1/%(tenant_id)s`という形式を使用しています
>   - これは後方互換性のため、または古いバージョンの手順に基づいている可能性があります
>   - 実際には、`%(tenant_id)s`を含めても動作しますが、公式ドキュメントでは不要とされています
> - **Nova API v2 vs v2.1の違い**:
>   - **v2**: `/v2/%(tenant_id)s`形式を使用（URLパスにテナントIDが必要）
>   - **v2.1**: `/v2.1`形式を使用（テナントIDは認証トークンから取得）
> - **実際の動作**:
>   - `%(tenant_id)s`なし: `https://controller:8774/v2.1` → 認証トークンからプロジェクトIDを取得
>   - `%(tenant_id)s`あり: `https://controller:8774/v2.1/%(tenant_id)s` → URLパスでもテナントIDを指定可能（後方互換性）
> - **推奨**:
>   - 公式ドキュメントに従い、`%(tenant_id)s`なしの形式（`https://controller:8774/v2.1`）を使用することを推奨します
>   - ただし、Server Worldの手順に従う場合は、`%(tenant_id)s`を含める形式でも動作します

**placementユーザーの作成**:

```bash
openstack user create --domain default --project service --password PLACEMENT_PASS placement
```

**placementユーザーにadminロールを付与**:

```bash
openstack role add --project service --user placement admin
```

**placementサービスの作成**:

```bash
openstack service create --name placement --description "OpenStack Placement service" placement
```

**placementエンドポイントの作成**:

```bash
openstack endpoint create --region RegionOne placement public https://controller:8778
openstack endpoint create --region RegionOne placement internal https://controller:8778
openstack endpoint create --region RegionOne placement admin https://controller:8778
```

> **📌 注意**: Placement APIもNginx経由でHTTPSでアクセスするため、エンドポイントURLは`https://controller:8778`を使用します。

**確認**:

```bash
openstack user list
openstack service list
openstack endpoint list --service compute
openstack endpoint list --service placement
```

**期待される出力**:

```bash
# openstack service list
+----------------------------------+-----------+-----------+
| ID                               | Name      | Type      |
+----------------------------------+-----------+-----------+
| ...                              | nova      | compute   |
| ...                              | placement | placement |
| ...                              | keystone  | identity  |
| ...                              | glance    | image     |
+----------------------------------+-----------+-----------+

# openstack endpoint list --service compute
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                       |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ...                              | RegionOne | nova         | compute      | True    | public    | https://controller:8774/v2.1|
| ...                              | RegionOne | nova         | compute      | True    | internal  | https://controller:8774/v2.1|
| ...                              | RegionOne | nova         | compute      | True    | admin     | https://controller:8774/v2.1|
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
```

---

### Placementパッケージのインストール

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y placement-api
```

**インストール確認**:

```bash
dpkg -l | grep placement
```

### Novaパッケージのインストール

```bash
sudo apt update
sudo apt install -y nova-api nova-conductor nova-scheduler nova-novncproxy
```

**インストール確認**:

```bash
dpkg -l | grep nova
```

---

### Placement設定ファイルの編集

**設定ファイルのバックアップ**:

```bash
sudo mv /etc/placement/placement.conf /etc/placement/placement.conf.orig
```

**設定ファイルの新規作成**:

```bash
sudo vim /etc/placement/placement.conf
```

**以下の内容を記述**:

```ini
[DEFAULT]
debug = false

[api]
auth_strategy = keystone

[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = placement
password = PLACEMENT_PASS
insecure = true

[placement_database]
connection = mysql+pymysql://placement:PLACEMENT_DBPASS@controller/placement
```

> **📌 設定項目の説明**:
>
> - **connection**: Placementデータベースへの接続設定
> - **auth_strategy**: Keystone認証を使用
> - **insecure**: SSL証明書の検証（false=検証する）

**データベースの同期**:

```bash
sudo su -s /bin/bash placement -c "placement-manage db sync"
```

> **📌 コマンド解説**: `placement-manage db sync`
>
> - **目的**: Placementデータベースのスキーマを作成または更新します
> - **動作**: データベース接続設定に基づいて、必要なテーブルを作成します

**データベースにテーブルが作成されたことを確認**:

```bash
sudo mysql -u root -p placement -e "SHOW TABLES;" | head -20
```

**設定ファイルのパーミッション設定**:

```bash
sudo chmod 640 /etc/placement/placement.conf
sudo chgrp placement /etc/placement/placement.conf
```

> **📌 セキュリティ**: 設定ファイルにはパスワードが含まれているため、適切なパーミッションを設定します。

---

### Apache2とNginxの設定

Server Worldの手順では、Apache2とNginxの設定が必要です。

**Apache2の設定（Placement用）**:

```bash
sudo vim /etc/apache2/sites-available/placement-api.conf
```

**以下の内容を記述**:

```apache
# 1行目 : 変更
Listen 127.0.0.1:8778
```

**Apache2サイトの有効化**:

```bash
sudo a2ensite placement-api
sudo systemctl restart apache2
```

**Nginxの設定（Nova/Placement/novncproxy用）**:

Glanceと同様に、Nova/Placement/novncproxyも`/etc/nginx/sites-available/`に個別の設定ファイルを作成します。

> **📌 `stream`セクションと`server`ブロック（HTTP）の違い**:
>
> - **`stream`セクション**: TCP/UDPレベルのプロキシ（レイヤー4）
>   - TCPストリームをそのまま転送
>   - HTTPヘッダーの解析や変更ができない
>   - `client_max_body_size`などのHTTP特有の設定が使えない
>   - MySQL、Redis、SSHなどのTCPプロトコル用
>
> - **`server`ブロック（HTTP）**: HTTPレベルのプロキシ（レイヤー7）
>   - HTTPリクエスト/レスポンスを解析できる
>   - HTTPヘッダーの追加・変更が可能（`proxy_set_header`など）
>   - `client_max_body_size`、`client_header_buffer_size`などのHTTP特有の設定が使える
>   - `location`ディレクティブでパスベースのルーティングが可能
>   - OpenStackのHTTP/HTTPSサービス用
>
> OpenStackのサービス（Glance、Nova、Placementなど）はHTTP/HTTPSで動作し、大容量ファイル転送やHTTPヘッダーの操作が必要なため、**`server`ブロック（HTTP）を使う方が適切**です。

**Nova API用のNginx設定ファイルの作成**:

```bash
sudo vim /etc/nginx/sites-available/nova-api.conf
```

**以下の内容を記述**:

```nginx
upstream nova-api {
    server 127.0.0.1:8774;
}

server {
    listen 172.16.100.10:8774 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://nova-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Nova Metadata API用のNginx設定ファイルの作成**:

```bash
sudo vim /etc/nginx/sites-available/nova-metadata-api.conf
```

**以下の内容を記述**:

```nginx
upstream nova-metadata-api {
    server 127.0.0.1:8775;
}

server {
    listen 172.16.100.10:8775 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://nova-metadata-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Placement API用のNginx設定ファイルの作成**:

```bash
sudo vim /etc/nginx/sites-available/placement-api.conf
```

**以下の内容を記述**:

```nginx
upstream placement-api {
    server 127.0.0.1:8778;
}

server {
    listen 172.16.100.10:8778 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://placement-api;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

> **📌 注意**: Placement APIはApacheで動作していますが、外部からアクセスするためにNginxでプロキシします。Apacheは`127.0.0.1:8778`でリスニングし、Nginxが`172.16.100.10:8778`（HTTPS）でリスニングして、バックエンドのApacheにプロキシします。

**Nova VNC Proxy用のNginx設定ファイルの作成**:

```bash
sudo vim /etc/nginx/sites-available/novncproxy.conf
```

**以下の内容を記述**:

```nginx
upstream novncproxy {
    server 127.0.0.1:6080;
}

server {
    listen 172.16.100.10:6080 ssl;
    server_name controller;

    ssl_certificate /etc/ssl/certs/keystone/keystone-cert.pem;
    ssl_certificate_key /etc/ssl/private/keystone/keystone-key.pem;

    client_max_body_size 0;
    client_header_buffer_size 64k;
    large_client_header_buffers 4 64k;

    location / {
        proxy_pass http://novncproxy;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

**Nginxサイトの有効化**:

```bash
sudo ln -s /etc/nginx/sites-available/nova-api.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/nova-metadata-api.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/placement-api.conf /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/novncproxy.conf /etc/nginx/sites-enabled/
```

> **📌 注意**:
>
> - `listen 172.16.100.10:ポート番号 ssl`: 管理ネットワークのIPアドレスでHTTPSリスニング（SSL終端）
> - `ssl_certificate` / `ssl_certificate_key`: Keystoneで作成したSSL証明書を使用（Server Worldの手順に合わせてHTTPSで通信）
> - `client_max_body_size 0`: 大容量ファイル転送のため、リクエストボディサイズを無制限に設定
> - `client_header_buffer_size 64k`: クライアントヘッダーバッファサイズ（OpenStackの長い認証トークンに対応）
> - `large_client_header_buffers 4 64k`: 大きなクライアントヘッダー用のバッファ（4個、各64KB）
> - `proxy_pass http://`: バックエンド（Nova API）はHTTPで接続（SSL終端はNginxで行う）
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

**Nginx設定のリロード**:

```bash
sudo systemctl reload nginx
```

---

### Nova設定ファイルの編集

**設定ファイルのバックアップ**:

```bash
sudo mv /etc/nova/nova.conf /etc/nova/nova.conf.orig
```

**設定ファイルの新規作成**:

```bash
sudo vim /etc/nova/nova.conf
```

**以下の内容を記述**:

```ini
[DEFAULT]
# APIリスニング設定（Nginx経由でアクセスするため、127.0.0.1でリスニング）
# 重要: これらの設定は[DEFAULT]セクションの最初に配置することを推奨
osapi_compute_listen = 127.0.0.1
osapi_compute_listen_port = 8774
metadata_listen = 127.0.0.1
metadata_listen_port = 8775

# ログとデバッグ設定
log_dir = /var/log/nova
state_path = /var/lib/nova

# メッセージキュー設定
transport_url = rabbit://openstack:password@controller:5672

# マイグレーション設定
my_ip = 172.16.100.10
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

# VNC設定
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 172.16.100.10
novncproxy_base_url = http://controller:6080/vnc_auto.html
novncproxy_host = 127.0.0.1
novncproxy_port = 6080

# Glance設定
[glance]
api_servers = http://controller:9292

# データベース設定
[api_database]
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova_api

[database]
connection = mysql+pymysql://nova:NOVA_DBPASS@controller/nova

# Keystone認証設定
[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
insecure = true

# サービス設定
[oslo_concurrency]
lock_path = /var/lib/nova/tmp

# セル設定
[placement]
region_name = RegionOne
project_domain_name = Default
project_name = service
auth_type = password
user_domain_name = Default
auth_url = https://controller:5000/v3
username = placement
password = PLACEMENT_PASS
insecure = true
```

**設定ファイルのパーミッション設定**:

```bash
sudo chmod 640 /etc/nova/nova.conf
sudo chgrp nova /etc/nova/nova.conf
```

> **📌 セキュリティ**: 設定ファイルにはパスワードが含まれているため、適切なパーミッションを設定します。

> **📌 設定項目の説明**:
>
> - **transport_url**: RabbitMQへの接続（Phase 2で設定したもの）
> - **my_ip**: コントローラノードの管理ネットワークIPアドレス
> - **use_neutron**: Neutronを使用する（Phase 6で設定）
> - **firewall_driver**: Neutronがファイアウォールを管理するため、Novaのファイアウォールドライバーを無効化
> - **vncserver_listen**: VNCサーバーのリスンアドレス
> - **vncserver_proxyclient_address**: VNCプロキシのアドレス
> - **novncproxy_base_url**: VNCコンソールへのアクセスURL
> - **api_servers**: Glance APIサーバーのアドレス
> - **insecure**: SSL証明書の検証（false=検証する）
> - **placement**: Placementサービス（リソース管理）の設定（Phase 5では簡易設定）

> **📌 重要な設定項目**:
>
> - **my_ip**: コントローラノードの管理ネットワークIP（172.16.100.10）を設定
> - **transport_url**: RabbitMQへの接続（Phase 2で設定）
> - **use_neutron = true**: Neutronを使用する（Phase 6で設定するため、現時点ではエラーが出る可能性がありますが、後で解決します）
> - **firewall_driver**: Neutronがファイアウォールを管理するため、NoopFirewallDriverを設定

---

### データベースの同期とCellの設定

**データベーススキーマの同期**:

```bash
# nova_apiデータベースの同期
sudo su -s /bin/bash nova -c "nova-manage api_db sync"

# nova_cell0データベースの同期
sudo su -s /bin/bash nova -c "nova-manage cell_v2 map_cell0"

# novaデータベースの同期
sudo su -s /bin/bash nova -c "nova-manage db sync"
```

> **📌 コマンド解説**: `nova-manage`
>
> - **api_db sync**: nova_apiデータベースのスキーマを作成または更新します
> - **cell_v2 map_cell0**: nova_cell0データベースをCell0として登録します
> - **db sync**: novaデータベースのスキーマを作成または更新します（Cell1用）

**データベースにテーブルが作成されたことを確認**:

```bash
sudo mysql -u root -p nova_api -e "SHOW TABLES;" | head -20
sudo mysql -u root -p nova -e "SHOW TABLES;" | head -20
sudo mysql -u root -p nova_cell0 -e "SHOW TABLES;" | head -20
```

**Cell1の作成**:

```bash
# Cell1の作成
sudo su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"
```

**実行時の出力例**:

```bash
--transport-url not provided in the command line, using the value [DEFAULT]/transport_url from the configuration file
--database_connection not provided in the command line, using the value [database]/connection from the configuration file
e845836b-ead4-436e-843c-03862f08f19f
```

> **📌 出力の説明**:
>
> - 最初の2行は、コマンドライン引数が指定されていないため、設定ファイル（`nova.conf`）から値を読み取っていることを示しています
> - 最後の行（`e845836b-ead4-436e-843c-03862f08f19f`）は、作成されたCell1のUUIDです
> - このUUIDが表示されれば、Cell1の作成は成功しています

**Cell1の登録確認**:

```bash
sudo su -s /bin/bash nova -c "nova-manage cell_v2 list_cells"
```

**期待される出力**:

```bash
+-------+--------------------------------------+-----------------------------------------------------+--------------------------------------------------+
| Name  | UUID                                 | Transport URL                                        | Database Connection                              |
+-------+--------------------------------------+-----------------------------------------------------+--------------------------------------------------+
| cell0 | 00000000-0000-0000-0000-000000000000 | none:/                                               | mysql+pymysql://nova:***@controller/nova_cell0  |
| cell1 | xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx | rabbit://openstack:***@controller:5672/             | mysql+pymysql://nova:***@controller/nova        |
+-------+--------------------------------------+-----------------------------------------------------+--------------------------------------------------+
```

> **📌 Cellの概念**:
>
> - **Cell0**: 未配置のインスタンス情報を保存（スケジューリング前の状態）
> - **Cell1**: 実際のインスタンス情報を保存（スケジューリング後の状態）
> - 複数のCellを作成することで、大規模環境でのスケーラビリティを向上させることができます

---

### Novaサービスの起動

**Novaサービスの起動**:

> **📌 重要**: Nginx設定を適用する前に、Novaサービスを一時的に停止する必要があります。Novaサービスが既に起動している場合、Nginxが同じポートでバインドしようとして失敗する可能性があります。

**Novaサービスの一時停止（既に起動している場合）**:

```bash
sudo systemctl stop nova-api nova-conductor nova-scheduler nova-novncproxy
```

**Apache2とNginxの再起動**:

```bash
sudo systemctl restart apache2 nginx
```

> **📌 重要**: Apache2（Keystone/Placement用）とNginx（プロキシ用）を再起動して、設定を反映させます。

**Novaサービスの起動**:

```bash
sudo systemctl restart nova-api nova-conductor nova-scheduler nova-novncproxy
sudo systemctl enable nova-api nova-conductor nova-scheduler nova-novncproxy
```

> **📌 注意**: Novaサービス（nova-api、nova-metadata-api、nova-novncproxy）は`127.0.0.1`でリスニングし、Nginxが`172.16.100.10`でリスニングするため、ポート競合は発生しません。

**サービスの状態確認**:

```bash
sudo systemctl status nova-api nova-conductor nova-scheduler nova-novncproxy
```

**期待される出力**:

```bash
● nova-api.service - OpenStack Compute API server
     Loaded: loaded (/lib/systemd/system/nova-api.service; enabled; vendor preset: enabled)
     Active: active (running) since ...

● nova-conductor.service - OpenStack Compute Conductor service
     Loaded: loaded (/lib/systemd/system/nova-conductor.service; enabled; vendor preset: enabled)
     Active: active (running) since ...

● nova-scheduler.service - OpenStack Compute Scheduler service
     Loaded: loaded (/lib/systemd/system/nova-scheduler.service; enabled; vendor preset: enabled)
     Active: active (running) since ...

● nova-novncproxy.service - OpenStack Compute VNC proxy service
     Loaded: loaded (/lib/systemd/system/nova-novncproxy.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
```

**ポートの確認**:

```bash
sudo ss -tlnp | grep -E "(8774|8778|6080)"
```

**期待される出力例**:

```bash
LISTEN 0      511          0.0.0.0:8774        0.0.0.0:*    users:(("nova-api",pid=XXXX,fd=X))
LISTEN 0      511          0.0.0.0:8778        0.0.0.0:*    users:(("placement-api",pid=XXXX,fd=X))
LISTEN 0      511          0.0.0.0:6080        0.0.0.0:*    users:(("nova-novncproxy",pid=XXXX,fd=X))
```

- nova-apiが`0.0.0.0:8774`でリスニング
- placement-apiが`0.0.0.0:8778`でリスニング
- nova-novncproxyが`0.0.0.0:6080`でリスニング

> **📌 Placementサービスについて**:
>
> **Ubuntu 24.04の`placement-api`パッケージは、インストール時にsystemdサービスが自動的に有効化（`systemctl enable`）されます。**
>
> ただし、設定ファイル（`/etc/placement/placement.conf`）が正しく設定されていない場合、サービスは有効化されていても起動に失敗する可能性があります。
>
> Server Worldの手順では、Placementサービスの明示的な起動コマンドは記載されていません。これは、パッケージインストール時に自動的に有効化されているためです。
>
> **Placementサービスの状態を確認**:
>
> ```bash
> # サービスの状態確認
> sudo systemctl status placement-api
> ```
>
> もしPlacementサービスが起動していない場合は、設定ファイルを確認した後、以下のコマンドで明示的に起動できます：
>
> ```bash
> # Placementサービスの起動（必要な場合のみ）
> sudo systemctl restart placement-api
> sudo systemctl enable placement-api
> ```

**ログの確認**:

```bash
# nova-apiサービスのログ
sudo journalctl -u nova-api -n 20

# nova-conductorサービスのログ
sudo journalctl -u nova-conductor -n 20

# nova-schedulerサービスのログ
sudo journalctl -u nova-scheduler -n 20
```

---

### Novaの動作確認

Controllerノードで実行します。

```bash
# admin-openrcを読み込む
source ~/admin-openrc

# サービスリストの確認
openstack service list

# エンドポイントの確認
openstack endpoint list --service compute

# コンピュートサービス一覧の確認（現時点では空）
openstack compute service list
```

**期待される出力**:

```bash
# openstack service list
+----------------------------------+----------+----------+
| ID                               | Name     | Type     |
+----------------------------------+----------+----------+
| ...                              | keystone | identity |
| ...                              | glance   | image    |
| ...                              | nova     | compute  |
+----------------------------------+----------+----------+

# openstack endpoint list --service compute
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ID                               | Region    | Service Name | Service Type | Enabled | Interface | URL                       |
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+
| ...                              | RegionOne | nova         | compute      | True    | public    | https://controller:8774/v2.1|
| ...                              | RegionOne | nova         | compute      | True    | internal  | https://controller:8774/v2.1|
| ...                              | RegionOne | nova         | compute      | True    | admin     | https://controller:8774/v2.1|
+----------------------------------+-----------+--------------+--------------+---------+-----------+---------------------------+

# openstack compute service list
+--------------------------------------+----------------+------------+----------+---------+-------+------------+
| ID                                   | Binary         | Host       | Zone     | Status  | State | Updated At |
+--------------------------------------+----------------+------------+----------+---------+-------+------------+
| ...                                  | nova-conductor | controller | internal | enabled | up    | ...        |
| ...                                  | nova-scheduler | controller | internal | enabled | up    | ...        |
+--------------------------------------+----------------+------------+----------+---------+-------+------------+
```

> **📌 注意**:
>
> - コントローラノードのNovaサービス（nova-conductor、nova-scheduler）が表示されます
> - コンピュートノード（nova-compute）はまだ登録されていないため、表示されません
> - コンピュートノードを設定すると、`nova-compute`サービスが追加で表示されます

---

## 📝 Step 5-2: Novaコンピュート側のインストール

### Novaパッケージのインストール

**コンピュートノードにSSH接続**:

```bash
vagrant ssh compute1
```

**Nova Computeパッケージのインストール**:

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y nova-compute
```

**インストール確認**:

```bash
dpkg -l | grep nova
```

---

### Nova設定ファイルの編集

**設定ファイルのバックアップ**:

```bash
sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.orig
```

**設定ファイルの編集**:

```bash
sudo vim /etc/nova/nova.conf
```

**以下の内容を記述**:

```ini
[DEFAULT]
# ログとデバッグ設定
log_dir = /var/log/nova
state_path = /var/lib/nova

# メッセージキュー設定
transport_url = rabbit://openstack:RABBIT_PASS@controller:5672

# マイグレーション設定
my_ip = 172.16.100.31
use_neutron = true
firewall_driver = nova.virt.firewall.NoopFirewallDriver

# VNC設定
vncserver_listen = 0.0.0.0
vncserver_proxyclient_address = 172.16.100.31
novncproxy_base_url = http://controller:6080/vnc_auto.html

# Glance設定
[glance]
api_servers = http://controller:9292

# データベース設定（コンピュートノードは直接DBに接続しない）
# nova-conductor経由でアクセス

# Keystone認証設定
[keystone_authtoken]
www_authenticate_uri = https://controller:5000
auth_url = https://controller:5000
memcached_servers = controller:11211
auth_type = password
project_domain_name = Default
user_domain_name = Default
project_name = service
username = nova
password = NOVA_PASS
insecure = true

# サービス設定
[oslo_concurrency]
lock_path = /var/lib/nova/tmp

# ハイパーバイザー設定
[libvirt]
virt_type = kvm
```

> **📌 設定項目の説明**:
>
> - **my_ip**: コンピュートノードの管理ネットワークIPアドレス（172.16.100.31）
> - **vncserver_proxyclient_address**: コンピュートノードの管理ネットワークIPアドレス
> - **virt_type**: ハイパーバイザーのタイプ（kvm、qemu、xen等）
> - **use_neutron**: Neutronを使用する（Phase 6で設定）

> **📌 重要な設定項目**:
>
> - **my_ip**: コンピュートノードの管理ネットワークIP（172.16.100.31）を設定
> - **transport_url**: RabbitMQへの接続（Phase 2で設定）
> - **virt_type = kvm**: KVMハイパーバイザーを使用（入れ子仮想化が有効になっている必要があります）

---

### libvirt / KVMの設定確認

**KVMの確認**:

```bash
# KVMモジュールの確認
lsmod | grep kvm
```

**期待される出力**:

```bash
kvm_intel             245760  0
kvm                   901120  1 kvm_intel
```

または（AMD CPUの場合）:

```bash
kvm_amd                245760  0
kvm                   901120  1 kvm_amd
```

**CPU仮想化支援機能の確認**:

```bash
# Intel CPUの場合
egrep -c '(vmx|svm)' /proc/cpuinfo

# 1以上が返ってくればOK（0の場合は仮想化支援機能が無効）
```

**libvirtサービスの確認**:

```bash
sudo systemctl status libvirtd
sudo systemctl enable libvirtd
sudo systemctl start libvirtd
```

**libvirtの設定確認**:

```bash
# libvirtのバージョン確認
virsh version

# 期待される出力例:
# Compiled against library: libvirt 8.0.0
# Using library: libvirt 8.0.0
# Using API: QEMU 8.0.0
# Running hypervisor: QEMU 8.0.0
```

> **📌 トラブルシューティング**:
>
> - KVMモジュールが読み込まれていない場合: `sudo modprobe kvm` を実行
> - 仮想化支援機能が無効の場合: VirtualBoxの設定で「Nested VT-x/AMD-V」を有効化（Phase 1を参照）
> - libvirtが起動しない場合: ログを確認（`sudo journalctl -u libvirtd -n 50`）

---

### Nova Computeサービスの起動

**Nova Computeサービスの起動**:

```bash
sudo systemctl restart nova-compute
sudo systemctl enable nova-compute
```

**サービスの状態確認**:

```bash
sudo systemctl status nova-compute
```

**期待される出力**:

```bash
● nova-compute.service - OpenStack Compute Service
     Loaded: loaded (/lib/systemd/system/nova-compute.service; enabled; vendor preset: enabled)
     Active: active (running) since ...
```

**ログの確認**:

```bash
# nova-computeサービスのログ
sudo journalctl -u nova-compute -n 50
```

エラーがないことを確認します。

---

### コントローラでのコンピュートノード登録確認

**コントローラノードに戻る**:

```bash
exit
vagrant ssh controller
```

**admin-openrcを読み込む**:

```bash
source ~/admin-openrc
```

**コンピュートサービス一覧の確認**:

```bash
openstack compute service list
```

**期待される出力**:

```bash
+----+----------------+------------+----------+---------+-------+----------------------------+
| ID | Binary         | Host       | Zone     | Status  | State | Updated At                 |
+----+----------------+------------+----------+---------+-------+----------------------------+
| X  | nova-compute   | compute1   | nova     | enabled | up    | 2024-XX-XXTXX:XX:XX.000000 |
+----+----------------+------------+----------+---------+-------+----------------------------+
```

**ハイパーバイザー一覧の確認**:

```bash
openstack hypervisor list
```

**期待される出力**:

```bash
+----+---------------------+-----------------+----------------+-------+
| ID | Hypervisor Hostname | Hypervisor Type | Host IP        | State |
+----+---------------------+-----------------+----------------+-------+
| X  | compute1            | QEMU            | 172.16.100.31  | up    |
+----+---------------------+-----------------+----------------+-------+
```

**ハイパーバイザーの詳細確認**:

```bash
openstack hypervisor show compute1
```

**期待される出力**:

```bash
+----------------------+------------------------------------------------------+
| Field                | Value                                                |
+----------------------+------------------------------------------------------+
| id                   | X                                                    |
| hypervisor_hostname  | compute1                                             |
| hypervisor_type      | QEMU                                                 |
| hypervisor_version   | 8.0.0                                                |
| host_ip              | 172.16.100.31                                        |
| state                | up                                                   |
| status               | enabled                                               |
| vcpus                | 4                                                    |
| vcpus_used           | 0                                                    |
| memory_mb            | 8192                                                 |
| memory_mb_used       | 0                                                    |
| running_vms          | 0                                                    |
| current_workload     | 0                                                    |
| disk_available_least | 0                                                    |
| local_gb             | 40                                                   |
| local_gb_used        | 0                                                    |
+----------------------+------------------------------------------------------+
```

> **📌 確認ポイント**:
>
> - **Status**: `enabled` になっていること
> - **State**: `up` になっていること
> - **Hypervisor Type**: `QEMU` または `KVM` になっていること
> - **vcpus**: コンピュートノードのCPUコア数が表示されていること
> - **memory_mb**: コンピュートノードのメモリ容量が表示されていること

---

## 📝 Step 5-3: Flavorの作成

### 標準Flavorの作成

**Flavorとは**:

Flavorは、VMのインスタンスタイプ（サイズ）を定義します。CPU、メモリ、ディスク容量を指定します。

**標準Flavorの作成**:

```bash
# admin-openrcを読み込む
source ~/admin-openrc

# m1.tiny（最小サイズ）
openstack flavor create --id 1 --ram 512 --disk 1 --vcpus 1 m1.tiny

# m1.small（小サイズ）
openstack flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 m1.small

# m1.medium（中サイズ）
openstack flavor create --id 3 --ram 4096 --disk 40 --vcpus 2 m1.medium

# m1.large（大サイズ）
openstack flavor create --id 4 --ram 8192 --disk 80 --vcpus 4 m1.large
```

**パラメータの説明**:

| パラメータ | 説明               |
| ---------- | ------------------ |
| `--id`     | FlavorのID（数値） |
| `--ram`    | メモリ容量（MB）   |
| `--disk`   | ディスク容量（GB） |
| `--vcpus`  | 仮想CPUコア数      |

> **📌 注意**: 学習環境のリソース制約を考慮して、Flavorのサイズを調整してください。コンピュートノードのリソースを超えるFlavorは作成できません。

---

### Flavorの確認

**Flavor一覧の確認**:

```bash
openstack flavor list
```

**期待される出力**:

```bash
+----+-----------+-------+------+-----------+-------+-----------+
| ID | Name      |   RAM | Disk | Ephemeral | VCPUs | Is Public |
+----+-----------+-------+------+-----------+-------+-----------+
| 1  | m1.tiny   |   512 |    1 |         0 |     1 | True      |
| 2  | m1.small  |  2048 |   20 |         0 |     1 | True      |
| 3  | m1.medium |  4096 |   40 |         0 |     2 | True      |
| 4  | m1.large  |  8192 |   80 |         0 |     4 | True      |
+----+-----------+-------+------+-----------+-------+-----------+
```

**Flavorの詳細確認**:

```bash
openstack flavor show m1.tiny
```

**期待される出力**:

```bash
+----------------------------+---------+
| Field                      | Value   |
+----------------------------+---------+
| OS-FLV-DISABLED:disabled   | False   |
| OS-FLV-EXT-DATA:ephemeral  | 0       |
| disk                       | 1       |
| id                         | 1       |
| name                       | m1.tiny |
| os-flavor-access:is_public | True    |
| properties                 |         |
| ram                        | 512     |
| rxtx_factor                | 1.0     |
| swap                       |         |
| vcpus                      | 1       |
+----------------------------+---------+
```

---

## ✅ Phase 5 完了チェックリスト

以下を確認してください：

- [ ] nova_api、nova、nova_cell0、placementデータベースが作成されている
- [ ] novaユーザーがKeystoneに登録されている
- [ ] placementユーザーがKeystoneに登録されている
- [ ] novaサービスがKeystoneに登録されている
- [ ] placementサービスがKeystoneに登録されている
- [ ] novaエンドポイントが作成されている（public, internal, admin）
- [ ] placementエンドポイントが作成されている（public, internal, admin）
- [ ] Placementパッケージがインストールされている
- [ ] Placement設定ファイル（`/etc/placement/placement.conf`）が適切に設定されている
- [ ] Placementデータベーススキーマが同期されている（`placement-manage db sync`）
- [ ] Placementサービスが正常に起動している（placement-api）
- [ ] Nova設定ファイル（`/etc/nova/nova.conf`）が適切に設定されている（コントローラ、コンピュート）
- [ ] データベーススキーマが同期されている（`nova-manage api_db sync`、`nova-manage db sync`）
- [ ] Cell0が登録されている（`nova-manage cell_v2 map_cell0`）
- [ ] Cell1が作成されている（`nova-manage cell_v2 create_cell`）
- [ ] Novaコントローラ側のサービスが正常に起動している（nova-api、nova-conductor、nova-scheduler、nova-novncproxy）
- [ ] Novaコンピュート側のサービスが正常に起動している（nova-compute）
- [ ] ポート8774（nova-api）がリスニングしている
- [ ] ポート8778（placement-api）がリスニングしている
- [ ] ポート6080（nova-novncproxy）がリスニングしている
- [ ] `openstack compute service list` でコンピュートノードが表示される
- [ ] `openstack hypervisor list` でハイパーバイザーが表示される
- [ ] 標準Flavor（m1.tiny、m1.small、m1.medium、m1.large）が作成されている
- [ ] `openstack flavor list` でFlavor一覧が表示される

**確認コマンド例**:

```bash
# Controllerノードで実行
vagrant ssh controller
source ~/admin-openrc

# サービスの確認
openstack service list | grep compute
openstack endpoint list --service compute

# コンピュートサービスの確認
openstack compute service list
openstack hypervisor list

# Flavorの確認
openstack flavor list

# Placementサービスの状態確認（コントローラ）
sudo systemctl status placement-api

# Novaサービスの状態確認（コントローラ）
sudo systemctl status nova-api nova-conductor nova-scheduler nova-novncproxy

# Novaサービスの状態確認（コンピュート）
vagrant ssh compute1
sudo systemctl status nova-compute

# ポートの確認（コントローラ）
sudo ss -tlnp | grep -E "(8774|8778|6080)"
```

---

## ⚠️ トラブルシューティング

### 問題1: Nova APIに接続できない（502 Bad Gateway）

**症状**:

```bash
openstack compute service list
# HttpException: 502: Server Error for url: https://controller:8774/v2.1/os-services, 502 Bad Gateway: nginx/1.24.0 (Ubuntu)
```

**解決策**:

1. **Nova APIサービスが起動しているか確認**:

   ```bash
   sudo systemctl status nova-api
   ```

   サービスが起動していない場合（`Main process exited, code=exited, status=1/FAILURE`が表示される場合）:

   **詳細なエラーログを確認**:

   ```bash
   # systemdのログ（最後の50行）
   sudo journalctl -u nova-api -n 50 --no-pager

   # Nova APIのログファイル（より詳細なエラー情報）
   sudo tail -50 /var/log/nova/nova-api.log
   ```

   **よくあるエラー原因**:
   - **ポート競合（`Address already in use`）**:
     - `osapi_compute_listen = 127.0.0.1`が設定されていない、または反映されていない
     - Nova APIが`0.0.0.0:8774`にバインドしようとしている
     - 解決策: 設定ファイルを確認し、`osapi_compute_listen = 127.0.0.1`が正しく設定されているか確認
   - 設定ファイルの構文エラー
   - データベース接続エラー
   - Keystone認証エラー
   - 必要な設定項目の欠如

   **`Address already in use`エラーの場合**:

   ```bash
   # 設定ファイルでosapi_compute_listenが正しく設定されているか確認
   sudo grep -E "^osapi_compute_listen|^osapi_compute_listen_port" /etc/nova/nova.conf

   # 期待される出力:
   # osapi_compute_listen = 127.0.0.1
   # osapi_compute_listen_port = 8774

   # もし設定されていない、または0.0.0.0になっている場合:
   # 設定ファイルを編集して、osapi_compute_listen = 127.0.0.1を追加/修正
   sudo vim /etc/nova/nova.conf

   # 設定ファイルを修正した後、サービスを再起動
   sudo systemctl restart nova-api nova-conductor nova-scheduler
   ```

2. **ポート8774が127.0.0.1でリスニングしているか確認**:

   ```bash
   sudo ss -tlnp | grep :8774
   ```

   **期待される出力**（Nova APIとNginxの両方がリスニング）:

   ```bash
   LISTEN 0      511      127.0.0.1:8774        0.0.0.0:*    users:(("nova-api",pid=XXXX,fd=X))
   LISTEN 0      511    172.16.100.10:8774     0.0.0.0:*    users:(("nginx",pid=XXXX,fd=X))
   ```

   **問題がある場合**:
   - **Nginxのみがリスニングしている場合**（例: `172.16.100.10:8774`のみ）:
     - Nova APIサービスが起動していない、または`127.0.0.1:8774`でリスニングしていない
     - 設定ファイルの`osapi_compute_listen = 127.0.0.1`が反映されていない可能性
     - Nova APIサービスのログを確認: `sudo journalctl -u nova-api -n 50`
   - `0.0.0.0:8774`でNova APIがリスニングしている場合 → 設定ファイルの`osapi_compute_listen = 127.0.0.1`が反映されていない
   - ポートが全くリスニングしていない場合 → Nova APIサービスが起動していない

3. **Nova設定ファイルを確認**:

   ```bash
   sudo grep -E "osapi_compute_listen|osapi_compute_listen_port" /etc/nova/nova.conf
   ```

   **期待される出力**:

   ```bash
   osapi_compute_listen = 127.0.0.1
   osapi_compute_listen_port = 8774
   ```

4. **設定ファイルを変更した場合は、Novaサービスを再起動**:

   ```bash
   sudo systemctl restart nova-api nova-conductor nova-scheduler
   ```

   **再起動後、再度ポートを確認**:

   ```bash
   sudo ss -tlnp | grep :8774
   ```

   Nova APIが`127.0.0.1:8774`でリスニングしていることを確認してください。

5. **Nginxのエラーログを確認**:

   ```bash
   sudo tail -20 /var/log/nginx/error.log
   ```

6. **Nginxがバックエンドに接続できるか確認**:

   ```bash
   # ローカルから直接Nova APIに接続してみる
   curl -k https://127.0.0.1:8774/v2.1/ -H "X-Auth-Token: $(openstack token issue -f value -c id)"
   ```

   または、HTTPで接続:

   ```bash
   curl http://127.0.0.1:8774/v2.1/
   ```

7. **エンドポイントが正しく作成されているか確認**:

   ```bash
   source ~/admin-openrc
   openstack endpoint list --service compute
   ```

8. エンドポイントがない場合は再作成:

   ```bash
   openstack endpoint create --region RegionOne compute public https://controller:8774/v2.1
   openstack endpoint create --region RegionOne compute internal https://controller:8774/v2.1
   openstack endpoint create --region RegionOne compute admin https://controller:8774/v2.1
   ```

---

### 問題2: nova-conductorがPlacementサービスに接続できない

**症状**:

```bash
sudo tail -50 /var/log/nova/nova-conductor.log
# openstack.exceptions.NotSupported: The placement service for controller:RegionOne exists but does not have any supported versions.
# Failed to contact the endpoint at http://controller:8778 for discovery.
```

**解決策**:

1. **Placement APIサービス（Apache）が起動しているか確認**:

   ```bash
   sudo systemctl status apache2
   sudo systemctl status placement-api
   ```

2. **ポート8778がリスニングしているか確認**:

   ```bash
   sudo ss -tlnp | grep :8778
   ```

   **期待される出力**（ApacheとNginxの両方がリスニング）:

   ```bash
   LISTEN 0      511      127.0.0.1:8778        0.0.0.0:*    users:(("apache2",pid=XXXX,fd=X))
   LISTEN 0      511    172.16.100.10:8778     0.0.0.0:*    users:(("nginx",pid=XXXX,fd=X))
   ```

3. **Placement APIに直接接続して確認**:

   ```bash
   # ローカルホストから（Apacheに直接接続）
   curl http://127.0.0.1:8778/
   
   # 外部から（Nginx経由で接続）
   curl -k https://controller:8778/
   ```

   期待される出力: JSONレスポンスが返ってくる

   > **📌 注意**: Placement APIはApacheで`127.0.0.1:8778`でリスニングし、Nginxが`172.16.100.10:8778`（HTTPS）でプロキシします。外部からアクセスする場合は、Nginx経由（`https://controller:8778`）でアクセスする必要があります。

4. **Placementエンドポイントを確認・更新**:

   ```bash
   source ~/admin-openrc
   openstack endpoint list --service placement
   ```

   **エンドポイントがHTTPの場合は、HTTPSに更新**:

   ```bash
   # 各エンドポイントをHTTPSに更新
   ENDPOINT_ID=$(openstack endpoint list --service placement --interface public -f value -c ID | head -1)
   openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
   
   ENDPOINT_ID=$(openstack endpoint list --service placement --interface internal -f value -c ID | head -1)
   openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
   
   ENDPOINT_ID=$(openstack endpoint list --service placement --interface admin -f value -c ID | head -1)
   openstack endpoint set "${ENDPOINT_ID}" --url https://controller:8778
   ```

5. **Placement APIのログを確認**:

   ```bash
   sudo tail -50 /var/log/apache2/placement-api.log
   sudo tail -50 /var/log/apache2/error.log
   ```

6. **Apache設定ファイルを確認**:

   ```bash
   sudo apache2ctl -S | grep placement
   ```

7. **Placement設定ファイルを確認**:

   ```bash
   sudo grep -E "auth_url|username|password" /etc/placement/placement.conf
   ```

8. **必要に応じて、Placementサービスを再起動**:

   ```bash
   sudo systemctl restart apache2
   sudo systemctl restart nova-conductor nova-scheduler
   ```

---

### 問題3: コンピュートノードが登録されない

**症状**:

```bash
openstack compute service list
# コンピュートノードが表示されない
```

**解決策**:

1. コンピュートノードでnova-computeサービスが起動しているか確認:

   ```bash
   vagrant ssh compute1
   sudo systemctl status nova-compute
   ```

2. nova-computeサービスのログを確認:

   ```bash
   sudo journalctl -u nova-compute -n 50
   ```

3. RabbitMQへの接続を確認:

   ```bash
   # コンピュートノードから
   sudo rabbitmqctl list_connections
   ```

4. コントローラノードとの通信を確認:

   ```bash
   # コンピュートノードから
   ping -c 3 controller
   telnet controller 5672  # RabbitMQ
   ```

5. 設定ファイルの`my_ip`が正しいか確認:

   ```bash
   sudo grep my_ip /etc/nova/nova.conf
   # 172.16.100.31 になっていることを確認
   ```

---

### 問題4: KVMが有効になっていない

**症状**:

```bash
lsmod | grep kvm
# 何も表示されない
```

**解決策**:

1. KVMモジュールを手動で読み込む:

   ```bash
   sudo modprobe kvm
   sudo modprobe kvm_intel  # Intel CPUの場合
   # または
   sudo modprobe kvm_amd    # AMD CPUの場合
   ```

2. VirtualBoxの設定で入れ子仮想化を有効化:

   ```bash
   # ホストOSで実行
   VBoxManage modifyvm openstack-compute1 --nested-hw-virt on
   ```

3. CPU仮想化支援機能を確認:

   ```bash
   egrep -c '(vmx|svm)' /proc/cpuinfo
   # 1以上が返ってくればOK
   ```

4. libvirtサービスの再起動:

   ```bash
   sudo systemctl restart libvirtd
   ```

---

### 問題4: データベース同期エラー

**症状**:

```bash
sudo nova-manage api_db sync
# ERROR: ...
```

**解決策**:

1. データベースが作成されているか確認:

   ```bash
   sudo mysql -u root -p -e "SHOW DATABASES LIKE 'nova%';"
   ```

2. データベースユーザーに権限があるか確認:

   ```bash
   sudo mysql -u root -p -e "SHOW GRANTS FOR 'nova'@'localhost';"
   ```

3. データベース接続をテスト:

   ```bash
   mysql -u nova -pNOVA_DBPASS -h controller nova_api -e "SELECT 1;"
   ```

4. 既存のスキーマを削除して再同期（注意: データが削除されます）:

   ```bash
   sudo mysql -u root -p -e "DROP DATABASE nova_api;"
   sudo mysql -u root -p -e "DROP DATABASE nova;"
   sudo mysql -u root -p -e "DROP DATABASE nova_cell0;"
   # データベースを再作成してから同期
   ```

---

### 問題5: Cellの登録エラー

**症状**:

```bash
sudo nova-manage cell_v2 list_cells
# エラーが表示される、またはCellが表示されない
```

**解決策**:

1. Cell0が登録されているか確認:

   ```bash
   sudo nova-manage cell_v2 map_cell0
   ```

2. Cell1が作成されているか確認:

   ```bash
   sudo su -s /bin/bash nova -c "nova-manage cell_v2 list_cells"
   ```

3. Cell1が存在しない場合は再作成:

   ```bash
   sudo su -s /bin/bash nova -c "nova-manage cell_v2 create_cell --name cell1"
   ```

4. データベース接続を確認:

   ```bash
   sudo mysql -u root -p nova_cell0 -e "SHOW TABLES;" | head -5
   sudo mysql -u root -p nova -e "SHOW TABLES;" | head -5
   ```

---

## 📚 次のステップ

Phase 5が完了したら、Phase 6（Neutron - ネットワークサービス）に進んでください：

**Phase 6: Neutron（ネットワークサービス）**

- Neutronサーバーの構築
- ネットワークノードの構築
- コンピュートノードのNeutronエージェント
- ネットワークの作成
- 詳細: [Phase 6: Neutron構築](phase6_neutron.md)

**学習のポイント**:

- Novaで作成したFlavorを使用してVMを作成します（Phase 7で実行）
- NeutronはVMのネットワーク機能を提供します
- ネットワークが設定されないと、VMは起動できません

---

## 📝 学習記録

Phase 5の学習が完了したら、以下のテンプレートに記録してください：

```markdown
## Phase 5: Nova（コンピュートサービス）

### 実施日
YYYY/MM/DD

### 完了したStep
- [x] Step 5-1: Novaコントローラ側のインストール
- [x] Step 5-2: Novaコンピュート側のインストール
- [x] Step 5-3: Flavorの作成

### 使用した方法
- [x] Command

### 学んだこと
- NovaがVMのライフサイクル管理を行うこと
- コントローラノードとコンピュートノードの役割分担
- Cellの概念（Cell0とCell1）
- ハイパーバイザー（KVM）の理解
- Flavorによるリソース定義

### 遭遇した問題と解決策
**問題**:
**解決策**:

### 参考にしたリンク
- [Server World - Nova の設定 #1](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=7)
- [Server World - Nova の設定 #2](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=8)
- [Server World - Nova の設定 #3](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=9)

### 次回への引き継ぎ事項
- 作成したFlavorのIDと名前
- コンピュートノードのリソース情報（CPU、メモリ、ディスク）
- ハイパーバイザーの状態
```

---

## 🔗 関連ドキュメント

- **Phase 4: Glance構築** - [phase4_glance.md](phase4_glance.md)（前のPhase）
- **Phase 6: Neutron構築** - [phase6_neutron.md](phase6_neutron.md)（次のPhase）
- **ロードマップ** - [openstack-learning-roadmap.md](openstack-learning-roadmap.md)
- **Server World - Nova の設定 #1** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=7>
- **Server World - Nova の設定 #2** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=8>
- **Server World - Nova の設定 #3** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=9>
- **OpenStack公式ドキュメント - Nova** - <https://docs.openstack.org/nova/>

---

**Good luck with Phase 5! 🚀**
