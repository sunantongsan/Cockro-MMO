# Cockro MMO migration — 2026-10-28

Based on SlayHorizon/godot-tiny-mmo at f4ed04f20963c3285117e58b1149fa1117658d3c. Original MIT license retained; asset licenses require separate review before distribution.

## Prepared
- Cockro project identity and landscape Android AAB preset.
- Package com.sunantongsan.networkcokcro matches Cockro-Networkv4 app.json.
- Play Console checked: internal track already serves version 80 (4.0.0), Cockro Man - Internal, released 2026-10-27. Prepared next code 81; recheck before upload.
- Gateway URL is now a project setting: cockro/network/gateway_url (HTTPS). No upstream production endpoint fallback.
- Removed missing developer MCP autoload/plugin; disabled inherited upstream publishing workflow in this fork.

## Not ready for release
- No Cockro hosted gateway/master/world server configured. Database access alone is insufficient.
- Existing Android upload keystore and current Play version must be verified.
- Cockroach character art/animations, gun and five classes including Cockroach Man are not implemented.
- Existing account/database integration is not migrated.
- Do not upload until Android build, startup, two-client combat and save/reconnect checks pass.

## Validation
- Godot 4.6.3 editor import completed with no script parse errors after importing assets.
- Headless client startup completed; resource leak warnings at exit remain. This is not Android or multiplayer verification.
- Installed godot-sqlite v4.7 Linux binaries locally for validation (not committed).

- Initial separate-process smoke attempt failed. Retest with all services in one process environment succeeded: gateway/master connected and POST /v1/handshake returned {"ok":true}. This verifies only local handshake, not two-player world gameplay or phone access.
- Library contains COCKRO-upload-key-backup.zip; not downloaded or used yet.

