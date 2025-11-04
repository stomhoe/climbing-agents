extends Node2D
class_name Climber

# Body parts
@onready var torso: RigidBody2D = $Torso
@onready var r_forearm: RigidBody2D = $Rforearm
@onready var l_forearm: RigidBody2D = $Lforearm
@onready var r_upperarm: InterLimb = $Rupperarm
@onready var l_upperarm: InterLimb = $Lupperarm
@onready var r_thigh: InterLimb = $Rthigh
@onready var l_thigh: InterLimb = $Lthigh
@onready var r_calf: RigidBody2D = $Rcalf
@onready var l_calf: RigidBody2D = $Lcalf

@onready var body_parts: Array[BodyPart] = [
    torso, r_forearm, l_forearm, r_upperarm, l_upperarm,
    r_thigh, l_thigh, r_calf, l_calf,
]

@onready var l_shoulder: PinJoint2D = $Torso/Lshoulder
@onready var r_shoulder: PinJoint2D = $Torso/Rshoulder
@onready var l_hip: PinJoint2D = $Torso/Lhip
@onready var r_hip: PinJoint2D = $Torso/Rhip

@onready var r_hand_grabber: Grabber = $RightHand
@onready var l_hand_grabber: Grabber = $LeftHand
@onready var r_foot_grabber: Grabber = $RightFoot
@onready var l_foot_grabber: Grabber = $LeftFoot

@onready var joints: Dictionary[Grabber, Array] = {
    r_hand_grabber: [r_shoulder, r_upperarm.joint],
    l_hand_grabber: [l_shoulder, l_upperarm.joint],
    r_foot_grabber: [r_hip, r_thigh.joint],
    l_foot_grabber: [l_hip, l_thigh.joint]
}

@onready var corresponding_body_part: Dictionary[Grabber, RigidBody2D] = {
    r_hand_grabber: r_forearm,
    l_hand_grabber: l_forearm,
    r_foot_grabber: r_calf,
    l_foot_grabber: l_calf
}

var map: ClimbMap
var spawn_position: Vector2 = Vector2.ZERO
var bitten_count: int = 0
enum Role {CLIMBER, SURVIVOR, INFECTED}

var role: Role = Role.CLIMBER:
    set(value):
        role = value
        if role == Role.INFECTED:
            map.add_new_infected(self)
            for part: BodyPart in body_parts:
                part.modulate = Color.GREEN
        else:
            for part in body_parts:
                part.modulate = Color.WHITE

        #if role == Role.CLIMBER:
            #for part in body_parts:
                #part.collision_layer = 0
        #else:
            #for part in body_parts:
                #part.collision_layer = 1

        if role != Role.SURVIVOR:
            closest_infected_dist_vec = Vector2.ZERO
        else:
            map.non_infected.append(self)
            target_angle = TAU + 0.5

@onready var ai_controller: AIClimbController = $AIController2D
var target_angle: float:
    set(value):
        ai_controller.node_above.global_rotation = value + PI/2
        target_angle = value

var stagnation_timer: float = 0.0

func reset(punish: bool = false):
    if punish and ai_controller.reward > 0.0:
        ai_controller.reward *= 0.5
    ai_controller.reset()
    _release_all_grabs()
    stagnation_timer = 0.0
    nullify_velocity()
    set_pos(spawn_position)
    bitten_count = 0
    if role == Role.CLIMBER:
        spawning_rem_timer = 0.5
        
var spawning_rem_timer: float = 0.0

func nullify_velocity() -> void:
    for body_part in body_parts:
        body_part.linear_velocity = Vector2.ZERO
        body_part.angular_velocity = 0.0

func set_pos(pos: Vector2) -> void: for body_part in body_parts: body_part.global_position = pos

func get_pos() -> Vector2: return torso.global_position


func _at_least_one_grabbed() -> bool:
    return r_hand_grabber.is_attached_to_wall() or l_hand_grabber.is_attached_to_wall() or r_foot_grabber.is_attached_to_wall() or l_foot_grabber.is_attached_to_wall()

# Control variables

func _ready():
    for joints_arr in joints.values():
        for joint: PinJoint2D in joints_arr:
            joint.motor_enabled = true
            joint.angular_limit_enabled = false
            joint.angular_limit_lower = deg_to_rad(-1)
            joint.angular_limit_upper = deg_to_rad(1)

    for part in body_parts:
        for part2 in body_parts:
            part.add_collision_exception_with(part2)
        ai_controller.body_sensor.add_exception(part)

func _physics_process(delta: float):
    delta *= Config.speed_up
    if spawning_rem_timer >= 0.0:
        spawning_rem_timer -= delta
        nullify_velocity()

    _apply_muscle_forces(delta)
    
    var max_distance := 40.0  
    for body_part in body_parts:
        if body_part.global_position.distance_to(torso.global_position) > max_distance:
            body_part.global_position = torso.global_position
            body_part.linear_velocity = Vector2.ZERO
            body_part.angular_velocity = 0.0

var closest_infected_dist_vec: Vector2 = Vector2.ZERO

func _process(delta: float):
    delta *= Config.speed_up

    var min_dist: float = INF
    if role == Role.SURVIVOR:
        for climber in map.infected:
            var dist: float = get_pos().distance_to(climber.get_pos())
            if dist < min_dist:
                min_dist = dist
                closest_infected_dist_vec = (climber.get_pos() - get_pos())

        ai_controller.reward = 8000. + min(min_dist, 2000.0)
    elif role == Role.INFECTED:
        for prey in map.non_infected:
            var dist: float = get_pos().distance_to(prey.get_pos())
            if dist < min_dist:
                min_dist = dist
                target_angle = (prey.get_pos() - get_pos()).angle()
        ai_controller.reward = 1000. -min(min_dist, 2000.0) + bitten_count * 1500
    
    


var swing_boost_time: float = 1.5  # Duration of the swing boost in seconds
var swing_boost_strength: float = 4700.0  # Additional strength during the swing boost
var swing_timer: float = 0.0  # Timer to track the swing boost duration
var control_strength: float = 2000.0

func _apply_muscle_forces(delta: float):
    if currently_controlled:
        # Apply force to move the controlled limb towards the mouse position
        var limb: RigidBody2D = corresponding_body_part[currently_controlled]
        var final_strength: float = control_strength
        
        # Apply swing boost if within the boost timead
        if _at_least_one_grabbed():
            if swing_timer > 0.0:
                final_strength += swing_boost_strength * swing_boost_time
                swing_timer -= delta
            final_strength += 3000.
        
        limb.apply_force(force_direction * final_strength, currently_controlled.global_position - limb.global_position)


var currently_controlled: Grabber = null:
    set(value):
        if currently_controlled != value:
            if currently_controlled:
                #for joint in joints[currently_controlled]: joint.motor_enabled = true
                currently_controlled.mesh_instance_2d.modulate = Color.WHITE
                currently_controlled.is_currently_controlled = false
            currently_controlled = value
            if currently_controlled:
                currently_controlled.is_currently_controlled = true
                currently_controlled.mesh_instance_2d.modulate = Color.PURPLE                
                swing_timer = swing_boost_time 

var force_direction: Vector2 = Vector2.ZERO

func _release_all_grabs():
    for grabber in joints.keys():
        grabber.release()
