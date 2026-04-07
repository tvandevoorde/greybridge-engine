## test_overworld_hud.gd
## Unit tests for OverworldHud (src/ui/overworld_hud.gd).
##
## Acceptance criteria from the "Implement minimal overworld HUD" issue:
##   - Displays HP and key resources
##   - Displays current quest objective (optional)
##   - Does not show combat-only UI
##   - Can be toggled off
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_overworld_hud.gd
extends SceneTree

const OverworldHudClass = preload("res://ui/overworld_hud.gd")

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


func _make_hud() -> OverworldHudClass:
	return OverworldHudClass.new()


func _run_all_tests() -> void:
	_test_initial_state()
	_test_refresh_hp_basic()
	_test_refresh_hp_clamps_current_below_zero()
	_test_refresh_hp_clamps_current_above_max()
	_test_refresh_hp_max_clamped_to_one()
	_test_refresh_hp_signal_emitted()
	_test_refresh_hp_signal_carries_values()
	_test_quest_objective_empty_by_default()
	_test_set_quest_objective_stores_text()
	_test_has_quest_objective_false_when_empty()
	_test_has_quest_objective_true_when_set()
	_test_set_quest_objective_clear_with_empty_string()
	_test_quest_objective_signal_emitted()
	_test_quest_objective_signal_carries_text()
	_test_visible_by_default()
	_test_hide_hud()
	_test_show_hud_after_hide()
	_test_toggle_hides_when_visible()
	_test_toggle_shows_when_hidden()
	_test_visibility_changed_signal_on_hide()
	_test_visibility_changed_signal_on_show()
	_test_visibility_changed_signal_on_toggle()
	_test_show_hud_no_signal_when_already_visible()
	_test_hide_hud_no_signal_when_already_hidden()
	_test_hp_data_retained_while_hidden()
	_test_no_combat_ui_methods()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state() -> void:
	print("_test_initial_state")
	var hud := _make_hud()
	_check(hud.get_current_hp() == 0,  "current_hp is 0 before first refresh")
	_check(hud.get_max_hp() == 0,      "max_hp is 0 before first refresh")
	_check(hud.get_quest_objective() == "", "quest objective is empty initially")
	_check(hud.has_quest_objective() == false, "has_quest_objective is false initially")
	_check(hud.is_visible == true,     "hud is visible by default")
	hud.free()


# ---------------------------------------------------------------------------
# refresh_hp
# ---------------------------------------------------------------------------
func _test_refresh_hp_basic() -> void:
	print("_test_refresh_hp_basic")
	var hud := _make_hud()
	hud.refresh_hp(8, 10)
	_check(hud.get_current_hp() == 8,  "current_hp is 8 after refresh")
	_check(hud.get_max_hp() == 10,     "max_hp is 10 after refresh")
	hud.free()


func _test_refresh_hp_clamps_current_below_zero() -> void:
	print("_test_refresh_hp_clamps_current_below_zero")
	var hud := _make_hud()
	hud.refresh_hp(-5, 10)
	_check(hud.get_current_hp() == 0, "current_hp clamped to 0 when negative")
	hud.free()


func _test_refresh_hp_clamps_current_above_max() -> void:
	print("_test_refresh_hp_clamps_current_above_max")
	var hud := _make_hud()
	hud.refresh_hp(15, 10)
	_check(hud.get_current_hp() == 10, "current_hp clamped to max_hp when exceeding max")
	hud.free()


func _test_refresh_hp_max_clamped_to_one() -> void:
	print("_test_refresh_hp_max_clamped_to_one")
	var hud := _make_hud()
	hud.refresh_hp(0, 0)
	_check(hud.get_max_hp() == 1, "max_hp clamped to 1 when 0 is passed")
	hud.free()


func _test_refresh_hp_signal_emitted() -> void:
	print("_test_refresh_hp_signal_emitted")
	var hud := _make_hud()
	var state := {"emit_count": 0}
	hud.hp_updated.connect(func(_c: int, _m: int) -> void: state["emit_count"] += 1)
	hud.refresh_hp(5, 10)
	_check(state["emit_count"] == 1, "hp_updated emitted once on refresh_hp")
	hud.refresh_hp(3, 10)
	_check(state["emit_count"] == 2, "hp_updated emitted again on second refresh_hp")
	hud.free()


