#!/bin/bash
###############################################################################
# STX-NovaNetX Inbound Config Generator
# Generates CDN WS, Multi-SNI XTLS-Vision, REALITY, and Trojan gRPC inbounds for 3x-ui
###############################################################################

[[ $EUID -ne 0 ]] && { echo "Error: Must be run as root!"; exit 1; }

XUIDB="/etc/x-ui/x-ui.db"
OUTPUT_FILE="/etc/x-ui-pro/generated-links.txt"
mkdir -p /etc/x-ui-pro/ssl

DOMAIN="${1:-vpn.shanutechx.com}"
CF_IP="${2:-172.66.40.229}"

msg()     { echo -e "\e[1;37;40m $1 \e[0m"; }
msg_ok()  { echo -e "\e[1;32;40m $1 \e[0m"; }
msg_inf() { echo -e "\e[1;36;40m $1 \e[0m"; }
msg_war() { echo -e "\e[1;33;40m $1 \e[0m"; }

gen_uuid() {
    if command -v xray &>/dev/null; then
        xray uuid 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null
    else
        cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "$(openssl rand -hex 4)-$(openssl rand -hex 2)-4$(openssl rand -hex 1 | cut -c2-)-a$(openssl rand -hex 1 | cut -c2-)-$(openssl rand -hex 6)"
    fi
}

echo ""
msg_inf "============================================================"
msg_inf "   STX-NovaNetX Inbound & Config Generator Automated Setup  "
msg_inf "============================================================"
echo ""

# SSL Certificate Check & Self-Signed Fallback
CERT_FILE="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
KEY_FILE="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

if [[ ! -f "$CERT_FILE" ]]; then
    MAIN_DOMAIN=$(echo "$DOMAIN" | sed 's/.*\.\([^.]*\..*\)$/\1/')
    CERT_FILE="/etc/letsencrypt/live/${MAIN_DOMAIN}/fullchain.pem"
    KEY_FILE="/etc/letsencrypt/live/${MAIN_DOMAIN}/privkey.pem"
fi

if [[ ! -f "$CERT_FILE" ]]; then
    CERT_FILE="/etc/x-ui-pro/ssl/fullchain.pem"
    KEY_FILE="/etc/x-ui-pro/ssl/privkey.pem"
    if [[ ! -f "$CERT_FILE" ]]; then
        msg_war "Generating self-signed SSL fallback certificates..."
        openssl req -x509 -newkey rsa:2048 -nodes -keyout "$KEY_FILE" -out "$CERT_FILE" -days 3650 -subj "/CN=${DOMAIN}" >/dev/null 2>&1
    fi
fi

# List of target decoy SNIs for XTLS-Vision on Port 443
SNI_LIST=("zoom.us" "m.zoom.us" "tiktok.com" "netflix.com" "youtube.com" "m.youtube.com" "aka.ms")

# Stop x-ui before database insertion to prevent SQLite lock
if systemctl is-active --quiet x-ui; then
    x-ui stop >/dev/null 2>&1
fi

LINKS=()

# 1. Generate CDN WebSocket Inbound (Port 8443)
CDN_UUID=$(gen_uuid)
CDN_REMARK="STX-NovaNetX-CDN"

CDN_SETTINGS=$(cat <<EOF
{
  "clients": [
    {
      "id": "${CDN_UUID}",
      "flow": "",
      "email": "stx_cdn_client",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": "",
      "subId": ""
    }
  ],
  "decryption": "none",
  "fallbacks": []
}
EOF
)

CDN_STREAM=$(cat <<EOF
{
  "network": "ws",
  "security": "tls",
  "externalProxy": [],
  "tlsSettings": {
    "serverName": "${DOMAIN}",
    "minVersion": "1.2",
    "maxVersion": "1.3",
    "cipherSuites": "",
    "certificates": [
      {
        "certificateFile": "${CERT_FILE}",
        "keyFile": "${KEY_FILE}",
        "oneTimeLoading": false
      }
    ],
    "alpn": ["http/1.1"],
    "settings": {
      "allowInsecure": false,
      "fingerprint": "chrome"
    }
  },
  "wsSettings": {
    "acceptProxyProtocol": false,
    "path": "/",
    "headers": {
      "Host": "${DOMAIN}"
    }
  }
}
EOF
)

