# STX-NovaNetX Multi-SNI Automated Installer & Config Generator

**STX-NovaNetX** is a unified, automated proxy installation script for **ShanuTechX Panel**. It automatically provisions Nginx, Let's Encrypt SSL certificates, Xray inbounds, web traffic emulation, and multi-SNI XTLS-Vision and Cloudflare CDN VLESS configurations out of the box with **zero port conflicts**.

---

## Features

- **Automated Master Setup**: Installs Nginx, SSL via Certbot, SQLite, Xray-core, and ShanuTechX Panel in a single command.
- **Web Traffic Emulation**: Deploys a modern Cloud Services decoy page to `/var/www/html/index.html` for direct browser probes.
- **Multi-SNI XTLS-Vision on Port 443**: Generates isolated inbounds for decoy SNIs (`zoom.us`, `m.zoom.us`, `tiktok.com`, `netflix.com`, `youtube.com`, `m.youtube.com`, `aka.ms`) using Xray's single-socket multi-cert matching array.
- **Cloudflare CDN VLESS Inbound on Port 8443**: Generates WebSocket + TLS inbounds for `vpn.shanutechx.com` with Cloudflare edge IP (`172.66.40.229`).
- **`STX-NovaNetX` Custom Remarks**: All generated links carry the custom remark prefix (`#STX-NovaNetX-...`).
- **Automatic Output**: Displays generated `vless://` share links directly in the terminal and saves them to `/etc/x-ui-pro/generated-links.txt`.

---

## One-Line Master Installation

To run the unified installation script on your server:

```bash
bash <(curl -Ls https://raw.githubusercontent.com/ShanudhaTirosh/STX-VPN/master/stx-release/stx-install.sh) -subdomain vpn.shanutechx.com
```

---

## Output File

All generated VLESS share links are saved to:
```bash
cat /etc/x-ui-pro/generated-links.txt
```

Repository: [https://github.com/ShanudhaTirosh/STX-VPN](https://github.com/ShanudhaTirosh/STX-VPN)
EOF
