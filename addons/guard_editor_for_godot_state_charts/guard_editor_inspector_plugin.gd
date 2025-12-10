@tool
class_name GuardEditorInspectorPlugin
extends EditorInspectorPlugin


func _can_handle(object: Object) -> bool:
	var script: Script = object.get_script()

	if not is_instance_valid(script):
		return false

	var global_name: String = script.get_global_name()

	return global_name == GuardEditorData.Name.transition


func _parse_property(
	object: Object,
	_type: Variant.Type,
	name: String,
	_hint_type: PropertyHint,
	_hint_string: String,
	_usage_flags: PropertyUsageFlags,
	_wide: bool
) -> bool:
	var object_script: Script = object.get_script()
	var object_global_name: String = object_script.get_global_name()

	if object_global_name == GuardEditorData.Name.transition and name == "guard":
		var es: EditorSettings = EditorInterface.get_editor_settings()

		return es.get_setting(GuardEditorData.Setting.Key.hide_original_guard_property)

	return false


func _parse_category(object: Object, category: String) -> void:
	var object_script: Script = object.get_script()
	var object_global_name: String = object_script.get_global_name()

	if not object_global_name == GuardEditorData.Name.transition or not category == "transition.gd":
		return

	var transition: Transition = object
	var state_chart: StateChart = GuardEditorPlugin.Util.get_ancestor_state_chart(transition)
	var tree: GuardEditorTree = GuardEditorTree.new(transition, self)
	var root_item: TreeItem = tree.create_item()
	var first_guard: Guard = transition.guard

	_handle_guard_generic(tree, root_item, transition, state_chart, first_guard)

	add_custom_control(tree)


# handle guard


func _handle_guard_generic(
	tree: Tree, parent_item: TreeItem, transition: Transition, state_chart: StateChart, guard: Guard
) -> void:
	var added_item: TreeItem

	if guard is AllOfGuard:
		added_item = tree.add_all_of_guard_item(parent_item)
		added_item.set_meta("guard", guard)

		var guards: Array = guard.get("guards")

		for child: Guard in guards:
			_handle_guard_generic(tree, added_item, transition, state_chart, child)
	elif guard is AnyOfGuard:
		added_item = tree.add_any_of_guard_item(parent_item)
		added_item.set_meta("guard", guard)

		var guards: Array = guard.get("guards")

		for child: Guard in guards:
			_handle_guard_generic(tree, added_item, transition, state_chart, child)
	elif guard is NotGuard:
		var inverted_guard: Guard = guard.get("guard")

		if inverted_guard is AllOfGuard:
			added_item = tree.add_all_of_guard_item(parent_item)
			added_item.set_meta("guard", guard)
			added_item.set_icon(0, GuardEditorData.Icon.not_all_of_guard_orange)

			var guards: Array = inverted_guard.get("guards")

			for child: Guard in guards:
				_handle_guard_generic(tree, added_item, transition, state_chart, child)
		elif inverted_guard is AnyOfGuard:
			added_item = tree.add_any_of_guard_item(parent_item)
			added_item.set_meta("guard", guard)
			added_item.set_icon(0, GuardEditorData.Icon.not_any_of_guard_orange)

			var guards: Array = inverted_guard.get("guards")

			for child: Guard in guards:
				_handle_guard_generic(tree, added_item, transition, state_chart, child)
		elif inverted_guard is ExpressionGuard:
			added_item = tree.add_expression_guard_item(parent_item, inverted_guard)
			added_item.set_meta("guard", guard)
			added_item.set_icon(0, GuardEditorData.Icon.not_expression_guard_blue)
		elif inverted_guard is StateIsActiveGuard:
			var state_path: NodePath = inverted_guard.get("state")
			var state: StateChartState

			if transition.has_node(state_path):
				state = transition.get_node(state_path)

			added_item = tree.add_state_is_active_guard_item(parent_item, inverted_guard)
			added_item.set_meta("guard", guard)

			if state == null or state is AtomicState:
				added_item.set_icon(0, GuardEditorData.Icon.not_atomic_state_green)
			elif state is CompoundState:
				added_item.set_icon(0, GuardEditorData.Icon.not_compound_state_green)
			elif state is HistoryState:
				added_item.set_icon(0, GuardEditorData.Icon.not_history_state_green)
			elif state is ParallelState:
				added_item.set_icon(0, GuardEditorData.Icon.not_parallel_state_green)

	elif guard is ExpressionGuard:
		added_item = tree.add_expression_guard_item(parent_item, guard)
		added_item.set_meta("guard", guard)
	elif guard is StateIsActiveGuard:
		added_item = tree.add_state_is_active_guard_item(parent_item, guard)
		added_item.set_meta("guard", guard)
	elif not is_instance_valid(guard):
		if not parent_item.has_meta("guard"):
			return

		var parent_guard: Guard = GuardEditorTree.Util.get_item_guard_ignoring_not(parent_item)

		if parent_guard is AllOfGuard or parent_guard is AnyOfGuard:
			added_item = tree.add_empty_slot_item(parent_item)

	if is_instance_valid(added_item):
		GuardEditorTree.Util.add_move_buttons_to_self_and_siblings_if_has_siblings(added_item)
		GuardEditorTree.Util.clear_parent_item_bg_if_is_all_of_guard(added_item)
		GuardEditorTree.Util.clear_parent_item_bg_if_is_any_of_guard(added_item)
