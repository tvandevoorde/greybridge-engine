## test_combat_log.gd
## Unit tests for CombatLog (src/ui/combat_log.gd).
##
## Acceptance criteria from the "Implement structured combat log" issue:
##   - Displays attacks, damage, saves, conditions
##   - Shows critical hits
##   - Shows concentration breaks
##   - Log driven by structured result objects
##   - No logic inside log system
##
## Run headlessly from the Godot project root (src/) with:
##   godot --headless --script ./tests/unit/ui/test_combat_log.gd
extends SceneTree

const CombatLogClass      = preload("res://ui/combat_log.gd")
const CombatLogEntryClass = preload("res://rules_engine/core/combat_log_entry.gd")
const AttackResultClass   = preload("res://rules_engine/core/attack_result.gd")
const SaveResultClass     = preload("res://rules_engine/core/save_result.gd")

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


func _make_log() -> CombatLogClass:
	return CombatLogClass.new()


# ---------------------------------------------------------------------------
# Helpers to build entries
# ---------------------------------------------------------------------------

func _make_attack_entry(
	actor: String,
	target: String,
	hit: bool,
	critical: bool,
	roll: int,
	total: int,
	damage: int
) -> CombatLogEntryClass:
	var r := AttackResultClass.new()
	r.hit      = hit
	r.critical = critical
	r.roll     = roll
	r.total    = total
	r.damage   = damage
	var e := CombatLogEntryClass.new()
	e.event_type    = "attack"
	e.actor_name    = actor
	e.target_name   = target
	e.attack_result = r
	return e


func _make_save_entry(
	actor: String,
	dc: int,
	roll: int,
	total: int,
	success: bool
) -> CombatLogEntryClass:
	var s := SaveResultClass.new()
	s.dc      = dc
	s.roll    = roll
	s.total   = total
	s.success = success
	var e := CombatLogEntryClass.new()
	e.event_type  = "save"
	e.actor_name  = actor
	e.save_result = s
	return e


func _make_condition_entry(
	actor: String,
	cond_id: String,
	cond_name: String
) -> CombatLogEntryClass:
	var e := CombatLogEntryClass.new()
	e.event_type     = "condition"
	e.actor_name     = actor
	e.condition_id   = cond_id
	e.condition_name = cond_name
	return e


func _make_concentration_break_entry(
	actor: String,
	effect_id: String
) -> CombatLogEntryClass:
	var e := CombatLogEntryClass.new()
	e.event_type              = "concentration_break"
	e.actor_name              = actor
	e.concentration_effect_id = effect_id
	return e


func _run_all_tests() -> void:
	_test_initial_state_empty()
	_test_append_entry_increments_count()
	_test_get_entries_returns_copy()
	_test_clear_removes_all_entries()
	_test_attack_miss_message()
	_test_attack_normal_hit_message()
	_test_attack_critical_hit_message()
	_test_attack_no_result_message()
	_test_save_success_message()
	_test_save_failure_message()
	_test_save_no_result_message()
	_test_condition_with_name_message()
	_test_condition_id_fallback_when_name_empty()
	_test_concentration_break_with_effect_message()
	_test_concentration_break_without_effect_message()
	_test_unknown_event_type_placeholder()
	_test_entry_added_signal_emitted()
	_test_entry_added_signal_carries_message()
	_test_multiple_entries_ordered()
	_test_no_logic_methods()


# ---------------------------------------------------------------------------
# Initial state
# ---------------------------------------------------------------------------
func _test_initial_state_empty() -> void:
	print("_test_initial_state_empty")
	var log := _make_log()
	_check(log.get_entry_count() == 0,          "entry count is 0 before any entries")
	_check(log.get_entries().size() == 0,        "get_entries returns empty array initially")
	log.free()


# ---------------------------------------------------------------------------
# append_entry increments count
# ---------------------------------------------------------------------------
func _test_append_entry_increments_count() -> void:
	print("_test_append_entry_increments_count")
	var log := _make_log()
	log.append_entry(_make_attack_entry("A", "B", false, false, 5, 5, 0))
	_check(log.get_entry_count() == 1, "count is 1 after one entry")
	log.append_entry(_make_attack_entry("A", "B", true, false, 12, 14, 7))
	_check(log.get_entry_count() == 2, "count is 2 after two entries")
	log.free()


# ---------------------------------------------------------------------------
# get_entries returns a copy (mutations don't affect internal state)
# ---------------------------------------------------------------------------
func _test_get_entries_returns_copy() -> void:
	print("_test_get_entries_returns_copy")
	var log := _make_log()
	log.append_entry(_make_attack_entry("A", "B", false, false, 5, 5, 0))
	var snapshot: Array = log.get_entries()
	snapshot.append("injected")
	_check(log.get_entry_count() == 1, "internal state unaffected by mutation of returned array")
	log.free()


