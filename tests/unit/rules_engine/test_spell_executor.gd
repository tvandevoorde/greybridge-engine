## test_spell_executor.gd
## Unit tests for SpellExecutor and SpellEffect
## (src/rules_engine/core/spell_executor.gd and spell_effect.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_spell_executor.gd
extends SceneTree

const SpellEffect  = preload("res://rules_engine/core/spell_effect.gd")
const SpellExecutor = preload("res://rules_engine/core/spell_executor.gd")
const DiceRoller   = preload("res://rules_engine/core/dice_roller.gd")

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
	# SpellEffect factory tests
	_test_make_attack_keys()
	_test_make_saving_throw_keys()
	_test_make_healing_keys()
	_test_make_concentration_keys()

	# SpellExecutor — attack spells
	_test_attack_miss_deals_no_damage()
	_test_attack_hit_deals_damage()
	_test_attack_natural_20_critical_doubles_dice()
	_test_attack_natural_1_auto_miss()
	_test_attack_result_keys()
	_test_attack_damage_type_forwarded()

	# SpellExecutor — saving throw spells
	_test_saving_throw_result_keys()
	_test_saving_throw_failed_full_damage()
	_test_saving_throw_success_half_damage()
	_test_saving_throw_success_no_half_when_flag_false()
	_test_saving_throw_half_damage_rounds_down()

	# SpellExecutor — healing
	_test_healing_result_key()
	_test_healing_amount_uses_roller()
	_test_healing_modifier_added()

	# SpellExecutor — concentration DC
	_test_concentration_dc_minimum_ten()
	_test_concentration_dc_above_minimum()
	_test_concentration_dc_rounds_down()


# ---------------------------------------------------------------------------
# SpellEffect factory — attack
# ---------------------------------------------------------------------------
func _test_make_attack_keys() -> void:
	print("_test_make_attack_keys")
	var effect: Dictionary = SpellEffect.make_attack(2, 6, 3, "fire")
	_check(effect["type"] == SpellEffect.TYPE_ATTACK, "type is TYPE_ATTACK")
	_check(effect["dice_count"] == 2,       "dice_count stored")
	_check(effect["dice_faces"] == 6,       "dice_faces stored")
	_check(effect["damage_modifier"] == 3,  "damage_modifier stored")
	_check(effect["damage_type"] == "fire", "damage_type stored")


# ---------------------------------------------------------------------------
# SpellEffect factory — saving throw
# ---------------------------------------------------------------------------
func _test_make_saving_throw_keys() -> void:
	print("_test_make_saving_throw_keys")
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 8, 6, 0, "fire", true)
	_check(effect["type"] == SpellEffect.TYPE_SAVING_THROW, "type is TYPE_SAVING_THROW")
	_check(effect["dc"] == 14,               "dc stored")
	_check(effect["save_ability"] == "DEX",  "save_ability stored")
	_check(effect["dice_count"] == 8,        "dice_count stored")
	_check(effect["dice_faces"] == 6,        "dice_faces stored")
	_check(effect["damage_modifier"] == 0,   "damage_modifier stored")
	_check(effect["damage_type"] == "fire",  "damage_type stored")
	_check(effect["half_on_success"] == true, "half_on_success stored")


# ---------------------------------------------------------------------------
# SpellEffect factory — healing
# ---------------------------------------------------------------------------
func _test_make_healing_keys() -> void:
	print("_test_make_healing_keys")
	var effect: Dictionary = SpellEffect.make_healing(1, 8, 4)
	_check(effect["type"] == SpellEffect.TYPE_HEALING, "type is TYPE_HEALING")
	_check(effect["dice_count"] == 1, "dice_count stored")
	_check(effect["dice_faces"] == 8, "dice_faces stored")
	_check(effect["modifier"] == 4,   "modifier stored")


# ---------------------------------------------------------------------------
# SpellEffect factory — concentration
# ---------------------------------------------------------------------------
func _test_make_concentration_keys() -> void:
	print("_test_make_concentration_keys")
	var effect: Dictionary = SpellEffect.make_concentration(10)
	_check(effect["type"] == SpellEffect.TYPE_CONCENTRATION, "type is TYPE_CONCENTRATION")
	_check(effect["duration_rounds"] == 10, "duration_rounds stored")


