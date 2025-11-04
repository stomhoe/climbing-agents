extends RaycastSensor2D
class_name BodySensor


func get_raycasts() -> PackedFloat64Array:
    var result: PackedFloat64Array = PackedFloat64Array()
    result.resize(int(n_rays))
    for i in range(int(n_rays)):
        var ray: RayCast2D = rays[i]
        ray.enabled = true
        ray.force_raycast_update()
        var object: Object = ray.get_collider()

        var distance: float = _get_raycast_distance(ray)
        result[i] = distance * 1 if object is StaticBody2D else -1.0
        
                
        ray.enabled = false
    return result
