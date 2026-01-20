extends ActionReactionAttacked

@export var fxg_target: PackedScene
@export var fxg_aoe: PackedScene

func get_per_round_hard_limit(specific: SpecificAction) -> int: return 1

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if not super.triggers_on_event(unit, gear, triggering_event): return false
    if not triggering_event.context.action is ActionAttackWeapon: return false
    #var weapon: ActionAttackWeapon = triggering_event.context.action
    for mod in triggering_event.context.gear.get_all_weapon_mod_gear(unit.core.loadout):
        if(mod == gear):
            return true
    return false

func activate(context: Context, activation: EventCore) -> void:
    var target_unit: = activation.context.event.context.target_unit
    var specific: = SpecificAction.create(context.unit, context.gear, self)
    if not await CommonActionUtil.confirm_use_alt(specific): return
    
    var action: = ActionAttackWeapon.new()
    action.weapon_size = Lancer.WEAPON_SIZE.NONE
    action.range_pattern = RangePattern.create(Lancer.AOE_TYPE.CONE, 3)
    #var specific2 = SpecificAction.create(context.unit, context.gear, action)
    
    #var plan = await TargetActionUtil.ask_for_targets_alt(activation, specific2)
    var plan = await TargetActionUtil.ask_for_targets_from_proxy(activation, context.unit, context.gear, action, target_unit.state.tile, target_unit.get_size())
    if not plan.is_valid_with_targets(plan, context): return
    var tiles: Array[Vector2i] = []
    if action.has_method("get_aoe_tiles_with_target"):
        tiles = await action.call("get_aoe_tiles_with_target", action.range_pattern, plan.target_tiles, target_unit.state.tile, SpecificAction.create(context.unit, context.gear, action))
    if action.has_method("get_aoe_tiles_with_targets"):
        tiles = await action.call("get_aoe_tiles_with_targets", action.range_pattern, plan.target_tiles, target_unit.state.tile, SpecificAction.create(context.unit, context.gear, action))
    
    spend_actions(activation)
    
    var units: Array[Unit] = [target_unit]
    for unit in context.unit.map.get_all_units_at_tiles(tiles, context.unit):
        if unit.is_character():
            units.append(unit)
    
    tiles.append(target_unit.state.tile)
    await FxGroup.run_attack_and_targets(
        fxg_target, target_unit, 
        null, [], 
        fxg_aoe, tiles, 
        true
    )
    
    for unit in units:
        activation.queue_event(&"event_unit_damage", {
            unit = unit, 
            number = 2, 
            category = Lancer.DAMAGE_TYPE.EXPLOSIVE,
            flags = [], 
            target_unit = context.unit
        })
    
    activation.queue_event(&"event_unit_damage", {
        unit = context.unit, 
        number = 1, 
        category = Lancer.DAMAGE_TYPE.HEAT,
        flags = [Lancer.DAMAGE_FLAG.SELF_INFLICTED], 
        target_unit = context.unit
    })
