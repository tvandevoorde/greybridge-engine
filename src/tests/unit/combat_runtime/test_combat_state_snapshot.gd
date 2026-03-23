## test_combat_state_snapshot.gd
## Unit tests for CombatStateManager.take_snapshot() and CombatSnapshot.to_dict()
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_combat_state_snapshot.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatStateManager = preload("res://combat_runtime/combat_state_manager.gd")
const CombatSnapshot = preload("res://rules_engine/core/combat_snapshot.gd")

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
	_test_snapshot_inactive_state()
	_test_snapshot_round_and_turn_index()
	_test_snapshot_current_combatant_id()
	_test_snapshot_initiative_order()
	_test_snapshot_actor_hp()
	_test_snapshot_actor_positions()
	_test_snapshot_actor_without_position()
	_test_snapshot_no_positions_passed()
	_test_snapshot_after_advance_turn()
	_test_snapshot_is_independent_copy()
	_test_to_dict_keys_present()
	_test_to_dict_actors_serialized()
	_test_to_dict_positions_are_plain_ints()


# ---------------------------------------------------------------------------
# Inactive state snapshot
# ---------------------------------------------------------------------------
func _test_snapshot_inactive_state() -> void:
	print("_test_snapshot_inactive_state")
	var m := CombatStateManager.new()
	var snap := m.take_snapshot({})
	_check(snap.round == 0, "round is 0 for inactive combat snapshot")
	_check(snap.turn_index == 0, "turn_index is 0 for inactive combat snapshot")
	_check(snap.current_combatant_id == "", "current_combatant_id is empty for inactive combat snapshot")
	_check(snap.initiative_order.is_empty(), "initiative_order is empty for inactive combat snapshot")
	_check(snap.actors.is_empty(), "actors is empty for inactive combat snapshot")


# ---------------------------------------------------------------------------
# Turn state fields
# ---------------------------------------------------------------------------
func _test_snapshot_round_and_turn_index() -> void:
	print("_test_snapshot_round_and_turn_index")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "player", "current_hp": 10}, {"id": "goblin", "current_hp": 7}],
		["goblin", "player"]
	)
	var snap := m.take_snapshot({})
	_check(snap.round == 1, "round is 1 at combat start")
	_check(snap.turn_index == 0, "turn_index is 0 at combat start")


func _test_snapshot_current_combatant_id() -> void:
	print("_test_snapshot_current_combatant_id")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "player", "current_hp": 10}, {"id": "orc", "current_hp": 15}],
		["orc", "player"]
	)
	var snap := m.take_snapshot({})
	_check(snap.current_combatant_id == "orc", "current_combatant_id is orc (first in initiative)")


# ---------------------------------------------------------------------------
# Initiative order
# ---------------------------------------------------------------------------
func _test_snapshot_initiative_order() -> void:
	print("_test_snapshot_initiative_order")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "hero"}, {"id": "bandit"}],
		["bandit", "hero"]
	)
	var snap := m.take_snapshot({})
	_check(snap.initiative_order.size() == 2, "initiative_order has 2 entries")
	_check(snap.initiative_order[0] == "bandit", "bandit is first in initiative_order")
	_check(snap.initiative_order[1] == "hero", "hero is second in initiative_order")


# ---------------------------------------------------------------------------
# Actor HP
# ---------------------------------------------------------------------------
func _test_snapshot_actor_hp() -> void:
	print("_test_snapshot_actor_hp")
	var m := CombatStateManager.new()
	m.start_combat(
		[
			{"id": "player", "current_hp": 8},
			{"id": "goblin", "current_hp": 3},
		],
		["player", "goblin"]
	)
	var snap := m.take_snapshot({})
	_check(snap.actors.size() == 2, "snapshot contains 2 actors")
	var player_entry: Dictionary = {}
	var goblin_entry: Dictionary = {}
	for a: Dictionary in snap.actors:
		if a["id"] == "player":
			player_entry = a
		elif a["id"] == "goblin":
			goblin_entry = a
	_check(player_entry.get("current_hp", -1) == 8, "player current_hp is 8")
	_check(goblin_entry.get("current_hp", -1) == 3, "goblin current_hp is 3")


# ---------------------------------------------------------------------------
# Actor positions
# ---------------------------------------------------------------------------
func _test_snapshot_actor_positions() -> void:
	print("_test_snapshot_actor_positions")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "hero", "current_hp": 10}, {"id": "orc", "current_hp": 12}],
		["hero", "orc"]
	)
	var positions: Dictionary = {
		"hero": Vector2i(1, 2),
		"orc": Vector2i(5, 3),
	}
	var snap := m.take_snapshot(positions)
	var hero_entry: Dictionary = {}
	var orc_entry: Dictionary = {}
	for a: Dictionary in snap.actors:
		if a["id"] == "hero":
			hero_entry = a
		elif a["id"] == "orc":
			orc_entry = a
	_check(hero_entry.get("position_x", -1) == 1, "hero position_x is 1")
	_check(hero_entry.get("position_y", -1) == 2, "hero position_y is 2")
	_check(orc_entry.get("position_x", -1) == 5, "orc position_x is 5")
	_check(orc_entry.get("position_y", -1) == 3, "orc position_y is 3")


