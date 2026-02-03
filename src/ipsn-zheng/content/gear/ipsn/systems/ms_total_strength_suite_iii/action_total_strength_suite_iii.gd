extends ActionSystemTargetUnit

@export var buff: Buff

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if UnitCondition.get_outgoing_grapples(unit).is_empty(): return false
    return true

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    for outgoing_grapple: SpecificAction in UnitCondition.get_outgoing_grapples(specific.unit):
        if(potential_target == outgoing_grapple.unit):
            return true
    return false

func get_target_range(specific: SpecificAction) -> int:
    var dist = 0
    for outgoing_grapple: SpecificAction in UnitCondition.get_outgoing_grapples(specific.unit):
        dist = maxi(dist, Tile.distance(specific.unit.state.tile, outgoing_grapple.unit.state.tile))
    return dist

func activate_for_target(context: Context, activation: EventCore, target_unit: Unit) -> void:
    var specific = SpecificAction.create(context.unit, context.gear, self)
    
    Katamari.dettach_units(activation, context.unit, target_unit)
    
    var buff_core = UnitCondition.apply_buff(activation, target_unit, buff, context.gear)
    
    var movement_type = MovementType.create_for_involuntary(target_unit)
    movement_type.straight_line = true
    movement_type.must_move_max_possible = true
    movement_type.can_move_through_enemies = true
    movement_type.cannot_move_uphill = true
    movement_type.jump_downhill = true
    
    var obstruction_cache = {}
    for unit in context.map.get_all_units():
        if unit.is_character():
            if not obstruction_cache.has(unit.core.frame):
                obstruction_cache[unit.core.frame] = unit.core.frame.is_obstruction
                unit.core.frame.is_obstruction = false
    
    await activation.execute_event(&"event_unit_pick_move", {
        target_unit = target_unit, 
        resource = movement_type, 
        number = 5, 
        array = target_unit.occupied_tiles(), 
        flags = [], 
        unit = specific.unit, 
        gear = specific.gear, 
        action = specific.action, 
    })
    
    for frame in obstruction_cache.keys():
        frame.is_obstruction = obstruction_cache[frame]
    
    #for unit in context.map.get_all_units():
        #if unit.is_character():
            #print(unit.core.frame.compcon_id)
            #print(obstruction_cache[unit.core.frame.compcon_id])
            #unit.core.frame.is_obstruction = obstruction_cache[unit.core.frame.compcon_id]
    
    if Unit.is_valid(target_unit):
        UnitCondition.clear_buff(activation, target_unit, buff_core)
        activation.queue_events(EventUnitMove.get_events_to_make_sure_units_are_in_valid_spots([target_unit]))
