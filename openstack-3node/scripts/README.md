# 補助スクリプト

OpenStack学習環境の構築・管理を効率化するための補助スクリプトです。

## 目次

- [前提条件確認スクリプト](#前提条件確認スクリプト)
- [環境構築スクリプト](#環境構築スクリプト)
- [環境削除スクリプト](#環境削除スクリプト)
- [ネットワーク設定スクリプト](#ネットワーク設定スクリプト)

---

## 前提条件確認スクリプト

### check_environment.ps1 / check_environment.sh

環境構築前に、前提条件が満たされているか確認するスクリプトです。

**機能:**

- 仮想化支援機能の確認（Intel VT-x / AMD-V）
- Hyper-Vの確認（VirtualBoxとの互換性確認、Windowsのみ）
- VirtualBoxのインストール確認
- Vagrantのインストール確認
- ブリッジネットワークの確認

**使用方法:**

**Windows (PowerShell 7.x):**

```powershell
# 管理者権限は不要
pwsh -ExecutionPolicy Bypass -File .\scripts\check_environment.ps1
```

**macOS/Linux:**

```bash
# スクリプトを実行
bash scripts/check_environment.sh

# または実行権限を付与してから実行
chmod +x scripts/check_environment.sh
./scripts/check_environment.sh
```

**実行例:**

```bash
========================================
OpenStack学習環境 - 前提条件確認
========================================

[1/4] 仮想化支援機能を確認中...
✓ 仮想化支援機能が有効です
✓ Hyper-Vは無効です（VirtualBoxと互換性あり）

[2/4] VirtualBoxのインストールを確認中...
✓ VirtualBoxがインストールされています: 7.0.12r159484

[3/4] Vagrantのインストールを確認中...
✓ Vagrantがインストールされています: Vagrant 2.4.0

[4/4] ブリッジネットワークを確認中...
✓ 使用可能な物理ネットワークアダプタ:
  - Intel(R) Wi-Fi 6E AX211 160MHz

========================================
確認完了 - 全ての前提条件を満たしています
========================================
```

---

## 環境構築スクリプト

### setup_environment.ps1 / setup_environment.sh

環境構築を自動化するスクリプトです。`cleanup_environment.ps1`/`cleanup_environment.sh`の逆の操作を行います。

**機能:**

- Host-Only Networkの作成（`setup_vbox_network.ps1`/`setup_vbox_network.sh`を呼び出し）
- ブリッジネットワークの確認
- Vagrant VMの起動（`vagrant up`）

**使用方法:**

**Windows (PowerShell 7.x管理者権限で実行):**

```powershell
# 管理者権限が必要（ネットワーク作成のため）
pwsh -ExecutionPolicy Bypass -File .\scripts\setup_environment.ps1
```

**macOS/Linux:**

```bash
# スクリプトを実行
bash scripts/setup_environment.sh

# または実行権限を付与してから実行
chmod +x scripts/setup_environment.sh
./scripts/setup_environment.sh
```

**実行例:**

```bash
========================================
OpenStack学習環境 - 環境構築
========================================

[1/3] Host-Only Networkを設定中...
  （setup_vbox_network.ps1の出力が表示されます）

[2/3] ブリッジネットワークを確認中...
✓ 使用可能な物理ネットワークアダプタ:
  - Intel(R) Wi-Fi 6E AX211 160MHz

[3/3] Vagrant VMを起動中...
  初回起動は20-30分かかります...
  （vagrant upの出力が表示されます）

========================================
環境構築完了
========================================
```

---

## 環境削除スクリプト

### cleanup_environment.ps1 / cleanup_environment.sh

学習環境を完全に削除するスクリプトです。`setup_environment.ps1`/`setup_environment.sh`で作成したリソースを削除します。

**機能:**

- Vagrant VMの削除（`controller`、`network`、`compute1`）
- VirtualBox Host-Only Networkの削除（172.16.100.0/24）
- Vagrantメタデータの削除（`.vagrant`ディレクトリ）
- オプション: 未使用のVagrantボックスの削除

**使用方法:**

**Windows (PowerShell 7.x):**

```powershell
# PowerShell 7.xで実行
pwsh -ExecutionPolicy Bypass -File .\scripts\cleanup_environment.ps1
```

**macOS/Linux:**

```bash
# スクリプトを実行
bash scripts/cleanup_environment.sh

# または実行権限を付与してから実行
chmod +x scripts/cleanup_environment.sh
./scripts/cleanup_environment.sh
```

**実行例:**

```bash
========================================
OpenStack学習環境 - クリーンアップ
========================================

警告: このスクリプトは以下のリソースを削除します:
  - 全てのVagrant VM (controller, network, compute1)
  - VirtualBox Host-Only Network (172.16.100.0/24)

続行してもよろしいですか? (yes/no): yes

[1/3] Vagrant VMを削除中...
✓ Vagrant VMを削除しました

未使用のVagrantボックスも削除しますか? (yes/no): no

[2/3] VirtualBox Host-Only Networkを削除中...
✓ VirtualBox Host-Only Networkを削除しました

[3/3] その他のリソースをクリーンアップ中...
✓ VirtualBox内部ネットワークのクリーンアップ完了
✓ Vagrantメタデータを削除しました

========================================
クリーンアップ完了
========================================
```

**削除されるリソース:**

1. **Vagrant VM**
   - `controller`、`network`、`compute1` の全てのVM
   - Vagrantメタデータ (`.vagrant` ディレクトリ)
   - オプション: 未使用のVagrantボックス

2. **VirtualBox Host-Only Network**
   - 管理ネットワーク用アダプタ (172.16.100.0/24)
   - 関連するDHCPサーバー設定

3. **その他のリソース**
   - VirtualBox内部ネットワーク（VM削除時に自動削除）

**注意事項:**

- **警告**: クリーンアップスクリプトは全てのVMとデータを削除します
- 実行前に必要なデータのバックアップを取ってください
- 削除後、再度環境を構築する場合は `setup_environment.ps1`（または `.sh`）を実行してください

**手動での削除:**

スクリプトを使用しない場合は、以下のコマンドで手動削除も可能です：

```bash
# VMを削除
vagrant destroy -f

# Vagrantメタデータを削除
rm -rf .vagrant

# VirtualBox Host-Only Networkを削除（手動）
VBoxManage list hostonlyifs  # アダプタ名を確認
VBoxManage hostonlyif remove <アダプタ名>
```

---

## ネットワーク設定スクリプト

### setup_vbox_network.ps1 / setup_vbox_network.sh

VirtualBox Host-Only Networkを作成・設定するスクリプトです。管理ネットワーク（172.16.100.0/24）用のアダプタを作成します。

**機能:**

- VirtualBox Host-Only Networkアダプタの作成
- 管理ネットワーク (172.16.100.0/24) の設定
- DHCPサーバーの無効化

**使用方法:**

**Windows (PowerShell 7.x管理者権限で実行):**

```powershell
# PowerShell 7.x管理者権限で実行
pwsh -ExecutionPolicy Bypass -File .\scripts\setup_vbox_network.ps1
```

**macOS/Linux (Bash):**

```bash
# プロジェクトディレクトリで実行
bash scripts/setup_vbox_network.sh

# または実行権限を付与してから実行
chmod +x scripts/setup_vbox_network.sh
./scripts/setup_vbox_network.sh
```

**実行例:**

```bash
========================================
OpenStack学習環境 - ネットワーク設定
========================================

[1/4] 既存のHost-Only Networkアダプタを確認中...
× 管理ネットワーク用アダプタが見つかりません。

[2/4] Host-Only Networkアダプタを作成中...
✓ アダプタを作成しました: VirtualBox Host-Only Ethernet Adapter #2

[3/4] IPアドレスを設定中...
✓ IPアドレスを設定しました: 172.16.100.1/24

[4/4] DHCPサーバーを無効化中...
✓ DHCPサーバーを無効化しました

========================================
設定完了
========================================

管理ネットワーク設定:
  ネットワーク: 172.16.100.0/24
  ゲートウェイ: 172.16.100.1 (ホストOS)
  アダプタ名: VirtualBox Host-Only Ethernet Adapter #2

ノードIPアドレス:
  Controller: 172.16.100.10
  Network:    172.16.100.20
  Compute1:   172.16.100.31

次のステップ:
  1. vagrant up を実行してVMを起動
  2. ssh vagrant@172.16.100.10 でControllerノードに接続可能
```

**注意事項:**

- このスクリプトは管理者権限が必要です（ネットワークアダプタ作成のため）
- 既に同じIPアドレス（172.16.100.1）のアダプタが存在する場合は、作成をスキップします
- スクリプトは `setup_environment.ps1`/`setup_environment.sh` から自動的に呼び出されます

---

## 関連ドキュメント

- [Phase 1: 環境準備](../docs/phase1_environment_setup.md)
- [Vagrantfile](../Vagrantfile)

