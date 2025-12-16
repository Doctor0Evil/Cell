# File: res://scripts/ai/cell_bootloader_console.gd
extends Node
class_name CellBootloaderConsole

# -----------------------------------------------------------------------------
# CORE DATA STRUCTURES (SIMULATED, GODOT/GD-SCRIPT VERSION)
# -----------------------------------------------------------------------------

# User record for console access
class_name CellUser
extends Resource

@export var username: String = ""
@export var password_hash: String = "" # NOTE: placeholder, not secure
@export var role: String = "User"      # "Admin", "Tech", "User"


# Plugin action (command) description
class_name CellPluginAction
extends Resource

@export var name: String = ""
@export var description: String = ""
@export var requires_auth: bool = true
@export var horror_risk: float = 0.0        # 0-1, higher = more dangerous
@export var stamina_cost: float = 0.0
@export var oxygen_cost: float = 0.0
@export var water_cost: float = 0.0
@export var wellness_cost: float = 0.0


# Plugin manifest descriptor
class_name CellPluginManifest
extends Resource

@export var name: String = ""
@export var version: String = "1.0.0"
@export var description: String = ""
@export var actions: Array[CellPluginAction] = []
@export var tags: Array[StringName] = []        # ["NETWORK", "DIAGNOSTICS", "SURVIVAL"]
@export var enabled: bool = true
@export var risk_rating: float = 0.0            # 0-1 total plugin danger rating


# Menu node (for in‑game containment console)
class_name CellMenuNode
extends Resource

@export var title: String = ""
@export var command_type: StringName = &""      # e.g. "SystemInfo", "Diagnostics"
@export var children: Array[CellMenuNode] = []
@export var is_leaf: bool = false
@export var icon_id: StringName = &""           # HUD icon key
@export var tooltip: String = ""


# -----------------------------------------------------------------------------
# GLOBAL-LIKE STATE (INSTANCE FIELDS)
# -----------------------------------------------------------------------------

var users: Array[CellUser] = []
var current_user: CellUser = null

var plugins: Array[CellPluginManifest] = []
var root_menu: CellMenuNode = null

var log_entries: Array[String] = []

var exit_requested: bool = false
var menu_history: Array[CellMenuNode] = []
var current_menu: CellMenuNode = null

# References into Cell systems (wired from scene)
@export var vitality_system: PlayerVitalitySystem
@export var fracture_system: FractureSystem
@export var status_hud: Node      # any HUD controller that can show messages


# -----------------------------------------------------------------------------
# LIFECYCLE
# -----------------------------------------------------------------------------

func _ready() -> void:
	_init_users()
	_init_plugins()
	root_menu = _create_main_menu()
	current_menu = root_menu
	_log_message("INFO", "CellBootloaderConsole READY")
	# Authentication would normally be triggered by UI; for dev,
	# auto-login as admin if none set.
	if current_user == null:
		_authenticate_default()
	

# -----------------------------------------------------------------------------
# INITIALIZATION HELPERS
# -----------------------------------------------------------------------------

func _init_users() -> void:
	users.clear()

	var admin := CellUser.new()
	admin.username = "admin"
	admin.password_hash = "admin123" # placeholder
	admin.role = "Admin"
	users.append(admin)

	var tech := CellUser.new()
	tech.username = "tech"
	tech.password_hash = "tech123"
	tech.role = "Tech"
	users.append(tech)

	var survivor := CellUser.new()
	survivor.username = "survivor"
	survivor.password_hash = "cell"
	survivor.role = "User"
	users.append(survivor)


