## OverworldController
## Manages overworld exploration state.
## Locks/unlocks player controls and triggers the combat initialization flow.
##
## Architecture: extends Node. Delegates to CombatInitializer (combat_runtime)
## for initiative rolling. Emits signals for UI and scene layers to react to.
class_name OverworldController
extends Node

const CombatInitializerClass = preload("res://combat_runtime/combat_initializer.gd")
const DiceRollerClass = preload("res://rules_engine/core/dice_roller.gd")

## Emitted when the controls_locked state changes.
signal controls_locked_changed(locked: bool)

## Emitted when combat has been initialized and is ready to begin.
## turn_order : Array of Dictionaries — actors sorted by initiative (highest first).
##              Each entry contains: { "id", "roll", "modifier", "total", "dex_score" }
## positions  : Dictionary mapping actor id (String) → Vector2i starting grid position.
signal combat_ready(turn_order: Array, positions: Dictionary)

## Emitted when combat resolves and the overworld resumes.
## rewards : Array of reward items collected during the combat encounter.
signal combat_resolved(rewards: Array)

## True when the player cannot move or interact in the overworld.
var controls_locked: bool = false

## Reward items collected from the most recent combat encounter.
## Populated by return_from_combat() and cleared on the next start_combat().
var pending_rewards: Array = []

## The player's grid tile position at the moment combat was initiated.
## Preserved so the scene can restore the player after returning from combat.
var saved_player_tile: Vector2i = Vector2i(0, 0)


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
## Preserves the player's current tile position for restoration after combat.
##
## actors      : Array of actor Dictionaries, each with "id" and "dex_score".
## positions   : Dictionary mapping actor id (String) → Vector2i starting grid position.
## roller      : DiceRoller instance (inject a seeded roller for deterministic tests).
## player_tile : Vector2i — the player's current overworld tile (saved for return).
func start_combat(actors: Array, positions: Dictionary, roller: DiceRollerClass, player_tile: Vector2i = Vector2i(0, 0)) -> void:
	pending_rewards = []
	saved_player_tile = player_tile
	lock_controls()
	var initializer := CombatInitializerClass.new()
	var result: Dictionary = initializer.initialize(actors, positions, roller)
	initializer.free()
	combat_ready.emit(result["turn_order"], result["positions"])


## Called when combat ends and the scene returns to the overworld.
## Stores the rewards collected during combat, unlocks player controls,
## and emits combat_resolved so the scene can distribute rewards.
##
## rewards : Array of reward items collected during the combat encounter.
func return_from_combat(rewards: Array) -> void:
	pending_rewards = rewards.duplicate()
	unlock_controls()
	combat_resolved.emit(pending_rewards)
