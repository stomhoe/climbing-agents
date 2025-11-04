extends StaticBody2D
class_name Enclosure

@onready var map: ClimbMap = get_parent()

const BOX: PackedScene = preload("uid://dh3naami7rgg6")
var size: float:
    set(value):

        size = abs(value)

        for wall in walls:
            wall.distance = -size

        var rand_density_mult: float = randf_range(0.8, 1.2)
        var n_boxes_to_spawn: int = int(value * value * rand_density_mult * box_density_mult / 3000.0)

        for box in map.boxes.get_children():
            box.queue_free()

        for i in range(n_boxes_to_spawn):
            var box_instance: Node2D = BOX.instantiate()
            box_instance.rotation = randf() * TAU
            box_instance.position = Vector2(randf_range(-size, size), randf_range(-size, size))
            box_instance.scale.x = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)
            box_instance.scale.y = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)
            map.boxes.add_child(box_instance)


var walls: Array[WorldBoundaryShape2D] = []
var box_density_mult: float = 1.0

func _ready():
    for child in get_children():
        if child is CollisionShape2D:
            var shape: Shape2D = child.shape
            if shape is WorldBoundaryShape2D:
                walls.append(shape)
