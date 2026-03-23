## CombatAnimationEventBus
## Combat runtime class — extends Node.
## Central hub for animation event notification during combat.
##
## Architecture: extends Node. Lives in the combat_runtime layer.
## Emits signals carrying only presentation-relevant data (actor IDs, outcomes).
## Contains NO 5e rules logic. Damage is always applied by the rules engine
## BEFORE the corresponding animation event is emitted here.
##
## Usage: Call the notify_* methods from the combat runtime orchestrator
## AFTER the rules engine has resolved the action and updated state.
## Connect the signals from animation or UI subscribers.
class_name CombatAnimationEventBus
extends Node

## Emitted after an attack is resolved and damage (if any) is already applied.
## attacker_id : String — ID of the attacking actor.
## target_id   : String — ID of the defending actor.
## hit         : bool   — true when the attack connected.
## critical    : bool   — true when a natural 20 was rolled (auto-hit + extra dice).
signal attack_resolved(attacker_id: String, target_id: String, hit: bool, critical: bool)

## Emitted after damage has been applied to a target.
## target_id   : String — ID of the actor that received the damage.
## amount      : int    — final damage value already subtracted from hit points.
## damage_type : String — e.g. "slashing", "fire", "bludgeoning".
signal damage_applied(target_id: String, amount: int, damage_type: String)

## Emitted after an actor's HP drops to 0 (or below).
## actor_id : String — ID of the actor that has fallen.
signal actor_died(actor_id: String)

## Emitted after movement begins for an actor between two grid tiles.
## actor_id : String   — ID of the moving actor.
## from_pos : Vector2i — tile the actor is leaving.
## to_pos   : Vector2i — tile the actor is entering.
signal move_started(actor_id: String, from_pos: Vector2i, to_pos: Vector2i)

## Emitted after a condition is applied to or removed from an actor.
## actor_id     : String — ID of the affected actor.
## condition_id : String — identifier of the condition (e.g. "poisoned", "prone").
## gained       : bool   — true when the condition was added; false when removed.
signal condition_changed(actor_id: String, condition_id: String, gained: bool)

## Emitted after a spell's effects are resolved and all damage is applied.
## caster_id        : String           — ID of the spell caster.
## spell_id         : String           — identifier of the spell (e.g. "fireball").
## target_positions : Array[Vector2i]  — grid tiles affected by the spell.
signal spell_cast(caster_id: String, spell_id: String, target_positions: Array)


## Notify that an attack has been resolved.
## Call AFTER the rules engine has applied all damage and updated actor state.
func notify_attack_resolved(
		attacker_id: String,
		target_id: String,
		hit: bool,
		critical: bool) -> void:
	attack_resolved.emit(attacker_id, target_id, hit, critical)


## Notify that damage has been applied to a target.
## Call AFTER hit points have been updated by the rules engine.
func notify_damage_applied(target_id: String, amount: int, damage_type: String) -> void:
	damage_applied.emit(target_id, amount, damage_type)


## Notify that an actor has died (HP reached 0 or below).
## Call AFTER the actor's state has been updated to dead/unconscious.
func notify_actor_died(actor_id: String) -> void:
	actor_died.emit(actor_id)


## Notify that an actor is beginning movement between two tiles.
## Call AFTER the rules engine has validated and approved the move.
func notify_move_started(actor_id: String, from_pos: Vector2i, to_pos: Vector2i) -> void:
	move_started.emit(actor_id, from_pos, to_pos)


## Notify that a condition was applied to or removed from an actor.
## Call AFTER the condition manager has updated the actor's condition set.
func notify_condition_changed(actor_id: String, condition_id: String, gained: bool) -> void:
	condition_changed.emit(actor_id, condition_id, gained)


## Notify that a spell was cast.
## Call AFTER the spell executor has resolved all effects and damage.
func notify_spell_cast(caster_id: String, spell_id: String, target_positions: Array) -> void:
	spell_cast.emit(caster_id, spell_id, target_positions)
