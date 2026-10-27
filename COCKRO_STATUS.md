# Cockro Android internal preview — code 81

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
