class_name GuardEditorTree
extends Tree

enum PopupButton {
	ADD_ALL_OF_GUARD,
	ADD_ANY_OF_GUARD,
	ADD_EXPRESSION_GUARD,
	ADD_STATE_IS_ACTIVE_GUARD,
	DELETE,
	INVERT,
}

var transition: Transition
var state_chart: StateChart
var inspector_plugin: GuardEditorInspectorPlugin
var popup_id_deleted_item_map: Dictionary[int, TreeItem] = {}
var popup_id_button_map: Dictionary[int, PopupButton] = {}
var last_popup_clicked_tree_item: TreeItem


func _init(transition: Transition, inspector_plugin: GuardEditorInspectorPlugin) -> void:
	self.transition = transition
	self.inspector_plugin = inspector_plugin
	drop_mode_flags = DROP_MODE_ON_ITEM
	allow_rmb_select = true
	item_mouse_selected.connect(_on_self_item_mouse_selected)
	empty_clicked.connect(_on_self_empty_clicked)
	button_clicked.connect(_on_self_button_clicked)

	var es: EditorSettings = EditorInterface.get_editor_settings()

	# BEGIN icon_to_label_padding
	var icon_to_label_padding: int = es.get_setting(
		GuardEditorData.Setting.Key.icon_to_label_padding
	)

	add_theme_constant_override("h_separation", icon_to_label_padding)
	# END icon_to_label_padding

	# BEGIN between_lines_padding
	var between_lines_padding: int = es.get_setting(
		GuardEditorData.Setting.Key.between_line_padding
	)

	add_theme_constant_override("v_separation", between_lines_padding)
	# END between_lines_padding

	# BEGIN theme

	#     BEGIN separation lines
	var draw_separation_lines: bool = es.get_setting(
		GuardEditorData.Setting.Key.draw_separation_lines
	)
	var separation_line_color: Color = es.get_setting(
		GuardEditorData.Setting.Key.separation_line_color
	)

	add_theme_constant_override("draw_guides", draw_separation_lines)

	if not separation_line_color.is_equal_approx(GuardEditorData.DEFAULT_COLOR):
		add_theme_color_override("guide_color", separation_line_color)
	#     END separation lines

	#     BEGIN indent guides
	var draw_indent_guides: bool = es.get_setting(GuardEditorData.Setting.Key.draw_indent_guides)
	var indent_guide_color: Color = es.get_setting(GuardEditorData.Setting.Key.indent_guide_color)
	var indent_guide_width: int = es.get_setting(GuardEditorData.Setting.Key.indent_guide_width)

	add_theme_constant_override("draw_relationship_lines", draw_indent_guides)
	add_theme_constant_override("relationship_line_width", indent_guide_width)

	if not indent_guide_color.is_equal_approx(GuardEditorData.DEFAULT_COLOR):
		add_theme_color_override("relationship_line_color", indent_guide_color)
	#     END indent guides

	#     BEGIN indent margin
	var indent_margin_size: int = es.get_setting(GuardEditorData.Setting.Key.indent_margin_size)

	add_theme_constant_override("item_margin", indent_margin_size)
	#     END indent margin

	#     BEGIN editor height
	var editor_height: int = es.get_setting(GuardEditorData.Setting.Key.editor_height)

	custom_minimum_size = Vector2(1000, editor_height)
	#     END editor height

	#     BEGIN bg color
	var line_edit_style_box: StyleBoxFlat = get_theme_stylebox("normal", "TextEdit")

	add_theme_stylebox_override("panel", line_edit_style_box)
	#     END bg color

	hide_root = true
	# END theme


# gdlint: disable=max-returns


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false

	var p_data: Dictionary = data

	if p_data.get("type") != "nodes":
		return false

	var node_paths: Array = p_data.get("nodes")

	if node_paths.is_empty() or node_paths.size() > 1:
		return false

	var node: Node = get_node(node_paths[0])

	if not node is StateChartState:
		return false

	# at this point data contains a single state

	var item: TreeItem = get_item_at_position(at_position)

	if not is_instance_valid(item):
		return false

	var guard: Guard = Util.get_item_guard_ignoring_not(item)

	if not is_instance_valid(guard):
		return false

	if not guard is StateIsActiveGuard:
		return false

	# at this point we are dropping onto a StateIsActiveGuard

	return true


