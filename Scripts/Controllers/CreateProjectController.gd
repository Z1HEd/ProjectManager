extends Tab

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %TextEdit
@onready var create_button : Button = %CreateButton
@onready var cancel_button : NavigationButton = %CancelButton

@export var summary_tab : Tab

func open():pass
func close():pass

func _on_create_project_button_pressed() -> void:
	var project_name = name_input.text.strip_edges()
	var description = description_input.text.strip_edges()
	if project_name == "":
		AppNotifications.push("Project must have a name!")
		return
	
	create_button.disabled = true
	
	var _on_create_success = func(project_id : String):
		create_button.disabled = false
		Project.set_project(project_id)

	var _on_create_fail = func(_err_msg: String):
		create_button.disabled = false
	
	ProjectService.create_project(project_name, 
			description, 
			_on_create_success, 
			_on_create_fail)
