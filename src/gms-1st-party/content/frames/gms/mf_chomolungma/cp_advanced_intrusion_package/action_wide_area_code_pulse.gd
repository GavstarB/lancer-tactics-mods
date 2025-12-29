extends ActionSystem

@export var buff: Buff
@export var buff2: Buff

func activate(context: Context, activation: EventCore) -> void:
    if not await CommonActionUtil.confirm_use(context): return
    
    var sensor_tiles = Tile.get_all_within(context.unit.state.tile, context.unit.get_sensor_range(), context.map)
    var units: Array[Unit] = []
    var unit_tiles: Array[Vector2i] = []
    for unit in context.unit.get_enemy_units():
        if sensor_tiles.has(unit.state.tile):
            units.append(unit)
            unit_tiles.append(unit.state.tile)
    
    if units.is_empty(): return
    
    var possible_tech: Array[SpecificAction] = []
    for gear: GearCore in context.unit.core.loadout.get_frame_traits(context.unit.frame()):
        for action: Action in gear.kit.get_tech_attack_actions():
            var specific: = SpecificAction.create(context.unit, gear, action)
            if action.get_action_cost(specific) == Lancer.ACTION_COST_QUICK and is_instance_of(action, ActionAttackTech):
                if action.is_invade:
                    possible_tech.append(specific)
    for gear: GearCore in context.unit.core.loadout.get_all_tech_attacks():
        for action: Action in gear.kit.get_tech_attack_actions():
            var specific: = SpecificAction.create(context.unit, gear, action)
            if action.get_action_cost(specific) == Lancer.ACTION_COST_QUICK and is_instance_of(action, ActionAttackTech):
                if action.is_invade:
                    possible_tech.append(specific)
    
    Util.filter(possible_tech, func(specific: SpecificAction): return UnitAction.is_gear_available(specific, true))
    if possible_tech.is_empty(): return
    
    camera_bus.show_all_tiles(unit_tiles)
    run_system_fxgs(context.unit)
    spend_actions(activation)
    
    var buff_core = UnitCondition.apply_buff(activation, context.unit, buff, context.gear)
    
    var units_len = len(units)
    for i in range(units_len):
        var unit: Unit = await choice_bus.choose_unit(units)
        if(unit == null):
            break
            #unit = units.pop_back()
            #UnitCondition.apply_status(activation, unit, Lancer.STATUS.IMPAIRED, Lancer.UNTIL.END_OF_NEXT_TURN, get_id())
        else:
            units.erase(unit)
            
            var buff_core2 = UnitCondition.apply_buff(activation, unit, buff2, context.gear)
            
            var chosen: SpecificAction = await TargetActionUtil.choice_bus.choose_from_gear(
                possible_tech,
                tr("gear.cp_advanced_intrusion_package.action_wide_area_code_pulse.choose"),
                true
            )
            
            await activation.execute_event(&"event_gear_activate", {
                unit = chosen.unit, 
                gear = chosen.gear, 
                action = chosen.action, 
                flags = [Action.FLAG.AS_FREEBIE, Action.FLAG.SKIP_TELEGRAPHING], 
                event = activation,
                target_unit = unit
            })
            
            camera_bus.show_all_tiles(unit_tiles)
            
            if(unit != null):
                UnitCondition.clear_buff(activation, unit, buff_core2)
            
            
    
    UnitCondition.clear_buff(activation, context.unit, buff_core)
