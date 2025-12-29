extends ActionReaction

@export var buff: Buff
@export var buff2: Buff

func activate(context: Context, activation: EventCore) -> void:
    UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id)
    #UnitCondition.clear_buff_id(activation, context.unit, buff2.compcon_id)
