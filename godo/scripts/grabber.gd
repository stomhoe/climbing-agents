extends Node2D
class_name Grabber

@onready var joint = $Joint
@onready var grab_area = $GrabArea

func _ready():
    joint.node_a = get_parent().get_parent().get_path()
