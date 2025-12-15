extends Node3D
class_name DismembermentController

@export var skeleton: Skeleton3D
@export var gore_chunk_scene: PackedScene    # CC0 limb/gore mesh
@export var blood_fx_scene: PackedScene      # CC0 blood particle scene

func cut_limb(bone_name: String, impulse: Vector3) -> void:
    if not skeleton:
        push_warning("DismembermentController: skeleton not assigned.")
        return

    var idx := skeleton.find_bone(bone_name)
    if idx == -1:
        push_warning("DismembermentController: bone '%s' not found." % bone_name)
        return

    var pose := skeleton.get_bone_global_pose(idx)

    # Collapse bone influence
    skeleton.set_bone_global_pose_override(
        idx,
        pose.scaled(Vector3(0.01, 0.01, 0.01)),
        1.0,
        true
    )

    # Spawn gore chunk
    if gore_chunk_scene:
        var chunk := gore_chunk_scene.instantiate()
        get_tree().current_scene.add_child(chunk)
        chunk.global_transform.origin = pose.origin
        if chunk is RigidBody3D:
            chunk.apply_impulse(Vector3.ZERO, impulse)

    # Spawn local blood spray
    if blood_fx_scene:
        var blood := blood_fx_scene.instantiate()
        add_child(blood)
        blood.global_transform.origin = pose.origin
