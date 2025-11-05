extends Node2D
class_name Config

const MAP_SCENE: PackedScene = preload("res://scenes/climb_map.tscn")

var instantiated_maps: Array[ClimbMap] = []
@onready var sync = $Sync

var n_arenas: int:
    set(value):
        n_arenas = value
        for child in get_children():
            if child is ClimbMap:
                child.queue_free()
        for i in range(n_arenas):
            var map_instance: ClimbMap = MAP_SCENE.instantiate()
            map_instance.name = "ClimbMap_%d" % i
            self.add_child(map_instance)
            instantiated_maps.append(map_instance)
            var sep: float = 3000. if (sync.args.has("show_window") or not sync.args.has("env_path")) else 100000.
            map_instance.position = Vector2( i * sep, 0)
            map_instance.climbers_initialized.connect(on_climbers_initialized)

var n_climbers: int:
    set(value):
        n_climbers = value
        for map_instance in instantiated_maps:
            map_instance.n_climbers = n_climbers

static var round_duration: float = 120.

static var init_rand_mult: float = 0.0

static var speed_up: float = 1.0
static var infection_ratio: float = 1.0

static var rand_incr: float = 0.01
static var rand_cap: float = 1.0

static var pvp_on_round: int = -1

static var collision_enabled: bool = false

func _ready():

    if sync.args.has(&"n_arenas"):
        n_arenas = int(sync.args[&"n_arenas"])
    else:
        n_arenas = 2
    
    if sync.args.has(&"n_climbers"):
        n_climbers = int(sync.args[&"n_climbers"])
    else:
        n_climbers = 15
        
    if sync.args.has(&"round_duration"):
        round_duration = float(sync.args[&"round_duration"])

    if sync.args.has(&"random"):
        init_rand_mult = float(sync.args[&"random"])

    if sync.args.has(&"infection_ratio"):
        infection_ratio = float(sync.args[&"infection_ratio"])

    if sync.args.has(&"rand_incr"):
        rand_incr = float(sync.args[&"rand_incr"])

    if sync.args.has(&"rand_cap"):
        rand_cap = float(sync.args[&"rand_cap"])

    if sync.args.has(&"pvp"):
        pvp_on_round = int(sync.args[&"pvp"])

    if sync.args.has(&"collision_enabled"):
        collision_enabled = bool(sync.args[&"collision_enabled"])

    speed_up = sync.speed_up

    

var climbers_initialized_count: int = 0
func on_climbers_initialized():
    climbers_initialized_count += 1
    if climbers_initialized_count == n_arenas:
        sync._initialize()
