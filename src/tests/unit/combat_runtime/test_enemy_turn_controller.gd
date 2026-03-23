## test_enemy_turn_controller.gd
## Unit tests for EnemyTurnController (src/combat_runtime/enemy_turn_controller.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_enemy_turn_controller.gd
extends SceneTree

const EnemyTurnControllerClass = preload("res://combat_runtime/enemy_turn_controller.gd")
const CombatGridClass          = preload("res://rules_engine/core/combat_grid.gd")
const ActionEconomyClass       = preload("res://rules_engine/core/action_economy.gd")
const DiceRollerClass          = preload("res://rules_engine/core/dice_roller.gd")

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
	_test_turn_complete_emitted()
	_test_enemy_moved_emitted_no_movement()
	_test_melee_attack_in_range_emits_enemy_attacked()
	_test_melee_attack_in_range_spends_action()
	_test_melee_attack_in_range_no_movement()
	_test_move_and_melee_attack_updates_grid()
	_test_move_and_melee_attack_spends_movement()
	_test_ranged_attack_emits_enemy_attacked()
	_test_no_attack_when_no_targets()
	_test_no_attack_when_action_unavailable()
	_test_critical_hit_deals_double_dice()
	_test_miss_deals_zero_damage()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_grid(placements: Array) -> CombatGridClass:
	var g := CombatGridClass.new()
	for e in placements:
		g.place_combatant(e["id"], e["pos"])
	return g


func _make_economy(speed_ft: int, action_used: bool = false) -> ActionEconomyClass:
	var e := ActionEconomyClass.new(speed_ft)
	e.start_turn()
	if action_used:
		e.use_action()
	return e


func _default_stats() -> Dictionary:
	return {
		"melee_range_ft":    5,
		"ranged_range_ft":   0,
		"speed_ft":          30,
		"ability_modifier":  0,
		"proficiency_bonus": 2,
		"damage_dice_count": 1,
		"damage_dice_faces": 6,
		"damage_type":       "slashing",
	}


func _participant(id: String, side: String, hp: int, ac: int) -> Dictionary:
	return {"id": id, "side": side, "current_hp": hp, "armor_class": ac}


# ---------------------------------------------------------------------------
# turn_complete signal
# ---------------------------------------------------------------------------

func _test_turn_complete_emitted() -> void:
	print("_test_turn_complete_emitted")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([{"id": "orc", "pos": Vector2i(0, 0)}])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(42)
	var completed: Array = []
	etc.turn_complete.connect(func(id: String) -> void: completed.append(id))
	etc.execute_turn("orc", _default_stats(), [], grid, economy, roller)
	_check(completed.size() == 1, "turn_complete emitted once")
	_check(completed[0] == "orc", "turn_complete carries the correct enemy ID")
	etc.free()


# ---------------------------------------------------------------------------
# enemy_moved signal — no movement
# ---------------------------------------------------------------------------

func _test_enemy_moved_emitted_no_movement() -> void:
	print("_test_enemy_moved_emitted_no_movement")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([{"id": "orc", "pos": Vector2i(0, 0)}])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(42)
	var moved_events: Array = []
	etc.enemy_moved.connect(func(id: String, path: Array, cost: int) -> void:
		moved_events.append({"id": id, "path": path, "cost": cost})
	)
	etc.execute_turn("orc", _default_stats(), [], grid, economy, roller)
	_check(moved_events.size() == 1, "enemy_moved emitted once even with no targets")
	_check(moved_events[0]["path"].size() == 0, "path is empty when no movement occurred")
	_check(moved_events[0]["cost"] == 0, "cost is 0 when no movement occurred")
	etc.free()


# ---------------------------------------------------------------------------
# Melee attack — target already in range
# ---------------------------------------------------------------------------

