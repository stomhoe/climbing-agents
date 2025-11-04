extends Node2D
class_name Grabber

@onready var joint: PinJoint2D = $Joint
@onready var grab_area: Area2D = $GrabArea
@onready var hold_area: Area2D = $HoldArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var climber: Climber = get_parent()

var raycasts: Array[RayCast2D]

var is_currently_controlled: bool = false:
    set(value):
        is_currently_controlled = value
        if is_currently_controlled:
            release()

var grab_on_contact: bool = true:
    set(value):
        grab_on_contact = value
        if grab_on_contact:
            if not grab_area.body_entered.is_connected(_on_grab_area_body_entered):
                grab_area.body_entered.connect(_on_grab_area_body_entered)
        else:
            if grab_area.body_entered.is_connected(_on_grab_area_body_entered):
                grab_area.body_entered.disconnect(_on_grab_area_body_entered)
            release()

func _ready():
    grab_area.body_entered.connect(_on_grab_area_body_entered)
    hold_area.body_exited.connect(_on_hold_area_body_exited)
    hold_area.collision_layer = grab_area.collision_layer
    hold_area.collision_mask = grab_area.collision_mask
    
var grabbing_static: bool = false

func is_attached_to_wall() -> bool: return grabbing_static


func release():
    mesh_instance_2d.modulate = Color.GRAY
    joint.node_b = NodePath("")
    grabbing_static = false


func _on_grab_area_body_entered(body: Node):
    if is_currently_controlled:
        return
    if joint.node_b != NodePath(""):
        return
    if body is BodyPart and body.get_parent() == climber:
        return

    if body is StaticBody2D:
        joint.node_a = climber.corresponding_body_part[self].get_path()#DEJAR ACÁ
        joint.node_b = body.get_path()
        mesh_instance_2d.modulate = Color.GREEN
        grabbing_static = true
    else:
        grabbing_static = false
        joint.node_b = body.get_path()

        if body is BodyPart  and climber.role == Climber.Role.INFECTED and body.climber.role == Climber.Role.SURVIVOR and not climber.map.grace_active:
            body.climber.role = Climber.Role.INFECTED
            climber.bitten_count += 1

func _on_hold_area_body_exited(body: Node2D):
    if body.get_path() == joint.node_b:
        release()
