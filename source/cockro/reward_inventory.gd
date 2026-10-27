class_name CockroRewardInventory
extends RefCounted
## Isolated local INTERNAL TEST inventory. Never trusted by an online economy.
const PATH := "user://training_rewards_v1.json"
const CATALOG := {"weapon": "อาวุธพลังแมงสาบ", "outfit": "ชุดเกราะฮีโร่", "stone": "หินตีบวกพิเศษ"}
var data := {"weapon": false, "outfit": false, "stones": 0, "level": 0, "receipts": []}
var save_path := PATH

func load_data() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if parsed is Dictionary:
		data.weapon = parsed.get("weapon", false) == true
		data.outfit = parsed.get("outfit", false) == true
		data.stones = clampi(int(parsed.get("stones", 0)), 0, 9999)
		data.level = clampi(int(parsed.get("level", 0)), 0, 5)
		if parsed.get("receipts", []) is Array:
			data.receipts = parsed.get("receipts", [])

func available(item: String) -> bool:
	return CATALOG.has(item) and (item == "stone" or not data[item])

func grant(item: String, receipt: String) -> bool:
	if receipt.is_empty() or data.receipts.has(receipt) or not available(item):
		return false
	var before: Dictionary = data.duplicate(true)
	if item == "stone":
		data.stones += 1
	else:
		data[item] = true
	data.receipts.append(receipt)
	if not save():
		data = before
		return false
	return true

func enhance() -> bool:
	if not data.weapon or data.stones < 1 or data.level >= 5:
		return false
	var before: Dictionary = data.duplicate(true)
	data.stones -= 1
	data.level += 1
	if not save():
		data = before
		return false
	return true

func save() -> bool:
	var f := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data))
	f.flush()
	var error := f.get_error()
	f.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(save_path + ".tmp", save_path) == OK
