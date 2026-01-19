extends ActionAttackWeapon

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    var counter: PassiveDieCounter = gear.get_die_counter_passive()
    if(counter.get_current(gear) <= 1): return false
    return true

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    var counter: PassiveDieCounter = context.gear.get_die_counter_passive()
    counter.reset(context.unit, context.gear, true)
