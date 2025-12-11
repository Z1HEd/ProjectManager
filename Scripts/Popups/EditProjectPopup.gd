extends Control
class_name EditProjectPopup

@onready var name_input : LineEdit = %NameEdit
@onready var description_input : TextEdit = %TextEdit
@onready var submit_button : Button = %SubmitButton
@onready var cancel_button : NavigationButton = %CancelButton

func set_current_info(current_name: String, current_description: String):
	name_input.text = current_name
	description_input.text = current_description

func _on_submit_button_pressed() -> void:
	var project_name = name_input.text.strip_edges()
	var description = description_input.text.strip_edges()
	if project_name == "":
		AppNotifications.push("Project must have a name!")
		return
	
	submit_button.disabled = true
	cancel_button.disabled = true
	
	var _on_success = func(_result):
		submit_button.disabled = false
		cancel_button.disabled = false
		visible = false
		AppNotifications.push("Changes have been saved")
	
	var _on_fail = func(_err_msg: String):
		submit_button.disabled = false
		cancel_button.disabled = false
	
	ProjectService.edit_project(
			Project.pid,
			project_name, 
			description, 
			_on_success, 
			_on_fail)


func _on_cancel_button_pressed() -> void:
	visible = false
