extends Camera2D

@export var move_speed: float = 3000.0

func _process(delta: float) -> void:
    var direction = Vector2.ZERO

    if Input.is_action_pressed("ui_right"):
        direction.x += 1
    if Input.is_action_pressed("ui_left"):
        direction.x -= 1
    if Input.is_action_pressed("ui_down"):
        direction.y += 1
    if Input.is_action_pressed("ui_up"):
        direction.y -= 1

    if direction != Vector2.ZERO:
        direction = direction.normalized()
        position += direction * move_speed * delta

    if Input.is_action_just_pressed("reset_pos"):
        position = Vector2.ZERO

func _input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
            zoom *= 1.1
        elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
            zoom *= 0.9
