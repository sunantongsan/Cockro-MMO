extends Node
## Exercises the original client, map replication and movement against a local stack.

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var path: String = CmdlineUtils.get_parsed_args().get("handoff", "")
	var handoff: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var client: Node = get_tree().root.get_node("Client")
	client.connect_to_server(handoff.address, int(handoff.port), handoff["auth-token"])
	for i in range(300):
		await get_tree().create_timer(0.1).timeout
		if InstanceClient.local_player != null:
			break
	if InstanceClient.local_player == null:
		push_error("Original world did not spawn the player")
		get_tree().quit(1)
		return
	var player: LocalPlayer = InstanceClient.local_player
	var start: Vector2 = player.position
	Input.action_press("player_move_right")
	await get_tree().create_timer(1.0).timeout
	Input.action_release("player_move_right")
	if player.position.distance_to(start) < 1.0:
		push_error("Original player failed to move")
		get_tree().quit(1)
		return
	print("CLASSIC_SMOKE_PASS: original map loaded, player replicated and movement works")
	client.close_connection()
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)
