#!/bin/bash
# RabbitMQのインストールと設定（コントローラノード専用）

set -euo pipefail

# パスワード設定（環境変数から取得、デフォルト値あり）
RABBITMQ_PASSWORD=${RABBITMQ_PASSWORD:-"rabbitmq123"}

echo "[rabbitmq] RabbitMQのインストールと設定中..."
if ! command -v rabbitmqctl &> /dev/null; then
    apt-get install -y rabbitmq-server

    # RabbitMQサービスの起動
    systemctl enable rabbitmq-server
    systemctl start rabbitmq-server

    # openstackユーザーの作成
    rabbitmqctl add_user openstack "${RABBITMQ_PASSWORD}" || true
    rabbitmqctl set_permissions openstack ".*" ".*" ".*"
    rabbitmqctl set_user_tags openstack administrator

    echo "✓ RabbitMQをインストール・設定しました"
else
    echo "✓ RabbitMQは既にインストール済みです"
    # 既存環境でもユーザーが存在するか確認
    if ! rabbitmqctl list_users | grep -q openstack; then
        rabbitmqctl add_user openstack "${RABBITMQ_PASSWORD}" || true
        rabbitmqctl set_permissions openstack ".*" ".*" ".*"
        rabbitmqctl set_user_tags openstack administrator
    fi
fi

systemctl is-active --quiet rabbitmq-server && echo "✓ RabbitMQが動作中"
