## test_trigger_tile_resolver.gd
## Unit tests for TriggerTileResolver (src/rules_engine/core/trigger_tile_resolver.gd).
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


func _test_unknown_type_does_not_fire() -> void:
	print("_test_unknown_type_does_not_fire")
	var resolver := TriggerTileResolverClass.new()
	var trigger: Dictionary = {"type": "invisible_wall", "encounter_id": "xyz"}
	var result: Dictionary = resolver.resolve(trigger, [], {})
	_check(result["should_fire"] == false, "unknown type does not fire")
	_check(result["reason"] == "unknown_type", "reason is unknown_type")


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


func _test_is_valid_type_empty_string_returns_false() -> void:
	print("_test_is_valid_type_empty_string_returns_false")
	var resolver := TriggerTileResolverClass.new()
	_check(resolver.is_valid_type("") == false, "empty string returns false")
