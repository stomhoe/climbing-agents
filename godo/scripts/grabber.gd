extends Node2D
class_name Grabber

@onready var joint: PinJoint2D = $Joint
@onready var grab_area: Area2D = $GrabArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D
@onready var climber: Climber = get_parent().get_parent()
var grabbing_wall: bool = false

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
    joint.node_a = get_parent().get_path()
    grab_area.body_entered.connect(_on_grab_area_body_entered)
    pass
    
func is_grabbing_wall() -> bool:
    return grabbing_wall

func release():
    mesh_instance_2d.modulate = Color.GRAY
    joint.node_b = NodePath("")
    grabbing_wall = false


func _on_grab_area_body_entered(body: Node):
    if is_currently_controlled:
        return

    if joint.node_b != NodePath(""):
        return

    if body is BodyPart and body.climber == climber:
        return
    if not body is BodyPart:
        grabbing_wall = true
    else:
        grabbing_wall = false

    joint.node_b = body.get_path()
    mesh_instance_2d.modulate = Color.GREEN
