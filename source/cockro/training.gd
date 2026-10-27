extends Node2D
## Local training only. No account, currency or multiplayer state is modified.
const NAMES = ["ดาบ", "ธนู", "ปืน", "กระบอง", "แมงสาบแมน"]
const REACH = [115.0, 420.0, 520.0, 140.0, 180.0]
const DAMAGE = [25, 18, 14, 35, 40]
var hero := Vector2(480, 280)
var foes: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var weapon := 0
var hp := 100.0
var score := 0
var cooldown := 0.0
var skill_cd := 0.0
var flash := 0.0
var stick_id := -1
var attack_id := -1
var stick_origin := Vector2.ZERO
var stick := Vector2.ZERO
var attacking := false
var active := false
var status: Label
var skill_button: Button
var menu: PanelContainer
var ads: Node
var shop: PanelContainer
var shop_info: Label
var shop_message: Label
var offer_buttons: Dictionary = {}
var enhance_button: Button
var shop_was_active := false
var hud: Control
var mascot: Texture2D = preload("res://assets/cockro/mascot.webp")
var font: Font = preload("res://assets/cockro/NotoSansThai.ttf")

func _ready() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(hud)
	var theme := Theme.new()
	theme.default_font = font
	theme.default_font_size = 20
	hud.theme = theme
	status = Label.new()
	status.position = Vector2(24, 12)
	hud.add_child(status)
	for i in range(5):
		var b := make_button(NAMES[i], Vector2(230 + i * 126, 486), Vector2(120, 44))
		b.pressed.connect(func(): weapon = i)
	var attack := make_button("โจมตี", Vector2(810, 350), Vector2(126, 100))
	attack.button_down.connect(func(): attacking = true)
	attack.button_up.connect(func(): attacking = false)
	skill_button = make_button("สกิล", Vector2(680, 372), Vector2(112, 78))
	skill_button.pressed.connect(use_skill)
	var back := make_button("เมนู", Vector2(844, 12), Vector2(90, 44))
	back.pressed.connect(show_menu)
	menu = PanelContainer.new()
	menu.position = Vector2(210, 36)
	menu.size = Vector2(540, 396)
	hud.add_child(menu)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	menu.add_child(col)
	var title := Label.new()
	title.text = "COCKRO MMO • ANDROID PREVIEW"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var art := TextureRect.new()
	art.texture = mascot
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(0, 92)
	col.add_child(art)
	var info := Label.new()
	info.text = "สนามฝึกออฟไลน์ • ต้นแบบอาวุธ 5 แบบ\nลากฝั่งซ้ายเพื่อเดิน • กดโจมตี / สกิล\nระบบอาชีพและสัตว์เดิมยังอยู่ระหว่างพัฒนา"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(info)
	var play := Button.new()
	play.text = "เข้าสนามฝึก"
	play.custom_minimum_size.y = 52
	play.pressed.connect(start_training)
	col.add_child(play)
	var online := Button.new()
	online.text = "ออนไลน์: ยังไม่ได้เชื่อมต่อเซิร์ฟเวอร์"
	online.disabled = GatewayAPI.base_url().is_empty()
	online.pressed.connect(func(): get_tree().change_scene_to_file("res://source/client/client_main.tscn"))
	col.add_child(online)
	ads = preload("res://source/cockro/reward_ads.gd").new()
	add_child(ads)
	ads.changed.connect(refresh_shop)
	build_shop()
	var shop_button := make_button("แลกของ", Vector2(720, 12), Vector2(110, 44))
	shop_button.pressed.connect(open_shop)
	var menu_shop := Button.new()
	menu_shop.text = "ดูโฆษณาแลกของ / ตีบวก"
	menu_shop.custom_minimum_size.y = 44
	menu_shop.pressed.connect(open_shop)
	col.add_child(menu_shop)
	show_menu()

func make_button(caption: String, pos: Vector2, dimensions: Vector2) -> Button:
	var b := Button.new()
	b.text = caption
	b.position = pos
	b.size = dimensions
	hud.add_child(b)
	return b

func show_menu() -> void:
	active = false
	attacking = false
	stick_id = -1
	attack_id = -1
	stick = Vector2.ZERO
	menu.show()

func start_training() -> void:
	menu.hide()
	active = true
	hp = 130 if ads and ads.inventory.data.outfit else 100
	score = 0
	hero = Vector2(480, 280)
	foes.clear()
	shots.clear()
	cooldown = 0
	skill_cd = 0
	flash = 0
	attacking = false
	for i in range(6):
		spawn_foe(i)

