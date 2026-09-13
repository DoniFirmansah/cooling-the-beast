extends Node
## GlobalInput.gd
## Dynamically registers all required game input actions at boot time.
## Adheres to .clinerules: Dynamic Input Mapping protocol.

func _ready() -> void:
	_register_input_actions()

func _register_input_actions() -> void:
	_register_action("move_left", [KEY_A, KEY_LEFT])
	_register_action("move_right", [KEY_D, KEY_RIGHT])
	_register_action("move_up", [KEY_W, KEY_UP])
	_register_action("move_down", [KEY_S, KEY_DOWN])
	_register_action("interact", [KEY_SPACE, MOUSE_BUTTON_LEFT])
	_register_action("dash", [KEY_SHIFT])
	_register_action("pause", [KEY_ESCAPE, KEY_P])

func _register_action(action_name: StringName, keys: Array) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	
	for key in keys:
		if key is Key:
			var ev: InputEventKey = InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event(action_name, ev)
		elif key is MouseButton:
			var ev_mouse: InputEventMouseButton = InputEventMouseButton.new()
			ev_mouse.button_index = key
			InputMap.action_add_event(action_name, ev_mouse)
