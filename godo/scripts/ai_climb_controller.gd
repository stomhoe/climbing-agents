extends AIController2D
class_name AIClimbController

@onready var climber: Climber = $".."
@onready var node_above: Node2D = $NodeAbove

@onready var body_sensor: RaycastSensor2D = $NodeAbove/RaycastBody
@onready var raycast_right: RaycastSensor2D = $NodeAbove/RaycastRight
@onready var raycast_left: RaycastSensor2D = $NodeAbove/RaycastLeft
@onready var label: Label = $NodeAbove/Label

func _process(_delta: float):
    label.text = str(int(reward))
    

func get_obs() -> Dictionary:
    var obs: Array = [
        climber.target_angle/(2.*PI),
        climber.torso.global_rotation/(2.*PI),
        climber.torso.angular_velocity/1000.,
        climber.torso.linear_velocity.x/200.,
        climber.torso.linear_velocity.y/200.,
        climber.l_forearm.global_rotation/(2.*PI),
        climber.r_forearm.global_rotation/(2.*PI),
        climber.l_upperarm.global_rotation/(2.*PI),
        climber.r_upperarm.global_rotation/(2.*PI),
        climber.l_thigh.global_rotation/(2.*PI),
        climber.r_thigh.global_rotation/(2.*PI),
        climber.l_calf.global_rotation/(2.*PI),
        climber.r_calf.global_rotation/(2.*PI),
        climber.l_foot_grabber.is_grabbing(),
        climber.r_foot_grabber.is_grabbing(),
        climber.l_hand_grabber.is_grabbing(),
        climber.r_hand_grabber.is_grabbing(),
    ] + body_sensor.calculate_raycasts() + raycast_left.calculate_raycasts() + raycast_right.calculate_raycasts()
    return {"obs":obs}

func get_reward() -> float:	
    return reward
    
func get_action_space() -> Dictionary:
    return {
        "l_hand_lock" : {"size": 1, "action_type": "discrete"},
        "r_hand_lock" : {"size": 1,"action_type": "discrete"},
        "l_foot_lock" : {"size": 1,"action_type": "discrete"},
        "r_foot_lock" : {"size": 1,"action_type": "discrete"},

        "l_hand_grab" : {"size": 1, "action_type": "discrete"},
        "r_hand_grab" : {"size": 1,"action_type": "discrete"},
        "l_foot_grab" : {"size": 1,"action_type": "discrete"},
        "r_foot_grab" : {"size": 1,"action_type": "discrete"},
        #rotorization:
        "l_shoulder" : {"size": 1, "action_type": "continuous"},
        "l_elbow" : {"size": 1, "action_type": "continuous"},
        "r_shoulder" : {"size": 1, "action_type": "continuous"},
        "r_elbow" : {"size": 1, "action_type": "continuous"},
        "l_hip" : {"size": 1, "action_type": "continuous"},
        "l_knee" : {"size": 1, "action_type": "continuous"},
        "r_hip" : {"size": 1, "action_type": "continuous"},
        "r_knee" : {"size": 1, "action_type": "continuous"},
    }

var limb_force_multiplier: float = 150.0

func set_action(action: Dictionary) -> void:	

    climber.l_hand_grabber.joint.angular_limit_enabled = action["l_hand_lock"] as bool
    climber.r_hand_grabber.joint.angular_limit_enabled = action["r_hand_lock"] as bool
    climber.l_foot_grabber.joint.angular_limit_enabled = action["l_foot_lock"] as bool
    climber.r_foot_grabber.joint.angular_limit_enabled = action["r_foot_lock"] as bool
    
    climber.l_hand_grabber.grab_on_contact = action["l_hand_grab"] as bool
    climber.r_hand_grabber.grab_on_contact = action["r_hand_grab"] as bool
    climber.l_foot_grabber.grab_on_contact = action["l_foot_grab"] as bool
    climber.r_foot_grabber.grab_on_contact = action["r_foot_grab"] as bool

    

    climber.l_shoulder.motor_target_velocity = action["l_shoulder"][0] * limb_force_multiplier
    climber.l_upperarm.joint.motor_target_velocity = action["l_elbow"][0] * limb_force_multiplier
    climber.r_shoulder.motor_target_velocity = action["r_shoulder"][0] * limb_force_multiplier
    climber.r_upperarm.joint.motor_target_velocity = action["r_elbow"][0] * limb_force_multiplier
    climber.l_hip.motor_target_velocity = action["l_hip"][0] * limb_force_multiplier
    climber.l_thigh.joint.motor_target_velocity = action["l_knee"][0] * limb_force_multiplier
    climber.r_hip.motor_target_velocity = action["r_hip"][0] * limb_force_multiplier
    climber.r_thigh.joint.motor_target_velocity = action["r_knee"][0] * limb_force_multiplier
