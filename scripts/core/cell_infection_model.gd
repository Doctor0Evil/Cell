extends Resource
class_name CellInfectionModel

@export var base_infection_rate: float = 1.0

func tick_infection(delta: float, vsys: PlayerVitalitySystem, race: RaceDefinition, contamination_level: float) -> float:
    if race.immune_to_cell:
        return 0.0

    var resistance := (vsys.vitality + vsys.temper + vsys.tenacity) / 30.0
    resistance = clamp(resistance, 0.2, 1.5)

    var rate := base_infection_rate * contamination_level
    rate *= race.cell_resistance_factor
    rate *= 1.3 - resistance

    var wellness_factor := clamp(vsys.wellness / max(1.0, vsys.wellness_max), 0.2, 1.2)
    rate *= 1.4 - wellness_factor

    return max(rate * delta, 0.0)
