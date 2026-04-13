## test_dialogue_graph.gd
## Unit tests for DialogueGraph (src/rules_engine/core/dialogue_graph.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_dialogue_graph.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DialogueGraphClass = preload("res://rules_engine/core/dialogue_graph.gd")

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
	_test_from_dict_dialogue_id()
	_test_from_dict_start_node_id()
	_test_from_dict_node_count()
	_test_get_node_returns_correct_node()
	_test_get_node_unknown_id_returns_null()
	_test_get_start_node_returns_first_node()
	_test_get_start_node_empty_start_id_returns_null()
	_test_is_valid_full_graph()
	_test_is_valid_empty_dialogue_id()
	_test_is_valid_empty_start_node_id()
	_test_is_valid_start_node_not_in_graph()
	_test_is_valid_no_nodes()
	_test_from_dict_defaults_empty()
	_test_end_node_accessible()
	_test_node_choices_link_to_other_nodes()
	_test_node_count_method()


# ---------------------------------------------------------------------------
# Helper: builds a minimal valid graph dictionary
# ---------------------------------------------------------------------------
func _make_graph_dict() -> Dictionary:
	return {
		"dialogue_id": "test_dialogue",
		"start_node_id": "start",
		"nodes": [
			{
				"node_id": "start",
				"text": "Hello!",
				"is_end": false,
				"choices": [
					{"text": "Continue", "next_node_id": "end_node"}
				]
			},
			{
				"node_id": "end_node",
				"text": "Goodbye.",
				"is_end": true,
				"choices": []
			}
		]
	}


