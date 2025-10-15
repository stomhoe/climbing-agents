extends Node2D


@onready var climbers = $Climbers

func _ready():
    for climber in climbers.get_children():
        climber.target_angle = reward_angle

func _process(delta):
    for climber in climbers.get_children():
        var cli: Climber = climber as Climber
        var reward: float = get_reward(cli)
        cli.ai_controller.reward = max(reward, cli.ai_controller.reward)

var reward_angle: float = -PI/2

func get_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(Vector2(cos(reward_angle), sin(reward_angle)))
