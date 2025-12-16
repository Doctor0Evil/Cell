extends Resource
class_name CellSkillTexts

# Core skill display names (legacy IDs 100–117, now Cell-internal)
const SKILL_NAMES := {
    100: "Small Firearms",
    101: "Heavy Weapons",
    102: "Energy Systems",
    103: "Close Combat - Unarmed",
    104: "Close Combat - Melee",
    105: "Thrown Weapons",
    106: "First Aid",
    107: "Trauma Care",
    108: "Stealth Movement",
    109: "Lockpicking",
    110: "Theft",
    111: "Traps",
    112: "Technical Sciences",
    113: "Repair",
    114: "Speech",
    115: "Trade",
    116: "Gambling",
    117: "Outdoors Survival",
}

# Skill descriptions (legacy 200–217) reframed for Cell
const SKILL_DESCRIPTIONS := {
    100: "Use, care, and general knowledge of small firearms: pistols, SMGs, and rifles.",
    101: "Operation and maintenance of heavy weaponry: rotary cannons, launchers, industrial flamers.",
    102: "Handling of energy-based systems and weapons: laser, plasma, and directed power tools.",
    103: "Unarmed combat: martial strikes, grapples, and emergency close-quarters techniques.",
    104: "Use of hand-held melee weapons: knives, blades, hammers, spears, and improvised tools.",
    105: "Use of muscle-propelled ranged weapons: thrown blades, spears, grenades, and devices.",
    106: "General healing skill for minor trauma and common medical issues.",
    107: "Stabilizing major wounds, fractures, and crippled limbs under field conditions.",
    108: "Quiet movement and staying unnoticed; reduces detection by patrols and monsters.",
    109: "Opening physical locks without the proper key using mechanical or improvised tools.",
    110: "Taking items from others or containers without detection.",
    111: "Finding, disarming, and setting traps and demolition charges.",
    112: "High-technology disciplines: computation, biology, physics, geology, and related analysis.",
    113: "Practical application of technical skills to fix broken machinery and electronics.",
    114: "Convincing others, negotiating, lying, and steering conversations in your favor.",
    115: "Trade and barter: getting better prices and exploiting market imbalances.",
    116: "Wagering and games of chance; understanding odds and reading opponents.",
    117: "Living off hostile terrain: navigation, plants, animals, and environmental hazards."
}

# Generic skill-use feedback strings (legacy 500+), Cell-neutral
const SKILL_USE_MESSAGES := {
    "heal_self_success": "You heal %d hit points.",
    "heal_self_unneeded": "You look stable enough already.",
    "heal_target_unneeded": "%s looks stable enough already.",
    "heal_self_fail": "You fail to stabilize yourself.",
    "heal_xp_gain": "You earn %d XP for honing your skills.",
    "invalid_skill": "\nskill_use: invalid skill used.",
    "heal_dead_fail_1": "You can't heal the dead.",
    "heal_dead_fail_2": "Let the dead rest.",
    "heal_dead_fail_3": "It's gone. Move on.",
    "heal_limb_self_success": "You stabilize your %s.",
    "heal_limb_target_success": "You stabilize the %s.",
    "heal_limb_self_fail": "You fail to stabilize your %s.",
    "heal_limb_target_fail": "You fail to stabilize the %s.",
    "limb_eye": "damaged eye",
    "limb_left_arm": "crippled left arm",
    "limb_right_arm": "crippled right arm",
    "limb_right_leg": "crippled right leg",
    "limb_left_leg": "crippled left leg",
    "lockpick_fail": "You fail to pick the lock.",
    "trap_search_fail": "You fail to find any traps.",
    "learn_fail": "You fail to learn anything.",
    "repair_fail": "You cannot repair that.",
    "steal_caught": "You're caught taking the %s.",
    "steal_success": "You take the %s.",
    "plant_caught": "You're caught planting the %s.",
    "plant_success": "You plant the %s.",
    "skill_overused": "You've taxed your ability with that skill. Wait a while.",
    "too_tired": "You're too tired.",
    "strain_may_kill": "The strain might kill you.",
    "cripple_heal_insufficient": "You aren't skilled enough to heal crippling injuries.",
    "robot_unrepairable": "This unit is beyond repair.",

    # Generic NPC helper responses (no franchise context)
    "helper_try_1": "Let me handle it.",
    "helper_try_2": "I can do that.",
    "helper_try_3": "On it.",
    "helper_try_4": "Glad to help.",
    "helper_try_5": "Okay.",
    "helper_try_6": "I'll try.",

    "helper_player_do_1": "If you have trouble, call me.",
    "helper_player_do_2": "You got it?",
    "helper_player_do_3": "If that's what you want.",
    "helper_player_do_4": "Go ahead and try.",
    "helper_player_do_5": "You go ahead."
}
