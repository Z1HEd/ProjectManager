extends Control
class_name OptionPopup

@onready var title = %Title
@onready var description = %Description
@onready var option_button = %OptionButton
@onready var submit_button = %SubmitButton
@onready var cancel_button = %CancelButton

func set_info(title_text:String, description_text:String):
	title.text = title_text
	description.text = description_text

func set_items(items: Array[String],default_index := -1):
	option_button.clear()
	
	for item in items:
		option_button.add_item(item)
	
	option_button.selected = default_index

func set_callbacks(on_confirm: Callable = func(_val:String):pass, on_cancel : Callable = func():pass):
	
	var _on_confirm_pressed = func():
		on_confirm.call(option_button.get_item_text(option_button.selected))
		visible = false
	
	var _on_cancel_pressed = func():
		on_cancel.call()
		visible = false
	
	for connection in submit_button.pressed.get_connections():
		submit_button.pressed.disconnect(connection["callable"])
	for connection in cancel_button.pressed.get_connections():
		cancel_button.pressed.disconnect(connection["callable"])
	
	submit_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
