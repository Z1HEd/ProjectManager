extends Control
class_name ConfirmActionPopup

@onready var title = %Title
@onready var description = %Description
@onready var confirm_button = %ConfirmButton
@onready var cancel_button = %CancelButton
@onready var button_separator = %ButtonSeparator

func set_info(title_text:String, description_text:String):
	title.text = title_text
	description.text = description_text

func set_callbacks(on_confirm: Callable = func(_res):pass, on_cancel : Callable = func(_res):pass):
	
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

func set_buttons_visible(confirm_visible:bool, cancel_visible:bool):
	confirm_button.visible = confirm_visible
	cancel_button.visible = cancel_visible
	
	button_separator.visible = confirm_visible and cancel_visible