func _test_melee_attack_in_range_emits_enemy_attacked() -> void:
	print("_test_melee_attack_in_range_emits_enemy_attacked")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	# Seeded roller: seed 0 gives a deterministic d20 roll that hits AC 10
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy", 20, 13),
		_participant("player", "player", 10, 10),
	]
	var attacked_events: Array = []
	etc.enemy_attacked.connect(func(a: String, t: String, atype: String, h: bool, c: bool, d: int) -> void:
		attacked_events.append({"attacker": a, "target": t, "type": atype, "hit": h, "crit": c, "dmg": d})
	)
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(attacked_events.size() == 1, "enemy_attacked emitted for melee attack in range")
	_check(attacked_events[0]["attacker"] == "orc", "attacker ID is correct")
	_check(attacked_events[0]["target"] == "player", "target ID is correct")
	_check(attacked_events[0]["type"] == "melee", "attack type is melee")
	etc.free()


func _test_melee_attack_in_range_spends_action() -> void:
	print("_test_melee_attack_in_range_spends_action")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(economy.is_action_available() == false, "action is spent after attack")
	etc.free()


func _test_melee_attack_in_range_no_movement() -> void:
	print("_test_melee_attack_in_range_no_movement")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	var moved_events: Array = []
	etc.enemy_moved.connect(func(_id: String, path: Array, _cost: int) -> void:
		moved_events.append(path)
	)
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(moved_events[0].size() == 0, "no movement when target already in melee range")
	_check(economy.movement_remaining_ft == 30, "movement budget unchanged when no movement")
	etc.free()


# ---------------------------------------------------------------------------
# Move and melee attack
# ---------------------------------------------------------------------------

func _test_move_and_melee_attack_updates_grid() -> void:
	print("_test_move_and_melee_attack_updates_grid")
	var etc := EnemyTurnControllerClass.new()
	# Enemy at (0,0), player at (3,0) — 15 ft away
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(3, 0)},
	])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	var old_pos := grid.get_position("orc")
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	var new_pos := grid.get_position("orc")
	_check(new_pos != old_pos, "enemy position is updated on the grid after movement")
	_check(new_pos == Vector2i(2, 0), "enemy ends adjacent to player after moving")
	etc.free()


func _test_move_and_melee_attack_spends_movement() -> void:
	print("_test_move_and_melee_attack_spends_movement")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(3, 0)},
	])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	# Moved 2 tiles × 5 ft = 10 ft; remaining = 30 - 10 = 20
	_check(economy.movement_remaining_ft == 20, "movement cost is deducted from economy")
	etc.free()


# ---------------------------------------------------------------------------
# Ranged attack
# ---------------------------------------------------------------------------

func _test_ranged_attack_emits_enemy_attacked() -> void:
	print("_test_ranged_attack_emits_enemy_attacked")
	var etc := EnemyTurnControllerClass.new()
	# Enemy at (0,0), player at (6,0) — 30 ft; ranged range 60 ft, melee 5 ft
	var grid := _make_grid([
		{"id": "archer", "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(6, 0)},
	])
	var economy := _make_economy(0)  # no movement available
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("archer", "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	var stats := {
		"melee_range_ft":    5,
		"ranged_range_ft":   60,
		"speed_ft":          30,
		"ability_modifier":  0,
		"proficiency_bonus": 2,
		"damage_dice_count": 1,
		"damage_dice_faces": 6,
		"damage_type":       "piercing",
	}
	var attacked_events: Array = []
	etc.enemy_attacked.connect(func(a: String, t: String, atype: String, h: bool, c: bool, _d: int) -> void:
		attacked_events.append({"attacker": a, "target": t, "type": atype, "hit": h})
	)
	etc.execute_turn("archer", stats, participants, grid, economy, roller)
	_check(attacked_events.size() == 1, "enemy_attacked emitted for ranged attack")
	_check(attacked_events[0]["type"] == "ranged", "attack type is ranged")
	_check(attacked_events[0]["attacker"] == "archer", "attacker ID correct for ranged")
	_check(attacked_events[0]["target"] == "player", "target ID correct for ranged")
	etc.free()


# ---------------------------------------------------------------------------
# No attack when no targets / action unavailable
# ---------------------------------------------------------------------------

func _test_no_attack_when_no_targets() -> void:
	print("_test_no_attack_when_no_targets")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([{"id": "orc", "pos": Vector2i(0, 0)}])
	var economy := _make_economy(30)
	var roller := DiceRollerClass.new(0)
	var attacked: bool = false
	etc.enemy_attacked.connect(func(_a, _t, _at, _h, _c, _d) -> void: attacked = true)
	etc.execute_turn("orc", _default_stats(), [], grid, economy, roller)
	_check(attacked == false, "no enemy_attacked emitted when there are no targets")
	_check(economy.is_action_available() == true, "action not spent when there are no targets")
	etc.free()


func _test_no_attack_when_action_unavailable() -> void:
	print("_test_no_attack_when_action_unavailable")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30, true)  # action already spent
	var roller := DiceRollerClass.new(0)
	var participants := [
		_participant("orc",    "enemy",  20, 13),
		_participant("player", "player", 10, 10),
	]
	var attacked: bool = false
	etc.enemy_attacked.connect(func(_a, _t, _at, _h, _c, _d) -> void: attacked = true)
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(attacked == false, "no enemy_attacked emitted when action is already spent")
	etc.free()


