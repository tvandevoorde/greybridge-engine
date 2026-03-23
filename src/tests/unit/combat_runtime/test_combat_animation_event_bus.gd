## test_combat_animation_event_bus.gd
## Unit tests for CombatAnimationEventBus
## (src/combat_runtime/combat_animation_event_bus.gd).
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/combat_runtime/test_combat_animation_event_bus.gd
##
## Exit code 0 = all assertions passed; 1 = one or more assertions failed.
extends SceneTree

const CombatAnimationEventBusClass = preload("res://combat_runtime/combat_animation_event_bus.gd")

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
	_test_notify_attack_resolved_hit_critical()
	_test_notify_attack_resolved_miss_not_critical()
	_test_notify_damage_applied()
	_test_notify_actor_died()
	_test_notify_move_started()
	_test_notify_condition_changed_gained()
	_test_notify_condition_changed_removed()
	_test_notify_spell_cast()
	_test_multiple_subscribers_all_notified()


# ---------------------------------------------------------------------------
# notify_attack_resolved emits attack_resolved with hit=true, critical=true
# ---------------------------------------------------------------------------
func _test_notify_attack_resolved_hit_critical() -> void:
	print("_test_notify_attack_resolved_hit_critical")
	var bus := CombatAnimationEventBusClass.new()

	var attacker_ids: Array[String] = []
	var target_ids: Array[String] = []
	var hit_flags: Array[bool] = []
	var critical_flags: Array[bool] = []
	bus.attack_resolved.connect(
		func(a: String, t: String, h: bool, c: bool) -> void:
			attacker_ids.append(a)
			target_ids.append(t)
			hit_flags.append(h)
			critical_flags.append(c)
	)

	bus.notify_attack_resolved("fighter", "goblin", true, true)

	_check(attacker_ids.size() == 1, "attack_resolved emitted once")
	_check(attacker_ids[0] == "fighter", "attacker_id == 'fighter'")
	_check(target_ids[0] == "goblin", "target_id == 'goblin'")
	_check(hit_flags[0] == true, "hit == true")
	_check(critical_flags[0] == true, "critical == true")

	bus.free()


# ---------------------------------------------------------------------------
# notify_attack_resolved emits attack_resolved with hit=false, critical=false
# ---------------------------------------------------------------------------
func _test_notify_attack_resolved_miss_not_critical() -> void:
	print("_test_notify_attack_resolved_miss_not_critical")
	var bus := CombatAnimationEventBusClass.new()

	var hit_flags: Array[bool] = []
	var critical_flags: Array[bool] = []
	bus.attack_resolved.connect(
		func(_a: String, _t: String, h: bool, c: bool) -> void:
			hit_flags.append(h)
			critical_flags.append(c)
	)

	bus.notify_attack_resolved("bandit", "hero", false, false)

	_check(hit_flags.size() == 1, "attack_resolved emitted once for miss")
	_check(hit_flags[0] == false, "hit == false on miss")
	_check(critical_flags[0] == false, "critical == false on miss")

	bus.free()


# ---------------------------------------------------------------------------
# notify_damage_applied emits damage_applied with correct arguments
# ---------------------------------------------------------------------------
func _test_notify_damage_applied() -> void:
	print("_test_notify_damage_applied")
	var bus := CombatAnimationEventBusClass.new()

	var target_ids: Array[String] = []
	var amounts: Array[int] = []
	var damage_types: Array[String] = []
	bus.damage_applied.connect(
		func(t: String, a: int, d: String) -> void:
			target_ids.append(t)
			amounts.append(a)
			damage_types.append(d)
	)

	bus.notify_damage_applied("goblin", 8, "slashing")

	_check(target_ids.size() == 1, "damage_applied emitted once")
	_check(target_ids[0] == "goblin", "target_id == 'goblin'")
	_check(amounts[0] == 8, "amount == 8")
	_check(damage_types[0] == "slashing", "damage_type == 'slashing'")

	bus.free()


# ---------------------------------------------------------------------------
# notify_actor_died emits actor_died with the correct actor id
# ---------------------------------------------------------------------------
func _test_notify_actor_died() -> void:
	print("_test_notify_actor_died")
	var bus := CombatAnimationEventBusClass.new()

	var dead_ids: Array[String] = []
	bus.actor_died.connect(func(id: String) -> void: dead_ids.append(id))

	bus.notify_actor_died("goblin")

	_check(dead_ids.size() == 1, "actor_died emitted once")
	_check(dead_ids[0] == "goblin", "actor_id == 'goblin'")

	bus.free()


