## test_chest_interactable.gd
## Unit tests for ChestInteractable (src/overworld/chest_interactable.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/overworld/test_chest_interactable.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const ChestInteractableClass = preload("res://overworld/chest_interactable.gd")
const InventoryClass = preload("res://rules_engine/core/inventory.gd")

var _pass_count: int = 0
var _fail_count: int = 0


class SignalCapture:
	var count: int = 0
	var emitted: bool = false
	var items: Array = []

	func on_chest_opened(opened_items: Array) -> void:
		count += 1
		emitted = true
		items = opened_items.duplicate(true)


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
	_test_chest_closed_by_default()
	_test_open_marks_chest_as_opened()
	_test_open_adds_loot_to_inventory()
	_test_open_returns_transferred_items()
	_test_open_second_time_returns_empty()
	_test_open_second_time_does_not_duplicate_items()
	_test_open_second_time_does_not_emit_signal()
	_test_open_emits_chest_opened_signal()
	_test_open_signal_carries_correct_items()
	_test_set_loot_replaces_existing_loot()
	_test_set_loot_stores_copy()
	_test_empty_chest_yields_no_items()
	_test_multiple_loot_items_all_added()
	_test_open_does_not_modify_original_loot_array()
	_test_open_blocked_when_required_flags_not_met()
	_test_open_allowed_when_required_flags_met()
	_test_interaction_blocked_signal_emitted_when_flags_not_met()
	_test_set_quest_flags_updates_immediately()
	_test_open_no_required_flags_always_allowed()
	_test_set_required_flags_stores_copy()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_chest_closed_by_default() -> void:
	print("_test_chest_closed_by_default")
	var chest := ChestInteractableClass.new()
	_check(chest.is_opened == false, "is_opened is false by default")
	chest.free()


# ---------------------------------------------------------------------------
# open() — successful first open
# ---------------------------------------------------------------------------
func _test_open_marks_chest_as_opened() -> void:
	print("_test_open_marks_chest_as_opened")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "gold_coins", "name": "Gold Coins", "quantity": 5}])
	chest.open(inv)
	_check(chest.is_opened == true, "is_opened is true after open()")
	chest.free()


func _test_open_adds_loot_to_inventory() -> void:
	print("_test_open_adds_loot_to_inventory")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "health_potion", "name": "Health Potion", "quantity": 1}])
	chest.open(inv)
	_check(inv.has_item("health_potion"), "health_potion added to inventory after open")
	chest.free()


func _test_open_returns_transferred_items() -> void:
	print("_test_open_returns_transferred_items")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "key", "name": "Iron Key", "quantity": 1}])
	var result: Array = chest.open(inv)
	_check(result.size() == 1, "open() returns one item")
	_check(result[0].get("id") == "key", "returned item has correct id")
	chest.free()


# ---------------------------------------------------------------------------
# open() — second open is a no-op
# ---------------------------------------------------------------------------
func _test_open_second_time_returns_empty() -> void:
	print("_test_open_second_time_returns_empty")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "gem", "name": "Gem", "quantity": 1}])
	chest.open(inv)
	var result: Array = chest.open(inv)
	_check(result.size() == 0, "second open() returns empty Array")
	chest.free()


func _test_open_second_time_does_not_duplicate_items() -> void:
	print("_test_open_second_time_does_not_duplicate_items")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "arrow", "name": "Arrow", "quantity": 10}])
	chest.open(inv)
	chest.open(inv)
	_check(inv.get_quantity("arrow") == 10,
		"second open() does not duplicate loot in inventory")
	chest.free()


func _test_open_second_time_does_not_emit_signal() -> void:
	print("_test_open_second_time_does_not_emit_signal")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "torch", "name": "Torch", "quantity": 1}])
	var capture := SignalCapture.new()
	chest.chest_opened.connect(capture.on_chest_opened)
	chest.open(inv)
	chest.open(inv)
	_check(capture.count == 1, "chest_opened emitted exactly once across two open() calls")
	chest.free()


# ---------------------------------------------------------------------------
# chest_opened signal
# ---------------------------------------------------------------------------
func _test_open_emits_chest_opened_signal() -> void:
	print("_test_open_emits_chest_opened_signal")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "sword", "name": "Sword", "quantity": 1}])
	var capture := SignalCapture.new()
	chest.chest_opened.connect(capture.on_chest_opened)
	chest.open(inv)
	_check(capture.emitted, "chest_opened signal emitted on first open()")
	chest.free()


func _test_open_signal_carries_correct_items() -> void:
	print("_test_open_signal_carries_correct_items")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "ruby", "name": "Ruby", "quantity": 2}])
	var capture := SignalCapture.new()
	chest.chest_opened.connect(capture.on_chest_opened)
	chest.open(inv)
	_check(capture.items.size() == 1, "signal carries one item")
	if capture.items.size() > 0:
		_check(capture.items[0].get("id") == "ruby", "signal item has correct id")
		_check(capture.items[0].get("quantity") == 2, "signal item has correct quantity")
	else:
		_check(false, "signal item has correct id")
		_check(false, "signal item has correct quantity")
	chest.free()


# ---------------------------------------------------------------------------
# set_loot
# ---------------------------------------------------------------------------
func _test_set_loot_replaces_existing_loot() -> void:
	print("_test_set_loot_replaces_existing_loot")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "old_item", "name": "Old", "quantity": 1}])
	chest.set_loot([{"id": "new_item", "name": "New", "quantity": 1}])
	chest.open(inv)
	_check(inv.has_item("new_item"), "set_loot replaces previous loot (new_item present)")
	_check(inv.has_item("old_item") == false, "old_item not present after set_loot replacement")
	chest.free()


