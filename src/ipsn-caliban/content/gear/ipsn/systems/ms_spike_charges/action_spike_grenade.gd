extends ActionSystemGrenade

#static var basic_loadout: KitList = preload("res://content/gear/basic/basic_loadout_mech_player.tres")
#static var basic_loadout_npc: KitList = preload("res://content/gear/basic/basic_loadout_mech_npc.tres")
static var remove_grenade_kit: Kit = preload("res://content/gear/ipsn/systems/ms_spike_charges/ms_remove_spike_grenade/ms_remove_spike_grenade.tres")

@export var buff: Buff
@export var buff2: Buff
@export var buff3: Buff

#const GRENADE_DAMAGE: = {count = 1, dietype = 6, bonus = 3}

#func _init():
    #print(remove_grenade_kit)
    #if not basic_loadout.list.has(remove_grenade_kit):
        #basic_loadout.list.append(remove_grenade_kit)
        #basic_loadout_npc.list.append(remove_grenade_kit)

func activate(context: Context, activation: EventCore) -> void :
    var specific: = SpecificAction.from_context(context)
    var unit: Unit = context.unit

    var plan: CompconPlan = await TargetActionUtil.ask_for_targets(activation)
    if activation.abort_without_targeting_plan(plan): return
    spend_actions(activation)
    
    var target_unit: Unit = plan.target_units.front()
    #var all_targets: Array[Unit] = [target_unit]


    #var damage_amount: int = Dice.roll_and_sum(GRENADE_DAMAGE)


    await run_system_fxgs(unit, [target_unit.state.tile])
    if activation.abort_without_unit(unit): return
    
    if(target_unit.is_character()):
        var passed_save: bool = await UnitHasecheck.make_save(activation, target_unit, specific, Lancer.HASE.AGI)
        if not Unit.is_valid(target_unit): return
        
        if not passed_save:
            effect_bus.play_text(tr("gear.spike_charges.attach_spike_grenade.pop"), target_unit.state.tile)
            battle_log.log_unit("gear.spike_charges.attach_spike_grenade.log", target_unit)
            UnitCondition.apply_buff(activation, target_unit, buff, context.gear)
            
            var has_grenade_kit = false
            for gear in target_unit.core.loadout.basic:
                if(gear.kit == remove_grenade_kit):
                    has_grenade_kit = true
            if not has_grenade_kit:
                target_unit.core.loadout.basic.append(GearCore.create(remove_grenade_kit))
            
            if not UnitCondition.has_buff(unit, buff2.compcon_id):
                UnitCondition.apply_buff(activation, unit, buff2, context.gear)
                UnitCondition.apply_buff(activation, unit, buff3, context.gear)
        
    else:
        if Unit.is_valid(target_unit):
            effect_bus.play_text(tr("gear.spike_charges.attach_spike_grenade.pop"), target_unit.state.tile)
            battle_log.log_unit("gear.spike_charges.attach_spike_grenade.log", target_unit)
            UnitCondition.apply_buff(activation, target_unit, buff, context.gear)
            
            if not UnitCondition.has_buff(unit, buff2.compcon_id):
                UnitCondition.apply_buff(activation, unit, buff2, context.gear)
                UnitCondition.apply_buff(activation, unit, buff3, context.gear)

    #await CommonActionUtil.queue_damage_events_with_save_for_half(
        #activation, specific, all_targets, damage_amount, Lancer.DAMAGE_TYPE.ENERGY, Lancer.HASE.AGI
    #)
