extends Node
class_name AssetRegistry

@export var database: AssetDatabase

var _by_id: Dictionary = {}

func _ready() -> void:
	# Ensure the runtime database has default assets populated (meds, LOX bottles, etc.).
	if not database:
		# Create an in-memory database if one was not assigned in the editor.
		database = AssetDatabase.new()
		DebugLog.log("AssetRegistry", "DATABASE_CREATED_AT_RUNTIME", {})

	if database and database.has_method("load_default_assets"):
		database.load_default_assets()

	_build_index()

func _build_index() -> void:
	_by_id.clear()
	if not database:
		push_warning("AssetRegistry: no AssetDatabase assigned.")
		return
	for a in database.assets:
		if a.id == StringName():
			push_warning("AssetRegistry: asset has empty id, skipping.")
			continue
		if _by_id.has(a.id):
			push_warning("AssetRegistry: duplicate id '%s', overwriting." % a.id)
		_by_id[a.id] = a

func get_asset(id: StringName) -> AssetDefinition:
	if not _by_id.has(id):
		push_warning("AssetRegistry: unknown asset id '%s'." % id)
		return null
	return _by_id[id] as AssetDefinition

func get_weapon(id: StringName) -> WeaponDefinition:
	var a := get_asset(id)
	return a as WeaponDefinition

func get_armor(id: StringName) -> ArmorDefinition:
	var a := get_asset(id)
	return a as ArmorDefinition

func get_implant(id: StringName) -> ImplantDefinition:
	var a := get_asset(id)
	return a as ImplantDefinition

func get_consumable(id: StringName) -> ConsumableDefinition:
	var a := get_asset(id)
	return a as ConsumableDefinition
