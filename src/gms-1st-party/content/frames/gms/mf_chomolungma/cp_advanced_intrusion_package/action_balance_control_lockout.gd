extends ActionAttackTech

const USED_ON_KEY: = "bcl_used_on"

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    return true

func on_hit(activation: EventCore, attacked_unit: Unit) -> void :
    if(UnitCondition.has_status(attacked_unit, Lancer.STATUS.PRONE) and not activation.context.gear.state_has_id_in(USED_ON_KEY, attacked_unit.core.persistent_id)):
        activation.context.gear.append_to_array_state(USED_ON_KEY, attacked_unit.core.persistent_id)
        UnitCondition.apply_status(activation, attacked_unit, Lancer.STATUS.IMMOBILIZED, Lancer.UNTIL.END_OF_NEXT_TURN, get_id())
    
    UnitCondition.apply_status(activation, attacked_unit, Lancer.STATUS.PRONE, Lancer.UNTIL.MANUAL, activation.context.gear.persistent_id)
    
    activation.queue_events(CommonActionUtil.generate_knockback_events(
        attacked_unit, 
        2, 
        SpecificAction.from_context(activation.context), 
        attacked_unit.occupied_tiles(), 
    ))
