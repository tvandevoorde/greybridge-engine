## ChestInteractable
## Overworld runtime class — extends Node.
## Represents a chest that can be opened once and yields loot to an Inventory.
##
## Loot is injected at setup time via set_loot(), using data sourced from
## map definitions or content JSON.  When the player opens the chest, all loot
## items are transferred to the given Inventory and the chest is permanently
## marked as opened.
##
## Quest flag gating: set required_flags and call set_quest_flags() with the
## current world state to prevent the chest from opening until the conditions
## are met.  interaction_blocked is emitted when a flag requirement blocks the
## open attempt.
##
## Architecture: extends Node.  Delegates item management to Inventory
## (rules_engine).  Emits signals for UI and scene layers to react to.
## Contains no rendering or audio logic.
class_name ChestInteractable
extends Node

const InventoryClass = preload("res://rules_engine/core/inventory.gd")

## Emitted once when the chest is successfully opened.
## items : Array — list of item Dictionaries transferred to the inventory.
signal chest_opened(items: Array)

## Emitted when an open() attempt is blocked because a required quest flag
## is not satisfied.
## reason : String — always "missing_flag" in the current implementation.
signal interaction_blocked(reason: String)

## True once this chest has been opened.  A chest can only be opened once.
var is_opened: bool = false

## List of item Dictionaries that this chest will yield when opened.
## Populated by set_loot() before the first call to open().
var loot: Array = []

## Quest flags that must all match the current world state before this chest
## can be opened.  Keys are flag names (String); values are required values
## (Variant).  An empty dictionary means no flags are required.
var required_flags: Dictionary = {}

## Current world quest flag state used to validate required_flags.
## Updated by set_quest_flags() whenever the world state changes.
var _quest_flags: Dictionary = {}


## Replace the chest's loot with a copy of [param items].
## Must be called before open() to define what the chest contains.
func set_loot(items: Array) -> void:
	loot = items.duplicate(true)


## Set the quest flags that must be satisfied before this chest can be opened.
## Pass a copy of the flags from the map definition or content JSON.
func set_required_flags(flags: Dictionary) -> void:
	required_flags = flags.duplicate(true)


## Replace the current world quest flag state used to evaluate required_flags.
## Call this whenever a quest flag changes so the chest immediately reflects
## the new world state.
func set_quest_flags(flags: Dictionary) -> void:
	_quest_flags = flags.duplicate()


## Attempt to open this chest.
##
## If the chest is already opened, returns an empty Array and emits nothing.
## If any required_flags condition is not met, emits interaction_blocked and
## returns an empty Array.
## Otherwise, transfers all loot items into [param inventory], marks the chest
## as opened, and emits chest_opened with the list of transferred items.
##
## inventory : Inventory — the player's inventory to receive the loot.
## Returns   : Array     — the items transferred (empty if already opened or blocked).
func open(inventory: InventoryClass) -> Array:
	if is_opened:
		return []
	for flag_name in required_flags:
		if _quest_flags.get(flag_name, null) != required_flags[flag_name]:
			interaction_blocked.emit("missing_flag")
			return []
	is_opened = true
	var transferred: Array = loot.duplicate(true)
	for item in transferred:
		inventory.add_item(item)
	chest_opened.emit(transferred)
	return transferred
