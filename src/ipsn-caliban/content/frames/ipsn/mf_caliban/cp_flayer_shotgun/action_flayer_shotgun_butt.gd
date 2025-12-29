extends ActionAttackWeapon

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    if not potential_target.is_character(): return false
    return true
