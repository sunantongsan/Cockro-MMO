# VPS internal-test deployment checkpoint — 2026-10-28

## Completed
- VPS Ubuntu 24.04, 2 vCPU / 2 GB RAM; staging checkout `/opt/cockro-src`.
- Official Godot 4.6.3 editor and export templates downloaded and SHA512 verified.
- `tools/prepare_vps.py` passed original-game signup, login, character creation, original map load, movement, reconnect and character retrieval on the VPS.
- An exported Linux server also passed the same gameplay smoke check in the build environment.
- `tools/install_vps_service.py` installed/enabled `cockro.service`, with a non-login `cockro` user, three server processes, graceful pre-stop save, persistent state under `/var/lib/cockro`, and a 12-player configured limit (not a load-test result).
- Removed default guest1/guest2 administrator grants; deployed administrator list is empty.
- Namecheap A record `game.guardscan.xyz` points at `143.14.4.241`; existing website/mail records preserved.
- Caddy installed. Active configuration is loopback HTTP at `127.0.0.1:8090`; local health check passed. Public HTTPS configuration validated but NOT activated.
- Android AAB versionCode 83 / versionName `4.0.0-internal.3` built with original client startup and `https://game.guardscan.xyz` gateway. Game protocol version remains `4.0.0-internal.2` to match the installed server.
- AAB bundletool validation passed and JAR signature verified. Build has no GDScript parse/compile errors after installing pinned AdMob dependencies. Export still reports resource cleanup warnings.
- AAB SHA256: `d0272917b494dde58a532ac0ed5392e1d6979f90f36c14b857f895bb3a235775`.

## Pending / do not claim published
- Public HTTPS listener/certificate issuance requires action-time confirmation in the browser-control workflow. Staged files: `/etc/caddy/Caddyfile.pending`, `/etc/cockro/world.cfg.pending`.
- After confirmation: activate those files, restart `cockro` with its save hook, reload Caddy, verify DNS/TLS, API handshake, authenticated world entry and WSS movement through the real domain.
- Verify persistent accounts/characters across service restart and Android runtime behavior. No combat/quest or concurrent-user load test completed.
- Version 83 has NOT been uploaded or rolled out in Google Play Console. Publish only to INTERNAL testing after network checks pass.
- Internal Play distribution restricts who receives the app; the proposed Internet-facing game API is not itself an invite-only access gate. If private server access is required, add an explicit tester allowlist/invitation mechanism before exposure.

## Operations
- `systemctl status cockro --no-pager`
- `journalctl -u cockro -n 80 --no-pager`
- Logs: `/var/lib/cockro/logs`, `/opt/cockro-tools/classic-test.log`, `/opt/cockro-tools/server-export.log`.
- `prepare_vps.py` is staging-only. `install_vps_service.py` deliberately refuses to overwrite an existing installation. Do not delete live data to rerun it.
- Caddy admin API and game master/dashboard ports must stay on loopback; only game HTTP/WSS routes may be proxied.
