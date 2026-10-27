extends Node
## Real native AdMob integration; ONLY Google's test unit in internal builds.
## Production must use authenticated server-side verification before granting online items.
signal changed
const TEST_UNIT := "ca-app-pub-3940256099942544/5224354917"
var inventory := CockroRewardInventory.new()
var message := "โฆษณาทดสอบ • ของใช้ได้เฉพาะสนามฝึกบนเครื่องนี้"
var busy := false
var initialized := false
var ad: RewardedAd
var pending := ""
var receipt := ""
var earned := false
var generation := 0

func _ready() -> void:
	inventory.load_data()
	if OS.get_name() != "Android" or not Engine.has_singleton("PoingGodotAdMob"):
		message = "ดูโฆษณาทดสอบได้ในแอป Android เท่านั้น"
		return
	var callback := OnInitializationCompleteListener.new()
	callback.on_initialization_complete = func(_status):
		initialized = true
		changed.emit()
	MobileAds.initialize(callback)

func request(item: String) -> void:
	if busy or not inventory.available(item):
		return
	if not initialized:
		message = "โฆษณายังไม่พร้อม กรุณาตรวจอินเทอร์เน็ตแล้วลองอีกครั้ง"
		changed.emit()
		return
	busy = true
	earned = false
	pending = item
	receipt = Crypto.new().generate_random_bytes(16).hex_encode()
	generation += 1
	var current := generation
	message = "กำลังโหลดโฆษณา…"
	changed.emit()
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_failed_to_load = func(_error):
		if current == generation:
			finish("โหลดโฆษณาไม่ได้ ยังไม่ได้รับของ กดลองใหม่ได้")
	callback.on_ad_loaded = func(loaded: RewardedAd):
		if current != generation or not is_inside_tree():
			loaded.destroy()
			return
		ad = loaded
		var full := FullScreenContentCallback.new()
		full.on_ad_failed_to_show_full_screen_content = func(_error):
			if current == generation:
				finish("เปิดโฆษณาไม่สำเร็จ ยังไม่ได้รับของ")
		full.on_ad_dismissed_full_screen_content = func():
			if current == generation:
				finish(message if earned else "ปิดโฆษณาก่อนรับรางวัล ยังไม่ได้รับของ")
		ad.full_screen_content_callback = full
		var reward := OnUserEarnedRewardListener.new()
		reward.on_user_earned_reward = func(_reward):
			if current != generation or earned or pending.is_empty():
				return
			earned = true
			if inventory.grant(pending, receipt):
				message = "ได้รับ %s แล้ว!" % CockroRewardInventory.CATALOG[pending]
			else:
				message = "บันทึกของไม่สำเร็จ กรุณาตรวจพื้นที่ว่าง"
			changed.emit()
		message = "กำลังแสดงโฆษณา ดูจบเพื่อรับของ"
		changed.emit()
		ad.show(reward)
	RewardedAdLoader.new().load(TEST_UNIT, AdRequest.new(), callback)
	get_tree().create_timer(40).timeout.connect(func():
		if current == generation and busy and ad == null:
			finish("หมดเวลาโหลดโฆษณา ยังไม่ได้รับของ กดลองใหม่ได้")
	)

func finish(text: String) -> void:
	generation += 1
	busy = false
	pending = ""
	message = text
	if ad:
		ad.destroy()
		ad = null
	changed.emit()

func _exit_tree() -> void:
	generation += 1
	if ad:
		ad.destroy()
