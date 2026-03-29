## test_trigger_tile_resolver.gd
## Unit tests for TriggerTileResolver (src/rules_engine/core/trigger_tile_resolver.gd).
## Unit tests for TriggerTileResolver
## (src/rules_engine/core/trigger_tile_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_trigger_tile_resolver.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const TriggerTileResolverClass = preload("res://rules_engine/core/trigger_tile_resolver.gd")

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
	_test_null_trigger_does_not_fire()
	_test_non_dict_trigger_does_not_fire()
	_test_unknown_type_does_not_fire()
	_test_combat_start_fires()
	_test_combat_start_already_fired_does_not_fire()
	_test_combat_start_different_encounter_id_fires()
	_test_reason_empty_when_should_fire()
	_test_reason_no_trigger_for_null()
	_test_reason_already_fired()
	_test_reason_unknown_type()
	_test_empty_fired_ids_allows_fire()
	_test_quest_flags_ignored_for_combat_start()


# ---------------------------------------------------------------------------
# Null / non-dict trigger
# ---------------------------------------------------------------------------
func _test_null_trigger_does_not_fire() -> void:
	print("_test_null_trigger_does_not_fire")
	var resolver := TriggerTileResolverClass.new()
	var result: Dictionary = resolver.resolve(null, [], {})
	_check(result["should_fire"] == false, "null trigger does not fire")
	_check(result["reason"] == "no_trigger", "reason is no_trigger for null")


func _test_non_dict_trigger_does_not_fire() -> void:
	print("_test_non_dict_trigger_does_not_fire")
	var resolver := TriggerTileResolverClass.new()
	var result: Dictionary = resolver.resolve(0, [], {})
	_check(result["should_fire"] == false, "non-dict trigger does not fire")
	_check(result["reason"] == "no_trigger", "reason is no_trigger for non-dict")


# ---------------------------------------------------------------------------
# Unknown type
# ---------------------------------------------------------------------------
func _test_unknown_type_does_not_fire() -> void:
	print("_test_unknown_type_does_not_fire")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "invisible_wall", "encounter_id": "xyz"}
	var result: Dictionary = resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == false, "unknown type does not fire")
	_check(result["reason"] == "unknown_type", "reason is unknown_type")


# ---------------------------------------------------------------------------
# combat_start trigger
# ---------------------------------------------------------------------------
func _test_combat_start_fires() -> void:
	print("_test_combat_start_fires")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "bandit_ambush"}
	var result: Dictionary = resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == true, "combat_start trigger fires")
	_check(result["reason"] == "", "reason is empty when should_fire is true")


func _test_combat_start_already_fired_does_not_fire() -> void:
	print("_test_combat_start_already_fired_does_not_fire")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "bandit_ambush"}
	var fired: Array = ["bandit_ambush"]
	var result: Dictionary = resolver.resolve(trigger, fired, {})
	_check(result["should_fire"] == false, "already-fired encounter does not fire again")
	_check(result["reason"] == "already_fired", "reason is already_fired")


func _test_combat_start_different_encounter_id_fires() -> void:
	print("_test_combat_start_different_encounter_id_fires")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "wolf_pack"}
	var fired: Array = ["bandit_ambush"]
	var result: Dictionary = resolver.resolve(trigger, fired, {})
	_check(result["should_fire"] == true, "different encounter_id still fires")


# ---------------------------------------------------------------------------
# Reason strings
# ---------------------------------------------------------------------------
func _test_reason_empty_when_should_fire() -> void:
	print("_test_reason_empty_when_should_fire")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "enc_01"}
	var result: Dictionary = resolver.resolve(trigger, [], {})
	_check(result["reason"] == "", "reason is empty string when trigger fires")


func _test_reason_no_trigger_for_null() -> void:
	print("_test_reason_no_trigger_for_null")
	var resolver := TriggerTileResolverClass.new()
	var result: Dictionary = resolver.resolve(null, [], {})
	_check(result["reason"] == "no_trigger", "reason is no_trigger for null input")


func _test_reason_already_fired() -> void:
	print("_test_reason_already_fired")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "enc_02"}
	var result: Dictionary = resolver.resolve(trigger, ["enc_02"], {})
	_check(result["reason"] == "already_fired", "reason is already_fired")


func _test_reason_unknown_type() -> void:
	print("_test_reason_unknown_type")
	var resolver := TriggerTileResolverClass.new()
	var result: Dictionary = resolver.resolve({"type": "warp_zone"}, [], {})
	_check(result["reason"] == "unknown_type", "reason is unknown_type")


# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------
func _test_empty_fired_ids_allows_fire() -> void:
	print("_test_empty_fired_ids_allows_fire")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "bandit_camp"}
	var result: Dictionary = resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == true, "empty fired_ids allows trigger to fire")


func _test_quest_flags_ignored_for_combat_start() -> void:
	print("_test_quest_flags_ignored_for_combat_start")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "combat_start", "encounter_id": "ambush_2"}
	var flags: Dictionary = {"quest_started": true, "bandit_defeated": false}
	var result: Dictionary = resolver.resolve(trigger, [], flags)
	_check(result["should_fire"] == true, "quest flags do not block combat_start trigger")
	_test_resolve_no_id_no_conditions_fires()
	_test_resolve_one_time_not_yet_fired()
	_test_resolve_one_time_already_fired()
	_test_resolve_repeatable_fires_even_when_id_in_list()
	_test_resolve_condition_met_fires()
	_test_resolve_condition_not_met_blocks()
	_test_resolve_multiple_conditions_all_met()
	_test_resolve_multiple_conditions_one_fails()
	_test_resolve_missing_flag_defaults_to_false()
	_test_is_valid_type_combat_start()
	_test_is_valid_type_dialogue_start()
	_test_is_valid_type_set_flag()
	_test_is_valid_type_teleport()
	_test_is_valid_type_unknown_returns_false()
	_test_is_valid_type_empty_string_returns_false()


