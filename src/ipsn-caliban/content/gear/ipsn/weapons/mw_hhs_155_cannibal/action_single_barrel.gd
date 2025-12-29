extends ActionAttackWeapon

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    return true

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    
    var counter: PassiveDieCounter = context.gear.get_die_counter_passive()
    
    if(counter.get_current(context.gear) <= 1):
        counter.reset(context.unit, context.gear, true)
    else:
        counter.decrease(context.unit, context.gear, 1)
        context.gear.is_loaded = true
