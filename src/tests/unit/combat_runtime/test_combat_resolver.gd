## test_combat_resolver.gd
## Unit tests for CombatResolver (src/combat_runtime/combat_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_combat_resolver.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatResolverClass = preload("res://combat_runtime/combat_resolver.gd")
const CombatStateManagerClass = preload("res://combat_runtime/combat_state_manager.gd")

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
	_test_check_ongoing_when_both_sides_alive()
	_test_check_player_victory_when_all_enemies_down()
	_test_check_player_defeat_when_all_players_down()
	_test_check_ongoing_when_some_enemies_alive()
	_test_check_ongoing_when_some_players_alive()
	_test_check_ongoing_when_no_enemy_side()
	_test_check_ongoing_when_no_player_side()
	_test_check_ongoing_when_empty_participants()
	_test_collect_rewards_from_defeated_enemies()
	_test_collect_rewards_ignores_alive_enemies()
	_test_collect_rewards_ignores_player_side()
	_test_collect_rewards_empty_loot_field()
	_test_collect_rewards_multiple_enemies()
	_test_resolve_no_op_when_combat_ongoing()
	_test_resolve_ends_combat_state_on_victory()
	_test_resolve_ends_combat_state_on_defeat()
	_test_resolve_emits_combat_ended_on_victory()
	_test_resolve_emits_combat_ended_on_defeat()
	_test_resolve_emits_loot_ready_on_victory()
	_test_resolve_no_loot_ready_on_defeat()
	_test_resolve_emits_return_to_overworld_on_victory()
	_test_resolve_emits_return_to_overworld_on_defeat()
	_test_resolve_outcome_contains_rewards_on_victory()
	_test_resolve_outcome_rewards_empty_on_defeat()


# ---------------------------------------------------------------------------
# check_for_combat_end — ongoing conditions
# ---------------------------------------------------------------------------
func _test_check_ongoing_when_both_sides_alive() -> void:
	print("_test_check_ongoing_when_both_sides_alive")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 10},
		{"id": "goblin", "side": "enemy", "current_hp": 5},
	]
	_check(cr.check_for_combat_end(participants) == "", "returns '' when both sides have HP")
	cr.free()


func _test_check_ongoing_when_some_enemies_alive() -> void:
	print("_test_check_ongoing_when_some_enemies_alive")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 8},
		{"id": "goblin1", "side": "enemy", "current_hp": 0},
		{"id": "goblin2", "side": "enemy", "current_hp": 3},
	]
	_check(cr.check_for_combat_end(participants) == "", "returns '' when at least one enemy has HP")
	cr.free()


func _test_check_ongoing_when_some_players_alive() -> void:
	print("_test_check_ongoing_when_some_players_alive")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player1", "side": "player", "current_hp": 0},
		{"id": "player2", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 2},
	]
	_check(cr.check_for_combat_end(participants) == "", "returns '' when at least one player has HP")
	cr.free()


func _test_check_ongoing_when_no_enemy_side() -> void:
	print("_test_check_ongoing_when_no_enemy_side")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 10},
	]
	_check(cr.check_for_combat_end(participants) == "", "returns '' when no enemies present")
	cr.free()


func _test_check_ongoing_when_no_player_side() -> void:
	print("_test_check_ongoing_when_no_player_side")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "goblin", "side": "enemy", "current_hp": 5},
	]
	_check(cr.check_for_combat_end(participants) == "", "returns '' when no players present")
	cr.free()


func _test_check_ongoing_when_empty_participants() -> void:
	print("_test_check_ongoing_when_empty_participants")
	var cr := CombatResolverClass.new()
	_check(cr.check_for_combat_end([]) == "", "returns '' for empty participants")
	cr.free()


# ---------------------------------------------------------------------------
# check_for_combat_end — terminal conditions
# ---------------------------------------------------------------------------
func _test_check_player_victory_when_all_enemies_down() -> void:
	print("_test_check_player_victory_when_all_enemies_down")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 6},
		{"id": "goblin", "side": "enemy", "current_hp": 0},
	]
	_check(
		cr.check_for_combat_end(participants) == "player_victory",
		"returns 'player_victory' when all enemies at 0 HP"
	)
	cr.free()