func _init_plugins() -> void:
	plugins.clear()

	# Example diagnostics plugin
	var p_diag := CellPluginManifest.new()
	p_diag.name = "DiagnosticsCore"
	p_diag.version = "1.0.0"
	p_diag.description = "Reads suit vitals, deck stress and containment flags."
	p_diag.tags = [ &"DIAGNOSTICS", &"SURVIVAL" ]
	p_diag.enabled = true

	var a_sys := CellPluginAction.new()
	a_sys.name = "SuitVitalsScan"
	a_sys.description = "Polls Blood/Oxygen/Water/Stamina/Wellness and logs a snapshot."
	a_sys.requires_auth = false
	a_sys.horror_risk = 0.1
	a_sys.stamina_cost = 0.0
	a_sys.oxygen_cost = 1.0
	a_sys.water_cost = 0.0
	a_sys.wellness_cost = 0.0
	p_diag.actions.append(a_sys)

	var a_env := CellPluginAction.new()
	a_env.name = "HullStressProbe"
	a_env.description = "Queries deck hull stress, temperature drift, and contamination spikes."
	a_env.requires_auth = true
	a_env.horror_risk = 0.25
	a_env.stamina_cost = 3.0
	a_env.oxygen_cost = 2.0
	a_env.water_cost = 0.0
	a_env.wellness_cost = 1.0
	p_diag.actions.append(a_env)

	p_diag.risk_rating = 0.2
	plugins.append(p_diag)

	# Example survival tools plugin
	var p_surv := CellPluginManifest.new()
	p_surv.name = "SurvivalTools"
	p_surv.version = "1.1.0"
	p_surv.description = "Emergency routines for ration / oxygen / water hunting."
	p_surv.tags = [ &"SURVIVAL", &"SCAVENGE" ]
	p_surv.enabled = true

	var a_ping := CellPluginAction.new()
	a_ping.name = "ResourcePing"
	a_ping.description = "Attempts to locate nearby caches: ration‑chips, water reclaim tanks, O2 capsules."
	a_ping.requires_auth = false
	a_ping.horror_risk = 0.35
	a_ping.stamina_cost = 8.0
	a_ping.oxygen_cost = 5.0
	a_ping.water_cost = 2.0
	a_ping.wellness_cost = 2.0
	p_surv.actions.append(a_ping)

	var a_bait := CellPluginAction.new()
	a_bait.name = "NoiseBait"
	a_bait.description = "Triggers remote clanks to draw Breathers away from a target corridor."
	a_bait.requires_auth = true
	a_bait.horror_risk = 0.7
	a_bait.stamina_cost = 10.0
	a_bait.oxygen_cost = 3.0
	a_bait.water_cost = 0.0
	a_bait.wellness_cost = 3.0
	p_surv.actions.append(a_bait)

	p_surv.risk_rating = 0.5
	plugins.append(p_surv)

	# Example AI / signal plugin
	var p_signal := CellPluginManifest.new()
	p_signal.name = "SignalWeaver"
	p_signal.version = "0.9.2"
	p_signal.description = "Work with Red Silence howl and AI noise. Dangerous."
	p_signal.tags = [ &"SIGNAL", &"RED_SILENCE", &"PSYCH" ]
	p_signal.enabled = true

	var a_filter := CellPluginAction.new()
	a_filter.name = "HowlFilter"
	a_filter.description = "Dampens Red Silence howl for a short time; reduces Wellness loss from sound."
	a_filter.requires_auth = true
	a_filter.horror_risk = 0.8
	a_filter.stamina_cost = 4.0
	a_filter.oxygen_cost = 1.0
	a_filter.water_cost = 0.0
	a_filter.wellness_cost = 1.5
	p_signal.actions.append(a_filter)

	var a_peek := CellPluginAction.new()
	a_peek.name = "PatternPeek"
	a_peek.description = "Peeks into AI noise shapes; may reveal enemy routes but shakes sanity."
	a_peek.requires_auth = true
	a_peek.horror_risk = 0.95
	a_peek.stamina_cost = 5.0
	a_peek.oxygen_cost = 2.0
	a_peek.water_cost = 0.0
	a_peek.wellness_cost = 6.0
	p_signal.actions.append(a_peek)

	p_signal.risk_rating = 0.9
	plugins.append(p_signal)


func _authenticate_default() -> void:
	# Dev convenience: log in first defined user (admin)
	if users.size() > 0:
		current_user = users[0]
		_log_message("INFO", "Auto-authenticated default user: %s" % current_user.username)


# -----------------------------------------------------------------------------
# AUTH & LOGGING
# -----------------------------------------------------------------------------

func authenticate(username: String, password: String) -> bool:
	for u in users:
		if u.username == username and _verify_password(password, u.password_hash):
			current_user = u
			_log_message("INFO", "User authenticated: %s" % username)
			return true
	_log_message("WARN", "Authentication failed for: %s" % username)
	return false


func _hash_password(password: String) -> String:
	# Placeholder for real hashing. Do NOT use in production.
	return password


func _verify_password(input_password: String, stored_hash: String) -> bool:
	return _hash_password(input_password) == stored_hash


func _log_message(level: String, msg: String) -> void:
	var ts := Time.get_datetime_string_from_system()
	var entry := "[%s] %s: %s" % [ts, level, msg]
	log_entries.append(entry)
	print(entry)


