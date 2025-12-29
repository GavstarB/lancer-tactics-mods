extends ActionReaction

#const BRACE_BUFFS: Array[Buff] = [
    #preload("res://content/events/event_unit_brace/buff_brace_difficulty.tres"), 
    #preload("res://content/events/event_unit_brace/buff_brace_resist.tres"), 
#]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    
    if(triggering_event.context.unit != unit): return false
    
    return true

func activate(context: Context, activation: EventCore) -> void:
    #var brace_gear: GearCore = context.unit.core.loadout.get_by_compcon_id(&"ms_brace")
    
    spend_actions(activation)
    
    UnitCondition.clear_status(activation, context.unit, Lancer.STATUS.DAZED)
    #for buff: Buff in BRACE_BUFFS: UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id, brace_gear.persistent_id)
