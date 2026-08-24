# STX-VPN: ShanuTechX Panel (STX-NovaNetX) & Automated Multi-SNI Installer

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https.www.gnu.org/licenses/gpl-3.0)
[![Repository](https://img.shields.io/badge/GitHub-ShanudhaTirosh%2FSTX--VPN-cyan)](https://github.com/ShanudhaTirosh/STX-VPN)

**STX-VPN** is an all-in-one automated Xray proxy suite featuring **ShanuTechX Panel (STX-NovaNetX)** — an English-only, high-performance web panel with custom glassmorphic UI — integrated with an automated multi-SNI XTLS-Vision and Cloudflare CDN VLESS inbound generator.

---

## 🌐 Dashboard URL & Access

After installation, your admin dashboard is accessible securely via HTTPS:

- **Dashboard URL**: `https://vpn.shanutechx.com/shanutechx/`
- **Dashboard Path**: `/shanutechx/`
- **Port**: Dynamically assigned random port (proxied through Nginx on 443/SSL)

> [!NOTE]
> Visiting `https://vpn.shanutechx.com/` directly displays an enterprise Cloud Services decoy site to defeat passive scanning and DPI probes.

---

## 🚀 One-Line Automated Master Installation

Run this command on your server (Ubuntu / Debian / CentOS / AlmaLinux / Arch):

```bash
bash <(curl -Ls https://raw.githubusercontent.com/ShanudhaTirosh/STX-VPN/master/stx-release/stx-install.sh) -subdomain vpn.shanutechx.com
```

### What Happens Automatically:
1. **System & Web Dependencies**: Installs Nginx, Certbot, SQLite, Curl, and system tools.
2. **Decoy Web Traffic Emulation**: Deploys a modern tech landing page to `/var/www/html/index.html`.
3. **SSL Certificate Provisioning**: Issues Let's Encrypt SSL certificates for `vpn.shanutechx.com`.
4. **ShanuTechX Panel Installation**: Deploys English-only panel configured with `/shanutechx/` base path.
5. **Automated Inbound Provisioning**:
   - **Cloudflare CDN WS (Port 8443)**: `vpn.shanutechx.com` (`#STX-NovaNetX-CDN`)
   - **XTLS-Vision TCP Multi-SNI (Port 443)**: Decoy SNIs (`zoom.us`, `m.zoom.us`, `tiktok.com`, `netflix.com`, `youtube.com`, `m.youtube.com`, `aka.ms`) with zero port conflicts.
6. **VLESS Share Link Generation**: Saves generated share links to `/etc/x-ui-pro/generated-links.txt` and displays them in the terminal.

---

## 📁 Repository Structure

- `stx-install.sh` — Unified master automated installation script.
- `3x-ui/` — Rebranded, English-only ShanuTechX Panel Go + React source.
- `x-ui-pro/` — Installation engine & `gen-inbounds.sh` config generator.
- `web-decoy/` — Web traffic emulation HTML landing page.

---

## 💖 Acknowledgments & Credits

Special thanks and full credit to the authors and maintainers of the foundational open-source projects:

- **3X-UI Project**: [MHSanaei/3x-ui](https://github.com/MHSanaei/3x-ui)
- **XUI-PRO Project**: [GFW4Fun/x-ui-pro](https://github.com/GFW4Fun/x-ui-pro)
- **Xray-core**: [XTLS/Xray-core](https://github.com/XTLS/Xray-core)
- **Original X-UI Author**: [alireza0](https://github.com/alireza0)

---

## 📜 License

Distributed under the [GPL-3.0 License](LICENSE).
EOF
