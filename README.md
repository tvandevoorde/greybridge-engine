# Greybridge Engine

## Scope for V1

- Turn-based combat (JRPG style)
    - Initiative
    - Action / Bonus / Reaction / Movement
    - Attacks, Saving Throws, Conditions
  - Exploration on tilemap + interactions (door, chest, conversation)
  - Dialogue + quest flags
  - Limited content set: e.g., 4 classes, 20 spells, 30 monsters, levels 1–5

## Architecture: split "Rules Engine" and "Presentation"

- A. Content/data layer
    - JSON/YAML for: classes, features, spells, items, monsters, races, backgrounds
    - Maps, NPC dialog trees, encounters, quests
- B. Rules Engine (5e core)
    - Pure logic: "can I do this?", "what is the outcome?"
    - Deterministic + testable
    - No rendering, no input, no God objects
- C. Game Runtime (JRPG)
    - Scenes: exploration, combat, menu, cutscene
    - UI, animations, audio
    - Save/load
    - Scripting layer for campaign events
- D. DM/Authoring tools
    - Campaign editor: maps, triggers, dialog, encounters
    - Monster/spell browser
    - Debug console (super handy)

## Modeling D&D 5e: the core objects

- Entity/Actor: PC/NPC/monster
    - ability scores, prof bonus, AC, HP, speed
    - skills/saves proficiencies
    - resistances/immunities/vulnerabilities
    - conditions, active effects, resources (spell slots, ki, superiority dice)
- Action (and BonusAction/Reaction)
    - AttackAction, CastSpellAction, Dash, Disengage, Dodge, Help, UseObject, Ready
  - Effect (the real magic)
    - “ApplyDamage”, “ApplyCondition”, “ModifyRoll”, “GrantAdvantage”, “SetSpeed”, “OngoingDamage”, etc.
    - duration + concentration + stacking rules
- Roll system
    - d20 tests, advantage/disadvantage, modifiers, proficiency, expertise
    - dice expressions: 2d6+3, 1d8, etc.
- Combat state
    - initiative order, turn state, action economy tracking, reactions used, concentration tracking

## Combat flow (JRPG feel, but 5e compliant)

- Start encounter
- Roll initiative (or "take 10" variant for mobs, but later)
- Per turn:
    - Start of turn triggers (regen, conditions)
    - Movement (with opportunity attacks)
    - Action / Bonus / (possibly) Free object interact
    - Reaction management
    - End of turn triggers (saves vs conditions, durations)
- End encounter -> loot/XP/story flags

JRPG sauce without breaking 5e

- Cinematic camera + battle intros
- “Party formation” UI
- Snappy menus for actions/spells
- Damage popups / status icons
- Enemy AI that makes "reads" (but still within the rules)

## Spellcasting and features

D&D 5e has an enormous amount of exceptions. Therefore we start with a subset of spells:

- Magic Missile (no attack roll, force damage)
- Cure Wounds (heal, touch)
- Sleep (HP pool logic)
- Shield (reaction, temporary AC)
- Bless (concentration, add d4 to rolls)
- Fireball (AoE, save for half)

Concentration

- 1 concentration spell at a time per caster
- Damage -> CON save (DC max(10, dmg/2))
- Concentration ends -> remove effects

## Campaign system: from "DM tells" to "game triggers"

- locations
- NPCs
- skill checks / choices
- combats
- loot
- flags (quest states)

"Story Scripting" as a simple state machine

- Triggers: onEnterTile, onTalkToNPC, onItemUsed, onCombatEnd
- Conditions: flag set, hasItem, skill >=, quest stage
- Actions: setFlag, giveItem, startDialogue, startCombat, teleport, playCutscene

## Dealing with randomness, saves, and "DM fiat"

- Option A: "Strict sim": Everything according to the rules, no DM overrides.
- Option B: "DM mode":
    - Button "force success/fail"
    - Reroll
    - Spawn/add monsters mid-fight
    - Edit HP on the fly
    - Reveal/hide checks (passive perception etc.)

## Content: SRD vs full 5e (important!)

- Work with SRD material (openly accessible basic content)

## Tech stack advice (simple and achievable)

Godot (fast JRPG iteration)
- Strong for 2D JRPG maps + UI + turn-based
- Rules engine in GDScript or C#
- Data-driven content via JSON

## Test strategy: rules engine must be "proofed"

- Advantage/disadvantage cancels
- AC calculation with armor/shield/spells
- Concentration DC correct
- Conditions (Prone, Grappled, Restrained) effect on rolls/movement
- Spell save for half damage
- Opportunity attacks triggers