# gdlint: enable=max-returns


func _set_state_is_active_item_path(state_is_active_item: TreeItem, node_path: NodePath) -> void:
	var guard: Guard = Util.get_item_guard_ignoring_not(state_is_active_item)
	var state: StateChartState = get_node(node_path)
	var rel_state_path: NodePath = transition.get_path_to(state)
	var es: EditorSettings = EditorInterface.get_editor_settings()

	if not is_instance_valid(state_chart):
		state_chart = GuardEditorPlugin.Util.get_ancestor_state_chart(transition)

	var real_node_path: String = state_chart.get_path_to(state)
	var first_slash_i: int = real_node_path.find("/")
	var human_readable_node_path: String = (
		real_node_path if first_slash_i == -1 else real_node_path.substr(first_slash_i + 1)
	)

	guard.state = rel_state_path

	if es.get_setting(GuardEditorData.Setting.Key.human_readable_node_path):
		state_is_active_item.set_text(0, human_readable_node_path)
	else:
		state_is_active_item.set_text(0, state.name)

	var raw_guard: Guard = Util.get_item_guard(state_is_active_item)

	if raw_guard is NotGuard:
		state_is_active_item.set_icon(
			0, GuardEditorPlugin.Util.get_inverted_icon(guard, transition)
		)
	else:
		state_is_active_item.set_icon(0, GuardEditorPlugin.Util.get_corresponding_state_icon(state))

	state_is_active_item.clear_custom_color(0)
	state_is_active_item.clear_custom_bg_color(0)
	state_is_active_item.set_tooltip_text(0, human_readable_node_path)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var item: TreeItem = get_item_at_position(at_position)
	var state_path: NodePath = data.get("nodes")[0]

	_set_state_is_active_item_path(item, state_path)


# callbacks


func _on_popup_id_pressed(id: int) -> void:
	var pressed_button: PopupButton = popup_id_button_map.get(id)

	if pressed_button == PopupButton.DELETE:
		_popup_delete_behavior(last_popup_clicked_tree_item)
	elif (
		pressed_button == PopupButton.ADD_ALL_OF_GUARD
		or pressed_button == PopupButton.ADD_ANY_OF_GUARD
		or pressed_button == PopupButton.ADD_EXPRESSION_GUARD
		or pressed_button == PopupButton.ADD_STATE_IS_ACTIVE_GUARD
	):
		_popup_add_guard_behavior(last_popup_clicked_tree_item, pressed_button)
	elif pressed_button == PopupButton.INVERT:
		_popup_invert_behavior(last_popup_clicked_tree_item)


func _on_self_empty_clicked(click_position: Vector2, mouse_button_index: int) -> void:
	if is_instance_valid(transition.guard):
		return

	var popup_menu: PopupMenu = PopupMenu.new()
	var is_right: bool = mouse_button_index == MOUSE_BUTTON_RIGHT
	var showing_menu: bool

	if is_right:
		_append_state_additions_to_popup(popup_menu)

		showing_menu = true

	if showing_menu:
		add_child(popup_menu)
		popup_menu.add_theme_constant_override("separation", 0)
		popup_menu.id_pressed.connect(_on_popup_id_pressed)
		last_popup_clicked_tree_item = get_root()
		popup_menu.position = get_screen_position() + click_position
		popup_menu.reset_size()
		popup_menu.popup()


