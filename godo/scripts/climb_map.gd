extends Node2D


@onready var climbers = $Climbers

func _ready():
    for climber in climbers.get_children():
        climber.target = $Target

func _process(delta):
    for climber in climbers.get_children():
        (climber as Climber).ai_controller.reward = 1
