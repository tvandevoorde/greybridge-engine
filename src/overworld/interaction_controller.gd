## InteractionController
## Overworld runtime class — extends Node.
## Tracks the player's facing direction and resolves interactions with the tile
## directly in front of the player when the interact action is triggered.
##
## Facing direction updates whenever update_facing() is called with a cardinal
## direction, so the player always faces the direction they last moved or pressed.
## Facing defaults to south (0, 1) — facing the camera in top-down view.
##
## Architecture: extends Node. Delegates resolution to InteractResolver (rules_engine).
## Emits signals for the scene layer to react to. Does not manipulate any visual node.
##
## Interactable candidates are plain Dictionaries with keys:
##   "id"       : String   — unique identifier (NPC name, door id, chest id, etc.).
##   "position" : Vector2i — tile position of the interactable.
##
## Typical wiring in a scene:
##   movement_ctrl.stepped.connect(func(from, to): interaction_ctrl.update_facing(to - from))
##   movement_ctrl.move_blocked.connect(func(_pos, dir, _r): interaction_ctrl.update_facing(dir))
class_name InteractionController
extends Node

const InteractResolverClass = preload("res://rules_engine/core/interact_resolver.gd")

## Emitted when the player interacts with something at target_tile.
## target_tile     : Vector2i — tile the player interacted with.
## interactable_id : String   — "id" value from the matched interactable entry.
signal interacted(target_tile: Vector2i, interactable_id: String)

## Emitted when the player presses interact but the tile in front is empty.
## target_tile : Vector2i — tile that was checked.
signal interact_empty(target_tile: Vector2i)

## Current facing direction of the player (unit cardinal vector).
## Defaults to south so the player faces "toward the camera" on spawn.
var facing: Vector2i = Vector2i(0, 1)

## Interactable objects on the current map.
## Each entry is a Dictionary with "id" (String) and "position" (Vector2i).
var interactables: Array = []

var _controls_locked: bool = false
var _resolver: InteractResolverClass = InteractResolverClass.new()


## Prevent interaction input from being processed.
## Clears no held-input state (interaction has no repeat mechanic).
func lock_controls() -> void:
	_controls_locked = true


## Allow interaction input to be processed.
func unlock_controls() -> void:
	_controls_locked = false


## Returns true when controls are locked.
func is_controls_locked() -> bool:
	return _controls_locked


## Update the player's facing direction.
## Call this whenever the player inputs a direction (on movement or on a blocked step).
## Only cardinal directions (N/S/E/W) are meaningful; other values are accepted but
## will produce an off-axis interact target.
func update_facing(direction: Vector2i) -> void:
	facing = direction


## Replace the full set of interactable candidates.
func set_interactables(items: Array) -> void:
	interactables = items.duplicate()


## Attempt an interaction from from_position using the current facing direction.
## Emits interacted when an interactable occupies the tile in front.
## Emits interact_empty when no interactable is found there.
## Has no effect when controls are locked.
##
## from_position : Vector2i — the player's current grid tile.
func request_interact(from_position: Vector2i) -> void:
	if _controls_locked:
		return
	var target: Vector2i = _resolver.get_interact_target(from_position, facing)
	var found: Dictionary = _resolver.resolve(target, interactables)
	if found.is_empty():
		interact_empty.emit(target)
	else:
		interacted.emit(target, found["id"])


func _unhandled_input(event: InputEvent) -> void:
	if _controls_locked:
		return

	# Update facing on directional press (mirrors GridMovementController direction logic).
	if event.is_action_pressed("ui_up"):
		update_facing(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		update_facing(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		update_facing(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		update_facing(Vector2i(1, 0))
