# VPS internal-test deployment checkpoint — 2026-10-28

## Completed
- VPS Ubuntu 24.04, 2 vCPU / 2 GB RAM; staging checkout `/opt/cockro-src`.
- Official Godot 4.6.3 editor and export templates downloaded and SHA512 verified.
- `tools/prepare_vps.py` passed original-game signup, login, character creation, original map load, movement, reconnect and character retrieval on the VPS.
- An exported Linux server also passed the same gameplay smoke check in the build environment.
- `tools/install_vps_service.py` installed/enabled `cockro.service`, with a non-login `cockro` user, three server processes, graceful pre-stop save, persistent state under `/var/lib/cockro`, and a 12-player configured limit (not a load-test result).
- Removed default guest1/guest2 administrator grants; deployed administrator list is empty.
- Namecheap A record `game.guardscan.xyz` points at `143.14.4.241`; existing website/mail records preserved.
- Caddy HTTPS activated after user confirmation. External TLS-verified `/health`, account creation and login passed. World advertises `wss://game.guardscan.xyz/world`. Master/dashboard ports remain on loopback.
- Android AAB versionCode 83 / versionName `4.0.0-internal.3` built with original client startup and `https://game.guardscan.xyz` gateway. Game protocol version remains `4.0.0-internal.2` to match the installed server.
- AAB bundletool validation passed and JAR signature verified. Build has no GDScript parse/compile errors after installing pinned AdMob dependencies. Export still reports resource cleanup warnings.
- AAB SHA256: `d0272917b494dde58a532ac0ed5392e1d6979f90f36c14b857f895bb3a235775`.

## Network and persistence checks
- `tools/check_remote.py` passed HTTPS signup/login, original map load and player movement over WSS when executed on the VPS against the public domain.
- A second run with `--resume` confirmed persisted accounts and characters after `systemctl restart cockro`, both from the VPS and the external build environment.
- The build environment's Godot WSS movement run timed out; its HTTPS checks passed. Do not claim a successful external Android runtime test.
- Android 83 published to INTERNAL testing. Play Console shows “Available to internal testers”, latest release `83 (4.0.0-internal.3) Original MMO`, published 28 October 2026 at 12:07 Bangkok. No production rollout. Existing tester access retained. User account verified as enrolled at https://play.google.com/apps/internaltest/4701506968907566093 .

## Known limitations
- Intermittent native engine crash during world startup remains unresolved. On the tested restart, systemd recovered after four retries; account/character persistence then passed. Kernel logged `server.x86_64` segmentation faults. A local editor reproduction points to `ServerInstance.load_map` / map resource loading; 6 successful boots followed by signal 11. The exported local server passed 8 consecutive startup checks. These checks do not establish stability.
- Actual Android device, combat, quests and concurrent-player capacity have not been tested.
- Google Play warns about missing obfuscation mapping and native debug symbols; neither blocks this internal release.
- Internal Play distribution restricts app recipients; the Internet-facing game API is not itself invite-only.

## Operations
- `systemctl status cockro --no-pager`
- `journalctl -u cockro -n 80 --no-pager`
- Runtime diagnostics: `journalctl -u cockro`; release export did not create the requested per-role log files. Build logs: `/opt/cockro-tools/classic-test.log`, `/opt/cockro-tools/server-export.log`.
- `prepare_vps.py` is staging-only. `install_vps_service.py` deliberately refuses to overwrite an existing installation. Do not delete live data to rerun it.
- Caddy admin API and game master/dashboard ports must stay on loopback; only game HTTP/WSS routes may be proxied.

