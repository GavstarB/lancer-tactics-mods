extends Buff

@export var action: ActionSystemMovement

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit != unit): return false
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var gear: = core.get_owner_gear(activation.context.unit.map)
    if action.attacked_units_cache.has(gear.persistent_id):
        var counter: = gear.get_die_counter_passive()
        var increase = len(action.attacked_units_cache[gear.persistent_id])
        increase += abs(mini(counter.get_current(gear), 0))
        counter.increase(activation.context.unit, gear, increase)
        action.attacked_units_cache[gear.persistent_id] = []