# ---------------------------------------------------------------------------
# from_dict — dialogue_id is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_dialogue_id() -> void:
	print("_test_from_dict_dialogue_id")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	_check(graph != null, "from_dict returns non-null")
	_check(graph.dialogue_id == "test_dialogue", "dialogue_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — start_node_id is parsed
# ---------------------------------------------------------------------------
func _test_from_dict_start_node_id() -> void:
	print("_test_from_dict_start_node_id")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	_check(graph.start_node_id == "start", "start_node_id parsed correctly")


# ---------------------------------------------------------------------------
# from_dict — all nodes are indexed
# ---------------------------------------------------------------------------
func _test_from_dict_node_count() -> void:
	print("_test_from_dict_node_count")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	_check(graph.node_count() == 2, "both nodes indexed")


# ---------------------------------------------------------------------------
# get_node — returns correct node by id
# ---------------------------------------------------------------------------
func _test_get_node_returns_correct_node() -> void:
	print("_test_get_node_returns_correct_node")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	var node = graph.get_node("start")
	_check(node != null, "get_node('start') returns non-null")
	_check(node.node_id == "start", "returned node has correct node_id")
	_check(node.text == "Hello!", "returned node has correct text")


# ---------------------------------------------------------------------------
# get_node — unknown id returns null
# ---------------------------------------------------------------------------
func _test_get_node_unknown_id_returns_null() -> void:
	print("_test_get_node_unknown_id_returns_null")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	_check(graph.get_node("nonexistent") == null, "unknown node_id returns null")


# ---------------------------------------------------------------------------
# get_start_node — returns the start node
# ---------------------------------------------------------------------------
func _test_get_start_node_returns_first_node() -> void:
	print("_test_get_start_node_returns_first_node")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	var start = graph.get_start_node()
	_check(start != null, "get_start_node returns non-null")
	_check(start.node_id == "start", "get_start_node returns node with correct id")


# ---------------------------------------------------------------------------
# get_start_node — empty start_node_id returns null
# ---------------------------------------------------------------------------
func _test_get_start_node_empty_start_id_returns_null() -> void:
	print("_test_get_start_node_empty_start_id_returns_null")
	var graph := DialogueGraphClass.new()
	_check(graph.get_start_node() == null, "get_start_node returns null when start_node_id is empty")


# ---------------------------------------------------------------------------
# is_valid — returns true for a complete graph
# ---------------------------------------------------------------------------
func _test_is_valid_full_graph() -> void:
	print("_test_is_valid_full_graph")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	_check(graph.is_valid() == true, "is_valid returns true for complete graph")


# ---------------------------------------------------------------------------
# is_valid — returns false when dialogue_id is empty
# ---------------------------------------------------------------------------
func _test_is_valid_empty_dialogue_id() -> void:
	print("_test_is_valid_empty_dialogue_id")
	var data := _make_graph_dict()
	data["dialogue_id"] = ""
	var graph := DialogueGraphClass.from_dict(data)
	_check(graph.is_valid() == false, "is_valid returns false when dialogue_id is empty")


# ---------------------------------------------------------------------------
# is_valid — returns false when start_node_id is empty
# ---------------------------------------------------------------------------
func _test_is_valid_empty_start_node_id() -> void:
	print("_test_is_valid_empty_start_node_id")
	var data := _make_graph_dict()
	data["start_node_id"] = ""
	var graph := DialogueGraphClass.from_dict(data)
	_check(graph.is_valid() == false, "is_valid returns false when start_node_id is empty")


# ---------------------------------------------------------------------------
# is_valid — returns false when start_node_id not present in nodes
# ---------------------------------------------------------------------------
func _test_is_valid_start_node_not_in_graph() -> void:
	print("_test_is_valid_start_node_not_in_graph")
	var data := _make_graph_dict()
	data["start_node_id"] = "missing_node"
	var graph := DialogueGraphClass.from_dict(data)
	_check(graph.is_valid() == false, "is_valid returns false when start_node_id not in nodes")


# ---------------------------------------------------------------------------
# is_valid — returns false when nodes list is empty
# ---------------------------------------------------------------------------
func _test_is_valid_no_nodes() -> void:
	print("_test_is_valid_no_nodes")
	var data := _make_graph_dict()
	data["nodes"] = []
	var graph := DialogueGraphClass.from_dict(data)
	_check(graph.is_valid() == false, "is_valid returns false when nodes list is empty")


# ---------------------------------------------------------------------------
# from_dict — empty dict produces safe defaults
# ---------------------------------------------------------------------------
func _test_from_dict_defaults_empty() -> void:
	print("_test_from_dict_defaults_empty")
	var graph := DialogueGraphClass.from_dict({})
	_check(graph.dialogue_id == "", "default dialogue_id is empty string")
	_check(graph.start_node_id == "", "default start_node_id is empty string")
	_check(graph.node_count() == 0, "default node count is 0")
	_check(graph.is_valid() == false, "default graph is not valid")


# ---------------------------------------------------------------------------
# End node is accessible via get_node
# ---------------------------------------------------------------------------
func _test_end_node_accessible() -> void:
	print("_test_end_node_accessible")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	var end_node = graph.get_node("end_node")
	_check(end_node != null, "end node accessible by id")
	_check(end_node.is_end == true, "end node has is_end true")


# ---------------------------------------------------------------------------
# Node choices link to accessible nodes
# ---------------------------------------------------------------------------
func _test_node_choices_link_to_other_nodes() -> void:
	print("_test_node_choices_link_to_other_nodes")
	var graph := DialogueGraphClass.from_dict(_make_graph_dict())
	var start = graph.get_start_node()
	_check(start.choices.size() == 1, "start node has one choice")
	var next_id: String = start.choices[0]["next_node_id"]
	var next_node = graph.get_node(next_id)
	_check(next_node != null, "choice next_node_id resolves to a valid node")


# ---------------------------------------------------------------------------
# node_count method returns correct value
# ---------------------------------------------------------------------------
func _test_node_count_method() -> void:
	print("_test_node_count_method")
	var data := {
		"dialogue_id": "three_nodes",
		"start_node_id": "a",
		"nodes": [
			{"node_id": "a", "text": "A", "choices": [{"text": "to b", "next_node_id": "b"}]},
			{"node_id": "b", "text": "B", "choices": [{"text": "to c", "next_node_id": "c"}]},
			{"node_id": "c", "text": "C", "is_end": true, "choices": []}
		]
	}
	var graph := DialogueGraphClass.from_dict(data)
	_check(graph.node_count() == 3, "node_count returns 3 for three nodes")
