extends Resource
class_name CellRespectSystem

@export var range_min := 0.0
@export var range_max := 100.0
@export var base_neutral := 50.0

@export var rep_weight := 0.5
@export var disp_weight := 0.3
@export var resp_weight := 0.2

@export var hostile_max := -25.0
@export var neutral_min := -10.0
@export var friendly_min := 20.0
@export var admire_min := 40.0

func compute_standing(rep: float, disp: float, resp: float) -> float:
    var standing := rep_weight * rep + disp_weight * disp + resp_weight * (resp - base_neutral)
    return clamp(standing, -100.0, 100.0)

func classify(standing: float) -> StringName:
    if standing <= hostile_max:
        return &"hostile"
    if standing < neutral_min:
        return &"wary"
    if standing < friendly_min:
        return &"neutral"
    if standing < admire_min:
        return &"friendly"
    return &"admire"
