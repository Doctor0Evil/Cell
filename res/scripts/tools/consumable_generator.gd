@tool
extends Node
class_name ConsumableGenerator

# Editor tool: parse a simple consumables list and write ConsumableDefinition .tres files
# Usage: ConsumableGenerator.generate_from_file("res://res/data/consumables_list.txt")
# Writes files to res://res/data/consumables/con_<id>.tres

const FIELD_MAP = {
	"strength": "tenacity_delta",
	"instinct": "instinct_delta",
	"vitality": "vitality_delta",
	"tenacity": "tenacity_delta",
	"agility": "agility_delta",
	"logic": "logic_delta",
	"influence": "influence_delta",
	"temper": "temper_delta",
	"yield": "yield_delta",
	"oxygen": "oxygen_delta",
	"blood": "blood_delta",
	"stamina": "stamina_delta",
	"wellness": "wellness_delta",
	"bodytemp": "body_temp_delta",
	"body_temp": "body_temp_delta",
	"protein": "protein_delta"
}

static func _parse_deltas(text: String) -> Dictionary:
	# examples: +Strength4, +Instinct+0.3, -Wellness-2.0
	var out := {}
	for token in text.split(","):
		token = token.strip_edges().strip_prefix("+").strip_prefix("-")
		if token == "":
			continue
		# split alpha vs numeric
		var m := token.match("^([A-Za-z_]+)\+?(-?\d+\.?\d*)$")
		if not m:
			m = token.match("^([A-Za-z_]+)(-?\d+\.?\d*)$")
		if m:
			var k = m[1].to_lower()
			var v = float(m[2])
			if FIELD_MAP.has(k):
				out[FIELD_MAP[k]] = v
			else:
				out[k] = v
	return out

static func _nicify_id(id: String) -> String:
	var s := id.replace("-", " ").replace("_", " ")
	var words := []
	for w in s.split(" "):
		if w.strip_edges() == "":
			continue
		words.append(w.capitalize())
	return " ".join(words)

static func generate_from_file(list_path: String, out_dir: String = "res://res/data/consumables") -> int:
	if not FileAccess.file_exists(list_path):
		push_warning("ConsumableGenerator: list file not found: %s" % list_path)
		return 0

	var f := FileAccess.open(list_path, FileAccess.READ)
	var content := f.get_as_text()
	f.close()

	var entries := []
	var lines := content.split("\n")
	var cur := null
	for ln in lines:
		if ln.strip_edges() == "":
			continue
		if ln.strip_edges().begins_with("-"):
			# new entry header
			if cur != null:
				entries.append(cur)
			cur = {"id": "", "delta_line": "", "meta_line": "", "extra_lines": []}
			# id is up to first whitespace after dash
			var tok := ln.strip_edges().lstrip("-")
			var parts := tok.split(" ")
			cur["id"] = parts[0].strip_edges()
			# capture remainder as a delta line if present
			var rem := tok.substr(parts[0].length()).strip_edges()
			if rem != "":
				cur["delta_line"] = rem
		else:
			# continuation metadata lines
			if cur != null:
				cur["extra_lines"].append(ln.strip_edges())

	if cur != null:
		entries.append(cur)

	# ensure output dir exists
	var da := DirAccess.open(out_dir)
	if not da:
		DirAccess.make_dir_recursive(out_dir)

	var generated := 0
	for e in entries:
		var id := e["id"]
		var deltas := {}
		if e["delta_line"] != "":
			# strip surrounding brackets if present
			var dl := e["delta_line"].strip_prefix("[").strip_suffix("]")
			deltas = _parse_deltas(dl)

		var meta := {"addiction_channel":"", "withdrawal_template":"", "duration":"", "safe_stack":1, "min_yield":0.0, "tags": []}
		for ln in e["extra_lines"]:
			var l := ln
			if l.begins_with("[") and l.ends_with("]"):
				l = l.strip_prefix("[").strip_suffix("]").strip_edges()
			# parse kv style or tags style
			if l.find(":") != -1 and l.find("tags") == -1:
				# key=val pairs separated by commas
				for kv in l.split(","):
					var pair := kv.split("=")
					if pair.size() == 2:
						var k := pair[0].strip_edges()
						var v := pair[1].strip_edges()
						if k == "addiction_channel":
							meta.add("addiction_channel", v)
						elif k == "withdrawal_template":
							meta.add("withdrawal_template", v)
						elif k == "duration":
							meta.add("duration", v)
						elif k == "safe_stack":
							meta["safe_stack"] = int(v)
						elif k == "min_yield":
							meta["min_yield"] = float(v)
			elif l.begins_with("tags"):
				var colon := l.find(":")
				if colon != -1:
					var tagstr := l.substr(colon+1).strip_edges()
					for t in tagstr.split(","):
						meta["tags"].append(t.strip_edges())

		# Build ConsumableDefinition
		var c := ConsumableDefinition.new()
		c.id = StringName("con_" + id.replace("-","_") )
		c.display_name = _nicify_id(id)
		c.category = &"consumable"
		c.rarity = &"common"
		c.max_stack = meta["safe_stack"]
		c.safe_stack_limit = meta["safe_stack"]
		c.min_yield_required = meta["min_yield"]
		c.tags = []
		# apply deltas
		for k in deltas.keys():
			if c.has_property(k):
				c.set(k, deltas[k])
			else:
				# unknown mapping: store as meta tag
				c.tags.append(StringName("meta:" + k + "=" + str(deltas[k])))

		# apply meta tags
		if meta["addiction_channel"] != "":
			c.tags.append(StringName("addiction:" + meta["addiction_channel"]))
		if meta["withdrawal_template"] != "":
			c.tags.append(StringName("withdrawal:" + meta["withdrawal_template"]))
		for t in meta["tags"]:
			c.tags.append(StringName(t))

		# sensible defaults for value / stack / icons
		c.base_value_chips = 50
		c.weight_kg = 0.05
		c.volume_l = 0.02

		# save resource file
		var oname := out_dir.plus_file("con_%s.tres" % id.replace("-","_") )
		var err := ResourceSaver.save(oname, c)
		if err == OK:
			generated += 1
		else:
			push_warning("ConsumableGenerator: failed to save %s (err=%d)" % [oname, err])

	print("ConsumableGenerator: generated %d consumables from %s" % [generated, list_path])
	return generated
