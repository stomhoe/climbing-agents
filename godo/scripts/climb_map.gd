extends Node2D


@onready var climbers_node: Node2D = $Climbers

var climbers: Array[Climber] = []

# Position tracking for stagnation penalty
var climber_positions: Array[Vector2] = []
var stagnation_threshold: float = 5.0  # Time in seconds before penalty kicks in
var position_tolerance: float = 20.0   # Distance tolerance for considering "same position"
var stagnation_penalty: float = 0.5   # Penalty applied per second when stagnant

@export var N_CLIMBERS = 50
var climber_scene: PackedScene = preload("res://scenes/climber.tscn")

func _ready():
    reward_angle = -PI/2 #DEJARLO SETTEADO ACÁ
    for i in range(N_CLIMBERS):
        var climber: Climber = climber_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
        climbers_node.add_child(climber)
        climber.name = "Climber_%d" % i  # Set a numbered name for each climber
        climber.target_angle = reward_angle
        climbers.append(climber)
        climber_positions.append(climber.get_pos())

var round_duration: float = 30.0
var climb_round_timer: float = round_duration

var box_scene: PackedScene = preload("res://scenes/box.tscn")

var climber_highest_reward: Climber = null

const OFFSET_DISTANCE: float = 330.0

var max_reached_distance: float = 0.0
func _process(delta: float):
    climb_round_timer -= delta
    if climb_round_timer < 0:
        for climber in climbers:
            climber.set_pos(climber.global_position)
            climber.ai_controller.reset()
            climber.stagnation_timer = 0.0
        climb_round_timer = round_duration
        round_duration *= 1.13
        # Reset position tracking
        for i in range(climbers.size()):
            climber_positions[i] = climbers[i].get_pos()
    else:
        for i in range(climbers.size()):
            var climber = climbers[i]

            # Update max_reached_distance based on the reward direction
            var reward_direction = Vector2(cos(reward_angle), sin(reward_angle))
            var projected_distance = (climber.get_pos() - Vector2(0, 0)).dot(reward_direction) + OFFSET_DISTANCE
            
            # Define a dynamic minimum threshold for distance increase
            var min_distance_threshold = 17.0 if max_reached_distance < 100.0 else 22.0
            if max_reached_distance >= 100.0:
                min_distance_threshold += (max_reached_distance - 100.0) * 0.0005  # Gradually increase threshold
            
            if projected_distance > max_reached_distance + min_distance_threshold:
                max_reached_distance += min_distance_threshold
                spawn_box(max_reached_distance - OFFSET_DISTANCE)  # Adjust for the offset when spawning the box
            
            # Check if climber has moved significantly
            var current_pos = climber.get_pos()
            var distance_moved = current_pos.distance_to(climber_positions[i])
            
            if distance_moved < position_tolerance:
                # Climber is stagnant, increase climb_round_timer
                climber.stagnation_timer += delta
            else:
                # Climber has moved, reset climb_round_timer and update position
                climber.stagnation_timer = 0.0
                climber_positions[i] = current_pos
            
            # Apply stagnation penalty if climber has been still too long and max_reached_distance is at least 120 (without offset)
            if max_reached_distance - OFFSET_DISTANCE >= 200  and climber.stagnation_timer > stagnation_threshold:
                var penalty_time = climber.stagnation_timer - stagnation_threshold
                climber.ai_controller.reward -= stagnation_penalty * penalty_time
               
            climber.ai_controller.reward = max(get_dist_reward(climber), climber.ai_controller.reward)
            
            # Track the climber with the highest reward
            if ! climber_highest_reward or climber.ai_controller.reward > climber_highest_reward.ai_controller.reward:
                climber_highest_reward = climber

@onready var boxes: Node2D = $Boxes
func spawn_box(distance: float):
    var box = box_scene.instantiate()
    var reward_direction = Vector2(cos(reward_angle), sin(reward_angle)).normalized()
    var spawn_position = reward_direction * (distance + OFFSET_DISTANCE)  # Adjust spawn position to include the offset

    # Add a smaller random offset in the direction of the reward for the first 100 meters
    var random_offset_magnitude = 75 if distance < 100 else 100
    var random_offset = reward_direction * (randf() * random_offset_magnitude - random_offset_magnitude / 2.0)
    random_offset += Vector2(randf() * 50 - 25, randf() * 50 - 25)  # Add some perpendicular randomness
    spawn_position += random_offset

    # Adjust spawn position to be 20 higher
    spawn_position.y -= 40

    box.position = spawn_position

    # Randomize scale and rotation
    var random_scale = clamp(abs(randfn(1.3, 0.7)), 0.5, 2.4)  # Normal distribution with mean 1.3 and std dev 0.4
    box.scale = Vector2(random_scale, random_scale)
    box.rotation = randf() * PI * 2  # Random rotation between 0 and 2π

    boxes.add_child(box)

var reward_vec: Vector2
var reward_angle: float:
    set(value):
        reward_angle = value
        var angle_vec = Vector2(cos(reward_angle), sin(reward_angle))
        reward_vec = angle_vec.normalized()



func get_dist_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(reward_vec)