func _on_self_item_mouse_selected(mouse_position: Vector2, mouse_button_index: int) -> void:
	var item: TreeItem = get_item_at_position(mouse_position)

	if not is_instance_valid(item):
		return

	var parent_item: TreeItem = item.get_parent()
	var is_right: bool = mouse_button_index == MOUSE_BUTTON_RIGHT
	var is_left: bool = mouse_button_index == MOUSE_BUTTON_LEFT

	if is_right:
		var popup_menu: PopupMenu

		if item.has_meta("guard"):
			var guard: Guard = Util.get_item_guard_ignoring_not(item)

			popup_menu = PopupMenu.new()

			if guard is AllOfGuard:
				_append_state_additions_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_invert_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_delete_to_popup(popup_menu)
			elif guard is AnyOfGuard:
				_append_state_additions_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_invert_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_delete_to_popup(popup_menu)
			elif guard is ExpressionGuard:
				_append_invert_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_delete_to_popup(popup_menu)
			elif guard is StateIsActiveGuard:
				_append_invert_to_popup(popup_menu)
				_append_separator_to_popup(popup_menu)
				_append_delete_to_popup(popup_menu)
		elif is_instance_valid(parent_item):
			popup_menu = PopupMenu.new()
			_append_delete_to_popup(popup_menu)

		if is_instance_valid(popup_menu):
			add_child(popup_menu)
			popup_menu.add_theme_constant_override("separation", 0)
			popup_menu.id_pressed.connect(_on_popup_id_pressed)
			last_popup_clicked_tree_item = item
			popup_menu.position = get_screen_position() + mouse_position
			popup_menu.reset_size()
			popup_menu.popup()
	elif is_left:
		if item.has_meta("guard"):
			var guard: Guard = Util.get_item_guard_ignoring_not(item)

			if guard is StateIsActiveGuard:
				EditorInterface.popup_node_selector(
					func(tree_node_path: NodePath) -> void:
						if tree_node_path.is_empty():
							return

						var edited_scene_root: Node = EditorInterface.get_edited_scene_root()
						var state_node: Node = edited_scene_root.get_node(tree_node_path)
						var node_path: NodePath = state_node.get_path()

						_set_state_is_active_item_path(item, node_path),
					["StateChartState"]
				)


func _on_self_item_edited() -> void:
	var edited_item: TreeItem = get_edited()
	var guard: Guard = Util.get_item_guard_ignoring_not(edited_item)
	var new_expression: String = edited_item.get_text(0)
	var es: EditorSettings = EditorInterface.get_editor_settings()

	guard.expression = new_expression

	if (
		new_expression.strip_edges().is_empty()
		and es.get_setting(GuardEditorData.Setting.Key.highlight_errors)
	):
		Util.set_item_error_color(edited_item)
		edited_item.set_tooltip_text(0, "No expression set")
	else:
		edited_item.clear_custom_color(0)
		edited_item.clear_custom_bg_color(0)
		edited_item.set_tooltip_text(0, GuardEditorData.Name.expression_guard)


func _on_self_button_clicked(
	item: TreeItem, _column: int, id: int, mouse_button_index: int
) -> void:
	var is_left: bool = mouse_button_index == MOUSE_BUTTON_LEFT
	var is_move_up: bool = id == 1
	var parent_item: TreeItem = item.get_parent()
	var parent_guard: Guard = Util.get_item_guard_ignoring_not(parent_item)
	var parent_children: Array = parent_item.get_children()
	var item_i: int = parent_children.find(item)

	if is_left and is_move_up and item_i > 0:
		var prev_item: TreeItem = parent_item.get_child(item_i - 1)
		var guards: Array = parent_guard.get("guards")

		item.move_before(prev_item)
		GuardEditorPlugin.Util.move_array_item_backward(item_i, guards)
	elif is_left and not is_move_up and item_i < parent_children.size() - 1:
		var next_item: TreeItem = parent_item.get_child(item_i + 1)
		var guards: Array = parent_guard.get("guards")

		item.move_after(next_item)
		GuardEditorPlugin.Util.move_array_item_forward(item_i, guards)


# add guard to tree


