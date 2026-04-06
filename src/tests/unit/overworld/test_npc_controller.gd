## test_npc_controller.gd
## Unit tests for NpcController (src/overworld/npc_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_npc_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const NpcControllerClass = preload("res://overworld/npc_controller.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	_run_all_tests()
	print("\nResults: %d passed, %d failed" % [_pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
		_pass_count += 1
	else:
		print("  FAIL: %s" % description)
		_fail_count += 1


func _run_all_tests() -> void:
	_test_load_npcs_emits_npc_blocked_tiles_changed()
	_test_load_npcs_blocked_tiles_excludes_pass_through()
	_test_load_npcs_blocked_tiles_includes_solid()
	_test_try_interact_emits_dialogue_started()
	_test_try_interact_uses_facing_direction()
	_test_try_interact_no_signal_when_no_npc()
	_test_try_interact_no_signal_when_dialogue_id_empty()
	_test_update_player_state_affects_try_interact()
	_test_apply_dialogue_outcome_emits_quest_flag_set()
	_test_apply_dialogue_outcome_emits_once_per_flag()
	_test_apply_dialogue_outcome_empty_flags_emits_nothing()
	_test_try_interact_blocked_when_required_flags_not_met()
	_test_try_interact_allowed_when_required_flags_met()
	_test_set_quest_flags_updates_immediately()
	_test_try_interact_no_required_flags_always_allowed()


# ---------------------------------------------------------------------------
# load_npcs — emits npc_blocked_tiles_changed
# ---------------------------------------------------------------------------
func _test_load_npcs_emits_npc_blocked_tiles_changed() -> void:
	print("_test_load_npcs_emits_npc_blocked_tiles_changed")
	var ctrl := NpcControllerClass.new()
	var events: Array = []
	ctrl.npc_blocked_tiles_changed.connect(func(tiles: Array) -> void:
		events.append(tiles)
	)
	ctrl.load_npcs([
		{"npc_id": "guard", "position": {"x": 2, "y": 3},
			"dialogue_id": "guard_talk", "pass_through": false, "quest_flags": {}}
	])
	_check(events.size() == 1, "npc_blocked_tiles_changed emitted once after load_npcs")
	ctrl.free()


func _test_load_npcs_blocked_tiles_excludes_pass_through() -> void:
	print("_test_load_npcs_blocked_tiles_excludes_pass_through")
	var ctrl := NpcControllerClass.new()
	var events: Array = []
	ctrl.npc_blocked_tiles_changed.connect(func(tiles: Array) -> void:
		events.append(tiles.duplicate())
	)
	ctrl.load_npcs([
		{"npc_id": "spirit", "position": {"x": 5, "y": 5},
			"dialogue_id": "spirit_talk", "pass_through": true, "quest_flags": {}}
	])
	_check(events.size() == 1, "npc_blocked_tiles_changed emitted once for pass-through NPC")
	_check(events[0].size() == 0,
		"pass-through NPC not included in blocked tiles signal")
	ctrl.free()


func _test_load_npcs_blocked_tiles_includes_solid() -> void:
	print("_test_load_npcs_blocked_tiles_includes_solid")
	var ctrl := NpcControllerClass.new()
	var events: Array = []
	ctrl.npc_blocked_tiles_changed.connect(func(tiles: Array) -> void:
		events.append(tiles.duplicate())
	)
	ctrl.load_npcs([
		{"npc_id": "merchant", "position": {"x": 4, "y": 3},
			"dialogue_id": "merchant_greeting", "pass_through": false, "quest_flags": {}}
	])
	_check(events.size() == 1, "npc_blocked_tiles_changed emitted once for solid NPC")
	_check(events[0].size() == 1, "solid NPC position included in blocked tiles")
	_check(events[0][0] == Vector2i(4, 3), "blocked tile matches NPC position")
	ctrl.free()


# ---------------------------------------------------------------------------
# try_interact — emits dialogue_started for the NPC in front
# ---------------------------------------------------------------------------
func _test_try_interact_emits_dialogue_started() -> void:
	print("_test_try_interact_emits_dialogue_started")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "innkeeper", "position": {"x": 3, "y": 4},
			"dialogue_id": "inn_welcome", "pass_through": false, "quest_flags": {}}
	])
	# Player at (3,3) facing south — NPC is at (3,4).
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	var npc_ids: Array[String] = []
	var dlg_ids: Array[String] = []
	ctrl.dialogue_started.connect(func(npc_id: String, dialogue_id: String) -> void:
		npc_ids.append(npc_id)
		dlg_ids.append(dialogue_id)
	)
	ctrl.try_interact()
	_check(npc_ids.size() == 1, "dialogue_started emitted once")
	_check(npc_ids[0] == "innkeeper", "dialogue_started carries correct npc_id")
	_check(dlg_ids[0] == "inn_welcome", "dialogue_started carries correct dialogue_id")
	ctrl.free()