func _test_refresh_hp_signal_carries_values() -> void:
	print("_test_refresh_hp_signal_carries_values")
	var hud := _make_hud()
	var state := {"current": -1, "max": -1}
	hud.hp_updated.connect(func(c: int, m: int) -> void:
		state["current"] = c
		state["max"] = m
	)
	hud.refresh_hp(7, 12)
	_check(state["current"] == 7,  "hp_updated signal carries current_hp = 7")
	_check(state["max"] == 12,     "hp_updated signal carries max_hp = 12")
	hud.free()


# ---------------------------------------------------------------------------
# Quest objective
# ---------------------------------------------------------------------------
func _test_quest_objective_empty_by_default() -> void:
	print("_test_quest_objective_empty_by_default")
	var hud := _make_hud()
	_check(hud.get_quest_objective() == "", "quest objective is empty string by default")
	hud.free()


func _test_set_quest_objective_stores_text() -> void:
	print("_test_set_quest_objective_stores_text")
	var hud := _make_hud()
	hud.set_quest_objective("Reach Greybridge")
	_check(hud.get_quest_objective() == "Reach Greybridge", "quest objective stored correctly")
	hud.free()


func _test_has_quest_objective_false_when_empty() -> void:
	print("_test_has_quest_objective_false_when_empty")
	var hud := _make_hud()
	_check(hud.has_quest_objective() == false, "has_quest_objective false when empty")
	hud.free()


func _test_has_quest_objective_true_when_set() -> void:
	print("_test_has_quest_objective_true_when_set")
	var hud := _make_hud()
	hud.set_quest_objective("Find the bandit camp")
	_check(hud.has_quest_objective() == true, "has_quest_objective true when text is set")
	hud.free()


func _test_set_quest_objective_clear_with_empty_string() -> void:
	print("_test_set_quest_objective_clear_with_empty_string")
	var hud := _make_hud()
	hud.set_quest_objective("Reach Greybridge")
	hud.set_quest_objective("")
	_check(hud.get_quest_objective() == "", "quest objective cleared by empty string")
	_check(hud.has_quest_objective() == false, "has_quest_objective false after clearing")
	hud.free()


func _test_quest_objective_signal_emitted() -> void:
	print("_test_quest_objective_signal_emitted")
	var hud := _make_hud()
	var state := {"emit_count": 0}
	hud.quest_objective_updated.connect(func(_t: String) -> void: state["emit_count"] += 1)
	hud.set_quest_objective("Reach Greybridge")
	_check(state["emit_count"] == 1, "quest_objective_updated emitted on set_quest_objective")
	hud.set_quest_objective("")
	_check(state["emit_count"] == 2, "quest_objective_updated emitted when objective cleared")
	hud.free()


func _test_quest_objective_signal_carries_text() -> void:
	print("_test_quest_objective_signal_carries_text")
	var hud := _make_hud()
	var state := {"received": ""}
	hud.quest_objective_updated.connect(func(t: String) -> void: state["received"] = t)
	hud.set_quest_objective("Escort the merchant")
	_check(state["received"] == "Escort the merchant", "quest_objective_updated carries correct text")
	hud.free()


# ---------------------------------------------------------------------------
# Visibility toggle (AC: can be toggled off)
# ---------------------------------------------------------------------------
func _test_visible_by_default() -> void:
	print("_test_visible_by_default")
	var hud := _make_hud()
	_check(hud.is_visible == true, "hud is_visible is true by default")
	hud.free()


func _test_hide_hud() -> void:
	print("_test_hide_hud")
	var hud := _make_hud()
	hud.hide_hud()
	_check(hud.is_visible == false, "is_visible is false after hide_hud()")
	hud.free()


func _test_show_hud_after_hide() -> void:
	print("_test_show_hud_after_hide")
	var hud := _make_hud()
	hud.hide_hud()
	hud.show_hud()
	_check(hud.is_visible == true, "is_visible is true after show_hud()")
	hud.free()


func _test_toggle_hides_when_visible() -> void:
	print("_test_toggle_hides_when_visible")
	var hud := _make_hud()
	hud.toggle()
	_check(hud.is_visible == false, "toggle() hides the HUD when it was visible")
	hud.free()


