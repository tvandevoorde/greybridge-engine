## InteractionController
## Overworld runtime class — extends Node.
## Handles two interaction flows used by tests and runtime:
##   1) Facing-based tile-in-front interaction (interacted / interact_empty)
##   2) Adjacency-based prompt + interaction (prompt_show / prompt_hide / interaction_triggered)
class_name InteractionController
extends Node

const InteractResolverClass = preload("res://rules_engine/core/interact_resolver.gd")
const InteractionValidatorClass = preload("res://rules_engine/core/interaction_validator.gd")

signal interacted(target_tile: Vector2i, interactable_id: String)
signal interact_empty(target_tile: Vector2i)

signal prompt_show(handler_id: String)
signal prompt_hide()
signal interaction_triggered(handler_id: String)

var facing: Vector2i = Vector2i(0, 1)
var interactables: Array = []
var current_position: Vector2i = Vector2i(0, 0)

var _controls_locked: bool = false
var _resolver: InteractResolverClass = InteractResolverClass.new()
var _validator: InteractionValidatorClass = InteractionValidatorClass.new()
var _interactables: Dictionary = {}
var _current_prompt_id: String = ""


func lock_controls() -> void:
	_controls_locked = true


func unlock_controls() -> void:
	_controls_locked = false


func is_controls_locked() -> bool:
	return _controls_locked


func update_facing(direction: Vector2i) -> void:
	facing = direction


func set_interactables(items: Array) -> void:
	interactables = items.duplicate(true)


func register_interactable(position: Vector2i, handler_id: String) -> void:
	_interactables[position] = handler_id


func unregister_interactable(position: Vector2i) -> void:
	_interactables.erase(position)
	_refresh_prompt()


func update_player_position(pos: Vector2i) -> void:
	current_position = pos
	_refresh_prompt()


## Supports both request_interact(Vector2i) and request_interact().
## - With Vector2i: facing-based interaction against tile in front.
## - Without args: adjacency-based interaction against registered interactables.
func request_interact(from_position: Variant = null) -> void:
	if _controls_locked:
		return

	if from_position == null:
		var adjacent_id: String = _find_adjacent_handler_id()
		if adjacent_id != "":
			interaction_triggered.emit(adjacent_id)
		return

	if not (from_position is Vector2i):
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

	if event.is_action_pressed("ui_up"):
		update_facing(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		update_facing(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		update_facing(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		update_facing(Vector2i(1, 0))

	if event.is_action_pressed("ui_accept"):
		request_interact()


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


func _find_adjacent_handler_id() -> String:
	for pos: Vector2i in _interactables:
		if _validator.is_adjacent(current_position, pos):
			return _interactables[pos]
	return ""
