# Appendix A: 用語集

## 📋 目次

- [Appendix A: 用語集](#appendix-a-用語集)
  - [📋 目次](#-目次)
  - [🎯 このドキュメントについて](#-このドキュメントについて)
  - [A](#a)
  - [B-C](#b-c)
  - [D](#d)
  - [F-G](#f-g)
  - [H-K](#h-k)
  - [L](#l)
  - [N-O](#n-o)
  - [P](#p)
  - [R-S](#r-s)
  - [T-Z](#t-z)

---

## 🎯 このドキュメントについて

ドメイン管理に関連する重要な用語をアルファベット順にまとめています。

---

## A

**ACL (Access Control List)**

- アクセス制御リスト
- ファイルやオブジェクトに対するアクセス権限のリスト
- 誰がどのような操作（読み取り、書き込み、削除等）を実行できるかを定義

**Active Directory (AD)**

- Microsoftが開発したディレクトリサービス
- Windows Server上で動作し、Windows環境の中核管理基盤
- ユーザー、グループ、コンピューターを集中管理

**AD CS (Active Directory Certificate Services)**

- Active Directory証明書サービス
- 内部CAとして証明書を発行・管理
- SSL/TLS証明書、ユーザー証明書などを発行

**AD DS (Active Directory Domain Services)**

- Active Directoryドメインサービス
- Active Directoryの中核機能
- LDAP、Kerberos、DNSを統合

**AD FS (Active Directory Federation Services)**

- Active Directoryフェデレーションサービス
- SAML、WS-Federationによる外部組織との認証連携
- シングルサインオン（SSO）を実現

**AGDLP**

- Account → Global Group → Domain Local Group → Permission
- Active Directoryのグループ設計戦略
- スケーラブルで管理しやすい権限管理

**Attribute (属性)**

- LDAPオブジェクトが持つ情報の項目
- 例: cn（名前）、mail（メール）、telephoneNumber（電話番号）

**Authentication (認証)**

- ユーザーが本人であることを確認するプロセス
- パスワード、証明書、生体認証などで実施

**Authorization (認可)**

- 認証されたユーザーが何にアクセスできるかを決定
- ACL、グループメンバーシップで制御

---

## B-C

**Backup (バックアップ)**

- データやシステムの複製を作成すること
- ディザスタリカバリ、データ保護のために必須

**BIND**

- オープンソースのDNSサーバー実装
- FreeIPAで使用

**CA (Certificate Authority / 認証局)**

- デジタル証明書を発行・管理する機関
- FreeIPAではDogtag CAを統合

**CN (Common Name)**

- LDAPの識別子の一つ
- 例: `CN=John Doe`
- ユーザー、グループ、コンピューターの名前

**CNAME (Canonical Name)**

- DNSのエイリアスレコード
- ホスト名の別名を定義
- 例: `www` → `web-server01.lab.local`

**Container (コンテナ)**

- LDAPツリーの入れ物
- OUより単純な構造
- 例: `CN=Users`, `CN=Computers`

**CSE (Client-Side Extension)**

- グループポリシーのクライアント側拡張機能
- GPOの各機能を実装するモジュール

---

## D

**DC (Domain Controller / ドメインコントローラー)**

- Active Directoryサービスを提供するサーバー
- 認証、ディレクトリサービス、GPO配布を担当

**DC (Domain Component)**

- LDAPのドメイン構成要素
- 例: `DC=lab,DC=local` は `lab.local` ドメインを表す

**DFS (Distributed File System)**

- 分散ファイルシステム
- 複数のファイルサーバーを統合して管理

**DHCP (Dynamic Host Configuration Protocol)**

- IPアドレスを自動割り当てするプロトコル
- クライアントに動的にネットワーク設定を提供

**Directory (ディレクトリ)**

- 情報を階層構造で保存するデータベース
- LDAPで管理

**DN (Distinguished Name)**

- LDAPオブジェクトの一意な識別子
- ツリー内の位置を完全に表す
- 例: `CN=John Doe,OU=IT,DC=lab,DC=local`

**DNS (Domain Name System)**

- ホスト名とIPアドレスを対応付けるシステム
- ドメイン管理では、サービスの発見（SRVレコード）にも使用

**Dogtag CA**

- Red Hatが開発したオープンソースのCA
- FreeIPAに統合され、証明書を自動発行

**Domain (ドメイン)**

- セキュリティ境界と管理の基本単位
- 共通のディレクトリデータベースを持つ
- 例: `lab.local`

**Dynamic DNS (動的DNS)**

- クライアントが自動的にDNSレコードを更新する仕組み
- DHCPと連携してIPアドレス変更に対応

---

## F-G

**Forest (フォレスト)**

- 複数のドメインツリーを含む最上位の管理境界
- 共通のスキーマ、グローバルカタログを持つ

**FreeIPA**

- Red Hatが開発したLinux統合ID管理システム
- 389DS、MIT Kerberos、Dogtag CA、BINDを統合

**FSMO (Flexible Single Master Operations)**

- 特定のDCが担当する5つの特別な役割
- Schema Master、Domain Naming Master、RID Master、PDC Emulator、Infrastructure Master

**GC (Global Catalog / グローバルカタログ)**

- フォレスト内の全オブジェクトの部分的なコピー
- クロスドメイン検索を高速化

**GPO (Group Policy Object / グループポリシーオブジェクト)**

- Windows クライアントに設定を配布する仕組み
- デスクトップ設定、セキュリティポリシー、ソフトウェアインストールなど

**Group (グループ)**

- 複数のユーザーやコンピューターをまとめたもの
- アクセス権限の管理を簡素化

---

## H-K

**HBAC (Host-Based Access Control)**

- FreeIPAのホストベースアクセス制御
- どのユーザーがどのホストにアクセスできるかを制御

**HBAC Rule (HBACルール)**

- HBACの設定単位
- Who（誰が）、Accessing What（どこに）、Via Which Service（どのサービスで）を定義

**Host (ホスト)**

- ネットワークに接続されたコンピューター
- サーバー、クライアントを含む

**Hostgroup (ホストグループ)**

- 複数のホストをまとめたもの
- FreeIPAでアクセス制御を簡素化

**Kerberos**

- チケットベースの認証プロトコル
- パスワードをネットワークに流さず、シングルサインオン（SSO）を実現

**KDC (Key Distribution Center)**

- Kerberos認証サーバー
- TGTとサービスチケットを発行

---

## L

**LDAP (Lightweight Directory Access Protocol)**

- ディレクトリサービスにアクセスするプロトコル
- 階層構造でデータを管理
- Active DirectoryとFreeIPAの基盤

**LDIF (LDAP Data Interchange Format)**

- LDAPデータを表現するテキスト形式
- データのインポート・エクスポートに使用

**LDAPS**

- LDAP over SSL/TLS
- 暗号化されたLDAP通信
- ポート636を使用

---

## N-O

**Namespace (名前空間)**

- ドメイン名の階層構造
- 例: `lab.local` は `local` 配下の `lab`

**NTLM (NT LAN Manager)**

- Windowsのレガシー認証プロトコル
- 後方互換性のために残存

**Object (オブジェクト)**

- LDAPディレクトリに保存される個々のエントリ
- ユーザー、グループ、コンピューターなど

**ObjectClass (オブジェクトクラス)**

- LDAPオブジェクトの種類を定義
- 例: `user`, `group`, `computer`

**OIDC (OpenID Connect)**

- OAuth 2.0ベースの認証プロトコル
- Web認証、API認証で使用

**OU (Organizational Unit / 組織単位)**

- Active Directoryでオブジェクトをグループ化する単位
- GPOの適用単位、管理権限の委任単位

**OTP (One-Time Password / ワンタイムパスワード)**

- 1回限り有効なパスワード
- 2要素認証（2FA）で使用

---

## P

**PAM (Pluggable Authentication Modules)**

- Linux の認証フレームワーク
- 様々な認証方式を統合

**Password Policy (パスワードポリシー)**

- パスワードの要件を定義
- 最小文字数、複雑さ、有効期限など

**PDC (Primary Domain Controller)**

- NT4ドメインの主ドメインコントローラー
- Active DirectoryではPDC Emulatorとして機能継続

**PDC Emulator**

- FSMO役割の一つ
- 時刻同期のマスター、パスワード変更の優先処理

**Permission (権限)**

- ユーザーが実行できる操作
- 読み取り、書き込み、削除、実行など

**PowerShell**

- Windowsのスクリプト言語とシェル
- Active Directory管理の自動化に使用

**Principal (プリンシパル)**

- Kerberosで識別されるエンティティ
- ユーザー、サービスを表す
- 例: `jdoe@LAB.LOCAL`

**PTR Record**

- DNSの逆引きレコード
- IPアドレスからホスト名を解決
- 例: `10.0.20.172.in-addr.arpa` → `dc.lab.local`

---

## R-S

**Realm (レルム)**

- Kerberosドメイン
- 通常、ドメイン名を大文字にしたもの
- 例: `LAB.LOCAL`

**Replication (レプリケーション)**

- 複数のDC間でデータを同期
- 高可用性、負荷分散を実現

**RID (Relative Identifier)**

- ドメイン内でオブジェクトを一意に識別する番号
- SID（Security Identifier）の一部

**RODC (Read-Only Domain Controller)**

- 読み取り専用のドメインコントローラー
- 支社など物理的セキュリティが低い場所に配置

**RSAT (Remote Server Administration Tools)**

- Windows PCからサーバーを管理するツール群
- Active Directory管理ツールを含む

**Samba**

- SMB/CIFSプロトコルのオープンソース実装
- Samba4でActive Directoryドメインコントローラー機能を提供

**Schema (スキーマ)**

- LDAPディレクトリのオブジェクトと属性の定義
- どのような情報を保存できるかを規定

**Security Group (セキュリティグループ)**

- アクセス権限の管理に使用するグループ
- ファイル、フォルダー、アプリケーションのアクセス制御

**SELinux (Security-Enhanced Linux)**

- Linuxのセキュリティ機能
- 強制アクセス制御（MAC）を提供

**Service Principal Name (SPN)**

- Kerberosでサービスを識別する名前
- 例: `HTTP/web.lab.local@LAB.LOCAL`

**SID (Security Identifier)**

- Windowsでオブジェクトを一意に識別する番号
- 例: `S-1-5-21-...`

**Site (サイト)**

- Active Directoryの物理的な場所
- レプリケーション、クライアント認証の最適化に使用

**SMB (Server Message Block)**

- Windowsファイル共有プロトコル
- CIFS（Common Internet File System）とも呼ばれる

**SRV Record**

- DNSのサービスレコード
- サービスの場所（ホスト名、ポート）を定義
- 例: `_ldap._tcp.lab.local` → `dc.lab.local:389`

**SSO (Single Sign-On / シングルサインオン)**

- 一度の認証で複数のサービスにアクセスできる仕組み
- Kerberosで実現

**SSSD (System Security Services Daemon)**

- Linux のクライアント側認証デーモン
- FreeIPAとクライアント間のブリッジ

**SUDO**

- Linuxで一時的に管理者権限を得るコマンド
- 特権コマンドの実行に使用

**SUDO Rules**

- FreeIPAでsudoコマンドの実行権限を集中管理
- 誰が、どのホストで、どのコマンドを実行できるかを定義

---

## T-Z

**TGT (Ticket Granting Ticket)**

- Kerberosの初期認証チケット
- 他のサービスチケットを取得するために使用

**Ticket (チケット)**

- Kerberos認証で使用される暗号化されたトークン
- TGT、サービスチケットの2種類

**Tree (ツリー)**

- LDAPの階層構造
- ルートから枝分かれして各オブジェクトに到達

**Trust (トラスト)**

- 異なるドメイン間の信頼関係
- クロスドメイン認証を可能にする

**UPN (User Principal Name)**

- ユーザーのログイン名（メール形式）
- 例: `jdoe@lab.local`

**User (ユーザー)**

- システムにアクセスする個人
- アカウント、パスワード、属性を持つ

**Vagrant**

- 仮想マシンの構築・管理ツール
- Vagrantfileで環境を定義

**VirtualBox**

- オープンソースの仮想化ソフトウェア
- 仮想マシンを作成・実行

**Zone (ゾーン)**

- DNSのドメイン管理単位
- 正引きゾーン（ホスト名→IP）と逆引きゾーン（IP→ホスト名）

---

**作成日**: 2025年11月2日
**対象**: ドメイン管理学習者
**次のドキュメント**: appendix_b_troubleshooting.md
