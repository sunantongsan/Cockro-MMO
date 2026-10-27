extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://source/cockro/training.tscn").instantiate()
	root.add_child(scene)
	scene.set_process(false)
	scene.start_training()
	assert(scene.active and scene.foes.size() == 6)
	for w in range(5):
		scene.weapon = w
		scene.foes.clear()
		scene.foes.append({"pos": scene.hero + Vector2(60, 0), "hp": 100.0})
		scene.cooldown = 0
		scene.attack()
		assert(scene.foes[0].hp < 100)
		var hp = scene.foes[0].hp
		scene.attack()
		assert(scene.foes[0].hp == hp, "Cooldown must prevent repeated damage")
	scene.skill_cd = 0
	scene.use_skill()
	assert(scene.skill_cd == 5)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = Vector2(100, 300)
	touch.pressed = true
	scene._input(touch)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(160, 300)
	scene._input(drag)
	var before = scene.hero
	scene._process(0.1)
	assert(scene.hero.x > before.x)
	touch.pressed = false
	scene._input(touch)
	assert(scene.stick == Vector2.ZERO)
	scene.attacking = true
	scene._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(not scene.attacking)
	scene.hp = 0
	scene._process(0.1)
	assert(not scene.active)
	scene.start_training()
	assert(scene.hp == 100 and scene.score == 0)
	print("PASS: five weapons, cooldown, skill, touch movement/release, focus loss, defeat/restart")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("/tmp/cockro-training.png")
		scene.show_menu()
		await process_frame
		await process_frame
		root.get_texture().get_image().save_png("/tmp/cockro-menu.png")
	scene.queue_free()
	await process_frame
	quit()
