extends Resource
class_name CellCombatSequencer

# Turn‑based combat simulation used by the Director AI to forecast outcomes
# and pick pacing events. Slavic‑horror tone via log strings and parameter naming.

@export var max_turns: int = 32

# Expects minimal “actor” dictionaries; IDE agents can build them from Player/Enemy nodes.
# actor_player: { "name", "hp", "weapon_damage", "luck", "armor_dt", "status": { "hypothermia": bool } }
# actor_enemy:  { "name", "hp", "base_damage", "crit_chance", "dt", "status": { "feral": bool } }

func simulate_combat(actor_player: Dictionary, actor_enemy: Dictionary, env: Dictionary) -> Dictionary:
	var log: Array[String] = []
	var turn := 1

	var player_hp := float(actor_player.get("hp", 100.0))
	var enemy_hp := float(actor_enemy.get("hp", 80.0))

	var weather := String(env.get("weather", "snow"))
	var time_of_day := String(env.get("timeofday", "dusk"))

	log.append("Weather outside: %s, time: %s. Steel groans somewhere in the dark corridor." % [weather, time_of_day])

	while player_hp > 0.0 and enemy_hp > 0.0 and turn <= max_turns:
		var player_goes_first := _initiative_roll(actor_player, actor_enemy)

		if player_goes_first:
			var dmg_p := _calc_player_attack(actor_player, actor_enemy)
			enemy_hp = max(enemy_hp - dmg_p, 0.0)
			log.append("Turn %d: You carve into %s for %.1f. Enemy HP: %.1f" % [
				turn, actor_enemy.get("name", "thing"), dmg_p, enemy_hp
			])
			if enemy_hp <= 0.0:
				break

			var dmg_e := _calc_enemy_attack(actor_enemy, actor_player)
			player_hp = max(player_hp - dmg_e, 0.0)
			log.append("Turn %d: %s answers. You take %.1f. Your HP: %.1f" % [
				turn, actor_enemy.get("name", "thing"), dmg_e, player_hp
			])
		else:
			var dmg_e2 := _calc_enemy_attack(actor_enemy, actor_player)
			player_hp = max(player_hp - dmg_e2, 0.0)
			log.append("Turn %d: %s moves first. You feel the hit before you hear it: %.1f. Your HP: %.1f" % [
				turn, actor_enemy.get("name", "thing"), dmg_e2, player_hp
			])
			if player_hp <= 0.0:
				break

			var dmg_p2 := _calc_player_attack(actor_player, actor_enemy)
			enemy_hp = max(enemy_hp - dmg_p2, 0.0)
			log.append("Turn %d: You strike back for %.1f. Enemy HP: %.1f" % [
				turn, dmg_p2, enemy_hp
			])

		_apply_status_effects(actor_player, actor_enemy, env, turn, log)

		turn += 1

	var outcome := ""
	if player_hp > 0.0 and enemy_hp <= 0.0:
		outcome = "player_victory"
		log.append("Silence. The body twitches once, then settles. You are still breathing.")
	elif enemy_hp > 0.0 and player_hp <= 0.0:
		outcome = "enemy_victory"
		log.append("Floor is cold. Lights hum overhead. The station will recycle what is left of you.")
	else:
		outcome = "inconclusive"
		log.append("Combat dissolved into distance and static. No one truly walked away whole.")

	return {
		"log": log,
		"outcome": outcome,
		"player_hp": player_hp,
		"enemy_hp": enemy_hp,
		"turns": turn - 1
	}

func _initiative_roll(player: Dictionary, enemy: Dictionary) -> bool:
	var p_agility := float(player.get("agility", 5.0))
	var e_agility := float(enemy.get("agility", 4.0))
	var p_roll := randf() + p_agility * 0.05
	var e_roll := randf() + e_agility * 0.05
	return p_roll >= e_roll

func _calc_enemy_attack(enemy: Dictionary, target: Dictionary) -> float:
	var base := float(enemy.get("base_damage", 40.0))
	var crit_chance := float(enemy.get("crit_chance", 0.08))
	var crit := randf() < crit_chance ? 2.0 : 1.0
	var target_status := target.get("status", {})
	var hypothermia_penalty := 0.0
	if typeof(target_status) == TYPE_DICTIONARY and bool(target_status.get("hypothermia", false)):
		hypothermia_penalty = -6.0

	var armor_dt := float(target.get("armor_dt", 0.0))
	var dmg := max(0.0, (base + hypothermia_penalty) * crit - armor_dt)
	return dmg

func _calc_player_attack(player: Dictionary, target: Dictionary) -> float:
	var base := float(player.get("weapon_damage", 25.0))
	var luck := float(player.get("luck", 5.0))
	var crit_chance := 0.10 + (luck / 10.0) * 0.05
	var crit := randf() < crit_chance ? 2.0 : 1.0
	var dt := float(target.get("dt", 0.0))
	var dmg := max(0.0, base * crit - dt)
	return dmg

func _apply_status_effects(player: Dictionary, enemy: Dictionary, env: Dictionary, turn: int, log: Array) -> void:
	var weather := String(env.get("weather", "snow"))
	if weather == "snow" and turn % 3 == 0:
		var snow_tick := 2.0
		var p_hp := float(player.get("hp", 100.0)) - snow_tick
		player["hp"] = p_hp
		log.append("Cold seeps under the suit. You lose %.1f HP to the chill." % snow_tick)
	# Hook: extend for dehydration, low oxygen, fractures, etc.
