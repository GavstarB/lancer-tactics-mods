extends ActionReactionAttacked

func activate(context: Context, activation: EventCore) -> void:
    var specific: = SpecificAction.create(context.unit, context.gear, context.action)
    
    var units: Array[Unit] = []
    var unit_tiles: Array[Vector2i] = []
    for unit in UnitRelation.get_units_within(context.unit, context.unit.get_sensor_range(), false):
        if unit.is_character():
            units.append(unit)
            unit_tiles.append(unit.state.tile)
    
    await camera_bus.show_all_tiles(unit_tiles)
    
    var target_unit: Unit = await choice_bus.choose_unit(units, true, specific)
    
    var movement_type: = MovementType.create_for_involuntary(target_unit)
    movement_type.must_move_max_possible = true
    var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(target_unit, 2, movement_type)

    var plan: CompconPlan = await TargetActionUtil.ask_for_movement_alt(target_unit, pathfinder, specific)
    if activation.abort_without_movement_plan(plan, target_unit): return

    activation.queue_event(&"event_unit_move", {
        unit = target_unit, 
        array = plan.move_path, 
        resource = movement_type, 
    })
