extends RaycastSensor2D
class_name BodySensor

var accumulated: PackedFloat64Array = PackedFloat64Array()
var accumulation_count: int = 0
var time_since_last_update: float = 0.0
const MAX_ACC: int = 10
@onready var _sync: Sync = (get_tree().root.get_child(0) as ClimbMap).sync

func _ready() -> void:
    current_raycasts.resize(int(n_rays) + 2)
    accumulated.resize(current_raycasts.size() * MAX_ACC)

func _physics_process(delta: float):
    delta += _sync.speed_up
    time_since_last_update += delta
    if time_since_last_update > 3.0:
        time_since_last_update = 0.0
        update_raycasts()
        var raycast_size: int = current_raycasts.size()
        var index: int = accumulation_count % MAX_ACC
        for i in range(raycast_size):
            accumulated[index * raycast_size + i] = current_raycasts[i]
        accumulation_count += 1

var current_raycasts = PackedFloat64Array()
func update_raycasts():
    for i in rays.size():
        var ray = rays[i]
        ray.enabled = true
        ray.force_raycast_update()
        var distance = _get_raycast_distance(ray)
        current_raycasts[i] = distance
        ray.enabled = false
    current_raycasts[rays.size()] = global_position.x / AIClimbController.POS_DIV
    current_raycasts[rays.size() + 1] = global_position.y / AIClimbController.POS_DIV
