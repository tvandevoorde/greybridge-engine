## test_interact_resolver.gd
## Unit tests for InteractResolver (src/rules_engine/core/interact_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_interact_resolver.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InteractResolverClass = preload("res://rules_engine/core/interact_resolver.gd")
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


func _make_npc(npc_id: String, x: int, y: int) -> NpcDefinitionClass:
	var def := NpcDefinitionClass.new()
	def.npc_id = npc_id
	def.position = Vector2i(x, y)
	def.dialogue_id = npc_id + "_talk"
	def.pass_through = false
	return def


func _run_all_tests() -> void:
	_test_get_interact_target_south()
	_test_get_interact_target_north()
	_test_get_interact_target_east()
	_test_get_interact_target_west()
	_test_get_interact_target_zero_facing_returns_same_tile()
	_test_resolve_finds_npc_at_target()
	_test_resolve_returns_null_no_candidates()
	_test_resolve_returns_null_no_match()
	_test_resolve_ignores_npcs_not_at_target()
	_test_resolve_multiple_candidates_returns_correct()


# ---------------------------------------------------------------------------
# get_interact_target — cardinal directions
# ---------------------------------------------------------------------------
func _test_get_interact_target_south() -> void:
	print("_test_get_interact_target_south")
	var resolver := InteractResolverClass.new()
	var target := resolver.get_interact_target(Vector2i(3, 3), Vector2i(0, 1))
	_check(target == Vector2i(3, 4), "facing south targets tile one step south")


func _test_get_interact_target_north() -> void:
	print("_test_get_interact_target_north")
	var resolver := InteractResolverClass.new()
	var target := resolver.get_interact_target(Vector2i(3, 3), Vector2i(0, -1))
	_check(target == Vector2i(3, 2), "facing north targets tile one step north")


func _test_get_interact_target_east() -> void:
	print("_test_get_interact_target_east")
	var resolver := InteractResolverClass.new()
	var target := resolver.get_interact_target(Vector2i(2, 5), Vector2i(1, 0))
	_check(target == Vector2i(3, 5), "facing east targets tile one step east")


func _test_get_interact_target_west() -> void:
	print("_test_get_interact_target_west")
	var resolver := InteractResolverClass.new()
	var target := resolver.get_interact_target(Vector2i(4, 2), Vector2i(-1, 0))
	_check(target == Vector2i(3, 2), "facing west targets tile one step west")


func _test_get_interact_target_zero_facing_returns_same_tile() -> void:
	print("_test_get_interact_target_zero_facing_returns_same_tile")
	var resolver := InteractResolverClass.new()
	var target := resolver.get_interact_target(Vector2i(5, 5), Vector2i(0, 0))
	_check(target == Vector2i(5, 5), "zero facing vector returns player's own tile")


# ---------------------------------------------------------------------------
# resolve — finds matching NPC in candidates
# ---------------------------------------------------------------------------
func _test_resolve_finds_npc_at_target() -> void:
	print("_test_resolve_finds_npc_at_target")
	var resolver := InteractResolverClass.new()
	var npc := _make_npc("merchant", 4, 3)
	var result = resolver.resolve(Vector2i(4, 3), [npc])
	_check(result != null, "resolve returns non-null when NPC is at target tile")
	_check(result.npc_id == "merchant", "resolve returns the correct NPC")


func _test_resolve_returns_null_no_candidates() -> void:
	print("_test_resolve_returns_null_no_candidates")
	var resolver := InteractResolverClass.new()
	var result = resolver.resolve(Vector2i(4, 3), [])
	_check(result == null, "resolve returns null for empty candidates list")


func _test_resolve_returns_null_no_match() -> void:
	print("_test_resolve_returns_null_no_match")
	var resolver := InteractResolverClass.new()
	var npc := _make_npc("guard", 1, 1)
	var result = resolver.resolve(Vector2i(4, 3), [npc])
	_check(result == null, "resolve returns null when no NPC is at target tile")


func _test_resolve_ignores_npcs_not_at_target() -> void:
	print("_test_resolve_ignores_npcs_not_at_target")
	var resolver := InteractResolverClass.new()
	var npc_a := _make_npc("npc_a", 1, 1)
	var npc_b := _make_npc("npc_b", 2, 2)
	var result = resolver.resolve(Vector2i(3, 3), [npc_a, npc_b])
	_check(result == null,
		"resolve returns null when neither candidate is at target tile")


func _test_resolve_multiple_candidates_returns_correct() -> void:
	print("_test_resolve_multiple_candidates_returns_correct")
	var resolver := InteractResolverClass.new()
	var npc_a := _make_npc("npc_a", 1, 0)
	var npc_b := _make_npc("npc_b", 0, 1)
	var npc_c := _make_npc("npc_c", 2, 0)
	var result = resolver.resolve(Vector2i(0, 1), [npc_a, npc_b, npc_c])
	_check(result != null, "resolve finds the matching NPC among multiple candidates")
	_check(result.npc_id == "npc_b", "resolve returns the NPC at the target tile")
