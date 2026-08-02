class_name EnvLoader
extends RefCounted
## 简易 .env 解析器。按路径顺序加载，后加载的键覆盖先加载的。

static func load_files(paths: PackedStringArray) -> Dictionary:
	var values := {}
	for path in paths:
		if not FileAccess.file_exists(path):
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			push_warning("[EnvLoader] 无法打开: %s" % path)
			continue
		_merge_into(values, _parse(file.get_as_text()))
		print("[EnvLoader] 已加载: %s" % path)
	return values

static func _parse(text: String) -> Dictionary:
	var values := {}
	for raw_line in text.split("\n"):
		var line := raw_line.strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		if line.begins_with("export "):
			line = line.substr(7).strip_edges()
		var eq := line.find("=")
		if eq <= 0:
			continue
		var key := line.substr(0, eq).strip_edges()
		var value := line.substr(eq + 1).strip_edges()
		if (value.begins_with("\"") and value.ends_with("\"")) \
			or (value.begins_with("'") and value.ends_with("'")):
			value = value.substr(1, value.length() - 2)
		values[key] = value
	return values

static func _merge_into(target: Dictionary, source: Dictionary) -> void:
	for key in source:
		target[key] = source[key]
