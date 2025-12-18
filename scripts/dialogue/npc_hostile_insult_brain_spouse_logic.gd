extends Resource
class_name HostileInsultBrainSpouseLogic

var emotions := {
	"wary":        0.92,
	"frustrated":  0.82,
	"impatience":  0.78,
	"skepticism":  0.96,
	"pragmatic":   1.0,
	"aggression":  0.88,
}

var priorities := {
	"group_wellbeing":   1.0,
	"outsider_trust":    0.04,
	"territory_defense": 0.97,
	"survival_focus":    0.90,
}

var humor_policy := {
	"mode": "auto",               # "auto", "force_none", "force_grim"
	"frustrated_hard_cap": 0.85,
	"aggression_hard_cap": 0.90,
}

var insult_map: Array = [
	{"key": "intelligence",         "handler": "intelligence_reversal"},
	{"key": "partner_mock",         "handler": "human_norms_rejection"},
	{"key": "death_joke",           "handler": "death_seriousness"},
	{"key": "territory_disrespect", "handler": "territory_boundary"},
]

var rng := RandomNumberGenerator.new()

func _init() -> void:
	rng.randomize()


func respond(user_input: String) -> String:
	_apply_state_updates()
	var line := _handle_insult(user_input)
	_log_response(user_input, line)
	return line


func _handle_insult(user_input: String) -> String:
	var segments: Array[String] = []
	segments.append(_intelligence_reversal(user_input))
	segments.append(_human_norms_rejection(user_input))
	segments.append(_death_seriousness(user_input))
	segments.append(_territory_boundary(user_input))
	segments.append(_humor_maybe(user_input))
	return _concatenate_segments(segments)


func _contains(haystack: String, needle: String) -> bool:
	return haystack.to_lower().find(needle.to_lower()) != -1


func _intelligence_reversal(input: String) -> String:
	if _contains(input, "brain") or _contains(input, "idiot"):
		return "You throw cheap brain jokes while walking into a hostile zone half-starved, half-frozen, and loud. That is not intelligence; that is a slow-motion suicide note. "
	return ""


func _human_norms_rejection(input: String) -> String:
	if _contains(input, "wife") or _contains(input, "husband") or _contains(input, "first base"):
		return "You reach for playground talk about partners like that means anything here. Out here, the only thing that counts is who still stands beside you when the alarms fail and the walls start breathing. "
	return ""


func _death_seriousness(input: String) -> String:
	if _contains(input, "before you die") or _contains(input, "die") or _contains(input, "death"):
		return "You talk about dying like it is a punchline. In this place, death is not a joke; it is a slow negotiation with cold, infection, and whatever is scraping on the other side of the bulkhead. "
	return ""


func _territory_boundary(input: String) -> String:
	return "This is not a bar where words disappear into the noise. Every insult you spit lands on people holding themselves together with bad sleep, empty oxygen gauges, and nerves one whisper away from breaking. Keep talking, and this stops being a conversation and starts being cleanup. "


func _apply_state_updates() -> void:
	emotions["aggression"] = emotions["aggression"] + 0.12
	emotions["frustrated"] = emotions["frustrated"] + 0.10
	emotions["wary"] = emotions["wary"] + 0.05
	priorities["outsider_trust"] = max(0.0, priorities["outsider_trust"] - 0.02)


func _humor_mode_current() -> String:
	var mode: String = str(humor_policy.get("mode", "auto"))
	if mode == "force_none":
		return "none"
	if mode == "force_grim":
		return "grim"

	if emotions["frustrated"] > float(humor_policy["frustrated_hard_cap"]):
		return "none"
	if emotions["aggression"] > float(humor_policy["aggression_hard_cap"]):
		return "none"
	return "grim"


func _humor_maybe(input: String) -> String:
	var mode := _humor_mode_current()
	if mode == "none":
		return ""

	var roll := rng.randf_range(0.0, 1.0)
	if roll > 0.12:
		return ""

	if _contains(input, "brain"):
		return "Relax. No one is here to steal your brain; whatever you brought in clearly was not top-shelf to begin with. "
	elif _contains(input, "wife") or _contains(input, "husband"):
		return "If you are flirting by calling people monsters, you are worse at courtship than you are at staying alive. "
	else:
		return "Keep joking. The station loves new last words. "


func _concatenate_segments(segments: Array) -> String:
	var out := ""
	for s in segments:
		if typeof(s) == TYPE_STRING and s != "":
			out += s
	return out


func _log_response(user_input: String, output: String) -> void:
	# Replace with your central DebugLog system call if available.
	print_debug({
		"source": "Hostile Insult-Intelligence-Partner Logic",
		"input": user_input,
		"output": output,
		"state": emotions,
		"priorities": priorities,
		"humor_mode": _humor_mode_current(),
	})
