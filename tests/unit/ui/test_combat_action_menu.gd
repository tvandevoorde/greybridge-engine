## test_combat_action_menu.gd
## Unit tests for CombatActionMenu (src/ui/combat_action_menu.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ../tests/unit/ui/test_combat_action_menu.gd
extends SceneTree

const ActionEconomy = preload("res://rules_engine/core/action_economy.gd")
const CombatAction = preload("res://rules_engine/core/combat_action.gd")
const CombatActionMenu = preload("res://ui/combat_action_menu.gd")

var _pass_count: int = 0
var _fail_count: int = 0
var _last_signal_id: String = ""
var _signal_count: int = 0


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


func _on_action_selected(action_id: String) -> void:
	_last_signal_id = action_id
	_signal_count += 1


func _make_menu() -> CombatActionMenu:
	var menu := CombatActionMenu.new()
	menu.action_selected.connect(_on_action_selected)
	_last_signal_id = ""
	_signal_count = 0
	return menu


func _run_all_tests() -> void:
	_test_get_all_actions_returns_five()
	_test_get_available_actions_no_economy()
	_test_get_available_actions_before_start_turn()
	_test_get_available_actions_slot_free()
	_test_get_available_actions_slot_spent()
	_test_is_action_enabled_slot_free()
	_test_is_action_enabled_slot_spent()
	_test_select_action_no_economy()
	_test_select_action_invalid_id()
	_test_select_action_slot_spent()
	_test_select_action_valid_emits_signal()
	_test_select_action_emits_correct_id()
	_test_select_action_does_not_spend_slot()
	_test_refresh_replaces_economy()
	_test_all_five_actions_selectable()


# ---------------------------------------------------------------------------
# get_all_actions always returns every renderable action regardless of state
# ---------------------------------------------------------------------------
func _test_get_all_actions_returns_five() -> void:
	print("_test_get_all_actions_returns_five")
	var menu := _make_menu()
	var all: Array[String] = menu.get_all_actions()
	_check(all.size() == 5, "get_all_actions returns 5 entries")
	_check(all.has("attack"),     "get_all_actions includes attack")
	_check(all.has("cast_spell"), "get_all_actions includes cast_spell")
	_check(all.has("dash"),       "get_all_actions includes dash")
	_check(all.has("disengage"),  "get_all_actions includes disengage")
	_check(all.has("dodge"),      "get_all_actions includes dodge")


# ---------------------------------------------------------------------------
# get_available_actions returns empty array when no economy is set
# ---------------------------------------------------------------------------
func _test_get_available_actions_no_economy() -> void:
	print("_test_get_available_actions_no_economy")
	var menu := _make_menu()
	_check(menu.get_available_actions().size() == 0, "no available actions without economy")


# ---------------------------------------------------------------------------
# get_available_actions returns empty array before start_turn
# ---------------------------------------------------------------------------
func _test_get_available_actions_before_start_turn() -> void:
	print("_test_get_available_actions_before_start_turn")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	menu.refresh(economy)
	_check(menu.get_available_actions().size() == 0, "no available actions before start_turn")


# ---------------------------------------------------------------------------
# get_available_actions returns all five when Action slot is free
# ---------------------------------------------------------------------------
func _test_get_available_actions_slot_free() -> void:
	print("_test_get_available_actions_slot_free")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	menu.refresh(economy)
	_check(menu.get_available_actions().size() == 5, "all 5 available when slot free")


# ---------------------------------------------------------------------------
# get_available_actions returns empty array once Action slot is spent
# ---------------------------------------------------------------------------
func _test_get_available_actions_slot_spent() -> void:
	print("_test_get_available_actions_slot_spent")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	economy.use_action()
	menu.refresh(economy)
	_check(menu.get_available_actions().size() == 0, "no available actions when slot spent")


# ---------------------------------------------------------------------------
# is_action_enabled returns true for each action when slot is free
# ---------------------------------------------------------------------------
func _test_is_action_enabled_slot_free() -> void:
	print("_test_is_action_enabled_slot_free")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	menu.refresh(economy)
	_check(menu.is_action_enabled("attack"),     "attack enabled when slot free")
	_check(menu.is_action_enabled("cast_spell"), "cast_spell enabled when slot free")
	_check(menu.is_action_enabled("dash"),       "dash enabled when slot free")
	_check(menu.is_action_enabled("disengage"),  "disengage enabled when slot free")
	_check(menu.is_action_enabled("dodge"),      "dodge enabled when slot free")


