## test_interact_resolver.gd
## Unit tests for InteractResolver (src/rules_engine/core/interact_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_interact_resolver.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InteractResolverClass = preload("res://rules_engine/core/interact_resolver.gd")

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
	_test_get_interact_target_north()
	_test_get_interact_target_south()
	_test_get_interact_target_west()
	_test_get_interact_target_east()
	_test_get_interact_target_arbitrary_position()
	_test_resolve_finds_npc()
	_test_resolve_finds_door()
	_test_resolve_finds_chest()
	_test_resolve_returns_empty_when_no_match()
	_test_resolve_returns_first_match_when_multiple_at_tile()
	_test_resolve_empty_candidates_returns_empty()
	_test_resolve_does_not_match_wrong_tile()


# ---------------------------------------------------------------------------
# get_interact_target -- facing-direction target tile
# ---------------------------------------------------------------------------
func _test_get_interact_target_north() -> void:
	print("_test_get_interact_target_north")
	var r := InteractResolverClass.new()
	var target := r.get_interact_target(Vector2i(3, 4), Vector2i(0, -1))
	_check(target == Vector2i(3, 3), "target is one tile north of position")


func _test_get_interact_target_south() -> void:
	print("_test_get_interact_target_south")
	var r := InteractResolverClass.new()
	var target := r.get_interact_target(Vector2i(3, 4), Vector2i(0, 1))
	_check(target == Vector2i(3, 5), "target is one tile south of position")


func _test_get_interact_target_west() -> void:
	print("_test_get_interact_target_west")
	var r := InteractResolverClass.new()
	var target := r.get_interact_target(Vector2i(3, 4), Vector2i(-1, 0))
	_check(target == Vector2i(2, 4), "target is one tile west of position")


func _test_get_interact_target_east() -> void:
	print("_test_get_interact_target_east")
	var r := InteractResolverClass.new()
	var target := r.get_interact_target(Vector2i(3, 4), Vector2i(1, 0))
	_check(target == Vector2i(4, 4), "target is one tile east of position")


func _test_get_interact_target_arbitrary_position() -> void:
	print("_test_get_interact_target_arbitrary_position")
	var r := InteractResolverClass.new()
	var target := r.get_interact_target(Vector2i(10, 7), Vector2i(0, -1))
	_check(target == Vector2i(10, 6), "target is correct for arbitrary position facing north")


# ---------------------------------------------------------------------------
# resolve -- interactable candidate lookup
# ---------------------------------------------------------------------------
func _test_resolve_finds_npc() -> void:
	print("_test_resolve_finds_npc")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "npc_guard", "position": Vector2i(5, 3)},
	]
	var found := r.resolve(Vector2i(5, 3), candidates)
	_check(not found.is_empty(), "resolve returns non-empty dict for matching NPC tile")
	_check(found["id"] == "npc_guard", "resolve returns correct NPC id")


func _test_resolve_finds_door() -> void:
	print("_test_resolve_finds_door")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "door_east", "position": Vector2i(8, 2)},
	]
	var found := r.resolve(Vector2i(8, 2), candidates)
	_check(not found.is_empty(), "resolve returns non-empty dict for matching door tile")
	_check(found["id"] == "door_east", "resolve returns correct door id")


func _test_resolve_finds_chest() -> void:
	print("_test_resolve_finds_chest")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "chest_1", "position": Vector2i(2, 9)},
	]
	var found := r.resolve(Vector2i(2, 9), candidates)
	_check(not found.is_empty(), "resolve returns non-empty dict for matching chest tile")
	_check(found["id"] == "chest_1", "resolve returns correct chest id")


func _test_resolve_returns_empty_when_no_match() -> void:
	print("_test_resolve_returns_empty_when_no_match")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "npc_guard", "position": Vector2i(5, 3)},
	]
	var found := r.resolve(Vector2i(0, 0), candidates)
	_check(found.is_empty(), "resolve returns empty dict when no candidate matches")


func _test_resolve_returns_first_match_when_multiple_at_tile() -> void:
	print("_test_resolve_returns_first_match_when_multiple_at_tile")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "first", "position": Vector2i(4, 4)},
		{"id": "second", "position": Vector2i(4, 4)},
	]
	var found := r.resolve(Vector2i(4, 4), candidates)
	_check(found["id"] == "first", "resolve returns the first matching candidate")


func _test_resolve_empty_candidates_returns_empty() -> void:
	print("_test_resolve_empty_candidates_returns_empty")
	var r := InteractResolverClass.new()
	var found := r.resolve(Vector2i(1, 1), [])
	_check(found.is_empty(), "resolve returns empty dict when candidates list is empty")


func _test_resolve_does_not_match_wrong_tile() -> void:
	print("_test_resolve_does_not_match_wrong_tile")
	var r := InteractResolverClass.new()
	var candidates: Array = [
		{"id": "chest_2", "position": Vector2i(3, 3)},
		{"id": "npc_elder", "position": Vector2i(6, 1)},
	]
	var found := r.resolve(Vector2i(3, 4), candidates)
	_check(found.is_empty(), "resolve returns empty dict when tile does not match any candidate")
