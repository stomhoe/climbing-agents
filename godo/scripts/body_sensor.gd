extends RaycastSensor2D
class_name BodySensor


var accumulated_obs: PackedFloat64Array = PackedFloat64Array()

var reset_time: float = 0.6
var rem_time_until_new_accumulation: float = 0.0

func _physics_process(delta: float) -> void:
    delta *= Config.speed_up
    rem_time_until_new_accumulation -= delta
    if rem_time_until_new_accumulation <= 0.0:
        accumulate_raycasts()
        rem_time_until_new_accumulation = reset_time

func _ready() -> void:
    super._ready()
    accumulated_obs.resize(int(n_rays)*max_accumulations * 2)

var max_accumulations: int = 10

var accumulated_obs_index: int = 0

func accumulate_raycasts():
    var raycasts = get_raycasts_static_only()
    var obs_per_accumulation = int(n_rays) + 2  # raycasts + x + y position
    
    for i in range(int(n_rays)):
        accumulated_obs[accumulated_obs_index * obs_per_accumulation + i] = raycasts[i]
    
    accumulated_obs[accumulated_obs_index * obs_per_accumulation + int(n_rays)] = global_position.x
    accumulated_obs[accumulated_obs_index * obs_per_accumulation + int(n_rays) + 1] = global_position.y
    
    accumulated_obs_index = (accumulated_obs_index + 1) % max_accumulations
    
    rem_time_until_new_accumulation = reset_time


func get_raycasts() -> PackedFloat64Array:
    var result: PackedFloat64Array = PackedFloat64Array()
    result.resize(int(n_rays)*2)
    for i in range(int(n_rays)):
        var ray: RayCast2D = rays[i]
        ray.enabled = true

        if Config.collision:
            ray.collision_mask = 2; ray.force_raycast_update()
            var object: Object = ray.get_collider()
            var distance: float = _get_raycast_distance(ray)
            
            if object != null and object is BodyPart:
                var climber: Climber = (object as BodyPart).get_parent()
                distance *= 1 if climber.role != Climber.Role.INFECTED else -1
            result[i * 2] = distance

        #estaticos
        ray.collision_mask = 4; ray.force_raycast_update()
        result[i * 2 + 1] = _get_raycast_distance(ray)
        
                
        ray.enabled = false
    return result

func get_raycasts_static_only() -> PackedFloat64Array:
    var result: PackedFloat64Array = PackedFloat64Array()
    result.resize(int(n_rays))
    for i in range(int(n_rays)):
        var ray: RayCast2D = rays[i]
        ray.enabled = true

        ray.collision_mask = 4; ray.force_raycast_update()
        result[i] = _get_raycast_distance(ray)
                
        ray.enabled = false
    return result
