## DeathSavingThrow
## Pure logic class — no Node, no UI, no scene references.
## Implements the D&D 5e SRD death saving throw system.
##
## Triggered at the start of a creature's turn when HP = 0.
## Rules:
##   Natural 20 → restore 1 HP (creature regains consciousness).
##   Natural  1 → counts as 2 failures.
##   Roll 10+   → 1 success;  3 cumulative successes → stable.
##   Roll 2–9   → 1 failure;  3 cumulative failures  → dead.
##
## RNG is injected as a Callable for fully deterministic testing:
##   func() -> int   # must return a value in [1, 20]
class_name DeathSavingThrow

const NATURAL_20: int = 20
const NATURAL_1: int = 1
const SUCCESS_THRESHOLD: int = 10
const SUCCESSES_TO_STABILIZE: int = 3
const FAILURES_TO_DIE: int = 3


## Returns true when a death saving throw should be triggered.
## Call at the start of a creature's turn.
##
## Parameters:
##   current_hp - the creature's current hit points
static func should_trigger(current_hp: int) -> bool:
	return current_hp <= 0


## Roll a death saving throw and return the updated state.
##
## Parameters:
##   successes - current success count before this roll (0–2)
##   failures  - current failure count before this roll (0–2)
##   roll_d20  - Callable returning an int in [1, 20] (injected for determinism)
##
## Returns a Dictionary:
##   "roll"        - Raw d20 result
##   "outcome"     - One of: "restored", "stable", "dead", "success", "failure"
##                   "restored" : natural 20 — HP restored to 1, creature wakes up
##                   "stable"   : 3 cumulative successes reached
##                   "dead"     : 3 cumulative failures reached
##                   "success"  : 1 success recorded, not yet stable
##                   "failure"  : 1 failure recorded, not yet dead
##   "successes"   - Updated success count
##   "failures"    - Updated failure count
##   "hp_restored" - 1 if natural 20 restores HP, otherwise 0
static func roll(successes: int, failures: int, roll_d20: Callable) -> Dictionary:
	var d20: int = roll_d20.call()
	var new_successes: int = successes
	var new_failures: int = failures
	var hp_restored: int = 0
	var outcome: String

	if d20 == NATURAL_20:
		hp_restored = 1
		new_successes = 0
		new_failures = 0
		outcome = "restored"
	elif d20 == NATURAL_1:
		new_failures = mini(new_failures + 2, FAILURES_TO_DIE)
		outcome = "dead" if new_failures >= FAILURES_TO_DIE else "failure"
	elif d20 >= SUCCESS_THRESHOLD:
		new_successes += 1
		outcome = "stable" if new_successes >= SUCCESSES_TO_STABILIZE else "success"
	else:
		new_failures += 1
		outcome = "dead" if new_failures >= FAILURES_TO_DIE else "failure"

	return {
		"roll": d20,
		"outcome": outcome,
		"successes": new_successes,
		"failures": new_failures,
		"hp_restored": hp_restored,
	}
