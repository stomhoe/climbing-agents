extends CharacterBody3D

@onready var ai_controller = $AIController3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var initial_pos: Vector3 = self.position

const SPEED = 5.0

func _physics_process(delta: float):
	velocity = Vector3(
		ai_controller.move.x * SPEED * delta,
		0,
		ai_controller.move.y * SPEED * delta
	)
	move_and_slide()

func _on_target_body_entered(body):
	position = initial_pos
	ai_controller.reward += 1.0


func _on_walls_body_entered(body):
	position = initial_pos
	ai_controller.reward -= 1.0
	ai_controller.reset()
