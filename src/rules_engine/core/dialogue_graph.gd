## DialogueGraph
## Pure logic class representing a complete dialogue tree for one conversation.
## Holds an indexed collection of DialogueNodes and exposes lookup helpers.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name DialogueGraph
extends RefCounted

const DialogueNodeClass  = preload("res://rules_engine/core/dialogue_node.gd")

## Identifier matching the dialogue_id referenced in NpcDefinition.
var dialogue_id: String = ""

## The node_id of the first node shown when the dialogue begins.
var start_node_id: String = ""

## Internal index from node_id (String) to DialogueNode.
var _nodes: Dictionary = {}


## Constructs a DialogueGraph from a Dictionary (e.g. parsed from JSON).
## Expected keys:
##   "dialogue_id"   : String
##   "start_node_id" : String
##   "nodes"         : Array of node Dictionaries (see DialogueNode.from_dict)
static func from_dict(data: Dictionary) -> DialogueGraph:
	var graph := DialogueGraph.new()
	graph.dialogue_id   = data.get("dialogue_id", "")
	graph.start_node_id = data.get("start_node_id", "")
	var raw_nodes = data.get("nodes", [])
	if raw_nodes is Array:
		for entry in raw_nodes:
			if entry is Dictionary:
				var node := DialogueNodeClass.from_dict(entry)
				if node.is_valid():
					graph._nodes[node.node_id] = node
	return graph


## Returns the DialogueNode with the given node_id, or null if not found.
func get_node(node_id: String):
	return _nodes.get(node_id, null)


## Returns the starting DialogueNode (looked up via start_node_id),
## or null if start_node_id is empty or not present in the graph.
func get_start_node():
	if start_node_id == "":
		return null
	return get_node(start_node_id)


## Returns true when the graph has a non-empty dialogue_id, a non-empty
## start_node_id that resolves to a known node, and at least one node.
func is_valid() -> bool:
	if dialogue_id == "" or start_node_id == "":
		return false
	if _nodes.is_empty():
		return false
	return _nodes.has(start_node_id)


## Returns the total number of nodes in this graph.
func node_count() -> int:
	return _nodes.size()
