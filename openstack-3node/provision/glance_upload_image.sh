#!/bin/bash
# テストイメージのアップロード（オプション）

set -euo pipefail

# 環境変数の設定
IMAGE_DIR="${HOME}/images"
UBUNTU_IMAGE_NAME="Ubuntu-24.04"
UBUNTU_IMAGE_FILE="noble-server-cloudimg-amd64.img"
UBUNTU_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/${UBUNTU_IMAGE_FILE}"
CIRROS_IMAGE_NAME="Cirros-0.6.2"
CIRROS_IMAGE_FILE="cirros-0.6.2-x86_64-disk.img"
CIRROS_IMAGE_URL="https://download.cirros-cloud.net/0.6.2/${CIRROS_IMAGE_FILE}"

echo "[glance-upload-image] テストイメージのアップロード中..."

# admin-openrcの確認
if [ ! -f ~/admin-openrc ]; then
    echo "× エラー: ~/admin-openrc が見つかりません"
    echo "  Phase 3 (Keystone) を先に完了させてください"
    exit 1
fi

# 環境変数の読み込み
source ~/admin-openrc

# イメージディレクトリの作成
if [ ! -d "${IMAGE_DIR}" ]; then
    echo "  イメージディレクトリを作成中..."
    mkdir -p "${IMAGE_DIR}"
    echo "✓ イメージディレクトリを作成しました: ${IMAGE_DIR}"
fi

# Ubuntu 24.04 イメージの処理
echo ""
echo "=== Ubuntu 24.04 イメージ ==="

# Ubuntu イメージがGlanceに既に存在するか確認
if openstack image show "${UBUNTU_IMAGE_NAME}" >/dev/null 2>&1; then
    echo "✓ ${UBUNTU_IMAGE_NAME}は既にGlanceに登録されています"
else
    # Ubuntu イメージのダウンロード
    if [ -f "${IMAGE_DIR}/${UBUNTU_IMAGE_FILE}" ]; then
        echo "✓ ${UBUNTU_IMAGE_FILE}は既にダウンロード済みです"
    else
        echo "  ${UBUNTU_IMAGE_FILE}をダウンロード中（約500MB、数分かかります）..."
        wget -q --show-progress -O "${IMAGE_DIR}/${UBUNTU_IMAGE_FILE}" "${UBUNTU_IMAGE_URL}"
        echo "✓ ${UBUNTU_IMAGE_FILE}をダウンロードしました"
    fi

    # ファイルサイズの確認
    echo "  ファイルサイズ: $(du -h "${IMAGE_DIR}/${UBUNTU_IMAGE_FILE}" | cut -f1)"

    # Glanceへの登録
    echo "  ${UBUNTU_IMAGE_NAME}をGlanceに登録中..."
    openstack image create "${UBUNTU_IMAGE_NAME}" \
        --file "${IMAGE_DIR}/${UBUNTU_IMAGE_FILE}" \
        --disk-format qcow2 \
        --container-format bare \
        --public
    echo "✓ ${UBUNTU_IMAGE_NAME}をGlanceに登録しました"
fi

# Ubuntu イメージの詳細表示
echo "  イメージの詳細:"
openstack image show "${UBUNTU_IMAGE_NAME}" -f value -c id -c name -c status -c size | \
    awk '{printf "    ID: %s\n    Name: %s\n    Status: %s\n    Size: %.2f MB\n", $1, $2, $3, $4/1024/1024}'

# Cirros イメージの処理（オプション）
echo ""
echo "=== Cirros イメージ（軽量テスト用・オプション） ==="

# Cirros イメージがGlanceに既に存在するか確認
if openstack image show "${CIRROS_IMAGE_NAME}" >/dev/null 2>&1; then
    echo "✓ ${CIRROS_IMAGE_NAME}は既にGlanceに登録されています"
else
    # Cirros イメージのダウンロード
    if [ -f "${IMAGE_DIR}/${CIRROS_IMAGE_FILE}" ]; then
        echo "✓ ${CIRROS_IMAGE_FILE}は既にダウンロード済みです"
    else
        echo "  ${CIRROS_IMAGE_FILE}をダウンロード中（約13MB）..."
        wget -q --show-progress -O "${IMAGE_DIR}/${CIRROS_IMAGE_FILE}" "${CIRROS_IMAGE_URL}"
        echo "✓ ${CIRROS_IMAGE_FILE}をダウンロードしました"
    fi

    # ファイルサイズの確認
    echo "  ファイルサイズ: $(du -h "${IMAGE_DIR}/${CIRROS_IMAGE_FILE}" | cut -f1)"

    # Glanceへの登録
    echo "  ${CIRROS_IMAGE_NAME}をGlanceに登録中..."
    openstack image create "${CIRROS_IMAGE_NAME}" \
        --file "${IMAGE_DIR}/${CIRROS_IMAGE_FILE}" \
        --disk-format qcow2 \
        --container-format bare \
        --public
    echo "✓ ${CIRROS_IMAGE_NAME}をGlanceに登録しました"
fi

# Cirros イメージの詳細表示
echo "  イメージの詳細:"
openstack image show "${CIRROS_IMAGE_NAME}" -f value -c id -c name -c status -c size | \
    awk '{printf "    ID: %s\n    Name: %s\n    Status: %s\n    Size: %.2f MB\n", $1, $2, $3, $4/1024/1024}'

# 登録されているイメージの一覧
echo ""
echo "=== 登録済みイメージ一覧 ==="
openstack image list

# イメージファイルの保存場所確認
echo ""
echo "=== イメージファイルの保存場所 ==="
echo "  保存先: /var/lib/glance/images/"
sudo ls -lh /var/lib/glance/images/ | tail -n +2 | \
    awk '{printf "    %s %10s %s\n", $9, $5, $6 " " $7 " " $8}'

# ディスク使用量
DISK_USAGE=$(sudo du -sh /var/lib/glance/images/ | cut -f1)
echo "  ディスク使用量: ${DISK_USAGE}"

echo ""
echo "[glance-upload-image] 完了"
