extends Node2D
class_name Grabber

@onready var joint = $Joint
@onready var grab_area = $GrabArea
@onready var mesh_instance_2d: MeshInstance2D = $MeshInstance2D

func _ready():
    # Set up the joint to connect to the parent body part
    joint.node_a = get_parent().get_path()
    joint.node_b = NodePath("")  # Initially not connected
    
func is_grabbing() -> bool:
    """Returns true if this grabber is currently grabbing something"""
    return joint.node_b != NodePath("")

func release():
    """Release the current grab"""
    print("\nRELEASE: ----", joint.node_b)
    mesh_instance_2d.modulate = Color.WHITE
    joint.node_b = NodePath("")

func debug_joint_status():
    """Debug function to check joint status"""
    print("=== Grabber Joint Debug ===")
    print("Joint exists: ", joint != null)
    print("Node A: ", joint.node_a)
    print("Node B: ", joint.node_b)
    print("Joint position: ", joint.position)
    print("Parent: ", get_parent().name if get_parent() else "None")
    print("==========================")
