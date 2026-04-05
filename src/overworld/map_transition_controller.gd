## MapTransitionController
## Overworld runtime class — extends Node.
## Manages map transition points loaded from a MapDefinition.  When the player
## steps onto a registered transition tile, this controller validates the
## transition conditions and emits transition_triggered.
##
## Architecture: extends Node.  Delegates flag validation to
## MapTransitionResolver (rules_engine).  Emits signals for the scene layer.
##
## Usage:
##   1. Call load_transitions(map_def.transitions) after loading a new map.
##   2. Call set_quest_flags(flags) whenever quest flags change.
##   3. Connect GridMovementController.stepped to on_player_stepped.
##   4. Listen to transition_triggered to perform the actual map swap.
class_name MapTransitionController
extends Node

const MapTransitionClass = preload("res://rules_engine/core/map_transition.gd")
const MapTransitionResolverClass = preload("res://rules_engine/core/map_transition_resolver.gd")

## Emitted when the player steps onto a valid, unblocked transition tile.
## target_map   : String    — map_id of the destination map.
## target_spawn : Vector2i  — spawn tile on the destination map.
signal transition_triggered(target_map: String, target_spawn: Vector2i)

## All transition definitions loaded for the current map.
var _transitions: Array = []

## Current quest flag state (flag_name → value).
var _quest_flags: Dictionary = {}

var _resolver: MapTransitionResolverClass = MapTransitionResolverClass.new()


## Loads transition definitions from an Array of raw Dictionaries.
## Invalid transitions (empty target_map) are silently discarded.
## Clears any previously loaded transitions.
func load_transitions(transitions: Array) -> void:
	_transitions = []
	for raw in transitions:
		var t: MapTransitionClass = MapTransitionClass.from_dict(raw)
		if t.is_valid():
			_transitions.append(t)


## Updates the quest flag state used for conditional transition resolution.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Called by the scene layer when the player successfully steps from [param from]
## to [param to].  Checks whether [param to] is a registered transition tile
## and, if so, whether its conditions are met.  Emits transition_triggered on
## success.  Silently ignores the step when the tile is not a transition point
## or its conditions are not met.
func on_player_stepped(from: Vector2i, to: Vector2i) -> void:
	for transition in _transitions:
		if transition.tile == to:
			var result: Dictionary = _resolver.resolve(transition, _quest_flags)
			if result["can_transition"]:
				transition_triggered.emit(transition.target_map, transition.target_spawn)
			return
