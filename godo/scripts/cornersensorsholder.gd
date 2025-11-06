extends Node2D
class_name CornerSensors

var sensors: Array[BodySensor] = []

func _ready():
    for child in get_children():
        if child is BodySensor:
            sensors.append(child)

func get_all_static_raycasts() -> PackedFloat64Array:
    var raycasts: PackedFloat64Array = PackedFloat64Array()
    for sensor in sensors:
        raycasts.append_array(sensor.get_raycasts_static_only())
    return raycasts
