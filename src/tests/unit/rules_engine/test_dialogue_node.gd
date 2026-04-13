## test_dialogue_node.gd
## Unit tests for DialogueNode (src/rules_engine/core/dialogue_node.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_dialogue_node.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DialogueNodeClass = preload("res://rules_engine/core/dialogue_node.gd")

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
	_test_from_dict_node_id()
	_test_from_dict_text()
	_test_from_dict_is_end_true()
	_test_from_dict_is_end_defaults_false()
	_test_from_dict_choices_parsed()
	_test_from_dict_choices_text_and_next()
	_test_from_dict_choices_defaults_empty()
	_test_from_dict_defaults_empty()
	_test_is_valid_with_id()
	_test_is_valid_empty_id()
	_test_from_dict_choices_is_copy()
	_test_from_dict_invalid_choice_entry_skipped()
	_test_end_node_no_choices()


# ---------------------------------------------------------------------------
# from_dict — node_id is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_node_id() -> void:
	print("_test_from_dict_node_id")
	var data := {"node_id": "greeting", "text": "Hello!", "choices": [], "is_end": false}
	var node := DialogueNodeClass.from_dict(data)
	_check(node != null, "from_dict returns non-null")
	_check(node.node_id == "greeting", "node_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — text is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_text() -> void:
	print("_test_from_dict_text")
	var data := {"node_id": "n1", "text": "Hello, traveller!", "choices": [], "is_end": false}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.text == "Hello, traveller!", "text parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — is_end true is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_is_end_true() -> void:
	print("_test_from_dict_is_end_true")
	var data := {"node_id": "farewell", "text": "Goodbye.", "choices": [], "is_end": true}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.is_end == true, "is_end true parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — is_end defaults to false when omitted
# ---------------------------------------------------------------------------
func _test_from_dict_is_end_defaults_false() -> void:
	print("_test_from_dict_is_end_defaults_false")
	var data := {"node_id": "mid", "text": "Keep going."}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.is_end == false, "is_end defaults to false when omitted")


# ---------------------------------------------------------------------------
# from_dict — choices count is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_choices_parsed() -> void:
	print("_test_from_dict_choices_parsed")
	var data := {
		"node_id": "branch",
		"text": "What will you do?",
		"choices": [
			{"text": "Option A", "next_node_id": "node_a"},
			{"text": "Option B", "next_node_id": "node_b"}
		],
		"is_end": false
	}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.choices.size() == 2, "two choices parsed")


# ---------------------------------------------------------------------------
# from_dict — choice text and next_node_id are parsed
# ---------------------------------------------------------------------------
func _test_from_dict_choices_text_and_next() -> void:
	print("_test_from_dict_choices_text_and_next")
	var data := {
		"node_id": "q",
		"text": "Choose.",
		"choices": [
			{"text": "Go left", "next_node_id": "left_node"}
		],
		"is_end": false
	}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.choices.size() == 1, "one choice parsed")
	_check(node.choices[0]["text"] == "Go left", "choice text parsed correctly")
	_check(node.choices[0]["next_node_id"] == "left_node", "choice next_node_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — choices defaults to empty array when omitted
# ---------------------------------------------------------------------------
func _test_from_dict_choices_defaults_empty() -> void:
	print("_test_from_dict_choices_defaults_empty")
	var data := {"node_id": "lone", "text": "Just text."}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.choices.is_empty(), "choices defaults to empty array when omitted")


# ---------------------------------------------------------------------------
# from_dict — empty dict produces safe defaults
# ---------------------------------------------------------------------------
func _test_from_dict_defaults_empty() -> void:
	print("_test_from_dict_defaults_empty")
	var node := DialogueNodeClass.from_dict({})
	_check(node.node_id == "", "default node_id is empty string")
	_check(node.text == "", "default text is empty string")
	_check(node.is_end == false, "default is_end is false")
	_check(node.choices.is_empty(), "default choices is empty array")


# ---------------------------------------------------------------------------
# is_valid — returns true when node_id is non-empty
# ---------------------------------------------------------------------------
func _test_is_valid_with_id() -> void:
	print("_test_is_valid_with_id")
	var node := DialogueNodeClass.new()
	node.node_id = "start"
	_check(node.is_valid() == true, "is_valid returns true for non-empty node_id")


# ---------------------------------------------------------------------------
# is_valid — returns false when node_id is empty
# ---------------------------------------------------------------------------
func _test_is_valid_empty_id() -> void:
	print("_test_is_valid_empty_id")
	var node := DialogueNodeClass.new()
	_check(node.is_valid() == false, "is_valid returns false for empty node_id")


# ---------------------------------------------------------------------------
# from_dict — choices array is independent of original data
# ---------------------------------------------------------------------------
func _test_from_dict_choices_is_copy() -> void:
	print("_test_from_dict_choices_is_copy")
	var original_choices := [{"text": "Yes", "next_node_id": "yes_node"}]
	var data := {"node_id": "q", "text": "?", "choices": original_choices}
	var node := DialogueNodeClass.from_dict(data)
	original_choices.append({"text": "Injected", "next_node_id": "injected"})
	_check(node.choices.size() == 1,
		"choices is independent; appending to original does not affect parsed node")


# ---------------------------------------------------------------------------
# from_dict — non-Dictionary entries in choices are skipped
# ---------------------------------------------------------------------------
func _test_from_dict_invalid_choice_entry_skipped() -> void:
	print("_test_from_dict_invalid_choice_entry_skipped")
	var data := {
		"node_id": "mixed",
		"text": "Mixed choices.",
		"choices": [
			"not_a_dict",
			{"text": "Valid", "next_node_id": "valid_node"},
			42
		]
	}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.choices.size() == 1, "non-Dictionary entries in choices are skipped")
	_check(node.choices[0]["text"] == "Valid", "valid choice is retained")


# ---------------------------------------------------------------------------
# End node has empty choices
# ---------------------------------------------------------------------------
func _test_end_node_no_choices() -> void:
	print("_test_end_node_no_choices")
	var data := {"node_id": "end", "text": "Goodbye.", "is_end": true, "choices": []}
	var node := DialogueNodeClass.from_dict(data)
	_check(node.is_end == true, "end node is_end is true")
	_check(node.choices.is_empty(), "end node has no choices")
