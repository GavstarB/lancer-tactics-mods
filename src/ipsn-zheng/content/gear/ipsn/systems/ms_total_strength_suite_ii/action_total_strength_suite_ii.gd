extends ActionSystemTargetUnit

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if UnitCondition.get_outgoing_grapples(unit).is_empty(): return false
    return true

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    for outgoing_grapple: SpecificAction in UnitCondition.get_outgoing_grapples(specific.unit):
        if(potential_target == outgoing_grapple.unit):
            return true
    return false

func get_target_range(specific: SpecificAction) -> int:
    var dist = 0
    for outgoing_grapple: SpecificAction in UnitCondition.get_outgoing_grapples(specific.unit):
        dist = maxi(dist, Tile.distance(specific.unit.state.tile, outgoing_grapple.unit.state.tile))
    return dist

func activate_for_target(context: Context, activation: EventCore, target_unit: Unit) -> void:
    var damage = Dice.roll_d6()
    await activation.execute_event(&"event_unit_damage", {
        unit = target_unit, 
        number = damage, 
        category = Lancer.DAMAGE_TYPE.KINETIC,
        flags = [], 
        target_unit = context.unit
    })
