extends PassiveMountMod

const IMPROVED_MOUNT_KEY: = "mount_id"
#var SUPERHEAVY = 6

#func str_to_unique_int(string: String) -> int:
    #string = string.substr(0, 8)
    #var acc = 0
    #var buffer = string.to_ascii_buffer()
    #for i in range(len(buffer)):
        #if(i == 0):
            #acc += buffer.get(i)
        #else:
            #acc = (acc*128)+buffer.get(i)
        ##print(acc)
        ##print(i)
        ##print(acc < 9223372036854775807)
    ##print(string)
    #return acc

#func _init() -> void:
    #SUPERHEAVY = 6
    #str_to_unique_int("SUPERHEAVY")

func get_modified_mounts(mount_mod_gear: GearCore, new_mounts: Array[MechMount], old_mounts: Array[MechMount]) -> Array[MechMount]:
    var modified_mounts: Array[MechMount] = []
    modified_mounts.assign(new_mounts)
    
    #for i in range(len(old_mounts)):
        #print(old_mounts[i].persistent_id)

    var nonintegrated_count: int = new_mounts.reduce(
        func(accum: int, mount: MechMount): return accum + (0 if mount.is_integrated else 1), 
        0
    )

    if nonintegrated_count < 3:
        var mount_script = load("res://content/gear/gms/core_bonuses/cb_superheavy_mounting/mech_mount_superheavy.gd")
        var improved_mount: MechMount = mount_script.create(6)

        improved_mount.persistent_id = mount_mod_gear.get_configuration(IMPROVED_MOUNT_KEY, improved_mount.persistent_id)
        mount_mod_gear.set_configuration(IMPROVED_MOUNT_KEY, improved_mount.persistent_id)
        
        var heavy_count: int = new_mounts.reduce(
            func(accum: int, mount: MechMount): return accum + (1 if mount.type == Lancer.MOUNT.HEAVY else 0), 
            0
        )
        
        if(heavy_count > 0):
            for i in range(len(modified_mounts)):
                var new_mount: MechMount = mount_script.new()
                new_mount.inherit_from_mount(modified_mounts[i])
                #if(i < len(old_mounts)):
                    #new_mount.persistent_id = old_mounts[i].persistent_id
                    #print(modified_mounts[i].persistent_id, " ", old_mounts[i].persistent_id)
                    #print(modified_mounts[i].type, " ", old_mounts[i].type)
                #new_mount.slot_primary = modified_mounts[i].slot_primary
                #new_mount.slot_secondary = modified_mounts[i].slot_secondary
                #new_mount.is_bracing = modified_mounts[i].is_bracing
                
                new_mount.type = modified_mounts[i].type
                new_mount.is_integrated = modified_mounts[i].is_integrated
                new_mount.is_integrated_swappable = modified_mounts[i].is_integrated_swappable
                modified_mounts[i] = new_mount
        
        #print(modified_mounts)
        #for mount in modified_mounts:
        #    print(mount.persistent_id)
        
        #improved_mount.is_integrated = true
        #improved_mount.is_integrated_swappable = true
        
        #modified_mounts.push_front(improved_mount)
        modified_mounts.push_front(improved_mount)
        for i in range(len(old_mounts)):
            if(i < len(modified_mounts)):
                modified_mounts[i].persistent_id = old_mounts[i].persistent_id
        #if(old_mounts[0].type == 6):
            #for i in range(len(old_mounts)):
                #if(i < len(modified_mounts)):
                    #modified_mounts[i].persistent_id = old_mounts[i].persistent_id
        #else:
            #for i in range(len(old_mounts)):
                #if(i+1 < len(modified_mounts)):
                    #modified_mounts[i+1].persistent_id = old_mounts[i].persistent_id
        
        if(heavy_count > 0):
            #print(old_mounts)
            var added_bracing = false
            var has_superheavy = false
            for i in range(len(old_mounts)):
                if(old_mounts[i].has_primary()):
                    #print(Lancer.WEAPON_SIZE.keys()[old_mounts[i].get_kit_weapon_size(old_mounts[i].slot_primary.kit)])
                    if(old_mounts[i].get_kit_weapon_size(old_mounts[i].slot_primary.kit) == Lancer.WEAPON_SIZE.SUPERHEAVY and not old_mounts[i].is_integrated):
                        has_superheavy = true
            
            for i in range(len(old_mounts)):
                if(old_mounts[i].is_bracing):
                    old_mounts[i].is_bracing = false
                if(i < len(modified_mounts)):
                    if(modified_mounts[i].type == Lancer.MOUNT.HEAVY and has_superheavy and not added_bracing):
                        old_mounts[i].is_bracing = true
                        added_bracing = true
                
                #print(old_mounts[i].has_primary(), " ", old_mounts[i].is_bracing, " ", Lancer.MOUNT.keys()[old_mounts[i].type])
        
        #old_mounts.push_back(MechMount.create(6))
        old_mounts.append(improved_mount)

    return modified_mounts
