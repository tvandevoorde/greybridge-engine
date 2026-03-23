## GridMovementController
## Overworld runtime class — extends Node.
## Processes player directional input and steps the player exactly one tile
## per key press on a 2D integer grid.  Held inputs repeat at a configurable
## rate after an initial delay, giving the player tactile control without
## desync from the grid.
##
## Architecture: extends Node.  Delegates step validation to
## GridMovementValidator (rules_engine).  Emits signals for the scene layer
## to react to.  Does not manipulate any visual node directly.
##
## Supported input actions (mapped via Godot's InputMap or project.godot):
##   "ui_up"    → north  (0, -1)
##   "ui_down"  → south  (0,  1)
##   "ui_left"  → west   (-1, 0)
##   "ui_right" → east   (1,  0)
##
## Godot's built-in ui_* actions are always available; they default to arrow
## keys and can be supplemented with WASD or controller bindings via the
## project InputMap without changing this code.
class_name GridMovementController
extends Node

const GridMovementValidatorClass = preload("res://rules_engine/core/grid_movement_validator.gd")

## Emitted after the player successfully steps to a new tile.
## from : Vector2i — tile the player left.
## to   : Vector2i — tile the player entered.
signal stepped(from: Vector2i, to: Vector2i)

## Emitted when a requested step is rejected.
## position  : Vector2i — tile the player attempted to leave.
## direction : Vector2i — the rejected direction vector.
## reason    : String   — "blocked_by_collision" | "invalid_direction"
signal move_blocked(position: Vector2i, direction: Vector2i, reason: String)

## Emitted after the player successfully lands on a new tile.
## Connect to trigger a footstep sound effect.
## position : Vector2i — the tile the player has just stepped onto.
signal footstep_requested(position: Vector2i)

## Current grid tile occupied by the player.
var current_position: Vector2i = Vector2i(0, 0)

## Tiles the player cannot enter (walls, obstacles).
var blocked_tiles: Array = []

## Seconds before a held direction begins repeating.
var hold_delay_sec: float = 0.35

## Seconds between repeated steps while a direction is held.
var step_interval_sec: float = 0.15

var _controls_locked: bool = false
var _validator: GridMovementValidatorClass = GridMovementValidatorClass.new()

## Direction currently held by the player (zero vector when no key is held).
var _held_direction: Vector2i = Vector2i(0, 0)

## Seconds accumulated since the held key was first pressed.
var _hold_elapsed_sec: float = 0.0

## True once the hold delay has elapsed and the first repeated step has fired.
var _hold_initial_fired: bool = false


## Prevent the player from moving.
## Clears any held-input state so there is no ghost movement after unlock.
func lock_controls() -> void:
	_controls_locked = true
	_held_direction = Vector2i(0, 0)
	_hold_elapsed_sec = 0.0
	_hold_initial_fired = false


## Allow the player to move.
func unlock_controls() -> void:
	_controls_locked = false


## Returns true when controls are locked.
func is_controls_locked() -> bool:
	return _controls_locked


## Teleport the player to a specific grid tile without emitting stepped.
## Use this for scene setup and respawning.
func set_position(pos: Vector2i) -> void:
	current_position = pos


## Replace the full set of collision tiles.
func set_blocked_tiles(tiles: Array) -> void:
	blocked_tiles = tiles.duplicate()


## Attempt a single step in the given direction.
## Called internally by the input handlers and directly in tests.
## Emits stepped on success, or move_blocked on failure.
## Has no effect when controls are locked.
func request_step(direction: Vector2i) -> void:
	if _controls_locked:
		return
	var result: Dictionary = _validator.validate_step(current_position, direction, blocked_tiles)
	if result["success"]:
		var from: Vector2i = current_position
		current_position = result["new_position"]
		stepped.emit(from, current_position)
		footstep_requested.emit(current_position)
	else:
		move_blocked.emit(current_position, direction, result["reason"])


func _unhandled_input(event: InputEvent) -> void:
	if _controls_locked:
		return

	var dir: Vector2i = _direction_from_event(event)

	if dir == Vector2i(0, 0):
		# A directional key was released — clear the held state.
		if event.is_action_released("ui_up") or event.is_action_released("ui_down") \
				or event.is_action_released("ui_left") or event.is_action_released("ui_right"):
			_held_direction = Vector2i(0, 0)
			_hold_elapsed_sec = 0.0
			_hold_initial_fired = false
		return

	if event.is_pressed() and not event.is_echo():
		# Fresh press: fire one step immediately and start the hold timer.
		_held_direction = dir
		_hold_elapsed_sec = 0.0
		_hold_initial_fired = false
		request_step(dir)


func _process(delta: float) -> void:
	if _controls_locked or _held_direction == Vector2i(0, 0):
		return

	_hold_elapsed_sec += delta

	if not _hold_initial_fired:
		if _hold_elapsed_sec >= hold_delay_sec:
			_hold_initial_fired = true
			_hold_elapsed_sec = 0.0
			request_step(_held_direction)
	else:
		if _hold_elapsed_sec >= step_interval_sec:
			_hold_elapsed_sec -= step_interval_sec
			request_step(_held_direction)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _direction_from_event(event: InputEvent) -> Vector2i:
	if event.is_action("ui_up"):
		return Vector2i(0, -1)
	if event.is_action("ui_down"):
		return Vector2i(0, 1)
	if event.is_action("ui_left"):
		return Vector2i(-1, 0)
	if event.is_action("ui_right"):
		return Vector2i(1, 0)
	return Vector2i(0, 0)
