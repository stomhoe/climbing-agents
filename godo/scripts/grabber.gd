extends Node2D
class_name Grabber

@onready var joint = $Joint
@onready var grab_area = $GrabArea

func _ready():
    # Set up the joint to connect to the parent body part
    joint.node_a = get_parent().get_path()
    joint.node_b = NodePath("")  # Initially not connected
    
    # Set the joint position to this grabber's position relative to parent
    joint.position = position

func is_grabbing() -> bool:
    """Returns true if this grabber is currently grabbing something"""
    return joint.node_b != NodePath("")

func release():
    """Release the current grab"""
    joint.node_b = NodePath("")
