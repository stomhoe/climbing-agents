extends RigidBody3D
class_name Grabbable

func get_data() -> Array:
    var data: Array = []
    data.append(global_position)
    data.append(rotation)
    data.append(linear_velocity)
    data.append(angular_velocity)
    return data
