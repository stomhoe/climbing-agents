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
        "control" : {"size": 1, "action_type": "discrete"},
        "control_2" : {"size": 1, "action_type": "discrete"},
        "move" : {"size": 2, "action_type": "continuous"},

         "l_shoulder": {"size": 1, "action_type": "continuous"},
         "r_shoulder": {"size": 1, "action_type": "continuous"},
         "l_hip": {"size": 1, "action_type": "continuous"},
         "r_hip": {"size": 1, "action_type": "continuous"},
         "l_knee": {"size": 1, "action_type": "continuous"},
         "r_knee": {"size": 1, "action_type": "continuous"},
         "l_elbow": {"size": 1, "action_type": "continuous"},
         "r_elbow": {"size": 1, "action_type": "continuous"},

        #"lock_l_arm": {"size": 1, "action_type": "discrete"},
        #"lock_r_arm": {"size": 1, "action_type": "discrete"},
        #"lock_l_leg": {"size": 1, "action_type": "discrete"},
        #"lock_r_leg": {"size": 1, "action_type": "discrete"},

        "left_hand_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "right_hand_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "left_foot_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "right_foot_grab_on_contact": {"size": 1, "action_type": "discrete"}

    }
    
var rotor_speed: float = 15

func set_action(action: Dictionary) -> void:	
    
    var move: Vector2 = Vector2(action[&"move"][0], action[&"move"][1])
    climber.force_direction = move.normalized()

    var grabber_i: int = (abs(action[&"control"]*2) + abs(action[&"control_2"])) as int

    climber.l_hand_grabber.grab_on_contact = action[&"left_hand_grab_on_contact"]
    climber.r_hand_grabber.grab_on_contact = action[&"right_hand_grab_on_contact"]
    climber.l_foot_grabber.grab_on_contact = action[&"left_foot_grab_on_contact"]
    climber.r_foot_grabber.grab_on_contact = action[&"right_foot_grab_on_contact"]

    #for joint in climber.joints[climber.r_hand_grabber]:
        #joint.angular_limit_enabled = action[&"lock_r_arm"] as bool
    #for joint in climber.joints[climber.l_hand_grabber]:
        #joint.angular_limit_enabled = action[&"lock_l_arm"] as bool
    #for joint in climber.joints[climber.r_foot_grabber]:
        #joint.angular_limit_enabled = action[&"lock_r_leg"] as bool
    #for joint in climber.joints[climber.l_foot_grabber]:
        #joint.angular_limit_enabled = action[&"lock_l_leg"] as bool

    climber.l_shoulder.motor_target_velocity = action[&"l_shoulder"][0]*rotor_speed
    climber.r_shoulder.motor_target_velocity = action[&"r_shoulder"][0]*rotor_speed
    climber.l_hip.motor_target_velocity = action[&"l_hip"][0]*rotor_speed
    climber.r_hip.motor_target_velocity = action[&"r_hip"][0]*rotor_speed
    climber.l_thigh.joint.motor_target_velocity = action[&"l_knee"][0]*rotor_speed
    climber.r_thigh.joint.motor_target_velocity = action[&"r_knee"][0]*rotor_speed
    climber.l_upperarm.joint.motor_target_velocity = action[&"l_elbow"][0]*rotor_speed
    climber.r_upperarm.joint.motor_target_velocity = action[&"r_elbow"][0]*rotor_speed
    var new_controlled: Grabber = (climber.joints.keys())[grabber_i]
    climber.currently_controlled = new_controlled
        
