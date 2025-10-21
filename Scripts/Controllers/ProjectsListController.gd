extends Tab

@onready var refresh_button = $HBoxContainer/ProjectsList/MarginContainer/VBoxContainer/HBoxContainer2/RefreshButton
@onready var error_message = $HBoxContainer/ProjectsList/MarginContainer/VBoxContainer/ErrorMessage
@onready var item_list = $HBoxContainer/ProjectsList/MarginContainer/VBoxContainer/ItemList

@onready var project_name = $HBoxContainer/MarginContainer/MarginContainer/VBoxContainer/Name
@onready var project_member_count = $HBoxContainer/MarginContainer/MarginContainer/VBoxContainer/MemberCount
@onready var project_description = $HBoxContainer/MarginContainer/MarginContainer/VBoxContainer/Description

var projects : Dictionary = {}
var projects_details = []
var selected_id := -1

func _on_open():
	refresh_projects()

func refresh_projects():
	
	error_message.text = ""
	item_list.clear()
	selected_id = -1
	refresh_button.disabled = true
	
	var _on_projects_refresh_success = func(projects_dict):
		projects = projects_dict
		repopulate_project_list()
	
	var _on_projects_refresh_fail = func(err_msg):
		error_message.text ="Failed to refresh project list: %s" % err_msg
		
	UserService.get_user_projects(Session.uid,_on_projects_refresh_success,_on_projects_refresh_fail)

var projects_to_read : int
func repopulate_project_list():
	
	projects_to_read = projects.size()
	
	var _on_success = func(project : Dictionary):
		projects_details.append(project)
		item_list.add_item(project.get("name"))
		projects_to_read -= 1
		if projects_to_read == 0:
			refresh_button.disabled = false
	
	var _on_fail = func(err_msg : String):
		refresh_button.disabled = false
		error_message.text ="Failed to retrieve project details: %s" % err_msg
	
	for project in projects:
		ProjectService.get_project(project, _on_success, _on_fail)

func _on_item_list_item_selected(index: int) -> void:
	selected_id = index
	project_name.text = projects_details[index].get("name")
	project_description.text = projects_details[index].get("description")
	project_member_count.text = "Members: %s" % projects_details[index].get("members").size()


func _on_open_button_pressed() -> void:
	if (selected_id == -1):
		push_error("Tried opening project when no project is selected!")
	
	CurrentProject.set_project(projects.keys()[selected_id])
