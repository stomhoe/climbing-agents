extends Camera3D

var speed := 10.0
var sensitivity := 0.00005
var velocity := Vector3.ZERO

func _process(delta):
    handle_input(delta)
    move_and_rotate(delta)

func handle_input(delta):
    velocity = Vector3.ZERO
    if Input.is_action_pressed("move_forward"):
        velocity -= transform.basis.z
    if Input.is_action_pressed("move_backward"):
        velocity += transform.basis.z
    if Input.is_action_pressed("move_left"):
        velocity -= transform.basis.x
    if Input.is_action_pressed("move_right"):
        velocity += transform.basis.x
    if Input.is_action_pressed("ui_up"):
        velocity += transform.basis.y
    if Input.is_action_pressed("down"):
        velocity -= transform.basis.y
    velocity = velocity.normalized() * speed

func move_and_rotate(delta):
    # Move the camera based on its orientation
    translate(velocity * delta)

    # Rotate the camera
    if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
        var mouse_motion := Input.get_last_mouse_velocity()
        var yaw: float = -mouse_motion.x * sensitivity
        var pitch: float = -mouse_motion.y * sensitivity
        rotate_y(yaw)
        rotate_object_local(Vector3(1, 0, 0), pitch)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
