## test_inventory.gd
## Unit tests for Inventory (src/rules_engine/core/inventory.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/rules_engine/test_inventory.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const InventoryClass = preload("res://rules_engine/core/inventory.gd")

var _pass_count: int = 0
var _fail_count: int = 0


func _initialize() -> void:
	_run_all_tests()
	print("\nResults: %d passed, %d failed" % [_pass_count, _fail_count])
	quit(1 if _fail_count > 0 else 0)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
		_pass_count += 1
	else:
		print("  FAIL: %s" % description)
		_fail_count += 1


func _run_all_tests() -> void:
	_test_empty_inventory_has_count_zero()
	_test_add_item_increases_count()
	_test_add_item_stores_item()
	_test_has_item_returns_true_when_present()
	_test_has_item_returns_false_when_absent()
	_test_add_duplicate_id_stacks_quantity()
	_test_add_item_without_id_appended_separately()
	_test_get_items_returns_copy()
	_test_get_quantity_returns_correct_value()
	_test_get_quantity_returns_zero_for_absent_item()
	_test_add_item_stores_copy_not_reference()
	_test_multiple_distinct_items()
	_test_stack_respects_incoming_quantity()


# ---------------------------------------------------------------------------
# Empty inventory
# ---------------------------------------------------------------------------
func _test_empty_inventory_has_count_zero() -> void:
	print("_test_empty_inventory_has_count_zero")
	var inv := InventoryClass.new()
	_check(inv.count() == 0, "count() is 0 on empty inventory")


# ---------------------------------------------------------------------------
# add_item
# ---------------------------------------------------------------------------
func _test_add_item_increases_count() -> void:
	print("_test_add_item_increases_count")
	var inv := InventoryClass.new()
	inv.add_item({"id": "sword", "name": "Iron Sword", "quantity": 1})
	_check(inv.count() == 1, "count() is 1 after one add_item()")


func _test_add_item_stores_item() -> void:
	print("_test_add_item_stores_item")
	var inv := InventoryClass.new()
	inv.add_item({"id": "shield", "name": "Wooden Shield", "quantity": 1})
	var items := inv.get_items()
	_check(items.size() == 1, "get_items() returns one entry")
	_check(items[0].get("id") == "shield", "stored item has correct id")
	_check(items[0].get("name") == "Wooden Shield", "stored item has correct name")


# ---------------------------------------------------------------------------
# has_item
# ---------------------------------------------------------------------------
func _test_has_item_returns_true_when_present() -> void:
	print("_test_has_item_returns_true_when_present")
	var inv := InventoryClass.new()
	inv.add_item({"id": "health_potion", "name": "Health Potion", "quantity": 1})
	_check(inv.has_item("health_potion") == true,
		"has_item() returns true for present item")


func _test_has_item_returns_false_when_absent() -> void:
	print("_test_has_item_returns_false_when_absent")
	var inv := InventoryClass.new()
	_check(inv.has_item("nonexistent") == false,
		"has_item() returns false for absent item")


# ---------------------------------------------------------------------------
# Stacking by id
# ---------------------------------------------------------------------------
func _test_add_duplicate_id_stacks_quantity() -> void:
	print("_test_add_duplicate_id_stacks_quantity")
	var inv := InventoryClass.new()
	inv.add_item({"id": "arrow", "name": "Arrow", "quantity": 5})
	inv.add_item({"id": "arrow", "name": "Arrow", "quantity": 3})
	_check(inv.count() == 1, "duplicate id does not create a new entry")
	_check(inv.get_quantity("arrow") == 8, "quantities are summed on stack")


func _test_stack_respects_incoming_quantity() -> void:
	print("_test_stack_respects_incoming_quantity")
	var inv := InventoryClass.new()
	inv.add_item({"id": "gold_coins", "name": "Gold Coins", "quantity": 10})
	inv.add_item({"id": "gold_coins", "name": "Gold Coins", "quantity": 5})
	_check(inv.get_quantity("gold_coins") == 15,
		"stack adds both quantities correctly")


# ---------------------------------------------------------------------------
# Items without id are always appended
# ---------------------------------------------------------------------------
func _test_add_item_without_id_appended_separately() -> void:
	print("_test_add_item_without_id_appended_separately")
	var inv := InventoryClass.new()
	inv.add_item({"name": "Mystery Box"})
	inv.add_item({"name": "Mystery Box"})
	_check(inv.count() == 2, "items without id are each appended separately")


# ---------------------------------------------------------------------------
# get_items returns a copy
# ---------------------------------------------------------------------------
func _test_get_items_returns_copy() -> void:
	print("_test_get_items_returns_copy")
	var inv := InventoryClass.new()
	inv.add_item({"id": "key", "name": "Dungeon Key", "quantity": 1})
	var items := inv.get_items()
	items.clear()
	_check(inv.count() == 1,
		"clearing returned Array does not affect internal inventory")


# ---------------------------------------------------------------------------
# get_quantity
# ---------------------------------------------------------------------------
func _test_get_quantity_returns_correct_value() -> void:
	print("_test_get_quantity_returns_correct_value")
	var inv := InventoryClass.new()
	inv.add_item({"id": "torch", "name": "Torch", "quantity": 3})
	_check(inv.get_quantity("torch") == 3, "get_quantity() returns stored quantity")


func _test_get_quantity_returns_zero_for_absent_item() -> void:
	print("_test_get_quantity_returns_zero_for_absent_item")
	var inv := InventoryClass.new()
	_check(inv.get_quantity("rope") == 0,
		"get_quantity() returns 0 for absent item")


# ---------------------------------------------------------------------------
# add_item stores a copy, not a reference
# ---------------------------------------------------------------------------
func _test_add_item_stores_copy_not_reference() -> void:
	print("_test_add_item_stores_copy_not_reference")
	var inv := InventoryClass.new()
	var item := {"id": "gem", "name": "Ruby", "quantity": 1}
	inv.add_item(item)
	item["name"] = "Modified"
	var stored := inv.get_items()
	_check(stored[0].get("name") == "Ruby",
		"modifying original dict does not affect stored item")


# ---------------------------------------------------------------------------
# Multiple distinct items
# ---------------------------------------------------------------------------
func _test_multiple_distinct_items() -> void:
	print("_test_multiple_distinct_items")
	var inv := InventoryClass.new()
	inv.add_item({"id": "sword", "name": "Sword", "quantity": 1})
	inv.add_item({"id": "shield", "name": "Shield", "quantity": 1})
	inv.add_item({"id": "potion", "name": "Potion", "quantity": 2})
	_check(inv.count() == 3, "three distinct items stored separately")
	_check(inv.has_item("sword"), "sword is present")
	_check(inv.has_item("shield"), "shield is present")
	_check(inv.has_item("potion"), "potion is present")
