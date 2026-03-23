## test_target_resolver.gd
## Unit tests for TargetResolver (src/rules_engine/core/target_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_target_resolver.gd
extends SceneTree

const TargetResolverClass = preload("res://rules_engine/core/target_resolver.gd")

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
	_test_empty_candidates_returns_empty()
	_test_attacker_excluded_from_results()
	_test_candidate_within_range_included()
	_test_candidate_beyond_range_excluded()
	_test_candidate_at_exact_range_included()
	_test_candidate_one_foot_beyond_range_excluded()
	_test_multiple_candidates_filtered_by_range()
	_test_zero_range_only_same_tile_valid()
	_test_single_mode_respects_range()
	_test_aoe_mode_respects_range()
	_test_diagonal_distance_chebyshev()
	_test_all_candidates_out_of_range()
	_test_distance_ft_static_cardinal()
	_test_distance_ft_static_diagonal()


# ---------------------------------------------------------------------------
# Empty candidate list produces empty result
# ---------------------------------------------------------------------------
func _test_empty_candidates_returns_empty() -> void:
	print("_test_empty_candidates_returns_empty")
	var resolver := TargetResolverClass.new()
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, [], "player", "single"
	)
	_check(result.size() == 0, "empty candidates → empty result")


# ---------------------------------------------------------------------------
# The attacker's own position is excluded even when within range
# ---------------------------------------------------------------------------
func _test_attacker_excluded_from_results() -> void:
	print("_test_attacker_excluded_from_results")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "player", "position": Vector2i(0, 0)},
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 0, "attacker excluded from valid targets")


# ---------------------------------------------------------------------------
# A candidate within range appears in the result
# ---------------------------------------------------------------------------
func _test_candidate_within_range_included() -> void:
	print("_test_candidate_within_range_included")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "bandit", "position": Vector2i(3, 0)},  # 15 ft
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 1,                      "one valid target within range")
	_check(result[0] == Vector2i(3, 0),             "correct position returned")


# ---------------------------------------------------------------------------
# A candidate beyond range is excluded
# ---------------------------------------------------------------------------
func _test_candidate_beyond_range_excluded() -> void:
	print("_test_candidate_beyond_range_excluded")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "bandit", "position": Vector2i(7, 0)},  # 35 ft > 30 ft
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 0, "candidate beyond range excluded")


# ---------------------------------------------------------------------------
# A candidate at exactly range_ft is included (boundary is inclusive)
# ---------------------------------------------------------------------------
func _test_candidate_at_exact_range_included() -> void:
	print("_test_candidate_at_exact_range_included")
	var resolver := TargetResolverClass.new()
	# 6 tiles away = 30 ft; range = 30 → exactly on the boundary
	var candidates: Array = [
		{"id": "bandit", "position": Vector2i(6, 0)},
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 1, "candidate at exact range boundary is included")


# ---------------------------------------------------------------------------
# A candidate one foot beyond range_ft is excluded
# ---------------------------------------------------------------------------
func _test_candidate_one_foot_beyond_range_excluded() -> void:
	print("_test_candidate_one_foot_beyond_range_excluded")
	var resolver := TargetResolverClass.new()
	# 35 ft distance (7 tiles), range = 30 ft → excluded
	var candidates: Array = [
		{"id": "bandit", "position": Vector2i(7, 0)},
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 0, "candidate 1 ft beyond range boundary is excluded")


# ---------------------------------------------------------------------------
# Multiple candidates: only those within range appear in results
# ---------------------------------------------------------------------------
func _test_multiple_candidates_filtered_by_range() -> void:
	print("_test_multiple_candidates_filtered_by_range")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "bandit_1", "position": Vector2i(2, 0)},  # 10 ft — inside
		{"id": "bandit_2", "position": Vector2i(6, 0)},  # 30 ft — inside (boundary)
		{"id": "bandit_3", "position": Vector2i(8, 0)},  # 40 ft — outside
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 2,                "two of three candidates in range")
	_check(result.has(Vector2i(2, 0)),        "bandit_1 at 10 ft included")
	_check(result.has(Vector2i(6, 0)),        "bandit_2 at 30 ft included")
	_check(not result.has(Vector2i(8, 0)),    "bandit_3 at 40 ft excluded")


