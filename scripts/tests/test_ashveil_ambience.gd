extends Node3D

func _ready() -> void:
    var amb := $AmbiencePlayer
    var ctrl := $AmbienceController
    ctrl.ambience_player_path = amb.get_path()
    ctrl.profile = preload("res://resources/ambience/ashveil_ambience_profile.gd").new()
    ctrl._ready()
    DebugLog.log("TestAshveilAmbience", "SMOKE", {"status": "started"})
    # Set a debug tension bias and play a stinger after 1s
    await get_tree().create_timer(1.0).timeout
    amb.set_debug_tension_override(0.5)
    await get_tree().create_timer(0.5).timeout
    ctrl._scan_petrified_nodes()
    if ctrl.profile.stingers_collapse.size() > 0:
        amb.play_stinger(ctrl.profile.stingers_collapse[0])

    # Initialize the 3D controller and fire a test event (placeholder players may be silent until assets are assigned)
    var ctrl3d := $AmbienceController3D
    ctrl3d._ready()
    # register as active controller for debug hooks
    GameState.extreme_ambience_controller = ctrl3d
    # Allow previewing the real Ashveil profile directly from the test scene
    ctrl3d.preview_profile_id = &"ASHVEIL_DEBRIS_STRATUM"
    # Apply a simulated region profile if available
    var region_def := preload("res://resources/ambience/ashveil_ambience_profile.gd").new()
    if ctrl3d.has_method("apply_region_profile"):
        ctrl3d.apply_region_profile({"oxygen_penalty": 0.5}, 2)
    await get_tree().create_timer(0.25).timeout
    ctrl3d.trigger_evac_memory_event()

    # Log a preview of the tuning curves
    if ctrl3d.has_method("preview_tuning_sweep"):
        ctrl3d.preview_tuning_sweep(6)

    # Lightweight debug overlay loop: log next-fire times, intensity, and last-picked players
    for i in 6:
        var debug_info := {
            "next_roar_in": ctrl3d.get_next_roar_in(),
            "next_creak_in": ctrl3d.get_next_creak_in(),
            "intensity": ctrl3d.get_effective_intensity(),
            "last_roar": ctrl3d.get_last_roar_player_name(),
            "last_creak": ctrl3d.get_last_creak_player_name()
        }
        DebugLog.log("TestAshveilAmbience", "DEBUG", debug_info)
        # Occasionally fire a collapse event to confirm roars trigger
        if i == 2:
            ctrl3d.trigger_collapse_event()
        await get_tree().create_timer(1.0).timeout

    DebugLog.log("TestAshveilAmbience", "SMOKE_DONE", {})