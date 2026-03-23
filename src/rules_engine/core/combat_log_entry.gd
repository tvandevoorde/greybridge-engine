## CombatLogEntry
## Pure data class — no Node, no UI, no scene references.
## Holds the context and structured result for a single combat event so the
## combat log can render it without performing any game-logic calculations.
##
## Supported event types (set event_type to one of these string identifiers):
##   "attack"              — an attack roll was made (populate attack_result)
##   "save"                — a saving throw was resolved (populate save_result)
##   "condition"           — a condition was applied to an actor (populate
##                           condition_id and condition_name)
##   "concentration_break" — an actor lost concentration (populate
##                           concentration_effect_id; optionally save_result
##                           for the failed concentration save)
##
## Usage (attack example):
##   var entry := CombatLogEntry.new()
##   entry.event_type    = "attack"
##   entry.actor_name    = "Fighter"
##   entry.target_name   = "Goblin"
##   entry.attack_result = my_attack_result   # AttackResult instance
##
## Usage (concentration break example):
##   var entry := CombatLogEntry.new()
##   entry.event_type              = "concentration_break"
##   entry.actor_name              = "Wizard"
##   entry.concentration_effect_id = "hold_person"
##   entry.save_result             = my_save_result  # SaveResult instance (optional)
class_name CombatLogEntry

## One of: "attack", "save", "condition", "concentration_break".
var event_type: String = ""

## Name of the actor who performed or triggered the event.
var actor_name: String = ""

## Name of the target who received the event.  Empty when not applicable.
var target_name: String = ""

## Populated for "attack" events.
## Must be an AttackResult instance (or null).
var attack_result = null

## Populated for "save" and "concentration_break" events.
## Must be a SaveResult instance (or null when the result is unavailable).
var save_result = null

## Populated for "condition" events.
## The unique identifier of the condition applied (e.g. "poisoned").
var condition_id: String = ""

## Populated for "condition" events.
## Human-readable name of the condition (e.g. "Poisoned").
var condition_name: String = ""

## Populated for "concentration_break" events.
## Identifier of the spell or effect whose concentration was broken.
var concentration_effect_id: String = ""