# ---------------------------------------------------------------------------
# is_action_enabled returns false for all actions when slot is spent
# ---------------------------------------------------------------------------
func _test_is_action_enabled_slot_spent() -> void:
	print("_test_is_action_enabled_slot_spent")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	economy.use_action()
	menu.refresh(economy)
	_check(menu.is_action_enabled("attack") == false,     "attack disabled when slot spent")
	_check(menu.is_action_enabled("cast_spell") == false, "cast_spell disabled when slot spent")
	_check(menu.is_action_enabled("dash") == false,       "dash disabled when slot spent")
	_check(menu.is_action_enabled("disengage") == false,  "disengage disabled when slot spent")
	_check(menu.is_action_enabled("dodge") == false,      "dodge disabled when slot spent")


# ---------------------------------------------------------------------------
# select_action returns false when no economy has been set (prevents crash)
# ---------------------------------------------------------------------------
func _test_select_action_no_economy() -> void:
	print("_test_select_action_no_economy")
	var menu := _make_menu()
	_check(menu.select_action("attack") == false, "select_action returns false with no economy")
	_check(_signal_count == 0, "no signal emitted with no economy")


# ---------------------------------------------------------------------------
# select_action returns false for unrecognised action IDs
# ---------------------------------------------------------------------------
func _test_select_action_invalid_id() -> void:
	print("_test_select_action_invalid_id")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	menu.refresh(economy)
	_check(menu.select_action("fireball") == false, "unknown id 'fireball' returns false")
	_check(menu.select_action("") == false,         "empty id returns false")
	_check(menu.select_action("ATTACK") == false,   "uppercase 'ATTACK' returns false")
	_check(_signal_count == 0, "no signal emitted for invalid ids")


# ---------------------------------------------------------------------------
# select_action returns false when Action slot is already spent
# ---------------------------------------------------------------------------
func _test_select_action_slot_spent() -> void:
	print("_test_select_action_slot_spent")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	economy.use_action()
	menu.refresh(economy)
	_check(menu.select_action("attack") == false, "select_action returns false when slot spent")
	_check(_signal_count == 0, "no signal emitted when slot spent")


# ---------------------------------------------------------------------------
# select_action emits action_selected on a valid, available selection
# ---------------------------------------------------------------------------
func _test_select_action_valid_emits_signal() -> void:
	print("_test_select_action_valid_emits_signal")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	menu.refresh(economy)
	var result: bool = menu.select_action("attack")
	_check(result == true, "select_action returns true for valid selection")
	_check(_signal_count == 1, "action_selected signal fired once")


# ---------------------------------------------------------------------------
# signal carries the correct action ID
# ---------------------------------------------------------------------------
func _test_select_action_emits_correct_id() -> void:
	print("_test_select_action_emits_correct_id")
	for action_id: String in CombatAction.ACTION_SLOT_ACTIONS:
		var menu := _make_menu()
		var economy := ActionEconomy.new(30)
		economy.start_turn()
		menu.refresh(economy)
		menu.select_action(action_id)
		_check(_last_signal_id == action_id, "signal id matches '%s'" % action_id)


# ---------------------------------------------------------------------------
# select_action does NOT call use_action() — that is the runtime's job
# ---------------------------------------------------------------------------
func _test_select_action_does_not_spend_slot() -> void:
	print("_test_select_action_does_not_spend_slot")
	var menu := _make_menu()
	var economy := ActionEconomy.new(30)
	economy.start_turn()
	menu.refresh(economy)
	menu.select_action("attack")
	_check(economy.is_action_available() == true,
		"Action slot remains unspent after select_action (runtime must call use_action)")


# ---------------------------------------------------------------------------
# refresh replaces the economy snapshot; old state is no longer used
# ---------------------------------------------------------------------------
func _test_refresh_replaces_economy() -> void:
	print("_test_refresh_replaces_economy")
	var menu := _make_menu()

	var spent := ActionEconomy.new(30)
	spent.start_turn()
	spent.use_action()
	menu.refresh(spent)
	_check(menu.get_available_actions().size() == 0, "no actions available on spent economy")
	_check(menu.select_action("attack") == false, "select_action blocked on spent economy")

	var fresh := ActionEconomy.new(30)
	fresh.start_turn()
	menu.refresh(fresh)
	_check(menu.get_available_actions().size() == 5, "all actions available after refresh with fresh economy")
	_check(menu.select_action("dodge") == true, "select_action succeeds after refresh with fresh economy")


# ---------------------------------------------------------------------------
# Each of the five actions can be individually selected when the slot is free
# ---------------------------------------------------------------------------
func _test_all_five_actions_selectable() -> void:
	print("_test_all_five_actions_selectable")
	for action_id: String in CombatAction.ACTION_SLOT_ACTIONS:
		var menu := _make_menu()
		var economy := ActionEconomy.new(30)
		economy.start_turn()
		menu.refresh(economy)
		_check(menu.select_action(action_id) == true, "can select '%s' when slot free" % action_id)
