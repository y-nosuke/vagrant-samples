# 付録B: トラブルシューティング

**[OpenStack学習資料]**

---

このドキュメントでは、OpenStackの構築・運用時によく遭遇する問題とその解決方法をまとめています。問題発生時の第一歩として活用してください。

---

## 📑 目次

- [付録B: トラブルシューティング](#付録b-トラブルシューティング)
  - [📑 目次](#-目次)
  - [基本的なトラブルシューティングの流れ](#基本的なトラブルシューティングの流れ)
    - [1. **現象の特定** 🔍](#1-現象の特定-)
    - [2. **ログの確認** 📋](#2-ログの確認-)
    - [3. **サービスの状態確認** ⚙️](#3-サービスの状態確認-️)
    - [4. **接続性の確認** 🌐](#4-接続性の確認-)
    - [5. **設定ファイルの確認** 📄](#5-設定ファイルの確認-)
    - [6. **リソースの確認** 💻](#6-リソースの確認-)
  - [環境準備関連の問題](#環境準備関連の問題)
    - [問題1: PowerShellのバージョンが古い](#問題1-powershellのバージョンが古い)
      - [方法1: WinGetを使用（推奨・最も簡単）](#方法1-wingetを使用推奨最も簡単)
      - [方法2: Microsoft Storeからインストール](#方法2-microsoft-storeからインストール)
      - [方法3: MSIパッケージからインストール](#方法3-msiパッケージからインストール)
    - [問題2: PowerShellスクリプトの実行が無効になっている（Windows）](#問題2-powershellスクリプトの実行が無効になっているwindows)
      - [方法1: 現在のセッションでのみ実行を許可（推奨・一時的）](#方法1-現在のセッションでのみ実行を許可推奨一時的)
      - [方法2: 現在のユーザーのみ実行を許可（永続的・推奨）](#方法2-現在のユーザーのみ実行を許可永続的推奨)
      - [方法3: スクリプトを直接実行（一時的）](#方法3-スクリプトを直接実行一時的)
    - [問題3: 仮想化支援機能が有効にならない](#問題3-仮想化支援機能が有効にならない)
      - [Windowsの場合（PowerShell 7.x管理者権限で実行）](#windowsの場合powershell-7x管理者権限で実行)
      - [BIOS/UEFI設定](#biosuefi設定)
    - [問題4: メモリ不足でVM起動失敗](#問題4-メモリ不足でvm起動失敗)
      - [ノードを順次起動（推奨）](#ノードを順次起動推奨)
    - [問題5: ネットワーク接続失敗](#問題5-ネットワーク接続失敗)
  - [構築フェーズの問題](#構築フェーズの問題)
    - [問題1: コンポーネント間の通信エラー](#問題1-コンポーネント間の通信エラー)
    - [問題2: データベース接続エラー](#問題2-データベース接続エラー)
    - [問題3: RabbitMQ接続エラー](#問題3-rabbitmq接続エラー)
    - [問題4: Keystoneの認証エラー](#問題4-keystoneの認証エラー)
  - [ネットワーク関連の問題](#ネットワーク関連の問題)
    - [問題5: VMにFloating IPが割り当てられない](#問題5-vmにfloating-ipが割り当てられない)
    - [問題6: VMが外部と通信できない](#問題6-vmが外部と通信できない)
    - [問題7: VMのDHCPが機能しない](#問題7-vmのdhcpが機能しない)
    - [問題8: Open vSwitchブリッジの設定エラー](#問題8-open-vswitchブリッジの設定エラー)
  - [ストレージ関連の問題](#ストレージ関連の問題)
    - [問題9: Cinderボリュームの作成に失敗](#問題9-cinderボリュームの作成に失敗)
    - [問題10: ボリュームがVMにアタッチできない](#問題10-ボリュームがvmにアタッチできない)
  - [VM（インスタンス）関連の問題](#vmインスタンス関連の問題)
    - [問題11: VMの起動に失敗](#問題11-vmの起動に失敗)
    - [問題12: VMにSSH接続できない](#問題12-vmにssh接続できない)
    - [問題13: VMのコンソールアクセスができない](#問題13-vmのコンソールアクセスができない)
  - [パフォーマンス関連の問題](#パフォーマンス関連の問題)
    - [問題14: VMのパフォーマンスが低い](#問題14-vmのパフォーマンスが低い)
    - [問題15: API応答が遅い](#問題15-api応答が遅い)
  - [認証・権限の問題](#認証権限の問題)
    - [問題16: ユーザーがリソースにアクセスできない](#問題16-ユーザーがリソースにアクセスできない)
    - [問題17: サービスアカウントのトークンエラー](#問題17-サービスアカウントのトークンエラー)
  - [ログの確認方法](#ログの確認方法)
    - [主要なログファイルの場所](#主要なログファイルの場所)
      - [**Systemdサービスのログ**](#systemdサービスのログ)
      - [**ファイルベースのログ**](#ファイルベースのログ)
    - [ログレベルの調整](#ログレベルの調整)
  - [便利なデバッグコマンド集](#便利なデバッグコマンド集)
    - [OpenStack CLIでのデバッグ](#openstack-cliでのデバッグ)
    - [ネットワークデバッグ](#ネットワークデバッグ)
    - [リソース使用状況の確認](#リソース使用状況の確認)
    - [データベース直接確認（上級者向け）](#データベース直接確認上級者向け)
  - [🆘 さらに助けが必要な場合](#-さらに助けが必要な場合)
    - [公式リソース](#公式リソース)
    - [コミュニティ](#コミュニティ)
    - [日本語リソース](#日本語リソース)
  - [📚 関連ドキュメント](#-関連ドキュメント)

---

## 基本的なトラブルシューティングの流れ

OpenStackで問題が発生した際は、以下の流れで調査を進めます。

### 1. **現象の特定** 🔍

**チェックリスト:**

- □ どのサービスで問題が起きているか？
- □ いつから問題が発生したか？
- □ 再現性はあるか？
- □ エラーメッセージは何か？

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

## 環境準備関連の問題

### 問題1: PowerShellのバージョンが古い

**症状**:

- PowerShell 5.1がインストールされているが、最新機能が使えない
- スクリプトの構文エラーが発生する（PowerShell 7.xで解決される可能性）
- `$PSVersionTable.PSVersion`で確認すると5.x系が表示される

**現在のバージョン確認**:

```powershell
$PSVersionTable.PSVersion
```

**解決方法**:

PowerShell 7.x（PowerShell Core）は、PowerShell 5.1（Windows PowerShell）とは別にインストールされます。両方を共存させることができます。

#### 方法1: WinGetを使用（推奨・最も簡単）

```powershell
# 1. WinGetがインストールされているか確認
winget --version

# WinGetがインストールされていない場合は、Microsoft Storeから「App Installer」をインストール

# 2. PowerShell 7をインストールまたは更新
winget install --id Microsoft.PowerShell --source winget

# 3. インストール確認
pwsh --version
```

#### 方法2: Microsoft Storeからインストール

1. Microsoft Storeを開く
2. 「PowerShell」で検索
3. 「取得」または「インストール」をクリック

#### 方法3: MSIパッケージからインストール

1. [PowerShell公式GitHubリリースページ](https://github.com/PowerShell/PowerShell/releases)にアクセス
2. 最新バージョンの`PowerShell-7.x.x-win-x64.msi`をダウンロード
3. MSIファイルを実行してインストール

**インストール後の使用方法**:

PowerShell 7.xは、PowerShell 5.1とは別の実行ファイルとしてインストールされます。**重要なポイント**: `powershell.exe`は依然としてPowerShell 5.1を起動します。PowerShell 7.xを起動するには、`pwsh.exe`を使用する必要があります。

```powershell
# PowerShell 5.1（従来のWindows PowerShell）
powershell.exe
$PSVersionTable.PSVersion  # 5.x系（Major: 5）

# PowerShell 7.x（新しいPowerShell）
pwsh.exe
$PSVersionTable.PSVersion  # 7.x系（Major: 7）
```

**インストール確認**:

PowerShell 7が正しくインストールされているか確認：

```powershell
# PowerShell 7のバージョン確認（PowerShell 5.1から実行）
pwsh --version

# または、PowerShell 7を起動して確認
pwsh
$PSVersionTable.PSVersion
```

**「まだ5.1が表示される」場合の確認事項**:

1. **PowerShell 7がインストールされているか確認**:

   ```powershell
   # PowerShell 7の実行ファイルの存在確認
   Test-Path "C:\Program Files\PowerShell\7\pwsh.exe"

   # インストールされている場合、パスが表示される
   Get-Command pwsh | Select-Object -ExpandProperty Source
   ```

2. **`pwsh`コマンドを使用する**:
   - ❌ `powershell` または `powershell.exe` → PowerShell 5.1が起動
   - ✅ `pwsh` または `pwsh.exe` → PowerShell 7が起動

3. **スタートメニューから起動**:
   - 「PowerShell 7」または「PowerShell」と検索
   - アイコンが青いアイコン（PowerShell 7）を選択

**デフォルトのPowerShellを変更**:

```powershell
# PowerShell 7をデフォルトのPowerShellとして設定
# （オプション: 管理者権限で実行）
New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name DefaultShell -Value "C:\Program Files\PowerShell\7\pwsh.exe" -PropertyType String -Force
```

**注意事項**:

- PowerShell 5.1とPowerShell 7.xは共存できます
- PowerShell 7.xは`.NET`ベースで、クロスプラットフォーム対応
- 一部のモジュールはPowerShell 7.xで動作しない場合があります（例: 一部のWindows専用モジュール）
- スクリプトを実行する際は、PowerShell 7.xを使用することを推奨：

```powershell
# 重要: pwshを使用すること
pwsh -File .\scripts\setup_vbox_network.ps1

# powershell.exeではPowerShell 5.1が起動するため、構文エラーが発生する可能性がある
```

**Windows Terminalを使用する場合**:

Windows Terminalを使用している場合、デフォルトのプロファイルをPowerShell 7に変更できます：

1. Windows Terminalを開く
2. 設定（歯車アイコン）を開く
3. 「デフォルトのプロファイル」を「PowerShell」または「PowerShell 7」に変更

---

### 問題2: PowerShellスクリプトの実行が無効になっている（Windows）

**症状**:

```text
.\scripts\setup_vbox_network.ps1 : このシステムではスクリプトの実行が無効になっているため、
ファイル D:\...\setup_vbox_network.ps1 を読み込むことができません。
PSSecurityException: UnauthorizedAccess
```

**原因**:

- PowerShellの実行ポリシーが `Restricted` または `AllSigned` に設定されている
- 未署名のスクリプトの実行がブロックされている

**解決方法**:

#### 方法1: 現在のセッションでのみ実行を許可（推奨・一時的）

```powershell
# PowerShell管理者権限で実行
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# スクリプトを実行
.\scripts\setup_vbox_network.ps1
```

#### 方法2: 現在のユーザーのみ実行を許可（永続的・推奨）

```powershell
# PowerShell管理者権限で実行
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 実行ポリシーの確認
Get-ExecutionPolicy -List

# スクリプトを実行
.\scripts\setup_vbox_network.ps1
```

#### 方法3: スクリプトを直接実行（一時的）

```powershell
# PowerShell 7で直接実行（-ExecutionPolicy Bypassを指定）
pwsh -ExecutionPolicy Bypass -File .\scripts\setup_vbox_network.ps1

# 注意: powershell.exeを使用するとPowerShell 5.1が起動します
```

**実行ポリシーの確認**:

```powershell
# 現在の実行ポリシーを確認
Get-ExecutionPolicy

# すべてのスコープの実行ポリシーを確認
Get-ExecutionPolicy -List
```

**実行ポリシーの説明**:

| ポリシー       | 説明                                                         | 推奨度                       |
| -------------- | ------------------------------------------------------------ | ---------------------------- |
| `Restricted`   | すべてのスクリプトの実行を禁止                               | デフォルト                   |
| `AllSigned`    | 署名されたスクリプトのみ実行可能                             | 中                           |
| `RemoteSigned` | ローカルスクリプトは実行可能、リモートスクリプトは署名が必要 | **推奨**                     |
| `Unrestricted` | すべてのスクリプトを実行可能（警告あり）                     | 低（セキュリティリスクあり） |
| `Bypass`       | すべてのスクリプトを警告なしで実行                           | 開発環境のみ                 |

**セキュリティ上の注意**:

- `Unrestricted` や `Bypass` は本番環境では使用しないでください
- プロジェクトのローカルスクリプトのみ実行する場合は `RemoteSigned` で十分です

**実行ポリシーの階層とスコープ**:

PowerShellの実行ポリシーには優先順位があります（上位から下位へ）:

1. `MachinePolicy` (グループポリシー)
2. `UserPolicy` (グループポリシー)
3. `Process` (現在のセッション)
4. `CurrentUser` (現在のユーザー)
5. `LocalMachine` (すべてのユーザー)

より上位のスコープで設定されたポリシーが、下位のスコープの設定を上書きします。

**実行ポリシーを元に戻す際の注意**:

```powershell
# 現在の実行ポリシーを確認
Get-ExecutionPolicy -List
```

もし `Process` スコープで `Bypass` が設定されている場合、`CurrentUser` スコープでの変更は無効になります：

```powershell
# エラー例: ProcessスコープでBypassが設定されている場合
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
# エラー: より上位のスコープ（Process）で定義されたポリシーによって上書きされています

# 解決方法1: Processスコープを確認・変更（現在のセッションのみ）
Get-ExecutionPolicy -Scope Process
# Processスコープはセッション終了時に自動的にリセットされるため、明示的に変更する必要はありません

# 解決方法2: CurrentUserスコープのみ変更（推奨）
# 現在のセッションを閉じて新しいセッションを開いた後：
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser

# 解決方法3: すべてのスコープを確認して適切なスコープを変更
Get-ExecutionPolicy -List
# 実際に有効になっているスコープを確認してから変更してください
```

**推奨される方法**:

現在のセッションで一時的に `Bypass` を設定した場合、セッションを閉じれば自動的にリセットされます。永続的な設定を変更する場合は、新しいPowerShellセッションを開いてから変更してください：

```powershell
# 新しいPowerShellセッションで実行
Set-ExecutionPolicy -ExecutionPolicy Restricted -Scope CurrentUser
```

### 問題3: 仮想化支援機能が有効にならない

**症状**:

- VirtualBoxでVMが起動しない
- `VT-x is not available` エラー
- 仮想化機能が使用できない

**原因**:

- BIOS/UEFIで仮想化機能が無効になっている
- Windows: Hyper-Vが有効になっており、VirtualBoxと競合している

**解決方法**:

#### Windowsの場合（PowerShell 7.x管理者権限で実行）

**WMIを使用した確認方法（推奨）**

```powershell
# 仮想化機能の確認
Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -ExpandProperty HypervisorPresent
```

より詳細な情報を取得する場合：

```powershell
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
Write-Host "仮想化ファームウェア有効: $($computerSystem.HypervisorPresent)"
```

**systeminfoを使用した確認方法**

```powershell
# 仮想化機能の確認
systeminfo | Select-String -Pattern "Virtualization"
```

**期待される出力**: `Virtualization Enabled In Firmware: Yes` または `True`

**Hyper-Vが有効の場合は無効化**:

```powershell
# Hyper-Vが有効の場合は無効化
bcdedit /set hypervisorlaunchtype off

# 再起動が必要
shutdown /r /t 0
```

**注意**: 日本語版Windowsでは、`Select-String`を使用すると確実です。

#### BIOS/UEFI設定

1. PCを再起動
2. 起動時にBIOS/UEFI設定画面に入る（Del, F2, F10, F12など）
3. 以下の設定を探して有効化：
   - **Intel**: "Intel Virtualization Technology" または "Intel VT-x"
   - **AMD**: "AMD-V" または "SVM Mode"
4. 設定を保存して再起動

### 問題4: メモリ不足でVM起動失敗

**症状**:

- `vagrant up`実行時にメモリ不足エラー
- VMが起動しない
- ホストマシンのメモリ使用率が高い

**原因**:

- ホストマシンのメモリが不足している
- 3ノード同時起動で必要なメモリが確保できない

**解決方法**:

```bash
# 1. ホストマシンの空きメモリを確認
# Windows
systeminfo | findstr /C:"Available Physical Memory"

# Linux/macOS
free -h
# または
vm_stat  # macOS

# 2. Vagrantfileでメモリ設定を削減
# openstack-3node/Vagrantfile を編集

# Controller Node
vb.memory = "4096"  # 8GB → 4GB

# Network Node
vb.memory = "2048"  # 4GB → 2GB

# Compute Node
vb.memory = "4096"  # 8GB → 4GB
```

#### ノードを順次起動（推奨）

```bash
# 1台ずつ起動
vagrant up controller
# 起動完了を待つ

vagrant up network
# 起動完了を待つ

vagrant up compute1
```

### 問題5: ネットワーク接続失敗

**症状**:

- VM起動後にネットワーク接続ができない
- SSH接続ができない
- ノード間のpingが通らない

**原因**:

- VirtualBoxネットワーク設定の問題
- ファイアウォールでポートがブロックされている
- Host-Only Networkが正しく設定されていない

**解決方法**:

```bash
# 1. VirtualBoxネットワーク設定の確認
VBoxManage list hostonlyifs

# 2. Host-Only Networkが存在するか確認
# 192.168.100.1のアダプタが存在することを確認

# 3. ネットワークスクリプトを再実行（Windows）
.\scripts\setup_vbox_network.ps1

# または（macOS/Linux）
bash scripts/setup_vbox_network.sh

# 4. ファイアウォールを一時無効化してテスト
# Windows
netsh advfirewall set allprofiles state off

# Linux (Ubuntu)
sudo ufw disable

# macOS（通常はファイアウォールによる問題は少ない）

# 5. VM内からネットワーク設定を確認
vagrant ssh controller
ip addr show
ping -c 3 192.168.100.20
ping -c 3 192.168.100.31
```

**ファイアウォールの再有効化**:

```bash
# Windows
netsh advfirewall set allprofiles state on

# Linux (Ubuntu)
sudo ufw enable
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
- `Missing value auth-url required for auth plugin password`

**原因**:

- 環境変数が設定されていない
- 認証情報が間違っている
- Keystoneサービスが起動していない
- `admin-openrc`ファイルを読み込んでいない

**解決方法**:

```bash
# 1. 環境変数の確認
env | grep OS_

# 2. admin-openrcファイルが存在するか確認
ls -l ~/admin-openrc

# 3. ファイルが存在しない場合は作成
vim ~/admin-openrc
```

以下の内容を追加（パスワードは実際の値に置き換えてください）:

```bash
export OS_PROJECT_DOMAIN_NAME=default
export OS_USER_DOMAIN_NAME=default
export OS_PROJECT_NAME=admin
export OS_USERNAME=admin
export OS_PASSWORD=ADMIN_PASS
export OS_AUTH_URL=https://controller:5000/v3
export OS_IDENTITY_API_VERSION=3
export OS_IMAGE_API_VERSION=2
```

自己署名証明書を使用している場合:

```bash
export OS_CACERT=/etc/ssl/certs/keystone/keystone-cert.pem
# または（開発環境のみ）
export OS_INSECURE=true
```

```bash
# 4. 認証情報を再読込
source ~/admin-openrc

# 5. 環境変数が正しく設定されているか確認
env | grep OS_

# 6. Keystoneサービスの確認
sudo systemctl status apache2  # KeystoneはApacheで動作

# 7. 手動で認証テスト
openstack token issue

# 8. エンドポイントの確認
openstack catalog list
```

> **📌 注意**: 新しいシェルセッションを開始するたびに、`source ~/admin-openrc`を実行する必要があります。または、`~/.bashrc`に`source ~/admin-openrc`を追加することで、自動的に読み込まれるようにできます。

### 問題4-1: トークン発行エラー

**症状**:

```bash
openstack token issue
# ERROR: The request you have made requires authentication.
```

**解決方法**:

1. 環境変数が正しく設定されているか確認:

   ```bash
   env | grep OS_
   ```

2. `admin-openrc`ファイルを再読み込み:

   ```bash
   source ~/admin-openrc
   ```

3. パスワードが正しいか確認（再度ユーザーを作成するか、パスワードをリセット）

4. Keystoneサービスが正常に動作しているか確認:

   ```bash
   curl -k https://controller:5000/v3/ | python3 -m json.tool
   ```

### 問題4-2: データベース同期エラー

**症状**:

```bash
sudo keystone-manage db_sync
# または
sudo nova-manage api_db sync
# ERROR: ...
```

**解決方法**:

1. データベースが作成されているか確認:

   ```bash
   sudo mysql -u root -p -e "SHOW DATABASES LIKE '<service>';"
   # 例: SHOW DATABASES LIKE 'keystone';
   # 例: SHOW DATABASES LIKE 'nova%';
   ```

2. データベースユーザーに権限があるか確認:

   ```bash
   sudo mysql -u root -p -e "SHOW GRANTS FOR '<user>'@'localhost';"
   # 例: SHOW GRANTS FOR 'keystone'@'localhost';
   ```

3. データベース接続をテスト:

   ```bash
   mysql -u <user> -p<PASSWORD> -h controller <database> -e "SELECT 1;"
   ```

4. 既存のスキーマを削除して再同期（注意: データが削除されます）:

   ```bash
   sudo mysql -u root -p <database> -e "DROP DATABASE <database>;"
   sudo mysql -u root -p -e "CREATE DATABASE <database> CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
   sudo <service>-manage db_sync
   # 例: sudo keystone-manage db_sync
   # 例: sudo nova-manage api_db sync
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
