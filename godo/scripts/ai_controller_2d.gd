extends AIController2D


@onready var climber: Climber = $".."
@onready var body_sensor = $RaycastBody
@onready var raycast_above = $NodeAbove/RaycastAbove

func _process(delta):
    raycast_above.position = 80 * Vector2(cos(climber.target_angle), sin(climber.target_angle))

func get_obs() -> Dictionary:
    var obs: Array = [
        climber.target_angle,
        climber.get_pos().x,
        climber.get_pos().y,
        climber.torso.rotation,
        climber.torso.angular_velocity,
        climber.torso.linear_velocity.x,
        climber.torso.linear_velocity.y,
        climber.l_forearm.rotation,
        climber.r_forearm.rotation,
        climber.l_upperarm.rotation,
        climber.r_upperarm.rotation,
        climber.l_thigh.rotation,
        climber.r_thigh.rotation,
        climber.l_calf.rotation,
        climber.r_calf.rotation,
        climber.l_foot_grabber.is_grabbing(),
        climber.r_foot_grabber.is_grabbing(),
        climber.l_hand_grabber.is_grabbing(),
        climber.r_hand_grabber.is_grabbing(),
        climber.swing_timer,
    ] + body_sensor.calculate_raycasts() + raycast_above.calculate_raycasts()
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
    print(grabber_i)
    
    climber.currently_controlled = (climber.joints.keys())[grabber_i]
        
        
    
    
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
