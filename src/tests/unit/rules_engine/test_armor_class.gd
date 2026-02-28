## test_armor_class.gd
## Unit tests for ArmorClassClass (src/rules_engine/core/armor_class.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/rules_engine/test_armor_class.gd
extends SceneTree

const ArmorClassClassClass = preload("res://rules_engine/core/armor_class.gd")

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
	_test_unarmored_ac()
	_test_light_armor_ac()
	_test_medium_armor_dex_cap()
	_test_heavy_armor_no_dex()
	_test_shield_bonus()
	_test_temp_bonus()
	_test_temp_bonus_stacks()
	_test_clear_temp_bonuses()
	_test_shield_plus_armor()
	_test_all_bonuses_combined()
	_test_negative_dex_modifier()
	_test_invalid_armor_type_rejected()
	_test_equip_armor_change()


# ---------------------------------------------------------------------------
# No armor: AC = 10 + DEX modifier (full DEX applied)
# ---------------------------------------------------------------------------
func _test_unarmored_ac() -> void:
	print("_test_unarmored_ac")
	var ac := ArmorClassClassClass.new()
	_check(ac.calculate(0) == 10, "unarmored, DEX +0 -> AC 10")
	_check(ac.calculate(2) == 12, "unarmored, DEX +2 -> AC 12")
	_check(ac.calculate(-1) == 9, "unarmored, DEX -1 -> AC 9")


# ---------------------------------------------------------------------------
# Light armor: AC = base + DEX modifier (full DEX applied)
# ---------------------------------------------------------------------------
func _test_light_armor_ac() -> void:
	print("_test_light_armor_ac")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_LIGHT, 11)  # leather armor
	_check(ac.calculate(2) == 13, "leather (11) + DEX +2 -> AC 13")
	_check(ac.calculate(4) == 15, "leather (11) + DEX +4 -> AC 15")
	_check(ac.calculate(0) == 11, "leather (11) + DEX +0 -> AC 11")
	ac.equip_armor(ArmorClassClassClass.ARMOR_LIGHT, 12)  # studded leather
	_check(ac.calculate(3) == 15, "studded leather (12) + DEX +3 -> AC 15")


# ---------------------------------------------------------------------------
# Medium armor: AC = base + min(DEX, +2)  —  DEX bonus capped at +2
# ---------------------------------------------------------------------------
func _test_medium_armor_dex_cap() -> void:
	print("_test_medium_armor_dex_cap")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_MEDIUM, 14)  # scale mail
	_check(ac.calculate(1) == 15, "scale mail (14) + DEX +1 -> AC 15")
	_check(ac.calculate(2) == 16, "scale mail (14) + DEX +2 -> AC 16")
	_check(ac.calculate(4) == 16, "scale mail (14) + DEX +4 capped at +2 -> AC 16")
	_check(ac.calculate(0) == 14, "scale mail (14) + DEX +0 -> AC 14")


# ---------------------------------------------------------------------------
# Heavy armor: AC = base (DEX modifier not applied at all)
# ---------------------------------------------------------------------------
func _test_heavy_armor_no_dex() -> void:
	print("_test_heavy_armor_no_dex")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_HEAVY, 16)  # chain mail
	_check(ac.calculate(0) == 16, "chain mail (16) + DEX +0 -> AC 16")
	_check(ac.calculate(4) == 16, "chain mail (16) + DEX +4 ignored -> AC 16")
	_check(ac.calculate(-2) == 16, "chain mail (16) + DEX -2 ignored -> AC 16")
	ac.equip_armor(ArmorClassClassClass.ARMOR_HEAVY, 18)  # plate armor
	_check(ac.calculate(5) == 18, "plate (18) + DEX +5 ignored -> AC 18")


# ---------------------------------------------------------------------------
# Shield: +2 AC bonus regardless of armor type
# ---------------------------------------------------------------------------
func _test_shield_bonus() -> void:
	print("_test_shield_bonus")
	var ac := ArmorClassClassClass.new()
	ac.equip_shield(true)
	_check(ac.calculate(0) == 12, "unarmored + shield -> AC 12")
	_check(ac.calculate(2) == 14, "unarmored + DEX +2 + shield -> AC 14")
	ac.equip_shield(false)
	_check(ac.calculate(0) == 10, "shield removed -> AC 10")


