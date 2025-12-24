extends Node
class_name TestLoxBottle

# Smoke tests for LOX bottle pipeline (Inventory -> LOX -> Vitality)

var vit := PlayerVitalitySystem.new()
var inv := InventoryController.new()
var pools := PlayerPools.new()

func _ready() -> void:
	_run_all()

func _fail(msg: String) -> void:
	push_error("[TestLoxBottle] FAIL: %s" % msg)
	assert(false)

func _setup_baseline() -> void:
	vit.oxygen_max = 600.0
	vit.oxygen = 200.0
	vit.vitality = 5.0
	vit.temper = 5.0
	vit.wellness = 80.0
	vit.suit_oxygen_capacity_sl = 600.0

	inv.vitality_system = vit
	inv.capacity_slots = 4
	inv._ready()

	pools.vitality_system = vit

func _make_lox_instance() -> CellItemInstance:
	var defs := OxygenRegistry.build_all()
	if defs.size() == 0:
		_fail("OxygenRegistry.build_all() returned no definitions")
	var def := defs[0]
	var inst := CellItemInstance.new()
	inst.definition = def
	inst.stack_count = 1
	inst.condition = 100.0
	return inst

func _find_slot_for(def_id: String) -> int:
	for i in range(inv.slots.size()):
		var s := inv.slots[i]
		if s and s.definition and s.definition.id == def_id:
			return i
	return -1

func _test_inventory_use_lox() -> void:
	_setup_baseline()
	var inst := _make_lox_instance()
	var added := inv.add_item(inst)
	if not added:
		_fail("Failed to add LOX instance to inventory")

	var def_id := inst.definition.id
	var slot := _find_slot_for(def_id)
	if slot == -1:
		_fail("LOX item not found in inventory after add")

	var before_oxy := vit.oxygen
	var before_vitality := vit.vitality
	var before_temper := vit.temper
	var before_wellness := vit.wellness

	inv.use_item(slot)

	# Expected oxygen increase: def.oxygen_delta (SL) converted via suit capacity.
	var sl := inst.definition.oxygen_delta
	var expected_fraction := sl / max(1.0, vit.suit_oxygen_capacity_sl)
	var expected_add := expected_fraction * vit.oxygen_max
	var expected_final := min(vit.oxygen_max, before_oxy + expected_add)

	if abs(vit.oxygen - expected_final) > 0.0001:
		_fail("Oxygen not increased as expected (got %s, expected %s)" % [vit.oxygen, expected_final])

	# Stack decremented -> slot cleared
	if inv.slots[slot] != null:
		_fail("LOX item slot not cleared after use")

	# Wellness/vitality/temper should reflect penalties
	if not (vit.wellness < before_wellness):
		_fail("Wellness did not decrease after using LOX bottle")
	if not (vit.vitality <= before_vitality):
		_fail("Vitality did not decrease (or unchanged) after using LOX bottle")
	if not (vit.temper <= before_temper):
		_fail("Temper did not decrease (or unchanged) after using LOX bottle")

func _test_alias_and_deprecation_behavior() -> void:
	_setup_baseline()

	# Test alias: use_lox_bottle vs use_oxygen_bottle -> should be identical
	vit.use_lox_bottle(160.0)
	var after_lox := vit.oxygen

	_setup_baseline()
	vit.use_oxygen_bottle(160.0)
	var after_oxy := vit.oxygen

	if abs(after_lox - after_oxy) > 0.0001:
		_fail("use_lox_bottle and use_oxygen_bottle produced different oxygen values: %s vs %s" % [after_lox, after_oxy])

	# Test apply_lox_bottle vs deprecated apply_oxygen_capsule on PlayerPools
	_setup_baseline()
	pools.apply_lox_bottle(160.0)
	var after_apply_lox := vit.oxygen

	_setup_baseline()
	pools.apply_oxygen_capsule(160.0) # deprecated wrapper
	var after_apply_capsule := vit.oxygen

	if abs(after_apply_lox - after_apply_capsule) > 0.0001:
		_fail("apply_lox_bottle and apply_oxygen_capsule produced different results")

func _test_mission_grant_wiring() -> void:
	# Ensure mission _grant_lox_bottle puts the LOX asset into GameState.inventory
	# Prepare a simple GameState.inventory container
	GameState.inventory = []
	var m := MissionColdVergeOxygenRun.new()
	m._grant_lox_bottle()
	if GameState.inventory.size() == 0:
		_fail("Mission did not grant any inventory items")
	var entry := GameState.inventory[0]
	if entry.get("id", "") != "CON_LOX_CRYO_CORE_STD":
		_fail("Mission granted wrong item id: %s" % entry)

func _run_all() -> void:
	_test_inventory_use_lox()
	_test_alias_and_deprecation_behavior()
	_test_mission_grant_wiring()
	print("TestLoxBottle: ALL PASSED")