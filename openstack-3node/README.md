# OpenStack 3-Node Learning Environment

OpenStack学習用の3ノード構成環境です。Vagrant + VirtualBoxで構築します。

## 🎯 このプロジェクトについて

このリポジトリは、OpenStackの仕組みを深く理解するための学習環境を提供します。
手動構築を通じて、各コンポーネントの役割と相互作用を学ぶことができます。

### 📝 このドキュメントについて

このドキュメントでは、Markdownの引用ブロック（`>`）をNOTE記法の代わりとして使用しています。

**引用ブロック（`>`）を使うべき場合**:

1. **重要な警告・注意事項**
   - `⚠️ 重要`、`🔐 セキュリティノート` など
   - 本文から独立した補足情報
   - 例: セキュリティに関する警告、重要な注意事項

2. **短い補足情報・参考情報**
   - 本文の流れを中断しない短い補足
   - 参考リンクや関連情報
   - 例: 「📌 参考: [リンク]」

3. **短い注意書き**
   - 1-2行程度の簡潔な注意
   - 例: 「📌 注意: Vagrant環境では...」

**引用ブロックを使わないべき場合**:

1. **コマンド解説**
   - 本文の一部として説明
   - 例: 「📌 コマンド解説: `keystone-manage db_sync`」

2. **設定項目の説明**
   - 手順の一部として説明
   - 例: 「📌 設定項目の説明」

3. **長い説明文**
   - 複数段落にわたる説明
   - 例: 「📌 重要な設定項目」（複数の項目を説明）

4. **手順の一部としての説明**
   - 本文の流れに沿った説明
   - 例: 「📌 次のステップ」

### 特徴

- **3ノード構成**: Controller、Network、Computeの役割分担を明確に学習
- **段階的な学習**: Phase 1-5のステップバイステップガイド
- **実践的な演習**: Webサーバー構築、ネットワーク設定、ボリューム管理
- **CommandとTerraform**: 両方のアプローチで学習可能
- **豊富なドキュメント**: アーキテクチャからトラブルシューティングまで網羅

## 📋 前提条件

- **CPU**: 8コア以上（仮想化支援機能必須）
- **メモリ**: 16GB以上（24GB推奨）
- **ディスク**: 200GB以上の空き容量（SSD推奨）
- **ソフトウェア**: VirtualBox 7.0+, Vagrant 2.3+

📖 **詳細な環境要件と構成**: [OpenStack学習環境構築ロードマップ](docs/openstack-learning-roadmap.md)

## 🚀 クイックスタート

```bash
# リポジトリのクローン
git clone https://github.com/y-nosuke/vagrant-samples.git
cd vagrant-samples/openstack-3node

# VM起動（初回は20-30分）
vagrant up

# 状態確認
vagrant status

# SSH接続
vagrant ssh controller
```

詳細は [Phase 1: 環境準備](docs/phase1_environment_setup.md) を参照してください。

## 📁 ディレクトリ構成

```bash
openstack-3node/
├── Vagrantfile              # VM構成定義
├── README.md                # このファイル
├── provision/               # プロビジョニングスクリプト
├── configs/                 # 設定ファイルテンプレート
├── scripts/                 # 運用スクリプト
├── terraform/               # Terraform設定（オプション）
└── docs/                    # ドキュメント
    ├── phase1_environment_setup.md
    ├── phase2_foundation.md
    ├── phase3_keystone.md
    ├── phase4_glance.md
    ├── phase5_nova.md
    └── (その他のドキュメント)
```

## 📚 学習の流れ

### コアパス（必須）

1. **[Phase 1: 環境準備](docs/phase1_environment_setup.md)**
   - Vagrant + VirtualBoxでVM構築
   - ノード間ネットワーク確認

2. **[Phase 2: 基盤構築](docs/phase2_foundation.md)**
   - MariaDB、RabbitMQ、Memcached構築
   - OpenStackの基盤を準備

3. **[Phase 3: Keystone（認証サービス）](docs/phase3_keystone.md)**
   - OpenStackの認証・認可基盤を構築
   - プロジェクト、ユーザー、ロールの作成

4. **[Phase 4: Glance（イメージサービス）](docs/phase4_glance.md)**
   - VMイメージの管理システムを構築

5. **[Phase 5: Nova（コンピュートサービス）](docs/phase5_nova.md)**
   - 仮想マシンの管理システムを構築

6. **[Phase 6: Neutron（ネットワークサービス）](docs/phase6_neutron.md)**
   - 仮想ネットワークの管理システムを構築

7. **[Phase 7: 初回VM起動](docs/phase7_first_vm.md)**
   - SSH鍵ペア作成
   - セキュリティグループ設定
   - VMインスタンス起動
   - Floating IP割り当て

8. **[Phase 8: Cinder（ボリュームサービス）](docs/phase8_cinder.md)**
   - 永続ブロックストレージシステムを構築

9. **[Phase 9: 基本演習・統合確認](docs/phase9_exercises.md)**
   - Webサーバー構築
   - 全サービスの連携確認

### オプション学習（選択）

