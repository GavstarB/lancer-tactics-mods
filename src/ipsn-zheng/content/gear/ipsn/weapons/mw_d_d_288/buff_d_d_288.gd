extends BuffCover

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit != unit): return false
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var unit: = activation.context.unit
    var gear: = core.get_owner_gear(unit.map)
    var charged: Dictionary = gear.get_state("charged", {})
    charged[gear.persistent_id] = true
    gear.set_state("charged", charged)
    activation.queue_event(&"event_unit_damage", {
        unit = unit, 
        number = 2, 
        category = Lancer.DAMAGE_TYPE.HEAT,
        flags = [Lancer.DAMAGE_FLAG.SELF_INFLICTED], 
        target_unit = unit
    })
