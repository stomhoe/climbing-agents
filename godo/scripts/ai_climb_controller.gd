extends AIController2D
class_name AIClimbController

@onready var climber: Climber = $".."
@onready var node_above: Node2D = $NodeAbove
@onready var map: ClimbMap = get_tree().root.get_child(0)

@onready var body_sensor: BodySensor = $NodeAbove/RaycastBody
@onready var label: Label = $"../Label2/Label"
#@onready var raycast_ahead: BodySensor = $NodeAbove/RaycastAhead


func _process(_delta: float):
    label.text = str(int(reward))

const POS_DIV: float = 2000.0

var obs: PackedFloat64Array = PackedFloat64Array()
func get_obs() -> Dictionary:
    obs.clear()
    obs.append(climber.target_angle / TAU)
    obs.append(climber.torso.global_rotation / TAU)
    obs.append(climber.torso.angular_velocity / 1000.0)
    obs.append(climber.torso.linear_velocity.x / 200.0)
    obs.append(climber.torso.linear_velocity.y / 200.0)
    obs.append(climber.l_forearm.global_rotation / TAU)
    obs.append(climber.r_forearm.global_rotation / TAU)
    obs.append(climber.l_upperarm.global_rotation / TAU)
    obs.append(climber.r_upperarm.global_rotation / TAU)
    obs.append(climber.l_thigh.global_rotation / TAU)
    obs.append(climber.r_thigh.global_rotation / TAU)
    obs.append(climber.l_calf.global_rotation / TAU)
    obs.append(climber.r_calf.global_rotation / TAU)
    obs.append(float(climber.l_foot_grabber.is_attached()))
    obs.append(float(climber.r_foot_grabber.is_attached()))
    obs.append(float(climber.l_hand_grabber.is_attached()))
    obs.append(float(climber.r_hand_grabber.is_attached()))
    obs.append(climber.closest_infected_dist_vec.x / (POS_DIV * 0.5))
    obs.append(climber.closest_infected_dist_vec.y / (POS_DIV * 0.5))
    obs.append(climber.get_pos().x / POS_DIV)
    obs.append(climber.get_pos().y / POS_DIV)
    obs.append_array(body_sensor.get_raycasts())

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
        "right_foot_grab_on_contact": {"size": 1, "action_type": "discrete"},

    }
    
var rotor_speed: float = 30

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
        
