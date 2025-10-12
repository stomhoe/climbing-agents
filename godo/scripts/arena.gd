extends Node3D
class_name Arena

@onready var objects = $Objects
@onready var combatants = $Combatants


func get_nearest_combatants_data(mine: Character, n_max: int) -> Array:

    var nearest: Array[Character] = []
    for combatant in combatants.get_children():
        if combatant is Character and combatant != mine:
            nearest.append(combatant)

    var sort_func = func(a, b):
        return a.get_pos().distance_to(mine.get_pos()) < b.get_pos().distance_to(mine.get_pos())

    nearest.sort_custom(sort_func)

    var nearest_data: Array = []

    for i in range(min(n_max, nearest.size())):
        var c = nearest[i]
        nearest_data.append(c.get_body_data())
    return nearest_data
