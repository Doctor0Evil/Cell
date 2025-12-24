extends Node
class_name CellIDERateGuard

# Lightweight, client-side throttle for IDE / MCP / assistant integrations.
# Attach as an autoload or instantiate inside your tooling bridge.

const WINDOW_SECONDS: float = 60.0
const MAX_REQUESTS_PER_WINDOW: int = 45  # Keep well below typical 60/hour unauthenticated & 1,000/hour GITHUB_TOKEN repo limits.

var _window_start_time: float = 0.0
var _request_count_in_window: int = 0

signal rate_window_reset(new_window_start_time: float)
signal request_allowed(current_count: int, remaining_in_window: int)
signal request_blocked(current_count: int)

func _ready() -> void:
	_window_start_time = Time.get_unix_time_from_system()

func _reset_window_if_needed(now: float) -> void:
	if now - _window_start_time >= WINDOW_SECONDS:
		_window_start_time = now
		_request_count_in_window = 0
		emit_signal("rate_window_reset", _window_start_time)

func can_send_request() -> bool:
	var now := Time.get_unix_time_from_system()
	_reset_window_if_needed(now)
	if _request_count_in_window < MAX_REQUESTS_PER_WINDOW:
		return true
	return false

func register_request() -> void:
	var now := Time.get_unix_time_from_system()
	_reset_window_if_needed(now)
	_request_count_in_window += 1
	if _request_count_in_window <= MAX_REQUESTS_PER_WINDOW:
		emit_signal("request_allowed", _request_count_in_window, MAX_REQUESTS_PER_WINDOW - _request_count_in_window)
	else:
		emit_signal("request_blocked", _request_count_in_window)

func get_window_info() -> Dictionary:
	var now := Time.get_unix_time_from_system()
	var elapsed := now - _window_start_time
	return {
		"window_start_time": _window_start_time,
		"elapsed": elapsed,
		"remaining_seconds": max(WINDOW_SECONDS - elapsed, 0.0),
		"count": _request_count_in_window,
		"max": MAX_REQUESTS_PER_WINDOW
	}
