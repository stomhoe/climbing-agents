extends Node2D


@onready var climbers_node: Node2D = $Climbers

var climbers: Array[Climber] = []

# Position tracking for stagnation penalty
var climber_positions: Array[Vector2] = []
var position_tolerance: float = 15.0   # Distance tolerance for considering "same position"
@onready var sync: Sync = $Sync

@export var N_CLIMBERS = 40
var climber_scene: PackedScene = preload("res://scenes/climber.tscn")

func _ready():
    reward_angle = -PI/2 #DEJARLO SETTEADO ACÁ
    for i in range(N_CLIMBERS):
        var climber: Climber = climber_scene.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
        climbers_node.add_child(climber)
        climber.name = "Climber_%d" % i  # Set a numbered name for each climber
        climber.target_angle = reward_angle
        climber.spawn_position = climbers_node.global_position
        climbers.append(climber)
        climber_positions.append(climber.get_pos())

var round_duration: float = 300.0
var climb_round_timer: float = round_duration

var box_scene: PackedScene = preload("res://scenes/box.tscn")

var climber_highest_reward: Climber = null

const OFFSET_DISTANCE: float = 330.0

var max_reached_distance: float = 0.0

func _process(delta: float):
    delta *= sync.speed_up
    
    climb_round_timer -= delta
    if climb_round_timer < 0:
        for climber in climbers:
            if climber != climber_highest_reward:
                climber.reset()
        climb_round_timer = round_duration
            
    else:
        for i in range(climbers.size()):
            var climber: Climber = climbers[i]
            climber.speed_up = sync.speed_up

            var dot: float = (climber.get_pos()).dot(reward_vec)
            
            var projected_distance: float = dot + OFFSET_DISTANCE
            
            # Define a dynamic minimum threshold for distance increase
            var min_distance_threshold: float = 17.0 if max_reached_distance < 100.0 else 22.0
            if max_reached_distance >= 100.0:
                min_distance_threshold += (max_reached_distance - 100.0) * 0.0005  # Gradually increase threshold
            
            if projected_distance > max_reached_distance + min_distance_threshold:
                max_reached_distance += min_distance_threshold
                spawn_box(max_reached_distance - OFFSET_DISTANCE)  # Adjust for the offset when spawning the box
            
            # Check if climber has moved significantly
            var current_pos: Vector2 = climber.get_pos()
            var distance_moved: float = current_pos.distance_to(climber_positions[i])
            
            if distance_moved < position_tolerance or dot < 40.0:
                # Climber is stagnant, increase climb_round_timer
                climber.stagnation_timer += delta
                if climber.stagnation_timer >= 7.0:
                    climber.ai_controller.reward *= 0.5
                    climber.reset()
                    continue
            else:
                # Climber has moved, reset climb_round_timer and update position
                climber.stagnation_timer = 0.0
                climber_positions[i] = current_pos
                
            var base_reward: float = get_dist_reward(climber)
            if base_reward > 40.0:
                climber.ai_controller.reward = base_reward
                
            if ! climber_highest_reward or climber.ai_controller.reward > climber_highest_reward.ai_controller.reward:
                climber_highest_reward = climber

@onready var boxes: Node2D = $Boxes
var last_spawned_box: StaticBody2D = null

func spawn_box(distance: float):
    var box = box_scene.instantiate()
    var spawn_position: Vector2

    if last_spawned_box != null:
        # Use the last spawned box's position as a base
        spawn_position = last_spawned_box.global_position
        var random_offset = Vector2(randf() * 100 - 50, randf() * 10 - 20)  # Random offset in both x and y
        spawn_position += random_offset
    else:
        # Default spawn position based on reward vector and distance
        spawn_position = reward_vec * (distance + OFFSET_DISTANCE)

    # Adjust spawn position to be 20 higher
    spawn_position.y -= 40

    box.position = spawn_position

    # Randomize scale and rotation
    var random_scale = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)  # Normal distribution with mean 1.3 and std dev 0.4
    box.scale = Vector2(random_scale, random_scale)
    box.rotation = randf() * PI * 2  # Random rotation between 0 and 2π

    # Name the box uniquely
    box.name = "Box%d" % boxes.get_child_count()

    boxes.add_child(box)
    last_spawned_box = box  # Update the last spawned box

var reward_vec: Vector2
var reward_angle: float:
    set(value):
        reward_angle = value
        var angle_vec = Vector2(cos(reward_angle), sin(reward_angle))
        reward_vec = angle_vec.normalized()



func get_dist_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(reward_vec)
