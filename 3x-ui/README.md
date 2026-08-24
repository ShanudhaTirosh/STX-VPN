# ShanuTechX Panel (STX-NovaNetX)

**ShanuTechX Panel (STX-NovaNetX)** is an advanced, high-performance web control panel for managing [Xray-core](https://github.com/XTLS/Xray-core) servers. Rebranded and streamlined for maximum efficiency, it features an **English-Only interface**, modern glassmorphic dark theme, auto-provisioning multi-SNI XTLS-Vision inbounds, and Cloudflare CDN VLESS setup.

---

## Key Features

- **Brand Identity**: Rebranded as **ShanuTechX Panel (NovaNetX)** (`STX-NovaNetX`).
- **Streamlined English Interface**: Zero multi-language overhead for maximum speed (`en-US`).
- **Modern Glassmorphic Dark UI**: Custom color tokens, refined contrast, rounded borders, and sleek status badges.
- **Automated Inbound Provisioning**: Integrated multi-SNI XTLS-Vision (`zoom.us`, `m.zoom.us`, `tiktok.com`, `netflix.com`, `youtube.com`, `m.youtube.com`, `aka.ms`) and Cloudflare CDN WS inbounds out of the box with zero port conflicts.
- **`STX-NovaNetX` Remark Tags**: Custom brand remark tags on generated share links.

---

## One-Line Automated Installation

To install on your server:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/ShanudhaTirosh/STX-VPN/master/stx-release/stx-install.sh) -subdomain vpn.shanutechx.com
```

### What the Automated Installer Does:
1. Installs system packages (Nginx, Certbot, SQLite, Curl, etc.).
2. Deploys the web traffic decoy landing page to `/var/www/html/index.html`.
3. Issues Let's Encrypt SSL certificates for your domain (`vpn.shanutechx.com`).
4. Installs and configures **ShanuTechX Panel**.
5. Automatically provisions:
   - **Cloudflare CDN WS Inbound** on port 8443.
   - **XTLS-Vision TCP Multi-SNI Inbounds** on port 443.
6. Saves all generated `vless://` share links to `/etc/x-ui-pro/generated-links.txt` and prints them cleanly in terminal output.

---

## Repository & License

- Repository: [https://github.com/ShanudhaTirosh/STX-VPN](https://github.com/ShanudhaTirosh/STX-VPN)
- License: Distributed under the GPL-3.0 License.
EOF
