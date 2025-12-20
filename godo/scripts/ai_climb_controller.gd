extends AIController2D
class_name AIClimbController

@onready var climber: Climber = $".."

@onready var body_sensor: BodySensor = $RaycastBody
@onready var reward_label: Label = $"../Labels/score_Label"

@onready var node_above: CornerSensors = $NodeAbove


func _process(_delta: float):
    var int_reward: int = int(reward)
    reward_label.text = str(int_reward)
    if int_reward <= 0:
        reward_label.set(&"theme_override_colors/font_color",Color.RED)
    else:
        reward_label.set(&"theme_override_colors/font_color",Color.WHITE)

const POS_DIV: float = 2000.0

var obs: PackedFloat64Array = PackedFloat64Array()
func get_obs() -> Dictionary:
    obs.clear()
    obs.append(climber.angular_distance_to_target_angle_normalized())
    obs.append(climber.torso.global_rotation / TAU)
    obs.append(climber.torso.global_position.x / POS_DIV)
    obs.append(climber.torso.global_position.y / POS_DIV)
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
    obs.append(float(climber.l_foot_grabber.what_is_grabbing()))
    obs.append(float(climber.r_foot_grabber.what_is_grabbing()))
    obs.append(float(climber.l_hand_grabber.what_is_grabbing()))
    obs.append(float(climber.r_hand_grabber.what_is_grabbing()))
    #obs.append(climber.closest_infected_dist_vec.x / (POS_DIV * 0.5)); obs.append(climber.closest_infected_dist_vec.y / (POS_DIV * 0.5))
    obs.append_array(body_sensor.get_raycasts()); obs.append_array(node_above.get_all_static_raycasts())
    #obs.append_array(body_sensor.accumulated_obs)

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
        "left_hand_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "right_hand_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "left_foot_grab_on_contact": {"size": 1, "action_type": "discrete"},
        "right_foot_grab_on_contact": {"size": 1, "action_type": "discrete"},
    }
    
# Rotor speed multiplier
var mult: float = 30

func set_action(a: Dictionary) -> void:	
    
    var move := Vector2(a[&"move"][0], a[&"move"][1])
    climber.force_direction = move.normalized()

    var grabber_i := int(abs(a[&"control"]*2) + abs(a[&"control_2"]))

    climber.l_hand_grabber.grab_on_contact = a[&"left_hand_grab_on_contact"]
    climber.r_hand_grabber.grab_on_contact = a[&"right_hand_grab_on_contact"]
    climber.l_foot_grabber.grab_on_contact = a[&"left_foot_grab_on_contact"]
    climber.r_foot_grabber.grab_on_contact = a[&"right_foot_grab_on_contact"]
    climber.l_shoulder.motor_target_velocity = a[&"l_shoulder"][0] * mult
    climber.r_shoulder.motor_target_velocity = a[&"r_shoulder"][0] * mult
    climber.l_hip.motor_target_velocity = a[&"l_hip"][0] * mult
    climber.r_hip.motor_target_velocity = a[&"r_hip"][0] * mult
    climber.l_thigh.joint.motor_target_velocity = a[&"l_knee"][0] * mult
    climber.r_thigh.joint.motor_target_velocity = a[&"r_knee"][0] * mult
    climber.l_upperarm.joint.motor_target_velocity = a[&"l_elbow"][0] * mult
    climber.r_upperarm.joint.motor_target_velocity = a[&"r_elbow"][0] * mult
    var new_controlled: Grabber = (climber.joints.keys())[grabber_i]
    climber.currently_controlled = new_controlled
        

var is_success := false
func get_info() -> Dictionary:
    if done: 
        return {"is_success": is_success}
    return {}
