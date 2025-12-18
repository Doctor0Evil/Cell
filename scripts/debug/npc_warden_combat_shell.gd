# Filename: res/scripts/debug/npc_warden_combat_shell.gd
extends Node
class_name NpcWardenCombatShell

@export var snapshot: NpcWardenCombatEngageCell

func _ready() -> void:
	if snapshot == null:
		snapshot = NpcWardenCombatEngageCell.new()
	_debug_print_snapshot()

func _debug_print_snapshot() -> void:
	print("--- NPC Warden Combat Engage Snapshot ---")
	print("Region:", snapshot.env_profile["region_id"])
	print("Player primary weapon:", snapshot.player_combat_profile["primary_weapon"])
	print("Warden id:", snapshot.warden_profile["id"])
	print("Warden claws base damage:", snapshot.warden_profile["natural_weapon"]["base_damage"])
	print("Hex block labels:", [b["label"] for b in snapshot.dense_hexblocks])
	print("Hit matrix:", snapshot.parameter_matrices[0]["values"])
