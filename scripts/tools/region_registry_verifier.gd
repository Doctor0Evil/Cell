extends Node

func run_verification() -> Dictionary:
    var registry := CellContentRegistry.new()
    var report := {}
    for id in registry.regions.keys():
        var d := registry.get_region(id)
        var problems := []
        var scene := String(d.get("scene_path", ""))
        if scene == "" or not ResourceLoader.exists(scene):
            problems.append("scene_missing: %s" % scene)
        var runtime := String(d.get("runtime_script_path", ""))
        if runtime == "":
            problems.append("runtime_missing_path")
        elif not ResourceLoader.exists(runtime):
            problems.append("runtime_not_found: %s" % runtime)
        if problems.size() > 0:
            report[id] = problems
    if report.size() == 0:
        DebugLog.log("RegionVerifier", "OK", {})
    else:
        DebugLog.log("RegionVerifier", "PROBLEMS", report)
    return report
