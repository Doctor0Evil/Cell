extends Node
class_name CellSecurity

# Sanitizes freeform text before it hits logging / mission scripts.

static func sanitize_input(text_in: String, max_len: int = 512) -> String:
	var regex := RegEx.new()
	# Keep letters, digits, underscores, dashes, spaces, dots, colons.
	var pattern := r"[^a-zA-Z0-9 _\-\.:]"
	var err := regex.compile(pattern)
	if err != OK:
		return text_in.left(max_len)
	var cleaned := regex.sub(text_in, "", true)
	if cleaned.length() > max_len:
		cleaned = cleaned.substr(0, max_len)
	return cleaned

# Minimal “platform” detection; in Cell this is mostly for debug labeling.
static func detect_platform() -> String:
	var os_name := OS.get_name().to_lower()
	if os_name.find("windows") != -1:
		return "windows"
	if os_name.find("linux") != -1:
		return "linux"
	if os_name.find("bsd") != -1:
		return "bsd"
	if os_name.find("mac") != -1:
		return "mac"
	return "unknown"

static func is_supported_platform() -> bool:
	var p := detect_platform()
	return p in ["windows", "linux", "bsd", "mac"]
