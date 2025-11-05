extends StaticBody2D
class_name Enclosure

@onready var map: ClimbMap = get_parent()

const BOX: PackedScene = preload("uid://dh3naami7rgg6")
var size: float:
    set(value):

        size = abs(value)

        for i in range(polygon.polygon.size()):
            var vertex: Vector2 = polygon.polygon[i]
            vertex.x *= size
            vertex.y *= size
            polygon.polygon[i] = vertex

        var n_boxes_to_spawn: int = int(value * value * box_density_mult / 4000.0)

        for box in map.boxes.get_children():
            box.queue_free()

        for i in range(n_boxes_to_spawn):
            var box_instance: Node2D = BOX.instantiate()
            box_instance.rotation = randf() * TAU
            box_instance.position = Vector2(randf_range(-size, size), randf_range(-size, size))
            box_instance.scale.x = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)
            box_instance.scale.y = clamp(abs(randfn(1.7, 0.7)), 0.6, 3.4)
            map.boxes.add_child(box_instance)

@onready var polygon: CollisionPolygon2D = $polygon

var box_density_mult: float = 1.0
