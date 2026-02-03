extends ActionSystem

@export var buff: Buff

func activate(context: Context, activation: EventCore) -> void:
    spend_actions(activation)
    
    context.gear.wake_action(&"action_charge_d_d_288")
    context.gear.hibernate_action(&"action_disperse_d_d_288")
    context.gear.wake_action(&"action_d_d_288_uncharged")
    context.gear.hibernate_action(&"action_d_d_288_charged")
    
    var charged: Dictionary = context.gear.get_state("charged", {})
    charged[context.gear.persistent_id] = false
    context.gear.set_state("charged", charged)
    
    await CommonActionUtil.run_attack_and_target_fx(
        fxg_use, context.unit, 
        fxg_target, [], 
        fxg_aoe, [], 
        true
    )
    
    UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id, context.gear.persistent_id)
