## DoorInteractable
## Overworld runtime class — extends Node.
## Manages a door's interactable state on the overworld map.
## Delegates door logic to DoorState (rules_engine).
##
## When interact() is called, toggles the door open/closed and emits
## door_state_changed so consumers (e.g. GridMovementController) can
## update their blocked_tiles accordingly.
##
## Architecture: extends Node. Holds a DoorState (rules_engine).
## Emits signals for the scene layer to react to.
## Does not manipulate any visual node directly.
class_name DoorInteractable
extends Node

const DoorStateClass = preload("res://rules_engine/core/door_state.gd")
const DoorInteractableClass = preload("res://overworld/door_interactable.gd")

## Emitted after the door's open/closed state changes.
## position : Vector2i — tile position of the door.
## is_open  : bool     — true when the door is now open.
signal door_state_changed(position: Vector2i, is_open: bool)

var _state: DoorStateClass = DoorStateClass.new()


## Constructs a DoorInteractable from a Dictionary (e.g. parsed JSON).
## Expected keys match DoorState.from_dict():
##   "position" : Dictionary with "x" (int) and "y" (int)
##   "is_open"  : bool (default false)
static func from_dict(data: Dictionary):
	var interactable := DoorInteractableClass.new()
	interactable._state = DoorStateClass.from_dict(data)
	return interactable


## Toggle the door's open/closed state.
## Emits door_state_changed with the new state.
func interact() -> void:
	_state.toggle()
	door_state_changed.emit(_state.position, _state.is_open)


## Returns the tile position of this door in grid coordinates.
func get_tile_position() -> Vector2i:
	return _state.position


## Sets the tile position of this door in grid coordinates.
func set_tile_position(pos: Vector2i) -> void:
	_state.position = pos


## Returns true when the door is blocking movement (i.e. is closed).
func is_blocking() -> bool:
	return _state.is_blocking()


## Returns true when the door is currently open.
func is_open() -> bool:
	return _state.is_open
