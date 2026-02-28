## test_overworld_controller.gd
## Unit tests for OverworldController (src/overworld/overworld_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/overworld/test_overworld_controller.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DiceRoller = preload("res://rules_engine/core/dice_roller.gd")
const OverworldController = preload("res://overworld/overworld_controller.gd")

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
	_test_controls_unlocked_by_default()
	_test_lock_controls()
	_test_unlock_controls()
	_test_controls_locked_changed_signal()
	_test_start_combat_locks_controls()
	_test_start_combat_emits_combat_ready()
	_test_start_combat_turn_order_sorted()


# ---------------------------------------------------------------------------
# controls_locked is false by default
# ---------------------------------------------------------------------------
func _test_controls_unlocked_by_default() -> void:
	print("_test_controls_unlocked_by_default")
	var oc := OverworldController.new()
	_check(oc.controls_locked == false, "controls_locked is false by default")
	oc.free()


# ---------------------------------------------------------------------------
# lock_controls() sets controls_locked to true
# ---------------------------------------------------------------------------
func _test_lock_controls() -> void:
	print("_test_lock_controls")
	var oc := OverworldController.new()
	oc.lock_controls()
	_check(oc.controls_locked == true, "controls_locked is true after lock_controls()")
	oc.free()


# ---------------------------------------------------------------------------
# unlock_controls() sets controls_locked to false
# ---------------------------------------------------------------------------
func _test_unlock_controls() -> void:
	print("_test_unlock_controls")
	var oc := OverworldController.new()
	oc.lock_controls()
	oc.unlock_controls()
	_check(oc.controls_locked == false, "controls_locked is false after unlock_controls()")
	oc.free()


# ---------------------------------------------------------------------------
# controls_locked_changed emits the correct values
# ---------------------------------------------------------------------------
func _test_controls_locked_changed_signal() -> void:
	print("_test_controls_locked_changed_signal")
	var oc := OverworldController.new()
	var signal_values: Array = []
	oc.controls_locked_changed.connect(func(locked: bool) -> void:
		signal_values.append(locked)
	)
	oc.lock_controls()
	oc.unlock_controls()
	_check(signal_values.size() == 2, "controls_locked_changed emitted twice")
	_check(signal_values[0] == true, "first emission: locked=true")
	_check(signal_values[1] == false, "second emission: locked=false")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() locks overworld controls
# ---------------------------------------------------------------------------
func _test_start_combat_locks_controls() -> void:
	print("_test_start_combat_locks_controls")
	var oc := OverworldController.new()
	var roller := DiceRoller.new(42)
	var actors: Array = [{"id": "hero", "dex_score": 14}]
	var positions: Dictionary = {"hero": Vector2i(0, 0)}
	oc.start_combat(actors, positions, roller)
	_check(oc.controls_locked == true, "controls_locked is true after start_combat()")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() emits combat_ready with turn_order and positions
# ---------------------------------------------------------------------------
func _test_start_combat_emits_combat_ready() -> void:
	print("_test_start_combat_emits_combat_ready")
	var oc := OverworldController.new()
	var roller := DiceRoller.new(10)
	var actors: Array = [
		{"id": "fighter", "dex_score": 12},
		{"id": "bandit", "dex_score": 10},
	]
	var positions: Dictionary = {"fighter": Vector2i(0, 0), "bandit": Vector2i(4, 0)}
	var received_order: Array = []
	var received_positions: Dictionary = {}
	oc.combat_ready.connect(func(to: Array, pos: Dictionary) -> void:
		received_order = to
		received_positions = pos
	)
	oc.start_combat(actors, positions, roller)
	_check(received_order.size() == 2, "combat_ready received turn_order with 2 entries")
	_check(received_positions.has("fighter"), "combat_ready received positions with fighter key")
	_check(received_positions.has("bandit"), "combat_ready received positions with bandit key")
	oc.free()


# ---------------------------------------------------------------------------
# start_combat() turn order is sorted descending by initiative total
# ---------------------------------------------------------------------------
func _test_start_combat_turn_order_sorted() -> void:
	print("_test_start_combat_turn_order_sorted")
	var oc := OverworldController.new()
	var roller := DiceRoller.new(5)
	var actors: Array = [
		{"id": "a", "dex_score": 10},
		{"id": "b", "dex_score": 14},
		{"id": "c", "dex_score": 8},
	]
	var received_order: Array = []
	oc.combat_ready.connect(func(to: Array, _pos: Dictionary) -> void:
		received_order = to
	)
	oc.start_combat(actors, {}, roller)
	_check(received_order.size() == 3, "turn order has 3 entries")
	for i: int in range(received_order.size() - 1):
		_check(
			received_order[i]["total"] >= received_order[i + 1]["total"],
			"entry %d total >= entry %d total" % [i, i + 1]
		)
	oc.free()
