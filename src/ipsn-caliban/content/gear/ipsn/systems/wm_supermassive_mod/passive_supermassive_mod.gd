extends PassiveWeaponMod

static var character_sheet_script = preload("res://ui/page/character_sheet/character_sheet.gd")

func get_child(node: Node, name: StringName) -> Node:
    if(node != null):
        for child in node.get_children():
            if(child.name == name):
                return child
    return null

func print_children(node: Node):
    for child in node.get_children():
        print(child.name)

func get_unit_core() -> UnitCore:
    var scene_tree = Engine.get_main_loop()
    if(is_instance_of(scene_tree, SceneTree)):
        scene_tree = scene_tree as SceneTree
        var root: Node = scene_tree.get_root()
        var node: Node = root
        for name in [&"LancerTactics", &"campaign_title_screen", &"LevelTitle", &"Interface", &"Default", &"CharacterSheet"]:
            node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_instant_action", &"LevelFightSetup", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_editor", &"LevelCombatEditor", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_instant_action", &"Gamemaster", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        #print_children(node)
        #node.print_tree_pretty()
        if(node != null):
            return node.unit_core
    return null

func is_applicable_to(gear: GearCore) -> bool:
    if not super.is_applicable_to(gear):
        return false
    
    #character_sheet_script.character_sheet_bus.save_character.emit()
    
    #var user_pilots: Dictionary[String, UnitCore] = UserContentLibrary.get_all_user_pilots()
    #for unit_core: UnitCore in user_pilots.values():
    
    var unit_core = get_unit_core()
    if(unit_core != null):
        for unit_gear in unit_core.loadout.get_all_weapons():
            if(unit_gear.persistent_id == gear.persistent_id):
                #print("")
                #print("this: ", gear.kit.compcon_id, " ", gear.persistent_id)
                for weapon in unit_core.loadout.get_all_weapons():
                    if(weapon.persistent_id != gear.persistent_id):
                        #print(unit_core.loadout.get_by_compcon_id(&"wm_supermassive_mod"))
                        #print("other: ", weapon.kit.compcon_id)
                        for mod in weapon.get_all_weapon_mod_gear(unit_core.loadout):
                            #print(mod.kit.compcon_id)
                            if [&"wm_supermassive_mod", &"wm_supermassive_mod_no_limiters_ranged", &"wm_supermassive_mod_no_limiters_melee"].has(mod.kit.compcon_id):
                                #print("test1")
                                return false
                #print("test2")
                return true
    return true
