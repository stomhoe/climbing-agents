extends Node2D


@onready var climbers = $Climbers

func _ready():
    for climber in climbers.get_children():
        climber.target_angle = reward_angle

var climb_time:float = 180
var timer = climb_time
        
#TODO: GENERACIÓN RANDOM ASÍ NO SE BASA EN RANDOMIZACIÓN A BASE DE POSICION

func _process(delta: float):
    timer -= delta
    if timer < 0:
        for _climber in climbers.get_children():
            var climber: Climber = _climber as Climber
            climber.torso.global_position = climber.global_position
            climber.ai_controller.reset()
        timer = climb_time
    else:
        for climber in climbers.get_children():
            var cli: Climber = climber as Climber
            var reward: float = get_reward(cli)
            cli.ai_controller.reward = reward #max(reward, cli.ai_controller.reward)

var reward_angle: float = -PI/2

func get_reward(climber: Climber) -> float:
    var distance_reward_vec = climber.get_pos() - Vector2(0, 0)
    return distance_reward_vec.dot(Vector2(cos(reward_angle), sin(reward_angle)))
