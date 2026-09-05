extends SceneTree
## Compile check for `make check`.
##
## Loads every GDScript and scene under DIRS and forces a script reload, so parse/type
## errors anywhere in the project fail the build — not just in scripts the main scene
## happens to reach. Runs headless with autoloads available:
##   godot --headless --path . -s scripts/check_scripts.gd
## (Godot's own `--check-only` is per-file and currently breaks on autoloads.)

const DIRS: Array[String] = ["res://game", "res://tests"]
const EXTENSIONS: Array[String] = ["gd", "tscn", "tres"]


## Runs on the first frame (not `_init`) so that autoloads are already registered.
func _process(_delta: float) -> bool:
	var paths: Array[String] = []
	for dir in DIRS:
		_collect(dir, paths)

	var failures := 0
	for path in paths:
		if not _check(path):
			failures += 1

	if failures > 0:
		printerr(
			"CHECK FAILED: %d of %d resources failed to load/compile" % [failures, paths.size()]
		)
		quit(1)
	else:
		print("check: %d resources loaded and compiled OK" % paths.size())
		quit(0)
	return true


func _check(path: String) -> bool:
	var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
	if resource == null:
		printerr("CHECK FAILED: could not load %s" % path)
		return false
	if resource is GDScript:
		var script := resource as GDScript
		var error := script.reload(true)
		if error != OK:
			printerr("CHECK FAILED: %s (reload error %d)" % [path, error])
			return false
	return true


func _collect(dir_path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		printerr("CHECK FAILED: cannot open %s" % dir_path)
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var path := dir_path.path_join(name)
		if dir.current_is_dir():
			if not name.begins_with("."):
				_collect(path, out)
		elif name.get_extension() in EXTENSIONS:
			out.append(path)
		name = dir.get_next()
	dir.list_dir_end()
	out.sort()