- **カテゴリA**: 管理機能強化（Horizon、Cinder詳細）
- **カテゴリB**: ネットワーク深掘り（LB、マルチテナント）
- **カテゴリC**: 運用・監視（バックアップ、Prometheus）
- **カテゴリD**: スケーラビリティ（ノード追加、HA構成）
- **カテゴリE**: 自動化・IaC（Terraform、Ansible、Heat）
- **カテゴリF**: 次世代への移行（Kolla-Ansible）

詳細は [OpenStack学習ロードマップ](docs/openstack-learning-roadmap.md) を参照してください。

## 📖 ドキュメント

### 基礎知識

- [01_overview.md](docs/01_overview.md) - OpenStack概要
- [02_architecture.md](docs/02_architecture.md) - アーキテクチャ
- [03_network_design.md](docs/03_network_design.md) - ネットワーク設計
- [04_system_design.md](docs/04_system_design.md) - システム設計
- [05_operations_security.md](docs/05_operations_security.md) - 運用・セキュリティ
- [06_practical_guide.md](docs/06_practical_guide.md) - 実践ガイド

### 構築手順

- [phase1_environment_setup.md](docs/phase1_environment_setup.md) - Phase 1: 環境準備
- [phase2_foundation.md](docs/phase2_foundation.md) - Phase 2: 基盤構築
- [phase3_keystone.md](docs/phase3_keystone.md) - Phase 3: Keystone（認証サービス）
- [phase4_glance.md](docs/phase4_glance.md) - Phase 4: Glance（イメージサービス）
- [phase5_nova.md](docs/phase5_nova.md) - Phase 5: Nova（コンピュートサービス）
- [phase6_neutron.md](docs/phase6_neutron.md) - Phase 6: Neutron（ネットワークサービス）
- [phase7_first_vm.md](docs/phase7_first_vm.md) - Phase 7: 初回VM起動
- [phase8_cinder.md](docs/phase8_cinder.md) - Phase 8: Cinder（ボリュームサービス）
- [phase9_exercises.md](docs/phase9_exercises.md) - Phase 9: 基本演習・統合確認

### 付録

- [appendix_a_glossary.md](docs/appendix_a_glossary.md) - 用語集
- [appendix_b_troubleshooting.md](docs/appendix_b_troubleshooting.md) - トラブルシューティング
- [appendix_c_references.md](docs/appendix_c_references.md) - 参考リンク

### その他

- [network-diagram.md](docs/network-diagram.md) - ネットワーク構成図（詳細）

## 🔧 よく使うコマンド

```bash
# VM起動
vagrant up
# または
vagrant up controller

# プロビジョニングを伴う既存VMの起動
vagrant up --provision
# または
vagrant up --provision controller

# プロビジョニング
vagrant provision
# または
vagrant provision controller

# VM停止
vagrant halt

# VM再起動
vagrant reload

# VM削除
vagrant destroy -f

# SSH接続
vagrant ssh <node-name>

# VM状態確認
vagrant status
```

## 🚀 プロビジョニングスクリプト

Vagrantfileに機能ごとのプロビジョニングスクリプトが定義されています。不要な機能はコメントアウトすることで実行をスキップできます。

### 使用方法

#### 1. 初回VM起動時（全プロビジョニング実行）

```bash
vagrant up
```

#### 2. 特定のプロビジョニングのみ実行

```bash
# コントローラノードのhosts設定のみ実行
vagrant provision controller --provision-with hosts

# Keystone関連をすべて実行
vagrant provision controller --provision-with keystone-db,keystone-install,keystone-config,keystone-apache,keystone-bootstrap
```

#### 3. Vagrantfileでコメントアウト

```ruby
# 不要なプロビジョニングをコメントアウト
# controller.vm.provision "rabbitmq", type: "shell", path: "provision/foundation_rabbitmq.sh"
```

### パスワードのカスタマイズ

環境変数でパスワードを指定できます：

```bash
export MARIADB_ROOT_PASSWORD="your_password"
export KEYSTONE_DBPASS="keystone_password"
export ADMIN_PASS="admin_password"
export RABBITMQ_PASSWORD="rabbitmq_password"

vagrant up
```

### 利用可能なプロビジョニング

- **全ノード共通**: `hosts`, `ntp`, `repository`
- **基盤構築**: `mariadb`, `rabbitmq`, `memcached`
- **Keystone**: `keystone-db`, `keystone-install`, `keystone-config`, `keystone-apache`, `keystone-bootstrap`

📖 **詳細**: [provision/README.md](provision/README.md)

## ⚠️ トラブルシューティング

問題が発生した場合は以下を参照：

- [トラブルシューティングガイド](docs/appendix_b_troubleshooting.md)

よくある問題：

- 仮想化支援機能が有効にならない
- メモリ不足でVM起動失敗
- ノード間の通信失敗

## 🔗 参考リンク

- [OpenStack公式ドキュメント](https://docs.openstack.org/)
- [Server World - OpenStack Flamingo](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox Documentation](https://www.virtualbox.org/wiki/Documentation)

## 📝 ライセンス

MIT License

## 🤝 コントリビューション

Issue、Pull Requestを歓迎します。

## 📧 お問い合わせ

質問や提案がある場合は、GitHubのIssueをご利用ください。