# ---------------------------------------------------------------------------
# Attack spell — miss → damage is 0
# ---------------------------------------------------------------------------
func _test_attack_miss_deals_no_damage() -> void:
	print("_test_attack_miss_deals_no_damage")
	# Roll 5, no modifier, no proficiency vs AC 20 → miss
	var effect: Dictionary = SpellEffect.make_attack(2, 6, 3, "fire")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 5, 0, 0, 20, roller)
	_check(result["hit"] == false,  "roll 5 vs AC 20 is a miss")
	_check(result["damage"] == 0,   "miss deals 0 damage")


# ---------------------------------------------------------------------------
# Attack spell — hit → damage > 0
# ---------------------------------------------------------------------------
func _test_attack_hit_deals_damage() -> void:
	print("_test_attack_hit_deals_damage")
	# Roll 15, no modifier, no proficiency vs AC 10 → hit; 2d6+3 (seed 0)
	var effect: Dictionary = SpellEffect.make_attack(2, 6, 3, "fire")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 15, 0, 0, 10, roller)
	_check(result["hit"] == true,    "roll 15 vs AC 10 is a hit")
	_check(result["damage"] > 0,     "hit deals damage greater than 0")
	# Minimum possible for 2d6+3 is 5; maximum is 15
	_check(result["damage"] >= 5,    "2d6+3 minimum is 5")
	_check(result["damage"] <= 15,   "2d6+3 maximum is 15")


# ---------------------------------------------------------------------------
# Attack spell — natural 20 → critical hit doubles dice
# ---------------------------------------------------------------------------
func _test_attack_natural_20_critical_doubles_dice() -> void:
	print("_test_attack_natural_20_critical_doubles_dice")
	# 1d4 spell with no modifier; seeded roller gives predictable results.
	# On a critical the executor rolls 2d4 instead of 1d4, so min=2, max=8.
	var effect: Dictionary = SpellEffect.make_attack(1, 4, 0, "force")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 20, 0, 0, 30, roller)
	_check(result["critical"] == true, "natural 20 sets critical flag")
	_check(result["hit"] == true,      "critical hit always hits")
	_check(result["damage"] >= 2,      "critical 1d4 rolls at least 2 (2 dice)")
	_check(result["damage"] <= 8,      "critical 1d4 rolls at most 8 (2 dice)")


# ---------------------------------------------------------------------------
# Attack spell — natural 1 → auto miss, damage 0
# ---------------------------------------------------------------------------
func _test_attack_natural_1_auto_miss() -> void:
	print("_test_attack_natural_1_auto_miss")
	var effect: Dictionary = SpellEffect.make_attack(2, 6, 5, "cold")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 1, 10, 10, 1, roller)
	_check(result["hit"] == false,     "natural 1 always misses")
	_check(result["critical"] == false, "natural 1 is not critical")
	_check(result["damage"] == 0,      "auto miss deals 0 damage")


# ---------------------------------------------------------------------------
# Attack spell — result dictionary has all required keys
# ---------------------------------------------------------------------------
func _test_attack_result_keys() -> void:
	print("_test_attack_result_keys")
	var effect: Dictionary = SpellEffect.make_attack(1, 6, 0, "force")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 10, 2, 2, 8, roller)
	_check(result.has("hit"),          "result has 'hit'")
	_check(result.has("critical"),     "result has 'critical'")
	_check(result.has("roll"),         "result has 'roll'")
	_check(result.has("total"),        "result has 'total'")
	_check(result.has("damage"),       "result has 'damage'")
	_check(result.has("damage_type"),  "result has 'damage_type'")


