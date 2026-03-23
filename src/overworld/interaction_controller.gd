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
## Manages registration of interactable objects on the overworld grid and
## drives the interaction prompt system based on player position changes.
##
## Architecture: extends Node.  Delegates adjacency checking to
## InteractionValidator (rules_engine).  Emits signals for the UI and scene
## layers to react to.  Does not manipulate any visual node directly.
##
## Supported input action:
##   "ui_accept" — triggers interaction when the player is adjacent to an
##                 interactable (same default as Godot's Enter / Space keys).
##
## Usage:
##   # Scene setup
##   controller.register_interactable(Vector2i(3, 4), "chest_01")
##
##   # Called from GridMovementController.stepped signal handler
##   controller.update_player_position(Vector2i(3, 3))
##   # → prompt_show("chest_01") emitted because (3,3) is adjacent north of (3,4)
##
##   # Player presses interact key  →  _unhandled_input calls request_interact()
##   # → interaction_triggered("chest_01") emitted
class_name InteractionController
extends Node

const InteractionValidatorClass = preload("res://rules_engine/core/interaction_validator.gd")

## Emitted when the player steps adjacent to a registered interactable.
## handler_id : String — identifier of the nearby interactable object.
signal prompt_show(handler_id: String)

## Emitted when the player is no longer adjacent to any registered interactable.
signal prompt_hide()

## Emitted when the player activates an interaction while adjacent to an interactable.
## handler_id : String — identifier of the interactable that was triggered.
signal interaction_triggered(handler_id: String)

## Current grid position of the player (tile coordinates).
var current_position: Vector2i = Vector2i(0, 0)

# Registered interactables: maps tile position → handler identifier.
var _interactables: Dictionary = {}

var _validator: InteractionValidatorClass = InteractionValidatorClass.new()

# handler_id currently shown in the prompt, or "" when no prompt is visible.
var _current_prompt_id: String = ""


## Register an interactable at the given grid tile.
## Overwrites any existing registration at that position.
func register_interactable(position: Vector2i, handler_id: String) -> void:
	_interactables[position] = handler_id


## Remove the interactable registration at the given grid tile.
## Has no effect if no interactable is registered there.
## Refreshes the prompt state so the prompt hides if the active interactable
## was just removed.
func unregister_interactable(position: Vector2i) -> void:
	_interactables.erase(position)
	_refresh_prompt()


## Update the player's current grid position and refresh the prompt state.
## Call this whenever the player steps to a new tile (e.g. from
## GridMovementController.stepped).
func update_player_position(pos: Vector2i) -> void:
	current_position = pos
	_refresh_prompt()


## Attempt an interaction at the current player position.
## Emits interaction_triggered if the player is adjacent to a registered
## interactable.  Called by _unhandled_input on "ui_accept" and may be
## called directly from tests.
func request_interact() -> void:
	var adjacent_id: String = _find_adjacent_handler_id()
	if adjacent_id != "":
		interaction_triggered.emit(adjacent_id)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		request_interact()


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Scan registered interactables; emit prompt_show / prompt_hide as needed.
func _refresh_prompt() -> void:
	var adjacent_id: String = _find_adjacent_handler_id()
	if adjacent_id != "":
		if _current_prompt_id != adjacent_id:
			_current_prompt_id = adjacent_id
			prompt_show.emit(adjacent_id)
	else:
		if _current_prompt_id != "":
			_current_prompt_id = ""
			prompt_hide.emit()


## Returns the handler_id of the first adjacent interactable, or "" if none.
func _find_adjacent_handler_id() -> String:
	for pos: Vector2i in _interactables:
		if _validator.is_adjacent(current_position, pos):
			return _interactables[pos]
	return ""
