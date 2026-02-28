## test_combat_action.gd
## Unit tests for CombatAction (src/rules_engine/core/combat_action.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_combat_action.gd
extends SceneTree

const ActionEconomy = preload("res://rules_engine/core/action_economy.gd")
const CombatAction = preload("res://rules_engine/core/combat_action.gd")

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
	_test_action_constants_defined()
	_test_action_slot_actions_contains_all_five()
	_test_get_available_actions_when_slot_free()
	_test_get_available_actions_when_slot_spent()
	_test_get_available_actions_before_start_turn()
	_test_is_valid_action_recognises_all_five()
	_test_is_valid_action_rejects_unknown()
	_test_available_actions_is_a_copy()


# ---------------------------------------------------------------------------
# Action ID constants are non-empty strings
# ---------------------------------------------------------------------------
func _test_action_constants_defined() -> void:
	print("_test_action_constants_defined")
	_check(CombatAction.ATTACK == "attack",        "ATTACK constant equals 'attack'")
	_check(CombatAction.CAST_SPELL == "cast_spell", "CAST_SPELL constant equals 'cast_spell'")
	_check(CombatAction.DASH == "dash",             "DASH constant equals 'dash'")
	_check(CombatAction.DISENGAGE == "disengage",   "DISENGAGE constant equals 'disengage'")
	_check(CombatAction.DODGE == "dodge",           "DODGE constant equals 'dodge'")


# ---------------------------------------------------------------------------
# ACTION_SLOT_ACTIONS contains exactly the five V1 actions
# ---------------------------------------------------------------------------
func _test_action_slot_actions_contains_all_five() -> void:
	print("_test_action_slot_actions_contains_all_five")
	var all: Array[String] = CombatAction.ACTION_SLOT_ACTIONS
	_check(all.size() == 5, "ACTION_SLOT_ACTIONS has exactly 5 entries")
	_check(all.has(CombatAction.ATTACK),     "ACTION_SLOT_ACTIONS includes ATTACK")
	_check(all.has(CombatAction.CAST_SPELL), "ACTION_SLOT_ACTIONS includes CAST_SPELL")
	_check(all.has(CombatAction.DASH),       "ACTION_SLOT_ACTIONS includes DASH")
	_check(all.has(CombatAction.DISENGAGE),  "ACTION_SLOT_ACTIONS includes DISENGAGE")
	_check(all.has(CombatAction.DODGE),      "ACTION_SLOT_ACTIONS includes DODGE")


# ---------------------------------------------------------------------------
# All five actions are available when the Action slot is free
# ---------------------------------------------------------------------------
func _test_get_available_actions_when_slot_free() -> void:
	print("_test_get_available_actions_when_slot_free")
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	var available: Array[String] = CombatAction.get_available_actions(economy)
	_check(available.size() == 5, "all 5 actions available when slot is free")
	_check(available.has(CombatAction.ATTACK),     "attack available when slot free")
	_check(available.has(CombatAction.CAST_SPELL), "cast_spell available when slot free")
	_check(available.has(CombatAction.DASH),       "dash available when slot free")
	_check(available.has(CombatAction.DISENGAGE),  "disengage available when slot free")
	_check(available.has(CombatAction.DODGE),      "dodge available when slot free")


# ---------------------------------------------------------------------------
# No actions available once the Action slot is spent
# ---------------------------------------------------------------------------
func _test_get_available_actions_when_slot_spent() -> void:
	print("_test_get_available_actions_when_slot_spent")
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	economy.use_action()
	var available: Array[String] = CombatAction.get_available_actions(economy)
	_check(available.size() == 0, "no actions available after use_action()")


# ---------------------------------------------------------------------------
# No actions available before start_turn() is called
# ---------------------------------------------------------------------------
func _test_get_available_actions_before_start_turn() -> void:
	print("_test_get_available_actions_before_start_turn")
	var economy := ActionEconomy.new(30)
	var available: Array[String] = CombatAction.get_available_actions(economy)
	_check(available.size() == 0, "no actions available before start_turn()")


# ---------------------------------------------------------------------------
# is_valid_action recognises all five V1 action IDs
# ---------------------------------------------------------------------------
func _test_is_valid_action_recognises_all_five() -> void:
	print("_test_is_valid_action_recognises_all_five")
	_check(CombatAction.is_valid_action("attack"),     "is_valid_action: attack")
	_check(CombatAction.is_valid_action("cast_spell"), "is_valid_action: cast_spell")
	_check(CombatAction.is_valid_action("dash"),       "is_valid_action: dash")
	_check(CombatAction.is_valid_action("disengage"),  "is_valid_action: disengage")
	_check(CombatAction.is_valid_action("dodge"),      "is_valid_action: dodge")


# ---------------------------------------------------------------------------
# is_valid_action rejects unknown identifiers
# ---------------------------------------------------------------------------
func _test_is_valid_action_rejects_unknown() -> void:
	print("_test_is_valid_action_rejects_unknown")
	_check(CombatAction.is_valid_action("") == false,        "empty string is invalid")
	_check(CombatAction.is_valid_action("fireball") == false, "'fireball' is invalid")
	_check(CombatAction.is_valid_action("ATTACK") == false,  "uppercase 'ATTACK' is invalid")
	_check(CombatAction.is_valid_action("help") == false,    "'help' (non-V1) is invalid")


# ---------------------------------------------------------------------------
# get_available_actions returns a copy; mutating it does not affect the source
# ---------------------------------------------------------------------------
func _test_available_actions_is_a_copy() -> void:
	print("_test_available_actions_is_a_copy")
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	var available: Array[String] = CombatAction.get_available_actions(economy)
	available.clear()
	var fresh: Array[String] = CombatAction.get_available_actions(economy)
	_check(fresh.size() == 5, "get_available_actions returns a copy (clearing does not affect source)")
