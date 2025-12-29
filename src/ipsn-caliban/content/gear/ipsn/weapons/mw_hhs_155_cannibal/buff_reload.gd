extends Buff

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if(unit != triggering_event.context.unit): return false
    
    var context: Context = triggering_event.context
    var weapons_to_reload: Array[GearCore] = []
    weapons_to_reload.assign(context.array)
    if GearCore.is_valid(context.gear): weapons_to_reload.append(context.gear)
    for weapon in weapons_to_reload:
        if(weapon.kit.compcon_id == &"mw_hhs_155_cannibal"):
            return true
    
    return false

func activate(core: BuffCore, activation: EventCore) -> void:
    var context: Context = activation.context.event.context
    var weapons_to_reload: Array[GearCore] = []
    weapons_to_reload.assign(context.array)
    if GearCore.is_valid(context.gear): weapons_to_reload.append(context.gear)
    for weapon in weapons_to_reload:
        if(weapon.kit.compcon_id == &"mw_hhs_155_cannibal"):
            var counter: PassiveDieCounter = weapon.get_die_counter_passive()
            counter.reset(context.unit, weapon, true)
            
            var specific = SpecificAction.from_id(context.unit, &"mw_hhs_155_cannibal")
            specific.unit = context.unit
            
            #var action: ActionAttackWeapon = ActionAttackWeapon.new()
            #action.aim_range = 1
            #action.weapon_size = Lancer.WEAPON_SIZE.HEAVY
            #action.weapon_type = Lancer.WEAPON_TYPE.CQB
            #specific = SpecificAction.create(context.unit, context.gear, action)
            
            var tiles = Tile.get_all_within(context.unit.state.tile, 1, context.unit.map)
            var target_units: Array[Unit] = context.unit.map.get_all_units_at_tiles(tiles, context.unit)
            target_units.erase(context.unit)
            if(len(target_units) > 0):
            
                #await CommonActionUtil.choice_bus.telegraph_ability(specific)
                var target_unit = await CommonActionUtil.choice_bus.choose_unit(target_units, true, specific)
                #var plan: CompconPlan = await TargetActionUtil.ask_for_targets_alt(activation, specific, null, [], [], context.unit, [Action.FLAG.AS_FREEBIE])
                #print(plan.target_units)
                #if(plan != null):
                    #if(len(plan.target_units) > 0):
                        #var target_unit = plan.target_units[0]
                activation.queue_event(&"event_unit_damage", {
                    unit = target_unit,
                    number = 5, 
                    category = Lancer.DAMAGE_TYPE.KINETIC, 
                    flags = [], 
                    target_unit = context.unit
                })
            
            
            
            
            
            
            
