extends Node2D
class_name Climber

# Body parts
@onready var torso: RigidBody2D = $Torso
@onready var r_forearm: RigidBody2D = $Rforearm
@onready var l_forearm: RigidBody2D = $Lforearm
@onready var r_upperarm: RigidBody2D = $Rupperarm
@onready var l_upperarm: RigidBody2D = $Lupperarm
@onready var r_thigh: RigidBody2D = $Rthigh
@onready var l_thigh: RigidBody2D = $Lthigh
@onready var r_calf: RigidBody2D = $Rcalf
@onready var l_calf: RigidBody2D = $Lcalf

@onready var l_shoulder = $Torso/Lshoulder
@onready var r_shoulder = $Torso/Rshoulder
@onready var l_hip = $Torso/Lhip
@onready var r_hip = $Torso/Rhip
@onready var r_knee = $Rthigh/Rknee
@onready var r_elbow = $Rupperarm/Relbow
@onready var l_knee = $Lthigh/Lknee

# also stores Grab states
@onready var r_hand_grabber = $Rforearm/Grabber
@onready var l_hand_grabber = $Lforearm/Grabber
@onready var r_foot_grabber = $Rcalf/Grabber
@onready var l_foot_grabber = $Lcalf/Grabber


# Control variables
var control_strength: float = 2000.0
var damping: float = 3


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

    _setup_body_physics()

func _setup_body_physics():
    # Make the climber more responsive and realistic
    var bodies = [r_forearm, l_forearm, r_upperarm, l_upperarm, 
                  r_thigh, l_thigh, r_calf, l_calf]
    
    for body in bodies:
        body.linear_damp = damping
        body.angular_damp = damping

func _physics_process(delta: float):
    _handle_input()
    _apply_muscle_forces(delta)

# Add any necessary vars here
var swing_boost_time: float = 0.5  # Duration of the swing boost in seconds
var swing_boost_strength: float = 4000.0  # Additional strength during the swing boost
var swing_timer: float = 0.0  # Timer to track the swing boost duration

func _apply_muscle_forces(delta: float):
    if currently_controlled:
        # Apply force to move the controlled limb towards the mouse position
        var limb: RigidBody2D = currently_controlled.get_parent() as RigidBody2D
        var applied_strength = control_strength
        
        # Apply swing boost if within the boost time
        if swing_timer > 0.0:
            applied_strength += swing_boost_strength
            swing_timer -= delta
        
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
    
    # If we just stopped controlling a grabber, try to grab
    if currently_controlled != null and new_controlled != currently_controlled:
        _try_auto_grab(currently_controlled)
    
    # If we just started controlling a grabber, release its grab and reset swing boost
    if new_controlled != null and new_controlled != currently_controlled:
        _release_grab(new_controlled)
        swing_timer = swing_boost_time  # Reset swing boost timer
    
    currently_controlled = new_controlled

    if currently_controlled:
        force_direction = (get_global_mouse_position() - currently_controlled.global_position).normalized()


var currently_controlled: Grabber = null

var force_direction: Vector2 = Vector2.ZERO


func _on_grab_area_entered(body: Node2D, grabber: Grabber):
    # This function now just provides debug info
    # Actual grabbing is handled by _try_auto_grab when releasing control
    if not (body is Boundaries or (body is BodyPart and body.get_parent() == self)):
        print("%s detected %s in grab range" % [grabber.get_parent().name, body.name])

func _release_grab(grabber: Grabber):
    """Release the grab by disconnecting the joint"""
    grabber.release()
    print("Released grab for: " + grabber.get_parent().name)

func _try_auto_grab(grabber: Grabber):
    """Try to automatically grab whatever this grabber is touching"""
    var bodies = grabber.grab_area.get_overlapping_bodies()
    
    print("Trying to auto-grab with %s, found %d bodies" % [grabber.get_parent().name, bodies.size()])
    
    for body in bodies:
        print("  - Found body: %s (type: %s)" % [body.name, body.get_class()])
        
        # Check if it's a valid body to grab
        if body is Boundaries:
            print("    Skipping: is Boundaries")
            continue
            
        # Prevent grabbing own body parts
        if body is BodyPart and body.get_parent() == self:
            print("    Skipping: is own body part")
            continue
            
        # Found a valid body to grab
        grabber.joint.node_b = body.get_path()
        # Set the joint position to the grabber's local position relative to its parent
        grabber.joint.position = grabber.position
        print("    SUCCESS: %s auto-grabbed %s" % [grabber.get_parent().name, body.name])
        return
    
    print("  %s found nothing valid to grab" % grabber.get_parent().name)
            
            
