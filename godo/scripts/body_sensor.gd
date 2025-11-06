extends RaycastSensor2D
class_name BodySensor

var first: bool = false

func get_raycasts() -> PackedFloat64Array:
    var result: PackedFloat64Array = PackedFloat64Array()
    result.resize(int(n_rays)*2)
    for i in range(int(n_rays)):
        var ray: RayCast2D = rays[i]
        ray.enabled = true

        if Config.collision_enabled:
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
