extends Control
class_name ConfirmCriticalPopup

@onready var title = %Title
@onready var description = %Description
@onready var confirm_button = %ConfirmButton
@onready var cancel_button = %CancelButton
@onready var button_separator = %ButtonSeparator
@onready var input = %Input

var text_to_enter := ""

func set_info(title_text:String, description_text : String ,_text_to_enter:String):
	title.text = title_text
	text_to_enter = _text_to_enter
	description.text = description_text
	confirm_button.disabled = text_to_enter != ""
	input.text = ""

func set_callbacks(on_confirm: Callable = func():pass, on_cancel : Callable = func():pass):
	
	var _on_confirm_pressed = func():
		on_confirm.call()
		visible = false
	
	var _on_cancel_pressed = func():
		on_cancel.call()
		visible = false
	
	for connection in confirm_button.pressed.get_connections():
		confirm_button.pressed.disconnect(connection["callable"])
	for connection in cancel_button.pressed.get_connections():
		cancel_button.pressed.disconnect(connection["callable"])
	
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)


func _on_input_text_changed(new_text: String) -> void:
	confirm_button.disabled = text_to_enter != new_text
