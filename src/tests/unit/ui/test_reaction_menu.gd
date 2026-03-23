## test_reaction_menu.gd
## Unit tests for ReactionMenu (src/ui/reaction_menu.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_reaction_menu.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const ActionEconomyClass = preload("res://rules_engine/core/action_economy.gd")
const ReactionTriggerClass = preload("res://rules_engine/core/reaction_trigger.gd")
const ReactionMenuClass = preload("res://ui/reaction_menu.gd")

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


func _on_reaction_chosen(reaction_id: String) -> void:
	_last_signal_id = reaction_id
	_signal_count += 1


func _make_menu() -> ReactionMenuClass:
	var menu := ReactionMenuClass.new()
	menu.reaction_chosen.connect(_on_reaction_chosen)
	_last_signal_id = ""
	_signal_count = 0
	return menu


func _run_all_tests() -> void:
	_test_get_all_reactions_returns_empty_before_refresh()
	_test_get_all_reactions_being_hit_returns_shield()
	_test_get_all_reactions_creature_leaves_reach_returns_opportunity_attack()
	_test_get_available_reactions_no_economy()
	_test_get_available_reactions_before_start_turn()
	_test_get_available_reactions_reaction_available()
	_test_get_available_reactions_reaction_spent()
	_test_is_reaction_enabled_available()
	_test_is_reaction_enabled_spent()
	_test_select_reaction_no_economy()
	_test_select_reaction_wrong_trigger_type_reaction()
	_test_select_reaction_reaction_spent()
	_test_select_reaction_valid_emits_signal()
	_test_select_reaction_does_not_spend_slot()
	_test_refresh_replaces_economy()
	_test_both_reactions_selectable_for_their_trigger()


# ---------------------------------------------------------------------------
# get_all_reactions — before and after refresh
# ---------------------------------------------------------------------------
func _test_get_all_reactions_returns_empty_before_refresh() -> void:
	print("_test_get_all_reactions_returns_empty_before_refresh")
	var menu := _make_menu()
	_check(menu.get_all_reactions().size() == 0,
		"get_all_reactions returns empty array before refresh is called")
	menu.free()


func _test_get_all_reactions_being_hit_returns_shield() -> void:
	print("_test_get_all_reactions_being_hit_returns_shield")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	var all := menu.get_all_reactions()
	_check(all.size() == 1, "get_all_reactions returns one entry for BEING_HIT")
	_check(all.has("shield"), "get_all_reactions includes 'shield' for BEING_HIT")
	menu.free()


func _test_get_all_reactions_creature_leaves_reach_returns_opportunity_attack() -> void:
	print("_test_get_all_reactions_creature_leaves_reach_returns_opportunity_attack")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH)
	var all := menu.get_all_reactions()
	_check(all.size() == 1, "get_all_reactions returns one entry for CREATURE_LEAVES_REACH")
	_check(all.has("opportunity_attack"),
		"get_all_reactions includes 'opportunity_attack' for CREATURE_LEAVES_REACH")
	menu.free()


# ---------------------------------------------------------------------------
# get_available_reactions
# ---------------------------------------------------------------------------
func _test_get_available_reactions_no_economy() -> void:
	print("_test_get_available_reactions_no_economy")
	var menu := _make_menu()
	_check(menu.get_available_reactions().size() == 0,
		"no available reactions without economy")
	menu.free()


func _test_get_available_reactions_before_start_turn() -> void:
	print("_test_get_available_reactions_before_start_turn")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	# Do not call start_turn() — reaction slot starts as spent
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.get_available_reactions().size() == 0,
		"no available reactions before start_turn")
	menu.free()


func _test_get_available_reactions_reaction_available() -> void:
	print("_test_get_available_reactions_reaction_available")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.get_available_reactions().size() == 1,
		"one reaction available when slot is free and trigger is BEING_HIT")
	menu.free()


func _test_get_available_reactions_reaction_spent() -> void:
	print("_test_get_available_reactions_reaction_spent")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	economy.use_reaction()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.get_available_reactions().size() == 0,
		"no available reactions when reaction slot is spent")
	menu.free()


# ---------------------------------------------------------------------------
# is_reaction_enabled
# ---------------------------------------------------------------------------
func _test_is_reaction_enabled_available() -> void:
	print("_test_is_reaction_enabled_available")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.is_reaction_enabled("shield") == true,
		"'shield' is enabled when BEING_HIT and reaction available")
	menu.free()


