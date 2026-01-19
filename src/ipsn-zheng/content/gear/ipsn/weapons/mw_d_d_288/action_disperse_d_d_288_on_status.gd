extends ActionReaction

@export var buff: Buff

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit != unit): return false
    var status: Lancer.STATUS = (triggering_event.context.category as Lancer.STATUS)
    if(status == Lancer.STATUS.STUNNED or status == Lancer.STATUS.SHUTDOWN): return true
    return false

func activate(context: Context, activation: EventCore) -> void:
    context.gear.wake_action(&"action_charge_d_d_288")
    context.gear.hibernate_action(&"action_disperse_d_d_288")
    context.gear.wake_action(&"action_d_d_288_uncharged")
    context.gear.hibernate_action(&"action_d_d_288_charged")
    
    var charged: Dictionary = context.gear.get_state("charged", {})
    charged[context.gear.persistent_id] = false
    context.gear.set_state("charged", charged)
    
    UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id, context.gear.persistent_id)
