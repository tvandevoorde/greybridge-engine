## test_trigger_tile_controller.gd
## Unit tests for TriggerTileController (src/overworld/trigger_tile_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_trigger_tile_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const TriggerTileControllerClass = preload("res://overworld/trigger_tile_controller.gd")

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
	_test_no_signal_when_no_triggers_loaded()
	_test_no_signal_on_non_trigger_tile()
	_test_combat_trigger_fired_on_trigger_tile()
	_test_combat_trigger_carries_encounter_id()
	_test_combat_trigger_carries_player_tile()
	_test_trigger_fires_only_once()
	_test_load_triggers_resets_fired_state()
	_test_stepping_from_does_not_affect_result()
	_test_out_of_bounds_tile_does_not_crash()
	_test_negative_tile_does_not_crash()
	_test_multiple_trigger_tiles_each_fire_once()
	_test_null_tile_in_layer_does_not_fire()


func _make_3x3_layer_with_trigger(trigger_row: int, trigger_col: int, trigger: Dictionary) -> Array:
	var layer: Array = []
	for r in range(3):
		var row: Array = []
		for c in range(3):
			if r == trigger_row and c == trigger_col:
				row.append(trigger)
			else:
				row.append(null)
		layer.append(row)
	return layer


func _test_no_signal_when_no_triggers_loaded() -> void:
	print("_test_no_signal_when_no_triggers_loaded")
	var ctrl := TriggerTileControllerClass.new()
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 0))
	_check(fired.size() == 0, "no signal when no trigger layer loaded")
	ctrl.free()


func _test_no_signal_on_non_trigger_tile() -> void:
	print("_test_no_signal_on_non_trigger_tile")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(1, 1,
		{"type": "combat_start", "encounter_id": "test_enc"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(0, 0))
	_check(fired.size() == 0, "no signal on non-trigger tile")
	ctrl.free()


func _test_combat_trigger_fired_on_trigger_tile() -> void:
	print("_test_combat_trigger_fired_on_trigger_tile")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(1, 1,
		{"type": "combat_start", "encounter_id": "bandit_ambush"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 1))
	_check(fired.size() == 1, "combat_trigger_fired emitted when stepping onto trigger tile")
	ctrl.free()


func _test_combat_trigger_carries_encounter_id() -> void:
	print("_test_combat_trigger_carries_encounter_id")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(0, 2,
		{"type": "combat_start", "encounter_id": "wolf_pack"})
	ctrl.load_triggers(layer)
	var encounter_ids: Array[String] = []
	ctrl.combat_trigger_fired.connect(func(id: String, _tile: Vector2i) -> void:
		encounter_ids.append(id)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(2, 0))
	_check(encounter_ids.size() == 1, "combat_trigger_fired emitted once")
	_check(encounter_ids[0] == "wolf_pack", "encounter_id is wolf_pack")
	ctrl.free()


func _test_combat_trigger_carries_player_tile() -> void:
	print("_test_combat_trigger_carries_player_tile")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(2, 0,
		{"type": "combat_start", "encounter_id": "bandit_camp"})
	ctrl.load_triggers(layer)
	var tiles: Array[Vector2i] = []
	ctrl.combat_trigger_fired.connect(func(_id: String, tile: Vector2i) -> void:
		tiles.append(tile)
	)
	ctrl.on_stepped(Vector2i(1, 1), Vector2i(0, 2))
	_check(tiles.size() == 1, "combat_trigger_fired emitted once")
	_check(tiles[0] == Vector2i(0, 2), "player_tile in signal matches destination tile")
	ctrl.free()


func _test_trigger_fires_only_once() -> void:
	print("_test_trigger_fires_only_once")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(1, 1,
		{"type": "combat_start", "encounter_id": "bandit_ambush"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 1))
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 1))
	_check(fired.size() == 1, "combat trigger fires only once per encounter_id")
	ctrl.free()


func _test_load_triggers_resets_fired_state() -> void:
	print("_test_load_triggers_resets_fired_state")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(0, 0,
		{"type": "combat_start", "encounter_id": "bandit_ambush"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(0, 0))
	_check(fired.size() == 1, "first trigger fires")
	ctrl.load_triggers(layer)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(0, 0))
	_check(fired.size() == 2, "trigger fires again after load_triggers() reset")
	ctrl.free()


func _test_stepping_from_does_not_affect_result() -> void:
	print("_test_stepping_from_does_not_affect_result")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(1, 1,
		{"type": "combat_start", "encounter_id": "enc_a"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 1), Vector2i(1, 1))
	_check(fired.size() == 1, "trigger fires regardless of which tile was stepped from")
	ctrl.free()


func _test_out_of_bounds_tile_does_not_crash() -> void:
	print("_test_out_of_bounds_tile_does_not_crash")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(0, 0,
		{"type": "combat_start", "encounter_id": "enc_b"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(99, 99))
	_check(fired.size() == 0, "out-of-bounds step does not crash or fire")
	ctrl.free()


func _test_negative_tile_does_not_crash() -> void:
	print("_test_negative_tile_does_not_crash")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = _make_3x3_layer_with_trigger(0, 0,
		{"type": "combat_start", "encounter_id": "enc_c"})
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(-1, -1))
	_check(fired.size() == 0, "negative tile coordinates do not crash or fire")
	ctrl.free()


func _test_multiple_trigger_tiles_each_fire_once() -> void:
	print("_test_multiple_trigger_tiles_each_fire_once")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = [
		[{"type": "combat_start", "encounter_id": "enc_x"}, null],
		[null, {"type": "combat_start", "encounter_id": "enc_y"}],
	]
	ctrl.load_triggers(layer)
	var encounter_ids: Array[String] = []
	ctrl.combat_trigger_fired.connect(func(id: String, _tile: Vector2i) -> void:
		encounter_ids.append(id)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(0, 0))
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 1))
	_check(encounter_ids.size() == 2, "two different triggers each fire once")
	_check(encounter_ids.has("enc_x"), "enc_x fired")
	_check(encounter_ids.has("enc_y"), "enc_y fired")
	ctrl.free()


func _test_null_tile_in_layer_does_not_fire() -> void:
	print("_test_null_tile_in_layer_does_not_fire")
	var ctrl := TriggerTileControllerClass.new()
	var layer: Array = [[null, null], [null, null]]
	ctrl.load_triggers(layer)
	var fired: Array = []
	ctrl.combat_trigger_fired.connect(func(_id: String, _tile: Vector2i) -> void:
		fired.append(true)
	)
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(0, 0))
	ctrl.on_stepped(Vector2i(0, 0), Vector2i(1, 0))
	_check(fired.size() == 0, "null trigger tiles never fire")
	ctrl.free()