# ---------------------------------------------------------------------------
# clear removes all entries
# ---------------------------------------------------------------------------
func _test_clear_removes_all_entries() -> void:
	print("_test_clear_removes_all_entries")
	var log := _make_log()
	log.append_entry(_make_attack_entry("A", "B", false, false, 4, 4, 0))
	log.append_entry(_make_attack_entry("A", "B", true, false, 13, 15, 8))
	_check(log.get_entry_count() == 2, "two entries before clear")
	log.clear()
	_check(log.get_entry_count() == 0, "zero entries after clear")
	log.free()


# ---------------------------------------------------------------------------
# Attack — miss (AC: displays attacks)
# ---------------------------------------------------------------------------
func _test_attack_miss_message() -> void:
	print("_test_attack_miss_message")
	var log := _make_log()
	log.append_entry(_make_attack_entry("Fighter", "Goblin", false, false, 5, 7, 0))
	var msg: String = log.get_entries()[0]
	_check("Fighter" in msg,  "miss message contains attacker name")
	_check("Goblin" in msg,   "miss message contains target name")
	_check("miss" in msg,     "miss message contains 'miss'")
	_check("7" in msg,        "miss message contains the attack total")
	log.free()


# ---------------------------------------------------------------------------
# Attack — normal hit (AC: displays attacks, damage)
# ---------------------------------------------------------------------------
func _test_attack_normal_hit_message() -> void:
	print("_test_attack_normal_hit_message")
	var log := _make_log()
	log.append_entry(_make_attack_entry("Fighter", "Goblin", true, false, 14, 16, 8))
	var msg: String = log.get_entries()[0]
	_check("Fighter" in msg,  "hit message contains attacker name")
	_check("Goblin" in msg,   "hit message contains target name")
	_check("hit" in msg,      "hit message contains 'hit'")
	_check("8" in msg,        "hit message contains damage value")
	_check("16" in msg,       "hit message contains attack total")
	_check("CRITICAL" not in msg, "normal hit message does not say CRITICAL")
	log.free()


# ---------------------------------------------------------------------------
# Attack — critical hit (AC: shows critical hits)
# ---------------------------------------------------------------------------
func _test_attack_critical_hit_message() -> void:
	print("_test_attack_critical_hit_message")
	var log := _make_log()
	log.append_entry(_make_attack_entry("Paladin", "Orc", true, true, 20, 20, 14))
	var msg: String = log.get_entries()[0]
	_check("Paladin" in msg,  "critical message contains attacker name")
	_check("Orc" in msg,      "critical message contains target name")
	_check("CRITICAL" in msg, "critical hit message contains 'CRITICAL'")
	_check("14" in msg,       "critical message contains damage value")
	log.free()


# ---------------------------------------------------------------------------
# Attack — no AttackResult attached
# ---------------------------------------------------------------------------
func _test_attack_no_result_message() -> void:
	print("_test_attack_no_result_message")
	var log := _make_log()
	var e := CombatLogEntryClass.new()
	e.event_type  = "attack"
	e.actor_name  = "Hero"
	e.target_name = "Bandit"
	log.append_entry(e)
	var msg: String = log.get_entries()[0]
	_check("Hero" in msg,   "no-result attack message contains actor name")
	_check("Bandit" in msg, "no-result attack message contains target name")
	log.free()


# ---------------------------------------------------------------------------
# Save — success (AC: displays saves)
# ---------------------------------------------------------------------------
func _test_save_success_message() -> void:
	print("_test_save_success_message")
	var log := _make_log()
	log.append_entry(_make_save_entry("Rogue", 14, 15, 17, true))
	var msg: String = log.get_entries()[0]
	_check("Rogue" in msg,     "save success message contains actor name")
	_check("succeeds" in msg,  "save success message contains 'succeeds'")
	_check("14" in msg,        "save success message contains DC")
	_check("17" in msg,        "save success message contains total")
	log.free()


# ---------------------------------------------------------------------------
# Save — failure (AC: displays saves)
# ---------------------------------------------------------------------------
func _test_save_failure_message() -> void:
	print("_test_save_failure_message")
	var log := _make_log()
	log.append_entry(_make_save_entry("Cleric", 14, 6, 8, false))
	var msg: String = log.get_entries()[0]
	_check("Cleric" in msg,  "save failure message contains actor name")
	_check("fails" in msg,   "save failure message contains 'fails'")
	_check("14" in msg,      "save failure message contains DC")
	_check("8" in msg,       "save failure message contains total")
	log.free()


# ---------------------------------------------------------------------------
# Save — no SaveResult attached
# ---------------------------------------------------------------------------
func _test_save_no_result_message() -> void:
	print("_test_save_no_result_message")
	var log := _make_log()
	var e := CombatLogEntryClass.new()
	e.event_type = "save"
	e.actor_name = "Wizard"
	log.append_entry(e)
	var msg: String = log.get_entries()[0]
	_check("Wizard" in msg, "no-result save message contains actor name")
	log.free()


# ---------------------------------------------------------------------------
# Condition — with name (AC: displays conditions)
# ---------------------------------------------------------------------------
func _test_condition_with_name_message() -> void:
	print("_test_condition_with_name_message")
	var log := _make_log()
	log.append_entry(_make_condition_entry("Fighter", "poisoned", "Poisoned"))
	var msg: String = log.get_entries()[0]
	_check("Fighter" in msg,   "condition message contains actor name")
	_check("Poisoned" in msg,  "condition message contains condition name")
	log.free()


