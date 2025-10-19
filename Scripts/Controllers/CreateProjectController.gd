extends Tab

@onready var name_input : LineEdit = $CenterContainer/Control/MarginContainer/VBoxContainer/NameEdit
@onready var description_input : TextEdit = $CenterContainer/Control/MarginContainer/VBoxContainer/TextEdit
@onready var create_button : Button = $CenterContainer/Control/MarginContainer/VBoxContainer/HBoxContainer/CreateButton
@onready var cancel_button : NavigationButton = $CenterContainer/Control/MarginContainer/VBoxContainer/HBoxContainer/CancelButton
@onready var error_label : RichTextLabel = $CenterContainer/Control/MarginContainer/VBoxContainer/ErrorText

func _on_create_success(_project_id : String):
	create_button.disabled = false
	cancel_button._pressed()

func _on_create_fail(err_msg: String):
	create_button.disabled = false
	error_label.text=err_msg

func _on_create_project_button_pressed() -> void:
	var project_name = name_input.text.strip_edges()
	var description = description_input.text.strip_edges()
	if project_name == "":
		error_label.text="Project must have a name!"
		return
	
	error_label.text = ""
	create_button.disabled = true
	
	ProjectService.create_project(project_name, 
			description, 
			Callable(self, "_on_create_success"), 
			Callable(self, "_on_create_fail")
	)
