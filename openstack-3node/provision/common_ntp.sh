#!/bin/bash
# NTP（chrony）の設定（全ノード共通）

set -euo pipefail

echo "[ntp] NTP（chrony）の設定中..."
if ! command -v chrony &> /dev/null; then
    apt-get update
    apt-get install -y chrony
fi

# ホスト名に基づいてchrony設定を分岐
HOSTNAME=$(hostname)
if [ "$HOSTNAME" = "controller" ]; then
    # コントローラノード: NTPサーバーとして動作
    cat > /etc/chrony/chrony.conf <<EOF
pool ntp.ubuntu.com        iburst maxsources 4
pool 0.ubuntu.pool.ntp.org iburst maxsources 1
pool 1.ubuntu.pool.ntp.org iburst maxsources 1
pool 2.ubuntu.pool.ntp.org iburst maxsources 2

# ローカルネットワークからの時刻同期を許可
allow 172.16.100.0/24

# その他の設定
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
EOF
    echo "✓ コントローラノードとしてchronyを設定しました"
else
    # その他のノード: コントローラを参照
    cat > /etc/chrony/chrony.conf <<EOF
server controller iburst
pool ntp.ubuntu.com        iburst maxsources 2
pool 0.ubuntu.pool.ntp.org iburst maxsources 1

# その他の設定
keyfile /etc/chrony/chrony.keys
driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
EOF
    echo "✓ クライアントノードとしてchronyを設定しました"
fi

# chronyサービスの起動
systemctl enable chrony
systemctl restart chrony

# サービスが正常に起動したことを確認
sleep 3
if systemctl is-active --quiet chrony; then
    echo "✓ chronyサービスが正常に起動しました"
else
    echo "⚠ chronyサービスの起動に問題があります"
    systemctl status chrony || true
    exit 1
fi

# chronyの同期状態を確認（NTPサーバーへの接続には時間がかかるため、失敗しても続行）
# 最大3回までリトライ
for i in {1..3}; do
    if chronyc sources -v > /dev/null 2>&1; then
        echo "✓ chronyが正常に動作しています"
        break
    fi
    if [ $i -lt 3 ]; then
        sleep 2
    else
        echo "⚠ chronyの同期状態を確認できませんでした（NTPサーバーへの接続に時間がかかっている可能性があります）"
    fi
done
