## test_combat_log_entry.gd
## Unit tests for CombatLogEntry (src/rules_engine/core/combat_log_entry.gd).
##
## Acceptance criteria from the "Implement structured combat log" issue:
##   - Log driven by structured result objects
##   - Displays attacks, damage, saves, conditions
##   - Shows critical hits
##   - Shows concentration breaks
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_combat_log_entry.gd
extends SceneTree

const CombatLogEntryClass = preload("res://rules_engine/core/combat_log_entry.gd")
const AttackResultClass   = preload("res://rules_engine/core/attack_result.gd")
const SaveResultClass     = preload("res://rules_engine/core/save_result.gd")

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
	_test_default_field_values()
	_test_field_presence()
	_test_attack_entry_fields()
	_test_save_entry_fields()
	_test_condition_entry_fields()
	_test_concentration_break_entry_fields()
	_test_attack_result_stored_by_reference()
	_test_save_result_stored_by_reference()
	_test_no_logic_methods()


# ---------------------------------------------------------------------------
# Default field values
# ---------------------------------------------------------------------------
func _test_default_field_values() -> void:
	print("_test_default_field_values")
	var e := CombatLogEntryClass.new()
	_check(e.event_type == "",                "event_type defaults to empty string")
	_check(e.actor_name == "",                "actor_name defaults to empty string")
	_check(e.target_name == "",               "target_name defaults to empty string")
	_check(e.attack_result == null,           "attack_result defaults to null")
	_check(e.save_result == null,             "save_result defaults to null")
	_check(e.condition_id == "",              "condition_id defaults to empty string")
	_check(e.condition_name == "",            "condition_name defaults to empty string")
	_check(e.concentration_effect_id == "",   "concentration_effect_id defaults to empty string")


# ---------------------------------------------------------------------------
# Field presence
# ---------------------------------------------------------------------------
func _test_field_presence() -> void:
	print("_test_field_presence")
	var e := CombatLogEntryClass.new()
	_check("event_type" in e,               "CombatLogEntry has 'event_type' field")
	_check("actor_name" in e,               "CombatLogEntry has 'actor_name' field")
	_check("target_name" in e,              "CombatLogEntry has 'target_name' field")
	_check("attack_result" in e,            "CombatLogEntry has 'attack_result' field")
	_check("save_result" in e,              "CombatLogEntry has 'save_result' field")
	_check("condition_id" in e,             "CombatLogEntry has 'condition_id' field")
	_check("condition_name" in e,           "CombatLogEntry has 'condition_name' field")
	_check("concentration_effect_id" in e,  "CombatLogEntry has 'concentration_effect_id' field")


# ---------------------------------------------------------------------------
# Attack entry — fields assigned correctly
# ---------------------------------------------------------------------------
func _test_attack_entry_fields() -> void:
	print("_test_attack_entry_fields")
	var e := CombatLogEntryClass.new()
	var r := AttackResultClass.new()
	r.hit = true
	r.critical = false
	r.roll = 15
	r.total = 17
	r.damage = 6
	e.event_type    = "attack"
	e.actor_name    = "Fighter"
	e.target_name   = "Goblin"
	e.attack_result = r
	_check(e.event_type == "attack",    "event_type is 'attack'")
	_check(e.actor_name == "Fighter",   "actor_name is 'Fighter'")
	_check(e.target_name == "Goblin",   "target_name is 'Goblin'")
	_check(e.attack_result == r,        "attack_result stores the AttackResult")
	_check(e.attack_result.hit == true, "attack_result.hit accessible via entry")
	_check(e.attack_result.damage == 6, "attack_result.damage accessible via entry")


# ---------------------------------------------------------------------------
# Save entry — fields assigned correctly
# ---------------------------------------------------------------------------
func _test_save_entry_fields() -> void:
	print("_test_save_entry_fields")
	var e := CombatLogEntryClass.new()
	var s := SaveResultClass.new()
	s.dc      = 14
	s.roll    = 8
	s.total   = 8
	s.success = false
	e.event_type   = "save"
	e.actor_name   = "Wizard"
	e.save_result  = s
	_check(e.event_type == "save",          "event_type is 'save'")
	_check(e.actor_name == "Wizard",        "actor_name is 'Wizard'")
	_check(e.save_result == s,              "save_result stores the SaveResult")
	_check(e.save_result.success == false,  "save_result.success accessible via entry")
	_check(e.save_result.dc == 14,          "save_result.dc accessible via entry")


# ---------------------------------------------------------------------------
# Condition entry — fields assigned correctly
# ---------------------------------------------------------------------------
func _test_condition_entry_fields() -> void:
	print("_test_condition_entry_fields")
	var e := CombatLogEntryClass.new()
	e.event_type     = "condition"
	e.actor_name     = "Rogue"
	e.condition_id   = "poisoned"
	e.condition_name = "Poisoned"
	_check(e.event_type == "condition",     "event_type is 'condition'")
	_check(e.actor_name == "Rogue",         "actor_name is 'Rogue'")
	_check(e.condition_id == "poisoned",    "condition_id is 'poisoned'")
	_check(e.condition_name == "Poisoned",  "condition_name is 'Poisoned'")


# ---------------------------------------------------------------------------
# Concentration break entry — fields assigned correctly
# ---------------------------------------------------------------------------
func _test_concentration_break_entry_fields() -> void:
	print("_test_concentration_break_entry_fields")
	var e := CombatLogEntryClass.new()
	var s := SaveResultClass.new()
	s.dc      = 10
	s.roll    = 4
	s.total   = 4
	s.success = false
	e.event_type              = "concentration_break"
	e.actor_name              = "Sorcerer"
	e.concentration_effect_id = "hold_person"
	e.save_result             = s
	_check(e.event_type == "concentration_break",       "event_type is 'concentration_break'")
	_check(e.actor_name == "Sorcerer",                  "actor_name is 'Sorcerer'")
	_check(e.concentration_effect_id == "hold_person",  "concentration_effect_id is 'hold_person'")
	_check(e.save_result == s,                          "save_result stored on concentration break")


# ---------------------------------------------------------------------------
# attack_result is stored by reference, not copied
# ---------------------------------------------------------------------------
func _test_attack_result_stored_by_reference() -> void:
	print("_test_attack_result_stored_by_reference")
	var e := CombatLogEntryClass.new()
	var r := AttackResultClass.new()
	r.damage = 3
	e.attack_result = r
	r.damage = 9
	_check(e.attack_result.damage == 9, "attack_result stored by reference (mutation visible)")


# ---------------------------------------------------------------------------
# save_result is stored by reference, not copied
# ---------------------------------------------------------------------------
func _test_save_result_stored_by_reference() -> void:
	print("_test_save_result_stored_by_reference")
	var e := CombatLogEntryClass.new()
	var s := SaveResultClass.new()
	s.total = 5
	e.save_result = s
	s.total = 18
	_check(e.save_result.total == 18, "save_result stored by reference (mutation visible)")


# ---------------------------------------------------------------------------
# No logic methods — CombatLogEntry must not expose any rules calculations
# ---------------------------------------------------------------------------
func _test_no_logic_methods() -> void:
	print("_test_no_logic_methods")
	var e := CombatLogEntryClass.new()
	_check(not e.has_method("resolve"),
		"no resolve() method (rules logic must stay in rules_engine resolvers)")
	_check(not e.has_method("format"),
		"no format() method (formatting is the log UI's responsibility)")
	_check(not e.has_method("compute_dc"),
		"no compute_dc() method (DC computation must stay in rules_engine)")
