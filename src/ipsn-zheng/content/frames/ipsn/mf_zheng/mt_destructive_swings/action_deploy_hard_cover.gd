extends ActionReaction

@export var deployable_frame: Frame

@export var deploy_range: int = 0
@export var deploy_to_sensors: bool = false


@export var needs_los: bool = true


@export var deploy_to_every_aoe_space: bool = false

@export var remove_previous_deployments: bool = false

@export var disable_while_deployed: bool = false

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if unit.has_status(Lancer.STATUS.INTANGIBLE): return false
    if disable_while_deployed and not UnitAction.get_deployables_from(unit, gear, deployable_frame.compcon_id).is_empty(): return false
    return true

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    return false

func get_target_range(specific: SpecificAction) -> int:
    return specific.unit.get_sensor_range() if deploy_to_sensors else deploy_range

func get_target_requirements(specific: SpecificAction) -> TargetRequirements:
    var reqs: TargetRequirements
    if target_requirements_override:
        reqs = target_requirements_override.duplicate()
    else:
        reqs = TargetRequirements.new()
        reqs.can_target_empty_tiles = true
    reqs.check_if_tile_is_free = deploy_check_if_tile_is_free
    return reqs

func deploy_check_if_tile_is_free(tile: Vector2i, map: MapState) -> bool:

    if deployable_frame.is_mine and map.get_all_units_at_tiles(Tile.get_all_within(tile, 1, map), null, true).any(
        func(adjacent_unit: Unit) -> bool: return adjacent_unit.core.frame.is_mine
    ): return false


    return TargetRequirements.standard_check_if_tile_is_free(tile, map)

func get_aoe_preview_style() -> ShrinkwrapStyle: return ShrinkwrapStyle.VALID

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit != unit): return false
    var counter: PassiveDieCounter = gear.get_die_counter_passive()
    if(counter.get_current(gear) > 1):
        counter.reset(unit, gear, true)
        return true
    return false

func activate(context: Context, activation: EventCore) -> void :
    var unit: Unit = context.unit


    var plan: CompconPlan = await get_deploy_plan_targets(context, activation)
    if activation.abort_when( not CompconPlan.is_valid_with_targets(plan, context)): return

    spend_actions(activation)
    #await run_system_fxgs(unit, plan.target_tiles)
    if activation.abort_without_unit(unit): return


    place_deployables_at_target_tiles(activation, plan.target_tiles if not plan.target_tiles.is_empty() else unit.occupied_tiles())



func get_deploy_plan_targets(context: Context, activation: EventCore) -> CompconPlan:
    return await TargetActionUtil.ask_for_targets(activation)

func place_deployables_at_target_tiles(activation: EventCore, target_tiles: Array[Vector2i]) -> void :
    var context: = activation.context
    var specific: = SpecificAction.from_context(context)
    var aoe: RangePattern
    if has_method("get_range_patten_for_target"):
        aoe = call("get_range_pattern_for_target", specific)
    if has_method("get_range_patten_for_targets"):
        aoe = call("get_range_pattern_for_targets", specific)

    if remove_previous_deployments: queue_remove_previous_deployables(specific, activation)

    var flags: = []
    if deployable_frame.is_prop: flags.append(EventUnitSpawn.FLAG.SKIP_ANIMATION)
    if deploy_to_every_aoe_space and aoe:
        for aoe_tile: Vector2i in specific.action.get_aoe_tiles_with_target(
            aoe, 
            target_tiles, 
            context.unit.tile(), 
            specific, 
            UnitTile.get_tiles_in_los(specific.unit)
        ):
            place_deployable(context, activation, aoe_tile, deployable_frame, flags)
    else:
        for tile: Vector2i in target_tiles:
            place_deployable(context, activation, tile, deployable_frame, flags)

func place_deployable(context: Context, activation: EventCore, target_tile: Vector2i, frame: Frame, flags: Array = []) -> Unit:
    var map: MapState = context.map
    var unit: Unit = context.unit
    var gear: GearCore = context.gear
    var deployable: Unit

    if not Tile.is_valid(target_tile, map): return null
    deployable = Unit.create(UnitCore.create(Faction.NONE, frame))
    deployable.core.token_customization.chosen_mesh = frame.meshes.pick_random()
    deployable.set_facing( - Tile.position_2d_center(target_tile).angle_to_point(Tile.position_2d_center(unit.state.tile)) + (TAU / 4))
    UnitAction.set_deployable_owner(deployable, unit, gear)
    activation.queue_event(&"event_unit_spawn", {
        unit = deployable, 
        target_tiles = [target_tile], 
        flags = flags
    })

    return deployable

func queue_remove_previous_deployables(specific: SpecificAction, activation: EventCore) -> void :
    for previous_deployable: Unit in UnitAction.get_deployables_from(specific.unit, specific.gear, deployable_frame.compcon_id):
        activation.queue_event(&"event_unit_die", {unit = previous_deployable})

func is_placing_large_deployable(specific: SpecificAction) -> bool:
    var aoe: RangePattern
    if has_method("get_range_patten_for_target"):
        aoe = call("get_range_pattern_for_target", specific)
    if has_method("get_range_patten_for_targets"):
        aoe = call("get_range_pattern_for_targets", specific)
    return aoe and aoe.pattern == Lancer.AOE_TYPE.SIZE and aoe.value > 1

func is_tile_flat_enough_for_deployable(tile: Vector2i, deployable_size: int, map: MapState) -> bool:
    var starting_elev: int = map.elevation(tile)
    for check_tile: Vector2i in UnitTile.get_occupied(tile, deployable_size, map.size):
        if starting_elev != map.elevation(check_tile): return false
    return true
