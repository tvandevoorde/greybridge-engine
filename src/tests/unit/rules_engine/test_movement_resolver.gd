## test_movement_resolver.gd
## Unit tests for MovementResolver (src/rules_engine/core/movement_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_movement_resolver.gd
extends SceneTree

const CombatGridClass = preload("res://rules_engine/core/combat_grid.gd")
const MovementResolverClass = preload("res://rules_engine/core/movement_resolver.gd")

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
	_test_empty_path_succeeds_with_zero_cost()
	_test_single_step_deducts_five_feet()
	_test_multi_step_deducts_correct_cost()
	_test_diagonal_step_costs_five_feet()
	_test_exact_budget_path_succeeds()
	_test_path_exceeding_budget_fails()
	_test_partial_budget_prevents_second_step()
	_test_path_blocked_by_occupied_tile()
	_test_path_blocked_at_first_tile()
	_test_oa_triggers_when_leaving_hostile_reach()
	_test_no_oa_when_staying_within_reach()
	_test_no_oa_when_hostile_not_on_grid()
	_test_oa_triggers_only_on_exit_step()
	_test_oa_from_multiple_hostiles()
	_test_result_keys_always_present()
	_test_feet_per_tile_constant()


# ---------------------------------------------------------------------------
# Empty path
# ---------------------------------------------------------------------------
func _test_empty_path_succeeds_with_zero_cost() -> void:
	print("_test_empty_path_succeeds_with_zero_cost")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	var result = resolver.resolve([], Vector2i(0, 0), 30, grid, "a", [])
	_check(result["success"] == true, "empty path succeeds")
	_check(result["tiles_moved"] == 0, "zero tiles moved")
	_check(result["cost_ft"] == 0, "zero ft cost")
	_check(result["blocked_at"] == null, "blocked_at is null")
	_check(result["reason"] == "", "reason is empty")
	_check(result["oa_triggers"].size() == 0, "no OA triggers")


# ---------------------------------------------------------------------------
# Movement cost: 5 ft per tile
# ---------------------------------------------------------------------------
func _test_single_step_deducts_five_feet() -> void:
	print("_test_single_step_deducts_five_feet")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	var result = resolver.resolve(
		[Vector2i(1, 0)], Vector2i(0, 0), 30, grid, "a", []
	)
	_check(result["success"] == true, "single step succeeds")
	_check(result["tiles_moved"] == 1, "1 tile moved")
	_check(result["cost_ft"] == 5, "costs 5 ft")


func _test_multi_step_deducts_correct_cost() -> void:
	print("_test_multi_step_deducts_correct_cost")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	var path: Array = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	var result = resolver.resolve(path, Vector2i(0, 0), 30, grid, "a", [])
	_check(result["success"] == true, "3-step path succeeds")
	_check(result["tiles_moved"] == 3, "3 tiles moved")
	_check(result["cost_ft"] == 15, "costs 15 ft")


# ---------------------------------------------------------------------------
# Diagonal movement: 5-5-5 rule (same cost as cardinal)
# ---------------------------------------------------------------------------
func _test_diagonal_step_costs_five_feet() -> void:
	print("_test_diagonal_step_costs_five_feet")
	var resolver := MovementResolverClass.new()
	var grid := CombatGrid.new()
	grid.place_combatant("a", Vector2i(0, 0))
	var result = resolver.resolve(
		[Vector2i(1, 1)], Vector2i(0, 0), 30, grid, "a", []
	)
	_check(result["success"] == true, "diagonal step succeeds")
	_check(result["cost_ft"] == 5, "diagonal step costs 5 ft (5-5-5 rule)")


# ---------------------------------------------------------------------------
# Movement budget enforcement
# ---------------------------------------------------------------------------
func _test_exact_budget_path_succeeds() -> void:
	print("_test_exact_budget_path_succeeds")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	# 6 steps = 30 ft = exactly the budget
	var path: Array = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0)
	]
	var result = resolver.resolve(path, Vector2i(0, 0), 30, grid, "a", [])
	_check(result["success"] == true, "path costing exactly 30 ft succeeds with 30 ft budget")
	_check(result["cost_ft"] == 30, "cost is 30 ft")


