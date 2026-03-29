## Inventory
## Pure data class — not a Node. Manages a list of items for a player or container.
##
## Each item is a Dictionary with at minimum:
##   "id"       : String — unique item identifier
##   "name"     : String — display name
##   "quantity" : int    — stack count (defaults to 1 if omitted)
##
## Architecture: pure GDScript class. No Node, no scene references.
class_name Inventory
extends RefCounted

## Internal list of item Dictionaries held in this inventory.
var _items: Array = []


## Add a copy of [param item] to this inventory.
## If an item with the same "id" already exists, its quantity is increased.
func add_item(item: Dictionary) -> void:
	var id: String = item.get("id", "")
	if id != "":
		for existing in _items:
			if existing.get("id", "") == id:
				existing["quantity"] = existing.get("quantity", 1) + item.get("quantity", 1)
				return
	_items.append(item.duplicate())


## Returns a shallow copy of all items in this inventory.
func get_items() -> Array:
	return _items.duplicate()


## Returns true if this inventory contains an item with the given [param item_id].
func has_item(item_id: String) -> bool:
	for item in _items:
		if item.get("id", "") == item_id:
			return true
	return false


## Returns the number of distinct item entries in this inventory.
func count() -> int:
	return _items.size()


## Returns the quantity of the item with the given [param item_id].
## Returns 0 if the item is not present.
func get_quantity(item_id: String) -> int:
	for item in _items:
		if item.get("id", "") == item_id:
			return item.get("quantity", 1)
	return 0
