extends Buff

func on_application(event: EventCore, core: BuffCore, unit: Unit) -> void:
    unit.core.current.speed = 1

func on_clear(event: EventCore, core: BuffCore, unit: Unit) -> void:
    unit.core.current.speed = unit.get_speed_max()

func activate(core: BuffCore, activation: EventCore) -> void:
    if(activation.context.unit.core.current.speed > 1):
        if(activation.context.unit.state.spaces_moved_this_turn > 1):
            activation.context.unit.core.current.speed = 0
        else:
            activation.context.unit.core.current.speed = 1