func _test_try_interact_uses_facing_direction() -> void:
	print("_test_try_interact_uses_facing_direction")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "guard_north", "position": {"x": 3, "y": 2},
			"dialogue_id": "guard_north_talk", "pass_through": false, "quest_flags": {}},
		{"npc_id": "guard_south", "position": {"x": 3, "y": 4},
			"dialogue_id": "guard_south_talk", "pass_through": false, "quest_flags": {}}
	])
	# Player at (3,3) facing north — should interact with guard_north.
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, -1))
	var npc_ids: Array[String] = []
	ctrl.dialogue_started.connect(func(npc_id: String, _dlg: String) -> void:
		npc_ids.append(npc_id)
	)
	ctrl.try_interact()
	_check(npc_ids.size() == 1, "dialogue_started emitted once")
	_check(npc_ids[0] == "guard_north", "try_interact targets tile in facing direction")
	ctrl.free()


func _test_try_interact_no_signal_when_no_npc() -> void:
	print("_test_try_interact_no_signal_when_no_npc")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([])
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	ctrl.try_interact()
	_check(events.size() == 0,
		"dialogue_started not emitted when no NPC at target tile")
	ctrl.free()


func _test_try_interact_no_signal_when_dialogue_id_empty() -> void:
	print("_test_try_interact_no_signal_when_dialogue_id_empty")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "silent_npc", "position": {"x": 3, "y": 4},
			"dialogue_id": "", "pass_through": false, "quest_flags": {}}
	])
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	ctrl.try_interact()
	_check(events.size() == 0,
		"dialogue_started not emitted for NPC with empty dialogue_id")
	ctrl.free()


# ---------------------------------------------------------------------------
# update_player_state affects try_interact targeting
# ---------------------------------------------------------------------------
func _test_update_player_state_affects_try_interact() -> void:
	print("_test_update_player_state_affects_try_interact")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "shopkeeper", "position": {"x": 5, "y": 3},
			"dialogue_id": "shop_open", "pass_through": false, "quest_flags": {}}
	])
	# Initial state: player at (3,3) facing south — NPC at (5,3) is not in front.
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	ctrl.try_interact()
	_check(events.size() == 0, "no interaction when NPC is not directly in front")

	# Now reposition the player to face the shopkeeper.
	ctrl.update_player_state(Vector2i(4, 3), Vector2i(1, 0))
	ctrl.try_interact()
	_check(events.size() == 1,
		"dialogue_started emitted after update_player_state points at NPC")
	ctrl.free()


# ---------------------------------------------------------------------------
# apply_dialogue_outcome — emits quest_flag_set
# ---------------------------------------------------------------------------
func _test_apply_dialogue_outcome_emits_quest_flag_set() -> void:
	print("_test_apply_dialogue_outcome_emits_quest_flag_set")
	var ctrl := NpcControllerClass.new()
	var flag_names: Array[String] = []
	var flag_values: Array = []
	ctrl.quest_flag_set.connect(func(name: String, value: Variant) -> void:
		flag_names.append(name)
		flag_values.append(value)
	)
	ctrl.apply_dialogue_outcome("elder", {"quest_started": true})
	_check(flag_names.size() == 1, "quest_flag_set emitted once")
	_check(flag_names[0] == "quest_started", "correct flag name emitted")
	_check(flag_values[0] == true, "correct flag value emitted")
	ctrl.free()


