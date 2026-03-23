## test_enemy_ai.gd
## Unit tests for EnemyAI (src/rules_engine/core/enemy_ai.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_enemy_ai.gd
extends SceneTree

const EnemyAIClass      = preload("res://rules_engine/core/enemy_ai.gd")
const CombatGridClass   = preload("res://rules_engine/core/combat_grid.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")

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
	# find_nearest_target
	_test_find_nearest_target_returns_closest_player()
	_test_find_nearest_target_ignores_dead_combatants()
	_test_find_nearest_target_ignores_enemy_side()
	_test_find_nearest_target_returns_empty_when_no_candidates()
	# path_toward
	_test_path_toward_moves_toward_target()
	_test_path_toward_stops_within_melee_range()
	_test_path_toward_stops_at_blocked_tile()
	_test_path_toward_empty_when_already_in_range()
	_test_path_toward_respects_max_tiles()
	# decide — melee
	_test_decide_melee_attack_when_in_range()
	_test_decide_moves_then_melee_attacks()
	_test_decide_no_attack_when_action_unavailable()
	# decide — ranged
	_test_decide_ranged_attack_when_target_in_range()
	_test_decide_no_ranged_when_range_is_zero()
	# decide — movement only
	_test_decide_moves_toward_target_when_no_attack_possible()
	# decide — guard conditions
	_test_decide_no_op_when_enemy_not_on_grid()
	_test_decide_no_op_when_no_candidates()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_grid_with(placements: Array) -> CombatGridClass:
	var g := CombatGridClass.new()
	for entry in placements:
		g.place_combatant(entry["id"], entry["pos"])
	return g


func _make_economy(speed_ft: int, action_used: bool = false) -> ActionEconomyClass:
	var e := ActionEconomyClass.new(speed_ft)
	e.start_turn()
	if action_used:
		e.use_action()
	return e


func _player_at(id: String, pos: Vector2i, hp: int = 10) -> Dictionary:
	return {"id": id, "position": pos, "side": "player", "current_hp": hp}


# ---------------------------------------------------------------------------
# find_nearest_target
# ---------------------------------------------------------------------------

func _test_find_nearest_target_returns_closest_player() -> void:
	print("_test_find_nearest_target_returns_closest_player")
	var ai := EnemyAIClass.new()
	var enemy_pos := Vector2i(0, 0)
	var candidates := [
		_player_at("far_player",  Vector2i(10, 0)),
		_player_at("near_player", Vector2i(2, 0)),
	]
	var result: String = ai.find_nearest_target(enemy_pos, candidates)
	_check(result == "near_player", "returns the closer player target")


func _test_find_nearest_target_ignores_dead_combatants() -> void:
	print("_test_find_nearest_target_ignores_dead_combatants")
	var ai := EnemyAIClass.new()
	var enemy_pos := Vector2i(0, 0)
	var candidates := [
		_player_at("dead_player",  Vector2i(1, 0), 0),
		_player_at("alive_player", Vector2i(5, 0), 10),
	]
	var result: String = ai.find_nearest_target(enemy_pos, candidates)
	_check(result == "alive_player", "ignores dead (hp <= 0) combatants")


func _test_find_nearest_target_ignores_enemy_side() -> void:
	print("_test_find_nearest_target_ignores_enemy_side")
	var ai := EnemyAIClass.new()
	var enemy_pos := Vector2i(0, 0)
	var candidates := [
		{"id": "ally_enemy", "position": Vector2i(1, 0), "side": "enemy", "current_hp": 10},
		_player_at("player", Vector2i(5, 0)),
	]
	var result: String = ai.find_nearest_target(enemy_pos, candidates)
	_check(result == "player", "ignores enemy-side combatants")


func _test_find_nearest_target_returns_empty_when_no_candidates() -> void:
	print("_test_find_nearest_target_returns_empty_when_no_candidates")
	var ai := EnemyAIClass.new()
	var result: String = ai.find_nearest_target(Vector2i(0, 0), [])
	_check(result == "", "returns empty string when candidate list is empty")


