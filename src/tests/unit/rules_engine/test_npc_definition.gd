## test_npc_definition.gd
## Unit tests for NpcDefinition (src/rules_engine/core/npc_definition.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_npc_definition.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const NpcDefinitionClass = preload("res://rules_engine/core/npc_definition.gd")

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
	_test_from_dict_npc_id()
	_test_from_dict_position()
	_test_from_dict_dialogue_id()
	_test_from_dict_pass_through_true()
	_test_from_dict_pass_through_defaults_false()
	_test_from_dict_quest_flags()
	_test_from_dict_defaults_empty()
	_test_is_valid_with_id()
	_test_is_valid_empty_id()
	_test_from_dict_quest_flags_duplicated()


# ---------------------------------------------------------------------------
# from_dict — npc_id is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_npc_id() -> void:
	print("_test_from_dict_npc_id")
	var data := {
		"npc_id": "travelling_merchant",
		"position": {"x": 4, "y": 3},
		"dialogue_id": "merchant_greeting",
		"pass_through": false,
		"quest_flags": {}
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def != null, "from_dict returns non-null")
	_check(def.npc_id == "travelling_merchant", "npc_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — position is parsed as Vector2i
# ---------------------------------------------------------------------------
func _test_from_dict_position() -> void:
	print("_test_from_dict_position")
	var data := {
		"npc_id": "guard_01",
		"position": {"x": 7, "y": 2},
		"dialogue_id": "guard_idle",
		"pass_through": false,
		"quest_flags": {}
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def.position == Vector2i(7, 2), "position parsed as Vector2i(7, 2)")


# ---------------------------------------------------------------------------
# from_dict — dialogue_id is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_dialogue_id() -> void:
	print("_test_from_dict_dialogue_id")
	var data := {
		"npc_id": "innkeeper",
		"position": {"x": 1, "y": 1},
		"dialogue_id": "innkeeper_welcome",
		"pass_through": false,
		"quest_flags": {}
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def.dialogue_id == "innkeeper_welcome", "dialogue_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — pass_through true is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_pass_through_true() -> void:
	print("_test_from_dict_pass_through_true")
	var data := {
		"npc_id": "ghost",
		"position": {"x": 3, "y": 3},
		"dialogue_id": "ghost_whisper",
		"pass_through": true,
		"quest_flags": {}
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def.pass_through == true, "pass_through true parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — pass_through defaults to false when omitted
# ---------------------------------------------------------------------------
func _test_from_dict_pass_through_defaults_false() -> void:
	print("_test_from_dict_pass_through_defaults_false")
	var data := {
		"npc_id": "soldier",
		"position": {"x": 0, "y": 0},
		"dialogue_id": "soldier_idle",
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def.pass_through == false, "pass_through defaults to false when omitted")


# ---------------------------------------------------------------------------
# from_dict — quest_flags dictionary is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_quest_flags() -> void:
	print("_test_from_dict_quest_flags")
	var data := {
		"npc_id": "elder",
		"position": {"x": 5, "y": 5},
		"dialogue_id": "elder_quest",
		"pass_through": false,
		"quest_flags": {"quest_started": true, "elder_met": true}
	}
	var def := NpcDefinitionClass.from_dict(data)
	_check(def.quest_flags.has("quest_started"), "quest_flags contains quest_started key")
	_check(def.quest_flags["quest_started"] == true, "quest_started flag value is true")
	_check(def.quest_flags.has("elder_met"), "quest_flags contains elder_met key")


# ---------------------------------------------------------------------------
# from_dict — missing keys produce safe defaults
# ---------------------------------------------------------------------------
func _test_from_dict_defaults_empty() -> void:
	print("_test_from_dict_defaults_empty")
	var def := NpcDefinitionClass.from_dict({})
	_check(def.npc_id == "", "default npc_id is empty string")
	_check(def.position == Vector2i(0, 0), "default position is Vector2i(0, 0)")
	_check(def.dialogue_id == "", "default dialogue_id is empty string")
	_check(def.pass_through == false, "default pass_through is false")
	_check(def.quest_flags.is_empty(), "default quest_flags is empty dict")


# ---------------------------------------------------------------------------
# is_valid — returns true when npc_id is non-empty
# ---------------------------------------------------------------------------
func _test_is_valid_with_id() -> void:
	print("_test_is_valid_with_id")
	var def := NpcDefinitionClass.new()
	def.npc_id = "guard"
	_check(def.is_valid() == true, "is_valid returns true for non-empty npc_id")


# ---------------------------------------------------------------------------
# is_valid — returns false when npc_id is empty
# ---------------------------------------------------------------------------
func _test_is_valid_empty_id() -> void:
	print("_test_is_valid_empty_id")
	var def := NpcDefinitionClass.new()
	_check(def.is_valid() == false, "is_valid returns false for empty npc_id")


# ---------------------------------------------------------------------------
# from_dict — quest_flags is a copy (modifying original does not affect def)
# ---------------------------------------------------------------------------
func _test_from_dict_quest_flags_duplicated() -> void:
	print("_test_from_dict_quest_flags_duplicated")
	var original_flags := {"some_flag": true}
	var data := {
		"npc_id": "npc_a",
		"position": {"x": 0, "y": 0},
		"dialogue_id": "test",
		"pass_through": false,
		"quest_flags": original_flags
	}
	var def := NpcDefinitionClass.from_dict(data)
	original_flags["new_key"] = "injected"
	_check(not def.quest_flags.has("new_key"),
		"quest_flags is a duplicate; modifying original does not affect definition")