func spawn_foe(i: int) -> void:
	foes.append({"pos": Vector2(120 + (i * 137) % 720, 100 + (i * 89) % 300), "hp": 60.0})

func _input(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventScreenTouch:
		if event.pressed and Rect2(810, 350, 126, 100).has_point(event.position):
			attack_id = event.index
			attacking = true
		elif not event.pressed and event.index == attack_id:
			attack_id = -1
			attacking = false
		if event.pressed and Rect2(680, 372, 112, 78).has_point(event.position):
			use_skill()
		if event.pressed and event.position.x < 220 and event.position.y > 100 and stick_id == -1:
			stick_id = event.index
			stick_origin = event.position
		elif not event.pressed and event.index == stick_id:
			stick_id = -1
			stick = Vector2.ZERO
	if event is InputEventScreenDrag and event.index == stick_id:
		stick = (event.position - stick_origin).limit_length(64) / 64.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		attacking = false
		stick = Vector2.ZERO
		stick_id = -1
		attack_id = -1

func _process(delta: float) -> void:
	if active:
		var keys := Vector2(float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)), float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
		hero += (stick + keys).limit_length(1) * 220 * delta
		hero = hero.clamp(Vector2(40, 82), Vector2(920, 450))
		cooldown = maxf(0, cooldown - delta)
		skill_cd = maxf(0, skill_cd - delta)
		flash = maxf(0, flash - delta)
		if attacking or Input.is_physical_key_pressed(KEY_SPACE):
			attack()
		for enemy in foes:
			var p: Vector2 = enemy.pos
			if p.distance_to(hero) > 45:
				enemy.pos = p.move_toward(hero, delta * 42)
			else:
				hp -= delta * 7
		for shot in shots:
			shot.life -= delta
		shots = shots.filter(func(s): return s.life > 0)
		for i in range(foes.size() - 1, -1, -1):
			if foes[i].hp <= 0:
				foes.remove_at(i)
				score += 1
				spawn_foe(randi_range(0, 200))
		if hp <= 0:
			show_menu()
	status.text = "COCKRO • สนามฝึกออฟไลน์   HP %d   เป้าหมาย %d   %s" % [maxi(0, int(hp)), score, NAMES[weapon]]
	skill_button.text = "สกิล %ds" % ceili(skill_cd) if skill_cd > 0 else "สกิล"
	queue_redraw()

func attack() -> void:
	if cooldown > 0 or not active:
		return
	cooldown = 0.22 if weapon == 2 else 0.5
	var target: Dictionary = {}
	var nearest: float = REACH[weapon]
	for enemy in foes:
		var distance: float = hero.distance_to(enemy.pos)
		if distance < nearest:
			nearest = distance
			target = enemy
	if not target.is_empty():
		var bonus := 0
		if ads and ads.inventory.data.weapon:
			bonus = 5 + int(ads.inventory.data.level) * 3
		target.hp -= DAMAGE[weapon] + bonus
		shots.append({"from": hero, "to": target.pos, "life": 0.16, "ranged": weapon == 1 or weapon == 2})
	flash = 0.12

func use_skill() -> void:
	if not active or skill_cd > 0:
		return
	skill_cd = 5
	flash = 0.5
	for enemy in foes:
		if hero.distance_to(enemy.pos) < 230:
			enemy.hp -= 55
			shots.append({"from": hero, "to": enemy.pos, "life": 0.4, "ranged": true})

func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, 540), Color("101c29"))
	draw_rect(Rect2(24, 72, 912, 392), Color("233c40"))
	for x in range(24, 937, 48):
		draw_line(Vector2(x, 72), Vector2(x, 464), Color("2a4548"))
	for y in range(72, 465, 48):
		draw_line(Vector2(24, y), Vector2(936, y), Color("2a4548"))
	for enemy in foes:
		var p: Vector2 = enemy.pos
		draw_circle(p, 23, Color("bb645d"))
		draw_circle(p + Vector2(-7, -4), 3, Color.WHITE)
		draw_circle(p + Vector2(7, -4), 3, Color.WHITE)
		draw_rect(Rect2(p + Vector2(-24, -34), Vector2(48 * maxf(0, enemy.hp) / 60, 4)), Color("f7b267"))
	if flash > 0:
		draw_arc(hero, 65 if flash < 0.2 else 230, 0, TAU, 48, Color("ffd16b"), 4)
	draw_circle(hero + Vector2(0, 30), 28, Color(0, 0, 0, 0.3))
	if ads and ads.inventory.data.outfit:
		draw_arc(hero, 44, 0, TAU, 40, Color("65e4b5"), 4)
	draw_texture_rect(mascot, Rect2(hero - Vector2(38, 45), Vector2(76, 90)), false)
	for shot in shots:
		draw_line(shot.from, shot.to, Color("80e6ff") if shot.ranged else Color("ffd16b"), 4)
	var origin := stick_origin if stick_id >= 0 else Vector2(115, 393)
	draw_circle(origin, 62, Color(0.6, 0.8, 0.9, 0.12))
	draw_circle(origin + stick * 64, 24, Color(0.7, 0.9, 1, 0.4))


