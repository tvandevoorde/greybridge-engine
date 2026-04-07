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
const OverworldSnapshotClass = preload("res://rules_engine/core/overworld_snapshot.gd")

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
## Emitted when a map transition is initiated by the player stepping on a
## transition tile.  The scene layer should respond by loading the target map
## and calling OverworldBootstrap.bootstrap_at() with the supplied spawn.
## target_map   : String    — map_id of the destination map to load.
## target_spawn : Vector2i  — grid tile to place the player on arrival.
signal map_transition_started(target_map: String, target_spawn: Vector2i)

## Emitted by restore_state() after all internal state has been updated from
## the provided snapshot.  The scene layer should connect to this signal and
## restore individual controller state (player position, chest flags, door
## states, etc.) from the supplied snapshot.
signal overworld_state_restored(snapshot: OverworldSnapshotClass)

## True when the player cannot move or interact in the overworld.
var controls_locked: bool = false

## Reward items collected from the most recent combat encounter.
## Populated by return_from_combat() and cleared on the next start_combat().
var pending_rewards: Array = []

## The music track identifier for the currently loaded map.
## Set via set_current_music_track() after bootstrap.
var current_music_track: String = ""
## The player's grid tile position at the moment combat was initiated.
## Preserved so the scene can restore the player after returning from combat.
var saved_player_tile: Vector2i = Vector2i(0, 0)

## ---------------------------------------------------------------------------
## Serializable overworld state — updated via the on_* / set_* hooks below.
## ---------------------------------------------------------------------------

## map_id of the currently active map.  Set via set_current_map().
var _current_map_id: String = ""

## Most-recently-reported player grid position (updated via on_player_state_changed()).
var _player_position: Vector2i = Vector2i.ZERO

## Most-recently-reported player facing direction (updated via on_player_state_changed()).
var _player_facing: Vector2i = Vector2i(0, 1)

## Quest flags accumulated this session (updated via on_quest_flag_set()).
var _quest_flags: Dictionary = {}

## IDs of chests opened this session (updated via on_chest_opened()).
var _opened_chest_ids: Array = []

## Per-door open/closed state keyed by "x,y" string (updated via on_door_state_changed()).
var _door_states: Dictionary = {}

## Combat encounter IDs that have already fired (updated via on_trigger_fired()).
var _fired_trigger_ids: Array = []


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


## Initiate a map transition triggered by the player stepping on a
## transition tile.  Locks overworld controls and emits
## map_transition_started so the scene layer can load the new map and
## call OverworldBootstrap.bootstrap_at() with the supplied spawn.
##
## target_map   : String    — map_id of the destination map.
## target_spawn : Vector2i  — grid tile the player should arrive on.
func start_map_transition(target_map: String, target_spawn: Vector2i) -> void:
	lock_controls()
	map_transition_started.emit(target_map, target_spawn)


## ---------------------------------------------------------------------------
## State-tracking hooks — call these from the scene layer to keep the
## controller's internal state in sync for capture_state().
## ---------------------------------------------------------------------------

## Record the map_id of the map that has just been bootstrapped.
## Call this after OverworldBootstrap emits map_loaded.
##
## map_id : String — map_id from MapDefinition.
func set_current_map(map_id: String) -> void:
	_current_map_id = map_id


## Update the tracked player position and facing direction.
## Call this whenever GridMovementController emits stepped or the player
## rotates (e.g. from InteractionController.update_player_position).
##
## position : Vector2i — current player grid tile.
## facing   : Vector2i — current cardinal facing direction (unit vector).
func on_player_state_changed(position: Vector2i, facing: Vector2i) -> void:
	_player_position = position
	_player_facing = facing


## Record that a chest has been opened.
## Call this when ChestInteractable emits chest_opened.
##
## chest_id : String — unique identifier of the chest (from JSON "id" field).
func on_chest_opened(chest_id: String) -> void:
	if not _opened_chest_ids.has(chest_id):
		_opened_chest_ids.append(chest_id)


## Record a door's current open/closed state.
## Call this when DoorInteractable emits door_state_changed.
##
## position : Vector2i — tile position of the door.
## is_open  : bool     — true when the door is now open.
func on_door_state_changed(position: Vector2i, is_open: bool) -> void:
	var key: String = "%d,%d" % [position.x, position.y]
	_door_states[key] = is_open


## Record a quest flag update.
## Call this when NpcController emits quest_flag_set or TriggerTileController
## emits flag_trigger_fired.
##
## flag_name  : String  — the flag key.
## flag_value : Variant — the flag value (typically bool or int).
func on_quest_flag_set(flag_name: String, flag_value: Variant) -> void:
	_quest_flags[flag_name] = flag_value


## Record that a combat trigger has fired so it is suppressed on reload.
## Call this when TriggerTileController emits combat_trigger_fired.
##
## encounter_id : String — identifier of the encounter that fired.
func on_trigger_fired(encounter_id: String) -> void:
	if not _fired_trigger_ids.has(encounter_id):
		_fired_trigger_ids.append(encounter_id)


## ---------------------------------------------------------------------------
## Serialization hooks
## ---------------------------------------------------------------------------

## Build and return an OverworldSnapshot from the current tracked state.
## The caller (save system / scene layer) can then call snapshot.to_dict()
## to serialize to JSON.
func capture_state() -> OverworldSnapshotClass:
	var snap := OverworldSnapshotClass.new()
	snap.map_id = _current_map_id
	snap.player_position = _player_position
	snap.player_facing = _player_facing
	snap.quest_flags = _quest_flags.duplicate()
	snap.opened_chest_ids = _opened_chest_ids.duplicate()
	snap.door_states = _door_states.duplicate()
	snap.fired_trigger_ids = _fired_trigger_ids.duplicate()
	return snap


## Restore internal state from a previously captured snapshot, then emit
## overworld_state_restored so the scene layer can re-apply the state to
## individual controllers (GridMovementController, ChestInteractable, etc.).
##
## snapshot : OverworldSnapshot — produced by OverworldSnapshot.from_dict().
func restore_state(snapshot: OverworldSnapshotClass) -> void:
	_current_map_id = snapshot.map_id
	_player_position = snapshot.player_position
	_player_facing = snapshot.player_facing
	_quest_flags = snapshot.quest_flags.duplicate()
	_opened_chest_ids = snapshot.opened_chest_ids.duplicate()
	_door_states = snapshot.door_states.duplicate()
	_fired_trigger_ids = snapshot.fired_trigger_ids.duplicate()
	overworld_state_restored.emit(snapshot)