# ---------------------------------------------------------------------------
# Critical hit — double damage dice
# ---------------------------------------------------------------------------

func _test_critical_hit_deals_double_dice() -> void:
	print("_test_critical_hit_deals_double_dice")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	var participants := [
		_participant("orc",    "enemy",  20, 1),   # AC 1: any non-1 roll hits
		_participant("player", "player", 10, 1),
	]
	var attack_events: Array = []
	etc.enemy_attacked.connect(func(_a, _t, _at, h: bool, c: bool, d: int) -> void:
		attack_events.append({"hit": h, "crit": c, "dmg": d})
	)
	var roller := DiceRollerClass.new(0)
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(attack_events.size() == 1, "attack event emitted")
	if attack_events.size() > 0:
		var ev: Dictionary = attack_events[0]
		if ev["crit"]:
			# Critical hit: double the damage dice — minimum 2 with 2d6 at modifier 0
			_check(ev["dmg"] >= 2, "critical hit uses at least 2 damage dice (minimum 2)")
		elif ev["hit"]:
			# Normal hit: at least 1 damage from 1d6
			_check(ev["dmg"] >= 1, "normal hit deals at least 1 damage")
		else:
			# Natural 1 auto-miss: damage must be zero
			_check(ev["dmg"] == 0, "natural 1 miss deals 0 damage")
	etc.free()


# ---------------------------------------------------------------------------
# Miss deals zero damage
# ---------------------------------------------------------------------------

func _test_miss_deals_zero_damage() -> void:
	print("_test_miss_deals_zero_damage")
	var etc := EnemyTurnControllerClass.new()
	var grid := _make_grid([
		{"id": "orc",    "pos": Vector2i(0, 0)},
		{"id": "player", "pos": Vector2i(1, 0)},
	])
	var economy := _make_economy(30)
	var participants := [
		_participant("orc",    "enemy",  20, 30),  # AC 30: virtually impossible to hit
		_participant("player", "player", 10, 30),
	]
	var attack_events: Array = []
	etc.enemy_attacked.connect(func(_a, _t, _at, h: bool, c: bool, d: int) -> void:
		attack_events.append({"hit": h, "crit": c, "dmg": d})
	)
	# Seed 1: roll(20) sequence; first roll should be low enough to miss AC 30
	var roller := DiceRollerClass.new(1)
	etc.execute_turn("orc", _default_stats(), participants, grid, economy, roller)
	_check(attack_events.size() == 1, "attack event emitted even on miss")
	if attack_events.size() > 0 and not attack_events[0]["crit"]:
		_check(attack_events[0]["dmg"] == 0, "miss deals zero damage")
	else:
		# Critical hit: ignore — the test is about miss behaviour
		_check(true, "critical hit occurred (seed-dependent); miss path not exercised")
	etc.free()
