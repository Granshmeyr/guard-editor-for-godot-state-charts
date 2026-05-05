@tool
class_name GuardEditorData
extends Node

const DEFAULT_COLOR: Color = Color("#654e00")
const ARROW_COLOR: Color = Color("#FFFFFFFF")
const ERROR_BG_COLOR: Color = Color.DARK_RED
const ERROR_COLOR: Color = Color("#FFFFFFD0")
const EMPTY_ARRAY_SLOT_LABEL: String = "<--- EMPTY ARRAY SLOT --->"

static var _did_reimport: bool
static var _godot_state_charts_files: PackedStringArray = PackedStringArray([
	"res://addons/godot_state_charts/all_of_guard.svg",
	"res://addons/godot_state_charts/animation_player_state.svg",
	"res://addons/godot_state_charts/animation_tree_state.svg",
	"res://addons/godot_state_charts/any_of_guard.svg",
	"res://addons/godot_state_charts/atomic_state.svg",
	"res://addons/godot_state_charts/compound_state.svg",
	"res://addons/godot_state_charts/expression_guard.svg",
	"res://addons/godot_state_charts/guard.svg",
	"res://addons/godot_state_charts/history_state.svg",
	"res://addons/godot_state_charts/not_guard.svg",
	"res://addons/godot_state_charts/parallel_state.svg",
	"res://addons/godot_state_charts/state_chart.svg",
	"res://addons/godot_state_charts/state_is_active_guard.svg",
	"res://addons/godot_state_charts/toggle_sidebar.svg",
	"res://addons/godot_state_charts/transition.svg",
])


static func _static_init() -> void:
	var data: Variant = Util.load_json(_get_data_path())
	var editor_scale: float = EditorInterface.get_editor_scale()
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()

	if not _did_reimport and (data == null or data.previous_editor_scale != editor_scale):
		fs.filesystem_changed.connect(_do_reimport, CONNECT_ONE_SHOT)


static func _do_reimport() -> void:
	var editor_scale: float = EditorInterface.get_editor_scale()
	var new_data := {"previous_editor_scale": editor_scale}
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	var all_files: PackedStringArray = \
		_godot_state_charts_files + _get_files()

	Util.save_json(_get_data_path(), new_data)
	fs.reimport_files(all_files)

	_did_reimport = true


class Setting:
	extends RefCounted

	class Section:
		extends RefCounted

		static var root: String
		static var settings: String
		static var separation_lines: String
		static var indent_guides: String
		static var indent_margin: String
		static var general: String

		static func _static_init() -> void:
			root = "guard_editor"
			settings = "%s/settings" % root
			separation_lines = "%s/separation_lines" % settings
			indent_guides = "%s/indent_guides" % settings
			indent_margin = "%s/indent_margin" % settings
			general = "%s/general" % settings

	class Key:
		extends RefCounted

		# separation lines
		static var draw_separation_lines: String
		static var separation_line_color: String
		# indent guides
		static var draw_indent_guides: String
		static var indent_guide_color: String
		static var indent_guide_width: String
		static var indent_margin_size: String
		# general
		static var editor_height: String
		static var hide_original_guard_property: String
		static var highlight_errors: String
		static var human_readable_node_path: String
		static var between_line_padding: String
		static var icon_to_label_padding: String

		static func _static_init() -> void:
			draw_separation_lines = "%s/draw_separation_lines" % Section.separation_lines
			separation_line_color = "%s/separation_line_color" % Section.separation_lines
			draw_indent_guides = "%s/draw_indent_guides" % Section.indent_guides
			indent_guide_color = "%s/indent_guide_color" % Section.indent_guides
			indent_guide_width = "%s/indent_guide_width" % Section.indent_guides
			indent_margin_size = "%s/indent_margin_size" % Section.indent_margin
			editor_height = "%s/editor_height" % Section.general
			hide_original_guard_property = "%s/hide_original_guard_property" % Section.general
			highlight_errors = "%s/highlight_errors" % Section.general
			human_readable_node_path = "%s/human_readable_node_path" % Section.general
			between_line_padding = "%s/between_line_padding" % Section.general
			icon_to_label_padding = "%s/icon_to_label_padding" % Section.general


