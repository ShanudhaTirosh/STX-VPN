#!/bin/bash
###############################################################################
# ShanuTechX Panel (STX-NovaNetX) Master Unified Installation Script
# Performs complete end-to-end automated installation:
# - System dependencies & Nginx
# - Decoy web traffic emulation (/var/www/html/index.html)
# - Let's Encrypt SSL Certificate provisioning
# - ShanuTechX 3X-UI Panel installation
# - Automatic SQLite Inbound configuration (CDN WS + Multi-SNI XTLS-Vision)
# - Sets SSL Cert/Key paths & Dashboard Path (/shanutechx/)
# - Saves & displays STX-NovaNetX VLESS share links and Admin Credentials
###############################################################################

[[ $EUID -ne 0 ]] && { echo -e "\e[1;31mFatal error: Please run as root!\e[0m"; exit 1; }

DOMAIN="vpn.shanutechx.com"
CF_IP="172.66.40.229"
XUIUSER="admin"
XUIPASS=""

# Parse arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -subdomain|-domain|-d) DOMAIN="$2"; shift 2;;
    -cdnip|-cfip) CF_IP="$2"; shift 2;;
    -u|-user|-username) XUIUSER="$2"; shift 2;;
    -p|-pass|-password) XUIPASS="$2"; shift 2;;
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
msg_inf "Target Domain: ${DOMAIN}"
msg_inf "Cloudflare Edge IP: ${CF_IP}"
echo ""

# Generate random password if not provided
if [[ -z "$XUIPASS" ]]; then
    XUIPASS=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom 2>/dev/null | head -c 12 || echo "STXAdmin2026")
fi

# 1. Package Installation
Pak=$(command -v apt || command -v dnf || command -v yum) && Pak=$(basename "$Pak") || { msg_err "No package manager found!"; exit 1; }

msg_inf "Step 1: Installing System Dependencies & Nginx..."
[[ $Pak == *apt ]] && sudo apt update -y || sudo dnf makecache

for p in epel-release cronie psmisc unzip curl git nginx python3 certbot sqlite3 jq openssl; do
  (command -v dpkg &>/dev/null && dpkg -l $p &>/dev/null) || (rpm -q $p &>/dev/null) || sudo $Pak -y install $p >/dev/null 2>&1
done

systemctl enable nginx cron >/dev/null 2>&1
systemctl start nginx cron >/dev/null 2>&1

# 2. Deploy Web Traffic Emulation Decoy Page
msg_inf "Step 2: Deploying Web Traffic Emulation Decoy Site..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p /var/www/html

if [[ -f "${SCRIPT_DIR}/web-decoy/index.html" ]]; then
    cp -f "${SCRIPT_DIR}/web-decoy/index.html" /var/www/html/index.html
elif [[ -f "${SCRIPT_DIR}/../web-decoy/index.html" ]]; then
    cp -f "${SCRIPT_DIR}/../web-decoy/index.html" /var/www/html/index.html
else
    curl -sSL "https://raw.githubusercontent.com/ShanudhaTirosh/STX-VPN/master/stx-release/web-decoy/index.html" -o /var/www/html/index.html 2>/dev/null
fi

# Stop Nginx temporarily for Standalone Certbot SSL Issue
systemctl stop nginx >/dev/null 2>&1

# 3. SSL Provisioning
msg_inf "Step 3: Provisioning Let's Encrypt SSL Certificate for ${DOMAIN}..."
certbot certonly --standalone --non-interactive --force-renewal --agree-tos --register-unsafely-without-email -d "$DOMAIN" >/dev/null 2>&1

CERT_FILE="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
KEY_FILE="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"

if [[ ! -f "$CERT_FILE" ]]; then
    MAIN_DOMAIN=$(echo "$DOMAIN" | sed 's/.*\.\([^.]*\..*\)$/\1/')
    CERT_FILE="/etc/letsencrypt/live/${MAIN_DOMAIN}/fullchain.pem"
    KEY_FILE="/etc/letsencrypt/live/${MAIN_DOMAIN}/privkey.pem"
