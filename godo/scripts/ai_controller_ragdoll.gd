extends AIController3D
class_name RagdollAi

@onready var combatant: Combatant = get_parent() as Combatant

func _ready():
    combatant.ai_controller = self

func get_obs() -> Dictionary:
    var obs = combatant.get_body_data() + \
              combatant.arena.get_nearest_objects_data(combatant, 1) + \
              combatant.arena.get_nearest_combatants_data(combatant, 1)
    return {"obs": obs}

func get_reward() -> float:    
    return reward
    
func get_action_space() -> Dictionary:
    return {
        "move": {
            "size": 2,
            "action_type": "continuous"
        },
        "rot": {
            "size": 2,
            "action_type": "continuous"
        },
        "arm_left": {
            "size": 1,
            "action_type": "discrete"
        },
        "arm_right": {
            "size": 1,
            "action_type": "discrete"
        },
    }
    
func set_action(action) -> void:  
    combatant.active_arm_left = action["arm_left"]  
    combatant.active_arm_right = action["arm_right"]  
    
    combatant.input_move.x = action["move"][0] as int
    combatant.input_move.y = action["move"][1] as int
    combatant.input_rot.x = action["rot"][0] as int
    combatant.input_rot.y = action["rot"][1] as int
