## test_combat_harness.gd
## Integration test: simulates a full 1v1 combat using the rules engine.
## Validates that a seeded combat scenario completes deterministically.
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/integration/test_combat_harness.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DiceRoller = preload("res://rules_engine/core/dice_roller.gd")
const AttackResolver = preload("res://rules_engine/core/attack_resolver.gd")

var _pass_count: int = 0
var _fail_count: int = 0

## Fixed seed used for all deterministic assertions.
const COMBAT_SEED: int = 42

## Hard cap on rounds to prevent an infinite loop in the harness itself.
const MAX_ROUNDS: int = 100


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
	_test_combat_completes()
	_test_combat_is_deterministic()
	_test_winner_has_positive_hp()
	_test_loser_has_zero_or_less_hp()
	_test_different_seeds_may_differ()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

## Build a fresh Fighter combatant dictionary (level-1 Fighter, SRD stats).
## STR 16 (+3), DEX 12 (+1), CON 14 (+2).
## HP 12 (d10 + CON +2), AC 16 (chain mail), longsword 1d8.
func _make_fighter() -> Dictionary:
	return {
		"name": "Fighter",
		"hp": 12,
		"max_hp": 12,
		"ac": 16,
		"dex_modifier": 1,
		"str_modifier": 3,
		"damage_dice": 8,
		"damage_modifier": 3,
		"proficiency_bonus": 2,
	}


## Build a fresh Bandit combatant dictionary (SRD Bandit, CR 1/8).
## STR 11 (+0), DEX 12 (+1).
## HP 11 (2d8+2 average), AC 12 (leather armor), scimitar 1d6.
func _make_bandit() -> Dictionary:
	return {
		"name": "Bandit",
		"hp": 11,
		"max_hp": 11,
		"ac": 12,
		"dex_modifier": 1,
		"str_modifier": 0,
		"damage_dice": 6,
		"damage_modifier": 1,
		"proficiency_bonus": 2,
	}


## Simulate a full combat between a Fighter and a Bandit.
## Returns a result dictionary:
##   "winner"     : String — name of the surviving combatant
##   "loser"      : String — name of the downed combatant
##   "rounds"     : int    — number of rounds played
##   "winner_hp"  : int    — winner's remaining HP
##   "loser_hp"   : int    — loser's final HP (0 or negative)
##   "completed"  : bool   — false only if MAX_ROUNDS was reached without a winner
func _run_combat(seed_value: int) -> Dictionary:
	var roller := DiceRoller.new(seed_value)
	var resolver := AttackResolver.new()

	var fighter := _make_fighter()
	var bandit := _make_bandit()

	# --- Initiative ---
	var fighter_init: int = roller.roll(20) + fighter["dex_modifier"]
	var bandit_init: int = roller.roll(20) + bandit["dex_modifier"]
	print("[Initiative] %s rolled %d | %s rolled %d" % [
		fighter["name"], fighter_init, bandit["name"], bandit_init
	])

	# Ties go to the fighter (player-first tiebreak).
	var turn_order: Array = (
		[fighter, bandit] if fighter_init >= bandit_init else [bandit, fighter]
	)
	print("[Turn order] %s → %s" % [turn_order[0]["name"], turn_order[1]["name"]])

	# --- Combat loop ---
	var round_num: int = 0
	var winner: Dictionary = {}
	var loser: Dictionary = {}

	while round_num < MAX_ROUNDS:
		round_num += 1
		print("\n--- Round %d ---" % round_num)

		for i: int in 2:
			var attacker: Dictionary = turn_order[i]
			var defender: Dictionary = turn_order[1 - i]

			if attacker["hp"] <= 0 or defender["hp"] <= 0:
				continue

			# Attack roll
			var d20: int = roller.roll(20)
			var atk: Dictionary = resolver.resolve(
				d20,
				attacker["str_modifier"],
				attacker["proficiency_bonus"],
				defender["ac"]
			)
			var hit_label: String = (
				"CRITICAL HIT!" if atk["critical"] else ("HIT" if atk["hit"] else "MISS")
			)
			print("[Attack] %s → %s: d20=%d total=%d AC=%d %s" % [
				attacker["name"], defender["name"],
				atk["roll"], atk["total"], defender["ac"], hit_label
			])

			if atk["hit"]:
				# Double weapon dice on a critical hit (SRD rule).
				var dice_count: int = 2 if atk["critical"] else 1
				var damage: int = roller.roll_expression(
					dice_count,
					attacker["damage_dice"],
					attacker["damage_modifier"]
				)
				var hp_before: int = defender["hp"]
				defender["hp"] -= damage
				print("[Damage] %s deals %d damage to %s (HP %d → %d)" % [
					attacker["name"], damage,
					defender["name"], hp_before, defender["hp"]
				])

			if defender["hp"] <= 0:
				print("[Combat End] %s is downed!" % defender["name"])
				winner = attacker
				loser = defender
				break

		if winner.size() > 0:
			break

	if winner.size() > 0:
		print("\n[Result] %s wins after %d round(s)! HP remaining: %d" % [
			winner["name"], round_num, winner["hp"]
		])
	else:
		print("\n[Result] Combat reached %d-round safety limit without a winner." % MAX_ROUNDS)

	return {
		"winner": winner.get("name", ""),
		"loser": loser.get("name", ""),
		"rounds": round_num,
		"winner_hp": winner.get("hp", 0),
		"loser_hp": loser.get("hp", 0),
		"completed": winner.size() > 0,
	}