# ---------------------------------------------------------------------------
# path_toward
# ---------------------------------------------------------------------------

func _test_path_toward_moves_toward_target() -> void:
	print("_test_path_toward_moves_toward_target")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("enemy", Vector2i(0, 0))
	# Target is 3 tiles away; melee_range_ft=5 (1 tile); max_tiles=6
	var path: Array[Vector2i] = ai.path_toward(
		Vector2i(0, 0), Vector2i(3, 0), 6, 5, grid, "enemy"
	)
	# Should stop when adjacent to target (within 5 ft = 1 tile)
	_check(path.size() == 2, "path is 2 steps to reach adjacency to tile 3")
	_check(path[0] == Vector2i(1, 0), "first step moves toward target")
	_check(path[1] == Vector2i(2, 0), "second step reaches adjacent tile")


func _test_path_toward_stops_within_melee_range() -> void:
	print("_test_path_toward_stops_within_melee_range")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("enemy", Vector2i(0, 0))
	# Already 1 tile away — within melee range of 5 ft
	var path: Array[Vector2i] = ai.path_toward(
		Vector2i(0, 0), Vector2i(1, 0), 6, 5, grid, "enemy"
	)
	_check(path.size() == 0, "returns empty path when already within melee range")


func _test_path_toward_stops_at_blocked_tile() -> void:
	print("_test_path_toward_stops_at_blocked_tile")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("enemy",   Vector2i(0, 0))
	grid.place_combatant("blocker", Vector2i(1, 0))
	var path: Array[Vector2i] = ai.path_toward(
		Vector2i(0, 0), Vector2i(3, 0), 6, 5, grid, "enemy"
	)
	_check(path.size() == 0, "stops immediately when direct path is blocked")


func _test_path_toward_empty_when_already_in_range() -> void:
	print("_test_path_toward_empty_when_already_in_range")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("enemy", Vector2i(2, 2))
	# Same position as target — distance 0 <= melee_range_ft
	var path: Array[Vector2i] = ai.path_toward(
		Vector2i(2, 2), Vector2i(2, 2), 6, 5, grid, "enemy"
	)
	_check(path.size() == 0, "returns empty path when already at target position")


func _test_path_toward_respects_max_tiles() -> void:
	print("_test_path_toward_respects_max_tiles")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()
	grid.place_combatant("enemy", Vector2i(0, 0))
	# Target is 10 tiles away; only 3 steps allowed
	var path: Array[Vector2i] = ai.path_toward(
		Vector2i(0, 0), Vector2i(10, 0), 3, 5, grid, "enemy"
	)
	_check(path.size() == 3, "path length is capped by max_tiles")


# ---------------------------------------------------------------------------
# decide — melee attack
# ---------------------------------------------------------------------------

