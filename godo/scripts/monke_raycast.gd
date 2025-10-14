extends RaycastSensor2D

func calculate_raycasts() -> Array:
    var result = []
    for ray in rays:
        ray.set_enabled(true)
        ray.force_raycast_update()
        result.append(_get_raycast_distance(ray))

        ray.set_enabled(false)
    return result