func _test_path_exceeding_budget_fails() -> void:
	print("_test_path_exceeding_budget_fails")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	# 7 steps = 35 ft > 30 ft budget
	var path: Array = [
		Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0),
		Vector2i(4, 0), Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)
	]
	var result = resolver.resolve(path, Vector2i(0, 0), 30, grid, "a", [])
	_check(result["success"] == false, "path exceeding budget fails")
	_check(result["reason"] == "insufficient_movement", "reason is insufficient_movement")
	_check(result["blocked_at"] == Vector2i(7, 0), "blocked_at points to over-budget tile")
	_check(result["tiles_moved"] == 6, "6 tiles moved before failure")
	_check(result["cost_ft"] == 30, "cost reflects tiles moved before failure")


func _test_partial_budget_prevents_second_step() -> void:
	print("_test_partial_budget_prevents_second_step")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	# Only 5 ft remaining — second step should be denied
	var result = resolver.resolve(
		[Vector2i(1, 0), Vector2i(2, 0)], Vector2i(0, 0), 5, grid, "a", []
	)
	_check(result["success"] == false, "second step denied when budget is 5 ft")
	_check(result["reason"] == "insufficient_movement", "reason is insufficient_movement")
	_check(result["tiles_moved"] == 1, "1 tile moved before failure")


# ---------------------------------------------------------------------------
# Tile occupancy blocking
# ---------------------------------------------------------------------------
func _test_path_blocked_by_occupied_tile() -> void:
	print("_test_path_blocked_by_occupied_tile")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	grid.place_combatant("blocker", Vector2i(2, 0))
	var path: Array = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
	var result = resolver.resolve(path, Vector2i(0, 0), 30, grid, "a", [])
	_check(result["success"] == false, "path blocked by occupied tile fails")
	_check(result["reason"] == "tile_occupied", "reason is tile_occupied")
	_check(result["blocked_at"] == Vector2i(2, 0), "blocked_at is the occupied tile")
	_check(result["tiles_moved"] == 1, "1 tile moved before block")


func _test_path_blocked_at_first_tile() -> void:
	print("_test_path_blocked_at_first_tile")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	grid.place_combatant("wall", Vector2i(1, 0))
	var result = resolver.resolve(
		[Vector2i(1, 0)], Vector2i(0, 0), 30, grid, "a", []
	)
	_check(result["success"] == false, "first tile occupied blocks immediately")
	_check(result["tiles_moved"] == 0, "0 tiles moved when blocked at first step")
	_check(result["cost_ft"] == 0, "0 ft cost when blocked at first step")


# ---------------------------------------------------------------------------
# Opportunity attack triggers
# ---------------------------------------------------------------------------
func _test_oa_triggers_when_leaving_hostile_reach() -> void:
	print("_test_oa_triggers_when_leaving_hostile_reach")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("mover",  Vector2i(1, 0))
	grid.place_combatant("hostile", Vector2i(0, 0))  # adjacent (reach 5 ft)
	# Mover steps from (1,0) to (2,0): leaves hostile's 5 ft reach
	var hostiles: Array = [{"id": "hostile", "reach_ft": 5}]
	var result = resolver.resolve(
		[Vector2i(2, 0)], Vector2i(1, 0), 30, grid, "mover", hostiles
	)
	_check(result["success"] == true, "path succeeds")
	_check(result["oa_triggers"].size() == 1, "one OA trigger")
	var trigger = result["oa_triggers"][0]
	_check(trigger["from"] == Vector2i(1, 0), "OA trigger from is departure tile")
	_check(trigger["to"] == Vector2i(2, 0), "OA trigger to is arrival tile")
	_check(trigger["threatening_id"] == "hostile", "threatening_id is hostile combatant")


