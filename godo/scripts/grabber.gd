extends Node2D
class_name Grabber

@onready var joint: PinJoint2D = $Joint
@onready var grab_area: Area2D = $GrabArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D

func _ready():
    # Set up the joint to connect to the parent body part
    joint.node_a = get_parent().get_path()
    
func is_grabbing() -> bool:
    """Returns true if this grabber is currently grabbing something"""
    return joint.node_b != NodePath("")

func release():
    """Release the current grab"""
    var was_grabbing = is_grabbing()
    mesh_instance_2d.modulate = Color.WHITE
    joint.node_b = NodePath("")
    
    # Notify the climber that this grabber released
    if was_grabbing:
        var climber = get_node("../../") as Climber  # Navigate to climber
        if climber:
            climber._on_grabber_released(self)
