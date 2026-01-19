extends ActionReactionApplyBuff

@export var buff_slam: Buff

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    var attack_summary: DeclaredAttackSummary = activation.context.event.context.resource
    #print("Added")
    #for unit in attack_summary.all_attacked_units:
        #print(unit.core.persistent_id)
    for buff in buffs + [buff_slam]:
        buff.attacked_unit_ids = ([] as Array[StringName])
        for unit in attack_summary.all_attacked_units:
            buff.attacked_unit_ids.append(unit.core.persistent_id)
