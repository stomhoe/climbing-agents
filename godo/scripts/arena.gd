extends Node3D
class_name Arena

@onready var objects = $Objects
@onready var combatants= $Combatants

@onready var remaining_combatants: Array[Combatant] = []

func _ready():
    restart_match()

func restart_match():
    print("Restarting match")
    remaining_combatants.clear()
    for combatant in combatants.get_children():
        if combatant is Combatant:
            combatant.set_physics_process(true)
            combatant.physical_skel.physical_bones_stop_simulation()
            combatant.physical_skel.position = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
            combatant.physical_skel.physical_bones_start_simulation()
            combatant.ragdoll_mode = false
            combatant.animation_tree.active = true
            combatant.can_jump = true
            combatant.grabbing_arm_left = false
            combatant.grabbing_arm_right = false
            combatant.active_arm_left = false
            combatant.active_arm_right = false
            combatant.jump_timer.stop()
            remaining_combatants.append(combatant)


func get_nearest_combatants_data(mine: Combatant, n_max: int) -> Array:

    var nearest: Array[Combatant] = []
    for combatant in combatants.get_children():
        if combatant is Combatant and combatant != mine:
            nearest.append(combatant)

    var sort_func = func(a, b):
        return a.get_pos().distance_to(mine.get_pos()) < b.get_pos().distance_to(mine.get_pos())

    nearest.sort_custom(sort_func)

    var nearest_data: Array = []

    for i in range(min(n_max, nearest.size())):
        var c = nearest[i]
        nearest_data.append_array(c.get_body_data())
    return nearest_data


func get_nearest_objects_data(mine: Combatant, n_max: int) -> Array:
    var nearest: Array[Grabbable] = []
    for obj in objects.get_children():
        if obj is Grabbable:
            nearest.append(obj)

    var sort_func = func(a, b):
        return a.global_position.distance_to(mine.get_pos()) < b.global_position.distance_to(mine.get_pos())

    nearest.sort_custom(sort_func)

    var nearest_data: Array = []

    for i in range(min(n_max, nearest.size())):
        var o = nearest[i]
        nearest_data.append_array(o.get_data())
    return nearest_data

func _physics_process(_delta):
    var combatant_died: bool = false

    for grabbable in objects.get_children():
        if grabbable is Grabbable and grabbable.global_position.y < self.global_position.y -2:
            grabbable.linear_velocity = Vector3.ZERO
            grabbable.angular_velocity = Vector3.ZERO
            grabbable.position = Vector3(randf_range(-5, 5), 3, randf_range(-5, 5))
    
    for combatant in combatants.get_children():
        if combatant is Combatant and combatant.physical_bone_body.global_position.y < self.global_position.y-1:
            combatant.set_physics_process(false)
            if combatant.ai_controller:
                combatant.ai_controller.reward -= 1
                combatant.ai_controller.reset()
            combatant.physical_skel.physical_bones_stop_simulation()
            combatant.active_arm_left = false
            combatant.active_arm_right = false
            combatant.grabbing_arm_left = false
            combatant.grabbing_arm_right = false
            remaining_combatants.erase(combatant)
            combatant_died = true
    if combatant_died:
        for rem_combatant: Combatant in remaining_combatants:
            if rem_combatant.ai_controller:
                rem_combatant.ai_controller.reward += 0.3

        if remaining_combatants.size() <= 1:
            if remaining_combatants.size() == 1:
                var winner: Combatant = remaining_combatants[0]
                if winner and winner.ai_controller:
                    winner.ai_controller.reward += 0.5
            restart_match()
                
    
