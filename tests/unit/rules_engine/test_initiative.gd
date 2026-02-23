## test_initiative.gd
## Unit tests for InitiativeRoller (src/rules_engine/core/initiative.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_initiative.gd
extends SceneTree

const DiceRoller = preload("res://rules_engine/core/dice_roller.gd")
const InitiativeRoller = preload("res://rules_engine/core/initiative.gd")

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
	_test_total_equals_roll_plus_modifier()
	_test_dex_modifier_derived_correctly()
	_test_sorted_descending_by_total()
	_test_tie_broken_by_dex_score()
	_test_tie_fallback_by_id()
	_test_single_combatant()
	_test_empty_combatants()
	_test_sort_results_standalone()
	_test_negative_dex_modifier()


# ---------------------------------------------------------------------------
# Result dictionary contains all required keys
# ---------------------------------------------------------------------------
func _test_result_keys_present() -> void:
	print("_test_result_keys_present")
	var roller := DiceRoller.new(42)
	var ir := InitiativeRoller.new()
	var combatants: Array = [{"id": "hero", "dex_score": 14}]
	var results: Array = ir.roll_for_combatants(combatants, roller)
	_check(results.size() == 1, "one result for one combatant")
	var r: Dictionary = results[0]
	_check(r.has("id"), "result has 'id' key")
	_check(r.has("roll"), "result has 'roll' key")
	_check(r.has("modifier"), "result has 'modifier' key")
	_check(r.has("total"), "result has 'total' key")
	_check(r.has("dex_score"), "result has 'dex_score' key")


# ---------------------------------------------------------------------------
# total = roll + modifier
# ---------------------------------------------------------------------------
func _test_total_equals_roll_plus_modifier() -> void:
	print("_test_total_equals_roll_plus_modifier")
	var roller := DiceRoller.new(0)
	var ir := InitiativeRoller.new()
	var combatants: Array = [
		{"id": "a", "dex_score": 14},
		{"id": "b", "dex_score": 8},
		{"id": "c", "dex_score": 10},
	]
	var results: Array = ir.roll_for_combatants(combatants, roller)
	for entry in results:
		_check(
			entry["total"] == entry["roll"] + entry["modifier"],
			"total == roll + modifier for '%s'" % entry["id"]
		)


# ---------------------------------------------------------------------------
# DEX modifier derived as floor((score - 10) / 2)
# ---------------------------------------------------------------------------
func _test_dex_modifier_derived_correctly() -> void:
	print("_test_dex_modifier_derived_correctly")
	var roller := DiceRoller.new(1)
	var ir := InitiativeRoller.new()
	# DEX 10 -> mod 0, DEX 14 -> mod +2, DEX 8 -> mod -1, DEX 20 -> mod +5
	var combatants: Array = [
		{"id": "dex10", "dex_score": 10},
		{"id": "dex14", "dex_score": 14},
		{"id": "dex8",  "dex_score": 8},
		{"id": "dex20", "dex_score": 20},
	]
	var results: Array = ir.roll_for_combatants(combatants, roller)
	var by_id: Dictionary = {}
	for entry in results:
		by_id[entry["id"]] = entry
	_check(by_id["dex10"]["modifier"] == 0,  "DEX 10 -> modifier 0")
	_check(by_id["dex14"]["modifier"] == 2,  "DEX 14 -> modifier +2")
	_check(by_id["dex8"]["modifier"]  == -1, "DEX  8 -> modifier -1")
	_check(by_id["dex20"]["modifier"] == 5,  "DEX 20 -> modifier +5")


# ---------------------------------------------------------------------------
# Results are sorted descending by initiative total
# ---------------------------------------------------------------------------
func _test_sorted_descending_by_total() -> void:
	print("_test_sorted_descending_by_total")
	var ir := InitiativeRoller.new()
	# Build pre-rolled results with known totals and sort them directly.
	var raw: Array = [
		{"id": "c", "roll": 5,  "modifier": 0, "total": 5,  "dex_score": 10},
		{"id": "a", "roll": 18, "modifier": 2, "total": 20, "dex_score": 14},
		{"id": "b", "roll": 10, "modifier": 1, "total": 11, "dex_score": 12},
	]
	var sorted: Array = ir.sort_results(raw)
	_check(sorted[0]["id"] == "a", "highest total (20) is first")
	_check(sorted[1]["id"] == "b", "middle total (11) is second")
	_check(sorted[2]["id"] == "c", "lowest total (5) is third")
	for i in range(sorted.size() - 1):
		_check(
			sorted[i]["total"] >= sorted[i + 1]["total"],
			"entry %d total >= entry %d total" % [i, i + 1]
		)


