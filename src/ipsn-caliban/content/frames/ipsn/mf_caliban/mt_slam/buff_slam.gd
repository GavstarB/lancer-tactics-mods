extends Buff

@export var attacked_unit_ids: Array[StringName] = []

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if not Unit.is_valid(triggering_event.context.unit): return false
    
    if not triggering_event.context.is_property_present(Context.PROP.event): return false
    var move_event: EventCore = triggering_event.context.event
    if(move_event.context.unit == unit): return false
    if UnitRelation.are_allies(move_event.context.unit, unit): return false
    if not move_event.context.is_property_present(Context.PROP.object): return false
    var specific: SpecificAction = move_event.context.object
    if(specific.unit != unit): return false
    
    #print(attacked_unit_ids)
    var is_attacked_unit = false
    for id in attacked_unit_ids:
        if(triggering_event.context.unit.core.persistent_id == id): 
            is_attacked_unit = true
    if not is_attacked_unit: return false
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var context: Context = activation.context.event.context
    var unit: Unit = core.get_holder_unit(context.map)
    var attacked_unit = context.unit
    
    var specific = SpecificAction.from_id(unit, &"mt_slam")
    if not await CommonActionUtil.confirm_use_alt(specific): return
    
    if not await UnitHasecheck.make_save(activation, attacked_unit, specific, Lancer.HASE.HULL):
        
        activation.queue_event(&"event_unit_damage", {
            unit = attacked_unit, 
            number = Dice.roll_d6(),
            category = Lancer.DAMAGE_TYPE.KINETIC,
            flags = [],
            target_unit = unit, 
            gear = specific.gear, 
            action = specific.action, 
        }, Priority.ATTACK.dice)
        
        UnitCondition.apply_status(activation, attacked_unit, Lancer.STATUS.IMPAIRED, Lancer.UNTIL.END_OF_NEXT_TURN, unit.core.loadout.get_by_compcon_id(&"mt_slam").persistent_id)
    
    UnitCondition.clear_buff(activation, unit, core)
