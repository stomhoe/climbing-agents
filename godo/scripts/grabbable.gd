extends RigidBody3D
class_name Grabbable

@onready var collision_shape_3d = $CollisionShape3D

func get_data() -> Array:
    var data: Array = []
    data.append(global_position.x)
    data.append(global_position.y)
    data.append(global_position.z)
    data.append(rotation.x)
    data.append(rotation.y)
    data.append(rotation.z)
    data.append(linear_velocity.x)
    data.append(linear_velocity.y)
    data.append(linear_velocity.z)
    return data
