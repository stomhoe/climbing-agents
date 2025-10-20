extends BodyPart
class_name InterLimb


@export var glob_mult: float = 1.0
@export var rad_mult: float = 1.0
@export var height_mult: float = 1.0

@export var next_limb: BodyPart:
    set(value):
        assert(value != self)
        next_limb = value
        
@export var joint_displacement: float = 3.415

@onready var joint: PinJoint2D = $InterLimbJoint
@onready var collision_shape_2d = $CollisionShape2D
@onready var mesh_instance_2d = $MeshInstance2D

func _ready():
    joint.position.x = joint_displacement
    joint.node_a = self.get_path()
    joint.node_b = next_limb.get_path()
    
    collision_shape_2d.shape.height *= height_mult * glob_mult
    collision_shape_2d.shape.radius *= rad_mult * glob_mult
    
    mesh_instance_2d.mesh.radius *= rad_mult * glob_mult
    mesh_instance_2d.mesh.height *= height_mult * glob_mult
    
