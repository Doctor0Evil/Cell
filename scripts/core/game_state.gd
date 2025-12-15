extends Node
class_name GameState

# Global game flags and tunables for Cell.

var player_health: int = 100
var player_sanity: float = 1.0        # 0.0–1.0, affects visuals and audio
var alert_level: float = 0.0          # 0.0–1.0, how “awake” the facility is
var current_save_slot: int = 0
var is_paused: bool = false

var inventory: Array = []             # Will be populated with item dicts

# Runtime metrics for telemetry / balancing.
var play_time_seconds: int = 0
var death_count: int = 0

func _process(delta: float) -> void:
    if is_paused:
        return
    play_time_seconds += int(delta)

func apply_damage(amount: int) -> void:
    player_health = max(0, player_health - amount)
    if player_health == 0:
        _on_player_death()

func modify_sanity(delta_sanity: float) -> void:
    player_sanity = clamp(player_sanity + delta_sanity, 0.0, 1.0)

func modify_alert(delta_alert: float) -> void:
    alert_level = clamp(alert_level + delta_alert, 0.0, 1.0)

func _on_player_death() -> void:
    death_count += 1
    get_tree().call_group("runtime", "on_player_death_global")
