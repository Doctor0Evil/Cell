extends Node
class_name CellObjectFactory

# Generates stable, per‑device / per‑profile object descriptors for Cell.
# Used for logs, mission records, and director AI “pipe stems”.

# -------------------------------------------------------------------
# INTERNAL DEPENDENCY MAPPING (no external APIs)
# -------------------------------------------------------------------
static func _get_internal_deps(obj_type: String) -> Array:
	var deps: Array = []
	match obj_type:
		"REGION_SEGMENT":
			deps.append("navmesh-loader-v1")
			deps.append("threat-profile-resolver-v1")
		"PLAYER_TELEMETRY":
			deps.append("vitality-system-core")
			deps.append("fracture-matrix-v1")
		"ENCOUNTER_BLOCK":
			deps.append("spawn-table-resolver-v1")
			deps.append("audio-ambience-router-v1")
		"SETTLEMENT_SNAPSHOT":
			deps.append("settlement-pools-core")
			deps.append("faction-reputation-core")
		_:
			deps.append("generic-runtime-stub")
	return deps

static func make_object(obj_type: String, user_id: String, sys_id: String) -> Dictionary:
	var obj: Dictionary = {}
	obj["obj_type"] = obj_type
	obj["subject"] = user_id
	obj["node"] = sys_id
	obj["timestamp"] = CellSystemKernel.now_compact_stamp()
	obj["internal_dep"] = _get_internal_deps(obj_type)
	obj["sealed"] = true   # Not meant to be mutated from outside once logged.
	return obj

# Example: auto‑generate file descriptors per major category for logging / save stubs.
static func autogen_files_for_categories(categories: Array) -> Array:
	var files: Array = []
	for cat in categories:
		if typeof(cat) != TYPE_STRING:
			continue
		var f: Dictionary = {}
		f["category"] = cat
		f["filename"] = _gen_filename(cat, CellSystemKernel.now_compact_stamp())
		f["created"] = CellSystemKernel.now_compact_stamp()
		files.append(f)
	return files

static func _gen_filename(category: String, timestamp: String) -> String:
	var safe := category.strip_edges().replace(" ", "_").to_lower()
	return "%s.%s.cell" % [safe, timestamp]
