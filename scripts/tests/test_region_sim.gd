extends Node

func _ready() -> void:
    var sim := RegionSimManager.new()
    add_child(sim)
    sim.register_region(&"ASHVEIL_DEBRIS_STRATUM", ["ASHVEIL_DRIFT", "DEBRIS_STRATUM"])
    # Run several simulated steps
    sim.simulate_region(&"ASHVEIL_DEBRIS_STRATUM", 240.0) # 4 hours
    var snap := sim.get_debug_snapshot()
    DebugLog.log("TestRegionSim", "SMOKE", snap)
    assert(snap.has("ASHVEIL_DEBRIS_STRATUM"))
    print("RegionSim smoke test passed: ", snap["ASHVEIL_DEBRIS_STRATUM"])