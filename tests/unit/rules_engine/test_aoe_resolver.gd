## test_aoe_resolver.gd
## Unit tests for AoEResolver (src/rules_engine/core/aoe_resolver.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_aoe_resolver.gd
extends SceneTree

const AoETemplate = preload("res://rules_engine/core/aoe_template.gd")
const AoEResolver  = preload("res://rules_engine/core/aoe_resolver.gd")
const SpellEffect  = preload("res://rules_engine/core/spell_effect.gd")
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
	_test_actor_outside_area_excluded()
	_test_actor_inside_radius_included()
	_test_result_has_required_keys()
	_test_failed_save_deals_full_damage()
	_test_successful_save_half_damage()
	_test_successful_save_no_half_when_flag_false()
	_test_multiple_actors_only_affected_returned()
	_test_cone_template_filters_actors()


# ---------------------------------------------------------------------------
# Actor whose tile is outside the AoE gets no entry in results
# ---------------------------------------------------------------------------
func _test_actor_outside_area_excluded() -> void:
	print("_test_actor_outside_area_excluded")
	# 10 ft radius centred at (0,0) = 2 tiles; actor at (5,0) is far outside.
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor: Dictionary = {
		"position": Vector2i(5, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 10
	)
	_check(results.size() == 0, "actor outside radius area produces no results")


# ---------------------------------------------------------------------------
# Actor whose tile is inside the radius area is included in results
# ---------------------------------------------------------------------------
func _test_actor_inside_radius_included() -> void:
	print("_test_actor_inside_radius_included")
	# 10 ft radius centred at (0,0) = 2 tiles; actor at (1,0) is inside.
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 10
	)
	_check(results.size() == 1, "actor inside radius area produces one result entry")


# ---------------------------------------------------------------------------
# Result dictionary contains all required keys
# ---------------------------------------------------------------------------
func _test_result_has_required_keys() -> void:
	print("_test_result_has_required_keys")
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 10
	)
	var r: Dictionary = results[0]
	_check(r.has("actor"),       "result has 'actor' key")
	_check(r.has("roll"),        "result has 'roll' key")
	_check(r.has("total"),       "result has 'total' key")
	_check(r.has("success"),     "result has 'success' key")
	_check(r.has("damage"),      "result has 'damage' key")
	_check(r.has("damage_type"), "result has 'damage_type' key")
	_check(r["actor"] == actor,  "actor reference is preserved in result")


# ---------------------------------------------------------------------------
# Failed saving throw delivers full damage
# ---------------------------------------------------------------------------
func _test_failed_save_deals_full_damage() -> void:
	print("_test_failed_save_deals_full_damage")
	# DC 14, actor rolls 5 (fails), half_on_success=true → full 2d6 damage.
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 5
	)
	var r: Dictionary = results[0]
	_check(r["success"] == false, "roll 5 vs DC 14 → failure")
	# Full 2d6: min 2, max 12
	_check(r["damage"] >= 2,      "failed save deals at least 2 (2d6 min)")
	_check(r["damage"] <= 12,     "failed save deals at most 12 (2d6 max)")


# ---------------------------------------------------------------------------
# Successful save with half_on_success=true delivers halved damage
# ---------------------------------------------------------------------------
func _test_successful_save_half_damage() -> void:
	print("_test_successful_save_half_damage")
	# DC 10, actor rolls 15 (succeeds), half_on_success=true → half 2d6 damage.
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(10, "DEX", 2, 6, 0, "fire", true)
	var actor: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 15
	)
	var r: Dictionary = results[0]
	_check(r["success"] == true,  "roll 15 >= DC 10 → success")
	# Half of 2d6 (2..12): halved result in [1, 6]
	_check(r["damage"] >= 1,      "halved damage is at least 1")
	_check(r["damage"] <= 6,      "halved 2d6 is at most 6")


# ---------------------------------------------------------------------------
# Successful save with half_on_success=false delivers full damage
# ---------------------------------------------------------------------------
func _test_successful_save_no_half_when_flag_false() -> void:
	print("_test_successful_save_no_half_when_flag_false")
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(10, "DEX", 2, 6, 0, "fire", false)
	var actor: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor], effect, roller, func() -> int: return 15
	)
	var r: Dictionary = results[0]
	_check(r["success"] == true,  "roll 15 >= DC 10 → success")
	# half_on_success=false → full 2d6: [2, 12]
	_check(r["damage"] >= 2,      "success with no-half flag → full 2d6 (min 2)")
	_check(r["damage"] <= 12,     "success with no-half flag → full 2d6 (max 12)")


# ---------------------------------------------------------------------------
# Multiple actors — only those inside the area appear in results
# ---------------------------------------------------------------------------
func _test_multiple_actors_only_affected_returned() -> void:
	print("_test_multiple_actors_only_affected_returned")
	# 10 ft radius at (0,0) = 2 tiles.
	# actor_a at (1,0) → inside; actor_b at (5,5) → outside.
	var template: Dictionary = AoETemplate.make_radius(Vector2i(0, 0), 10)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor_a: Dictionary = {
		"position": Vector2i(1, 0),
		"ability_modifier": 2,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var actor_b: Dictionary = {
		"position": Vector2i(5, 5),
		"ability_modifier": 1,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor_a, actor_b], effect, roller, func() -> int: return 10
	)
	_check(results.size() == 1, "only one actor inside 10ft radius area")
	_check(results[0]["actor"] == actor_a, "result belongs to the actor inside the area")


# ---------------------------------------------------------------------------
# Cone template — actors inside and outside the cone are filtered correctly
# ---------------------------------------------------------------------------
func _test_cone_template_filters_actors() -> void:
	print("_test_cone_template_filters_actors")
	# Cone pointing right (+x), 15 ft = 3 tiles, origin (0,0).
	# actor_in at (2,0) → directly ahead → inside.
	# actor_out at (-1,0) → behind origin → outside.
	var template: Dictionary = AoETemplate.make_cone(Vector2i(0, 0), Vector2(1, 0), 15)
	var effect: Dictionary = SpellEffect.make_saving_throw(14, "DEX", 2, 6, 0, "fire", true)
	var actor_in: Dictionary = {
		"position": Vector2i(2, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var actor_out: Dictionary = {
		"position": Vector2i(-1, 0),
		"ability_modifier": 0,
		"proficiency_bonus": 2,
		"is_proficient": false,
	}
	var roller := DiceRoller.new(0)
	var resolver := AoEResolver.new()
	var results: Array = resolver.resolve_area(
		template, [actor_in, actor_out], effect, roller, func() -> int: return 10
	)
	_check(results.size() == 1,                   "only one actor inside cone area")
	_check(results[0]["actor"] == actor_in,        "result belongs to actor inside the cone")