# ---------------------------------------------------------------------------
# notify_move_started emits move_started with actor id and tile positions
# ---------------------------------------------------------------------------
func _test_notify_move_started() -> void:
	print("_test_notify_move_started")
	var bus := CombatAnimationEventBusClass.new()

	var actor_ids: Array[String] = []
	var from_positions: Array[Vector2i] = []
	var to_positions: Array[Vector2i] = []
	bus.move_started.connect(
		func(a: String, f: Vector2i, t: Vector2i) -> void:
			actor_ids.append(a)
			from_positions.append(f)
			to_positions.append(t)
	)

	bus.notify_move_started("hero", Vector2i(2, 3), Vector2i(3, 3))

	_check(actor_ids.size() == 1, "move_started emitted once")
	_check(actor_ids[0] == "hero", "actor_id == 'hero'")
	_check(from_positions[0] == Vector2i(2, 3), "from_pos == (2, 3)")
	_check(to_positions[0] == Vector2i(3, 3), "to_pos == (3, 3)")

	bus.free()


# ---------------------------------------------------------------------------
# notify_condition_changed emits condition_changed with gained=true
# ---------------------------------------------------------------------------
func _test_notify_condition_changed_gained() -> void:
	print("_test_notify_condition_changed_gained")
	var bus := CombatAnimationEventBusClass.new()

	var actor_ids: Array[String] = []
	var condition_ids: Array[String] = []
	var gained_flags: Array[bool] = []
	bus.condition_changed.connect(
		func(a: String, c: String, g: bool) -> void:
			actor_ids.append(a)
			condition_ids.append(c)
			gained_flags.append(g)
	)

	bus.notify_condition_changed("wizard", "poisoned", true)

	_check(actor_ids.size() == 1, "condition_changed emitted once")
	_check(actor_ids[0] == "wizard", "actor_id == 'wizard'")
	_check(condition_ids[0] == "poisoned", "condition_id == 'poisoned'")
	_check(gained_flags[0] == true, "gained == true")

	bus.free()


# ---------------------------------------------------------------------------
# notify_condition_changed emits condition_changed with gained=false
# ---------------------------------------------------------------------------
func _test_notify_condition_changed_removed() -> void:
	print("_test_notify_condition_changed_removed")
	var bus := CombatAnimationEventBusClass.new()

	var gained_flags: Array[bool] = []
	bus.condition_changed.connect(
		func(_a: String, _c: String, g: bool) -> void: gained_flags.append(g)
	)

	bus.notify_condition_changed("wizard", "poisoned", false)

	_check(gained_flags.size() == 1, "condition_changed emitted once for removal")
	_check(gained_flags[0] == false, "gained == false on removal")

	bus.free()


# ---------------------------------------------------------------------------
# notify_spell_cast emits spell_cast with caster, spell id, and target tiles
# ---------------------------------------------------------------------------
func _test_notify_spell_cast() -> void:
	print("_test_notify_spell_cast")
	var bus := CombatAnimationEventBusClass.new()

	var caster_ids: Array[String] = []
	var spell_ids: Array[String] = []
	var target_arrays: Array = []
	bus.spell_cast.connect(
		func(c: String, s: String, t: Array) -> void:
			caster_ids.append(c)
			spell_ids.append(s)
			target_arrays.append(t)
	)

	var targets: Array = [Vector2i(4, 4), Vector2i(5, 4)]
	bus.notify_spell_cast("wizard", "fireball", targets)

	_check(caster_ids.size() == 1, "spell_cast emitted once")
	_check(caster_ids[0] == "wizard", "caster_id == 'wizard'")
	_check(spell_ids[0] == "fireball", "spell_id == 'fireball'")
	_check(target_arrays[0].size() == 2, "target_positions has 2 tiles")
	_check(target_arrays[0][0] == Vector2i(4, 4), "first target == (4, 4)")

	bus.free()


# ---------------------------------------------------------------------------
# Multiple independent subscribers all receive the same emitted signal
# ---------------------------------------------------------------------------
func _test_multiple_subscribers_all_notified() -> void:
	print("_test_multiple_subscribers_all_notified")
	var bus := CombatAnimationEventBusClass.new()

	var received_a: Array[String] = []
	var received_b: Array[String] = []

	bus.actor_died.connect(func(id: String) -> void: received_a.append(id))
	bus.actor_died.connect(func(id: String) -> void: received_b.append(id))

	bus.notify_actor_died("bandit")

	_check(received_a.size() == 1, "first subscriber received actor_died")
	_check(received_b.size() == 1, "second subscriber received actor_died")
	_check(received_a[0] == "bandit", "first subscriber got 'bandit'")
	_check(received_b[0] == "bandit", "second subscriber got 'bandit'")

	bus.free()
