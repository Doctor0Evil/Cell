extends Node3D
class_name AshveilDetailPlacer

@export var region_id: StringName = AshveilAssetTags.REGION_ID
@export var tilemap_path: NodePath
@export var petrified_scenes: Array[PackedScene] = []
@export var slag_arch_scenes: Array[PackedScene] = []
@export var buried_vehicle_scenes: Array[PackedScene] = []
@export var safety_station_scene: PackedScene

var _rng := RandomNumberGenerator.new()

func _ready() -> void:
    _rng.seed = hash(str(region_id, ":", OS.get_unix_time()))
    var tm: Node = get_node_or_null(tilemap_path)
    if tm == null:
        push_warning("AshveilDetailPlacer: TileMapLayer3D missing")
        return
    _scatter_detail(tm)

func _scatter_detail(tm) -> void:
    if not tm.has_method("get_used_cells"):
        push_warning("AshveilDetailPlacer: tilemap API missing get_used_cells")
        return
    for cell in tm.get_used_cells():
        var td = null
        if tm.has_method("get_cell_tile_data"):
            td = tm.get_cell_tile_data(cell)
        var tag := ""
        if td and td.has_method("get_custom_data"):
            tag = str(td.get_custom_data("ash_tag"))
        match tag:
            "ASH_PLAIN":
                if _rng.randf() < 0.02:
                    _place_petrified_cluster(tm, cell)
            "BURIED_ROAD":
                if _rng.randf() < 0.015:
                    _place_buried_vehicle(tm, cell)
            "ASH_DUNE":
                if _rng.randf() < 0.01:
                    _place_slag_arch(tm, cell)

        if td and bool(td.get_custom_data("safety_station")) and safety_station_scene:
            _place_single(tm, cell, safety_station_scene)

func _place_petrified_cluster(tm, cell: Vector2i) -> void:
    if petrified_scenes.is_empty():
        return
    var count := 2 + _rng.randi_range(0, 3)
    for i in count:
        var scene := petrified_scenes[_rng.randi_range(0, petrified_scenes.size() - 1)]
        _place_single(tm, cell, scene, 0.5, true)

func _place_buried_vehicle(tm, cell: Vector2i) -> void:
    if buried_vehicle_scenes.is_empty():
        return
    var scene := buried_vehicle_scenes[_rng.randi_range(0, buried_vehicle_scenes.size() - 1)]
    _place_single(tm, cell, scene, 0.0, false)

func _place_slag_arch(tm, cell: Vector2i) -> void:
    if slag_arch_scenes.is_empty():
        return
    var scene := slag_arch_scenes[_rng.randi_range(0, slag_arch_scenes.size() - 1)]
    _place_single(tm, cell, scene, -0.2, false)

func _place_single(tm, cell: Vector2i, scene: PackedScene, y_offset: float = 0.0, mark_petrified: bool = false) -> void:
    var inst := scene.instantiate()
    var local := tm.map_to_local(cell) if tm.has_method("map_to_local") else Vector2(cell.x, cell.y)
    inst.translation = Vector3(local.x, y_offset, local.y)
    inst.rotation.y = _rng.randf() * TAU
    add_child(inst)
    if mark_petrified:
        inst.add_to_group("ashveil_petrified")
    # Snap to nearest surface normal if TileMapLayer3D exposes that (best-effort)
    if inst is Node3D:
        inst.set_physics_process(false)
