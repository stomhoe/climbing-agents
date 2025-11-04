extends Node2D
class_name ClimbMap

const climber_scene: PackedScene = preload("res://scenes/climber.tscn")
const box_scene: PackedScene = preload("res://scenes/box.tscn")
const floor_scene: PackedScene = preload("res://scenes/floor.tscn")

@onready var climbers_node: Node2D = $Climbers

var climbers: Array[Climber] = []

# Position tracking for stagnation penalty
var climber_positions: PackedVector2Array = PackedVector2Array()
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
            climber.map = self
            climbers.append(climber)
            climber_positions.append(climber.get_pos())
        sync._initialize()



func _ready():
    reward_angle = -PI/2 #DEJARLO SETTEADO ACÁ

var round_duration: float = 60.0
var climb_round_timer: float = -1


var climber_highest_reward: Climber = null

const OFFSET_DISTANCE: float = 200.0

var max_reached_distance: float = 0.0

var floor: StaticBody2D

var gravity_angle: float = ProjectSettings.get_setting("physics/2d/default_gravity_vector", Vector2(0, 1)).angle()
var gravity_strength: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

var current_round: int = 0
func _new_round():
    current_round += 1
    
    for box in boxes.get_children(): box.queue_free()

    current_game_mode = GameMode.values()[randi() % GameMode.values().size()]


var infected: Array[Climber] = []
var non_infected: Array[Climber] = []

const ENCLOSURE_SCENE: PackedScene = preload("res://scenes/enclosure.tscn")
var enclosure: Enclosure = null

func _new_infection_tag_round():
    if floor != null:
        floor.queue_free()
        floor = null
    ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(0, 1))
    ProjectSettings.set_setting("physics/2d/default_gravity", 980.0)
    enclosure = ENCLOSURE_SCENE.instantiate()
    add_child(enclosure)
    var rand_size_mult = randf_range(0.75, 1.5)
    enclosure.size = 1000 * rand_size_mult
    climb_round_timer *= rand_size_mult * rand_size_mult

    infected.clear()
    non_infected.clear()

    var first_infected_i: int = randi() % climbers.size()
    var first_infected: Climber = climbers[first_infected_i]
    for i in range(climbers.size()):
        if i == first_infected_i:
            continue

        var climber: Climber = climbers[i]
        climber.spawn_position = Vector2(randf_range(-enclosure.size, enclosure.size), randf_range(-enclosure.size, enclosure.size))
        climber.role = Climber.Role.PREY
        climber.reset()

    grace_active = true
    first_infected.spawn_position = Vector2.ZERO
    first_infected.reset()
    first_infected.role = Climber.Role.INFECTED

func _new_climb_round():
    if enclosure != null:
        enclosure.queue_free()
        enclosure = null
        
    if floor == null:
        floor = floor_scene.instantiate()
        add_child(floor)
    
    max_reached_distance = 0.0
    last_spawned_box = null
    climber_highest_reward = null
    reward_angle = -PI/2 + randf_range(-PI/2., PI/2.)
    gravity_angle = reward_angle + randf_range(-PI/3.5, PI/3.5)
    gravity_strength = randf_range(100.0, 1500.0)
    ProjectSettings.set_setting("physics/2d/default_gravity_vector", Vector2(cos(gravity_angle), sin(gravity_angle)))
    ProjectSettings.set_setting("physics/2d/default_gravity", gravity_strength)

    var nodes_angle: float = reward_angle + PI/2
    for climber in climbers:
        climber.spawn_position = reward_vec * 20.0
        climber.role = Climber.Role.CLIMBER
        climber.reset()

    floor.rotation = nodes_angle

enum GameMode { CLIMBING, INFECTION_TAG }

var current_game_mode: GameMode:
    set(value):
        current_game_mode = value
        if current_game_mode == GameMode.INFECTION_TAG:
            _new_infection_tag_round()
        else:
            _new_climb_round()
            

var grace_period: float = 5.0
var grace_active: bool = true
const OUT_OF_BOUNDS_THRESHOLD: float = 3000.0
func _process(delta: float):
    delta *= sync.speed_up
    climb_round_timer -= delta

    if climb_round_timer < 0 or (current_game_mode == GameMode.INFECTION_TAG and infected.size() == climbers.size()):
        for survivor in non_infected:
            survivor.ai_controller.reward += 30000.0
        grace_active = true

        climb_round_timer = round_duration
        _new_round()
        return
    var gravity_vec: Vector2 = Vector2(cos(gravity_angle), sin(gravity_angle))

    if current_game_mode == GameMode.CLIMBING:
        for i in range(climbers.size()):
            var climber: Climber = climbers[i]

            var dot: float = (climber.get_pos()).dot(reward_vec)
            var projected_distance: float = dot + OFFSET_DISTANCE

            # Out of bounds detection
            var gravity_projection: float = climber.get_pos().dot(gravity_vec)
            if gravity_projection > OUT_OF_BOUNDS_THRESHOLD:
                climber.reset(true)
                continue

            const min_distance_threshold: float = 24.0

            if projected_distance > max_reached_distance + min_distance_threshold:
                max_reached_distance += min_distance_threshold
                spawn_box()  

            # Check if climber has moved significantly
            var current_pos: Vector2 = climber.get_pos()
            var distance_moved: float = current_pos.distance_to(climber_positions[i])

            if distance_moved < position_tolerance or dot < 40.0:
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
    else:
        if round_duration - climb_round_timer < grace_period:
            grace_active = true
            for infected_climber in infected:
                infected_climber.nullify_velocity()
        else:
            grace_active = false

@onready var boxes: Node2D = $Boxes
var last_spawned_box: StaticBody2D = null

var powerup_scenes: Dictionary[float, PackedScene] = {
    #0.8: preload("res://scenes/powerup/grenade.tscn")
}

func spawn_box() -> void:
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
        box.scale = Vector2(clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4), clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4))

        spawn_position += random_offset

    else:
        box.scale = Vector2(2.2, 2.2)
        spawn_position *= 1.6
        box.rotation = reward_angle
        climbers_node.global_position = spawn_position * 1.2
        for climber in climbers:
            climber.spawn_position = climbers_node.global_position

    box.global_position = spawn_position

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

func add_new_infected(climber: Climber) -> void:
    infected.append(climber)
    non_infected.erase(climber)

func get_dist_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(reward_vec)


func _on_sync_ready():
    await self.ready
    
    if sync.args.has(&"n_climbers"):
        n_climbers = int(sync.args[&"n_climbers"])
    else:
        n_climbers = 30
        
    if sync.args.has(&"round_duration"):
        round_duration = float(sync.args[&"round_duration"])
    else:
        round_duration = 60.
