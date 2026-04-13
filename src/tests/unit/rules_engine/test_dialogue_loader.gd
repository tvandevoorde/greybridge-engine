## test_dialogue_loader.gd
## Unit tests for DialogueLoader (src/rules_engine/core/dialogue_loader.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_dialogue_loader.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const DialogueLoaderClass = preload("res://rules_engine/core/dialogue_loader.gd")
const DialogueGraphClass  = preload("res://rules_engine/core/dialogue_graph.gd")

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
	_test_load_from_dict_returns_graph()
	_test_load_from_dict_populates_dialogue_id()
	_test_load_from_dict_populates_start_node_id()
	_test_load_from_dict_populates_nodes()
	_test_load_from_dict_missing_dialogue_id_returns_null()
	_test_load_from_dict_missing_start_node_id_returns_null()
	_test_load_from_dict_missing_nodes_returns_null()
	_test_load_from_dict_empty_dialogue_id_returns_null()
	_test_load_from_dict_empty_start_node_id_returns_null()
	_test_load_from_dict_nodes_not_array_returns_null()
	_test_load_from_json_returns_graph()
	_test_load_from_json_malformed_returns_null()
	_test_load_from_json_non_dict_root_returns_null()
	_test_load_from_json_populates_nodes()
	_test_load_from_json_missing_field_returns_null()
	_test_load_from_dict_graph_is_valid()


# ---------------------------------------------------------------------------
# Helper: minimal valid dialogue dict
# ---------------------------------------------------------------------------
func _make_dict() -> Dictionary:
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
# load_from_dict — returns a DialogueGraph
# ---------------------------------------------------------------------------
func _test_load_from_dict_returns_graph() -> void:
	print("_test_load_from_dict_returns_graph")
	var loader := DialogueLoaderClass.new()
	var graph = loader.load_from_dict(_make_dict())
	_check(graph != null, "load_from_dict returns non-null")


# ---------------------------------------------------------------------------
# load_from_dict — dialogue_id is populated
# ---------------------------------------------------------------------------
func _test_load_from_dict_populates_dialogue_id() -> void:
	print("_test_load_from_dict_populates_dialogue_id")
	var loader := DialogueLoaderClass.new()
	var graph = loader.load_from_dict(_make_dict())
	_check(graph.dialogue_id == "test_dialogue", "dialogue_id populated")


# ---------------------------------------------------------------------------
# load_from_dict — start_node_id is populated
# ---------------------------------------------------------------------------
func _test_load_from_dict_populates_start_node_id() -> void:
	print("_test_load_from_dict_populates_start_node_id")
	var loader := DialogueLoaderClass.new()
	var graph = loader.load_from_dict(_make_dict())
	_check(graph.start_node_id == "start", "start_node_id populated")


# ---------------------------------------------------------------------------
# load_from_dict — nodes are populated
# ---------------------------------------------------------------------------
func _test_load_from_dict_populates_nodes() -> void:
	print("_test_load_from_dict_populates_nodes")
	var loader := DialogueLoaderClass.new()
	var graph = loader.load_from_dict(_make_dict())
	_check(graph.node_count() == 2, "both nodes loaded")


# ---------------------------------------------------------------------------
# load_from_dict — missing dialogue_id returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_missing_dialogue_id_returns_null() -> void:
	print("_test_load_from_dict_missing_dialogue_id_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data.erase("dialogue_id")
	_check(loader.load_from_dict(data) == null, "missing dialogue_id returns null")


# ---------------------------------------------------------------------------
# load_from_dict — missing start_node_id returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_missing_start_node_id_returns_null() -> void:
	print("_test_load_from_dict_missing_start_node_id_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data.erase("start_node_id")
	_check(loader.load_from_dict(data) == null, "missing start_node_id returns null")


# ---------------------------------------------------------------------------
# load_from_dict — missing nodes returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_missing_nodes_returns_null() -> void:
	print("_test_load_from_dict_missing_nodes_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data.erase("nodes")
	_check(loader.load_from_dict(data) == null, "missing nodes key returns null")


# ---------------------------------------------------------------------------
# load_from_dict — empty dialogue_id returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_empty_dialogue_id_returns_null() -> void:
	print("_test_load_from_dict_empty_dialogue_id_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data["dialogue_id"] = ""
	_check(loader.load_from_dict(data) == null, "empty dialogue_id returns null")


# ---------------------------------------------------------------------------
# load_from_dict — empty start_node_id returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_empty_start_node_id_returns_null() -> void:
	print("_test_load_from_dict_empty_start_node_id_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data["start_node_id"] = ""
	_check(loader.load_from_dict(data) == null, "empty start_node_id returns null")


# ---------------------------------------------------------------------------
# load_from_dict — nodes not an Array returns null
# ---------------------------------------------------------------------------
func _test_load_from_dict_nodes_not_array_returns_null() -> void:
	print("_test_load_from_dict_nodes_not_array_returns_null")
	var loader := DialogueLoaderClass.new()
	var data := _make_dict()
	data["nodes"] = "not_an_array"
	_check(loader.load_from_dict(data) == null, "nodes not an Array returns null")


# ---------------------------------------------------------------------------
# load_from_json — returns a DialogueGraph
# ---------------------------------------------------------------------------
func _test_load_from_json_returns_graph() -> void:
	print("_test_load_from_json_returns_graph")
	var loader := DialogueLoaderClass.new()
	var json_text := JSON.stringify(_make_dict())
	var graph = loader.load_from_json(json_text)
	_check(graph != null, "load_from_json returns non-null")


# ---------------------------------------------------------------------------
# load_from_json — malformed JSON returns null
# ---------------------------------------------------------------------------
func _test_load_from_json_malformed_returns_null() -> void:
	print("_test_load_from_json_malformed_returns_null")
	var loader := DialogueLoaderClass.new()
	_check(loader.load_from_json("{not valid json") == null, "malformed JSON returns null")


# ---------------------------------------------------------------------------
# load_from_json — non-dict root returns null
# ---------------------------------------------------------------------------
func _test_load_from_json_non_dict_root_returns_null() -> void:
	print("_test_load_from_json_non_dict_root_returns_null")
	var loader := DialogueLoaderClass.new()
	_check(loader.load_from_json("[1, 2, 3]") == null, "non-dict JSON root returns null")


# ---------------------------------------------------------------------------
# load_from_json — nodes are populated
# ---------------------------------------------------------------------------
func _test_load_from_json_populates_nodes() -> void:
	print("_test_load_from_json_populates_nodes")
	var loader := DialogueLoaderClass.new()
	var json_text := JSON.stringify(_make_dict())
	var graph = loader.load_from_json(json_text)
	_check(graph.node_count() == 2, "nodes populated from JSON string")


# ---------------------------------------------------------------------------
# load_from_json — missing field returns null
# ---------------------------------------------------------------------------
func _test_load_from_json_missing_field_returns_null() -> void:
	print("_test_load_from_json_missing_field_returns_null")
	var loader := DialogueLoaderClass.new()
	var incomplete := {"start_node_id": "start", "nodes": []}
	_check(loader.load_from_json(JSON.stringify(incomplete)) == null,
		"JSON missing dialogue_id returns null")


# ---------------------------------------------------------------------------
# load_from_dict — resulting graph is_valid()
# ---------------------------------------------------------------------------
func _test_load_from_dict_graph_is_valid() -> void:
	print("_test_load_from_dict_graph_is_valid")
	var loader := DialogueLoaderClass.new()
	var graph = loader.load_from_dict(_make_dict())
	_check(graph.is_valid() == true, "loaded graph reports is_valid() true")