func _test_toggle_shows_when_hidden() -> void:
	print("_test_toggle_shows_when_hidden")
	var hud := _make_hud()
	hud.hide_hud()
	hud.toggle()
	_check(hud.is_visible == true, "toggle() shows the HUD when it was hidden")
	hud.free()


func _test_visibility_changed_signal_on_hide() -> void:
	print("_test_visibility_changed_signal_on_hide")
	var hud := _make_hud()
	var received: Array = []
	hud.visibility_changed.connect(func(v: bool) -> void: received.append(v))
	hud.hide_hud()
	_check(received.size() == 1,      "visibility_changed emitted on hide_hud()")
	_check(received[0] == false,      "visibility_changed carries false when hidden")
	hud.free()


func _test_visibility_changed_signal_on_show() -> void:
	print("_test_visibility_changed_signal_on_show")
	var hud := _make_hud()
	var received: Array = []
	hud.visibility_changed.connect(func(v: bool) -> void: received.append(v))
	hud.hide_hud()
	hud.show_hud()
	_check(received.size() == 2,      "visibility_changed emitted on show_hud() after hide")
	_check(received[1] == true,       "visibility_changed carries true when shown")
	hud.free()


func _test_visibility_changed_signal_on_toggle() -> void:
	print("_test_visibility_changed_signal_on_toggle")
	var hud := _make_hud()
	var received: Array = []
	hud.visibility_changed.connect(func(v: bool) -> void: received.append(v))
	hud.toggle()
	_check(received.size() == 1,  "visibility_changed emitted on first toggle()")
	_check(received[0] == false,  "first toggle emits false (was visible)")
	hud.toggle()
	_check(received.size() == 2,  "visibility_changed emitted on second toggle()")
	_check(received[1] == true,   "second toggle emits true (was hidden)")
	hud.free()


func _test_show_hud_no_signal_when_already_visible() -> void:
	print("_test_show_hud_no_signal_when_already_visible")
	var hud := _make_hud()
	var emit_count: int = 0
	hud.visibility_changed.connect(func(_v: bool) -> void: emit_count += 1)
	hud.show_hud()  # already visible — should be a no-op
	_check(emit_count == 0, "visibility_changed NOT emitted when show_hud() called while already visible")
	hud.free()


func _test_hide_hud_no_signal_when_already_hidden() -> void:
	print("_test_hide_hud_no_signal_when_already_hidden")
	var hud := _make_hud()
	var emit_count: int = 0
	hud.visibility_changed.connect(func(_v: bool) -> void: emit_count += 1)
	hud.hide_hud()           # first call: emits
	emit_count = 0           # reset counter
	hud.hide_hud()           # second call: already hidden — should be a no-op
	_check(emit_count == 0, "visibility_changed NOT emitted when hide_hud() called while already hidden")
	hud.free()


# ---------------------------------------------------------------------------
# HP data retained while hidden
# ---------------------------------------------------------------------------
func _test_hp_data_retained_while_hidden() -> void:
	print("_test_hp_data_retained_while_hidden")
	var hud := _make_hud()
	hud.refresh_hp(6, 10)
	hud.hide_hud()
	_check(hud.get_current_hp() == 6,  "current_hp retained while hud is hidden")
	_check(hud.get_max_hp() == 10,     "max_hp retained while hud is hidden")
	hud.free()


# ---------------------------------------------------------------------------
# No combat-only UI methods (AC: does not show combat-only UI)
# ---------------------------------------------------------------------------
func _test_no_combat_ui_methods() -> void:
	print("_test_no_combat_ui_methods")
	var hud := _make_hud()
	_check(not hud.has_method("refresh"),
		"no generic refresh method (combat UI pattern must not leak into HUD)")
	_check(not hud.has_method("get_available_actions"),
		"no get_available_actions (combat action menu must not be in overworld HUD)")
	_check(not hud.has_method("select_action"),
		"no select_action (combat action menu must not be in overworld HUD)")
	_check(not hud.has_method("append_entry"),
		"no append_entry (combat log must not be in overworld HUD)")
	_check(not hud.has_method("begin_selection"),
		"no begin_selection (target selector must not be in overworld HUD)")
	hud.free()
