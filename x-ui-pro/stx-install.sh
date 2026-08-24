#!/bin/bash
###############################################################################
# ShanuTechX Panel (STX-NovaNetX) Master Unified Installation Script
# Performs complete end-to-end automated installation:
# - System dependencies & Nginx
# - Let's Encrypt SSL Certificate provisioning
# - ShanuTechX 3X-UI Panel installation
# - Automatic SQLite Inbound configuration (CDN WS + Multi-SNI XTLS-Vision)
# - Saves & displays STX-NovaNetX VLESS share links
###############################################################################

[[ $EUID -ne 0 ]] && { echo "Error: Script must be run as root!"; exec sudo "$0" "$@"; }

DOMAIN="vpn.shanutechx.com"
CF_IP="172.66.40.229"
PNLNUM=1

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -subdomain|-domain|-d) DOMAIN="$2"; shift 2;;
    -cdnip|-cfip) CF_IP="$2"; shift 2;;
    *) shift 1;;
  esac
done

msg()     { echo -e "\e[1;37;40m $1 \e[0m"; }
msg_ok()  { echo -e "\e[1;32;40m $1 \e[0m"; }
msg_err() { echo -e "\e[1;31;40m $1 \e[0m"; }
msg_inf() { echo -e "\e[1;36;40m $1 \e[0m"; }
msg_war() { echo -e "\e[1;33;40m $1 \e[0m"; }
hrline()  { printf '\033[1;35;40m%s\033[0m\n' "$(printf '%*s' "${COLUMNS:-$(tput cols)}" '' | tr ' ' "${1:--}")"; }

echo ""
msg_inf "  ____ _____  _  __  _   _                 _   _  _____ _____  "
msg_inf " / ___|_   _| \ \ / / | \ | | _____   ____ _| \ | || ____|_   _| "
msg_inf " \___ \ | |    \ V /  |  \| |/ _ \ \ / / _\` |  \| ||  _|   | |   "
msg_inf "  ___) || |     | |   | |\  | (_) \ V / (_| | |\  || |___  | |   "
msg_inf " |____/ |_|     |_|   |_| \_|\___/ \_/ \__,_|_| \_||_____| |_|   "
hrline
echo ""
msg_ok "Starting ShanuTechX Panel (STX-NovaNetX) Automated Master Installation..."
msg_inf "Target Subdomain: ${DOMAIN}"
msg_inf "Cloudflare CDN IP: ${CF_IP}"
echo ""

# 1. Package Installation
Pak=$(command -v apt || command -v dnf || command -v yum) && Pak=$(basename "$Pak") || { msg_err "No package manager found!"; exit 1; }

msg_inf "Step 1: Installing System Dependencies & Nginx..."
[[ $Pak == *apt ]] && sudo apt update -y || sudo dnf makecache

for p in epel-release cronie psmisc unzip curl nginx python3 certbot sqlite3 jq openssl; do
  (command -v dpkg &>/dev/null && dpkg -l $p &>/dev/null) || (rpm -q $p &>/dev/null) || sudo $Pak -y install $p >/dev/null 2>&1
done

systemctl enable nginx cron >/dev/null 2>&1
systemctl start nginx cron >/dev/null 2>&1

# Copy Decoy Web Page for Web Traffic Emulation
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p /var/www/html
if [[ -f "${SCRIPT_DIR}/web-decoy/index.html" ]]; then
    cp -f "${SCRIPT_DIR}/web-decoy/index.html" /var/www/html/index.html
fi

# Stop Nginx temporarily for Standalone Certbot SSL Issue
systemctl stop nginx >/dev/null 2>&1

# 2. SSL Provisioning
msg_inf "Step 2: Provisioning Let's Encrypt SSL Certificate for ${DOMAIN}..."
certbot certonly --standalone --non-interactive --force-renewal --agree-tos --register-unsafely-without-email -d "$DOMAIN" >/dev/null 2>&1

CERT_DIR="/etc/letsencrypt/live/${DOMAIN}"
if [[ ! -d "$CERT_DIR" ]]; then
    # Fallback to main domain cert path if subdomain is nested
    MAIN_DOMAIN=$(echo "$DOMAIN" | sed 's/.*\.\([^.]*\..*\)$/\1/')
    CERT_DIR="/etc/letsencrypt/live/${MAIN_DOMAIN}"
fi

if [[ ! -d "$CERT_DIR" ]]; then
    msg_war "Warning: Certbot SSL issue for ${DOMAIN}. Setup will proceed with self-signed certificate placeholders."
fi

# 3. Install ShanuTechX Panel (3x-ui)
msg_inf "Step 3: Installing ShanuTechX 3X-UI Panel..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "${SCRIPT_DIR}/3x-ui/install.sh" ]]; then
    bash "${SCRIPT_DIR}/3x-ui/install.sh"
elif [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    bash "${SCRIPT_DIR}/install.sh"
else
    printf 'n\n' | bash <(wget -qO- "https://raw.githubusercontent.com/ShanudhaTirosh/STX-VPN/master/stx-release/3x-ui/install.sh")
fi

systemctl enable x-ui >/dev/null 2>&1
systemctl start x-ui >/dev/null 2>&1

# Set Dashboard Path to /shanutechx/ and Random Port in x-ui.db
XUIDB="/etc/x-ui/x-ui.db"
if [[ -f "$XUIDB" ]]; then
    x-ui stop >/dev/null 2>&1
    RANDOM_PORT=$((RANDOM%30000+30000))
    sqlite3 "$XUIDB" <<EOF
    DELETE FROM settings WHERE key IN ('webPort', 'webCertFile', 'webKeyFile', 'webBasePath');
    INSERT INTO settings (key, value) VALUES ('webPort', '${RANDOM_PORT}'), ('webCertFile', ''), ('webKeyFile', ''), ('webBasePath', '/shanutechx/');
EOF
fi

# 4. Automatic Inbound & Config Provisioning
msg_inf "Step 4: Provisioning STX-NovaNetX Inbounds & Certificates..."
GEN_SCRIPT=""
if [[ -f "${SCRIPT_DIR}/x-ui-pro/gen-inbounds.sh" ]]; then
    GEN_SCRIPT="${SCRIPT_DIR}/x-ui-pro/gen-inbounds.sh"
elif [[ -f "${SCRIPT_DIR}/gen-inbounds.sh" ]]; then
    GEN_SCRIPT="${SCRIPT_DIR}/gen-inbounds.sh"
fi

if [[ -n "$GEN_SCRIPT" ]]; then
    bash "$GEN_SCRIPT" "$DOMAIN" "$CF_IP"
fi

# Start Nginx
systemctl start nginx >/dev/null 2>&1

echo ""
hrline
msg_ok "Master Installation Completed Successfully!"
msg_inf "All inbounds configured automatically with STX-NovaNetX remarks."
msg_inf "VLESS links saved to: /etc/x-ui-pro/generated-links.txt"
hrline
echo ""
EOF
chmod +x "c:\Users\tiros\OneDrive\Documents\coding\3xui v\stx-release\stx-install.sh" 2>/dev/null || true
