extends Resource
class_name SettlementPools

@export var oxygen: float = 1000.0
@export var oxygen_max: float = 1000.0

@export var rations: float = 500.0
@export var rations_max: float = 500.0

@export var research: float = 0.0
@export var research_max: float = 1000.0

@export var manpower: int = 50
@export var manpower_max: int = 100

var days_without_oxygen: int = 0
var days_starving: int = 0

func tick_daily_consumption() -> void:
    if manpower <= 0:
        return

    var oxy_use := manpower * 1.5
    var ration_use := manpower * 0.8

    oxygen = max(0.0, oxygen - oxy_use)
    rations = max(0.0, rations - ration_use)

    if oxygen <= 0.0:
        days_without_oxygen += 1
        manpower = max(0, manpower - 4)
    else:
        days_without_oxygen = 0

    if rations <= 0.0:
        days_starving += 1
        manpower = max(0, manpower - 2)
    else:
        days_starving = 0

func add_oxygen(amount: float) -> void:
    oxygen = min(oxygen_max, oxygen + amount)

func add_rations(amount: float) -> void:
    rations = min(rations_max, rations + amount)

func add_research(amount: float) -> void:
    research = clamp(research + amount, 0.0, research_max)

func add_manpower(amount: int) -> void:
    manpower = clamp(manpower + amount, 0, manpower_max)

func get_collapse_state() -> String:
    if oxygen <= 0.0 and manpower <= 0:
        return "DEAD"
    if manpower <= 0:
        return "ABANDONED"
    if rations <= 0.0 and days_starving > 7:
        return "RIOT"
    if oxygen <= 0.0 and days_without_oxygen > 1:
        return "ASPHYXIATION"
    return "STABLE"
