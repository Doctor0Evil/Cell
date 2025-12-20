# File: res://cell/creatures/creature_generation_config.gd
# j.s.f-style generation config translated to GDScript.

class_name CellCreatureGenerationConfig
extends Resource

var input: Dictionary = {
	"source_spec_path": "",
	"output_namespace": ""
}

var targets: Dictionary = {
	"generate_2d_concepts": true,
	"generate_3d_prompt": true,
	"generate_lore": true
}

var constraints: Dictionary = {
	"universe": "CELL_CORE_CANON",
	"style_lock": [],
	"prohibited_motifs": [],
	"asset_requirements": [],
	"rights_enforcement": []
}

var generator: Dictionary = {
	"two_d": {
		"views": [],
		"prompt_template": ""
	},
	"three_d": {
		"prompt_template": ""
	},
	"lore": {
		"prompt_template": ""
	}
}

var compliance: Dictionary = {
	"attach_invisible_watermark": true,
	"record_generation_summary": true,
	"log_fields": []
}


func to_dict() -> Dictionary:
	return {
		"input": input,
		"targets": targets,
		"constraints": constraints,
		"generator": generator,
		"compliance": compliance
	}


static func from_dict(data: Dictionary) -> CellCreatureGenerationConfig:
	var cfg := CellCreatureGenerationConfig.new()
	if data.has("input"): cfg.input = data.input
	if data.has("targets"): cfg.targets = data.targets
	if data.has("constraints"): cfg.constraints = data.constraints
	if data.has("generator"): cfg.generator = data.generator
	if data.has("compliance"): cfg.compliance = data.compliance
	return cfg
