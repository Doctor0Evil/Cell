# File: res://scripts/core/skill_tree.gd
extends Resource
class_name SkillTree

# skill_id -> SkillDefinition (from res://scripts/core/skill_definition.gd)
@export var skills: Dictionary = {} # Dictionary[StringName, SkillDefinition]

# Unlock links: parent skill_id -> Array[child skill_id] that depend on it
@export var links: Dictionary = {} # Dictionary[StringName, Array[StringName]]

# Track which skills are unlocked: skill_id -> SkillDefinition
var unlocked: Dictionary = {} # Dictionary[StringName, SkillDefinition]

# Optional: track invested ranks per skill_id
var ranks: Dictionary = {} # Dictionary[StringName, int]

# Metadata for compliance / audit
@export var tree_id: String = "UNSET"
@export var version: String = "CELL_SKILLTREE_v1.0"
@export var last_updated: String = ""

# Optional: flavor tags for UI (region, faction, theme)
@export var tags: Array[StringName] = [] # e.g. ["CYBERFROST", "ASHVEIL", "SURVIVAL"]

# Cosmetic layout data for UI skill grid/radial
@export var layout_positions: Dictionary = {} 
# skill_id -> Vector2: used to draw the tree on screen

func _init() -> void:
	unlocked.clear()
	ranks.clear()
	last_updated = Time.get_datetime_string_from_system()


# -------------------------------------------------------------------
# Core Operations
# -------------------------------------------------------------------

func can_unlock(skill_id: StringName) -> bool:
	if not skills.has(skill_id):
		return false
	if unlocked.has(skill_id):
		return false

	# Check prerequisites: for every link parent -> children, if this
	# skill is a child, parent must be unlocked.
	for prereq in links.keys():
		var children: Array = links[prereq]
		if skill_id in children and not unlocked.has(prereq):
			return false
	return true


func unlock(skill_id: StringName) -> bool:
	if not can_unlock(skill_id):
		return false

	var def := skills[skill_id] as SkillDefinition
	if def == null:
		return false

	unlocked[skill_id] = def
	ranks[skill_id] = 1

	last_updated = Time.get_datetime_string_from_system()
	DebugLog.log("SkillTree", "UNLOCK", {
		"skill": str(skill_id),
		"tree": tree_id,
		"rank": 1,
		"timestamp": last_updated
	})
	return true


func can_rank_up(skill_id: StringName) -> bool:
	if not unlocked.has(skill_id):
		return false
	if not skills.has(skill_id):
		return false

	var def := skills[skill_id] as SkillDefinition
	if def == null:
		return false

	var current_rank: int = 0
	if ranks.has(skill_id):
		current_rank = ranks[skill_id]

	if current_rank >= def.max_rank:
		return false

	return true


func rank_up(skill_id: StringName) -> bool:
	if not can_rank_up(skill_id):
		return false

	var current_rank: int = 0
	if ranks.has(skill_id):
		current_rank = ranks[skill_id]

	current_rank += 1
	ranks[skill_id] = current_rank

	last_updated = Time.get_datetime_string_from_system()
	DebugLog.log("SkillTree", "RANK_UP", {
		"skill": str(skill_id),
		"tree": tree_id,
		"rank": current_rank,
		"timestamp": last_updated
	})
	return true


func is_unlocked(skill_id: StringName) -> bool:
	return unlocked.has(skill_id)


func get_unlocked_skills() -> Array[StringName]:
	return unlocked.keys()


func get_locked_skills() -> Array[StringName]:
	var locked: Array[StringName] = []
	for id in skills.keys():
		if not unlocked.has(id):
			locked.append(id)
	return locked


func get_skill(skill_id: StringName) -> SkillDefinition:
	if skills.has(skill_id):
		return skills[skill_id]
	return null


func get_skill_rank(skill_id: StringName) -> int:
	if ranks.has(skill_id):
		return int(ranks[skill_id])
	return 0


# -------------------------------------------------------------------
# Utility / Query for UI & Debug
# -------------------------------------------------------------------

func reset_tree() -> void:
	unlocked.clear()
	ranks.clear()
	last_updated = Time.get_datetime_string_from_system()
	DebugLog.log("SkillTree", "RESET", {
		"tree": tree_id,
		"timestamp": last_updated
	})


func get_prerequisites(skill_id: StringName) -> Array[StringName]:
	var prereqs: Array[StringName] = []
	for prereq in links.keys():
		var children: Array = links[prereq]
		if skill_id in children:
			prereqs.append(prereq)
	return prereqs


func get_dependents(skill_id: StringName) -> Array[StringName]:
	if links.has(skill_id):
		return links[skill_id]
	return []


func set_layout_position(skill_id: StringName, pos: Vector2) -> void:
	layout_positions[skill_id] = pos


func get_layout_position(skill_id: StringName) -> Vector2:
	if layout_positions.has(skill_id):
		return layout_positions[skill_id]
	return Vector2.ZERO


func get_skill_attribute_factor(skill_id: StringName, vsys: PlayerVitalitySystem) -> float:
	var def := get_skill(skill_id)
	if def == null:
		return 0.0
	# Uses SkillDefinition.get_attribute_factor(vsys) variant
	if def.has_method("get_attribute_factor"):
		return def.get_attribute_factor(vsys)
	if def.has_method("get_attribute_factor_vsys"):
		return def.get_attribute_factor_vsys(vsys)
	return 0.0


func get_tree_snapshot() -> Dictionary:
	var snap := {
		"tree_id": tree_id,
		"version": version,
		"timestamp": last_updated,
		"unlocked": [],
		"locked": [],
		"ranks": {}
	}

	var unlocked_ids: Array[StringName] = get_unlocked_skills()
	var locked_ids: Array[StringName] = get_locked_skills()

	snap["unlocked"] = unlocked_ids
	snap["locked"] = locked_ids

	var rank_dict: Dictionary = {}
	for id in ranks.keys():
		rank_dict[str(id)] = int(ranks[id])
	snap["ranks"] = rank_dict

	return snap


# -------------------------------------------------------------------
# Example: prefilled CYBERFROST / ASHVEIL wiring helper
# Called from SkillRegistry after packs are built.
# -------------------------------------------------------------------

func populate_from_pack(pack_id: StringName, pack_skills: Array[SkillDefinition]) -> void:
	tree_id = str(pack_id)
	skills.clear()
	unlocked.clear()
	ranks.clear()

	for s in pack_skills:
		if s == null:
			continue
		if s.id == StringName():
			continue
		skills[s.id] = s

	last_updated = Time.get_datetime_string_from_system()
	DebugLog.log("SkillTree", "POPULATE_FROM_PACK", {
		"tree": tree_id,
		"skills_count": skills.size(),
		"timestamp": last_updated
	})


# -------------------------------------------------------------------
# Simulated internal debug snapshot for Cell
# -------------------------------------------------------------------

func debug_dump_state() -> void:
	var snap := get_tree_snapshot()
	DebugLog.log("SkillTree", "SNAPSHOT", {
		"tree": tree_id,
		"version": version,
		"unlocked_count": snap["unlocked"].size(),
		"locked_count": snap["locked"].size(),
		"ranks": snap["ranks"],
		"timestamp": snap["timestamp"]
	})