# -----------------------------------------------------------------------------
# MENU BUILDING
# -----------------------------------------------------------------------------

func _create_menu_node(
	title: String,
	command_type: StringName,
	is_leaf: bool,
	icon_id: StringName,
	tooltip: String
) -> CellMenuNode:
	var n := CellMenuNode.new()
	n.title = title
	n.command_type = command_type
	n.is_leaf = is_leaf
	n.icon_id = icon_id
	n.tooltip = tooltip
	return n


func _add_child(parent: CellMenuNode, child: CellMenuNode) -> void:
	parent.children.append(child)


func _create_main_menu() -> CellMenuNode:
	var root := _create_menu_node("Containment Console", &"", false, &"icon_console", "Root console menu.")

	# System
	var sys := _create_menu_node("System", &"OpenSubMenu", false, &"icon_system", "System info and diagnostics.")
	_add_child(sys, _create_menu_node("System Info", &"SystemInfo", true, &"icon_sysinfo", "Suit and deck info."))
	_add_child(sys, _create_menu_node("Diagnostics", &"Diagnostics", true, &"icon_diag", "Run diagnostics."))
	_add_child(sys, _create_menu_node("Logs", &"Logs", true, &"icon_logs", "View recent events."))
	_add_child(root, sys)

	# Survival
	var surv := _create_menu_node("Survival", &"OpenSubMenu", false, &"icon_survival", "Suit survival tools.")
	_add_child(surv, _create_menu_node("Vitals Snapshot", &"VitalsSnapshot", true, &"icon_vitals", "Snapshot current pools."))
	_add_child(surv, _create_menu_node("Resource Ping", &"Survival_ResourcePing", true, &"icon_ping", "Ping for caches."))
	_add_child(surv, _create_menu_node("Noise Bait", &"Survival_NoiseBait", true, &"icon_bait", "Distract enemies with noise."))
	_add_child(root, surv)

	# Signal / Red Silence
	var sig := _create_menu_node("Signal", &"OpenSubMenu", false, &"icon_signal", "Red Silence tools.")
	_add_child(sig, _create_menu_node("Howl Filter", &"Signal_HowlFilter", true, &"icon_filter", "Dampen howl."))
	_add_child(sig, _create_menu_node("Pattern Peek", &"Signal_PatternPeek", true, &"icon_peek", "Glance at AI noise."))
	_add_child(root, sig)

	# Admin
	var admin := _create_menu_node("Admin", &"OpenSubMenu", false, &"icon_admin", "Admin-only settings.")
	_add_child(admin, _create_menu_node("User List", &"Admin_UserList", true, &"icon_users", "List registered users."))
	_add_child(admin, _create_menu_node("Plugin List", &"Admin_PluginList", true, &"icon_plugins", "List loaded plugins."))
	_add_child(root, admin)

	# Power
	var power := _create_menu_node("Power", &"OpenSubMenu", false, &"icon_power", "Exit or soft shutdown.")
	_add_child(power, _create_menu_node("Soft Exit", &"SoftExit", true, &"icon_exit", "Return control to game."))
	_add_child(root, power)

	return root


# -----------------------------------------------------------------------------
# MENU INVOCATION (FOR HUD / DEBUG CONSOLE)
# -----------------------------------------------------------------------------

func get_root_menu() -> CellMenuNode:
	return root_menu


func get_menu_children(node: CellMenuNode) -> Array[CellMenuNode]:
	return node.children


func run_menu_command(cmd: StringName) -> void:
	# Can be called from UI buttons for a given menu node.
	_execute_command(cmd)


# -----------------------------------------------------------------------------
# COMMAND EXECUTION (GD-SCRIPT VERSION OF THE MATLAB LOGIC)
# -----------------------------------------------------------------------------

func _execute_command(command_type: StringName) -> void:
	match command_type:
		&"SystemInfo":
			_cmd_system_info()
		&"Diagnostics":
			_cmd_diagnostics()
		&"Logs":
			_cmd_logs()
		&"VitalsSnapshot":
			_cmd_vitals_snapshot()
		&"Survival_ResourcePing":
			_cmd_survival_resource_ping()
		&"Survival_NoiseBait":
			_cmd_survival_noise_bait()
		&"Signal_HowlFilter":
			_cmd_signal_howl_filter()
		&"Signal_PatternPeek":
			_cmd_signal_pattern_peek()
		&"Admin_UserList":
			_cmd_admin_user_list()
		&"Admin_PluginList":
			_cmd_admin_plugin_list()
		&"SoftExit":
			_cmd_soft_exit()
		_:
			_log_message("WARN", "Unknown command: %s" % str(command_type))


