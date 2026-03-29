## test_npc_registry.gd
## Unit tests for NpcRegistry (src/rules_engine/core/npc_registry.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_npc_registry.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const NpcRegistryClass = preload("res://rules_engine/core/npc_registry.gd")

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
	_test_empty_registry_blocked_tiles_empty()
	_test_empty_registry_get_npc_at_returns_null()
	_test_empty_registry_get_all_empty()
	_test_load_npcs_populates_registry()
	_test_load_npcs_blocked_tiles_excludes_pass_through()
	_test_load_npcs_blocked_tiles_includes_solid()
	_test_load_npcs_blocked_tiles_all_pass_through_empty()
	_test_get_npc_at_finds_npc()
	_test_get_npc_at_returns_null_for_empty_tile()
	_test_get_all_returns_all_npcs()
	_test_get_all_is_duplicate()
	_test_load_npcs_twice_replaces_previous()


# ---------------------------------------------------------------------------
# Empty registry
# ---------------------------------------------------------------------------
func _test_empty_registry_blocked_tiles_empty() -> void:
	print("_test_empty_registry_blocked_tiles_empty")
	var reg := NpcRegistryClass.new()
	_check(reg.get_blocked_tiles().size() == 0,
		"get_blocked_tiles returns empty array on empty registry")


func _test_empty_registry_get_npc_at_returns_null() -> void:
	print("_test_empty_registry_get_npc_at_returns_null")
	var reg := NpcRegistryClass.new()
	_check(reg.get_npc_at(Vector2i(0, 0)) == null,
		"get_npc_at returns null on empty registry")


func _test_empty_registry_get_all_empty() -> void:
	print("_test_empty_registry_get_all_empty")
	var reg := NpcRegistryClass.new()
	_check(reg.get_all().size() == 0, "get_all returns empty array on empty registry")


# ---------------------------------------------------------------------------
# load_npcs — populates registry
# ---------------------------------------------------------------------------
func _test_load_npcs_populates_registry() -> void:
	print("_test_load_npcs_populates_registry")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "guard_01", "position": {"x": 3, "y": 2},
			"dialogue_id": "guard_idle", "pass_through": false, "quest_flags": {}}
	])
	_check(reg.get_all().size() == 1, "one NPC loaded into registry")


# ---------------------------------------------------------------------------
# get_blocked_tiles — solid NPC is included, pass-through is not
# ---------------------------------------------------------------------------
func _test_load_npcs_blocked_tiles_excludes_pass_through() -> void:
	print("_test_load_npcs_blocked_tiles_excludes_pass_through")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "ghost", "position": {"x": 5, "y": 5},
			"dialogue_id": "ghost_whisper", "pass_through": true, "quest_flags": {}}
	])
	_check(reg.get_blocked_tiles().size() == 0,
		"pass-through NPC not included in blocked tiles")


func _test_load_npcs_blocked_tiles_includes_solid() -> void:
	print("_test_load_npcs_blocked_tiles_includes_solid")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "merchant", "position": {"x": 4, "y": 3},
			"dialogue_id": "merchant_greeting", "pass_through": false, "quest_flags": {}}
	])
	var blocked: Array = reg.get_blocked_tiles()
	_check(blocked.size() == 1, "solid NPC included in blocked tiles")
	_check(blocked[0] == Vector2i(4, 3), "blocked tile matches NPC position")


func _test_load_npcs_blocked_tiles_all_pass_through_empty() -> void:
	print("_test_load_npcs_blocked_tiles_all_pass_through_empty")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "spirit_a", "position": {"x": 1, "y": 1},
			"dialogue_id": "spirit_a_talk", "pass_through": true, "quest_flags": {}},
		{"npc_id": "spirit_b", "position": {"x": 2, "y": 2},
			"dialogue_id": "spirit_b_talk", "pass_through": true, "quest_flags": {}}
	])
	_check(reg.get_blocked_tiles().size() == 0,
		"all pass-through NPCs yield empty blocked tiles")


# ---------------------------------------------------------------------------
# get_npc_at — finds the right NPC by position
# ---------------------------------------------------------------------------
func _test_get_npc_at_finds_npc() -> void:
	print("_test_get_npc_at_finds_npc")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "innkeeper", "position": {"x": 2, "y": 4},
			"dialogue_id": "inn_welcome", "pass_through": false, "quest_flags": {}}
	])
	var npc = reg.get_npc_at(Vector2i(2, 4))
	_check(npc != null, "get_npc_at returns non-null for occupied tile")
	_check(npc.npc_id == "innkeeper", "get_npc_at returns correct NPC")


func _test_get_npc_at_returns_null_for_empty_tile() -> void:
	print("_test_get_npc_at_returns_null_for_empty_tile")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "guard", "position": {"x": 1, "y": 1},
			"dialogue_id": "guard_talk", "pass_through": false, "quest_flags": {}}
	])
	_check(reg.get_npc_at(Vector2i(9, 9)) == null,
		"get_npc_at returns null for unoccupied tile")


# ---------------------------------------------------------------------------
# get_all — returns all NPCs
# ---------------------------------------------------------------------------
func _test_get_all_returns_all_npcs() -> void:
	print("_test_get_all_returns_all_npcs")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "a", "position": {"x": 0, "y": 0},
			"dialogue_id": "a_talk", "pass_through": false, "quest_flags": {}},
		{"npc_id": "b", "position": {"x": 1, "y": 0},
			"dialogue_id": "b_talk", "pass_through": false, "quest_flags": {}},
		{"npc_id": "c", "position": {"x": 2, "y": 0},
			"dialogue_id": "c_talk", "pass_through": true, "quest_flags": {}}
	])
	_check(reg.get_all().size() == 3, "get_all returns all three NPCs")


func _test_get_all_is_duplicate() -> void:
	print("_test_get_all_is_duplicate")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "npc_x", "position": {"x": 3, "y": 3},
			"dialogue_id": "npc_x_talk", "pass_through": false, "quest_flags": {}}
	])
	var all1: Array = reg.get_all()
	all1.clear()
	_check(reg.get_all().size() == 1,
		"get_all returns a duplicate; clearing result does not affect registry")


# ---------------------------------------------------------------------------
# load_npcs — calling twice replaces previous data
# ---------------------------------------------------------------------------
func _test_load_npcs_twice_replaces_previous() -> void:
	print("_test_load_npcs_twice_replaces_previous")
	var reg := NpcRegistryClass.new()
	reg.load_npcs([
		{"npc_id": "old_npc", "position": {"x": 0, "y": 0},
			"dialogue_id": "old_talk", "pass_through": false, "quest_flags": {}}
	])
	reg.load_npcs([
		{"npc_id": "new_npc_a", "position": {"x": 1, "y": 1},
			"dialogue_id": "new_talk_a", "pass_through": false, "quest_flags": {}},
		{"npc_id": "new_npc_b", "position": {"x": 2, "y": 2},
			"dialogue_id": "new_talk_b", "pass_through": false, "quest_flags": {}}
	])
	_check(reg.get_all().size() == 2, "second load_npcs replaces previous registry data")
	_check(reg.get_npc_at(Vector2i(0, 0)) == null,
		"old NPC no longer found after second load_npcs")