func _test_no_oa_when_staying_within_reach() -> void:
	print("_test_no_oa_when_staying_within_reach")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("mover",  Vector2i(1, 0))
	grid.place_combatant("hostile", Vector2i(0, 0))  # 5 ft away
	# Hostile has 10 ft reach — mover steps to (2,0) which is still within 10 ft
	var hostiles: Array = [{"id": "hostile", "reach_ft": 10}]
	var result = resolver.resolve(
		[Vector2i(2, 0)], Vector2i(1, 0), 30, grid, "mover", hostiles
	)
	_check(result["success"] == true, "path succeeds")
	_check(result["oa_triggers"].size() == 0, "no OA when destination is still within reach")


func _test_no_oa_when_hostile_not_on_grid() -> void:
	print("_test_no_oa_when_hostile_not_on_grid")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("mover", Vector2i(0, 0))
	# Hostile listed but NOT placed on the grid
	var hostiles: Array = [{"id": "ghost", "reach_ft": 5}]
	var result = resolver.resolve(
		[Vector2i(1, 0)], Vector2i(0, 0), 30, grid, "mover", hostiles
	)
	_check(result["oa_triggers"].size() == 0, "no OA when hostile has no grid position")


func _test_oa_triggers_only_on_exit_step() -> void:
	print("_test_oa_triggers_only_on_exit_step")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("mover",  Vector2i(1, 0))
	grid.place_combatant("hostile", Vector2i(0, 0))
	# 3-step path; only step (1,0)->(2,0) exits the 5 ft reach
	var path: Array = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 0)]
	var hostiles: Array = [{"id": "hostile", "reach_ft": 5}]
	var result = resolver.resolve(path, Vector2i(1, 0), 30, grid, "mover", hostiles)
	_check(result["oa_triggers"].size() == 1, "OA triggers exactly once (only on exit step)")
	_check(result["oa_triggers"][0]["from"] == Vector2i(1, 0), "exit from tile (1,0)")


func _test_oa_from_multiple_hostiles() -> void:
	print("_test_oa_from_multiple_hostiles")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	# hostile1(0,0) and hostile2(0,1) are both adjacent to mover(1,0).
	# Destination (2,0): Chebyshev from (0,0)=10 ft and from (0,1)=10 ft — outside 5 ft reach.
	grid.place_combatant("mover",    Vector2i(1, 0))
	grid.place_combatant("hostile1", Vector2i(0, 0))
	grid.place_combatant("hostile2", Vector2i(0, 1))
	var hostiles: Array = [
		{"id": "hostile1", "reach_ft": 5},
		{"id": "hostile2", "reach_ft": 5}
	]
	var result = resolver.resolve(
		[Vector2i(2, 0)], Vector2i(1, 0), 30, grid, "mover", hostiles
	)
	_check(result["oa_triggers"].size() == 2, "OA triggers from two hostile combatants")


# ---------------------------------------------------------------------------
# Result dictionary always contains required keys
# ---------------------------------------------------------------------------
func _test_result_keys_always_present() -> void:
	print("_test_result_keys_always_present")
	var resolver := MovementResolverClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("a", Vector2i(0, 0))
	var result = resolver.resolve([], Vector2i(0, 0), 30, grid, "a", [])
	_check(result.has("success"), "result has 'success'")
	_check(result.has("tiles_moved"), "result has 'tiles_moved'")
	_check(result.has("cost_ft"), "result has 'cost_ft'")
	_check(result.has("blocked_at"), "result has 'blocked_at'")
	_check(result.has("reason"), "result has 'reason'")
	_check(result.has("oa_triggers"), "result has 'oa_triggers'")


# ---------------------------------------------------------------------------
# FEET_PER_TILE constant
# ---------------------------------------------------------------------------
func _test_feet_per_tile_constant() -> void:
	print("_test_feet_per_tile_constant")
	_check(MovementResolverClass.FEET_PER_TILE == 5, "1 tile equals 5 feet")