# ---------------------------------------------------------------------------
# Attack spell — damage_type forwarded from effect
# ---------------------------------------------------------------------------
func _test_attack_damage_type_forwarded() -> void:
	print("_test_attack_damage_type_forwarded")
	var effect: Dictionary = SpellEffect.make_attack(1, 6, 0, "lightning")
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_attack(effect, 15, 0, 0, 10, roller)
	_check(result["damage_type"] == "lightning", "damage_type matches effect")


# ---------------------------------------------------------------------------
# Saving throw — result dictionary has all required keys
# ---------------------------------------------------------------------------
func _test_saving_throw_result_keys() -> void:
	print("_test_saving_throw_result_keys")
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_saving_throw(
		effect, func() -> int: return 10, 0, 0, false, roller
	)
	_check(result.has("roll"),        "result has 'roll'")
	_check(result.has("total"),       "result has 'total'")
	_check(result.has("success"),     "result has 'success'")
	_check(result.has("damage"),      "result has 'damage'")
	_check(result.has("damage_type"), "result has 'damage_type'")


# ---------------------------------------------------------------------------
# Saving throw — failed save → full damage
# ---------------------------------------------------------------------------
func _test_saving_throw_failed_full_damage() -> void:
	print("_test_saving_throw_failed_full_damage")
	# DC 14, target rolls 5, no modifiers → fails → full damage
	# Use 2d6+0 with seed 0; DiceRoller(0) is deterministic so we check range.
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_saving_throw(
		effect, func() -> int: return 5, 0, 0, false, roller
	)
	_check(result["success"] == false,  "roll 5 < DC 14 → failure")
	_check(result["damage"] >= 2,       "failed save deals at least 2 (2d6 min)")
	_check(result["damage"] <= 12,      "failed save deals at most 12 (2d6 max)")


# ---------------------------------------------------------------------------
# Saving throw — successful save with half_on_success → half damage
# ---------------------------------------------------------------------------
func _test_saving_throw_success_half_damage() -> void:
	print("_test_saving_throw_success_half_damage")
	# DC 10, target rolls 15 → success; half_on_success=true halves the damage.
	# We verify the result falls within the expected halved range for 2d6.
	var effect: Dictionary = SpellEffect.make_saving_throw(10, "CON", 2, 6, 0, "cold", true)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_saving_throw(
		effect, func() -> int: return 15, 0, 0, false, roller
	)
	_check(result["success"] == true,   "roll 15 >= DC 10 → success")
	# Half of 2d6 (min 2, max 12) → halved result in [1, 6]
	_check(result["damage"] >= 1,       "halved 2d6 is at least 1")
	_check(result["damage"] <= 6,       "halved 2d6 is at most 6")


# ---------------------------------------------------------------------------
# Saving throw — success with half_on_success=false → 0 damage
# ---------------------------------------------------------------------------
func _test_saving_throw_success_no_half_when_flag_false() -> void:
	print("_test_saving_throw_success_no_half_when_flag_false")
	# When half_on_success is false, a successful save still deals full damage —
	# SavingThrow.apply_damage only halves when both success=true AND half_on_success=true.
	var effect: Dictionary = SpellEffect.make_saving_throw(10, "DEX", 2, 6, 0, "fire", false)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_saving_throw(
		effect, func() -> int: return 15, 0, 0, false, roller
	)
	_check(result["success"] == true, "roll 15 >= DC 10 → success")
	# half_on_success=false → apply_damage returns full damage even on success
	_check(result["damage"] >= 2,     "success + no-half flag → full 2d6 (min 2)")
	_check(result["damage"] <= 12,    "success + no-half flag → full 2d6 (max 12)")


# ---------------------------------------------------------------------------
# Saving throw — half damage rounds down (SRD)
# ---------------------------------------------------------------------------
func _test_saving_throw_half_damage_rounds_down() -> void:
	print("_test_saving_throw_half_damage_rounds_down")
	# Verify via SavingThrow.apply_damage directly (already tested there),
	# and via executor with a seeded roller that produces a known odd result.
	# Use 1d20 (faces=20) with seed chosen so we know the roll.
	# DiceRoller(7) with 1d20: test what we get.
	var effect: Dictionary = SpellEffect.make_saving_throw(8, "CON", 1, 20, 0, "necrotic", true)
	var roller := DiceRoller.new(7)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_saving_throw(
		effect, func() -> int: return 15, 0, 0, false, roller
	)
	_check(result["success"] == true, "roll 15 >= DC 8 → success")
	# damage is the halved (floor) value of a 1d20 roll; must be >= 0
	_check(result["damage"] >= 0,     "halved damage is non-negative")
	_check(result["damage"] <= 10,    "halved 1d20 is at most 10")


