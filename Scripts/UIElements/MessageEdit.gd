extends TextEdit
class_name MessageEdit

@export_range(1, 10)
var min_lines: int = 1
@export_range(5, 40)
var max_lines: int = 15

signal send_message(msg: String)

func _ready() -> void:
	_on_text_changed()
	text_changed.connect(_on_text_changed)

func _gui_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if not event.pressed or event.echo:
		return

	var key = event.keycode
	if key != Key.KEY_ENTER:
		return
	accept_event()
	
	if event.shift_pressed:
		insert_text_at_caret("\n")
		return
	
	var msg := text.strip_edges()
	if msg == "":
		return
	
	emit_signal("send_message", msg)
	clear()
	grab_focus()
	_on_text_changed()

func _on_text_changed() -> void:
	var lines = get_line_count()
	if lines < min_lines:
		lines = min_lines

	var clamped = lines
	var should_scroll := false
	if lines > max_lines:
		clamped = max_lines
		should_scroll = true

	var desired_h = int(clamped * get_line_height())+8
	custom_minimum_size = Vector2(custom_minimum_size.x, desired_h)

	if not should_scroll:
		return
		#ensure_cursor_is_visible()

func ensure_cursor_is_visible() -> void:
	var cursor_line = get_caret_line()
	var top_line = get_v_scroll()
	var visible_lines = int((size.y) / get_line_height())
	if cursor_line < top_line:
		set_v_scroll(cursor_line)
	elif cursor_line >= top_line + visible_lines:
		set_v_scroll(cursor_line - visible_lines + 1)
