extends Node2D
class_name ClimbMap

const CLIMBER_SCENE: PackedScene = preload("res://scenes/climber.tscn")
const BOX_SCENE: PackedScene = preload("res://scenes/box.tscn")
const FLOOR_SCENE: PackedScene = preload("res://scenes/floor.tscn")
const ENCLOSURE_SCENE: PackedScene = preload("res://scenes/enclosure.tscn")

@onready var climbers_node: Node2D = $Climbers

var climbers: Array[Climber] = []

# Position tracking for stagnation penalty
var climber_positions: PackedVector2Array = PackedVector2Array()
var position_tolerance: float = 15.0   # Distance tolerance for considering "same position"

@export var n_climbers: int:
    set(value):
        climbers.clear()
        climber_positions.clear()
        for child in climbers_node.get_children():
            if child is Climber:
                child.queue_free()
        
        n_climbers = value
        for i in range(n_climbers):
            var climber: Climber = CLIMBER_SCENE.instantiate()
            climbers_node.add_child(climber)
            climber.set_pos(get_parent().global_position)
            climber.name = "Climber_%d" % i  # Set a numbered name for each climber
            climber.target_angle = reward_angle
            climber.map = self
            climbers.append(climber)
            climber_positions.append(climber.get_pos())
        
        climbers_initialized.emit()

signal climbers_initialized

func _ready():
    reward_angle = -PI/2 #DEJARLO SETTEADO ACÁ

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

    if randf() < Config.infection_ratio:
        current_game_mode = GameMode.INFECTION_TAG
    else:
        current_game_mode = GameMode.CLIMBING


var infected: Array[Climber] = []; var non_infected: Array[Climber] = []

var enclosure: Enclosure = null

func _calc_round_duration() -> float:
    if current_game_mode == GameMode.CLIMBING:
        return Config.round_duration
    else:
        return Config.round_duration * rand_size_mult * rand_size_mult * 3.0

var rand_size_mult: float

func _new_infection_tag_round():
    if floor != null:
        floor.queue_free()
        floor = null
    enclosure = ENCLOSURE_SCENE.instantiate()
    self.add_child(enclosure)
    rand_size_mult = randf_range(0.75, 1.5) * n_climbers / 10.0
    enclosure.size = 1000 * rand_size_mult
    climb_round_timer = _calc_round_duration()

    infected.clear(); non_infected.clear()

    var first_infected_i: int = randi() % climbers.size()
    var first_infected: Climber = climbers[first_infected_i]
    for i in range(climbers.size()):
        if i == first_infected_i:
            continue

        var climber: Climber = climbers[i]
        climber.spawn_position = Vector2(randf_range(-enclosure.size+20, enclosure.size -20), enclosure.size - 20)
        climber.role = Climber.Role.SURVIVOR
        climber.reset()

    grace_active = true
    first_infected.spawn_position = Vector2(randf_range(-enclosure.size+20, enclosure.size -20), enclosure.size - 20)
    first_infected.reset()
    first_infected.role = Climber.Role.INFECTED


func calc_rand_mult() -> float:
    return min(Config.init_rand_mult + Config.rand_incr * float(current_round), Config.rand_cap)

func _new_climb_round():
    if enclosure != null:
        enclosure.queue_free()
        enclosure = null
    if floor == null:
        floor = FLOOR_SCENE.instantiate()
        self.add_child(floor)
    max_reached_distance = 0.0
    last_spawned_box = null
    climber_highest_reward = null
    reward_angle = -PI/2 + randf_range(-PI/2., PI/2.) * calc_rand_mult()

    for climber in climbers:
        # Add randomness to climber spawn position
        var random_offset = Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
        climber.spawn_position = global_position + reward_vec * 40.0 + random_offset
        climber.role = Climber.Role.CLIMBER
        climber.reset()

    floor.rotation = reward_angle + PI/2

enum GameMode { CLIMBING, INFECTION_TAG }

var current_game_mode: GameMode:
    set(value):
        current_game_mode = value
        if current_game_mode == GameMode.INFECTION_TAG:
            _new_infection_tag_round()
        else:
            _new_climb_round()
            

var grace_period: float = 3.0
var grace_active: bool = true
const OUT_OF_BOUNDS_THRESHOLD: float = 3000.0
func _process(delta: float):
    delta *= Config.speed_up
    climb_round_timer -= delta

    if climb_round_timer < 0 or (current_game_mode == GameMode.INFECTION_TAG and infected.size() == climbers.size()):
        for survivor in non_infected:
            survivor.ai_controller.reward += 30000.0
        grace_active = true

        climb_round_timer = _calc_round_duration()
        _new_round()
        return
    var gravity_vec: Vector2 = Vector2(cos(gravity_angle), sin(gravity_angle))

    if current_game_mode == GameMode.CLIMBING:
        for i in range(climbers.size()):
            var climber: Climber = climbers[i]

            var projected_distance: float = get_dist_reward(climber) + OFFSET_DISTANCE

            # Out of bounds detection
            var gravity_projection: float = (climber.get_pos() - global_position).dot(gravity_vec)
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

            if distance_moved < position_tolerance:
                climber.stagnation_timer += delta
                if climber.stagnation_timer >= 10.0:
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
        if _calc_round_duration() - climb_round_timer < grace_period:
            grace_active = true
            for infected_climber in infected:
                infected_climber.nullify_velocity()
        else:
            grace_active = false

@onready var boxes: Node2D = $Boxes
var last_spawned_box: StaticBody2D = null

func spawn_box() -> void:
    var box: StaticBody2D = BOX_SCENE.instantiate()
    var spawn_position: Vector2 = Vector2.ZERO
    spawn_position += 40 * reward_vec.normalized()

    if last_spawned_box != null:
      
        box.rotation = randf() * PI * 2 
        spawn_position += last_spawned_box.position
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

    box.position = spawn_position

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
    infected.append(climber); non_infected.erase(climber)

func get_dist_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - global_position
    return distance_reward_vec.dot(reward_vec)


    

    
