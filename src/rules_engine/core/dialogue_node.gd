## DialogueNode
## Pure data class representing a single node in a dialogue tree.
## Each node holds the speaker's text, an optional list of player choices,
## and a flag indicating whether the dialogue ends here.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name DialogueNode
extends RefCounted

## Unique identifier for this node within a dialogue graph.
var node_id: String = ""

## The text displayed to the player when this node is active.
var text: String = ""

## Player choices available at this node.
## Each entry is a Dictionary with:
##   "text"         : String — the label shown for this choice.
##   "next_node_id" : String — the node_id to advance to when chosen.
var choices: Array = []

## When true, the dialogue ends after this node is shown (no further
## navigation is expected, even if choices is non-empty).
var is_end: bool = false


## Constructs a DialogueNode from a Dictionary (e.g. parsed from JSON).
## Expected keys:
##   "node_id"  : String  (required — empty string if absent)
##   "text"     : String  (default "")
##   "choices"  : Array   (default []) — each item a Dictionary with
##                          "text" (String) and "next_node_id" (String)
##   "is_end"   : bool    (default false)
static func from_dict(data: Dictionary) -> DialogueNode:
	var node := DialogueNode.new()
	node.node_id = data.get("node_id", "")
	node.text = data.get("text", "")
	node.is_end = bool(data.get("is_end", false))
	var raw_choices = data.get("choices", [])
	node.choices = []
	if raw_choices is Array:
		for choice in raw_choices:
			if choice is Dictionary:
				node.choices.append({
					"text": str(choice.get("text", "")),
					"next_node_id": str(choice.get("next_node_id", ""))
				})
	return node


## Returns true when node_id is non-empty.
func is_valid() -> bool:
	return node_id != ""
