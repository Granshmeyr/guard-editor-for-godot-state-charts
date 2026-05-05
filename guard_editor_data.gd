@tool
class_name GuardEditorData
extends Node

const _ADDON_FOLDER := "res://addons/guard-editor-for-godot-state-charts"
const _GODOT_STATE_CHARTS_FOLDER := "res://addons/godot_state_charts"
const _DATA_PATH := "%s/data.json" % _ADDON_FOLDER
const DEFAULT_COLOR: Color = Color("#654e00")
const ARROW_COLOR: Color = Color("#FFFFFFFF")
const ERROR_BG_COLOR: Color = Color.DARK_RED
const ERROR_COLOR: Color = Color("#FFFFFFD0")
const EMPTY_ARRAY_SLOT_LABEL: String = "<--- EMPTY ARRAY SLOT --->"

static var _did_reimport: bool
static var _godot_state_charts_files: PackedStringArray = PackedStringArray([
	"%s/all_of_guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/animation_player_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/animation_tree_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/any_of_guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/atomic_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/compound_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/expression_guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/history_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/not_guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/parallel_state.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/state_chart.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/state_is_active_guard.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/toggle_sidebar.svg" % _GODOT_STATE_CHARTS_FOLDER,
	"%s/transition.svg" % _GODOT_STATE_CHARTS_FOLDER,
])
static var _addon_files := PackedStringArray([
	"%s/all_of_guard_orange.svg" % _ADDON_FOLDER,
	"%s/any_of_guard_orange.svg" % _ADDON_FOLDER,
	"%s/atomic_state_green.svg" % _ADDON_FOLDER,
	"%s/chevron_down.svg" % _ADDON_FOLDER,
	"%s/chevron_up.svg" % _ADDON_FOLDER,
	"%s/compound_state_green.svg" % _ADDON_FOLDER,
	"%s/expression_guard_blue.svg" % _ADDON_FOLDER,
	"%s/expression_guard_orange.svg" % _ADDON_FOLDER,
	"%s/history_state_green.svg" % _ADDON_FOLDER,
	"%s/not_all_of_guard_orange.svg" % _ADDON_FOLDER,
	"%s/not_any_of_guard_orange.svg" % _ADDON_FOLDER,
	"%s/not_atomic_state_green.svg" % _ADDON_FOLDER,
	"%s/not_compound_state_green.svg" % _ADDON_FOLDER,
	"%s/not_expression_guard_blue.svg" % _ADDON_FOLDER,
	"%s/not_history_state_green.svg" % _ADDON_FOLDER,
	"%s/not_parallel_state_green.svg" % _ADDON_FOLDER,
	"%s/parallel_state_green.svg" % _ADDON_FOLDER,
	"%s/state_is_active_guard_orange.svg" % _ADDON_FOLDER,
])
static var _all_files: PackedStringArray = \
	_godot_state_charts_files + _addon_files


static func _static_init() -> void:
	var data: Variant = Util.load_json(_DATA_PATH)
	var editor_scale: float = EditorInterface.get_editor_scale()
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()

	if (
		not _did_reimport
		and (
			data == null
			or data.previous_editor_scale != editor_scale
		)
	):
		fs.filesystem_changed.connect(_do_reimport, CONNECT_ONE_SHOT)


static func _do_reimport() -> void:
	var editor_scale: float = EditorInterface.get_editor_scale()
	var new_data := {"previous_editor_scale": editor_scale}
	var fs: EditorFileSystem = EditorInterface.get_resource_filesystem()

	Util.save_json(_DATA_PATH, new_data)
	fs.reimport_files(_all_files)

	_did_reimport = true


class Setting:
	extends RefCounted

	class Section:
		extends RefCounted

		static var root := "guard_editor"
		static var settings := "%s/settings" % root
		static var separation_lines := "%s/separation_lines" % settings
		static var indent_guides := "%s/indent_guides" % settings
		static var indent_margin := "%s/indent_margin" % settings
		static var general := "%s/general" % settings
	class Key:
		extends RefCounted

		static var draw_separation_lines := \
			"%s/draw_separation_lines" % Section.separation_lines
		static var separation_line_color := \
			"%s/separation_line_color" % Section.separation_lines
		static var draw_indent_guides := \
			"%s/draw_indent_guides" % Section.indent_guides
		static var indent_guide_color := \
			"%s/indent_guide_color" % Section.indent_guides
		static var indent_guide_width := \
			"%s/indent_guide_width" % Section.indent_guides
		static var indent_margin_size := \
			"%s/indent_margin_size" % Section.indent_margin
		static var editor_height := \
			"%s/editor_height" % Section.general
		static var hide_original_guard_property := \
			"%s/hide_original_guard_property" % Section.general
		static var highlight_errors := \
			"%s/highlight_errors" % Section.general
		static var human_readable_node_path := \
			"%s/human_readable_node_path" % Section.general
		static var between_line_padding := \
			"%s/between_line_padding" % Section.general
		static var icon_to_label_padding := \
			"%s/icon_to_label_padding" % Section.general