CDN_SNIFFING='{"enabled":true,"destOverride":["http","tls","quic"]}'

if [[ -f "$XUIDB" ]]; then
    sqlite3 "$XUIDB" <<EOF
DELETE FROM inbounds WHERE remark='${CDN_REMARK}' OR port=8443;
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing)
VALUES (0, 0, 0, 0, '${CDN_REMARK}', 1, 0, '', 8443, 'vless', '${CDN_SETTINGS}', '${CDN_STREAM}', 'inbound-8443', '${CDN_SNIFFING}');
EOF
fi

CDN_LINK="vless://${CDN_UUID}@${CF_IP}:8443/?encryption=none&flow=none&security=tls&fp=chrome&sni=${DOMAIN}&type=ws&host=${DOMAIN}&headerType=none&path=%2f#${CDN_REMARK}"
LINKS+=("$CDN_LINK")

# 2. Generate Multi-SNI XTLS-Vision TCP Inbounds (Port 443)
CLIENTS_JSON=""
CERTS_JSON=""

for i in "${!SNI_LIST[@]}"; do
    SNI="${SNI_LIST[$i]}"
    U_UUID=$(gen_uuid)
    U_REMARK="STX-NovaNetX-${SNI}-443"

    LINK="vless://${U_UUID}@${DOMAIN}:443/?encryption=none&flow=xtls-rprx-vision&security=tls&fp=chrome&sni=${SNI}&type=tcp&headerType=none#${U_REMARK}"
    LINKS+=("$LINK")

    CLIENT_ENTRY=$(cat <<EOF
    {
      "id": "${U_UUID}",
      "flow": "xtls-rprx-vision",
      "email": "stx_${SNI//./_}",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true,
      "tgId": "",
      "subId": ""
    }
EOF
    )

    if [[ -z "$CLIENTS_JSON" ]]; then
        CLIENTS_JSON="$CLIENT_ENTRY"
    else
        CLIENTS_JSON="${CLIENTS_JSON},${CLIENT_ENTRY}"
    fi

    CERT_ENTRY=$(cat <<EOF
    {
      "certificateFile": "${CERT_FILE}",
      "keyFile": "${KEY_FILE}",
      "oneTimeLoading": false,
      "buildChain": true
    }
EOF
    )

    if [[ -z "$CERTS_JSON" ]]; then
        CERTS_JSON="$CERT_ENTRY"
    else
        CERTS_JSON="${CERTS_JSON},${CERT_ENTRY}"
    fi
done

VISION_REMARK="STX-NovaNetX-MultiSNI-443"
VISION_SETTINGS="{ \"clients\": [ ${CLIENTS_JSON} ], \"decryption\": \"none\", \"fallbacks\": [] }"
VISION_STREAM=$(cat <<EOF
{
  "network": "tcp",
  "security": "tls",
  "externalProxy": [],
  "tlsSettings": {
    "serverName": "${DOMAIN}",
    "minVersion": "1.2",
    "maxVersion": "1.3",
    "cipherSuites": "",
    "certificates": [ ${CERTS_JSON} ],
    "alpn": ["h2", "http/1.1"],
    "settings": {
      "allowInsecure": false,
      "fingerprint": "chrome"
    }
  },
  "tcpSettings": {
    "acceptProxyProtocol": false,
    "header": {
      "type": "none"
    }
  }
}
EOF
)

if [[ -f "$XUIDB" ]]; then
    sqlite3 "$XUIDB" <<EOF
DELETE FROM inbounds WHERE remark='${VISION_REMARK}' OR port=443;
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing)
VALUES (0, 0, 0, 0, '${VISION_REMARK}', 1, 0, '', 443, 'vless', '${VISION_SETTINGS}', '${VISION_STREAM}', 'inbound-443', '${CDN_SNIFFING}');
EOF
fi

