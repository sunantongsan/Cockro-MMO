# Cockro Android internal preview — code 82

CURRENT STATUS: Google Play internal track shows code82 (4.0.0-internal.2), Rewarded Ads Test, ready for internal testers. Published 2026-10-28 06:52 Thailand time. Code81 was never rolled out. Historical code81 notes below are retained for traceability.

Fork of SlayHorizon/godot-tiny-mmo at f4ed04f20963c3285117e58b1149fa1117658d3c. Original license retained.

## Android training preview
- Package `com.sunantongsan.networkcokcro`; version `4.0.0-internal.1` (81), landscape, arm64.
- Local training menu using existing Cockro-Networkv4 mascot (assets/mascot-wai.webp).
- Multitouch movement, attack and area skill; sword, bow, gun, club and Cockroach Man training loadouts.
- Enemy targets, health, cooldowns, defeat and restart. Training does not read or modify accounts, currencies or database.
- Thai font: Noto Sans Thai, SIL Open Font License in assets/cockro/OFL.txt.
- These are prototype weapon loadouts, not completed MMORPG professions. Art, animations, maps and enemy behavior are placeholders.

## Online migration remains incomplete
No hosted Cockro gateway/master/world server configured. Online control is disabled when the HTTPS gateway setting is empty. Original Tiny MMO online client/server source remains in the fork. Prior account/database integration, five complete professions, original animal collection and two-client combat/save/reconnect validation are not complete.

## Validation
Godot 4.6.3 imports and starts the client. Automated training checks cover all five weapon damage paths, attack cooldown, skill cooldown, touch movement/release, focus-loss reset and defeat/restart. Desktop rendering inspected at 960x540. Upstream ObjectDB/resource warnings remain at engine shutdown.
Local gateway/master handshake previously returned {"ok":true}; this does not verify Internet multiplayer.
Existing COCKRO upload key was retrieved privately and used only for Android signing, never committed.

## Build
Install Godot 4.6.3 Android export templates, JDK17, Android SDK36 and build tools36.1.0. Install the Android build template to android/build and retain android/.gdignore. Set Godot editor SDK/JDK paths and GODOT_ANDROID_KEYSTORE_RELEASE_PATH, GODOT_ANDROID_KEYSTORE_RELEASE_USER, GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD privately. Run Godot --headless --path . --export-release Android exports/android/cockro-81.aab. Android generated files and exports are ignored by git.

Internal preview upload is permitted after successful signed build and package validation. Full online release requires hosted-server and multiplayer validation. Distribution status must be checked in Play Console; this document is not proof of rollout.

## Build and upload result (2026-10-27 UTC)
- Signed AAB successfully built: 42,535,267 bytes. SHA256 b9df6f9262867de8e97f5111b0014e9bf69e3b1a703db1afa0e04e71836bd36f.
- jarsigner verified the signature. bundletool validate passed. Manifest confirms package, version81, minSDK24/targetSDK36, arm64-v8a. No keystore files in bundle.
- Extracted exported Android game data starts with Godot headless without script errors; this is not a physical Android-device test.
- Uploaded and processed in Google Play internal track 4701506968907566093, draft release4. NOT rolled out. Existing release80 remains active.
- Release blocked by existing app Advertising ID declaration versus the preview's absent AD_ID permission. Preview has no ads. Automatic action review rejected Google's publish-without-permission option pending explicit user approval. No declaration or permission bypass applied.
- Other Play warnings: 5,588 fewer supported devices (arm64-only preview), larger download, missing deobfuscation/native symbol files.
- To reproduce the local build, keep android/.gdignore present before importing; remove stale *.import metadata from generated android resources if earlier imports scanned that directory.

## Rewarded ads — internal code82
- Added native Poing AdMob 5.1.0 / Godot4.6.3 Android integration, Google Mobile Ads next-gen SDK1.4.0, and AD_ID/network permissions. Uses Google's TEST app/unit IDs only; this build earns no advertising revenue.
- Run `python tools/install_admob.py` before opening/importing a fresh checkout. Dependency archives are pinned to official release URLs and SHA256 hashes; generated dependency files stay out of git.
- Voluntary shop: 1 rewarded ad unlocks weapon (+5 damage) or hero armor (130 starting HP), or grants 1 enhancement stone. Weapon enhancement consumes a stone, succeeds deterministically, adds +3 damage per level, capped at +5.
- Reward is issued only from the native SDK earned-reward callback, with a unique receipt and duplicate guard. Close/failure/timeout never grants rewards. Loading prevents concurrent requests. Owned nonconsumables cannot be claimed again.
- Inventory is atomically persisted under user://training_rewards_v1.json. This is local INTERNAL TEST inventory only, never an authoritative online account or transferable economy. Live advertising and online rewards require production AdMob IDs, UMP consent configuration, authenticated SSV and server-side inventory transactions before launch.
- Inventory tests pass: invalid claims, duplicate receipts, ownership, enhancement consumption/cap, reload persistence, and no reward on ad failure/non-Android fallback. Shop rendered and inspected at960x540. Native ad playback still needs testing on an Android device.
- Code82 supersedes draft81. Do not use the rejected publish-without-AD_ID workaround: this version includes actual ad functionality requested by the user.
- Code82 signed AAB: 50,969,010 bytes; SHA256 8d7fc60d28781648483a7ab4cedc3174333ecff6a3083b764bf6d5e330c86636. bundletool validation and jarsigner signature verification pass. Exported game data starts without script errors (desktop/headless, not physical Android).
- Manifest verified: code82, original package, native PoingGodotAdMobRewardedAd registration and AD_ID permission. Required MIT/font notices included; no signing keys inside bundle. Full-screen callbacks ignore stale ad generations.

- Final Play validation: no Advertising ID error; four nonblocking warnings (device coverage, download size, missing deobfuscation/native symbols). Normal Save and Publish completed. Internal track4701506968907566093 confirms latest release82 ready for testers. No production/closed-track rollout performed.
