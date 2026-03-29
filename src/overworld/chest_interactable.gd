## ChestInteractable
## Overworld runtime class — extends Node.
## Represents a chest that can be opened once and yields loot to an Inventory.
##
## Loot is injected at setup time via set_loot(), using data sourced from
## map definitions or content JSON.  When the player opens the chest, all loot
## items are transferred to the given Inventory and the chest is permanently
## marked as opened.
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

## True once this chest has been opened.  A chest can only be opened once.
var is_opened: bool = false

## List of item Dictionaries that this chest will yield when opened.
## Populated by set_loot() before the first call to open().
var loot: Array = []


## Replace the chest's loot with a copy of [param items].
## Must be called before open() to define what the chest contains.
func set_loot(items: Array) -> void:
	loot = items.duplicate(true)


## Attempt to open this chest.
##
## If the chest is already opened, returns an empty Array and emits nothing.
## Otherwise, transfers all loot items into [param inventory], marks the chest
## as opened, and emits chest_opened with the list of transferred items.
##
## inventory : Inventory — the player's inventory to receive the loot.
## Returns   : Array     — the items transferred (empty if already opened).
func open(inventory: InventoryClass) -> Array:
	if is_opened:
		return []
	is_opened = true
	var transferred: Array = loot.duplicate(true)
	for item in transferred:
		inventory.add_item(item)
	chest_opened.emit(transferred)
	return transferred
