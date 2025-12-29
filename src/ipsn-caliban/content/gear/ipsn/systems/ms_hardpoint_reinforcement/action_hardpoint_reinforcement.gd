extends ActionReactionApplyBuff

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    #print(triggering_event.context.unit.core.frame.compcon_id, " ", unit.core.frame.compcon_id)
    #print(triggering_event.base.event_type)
    if(triggering_event.context.unit != unit): return false
    if(triggering_event.base.event_type == &"event_turn_start"):
        if(triggering_event.context.unit.has_status(Lancer.STATUS.SLOWED) or triggering_event.context.unit.has_status(Lancer.STATUS.IMMOBILIZED) or triggering_event.context.unit.has_status(Lancer.STATUS.GRAPPLED)):
            return false
        return true
    elif(triggering_event.base.event_type == &"event_unit_apply_status"):
        var status: Lancer.STATUS = (triggering_event.context.category as Lancer.STATUS)
        if(status == Lancer.STATUS.SLOWED or status == Lancer.STATUS.IMMOBILIZED):
            return true
    return false

func activate(context: Context, activation: EventCore) -> void:
    #print(activation.context.event.base.event_type)
    if(activation.context.event.base.event_type == &"event_turn_start"):
        if not (context.unit.has_status(Lancer.STATUS.SLOWED) or context.unit.has_status(Lancer.STATUS.IMMOBILIZED) or context.unit.has_status(Lancer.STATUS.GRAPPLED)):
            super.activate(context, activation)
    elif(activation.context.event.base.event_type == &"event_unit_apply_status"):
        #print(context.unit.core.frame.compcon_id)
        #print(activation.context.event.context.unit.core.frame.compcon_id)
        if(context.unit == activation.context.event.context.unit):
            if(context.unit.has_status(Lancer.STATUS.SLOWED) or context.unit.has_status(Lancer.STATUS.IMMOBILIZED) or context.unit.has_status(Lancer.STATUS.GRAPPLED)):
                for buff in buffs:
                    UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id)
            else:
                super.activate(context, activation)
