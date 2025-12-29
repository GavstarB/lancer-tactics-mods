extends Buff

@export var movement_pursue_prey: MovementType
@export var attacked_unit_ids: Array[StringName] = []

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit == unit): return false
    #if not triggering_event.context.unit.is_character(): return false
    #print(triggering_event.context.unit.core.persistent_id)
    #print(attacked_unit_ids)
    var is_attacked_unit = false
    for id in attacked_unit_ids:
        if(triggering_event.context.unit.core.persistent_id == id): 
            is_attacked_unit = true
    if not is_attacked_unit: return false
    if not triggering_event.context.is_property_present(Context.PROP.flags): return false
    if not triggering_event.context.is_property_present(Context.PROP.resource): return false
    #if not triggering_event.context.is_property_present(Context.PROP.action): return false
    #if not triggering_event.context.flags.has(EventUnitMove.FLAG.NO_RXNS): return false
    
    #var specific = triggering_event.context.action
    var movement_type = (triggering_event.context.resource as MovementType)
    if((not movement_type.spend_move) and (not movement_type.voluntary) and movement_type.ignore_rxns and
        movement_type.ignore_engagement and movement_type.ignore_difficult and (not movement_type.free_climb) and 
        movement_type.cannot_move_uphill and (not movement_type.teleport) and movement_type.straight_line and 
        movement_type.must_move_max_possible and (not movement_type.can_move_through_enemies) and 
        movement_type.jump_downhill
    ):
        return true
    return false

func activate(core: BuffCore, activation: EventCore) -> void:
    var context: Context = activation.context.event.context
    context.map = context.unit.map
    var unit: Unit = core.get_holder_unit(context.map)
    var attacked_unit = context.unit
    var steps: Array[Pathfinder.Step] = context.array
    var dist = min(Tile.distance(unit.state.tile, attacked_unit.state.tile)-1, len(steps))
    
    var arr: Array[Vector2i] = AoeCalculator.line(unit.state.tile, attacked_unit.state.tile, dist, context.map.shape)
    var pathfinder: Pathfinder = await Pathfinder.generate_for_given_tiles(unit, arr, movement_pursue_prey)
    #var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(unit, dist, movement_pursue_prey)
    #var tile = arr[len(steps)-1]
    var tile = Tile.furthest_possible_from(arr, unit.state.tile)
    
    if(len(arr) > 0):
        #print("TEST6")
        #print(arr)
        #print(tile)
        #print(unit.state.tile)
        #print(attacked_unit.state.tile)
        
        var arr2: Array[Vector2i] = []
        var steps2: Array[Pathfinder.Step] = []
        for step in pathfinder.straight_path_to(tile, unit.state.tile, dist, context.map.shape):
            var units = context.map.get_all_units_at_tile(step.tile)
            var obstructed = false
            for unit2 in units:
                print(unit2.core.frame.compcon_id)
                if unit2.core.frame.is_obstruction:
                    obstructed = true
            if obstructed:
                break
            arr2.append(step.tile)
            steps2.append(step)
        
        if(len(arr2) > 0):
            CommonActionUtil.camera_bus.show_all_tiles([unit.state.tile, attacked_unit.state.tile])
            
            effect_bus.show_range(arr2, Rangemesh.TYPE.MOVE, ShrinkwrapStyle.MOVE) #v0.5.0+
            #effect_bus.show_range.emit(arr2, Rangemesh.TYPE.MOVE, ShrinkwrapStyle.MOVE) #v0.4.7
            
            if not await CommonActionUtil.confirm_use_alt(SpecificAction.from_id(unit, &"mt_pursue_prey")): return
            
            activation.queue_event(&"event_unit_move", {
                unit = unit, 
                array = steps2, 
                resource = movement_pursue_prey, 
                flags = [] #[EventUnitMove.FLAG.IGNORE_NOT_HAVING_ENOUGH_TO_REACH_DEST]
            }, Priority.ATTACK.knockback)
