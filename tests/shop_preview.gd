extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://source/cockro/training.tscn").instantiate()
	root.add_child(scene)
	scene.open_shop()
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/tmp/cockro-reward-shop.png")
	scene.queue_free()
	await process_frame
	quit()