func _test_is_reaction_enabled_spent() -> void:
	print("_test_is_reaction_enabled_spent")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	economy.use_reaction()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.is_reaction_enabled("shield") == false,
		"'shield' is disabled when reaction slot is spent")
	menu.free()


# ---------------------------------------------------------------------------
# select_reaction — guard conditions
# ---------------------------------------------------------------------------
func _test_select_reaction_no_economy() -> void:
	print("_test_select_reaction_no_economy")
	var menu := _make_menu()
	_check(menu.select_reaction("shield") == false,
		"select_reaction returns false with no economy")
	_check(_signal_count == 0, "no signal emitted with no economy")
	menu.free()


func _test_select_reaction_wrong_trigger_type_reaction() -> void:
	print("_test_select_reaction_wrong_trigger_type_reaction")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	# BEING_HIT menu — try to select an opportunity_attack (only valid for CREATURE_LEAVES_REACH)
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.select_reaction("opportunity_attack") == false,
		"opportunity_attack blocked on BEING_HIT trigger menu")
	_check(_signal_count == 0, "no signal emitted for wrong-trigger reaction")
	menu.free()


func _test_select_reaction_reaction_spent() -> void:
	print("_test_select_reaction_reaction_spent")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	economy.use_reaction()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.select_reaction("shield") == false,
		"select_reaction returns false when reaction slot is spent")
	_check(_signal_count == 0, "no signal emitted when reaction slot is spent")
	menu.free()


# ---------------------------------------------------------------------------
# select_reaction — success path
# ---------------------------------------------------------------------------
func _test_select_reaction_valid_emits_signal() -> void:
	print("_test_select_reaction_valid_emits_signal")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	var result := menu.select_reaction("shield")
	_check(result == true, "select_reaction returns true for valid selection")
	_check(_signal_count == 1, "reaction_chosen signal fired once")
	_check(_last_signal_id == "shield", "reaction_chosen carries correct reaction_id 'shield'")
	menu.free()


func _test_select_reaction_does_not_spend_slot() -> void:
	print("_test_select_reaction_does_not_spend_slot")
	var menu := _make_menu()
	var economy := ActionEconomyClass.new(30)
	economy.start_turn()
	menu.refresh(economy, ReactionTriggerClass.TriggerType.BEING_HIT)
	menu.select_reaction("shield")
	_check(economy.is_reaction_available() == true,
		"reaction slot is NOT spent by select_reaction (runtime must call use_reaction)")
	menu.free()


# ---------------------------------------------------------------------------
# refresh replaces economy and trigger type
# ---------------------------------------------------------------------------
func _test_refresh_replaces_economy() -> void:
	print("_test_refresh_replaces_economy")
	var menu := _make_menu()

	var spent := ActionEconomyClass.new(30)
	spent.start_turn()
	spent.use_reaction()
	menu.refresh(spent, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.get_available_reactions().size() == 0,
		"no reactions available on spent economy")
	_check(menu.select_reaction("shield") == false,
		"select_reaction blocked on spent economy")

	var fresh := ActionEconomyClass.new(30)
	fresh.start_turn()
	menu.refresh(fresh, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu.get_available_reactions().size() == 1,
		"reaction available after refresh with fresh economy")
	_check(menu.select_reaction("shield") == true,
		"select_reaction succeeds after refresh with fresh economy")
	menu.free()


# ---------------------------------------------------------------------------
# Both reactions are selectable for their own trigger type
# ---------------------------------------------------------------------------
func _test_both_reactions_selectable_for_their_trigger() -> void:
	print("_test_both_reactions_selectable_for_their_trigger")
	# BEING_HIT → shield
	var menu1 := _make_menu()
	var eco1 := ActionEconomyClass.new(30)
	eco1.start_turn()
	menu1.refresh(eco1, ReactionTriggerClass.TriggerType.BEING_HIT)
	_check(menu1.select_reaction("shield") == true, "shield selectable for BEING_HIT trigger")
	menu1.free()

	# CREATURE_LEAVES_REACH → opportunity_attack
	var menu2 := _make_menu()
	var eco2 := ActionEconomyClass.new(30)
	eco2.start_turn()
	menu2.refresh(eco2, ReactionTriggerClass.TriggerType.CREATURE_LEAVES_REACH)
	_check(menu2.select_reaction("opportunity_attack") == true,
		"opportunity_attack selectable for CREATURE_LEAVES_REACH trigger")
	menu2.free()
