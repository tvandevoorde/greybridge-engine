## test_combat_flow.gd
## Integration tests for combat flow.
## Exercises CombatStateManager, TurnLifecycleController, ActionEconomy,
## AttackResolver, CombatResolver, CombatGrid, and OpportunityAttack
## working together end-to-end.
##
## Acceptance criteria:
##   - Simulate full combat encounter
##   - Validate turn progression
##   - Validate action economy enforcement
##   - Validate OA triggering
##   - Deterministic with seeded RNG
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/integration/test_combat_flow.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatStateManagerClass = preload("res://combat_runtime/combat_state_manager.gd")
const TurnLifecycleControllerClass = preload("res://combat_runtime/turn_lifecycle_controller.gd")
const CombatResolverClass = preload("res://combat_runtime/combat_resolver.gd")
const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")
const AttackResolverClass = preload("res://rules_engine/core/attack_resolver.gd")
const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")
const CombatGridClass = preload("res://rules_engine/core/combat_grid.gd")
const OpportunityAttackClass = preload("res://rules_engine/core/opportunity_attack.gd")

var _pass_count: int = 0
var _fail_count: int = 0

## Fixed seed for all deterministic assertions.
const COMBAT_SEED: int = 7

## Hard cap on turns to prevent infinite loops.
## Set to 200 to accommodate up to 100 rounds for 2 actors; the encounter
## assertion checks outcome["rounds"] < 100 for a more meaningful bound.
const MAX_TURNS: int = 200


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
	_test_full_encounter_completes()
	_test_turn_progression_two_combatants()
	_test_round_increments_after_full_initiative_cycle()
	_test_action_economy_enforced_per_turn()
	_test_movement_limit_enforced()
	_test_oa_can_trigger_when_reaction_available()
	_test_oa_blocked_when_reaction_spent()
	_test_oa_blocked_when_target_disengaging()
	_test_combat_ends_player_victory()
	_test_combat_ends_player_defeat()
	_test_full_encounter_is_deterministic()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Build a level-1 SRD Fighter actor dictionary.
## STR 16 (+3), DEX 12 (+1), speed 30 ft, HP 12, AC 16, longsword 1d8.
func _make_fighter() -> Dictionary:
	return {
		"id": "fighter",
		"side": "player",
		"current_hp": 12,
		"max_hp": 12,
		"ac": 16,
		"str_modifier": 3,
		"dex_modifier": 1,
		"damage_dice": 8,
		"damage_modifier": 3,
		"proficiency_bonus": 2,
		"speed_ft": 30,
		"loot": [],
	}


## Build a SRD Bandit (CR 1/8) actor dictionary.
## STR 11 (+0), DEX 12 (+1), speed 30 ft, HP 11, AC 12, scimitar 1d6.
func _make_bandit() -> Dictionary:
	return {
		"id": "bandit",
		"side": "enemy",
		"current_hp": 11,
		"max_hp": 11,
		"ac": 12,
		"str_modifier": 0,
		"dex_modifier": 1,
		"damage_dice": 6,
		"damage_modifier": 1,
		"proficiency_bonus": 2,
		"speed_ft": 30,
		"loot": ["gold_piece"],
	}