func add_all_of_guard_item(parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	var es: EditorSettings = EditorInterface.get_editor_settings()

	item.set_text(0, "All")
	item.set_tooltip_text(0, GuardEditorData.Name.all_of_guard)
	item.set_icon(0, GuardEditorData.Icon.all_of_guard_orange)

	if es.get_setting(GuardEditorData.Setting.Key.highlight_errors):
		Util.set_item_error_color(item)

	return item


func add_any_of_guard_item(parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	var es: EditorSettings = EditorInterface.get_editor_settings()

	item.set_text(0, "Any")
	item.set_tooltip_text(0, GuardEditorData.Name.any_of_guard)
	item.set_icon(0, GuardEditorData.Icon.any_of_guard_orange)

	if es.get_setting(GuardEditorData.Setting.Key.highlight_errors):
		Util.set_item_error_color(item)

	return item


func add_expression_guard_item(
	parent_item: TreeItem, expression_guard: ExpressionGuard
) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	var expression: String = expression_guard.expression
	var es: EditorSettings = EditorInterface.get_editor_settings()

	item.set_text(0, expression_guard.expression)
	item.set_tooltip_text(0, GuardEditorData.Name.expression_guard)
	item.set_icon(0, GuardEditorData.Icon.expression_guard_blue)
	item.set_editable(0, true)
	item.set_edit_multiline(0, true)

	if (
		expression.strip_edges().is_empty()
		and es.get_setting(GuardEditorData.Setting.Key.highlight_errors)
	):
		Util.set_item_error_color(item)
		item.set_tooltip_text(0, "No expression set")

	if not item_edited.is_connected(_on_self_item_edited):
		item_edited.connect(_on_self_item_edited)

	return item


func add_state_is_active_guard_item(
	parent_item: TreeItem, state_is_active_guard: StateIsActiveGuard
) -> TreeItem:
	var item: TreeItem = create_item(parent_item)
	var state: StateChartState
	var state_path: NodePath = state_is_active_guard.state
	var es: EditorSettings = EditorInterface.get_editor_settings()

	if transition.has_node(state_path):
		state = transition.get_node(state_path)

	if not is_instance_valid(state_chart):
		state_chart = GuardEditorPlugin.Util.get_ancestor_state_chart(transition)

	var human_readable_node_path: String

	if is_instance_valid(state):
		var node_path: String = state_chart.get_path_to(state)
		var first_slash_i: int = node_path.find("/")

		human_readable_node_path = (
			node_path if first_slash_i == -1 else node_path.substr(first_slash_i + 1)
		)
		item.set_icon(0, GuardEditorPlugin.Util.get_corresponding_state_icon(state))

		if es.get_setting(GuardEditorData.Setting.Key.human_readable_node_path):
			item.set_text(0, human_readable_node_path)
		else:
			item.set_text(0, state.name)

		item.set_tooltip_text(0, human_readable_node_path)
	else:
		item.set_icon(0, GuardEditorData.Icon.atomic_state_green)

		if es.get_setting(GuardEditorData.Setting.Key.highlight_errors):
			Util.set_item_error_color(item)

		item.set_tooltip_text(0, "No state set")

	return item


# unique add to tree


func add_empty_slot_item(parent_item: TreeItem) -> TreeItem:
	var item: TreeItem = create_item(parent_item)

	item.set_text(0, GuardEditorData.EMPTY_ARRAY_SLOT_LABEL)

	Util.set_item_error_color(item)

	return item


func add_state_item(
	parent_item: TreeItem,
	state_chart: StateChart,
	transition: Transition,
	state_is_active_guard: StateIsActiveGuard
) -> TreeItem:
	var state: StateChartState
	var state_path: NodePath = state_is_active_guard.state
	var item: TreeItem = create_item(parent_item)
	var es: EditorSettings = EditorInterface.get_editor_settings()

	if transition.has_node(state_path):
		state = transition.get_node(state_path)

	if is_instance_valid(state):
		item.set_icon(0, GuardEditorPlugin.Util.get_corresponding_state_icon(state))

		if es.get_setting(GuardEditorData.Setting.Key.human_readable_node_path):
			if not is_instance_valid(state_chart):
				state_chart = GuardEditorPlugin.Util.get_ancestor_state_chart(transition)

			var node_path: String = state_chart.get_path_to(state)
			var first_slash_i: int = node_path.find("/")
			var p_path: String = (
				node_path if first_slash_i == -1 else node_path.substr(first_slash_i + 1)
			)

			item.set_text(0, p_path)
		else:
			item.set_text(0, state.name)
	else:
		item.set_icon(0, GuardEditorData.Icon.atomic_state_green)

		if es.get_setting(GuardEditorData.Setting.Key.highlight_errors):
			Util.set_item_error_color(item)

	return item


# popup menu configurations


func _append_invert_to_popup(popup_menu: PopupMenu) -> void:
	var i_shortcut: Shortcut = Shortcut.new()
	var i_input: InputEventKey = InputEventKey.new()

	i_input.keycode = KEY_I
	i_shortcut.events.push_back(i_input)

	var last_item_i: int = popup_menu.item_count - 1

	popup_menu.add_icon_item(GuardEditorData.Icon.popup_not_icon, "Invert Guard", last_item_i + 1)

	popup_id_button_map.set(last_item_i + 1, PopupButton.INVERT)
	popup_menu.set_item_shortcut(last_item_i + 1, i_shortcut)


func _append_state_additions_to_popup(popup_menu: PopupMenu) -> void:
	var one_shortcut: Shortcut = Shortcut.new()
	var two_shortcut: Shortcut = Shortcut.new()
	var three_shortcut: Shortcut = Shortcut.new()
	var four_shortcut: Shortcut = Shortcut.new()
	var one_input: InputEventKey = InputEventKey.new()
	var two_input: InputEventKey = InputEventKey.new()
	var three_input: InputEventKey = InputEventKey.new()
	var four_input: InputEventKey = InputEventKey.new()

	one_input.keycode = KEY_1
	two_input.keycode = KEY_2
	three_input.keycode = KEY_3
	four_input.keycode = KEY_4
	one_shortcut.events.push_back(one_input)
	two_shortcut.events.push_back(two_input)
	three_shortcut.events.push_back(three_input)
	four_shortcut.events.push_back(four_input)

	var last_item_i: int = popup_menu.item_count - 1

	popup_menu.add_icon_item(
		GuardEditorData.Icon.popup_all_of_guard_orange,
		"New %s" % GuardEditorData.Name.all_of_guard,
		last_item_i + 1
	)
	popup_menu.add_icon_item(
		GuardEditorData.Icon.popup_any_of_guard_orange,
		"New %s" % GuardEditorData.Name.any_of_guard,
		last_item_i + 2
	)
	popup_menu.add_icon_item(
		GuardEditorData.Icon.popup_expression_guard_orange,
		"New %s" % GuardEditorData.Name.expression_guard,
		last_item_i + 3
	)
	popup_menu.add_icon_item(
		GuardEditorData.Icon.popup_state_is_active_guard_orange,
		"New %s" % GuardEditorData.Name.state_is_active_guard,
		last_item_i + 4
	)

	popup_id_button_map.set(last_item_i + 1, PopupButton.ADD_ALL_OF_GUARD)
	popup_id_button_map.set(last_item_i + 2, PopupButton.ADD_ANY_OF_GUARD)
	popup_id_button_map.set(last_item_i + 3, PopupButton.ADD_EXPRESSION_GUARD)
	popup_id_button_map.set(last_item_i + 4, PopupButton.ADD_STATE_IS_ACTIVE_GUARD)
	popup_menu.set_item_shortcut(last_item_i + 1, one_shortcut)
	popup_menu.set_item_shortcut(last_item_i + 2, two_shortcut)
	popup_menu.set_item_shortcut(last_item_i + 3, three_shortcut)
	popup_menu.set_item_shortcut(last_item_i + 4, four_shortcut)


func _append_separator_to_popup(popup_menu: PopupMenu) -> void:
	var last_item_i: int = popup_menu.item_count - 1

	popup_menu.add_separator("", last_item_i + 1)


func _append_delete_to_popup(popup_menu: PopupMenu) -> void:
	var delete_shortcut: Shortcut = Shortcut.new()
	var delete_input: InputEventKey = InputEventKey.new()

	delete_input.keycode = KEY_DELETE
	delete_shortcut.events.push_back(delete_input)

	var last_item_i: int = popup_menu.item_count - 1

	popup_id_button_map.set(last_item_i + 1, PopupButton.DELETE)

	popup_menu.add_icon_item(GuardEditorData.Icon.popup_delete_icon, "Delete", last_item_i + 1)
	popup_menu.set_item_shortcut(last_item_i + 1, delete_shortcut)


# popup button behaviors


func _popup_invert_behavior(tree_item: TreeItem) -> void:
	var guard: Guard = Util.get_item_guard(tree_item)
	var parent_item: TreeItem = tree_item.get_parent()
	var parent_guard: Guard = Util.get_item_guard_ignoring_not(parent_item)

	if guard is NotGuard:
		if is_instance_valid(parent_guard):
			var guards: Array = parent_guard.get("guards")
			var index: int = guards.find(guard)
			var inverted_guard: Guard = guard.get("guard")

			guards.remove_at(index)
			guards.insert(index, inverted_guard)
			tree_item.set_meta("guard", inverted_guard)
		else:
			var inverted_guard: Guard = guard.get("guard")

			transition.guard = inverted_guard
			tree_item.set_meta("guard", inverted_guard)
	else:
		if is_instance_valid(parent_guard):
			var guards: Array = parent_guard.get("guards")
			var index: int = guards.find(guard)
			var not_guard: NotGuard = NotGuard.new()

			guards.remove_at(index)
			not_guard.guard = guard
			guards.insert(index, not_guard)
			tree_item.set_meta("guard", not_guard)
		else:
			var not_guard: NotGuard = NotGuard.new()

			not_guard.guard = guard
			transition.guard = not_guard
			tree_item.set_meta("guard", not_guard)

	tree_item.set_icon(0, GuardEditorPlugin.Util.get_inverted_icon(guard, transition))


func _popup_delete_behavior(tree_item: TreeItem) -> void:
	var parent_item: TreeItem = tree_item.get_parent()
	var parent_guard: Guard = Util.get_item_guard_ignoring_not(parent_item)
	var sibling_items: Array = parent_item.get_children()
	var item_i: int = sibling_items.find(tree_item)

	if parent_guard is AllOfGuard or parent_guard is AnyOfGuard:
		var sibling_guards: Array = parent_guard.get("guards")

		sibling_guards.pop_at(item_i)

		if sibling_guards.is_empty():
			Util.set_item_error_color(parent_item)
		elif sibling_guards.size() == 1:
			var deleted_item_i: int = sibling_items.find(tree_item)
			var other_i: int = 1 if deleted_item_i == 0 else 0
			var other_item: TreeItem = parent_item.get_child(other_i)

			other_item.clear_buttons()
	else:
		transition.guard = null

	tree_item.free()


func _popup_add_guard_behavior(tree_item: TreeItem, popup_button: PopupButton) -> void:
	var guard: Guard = Util.get_item_guard_ignoring_not(tree_item)
	var added_guard: Guard
	var added_item: TreeItem

	if popup_button == PopupButton.ADD_ALL_OF_GUARD:
		added_guard = AllOfGuard.new()
		added_item = add_all_of_guard_item(tree_item)
		added_item.set_meta("guard", added_guard)
	elif popup_button == PopupButton.ADD_ANY_OF_GUARD:
		added_guard = AnyOfGuard.new()
		added_item = add_any_of_guard_item(tree_item)
		added_item.set_meta("guard", added_guard)
	elif popup_button == PopupButton.ADD_EXPRESSION_GUARD:
		added_guard = ExpressionGuard.new()
		added_item = add_expression_guard_item(tree_item, added_guard)
		added_item.set_meta("guard", added_guard)
	elif popup_button == PopupButton.ADD_STATE_IS_ACTIVE_GUARD:
		added_guard = StateIsActiveGuard.new()
		added_item = add_state_is_active_guard_item(tree_item, added_guard)
		added_item.set_meta("guard", added_guard)

	if guard is AllOfGuard or guard is AnyOfGuard:
		var guards: Array = guard.get("guards")

		guards.push_back(added_guard)
	elif guard is NotGuard:
		guard.set("guard", added_guard)
	else:
		transition.guard = added_guard

	Util.add_move_buttons_to_self_and_siblings_if_has_siblings(added_item)
	Util.clear_parent_item_bg_if_is_all_of_guard(added_item)
	Util.clear_parent_item_bg_if_is_any_of_guard(added_item)


class Util:
	static func clear_parent_item_bg_if_is_any_of_guard(tree_item: TreeItem) -> void:
		var parent_item: TreeItem = tree_item.get_parent()
		var parent_guard: Guard = get_item_guard_ignoring_not(parent_item)

		if not is_instance_valid(parent_guard):
			return

		if parent_guard is AnyOfGuard:
			parent_item.clear_custom_color(0)
			parent_item.clear_custom_bg_color(0)

	static func clear_parent_item_bg_if_is_all_of_guard(tree_item: TreeItem) -> void:
		var parent_item: TreeItem = tree_item.get_parent()
		var parent_guard: Guard = get_item_guard_ignoring_not(parent_item)

		if not is_instance_valid(parent_guard):
			return

		if parent_guard is AllOfGuard:
			parent_item.clear_custom_color(0)
			parent_item.clear_custom_bg_color(0)

	static func add_move_buttons_to_self_and_siblings_if_has_siblings(tree_item: TreeItem) -> void:
		var parent_item: TreeItem = tree_item.get_parent()
		var parent_guard: Guard = get_item_guard_ignoring_not(parent_item)
		var parent_item_child_count: int

		if (
			is_instance_valid(parent_guard)
			and (parent_guard is AllOfGuard or parent_guard is AnyOfGuard)
		):
			parent_item_child_count = parent_item.get_children().size()

		if parent_item_child_count == 2:
			var item_siblings: Array = parent_item.get_children()

			for s: TreeItem in item_siblings:
				s.add_button(0, GuardEditorData.Icon.arrow_down, 0)
				s.add_button(0, GuardEditorData.Icon.arrow_up, 1)
				s.set_button_color(0, 0, GuardEditorData.ARROW_COLOR)
				s.set_button_color(0, 1, GuardEditorData.ARROW_COLOR)
		elif parent_item_child_count > 2:
			tree_item.add_button(0, GuardEditorData.Icon.arrow_down, 0)
			tree_item.add_button(0, GuardEditorData.Icon.arrow_up, 1)
			tree_item.set_button_color(0, 0, GuardEditorData.ARROW_COLOR)
			tree_item.set_button_color(0, 1, GuardEditorData.ARROW_COLOR)

	static func set_item_error_color(tree_item: TreeItem) -> void:
		tree_item.set_custom_bg_color(0, GuardEditorData.ERROR_BG_COLOR)
		tree_item.set_custom_color(0, GuardEditorData.ERROR_COLOR)

	static func get_item_guard_ignoring_not(tree_item: TreeItem) -> Guard:
		if not is_instance_valid(tree_item) or not tree_item.has_meta("guard"):
			return null

		var raw_guard: Guard = tree_item.get_meta("guard")
		var guard: Guard

		if raw_guard is NotGuard:
			var inverted_guard: Guard = raw_guard.get("guard")

			guard = inverted_guard
		else:
			guard = raw_guard

		if not guard is Guard:
			return null

		return guard

	static func get_item_guard(tree_item: TreeItem) -> Guard:
		if not is_instance_valid(tree_item) or not tree_item.has_meta("guard"):
			return null

		var guard: Guard = tree_item.get_meta("guard")

		if not guard is Guard:
			return null

		return guard