# ---------------------------------------------------------------------------
# Zero range: only a candidate on the same tile (distance 0) is valid
# ---------------------------------------------------------------------------
func _test_zero_range_only_same_tile_valid() -> void:
	print("_test_zero_range_only_same_tile_valid")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "bandit_a", "position": Vector2i(0, 0)},  # 0 ft — same tile
		{"id": "bandit_b", "position": Vector2i(1, 0)},  # 5 ft — adjacent
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 0, candidates, "player", "single"
	)
	_check(result.size() == 1,             "only same-tile candidate valid at range 0")
	_check(result[0] == Vector2i(0, 0),    "same-tile position returned")


# ---------------------------------------------------------------------------
# "single" mode applies range filtering
# ---------------------------------------------------------------------------
func _test_single_mode_respects_range() -> void:
	print("_test_single_mode_respects_range")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "enemy", "position": Vector2i(1, 0)},  # 5 ft — inside 5 ft melee
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 5, candidates, "player", "single"
	)
	_check(result.size() == 1, "single mode: adjacent enemy within melee range")


# ---------------------------------------------------------------------------
# "aoe" mode applies the same range filtering as "single"
# ---------------------------------------------------------------------------
func _test_aoe_mode_respects_range() -> void:
	print("_test_aoe_mode_respects_range")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "tile_a", "position": Vector2i(2, 0)},  # 10 ft — inside
		{"id": "tile_b", "position": Vector2i(9, 0)},  # 45 ft — outside
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "aoe"
	)
	_check(result.size() == 1,             "aoe mode: only in-range candidate returned")
	_check(result[0] == Vector2i(2, 0),    "in-range aoe origin returned")


# ---------------------------------------------------------------------------
# Diagonal distance uses Chebyshev (5-5-5) rule: max(|dx|, |dy|) * 5
# ---------------------------------------------------------------------------
func _test_diagonal_distance_chebyshev() -> void:
	print("_test_diagonal_distance_chebyshev")
	var resolver := TargetResolverClass.new()
	# (0,0) to (3,3) — Chebyshev = 3 tiles = 15 ft (not Euclidean ~21 ft)
	var candidates: Array = [
		{"id": "bandit", "position": Vector2i(3, 3)},
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 15, candidates, "player", "single"
	)
	_check(result.size() == 1, "diagonal 3x3 is 15 ft Chebyshev — within 15 ft range")


# ---------------------------------------------------------------------------
# All candidates out of range produces empty result
# ---------------------------------------------------------------------------
func _test_all_candidates_out_of_range() -> void:
	print("_test_all_candidates_out_of_range")
	var resolver := TargetResolverClass.new()
	var candidates: Array = [
		{"id": "bandit_1", "position": Vector2i(10, 0)},  # 50 ft
		{"id": "bandit_2", "position": Vector2i(0, 10)},  # 50 ft
	]
	var result: Array[Vector2i] = resolver.get_valid_targets(
		Vector2i(0, 0), 30, candidates, "player", "single"
	)
	_check(result.size() == 0, "all candidates out of range → empty result")


# ---------------------------------------------------------------------------
# distance_ft static helper — cardinal direction
# ---------------------------------------------------------------------------
func _test_distance_ft_static_cardinal() -> void:
	print("_test_distance_ft_static_cardinal")
	_check(TargetResolverClass.distance_ft(Vector2i(0, 0), Vector2i(4, 0)) == 20,
		"4 tiles east = 20 ft")
	_check(TargetResolverClass.distance_ft(Vector2i(0, 0), Vector2i(0, 6)) == 30,
		"6 tiles south = 30 ft")
	_check(TargetResolverClass.distance_ft(Vector2i(2, 2), Vector2i(2, 2)) == 0,
		"same tile = 0 ft")


# ---------------------------------------------------------------------------
# distance_ft static helper — diagonal uses Chebyshev
# ---------------------------------------------------------------------------
func _test_distance_ft_static_diagonal() -> void:
	print("_test_distance_ft_static_diagonal")
	# (0,0) to (3,4): Chebyshev = max(3,4) = 4 tiles = 20 ft
	_check(TargetResolverClass.distance_ft(Vector2i(0, 0), Vector2i(3, 4)) == 20,
		"diagonal (3,4) = 20 ft Chebyshev")
	# (0,0) to (5,5): Chebyshev = 5 tiles = 25 ft
	_check(TargetResolverClass.distance_ft(Vector2i(0, 0), Vector2i(5, 5)) == 25,
		"diagonal (5,5) = 25 ft Chebyshev")
