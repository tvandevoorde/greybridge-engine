# Copilot Instructions -- JRPG 5e Engine (Godot 4, Windows)

## Project Overview

This project is a 2D grid-based JRPG engine built in Godot 4. It
implements strict D&D 5e SRD mechanics and supports a data-driven
campaign system.

Architecture priorities: - Strict separation between rules logic and
presentation. - Data-driven content (JSON). - Deterministic and testable
rules engine. - Single-player V1 campaign: "The Road to Greybridge".

Copilot must respect these constraints at all times.

------------------------------------------------------------------------

# Architectural Rules (Non-Negotiable)

## 1. Rules Engine Is Pure Logic

All files under:

src/rules_engine/

MUST: - Contain pure GDScript classes. - NOT extend Node. - NOT
reference scenes. - NOT access UI. - NOT load resources via
get_node(). - Be fully unit-testable.

Rules engine handles: - Ability modifiers - Proficiency - Attack
resolution - Saving throws - Conditions - Concentration - Initiative -
Action economy - Damage calculation

It does NOT: - Render anything - Play sounds - Show UI - Manage scenes

------------------------------------------------------------------------

## 2. Combat Runtime Orchestrates

src/combat_runtime/

-   Extends Node.
-   Calls rules engine.
-   Emits events.
-   Does not contain 5e math.
-   Does not duplicate rule logic.

All mechanical calculations must go through rules_engine.

------------------------------------------------------------------------

## 3. UI Is Dumb

src/ui/

UI: - Displays state - Emits intent - Subscribes to events - Never
calculates game logic

UI calls controller → controller calls rules engine.

------------------------------------------------------------------------

## 4. Data Is External

All content lives under:

content/

Including: - Campaign definitions - Dialogue trees - Maps - Loot
tables - Spells - Items - Monsters - Preset characters

Never hardcode content inside engine files.

------------------------------------------------------------------------

# Coding Conventions

## Language

-   GDScript (Godot 4)
-   Use typed GDScript where possible.

## Naming

-   Classes: PascalCase
-   Methods: snake_case
-   Constants: UPPER_SNAKE_CASE
-   JSON keys: snake_case

## Files

-   One class per file where possible.
-   Match filename to class_name.

------------------------------------------------------------------------

# Rules Strictness (5e SRD Compliance)

When implementing mechanics:

-   Follow SRD strictly.
-   No house rules.
-   No simplifications unless explicitly documented.
-   Edge cases must be handled properly.

Examples: - Natural 20 = auto hit + critical. - Natural 1 = auto miss. -
Concentration DC = max(10, damage / 2). - Resistance halves damage
(round down). - Only one reaction per round.

------------------------------------------------------------------------

# Determinism & Testing

All rules engine logic must support deterministic RNG.

Dice rolls must: - Accept injected RNG provider. - Not use global
randomness directly.

Tests live in:

tests/unit/ tests/integration/ tests/e2e/

Never write logic that cannot be tested headlessly.

------------------------------------------------------------------------

# Save & Load Rules

Save files must: - Include schema_version - Include campaign_id -
Serialize: - Player state - Inventory - Flags - Map state - Avoid
duplication of rewards on reload

Never: - Save live scene nodes directly. - Serialize Godot Node
references.

Use structured data only.

------------------------------------------------------------------------

# Campaign V1 Scope

Campaign: greybridge_v1

Contains: - Road map - Bandit ambush - Bandit camp - Boss fight -
Greybridge resolution

V1 constraints: - Level 1 only. - No multiclassing. - Limited spell
set. - Single player only.

Do not add features beyond V1 scope unless explicitly instructed.

------------------------------------------------------------------------

# High-Level Layer Model

rules_engine → pure mechanics combat_runtime → orchestration overworld →
grid + triggers dialogue → state machine inventory → container system ui
→ presentation only

If code crosses these boundaries improperly, it must be corrected.

------------------------------------------------------------------------

# Testing First Policy

When adding: - New rule - New spell - New condition - New combat
mechanic

Generate: 1. Unit test 2. Implementation 3. Edge case tests

------------------------------------------------------------------------

# Final Directive

If there is a conflict between: - Making it easy and - Keeping
architecture clean

Architecture cleanliness wins.
