## DoorState
## Pure data/logic class representing a door's open/closed state.
## Tracks whether the door blocks movement on the overworld grid.
##
## Architecture: pure GDScript class — NOT a Node. No scene/resource access.
class_name DoorState
extends RefCounted

const DoorStateClass = preload("res://rules_engine/core/door_state.gd")

## The tile position of this door on the map grid.
var position: Vector2i = Vector2i.ZERO

## Whether the door is currently open. Defaults to false (closed).
var is_open: bool = false


## Constructs a DoorState from a Dictionary (e.g. parsed JSON).
## Expected keys:
##   "position" : Dictionary with "x" (int) and "y" (int)
##   "is_open"  : bool (default false)
static func from_dict(data: Dictionary):
	var state := DoorStateClass.new()
	var pos: Dictionary = data.get("position", {})
	state.position = Vector2i(int(pos.get("x", 0)), int(pos.get("y", 0)))
	state.is_open = bool(data.get("is_open", false))
	return state


## Open the door.
func open() -> void:
	is_open = true


## Close the door.
func close() -> void:
	is_open = false


## Toggle the door between open and closed.
func toggle() -> void:
	is_open = not is_open


## Returns true when the door blocks movement (i.e. is closed).
func is_blocking() -> bool:
	return not is_open
