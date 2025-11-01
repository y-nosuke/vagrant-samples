# OpenStack 3-Node Learning Environment

OpenStack学習用の3ノード構成環境です。Vagrant + VirtualBoxで構築します。

## 🎯 このプロジェクトについて

このリポジトリは、OpenStackの仕組みを深く理解するための学習環境を提供します。
手動構築を通じて、各コンポーネントの役割と相互作用を学ぶことができます。

### 特徴

- **3ノード構成**: Controller、Network、Computeの役割分担を明確に学習
- **段階的な学習**: Phase 1-5のステップバイステップガイド
- **実践的な演習**: Webサーバー構築、ネットワーク設定、ボリューム管理
- **CommandとTerraform**: 両方のアプローチで学習可能
- **豊富なドキュメント**: アーキテクチャからトラブルシューティングまで網羅

## 📋 前提条件

- **CPU**: 8コア以上（仮想化支援機能必須）
- **メモリ**: 24GB以上推奨（最小16GB）
- **ディスク**: 200GB以上の空き容量（SSD推奨）
- **ソフトウェア**: VirtualBox 7.0+, Vagrant 2.3+

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
    ├── phase3_core_services.md
    ├── phase4_first_vm.md
    ├── phase5_exercises.md
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

3. **[Phase 3: コアサービス構築](docs/phase3_core_services.md)**
   - Keystone（認証）
   - Glance（イメージ）
   - Nova（コンピュート）
   - Neutron（ネットワーク）

4. **[Phase 4: 初回VM起動](docs/phase4_first_vm.md)**
   - SSH鍵ペア作成
   - セキュリティグループ設定
   - VMインスタンス起動
   - Floating IP割り当て

5. **[Phase 5: 基本演習](docs/phase5_exercises.md)**
   - Webサーバー構築
   - ボリューム管理

### オプション学習（選択）

- **カテゴリA**: 管理機能強化（Horizon、Cinder詳細）
- **カテゴリB**: ネットワーク深掘り（LB、マルチテナント）
- **カテゴリC**: 運用・監視（バックアップ、Prometheus）
- **カテゴリD**: スケーラビリティ（ノード追加、HA構成）
- **カテゴリE**: 自動化・IaC（Terraform、Ansible、Heat）
- **カテゴリF**: 次世代への移行（Kolla-Ansible）

詳細は [OpenStack学習ロードマップ](../openstack-learning-roadmap.md) を参照してください。

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
- [phase3_core_services.md](docs/phase3_core_services.md) - Phase 3: コアサービス
- [phase4_first_vm.md](docs/phase4_first_vm.md) - Phase 4: 初回VM起動
- [phase5_exercises.md](docs/phase5_exercises.md) - Phase 5: 基本演習

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

## ⚠️ トラブルシューティング

問題が発生した場合は以下を参照：

- [トラブルシューティングガイド](docs/appendix_b_troubleshooting.md)

よくある問題：

- 仮想化支援機能が有効にならない
- メモリ不足でVM起動失敗
- ノード間の通信失敗

## 🔗 参考リンク

- [OpenStack公式ドキュメント](https://docs.openstack.org/)
- [Server World - OpenStack Epoxy](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack_epoxy)
- [Vagrant Documentation](https://www.vagrantup.com/docs)
- [VirtualBox Documentation](https://www.virtualbox.org/wiki/Documentation)

## 📝 ライセンス

MIT License

## 🤝 コントリビューション

Issue、Pull Requestを歓迎します。

## 📧 お問い合わせ

質問や提案がある場合は、GitHubのIssueをご利用ください。