fi

# 4. Install ShanuTechX Panel (3x-ui)
msg_inf "Step 4: Installing ShanuTechX 3X-UI Panel..."
if [[ -f "${SCRIPT_DIR}/3x-ui/install.sh" ]]; then
    bash "${SCRIPT_DIR}/3x-ui/install.sh"
elif [[ -f "${SCRIPT_DIR}/install.sh" ]]; then
    bash "${SCRIPT_DIR}/install.sh"
else
    msg_inf "Downloading ShanuTechX Panel repository from GitHub..."
    mkdir -p /tmp/stx-repo && cd /tmp/stx-repo
    git clone https://github.com/ShanudhaTirosh/STX-VPN.git . >/dev/null 2>&1 || (curl -sSL https://github.com/ShanudhaTirosh/STX-VPN/archive/refs/heads/master.tar.gz | tar -xz --strip-components=1)
    bash stx-release/3x-ui/install.sh
fi

systemctl enable x-ui >/dev/null 2>&1
systemctl start x-ui >/dev/null 2>&1

# 5. Configure Database: Dashboard Path (/shanutechx/), Random Port, Credentials, SSL Cert Paths
msg_inf "Step 5: Configuring Panel Settings, Dashboard Path & SSL Paths..."
XUIDB="/etc/x-ui/x-ui.db"
RANDOM_PORT=$((RANDOM%30000+30000))

if [[ -f "$XUIDB" ]]; then
    x-ui stop >/dev/null 2>&1
    sqlite3 "$XUIDB" <<EOF
    DELETE FROM settings WHERE key IN ('webPort', 'webCertFile', 'webKeyFile', 'webBasePath');
    INSERT INTO settings (key, value) VALUES ('webPort', '${RANDOM_PORT}'), ('webCertFile', '${CERT_FILE}'), ('webKeyFile', '${KEY_FILE}'), ('webBasePath', '/shanutechx/');
EOF
    if [[ -f /usr/local/x-ui/x-ui ]]; then
        /usr/local/x-ui/x-ui setting -username "$XUIUSER" -password "$XUIPASS" >/dev/null 2>&1
    fi
    x-ui start >/dev/null 2>&1
fi

# 6. Automatic Inbound & Config Provisioning
msg_inf "Step 6: Provisioning STX-NovaNetX Inbounds & Certificates..."
GEN_SCRIPT=""
if [[ -f "${SCRIPT_DIR}/x-ui-pro/gen-inbounds.sh" ]]; then
    GEN_SCRIPT="${SCRIPT_DIR}/x-ui-pro/gen-inbounds.sh"
elif [[ -f "${SCRIPT_DIR}/gen-inbounds.sh" ]]; then
    GEN_SCRIPT="${SCRIPT_DIR}/gen-inbounds.sh"
fi

if [[ -n "$GEN_SCRIPT" ]]; then
    bash "$GEN_SCRIPT" "$DOMAIN" "$CF_IP"
fi

# Start Nginx service
systemctl start nginx >/dev/null 2>&1

# 7. Print Summary Output and Login Credentials
echo ""
hrline
msg_ok "🎉 ShanuTechX Master Installation Completed Successfully!"
hrline
msg_inf "🌐 Web Dashboard URL  : https://${DOMAIN}/shanutechx/"
msg_inf "👤 Admin Username     : ${XUIUSER}"
msg_inf "🔑 Admin Password     : ${XUIPASS}"
msg_inf "📌 Internal Panel Port : ${RANDOM_PORT}"
msg_inf "🔒 SSL Cert File      : ${CERT_FILE}"
msg_inf "🔒 SSL Key File       : ${KEY_FILE}"
msg_inf "📄 VLESS Share Links   : /etc/x-ui-pro/generated-links.txt"
hrline
echo ""
