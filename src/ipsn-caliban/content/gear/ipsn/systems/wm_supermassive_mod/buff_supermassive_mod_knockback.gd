extends BuffWeaponType

func get_values(core: BuffCore, context: Context = null) -> Context:
    #print("test")
    #print(core.get_owner_unit(context.unit.map).core.frame.compcon_id)
    #print(core.get_owner_gear(context.unit.map).kit.compcon_id)
    #print(context.gear.kit.compcon_id)
    
    var owner_mod: GearCore = core.get_owner_gear(context.unit.map)
    var valid = false
    for mod in context.gear.get_all_weapon_mod_gear(context.unit.core.loadout):
        print(mod.kit.compcon_id)
        if(mod == owner_mod):
            valid = true
    if valid:
        if(owner_mod.kit.compcon_id == &"wm_supermassive_mod"):
            return Context.create({ number = 1 })
        elif(owner_mod.kit.compcon_id == &"wm_supermassive_mod_no_limiters_melee" or owner_mod.kit.compcon_id == &"wm_supermassive_mod_no_limiters_ranged"):
            return Context.create({ number = 2 })
    
    return Context.create({ number = 0 })
