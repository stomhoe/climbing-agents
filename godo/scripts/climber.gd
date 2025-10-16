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

@onready var l_shoulder: PinJoint2D = $Torso/Lshoulder
@onready var r_shoulder: PinJoint2D = $Torso/Rshoulder
@onready var l_hip: PinJoint2D = $Torso/Lhip
@onready var r_hip: PinJoint2D = $Torso/Rhip

# also stores Grab states
@onready var r_hand_grabber: Grabber = $Rforearm/Grabber
@onready var l_hand_grabber: Grabber = $Lforearm/Grabber
@onready var r_foot_grabber: Grabber = $Rcalf/Grabber
@onready var l_foot_grabber: Grabber = $Lcalf/Grabber

var speed_up: float = 1.0

var max_height: float = 0.0;

@onready var ai_controller: AIClimbController = $AIController2D
var target_angle: float:
    set(value):
        ai_controller.node_above.global_rotation = value + PI/2
        target_angle = value

var stagnation_timer: float = 0.0

func reset():
    ai_controller.reset()
    _release_all_grabs()
    set_pos(Vector2.ZERO)
    stagnation_timer = 0.0
    max_height = 0.0

func set_pos(pos: Vector2) -> void:
    torso.global_position = pos
    r_upperarm.global_position = pos
    l_upperarm.global_position = pos
    r_thigh.global_position = pos
    l_thigh.global_position = pos
    r_forearm.global_position = pos
    l_forearm.global_position = pos
    r_calf.global_position = pos
    l_calf.global_position = pos

func get_pos() -> Vector2:
    return torso.global_position

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
# Input states
var left_trigger_pressed: bool = false
var right_trigger_pressed: bool = false
var left_bumper_pressed: bool = false
var right_bumper_pressed: bool = false

func _ready():
    # Connect grab area signals
    r_hand_grabber.grab_area.body_entered.connect(_on_grab_area_entered.bind(r_hand_grabber))
    l_hand_grabber.grab_area.body_entered.connect(_on_grab_area_entered.bind(l_hand_grabber))
    r_foot_grabber.grab_area.body_entered.connect(_on_grab_area_entered.bind(r_foot_grabber))
    l_foot_grabber.grab_area.body_entered.connect(_on_grab_area_entered.bind(l_foot_grabber))
    
    for joints_arr in joints.values():
        for joint in joints_arr:
            joint.angular_limit_lower = -2.5
            joint.angular_limit_upper = 2.5

func _physics_process(delta: float):
    delta *= speed_up
    #_handle_input()
    _apply_muscle_forces(delta)

# Add any necessary vars here
var swing_boost_time: float = 1.5  # Duration of the swing boost in seconds
var swing_boost_strength: float = 1400.0  # Additional strength during the swing boost
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
    
    # Lock joints for uncontrolled limbs that aren't grabbing anything

    for grabber in joints:
        var joint_list = joints[grabber]
        if grabber != currently_controlled and not grabber.is_grabbing():
            for joint in joint_list:
                joint.angular_limit_enabled = true
        else:
            for joint in joint_list:
                joint.angular_limit_enabled = false


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
    set_controlled_grabber(new_controlled)

    if currently_controlled:
        force_direction = (get_global_mouse_position() - currently_controlled.global_position).normalized()


var currently_controlled: Grabber = null

var force_direction: Vector2 = Vector2.ZERO

func set_controlled_grabber(new_controlled: Grabber):
    """Set the currently controlled grabber and handle grab/release logic."""
    # If we just stopped controlling a grabber, try to grab
    if currently_controlled != null and new_controlled != currently_controlled:
        _try_auto_grab(currently_controlled)
        
    if new_controlled != null and new_controlled != currently_controlled:
        _release_grab(new_controlled)
        swing_timer = swing_boost_time 
    
    currently_controlled = new_controlled


func _on_grab_area_entered(body: Node2D, grabber: Grabber):
    """Automatically grab any valid body if the grabber is not currently controlled."""
    if grabber != currently_controlled:
        if _is_valid_grab_target(body, grabber):
            grabber.joint.node_b = body.get_path()
            grabber.joint.position = grabber.position

func _release_all_grabs():
    for grabber in joints.keys():
        _release_grab(grabber)

func _release_grab(grabber: Grabber):
    """Release the grab by disconnecting the joint."""
    grabber.release()

func _try_auto_grab(grabber: Grabber):
    """Try to automatically grab whatever this grabber is touching."""
    var bodies = grabber.grab_area.get_overlapping_bodies()
    
    for body in bodies:
        if _is_valid_grab_target(body, grabber):
            grabber.joint.node_b = body.get_path()
            grabber.joint.position = grabber.position
            return
    

func _is_valid_grab_target(body: Node2D, grabber: Grabber) -> bool:
    """Check if the body is a valid target for grabbing."""
    if body is Boundaries:
        return false
    if body is BodyPart and body.get_parent() == self:
        return false
    return true