func _test_check_player_defeat_when_all_players_down() -> void:
	print("_test_check_player_defeat_when_all_players_down")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7},
	]
	_check(
		cr.check_for_combat_end(participants) == "player_defeat",
		"returns 'player_defeat' when all players at 0 HP"
	)
	cr.free()


# ---------------------------------------------------------------------------
# collect_rewards
# ---------------------------------------------------------------------------
func _test_collect_rewards_from_defeated_enemies() -> void:
	print("_test_collect_rewards_from_defeated_enemies")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 0, "loot": ["gold_piece", "dagger"]},
	]
	var rewards := cr.collect_rewards(participants)
	_check(rewards.size() == 2, "two loot items collected from defeated enemy")
	_check(rewards.has("gold_piece"), "gold_piece in rewards")
	_check(rewards.has("dagger"), "dagger in rewards")
	cr.free()


func _test_collect_rewards_ignores_alive_enemies() -> void:
	print("_test_collect_rewards_ignores_alive_enemies")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 3, "loot": ["gold_piece"]},
	]
	var rewards := cr.collect_rewards(participants)
	_check(rewards.size() == 0, "no rewards collected from alive enemies")
	cr.free()


func _test_collect_rewards_ignores_player_side() -> void:
	print("_test_collect_rewards_ignores_player_side")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0, "loot": ["shield"]},
		{"id": "goblin", "side": "enemy", "current_hp": 0, "loot": ["sword"]},
	]
	var rewards := cr.collect_rewards(participants)
	_check(rewards.size() == 1, "only one loot item collected (from enemy, not player)")
	_check(rewards.has("sword"), "sword from enemy is in rewards")
	_check(not rewards.has("shield"), "shield from player is not in rewards")
	cr.free()


func _test_collect_rewards_empty_loot_field() -> void:
	print("_test_collect_rewards_empty_loot_field")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0},
	]
	var rewards := cr.collect_rewards(participants)
	_check(rewards.size() == 0, "no rewards when defeated enemy has no loot field")
	cr.free()


func _test_collect_rewards_multiple_enemies() -> void:
	print("_test_collect_rewards_multiple_enemies")
	var cr := CombatResolverClass.new()
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin1", "side": "enemy", "current_hp": 0, "loot": ["gold_piece"]},
		{"id": "goblin2", "side": "enemy", "current_hp": 0, "loot": ["arrow", "arrow"]},
	]
	var rewards := cr.collect_rewards(participants)
	_check(rewards.size() == 3, "rewards collected from all defeated enemies")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — no-op when combat is ongoing
# ---------------------------------------------------------------------------
func _test_resolve_no_op_when_combat_ongoing() -> void:
	print("_test_resolve_no_op_when_combat_ongoing")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 10},
		{"id": "goblin", "side": "enemy", "current_hp": 5},
	]
	var ended_emitted: bool = false
	cr.combat_ended.connect(func(_o: Dictionary) -> void: ended_emitted = true)
	cr.resolve(sm, participants)
	_check(sm.is_active() == true, "combat remains active when no end condition")
	_check(ended_emitted == false, "combat_ended not emitted when no end condition")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — state cleared
# ---------------------------------------------------------------------------
func _test_resolve_ends_combat_state_on_victory() -> void:
	print("_test_resolve_ends_combat_state_on_victory")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0},
	]
	cr.resolve(sm, participants)
	_check(sm.is_active() == false, "combat state cleared after player victory")
	_check(sm.get_round() == 0, "round reset to 0 after player victory")
	_check(sm.get_participants().size() == 0, "participants cleared after player victory")
	cr.free()


func _test_resolve_ends_combat_state_on_defeat() -> void:
	print("_test_resolve_ends_combat_state_on_defeat")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7},
	]
	cr.resolve(sm, participants)
	_check(sm.is_active() == false, "combat state cleared after player defeat")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — combat_ended signal
