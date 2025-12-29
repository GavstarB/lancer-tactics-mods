extends ActionSystem

func activate(context: Context, activation: EventCore) -> void:
    context.gear.wake_action(&"action_flayer_shotgun_autochoke")
    context.gear.hibernate_action(&"action_flayer_shotgun")
    context.gear.hibernate_action(&"action_equip_autochoke")
    
    context.unit.core.has_core_power = false
