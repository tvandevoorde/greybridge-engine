## DoorInteractable
## Overworld runtime class — extends Node.
## Manages a door's interactable state on the overworld map.
## Delegates door logic to DoorState (rules_engine).
##
## When interact() is called, toggles the door open/closed and emits
## door_state_changed so consumers (e.g. GridMovementController) can
## update their blocked_tiles accordingly.
##
## Quest flag gating: set required_flags (via from_dict or set_required_flags)
## and call set_quest_flags() with the current world state to prevent the door
## from toggling until the conditions are met.  interaction_blocked is emitted
## when a flag requirement blocks the interact attempt.
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

## Emitted when an interact() attempt is blocked because a required quest flag
## is not satisfied.
## reason : String — always "missing_flag" in the current implementation.
signal interaction_blocked(reason: String)

var _state: DoorStateClass = DoorStateClass.new()

## Quest flags that must all match the current world state before this door
## can be toggled.  Keys are flag names (String); values are required values
## (Variant).  An empty dictionary means no flags are required.
var required_flags: Dictionary = {}

## Current world quest flag state used to validate required_flags.
## Updated by set_quest_flags() whenever the world state changes.
var _quest_flags: Dictionary = {}


## Constructs a DoorInteractable from a Dictionary (e.g. parsed JSON).
## Expected keys match DoorState.from_dict():
##   "position"       : Dictionary with "x" (int) and "y" (int)
##   "is_open"        : bool (default false)
##   "required_flags" : Dictionary (default {}) — flags required to interact
static func from_dict(data: Dictionary):
	var interactable := DoorInteractableClass.new()
	interactable._state = DoorStateClass.from_dict(data)
	interactable.required_flags = data.get("required_flags", {}).duplicate()
	return interactable


## Set the quest flags that must be satisfied before this door can be toggled.
func set_required_flags(flags: Dictionary) -> void:
	required_flags = flags.duplicate(true)


## Replace the current world quest flag state used to evaluate required_flags.
## Call this whenever a quest flag changes so the door immediately reflects
## the new world state.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Toggle the door's open/closed state.
## If any required_flags condition is not met, emits interaction_blocked and
## returns without changing state.
## Otherwise emits door_state_changed with the new state.
func interact() -> void:
	for flag_name in required_flags:
		if _quest_flags.get(flag_name, null) != required_flags[flag_name]:
			interaction_blocked.emit("missing_flag")
			return
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