# ---------------------------------------------------------------------------
# Tie in total is broken by DEX score (higher wins)
# ---------------------------------------------------------------------------
func _test_tie_broken_by_dex_score() -> void:
	print("_test_tie_broken_by_dex_score")
	var ir := InitiativeRoller.new()
	var raw: Array = [
		{"id": "low_dex",  "roll": 10, "modifier": 0, "total": 10, "dex_score": 10},
		{"id": "high_dex", "roll": 8,  "modifier": 2, "total": 10, "dex_score": 14},
	]
	var sorted: Array = ir.sort_results(raw)
	_check(sorted[0]["id"] == "high_dex", "higher DEX score wins the tie")
	_check(sorted[1]["id"] == "low_dex",  "lower DEX score loses the tie")


# ---------------------------------------------------------------------------
# Tie fallback: identical total and DEX score — sorted by id (deterministic)
# ---------------------------------------------------------------------------
func _test_tie_fallback_by_id() -> void:
	print("_test_tie_fallback_by_id")
	var ir := InitiativeRoller.new()
	var raw: Array = [
		{"id": "goblin_b", "roll": 10, "modifier": 0, "total": 10, "dex_score": 10},
		{"id": "goblin_a", "roll": 10, "modifier": 0, "total": 10, "dex_score": 10},
		{"id": "goblin_c", "roll": 10, "modifier": 0, "total": 10, "dex_score": 10},
	]
	var sorted: Array = ir.sort_results(raw)
	_check(sorted[0]["id"] == "goblin_a", "id 'goblin_a' sorts first alphabetically")
	_check(sorted[1]["id"] == "goblin_b", "id 'goblin_b' sorts second")
	_check(sorted[2]["id"] == "goblin_c", "id 'goblin_c' sorts third")


# ---------------------------------------------------------------------------
# Single combatant returns a list of one entry
# ---------------------------------------------------------------------------
func _test_single_combatant() -> void:
	print("_test_single_combatant")
	var roller := DiceRoller.new(7)
	var ir := InitiativeRoller.new()
	var combatants: Array = [{"id": "solo", "dex_score": 12}]
	var results: Array = ir.roll_for_combatants(combatants, roller)
	_check(results.size() == 1, "single combatant returns one result")
	_check(results[0]["id"] == "solo", "result id matches input id")
	_check(results[0]["roll"] >= 1 and results[0]["roll"] <= 20, "roll is in [1, 20]")
	_check(results[0]["modifier"] == 1, "DEX 12 -> modifier +1")


# ---------------------------------------------------------------------------
# Empty combatant list returns an empty array
# ---------------------------------------------------------------------------
func _test_empty_combatants() -> void:
	print("_test_empty_combatants")
	var roller := DiceRoller.new(0)
	var ir := InitiativeRoller.new()
	var results: Array = ir.roll_for_combatants([], roller)
	_check(results.size() == 0, "empty input returns empty array")


# ---------------------------------------------------------------------------
# sort_results can be called on pre-built data (used for tie-break edge cases)
# ---------------------------------------------------------------------------
func _test_sort_results_standalone() -> void:
	print("_test_sort_results_standalone")
	var ir := InitiativeRoller.new()
	# Mixed scenario: different totals, one tie broken by DEX, one by id
	var raw: Array = [
		{"id": "z_char", "roll": 5,  "modifier": 3, "total": 8,  "dex_score": 16},
		{"id": "a_char", "roll": 15, "modifier": 0, "total": 15, "dex_score": 10},
		{"id": "m_char", "roll": 8,  "modifier": 0, "total": 8,  "dex_score": 10},
	]
	var sorted: Array = ir.sort_results(raw)
	_check(sorted[0]["id"] == "a_char", "highest total (15) is first")
	_check(sorted[1]["id"] == "z_char", "total tie (8): higher DEX 16 beats DEX 10")
	_check(sorted[2]["id"] == "m_char", "total tie (8): lower DEX 10 is last")


# ---------------------------------------------------------------------------
# Negative DEX modifier (DEX < 10) is applied correctly
# ---------------------------------------------------------------------------
func _test_negative_dex_modifier() -> void:
	print("_test_negative_dex_modifier")
	var roller := DiceRoller.new(5)
	var ir := InitiativeRoller.new()
	var combatants: Array = [{"id": "slow", "dex_score": 6}]
	var results: Array = ir.roll_for_combatants(combatants, roller)
	_check(results[0]["modifier"] == -2, "DEX 6 -> modifier -2")
	_check(
		results[0]["total"] == results[0]["roll"] + (-2),
		"total correctly applies negative modifier"
	)
