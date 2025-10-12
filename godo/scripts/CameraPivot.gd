extends Node3D


var mouse_sensitivity: float = 0.1# camera rotation speed


@onready var spring_arm = $SpringArm3D

@onready var character: Character = get_parent()

var mouse_lock = false # is mouse locked

func _physics_process(_delta: float):
    if character.physical_bone_head != null:
        # lerp position to the target position
        global_position = lerp(global_position, character.physical_bone_head.global_position,0.5)
        #print
        for child in character.physical_skel.get_children():
        # prevent the camera from clipping into the character
            if child is PhysicalBone3D:spring_arm.add_excluded_object(child.get_rid())

func _input(event):
    
    if Input.is_action_just_pressed(&"ragdoll"): character.ragdoll_mode = !character.ragdoll_mode # toggle ragdoll mode

    character.input_move = Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_backward")

    character.active_arm_left = Input.is_action_pressed(&"grab_left")# activate left arm with mouse left click
    character.active_arm_right = Input.is_action_pressed(&"grab_right")# activate right arm with mouse right click
    # mouse lock
    if Input.is_action_just_pressed(&"exit_camera"):
        mouse_lock = false
        Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
        mouse_lock = true
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    
    #rotate camera
    if event is InputEventMouseMotion and mouse_lock:
        rotation_degrees.y -= mouse_sensitivity*event.relative.x
        rotation_degrees.x -= mouse_sensitivity*event.relative.y
        rotation_degrees.x = clamp(rotation_degrees.x,-45,45)
        character.input_rot.x = rotation.x
        character.input_rot.y = rotation.y
    
        
