## NpcController
## Overworld runtime class — extends Node.
## Manages NPC state on the overworld map: tiles blocked by NPCs,
## interaction (starting dialogue), and applying quest flags from
## dialogue outcomes.
##
## Architecture: extends Node. Delegates NPC logic to NpcRegistry and
## InteractResolver (rules_engine). Emits signals for UI and system layers.
## Does not contain 5e math.
class_name NpcController
extends Node

const NpcRegistryClass = preload("res://rules_engine/core/npc_registry.gd")
const InteractResolverClass = preload("res://rules_engine/core/interact_resolver.gd")

## Emitted after load_npcs() runs with the positions of solid NPCs.
## tiles : Array of Vector2i — positions of non-pass-through NPCs that
##         must be forwarded to GridMovementController.set_blocked_tiles().
signal npc_blocked_tiles_changed(tiles: Array)

## Emitted when the player interacts with an NPC that has a dialogue_id
## and all required_flags are satisfied.
## npc_id      : String — the NPC's unique identifier.
## dialogue_id : String — the dialogue tree to start.
signal dialogue_started(npc_id: String, dialogue_id: String)

## Emitted once per flag when apply_dialogue_outcome() is called.
## flag_name  : String  — the quest flag key.
## flag_value : Variant — the value to set on that flag.
signal quest_flag_set(flag_name: String, flag_value: Variant)

var _registry: NpcRegistryClass = NpcRegistryClass.new()
var _resolver: InteractResolverClass = InteractResolverClass.new()

## Current player grid position. Updated by update_player_state().
var _player_position: Vector2i = Vector2i.ZERO

## Direction the player is currently facing (cardinal unit vector).
## Defaults to south (0, 1).
var _player_facing: Vector2i = Vector2i(0, 1)

## Current quest flag state used to validate NPC required_flags.
## Updated by set_quest_flags() whenever the world state changes.
var _quest_flags: Dictionary = {}


## Loads NPC definitions from an Array of raw Dictionaries and emits
## npc_blocked_tiles_changed so consumers can update collision data.
## Call this immediately after OverworldBootstrap.bootstrap().
func load_npcs(npc_data: Array) -> void:
	_registry.load_npcs(npc_data)
	npc_blocked_tiles_changed.emit(_registry.get_blocked_tiles())


## Updates the controller's knowledge of the player's grid position and
## facing direction. Call this whenever the player moves (stepped signal)
## or changes direction.
func update_player_state(position: Vector2i, facing: Vector2i) -> void:
	_player_position = position
	_player_facing = facing


## Replaces the current quest flag state used to validate NPC required_flags.
## Call this whenever a quest flag changes so the controller immediately
## reflects the new world state.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Attempts an interaction in the player's facing direction.
## If an NPC occupies the target tile, has a dialogue_id, and all its
## required_flags are satisfied, emits dialogue_started.
## Has no effect when no NPC is found or flag requirements are not met.
func try_interact() -> void:
	var target_tile := _resolver.get_interact_target(_player_position, _player_facing)
	var npc = _registry.get_npc_at(target_tile)
	if npc == null or npc.dialogue_id == "":
		return
	for flag_name in npc.required_flags:
		if _quest_flags.get(flag_name, null) != npc.required_flags[flag_name]:
			return
	dialogue_started.emit(npc.npc_id, npc.dialogue_id)


## Applies the quest flags produced by a completed dialogue outcome.
## Emits quest_flag_set once for each key in [param flags].
##
## npc_id : String     — the NPC whose dialogue produced the outcome.
## flags  : Dictionary — flag_name (String) → flag_value (Variant).
func apply_dialogue_outcome(npc_id: String, flags: Dictionary) -> void:
	for flag_name in flags:
		quest_flag_set.emit(flag_name, flags[flag_name])
