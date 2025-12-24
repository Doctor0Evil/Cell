Run the consumable generator to create .tres ConsumableDefinition resources from the text list:

1) Open the project in Godot editor.
2) In a script or the editor console, run:
   ConsumableGenerator.generate_from_file("res://res/data/consumables_list.txt")

This will write files to res://res/data/consumables/con_<id>.tres and they will be auto-loaded into the AssetDatabase at startup.

Notes:
- The parser is conservative and stores unknown fields as meta tags.
- If you want to adjust archetypes, edit res://res/scripts/core/data/consumable_archetype_registry.gd
