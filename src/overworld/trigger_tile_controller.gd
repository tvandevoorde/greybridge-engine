## TriggerTileController
## Overworld runtime class — extends Node.
## Monitors player movement, detects when the player enters a trigger tile,
## and fires the appropriate signals to initiate combat or other overworld events.
##
## Architecture: extends Node. Delegates trigger resolution to TriggerTileResolver
## (rules_engine). Emits signals for the scene to connect to OverworldController.
## Does not call OverworldController directly — no 5e logic here.
##
## Usage:
##   1. Call load_triggers(map_definition.layers["triggers"]) after loading the map.
##   2. Connect GridMovementController.stepped to on_stepped.
##   3. Listen to combat_trigger_fired to start combat via OverworldController.
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

## Encounter IDs that have already fired. Prevents one-shot encounters from
## re-triggering when the player walks back over the same tile.
var _fired_trigger_ids: Array = []

## Current quest flag state. Reserved for future conditional trigger logic.
var _quest_flags: Dictionary = {}

var _resolver: TriggerTileResolverClass = TriggerTileResolverClass.new()


## Load the trigger layer from the map definition and reset fired state.
## layer : Array of rows from MapDefinition.layers["triggers"]
func load_triggers(layer: Array) -> void:
	_trigger_layer = layer.duplicate(true)
	_fired_trigger_ids = []


## Replace the current quest flags used for conditional trigger resolution.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Called when the player steps to a new tile.
## Checks whether the destination tile has a trigger and fires the appropriate signal.
## Connect this to GridMovementController.stepped.
##
## from : Vector2i — tile the player left.
## to   : Vector2i — tile the player entered.
func on_stepped(from: Vector2i, to: Vector2i) -> void:
	var trigger = _get_trigger_at(to)
	var result: Dictionary = _resolver.resolve(trigger, _fired_trigger_ids, _quest_flags)
	if not result["should_fire"]:
		return

	var trigger_type: String = trigger.get("type", "")
	var encounter_id: String = trigger.get("encounter_id", "")

	if trigger_type == "combat_start":
		_fired_trigger_ids.append(encounter_id)
		combat_trigger_fired.emit(encounter_id, to)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

## Returns the trigger data at the given tile, or null if none exists.
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
