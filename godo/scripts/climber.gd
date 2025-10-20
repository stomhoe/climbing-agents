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

@onready var knees: Array[PinJoint2D] = [r_thigh.joint, l_thigh.joint]
@onready var elbows: Array[PinJoint2D] = [r_upperarm.joint, l_upperarm.joint]

@onready var l_shoulder: PinJoint2D = $Torso/Lshoulder
@onready var r_shoulder: PinJoint2D = $Torso/Rshoulder
@onready var shoulders: Array[PinJoint2D] = [l_shoulder, r_shoulder]

@onready var l_hip: PinJoint2D = $Torso/Lhip
@onready var r_hip: PinJoint2D = $Torso/Rhip
@onready var hips: Array[PinJoint2D] = [l_hip, r_hip]

@onready var r_hand_grabber: Grabber = $Rforearm/RightHand
@onready var l_hand_grabber: Grabber = $Lforearm/LeftHand
@onready var r_foot_grabber: Grabber = $Rcalf/RightFoot
@onready var l_foot_grabber: Grabber = $Lcalf/LeftFoot

@onready var grabbers: Array[Grabber] = [
    r_hand_grabber, l_hand_grabber,
    r_foot_grabber, l_foot_grabber
]

var speed_up: float = 1.0
var stagnation_timer: float = 0.0

@onready var ai_controller: AIClimbController = $AIController2D
var target_angle: float:
    set(value):
        ai_controller.node_above.global_rotation = value + PI/2
        target_angle = value


func reset():
    ai_controller.reset()
    _release_all_grabs()
    stagnation_timer = 0.0
    for body_part in body_parts:
        body_part.linear_velocity = Vector2.ZERO
        body_part.angular_velocity = 0.0
    set_pos(get_parent().global_position)

func set_pos(pos: Vector2) -> void:
    for body_part in body_parts: body_part.global_position = pos

func get_pos() -> Vector2: return torso.global_position

@onready var joints: Dictionary[Grabber, Array] = {
    r_hand_grabber: [r_shoulder, r_upperarm.joint],
    l_hand_grabber: [l_shoulder, l_upperarm.joint],
    r_foot_grabber: [r_hip, r_thigh.joint],
    l_foot_grabber: [l_hip, l_thigh.joint]
}


func _ready():
    for joints_arr in joints.values():
        for joint: PinJoint2D in joints_arr:
            joint.softness = 0
            joint.angular_limit_enabled = true
            joint.motor_enabled = true
    
    for shoulder in shoulders:
        shoulder.angular_limit_lower = deg_to_rad(-110)
        shoulder.angular_limit_upper = deg_to_rad(110)


    r_thigh.joint.angular_limit_lower = 0
    r_thigh.joint.angular_limit_upper = PI/2
    l_thigh.joint.angular_limit_lower = -PI/2
    l_thigh.joint.angular_limit_upper = 0
    
    r_upperarm.joint.angular_limit_lower =  deg_to_rad(-150)
    r_upperarm.joint.angular_limit_upper = deg_to_rad(10)

    l_upperarm.joint.angular_limit_lower = -r_upperarm.joint.angular_limit_upper
    l_upperarm.joint.angular_limit_upper = -r_upperarm.joint.angular_limit_lower


func _physics_process(delta: float):
    delta *= speed_up
    


func _release_all_grabs():
    for grabber in joints.keys():
        grabber.release()
