# 付録C: 参考リンク集

**[OpenStack学習資料]**

---

このドキュメントでは、OpenStackの学習・構築・運用に役立つWebサイト、ドキュメント、ツール等のリンクを分類して紹介します。

---

## 📑 目次

- [付録C: 参考リンク集](#付録c-参考リンク集)
  - [📑 目次](#-目次)
  - [公式ドキュメント](#公式ドキュメント)
    - [📘 メインドキュメント](#-メインドキュメント)
    - [🔧 コンポーネント別ドキュメント](#-コンポーネント別ドキュメント)
    - [📖 運用ガイド](#-運用ガイド)
  - [学習リソース](#学習リソース)
    - [🎓 初心者向けチュートリアル](#-初心者向けチュートリアル)
    - [🎬 動画・オンラインコース](#-動画オンラインコース)
    - [📚 ハンズオン環境](#-ハンズオン環境)
  - [デプロイメントツール](#デプロイメントツール)
    - [🚀 主要デプロイメントツール](#-主要デプロイメントツール)
    - [🔄 コンテナオーケストレーション](#-コンテナオーケストレーション)
  - [コミュニティ](#コミュニティ)
    - [💬 フォーラム・Q\&A](#-フォーラムqa)
    - [📧 メーリングリスト](#-メーリングリスト)
    - [💻 IRC / Slack](#-irc--slack)
    - [🌏 イベント](#-イベント)
  - [日本語リソース](#日本語リソース)
    - [🇯🇵 日本語ドキュメント・サイト](#-日本語ドキュメントサイト)
    - [🏢 日本のコミュニティ](#-日本のコミュニティ)
    - [📰 日本語ブログ・メディア](#-日本語ブログメディア)
  - [関連プロジェクト](#関連プロジェクト)
    - [🔗 インフラストラクチャ](#-インフラストラクチャ)
    - [🧰 管理・自動化ツール](#-管理自動化ツール)
    - [☁️ クラウドネイティブ](#️-クラウドネイティブ)
    - [🌐 比較検討](#-比較検討)
  - [モニタリング・運用ツール](#モニタリング運用ツール)
    - [📊 モニタリング](#-モニタリング)
    - [📋 ロギング](#-ロギング)
    - [🚨 アラート・オンコール](#-アラートオンコール)
  - [ブログ・技術記事](#ブログ技術記事)
    - [🌟 著名なブログ](#-著名なブログ)
    - [✍️ 個人ブログ](#️-個人ブログ)
    - [📰 ニュース・メディア](#-ニュースメディア)
  - [書籍](#書籍)
    - [📖 英語の書籍](#-英語の書籍)
    - [📕 日本語の書籍](#-日本語の書籍)
  - [🔧 便利なツール・スクリプト](#-便利なツールスクリプト)
    - [🛠️ CLI拡張](#️-cli拡張)
    - [🐍 Python SDK](#-python-sdk)
    - [🌐 Web UI](#-web-ui)
  - [📱 モバイルアプリ](#-モバイルアプリ)
  - [🎓 資格・認定](#-資格認定)
  - [🚀 最新情報の入手方法](#-最新情報の入手方法)
    - [📢 公式情報源](#-公式情報源)
    - [📅 リリース情報](#-リリース情報)
  - [🎯 学習ロードマップの参考](#-学習ロードマップの参考)
    - [レベル別おすすめリソース](#レベル別おすすめリソース)
      - [**初級者（入門）**](#初級者入門)
      - [**中級者（実践）**](#中級者実践)
      - [**上級者（深堀り）**](#上級者深堀り)
  - [📚 関連ドキュメント](#-関連ドキュメント)
  - [🙏 謝辞](#-謝辞)

---

## 公式ドキュメント

OpenStackプロジェクトの公式ドキュメントです。最も信頼性の高い情報源。

### 📘 メインドキュメント

| リンク                                                                               | 説明                               |
| ------------------------------------------------------------------------------------ | ---------------------------------- |
| [OpenStack Documentation](https://docs.openstack.org/)                               | 公式ドキュメントのトップページ     |
| [OpenStack Installation Guides](https://docs.openstack.org/install/)                 | インストールガイド（リリースごと） |
| [OpenStack API Guide](https://docs.openstack.org/api-quick-start/)                   | APIクイックスタート                |
| [OpenStack CLI Reference](https://docs.openstack.org/python-openstackclient/latest/) | コマンドラインリファレンス         |
| [OpenStack Configuration Reference](https://docs.openstack.org/configuration/)       | 設定ファイルリファレンス           |

### 🔧 コンポーネント別ドキュメント

| コンポーネント                     | ドキュメント                                                        |
| ---------------------------------- | ------------------------------------------------------------------- |
| **Keystone** (認証)                | [docs.openstack.org/keystone](https://docs.openstack.org/keystone/) |
| **Nova** (コンピュート)            | [docs.openstack.org/nova](https://docs.openstack.org/nova/)         |
| **Neutron** (ネットワーク)         | [docs.openstack.org/neutron](https://docs.openstack.org/neutron/)   |
| **Glance** (イメージ)              | [docs.openstack.org/glance](https://docs.openstack.org/glance/)     |
| **Cinder** (ブロックストレージ)    | [docs.openstack.org/cinder](https://docs.openstack.org/cinder/)     |
| **Swift** (オブジェクトストレージ) | [docs.openstack.org/swift](https://docs.openstack.org/swift/)       |
| **Horizon** (ダッシュボード)       | [docs.openstack.org/horizon](https://docs.openstack.org/horizon/)   |
| **Heat** (オーケストレーション)    | [docs.openstack.org/heat](https://docs.openstack.org/heat/)         |

### 📖 運用ガイド

| リンク                                                               | 説明                                         |
| -------------------------------------------------------------------- | -------------------------------------------- |
| [Operations Guide](https://docs.openstack.org/operations-guide/)     | 運用ガイド（監視、トラブルシューティング等） |
| [Security Guide](https://docs.openstack.org/security-guide/)         | セキュリティガイド                           |
| [High Availability Guide](https://docs.openstack.org/ha-guide/)      | 高可用性構成ガイド                           |
| [Architecture Design Guide](https://docs.openstack.org/arch-design/) | アーキテクチャ設計ガイド                     |

---

## 学習リソース

OpenStackを学ぶための初心者向けリソースです。

### 🎓 初心者向けチュートリアル

| リンク                                                                                      | 説明                                                      |
| ------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| [Server World - OpenStack](https://www.server-world.info/query?os=Ubuntu_24.04&p=openstack) | **日本語・最強の実践ガイド** - コマンドベースで詳細に解説 |
| [OpenStack First App](https://docs.openstack.org/firstapp/)                                 | 初めてのOpenStackアプリケーション開発                     |
| [Try OpenStack](https://www.openstack.org/software/try)                                     | 公式のクイックスタートガイド                              |

### 🎬 動画・オンラインコース

| リンク                                                                                                                      | 説明                                       |
| --------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------ |
| [OpenStack YouTube Channel](https://www.youtube.com/@OpenStack)                                                             | 公式YouTubeチャンネル（Summit動画など）    |
| [edX - Introduction to OpenStack](https://www.edx.org/learn/cloud-computing/the-linux-foundation-introduction-to-openstack) | Linux Foundation提供の無料オンラインコース |
| [Udemy - OpenStack Courses](https://www.udemy.com/topic/openstack/)                                                         | Udemy上のOpenStack関連コース（有料）       |

### 📚 ハンズオン環境

| リンク                                                             | 説明                                                   |
| ------------------------------------------------------------------ | ------------------------------------------------------ |
| [DevStack](https://docs.openstack.org/devstack/)                   | 開発・テスト用の自動セットアップツール                 |
| [TryStack](http://trystack.org/)                                   | ブラウザで試せるOpenStack（無料）                      |
| [Katacoda - OpenStack](https://www.katacoda.com/courses/openstack) | ブラウザベースのインタラクティブ学習（一部コンテンツ） |

---

## デプロイメントツール

OpenStackを簡単にデプロイするためのツールです。

### 🚀 主要デプロイメントツール

| ツール                | 説明                                    | リンク                                                                                |
| --------------------- | --------------------------------------- | ------------------------------------------------------------------------------------- |
| **Kolla-Ansible**     | **推奨** - コンテナベース、本番環境向け | [docs.openstack.org/kolla-ansible](https://docs.openstack.org/kolla-ansible/)         |
| **OpenStack-Ansible** | Ansibleベース、Red Hat系で人気          | [docs.openstack.org/openstack-ansible](https://docs.openstack.org/openstack-ansible/) |
| **TripleO**           | OpenStack on OpenStack、Red Hat系       | [docs.openstack.org/tripleo-docs](https://docs.openstack.org/tripleo-docs/)           |
| **DevStack**          | 開発・テスト専用                        | [docs.openstack.org/devstack](https://docs.openstack.org/devstack/)                   |
| **MicroStack**        | Snapベース、小規模環境向け              | [microstack.run](https://microstack.run/)                                             |
| **Sunbeam**           | Juju/Snapベース、Canonicalが開発        | [ubuntu.com/openstack/sunbeam](https://ubuntu.com/openstack/sunbeam)                  |
| **Packstack**         | Red Hat系、簡単セットアップ             | [rdoproject.org/install/packstack](https://www.rdoproject.org/install/packstack/)     |

### 🔄 コンテナオーケストレーション

| ツール             | 説明                          | リンク                                                                  |
| ------------------ | ----------------------------- | ----------------------------------------------------------------------- |
| **Kolla**          | OpenStackコンテナイメージ     | [docs.openstack.org/kolla](https://docs.openstack.org/kolla/)           |
| **OpenStack-Helm** | Kubernetes上でOpenStackを実行 | [openstack-helm.readthedocs.io](https://openstack-helm.readthedocs.io/) |

---

## コミュニティ

質問・情報交換のためのコミュニティリソースです。

### 💬 フォーラム・Q&A

| リンク                                                                             | 説明                                   |
| ---------------------------------------------------------------------------------- | -------------------------------------- |
| [OpenStack Ask](https://ask.openstack.org/)                                        | **公式Q&Aサイト** - 英語での質問・回答 |
| [Stack Overflow - OpenStack](https://stackoverflow.com/questions/tagged/openstack) | プログラミング関連の質問               |

### 📧 メーリングリスト

| リンク                                                                                         | 説明                     |
| ---------------------------------------------------------------------------------------------- | ------------------------ |
| [openstack-discuss](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-discuss)     | 一般的なディスカッション |
| [openstack-operators](http://lists.openstack.org/cgi-bin/mailman/listinfo/openstack-operators) | 運用者向け               |

### 💻 IRC / Slack

| リンク                                                     | 説明                          |
| ---------------------------------------------------------- | ----------------------------- |
| [OFTC IRC](https://oftc.net/)                              | #openstack チャンネル         |
| [OpenInfra Slack](https://openinfra-foundation.slack.com/) | Slackワークスペース（要登録） |

### 🌏 イベント

| イベント                          | 説明                             | リンク                                                                        |
| --------------------------------- | -------------------------------- | ----------------------------------------------------------------------------- |
| **OpenStack Summit**              | 年2回開催の大規模カンファレンス  | [openinfra.dev/summit](https://openinfra.dev/summit/)                         |
| **Project Teams Gathering (PTG)** | 開発者向けイベント               | [openinfra.dev/ptg](https://openinfra.dev/ptg/)                               |
| **OpenStack Days**                | 各国で開催されるローカルイベント | [openstack.org/community/events](https://www.openstack.org/community/events/) |

---

## 日本語リソース

日本語で利用できるリソースです。

### 🇯🇵 日本語ドキュメント・サイト

| リンク                                                        | 説明                                           |
| ------------------------------------------------------------- | ---------------------------------------------- |
| [Server World](https://www.server-world.info/)                | **最強の日本語実践ガイド** - Ubuntu/CentOS対応 |
| [OpenStack日本語ドキュメント](https://docs.openstack.org/ja/) | 公式ドキュメントの日本語翻訳（一部）           |
| [Qiita - OpenStackタグ](https://qiita.com/tags/openstack)     | 日本語の技術記事                               |

### 🏢 日本のコミュニティ

| リンク                                             | 説明                        |
| -------------------------------------------------- | --------------------------- |
| [OpenStack日本ユーザ会](https://openstack.jp/)     | 日本のOpenStackコミュニティ |
| [OpenStack Day Tokyo](https://openstack.jp/event/) | 日本で開催されるイベント    |

### 📰 日本語ブログ・メディア

| リンク                                              | 説明                             |
| --------------------------------------------------- | -------------------------------- |
| [Think IT - OpenStack記事](https://thinkit.co.jp/)  | 技術解説記事                     |
| [さくらのナレッジ](https://knowledge.sakura.ad.jp/) | さくらインターネットの技術ブログ |
| [NTT技術ジャーナル](https://journal.ntt.co.jp/)     | NTTの技術情報                    |

---

## 関連プロジェクト

OpenStackと連携する関連プロジェクト・技術です。

### 🔗 インフラストラクチャ

| プロジェクト     | 説明                                  | リンク                                          |
| ---------------- | ------------------------------------- | ----------------------------------------------- |
| **Ceph**         | 分散ストレージ（OpenStackと相性抜群） | [ceph.io](https://ceph.io/)                     |
| **Open vSwitch** | 仮想スイッチ                          | [openvswitch.org](https://www.openvswitch.org/) |
| **KVM**          | Linuxハイパーバイザー                 | [linux-kvm.org](https://www.linux-kvm.org/)     |
| **libvirt**      | 仮想化管理API                         | [libvirt.org](https://libvirt.org/)             |

### 🧰 管理・自動化ツール

| ツール        | 説明                   | リンク                                    |
| ------------- | ---------------------- | ----------------------------------------- |
| **Ansible**   | 構成管理ツール         | [ansible.com](https://www.ansible.com/)   |
| **Terraform** | Infrastructure as Code | [terraform.io](https://www.terraform.io/) |
| **Packer**    | イメージビルダー       | [packer.io](https://www.packer.io/)       |

### ☁️ クラウドネイティブ

| プロジェクト         | 説明                                | リンク                                                          |
| -------------------- | ----------------------------------- | --------------------------------------------------------------- |
| **Kubernetes**       | コンテナオーケストレーション        | [kubernetes.io](https://kubernetes.io/)                         |
| **KubeVirt**         | Kubernetes上でVMを実行              | [kubevirt.io](https://kubevirt.io/)                             |
| **OpenStack Magnum** | OpenStackでKubernetesクラスタを管理 | [docs.openstack.org/magnum](https://docs.openstack.org/magnum/) |

### 🌐 比較検討

| プロジェクト   | 説明                                 | リンク                                      |
| -------------- | ------------------------------------ | ------------------------------------------- |
| **Proxmox VE** | オープンソース仮想化プラットフォーム | [proxmox.com](https://www.proxmox.com/)     |
| **Harvester**  | Kubernetes上のHCI                    | [harvesterhci.io](https://harvesterhci.io/) |
| **oVirt**      | Red Hat系仮想化管理                  | [ovirt.org](https://www.ovirt.org/)         |

---

## モニタリング・運用ツール

OpenStackの監視・運用に役立つツールです。

### 📊 モニタリング

| ツール         | 説明                          | リンク                                      |
| -------------- | ----------------------------- | ------------------------------------------- |
| **Prometheus** | メトリクス収集・アラート      | [prometheus.io](https://prometheus.io/)     |
| **Grafana**    | メトリクス可視化              | [grafana.com](https://grafana.com/)         |
| **Gnocchi**    | OpenStack時系列データベース   | [gnocchi.osci.io](https://gnocchi.osci.io/) |
| **Monasca**    | OpenStackモニタリングシステム | [monasca.io](https://monasca.io/)           |

### 📋 ロギング

| ツール            | 説明           | リンク                                                  |
| ----------------- | -------------- | ------------------------------------------------------- |
| **Elasticsearch** | ログ検索・分析 | [elastic.co](https://www.elastic.co/)                   |
| **Logstash**      | ログ収集・加工 | [elastic.co/logstash](https://www.elastic.co/logstash/) |
| **Kibana**        | ログ可視化     | [elastic.co/kibana](https://www.elastic.co/kibana/)     |
| **Fluentd**       | ログコレクター | [fluentd.org](https://www.fluentd.org/)                 |

### 🚨 アラート・オンコール

| ツール           | 説明                     | リンク                                                                                 |
| ---------------- | ------------------------ | -------------------------------------------------------------------------------------- |
| **Alertmanager** | Prometheus用アラート管理 | [prometheus.io/alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/) |
| **PagerDuty**    | インシデント管理（商用） | [pagerduty.com](https://www.pagerduty.com/)                                            |
| **Opsgenie**     | インシデント管理（商用） | [atlassian.com/opsgenie](https://www.atlassian.com/software/opsgenie)                  |

---

## ブログ・技術記事

OpenStack関連の有益なブログや記事です。

### 🌟 著名なブログ

| ブログ                                                                              | 説明                  |
| ----------------------------------------------------------------------------------- | --------------------- |
| [RedHat OpenStack Blog](https://www.redhat.com/en/blog/products/openstack-platform) | Red Hatの公式ブログ   |
| [Canonical OpenStack Blog](https://ubuntu.com/blog/tag/openstack)                   | Canonicalの公式ブログ |
| [Mirantis Blog](https://www.mirantis.com/blog/)                                     | Mirantisの技術ブログ  |
| [SUSE OpenStack Blog](https://www.suse.com/c/category/openstack/)                   | SUSEのOpenStack記事   |

### ✍️ 個人ブログ

| ブログ                                              | 説明                                              |
| --------------------------------------------------- | ------------------------------------------------- |
| [ラボブログ](https://labs.cybozu.co.jp/)            | サイボウズ・ラボのブログ（OpenStack関連記事あり） |
| [さくらのナレッジ](https://knowledge.sakura.ad.jp/) | さくらインターネットの技術ブログ                  |

### 📰 ニュース・メディア

| メディア                                                         | 説明                                 |
| ---------------------------------------------------------------- | ------------------------------------ |
| [OpenStack Superuser Magazine](https://superuser.openstack.org/) | 公式のユーザー向けメディア           |
| [The New Stack](https://thenewstack.io/)                         | クラウドネイティブ技術全般のニュース |
| [ZDNet - OpenStack](https://www.zdnet.com/topic/openstack/)      | 技術ニュース                         |

---

## 書籍

OpenStackを学べる書籍です。

### 📖 英語の書籍

| 書籍                                        | 説明                              |
| ------------------------------------------- | --------------------------------- |
| **"OpenStack Operations Guide"**            | 公式の運用ガイドブック（無料PDF） |
| **"Mastering OpenStack"** (Packt)           | 包括的なOpenStack解説書           |
| **"Learning OpenStack Networking"** (Packt) | Neutron深掘り                     |

### 📕 日本語の書籍

| 書籍                              | 説明                                     |
| --------------------------------- | ---------------------------------------- |
| **「OpenStack実践ガイド」**       | 日本語の実践的なガイドブック（やや古い） |
| **「OpenStack構築・運用ガイド」** | 日本オラクルによる解説書                 |

> **注**: OpenStackは進化が早いため、書籍は出版年が古いと内容が陳腐化している可能性があります。最新の公式ドキュメントとの併用を推奨します。

---

## 🔧 便利なツール・スクリプト

OpenStack運用に役立つツールやスクリプト集です。

### 🛠️ CLI拡張

| ツール                     | 説明                        | リンク                                                                                          |
| -------------------------- | --------------------------- | ----------------------------------------------------------------------------------------------- |
| **python-openstackclient** | 統合CLIクライアント         | [docs.openstack.org/python-openstackclient](https://docs.openstack.org/python-openstackclient/) |
| **osc-lib**                | OpenStack CLI拡張ライブラリ | [docs.openstack.org/osc-lib](https://docs.openstack.org/osc-lib/)                               |

### 🐍 Python SDK

| ツール                   | 説明                          | リンク                                                                                      |
| ------------------------ | ----------------------------- | ------------------------------------------------------------------------------------------- |
| **openstacksdk**         | Python用OpenStack SDK         | [docs.openstack.org/openstacksdk](https://docs.openstack.org/openstacksdk/)                 |
| **python-novaclient**    | Nova専用Pythonクライアント    | [docs.openstack.org/python-novaclient](https://docs.openstack.org/python-novaclient/)       |
| **python-neutronclient** | Neutron専用Pythonクライアント | [docs.openstack.org/python-neutronclient](https://docs.openstack.org/python-neutronclient/) |

### 🌐 Web UI

| ツール      | 説明                        | リンク                                                                      |
| ----------- | --------------------------- | --------------------------------------------------------------------------- |
| **Skyline** | 新世代のWebUI（React製）    | [docs.openstack.org/skyline](https://docs.openstack.org/skyline-apiserver/) |
| **Rally**   | OpenStackベンチマークツール | [rally.readthedocs.io](https://rally.readthedocs.io/)                       |

---

## 📱 モバイルアプリ

OpenStackをモバイルから管理するアプリです。

| アプリ                   | プラットフォーム | 説明                               |
| ------------------------ | ---------------- | ---------------------------------- |
| **OpenStack Summit App** | iOS / Android    | OpenStack Summitのスケジュール管理 |

---

## 🎓 資格・認定

OpenStack関連の資格です。

| 資格                                                            | 説明                             | リンク                                                                               |
| --------------------------------------------------------------- | -------------------------------- | ------------------------------------------------------------------------------------ |
| **Certified OpenStack Administrator (COA)**                     | OpenStack Foundation公式認定資格 | [openstack.org/coa](https://www.openstack.org/coa/)                                  |
| **Red Hat Certified System Administrator in Red Hat OpenStack** | Red Hat公式認定                  | [redhat.com/training](https://www.redhat.com/en/services/training-and-certification) |

---

## 🚀 最新情報の入手方法

OpenStackの最新情報をキャッチアップする方法です。

### 📢 公式情報源

| リンク                                                            | 説明         |
| ----------------------------------------------------------------- | ------------ |
| [OpenStack Blog](https://www.openstack.org/blog/)                 | 公式ブログ   |
| [OpenStack Twitter](https://twitter.com/OpenStack)                | 公式Twitter  |
| [OpenStack LinkedIn](https://www.linkedin.com/company/openstack/) | 公式LinkedIn |

### 📅 リリース情報

| リンク                                                                      | 説明                         |
| --------------------------------------------------------------------------- | ---------------------------- |
| [OpenStack Releases](https://releases.openstack.org/)                       | リリーススケジュールとノート |
| [Release Notes](https://releases.openstack.org/teams/release-schedule.html) | 各リリースの詳細情報         |

---

## 🎯 学習ロードマップの参考

OpenStackの学習を進める際の参考ロードマップです。

### レベル別おすすめリソース

#### **初級者（入門）**

1. [Server World](https://www.server-world.info/) で手を動かす
2. [OpenStack First App](https://docs.openstack.org/firstapp/) でアプリを作る
3. [OpenStack YouTube](https://www.youtube.com/@OpenStack) で概念を理解

#### **中級者（実践）**

1. Kolla-Ansibleで本番環境構築を試す
2. 各コンポーネントの公式ドキュメントを読む
3. [OpenStack Ask](https://ask.openstack.org/) で質問・回答する

#### **上級者（深堀り）**

1. ソースコードを読む ([OpenStack Git](https://opendev.org/))
2. コミュニティに貢献する（バグ報告、パッチ送信）
3. [COA資格](https://www.openstack.org/coa/) を取得

---

## 📚 関連ドキュメント

- [Part 1: OpenStack概要と選択肢](01_openstack_overview.md)
- [Part 6: 実践ガイドと構成例](06_practical_guide.md)
- [付録A: 用語集](appendix_a_glossary.md)
- [付録B: トラブルシューティング](appendix_b_troubleshooting.md)

---

**OpenStack学習資料** - Powered by Server World + OpenStack Documentation
**最終更新**: 2025年10月

---

## 🙏 謝辞

この学習資料の作成にあたり、以下のリソースを参考にさせていただきました：

- [Server World](https://www.server-world.info/) - 詳細な実践ガイド
- [OpenStack Official Documentation](https://docs.openstack.org/) - 公式ドキュメント
- OpenStackコミュニティの皆様

OpenStackは世界中の開発者・運用者のコミュニティによって支えられています。このドキュメントが皆様のOpenStack学習の一助となれば幸いです。
