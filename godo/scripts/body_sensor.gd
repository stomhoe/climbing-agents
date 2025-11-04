extends RaycastSensor2D
class_name BodySensor


func get_raycasts() -> PackedFloat64Array:
    var result: PackedFloat64Array = PackedFloat64Array()
    result.resize(int(n_rays)*2)
    for i in range(n_rays):
        var ray: RayCast2D = rays[i]
        ray.enabled = true
        ray.force_raycast_update()
        var object: Object = ray.get_collider()

        var distance: float = _get_raycast_distance(ray)
        result[i * 2] = distance
        var classf_i: int = i * 2 + 1
        if object is BodyPart:
            if (object as BodyPart).climber.role == Climber.Role.INFECTED:
                result[classf_i] = 1.0
            else:
                result[classf_i] = 0.5
                
        ray.enabled = false
    return result