func _test_decide_melee_attack_when_in_range() -> void:
	print("_test_decide_melee_attack_when_in_range")
	var ai := EnemyAIClass.new()
	var grid := _make_grid_with([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	var candidates := [_player_at("player", Vector2i(1, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "melee", "melee attack chosen when target is adjacent")
	_check(d["target_id"] == "player", "correct target ID selected")
	_check(d["move_path"].size() == 0, "no movement needed when already in range")


func _test_decide_moves_then_melee_attacks() -> void:
	print("_test_decide_moves_then_melee_attacks")
	var ai := EnemyAIClass.new()
	# Enemy at (0,0), player at (3,0) — 15 ft away; speed 30 ft
	var grid := _make_grid_with([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(3, 0)},
	])
	var economy := _make_economy(30)
	var candidates := [_player_at("player", Vector2i(3, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "melee", "melee attack chosen after closing the gap")
	_check(d["target_id"] == "player", "correct target ID selected after movement")
	_check(d["move_path"].size() > 0, "movement path is non-empty")
	# Final position in path should be adjacent (within 5 ft) to player at (3,0)
	var final: Vector2i = d["move_path"][d["move_path"].size() - 1]
	var dist_tiles: int = maxi(abs(final.x - 3), abs(final.y - 0))
	_check(dist_tiles <= 1, "final position is adjacent to target")


func _test_decide_no_attack_when_action_unavailable() -> void:
	print("_test_decide_no_attack_when_action_unavailable")
	var ai := EnemyAIClass.new()
	var grid := _make_grid_with([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30, true)  # action already spent
	var candidates := [_player_at("player", Vector2i(1, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "none", "no attack when action is already spent")
	_check(d["target_id"] == "", "no target ID when action unavailable")


# ---------------------------------------------------------------------------
# decide — ranged attack
# ---------------------------------------------------------------------------

func _test_decide_ranged_attack_when_target_in_range() -> void:
	print("_test_decide_ranged_attack_when_target_in_range")
	var ai := EnemyAIClass.new()
	# Enemy at (0,0), player at (6,0) — 30 ft away (out of 5 ft melee)
	var grid := _make_grid_with([
		{"id": "archer", "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(6, 0)},
	])
	var economy := _make_economy(0)  # no movement
	var candidates := [_player_at("player", Vector2i(6, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 60, "speed_ft": 30}
	var d: Dictionary = ai.decide("archer", stats, candidates, grid, economy)
	_check(d["attack_type"] == "ranged", "ranged attack chosen when target is in ranged range")
	_check(d["target_id"] == "player", "correct target ID for ranged attack")


func _test_decide_no_ranged_when_range_is_zero() -> void:
	print("_test_decide_no_ranged_when_range_is_zero")
	var ai := EnemyAIClass.new()
	var grid := _make_grid_with([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(6, 0)},
	])
	var economy := _make_economy(0)  # no movement
	var candidates := [_player_at("player", Vector2i(6, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "none", "no ranged attack when ranged_range_ft is 0")


# ---------------------------------------------------------------------------
# decide — movement only
# ---------------------------------------------------------------------------

func _test_decide_moves_toward_target_when_no_attack_possible() -> void:
	print("_test_decide_moves_toward_target_when_no_attack_possible")
	var ai := EnemyAIClass.new()
	# Enemy at (0,0), player at (10,0) — 50 ft away; speed 30 ft
	var grid := _make_grid_with([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(10, 0)},
	])
	var economy := _make_economy(30)
	var candidates := [_player_at("player", Vector2i(10, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "none", "no attack when target is out of reach after moving")
	_check(d["move_path"].size() > 0, "still moves toward target to close the gap")


# ---------------------------------------------------------------------------
# decide — guard conditions
# ---------------------------------------------------------------------------

func _test_decide_no_op_when_enemy_not_on_grid() -> void:
	print("_test_decide_no_op_when_enemy_not_on_grid")
	var ai := EnemyAIClass.new()
	var grid := CombatGridClass.new()  # empty grid
	var economy := _make_economy(30)
	var candidates := [_player_at("player", Vector2i(1, 0))]
	var stats := {"melee_range_ft": 5, "ranged_range_ft": 0, "speed_ft": 30}
	var d: Dictionary = ai.decide("orc", stats, candidates, grid, economy)
	_check(d["attack_type"] == "none", "no-op when enemy is not placed on the grid")
	_check(d["move_path"].size() == 0, "no movement when enemy is not on the grid")


func _test_decide_no_op_when_no_candidates() -> void:
	print("_test_decide_no_op_when_no_candidates")
	var ai := EnemyAIClass.new()
	var grid := _make_grid_with([{"id": "orc", "pos": Vector2i(0, 0)}])
	var economy := _make_economy(30)
	var d: Dictionary = ai.decide("orc", {}, [], grid, economy)
	_check(d["attack_type"] == "none", "no-op when candidate list is empty")
	_check(d["target_id"] == "", "no target when candidate list is empty")
