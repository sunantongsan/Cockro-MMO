extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var bag := CockroRewardInventory.new()
	bag.save_path = "user://reward_test_%d.json" % Time.get_ticks_usec()
	assert(not bag.grant("unknown", "a"))
	assert(not bag.grant("weapon", ""))
	assert(bag.grant("weapon", "a"))
	assert(not bag.grant("weapon", "b"))
	assert(not bag.grant("stone", "a"))
	assert(not bag.enhance())
	assert(bag.grant("outfit", "b"))
	for i in range(6):
		assert(bag.grant("stone", "stone-%d" % i))
	for i in range(5):
		assert(bag.enhance())
	assert(not bag.enhance())
	assert(bag.data.stones == 1 and bag.data.level == 5)
	var reloaded := CockroRewardInventory.new()
	reloaded.save_path = bag.save_path
	reloaded.load_data()
	assert(reloaded.data == bag.data)
	var ads = load("res://source/cockro/reward_ads.gd").new()
	root.add_child(ads)
	ads.inventory = bag
	var before = bag.data.duplicate(true)
	ads.finish("load failed")
	assert(bag.data == before)
	ads.request("stone") # Desktop cannot simulate a successful native ad.
	assert(bag.data == before)
	DirAccess.remove_absolute(bag.save_path)
	ads.queue_free()
	await process_frame
	print("PASS: invalid/duplicate rewards, ownership, material consumption, cap, persistence, ad failure/no native reward")
	quit()
