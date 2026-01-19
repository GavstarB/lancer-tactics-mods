extends Buff

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    var owner_unit: = core.get_owner_unit(unit.map)
    #print(triggering_event.base.event_type)
    
    if(triggering_event.base.event_type == &"event_unit_move"):
        if(triggering_event.context.unit != unit): return false
        return true
    
    elif(triggering_event.base.event_type == &"event_unit_collide"):
        if(triggering_event.context.unit != unit): return false
        if not triggering_event.context.is_property_present(Context.PROP.event): return false
        var move_event: EventCore = triggering_event.context.event
        if(move_event.context.unit != unit): return false
        if not move_event.context.is_property_present(Context.PROP.object): return false
        var specific: SpecificAction = move_event.context.object
        if(specific.unit != owner_unit): return false
        return true
    
    return false

func activate(core: BuffCore, activation: EventCore) -> void:
    var owner_unit: = core.get_owner_unit(activation.context.unit.map)
    var unit: = activation.context.event.context.unit
    
    if(activation.context.event.base.event_type == &"event_unit_move"):
        #var tiles: Array[Vector2i] = []
        #if(activation.context.event.context.array != null):
            #for step: Pathfinder.Step in activation.context.event.context.array:
                #tiles.append(step.tile)
        #else:
            #tiles = activation.context.event.context.target_tiles
        
        var tiles: Array[Vector2i] = [unit.state.tile]
        
        #print(tiles)
        
        var units: Array[Unit] = []
        for passed_unit in unit.map.get_all_units_at_tiles(tiles):
            if passed_unit.is_character():
                if(passed_unit != unit):
                    units.append(passed_unit)
        
        var specific: = activation.context.event.context.object as SpecificAction
        for passed_unit in units:
            var passed = await UnitHasecheck.make_hull_save(activation, unit, specific)
            if not passed:
                UnitCondition.apply_status(activation, passed_unit, Lancer.STATUS.PRONE, Lancer.UNTIL.MANUAL, specific.gear.persistent_id)
    
    elif(activation.context.event.base.event_type == &"event_unit_collide"):
        var damage = Dice.roll_d6()
        var specific: = activation.context.event.context.event.context.object as SpecificAction
        var passed = await UnitHasecheck.make_hull_save(activation, unit, specific)
        
        await activation.execute_event(&"event_unit_damage", {
            unit = unit, 
            number = damage, 
            category = Lancer.DAMAGE_TYPE.KINETIC,
            flags = [], 
            target_unit = owner_unit
        })
        if not Unit.is_valid(unit): return
        
        if not passed:
            UnitCondition.apply_status(activation, unit, Lancer.STATUS.STUNNED, Lancer.UNTIL.END_OF_NEXT_TURN, specific.gear.persistent_id)
        