# 3. Generate REALITY Inbound (Port 2096)
REALITY_UUID=$(gen_uuid)
REALITY_REMARK="STX-NovaNetX-REALITY"
KEYPAIR=""
if command -v /usr/local/x-ui/bin/xray-linux-amd64 &>/dev/null; then
    KEYPAIR=$(/usr/local/x-ui/bin/xray-linux-amd64 x25519 2>/dev/null)
elif command -v xray &>/dev/null; then
    KEYPAIR=$(xray x25519 2>/dev/null)
fi

PRIV_KEY=$(echo "$KEYPAIR" | grep -i "Private key:" | awk '{print $3}')
PUB_KEY=$(echo "$KEYPAIR" | grep -i "Public key:" | awk '{print $3}')
[[ -z "$PRIV_KEY" ]] && PRIV_KEY="aBB11223344556677889900aabbccddeeff11223344="
[[ -z "$PUB_KEY" ]] && PUB_KEY="cCC11223344556677889900aabbccddeeff11223344="
SHORT_ID=$(openssl rand -hex 8 2>/dev/null || echo "1234567890abcdef")

REALITY_SETTINGS=$(cat <<EOF
{
  "clients": [
    {
      "id": "${REALITY_UUID}",
      "flow": "xtls-rprx-vision",
      "email": "stx_reality_client",
      "limitIp": 0,
      "totalGB": 0,
      "expiryTime": 0,
      "enable": true
    }
  ],
  "decryption": "none",
  "fallbacks": []
}
EOF
)

REALITY_STREAM=$(cat <<EOF
{
  "network": "tcp",
  "security": "reality",
  "externalProxy": [],
  "realitySettings": {
    "show": false,
    "xver": 0,
    "dest": "zoom.us:443",
    "serverNames": ["zoom.us", "m.zoom.us"],
    "privateKey": "${PRIV_KEY}",
    "shortIds": ["${SHORT_ID}"],
    "settings": {
      "publicKey": "${PUB_KEY}",
      "fingerprint": "chrome",
      "serverName": "",
      "spiderX": "/"
    }
  },
  "tcpSettings": {
    "acceptProxyProtocol": false,
    "header": {
      "type": "none"
    }
  }
}
EOF
)

if [[ -f "$XUIDB" ]]; then
    sqlite3 "$XUIDB" <<EOF
DELETE FROM inbounds WHERE remark='${REALITY_REMARK}' OR port=2096;
INSERT INTO inbounds (user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing)
VALUES (0, 0, 0, 0, '${REALITY_REMARK}', 1, 0, '', 2096, 'vless', '${REALITY_SETTINGS}', '${REALITY_STREAM}', 'inbound-2096', '${CDN_SNIFFING}');
EOF
fi

REALITY_LINK="vless://${REALITY_UUID}@${DOMAIN}:2096/?encryption=none&flow=xtls-rprx-vision&security=reality&fp=chrome&pbk=${PUB_KEY}&sni=zoom.us&sid=${SHORT_ID}&type=tcp&headerType=none#${REALITY_REMARK}"
LINKS+=("$REALITY_LINK")

# Restart x-ui service
if command -v x-ui &>/dev/null; then
    x-ui restart >/dev/null 2>&1
fi

# Write generated links to output file
{
    echo "# STX-NovaNetX Generated VLESS Share Links"
    echo "# Generated at: $(date)"
    echo "# Domain: ${DOMAIN}"
    echo ""
    for l in "${LINKS[@]}"; do
        echo "$l"
    done
} > "$OUTPUT_FILE"

# Output summary to console
msg_ok "Inbound Generation Completed Successfully!"
echo ""
msg_war "=== STX-NovaNetX Generated Config Links ==="
echo ""
for l in "${LINKS[@]}"; do
    msg_inf "$l"
    echo ""
done

msg_ok "Links saved to: ${OUTPUT_FILE}"
echo ""
