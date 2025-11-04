extends Tab

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %TextEdit
@onready var create_button : Button = %CreateButton
@onready var cancel_button : NavigationButton = %CancelButton
@onready var error_label : RichTextLabel = %ErrorText

@export var summary_tab : Tab

func _on_create_success(project_id : String):
	create_button.disabled = false
	Project.pid = project_id
	cancel_button.menu.open_tab(summary_tab)

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
			_on_create_success, 
			_on_create_fail
	)
