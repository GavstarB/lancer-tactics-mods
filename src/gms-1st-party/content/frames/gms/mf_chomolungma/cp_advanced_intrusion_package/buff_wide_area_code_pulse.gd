extends Buff

func activate(core: BuffCore, activation: EventCore) -> void:
    var attack_roll: AttackRoll = activation.context.event.context.object
    
    if(attack_roll.hit == false):
        UnitCondition.apply_status(activation, activation.context.event.context.target_unit, Lancer.STATUS.IMPAIRED, Lancer.UNTIL.END_OF_NEXT_TURN)
