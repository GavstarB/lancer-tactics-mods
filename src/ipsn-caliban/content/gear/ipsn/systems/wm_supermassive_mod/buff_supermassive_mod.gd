extends BuffBonus

func check_if_passive_applies(core: BuffCore, context: Context) -> bool:
    if not (context.is_property_present(Context.PROP.gear) and context.is_property_present(Context.PROP.action)): return false
    #print(context.gear.kit.compcon_id)
    for mod in context.gear.get_all_weapon_mod_gear(context.unit.core.loadout):
        #print(mod.kit.compcon_id)
        if(context.gear.is_weapon_mod_attached(mod.persistent_id) and mod.kit.compcon_id == &"wm_supermassive_mod_no_limiters_melee"):
        #if(mod.kit.compcon_id == &"wm_supermassive_mod_no_limiters_melee"):
            if is_instance_of(context.action, ActionAttackWeapon):
                if(Dice.process_dice_string((context.action as ActionAttackWeapon).attack_accuracy).bonus >= 0):
                    return true
    return false
