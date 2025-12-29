extends ActionSystem

func activate(context: Context, activation: EventCore) -> void :
    
    var possible_tech: Array[SpecificAction] = []
    
    for gear: GearCore in context.unit.core.loadout.get_frame_traits(context.unit.frame()):
        for action: Action in gear.kit.get_tech_attack_actions():
            var specific: = SpecificAction.create(context.unit, gear, action)
            if action.get_action_cost(specific) == Lancer.ACTION_COST_QUICK and is_instance_of(action, ActionAttackTech):
                possible_tech.append(specific)
    for gear: GearCore in context.unit.core.loadout.get_all_tech_attacks():
        for action: Action in gear.kit.get_tech_attack_actions():
            var specific: = SpecificAction.create(context.unit, gear, action)
            if action.get_action_cost(specific) == Lancer.ACTION_COST_QUICK:
                possible_tech.append(specific)
    for gear: GearCore in context.unit.core.loadout.get_all_systems():
        for action: Action in gear.kit.actions:
            var specific: = SpecificAction.create(context.unit, gear, action)
            if action.get_action_cost(specific) == Lancer.ACTION_COST_QUICK and action.is_tech:
                possible_tech.append(specific)

    Util.filter(possible_tech, func(specific: SpecificAction): return UnitAction.is_gear_available(specific, true))
    if possible_tech.is_empty(): return
    
    var chosen: SpecificAction = await TargetActionUtil.choice_bus.choose_from_gear(
        possible_tech,
        tr("gear.mt_brilliance.choose"),
        true
    )
    
    spend_actions(activation)
    
    await activation.execute_event(&"event_gear_activate", {
        unit = chosen.unit, 
        gear = chosen.gear, 
        action = chosen.action, 
        flags = [Action.FLAG.AS_FREEBIE], 
        event = activation
    })
    
    var bolster: SpecificAction = SpecificAction.from_id(context.unit, &"ms_bolster")
    var lock_on: SpecificAction = SpecificAction.from_id(context.unit, &"ms_lock_on")
    
    chosen = await TargetActionUtil.choice_bus.choose_from_gear(
        [bolster, lock_on],
        tr("gear.mt_brilliance.choose"),
        true
    )
    
    await activation.execute_event(&"event_gear_activate", {
        unit = chosen.unit, 
        gear = chosen.gear, 
        action = chosen.action, 
        flags = [Action.FLAG.AS_FREEBIE], 
        event = activation
    })
