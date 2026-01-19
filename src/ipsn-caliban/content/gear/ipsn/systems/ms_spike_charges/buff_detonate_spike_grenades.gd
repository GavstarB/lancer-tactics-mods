extends Buff

const GRENADE_DAMAGE: = {count = 1, dietype = 6, bonus = 3}

@export var buff: Buff
@export var clear_id: String

var could_use_last_turn_end = false

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    #if(unit != triggering_event.context.unit): return false
    
    if(unit.core.current.reactions <= 0): return false
    
    #print(compcon_id, " ", could_use_last_turn_end)
    
    var buff2_core: BuffCore = UnitCondition.get_buff(unit, clear_id)
    if(compcon_id == &"buff_detonate_spike_grenades2"):
        could_use_last_turn_end = true
        buff2_core.base.could_use_last_turn_end = true
    else:
        if could_use_last_turn_end:
            could_use_last_turn_end = false
            buff2_core.base.could_use_last_turn_end = false
            return false
    
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var context: Context = activation.context.event.context
    var unit: Unit = core.get_owner_unit(context.unit.map)
    var gear: GearCore = unit.core.loadout.get_by_compcon_id(&"ms_spike_charges")
    
    if GearCore.is_valid(gear):
        var all_targets: Array[Unit] = []
        for target_unit in unit.map.get_all_units():
            if UnitCondition.has_buff(target_unit, buff.compcon_id, gear.persistent_id):
                all_targets.append(target_unit)
        
        var damage_amount: int = Dice.roll_and_sum(GRENADE_DAMAGE)
        if(len(all_targets) > 0):
            if await CommonActionUtil.confirm_use_alt(SpecificAction.create(unit, gear, gear.kit.actions[2])):
            #if await CommonActionUtil.choice_bus.quick_yesno(unit.state.tile, "Detonate Spike Grenades", ""):
                #context.unit.core.current.reactions -= 1
                gear.kit.actions[2].spend_actions(activation)
                
                var specific = SpecificAction.create(unit, gear, ActionAttack.new())
                var declared_attack_summary = DeclaredAttackSummary.create(all_targets, [], [], [])
                var virtual_event: = EventCore.create(&"event_unit_attack_declared", {
                    unit = unit, 
                    gear = specific.gear, 
                    action = specific.action, 
                    resource = declared_attack_summary,
                })
                virtual_event.block = activation.block
                activation.queue_reaction_events(ReactionBus.TRIGGER.ATTACK_DECLARED, ReactionBus.TIMING.PRE, virtual_event)
                
                for target_unit in all_targets:
                    UnitCondition.clear_buff_id(activation, target_unit, buff.compcon_id, gear.persistent_id)
                    
                    if(target_unit.is_character()):
                        activation.queue_events(CommonActionUtil.generate_knockback_events(target_unit, 3, specific))
                    
                    activation.queue_event(&"event_unit_damage", {
                        unit = target_unit, 
                        number = damage_amount, 
                        category = Lancer.DAMAGE_TYPE.KINETIC, 
                        flags = [], 
                        target_unit = unit
                    })
                
                activation.queue_reaction_events(ReactionBus.TRIGGER.ATTACK_DECLARED, ReactionBus.TIMING.POST, virtual_event)
                
        else:
            UnitCondition.clear_buff(activation, unit, core)
            UnitCondition.clear_buff_id(activation, unit, clear_id)
