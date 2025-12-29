extends MechMount

static func create(mount_type: Lancer.MOUNT) -> MechMount:
    var mount: = new()
    mount.type = mount_type
    mount.persistent_id = Util.generate_scene_unique_id()
    return mount

func can_brace() -> bool:
    return type == Lancer.MOUNT.HEAVY and not is_integrated

func get_legal_primary_sizes() -> Array[Lancer.WEAPON_SIZE]:
    match type:
        Lancer.MOUNT.MAIN:
            return [Lancer.WEAPON_SIZE.AUX, Lancer.WEAPON_SIZE.MAIN]
        Lancer.MOUNT.AUX_AUX:
            return [Lancer.WEAPON_SIZE.AUX]
        Lancer.MOUNT.FLEX:
            return [Lancer.WEAPON_SIZE.AUX, Lancer.WEAPON_SIZE.MAIN]
        Lancer.MOUNT.MAIN_AUX:
            return [Lancer.WEAPON_SIZE.AUX, Lancer.WEAPON_SIZE.MAIN]
        Lancer.MOUNT.HEAVY:
            return [Lancer.WEAPON_SIZE.AUX, Lancer.WEAPON_SIZE.MAIN, Lancer.WEAPON_SIZE.HEAVY] #, Lancer.WEAPON_SIZE.SUPERHEAVY
        Lancer.MOUNT.AUX:
            return [Lancer.WEAPON_SIZE.AUX]
        6:
            return [Lancer.WEAPON_SIZE.SUPERHEAVY]
    return []
