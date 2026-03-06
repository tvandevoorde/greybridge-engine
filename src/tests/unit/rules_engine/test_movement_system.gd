## test_movement_system.gd
## Unit tests for MovementSystem (src/rules_engine/core/movement_system.gd).
##
## Covers all acceptance criteria from the "integrate opportunity attacks into
## movement system" issue:
##   - Trigger when actor leaves melee reach
##   - Check if enemy has reaction available
##   - Calls rules engine to resolve attack
##   - Reaction consumed on use
##   - Disengage prevents trigger
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_movement_system.gd
extends SceneTree

const MovementSystemClass = preload("res://rules_engine/core/movement_system.gd")
const ActionEconomyClass  = preload("res://rules_engine/core/action_economy.gd")

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


## Build an ActionEconomy already past start_turn() so all slots are available.
func _fresh_economy(speed_ft: int = 30) -> ActionEconomyClass:
	var e := ActionEconomyClass.new(speed_ft)
	e.start_turn()
	return e


func _run_all_tests() -> void:
	# is_within_reach
	_test_same_tile_is_within_reach()
	_test_adjacent_tile_is_within_reach()
	_test_diagonal_tile_is_within_reach()
	_test_two_tiles_away_is_out_of_reach()
	_test_diagonal_two_tiles_is_out_of_reach()
	_test_custom_reach_10ft()

	# process_leave_reach — happy path
	_test_oa_triggers_and_returns_attack_result()
	_test_oa_triggers_consumes_reaction()
	_test_oa_hit_on_high_roll()
	_test_oa_miss_on_low_roll()
	_test_oa_critical_on_natural_20()

	# process_leave_reach — reaction already spent
	_test_oa_blocked_when_reaction_spent()
	_test_reaction_not_consumed_when_oa_blocked()

	# process_leave_reach — target disengaging
	_test_oa_blocked_when_target_disengaging()
	_test_reaction_not_consumed_when_target_disengaging()

	# process_leave_reach — result keys always present
	_test_result_keys_present_on_trigger()
	_test_result_keys_present_on_no_trigger()

	# Only one reaction per round
	_test_reaction_cannot_be_used_twice_same_round()


# ---------------------------------------------------------------------------
# is_within_reach — reach detection
# ---------------------------------------------------------------------------

func _test_same_tile_is_within_reach() -> void:
	print("_test_same_tile_is_within_reach")
	var ms := MovementSystemClass.new()
	var pos := {"x": 3, "y": 3}
	_check(ms.is_within_reach(pos, pos), "same tile is within 5-ft reach")


func _test_adjacent_tile_is_within_reach() -> void:
	print("_test_adjacent_tile_is_within_reach")
	var ms := MovementSystemClass.new()
	_check(ms.is_within_reach({"x": 0, "y": 0}, {"x": 1, "y": 0}),
		"horizontally adjacent tile is within 5-ft reach")
	_check(ms.is_within_reach({"x": 0, "y": 0}, {"x": 0, "y": 1}),
		"vertically adjacent tile is within 5-ft reach")


func _test_diagonal_tile_is_within_reach() -> void:
	print("_test_diagonal_tile_is_within_reach")
	var ms := MovementSystemClass.new()
	_check(ms.is_within_reach({"x": 0, "y": 0}, {"x": 1, "y": 1}),
		"diagonal tile is within 5-ft reach (Chebyshev/5e grid rule)")


func _test_two_tiles_away_is_out_of_reach() -> void:
	print("_test_two_tiles_away_is_out_of_reach")
	var ms := MovementSystemClass.new()
	_check(not ms.is_within_reach({"x": 0, "y": 0}, {"x": 2, "y": 0}),
		"two tiles away is out of 5-ft reach")


func _test_diagonal_two_tiles_is_out_of_reach() -> void:
	print("_test_diagonal_two_tiles_is_out_of_reach")
	var ms := MovementSystemClass.new()
	_check(not ms.is_within_reach({"x": 0, "y": 0}, {"x": 2, "y": 2}),
		"two tiles diagonally is out of 5-ft reach")


func _test_custom_reach_10ft() -> void:
	print("_test_custom_reach_10ft")
	var ms := MovementSystemClass.new()
	_check(ms.is_within_reach({"x": 0, "y": 0}, {"x": 2, "y": 0}, 10),
		"two tiles away is within 10-ft reach")
	_check(not ms.is_within_reach({"x": 0, "y": 0}, {"x": 3, "y": 0}, 10),
		"three tiles away is out of 10-ft reach")


# ---------------------------------------------------------------------------
# process_leave_reach — happy path: OA triggers
# ---------------------------------------------------------------------------

func _test_oa_triggers_and_returns_attack_result() -> void:
	print("_test_oa_triggers_and_returns_attack_result")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	# STR +3, prof +2 vs AC 12: total = 10+3+2=15 >= 12 → hit
	var result: Dictionary = ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	_check(result["triggered"] == true, "OA triggered when reaction available and not disengaging")
	_check(result["reason"] == "", "reason is empty when OA triggers")
	_check(result.has("hit"), "result contains 'hit'")
	_check(result.has("critical"), "result contains 'critical'")
	_check(result.has("roll"), "result contains 'roll'")
	_check(result.has("total"), "result contains 'total'")


