extends ActionAttackWeapon

const DAMAGE_TO_OBJECTS = 30

@export var buff: Buff

var hit_unit: Unit = null
var hit_unit_tile: = Tile.INVALID
var hit_unit_height = 0

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    var charged: Dictionary = gear.get_state("charged", {})
    if charged.has(gear.persistent_id):
        return charged[gear.persistent_id]
    return false

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    if not Unit.is_valid(hit_unit) and (hit_unit_tile != Tile.INVALID):
        var fxg = FxGroup.create_from_id(&"fxg_terrain_destroy", Vector3(hit_unit_tile.x, hit_unit_height, hit_unit_tile.y))
        fxg.run()
        on_object_destroyed(activation, context, hit_unit_tile, hit_unit_height)
    hit_unit = null
    hit_unit_tile = Tile.INVALID
    hit_unit_height = 0
    
    if GearCore.is_valid(context.gear):
        context.gear.wake_action(&"action_charge_d_d_288")
        context.gear.hibernate_action(&"action_disperse_d_d_288")
        context.gear.wake_action(&"action_d_d_288_uncharged")
        context.gear.hibernate_action(&"action_d_d_288_charged")
        var charged: Dictionary = context.gear.get_state("charged", {})
        charged[context.gear.persistent_id] = false
        context.gear.set_state("charged", charged)
        if Unit.is_valid(context.unit):
            UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id, context.gear.persistent_id)

func get_attacked_tiles_and_units_from_plan(activation: EventCore, specific: SpecificAction, plan: CompconPlan) -> Dictionary:
    for target_tile in plan.target_tiles:
        var attacked_units: = activation.context.map.get_all_units_at_tiles([target_tile], specific.unit)
        if not attacked_units.is_empty():
            var unit = await TargetActionUtil.disambiguate_target_tile_to_single_unit(target_tile, specific, activation.context.unit)
            plan.target_units.append(unit)
            plan.target_tiles = []
    
    return super.get_attacked_tiles_and_units_from_plan(activation, specific, plan)

func automatically_hits_terrain_and_objects(specific: SpecificAction) -> bool: return true

func get_damage_to_terrain_and_objects(specific: SpecificAction, damage_data: AttackUtil.DamageRollSummary) -> int: return DAMAGE_TO_OBJECTS

func on_hit(activation: EventCore, attacked_unit: Unit) -> void:
    #print("on hit")
    #print(attacked_unit)
    
    if not attacked_unit.is_character():
        hit_unit = attacked_unit
        hit_unit_tile = attacked_unit.state.tile
        hit_unit_height = activation.context.map.elevation(attacked_unit.state.tile)
        if attacked_unit.has_status(Lancer.STATUS.FLYING):
            hit_unit_height += 3

func on_targeted_tiles(activation: EventCore, direct_target_tiles: Array[Vector2i], all_target_tiles: Array[Vector2i]) -> void:
    #print("on target tiles")
    #print(direct_target_tiles)
    #print(all_target_tiles)
    
    if not direct_target_tiles.is_empty():
        var context: = activation.context
        var tile = direct_target_tiles[0]
        
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

        if(is_destroyed):
            on_object_destroyed(activation, context, tile, height)

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
