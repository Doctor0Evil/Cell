extends Resource
class_name RegionNavData

# Serialized nav structures for AI and pathing
@export var nav_mesh_path: String = ""
@export var nav_regions: Array = []
@export var anchor_points: Array = []
@export var marker_points: Array = []
@export var grid_size: int = 1
