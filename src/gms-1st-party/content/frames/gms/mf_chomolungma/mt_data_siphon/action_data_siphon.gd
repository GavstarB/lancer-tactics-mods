extends ActionReaction

#func get_required_triggering_context() -> Array[Context.PROP]:
    #return [
        #Context.PROP.target_unit, 
        #Context.PROP.unit, 
        #Context.PROP.gear, 
        #Context.PROP.action, 
        #Context.PROP.resource, 
        #Context.PROP.event, 
    #]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: = triggering_event.context
    if context.unit != unit: return false
    
    if not context.action is ActionAttackTech: return false
    
    var target_unit = context.target_unit
    if not target_unit.is_character(): return false
    
    return Scanpedia.is_anything_unscanned(target_unit)

func activate(context: Context, activation: EventCore) -> void:
    #var action: ActionAttackTech = activation.context.event.context.action
    var target_unit = activation.context.event.context.target_unit
    
    Scanpedia.scan(target_unit)
    effect_bus.play_text(tr("gear.ms_scan.action_scan.pop"), target_unit.tile())
    
