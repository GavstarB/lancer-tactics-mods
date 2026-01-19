extends ActionSystemMovement

const DAMAGE_TO_CHARACTERS = 2
const DAMAGE_TO_OBJECTS = 10

var attacked_units_cache = {}

func get_per_turn_soft_limit(specific: SpecificAction) -> int:
    var counter: = specific.gear.get_die_counter_passive()
    if(counter.get_current(specific.gear) <= -1 and specific.gear.get_uses_this_turn(self) <= 0):
        counter.reset(specific.unit, specific.gear, true)
    return counter.get_current(specific.gear) + specific.gear.get_uses_this_turn(self) + 1

func get_per_round_hard_limit(specific: SpecificAction) -> int:
    return 99

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if not super.is_available_to_activate(unit, gear): return false
    return true

func get_movement_type(unit: Unit) -> MovementType:
    var use_movement_type: = MovementType.create(unit, true, false)
    return use_movement_type

func activate(context: Context, activation: EventCore) -> void:
    if not attacked_units_cache.has(context.gear.persistent_id):
        attacked_units_cache[context.gear.persistent_id] = []
    
    var uses = context.gear.get_uses_this_turn(self)
    await super.activate(context, activation)
    if activation.aborted: return
    if not Unit.is_valid(context.unit): return
    #if(uses == context.gear.get_uses_this_turn(self)): return
    
    var counter: = context.gear.get_die_counter_passive()
    var starting_value = counter.starting_value
    counter.starting_value = -1
    if(counter.get_current(context.gear) > -1):
        counter.decrease(context.unit, context.gear, 1)
    counter.starting_value = starting_value
    
    var specific = SpecificAction.create(context.unit, context.gear, self)
    var tiles: = UnitTile.get_adjacent_tiles(context.unit)
    var plan: CompconPlan = await choice_bus.choose_target_tiles(specific, tiles)
    if not CompconPlan.is_valid(plan, context.unit): return
    
    if not plan.target_tiles.is_empty():
        if(uses == context.gear.get_uses_this_turn(self)): 
            spend_actions(activation)
        
        var tile = plan.target_tiles[0]
        var units: Array[Unit] = []
        for unit in context.unit.map.get_all_units_at_tile(tile, context.unit, true):
            if UnitRelation.can_affect(context.unit, unit):
                units.append(unit)
        
        if not units.is_empty():
            var attacked_unit: Unit = units[0]
            if(len(units) > 1):
                #attacked_unit = await choice_bus.choose_unit(units, false, specific)
                attacked_unit = await choice_bus.disambiguate_targets(tile, units, false)
            if attacked_unit.is_character():
                # attack unit
                activation.queue_event(&"event_unit_damage", {
                    unit = attacked_unit, 
                    number = DAMAGE_TO_CHARACTERS, 
                    category = Lancer.DAMAGE_TYPE.KINETIC,
                    flags = [], 
                    target_unit = context.unit
                })
                
            else:
                # attack object
                await activation.execute_event(&"event_unit_damage", {
                    unit = attacked_unit, 
                    number = DAMAGE_TO_OBJECTS, 
                    category = Lancer.DAMAGE_TYPE.KINETIC,
                    flags = [Lancer.DAMAGE_FLAG.AP], 
                    target_unit = context.unit
                })
                #if activation.abort_without_unit(context.unit): return
                
                var is_destroyed = false
                if not Unit.is_valid(attacked_unit):
                    is_destroyed = true
                else:
                    if not attacked_unit.is_alive:
                        is_destroyed = true
                
                if is_destroyed:
                    var unit_height = context.unit.map.elevation(attacked_unit.state.tile)
                    if attacked_unit.has_status(Lancer.STATUS.FLYING):
                        unit_height += 3
                    var fxg = FxGroup.create_from_id(&"fxg_terrain_destroy", Vector3(tile.x, unit_height, tile.y))
                    fxg.run()
                    on_object_destroyed(activation, context, tile, unit_height)
            
            if not attacked_units_cache[context.gear.persistent_id].has(attacked_unit):
                attacked_units_cache[context.gear.persistent_id].append(attacked_unit)
            return
        
        else:
            # attack terrain
            var is_destroyed = false
            var height = context.unit.map.elevation_ground(tile) - 1
            var current_damage = context.unit.map.game_core.get_current_damage_to_tile(tile)
            var gamemaster: = X.current_level()
            if gamemaster is Gamemaster:
                var landscape: LandscapeNode = gamemaster.get_landscape_node()
                if landscape:
                    var voxel: = Tile.to_voxel(tile, height)
                    
                    var setpiece: Setpiece
                    var setpiece_id: int = landscape.get_setpiece_id_for_tile(tile)
                    if setpiece_id != 0:
                        setpiece = LandscapeLibrary.get_setpiece(setpiece_id)
                    
                    var terrain: TerrainBlockData = landscape.get_terrain_for_voxel(voxel)
                    if setpiece and setpiece.terrain and setpiece.terrain.is_destructable(): terrain = setpiece.terrain
                    if terrain.is_destructable():
                        if(current_damage + DAMAGE_TO_OBJECTS >= terrain.get_health()):
                            is_destroyed = true
            
            await activation.execute_event(&"event_map_damage", {
                target_tiles = [tile], 
                number = DAMAGE_TO_OBJECTS, 
                flags = [EventMapDamage.FLAG.AP], 
            })
            if activation.abort_without_unit(context.unit): return
            
            if(is_destroyed):
                on_object_destroyed(activation, context, tile, height)
            
            if not attacked_units_cache[context.gear.persistent_id].has(null):
                attacked_units_cache[context.gear.persistent_id].append(null)

func on_object_destroyed(activation: EventCore, context: Context, tile: Vector2i, height: int):
    var specific = SpecificAction.create(context.unit, context.gear, self)
    var exploded_tiles: = Tile.get_all_within(tile, 1, context.unit.map)
    exploded_tiles.erase(tile)
    var units: Array[Unit] = []
    for unit in context.unit.map.get_all_units_at_tiles(exploded_tiles):
        var unit_height = context.unit.map.elevation(unit.state.tile)
        if unit.has_status(Lancer.STATUS.FLYING):
            unit_height += 3
        if(abs(unit_height - height) <= 2):
            if(unit != context.unit):
                if unit.is_character():
                    units.append(unit)
    var damage = Dice.roll_d6()
    for unit in units:
        activation.queue_events(CommonActionUtil.generate_knockback_events(unit, 1, specific, [tile], []))
    for unit in units:
        activation.queue_event(&"event_unit_damage", {
            unit = unit, 
            number = damage, 
            category = Lancer.DAMAGE_TYPE.KINETIC,
            flags = [], 
            target_unit = null
        })
    if not attacked_units_cache.has(context.gear.persistent_id):
        attacked_units_cache[context.gear.persistent_id] = []
    for unit in units:
        if not attacked_units_cache[context.gear.persistent_id].has(unit):
            attacked_units_cache[context.gear.persistent_id].append(unit)
