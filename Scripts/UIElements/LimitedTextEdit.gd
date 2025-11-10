extends TextEdit
class_name LimitedTextEdit

# Godot, why is there a max_length property for LineEdit, but not for TextEdit?
# Good thing someone posted this code for me to copy and adapt for Godot 4.x

@export var max_length = 5000
var current_text = ''
var cursor_line = 0
var cursor_column = 0

func _ready() -> void:
	current_text = text
	text_changed.connect(_on_text_changed)

func _on_text_changed():
	var new_text := text
	if new_text.length() > max_length:
		text = current_text
		
		set_caret_line(cursor_line)
		set_caret_column(cursor_column)

	current_text = text
	cursor_line = get_caret_line()
	cursor_column = get_caret_column()
