extends ActionSystemApplyBuff

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    var counter: = context.gear.get_die_counter_passive()
    counter.increase(context.unit, context.gear, 6)
