extends Buff

@export var buff: Buff
@export var buff2: Buff

func on_clear(event: EventCore, core: BuffCore, unit: Unit) -> void:
    for target_unit in unit.map.get_all_units():
        if(UnitCondition.has_buff(target_unit, buff.compcon_id)):
            UnitCondition.clear_buff_id(event, target_unit, buff.compcon_id)
        if(UnitCondition.has_buff(target_unit, buff2.compcon_id)):
            UnitCondition.clear_buff_id(event, target_unit, buff2.compcon_id)
    
