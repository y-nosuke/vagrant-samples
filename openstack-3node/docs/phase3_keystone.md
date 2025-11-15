# Phase 3: Keystone（認証サービス）

## 目次

- [Phase 3: Keystone（認証サービス）](#phase-3-keystone認証サービス)
  - [目次](#目次)
  - [📋 概要](#-概要)
    - [目的](#目的)
    - [Keystoneの役割](#keystoneの役割)
  - [🎯 前提条件](#-前提条件)
    - [Phase 2の完了確認](#phase-2の完了確認)
    - [必要な知識](#必要な知識)
  - [📐 Keystoneのアーキテクチャ](#-keystoneのアーキテクチャ)
    - [Keystoneの主要コンポーネント](#keystoneの主要コンポーネント)
    - [認証フロー](#認証フロー)
  - [📝 Step 3-1: Keystoneのインストール](#-step-3-1-keystoneのインストール)
    - [データベースの作成](#データベースの作成)
    - [Keystoneパッケージのインストール](#keystoneパッケージのインストール)
    - [Keystone設定ファイルの編集](#keystone設定ファイルの編集)
      - [1. memcacheセクション](#1-memcacheセクション)
      - [2. databaseセクション](#2-databaseセクション)
      - [3. tokenセクション](#3-tokenセクション)
    - [データベースの同期](#データベースの同期)
    - [Fernetキーの設定](#fernetキーの設定)
    - [Credentialキーの設定](#credentialキーの設定)
    - [Keystone Bootstrapの実行](#keystone-bootstrapの実行)
    - [SSL/TLS証明書の設定](#ssltls証明書の設定)
      - [方法1: Let's Encrypt証明書を使用（推奨・本番環境）](#方法1-lets-encrypt証明書を使用推奨本番環境)
      - [方法2: 自己署名証明書を作成（学習環境用）](#方法2-自己署名証明書を作成学習環境用)
    - [Apache HTTP Serverの設定](#apache-http-serverの設定)
    - [サービスの起動と確認](#サービスの起動と確認)
  - [📝 Step 3-2: Keystoneの動作確認と設定](#-step-3-2-keystoneの動作確認と設定)
    - [環境変数ファイル（admin-openrc）の作成](#環境変数ファイルadmin-openrcの作成)
    - [`service`プロジェクトの作成（必須）](#serviceプロジェクトの作成必須)
    - [作成されたリソースの確認](#作成されたリソースの確認)
    - [動作確認](#動作確認)
  - [✅ Phase 3 完了チェックリスト](#-phase-3-完了チェックリスト)
  - [⚠️ トラブルシューティング](#️-トラブルシューティング)
    - [問題1: Apacheサービスが起動しない](#問題1-apacheサービスが起動しない)
    - [問題3: Keystone APIが応答しない](#問題3-keystone-apiが応答しない)
    - [問題2: WSGIファイルが見つからない](#問題2-wsgiファイルが見つからない)
  - [📚 次のステップ](#-次のステップ)
  - [📝 学習記録](#-学習記録)
  - [🔗 関連ドキュメント](#-関連ドキュメント)

## 📋 概要

このPhaseでは、OpenStackの認証・認可基盤となるKeystoneを構築します。

### 目的

- Keystoneサービスのインストールと設定
- プロジェクト、ユーザー、ロールの作成
- OpenStack APIの認証基盤の確立

### Keystoneの役割

KeystoneはOpenStackの認証・認可サービスで、以下の機能を提供します：

- **認証（Authentication）**: ユーザーの身元を確認
- **認可（Authorization）**: ユーザーに適切な権限を付与
- **サービスカタログ**: OpenStack各サービスのエンドポイント情報を提供
- **トークン管理**: 認証トークンの発行・検証・無効化

> **📌 参考**: このドキュメントは、[Server World - Ubuntu 24.04 OpenStack Epoxy Keystone](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=3)の手順に基づいています。

---

## 🎯 前提条件

### Phase 2の完了確認

以下が完了していることを確認してください：

- [ ] Phase 2の全Stepが完了している
- [ ] MariaDBが正常に動作している
- [ ] RabbitMQが正常に動作している
- [ ] Memcachedが正常に動作している
- [ ] コントローラノードにSSH接続できる

### 必要な知識

- Linux基本コマンド（vim、systemctlなど）
- データベース基本操作（CREATE DATABASE、GRANTなど）
- HTTP/HTTPS基礎（ポート番号、プロトコル）
- OpenStack CLI基本操作

---

## 📐 Keystoneのアーキテクチャ

### Keystoneの主要コンポーネント

```mermaid
graph TB
    subgraph "コントローラノード"
        KeystoneAPI[Keystone API<br/>ポート5000]
        KeystoneDB[(Keystone DB<br/>MariaDB)]
        Memcached[Memcached<br/>トークンキャッシュ]
        Apache[Apache HTTP Server<br/>WSGI]
    end

    subgraph "クライアント"
        User[ユーザー/管理者]
        OpenStackCLI[OpenStack CLI]
        OtherServices[他OpenStackサービス<br/>Nova, Glance, etc.]
    end

    User -->|認証要求| OpenStackCLI
    OpenStackCLI -->|APIリクエスト| KeystoneAPI
    KeystoneAPI -->|トークン検証| Memcached
    KeystoneAPI -->|認証情報保存| KeystoneDB
    OtherServices -->|トークン検証| KeystoneAPI
    Apache -->|WSGI| KeystoneAPI

    style KeystoneAPI fill:#ffeb3b
    style KeystoneDB fill:#c8e6c9
    style Memcached fill:#b3e5fc
    style Apache fill:#ff9800
```

### 認証フロー

```mermaid
sequenceDiagram
    participant User as ユーザー
    participant CLI as OpenStack CLI
    participant Keystone as Keystone API
    participant DB as Keystone DB
    participant Cache as Memcached

    User->>CLI: openstack token issue
    CLI->>Keystone: POST /v3/auth/tokens
    Keystone->>DB: ユーザー認証情報確認
    DB-->>Keystone: 認証成功
    Keystone->>Cache: トークンキャッシュ保存
    Keystone-->>CLI: トークン発行
    CLI-->>User: トークン表示
```

---

## 📝 Step 3-1: Keystoneのインストール

このStepでは、Keystoneサービスをインストールし、基本設定を行います。

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

**keystoneデータベースの作成**:

```sql
CREATE DATABASE keystone CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- keystone用のデータベースユーザーと権限の作成

GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';

-- 権限の反映
FLUSH PRIVILEGES;

-- データベース接続の確認
SHOW DATABASES;

-- keystoneデータベースが表示されることを確認します。

-- MariaDBから退出
EXIT;
```

> **🔐 セキュリティノート**:
>
> - 本番環境では `KEYSTONE_DBPASS` をより強力なパスワードに変更してください
> - パスワードは環境変数やシークレット管理システムで管理することを推奨します

### Keystoneパッケージのインストール

**パッケージのインストール**:

```bash
sudo apt update
sudo apt install -y keystone python3-openstackclient apache2 libapache2-mod-wsgi-py3 python3-oauth2client
```

**📌 パッケージの説明**:

- `keystone`: Keystone認証サービス本体
- `python3-openstackclient`: OpenStack CLIクライアント
- `apache2`: Apache HTTP Server（KeystoneはWSGIアプリケーションとして動作）
- `libapache2-mod-wsgi-py3`: Apache用のPython WSGIモジュール
- `python3-oauth2client`: OAuth2認証クライアント（Keystoneで使用）

**インストール確認**:

```bash
dpkg -l | grep -E "(keystone|openstackclient|apache2|wsgi|oauth2client)"
```

必要なパッケージがインストールされていることを確認します。

### Keystone設定ファイルの編集

**設定ファイルのバックアップ**:

```bash
sudo cp /etc/keystone/keystone.conf /etc/keystone/keystone.conf.backup
```

**設定ファイルの編集**:

```bash
sudo vim /etc/keystone/keystone.conf
```

**主要な設定項目を編集**:

#### 1. memcacheセクション

```ini
[cache]
memcache_servers = controller:11211
```

#### 2. databaseセクション

```ini
[database]
connection = mysql+pymysql://keystone:KEYSTONE_DBPASS@controller/keystone
```

#### 3. tokenセクション

```ini
[token]
provider = fernet
```

Fernetトークンプロバイダーを使用します（推奨）。

**📌 注意**: Server Worldでは具体的なIPアドレス（例: `10.0.0.30:11211`）を指定していますが、Vagrant環境ではホスト名（`controller`）を使用します。Memcachedがローカルホストで動作している場合は`localhost:11211`でも問題ありません。

Memcachedを使用してトークンをキャッシュします。

### データベースの同期

**データベーススキーマの初期化**:

```bash
sudo su -s /bin/bash keystone -c "keystone-manage db_sync"
```

> **📌 コマンド解説**: `keystone-manage db_sync`
>
> - **目的**: Keystoneデータベースのスキーマを作成または更新します
> - **動作**: データベース接続設定（`/etc/keystone/keystone.conf`の`[database]`セクション）に基づいて、必要なテーブルを作成します
> - **実行タイミング**: 初回インストール時、またはKeystoneのバージョンアップ時に実行します
> - **注意**: 既存のデータベースに対して実行すると、スキーマが更新されますが、既存のデータは保持されます

**データベースにテーブルが作成されたことを確認**:

```bash
sudo mysql -u root -p keystone -e "SHOW TABLES;"
```

**期待される出力例**:

多数のテーブルが作成されていることを確認します。主要なテーブルは以下の通りです：

```bash
+------------------------------------+
| Tables_in_keystone                 |
+------------------------------------+
| access_rule                        |
| access_token                       |
| alembic_version                    |
| application_credential             |
| assignment                         |
| credential                         |
| endpoint                           |
| group                              |
| local_user                         |
| password                           |
| policy                             |
| project                            |
| region                             |
| role                               |
| service                            |
| token                              |
| trust                              |
| user                               |
| ...（他にも多数のテーブル）       |
+------------------------------------+
```

主要なテーブル（`project`、`user`、`role`、`token`、`endpoint`、`service`など）が表示されることを確認します。

### Fernetキーの設定

**Fernetキーの初期化**:

FernetはKeystoneが使用するトークン暗号化方式です。Fernetキーを生成して初期化します。

```bash
sudo keystone-manage fernet_setup --keystone-user keystone --keystone-group keystone
```

**Fernetキーの確認**:

```bash
sudo ls -la /etc/keystone/fernet-keys/
```

Fernetキーファイル（0、1など）が作成されていることを確認します。

> **📌 コマンド解説**: `keystone-manage fernet_setup`
>
> - **目的**: Fernetトークンプロバイダー用の暗号化キーを生成します
> - **--keystone-user**: Keystoneプロセスを実行するユーザー（通常は`keystone`）
> - **--keystone-group**: Keystoneプロセスを実行するグループ（通常は`keystone`）
> - **生成場所**: `/etc/keystone/fernet-keys/` ディレクトリにキーファイルが作成されます
> - **重要性**: これらのキーはトークンの暗号化・復号化に使用され、セキュリティ上重要です

### Credentialキーの設定

**Credentialキーの初期化**:

Credentialはアプリケーション認証情報（Application Credentials）の暗号化に使用されます。

```bash
sudo keystone-manage credential_setup --keystone-user keystone --keystone-group keystone
```

**Credentialキーの確認**:

```bash
sudo ls -la /etc/keystone/credential-keys/
```

Credentialキーファイルが作成されていることを確認します。

> **📌 コマンド解説**: `keystone-manage credential_setup`
>
> - **目的**: アプリケーション認証情報（Application Credentials）の暗号化キーを生成します
> - **--keystone-user**: Keystoneプロセスを実行するユーザー
> - **--keystone-group**: Keystoneプロセスを実行するグループ
> - **生成場所**: `/etc/keystone/credential-keys/` ディレクトリにキーファイルが作成されます
> - **用途**: アプリケーションがユーザー認証情報を直接扱わずに認証できるようにする機能で使用されます

### Keystone Bootstrapの実行

`keystone-manage bootstrap`コマンドを使用して、Keystoneの初期設定を自動的に行います。このコマンドは、adminユーザー、adminプロジェクト、adminロール、およびサービスカタログを自動的に作成します。**注意**: `service`プロジェクトは自動作成されないため、この後の手順で手動作成する必要があります。

**Keystone Bootstrapの実行**:

```bash
sudo keystone-manage bootstrap --bootstrap-password adminpassword \
  --bootstrap-admin-url https://controller:5000/v3/ \
  --bootstrap-internal-url https://controller:5000/v3/ \
  --bootstrap-public-url https://controller:5000/v3/ \
  --bootstrap-region-id RegionOne
```

> **📌 注意**: Vagrant環境では`controller`を使用します。ホスト名が異なる場合は適宜変更してください。

**コマンド解説**: `keystone-manage bootstrap`

- **目的**: Keystoneの初期設定を自動的に行います。OpenStackの標準的な初期化方法です
- **パラメータの説明**:
  - `--bootstrap-password adminpassword`: adminユーザーのパスワードを設定します（`adminpassword`は任意の強力なパスワードに置き換えてください）
  - `--bootstrap-admin-url`: 管理者用のKeystone APIエンドポイントURL
  - `--bootstrap-internal-url`: 内部ネットワーク用のKeystone APIエンドポイントURL
  - `--bootstrap-public-url`: 公開用のKeystone APIエンドポイントURL
  - `--bootstrap-region-id`: リージョンID（通常は`RegionOne`）
- **作成されるリソース**:
  - `default`ドメイン
  - `admin`プロジェクト
  - `admin`ユーザー
  - `admin`ロール
  - `member`ロール
  - `reader`ロール
  - `service`ロール
  - adminユーザーへのadminロールの割り当て
  - Keystoneサービスのエンドポイント
- **注意事項**:
  - `adminpassword`は任意の管理者パスワードに置き換えてください
  - この時点ではまだSSL/TLS証明書とApacheが設定されていません。bootstrapコマンド自体は証明書なしでも実行できますが、後でApacheを設定する際にHTTPSを使用するため、ここでHTTPSのURLを指定します
  - `service`プロジェクトは自動作成されません。この後の手順で手動作成する必要があります
  - このコマンドは初回実行時のみ使用します。既にKeystoneが初期化されている場合は実行しないでください
- **参考**: [OpenStack公式ドキュメント - Bootstrapping Identity](https://docs.openstack.org/keystone/2024.1/admin/bootstrap.html)

### SSL/TLS証明書の設定

SSL/TLS証明書を使用したHTTPS設定を行います。以下のいずれかの方法で証明書を準備します。

#### 方法1: Let's Encrypt証明書を使用（推奨・本番環境）

正規のSSL/TLS証明書を取得している場合は、その証明書を使用します。

```bash
# Let's Encrypt証明書の例（既に取得済みの場合）
# 証明書ファイルの場所:
# - /etc/letsencrypt/live/controller/cert.pem
# - /etc/letsencrypt/live/controller/privkey.pem
# - /etc/letsencrypt/live/controller/chain.pem
```

#### 方法2: 自己署名証明書を作成（学習環境用）

学習環境では、自己署名証明書を作成して使用できます。

> **⚠️ 重要**: 最新のOpenSSLやクライアントライブラリは、CN（Common Name）だけでなくSAN（Subject Alternative Names）をチェックします。SANを含まない証明書は「Hostname mismatch」エラーが発生します。

```bash
# OpenSSLを使用して自己署名証明書を作成（SANを含む）
sudo mkdir -p /etc/ssl/certs/keystone
sudo mkdir -p /etc/ssl/private/keystone

# SAN（Subject Alternative Names）を含む証明書を作成
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/keystone/keystone-key.pem \
  -out /etc/ssl/certs/keystone/keystone-cert.pem \
  -subj "/C=JP/ST=State/L=City/O=Organization/CN=controller" \
  -addext "subjectAltName=DNS:controller,DNS:localhost,IP:172.16.100.10,IP:127.0.0.1"

# 証明書ファイルの権限設定
sudo chmod 600 /etc/ssl/private/keystone/keystone-key.pem
sudo chmod 644 /etc/ssl/certs/keystone/keystone-cert.pem
```

> **📌 注意**:
>
> - SANには以下の情報が含まれています：
>   - `DNS:controller` - ホスト名
>   - `DNS:localhost` - ローカルホスト名
>   - `IP:172.16.100.10` - 管理ネットワークのIPアドレス
>   - `IP:127.0.0.1` - ループバックアドレス
> - 自己署名証明書はブラウザで警告が表示されますが、学習環境では問題ありません
> - 本番環境では必ず正規のSSL証明書（Let's Encryptなど）を使用してください
> - 証明書の内容を確認するには: `openssl x509 -in /etc/ssl/certs/keystone/keystone-cert.pem -text -noout | grep -A 2 "Subject Alternative Name"`
>
> **既存の証明書を再作成する場合**（SANを含まない証明書が既に存在する場合）:
>
> ```bash
> # 既存の証明書を削除
> sudo rm -f /etc/ssl/certs/keystone/keystone-cert.pem
> sudo rm -f /etc/ssl/private/keystone/keystone-key.pem
>
> # 上記のコマンドでSANを含む証明書を再作成
> ```
>

### Apache HTTP Serverの設定

KeystoneはApache HTTP Server上でWSGIアプリケーションとして動作します。

**📌 注意**: Apacheパッケージは、Keystoneパッケージのインストール時に既にインストールされています（前のステップを参照）。未インストールの場合は、以下でインストールしてください：

```bash
sudo apt install -y apache2 libapache2-mod-wsgi-py3
```

**Apache設定ファイルのバックアップ**:

```bash
sudo cp /etc/apache2/apache2.conf /etc/apache2/apache2.conf.backup
```

**Apache基本設定**:

`/etc/apache2/apache2.conf`にサーバー名を設定します。

```bash
sudo vim /etc/apache2/apache2.conf
```

70行目付近に以下を追加（または既存の`ServerName`行を編集）:

```apache
ServerName controller
```

**📌 注意**: Server Worldの例では`dlp.srv.world`を使用していますが、Vagrant環境では`controller`を使用します。

**Keystone用のApache設定ファイルのバックアップ**:

```bash
sudo mv /etc/apache2/sites-available/keystone.conf /etc/apache2/sites-available/keystone.conf.backup
```

**Keystone用のApache設定ファイルの作成**:

```bash
sudo vim /etc/apache2/sites-available/keystone.conf
```

**以下の内容を追加**:

**Let's Encrypt証明書を使用する場合**:

```apache
Listen 5000

<VirtualHost *:5000>
    SSLEngine on
    SSLHonorCipherOrder on
    SSLCertificateFile /etc/letsencrypt/live/controller/cert.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/controller/privkey.pem
    SSLCertificateChainFile /etc/letsencrypt/live/controller/chain.pem

    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>

    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
```

**自己署名証明書を使用する場合**（学習環境用）:

```apache
Listen 5000

<VirtualHost *:5000>
    SSLEngine on
    SSLHonorCipherOrder on
    SSLCertificateFile /etc/ssl/certs/keystone/keystone-cert.pem
    SSLCertificateKeyFile /etc/ssl/private/keystone/keystone-key.pem

    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>

    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
```

**📌 注意**:

- 本番環境ではLet's Encrypt証明書の使用を推奨します
- 学習環境では自己署名証明書でも動作しますが、ブラウザで警告が表示されます
- 証明書ファイルのパスは、実際の環境に合わせて変更してください
- Ubuntu 24.04 + OpenStack Epoxyでは、ポート35357（adminポート）は使用されず、ポート5000のみで動作します。また、`/identity`エイリアスも設定されています。

**Keystone WSGIファイルの確認**:

`keystone`パッケージのインストール時に、WSGIファイルは自動的に作成されています。ファイルが存在することを確認します：

```bash
ls -l /usr/bin/keystone-wsgi-public
```

**期待される出力例**:

```bash
-rwxr-xr-x 1 root root 3456 XX XX XX:XX /usr/bin/keystone-wsgi-public
```

ファイルが存在し、実行権限が付与されていることを確認します。

**ファイルの内容確認（オプション）**:

```bash
head -20 /usr/bin/keystone-wsgi-public
```

PBR（Python Build Reasonableness）によって生成されたコードが含まれていることを確認できます。

**📌 注意**:

- Ubuntu 24.04 + OpenStack Epoxyでは、`keystone`パッケージのインストール時に自動的に`/usr/bin/keystone-wsgi-public`が作成されます。手動で作成する必要はありません。
- `keystone-wsgi-admin`ファイルは使用されません（ポート5000のみでpublic/adminの両方の機能が動作します）。

**SSLモジュールの有効化**:

```bash
sudo a2enmod ssl
```

**期待される出力**:

```bash
Considering dependency mime for ssl:
Module mime already enabled
Considering dependency socache_shmcb for ssl:
Enabling module socache_shmcb.
Enabling module ssl.
See /usr/share/doc/apache2/README.Debian.gz on how to configure SSL and create self-signed certificates.
To activate the new configuration, you need to run:
  systemctl restart apache2
```

**Apache設定の構文チェック**:

```bash
sudo apache2ctl configtest
```

**期待される出力**:

```bash
Syntax OK
```

> エラーが表示された場合は、設定ファイルを確認してください。
>
> **Apacheサイトの有効化**:
>
> ```bash
> sudo a2ensite keystone
> ```
>
> **期待される出力**:
>
> ```bash
> Enabling site keystone.
> To activate the new configuration, you need to run:
>   systemctl restart apache2
> ```
>

**Apache設定のリロード**:

Apacheを再起動します。

```bash
sudo systemctl restart apache2
```

### サービスの起動と確認

**Apacheサービスの状態確認**:

```bash
sudo systemctl status apache2
```

**Apacheが正常に起動していることを確認**:

```bash
sudo systemctl enable apache2
sudo systemctl restart apache2
```

**Apacheエラーログの確認**:

```bash
sudo tail -20 /var/log/apache2/error.log
```

エラーが表示されていないことを確認します。

**ポートの確認**:

```bash
sudo ss -tlnp | grep :5000
```

**期待される出力例**:

```bash
LISTEN 0      511          0.0.0.0:5000      0.0.0.0:*    users:(("apache2",pid=XXXX,fd=X))
```

ポート5000がリスニング状態であることを確認します。

**📌 注意**: `netstat`コマンドは`net-tools`パッケージに含まれていますが、Ubuntu 24.04ではデフォルトでインストールされていません。代わりに`ss`コマンドを使用します（`ss`は`iproute2`パッケージに含まれ、デフォルトでインストールされています）。

**Keystone APIの動作確認**:

Keystone APIのバージョン情報を取得します：

**Let's Encrypt証明書を使用している場合**:

```bash
curl -s https://controller:5000/v3/ | python3 -m json.tool
```

**自己署名証明書を使用している場合**（`-k`オプションで証明書検証をスキップ）:

```bash
curl -k -s https://controller:5000/v3/ | python3 -m json.tool
```

**期待される出力例**:

```bash
{
    "version": {
        "id": "v3.22",
        "status": "stable",
        "updated": "2024-XX-XXT00:00:00Z",
        "links": [
            {
                "rel": "self",
                "href": "https://controller:5000/v3/"
            }
        ]
    }
}
```

JSONレスポンスが返ってくることを確認します。

**別の確認方法（エンドポイント情報）**:

**Let's Encrypt証明書を使用している場合**:

```bash
curl -s https://controller:5000/identity/v3/ | python3 -m json.tool
```

**自己署名証明書を使用している場合**:

```bash
curl -k -s https://controller:5000/identity/v3/ | python3 -m json.tool
```

**📌 注意**: レスポンスが返ってこない場合は、以下のトラブルシューティング手順を参照してください。

**ログの確認**:

```bash
sudo tail -20 /var/log/apache2/keystone.log
```

ログが出力されていることを確認します（初回アクセス時はログが空の場合もあります）。

---

## 📝 Step 3-2: Keystoneの動作確認と設定

> **⚠️ 重要**: OpenStack CLIコマンド（`openstack`）を実行するには、認証情報を環境変数として設定する必要があります。以下の手順で環境変数ファイルを作成してから、リソースの確認を行ってください。

### 環境変数ファイル（admin-openrc）の作成

OpenStackコマンドを実行する際に認証情報を毎回入力するのは非効率です。環境変数ファイルを作成して、認証情報を自動的に読み込むようにします。

**admin-openrcファイルの作成**:

```bash
vim ~/admin-openrc
```

**以下の内容を追加**（パスワードは実際に設定した値に置き換えてください）:

**正規のSSL証明書を使用している場合**:

```bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=adminpassword
export OS_AUTH_URL=https://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\W\[\033[00m\] \[\033[01;33m\](keystone)\[\033[00m\] $ '
```

**自己署名証明書を使用している場合**（学習環境）:

自己署名証明書を使用している場合、以下のいずれかの方法でSSL証明書の検証を設定する必要があります。

**方法1: 証明書ファイルを指定する（推奨）**:

```bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=adminpassword
export OS_AUTH_URL=https://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export OS_CACERT=/etc/ssl/certs/keystone/keystone-cert.pem
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\W\[\033[00m\] \[\033[01;33m\](keystone)\[\033[00m\] $ '
```

**方法2: 証明書検証を無効化する（開発環境のみ）**:

> **⚠️ 警告**: この方法は開発・学習環境でのみ使用してください。本番環境では絶対に使用しないでください。

```bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=https://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
export OS_INSECURE=true
export PS1='\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\W\[\033[00m\] \[\033[01;33m\](keystone)\[\033[00m\] $ '
```

**方法3: openstackコマンドに`--insecure` オプションを付ける**:

```bash
openstack project list --insecure
```

**📌 注意**:

- SSL/TLS証明書を設定した場合は、必ずHTTPSを使用してください
- 自己署名証明書を使用している場合、上記のいずれかの方法で証明書検証を設定する必要があります
- `OS_INSECURE=true`は開発・学習環境でのみ使用し、本番環境では絶対に使用しないでください
- 証明書ファイルのパス（`OS_CACERT`）は、実際に作成した証明書のパスに合わせて調整してください

**ファイルの権限設定**（セキュリティのため）:

```bash
chmod 600 ~/admin-openrc
```

**環境変数の読み込み確認**:

```bash
source ~/admin-openrc
```

**認証情報の確認**:

```bash
echo $OS_USERNAME
echo $OS_PROJECT_NAME
```

設定した値が表示されることを確認します。

**📌 参考**:

- プロジェクトの概念については [Part 2 - Keystoneの基本概念](02_architecture.md#111-openstackの基本概念プロジェクトユーザーロールドメイン) を参照してください。
- プロジェクトの設計方法については [Part 4 - プロジェクト・マルチテナント設計](04_system_design.md#3-プロジェクトマルチテナント設計) を参照してください。

### `service`プロジェクトの作成（必須）

**⚠️ 重要**: `keystone-manage bootstrap`コマンドは`service`プロジェクトを**自動作成しません**。公式ドキュメントによると、`bootstrap`コマンドは`admin`プロジェクト、`admin`ユーザー、各種ロールのみを作成します。`service`プロジェクトは手動作成が必要です。

**📌 参考**: `service`プロジェクトの役割については [Part 2 - Keystoneの基本概念](02_architecture.md#111-openstackの基本概念プロジェクトユーザーロールドメイン) を参照してください。

**`service`プロジェクトの作成**:

```bash
openstack project create --domain default --description "Service Project" service
```

**📌 注意**:

- `service`プロジェクトは、OpenStackの各サービスが慣習的に使用するプロジェクトです
- このプロジェクトがないと、Glance、Nova、Neutron、Cinderなどのサービスが正常に動作しません（各サービスは`service`プロジェクトに属するユーザーとして認証するため）
- 技術的には別の名前のプロジェクトでも動作しますが、OpenStackの標準的な手順に従うため、`service`という名前を使用することを推奨します
- 削除や名前変更は行わないでください
- 既に存在する場合は「既に存在する」というエラーが表示されますが、これは正常です

**作成されたプロジェクトの確認**:

```bash
openstack project list
```

`admin`と`service`プロジェクトが表示されることを確認します。

**📌 参考**:

- [Server World - Keystone設定 #2](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=4)では、bootstrap後に明示的に`service`プロジェクトを作成しています
- [OpenStack公式ドキュメント - Bootstrapping Identity](https://docs.openstack.org/keystone/2024.1/admin/bootstrap.html)でも、`service`プロジェクトは手動作成が必要とされています

### 作成されたリソースの確認

環境変数を設定した後、以下のコマンドでKeystoneに作成されたリソースを確認します。

**プロジェクト一覧の確認**:

```bash
openstack project list
```

`admin`と`service`プロジェクトが表示されることを確認します。

**ユーザー一覧の確認**:

```bash
openstack user list
```

`admin`ユーザーが表示されることを確認します。

**ロール一覧の確認**:

```bash
openstack role list
```

`admin`、`member`、`reader`、`service`ロールが表示されることを確認します。

**エンドポイント一覧の確認**:

```bash
openstack endpoint list
```

Keystoneサービスのエンドポイント（admin、internal、public）が表示されることを確認します。

### 動作確認

**トークンの発行と確認**:

```bash
openstack token issue
```

**期待される出力例**:

```bash
+------------+-----------------------------------------------------------------+
| Field      | Value                                                           |
+------------+-----------------------------------------------------------------+
| expires    | 2024-XX-XXTXX:XX:XX+0000                                          |
| id         | gAAAAABh...（長いトークン文字列）                                  |
| project_id | a1b2c3d4e5f6789012345678901234ab                                   |
| user_id    | 1a2b3c4d5e6f789012345678901234ab                                   |
+------------+-----------------------------------------------------------------+
```

トークンが正常に発行されることを確認します。

---

## ✅ Phase 3 完了チェックリスト

以下を確認して、Phase 3が完了していることを確認してください：

- [ ] Keystoneデータベースが作成されている
- [ ] Keystoneパッケージがインストールされている
- [ ] `/etc/keystone/keystone.conf` が適切に設定されている
- [ ] データベーススキーマが同期されている（`keystone-manage db_sync`）
- [ ] Fernetキーが生成されている（`keystone-manage fernet_setup`）
- [ ] Credentialキーが生成されている（`keystone-manage credential_setup`）
- [ ] Apache HTTP Serverが正常に起動している
- [ ] Keystone APIがポート5000でリスニングしている
- [ ] Keystone Bootstrapが正常に完了している（`keystone-manage bootstrap`）
- [ ] adminプロジェクトが作成されている
- [ ] serviceプロジェクトが作成されている
- [ ] adminユーザーが作成されている
- [ ] adminロールが作成されている
- [ ] adminユーザーにadminロールが付与されている
- [ ] Keystoneサービスのエンドポイントが作成されている
- [ ] `admin-openrc` ファイルが作成されている
- [ ] `openstack token issue` コマンドが正常に動作する
- [ ] プロジェクト、ユーザー、ロール、エンドポイントの一覧が正常に表示される

---

## ⚠️ トラブルシューティング

**📌 注意**: データベース接続エラー、認証エラー、トークンエラー、データベース同期エラーなどの汎用的な問題については、[トラブルシューティングガイド](./appendix_b_troubleshooting.md)を参照してください。

### 問題1: Apacheサービスが起動しない

**症状**:

```bash
sudo systemctl status apache2
# Active: failed
```

**解決策**:

1. Apache設定の構文チェック:

   ```bash
   sudo apache2ctl configtest
   ```

2. ログファイルを確認:

   ```bash
   sudo tail -50 /var/log/apache2/error.log
   ```

3. ポートが既に使用されていないか確認:

   ```bash
   sudo ss -tlnp | grep :5000
   ```

   > **📌 注意**: `netstat`の代わりに`ss`コマンドを使用します。

### 問題3: Keystone APIが応答しない

**症状**:

```bash
curl http://controller:5000/
# または
curl http://controller:5000/v3/
# レスポンスが返ってこない（タイムアウト）
```

**解決策**:

1. Apacheサービスが正常に起動しているか確認:

   ```bash
   sudo systemctl status apache2
   ```

2. ポート5000がリスニング状態か確認:

   ```bash
   sudo ss -tlnp | grep :5000
   ```

   ポートが表示されない場合は、Apacheが正しく起動していません。

3. Apacheエラーログを確認:

   ```bash
   sudo tail -50 /var/log/apache2/error.log
   ```

4. Keystoneサイトが有効化されているか確認:

   ```bash
   sudo a2ensite keystone
   sudo systemctl reload apache2
   ```

5. WSGIファイルが存在し、実行可能か確認:

   ```bash
   ls -l /usr/bin/keystone-wsgi-public
   sudo chmod +x /usr/bin/keystone-wsgi-public
   ```

6. Apache設定ファイルの構文を確認:

   ```bash
   sudo apache2ctl configtest
   ```

7. Apacheプロセスの確認:

   ```bash
   sudo ps aux | grep apache2
   ```

   プロセスが表示されない場合は、Apacheが起動していません。

8. より詳細なエラー情報を取得:

   ```bash
   curl -vvv http://controller:5000/v3/
   ```

   詳細な接続情報が表示されます。

### 問題2: WSGIファイルが見つからない

**症状**:

```bash
sudo apache2ctl configtest
# AH00526: Syntax error on line X: Invalid command 'WSGIScriptAlias'
```

**解決策**:

1. WSGIモジュールが有効になっているか確認:

   ```bash
   sudo a2enmod wsgi
   ```

2. WSGIファイルが存在するか確認:

   ```bash
   ls -l /usr/bin/keystone-wsgi-public
   ```

   > **📌 注意**: `keystone`パッケージのインストール時に自動的に作成されます。ファイルが存在しない場合は、パッケージの再インストールを試してください。

3. 実行権限があるか確認:

   ```bash
   sudo chmod +x /usr/bin/keystone-wsgi-public
   ```

---

**その他の問題**: データベース接続エラー、認証エラー、トークンエラー、データベース同期エラーなどの汎用的な問題については、[トラブルシューティングガイド](./appendix_b_troubleshooting.md)を参照してください。

---

## 📚 次のステップ

Phase 3が完了したら、以下のPhaseに進みます：

**Phase 4: Glance（イメージサービス）**

- Keystoneの認証基盤を使用してGlanceサービスを構築します
- VMイメージの管理機能を実装します
- 詳細: [Phase 4: Glance構築](phase4_glance.md)

**学習のポイント**:

- Keystoneで作成したadminユーザーとプロジェクトを使用して、Glanceサービスを登録します
- エンドポイントの概念を理解します
- サービス間認証の仕組みを学びます

---

## 📝 学習記録

Phase 3の学習が完了したら、以下のテンプレートに記録してください：

```markdown
## Phase 3: Keystone（認証サービス）

### 実施日
YYYY/MM/DD

### 完了したStep
- [x] Step 3-1: Keystoneのインストール
- [x] Step 3-2: Keystoneの動作確認と設定

### 使用した方法
- [x] Command

### 学んだこと
- KeystoneがOpenStackの認証・認可の中核であること
- プロジェクト、ユーザー、ロールの関係性
- トークンベース認証の仕組み
- Apache HTTP ServerによるWSGIアプリケーションのホスティング

### 遭遇した問題と解決策
**問題**: 
**解決策**: 

### 参考にしたリンク
- [Server World - Keystone](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=3)

### 次回への引き継ぎ事項
- admin-openrcファイルのパスワード管理方法
- エンドポイントの作成方法（Phase 4で学習）
```

---

## 🔗 関連ドキュメント

- **Phase 1: 環境準備** - [phase1_environment_setup.md](phase1_environment_setup.md)
- **Phase 2: 基盤構築** - [phase2_foundation.md](phase2_foundation.md)
- **Phase 4: Glance構築** - [phase4_glance.md](phase4_glance.md)（次のPhase）
- **ロードマップ** - [openstack-learning-roadmap.md](openstack-learning-roadmap.md)
- **Server World - Keystone** - <https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy&f=3>
- **OpenStack公式ドキュメント - Keystone** - <https://docs.openstack.org/keystone/>

---

**Good luck with Phase 3! 🚀**
