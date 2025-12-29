extends ActionSystemClearBuff

func can_be_used_situationally_by(unit: Unit, situational_unit: Unit, situational_gear: GearCore) -> bool:
    return clear_buffs.any( func(buff: Buff) -> bool:
        return UnitCondition.has_buff(unit, buff.compcon_id)
    )

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    return clear_buffs.any( func(buff: Buff) -> bool:
        return UnitCondition.has_buff(unit, buff.compcon_id)
    )

func activate(context: Context, activation: EventCore) -> void:
    var suffering_unit: Unit = context.unit
    var buffs_to_clear: Array[BuffCore] = []
    Util.map_and_remove_nulls(buffs_to_clear, clear_buffs, func(buff: Buff) -> BuffCore:
        return UnitCondition.get_buff(suffering_unit, buff.compcon_id)
    )

    if activation.abort_when(buffs_to_clear.is_empty()): return

    var applier_unit: Unit = buffs_to_clear[0].get_owner_unit()
    var applier_gear: GearCore = buffs_to_clear[0].get_owner_gear()
    var applier_action: = applier_gear.get_solo_action()
    var applier_specific: = SpecificAction.create(applier_unit, applier_gear, applier_action)

    var confirmed: = await CommonActionUtil.confirm_use(context)
    if activation.abort_when( not confirmed): return
    spend_actions(activation)

    var passed_save: bool = true
    if make_save:
        if is_check_instead_of_save:
            passed_save = await UnitHasecheck.make_check(activation, suffering_unit, 10, make_save_type)
        else:
            passed_save = await UnitHasecheck.make_save(activation, suffering_unit, applier_specific, make_save_type)
        if activation.abort_without_units([suffering_unit, applier_unit]): return

    if passed_save:
        for buff_to_clear in buffs_to_clear:
            UnitCondition.clear_buff(activation, suffering_unit, buff_to_clear)
        await clear_additional_effect(SpecificAction.from_context(context), suffering_unit, activation)
