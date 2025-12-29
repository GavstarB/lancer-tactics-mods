extends ActionAttackTech

const USED_ON_KEY: = "sc_used_on"

func get_damage_dice(gear: GearCore = null) -> String: return "4"

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    if specific.gear.state_has_id_in(USED_ON_KEY, potential_target.core.persistent_id): return false
    return true

func on_hit(activation: EventCore, attacked_unit: Unit) -> void :
    activation.context.gear.append_to_array_state(USED_ON_KEY, attacked_unit.core.persistent_id)
    #var attack_roll: AttackRoll = activation.context.object
    
    var heat = 4
    if not activation.context.flags.has(Action.FLAG.NO_BONUS_DAMAGE):
        var bonus_damage_buffs: Array[BuffCore] = UnitCondition.get_buffs_to(activation.context.unit, Buff.TO.BONUS_DAMAGE, activation.context)
        bonus_damage_buffs.append_array(UnitCondition.get_buffs_to(activation.context.unit, Buff.TO.BONUS_DAMAGE_SPECIFIC, activation.context))
        for bonus_damage_buff in bonus_damage_buffs:
            var bonus_damage_buff_value: Context = bonus_damage_buff.get_values(activation.context)
            var damage_dice: String = bonus_damage_buff_value.string
            var dice = Dice.process_dice_string(damage_dice)
            heat += dice.count + dice.bonus
    
    if(attacked_unit.core.current.heat + heat > attacked_unit.get_heat_max()):
        activation.queue_event(&"event_unit_damage", {
            unit = attacked_unit, 
            number = 4,
            category = Lancer.DAMAGE_TYPE.BURN,
            flags = [],
            target_unit = activation.context.unit, 
            gear = activation.context.gear, 
            action = activation.context.action, 
        }, Priority.ATTACK.onhit)
    
    #activation.queue_event(&"event_unit_damage", {
        #unit = attacked_unit, 
        #number = heat,
        #category = Lancer.DAMAGE_TYPE.HEAT,
        #flags = [],
        #target_unit = activation.context.unit, 
        #gear = activation.context.gear, 
        #action = activation.context.action, 
    #}, Priority.ATTACK.dice)
    
