# OpenStack 3-Node Learning Environment

OpenStack学習用の3ノード構成環境です。Vagrant + VirtualBoxで構築します。

## 🎯 このプロジェクトについて

このリポジトリは、OpenStackの仕組みを深く理解するための学習環境を提供します。
手動構築を通じて、各コンポーネントの役割と相互作用を学ぶことができます。

### 特徴

- **3ノード構成**: Controller、Network、Computeの役割分担を明確に学習
- **段階的な学習**: Phase 1-9のステップバイステップガイド
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

## 📚 学習の流れ

### コアパス（必須）

1. **[Phase 1: 環境準備](docs/phase1_environment_setup.md)** - Vagrant + VirtualBoxでVM構築
2. **[Phase 2: 基盤構築](docs/phase2_foundation.md)** - MariaDB、RabbitMQ、Memcached構築
3. **[Phase 3: Keystone（認証サービス）](docs/phase3_keystone.md)** - 認証・認可基盤を構築
4. **[Phase 4: Glance（イメージサービス）](docs/phase4_glance.md)** - VMイメージの管理システムを構築
5. **[Phase 5: Nova（コンピュートサービス）](docs/phase5_nova.md)** - 仮想マシンの管理システムを構築
6. **[Phase 6: Neutron（ネットワークサービス）](docs/phase6_neutron.md)** - 仮想ネットワークの管理システムを構築
7. **[Phase 7: 初回VM起動](docs/phase7_first_vm.md)** - SSH鍵ペア作成、セキュリティグループ設定、VMインスタンス起動
8. **[Phase 8: Cinder（ボリュームサービス）](docs/phase8_cinder.md)** - 永続ブロックストレージシステムを構築
9. **[Phase 9: 基本演習・統合確認](docs/phase9_exercises.md)** - Webサーバー構築、全サービスの連携確認

### オプション学習（選択）

- **カテゴリA**: 管理機能強化（Horizon、Cinder詳細）
- **カテゴリB**: ネットワーク深掘り（LB、マルチテナント）
- **カテゴリC**: 運用・監視（バックアップ、Prometheus）
- **カテゴリD**: スケーラビリティ（ノード追加、HA構成）
- **カテゴリE**: 自動化・IaC（Terraform、Ansible、Heat）
- **カテゴリF**: 次世代への移行（Kolla-Ansible）

詳細は [OpenStack学習ロードマップ](docs/openstack-learning-roadmap.md) を参照してください。

## 📖 ドキュメント

### 構築手順（Phaseガイド）

各Phaseの詳細な構築手順は、上記の「学習の流れ」を参照してください。

### 基礎知識

- [01_overview.md](docs/01_overview.md) - OpenStack概要
- [02_architecture.md](docs/02_architecture.md) - アーキテクチャ
- [03_network_design.md](docs/03_network_design.md) - ネットワーク設計
- [04_system_design.md](docs/04_system_design.md) - システム設計
- [05_operations_security.md](docs/05_operations_security.md) - 運用・セキュリティ
- [06_practical_guide.md](docs/06_practical_guide.md) - 実践ガイド

### 付録

- [appendix_a_glossary.md](docs/appendix_a_glossary.md) - 用語集
- [appendix_b_troubleshooting.md](docs/appendix_b_troubleshooting.md) - トラブルシューティング
- [appendix_c_references.md](docs/appendix_c_references.md) - 参考リンク

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

### 基本的な使用方法

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

### プロビジョニングの設計思想

このプロジェクトでは、**ガイドドキュメントのStep単位とプロビジョニングファイルの単位を一致させる**ことで、学習しやすく、理解しやすい構造にしています。

- **1つのStep = 1つのプロビジョニングファイル**（または明確な対応関係）
- ガイドを読みながら、対応するプロビジョニングファイルを実行できる
- 手動構築と自動化の両方で同じ手順を学習できる

#### 統一されたセクション構造

各OpenStackコンポーネント（Keystone、Glance、Novaなど）のPhaseガイドドキュメントでは、以下の統一されたセクション構造を使用しています。新しいコンポーネントのドキュメントを作成する際は、この構造に従ってください：

1. **データベースの作成** - コンポーネント用のデータベースとユーザーを作成
2. **Keystoneでのサービス登録** - ユーザー、サービス、エンドポイントの登録（該当する場合）
3. **パッケージのインストール** - 必要なパッケージのインストール
4. **設定ファイルの編集** - コンポーネントの設定ファイルを編集
5. **データベースの同期** - データベーススキーマの作成・更新
6. **Webサーバーの設定** - Apache/Nginxの設定（該当する場合）
7. **サービスの起動** - systemdサービスの起動と有効化
8. **動作確認** - サービスが正常に動作しているか確認
9. **追加設定** - Bootstrap、Flavor作成、イメージアップロードなど（該当する場合）

> **📌 注意**: 一部のStepは複数の処理を含むため、1つのプロビジョニングファイルが複数のStepに対応する場合があります。その場合、プロビジョニングファイル内で処理が順番に実行されるように設計されています。

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
- **Glance**: `glance-db`, `glance-install`, `glance-config`, `glance-nginx`, `glance-service`, `glance-upload-image`
- **Nova**: `nova-db`, `nova-install`, `placement-config`, `placement-apache`, `nova-config`, `nova-nginx`, `placement-service`, `nova-service`, `nova-flavor`
- **Nova Compute**: `nova-compute-install`, `nova-compute-config`, `nova-compute-service`

📖 **詳細な対応表と使用方法**: [provision/README.md](provision/README.md)

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

---

## 📝 このドキュメントについて

このドキュメントでは、Markdownの引用ブロック（`>`）をNOTE記法の代わりとして使用しています。

**引用ブロック（`>`）を使うべき場合**:

1. **重要な警告・注意事項** - `⚠️ 重要`、`🔐 セキュリティノート` など
2. **短い補足情報・参考情報** - 本文から独立した短い補足
3. **短い注意書き** - 1-2行程度の簡潔な注意

**引用ブロックを使わないべき場合**:

1. **コマンド解説** - 本文の一部として説明
2. **設定項目の説明** - 手順の一部として説明
3. **長い説明文** - 複数段落にわたる説明
4. **手順の一部としての説明** - 本文の流れに沿った説明

詳細は各Phaseガイドドキュメントを参照してください。