class Icon:
	extends RefCounted

	static var all_of_guard_orange: Texture2D = \
		load("%s/all_of_guard_orange.svg" % _ADDON_FOLDER)
	static var any_of_guard_orange: Texture2D = \
		load("%s/any_of_guard_orange.svg" % _ADDON_FOLDER)
	static var arrow_up: Texture2D = \
		load("%s/chevron_up.svg" % _ADDON_FOLDER)
	static var arrow_down: Texture2D = \
		load("%s/chevron_down.svg" % _ADDON_FOLDER)
	static var atomic_state_green: Texture2D = \
		load("%s/atomic_state_green.svg" % _ADDON_FOLDER)
	static var compound_state_green: Texture2D = \
		load("%s/compound_state_green.svg" % _ADDON_FOLDER)
	static var history_state_green: Texture2D = \
		load("%s/history_state_green.svg" % _ADDON_FOLDER)
	static var expression_guard_blue: Texture2D = \
		load("%s/expression_guard_blue.svg" % _ADDON_FOLDER)
	static var not_all_of_guard_orange: Texture2D = \
		load("%s/not_all_of_guard_orange.svg" % _ADDON_FOLDER)
	static var not_any_of_guard_orange: Texture2D = \
		load("%s/not_any_of_guard_orange.svg" % _ADDON_FOLDER)
	static var not_atomic_state_green: Texture2D = \
		load("%s/not_atomic_state_green.svg" % _ADDON_FOLDER)
	static var not_compound_state_green: Texture2D = \
		load("%s/not_compound_state_green.svg" % _ADDON_FOLDER)
	static var not_expression_guard_blue: Texture2D = \
		load("%s/not_expression_guard_blue.svg" % _ADDON_FOLDER)
	static var not_history_state_green: Texture2D = \
		load("%s/not_history_state_green.svg" % _ADDON_FOLDER)
	static var not_parallel_state_green: Texture2D = \
		load("%s/not_parallel_state_green.svg" % _ADDON_FOLDER)
	static var parallel_state_green: Texture2D = \
		load("%s/parallel_state_green.svg" % _ADDON_FOLDER)
	static var popup_all_of_guard_orange: Texture2D = \
		load("%s/popup_all_of_guard_orange.svg" % _ADDON_FOLDER)
	static var popup_any_of_guard_orange: Texture2D = \
		load("%s/popup_any_of_guard_orange.svg" % _ADDON_FOLDER)
	static var popup_expression_guard_orange: Texture2D = \
		load("%s/popup_expression_guard_orange.svg" % _ADDON_FOLDER)
	static var popup_state_is_active_guard_orange: Texture2D = \
		load("%s/popup_state_is_active_guard_orange.svg" % _ADDON_FOLDER)
	static var popup_not_icon: Texture2D = \
		load("%s/popup_not_icon.svg" % _ADDON_FOLDER)
	static var popup_delete_icon: Texture2D

	static func _static_init() -> void:
		if (
			EditorInterface == null
			or not EditorInterface.has_method("get_editor_theme")
		):
			return

		var theme: Theme = EditorInterface.get_editor_theme()

		popup_delete_icon = theme.get_icon("Remove", "EditorIcons")


class Name:
	extends RefCounted

	static var transition := &"Transition"
	static var all_of_guard := &"AllOfGuard"
	static var any_of_guard := &"AnyOfGuard"
	static var expression_guard := &"ExpressionGuard"
	static var not_guard := &"NotGuard"
	static var state_is_active_guard := &"StateIsActiveGuard"
	static var atomic_state := &"AtomicState"
	static var compound_state := &"CompoundState"
	static var history_state := &"HistoryState"
	static var parallel_state := &"ParallelState"


class Util:
	extends RefCounted

	static func save_json(
		path: String,
		data: Variant,
		indent: int = 2,
		indent_char: String = " ",
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


