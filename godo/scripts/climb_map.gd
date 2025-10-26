extends Node2D
class_name ClimbMap

@onready var climbers_node: Node2D = $Climbers

var climbers: Array[Climber] = []

# Position tracking for stagnation penalty
var climber_positions: Array[Vector2] = []
var position_tolerance: float = 15.0   # Distance tolerance for considering "same position"
@onready var sync: Sync = $Sync

@export var n_climbers: int = 0:
    set(value):
        climbers.clear()
        climber_positions.clear()
        for child in climbers_node.get_children():
            if child is Climber:
                child.queue_free()
        
        n_climbers = value
        for i in range(n_climbers):
            var climber: Climber = climber_scene.instantiate()
            climbers_node.add_child(climber)
            climber.name = "Climber_%d" % i  # Set a numbered name for each climber
            climber.target_angle = reward_angle
            climber.spawn_position = climbers_node.global_position
            climbers.append(climber)
            climber_positions.append(climber.get_pos())
        sync._initialize()

var climber_scene: PackedScene = preload("res://scenes/climber.tscn")

func _ready():
    reward_angle = -PI/2 #DEJARLO SETTEADO ACÁ

var round_duration: float = 10.0
var climb_round_timer: float = round_duration

var box_scene: PackedScene = preload("res://scenes/box.tscn")

var climber_highest_reward: Climber = null

const OFFSET_DISTANCE: float = 200.0

var max_reached_distance: float = 0.0

@onready var floor_rect: StaticBody2D = $Floor

var gravity_angle: float = ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2(0, 1)).angle()
var gravity_strength: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

func _new_round():
    climb_round_timer = round_duration
    max_reached_distance = 0.0
    last_spawned_box = null
    climber_highest_reward = null
    for box in boxes.get_children():
        box.queue_free()
    reward_angle = -PI/2 + randf_range(-PI/2., PI/2.)
    # Also randomize gravity
    gravity_angle = reward_angle + randf_range(-PI/2.2, PI/2.2)
    gravity_strength = randf_range(100.0, 2000.0)
    ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(cos(gravity_angle), sin(gravity_angle)))
    ProjectSettings.set_setting("physics/2d/default_gravity", gravity_strength)

    var nodes_angle: float = reward_angle + PI/2
    for climber in climbers:
        climber.spawn_position = reward_vec * 20.0
        climber.reset()

    floor_rect.rotation = nodes_angle


    print("New round! Reward angle: %.2f, Gravity angle: %.2f, Strength: %.2f" % [rad_to_deg(reward_angle), rad_to_deg(gravity_angle), gravity_strength])

func _process(delta: float):
    delta *= sync.speed_up

    climb_round_timer -= delta
    if climb_round_timer < 0:
        _new_round()
    else:
        var gravity_vec: Vector2 = Vector2(cos(gravity_angle), sin(gravity_angle))
        var out_of_bounds_threshold: float = 300.0  # Adjust as needed

        for i in range(climbers.size()):
            var climber: Climber = climbers[i]
            climber.speed_up = sync.speed_up

            var dot: float = (climber.get_pos()).dot(reward_vec)
            var projected_distance: float = dot + OFFSET_DISTANCE

            # Out of bounds detection
            var gravity_projection: float = climber.get_pos().dot(gravity_vec)
            if gravity_projection > out_of_bounds_threshold:
                climber.reset(true)
                continue

            # Define a dynamic minimum threshold for distance increase
            var min_distance_threshold: float = 24.0

            if projected_distance > max_reached_distance + min_distance_threshold:
                max_reached_distance += min_distance_threshold
                spawn_box(reward_angle)  # Adjust for the offset when spawning the box

            # Check if climber has moved significantly
            var current_pos: Vector2 = climber.get_pos()
            var distance_moved: float = current_pos.distance_to(climber_positions[i])

            if distance_moved < position_tolerance or dot < 40.0:
                # Climber is stagnant, increase climb_round_timer
                climber.stagnation_timer += delta
                if climber.stagnation_timer >= 7.0:
                    climber.reset(true)
                    continue
            else:
                # Climber has moved, reset climb_round_timer and update position
                climber.stagnation_timer = 0.0
                climber_positions[i] = current_pos

            climber.ai_controller.reward = get_dist_reward(climber)

            if !climber_highest_reward or climber.ai_controller.reward > climber_highest_reward.ai_controller.reward:
                climber_highest_reward = climber

@onready var boxes: Node2D = $Boxes
var last_spawned_box: StaticBody2D = null
var angle_between_boxes_sum: float = 0.0
var box_count: int = 0

func spawn_box(angle_from_previous: float = 0.0) -> void:
    var box: StaticBody2D = box_scene.instantiate()
    var spawn_position: Vector2 = Vector2.ZERO
    spawn_position += 40 * reward_vec.normalized()

    if last_spawned_box != null:
        box.rotation = randf() * PI * 2  # Random rotation between 0 and 2π
        # Use the last spawned box's position as a base
        spawn_position += last_spawned_box.global_position
        var min_distance: float = 10.0 + (max_reached_distance * 0.005)  # Increase min distance based on progress

        var noisy_direction: Vector2 = reward_vec.rotated(randf_range(-PI/1.6, PI/1.6))
        var offset_length: float = min_distance + randf() * 40.0  # Add some randomness to distance
        var random_offset: Vector2 = noisy_direction * offset_length

        var perp: Vector2 = noisy_direction.orthogonal().normalized()
        random_offset += perp * randf_range(-20.0, 20.0)
        var random_scale: float = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)  # Normal distribution with mean 1.7 and std dev 0.7
        box.scale = Vector2(random_scale, random_scale)

        spawn_position += random_offset
        angle_between_boxes_sum += last_spawned_box.global_position.angle_to_point(spawn_position)
        box_count += 1

    else:
        box.scale = Vector2(2.2, 2.2)
        spawn_position *= 1.6
        box.rotation = reward_angle
        climbers_node.global_position = spawn_position * 1.2
        for climber in climbers:
            climber.spawn_position = climbers_node.global_position



    # Adjust spawn position to be 40 higher

    box.global_position = spawn_position

    # Randomize scale and rotation

    box.name = "Box%d" % boxes.get_child_count()

    boxes.add_child(box)
    last_spawned_box = box 

var reward_vec: Vector2
var reward_angle: float:
    set(value):
        reward_angle = value
        var angle_vec = Vector2(cos(reward_angle), sin(reward_angle))
        reward_vec = angle_vec.normalized()
        for climber in climbers:
            climber.target_angle = reward_angle



func get_dist_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(reward_vec)


func _on_sync_ready():
    await self.ready
    
    if sync.args.has(&"n_climbers"):
        n_climbers = int(sync.args[&"n_climbers"])
    else:
        n_climbers = 40
        
    if sync.args.has(&"round_duration"):
        round_duration = float(sync.args[&"round_duration"])
    else:
        round_duration = 300.