# ---------------------------------------------------------------------------
# Condition — falls back to condition_id when condition_name is empty
# ---------------------------------------------------------------------------
func _test_condition_id_fallback_when_name_empty() -> void:
	print("_test_condition_id_fallback_when_name_empty")
	var log := _make_log()
	log.append_entry(_make_condition_entry("Monk", "blinded", ""))
	var msg: String = log.get_entries()[0]
	_check("Monk" in msg,     "condition fallback message contains actor name")
	_check("blinded" in msg,  "condition fallback message contains condition_id when name empty")
	log.free()


# ---------------------------------------------------------------------------
# Concentration break — with effect_id (AC: shows concentration breaks)
# ---------------------------------------------------------------------------
func _test_concentration_break_with_effect_message() -> void:
	print("_test_concentration_break_with_effect_message")
	var log := _make_log()
	log.append_entry(_make_concentration_break_entry("Wizard", "hold_person"))
	var msg: String = log.get_entries()[0]
	_check("Wizard" in msg,       "concentration break message contains actor name")
	_check("concentration" in msg, "concentration break message mentions concentration")
	_check("hold_person" in msg,  "concentration break message contains effect id")
	log.free()


# ---------------------------------------------------------------------------
# Concentration break — without effect_id
# ---------------------------------------------------------------------------
func _test_concentration_break_without_effect_message() -> void:
	print("_test_concentration_break_without_effect_message")
	var log := _make_log()
	log.append_entry(_make_concentration_break_entry("Sorcerer", ""))
	var msg: String = log.get_entries()[0]
	_check("Sorcerer" in msg,      "concentration break (no effect) contains actor name")
	_check("concentration" in msg, "concentration break (no effect) mentions concentration")
	log.free()


# ---------------------------------------------------------------------------
# Unknown event_type produces a non-empty placeholder
# ---------------------------------------------------------------------------
func _test_unknown_event_type_placeholder() -> void:
	print("_test_unknown_event_type_placeholder")
	var log := _make_log()
	var e := CombatLogEntryClass.new()
	e.event_type = "unknown_xyz"
	log.append_entry(e)
	var msg: String = log.get_entries()[0]
	_check(msg.length() > 0, "unknown event type still produces a non-empty message")
	log.free()


# ---------------------------------------------------------------------------
# entry_added signal emitted
# ---------------------------------------------------------------------------
func _test_entry_added_signal_emitted() -> void:
	print("_test_entry_added_signal_emitted")
	var log := _make_log()
	var received: Array = []
	log.entry_added.connect(func(msg: String) -> void: received.append(msg))
	log.append_entry(_make_attack_entry("A", "B", false, false, 5, 5, 0))
	_check(received.size() == 1, "entry_added emitted once after one append_entry")
	log.free()


# ---------------------------------------------------------------------------
# entry_added signal carries the formatted message
# ---------------------------------------------------------------------------
func _test_entry_added_signal_carries_message() -> void:
	print("_test_entry_added_signal_carries_message")
	var log := _make_log()
	var received: Array = []
	log.entry_added.connect(func(msg: String) -> void: received.append(msg))
	log.append_entry(_make_attack_entry("Hero", "Boss", true, false, 12, 15, 10))
	_check(received.size() == 1, "one signal emission")
	_check("Hero" in received[0], "emitted message contains actor name")
	log.free()


# ---------------------------------------------------------------------------
# Multiple entries stored in chronological order
# ---------------------------------------------------------------------------
func _test_multiple_entries_ordered() -> void:
	print("_test_multiple_entries_ordered")
	var log := _make_log()
	log.append_entry(_make_attack_entry("Fighter", "Goblin", false, false, 3, 3, 0))
	log.append_entry(_make_save_entry("Goblin", 12, 10, 12, true))
	log.append_entry(_make_condition_entry("Fighter", "prone", "Prone"))
	var entries: Array = log.get_entries()
	_check(entries.size() == 3,          "three entries stored")
	_check("miss" in entries[0],         "first entry is the attack miss")
	_check("succeeds" in entries[1],     "second entry is the save success")
	_check("Prone" in entries[2],        "third entry is the condition")
	log.free()


# ---------------------------------------------------------------------------
# No logic methods — CombatLog must not expose any 5e calculation methods
# ---------------------------------------------------------------------------
func _test_no_logic_methods() -> void:
	print("_test_no_logic_methods")
	var log := _make_log()
	_check(not log.has_method("resolve_attack"),
		"no resolve_attack() method (rules logic must stay in rules_engine)")
	_check(not log.has_method("compute_damage"),
		"no compute_damage() method (damage calculation must stay in rules_engine)")
	_check(not log.has_method("roll"),
		"no roll() method (dice rolling must stay in rules_engine)")
	_check(not log.has_method("tick"),
		"no tick() method (turn advancement is not a log responsibility)")
	log.free()
