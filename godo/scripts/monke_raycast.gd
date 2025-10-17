extends RaycastSensor2D

func calculate_raycasts() -> Array:
    var result = []
    for ray in rays:
        ray.set_enabled(true)
        ray.force_raycast_update()
        
        var dist: float = _get_raycast_distance(ray)
        
        result.append(dist)

        ray.set_enabled(false)
    return result
