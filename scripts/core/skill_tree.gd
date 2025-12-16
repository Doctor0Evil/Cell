extends Resource
class_name SkillTree

@export var skills: Array[SkillDefinition] = []
@export var links: Dictionary = {} # root_skill_id -> Array[child_skill_ids]

func get_skill(id: StringName) -> SkillDefinition:
    for s in skills:
        if s.id == id:
            return s
    return null

func get_children(id: StringName) -> Array[StringName]:
    if links.has(id):
        return links[id]
    return []
