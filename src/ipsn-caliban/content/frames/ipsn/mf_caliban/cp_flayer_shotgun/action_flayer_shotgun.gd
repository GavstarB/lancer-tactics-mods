extends ActionAttackWeapon

@export var butt_attack: ActionAttackWeapon
@export var buff: Buff

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    var units: Array[Unit] = context.map.get_all_units_at_tiles(Tile.get_neighbors(context.unit.state.tile, context.map), context.unit)
    if(len(units) > 0):
        var buff_core = UnitCondition.apply_buff(activation, context.unit, buff, context.gear)
        
        #var status_cache: Array[StatusCondition] = []
        #for status in context.unit.state.statuses:
            #status_cache.append(status)
        #context.unit.state.statuses.append(StatusCondition.new(Lancer.STATUS.IMMOBILIZED, Lancer.UNTIL.MANUAL))
        #context.unit.update_cached_values_and_token()
        
        var composed_context: = Context.clone(context, {action = butt_attack, flags = []})
        if(context.is_property_present(Context.PROP.flags)):
            composed_context.flags = context.flags
        composed_context.flags.append_array([Action.FLAG.IS_FOLLOWUP, Action.FLAG.AS_FREEBIE])
        composed_context.object = null
        activation.context = composed_context
        await butt_attack.activate(composed_context, activation)
        activation.context = context
        
        #context.unit.state.statuses = status_cache
        #context.unit.update_cached_values_and_token()
        
        UnitCondition.clear_buff(activation, context.unit, buff_core)
