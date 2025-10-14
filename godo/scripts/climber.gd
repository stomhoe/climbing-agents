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
var damping: float = 0.8


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
    var bodies = [torso, r_forearm, l_forearm, r_upperarm, l_upperarm, 
                  r_thigh, l_thigh, r_calf, l_calf]
    
    #for body in bodies:
        #body.linear_damp = damping
        #body.angular_damp = damping

func _physics_process(delta):
    _handle_input()
    _apply_muscle_forces()
    
func _apply_muscle_forces():
    if currently_controlled:
        # Apply force to move the controlled limb towards the mouse position
        var limb: RigidBody2D = currently_controlled.get_parent() as RigidBody2D
        limb.apply_force(force_direction * control_strength, currently_controlled.global_position - limb.global_position)
        print("applying force ", force_direction * control_strength)


var currently_controlled: Grabber = null

var force_direction: Vector2 = Vector2.ZERO

func _handle_input():
    var left_hand_pressed: bool = Input.is_action_pressed(&"left_hand_control")
    var right_hand_pressed: bool = Input.is_action_pressed(&"right_hand_control")
    var left_foot_pressed: bool = Input.is_action_pressed(&"left_foot_control")
    var right_foot_pressed: bool = Input.is_action_pressed(&"right_foot_control")

    match [left_hand_pressed, right_hand_pressed, left_foot_pressed, right_foot_pressed]:
        [false, true, false, false]:
            currently_controlled = r_hand_grabber
        [false, false, true, false]:
            currently_controlled = l_foot_grabber
        [false, false, false, true]:
            currently_controlled = r_foot_grabber
        [false, false, false, false]:
            currently_controlled = null
        [true, _, _, _]:
            currently_controlled = l_hand_grabber

    if currently_controlled:
        currently_controlled.joint.node_b = NodePath("")

        force_direction = (get_global_mouse_position() - currently_controlled.global_position).normalized()

func _on_grab_area_entered(body: Node, grabber: Grabber):
    if grabber != currently_controlled:
        var joint: PinJoint2D = grabber.joint
        if not (body is Boundaries or body is BodyPart):
            joint.node_b = body.get_path()
            
            