func build_shop() -> void:
	shop = PanelContainer.new()
	shop.position = Vector2(104, 40)
	shop.size = Vector2(752, 460)
	hud.add_child(shop)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	shop.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)
	var title := Label.new()
	title.text = "ดูโฆษณาแลกของ • สนามฝึก"
	col.add_child(title)
	shop_info = Label.new()
	col.add_child(shop_info)
	var rows := HBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	col.add_child(rows)
	var details := {"weapon": "โจมตี +5 • ตีบวกได้ถึง +5", "outfit": "พลังชีวิตเริ่มต้น 130", "stone": "วัตถุดิบตีบวก 1 ก้อน"}
	var icons := {"weapon": "sword", "outfit": "shield", "stone": "gem"}
	for item: String in CockroRewardInventory.CATALOG:
		var card := VBoxContainer.new()
		card.custom_minimum_size = Vector2(226, 0)
		rows.add_child(card)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/node_icons/green/icon_%s.png" % icons[item])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(0, 60)
		card.add_child(icon)
		var caption := Label.new()
		caption.text = CockroRewardInventory.CATALOG[item] + "\n" + details[item]
		caption.add_theme_font_size_override("font_size", 17)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(caption)
		var button := Button.new()
		button.text = "ดูโฆษณา 1 ครั้ง รับของ"
		button.add_theme_font_size_override("font_size", 16)
		button.custom_minimum_size.y = 52
		button.pressed.connect(func(): ads.request(item))
		card.add_child(button)
		offer_buttons[item] = button
	enhance_button = Button.new()
	enhance_button.text = "ตีบวกอาวุธ +1 • ใช้หิน 1 ก้อน • สำเร็จแน่นอน"
	enhance_button.custom_minimum_size.y = 48
	enhance_button.pressed.connect(func():
		if ads.inventory.enhance():
			ads.message = "ตีบวกสำเร็จ! อาวุธ +%d" % ads.inventory.data.level
		refresh_shop()
	)
	col.add_child(enhance_button)
	shop_message = Label.new()
	shop_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_message.custom_minimum_size = Vector2(690, 54)
	shop_message.add_theme_font_size_override("font_size", 17)
	col.add_child(shop_message)
	var close_button := Button.new()
	close_button.text = "กลับ"
	close_button.custom_minimum_size.y = 44
	close_button.pressed.connect(func():
		if ads.busy:
			return
		shop.hide()
		active = shop_was_active
		menu.visible = not active
	)
	col.add_child(close_button)
	shop.hide()
	refresh_shop()

func open_shop() -> void:
	shop_was_active = active
	active = false
	attacking = false
	stick = Vector2.ZERO
	stick_id = -1
	attack_id = -1
	menu.hide()
	shop.show()
	refresh_shop()

func refresh_shop() -> void:
	if shop_info == null:
		return
	var bag: Dictionary = ads.inventory.data
	shop_info.text = "อาวุธ: %s  |  ชุด: %s  |  หิน: %d" % ["+%d" % bag.level if bag.weapon else "ยังไม่มี", "มีแล้ว" if bag.outfit else "ยังไม่มี", bag.stones]
	shop_message.text = ads.message + "\nโฆษณาทดสอบ • ของบันทึกบนเครื่องนี้ ยังไม่เชื่อมบัญชีออนไลน์"
	for item: String in offer_buttons:
		var button: Button = offer_buttons[item]
		button.disabled = ads.busy or not ads.inventory.available(item)
		button.text = "รับแล้ว • สวมใส่อัตโนมัติ" if item != "stone" and bag[item] else "ดูโฆษณา 1 ครั้ง รับของ"
	enhance_button.disabled = ads.busy or not bag.weapon or bag.stones < 1 or bag.level >= 5
