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

@onready var body_parts: Array[RigidBody2D] = [
    torso, r_forearm, l_forearm, r_upperarm, l_upperarm,
    r_thigh, l_thigh, r_calf, l_calf,
]

@onready var l_shoulder: PinJoint2D = $Torso/Lshoulder
@onready var r_shoulder: PinJoint2D = $Torso/Rshoulder
@onready var l_hip: PinJoint2D = $Torso/Lhip
@onready var r_hip: PinJoint2D = $Torso/Rhip

@onready var r_hand_grabber: Grabber = $Rforearm/RightHand
@onready var l_hand_grabber: Grabber = $Lforearm/LeftHand
@onready var r_foot_grabber: Grabber = $Rcalf/RightFoot
@onready var l_foot_grabber: Grabber = $Lcalf/LeftFoot

var spawn_position: Vector2 = Vector2.ZERO

var speed_up: float = 1.0

@onready var ai_controller: AIClimbController = $AIController2D
var target_angle: float:
    set(value):
        ai_controller.node_above.global_rotation = value + PI/2
        target_angle = value

var stagnation_timer: float = 0.0

func reset():
    ai_controller.reset()
    _release_all_grabs()
    stagnation_timer = 0.0
    for body_part in body_parts:
        body_part.linear_velocity = Vector2.ZERO
        body_part.angular_velocity = 0.0
    set_pos(spawn_position)
    #print("reset")

func set_pos(pos: Vector2) -> void:
    for body_part in body_parts:
        body_part.global_position = pos

func get_pos() -> Vector2: return torso.global_position

@onready var joints: Dictionary[Grabber, Array] = {
    r_hand_grabber: [r_shoulder, r_upperarm.joint],
    l_hand_grabber: [l_shoulder, l_upperarm.joint],
    r_foot_grabber: [r_hip, r_thigh.joint],
    l_foot_grabber: [l_hip, l_thigh.joint]
}
func _at_least_one_grabbed() -> bool:
    return r_hand_grabber.is_grabbing() or l_hand_grabber.is_grabbing() or r_foot_grabber.is_grabbing() or l_foot_grabber.is_grabbing()

# Control variables
var control_strength: float = 1000.0

func _ready():
    for joints_arr in joints.values():
        for joint: PinJoint2D in joints_arr:
            joint.motor_enabled = false
            joint.angular_limit_enabled = false
            joint.angular_limit_lower = deg_to_rad(-1)
            joint.angular_limit_upper = deg_to_rad(1)

func _physics_process(delta: float):
    delta *= speed_up
    _apply_muscle_forces(delta)

# Add any necessary vars here
var swing_boost_time: float = 1.5  # Duration of the swing boost in seconds
var swing_boost_strength: float = 1700.0  # Additional strength during the swing boost
var swing_timer: float = 0.0  # Timer to track the swing boost duration

func _apply_muscle_forces(delta: float):
    if currently_controlled:
        # Apply force to move the controlled limb towards the mouse position
        var limb: RigidBody2D = currently_controlled.get_parent() as RigidBody2D
        var applied_strength: float = control_strength
        
        # Apply swing boost if within the boost timead
        if _at_least_one_grabbed():
            if swing_timer > 0.0:
                applied_strength += swing_boost_strength * swing_boost_time
                swing_timer -= delta
            applied_strength += 1500.
        
        limb.apply_force(force_direction * applied_strength, currently_controlled.global_position - limb.global_position)


func _handle_input():
    var left_hand_pressed: bool = Input.is_action_pressed(&"left_hand_control")
    var right_hand_pressed: bool = Input.is_action_pressed(&"right_hand_control")
    var left_foot_pressed: bool = Input.is_action_pressed(&"left_foot_control")
    var right_foot_pressed: bool = Input.is_action_pressed(&"right_foot_control")

    var new_controlled: Grabber = null
    
    match [left_hand_pressed, right_hand_pressed, left_foot_pressed, right_foot_pressed]:
        [false, true, false, false]:
            new_controlled = r_hand_grabber
        [false, false, true, false]:
            new_controlled = l_foot_grabber
        [false, false, false, true]:
            new_controlled = r_foot_grabber
        [false, false, false, false]:
            new_controlled = null
        [true, _, _, _]:
            new_controlled = l_hand_grabber
    
    # Use the helper method to set the controlled grabber
    currently_controlled = new_controlled
    
    print("CONTROLANDO A MANO")

    if currently_controlled:
        force_direction = (get_global_mouse_position() - currently_controlled.global_position).normalized()


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
