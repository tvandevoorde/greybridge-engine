## OverworldController
## Manages overworld exploration state.
## Locks/unlocks player controls and triggers the combat initialization flow.
##
## Architecture: extends Node. Delegates to CombatInitializer (combat_runtime)
## for initiative rolling. Emits signals for UI and scene layers to react to.
class_name OverworldController
extends Node

const CombatInitializerClass = preload("res://combat_runtime/combat_initializer.gd")

## Emitted when the controls_locked state changes.
signal controls_locked_changed(locked: bool)

## Emitted when combat has been initialized and is ready to begin.
## turn_order : Array of Dictionaries — actors sorted by initiative (highest first).
##              Each entry contains: { "id", "roll", "modifier", "total", "dex_score" }
## positions  : Dictionary mapping actor id (String) → Vector2i starting grid position.
signal combat_ready(turn_order: Array, positions: Dictionary)

## True when the player cannot move or interact in the overworld.
var controls_locked: bool = false


## Lock overworld controls, preventing player input.
func lock_controls() -> void:
	controls_locked = true
	controls_locked_changed.emit(true)


## Unlock overworld controls, allowing player input.
func unlock_controls() -> void:
	controls_locked = false
	controls_locked_changed.emit(false)


## Transition from overworld to combat.
## Locks controls, rolls initiative for all actors, and emits combat_ready.
##
## actors    : Array of actor Dictionaries, each with "id" and "dex_score".
## positions : Dictionary mapping actor id (String) → Vector2i starting grid position.
## roller    : DiceRoller instance (inject a seeded roller for deterministic tests).
func start_combat(actors: Array, positions: Dictionary, roller: DiceRoller) -> void:
	lock_controls()
	var initializer := CombatInitializerClass.new()
	var result: Dictionary = initializer.initialize(actors, positions, roller)
	initializer.free()
	combat_ready.emit(result["turn_order"], result["positions"])
