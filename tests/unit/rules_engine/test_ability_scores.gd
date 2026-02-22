## test_ability_scores.gd
## Unit tests for AbilityScores (src/rules_engine/core/ability_scores.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_ability_scores.gd
##
## Invalid-input strategy: set_score / get_score call push_error and return
## without modifying state, so tests verify the state is unchanged.
extends SceneTree

const AbilityScores = preload("res://rules_engine/core/ability_scores.gd")

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
	_test_modifier_table()
	_test_set_score_updates_modifier()
	_test_invalid_ability_key()
	_test_invalid_score_out_of_range()
	_test_to_dict()
	_test_from_dict()


# ---------------------------------------------------------------------------
# Modifier table: floor((score - 10) / 2)
# ---------------------------------------------------------------------------
func _test_modifier_table() -> void:
	print("_test_modifier_table")
	var s := AbilityScores.new()
	# Representative values from SRD score range 1–30
	var cases: Dictionary = {
		1: -5,
		2: -4,
		3: -4,
		8: -1,
		9: -1,
		10: 0,
		11: 0,
		12: 1,
		13: 1,
		18: 4,
		20: 5,
		30: 10,
	}
	for score: int in cases:
		s.set_score("STR", score)
		var got: int = s.get_modifier("STR")
		var want: int = cases[score]
		_check(got == want, "score %d -> modifier %d (got %d)" % [score, want, got])


# ---------------------------------------------------------------------------
# Setting a score immediately changes the derived modifier
# ---------------------------------------------------------------------------
func _test_set_score_updates_modifier() -> void:
	print("_test_set_score_updates_modifier")
	var s := AbilityScores.new()
	s.set_score("DEX", 14)
	_check(s.get_modifier("DEX") == 2, "DEX 14 -> modifier 2")
	s.set_score("DEX", 8)
	_check(s.get_modifier("DEX") == -1, "DEX updated to 8 -> modifier -1")
	s.set_score("CON", 20)
	_check(s.get_modifier("CON") == 5, "CON 20 -> modifier 5")


# ---------------------------------------------------------------------------
# Invalid ability keys are rejected (push_error + no state change)
# ---------------------------------------------------------------------------
func _test_invalid_ability_key() -> void:
	print("_test_invalid_ability_key")
	var s := AbilityScores.new()
	# set_score with unknown key must not change anything
	s.set_score("LUCK", 15)
	_check(s.get_score("LUCK") == 0, "get_score returns 0 after set_score with unknown key 'LUCK' is rejected")
	# get_modifier delegates to get_score, so it also returns 0 for an unknown key
	_check(s.get_modifier("LUCK") == 0, "get_modifier returns 0 for unknown key 'LUCK' (delegates to get_score)")


# ---------------------------------------------------------------------------
# Scores outside [1, 30] are rejected; existing value is preserved
# ---------------------------------------------------------------------------
func _test_invalid_score_out_of_range() -> void:
	print("_test_invalid_score_out_of_range")
	var s := AbilityScores.new()
	s.set_score("STR", 10)  # baseline
	s.set_score("STR", 0)   # below MIN_SCORE
	_check(s.get_score("STR") == 10, "score 0 (below min) rejected, STR unchanged at 10")
	s.set_score("STR", 31)  # above MAX_SCORE
	_check(s.get_score("STR") == 10, "score 31 (above max) rejected, STR unchanged at 10")
	s.set_score("STR", 1)   # boundary min — must succeed
	_check(s.get_score("STR") == 1, "score 1 (boundary min) accepted")
	s.set_score("STR", 30)  # boundary max — must succeed
	_check(s.get_score("STR") == 30, "score 30 (boundary max) accepted")


# ---------------------------------------------------------------------------
# to_dict returns a copy of current scores
# ---------------------------------------------------------------------------
func _test_to_dict() -> void:
	print("_test_to_dict")
	var s := AbilityScores.new()
	s.set_score("STR", 16)
	s.set_score("CHA", 8)
	var d: Dictionary = s.to_dict()
	_check(d["STR"] == 16, "to_dict STR == 16")
	_check(d["CHA"] == 8, "to_dict CHA == 8")
	_check(d.has("DEX"), "to_dict contains DEX key")
	# Verify it is a copy — mutating d must not affect s
	d["STR"] = 99
	_check(s.get_score("STR") == 16, "to_dict returns a copy (mutation does not affect source)")


# ---------------------------------------------------------------------------
# from_dict populates all six scores and modifiers update accordingly
# ---------------------------------------------------------------------------
func _test_from_dict() -> void:
	print("_test_from_dict")
	var s := AbilityScores.new()
	s.from_dict({"STR": 18, "DEX": 14, "CON": 12, "INT": 10, "WIS": 8, "CHA": 15})
	_check(s.get_score("STR") == 18, "from_dict STR == 18")
	_check(s.get_score("CHA") == 15, "from_dict CHA == 15")
	_check(s.get_modifier("STR") == 4, "from_dict STR modifier == 4")
	_check(s.get_modifier("WIS") == -1, "from_dict WIS modifier == -1")
	# from_dict should reject invalid keys embedded in the dict
	s.from_dict({"POWER": 99})
	_check(s.get_score("POWER") == 0, "from_dict rejects unknown key 'POWER'")
