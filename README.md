
An unofficial in-line editor for the `guard` property of the `Transition` node. Depends on **Godot State Charts** by **Jan Thomä & Contributors**.

<br>

https://github.com/Granshmeyr/guard-editor-for-godot-state-charts/raw/refs/heads/main/demo.mp4

<br>

> What problem does this solve?

`Transition` guards are edited using the default `Resource` editor. On top of the horrible nesting, guards recursively collapse when clicking away. With this editor, nothing will ever collapse and nesting is displayed using the standard `Tree` control.

<br>

## Info

- Written in GDScript using built-in controls.
- `ExpressionGuard` displays in-lined with its `expression` for reduced nesting.
- `StateIsActiveGuard` displays in-lined with its `state` for reduced nesting.
- `NotGuard` displays in-lined with its `guard` for reduced nesting.
- Simple error checking highlighting configuration errors in red.
- Guard's index can be moved within its parent array.
- A handful of display settings in `Editor Settings...`

## Caveat

- Editor state is not synced to the actual state of `Transition`'s `guard` property. If you update guards in the original `Resource` editor, Guard Editor's state will not update. There is an option to disable the original editor (enabled by default).
- Is opinionated in visual design, with emphasis on brevity and condensed information.
- Only supports built-in guards, but should be easily extendable.
- There is a random line access error that is reported by the engine sometimes when editing an `ExpressionGuard`, but it doesn't affect anything.

<br>

Developed / tested on `v4.4.1.stable.official [49a5bc7b6]` with **Godot State Charts** version `0.22.0`.
