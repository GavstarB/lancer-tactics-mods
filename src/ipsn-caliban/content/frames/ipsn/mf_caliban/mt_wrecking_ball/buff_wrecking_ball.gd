extends Buff

func is_buff_context_valid_for_passive(core: BuffCore, context: Context) -> bool:
    if not Unit.is_valid(context.unit): return false
    if not Unit.is_valid(context.target_unit): return false
    return true

func check_if_passive_applies(core: BuffCore, context: Context) -> bool:
    match context.category:
        UnitRelation.COMPARE_SIZE_SITUATION.RAM: 
            return true
        UnitRelation.COMPARE_SIZE_SITUATION.KNOCKBACK:
            return true
    return false

func get_values(core: BuffCore, context: Context = null) -> Context:
    return Context.create({
        number = 3
    })
