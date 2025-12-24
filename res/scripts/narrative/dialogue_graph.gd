extends Resource
class_name DialogueGraph

const NODE_LINE := "line"
const NODE_CHOICE := "choice"
const NODE_END := "end"

class DialogueNode:
	var id: StringName
	var type: StringName
	var speaker: StringName
	var text: String = ""
	var next: StringName = &""
	var choices: Array = []

class DialogueChoice:
	var id: StringName
	var text: String
	var label: String = ""
	var action_type: StringName = "DIALOGUE_BRANCH"
	var action_payload: Dictionary = {}
	var conditions: Array = []
	var checks: Array = []
	var effects: Array = []
	var effects_success: Array = []
	var effects_fail: Array = []
	var next: StringName = &""
	var on_success_next: StringName = &""
	var on_fail_next: StringName = &""

var id: StringName
var title: String
var meta := {}
var nodes: Dictionary = {}

static func from_dict(data: Dictionary) -> DialogueGraph:
	var g := DialogueGraph.new()
	g.id = StringName(data.get("id", ""))
	g.title = data.get("title", "")
	g.meta = data.get("meta", {})
	for n_dict in data.get("nodes", []):
		var n := DialogueNode.new()
		n.id = StringName(n_dict.get("id", ""))
		n.type = StringName(n_dict.get("type", "line"))
		n.speaker = StringName(n_dict.get("speaker", ""))
		n.text = n_dict.get("text", "")
		n.next = StringName(n_dict.get("next", ""))
		if n.type == NODE_CHOICE:
			n.choices = []
			for c_dict in n_dict.get("choices", []):
				var c := DialogueChoice.new()
				c.id = StringName(c_dict.get("id", ""))
				c.text = c_dict.get("text", "")
				c.label = c_dict.get("label", "")
				c.action_type = StringName(c_dict.get("action_type", "DIALOGUE_BRANCH"))
				c.action_payload = c_dict.get("action_payload", {})
				c.conditions = c_dict.get("conditions", [])
				c.checks = c_dict.get("checks", [])
				c.effects = c_dict.get("effects", [])
				c.effects_success = c_dict.get("effects_success", [])
				c.effects_fail = c_dict.get("effects_fail", [])
				c.next = StringName(c_dict.get("next", ""))
				c.on_success_next = StringName(c_dict.get("on_success_next", ""))
				c.on_fail_next = StringName(c_dict.get("on_fail_next", ""))
				n.choices.append(c)
		g.nodes[n.id] = n
	return g

func get_node(node_id: StringName) -> DialogueNode:
	return nodes.get(node_id, null)
