@tool
extends Node

@export var target: MeshInstance3D
@export_file("*.mesh", "*.res", "*.tres") var output_path := "res://assets/maps/map_baked.mesh"
@export var bake_and_swap_now: bool = false : set = _bake_and_swap

func _bake_and_swap(v: bool) -> void:
	if !Engine.is_editor_hint() or !v:
		return
	bake_and_swap_now = false

	# 0) Sanity checks
	if target == null:
		push_error("Bake: 'target' is not set."); return
	if target.mesh == null:
		push_error("Bake: target.mesh is null (did the generator build yet?)."); return

	# 1) Ensure directory exists
	var dir := output_path.get_base_dir()  # e.g. res://assets/maps
	var da := DirAccess.open("res://")
	if da == null:
		push_error("Bake: can't open project root."); return
	var mk_err := da.make_dir_recursive(dir)
	if mk_err != OK and mk_err != ERR_ALREADY_EXISTS:
		push_error("Bake: make_dir_recursive failed for %s (%s)" % [dir, error_string(mk_err)])
		return

	# 2) Save mesh (correct arg order in Godot 4.5)
	var flags := ResourceSaver.FLAG_COMPRESS
	var err := ResourceSaver.save(target.mesh, output_path, flags)
	print("Bake: ResourceSaver.save -> %s" % error_string(err))
	if err != OK:
		push_error("Bake: save failed (%s) path=%s" % [error_string(err), output_path]); return

	# 3) Reload baked mesh and assign it
	var baked: Mesh = load(output_path)
	if baked == null:
		push_error("Bake: failed to reload baked mesh at %s" % output_path); return
	target.mesh = baked

	# 4) Detach heavy generator if present
	if target.get_script() != null:
		if target.has_method("_do_clear"):
			target.call("_do_clear", true)
		target.set_script(null)

	print("Bake: wrote and swapped -> %s" % output_path)
