@tool
class_name GuardEditorPlugin
extends EditorPlugin

var _inspector_plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	_inspector_plugin = GuardEditorInspectorPlugin.new()
	_ensure_editor_settings()
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(_inspector_plugin)


func _ensure_editor_settings() -> void:
	var es: EditorSettings = EditorInterface.get_editor_settings()
	var editor_scale: float = EditorInterface.get_editor_scale()

	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.draw_separation_lines,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		"Determines whether lines are drawn between rows.",
		false,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.separation_line_color,
		TYPE_COLOR,
		PROPERTY_HINT_COLOR_NO_ALPHA,
		"Determines the color of separation lines.",
		GuardEditorData.DEFAULT_COLOR,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.draw_indent_guides,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		"Determines whether indent guides are drawn.",
		true,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.indent_guide_color,
		TYPE_COLOR,
		PROPERTY_HINT_COLOR_NO_ALPHA,
		"Determines the color of indent guides.",
		GuardEditorData.DEFAULT_COLOR,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.indent_guide_width,
		TYPE_INT,
		PROPERTY_HINT_NONE,
		"Determines the width of indent guides.",
		maxi(1, floori(1 * editor_scale)),
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.indent_margin_size,
		TYPE_INT,
		PROPERTY_HINT_NONE,
		"Determines the size of the indent margin.",
		floori(15 * editor_scale),
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.editor_height,
		TYPE_INT,
		PROPERTY_HINT_NONE,
		"Determines the height of the added editor control.",
		floori(250 * editor_scale),
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.hide_original_guard_property,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		"Determines if the original Guard property is shown under Transition in the Inspector.",
		true,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.highlight_errors,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		"Determines if configuration errors are highlighted in a red bg color.",
		true,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.human_readable_node_path,
		TYPE_BOOL,
		PROPERTY_HINT_NONE,
		"Determines if StateIsActive set State displays as a full NodePath or just its name.",
		true,
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.between_line_padding,
		TYPE_INT,
		PROPERTY_HINT_NONE,
		"Determines the vertical padding between lines.",
		floori(2 * editor_scale),
	)
	_add_setting_if_missing(
		es,
		GuardEditorData.Setting.Key.icon_to_label_padding,
		TYPE_INT,
		PROPERTY_HINT_NONE,
		"Determines the padding between the guard icon and the label text.",
		floori(6 * editor_scale),
	)


func _add_setting_if_missing(
	es: EditorSettings,
	key: String,
	type: Variant.Type,
	hint: int,
	hint_string: String,
	default_value: Variant
) -> void:
	if not es.has_setting(key):
		es.set_setting(key, default_value)

	es.set_initial_value(key, default_value, false)
	es.add_property_info({"name": key, "type": type, "hint": hint, "hint_string": hint_string})


class Util:
	extends RefCounted

	static func get_corresponding_state_icon(state: StateChartState) -> Texture2D:
		var icon: Texture2D

		if state is AtomicState:
			icon = GuardEditorData.Icon.atomic_state_green
		elif state is CompoundState:
			icon = GuardEditorData.Icon.compound_state_green
		elif state is HistoryState:
			icon = GuardEditorData.Icon.history_state_green
		elif state is ParallelState:
			icon = GuardEditorData.Icon.parallel_state_green

		return icon

	static func get_ancestor_state_chart(node: Node) -> Node:
		if not is_instance_valid(node):
			return null

		var parent: Node = node.get_parent()

		if not is_instance_valid(parent):
			return null

		if parent is StateChart:
			return parent

		return get_ancestor_state_chart(parent)

	static func move_array_item_forward(index: int, array: Array) -> void:
		if index < array.size() - 1:
			var tmp: Variant = array[index]

			array[index] = array[index + 1]
			array[index + 1] = tmp

	static func move_array_item_backward(index: int, array: Array) -> void:
		if index > 0:
			var tmp: Variant = array[index]

			array[index] = array[index - 1]
			array[index - 1] = tmp

	static func get_inverted_icon(guard: Guard, transition: Transition) -> Texture2D:
		var icon: Texture2D

		if guard is NotGuard:
			var inverted_guard: Guard = guard.get("guard")

			if inverted_guard is AllOfGuard:
				icon = GuardEditorData.Icon.all_of_guard_orange
			elif inverted_guard is AnyOfGuard:
				icon = GuardEditorData.Icon.any_of_guard_orange
			elif inverted_guard is ExpressionGuard:
				icon = GuardEditorData.Icon.expression_guard_blue
			elif inverted_guard is StateIsActiveGuard:
				var state_path: NodePath = inverted_guard.get("state")
				var state: StateChartState

				if transition.has_node(state_path):
					state = transition.get_node(state_path)

				if state == null or state is AtomicState:
					icon = GuardEditorData.Icon.atomic_state_green
				if state is CompoundState:
					icon = GuardEditorData.Icon.compound_state_green
				if state is HistoryState:
					icon = GuardEditorData.Icon.history_state_green
				if state is ParallelState:
					icon = GuardEditorData.Icon.parallel_state_green
		elif guard is Guard:
			if guard is AllOfGuard:
				icon = GuardEditorData.Icon.not_all_of_guard_orange
			elif guard is AnyOfGuard:
				icon = GuardEditorData.Icon.not_any_of_guard_orange
			elif guard is ExpressionGuard:
				icon = GuardEditorData.Icon.not_expression_guard_blue
			elif guard is StateIsActiveGuard:
				var state_path: NodePath = guard.get("state")
				var state: StateChartState

				if transition.has_node(state_path):
					state = transition.get_node(state_path)

				if state == null or state is AtomicState:
					icon = GuardEditorData.Icon.not_atomic_state_green
				if state is CompoundState:
					icon = GuardEditorData.Icon.not_compound_state_green
				if state is HistoryState:
					icon = GuardEditorData.Icon.not_history_state_green
				if state is ParallelState:
					icon = GuardEditorData.Icon.not_parallel_state_green

		return icon
