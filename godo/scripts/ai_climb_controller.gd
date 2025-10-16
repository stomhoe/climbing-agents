extends AIController2D
class_name AIClimbController

@onready var climber: Climber = $".."
@onready var node_above: Node2D = $NodeAbove

@onready var body_sensor: RaycastSensor2D = $"../Torso/RaycastBody"
@onready var raycast_right: RaycastSensor2D = $NodeAbove/RaycastRight
@onready var raycast_left: RaycastSensor2D = $NodeAbove/RaycastLeft

func _process(delta: float):
    node_above.global_rotation = climber.target_angle + PI/2

func get_obs() -> Dictionary:
    var obs: Array = [
        climber.target_angle,
        climber.get_pos().x,
        climber.get_pos().y,
        climber.torso.global_rotation,
        climber.torso.angular_velocity,
        climber.torso.linear_velocity.x,
        climber.torso.linear_velocity.y,
        climber.l_forearm.global_rotation,
        climber.r_forearm.global_rotation,
        climber.l_upperarm.global_rotation,
        climber.r_upperarm.global_rotation,
        climber.l_thigh.global_rotation,
        climber.r_thigh.global_rotation,
        climber.l_calf.global_rotation,
        climber.r_calf.global_rotation,
        climber.l_foot_grabber.is_grabbing(),
        climber.r_foot_grabber.is_grabbing(),
        climber.l_hand_grabber.is_grabbing(),
        climber.r_hand_grabber.is_grabbing(),
        climber.swing_timer,
    ] + body_sensor.calculate_raycasts() + raycast_left.calculate_raycasts() + raycast_right.calculate_raycasts()
    return {"obs":obs}

func get_reward() -> float:	
    return reward
    
func get_action_space() -> Dictionary:
    return {
        "grabber" : {
            "size": 1,
            "action_type": "continuous"
        },
        "move" : {
            "size": 2,
            "action_type": "continuous"
        },
        }
    
func set_action(action: Dictionary) -> void:	
    
    var move: Vector2 = Vector2(action[&"move"][0], action[&"move"][1])
    climber.force_direction = move.normalized()
    var grabber_i: int = (abs(action[&"grabber"][0]*3)) as int
    
    var new_controlled = (climber.joints.keys())[grabber_i]
    climber.set_controlled_grabber(new_controlled)
        
        
    
    
# -----------------------------------------------------------------------------#

#-- Methods that can be overridden if needed --#

#func get_obs_space() -> Dictionary:
# May need overriding if the obs space is complex
#	var obs = get_obs()
#	return {
#		"obs": {
#			"size": [len(obs["obs"])],
#			"space": "box"
#		},
#	}