class Icon:
	extends RefCounted

	# BEGIN custom
	static var all_of_guard_orange: Texture2D
	static var any_of_guard_orange: Texture2D
	static var arrow_up: Texture2D
	static var arrow_down: Texture2D
	static var atomic_state_green: Texture2D
	static var compound_state_green: Texture2D
	static var history_state_green: Texture2D
	static var expression_guard_blue: Texture2D
	static var not_all_of_guard_orange: Texture2D
	static var not_any_of_guard_orange: Texture2D
	static var not_atomic_state_green: Texture2D
	static var not_compound_state_green: Texture2D
	static var not_expression_guard_blue: Texture2D
	static var not_history_state_green: Texture2D
	static var not_parallel_state_green: Texture2D
	static var parallel_state_green: Texture2D
	static var popup_all_of_guard_orange: Texture2D
	static var popup_any_of_guard_orange: Texture2D
	static var popup_expression_guard_orange: Texture2D
	static var popup_state_is_active_guard_orange: Texture2D
	static var popup_not_icon: Texture2D
	static var popup_delete_icon: Texture2D
	# END custom

	static func _static_init() -> void:
		if (
			EditorInterface == null
			or not EditorInterface.has_method("get_editor_theme")
		):
			return

		var theme: Theme = EditorInterface.get_editor_theme()
		var folder: String = GuardEditorData._get_folder()

		# BEGIN custom
		all_of_guard_orange = load(
			"res://addons/%s/all_of_guard_orange.svg" % folder,
		)
		any_of_guard_orange = load(
			"res://addons/%s/any_of_guard_orange.svg" % folder,
		)
		arrow_up = load(
			"res://addons/%s/chevron_up.svg" % folder,
		)
		arrow_down = load(
			"res://addons/%s/chevron_down.svg" % folder,
		)
		atomic_state_green = load(
			"res://addons/%s/atomic_state_green.svg" % folder,
		)
		compound_state_green = load(
			"res://addons/%s/compound_state_green.svg" % folder,
		)
		history_state_green = load(
			"res://addons/%s/history_state_green.svg" % folder,
		)
		expression_guard_blue = load(
			"res://addons/%s/expression_guard_blue.svg" % folder,
		)
		not_all_of_guard_orange = load(
			"res://addons/%s/not_all_of_guard_orange.svg" % folder,
		)
		not_any_of_guard_orange = load(
			"res://addons/%s/not_any_of_guard_orange.svg" % folder,
		)
		not_atomic_state_green = load(
			"res://addons/%s/not_atomic_state_green.svg" % folder,
		)
		not_compound_state_green = load(
			"res://addons/%s/not_compound_state_green.svg" % folder,
		)
		not_expression_guard_blue = load(
			"res://addons/%s/not_expression_guard_blue.svg" % folder,
		)
		not_history_state_green = load(
			"res://addons/%s/not_history_state_green.svg" % folder,
		)
		not_parallel_state_green = load(
			"res://addons/%s/not_parallel_state_green.svg" % folder,
		)
		parallel_state_green = load(
			"res://addons/%s/parallel_state_green.svg" % folder,
		)
		popup_all_of_guard_orange = load(
			"res://addons/%s/popup_all_of_guard_orange.svg" % folder,
		)
		popup_any_of_guard_orange = load(
			"res://addons/%s/popup_any_of_guard_orange.svg" % folder,
		)
		popup_expression_guard_orange = load(
			"res://addons/%s/popup_expression_guard_orange.svg" % folder,
		)
		popup_state_is_active_guard_orange = load(
			"res://addons/%s/popup_state_is_active_guard_orange.svg" % folder,
		)
		popup_not_icon = load(
			"res://addons/%s/popup_not_icon.svg" % folder,
		)
		popup_delete_icon = theme.get_icon("Remove", "EditorIcons")
		# END custom


class Name:
	extends RefCounted

	# transition
	static var transition: StringName
	# guard
	static var all_of_guard: StringName
	static var any_of_guard: StringName
	static var expression_guard: StringName
	static var not_guard: StringName
	static var state_is_active_guard: StringName
	# state
	static var atomic_state: StringName
	static var compound_state: StringName
	static var history_state: StringName
	static var parallel_state: StringName

	static func _static_init() -> void:
		# transition
		transition = StringName("Transition")
		# guard
		all_of_guard = StringName("AllOfGuard")
		any_of_guard = StringName("AnyOfGuard")
		expression_guard = StringName("ExpressionGuard")
		not_guard = StringName("NotGuard")
		state_is_active_guard = StringName("StateIsActiveGuard")
		# state
		atomic_state = StringName("AtomicState")
		compound_state = StringName("CompoundState")
		history_state = StringName("HistoryState")
		parallel_state = StringName("ParallelState")


