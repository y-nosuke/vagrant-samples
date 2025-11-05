#!/bin/bash
# Apache設定（コントローラノード専用）

set -euo pipefail

echo "[keystone-apache] Apache設定中..."

# SSL証明書の確認と作成（自己署名証明書）
SSL_CERT_FILE=""
SSL_KEY_FILE=""
SSL_CHAIN_FILE=""

# Let's Encrypt証明書の確認
if [ -f /etc/letsencrypt/live/controller/cert.pem ] && [ -f /etc/letsencrypt/live/controller/privkey.pem ]; then
    SSL_CERT_FILE="/etc/letsencrypt/live/controller/cert.pem"
    SSL_KEY_FILE="/etc/letsencrypt/live/controller/privkey.pem"
    SSL_CHAIN_FILE="/etc/letsencrypt/live/controller/chain.pem"
    echo "[keystone-apache] Let's Encrypt証明書を検出しました"
elif [ -f /etc/letsencrypt/live/$(hostname)/cert.pem ] && [ -f /etc/letsencrypt/live/$(hostname)/privkey.pem ]; then
    HOSTNAME=$(hostname)
    SSL_CERT_FILE="/etc/letsencrypt/live/${HOSTNAME}/cert.pem"
    SSL_KEY_FILE="/etc/letsencrypt/live/${HOSTNAME}/privkey.pem"
    SSL_CHAIN_FILE="/etc/letsencrypt/live/${HOSTNAME}/chain.pem"
    echo "[keystone-apache] Let's Encrypt証明書を検出しました（ホスト名: ${HOSTNAME}）"
else
    # 自己署名証明書を作成
    echo "[keystone-apache] 自己署名証明書を作成中..."
    mkdir -p /etc/ssl/certs/keystone
    mkdir -p /etc/ssl/private/keystone
    
    if [ ! -f /etc/ssl/certs/keystone/keystone-cert.pem ] || [ ! -f /etc/ssl/private/keystone/keystone-key.pem ]; then
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
          -keyout /etc/ssl/private/keystone/keystone-key.pem \
          -out /etc/ssl/certs/keystone/keystone-cert.pem \
          -subj "/C=JP/ST=State/L=City/O=Organization/CN=controller" 2>/dev/null || true
        
        chmod 600 /etc/ssl/private/keystone/keystone-key.pem
        chmod 644 /etc/ssl/certs/keystone/keystone-cert.pem
        echo "[keystone-apache] 自己署名証明書を作成しました"
    else
        echo "[keystone-apache] 自己署名証明書は既に存在します"
    fi
    
    SSL_CERT_FILE="/etc/ssl/certs/keystone/keystone-cert.pem"
    SSL_KEY_FILE="/etc/ssl/private/keystone/keystone-key.pem"
fi

if [ ! -f /etc/apache2/sites-available/keystone.conf.backup ]; then
    mv /etc/apache2/sites-available/keystone.conf /etc/apache2/sites-available/keystone.conf.backup 2>/dev/null || true
fi

# Apache設定ファイルの作成
if [ -n "$SSL_CERT_FILE" ] && [ -n "$SSL_KEY_FILE" ]; then
    # SSL設定を含むApache設定
    if [ -n "$SSL_CHAIN_FILE" ] && [ -f "$SSL_CHAIN_FILE" ]; then
        # Let's Encrypt証明書（チェーンファイルあり）
        cat > /etc/apache2/sites-available/keystone.conf <<EOF
Listen 5000

<VirtualHost *:5000>
    SSLEngine on
    SSLHonorCipherOrder on
    SSLCertificateFile ${SSL_CERT_FILE}
    SSLCertificateKeyFile ${SSL_KEY_FILE}
    SSLCertificateChainFile ${SSL_CHAIN_FILE}

    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>

    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
EOF
    else
        # 自己署名証明書（チェーンファイルなし）
        cat > /etc/apache2/sites-available/keystone.conf <<EOF
Listen 5000

<VirtualHost *:5000>
    SSLEngine on
    SSLHonorCipherOrder on
    SSLCertificateFile ${SSL_CERT_FILE}
    SSLCertificateKeyFile ${SSL_KEY_FILE}

    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>

    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
EOF
    fi
else
    echo "[keystone-apache] 警告: SSL証明書が見つかりません。HTTP設定を使用します（非推奨）"
    # HTTP設定（フォールバック）
    cat > /etc/apache2/sites-available/keystone.conf <<EOF
Listen 5000

<VirtualHost *:5000>
    WSGIScriptAlias / /usr/bin/keystone-wsgi-public
    WSGIDaemonProcess keystone-public processes=5 threads=1 user=keystone group=keystone display-name=%{GROUP}
    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
    LimitRequestBody 114688

    <IfVersion >= 2.4>
      ErrorLogFormat "%{cu}t %M"
    </IfVersion>

    ErrorLog /var/log/apache2/keystone.log
    CustomLog /var/log/apache2/keystone_access.log combined

    <Directory /usr/bin>
        <IfVersion >= 2.4>
            Require all granted
        </IfVersion>
        <IfVersion < 2.4>
            Order allow,deny
            Allow from all
        </IfVersion>
    </Directory>
</VirtualHost>

Alias /identity /usr/bin/keystone-wsgi-public
<Location /identity>
    SetHandler wsgi-script
    Options +ExecCGI

    WSGIProcessGroup keystone-public
    WSGIApplicationGroup %{GLOBAL}
    WSGIPassAuthorization On
</Location>
EOF
fi

# SSLモジュールの有効化（SSL証明書がある場合）
if [ -n "$SSL_CERT_FILE" ] && [ -f "$SSL_CERT_FILE" ]; then
    a2enmod ssl 2>/dev/null || true
fi

# WSGIモジュールの有効化
a2enmod wsgi
a2ensite keystone

# Apacheサービスの起動
systemctl enable apache2
systemctl restart apache2
echo "✓ Apache設定を完了しました"

sleep 2
systemctl is-active --quiet apache2 && echo "✓ Apacheが動作中"
ss -tlnp | grep :5000 > /dev/null && echo "✓ Keystone APIがポート5000でリスニング中"