# ---------------------------------------------------------------------------
# Test: combat reaches a conclusion within MAX_ROUNDS
# ---------------------------------------------------------------------------
func _test_combat_completes() -> void:
	print("\n=== _test_combat_completes ===")
	var outcome: Dictionary = _run_combat(COMBAT_SEED)
	_check(outcome["completed"], "combat reached a conclusion (not cut off by round limit)")
	_check(outcome["rounds"] >= 1, "at least one round was played (got %d)" % outcome["rounds"])
	_check(outcome["rounds"] < MAX_ROUNDS, "combat ended before the %d-round safety limit" % MAX_ROUNDS)
	_check(outcome["winner"] != "", "a winner was declared")
	_check(outcome["loser"] != "", "a loser was declared")


# ---------------------------------------------------------------------------
# Test: same seed → identical outcome (determinism)
# ---------------------------------------------------------------------------
func _test_combat_is_deterministic() -> void:
	print("\n=== _test_combat_is_deterministic ===")
	var a: Dictionary = _run_combat(COMBAT_SEED)
	var b: Dictionary = _run_combat(COMBAT_SEED)
	_check(a["winner"] == b["winner"],
		"same seed → same winner ('%s')" % a["winner"])
	_check(a["rounds"] == b["rounds"],
		"same seed → same round count (%d)" % a["rounds"])
	_check(a["winner_hp"] == b["winner_hp"],
		"same seed → same winner HP remaining (%d)" % a["winner_hp"])
	_check(a["loser_hp"] == b["loser_hp"],
		"same seed → same loser final HP (%d)" % a["loser_hp"])


# ---------------------------------------------------------------------------
# Test: winner finishes with positive HP
# ---------------------------------------------------------------------------
func _test_winner_has_positive_hp() -> void:
	print("\n=== _test_winner_has_positive_hp ===")
	var outcome: Dictionary = _run_combat(COMBAT_SEED)
	_check(outcome["winner_hp"] > 0,
		"winner has positive HP remaining (%d)" % outcome["winner_hp"])


# ---------------------------------------------------------------------------
# Test: loser is at 0 or negative HP
# ---------------------------------------------------------------------------
func _test_loser_has_zero_or_less_hp() -> void:
	print("\n=== _test_loser_has_zero_or_less_hp ===")
	var outcome: Dictionary = _run_combat(COMBAT_SEED)
	_check(outcome["loser_hp"] <= 0,
		"loser HP is 0 or negative (%d)" % outcome["loser_hp"])


# ---------------------------------------------------------------------------
# Test: different seeds can produce different outcomes (sanity check)
# ---------------------------------------------------------------------------
func _test_different_seeds_may_differ() -> void:
	print("\n=== _test_different_seeds_may_differ ===")
	# Run many seeds and confirm the winner is not always the same combatant.
	var winners: Dictionary = {}
	for s: int in 20:
		var outcome: Dictionary = _run_combat(s)
		winners[outcome["winner"]] = true
	_check(winners.size() > 1,
		"across 20 different seeds, more than one unique winner observed (found: %s)" % str(winners.keys()))
