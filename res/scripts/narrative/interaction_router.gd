extends Node
class_name InteractionRouter

@export var combat_system: Node
@export var barter_system: Node
@export var inventory_system: Node
@export var party_menu: Node
@export var journal_system: Node
@export var dialogue_session: Node

signal interaction_completed(should_resume_dialogue: bool, next_node: StringName)

func handle_choice(choice: Object, node_id: StringName) -> void:
	var action_type := String(choice.get("action_type", "DIALOGUE_BRANCH"))
	var payload := choice.get("action_payload", {})

	match action_type:
		"DIALOGUE_BRANCH":
			_route_dialogue_branch(choice)
		"OPEN_BARTER":
			_open_barter(payload)
		"SHOW_ITEM_MENU":
			_open_show_item_menu(payload)
		"OFFER_CONSUMABLE":
			_open_offer_consumable_menu(payload)
		"OPEN_PARTY_MENU":
			_open_party_menu(payload)
		"START_COMBAT":
			_start_combat(payload)
		_:
			_route_dialogue_branch(choice)

func _route_dialogue_branch(choice: Object) -> void:
	if dialogue_session and dialogue_session.has_method("choose"):
		dialogue_session.choose(StringName(choice.get("id", "")))

func _open_barter(payload: Dictionary) -> void:
	if barter_system and barter_system.has_method("open_barter"):
		barter_system.open_barter(payload.get("shop_id", ""))
	emit_signal("interaction_completed", true, dialogue_session.current_node_id)

func _open_show_item_menu(payload: Dictionary) -> void:
	if inventory_system and inventory_system.has_method("open_show_item_menu"):
		inventory_system.open_show_item_menu(payload)
	emit_signal("interaction_completed", true, dialogue_session.current_node_id)

func _open_offer_consumable_menu(payload: Dictionary) -> void:
	if inventory_system and inventory_system.has_method("open_offer_consumable_menu"):
		inventory_system.open_offer_consumable_menu(payload)
	emit_signal("interaction_completed", true, dialogue_session.current_node_id)

func _open_party_menu(_payload: Dictionary) -> void:
	if party_menu and party_menu.has_method("open_party_menu"):
		party_menu.open_party_menu()
	emit_signal("interaction_completed", true, dialogue_session.current_node_id)

func _start_combat(payload: Dictionary) -> void:
	if combat_system and combat_system.has_method("start_scripted_encounter"):
		combat_system.start_scripted_encounter(payload.get("encounter_id", ""))
	emit_signal("interaction_completed", false, StringName())
