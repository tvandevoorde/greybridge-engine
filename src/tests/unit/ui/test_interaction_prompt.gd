## test_interaction_prompt.gd
## Unit tests for InteractionPrompt (src/ui/interaction_prompt.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_interaction_prompt.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InteractionPromptClass = preload("res://ui/interaction_prompt.gd")

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
	_test_is_visible_false_by_default()
	_test_current_handler_id_empty_by_default()
	_test_show_prompt_sets_is_visible()
	_test_show_prompt_stores_handler_id()
	_test_hide_prompt_clears_is_visible()
	_test_hide_prompt_clears_handler_id()
	_test_show_prompt_replaces_previous_handler_id()
	_test_hide_after_never_shown_stays_hidden()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_is_visible_false_by_default() -> void:
	print("_test_is_visible_false_by_default")
	var prompt := InteractionPromptClass.new()
	_check(prompt.is_visible == false, "is_visible is false by default")
	prompt.free()


func _test_current_handler_id_empty_by_default() -> void:
	print("_test_current_handler_id_empty_by_default")
	var prompt := InteractionPromptClass.new()
	_check(prompt.current_handler_id == "", "current_handler_id is empty by default")
	prompt.free()


# ---------------------------------------------------------------------------
# show_prompt
# ---------------------------------------------------------------------------
func _test_show_prompt_sets_is_visible() -> void:
	print("_test_show_prompt_sets_is_visible")
	var prompt := InteractionPromptClass.new()
	prompt.show_prompt("chest_01")
	_check(prompt.is_visible == true, "is_visible is true after show_prompt()")
	prompt.free()


func _test_show_prompt_stores_handler_id() -> void:
	print("_test_show_prompt_stores_handler_id")
	var prompt := InteractionPromptClass.new()
	prompt.show_prompt("door_02")
	_check(prompt.current_handler_id == "door_02",
		"current_handler_id is 'door_02' after show_prompt('door_02')")
	prompt.free()


# ---------------------------------------------------------------------------
# hide_prompt
# ---------------------------------------------------------------------------
func _test_hide_prompt_clears_is_visible() -> void:
	print("_test_hide_prompt_clears_is_visible")
	var prompt := InteractionPromptClass.new()
	prompt.show_prompt("npc_01")
	prompt.hide_prompt()
	_check(prompt.is_visible == false, "is_visible is false after hide_prompt()")
	prompt.free()


func _test_hide_prompt_clears_handler_id() -> void:
	print("_test_hide_prompt_clears_handler_id")
	var prompt := InteractionPromptClass.new()
	prompt.show_prompt("npc_01")
	prompt.hide_prompt()
	_check(prompt.current_handler_id == "",
		"current_handler_id is empty after hide_prompt()")
	prompt.free()


# ---------------------------------------------------------------------------
# Replacing handler_id
# ---------------------------------------------------------------------------
func _test_show_prompt_replaces_previous_handler_id() -> void:
	print("_test_show_prompt_replaces_previous_handler_id")
	var prompt := InteractionPromptClass.new()
	prompt.show_prompt("first_obj")
	prompt.show_prompt("second_obj")
	_check(prompt.current_handler_id == "second_obj",
		"current_handler_id updates to 'second_obj' on second show_prompt() call")
	_check(prompt.is_visible == true, "is_visible remains true")
	prompt.free()


# ---------------------------------------------------------------------------
# hide when never shown
# ---------------------------------------------------------------------------
func _test_hide_after_never_shown_stays_hidden() -> void:
	print("_test_hide_after_never_shown_stays_hidden")
	var prompt := InteractionPromptClass.new()
	prompt.hide_prompt()
	_check(prompt.is_visible == false, "is_visible remains false after hide_prompt() with no prior show")
	_check(prompt.current_handler_id == "", "current_handler_id remains empty")
	prompt.free()