# ---------------------------------------------------------------------------
# Temporary bonus (e.g., Shield spell +5)
# ---------------------------------------------------------------------------
func _test_temp_bonus() -> void:
	print("_test_temp_bonus")
	var ac := ArmorClassClassClass.new()
	ac.add_temp_bonus(5)
	_check(ac.calculate(0) == 15, "unarmored + temp +5 -> AC 15")
	_check(ac.calculate(2) == 17, "unarmored + DEX +2 + temp +5 -> AC 17")


# ---------------------------------------------------------------------------
# Multiple add_temp_bonus calls stack together
# ---------------------------------------------------------------------------
func _test_temp_bonus_stacks() -> void:
	print("_test_temp_bonus_stacks")
	var ac := ArmorClassClassClass.new()
	ac.add_temp_bonus(5)
	ac.add_temp_bonus(2)
	_check(ac.calculate(0) == 17, "temp +5 and temp +2 stack -> AC 17")


# ---------------------------------------------------------------------------
# clear_temp_bonuses removes all temporary bonuses
# ---------------------------------------------------------------------------
func _test_clear_temp_bonuses() -> void:
	print("_test_clear_temp_bonuses")
	var ac := ArmorClassClassClass.new()
	ac.add_temp_bonus(5)
	ac.clear_temp_bonuses()
	_check(ac.calculate(0) == 10, "after clear_temp_bonuses, unarmored -> AC 10")


# ---------------------------------------------------------------------------
# Shield combined with armor
# ---------------------------------------------------------------------------
func _test_shield_plus_armor() -> void:
	print("_test_shield_plus_armor")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_HEAVY, 18)  # plate
	ac.equip_shield(true)
	_check(ac.calculate(5) == 20, "plate (18) + shield -> AC 20")
	ac.equip_armor(ArmorClassClassClass.ARMOR_LIGHT, 11)  # leather
	_check(ac.calculate(3) == 16, "leather (11) + DEX +3 + shield -> AC 16")


# ---------------------------------------------------------------------------
# All bonuses combined: armor + DEX + shield + temp modifier
# ---------------------------------------------------------------------------
func _test_all_bonuses_combined() -> void:
	print("_test_all_bonuses_combined")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_MEDIUM, 15)  # half plate
	ac.equip_shield(true)
	ac.add_temp_bonus(5)  # Shield spell
	# 15 + min(+3, +2) + 2 (shield) + 5 (temp) = 15 + 2 + 2 + 5 = 24
	_check(ac.calculate(3) == 24, "half plate (15) + DEX +3 capped + shield + temp +5 -> AC 24")


# ---------------------------------------------------------------------------
# Negative DEX modifier reduces AC for no-armor and light/medium armor
# ---------------------------------------------------------------------------
func _test_negative_dex_modifier() -> void:
	print("_test_negative_dex_modifier")
	var ac := ArmorClassClassClass.new()
	_check(ac.calculate(-2) == 8, "unarmored, DEX -2 -> AC 8")
	ac.equip_armor(ArmorClassClassClass.ARMOR_LIGHT, 11)
	_check(ac.calculate(-2) == 9, "light armor (11), DEX -2 -> AC 9")
	ac.equip_armor(ArmorClassClassClass.ARMOR_MEDIUM, 14)
	_check(ac.calculate(-2) == 12, "medium armor (14), DEX -2 (no cap on negative) -> AC 12")


# ---------------------------------------------------------------------------
# Invalid armor type is rejected — state unchanged (push_error, no crash)
# ---------------------------------------------------------------------------
func _test_invalid_armor_type_rejected() -> void:
	print("_test_invalid_armor_type_rejected")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor("mythril", 20)
	_check(ac.calculate(0) == 10, "invalid armor type rejected, state unchanged (unarmored AC 10)")


# ---------------------------------------------------------------------------
# Switching armor type immediately changes the calculation
# ---------------------------------------------------------------------------
func _test_equip_armor_change() -> void:
	print("_test_equip_armor_change")
	var ac := ArmorClassClassClass.new()
	ac.equip_armor(ArmorClassClassClass.ARMOR_LIGHT, 11)
	_check(ac.calculate(2) == 13, "light armor (11) + DEX +2 -> AC 13")
	ac.equip_armor(ArmorClassClassClass.ARMOR_HEAVY, 16)
	_check(ac.calculate(2) == 16, "switched to heavy (16), DEX +2 ignored -> AC 16")