## Simulate a complete 1v1 combat encounter using the full combat_runtime and
## rules_engine stacks working together.
##
## Returns a Dictionary:
##   "result"   : String     — "player_victory", "player_defeat", or "" (safety limit hit)
##   "rounds"   : int        — round number during which the deciding blow was struck
##   "final_hp" : Dictionary — combatant_id → final current_hp
func _run_full_encounter(seed_value: int) -> Dictionary:
	var roller := DiceRollerClass.new(seed_value)
	var attack_resolver := AttackResolverClass.new()
	var state_manager := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	var combat_resolver := CombatResolverClass.new()

	var fighter := _make_fighter()
	var bandit := _make_bandit()
	var participants := [fighter, bandit]
	var by_id: Dictionary = {"fighter": fighter, "bandit": bandit}

	# Roll initiative (DEX-based; ties go to fighter via lexicographic id ordering).
	var fighter_init: int = roller.roll(20) + fighter["dex_modifier"]
	var bandit_init: int = roller.roll(20) + bandit["dex_modifier"]
	var turn_order_ids: Array = (
		["fighter", "bandit"] if fighter_init >= bandit_init else ["bandit", "fighter"]
	)
	print("[Initiative] fighter=%d bandit=%d  order: %s (ties favour fighter)" % [
		fighter_init, bandit_init, str(turn_order_ids)
	])

	# Set up combat runtime.
	state_manager.start_combat(participants, turn_order_ids)
	var economies: Dictionary = {
		"fighter": ActionEconomyClass.new(fighter["speed_ft"]),
		"bandit": ActionEconomyClass.new(bandit["speed_ft"]),
	}
	tlc.setup(state_manager, economies)

	# Capture result from CombatResolver signal using array mutation (closure-safe).
	var combat_results: Array = []
	combat_resolver.combat_ended.connect(func(outcome: Dictionary) -> void:
		combat_results.append(outcome["result"])
	)

	# --- Main combat loop ---
	var turn_count: int = 0
	var rounds_played: int = 0

	while state_manager.is_active() and turn_count < MAX_TURNS:
		turn_count += 1
		var actor_id: String = state_manager.get_current_combatant_id()
		var actor: Dictionary = by_id[actor_id]

		# Capture the current round before end_turn() may increment it.
		rounds_played = state_manager.get_round()

		tlc.begin_turn()

		# Conscious actor spends their action on a single Attack.
		if actor["current_hp"] > 0:
			var target: Dictionary = {}
			for p in participants:
				if p["id"] != actor_id and p["current_hp"] > 0:
					target = p
					break

			if not target.is_empty() and economies[actor_id].use_action():
				var d20: int = roller.roll(20)
				var atk = attack_resolver.resolve(
					d20, actor["str_modifier"], actor["proficiency_bonus"], target["ac"]
				)
				if atk.hit:
					var dice_count: int = 2 if atk.critical else 1
					var damage: int = roller.roll_expression(
						dice_count, actor["damage_dice"], actor["damage_modifier"]
					)
					target["current_hp"] -= damage
					print("[Round %d] %s → %s: d20=%d %s dmg=%d hp→%d" % [
						rounds_played, actor_id, target["id"],
						d20, ("CRIT" if atk.critical else "HIT"), damage, target["current_hp"]
					])
				else:
					print("[Round %d] %s → %s: d20=%d MISS" % [
						rounds_played, actor_id, target["id"], d20
					])

		tlc.end_turn()

		# Check whether one side has been eliminated.
		combat_resolver.resolve(state_manager, participants)

	var final_hp: Dictionary = {}
	for p in participants:
		final_hp[p["id"]] = p["current_hp"]

	tlc.free()
	combat_resolver.free()

	return {
		"result": combat_results[0] if combat_results.size() > 0 else "",
		"rounds": rounds_played,
		"final_hp": final_hp,
	}


# ---------------------------------------------------------------------------
# Test 1: full encounter completes within the safety limit
# ---------------------------------------------------------------------------
func _test_full_encounter_completes() -> void:
	print("\n=== _test_full_encounter_completes ===")
	var outcome := _run_full_encounter(COMBAT_SEED)
	_check(outcome["result"] != "",
		"combat reached a conclusion (not cut off by the turn safety limit)")
	_check(outcome["rounds"] >= 1, "at least one round was played")
	_check(outcome["rounds"] < 100, "combat ended well before the 100-round safety limit")
	# Exactly one combatant should survive with positive HP.
	var final_hp: Dictionary = outcome["final_hp"]
	var survivors: int = 0
	for id in final_hp:
		if final_hp[id] > 0:
			survivors += 1
	_check(survivors == 1, "exactly one combatant survives with positive HP (got %d)" % survivors)


