## test_combat_initializer.gd
## Unit tests for CombatInitializer (src/combat_runtime/combat_initializer.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/combat_runtime/test_combat_initializer.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")
const CombatInitializerClass = preload("res://combat_runtime/combat_initializer.gd")

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
	_test_result_keys_present()
	_test_turn_order_sorted_descending()
	_test_all_actors_in_turn_order()
	_test_positions_preserved()
	_test_combat_ready_signal_emitted()
	_test_empty_actors()


# ---------------------------------------------------------------------------
# initialize() returns a dict with required keys
# ---------------------------------------------------------------------------
func _test_result_keys_present() -> void:
	print("_test_result_keys_present")
	var roller := DiceRollerClass.new(42)
	var ci := CombatInitializerClass.new()
	var actors: Array = [
		{"id": "hero", "dex_score": 14},
		{"id": "goblin", "dex_score": 10},
	]
	var positions: Dictionary = {"hero": Vector2i(0, 0), "goblin": Vector2i(3, 3)}
	var result: Dictionary = ci.initialize(actors, positions, roller)
	_check(result.has("turn_order"), "result has 'turn_order' key")
	_check(result.has("positions"), "result has 'positions' key")
	ci.free()


# ---------------------------------------------------------------------------
# turn_order is sorted descending by initiative total
# ---------------------------------------------------------------------------
func _test_turn_order_sorted_descending() -> void:
	print("_test_turn_order_sorted_descending")
	var roller := DiceRollerClass.new(1)
	var ci := CombatInitializerClass.new()
	var actors: Array = [
		{"id": "a", "dex_score": 10},
		{"id": "b", "dex_score": 14},
		{"id": "c", "dex_score": 8},
	]
	var result: Dictionary = ci.initialize(actors, {}, roller)
	var order: Array = result["turn_order"]
	_check(order.size() == 3, "turn order contains all 3 actors")
	for i: int in range(order.size() - 1):
		_check(
			order[i]["total"] >= order[i + 1]["total"],
			"entry %d total >= entry %d total" % [i, i + 1]
		)
	ci.free()


# ---------------------------------------------------------------------------
# All input actors appear in the turn order
# ---------------------------------------------------------------------------
func _test_all_actors_in_turn_order() -> void:
	print("_test_all_actors_in_turn_order")
	var roller := DiceRollerClass.new(7)
	var ci := CombatInitializerClass.new()
	var actors: Array = [
		{"id": "fighter", "dex_score": 12},
		{"id": "bandit", "dex_score": 12},
	]
	var positions: Dictionary = {"fighter": Vector2i(0, 0), "bandit": Vector2i(5, 0)}
	var result: Dictionary = ci.initialize(actors, positions, roller)
	var ids: Array = []
	for entry in result["turn_order"]:
		ids.append(entry["id"])
	_check(ids.has("fighter"), "fighter is in turn order")
	_check(ids.has("bandit"), "bandit is in turn order")
	ci.free()


# ---------------------------------------------------------------------------
# Starting positions are preserved unchanged in the result
# ---------------------------------------------------------------------------
func _test_positions_preserved() -> void:
	print("_test_positions_preserved")
	var roller := DiceRollerClass.new(0)
	var ci := CombatInitializerClass.new()
	var actors: Array = [{"id": "hero", "dex_score": 14}]
	var positions: Dictionary = {"hero": Vector2i(2, 4)}
	var result: Dictionary = ci.initialize(actors, positions, roller)
	_check(result["positions"].has("hero"), "positions contains hero key")
	_check(result["positions"]["hero"] == Vector2i(2, 4), "hero position preserved as Vector2i(2, 4)")
	ci.free()


# ---------------------------------------------------------------------------
# combat_ready signal is emitted with correct arguments
# ---------------------------------------------------------------------------
func _test_combat_ready_signal_emitted() -> void:
	print("_test_combat_ready_signal_emitted")
	var roller := DiceRollerClass.new(42)
	var ci := CombatInitializerClass.new()
	var actors: Array = [
		{"id": "hero", "dex_score": 14},
		{"id": "goblin", "dex_score": 10},
	]
	var positions: Dictionary = {"hero": Vector2i(0, 0), "goblin": Vector2i(3, 3)}
	var signal_turn_order: Array = []
	var signal_positions: Dictionary = {}
	ci.combat_ready.connect(func(to: Array, pos: Dictionary) -> void:
		signal_turn_order = to
		signal_positions = pos
	)
	ci.initialize(actors, positions, roller)
	_check(signal_turn_order.size() == 2, "signal received turn_order with 2 entries")
	_check(signal_positions.has("hero"), "signal received positions with hero key")
	_check(signal_positions.has("goblin"), "signal received positions with goblin key")
	ci.free()


# ---------------------------------------------------------------------------
# Empty actor list returns an empty turn order
# ---------------------------------------------------------------------------
func _test_empty_actors() -> void:
	print("_test_empty_actors")
	var roller := DiceRollerClass.new(0)
	var ci := CombatInitializerClass.new()
	var result: Dictionary = ci.initialize([], {}, roller)
	_check(result["turn_order"].size() == 0, "empty input gives empty turn order")
	ci.free()
