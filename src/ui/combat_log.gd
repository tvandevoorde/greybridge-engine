## CombatLog
## UI layer class — extends Node.
## Receives structured CombatLogEntry objects and formats them into
## human-readable strings for display.  Contains NO D&D rules logic and
## performs NO 5e calculations of any kind.
##
## Responsibilities:
##   - Accept CombatLogEntry objects via append_entry().
##   - Format each entry into a readable string (presentation only).
##   - Maintain an ordered list of formatted messages.
##   - Emit entry_added whenever a new message is appended.
##
## Usage:
##   log.append_entry(entry)         # add a CombatLogEntry
##   log.get_entries()               # Array[String] of all messages
##   log.get_entry_count()           # number of stored messages
##   log.clear()                     # remove all messages
##
## The combat runtime (or a controller) is responsible for constructing
## CombatLogEntry objects and calling append_entry() at the appropriate
## moments during combat.
class_name CombatLog
extends Node

const CombatLogEntryClass = preload("res://rules_engine/core/combat_log_entry.gd")

## Emitted after each new entry is appended.
## The message parameter is the formatted string that was just stored.
signal entry_added(message: String)

## Ordered list of formatted log messages.
var _entries: Array[String] = []


## Formats [param entry] and appends the result to the log.
## Emits entry_added with the formatted message.
## Unknown event_type values produce a generic placeholder message.
func append_entry(entry: CombatLogEntryClass) -> void:
	var msg: String = _format_entry(entry)
	_entries.append(msg)
	entry_added.emit(msg)


## Returns a copy of all formatted log messages in chronological order.
func get_entries() -> Array[String]:
	return _entries.duplicate()


## Returns the total number of messages currently stored.
func get_entry_count() -> int:
	return _entries.size()


## Removes all stored messages.
func clear() -> void:
	_entries.clear()


# ---------------------------------------------------------------------------
# Private formatting helpers — presentation only, no 5e math.
# ---------------------------------------------------------------------------

func _format_entry(entry: CombatLogEntryClass) -> String:
	match entry.event_type:
		"attack":
			return _format_attack(entry)
		"save":
			return _format_save(entry)
		"condition":
			return _format_condition(entry)
		"concentration_break":
			return _format_concentration_break(entry)
		_:
			return "[combat event]"


func _format_attack(entry: CombatLogEntryClass) -> String:
	var attacker: String = entry.actor_name
	var target: String   = entry.target_name
	var r = entry.attack_result
	if r == null:
		return "%s attacks %s." % [attacker, target]
	if not r.hit:
		return "%s attacks %s — miss (rolled %d)." % [attacker, target, r.total]
	if r.critical:
		return "%s attacks %s — CRITICAL HIT! Deals %d damage (rolled %d)." \
			% [attacker, target, r.damage, r.total]
	return "%s attacks %s — hit! Deals %d damage (rolled %d)." \
		% [attacker, target, r.damage, r.total]


func _format_save(entry: CombatLogEntryClass) -> String:
	var actor: String = entry.actor_name
	var r = entry.save_result
	if r == null:
		return "%s makes a saving throw." % actor
	var outcome: String = "succeeds" if r.success else "fails"
	return "%s saving throw: %s (DC %d, rolled %d)." \
		% [actor, outcome, r.dc, r.total]


func _format_condition(entry: CombatLogEntryClass) -> String:
	var label: String = entry.condition_name if entry.condition_name != "" \
		else entry.condition_id
	return "%s gains condition: %s." % [entry.actor_name, label]


func _format_concentration_break(entry: CombatLogEntryClass) -> String:
	var actor: String = entry.actor_name
	var effect: String = entry.concentration_effect_id
	if effect != "":
		return "%s loses concentration on %s." % [actor, effect]
	return "%s loses concentration." % actor
