extends ActionSystemTargetUnit

@export var debris_frame: Frame

var yeeted_unit: Unit = null

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if not super.is_available_to_activate(unit, gear): return false
    if UnitCondition.has_status(unit, Lancer.STATUS.FLYING): return false
    return true

func activate(context: Context, activation: EventCore) -> void:
    # choose rock
    var potential_damage_tiles: = UnitTile.get_adjacent_tiles(context.unit)
    
    var specific = SpecificAction.create(context.unit, context.gear, self)
    var plan: CompconPlan = await choice_bus.choose_target_tiles(specific, potential_damage_tiles)
    if(plan == null): return
    
    if not plan.target_tiles.is_empty():
        var tile = plan.target_tiles[0]
        var units: Array[Unit] = []
        for unit in context.unit.map.get_all_units_at_tile(tile, context.unit, true):
            if UnitRelation.can_affect(context.unit, unit):
                if not unit.is_character():
                    if(unit.get_size() <= 1):
                        units.append(unit)
        
        if not units.is_empty():
            #yeet unit
            var attacked_unit: Unit = units[0]
            if(len(units) > 1):
                attacked_unit = await choice_bus.disambiguate_targets(tile, units, false)
            
            yeeted_unit = attacked_unit
            
        else:
            #yeet terrain
            await activation.execute_event(&"event_map_damage", {
                target_tiles = [tile], 
                number = 20, 
                flags = [EventMapDamage.FLAG.AP], 
            })
            if activation.abort_without_unit(context.unit): return
            
            var deployable: = Unit.create(UnitCore.create(Faction.NONE, debris_frame))
            deployable.set_facing( - Tile.position_2d_center(tile).angle_to_point(Tile.position_2d_center(context.unit.state.tile)) + (TAU / 4))
            deployable.core.token_customization.chosen_mesh = debris_frame.meshes.pick_random()
            await activation.execute_event(&"event_unit_spawn", {
                unit = deployable, 
                target_tiles = [tile], 
            })
            
            yeeted_unit = deployable
    
    # attack target
    var unit: Unit = context.unit

    plan = await TargetActionUtil.ask_for_targets(activation, false)
    if activation.abort_without_target_unit_plan(plan): return

    spend_actions(activation)
    #await run_system_fxgs(unit, plan.target_units)
    if activation.abort_without_units([unit] + plan.target_units): return

    for target_unit in plan.target_units:
        if Unit.is_valid(target_unit) and Unit.is_valid(unit):
            await activate_for_target(context, activation, target_unit)


static func check_if_tile_is_free(tile: Vector2i, map: MapState) -> bool:

    if map.get_surface_terrain_at(tile).is_invalid_endpoint(): return false

    if map.get_all_units_at_tile(tile).any( func(unit: Unit) -> bool:
        if unit.has_status(Lancer.STATUS.EXILED): return false
        if unit.has_status(Lancer.STATUS.FLYING): return false
        if unit.core.frame.is_prop: return false
        return true
    ): return false

    return true

func activate_for_target(context: Context, activation: EventCore, target_unit: Unit) -> void:
    var specific = SpecificAction.create(context.unit, context.gear, self)
    var movement_type = MovementType.create_for_involuntary(target_unit)
    movement_type.flying = true
    
    if(yeeted_unit != null):
        # move object
        UnitCondition.apply_status(activation, yeeted_unit, Lancer.STATUS.FLYING, Lancer.UNTIL.MANUAL, context.gear.persistent_id)
        var pathfinder = await Pathfinder.generate_for_movement_budget(yeeted_unit, 5 + target_unit.get_size(), movement_type)
        await activation.execute_event(&"event_unit_move", {
            unit = yeeted_unit, 
            array = pathfinder.path_to(target_unit.state.tile), 
            resource = movement_type, 
            object = specific, 
        })
    
    await FxGroup.run_attack_and_targets(
        fxg_use, target_unit, 
        fxg_target, [], 
        fxg_aoe, [], 
        true
    )
    
    var passed = await UnitHasecheck.make_agility_save(activation, target_unit, specific)
    if not passed:
        await activation.execute_events(CommonActionUtil.generate_knockback_events(target_unit, 1, specific))
        var damage = Dice.roll_d6()
        await activation.execute_event(&"event_unit_damage", {
            unit = target_unit, 
            number = damage, 
            category = Lancer.DAMAGE_TYPE.KINETIC,
            flags = [], 
            target_unit = context.unit
        })
    
    var adjacent_tiles: = UnitTile.get_adjacent_tiles(target_unit)
    if UnitCondition.has_status(target_unit, Lancer.STATUS.FLYING):
        adjacent_tiles.append(target_unit.state.tile)
    #UnitTile.filter_to_free_tiles(adjacent_tiles, context.map)
    Util.filter(adjacent_tiles, check_if_tile_is_free.bind(context.map))
    Util.filter(adjacent_tiles, func(tile: Vector2i) -> bool: return context.map.elevation_blocks(tile) == context.map.elevation_ground(tile))
    if not adjacent_tiles.is_empty():
        var plan: CompconPlan = await choice_bus.choose_target_tiles(specific, adjacent_tiles)
        if not plan.target_tiles.is_empty():
            var free_tile: Vector2i = plan.target_tiles[0]

            if(yeeted_unit != null):
                # move object
                var pathfinder = await Pathfinder.generate_for_movement_budget(yeeted_unit, 1 + target_unit.get_size(), movement_type)
                await activation.execute_event(&"event_unit_move", {
                    unit = yeeted_unit, 
                    array = pathfinder.path_to(free_tile), 
                    resource = movement_type, 
                    object = specific, 
                })
    
    if(yeeted_unit != null):
        UnitCondition.clear_status(activation, yeeted_unit, Lancer.STATUS.FLYING, context.gear.persistent_id)
        yeeted_unit = null
