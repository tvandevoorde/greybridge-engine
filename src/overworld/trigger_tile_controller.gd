## TriggerTileController
## Overworld runtime class — extends Node.
## Monitors the tile the player steps onto and emits combat trigger events.
##
## Architecture: extends Node. Delegates trigger evaluation to
## TriggerTileResolver (rules_engine). Does not implement rules logic itself.
class_name TriggerTileController
extends Node

const TriggerTileResolverClass = preload("res://rules_engine/core/trigger_tile_resolver.gd")

## Emitted when a combat_start trigger fires.
## encounter_id : String   — identifier of the encounter to begin.
## player_tile  : Vector2i — grid tile the player just stepped onto.
signal combat_trigger_fired(encounter_id: String, player_tile: Vector2i)

## Trigger layer data loaded from the map definition.
## Array of rows (Array[Array]) — null means no trigger, Dictionary means trigger data.
var _trigger_layer: Array = []

## Encounter IDs that have already fired this session.
var _fired_trigger_ids: Array = []

## Current quest flag state (reserved for future conditions).
var _quest_flags: Dictionary = {}

var _resolver: TriggerTileResolverClass = TriggerTileResolverClass.new()


## Load the trigger layer and reset fired trigger state.
func load_triggers(layer: Array) -> void:
	_trigger_layer = layer.duplicate(true)
	_fired_trigger_ids = []


## Replace quest flags used by the resolver.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Called when the player steps to a new tile.
## Only the destination tile is checked for triggers.
func on_stepped(from: Vector2i, to: Vector2i) -> void:
	var trigger = _get_trigger_at(to)
	var result: Dictionary = _resolver.resolve(trigger, _fired_trigger_ids, _quest_flags)
	if not result.get("should_fire", false):
		return

	var trigger_type: String = trigger.get("type", "")
	var encounter_id: String = trigger.get("encounter_id", "")

	if trigger_type == "combat_start":
		if encounter_id != "":
			_fired_trigger_ids.append(encounter_id)
		combat_trigger_fired.emit(encounter_id, to)


## Returns trigger data at [param tile], or null when out of bounds / no trigger.
func _get_trigger_at(tile: Vector2i):
	if _trigger_layer.is_empty():
		return null

	var row: int = tile.y
	var col: int = tile.x
	if row < 0 or row >= _trigger_layer.size():
		return null

	var layer_row: Array = _trigger_layer[row]
	if col < 0 or col >= layer_row.size():
		return null

	return layer_row[col]
