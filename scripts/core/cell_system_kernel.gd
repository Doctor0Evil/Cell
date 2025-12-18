extends Node
class_name CellSystemKernel

# Core runtime configuration for Cell's in‑engine "Director" shell.
# This node should be autoloaded as "CellSystemKernel" in Project Settings.

const VERSION: String = "1.0.0"
const ENVIRONMENT: String = "production"

# High‑level feature flags for IDE agents and runtime checks.
const FEATURE_FLAGS := {
	"realtime_sync": true,
	"cross_platform": true,
	"telemetry_logging": true,
	"responsive_ui": true,
	"director_ai": true
}

# -------------------------------------------------------------------
# TIME PARSER – hardened, Cell‑style timestamp parsing
# -------------------------------------------------------------------
# Expected format: "YYYY.MMDD.HH.MM.SS"
# Example: "2079.1103.18.42.09"
# Returns: (year, month, day, hour, minute, second, valid)
static func parse_time_string(timestr: String) -> Dictionary:
	var pattern := r"^(\d{4})\.?(\d{2})(\d{2})\.(\d{2})\.(\d{2})$"
	var regex := RegEx.new()
	var compile_err := regex.compile(pattern)
	if compile_err != OK:
		return {
			"year": 0, "month": 0, "day": 0,
			"hour": 0, "minute": 0, "second": 0,
			"valid": false
		}
	var result := regex.search(timestr)
	if result == null:
		return {
			"year": 0, "month": 0, "day": 0,
			"hour": 0, "minute": 0, "second": 0,
			"valid": false
		}

	var year  := int(result.get_string(1))
	var month := int(result.get_string(2))
	var day   := int(result.get_string(3))
	var hour  := int(result.get_string(4))
	var minute:= int(result.get_string(5))
	var second:= 0

	var valid := (
		year >= 2000 and year <= 2150 and
		month >= 1 and month <= 12 and
		day >= 1 and day <= 31 and
		hour >= 0 and hour <= 23 and
		minute >= 0 and minute <= 59 and
		second >= 0 and second <= 59
	)

	return {
		"year": year,
		"month": month,
		"day": day,
		"hour": hour,
		"minute": minute,
		"second": second,
		"valid": valid
	}

static func now_compact_stamp() -> String:
	# Uses OS time; in‑world you can replace with GameState’s mission clock.
	var dt := Time.get_datetime_dict_from_system()
	return "%04d.%02d%02d.%02d.%02d" % [
		dt.year, dt.month, dt.day, dt.hour, dt.minute
	]
