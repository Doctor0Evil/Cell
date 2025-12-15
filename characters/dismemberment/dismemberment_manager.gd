extends Node3D
class_name DismembermentManager

@export var skeleton: Skeleton3D
@export var blood_fx_scene: PackedScene          # CC0 blood particle / mesh chunk
@export var gore_material: Material              # CC0 blood / flesh material
@export var detach_rigid_chunk_scene: PackedScene # optional full limb prefab

func dismember_bone(bone_name: String, impulse: Vector3 = Vector3.ZERO) -> void:
    if skeleton == null:
        push_warning("DismembermentManager: skeleton not assigned.")
        return

    var bone_idx := skeleton.find_bone(bone_name)
    if bone_idx == -1:
        push_warning("DismembermentManager: bone '%s' not found." % bone_name)
        return

    var bone_pose := skeleton.get_bone_global_pose(bone_idx)

    # Visually collapse the bone influence (simplest non-destructive dismemberment)
    skeleton.set_bone_global_pose_override(
        bone_idx,
        bone_pose.scaled(Vector3(0.01, 0.01, 0.01)),
        1.0,
        true
    )

    # Spawn local blood FX at sever point
    if blood_fx_scene:
        var blood_fx := blood_fx_scene.instantiate()
        add_child(blood_fx)
        blood_fx.global_transform.origin = bone_pose.origin

    # Spawn a rigid "chunk" limb if available
    if detach_rigid_chunk_scene:
        var chunk := detach_rigid_chunk_scene.instantiate()
        get_tree().current_scene.add_child(chunk)
        chunk.global_transform.origin = bone_pose.origin
        if chunk is RigidBody3D:
            chunk.apply_impulse(Vector3.ZERO, impulse)

    # Apply gore material to any matching decal meshes
    for child in get_children():
        if child is MeshInstance3D and child.name.begins_with(bone_name + "_DECAL"):
            child.set_surface_override_material(0, gore_material)
