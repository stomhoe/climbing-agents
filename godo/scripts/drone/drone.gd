extends VehicleBody3D
class_name LandDrone

@onready var ai_controller_3d: AiLandDroneController = $AIController3D

@onready var yaw_joint: PinJoint3D = $yaw_joint
@onready var rigid: RigidBody3D = $yaw_joint/rigid
@onready var roll_joint: PinJoint3D = $yaw_joint/roll_joint
@onready var mg_rigid: RigidBody3D = $yaw_joint/roll_joint/mg_rigid

# Wheel references (assuming VehicleWheel3D nodes)
@onready var wheel_fl: VehicleWheel3D = $wheel_fl  # front left
@onready var wheel_fr: VehicleWheel3D = $wheel_fr  # front right
@onready var wheel_bl: VehicleWheel3D = $wheel_bl  # back left
@onready var wheel_br: VehicleWheel3D = $wheel_br  # back right

@export var max_wheel_force: float = 1000.0
@export var turret_rotation_speed: float = 2.0

func _physics_process(delta: float) -> void:
    if ai_controller_3d:
        # Apply wheel forces
        var forces: Vector4 = ai_controller_3d.wheel_forces
        wheel_fl.engine_force = forces.x * max_wheel_force
        wheel_fr.engine_force = forces.y * max_wheel_force
        wheel_bl.engine_force = forces.z * max_wheel_force
        wheel_br.engine_force = forces.w * max_wheel_force
        
        # Apply turret rotation
        var turret_rot = ai_controller_3d.turret_rotation
        # Apply torque forces to rigid bodies instead of motor velocities
        rigid.apply_torque(Vector3(0, turret_rot.y * turret_rotation_speed, 0))
        mg_rigid.apply_torque(Vector3(turret_rot.x * turret_rotation_speed, 0, 0))
        
        # Handle firing
        if ai_controller_3d.fire_command:
            fire_weapon()

func fire_weapon() -> void:
    # Implement weapon firing logic here
    print("Firing weapon!")