func _test_oa_triggers_consumes_reaction() -> void:
	print("_test_oa_triggers_consumes_reaction")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	_check(economy.is_reaction_available(), "reaction available before OA")
	ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	_check(not economy.is_reaction_available(), "reaction consumed after OA triggers")


func _test_oa_hit_on_high_roll() -> void:
	print("_test_oa_hit_on_high_roll")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	# d20=15, +3 STR, +2 prof = 20 vs AC 16 → hit
	var result: Dictionary = ms.process_leave_reach(economy, 15, 3, 2, 16, false)
	_check(result["triggered"] == true, "OA triggered")
	_check(result["hit"] == true, "OA hits on roll 15+3+2=20 vs AC 16")
	_check(result["critical"] == false, "not a critical hit on roll 15")
	_check(result["roll"] == 15, "roll stored as 15")
	_check(result["total"] == 20, "total is 15+3+2=20")


func _test_oa_miss_on_low_roll() -> void:
	print("_test_oa_miss_on_low_roll")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	# d20=2, +0 STR, +2 prof = 4 vs AC 16 → miss; d20=1 is auto-miss, use 2
	var result: Dictionary = ms.process_leave_reach(economy, 2, 0, 2, 16, false)
	_check(result["triggered"] == true, "OA triggered")
	_check(result["hit"] == false, "OA misses on roll 2+0+2=4 vs AC 16")
	_check(result["critical"] == false, "not a critical on roll 2")


func _test_oa_critical_on_natural_20() -> void:
	print("_test_oa_critical_on_natural_20")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	var result: Dictionary = ms.process_leave_reach(economy, 20, 3, 2, 16, false)
	_check(result["triggered"] == true, "OA triggered")
	_check(result["hit"] == true, "natural 20 is always a hit")
	_check(result["critical"] == true, "natural 20 is a critical hit")


# ---------------------------------------------------------------------------
# process_leave_reach — reaction spent
# ---------------------------------------------------------------------------

func _test_oa_blocked_when_reaction_spent() -> void:
	print("_test_oa_blocked_when_reaction_spent")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	economy.use_reaction()    # spend the reaction before movement
	var result: Dictionary = ms.process_leave_reach(economy, 15, 3, 2, 12, false)
	_check(result["triggered"] == false, "OA not triggered when reaction already spent")
	_check(result["reason"] == "reaction_spent", "reason is 'reaction_spent'")


func _test_reaction_not_consumed_when_oa_blocked() -> void:
	print("_test_reaction_not_consumed_when_oa_blocked")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	economy.use_reaction()
	# Reaction is already gone; process_leave_reach must not double-spend or error
	var result: Dictionary = ms.process_leave_reach(economy, 15, 3, 2, 12, false)
	_check(result["triggered"] == false, "OA blocked")
	# is_reaction_available still false (was spent before, not changed by blocked OA)
	_check(not economy.is_reaction_available(), "reaction state unchanged by blocked OA")


# ---------------------------------------------------------------------------
# process_leave_reach — target disengaging
# ---------------------------------------------------------------------------

func _test_oa_blocked_when_target_disengaging() -> void:
	print("_test_oa_blocked_when_target_disengaging")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	var result: Dictionary = ms.process_leave_reach(economy, 15, 3, 2, 12, true)
	_check(result["triggered"] == false, "OA not triggered when target used Disengage")
	_check(result["reason"] == "target_disengaging", "reason is 'target_disengaging'")


func _test_reaction_not_consumed_when_target_disengaging() -> void:
	print("_test_reaction_not_consumed_when_target_disengaging")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	ms.process_leave_reach(economy, 15, 3, 2, 12, true)
	_check(economy.is_reaction_available(), "reaction not consumed when OA blocked by Disengage")


# ---------------------------------------------------------------------------
# Result keys always present
# ---------------------------------------------------------------------------

func _test_result_keys_present_on_trigger() -> void:
	print("_test_result_keys_present_on_trigger")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	var result: Dictionary = ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	for key: String in ["triggered", "reason", "hit", "critical", "roll", "total"]:
		_check(result.has(key), "triggered result has '%s' key" % key)


func _test_result_keys_present_on_no_trigger() -> void:
	print("_test_result_keys_present_on_no_trigger")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	economy.use_reaction()
	var result: Dictionary = ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	for key: String in ["triggered", "reason", "hit", "critical", "roll", "total"]:
		_check(result.has(key), "non-triggered result has '%s' key" % key)


# ---------------------------------------------------------------------------
# Only one reaction per round
# ---------------------------------------------------------------------------

func _test_reaction_cannot_be_used_twice_same_round() -> void:
	print("_test_reaction_cannot_be_used_twice_same_round")
	var ms := MovementSystemClass.new()
	var economy := _fresh_economy()
	# First enemy triggers OA → reaction consumed
	var result1: Dictionary = ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	_check(result1["triggered"] == true, "first OA triggers")
	# Second enemy cannot trigger OA same round
	var result2: Dictionary = ms.process_leave_reach(economy, 10, 3, 2, 12, false)
	_check(result2["triggered"] == false, "second OA blocked — reaction already spent this round")
	_check(result2["reason"] == "reaction_spent", "reason is 'reaction_spent' for second attempt")