class Util:
	extends RefCounted

	static func save_json(
		path: String, data: Variant, indent: int = 2, indent_char: String = " "
	) -> bool:
		var dir: String = path.get_base_dir()
		var dir_abs: String = ProjectSettings.globalize_path(dir)
		var exists: bool = DirAccess.dir_exists_absolute(dir_abs)

		if not exists:
			var created: bool = ensure_dir(dir)

			if not created:
				push_error("Could not create directory: %s" % dir)

				return false

		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)

		if file == null:
			var open_err: int = FileAccess.get_open_error()

			push_error("File open failed for %s (err %d)" % [path, open_err])

			return false

		var use_tab: bool = indent_char == "\t"
		var effective_indent: int = indent

		if use_tab and indent < 1:
			effective_indent = 1

		var json_text: String = ""

		if use_tab:
			json_text = JSON.stringify(data, "\t", effective_indent)
		else:
			json_text = JSON.stringify(data, " ", indent)

		file.store_string(json_text)
		file.close()

		return true

	static func load_json(path: String) -> Variant:
		var exists: bool = FileAccess.file_exists(path)

		if not exists:
			return null

		var file: FileAccess = FileAccess.open(path, FileAccess.READ)

		if file == null:
			var open_err: int = FileAccess.get_open_error()
			push_error("Open failed for %s (err %d)" % [path, open_err])
			return null

		var text: String = file.get_as_text()

		file.close()

		var parser: JSON = JSON.new()
		var parse_err: int = parser.parse(text)

		if parse_err != OK:
			var line: int = parser.get_error_line()
			var msg: String = parser.get_error_message()

			push_error("JSON parse error at line %d: %s" % [line, msg])

			return null

		var result: Variant = parser.data

		return result

	static func ensure_dir(path: String) -> bool:
		var abs_str: String = ProjectSettings.globalize_path(path)
		var exists: bool = DirAccess.dir_exists_absolute(abs_str)

		if exists:
			return true

		var parent: String = path.get_base_dir()

		if parent != "" and parent != path:
			var parent_ok: bool = ensure_dir(parent)

			if not parent_ok:
				return false

		var base_to_open: String = "res://"

		if parent != "":
			base_to_open = parent

		var d: DirAccess = DirAccess.open(base_to_open)

		if d == null:
			return false

		var mk_err: int = d.make_dir(path)

		return mk_err == OK


static func _get_data_path() -> String:
	var folder: String = _get_folder()
	var data_path: String = "res://addons/%s/data.json" % folder

	return data_path


static func _get_files() -> PackedStringArray:
	var folder: String = _get_folder()
	var files := PackedStringArray([
		"res://addons/%s/all_of_guard_orange.svg" % folder,
		"res://addons/%s/any_of_guard_orange.svg" % folder,
		"res://addons/%s/atomic_state_green.svg" % folder,
		"res://addons/%s/chevron_down.svg" % folder,
		"res://addons/%s/chevron_up.svg" % folder,
		"res://addons/%s/compound_state_green.svg" % folder,
		"res://addons/%s/expression_guard_blue.svg" % folder,
		"res://addons/%s/expression_guard_orange.svg" % folder,
		"res://addons/%s/history_state_green.svg" % folder,
		"res://addons/%s/not_all_of_guard_orange.svg" % folder,
		"res://addons/%s/not_any_of_guard_orange.svg" % folder,
		"res://addons/%s/not_atomic_state_green.svg" % folder,
		"res://addons/%s/not_compound_state_green.svg" % folder,
		"res://addons/%s/not_expression_guard_blue.svg" % folder,
		"res://addons/%s/not_history_state_green.svg" % folder,
		"res://addons/%s/not_parallel_state_green.svg" % folder,
		"res://addons/%s/parallel_state_green.svg" % folder,
		"res://addons/%s/state_is_active_guard_orange.svg" % folder,
	])

	return files


static func _get_folder() -> String:
	const EXPORT_FOLDER := "guard_editor_for_godot_state_charts"
	const CLONE_FOLDER := "guard-editor-for-godot-state-charts"

	var folder: String

	if FileAccess.file_exists(
		"res://addons/%s/all_of_guard_orange.svg" % EXPORT_FOLDER,
	):
		folder = EXPORT_FOLDER
	elif FileAccess.file_exists(
		"res://addons/%s/all_of_guard_orange.svg" % CLONE_FOLDER,
	):
		folder = CLONE_FOLDER

	return folder