func _test_set_loot_stores_copy() -> void:
	print("_test_set_loot_stores_copy")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	var original_loot: Array = [{"id": "gem", "name": "Gem", "quantity": 1}]
	chest.set_loot(original_loot)
	original_loot.clear()
	var result: Array = chest.open(inv)
	_check(result.size() == 1,
		"set_loot stores a copy; clearing original does not empty chest loot")
	chest.free()


# ---------------------------------------------------------------------------
# Empty chest
# ---------------------------------------------------------------------------
func _test_empty_chest_yields_no_items() -> void:
	print("_test_empty_chest_yields_no_items")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	var result: Array = chest.open(inv)
	_check(result.size() == 0, "empty chest yields no items")
	_check(inv.count() == 0, "inventory unchanged when chest is empty")
	chest.free()


# ---------------------------------------------------------------------------
# Multiple loot items
# ---------------------------------------------------------------------------
func _test_multiple_loot_items_all_added() -> void:
	print("_test_multiple_loot_items_all_added")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([
		{"id": "gold_coins", "name": "Gold Coins", "quantity": 10},
		{"id": "health_potion", "name": "Health Potion", "quantity": 1},
		{"id": "rope", "name": "Rope", "quantity": 1},
	])
	var result: Array = chest.open(inv)
	_check(result.size() == 3, "open() returns all three items")
	_check(inv.has_item("gold_coins"), "gold_coins added to inventory")
	_check(inv.has_item("health_potion"), "health_potion added to inventory")
	_check(inv.has_item("rope"), "rope added to inventory")
	chest.free()


# ---------------------------------------------------------------------------
# open() does not modify the internal loot array
# ---------------------------------------------------------------------------
func _test_open_does_not_modify_original_loot_array() -> void:
	print("_test_open_does_not_modify_original_loot_array")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "shield", "name": "Shield", "quantity": 1}])
	chest.open(inv)
	_check(chest.loot.size() == 1,
		"internal loot array is unchanged after open()")
	chest.free()


# ---------------------------------------------------------------------------
# required_flags gating
# ---------------------------------------------------------------------------
func _test_open_blocked_when_required_flags_not_met() -> void:
	print("_test_open_blocked_when_required_flags_not_met")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "gem", "name": "Gem", "quantity": 1}])
	chest.set_required_flags({"chest_key_found": true})
	var result: Array = chest.open(inv)
	_check(result.size() == 0, "open() returns empty when required_flags not met")
	_check(chest.is_opened == false, "chest remains closed when required_flags not met")
	_check(inv.has_item("gem") == false, "gem not added to inventory when blocked")
	chest.free()


func _test_open_allowed_when_required_flags_met() -> void:
	print("_test_open_allowed_when_required_flags_met")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "gem", "name": "Gem", "quantity": 1}])
	chest.set_required_flags({"chest_key_found": true})
	chest.set_quest_flags({"chest_key_found": true})
	var result: Array = chest.open(inv)
	_check(result.size() == 1, "open() returns items when required_flags are met")
	_check(chest.is_opened == true, "chest is opened when required_flags are satisfied")
	_check(inv.has_item("gem"), "gem added to inventory when flags satisfied")
	chest.free()


func _test_interaction_blocked_signal_emitted_when_flags_not_met() -> void:
	print("_test_interaction_blocked_signal_emitted_when_flags_not_met")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "coin", "name": "Coin", "quantity": 1}])
	chest.set_required_flags({"dungeon_cleared": true})
	var blocked_reasons: Array[String] = []
	chest.interaction_blocked.connect(func(reason: String) -> void:
		blocked_reasons.append(reason)
	)
	chest.open(inv)
	_check(blocked_reasons.size() == 1,
		"interaction_blocked emitted when required_flags not met")
	_check(blocked_reasons[0] == "missing_flag",
		"reason is missing_flag")
	chest.free()


func _test_set_quest_flags_updates_immediately() -> void:
	print("_test_set_quest_flags_updates_immediately")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "scroll", "name": "Scroll", "quantity": 1}])
	chest.set_required_flags({"library_unlocked": true})
	# First attempt blocked.
	var result_1: Array = chest.open(inv)
	_check(result_1.size() == 0, "chest blocked before set_quest_flags")
	# Set the flag — should immediately enable opening.
	chest.set_quest_flags({"library_unlocked": true})
	var result_2: Array = chest.open(inv)
	_check(result_2.size() == 1, "chest opens after set_quest_flags sets required flag")
	chest.free()


func _test_open_no_required_flags_always_allowed() -> void:
	print("_test_open_no_required_flags_always_allowed")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "potion", "name": "Potion", "quantity": 1}])
	var result: Array = chest.open(inv)
	_check(result.size() == 1,
		"chest with no required_flags is always openable")
	chest.free()


func _test_set_required_flags_stores_copy() -> void:
	print("_test_set_required_flags_stores_copy")
	var chest := ChestInteractableClass.new()
	var inv := InventoryClass.new()
	chest.set_loot([{"id": "diamond", "name": "Diamond", "quantity": 1}])
	var original_req := {"vault_open": true}
	chest.set_required_flags(original_req)
	# Mutate the original — should not affect the chest's stored copy.
	original_req.clear()
	# Now the stored required_flags should still block (vault_open not in quest flags).
	var blocked_count: int = 0
	chest.interaction_blocked.connect(func(_r: String) -> void:
		blocked_count += 1
	)
	chest.open(inv)
	_check(blocked_count == 1,
		"set_required_flags stores a copy; clearing original does not clear chest flags")