func _test_snapshot_actor_without_position() -> void:
	print("_test_snapshot_actor_without_position")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "rogue", "current_hp": 6}],
		["rogue"]
	)
	# Only pass position for an actor that is NOT in participants
	var snap := m.take_snapshot({"other": Vector2i(0, 0)})
	_check(snap.actors.size() == 1, "snapshot has one actor entry")
	var rogue_entry: Dictionary = snap.actors[0]
	_check(not rogue_entry.has("position_x"), "position_x absent when position not provided")
	_check(not rogue_entry.has("position_y"), "position_y absent when position not provided")


func _test_snapshot_no_positions_passed() -> void:
	print("_test_snapshot_no_positions_passed")
	var m := CombatStateManager.new()
	m.start_combat([{"id": "fighter", "current_hp": 12}], ["fighter"])
	var snap := m.take_snapshot({})
	_check(snap.actors.size() == 1, "snapshot has one actor entry with empty positions")
	_check(not snap.actors[0].has("position_x"), "position_x absent when no positions provided")


# ---------------------------------------------------------------------------
# Snapshot reflects state after advance_turn
# ---------------------------------------------------------------------------
func _test_snapshot_after_advance_turn() -> void:
	print("_test_snapshot_after_advance_turn")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "a", "current_hp": 10}, {"id": "b", "current_hp": 5}],
		["a", "b"]
	)
	m.advance_turn()
	var snap := m.take_snapshot({})
	_check(snap.turn_index == 1, "turn_index is 1 after one advance")
	_check(snap.current_combatant_id == "b", "current_combatant_id is b after advance")
	_check(snap.round == 1, "still round 1 after one advance")


# ---------------------------------------------------------------------------
# Snapshot is an independent copy (mutating state does not affect old snapshot)
# ---------------------------------------------------------------------------
func _test_snapshot_is_independent_copy() -> void:
	print("_test_snapshot_is_independent_copy")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "x", "current_hp": 10}, {"id": "y", "current_hp": 8}],
		["x", "y"]
	)
	var snap := m.take_snapshot({})
	m.advance_turn()
	m.advance_turn()  # wraps to round 2
	_check(snap.round == 1, "snapshot round unchanged after state advances")
	_check(snap.turn_index == 0, "snapshot turn_index unchanged after state advances")
	_check(snap.current_combatant_id == "x", "snapshot current_combatant_id unchanged after state advances")


# ---------------------------------------------------------------------------
# to_dict serialization
# ---------------------------------------------------------------------------
func _test_to_dict_keys_present() -> void:
	print("_test_to_dict_keys_present")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "p1", "current_hp": 9}],
		["p1"]
	)
	var d: Dictionary = m.take_snapshot({}).to_dict()
	_check(d.has("round"), "to_dict has 'round' key")
	_check(d.has("turn_index"), "to_dict has 'turn_index' key")
	_check(d.has("current_combatant_id"), "to_dict has 'current_combatant_id' key")
	_check(d.has("initiative_order"), "to_dict has 'initiative_order' key")
	_check(d.has("actors"), "to_dict has 'actors' key")


func _test_to_dict_actors_serialized() -> void:
	print("_test_to_dict_actors_serialized")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "warrior", "current_hp": 11}],
		["warrior"]
	)
	var d: Dictionary = m.take_snapshot({}).to_dict()
	var actors: Array = d.get("actors", [])
	_check(actors.size() == 1, "to_dict actors has one entry")
	_check(actors[0].get("id", "") == "warrior", "actor id serialized correctly")
	_check(actors[0].get("current_hp", -1) == 11, "actor current_hp serialized correctly")


func _test_to_dict_positions_are_plain_ints() -> void:
	print("_test_to_dict_positions_are_plain_ints")
	var m := CombatStateManager.new()
	m.start_combat(
		[{"id": "mage", "current_hp": 6}],
		["mage"]
	)
	var d: Dictionary = m.take_snapshot({"mage": Vector2i(3, 7)}).to_dict()
	var actor: Dictionary = d["actors"][0]
	_check(actor.get("position_x", -1) == 3, "position_x is plain int 3")
	_check(actor.get("position_y", -1) == 7, "position_y is plain int 7")
	_check(actor["position_x"] is int, "position_x type is int (not Vector2i)")
	_check(actor["position_y"] is int, "position_y type is int (not Vector2i)")
