extends RaycastSensor2D

func calculate_raycasts() -> Array:
    var result = []
    for ray in rays:
        ray.set_enabled(true)
        ray.force_raycast_update()
        var distance = _get_raycast_distance(ray)
        result.append(distance)

        var collider = ray.get_collider()

        if collider is not Boundaries:
            result.append(1.0)
        else:
            result.append(0.0)

        ray.set_enabled(false)
    return result