func _test_apply_dialogue_outcome_emits_once_per_flag() -> void:
	print("_test_apply_dialogue_outcome_emits_once_per_flag")
	var ctrl := NpcControllerClass.new()
	var events: Array = []
	ctrl.quest_flag_set.connect(func(_n: String, _v: Variant) -> void:
		events.append(true)
	)
	ctrl.apply_dialogue_outcome("merchant",
		{"met_merchant": true, "shop_unlocked": true, "coin_spent": 5})
	_check(events.size() == 3,
		"quest_flag_set emitted once per flag (3 flags → 3 emissions)")
	ctrl.free()


func _test_apply_dialogue_outcome_empty_flags_emits_nothing() -> void:
	print("_test_apply_dialogue_outcome_empty_flags_emits_nothing")
	var ctrl := NpcControllerClass.new()
	var events: Array = []
	ctrl.quest_flag_set.connect(func(_n: String, _v: Variant) -> void:
		events.append(true)
	)
	ctrl.apply_dialogue_outcome("silent_npc", {})
	_check(events.size() == 0, "no quest_flag_set emitted for empty flags dictionary")
	ctrl.free()


# ---------------------------------------------------------------------------
# try_interact — required_flags gating
# ---------------------------------------------------------------------------
func _test_try_interact_blocked_when_required_flags_not_met() -> void:
	print("_test_try_interact_blocked_when_required_flags_not_met")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "gatekeeper", "position": {"x": 3, "y": 4},
			"dialogue_id": "gate_talk", "pass_through": false,
			"quest_flags": {}, "required_flags": {"gate_key_found": true}}
	])
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	# Quest flags do not satisfy requirement yet.
	ctrl.try_interact()
	_check(events.size() == 0,
		"dialogue_started not emitted when NPC required_flags not met")
	ctrl.free()


func _test_try_interact_allowed_when_required_flags_met() -> void:
	print("_test_try_interact_allowed_when_required_flags_met")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "gatekeeper", "position": {"x": 3, "y": 4},
			"dialogue_id": "gate_talk", "pass_through": false,
			"quest_flags": {}, "required_flags": {"gate_key_found": true}}
	])
	ctrl.update_player_state(Vector2i(3, 3), Vector2i(0, 1))
	ctrl.set_quest_flags({"gate_key_found": true})
	var npc_ids: Array[String] = []
	ctrl.dialogue_started.connect(func(npc_id: String, _d: String) -> void:
		npc_ids.append(npc_id)
	)
	ctrl.try_interact()
	_check(npc_ids.size() == 1, "dialogue_started emitted when required_flags are met")
	_check(npc_ids[0] == "gatekeeper", "correct npc_id emitted")
	ctrl.free()


func _test_set_quest_flags_updates_immediately() -> void:
	print("_test_set_quest_flags_updates_immediately")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "guard", "position": {"x": 2, "y": 3},
			"dialogue_id": "guard_talk", "pass_through": false,
			"quest_flags": {}, "required_flags": {"pass_granted": true}}
	])
	ctrl.update_player_state(Vector2i(2, 2), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	# First attempt — flag not set.
	ctrl.try_interact()
	_check(events.size() == 0, "no dialogue before set_quest_flags")
	# Set the flag — immediately enables interaction.
	ctrl.set_quest_flags({"pass_granted": true})
	ctrl.try_interact()
	_check(events.size() == 1, "dialogue starts after set_quest_flags sets required flag")
	ctrl.free()


func _test_try_interact_no_required_flags_always_allowed() -> void:
	print("_test_try_interact_no_required_flags_always_allowed")
	var ctrl := NpcControllerClass.new()
	ctrl.load_npcs([
		{"npc_id": "merchant", "position": {"x": 4, "y": 3},
			"dialogue_id": "merchant_hello", "pass_through": false,
			"quest_flags": {}}
	])
	ctrl.update_player_state(Vector2i(4, 2), Vector2i(0, 1))
	var events: Array = []
	ctrl.dialogue_started.connect(func(_n: String, _d: String) -> void:
		events.append(true)
	)
	ctrl.try_interact()
	_check(events.size() == 1,
		"NPC with no required_flags is always accessible")
