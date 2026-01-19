extends ActionReactionAttacked

func activate(context: Context, activation: EventCore) -> void:
    var counter: PassiveDieCounter = context.gear.get_die_counter_passive()
    counter.increase(context.unit, context.gear, 1)