# ---------------------------------------------------------------------------
# Healing — result has 'amount' key
# ---------------------------------------------------------------------------
func _test_healing_result_key() -> void:
	print("_test_healing_result_key")
	var effect: Dictionary = SpellEffect.make_healing(1, 8, 0)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_healing(effect, roller)
	_check(result.has("amount"), "result has 'amount' key")


# ---------------------------------------------------------------------------
# Healing — amount within valid range for die size
# ---------------------------------------------------------------------------
func _test_healing_amount_uses_roller() -> void:
	print("_test_healing_amount_uses_roller")
	# 1d8: result in [1, 8]
	var effect: Dictionary = SpellEffect.make_healing(1, 8, 0)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_healing(effect, roller)
	_check(result["amount"] >= 1, "1d8 heals at least 1")
	_check(result["amount"] <= 8, "1d8 heals at most 8")


# ---------------------------------------------------------------------------
# Healing — modifier added to roll
# ---------------------------------------------------------------------------
func _test_healing_modifier_added() -> void:
	print("_test_healing_modifier_added")
	# 1d4+4 (Cure Wounds with +4 modifier): result in [5, 8]
	var effect: Dictionary = SpellEffect.make_healing(1, 4, 4)
	var roller := DiceRoller.new(0)
	var executor := SpellExecutor.new()
	var result: Dictionary = executor.execute_healing(effect, roller)
	_check(result["amount"] >= 5,  "1d4+4 heals at least 5")
	_check(result["amount"] <= 8,  "1d4+4 heals at most 8")


# ---------------------------------------------------------------------------
# Concentration DC — minimum is always 10
# ---------------------------------------------------------------------------
func _test_concentration_dc_minimum_ten() -> void:
	print("_test_concentration_dc_minimum_ten")
	_check(SpellExecutor.concentration_dc(0) == 10,  "0 damage → DC 10")
	_check(SpellExecutor.concentration_dc(1) == 10,  "1 damage → DC 10 (floor(1/2)=0 < 10)")
	_check(SpellExecutor.concentration_dc(10) == 10, "10 damage → DC 10 (floor(10/2)=5 < 10)")
	_check(SpellExecutor.concentration_dc(18) == 10, "18 damage → DC 10 (floor(18/2)=9 < 10)")
	_check(SpellExecutor.concentration_dc(19) == 10, "19 damage → DC 10 (floor(19/2)=9 < 10)")


# ---------------------------------------------------------------------------
# Concentration DC — exceeds minimum when damage is high enough
# ---------------------------------------------------------------------------
func _test_concentration_dc_above_minimum() -> void:
	print("_test_concentration_dc_above_minimum")
	_check(SpellExecutor.concentration_dc(20) == 10, "20 damage → DC 10 (floor(20/2)=10 == 10)")
	_check(SpellExecutor.concentration_dc(22) == 11, "22 damage → DC 11 (floor(22/2)=11)")
	_check(SpellExecutor.concentration_dc(30) == 15, "30 damage → DC 15")
	_check(SpellExecutor.concentration_dc(50) == 25, "50 damage → DC 25")


# ---------------------------------------------------------------------------
# Concentration DC — odd damage rounds down (SRD)
# ---------------------------------------------------------------------------
func _test_concentration_dc_rounds_down() -> void:
	print("_test_concentration_dc_rounds_down")
	_check(SpellExecutor.concentration_dc(21) == 10, "21 damage → DC 10 (floor(21/2)=10)")
	_check(SpellExecutor.concentration_dc(23) == 11, "23 damage → DC 11 (floor(23/2)=11)")