# ---------------------------------------------------------------------------
# resolve — basic firing
# ---------------------------------------------------------------------------
func _test_resolve_no_id_no_conditions_fires() -> void:
	print("_test_resolve_no_id_no_conditions_fires")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {"type": "combat_start", "encounter_id": "test"}
	var result := resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == true, "fires when no id and no conditions")
	_check(result["reason"] == "", "reason is empty when firing")


# ---------------------------------------------------------------------------
# resolve — one-time logic
# ---------------------------------------------------------------------------
func _test_resolve_one_time_not_yet_fired() -> void:
	print("_test_resolve_one_time_not_yet_fired")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {"id": "trig_a", "type": "combat_start", "one_time": true}
	var result := resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == true, "one_time trigger fires when not in fired_ids")


func _test_resolve_one_time_already_fired() -> void:
	print("_test_resolve_one_time_already_fired")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {"id": "trig_a", "type": "combat_start", "one_time": true}
	var result := resolver.resolve(trigger, ["trig_a"], {})
	_check(result["should_fire"] == false, "one_time trigger blocked when id in fired_ids")
	_check(result["reason"] == "already_fired", "reason is 'already_fired'")


func _test_resolve_repeatable_fires_even_when_id_in_list() -> void:
	print("_test_resolve_repeatable_fires_even_when_id_in_list")
	var resolver := TriggerTileResolverClass.new()
	# one_time is false (default) — trigger is repeatable.
	var trigger := {"id": "trig_b", "type": "dialogue_start", "one_time": false}
	var result := resolver.resolve(trigger, ["trig_b"], {})
	_check(result["should_fire"] == true, "repeatable trigger fires even when id is in fired list")


# ---------------------------------------------------------------------------
# resolve — condition evaluation
# ---------------------------------------------------------------------------
func _test_resolve_condition_met_fires() -> void:
	print("_test_resolve_condition_met_fires")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {
		"type": "dialogue_start",
		"conditions": [{"flag": "met_innkeeper", "value": true}]
	}
	var result := resolver.resolve(trigger, [], {"met_innkeeper": true})
	_check(result["should_fire"] == true, "fires when single condition is met")


func _test_resolve_condition_not_met_blocks() -> void:
	print("_test_resolve_condition_not_met_blocks")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {
		"type": "dialogue_start",
		"conditions": [{"flag": "met_innkeeper", "value": true}]
	}
	var result := resolver.resolve(trigger, [], {"met_innkeeper": false})
	_check(result["should_fire"] == false, "blocked when condition flag value does not match")
	_check(result["reason"] == "condition_not_met", "reason is 'condition_not_met'")


func _test_resolve_multiple_conditions_all_met() -> void:
	print("_test_resolve_multiple_conditions_all_met")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {
		"type": "combat_start",
		"conditions": [
			{"flag": "bandits_alive", "value": true},
			{"flag": "road_cleared", "value": false}
		]
	}
	var flags := {"bandits_alive": true, "road_cleared": false}
	var result := resolver.resolve(trigger, [], flags)
	_check(result["should_fire"] == true, "fires when all conditions are met")


func _test_resolve_multiple_conditions_one_fails() -> void:
	print("_test_resolve_multiple_conditions_one_fails")
	var resolver := TriggerTileResolverClass.new()
	var trigger := {
		"type": "combat_start",
		"conditions": [
			{"flag": "bandits_alive", "value": true},
			{"flag": "road_cleared", "value": false}
		]
	}
	# road_cleared is true, but condition expects false.
	var flags := {"bandits_alive": true, "road_cleared": true}
	var result := resolver.resolve(trigger, [], flags)
	_check(result["should_fire"] == false, "blocked when one condition in a list is not met")
	_check(result["reason"] == "condition_not_met", "reason is 'condition_not_met'")


func _test_resolve_missing_flag_defaults_to_false() -> void:
	print("_test_resolve_missing_flag_defaults_to_false")
	var resolver := TriggerTileResolverClass.new()
	# Condition expects "quest_done" == false; flag is absent → defaults to false → match.
	var trigger := {
		"type": "combat_start",
		"conditions": [{"flag": "quest_done", "value": false}]
	}
	var result := resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == true, "missing flag defaults to false; condition false==false passes")


# ---------------------------------------------------------------------------
# is_valid_type
# ---------------------------------------------------------------------------
func _test_is_valid_type_combat_start() -> void:
	print("_test_is_valid_type_combat_start")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("combat_start") == true, "'combat_start' is a valid type")


func _test_is_valid_type_dialogue_start() -> void:
	print("_test_is_valid_type_dialogue_start")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("dialogue_start") == true, "'dialogue_start' is a valid type")


func _test_is_valid_type_set_flag() -> void:
	print("_test_is_valid_type_set_flag")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("set_flag") == true, "'set_flag' is a valid type")


func _test_is_valid_type_teleport() -> void:
	print("_test_is_valid_type_teleport")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("teleport") == true, "'teleport' is a valid type")


func _test_is_valid_type_unknown_returns_false() -> void:
	print("_test_is_valid_type_unknown_returns_false")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("fly_away") == false, "unknown type returns false")


func _test_is_valid_type_empty_string_returns_false() -> void:
	print("_test_is_valid_type_empty_string_returns_false")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("") == false, "empty string returns false")