# ---------------------------------------------------------------------------
# Test 2: turn progression — two combatants alternate correctly over two rounds
# ---------------------------------------------------------------------------
func _test_turn_progression_two_combatants() -> void:
	print("\n=== _test_turn_progression_two_combatants ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	tlc.setup(sm, {})

	var turn_start_ids: Array = []
	tlc.turn_started.connect(func(id: String, _r: int) -> void: turn_start_ids.append(id))
	var turn_end_ids: Array = []
	tlc.turn_ended.connect(func(id: String) -> void: turn_end_ids.append(id))
	var advanced_ids: Array = []
	tlc.turn_advanced.connect(func(id: String, _r: int) -> void: advanced_ids.append(id))

	# Play exactly 4 turns (two full rounds).
	for _i in 4:
		tlc.begin_turn()
		tlc.end_turn()

	_check(turn_start_ids.size() == 4, "turn_started emitted 4 times across two rounds")
	_check(turn_start_ids[0] == "fighter", "round 1 turn 1: fighter goes first")
	_check(turn_start_ids[1] == "bandit",  "round 1 turn 2: bandit goes second")
	_check(turn_start_ids[2] == "fighter", "round 2 turn 1: fighter first again")
	_check(turn_start_ids[3] == "bandit",  "round 2 turn 2: bandit second again")
	_check(turn_end_ids[0] == "fighter", "first turn_ended is fighter")
	_check(turn_end_ids[1] == "bandit",  "second turn_ended is bandit")
	_check(advanced_ids[1] == "fighter", "after bandit ends turn, fighter holds the initiative")
	_check(sm.get_current_combatant_id() == "fighter",
		"initiative wraps back to fighter at the start of round 3")
	tlc.free()


# ---------------------------------------------------------------------------
# Test 3: round counter increments once per full initiative cycle
# ---------------------------------------------------------------------------
func _test_round_increments_after_full_initiative_cycle() -> void:
	print("\n=== _test_round_increments_after_full_initiative_cycle ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	sm.start_combat(
		[{"id": "a"}, {"id": "b"}, {"id": "c"}],
		["a", "b", "c"]
	)
	tlc.setup(sm, {})

	var round_events: Array = []
	tlc.round_started.connect(func(r: int) -> void: round_events.append(r))

	_check(sm.get_round() == 1, "combat begins in round 1")

	# First full cycle: a, b, c each take one turn.
	for _i in 3:
		tlc.begin_turn()
		tlc.end_turn()

	_check(sm.get_round() == 2, "round increments to 2 after the first full 3-actor cycle")
	_check(round_events.size() == 1, "round_started emitted exactly once after one full cycle")
	_check(round_events[0] == 2, "round_started carries round number 2")

	# Second full cycle.
	for _i in 3:
		tlc.begin_turn()
		tlc.end_turn()

	_check(sm.get_round() == 3, "round increments to 3 after the second full cycle")
	_check(round_events.size() == 2, "round_started emitted exactly twice after two full cycles")
	_check(round_events[1] == 3, "second round_started carries round number 3")
	tlc.free()


# ---------------------------------------------------------------------------
# Test 4: action economy enforced — one action and one bonus action per turn,
#         both reset at the start of the actor's next turn
# ---------------------------------------------------------------------------
func _test_action_economy_enforced_per_turn() -> void:
	print("\n=== _test_action_economy_enforced_per_turn ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	var economy_fighter := ActionEconomyClass.new(30)
	var economy_bandit := ActionEconomyClass.new(30)
	tlc.setup(sm, {"fighter": economy_fighter, "bandit": economy_bandit})

	# --- Fighter's first turn ---
	tlc.begin_turn()  # fighter
	_check(economy_fighter.is_action_available() == true,
		"fighter action available at the start of turn 1")
	_check(economy_fighter.use_action() == true,
		"fighter can spend their action")
	_check(economy_fighter.use_action() == false,
		"fighter cannot spend action a second time in the same turn")
	_check(economy_fighter.is_bonus_action_available() == true,
		"bonus action still available after spending action")
	_check(economy_fighter.use_bonus_action() == true,
		"fighter can spend their bonus action")
	_check(economy_fighter.use_bonus_action() == false,
		"fighter cannot spend bonus action a second time in the same turn")
	tlc.end_turn()

	# --- Bandit's first turn ---
	tlc.begin_turn()  # bandit
	_check(economy_bandit.is_action_available() == true,
		"bandit action available on their own turn")
	_check(economy_bandit.use_action() == true,
		"bandit can spend their action")
	tlc.end_turn()

	# --- Fighter's second turn: economy must be reset ---
	tlc.begin_turn()  # fighter (round 2)
	_check(economy_fighter.is_action_available() == true,
		"fighter action resets at the start of turn 2")
	_check(economy_fighter.is_bonus_action_available() == true,
		"fighter bonus action resets at the start of turn 2")
	_check(economy_fighter.movement_remaining_ft == 30,
		"fighter movement resets to 30 ft at the start of turn 2")
	tlc.end_turn()
	tlc.free()


# ---------------------------------------------------------------------------
# Test 5: movement is limited to speed per turn and resets each turn
# ---------------------------------------------------------------------------
func _test_movement_limit_enforced() -> void:
	print("\n=== _test_movement_limit_enforced ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	var economy_fighter := ActionEconomyClass.new(30)
	tlc.setup(sm, {"fighter": economy_fighter, "bandit": ActionEconomyClass.new(30)})

	# Fighter's first turn: partial move, then try to exceed the cap.
	tlc.begin_turn()  # fighter
	_check(economy_fighter.movement_remaining_ft == 30,
		"fighter starts their turn with 30 ft of movement")
	_check(economy_fighter.use_movement(20) == true,
		"moving 20 ft succeeds (30 ft available)")
	_check(economy_fighter.movement_remaining_ft == 10,
		"10 ft remain after moving 20 ft")
	_check(economy_fighter.use_movement(15) == false,
		"cannot move 15 ft when only 10 ft remain")
	_check(economy_fighter.use_movement(10) == true,
		"moving the remaining 10 ft succeeds")
	_check(economy_fighter.movement_remaining_ft == 0,
		"no movement remaining after exhausting speed")
	tlc.end_turn()

	# Bandit's turn (no movement tested here).
	tlc.begin_turn()  # bandit
	tlc.end_turn()

	# Fighter's second turn: movement must be fully restored.
	tlc.begin_turn()  # fighter (round 2)
	_check(economy_fighter.movement_remaining_ft == 30,
		"movement restored to 30 ft at the start of the fighter's next turn")
	tlc.end_turn()
	tlc.free()


# ---------------------------------------------------------------------------
# Test 6: opportunity attack triggers when attacker has reaction and target
#         is not disengaging; reaction is consumed and further OA is blocked
# ---------------------------------------------------------------------------
func _test_oa_can_trigger_when_reaction_available() -> void:
	print("\n=== _test_oa_can_trigger_when_reaction_available ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	# Fighter goes first so begin_turn() resets their reaction.
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	var economy_fighter := ActionEconomyClass.new(30)
	var economy_bandit := ActionEconomyClass.new(30)
	tlc.setup(sm, {"fighter": economy_fighter, "bandit": economy_bandit})

	var grid := CombatGridClass.new()
	grid.place_combatant("fighter", Vector2i(0, 0))
	grid.place_combatant("bandit", Vector2i(1, 0))  # adjacent (5 ft)
	var oa := OpportunityAttackClass.new()

	# Fighter's turn: reaction resets; fighter does not use it.
	tlc.begin_turn()  # fighter
	_check(economy_fighter.is_reaction_available() == true,
		"fighter reaction is available after begin_turn() resets it")
	tlc.end_turn()

	# Bandit's turn: bandit moves out of fighter's reach.
	tlc.begin_turn()  # bandit
	grid.move_combatant("bandit", Vector2i(2, 0))  # now 10 ft away
	var dist_ft: int = grid.distance_ft(
		grid.get_position("fighter"), grid.get_position("bandit")
	)
	_check(dist_ft > 5,
		"bandit has moved outside fighter's 5 ft reach (distance=%d ft)" % dist_ft)

	# OA check: fighter has reaction; bandit is NOT disengaging.
	var oa_result := oa.check(economy_fighter.is_reaction_available(), false)
	_check(oa_result["can_trigger"] == true,
		"OA can trigger: fighter has reaction and bandit did not disengage")
	_check(oa_result["reason"] == "",
		"OA trigger reason is empty string on success")

	# Fighter uses reaction to make the OA.
	_check(economy_fighter.use_reaction() == true,
		"fighter's reaction is successfully consumed for the OA")
	_check(economy_fighter.is_reaction_available() == false,
		"fighter's reaction is now spent")

	# A second OA attempt during the same round must fail.
	var oa_result2 := oa.check(economy_fighter.is_reaction_available(), false)
	_check(oa_result2["can_trigger"] == false,
		"second OA attempt blocked: reaction already spent")
	_check(oa_result2["reason"] == "reaction_spent",
		"second OA reason is 'reaction_spent'")

	tlc.end_turn()
	tlc.free()


# ---------------------------------------------------------------------------
# Test 7: OA is blocked when the attacker's reaction was already spent
# ---------------------------------------------------------------------------
func _test_oa_blocked_when_reaction_spent() -> void:
	print("\n=== _test_oa_blocked_when_reaction_spent ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	var economy_fighter := ActionEconomyClass.new(30)
	tlc.setup(sm, {"fighter": economy_fighter, "bandit": ActionEconomyClass.new(30)})
	var oa := OpportunityAttackClass.new()

	# Fighter's turn resets their reaction; they immediately spend it elsewhere.
	tlc.begin_turn()  # fighter
	_check(economy_fighter.is_reaction_available() == true,
		"fighter reaction available after begin_turn()")
	economy_fighter.use_reaction()  # e.g. used for Shield or Counterspell
	_check(economy_fighter.is_reaction_available() == false,
		"fighter reaction is now spent")
	tlc.end_turn()

	# Bandit's turn: fighter cannot make an OA — reaction is gone.
	tlc.begin_turn()  # bandit
	var result := oa.check(economy_fighter.is_reaction_available(), false)
	_check(result["can_trigger"] == false,
		"OA blocked: fighter's reaction was already spent this round")
	_check(result["reason"] == "reaction_spent",
		"reason is 'reaction_spent'")
	tlc.end_turn()
	tlc.free()


# ---------------------------------------------------------------------------
# Test 8: OA is blocked when the target used the Disengage action
# ---------------------------------------------------------------------------
func _test_oa_blocked_when_target_disengaging() -> void:
	print("\n=== _test_oa_blocked_when_target_disengaging ===")
	var oa := OpportunityAttackClass.new()
	# Direct start_turn() call is intentional here: this test is purely validating
	# the OpportunityAttack rule against a Disengage flag and does not require the
	# full TurnLifecycleController setup.
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	_check(economy.is_reaction_available() == true, "reaction available for this check")

	# Target used the Disengage action — OA must not trigger.
	var result := oa.check(economy.is_reaction_available(), true)
	_check(result["can_trigger"] == false,
		"OA blocked: target used the Disengage action")
	_check(result["reason"] == "target_disengaging",
		"reason is 'target_disengaging'")


# ---------------------------------------------------------------------------
# Test 9: CombatResolver emits correct signals and clears state on victory
# ---------------------------------------------------------------------------
func _test_combat_ends_player_victory() -> void:
	print("\n=== _test_combat_ends_player_victory ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	var cr := CombatResolverClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	tlc.setup(sm, {
		"fighter": ActionEconomyClass.new(30),
		"bandit": ActionEconomyClass.new(30),
	})

	# All enemies are already downed.
	var participants := [
		{"id": "fighter", "side": "player", "current_hp": 10, "loot": []},
		{"id": "bandit",  "side": "enemy",  "current_hp": 0,  "loot": ["gold_piece"]},
	]

	var received_outcomes: Array = []
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcomes.append(o))
	var loot_items: Array = []
	cr.loot_ready.connect(func(r: Array) -> void: loot_items.append_array(r))
	var overworld_events: Array = []
	cr.return_to_overworld.connect(func() -> void: overworld_events.append(true))

	tlc.begin_turn()
	cr.resolve(sm, participants)

	_check(received_outcomes.size() > 0 and received_outcomes[0].get("result", "") == "player_victory",
		"combat_ended result is 'player_victory'")
	_check(loot_items.has("gold_piece"),
		"loot_ready emitted with the bandit's gold_piece")
	_check(overworld_events.size() > 0,
		"return_to_overworld emitted after player victory")
	_check(sm.is_active() == false,
		"CombatStateManager is cleared after combat ends")

	tlc.free()
	cr.free()


# ---------------------------------------------------------------------------
# Test 10: CombatResolver emits correct signals and clears state on defeat
# ---------------------------------------------------------------------------
func _test_combat_ends_player_defeat() -> void:
	print("\n=== _test_combat_ends_player_defeat ===")
	var sm := CombatStateManagerClass.new()
	var tlc := TurnLifecycleControllerClass.new()
	var cr := CombatResolverClass.new()
	sm.start_combat([{"id": "fighter"}, {"id": "bandit"}], ["fighter", "bandit"])
	tlc.setup(sm, {
		"fighter": ActionEconomyClass.new(30),
		"bandit": ActionEconomyClass.new(30),
	})

	# All players are downed.
	var participants := [
		{"id": "fighter", "side": "player", "current_hp": 0,  "loot": []},
		{"id": "bandit",  "side": "enemy",  "current_hp": 8,  "loot": []},
	]

	var received_outcomes: Array = []
	cr.combat_ended.connect(func(o: Dictionary) -> void: received_outcomes.append(o))
	var overworld_events: Array = []
	cr.return_to_overworld.connect(func() -> void: overworld_events.append(true))

	tlc.begin_turn()
	cr.resolve(sm, participants)

	_check(received_outcomes.size() > 0 and received_outcomes[0].get("result", "") == "player_defeat",
		"combat_ended result is 'player_defeat'")
	_check(overworld_events.size() > 0,
		"return_to_overworld emitted after player defeat")
	_check(sm.is_active() == false,
		"CombatStateManager is cleared after player defeat")

	tlc.free()
	cr.free()


# ---------------------------------------------------------------------------
# Test 11: full encounter produces identical outcomes with the same seed
# ---------------------------------------------------------------------------
func _test_full_encounter_is_deterministic() -> void:
	print("\n=== _test_full_encounter_is_deterministic ===")
	var run_a := _run_full_encounter(COMBAT_SEED)
	var run_b := _run_full_encounter(COMBAT_SEED)

	_check(run_a["result"] == run_b["result"],
		"same seed → same result ('%s')" % run_a["result"])
	_check(run_a["rounds"] == run_b["rounds"],
		"same seed → same round count (%d)" % run_a["rounds"])

	var hp_a: Dictionary = run_a["final_hp"]
	var hp_b: Dictionary = run_b["final_hp"]
	for id in hp_a:
		_check(hp_a[id] == hp_b[id],
			"same seed → same final HP for %s (%d)" % [id, hp_a[id]])
