extends AIController3D
class_name AiLandDroneController

@onready var rgb_camera_sensor_3d: RGBCameraSensor3D = $yaw_joint/roll_joint/mg_rigid/RGBCameraSensor3D
@onready var car: LandDrone = get_parent()


func get_obs() -> Dictionary:
    var obs: PackedFloat64Array = PackedFloat64Array([
        car.linear_velocity.x,
        car.linear_velocity.z,
        car.mg_rigid.global_rotation.x,
        car.mg_rigid.global_rotation.y,
        car.mg_rigid.angular_velocity.x,
        car.mg_rigid.angular_velocity.y,
        
    ])
    obs.append_array(rgb_camera_sensor_3d.get_camera_pixel_encoding().to_ascii_buffer().to_float64_array())
    return {"obs":obs}

func get_reward() -> float:	
    return reward
    
func get_action_space() -> Dictionary:
    return {
        "wheels" : {"size": 4, "action_type": "continuous"},
        "turret_rot" : {"size": 2, "action_type": "continuous"},
        "fire" : {"size": 1, "action_type": "discrete"},


    }

var wheel_forces: Vector4 = Vector4.ZERO
var turret_rotation: Vector2 = Vector2.ZERO
var fire_command: bool = false

func set_action(action: Dictionary) -> void:	
    wheel_forces.x = action.get(&"wheels")[0]
    wheel_forces.y = action.get(&"wheels")[1]
    wheel_forces.z = action.get(&"wheels")[2]
    wheel_forces.w = action.get(&"wheels")[3]
    turret_rotation.x = action.get(&"turret_rot")[0]
    turret_rotation.y = action.get(&"turret_rot")[1]
    fire_command = action.get(&"fire") as bool
