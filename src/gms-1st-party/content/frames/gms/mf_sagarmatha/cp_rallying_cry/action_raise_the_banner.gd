extends ActionSystemApplyBuff

@export var buff: Buff
@export var buff2: Buff

func can_apply_buff_to_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    #if not super.can_target_unit(potential_target, specific): return false
    
    return UnitTile.is_tile_in_los(
        potential_target.map, 
        UnitTile.get_occupied(specific.unit.state.tile, specific.unit.get_size(), potential_target.map.size), 
        potential_target.get_height(true), 
        potential_target.state.tile
    )

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    var specific: = SpecificAction.from_context(context)
    for unit in context.unit.get_allied_units(false):
        if can_apply_buff_to_unit(unit, specific) and unit.is_character():
            UnitCondition.apply_buff(activation, unit, buff, specific.gear)
            UnitCondition.apply_buff(activation, unit, buff2, specific.gear)
