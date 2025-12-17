extends Node
class_name DebugLog

const LOG_TO_FILE := false
const LOG_FILE := "user://cell_debug_log.txt"

static func log(source: String, event: String, data = null) -> void:
    var payload := {
        "time": Time.get_unix_time_from_system(),
        "source": source,
        "event": event,
        "data": data
    }
    var line := JSON.stringify(payload)
    print(line)
    if LOG_TO_FILE:
        var f := FileAccess.open(LOG_FILE, FileAccess.WRITE_READ)
        if f:
            f.seek_end()
            f.store_line(line)
            f.flush()
