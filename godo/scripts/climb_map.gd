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
            climber.int_id = i
            climber.target_angle = reward_angle
            climber.map = self
            climber.torso.modulate = Color(randf(), randf(), randf())
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
    rand_size_mult = n_climbers / 10.0
    enclosure.size = 500 * rand_size_mult
    climb_round_timer = _calc_round_duration()

    infected.clear(); non_infected.clear()

    var first_infected_i: int = randi() % climbers.size()
    var first_infected: Climber = climbers[first_infected_i]
    for i in range(climbers.size()):
        if i == first_infected_i:
            continue

        var climber: Climber = climbers[i]
        climber.spawn_position = global_position + Vector2(randf_range(-enclosure.size+20, enclosure.size -20), enclosure.size - 20)
        climber.role = Climber.Role.SURVIVOR
        climber.reset()

    grace_active = true
    first_infected.spawn_position = global_position + Vector2(randf_range(-enclosure.size+20, enclosure.size -20), enclosure.size - 20)
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

    for i in range(climbers.size()):
        var climber = climbers[i]
        # Add randomness to climber spawn position
        var random_offset: Vector2 = Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
        # Try to find a spawn position that is not too close to other climbers
        var spawn_position: Vector2 = global_position + reward_vec * 40.0
        var max_attempts := 20
        var min_distance := 40.0
        var attempt := 0
        while attempt < max_attempts and Config.collision:
            spawn_position = global_position + reward_vec * 40.0 + random_offset
            var too_close := false
            for j in range(i):
                if spawn_position.distance_to(climbers[j].get_pos()) < min_distance:
                    too_close = true
                    break
            if not too_close:
                break
            random_offset = Vector2(randf_range(-30.0, 30.0), randf_range(-30.0, 30.0))
            attempt += 1
        climber.spawn_position = spawn_position
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
            

func infection_game_ended() -> bool:
    return infected.size() == climbers.size() and climbers.size() > 1

var grace_period: float = 3.0
var grace_active: bool = true
const OUT_OF_BOUNDS_THRESHOLD: float = -2000.0
func _process(delta: float):
    delta *= Config.speed_up
    climb_round_timer -= delta

    if climb_round_timer < 0 or infection_game_ended():
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

            var dist_reward: float = get_dist_reward(climber)

            var dist_from_origin: Vector2 = climber.get_pos() - global_position

            if dist_reward < OUT_OF_BOUNDS_THRESHOLD:
                climber.reset(true)
                continue

            const min_distance_threshold: float = 27.0

            if dist_reward + OFFSET_DISTANCE > max_reached_distance + min_distance_threshold:
                max_reached_distance += min_distance_threshold
                spawn_box()  

            # Check if climber has moved significantly
            var current_pos: Vector2 = climber.get_pos()
            var distance_moved: float = current_pos.distance_to(climber_positions[i])

            if distance_moved < position_tolerance:
                climber.stagnation_timer += delta
                if climber.stagnation_timer >= Config.idle_timeout:
                    climber.reset(true)
                    continue
            else:
                # Climber has moved, reset climb_round_timer and update position
                climber.stagnation_timer = 0.0
                climber_positions[i] = current_pos

            climber.ai_controller.reward = 300. + get_dist_reward(climber) + climber.accumulated_reward_from_making_others_fall - climber.accumulated_punishment_from_getting_fallen

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
var box_count: int = 0
func spawn_box() -> void:
    var box: StaticBody2D = BOX_SCENE.instantiate()
    var spawn_position: Vector2 = 40 * reward_vec.normalized()
    box_count += 1

    if last_spawned_box != null:
      
        box.rotation = randf() * PI * 2 
        spawn_position += last_spawned_box.position
        var min_distance: float = 30.0 + (max_reached_distance * 0.005)  # Increase min distance based on progress

        var max_angle: float
        if box_count < 3:
            max_angle = PI/3.
        else:
            max_angle = PI/1.6

        var noisy_direction: Vector2 = reward_vec.rotated(randf_range(-max_angle, max_angle))
        var offset_length: float = min_distance + randf() * 40.0  # Add some randomness to distance
        var random_offset: Vector2 = noisy_direction * offset_length

        var perp: Vector2 = noisy_direction.orthogonal().normalized()
        random_offset += perp * randf_range(-20.0, 20.0)
        box.scale = Vector2(clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4), clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4))
        spawn_position += random_offset

    else:
        box.scale = Vector2(2.2, 2.2)
        spawn_position *= 1.8
        box.rotation = reward_angle
        # Separate climbers from box if too close
        for climber in climbers:
            var climber_pos = climber.get_pos()
            if spawn_position.distance_to(climber_pos) < 30.0:
                var direction: Vector2 = (climber_pos - spawn_position).normalized()
                var perp: Vector2 = direction.orthogonal().normalized()
                var perp_2: Vector2 = -perp
                # Pick the perp with the furthest angle from gravity vector
                var gravity_vec: Vector2 = Vector2(cos(gravity_angle), sin(gravity_angle))
                var angle1 = abs(perp.angle_to(gravity_vec))
                var angle2 = abs(perp_2.angle_to(gravity_vec))
                var chosen_perp: Vector2 = perp if angle1 > angle2 else perp_2
                
                climber.set_pos(spawn_position + chosen_perp * 30.0)

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

var mod_i: int = 0
func get_dist_reward(climber: Climber) -> float:
    mod_i += 1
    var distance_from_orig: Vector2 = climber.get_pos() - global_position
    var reward: float = distance_from_orig.dot(reward_vec)
    var base_angle_limit: float = deg_to_rad(75)
    var extra_strictness: float = clamp((distance_from_orig.length()) * 0.0004, 0.0, deg_to_rad(65))#ESTÁ EN RADIANES
    var angle_limit: float = base_angle_limit - extra_strictness
    # if mod_i % 1000 == 0:
    #     print("Climber ID: %d, Distance from orig: %f, Extra strictness: %f°, Angle limit: %f°" % [
    #         climber.int_id,
    #         distance_from_orig.length(),
    #         rad_to_deg(extra_strictness),
    #         rad_to_deg(angle_limit)
    #     ])
    var angle_diff: float = abs(distance_from_orig.angle_to(reward_vec))
    if angle_diff > angle_limit:
        reward = -abs(reward)
    return reward


    

    