# -----------------------------------------------------------------------------
# COMMAND IMPLEMENTATIONS
# -----------------------------------------------------------------------------

func _cmd_system_info() -> void:
	if vitality_system == null:
		_log_message("ERROR", "Vitals system missing for SystemInfo.")
		return
	var msg := "SYS: B=%.1f/%.1f O2=%.1f/%.1f H2O=%.1f/%.1f STAM=%.1f/%.1f WELL=%.1f/%.1f TEMP=%.1f" % [
		vitality_system.blood, vitality_system.bloodmax,
		vitality_system.oxygen, vitality_system.oxygenmax,
		vitality_system.water, vitality_system.watermax,
		vitality_system.stamina, vitality_system.staminamax,
		vitality_system.wellness, vitality_system.wellnessmax,
		vitality_system.bodytemperature
	]
	_log_message("INFO", msg)
	_emit_hud_message(msg)


func _cmd_diagnostics() -> void:
	# Simulate CPU/memory/IO stress using random ranges
	var cpu := randf_range(32.0, 94.0)
	var mem := randf_range(28.0, 91.0)
	var io := randf_range(10.0, 88.0)
	var msg := "DIAG: CPU=%.1f%% MEM=%.1f%% IO=%.1f%%" % [cpu, mem, io]
	_log_message("INFO", msg)
	_emit_hud_message(msg)


func _cmd_logs() -> void:
	var count := min(10, log_entries.size())
	if count == 0:
		_emit_hud_message("LOG: (no entries)")
		return
	var start := log_entries.size() - count
	for i in range(start, log_entries.size()):
		_emit_hud_message(log_entries[i])


func _cmd_vitals_snapshot() -> void:
	if vitality_system == null:
		_log_message("ERROR", "Vitals system missing for VitalsSnapshot.")
		return
	var msg := "SNAPSHOT: B=%.1f O2=%.1f H2O=%.1f ST=%.1f WELL=%.1f" % [
		vitality_system.blood,
		vitality_system.oxygen,
		vitality_system.water,
		vitality_system.stamina,
		vitality_system.wellness
	]
	_log_message("INFO", msg)
	_emit_hud_message(msg)


func _cmd_survival_resource_ping() -> void:
	var plugin := _find_plugin("SurvivalTools")
	if plugin == null:
		_emit_hud_message("PING: survival tools offline.")
		return
	var action := _find_action(plugin, "ResourcePing")
	if action == null:
		_emit_hud_message("PING: action not found.")
		return
	if not _consume_action_costs(action):
		_emit_hud_message("PING: too weak to ping.")
		return

	# Simulate resource hints
	var found_rations := randf() < 0.65
	var found_water := randf() < 0.45
	var found_o2 := randf() < 0.40

	var msg_parts: Array[String] = []
	if found_rations:
		msg_parts.append("Ration chips: nearby cabin stack.")
	if found_water:
		msg_parts.append("Water reclaim tank: two decks below.")
	if found_o2:
		msg_parts.append("O2 capsule: vent access panel.")
	if msg_parts.is_empty():
		msg_parts.append("No clear resources detected; hull noise only.")
	for m in msg_parts:
		_emit_hud_message("PING: " + m)
	_log_message("INFO", "ResourcePing executed. Results=%s" % str(msg_parts))


func _cmd_survival_noise_bait() -> void:
	if not _require_role("Tech"):
		_emit_hud_message("Noise bait requires Tech or Admin clearance.")
		return

	var plugin := _find_plugin("SurvivalTools")
	if plugin == null:
		_emit_hud_message("BAIT: survival tools offline.")
		return
	var action := _find_action(plugin, "NoiseBait")
	if action == null:
		_emit_hud_message("BAIT: action not found.")
		return
	if not _consume_action_costs(action):
		_emit_hud_message("BAIT: too exhausted to deploy bait.")
		return

	# Simulate enemy shift
	var success := randf() < 0.7
	if success:
		_emit_hud_message("BAIT: clanks deployed; Breathers drifting off‑path.")
	else:
		_emit_hud_message("BAIT: sound misfired; corridor noise rising.")
		# Extra panic / wellness hit
		if vitality_system != null:
			vitality_system.wellness = max(0.0, vitality_system.wellness - 4.0)
	_log_message("INFO", "NoiseBait executed, success=%s" % str(success))


