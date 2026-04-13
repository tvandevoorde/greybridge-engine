## DialogueLoader
## Parses dialogue definition JSON into DialogueGraph instances.
##
## Architecture: NOT a Node. Pure logic — no UI, no scene references.
## Accepts raw JSON text or a pre-parsed Dictionary.
const DialogueGraphClass = preload("res://rules_engine/core/dialogue_graph.gd")


## Parse a DialogueGraph from a pre-parsed Dictionary.
##
## Required keys: "dialogue_id" (String), "start_node_id" (String),
##                "nodes" (Array)
##
## Returns a DialogueGraph on success, or null when required fields are
## absent or have invalid types.
func load_from_dict(data: Dictionary):
	if not data.has("dialogue_id") or not data.has("start_node_id") or not data.has("nodes"):
		return null
	if not data["dialogue_id"] is String or data["dialogue_id"] == "":
		return null
	if not data["start_node_id"] is String or data["start_node_id"] == "":
		return null
	if not data["nodes"] is Array:
		return null
	return DialogueGraphClass.from_dict(data)


## Parse a DialogueGraph from a JSON string.
##
## Returns a DialogueGraph on success, or null when the JSON is malformed
## or required fields are missing.
func load_from_json(json_text: String):
	var json := JSON.new()
	var err: int = json.parse(json_text)
	if err != OK:
		return null
	var data = json.data
	if not data is Dictionary:
		return null
	return load_from_dict(data)
