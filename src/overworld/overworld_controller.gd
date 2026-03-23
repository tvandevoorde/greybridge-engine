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

## Emitted when combat begins and overworld music should stop or change.
## The scene layer should use this to switch to combat music.
signal combat_music_requested()

## Emitted when combat ends and the overworld music should resume.
## track_id : String — the music track associated with the current map.
##            Empty string when no track was set for this map.
signal overworld_music_resumed(track_id: String)

## True when the player cannot move or interact in the overworld.
var controls_locked: bool = false

## Reward items collected from the most recent combat encounter.
## Populated by return_from_combat() and cleared on the next start_combat().
var pending_rewards: Array = []

## The music track identifier for the currently loaded map.
## Set via set_current_music_track() after bootstrap.
var current_music_track: String = ""


## Lock overworld controls, preventing player input.
func lock_controls() -> void:
	controls_locked = true
	controls_locked_changed.emit(true)


## Unlock overworld controls, allowing player input.
func unlock_controls() -> void:
	controls_locked = false
	controls_locked_changed.emit(false)


## Store the music track identifier for the currently loaded map.
## Call this after bootstrap so return_from_combat() can resume the correct track.
##
## track_id : The music track identifier from MapDefinition.music_track.
##            Pass an empty string to indicate no music for this map.
func set_current_music_track(track_id: String) -> void:
	current_music_track = track_id


## Transition from overworld to combat.
## Locks controls, rolls initiative for all actors, emits combat_music_requested,
## and emits combat_ready.
##
## actors    : Array of actor Dictionaries, each with "id" and "dex_score".
## positions : Dictionary mapping actor id (String) → Vector2i starting grid position.
## roller    : DiceRoller instance (inject a seeded roller for deterministic tests).
func start_combat(actors: Array, positions: Dictionary, roller: DiceRollerClass) -> void:
	pending_rewards = []
	lock_controls()
	combat_music_requested.emit()
	var initializer := CombatInitializerClass.new()
	var result: Dictionary = initializer.initialize(actors, positions, roller)
	initializer.free()
	combat_ready.emit(result["turn_order"], result["positions"])


## Called when combat ends and the scene returns to the overworld.
## Stores the rewards collected during combat, unlocks player controls,
## emits combat_resolved so the scene can distribute rewards, and emits
## overworld_music_resumed so the scene can resume background music.
##
## rewards : Array of reward items collected during the combat encounter.
func return_from_combat(rewards: Array) -> void:
	pending_rewards = rewards.duplicate()
	unlock_controls()
	combat_resolved.emit(pending_rewards)
	overworld_music_resumed.emit(current_music_track)