func _cmd_signal_howl_filter() -> void:
	if not _require_role("Admin"):
		_emit_hud_message("Howl Filter requires Admin clearance.")
		return

	var plugin := _find_plugin("SignalWeaver")
	if plugin == null:
		_emit_hud_message("FILTER: signal weaver offline.")
		return
	var action := _find_action(plugin, "HowlFilter")
	if action == null:
		_emit_hud_message("FILTER: action not found.")
		return
	if not _consume_action_costs(action):
		_emit_hud_message("FILTER: your hands shake too much to tune it.")
		return

	_emit_hud_message("FILTER: howl damped. Wellness drain reduced briefly.")
	_log_message("INFO", "HowlFilter engaged.")
	# Here you could set a short-lived buff in FractureSystem or a BuffSystem


func _cmd_signal_pattern_peek() -> void:
	if not _require_role("Admin"):
		_emit_hud_message("Pattern Peek requires Admin clearance.")
		return

	var plugin := _find_plugin("SignalWeaver")
	if plugin == null:
		_emit_hud_message("PEEK: signal weaver offline.")
		return
	var action := _find_action(plugin, "PatternPeek")
	if action == null:
		_emit_hud_message("PEEK: action not found.")
		return
	if not _consume_action_costs(action):
		_emit_hud_message("PEEK: your skull feels too thin to try again.")
		return

	var route_hint := randf() < 0.6
	if route_hint:
		_emit_hud_message("PEEK: corridor overlay flashes a safer flank route.")
	else:
		_emit_hud_message("PEEK: nothing but static and bone‑deep pressure.")
	# Extra wellness damage from horror
	if vitality_system != null:
		vitality_system.wellness = max(0.0, vitality_system.wellness - 5.0)
	_log_message("INFO", "PatternPeek executed, route_hint=%s" % str(route_hint))


func _cmd_admin_user_list() -> void:
	if not _require_role("Admin"):
		_emit_hud_message("User list requires Admin clearance.")
		return
	for u in users:
		_emit_hud_message("USER: %s (%s)" % [u.username, u.role])
	_log_message("INFO", "Admin_UserList executed.")


func _cmd_admin_plugin_list() -> void:
	if not _require_role("Admin"):
		_emit_hud_message("Plugin list requires Admin clearance.")
		return
	for p in plugins:
		_emit_hud_message("PLUGIN: %s v%s (enabled=%s, risk=%.2f)" % [
			p.name, p.version, str(p.enabled), p.risk_rating
		])
	_log_message("INFO", "Admin_PluginList executed.")


func _cmd_soft_exit() -> void:
	exit_requested = true
	_emit_hud_message("Console: soft exit requested. Control returns to runtime.")
	_log_message("INFO", "SoftExit requested from console.")


# -----------------------------------------------------------------------------
# INTERNAL HELPERS
# -----------------------------------------------------------------------------

func _find_plugin(name: String) -> CellPluginManifest:
	for p in plugins:
		if p.name == name:
			return p
	return null


func _find_action(plugin: CellPluginManifest, action_name: String) -> CellPluginAction:
	for a in plugin.actions:
		if a.name == action_name:
			return a
	return null


func _consume_action_costs(action: CellPluginAction) -> bool:
	if vitality_system == null:
		return true
	var total_stam := action.stamina_cost
	var total_o2 := action.oxygen_cost
	var total_h2o := action.water_cost
	var total_well := action.wellness_cost

	if vitality_system.stamina < total_stam:
		return false
	if vitality_system.oxygen < total_o2:
		return false
	if vitality_system.water < total_h2o:
		return false
	if vitality_system.wellness < total_well:
		return false

	vitality_system.stamina = max(0.0, vitality_system.stamina - total_stam)
	vitality_system.oxygen = max(0.0, vitality_system.oxygen - total_o2)
	vitality_system.water = max(0.0, vitality_system.water - total_h2o)
	vitality_system.wellness = max(0.0, vitality_system.wellness - total_well)
	return true


func _require_role(required_role: String) -> bool:
	if current_user == null:
		return false
	if current_user.role == "Admin":
		return true
	if current_user.role == required_role:
		return true
	return false


func _emit_hud_message(msg: String) -> void:
	if status_hud != null and status_hud.has_method("push_console_line"):
		status_hud.push_console_line(msg)
	else:
		print("HUD:", msg)