# ---------------------------------------------------------------------------
func _test_resolve_emits_combat_ended_on_victory() -> void:
	print("_test_resolve_emits_combat_ended_on_victory")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0},
	]
	var received_outcome: Dictionary = {}
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcome = o)
	cr.resolve(sm, participants)
	_check(received_outcome.get("result", "") == "player_victory", "combat_ended result is player_victory")
	cr.free()


func _test_resolve_emits_combat_ended_on_defeat() -> void:
	print("_test_resolve_emits_combat_ended_on_defeat")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7},
	]
	var received_outcome: Dictionary = {}
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcome = o)
	cr.resolve(sm, participants)
	_check(received_outcome.get("result", "") == "player_defeat", "combat_ended result is player_defeat")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — loot_ready signal
# ---------------------------------------------------------------------------
func _test_resolve_emits_loot_ready_on_victory() -> void:
	print("_test_resolve_emits_loot_ready_on_victory")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0, "loot": ["gold_piece"]},
	]
	var loot_received: Array = []
	cr.loot_ready.connect(func(r: Array) -> void: loot_received.append_array(r))
	cr.resolve(sm, participants)
	_check(loot_received.size() == 1, "loot_ready emitted with one item on victory")
	_check(loot_received.has("gold_piece"), "gold_piece present in loot_ready payload")
	cr.free()


func _test_resolve_no_loot_ready_on_defeat() -> void:
	print("_test_resolve_no_loot_ready_on_defeat")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7, "loot": ["gold_piece"]},
	]
	var loot_ready_emitted: bool = false
	cr.loot_ready.connect(func(_r: Array) -> void: loot_ready_emitted = true)
	cr.resolve(sm, participants)
	_check(loot_ready_emitted == false, "loot_ready not emitted on player defeat")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — return_to_overworld signal
# ---------------------------------------------------------------------------
func _test_resolve_emits_return_to_overworld_on_victory() -> void:
	print("_test_resolve_emits_return_to_overworld_on_victory")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0},
	]
	var overworld_return_emitted: bool = false
	cr.return_to_overworld.connect(func() -> void: overworld_return_emitted = true)
	cr.resolve(sm, participants)
	_check(overworld_return_emitted == true, "return_to_overworld emitted on player victory")
	cr.free()


func _test_resolve_emits_return_to_overworld_on_defeat() -> void:
	print("_test_resolve_emits_return_to_overworld_on_defeat")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7},
	]
	var overworld_return_emitted: bool = false
	cr.return_to_overworld.connect(func() -> void: overworld_return_emitted = true)
	cr.resolve(sm, participants)
	_check(overworld_return_emitted == true, "return_to_overworld emitted on player defeat")
	cr.free()


# ---------------------------------------------------------------------------
# resolve — outcome rewards content
# ---------------------------------------------------------------------------
func _test_resolve_outcome_contains_rewards_on_victory() -> void:
	print("_test_resolve_outcome_contains_rewards_on_victory")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 5},
		{"id": "goblin", "side": "enemy", "current_hp": 0, "loot": ["dagger"]},
	]
	var received_outcome: Dictionary = {}
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcome = o)
	cr.resolve(sm, participants)
	var rewards: Array = received_outcome.get("rewards", [])
	_check(rewards.size() == 1, "outcome rewards has one item")
	_check(rewards.has("dagger"), "dagger present in outcome rewards")
	cr.free()


func _test_resolve_outcome_rewards_empty_on_defeat() -> void:
	print("_test_resolve_outcome_rewards_empty_on_defeat")
	var cr := CombatResolverClass.new()
	var sm := CombatStateManagerClass.new()
	sm.start_combat([{"id": "player"}, {"id": "goblin"}], ["player", "goblin"])
	var participants := [
		{"id": "player", "side": "player", "current_hp": 0},
		{"id": "goblin", "side": "enemy", "current_hp": 7, "loot": ["gold_piece"]},
	]
	var received_outcome: Dictionary = {}
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcome = o)
	cr.resolve(sm, participants)
	var rewards: Array = received_outcome.get("rewards", [])
	_check(rewards.size() == 0, "outcome rewards is empty on player defeat")
	cr.free()
