extends Node2D


@onready var climbers = $Climbers

func _ready():
    for climber in climbers.get_children():
        climber.target = $Target

func _process(delta):
    for climber in climbers.get_children():
        var cli: Climber = climber as Climber
        cli.ai_controller.reward = get_reward(cli)

var reward_angle: float = 0

func get_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.global_position - Vector2(0, 0)
    return distance_reward_vec.dot(Vector2(cos(reward_angle), sin(reward_angle)))
