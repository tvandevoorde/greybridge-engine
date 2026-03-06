## CombatCameraController
## Orchestrates camera focus during combat turns.
## Extends Node — lives in the combat_runtime layer.
##
## Responsibilities:
##   - Centers the camera on the active actor when a turn begins.
##   - Broadcasts which actor is currently highlighted (for UI turn indicators).
##   - Briefly shifts focus to an attack target when an attack is declared.
##   - Returns focus to the active actor once the attack resolves.
##
## This class contains NO rules logic and performs NO 5e math.
## Connect its signals from the scene / UI layer; call its methods from the
## combat runtime orchestrator.
class_name CombatCameraController
extends Node

## Emitted whenever the camera should reposition to a new world position.
## Consumers (e.g. a Camera2D tween) should interpolate to this position.
signal camera_focus_requested(position: Vector2)

## Emitted when a new actor becomes the active turn owner.
## Consumers (e.g. a turn-highlight sprite) should mark this actor.
signal actor_highlighted(actor_id: String)

## Emitted when the brief attack-target focus ends and the camera has
## been asked to return to the active actor's position.
signal focus_returned(position: Vector2)

## Duration hint (seconds) for how long the camera should linger on an
## attack target before returning.  Not enforced here — provided as data
## for the consumer (e.g. a tween).
var attack_focus_duration: float = 0.8

var _active_actor_id: String = ""
var _active_position: Vector2 = Vector2.ZERO


## Call this at the start of each combatant's turn.
## Moves the camera to [param position] and highlights [param actor_id].
func on_turn_started(actor_id: String, position: Vector2) -> void:
	_active_actor_id = actor_id
	_active_position = position
	camera_focus_requested.emit(position)
	actor_highlighted.emit(actor_id)


## Call this when an attack is declared against a target at [param target_position].
## Shifts the camera briefly to the target.
func on_attack_declared(target_position: Vector2) -> void:
	camera_focus_requested.emit(target_position)


## Call this when an attack resolves (hit or miss).
## Returns the camera to the active actor.
func on_attack_resolved() -> void:
	camera_focus_requested.emit(_active_position)
	focus_returned.emit(_active_position)


## Returns the actor_id of the currently active combatant.
func get_active_actor_id() -> String:
	return _active_actor_id


## Returns the last known position of the active combatant.
func get_active_position() -> Vector2:
	return _active_position
