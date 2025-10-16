extends RaycastSensor2D

func calculate_raycasts() -> Array:
    var result = []
    for ray in rays:
        ray.set_enabled(true)
        ray.force_raycast_update()
        
        var dist: float = _get_raycast_distance(ray)
        if dist == 0:
            dist = 999999999999999.0
        
        result.append(dist)

        ray.set_enabled(false)
    return result
