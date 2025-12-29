extends ActionSystemMineDetonation

static var remove_grenade_kit: Kit = preload("res://content/gear/ipsn/systems/ms_spike_charges/ms_remove_spike_grenade/ms_remove_spike_grenade.tres")

@export var buff: Buff
@export var buff2: Buff
@export var buff3: Buff

var detonated = false
var all_targets_cache: Array[Unit] = []

func activate_detonation_effects(all_targets: Array[Unit], forcing_action: SpecificAction, blast_tiles: Array[Vector2i], activation: EventCore) -> void :
    detonated = true
    all_targets_cache = all_targets

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    
    if detonated:
        detonated = false
        if(len(all_targets_cache) > 0):
            var mine: Unit = context.unit
            var unit: Unit = mine.get_owner_unit()
            if(unit == null): return
            var gear: GearCore = unit.core.loadout.get_by_compcon_id(&"ms_spike_charges")
            if GearCore.is_valid(gear):
                var specific = SpecificAction.create(unit, gear, gear.kit.actions[0])
                for target_unit in all_targets_cache:
                    if(target_unit.is_character()):
                        var passed_save: bool = await UnitHasecheck.make_save(activation, target_unit, specific, Lancer.HASE.AGI)
                        if not Unit.is_valid(target_unit): return
                        
                        if not passed_save:
                            effect_bus.play_text(tr("gear.spike_charges.attach_spike_grenade.pop"), target_unit.state.tile)
                            battle_log.log_unit("gear.spike_charges.attach_spike_grenade.log", target_unit)
                            UnitCondition.apply_buff(activation, target_unit, buff, gear)
                            
                            var has_grenade_kit = false
                            for gear2 in target_unit.core.loadout.basic:
                                if(gear2.kit == remove_grenade_kit):
                                    has_grenade_kit = true
                            if not has_grenade_kit:
                                target_unit.core.loadout.basic.append(GearCore.create(remove_grenade_kit))
                            
                            if not UnitCondition.has_buff(unit, buff2.compcon_id):
                                UnitCondition.apply_buff(activation, unit, buff2, gear)
                                UnitCondition.apply_buff(activation, unit, buff3, gear)
                        
                    else:
                        if Unit.is_valid(target_unit):
                            effect_bus.play_text(tr("gear.spike_charges.attach_spike_grenade.pop"), target_unit.state.tile)
                            battle_log.log_unit("gear.spike_charges.attach_spike_grenade.log", target_unit)
                            UnitCondition.apply_buff(activation, target_unit, buff, gear)
                            
                            if not UnitCondition.has_buff(unit, buff2.compcon_id):
                                UnitCondition.apply_buff(activation, unit, buff2, gear)
                                UnitCondition.apply_buff(activation, unit, buff3, gear)
            
        
        
    
    
